Phrase Definitions.

The phrases making up the Inform language, and in terms of which all
other phrases and rules are defined.

@ All phrases of the Inform language itself are defined here. The Standard
Rules extension adds more, specialised for interactive fiction creation,
but the bones of the language are here. For example, we will define what
the plus sign will mean, and how Inform should compile "say N in words",
where N is a number. Inform has no phrase definitions built in, as such;
but it does contain assumptions about control structures such as "say ...",
"repeat ...", "let ...", "otherwise ..." and so on will behave. Those, we
would not be able to redefine in fundamentally different ways. In most
respects, though, we are more or less free to define any language we like.

At first sight, these phrase definitions look little more than simple
transliterations, and this was one source of early criticism of Inform 7.
Phrases appeared to have very simplistic definitions, with the natural
language simply being a verbose description of obviously equivalent C-like
code. However, the simplicity is misleading, because the definitions below
tend to conceal where the complexity of the translation process suddenly
increases. If the preamble includes "(c - condition)", and the definition
includes the expansion |{c}|, then the text forming c is translated in a way
much more profound than any simple substitution process could describe.
Type-checking also complicates the code produced below, since Inform
automatically generates the code needed to perform run-time type checking at
any point where doubt remains as to the phrase definition which must be used.

@ Many of these phrases have what are called inline definitions, written
using the |(-| and |-)| notation. Non-inline phrases are compiled as
functions, which are then called when they need to be used. For example,
"To say the magic number: say 17." compiles to a function, and when
another phrase includes the instruction "say the magic number", that
instruction compiles a call to this function. But an inline phrase
instead generates Inter instructions to do something directly. (That
something may in fact still be just a function call, but not always.)
The Inter code to be generated is expressed by the contents of the
definition between the |(-| and |-)| markers, and is written in a
marked-up form of Inform 6 notation. This is much more concise and
readable than if the Inter code were written out longhand, but it may
give the misleading impression that Inform inline definitions can only
produce Inform 6 code. That is not so: they produce Inter code, which
can then be translated as needed.

Most of the definitions here also have annotations to positions in the
main Inform dcumentation: for example, |(documented at phs_s)|. This has
no effect on the code compiled, and is used only when Inform generates
certain problem messages; if the source text misuses the phrase, the problem
can then give a reference to the relevant documentation. |phs_s| is a
typical example of a "documentation token", and is only a label. See the
source of the Inform documentation for how this markup is done.

@ Unit tests for the phrases below have test case names beginning |BIP-|,
which stands for "Basic Inform phrase". In fact, these come in pairs, one for
each virtual machine we customarily generate code to. For example, |BIP-Say|
tests the "say" phrase for the Z-machine target, and |BIP-Say-G| does the same
for the Glulx target. But in the commentary below, test cases will be listed
only once.

It follows that running |intest -from inform7 BIP-%c+| will test all of
these phrases on all platforms, since this regular expression matches all
test case names beginning with "BIP-".

@h Say phrases.
We begin with saying phrases: the very first phrase to exist is the one
printing a single value -- literal text, a number, a time, an object, or
really almost anything, since the vast majority of kinds in Inform are
sayable. There used to be separate definitions for saying text, numbers
and unicode characters here, but they were removed in June 2015 as being
redundant. Though they did no harm, they made some problem messages longer
than necessary by obliging them to cite a longer list of possible readings
of a misread phrase.

The three inline definitions here neatly demonstrate the three sorts of
things which appear inside |(-| and |-)|. The definition for "To say s",
which looks more familiar as the "[s]" text substitution, is straightforwardly
Inform 6 notation. The definition for "To say (something - number) in words"
is I6 notation except for the |{something}| part in braces: this expands
to the value used by the code causing compilation. For example, if the code
to be compiled is "say 17 in words" then |{something}| here would expand to
the constant 17. The definition for "To say (val)" is much more complex than
I6 notation could convey, and so a more complex escape notation is needed,
|{-say:val:K}|, which tells Inform o compile code which will say |val| with
whatever method is appropriate to its kind |K|. For documentation on these
escape notations, see the core Inform source code.

The global variable |say__n| tracks the last number printed. For the "in
words" definition, we need to set it by hand, since Inform doesn't otherwise
realise that number-printing is what we are doing here. For definitions of
functions such as |STextSubstitution|, see the source for the |basic_inform|
template library, which is also where |say__n| is defined.

