[NounIdentifiers::] Noun Identifiers.

Instances and kinds are both referred to by nouns, and here we create corresponding
inames for use in compiled Inter code, and identifiers for use in the index.

@ |noun| objects are created in the //linguistics// module; the following attaches
some compilation data to those.

@d NOUN_COMPILATION_LINGUISTICS_CALLBACK NounIdentifiers::initialise_noun_compilation

=
typedef struct name_compilation_data {
	struct text_stream *nt_identifier;
	struct inter_name *nt_iname; /* (which will have that identifier) */
} name_compilation_data;

void NounIdentifiers::initialise_noun_compilation(noun *t) {
	if (t == NULL) internal_error("no noun");
	t->compilation_data.nt_identifier = Str::new();
	t->compilation_data.nt_iname = NULL;
}

@ This records a textual identifier...

=
text_stream *NounIdentifiers::identifier(noun *t) {
	if (t == NULL) return I"nothing";
	return t->compilation_data.nt_identifier;
}

@ ...and also an iname:

=
int NounIdentifiers::iname_set(noun *t) {
	if (t == NULL) return FALSE;
	if (t->compilation_data.nt_iname == NULL) return FALSE;
	return TRUE;
}

void NounIdentifiers::set_iname(noun *t, inter_name *iname) {
	if (t->compilation_data.nt_iname == NULL) t->compilation_data.nt_iname = iname;
}

inter_name *NounIdentifiers::iname(noun *t) {
	if (t == NULL) return NULL;
	if (t->compilation_data.nt_iname == NULL) internal_error("no iname for noun");
	return t->compilation_data.nt_iname;
}

@ If a noun is given an explicit Inter identifier -- for example, if the
player's avatar is given the identifier |selfobj| rather than, say, |I_yourself| --
then we need to change the textual identifier, and also the translation of
the iname. We also want it to be visible to the linker, and we know that the
name will be unique in the global namespace, so we tell the linker not to
mutate the name in order to achieve that uniqueness.

=
void NounIdentifiers::noun_set_translation(noun *t, text_stream *new) {
	if (t->compilation_data.nt_iname == NULL) internal_error("no instance iname yet");
	text_stream *ident = t->compilation_data.nt_identifier;
	Str::clear(ident);
	Str::copy(ident, new);
	if (Str::get_first_char(ident) == '"') Str::delete_first_character(ident);
	if (Str::get_last_char(ident) == '"') Str::delete_last_character(ident);
	inter_name *iname = t->compilation_data.nt_iname;
	if (iname) {
		InterNames::set_translation(iname, ident);
		InterNames::clear_flag(iname, MAKE_NAME_UNIQUE);
		Hierarchy::make_available(iname);
	}
}
