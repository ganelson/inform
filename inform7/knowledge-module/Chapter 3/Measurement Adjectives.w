[MeasurementAdjectives::] Measurement Adjectives.

The family of adjectives arising from property value comparisons.

@ We must define:

=
adjective_meaning_family *measurement_amf = NULL;

void MeasurementAdjectives::start(void) {
	measurement_amf = AdjectiveMeanings::new_family(3);
	METHOD_ADD(measurement_amf, ASSERT_ADJM_MTID,
		MeasurementAdjectives::assert);
	METHOD_ADD(measurement_amf, PREPARE_SCHEMAS_ADJM_MTID,
		MeasurementAdjectives::prepare_schemas);
	METHOD_ADD(measurement_amf, CLAIM_DEFINITION_SENTENCE_ADJM_MTID,
		MeasurementAdjectives::claim_definition);
}

@ Measurement adjectives are created when we parse a "Definition:" clause for
a new adjective, and then only when the definition has a particular form:

>> Definition: A container is roomy if its carrying capacity is 10 or more.

<measurement-adjective-definition> is used to parse the definition part,

>> its carrying capacity is 10 or more

The following grammar is a little sketchy because it's parsed very early in
Inform's run; stricter rules eventually apply to all those ellipses.

=
<measurement-adjective-definition> ::=
	<possessive-third-person> ... is/are not ... |    ==> @<Issue PM_GradingMisphrased problem@>
	<possessive-third-person> {<property-name>} is/are <measurement-range> | ==> { R[3], RP[2] }
	<possessive-third-person> ... is/are <measurement-range>                 ==> { R[2], NULL }

<measurement-range> ::=
	... or more |    ==> { MEASURE_T_OR_MORE, - }
	... or less |    ==> { MEASURE_T_OR_LESS, - }
	...              ==> { MEASURE_T_EXACTLY, - }

@<Issue PM_GradingMisphrased problem@> =
	StandardProblems::definition_problem(Task::syntax_tree(), _p_(PM_GradingMisphrased),
		Diagrams::new_UNPARSED_NOUN(W),
		"that definition is wrongly phrased",
		"assuming it was meant to be a grading adjective like 'Definition: a "
		"container is large if its carrying capacity is 10 or more.'");
	return FALSE;


@ So, then, we look at a Definition and see if we want to claim it as a
measurement.

=
int MeasurementAdjectives::claim_definition(adjective_meaning_family *f,
	adjective_meaning **result, parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	if (sense == 0) return FALSE;

	if (<measurement-adjective-definition>(CONW) == FALSE) return FALSE;
	int shape = <<r>>;
	wording PRW = GET_RW(<measurement-adjective-definition>, 1);
	wording THRESW = GET_RW(<measurement-range>, 1);
	property *prop = <<rp>>;

	@<Reject some overly elaborate attempts to define overly elaborate measurements@>;
	@<Allow an exact measurement to be created only if we can already parse the threshold@>;

	measurement_definition *mdef = Measurements::new(q, AW, THRESW, prop, shape, PRW);
	if (shape != MEASURE_T_EXACTLY) @<Create the superlative form@>;
	@<Create the adjectival meaning arising from this measurement@>;
	*result = mdef->headword_as_adjective;
	return TRUE;
}

@<Reject some overly elaborate attempts to define overly elaborate measurements@> =
	if (Wordings::length(AW) > 1) {
		if (shape != MEASURE_T_EXACTLY)
			StandardProblems::definition_problem(Task::syntax_tree(),
				_p_(PM_MultiwordGrading),
				q, "a grading adjective must be a single word",
				"as in 'Definition: a container is large if its carrying capacity is "
				"10 or more.': 'fairly large' would not be allowed because it would "
				"make no sense to talk about 'fairly larger' or 'fairly largest'.");
		return FALSE;
	}

	if (Wordings::nonempty(CALLW)) {
		if (shape != MEASURE_T_EXACTLY)
			StandardProblems::definition_problem(Task::syntax_tree(),
				_p_(PM_GradingCalled),
				q, "callings are not allowed when defining grading adjectives",
				"so 'Definition: a container is large if its carrying capacity is 10 "
				"or more.' is fine, but so 'Definition: a container (called the bag) "
				"is large if its carrying capacity is 10 or more.' is not - then again, "
				"there's very little call for it.");
		return FALSE;
	}

	if (sense != 1) {
		if (shape != MEASURE_T_EXACTLY)
			StandardProblems::definition_problem(Task::syntax_tree(),
				_p_(PM_GradingUnless),
				q, "'unless' is not allowed when defining grading adjectives",
				"so 'Definition: a container is large if its carrying capacity is 10 "
				"or more.' is fine, but so 'Definition: a container is modest unless "
				"its carrying capacity is 10 or more.' is not - of course a similar "
				"effect could be achieved by 'Definition: a container is modest if its "
				"carrying capacity is 9 or less.'");
		return FALSE;
	}

