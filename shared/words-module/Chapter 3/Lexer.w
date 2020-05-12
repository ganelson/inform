[Lexer::] Lexer.

To break down a stream of characters into a numbered sequence of
words, literal strings and literal I6 inclusions, removing comments and
unnecessary whitespace.

@h Definitions.

@ Lexical analysis is the process of reading characters from the source
text files and forming them into globs which we call "words": the part of
Inform which does this is the "lexical analyser", or lexer for short. The
algorithms in this chapter are entirely routine, but occasional eye-opening
moments come because natural language does not have the rigorous division
between lexical and semantic parsing which programming language theory
expects. For instance, we want Inform to be case insensitive for the most part,
but we cannot discard upper case entirely at the lexical stage because we
will need it later to decide whether punctuation at the end of a quotation
is meant to end the sentence making the quote, or not. Humans certainly
read these differently:

>> Say "Hello!" with alarm, ... Say "Hello!" With alarm, ...

And paragraph breaks can also have semantic meanings. A gap between two words
does not end a sentence, but a paragraph break between two words clearly does.
So semantic considerations occasionally infiltrate themselves into even the
earliest parts of this chapter.

@ We must never lose sight of the origin of text, because we may need to
print problem messages back to the user which refer to that original material.
We record the provenance of text using the following structure; the
|lexer_position| is such a structure, and marks where the lexer is
currently reading.

=
typedef struct source_location {
	struct source_file *file_of_origin; /* or |NULL| if internally written and not from a file */
	int line_number; /* counting upwards from 1 within file (if any) */
} source_location;

@ When words are being invented by the compiler, we use:

=
source_location Lexer::as_if_from_nowhere(void) {
	source_location as_if_from_nowhere;
    as_if_from_nowhere.file_of_origin = NULL;
    as_if_from_nowhere.line_number = 1;
    return as_if_from_nowhere;
}

@ And while lexing, we maintain:

=
source_location lexer_position;

@ A word can be an English word such as |bedspread|, or a piece of punctuation
such as |!|, or a number such as |127|, or a piece of quoted text of arbitrary
size such as |"I summon up remembrance of things past"|.

The words found are numbered 0, 1, 2, ... in order of being read by
the lexer. The first eight or so words come from the mandatory insertion
text (see Read Source Text.w), then come the words from the primary source
text, then those from the extensions loaded.

References to text throughout Inform's data structure are often in the form
of a pair of word numbers, usually called |w1| and |w2| or some variation
on that, indicating the text which starts at word |w1| and finishes
at |w2| (including both ends). Thus if the text is

>> When to the sessions of sweet silent thought

then the eight words are numbered 0 to 7 and a reference to |w1=2|, |w2=5|
would mean the sub-text "the sessions of sweet". The special null value
|wn=-1| is used when no word reference has been made: never 0, as that would
mean the first word in the list. The maximum legal word number is always one
less than the following variable's value.

=
int lexer_wordcount; /* Number of words read in to arrays */

@h The lexical structure of source text.
The following definitions are fairly self-evident: they specify which
characters cause word divisions, or signal literals.

@d STRING_BEGIN '"' /* Strings are always double-quoted */
@d STRING_END '"'
@d TEXT_SUBSTITUTION_BEGIN '[' /* Inside strings, this denotes a text substitution */
@d TEXT_SUBSTITUTION_END ']'
@d TEXT_SUBSTITUTION_SEPARATOR ','
@d COMMENT_BEGIN '[' /* Text between these, outside strings, is comment */
@d COMMENT_END ']'
@d INFORM6_ESCAPE_BEGIN_1 '(' /* Text beginning with this pair is literal I6 code */
@d INFORM6_ESCAPE_BEGIN_2 '-'
@d INFORM6_ESCAPE_END_1 '-'
@d INFORM6_ESCAPE_END_2 ')'
@d PARAGRAPH_BREAK L"|__" /* Inserted as a special word to mark paragraph breaks */
@d UNICODE_CHAR_IN_STRING ((wchar_t) 0x1b) /* To represent awkward characters in metadata only */

@ This is the standard set used for parsing source text.

@d STANDARD_PUNCTUATION_MARKS L".,:;?!(){}[]" /* Do not add to this list lightly! */

@ This seems a good point to describe how best to syntax-colour source
text, something which the user interfaces do on every platform. By
convention we are sparing with the colours: ordinary word-processing
is not a kaleidoscopic experience (even when Microsoft Word's impertinent
grammar checker is accidentally left switched on), and we want the experience
of writing Inform source text to be like writing, not like programming.
So we use just a little colour, and that goes a long way.

Because the Inform applications generally syntax-colour source text in the
Source panel of the user interface, it is probably worth writing down the
lexical specification. There are eight basic categories of text, and
they should be detected in the following order, with the first category
that applies being the one to determine the colour and/or font weight:

(1) Titling text (primary source text only: not found in extensions).
If the first non-whitespace in the file is a double-quoted text (see (4a)),
this is the title of the work.

(2) Documentation text (extension text only: not found in primary source).
If a paragraph consists of a single non-whitespace token only, and that
token is |----| (four hyphens in a row), then this paragraph and all
subsequent text down to the bottom of the file.

(3) Heading text. If a paragraph consists of a single line only and which
begins with one of the five words Volume, Book, Part, Chapter or Section,
capitalised as here, then that paragraph is a heading. (A paragraph
division is found at the start and end of a file, and also at any run
of white space containing two or more newline characters: a newline
can be any of the Unicode characters |0x000A|, |0x2028| or |0x2029|.)

(4a) Quoted text. Outside of (4b) and (4c), a double-quotation mark
(in principle any of Unicode |0x0022|, |0x201C|, |0x201D|) begins
quoted text provided it follows either whitespace, or the start of
the file, or one of the punctuation marks in the |PUNCTUATION_MARKS|
string defined above. Quoted text continues until the next
double-quotation mark (or the end of the file if there isn't one,
though Inform would issue Problems if asked to compile this).

(4a1) Text substitution text. Within (4a) only, an open square bracket
introduced text substitution matter which continues until the next
close square bracket or the end of the quoted text. (Again, Inform would
issue problem messages if given a string malformed in this way.)

