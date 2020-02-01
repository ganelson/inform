[Works::] Works.

To store, hash code and compare title/author pairs used to identify works.

@h Works.
A "work" is a single artistic or programming creation; for example, the IF
story Bronze by Emily Short might be a work. Mamy versions of this IF story
may exist over time, but they will all be versions of the same "work".
Extensions are also works: for example, Epistemology by Eric Eve is a work.

Works are identified by the pair of title and author name, each of which is an
ISO Latin-1 string limited in length, with certain bad-news characters
excluded (such as |/| and |:|) so that they can be used directly in filenames.
However, we will not want to compare these by string comparison: so we
hash-code the combination for speed. The following structure holds a
combination of the textual names and the hash code:

=
typedef struct inbuild_work {
	struct inbuild_genre *genre;
	struct text_stream *author_name;
	struct text_stream *raw_author_name;
	struct text_stream *title;
	struct text_stream *raw_title;
	int inbuild_work_hash_code; /* hash code derived from the above */
	MEMORY_MANAGEMENT
} inbuild_work;

@ Each work structure is written only once, and its title and author name are
not subsequently altered. We therefore hash-code on arrival. As when
hashing vocabulary, we apply the X 30011 algorithm, this time with 499
(coprime to 30011) as base, to the text of the Unix-style pathname
|Author/Title|.

Though it is probably the case that the author name and title supplied are
already of normalised casing, we do not want to rely on that. Works intending
to represent (e.g.) the same extension but named with different casing
conventions would fail to match: and this could happen if a new build of
Inform were published which made a subtle change to the casing conventions,
but which continued to use an extension dictionary file first written by
previous builds under the previous conventions.

The hash code is an integer between 0 and the following constant minus 1,
derived from its title and author name.

@d WORK_HASH_CODING_BASE 499

=
inbuild_work *Works::new(inbuild_genre *genre, text_stream *ti, text_stream *an) {
	inbuild_work *work = CREATE(inbuild_work);
	work->genre = genre;
	work->raw_author_name = Str::duplicate(an);
	work->author_name = Str::duplicate(an);
	work->raw_title = Str::duplicate(ti);
	work->title = Str::duplicate(ti);
	Works::normalise_casing(work->author_name);
	Works::normalise_casing(work->title);

	unsigned int hc = 0;
	LOOP_THROUGH_TEXT(pos, work->author_name)
		hc = hc*30011 + (unsigned int) Str::get(pos);
	hc = hc*30011 + (unsigned int) '/';
	LOOP_THROUGH_TEXT(pos, work->title)
		hc = hc*30011 + (unsigned int) Str::get(pos);
	hc = hc % WORK_HASH_CODING_BASE;
	work->inbuild_work_hash_code = (int) hc;
	return work;
}

void Works::set_raw(inbuild_work *work, text_stream *raw_an, text_stream *raw_ti) {
	work->raw_author_name = Str::duplicate(raw_an);
	work->raw_title = Str::duplicate(raw_ti);
}

void Works::write(OUTPUT_STREAM, inbuild_work *work) {
	VMETHOD_CALL(work->genre, GENRE_WRITE_WORK_MTID, OUT, work);
}

void Works::write_to_HTML_file(OUTPUT_STREAM, inbuild_work *work, int fancy) {
	WRITE("%S", work->raw_title);
	if (fancy) HTML::begin_colour(OUT, I"404040");
	WRITE(" by ");
	if (fancy) HTML::end_colour(OUT);
	WRITE("%S", work->raw_author_name);
}

void Works::write_link_to_HTML_file(OUTPUT_STREAM, inbuild_work *work) {
	HTML_OPEN_WITH("a", "href='Extensions/%S/%S.html' style=\"text-decoration: none\"",
		work->author_name, work->title);
	HTML::begin_colour(OUT, I"404040");
	if (Works::is_standard_rules(work)) WRITE("%S", work->title);
	else Works::write_to_HTML_file(OUT, work, FALSE);
	HTML::end_colour(OUT);
	HTML_CLOSE("a");
}

void Works::writer(OUTPUT_STREAM, char *format_string, void *vE) {
	inbuild_work *work = (inbuild_work *) vE;
	switch (format_string[0]) {
		case '<':
			if (work == NULL) WRITE("source text");
			else {
				WRITE("%S", work->raw_title);
				if (Works::is_standard_rules(work) == FALSE)
					WRITE(" by %S", work->raw_author_name);
			}
			break;
		case 'X':
			if (work == NULL) WRITE("<no extension>");
			else WRITE("%S by %S", work->raw_title, work->raw_author_name);
			break;
		default:
			internal_error("bad %X extension");
	}
}

@ Two works with different hash codes definitely identify different extensions;
if the code is the same, we must use |strcmp| on the actual title and author
name. This is in effect case insensitive, since we normalised casing when
the works were created.

(Note that this is not a lexicographic function suitable for sorting
works into alphabetical order: it cannot be, since the hash code is not
order-preserving. To emphasise this we return true or false rather than a
|strcmp|-style delta value. For |Works::compare|, see below...)

