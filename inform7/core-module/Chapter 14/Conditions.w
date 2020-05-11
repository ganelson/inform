[Conditions::] Conditions.

Utility functions for condition nodes.

@h Creation.
In Inform, conditions are not values, nor can values be used directly as
conditions: we therefore need to provide the logical operations of AND, OR,
and NOT structurally via the SP rather than implementing them as phrases
like the arithmetic operators. (Conditions and values are kept separate
even though it does complicate the type system because this provides
cleaner resolution of ambiguities, and I don't repent of this, because the
mixture of the two is sometimes unclear enough even in C: in natural
language, it tends to look very odd indeed.)

So |LOGICAL_AND_NT| and |LOGICAL_OR_NT| imitate the effect of logical
operators. They have two arguments which must themselves be CONDITIONs;
and similarly for the unary |LOGICAL_NOT_NT|. A unique feature of Inform
among programming languages is that it has a fourth: |LOGICAL_TENSE_NT|,
which expresses that a condition holds at a different time from the present.

@ |TEST_PROPOSITION_NT| contains a predicate calculus sentence in the
|proposition| field of its SP: there are no arguments.

@ |TEST_PHRASE_OPTION_NT| tests the use of a phrase option, and is the
actual SP parsed for the second usage of the word "thoroughly" in
the following example:

>> To prognosticate, swiftly or thoroughly: ...; if thoroughly, ...

It uses the SP's data field to refer to the option in question: its value is the
bitmap value of the option, which will usually be $2^n$ where the option
is the $n$-th in the list for this phrase, counting upwards from 0.

@ |TEST_VALUE_NT| tests the value beneath it in a condition context. For
truth state values, this does the obvious thing: |true| passes and
|false| fails. For stored actions or descriptions of actions, the current
action is tested to see if it matches.

For constant descriptions, whatever is currently being discussed (the I6 value
|self|, generally speaking) is tested to see if it matches. But in order to
make definitions like this one work, we also need to treat descriptions as
values:

>> To decide which number is total (P - property) of (D - description):

