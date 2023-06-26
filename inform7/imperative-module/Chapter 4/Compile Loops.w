[CompileLoops::] Compile Loops.

To compile loop headers from a range of values expressed by a proposition.

@h Domains of loops.
This function ccmpiles the header (and in effect therefore the structure)
of a loop through all values $x$ such that $\phi(x)$ is true, where $\phi$
is the proposition inside the description |desc|. The loop variable will
be |v1|.

=
void CompileLoops::through_matches(parse_node *spec, local_variable *v1) {
	kind *DK = Specifications::to_kind(spec);
	if (Kinds::get_construct(DK) != CON_description)
		internal_error("repeat through non-description");
	kind *K = Kinds::unary_construction_material(DK);
	CodeBlocks::set_scope_to_block_about_to_open(v1);
	local_variable *v2 = LocalVariables::new_let_value(EMPTY_WORDING, K);
	CodeBlocks::set_scope_to_block_about_to_open(v2);

	if (Kinds::Behaviour::is_object(K)) {
		@<Exploit the runtime representation of objects@>
	} else {
		i6_schema loop_schema;
		if (CompileLoops::schema(&loop_schema, K)) @<Compile from the kind's loop schema@>
		else @<Issue bad repeat domain problem@>;
	}
}

@ In the case where we are looping through objects, we can exploit a runtime
ability to move quickly to the next object in a given kind. This requires a
loop construction a little too complex for a schema, so we generate the code
by hand.

In fact we secretly make a second loop variable |v2| as well, though it is
invisible from source text, and construct a loop analogous to:
= (text)
	for (v1=D(0), v2=D(v1); v1; v1=v2, v2=D(v1))
=
where |D| is a function deferred from the proposition which is such that:
(*) |D(0)| produces the first $x$ such that $\phi(x)$, and otherwise
(*) |D(x)| produces either the next match after $x$, or 0 to indicate that
there are no further matches.

This arrangement is possible because object values, and enumerated values, are
never equal to 0 at runtime.

The reason we do not simply compile
= (text)
	for (v1=D(0); v1; v1=D(v1))
=
is to protects us in case the body of the loop takes action which moves |v1| out
of the domain -- e.g., in the case of:
= (text as Inform 7)
	repeat with T running through items on the table:
		now T is in the box.
=
This is the famous "broken |objectloop|" hazard of Inform 6. Experience shows
that authors value safety over the slight speed overhead incurred.

@<Exploit the runtime representation of objects@> =
	inter_symbol *val_var_s = LocalVariables::declare(v1);
	inter_symbol *aux_var_s = LocalVariables::declare(v2);

	if (Deferrals::spec_is_variable_of_kind_description(spec) == FALSE) {
		pcalc_prop *domain_prop = SentencePropositions::from_spec(spec);
		if (CreationPredicates::contains_callings(domain_prop))
			@<Issue called in repeat problem@>;
	}

	EmitCode::inv(FOR_BIP);
	EmitCode::down();
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, val_var_s);
				CompileLoops::iterate(spec, NULL);
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, aux_var_s);
				CompileLoops::iterate(spec, v1);
			EmitCode::up();
		EmitCode::up();

		EmitCode::val_symbol(K_value, val_var_s);

		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, val_var_s);
				EmitCode::val_symbol(K_value, aux_var_s);
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, aux_var_s);
				CompileLoops::iterate(spec, v2);
			EmitCode::up();
		EmitCode::up();

		EmitCode::code();
		EmitCode::down();

@ It would be nice to generate the whole loop from the schema for the kind,
but of course our description is unlikely to be just ${\it kind}_K(x)$. So
the idea is roughly:
= (text)
	loop over each v1 in K
	    if phi(v1)
	        ...
=
We can optimise out the "if" part in the case when $\phi(x) = {\it kind}_K(x)$.

@<Compile from the kind's loop schema@> =
	CompileSchemas::from_local_variables_in_void_context(&loop_schema, v1, v2);
	if (Lvalues::is_lvalue(spec) == FALSE) {
		if (Specifications::is_kind_like(spec) == FALSE) {
			pcalc_prop *prop = Specifications::to_proposition(spec);
			if (prop) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					CompilePropositions::to_test_as_condition(
						Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1), prop);
					EmitCode::code();
					EmitCode::down();
			}
		}
	} else {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(INDIRECT2_BIP);
			EmitCode::down();
				CompileValues::to_code_val(spec);
				EmitCode::val_number((inter_ti) CONDITION_DUSAGE);
				CompileValues::to_code_val(
					Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, v1));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
	}

