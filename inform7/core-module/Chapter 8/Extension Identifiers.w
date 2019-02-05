[Extensions::IDs::] Extension Identifiers.

To store, hash code and compare title/author pairs used to identify
extensions which, though installed, are not necessarily used in the present
source text.

@h Definitions.

@ Extensions are identified by the pair of title and author name, each of
which is an ISO Latin-1 string limited in length, with certain bad-news
characters excluded (such as |/| and |:|) so that they can be used
directly in filenames. However, we will not want to compare these by
string comparison: so we hash-code the combination for speed. The
following structure holds a combination of the textual names and the
hash code:

=
typedef struct extension_identifier {
	struct text_stream *author_name;
	struct text_stream *raw_author_name;
	struct text_stream *title;
	struct text_stream *raw_title;
	int extension_id_hash_code; /* hash code derived from the above */
} extension_identifier;

@ Each EID is given a hash code -- an integer between 0 and the following
constant minus 1, derived from its title and author name.

@d EI_HASH_CODING_BASE 499

@ EIDs are created with one of the following contexts:

@d NO_EIDB_CONTEXTS 5
@d LOADED_EIDBC 0
@d INSTALLED_EIDBC 1
@d DICTIONARY_REFERRED_EIDBC 2
@d HYPOTHETICAL_EIDBC 3
@d USEWITH_EIDBC 4

=
typedef struct extension_identifier_database_entry {
	struct extension_identifier *eide_id;
	struct extension_identifier_database_entry *hash_next; /* next one in hashed EID database */
	int incidence_count[NO_EIDB_CONTEXTS];
	struct text_stream *last_usage_date;
	struct text_stream *sort_usage_date;
	struct text_stream *word_count_text;
	int word_count_number;
} extension_identifier_database_entry;

@

@d EXTENSIONS_PRESENT

@ Each EID structure is written only once, and its title and author name are
not subsequently altered. We therefore hash-code on arrival. As when
hashing vocabulary, we apply the X 30011 algorithm, this time with 499
(coprime to 30011) as base, to the text of the Unix-style pathname
|Author/Title|.

It is important that no EID structure ever be modified or destroyed once
created, so it must not be stored inside a transient data structure like a
|specification|.

Though it is probably the case that the author name and title supplied are
already of normalised casing, we do not want to rely on that. EIDs of the
same extension but named with different casing conventions would fail to
match: and this could happen if a new build of NI were published which
made a subtle change to the casing conventions, but which continued to use
an extension dictionary file first written by previous builds under the
previous conventions.

=
void Extensions::IDs::new(extension_identifier *eid, text_stream *an, text_stream *ti, int context) {
	eid->raw_author_name = Str::duplicate(an);
	eid->author_name = Str::duplicate(an);
	eid->raw_title = Str::duplicate(ti);
	eid->title = Str::duplicate(ti);
	Extensions::IDs::normalise_casing(eid->author_name);
	Extensions::IDs::normalise_casing(eid->title);

	unsigned int hc = 0;
	LOOP_THROUGH_TEXT(pos, eid->author_name)
		hc = hc*30011 + (unsigned int) Str::get(pos);
	hc = hc*30011 + (unsigned int) '/';
	LOOP_THROUGH_TEXT(pos, eid->title)
		hc = hc*30011 + (unsigned int) Str::get(pos);
	hc = hc % EI_HASH_CODING_BASE;
	eid->extension_id_hash_code = (int) hc;

	Extensions::IDs::add_EID_to_database(eid, context);
}

void Extensions::IDs::set_raw(extension_identifier *eid, text_stream *raw_an, text_stream *raw_ti) {
	eid->raw_author_name = Str::duplicate(raw_an);
	eid->raw_title = Str::duplicate(raw_ti);
}

void Extensions::IDs::write_to_HTML_file(OUTPUT_STREAM, extension_identifier *eid, int fancy) {
	WRITE("%S", eid->raw_title);
	if (fancy) HTML::begin_colour(OUT, I"404040");
	WRITE(" by ");
	if (fancy) HTML::end_colour(OUT);
	WRITE("%S", eid->raw_author_name);
}

