[RTConditions::] Conditions.

Compiling conditions is mostly a matter of getting callings right.

@ We need to keep track of the callings made in any condition so that the
variables, which generally have a scope extending beyond that condition,
can't be left with kind-unsafe (or no) values. For example, if:

>> if a device (called the mechanism) is switched on: ...

turns out false, then "mechanism" has to be safely defused to some kind-safe
value.

@d MAX_CALLINGS_IN_MATCH 128

=
int current_session_number = -1;
int callings_in_condition_sp = 0;
int callings_session_number[MAX_CALLINGS_IN_MATCH];
local_variable *callings_in_condition[MAX_CALLINGS_IN_MATCH];

void RTConditions::add_calling_to_condition(local_variable *lvar) {
	if (current_session_number < 0) internal_error("no PM session");
	if (callings_in_condition_sp + 1 == MAX_CALLINGS_IN_MATCH)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
		"that makes too complicated a condition to test",
		"with all of those clauses involving 'called' values.");
	else {
		callings_session_number[callings_in_condition_sp] = current_session_number;
		callings_in_condition[callings_in_condition_sp++] = lvar;
	}
}

void RTConditions::begin_condition_emit(void) {
	current_session_number++;
	Produce::inv_primitive(Emit::tree(), OR_BIP);
	Produce::down(Emit::tree());
}

void RTConditions::end_condition_emit(void) {
	if (current_session_number < 0) internal_error("unstarted PM session");

	int NC = 0, x = callings_in_condition_sp, downs = 1;
	while ((x > 0) &&
		(callings_session_number[x-1] == current_session_number)) {
		NC++;
		x--;
	}

	if (NC == 0) {
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
	} else {
		Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
		Produce::down(Emit::tree()); downs++;
		int NM = 0, inner_downs = 0;;
		while ((callings_in_condition_sp > 0) &&
			(callings_session_number[callings_in_condition_sp-1] == current_session_number)) {
			NM++;
			local_variable *lvar = callings_in_condition[callings_in_condition_sp-1];
			if (NM < NC) { Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP); Produce::down(Emit::tree()); inner_downs++; }
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				inter_symbol *lvar_s = LocalVariables::declare(lvar);
				Produce::ref_symbol(Emit::tree(), K_value, lvar_s);
				kind *K = LocalVariables::kind(lvar);
				if ((K == NULL) ||
					(Kinds::Behaviour::is_object(K)) ||
					(Kinds::Behaviour::definite(K) == FALSE) ||
					(RTKinds::emit_default_value_as_val(K, EMPTY_WORDING, "'called' value") != TRUE))
					Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			callings_in_condition_sp--;
		}
		while (inner_downs > 0) { inner_downs--; Produce::up(Emit::tree()); }
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
	}
	current_session_number--;
	while (downs > 0) { downs--; Produce::up(Emit::tree()); }
}
