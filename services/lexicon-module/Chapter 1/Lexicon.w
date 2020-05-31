[Lexicon::] Lexicon.

This section provides a simple API for storing and retrieving lexicon entries.

@ The user creates new lexicon entries with:

=
excerpt_meaning *Lexicon::register(
	unsigned int meaning_code, wording W, general_pointer data) {
	if (Wordings::empty(W)) internal_error("tried to register empty excerpt meaning");
	return ExcerptMeanings::register(meaning_code, W, data);
}

@ //excerpt_meaning// objects are intended to be fairly opaque, but the user
can call this to extract their attached data:

=
general_pointer Lexicon::get_data(excerpt_meaning *em) {
	return em->data;
}

@ Entries can be retrieved either the regular way, or in "maximal mode",
which tries to parse a maximal-length initial portion of |W| rather than
necessarily the whole thing. For example, that mode might peel off the
adjective "fixed in place" from wording |W| which was "fixed in place door".
This is very much the exception: we almost always want to match the whole of |W|.

It might seem symmetrical that the return value should be an //excerpt_meaning//.
But that wouldn't enable us to return multiple results in the (frequent) case
of ambiguity. Instead, we need to return a list of possibilities, and we do
that by returning fragment of syntax tree material, using the infrastructure
from //syntax//. This will be a list of nodes joined by |->next_alternative| limks.

This list of nodes is disposable -- even if it is a copy of something from the
syntax tree, it is never the only copy. It can freely be ignored or changed.
A return value of |NULL| means there were no results at all.

(*) If a meaning was registered in such a way that its |data| actually was a
node from the syntax tree, then the result is a copy of that node.
(*) If not then the result is a node with the meaning code as its node type,
and the excerpt meaning can be recovered from it using |Node::get_meaning|.

=
parse_node *Lexicon::retrieve(unsigned int mc_bitmap, wording W) {
	return FromLexicon::parse(mc_bitmap, W);
}

int lexicon_in_maximal_mode = FALSE;
parse_node *Lexicon::retrieve_longest_initial_segment(unsigned int mc_bitmap,
	wording W) {
	int s = lexicon_in_maximal_mode;
	lexicon_in_maximal_mode = TRUE;
	parse_node *p = FromLexicon::parse(mc_bitmap, W);
	lexicon_in_maximal_mode = s;
	return p;
}

@ As a bonus, since the lexicon uses quite a convenient hash-coding system
for excerpts, the following is available for anyone wanting to take advantage:

=
int Lexicon::wording_hash(wording W) {
	return ExcerptMeanings::hash_code(W);
}
