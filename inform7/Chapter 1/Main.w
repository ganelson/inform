[Main::] Main.

A shell for the modules which actually form the compiler.

@ The source code for the Inform 7 compiler is modularised, and each module
has its own web, leaving very little here. (To get a sense of how Inform works,
read the web for the Core module, and dip into the others as needed.)

First, some identification:

@d INTOOL_NAME "inform7"
@d INFORM7_BUILD "inform7 [[Build Number]]"
@d HUMAN_READABLE_INTOOL_NAME "Inform 7"

@ On some platforms the core Inform compiler is a separate command-line tool,
so that execution should begin with |main()|, as in all C programs. But some
Inform UI applications need to compile it into the body of a larger program:
those should define the symbol |SUPPRESS_MAIN| and call |Main::core_inform_main()|
when they want I7 to run.

=
#ifndef SUPPRESS_MAIN
int main(int argc, char *argv[]) {
	return Main::core_inform_main(argc, argv);
}
#endif

@ Either way, that brings us here. All our modules have to be started up and
shut down, so we take care of that with one more intermediary. These modules
fall into four categories:

(a) Libraries of code providing services to the compiler but containing
none of its logic: Foundation, Words, Inflections, Syntax, Linguistics,
Kinds, Problems, Index. Foundation is shared with numerous other tools,
and is part of the Inweb repository.

(b) Core, the front end of the compiler for the basic Inform 7 language.

(c) Inter and Codegen, the back end. These modules are shared with the
command-line tool Inter.

(d) Extensions to the Inform 7 language for interactive fiction: IF,
Multimedia.

=
int Main::core_inform_main(int argc, char *argv[]) {
	Foundation::start(); /* must be started first */
	WordsModule::start();
	InflectionsModule::start();
	SyntaxModule::start();
	LinguisticsModule::start();
	KindsModule::start();
	ProblemsModule::start();
	CoreModule::start();
	IFModule::start();
	MultimediaModule::start();
	IndexModule::start();
	InterModule::start();
	BuildingModule::start();
	CodegenModule::start();
	InbuildModule::start();

	int rv = CoreMain::main(argc, argv);

	WordsModule::end();
	InflectionsModule::end();
	SyntaxModule::end();
	LinguisticsModule::end();
	KindsModule::end();
	ProblemsModule::end();
	MultimediaModule::end();
	CoreModule::end();
	IFModule::end();
	IndexModule::end();
	InterModule::end();
	BuildingModule::end();
	CodegenModule::end();
	InbuildModule::end();
	Foundation::end(); /* must be ended last */
	return rv;
}