@<Issue called in repeat problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CalledInRepeat),
		"this tries to use '(called ...)' to give names to values "
		"arising in the course of working out what to repeat through",
		"but this is not allowed. (Sorry: it's too hard to get right.)");

@<Issue bad repeat domain problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BadRepeatDomain));
	Problems::issue_problem_segment(
		"In %1, you seem to want to repeat through all possible values which have "
		"the kind '%2', and there are just too many of those. "
		"For instance, you can 'repeat with D running through doors' because "
		"there are only a small number of doors, but you can't 'repeat with N "
		"running through numbers' because numbers are without end.");
	Problems::issue_problem_end();

@ Here we compile code to call |D(v)|, on the variable |fromv|, or |D(0)| if
|fromv| is |NULL|. As in //Deciding to Defer//, we are forced to call |D| as
a multipurpose description function if it is not known at compile time; but
we can more efficiently defer for this single purpose if it is.

=
void CompileLoops::iterate(parse_node *spec, local_variable *fromv) {
	if (Deferrals::spec_is_variable_of_kind_description(spec)) {
		EmitCode::inv(INDIRECT2_BIP);
		EmitCode::down();
			CompileValues::to_code_val(spec);
			EmitCode::val_number((inter_ti) LOOP_DOMAIN_DUSAGE);
			if (fromv) {
				inter_symbol *fromv_s = LocalVariables::declare(fromv);
				EmitCode::val_symbol(K_value, fromv_s);
			} else {
				EmitCode::val_number(0);
			}
		EmitCode::up();
	} else {
		pcalc_prop *prop = SentencePropositions::from_spec(spec);
		pcalc_prop_deferral *pdef = Deferrals::defer_loop_domain(prop);
		int arity = Cinders::count(prop, pdef) + 1;
		switch (arity) {
			case 0: EmitCode::inv(INDIRECT0_BIP); break;
			case 1: EmitCode::inv(INDIRECT1_BIP); break;
			case 2: EmitCode::inv(INDIRECT2_BIP); break;
			case 3: EmitCode::inv(INDIRECT3_BIP); break;
			case 4: EmitCode::inv(INDIRECT4_BIP); break;
			default: internal_error("indirect function call with too many arguments");
		}
		EmitCode::down();
			EmitCode::val_iname(K_value, pdef->ppd_iname);
			Cinders::compile_cindered_values(prop, pdef);
			if (fromv) {
				inter_symbol *fromv_s = LocalVariables::declare(fromv);
				EmitCode::val_symbol(K_value, fromv_s);
			} else {
				EmitCode::val_number(0);
			}
		EmitCode::up();
	}
}

@h Loop schemas over a whole kind.
If |K| is a kind, this function generates a schema for a loop over all instances
of the kind, or returns |FALSE| if that is impossible or unreasonable.

In the situation above, this function was needed only for non-object kinds; but
other parts of Inform also use it, so it needs to work for object kinds too.

Choosing an efficient schema here makes a big difference to Inform's runtime
performance.

@d MAX_LOOP_DOMAIN_SCHEMA_LENGTH 1000

=
int CompileLoops::schema(i6_schema *sch, kind *K) {
	if (K == NULL) return FALSE;
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		if (InstanceCounting::optimise_loop(sch, K) == FALSE)
			Calculus::Schemas::modify(sch, "objectloop (*1 ofclass %n)",
				RTKindDeclarations::iname(K));
		return TRUE;
	}
	if (Kinds::eq(K, K_object)) {
		Calculus::Schemas::modify(sch, "objectloop (*1 ofclass Object)");
		return TRUE;
	}
	if (Kinds::Behaviour::is_an_enumeration(K)) {
		if (RTKindConstructors::is_nonstandard_enumeration(K)) {
			inter_name *lname = RTKindConstructors::instances_array_iname(K);
			Calculus::Schemas::modify(sch,
				"for (*2=1, *1=%n-->*2: *2<=%d: *2++, *1=%n-->*2)",
					lname, RTKindConstructors::enumeration_size(K), lname);
		} else {
			Calculus::Schemas::modify(sch,
				"for (*1=1: *1<=%d: *1++)",
					RTKindConstructors::enumeration_size(K));
		}
		return TRUE;
	}
	text_stream *p = K->construct->loop_domain_schema;
	if (p == NULL) return FALSE;
	Calculus::Schemas::modify(sch, "%S", p);
	return TRUE;
}