void Extensions::IDs::write_link_to_HTML_file(OUTPUT_STREAM, extension_identifier *eid) {
	HTML_OPEN_WITH("a", "href='Extensions/%S/%S.html' style=\"text-decoration: none\"",
		eid->author_name, eid->title);
	HTML::begin_colour(OUT, I"404040");
	if (Extensions::IDs::is_standard_rules(eid)) WRITE("%S", eid->title);
	else Extensions::IDs::write_to_HTML_file(OUT, eid, FALSE);
	HTML::end_colour(OUT);
	HTML_CLOSE("a");
}

void Extensions::IDs::writer(OUTPUT_STREAM, char *format_string, void *vE) {
	extension_identifier *eid = (extension_identifier *) vE;
	switch (format_string[0]) {
		case '<':
			if (eid == NULL) WRITE("source text");
			else {
				WRITE("%S", eid->raw_title);
				if (Extensions::IDs::is_standard_rules(eid) == FALSE)
					WRITE(" by %S", eid->raw_author_name);
			}
			break;
		case 'X':
			if (eid == NULL) WRITE("<no extension>");
			else WRITE("%S by %S", eid->raw_title, eid->raw_author_name);
			break;
		default:
			internal_error("bad %X extension");
	}
}

@ Two EIDs with different hash codes definitely identify different extensions;
if the code is the same, we must use |strcmp| on the actual title and author
name. This is in effect case insensitive, since we normalised casing when
the EIDs were created.

(Note that this is not a lexicographic function suitable for sorting
EIDs into alphabetical order: it cannot be, since the hash code is not
order-preserving. To emphasise this we return true or false rather than a
|strcmp|-style delta value. For |Extensions::IDs::compare|, see below...)

=
int Extensions::IDs::match(extension_identifier *eid1, extension_identifier *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad eid match");
	if (eid1->extension_id_hash_code != eid2->extension_id_hash_code) return FALSE;
	if (Str::eq(eid1->author_name, eid2->author_name) == FALSE) return FALSE;
	if (Str::eq(eid1->title, eid2->title) == FALSE) return FALSE;
	return TRUE;
}

@ These are quite a deal slower, but trichotomous.

=
int Extensions::IDs::compare(extension_identifier *eid1, extension_identifier *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad eid match");
	int d = Str::cmp(eid1->author_name, eid2->author_name);
	if (d != 0) return d;
	return Str::cmp(eid1->title, eid2->title);
}

int Extensions::IDs::compare_by_title(extension_identifier *eid1, extension_identifier *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad eid match");
	int d = Str::cmp(eid1->title, eid2->title);
	if (d != 0) return d;
	return Str::cmp(eid1->author_name, eid2->author_name);
}

int Extensions::IDs::compare_by_date(extension_identifier *eid1, extension_identifier *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad eid match");
	int d = Str::cmp(Extensions::IDs::get_sort_date(eid2), Extensions::IDs::get_sort_date(eid1));
	if (d != 0) return d;
	d = Str::cmp(eid1->title, eid2->title);
	if (d != 0) return d;
	return Str::cmp(eid1->author_name, eid2->author_name);
}

int Extensions::IDs::compare_by_length(extension_identifier *eid1, extension_identifier *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad eid match");
	int d = Str::cmp(Extensions::IDs::get_sort_word_count(eid2), Extensions::IDs::get_sort_word_count(eid1));
	if (d != 0) return d;
	d = Str::cmp(eid1->title, eid2->title);
	if (d != 0) return d;
	return Str::cmp(eid1->author_name, eid2->author_name);
}

@ Because the Standard Rules are treated slightly differently by the
documentation, and so forth, it's convenient to provide a single function
which asks if a given EID is talking about them.