(4b) Comment text. Outside of (4a) and (4c), an open square bracket begins
comment. Comment continues until the next matching close square
bracket. (This is the case even if that is in double quotes within the
comment, i.e., quotation marks should be ignored when matching |[| and |]|
inside a comment.) Thus, nested comments are allowed, and the following
text contains a single comment running from just after "the" through to
the full stop:

>> |Snow White and the [Seven Dwarfs [but not Doc]].|

(4c) Literal I6 code. Outside of (4a) and (4b), the combination |(-| begins
literal I6 matter. This matter continues until the next |-)| is reached.
Within literal I6 matter, one can escape back into I7 source text using a
matched pair of |(+| and |+)| tokens, but it really doesn't seem worth
syntax colouring this very much. And the authors of Inform will lose no
sleep if we miscolour this, for instance, especially if it deters people
from such horrible coding practices:

>> |(- Constant BLOB = (+ the total weight of things in (- selfobj -) +); -)|

(5) Normal text. Everything else.

Inform regards all of the Unicode characters |0x0009|, |0x000A|, |0x000D|,
|0x0020|, |0x0085|, |0x00A0|, |0x02000| to |0x200A|, |0x2028| and |0x2029|
as instances of white space. Of course, it's entirely open to the Inform
user interfaces to not allow the user to key some of these codes, but
we should bear in mind that projects using them might be created on one
platform and then reopened on another one, so it's probably best to be
careful.

@ These categories of text are conventionally displayed as follows:

(1) Titling text: black boldface.

(2) Documentation text: grey type.

(3) Heading text: black boldface, perhaps of a slightly larger point
size.

(4a) Quoted text: dark blue boldface.

(4a1) Text substitution text: lighter blue and not boldface.

(4b) Comment text: darkish green type, perhaps of a slightly smaller point
size.

(4c) Literal I6 code: grey type. (Inform for OS X rather coolly goes into
I6 syntax-colouring, which is considerably harder, for this material:
see "The Inform 6 Technical Manual" for an algorithm.)

(5) Normal text: black type.

@h What the lexer stores for each word.
The lexer builds a small data structure for each individual word it reads.

=
typedef struct lexer_details {
	wchar_t *lw_text; /* text of word after treatment to normalise */
	wchar_t *lw_rawtext; /* original untouched text of word */
	struct source_location lw_source; /* where it was read from */
	int lw_break; /* the divider (space, tab, etc.) preceding it */
	struct vocabulary_entry *lw_identity; /* which distinct word */
} lexer_details;

lexer_details *lw_array = NULL; /* a dynamically allocated (and mobile) array */
int lexer_details_memory_allocated = 0; /* bytes allocated to this array */
int lexer_workspace_allocated = 0; /* bytes allocated to text storage */

@ The following bounds on how much we can read are immutable without
editing and recompiling Inform.

Some readers will be wondering about Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogochuchaf
(the upper old part of the village of Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch,
on the Welsh isle of Anglesey), but this has a mere 63 letters, and in any case
the name was "improved" by the village cobbler in the mid-19th century to
make it a tourist attraction for the new railway age.

@d TEXT_STORAGE_CHUNK_SIZE 600000 /* Must exceed |MAX_VERBATIM_LENGTH+MAX_WORD_LENGTH| */
@d MAX_VERBATIM_LENGTH 200000 /* Largest quantity of Inform 6 which can be quoted verbatim. */
@d MAX_WORD_LENGTH 128 /* Maximum length of any unquoted word */

@ The main text area of memory has a simple structure: it is allocated in
one contiguous block, and at any given time the memory is used from the
lowest address up to (but not including) the "high water mark", a pointer
in effect to the first free character.

=
wchar_t *lexer_workspace; /* Large area of contiguous memory for text */
wchar_t *lexer_word; /* Start of current word in workspace */
wchar_t *lexer_hwm; /* High water mark of workspace */
wchar_t *lexer_workspace_end; /* Pointer to just past the end of the workspace: HWM must not exceed this */

void Lexer::start(void) {
	lexer_wordcount = 0;
	Lexer::ensure_space_up_to(50000); /* the Standard Rules are about 44,000 words */
	Lexer::allocate_lexer_workspace_chunk(1);
	Vocabulary::start_hash_table();
}

@ These are quite hefty memory allocations, with the expensive one --
|lw_source| -- also being the least essential to Inform's running. But at least
we use memory in a way at least vaguely related to the size of the source
text, never using more than twice what we need, and we impose no absolute
upper limits.

=
int current_lw_array_size = 0, next_lw_array_size = 75000;

void Lexer::ensure_space_up_to(int n) {
	if (n < current_lw_array_size) return;
	int new_size = current_lw_array_size;
	while (n >= new_size) {
		new_size = next_lw_array_size;
		next_lw_array_size = next_lw_array_size*2;
	}
	lexer_details_memory_allocated = new_size*((int) sizeof(lexer_details));
	lexer_details *new_lw_array =
		((lexer_details *) (Memory::calloc(new_size, sizeof(lexer_details), LEXER_WORDS_MREASON)));

	if (new_lw_array == NULL) {
		Lexer::lexer_problem_handler(MEMORY_OUT_LEXERERROR, NULL, NULL);
		exit(1); /* in case the handler fails to do this */
	}
	for (int i=0; i<new_size; i++) {
		if (i < current_lw_array_size) new_lw_array[i] = lw_array[i];
		else {
			new_lw_array[i].lw_text = NULL;
			new_lw_array[i].lw_rawtext = NULL;
			new_lw_array[i].lw_break = ' ';
			new_lw_array[i].lw_source.file_of_origin = NULL;
			new_lw_array[i].lw_source.line_number = -1;
			new_lw_array[i].lw_identity = NULL;
		}
	}
	if (lw_array) Memory::I7_array_free(lw_array, LEXER_WORDS_MREASON,
		current_lw_array_size, ((int) sizeof(lexer_details)));
	lw_array = new_lw_array;
	current_lw_array_size = new_size;
}

@ Inform would almost certainly crash if we wrote past the end of the
workspace, so we need to watch for the water running high. The following
routine checks that there is room for another |n| characters, plus a
termination character, plus breathing space for a single character's worth
of lookahead:

=
void Lexer::ensure_lexer_hwm_can_be_raised_by(int n, int transfer_partial_word) {
	if (lexer_hwm + n + 2 >= lexer_workspace_end) {
		wchar_t *old_hwm = lexer_hwm;
		int m = 1;
		if (transfer_partial_word) {
			m = (((int) (old_hwm - lexer_word) + n + 3)/TEXT_STORAGE_CHUNK_SIZE) + 1;
			if (m < 1) m = 1;
		}
		Lexer::allocate_lexer_workspace_chunk(m);
		if (transfer_partial_word) {
			*(lexer_hwm++) = ' ';
			wchar_t *new_lword = lexer_hwm;
			while (lexer_word < old_hwm) {
				*(lexer_hwm++) = *(lexer_word++);
			}
			lexer_word = new_lword;
		}
		if (lexer_hwm + n + 2 >= lexer_workspace_end)
			internal_error("further allocation failed to liberate enough space");
	}
}

void Lexer::allocate_lexer_workspace_chunk(int multiplier) {
	int extent = multiplier * TEXT_STORAGE_CHUNK_SIZE;
	lexer_workspace = ((wchar_t *) (Memory::calloc(extent, sizeof(wchar_t), LEXER_TEXT_MREASON)));
	lexer_workspace_allocated += extent;
	lexer_hwm = lexer_workspace;
	lexer_workspace_end = lexer_workspace + extent;
}

@ We occasionally want to reprocess the text of a word again in higher-level
parsing, and it's convenient to use the lexer workspace to store the results
of such a reprocessed text. The following routine makes a persistent copy
of its argument, then: it should never be used while the lexer is actually
running.

=
wchar_t *Lexer::copy_to_memory(wchar_t *p) {
	Lexer::ensure_lexer_hwm_can_be_raised_by(Wide::len(p), FALSE);
	wchar_t *q = lexer_hwm;
	lexer_hwm = q + Wide::len(p) + 1;
	wcscpy(q, p);
	return q;
}

@h External lexer states.
The lexer is a finite state machine at heart. Its current state is the
collective value of an extensive set of variables, almost all of them
flags, but with three exceptions this state is used only within the lexer.

The three exceptional modes are by default both off and by default they
stay off: the lexer never goes into either mode by itself.

|lexer_divide_strings_at_text_substitutions| is used by some of the lexical writing-back
machinery,  when it has been decided to compile something like

>> say "[The noun] falls onto [the second noun]."

In its ordinary mode, with this setting off, the lexer will render this as
two words, the second being the entire quoted text. But if
|lexer_divide_strings_at_text_substitutions| is set then the text is reinterpreted as

>> say The noun, " falls onto ", the second noun, "."

which runs to eleven words, three of them commas (punctuation always counts
as a word).

|lexer_wait_for_dashes| is set by the extension-reading machinery, in
cases where it wants to get at the documentation text of an extension but
does not want to have to fill Inform's memory with the source text of its code.
In this mode, the lexer ignores the whole stream of words until it reaches
|----|, the special marker used in extensions to divide source text from
documentation: it then drops out of this mode and back into normal running,
so that subsequent words are lexed as usual.

=
wchar_t *lexer_punctuation_marks = L"";
int lexer_divide_strings_at_text_substitutions; /* Break up text substitutions in quoted text */
int lexer_allow_I6_escapes; /* Recognise |(-| and |-)| */
int lexer_wait_for_dashes; /* Ignore all text until first |----| found */

@h Definition of punctuation.
As we have seen, the question of whether something is a punctuation mark
or not depends slightly on the context:

=
int Lexer::is_punctuation(int c) {
	for (int i=0; lexer_punctuation_marks[i]; i++)
		if (c == lexer_punctuation_marks[i])
			return TRUE;
	return FALSE;
}

@h Definition of indentation.
We're going to record the level of indentation in the "break" character.
We will recognise anything from 1 to 25 tabs as distinct indentation amounts;
a value of 26 means "26 or more", and at such sizes, indentation isn't
distinguished. We'll do this with the letters |A| to |Z|.

@d GROSS_AMOUNT_OF_INDENTATION 26

=
int Lexer::indentation_level(int wn) {
	int q = lw_array[wn].lw_break - 'A' + 1;
	if ((q >= 1) && (q <= GROSS_AMOUNT_OF_INDENTATION)) return q;
	return 0;
}

int Lexer::break_char_for_indents(int t) {
	if (t <= 0) internal_error("bad indentation break");
	if (t >= 26) return 'Z';
	return 'A' + t - 1;
}

@h Access functions.

=
vocabulary_entry *Lexer::word(int wn) {
	return lw_array[wn].lw_identity;
}

void Lexer::set_word(int wn, vocabulary_entry *ve) {
	lw_array[wn].lw_identity = ve;
}

int Lexer::break_before(int wn) {
	return lw_array[wn].lw_break;
}

source_file *Lexer::file_of_origin(int wn) {
	return lw_array[wn].lw_source.file_of_origin;
}

source_location Lexer::word_location(int wn) {
	if (wn < 0) {
		source_location nowhere;
		nowhere.file_of_origin = NULL;
		nowhere.line_number = 0;
		return nowhere;
	}
	return lw_array[wn].lw_source;
}

void Lexer::set_word_location(int wn, source_location sl) {
	if (wn < 0) internal_error("can't set word location");
	lw_array[wn].lw_source = sl;
}

wchar_t *Lexer::word_raw_text(int wn) {
	return lw_array[wn].lw_rawtext;
}

void Lexer::set_word_raw_text(int wn, wchar_t *rt) {
	lw_array[wn].lw_rawtext = rt;
}

wchar_t *Lexer::word_text(int wn) {
	return lw_array[wn].lw_text;
}

void Lexer::set_word_text(int wn, wchar_t *rt) {
	lw_array[wn].lw_text = rt;
}

void Lexer::word_copy(int to, int from) {
	lw_array[to] = lw_array[from];
}

