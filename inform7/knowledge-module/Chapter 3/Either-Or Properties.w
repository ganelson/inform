[EitherOrProperties::] Either-Or Properties.

Properties which can either be present or not, but have no value
attached.

@h Pairs and negations.
Either-or properties may need rather different run-time implementation from
properties with values, but otherwise they might seem nothing special: why
not simply regard them as properties holding truth state values? And then
there would just be obe type of property.

The answer is that whereas a computer-science view of the "open" property,
say, would take exactly this line -- i.e., that it simply holds a truth
state, and that the word "closed" is only syntactic sugar for saying that
this value is false -- natural language is different. In natural language,
the words "open" and "closed" are just as good as each other. One might
talk equally about "the closed property" as about "the open property".

We therefore implement these as two //property// instances, each of the
either-or type. For each one, |negation| points to the other. We call
this a "pair". It's not required that either-or properties come in pairs;
sometimes an author simply says that something "can be P" rather than "can be
P or Q".

@h Initialising details.
Each either-or property has the following small block of data attached:

=
typedef struct either_or_property_data {
	struct property *negation; /* see above: the other, if it's one of a pair */
	struct adjective *as_adjective; /* if it is adjectivally used */
	#ifdef IF_MODULE
	struct grammar_verb *eo_parsing_grammar; /* exotic forms used in parsing */
	#endif
	CLASS_DEFINITION
} either_or_property_data;

either_or_property_data *EitherOrProperties::new_eo_data(property *prn) {
	either_or_property_data *eod = CREATE(either_or_property_data);
	eod->negation = NULL;
	eod->as_adjective = NULL;
	#ifdef IF_MODULE
	eod->eo_parsing_grammar = NULL;
	#endif
	return eod;
}

@h Requesting new named properties.
The following is called to find an existing property called |W|, or create
a new one if necessary, and give the subject |subj| permission to have it:

=
property *EitherOrProperties::obtain(wording W, inference_subject *subj) {
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
	kind *K = KindSubjects::to_kind(subj);
	EitherOrPropertyAdjectives::create_for_property(prn, W, K);
	return prn;
}

@h Requesting new nameless properties.
These are properties needed for implementation reasons by //runtime//, or by
plugins in //if//, but which have no existence at the Inform 7 source text level --
and hence have no names. An author cannot refer to them, knows nothing of them.

Setting them up as adjectives may seem a little over the top, since they cannot
be encountered in source text, but the world model will have to set these properties
by asserting propositions to be true; and type-checking of those propositions
relies on adjectival meanings.

=
property *EitherOrProperties::new_nameless(wchar_t *identifier_text) {
	wording W = Feeds::feed_C_string(identifier_text);
	package_request *R = Hierarchy::synoptic_package(PROPERTIES_HAP);
	inter_name *iname = Hierarchy::make_iname_with_memo(PROPERTY_HL, R, W);
	property *prn = Properties::create(EMPTY_WORDING, R, iname, TRUE);
	IXProperties::dont_show_in_index(prn);
	RTProperties::set_translation(prn, identifier_text);
	EitherOrPropertyAdjectives::create_for_property(prn, EMPTY_WORDING, K_object);
	prn->Inter_level_only = TRUE;
	return prn;
}

@h Dealing with pairs.
When created, all properties start out as singletons; the following joins
two together into a pair. It's allowed to rejoin an existing pair (either way
around), but not to break one.

=
void EitherOrProperties::make_pair(property *prn, property *neg) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	if ((neg == NULL) || (neg->either_or_data == NULL)) internal_error("non-EO property");
	if ((EitherOrProperties::get_negation(prn)) ||
		(EitherOrProperties::get_negation(neg))) {
		if ((EitherOrProperties::get_negation(prn) != neg) ||
			(EitherOrProperties::get_negation(neg) != prn)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_property(2, prn);
			Problems::quote_property(3, neg);
			if (EitherOrProperties::get_negation(prn)) {
				Problems::quote_property(4, prn);
				Problems::quote_property(5, EitherOrProperties::get_negation(prn));
			} else {
				Problems::quote_property(4, neg);
				Problems::quote_property(5, EitherOrProperties::get_negation(neg));
			}
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_BrokenNegationPair));
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

@ =
property *EitherOrProperties::get_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) return NULL;
	return prn->either_or_data->negation;
}

@ Miscellaneous details:

=
#ifdef IF_MODULE
grammar_verb *EitherOrProperties::get_parsing_grammar(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) return NULL;
	return prn->either_or_data->eo_parsing_grammar;
}

void EitherOrProperties::set_parsing_grammar(property *prn, grammar_verb *gv) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	prn->either_or_data->eo_parsing_grammar = gv;
}
#endif

adjective *EitherOrProperties::as_adjective(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	return prn->either_or_data->as_adjective;
}

@h Assertion.

=
void EitherOrProperties::assert(property *prn,
	inference_subject *owner, int parity, int certainty) {
	pcalc_prop *prop = AdjectivalPredicates::new_atom_on_x(
		EitherOrProperties::as_adjective(prn), (parity)?FALSE:TRUE);
	Assert::true_about(prop, owner, certainty);
}
