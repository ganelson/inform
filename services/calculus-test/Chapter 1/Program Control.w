[Main::] Program Control.

What shall we test?

@ A simple command line:

@d PROGRAM_NAME "calculus-test"

@e INTERPRET_CLSW
@e LOAD_CLSW

=
int main(int argc, char **argv) {
	Foundation::start(argc, argv);
	WordsModule::start();
	SyntaxModule::start();
	LexiconModule::start();
	InflectionsModule::start();
	LinguisticsModule::start();
	KindsModule::start();
	CalculusModule::start();

	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"calculus-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, I"Syntax.preform");
	LoadPreform::load(S, NULL);

	CommandLine::declare_heading(
		L"calculus-test: a tool for testing the calculus module\n");

	CommandLine::declare_switch(LOAD_CLSW, L"load", 2,
		L"load kind definitions from file X");
	CommandLine::declare_switch(INTERPRET_CLSW, L"interpret", 2,
		L"interpret REPL commands in file X");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	SyntaxModule::end();
	LexiconModule::end();
	InflectionsModule::end();
	LinguisticsModule::end();
	KindsModule::end();
	CalculusModule::end();
	Foundation::end();
	return 0;
}

@ =
void Main::respond(int id, int val, text_stream *arg, void *state) {
	text_stream *save_DL = DL;
	DL = STDOUT;
	Streams::enable_debugging(DL);
	switch (id) {
		case LOAD_CLSW: NeptuneFiles::load(Filenames::from_text(arg)); break;
		case INTERPRET_CLSW: Declarations::load_from_file(arg); break;
	}
	DL = save_DL;
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}

@

@d DIVIDE_AT_COLON_SYNTAX_CALLBACK Main::dont

=
int Main::dont(int wn) {
	return FALSE;
}

@

@d TERM_DOMAIN_WORDING_FUNCTION Main::get_name_text
@d TERM_DOMAIN_FROM_KIND_FUNCTION Main::get_kind
@d TERM_DOMAIN_TO_KIND_FUNCTION Main::get_kind
@d VALUE_TO_KIND_FUNCTION Main::value_to_kind
@d RVALUE_TO_KIND_FUNCTION Main::value_to_kind
@d VALUE_TO_RELATION_FUNCTION Main::value_to_relation
@d ADJECTIVE_APPLICABLE_FUNCTION Main::adjective_applicable
@d NP_IS_DESCRIPTIVE Main::is_descriptive
@d NP_TO_PROPOSITION Main::to_proposition

=
wording Main::get_name_text(kind *K) {
	return EMPTY_WORDING;
}
kind *Main::get_kind(kind *K) {
	return K;
}
kind *Main::value_to_kind(parse_node *val) {
	return K_number;
}
binary_predicate *Main::value_to_relation(parse_node *val) {
	return NULL;
}
int Main::adjective_applicable(adjective *aph, kind *K) {
	return TRUE;
}
int Main::is_descriptive(parse_node *val) {
	return FALSE;
}
pcalc_prop *Main::to_proposition(parse_node *val) {
	return NULL;
}

@

@d EQUALITY_RELATION_NAME 0
@d UNIVERSAL_RELATION_NAME 1
@d POSSESSION_RELATION_NAME 2

=
<relation-names> ::=
	equality |
	universal |
	possession