void Lexer::writer(OUTPUT_STREAM, char *format_string, int wn) {
	if ((wn < 0) || (wn >= lexer_wordcount)) return;
	switch (format_string[0]) {
		case '+': WRITE("%w", lw_array[wn].lw_rawtext); break;
		case '~':
			Word::compile_to_I6_dictionary(OUT, lw_array[wn].lw_text, FALSE);
			break;
		case '<':
			if (STREAM_USES_UTF8(OUT)) Streams::enable_XML_escapes(OUT);
			WRITE("%w", lw_array[wn].lw_rawtext);
			if (STREAM_USES_UTF8(OUT)) Streams::disable_XML_escapes(OUT);
			break;
		case 'N': WRITE("%w", lw_array[wn].lw_text); break;
		default: internal_error("bad %N extension");
	}
}

@h Definition of white space.
The following macro (to save time over a function call) is highly dangerous,
and of the kind which all books on C counsel against. If it were called with
any argument whose evaluation had side-effects, disaster would ensue.
It is therefore used only twice, with care, and only in this section below.

@d is_whitespace(c) ((c == ' ') || (c == '\n') || (c == '\t'))

@h Internal lexer states.
The current situation of the lexer is specified by the collective values
of all of the following. First, the start of the current word being
recorded, and the current high water mark -- those are defined above.
Second, we need the feeder machinery to maintain a variable telling us
the previous character in the raw, un-respaced source. We need to be a
little careful about the type of this: it needs to be an |int| so that it
can on occasion hold the pseudo-character value |EOF|.

=
int lxs_previous_char_in_raw_feed; /* Preceding character in raw file read */

@ There are four kinds of word: ordinary words, [comments in square brackets],
"strings in double quotes," and |(- I6_inclusion_text -)|. The latter
three are kinds are collectively called literals. As each word is read,
the variable |lxs_kind_of_word| holds what it is currently believed to be.

@d ORDINARY_KW 0
@d COMMENT_KW 1
@d STRING_KW 2
@d I6_INCLUSION_KW 3

=
int lxs_kind_of_word; /* One of the defined values above */

@ While there are a pile of state variables below, the basic situation is that
the lexer has two main modes: ordinary mode and literal mode, determined
by whether |lxs_literal_mode| is false or true. It might look as if this
variable is redundant -- can't we simply see whether |lxs_kind_of_word|
is |ORDINARY_KW| or not? -- but in fact we return to ordinary mode slightly
before we finish recording a literal, as we shall see, so it is important
to be able to switch in and out of literal mode without changing the kind
of word.

=
int lxs_literal_mode; /* Are we in literal or ordinary mode? */

/* significant in ordinary mode: */
int lxs_most_significant_space_char; /* Most significant whitespace character preceding */
int lxs_number_of_tab_stops; /* Number of consecutive tabs */
int lxs_this_line_is_empty_so_far; /* Current line white space so far? */
int lxs_this_word_is_empty_so_far; /* Looking for a word to start? */
int lxs_scanning_text_substitution; /* Used to break up strings at [substitutions] */

/* significant in literal mode: */
int lxs_comment_nesting; /* For square brackets within square brackets */
int lxs_string_soak_up_spaces_mode; /* Used to fold strings which break across lines */

@ The lexer needs to be reset each time it is used on a given feed of text,
whether from a file or internally. Note that this resets both external
and internal states to their defaults (the default for external states
always being "off").

=
void Lexer::reset_lexer(void) {
	lexer_word = lexer_hwm;
	lxs_previous_char_in_raw_feed = EOF;

    /* reset the external states */
    lexer_wait_for_dashes = FALSE;
    lexer_punctuation_marks = STANDARD_PUNCTUATION_MARKS;
	lexer_divide_strings_at_text_substitutions = FALSE;
	lexer_allow_I6_escapes = TRUE;

    /* reset the internal states */
	lxs_most_significant_space_char = '\n'; /* we imagine each lexer feed starting a new line */
	lxs_number_of_tab_stops = 0; /* but not yet indented with tabs */

	lxs_this_line_is_empty_so_far = TRUE; /* clearly */
	lxs_this_word_is_empty_so_far = TRUE; /* likewise */

	lxs_literal_mode = FALSE; /* begin in ordinary mode... */
	lxs_kind_of_word = ORDINARY_KW; /* ...expecting an ordinary word */
	lxs_string_soak_up_spaces_mode = FALSE;
	lxs_scanning_text_substitution = FALSE;
	lxs_comment_nesting = 0;
}

@h Feeding the lexer.
The lexer takes its input as a stream of characters, sent from a "feeder
routine": there are two of these, one sending the stream from a file, the
other from a C string. A feeder routine is required to:

(1) call |Lexer::feed_begins| before sending the first character,

(2) send ISO Latin-1 characters which also exist in ZSCII, in sequence,
via |Lexer::feed_triplet|,

(3) conclude by calling |Lexer::feed_ends|.

Only one feeder can be active at a time, as the following routines ensure.

=
int lexer_feed_started_at = -1;

void Lexer::feed_begins(source_location sl) {
    if (lexer_feed_started_at >= 0) internal_error("one lexer feeder interrupted another");
    lexer_feed_started_at = lexer_wordcount;
    lexer_position = sl;
    Lexer::reset_lexer();
    LOGIF(LEXICAL_OUTPUT, "Lexer feed began at %d\n", lexer_feed_started_at);
}

wording Lexer::feed_ends(int extra_padding, text_stream *problem_source_description) {
    if (lexer_feed_started_at == -1) internal_error("lexer feeder ended without starting");

    @<Feed whitespace as padding@>;

    wording RRW = EMPTY_WORDING;
	if (lexer_feed_started_at < lexer_wordcount)
		RRW = Wordings::new(lexer_feed_started_at, lexer_wordcount-1);
    lexer_feed_started_at = -1;
    LOGIF(LEXICAL_OUTPUT, "Lexer feed ended at %d\n", Wordings::first_wn(RRW));
    @<Issue Problem messages if feed ended in the middle of quoted text, comment or verbatim I6@>;
    return RRW;
}

@ White space padding guarantees that a word running right up to the end of
the feed will be processed, since (outside literal mode) that white space
signals to the lexer that a word is complete. (If we are in literal mode at
the end of the feed, problem messages are produced. We code Inform to ensure
that this never occurs when feeding our own C strings through.)

