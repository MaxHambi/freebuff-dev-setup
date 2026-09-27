import { afterAll, describe, expect, test } from 'bun:test';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import {
	composeTranscript,
	extractTextParts,
	fmtTs,
	nextState,
	parseState,
	planExport,
	serializeState,
	slugify,
	transcriptFileName,
	type ThreadRecord,
} from '../lib.ts';

const tmpDirs: string[] = [];

function makeTmpDir(): string {
	const dir = mkdtempSync(join(tmpdir(), 'memory-ingest-'));
	tmpDirs.push(dir);
	return dir;
}

afterAll(() => {
	for (const dir of tmpDirs) rmSync(dir, { recursive: true, force: true });
});

function thread(id: string, title: string, updatedAt: number, status = 'done'): ThreadRecord {
	return { id, title, status, createdAt: updatedAt - 60_000, updatedAt };
}

const NOW = 1_800_000_000_000; // fester Zeitstempel, deterministisch

describe('slugify', () => {
	test('umschreibt Umlaute und begrenzt die Laenge', () => {
		expect(slugify('Über große Pfade?', 'abcdef12-3456')).toBe('ueber-grosse-pfade-abcdef12');
	});

	test('entfernt nicht-lateinische Zeichen statt sie zu transliterieren', () => {
		expect(slugify('Mérida / Café', 'abcdef12-3456')).toBe('m-rida-caf-abcdef12');
	});

	test('leerer Titel faellt auf "thread" zurueck', () => {
		expect(slugify('!!!', 'abcdef12-3456')).toBe('thread-abcdef12');
	});
});

describe('extractTextParts', () => {
	test('extrahiert nur Text-Parts und verkettet sie', () => {
		const json = JSON.stringify([
			{ kind: 'text', text: 'Entscheidung: Bun-only.' },
			{ kind: 'reasoning', text: 'geheim' },
			{ kind: 'text', text: 'Zweite Zeile' },
			{ kind: 'tool', tool: 'x' },
		]);
		expect(extractTextParts(json)).toBe('Entscheidung: Bun-only.\n\nZweite Zeile');
	});

	test('kaputtes JSON oder Nicht-Array ergibt leeren String', () => {
		expect(extractTextParts('{kein json')).toBe('');
		expect(extractTextParts(JSON.stringify({ kind: 'text' }))).toBe('');
	});
});

describe('composeTranscript', () => {
	test('erzeugt Header und rollen-markierte Abschnitte', () => {
		const th = thread('t1', 'Sitzung', NOW);
		const md = composeTranscript(th, [
			{ role: 'user', ts: NOW, text: 'Frage' },
			{ role: 'assistant', ts: NOW, text: 'Antwort' },
		]);
		expect(md).toContain('# Sitzung');
		expect(md).toContain('- Session: t1');
		expect(md).toContain('- Nachrichten (mit Text): 2');
		expect(md).toContain('### User —');
		expect(md).toContain('### Assistant —');
		expect(md).toContain('Frage');
		expect(md).not.toContain('Assistant — Frage');
	});
});

describe('parseState / serializeState', () => {
	test('null, kaputter JSON und Legacy-Form ergeben leeren State', () => {
		expect(parseState(null)).toEqual({ version: 1, threads: {} });
		expect(parseState('{kaputt')).toEqual({ version: 1, threads: {} });
		expect(parseState('{"foo":1}')).toEqual({ version: 1, threads: {} });
	});

	test('Round-Trip ueber Datei bleibt stabil', () => {
		const dir = makeTmpDir();
		const path = join(dir, 'state.json');
		const st = nextState({ version: 1, threads: {} }, [{ thread: thread('t1', 'A', NOW), messageCount: 3 }], NOW);
		writeFileSync(path, serializeState(st), 'utf8');
		const readBack = parseState(readFileSync(path, 'utf8'));
		expect(readBack.threads['t1']).toEqual(st.threads['t1']);
	});
});

