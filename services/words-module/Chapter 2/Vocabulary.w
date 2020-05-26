[Vocabulary::] Vocabulary.

To classify the words in the lexical stream, where two different
words are considered equivalent if they are unquoted and have the same text,
taken case insensitively.

@h Vocabulary Entries.
A //vocabulary_entry// object is created for each different word found in the
source. (Recall that these are not necessarily words in the usual English
sense: for instance, |17| is a word here.)

The vocabulary entry structure exists to make textual comparisons faster,
which is essential to make Inform run tolerably quickly: Inform's speed on
typical source texts increased by a factor of 5-10 when this structure was
introduced. Firstly, the vocabulary is hashed so that it is not too
painful to compare a newly-read word against the known vocabulary;
secondly, each word stores linked lists of meanings which it begins,
occurs in the middle of, ends, or is optionally part of (in the sense
that "brown" is optionally part of the name "small brown shoe", which
could also be written "small shoe"); and thirdly, each word also carries
a bitmap of flags indicating the possible contexts in which it might
be used. Finally, to avoid parsing the same text over and over for its
possible meaning as a literal integer, we cache the result: for instance,
17 for the text |17|.

The meaning codes alluded to below are also used for excerpts of text
(i.e., are not just for single words): see //linguistics: Excerpt Meanings//.

@d ING_MC					0x04000000 /* a word ending in -ing */
@d NUMBER_MC				0x08000000 /* one, two, ..., twelve, 1, 2, ... */
@d I6_MC					0x10000000 /* piece of verbatim I6 code */
@d TEXTWITHSUBS_MC			0x20000000 /* double-quoted text literal with substitutions */
@d TEXT_MC					0x40000000 /* double-quoted text literal without substitutions */
@d ORDINAL_MC				0x80000000 /* first, second, third, ..., twelfth */

=
typedef struct vocabulary_entry {
	unsigned int flags; /* bitmap of "meaning codes" indicating possible usages */
	int literal_number_value; /* evaluation as a literal number, if any */
	wchar_t *exemplar; /* text of one instance of this word */
	wchar_t *raw_exemplar; /* text of one instance in its raw untreated form */
	int hash; /* hash code derived from text of word */
	struct vocabulary_entry *next_in_vocab_hash; /* next in list with this hash */
	struct vocabulary_entry *lower_case_form; /* or null if none exists */
	struct vocabulary_entry *upper_case_form; /* or null if none exists */
	int nt_incidence; /* bitmap hashing which Preform nonterminals it occurs in */
	#ifdef VOCABULARY_MEANING_INITIALISER_WORDS_CALLBACK
	struct vocabulary_meaning means;
	#endif
} vocabulary_entry;

@ Some standard punctuation marks:

=
vocabulary_entry *CLOSEBRACE_V = NULL;
vocabulary_entry *CLOSEBRACKET_V = NULL;
vocabulary_entry *COLON_V = NULL;
vocabulary_entry *COMMA_V = NULL;
vocabulary_entry *DOUBLEDASH_V = NULL;
vocabulary_entry *FORWARDSLASH_V = NULL;
vocabulary_entry *FULLSTOP_V = NULL;
vocabulary_entry *OPENBRACE_V = NULL;
vocabulary_entry *OPENBRACKET_V = NULL;
vocabulary_entry *OPENI6_V = NULL;
vocabulary_entry *PARBREAK_V = NULL;
vocabulary_entry *PLUS_V = NULL;
vocabulary_entry *SEMICOLON_V = NULL;
vocabulary_entry *STROKE_V = NULL;

void Vocabulary::create_punctuation(void) {
	CLOSEBRACE_V     = Vocabulary::entry_for_text(L"}");
	CLOSEBRACKET_V   = Vocabulary::entry_for_text(L")");
	COLON_V          = Vocabulary::entry_for_text(L":");
	COMMA_V          = Vocabulary::entry_for_text(L",");
	DOUBLEDASH_V     = Vocabulary::entry_for_text(L"--");
	FORWARDSLASH_V   = Vocabulary::entry_for_text(L"/");
	FULLSTOP_V       = Vocabulary::entry_for_text(L".");
	OPENBRACE_V      = Vocabulary::entry_for_text(L"{");
	OPENBRACKET_V    = Vocabulary::entry_for_text(L"(");
	OPENI6_V         = Vocabulary::entry_for_text(L"(-");
	PARBREAK_V       = Vocabulary::entry_for_text(PARAGRAPH_BREAK);
	PLUS_V      	 = Vocabulary::entry_for_text(L"+");
	SEMICOLON_V      = Vocabulary::entry_for_text(L";");
	STROKE_V         = Vocabulary::entry_for_text(L"|");
}

