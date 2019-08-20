[Properties::EitherOr::] Either-Or Properties.

Properties which can either be present or not, but have no value
attached.

@h A design choice.
A property name structure with the either/or flag set represents one which is
true or false. It's not obvious what the best way to handle these properties
would be. A traditional computer-science view would be that a property like
"open" is really just another valued property, whose kind of value is
"truth state" -- that is, "true" or "false". The word "closed" would
then be no property at all, only a sort of syntactic sugar for a particular
way to initialise the "open" property.

But in natural language, there seems no reason why "open" should be somehow
more real than "closed". Source text ought to regard them as linguistically
the same, and might talk about "the closed property" just as readily as
"the open property". It's true that at some low-level implementation level
these two properties, "open" and "closed", are tied together, but
otherwise they ought both to be just as valid.

The language is the same either way, but the compiler has to choose which of
these tacks it will take in implementing either/or properties. The first
approach involves messy higher-level code pretending that certain linguistic
features are properties even when they don't map onto |property|
structures, which is bad; the second approach involves messy lower-level code
coping with the fact that two different |property| structures are somehow
the same, which is also bad. In the end, we went with the second approach (but
about every two years consider stripping it out and rewriting the other way,
just the same).

@ The rule, therefore, is:

(a) If an either/or property has one named form for when it is present and
another for when it is absent, both forms are considered either/or properties.
Each has a |property| structure. We call these a "pair".

(b) Within a pair, the |negation| field of each member points to the other.
Thus it points from the "open" structure to the "closed" one, and vice
versa.

(c) Exactly one member of the pair has |stored_in_negation| set. This one is
the ghostly one not existing at run-time; for example, in the Standard Rules,
"open" is the stored one and "closed" is the ghost, so "closed" has
|stored_in_negation| set.

(d) If an either/or property has no named form for when it is absent, it is
a "singleton" and not a member of any pair. Its |negation| field is |NULL|,
and |stored_in_negation| is clear.

@h Requesting new named properties.
This is how the either/or properties declared by the source text are made.

=
property *Properties::EitherOr::obtain(wording W, inference_subject *infs) {
	if (<k-kind>(W)) {
		Problems::Issue::sentence_problem(_p_(PM_KindAdjectiveClash),
			"this tries to create a new either/or adjective with the same name "
			"as an existing kind",
			"which isn't allowed. For example, 'A hopper can be a container.' is "
			"not allowed because something either is, or is not, a 'container', "
			"and that can never change during play. 'Container' is a kind, and "
			"those are fixed. 'A hopper is a container' would be allowed, because "
			"that makes a definite statement.");
	}
	property *prn = Properties::obtain(W, FALSE);
	prn->either_or = TRUE;
	kind *K = InferenceSubjects::domain(infs);
	if (prn->adjectival_meaning_registered == NULL)
		Properties::EitherOr::create_adjective_from_property(prn, W, K);
	else
		Properties::EitherOr::make_new_adjective_sense_from_property(prn, W, K);
	return prn;
}

@h Requesting new nameless properties.
These are properties needed for implementation reasons by the template, and
which are added to the model by plugins here inside Inform, but which have
no existence at the source text level -- and hence have no names.

Setting them up as adjectives may seem a little over the top, since they cannot
be encountered in source text, but the world model will have to set these properties
by asserting propositions to be true; and type-checking of those propositions
relies on adjectival meanings.

=
property *Properties::EitherOr::new_nameless(wchar_t *I6_form) {
	wording W = Feeds::feed_text(I6_form);
	package_request *R = Hierarchy::synoptic_package(PROPERTIES_HAP);
	inter_name *iname = Hierarchy::make_iname_with_memo(PROPERTY_HL, R, W);
	property *prn = Properties::create(EMPTY_WORDING, R, iname);
	prn->either_or = TRUE;
	Properties::exclude_from_index(prn);
	Properties::set_translation(prn, I6_form);
	Properties::EitherOr::create_adjective_from_property(prn, EMPTY_WORDING, K_object);
	prn->run_time_only = TRUE;
	return prn;
}

@h Initialising details.

=
void Properties::EitherOr::initialise(property *prn) {
	prn->negation = NULL;
	prn->stored_in_negation = FALSE;
	prn->implemented_as_attribute = NOT_APPLICABLE;
	prn->adjectival_meaning_registered = NULL;
	prn->adjectival_phrase_registered = NULL;
	#ifdef IF_MODULE
	prn->eo_parsing_grammar = NULL;
	#endif
}

@ When created, all properties start out as singletons; the following joins
two together into a pair. It's allowed to rejoin an existing pair (either way
around), but not to break one.

