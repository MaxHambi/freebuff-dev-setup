# API-Referenz: Skills-Manager Lib

Öffentliche Funktionen der Kernmodule (Slice 1). Alle Funktionen sind
TypeScript-first mit strikten Typen;(fs-Zugriffe sind über Root-Parameter injiziert).

## `frontmatter.ts`

### `parseFrontmatter(raw: string): Frontmatter`

Parst den YAML-ähnlichen Frontmatter-Block eines SKILL.md.

```ts
interface Frontmatter {
	name: string | null;
	description: string | null;
	category: string | null;
	risk: string | null;
	dateAdded: string | null; // YYYY-MM-DD
}
```

- Tolerant gegenüber: `"`- und `'`-Quotes, mehrzeiligen Werten, CRLF, BOM
- Fehlende Felder sind `null`, nie `undefined`

## `classify.ts`

### `classify(input: ClassifyInput): { flags: StatusFlag[]; reasons: string[] }`

```ts
interface ClassifyInput {
	id: string;
	container: string;
	content: string;          // SKILL.md-Inhalt
	looksBinary: boolean;     // Replacement-Character-Signal
	missingLocalRefs: string[]; // Referenzen, die nicht existieren
	presentFiles: string[];   // Dateinamen im Skill-Ordner
	now?: Date;               // Stichtag für stale (Default: jetzt)
}
```

Konstante `STALE_MONTHS = 6`.

### `normalizeRisk(raw: string | null): RiskLevel`

Normalisiert auf `safe | unknown | critical | offensive | none`; Unbekanntes → `unknown`.

### `extractRisk(content: string): RiskLevel`

Zieht `risk:` aus dem Frontmatter-Block und normalisiert es.

## `scan.ts`

### `scanSkillsRoot(root: string, options?: { now?: Date }): Promise<ScanResult>`

```ts
interface ScanResult {
	skills: SkillMeta[];                       // alle gültigen Skills
	nonSkillDirs: { relPath: string; isContainer: boolean }[];
	issues: ScanIssue[];                       // Ordner ohne SKILL.md etc.
}
```

- Läuft zwei Ebenen: Top-Level-Skills und Container-Ordner mit Sub-Skills
- Wirft `Error` mit klarer Meldung, wenn der Root nicht lesbar ist
- `SkillMeta.relPath` ist `container/id` bzw. `id` – der stabile Schlüssel überall sonst

### `hashContent(content: string): string`

SHA-256, erste 16 Hex-Zeichen – die Content-Identität für Delta und Move-Erkennung.

## `delta.ts`

### `buildState(skills: SkillMeta[], skillsRoot: string): SkillsState`

Erzeugt den State-Snapshot (Hash pro Skill) für den nächsten Lauf.

### `computeDelta(previous: SkillsState, current: SkillMeta[]): DeltaResult`

```ts
interface DeltaResult {
	entries: DeltaEntry[];   // alle, inkl. unchanged
	added: DeltaEntry[];
	changed: DeltaEntry[];
	deleted: DeltaEntry[];   // nur key gesetzt
	renamed: DeltaEntry[];   // key = neu, oldKey = alt
	unchangedCount: number;
}
```

Rein funktional – kein Dateisystem, kein Timing, dadurch deterministisch testbar.

## `report.ts`

### `buildIndex(skills: SkillMeta[], skillsRoot: string, generatedAt: string): SkillsIndex`

Baut den serialisierbaren Index inkl. Statistik (Flags, Risiko-Verteilung).

### `renderReport(index: SkillsIndex): string`

Erzeugt den Markdown-Report (Kopfzahlen, Risiko-Tabelle, Container, max. 50 Flag-Zeilen).

## `analyze.ts`

### `analyze(root: string, options?: { stateFile?: string }): Promise<AnalyzeResult>`

Orchestriert Scan → Delta → Index. `delta` ist `null`, wenn kein passender
Vorläufer-State existiert (anderer Root oder Erstlauf).

### `writeArtifacts(result: AnalyzeResult, options?: { dataDir?: string })`

Schreibt `skills.json`, `REPORT.md`, `state.json` und liefert die Pfade zurück.

### `loadState(stateFile?): Promise<SkillsState | null>`

Lädt den State oder `null` bei Fehlen/Korruption.

### CLI

```
bun run skills-manager/src/analyze.ts [--root <pfad>] [--quiet]
```
