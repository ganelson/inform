[ExcerptMeanings::] Excerpt Meanings.

To register and deregister meanings for excerpts of text as
nouns, adjectives, imperative phrases and other usages.

@h Excerpt meanings.
We now define the //excerpt_meaning// data structure, which holds a single
entry in this what amounts to a dictionary. The text to be matched is specified
as a sequence of at least one, and at most 32, tokens: these can either be
pointers to specific vocabulary, or can be null, which implies that
arbitrary non-empty text can appear in the given position. It is forbidden
for the token list to contain two nulls in a row.

For instance, the token list:
= (text)
	drink # milk #
=
matches "drink more milk today and every day", but not "drink milk". The
sharp symbol |#| is printed in place of a null token, both here and in the
debugging log.

Each excerpt meaning also comes with a hash code, which is automatically
generated from its token list, and a pointer to some structure.

@d MAX_TOKENS_PER_EXCERPT_MEANING 32

=
typedef struct excerpt_meaning {
	unsigned int meaning_code; /* what kind of meaning: a single MC, not a bitmap */
	struct general_pointer data; /* data structure being referred to */
	int no_em_tokens; /* length of token list */
	struct vocabulary_entry *em_tokens[MAX_TOKENS_PER_EXCERPT_MEANING]; /* token list */
	int excerpt_hash; /* hash code generated from the token list */
	CLASS_DEFINITION
} excerpt_meaning;

@h Meaning codes.
These assign a context to a meaning, and so decide how the |data| pointer for
an excerpt meaning is to interpreted. For instance, "Persian carpet" might
have a meaning with code |NOUN_MC|.

Meaning codes are used in other contexts in Inform besides this one. There
are up to 31 of them and each is a distinct power of two; there is no
significance to their ordering. Integers are assumed at least 32 bits wide and
can therefore hold a bitmap representing any subset of these meaning codes;
using only 31 bits avoids any potential nuisance over the sign bit.

For instance, |PROPERTY_MC + TABLE_MC| might mean "either a property name or
a table name". But the |meaning_code| field of an //excerpt_meaning// is always
a pure power of 2, i.e., a single bit.

@d MISCELLANEOUS_MC			0x00000001 /* a grab-bag of other possible nouns */
@d NOUN_MC					0x00000002 /* e.g., |upright chair| */
@d ADJECTIVE_MC				0x00000004 /* e.g., |invisible| */

@h Annotating words.
Each word in the vocabulary collected up by //words// will be annotated with
an object of the following class:

=
typedef struct vocabulary_lexicon_data {
	#ifdef KINDS_MODULE
	struct kind *one_word_kind; /* ditto as a kind with single-word name */
	#endif
	struct parse_node *start_list; /* meanings starting with this */
	struct parse_node *end_list; /* meanings ending with this */
	struct parse_node *middle_list; /* meanings with this inside but at neither end */
	struct parse_node *subset_list; /* meanings allowing subsets which include this */
	int subset_list_length; /* number of meanings in the subset list */
	int scanned_already; /* used only for diagnostics */
} vocabulary_lexicon_data;

@ With the following initialiser:

@d VOCABULARY_MEANING_INITIALISER_WORDS_CALLBACK ExcerptMeanings::new_vocabulary_attachment

=
vocabulary_lexicon_data ExcerptMeanings::new_vocabulary_attachment(vocabulary_entry *ve) {
	#ifdef KINDS_MODULE
	if (Kinds::Textual::parse_variable(ve)) ve->flags |= KIND_FAST_MC;
	#endif
	if ((ve->flags) & NUMBER_MC) Cardinals::mark_as_cardinal(ve);
	if ((ve->flags) & ORDINAL_MC) Cardinals::mark_as_ordinal(ve);

	vocabulary_lexicon_data ld;
	ld.start_list = NULL; ld.end_list = NULL; ld.middle_list = NULL;
	ld.subset_list = NULL; ld.subset_list_length = 0;
	ld.scanned_already = FALSE;
	#ifdef KINDS_MODULE
	ld.one_word_kind = NULL;
	#endif
	return ld;
}

@h Creating EMs.
The following makes a skeletal EM structure, with no token list or hash code
as yet.

=
excerpt_meaning *ExcerptMeanings::new(unsigned int mc, general_pointer data) {
	excerpt_meaning *em = CREATE(excerpt_meaning);
	em->meaning_code = mc;
	em->data = data;
	em->no_em_tokens = 0;
	em->excerpt_hash = 0;
	return em;
}

@h Debugging log.
First to log a general bitmap made up from meaning codes:

