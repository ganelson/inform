[Calculus::Equality::] The Equality Relation.

To define that prince among predicates, the equality relation.

@h Definitions.

@ This predicate expresses the meaning of $a=b$, and plays a very special role
in our calculus.

= (early code)
binary_predicate *R_equality = NULL;
binary_predicate *a_has_b_predicate = NULL;

@h Initial stock.
This relation is hard-wired in, and it is made in a slightly special way
since (alone among binary predicates) it has no distinct reversal.

=
void Calculus::Equality::REL_create_initial_stock(void) {
	R_equality = BinaryPredicates::make_equality();
	BinaryPredicates::set_index_details(R_equality, "value", "value");

	word_assemblage wa = Preform::Nonparsing::merge(<relation-name-formal>, 0,
			Preform::Nonparsing::wording(<relation-names>, EQUALITY_RELATION_NAME));
	wording AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_binary_predicate(R_equality));

	#ifndef IF_MODULE
	a_has_b_predicate =
		BinaryPredicates::make_pair(SPATIAL_KBP,
			BinaryPredicates::full_new_term(NULL, NULL, EMPTY_WORDING, NULL),
			BinaryPredicates::new_term(NULL),
			I"has", I"is-had-by",
			NULL, NULL, NULL,
			Preform::Nonparsing::wording(<relation-names>, POSSESSION_RELATION_NAME));
	#endif
}

@h Second stock.
There is none, of course.

=
void Calculus::Equality::REL_create_second_stock(void) {
}

@h Typechecking.
This is a very polymorphic relation, in that it can accept terms of almost
any kind.

=
int Calculus::Equality::REL_typecheck(binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	LOGIF(MATCHING, "Typecheck $u '==' $u\n", kinds_of_terms[0], kinds_of_terms[1]);
	if ((Kinds::Compare::eq(kinds_of_terms[0], K_understanding)) &&
			(Kinds::Compare::eq(kinds_of_terms[1], K_text))) {
			LOGIF(MATCHING, "No!\n");
		Problems::Issue::tcp_problem(_p_(PM_TextIsNotTopic), tck,
			"though they look the same, because both are written in double "
			"quotes, text values can't in fact be used as topics, so it's "
			"impossible to store this piece of text in that location.");
		return NEVER_MATCH;
	}


	if (Plugins::Call::typecheck_equality(kinds_of_terms[0], kinds_of_terms[1]))
		return ALWAYS_MATCH;
	if ((Kinds::Compare::le(kinds_of_terms[0], K_object)) &&
		(Properties::Conditions::name_can_coincide_with_property(kinds_of_terms[1])))
		@<Apply rule for "is" applied to an object and a value@>
	else if ((Kinds::Compare::eq(kinds_of_terms[1], K_understanding)) &&
			(Kinds::Compare::eq(kinds_of_terms[0], K_snippet)))
		return ALWAYS_MATCH;
	else if ((Kinds::Compare::eq(kinds_of_terms[0], K_understanding)) &&
			(Kinds::Compare::eq(kinds_of_terms[1], K_snippet)))
		return ALWAYS_MATCH;
	else if ((Kinds::Compare::eq(kinds_of_terms[1], K_text)) &&
			(Kinds::Compare::eq(kinds_of_terms[0], K_response)))
		return ALWAYS_MATCH;
	else
		@<Allow comparison only where left domain and right domain are not disjoint@>;
	return ALWAYS_MATCH;
}

@ This case is only separated in order to provide a better problem message
for a fairly common mistake:

@<Apply rule for "is" applied to an object and a value@> =
	property *prn = Properties::Conditions::get_coinciding_property(kinds_of_terms[1]);
	if (prn == NULL) {
		if (tck->log_to_I6_text)
			LOG("Comparison of object with $u value\n", kinds_of_terms[1]);
		Problems::quote_kind(4, kinds_of_terms[1]);
		Problems::Issue::tcp_problem(_p_(PM_NonPropertyCompared), tck,
			"taken literally that says that an object is the same as a "
			"value. Maybe you intended to say that the object "
			"has a property - but right now %4 is not yet a property; if you "
			"want to use it as one, you'll need to say so. (You can turn a "
			"kind of value - say, 'colour' - into a property by writing - "
			"say - 'A thing has a colour.')");
		return NEVER_MATCH;
	}

@ With comparisons there is no restriction on the two kinds except that they
must match each other; ${\it is}(t, s)$ is allowed if $K(t)\subseteq K(s)$ or
vice versa. So rules and rulebooks are comparable, for instance, but numbers
and scenes are not.

