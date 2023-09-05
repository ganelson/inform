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
	Foundation::start(argc, argv);
	WordsModule::start();
	InflectionsModule::start();

	CommandLine::declare_heading(U"inflections-test: a tool for testing inflections facilities\n");

	CommandLine::declare_switch(TEST_ADJECTIVES_CLSW, U"test-adjectives", 2,
		U"test adjective inflection (from list in X)");
	CommandLine::declare_switch(TEST_ARTICLES_CLSW, U"test-articles", 2,
		U"test article inflection (from list in X)");
	CommandLine::declare_switch(TEST_DECLENSIONS_CLSW, U"test-declensions", 2,
		U"test noun declension (from list in X)");
	CommandLine::declare_switch(TEST_PARTICIPLES_CLSW, U"test-participles", 2,
		U"test plural inflection (from list in X)");
	CommandLine::declare_switch(TEST_PLURALS_CLSW, U"test-plurals", 2,
		U"test plural inflection (from list in X)");
	CommandLine::declare_switch(TEST_VERBS_CLSW, U"test-verbs", 2,
		U"test verb conjugation (from list in X)");

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
	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"inflections-test");
	P = Pathnames::down(P, I"Tangled");
	filename *S = Filenames::in(P, leaf);
	LoadPreform::load(S, NULL);
}

void Main::load_other(text_stream *leaf) {
	pathname *P = Pathnames::from_text(I"services");
	P = Pathnames::down(P, I"inflections-test");
	P = Pathnames::down(P, I"Preform");
	filename *S = Filenames::in(P, leaf);
	LoadPreform::load(S, NULL);
}

void Main::ignore(int id, text_stream *arg, void *state) {
	Errors::fatal("only switches may be used at the command line");
}