=
void ExcerptMeanings::log(OUTPUT_STREAM, void *vem) {
	excerpt_meaning *em = (excerpt_meaning *) vem;
	if (em == NULL) { WRITE("<null-em>"); return; }
	WRITE("{");
	for (int i=0; i<em->no_em_tokens; i++) {
		if (i>0) WRITE(" ");
		if (em->em_tokens[i] == NULL) { WRITE("#"); continue; }
		WRITE("%V", em->em_tokens[i]);
	}
	WRITE(" = ");
	NodeType::log(OUT, (int) em->meaning_code);
	WRITE("}");
}

void ExcerptMeanings::log_all(void) {
	int i = 0;
	excerpt_meaning *em;
	LOOP_OVER(em, excerpt_meaning)
		LOG("%02d: $M\n", i++, em);
}

@h Hashing excerpts.
For excerpts |(w1, w2)|, we need a form of hash function which makes it
easy to test whether the words in one excerpt can all be found in another,
or to be more exact whether

$$ \lbrace I_j\mid w_1\leq j\leq w_2\rbrace \subseteq
\lbrace I_j\mid w_3\leq j\leq w_4\rbrace $$

where $I_n$ is the identity of word $n$. As with all hash algorithms, we do
not need to guarantee a positive match, only a negative, so we can throw
away a lot of information. And we also want a hash function which makes it
easy to test whether an excerpt contains any of the literals.

@ There are two sources of text which we might want to hash in this way:
first, actual excerpts found in the source text. These are not very
expensive to calculate, but every ounce of speed helps here, so we cache
the most recent.

The hash generated this way is an arbitrary bitmap of bits 1 to 30, with
bits 31 and 32 left clear.

=
int cached_hash_w1 = -2, cached_hash_w2 = -2, cached_value;

int ExcerptMeanings::hash_code(wording W) {
	if (Wordings::empty(W)) return 0;
	int w1 = Wordings::first_wn(W), w2 = Wordings::last_wn(W);
	int i, h = 0; vocabulary_entry *v;
	if ((w1 == cached_hash_w1) && (w2 == cached_hash_w2)) return cached_value;
	for (i=w1; i<=w2; i++) {
		v = Lexer::word(i);
		if (v) @<Allow this vocabulary entry to contribute to the excerpt's hash code@>;
	}
	return h;
}

@ Second, when a new excerpt meaning is to be registered, we want to hash
code its token list. But only some of the tokens are vocabulary entries,
while others instead represent gaps where arbitrary text can appear (referred
to with a null pointer). Note that we simply ignore that gaps when hashing,
that is, we produce the same hash as we would if the gaps were not there at
all.

The hash generated this way is an arbitrary bitmap of bits 1 to 31, with
bit 32 left clear. Bit 31 is set, as a special case, for excerpts in the
context of text substitutions which begin with a word known to exist, and
with differing meanings, in two differently cased forms: this is how "[the
noun]" is distinguished from "[The noun]". (The lower 30 bits have the
same meaning as in the first case above.)

@d CAPITALISED_VARIANT_FORM (1 << 30)

=
void ExcerptMeanings::hash_code_from_token_list(excerpt_meaning *em) {
	int i, h = 0;
	if (em->no_em_tokens == 0) internal_error("Empty text when registering");
	if ((em->no_em_tokens >= 1) && (em->em_tokens[0])) {
		vocabulary_entry *lcf = Vocabulary::get_lower_case_form(em->em_tokens[0]);
		if (lcf) {
			h = h | CAPITALISED_VARIANT_FORM;
			em->em_tokens[0] = lcf;
		}
	}
	for (i=0; i<em->no_em_tokens; i++) {
		vocabulary_entry *v = em->em_tokens[i];
		if (v) @<Allow this vocabulary entry to contribute to the excerpt's hash code@>;
	}
	em->excerpt_hash = h;
}

@ Now each vocabulary entry |v|, i.e., each distinct word identity, itself has
a hash code to identify it. These are stored in |v->hash| and, except for
literals, are more or less evenly distributed in about the range 0 to 1000.

The contribution made by a single word's individual hash to the bitmap hash
for the whole excerpt is as follows.

@<Allow this vocabulary entry to contribute to the excerpt's hash code@> =
	if ((v->flags) & NUMBER_MC)    h = h | 1;
	else if ((v->flags) & TEXT_MC) h = h | 2;
	else if ((v->flags) & I6_MC)   h = h | 4;
	else                           h = h | (8 << ((v->hash) % 27));

