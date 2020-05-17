What This Module Does.

An overview of the words module's role and abilities.

@h Prerequisites.
The words module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than |add_by_name|.
(c) This module uses other modules drawn from the //compiler//, and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Words, words, words.
Natural language text for use with Inform begins as text files written by
human users, which are fed into the "lexer" (i.e., lexical analyser).
The function //TextFromFiles::feed_open_file_into_lexer// reads such a file,
converting it to a numbered stream of words. For indexing and error reporting
purposes, we must not forget where these words came from: the function returns
a //source_file// object representing the file as an origin, and the lexer
assigns each word a //source_location// which is simply its SF together with
a line number. //Lexer::word_location// returns this for a given word number.

Word numbers count upwards from 1 and are contiguous: for example --
= (text)
	Mary had a  little lamb .   Everywhere that Mary went ,  the lamb
	17   18  19 20     21   22  23         24   25   26   27 28  29
=
Repetitions are frequent: a typical source text of 50,000 words has an
unquoted[1] vocabulary of only about 2000 different words. Inform generates
a //vocabulary_entry// object for each of these distinct words, and //Lexer::word//
returns the VE for a given word number. In the above example,
= (text as InC)
	Lexer::word(17) == Lexer::word(25)   /* both are uses of "Mary" */
	Lexer::word(21) == Lexer::word(29)   /* both are uses of "lamb" */
	Lexer::word(20) != Lexer::word(24)   /* one is "little", the other "that" */
