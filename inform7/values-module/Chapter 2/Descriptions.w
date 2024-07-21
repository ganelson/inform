[Descriptions::] Descriptions.

Descriptions such as "open door" or "number which is greater than 8" which may
or may not be true of any given rvalue at run-time.

@h Descriptions vs propositions.
A description of $K$-values is stored as a |TEST_VALUE_NT| node with a constant
node beneath it of kind "description of $K$". This in turn will hold a logical
proposition $\phi(x)$ with one free variable $x$ expected to range over $K$.

=
parse_node *Descriptions::from_proposition(pcalc_prop *prop, wording W) {
	parse_node *spec = Node::new_with_words(TEST_VALUE_NT, W);
	spec->down = Rvalues::constant_description(prop, W);
	return spec;
}

pcalc_prop *Descriptions::to_proposition(parse_node *spec) {
	if ((Specifications::is_description(spec)) || (Node::is(spec, TEST_VALUE_NT))) {
		spec = spec->down;
	} else {
		LOG("Spec: $T\n", spec);
		internal_error("tried to extract proposition from non-description");
	}
	if (Rvalues::is_CONSTANT_construction(spec, CON_description))
		return Specifications::to_proposition(spec);
	return NULL;
}

pcalc_prop *Descriptions::to_unbound_proposition(parse_node *spec) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	if (prop) prop = Binding::unbind(prop);
	return prop;
}

@ We are going to need to edit the proposition, using the following:

=
void Descriptions::set_proposition(parse_node *spec, pcalc_prop *prop) {
	if (Specifications::is_description(spec)) spec = spec->down;
	else internal_error("tried to set proposition for non-description");
	if (Rvalues::is_CONSTANT_construction(spec, CON_description))
		Rvalues::set_constant_description_proposition(spec, prop);
	else internal_error("set domain proposition wrongly");
}

@h Descriptions vs kinds.
A kind is "composited" if it's derived from a word such as "something",
which implies a quantifier as well as a kind.

=
parse_node *Descriptions::from_kind(kind *K, int composited) {
	parse_node *spec = Descriptions::from_proposition(NULL, EMPTY_WORDING);
	if (K) { /* a test made only for error recovery */
		pcalc_prop *prop;
		if (composited)
			prop = KindPredicates::new_composited_atom(K, Terms::new_variable(0));
		else
			prop = KindPredicates::new_atom(K, Terms::new_variable(0));
		TypecheckPropositions::type_check(prop,
			TypecheckPropositions::tc_no_problem_reporting());
		Descriptions::set_proposition(spec, prop);
	}
	return spec;
}

kind *Descriptions::to_kind(parse_node *spec) {
	return Binding::infer_kind_of_variable_0(
		Descriptions::to_proposition(spec));
}

@ Some descriptions explicitly name a kind ("even numbers"), others imply
a kind but do so only implicitly ("scenery").

=
int Descriptions::makes_kind_explicit(parse_node *spec) {
	if ((Specifications::is_description(spec)) &&
		(Descriptions::explicit_kind(spec))) return TRUE;
	return FALSE;
}

kind *Descriptions::explicit_kind(parse_node *spec) {
	return Propositions::describes_kind(Descriptions::to_proposition(spec));
}

@h Descriptions vs instances.
One is not allowed to form a description such as "the even 22", where
adjectives are applied to a literal. But one is allowed to do so with
a named object or similar, so:

=
parse_node *Descriptions::from_instance(instance *I, wording W) {
	if (I == NULL) internal_error("description of null instance");
	parse_node *val = Rvalues::from_instance(I);
	pcalc_prop *prop = Atoms::prop_x_is_constant(val);
	TypecheckPropositions::type_check(prop,
		TypecheckPropositions::tc_no_problem_reporting());
	return Descriptions::from_proposition(prop, W);
}

instance *Descriptions::to_instance(parse_node *spec) {
	if (Specifications::is_description(spec)) {
		pcalc_prop *prop = Descriptions::to_proposition(spec);
		parse_node *val = Propositions::describes_value(prop);
		if (val == NULL) return NULL;
		return Rvalues::to_instance(val);
	}
	return NULL;
}