@h Loops through list values.
This is a quite different kind of loop: for iterating through the members of
a list (whose contents are not known at compile time).

We need three variables, of which only |val_var| is visible in source text:
(*) |index_var_s| is the position in the list -- 0, 1, 2, ...;
(*) |val_var_s| is the entry at that position;
(*) |copy_var_s| is the list itself -- which we stash into this temporary
variable to avoid having to evaluate it more than once.

=
void CompileLoops::through_list(parse_node *spec, local_variable *val_var) {
	local_variable *index_var = LocalVariables::new_let_value(EMPTY_WORDING, K_number);
	local_variable *copy_var = LocalVariables::new_let_value(EMPTY_WORDING, K_number);
	kind *K = Specifications::to_kind(spec);
	kind *CK = Kinds::unary_construction_material(K);

	int pointery = FALSE;
	if (Kinds::Behaviour::uses_block_values(CK)) {
		pointery = TRUE;
		LocalVariableSlates::free_at_end_of_scope(val_var);
	}

	CodeBlocks::set_scope_to_block_about_to_open(val_var);
	LocalVariables::set_kind(val_var, CK);
	CodeBlocks::set_scope_to_block_about_to_open(index_var);

	inter_symbol *val_var_s = LocalVariables::declare(val_var);
	inter_symbol *index_var_s = LocalVariables::declare(index_var);
	inter_symbol *copy_var_s = LocalVariables::declare(copy_var);

	EmitCode::inv(FOR_BIP);
	EmitCode::down();
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, copy_var_s);
				CompileValues::to_code_val(spec);
			EmitCode::up();
			EmitCode::inv(SEQUENTIAL_BIP);
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, index_var_s);
					EmitCode::val_number(1);
				EmitCode::up();
				if (pointery) {
					EmitCode::inv(SEQUENTIAL_BIP);
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, val_var_s);
							EmitCode::call(Hierarchy::find(BLKVALUECREATE_HL));
							EmitCode::down();
								RTKindIDs::emit_strong_ID_as_val(CK);
							EmitCode::up();
						EmitCode::up();
						EmitCode::call(Hierarchy::find(BLKVALUECOPYAZ_HL));
						EmitCode::down();
							EmitCode::val_symbol(K_value, val_var_s);
							EmitCode::call(Hierarchy::find(LIST_OF_TY_GETITEM_HL));
							EmitCode::down();
								EmitCode::val_symbol(K_value, copy_var_s);
								EmitCode::val_symbol(K_value, index_var_s);
								EmitCode::val_true();
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				} else {
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, val_var_s);
						EmitCode::call(Hierarchy::find(LIST_OF_TY_GETITEM_HL));
						EmitCode::down();
							EmitCode::val_symbol(K_value, copy_var_s);
							EmitCode::val_symbol(K_value, index_var_s);
							EmitCode::val_true();
						EmitCode::up();
					EmitCode::up();
				}
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(LE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, index_var_s);
			EmitCode::call(Hierarchy::find(LIST_OF_TY_GETLENGTH_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, copy_var_s);
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(POSTINCREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, index_var_s);
			EmitCode::up();
			if (pointery) {
				EmitCode::call(Hierarchy::find(BLKVALUECOPYAZ_HL));
				EmitCode::down();
					EmitCode::val_symbol(K_value, val_var_s);
					EmitCode::call(Hierarchy::find(LIST_OF_TY_GETITEM_HL));
					EmitCode::down();
						EmitCode::val_symbol(K_value, copy_var_s);
						EmitCode::val_symbol(K_value, index_var_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			} else {
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, val_var_s);
					EmitCode::call(Hierarchy::find(LIST_OF_TY_GETITEM_HL));
					EmitCode::down();
						EmitCode::val_symbol(K_value, copy_var_s);
						EmitCode::val_symbol(K_value, index_var_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			}
		EmitCode::up();

		EmitCode::code();
			EmitCode::down();
}
