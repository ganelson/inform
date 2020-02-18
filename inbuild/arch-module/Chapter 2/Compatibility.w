[Compatibility::] Compatibility.

To manage compatibility lists: what can be compiled to what format.

@

=
typedef struct compatibility_specification {
	int default_allows;
	struct linked_list *exceptions; /* of |inter_architecture| */
	MEMORY_MANAGEMENT
} compatibility_specification;

compatibility_specification *Compatibility::all(void) {
	compatibility_specification *C = CREATE(compatibility_specification);
	C->default_allows = TRUE;
	C->exceptions = NEW_LINKED_LIST(inter_architecture);
	return C;
}

void Compatibility::write(OUTPUT_STREAM, compatibility_specification *C) {
	if (C == NULL) { WRITE("for none"); return; }
	int x = LinkedLists::len(C->exceptions);
	if (x == 0) {
		if (C->default_allows) WRITE("for all");
		else WRITE("for none");
	} else {
		if (C->default_allows) WRITE("not ");
		WRITE("for ");
		int n = 0;
		inter_architecture *A;
		LOOP_OVER_LINKED_LIST(A, inter_architecture, C->exceptions) {
			n++;
			if ((n > 1) && (n < x)) WRITE(", ");
			if ((n > 1) && (n == x)) WRITE(" or ");
			WRITE("%S", Architectures::to_codename(A));
		}
	}
}
	
compatibility_specification *Compatibility::from_text(text_stream *text) {
	compatibility_specification *C = Compatibility::all();
	int incorrect = FALSE;
	if (Str::len(text) == 0) return C;
	TEMPORARY_TEXT(parse);
	WRITE_TO(parse, "%S", text);
	Str::trim_white_space(parse);

	C->default_allows = FALSE;
	match_results mr = Regexp::create_mr();
	int negated = FALSE;
	if (Regexp::match(&mr, parse, L"not (%c+)")) {
		Str::clear(parse);
		WRITE_TO(parse, "%S", mr.exp[0]);
		Str::trim_white_space(parse);
		C->default_allows = TRUE;
		negated = TRUE;
	}

	if (Regexp::match(&mr, parse, L"for (%c+)")) {
		Str::clear(parse);
		WRITE_TO(parse, "%S", mr.exp[0]);
		Str::trim_white_space(parse);
	}
	
	if (Str::eq(parse, I"all")) {
		if (negated) incorrect = TRUE; /* "not for all" */
		C->default_allows = TRUE;
	} else if (Str::eq(parse, I"none")) {
		if (negated) incorrect = TRUE; /* "not for none" */
		C->default_allows = FALSE;
	} else if (Compatibility::clause(C, parse) == FALSE)
		incorrect = TRUE;

	DISCARD_TEXT(parse);
	Regexp::dispose_of(&mr);
	if (incorrect) C = NULL;
	return C;
}

int Compatibility::clause(compatibility_specification *C, text_stream *text) {
	int correct = FALSE;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, text, L"(%c+?), (%c+)")) {
		int a = Compatibility::clause(C, mr.exp[0]);
		int b = Compatibility::clause(C, mr.exp[1]);
		correct = a && b;
	} else if (Regexp::match(&mr, text, L"(%c+?) or (%c+)")) {
		int a = Compatibility::clause(C, mr.exp[0]);
		int b = Compatibility::clause(C, mr.exp[1]);
		correct = a && b;
	} else {
		inter_architecture *A = Architectures::from_codename(text);
		if (A) {
			int already_there = FALSE;
			inter_architecture *X;
			LOOP_OVER_LINKED_LIST(X, inter_architecture, C->exceptions)
				if (A == X)
					already_there = TRUE;
			if (already_there == FALSE) {
				ADD_TO_LINKED_LIST(A, inter_architecture, C->exceptions);
				correct = TRUE;
			}
		}
	}
	Regexp::dispose_of(&mr);
	return correct;
}

int Compatibility::with(compatibility_specification *C, inter_architecture *A) {
	if (C == NULL) return FALSE;
	int decision = C->default_allows;
	inter_architecture *X;
	LOOP_OVER_LINKED_LIST(X, inter_architecture, C->exceptions)
		if (A == X)
			decision = decision?FALSE:TRUE;
	return decision;
}

void Compatibility::test(OUTPUT_STREAM) {
	Compatibility::test_one(OUT, I"for all");
	Compatibility::test_one(OUT, I"all");
	Compatibility::test_one(OUT, I"not for all");
	Compatibility::test_one(OUT, I"not all");
	Compatibility::test_one(OUT, I"for none");
	Compatibility::test_one(OUT, I"none");
	Compatibility::test_one(OUT, I"not for none");
	Compatibility::test_one(OUT, I"not none");
	Compatibility::test_one(OUT, I"for 16d");
	Compatibility::test_one(OUT, I"not for 32");
	Compatibility::test_one(OUT, I"for 16d or 32d");
	Compatibility::test_one(OUT, I"not for 32 or 16");
	Compatibility::test_one(OUT, I"for 16d, 32d or 32");
	Compatibility::test_one(OUT, I"not for 16d, 32d or 32");
}

void Compatibility::test_one(OUTPUT_STREAM, text_stream *test) {
	WRITE("'%S': ", test);
	compatibility_specification *C = Compatibility::from_text(test);
	if (C == NULL) { WRITE("not a valid compatibility specification\n"); return; }
	Compatibility::write(OUT, C);
	WRITE(":");
	inter_architecture *A;
	LOOP_OVER(A, inter_architecture)
		WRITE(" %S=%S", Architectures::to_codename(A),
			(Compatibility::with(C, A))?I"yes":I"no");
	WRITE("\n");
}