See test case |BIP-Say|.

=
Part Two - Phrasebook

Chapter 1 - Saying

Section 1 - Saying Values

To say (val - sayable value of kind K)
	(documented at ph_say):
	(- {-say:val:K} -).
To say (something - number) in words
	(documented at phs_numwords):
	(- print (number) say__n=({something}); -).
To say s
	(documented at phs_s):
	(- STextSubstitution(); -).

@ "Showme" is a debugging version of "say" which can print some version of
the value, and the kind, of just about anything.

See test case |BIP-Showme|.

=
To showme (val - value)
	(documented at ph_showme):
	(- {-show-me:val} -).

@ Objects are the most difficult things to say, because of the elaborate
apparatus for managing their natural-language representations. In particular,
we need to say them with a definite or indefinite article, which can either
be capitalised or not, and as part of that we need to keep track of whether
they are proper nouns; in languages other than English, there are also gender
and case to worry about.

Note that "To say ..." phrases are case sensitive on the first word, so that
"to say a something" and "to say A something" are different.

A curiosity of Inform 6's syntax, arising I think mostly from the need to
save property memory in "Curses" (1993), the work of IF for which Inform 1
had been created, is that it lacks a |print (A) ...| statement. The omission
is made good by using a routine in the template library instead.

See test case |BIP-SayName|.

=
Section 2 - Saying Names

To say a (something - object)
	(documented at phs_a):
	(- print (a) {something}; -).
To say an (something - object)
	(documented at phs_a):
	(- print (a) {something}; -).
To say A (something - object)
	(documented at phs_A):
	(- CIndefArt({something}); -).
To say An (something - object)
	(documented at phs_A):
	(- CIndefArt({something}); -).
To say the (something - object)
	(documented at phs_the):
	(- print (the) {something}; -).
To say The (something - object)
	(documented at phs_The):
	(- print (The) {something}; -).

@ Now some text substitutions which are the equivalent of escape characters.
(In double-quoted I6 text, the notation for a literal quotation mark is a
tilde |~|.) Note the use of the "-- running on" annotation, which tells Inform
that a text substitution should not cause a new-line.

See test case |BIP-SaySpecial|.

=
Section 3 - Saying Special Characters

To say bracket -- running on
	(documented at phs_bracket):
	(- print "["; -).
To say close bracket -- running on
	(documented at phs_closebracket):
	(- print "]"; -).
To say apostrophe/' -- running on
	(documented at phs_apostrophe):
	(- print "'"; -).
To say quotation mark -- running on
	(documented at phs_quotemark):
	(- print "~"; -).

@ For an explanation of the paragraph breaking algorithm, see the template
file "Printing.i6t".

See test case |BIP-SayParagraphing|.

=
Section 4 - Saying Line and Paragraph Breaks

To say line break -- running on
	(documented at phs_linebreak):
	(- new_line; -).
To say no line break -- running on
	(documented at phs_nolinebreak):
	do nothing.
To say conditional paragraph break -- running on
	(documented at phs_condparabreak):
	(- DivideParagraphPoint(); -).
To say paragraph break -- running on
	(documented at phs_parabreak):
	(- DivideParagraphPoint(); new_line; -).
To say run paragraph on -- running on
	(documented at phs_runparaon):
	(- RunParagraphOn(); -).
To decide if a paragraph break is pending
	(documented at ph_breakpending):
	(- (say__p) -).

@ Now for "[if ...]", which expands into a rather assembly-language-like
usage of |jump| statements, I6's form of goto. For instance, the text
"[if the score is 10]It's ten![otherwise]It's not ten, alas." compiles
thus:

	|if (~~(score == 10)) jump L_Say3;|
	|    ...|
	|jump L_SayX2; .L_Say3;|
	|    ...|
	|.L_Say4; .L_SayX2;|

Though labels actually have local namespaces in I6 routines, we use
globally unique labels throughout the whole program: compiling the same
phrase again would involve say labels 5 and 6 and "say exit" label 3.
This example text demonstrates the reason we |jump| about, rather than
making use of |if... else...| and bracing groups of statements: it is legal
in I7 either to conclude with or to omit the "[end if]". (If statements
in I6 compile to jump instructions in any event, and on our virtual
machines there is no speed penalty for branches.) We also need the same
definitions to accommodate what amounts to a switch statement. The trickier
text "[if the score is 10]It's ten![otherwise if the score is 8]It's
eight?[otherwise]It's not ten, alas." comes out as:

	|if (~~(score == 10)) jump L_Say5;|
	|    ...|
	|jump L_SayX3; .L_Say5; if (~~(score == 8)) jump L_Say6;|
	|    ...|
	|jump L_SayX3; .L_Say6;|
	|    ...|
	|.L_Say7; .L_SayX3;|