@ Each distinct word is to have a unique |vocabulary_entry| structure, and the
"identity" at word number |wn| is to point to the structure for the text
at that word. Two words are distinct if their lower-case forms are different,
except that two quoted literal texts are always distinct, even if they have
the same content. So for instance,

>> Daleks conquer and destroy! "Ba-dum." Exterminate, exterminate! "Ba-dum."

would be identified as

>> |ve0| |ve1| |ve2| |ve3| |ve4| |ve5| |ve6| |ve6| |ve4| |ve7|

where |ve4| is the common identity of both exclamation marks, and |ve6|
that of the two "exterminate"s, even though they have different casings;
while the quoted text |"Ba-dum."| came out with two different identities
|ve5| and |ve7|.

When we want to set the identity for a given word, we call these front-door
routines, either on a single word or on a range.

=
void Vocabulary::identify_word(int wn) {
	vocabulary_entry *ve = Vocabulary::entry_for_text(Lexer::word_text(wn));
	ve->raw_exemplar = Lexer::word_raw_text(wn);
	Lexer::set_word(wn, ve);
}

void Vocabulary::identify_word_range(wording W) {
	LOOP_THROUGH_WORDING(i, W)
		Vocabulary::identify_word(i);
}

@ Should we ever change the text of a word, it's essential to re-identify it,
as otherwise its |lw_identity| points to the wrong vocabulary entry.

=
void Vocabulary::change_text_of_word(int wn, wchar_t *new) {
	Lexer::set_word_text(wn, new);
	Lexer::set_word_raw_text(wn, new);
	Vocabulary::identify_word(wn);
}

@ We now need some utilities for dealing with vocabulary entries. Here is a
creator, and a debugging logger:

=
vocabulary_entry *Vocabulary::vocab_entry_new(wchar_t *text, int hash_code,
	unsigned int flags, int val) {
	vocabulary_entry *ve = CREATE(vocabulary_entry);
	ve->exemplar = text; ve->raw_exemplar = text;
	ve->next_in_vocab_hash = NULL;
	ve->lower_case_form = NULL; ve->upper_case_form = NULL;
	ve->hash = hash_code;
	ve->nt_incidence = 0;
	ve->flags = flags;
	int l = Wide::len(text);
	if ((l>3) && (text[l-3] == 'i') && (text[l-2] == 'n') && (text[l-1] == 'g'))
		ve->flags |= ING_MC;
	ve->literal_number_value = val;
	#ifdef VOCABULARY_MEANING_INITIALISER_WORDS_CALLBACK
	ve->means = VOCABULARY_MEANING_INITIALISER_WORDS_CALLBACK(ve);
	#endif
	return ve;
}

void Vocabulary::log(OUTPUT_STREAM, void *vve) {
	vocabulary_entry *ve = (vocabulary_entry *) vve;
	if (ve == NULL) { WRITE("NULL"); return; }
	if (ve->exemplar == NULL) { WRITE("NULL-EXEMPLAR"); return; }
	WRITE("%08x-%w-%08x", ve->hash, ve->raw_exemplar, ve->flags);
}

@ It's perhaps unexpected that a vocabulary entry not only stores a (pointer
to) a copy of the text, the "exemplar" (since it is text which is an
example of this vocabulary being used), but also a separate raw copy of
the text: raw in the sense of retaining the original form in the source
files which the word came from. This looks strange because we normally
identify words on their case-lowered text, not on their raw text. In
the source material:

>> Former Marillion vocalist Fish derived his nickname not from a fish, but from habitual bathing.

words 4, "Fish", and 11, "fish", each have the same vocabulary entry
as identity, even though their raw texts differ. Clearly the ordinary
exemplar of this entry must be "fish". But what should the raw exemplar
be, "Fish" or "fish"? The answer is the latter, or in general, the raw
exemplar will always be the same as the exemplar; unless we have amended
it by hand, using the following routine.