=
void Properties::EitherOr::make_negations(property *prn, property *neg) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	if ((neg == NULL) || (neg->either_or == FALSE)) internal_error("non-EO property");
	if ((prn->negation) || (neg->negation)) {
		if ((prn->negation != neg) || (neg->negation != prn)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_property(2, prn);
			Problems::quote_property(3, neg);
			if (prn->negation) {
				Problems::quote_property(4, prn);
				Problems::quote_property(5, prn->negation);
			} else {
				Problems::quote_property(4, neg);
				Problems::quote_property(5, neg->negation);
			}
			Problems::Issue::handmade_problem(_p_(PM_BrokenNegationPair));
			Problems::issue_problem_segment(
				"In %1, you proposed to set up the properties '%2' and '%3' as "
				"opposites of each other. But I can't allow that, because '%4' "
				"already has an opposite in another context ('%5').");
			Problems::issue_problem_end();
			return;
		}
		return;
	}

	prn->negation = neg; neg->negation = prn;
	Properties::EitherOr::make_stored_in_negation(neg);
}

property *Properties::EitherOr::get_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	return prn->negation;
}

@ =
int Properties::EitherOr::stored_in_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	return prn->stored_in_negation;
}

void Properties::EitherOr::make_stored_in_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	if (prn->negation == NULL) internal_error("singleton EO cannot store in negation");

	prn->stored_in_negation = TRUE;
	if (prn->negation) prn->negation->stored_in_negation = FALSE;
}

@ Miscellaneous details:

=
#ifdef IF_MODULE
grammar_verb *Properties::EitherOr::get_parsing_grammar(property *prn) {
	if ((prn == NULL) || (prn->either_or == FALSE)) return NULL;
	return prn->eo_parsing_grammar;
}

void Properties::EitherOr::set_parsing_grammar(property *prn, grammar_verb *gv) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	prn->eo_parsing_grammar = gv;
}
#endif

adjectival_phrase *Properties::EitherOr::get_aph(property *prn) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	return prn->adjectival_phrase_registered;
}

@h Assertion.

=
void Properties::EitherOr::assert(property *prn,
	inference_subject *owner, int parity, int certainty) {
	pcalc_prop *prop = Calculus::Atoms::unary_PREDICATE_from_aph(
		Properties::EitherOr::get_aph(prn), (parity)?FALSE:TRUE);
	Calculus::Propositions::Assert::assert_true_about(prop, owner, certainty);
}

@h Compilation.
Inform 6 provides "attributes" as a faster-access, more memory-efficient
form of object properties, stored at run-time in a bitmap rather than as
key-value pairs in a small dictionary. Because the bitmap is inflexibly sized,
only some of our either/or properties will be able to make use of it. See
"Properties of Objects" for how these are chosen; the following simply
keep a flag recording the outcome.

=
int Properties::EitherOr::implemented_as_attribute(property *prn) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	if (prn->implemented_as_attribute == NOT_APPLICABLE) return TRUE;
	return prn->implemented_as_attribute;
}

void Properties::EitherOr::implement_as_attribute(property *prn, int state) {
	if ((prn == NULL) || (prn->either_or == FALSE)) internal_error("non-EO property");
	prn->implemented_as_attribute = state;
	if (prn->negation) prn->negation->implemented_as_attribute = state;
}

@ Otherwise, each either/or property is stored as either |true| or |false|
in a given cell of memory at run-time -- wastefully since only 1 of the
16 or 32 bits in that memory word is used, but at least rapidly. The
following compiles this |true| or |false| value.

(Because of the way the attribute optimisation works, it's very important not to
change the strings of compiled code here without making a matching change in
"Properties of Objects".)

