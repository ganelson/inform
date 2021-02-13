[Assertions::Implications::] Implications.

To keep track of a dangerous form of super-assertion called an
implication, which is allowed to generalise about properties.

@h Creation.
Implications are structures are used to store the information in sentences
like "Something worn is usually wearable and initially carried." The
"something worn" part must turn out to be a description of a category of
objects; the "usually" part translates into a level of certainty. We regard
these as implications in the sense of IF condition A, THEN condition B, but
note that A is quite restricted in what it can be: it must be a simple-to-test
description only, whereas B could be any subtree of an assertion.

=
typedef struct implication {
	struct pcalc_prop *if_spec; /* which objects are affected */
	struct parse_node *then_pn; /* what assertion is implied about them */
	int implied_likelihood; /* with what certainty level */
	struct implication *next_implication; /* in list of implications */
	CLASS_DEFINITION
} implication;

@ We also need a little piece of storage attached to each property name:

=
typedef struct possession_marker {
	int possessed; /* temporary use when checking implications about objects */
	int possession_certainty; /* ditto */
} possession_marker;

@ Implications are gathered during the main parse tree traverses, but all we do
is to store them and sit on them.

=
void Assertions::Implications::new(parse_node *px, parse_node *py) {
	if (prevailing_mood == CERTAIN_CE) @<Reject implications given with certainty@>;
	if (Node::get_type(py) == AND_NT) {
		Assertions::Implications::new(px, py->down);
		Assertions::Implications::new(px, py->down->next);
		return;
	}
	@<Actually create a single implication@>;
}

@<Reject implications given with certainty@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ImplicationCertain),
		"that's an implication which is too certain for me",
		"since a sentence like this talks about a generality of things in terms of "
		"one either/or property implying another, and I can only handle those as "
		"likelihoods. You should probably add 'usually' somewhere: e.g., 'An open "
		"door is usually openable'. (But implications can have unpredictable "
		"consequences: best to avoid them altogether where possible.)");
	return;

@<Actually create a single implication@> =
	inference_subject *premiss_kind = NULL;
	pcalc_prop *premiss = NULL;
	@<Find the premiss kind and specification@>;
	@<Check that the premiss involves only either/or properties and/or a kind@>;
	@<Check that the conclusion involves only a single either/or property@>;

	implication *imp = CREATE(implication);
	imp->if_spec = premiss;
	imp->then_pn = py;
	imp->implied_likelihood = prevailing_mood;

	imp->next_implication = InferenceSubjects::get_implications(premiss_kind);
	InferenceSubjects::set_implications(premiss_kind, imp);

	LOGIF(IMPLICATIONS, "Forming implication for $j: $D implies\n  $T",
		premiss_kind, imp->if_spec, imp->then_pn);

@<Find the premiss kind and specification@> =
	parse_node *loc = px;
	if (Node::get_type(loc) == WITH_NT) loc = loc->down;
	premiss_kind = Node::get_subject(loc);
	premiss = Node::get_creation_proposition(loc);
	#ifdef IF_MODULE
	if (premiss_kind == NULL) premiss_kind = KindSubjects::from_kind(K_thing);
	#endif
	#ifndef IF_MODULE
	if (premiss_kind == NULL) premiss_kind = KindSubjects::from_kind(K_object);
	#endif

@<Check that the premiss involves only either/or properties and/or a kind@> =
	if (Assert::testable_at_compile_time(premiss) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadImplicationDomain),
			"that's an implication where the condition to qualify is not "
			"one that I can determine in advance of the start of play",
			"since it involves more than simple either/or properties "
			"plus a kind. (For example, adjectives like 'adjacent' or "
			"'visible' here are too difficult to determine.)");
		return;
	}

@<Check that the conclusion involves only a single either/or property@> =
	unary_predicate *pred = Node::get_predicate(py);
	property *prn = AdjectiveAmbiguity::has_either_or_property_meaning(AdjectivalPredicates::to_adjective(pred), NULL);
	if (prn == NULL) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ImplicationValueProperty),
			"that's an implication where the outcome is an adjective other than "
			"a simple either/or property",
			"which is the only form of implication I can handle.");
		return;
	}

@h Implication checking.
The checking of implications happens all at once, during model completion,
so that all inferences arising directly from the source text have already
been drawn.

For instance, if there is an inference asserting that object X is worn, and
there is an implication that what is worn is usually also wearable, then we
must generate an inference that X is wearable: in effect, this is a deduction
from a syllogism. We should however not generate such an inference if we
already have definite knowledge that X is not wearable. We do this for each
object X individually.

We begin by checking implications associated with X and applying to X,
but in fact because |Assertions::Implications::check_implications_of| recurses depth-first through
the kinds, a typical object X -- a container, say -- will first have
implications associated with "thing" applied to it, then with
those associated with "container", and only then its own implications.

=
void Assertions::Implications::consider_all(inference_subject *infs) {
	if (KindSubjects::to_kind(infs)) return;
	int ongoing = TRUE;
	while (ongoing) {
		@<Erase all of the possession markers@>;
		Assertions::Implications::set_possessed_flags(infs);
		ongoing = Assertions::Implications::check_implications_of(infs, infs);
	}
}

@ We are going to need to examine which either/or properties are held by X.
We don't want to store all of the properties of everything in memory at once,
so we keep just a single set of "possession markers", one for each property.
Here we erase these markers ready for use with X.

@<Erase all of the possession markers@> =
	property *prn;
	LOOP_OVER(prn, property) {
		possession_marker *pom = Properties::get_possession_marker(prn);
		pom->possessed = FALSE;
		pom->possession_certainty = UNKNOWN_CE;
	}