=
void Vocabulary::set_raw_exemplar_to_text(int wn) {
	Lexer::word(wn)->raw_exemplar = Lexer::word_text(wn);
}

@ Here are some access routines for the data stored in this
structure:

=
wchar_t *Vocabulary::get_exemplar(vocabulary_entry *ve, int raw) {
	if (raw) return ve->raw_exemplar;
	else return ve->exemplar;
}

void Vocabulary::writer(OUTPUT_STREAM, char *format_string, void *vV) {
	vocabulary_entry *ve = (vocabulary_entry *) vV;
	if (ve == NULL) internal_error("tried to write null vocabulary");
	switch (format_string[0]) {
		case '+': WRITE("%w", ve->raw_exemplar); break;
		case 'V': WRITE("%w", ve->exemplar); break;
		default: internal_error("bad %V extension");
	}
}

@ An integer is stored at each vocabulary entry, recording its value
if it every turns out to parse as a literal number:

=
int Vocabulary::get_literal_number_value(vocabulary_entry *ve) {
	return ve->literal_number_value;
}
void Vocabulary::set_literal_number_value(vocabulary_entry *ve, int val) {
	ve->literal_number_value = val;
}

@ Almost all text is used case insensitively in Inform source, but we do
occasionally need to distinguish "The" from "the" and the like, when
parsing the names of text substitutions. When a new text substitution is
declared whose first word, in the definition, begins with a capital letter,
|Vocabulary::make_case_sensitive| is called on the first word, and its identity
is changed to the upper case variant form.

=
int Vocabulary::used_case_sensitively(vocabulary_entry *ve) {
	if ((ve->upper_case_form) || (ve->lower_case_form)) return TRUE;
	return FALSE;
}
vocabulary_entry *Vocabulary::get_lower_case_form(vocabulary_entry *ve) {
	return ve->lower_case_form;
}
vocabulary_entry *Vocabulary::make_case_sensitive(vocabulary_entry *ve) {
	if (ve->upper_case_form) return ve->upper_case_form;
	ve->upper_case_form =
		Vocabulary::vocab_entry_new(ve->exemplar, ve->hash, ve->flags, ve->literal_number_value);
	ve->upper_case_form->lower_case_form = ve;
	return ve->upper_case_form;
}

@ Finally, each vocabulary entry comes with a bitmap of flags, and here
we get to set and test them:

=
void Vocabulary::set_flags(vocabulary_entry *ve, unsigned int t) {
	ve->flags |= t;
}
unsigned int Vocabulary::test_vflags(vocabulary_entry *ve, unsigned int t) {
	return (ve->flags) & t;
}
unsigned int Vocabulary::test_flags(int wn, unsigned int t) {
	return (Lexer::word(wn)->flags) & t;
}

@ It can be useful to find the disjunction of the flags for all the words
in a range, as that gives us a single bitmap which tells us quickly whether
any of the words in that range is a number, or is a word ending in "-ing",
and so on:

=
unsigned int Vocabulary::disjunction_of_flags(wording W) {
	unsigned int d = 0;
	LOOP_THROUGH_WORDING(i, W)
		d |= (Lexer::word(i)->flags);
	return d;
}

@ We also leave space for a bitmap used by //The Optimiser//: in particular,
see //NTI::mark_vocabulary//.

=
void Vocabulary::set_nti(vocabulary_entry *ve, int R) {
	ve->nt_incidence = R;
}
int Vocabulary::get_nti(vocabulary_entry *ve) {
	return ve->nt_incidence;
}

@h Hash coding of words.
To find all the different words used in the source text, we need in principle
to make an enormous number of comparisons of their texts. It is slow to make
a correct identification of two texts as being equal: we have to compare
their every characters against each other. Fortunately, it can be much
faster to tell if they are different. We do this by rapidly deriving a
number from their texts, and then comparing the numbers: if different,
the texts were different.

The most obvious number would be the length of the text, but this produces
too little variation, and too many false positives: "blue" and "cyan",
for instance, would each produce the number 4.

