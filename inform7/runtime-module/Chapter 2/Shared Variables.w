[RTSharedVariables::] Shared Variables.

Functions to create sets of shared variables.

@ Shared variables are fleeting things: they come and go at runtime, and
therefore they can't be set up statically by the compiler -- they must be
dynamically created by a function which is called at runtime each time they
need to come into being.

Each set therefore has its own "creator function", and the following compiles it:

=
void RTSharedVariables::compile_creator_fn(shared_variable_set *set, inter_name *iname) {
	if (set == NULL) internal_error("no shared variable set");

	packaging_state save = Functions::begin(iname);
	inter_symbol *pos_s = LocalVariables::new_other_as_symbol(I"pos");
	inter_symbol *state_s = LocalVariables::new_other_as_symbol(I"state");

	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, state_s);
			EmitCode::val_number(1);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Compile frame creator if state is set@>;
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Compile frame creator if state is clear@>;
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_number((inter_ti) LinkedLists::len(set->variables));
	EmitCode::up();

	Functions::end(save);
}

@<Compile frame creator if state is set@> =
	shared_variable *shv;
	LOOP_OVER_LINKED_LIST(shv, shared_variable, set->variables) {
		nonlocal_variable *q = SharedVariables::get_variable(shv);
		kind *K = NonlocalVariables::kind(q);
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::reference();
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(MSTACK_HL));
					EmitCode::val_symbol(K_value, pos_s);
				EmitCode::up();
			EmitCode::up();
			if (Kinds::Behaviour::uses_block_values(K))
				TheHeap::emit_allocation(TheHeap::make_allocation(K, 1, -1));
			else
				RTVariables::initial_value_as_val(q);
		EmitCode::up();

		EmitCode::inv(POSTINCREMENT_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, pos_s);
		EmitCode::up();
	}

@<Compile frame creator if state is clear@> =
	shared_variable *shv;
	LOOP_OVER_LINKED_LIST(shv, shared_variable, set->variables) {
		nonlocal_variable *q = SharedVariables::get_variable(shv);
		kind *K = NonlocalVariables::kind(q);
		if (Kinds::Behaviour::uses_block_values(K)) {
			EmitCode::call(Hierarchy::find(DESTROYPV_HL));
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(MSTACK_HL));
					EmitCode::val_symbol(K_value, pos_s);
				EmitCode::up();
			EmitCode::up();
		}
		EmitCode::inv(POSTINCREMENT_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, pos_s);
		EmitCode::up();
	}
