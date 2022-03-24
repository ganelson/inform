Using Inter.

Using Inter at the command line.

@h What Inter does.
"Inter" is the intermediate representation of a program used in the Inform
compiler toolchain. Most compilers have one of these: for example, Microsoft
compilers mostly use "CIL" (common intermediate language), while |gcc| uses
something called GIMPLE, and so on. See //bytecode// for a longer discussion
of what motivates the design of Inter.

The practical effect is that the back end of the Inform compiler deals only
with Inter code. This back end exists as part of the executable //inform7//,
but also as a stand-alone program called //inter//, which comes with its
own command-line interface. Whereas //inform7// has a specific task to perform
and uses Inter code only as a means to an end, //inter// is designed to be
as flexible as possible.

@ Inter code can exist in memory, or in a human-readable text file, or in a
rapid-access binary file. The tool //inter// can convert between these formats: 
= (text as BoxArt)
  textual                                  textual
  inter   ---+                       +---> inter
              \                     /
               \                   /
                ---->  memory  ----
               /       inter       \
  binary      /                     \      binary
  inter   ---+                       +---> inter
=

However, Inter can do much more than simply convert between these forms. It
has a "pipeline" design, meaning that it can run memory inter through any
desired series of compilation stages, one at a time:
= (text as BoxArt)
	T --------> T --------> T --------> ... --------> T
	   step 1      step 2      step 3   ...  step N
=
The Inter tree |T| starts out empty,[1] and at the end it is thrown away. So any
useful pipeline will begin by loading something in (usually as step 1), and
end by producing some useful output (usually in its last step or steps).

The advantage of this design is that it enables us to build what amount to
entirely different compilers, just by using different pipelines -- see
"assimilation" below for an example of a pipeline very different to the one
used in normal Inform 7 compilations. Pipelines also allow us to test existing
or proposed code-generation stages individually.

[1] Programs in Inter format are called "Inter trees".

@h Verify only.
If you have compiled the standard distribution of the command-line tools
for Inform then the Inter executable will be at |inter/Tangled/inter|.

Inter has three basic modes. In the first, the command line specifies only
a single file:
= (text as ConsoleText)
	$ inter/Tangled/inter INTERFILE
=
Inter simply verifies this file for correctness: that is, to see if the inter
code supplied conforms to the inter specification. It returns the exit code 0
if all is well, and issues error messages and returns 1 if not.

Such files can be in either textual or binary form, and Inter automatically
detects which by looking at their contents. (Conventionally, such files
have the filename extension |.intert| or |.interb| respectively, but that's
not how Inter decides.)

@h Format conversion.
In the second mode, Inter not only loads (and verifies) the named file, but
then converts it to a different format and writes that out. For example,
= (text as ConsoleText)
	$ inter/Tangled/inter my.intert -o my.interb -format=binary
=
converts |my.intert| (a textual inter file) to its binary equivalent |my.interb|,
and conversely:
= (text as ConsoleText)
	$ inter/Tangled/inter my.interb -o my.intert -format=text
=
Two parameters must be specified: |-o| giving the output file, and |-format=F|
to say what format |F| this should have. Formats are in the same notation as
those used by //inbuild//, which similarly supports |-o| and |-format|.
In fact, |-format=text| is the default.

To take an elaborate example,
= (text as ConsoleText)
	$ inter/Tangled/inter my.interb -o my.intert -format=C/32d/nomain
=
generates a 32-bit-word, debugging-enabled ANSI C program from the Inter tree
in |my.interb|, with no |main| function included in it.

As a special case, if |-o| is given just as |-|, then the output is printed
to the console rather than to a file.

@h Running a pipeline.
If we specify |-trace| as a command-line switch, Inter prints out every step
of the pipeline(s) it is following. This reveals that even the simple commands
above are, in fact, running pipelines, albeit short ones:
= (text as ConsoleText)
	$ inter/Tangled/inter my.intert -trace
	step 1/1: read <- my.intert
	$ inter/Tangled/inter my.intert -o my.interb -format=binary -trace
	step 1/2: read <- my.intert
	step 2/2: generate binary -> my.interb
=
As this shows, a one or two-step pipeline was running:

(1) The first step used the |read| compilation stage, which reads some Inter
code into memory. Here, it comes from the file |my.intert|.

(2) The second step used the |generate| stage, which writes out Inter code
in the format of one's choice -- here "binary".

