// Klassifizierung: stale / incompatible / needs-setup.
// Pure Funktionen ohne Dateisystem-Zugriff; das Scannen liefert die Rohdaten.

import type { RiskLevel, SkillMeta, StatusFlag } from './types.ts';

// Skills, die aelter als STALE_MONTHS Monate sind, gelten als veraltet
export const STALE_MONTHS = 6;

const DEPRECATED_MARKERS =
	/\b(deprecated|superseded|archived|do not use|no longer (maintained|supported|used))\b/i;
const LEGACY_MARKER = /\blegacy\b/i;

const SETUP_PATTERNS: { re: RegExp; reason: string }[] = [
	{
		re: /\b(api[_ -]?key|api[_ -]?token|access[_ -]?token|secret[_ -]?key|bearer[_ -]?token)\b/i,
		reason: 'API-Key/Token erwaehnt',
	},
	{
		re: /\b(ANTHROPIC_API_KEY|OPENAI_API_KEY|GITHUB_TOKEN|API_KEY|API_TOKEN|SECRET_TOKEN)\b/,
		reason: 'API-Key-Env-Variable erwaehnt',
	},
	{
		re: /\bMCP\b.+\b(setup|server|install|configur)/i,
		reason: 'MCP-Server-Setup erwaehnt',
	},
	{
		re: /\bMCP (server|config)/i,
		reason: 'MCP-Server erwaehnt',
	},
	{
		re: /\bpip install\b|\buv pip\b|\bun install\b --/,
		reason: 'pip-Installation noetig',
	},
];

const RISK_LEVELS: RiskLevel[] = [
	'safe',
	'unknown',
	'critical',
	'offensive',
	'none',
];

export function normalizeRisk(raw: string | null): RiskLevel {
	if (raw === null) return 'unknown';
	const cleaned = raw.toLowerCase().replace(/[^a-z]/g, '');
	const hit = RISK_LEVELS.find((level) => level === cleaned);
	return hit ?? 'unknown';
}

export interface ClassifyInput {
	id: string;
	container: string;
	content: string;
	// Unicode-Replacement-Character-Anteil als Signal fuer Binaer-Muell
	looksBinary: boolean;
	// relative Pfade, die im Text als lokale Skript-/Doc-Referenz vorkommen, mit Existenz-Info
	missingLocalRefs: string[];
	// Dateien im Skill-Ordner (relative Namen), fuer requirements.txt/package.json
	presentFiles: string[];
	// Referenzdatum fuer die Stale-Bewertung; Default: jetzt
	now?: Date;
}

export function classify(input: ClassifyInput): {
	flags: StatusFlag[];
	reasons: string[];
} {
	const flags: StatusFlag[] = [];
	const reasons: string[] = [];
	const fmText = input.content;

	// --- stale ---
	let stale = false;
	const dateMatch = /date_added\s*:\s*['"]?(\d{4}-\d{2}-\d{2})['"]?/.exec(
		fmText,
	);
	if (dateMatch?.[1]) {
		const added = new Date(`${dateMatch[1]}T00:00:00`);
		const now = input.now ?? new Date();
		const monthsOld =
			(now.getFullYear() - added.getFullYear()) * 12 +
			(now.getMonth() - added.getMonth());
		if (!Number.isNaN(monthsOld) && monthsOld > STALE_MONTHS) {
			stale = true;
			reasons.push(
				`date_added ${dateMatch[1]} ist aelter als ${STALE_MONTHS} Monate`,
			);
		}
	}
	if (DEPRECATED_MARKERS.test(fmText) || LEGACY_MARKER.test(fmText)) {
		stale = true;
		reasons.push('Deprecated-/Legacy-Marker im Text');
	}
	if (stale) flags.push('stale');

	// --- incompatible ---
	let incompatible = false;
	if (input.looksBinary) {
		incompatible = true;
		reasons.push('SKILL.md enthaelt Binaer-Anteile (Replacement-Character)');
	}
	if (input.missingLocalRefs.length > 0) {
		incompatible = true;
		reasons.push(
			`Fehlende lokale Referenzen: ${input.missingLocalRefs.slice(0, 3).join(', ')}`,
		);
	}
	if (incompatible) flags.push('incompat');

	// --- needs-setup ---
	let setup = false;
	for (const pattern of SETUP_PATTERNS) {
		if (pattern.re.test(fmText)) {
			setup = true;
			reasons.push(pattern.reason);
			break;
		}
	}
	if (input.presentFiles.includes('requirements.txt')) {
		setup = true;
		reasons.push('requirements.txt vorhanden (Python-Abhaengigkeiten)');
	}
	if (input.presentFiles.includes('package.json')) {
		setup = true;
		reasons.push('package.json vorhanden (Node-Abhaengigkeiten)');
	}
	if (setup) flags.push('setup');

	return { flags, reasons };
}

export function extractRisk(content: string): RiskLevel {
	const match = /^risk\s*:\s*(.+)$/m.exec(content);
	return normalizeRisk(match?.[1]?.trim() ?? null);
}
