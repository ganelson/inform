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
	return los;
}

loop_over_scope *latest_los = NULL;
int LoopingOverScope::compilation_coroutine(void) {
	int N = 0;
	while (TRUE) {
		loop_over_scope *los;
		if (latest_los == NULL)
			los = FIRST_OBJECT(loop_over_scope);
		else los = NEXT_OBJECT(latest_los, loop_over_scope);
		if (los == NULL) break;
		latest_los = los;
		@<Compile an individual loop-over-scope@>;
		N++;
	}
	return N;
}

@<Compile an individual loop-over-scope@> =
	packaging_state save = Routines::begin(los->los_iname);

	stack_frame *phsf = Frames::current_stack_frame();
	local_variable *it_lv = Frames::enable_it(phsf, EMPTY_WORDING, K_object);
	inter_symbol *it_s = LocalVariables::declare(it_lv);

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		RTConditions::begin_condition_emit();
		value_holster VH = Holsters::new(INTER_VAL_VHMODE);
		if (los->what_to_find) {
			parse_node *lv_sp = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, it_lv);
			RTActionPatterns::compile_pattern_match_clause_inner(&VH,
				lv_sp, FALSE, los->what_to_find, K_object, FALSE);
		} else
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
		RTConditions::end_condition_emit();
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(LOS_RV_HL));
				Produce::val_symbol(Emit::tree(), K_value, it_s);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Routines::end(save);
