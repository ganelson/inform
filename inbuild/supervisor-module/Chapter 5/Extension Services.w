[Extensions::] Extension Services.

Behaviour specific to copies of the extension genre.

@h Scanning metadata.
An extension has a title and an author name, each of which is limited in
length to one character less than the following constants:

@d MAX_EXTENSION_TITLE_LENGTH 51
@d MAX_EXTENSION_AUTHOR_LENGTH 51

=
typedef struct inform_extension {
	struct inbuild_copy *as_copy;
	struct wording body_text; /* Body of source text supplied in extension, if any */
	int body_text_unbroken; /* Does this contain text waiting to be sentence-broken? */
	struct wording documentation_text; /* Documentation supplied in extension, if any */
	int standard; /* the (or perhaps just a) Standard Rules extension */
	int authorial_modesty; /* Do not credit in the compiled game */
	struct text_stream *rubric_as_lexed; /* brief description found in opening lines */
	struct text_stream *extra_credit_as_lexed;
	struct source_file *read_into_file; /* Which source file loaded this */
	struct inbuild_requirement *must_satisfy;
	int loaded_from_built_in_area; /* Located within Inform application */
	struct inform_project *read_into_project; /* If any */
	struct parse_node_tree *syntax_tree;
	struct parse_node *inclusion_sentence; /* Where the source called for this */
	int auto_included;
	struct linked_list *search_list; /* of |inbuild_nest| */	
	int word_count; /* or 0 if this hasn't been read (yet) */
	struct text_stream *last_usage_date; /* perhaps on a previous run */
	struct text_stream *sort_usage_date; /* used temporarily when sorting */	
	int has_historically_been_used;
	CLASS_DEFINITION
} inform_extension;

@ This is called as soon as a new copy |C| of the extension genre is created.
We scan the extension file for the title, author, version number and any
compatibility notes given (such as "for Glulx only").

=
void Extensions::scan(inbuild_copy *C) {
	inform_extension *E = CREATE(inform_extension);
	E->as_copy = C;
	Copies::set_metadata(C, STORE_POINTER_inform_extension(E));
	@<Initialise the extension docket@>;

	TEMPORARY_TEXT(claimed_author_name)
	TEMPORARY_TEXT(claimed_title)
	TEMPORARY_TEXT(reqs)
	semantic_version_number V = VersionNumbers::null();
	@<Scan the file@>;
	@<Change the edition of the copy in light of the metadata found in the scan@>;
	DISCARD_TEXT(claimed_author_name)
	DISCARD_TEXT(claimed_title)
	DISCARD_TEXT(reqs)

	if (Works::is_basic_inform(C->edition->work)) E->standard = TRUE;
	if (Works::is_standard_rules(C->edition->work)) E->standard = TRUE;
}

@<Initialise the extension docket@> =
	E->body_text = EMPTY_WORDING;
	E->body_text_unbroken = FALSE;
	E->documentation_text = EMPTY_WORDING;
	E->standard = FALSE;
	E->authorial_modesty = FALSE;
	E->read_into_file = NULL;
	E->rubric_as_lexed = Str::new();
	E->extra_credit_as_lexed = NULL;	
	E->must_satisfy = NULL;
	E->loaded_from_built_in_area = FALSE;
	E->read_into_project = NULL;
	E->syntax_tree = SyntaxTree::new();
	E->inclusion_sentence = NULL;
	E->auto_included = FALSE;
	E->search_list = NEW_LINKED_LIST(inbuild_nest);
	E->has_historically_been_used = FALSE;
	E->word_count = 0;
	E->last_usage_date = Str::new();
	E->sort_usage_date = Str::new();
	
@ The following scans a potential extension file. If it seems malformed, a
suitable error is written to the stream |error_text|. If not, this is left
alone, and the version number is returned.

=
@<Scan the file@> =
	TEMPORARY_TEXT(titling_line)
	TEMPORARY_TEXT(version_text)
	filename *F = C->location_if_file;
	FILE *EXTF = Filenames::fopen_caseless(F, "r");
	if (EXTF == NULL) {
		Copies::attach_error(C, CopyErrors::new_F(OPEN_FAILED_CE, -1, F));
	} else {
		@<Read the titling line of the extension and normalise its casing@>;
		@<Read the rubric text, if any is present@>;
		@<Parse the version, title, author and VM requirements from the titling line@>;
		fclose(EXTF);
		if (Str::len(version_text) > 0) {
			V = VersionNumbers::from_text(version_text);
			if (VersionNumbers::is_null(V)) {
				TEMPORARY_TEXT(error_text)
				WRITE_TO(error_text, "the version number '%S' is malformed", version_text);
				Copies::attach_error(C, CopyErrors::new_T(EXT_MISWORDED_CE, -1, error_text));
				DISCARD_TEXT(error_text)
			}
		}
	}
	DISCARD_TEXT(titling_line)
	DISCARD_TEXT(version_text)

