What This Module Does.

An overview of the final module's role and abilities.

@h Prerequisites.
The final module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than just |add_by_name|.
(c) This module uses other modules drawn from the //compiler//, and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Finally final.
The final module is aptly named, in that it is the very last stage in compiling
an Inform project. Everything up to this module has been generating a tree of
Inter code, which is (to a large extent) an abstract, general-purpose description
of a program. We finally turn that into an Inform 6 program, or a C program,
or some other concrete expression of that program.

This module has a very simple interface to the rest of the tool chain: it
simply provides a single Inter pipeline stage called |generate|. See
//CodeGen::create_pipeline_stage//. When this stage is reached, the function
//CodeGen::run_pipeline_stage// is run. This then creates a //code_generation//
object, which holds all the temporary storage and configuration details for a
single act of code-generation. The most important of those details is the
choice of which //code_generator// to use -- see below.

@ The module creates a small number of //code_generator//s, one for each
possible output format. For example, //I6Target::create_generator// creates
one which represents "output Inform 6 code, please"; //CTarget::create_generator//
creates one for "output ANSI C-99 code, please".

If you are considering adding a new output format, say for JavaScript or Python,
that should be done by adding a new //code_generator//. Although the default
generator is the Inform 6 one, that is in some ways misleadingly simple in
design because Inter, our intermediate format, was originally designed as a
sort of abstract paraphrase of Inform 6 -- which means that it's quite easy
to turn Inter to I6. The C code generator is a much better example of the real
issues likely to present themselves. So reading through the chapter on C is
probably the best way to get an idea of the task.

@ It seems likely that many if not most of the formats we will ever need to
generate will be procedural programming languages of the sort usually called
C-like, and we want to avoid duplicated effort. A generic algorithm called
//Vanilla// is therefore provided: a generator can, if it wishes, make use of
this to simplify its work, and both our C and Inform 6 generators do so.
