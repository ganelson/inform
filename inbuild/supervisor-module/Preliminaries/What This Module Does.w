What This Module Does.

An overview of the supervisor module's role and abilities.

@h Prerequisites.
The supervisor module is a part of the Inform compiler toolset. It is
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

@h The Supervisor and its Parent.
The //supervisor// module is part of both //inform7// and //inbuild//, and acts
as a build manager. To compile an Inform project is not so atomic a task as
it sounds, because the project may need resources which themselves need to be
built first, and so on. //supervisor// takes charge of this, issuing
instructions as needed. It does so either "externally", by issuing shell
commands, or "internally", by calling functions in other modules resident in
the current compiler tool.

When included in //inform7//, the Supervisor is given a single task which
is always the same: build the current Inform 7 project. (See //core: Main Routine//.)
But when included in //inbuild//, a much wider range of tasks can be asked for,
as specified at the command line. (See //inbuild: Main//.) In this discussion,
"the parent" means the tool which is using //supervisor//, and might be either
//inform7// or //inbuild//.

@ //supervisor// has a relationship with its parent tool which involves to and
fro: it's not as simple as single one-time call from the parent to //supervisor//
saying "now build this".

(1) //supervisor// has to be started and stopped at each end of the parent's
run, by calling //SupervisorModule::start// and //SupervisorModule::end//.
The former calls //Supervisor::start// in turn, and that activates a number of
subsystems with further calls. But all modules do something like this.
(2) More unusually, when the parent is creating its command-line options, it
should call //Supervisor::declare_options// to add more. This allows all tools
containing the Supervisor to offer a unified set of command-line options to
configure it. (Compare //inform7: Reference Card// and //inbuild: Reference Card//
to see the effect.) When the parent is given a command-line switch that
it doesn't recognise, it should call //Supervisor::option// to handle that; and
when the command line has been fully processed, it should call
//Supervisor::optioneering_complete//.
(3) The parent can now, if it chooses, make calls into //supervisor// to set
up additional dependencies. But eventually it will call //Supervisor::go_operational//.
The Supervisor is now ready for use!

There is no single "go" button: instead, the Supervisor provides a suite
of functions to call, each acting on a "copy" -- an instance of some software
at a given filing system location. When //inform7// is the parent, it follows
the call to //Supervisor::go_operational// with a single call to //Copies::build//
on the copy representing the current Inform 7 project. But when //inbuild//
is the parent, a variety of other functions may be made.
