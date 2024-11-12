[Works::] Works.

To store, hash code and compare title/author pairs used to identify works.

@h Works.
A "work" is a single artistic or programming creation; for example, the IF
story Bronze by Emily Short might be a work. Many versions of this IF story
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
	CLASS_DEFINITION
} inbuild_work;

@ Each work structure is written only once, and its title and author name are
not subsequently altered.

=
inbuild_work *Works::new(inbuild_genre *genre, text_stream *ti, text_stream *an) {
	return Works::new_inner(genre, ti, an, TRUE);
}
inbuild_work *Works::new_raw(inbuild_genre *genre, text_stream *ti, text_stream *an) {
	return Works::new_inner(genre, ti, an, FALSE);
}

@ Though it is probably the case that the author name and title supplied are
already of normalised casing, we do not want to rely on that. Works intending
to represent (e.g.) the same extension but named with different casing
conventions would fail to match: and this could happen if a new build of
Inform were published which made a subtle change to the casing conventions,
but which continued to use an extension dictionary file first written by
previous builds under the previous conventions.

The "raw", i.e., not case-normalised, forms of the title and author name are
preserved for use in text output, but not identification.

=
inbuild_work *Works::new_inner(inbuild_genre *genre, text_stream *ti, text_stream *an, int norm) {
	inbuild_work *work = CREATE(inbuild_work);
	work->genre = genre;
	work->raw_author_name = Str::duplicate(an);
	work->author_name = Str::duplicate(an);
	work->raw_title = Str::duplicate(ti);
	work->title = Str::duplicate(ti);
	if (norm) {
		Works::normalise_casing(work->author_name);
		Works::normalise_casing(work->title);
	}
	@<Compute the hash code@>;
	return work;
}

@ We hash-code all works on arrival, using the X 30011 algorithm, on the text
of the pseudo-pathname |Author/Title|. The result is an integer between 0 and
the following constant minus 1.

@d WORK_HASH_CODING_BASE 499 /* this is coprime to 30011 */

@<Compute the hash code@> =
	unsigned int hc = 0;
	LOOP_THROUGH_TEXT(pos, work->author_name)
		hc = hc*30011 + (unsigned int) Characters::tolower(Str::get(pos));
	hc = hc*30011 + (unsigned int) '/';
	LOOP_THROUGH_TEXT(pos, work->title)
		hc = hc*30011 + (unsigned int) Characters::tolower(Str::get(pos));
	hc = hc % WORK_HASH_CODING_BASE;
	work->inbuild_work_hash_code = (int) hc;

@ Casing is normalised as follows. Every word is capitalised, where a word
begins at the start of the text, after a hyphen, or after a bracket. Thus
"Every Word Counts", "Even Double-Barrelled Ones (And Even Parenthetically)".

=
void Works::normalise_casing(text_stream *p) {
	int boundary = TRUE;
	LOOP_THROUGH_TEXT(pos, p) {
		inchar32_t c = Str::get(pos);
		if (boundary) Str::put(pos, Characters::toupper(c));
		else Str::put(pos, Characters::tolower(c));
		boundary = FALSE;
		if (c == ' ') boundary = TRUE;
		if (c == '-') boundary = TRUE;
		if (c == '(') boundary = TRUE;
	}
}

@ This variant is more forgiving, in that it allows mixed-casing inside a
word, that is, after the opening letter. So "PDQ Bach" and "Marc DuQuesne"
would both pass, whereas //Works::normalise_casing// would make them into
"Pdq Bach" and "Marc Duquesne".

=
void Works::normalise_casing_mixed(text_stream *p) {
	int boundary = TRUE;
	LOOP_THROUGH_TEXT(pos, p) {
		inchar32_t c = Str::get(pos);
		if (boundary) Str::put(pos, Characters::toupper(c));
		boundary = FALSE;
		if (c == ' ') boundary = TRUE;
		if (c == '-') boundary = TRUE;
		if (c == '(') boundary = TRUE;
	}
}

@h Printing.
As noted above, the raw forms are used for output.

=
void Works::write(OUTPUT_STREAM, inbuild_work *work) {
	VOID_METHOD_CALL(work->genre, GENRE_WRITE_WORK_MTID, OUT, work);
}

void Works::write_to_HTML_file(OUTPUT_STREAM, inbuild_work *work, int fancy) {
	WRITE("%S", work->raw_title);
	if (fancy) HTML::begin_span(OUT, I"extensionindexentry");
	WRITE(" by ");
	if (fancy) HTML::end_span(OUT);
	WRITE("%S", work->raw_author_name);
}

