[Main::] Main.

A shell for the modules which actually form the compiler.

@ The |inform7| tool is made up of modules: a set of its own, of which |core|
plays the central role; a set which makes up almost the whole of |inbuild|;
a set which makes up almost the whole of |inter|; and the |foundation| module
provided by Inweb, which is a general-purpose C library.

The only code in |inform7| which lies outside these modules is the following
set of dummy mains, which simply hand over to the |core| module. If you would
like a sense of how Inform 7 works, read that, not this.

@d PROGRAM_NAME "inform7"

@ On some platforms the core Inform compiler is a separate command-line tool,
so that execution should begin with |main()|, as in all C programs. But some
Inform UI applications need to compile it into the body of a larger program:
those should define the symbol |SUPPRESS_MAIN| and call |Main::deputy|
when they want I7 to run.

=
#ifndef SUPPRESS_MAIN
int main(int argc, char *argv[]) {
	return Main::deputy(argc, argv);
}
#endif

int Main::deputy(int argc, char *argv[]) {
    @<Start up the modules@>;
	int rv = CoreMain::main(argc, argv);
	@<Shut down the modules@>;
	return rv;
}

@<Start up the modules@> =
	Foundation::start(); /* must be started first */
	CommandLine::set_locale(argc, argv);
	WordsModule::start();
	InflectionsModule::start();
	SyntaxModule::start();
	LexiconModule::start();
	LinguisticsModule::start();
	KindsModule::start();
	ProblemsModule::start();
	CoreModule::start();
	IFModule::start();
	MultimediaModule::start();
	HTMLModule::start();
	IndexModule::start();
	ArchModule::start();
	BytecodeModule::start();
	BuildingModule::start();
	CodegenModule::start();
	SupervisorModule::start();

@<Shut down the modules@> =
	WordsModule::end();
	InflectionsModule::end();
	SyntaxModule::end();
	LexiconModule::end();
	LinguisticsModule::end();
	KindsModule::end();
	ProblemsModule::end();
	MultimediaModule::end();
	CoreModule::end();
	IFModule::end();
	IndexModule::end();
	HTMLModule::end();
	BytecodeModule::end();
	ArchModule::end();
	BuildingModule::end();
	CodegenModule::end();
	SupervisorModule::end();
	Foundation::end(); /* must be ended last */
