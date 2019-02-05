[Main::] Program Control.

The top level, which decides what is to be done and then carries
this plan out.

@

@d INTOOL_NAME "inform7"
@d INFORM7_BUILD "inform7 [[Build Number]]"
@d HUMAN_READABLE_INTOOL_NAME "Inform 7"

@h Main itself.
On some platforms the core Inform compiler is a separate command-line tool,
but on others it's compiled into the body of an application. So:

=
#ifndef SUPPRESS_MAIN
int main(int argc, char *argv[]) {
	return Main::core_inform_main(argc, argv);
}
#endif

@ As a matter of policy, no module is allowed to start or stop the foundation
module, not even the mighty core; so we take care of that with one more
intermediary:

=
int Main::core_inform_main(int argc, char *argv[]) {
	Foundation::start();
	WordsModule::start();
	InflectionsModule::start();
	SyntaxModule::start();
	LinguisticsModule::start();
	KindsModule::start();
	ProblemsModule::start();
	CoreModule::start();
	IndexModule::start();
	InterModule::start();
	CodegenModule::start();

	int rv = CoreMain::main(argc, argv);

	WordsModule::end();
	InflectionsModule::end();
	SyntaxModule::end();
	LinguisticsModule::end();
	KindsModule::end();
	ProblemsModule::end();
	CoreModule::end();
	IndexModule::end();
	InterModule::end();
	CodegenModule::end();
	Foundation::end();
	return rv;
}
