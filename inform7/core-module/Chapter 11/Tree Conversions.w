[Calculus::Propositions::Abstract::] Tree Conversions.

The second of the three sources of propositions to conjure with:
those which arise from subtrees constructed by the A-parser.

@h Elementary propositions.
The S-parser attacks whole sentences, but the A-parser more cautiously takes
on only fragments, and so it makes much shorter propositions -- usually with
a single free variable representing an object or value to which something
must be done.

We start with some elementary propositions which create things, by asserting
their existence.

=
pcalc_prop *Calculus::Propositions::Abstract::to_make_a_kind(kind *K) {
	return Atoms::ISAKIND_new(Terms::new_variable(0), K);
}

pcalc_prop *Calculus::Propositions::Abstract::to_make_a_var(void) {
	return Atoms::ISAVAR_new(Terms::new_variable(0));
}

pcalc_prop *Calculus::Propositions::Abstract::to_make_a_const(void) {
	return Atoms::ISACONST_new(Terms::new_variable(0));
}

pcalc_prop *Calculus::Propositions::Abstract::to_create_something(kind *K, wording W) {
	pcalc_prop *prop = Atoms::QUANTIFIER_new(exists_quantifier, 0, 0);
	if ((K) && (Kinds::eq(K, K_object) == FALSE))
		prop = Calculus::Propositions::concatenate(prop,
			Atoms::KIND_new(K, Terms::new_variable(0)));
	if (Wordings::nonempty(W))
		prop = Calculus::Propositions::concatenate(prop,
			Atoms::CALLED_new(W, Terms::new_variable(0), K));
	return prop;
}

@ A proposition to assert that an object has a given kind:

=
pcalc_prop *Calculus::Propositions::Abstract::prop_to_set_kind(instance *I, kind *k) {
	return Atoms::KIND_new(k, Terms::new_variable(0));
}

void Calculus::Propositions::Abstract::assert_kind_of_object(instance *I, kind *k) {
	Calculus::Propositions::Assert::assert_true_about(Calculus::Propositions::Abstract::prop_to_set_kind(I, k),
		Instances::as_subject(I), prevailing_mood);
}

void Calculus::Propositions::Abstract::assert_kind_of_subject(inference_subject *inst, inference_subject *new,
	pcalc_prop *subject_to) {
	kind *K = InferenceSubjects::domain(new);
	pcalc_prop *prop = Atoms::KIND_new(K, Terms::new_variable(0));
	if (subject_to) prop = Calculus::Propositions::concatenate(prop, subject_to);
	Calculus::Propositions::Assert::assert_true_about(prop, inst, prevailing_mood);
}

@ Now propositions to assert that relations hold:

=
pcalc_prop *Calculus::Propositions::Abstract::to_set_simple_relation(binary_predicate *bp, instance *I) {
	parse_node *spec;
	if (I) spec = Rvalues::from_instance(I);
	else spec = Rvalues::new_nothing_object_constant();
	return Atoms::binary_PREDICATE_new(bp,
		Terms::new_variable(0), Terms::new_constant(spec));
}

pcalc_prop *Calculus::Propositions::Abstract::to_set_relation(binary_predicate *bp,
	inference_subject *infs0, parse_node *spec0, inference_subject *infs1, parse_node *spec1) {
	pcalc_term pt0, pt1;
	if (infs0) pt0 = Terms::new_constant(InferenceSubjects::as_constant(infs0));
	else pt0 = Terms::new_constant(spec0);
	if (infs1) pt1 = Terms::new_constant(InferenceSubjects::as_constant(infs1));
	else pt1 = Terms::new_constant(spec1);
	pcalc_prop *prop = Atoms::binary_PREDICATE_new(bp, pt0, pt1);
	int dummy;
	prop = Calculus::Simplifications::make_kinds_of_value_explicit(prop, &dummy);
	return prop;
}

@ Property provision is itself a relation:

=
pcalc_prop *Calculus::Propositions::Abstract::to_provide_property(property *prn) {
	return Atoms::binary_PREDICATE_new(R_provision,
		Terms::new_variable(0), Terms::new_constant(Rvalues::from_property(prn)));
}

pcalc_prop *Calculus::Propositions::Abstract::to_set_property(property *prn, parse_node *val) {
	if (val == NULL) return NULL;
	if (Properties::Valued::get_setting_bp(prn) == NULL) internal_error("no BP for this property");
	return Atoms::binary_PREDICATE_new(Properties::Valued::get_setting_bp(prn),
		Terms::new_variable(0), Terms::new_constant(val));
}

@ "Everywhere", "nowhere" and "here":

=
pcalc_prop *Calculus::Propositions::Abstract::to_put_everywhere(void) {
	return Atoms::EVERYWHERE_new(Terms::new_variable(0));
}

pcalc_prop *Calculus::Propositions::Abstract::to_put_nowhere(void) {
	return Atoms::NOWHERE_new(Terms::new_variable(0));
}

pcalc_prop *Calculus::Propositions::Abstract::to_put_here(void) {
	return Atoms::HERE_new(Terms::new_variable(0));
}

@h Property setting.
Sometimes the A-parser wants to assert that a given property has the value
whose text can be found in a node |py|...

=
pcalc_prop *Calculus::Propositions::Abstract::from_property_subtree(property *prn, parse_node *py) {
	return Calculus::Propositions::Abstract::to_set_property(prn, Assertions::PropertyKnowledge::property_value_from_property_subtree(prn, py));
}

@ ...and sometimes it wants to assert a more elaborate list, such as "carrying
capacity 10 and weight 4kg" or "lockable unlocked". This is a syntax
allowed by the A-parser but not the S-parser, and here is where we deal
with it.

=
pcalc_prop *Calculus::Propositions::Abstract::from_property_list(parse_node *p, kind *K) {
	pcalc_prop *prop = NULL;
	if (p) {
		switch(Node::get_type(p)) {
			case AND_NT:
				for (p = p->down; p; p = p->next)
					prop = Calculus::Propositions::conjoin(prop, Calculus::Propositions::Abstract::from_property_list(p, NULL));
				break;
			case PROPERTY_LIST_NT:
				@<Conjoin atoms to assert from a property list@>;
				break;
			case ADJECTIVE_NT:
				@<Conjoin atoms to assert from an adjective node@>;
				break;
			default: internal_error_on_node_type(p);
		}
	}

	if ((prop) && (K)) {
		prop = Calculus::Propositions::conjoin(
			Atoms::KIND_new(K, Terms::new_variable(0)), prop);
	}
	return prop;
}

@ Recall that a |PROPERTY_LIST_NT| node is unannotated, as yet, and we have to
parse the text to find what which property is referred to.

@<Conjoin atoms to assert from a property list@> =
	property *prn = NULL;
	wording PW = EMPTY_WORDING, VW = EMPTY_WORDING;
	@<Divide the property list entry into property name and value text@>;

	if ((Wordings::nonempty(PW)) && (<property-name>(PW))) prn = <<rp>>;
	if (prn == NULL) @<Issue a problem message for no-such-property@>;

	if (Wordings::nonempty(VW)) { /* a value is supplied... */
		if (Properties::is_either_or(prn)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(p));
			Problems::quote_property(3, prn);
			Problems::quote_wording(4, VW);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_WithEitherOrValue));
			Problems::issue_problem_segment(
				"The sentence '%1' seems to be trying to create something which "
				"has '%2', where the %3 property is being set equal to %4. But "
				"this made no sense to me, because %3 is an either/or property "
				"and cannot have a value.");
			Problems::issue_problem_end();
			return NULL;
		}
		<np-as-object>(VW);
		parse_node *pn = <<rp>>;
		Refiner::refine(pn, FORBID_CREATION);
		pcalc_prop *P = Calculus::Propositions::Abstract::from_property_subtree(prn, pn);
		prop = Calculus::Propositions::conjoin(prop, P);
	} else { /* no value is supplied... */
		if (Properties::is_either_or(prn) == FALSE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(p));
			Problems::quote_property(3, prn);
			Problems::quote_kind(4, Properties::Valued::kind(prn));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_WithValuelessValue));
			Problems::issue_problem_segment(
				"The sentence '%1' seems to be trying to create something which "
				"has '%2', where the %3 property is being set in some way. But "
				"this made no sense to me, because %3 is a value property (it "
				"needs to be %4) and no value for it was given here.");
			Problems::issue_problem_end();
			return NULL;
		}
		prop = Calculus::Propositions::conjoin(prop, Calculus::Propositions::Abstract::from_property_subtree(prn, NULL));
	}