@<Allow comparison only where left domain and right domain are not disjoint@> =
	if (Calculus::Equality::both_terms_of_same_construction(kinds_of_terms[0], kinds_of_terms[1], CON_rule))
		return ALWAYS_MATCH;
	if (Calculus::Equality::both_terms_of_same_construction(kinds_of_terms[0], kinds_of_terms[1], CON_rulebook))
		return ALWAYS_MATCH;
	if (Calculus::Equality::both_terms_of_same_construction(kinds_of_terms[0], kinds_of_terms[1], CON_activity))
		return ALWAYS_MATCH;
	if ((Kinds::Compare::compatible(kinds_of_terms[0], kinds_of_terms[1]) == NEVER_MATCH) &&
		(Kinds::Compare::compatible(kinds_of_terms[1], kinds_of_terms[0]) == NEVER_MATCH)) {
		if (tck->log_to_I6_text)
			LOG("Unable to compare $u with $u\n", kinds_of_terms[0], kinds_of_terms[1]);
		return NEVER_MATCH_SAYING_WHY_NOT;
	}

@ =
int Calculus::Equality::both_terms_of_same_construction(kind *k0, kind *k1, kind_constructor *cons) {
	if ((Kinds::get_construct(k0) == cons) && (Kinds::get_construct(k1) == cons))
		return TRUE;
	return FALSE;
}

@h Assertion.
In general values differ, and cannot be equated by fiat. But an exception is
setting a global variable.

=
int Calculus::Equality::REL_assert(binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	if (Lvalues::is_actual_NONLOCAL_VARIABLE(spec0)) {
		nonlocal_variable *q = ParseTree::get_constant_nonlocal_variable(spec0);
		int allowed = TRUE;
		if ((prevailing_mood != UNKNOWN_CE) && (prevailing_mood != LIKELY_CE))
			allowed = FALSE;
		if ((NonlocalVariables::is_constant(q)) && (prevailing_mood == CERTAIN_CE))
			allowed = TRUE;
		if (allowed == FALSE)
			Problems::Issue::sentence_problem(_p_(PM_CantQualifyVariableValues),
				"a variable can only be given its value straightforwardly or "
				"qualified by 'usually'",
				"not with 'always', 'seldom' or 'never'.");
		else World::Inferences::draw_property(
			NonlocalVariables::get_knowledge(q), P_variable_initial_value, spec1);
		return TRUE;
	}
	return FALSE;
}

@h Compilation.
Since we are compiling to I6, which is itself a C-level programming
language, it looks at first as if we can compile is into |==| when
testing equality and |=| when asserting it: thus

>> now the score is 10;
>> if the score is 10, ...

would compile to |score = 10;| and |if (score == 10) ...| respectively.

But there are three problems with this simplistic approach to "A is B".

(a) Sometimes "now A is B" must set a property of A, which does not
change, rather than making A equal to B; and similarly for testing.
(b) Sometimes A is reference to a value stored in some data structure
other than a local or global variable: for example, in "now entry 3 of
the passenger list is 208", where A is "entry 3 of the passenger list".
Access to this value is via I6 routines in the template, and the form of
what we compile has to be different depending on whether we are reading
or writing.
(c) Sometimes the values in question are block values, that is, they are
stored as pointers to blocks of data on the heap at run-time. If we compile
"now T is X", where T is a text variable and X is some piece of text, we
cannot simply copy the pointers: T needs to hold a fresh, independent copy of
the text referred to by X.

Problem (a) is easily detected by looking at the kinds of value of A and B.
To handle problems (b) and (c), we use a general framework in which the
schema is a function of both the storage class of A and the kinds of value
of both A and B.

=
int Calculus::Equality::REL_compile(int task, binary_predicate *bp, annotated_i6_schema *asch) {
	kind *st[2];
	st[0] = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt0);
	st[1] = Calculus::Deferrals::Cinders::kind_of_value_of_term(asch->pt1);

	if ((Kinds::Compare::le(st[0], K_object)) &&
		(Properties::Conditions::name_can_coincide_with_property(st[1])) && (Properties::Conditions::get_coinciding_property(st[1])))
		@<Handle the case of setting a property of A separately@>;

	if ((Kinds::Compare::eq(st[0], K_response)) && (Kinds::Compare::eq(st[1], K_text)))
		@<Handle the case of setting a response separately@>;

	switch (task) {
		case TEST_ATOM_TASK:
			if ((st[0]) && (st[1]))
				Calculus::Schemas::modify(asch->schema, "%S",
					Kinds::RunTime::interpret_test_equality(st[0], st[1]));
			else if (problem_count == 0) {
				LOG("$0 and $0; $u and $u\n", &(asch->pt0), &(asch->pt1), st[0], st[1]);
				Problems::Issue::sentence_problem(_p_(PM_CantCompareValues),
					"that would involve comparing things which don't mean "
					"anything to me",
					"so I'm lost.");
			}
			return TRUE;
		case NOW_ATOM_FALSE_TASK:
			break;
		case NOW_ATOM_TRUE_TASK: {
			node_type_t storage_class = Lvalues::get_storage_form(asch->pt0.constant);
			if ((storage_class == UNKNOWN_NT) &&
				(Kinds::get_construct(st[0]) == CON_property))
				storage_class = PROPERTY_VALUE_NT;
			if (Plugins::Call::forbid_setting(asch->pt1.term_checked_as_kind)) {
				asch->schema = NULL;
				return TRUE;
			}
			@<Make a further check that kinds permit this assignment@>;
			if (storage_class == UNKNOWN_NT) {
				@<Issue problem message for being unable to set equal@>
				asch->schema = NULL;
			} else {
				@<Exceptional case of setting the "player" global variable@>;
				Calculus::Schemas::modify(asch->schema, "%s",
					Lvalues::interpret_store(storage_class, st[0], st[1], 0));
				@<Add kind-checking code for run-time checking@>;
			}
			return TRUE;
		}
	}
	return FALSE;
}

