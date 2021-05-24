[RTActionTries::] Action Tries.

Compiling the try statement, which causes an action to be processed.

@

=
void RTActionTries::compile_try(explicit_action *ea, int store_instead) {
	parse_node *spec0 = ea->first_noun; /* the noun */
	parse_node *spec1 = ea->second_noun; /* the second noun */
	parse_node *spec2 = ea->actor; /* the actor */

	if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(spec0, K_understanding)) &&
		(<subject-pronoun>(Node::get_text(spec0)) == FALSE))
		spec0 = Rvalues::from_wording(Node::get_text(spec0));
	if ((K_understanding) && (Rvalues::is_CONSTANT_of_kind(spec1, K_understanding)) &&
		(<subject-pronoun>(Node::get_text(spec1)) == FALSE))
		spec1 = Rvalues::from_wording(Node::get_text(spec1));

	action_name *an = ea->action;

	int flag_bits = 0;
	if (Kinds::eq(Specifications::to_kind(spec0), K_text)) flag_bits += 16;
	if (Kinds::eq(Specifications::to_kind(spec1), K_text)) flag_bits += 32;
	if (flag_bits > 0) TheHeap::ensure_basic_heap_present();

	if (ea->request) flag_bits += 1;

	EmitCode::call(Hierarchy::find(TRYACTION_HL));
	EmitCode::down();
		EmitCode::val_number((inter_ti) flag_bits);
		if (spec2) RTActionTries::compile_parameter(spec2, K_object);
		else EmitCode::val_iname(K_object, Hierarchy::find(PLAYER_HL));
		EmitCode::val_iname(K_action_name, RTActions::double_sharp(an));
		if (spec0) RTActionTries::compile_parameter(spec0, ActionSemantics::kind_of_noun(an));
		else EmitCode::val_number(0);
		if (spec1) RTActionTries::compile_parameter(spec1, ActionSemantics::kind_of_second(an));
		else EmitCode::val_number(0);
		if (store_instead) {
			EmitCode::call(Hierarchy::find(STORED_ACTION_TY_CURRENT_HL));
			EmitCode::down();
				Frames::emit_new_local_value(K_stored_action);
			EmitCode::up();
		}
	EmitCode::up();
}

@ Which requires the following. Note that if the action expects to see a
|K_understanding|, then we typecheck in a way which will not cause an unwanted
silent cast to |K_text|; but type-safety is not violated.

=
void RTActionTries::compile_parameter(parse_node *term, kind *required_kind) {
	if ((K_understanding) && (Kinds::eq(required_kind, K_understanding))) {
		kind *K = Specifications::to_kind(term);
		if ((Kinds::compatible(K, K_understanding)) ||
			(Kinds::compatible(K, K_text)))
			required_kind = NULL;
	}
	if (Dash::check_value(term, required_kind))
		CompileValues::to_code_val_of_kind(term, K_object);
}
