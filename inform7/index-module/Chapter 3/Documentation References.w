[Index::DocReferences::] Documentation References.

To enable index or results pages to link into documentation.

@h Definitions.

@ Documentation is arranged in a series of HTML pages identified by
section number 0, 1, 2, ..., and the index contains little blue help
icons which link into this. In order to give these links the correct
destinations, NI needs to know which section number contains what:
but section numbering moves around a lot as the documentation is
written.

To avoid needlessly recompiling NI when documentation changes, we
give certain sections aliases called "symbols" which are rather
more lasting than the section numbering. For instance, the sentence

>> Document KINDSVALUE at doc64.

(in the Standard Rules, the only source file allowed to define symbols)
creates the symbol |KINDSVALUE| and says that it currently corresponds
to |doc64.html| in the documentation. Such sentences are automatically
amended by |indoc| to keep the Standard Rules in line with the Inform
documentation.

=
typedef struct documentation_ref {
	struct text_stream *symbol; /* Reference is by this piece of text */
	int section; /* HTML page number */
	int used_already; /* Has this been used in a problem message already? */
	int usage_count; /* For statistical purposes */
	char *fragment_at; /* Pointer to HTML documentation fragment in memory */
	int fragment_length; /* Number of bytes of fragment */
	int sr_usage_count;
	int ext_usage_count;
	wchar_t *chapter_reference; /* Or |NULL| if no chapter name supplied */
	wchar_t *section_reference; /* Or |NULL| if no section name supplied */
	MEMORY_MANAGEMENT
} documentation_ref;

@

@d DOCUMENTATION_REFERENCES_PRESENT

@ The blue query icons link to pages in the documentation, as described above.
Documentation references are used to match the documentation text against
the compiler so that each can be changed independently of the other.
First, we handle the Standard-Rules-only sentences which specify documentation
references:

=
int Index::DocReferences::document_at_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Document ... at ..." */
		case ACCEPT_SMFT:
			ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
			<nounphrase>(O2W);
			V->next = <<rp>>;
			<nounphrase>(OW);
			V->next->next = <<rp>>;
			return TRUE;
		case TRAVERSE1_SMFT:
			Index::DocReferences::dref_new(V);
			break;
	}
	return FALSE;
}

void Index::DocReferences::dref_new(parse_node *p) {
	wording SW = ParseTree::get_text(p->next);
	wording RW = ParseTree::get_text(p->next->next);
	wchar_t *chap = NULL, *sect = NULL;
	if ((Wordings::length(RW) > 1) && (Vocabulary::test_flags(Wordings::first_wn(RW)+1, TEXT_MC))) {
		Word::dequote(Wordings::first_wn(RW)+1);
		chap = Lexer::word_text(Wordings::first_wn(RW)+1);
	}
	if ((Wordings::length(RW) > 2) && (Vocabulary::test_flags(Wordings::first_wn(RW)+2, TEXT_MC))) {
		Word::dequote(Wordings::first_wn(RW)+2);
		sect = Lexer::word_text(Wordings::first_wn(RW)+2);
	}
	LOOP_THROUGH_WORDING(i, SW) {
		documentation_ref *dr = CREATE(documentation_ref);
		dr->symbol = Str::new();
		WRITE_TO(dr->symbol, "%+W", Wordings::one_word(i));
		dr->section = Wordings::first_wn(RW);
		dr->used_already = FALSE;
		dr->usage_count = 0;
		dr->sr_usage_count = 0;
		dr->ext_usage_count = 0;
		dr->chapter_reference = chap;
		dr->section_reference = sect;
		dr->fragment_at = NULL;
		dr->fragment_length = 0;
	}
}

@ The following routine is used to verify that a given text is, or is not,
a valid documentation reference symbol. (For instance, we might look up
|kind_vehicle| to see if any section of documentation has been flagged
as giving information on vehicles.) If our speculative link symbol exists,
we return the leafname for this documentation page, without filename
extension (say |doc24|); if it does not exist, we return NULL.

=
int Index::DocReferences::validate_if_possible(text_stream *temp) {
	documentation_ref *dr;
	LOOP_OVER(dr, documentation_ref)
		if (Str::eq(dr->symbol, temp))
			return TRUE;
	return FALSE;
}