At the end of each complete file, we also want to ensure there is always a
paragraph break, because this simplifies the parsing of headings (which in
turn is because a file boundary counts as a super-heading-break, and headings
are only detected as stand-alone paragraphs). We add a bit more white
space than is strictly necessary, because it saves worrying about whether
it is safe to look ahead to characters further on in the lexer's workspace
when we are close to the high water mark, and because it means that a source
file which is empty or contains only a byte-order marker comes out as at
least one paragraph, even if a blank one.

@<Feed whitespace as padding@> =
    if (extra_padding == FALSE) {
        Lexer::feed_char_into_lexer(' ');
    } else {
        Lexer::feed_char_into_lexer(' ');
        Lexer::feed_char_into_lexer('\n');
        Lexer::feed_char_into_lexer('\n');
        Lexer::feed_char_into_lexer('\n');
        Lexer::feed_char_into_lexer('\n');
        Lexer::feed_char_into_lexer(' ');
    }

@ These problem messages can, of course, never result from text which Inform
is feeding into the lexer itself, independently of source files. That would
be a bug, and Inform is bug-free, so it follows that it could never happen.

@e MEMORY_OUT_LEXERERROR from 0
@e STRING_NEVER_ENDS_LEXERERROR
@e COMMENT_NEVER_ENDS_LEXERERROR
@e I6_NEVER_ENDS_LEXERERROR

@<Issue Problem messages if feed ended in the middle of quoted text, comment or verbatim I6@> =
    if (lxs_kind_of_word != ORDINARY_KW) {
    	if (lexer_wordcount >= 20) {
	    	LOG("Last words: %W\n", Wordings::new(lexer_wordcount-20, lexer_wordcount-1));
	    } else if (lexer_wordcount >= 1) {
	        LOG("Last words: %W\n", Wordings::new(0, lexer_wordcount-1));
	    } else {
	        LOG("No words recorded\n");
        }
    }
    if (lxs_kind_of_word == STRING_KW)
    	Lexer::lexer_problem_handler(STRING_NEVER_ENDS_LEXERERROR, problem_source_description, NULL);
    if (lxs_kind_of_word == COMMENT_KW)
    	Lexer::lexer_problem_handler(COMMENT_NEVER_ENDS_LEXERERROR, problem_source_description, NULL);
    if (lxs_kind_of_word == I6_INCLUSION_KW)
    	Lexer::lexer_problem_handler(I6_NEVER_ENDS_LEXERERROR, problem_source_description, NULL);
    lxs_kind_of_word = ORDINARY_KW;

@ The feeder routine is required to send us a triple each time: |cr|
must be a valid character (see above) and may not be |EOF|; |last_cr| must
be the previous one or else perhaps |EOF| at the start of feed;
while |next_cr| must be the next or else perhaps |EOF| at the end of feed.

Spaces, often redundant, are inserted around punctuation unless one of the
following exceptions holds:

The lexer is in literal mode (inside strings, for instance);

Where a single punctuation mark occurs in between two digits, or between
a digit and a minus sign, or (in the case of full stops) between two lower-case
alphanumeric characters. This is done so that, for instance, "0.91" does
not split into three words in the lexer. We do not count square brackets
here, because if we did, that would cause trouble in parsing

>> say "[if M is less than 10]0[otherwise]1";

where the |0]0| would go unbroken in |lexer_divide_strings_at_text_substitutions|
mode, and therefore the |]| would remain glued to the preceding text;

Where the character following is a slash. (This is done essentially to make
most common URLs glue up as single words.)

=
void Lexer::feed_triplet(int last_cr, int cr, int next_cr) {
	lxs_previous_char_in_raw_feed = last_cr;
	int space = FALSE;
	if (Lexer::is_punctuation(cr)) space = TRUE;
	if ((space) && (lxs_literal_mode)) space = FALSE;
	if ((space) && (cr != '[') && (cr != ']')) {
		if ((space) && (next_cr == '/')) space = FALSE;
		if (space) {
			int lc = 0, nc = 0;
			if (Characters::isdigit(last_cr)) lc = 1;
			if ((last_cr >= 'a') && (last_cr <= 'z')) lc = 2;
			if (Characters::isdigit(next_cr)) nc = 1;
			if (next_cr == '-') nc = 1;
			if ((next_cr >= 'a') && (next_cr <= 'z')) nc = 2;
			if ((lc == 1) && (nc == 1)) space = FALSE;
			if ((cr == '.') && (lc > 0) && (nc > 0)) space = FALSE;
		}
	}
	if (space) {
		Lexer::feed_char_into_lexer(' ');
		Lexer::feed_char_into_lexer(cr); /* which might take us into literal mode, so to be careful... */
		if (lxs_literal_mode == FALSE) Lexer::feed_char_into_lexer(' ');
	} else Lexer::feed_char_into_lexer(cr);

	if ((cr == '\n') && (lexer_position.file_of_origin))
		lexer_position.line_number++;
}

@h Lexing one character at a time.
We can think of characters as a stream of differently-coloured marbles,
flowing from various sources into a hopper above our marble-sorting
machine. The hopper lets the marbles drop through one at a time into the
mechanism below, but inserts transparent glass marbles of its own on either
side of certain colours of marble, so that the sequence of marbles entering
the mechanism is no longer the same as that which entered the hopper.
Moreover, the mechanism can itself cause extra marbles of its choice to
drop in from time to time, further interrupting the original flow.

The following routine is the mechanism which receives the marbles. We want
the marbles to run swiftly through and either be pulverised to glass
powder, or dropped into the output bucket, as the mechanism chooses.
(Whatever marbles from the original source survive will always emerge in
their original order, though.) Every so often the mechanism decides that it
has completed one batch, and moves on to dropping marbles into the next
bucket.

The marbles are characters; transparent glass ones are whitespace, which
will always now be |' '|, |'\t'| or |'\n'|; the routine
|Lexer::feed_triplet| above was the hopper; the routine
|Lexer::feed_char_into_lexer|, which occupies the whole of the rest of this
section, is the mechanism which takes each marble in turn. (On occasion it
calls itself recursively to cause extra characters of its choice to drop
in.) The batches are words, and the bucket receiving the surviving marbles
is the sequence of characters starting at |lexer_word| and extending to
|lexer_hwm-1|.