Instead we use a standard method to derive a number traditionally called
a "hash code". This is the algorithm called "X 30011" in Aho, Sethi and
Ullman's standard "Compilers: Principles, Techniques and Tools" (1986).
Because it is derived from constantly overflowing integer arithmetic,
it will produce different codes on different architectures (say, where
|int| is 64 bits long rather than 32, or where |char| is unsigned).
All that matters is that it provides a good spread of hash codes for
typical texts fed into it on any given occasion.

Good results depend on the number of possible codes being not too tiny
compared to the number of different texts fed in, and also on the key value
30011 being coprime to this number (but 30011 is prime, so that's easily
arranged). A typical source text of 50,000 words has an unquoted vocabulary
of only about 2000 different words. The variation in vocabulary size
between the smallest text source and the largest is only about a factor of
three or four, so there is no need to make a dynamic estimate of the size
of the source. We will always choose 997 as the number of possible hash
codes produced by X 30011: we reserve a further three special codes to be
the hashes of literals rather than ordinary words, and this brings us up to
a round 1000.

Inside the lexer, decimal integers such as |-506| were treated as ordinary
words, as there were no lexical difficulties in parsing them. Here they
begin to semantically diverge from the way other ordinary words are handled:
they're treated more like literal texts and I6 inclusions.

@d HASH_TAB_SIZE 1000 /* the possible hash codes are 0 up to this minus 1 */
@d NUMBER_HASH 0 /* literal decimal integers, and no other words, have this hash code */
@d TEXT_HASH 1 /* double quoted texts, and no other words, have this hash code */
@d I6_HASH 2 /* the |(-| word introducing an I6 inclusion uniquely has this hash code */

=
int Vocabulary::hash_code_from_word(wchar_t *text) {
    unsigned int hash_code = 0;
    wchar_t *p = text;
    switch(*p) {
    	case '-': if (p[1] == 0) break; /* an isolated minus sign is an ordinary word */
    		/* and otherwise fall into... */
    	case '0': case '1': case '2': case '3': case '4':
    	case '5': case '6': case '7': case '8': case '9':
    		/* the first character may prove to be the start of a number: is this true? */
			for (p++; *p; p++) if (Characters::isdigit(*p) == FALSE) goto Try_Text;
			return NUMBER_HASH;
		case ' ': return I6_HASH;
		case '(': if (p[1] == '-') return I6_HASH;
			break;
		case '"': return TEXT_HASH;
    }
    Try_Text:
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wsign-conversion"
    for (p=text; *p; p++) hash_code = hash_code*30011 + (*p);
	#pragma clang diagnostic pop
    return (int) (3+(hash_code % (HASH_TAB_SIZE-3))); /* result of X 30011, plus 3 */
}

@h The hash table of vocabulary.
Armed with these hash codes, we now store the pointers to the vocabulary
entry structures in linked lists, one for each possible hash code.
These begin empty.

=
vocabulary_entry *list_of_vocab_with_hash[HASH_TAB_SIZE];
void Vocabulary::start_hash_table(void) {
    for (int i=0; i<HASH_TAB_SIZE; i++) list_of_vocab_with_hash[i] = NULL;
}

void Vocabulary::write_hash_table(OUTPUT_STREAM) {
    for (int i=0; i<HASH_TAB_SIZE; i++) {
    	int c=0;
		for (vocabulary_entry *entry = list_of_vocab_with_hash[i];
			entry; entry = entry->next_in_vocab_hash) {
			if (c++ == 0) PRINT("%d:", i);
			PRINT(" %w", entry->exemplar);
		}
    	if (c>0) PRINT("\n");
    }
}

