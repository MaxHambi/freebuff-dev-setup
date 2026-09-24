// Prueft, dass alle Commits seit dem Basis-Branch dem Conventional-Commits-Format folgen.
// Aufruf: bun run skills-manager/scripts/check-commits.ts --base origin/master
// Auf master-Push (kein Base-Ref im PR-Sinn) werden die letzten 20 Commits geprueft.

import { execSync } from "node:child_process";

const ALLOWED_TYPES = new Set([
	"feat",
	"fix",
	"refactor",
	"test",
	"docs",
	"chore",
	"build",
	"ci",
	"perf",
	"style",
	"revert",
]);

const PATTERN = /^(feat|fix|refactor|test|docs|chore|build|ci|perf|style|revert)(\([\w./-]+\))?(!)?: .+/;

function git(args: string): string {
	return execSync(`git ${args}`, { encoding: "utf8" }).trim();
}

function getCommits(base: string): string[] {
	// Subject-Zeile jedes Commits zwischen base und HEAD
	const range = base ? `${base}..HEAD` : "-20";
	if (base) {
		try {
			git(`rev-parse --verify ${base}`);
		} catch {
			console.error(`Basis-Ref ${base} nicht gefunden - ueberspringe Commit-Check.`);
			process.exit(0);
		}
		return git(`log ${range} --pretty=%s`).split("\n").filter(Boolean);
	}
	return git(`log ${range} --pretty=%s`).split("\n").filter(Boolean);
}

const baseArgIdx = process.argv.indexOf("--base");
const base = baseArgIdx !== -1 ? (process.argv[baseArgIdx + 1] ?? "") : "";
const subjects = getCommits(base);

if (subjects.length === 0) {
	console.log("Keine Commits zu pruefen.");
	process.exit(0);
}

const failures: string[] = [];
for (const subject of subjects) {
	// Merge-Commits ausnehmen
	if (subject.startsWith("Merge ") || subject.startsWith("Revert ")) continue;
	if (!PATTERN.test(subject)) {
		failures.push(subject);
	}
}

if (failures.length > 0) {
	console.error("Nicht konforme Commit-Subjects gefunden:");
	for (const f of failures) console.error(`  - ${f}`);
	console.error(
		`\nFormat: <type>(<scope>)?: <beschreibung>  mit type aus ${[...ALLOWED_TYPES].join("|")}`,
	);
	process.exit(1);
}

console.log(`OK: ${subjects.length} Commit(s) folgen Conventional Commits.`);