@ To sum up: the excerpt hash is a bitmap indicating what categories of
words are present in the excerpt. It ignores "gaps" in token lists, and
it ignores the order of the words and repetitions. The three least
significant bits indicate whether numbers, text or I6 verbatims are
present, and the next 27 bits indicate the presence of other words: e.g.,
bit 4 indicates that a word with hash code 0, 27, 54, ..., is present, and
so on. Bit 31, which is used only for token lists of excerpt meanings,
marks that an excerpt is a variant form whose first word must be
capitalised in order for it to match. Bit 32 is always left blank (for
superstitious reasons to do with the sign bit and differences between
platforms in handling signed bit shifts).

The result is not a tremendously good hashing number, since it generally
produces a sparse bitmap, so that the variety is not as great as might be
thought. But it is optimised for the trickiest parsing cases where the
rewards of saving unnecessary tests are greatest.

@h EM Listing.
We are clearly not going to store the excerpt meanings in a hash table
keyed by the hash values of excerpts -- with hash values as large as
$2^{31}-1$, that would be practically impossible.

Instead we key using the actual words. Each vocabulary entry has four
linked lists of EMs: its subset list, its start list, its middle list,
and its end list.

(a) If an EM needs to allow parsing as a subset, it must be placed in the
subset list of every word. For instance, "buttress against cathedral
wall" registered under the code |NOUN_MC| would be listed
in the subset lists of "buttress", "against", "cathedral" and "wall".

(b) Otherwise it is placed in only one list:

(-b1) If the token list consists only of a single gap |#|, we must be
registering a "say" phrase to say a value. (There is one of these for
each kind of value.) This meaning is listed under a special |blank_says_p|
list, which is not attached to any vocabulary entry.
(-b2) Otherwise, if the first token is not a |#| gap, it goes into the
start list for the first token's word: for instance, |award # points| joins
the start list for "award".
(-b3) Otherwise, if the last token is not a |#| gap, it goes into the end
list for the last token's word: for instance, |# in # from now| joins the
end list for "now".
(-b4) Otherwise, it goes into the middle list of the word for the leftmost
token which is not a |#|: for instance, |# plus #| joins the middle list for
"plus".

Since no token lists of two or more consecutive |#|s cannot exist, this exhausts the possibilities.

Outside of subset mode, we will then test a given excerpt |(w1, w2)| in the
source text against all possible meanings by checking the start list for |w1|,
the end list for |w2| and the middle list for every one of |(w1+1, w2-1)|.
Because of this:

(i) Performance suffers if lists for individual words become unbalanced
in size. This is why we register Unicode translations as "white chess
knight" rather than "Unicode white chess knight", and so on; the
alternative would be a stupendously long start list for "unicode".
(ii) Middle lists are tested far more often than start or end lists, so
we should keep them as small as possible. This is why (b4) above is our last
resort; happily phrases both starting and ending with |#| are uncommon.

=
parse_node *blank_says_p = NULL;
void ExcerptMeanings::register_em(unsigned int meaning_code, excerpt_meaning *em) {
	#ifdef CORE_MODULE
	PreformCache::warn_of_changes(); /* the existence of new meanings jeopardises any cached parsing results */
	#endif

	@<Compute the new excerpt's hash code from its token list@>;
	@<Watermark each word in the token list with the meaning code being applied@>;

	LOGIF(EXCERPT_MEANINGS,
		"Logging meaning: $M with hash %08x, mc=%d, %d tokens\n",
		em, em->excerpt_hash, meaning_code, em->no_em_tokens);

	if (meaning_code & SUBSET_PARSING_BITMAP) {
		@<Place the new meaning under the subset list for each non-article word@>;
	}
	#ifdef EM_ALLOW_BLANK_TEST_LEXICON_CALLBACK
	else if ((em->no_em_tokens == 1) && (em->em_tokens[0] == NULL) &&
		(EM_ALLOW_BLANK_TEST_LEXICON_CALLBACK(meaning_code))) {
		@<Place the new meaning under the say-blank list@>;
	}
	#endif
	else if (em->em_tokens[0]) {
		@<Place the new meaning under the start list of the first word@>;
	} else if (em->em_tokens[em->no_em_tokens-1]) {
		@<Place the new meaning under the end list of the last word@>;
	} else {
		int i;
		for (i=1; i<em->no_em_tokens-1; i++)
			if (em->em_tokens[i]) { @<Place the new meaning under the middle list of word i@>; break; }
		if (i >= em->no_em_tokens-1) internal_error("registered meaning of two or more #s");
	}
}

@ See above.

@<Compute the new excerpt's hash code from its token list@> =
	ExcerptMeanings::hash_code_from_token_list(em);

