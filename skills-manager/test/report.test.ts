import { describe, expect, test } from 'bun:test';

import { buildIndex, renderReport } from '../src/report.ts';
import type { SkillMeta } from '../src/types.ts';

function skill(overrides: Partial<SkillMeta>): SkillMeta {
	return {
		id: 's',
		container: '',
		name: 's',
		description: 'd',
		category: null,
		risk: 'safe',
		dateAdded: null,
		analyzedAt: '2026-09-24T00:00:00.000Z',
		contentHash: 'abc123',
		flags: [],
		reasons: [],
		relPath: 's',
		...overrides,
	};
}

describe('buildIndex', () => {
	test('zaehlt Flags und Risiken korrekt', () => {
		const index = buildIndex(
			[
				skill({ id: 'a', relPath: 'a', flags: ['stale'], risk: 'safe' }),
				skill({
					id: 'b',
					relPath: 'b',
					flags: ['stale', 'setup'],
					risk: 'critical',
				}),
				skill({ id: 'c', relPath: 'c', flags: [], risk: 'unknown' }),
			],
			'/tmp/root',
			'2026-09-24T00:00:00.000Z',
		);
		expect(index.stats.total).toBe(3);
		expect(index.stats.stale).toBe(2);
		expect(index.stats.setup).toBe(1);
		expect(index.stats.incompat).toBe(0);
		expect(index.stats.byRisk.safe).toBe(1);
		expect(index.stats.byRisk.critical).toBe(1);
	});
});

describe('renderReport', () => {
	test('enthaelt Kopfzahlen und Flag-Auszug', () => {
		const index = buildIndex(
			[
				skill({
					id: 'a',
					relPath: 'a',
					flags: ['stale'],
					reasons: ['zu alt'],
					risk: 'safe',
				}),
				skill({
					id: 'b',
					relPath: 'b',
					container: 'libreoffice',
					relPathAlt: undefined,
				} as never),
			],
			'/tmp/root',
			'2026-09-24T00:00:00.000Z',
		);
		const md = renderReport(index);
		expect(md).toContain('# Skills-Bibliothek: Analyse-Report');
		expect(md).toContain('Stale: 1');
		expect(md).toContain('| a | stale | zu alt |');
		expect(md).toContain('libreoffice');
	});
});