=
int Works::match(inbuild_work *eid1, inbuild_work *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad work match");
	if (eid1->inbuild_work_hash_code != eid2->inbuild_work_hash_code) return FALSE;
	if (Str::eq(eid1->author_name, eid2->author_name) == FALSE) return FALSE;
	if (Str::eq(eid1->title, eid2->title) == FALSE) return FALSE;
	return TRUE;
}

@ These are quite a deal slower, but trichotomous.

=
int Works::compare(inbuild_work *eid1, inbuild_work *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(eid1->author_name, eid2->author_name);
	if (d != 0) return d;
	return Str::cmp(eid1->title, eid2->title);
}

int Works::compare_by_title(inbuild_work *eid1, inbuild_work *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(eid1->title, eid2->title);
	if (d != 0) return d;
	return Str::cmp(eid1->author_name, eid2->author_name);
}

int Works::compare_by_date(inbuild_work *eid1, inbuild_work *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(Works::get_sort_date(eid2), Works::get_sort_date(eid1));
	if (d != 0) return d;
	d = Str::cmp(eid1->title, eid2->title);
	if (d != 0) return d;
	return Str::cmp(eid1->author_name, eid2->author_name);
}

int Works::compare_by_length(inbuild_work *eid1, inbuild_work *eid2) {
	if ((eid1 == NULL) || (eid2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(Works::get_sort_word_count(eid2), Works::get_sort_word_count(eid1));
	if (d != 0) return d;
	d = Str::cmp(eid1->title, eid2->title);
	if (d != 0) return d;
	return Str::cmp(eid1->author_name, eid2->author_name);
}

@ Because the Standard Rules are treated slightly differently by the
documentation, and so forth, it's convenient to provide a single function
testing if a work refers to them.

=
inbuild_work *a_work_for_standard_rules = NULL;
int Works::is_standard_rules(inbuild_work *work) {
	if (a_work_for_standard_rules == NULL) {
		a_work_for_standard_rules =
			Works::new(extension_genre, I"Standard Rules", I"Graham Nelson");
		Works::add_to_database(a_work_for_standard_rules, HYPOTHETICAL_WDBC);
	}
	return Works::match(work, a_work_for_standard_rules);
}

inbuild_work *a_work_for_basic_inform = NULL;
int Works::is_basic_inform(inbuild_work *work) {
	if (a_work_for_basic_inform == NULL) {
		a_work_for_basic_inform =
			Works::new(extension_genre, I"Basic Inform", I"Graham Nelson");
		Works::add_to_database(a_work_for_basic_inform, HYPOTHETICAL_WDBC);
	}
	return Works::match(work, a_work_for_basic_inform);
}

@h The database of known works.
We will need to be able to give rapid answers to questions like "is there
an installed extension with this work?" and "does any entry in the dictionary
relate to this work?": there may be many extensions and very many dictionary
entries, so we keep an incidence count of each work and in what context it
has been used, and store that in a hash table. Note that each distinct work
is recorded only once in the table: this is important, as although an
individual extension can only be loaded or installed once, it could be
referred to in the dictionary dozens or even hundreds of times.

The table is unsorted and is intended for rapid searching. Typically there
will be only a handful of works in the list of those with a given hash code:
indeed, the typical number will be 0 or 1.

Works are entered into the database with one of the following contexts:

@d NO_WDB_CONTEXTS 5
@d LOADED_WDBC 0
@d INSTALLED_WDBC 1
@d DICTIONARY_REFERRED_WDBC 2
@d HYPOTHETICAL_WDBC 3
@d USEWITH_WDBC 4

=
typedef struct inbuild_work_database_entry {
	struct inbuild_work *work;
	struct inbuild_work_database_entry *hash_next; /* next one in hashed work database */
	int incidence_count[NO_WDB_CONTEXTS];
	struct text_stream *last_usage_date;
	struct text_stream *sort_usage_date;
	struct text_stream *word_count_text;
	int word_count_number;
} inbuild_work_database_entry;

int work_database_created = FALSE;
inbuild_work_database_entry *hash_of_works[WORK_HASH_CODING_BASE];

void Works::add_to_database(inbuild_work *work, int context) {
	if (work_database_created == FALSE) {
		work_database_created = TRUE;
		for (int i=0; i<WORK_HASH_CODING_BASE; i++) hash_of_works[i] = NULL;
	}

	int hc = work->inbuild_work_hash_code;

	inbuild_work_database_entry *iwde;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			iwde->incidence_count[context]++;
			return;
		}
	iwde = CREATE(inbuild_work_database_entry);
	iwde->hash_next = hash_of_works[hc]; hash_of_works[hc] = iwde;
	iwde->work = work;
	for (int i=0; i<NO_WDB_CONTEXTS; i++) iwde->incidence_count[i] = 0;
	iwde->incidence_count[context] = 1;
	iwde->last_usage_date = Str::new();
	iwde->sort_usage_date = Str::new();
	iwde->word_count_text = Str::new();
}

@ This gives us reasonably rapid access to a shared date:

=
void Works::set_usage_date(inbuild_work *work, text_stream *date) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			Str::copy(iwde->last_usage_date, date);
			return;
		}
}

