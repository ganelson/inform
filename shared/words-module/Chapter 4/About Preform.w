[AboutPreform::] About Preform.

A brief guide to Preform and how to use it.

@ That's what it would look like in the Preform file, but here is how it's
typed in the Inform source code. Definitions like this one are scattered all
across the Inform web, in order to keep them close to the code which relates to
them. The |inweb| tangler compiles them in two halves: the instructions right
of the |==>| arrows are extracted and compiled into a C routine called the
"compositor" for the nonterminal (see below), while the actual grammar is
extracted and placed into Inform's "Preform.txt" file.

In the document of Preform grammar extracted from Inform's source code to
lay the language out for translators, the |==>| arrows and formulae to the
right of them are omitted -- those represent semantics, not syntax.

= (text)
	<competitor> ::=
		<ordinal-number> runner |    ==> TRUE
		runner no <cardinal-number>				==> FALSE

@ Each nonterminal, when successfully matched, can provide both or more usually
just one of two results: an integer, to be stored in |*X|, and a void pointer,
to be stored in |*XP|. For example, <k-kind> matches if and only if the
text declares a legal kind, such as "number"; its pointer result is to the
kind found, such as |K_number|. But <competitor> only results in an integer.
The |==>| arrow is optional, but if present, it says what the result is if
the given production is matched; the |inweb| tangler, if it sees an expression
on the right of the arrow, assigns that value to the integer result. So,
for example, "runner bean" or "beetroot" would not match <competitor>;
"4th runner" would match with integer result |TRUE|; "runner no 17" would
match with integer result |FALSE|.

Usually, though, the result(s) of a nonterminal depend on the result(s) of
other nonterminals used to make the match. In the compositing expression,
so called because it composes together the various intermediate results into
one final result, |R[1]| is the integer result of the first nonterminal in
the production, |R[2]| the second, and so on; |RP[1]| and so on hold the
pointer results. Here, on both productions, there's just one nonterminal
in the line, <ordinal-number> in the first case, <cardinal-number> in
the second. So the following refinement of <competitor> means that "4th
runner" matches with integer result 4, because <ordinal-number> matches
"4th" with integer result 4, and that goes into |R[1]|. Similarly,
"runner no 17" ends up with integer result 17. "The pacemaker" matches
with integer result 1; here there are no intermediate results to make use
of, so |R[...]| can't be used.

= (text)
	<competitor> ::=
		the pacemaker |    ==> 1
		<ordinal-number> runner |    ==> R[1]
		runner no <cardinal-number>				==> R[1]

@ The arrows and expressions are optional, and if they are omitted, then the
result integer is set to the production number, counting up from 0. For
example, given the following, "polkadot" matches with result 1, and "green"
with result 2.

= (text)
	<race-jersey> ::=
		yellow | polkadot | green | white

Since I have found that well-known computer programmers look at me strangely
when I tell them that Inform doesn't use |yacc|, or |antlr|, or for that
matter any of the elegant theory of LALR parsers, perhaps an explanation
is called for.

One reason is that I am sceptical that formal grammars specify natural language
terribly well -- which is ironic, considering that the relevant computer
science, dating from the 1950s and 1960s, was strongly influenced by Noam
Chomsky's generative linguistics. Such formal descriptions tend to be too rigid
to be applied universally. The classical use case for |yacc| is to manage
hierarchies of associative operators on different levels: well, natural language
doesn't have those.

Another reason is that |yacc|-style grammars tend to react badly to uncompliant
input: that is, they correctly reject it, but are bad at diagnosing the
problem, and at recovering their wits afterwards. For Inform purposes, this
would be too sloppy: the user more often miscompiles than compiles, and quality
lies in how good our problem messages are in reply.

Lastly, there are two pragmatic reasons. In order to make Preform grammar
extensible, we couldn't use a parser-compiler like |yacc| anyway: we have to
interpret our grammar, not compile code to parse it. And we also want speed;
folk wisdom has it that |yacc| parsers are about half as fast as a shrewdly
hand-coded equivalent. (|gcc| abandoned the use of |bison| for exactly this
reason some years ago.) Until Preform's arrival in February 2011, Inform had a
hard-coded syntax analyser scattered throughout its code, which often made what
were provably the minimum possible number of comparisons. Even Preform's
parser is intentionally lean.