In either form of the construct, control passes into at most one of the
pieces of text. The terminal labels (the two on the final line) are
automatically generated; often -- when there is a simple "otherwise" or
"end if" to conclude the construct -- they are not needed, but labels are
quick to process in I6, are soon discarded from I6's memory when not needed
any more, and compile no code.

We assume in each case that the next say label number to be free is always
the start of the next block, and that the next say exit label number is always
the one at the end of the current construct. This is true because NI does
not allow "say if" to be nested.

See test case |BIP-SayIf|.

=
Section 5 - Saying If and Otherwise

To say if (c - condition)
	(documented at phs_if): (-
	if (~~({c})) jump {-label:Say};
		-).
To say unless (c - condition)
	(documented at phs_unless): (-
	if ({c}) jump {-label:Say};
		-).
To say otherwise/else if (c - condition)
	(documented at phs_elseif): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say}; if (~~({c})) jump {-label:Say};
		-).
To say otherwise/else unless (c - condition)
	(documented at phs_elseunless): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say}; if ({c}) jump {-label:Say};
		-).
To say otherwise
	(documented at phs_otherwise): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say};
		-).
To say else
	(documented at phs_otherwise): (-
	jump {-label:SayX}; .{-label:Say}{-counter-up:Say};
		-).
To say end if
	(documented at phs_endif): (-
	.{-label:Say}{-counter-up:Say}; .{-label:SayX}{-counter-up:SayX};
		-).
To say end unless
	(documented at phs_endunless): (-
	.{-label:Say}{-counter-up:Say}; .{-label:SayX}{-counter-up:SayX};
		-).

@ The other control structure: the random variations form of saying. This
part of the Inform design was in effect contributed by the community: it
reimplements a form of Jon Ingold's former extension Text Variations, which
itself built on code going back to the days of I6.

The head phrase has one of the most complicated definitions suppled with
Inform, but is actually documented fairly explicitly in the Extensions chapter
of "Writing with Inform", so we won't repeat all that here. Essentially it
uses its own allocated cell of storage in an array to remember a state between
uses, and compiles as a switch statement based on the current state.

See test case |BIP-SayOneOf|.

=
Section 6 - Saying one of

To say one of -- beginning say_one_of (documented at phs_oneof): (-
	{-counter-makes-array:say_one_of}
	{-counter-makes-array:say_one_flag}
	if ({-counter-storage:say_one_flag}-->{-counter:say_one_flag} == false) {
		{-counter-storage:say_one_of}-->{-counter:say_one_of} = {-final-segment-marker}({-counter-storage:say_one_of}-->{-counter:say_one_of}, {-segment-count});
	 	{-counter-storage:say_one_flag}-->{-counter:say_one_flag} = true;
	}
	if (say__comp == false) {-counter-storage:say_one_flag}-->{-counter:say_one_flag}{-counter-up:say_one_flag} = false;
	switch (({-counter-storage:say_one_of}-->{-counter:say_one_of}{-counter-up:say_one_of})%({-segment-count}+1)-1)
{-open-brace}
		0: -).
To say or -- continuing say_one_of (documented at phs_or):
	(- @nop; {-segment-count}: -).
To say at random -- ending say_one_of with marker I7_SOO_RAN (documented at phs_random):
	(- {-close-brace} -).
To say purely at random -- ending say_one_of with marker I7_SOO_PAR (documented at phs_purelyrandom):
	(- {-close-brace} -).
To say then at random -- ending say_one_of with marker I7_SOO_TRAN (documented at phs_thenrandom):
	(- {-close-brace} -).
To say then purely at random -- ending say_one_of with marker I7_SOO_TPAR (documented at phs_thenpurelyrandom):
	(- {-close-brace} -).
To say sticky random -- ending say_one_of with marker I7_SOO_STI (documented at phs_sticky):
	(- {-close-brace} -).
To say as decreasingly likely outcomes -- ending say_one_of with marker I7_SOO_TAP (documented at phs_decreasing):
	(- {-close-brace} -).