The way this is done is that type-checking a description (say, "closed doors
in lighted rooms") against the expectation of finding the kind constructor
"description of K" forces Inform to convert it to a constant of that type,
compiling it as an iterator routine in I6 capable of (among other things)
supplying the members in turn, and then using the address of this routine as
the actual I6 value. (Constants with the kind "description of K" cannot arise
in any other way.)

@ Now some creator routines.

=
parse_node *Conditions::new(time_period *tp) {
	parse_node *spec = Node::new(TEST_PROPOSITION_NT);
	if (Occurrence::get_tense(tp) != IS_TENSE) internal_error("tense improperly applied");
	Conditions::attach_historic_requirement(spec, tp);
	return spec;
}

@ So, some more specific creators. The operators are easy:

=
parse_node *Conditions::new_LOGICAL_AND(parse_node *spec1, parse_node *spec2) {
	parse_node *spec = Node::new(LOGICAL_AND_NT);
	spec->down = spec1;
	spec->down->next = spec2;
	return spec;
}

parse_node *Conditions::new_LOGICAL_OR(parse_node *spec1, parse_node *spec2) {
	parse_node *spec = Node::new(LOGICAL_OR_NT);
	spec->down = spec1;
	spec->down->next = spec2;
	return spec;
}

@ =
parse_node *Conditions::negate(parse_node *cond) {
	if (Node::is(cond, LOGICAL_NOT_NT)) return cond->down;
	parse_node *spec = Node::new_with_words(LOGICAL_NOT_NT, Node::get_text(cond));
	spec->down = cond;
	return spec;
}

@ Testing propositions is also straightforward. There's no creator for
|NOW_PREPOSITION_VNT|, since this is formed only by coercion of one of these.

=
parse_node *Conditions::new_TEST_PROPOSITION(pcalc_prop *prop) {
	parse_node *spec = Node::new(TEST_PROPOSITION_NT);
	Node::set_proposition(spec, prop);
	return spec;
}

@ The option number here is actually $2^i$, where $0\leq i<15$. This is just
exactly feasible, since the specification data field is 16 bits wide.

=
parse_node *Conditions::new_TEST_PHRASE_OPTION(int opt_num) {
	parse_node *spec = Node::new(TEST_PHRASE_OPTION_NT);
	Annotations::write_int(spec, phrase_option_ANNOT, opt_num);
	return spec;
}

@ =
#ifdef IF_MODULE
parse_node *Conditions::new_TEST_ACTION(action_pattern *ap, wording W) {
	if (ap == NULL) internal_error("null action pattern");
	parse_node *spec = Node::new_with_words(TEST_VALUE_NT, W);
	spec->down = Rvalues::from_action_pattern(ap);
	Node::set_text(spec->down, W);
	return spec;
}
#endif
#ifndef IF_MODULE
parse_node *Conditions::new_TEST_ACTION(void *ap, wording W) {
	internal_error("can't make test action without IF module");
	return NULL;
}
#endif

int Conditions::is_TEST_ACTION(parse_node *spec) {
	#ifdef IF_MODULE
	if ((Node::is(spec, TEST_VALUE_NT)) &&
		(Rvalues::to_action_pattern(spec->down))) return TRUE;
	#endif
	return FALSE;
}

parse_node *Conditions::action_tested(parse_node *spec) {
	#ifdef IF_MODULE
	if (Conditions::is_TEST_ACTION(spec) == FALSE)
		internal_error("action improperly extracted");
	return spec->down;
	#endif
	#ifndef IF_MODULE
	internal_error("can't perform action_tested without IF module");
	return NULL;
	#endif
}

@ Since, in principle, any condition might also have a time period attached
to it, we need a follow-up routine to attach this as necessary to a newly
created condition:

=
parse_node *Conditions::attach_tense(parse_node *cond, int t) {
	parse_node *spec = NULL;
	if (Node::is(cond, LOGICAL_TENSE_NT)) {
		spec = cond;
		Occurrence::set_tense(Node::get_condition_tense(spec), t);
	} else {
		spec = Node::new_with_words(LOGICAL_TENSE_NT, Node::get_text(cond));
		Node::set_condition_tense(spec, Occurrence::store(Occurrence::new_tense_marker(t)));
		spec->down = cond;
	}
	return spec;
}

parse_node *Conditions::attach_historic_requirement(parse_node *cond, time_period *tp) {
	if (Node::is(cond, AMBIGUITY_NT)) {
		parse_node *amb = NULL;
		for (cond = cond->down; cond; cond = cond->next_alternative) {
			parse_node *reading = Node::duplicate(cond);
			reading->next_alternative = NULL;
			reading = Conditions::attach_historic_requirement(reading, tp);
			if (Node::is(reading, UNKNOWN_NT) == FALSE)
				amb = SyntaxTree::add_reading(amb,
					reading, Node::get_text(cond));
		}
		return amb;
	}
	int t = IS_TENSE;
	parse_node *spec = NULL;
	if (Node::is(cond, LOGICAL_TENSE_NT)) {
		spec = cond;
		t = Occurrence::get_tense(Node::get_condition_tense(cond));
	} else {
		spec = Node::new_with_words(LOGICAL_TENSE_NT, Node::get_text(cond));
		spec->down = cond;
		t = IS_TENSE;
	}
	Node::set_condition_tense(spec, tp);
	Occurrence::set_tense(Node::get_condition_tense(spec), t);
	return spec;
}

@h Pretty-printing.

=
void Conditions::write_out_in_English(OUTPUT_STREAM, parse_node *spec) {
	if (Specifications::is_description(spec)) {
		Descriptions::write_out_in_English(OUT, spec);
	} else if ((Node::is(spec, TEST_VALUE_NT)) && (Node::is(spec->down, CONSTANT_NT))) {
		kind *K = Specifications::to_kind(spec->down);
		if (K) {
			Kinds::Textual::write_articled(OUT, K);
			return;
		}
	} else {
		WRITE("a condition");
	}
}

@ And the log:

=
void Conditions::log(parse_node *spec) {
	if (Node::get_condition_tense(spec))
		Occurrence::log(DL, Node::get_condition_tense(spec));
	if (Node::is(spec, TEST_PROPOSITION_NT))
		LOG("(test: $D)", Specifications::to_proposition(spec));
	if (Specifications::is_description(spec)) {
		LOG("(st: $D)", Descriptions::to_proposition(spec));
	}
}

@h Specificity.
We will need a way of determining which of two conditions is more complex,
so that action-based rules with "when..." clauses tacked on can be sorted:
the following is used to compare such "when..." conditions.

This is essentially a counting argument. Long conditions, with many clauses,
beat shorter ones.

=
int Conditions::compare_specificity_of_CONDITIONs(parse_node *spec1, parse_node *spec2) {
	if ((spec1 == NULL) && (spec2 == NULL)) return 0;
	int count1 = Conditions::count(spec1);
	int count2 = Conditions::count(spec2);
	if (count1 > count2) return 1;
	if (count1 < count2) return -1;
	return 0;
}

@ The only justification for the following complexity score is that it does
seem to accord well with what people expect. (There's clearly no theoretically
perfect way to define complexity of conditions in a language as complex as
Inform; this bit of scruffy, rather than neat, logic will have to do.)

=
int Conditions::count(parse_node *spec) {
	if (spec == NULL) return 0;
	if (ParseTreeUsage::is_condition(spec) == FALSE) return 1;
	switch (Node::get_type(spec)) {
		case LOGICAL_AND_NT:
			return Conditions::count(spec->down)
				+ Conditions::count(spec->down->next);
		case LOGICAL_OR_NT:
			return -1;
		case LOGICAL_NOT_NT:
			return Conditions::count(spec->down);
		case LOGICAL_TENSE_NT:
			return Conditions::count(spec->down);
		case TEST_PROPOSITION_NT:
			return Calculus::Propositions::length(Specifications::to_proposition(spec));
		case TEST_PHRASE_OPTION_NT:
		case TEST_VALUE_NT:
			return 1;
	}
	return 0;
}

@h Compiling.
We clear two oddball cases out of the way, and then for the most part we
delegate to potent routines elsewhere. Note that in some situations a valid
I6 condition must be enclosed in round brackets, and that a redundant pair
of brackets never does any harm; so we always compile one.

=
void Conditions::compile(value_holster *VH, parse_node *spec_found) {
	switch (Node::get_type(spec_found)) {
		case TEST_PROPOSITION_NT:
			Calculus::Deferrals::emit_test_of_proposition(NULL,
				Specifications::to_proposition(spec_found));
			break;
		case LOGICAL_TENSE_NT:
			Chronology::compile_past_tense_condition(VH, spec_found);
			break;
		case LOGICAL_NOT_NT: @<Compile a logical negation@>; break;
		case LOGICAL_AND_NT: case LOGICAL_OR_NT: @<Compile a logical operator@>; break;
		case TEST_VALUE_NT: {
			if (Conditions::is_TEST_ACTION(spec_found)) {
				#ifdef IF_MODULE
				action_pattern *ap = Rvalues::to_action_pattern(
					Conditions::action_tested(spec_found));
				PL::Actions::Patterns::compile_pattern_match(VH, *ap, FALSE);
				#endif
			} else if (Specifications::is_description(spec_found)) {
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1); /* purely for problem recovery */
			} else {
				Specifications::Compiler::emit_as_val(K_value, spec_found->down);
			}
			break;
		}
		case TEST_PHRASE_OPTION_NT: @<Compile a phrase option test@>; break;
	}
}

