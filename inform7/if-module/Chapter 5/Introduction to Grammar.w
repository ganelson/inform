[PL::Parsing::] Introduction to Grammar.

An exposition of the data structures and basic method used to
deal with the command-parsing grammar implied by Understand sentences in
the source text.

@ This is grammar in the sense of the parsing structures used at run-time,
and it occupies a chapter of its own in the source code since it is to some
extent detached from the rest of NI: what we create in this chapter is
almost an independent compiler in its own right, but of a much simpler
language. Although we use many higher-level features of NI in the process,
none use this.

Grammar is organised in a three-level hierarchy:

(a) A grammar verb (GV) is a small independent grammar of alternative
formulations for some concept: for instance, the possible commands beginning
TAKE, or the possible verbal forms of numbers. Each GV is a list of GLs, and
an individual GL must belong to exactly one GV. There are five different
types of GV, differentiated mostly by the purpose to which the GV is put:
(-1) |GV_IS_COMMAND|. An imperative verbal command at run-time.
(-2) |GV_IS_TOKEN|. A square-bracketed token in other grammar.
(-3) |GV_IS_OBJECT|. A noun phrase at run time: a name for an object.
(-4) |GV_IS_VALUE|. A noun phrase at run time: a name for a value.
(-5) |GV_IS_CONSULT|. A pattern to match in part of a command (such as "consult").
(-6) |GV_IS_PROPERTY_NAME|. A noun phrase at run time: a name for one
possibility for an either/or property, say "open" or "fixed in place".

(b) A grammar line (GL) is a single possibility within a GV: for
example, the line matching |"take [something]"| in the GV for the TAKE
command. Each GL is a list of tokens, and an individual token must belong
to exactly one GL.

(c) A grammar token (GTOK) is a single particle of a GL: for
example, |'take'| and |something| are tokens.

The picture is not quite so hierarchical as it looks, though, because
a GV naming a token can be used as a token inside other GVs. We need to
be careful that this does not lead to infinite regress: see below.

Much of what we do with grammar involves recursing down this hierarchy,
in some cases allowing results to percolate back upwards. What happens
takes place in four chronological phases. (This division into phases is
convenient because Inform 6 requires that all general parsing routines
and noun filter routines already exist when a |Verb| directive is reached
which uses them.)

@h Phase I: Slash Grammar.
Slashing is the process of dealing with slashes |/| used in grammar
to indicate alternatives.

@h Phase II: Determining Grammar.
We check that the grammar is well-founded and find the types of values
expressed by it, if any.

Determining well-foundedness means checking that no two grammar tokens
each require the use of the other, and that when a grammar token takes
several alternative forms, they have compatible results: so, for instance,
you can't have one version resulting in a number and another in a thing.
(This check is only meaningful for grammar verbs of type |GV_IS_TOKEN|.)

The result of a |GV_IS_TOKEN| is a single specification, which is the union of the
kinds resulting from its grammar lines. This is a more sophisticated approach
than we really need here, but might be useful for future expansion.

Of the determining traverse the following can be said:

(a) either errors are produced, or it is verified that no token's
definition depends directly or indirectly on already knowing itself;

(b) also that no grammar line attached to a |GV_IS_COMMAND| produces
more than 2 values, and that no grammar line attached to anything else
produces more than one; and

(c) also that the grammar lines attached to a |GV_IS_TOKEN| are
compatible in that there is a type to which they can all always be cast.

We note of the determining routines that:

(a) |PL::Parsing::Verbs::determine| runs at least once for each GV;

(b) |PL::Parsing::Lines::gl_determine| runs exactly once on each GL;

(c) |PL::Parsing::Tokens::determine| runs exactly once on each token.

@h Phase III: Sort Grammar.
We must ensure that if grammar line L1 is logically impossible once L2
has been parsed, then L1 must be checked before L2, regardless of the
ordering in the source code. Since the data sets are very small and
time is not of the essence, we simply insertion-sort the original
definition-order list into a second linked list.

@h Phase IV: Compile Grammar.
The final run-through, which uses the sorted order and not the original
declaration order, actually compiles the necessary I6 |Verb| and
|Extend| directives.
