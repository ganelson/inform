[Extensions::] Extension Services.

An Inform 7 extension.

@

@d EXTENSION_FILE_TYPE inform_extension

=
typedef struct inform_extension {
	struct inbuild_copy *as_copy;
	struct wording body_text; /* Body of source text supplied in extension, if any */
	int body_text_unbroken; /* Does this contain text waiting to be sentence-broken? */
	struct wording documentation_text; /* Documentation supplied in extension, if any */
	struct wording VM_restriction_text; /* Restricting use to certain VMs */
	int standard; /* the (or perhaps just a) Standard Rules extension */
	int authorial_modesty; /* Do not credit in the compiled game */
	struct text_stream *rubric_as_lexed; /* brief description found in opening lines */
	struct text_stream *extra_credit_as_lexed;
	struct source_file *read_into_file; /* Which source file loaded this */
	struct inbuild_requirement *must_satisfy;
	#ifdef CORE_MODULE
	int loaded_from_built_in_area; /* Located within Inform application */
	struct parse_node *inclusion_sentence; /* Where the source called for this */
	#endif
	MEMORY_MANAGEMENT
} inform_extension;

void Extensions::scan(inbuild_genre *G, inbuild_copy *C) {
	inform_extension *E = CREATE(inform_extension);
	E->as_copy = C;
	Copies::set_content(C, STORE_POINTER_inform_extension(E));
	E->body_text = EMPTY_WORDING;
	E->body_text_unbroken = FALSE;
	E->documentation_text = EMPTY_WORDING;
	E->VM_restriction_text = EMPTY_WORDING;
	E->standard = FALSE;
	E->authorial_modesty = FALSE;
	E->read_into_file = NULL;
	E->rubric_as_lexed = Str::new();
	E->extra_credit_as_lexed = NULL;	
	E->must_satisfy = NULL;
	#ifdef CORE_MODULE
	E->loaded_from_built_in_area = FALSE;
	E->inclusion_sentence = NULL;
	#endif

	TEMPORARY_TEXT(claimed_author_name);
	TEMPORARY_TEXT(claimed_title);
	TEMPORARY_TEXT(reqs);
	filename *F = C->location_if_file;
	semantic_version_number V = VersionNumbers::null();
	@<Scan the file@>;
	if (Str::len(claimed_title) == 0) { WRITE_TO(claimed_title, "Unknown"); }
	if (Str::len(claimed_author_name) == 0) { WRITE_TO(claimed_author_name, "Anonymous"); }
	if (Str::len(claimed_title) > MAX_EXTENSION_TITLE_LENGTH) {
		Copies::attach(C, Copies::new_error_N(EXT_TITLE_TOO_LONG_CE, Str::len(claimed_title)));
	}
	if (Str::len(claimed_author_name) > MAX_EXTENSION_AUTHOR_LENGTH) {
		Copies::attach(C, Copies::new_error_N(EXT_AUTHOR_TOO_LONG_CE, Str::len(claimed_author_name)));
	}
	C->edition = Editions::new(Works::new(extension_genre, claimed_title, claimed_author_name), V);
	if (Str::len(reqs) > 0) {
		compatibility_specification *CS = Compatibility::from_text(reqs);
		if (CS) C->edition->compatibility = CS;
		else {
			TEMPORARY_TEXT(err);
			WRITE_TO(err, "cannot read compatibility '%S'", reqs);
			Copies::attach(C, Copies::new_error(EXT_MISWORDED_CE, err));
			DISCARD_TEXT(err);
		}
	}
	Works::add_to_database(C->edition->work, CLAIMED_WDBC);
	DISCARD_TEXT(claimed_author_name);
	DISCARD_TEXT(claimed_title);
	DISCARD_TEXT(reqs);
}

@ The following scans a potential extension file. If it seems malformed, a
suitable error is written to the stream |error_text|. If not, this is left
alone, and the version number is returned.

=
@<Scan the file@> =
	TEMPORARY_TEXT(titling_line);
	TEMPORARY_TEXT(version_text);
	FILE *EXTF = Filenames::fopen_caseless(F, "r");
	if (EXTF == NULL) {
		Copies::attach(C, Copies::new_error_on_file(OPEN_FAILED_CE, F));
	} else {
		@<Read the titling line of the extension and normalise its casing@>;
		@<Read the rubric text, if any is present@>;
		@<Parse the version, title, author and VM requirements from the titling line@>;
		fclose(EXTF);
		if (Str::len(version_text) > 0) {
			V = VersionNumbers::from_text(version_text);
			if (VersionNumbers::is_null(V)) {
				TEMPORARY_TEXT(error_text);
				WRITE_TO(error_text, "the version number '%S' is malformed", version_text);
				Copies::attach(C, Copies::new_error(EXT_MISWORDED_CE, error_text));
				DISCARD_TEXT(error_text);
			}
		}
	}
	DISCARD_TEXT(titling_line);
	DISCARD_TEXT(version_text);

@ The titling line is terminated by any of |0A|, |0D|, |0A 0D| or |0D 0A|, or
by the local |\n| for good measure.

