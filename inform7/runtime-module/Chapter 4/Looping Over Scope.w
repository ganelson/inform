[LoopingOverScope::] Looping Over Scope.

To compile functions which implement conditions such as "in the presence of
Mrs Dalloway".

@ Each time we need to parse an action pattern with the provison "in the
presence of X", one of the following objects is created, as an instruction
to pass to the agent below. These tests are local resources, included in
the same enclosure as the function they are called from. Each test is used
in just one place in the program.

The term "loop over scope" is traditional and goes back to the Inform 6
world model, where the "scope" was the set of things which the player could
interact with at any given point.

=
typedef struct loop_over_scope {
	struct parse_node *what_to_find;
	struct inter_name *los_iname;
	CLASS_DEFINITION
} loop_over_scope;

@ Because the test is performed by a separate function, we need to make sure
that any called variables are created in the calling function, and not in
that external one: so we remove calling details from |what_to_find|.

=
loop_over_scope *LoopingOverScope::new(parse_node *what) {
	loop_over_scope *los = CREATE(loop_over_scope);
	los->what_to_find = Node::duplicate(what);
	if (Specifications::is_description(what)) {
		los->what_to_find->down = Node::duplicate(los->what_to_find->down);
		Descriptions::clear_calling(los->what_to_find);
	}
	los->los_iname = Enclosures::new_iname(LOOPS_OVER_SCOPE_HAP, LOOP_OVER_SCOPE_FN_HL);
	text_stream *desc = Str::new();
	WRITE_TO(desc, "loop over scope '%W'", Node::get_text(los->what_to_find));
	Sequence::queue(&LoopingOverScope::compilation_agent,
		STORE_POINTER_loop_over_scope(los), desc);
	return los;
}

@ And here we compile a single test.

=
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