@ The titling line is terminated by any of |0A|, |0D|, |0A 0D| or |0D 0A|, or
by the local |\n| for good measure.

@<Read the titling line of the extension and normalise its casing@> =
	int c;
	while ((c = TextFiles::utf8_fgetc(EXTF, NULL, FALSE, NULL)) != EOF) {
		if (c == 0xFEFF) continue; /* skip the optional Unicode BOM pseudo-character */
		if ((c == '\x0a') || (c == '\x0d') || (c == '\n')) break;
		PUT_TO(titling_line, c);
	}
	Str::trim_white_space(titling_line);
	Works::normalise_casing_mixed(titling_line);

@ In the following, all possible newlines are converted to white space, and
all white space before a quoted rubric text is ignored. We need to do this
partly because users have probably keyed a double line break before the
rubric, but also because we might have stopped reading the titling line
halfway through a line division combination like |0A 0D|, so that the first
thing we read here is a meaningless |0D|.

@<Read the rubric text, if any is present@> =
	int c, found_start = FALSE;
	while ((c = TextFiles::utf8_fgetc(EXTF, NULL, FALSE, NULL)) != EOF) {
		if ((c == '\x0a') || (c == '\x0d') || (c == '\n') || (c == '\t')) c = ' ';
		if ((c != ' ') && (found_start == FALSE)) {
			if (c == '"') found_start = TRUE;
			else break;
		} else {
			if (c == '"') break;
			if (found_start) PUT_TO(E->rubric_as_lexed, c);
		}
	}

@ In general, once case-normalised, a titling line looks like this:

>> Version 2/070423 Of Going To The Zoo (For Glulx Only) By Cary Grant Begins Here.

and the version information, the VM restriction and the full stop are all
optional, but the division word "of" and the concluding "begin[s] here"
are not. We break it up into pieces; for speed, we won't use the lexer to
load the entire file.

@<Parse the version, title, author and VM requirements from the titling line@> =
	match_results mr = Regexp::create_mr();
	if (Str::get_last_char(titling_line) == '.') Str::delete_last_character(titling_line);
	if ((Regexp::match(&mr, titling_line, L"(%c*) Begin Here")) ||
		(Regexp::match(&mr, titling_line, L"(%c*) Begins Here"))) {
		Str::copy(titling_line, mr.exp[0]);
	} else {
		if ((Regexp::match(&mr, titling_line, L"(%c*) Start Here")) ||
			(Regexp::match(&mr, titling_line, L"(%c*) Starts Here"))) {
			Str::copy(titling_line, mr.exp[0]);
		}
		Copies::attach_error(C, CopyErrors::new_T(EXT_MISWORDED_CE, -1,
			I"the opening line does not end 'begin(s) here'"));
	}
	@<Scan the version text, if any, and advance to the position past Version... Of@>;
	if (Regexp::match(&mr, titling_line, L"The (%c*)")) Str::copy(titling_line, mr.exp[0]);
	@<Divide the remaining text into a claimed author name and title, divided by By@>;
	@<Extract the VM requirements text, if any, from the claimed title@>;
	Regexp::dispose_of(&mr);

@ We make no attempt to check the version number for validity: the purpose
of the census is to identify extensions and reject accidentally included
other files, not to syntax-check all extensions to see if they would work
if used.

@<Scan the version text, if any, and advance to the position past Version... Of@> =
	if (Regexp::match(&mr, titling_line, L"Version (%c*?) Of (%c*)")) {
		Str::copy(version_text, mr.exp[0]);
		Str::copy(titling_line, mr.exp[1]);
	}

@ The earliest "by" is the divider: note that extension titles are not
allowed to contain this word, so "North By Northwest By Cary Grant" is
not a situation we need to contend with.

@<Divide the remaining text into a claimed author name and title, divided by By@> =
	if (Regexp::match(&mr, titling_line, L"(%c*?) By (%c*)")) {
		Str::copy(claimed_title, mr.exp[0]);
		Str::copy(claimed_author_name, mr.exp[1]);
	} else {
		Str::copy(claimed_title, titling_line);
		Copies::attach_error(C, CopyErrors::new_T(EXT_MISWORDED_CE, -1,
			I"the titling line does not give both author and title"));
	}

@ Similarly, extension titles are not allowed to contain parentheses, so
this is unambiguous.

