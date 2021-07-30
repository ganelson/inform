[InternalTests::] Internal Test Cases.

Handling requests to compile internal tests.

@ Partly because it is not written in a class-oriented programming language,
and partly because it is a complex and very interconnected program, Inform
does not really have unit tests in the usual sense of that term. It's hard
to test individual components with fake data, other than in the course of a
full run of the compiler, in which case you may as well carry out an
end-to-end test anyway.

But Inform does have a mechanism for "internal tests". These involve running
the top half of the compiler more or less as normal, and then making a sharp
turn to perform some test, printing the output to a file, and -- since there
is no point continuing -- stopping the compiler there.

Such internal tests are performed only if the source text instructs it, which is
done with a special, intentionally undocumented, and subject-to-change-without-notice,
syntax like so:
= (text as Inform 7)
Test pattern (internal) with putting the counter on the bench.
=
Internal tests are identified by name -- here, "pattern" -- and are marked
|(internal)|. Optionally, they can supply some text to give them variation, as
here: "putting the counter on the bench".

The Inform test group |:internal| runs a set of these.

@ Each request of the "Test X (internal)" sort generates an //internal_test_case//
object. See //assertions: Test Requests// for how sentences like the above are
parsed; that's the code which calls us here.

=
typedef struct internal_test_case {
	struct internal_test *which_method;
	struct wording text_supplying_the_case;
	struct parse_node *itc_defined_at;
	CLASS_DEFINITION
} internal_test_case;

internal_test_case *InternalTests::new(internal_test *it, wording W) {
	internal_test_case *itc = CREATE(internal_test_case);
	itc->which_method = it;
	itc->text_supplying_the_case = W;
	itc->itc_defined_at = current_sentence;
	return itc;
}

@ Each differently-named test, such as "pattern", corresponds to one of these:

=
typedef struct internal_test {
	struct wording test_name;
	void (*perform)(struct text_stream *, struct internal_test_case *);
	int via_log;
	int at_stage;
	CLASS_DEFINITION
} internal_test;

@ Inform modules wanting to provide internal tests should call the following
when they start up:

=
void InternalTests::make_test_available(text_stream *name,
	void (*perform)(struct text_stream *, struct internal_test_case *), int log) {
	internal_test *it = CREATE(internal_test);
	it->test_name = Feeds::feed_text(name);
	it->perform = perform;
	it->via_log = log;
	it->at_stage = 1;
}

void InternalTests::make_late_test_available(text_stream *name,
	void (*perform)(struct text_stream *, struct internal_test_case *), int log) {
	internal_test *it = CREATE(internal_test);
	it->test_name = Feeds::feed_text(name);
	it->perform = perform;
	it->via_log = log;
	it->at_stage = 2;
}

@ This is slow, but almost never used, so there is no point speeding it up:

=
internal_test *InternalTests::by_name(wording W) {
	internal_test *it;
	LOOP_OVER(it, internal_test)
		if (Wordings::match(W, it->test_name))
			return it;
	return NULL;
}

@ The output from a test is written to a file, and this is its filename, which
is set at the command like with |-test-output|. (The Intest script for testing
|inform7| shows how this works in practice.)

It's a deliberate policy choice to run internal texts this way -- i.e., with
the correct textual output stored in the Inform repository, and open to view --
rather than just as code which is either silent (for a pass) or fails assertions
(for a fail). It's much harder to check that such tests are themselves correctly
written.

=
filename *internal_test_output_file = NULL;
void InternalTests::set_file(filename *F) {
	 internal_test_output_file = F;
}

@ And now we run the tests, returning the number actually run -- which for
end users of Inform, not concerned with compiler maintenance, will always be 0.
Output from the tests is spooled together, and divided up with textual labels
for convenience of reading.

=
int InternalTests::run(int stage) {
	linked_list *L = NEW_LINKED_LIST(internal_test_case);
	internal_test_case *itc;
	LOOP_OVER(itc, internal_test_case)
		if (((itc->which_method == NULL) && (stage == 1)) ||
			((itc->which_method != NULL) && ((itc->which_method->at_stage == stage))))
			ADD_TO_LINKED_LIST(itc, internal_test_case, L);
		
	if (LinkedLists::len(L) == 0) return 0;
	text_stream OUTFILE_struct;
	text_stream *OUT = &OUTFILE_struct;
	if (internal_test_output_file) {
		if (STREAM_OPEN_TO_FILE(OUT, internal_test_output_file, UTF8_ENC) == FALSE)
			Problems::fatal_on_file("Can't open file to write internal test results to",
				internal_test_output_file);
	} else {
		internal_error("internal test cases can only be used with -test-output set");
	}

	int no_in_group = 0, no_run = 0;
	LOOP_OVER_LINKED_LIST(itc, internal_test_case, L) {
		no_in_group++;
		if (itc->which_method == NULL) {
			no_in_group = 0;
			WRITE("\n%+W\n", itc->text_supplying_the_case);
		} else {
			WRITE("%d. %+W\n", no_in_group, itc->text_supplying_the_case);
			@<Run the individual test case@>;
			WRITE("\n");
		}
		no_run++;
	}
	STREAM_CLOSE(OUT);
	return no_run;
}

