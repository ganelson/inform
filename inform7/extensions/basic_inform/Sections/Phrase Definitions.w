Phrase Definitions.

The phrases making up the basic Inform language, and in terms of which all
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
main Inform documentation: for example, |(documented at phs_s)|. This has
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
|{-say:val:K}|, which tells Inform to compile code which will say |val| with
whatever method is appropriate to its kind |K|. For documentation on these
escape notations, see the core Inform source code.

The global variable |say__n| tracks the last number printed. For the "in
words" definition, we need to set it by hand, since Inform doesn't otherwise
realise that number-printing is what we are doing here. For definitions of
functions such as |STextSubstitution|, see the source for |BasicInformKit|,
which is also where |say__n| is defined.

See test case |BIP-Say|.

=
Part Three - Phrasebook

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
= (text as Inform 6)
	if (~~(score == 10)) jump L_Say3;
	    ...
	jump L_SayX2; .L_Say3;
	    ...
	.L_Say4; .L_SayX2;
=
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
= (text as Inform 6)
	if (~~(score == 10)) jump L_Say5;
	    ...
	jump L_SayX3; .L_Say5; if (~~(score == 8)) jump L_Say6;
	    ...
	jump L_SayX3; .L_Say6;
	    ...
	.L_Say7; .L_SayX3;
=
In either form of the construct, control passes into at most one of the
pieces of text. The terminal labels (the two on the final line) are
automatically generated; often -- when there is a simple "otherwise" or
"end if" to conclude the construct -- they are not needed, but labels are
quick to process in I6, are soon discarded from I6's memory when not needed
any more, and compile no code.

We assume in each case that the next say label number to be free is always
the start of the next block, and that the next say exit label number is always
the one at the end of the current construct. This is true because Inform does
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

See test case |BIP-SayFonts|, though since |intest| runs on plain text only,
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

The "whether or not" phrase exists only to convert a condition to a value,
and is needed because I7 does not silently cast from one to the other in
the way that C would.

See test case |BIP-Now|.

=
Chapter 2 - Conditions and Variables

Section 1 - Conditions

To now (cn - condition)
	(documented at ph_now):
	(- {cn} -).
To decide what truth state is whether or not (C - condition)
	(documented at ph_whether):
	(- ({C}) -).

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

See test case |BIP-ArithmeticOperations|.

=
Chapter 2 - Arithmetic

Section 1 - Arithmetic Operations

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

@ Real numbers are not available in the Z-machine, but they are likely to
be available everywhere else, i.e., on any other platform Inform may target
in future.

See test case |BIP-SayRealNumbers-G|, which has no Z-machine counterpart.

=
Section 2 - Saying Real Numbers (not for Z-machine)

To say (R - a real number) to (N - number) decimal places
	(documented at phs_realplaces):
	(- Float({R}, {N}); -).
To say (R - a real number) in decimal notation
	(documented at phs_decimal):
	(- FloatDec({R}); -).
To say (R - a real number) to (N - number) decimal places in decimal notation
	(documented at phs_decimalplaces):
	(- FloatDec({R}, {N}); -).
To say (R - a real number) in scientific notation
	(documented at phs_scientific):
	(- FloatExp({R}); -).
To say (R - a real number) to (N - number) decimal places in scientific notation
	(documented at phs_scientificplaces):
	(- FloatExp({R}, {N}); -).

@ A number of miscellaneous mathematical functions follow, for real
numbers only; these are tested as part of |BIP-ArithmeticOperations-G|,
already mentioned above. Note that we do not need to define real versions
of addition, multiplication and so on: the above definitions are polymorphic
enough to have done that already.

=
Section 3 - Real Arithmetic (not for Z-machine)

To decide which real number is the reciprocal of (R - a real number)
	(documented at ph_reciprocal):
	(- REAL_NUMBER_TY_Reciprocal({R}) -).
To decide which real number is the absolute value of (R - a real number)
	(documented at ph_absolutevalue)
	(this is the abs function):
	(- REAL_NUMBER_TY_Abs({R}) -).
To decide which real number is the real square root of (R - a real number)
	(arithmetic operation 7)
	(documented at ph_realsquareroot)
	(this is the root function inverse to rsqr):
	(- REAL_NUMBER_TY_Root({R}) -).
To decide which real number is the real square of (R - a real number)
	(this is the rsqr function inverse to root):
	let x be given by x = R^2 where x is a real number;
	decide on x.
To decide which real number is the ceiling of (R - a real number)
	(documented at ph_ceiling)
	(this is the ceiling function):
	(- REAL_NUMBER_TY_Ceiling({R}) -).
To decide which real number is the floor of (R - a real number)
	(documented at ph_floor)
	(this is the floor function):
	(- REAL_NUMBER_TY_Floor({R}) -).
To decide which number is (R - a real number) to the nearest whole number
	(documented at ph_nearestwholenumber)
	(this is the int function):
	(- REAL_NUMBER_TY_to_NUMBER_TY({R}) -).

@ And these are tested in |BIP-Exponentials-G|.

=
Section 4 - Exponential Functions (not for Z-machine)

To decide which real number is the natural/-- logarithm of (R - a real number)
	(documented at ph_logarithm)
	(this is the log function inverse to exp):
	(- REAL_NUMBER_TY_Log({R}) -).
To decide which real number is the logarithm to base (N - a number) of (R - a real number)
	(documented at ph_logarithmto):
	(- REAL_NUMBER_TY_BLog({R}, {N}) -).
To decide which real number is the exponential of (R - a real number)
	(documented at ph_exp)
	(this is the exp function inverse to log):
	(- REAL_NUMBER_TY_Exp({R}) -).
To decide which real number is (R - a real number) to the power (P - a real number)
	(documented at ph_power):
	(- REAL_NUMBER_TY_Pow({R}, {P}) -).

@ And these are tested in |BIP-Trigonometry-G|.

=
Section 5 - Trigonometric Functions (not for Z-machine)

To decide which real number is (R - a real number) degrees
	(documented at ph_degrees):
	(- REAL_NUMBER_TY_Times({R}, $+0.0174532925) -).

