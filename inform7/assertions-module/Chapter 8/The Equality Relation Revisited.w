[EqualityDetails::] The Equality Relation Revisited.

To define how equality behaves in the Inform language.

@h Additional details.

=
void EqualityDetails::start(void) {
	METHOD_ADD(equality_bp_family, TYPECHECK_BPF_MTID, EqualityDetails::typecheck);
	METHOD_ADD(equality_bp_family, ASSERT_BPF_MTID, EqualityDetails::assert);
	METHOD_ADD(equality_bp_family, SCHEMA_BPF_MTID, EqualityDetails::schema);

	METHOD_ADD(empty_bp_family, TYPECHECK_BPF_MTID, EqualityDetails::typecheck_empty);
	METHOD_ADD(empty_bp_family, ASSERT_BPF_MTID, EqualityDetails::assert_empty);
	METHOD_ADD(empty_bp_family, SCHEMA_BPF_MTID, EqualityDetails::schema_empty);
}

@h Typechecking.
This is a very polymorphic relation, in that it can accept terms of almost
any kind.

=
int EqualityDetails::typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	LOGIF(MATCHING, "Typecheck %u '==' %u\n", kinds_of_terms[0], kinds_of_terms[1]);
	if ((K_understanding) && (Kinds::eq(kinds_of_terms[0], K_understanding)) &&
			(Kinds::eq(kinds_of_terms[1], K_text))) {
			LOGIF(MATCHING, "No!\n");
		StandardProblems::tcp_problem(_p_(PM_TextIsNotTopic), tck,
			"though they look the same, because both are written in double "
			"quotes, text values can't in fact be used as topics, so it's "
			"impossible to store this piece of text in that location.");
		return NEVER_MATCH;
	}

	if (PluginCalls::typecheck_equality(kinds_of_terms[0], kinds_of_terms[1]))
		return ALWAYS_MATCH;
	if ((Kinds::Behaviour::is_object(kinds_of_terms[0])) &&
		(Properties::can_name_coincide_with_kind(kinds_of_terms[1])))
		@<Apply rule for "is" applied to an object and a value@>
	else if ((K_understanding) && (Kinds::eq(kinds_of_terms[1], K_understanding)) &&
			(Kinds::eq(kinds_of_terms[0], K_snippet)))
		return ALWAYS_MATCH;
	else if ((K_understanding) && (Kinds::eq(kinds_of_terms[0], K_understanding)) &&
			(Kinds::eq(kinds_of_terms[1], K_snippet)))
		return ALWAYS_MATCH;
	else if ((Kinds::eq(kinds_of_terms[1], K_text)) &&
			(Kinds::eq(kinds_of_terms[0], K_response)))
		return ALWAYS_MATCH;
	else
		@<Allow comparison only where left domain and right domain are not disjoint@>;
	return ALWAYS_MATCH;
}

@ This case is only separated in order to provide a better problem message
for a fairly common mistake:

@<Apply rule for "is" applied to an object and a value@> =
	property *prn = Properties::property_with_same_name_as(kinds_of_terms[1]);
	if (prn == NULL) {
		if (tck->log_to_I6_text)
			LOG("Comparison of object with %u value\n", kinds_of_terms[1]);
		Problems::quote_kind(4, kinds_of_terms[1]);
		StandardProblems::tcp_problem(_p_(PM_NonPropertyCompared), tck,
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
	if (EqualityDetails::both_terms_of_same_construction(kinds_of_terms[0], kinds_of_terms[1], CON_rule))
		return ALWAYS_MATCH;
	if (EqualityDetails::both_terms_of_same_construction(kinds_of_terms[0], kinds_of_terms[1], CON_rulebook))
		return ALWAYS_MATCH;
	if (EqualityDetails::both_terms_of_same_construction(kinds_of_terms[0], kinds_of_terms[1], CON_activity))
		return ALWAYS_MATCH;
	if ((Kinds::compatible(kinds_of_terms[0], kinds_of_terms[1]) == NEVER_MATCH) &&
		(Kinds::compatible(kinds_of_terms[1], kinds_of_terms[0]) == NEVER_MATCH)) {
		if (tck->log_to_I6_text)
			LOG("Unable to compare %u with %u\n", kinds_of_terms[0], kinds_of_terms[1]);
		return NEVER_MATCH_SAYING_WHY_NOT;
	}

@ =
int EqualityDetails::both_terms_of_same_construction(kind *k0, kind *k1, kind_constructor *cons) {
	if ((Kinds::get_construct(k0) == cons) && (Kinds::get_construct(k1) == cons))
		return TRUE;
	return FALSE;
}

@ The never-holding relation is simpler: anything can be hypothetically related to
anything else (except of course that it always is not).

=
int EqualityDetails::typecheck_empty(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	return ALWAYS_MATCH;
}

@h Assertion.
In general values differ, and cannot be equated by fiat. But an exception is
setting a global variable.

=
int EqualityDetails::assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	if (Lvalues::is_actual_NONLOCAL_VARIABLE(spec0)) {
		nonlocal_variable *q = Node::get_constant_nonlocal_variable(spec0);
		int allowed = TRUE;
		if ((prevailing_mood != UNKNOWN_CE) && (prevailing_mood != LIKELY_CE))
			allowed = FALSE;
		if ((NonlocalVariables::is_constant(q)) && (prevailing_mood == CERTAIN_CE))
			allowed = TRUE;
		if (allowed == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantQualifyVariableValues),
				"a variable can only be given its value straightforwardly or "
				"qualified by 'usually'",
				"not with 'always', 'seldom' or 'never'.");
		else PropertyInferences::draw(
			NonlocalVariables::to_subject(q), P_variable_initial_value, spec1);
		return TRUE;
	}
	return FALSE;
}