=
void Lexer::feed_char_into_lexer(int c) {
	Lexer::ensure_lexer_hwm_can_be_raised_by(MAX_WORD_LENGTH, TRUE);

	if (lxs_literal_mode) {
	    @<Contemplate leaving literal mode@>;
    	if (lxs_kind_of_word == STRING_KW) {
    	    @<Force string division at the start of a text substitution, if necessary@>;
	        @<Soak up whitespace around line breaks inside a literal string@>;
	    }
	}

    /* whitespace outside literal mode ends any partly built word and need not be recorded */
	if ((lxs_literal_mode == FALSE) && (is_whitespace(c))) {
	    @<Admire the texture of the whitespace@>;
	    if (lexer_word != lexer_hwm) @<Complete the current word@>;
		if (c == '\n') @<Line break outside a literal@>;
		return;
	}

    /* otherwise record the current character as part of the word being built */
	*(lexer_hwm++) = c;

    if (lxs_scanning_text_substitution) {
        @<Force string division at the end of a text substitution, if necessary@>;
    }

	if (lxs_this_word_is_empty_so_far) {
    	@<Look at recent whitespace to see what break it followed@>;
	    @<Contemplate entering literal mode@>;
    }

	lxs_this_word_is_empty_so_far = FALSE;
	lxs_this_line_is_empty_so_far = FALSE;
}

@h Dealing with whitespace.
Let's deal with the different textures of whitespace first, as these are
surprisingly rich all by themselves.

The following keeps track of the biggest white space character it has seen
of late, ranking newlines bigger than tabs, which are in turn bigger than
spaces; and it counts up the number of tabs it has seen (cancelling
back to none if a newline is found).

@<Admire the texture of the whitespace@> =
	if (c == '\t') {
        lxs_number_of_tab_stops++;
	    if (lxs_most_significant_space_char != '\n') lxs_most_significant_space_char = '\t';
	}
	if (c == '\n') {
	    lxs_number_of_tab_stops = 0;
		lxs_most_significant_space_char = '\n';
    }

@ To recall: we need to know what kind of whitespace prefaces each word
the lexer records.

When we record the first character of a new word, it cannot be whitespace,
but it probably follows a sequence of one or more whitespace characters,
and the code in the previous paragraph has been watching them for us.

@<Look at recent whitespace to see what break it followed@> =
    if ((lxs_most_significant_space_char == '\n') && (lxs_number_of_tab_stops >= 1))
    	lw_array[lexer_wordcount].lw_break =
    		Lexer::break_char_for_indents(lxs_number_of_tab_stops); /* newline followed by 1 or more tabs */
    else
        lw_array[lexer_wordcount].lw_break = lxs_most_significant_space_char;

    lxs_most_significant_space_char = ' '; /* waiting for the next run of whitespace, after this word */
    lxs_number_of_tab_stops = 0;

@ Line breaks are usually like any other white space, if we are outside
literal mode, but we want to keep an eye out for paragraph breaks, because
these are sometimes semantically meaningful in Inform and so cannot be
discarded. A paragraph break is converted into a special "divider" word.

@<Line break outside a literal@> =
	if (lxs_this_line_is_empty_so_far) {
		for (int i=0; PARAGRAPH_BREAK[i]; i++)
			Lexer::feed_char_into_lexer(PARAGRAPH_BREAK[i]);
		Lexer::feed_char_into_lexer(' ');
	}
	lxs_this_line_is_empty_so_far = TRUE;

@ When working through a literal string, a new-line together with any
preceding whitespace is converted into a single space character, and we
enter "soak up spaces" mode: in which mode, any subsequent whitespace is
ignored until something else is reached. If we reach another new-line while
still soaking up, then the literal text contained a paragraph break. In
this instance, the splurge of whitespace is converted not to a single
space |" "| but to two forced newlines in quick succession. In other words,
paragraph breaks in literal strings are converted to codes which will make
Inform print a paragraph break at run-time.

@<Soak up whitespace around line breaks inside a literal string@> =
    if (lxs_string_soak_up_spaces_mode) {
        switch(c) {
            case ' ': case '\t': c = *(lexer_hwm-1); lexer_hwm--; break;
            case '\n':
                *(lexer_hwm-1) = NEWLINE_IN_STRING;
                c = NEWLINE_IN_STRING;
                break;
            default: lxs_string_soak_up_spaces_mode = FALSE; break;
        }
    }
    if (c == '\n') {
        while (is_whitespace(*(lexer_hwm-1))) lexer_hwm--;
        lxs_string_soak_up_spaces_mode = TRUE;
    }

@h Completing a word.
Outside of whitespace, then, our word (whatever it was -- ordinary word,
literal string, I6 insertion or comment) has been stored character by
character at the steadily rising high water mark. We have now hit the end
by reaching whitespace (in the case of a literal, this has happened because
we found the end of the literal, escaped literal mode, and then hit
whitespace). The start of the word is at |lexer_word|; the last character
is stored just below |lexer_hwm|.

@<Complete the current word@> =
    *lexer_hwm++ = 0; /* terminate the current word as a C string */

    if ((lexer_wait_for_dashes) && (Wide::cmp(lexer_word, L"----") == 0))
        lexer_wait_for_dashes = FALSE; /* our long wait for documentation is over */

    if ((lexer_wait_for_dashes == FALSE) && (lxs_kind_of_word != COMMENT_KW)) {
        @<Issue problem message and truncate if over maximum length for what it is@>;
        @<Store everything about the word except its break, which we already know@>;
    }

    /* now get ready for what we expect by default to be an ordinary word next */
	lexer_word = lexer_hwm;
	lxs_this_word_is_empty_so_far = TRUE;
    lxs_kind_of_word = ORDINARY_KW;

@ Note that here we are recording either an ordinary word, a literal string
or a literal I6 insertion: comments are also literal, but are thrown away,
and do not come here.

@d MAX_STRING_LENGTH 8*1024

@e STRING_TOO_LONG_LEXERERROR
@e WORD_TOO_LONG_LEXERERROR
@e I6_TOO_LONG_LEXERERROR

