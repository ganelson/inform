[InternalTests::] Internal Test Cases.

Handling requests to compile internal tests.

@ To exercise some of these, run the //intest// test group |:internal| through
Inform. The current roster is as follows:

@e HEADLINE_INTT
@e SENTENCE_INTT
@e DESCRIPTION_INTT
@e DIMENSIONS_INTT
@e EVALUATION_INTT
@e EQUATION_INTT
@e VERB_INTT
@e ADJECTIVE_INTT
@e ING_INTT
@e KIND_INTT
@e MAP_INTT
@e DASH_INTT
@e DASHLOG_INTT
@e REFINER_INTT

@ The following are the names of the internal test cases, which are in English
only and may change at any time without notice.

=
<internal-test-case-name> ::=
	headline |     ==> { HEADLINE_INTT, - }
	sentence |     ==> { SENTENCE_INTT, - }
	description |  ==> { DESCRIPTION_INTT, - }
	dimensions |   ==> { DIMENSIONS_INTT, - }
	evaluation |   ==> { EVALUATION_INTT, - }
	equation |     ==> { EQUATION_INTT, - }
	verb |         ==> { VERB_INTT, - }
	adjective |    ==> { ADJECTIVE_INTT, - }
	participle |   ==> { ING_INTT, - }
	kind |         ==> { KIND_INTT, - }
	map |          ==> { MAP_INTT, - }
	dash |         ==> { DASH_INTT, - }
	dashlog |      ==> { DASHLOG_INTT, - }
	refinery       ==> { REFINER_INTT, - }

@ Each request to run one of the above generates an //internal_test_case// object:

=
typedef struct internal_test_case {
	int itc_code; /* one of the |*_INTT| values */
	struct wording text_supplying_the_case;
	struct parse_node *itc_defined_at;
	CLASS_DEFINITION
} internal_test_case;

@ =
internal_test_case *InternalTests::new(int code, wording W) {
	internal_test_case *itc = CREATE(internal_test_case);
	itc->itc_code = code;
	itc->text_supplying_the_case = W;
	itc->itc_defined_at = current_sentence;
	return itc;
}

filename *internal_test_output_file = NULL;
void InternalTests::set_file(filename *F) {
	 internal_test_output_file = F;
}

text_stream *itc_save_DL = NULL, *itc_save_OUT = NULL;