To say in random order -- ending say_one_of with marker I7_SOO_SHU (documented at phs_order):
	(- {-close-brace} -).
To say cycling -- ending say_one_of with marker I7_SOO_CYC (documented at phs_cycling):
	(- {-close-brace} -).
To say stopping -- ending say_one_of with marker I7_SOO_STOP (documented at phs_stopping):
	(- {-close-brace} -).

To say first time -- beginning say_first_time (documented at phs_firsttime):
	(- {-counter-makes-array:say_first_time}
	if ((say__comp == false) && (({-counter-storage:say_first_time}-->{-counter:say_first_time}{-counter-up:say_first_time})++ == 0)) {-open-brace}
		-).
To say only -- ending say_first_time (documented at phs_firsttime):
	(- {-close-brace} -).

@ Now some visual effects, which may or may not be rendered the way the user
hopes: that's partly up to the virtual machine, unfortunately.

See test case |BIP-SayOneOf|, though since |intest| runs on plain text only,
you may need to run this in the Inform application to be convinced.

=
Section 7 - Saying Fonts and Visual Effects

To say bold type -- running on
	(documented at phs_bold):
	(- style bold; -).
To say italic type -- running on
	(documented at phs_italic):
	(- style underline; -).
To say roman type -- running on
	(documented at phs_roman):
	(- style roman; -).
To say fixed letter spacing -- running on
	(documented at phs_fixedspacing):
	(- font off; -).
To say variable letter spacing -- running on
	(documented at phs_varspacing):
	(- font on; -).
	
@ These are lists in the sense of the "list of" kind of value constructor, and
the first two phrases here might list any values, not just objects.

See test case |BIP-SayLists|.

=
Section 8 - Saying Lists of Values

To say (L - a list of values) in brace notation
	(documented at phs_listbraced):
	(- LIST_OF_TY_Say({-by-reference:L}, 1); -).
To say (L - a list of objects) with definite articles
	(documented at phs_listdef):
	(- LIST_OF_TY_Say({-by-reference:L}, 2); -).
To say (L - a list of objects) with indefinite articles
	(documented at phs_listindef):
	(- LIST_OF_TY_Say({-by-reference:L}, 3); -).

@h Variables.
The "now" phrase can do an extraordinary range of things, and is more or
less a genie granting one wish.

See test case |BIP-Now|.

=
Chapter 2

Section 1 - Making Conditions True

To now (cn - condition)
	(documented at ph_now):
	(- {cn} -).

@ Assignment is probably the most difficult thing the type-checker has to
cope with, since "let" has to work when applied to both unknown names (it
creates a new variable) and existing ones (kind of value permitting). There
are also four different ways to create with "let", and two to use
existing variables. Note that the "given by" forms are not strictly
speaking assignments at all; the value placed in |t| is found by solving
the equation |Q|. This does require special typechecking, but of a
different kind to that requested by "(assignment operation)". All of which
makes the "To let" section here only slightly shorter than John Galsworthy's
Forsyte novel of the same name.

See test case |BIP-Let|.

=
Section 2 - Assigning Temporary Variables

To let (t - nonexisting variable) be (u - value)
	(assignment operation)
	(documented at ph_let): (-
		{-unprotect:t}
		{-copy:t:u}
	-).
To let (t - nonexisting variable) be (u - name of kind of value)
	(assignment operation)
	(documented at ph_letdefault): (-
		{-unprotect:t}
		{-initialise:t}
	-).
To let (t - nonexisting variable) be (u - description of relations of values
	of kind K to values of kind L)
	(assignment operation)
	(documented at ph_letrelation): (-
		{-unprotect:t}
		{-initialise:t}
		{-now-matches-description:t:u};
	-).
To let (t - nonexisting variable) be given by (Q - equation name)
	(documented at ph_letequation): (-
		{-unprotect:t}
		{-primitive-definition:solve-equation};
	-).

To let (t - existing variable) be (u - value)
	(assignment operation)
	(documented at ph_let): (-
	 	{-copy:t:u}
	-).
To let (t - existing variable) be given by (Q - equation name)
	(documented at ph_letequation): (-
		{-primitive-definition:solve-equation};
	-).

@ It is not explicit in the following definitions that Inform should typecheck
that the values held by these storage objects can be incremented or decremented
(as an object, say, cannot, but a number can): Inform nevertheless contains
code which does this.

