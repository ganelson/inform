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
	struct text_stream *rubric_as_lexed;
	struct text_stream *extra_credit_as_lexed;
	struct source_file *read_into_file; /* Which source file loaded this */
	struct inbuild_requirement *must_satisfy;
	#ifdef CORE_MODULE
	int loaded_from_built_in_area; /* Located within Inform application */
	struct parse_node *inclusion_sentence; /* Where the source called for this */
	#endif
	MEMORY_MANAGEMENT
} inform_extension;

inform_extension *Extensions::new_ie(void) {
	inform_extension *E = CREATE(inform_extension);
	E->as_copy = NULL;
	E->body_text = EMPTY_WORDING;
	E->body_text_unbroken = FALSE;
	E->documentation_text = EMPTY_WORDING;
	E->VM_restriction_text = EMPTY_WORDING;
	E->standard = FALSE;
	E->authorial_modesty = FALSE;
	E->read_into_file = NULL;
	E->rubric_as_lexed = NULL;
	E->extra_credit_as_lexed = NULL;	
	E->must_satisfy = NULL;
	#ifdef CORE_MODULE
	E->loaded_from_built_in_area = FALSE;
	E->inclusion_sentence = NULL;
	#endif
	return E;
}

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
		inbuild_version_number V = req->min_version;
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
	E->read_into_file = SourceText::read_file(F, synopsis, doc_only, E->as_copy->errors_reading_source_text, FALSE);
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
