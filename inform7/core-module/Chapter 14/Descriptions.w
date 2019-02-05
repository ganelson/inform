[Descriptions::] Descriptions.

Description nodes represent text such as "even numbers", which
can either define a set of values or a predicate on them.

@h Descriptions vs propositions.
A description of K-values is stored as a |TEST_VALUE_NT| node with a constant
node beneath it of kind "description of K":

=
parse_node *Descriptions::from_proposition(pcalc_prop *prop, wording W) {
	parse_node *spec = ParseTree::new_with_words(TEST_VALUE_NT, W);
	spec->down = Rvalues::constant_description(prop, W);
	return spec;
}

pcalc_prop *Descriptions::to_proposition(parse_node *spec) {
	if (Specifications::is_description(spec)) spec = spec->down;
	else internal_error("tried to extract proposition from non-description");
	if (Rvalues::is_CONSTANT_construction(spec, CON_description))
		return Specifications::to_proposition(spec);
	return NULL;
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
			prop = Calculus::Atoms::KIND_new_composited(K, Calculus::Terms::new_variable(0));
		else
			prop = Calculus::Atoms::KIND_new(K, Calculus::Terms::new_variable(0));
		Calculus::Propositions::Checker::type_check(prop,
			Calculus::Propositions::Checker::tc_no_problem_reporting());
		Descriptions::set_proposition(spec, prop);
	}
	return spec;
}

kind *Descriptions::to_kind(parse_node *spec) {
	return Calculus::Variables::infer_kind_of_variable_0(
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
	return Calculus::Propositions::describes_kind(Descriptions::to_proposition(spec));
}

@h Descriptions vs instances.
One is not allowed to form a description such as "the even 22", where
adjectives are applied to a literal. But one is allowed to do so with
a named object or similar, so:

=
parse_node *Descriptions::from_instance(instance *I, wording W) {
	if (I == NULL) internal_error("description of null instance");
	parse_node *val = Rvalues::from_instance(I);
	pcalc_prop *prop = Calculus::Atoms::prop_x_is_constant(val);
	Calculus::Propositions::Checker::type_check(prop,
		Calculus::Propositions::Checker::tc_no_problem_reporting());
	return Descriptions::from_proposition(prop, W);
}

instance *Descriptions::to_instance(parse_node *spec) {
	if (Specifications::is_description(spec)) {
		pcalc_prop *prop = Descriptions::to_proposition(spec);
		parse_node *val = Calculus::Propositions::describes_value(prop);
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
	if (Specifications::is_description(spec) == FALSE) internal_error("not a description");

	pcalc_prop *prop = Calculus::Propositions::copy(
		Descriptions::to_proposition(spec));
	if (prop) {
		prop = Calculus::Propositions::trim_universal_quantifier(prop);
		if (Calculus::Variables::number_free(prop) != 1)
			return NULL; /* Specifications::new_UNKNOWN(ParseTree::get_text(spec)); */
	}

	parse_node *con = ParseTree::new(CONSTANT_NT);
	ParseTree::set_kind_of_value(con,
		Kinds::unary_construction(CON_description,
			Calculus::Variables::infer_kind_of_variable_0(prop)));
	ParseTree::set_proposition(con, prop);
	ParseTree::set_text(con, ParseTree::get_text(spec));
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
		(Calculus::Propositions::length(Descriptions::to_proposition(spec)) == 1) &&
		(Descriptions::explicit_kind(spec)))
		return TRUE;
	return FALSE;
}

int Descriptions::is_complex(parse_node *spec) {
	if (Specifications::is_description(spec))
		return Calculus::Propositions::is_complex(
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
	for (au = Calculus::Propositions::first_adjective_usage(
		Descriptions::to_proposition(spec), &au_prop);
		au;
		au = Calculus::Propositions::next_adjective_usage(&au_prop))

=
int Descriptions::number_of_adjectives_applied_to(parse_node *spec) {
	return Calculus::Propositions::count_unary_predicates(
		Descriptions::to_proposition(spec));
}

adjective_usage *Descriptions::first_adjective_usage(parse_node *spec) {
	return Calculus::Propositions::first_adjective_usage(
		Descriptions::to_proposition(spec), NULL);
}

void Descriptions::add_to_adjective_list(adjective_usage *au, parse_node *spec) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	adjectival_phrase *aph = AdjectiveUsages::get_aph(au);
	int negated = FALSE;
	if (AdjectiveUsages::get_parity(au) == FALSE) negated = TRUE;
	prop = Calculus::Propositions::concatenate(prop,
		Calculus::Atoms::unary_PREDICATE_from_aph(aph, negated));
	Calculus::Propositions::Checker::type_check(prop,
		Calculus::Propositions::Checker::tc_no_problem_reporting());
	Descriptions::set_proposition(spec, prop);
}

void Descriptions::add_to_adjective_list_w(adjective_usage *au, parse_node *spec) {
	quantifier *Q = Descriptions::get_quantifier(spec);
	int N = Descriptions::get_quantification_parameter(spec);
	pcalc_prop *prop = Descriptions::get_inner_prop(spec);
	adjectival_phrase *aph = AdjectiveUsages::get_aph(au);
	int negated = FALSE;
	if (AdjectiveUsages::get_parity(au) == FALSE) negated = TRUE;
	prop = Calculus::Propositions::concatenate(prop,
		Calculus::Atoms::unary_PREDICATE_from_aph(aph, negated));
	Calculus::Propositions::Checker::type_check(prop,
		Calculus::Propositions::Checker::tc_no_problem_reporting());
	Descriptions::set_proposition(spec, prop);
	if (Q) Descriptions::quantify(spec, Q, N);
}

@h Quantification.
For example, the "all" in "all of the open doors".

=
void Descriptions::quantify(parse_node *spec, quantifier *q, int par) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	if (q != exists_quantifier)
		prop = Calculus::Propositions::concatenate(Calculus::Atoms::new(DOMAIN_OPEN_ATOM), prop);
	prop = Calculus::Propositions::concatenate(Calculus::Atoms::QUANTIFIER_new(q, 0, par), prop);
	if (q != exists_quantifier)
		prop = Calculus::Propositions::concatenate(prop, Calculus::Atoms::new(DOMAIN_CLOSE_ATOM));
	Descriptions::set_proposition(spec, prop);
	Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
}

pcalc_prop *Descriptions::get_inner_prop(parse_node *spec) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	if ((prop) && (Calculus::Atoms::get_quantifier(prop))) {
		prop = Calculus::Propositions::copy(prop);
		prop = Calculus::Propositions::ungroup_after(prop, prop, NULL);
		return prop->next;
	}
	return Calculus::Propositions::from_spec(spec);
}

