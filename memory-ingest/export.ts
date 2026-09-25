/**
 * export.ts - CLI-Exportteil des Memory-Ingest.
 *
 * Liest die Freebuff-Desktop-DB read-only, schreibt Markdown-Transcripte
 * fuer `mempalace mine <dir> --mode convos` und fuehrt den State
 * (memory-ingest-state.json) fort. Die laufende Session bleibt ueber ein
 * Staleness-Fenster draussen; einzelne Threads lassen sich per
 * --include-thread erzwingen. Orchestrierung (mine) uebernimmt ingest.ps1.
 *
 * Benutzung:
 *   bun run memory-ingest/export.ts                  # inkrementeller Lauf
 *   bun run memory-ingest/export.ts --dry-run        # nur Plan zeigen
 *   bun run memory-ingest/export.ts --include-thread <id>[,<id>...]
 *   bun run memory-ingest/export.ts --force          # State ignorieren
 */

import { Database } from 'bun:sqlite';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
	composeTranscript,
	extractTextParts,
	fmtTs,
	nextState,
	parseState,
	planExport,
	serializeState,
	transcriptFileName,
	type ExportMessage,
	type MemoryIngestState,
	type ThreadRecord,
} from './lib.ts';

const DEFAULT_DB_PATH =
	'C:/Users/Max Hambi/.config/freebuff-desktop/projects/tools-entwicklung-b9df0048-1507-46ad-b826-4e4f4094d4e5/desktop-v2.db';
// Bewusst derselbe Ordner wie beim Legacy-Mining (25.09.2026): mempalace mine
// ist pro Quellpfad idempotent - der bestehende Pfad vermeidet Duplikat-Drawers.
const DEFAULT_OUT_DIR = 'D:/mempalace/exports/freebuff-legacy-sessions';

type Args = {
	dbPath: string;
	outDir: string;
	statePath: string;
	dryRun: boolean;
	force: boolean;
	stalenessMinutes: number;
	minMessages: number;
	includeThreads: string[];
	verbose: boolean;
	prune: boolean;
};

function parseArgs(argv: string[]): Args {
	const args: Args = {
		dbPath: process.env.MEMORY_INGEST_DB ?? DEFAULT_DB_PATH,
		outDir: process.env.MEMORY_INGEST_OUT ?? DEFAULT_OUT_DIR,
		statePath: '',
		dryRun: false,
		force: false,
		stalenessMinutes: 30,
		minMessages: 2,
		includeThreads: [],
		verbose: false,
		prune: true,
	};
	let i = 0;
	while (i < argv.length) {
		const a = argv[i] ?? '';
		switch (a) {
			case '--db':
				args.dbPath = argv[++i] ?? args.dbPath;
				break;
			case '--out':
				args.outDir = argv[++i] ?? args.outDir;
				break;
			case '--state':
				args.statePath = argv[++i] ?? args.statePath;
				break;
			case '--dry-run':
				args.dryRun = true;
				break;
			case '--force':
				args.force = true;
				break;
			case '--staleness-minutes':
				args.stalenessMinutes = Number.parseInt(argv[++i] ?? '', 10) || args.stalenessMinutes;
				break;
			case '--min-messages':
				args.minMessages = Number.parseInt(argv[++i] ?? '', 10) || args.minMessages;
				break;
			case '--include-thread': {
				const raw = argv[++i] ?? '';
				args.includeThreads.push(...raw.split(',').map((s) => s.trim()).filter(Boolean));
				break;
			}
			case '--no-prune':
				args.prune = false;
				break;
			case '--verbose':
				args.verbose = true;
				break;
			default:
				console.error(`Unbekanntes Argument: ${a}`);
				process.exit(1);
		}
		i++;
	}
	if (!args.statePath) {
		// Neben dem Export-Ordner (nicht darin): mempalace mine liest den ganzen
		// Ordner ein - der volatile State-JSON gehoert nicht in den Mining-Korpus.
		args.statePath = join(args.outDir, '..', 'memory-ingest-state.json');
	}
	return args;
}

type DbThreadRow = {
	id: string;
	title: string;
	status: string;
	created_at: number;
	updated_at: number;
};

type DbMessageRow = {
	role: string;
	parts_json: string;
	ts: number;
};