@ And similarly, returning the page we link to:

=
wchar_t *Index::DocReferences::link_if_possible_once(text_stream *temp, wchar_t **chap, wchar_t **sec) {
	documentation_ref *dr;
	LOOP_OVER(dr, documentation_ref)
		if (Str::eq(dr->symbol, temp)) {
			if (dr->used_already == FALSE) {
				wchar_t *leaf = Lexer::word_text(dr->section);
				*chap = dr->chapter_reference;
				*sec = dr->section_reference;
				LOOP_OVER(dr, documentation_ref)
					if (Wide::cmp(leaf, Lexer::word_text(dr->section)) == 0)
						dr->used_already = TRUE;
				return leaf;
			}
		}
	return NULL;
}

@ In the Standard Rules, a number of phrases (and other constructs) are
defined along with markers to sections in the documentation: here we parse
these markers, returning either the word number of the documentation symbol
in question, or $-1$ if there is none. Since this is used only with the
Standard Rules, which are in English, there's no point in translating it
to other natural languages.

=
<documentation-symbol-tail> ::=
	... ( <documentation-symbol> ) |	==> R[1]
	... -- <documentation-symbol> --	==> R[1]

<documentation-symbol> ::=
	documented at ###					==> Wordings::first_wn(WR[1])

@ =
wording Index::DocReferences::position_of_symbol(wording *W) {
	if (<documentation-symbol-tail>(*W)) {
		*W = GET_RW(<documentation-symbol-tail>, 1);
		return Wordings::one_word(<<r>>);
	}
	return EMPTY_WORDING;
}

@ It's convenient to associate a usage count to each symbol, since every
built-in documented phrase has a symbol. Every time Inform successfully uses
such a phrase, it increments the usage count by calling the following:

=
void Index::DocReferences::doc_mark_used(text_stream *symb, int at_word) {
	if (Log::aspect_switched_on(PHRASE_USAGE_DA)) {
		documentation_ref *dr;
		LOOP_OVER(dr, documentation_ref) {
			if (Str::eq(dr->symbol, symb)) {
				extension_file *loc = NULL;
				if (at_word >= 0) {
					source_file *pos = Lexer::file_of_origin(at_word);
					loc = SourceFiles::get_extension_corresponding(pos);
					if (loc == NULL) dr->usage_count++;
					else if (loc == standard_rules_extension) dr->sr_usage_count++;
					else dr->ext_usage_count++;
				} else dr->sr_usage_count++;
				return;
			}
		}
		internal_error("unable to update usage count");
	}
}

@ The following dumps the result. This is not useful for a single run,
especially, but to be accumulated over a whole corpus of source texts, e.g.:

	|intest --keep-log=USAGE -log=phrase-usage examples|

=
void Index::DocReferences::log_statistics(void) {
	LOGIF(PHRASE_USAGE, "The following shows how often each built-in phrase was used:\n");
	documentation_ref *dr;
	LOOP_OVER(dr, documentation_ref)
		if (Str::begins_with_wide_string(dr->symbol, L"ph"))
			LOGIF(PHRASE_USAGE, "USAGE: %S %d %d %d\n", dr->symbol,
				dr->usage_count, dr->sr_usage_count, dr->ext_usage_count);
}

@ Finally, the blue "see relevant help page" icon links are placed by the
following routine.

=
void Index::DocReferences::link_to(OUTPUT_STREAM, text_stream *fn, int full) {
	documentation_ref *dr = Index::DocReferences::name_to_dr(fn);
	if (dr) {
		if (full >= 0) WRITE("&nbsp;"); else WRITE(" ");
		HTML_OPEN_WITH("a", "href=inform:/%N.html", dr->section);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/help.png");
		HTML_CLOSE("a");
		if ((full > 0) && (dr->chapter_reference) && (dr->section_reference)) {
			WRITE("&nbsp;%w. %w", dr->chapter_reference, dr->section_reference);
		}
	}
}

void Index::DocReferences::link(OUTPUT_STREAM, text_stream *fn) {
	Index::DocReferences::link_to_S(OUT, fn, FALSE);
}

void Index::DocReferences::fully_link(OUTPUT_STREAM, text_stream *fn) {
	Index::DocReferences::link_to_S(OUT, fn, TRUE);
}