@ So here is the exceptional case (a) mentioned above. Suppose we have:

>> if the lantern is bright, ...

where "bright" is one value of "luminance", which is both a kind of value
and also a property. We then want to test if the luminance property of the
lantern equals the constant value "bright"; and similarly for "now the
lantern is bright".

@<Handle the case of setting a property of A separately@> =
	property *prn = Properties::Conditions::get_coinciding_property(st[1]);
	switch (task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "*1.%n == *2", Properties::iname(prn));
			return TRUE;
		case NOW_ATOM_FALSE_TASK:
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema, "*1.%n = *2", Properties::iname(prn));
			return TRUE;
	}
	return FALSE;

@<Handle the case of setting a response separately@> =
	switch (task) {
		case TEST_ATOM_TASK:
			Problems::Issue::sentence_problem(_p_(PM_ResponseComparisonUnsafe),
				"for complicated internal reasons this comparison isn't safe to perform",
				"and might give you a falsely negative result. To avoid what might "
				"be misleading, you aren't allowed to compare a response to text.");
			break;
		case NOW_ATOM_FALSE_TASK:
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema, "BlkValueCopy(ResponseTexts-->((*1)-1), *^2)");
			return TRUE;
	}
	return FALSE;

@ A little bit of support within Inform to help the template layer.

@<Exceptional case of setting the "player" global variable@> =
	nonlocal_variable *nlv =
		Lvalues::get_nonlocal_variable_if_any(asch->pt0.constant);
	if ((nlv) && (NonlocalVariables::must_be_constant(nlv))) {
		asch->schema = NULL;
		return TRUE;
	}
	char *exotica = NonlocalVariables::get_write_schema(nlv);
	if (exotica) {
		Calculus::Schemas::modify(asch->schema, "%s", exotica);
		return TRUE;
	}

@<Make a further check that kinds permit this assignment@> =
	if (Kinds::Compare::compatible(st[1], st[0]) == NEVER_MATCH) {
		kind *dst[2];
		dst[0] = Kinds::dereference_properties(st[0]);
		dst[1] = Kinds::dereference_properties(st[1]);
		if (Kinds::Compare::compatible(dst[1], dst[0]) == NEVER_MATCH) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind(2, st[1]);
			Problems::quote_kind(3, st[0]);
			Problems::Issue::handmade_problem(_p_(BelievedImpossible));
			Problems::issue_problem_segment(
				"In the line %1, you seem to be asking me to put %2 into %3, "
				"which can't safely be done.");
			Problems::issue_problem_end();
			asch->schema = NULL;
			return TRUE;
		}
	}

@ Rather than just returning |FALSE| for a generic problem message, we issue
one that's more helpfully specific and return |TRUE|.

@<Issue problem message for being unable to set equal@> =
	if (Rvalues::to_instance(asch->pt0.constant)) {
		if (Kinds::Compare::le(Specifications::to_kind(asch->pt0.constant), K_object))
			Problems::Issue::sentence_problem(_p_(PM_CantEquateValues),
				"equality is not something I can change",
				"so either those are already the same or are different, and I "
				"can't alter matters.");
		else
			Problems::Issue::sentence_problem(_p_(PM_CantChangeNamedConstant),
				"I can't change that",
				"because it is a name for a constant value. Some named values, "
				"like 'the score', can be changed, because they were defined "
				"as values that vary. But others are fixed. If we write 'The "
				"oak tree can be sturdy, lightning-struck or leaning.', for "
				"instance, then 'sturdy' is a name for a value which is fixed, "
				"just as the number '7' is fixed.");
	}

@<Add kind-checking code for run-time checking@> =
	if ((Kinds::Compare::compatible(st[1], st[0]) == SOMETIMES_MATCH) &&
		(Kinds::Compare::lt(st[0], K_object))) {
		TEMPORARY_TEXT(TEMP);
		WRITE_TO(TEMP,
			"; if (~~(*1 ofclass %n)) RunTimeProblem(RTP_WRONGASSIGNEDKIND, *1, \"*?\", \"",
			Kinds::RunTime::I6_classname(st[0]));
		Kinds::Textual::write(TEMP, st[0]);
		WRITE_TO(TEMP, "\");");
		Calculus::Schemas::append(asch->schema, "%S", TEMP);
		DISCARD_TEXT(TEMP);
	}

@h Problem message text.

=
int Calculus::Equality::REL_describe_for_problems(OUTPUT_STREAM, binary_predicate *bp) {
	return FALSE;
}
