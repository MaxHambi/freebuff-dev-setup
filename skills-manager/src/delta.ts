// Delta-Vergleich: alter State + aktueller Scan -> Delta-Auftraege.
// Pure Logik ohne fs.watch und ohne Timing: testbar und im CLI und TUI nutzbar.

import type { SkillMeta, SkillsState, StateEntry } from './types.ts';
import { hashContent } from './scan.ts';

export type DeltaKind =
	| 'added'
	| 'changed'
	| 'deleted'
	| 'renamed'
	| 'unchanged';

export interface DeltaEntry {
	kind: DeltaKind;
	// aktueller Schluessel (bei renamed: der neue)
	key: string;
	// nur bei renamed: der alte Schluessel
	oldKey?: string;
	// aktueller Skill (nicht bei deleted)
	skill?: SkillMeta;
}

export interface DeltaResult {
	entries: DeltaEntry[];
	added: DeltaEntry[];
	changed: DeltaEntry[];
	deleted: DeltaEntry[];
	renamed: DeltaEntry[];
	unchangedCount: number;
}

export function buildState(
	skills: SkillMeta[],
	skillsRoot: string,
): SkillsState {
	const skillMap: Record<string, StateEntry> = {};
	for (const skill of skills) {
		skillMap[skill.relPath] = {
			mtimeMs: 0,
			size: 0,
			contentHash: skill.contentHash,
			flags: skill.flags,
		};
	}
	return {
		updatedAt: new Date().toISOString(),
		skillsRoot,
		skills: skillMap,
	};
}

export function computeDelta(
	previous: SkillsState,
	current: SkillMeta[],
): DeltaResult {
	const prevKeys = new Set(Object.keys(previous.skills));

	// Hash -> key Index des alten States fuer Move-Erkennung
	const byHash = new Map<string, string>();
	for (const [key, entry] of Object.entries(previous.skills)) {
		if (!byHash.has(entry.contentHash)) byHash.set(entry.contentHash, key);
	}

	const entries: DeltaEntry[] = [];
	const added: DeltaEntry[] = [];
	const changed: DeltaEntry[] = [];
	const deleted: DeltaEntry[] = [];
	const renamed: DeltaEntry[] = [];
	let unchangedCount = 0;

	for (const skill of current) {
		const prev = previous.skills[skill.relPath];
		if (prev) {
			prevKeys.delete(skill.relPath);
			if (prev.contentHash === skill.contentHash) {
				unchangedCount++;
				entries.push({ kind: 'unchanged', key: skill.relPath, skill });
			} else {
				const entry: DeltaEntry = {
					kind: 'changed',
					key: skill.relPath,
					skill,
				};
				entries.push(entry);
				changed.push(entry);
			}
			continue;
		}

		// Move-Erkennung: gleicher Hash unter neuem Schluessel
		const oldKey = byHash.get(skill.contentHash);
		if (oldKey !== undefined && prevKeys.has(oldKey)) {
			prevKeys.delete(oldKey);
			const entry: DeltaEntry = {
				kind: 'renamed',
				key: skill.relPath,
				oldKey,
				skill,
			};
			entries.push(entry);
			renamed.push(entry);
			continue;
		}

		const entry: DeltaEntry = { kind: 'added', key: skill.relPath, skill };
		entries.push(entry);
		added.push(entry);
	}

	// Alles, was im alten State war und jetzt fehlt (und nicht als Rename-Quelle
	// verbraucht wurde), ist geloescht.
	for (const key of prevKeys) {
		const entry: DeltaEntry = { kind: 'deleted', key };
		entries.push(entry);
		deleted.push(entry);
	}

	return { entries, added, changed, deleted, renamed, unchangedCount };
}

export { hashContent };
