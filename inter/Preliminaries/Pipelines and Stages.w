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

	|$ inter/Tangled/inter -pipeline 'plugh, xyzzy, plover'|

If the pipeline is in an external file, then one stage should appear on
each line, and the comma is not needed:

	|plugh|
	|xyzzy|
	|plover|

@ A pipeline description can make use of "variables". These hold only text,
and generally represent filenames. Variable names begin with a star |*|.
The pipeline cannot create variables: instead, the user of the pipeline has
to make them before use. For example,

	|$ inter/Tangled/inter -variable '*X=ex/why' -pipeline-file mypl.interpipeline|

creates the variable |*X| with the textual contents |ex/why| before running
the given pipeline. Inside the pipeline, a line such as:

	|generate inform6 -> *X|

would then be read as:

	|generate inform6 -> ex/why|

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

	|generate inventory -> *log|

Template filenames are a little different: those are searched for inside
a path of possible directories. By default there's no such path, but using
|-template T| at the Inter command line gives a path of just one directory.

@h Pipelines run by Inform.
As the above implies, Inter pipelines normally begin with a clean slate:
no repositories, no variables. 

When a pipeline is being run by the main Inform 7 compiler, however,
two variables are created in advance. |*in| is set to the inter code
which Inform has generated on the current run, and |*out| is set to the
filename to which final I6 code needs to be written. The practical
effect is that any useful pipeline for Inform will begin and end thus:

	|read <- *in|
	|...|
	|generate inform6 -> *out|

In addition, the "domain" is set to the directory containing the |*out|
file, and the template search path is set to the one used in Inform, that is,
the template file |Whatever.i6t| would be looked for first in the project's
|X.materials/I6T| directory, then in the user's |I6T| directory, and failing
that in Inform's built-in one.

The pipeline is itself looked for in the same way. If you have a project
called |Strange.inform|, then Inform first looks for

	|Strange.materials/Inter/default.interpipeline|

If it can't find this file, it next looks for |default.interpipeline| in
the user's folder, and then in Inform's built-in one. If you're curious to
read the pipeline normally used by a shipping version of Inform, the file
can be found here in the Github repository for Inform:

	|inform7/Internal/Inter/default.interpipeline|

The best way to change the pipeline, then, is to put a new file in the
project's Materials folder. But there are also two other ways.

1. This sentence:

>> Use inter pipeline "PIPELINE".

replaces the pipeline normally used for code generation with the one supplied.
(That may very well cause the compiler not to produce viable code, of course.)

2. A replacement pipeline can be specified at the Inform 7 command line:

	|$ inform7/Tangled/inform7 ... -pipeline 'PIPELINE'|

Exactly as with Inter, Inform 7 also responds to |-pipeline-file|:

	|$ inform7/Tangled/inform7 ... -pipeline-file FILE|

@h Stage descriptions.
There are three sorts of stage description: those involving material coming
in, denoted by a left arrow, those involving some external file being written
out, denoted by a right arrow, and those which just process what we have.
These take the following forms:

	|STAGENAME [LOCATION] <- SOURCE|
	|STAGENAME [LOCATION] FORMAT -> DESTINATION|
	|STAGENAME [LOCATION]|

In each case the |LOCATION| is optional. For example:

	|read 2 <- *in|
	|generate binary -> *out|
	|eliminate-redundant-labels /main/template|

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

	|read REPOSITORY <- FILE|

where |REPOSITORY| is |0| to |9|, and is |0| if not supplied. Note that
this fills an entire repository: it's not meaningful to specify a
named package as the location.

The |FILE| can contain either binary or textual Inter, and this is
automatically detected.

	|generate FORMAT -> FILE|

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

	|splat &"Global nitwit = 2;\n"|

is recognised as an Inform 6 variable declaration, and annotated thus:

	|splat GLOBAL &"Global nitwit = 2;\n"|

@ |resolve-conditional-compilation| looks for splats arising from Inform 6
conditional compilation directives such as |#ifdef|, |#ifndef|, |#endif|;
it then detects whether the relevant symbols are defined, or looks at their
values, and deletes sections of code not to be compiled. At the end of this
stage, there are no conditional compilation splats left in the repository.
For example:

	|constant MAGIC K_number = 16339|
	|splat IFTRUE &"#iftrue MAGIC == 16339;\n"|
	|constant WIZARD K_number = 5|
	|splat IFNOT &"#ifnot;\n"|
	|constant MUGGLE K_number = 0|
	|splat ENDIF &"#endif;\n"|

is resolved to:

	|constant MAGIC K_number = 16339|
	|constant WIZARD K_number = 5|

@ |assimilate| aims to convert all remaining splats in the repository into
higher-level inter statements. For example,

	|splat STUB &"#Stub Peach 0;\n"|
	|splat ATTRIBUTE &"Attribute marmorial;\n"|

becomes:

	|constant Peach K_unchecked_function = Peach_B __assimilated=1|
	|property marmorial K_truth_state __assimilated=1 __attribute=1 __either_or=1|

At the end of this stage, there should be no splats left in the repository,
and the linking process is complete.

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