To decide which real number is the sine of (R - a real number)
	(documented at ph_sine)
	(this is the sin function inverse to arcsin):
	(- REAL_NUMBER_TY_Sin({R}) -).
To decide which real number is the cosine of (R - a real number)
	(documented at ph_cosine)
	(this is the cos function inverse to arccos):
	(- REAL_NUMBER_TY_Cos({R}) -).
To decide which real number is the tangent of (R - a real number)
	(documented at ph_tangent)
	(this is the tan function inverse to arctan):
	(- REAL_NUMBER_TY_Tan({R}) -).
To decide which real number is the arcsine of (R - a real number)
	(documented at ph_arcsine)
	(this is the arcsin function inverse to sin):
	(- REAL_NUMBER_TY_Arcsin({R}) -).
To decide which real number is the arccosine of (R - a real number)
	(documented at ph_arccosine)
	(this is the arccos function inverse to cos):
	(- REAL_NUMBER_TY_Arccos({R}) -).
To decide which real number is the arctangent of (R - a real number)
	(documented at ph_arctangent)
	(this is the arctan function inverse to tan):
	(- REAL_NUMBER_TY_Arctan({R}) -).

@ And these are tested in |BIP-Hyperbolics-G|.

=
Section 6 - Trigonometric Functions (not for Z-machine)

To decide which real number is the hyperbolic sine of (R - a real number)
	(documented at ph_hyperbolicsine)
	(this is the sinh function inverse to arcsinh):
	(- REAL_NUMBER_TY_Sinh({R}) -).
To decide which real number is the hyperbolic cosine of (R - a real number)
	(documented at ph_hyperboliccosine)
	(this is the cosh function inverse to arccosh):
	(- REAL_NUMBER_TY_Cosh({R}) -).
To decide which real number is the hyperbolic tangent of (R - a real number)
	(documented at ph_hyperbolictangent)
	(this is the tanh function inverse to arctanh):
	(- REAL_NUMBER_TY_Tanh({R}) -).
To decide which real number is the hyperbolic arcsine of (R - a real number)
	(documented at ph_hyperbolicarcsine)
	(this is the arcsinh function inverse to sinh):
	let x be given by x = log(R + root(R^2 + 1)) where x is a real number;
	decide on x.
To decide which real number is the hyperbolic arccosine of (R - a real number)
	(documented at ph_hyperbolicarccosine)
	(this is the arccosh function inverse to cosh):
	let x be given by x = log(R + root(R^2 - 1)) where x is a real number;
	decide on x.
To decide which real number is the hyperbolic arctangent of (R - a real number)
	(documented at ph_hyperbolicarctangent)
	(this is the arctanh function inverse to tanh):
	let x be given by x = 0.5*(log(1+R) - log(1-R)) where x is a real number;
	decide on x.

@h Control structures.
The term "control structure" conjures up the thought of conditionals and loops,
and we'll get to those, but we'll begin with the equivalent of the C language's
|return| statement: ending a function call with some value as an outcome.
Inform calls this "deciding" something, since in Inform programs functions
returning values are usually quite functional: that is, their point is what
value they return, rather than the side-effects of what they did.

Note that returning a value has to invoke the type-checker to ensure that
the return value matches the kind of value expected. This certainly rejects
the phrase if it's used in a definition which isn't meant to be deciding
a value at all, so an "in... only" clause is not needed.

The IF-form of Inform allows the antique syntaxes "yes" and "no" as
synonyms for "decide yes" and "decide no"; these are not present in Basic
Inform, and are defined in the Standard Rules (and only to keep old source
text working).

See test case |BIP-Decide|.

=
Chapter 3 - Control

Section 1 - Deciding Outcomes

To decide yes
	(documented at ph_yes):
	(- rtrue; -) - in to decide if only.
To decide no
	(documented at ph_no):
	(- rfalse; -) - in to decide if only.

To stop (documented at ph_stop):
	(- rtrue; -) - in to only.

To decide on (something - value)
	(documented at ph_decideon):
	(- return {-return-value:something}; -).

@ While "unless" is supposed to be exactly like "if" but with the reversed
sense of the condition, that isn't quite true. For example, there is no
"unless ... then ...": logical it might be, English it is not.

The switch form of "if" is subtly different, and here again "unless" is
not allowed in its place.

As with some other control structures, the definitions here are somewhat
partial, and made up for by direct code in the compiler. (There's a limit to
how much a general syntax for phrases can encode control phrases.)

See test case |BIP-If|.

=
Section 2 - If and Unless

To if (c - condition) begin -- end conditional
	(documented at ph_if):
	(- {c}  -).
To unless (c - condition) begin -- end conditional
	(documented at ph_unless):
	(- (~~{c})  -).
To if (V - value) is begin -- end conditional
	(documented at ph_switch):
	(-  -).

