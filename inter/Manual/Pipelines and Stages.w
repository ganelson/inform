Pipelines and Stages.

Sequences of named code-generation stages are called pipelines.

@h Stages and descriptions.
A processing stage is a step in code generation which acts on a repository
of inter in memory. Some stages change, add to or edit down that code, while
others leave it untouched but output a file based on it.

Each stage can see an entire repository of inter code at a time, and is
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
no repositories, no variables. 

When a pipeline is being run by the main Inform 7 compiler, however,
two variables are created in advance. |*in| is set to the inter code
which Inform has generated on the current run, and |*out| is set to the
filename to which final I6 code needs to be written. The practical
effect is that any useful pipeline for Inform will begin and end thus:
= (text as Inter Pipeline)
	read <- *in
	...
	generate inform6 -> *out
=
In addition, the "domain" is set to the directory containing the |*out|
file.

To Inbuild and Inform, pipelines are resources in their own right, rather
like extensions or kits. So, for example, the standard distribution includes
= (text)
	inform7/Internal/Pipelines/compile.interpipeline
=
which is the one used for standard compilation runs. A projects Materials
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
complex code for sorting out resources.)

@h Stage descriptions.
There are three sorts of stage description: those involving material coming
in, denoted by a left arrow, those involving some external file being written
out, denoted by a right arrow, and those which just process what we have.
These take the following forms:
= (text as Inter Pipeline)
	STAGENAME [LOCATION] <- SOURCE
	STAGENAME [LOCATION] FORMAT -> DESTINATION
	STAGENAME [LOCATION]
=
In each case the |LOCATION| is optional. For example:
= (text as Inter Pipeline)
	read 2 <- *in
	generate binary -> *out
	eliminate-redundant-labels /main/template
=
In the first line the location is |2|. Pipeline descriptios allow us to manage
up to 10 different repositories, and these are called |0| to |9|. These are
all initially empty. Any stage which doesn't specify a repository is considered
to apply to |0|; plenty of pipelines never mention the digits |0| to |9| at
all because they do everything inside |0|.

In the second line, there's no location given, so the location is presumed
to be |0|.

The third line demonstrates that a location can be more specific than just
a repository: it can be a specific package in a repository. Here, it's
|/main/template| in repository |0|, but we could also write |7:/main/template|
to mean |/main/template| in |7|, for example. Not all stages allow the
location to be narrowed down to a single package (which by definition
includes all its subpackages): see below.

@h Reading and generating.
The |read| stage reads Inter from a file into a repository in memory.
(Its previous contents, if any, are discarded.) This then becomes the
repository to which subsequent stages apply. The format is:
= (text as Inter Pipeline)
	read REPOSITORY <- FILE
=
where |REPOSITORY| is |0| to |9|, and is |0| if not supplied. Note that
this fills an entire repository: it's not meaningful to specify a
named package as the location.

The |FILE| can contain either binary or textual Inter, and this is
automatically detected.
= (text as Inter Pipeline)
	generate FORMAT -> FILE
=
writes the repository out into the given |FILE|. There are several possible
formats: |binary| and |text| mean a binary or textual Inter file, |inventory|
means a textual summary of the contents, and |inform6| means an Inform 6
program. At present, only |inventory| can be generated on specific
packages in a repository.

The |generate| stage leaves the repository unchanged, so it's possible
to generate multiple representations of the same repository into different
files.

@h The code-generation stages.
The following are all experimental, and have probably not yet reached their
final form or names.

Although one thinks of code generation as a process of turning inter into
Inform 6, in fact it goes both ways, because we also have to read in
the "template" of standing Inform 6 code. The early code generation stages
convert the template from Inform 6 into inter, merging it with the inter
already produced by the front end of the compiler. The later stages then
turn this merged repository into Inform 6 code. (Routines in the template,
therefore, are converted out of Inform 6 and then back into it again. This
sounds inefficient but is surprisingly fast, and enables many optimisations.)