void InternalTests::InternalTestCases_routine(void) {
	text_stream OUTFILE_struct; text_stream *OUTFILE = &OUTFILE_struct;
	if (internal_test_output_file) {
		if (STREAM_OPEN_TO_FILE(OUTFILE, internal_test_output_file, UTF8_ENC) == FALSE)
			Problems::fatal_on_file("Can't open file to write internal test results to",
				internal_test_output_file);
	}

	inter_name *iname = Hierarchy::find(INTERNALTESTCASES_HL);
	packaging_state save = Routines::begin(iname);
	internal_test_case *itc; int n = 0;
	LOOP_OVER(itc, internal_test_case) {
		n++;
		if (itc->itc_code == HEADLINE_INTT) {
			n = 0;
			Produce::inv_primitive(Emit::tree(), STYLEBOLD_BIP);
			TEMPORARY_TEXT(T)
			WRITE_TO(T, "\n%+W\n", itc->text_supplying_the_case);
			Produce::inv_primitive(Emit::tree(), PRINT_BIP);
			Produce::down(Emit::tree());
				Produce::val_text(Emit::tree(), T);
			Produce::up(Emit::tree());
			DISCARD_TEXT(T)
			Produce::inv_primitive(Emit::tree(), STYLEROMAN_BIP);
			continue;
		}
		TEMPORARY_TEXT(C)
		WRITE_TO(C, "%d. %+W\n", n, itc->text_supplying_the_case);
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), C);
		Produce::up(Emit::tree());
		DISCARD_TEXT(C)

		TEMPORARY_TEXT(OUT)
		itc_save_OUT = OUT;
		current_sentence = itc->itc_defined_at;
		switch (itc->itc_code) {
			case SENTENCE_INTT: {
				int SV_not_SN = TRUE;
				@<Perform an internal test of the sentence converter@>;
				break;
			}
			case DESCRIPTION_INTT: {
				int SV_not_SN = FALSE;
				@<Perform an internal test of the sentence converter@>;
				break;
			}
			case EVALUATION_INTT: {
				parse_node *spec = NULL;
				if (<s-value>(itc->text_supplying_the_case)) spec = <<rp>>;
				else spec = Specifications::new_UNKNOWN(itc->text_supplying_the_case);
				Dash::check_value(spec, NULL);
				kind *K = Specifications::to_kind(spec);
				WRITE("Kind of value: ");
				@<Begin reporting on the internal test case@>;
				Kinds::Textual::log(K);
				if (Kinds::Behaviour::is_quasinumerical(K))
					LOG(" scaled at k=%d", Kinds::Behaviour::scale_factor(K));
				@<End reporting on the internal test case@>;
				WRITE("\nPrints as: ");
				Produce::inv_primitive(Emit::tree(), PRINT_BIP);
				Produce::down(Emit::tree());
					Produce::val_text(Emit::tree(), OUT);
				Produce::up(Emit::tree());

				Produce::inv_primitive(Emit::tree(), INDIRECT1V_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Kinds::Behaviour::get_iname(K));
					Specifications::Compiler::emit_as_val(K_value, spec);
				Produce::up(Emit::tree());

				Str::clear(OUT);
				WRITE("\n");
				break;
			}
			case DIMENSIONS_INTT:
				@<Begin reporting on the internal test case@>;
				Kinds::Dimensions::log_unit_analysis();
				@<End reporting on the internal test case@>;
				break;
			case EQUATION_INTT:
				Equations::internal_test(itc->text_supplying_the_case);
				break;
			case VERB_INTT:
				Conjugation::test(OUT, itc->text_supplying_the_case, Projects::get_language_of_play(Task::project()));
				break;
			case ADJECTIVE_INTT:
				Adjectives::test_adjective(OUT, itc->text_supplying_the_case);
				break;
			case ING_INTT:
				Conjugation::test_participle(OUT, itc->text_supplying_the_case);
				break;
			case KIND_INTT:
				@<Begin reporting on the internal test case@>;
				InternalTests::log_poset(
					Vocabulary::get_literal_number_value(
						Lexer::word(
							Wordings::first_wn(
								itc->text_supplying_the_case))));
				@<End reporting on the internal test case@>;
				break;
			#ifdef IF_MODULE
			case MAP_INTT:
				@<Begin reporting on the internal test case@>;
				PL::SpatialMap::log_spatial_layout();
				@<End reporting on the internal test case@>;
				break;
			#endif
			case DASH_INTT:
				@<Begin reporting on the internal test case@>;
				Dash::experiment(itc->text_supplying_the_case, FALSE);
				@<End reporting on the internal test case@>;
				break;
			case DASHLOG_INTT:
				Dash::experiment(itc->text_supplying_the_case, TRUE);
				break;
			case REFINER_INTT:
				@<Perform an internal test of the refinery@>;
				break;
		}
		WRITE("\n");
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), OUT);
		Produce::up(Emit::tree());
		if (internal_test_output_file) WRITE_TO(OUTFILE, "%S", OUT);
		DISCARD_TEXT(OUT)
	}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
	if (internal_test_output_file) STREAM_CLOSE(OUTFILE);
}

void InternalTests::begin_internal_reporting(void) {
	@<Begin reporting on the internal test case@>;
}

void InternalTests::end_internal_reporting(void) {
	@<End reporting on the internal test case@>;
}

@<Perform an internal test of the sentence converter@> =
	parse_node *p = NULL;
	pcalc_prop *prop = NULL;
	int tc = FALSE;

	if (SV_not_SN) {
		if (<s-sentence>(itc->text_supplying_the_case)) p = <<rp>>;
	} else {
		if (<s-descriptive-np>(itc->text_supplying_the_case)) p = <<rp>>;
	}
	if (p) {
		prop = Specifications::to_proposition(p);
		tc = Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
	}
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	if (p == NULL) LOG("Failed: not a condition");
	else {
		LOG("$D\n", prop);
		if (tc == FALSE) LOG("Failed: proposition would not type-check\n");
		Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_problem_logging());
	}
	Streams::disable_I6_escapes(DL); @<End reporting on the internal test case@>;