@ "Do nothing" is a curious feature for a high-level programming language (C,
for example, does not have a NOP function); it entered Inform in the earliest
days, when it was useful mainly when natural language syntax had painted users
into a corner. (In the examples, it used to be used when conditions were
awkward to negate -- if condition, do nothing, otherwise blah blah blah -- but
the creation of "unless" made it possible to remove most of the "do
nothing"s.) It is now hardly ever useful.

=
To do nothing (documented at ph_nothing):
	(- ; -).

@ After all that, the while loop is simplicity itself. Perhaps the presence
of "unless" for "if" argues for a similarly negated form, "until" for
"while", but users haven't yet petitioned for this.

See test case |BIP-Loops|.

=
Section 3 - While and Repeat

To while (c - condition) begin -- end loop
	(documented at ph_while):
	(- while {c}  -).

@ The repeat loop looks like a single construction, but isn't, because the
range can be given in four fundamentally different ways (and the loop variable
then has a different kind of value accordingly). First, the equivalents of
BASIC's |for| loop and of Inform 6's |objectloop|, respectively:

=
To repeat with (loopvar - nonexisting K variable)
	running from (v - arithmetic value of kind K) to (w - K) begin -- end loop
	(documented at ph_repeat):
		(- for ({loopvar}={v}: {loopvar}<={w}: {loopvar}++)  -).
To repeat with (loopvar - nonexisting K variable)
	running from (v - enumerated value of kind K) to (w - K) begin -- end loop
	(documented at ph_repeat):
		(- for ({loopvar}={v}: {loopvar}<={w}: {loopvar}={-next-routine:K}({loopvar}))  -).
To repeat with (loopvar - nonexisting K variable)
	running through (OS - description of values of kind K) begin -- end loop
	(documented at ph_runthrough):
		(- {-primitive-definition:repeat-through} -).
To repeat with (loopvar - nonexisting object variable)
	running through (L - list of values) begin -- end loop
	(documented at ph_repeatlist):
		(- {-primitive-definition:repeat-through-list} -).

@ The following are all repeats where the range is the set of rows of a table,
taken in some order, and the repeat variable -- though it does exist -- is
never specified since the relevant row is instead the one selected during
each iteration of the loop.

=
To repeat through (T - table name) begin -- end loop
	(documented at ph_repeattable): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=1, ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}<=TableRows({-my:1}):
			{-my:2}++, ct_0={-my:1}, ct_1={-my:2})
			if (TableRowIsBlank(ct_0, ct_1)==false)
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).
To repeat through (T - table name) in reverse order begin -- end loop
	(documented at ph_repeattablereverse): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=TableRows({-my:1}), ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}>=1:
			{-my:2}--, ct_0={-my:1}, ct_1={-my:2})
			if (TableRowIsBlank(ct_0, ct_1)==false)
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).
To repeat through (T - table name) in (TC - table column) order begin -- end loop
	(documented at ph_repeattablecol): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=TableNextRow({-my:1}, {TC}, 0, 1), ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}~=0:
			{-my:2}=TableNextRow({-my:1}, {TC}, {-my:2}, 1), ct_0={-my:1}, ct_1={-my:2})
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).
To repeat through (T - table name) in reverse (TC - table column) order begin -- end loop
	(documented at ph_repeattablecolreverse): (-
		@push {-my:ct_0}; @push {-my:ct_1};
		for ({-my:1}={T}, {-my:2}=TableNextRow({-my:1}, {TC}, 0, -1), ct_0={-my:1}, ct_1={-my:2}:
			{-my:2}~=0:
			{-my:2}=TableNextRow({-my:1}, {TC}, {-my:2}, -1), ct_0={-my:1}, ct_1={-my:2})
				{-block}
		@pull {-my:ct_1}; @pull {-my:ct_0};
	-).

@ And this loops through the lines of a text file stored internally.

=
To repeat with (loopvar - nonexisting text variable)
	running through (F - internal file) begin -- end loop:
	(-
		for ({-my:1} = InternalFileIO_Line({-by-reference:loopvar}, {F}): {-my:1}:
			{-my:1} = InternalFileIO_Line({-by-reference:loopvar}, {F}))
			{-block}
	-).

@ The equivalent of |break| or |continue| in C or I6, or of |last| or |next|
in Perl. Here "in loop" means "in any of the forms of while or repeat".

See test case |BIP-Break|.

=
Section 4 - Loop Flow

To break -- in loop
	(documented at ph_break):
	(- {-primitive-definition:break} -).
To next -- in loop
	(documented at ph_next):
	(- continue; -).

@h Values.
Some of the things we can do with enumerations, others being listed under
randomness below.

See test case |BIP-Enumerations|.

=
Chapter 4 - Values

Section 1 - Enumerations

To decide which number is number of (S - description of values)
	(documented at ph_numberof):
	(- {-primitive-definition:number-of} -).
To decide what number is the numerical value of (X - enumerated value): (- {X} -).
To decide what number is the sequence number of (X - enumerated value of kind K):
	(- {-indexing-routine:K}({X}) -).
To decide which K is (name of kind of enumerated value K) after (X - K)
	(documented at ph_enumafter):
	(- {-next-routine:K}({X}) -).
To decide which K is (name of kind of enumerated value K) before (X - K)
	(documented at ph_enumbefore):
	(- {-previous-routine:K}({X}) -).
To decide which K is the first value of (name of kind of enumerated value K)
	(documented at ph_enumfirst):
	decide on the default value of K.
To decide which K is the last value of (name of kind of enumerated value K)
	(documented at ph_enumlast):
	decide on K before the default value of K.

@ Random numbers and random items chosen from sets of objects matching a
given description ("a random closed door").

See test case |BIP-Randomness|.

=
Section 2 - Randomness

To decide which K is a/-- random (S - description of values of kind K)
	(documented at ph_randomdesc):
	(- {-primitive-definition:random-of} -).
To decide which K is a random (name of kind of arithmetic value K) between (first value - K) and (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide which K is a random (name of kind of arithmetic value K) from (first value - K) to (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide which K is a random (name of kind of enumerated value K) between (first value - K) and (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide which K is a random (name of kind of enumerated value K) from (first value - K) to (second value - K)
	(documented at ph_randombetween):
	(- {-ranger-routine:K}({first value}, {second value}) -).
To decide whether a random chance of (N - number) in (M - number) succeeds
	(documented at ph_randomchance):
	(- (GenerateRandomNumber(1, {M}) <= {N}) -).
To seed the random-number generator with (N - number)
	(documented at ph_seed):
	(- VM_Seed_RNG({N}); -).

@ A novel feature of Inform is that there is a default value of any kind: for
example, it is 0 for a number, or the empty text for text. When Inform compiles
a value of a given kind but isn't told what value to compile, it always
chooses the default, which is why the following definition works.

See test case |BIP-DefaultValues|.

=
Section 3 - Default Values

To decide what K is the default value of (V - name of kind of value of kind K)
	(documented at ph_defaultvalue):
	(- {-new:K} -).

@h Text.
Inform programs swim in a sea of texts, and most of the ways to make text
involve substitutions; so phrases to manipulate text are nice to have, but
are bonuses rather than being the essentials.

As repetitive as the following is, it's much simpler and less prone to
possible namespace trouble if we don't define kinds of value for the different
structural levels of text (character, word, punctuated word, etc.).

See test case |BIP-Texts|.

=
Chapter 5 - Text

Section 1 - Breaking down text

To decide what number is the number of characters in (T - text)
	(documented at ph_numchars):
	(- TEXT_TY_BlobAccess({-by-reference:T}, CHR_BLOB) -).
To decide what number is the number of words in (T - text)
	(documented at ph_numwords):
	(- TEXT_TY_BlobAccess({-by-reference:T}, WORD_BLOB) -).
To decide what number is the number of punctuated words in (T - text)
	(documented at ph_numpwords):
	(- TEXT_TY_BlobAccess({-by-reference:T}, PWORD_BLOB) -).
To decide what number is the number of unpunctuated words in (T - text)
	(documented at ph_numupwords):
	(- TEXT_TY_BlobAccess({-by-reference:T}, UWORD_BLOB) -).
To decide what number is the number of lines in (T - text)
	(documented at ph_numlines):
	(- TEXT_TY_BlobAccess({-by-reference:T}, LINE_BLOB) -).
To decide what number is the number of paragraphs in (T - text)
	(documented at ph_numparas):
	(- TEXT_TY_BlobAccess({-by-reference:T}, PARA_BLOB) -).

To decide what text is character number (N - a number) in (T - text)
	(documented at ph_charnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, CHR_BLOB) -).
To decide what text is word number (N - a number) in (T - text)
	(documented at ph_wordnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, WORD_BLOB) -).
To decide what text is punctuated word number (N - a number) in (T - text)
	(documented at ph_pwordnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, PWORD_BLOB) -).