=
The important point is that words at two positions can be tested for textual
equality in an essentially instant process, by comparing |vocabulary_entry *|
pointers. (See //Numbered Words// for just this sort of comparison.)

Nothing in life is free, and building the vocabulary efficiently is itself a
challenge: see //Vocabulary::hash_code_from_word//. The key function is
//Vocabulary::entry_for_text//, which takes a wide C string for a word and
returns its //vocabulary_entry//. There are also issues with casing: in
general we want "Lamb" and "lamb" to match, but not always.

[1] A piece of text in double-quotes is treated as a single word by the lexer,
although //inform7// may later unroll text substitutions in it, calling the
lexer again to do that.

@ A few //vocabulary_entry// objects are hardwired into //words//, but only
for punctuation. These have names like |COMMA_V|, which means just what you
think it means. In our example,
= (text as InC)
	Lexer::word(27) == COMMA_V   /* the comma between "went" and "the" */
=
See //Vocabulary::create_punctuation//, and also //LoadPreform::create_punctuation//,
where further punctuation marks are created in order to parse Preform syntax --
there are exotica such as |COLONCOLONEQUALS_V| there, for "::=".

@ Lexical errors occur if words are too long, or quoted text continues without
a close quote right to the end of a file, and so on. These are sent to the
function //Lexer::lexer_problem_handler//, but can be intercepted by the
user (see //How To Include This Module//).

@h Meaning codes.
Each //vocabulary_entry// has a bitmap of |*_MC| meaning codes assigned to it.
(And //Vocabulary::test_flags// tests whether the Nth word has a given bit.)
For example, |ORDINAL_MC| is applied to ordinal numbers like "sixth" or "15th"
-- see //Vocabulary::an_ordinal_number//, and |NUMBER_MC| to cardinals. The
//words// module uses only a few bits in this map, but the //linguistics//
module develops the idea much further: for example, any word which can be used
in a particular semantic category -- say, in a variable name -- is marked
with a bit representing that -- say, |VARIABLE_MC|. The //core// module
uses this for 15 or so of the most commonly used semantic categories in the
Inform language. See //linguistics: What This Module Does// to pick up the story.

@h Contiguous runs of words.
Natural languages are fundamentally unlike programming languages because a noun
referring to, say, a variable is rarely a single lexical token. In C, a variable
name like |selected_lamb| is one lexical unit. For us, though, "a little lamb"
is three words.

However, multi-word snippets of text which have a joint meaning are almost
always contiguous. The text "a little lamb" is word numbers 19, 20, 21. We
deal with this using the //wording// type: it's essentially a pair of integers,
|(19, 21)|, and thus is very quick to form, compare, copy and pass as a
parameter. //Wordings// provides an extensive API for this.

@h Hypothetical words.
Sometimes Inform needs to make hypothetical passages of text. For example,
suppose there is a kind called "paint colour" in the source text; Inform may
then want to create a variable called "paint colour understood". But this text
may not occur as such anywhere in the source.

If all the words needed are in the source somewhere, but not together, the user
of the //words// module has two options:

(*) Create a //word_assemblage// object. This can represent any discontiguous
list of word numbers: thus, the text "lamb went everywhere" could be a WA
of numbers (21, 26, 23) in our example above.
(*) Use //Lexer::splice_words// to create duplicate snippets of text in the
word stream, with new numbers. For example, call this on "lamb", then "went",
then "everywhere"; the three new word numbers will then be contiguous, and
can be represented by a //wording//:
= (text)
	Mary had a  little lamb .   Everywhere that Mary went ,  the lamb lamb went everywhere
	17   18  19 20     21   22  23         24   25   26   27 28  29   30   31   32
=

If however we want to make "lamb tian with haricot beans", we need to use the
Lexer's ability to read text internally as well as from external files. This
is called a "feed": see //Feeds//. In particular, //Feeds::feed_text// will
take the text |I"tian with haricot beans"|, treat this as fresh text for
lexing so that we now have
= (text)
	... ,  the lamb lamb went everywhere tian with haricot beans
	... 27 28  29   30   31   32         34   35   36      37
=
and now the word assemblage (21, 34, 35, 36, 37) would indeed represent "lamb
tian with haricot beans". The return value of //Feeds::feed_text// is the
//wording// (34, 37).

These new words do not originate in a file; their //source_location// therefore
has a null //source_file//. Words which have been spliced, however, and thus
duplicated in the word stream (like "lamb went everywhere", 30-32), retain
their original origins.

@h Rock, paper, scissors.
We now have three ways to represent text which may contain multiple words:
as a |text_stream|, as a |wording|, as a |word_assemblage|. Each can be
converted into the other two:

(*) Use //Feeds::feed_text// to turn a |text_stream| to a |wording|.
(*) Use //WordAssemblages::from_wording// to turn a |wording| to a |word_assemblage|.
(*) Use //WordAssemblages::to_wording// to turn a |word_assemblage| to a |wording|.
(*) Use //Wordings::writer// or use the formatted |WRITE| escape |%W| to
write a |wording| into a |text_stream|.
(*) Use //WordAssemblages::writer// or use the formatted |WRITE| escape |%A| to
write a |word_assemblage| into a |text_stream|.

As a general design goal, all Inform code uses //wording// to identify names
of things: this is fastest and most efficient on memory.

@h Traditional identifiers.
Imagine you're a compiler turning natural language into some sort of computer
code, just hypothetically: then you probably want "a little lamb" to come out
as a named location in memory, or object, or something like that: and this name
must be a valid identifier for some other compiler or assembler -- alphanumeric,
not too long, and so on. Calling it "a little lamb" is not an option.

You could of course name it |ref_15A40F|, or some such, because the user will
never see it anyway, so why have a helpful name? But that won't make debugging
your output easy. The function //Identifiers::compose// therefore takes a
wording and a unique ID number and makes something sensible: |I15_a_little_lamb|,
say.

@h Preform.
Preform is a meta-language for writing a simple grammar: it's in some sense
pre-Inform, because it defines the Inform language itself. See //About Preform//.

Compilers are a little like the human body, in that most of their organs can
be located in a single spot: the heart, for example, or the gall bladder.
Or in the case of Inform, the //Lexer//. But a few organs of the body -- like
the nervous system, or blood vessels -- are found almost everywhere in the
body, and the Inform syntax analyser is like that. While the basic code which
drives this is in //Preform// and in the //syntax// module, the actual
syntax being read is in many, many different places. Such syntax has a notation
like so:
= (text as Preform)
	<competitor> ::=
		<ordinal-number> runner |    ==> TRUE
		runner no <cardinal-number>  ==> FALSE
=
This notation is mixed in with regular C code in many sections of the
//core// and other modules.

This apparent dispersal is in some ways misleading, though, because //inweb//,
when pre-processing Inform modules for compilation, gathers all of that
syntax into one single definition file -- |Syntax.preform|. This is read in
at run-time, and can therefore be replaced with alternatives if the user
prefers. See //About Preform// for more, and see //Loading Preform// for
how it is read in.

@ Inform parses Preform using a hand-built algorithm highly optimised for
the unusual structure of natural language -- unusual, that is, compared
to most programming languages. The parser occupies the whole //Preform//
section, but //The Optimiser// is also needed to make it acceptably fast.
It follows that Inform doesn't use parser-generators such as |yacc|, or
|antlr|, and for that matter does not use the elegant theory of LALR parsing.
This is for three reasons:
(a) I am sceptical that formal grammars specify natural language all that well
-- which is ironic, considering that the relevant computer science, dating
from the 1950s and 1960s, was strongly influenced by Noam Chomsky's generative
linguistics.The classical use case for |yacc| is to manage hierarchies of
associative operators: but natural language doesn't have those.
(b) If we used a generator like |yacc|, Preform grammar would not be extensible
at run-time, and there would be little hope of translating it to, say, French
or German.
(c) Folk wisdom has it that |yacc| parsers are about half as fast as a shrewdly
hand-coded equivalent, and I tend to believe this. I note that the |gcc| C
compiler abandoned the use of |bison| for exactly this reason, despite the
loyalty of |gcc|'s authors to the cause of interdependent standard Unix tools.
Sometimes performance is better than ideology.