@<Perform an internal test of the refinery@> =
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	wording W = itc->text_supplying_the_case;
	parse_node *p = Node::new(SENTENCE_NT); Node::set_text(p, W);
	Classifying::sentence(p);
	LOG("Classification:\n$T", p);
	if ((p->down) && (p->down->next) && (p->down->next->next)) {
		parse_node *px = p->down->next;
		parse_node *py = px->next;
		Refiner::refine_coupling(px, py, TRUE);
		LOG("After creation:\n$T", p);
	}
	Streams::disable_I6_escapes(DL); @<End reporting on the internal test case@>;

@<Begin reporting on the internal test case@> =
	itc_save_DL = DL; DL = itc_save_OUT;
	Streams::enable_debugging(DL); // Streams::enable_I6_escapes(DL);

@<End reporting on the internal test case@> =
	Streams::disable_debugging(DL); // Streams::disable_I6_escapes(DL);
	DL = itc_save_DL;

@ =
void InternalTests::emit_showme(parse_node *spec) {
	TEMPORARY_TEXT(OUT)
	itc_save_OUT = OUT;
	if (Node::is(spec, PROPERTY_VALUE_NT))
		spec = Lvalues::underlying_property(spec);
	kind *K = Specifications::to_kind(spec);
	if (Node::is(spec, CONSTANT_NT) == FALSE)
		WRITE("\"%+W\" = ", Node::get_text(spec));
	@<Begin reporting on the internal test case@>;
	Kinds::Textual::log(K);
	@<End reporting on the internal test case@>;
	WRITE(": ");
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Produce::down(Emit::tree());
		Produce::val_text(Emit::tree(), OUT);
	Produce::up(Emit::tree());
	DISCARD_TEXT(OUT)

	if (Kinds::get_construct(K) == CON_list_of) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SAY_HL));
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_as_val(K_value, spec);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	} else {
		BEGIN_COMPILATION_MODE;
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
		Produce::inv_call_iname(Emit::tree(), Kinds::Behaviour::get_iname(K));
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_as_val(K_value, spec);
		Produce::up(Emit::tree());
		END_COMPILATION_MODE;
	}
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Produce::down(Emit::tree());
		Produce::val_text(Emit::tree(), I"\n");
	Produce::up(Emit::tree());
}

@<Perform an internal test of the sentence converter@> =
	parse_node *p = NULL;
	pcalc_prop *prop = NULL;
	int tc = FALSE;

	if (SV_not_SN) {
		if (<s-sentence>(itc->text_supplying_the_case)) p = <<rp>>;
	} else {
		if (<s-descriptive-np>(itc->text_supplying_the_case)) p = <<rp>>;
	}
	if (p) {
		prop = Specifications::to_proposition(p);
		tc = Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_no_problem_reporting());
	}
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	if (p == NULL) LOG("Failed: not a condition");
	else {
		LOG("$D\n", prop);
		if (tc == FALSE) LOG("Failed: proposition would not type-check\n");
		Calculus::Propositions::Checker::type_check(prop, Calculus::Propositions::Checker::tc_problem_logging());
	}
	Streams::disable_I6_escapes(DL); @<End reporting on the internal test case@>;

@ And here's a test of the kinds system (though in practice test cases for the
//kinds-test// tool probably now does a better job):

=
void InternalTests::log_poset(int n) {
	switch (n) {
		case 1: @<Display the subkind relation of base kinds@>; break;
		case 2: @<Display the compatibility relation of base kinds@>; break;
		case 3: @<Display the results of the superkind function@>; break;
		case 4: @<Check for poset violations@>; break;
		case 5: @<Check the maximum function@>; break;
		case 6: @<Some miscellaneous tests with a grab bag of kinds@>; break;
	}
}

@<Display the subkind relation of base kinds@> =
	LOG("The subkind relation on (base) kinds:\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A) {
		int c = 0;
		LOOP_OVER_BASE_KINDS(B) {
			if ((Kinds::conforms_to(A, B)) && (Kinds::eq(A, B) == FALSE)) {
				if (c++ == 0) LOG("%u <= ", A); else LOG(", ");
				LOG("%u", B);
			}
		}
		if (c > 0) LOG("\n");
	}

