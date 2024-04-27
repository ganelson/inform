[NeptuneManual::] A Brief Guide to Neptune.

A manual for the mini-language used in Neptune files.

@h Purpose.
Neptune is a simple mini-language for defining the built-in kinds of Inform.
Each kit of Inter code can supply one or more Neptune files: for example,
|WorldModelKit| supplies a file called |Scenes.neptune| which defines the
built-in base kind "scene".

The name is nothing to do with the planet and derives from the Place Neptune,
Carcassonne, where these files were first implemented in August 2007. The
syntax was made more legible in 2020.

@h Comments and white space.
Lines consisting of white space or whose first non-white space character is
|!| are ignored as comments, but note that a |!| later in a line which already
has other content will not be treated as a comment.

All white space at the start or end of a line is similarly ignored. Indentation
can be used for clarity, but has no significance.

@h Declarations.
Otherwise, a Neptune file is a series of declarations. Each must begin with
a header line which ends in an open brace, and must conclude with a line
consisting only of a close brace.

@ A constructor is created with two initial keywords, and then its identifier
name. The first keyword must be either |new| or |builtin|. The only difference
here is that |builtin| must be used if the constructor being made is one of
the //Familiar Kinds//, whose identifier has to correspond to one of those
hardwired into the code of this module. |new| must be used in all other cases.[1]

The second keyword must be one of the following:
(*) |base| for a new base kind, like |NUMBER_TY|.
(*) |constructor| for a proper constructor, like |LIST_OF_TY|.
(*) |protocol| for a kind of kind, like |SAYABLE_VALUE_TY|.
(*) |punctuation| for a constructor with no independent meaning, such as |INTERMEDIATE_TY|.

For example:

= (text)
builtin protocol SAYABLE_VALUE_TY {
	conforms-to: STORED_VALUE_TY
	singular: sayable value
	plural: sayable values
}
=

[1] The distinction really only exists as a mnemonic - it reminds us that it
wouldn't be safe to change the identifier without also changing the compiler.

@ A "macro" is a set of commands which could be applied to any constructor.
It will have no effect unless applied, which happens only by a special command
(see below) or, for certain macro names, when the code in this module applies
it automatically.

For example:
= (text)
macro #REAL {
	conforms-to: REAL_ARITHMETIC_VALUE_TY
}
=
This declares a macro called |#REAL|. All macros have names beginning with a
sharp sign, and continuing with capital letters.

@ An "invention" is a piece of source text to be added to whatever is being
compiled.[1] Invention names begin with an asterisk. For example:
= (text)
invention *UNDERSTOOD-VARIABLE {
	<kind> understood is a <kind> which varies.
}
=
Note that the text is not quite literal, because it can contain wildcards like
|<kind>|, which expands to the name of the kind in question: for instance, we
might get "number understood is a number which varies". The legal wildcards are:
(*) <kind>, expanding to the singular name of the kind.
(*) <lower-case-kind>, the same but always using lower case.
(*) <kind-weak-ID>, the weak ID number for the base kind.
(*) <say-function>, the identifier of its printing routine.
(*) <compare-function>, similarly.

There are a few limitations on what template text can include. Firstly,
nothing with angle brackets in, except where a wildcard appears. Secondly,
each sentence must end at the end of a line, and similarly the colon for
any rule or other definition. Thus this template would fail:
= (text)
invention *UNDERSTOOD-VARIABLE {
	<kind> understood is a <kind> which
	varies. To judge <kind>: say "I judge [<kind> understood]."
}
=
because the first sentence ends in the middle of the second line, and the
colon dividing the phrase header from its definition is also mid-line. The
template must be reformatted thus to work:
= (text)
invention *UNDERSTOOD-VARIABLE {
	<kind> understood is a <kind> which varies.
	To judge <kind>:
		say "I judge [<kind> understood]."
}
=

[1] Inventions are not elegant and have now mostly been phased out, except to
create the "K understood" variables for each base kind conforming to
|understandable value|, using the example invention shown here.

@h Commands.
Inside a macro or a constructor declaration, each line consists of a single
command, always written in the form |command: value|. If the command occurs
in a constructor, it applies to that constructor; if in a macro, it is applied
to whatever constructor the macro is being applied to (if it ever is).

All commands are a single word, though sometimes hyphenated. White space
either side of the |value| is trimmed away. |value| is not allowed to be empty,
or to contain only white space.

@ Constructor declarations are conventionally written in four groups of commands,
though this is just convention. Let's start with the first block, which names
the constructor and locates it in the lattice.

|conforms-to: K| declares that the new kind conforms to the existing kind |K|.
Multiple conformances can be given, but there is seldom any need to, because if
|K| then conforms to |L|, our new kind will do so too. In general, new base
kinds should declare their conformance to the most specific protocol they can.

|compatible-with: K| declares that |K| is compatible with the new kind (note:
not the other way round), in a way needing explicit conversion code at run-time:
i.e., |K| does not conform to the new kind, but can be converted to it.