@ |merge-template <- T| reads in the I6T template file |T|, converts it to
inter in a very basic way (creating many splats), and merges it with the
repository. Splats are the unhappiest of inter statements, simply including
verbatim snippets of Inform 6 code.

@ |parse-linked-matter| examines the splats produced by merging and annotates
them by what they seem to want to do. For example,
= (text as Inter)
	splat &"Global nitwit = 2;\n"
=
is recognised as an Inform 6 variable declaration, and annotated thus:
= (text as Inter)
	splat GLOBAL &"Global nitwit = 2;\n"
=
@ |resolve-conditional-compilation| looks for splats arising from Inform 6
conditional compilation directives such as |#ifdef|, |#ifndef|, |#endif|;
it then detects whether the relevant symbols are defined, or looks at their
values, and deletes sections of code not to be compiled. At the end of this
stage, there are no conditional compilation splats left in the repository.
For example:
= (text as Inter)
	constant MAGIC K_number = 16339
	splat IFTRUE &"#iftrue MAGIC == 16339;\n"
	constant WIZARD K_number = 5
	splat IFNOT &"#ifnot;\n"
	constant MUGGLE K_number = 0
	splat ENDIF &"#endif;\n"
=
is resolved to:
= (text as Inter)
	constant MAGIC K_number = 16339
	constant WIZARD K_number = 5
=
@ |assimilate| aims to convert all remaining splats in the repository into
higher-level inter statements. For example,
= (text as Inter)
	splat STUB &"#Stub Peach 0;\n"
	splat ATTRIBUTE &"Attribute marmorial;\n"
=
becomes:
= (text as Inter)
	constant Peach K_unchecked_function = Peach_B __assimilated=1
	property marmorial K_truth_state __assimilated=1 __attribute=1 __either_or=1
=
At the end of this stage, there should be no splats left in the repository,
and the linking process is complete.
=
@ |make-identifiers-unique| looks for symbols marked with the |MAKE_NAME_UNIQUE|
flag (represented in textual form by an asterisk after its name), This flag
means that Inform wants the symbol name to be globally unique in the repository.
For example, if Inform generates the symbol name |fruit*|, it's really telling
the code generator that it eventually wants this to have a name which won't
collide with anything else.

What |make-identifiers-unique| does is to append |_U1|, |_U2|, ... to such
names across the repository. Thus |fruit*| might become |fruit_U176|, and it
is guaranteed that no other symbol has the same name.

This stage is needed because whereas the inter language has namespces, so
that the same name can mean different things in different parts of the
program, Inform 6 (mostly) does not. There cannot be two functions with the
same name in any I6 program, for example.

At the end of this stage, no symbol still has the |MAKE_NAME_UNIQUE| flag.

@ |reconcile-verbs| is a short stage looking for clashes between any verbs (in
the parser interactive fiction sense) which have been assimilated from the
template, and verbs which have been defined in the main source text. For
example, suppose the source creates the command verb "abstract": this would
collide with the command meta-verb "abstract", intended for debugging, which
appears in the template. What this stage does is to detect such problems,
and if it finds one, to prefix the template verb with |!|. Thus we would end
up with two command verbs: |abstract|, with its source text meaning, and
|!abstract|, with its template meaning.

At the end of this stage, all parser verbs have distinct textual forms.

@ |eliminate-redundant-code| deletes all packages which Inter can prove
will not be used in the final code generated from the repository. For
example, functions never called, or arrays never referred to, are deleted.

@ |eliminate-redundant-labels| performs peephole optimisation on all of
the functions in the repository to remove all labels which are declared
but can never be jumped to.

At the end of this stage, all labels inside functions are targets of some
branch, either by |inv !jump| or in assembly language.

@ The special stage |stop| halts processing of the pipeline midway. At present
this is only useful for making experimental edits to pipeline descriptions
to see what just the first half does, without deleting the second half of
the description.
