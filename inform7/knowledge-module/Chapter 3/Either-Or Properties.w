[EitherOrProperties::] Either-Or Properties.

Properties which can either be present or not, but have no value
attached.

@h Pairs and negations.
Either-or properties may need rather different run-time implementation from
properties with values, but otherwise they might seem nothing special: why
not simply regard them as properties holding truth state values? And then
there would just be one type of property.

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
	int is_default; /* |TRUE| if this is a negation and was declared second */
	struct parse_node *where_negated; /* the sentence making these antonyms */
	struct adjective *as_adjective; /* if it is adjectivally used */
	#ifdef IF_MODULE
	struct command_grammar *eo_parsing_grammar; /* exotic forms used in parsing */
	#endif
	CLASS_DEFINITION
} either_or_property_data;

either_or_property_data *EitherOrProperties::new_eo_data(property *prn) {
	either_or_property_data *eod = CREATE(either_or_property_data);
	eod->negation = NULL;
	eod->is_default = FALSE;
	eod->where_negated = NULL;
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
features in //if//, but which have no existence at the Inform 7 source text level --
and hence have no names. An author cannot refer to them, knows nothing of them.

Setting them up as adjectives may seem a little over the top, since they cannot
be encountered in source text, but the world model will have to set these properties
by asserting propositions to be true; and type-checking of those propositions
relies on adjectival meanings.

=
property *EitherOrProperties::new_nameless(text_stream *identifier_text) {
	package_request *R = Hierarchy::completion_package(PROPERTIES_HAP);
	property *prn = Properties::create(EMPTY_WORDING, R, NULL, TRUE, identifier_text);
	RTProperties::dont_show_in_index(prn);
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
		if (prn->either_or_data->is_default) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_property(2, prn);
			Problems::quote_property(3, neg);
			Problems::quote_source(4, prn->either_or_data->where_negated);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_TransposedNegationPair));
			Problems::issue_problem_segment(
				"In %1, you proposed to set up the properties '%2' and '%3' as "
				"opposites of each other. But I can't allow that, because they "
				"are already set up as opposites, but the other way around. "
				"(This matters because it affects whether things not explicitly "
				"said to be either should be %2 or %3. Here you imply %3 is the "
				"default, but in the previous declaration %4, %2 was.) Putting these "
				"two property names the other way around should fix it.");
			Problems::issue_problem_end();
			return;
		}
		return;
	}

	prn->either_or_data->negation = neg;
	neg->either_or_data->negation = prn;
	prn->either_or_data->is_default = FALSE;
	neg->either_or_data->is_default = TRUE;
	prn->either_or_data->where_negated = current_sentence;
	neg->either_or_data->where_negated = current_sentence;
	RTProperties::store_in_negation(neg);
}

void EitherOrProperties::vet_use_as_non_default_property(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) return;
	if (prn->either_or_data->is_default) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_property(2, prn);
		Problems::quote_property(3, EitherOrProperties::get_negation(prn));
		Problems::quote_source(4, prn->either_or_data->where_negated);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TransposedNegationPair2));
		Problems::issue_problem_segment(
			"In %1, you proposed to set up the property '%2' as something which "
			"is sometimes held and sometimes not, but by default is not. However, "
			"that clashes with the existing declaration %4, which establishes "
			"that %2 is the opposite of %3, and is held by default. (The "
			"simplest way to fix this is just to change '%2' to '%3' in your "
			"sentence here.)");
		Problems::issue_problem_end();
		return;
	}
}

@ =
property *EitherOrProperties::get_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) return NULL;
	return prn->either_or_data->negation;
}

@ Miscellaneous details:

=
#ifdef IF_MODULE
command_grammar *EitherOrProperties::get_parsing_grammar(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) return NULL;
	return prn->either_or_data->eo_parsing_grammar;
}

void EitherOrProperties::set_parsing_grammar(property *prn, command_grammar *cg) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	prn->either_or_data->eo_parsing_grammar = cg;
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
