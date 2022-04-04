What This Module Does.

An overview of the pipeline module's role and abilities.

@h Prerequisites.
The pipeline module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than just |add_by_name|.
(c) This module uses other modules drawn from the compiler (see //structure//), and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Pipelines.
This module manages the process of working on trees of Inter code by running
them through a "pipeline" of "steps", each performed in turn. Each step makes
use of an algorithm called a "stage" which transforms the tree in some way:
perhaps adding, removing or rearranging material, or perhaps just looking for
problems with it. //inter// currently has about 20 different stages, though
no single pipeline is ever likely to need all 20.

@ Command-line users of the Inform tool chain are free to define their
own pipelines, perhaps to experiment with adding new optimisation stages, or
to do other things with Inter code. To help with this, pipelines are specified
as text files, written in their own definition language. A brief guide to this
language can be found in //inter: Pipelines and Stages//.

See //Parsing Pipelines// for how such files are turned into //inter_pipeline//
objects, each made up of //pipeline_step// objects.

The mechanics of running through a pipeline can be found in //Running Pipelines//.

Pipelines can go wrong in two different ways: either by failing to be properly
defined because of syntax errors in their definitions, or by failing to run
properly. For example, if we compile this Basic Inform project:
= (text as Inform 7)
To begin: go awry.

To go awry: (- Cryptid(); -).
=
...then the //inform7// compiler happily makes an Inter tree, on the
assumption that an Inter function called |Cryptid| will be defined in one
of the kits to be loaded in later. But when later comes, the |compile| pipeline
has to halt when it fails to find |Cryptid| anywhere. The process has to halt
with error messages at the command line, or a legible problem message for users
of the GUI application.

Both sorts of pipeline error are dealt with by //Pipeline Errors//.

@ For purposes of Inform, two pipelines are important:

(*) |build-kit| reads in the source code for a kit written in Inform 6
(broadly C-like) syntax, compiles that to Inter code, and then saves this
as a binary Inter file.

(*) |compile| works on an Inter tree produced by //inform7// from natural
language source text, links in one or more binary Inter files from kits,
optimises the result, and then generates final code.

The //supervisor// module decides when these are to be "run", and sets them
up with configuration details -- what Inter architecture to use, where to
put the resultant files, when a kit needs to be rebuilt, and so on. None of
that is our problem here. Roughly speaking, though, |build-kit| is run only
occasionally, when the source code for a kit is modified -- for most Inform
users, that will be never -- whereas |compile| is run every time the user of
an Inform GUI app clicks the "Go" button.

Speed is therefore unimportant for stages used in |build-kit|, but very
important for stages used in |compile|. As a rule of thumb, if the user waits
10 seconds for the result after clicking "Go" then the first 6 seconds are spent
in //inform7//, the next 3 seconds running the |compile| pipeline, and the final
second in whatever compiler turns the final code into an executable -- usually
Inform 6.

@ The |compile| pipeline is as follows. Here the //supervisor// module has
already set the variables |*in| and |*out| respectively to the source of
Inter (in fact, it will be in memory, not in a file), and to the filename
for where the final code is to be written. By default |*tout| is not set
when the Inform 7 GUI app is being used, but it's sometimes set when testing
at the command line. If it is set, then the final state of the Inter tree
will be written out in a readable text format.

= (text from Figures/compile.interpipeline as Inter Pipeline)

Similarly, here is |build-kit|:

= (text from Figures/build-kit.interpipeline as Inter Pipeline)

@ These of course use three subsidiary pipelines. The |assimilate| pipeline
turns raw Inform 6-syntax source code into Inter material: so it does a great
deal of work when |build-kit| is running, but only a very little for |compile|,
when all it needs to worry about will be a few scraps of I6 code compiled
by //inform7// from uses of the low-level |Include (-| ... |-)| feature.

= (text from Figures/assimilate.interpipeline as Inter Pipeline)

The |link| pipeline sorts out cross-references between Inter code made by
//inform7//, and Inter code loaded in from kits. Each side may need to call
functions or access variables in the other. This process is more active
and less symmetrical than linking would be for a C-like language, but "linking"
is probably still the nearest word for it.

= (text from Figures/link.interpipeline as Inter Pipeline)

Finally, the |optimisation| pipeline is a chance to simplify the Inter tree
without changing its meaning, so that equivalent but faster or smaller final
code is generated. At present this does relatively little, but it's a start.

= (text from Figures/optimise.interpipeline as Inter Pipeline)

@ To create a new stage, you may want to copy a simple existing one -- say,
the //Eliminate Redundant Labels Stage// -- as a model. Note that a stage
must be "created", and your function to create it should be called from the
function //ParsingPipelines::parse_stage//.