To decide what text is unpunctuated word number (N - a number) in (T - text)
	(documented at ph_upwordnum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, UWORD_BLOB) -).
To decide what text is line number (N - a number) in (T - text)
	(documented at ph_linenum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, LINE_BLOB) -).
To decide what text is paragraph number (N - a number) in (T - text)
	(documented at ph_paranum):
	(- TEXT_TY_GetBlob({-new:text}, {-by-reference:T}, {N}, PARA_BLOB) -).

@ The "substituted form of" is a technicality most Inform users never need to
think about; as a one-off phrase, it may as well go here.

=
To decide what text is the substituted form of (T - text)
	(documented at ph_subform):
	(- TEXT_TY_SubstitutedForm({-new:text}, {-by-reference:T}) -).

@ A common matching engine is used for matching plain text...

See test case |BIP-TextReplacement|.

=
Section 2 - Matching and Replacing

To decide if (T - text) exactly matches the text (find - text),
	case insensitively
	(documented at ph_exactlymatches):
	(- TEXT_TY_Replace_RE(CHR_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options},1) -).
To decide if (T - text) matches the text (find - text),
	case insensitively
	(documented at ph_matches):
	(- TEXT_TY_Replace_RE(CHR_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options}) -).
To decide what number is number of times (T - text) matches the text
	(find - text), case insensitively
	(documented at ph_nummatches):
	(- TEXT_TY_Replace_RE(CHR_BLOB,{-by-reference:T},{-by-reference:find},1,{phrase options}) -).

To replace the text (find - text) in (T - text) with (replace - text),
	case insensitively
	(documented at ph_replace):
	(- TEXT_TY_Replace_RE(CHR_BLOB, {-lvalue-by-reference:T}, {-by-reference:find},
		{-by-reference:replace}, {phrase options}); -).
To replace the word (find - text) in (T - text) with
	(replace - text)
	(documented at ph_replacewordin):
	(- TEXT_TY_ReplaceText(WORD_BLOB, {-lvalue-by-reference:T}, {-by-reference:find}, {-by-reference:replace}); -).
To replace the punctuated word (find - text) in (T - text)
	with (replace - text)
	(documented at ph_replacepwordin):
	(- TEXT_TY_ReplaceText(PWORD_BLOB, {-lvalue-by-reference:T}, {-by-reference:find}, {-by-reference:replace}); -).

To replace character number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replacechar):
	(- TEXT_TY_ReplaceBlob(CHR_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace word number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replaceword):
	(- TEXT_TY_ReplaceBlob(WORD_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace punctuated word number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replacepword):
	(- TEXT_TY_ReplaceBlob(PWORD_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace unpunctuated word number (N - a number) in (T - text)
	with (replace - text)
	(documented at ph_replaceupword):
	(- TEXT_TY_ReplaceBlob(UWORD_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace line number (N - a number) in (T - text) with (replace - text)
	(documented at ph_replaceline):
	(- TEXT_TY_ReplaceBlob(LINE_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).
To replace paragraph number (N - a number) in (T - text) with (replace - text)
	(documented at ph_replacepara):
	(- TEXT_TY_ReplaceBlob(PARA_BLOB, {-lvalue-by-reference:T}, {N}, {-by-reference:replace}); -).

@ ...and for regular expressions, though here we also have access to the
exact text which matched (not interesting in the plain text case since it's
the same as the search text, up to case at least), and the values of matched
subexpressions (which the plain text case doesn't have).

See test case |BIP-RegExp|.

=
Section 3 - Regular Expressions

To decide if (T - text) exactly matches the regular expression (find - text),
	case insensitively
	(documented at ph_exactlymatchesre):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options},1) -).
To decide if (T - text) matches the regular expression (find - text),
	case insensitively
	(documented at ph_matchesre):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB,{-by-reference:T},{-by-reference:find},0,{phrase options}) -).
To decide what text is text matching regular expression
	(documented at ph_matchtext):
	(- TEXT_TY_RE_GetMatchVar(0) -).
To decide what text is text matching subexpression (N - a number)
	(documented at ph_subexpressiontext):
	(- TEXT_TY_RE_GetMatchVar({N}) -).
To decide what number is number of times (T - text) matches the regular expression
	(find - text),case insensitively
	(documented at ph_nummatchesre):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB,{-by-reference:T},{-by-reference:find},1,{phrase options}) -).
To replace the regular expression (find - text) in (T - text) with
	(replace - text), case insensitively
	(documented at ph_replacere):
	(- TEXT_TY_Replace_RE(REGEXP_BLOB, {-lvalue-by-reference:T}, {-by-reference:find},
		{-by-reference:replace}, {phrase options}); -).

@ Casing of text.

See test case |BIP-TextCasing|.

=
Section 4 - Casing of Text

To decide what text is (T - text) in lower case
	(documented at ph_lowercase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 0) -).