=
int an_eid_for_standard_rules_created = FALSE;
extension_identifier an_eid_for_standard_rules;
int Extensions::IDs::is_standard_rules(extension_identifier *eid) {
	if (an_eid_for_standard_rules_created == FALSE) {
		an_eid_for_standard_rules_created = TRUE;
		Extensions::IDs::new(&an_eid_for_standard_rules,
			I"Graham Nelson", I"Standard Rules", HYPOTHETICAL_EIDBC);
	}
	return Extensions::IDs::match(eid, &an_eid_for_standard_rules);
}

@h The database of known EIDs.
We will need to be able to give rapid answers to questions like "is there
an installed extension with this EID?" and "does any entry in the dictionary
relate to this EID?": there may be many extensions and very many dictionary
entries, so we keep an incidence count of each EID and in what context it
has been used, and store that in a hash table. Note that each distinct EID
is recorded only once in the table: this is important, as although an
individual extension can only be loaded or installed once, it could be
referred to in the dictionary dozens or even hundreds of times.

The table is unsorted and is intended for rapid searching. Typically there
will be only a handful of EIDs in the list of those with a given hash code:
indeed, the typical number will be 0 or 1.

=
int EID_database_created = FALSE;
extension_identifier_database_entry *hash_of_EIDEs[EI_HASH_CODING_BASE];

void Extensions::IDs::add_EID_to_database(extension_identifier *eid, int context) {
	if (EID_database_created == FALSE) {
		EID_database_created = TRUE;
		for (int i=0; i<EI_HASH_CODING_BASE; i++) hash_of_EIDEs[i] = NULL;
	}

	int hc = eid->extension_id_hash_code;

	extension_identifier_database_entry *eide;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			eide->incidence_count[context]++;
			return;
		}
	eide = CREATE(extension_identifier_database_entry);
	eide->hash_next = hash_of_EIDEs[hc]; hash_of_EIDEs[hc] = eide;
	eide->eide_id = eid;
	for (int i=0; i<NO_EIDB_CONTEXTS; i++) eide->incidence_count[i] = 0;
	eide->incidence_count[context] = 1;
	eide->last_usage_date = Str::new();
	eide->sort_usage_date = Str::new();
	eide->word_count_text = Str::new();
}

@ This gives us reasonably rapid access to a shared date:

=
void Extensions::IDs::set_usage_date(extension_identifier *eid, text_stream *date) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			Str::copy(eide->last_usage_date, date);
			return;
		}
}

void Extensions::IDs::set_sort_date(extension_identifier *eid, text_stream *date) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			Str::copy(eide->sort_usage_date, date);
			return;
		}
}

text_stream *Extensions::IDs::get_usage_date(extension_identifier *eid) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			if (Str::len(eide->last_usage_date) > 0)
				return eide->last_usage_date;
			if (eide->incidence_count[DICTIONARY_REFERRED_EIDBC] > 0)
				return I"Once upon a time";
			return I"Never";
		}
	return I"---";
}

text_stream *Extensions::IDs::get_sort_date(extension_identifier *eid) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			if (Str::len(eide->sort_usage_date) > 0)
				return eide->sort_usage_date;
			if (eide->incidence_count[DICTIONARY_REFERRED_EIDBC] > 0)
				return I"00000000000000Once upon a time";
			return I"00000000000000Never";
		}
	return I"000000000000000";
}

void Extensions::IDs::set_word_count(extension_identifier *eid, int wc) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			WRITE_TO(eide->word_count_text, "%08d words", wc);
			eide->word_count_number = wc;
			return;
		}
}

text_stream *Extensions::IDs::get_sort_word_count(extension_identifier *eid) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			if (Str::len(eide->word_count_text) > 0)
				return eide->word_count_text;
			if (eide->incidence_count[DICTIONARY_REFERRED_EIDBC] > 0)
				return I"00000000I did read this, but forgot";
			return I"00000000I've never read this";
		}
	return I"---";
}

