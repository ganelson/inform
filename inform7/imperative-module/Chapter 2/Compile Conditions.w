[CompileConditions::] Compile Conditions.

To compile Inter code to test a condition.

@ In fact almost all of the work is delegated to more potent routines elsewhere.
Much of //Chapter 4: Propositions// is really dedicated to this.

=
void CompileConditions::compile(value_holster *VH, parse_node *cond) {
	if (PluginCalls::compile_condition(VH, cond)) return;
	switch (Node::get_type(cond)) {
		case TEST_PROPOSITION_NT:
			CompilePropositions::to_test_as_condition(NULL,
				Specifications::to_proposition(cond));
			break;
		case LOGICAL_TENSE_NT:
			Chronology::compile_past_tense_condition(cond);
			break;
		case LOGICAL_NOT_NT: @<Compile a logical negation@>; break;
		case LOGICAL_AND_NT: case LOGICAL_OR_NT: @<Compile a logical operator@>; break;
		case TEST_VALUE_NT:
			if (Specifications::is_description(cond)) {
				/* purely for problem recovery: */
				EmitCode::val_number(1); 
			} else {
				CompileValues::to_code_val(cond->down);
			}
			break;
		case TEST_PHRASE_OPTION_NT: @<Compile a phrase option test@>; break;
	}
}

@ An easy case, running straight out to Inter operators:

@<Compile a logical negation@> =
	if (Node::no_children(cond) != 1)
		internal_error("Compiled malformed LOGICAL_NOT_NT");
	EmitCode::inv(NOT_BIP);
	EmitCode::down();
		CompileValues::to_code_val(cond->down);
	EmitCode::up();

@ An easy case, running straight out to Inter operators:

@<Compile a logical operator@> =
	if (Node::no_children(cond) != 2)
		internal_error("Compiled malformed logical operator");
	parse_node *left_operand = cond->down;
	parse_node *right_operand = cond->down->next;
	if ((left_operand == NULL) || (right_operand == NULL))
		internal_error("Compiled CONDITION/AND with LHS operands");

	if (Node::is(cond, LOGICAL_AND_NT)) EmitCode::inv(AND_BIP);
	if (Node::is(cond, LOGICAL_OR_NT)) EmitCode::inv(OR_BIP);
	EmitCode::down();
		CompileValues::to_code_val(left_operand);
		CompileValues::to_code_val(right_operand);
	EmitCode::up();

@ Phrase options are stored as bits in a 16-bit map, so that each individual
option is a power of two from $2^0$ to $2^15$. We test if this is valid by
performing logical-and against the Inter local variable |phrase_options|, which
exists if and only if the enclosing Inter routine takes phrase options. The
type-checker won't allow these specifications to be compiled anywhere else.

@<Compile a phrase option test@> =
	EmitCode::inv(BITWISEAND_BIP);
	EmitCode::down();
		local_variable *po = LocalVariables::options_parameter();
		if (po == NULL) internal_error("no phrase options exist in this frame");
		inter_symbol *po_s = LocalVariables::declare(po);
		EmitCode::val_symbol(K_value, po_s);
		EmitCode::val_number((inter_ti) Annotations::read_int(cond, phrase_option_ANNOT));
	EmitCode::up();

@ We need a mechanism for keeping track of the callings made in a condition,
and here it is. An issue here is that they generally have a scope extending
beyond that condition, and can't be left with kind-unsafe (or no) values. For
example, if:

>> if a device (called the mechanism) is switched on: ...

turns out false, then "mechanism" has to be safely defused to some typesafe value.
So, then, the model is that if some part of Inform wants to compile a condition
which may involve callings, it should call //CompileConditions::begin// first,
then notify us with //CompileConditions::add_calling// of any local being used
as a calling, and then //CompileConditions::end// when the code is done.

Callings arise from variables in predicate calculus, and there can only be 26
of those, so the following looks excessive. Well, so it is, of course: Inform
code in the wild never makes more than about three callings in any one condition.
But note that these condition sessions can be nested: you can begin a second
one inside the first, provided that you end it before you end the first one.

@d MAX_CALLINGS_IN_MATCH 128

=
int current_session_number = -1;
int callings_in_condition_sp = 0;
int callings_session_number[MAX_CALLINGS_IN_MATCH];
local_variable *callings_in_condition[MAX_CALLINGS_IN_MATCH];

@ The basic strategy here is to compile this:
= (text)
	((condition setting C1, ..., Ci) || (C1 = default, C2 = default, ..., Ci = default))
=
using the short-circuit property of |OR_BIP|: if the condition evaluates to false,
and therefore there is no consistent set of values written into the calling
variables |C1| to |Ci|, then we evaluate the second clause, and set all of the
variables to default values for their kinds. In particular, if the condition
fails halfway, with some callings set and some not, they are all defaulted out,
so that you can never see partial results.

=
void CompileConditions::begin(void) {
	current_session_number++;
	EmitCode::inv(OR_BIP);
	EmitCode::down();
}

@ Each variable records which "session" it belongs to, since there can be
multiple sessions happening at once:

=
void CompileConditions::add_calling(local_variable *lvar) {
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

@ Now for the second operand of the |OR_BIP|. If there weren't any callings,
we just compile |false|. (It looks wasteful to have compiled "if (... or false)",
but in that event the use of |OP_BIP| will be optimised out later: see
//pipeline: Eliminate Redundant Operations Stage//.) If there were callings,
we default them.

=
void CompileConditions::end(void) {
	if (current_session_number < 0) internal_error("unstarted PM session");
	int NC = 0, x = callings_in_condition_sp, downs = 1;
	while ((x > 0) && (callings_session_number[x-1] == current_session_number)) {
		NC++;
		x--;
	}
	if (NC == 0) {
		EmitCode::val_false();
	} else {
		@<Set the callings in this session to default values for their kinds@>;
	}
	current_session_number--;
	while (downs > 0) { downs--; EmitCode::up(); }
}

@<Set the callings in this session to default values for their kinds@> =
	EmitCode::inv(SEQUENTIAL_BIP);
	EmitCode::down(); downs++;
	int NM = 0, inner_downs = 0;;
	while ((callings_in_condition_sp > 0) &&
		(callings_session_number[callings_in_condition_sp-1] == current_session_number)) {
		NM++;
		local_variable *lvar = callings_in_condition[callings_in_condition_sp-1];
		if (NM < NC) {
			EmitCode::inv(SEQUENTIAL_BIP);
			EmitCode::down(); inner_downs++;
		}
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			inter_symbol *lvar_s = LocalVariables::declare(lvar);
			EmitCode::ref_symbol(K_value, lvar_s);
			kind *K = LocalVariables::kind(lvar);
			if ((K == NULL) ||
				(Kinds::Behaviour::is_object(K)) ||
				(Kinds::Behaviour::definite(K) == FALSE) ||
				(DefaultValues::val(K, EMPTY_WORDING,
					"'called' value") != TRUE))
				EmitCode::val_false();
		EmitCode::up();
		callings_in_condition_sp--;
	}
	while (inner_downs > 0) { inner_downs--; EmitCode::up(); }
	EmitCode::val_false();