=
void Properties::EitherOr::compile_value(value_holster *VH, property *prn, int val) {
	if (val) {
		if (Holsters::data_acceptable(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 1);
	} else {
		if (Holsters::data_acceptable(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
	}
}

void Properties::EitherOr::compile_default_value(value_holster *VH, property *prn) {
	if (Holsters::data_acceptable(VH))
		Holsters::holster_pair(VH, LITERAL_IVAL, 0);
}

@h Either/or properties as adjectives.
What makes either/or properties linguistically interesting is their use as
adjectives: an open door, a transparent container. Adjectival
meanings arising in this way are of the |EORP_KADJ| kind, and the following
is called every time an either/or property is created, to create its matching
adjectival meaning:

=
void Properties::EitherOr::create_adjective_from_property(property *prn, wording W, kind *K) {
	adjective_meaning *am =
		Adjectives::Meanings::new(EORP_KADJ, STORE_POINTER_property(prn), W);
	Adjectives::Meanings::declare(am, W, 1);
	Adjectives::Meanings::set_domain_from_kind(am, K);
	prn->adjectival_phrase_registered = Adjectives::Meanings::get_aph_from_am(am);
	prn->adjectival_meaning_registered = am;
}

void Properties::EitherOr::make_new_adjective_sense_from_property(property *prn, wording W, kind *K) {
	adjectival_phrase *aph = prn->adjectival_phrase_registered;
	if (Adjectives::Meanings::applicable_to(aph, K)) return;
	adjective_meaning *am =
		Adjectives::Meanings::new(EORP_KADJ, STORE_POINTER_property(prn), W);
	Adjectives::Meanings::declare(am, W, 2);
	Adjectives::Meanings::set_domain_from_kind(am, K);
}

@ And here are the methods which define |EORP| adjectives. They arise other
than by parsing, as we've seen, so:

=
adjective_meaning *Properties::EitherOr::ADJ_parse(parse_node *q,
	int sense, wording AW, wording DNW, wording CONW, wording CALLW) {
	return NULL;
}

@ Compiling tests or assertions of these adjectives is easy, because it just
means using their schemata in the usual way...

=
int Properties::EitherOr::ADJ_compile(property *prn, int T, int emit_flag, ph_stack_frame *phsf) {
	return FALSE;
}

@ ...but writing those schemata is not so easy, partly because of the way
either/or properties may be paired, partly because of the attribute storage
optimisation applied to some but not all of them.

=
void Properties::EitherOr::ADJ_compiling_soon(adjective_meaning *am, property *prn, int T) {
	if (am == NULL) internal_error("Unregistered adjectival either/or property in either/or atom");

	if (Adjectives::Meanings::get_ready_flag(am)) return;
	Adjectives::Meanings::set_ready_flag(am);

	kind *K = Adjectives::Meanings::get_domain(am);
	if (Kinds::Compare::le(K, K_object))
		@<Set the schemata for an either/or property adjective with objects as domain@>
	else
		@<Set the schemata for an either/or property adjective with some other domain@>;
	return;
}

@ The "objects" domain is not really very different, but it's the one used
overwhelmingly most often, so we will call the relevant routines directly rather
than accessing them via the unifying routines |GProperty| and |WriteGProperty| --
which would work just as well, but more slowly.

@<Set the schemata for an either/or property adjective with objects as domain@> =
	if (Properties::EitherOr::stored_in_negation(prn)) {
		property *neg = Properties::EitherOr::get_negation(prn);
		inter_name *identifier = Properties::iname(neg);

		i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "GetEitherOrProperty(*1, %n) == false", identifier);

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, true)", identifier);

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_FALSE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, false)", identifier);
	} else {
		inter_name *identifier = Properties::iname(prn);

		i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "GetEitherOrProperty(*1, %n)", identifier);

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, false)", identifier);

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_FALSE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, true)", identifier);
	}

@<Set the schemata for an either/or property adjective with some other domain@> =
	if (Properties::EitherOr::stored_in_negation(prn)) {
		property *neg = Properties::EitherOr::get_negation(prn);

		i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "GProperty(%k, *1, %n) == false", K,
			Properties::iname(neg));

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n)", K,
			Properties::iname(neg));

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_FALSE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n, true)", K,
			Properties::iname(neg));
	} else {
		i6_schema *sch = Adjectives::Meanings::set_i6_schema(am, TEST_ADJECTIVE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "GProperty(%k, *1, %n)", K,
			Properties::iname(prn));

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_TRUE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n, true)", K,
			Properties::iname(prn));

		sch = Adjectives::Meanings::set_i6_schema(am, NOW_ADJECTIVE_FALSE_TASK, FALSE);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n)", K,
			Properties::iname(prn));
	}

@ To assert an adjective like "open" is to draw an inference about its
property.

=
int Properties::EitherOr::ADJ_assert(property *prn,
	inference_subject *infs_to_assert_on, parse_node *val_to_assert_on, int parity) {
	if (parity == FALSE) World::Inferences::draw_negated_property(infs_to_assert_on, prn, NULL);
	else World::Inferences::draw_property(infs_to_assert_on, prn, NULL);
	return TRUE;
}

@ And finally:

=
int Properties::EitherOr::ADJ_index(OUTPUT_STREAM, property *prn) {
	property *neg = Properties::EitherOr::get_negation(prn);
	WRITE("either/or property");
	if (Properties::permission_list(prn)) {
		WRITE(" of "); World::Permissions::index(OUT, prn);
	} else if ((neg) && (Properties::permission_list(neg))) {
		WRITE(" of "); World::Permissions::index(OUT, neg);
	}
	if (neg) WRITE(", opposite of </i>%+W<i>", neg->name);
	return TRUE;
}