@ And that leaves only one routine: for finding the unique vocabulary
entry pointer associated with the material in |text|. We search the
hash table to see if we have the word already, and if not, we add it.
Either way, we return a valid pointer. (Compare Isaiah 55:11, "So shall
my word be that goeth forth out of my mouth: it shall not return unto
me void.")

It is in order to set the initial values of the flags for the new
word (if it does turn out to be new) that we mandated special hash
codes for any number, any text, or any I6 inclusion.

=
int no_vocabulary_entries = 0;

vocabulary_entry *Vocabulary::entry_for_text(wchar_t *text) {
	vocabulary_entry *new_entry;
	int hash_code = Vocabulary::hash_code_from_word(text), val = 0;
	unsigned int f = 0;
	switch(hash_code) {
		case NUMBER_HASH: f = NUMBER_MC; val = Wide::atoi(text); break;
		case TEXT_HASH:
			switch (Word::perhaps_ill_formed_text_routine(text)) {
				case TRUE: f = TEXTWITHSUBS_MC; break;
				case FALSE: f = TEXT_MC; break;
				case NOT_APPLICABLE: f = TEXT_MC; break;
			}
			break;
		case I6_HASH: f = I6_MC; break;
		default:
			val = Vocabulary::an_ordinal_number(text);
			if (val >= 0) f = NUMBER_MC + ORDINAL_MC; /* so that "4th", say, picks up both */
			break;
	}
	if (list_of_vocab_with_hash[hash_code] == NULL) {
		@<Pi-ty? That word is not in my vocabulary banks@>;
	} else {
		vocabulary_entry *old_entry = NULL;
		int n;
		/* search the non-empty list of words with this hash code */
		for (n=0, new_entry = list_of_vocab_with_hash[hash_code];
			new_entry != NULL;
			n++, old_entry = new_entry, new_entry = new_entry->next_in_vocab_hash)
			if (Wide::cmp(new_entry->exemplar, text) == 0)
				return new_entry;
		/* and if we do not find |text| in there, then... */
		@<My vision is impaired! I cannot see!@>;
	}
}

@ Here the list for this word's hash code was empty, either meaning that this
is a hash code never seen for any word before (in which case we start the
list for that hash code with the new word), or that the word is a text
literal -- because, for efficiency's sake, we deliberately keep the
hash list for all text literals empty.

@<Pi-ty? That word is not in my vocabulary banks@> =
	new_entry = Vocabulary::vocab_entry_new(text, hash_code, f, val);
	if (hash_code != TEXT_HASH) list_of_vocab_with_hash[hash_code] = new_entry;
	LOGIF(VOCABULARY, "Word %d <%w> is first vocabulary with hash %d\n",
		no_vocabulary_entries++, text, hash_code);
	return new_entry;

@ And here, we exhausted the list at entry |n-1|, with the last entry being
pointed to by |old_entry|. We add the new word at the end.

@<My vision is impaired! I cannot see!@> =
	new_entry = Vocabulary::vocab_entry_new(text, hash_code, f, val);
	old_entry->next_in_vocab_hash = new_entry;
	LOGIF(VOCABULARY, "Word %d <%w> is vocabulary entry no. %d with hash %d\n",
		no_vocabulary_entries++, text, n, hash_code);
	return new_entry;

@h Partial words.
Much the same, except that we enter a fragment of a word into lexical memory
and then find its identity as if it were a whole word.

=
vocabulary_entry *Vocabulary::entry_for_partial_text(wchar_t *str, int from, int to) {
	TEMPORARY_TEXT(TEMP);
	for (int i=from; i<=to; i++) PUT_TO(TEMP, str[i]);
	PUT_TO(TEMP, 0);
	wording W = Feeds::feed_text(TEMP);
	DISCARD_TEXT(TEMP);
	if (Wordings::empty(W)) return NULL;
	return Lexer::word(Wordings::first_wn(W));
}

@h Ordinals.
The following parses the string to see if it is a non-negative integer,
written as an English ordinal: 0th, 1st, 2nd, 3rd, 4th, 5th, ... Note
that we don't bother to police the finicky rules on which suffix should
accompany which value (22nd not 22th, and so on).

=
int Vocabulary::an_ordinal_number(wchar_t *fw) {
	for (int i=0; fw[i] != 0; i++)
		if (!(Characters::isdigit(fw[i]))) {
			if ((i>0) &&
				(((fw[i] == 's') && (fw[i+1] == 't') && (fw[i+2] == 0)) ||
				((fw[i] == 'n') && (fw[i+1] == 'd') && (fw[i+2] == 0)) ||
				((fw[i] == 'r') && (fw[i+1] == 'd') && (fw[i+2] == 0)) ||
				((fw[i] == 't') && (fw[i+1] == 'h') && (fw[i+2] == 0))))
				return Wide::atoi(fw);
			break;
		}
	return -1;
}