@ Perhaps this is a good point to say why we allow any exact measurements at
all. After all, if we didn't, a definition like:

>> Definition: a person is handy if his carrying capacity is 7.

...would still work; and "handy" would then be created as a |condition_amf|
adjective. So why not let that happen?

The answer is that our |measurement_amf| adjectives behave exactly the same
at run-time, but can also be asserted true in the model world at compile-time.
In particular, we could write:

>> Peter is a handy person.

This can't be done with general |condition_amf| adjectives, because conditions
can't normally be unravelled at compile time.

@<Allow an exact measurement to be created only if we can already parse the threshold@> =
	if (shape == MEASURE_T_EXACTLY) {
		if (<s-literal>(THRESW) == FALSE) return FALSE;
	}

@<Create the superlative form@> =
	mdef->superlative =
		Grading::make_superlative(mdef->headword, Task::language_of_syntax());
	@<Feed the preamble for the superlative phrase into the lexer@>;
	@<Feed the body of the superlative phrase into the lexer@>;
	RuleSubtrees::register_recently_lexed_phrases();

@<Feed the preamble for the superlative phrase into the lexer@> =
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, " To decide which object is %N ( S - description of objects ) ",
		Wordings::first_wn(mdef->superlative));
	Sentences::make_node(Task::syntax_tree(),
		Feeds::feed_text(TEMP),
		':');
	DISCARD_TEXT(TEMP)

@<Feed the body of the superlative phrase into the lexer@> =
	TEMPORARY_TEXT(TEMP)
	WRITE_TO(TEMP, " (- {-primitive-definition:extremal%s%W}  -) ",
		Measurements::strict_comparison(mdef->region_shape),
		mdef->name_of_property_to_compare);
	Sentences::make_node(Task::syntax_tree(), Feeds::feed_text(TEMP), '.');
	DISCARD_TEXT(TEMP)

@<Create the adjectival meaning arising from this measurement@> =
	adjective_meaning *am = AdjectiveMeanings::new(measurement_amf,
		STORE_POINTER_measurement_definition(mdef), Node::get_text(q));
	mdef->headword_as_adjective = am;
	adjective *adj = Adjectives::declare(AW, NULL);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeanings::perform_task_via_function(am, TEST_ATOM_TASK);
	AdjectiveMeaningDomains::set_from_text(am, DNW);

@h Assert.

=
int MeasurementAdjectives::assert(adjective_meaning_family *f,
	adjective_meaning *am, inference_subject *infs_to_assert_on, int parity) {
	measurement_definition *mdef =
		RETRIEVE_POINTER_measurement_definition(am->family_specific_data);
	Measurements::validate(mdef);
	if ((Measurements::is_valid(mdef)) && (mdef->prop) && (parity == TRUE)) {
		parse_node *val = NULL;
		if (<s-literal>(mdef->region_threshold_text)) val = <<rp>>;
		else internal_error("literal unreadable");
		PropertyInferences::draw(infs_to_assert_on, mdef->prop, val);
		return TRUE;
	}
	return FALSE;
}

@h Schemas.

=
void MeasurementAdjectives::prepare_schemas(adjective_meaning_family *family,
	adjective_meaning *am, int T) {
	measurement_definition *mdef =
		RETRIEVE_POINTER_measurement_definition(am->family_specific_data);
	if ((mdef->prop) && (mdef->region_threshold_evaluated))
		RTMeasurements::make_test_schema(mdef, T);
}
