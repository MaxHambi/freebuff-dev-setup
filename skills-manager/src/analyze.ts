// Analyse-CLI: scannt die Bibliothek, klassifiziert und schreibt Index + Report + State.
// Aufruf: bun run skills-manager/src/analyze.ts [--root <pfad>] [--watch] [--quiet]
// Delta-Verhalten: existiert die State-Datei, werden nur Deltas neu klassifiziert.

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';

import { buildState, computeDelta } from './delta.ts';
import { buildIndex, renderReport } from './report.ts';
import { scanSkillsRoot } from './scan.ts';
import type { SkillMeta, SkillsState } from './types.ts';

export const DEFAULT_ROOT = join(homedir(), '.agents', 'skills');
export const DATA_DIR = join(import.meta.dir, 'data');

const STATE_FILE = join(DATA_DIR, 'state.json');

export async function loadState(
	stateFile = STATE_FILE,
): Promise<SkillsState | null> {
	try {
		return JSON.parse(await readFile(stateFile, 'utf8')) as SkillsState;
	} catch {
		return null;
	}
}

export async function analyze(
	root: string,
	options: { stateFile?: string } = {},
): Promise<{
	index: ReturnType<typeof buildIndex>;
	delta: ReturnType<typeof computeDelta> | null;
	state: SkillsState;
}> {
	const scan = await scanSkillsRoot(root);
	const now = new Date();

	let delta: ReturnType<typeof computeDelta> | null = null;
	const stateFile = options.stateFile ?? STATE_FILE;
	const previous = await loadState(stateFile);
	if (previous && previous.skillsRoot === root) {
		delta = computeDelta(previous, scan.skills);
	}

	const state = buildState(scan.skills, root);
	const index = buildIndex(scan.skills, root, now.toISOString());
	return { index, delta, state };
}

export async function writeArtifacts(
	result: Awaited<ReturnType<typeof analyze>>,
	options: { dataDir?: string } = {},
): Promise<{ indexFile: string; reportFile: string; stateFile: string }> {
	const dataDir = options.dataDir ?? DATA_DIR;
	await mkdir(dataDir, { recursive: true });
	const indexFile = join(dataDir, 'skills.json');
	const reportFile = join(dataDir, 'REPORT.md');
	const stateFile = join(dataDir, 'state.json');

	await writeFile(
		indexFile,
		`${JSON.stringify(result.index, null, '\t')}\n`,
		'utf8',
	);
	await writeFile(reportFile, renderReport(result.index), 'utf8');
	await writeFile(
		stateFile,
		`${JSON.stringify(result.state, null, '\t')}\n`,
		'utf8',
	);
	return { indexFile, reportFile, stateFile };
}

function printDeltaSummary(
	delta: NonNullable<Awaited<ReturnType<typeof analyze>>['delta']>,
): void {
	console.log(
		`Delta: +${delta.added.length} neu, ~${delta.changed.length} geaendert, -${delta.deleted.length} geloescht, ` +
			`=> ${delta.renamed.length} umbenannt, ${delta.unchangedCount} unveraendert`,
	);
}

async function main(): Promise<void> {
	const args = process.argv.slice(2);
	const rootArg = args.indexOf('--root');
	const root =
		rootArg !== -1 ? (args[rootArg + 1] ?? DEFAULT_ROOT) : DEFAULT_ROOT;
	const quiet = args.includes('--quiet');

	if (!quiet) console.log(`Analysiere: ${root}`);
	const result = await analyze(root);
	if (result.delta) printDeltaSummary(result.delta);
	const files = await writeArtifacts(result);

	if (!quiet) {
		console.log(
			`Index: ${result.index.stats.total} Skills ` +
				`(stale: ${result.index.stats.stale}, incompat: ${result.index.stats.incompat}, setup: ${result.index.stats.setup})`,
		);
		console.log(`Geschrieben: ${files.indexFile}`);
		console.log(`Geschrieben: ${files.reportFile}`);
		console.log(`Geschrieben: ${files.stateFile}`);
	}
}

const isDirectRun =
	process.argv[1] !== undefined &&
	(process.argv[1].endsWith('analyze.ts') ||
		process.argv[1].endsWith('analyze.ts.exe'));
if (isDirectRun) {
	main().catch((error) => {
		console.error(
			`Fehler: ${error instanceof Error ? error.message : String(error)}`,
		);
		process.exitCode = 1;
	});
}
