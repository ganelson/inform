[LoopingOverScope::] Looping Over Scope.

To compile routines capable of being passed as arguments to the
I6 library routine for looping over parser scope at run-time, and so to provide
an implementation for conditions such as "in the presence of Mrs Dalloway".

@h Definitions.

=
typedef struct loop_over_scope {
	struct parse_node *what_to_find;
	struct inter_name *los_iname;
	CLASS_DEFINITION
} loop_over_scope;

@ =
loop_over_scope *LoopingOverScope::new(parse_node *what) {
	loop_over_scope *los = CREATE(loop_over_scope);
	los->what_to_find = Node::duplicate(what);
	if (Specifications::is_description(what)) {
		los->what_to_find->down = Node::duplicate(los->what_to_find->down);
		Descriptions::clear_calling(los->what_to_find);
	}
	package_request *PR = Hierarchy::local_package(LOOP_OVER_SCOPES_HAP);
	los->los_iname = Hierarchy::make_iname_in(LOOP_OVER_SCOPE_FN_HL, PR);
	text_stream *desc = Str::new();
	WRITE_TO(desc, "loop over scope '%W'", Node::get_text(los->what_to_find));
	Sequence::queue(&LoopingOverScope::compilation_agent,
		STORE_POINTER_loop_over_scope(los), desc);
	return los;
}

void LoopingOverScope::compilation_agent(compilation_subtask *t) {
	loop_over_scope *los = RETRIEVE_POINTER_loop_over_scope(t->data);
	packaging_state save = Functions::begin(los->los_iname);

	stack_frame *phsf = Frames::current_stack_frame();
	local_variable *it_lv = Frames::enable_it(phsf, EMPTY_WORDING, K_object);
	inter_symbol *it_s = LocalVariables::declare(it_lv);

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		CompileConditions::begin();
		value_holster VH = Holsters::new(INTER_VAL_VHMODE);
		if (los->what_to_find) {
			parse_node *lv_sp = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, it_lv);
			RTActionPatterns::compile_pattern_match_clause_inner(&VH,
				lv_sp, FALSE, los->what_to_find, K_object, FALSE);
		} else
			EmitCode::val_false();
		CompileConditions::end();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(LOS_RV_HL));
				EmitCode::val_symbol(K_value, it_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	Functions::end(save);
}