@<Extract the VM requirements text, if any, from the claimed title@> =
	if (Regexp::match(&mr, claimed_title, L"(%c*?) *(%(%c*%))")) {
		Str::copy(claimed_title, mr.exp[0]);
		Str::copy(reqs, mr.exp[1]);
	}

@ Note that we don't attempt to modify the |inbuild_work| structure inside
the edition; we create an entirely new |inbuild_work|. That's because they
are immutable, and need to be for the extensions dictionary to work.

@<Change the edition of the copy in light of the metadata found in the scan@> =
	if (Str::len(claimed_title) == 0) { WRITE_TO(claimed_title, "Unknown"); }
	if (Str::len(claimed_author_name) == 0) { WRITE_TO(claimed_author_name, "Anonymous"); }
	if (Str::len(claimed_title) > MAX_EXTENSION_TITLE_LENGTH)
		Copies::attach_error(C,
			CopyErrors::new_N(EXT_TITLE_TOO_LONG_CE, -1, Str::len(claimed_title)));
	if (Str::len(claimed_author_name) > MAX_EXTENSION_AUTHOR_LENGTH)
		Copies::attach_error(C,
			CopyErrors::new_N(EXT_AUTHOR_TOO_LONG_CE, -1, Str::len(claimed_author_name)));
	C->edition = Editions::new(
		Works::new_raw(extension_genre, claimed_title, claimed_author_name), V);
	if (Str::len(reqs) > 0) {
		compatibility_specification *CS = Compatibility::from_text(reqs);
		if (CS) C->edition->compatibility = CS;
		else {
			TEMPORARY_TEXT(err)
			WRITE_TO(err, "cannot read compatibility '%S'", reqs);
			Copies::attach_error(C, CopyErrors::new_T(EXT_MISWORDED_CE, -1, err));
			DISCARD_TEXT(err)
		}
	}

@h Cached metadata.
The following data hides between runs in the //Dictionary//.

=
void Extensions::set_usage_date(inform_extension *E, text_stream *date) {
	Str::clear(E->last_usage_date);
	Str::copy(E->last_usage_date, date);
}

void Extensions::set_sort_date(inform_extension *E, text_stream *date) {
	Str::clear(E->sort_usage_date);
	Str::copy(E->sort_usage_date, date);
}

text_stream *Extensions::get_usage_date(inform_extension *E) {
	return E->last_usage_date;
}

text_stream *Extensions::get_sort_date(inform_extension *E) {
	return E->sort_usage_date;
}

void Extensions::set_word_count(inform_extension *E, int wc) {
	E->word_count = wc;
}

int Extensions::get_word_count(inform_extension *E) {
	return E->word_count;
}

text_stream *Extensions::get_sort_word_count(inform_extension *E) {
	text_stream *T = Str::new();
	WRITE_TO(T, "%8d", E->word_count);
	return T;
}

int Extensions::compare_by_edition(inform_extension *E1, inform_extension *E2) {
	if ((E1 == NULL) || (E2 == NULL)) internal_error("bad work match");
	int d = Works::cmp(E1->as_copy->edition->work, E2->as_copy->edition->work);
	if (d != 0) return d;
	return VersionNumbers::cmp(
		E1->as_copy->edition->version, E2->as_copy->edition->version);
}

