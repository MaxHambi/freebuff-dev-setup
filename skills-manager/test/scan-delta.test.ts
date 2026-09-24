import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { buildState, computeDelta } from '../src/delta.ts';
import { scanSkillsRoot } from '../src/scan.ts';

let root: string;

beforeAll(async () => {
	root = await mkdtemp(join(tmpdir(), 'skills-manager-test-'));
	// Normaler Skill
	await mkdir(join(root, 'alpha'));
	await writeFile(
		join(root, 'alpha', 'SKILL.md'),
		'---\nname: alpha\ndescription: Test skill A\nrisk: safe\ndate_added: 2026-07-01\n---\nRead this.',
	);
	// Skill mit fehlender Referenz
	await mkdir(join(root, 'beta'));
	await writeFile(
		join(root, 'beta', 'SKILL.md'),
		'---\nname: beta\ndescription: B\nrisk: safe\n---\nRun `python scripts/tool.py`.',
	);
	// Skill mit API-Key
	await mkdir(join(root, 'gamma'));
	await writeFile(
		join(root, 'gamma', 'SKILL.md'),
		'---\nname: gamma\ndescription: G\n---\nSet OPENAI_API_KEY first.',
	);
	// Container mit Sub-Skills
	await mkdir(join(root, 'libreoffice', 'writer'), { recursive: true });
	await writeFile(
		join(root, 'libreoffice', 'writer', 'SKILL.md'),
		'---\nname: writer\ndescription: W\nrisk: safe\n---\nBody',
	);
	// Unvollstaendiger Ordner
	await mkdir(join(root, 'incomplete'));
	await writeFile(join(root, 'incomplete', 'notes.txt'), 'kein SKILL.md');
});

afterAll(async () => {
	await rm(root, { recursive: true, force: true });
});

describe('scanSkillsRoot', () => {
	test('findet Skills auf oberster Ebene und in Containern', async () => {
		const result = await scanSkillsRoot(root);
		const ids = result.skills.map((s) => s.relPath).sort();
		expect(ids).toEqual(['alpha', 'beta', 'gamma', 'libreoffice/writer']);
	});

	test('markiert unvollstaendige Ordner als Issue', async () => {
		const result = await scanSkillsRoot(root);
		expect(result.issues.some((i) => i.relPath === 'incomplete')).toBe(true);
	});

	test('klassifiziert fehlende Referenz als incompat', async () => {
		const result = await scanSkillsRoot(root);
		const beta = result.skills.find((s) => s.id === 'beta');
		expect(beta?.flags).toContain('incompat');
	});

	test('klassifiziert API-Key als setup', async () => {
		const result = await scanSkillsRoot(root);
		const gamma = result.skills.find((s) => s.id === 'gamma');
		expect(gamma?.flags).toContain('setup');
	});

	test('bricht mit verstaendlicher Meldung bei fehlendem Root', async () => {
		await expect(scanSkillsRoot(join(root, 'gibts-nicht'))).rejects.toThrow(
			/nicht lesbar/,
		);
	});
});

describe('computeDelta', () => {
	test('erkennt add, change, delete und rename', async () => {
		const first = await scanSkillsRoot(root);
		const state = buildState(first.skills, root);

		// alpha aendern, delta neu, umbrella loeschen+umbenennen simulieren
		await writeFile(
			join(root, 'alpha', 'SKILL.md'),
			'---\nname: alpha\ndescription: Geaendert\n---',
		);
		const renamedFrom = join(root, 'gamma');
		const renamedTo = join(root, 'gamma2');
		const { rename } = await import('node:fs/promises');
		await rename(renamedFrom, renamedTo);

		const second = await scanSkillsRoot(root);
		const delta = computeDelta(state, second.skills);

		expect(delta.added).toHaveLength(0);
		expect(delta.renamed.map((d) => d.key)).toEqual(['gamma2']);
		expect(delta.renamed[0]?.oldKey).toBe('gamma');
		expect(delta.changed.map((d) => d.key)).toEqual(['alpha']);
		expect(delta.unchangedCount).toBe(2); // beta + writer
	});

	test('zweiter Lauf ohne Aenderungen ergibt nur unchanged', async () => {
		const scan = await scanSkillsRoot(root);
		const state = buildState(scan.skills, root);
		const again = await scanSkillsRoot(root);
		const delta = computeDelta(state, again.skills);
		expect(delta.added).toHaveLength(0);
		expect(delta.changed).toHaveLength(0);
		expect(delta.deleted).toHaveLength(0);
		expect(delta.unchangedCount).toBe(scan.skills.length);
	});
});