|singular| and |plural| specify singular and plural natural language names for
the constructor. If these are omitted, it will be impossible to refer to in
source text, but that doesn't necessarily make the constructor useless: the
compiler can still generate it internally. Multiple legal wordings can be
given, divided by vertical strokes. Names of the construction kinds can be
written as |k| and |l| (note lower case). So, for example, |list of k|.

|terms| is used only for proper constructors. For a unary constructor, it will
give one term; for binary, two terms, separated by a comma. Each term should
be |covariant| or |contravariant|, with an optional keyword after it:
(*) |optional| means that it is legal to name the constructor without naming
this term. For example, "activity" is a legal way to say "activity on nothing".
(*) |list| means that it is legal to give a list of kinds here, in brackets
if there are some, or |nothing| if there are not.

|invent-source-text: *NAME| causes new source text to be invented. |*NAME|
must be an invention which has already been declared. If this command is applied
to a protocol, such as |arithmetic value|, then the invention will be made not
for the protocol itself, but for every base kind which conforms to it: this can
result in a stream of similar-looking sentences.

|apply-macro: #NAME| does what it says, really. Here, however, it applies to
protocols just the same as to everything else.

@ The second group concerns behaviours of the kinds in question, or methods
for compiling their data. They are in general meaningless for protocols or
other kinds which don't refer to data stored at run-time.

|default-value| is the default value for an uninitialised variable of this
kind. If this is not set, problem messages may be generated for such variables.

|can-coincide-with-property| is either |yes| or |no| (default |no|), and means
what it says: the name of this kind is allowed also to be the name of a property
which takes values in this kind.

|can-exchange| is either |yes| or |no| (default |no|), and means that data of
this kind can be serialised -- printed out as text into an external file --
and read into a different program, but with the same meaning.

|constant-compilation-method| tells Inform how to compile constants of this
kind. The possible options are: |none|, |literal|, |quantitative| and |special|,
the default being |none|:
(*) |none| means there are no constants of this kind.
(*) |literal| means constants are literals in Inform source text, such as 65 or 11:12 PM.
(*) |quantitative| means they are named instances, as for enumerations.
(*) |special| means that the compiler needs to use ad-hoc code to handle
this kind; unless it contains that code, of course, this can't be used.

|loop-domain-schema| is an Inter schema for iterating through the valid
instances of the kind.

|comparison-schema| is an Inter schema for comparing a value of this kind
with a value of a named other kind to which it does not conform. It should
take the form |NAME>>>SCHEMA|, where |NAME| is the other kind, and |SCHEMA|
the Inter code.

If the kind conforms to |POINTER_VALUE_TY| then it stores values on the heap,
rather than in single words of memory, and in that case three more properies
become meaningful: |multiple-block| is either |yes| or |no| (default |no|), and 
allows data to expand arbitrarily in size if necessary; |heap-size-estimate|
should be a power of 2, and gives an initial allocation size in words; and
|short-block-size| optionally allows a short block (in words) to point to the
data (thus adding further indirection).

|is-incompletely-defined| is either |yes| or |no| (default |no|), and is a
short-term device used to handle kinds which have been created but not yet
turned into units or enumerations.

@ The third group supplies identifier names for Inter routines to perform run-time
duties related to the kind. Inform will simply assume such a routine is present;
this will usually be defined in the same kit which is supplying the Neptune file.

|compare-function| determines which of two values of the kind is greater.
The default is |UnsignedCompare|. The special value |signed| can be used to
ask for signed comparison of the 2s-complement run-time values, which is a
little quicker than calling a routine.

|say-function| prints out a textual representation of a value of the given
kind. These have no effect for kinds which do not conform to |sayable value|.

|understand-function| is a "general parsing routine", which assists the run-time
command parser. |distinguish-function|, similarly, determines whether two
things can be distinguished by textual commands. These have no effect in Basic
Inform projects, or for kinds which do not conform to |understandable value|.

|recognise-function| is a "recognition-only general parsing routine". Again
this has no effect in Basic Inform projects. It is only used for kinds which
do not conform to |understandable value|, but can nevertheless be used when
the command parser allows things to be named by their property values, and
those values have the kind in question.

@ The final group is concerned only with documentation and indexing, and thus
has no effect on compilation.

|documentation-reference| is a reference keyword to the Inform documentation,
which can make be used to improve problem messages or the index by giving little
blue help buttons next to the kind's name.

|index-priority| is a non-negative integer. It is by default 100 for base kinds
and constructors, 0 for protocols and punctuation. 0 in fact means "omit from the
index", which is otherwise grouped in ascending order -- i.e., lowest priority
numbers first.

|index-default-value| can be used in place of the |default-value| in the index,
to make it look prettier.

|index-maximum-value| can similarly override the indexer's automated attempt to
print the largest representable value, and similarly for |index-minimum-value|.

|indexed-grey-if-empty| is either |yes| or |no| (default |no|), and specifies
that if the kind has no instances then it should be tinted grey in the index.

|specification-text| provides the value of the specification pseudo-property
(an oddball feature of the Inform language which seemed like a good idea at
the time). This should be plain text, not HTML.
