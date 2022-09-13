[Dialogue::] Dialogue.

A nascent system for managing conversation.

@ This feature, |dialogue|, is technically not part of |if|, but it clearly
belongs in this module.

Note that a child feature called |performance styles| -- see //Performance Styles// --
handles that kind, so it won't be dealt with in the code for this feature.

=
void Dialogue::start(void) {
	Dialogue::declare_annotations();
	PluginCalls::plug(NEW_BASE_KIND_NOTIFY_PLUG, Dialogue::new_base_kind_notify);
	PluginCalls::plug(COMPARE_CONSTANT_PLUG, Dialogue::compare_CONSTANT);
}

@ These two kinds are both created by a Neptune file belonging to //DialogueKit//,
and are recognised by their Inter identifiers:

= (early code)
kind *K_dialogue_beat = NULL;
kind *K_dialogue_line = NULL;

@ =
int Dialogue::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"DIALOGUE_BEAT_TY")) {
		K_dialogue_beat = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, L"DIALOGUE_LINE_TY")) {
		K_dialogue_line = new_base; return TRUE;
	}
	return FALSE;
}

@ The rest of this section is to some extent boiler-plate code: it provides for
specific beats and lines to be represented as rvalues, both inside the compiler
(and when typechecking) and at runtime.

=
parse_node *Dialogue::rvalue_from_dialogue_beat(dialogue_beat *val) {
	CONV_FROM(dialogue_beat, K_dialogue_beat) }
dialogue_beat *Dialogue::rvalue_to_dialogue_beat(parse_node *spec) { CONV_TO(dialogue_beat) }
parse_node *Dialogue::rvalue_from_dialogue_line(dialogue_line *val) {
	CONV_FROM(dialogue_line, K_dialogue_line) }
dialogue_line *Dialogue::rvalue_to_dialogue_line(parse_node *spec) { CONV_TO(dialogue_line) }

@ These can be compared at compile time, which means that type-checking can be
used to select phrases or rules depending on specific beats or lines.

=
int Dialogue::compare_CONSTANT(parse_node *spec1, parse_node *spec2, int *rv) {
	kind *K = Node::get_kind_of_value(spec1);
	if (Kinds::eq(K, K_dialogue_beat)) {
		if (Dialogue::rvalue_to_dialogue_beat(spec1) ==
			Dialogue::rvalue_to_dialogue_beat(spec2)) {
			*rv = TRUE;
		}
		*rv = FALSE;
		return TRUE;
	}
	if (Kinds::eq(K, K_dialogue_line)) {
		if (Dialogue::rvalue_to_dialogue_line(spec1) ==
			Dialogue::rvalue_to_dialogue_line(spec2)) {
			*rv = TRUE;
		}
		*rv = FALSE;
		return TRUE;
	}
	return FALSE;
}

@ The following syntax tree annotations are used for the constant rvalues:

@e constant_dialogue_beat_ANNOT /* |dialogue_beat|: for constant values */
@e constant_dialogue_line_ANNOT /* |dialogue_line|: for constant values */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(constant_dialogue_beat, dialogue_beat)
DECLARE_ANNOTATION_FUNCTIONS(constant_dialogue_line, dialogue_line)

@ =
MAKE_ANNOTATION_FUNCTIONS(constant_dialogue_beat, dialogue_beat)
MAKE_ANNOTATION_FUNCTIONS(constant_dialogue_line, dialogue_line)

void Dialogue::declare_annotations(void) {
	Annotations::declare_type(constant_dialogue_beat_ANNOT,
		Dialogue::write_constant_dialogue_beat_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_dialogue_beat_ANNOT);
	Annotations::declare_type(constant_dialogue_line_ANNOT,
		Dialogue::write_constant_dialogue_line_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_dialogue_line_ANNOT);
}
void Dialogue::write_constant_dialogue_beat_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_dialogue_beat(p))
		WRITE(" {dialogue beat: %I}", Node::get_constant_dialogue_beat(p)->as_instance);
}
void Dialogue::write_constant_dialogue_line_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_dialogue_line(p))
		WRITE(" {dialogue line: %I}", Node::get_constant_dialogue_line(p)->as_instance);
}