To decide what text is (T - text) in upper case
	(documented at ph_uppercase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 1) -).
To decide what text is (T - text) in title case
	(documented at ph_titlecase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 2) -).
To decide what text is (T - text) in sentence case
	(documented at ph_sentencecase):
	(- TEXT_TY_CharactersToCase({-new:text}, {-by-reference:T}, 3) -).
To decide if (T - text) is in lower case
	(documented at ph_inlower):
	(- TEXT_TY_CharactersOfCase({-by-reference:T}, 0) -).
To decide if (T - text) is in upper case
	(documented at ph_inupper):
	(- TEXT_TY_CharactersOfCase({-by-reference:T}, 1) -).

@h Adaptive text.

See test case |BIP-AdaptiveText|.

=
Section 5 - Adaptive Text

To say infinitive of (V - a verb)
	(documented at phs_infinitive):
	(- {V}(1); -).
To say past participle of (V - a verb)
	(documented at phs_pastpart):
	(- {V}(2); -).
To say present participle of (V - a verb)
	(documented at phs_prespart):
	(- {V}(3); -).

To say adapt (V - verb)
	(documented at phs_adapt):
	(- {V}(CV_POS, PNToVP(), story_tense); -).
To say adapt (V - verb) in (T - grammatical tense)
	(documented at phs_adaptt):
	(- {V}(CV_POS, PNToVP(), {T}); -).
To say adapt (V - verb) from (P - narrative viewpoint)
	(documented at phs_adaptv):
	(- {V}(CV_POS, {P}, story_tense); -).
To say adapt (V - verb) in (T - grammatical tense) from (P - narrative viewpoint)
	(documented at phs_adaptvt):
	(- {V}(CV_POS, {P}, {T}); -).
To say negate (V - verb)
	(documented at phs_negate):
	(- {V}(CV_NEG, PNToVP(), story_tense); -).
To say negate (V - verb) in (T - grammatical tense)
	(documented at phs_negatet):
	(- {V}(CV_NEG, PNToVP(), {T}); -).
To say negate (V - verb) from (P - narrative viewpoint)
	(documented at phs_negatev):
	(- {V}(CV_NEG, {P}, story_tense); -).
To say negate (V - verb) in (T - grammatical tense) from (P - narrative viewpoint)
	(documented at phs_negatevt):
	(- {V}(CV_NEG, {P}, {T}); -).

To decide which relation of objects is meaning of (V - a verb): (- {V}(CV_MEANING) -).

@h Data Structures.
Inform provides three main data structures: tables, lists, and relations,
which we will take in that order.

Tables mimic tables of data as seen in books or scientific papers. Note that
changing a table entry is not something defined here as a phrase: the
ever-powerful "now" can do that. But changing something to a non-value --
or "blanking" it -- requires specialist phrases.

See test case |BIP-Tables|.

=
Chapter 6 - Data Structures

Section 1 - Tables

To choose a/the/-- row (N - number) in/from (T - table name)
	(documented at ph_chooserow):
	(- {-my:ct_0} = {T}; {-my:ct_1} = {N}; -).
To choose a/the/-- row with (TC - K valued table column) of (w - value of kind K)
	in/from (T - table name)
	(documented at ph_chooserowwith):
	(- {-my:ct_0} = {T}; {-my:ct_1} = TableRowCorr(ct_0, {TC}, {w}); -).
To choose a/the/-- blank row in/from (T - table name)
	(documented at ph_chooseblankrow):
	(- {-my:ct_0} = {T}; {-my:ct_1} = TableBlankRow(ct_0); -).
To choose a/the/-- random row in/from (T - table name)
	(documented at ph_chooserandomrow):
	(- {-my:ct_0} = {T}; {-my:ct_1} = TableRandomRow(ct_0); -).
To decide which number is number of rows in/from (T - table name)
	(documented at ph_numrows):
	(- TableRows({T}) -).
To decide which number is number of blank rows in/from (T - table name)
	(documented at ph_numblank):
	(- TableBlankRows({T}) -).
To decide which number is number of filled rows in/from (T - table name)
	(documented at ph_numfilled):
	(- TableFilledRows({T}) -).
To decide if there is (TR - table-reference)
	(documented at ph_thereis):
	(- ({-reference-exists:TR}) -).
To decide if there is no (TR - table-reference)
	(documented at ph_thereisno):
	(- ({-reference-exists:TR} == false) -).
To blank out (tr - table-reference)
	(documented at ph_blankout):
	(- {-by-reference-blank-out:tr}; -).
To blank out the whole row
	(documented at ph_blankoutrow):
	(- TableBlankOutRow({-my:ct_0}, {-my:ct_1}); -).
To blank out the whole (TC - table column) in/from/of (T - table name)
	(documented at ph_blankoutcol):
	(- TableBlankOutColumn({T}, {TC}); -).
To blank out the whole of (T - table name)
	(documented at ph_blankouttable):
	(- TableBlankOutAll({T}); -).

@ These four are for debugging purposes only, and are used in the same test
case. "Showme the contents of ..." is not a text substitution, for efficiency
reasons: for a large table it could produce a gargantuan output, and in a
story file with memory constraints, one might not want to store that in a
text variable.

=
To showme the contents of (T - table name)
	(documented at ph_showmetable):
	(- TableDebug({T}); -).
To say the/-- current table row
	(documented at phs_currenttablerow):
	(- TableRowDebug({-my:ct_0}, {-my:ct_1}); -).
To say row (N - number) in/from (T - table name)
	(documented at phs_tablerow):
	(- TableRowDebug({T}, {N}); -).
To say (TC - table column) in/from (T - table name)
	(documented at phs_tablecolumn):
	(- TableColumnDebug({T}, {TC}); -).

@ Sorting.

See test case |BIP-TableSort|.

=
Section 2 - Sorting Tables

To sort (T - table name) in/into random order
	(documented at ph_sortrandom):
	(- TableShuffle({T}); -).
