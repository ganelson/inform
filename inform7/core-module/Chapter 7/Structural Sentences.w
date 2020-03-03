[StructuralSentences::] Structural Sentences.

To parse structurally important sentences.

@

@d list_node_type ROUTINE_NT
@d list_entry_node_type INVOCATION_LIST_NT

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

@d NEW_HEADING_HANDLER StructuralSentences::new_heading

=
int StructuralSentences::new_heading(parse_node *new) {
	heading *h = Sentences::Headings::declare(new);
	ParseTree::set_embodying_heading(new, h);
	return Sentences::Headings::include_material(h);
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
	Problems::Issue::sentence_problem(_p_(PM_UseElementWithdrawn),
		"the ability to activate or deactivate compiler elements in source text has been withdrawn",
		"in favour of a new system with Inform kits.");
}

@ This is for invented sentences, such as those creating the understood
variables.

=
void StructuralSentences::add_inventions_heading(void) {
	parse_node *implicit_heading = ParseTree::new(HEADING_NT);
	ParseTree::set_text(implicit_heading, Feeds::feed_text_expanding_strings(L"Invented sentences"));
	ParseTree::annotate_int(implicit_heading, sentence_unparsed_ANNOT, FALSE);
	ParseTree::annotate_int(implicit_heading, heading_level_ANNOT, 0);
	ParseTree::insert_sentence(implicit_heading);
	Sentences::Headings::declare(implicit_heading);
}
