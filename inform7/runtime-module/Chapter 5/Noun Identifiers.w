[NounIdentifiers::] Noun Identifiers.

Nametags provide for a more contextual parsing of nouns, allowing
them to be given in an inexact verbal form.

@h Identifiers.
Since I6 identifiers compiled by Inform are usually based on the names of
the things they represent -- a typical example would be |I45_silver_bars| --
it's convenient to associate them with nametags.

@d NOUN_COMPILATION_LINGUISTICS_CALLBACK NounIdentifiers::initialise_noun_compilation

=
typedef struct name_compilation_data {
	struct text_stream *nt_identifier;
	struct inter_name *nt_iname; /* (which will have that identifier) */
} name_compilation_data;

void NounIdentifiers::initialise_noun_compilation(noun *t) {
	if (t == NULL) internal_error("no noun");
	t->name_compilation.nt_identifier = Str::new();
	t->name_compilation.nt_iname = NULL;
}

text_stream *NounIdentifiers::identifier(noun *t) {
	if (t == NULL) return I"nothing";
	return t->name_compilation.nt_identifier;
}

inter_name *NounIdentifiers::iname(noun *t) {
	if (t == NULL) return NULL;
	if (t->name_compilation.nt_iname == NULL) {
		LOG("So %W / %S is stuck\n",
			Nouns::nominative(t, FALSE), t->name_compilation.nt_identifier);
		internal_error("noun compilation failed");
	}
	return t->name_compilation.nt_iname;
}

int NounIdentifiers::iname_set(noun *t) {
	if (t == NULL) return FALSE;
	if (t->name_compilation.nt_iname == NULL) return FALSE;
	return TRUE;
}

void NounIdentifiers::noun_compose_identifier(package_request *R, noun *t, int N) {
	if (t->name_compilation.nt_iname == NULL) {
		wording W = Nouns::nominative(t, FALSE);
		t->name_compilation.nt_iname = Hierarchy::make_iname_with_memo(INSTANCE_HL, R, W);
	}
}

void NounIdentifiers::noun_impose_identifier(noun *t, inter_name *iname) {
	if (t->name_compilation.nt_iname == NULL) t->name_compilation.nt_iname = iname;
}

void NounIdentifiers::noun_set_translation(noun *t, text_stream *new) {
	if (t->name_compilation.nt_iname == NULL) internal_error("no instance iname yet");
	Str::clear(t->name_compilation.nt_identifier);
	Str::copy(t->name_compilation.nt_identifier, new);
	if (Str::get_first_char(t->name_compilation.nt_identifier) == '"')
		Str::delete_first_character(t->name_compilation.nt_identifier);
	if (Str::get_last_char(t->name_compilation.nt_identifier) == '"')
		Str::delete_last_character(t->name_compilation.nt_identifier);
	Produce::change_translation(t->name_compilation.nt_iname, t->name_compilation.nt_identifier);
	Produce::clear_flag(t->name_compilation.nt_iname, MAKE_NAME_UNIQUE);
	Hierarchy::make_available(Emit::tree(), t->name_compilation.nt_iname);
}

@ The identifiers are created all at once, but the process is complicated by
the fact that the source text is allowed to override our choices. For
instance, the Standard Rules want the player-character object to be called
|selfobj| in I6 source text, not something like |I32_yourself|.

=
void NounIdentifiers::name_all(void) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		RTKinds::assure_iname_exists(K);
	SyntaxTree::traverse(Task::syntax_tree(), NounIdentifiers::visit_to_name);
}

void NounIdentifiers::visit_to_name(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down))
		MajorNodes::try_special_meaning(INTER_NAMING_SMFT, p->down);
}
