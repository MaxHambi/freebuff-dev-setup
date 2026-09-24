// Prueft, dass der CHANGELOG.md den Code-Aenderungen folgt:
// 1. Gibt es neue Commits mit nutzerrelevanten Typen (feat/fix), muss der
//    Unreleased-Abschnitt einen Eintrag enthalten, dessen Issue-/PR-Referenz
//    oder Schluesseiworte zu einem der Commit-Subjects passt.
// 2. Der Unreleased-Abschnitt muss existieren und darf nicht leer sein,
//    wenn feat/fix-Commits vorliegen.
// Aufruf: bun run skills-manager/scripts/check-changelog.ts --base origin/master

import { execSync } from "node:child_process";
import { readFileSync } from "node:fs";

function git(args: string): string {
	return execSync(`git ${args}`, { encoding: "utf8" }).trim();
}

const baseArgIdx = process.argv.indexOf("--base");
const base = baseArgIdx !== -1 ? (process.argv[baseArgIdx + 1] ?? "") : "";

let subjects: string[] = [];
if (base) {
	try {
		git(`rev-parse --verify ${base}`);
		subjects = git(`log ${base}..HEAD --pretty=%s`).split("\n").filter(Boolean);
	} catch {
		console.log(`Basis-Ref ${base} nicht gefunden - CHANGELOG-Check uebersprungen.`);
		process.exit(0);
	}
} else {
	subjects = git("log -20 --pretty=%s").split("\n").filter(Boolean);
}

const relevant = subjects.filter(
	(s) => /^(feat|fix)(\(|:|!)/.test(s) && !s.startsWith("Merge "),
);

if (relevant.length === 0) {
	console.log("Keine feat/fix-Commits seit Basis - CHANGELOG-Update nicht zwingend.");
	process.exit(0);
}

let changelog: string;
try {
	changelog = readFileSync("CHANGELOG.md", "utf8");
} catch {
	console.error("FEHLER: feat/fix-Commits vorhanden, aber CHANGELOG.md fehlt.");
	process.exit(1);
}

// Unreleased-Abschnitt extrahieren (bis zur naechsten Versionsueberschrift oder EOF)
const unreleasedMatch = /##\s*\[Unreleased\]([\s\S]*?)(?=\n##\s*\[|$)/.exec(changelog);
if (!unreleasedMatch) {
	console.error("FEHLER: CHANGELOG.md enthaelt keinen [Unreleased]-Abschnitt.");
	process.exit(1);
}
const unreleased = unreleasedMatch[1] ?? "";

// Jede relevante Commit-Aenderung muss im Unreleased-Block vertreten sein.
// Heuristik: Issue-Referenz (#n) des Commit-Subjects oder markante Woerter (>= 6 Zeichen,
// nicht Stopword) muessen im Block vorkommen.
const STOPWORDS = new Set([
	"added","added:","und","oder","der","die","das","fuer","mit","von","auf","im","in","ein","eine",
	"package","package.json","scripts","skills-manager","datei","dateien","wieder","update","update:","feature","features","changelog","anlegen","ergaenzen","klassifizierung","analyse","dokumentation","dokumentiere","geruest","projektgeruest","issue","tracker","konfig"
]);

const failures: string[] = [];
for (const subject of relevant) {
	const issueRef = /#(\d+)/.exec(subject);
	if (issueRef && unreleased.includes(issueRef[0])) continue;

	const cleaned = subject
		.replace(/^(feat|fix)(\([\w./-]+\))?(!)?:\s*/i, "")
		.toLowerCase();
	const words = cleaned
		.split(/[^a-z0-9äöüß-]+/)
		.filter((w) => w.length >= 7 && !STOPWORDS.has(w));
	const hit = words.some((w) => unreleased.toLowerCase().includes(w));
	if (!hit) {
		failures.push(subject);
	}
}

if (failures.length > 0) {
	console.error("FEHLER: Folgende Commits sind nicht im [Unreleased]-Abschnitt vertreten:");
	for (const f of failures) console.error(`  - ${f}`);
	console.error("\nBitte im CHANGELOG.md unter [Unreleased] ergaenzen (Issue-Referenz #n hilft).");
	process.exit(1);
}

console.log(`OK: CHANGELOG deckt ${relevant.length} feat/fix-Commit(s) ab.`);
