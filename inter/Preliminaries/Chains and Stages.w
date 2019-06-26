Chains and Stages.

Sequences of named code-generation stages are called chains.

@h Stages and descriptions.
A processing stage is a step in code generation which acts on a repository
of inter in memory. Some stages change, add to or edit down that code, while
others leave it untouched but output a file based on it.

Each stage can see an entire repository of inter code at a time, and is
not restricted to working through it in sequence. Those which read in or write
out a file also have a filename supplied to them as a parameter, but there
are otherwise no configuration options. It's not possible to tell a stage
to work on one specific function alone, for example.

Stages are named, which are written without spaces, and conventionally use
hyphens: for example, |resolve-conditional-compilation|. Where a filename has
to be supplied, it appears after a colon. Thus |generate-inter:my.intert|
is a valid stage description.

A "chain" is a comma-separated list of stage descriptions, and represents a
sort of program to follow: memory inter is passed through each stage in turn.
The special stage |stop| halts processing of the chain midway. At present
this is only useful for making experimental edits to chain descriptions
to see what just the first half does, without deleting the second half of
the description.

@ There are three ways to use chains. One is from the command line of Inter:

	|$ inter/Tangled/inter FILE -inter 'CHAIN'|

The other is to use two experimental features of Inform. This sentence:

>> Use inter chain "STAGES".

replaces the chain normally used for code generation with the one supplied.
(This may very well cause the compiler not to produce viable code, of course.)
Equivalently, a replacement chain can be specified at the Inform 7 command line:

	|$ inform7/Tangled/inform7 ... -inter 'CHAIN'|

When using a chain within Inform, one further description syntax is allowed:
the filename |*| means "the filename Inform wants to use for the final
Inform 6 file".

@h The code-generation stages.
The following are all experimental, and have probably not yet reached their
final form or names. But this briefly describes the stages which currently
exist in the code generator. In the description below, the "repository" is
the reservoir of memory inter code being worked on.

Although one thinks of code generation as a process of turning inter into
Inform 6, in fact it goes both ways, because we also have to read in
the "template" of standing Inform 6 code. The early code generation stages
convert the template from Inform 6 into inter, merging it with the inter
already produced by the front end of the compiler. The later stages then
turn this merged repository into Inform 6 code. (Routines in the template,
therefore, are converted out of Inform 6 and then back into it again. This
sounds inefficient but is surprisingly fast, and enables many optimisations.)

@ |link:T| reads in the I6T template file T, converts it to inter in a very
basic way (creating many splats), and merges it with the repository. Splats
are the unhappiest of inter statements, simply including verbatim snippets
of Inform 6 code.

@ |parse-linked-matter| examines the splats produced by linking and annotates
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

@ |eliminate-redundant-labels| performs peephole optimisation on all of
the functions in the repository to remove all labels which are declared
but can never be jumped to.

At the end of this stage, all labels inside functions are targets of some
branch, either by |inv !jump| or in assembly language.

@ |generate-inter:F| writes out the repository as a textual inter file |F|.
(By default, Inform doesn't do this: the inter ordinarily stays in memory
throughout.)

This stage leaves the repository unchanged.

@ |generate-inter-binary:F| writes out the repository as a binary inter
file |F|. (By default, Inform doesn't do this: the inter ordinarily stays in
memory throughout.)

This stage leaves the repository unchanged.

@ |generate-i6:F| translates the repository to an Inform 6 program. This is
normally the final stage in the Inform code generation chain.

This stage leaves the repository unchanged.

@h Diagnostic or non-working stages.

@ |show-dependencies:F| and |log-dependencies| output a dependency graph of
the symbols in the current repository, one to a file, the other to the
debugging log. A dependency means that one can't be compiled without the
other: for example, if a function has a local variable of a given kind, then
the function depends on that kind.

|eliminate-redundant-code| is a stage which removes all material from
the repository which the main routine is not dependent on. This can result
in many template routines being kicked out, and substantially reduces
story file sizes. The stage mostly works, but needs more refinement before
we could safely enable it by default with Inform.

@ |summarise:F| is a very slow diagnostic stage showing the breakdown of the
current repository into packages, writing the output to file |F|. (Slow in
this sense means that it roughly triples compilation time.)

@ |export:F| and |import:F| were part of an experiment to do with caching the
inter generated by the Standard Rules. This eventually worked, but was put on
ice while a better and more systematic solution was found.