int Extensions::compare_by_date(inform_extension *E1, inform_extension *E2) {
	if ((E1 == NULL) || (E2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(Extensions::get_sort_date(E2), Extensions::get_sort_date(E1));
	if (d != 0) return d;
	return Extensions::compare_by_edition(E1, E2);
}

int Extensions::compare_by_author(inform_extension *E1, inform_extension *E2) {
	if ((E1 == NULL) || (E2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(E2->as_copy->edition->work->author_name,
		E1->as_copy->edition->work->author_name);
	if (d != 0) return d;
	return Extensions::compare_by_edition(E1, E2);
}

int Extensions::compare_by_title(inform_extension *E1, inform_extension *E2) {
	if ((E1 == NULL) || (E2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(E2->as_copy->edition->work->title,
		E1->as_copy->edition->work->title);
	if (d != 0) return d;
	return Extensions::compare_by_edition(E1, E2);
}

int Extensions::compare_by_length(inform_extension *E1, inform_extension *E2) {
	if ((E1 == NULL) || (E2 == NULL)) internal_error("bad work match");
	int d = Str::cmp(
		Extensions::get_sort_word_count(E2), Extensions::get_sort_word_count(E1));
	if (d != 0) return d;
	return Extensions::compare_by_edition(E1, E2);
}

@h Search list.
Sometimes ane extension is being looked at in isolation, and then |read_into_project|
will be |NULL|; but if it is being loaded to be included in the source text of a
project, then...

=
void Extensions::set_associated_project(inform_extension *E, inform_project *P) {
	E->read_into_project = P;
}

@ ...and this affects its search list, because now its own inclusions can see
the Materials folder of the project in question:

=
linked_list *Extensions::nest_list(inform_extension *E) {
	if (E == NULL) return Supervisor::shared_nest_list();
	RUN_ONLY_FROM_PHASE(NESTED_INBUILD_PHASE)
	if (LinkedLists::len(E->search_list) == 0) {
		inform_project *proj = E->read_into_project;
		if (proj) ADD_TO_LINKED_LIST(proj->materials_nest, inbuild_nest, E->search_list);
		inbuild_nest *N;
		linked_list *L = Supervisor::shared_nest_list();
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, L)
			ADD_TO_LINKED_LIST(N, inbuild_nest, E->search_list);
	}
	return E->search_list;
}

@h Graph.
The dependency graph is not so much constructed as discovered; dependencies
are made to each other extension as it's Included in this one, during the
course of reading in the text.

Note that this function is not called when graphing a project which Includes
this extension: this is called only when //inbuild// wants to see the graph
of an extension in isolation from projects. (That's why we must perform the
Inclusion traverse: for a project this traverse would come later, but with
no project involved, we must take action ourselves.)

=
void Extensions::construct_graph(inform_extension *E) {
	Copies::get_source_text(E->as_copy);
	Sentences::set_start_of_source(sfsm, -1);
	Inclusions::traverse(E->as_copy, E->syntax_tree);
}

@h Read source text.
The scan only skimmed the surface of the file, and didn't try to parse it as
natural language text with Preform. But if the extension turns out to be one
that we need to use for something, we'll need to read its full text eventually.
This is that time.

At present all extensions are assumed to have English as the language of syntax.

=
void Extensions::read_source_text_for(inform_extension *E) {
	inform_language *L = Languages::find_for(I"English", Extensions::nest_list(E));
	Languages::read_Preform_definition(L, Extensions::nest_list(E));
	filename *F = E->as_copy->location_if_file;
	int doc_only = FALSE;
	if (census_mode) doc_only = TRUE;
	TEMPORARY_TEXT(synopsis)
	@<Concoct a synopsis for the extension to be read@>;
	E->read_into_file = SourceText::read_file(E->as_copy, F, synopsis, doc_only, FALSE);
	DISCARD_TEXT(synopsis)
	if (E->read_into_file) {
		E->read_into_file->your_ref = STORE_POINTER_inbuild_copy(E->as_copy);
		@<Break the text into sentences@>;
		E->body_text_unbroken = FALSE;
	}
}

@ We concoct a textual synopsis in the form
= (text)
	"Pantomime Sausages by Mr Punch"
=
to be used by |SourceFiles::read_extension_source_text| for printing to |stdout|. Since
we dare not assume |stdout| can manage characters outside the basic ASCII
range, we flatten them from general ISO to plain ASCII.

@<Concoct a synopsis for the extension to be read@> =
	WRITE_TO(synopsis, "%S by %S", 
		E->as_copy->edition->work->title,
		E->as_copy->edition->work->author_name);
	LOOP_THROUGH_TEXT(pos, synopsis)
		Str::put(pos,
			Characters::make_wchar_t_filename_safe(
				Str::get(pos)));

@ Note that if there is an active project, then we are reading the extension
in order to include it in that, and so we send it to the project's syntax tree,
rather than to the extension's own one. But if we are simply examining the
extension by running |-graph| on it in the Inbuild command line, for example,
then its sentences will go to the extension's own tree.

@<Break the text into sentences@> =
	wording EXW = E->read_into_file->text_read;
	if (Wordings::nonempty(EXW))
		@<Break the extension's text into body and documentation@>;
	inform_project *project = E->read_into_project;
	if (project) E->syntax_tree = project->syntax_tree;
	Sentences::break_into_extension_copy(E->syntax_tree,
		E->body_text, E->as_copy, project);
	E->body_text_unbroken = FALSE;

@  If an extension file contains the special text (outside literal mode) of
|---- Documentation ----| then this is taken as the end of the Inform source,
and the beginning of a snippet of documentation about the extension; text from
that point on is saved until later, but not broken into sentences for the
parse tree, and it is therefore invisible to the rest of Inform. If this
division line is not present then the extension contains only body source
and no documentation.

=
<extension-body> ::=
	*** ---- documentation ---- ... |  ==> { TRUE, - }
	...                                ==> { FALSE, - }

@<Break the extension's text into body and documentation@> =
	<extension-body>(EXW);
	E->body_text = GET_RW(<extension-body>, 1);
	if (<<r>>) E->documentation_text = GET_RW(<extension-body>, 2);
	E->body_text_unbroken = TRUE; /* mark this to be sentence-broken */

@ When the extension source text was read from its |source_file|, we
attached a reference to say which |inform_extension| it was, and here we
make use of that:

=
inform_extension *Extensions::corresponding_to(source_file *sf) {
	if (sf == NULL) return NULL;
	inbuild_copy *C = RETRIEVE_POINTER_inbuild_copy(sf->your_ref);
	if (C == NULL) return NULL;
	if (C->edition->work->genre != extension_genre) return NULL;
	return ExtensionManager::from_copy(C);
}

@h Miscellaneous.

=
void Extensions::write(OUTPUT_STREAM, inform_extension *E) {
	if (E == NULL) WRITE("none");
	else WRITE("%X", E->as_copy->edition->work);
}

void Extensions::write_name_to_file(inform_extension *E, OUTPUT_STREAM) {
	WRITE("%S", E->as_copy->edition->work->raw_title);
}

void Extensions::write_author_to_file(inform_extension *E, OUTPUT_STREAM) {
	WRITE("%S", E->as_copy->edition->work->raw_author_name);
}

@ Three pieces of information will be set later on, by other parts of Inform
calling the routines below.

The rubric text for an extension, which is double-quoted matter just below
its "begins here" line, is parsed as a sentence and will be read as an
assertion in the usual way when the material from this extension is being
worked through (quite a long time after the EF structure was created). When
that happens, the following function will be called to set the rubric.

=
void Extensions::set_rubric(inform_extension *E, text_stream *text) {
	if (E == NULL) internal_error("no extension");
	E->rubric_as_lexed = Str::duplicate(text);
	LOGIF(EXTENSIONS_CENSUS, "Extension rubric: %S\n", E->rubric_as_lexed);
}

text_stream *Extensions::get_rubric(inform_extension *E) {
	if (E == NULL) return NULL;
	return E->rubric_as_lexed;
}

@ The optional extra credit line is used to acknowledge I6 sources,
collaborators, translators and so on.

=
void Extensions::set_extra_credit(inform_extension *E, text_stream *text) {
	if (E == NULL) internal_error("no extension");
	E->extra_credit_as_lexed = Str::duplicate(text);
	LOGIF(EXTENSIONS_CENSUS, "Extension extra credit: %S\n", E->extra_credit_as_lexed);
}

@ The use option "authorial modesty" is unusual in applying to the extension
it is found in, not the whole source text. When we read it, we call one of
the following routines, depending on whether it was in an extension or in
the main source text:

=
int general_authorial_modesty = FALSE;
void Extensions::set_authorial_modesty(inform_extension *E) {
	if (E == NULL) internal_error("no extension");
	E->authorial_modesty = TRUE;
}
void Extensions::set_general_authorial_modesty(void) {
	general_authorial_modesty = TRUE;
}

@ The inclusion sentence for an extension is where it was Included in a
project's syntax tree (if it was). It isn't used in compilation, only for
problem messages and the index.

=
void Extensions::set_inclusion_sentence(inform_extension *E, parse_node *N) {
	E->inclusion_sentence = N;
}
parse_node *Extensions::get_inclusion_sentence(inform_extension *E) {
	if (E == NULL) return NULL;
	return E->inclusion_sentence;
}

@ An extension is "standard" if it's either the Standard Rules or Basic Inform.

=
int Extensions::is_standard(inform_extension *E) {
	if (E == NULL) return FALSE;
	return E->standard;
}

@h Version requirements.
When it's known that an extension must satisfy a given version requirement --
say, being version 7.2.1 or better -- the following is called. Note that
if incompatible requirements are placed on it, the range in |E->must_satisfy|
becomes empty and stays that way. 

=
void Extensions::must_satisfy(inform_extension *E, inbuild_requirement *req) {
	if (E->must_satisfy == NULL) E->must_satisfy = req;
	else VersionNumberRanges::intersect_range(E->must_satisfy->version_range, req->version_range);
}

@ And it is certainly possible, if an extension is loaded for multiple
reasons with different versioning needs, that the extension no longer meets
its requirements (even though it did when first loaded). This tests for that:

=
int Extensions::satisfies(inform_extension *E) {
	if (E == NULL) return FALSE;
	return Requirements::meets(E->as_copy->edition, E->must_satisfy);
}
