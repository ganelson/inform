[Extensions::] Extension Services.

An Inform 7 extension.

@ =
typedef struct inform_extension {
	struct inbuild_copy *as_copy;
	struct wording body_text; /* Body of source text supplied in extension, if any */
	int body_text_unbroken; /* Does this contain text waiting to be sentence-broken? */
	struct wording documentation_text; /* Documentation supplied in extension, if any */
	struct wording VM_restriction_text; /* Restricting use to certain VMs */
	int standard; /* the (or perhaps just a) Standard Rules extension */
	#ifdef CORE_MODULE
	int loaded_from_built_in_area; /* Located within Inform application */
	int authorial_modesty; /* Do not credit in the compiled game */
	struct extension_file *ef; /* Corresponding Inform7 compiler structure */
	struct text_stream *rubric_as_lexed;
	struct text_stream *extra_credit_as_lexed;
	struct parse_node *inclusion_sentence; /* Where the source called for this */
	#endif
	struct source_file *read_into_file; /* Which source file loaded this */
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
	#ifdef CORE_MODULE
	E->loaded_from_built_in_area = FALSE;
	E->authorial_modesty = FALSE;
	E->rubric_as_lexed = NULL;
	E->extra_credit_as_lexed = NULL;	
	E->read_into_file = NULL;
	E->ef = NULL;
	E->inclusion_sentence = NULL;
	#endif
	return E;
}

#ifdef CORE_MODULE
void Extensions::set_inclusion_sentence(inform_extension *E, parse_node *N) {
	E->inclusion_sentence = N;
}
#endif

void Extensions::set_VM_text(inform_extension *E, wording W) {
	E->VM_restriction_text = W;
}

int Extensions::is_standard(inform_extension *E) {
	if (E == NULL) return FALSE;
	return E->standard;
}

void Extensions::make_standard(inform_extension *E) {
	E->standard = TRUE;
}

@

@e EXT_MISWORDED_STE

=
void Extensions::read_source_text_for(inform_extension *E, linked_list *errors) {
	filename *F = E->as_copy->location_if_file;
	int doc_only = FALSE;
	#ifdef CORE_MODULE
	if (CoreMain::census_mode()) doc_only = TRUE;
	#endif
	TEMPORARY_TEXT(synopsis);
	@<Concoct a synopsis for the extension to be read@>;
	E->read_into_file = SourceText::read_file(F, synopsis, doc_only, errors, FALSE);
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