@ Another important optimisation is to flag each word in the meaning with
the given meaning code -- this is why vocabulary flags and excerpt meaning
codes share the same numbering space. If we register "Table of Surgical
Instruments" as a table name, the word "surgical", for instance, picks
up the |TABLE_MC| bit in its |flags| bitmap.

The advantage of this is that if we want to see whether |(w1, w2)| might be
a table name, we can take a bitwise AND of the flags for each word in
the range; if the result doesn't have the |TABLE_MC| bit set, then at least
one of the words never occurs in a table name, so the answer must be
"no". This produces rapid, definite negatives with only a few false
positives.

@<Watermark each word in the token list with the meaning code being applied@> =
	int i;
	for (i=0; i<em->no_em_tokens; i++)
		if (em->em_tokens[i])
			((em->em_tokens[i])->flags) |= meaning_code;

@ Note that articles (a, an, the, some) are excluded: this means we don't
waste time trying to see if the excerpt "the" might be a reference to the
object "Gregory the Great".

@<Place the new meaning under the subset list for each non-article word@> =
	int i;
	for (i=0; i<em->no_em_tokens; i++) {
		vocabulary_entry *v = em->em_tokens[i];
		if (v == NULL) {
			LOG("Logging meaning: $M with hash %08x\n", em, em->excerpt_hash);
			internal_error("# in registration of subset meaning");
		}
		if (NTI::test_vocabulary(v, <article>)) continue;
		parse_node *p = ExcerptMeanings::new_em_pnode(em);
		p->next_alternative = v->means.subset_list;
		v->means.subset_list = p;
		v->means.subset_list_length++;
	}

@ To register |#|, which is what "To say (N - a number)" and similar
constructions translate to.

@<Place the new meaning under the say-blank list@> =
	parse_node *p = ExcerptMeanings::new_em_pnode(em);
	if (blank_says_p) {
		parse_node *p2 = blank_says_p;
		while (p2->next_alternative) p2 = p2->next_alternative;
		p2->next_alternative = p;
	}
	else blank_says_p = p;
	LOGIF(EXCERPT_MEANINGS,
		"The blank list with $M is now:\n$T", em, blank_says_p);

@<Place the new meaning under the start list of the first word@> =
	parse_node *p = ExcerptMeanings::new_em_pnode(em);
	p->next_alternative = em->em_tokens[0]->means.start_list;
	em->em_tokens[0]->means.start_list = p;

@ ...and similarly...

@<Place the new meaning under the end list of the last word@> =
	parse_node *p = ExcerptMeanings::new_em_pnode(em);
	p->next_alternative = em->em_tokens[em->no_em_tokens-1]->means.end_list;
	em->em_tokens[em->no_em_tokens-1]->means.end_list = p;

@ ...and similarly again:

@<Place the new meaning under the middle list of word i@> =
	parse_node *p = ExcerptMeanings::new_em_pnode(em);
	p->next_alternative = em->em_tokens[i]->means.middle_list;
	em->em_tokens[i]->means.middle_list = p;

@ Parse nodes are only created from excerpt meanings for storage inside the
excerpt parser, so these never live on into trees.

=
parse_node *ExcerptMeanings::new_em_pnode(excerpt_meaning *em) {
	parse_node *pn = Node::new(em->meaning_code);
	Node::set_meaning(pn, em);
	return pn;
}

@h Registration.
The following is the main routine used throughout Inform to register new
meanings.

=
excerpt_meaning *ExcerptMeanings::register(
	unsigned int meaning_code, wording W, general_pointer data) {
	if (Wordings::empty(W)) internal_error("tried to register empty excerpt meaning");

	#ifdef CORE_MODULE
	if (meaning_code == NOUN_MC)
		LOOP_THROUGH_WORDING(i, W)
			NTI::mark_word(i, <s-object-instance>);
	if (meaning_code == KIND_SLOW_MC)
		LOOP_THROUGH_WORDING(i, W)
			NTI::mark_word(i, <k-kind>);
	#endif

	excerpt_meaning *em = ExcerptMeanings::new(meaning_code, data);

	@<Unless this is parametrised, skip any initial article@>;

	#ifdef EM_CASE_SENSITIVITY_TEST_LEXICON_CALLBACK
	if (EM_CASE_SENSITIVITY_TEST_LEXICON_CALLBACK(meaning_code))
		@<Detect use of upper case on the first word of this new text substitution@>;
	#endif

	@<Build the token list for the new EM@>;

	ExcerptMeanings::register_em(meaning_code, em);

	return em;
}

