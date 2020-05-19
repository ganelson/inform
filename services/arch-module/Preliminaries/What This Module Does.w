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
(c) This module uses other modules drawn from the //compiler//, and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h Architecture versus VM.
The Inform 7 build process ultimately wants to make code for some target
virtual machine -- traditionally, the Z or Glulx machines. But it does this
in two stages: first generating abstract Inter code, then further generating
VM code from that.

It's an appealing notion that this first stage might be VM-independent: that
is, that //inform7// could generate the same Inter code regardless of the
final VM, and that only the second stage would vary according to target.
And this is nearly true, but not quite. There are (currently) two reasons
why not:
(a) //inform7// has to generate different code if integers are 16 rather
than 32 bits wide, and
(b) it also generates different code with debugging enabled than without.

Reason (b) could be avoided, at some cost in complexity, but reason (a) is
something we cannot sensibly avoid without making Inter a much higher-level
form of bytecode. Instead, we have "architectures" for Inter: for example,
32-bit with debugging enabled is the |32d| architecture. See //Architectures//;
if ever we introduce a 64-bit VM, that will need new architectures, and
this is where they would go.

@ A //target_vm// object, on the other hand, represents an actual choice of
virtual machine. For example, Glulx is a //target_vm//. The compilation
process thus involves a combination of both architecture and target:
= (text as BoxArt)
	Source text -----------> Inter code       --------------> Bytecode for
	              INFORM7    for architecture   via INFORM6   target virtual machine
=
Each VM can be used with just one architecture: use the function
//TargetVMs::get_architecture// to obtain this. It might seem reasonable
to say that Glulx ought to be viable with both |32| and |32d| architectures,
but in fact "Glulx" is not a single virtual machine but a family of them.
A specific member of this family would be the //target_vm// representing
Glulx version 3.1.2 with debugging enabled, and that can be used with the
|32d| but not the |32| architecture.

There can in principle be numerous VMs in any given family; see
//TargetVMs::find_in_family// to obtain family members with given behaviour,
and in general see //Target Virtual Machines// for more.

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