@ The never-holding relation cannot be asserted true:

=
int EqualityDetails::assert_empty(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
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
int EqualityDetails::schema(bp_family *self, int task, binary_predicate *bp, annotated_i6_schema *asch) {
	kind *st[2];
	st[0] = Cinders::kind_of_term(asch->pt0);
	st[1] = Cinders::kind_of_term(asch->pt1);

	if ((Kinds::Behaviour::is_object(st[0])) &&
		(Properties::can_name_coincide_with_kind(st[1])) && (Properties::property_with_same_name_as(st[1])))
		@<Handle the case of setting a property of A separately@>;

	if ((Kinds::eq(st[0], K_response)) && (Kinds::eq(st[1], K_text)))
		@<Handle the case of setting a response separately@>;

	switch (task) {
		case TEST_ATOM_TASK:
			if ((st[0]) && (st[1]))
				Calculus::Schemas::modify(asch->schema, "%S",
					EqualitySchemas::interpret_equality(st[0], st[1]));
			else if (problem_count == 0) {
				LOG("$0 and $0; %u and %u\n", &(asch->pt0), &(asch->pt1), st[0], st[1]);
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
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
			@<Make a further check that kinds permit this assignment@>;
			if (storage_class == UNKNOWN_NT) {
				@<Issue problem message for being unable to set equal@>
				asch->schema = NULL;
			} else {
				@<Exceptional case of setting the "player" global variable@>;
				TEMPORARY_TEXT(prototype)
				CompileLvalues::interpret_store(prototype, storage_class, st[0], st[1], 0);
				Calculus::Schemas::modify(asch->schema, "%S", prototype);
				DISCARD_TEXT(prototype)
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
	property *prn = Properties::property_with_same_name_as(st[1]);
	switch (task) {
		case TEST_ATOM_TASK:
			Calculus::Schemas::modify(asch->schema, "*1.%n == *2", RTProperties::iname(prn));
			return TRUE;
		case NOW_ATOM_FALSE_TASK:
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema, "*1.%n = *2", RTProperties::iname(prn));
			return TRUE;
	}
	return FALSE;

@<Handle the case of setting a response separately@> =
	switch (task) {
		case TEST_ATOM_TASK:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ResponseComparisonUnsafe),
				"for complicated internal reasons this comparison isn't safe to perform",
				"and might give you a falsely negative result. To avoid what might "
				"be misleading, you aren't allowed to compare a response to text.");
			break;
		case NOW_ATOM_FALSE_TASK:
			break;
		case NOW_ATOM_TRUE_TASK:
			Calculus::Schemas::modify(asch->schema, "CopyPV(ResponseTexts-->((*1)-1), *^2)");
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
	NonlocalVariables::warn_about_change(nlv);
	text_stream *exotica = RTVariables::get_write_schema(nlv);
	if (exotica) {
		Calculus::Schemas::modify(asch->schema, "%S", exotica);
		return TRUE;
	}

@<Make a further check that kinds permit this assignment@> =
	if (Kinds::compatible(st[1], st[0]) == NEVER_MATCH) {
		kind *dst[2];
		dst[0] = Kinds::dereference_properties(st[0]);
		dst[1] = Kinds::dereference_properties(st[1]);
		if (Kinds::compatible(dst[1], dst[0]) == NEVER_MATCH) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind(2, st[1]);
			Problems::quote_kind(3, st[0]);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
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
		if (Kinds::Behaviour::is_object(Specifications::to_kind(asch->pt0.constant)))
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantEquateValues),
				"equality is not something I can change",
				"so either those are already the same or are different, and I "
				"can't alter matters.");
		else
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantChangeNamedConstant),
				"I can't change that",
				"because it is a name for a constant value. Some named values, "
				"like 'the score', can be changed, because they were defined "
				"as values that vary. But others are fixed. If we write 'The "
				"oak tree can be sturdy, lightning-struck or leaning.', for "
				"instance, then 'sturdy' is a name for a value which is fixed, "
				"just as the number '7' is fixed.");
	}

@<Add kind-checking code for run-time checking@> =
	if ((Kinds::compatible(st[1], st[0]) == SOMETIMES_MATCH) &&
		(Kinds::Behaviour::is_subkind_of_object(st[0]))) {
		TEMPORARY_TEXT(TEMP)
		WRITE_TO(TEMP,
			"; if (~~(*1 ofclass %n)) IssueSetVariableRTP(*1, \"*?\", \"",
			RTKindDeclarations::iname(st[0]));
		Kinds::Textual::write(TEMP, st[0]);
		WRITE_TO(TEMP, "\");");
		Calculus::Schemas::append(asch->schema, "%S", TEMP);
		DISCARD_TEXT(TEMP)
	}

@ This never holds and there is nothing to compile:

=
int EqualityDetails::schema_empty(bp_family *self, int task, binary_predicate *bp,
	annotated_i6_schema *asch) {
	return FALSE;
}