@h Descriptions vs constants.
A description such as "even numbers" is normally represented as a description
node, but sometimes we need to think of this as a noun and not a predicate.
If so, we convert to a constant using the following. Note that we remove
a universal quantifier: this is so that "even numbers", if read as "all
even numbers", becomes rather "is an even number".

=
parse_node *Descriptions::to_rvalue(parse_node *spec) {
	if (Rvalues::is_CONSTANT_construction(spec, CON_description)) return spec;
	if (Specifications::is_description(spec) == FALSE) {
		LOG("$T\n", spec); internal_error("not a description");
	}
	pcalc_prop *prop = Propositions::copy(
		Descriptions::to_proposition(spec));
	if (prop) {
		prop = Propositions::trim_universal_quantifier(prop);
		if (Binding::number_free(prop) != 1)
			return NULL; /* Specifications::new_UNKNOWN(Node::get_text(spec)); */
	}

	parse_node *con = Node::new(CONSTANT_NT);
	Node::set_kind_of_value(con,
		Kinds::unary_con(CON_description,
			Binding::infer_kind_of_variable_0(prop)));
	Node::set_proposition(con, prop);
	Node::set_text(con, Node::get_text(spec));
	return con;
}

@h Testing.
Descriptions are "qualified" when adjectives, or relative clauses, make
them dependent on context. For instance, "a vehicle" is unqualified, but
"an even number" or "a vehicle in Trafalgar Square" are qualified --
the same value might satisfy the description at some times but not others
during play.

=
int Descriptions::is_qualified(parse_node *spec) {
	if ((Specifications::is_description(spec)) &&
		((Descriptions::is_complex(spec)) ||
			(Descriptions::number_of_adjectives_applied_to(spec) > 0)))
		return TRUE;
	return FALSE;
}

int Descriptions::is_kind_like(parse_node *spec) {
	if ((Specifications::is_description(spec)) &&
		(Propositions::length(Descriptions::to_proposition(spec)) == 1) &&
		(Descriptions::explicit_kind(spec)))
		return TRUE;
	return FALSE;
}

int Descriptions::is_complex(parse_node *spec) {
	if (Specifications::is_description(spec))
		return Propositions::is_complex(
			Descriptions::to_proposition(spec));
	return FALSE;
}

int Descriptions::is_adjectives_plus_kind(parse_node *spec) {
	if (Specifications::is_description(spec)) {
		if (Descriptions::number_of_adjectives_applied_to(spec) == 0)
			return FALSE;
		kind *K = Descriptions::explicit_kind(spec);
		if (K) return TRUE;
	}
	return FALSE;
}

@h Adjectives.
Adjectives occurring in the proposition can be thought of as forming
a list. It's sometimes convenient to loop through this list:

@d LOOP_THROUGH_ADJECTIVE_LIST(au, au_prop, spec)
	for (au = Propositions::first_unary_predicate(
		Descriptions::to_proposition(spec), &au_prop);
		au;
		au = Propositions::next_unary_predicate(&au_prop))

=
int Descriptions::number_of_adjectives_applied_to(parse_node *spec) {
	return Propositions::count_adjectives(
		Descriptions::to_proposition(spec));
}

unary_predicate *Descriptions::first_unary_predicate(parse_node *spec) {
	return Propositions::first_unary_predicate(
		Descriptions::to_proposition(spec), NULL);
}

void Descriptions::add_to_adjective_list(unary_predicate *au, parse_node *spec) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	adjective *aph = AdjectivalPredicates::to_adjective(au);
	int negated = FALSE;
	if (AdjectivalPredicates::parity(au) == FALSE) negated = TRUE;
	prop = Propositions::concatenate(prop,
		AdjectivalPredicates::new_atom_on_x(aph, negated));
	TypecheckPropositions::type_check(prop,
		TypecheckPropositions::tc_no_problem_reporting());
	Descriptions::set_proposition(spec, prop);
}