@ However, we don't have to use this default pipeline. |-pipeline-text 'PIPELINE'|
reads in a textual description of the pipeline to follow, with the steps divided
by commas. The examples above used a pipeline which in this notation would
be written as:
= (text as ConsoleText)
	-pipeline-text 'read <- *in, generate -> *out'
=
|*in| and |*out| are examples of "pipeline variables". |*in| is the filename
of whatever file is to be read in, and |*out| is whatever was specified by |-o|
at the command line, or in other words, the filename to write the output to.

This is not quite the smallest possible pipeline. Consider:
= (text as ConsoleText)
	$ inter/Tangled/inter -o my.intert -pipeline-text 'new, generate -> *out' -trace
	step 1/2: new
	step 2/2: generate text -> my.intert
=
Here we didn't specify any Inter file to read in, so |*in| does not appear.
Instead wevbegan the pipeline with the |new| compilation stage, which creates
a minimal Inter program from nothing.

Even three-step pipelines can be very useful. For example:
= (text as ConsoleText)
	$ inter/Tangled/inter -o my.intert -pipeline-text 'read <- *in, eliminate-redundant-labels, generate -> *out' -trace
	step 1/3: read <- my.intert
	step 2/3: eliminate-redundant-labels
	step 3/3: generate text -> my.intert
=
This could be used to test that the |eliminate-redundant-labels| compilation
stage is working as it should. We can feed our choice of Inter code into it,
and examine its direct output, in isolation from the working of the rest of
the compiler (and, of course, more quickly).

@ In practice, it becomes cumbersome to spell the pipeline out longhand on
the command line, so we can also put it into a text file:
= (text as ConsoleText)
	$ inter/Tangled/inter -pipeline-file mypl.interpipeline
=
It's not allowed to specify both |-pipeline-file| and |-pipeline-text|.
The text file, however, specifies pipelines with one step on each line, not
using commas. So |-pipeline-text 'read <- *in, eliminate-redundant-labels, generate -> *out'|
is equivalent to |-pipeline-file| with the file:
= (text)
read <- *in
eliminate-redundant-labels
generate -> *out
=
For more on how to write and use pipeline files, see //Pipelines and Stages//.

@ In general, filenames follow the usual Unix conventions: they are taken as
relative to the current working directory, unless given as absolute filenames
beginning with |/|. But we can also set a "default directory" to take the
place of the CWD, using |-domain|:
= (text)
	-domain D

@h Assimilation.
Inform makes use of what are called "kits" of pre-compiled Inter code:
for example, |CommandParserKit| contains code for the traditional interactive
fiction command parser. That pre-compilation is called "assimilation", and
is performed by the //inter// tool alone: it does not require, or use, the
bulk of the //inform7// compiler.

The source code for a kit could in principle be textual Inter, but that's too
verbose to write comfortably. In practice we use Inform 6 code as a notation,
and therefore assimilation is really compilation from I6 to Inter.

Kits are like so-called "fat binaries", in that they contain binary Inter
for each different architecture with which they are compatible. Inter can
build kits for only one architecture at a time, so a command must specify
which is wanted. For example:
= (text as ConsoleText)
	$ inter/Tangled/inter -architecture 16 -build-kit inform7/Internal/Inter/BasicInformKit
	$ inter/Tangled/inter -architecture 32d -build-kit inform7/Internal/Inter/BasicInformKit
=
At present there are four architectures: |16|, |16d|, |32| and |32d|.
Note that an architecture is not the same thing as a format: it specifies
only the word size (16 or 32 bit) and the presence, or not, of debugging data.

Incrementally building kits as needed could be done with something like
the Unix tool |make|, but in fact Inbuild has this ability: the command
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -build K
=
looks at the kit |K|, works out which architectures need rebuilding, and
then issues commands like the above to instruct |inter| to do so. Indeed,
multiple kits can be managed with a single command:
= (text as ConsoleText)
	$ inbuild/Tangled/inbuild -build -contents-of inform7/Internal/Inter

@ Under the hood, assimilation is just another use of pipeline processing. If we
run one of these |-build-kit| commands with |-trace| switched on, we see
something like this:
= (text as ConsoleText)
step 1/6: new
step 2/6: load-kit-source <- BasicInformKit
step 3/6: parse-insertions
step 4/6: resolve-conditional-compilation
step 5/6: compile-splats
step 6/6: generate binary -> inform7/Internal/Inter/BasicInformKit/arch-32.interb
=
This is in fact the result of running a pipeline file called |build-kit.interpipeline|
which is included in the standard Inter distribution.