@ Articles are preserved at the front of phrase definitions, mainly because
text substitutions need to distinguish (for instance) "say [the X]" from
"say [an X]".

@<Unless this is parametrised, skip any initial article@> =
	if ((meaning_code & PARAMETRISED_PARSING_BITMAP) == 0)
		if (NTI::test_word(Wordings::first_wn(W), <article>)) {
			W = Wordings::trim_first_word(W);
			if (Wordings::empty(W))
				internal_error("registered a meaning which was only an article");
		}

@ Because an open bracket fails |isupper|, the following looks at the first
letter of the first word only if it's not a blank. If it finds upper case, as
it would when reading the "T" in:

>> To say The Portrait: ...

then it makes a new upper-case version of the word "the", i.e., "The",
with a distinct lexical identity; and places this distinguished identity as
the new first token. This ensures that we end up with a different token list
from the one in:

>> To say the Portrait: ...

(These are the only circumstances in which phrase parsing has any case
sensitivity.)

@<Detect use of upper case on the first word of this new text substitution@> =
	wchar_t *tx = Lexer::word_raw_text(Wordings::first_wn(W));
	if ((tx[0]) && ((isupper(tx[0])) || (tx[1] == 0))) {
		vocabulary_entry *ucf = Vocabulary::make_case_sensitive(Lexer::word(Wordings::first_wn(W)));
		if (!Characters::isupper(tx[0])) ucf = Vocabulary::get_lower_case_form(ucf);
		Lexer::set_word(Wordings::first_wn(W), ucf);
		LOGIF(EXCERPT_MEANINGS,
			"Allowing initial capitalised word %w: meaning_code = %08x\n",
				tx, meaning_code);
	}

@ We read the text in something like:

>> award (P - a number) points

and transcribe it into the token list, collapsing bracketed parts into |#|
tokens denoting gaps, to result in something like:
= (text)
	award # points
=
with a token count of 3.

@<Build the token list for the new EM@> =
	int tc = 0;
	for (int i=0; i < Wordings::length(W); i++) {
		if (tc >= MAX_TOKENS_PER_EXCERPT_MEANING) {
			@<Complain of excessive length of the new excerpt@>;
			break;
		}
		if (compare_word(Wordings::first_wn(W) + i, OPENBRACKET_V)) {
			em->em_tokens[tc++] = NULL;
			@<Skip over bracketed token description@>;
		} else em->em_tokens[tc++] = Lexer::word(Wordings::first_wn(W) + i);
	}
	em->no_em_tokens = tc;

@ This is all a little defensive, but syntax bugs higher up tend to find
their way down to this plughole:

@<Skip over bracketed token description@> =
	int bl = 1; i++;
	while (bl > 0) {
		if (i >= Wordings::length(W))  {
			LOG("Bad meaning: <%W>\n", W);
			internal_error("Bracket mismatch when registering");
		}
		if (compare_word(Wordings::first_wn(W) + i, OPENBRACKET_V)) bl++;
		if (compare_word(Wordings::first_wn(W) + i, CLOSEBRACKET_V)) bl--;
		i++;
	}
	if ((i < Wordings::length(W)) && (compare_word(Wordings::first_wn(W) + i, OPENBRACKET_V))) {
		LOG("Bad meaning: <%W>\n", W);
		internal_error("Two consecutive bracketed tokens when registering");
	}
	i--;

@ In practice, nobody ever hits this message except deliberately. It has
a tendency to fire twice or more on the same source text because of
registering multiple inflected forms of the same text; but it's not worth
going to any trouble to prevent this.

(At present, this is actually the only lexicon error.)

@e TooLongName_LEXICONERROR from 1

@<Complain of excessive length of the new excerpt@> =
	ExcerptMeanings::problem_handler(TooLongName_LEXICONERROR, EMPTY_WORDING, NULL, 0);

@h Errors.
Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |PROBLEM_LEXICON_CALLBACK|
to some routine of her own, gazumping this one.

=
void ExcerptMeanings::problem_handler(int err_no, wording W, void *ref, int k) {
	#ifdef PROBLEM_LEXICON_CALLBACK
	PROBLEM_LEXICON_CALLBACK(err_no, W, ref, k);
	#endif
	#ifndef PROBLEM_LEXICON_CALLBACK
	TEMPORARY_TEXT(text)
	WRITE_TO(text, "%+W", W);
	switch (err_no) {
		case TooLongName_LEXICONERROR:
			Errors::nowhere("noun too long");
			break;
	}
	DISCARD_TEXT(text)
	#endif
}
