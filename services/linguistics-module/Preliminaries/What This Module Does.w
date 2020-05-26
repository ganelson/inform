What This Module Does.

An overview of the linguistics module's role and abilities.

@h Prerequisites.
The linguistics module is a part of the Inform compiler toolset. It is
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

@h A symbols table for natural language.
Our first task is to provide something equivalent to the "symbols table"
used in a compiler for a conventional language. For example, in a C compiler,
identifiers such as |int|, |x| or |printf| might all be entries in such a
table, and any new name can rapidly be checked to see if it matches one already
known.

In natural language we have "excerpts", that is, contiguous runs of words,
rather than identifiers. But we must similarly remember their meanings.
Examples might include:

>> american dialect, say close bracket, player's command, open, Hall of Mirrors

Conventional symbols table algorithms depend on the fact that identifiers are
relatively long sequences of letters (often 8 or more units) drawn from a
small alphabet (say, the 37 letters, digits and the underscore). But Inform
has short symbols (typically 1 to 3 units) drawn from a huge alphabet (say,
5,000 different words found in the source text). Inform also allows for
flexibility in matching: the excerpt meaning |give # bone|, for example, must
match "give a dog a bone" or "give me the thigh bone".

We also need to parse in ways which a conventional compiler does not. If C has
registered the identifier |pink_martini|, it never needs to notice |martini| as
being related to it. But when Inform registers "pink martini" as the name of an
instance, it then has to spot that either "pink" or "martini" alone might also
refer to the same object.

@ The lexicon is stored using //excerpt_meaning// objects, in //Excerpt Meanings//,
and the algorithm for matching against is //ExParser::parse_excerpt//. When
the parent wants to declare a new meaning, it calls either

(*) //ExcerptMeanings::register// to register using a wording to represent
the text of the excerpt, or
(*) //ExcerptMeanings::register_assemblage// to use a word assemblage instead.

In either case it must supply a "meaning code", such as |TABLE_MC|, to give
a very loose idea of what is meant; we will use that to make lookups faster.

@h Optimisations.
This is a speed-critical part of Inform and has been heavily optimised, at the
cost of some complexity. There are two main ideas:

Firstly, each word in the vocabulary gathered up by the //words// module --
i.e., each different word in the source text -- has a //vocabulary_meaning//
object attached to it. This in turn contains lists of all known meanings
starting with, ending with, or simply involving the word.

For example, if "great green dragon" is given a meaning, then this is added to
the first-word list for "great", the last-word list for "dragon", and the
middle-word list for "green".

In addition, every word in an excerpt which is not an article adds the meaning
to its "subset list" -- here, that would be all three words, but for "gandalf
the grey", it would be entered onto the subset lists for "gandalf" and "grey".
Subset lists tend to be longer and thus slower to deal with, and are used only
in contexts where it is legal to use a subset of a name to refer to the
meaning -- for example, to say just "Gandalf" but mean the same wizard.

@ Secondly, recall that each vocabulary entry has a field 32 bits wide for
a bitmap, of which only 6 bits were used in the lexer. (See //words: Vocabulary//.)
For example, cardinal numbers had the |NUMBER_MC| bit set.

We're now going to use the other 26 bits. The idea is that if a meaning is
registered for the name of, say, a table, then the |TABLE_MC| bit would be
set for each of the words in that name. For example, if "table of tides" is
such a name, then each if the words |table|, |of| and |tides| picks up the
|TABLE_MC| bit.

What we gain by this is that if we are ever testing some words in the source
text to see if they might be the name of a table, we can immediately reject,
say, "green table" because the word |green| does not have the |TABLE_MC| bit.

For more on this, and for complications arising to do with case sensitivity,
see //ExcerptMeanings::hash_code_from_token_list//.

= (undisplayed text from ../../inform7/Figures/excerpts-diagnostics.txt)
