[WordAssemblages::] Word Assemblages.

To manage arbitrary assemblies of vocabulary, if a little slowly.

@ When putting names together out of fragments, we will need to string words
together in ways not laid out in the source text, and the following structure is
a convenient holder for such composites.

@d MAX_WORDS_IN_ASSEMBLAGE 32 /* do not reduce this below 5 */

=
typedef struct word_assemblage {
	int no_indiv_words; /* should be between 0 and |MAX_WORDS_IN_ASSEMBLAGE| */
	struct vocabulary_entry *indiv_words[MAX_WORDS_IN_ASSEMBLAGE]; /* some may be null */
} word_assemblage;

@h Word assemblages.
Inform normally handles names as word ranges in text read into the lexer,
but here we will need to manipulate and rearrange the text, and also use
words never lexed; so we need a simple data structure for words pieced
together from arbitrary vocabulary.

=
word_assemblage WordAssemblages::new_assemblage(void) {
	word_assemblage wa;
	wa.no_indiv_words = 0;
	int i;
	for (i=0; i<MAX_WORDS_IN_ASSEMBLAGE; i++) wa.indiv_words[i] = NULL;
	return wa;
}

@ We provide two ways to make these; first, from the source text directly:

=
word_assemblage WordAssemblages::from_wording(wording W) {
	if ((Wordings::empty(W)) || (Wordings::length(W) > MAX_WORDS_IN_ASSEMBLAGE))
		internal_error("assemblage won't fit");
	word_assemblage wa = WordAssemblages::new_assemblage();
	LOOP_THROUGH_WORDING(i, W)
		wa.indiv_words[wa.no_indiv_words++] = Lexer::word(i);
	return wa;
}

@ Second, an empty or single-word literal:

=
word_assemblage WordAssemblages::lit_0(void) {
	return WordAssemblages::new_assemblage();
}

word_assemblage WordAssemblages::lit_1(vocabulary_entry *ve1) {
	word_assemblage wa = WordAssemblages::new_assemblage();
	if (ve1) wa.indiv_words[wa.no_indiv_words++] = ve1;
	return wa;
}

@ The only other way to make a word assemblage is by concatenation:

=
word_assemblage WordAssemblages::join(word_assemblage wa1, word_assemblage wa2) {
	if (wa1.no_indiv_words + wa2.no_indiv_words > MAX_WORDS_IN_ASSEMBLAGE)
		internal_error("assemblage overflow");
	word_assemblage sum = WordAssemblages::new_assemblage();
	int i;
	for (i=0; i<wa1.no_indiv_words; i++)
		sum.indiv_words[sum.no_indiv_words++] = wa1.indiv_words[i];
	for (i=0; i<wa2.no_indiv_words; i++)
		sum.indiv_words[sum.no_indiv_words++] = wa2.indiv_words[i];
	return sum;
}

@ Here we convert back to a word range, though this mustn't be performed
frequently, since it consumes memory:

=
wording WordAssemblages::to_wording(word_assemblage *wa) {
	if (wa->no_indiv_words == 0) return EMPTY_WORDING;
	feed_t id = Feeds::begin();
	for (int i=0; i<wa->no_indiv_words; i++) {
		TEMPORARY_TEXT(str)
		WRITE_TO(str, " %V ", wa->indiv_words[i]);
		Feeds::feed_text(str);
		DISCARD_TEXT(str)
	}
	return Feeds::end(id);
}

@ Here we truncate from the front:

=
void WordAssemblages::truncate(word_assemblage *wa, int n) {
	if (n <= wa->no_indiv_words) {
		for (int i=0; i+n < wa->no_indiv_words; i++)
			wa->indiv_words[i] = wa->indiv_words[i+n];
		wa->no_indiv_words -= n;
	}
}

void WordAssemblages::truncate_to(word_assemblage *wa, int n) {
	if (n <= wa->no_indiv_words) {
		wa->no_indiv_words = n;
	}
}

@h Miscellaneous readings.

=
int WordAssemblages::nonempty(word_assemblage wa1) {
	if (wa1.no_indiv_words > 0) return TRUE;
	return FALSE;
}

void WordAssemblages::writer(OUTPUT_STREAM, char *format_string, void *vW) {
	if (vW == NULL) { WRITE("<null-assemblage>"); return; }
	word_assemblage *wa = (word_assemblage *) vW;
	if (wa)
		for (int i=0; i<wa->no_indiv_words; i++) {
			if (i > 0) WRITE(" ");
			WRITE("%V", wa->indiv_words[i]);
		}
}

