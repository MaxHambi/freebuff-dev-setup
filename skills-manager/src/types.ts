// Geteilte Typen des Skills-Managers.

export type StatusFlag = 'stale' | 'incompat' | 'setup';

export type RiskLevel = 'safe' | 'unknown' | 'critical' | 'offensive' | 'none';

export interface SkillMeta {
	// Ordnername unter dem Skills-Root (eindeutige ID)
	id: string;
	// Ordner, in dem der Skill liegt (Container oder "")
	container: string;
	name: string;
	description: string;
	category: string | null;
	risk: RiskLevel;
	// ISO-Datum oder null, wenn kein date_added vorhanden ist
	dateAdded: string | null;
	// ISO-8601-Zeitstempel der Analyse
	analyzedAt: string;
	// Hash des SKILL.md-Inhalts (sha-256, hex, 16 Zeichen)
	contentHash: string;
	// Klassifizierung; leere Liste = unauffaellig
	flags: StatusFlag[];
	// Maschinenlesbare Gruende zu den Flags
	reasons: string[];
	// Absolute-quellpfad-freie relative Referenz (container/id)
	relPath: string;
}

export interface SkillsIndex {
	// ISO-8601-Zeitstempel der letzten vollstaendigen/neuen Indexerstellung
	generatedAt: string;
	// Wurzel der analysierten Bibliothek
	skillsRoot: string;
	skills: SkillMeta[];
	stats: {
		total: number;
		stale: number;
		incompat: number;
		setup: number;
		byRisk: Record<string, number>;
	};
}

// Eintrag der State-Datei fuer Delta-Erkennung
export interface StateEntry {
	// Mtime in Millisekunden
	mtimeMs: number;
	size: number;
	contentHash: string;
	// Flags aus der letzten Klassifizierung (fuer schnelle Reports)
	flags: StatusFlag[];
}

export interface SkillsState {
	// ISO-8601-Zeitstempel der letzten Aktualisierung
	updatedAt: string;
	skillsRoot: string;
	// Schluessel: container/id bzw. id
	skills: Record<string, StateEntry>;
}

export interface ScanIssue {
	// relativ zum Skills-Root
	relPath: string;
	reason: string;
}

export interface ScanResult {
	// Alle gültigen Skills (mit SKILL.md)
	skills: SkillMeta[];
	// Ordner ohne SKILL.md (Container wie libreoffice/ oder defekt)
	nonSkillDirs: { relPath: string; isContainer: boolean }[];
	// Fehler waehrend des Scans
	issues: ScanIssue[];
}