void Index::DocReferences::link_to_S(OUTPUT_STREAM, text_stream *fn, int full) {
	documentation_ref *dr = Index::DocReferences::name_to_dr(fn);
	if (dr) {
		if (full >= 0) WRITE("&nbsp;"); else WRITE(" ");
		HTML_OPEN_WITH("a", "href=inform:/%N.html", dr->section);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/help.png");
		HTML_CLOSE("a");
		if ((full > 0) && (dr->chapter_reference) && (dr->section_reference)) {
			WRITE("&nbsp;%w. %w", dr->chapter_reference, dr->section_reference);
		}
	}
}

@h Fragments.
These are short pieces of documentation, which |indoc| has copied into a special
file so that we can paste them into the index at appropriate places. Note that
if the file can't be found, or contains nothing germane, we fail safe by doing
nothing at all -- not issuing any internal errors.

=
void Index::DocReferences::doc_fragment(OUTPUT_STREAM, text_stream *fn) {
	Index::DocReferences::doc_fragment_to(OUT, fn);
}

int fragments_loaded = FALSE;
void Index::DocReferences::doc_fragment_to(OUTPUT_STREAM, text_stream *fn) {
	if (fragments_loaded == FALSE) {
		@<Load in the documentation fragments file@>;
		fragments_loaded = TRUE;
	}
	documentation_ref *dr = Index::DocReferences::name_to_dr(fn);
	if ((dr) && (dr->fragment_at)) {
		char *p = dr->fragment_at;
		int i;
		for (i=0; i<dr->fragment_length; i++) PUT(p[i]);
	}
}

@

@d MAX_EXTENT_OF_FRAGMENTS 256*1024

@<Load in the documentation fragments file@> =
	FILE *FRAGMENTS = Filenames::fopen(filename_of_documentation_snippets, "r");
	if (FRAGMENTS) {
		char *p = Memory::I7_malloc(MAX_EXTENT_OF_FRAGMENTS, DOC_FRAGMENT_MREASON);
		@<Scan the file into memory, translating from UTF-8@>;
		@<Work out where the documentation fragments occur@>;
		fclose(FRAGMENTS);
	}

@ We scan to one long C string:

@<Scan the file into memory, translating from UTF-8@> =
	int i = 0;
	p[0] = 0;
	while (TRUE) {
		int c = TextFiles::utf8_fgetc(FRAGMENTS, NULL, FALSE, NULL);
		if (c == EOF) break;
		if (c == 0xFEFF) continue; /* the Unicode BOM non-character */
		if (i == MAX_EXTENT_OF_FRAGMENTS) break;
		p[i++] = (char) c;
		p[i] = 0;
	}

@<Work out where the documentation fragments occur@> =
	int i = 0;
	documentation_ref *tracking = NULL;
	for (i=0; p[i]; i++) {
		if ((p[i] == '*') && (p[i+1] == '=')) {
			i += 2;
			TEMPORARY_TEXT(rn);
			int j;
			for (j=0; p[i+j]; j++) {
				if ((p[i+j] == '=') && (p[i+j+1] == '*')) {
					i = i+j+1;
					tracking = Index::DocReferences::name_to_dr(rn);
					if (tracking) tracking->fragment_at = p+i+1;
					break;
				} else {
					PUT_TO(rn, p[i+j]);
				}
			}
			DISCARD_TEXT(rn);
		} else if (tracking) tracking->fragment_length++;
	}

@ This is a slow search, of course, but the number of DRs is relatively low,
and we need to search fairly seldom:

=
documentation_ref *Index::DocReferences::name_to_dr(text_stream *fn) {
	documentation_ref *dr;
	LOOP_OVER(dr, documentation_ref)
		if (Str::eq(dr->symbol, fn))
			return dr;
	@<Complain about a bad documentation reference@>;
	return NULL;
}

@ You and I could write a bad reference:

@<Complain about a bad documentation reference@> =
	if (problem_count == 0) {
		LOG("Bad ref was <%s>. Known references are:\n", fn);
		LOOP_OVER(dr, documentation_ref)
			LOG("%S = %+N\n", dr->symbol, dr->section);
		internal_error("Bad index documentation reference");
	}
