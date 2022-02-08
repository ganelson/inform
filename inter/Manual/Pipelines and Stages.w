Pipelines and Stages.

Sequences of named code-generation stages are called pipelines.

@h Stages and descriptions.
A processing stage is a step in code generation which acts on a tree
of inter in memory. Some stages change, add to or edit down that code, while
others leave it untouched but output a file based on it.

Each stage can see an entire tree of inter code at a time, and is
not restricted to working through it in sequence.

Stages are named, which are written without spaces, and conventionally use
hyphens: for example, |resolve-conditional-compilation|. Where a filename has
to be supplied, it appears after a colon. Thus |generate-inter:my.intert|
is a valid stage description.

A "pipeline" is a list of stage descriptions. If the pipeline is spelled
out textually on the command line, then commas are used to divide the stages:
= (text as ConsoleText)
	$ inter/Tangled/inter -pipeline-text 'plugh, xyzzy, plover'
=
If the pipeline is in an external file, we would instead write:
= (text as ConsoleText)
	$ inter/Tangled/inter -pipeline-file mypl.interpipeline
=
and the file |mypl.interpipeline| would have one stage listed on each line,
so that the commas are not needed:
= (text)
	plugh
	xyzzy
	plover

@ A pipeline description can make use of "variables". These hold only text,
and generally represent filenames. Variable names begin with a star |*|.
The pipeline cannot create variables: instead, the user of the pipeline has
to make them before use. For example,
= (text as ConsoleText)
	$ inter/Tangled/inter -variable '*X=ex/why' -pipeline-file mypl.interpipeline
=
creates the variable |*X| with the textual contents |ex/why| before running
the given pipeline. Inside the pipeline, a line such as:
= (text as Inter Pipeline)
	generate inform6 -> *X
=
would then be read as:
= (text as Inter Pipeline)
	generate inform6 -> ex/why
=
After variable substitution like this, filenames inside the pipeline
description are interpreted as follows:

(a) If a filename contains a slash character, it is considered a literal
filename.
(b) If not, it is considered to be a leafname inside the "domain" directory.
By default this is the current working directory, but using |-domain| at
the Inter command line changes that.

The special variable |*log|, which always exists, means the debugging log.
A command to write a text file to |*log| is interpreted instead to mean
"spool the output you would otherwise write to the debugging log instead".
For example,
= (text as Inter Pipeline)
	generate inventory -> *log

@h Pipelines run by Inform.
As the above implies, Inter pipelines normally begin with a clean slate:
no trees, no variables. 

When a pipeline is being run by the main Inform 7 compiler, however,
two variables are created in advance. |*in| is set to the Inter code
which Inform has generated on the current run, and |*out| is set to the
filename to which final code needs to be generated. The practical
effect is that any useful pipeline for Inform will begin and end thus:
= (text as Inter Pipeline)
	read <- *in
	...
	generate -> *out
=
In addition, the "domain" is set to the directory containing the |*out|
file.

To Inbuild and Inform, pipelines are resources in their own right, rather
like extensions or kits. So, for example, the standard distribution includes
= (text)
	inform7/Internal/Pipelines/compile.interpipeline
=
which is the one used for standard compilation runs. A project's Materials
folder is free to provide a replacement:
= (text)
	Strange.materials/Pipelines/compile.interpipeline
=
...and then this will be used instead when compiling |Strange.inform|.

1. This sentence in Inform source text:

>> Use inter pipeline "NAME".

replaces the pipeline normally used for code generation with the one supplied.
(That may very well cause the compiler not to produce viable code, of course.)
The default Inter pipeline is called |compile|, and comes built-in. Named
pipelines are stored alongside named extensions and other resources used by
Inform; so for example you could write:

>> Use inter pipeline "mypipeline".

And then store the actual pipeline file as:
= (text)
	Example Work.materials/Pipelines/mypipeline.interpipeline
=

2. You don't need the Use... sentence, though, if you're willing to choose
on the command line instead:
= (text as ConsoleText)
	$ inform7/Tangled/inform7 ... -pipeline NAME
=
Or, if you want to name a file explicitly, not have it looked for by name:
= (text as ConsoleText)
	$ inform7/Tangled/inform7 ... -pipeline-file FILE
=
3. Finally, you can also give Inform 7 an explicit pipeline in textual form:
= (text as ConsoleText)
	$ inform7/Tangled/inform7 ... -pipeline-text 'PIPELINE'
=
Note that Inbuild and Inform 7 respond to all three of |-pipeline|,
|-pipeline-file| and |-pipeline-text|, whereas Inter responds only to the
last two. (It can't find pipelines by name because it doesn't contain the
supervisor module for sorting out resources.)

@h Syntax of pipeline descriptions.
Pipelines are, roughly speaking, just lists of steps. Each step occupies
a single line: blank lines are ignored, and so are lines whose first non-white-space
character is a |!|, which are considered comments.

A step description is often as simple as being the name of a stage, but
sometimes that name is accompanied by parameters.

The difference between a step and a stage is illustrated by this example:
= (text as Inter Pipeline)
	! This is a comment

	read <- *in

	generate text -> *tout
	generate binary -> *bout
