[DefaultValues::] Default Values.

To compile I6 material needed at runtime to enable kinds
to function as they should.

@h Default values.
When we create a new variable (or other storage object) of a given kind, but
never say what its value is to be, Inform tries to initialise it to the
"default value" for that kind.

The following should compile a default value for $K$, and return
(a) |TRUE| if it succeeded,
(b) |FALSE| if it failed (because $K$ had no values or no default could be
chosen), but no problem message has been issued about this, or
(c) |NOT_APPLICABLE| if it failed and issued a specific problem message.

=
int DefaultValues::array_entry(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = DefaultValues::to_holster(&VH, K, W, storage_name);
	inter_ti v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	EmitArrays::generic_entry(v1, v2);
	return rv;
}
int DefaultValues::val(kind *K, wording W, char *storage_name) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	int rv = DefaultValues::to_holster(&VH, K, W, storage_name);
	Holsters::unholster_to_code_val(Emit::tree(), &VH);
	return rv;
}
int DefaultValues::to_holster(value_holster *VH, kind *K,
	wording W, char *storage_name) {
	if (Kinds::eq(K, K_value))
		@<"Value" is too vague to be the kind of a variable@>;
	if (Kinds::Behaviour::definite(K) == FALSE)
		@<This is a kind not intended for end users at all@>;
	inter_ti v1 = 0, v2 = 0;
	DefaultValues::to_value_pair(&v1, &v2, K);
	if (v1 != 0) {
		if (Holsters::non_void_context(VH)) {
			Holsters::holster_pair(VH, v1, v2);
			return TRUE;
		}
		internal_error("thwarted on gdv inter");
	}
	if (Kinds::Behaviour::is_subkind_of_object(K))
		@<The kind must have no instances, or it would have worked@>;
	return FALSE;
}

@<The kind must have no instances, or it would have worked@> =
	if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		Problems::quote_text(3, storage_name);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyKind2));
		Problems::issue_problem_segment(
			"I am unable to put any value into the %3 %1, which needs to be %2, "
			"because the world does not contain %2.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyKind));
		Problems::issue_problem_segment(
			"I am unable to find %2 to use here, because the world does not "
			"contain %2.");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@<This is a kind not intended for end users at all@> =
	if (Wordings::nonempty(W)) {
		Problems::quote_wording_as_source(1, W);
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create %1 with the kind of value '%2', "
			"because this is a kind of value which is not allowed as "
			"something to be stored in properties, variables and the "
			"like. (See the Kinds index for which kinds of value "
			"are available. The ones which aren't available are really "
			"for internal use by Inform.)");
		Problems::issue_problem_end();
	} else {
		Problems::quote_kind(1, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"I am unable to create a value of the kind '%1' "
			"because this is a kind of value which is not allowed as "
			"something to be stored in properties, variables and the "
			"like. (See the Kinds index for which kinds of value "
			"are available. The ones which aren't available are really "
			"for internal use by Inform.)");
		Problems::issue_problem_end();
	}
	return NOT_APPLICABLE;

@<"Value" is too vague to be the kind of a variable@> =
	Problems::quote_wording_as_source(1, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"I am unable to start %1 off with any value, because the "
		"instructions do not tell me what kind of value it should be "
		"(a number, a time, some text perhaps?).");
	Problems::issue_problem_end();
	return NOT_APPLICABLE;

@ This returns either valid I6 code for the value which is the default for
$K$, or else |NULL| if $K$ has no values, or no default can be chosen.

We bend the rules and allow |nothing| as the default value of all kinds of
objects when the source text is a roomless one used only to rerelease an old
I6 story file; this effectively suppresses problem messages which the
absence of rooms would otherwise result in.

=
void DefaultValues::to_value_pair(inter_ti *v1, inter_ti *v2, kind *K) {
	if (K == NULL) return;

	if ((Kinds::get_construct(K) == CON_list_of) ||
		(Kinds::get_construct(K) == CON_phrase) ||
		(Kinds::get_construct(K) == CON_relation)) {
		inter_name *DV = NULL;
		runtime_kind_structure *rks = RTKindIDs::get_rks(K);
		if (rks) DV = RTKindIDs::default_value_from_rks(rks);
		if (Kinds::get_construct(K) == CON_list_of) {
			Emit::to_value_pair(v1, v2, ListLiterals::small_block(DV));
		} else if (Kinds::get_construct(K) == CON_relation) {
			inter_name *N = RelationLiterals::default(K);
			Emit::to_value_pair(v1, v2, N);
		} else if (DV) {
			Emit::to_value_pair(v1, v2, DV);
		}
		return;
	}

	if (Kinds::eq(K, K_stored_action)) {
		inter_name *N = StoredActionLiterals::default();
		Emit::to_value_pair(v1, v2, N);
		return;
	}
	if (Kinds::eq(K, K_text)) {
		inter_name *N = TextLiterals::default_text();
		Emit::to_value_pair(v1, v2, N);
		return;
	}

	if (Kinds::eq(K, K_object)) {
		*v1 = LITERAL_IVAL; *v2 = 0;
		return;
	}

	instance *I;
	LOOP_OVER_INSTANCES(I, K) {
		inter_name *N = RTInstances::value_iname(I);
		Emit::to_value_pair(v1, v2, N);
		return;
	}

	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		#ifdef IF_MODULE
		if (Task::wraps_existing_storyfile()) {
			*v1 = LITERAL_IVAL; *v2 = 0;
			return;
		} /* see above */
		#endif
		return;
	}

	if (Kinds::Behaviour::is_an_enumeration(K)) return;

	if (Kinds::eq(K, K_rulebook_outcome)) {
		Emit::to_value_pair(v1, v2, RTRulebooks::default_outcome_iname());
		return;
	}

	if (Kinds::eq(K, K_action_name)) {
		inter_name *wait = RTActions::double_sharp(ActionsPlugin::default_action_name());
		Emit::to_value_pair(v1, v2, wait);
		return;
	}

	text_stream *name = K->construct->default_value;

	if (Str::len(name) == 0) return;

	inter_ti val1 = 0, val2 = 0;
	if (Inter::Types::read_I6_decimal(name, &val1, &val2) == TRUE) {
		*v1 = val1; *v2 = val2; return;
	}

	inter_symbol *S = Produce::seek_symbol(Produce::main_scope(Emit::tree()), name);
	if (S) {
		Emit::symbol_to_value_pair(v1, v2, S);
		return;
	}

	if (Str::eq(name, I"true")) { *v1 = LITERAL_IVAL; *v2 = 1; return; }
	if (Str::eq(name, I"false")) { *v1 = LITERAL_IVAL; *v2 = 0; return; }

	int hl = Hierarchy::kind_default(Kinds::get_construct(K), name);
	inter_name *default_iname = Hierarchy::find(hl);
	Emit::to_value_pair(v1, v2, default_iname);
}
