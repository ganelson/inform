[Main::] Main.

A shell for the modules which actually form the compiler.

@h Build identity.
First we define the build, using a notation which tangles out to the current
build number as specified in the contents section of this web.

Each time the master copy of NI is modified and recompiled, the build
number (digit-letter-digit-digit) is advanced. Build numbers do not reflect
a hierarchical branching of the source, but are simply a way to encode a
large number in four printable digits. Letters I and O are skipped, and the
tailing two digits run from 01 to 99.

Build 1A01 was the first rough draft of a completed compiler: but it did
not synchronise fully with the OS X Inform application until 1G22 and
private beta-testing did not begin until 1J34. Other milestones include
time (1B92), tables (1C86), component parts (1E60), indexing (1F46),
systematic memory allocation (1J53), pattern matching (1M11), the map index
(1P97), extension documentation support (1S39) and activities (1T89). The
first round of testing, a heroic effort by Emily Short and Sonja Kesserich,
came informally to an end at around the 1V50 build, after which a general
rewriting exercise began. Minor changes needed for David Kinder's Windows
port began to be made with 1W80, but the main aims were to increase speed
and to improve clarity of source code. Hashing algorithms adapted to
word-based syntax were introduced in 1Z50; the prototype parser was then
comprehensively rewritten using a unified system to handle ambiguities and
avoid blind alleys. A time trial of 2D52 against 1V59 on the same, very
large, source text showed a speed increase of a factor of four. A second
stage of rewriting, to generalise binary predicates and improve grammatical
accuracy, began with 2D70. By the time of the first public beta release,
3K27, the testing tool |inform-test| had been written (it subsequently
evolved into today's |intest|), and Emily Short's extensive suite of Examples
had been worked into the verification process for builds. The history since
3K27 is recorded in the published change log.

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

@ All our modules have to be started up and shut down, so we take care of that
with one more intermediary:

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
	IFModule::start();
	MultimediaModule::start();
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
	MultimediaModule::end();
	CoreModule::end();
	IFModule::end();
	IndexModule::end();
	InterModule::end();
	CodegenModule::end();
	Foundation::end();
	return rv;
}
