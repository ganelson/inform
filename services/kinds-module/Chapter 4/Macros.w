[NeptuneMacros::] Macros.

Neptune supports named macros, though they are only lists of kind commands.

@

@d MAX_KIND_MACRO_LENGTH 20 /* maximum number of commands in any one macro */

=
typedef struct kind_macro_definition {
	struct text_stream *kind_macro_name; /* including the sharp, e.g., |"#UNIT"| */
	int kind_macro_line_count;
	struct single_kind_command kind_macro_line[MAX_KIND_MACRO_LENGTH];
	CLASS_DEFINITION
} kind_macro_definition;

kind_macro_definition *current_km = NULL; /* the one now being recorded */

kind_macro_definition *NeptuneMacros::new(text_stream *name) {
	kind_macro_definition *tmd = CREATE(kind_macro_definition);
	tmd->kind_macro_line_count = 0;
	tmd->kind_macro_name = Str::duplicate(name);
	return tmd;
}

kind_macro_definition *NeptuneMacros::parse_name(text_stream *name) {
	kind_macro_definition *tmd;
	LOOP_OVER(tmd, kind_macro_definition)
		if (Str::eq(name, tmd->kind_macro_name))
			return tmd;
	return NULL;
}

int NeptuneMacros::recording(void) {
	if (current_km) return TRUE;
	return FALSE;
}

void NeptuneMacros::begin(text_stream *name, text_file_position *tfp) {
	if (NeptuneMacros::parse_name(name))
		NeptuneFiles::error(name, I"duplicate definition of kind command macro", tfp);
	else
		current_km = NeptuneMacros::new(name);
}

void NeptuneMacros::record_into_macro(single_kind_command stc, text_file_position *tfp) {
	if (current_km == NULL)
		NeptuneFiles::error(NULL, I"kind macro not being recorded", tfp);
	else if (current_km->kind_macro_line_count >= MAX_KIND_MACRO_LENGTH)
		NeptuneFiles::error(current_km->kind_macro_name,
			I"kind macro contains too many lines", tfp);
	else current_km->kind_macro_line[current_km->kind_macro_line_count++] = stc;
}

void NeptuneMacros::end(text_file_position *tfp) {
	if (current_km == NULL) NeptuneFiles::error(NULL,
		I"ended kind macro outside one", tfp);
	current_km = NULL;
}

@ Playing back is easier, since it's just a matter of despatching the stored
commands in sequence to the relevant kind.

=
void NeptuneMacros::play_back(parse_node_tree *T, kind_macro_definition *macro,
	kind_constructor *con, text_file_position *tfp) {
	if (macro == NULL) NeptuneFiles::error(NULL, I"no such kind macro to play back", tfp);
	LOGIF(KIND_CREATIONS, "Macro %S on %S (%d lines)\n",
		macro->kind_macro_name, con->name_in_template_code, macro->kind_macro_line_count);
	LOG_INDENT;
	for (int i=0; i<macro->kind_macro_line_count; i++)
		KindCommands::apply(T, macro->kind_macro_line[i], con);
	LOG_OUTDENT;
	LOGIF(KIND_CREATIONS, "Macro %S ended\n", macro->kind_macro_name);
}
