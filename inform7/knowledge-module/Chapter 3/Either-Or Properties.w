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
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_KindAdjectiveClash),
			"this tries to create a new either/or adjective with the same name "
			"as an existing kind",
			"which isn't allowed. For example, 'A hopper can be a container.' is "
			"not allowed because something either is, or is not, a 'container', "
			"and that can never change during play. 'Container' is a kind, and "
			"those are fixed. 'A hopper is a container' would be allowed, because "
			"that makes a definite statement.");
		return NULL;
	}
	property *prn = Properties::obtain(W, FALSE);
	kind *K = KindSubjects::to_kind(infs);
	if (prn->either_or_data->as_adjective_meaning == NULL)
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
	wording W = Feeds::feed_C_string(I6_form);
	package_request *R = Hierarchy::synoptic_package(PROPERTIES_HAP);
	inter_name *iname = Hierarchy::make_iname_with_memo(PROPERTY_HL, R, W);
	property *prn = Properties::create(EMPTY_WORDING, R, iname, TRUE);
	IXProperties::dont_show_in_index(prn);
	RTProperties::set_translation(prn, I6_form);
	Properties::EitherOr::create_adjective_from_property(prn, EMPTY_WORDING, K_object);
	prn->Inter_level_only = TRUE;
	return prn;
}

@h Initialising details.

=
typedef struct either_or_property_data {
	struct property *negation; /* and which property name (if any) negates it? */
	struct adjective_meaning *as_adjective_meaning; /* and has it been made an adjective yet? */
	#ifdef IF_MODULE
	struct grammar_verb *eo_parsing_grammar; /* exotic forms used in parsing */
	#endif
	CLASS_DEFINITION
} either_or_property_data;

either_or_property_data *Properties::EitherOr::new_eo_data(property *prn) {
	either_or_property_data *eod = CREATE(either_or_property_data);
	eod->negation = NULL;
	eod->as_adjective_meaning = NULL;
	#ifdef IF_MODULE
	eod->eo_parsing_grammar = NULL;
	#endif
	return eod;
}

@ When created, all properties start out as singletons; the following joins
two together into a pair. It's allowed to rejoin an existing pair (either way
around), but not to break one.

=
void Properties::EitherOr::make_negations(property *prn, property *neg) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	if ((neg == NULL) || (neg->either_or_data == NULL)) internal_error("non-EO property");
	if ((Properties::EitherOr::get_negation(prn)) || (Properties::EitherOr::get_negation(neg))) {
		if ((Properties::EitherOr::get_negation(prn) != neg) || (Properties::EitherOr::get_negation(neg) != prn)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_property(2, prn);
			Problems::quote_property(3, neg);
			if (Properties::EitherOr::get_negation(prn)) {
				Problems::quote_property(4, prn);
				Problems::quote_property(5, Properties::EitherOr::get_negation(prn));
			} else {
				Problems::quote_property(4, neg);
				Problems::quote_property(5, Properties::EitherOr::get_negation(neg));
			}
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BrokenNegationPair));
			Problems::issue_problem_segment(
				"In %1, you proposed to set up the properties '%2' and '%3' as "
				"opposites of each other. But I can't allow that, because '%4' "
				"already has an opposite in another context ('%5').");
			Problems::issue_problem_end();
			return;
		}
		return;
	}

	prn->either_or_data->negation = neg; neg->either_or_data->negation = prn;
	RTProperties::store_in_negation(neg);
}

property *Properties::EitherOr::get_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) return NULL;
	return prn->either_or_data->negation;
}

@ Miscellaneous details:

=
#ifdef IF_MODULE
grammar_verb *Properties::EitherOr::get_parsing_grammar(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) return NULL;
	return prn->either_or_data->eo_parsing_grammar;
}

void Properties::EitherOr::set_parsing_grammar(property *prn, grammar_verb *gv) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	prn->either_or_data->eo_parsing_grammar = gv;
}
#endif

adjective *Properties::EitherOr::get_aph(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	if (prn->either_or_data->as_adjective_meaning == NULL) return NULL;
	return prn->either_or_data->as_adjective_meaning->owning_adjective;
}

@h Assertion.

=
void Properties::EitherOr::assert(property *prn,
	inference_subject *owner, int parity, int certainty) {
	pcalc_prop *prop = AdjectivalPredicates::new_atom_on_x(
		Properties::EitherOr::get_aph(prn), (parity)?FALSE:TRUE);
	Assert::true_about(prop, owner, certainty);
}

@h Either/or properties as adjectives.
What makes either/or properties linguistically interesting is their use as
adjectives: an open door, a transparent container. Adjectival
meanings arising in this way are of the |either_or_property_amf| kind, and the following
is called every time an either/or property is created, to create its matching
adjectival meaning:

=
adjective_meaning_family *either_or_property_amf = NULL; /* defined by an either/or property like "closed" */