To sort (T - table name) in/into (TC - table column) order
	(documented at ph_sortcolumn):
	(- TableSort({T}, {TC}, 1); -).
To sort (T - table name) in/into reverse (TC - table column) order
	(documented at ph_sortcolumnreverse):
	(- TableSort({T}, {TC}, -1); -).

@h Lists.
The following are all for adding and removing values to dynamic lists.

See test case |BIP-Lists|.

=
Section 3 - Lists

To add (new entry - K) to (L - list of values of kind K), if absent
	(documented at ph_addtolist):
	(- LIST_OF_TY_InsertItem({-lvalue-by-reference:L}, {new entry}, 0, 0, {phrase options}); -).

To add (new entry - K) at entry (E - number) in/from (L - list of values of kind K), if absent
	(documented at ph_addatentry):
	(- LIST_OF_TY_InsertItem({-lvalue-by-reference:L}, {new entry}, 1, {E}, {phrase options}); -).

To add (LX - list of Ks) to (L - list of values of kind K), if absent
	(documented at ph_addlisttolist):
	(- LIST_OF_TY_AppendList({-lvalue-by-reference:L}, {-by-reference:LX}, 0, 0, {phrase options}); -).

To add (LX - list of Ks) at entry (E - number) in/from (L - list of values of kind K)
	(documented at ph_addlistatentry):
	(- LIST_OF_TY_AppendList({-lvalue-by-reference:L}, {-by-reference:LX}, 1, {E}, 0); -).

To remove (existing entry - K) in/from (L - list of values of kind K), if present
	(documented at ph_remfromlist):
	(- LIST_OF_TY_RemoveValue({-lvalue-by-reference:L}, {existing entry}, {phrase options}); -).

To remove (N - list of Ks) in/from (L - list of values of kind K), if present
	(documented at ph_remlistfromlist):
	(- LIST_OF_TY_Remove_List({-lvalue-by-reference:L}, {-by-reference:N}, {phrase options}); -).

To remove entry (N - number) in/from (L - list of values), if present
	(documented at ph_rementry):
	(- LIST_OF_TY_RemoveItemRange({-lvalue-by-reference:L}, {N}, {N}, {phrase options}); -).

To remove entries (N - number) to (N2 - number) in/from (L - list of values), if present
	(documented at ph_rementries):
	(- LIST_OF_TY_RemoveItemRange({-lvalue-by-reference:L}, {N}, {N2}, {phrase options}); -).

@ Searching a list is implemented in a somewhat crude way at present, and the
following syntax may later be replaced with a suitable verb "to be listed
in", so that there's no need to imitate.

=
To decide if (N - K) is listed in (L - list of values of kind K)
	(documented at ph_islistedin):
	(- (LIST_OF_TY_FindItem({-by-reference:L}, {N})) -).

To decide if (N - K) is not listed in (L - list of values of kind K)
	(documented at ph_isnotlistedin):
	(- (LIST_OF_TY_FindItem({-by-reference:L}, {N}) == false) -).

@ A description is a representation of a set of objects by means of a
predicate (e.g., "open unlocked doors"), and it converts into a list of
current members (in creation order), but there's no reverse process.

=
To decide what list of Ks is the list of (D - description of values of kind K)
	(documented at ph_listofdesc):
	(- {-new-list-of:list of K} -).

@ Determining and setting the length:

See test case |BIP-ListLength|.

=
Section 4 - Length of lists

To decide what number is the number of entries in/of/from (L - a list of values)
	(documented at ph_numberentries):
	(- LIST_OF_TY_GetLength({-by-reference:L}) -).
To truncate (L - a list of values) to (N - a number) entries/entry
	(documented at ph_truncate):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, -1, 1); -).
To truncate (L - a list of values) to the first (N - a number) entries/entry
	(documented at ph_truncatefirst):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, -1, 1); -).
To truncate (L - a list of values) to the last (N - a number) entries/entry
	(documented at ph_truncatelast):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, -1, -1); -).
To extend (L - a list of values) to (N - a number) entries/entry
	(documented at ph_extend):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, 1); -).
To change (L - a list of values) to have (N - a number) entries/entry
	(documented at ph_changelength):
	(- LIST_OF_TY_SetLength({-lvalue-by-reference:L}, {N}, 0); -).

@ Easy but useful list operations. Sorting ultimately uses a common sorting
mechanism, in "Sort.i6t", which handles both lists and tables.

See test case |BIP-ListOperations|.

=
Section 5 - List operations

To reverse (L - a list of values)
	(documented at ph_reverselist):
	(- LIST_OF_TY_Reverse({-lvalue-by-reference:L}); -).
To rotate (L - a list of values)
	(documented at ph_rotatelist):
	(- LIST_OF_TY_Rotate({-lvalue-by-reference:L}, 0); -).
To rotate (L - a list of values) backwards
	(documented at ph_rotatelistback):
	(- LIST_OF_TY_Rotate({-lvalue-by-reference:L}, 1); -).
To sort (L - a list of values)
	(documented at ph_sortlist):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, 1); -).
To sort (L - a list of values) in/into reverse order
	(documented at ph_sortlistreverse):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, -1); -).
To sort (L - a list of values) in/into random order
	(documented at ph_sortlistrandom):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, 2); -).
To sort (L - a list of objects) in/into (P - property) order
	(documented at ph_sortlistproperty):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, 1, {P}, {-property-holds-block-value:P}); -).
To sort (L - a list of objects) in/into reverse (P - property) order
	(documented at ph_sortlistpropertyreverse):
	(- LIST_OF_TY_Sort({-lvalue-by-reference:L}, -1, {P}, {-property-holds-block-value:P}); -).

@ Relations are the final data structure given here. In some ways they are
the most fundamental of all, but they're not either set or tested by
procedural phrases -- they lie in the linguistic structure of conditions.
So all we have here are the route-finding phrases:

See test case |BIP-Relations|.

=
Section 6 - Relations

To show relation (R - relation)
	(documented at ph_showrelation):
	(- {-show-me:R}; RelationTest({-by-reference:R}, RELS_SHOW); -).

To decide which object is next step via (R - relation of objects)
	from (O1 - object) to (O2 - object)
	(documented at ph_nextstep):
	(- RelationRouteTo({-by-reference:R},{O1},{O2},false) -).