See test case |BIP-Increase|.

=
Section 3 - Increase and Decrease

To increase (S - storage) by (w - value)
	(assignment operation)
	(documented at ph_increase): (-
		{-copy:S:+w};
	-).
To decrease (S - storage) by (w - value)
	(assignment operation)
	(documented at ph_decrease): (-
		{-copy:S:-w};
	-).
To increment (S - storage)
	(documented at ph_increment): (-
		{-copy:S:+};
	-).
To decrement (S - storage)
	(documented at ph_decrement): (-
		{-copy:S:-};
	-).


@h Arithmetic.
There are nine arithmetic operations, internally numbered 0 upwards, and
given verbal forms below. These are handled unusually in the type-checker
because they need to be more polymorphic than most phrases: Inform uses
dimension-checking to determine the kind of value resulting. (Thus a
height times a number is another height, and so on.)

The totalling code (12) is not structly to do with arithmetic in the same
way, but it's needed to flag the phrase for the Inform typechecker's special
attention.

See test case |BIP-IntegerArithmetic|.

=
Chapter 2 - Arithmetic

Section 1 - Integer Operations

To decide which arithmetic value is (X - arithmetic value) + (Y - arithmetic value)
	(arithmetic operation 0)
	(documented at ph_plus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) plus (Y - arithmetic value)
	(arithmetic operation 0)
	(documented at ph_plus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) - (Y - arithmetic value)
	(arithmetic operation 1)
	(documented at ph_minus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) minus (Y - arithmetic value)
	(arithmetic operation 1)
	(documented at ph_minus):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) * (Y - arithmetic value)
	(arithmetic operation 2)
	(documented at ph_times):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) times (Y - arithmetic value)
	(arithmetic operation 2)
	(documented at ph_times):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) multiplied by (Y - arithmetic value)
	(arithmetic operation 2)
	(documented at ph_times):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) / (Y - arithmetic value)
	(arithmetic operation 3)
	(documented at ph_divide):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) divided by (Y - arithmetic value)
	(arithmetic operation 3)
	(documented at ph_divide):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is remainder after dividing (X - arithmetic value)
	by (Y - arithmetic value)
	(arithmetic operation 4)
	(documented at ph_remainder):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is (X - arithmetic value) to the nearest (Y - arithmetic value)
	(arithmetic operation 5)
	(documented at ph_nearest):
	(- ({-arithmetic-operation:X:Y}) -).
To decide which arithmetic value is the square root of (X - arithmetic value)
	(arithmetic operation 6)
	(documented at ph_squareroot):
	(- ({-arithmetic-operation:X}) -).
To decide which arithmetic value is the cube root of (X - arithmetic value)
	(arithmetic operation 8)
	(documented at ph_cuberoot):
	(- ({-arithmetic-operation:X}) -).
To decide which arithmetic value is total (p - arithmetic value valued property)
	of (S - description of values)
	(arithmetic operation 12)
	(documented at ph_total):
	(- {-primitive-definition:total-of} -).


@ "Do nothing" is useful mainly when other syntax has backed us into
something clumsy, but it can't be dispensed with. (In the examples, it used
to be used when conditions were awkward to negate -- if condition, do nothing,
otherwise blah blah blah -- but the creation of "unless" made it possible
to remove most of the "do nothing"s.)

=
Section SR5/3/8 - Control phrases - Stop or go

To do nothing (documented at ph_nothing):
	(- ; -).
To stop (documented at ph_stop):
	(- rtrue; -) - in to only.

@

See test case |Showme|.

=
To decide what K is the default value of (V - name of kind of value of kind K)
	(documented at ph_defaultvalue):
	(- {-new:K} -).

@ The following exists only to convert a condition to a value, and is
needed because I7 does not silently cast from one to the other in the way
that C would.

=
Section SR5/2/6 - Values - Truth states

To decide what truth state is whether or not (C - condition)
	(documented at ph_whether):
	(- ({C}) -).

@ And so, at last...

=
Basic Inform ends here.

@ ...except that this is not quite true, because like most extensions they
then quote some documentation for Inform to weave into index pages: though
here it's more of a polite refusal than a manual, since the entire system
documentation is really the description of what was defined in this
extension.

=
---- DOCUMENTATION ----

Unlike other extensions, the Standard Rules are compulsorily included
with every project. They define the phrases, kinds and relations which
are basic to Inform, and which are described throughout the documentation.