function readMessages(db: Database, threadId: string): ExportMessage[] {
	const rows = db
		.prepare('SELECT role, parts_json, ts FROM messages WHERE thread_id = ? ORDER BY seq ASC')
		.all(threadId) as DbMessageRow[];
	const messages: ExportMessage[] = [];
	for (const row of rows) {
		const text = extractTextParts(row.parts_json);
		if (!text) continue;
		messages.push({ role: row.role, ts: row.ts, text });
	}
	return messages;
}

/**
 * Entfernt State-Eintraege, deren Transcript-Datei nicht mehr existiert
 * (manuell geloescht oder Out-Dir gewechselt). Persistierung uebernimmt
 * das finale nextState-Schreiben; mine ist idempotent, orphan-Transcripte
 * ohne State-Eintrag bleiben bewusst liegen.
 */
function pruneStateEntries(state: MemoryIngestState, outDir: string, verbose: boolean): number {
	if (!existsSync(outDir)) return 0;
	let removed = 0;
	for (const [id, entry] of Object.entries(state.threads)) {
		const fileGone = !entry?.file || !existsSync(join(outDir, entry.file));
		if (fileGone) {
			delete state.threads[id];
			removed++;
			if (verbose) console.log(`PRUNE state: ${id.slice(0, 8)} (${entry?.file ?? 'kein Dateiname'})`);
		}
	}
	return removed;
}

function main(): number {
	const args = parseArgs(process.argv.slice(2));

	if (!existsSync(args.dbPath)) {
		console.error(`FEHLER: DB nicht gefunden: ${args.dbPath}`);
		return 1;
	}

	let rawState: string | null = null;
	if (existsSync(args.statePath)) {
		rawState = readFileSync(args.statePath, 'utf8');
	}
	const state = parseState(rawState);

	const db = new Database(args.dbPath, { readonly: true });
	try {
		const threads = db
			.prepare('SELECT id, title, status, created_at, updated_at FROM threads ORDER BY created_at ASC')
			.all() as DbThreadRow[];

		const counts: Record<string, number> = {};
		const messageCache = new Map<string, ExportMessage[]>();
		for (const th of threads) {
			const msgs = readMessages(db, th.id);
			counts[th.id] = msgs.length;
			messageCache.set(th.id, msgs);
		}

		const now = Date.now();
		const plan = planExport(
			threads.map((th) => ({
				id: th.id,
				title: th.title,
				status: th.status,
				createdAt: th.created_at,
				updatedAt: th.updated_at,
			})),
			counts,
			state,
			{ now, stalenessMinutes: args.stalenessMinutes, minMessages: args.minMessages },
			args.includeThreads,
			args.force,
		);

		console.log(
			`Plan: ${plan.toExport.length} export, ${plan.unchanged.length} unveraendert, ${plan.live.length} live-geschuetzt, ${plan.empty.length} zu kurz (min=${args.minMessages}), forced=${plan.forced.length}`,
		);

		if (args.verbose) {
			for (const th of plan.live) console.log(`LIVE (geschuetzt): "${th.title}" (${th.id.slice(0, 8)})`);
			for (const th of plan.empty) console.log(`KURZ  (<${args.minMessages} Msgs): "${th.title}" (${th.id.slice(0, 8)})`);
			for (const th of plan.unchanged) console.log(`GLEICH: "${th.title}" (${th.id.slice(0, 8)})`);
			for (const th of plan.toExport) console.log(`EXPORT: "${th.title}" (${th.id.slice(0, 8)})`);
		}

		if (args.dryRun) {
			console.log('DRY-RUN: nichts geschrieben.');
			return 0;
		}

		mkdirSync(args.outDir, { recursive: true });

		const exported: { thread: ThreadRecord; messageCount: number }[] = [];
		for (const th of plan.toExport) {
			const messages = messageCache.get(th.id) ?? [];
			const content = composeTranscript(th, messages);
			const file = join(args.outDir, transcriptFileName(th));
			writeFileSync(file, content, 'utf8');
			exported.push({ thread: th, messageCount: messages.length });
			console.log(`OK: ${file} (${messages.length} Nachrichten)`);
		}

		if (args.prune) {
			pruneStateEntries(state, args.outDir, args.verbose);
		}

		const updated = nextState(state, exported, now);
		writeFileSync(args.statePath, serializeState(updated), 'utf8');
		console.log(`State: ${args.statePath} (${Object.keys(updated.threads).length} Threads bekannt)`);
		console.log(`\nFertig: ${exported.length} exportiert. Danach: mempalace mine "${args.outDir}" --mode convos`);
		return 0;
	} finally {
		db.close();
	}
}

process.exit(main());
