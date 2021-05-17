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
@e PATTERN_INTT

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
	refinery |     ==> { REFINER_INTT, - }
	pattern        ==> { PATTERN_INTT, - }

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
	packaging_state save = Functions::begin(iname);
	internal_test_case *itc; int n = 0;
	LOOP_OVER(itc, internal_test_case) {
		n++;
		if (itc->itc_code == HEADLINE_INTT) {
			n = 0;
			EmitCode::inv(STYLEBOLD_BIP);
			TEMPORARY_TEXT(T)
			WRITE_TO(T, "\n%+W\n", itc->text_supplying_the_case);
			EmitCode::inv(PRINT_BIP);
			EmitCode::down();
				EmitCode::val_text(T);
			EmitCode::up();
			DISCARD_TEXT(T)
			EmitCode::inv(STYLEROMAN_BIP);
			continue;
		}
		TEMPORARY_TEXT(C)
		WRITE_TO(C, "%d. %+W\n", n, itc->text_supplying_the_case);
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(C);
		EmitCode::up();
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
			case PATTERN_INTT:
				@<Perform an internal test of the action pattern parser@>;
				break;
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
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(OUT);
				EmitCode::up();

				EmitCode::inv(INDIRECT1V_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, RTKindConstructors::get_iname(K));
					CompileValues::to_code_val(spec);
				EmitCode::up();

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
				Conjugation::test(OUT, itc->text_supplying_the_case,
					Projects::get_language_of_play(Task::project()));
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
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(OUT);
		EmitCode::up();
		if (internal_test_output_file) WRITE_TO(OUTFILE, "%S", OUT);
		DISCARD_TEXT(OUT)
	}
	Functions::end(save);
	Hierarchy::make_available(iname);
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
		tc = TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_no_problem_reporting());
	}
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	if (p == NULL) LOG("Failed: not a condition");
	else {
		LOG("$D\n", prop);
		if (tc == FALSE) LOG("Failed: proposition would not type-check\n");
		TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_problem_logging());
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
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(OUT);
	EmitCode::up();
	DISCARD_TEXT(OUT)

	if (Kinds::get_construct(K) == CON_list_of) {
		EmitCode::call(Hierarchy::find(LIST_OF_TY_SAY_HL));
		EmitCode::down();
			CompileValues::to_code_val(spec);
			EmitCode::val_number(1);
		EmitCode::up();
	} else {
		EmitCode::call(RTKindConstructors::get_iname(K));
		EmitCode::down();
			CompileValues::to_code_val(spec);
		EmitCode::up();
	}
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(I"\n");
	EmitCode::up();
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
		tc = TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_no_problem_reporting());
	}
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	if (p == NULL) LOG("Failed: not a condition");
	else {
		LOG("$D\n", prop);
		if (tc == FALSE) LOG("Failed: proposition would not type-check\n");
		TypecheckPropositions::type_check(prop, TypecheckPropositions::tc_problem_logging());
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
				if ((Kinds::conforms_to(A, B)) && (Kinds::conforms_to(B, C)) &&
					(Kinds::conforms_to(A, C) == FALSE))
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
	tests[4] = Kinds::unary_con(CON_list_of, K_container);
	tests[5] = Kinds::unary_con(CON_list_of, K_door);
	tests[6] = Kinds::unary_con(CON_list_of, K_person);
	tests[7] = Kinds::unary_con(CON_list_of, K_thing);
	tests[8] = Kinds::binary_con(CON_phrase,
		Kinds::binary_con(CON_TUPLE_ENTRY, K_door, K_void), K_object);
	tests[9] = Kinds::binary_con(CON_phrase,
		Kinds::binary_con(CON_TUPLE_ENTRY, K_object, K_void), K_door);
	tests[10] = Kinds::binary_con(CON_phrase,
		Kinds::binary_con(CON_TUPLE_ENTRY, K_object, K_void), K_object);
	int i, j;
	for (i=0; i<SIZE_OF_GRAB_BAG; i++) for (j=i+1; j<SIZE_OF_GRAB_BAG; j++) {
		if (Kinds::conforms_to(tests[i], tests[j])) LOG("%u <= %u\n", tests[i], tests[j]);
		if (Kinds::conforms_to(tests[j], tests[i])) LOG("%u <= %u\n", tests[j], tests[i]);
		kind *M = Latticework::join(tests[i], tests[j]);
		if (Kinds::eq(M, K_value) == FALSE) LOG("max(%u, %u) = %u\n", tests[i], tests[j], M);
	}
	#endif

@

= (early code)
int ap_test_register_initialised = FALSE;
action_pattern *ap_test_register[10];

@ =
action_pattern *InternalTests::ap_of_nap(action_pattern *ap, wording W) {
	named_action_pattern *nap = NamedActionPatterns::add(ap, W);
	action_pattern *new_ap = ActionPatterns::new(W);
	anl_entry *entry = ActionNameLists::new_entry_at(W);
	entry->item.nap_listed = nap;
	new_ap->action_list = ActionNameLists::new_list(entry, ANL_POSITIVE);
	return new_ap;
}

@

=
<perform-ap-test> ::=
	list {...} |                  ==> { -, - }; ActionNameLists::test_list(WR[1]);
	<test-ap> |                   ==> @<Write textual AP test result@>
	<test-ap> ~~ <test-ap> |      ==> @<Write comparison AP test result@>
	...                           ==> @<Write failure@>

<test-ap> ::=
	<test-ap> is {...} |          ==> { -, InternalTests::ap_of_nap(RP[1], WR[1]) }
	<test-register> = <test-ap> | ==> { -, (ap_test_register[R[1]] = RP[2]) }
	<action-pattern> |            ==> { pass 1 }
	<test-register> |             ==> { -, ap_test_register[R[1]] }
	experimental {...}            ==> { -, ParseClauses::ap_seven(WR[1]) }

<test-register> ::=
	r1 | r2 | r3 | r4 | r5

@<Write textual AP test result@> =
	LOG("%W: $A\n", W, RP[1]);

@<Write comparison AP test result@> =
	int rv = ActionPatterns::compare_specificity(RP[1], RP[2]);
	int rv_converse = ActionPatterns::compare_specificity(RP[2], RP[1]);
	LOG("%W: ", W);
	if (rv > 0) LOG("left is more specific\n");
	if (rv < 0) LOG("right is more specific\n");
	if (rv == 0) LOG("equally specific\n");
	if (rv_converse != -1*rv) LOG("*** Not antisymmetric ***\n");

@<Write failure@> =
	LOG("%W: failed to parse\n", W);

@<Perform an internal test of the action pattern parser@> =
	if (ap_test_register_initialised == FALSE) {
		ap_test_register_initialised = TRUE;
		for (int i=0; i<10; i++) ap_test_register[i] = NULL;
	}
	@<Begin reporting on the internal test case@>; Streams::enable_I6_escapes(DL);
	int saved = ParseActionPatterns::enter_mode(PERMIT_TRYING_OMISSION);
	<perform-ap-test>(itc->text_supplying_the_case);
	ParseActionPatterns::restore_mode(saved);
	Streams::disable_I6_escapes(DL); @<End reporting on the internal test case@>;