@<Issue problem message and truncate if over maximum length for what it is@> =
    int len = Wide::len(lexer_word), max_len = MAX_WORD_LENGTH;
    if (lxs_kind_of_word == STRING_KW) max_len = MAX_STRING_LENGTH;
    if (lxs_kind_of_word == I6_INCLUSION_KW) max_len = MAX_VERBATIM_LENGTH;

    if (len > max_len) {
        lexer_word[max_len] = 0; /* truncate to its maximum length */
		if (lxs_kind_of_word == STRING_KW) {
			Lexer::lexer_problem_handler(STRING_TOO_LONG_LEXERERROR, NULL, lexer_word);
		} else if (lxs_kind_of_word == I6_INCLUSION_KW) {
			lexer_word[100] = 0; /* to avoid an absurdly long problem message */
			Lexer::lexer_problem_handler(I6_TOO_LONG_LEXERERROR, NULL, lexer_word);
		} else {
			Lexer::lexer_problem_handler(WORD_TOO_LONG_LEXERERROR, NULL, lexer_word);
		}
    }

@ We recorded the break for the word when it started (recall that, even if
the current word is a literal, its first character was read outside literal
mode, so it started out in life as an ordinary word and therefore had its
break recorded). So now we need to set everything else about it, and to
increment the word-count. We must not allow this to reach its maximum,
since this would allow the next word's break setting to overwrite the
array.

For ordinary words (but not literals), the copy of a word in the main array
|lw_text| is lowered in case. The original is preserved in |lw_rawtext| and
is used to print more attractive error messages, and also to enable a few
semantic parts of Inform to be case sensitive. This copying means that in the
worst case -- when we complete an ordinary word of maximal length -- we need
to consume an additional |MAX_WORD_LENGTH+2| bytes of the lexer's workspace,
which is why that was the amount we checked to ensure existed when the
lexer was called. The lowering loop can therefore never overspill the
workspace.

@<Store everything about the word except its break, which we already know@> =
    lw_array[lexer_wordcount].lw_rawtext = lexer_word;
    lw_array[lexer_wordcount].lw_source = lexer_position;

    if (lxs_kind_of_word == ORDINARY_KW) {
        int i;
        lw_array[lexer_wordcount].lw_text = lexer_hwm;
        for (i=0; lexer_word[i]; i++) *(lexer_hwm++) = Characters::tolower(lexer_word[i]);
        *(lexer_hwm++) = 0;
    } else {
        lw_array[lexer_wordcount].lw_text = lw_array[lexer_wordcount].lw_rawtext;
    }

    Vocabulary::identify_word(lexer_wordcount); /* which sets |lw_array[lexer_wordcount].lw_identity| */

    lexer_wordcount++;
    Lexer::ensure_space_up_to(lexer_wordcount);

@h Entering and leaving literal mode.
After a character has been stored, in ordinary mode, we see if it
provokes us into entering literal mode, by signifying the start of a
comment, string or passage of verbatim Inform 6.

In the case of a string, we positively want to keep the opening character
just recorded as part of the word: it's the opening double-quote mark.
In the case of a comment, we don't care, as we're going to throw it away
anyhow; as it happens, we keep it for now. But in the case of an I6
escape we are in danger, because of the auto-spacing around brackets, of
recording two words

