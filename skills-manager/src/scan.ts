// Scannt eine Skills-Bibliothek: liest SKILL.md-Dateien, prueft lokale Referenzen
// und liefert SkillMeta-Objekte plus Auffaelligkeiten. Injectables Root, damit
// Tests gegen tmp-Fixtures laufen.

import { createHash } from 'node:crypto';
import { readdir, readFile, stat } from 'node:fs/promises';
import { join, posix } from 'node:path';

import { classify, extractRisk } from './classify.ts';
import { parseFrontmatter } from './frontmatter.ts';
import type { ScanIssue, ScanResult, SkillMeta } from './types.ts';

// Container-Ordner: Gruppen-Container ohne eigenes SKILL.md, deren Kinder Skills sind
export const CONTAINER_HINTS = new Set([
	'libreoffice',
	'security',
	'sendblue',
	'agent-squad',
	'docs',
	'addyosmani',
]);

function hashContent(content: string): string {
	return createHash('sha256').update(content).digest('hex').slice(0, 16);
}

function looksBinary(content: string): boolean {
	if (content.length === 0) return false;
	const bad = (content.match(/\uFFFD/g) ?? []).length;
	return bad / content.length > 0.02;
}

// Lokale Referenzen in Markdown-Links und Script-Aufrufen pruefen
function findMissingLocalRefs(dir: string, content: string): Promise<string[]> {
	const refs = new Set<string>();
	for (const m of content.matchAll(
		/\]\(([^)#h]+?\.(?:md|mdx|py|ps1|sh|js|ts))\)/g,
	)) {
		refs.add(m[1] ?? '');
	}
	for (const m of content.matchAll(
		/(?:python3?|bash|sh|pwsh|powershell|node|bun|deno)\s+([\w./-]+\.(?:py|sh|ps1|js|mjs|cjs|ts))(?![\w])/g,
	)) {
		const ref = m[1] ?? '';
		// Externe Tool-Aufrufe ohne lokalen Ordnerbezug ignorieren
		if (ref.includes('..') || ref.startsWith('/') || ref.startsWith('$'))
			continue;
		refs.add(ref);
	}

	const checks = [...refs].map(async (ref) => {
		try {
			await stat(join(dir, ref));
			return null;
		} catch {
			return ref;
		}
	});
	return Promise.all(checks).then((results) =>
		results.filter((r): r is string => r !== null),
	);
}

async function listDirEntries(dir: string): Promise<string[]> {
	try {
		const entries = await readdir(dir, { withFileTypes: true });
		return entries.map((e) => e.name);
	} catch {
		return [];
	}
}

async function analyzeSkillDir(
	absDir: string,
	container: string,
	id: string,
	now: Date,
): Promise<SkillMeta | null> {
	const skillPath = join(absDir, 'SKILL.md');
	let content: string;
	try {
		content = await readFile(skillPath, 'utf8');
	} catch {
		return null;
	}

	const fm = parseFrontmatter(content);
	const files = await listDirEntries(absDir);
	const missingRefs = await findMissingLocalRefs(absDir, content);
	const { flags, reasons } = classify({
		id,
		container,
		content,
		looksBinary: looksBinary(content),
		missingLocalRefs: missingRefs,
		presentFiles: files,
		now,
	});

	return {
		id,
		container,
		name: fm.name ?? id,
		description: fm.description ?? '',
		category: fm.category,
		risk: extractRisk(content),
		dateAdded: fm.dateAdded,
		analyzedAt: now.toISOString(),
		contentHash: hashContent(content),
		flags,
		reasons,
		relPath: container ? posix.join(container, id) : id,
	};
}

export async function scanSkillsRoot(
	root: string,
	options: { now?: Date } = {},
): Promise<ScanResult> {
	const now = options.now ?? new Date();
	const issues: ScanIssue[] = [];
	const skills: SkillMeta[] = [];
	const nonSkillDirs: { relPath: string; isContainer: boolean }[] = [];

	let topEntries;
	try {
		topEntries = await readdir(root, { withFileTypes: true });
	} catch (error) {
		throw new Error(
			`Skills-Root nicht lesbar: ${root} (${error instanceof Error ? error.message : String(error)})`,
		);
	}

	// Ein Ebene oben: Skill-Ordner oder Container?
	// Container-Ordner enthalten Sub-Skills (eine Ebene tiefer).
	for (const entry of topEntries) {
		if (!entry.isDirectory() || entry.name.startsWith('.')) continue;

		const abs = join(root, entry.name);
		const hasSkillMd = await listDirEntries(abs).then((names) =>
			names.some((n) => n.toLowerCase() === 'skill.md'),
		);

		if (hasSkillMd) {
			const meta = await analyzeSkillDir(abs, '', entry.name, now);
			if (meta) skills.push(meta);
			continue;
		}

		// Kein SKILL.md: Container, wenn darunter Skill-Ordner liegen
		const children = await readdir(abs, { withFileTypes: true });
		const childSkillDirs = children.filter(
			(c) => c.isDirectory() && !c.name.startsWith('.'),
		);
		const isContainer = childSkillDirs.length > 0;

		if (!isContainer) {
			nonSkillDirs.push({ relPath: entry.name, isContainer: false });
			issues.push({
				relPath: entry.name,
				reason: 'Ordner ohne SKILL.md und ohne Sub-Skills (unvollstaendig)',
			});
			continue;
		}

		nonSkillDirs.push({ relPath: entry.name, isContainer: true });
		for (const child of childSkillDirs) {
			const meta = await analyzeSkillDir(
				join(abs, child.name),
				entry.name,
				child.name,
				now,
			);
			if (meta) {
				skills.push(meta);
			} else {
				issues.push({
					relPath: posix.join(entry.name, child.name),
					reason: 'Sub-Ordner eines Containers ohne SKILL.md',
				});
			}
		}
	}

	return { skills, nonSkillDirs, issues };
}

export { hashContent };