pcalc_prop *Descriptions::get_quantified_prop(parse_node *spec) {
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	if ((prop) && (Calculus::Atoms::get_quantifier(prop)) &&
		(Calculus::Atoms::get_quantification_parameter(prop) > 0)) {
		prop = Calculus::Propositions::copy(prop);
		prop = Calculus::Propositions::ungroup_after(prop, prop, NULL);
		return prop->next;
	}
	return Calculus::Propositions::from_spec(spec);
}

quantifier *Descriptions::get_quantifier(parse_node *spec) {
	if (Specifications::is_description(spec))
		return Calculus::Atoms::get_quantifier(Descriptions::to_proposition(spec));
	return NULL;
}

int Descriptions::get_quantification_parameter(parse_node *spec) {
	if (Specifications::is_description(spec))
		return Calculus::Atoms::get_quantification_parameter(Descriptions::to_proposition(spec));
	return 0;
}

@h Callings.
For example, "the neighbour" in "a room which is adjacent to a lighted room
(called the neighbour)".

=
void Descriptions::attach_calling(parse_node *spec, wording C) {
	kind *K = Descriptions::explicit_kind(spec);
	pcalc_prop *prop = Descriptions::to_proposition(spec);
	prop = Calculus::Propositions::concatenate(
		prop,
		Calculus::Atoms::CALLED_new(C, Calculus::Terms::new_variable(0), K));
	Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
	Descriptions::set_proposition(spec, prop);
}

wording Descriptions::get_calling(parse_node *spec) {
	if (Specifications::is_description(spec))
		for (pcalc_prop *pp = Descriptions::to_proposition(spec); pp; pp = pp->next)
			if (pp->element == CALLED_ATOM)
				return Calculus::Atoms::CALLED_get_name(pp);
	return EMPTY_WORDING;
}

void Descriptions::clear_calling(parse_node *spec) {
	if (spec == NULL) return;
	pcalc_prop *pp, *prev_pp = NULL;
	for (pp = Descriptions::to_proposition(spec); pp; prev_pp = pp, pp = pp->next)
		if (pp->element == CALLED_ATOM) {
			Descriptions::set_proposition(spec,
				Calculus::Propositions::delete_atom(
					Descriptions::to_proposition(spec), prev_pp));
			return;
		}
}

int Descriptions::makes_callings(parse_node *spec) {
	if (spec == NULL) return FALSE;
	if (Specifications::is_description(spec)) {
		if (Calculus::Propositions::contains_callings(Descriptions::to_proposition(spec)))
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
		int len1 = Calculus::Propositions::length(Descriptions::to_proposition(spec1));
		int len2 = Calculus::Propositions::length(Descriptions::to_proposition(spec2));
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
		if (Kinds::Compare::lt(k1, k2)) return 1;
		if (Kinds::Compare::lt(k2, k1)) return -1;
	}