int Extensions::IDs::forgot(extension_identifier *eid) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			if (Str::len(eide->word_count_text) > 0)
				return FALSE;
			if (eide->incidence_count[DICTIONARY_REFERRED_EIDBC] > 0)
				return TRUE;
			return FALSE;
		}
	return FALSE;
}

int Extensions::IDs::never(extension_identifier *eid) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) {
			if (Str::len(eide->word_count_text) > 0)
				return FALSE;
			if (eide->incidence_count[DICTIONARY_REFERRED_EIDBC] > 0)
				return FALSE;
			return TRUE;
		}
	return FALSE;
}

int Extensions::IDs::get_word_count(extension_identifier *eid) {
	extension_identifier_database_entry *eide;
	int hc = eid->extension_id_hash_code;
	for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id))
			return eide->word_count_number;
	return 0;
}

@ The purpose of the hash table is to enable us to reply quickly when asked
for one of the following usage counts:

=
int Extensions::IDs::no_times_used_in_context(extension_identifier *eid, int context) {
	extension_identifier_database_entry *eide;
	for (eide = hash_of_EIDEs[eid->extension_id_hash_code]; eide; eide = eide->hash_next)
		if (Extensions::IDs::match(eid, eide->eide_id)) return eide->incidence_count[context];
	return 0;
}

@ The EID hash table makes quite interesting reading, so:

=
void Extensions::IDs::log_EID_hash_table(void) {
	int hc, total = 0;
	LOG("Extension identifier hash table:\n");
	for (hc=0; hc<EI_HASH_CODING_BASE; hc++) {
		extension_identifier_database_entry *eide;
		for (eide = hash_of_EIDEs[hc]; eide; eide = eide->hash_next) {
			total++;
			LOG("%03d %3d %3d %3d %3d  %X\n",
				hc, eide->incidence_count[0], eide->incidence_count[1],
				eide->incidence_count[2], eide->incidence_count[3],
				eide->eide_id);
		}
	}
	LOG("%d entries in all\n", total);
}

@h How casing is normalised.
Every word is capitalised, where a word begins at the start of the text,
after a hyphen, or after a bracket. Thus "Every Word Counts", "Even
Double-Barrelled Ones (And Even Parenthetically)".

=
void Extensions::IDs::normalise_casing(text_stream *p) {
	int boundary = TRUE;
	LOOP_THROUGH_TEXT(pos, p) {
		wchar_t c = Str::get(pos);
		if (boundary) Str::put(pos, Characters::toupper(c));
		else Str::put(pos, Characters::tolower(c));
		boundary = FALSE;
		if (c == ' ') boundary = TRUE;
		if (c == '-') boundary = TRUE;
		if (c == '(') boundary = TRUE;
	}
}

@h Documentation links.
This is where HTML links to extension documentation are created; the URL for
each extension's page is generated from its ID.

=
void Extensions::IDs::begin_extension_link(OUTPUT_STREAM, extension_identifier *eid, text_stream *rubric) {
	TEMPORARY_TEXT(link);
	WRITE_TO(link, "href='inform://Extensions/Extensions/");
	Extensions::IDs::escape_apostrophes(link, eid->author_name);
	WRITE_TO(link, "/");
	Extensions::IDs::escape_apostrophes(link, eid->title);
	WRITE_TO(link, ".html' ");
	if (Str::len(rubric) > 0) WRITE_TO(link, "title=\"%S\" ", rubric);
	else WRITE_TO(link, "title=\"%X\" ", eid);
	WRITE_TO(link, "style=\"text-decoration: none\"");
	HTML_OPEN_WITH("a", "%S", link);
	DISCARD_TEXT(link);
}

void Extensions::IDs::escape_apostrophes(OUTPUT_STREAM, text_stream *S) {
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == '\'') || (c == '\"') || (c == ' ') || (c == '&') ||
			(c == '<') || (c == '>') || (c == '%'))
			WRITE("%%%x", (int) c);
		else
			PUT(c);
	}
}

void Extensions::IDs::end_extension_link(OUTPUT_STREAM, extension_identifier *eid) {
	HTML_CLOSE("a");
}