=
Here there are three steps. The first uses the |read| stage; the second and
third use the |generate| stage, but with different parameters.

There are three sorts of stage description: those involving material coming
in, denoted by a left arrow, those involving some external file being written
out, denoted by a right arrow, and those which just process what we have.
These take the following forms:
= (text as Inter Pipeline)
	STAGENAME [TREE] <- SOURCE
	STAGENAME [TREE] [FORMAT] -> DESTINATION
	STAGENAME [TREE]
=
The |STAGENAME| never contains white space; hyphens are used instead. So, for
example, |eliminate-redundant-labels| is a valid |STAGENAME|.

The |[TREE]| is optional. For example:
= (text as Inter Pipeline)
	read 2 <- *in
	generate 3 -> *out
=
Pipeline descriptios allow us to manage up to 10 different Inter trees, and
these are called |0| to |9|. These are all initially empty. Any stage which
doesn't specify a tree is considered to apply to |0|; so pipelines often never
mention the digits |0| to |9| at all because they always work inside |0|.

Another optional feature, not currently made use of by any stages, is that
the description can specify an exact package in a tree, giving its name in URL
form. Thus:
= (text as Inter Pipeline)
	hypothetical-stage /main/whatever
	hypothetical-stage 6:/main/whatever
=
The stages currently built in to //inter// do not work on individual packages,
but they did at one time in the past, and the infrastructure for it remains
in case useful in future.

SOURCE and DESTINATION specify, usually, files to read or write, but they are
often in fact given as variables, whose names start with an asterisk |*|.
Variables have to be set in advance, either at the command line (see above)
or by the tool calling for the pipeline to be run, e.g., the //supervisor//
module inside Inform 7.

@h Dictionary of stages.
The following gives a brief guide to the available stages, in alphabetical
order. See also //pipeline: What This Module Does// for how (some of) these
stages are used when building kits or projects.

@ |compile-splats|.
A "splat" node holds a single Inform 6-written statement or directive, and
thus represents not-yet-compiled material. This stage converts all remaining
splat nodes to Inter code. Note that |resolve-conditional-compilation| must
already have run for this to handle |#ifdef| and the like properly.

For the implementation, see //pipeline: Compile Splats Stage//.

@ |detect-indirect-calls|.
Handles an edge case in linking where a function call in one compilation unit,
e.g., |X(1)|, turned out more complicated because |X|, defined in another
compilation unit, was a variable holding the address of a function, and not
as expected the name of a specific function.

For the implementation, see //pipeline: Detect Indirect Calls Stage//.

@ |eliminate-redundant-labels|.
Performs peephole optimisation on functions to remove all labels which are
declared but can never be jumped to. At the end of this stage, all labels
inside functions are targets of some branch, either by |inv !jump| or in
assembly language.

For the implementation, see //pipeline: Eliminate Redundant Labels Stage//.

@ |eliminate-redundant-matter|.
Works through the dependency graph of the Inter tree to find packages which
are never needed (such as functions never called), and remove them, thus
making the final executable smaller.

Note that this is experimental, does not yet properly work, and is not used
in the built-in |compile| pipeline.

For the implementation, see //pipeline: Eliminate Redundant Matter Stage//.

@ |eliminate-redundant-operations|.
Performs peephole optimisation on functions to remove arithmetic or logical
operations which can be proved to have neither a direct effect nor any
side-effect: for example, performing |x + 0| rather than just evaluating |x|.

For the implementation, see //pipeline: Eliminate Redundant Operations Stage//.

@ |generate [FORMAT] -> [DESTINATION]|.
Produces "final code" in some format, writing it to an external file specified
as the destination. If not given, the format will be the one chosen by the
//supervisor// module. 

Note that the special destination |*log| writes to the debugging log rather
than to some other external file.

The current list of valid formats is: |inform6|, |c|, |binary|, |text|, |inventory|.
Of these |binary| and |text| are faithful, direct representations of Inter trees;
|inventory| is a human-readable summary of the contents; but the others are
genuine conversions to code which can be run through other compilers to
make executable programs.

For the implementation, see //final: Code Generation//.