@<Display the compatibility relation of base kinds@> =
	LOG("The (always) compatibility relation on (base) kinds, where it differs from <=:\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A) {
		int c = 0;
		LOOP_OVER_BASE_KINDS(B) {
			if ((Kinds::compatible(A, B) == ALWAYS_MATCH) &&
				(Kinds::conforms_to(A, B) == FALSE) &&
				(Kinds::eq(A, K_value) == FALSE)) {
				if (c++ == 0) LOG("%u --> ", A); else LOG(", ");
				LOG("%u", B);
			}
		}
		if (c > 0) LOG("\n");
	}

@<Display the results of the superkind function@> =
	LOG("The superkind function applied to base kinds:\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A) {
		for (B = A; B; B = Latticework::super(B))
			LOG("%u -> ", B);
		LOG("\n");
	}

@<Check for poset violations@> =
	LOG("Looking for partially ordered set violations.\n");
	kind *A, *B, *C;
	LOOP_OVER_BASE_KINDS(A)
		if (Kinds::conforms_to(A, A) == FALSE)
			LOG("Reflexivity violated: %u\n", A);
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if ((Kinds::conforms_to(A, B)) && (Kinds::conforms_to(B, A)) && (Kinds::eq(A, B) == FALSE))
				LOG("Antisymmetry violated: %u, %u\n", A, B);
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			LOOP_OVER_BASE_KINDS(C)
				if ((Kinds::conforms_to(A, B)) && (Kinds::conforms_to(B, C)) && (Kinds::conforms_to(A, C) == FALSE))
					LOG("Transitivity violated: %u, %u, %u\n", A, B, C);

@<Check the maximum function@> =
	LOG("Looking for maximum violations.\n");
	kind *A, *B;
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if (Kinds::eq(Latticework::join(A, B), Latticework::join(B, A)) == FALSE)
				LOG("Fail symmetry: max(%u, %u) = %u, but max(%u, %u) = %u\n",
					A, B, Latticework::join(A, B), B, A, Latticework::join(B, A));
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if (Kinds::conforms_to(A, Latticework::join(A, B)) == FALSE)
				LOG("Fail maximality(A): max(%u, %u) = %u\n", A, B, Latticework::join(A, B));
	LOOP_OVER_BASE_KINDS(A)
		LOOP_OVER_BASE_KINDS(B)
			if (Kinds::conforms_to(B, Latticework::join(A, B)) == FALSE)
				LOG("Fail maximality(B): max(%u, %u) = %u\n", A, B, Latticework::join(A, B));
	LOOP_OVER_BASE_KINDS(A)
		if (Kinds::eq(Latticework::join(A, A), A) == FALSE)
				LOG("Fail: max(%u, %u) = %u\n",
					A, A, Latticework::join(A, A));

@

@d SIZE_OF_GRAB_BAG 11

@<Some miscellaneous tests with a grab bag of kinds@> =
	#ifdef IF_MODULE
	kind *tests[SIZE_OF_GRAB_BAG];
	tests[0] = K_number;
	tests[1] = K_container;
	tests[2] = K_door;
	tests[3] = K_thing;
	tests[4] = Kinds::unary_construction(CON_list_of, K_container);
	tests[5] = Kinds::unary_construction(CON_list_of, K_door);
	tests[6] = Kinds::unary_construction(CON_list_of, K_person);
	tests[7] = Kinds::unary_construction(CON_list_of, K_thing);
	tests[8] = Kinds::binary_construction(CON_phrase,
		Kinds::binary_construction(CON_TUPLE_ENTRY, K_door, K_void), K_object);
	tests[9] = Kinds::binary_construction(CON_phrase,
		Kinds::binary_construction(CON_TUPLE_ENTRY, K_object, K_void), K_door);
	tests[10] = Kinds::binary_construction(CON_phrase,
		Kinds::binary_construction(CON_TUPLE_ENTRY, K_object, K_void), K_object);
	int i, j;
	for (i=0; i<SIZE_OF_GRAB_BAG; i++) for (j=i+1; j<SIZE_OF_GRAB_BAG; j++) {
		if (Kinds::conforms_to(tests[i], tests[j])) LOG("%u <= %u\n", tests[i], tests[j]);
		if (Kinds::conforms_to(tests[j], tests[i])) LOG("%u <= %u\n", tests[j], tests[i]);
		kind *M = Latticework::join(tests[i], tests[j]);
		if (Kinds::eq(M, K_value) == FALSE) LOG("max(%u, %u) = %u\n", tests[i], tests[j], M);
	}
	#endif