To decide which number is number of steps via (R - relation of objects)
	from (O1 - object) to (O2 - object)
	(documented at ph_numbersteps):
	(- RelationRouteTo({-by-reference:R},{O1},{O2},true) -).

To decide which list of Ks is list of (name of kind of value K)
	that/which/whom (R - relation of Ks to values of kind L) relates
	(documented at ph_leftdomain):
	(- RelationTest({-by-reference:R}, RELS_LIST, {-new:list of K}, RLIST_ALL_X) -).

To decide which list of Ls is list of (name of kind of value L)
	to which/whom (R - relation of values of kind K to Ls) relates
	(documented at ph_rightdomain):
	(- RelationTest({-by-reference:R}, RELS_LIST, {-new:list of L}, RLIST_ALL_Y) -). [1]

To decide which list of Ls is list of (name of kind of value L)
	that/which/whom (R - relation of values of kind K to Ls) relates to
	(documented at ph_rightdomain):
	(- RelationTest({-by-reference:R}, RELS_LIST, {-new:list of L}, RLIST_ALL_Y) -). [2]

To decide which list of Ks is list of (name of kind of value K) that/which/who
	relate to (Y - L) by (R - relation of Ks to values of kind L)
	(documented at ph_leftlookuplist):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ALL_X, {Y}, {-new:list of K}) -).

To decide which list of Ls is list of (name of kind of value L) to which/whom (X - K)
	relates by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookuplist):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ALL_Y, {X}, {-new:list of L}) -). [1]

To decide which list of Ls is list of (name of kind of value L)
	that/which/whom (X - K) relates to by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookuplist):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ALL_Y, {X}, {-new:list of L}) -). [2]

To decide whether (name of kind of value K) relates to (Y - L) by
	(R - relation of Ks to values of kind L)
	(documented at ph_ifright):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {Y}, RLANY_CAN_GET_X) -).

To decide whether (X - K) relates to (name of kind of value L) by
	(R - relation of values of kind K to Ls)
	(documented at ph_ifleft):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {X}, RLANY_CAN_GET_Y) -).

To decide which K is (name of kind of value K) that/which/who relates to
	(Y - L) by (R - relation of Ks to values of kind L)
	(documented at ph_leftlookup):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {Y}, RLANY_GET_X) -).

To decide which L is (name of kind of value L) to which/whom (X - K)
	relates by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookup):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {X}, RLANY_GET_Y) -). [1]

To decide which L is (name of kind of value L) that/which/whom (X - K)
	relates to by (R - relation of values of kind K to Ls)
	(documented at ph_rightlookup):
	(- RelationTest({-by-reference:R}, RELS_LOOKUP_ANY, {X}, RLANY_GET_Y) -). [2]

@h Functional Programming.
Here we have the ability to use the name of a function as a value, and to
apply such a function.

See test case |BIP-Apply|.

=
Chapter 7 - Functional Programming

Section 1 - Applying Functions

To decide whether (val - K) matches (desc - description of values of kind K)
	(documented at ph_valuematch):
	(- {-primitive-definition:description-application} -).

To decide what K is (function - phrase nothing -> value of kind K) applied
	(documented at ph_applied0):
	(- {-primitive-definition:function-application} -).

To decide what L is (function - phrase value of kind K -> value of kind L)
	applied to (input - K)
	(documented at ph_applied1):
	(- {-primitive-definition:function-application} -).

To decide what M is (function - phrase (value of kind K, value of kind L) -> value of kind M)
	applied to (input - K) and (second input - L)
	(documented at ph_applied2):
	(- {-primitive-definition:function-application} -).

To decide what N is (function - phrase (value of kind K, value of kind L, value of kind M) -> value of kind N)
	applied to (input - K) and (second input - L) and (third input - M)
	(documented at ph_applied3):
	(- {-primitive-definition:function-application} -).

To apply (function - phrase nothing -> nothing)
	(documented at ph_apply0):
	(- {-primitive-definition:function-application}; -).

To apply (function - phrase value of kind K -> nothing)
	to (input - K)
	(documented at ph_apply1):
	(- {-primitive-definition:function-application}; -).

To apply (function - phrase (value of kind K, value of kind L) -> nothing)
	to (input - K) and (second input - L)
	(documented at ph_apply2):
	(- {-primitive-definition:function-application}; -).

To apply (function - phrase (value of kind K, value of kind L, value of kind M) -> nothing)
	to (input - K) and (second input - L) and (third input - M)
	(documented at ph_apply3):
	(- {-primitive-definition:function-application}; -).

@ The standard map, reduce and filter operations found in most functional
programming languages also have Inform analogues.

See test case |BIP-Map|.

=
Section 2 - Working with Lists

To decide what list of L is (function - phrase K -> value of kind L) applied to (original list - list of values of kind K)
	(documented at ph_appliedlist):
	let the result be a list of Ls;
	repeat with item running through the original list:
		let the mapped item be the function applied to the item;
		add the mapped item to the result;
	decide on the result.

To decide what K is the (function - phrase (K, K) -> K) reduction of (original list - list of values of kind K)
	(documented at ph_reduction):
	let the total be a K;
	let the count be 0;
	repeat with item running through the original list:
		increase the count by 1;
		if the count is 1, now the total is the item;
		otherwise now the total is the function applied to the total and the item;
	decide on the total.

To decide what list of K is the filter to (criterion - description of Ks) of
	(full list - list of values of kind K)
	(documented at ph_filter):
	let the filtered list be a list of K;
	repeat with item running through the full list:
		if the item matches the criterion:
			add the item to the filtered list;
	decide on the filtered list.

@h Rulebooks and Activities.

Firing off activities:

See test case |BIP-Activities|.

=
Chapter 8 - Rulebooks and Activities

Section 1 - Carrying out Activities

To carry out the (A - activity on nothing) activity
	(documented at ph_carryout):
	(- CarryOutActivity({A}); -).
To carry out the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_carryoutwith):
	(- CarryOutActivity({A}, {val}); -).