@ An easy case, running straight out to I6 operators:

@<Compile a logical negation@> =
	if (Node::no_children(spec_found) != 1)
		internal_error("Compiled malformed LOGICAL_NOT_NT");
	Produce::inv_primitive(Emit::tree(), NOT_BIP);
	Produce::down(Emit::tree());
		Specifications::Compiler::emit_as_val(K_value, spec_found->down);
	Produce::up(Emit::tree());

@ An easy case, running straight out to I6 operators:

@<Compile a logical operator@> =
	if (Node::no_children(spec_found) != 2)
		internal_error("Compiled malformed logical operator");
	parse_node *left_operand = spec_found->down;
	parse_node *right_operand = spec_found->down->next;
	if ((left_operand == NULL) || (right_operand == NULL))
		internal_error("Compiled CONDITION/AND with LHS operands");

	if (Node::is(spec_found, LOGICAL_AND_NT)) Produce::inv_primitive(Emit::tree(), AND_BIP);
	if (Node::is(spec_found, LOGICAL_OR_NT)) Produce::inv_primitive(Emit::tree(), OR_BIP);
	Produce::down(Emit::tree());
		Specifications::Compiler::emit_as_val(K_value, left_operand);
		Specifications::Compiler::emit_as_val(K_value, right_operand);
	Produce::up(Emit::tree());

@ Phrase options are stored as bits in a 16-bit map, so that each individual
option is a power of two from $2^0$ to $2^15$. We test if this is valid by
performing logical-and against the I6 local variable |phrase_options|, which
exists if and only if the enclosing I6 routine takes phrase options. The
type-checker won't allow these specifications to be compiled anywhere else.

@<Compile a phrase option test@> =
	Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
	Produce::down(Emit::tree());
		local_variable *po = LocalVariables::phrase_options();
		if (po == NULL) internal_error("no phrase options exist in this frame");
		inter_symbol *po_s = LocalVariables::declare_this(po, FALSE, 8);
		Produce::val_symbol(Emit::tree(), K_value, po_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) Annotations::read_int(spec_found, phrase_option_ANNOT));
	Produce::up(Emit::tree());