@ Some tests find it more convenient to write their output to the debugging
log, not to an arbitrary file like |OUT|. For those (identified as |via_log|),
we temporarily wire the two streams together, so that for a brief period
|OUT| actually is the debugging log. This is a hack, but it'll do fine for
testing purposes.

@<Run the individual test case@> =
	text_stream *itc_save_DL = DL;
	current_sentence = itc->itc_defined_at;
	if (itc->which_method->via_log) {
		DL = OUT;
		Streams::enable_debugging(DL);
		Streams::enable_I6_escapes(DL);
	}
	if (itc->which_method->perform)
		(*(itc->which_method->perform))(OUT, itc);
	else
		internal_error("no test performance function");
	if (itc->which_method->via_log) {
		Streams::disable_I6_escapes(DL);
		Streams::disable_debugging(DL);
		DL = itc_save_DL;
	}

@h Some internal tests for services modules.
As noted above, each module of the main Inform compiler can register its own
internal tests. But service modules like //syntax// or //linguistics// have
no access to the function //InternalTests::make_test_available//, so we will
call it for them.

=
void InternalTests::begin(void) {
	InternalTests::make_test_available(I"adjective",
		&InternalTests::perform_adjective_internal_test, FALSE);
	InternalTests::make_test_available(I"dimensions",
		&InternalTests::perform_dimensions_internal_test, TRUE);
	InternalTests::make_test_available(I"kind",
		&InternalTests::perform_kind_internal_test, TRUE);
	InternalTests::make_test_available(I"participle",
		&InternalTests::perform_ing_internal_test, FALSE);
	InternalTests::make_test_available(I"verb",
		&InternalTests::perform_verb_internal_test, FALSE);
	InternalTests::make_late_test_available(I"index",
		&InternalTests::perform_index_internal_test, FALSE);
	InternalTests::make_late_test_available(I"eps",
		&InternalTests::perform_EPS_map_internal_test, FALSE);
}

void InternalTests::perform_dimensions_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	Kinds::Dimensions::log_unit_analysis();
}

void InternalTests::perform_verb_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	Conjugation::test(OUT, itc->text_supplying_the_case,
		Projects::get_language_of_play(Task::project()));
}

void InternalTests::perform_adjective_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	Adjectives::test_adjective(OUT, itc->text_supplying_the_case);
}

void InternalTests::perform_ing_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	Conjugation::test_participle(OUT, itc->text_supplying_the_case);
}

void InternalTests::perform_index_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	index_session *session = Task::index_session(Emit::tree(), Task::project());
	Indexing::generate_one_element(session, OUT, itc->text_supplying_the_case);
	Indexing::close_session(session);
}

void InternalTests::perform_EPS_map_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	index_session *session = Task::index_session(Emit::tree(), Task::project());
	Indexing::generate_EPS_map(session, NULL, OUT);
	Indexing::close_session(session);
}

@ And here's a set of six tests of the kinds system. This is quite old code,
written before the //kinds-test// tool was created, which performs much fuller
unit-testing of the //kinds// module. So we probably don't need these tests any
longer, but they are still in the test suite and do no harm there. They do tend
to be brittle tests in the sense that they will "fail" if a new built-in base
kind is added to //BasicInformKit//, say: but if so, just rebless the new output
and carry on regardless.

=
void InternalTests::perform_kind_internal_test(OUTPUT_STREAM,
	struct internal_test_case *itc) {
	InternalTests::log_poset(
		Vocabulary::get_literal_number_value(
			Lexer::word(
				Wordings::first_wn(
					itc->text_supplying_the_case))));
}

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
			if ((Kinds::conforms_to(A, B)) && (Kinds::conforms_to(B, A)) &&
				(Kinds::eq(A, B) == FALSE))
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
	for (int i=0; i<SIZE_OF_GRAB_BAG; i++) for (int j=i+1; j<SIZE_OF_GRAB_BAG; j++) {
		if (Kinds::conforms_to(tests[i], tests[j])) LOG("%u <= %u\n", tests[i], tests[j]);
		if (Kinds::conforms_to(tests[j], tests[i])) LOG("%u <= %u\n", tests[j], tests[i]);
		kind *M = Latticework::join(tests[i], tests[j]);
		if (Kinds::eq(M, K_value) == FALSE) LOG("max(%u, %u) = %u\n", tests[i], tests[j], M);
	}
