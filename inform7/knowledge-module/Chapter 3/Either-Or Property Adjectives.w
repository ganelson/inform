[EitherOrPropertyAdjectives::] Either-Or Property Adjectives.

Names of either-or properties when used as adjectives.

@ Names of either-or properties can be used adjectivally in Inform: thus,
"an open door", or "a transparent container". They form the |either_or_property_amf|
family of adjectives, which we now declare.

=
adjective_meaning_family *either_or_property_amf = NULL;

void EitherOrPropertyAdjectives::start(void) {
	either_or_property_amf = AdjectiveMeanings::new_family(1);
	METHOD_ADD(either_or_property_amf, ASSERT_ADJM_MTID,
		EitherOrPropertyAdjectives::assert);
	METHOD_ADD(either_or_property_amf, PREPARE_SCHEMAS_ADJM_MTID,
		EitherOrPropertyAdjectives::prepare_schemas);
	METHOD_ADD(either_or_property_amf, INDEX_ADJM_MTID,
		EitherOrPropertyAdjectives::index);
}

int EitherOrPropertyAdjectives::is(adjective_meaning *am) {
	if ((am) && (am->family == either_or_property_amf)) return TRUE;
	return FALSE;
}

@ This tells us that the property should now be used adjectivally over a given
kind. Note that it creates the adjective if it doesn't already exist, and also
that it does nothing if the adjective can already be used in this way. So, for
example, the either-or property "empty" has an associated adjective "empty",
but it can apply to both rulebooks and containers. These are two different
adjective meanings, one for each kind the adjective applies to.

=
void EitherOrPropertyAdjectives::create_for_property(property *prn, wording W, kind *K) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("not either-or");
	adjective *adj = EitherOrProperties::as_adjective(prn);
	if (adj) {
		if (AdjectiveAmbiguity::can_be_applied_to(adj, K)) return;
	} else {
		adj = Adjectives::declare(W, NULL);
		prn->either_or_data->as_adjective = adj;
	}
	adjective_meaning *am =
		AdjectiveMeanings::new(either_or_property_amf, STORE_POINTER_property(prn), W);
	AdjectiveAmbiguity::add_meaning_to_adjective(am, adj);
	AdjectiveMeaningDomains::set_from_kind(am, K);
}

@ That just leaves three methods, all of which pass out work elsewhere:

=
int EitherOrPropertyAdjectives::assert(adjective_meaning_family *f,
	adjective_meaning *am, inference_subject *infs_to_assert_on, int parity) {
	property *prn = RETRIEVE_POINTER_property(am->family_specific_data);
	if (parity == FALSE) PropertyInferences::draw_negated(infs_to_assert_on, prn, NULL);
	else PropertyInferences::draw(infs_to_assert_on, prn, NULL);
	return TRUE;
}

void EitherOrPropertyAdjectives::prepare_schemas(adjective_meaning_family *family,
	adjective_meaning *am, int T) {
	property *prn = RETRIEVE_POINTER_property(am->family_specific_data);
	if (am->schemas_prepared == FALSE)
		RTProperties::write_either_or_schemas(am, prn, T);
}

int EitherOrPropertyAdjectives::index(adjective_meaning_family *f, text_stream *OUT,
	adjective_meaning *am) {
	property *prn = RETRIEVE_POINTER_property(am->family_specific_data);
	IXProperties::index_either_or(OUT, prn);
	return TRUE;
}