vocabulary_entry *WordAssemblages::hyphenated(word_assemblage *wa) {
	if (wa->no_indiv_words > 9) return NULL;
	TEMPORARY_TEXT(str)
	WRITE_TO(str, " ");
	int i;
	for (i=0; i<wa->no_indiv_words; i++) {
		if (i > 0) WRITE_TO(str, "-");
		WRITE_TO(str, "%V", wa->indiv_words[i]);
	}
	WRITE_TO(str, " ");
	wording W = Feeds::feed_text(str);
	DISCARD_TEXT(str)
	return Lexer::word(Wordings::first_wn(W));
}

void WordAssemblages::as_array(word_assemblage *wa, vocabulary_entry ***array, int *len) {
	*array = wa->indiv_words;
	*len = wa->no_indiv_words;
}

@ =
int WordAssemblages::eq(word_assemblage *wa1, word_assemblage *wa2) {
	if (wa1 == wa2) return TRUE;
	if ((wa1 == NULL) || (wa2 == NULL)) return FALSE;
	if (wa1->no_indiv_words != wa2->no_indiv_words) return FALSE;
	for (int i=0; i<wa1->no_indiv_words; i++)
		if (wa1->indiv_words[i] != wa2->indiv_words[i])
			return FALSE;
	return TRUE;
}

int WordAssemblages::compare_with_wording(word_assemblage *wa, wording W) {
	if (wa == NULL) return FALSE;
	if (Wordings::empty(W)) return FALSE;
	if (wa->no_indiv_words != Wordings::length(W)) return FALSE;
	for (int i=0; i<wa->no_indiv_words; i++)
		if (wa->indiv_words[i] != Lexer::word(Wordings::first_wn(W) + i))
			return FALSE;
	return TRUE;
}

@ =
int WordAssemblages::parse_as_strictly_initial_text(wording W, word_assemblage *wa) {
	return WordAssemblages::parse_as_weakly_initial_text(W, wa, EMPTY_WORDING, TRUE, FALSE);
}

int WordAssemblages::parse_as_weakly_initial_text(wording W, word_assemblage *wa,
	wording S, int allow_uuc, int allow_to_fill) {
	int k, i;
	for (i=0, k=Wordings::first_wn(W); i<wa->no_indiv_words; i++)
		if ((wa->indiv_words[i] == PARBREAK_V) && (Wordings::nonempty(S))) {
			if (Wordings::starts_with(Wordings::from(W, k), S) == FALSE) return -1;
			k += Wordings::length(S);
		} else if (wa->indiv_words[i]) {
			if ((k > Wordings::last_wn(W)) || (wa->indiv_words[i] != Lexer::word(k))) return -1;
			if ((allow_uuc == FALSE) && (Word::unexpectedly_upper_case(k))) return -1;
			k++;
		}
	if ((k > Wordings::last_wn(W)) && (allow_to_fill == FALSE)) return -1;
	return k;
}

int WordAssemblages::is_at(word_assemblage *wa, int wn, int to) {
	if (wa->no_indiv_words > to-wn+1) return FALSE;
	for (int i=0; i<wa->no_indiv_words; i++)
		if (wa->indiv_words[i] != Lexer::word(wn + i))
			return FALSE;
	return TRUE;
}

@ Perhaps not the last word in programming, but...

=
vocabulary_entry *WordAssemblages::last_word(word_assemblage *wa) {
	if ((wa == NULL) || (wa->no_indiv_words == 0)) return NULL;
	return wa->indiv_words[wa->no_indiv_words-1];
}

vocabulary_entry *WordAssemblages::first_word(word_assemblage *wa) {
	if ((wa == NULL) || (wa->no_indiv_words == 0)) return NULL;
	return wa->indiv_words[0];
}

int WordAssemblages::length(word_assemblage *wa) {
	if (wa == NULL) return 0;
	return wa->no_indiv_words;
}

int WordAssemblages::longer(word_assemblage *wa1, word_assemblage *wa2) {
	int l1 = 0;
	if (wa1) l1 = wa1->no_indiv_words;
	int l2 = 0;
	if (wa2) l2 = wa2->no_indiv_words;
	return l1 - l2;
}

@ =
void WordAssemblages::log(OUTPUT_STREAM, void *vwa) {
	word_assemblage *wa = (word_assemblage *) vwa;
	if (wa == NULL) { WRITE("<null-words>"); return; }
	int i, sp = FALSE;
	for (i=0; i<wa->no_indiv_words; i++)
		if (wa->indiv_words[i]) {
			if (sp) WRITE(" "); sp = TRUE;
			WRITE("%V", wa->indiv_words[i]);
		}
}

void WordAssemblages::index(OUTPUT_STREAM, word_assemblage *wa) {
	if (wa == NULL) return;
	int i, sp = FALSE;
	for (i=0; i<wa->no_indiv_words; i++)
		if (wa->indiv_words[i]) {
			if (sp) WRITE(" "); sp = TRUE;
			WRITE("%V ", wa->indiv_words[i]);
		}
}