void Works::set_sort_date(inbuild_work *work, text_stream *date) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			Str::copy(iwde->sort_usage_date, date);
			return;
		}
}

text_stream *Works::get_usage_date(inbuild_work *work) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			if (Str::len(iwde->last_usage_date) > 0)
				return iwde->last_usage_date;
			if (iwde->incidence_count[DICTIONARY_REFERRED_WDBC] > 0)
				return I"Once upon a time";
			return I"Never";
		}
	return I"---";
}

text_stream *Works::get_sort_date(inbuild_work *work) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			if (Str::len(iwde->sort_usage_date) > 0)
				return iwde->sort_usage_date;
			if (iwde->incidence_count[DICTIONARY_REFERRED_WDBC] > 0)
				return I"00000000000000Once upon a time";
			return I"00000000000000Never";
		}
	return I"000000000000000";
}

void Works::set_word_count(inbuild_work *work, int wc) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			WRITE_TO(iwde->word_count_text, "%08d words", wc);
			iwde->word_count_number = wc;
			return;
		}
}

text_stream *Works::get_sort_word_count(inbuild_work *work) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			if (Str::len(iwde->word_count_text) > 0)
				return iwde->word_count_text;
			if (iwde->incidence_count[DICTIONARY_REFERRED_WDBC] > 0)
				return I"00000000I did read this, but forgot";
			return I"00000000I've never read this";
		}
	return I"---";
}

int Works::forgot(inbuild_work *work) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			if (Str::len(iwde->word_count_text) > 0)
				return FALSE;
			if (iwde->incidence_count[DICTIONARY_REFERRED_WDBC] > 0)
				return TRUE;
			return FALSE;
		}
	return FALSE;
}

int Works::never(inbuild_work *work) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) {
			if (Str::len(iwde->word_count_text) > 0)
				return FALSE;
			if (iwde->incidence_count[DICTIONARY_REFERRED_WDBC] > 0)
				return FALSE;
			return TRUE;
		}
	return FALSE;
}

int Works::get_word_count(inbuild_work *work) {
	inbuild_work_database_entry *iwde;
	int hc = work->inbuild_work_hash_code;
	for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work))
			return iwde->word_count_number;
	return 0;
}

@ The purpose of the hash table is to enable us to reply quickly when asked
for one of the following usage counts:

=
int Works::no_times_used_in_context(inbuild_work *work, int context) {
	inbuild_work_database_entry *iwde;
	for (iwde = hash_of_works[work->inbuild_work_hash_code]; iwde; iwde = iwde->hash_next)
		if (Works::match(work, iwde->work)) return iwde->incidence_count[context];
	return 0;
}

@ The work hash table makes quite interesting reading, so:

=
void Works::log_work_hash_table(void) {
	int hc, total = 0;
	LOG("Work identifier hash table:\n");
	for (hc=0; hc<WORK_HASH_CODING_BASE; hc++) {
		inbuild_work_database_entry *iwde;
		for (iwde = hash_of_works[hc]; iwde; iwde = iwde->hash_next) {
			total++;
			LOG("%03d %3d %3d %3d %3d  %X\n",
				hc, iwde->incidence_count[0], iwde->incidence_count[1],
				iwde->incidence_count[2], iwde->incidence_count[3],
				iwde->work);
		}
	}
	LOG("%d entries in all\n", total);
}

@h How casing is normalised.
Every word is capitalised, where a word begins at the start of the text,
after a hyphen, or after a bracket. Thus "Every Word Counts", "Even
Double-Barrelled Ones (And Even Parenthetically)".

=
void Works::normalise_casing(text_stream *p) {
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
each extension's page is generated from its |inbuild_work|.

=
void Works::begin_extension_link(OUTPUT_STREAM, inbuild_work *work, text_stream *rubric) {
	TEMPORARY_TEXT(link);
	WRITE_TO(link, "href='inform://Extensions/Extensions/");
	Works::escape_apostrophes(link, work->author_name);
	WRITE_TO(link, "/");
	Works::escape_apostrophes(link, work->title);
	WRITE_TO(link, ".html' ");
	if (Str::len(rubric) > 0) WRITE_TO(link, "title=\"%S\" ", rubric);
	else WRITE_TO(link, "title=\"%X\" ", work);
	WRITE_TO(link, "style=\"text-decoration: none\"");
	HTML_OPEN_WITH("a", "%S", link);
	DISCARD_TEXT(link);
}

void Works::escape_apostrophes(OUTPUT_STREAM, text_stream *S) {
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == '\'') || (c == '\"') || (c == ' ') || (c == '&') ||
			(c == '<') || (c == '>') || (c == '%'))
			WRITE("%%%x", (int) c);
		else
			PUT(c);
	}
}

void Works::end_extension_link(OUTPUT_STREAM, inbuild_work *work) {
	HTML_CLOSE("a");
}
