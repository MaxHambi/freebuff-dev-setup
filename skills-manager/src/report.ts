// Index- und Report-Erstellung: maschinenlesbares JSON + lesbares Markdown.

import type { SkillMeta, SkillsIndex } from './types.ts';

export function buildIndex(
	skills: SkillMeta[],
	skillsRoot: string,
	generatedAt: string,
): SkillsIndex {
	const stats = {
		total: skills.length,
		stale: skills.filter((s) => s.flags.includes('stale')).length,
		incompat: skills.filter((s) => s.flags.includes('incompat')).length,
		setup: skills.filter((s) => s.flags.includes('setup')).length,
		byRisk: {} as Record<string, number>,
	};
	for (const skill of skills) {
		stats.byRisk[skill.risk] = (stats.byRisk[skill.risk] ?? 0) + 1;
	}
	return { generatedAt, skillsRoot, skills, stats };
}

function countBy<T>(items: T[], key: (item: T) => string): Map<string, number> {
	const map = new Map<string, number>();
	for (const item of items) {
		const k = key(item);
		map.set(k, (map.get(k) ?? 0) + 1);
	}
	return map;
}

export function renderReport(index: SkillsIndex): string {
	const lines: string[] = [];
	const flagCount = (flag: string) =>
		index.skills.filter((s) => s.flags.includes(flag as never)).length;

	lines.push('# Skills-Bibliothek: Analyse-Report');
	lines.push('');
	lines.push(`- Generiert: ${index.generatedAt}`);
	lines.push(`- Skills-Root: ${index.skillsRoot}`);
	lines.push(`- Skills gesamt: ${index.stats.total}`);
	lines.push(`- Stale: ${flagCount('stale')}`);
	lines.push(`- Inkompatibel: ${flagCount('incompat')}`);
	lines.push(`- Setup noetig: ${flagCount('setup')}`);
	lines.push('');
	lines.push('## Risiko-Verteilung');
	lines.push('');
	lines.push('| Risiko | Anzahl |');
	lines.push('|--------|--------|');
	for (const [risk, count] of [...Object.entries(index.stats.byRisk)].sort(
		(a, b) => b[1] - a[1],
	)) {
		lines.push(`| ${risk} | ${count} |`);
	}
	lines.push('');
	lines.push('## Container & Auffaelligkeiten');
	lines.push('');
	const containers = countBy(
		index.skills.filter((s) => s.container !== ''),
		(s) => s.container,
	);
	if (containers.size > 0) {
		lines.push('| Container | Sub-Skills |');
		lines.push('|-----------|------------|');
		for (const [name, count] of [...containers.entries()].sort(
			(a, b) => b[1] - a[1],
		)) {
			lines.push(`| ${name} | ${count} |`);
		}
	}
	lines.push('');
	lines.push('## Skills mit Flags (Auszug, max. 50)');
	lines.push('');
	lines.push('| Skill | Flags | Gruende |');
	lines.push('|-------|-------|---------|');
	for (const skill of index.skills
		.filter((s) => s.flags.length > 0)
		.slice(0, 50)) {
		const reasons = skill.reasons[0] ?? '';
		lines.push(`| ${skill.relPath} | ${skill.flags.join(', ')} | ${reasons} |`);
	}
	lines.push('');
	return lines.join('\n');
}
