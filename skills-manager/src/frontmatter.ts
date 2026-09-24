// Robuster Zeilen-Parser fuer SKILL.md-Frontmatter (bewusst ohne YAML-Dependency).
// Unterstuetzt die real vorkommenden Varianten:
//   name: foo              name: "foo"           name: 'foo'
//   date_added: 2026-07-01 date_added: "2026-07-01" date_added: '2026-03-06'
//   description: "Ein Text: mit Doppelpunkt"   description: 'Ein Text'
//   description: "Erste Zeile
//     zweite Zeile"                               (mehrzeilig, eingerueckt)
// CRLF wird normalisiert, BOM entfernt.

export interface Frontmatter {
	name: string | null;
	description: string | null;
	category: string | null;
	risk: string | null;
	dateAdded: string | null;
}

const KEYS = new Set(['name', 'description', 'category', 'risk', 'date_added']);

function stripQuotes(value: string): string {
	const trimmed = value.trim();
	if (
		(trimmed.startsWith('"') && trimmed.endsWith('"') && trimmed.length >= 2) ||
		(trimmed.startsWith("'") && trimmed.endsWith("'") && trimmed.length >= 2)
	) {
		return trimmed.slice(1, -1);
	}
	return trimmed;
}

export function parseFrontmatter(raw: string): Frontmatter {
	const normalized = raw.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n');
	const empty: Frontmatter = {
		name: null,
		description: null,
		category: null,
		risk: null,
		dateAdded: null,
	};
	if (!normalized.startsWith('---')) return empty;

	// Frontmatter-Block zwischen der ersten --- und der naechsten --- Zeile
	const afterOpen = normalized.slice(3).replace(/^-+\n/, '\n');
	const closeIdx = afterOpen.indexOf('\n---');
	const block = closeIdx === -1 ? afterOpen : afterOpen.slice(0, closeIdx);
	const lines = block.split('\n');

	const result: Frontmatter = { ...empty };
	const consumed = new Set<number>();

	for (let i = 0; i < lines.length; i++) {
		if (consumed.has(i)) continue;
		const line = lines[i] ?? '';

		const match =
			/^(name|description|category|risk|date_added)\s*:\s*(.*)$/i.exec(line);
		if (!match) continue;

		const key = match[1]?.toLowerCase();
		if (!key || !KEYS.has(key)) continue;
		let value = match[2] ?? '';
		let collectedMultiline = false;

		// Mehrzeilige Werte: einleitendes Anfuehrungszeichen ohne schliessendes
		// -> Folgezeilen bis zum schliessenden Anfuehrungszeichen einsammeln.
		const opensQuote =
			(value.startsWith('"') && !value.slice(1).endsWith('"')) ||
			(value.startsWith("'") && !value.slice(1).endsWith("'"));
		if (opensQuote) {
			const quote = value[0] ?? '"';
			let j = i + 1;
			for (; j < lines.length; j++) {
				const next = lines[j] ?? '';
				consumed.add(j);
				const cleaned = next
					.replace(/^\s+/, '')
					.replace(/["']\s*$/, '')
					.trimEnd();
				value += ` ${cleaned}`;
				if ((next ?? '').trimEnd().endsWith(quote)) break;
			}
			i = j; // eingesammelte Zeilen ueberspringen
			collectedMultiline = true;
		}

		if (collectedMultiline) {
			value = value.replace(/^['"]/, '');
		}
		const finalValue = stripQuotes(value) || null;
		switch (key) {
			case 'name':
				result.name = finalValue;
				break;
			case 'description':
				result.description = finalValue;
				break;
			case 'category':
				result.category = finalValue;
				break;
			case 'risk':
				result.risk = finalValue;
				break;
			case 'date_added':
				result.dateAdded = finalValue;
				break;
		}
	}

	return result;
}
