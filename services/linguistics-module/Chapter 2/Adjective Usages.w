[AdjectiveUsages::] Adjective Usages.

A lightweight structure to record uses of an adjective, either
positively or negatively.

@ This really is just an ordered pair of an adjective and a boolean:

=
typedef struct adjective_usage {
	adjective *ref_to;
	int ref_positive; /* used positively? */
} adjective_usage;

@ =
adjective_usage *AdjectiveUsages::new(adjective *aph, int pos) {
	adjective_usage *au = CREATE(adjective_usage);
	au->ref_to = aph;
	au->ref_positive = pos;
	return au;
}

adjective_usage *AdjectiveUsages::copy(adjective_usage *au_from) {
	return AdjectiveUsages::new(au_from->ref_to, au_from->ref_positive);
}

@ Logging:

=
void AdjectiveUsages::log(adjective_usage *au) {
	adjective *aph = AdjectiveUsages::get_aph(au);
	if (au->ref_positive == FALSE) LOG("~");
	wording W = Adjectives::get_nominative_singular(aph);
	LOG("<adj:%W>", W);
}

@ Access:

=
adjective *AdjectiveUsages::get_aph(adjective_usage *au) {
	if (au == NULL) return NULL;
	return au->ref_to;
}

int AdjectiveUsages::get_parity(adjective_usage *au) {
	if (au == NULL) internal_error("null adjective tested for positivity");
	return au->ref_positive;
}

@ And this is the only non-trivial thing one can do with an adjective usage:
reverse its sense.

=
void AdjectiveUsages::flip_parity(adjective_usage *au) {
	if (au == NULL) internal_error("null adjective flipped");
	au->ref_positive = (au->ref_positive)?FALSE:TRUE;
}