void Properties::EitherOr::start(void) {
	either_or_property_amf = AdjectiveMeanings::new_family(1);

	METHOD_ADD(either_or_property_amf, ASSERT_ADJM_MTID, Properties::EitherOr::assert_adj);
	METHOD_ADD(either_or_property_amf, PREPARE_SCHEMAS_ADJM_MTID, Properties::EitherOr::prepare_schemas);
	METHOD_ADD(either_or_property_amf, INDEX_ADJM_MTID, Properties::EitherOr::ADJ_index);
}

int Properties::EitherOr::is_either_or_adjective(adjective_meaning *am) {
	if ((am) && (am->family == either_or_property_amf)) return TRUE;
	return FALSE;
}

void Properties::EitherOr::create_adjective_from_property(property *prn, wording W, kind *K) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("not either-or");
	adjective *adj = Adjectives::declare(W, NULL);
	adjective_meaning *am =
		AdjectiveMeanings::new(either_or_property_amf, STORE_POINTER_property(prn), W);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeaningDomains::set_from_kind(am, K);
	prn->either_or_data->as_adjective_meaning = am;
}

void Properties::EitherOr::make_new_adjective_sense_from_property(property *prn, wording W, kind *K) {
	adjective *adj = Adjectives::declare(W, NULL);
	adjective *aph = Properties::EitherOr::get_aph(prn);
	if (AdjectiveAmbiguity::can_be_applied_to(aph, K)) return;
	adjective_meaning *am =
		AdjectiveMeanings::new(either_or_property_amf, STORE_POINTER_property(prn), W);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeaningDomains::set_from_kind(am, K);
}

@ ...but writing those schemata is not so easy, partly because of the way
either/or properties may be paired, partly because of the attribute storage
optimisation applied to some but not all of them.

=
void Properties::EitherOr::prepare_schemas(adjective_meaning_family *family, adjective_meaning *am, int T) {
	property *prn = RETRIEVE_POINTER_property(am->family_specific_data);
	if (prn == NULL) internal_error("Unregistered adjectival either/or property in either/or atom");

	if (am->schemas_prepared == FALSE) {
		kind *K = AdjectiveMeaningDomains::get_kind(am);
		if (Kinds::Behaviour::is_object(K))
			@<Set the schemata for an either/or property adjective with objects as domain@>
		else
			@<Set the schemata for an either/or property adjective with some other domain@>;
	}
}

@ The "objects" domain is not really very different, but it's the one used
overwhelmingly most often, so we will call the relevant routines directly rather
than accessing them via the unifying routines |GProperty| and |WriteGProperty| --
which would work just as well, but more slowly.

@<Set the schemata for an either/or property adjective with objects as domain@> =
	if (RTProperties::stored_in_negation(prn)) {
		property *neg = Properties::EitherOr::get_negation(prn);
		inter_name *identifier = RTProperties::iname(neg);

		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GetEitherOrProperty(*1, %n) == false", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, true)", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, false)", identifier);
	} else {
		inter_name *identifier = RTProperties::iname(prn);

		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GetEitherOrProperty(*1, %n)", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, false)", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, true)", identifier);
	}

@<Set the schemata for an either/or property adjective with some other domain@> =
	if (RTProperties::stored_in_negation(prn)) {
		property *neg = Properties::EitherOr::get_negation(prn);

		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GProperty(%k, *1, %n) == false", K,
			RTProperties::iname(neg));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n)", K,
			RTProperties::iname(neg));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n, true)", K,
			RTProperties::iname(neg));
	} else {
		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GProperty(%k, *1, %n)", K,
			RTProperties::iname(prn));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n, true)", K,
			RTProperties::iname(prn));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n)", K,
			RTProperties::iname(prn));
	}

@ To assert an adjective like "open" is to draw an inference about its
property.

=
int Properties::EitherOr::assert_adj(adjective_meaning_family *f,
	adjective_meaning *am, inference_subject *infs_to_assert_on, int parity) {
	property *prn = RETRIEVE_POINTER_property(am->family_specific_data);
	if (parity == FALSE) PropertyInferences::draw_negated(infs_to_assert_on, prn, NULL);
	else PropertyInferences::draw(infs_to_assert_on, prn, NULL);
	return TRUE;
}

@ And finally:

=
int Properties::EitherOr::ADJ_index(adjective_meaning_family *f, text_stream *OUT,
	adjective_meaning *am) {
	property *prn = RETRIEVE_POINTER_property(am->family_specific_data);
	property *neg = Properties::EitherOr::get_negation(prn);
	WRITE("either/or property");
	if (Properties::get_permissions(prn)) {
		WRITE(" of "); IXProperties::index_permissions(OUT, prn);
	} else if ((neg) && (Properties::get_permissions(neg))) {
		WRITE(" of "); IXProperties::index_permissions(OUT, neg);
	}
	if (neg) WRITE(", opposite of </i>%+W<i>", neg->name);
	return TRUE;
}