@<Read the titling line of the extension and normalise its casing@> =
	int c;
	while ((c = TextFiles::utf8_fgetc(EXTF, NULL, FALSE, NULL)) != EOF) {
		if (c == 0xFEFF) continue; /* skip the optional Unicode BOM pseudo-character */
		if ((c == '\x0a') || (c == '\x0d') || (c == '\n')) break;
		PUT_TO(titling_line, c);
	}
	Works::normalise_casing(titling_line);

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
		Copies::attach(C, Copies::new_error(EXT_MISWORDED_CE,
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
		Copies::attach(C, Copies::new_error(EXT_MISWORDED_CE, 
			I"the titling line does not give both author and title"));
	}

@ Similarly, extension titles are not allowed to contain parentheses, so
this is unambiguous.

@<Extract the VM requirements text, if any, from the claimed title@> =
	if (Regexp::match(&mr, claimed_title, L"(%c*?) *(%(%c*%))")) {
		Str::copy(claimed_title, mr.exp[0]);
		Str::copy(reqs, mr.exp[1]);
	}

@ =
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

@ Three pieces of information (not available when the EF is created) will
be set later on, by other parts of Inform calling the routines below.

The rubric text for an extension, which is double-quoted matter just below
its "begins here" line, is parsed as a sentence and will be read as an
assertion in the usual way when the material from this extension is being
worked through (quite a long time after the EF structure was created). When
that happens, the following routine will be called to set the rubric; and
the one after for the optional extra credit line, used to acknowledge I6
sources, collaborators, translators and so on.

=
void Extensions::set_rubric(inform_extension *E, text_stream *text) {
	if (E == NULL) internal_error("unfound ef");
	E->rubric_as_lexed = Str::duplicate(text);
	LOGIF(EXTENSIONS_CENSUS, "Extension rubric: %S\n", E->rubric_as_lexed);
}

text_stream *Extensions::get_rubric(inform_extension *E) {
	if (E == NULL) return NULL;
	return E->rubric_as_lexed;
}

void Extensions::set_extra_credit(inform_extension *E, text_stream *text) {
	if (E == NULL) internal_error("unfound ef");
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
	if (E == NULL) internal_error("unfound ef");
	E->authorial_modesty = TRUE;
}
void Extensions::set_general_authorial_modesty(void) { general_authorial_modesty = TRUE; }

#ifdef CORE_MODULE
void Extensions::set_inclusion_sentence(inform_extension *E, parse_node *N) {
	E->inclusion_sentence = N;
}
parse_node *Extensions::get_inclusion_sentence(inform_extension *E) {
	if (E == NULL) return NULL;
	return E->inclusion_sentence;
}
#endif

void Extensions::set_VM_text(inform_extension *E, wording W) {
	E->VM_restriction_text = W;
}
wording Extensions::get_VM_text(inform_extension *E) {
	return E->VM_restriction_text;
}

int Extensions::is_standard(inform_extension *E) {
	if (E == NULL) return FALSE;
	return E->standard;
}

void Extensions::make_standard(inform_extension *E) {
	E->standard = TRUE;
}

#ifdef CORE_MODULE
void Extensions::must_satisfy(inform_extension *E, inbuild_requirement *req) {
	if (E->must_satisfy == NULL) E->must_satisfy = req;
	else {
		semantic_version_number V = req->min_version;
		if (VersionNumbers::is_null(V) == FALSE)
			if (Requirements::ratchet_minimum(V, E->must_satisfy))
				Extensions::set_inclusion_sentence(E, current_sentence);
	}
}
#endif

int Extensions::satisfies(inform_extension *E) {
	if (E == NULL) return FALSE;
	return Requirements::meets(E->as_copy->edition, E->must_satisfy);
}

@

=
void Extensions::read_source_text_for(inform_extension *E) {
	filename *F = E->as_copy->location_if_file;
	int doc_only = FALSE;
	#ifdef CORE_MODULE
	if (CoreMain::census_mode()) doc_only = TRUE;
	#endif
	TEMPORARY_TEXT(synopsis);
	@<Concoct a synopsis for the extension to be read@>;
	E->read_into_file = SourceText::read_file(E->as_copy, F, synopsis, doc_only, FALSE);
	DISCARD_TEXT(synopsis);
	if (E->read_into_file) {
		E->read_into_file->your_ref = STORE_POINTER_inbuild_copy(E->as_copy);
		wording EXW = E->read_into_file->text_read;
		if (Wordings::nonempty(EXW)) @<Break the extension's text into body and documentation@>;
	}
}

@ We concoct a textual synopsis in the form

	|"Pantomime Sausages by Mr Punch"|

to be used by |SourceFiles::read_extension_source_text| for printing to |stdout|. Since
we dare not assume |stdout| can manage characters outside the basic ASCII
range, we flatten them from general ISO to plain ASCII.

@<Concoct a synopsis for the extension to be read@> =
	WRITE_TO(synopsis, "%S by %S", E->as_copy->edition->work->title, E->as_copy->edition->work->author_name);
	LOOP_THROUGH_TEXT(pos, synopsis)
		Str::put(pos,
			Characters::make_filename_safe(Str::get(pos)));

@  If an extension file contains the special text (outside literal mode) of

	|---- Documentation ----|

then this is taken as the end of the Inform source, and the beginning of a
snippet of documentation about the extension; text from that point on is
saved until later, but not broken into sentences for the parse tree, and it
is therefore invisible to the rest of Inform. If this division line is not
present then the extension contains only body source and no documentation.

=
<extension-body> ::=
	*** ---- documentation ---- ... |	==> TRUE
	...									==> FALSE

@<Break the extension's text into body and documentation@> =
	<extension-body>(EXW);
	E->body_text = GET_RW(<extension-body>, 1);
	if (<<r>>) E->documentation_text = GET_RW(<extension-body>, 2);
	E->body_text_unbroken = TRUE; /* mark this to be sentence-broken */
