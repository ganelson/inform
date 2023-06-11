[Unit::] Unit Tests.

How we shall test it.

@

=
void Unit::run(filename *F) {
	inter_tree *dummy = InterTree::new();
	inter_bookmark IBM = InterBookmark::at_start_of_this_repository(dummy);
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
@e I6_ANNOTATION_IUT

=
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
	} else if (Str::eq(text, I"annotation")) {
		iut->to_perform = I6_ANNOTATION_IUT;
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
			case I6_ANNOTATION_IUT:
				@<Perform the annotation test@>;
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
	inter_schema *sch = ParsingSchemas::from_text(iut->test_input,
		Provenance::at_file_and_line(I"hypothetical.txt", 1));
	if (sch == NULL) LOG("<null schema>\n");
	else if (sch->node_tree == NULL) LOG("<nodeless scheme\n");
	else InterSchemas::log(DL, sch);
	LOG("=========\n");

@<Perform the annotation test@> =
	LOG("Test: parse annotation from:\n%S\n", iut->test_input);
	int verdict = I6Annotations::check(iut->test_input);
	if (verdict == -1) {
		LOG("Malformed\n");
	} else {
		TEMPORARY_TEXT(A)
		for (int i=0; i<verdict; i++) PUT_TO(A, Str::get_at(iut->test_input, i));
		for (I6_annotation *IA = I6Annotations::parse(A); IA; IA = IA->next) {
			LOG("Annotation: %S\n", IA->identifier);
			if (IA->terms) {
				int i = 0;
				I6_annotation_term *term;
				LOOP_OVER_LINKED_LIST(term, I6_annotation_term, IA->terms) {
					LOG("%d: %S = <%S>\n", i++, term->key, term->value);
				}
			}
		}
		if (verdict < Str::len(iut->test_input)) {
			LOG("Residue: ");
			for (int i = verdict; i<Str::len(iut->test_input); i++)
				LOG("%c", Str::get_at(iut->test_input, i));
		}
		DISCARD_TEXT(A)
	}
	LOG("=========\n");
