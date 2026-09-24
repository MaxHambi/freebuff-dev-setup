import { describe, expect, test } from 'bun:test';

import { parseFrontmatter } from '../src/frontmatter.ts';

describe('parseFrontmatter', () => {
	test('liest die Standard-Variante (unquoted)', () => {
		const fm = parseFrontmatter(
			'---\nname: agents-md\ndescription: Erzeugt AGENTS.md\ncategory: development\nrisk: safe\ndate_added: 2026-07-01\n---\n\n# Inhalt',
		);
		expect(fm.name).toBe('agents-md');
		expect(fm.description).toBe('Erzeugt AGENTS.md');
		expect(fm.category).toBe('development');
		expect(fm.risk).toBe('safe');
		expect(fm.dateAdded).toBe('2026-07-01');
	});

	test('liest quoted Varianten mit Doppel- und Einfachzitat', () => {
		const fm = parseFrontmatter(
			'---\nname: \'007\'\ndescription: "Security audit, hardening (STRIDE/PASTA)"\nrisk: "safe"\ndate_added: \'2026-03-06\'\n---\nBody',
		);
		expect(fm.name).toBe('007');
		expect(fm.description).toBe('Security audit, hardening (STRIDE/PASTA)');
		expect(fm.risk).toBe('safe');
		expect(fm.dateAdded).toBe('2026-03-06');
	});

	test('verbindet mehrzeilige (eingerueckte) Descriptions', () => {
		const fm = parseFrontmatter(
			'---\nname: x\ndescription: "Erste Zeile\n  zweite Zeile"\n---\nBody',
		);
		expect(fm.description).toBe('Erste Zeile zweite Zeile');
	});

	test('beschreibt CRLF und BOM korrekt', () => {
		const fm = parseFrontmatter(
			'\uFEFF---\r\nname: crlf-skill\r\ndescription: Windows-Zeilenden\r\n---\r\nBody',
		);
		expect(fm.name).toBe('crlf-skill');
		expect(fm.description).toBe('Windows-Zeilenden');
	});

	test('Doppelpunkt im Description-Wert bricht nichts', () => {
		const fm = parseFrontmatter(
			'---\nname: x\ndescription: "Wichtig: hier kommt der Punkt"\n---\nBody',
		);
		expect(fm.description).toBe('Wichtig: hier kommt der Punkt');
	});

	test('fehlende Felder bleiben null', () => {
		const fm = parseFrontmatter('---\nname: nur-name\n---\nBody');
		expect(fm.name).toBe('nur-name');
		expect(fm.description).toBeNull();
		expect(fm.category).toBeNull();
		expect(fm.risk).toBeNull();
		expect(fm.dateAdded).toBeNull();
	});
});
