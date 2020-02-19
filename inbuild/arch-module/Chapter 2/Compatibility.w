[Compatibility::] Compatibility.

To manage compatibility lists: what can be compiled to what format.

@

=
typedef struct compatibility_specification {
	struct text_stream *parsed_from;
	int default_allows;
	struct linked_list *exceptions; /* of |target_vm| */
	MEMORY_MANAGEMENT
} compatibility_specification;

compatibility_specification *Compatibility::all(void) {
	compatibility_specification *C = CREATE(compatibility_specification);
	C->parsed_from = NULL;
	C->default_allows = TRUE;
	C->exceptions = NEW_LINKED_LIST(target_vm);
	return C;
}

int Compatibility::universal(compatibility_specification *C) {
	if (C == NULL) return FALSE;
	if (LinkedLists::len(C->exceptions) > 0) return FALSE;
	if (C->default_allows == FALSE) return FALSE;
	return TRUE;
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
		target_vm *VM;
		LOOP_OVER_LINKED_LIST(VM, target_vm, C->exceptions) {
			n++;
			if ((n > 1) && (n < x)) WRITE(", ");
			if ((n > 1) && (n == x)) WRITE(" or ");
			TargetVMs::write(OUT, VM);
		}
	}
}
	
compatibility_specification *Compatibility::from_text(text_stream *text) {
	compatibility_specification *C = Compatibility::all();
	int incorrect = FALSE;
	if (Str::len(text) == 0) return C;
	TEMPORARY_TEXT(parse);
	WRITE_TO(parse, "%S", text);
	C->parsed_from = Str::duplicate(parse);
	Str::trim_white_space(parse);
	if ((Str::get_first_char(parse) == '(') && (Str::get_last_char(parse) == ')')) {
		Str::delete_first_character(parse);
		Str::delete_last_character(parse);
		Str::trim_white_space(parse);
	}
	LOOP_THROUGH_TEXT(pos, parse)
		Str::put(pos, Characters::tolower(Str::get(pos)));

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

	if (Regexp::match(&mr, parse, L"(%c+) only")) {
		Str::clear(parse);
		WRITE_TO(parse, "%S", mr.exp[0]);
		Str::trim_white_space(parse);
		if (negated) incorrect = TRUE; /* "not for 32d only" */
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

typedef struct compat_parser_state {
	compatibility_specification *C;
	text_stream *current_family;
	int version_allowed;
	int version_required;
	int family_used;
} compat_parser_state;

int Compatibility::clause(compatibility_specification *C, text_stream *text) {
	int correct = TRUE;
	match_results mr = Regexp::create_mr();

	compat_parser_state cps;
	cps.C = C; cps.version_allowed = FALSE; cps.version_required = FALSE;
	cps.current_family = NULL; cps.family_used = FALSE;

	while (Regexp::match(&mr, text, L"(%C+) (%c+)")) {
		int comma = FALSE;
		if (Str::get_last_char(mr.exp[0]) == ',') {
			comma = TRUE;
			Str::delete_last_character(mr.exp[0]);
			Str::trim_white_space(mr.exp[0]);
		}
		int with = NOT_APPLICABLE;
		match_results mr2 = Regexp::create_mr();
		if (Regexp::match(&mr2, mr.exp[1], L"with debugging,* *(%c*)")) {
			Str::clear(mr.exp[1]);
			Str::copy(mr.exp[1], mr2.exp[0]);
			with = TRUE;
		} else if (Regexp::match(&mr2, mr.exp[1], L"without debugging,* *(%c*)")) {
			Str::clear(mr.exp[1]);
			Str::copy(mr.exp[1], mr2.exp[0]);
			with = FALSE;
		}
		Regexp::dispose_of(&mr2);
		correct = (correct && Compatibility::word(&cps, mr.exp[0], with));
		if (comma) correct = (correct && Compatibility::word(&cps, I"or", with));
		Str::clear(text); Str::copy(text, mr.exp[1]);
	}
	if (Str::len(text) > 0)
		correct = (correct && Compatibility::word(&cps, text, NOT_APPLICABLE));
	if ((correct) && (cps.family_used == FALSE) && (Str::len(cps.current_family) > 0)) {
		target_vm *VM;
		LOOP_OVER(VM, target_vm)
			if (Str::eq_insensitive(cps.current_family, VM->family_name))
				Compatibility::add(C, VM);
	}

	Regexp::dispose_of(&mr);
	return correct;
}

int Compatibility::word(compat_parser_state *cps, text_stream *word, int with) {
	if (cps->version_allowed) {
		semantic_version_number V = VersionNumbers::from_text(word);
		if (VersionNumbers::is_null(V)) {
			if (cps->version_required) return FALSE;
		} else {
			if (Str::len(cps->current_family) == 0) return FALSE;
			cps->family_used = TRUE;
			target_vm *VM;
			int seen = FALSE;
			LOOP_OVER(VM, target_vm)
				if (Str::eq_insensitive(VM->family_name, cps->current_family)) {
					seen = TRUE;
					if ((VersionNumbers::eq(VM->version, V)) &&
						((with == NOT_APPLICABLE) || (TargetVMs::debug_enabled(VM) == with)))
						Compatibility::add(cps->C, VM);
				}
			cps->version_required = FALSE;
			return seen;
		}
	}

	if (Str::eq_insensitive(word, I"or")) {
		if (with != NOT_APPLICABLE) return FALSE;
		return TRUE;
	}
	if ((Str::eq_insensitive(word, I"version")) ||
		(Str::eq_insensitive(word, I"versions"))) {
		if (with != NOT_APPLICABLE) return FALSE;
		cps->version_required = TRUE;
		cps->version_allowed = TRUE;
		return TRUE;
	}

	cps->version_required = FALSE;
	cps->version_allowed = FALSE;

	int bits = NOT_APPLICABLE;
	if (Str::eq_insensitive(word, I"16-bit")) bits = TRUE;
	if (Str::eq_insensitive(word, I"32-bit")) bits = FALSE;
	if (bits != NOT_APPLICABLE) {
		target_vm *VM;
		LOOP_OVER(VM, target_vm)
			if (TargetVMs::is_16_bit(VM) == bits)
				if ((with == NOT_APPLICABLE) || (TargetVMs::debug_enabled(VM) == with))
					Compatibility::add(cps->C, VM);
		cps->current_family = NULL;
		cps->family_used = FALSE;
		return TRUE;
	}		

	if (with != NOT_APPLICABLE) {
		int seen = FALSE;
		target_vm *VM;
		LOOP_OVER(VM, target_vm)
			if (Str::eq_insensitive(VM->family_name, word)) {
				seen = TRUE;
				if (TargetVMs::debug_enabled(VM) == with)
					Compatibility::add(cps->C, VM);
			}
		cps->current_family = NULL;
		cps->family_used = FALSE;
		return seen;	
	}

	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (Str::eq_insensitive(VM->family_name, word)) {
			cps->current_family = VM->family_name;
			return TRUE;
		}
	return FALSE;
}

int Compatibility::add(compatibility_specification *C, target_vm *VM) {
	int already_there = FALSE;
	target_vm *X;
	LOOP_OVER_LINKED_LIST(X, target_vm, C->exceptions)
		if (VM == X)
			already_there = TRUE;
	if (already_there == FALSE)
		ADD_TO_LINKED_LIST(VM, target_vm, C->exceptions);
	return already_there;
}

int Compatibility::with(compatibility_specification *C, target_vm *VM) {
	if (C == NULL) return FALSE;
	int decision = C->default_allows;
	target_vm *X;
	LOOP_OVER_LINKED_LIST(X, target_vm, C->exceptions)
		if (VM == X)
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
	Compatibility::test_one(OUT, I"for 16-bit with debugging");
	Compatibility::test_one(OUT, I"not for 32-bit");
	Compatibility::test_one(OUT, I"for 16-bit with debugging or 32-bit with debugging");
	Compatibility::test_one(OUT, I"not for 32-bit or 16-bit");
	Compatibility::test_one(OUT, I"for 16-bit with debugging, 32-bit with debugging or 32-bit");
	Compatibility::test_one(OUT, I"not for 16-bit with debugging, 32-bit with debugging or 32-bit");
	Compatibility::test_one(OUT, I"for glulx");
	Compatibility::test_one(OUT, I"for glulx or z-machine version 8");
	Compatibility::test_one(OUT, I"for glulx without debugging");
	Compatibility::test_one(OUT, I"for z-machine version 8");
	Compatibility::test_one(OUT, I"for z-machine version 5 with debugging");
	Compatibility::test_one(OUT, I"for z-machine version 8, or Glulx without debugging");
	Compatibility::test_one(OUT, I"for z-machine version 5 or 8");
}

void Compatibility::test_one(OUTPUT_STREAM, text_stream *test) {
	WRITE("'%S': ", test);
	compatibility_specification *C = Compatibility::from_text(test);
	if (C == NULL) { WRITE("not a valid compatibility specification\n\n"); return; }
	Compatibility::write(OUT, C);
	WRITE(":\n"); INDENT;
	target_vm *VM;
	LOOP_OVER(VM, target_vm) {
		if (Compatibility::with(C, VM)) {
			TargetVMs::write(OUT, VM);
			WRITE("\n");
		}
	}
	OUTDENT; WRITE("\n");
}