@ |load-binary-kits|.
Kits are libraries of Inter code which support the operation of Inform programs
at runtime. When "built" (using //inter// with the |build-kit| pipeline), a
kit provides a binary Inter file of code for each possible architecture. This
stage gathers up all needed kits, and loads them into the current tree, thus
considerably expanding it.

Note that the list of "needed" kits has to be specified in advance of the pipeline
being run. For Inform compilations, this is handled automatically by the
//supervisor// module, but it can also be done via the command line.

For the implementation, see //pipeline: Load Binary Kits Stage//.

@ |load-kit-source <- [SOURCE]|.
Reads a file of Inform 6-syntax source code and adds the resulting material to
the Inter tree in the form of a series of "splat" nodes, one for each statement
or directive. Those won't be much use as they stand, but see |compile-splats|.

For the implementation, see //pipeline: Parsing Stages//.

@ |make-identifiers-unique|.
Ensures that symbols marked as needing to be unique will be translated, during
any use of |generate|, to identifiers which are all different from each other
across the entire tree. (In effect, this stage is needed because Inter has
private namespaces within packages, whereas the languages we are transpiling to --
to some extent C, but certainly Inform 6 -- have a single global namespace,
where collisions of identifiers would be very unfortunate.)

At the end of this stage, no symbol still has the |MAKE_NAME_UNIQUE_ISYMF| flag.

For the implementation, see //pipeline: Make Identifiers Unique Stage//.

@ |make-synoptic-module|.
The synoptic module is a top-level section of material in the Inter tree which
contains functions and arrays which index or otherwise gather up material
ranging across all other modules. For example, each module originally presents
itself with its own pieces of literal text, but the synoptic module then
collates all of those together, sorted and de-duplicated.

For the implementation, see //pipeline: Make Synoptic Module Stage//.

@ |move <- LOCATION|.
This moves a branch of one Inter tree to a position in another one, reconciling
the necessary symbol dependencies. For example, |move 1 <- 3:/main/my_fn|
moves the package |/main/my_fn| in tree 3 to the same position in tree 1.
Note that this is a move, not a copy, and is as fast an operation as we can
make it.

This stage is not used in the regular Inform pipelines, but exists to assist
testing of the so-called "transmigration" process, which powers |load-binary-kits|
(see above).

For the implementation, see //pipeline: Read, Move, Stop Stages//.

@ |new|.
A completely empty Inter tree is not very useful. |new| adds the very basic
definitions needed, and gives it a |/main| package.

For the implementation, see //pipeline: New Stage//.

@ |optionally-generate [FORMAT] -> DESTINATION|.
This is identical to |generate| except that if the DESTINATION is given as
a variable which does not exist then no error is produced, and nothing is done.

For the implementation, see //final: Code Generation//.

@ |parse-insertions|.
This looks for |LINK_IST| nodes in the tree, a small number of which may have
been created by the //inform7// compiler in response to uses of |Include (- ... -)|.
These can hold arbitrarily long runs of Inform 6-syntax source code, and what
|parse-insertions| does is to break then up into splats, one for each statement
or directive. Those won't be much use as they stand, but see |compile-splats|.

When this completes, no |LINK_IST| nodes remain in the tree.

For the implementation, see //pipeline: Parsing Stages//.

@ |read <- SOURCE|.
Copies the contents of the SOURCE file to be the new contents of the tree.
The file must be an Inter file, but can be in either binary or textual format.

The special source |*memory| can be used if we already have a tree set up in
slot 0; this is a device used by the //supervisor// when managing an Inform
compilation, because //inform7// will already have made an Inter tree in
memory, and it would be inefficient to save this out to the file system and
then read it in again.

For the implementation, see //pipeline: Read, Move, Stop Stages//.

@ |reconcile-verbs|.
Looks for clashes between any verbs (i.e., command parser imperatives like
PURLOIN or LOOK) which are created in different compilation units. For example,
if the main source text creates a verb called ABSTRACT, which clashes with the
completely different command ABSTRACT defined in |CommandParserKit| for debugging
purposes, then how is the player to differentiate these? The |reconcile-verbs|
stage inserts |!| characters in the kit definitions where such clashes occur;
thus ABSTRACT would be the source-text-defined command, and !ABSTRACT the
kit-defined one.

At the end of this stage, all command parser verbs have distinct textual forms.

For the implementation, see //pipeline: Reconcile Verbs Stage//.

@ |resolve-conditional-compilation|.
Looks for splats arising from Inform 6-syntax conditional compilation directives
such as |#ifdef|, |#ifndef|, |#endif|; it then detects whether the relevant
symbols are defined, or looks at their values, and deletes sections of code not
to be compiled. At the end of this stage, there are no conditional compilation
splats left in the tree. For example:
= (text as Inter)
	constant MAGIC K_number = 12345
	splat IFTRUE &"#iftrue MAGIC == 12345;\n"
	constant WIZARD K_number = 5
	splat IFNOT &"#ifnot;\n"
	constant MUGGLE K_number = 0
	splat ENDIF &"#endif;\n"
=
is resolved to:
= (text as Inter)
	constant MAGIC K_number = 12345
	constant WIZARD K_number = 5
=

For the implementation, see //pipeline: Resolve Conditional Compilation Stage//.

@ |shorten-wiring|.
Wiring is the process by which symbols in one package can refer to definitions
in another one; we say S is wired to T if S in one package refers to the meaning
defined by T is another one. The linking process can result in extended chains
of wiring, with A wired to B which is wired to C which... and so on; the
|shorten-wiring| stage cuts out those intermediate links so that if a symbol
S is wired to T then T is not wired to anything else.

For the implementation, see //pipeline: Shorten Wiring Stage//.

@ |stop|.
The special stage |stop| halts processing of the pipeline midway. At present
this is only useful for making experimental edits to pipeline descriptions
to see what just the first half does, without deleting the second half of
the description.

For the implementation, see //pipeline: Read, Move, Stop Stages//.

@ |wipe|.
Empties a tree slot, freeing it up to be used again.

For the implementation, see //pipeline: Read, Move, Stop Stages//.
