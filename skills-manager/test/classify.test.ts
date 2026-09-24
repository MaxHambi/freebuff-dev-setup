import { describe, expect, test } from 'bun:test';

import { classify, normalizeRisk } from '../src/classify.ts';

const BASE = {
	id: 'demo',
	container: '',
	looksBinary: false,
	missingLocalRefs: [] as string[],
	presentFiles: [] as string[],
	now: new Date('2026-09-24T00:00:00'),
};

describe('classify', () => {
	test('date_added aelter als 6 Monate -> stale', () => {
		const result = classify({
			...BASE,
			content: '---\nname: old\ndate_added: 2026-02-01\n---\nBody',
		});
		expect(result.flags).toContain('stale');
		expect(result.reasons[0]).toContain('aelter');
	});

	test('date_added innerhalb 6 Monate -> nicht stale', () => {
		const result = classify({
			...BASE,
			content: '---\nname: fresh\ndate_added: 2026-07-01\n---\nBody',
		});
		expect(result.flags).not.toContain('stale');
	});

	test('deprecated-Marker im Text -> stale', () => {
		const result = classify({
			...BASE,
			content:
				'---\nname: dep\n---\nThis skill is deprecated, use the new one.',
		});
		expect(result.flags).toContain('stale');
	});

	test('legacy-Marker im Text -> stale', () => {
		const result = classify({
			...BASE,
			content: 'Legacy workflow, kept for reference.',
		});
		expect(result.flags).toContain('stale');
	});

	test('fehlende lokale Referenz -> incompat', () => {
		const result = classify({
			...BASE,
			content: 'Run `python scripts/foo.py` to start.',
			missingLocalRefs: ['scripts/foo.py'],
		});
		expect(result.flags).toContain('incompat');
	});

	test('Binaer-Anteile -> incompat', () => {
		const result = classify({ ...BASE, content: 'x', looksBinary: true });
		expect(result.flags).toContain('incompat');
	});

	test('API-Key-Erwaehnung -> setup', () => {
		const result = classify({
			...BASE,
			content: 'Set the OPENAI_API_KEY environment variable before use.',
		});
		expect(result.flags).toContain('setup');
	});

	test('requirements.txt -> setup', () => {
		const result = classify({
			...BASE,
			content: 'plain',
			presentFiles: ['requirements.txt'],
		});
		expect(result.flags).toContain('setup');
	});

	test('paketloses skill ohne flags', () => {
		const result = classify({
			...BASE,
			content:
				'---\nname: clean\nrisk: safe\ndate_added: 2026-09-01\n---\nJust read this.',
		});
		expect(result.flags).toEqual([]);
	});
});

describe('normalizeRisk', () => {
	test('mappt quoted und unquoted Werte', () => {
		expect(normalizeRisk('safe')).toBe('safe');
		expect(normalizeRisk('"safe"')).toBe('safe');
		expect(normalizeRisk('critical')).toBe('critical');
		expect(normalizeRisk('offensive')).toBe('offensive');
		expect(normalizeRisk('sonstwas')).toBe('unknown');
		expect(normalizeRisk(null)).toBe('unknown');
	});
});
