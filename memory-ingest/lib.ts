/**
 * lib.ts - Pure Kernlogik fuer den Memory-Ingest (ADR-004-Test-Seam).
 *
 * Transcript-Komposition, Slug-Namen, Export-Planung und State-Merge
 * ohne IO: DB-Zugriff liegt in export.ts, Orchestrierung in ingest.ps1.
 * Kein Schreibzugriff auf die App-Datenbank (read-only-Contract).
 */

export type ThreadRecord = {
	id: string;
	title: string;
	status: string;
	createdAt: number;
	updatedAt: number;
};

export type ExportMessage = {
	role: string;
	ts: number;
	text: string;
};

export type StateEntry = {
	title: string;
	messageCount: number;
	updatedAt: number;
	exportedAt: number;
	file: string;
};

export type MemoryIngestState = {
	version: 1;
	threads: Record<string, StateEntry>;
};

export type PlanOptions = {
	now: number;
	stalenessMinutes: number;
	minMessages: number;
};

export type ExportPlan = {
	toExport: ThreadRecord[];
	unchanged: ThreadRecord[];
	live: ThreadRecord[];
	empty: ThreadRecord[];
	forced: ThreadRecord[];
};

export function parseState(raw: string | null): MemoryIngestState {
	if (!raw) {
		return { version: 1, threads: {} };
	}
	try {
		const parsed = JSON.parse(raw) as Partial<MemoryIngestState>;
		if (!parsed || typeof parsed !== 'object' || !parsed.threads || typeof parsed.threads !== 'object') {
			return { version: 1, threads: {} };
		}
		return { version: 1, threads: parsed.threads as Record<string, StateEntry> };
	} catch {
		return { version: 1, threads: {} };
	}
}

export function serializeState(state: MemoryIngestState): string {
	return `${JSON.stringify(state, null, '\t')}\n`;
}

export function fmtTs(ms: number): string {
	return new Date(ms).toISOString().replace('T', ' ').slice(0, 16);
}

export function slugify(title: string, id: string): string {
	const t = title
		.toLowerCase()
		.replace(/ä/g, 'ae')
		.replace(/ö/g, 'oe')
		.replace(/ü/g, 'ue')
		.replace(/ß/g, 'ss')
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-+|-+$/g, '')
		.slice(0, 60);
	return `${t || 'thread'}-${id.slice(0, 8)}`;
}

export function transcriptFileName(thread: ThreadRecord): string {
	return `${slugify(thread.title, thread.id)}.md`;
}

type Part = { kind: string; text?: string };

export function extractTextParts(partsJson: string): string {
	let parts: Part[] = [];
	try {
		const parsed = JSON.parse(partsJson);
		if (Array.isArray(parsed)) parts = parsed as Part[];
	} catch {
		return '';
	}
	const texts = parts
		.filter((p) => p && p.kind === 'text' && typeof p.text === 'string')
		.map((p) => (p.text ?? '').trim())
		.filter((t) => t.length > 0);
	return texts.join('\n\n');
}

export function composeTranscript(thread: ThreadRecord, messages: ExportMessage[]): string {
	const lines: string[] = [
		`# ${thread.title}`,
		'',
		`- Session: ${thread.id}`,
		`- Zeitraum: ${fmtTs(thread.createdAt)} bis ${fmtTs(thread.updatedAt)}`,
		`- Status: ${thread.status}`,
		`- Nachrichten (mit Text): ${messages.length}`,
		'',
		'---',
		'',
	];
	for (const m of messages) {
		lines.push(`### ${m.role === 'user' ? 'User' : 'Assistant'} — ${fmtTs(m.ts)}`);
		lines.push('');
		lines.push(m.text);
		lines.push('');
	}
	return lines.join('\n');
}

export function isLive(thread: ThreadRecord, opts: PlanOptions): boolean {
	return opts.now - thread.updatedAt < opts.stalenessMinutes * 60_000;
}

/**
 * Plant den Export-Lauf. Reihenfolge der Pruefungen pro Thread:
 * forced (--include-thread) > live (Staleness-Fenster) > leer/zu kurz
 * (MinMessages) > unveraendert (State) > Export.
 * Live-Schutz: Threads, die juenger als stalenessMinutes aktualisiert
 * wurden, bleiben draussen - die laufende Session wird nie angefasst.
 */
export function planExport(
	threads: ThreadRecord[],
	counts: Record<string, number>,
	state: MemoryIngestState,
	opts: PlanOptions,
	includeThreads: string[] = [],
	force = false,
): ExportPlan {
	const plan: ExportPlan = { toExport: [], unchanged: [], live: [], empty: [], forced: [] };
	const includeSet = new Set(includeThreads);
	for (const thread of threads) {
		const count = counts[thread.id] ?? 0;
		const entry = state.threads[thread.id];
		const file = transcriptFileName(thread);
		const isForced = includeSet.has(thread.id);
		const unchanged =
			entry !== undefined &&
			entry.messageCount === count &&
			entry.updatedAt === thread.updatedAt &&
			entry.file === file;
		if (isForced) {
			plan.forced.push(thread);
			plan.toExport.push(thread);
			continue;
		}
		if (isLive(thread, opts)) {
			plan.live.push(thread);
			continue;
		}
		if (count < opts.minMessages) {
			plan.empty.push(thread);
			continue;
		}
		if (!force && unchanged) {
			plan.unchanged.push(thread);
			continue;
		}
		plan.toExport.push(thread);
	}
	return plan;
}

export function nextState(
	state: MemoryIngestState,
	exported: { thread: ThreadRecord; messageCount: number }[],
	now: number,
): MemoryIngestState {
	const threads = { ...state.threads };
	for (const { thread, messageCount } of exported) {
		threads[thread.id] = {
			title: thread.title,
			messageCount,
			updatedAt: thread.updatedAt,
			exportedAt: now,
			file: transcriptFileName(thread),
		};
	}
	return { version: 1, threads };
}