void Descriptions::add_to_adjective_list_w(unary_predicate *au, parse_node *spec) {
	quantifier *Q = Descriptions::get_quantifier(spec);
	int N = Descriptions::get_quantification_parameter(spec);
	pcalc_prop *prop = Descriptions::get_inner_prop(spec);
	adjective *aph = AdjectivalPredicates::to_adjective(au);
	int negated = FALSE;
	if (AdjectivalPredicates::parity(au) == FALSE) negated = TRUE;
	prop = Propositions::concatenate(prop,
		AdjectivalPredicates::new_atom_on_x(aph, negated));
	TypecheckPropositions::type_check(prop,
		TypecheckPropositions::tc_no_problem_reporting());
	Descriptions::set_proposition(spec, prop);
	if (Q) Descriptions::quantify(spec, Q, N);
}

@h Quantification.
For example, the "all" in "all of the open doors".

=
void Descriptions::quantify(parse_node *spec, quantifier *q, int par) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	if (q != exists_quantifier)
		prop = Propositions::concatenate(Atoms::new(DOMAIN_OPEN_ATOM), prop);
	prop = Propositions::concatenate(Atoms::QUANTIFIER_new(q, 0, par), prop);
	if (q != exists_quantifier)
		prop = Propositions::concatenate(prop, Atoms::new(DOMAIN_CLOSE_ATOM));
	Descriptions::set_proposition(spec, prop);
	TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_no_problem_reporting());
}

pcalc_prop *Descriptions::get_inner_prop(parse_node *spec) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	if ((prop) && (Atoms::get_quantifier(prop))) {
		prop = Propositions::copy(prop);
		prop = Propositions::ungroup_after(prop, prop, NULL);
		return prop->next;
	}
	return SentencePropositions::from_spec(spec);
}

pcalc_prop *Descriptions::get_quantified_prop(parse_node *spec) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	if ((prop) && (Atoms::get_quantifier(prop)) &&
		(Atoms::get_quantification_parameter(prop) > 0)) {
		prop = Propositions::copy(prop);
		prop = Propositions::ungroup_after(prop, prop, NULL);
		return prop->next;
	}
	return SentencePropositions::from_spec(spec);
}

quantifier *Descriptions::get_quantifier(parse_node *spec) {
	if (Specifications::is_description(spec))
		return Atoms::get_quantifier(Descriptions::to_proposition(spec));
	return NULL;
}

int Descriptions::get_quantification_parameter(parse_node *spec) {
	if (Specifications::is_description(spec))
		return Atoms::get_quantification_parameter(Descriptions::to_proposition(spec));
	return 0;
}

@h Callings.
For example, "the neighbour" in "a room which is adjacent to a lighted room
(called the neighbour)".

=
void Descriptions::attach_calling(parse_node *spec, wording C) {
	kind *K = Descriptions::explicit_kind(spec);
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	prop = Propositions::concatenate(
		prop,
		CreationPredicates::calling_up(C, Terms::new_variable(0), K));
	TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_no_problem_reporting());
	Descriptions::set_proposition(spec, prop);
}

wording Descriptions::get_calling(parse_node *spec) {
	if (Specifications::is_description(spec))
		for (pcalc_prop *pp = Descriptions::to_proposition(spec); pp; pp = pp->next)
			if (CreationPredicates::is_calling_up_atom(pp))
				return CreationPredicates::get_calling_name(pp);
	return EMPTY_WORDING;
}

void Descriptions::clear_calling(parse_node *spec) {
	if (spec == NULL) return;
	pcalc_prop *pp, *prev_pp = NULL;
	for (pp = Descriptions::to_proposition(spec); pp; prev_pp = pp, pp = pp->next)
		if (CreationPredicates::is_calling_up_atom(pp)) {
			Descriptions::set_proposition(spec,
				Propositions::delete_atom(
					Descriptions::to_proposition(spec), prev_pp));
			return;
		}
}

