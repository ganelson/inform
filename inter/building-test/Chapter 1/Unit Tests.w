[Unit::] Unit Tests.

How we shall test it.

@

=
void Unit::run(filename *F) {
	inter_tree *dummy = InterTree::new();
	inter_bookmark IBM = Inter::Bookmarks::at_start_of_this_repository(dummy);
	Primitives::declare_standard_set(dummy, &IBM);
	Streams::enable_debugging(STDOUT);
	text_stream *FORMER_DL = DL;
	DL = STDOUT;
	inter_unit_test iut;
	iut.to_perform = NO_IUT;
	iut.test_input = Str::new();
	TextFiles::read(F, FALSE, "unable to read tests file", TRUE,
		&Unit::test_harvester, NULL, &iut);
	Streams::disable_debugging(STDOUT);
	DL = FORMER_DL;
}

@

@e NO_IUT from 0
@e SCHEMA_IUT
@e SCHEMA_WORKINGS_IUT

typedef struct inter_unit_test {
	int to_perform;
	struct text_stream *test_input;
} inter_unit_test;

void Unit::test_harvester(text_stream *text, text_file_position *tfp, void *v_iut) {
	inter_unit_test *iut = (inter_unit_test *) v_iut;
	if (Str::eq(text, I"schema")) {
		iut->to_perform = SCHEMA_IUT;
		Str::clear(iut->test_input);
	} else if (Str::eq(text, I"schema-workings")) {
		iut->to_perform = SCHEMA_WORKINGS_IUT;
		Str::clear(iut->test_input);
	} else if (Str::eq(text, I"end")) {
		switch (iut->to_perform) {
			case SCHEMA_WORKINGS_IUT:
				Log::set_aspect(SCHEMA_COMPILATION_DETAILS_DA, TRUE);
				@<Perform the schema test@>;
				Log::set_aspect(SCHEMA_COMPILATION_DETAILS_DA, FALSE);
				break;
			case SCHEMA_IUT:
				@<Perform the schema test@>;
				break;
			default: Errors::in_text_file("unimplemented test", tfp); break;
		}
		iut->to_perform = NO_IUT;
	} else {
		if (iut->to_perform == NO_IUT) {
			if (Str::len(text) == 0) return;
			Errors::in_text_file("content outside of test", tfp);
		} else {
			WRITE_TO(iut->test_input, "%S\n", text);
		}
	}
}

@<Perform the schema test@> =
	LOG("Test: parse schema from:\n%S\n", iut->test_input);
	Str::trim_white_space(iut->test_input);
	inter_schema *sch = ParsingSchemas::from_text(iut->test_input);
	if (sch == NULL) LOG("<null schema>\n");
	else if (sch->node_tree == NULL) LOG("<nodeless scheme\n");
	else InterSchemas::log(DL, sch);
	LOG("=========\n");