To continue the activity
	(documented at ph_continueactivity):
	(- rfalse; -) - in to only.

@ Advanced activity phrases: for setting up one's own activities structured
around I7 source text. People tend not to use this much, and perhaps that's
a good thing, but it does open up possibilities, and it's good for
retro-fitting onto extensions to make them more customisable.

These are really only useful in an activity-rich environment, in any case.
See the documentation example |AntSensitiveSunglasses|.

=
Section 2 - Advanced Activities

To begin the (A - activity on nothing) activity
	(documented at ph_beginactivity):
	(- BeginActivity({A}); -).
To begin the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_beginactivitywith):
	(- BeginActivity({A}, {val}); -).
To decide whether handling (A - activity) activity
	(documented at ph_handlingactivity):
	(- (~~(ForActivity({A}))) -).
To decide whether handling (A - activity on value of kind K) activity with (val - K)
	(documented at ph_handlingactivitywith):
	(- (~~(ForActivity({A}, {val}))) -).
To end the (A - activity on nothing) activity
	(documented at ph_endactivity):
	(- EndActivity({A}); -).
To end the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_endactivitywith):
	(- EndActivity({A}, {val}); -).
To abandon the (A - activity on nothing) activity
	(documented at ph_abandonactivity):
	(- AbandonActivity({A}); -).
To abandon the (A - activity on value of kind K) activity with (val - K)
	(documented at ph_abandonactivitywith):
	(- AbandonActivity({A}, {val}); -).

@ Here are four different ways to invoke a rule or rulebook:

See test case |BIP-Rules|.

=
Section 3 - Following Rules

To follow (RL - a rule)
	(documented at ph_follow):
	(- FollowRulebook({RL}); -).
To follow (RL - value of kind K based rule producing a value) for (V - K)
	(documented at ph_followfor):
	(- FollowRulebook({RL}, {V}, true); -).
To follow (RL - a nothing based rule)
	(documented at ph_follow):
	(- FollowRulebook({RL}); -).
To decide what K is the (name of kind K) produced by (RL - rule producing a value of kind K)
	(documented at ph_producedby):
	(- ResultOfRule({RL}, 0, true, {-strong-kind:K}) -).
To decide what L is the (name of kind L) produced by (RL - value of kind K based rule
	producing a value of kind L) for (V - K)
	(documented at ph_producedbyfor):
	(- ResultOfRule({RL}, {V}, true, {-strong-kind:L}) -).
To decide what K is the (name of kind K) produced by (RL - nothing based rule producing a value of kind K)
	(documented at ph_producedby):
	(- ResultOfRule({RL}, 0, true, {-strong-kind:K}) -).
To abide by (RL - a rule)
	(documented at ph_abide):
	(- if (FollowRulebook({RL})) rtrue; -) - in to only.
To abide by (RL - value of kind K based rule producing a value) for (V - K)
	(documented at ph_abidefor):
	(- if (FollowRulebook({RL}, {V}, true)) rtrue; -) - in to only.
To abide by (RL - a nothing based rule)
	(documented at ph_abide):
	(- if (FollowRulebook({RL})) rtrue; -) - in to only.

@ Rules return |true| to indicate a decision, which could be either a success
or a failure, and optionally may also return a value. If they return |false|,
there's no decision.

See test case |BIP-Rules| once again.

=
Section 4 - Success and Failure

To make no decision
	(documented at ph_nodecision): (- rfalse; -) - in to only.
To rule succeeds
	(documented at ph_succeeds):
	(- RulebookSucceeds(); rtrue; -) - in to only.
To rule fails
	(documented at ph_fails):
	(- RulebookFails(); rtrue; -) - in to only.
To rule succeeds with result (val - a value)
	(documented at ph_succeedswith):
	(- RulebookSucceeds({-strong-kind:rule-return-kind},{-return-value-from-rule:val}); rtrue; -) - in to only.
To decide if rule succeeded
	(documented at ph_succeeded):
	(- (RulebookSucceeded()) -).
To decide if rule failed
	(documented at ph_failed):
	(- (RulebookFailed()) -).
To decide which rulebook outcome is the outcome of the rulebook
	(documented at ph_rulebookoutcome):
	(- (ResultOfRule()) -).

@h External Files.
Inform has a quirky level of support for file-handling, which comes out what
the Glulx virtual machine will support.

See test case |BIP-Files-G|, which has no Z-machine counterpart.

=
Chapter 9 - External Files (not for Z-machine)

Section 1 - Files of Text

To write (T - text) to (FN - external file)
	(documented at ph_writetext):
	(- FileIO_PutContents({FN}, {T}, false); -).
To append (T - text) to (FN - external file)
	(documented at ph_appendtext):
	(- FileIO_PutContents({FN}, {T}, true); -).
To say text of (FN - external file)
	(documented at ph_saytext):
	(- FileIO_PrintContents({FN}); say__p = 1; -).

@ See test case |BIP-FilesOfTables-G|, which has no Z-machine counterpart.

=
Section 2 - Files of Data

To read (filename - external file) into (T - table name)
	(documented at ph_readtable):
	(- FileIO_GetTable({filename}, {T}); -).
To write (filename - external file) from (T - table name)
	(documented at ph_writetable):
	(- FileIO_PutTable({filename}, {T}); -).

@ These are hardly used phrases which are difficult to test convincingly
in our framework, since they defend against independent Inform programs
simultaneously trying to access the same file.

=
Section 3 - File Handling

To decide if (filename - external file) exists
	(documented at ph_fileexists):
	(- (FileIO_Exists({filename}, false)) -).
To decide if ready to read (filename - external file)
	(documented at ph_fileready):
	(- (FileIO_Ready({filename}, false)) -).
To mark (filename - external file) as ready to read
	(documented at ph_markfileready):
	(- FileIO_MarkReady({filename}, true); -).
To mark (filename - external file) as not ready to read
	(documented at ph_markfilenotready):
	(- FileIO_MarkReady({filename}, false); -).

@h Use Options.

=
Chapter 10 - Use Options

Section 1 - Numerical Value

To decide what number is the numerical value of (U - a use option):
	(- USE_OPTION_VALUES-->({U}) -).
