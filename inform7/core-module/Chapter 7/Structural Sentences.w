[StructuralSentences::] Structural Sentences.

To parse structurally important sentences.

@


@h Sentence division.
Sentence division can happen either early in Inform's run, when the vast bulk
of the source text is read, or at intermittent periods later when fresh text
is generated internally. New sentences need to be treated slightly differently
in these cases, so this seems as good a point as any to define the routine
which the |.i6t| interpreter calls when it wants to signal that the source
text has now officially been read.

@d SENTENCE_ANNOTATION_FUNCTION StructuralSentences::annotate_new_sentence

=
int text_loaded_from_source = FALSE;
void StructuralSentences::declare_source_loaded(void) {
	text_loaded_from_source = TRUE;
}

void StructuralSentences::annotate_new_sentence(parse_node *new) {
	if (text_loaded_from_source) {
		ParseTree::annotate_int(new, sentence_unparsed_ANNOT, FALSE);
		Sentences::VPs::seek(new);
	}
}

@

@d NEW_BEGINEND_HANDLER StructuralSentences::new_beginend

=
void StructuralSentences::new_beginend(parse_node *new, inbuild_copy *C) {
	inform_extension *E = ExtensionManager::from_copy(C);
	if (ParseTree::get_type(new) == BEGINHERE_NT)
		Extensions::Inclusion::check_begins_here(new, E);
	if (ParseTree::get_type(new) == ENDHERE_NT)
		Extensions::Inclusion::check_ends_here(new, E);
}

@

@d NEW_LANGUAGE_HANDLER StructuralSentences::new_language

=
void StructuralSentences::new_language(wording W) {
	parse_node_tree *T = NULL;

	inform_project *project = ProjectBundleManager::from_copy(sfsm_copy);
	if (project == NULL) project = ProjectFileManager::from_copy(sfsm_copy);
	if (project) T = project->syntax_tree;
	inform_extension *ext = ExtensionManager::from_copy(sfsm_copy);
	if (ext) T = ext->syntax_tree;
	
	if (T == NULL) internal_error("unable to locate syntax tree");

	Problems::Issue::sentence_problem(T, _p_(PM_UseElementWithdrawn),
		"the ability to activate or deactivate compiler elements in source text has been withdrawn",
		"in favour of a new system with Inform kits.");
}
