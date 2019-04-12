[PL::Actions::ScopeLoops::] Looping Over Scope.

To compile routines capable of being passed as arguments to the
I6 library routine for looping over parser scope at run-time, and so to provide
an implementation for conditions such as "in the presence of Mrs Dalloway".

@h Definitions.

=
typedef struct loop_over_scope {
	struct parse_node *what_to_find;
	struct inter_name *los_iname;
	MEMORY_MANAGEMENT
} loop_over_scope;

@ =
loop_over_scope *PL::Actions::ScopeLoops::new(parse_node *what) {
	loop_over_scope *los = CREATE(loop_over_scope);
	los->what_to_find = ParseTree::duplicate(what);
	if (Specifications::is_description(what)) {
		los->what_to_find->down = ParseTree::duplicate(los->what_to_find->down);
		Descriptions::clear_calling(los->what_to_find);
	}
	inter_name *m_iname = InterNames::new(LOOP_OVER_SCOPE_ROUTINE_INAMEF);
	package_request *PR = Packaging::local_resource(GRAMMAR_SUBMODULE);
	los->los_iname = Packaging::function(
		InterNames::one_off(I"loop_over_scope_fn", PR),
		PR,
		m_iname);
	return los;
}

loop_over_scope *latest_los = NULL;
int PL::Actions::ScopeLoops::compilation_coroutine(void) {
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

	ph_stack_frame *phsf = Frames::current_stack_frame();
	local_variable *it_lv = LocalVariables::add_pronoun(phsf, EMPTY_WORDING, K_object);
	inter_symbol *it_s = LocalVariables::declare_this(it_lv, FALSE, 8);

	Emit::inv_primitive(if_interp);
	Emit::down();
		LocalVariables::begin_condition_emit();
		value_holster VH = Holsters::new(INTER_VAL_VHMODE);
		if (los->what_to_find) {
			parse_node *lv_sp = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, it_lv);
			PL::Actions::Patterns::compile_pattern_match_clause_inner(FALSE, &VH,
				lv_sp, FALSE, los->what_to_find, K_object, FALSE);
		} else
			Emit::val(K_truth_state, LITERAL_IVAL, 0);
		LocalVariables::end_condition_emit();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(LOS_RV_HL));
				Emit::val_symbol(K_value, it_s);
			Emit::up();
		Emit::up();
	Emit::up();
	Routines::end(save);
