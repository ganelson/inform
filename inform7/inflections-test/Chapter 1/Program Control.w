[Main::] Program Control.

What shall we test?

@h Main routine.

@d PROGRAM_NAME "inflections-test"

@e TEST_ADJECTIVES_CLSW
@e TEST_ARTICLES_CLSW
@e TEST_DECLENSIONS_CLSW
@e TEST_PARTICIPLES_CLSW
@e TEST_PLURALS_CLSW
@e TEST_VERBS_CLSW

=
int main(int argc, char **argv) {
	Foundation::start();
	WordsModule::start();
	InflectionsModule::start();

	CommandLine::declare_heading(L"inflections-test: a tool for testing inflections facilities\n");

	CommandLine::declare_switch(TEST_ADJECTIVES_CLSW, L"test-adjectives", 2,
		L"test adjective inflection (from list in X)");
	CommandLine::declare_switch(TEST_ARTICLES_CLSW, L"test-articles", 2,
		L"test article inflection (from list in X)");
	CommandLine::declare_switch(TEST_DECLENSIONS_CLSW, L"test-declensions", 2,
		L"test noun declension (from list in X)");
	CommandLine::declare_switch(TEST_PARTICIPLES_CLSW, L"test-participles", 2,
		L"test plural inflection (from list in X)");
	CommandLine::declare_switch(TEST_PLURALS_CLSW, L"test-plurals", 2,
		L"test plural inflection (from list in X)");
	CommandLine::declare_switch(TEST_VERBS_CLSW, L"test-verbs", 2,
		L"test verb conjugation (from list in X)");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::ignore);

	WordsModule::end();
	InflectionsModule::end();
	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEST_ADJECTIVES_CLSW: Main::load(I"Syntax.preform"); Unit::test_adjectives(arg); break;
		case TEST_ARTICLES_CLSW: Main::load(I"Syntax.preform"); Unit::test_articles(arg); break;
		case TEST_DECLENSIONS_CLSW: Main::load_other(I"German.preform"); Unit::test_declensions(arg); break;
		case TEST_PARTICIPLES_CLSW: Main::load(I"Syntax.preform"); Unit::test_participles(arg); break;
		case TEST_PLURALS_CLSW: Main::load(I"Syntax.preform"); Unit::test_plurals(arg); break;
		case TEST_VERBS_CLSW: Main::load(I"Syntax.preform"); Unit::test_verbs(arg); break;
	}
}

void Main::load(text_stream *leaf) {
	pathname *P = Pathnames::from_text(I"inform7");
	P = Pathnames::down(P, I"inflections-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, leaf);
	wording W = Preform::load_from_file(S);
	Preform::parse_preform(W, FALSE);
}

void Main::load_other(text_stream *leaf) {
	pathname *P = Pathnames::from_text(I"inform7");
	P = Pathnames::down(P, I"inflections-test");
	P = Pathnames::down(P, I"Preform");
	filename *S = Filenames::in(P, leaf);
	wording W = Preform::load_from_file(S);
	Preform::parse_preform(W, FALSE);
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