@ The node has text in the form "property name property value", with no
obvious division of punctuation between the two. What makes matters worse
is that we do not yet know all the property names, nor do we have the
ability to discern values. So we seek the division by
(i) trying to find the longest known property name at the start of the
text; if there is no known name,
(ii) we see if the final word of the text is a literal, such as a number or
a quoted text, and if so we assume this is the entire property value and
that the rest is property name; and otherwise
(iii) we assume the property name is one word only.

@<Divide the property list entry into property name and value text@> =
	wording W = Articles::remove_the(Node::get_text(p));
	if (Wordings::empty(W)) {
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this looked to me as if it might be trying to create something "
			"which has certain properties",
			"and that made no sense on investigation. This sometimes happens "
			"if a sentence uses 'to have' oddly?");
		return NULL;
	}
	int name_length = Properties::match_longest(W);
	if (name_length < 0) {
		name_length = 1;
		if (<s-literal>(W)) name_length = Wordings::length(W) - 1;
	}
	PW = Wordings::up_to(W, Wordings::first_wn(W) + name_length - 1);
	VW = Wordings::from(W, Wordings::first_wn(W) + name_length);

@<Issue a problem message for no-such-property@> =
	LOG("Failed property list: pname = <%W>; pval = <%W>\n", PW, VW);
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadPropertyList),
		"this looked to me as if it might be trying to create something "
		"which has certain properties",
		"and that made no sense on investigation. This sometimes happens "
		"if a sentence uses 'with' a little too liberally, or to specify "
		"a never-declared property. For instance, 'An antique is a kind of "
		"thing with an age.' would not be the right way to declare the "
		"property 'age' (because it does not tell Inform what kind of "
		"value this would be). Instead, try 'An antique is a kind of "
		"thing. An antique has a number called age.' It would then be all "
		"right to say 'The Louis Quinze chair is an antique with age 241.'");
	return NULL;

@ An |ADJECTIVE_NT| node, on the other hand, is annotated with a valid
property name |property| already, and may also have a value ready to put
into that property, stored in |evaluation|. Nodes like this have been
created from descriptions like "open openable door in the kitchen", and
it's important not to lose the location information ("in the kitchen"),
which is by now inside the "creation proposition".

@<Conjoin atoms to assert from an adjective node@> =
	int negate_me = FALSE;
	unary_predicate *pred = Node::get_predicate(p);
	if (pred == NULL) internal_error("adjective without predicate");
	if (UnaryPredicates::get_parity(pred) == FALSE) negate_me = TRUE;
	if (Node::get_creation_proposition(p))
		prop = Calculus::Propositions::conjoin(prop, Node::get_creation_proposition(p));
	pcalc_prop *adj_prop = Atoms::from_adjective_on_x(
		UnaryPredicates::get_adj(pred), FALSE);
	if (negate_me) adj_prop = Calculus::Propositions::negate(adj_prop);
	prop = Calculus::Propositions::conjoin(prop, adj_prop);