@ This is the recursive routine which sets the possession markers for X on the
basis of the inferences so far drawn about it.

=
void Assertions::Implications::set_possessed_flags(inference_subject *infs) {
	inference_subject *k = InferenceSubjects::narrowest_broader_subject(infs);
	if (k) Assertions::Implications::set_possessed_flags(k);

	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF) {
		property *prn = World::Inferences::get_property(inf);
		if ((Properties::is_either_or(prn)) && (World::Inferences::get_certainty(inf) != UNKNOWN_CE))
			@<See what we can get out of this inference@>;
	}
}

@ Note that where there are antonyms such as open/closed, we have to mark
both of them, because an inference of being closed is as good as an inference
of not being open, and vice versa.

@<See what we can get out of this inference@> =
	int truth_state = TRUE, certainty = World::Inferences::get_certainty(inf);
	if (certainty < 0) { certainty = -certainty; truth_state = FALSE; }

	possession_marker *pom = Properties::get_possession_marker(prn);
	@<Mark this property if its possession is not already equally certainly known@>;

	if (Properties::EitherOr::get_negation(prn)) {
		prn = Properties::EitherOr::get_negation(prn);
		pom = Properties::get_possession_marker(prn);
		truth_state = (truth_state)?FALSE:TRUE;
		@<Mark this property if its possession is not already equally certainly known@>;
	}

@<Mark this property if its possession is not already equally certainly known@> =
	if (pom->possession_certainty < certainty) {
		pom->possessed = truth_state;
		pom->possession_certainty = certainty;
	}

@ Lastly, then, the routine actually checking and applying implications.
Our aim is to find and act upon the first implication which makes a difference,
and return |TRUE|; but if no implication can be acted on, to return |FALSE|.

This cannot act twice on the same candidate with the same implication, since
the act results in creating inferences about the property. An attempt at
repetition results in redundancy, since the inferences it would make have
no better a certainty level.

=
int Assertions::Implications::check_implications_of(inference_subject *domain,
	inference_subject *candidate) {
	inference_subject *k = InferenceSubjects::narrowest_broader_subject(domain);
	if ((k) && (Assertions::Implications::check_implications_of(k, candidate))) return TRUE;

	if (InferenceSubjects::get_implications(domain))
		LOGIF(IMPLICATIONS, "Considering implications about $j as they apply to $j:\n",
			domain, candidate);

	implication *imp;
	for (imp = InferenceSubjects::get_implications(domain); imp; imp = imp->next_implication)
		@<Consider this individual implication as it applies to the candidate@>;

	return FALSE;
}

@<Consider this individual implication as it applies to the candidate@> =
	unary_predicate *pred = Node::get_predicate(imp->then_pn);
	int conclusion_state = TRUE;
	if (AdjectivalPredicates::parity(pred) == FALSE) conclusion_state = FALSE;
	if (imp->implied_likelihood < 0) conclusion_state = (conclusion_state)?FALSE:TRUE;

	LOGIF(IMPLICATIONS, "$D => $T (certainty %d; changed state %d)\n",
		imp->if_spec, imp->then_pn, imp->implied_likelihood, conclusion_state);

	property *conclusion_prop = AdjectiveAmbiguity::has_either_or_property_meaning(
		AdjectivalPredicates::to_adjective(pred), NULL);
	@<Check that the conclusion is not impossible@>;

	possession_marker *pom = Properties::get_possession_marker(conclusion_prop);
	@<Check that the conclusion is not redundant or irrelevant@>;

	int candidate_qualifies = Assert::test_at_compile_time(imp->if_spec, candidate);

	if (candidate_qualifies) {
		LOGIF(IMPLICATIONS, "PASS: changing property $Y of $j\n", conclusion_prop, candidate);
		@<Apply the conclusion to the candidate@>;
	} else {
		LOGIF(IMPLICATIONS, "FAIL: take no action\n");
	}

@<Check that the conclusion is not impossible@> =
	if ((conclusion_prop == NULL) ||
		(World::Permissions::find(candidate, conclusion_prop, TRUE) == NULL)) {
		LOGIF(IMPLICATIONS, "IMPOSSIBLE: property not provided\n");
		continue;
	}
@<Check that the conclusion is not redundant or irrelevant@> =
	LOGIF(IMPLICATIONS, "Possession marker has (certainty %d; possessed state %d)\n",
		pom->possession_certainty, pom->possessed);
	if (pom->possessed == conclusion_state) {
		LOGIF(IMPLICATIONS, "REDUNDANT: property already correct\n");
		continue;
	}
	if (pom->possession_certainty == CERTAIN_CE) {
		LOGIF(IMPLICATIONS, "IRRELEVANT: property already settled\n");
		continue;
	}

@<Apply the conclusion to the candidate@> =
	adjective *aph = Properties::EitherOr::get_aph(conclusion_prop);
	pcalc_prop *prop = KindPredicates::new_atom(
		KindSubjects::to_kind(domain), Terms::new_variable(0));
	if (conclusion_state == FALSE) {
		prop = Propositions::concatenate(prop, Atoms::new(NEGATION_OPEN_ATOM));
		prop = Propositions::concatenate(prop, AdjectivalPredicates::new_atom_on_x(aph, FALSE));
		prop = Propositions::concatenate(prop, Atoms::new(NEGATION_CLOSE_ATOM));
	} else {
		prop = Propositions::concatenate(prop, AdjectivalPredicates::new_atom_on_x(aph, FALSE));
	}
	Assert::true_about(prop, candidate, CERTAIN_CE);
	return TRUE;