int Descriptions::makes_callings(parse_node *spec) {
	if (spec == NULL) return FALSE;
	if (Specifications::is_description(spec)) {
		if (CreationPredicates::contains_callings(Descriptions::to_proposition(spec)))
			return TRUE;
		wording C = Descriptions::get_calling(spec);
		if (Wordings::nonempty(C)) return TRUE;
	}
	return FALSE;
}

@h Pretty-printing.

=
void Descriptions::write_out_in_English(OUTPUT_STREAM, parse_node *spec) {
	kind *K = Specifications::to_kind(spec);
	WRITE("a description");
	if (K) {
		wording KW = Kinds::Behaviour::get_name(K, TRUE);
		if (Wordings::nonempty(KW)) WRITE(" of %+W", KW);
	}
}

@h Comparing.
Descriptions are used to set out the domain of rules, and rules have to be sorted
in order of narrowness, which means we need a way to tell which is narrower of
two descriptions.

=
int Descriptions::compare_specificity(parse_node *spec1, parse_node *spec2) {
	@<If either of these two descriptions has a complex proposition, then propositional size decides it@>;
	@<If the typechecker recognises one as properly within the other, then that's the more specific@>;
	@<If either of these two descriptions have adjectives, adjective count decides it@>;
	@<If both descriptions specify a kind, kind inheritance decides it@>;
	return 0;
}

@ Which of two propositions is more specific? To perform that test perfectly,
we would need a way to determine, given two propositions A and B, whether one
implied the other or not. Since predicate calculus is complete, and our
domains are mostly finite, there do in fact exist (slow and difficult)
algorithms which could determine this. But there would be real problems with
larger domains not amenable to model-checking, such as "number", and anyway --
why not cheat?

Proposition length is admittedly a crude measure, but because of the fact that
both propositions have come from the same generative algorithm, it does indeed
turn out that $A\Rightarrow B$ means $\ell(A) \geq \ell(B)$, where $\ell$ is
the number of atoms in the proposition. So we simply use it as a sorting key.

@<If either of these two descriptions has a complex proposition, then propositional size decides it@> =
	int comp1 = Descriptions::is_complex(spec1);
	int comp2 = Descriptions::is_complex(spec2);
	if ((comp1) || (comp2)) {
		if (comp2 == FALSE) return 1;
		if (comp1 == FALSE) return -1;
		int len1 = Propositions::length(Descriptions::to_proposition(spec1));
		int len2 = Propositions::length(Descriptions::to_proposition(spec2));
		if ((len1 > 0) || (len2 > 0)) {
			LOGIF(SPECIFICITIES,
				"Test %d: Comparing specificity of props:\n(%d) $D\n(%d) $D\n",
				cco, len1, Descriptions::to_proposition(spec1), len2, Descriptions::to_proposition(spec2));
		}
		if (len1 > len2) return 1;
		if (len1 < len2) return -1;
	}

@<If the typechecker recognises one as properly within the other, then that's the more specific@> =
	if (Dash::compatible_with_description(spec1, spec2) == ALWAYS_MATCH) {
		if (Dash::compatible_with_description(spec2, spec1) != ALWAYS_MATCH) return 1;
	} else {
		if (Dash::compatible_with_description(spec2, spec1) == ALWAYS_MATCH) return -1;
	}

@<If either of these two descriptions have adjectives, adjective count decides it@> =
	int count1 = Descriptions::number_of_adjectives_applied_to(spec1);
	int count2 = Descriptions::number_of_adjectives_applied_to(spec2);
	if (count1 > count2) return 1;
	if (count1 < count2) return -1;

@<If both descriptions specify a kind, kind inheritance decides it@> =
	kind *k1 = Descriptions::explicit_kind(spec1);
	kind *k2 = Descriptions::explicit_kind(spec2);
	if ((k1) && (k2)) {
		if (Kinds::ne(k1, k2)) {
			if (Kinds::conforms_to(k1, k2)) return 1;
			if (Kinds::conforms_to(k2, k1)) return -1;
		}
	}