describe('planExport', () => {
	test('frisch aktualisierte Threads bleiben im Staleness-Fenster draussen (Live-Schutz)', () => {
		const th = thread('live1', 'Live', NOW - 5 * 60_000);
		const plan = planExport([th], { live1: 5 }, { version: 1, threads: {} }, {
			now: NOW,
			stalenessMinutes: 30,
			minMessages: 2,
		});
		expect(plan.live).toHaveLength(1);
		expect(plan.toExport).toHaveLength(0);
	});

	test('Threads unter MinMessages gelten als zu kurz', () => {
		const th = thread('short1', 'Kurz', NOW - 5 * 60_60_000);
		const plan = planExport([th], { short1: 1 }, { version: 1, threads: {} }, {
			now: NOW,
			stalenessMinutes: 30,
			minMessages: 2,
		});
		expect(plan.empty).toHaveLength(1);
		expect(plan.toExport).toHaveLength(0);
	});

	test('unveraenderte Threads (State-Treffer) werden uebersprungen', () => {
		const th = thread('t1', 'Alt', NOW - 3_600_000);
		const state = nextState({ version: 1, threads: {} }, [{ thread: th, messageCount: 4 }], NOW);
		const plan = planExport([th], { t1: 4 }, state, { now: NOW, stalenessMinutes: 30, minMessages: 2 });
		expect(plan.unchanged).toHaveLength(1);
		expect(plan.toExport).toHaveLength(0);
	});

	test('neue Nachrichten oder neues updatedAt fuehren zu Re-Export', () => {
		const th = thread('t1', 'Alt', NOW - 3_600_000);
		const state = nextState({ version: 1, threads: {} }, [{ thread: th, messageCount: 4 }], NOW);
		const grown = planExport([th], { t1: 7 }, state, { now: NOW, stalenessMinutes: 30, minMessages: 2 });
		expect(grown.toExport).toHaveLength(1);

		const bumped = thread('t1', 'Alt', NOW - 1_800_000);
		const plan2 = planExport([bumped], { t1: 4 }, state, { now: NOW, stalenessMinutes: 30, minMessages: 2 });
		expect(plan2.toExport).toHaveLength(1);
	});

	test('forced (Include-Liste) ueberstimmt Live-Schutz und State', () => {
		const th = thread('t1', 'Live', NOW - 60_000);
		const state = nextState({ version: 1, threads: {} }, [{ thread: th, messageCount: 4 }], NOW);
		const plan = planExport([th], { t1: 4 }, state, { now: NOW, stalenessMinutes: 30, minMessages: 2 }, ['t1']);
		expect(plan.forced).toHaveLength(1);
		expect(plan.toExport).toHaveLength(1);
	});

	test('Force-Flag exportiert auch State-Treffer erneut', () => {
		const th = thread('t1', 'Alt', NOW - 3_600_000);
		const state = nextState({ version: 1, threads: {} }, [{ thread: th, messageCount: 4 }], NOW);
		const plan = planExport([th], { t1: 4 }, state, { now: NOW, stalenessMinutes: 30, minMessages: 2 }, [], true);
		expect(plan.unchanged).toHaveLength(0);
		expect(plan.toExport).toHaveLength(1);
	});
});

describe('nextState', () => {
	test('aktualisiert Eintraege ohne andere zu verlieren', () => {
		const a = thread('a', 'A', NOW - 1000);
		const b = thread('b', 'B', NOW - 2000);
		let state = nextState({ version: 1, threads: {} }, [{ thread: a, messageCount: 2 }], NOW - 5000);
		state = nextState(state, [{ thread: b, messageCount: 3 }], NOW);
		expect(Object.keys(state.threads).sort()).toEqual(['a', 'b']);
		expect(state.threads['b']?.exportedAt).toBe(NOW);
		expect(transcriptFileName(a)).toBe('a-' + a.id.slice(0, 8) + '.md');
	});
});

describe('fmtTs', () => {
	test('formatiert ISO-kompakt ohne Sekunden', () => {
		expect(fmtTs(Date.UTC(2026, 8, 26, 12, 34, 56))).toBe('2026-09-26 12:34');
	});
});