>> |( -something|

when in fact we want to record

>> |(- something|

We do this by adding a hyphen to the previous word (the |(| word), and by
throwing away the hyphen from the material of the current word.

@<Contemplate entering literal mode@> =
    switch(c) {
        case COMMENT_BEGIN:
            lxs_literal_mode = TRUE; lxs_kind_of_word = COMMENT_KW;
            lxs_comment_nesting = 1;
            break;
        case STRING_BEGIN:
            lxs_literal_mode = TRUE; lxs_kind_of_word = STRING_KW;
            break;
        case INFORM6_ESCAPE_BEGIN_2:
            if ((lxs_previous_char_in_raw_feed != INFORM6_ESCAPE_BEGIN_1) ||
            	(lexer_allow_I6_escapes == FALSE)) break;
            lxs_literal_mode = TRUE; lxs_kind_of_word = I6_INCLUSION_KW;
            /* because of spacing around punctuation outside literal mode, the |(| became a word */
            if (lexer_wordcount > 0) { /* this should always be true: just being cautious */
                lw_array[lexer_wordcount-1].lw_text = L"(-"; /* change the previous word's text from |(| to |(-| */
                lw_array[lexer_wordcount-1].lw_rawtext = L"(-";
                Vocabulary::identify_word(lexer_wordcount-1); /* and re-identify */
            }
            lexer_hwm--; /* erase the just-recorded |INFORM6_ESCAPE_BEGIN_2| character */
            break;
    }

@ So literal mode is used for comments, strings and verbatim passages of
Inform 6 code. We are in this mode when scanning only the middle of
the literal: after all, we scanned (and recorded) the start of the literal
in ordinary mode, before noticing that the character(s) marked the onset of
a literal.

Note that, when we leave literal mode, we set the current character to a
space. This means the character forcing our departure is lost and not
recorded: but we only actually want it in the case of strings (because
we prefer to record them in the form |"frogs and lilies"| rather than
|"frogs and lilies|, for tidiness's sake). And so for strings we explicitly
record a close quotation mark.

The new current character, being a space and thus whitespace outside of
literal mode, triggers the completion of the word, recording whatever
literal we have just made. (Or, if it was a comment, discarding it.)
|lxs_kind_of_word| continues to hold the kind of literal we have just
finished.

@<Contemplate leaving literal mode@> =
    switch(lxs_kind_of_word) {
        case COMMENT_KW:
    		if (c == COMMENT_BEGIN) lxs_comment_nesting++;
	    	if (c == COMMENT_END) {
	    	    lxs_comment_nesting--;
	    	    if (lxs_comment_nesting == 0) lxs_literal_mode = FALSE;
	    	}
            break;
        case STRING_KW:
            if (c == STRING_END) {
                lxs_string_soak_up_spaces_mode = FALSE;
                *(lexer_hwm++) = c; /* record the |STRING_END| character as part of the word */
                lxs_literal_mode = FALSE;
            }
            break;
        case I6_INCLUSION_KW:
            if ((c == INFORM6_ESCAPE_END_2) &&
                (lxs_previous_char_in_raw_feed == INFORM6_ESCAPE_END_1)) {
                lexer_hwm--; /* erase the |INFORM6_ESCAPE_END_1| character recorded last time */
                lxs_literal_mode = FALSE;
            }
            break;
        default: internal_error("in unknown literal mode");
    }
	if (lxs_literal_mode == FALSE) c = ' '; /* trigger completion of this word */

@h Breaking strings up at text substitutions.
When text contains text substitutions, these are ordinarily ignored by the
lexer, but in |lexer_divide_strings_at_text_substitutions| mode, we need to
force strings to end and resume at the two ends of each substitution. For
instance:

>> "Hello, [greeted person]. Do you make it [supper time]?"

must be split as

>> |"Hello, " , greeted person , ". Do you make it " , supper time , "?"|

where our original single text literal is now three text literals, plus
eight ordinary words (four of them commas).

Note that each open square bracket, and each close square bracket, has been
removed and become a comma word. We see to open squares before we come
to recording the character, so to get rid of the |[| character, we change
|c| to a space:

@<Force string division at the start of a text substitution, if necessary@> =
    if ((lexer_divide_strings_at_text_substitutions) && (c == TEXT_SUBSTITUTION_BEGIN)) {
        Lexer::feed_char_into_lexer(STRING_END); /* feed |"| to close the old string */
        Lexer::feed_char_into_lexer(' ');
        Lexer::feed_char_into_lexer(TEXT_SUBSTITUTION_SEPARATOR); /* feed |,| to start new word */
        c = ' '; /* the lexer now goes on to record a space, which will end the |,| word */
        lxs_scanning_text_substitution = TRUE; /* but remember that we must get back again */
    }

@ Whereas we see to close squares after recording the character, so we have
to erase it to get rid of the |]|. Note that since this was read in ordinary
mode, it was automatically spaced (being punctuation), and that therefore
the feeder above has just sent the second of a sequence of three characters:
space, |]|, space. That means we have recorded, so far, a one-character
word in ordinary mode, whose text consists only of |]|. By overwriting
this with a comma, we instead get a one-character word in ordinary mode
whose text consists only of a comma. We then feed a space to end that word;
then feed a double-quote to start text again.

But, it might be objected: surely the feeder above is still poised with
that third character in its sequence space, |]|, space, and that means
it will now feed a spurious space into the start of our resumed text?
Happily, the answer is no: this is why the feeder above checks that it
is still in ordinary mode before sending that third character. Having
open quotes again, we have put the lexer into literal mode: and so the
spurious space is never fed, and there is no problem.

@<Force string division at the end of a text substitution, if necessary@> =
    if ((lexer_divide_strings_at_text_substitutions) && (c == TEXT_SUBSTITUTION_END)) {
        lxs_scanning_text_substitution = FALSE;
		*(lexer_hwm-1) = TEXT_SUBSTITUTION_SEPARATOR; /* overwrite recorded copy of |]| with |,| */
		Lexer::feed_char_into_lexer(' '); /* then feed a space to end the |,| word */
		Lexer::feed_char_into_lexer(STRING_BEGIN); /* then feed |"| to open a new string */
	}

@ Finally, note that the breaking-up process may result in empty strings
where square brackets abut each other or the ends of the original string.
Thus

>> "[The noun] is on the [colour][style] table."

is split as: |"" , The noun , " is on the " , colour , "" , style , " table."|
This is not a bug: empty strings are legal. It's for higher-level code to
remove them if they aren't wanted.

@h Splicing.
Once in a while, we need to have a run of words in the lexer which
all do occur in the source text, but not contiguously, so that they
cannot be represented by a pair |(w1, w2)|. In that event we use the
following routine to splice duplicate references at the end of the word
list (this does not duplicate the text itself, only references to it):
for instance, if we start with 10 words (0 to 9) and then splice |(2,3)|
and then |(6,8)|, we end up with 15 words, and the text of |(10,14)|
contains the same material as words 2, 3, 6, 7, 8.

=
wording Lexer::splice_words(wording W) {
	int L = Wordings::length(W);
	Lexer::ensure_space_up_to(lexer_wordcount + L);
	for (int i=0; i<L; i++)
		Lexer::word_copy(lexer_wordcount+i, Wordings::first_wn(W)+i);
	wording N = Wordings::new(lexer_wordcount, lexer_wordcount + L - 1);
	lexer_wordcount += L;
	return N;
}

@h Basic command-line error handler.
Some tools using this module will want to push simple error messages out to
the command line; others will want to translate them into elaborate problem
texts in HTML. So the client is allowed to define |PROBLEM_WORDS_CALLBACK|
to some routine of her own, gazumping this one.

=
void Lexer::lexer_problem_handler(int err, text_stream *details, wchar_t *word) {
	#ifdef PROBLEM_WORDS_CALLBACK
	PROBLEM_WORDS_CALLBACK(err, details, word);
	#endif
	#ifndef PROBLEM_WORDS_CALLBACK
	if (err == MEMORY_OUT_LEXERERROR)
		Errors::fatal("Out of memory: unable to create lexer workspace");
	TEMPORARY_TEXT(word_t);
	if (word) WRITE_TO(word_t, "%w", word);
	switch (err) {
		case STRING_TOO_LONG_LEXERERROR:
			Errors::with_text("Too much text in quotation marks: %S", word_t);
            break;
		case WORD_TOO_LONG_LEXERERROR:
			Errors::with_text("Word too long: %S", word_t);
			break;
		case I6_TOO_LONG_LEXERERROR:
			Errors::with_text("I6 inclusion too long: %S", word_t);
			break;
		case STRING_NEVER_ENDS_LEXERERROR:
			Errors::with_text("Quoted text never ends: %S", details);
			break;
		case COMMENT_NEVER_ENDS_LEXERERROR:
			Errors::with_text("Square-bracketed text never ends: %S", details);
			break;
		case I6_NEVER_ENDS_LEXERERROR:
			Errors::with_text("I6 inclusion text never ends: %S", details);
			break;
		default:
			internal_error("unknown lexer error");
    }
	DISCARD_TEXT(word_t);
	#endif
}

@h Logging absolutely everything.
This is not to be done lightly: the output can be enormous.

=
void Lexer::log_lexer_output(void) {
	LOG("Entire lexer output to date:\n");
	for (int i=0; i<lexer_wordcount; i++)
		LOG("%d: <%+N> <%N> <%02x>\n", i, i, i, Lexer::break_before(i));
	LOG("------\n");
}
