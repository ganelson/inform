[AdjectiveUsages::] Adjective Usages.

A lightweight structure to record uses of an adjective, either
positively or negatively.

@h Adjective usages.
This really is just an ordered pair of an adjective and a boolean:

=
typedef struct adjective_usage {
	adjectival_phrase *ref_to;
	int ref_positive; /* used positively? */
} adjective_usage;

@ =
adjective_usage *AdjectiveUsages::new(adjectival_phrase *aph, int pos) {
	adjective_usage *au = CREATE(adjective_usage);
	au->ref_to = aph;
	au->ref_positive = pos;
	return au;
}

void AdjectiveUsages::log(adjective_usage *au) {
	adjectival_phrase *aph = AdjectiveUsages::get_aph(au);
	if (au->ref_positive == FALSE) LOG("~");
	wording W = Adjectives::get_text(aph, FALSE);
	LOG("<adj:%W>", W);
}

adjective_usage *AdjectiveUsages::copy(adjective_usage *au_from) {
	return AdjectiveUsages::new(au_from->ref_to, au_from->ref_positive);
}

adjectival_phrase *AdjectiveUsages::get_aph(adjective_usage *au) {
	if (au == NULL) return NULL;
	return au->ref_to;
}

int AdjectiveUsages::get_parity(adjective_usage *au) {
	if (au == NULL) internal_error("null adjective tested for positivity");
	return au->ref_positive;
}

void AdjectiveUsages::flip_parity(adjective_usage *au) {
	if (au == NULL) internal_error("null adjective flipped");
	au->ref_positive = (au->ref_positive)?FALSE:TRUE;
}