@ The following is only sensible for extensions, and is used when Inform
generates its Extensions index entries.

=
void Works::write_link_to_HTML_file(OUTPUT_STREAM, inbuild_work *work) {
	HTML_OPEN_WITH("a", "href='Extensions/%S/%S.html' style=\"text-decoration: none\"",
		work->author_name, work->title);
	HTML::begin_span(OUT, I"extensionindexentry");
	if (Works::is_standard_rules(work)) WRITE("%S", work->title);
	else Works::write_to_HTML_file(OUT, work, FALSE);
	HTML::end_span(OUT);
	HTML_CLOSE("a");
}

@ The Inbuild module provides the |%X| escape sequence for printing names of
works. (The X used to stand for Extension.) |%<X| provides an abbreviated form.

=
void Works::writer(OUTPUT_STREAM, char *format_string, void *vE) {
	inbuild_work *work = (inbuild_work *) vE;
	switch (format_string[0]) {
		case '<':
			if (work == NULL) WRITE("source text");
			else {
				WRITE("%S", work->raw_title);
				if ((Works::is_standard_rules(work) == FALSE) &&
					(Works::is_basic_inform(work) == FALSE))
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

@h Identification.
Two works with different hash codes definitely identify different works;
if the code is the same, we must use |Str::eq| on the actual title and author
name.

(Note that this is not a lexicographic function suitable for sorting
works into alphabetical order: it cannot be, since the hash code is not
order-preserving. To emphasise this we return true or false rather than a
|strcmp|-style delta value.)

=
int Works::match(inbuild_work *w1, inbuild_work *w2) {
	if ((w1 == NULL) || (w2 == NULL)) internal_error("bad work match");
	if (w1->inbuild_work_hash_code != w2->inbuild_work_hash_code) return FALSE;
	if (Str::eq_insensitive(w1->author_name, w2->author_name) == FALSE) return FALSE;
	if (Str::eq_insensitive(w1->title, w2->title) == FALSE) return FALSE;
	return TRUE;
}

@ This is quite a deal slower, but is trichotomous and can be used for sorting.

=
int Works::cmp(inbuild_work *w1, inbuild_work *w2) {
	if ((w1 == NULL) || (w2 == NULL)) internal_error("bad work match");
	int d = Genres::cmp(w1->genre, w2->genre);
	if (d == 0) d = Str::cmp_insensitive(w1->author_name, w2->author_name);
	if (d == 0) d = Str::cmp_insensitive(w1->title, w2->title);
	return d;
}

@ Because Basic Inform and the Standard Rules extensions are treated slightly
differently by the documentation, and so forth, it's convenient to provide a
single function testing if a work refers to them.

=
inbuild_work *a_work_for_standard_rules = NULL;
int Works::is_standard_rules(inbuild_work *work) {
	if (a_work_for_standard_rules == NULL)
		a_work_for_standard_rules =
			Works::new(extension_genre, I"Standard Rules", I"Graham Nelson");
	if (work == NULL) return FALSE;
	return Works::match(work, a_work_for_standard_rules);
}

inbuild_work *a_work_for_basic_inform = NULL;
int Works::is_basic_inform(inbuild_work *work) {
	if (a_work_for_basic_inform == NULL)
		a_work_for_basic_inform =
			Works::new(extension_genre, I"Basic Inform", I"Graham Nelson");
	if (work == NULL) return FALSE;
	return Works::match(work, a_work_for_basic_inform);
}

@h Documentation links.
This is where HTML links to extension documentation are created; the URL for
each extension's page is generated from its |inbuild_work|.

=
void Works::begin_extension_link(OUTPUT_STREAM, inbuild_work *work, text_stream *rubric) {
	TEMPORARY_TEXT(link)
	WRITE_TO(link, "href='inform://Extensions/Documentation/");
	Works::escape_apostrophes(link, work->author_name);
	WRITE_TO(link, "/");
	Works::escape_apostrophes(link, work->title);
	WRITE_TO(link, ".html' ");
	if (Str::len(rubric) > 0) WRITE_TO(link, "title=\"%S\" ", rubric);
	else WRITE_TO(link, "title=\"%X\" ", work);
	WRITE_TO(link, "style=\"text-decoration: none\"");
	HTML_OPEN_WITH("a", "%S", link);
	DISCARD_TEXT(link)
}

void Works::escape_apostrophes(OUTPUT_STREAM, text_stream *S) {
	LOOP_THROUGH_TEXT(pos, S) {
		inchar32_t c = Str::get(pos);
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
