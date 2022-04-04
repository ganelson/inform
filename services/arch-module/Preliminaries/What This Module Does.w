What This Module Does.

An overview of the arch module's role and abilities.

@h Prerequisites.
The arch module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than |add_by_name|.
(c) This module uses other modules drawn from the compiler (see //structure//), and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Architecture versus VM.
The Inform 7 build process works in two stages: first it generates abstract
Inter code, then it further generates "final code" from that.

It's an appealing notion that this first stage might be universal: that
is, that //inform7// could generate the same Inter code regardless of the
eventual build product needed, and that only the second stage would vary
according to this.

Which is very nearly true, but not quite. Here's why not:
(a) //inform7// has to generate different code if integers are 16 rather
than 32 bits wide, and
(b) kits of Inter code normally used in compilation make certain other
architectural assumptions based on the integer size (for example, the
assembly-language syntax and semantics are different in these cases);
(c) it also generates different code with debugging enabled than without.

Reason (c) could be avoided, at some cost in complexity, but reasons (a) and (b)
are something we cannot sensibly avoid without making Inter a much higher-level
form of bytecode. Instead, we have "architectures" for Inter: for example,
32-bit with debugging enabled is the |32d| architecture. See //Architectures//;
if ever we introduce a 64-bit VM, that will need new architectures, and
this is where they would go.

@ A //target_vm// object, on the other hand, expresses the choices made at
the second stage too. The term "VM" is traditional here, and stands for
"virtual machine", because until 2021, Inform could only generate code which
would ultimately run on virtual machines called Glulx and the Z-machine. But it
can now, for example, also generate C.

As a result, "VM" now has a more general meaning, and really means "form of
final code generation". The Glulx format used to be specified by supplying the
command-line option |-format=ulx| to //inform7// or //inter//: that still works,
though it is deprecated, and |-format=Inform6/32d| is better. But equally
possible now would be |-format=C/32d|. Here the target is a native executable
to be compiled with a C compiler.

As these new-style |-format| options suggest, the compilation process thus
involves a combination of both architecture and target:
= (text as BoxArt)
                             depends on architecture:           depends on target:
	Source text -----------> Inter code       ----------------> Bytecode for
	              INFORM7                       via INFORM6     target virtual machine
                                              ----------------> Executable
	                                            via CLANG/GCC
	                                          ...
=
Note that a single //target_vm// object can be used with just one architecture:
use the function //TargetVMs::get_architecture// to obtain this. If a target supports
multiple architectures, then there will be multiple //target_vm// objects for it,
one for each architecture it supports. For example, the Glulx VM can be reached
by |Inform6/32| or |Inform6/32d|. There can also be multiple versions: for example,
|Inform6/16/v8| is a valid target. The function //TargetVMs::find// finds the
//target_vm// object associated with a given textual form like |"C/32d"|, if
the toolchain supports this.

@h Compatibility.
Not all software in the Inform stack -- source text from the user, extensions,
kits of Inter code -- will be compatible with every architecture, or with
every VM. We represent that by giving something a //compatibility_specification//
object to say what it can work with: the function //Compatibility::test//
determines whether any given VM is allowed with this specification.

A specification can be converted to or from text: see //Compatibility::write//
and //Compatibility::from_text//. Typically, such text might read "for 32d only".

Lastly, //Compatibility::all// returns a specification meaning "works with
anything". This should be the default; //Compatibility::test_universal// tests
whether a specification is equivalent to this.
