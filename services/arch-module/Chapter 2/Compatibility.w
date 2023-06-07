[Compatibility::] Compatibility.

To manage specifications of compatibility with some VMs but not others.

@h Specifications.
An object of the following class can represent any subset of VMs, so
it's a fully general way to express which VMs some piece of software works with:

=
typedef struct compatibility_specification {
	struct text_stream *parsed_from; /* if it came from text */
	int default_allows;
	struct linked_list *exceptions; /* of |target_vm| */
	CLASS_DEFINITION
} compatibility_specification;

@ The creator function for this always begins with a specification meaning
"works with all VMs":

=
compatibility_specification *Compatibility::all(void) {
	compatibility_specification *C = CREATE(compatibility_specification);
	C->parsed_from = NULL;
	C->default_allows = TRUE;
	C->exceptions = NEW_LINKED_LIST(target_vm);
	return C;
}

@ We can then change this in two ways: one is to reverse the default...

=
void Compatibility::reverse(compatibility_specification *C) {
	C->default_allows = (C->default_allows)?FALSE:TRUE;
}

@ ...and the other is to add an exception:

=
int Compatibility::add_exception(compatibility_specification *C, target_vm *VM) {
	int already_there = FALSE;
	target_vm *X;
	LOOP_OVER_LINKED_LIST(X, target_vm, C->exceptions)
		if (VM == X)
			already_there = TRUE;
	if (already_there == FALSE)
		ADD_TO_LINKED_LIST(VM, target_vm, C->exceptions);
	return already_there;
}

@h Converting to text.
This often produces something verbose; the |parsed_from| text probably reads
better, if available.

=
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
	
@h Converting from text.
This is quite a tricky little parser, which has to read, for example,
text like "for Glulx only" used in Inform extension headings. A syntactically
invalid description returns |NULL| but prints no error message; an empty
description returns the universally valid specification.

A question we might return to is whether an unrecognisable description --
say, "for Marzipan version 28.1 only" -- should return a universally-false
specification rather than returning |NULL|: this would enable current Inform
tools to work with future resources which use VMs currently unthought of.
But for now, it seems best to generate errors, because the more likely thing
is that an extension author is botching the wording of something, or
writing "Z machine" instead of "Z-machine", or something like that.

It might seem better to all of this with a Preform grammar, rather than by
hand. But we want to make it work in tools which don't have Preform available,
and we want it to run quickly.

Unless the text is empty, we start with the "works with nothing" specification
and then add each VM with which |C| does work as an exception.

=	
compatibility_specification *Compatibility::from_text(text_stream *text) {
	compatibility_specification *C = Compatibility::all();
	C->parsed_from = Str::duplicate(text);
	if (Str::len(text) == 0) return C;
	Compatibility::reverse(C); /* now |C| works with nothing */
	int error_in_syntax = FALSE;

	match_results mr = Regexp::create_mr();
	TEMPORARY_TEXT(parse)
	WRITE_TO(parse, "%S", text);
	@<Remove excess space and/or enclosing brackets and lower in case@>;
	@<Actually parse the description@>;
	DISCARD_TEXT(parse)
	Regexp::dispose_of(&mr);

	return (error_in_syntax)?NULL:C;
}

@<Remove excess space and/or enclosing brackets and lower in case@> =
	Str::trim_white_space(parse);
	if ((Str::get_first_char(parse) == '(') && (Str::get_last_char(parse) == ')')) {
		Str::delete_first_character(parse);
		Str::delete_last_character(parse);
		Str::trim_white_space(parse);
	}
	LOOP_THROUGH_TEXT(pos, parse)
		Str::put(pos, Characters::tolower(Str::get(pos)));

@<Actually parse the description@> =
	int negated = FALSE;
	@<Parse out the prefix not@>;
	@<Remove the meaningless word for@>;
	@<Parse out the suffix only@>;
	if (Str::eq(parse, I"all")) {
		if (negated) error_in_syntax = TRUE; /* "not for all" */
		C->default_allows = TRUE;
	} else if (Str::eq(parse, I"none")) {
		if (negated) error_in_syntax = TRUE; /* "not for none" */
		C->default_allows = FALSE;
	} else if (Compatibility::parse_specifics(C, parse) == FALSE)
		error_in_syntax = TRUE;

@<Parse out the prefix not@> =
	if (Regexp::match(&mr, parse, L"not (%c+)")) {
		Str::clear(parse);
		WRITE_TO(parse, "%S", mr.exp[0]);
		Str::trim_white_space(parse);
		Compatibility::reverse(C);
		negated = TRUE;
	}

@<Remove the meaningless word for@> =
	if (Regexp::match(&mr, parse, L"for (%c+)")) {
		Str::clear(parse);
		WRITE_TO(parse, "%S", mr.exp[0]);
		Str::trim_white_space(parse);
	}

@<Parse out the suffix only@> =
	if (Regexp::match(&mr, parse, L"(%c+) only")) {
		Str::clear(parse);
		WRITE_TO(parse, "%S", mr.exp[0]);
		Str::trim_white_space(parse);
		if (negated) error_in_syntax = TRUE; /* "not for 32d only" */
	}

@ The above gets us down from, say, "for Glulx only" to just "Glulx", and
calls the function //Compatibility::parse_specifics// to handle that specific part --
though it may be more complicated. See the //arch-test// unit test for
examples. While parsing those specifics we maintain a state in the following
structure:

=
typedef struct compat_parser_state {
	compatibility_specification *C;
	text_stream *current_family;
	int version_allowed;
	int version_required;
	int family_used;
} compat_parser_state;

compat_parser_state Compatibility::initial_state(compatibility_specification *C) {
	compat_parser_state cps;
	cps.C = C; cps.version_allowed = FALSE; cps.version_required = FALSE;
	cps.current_family = NULL; cps.family_used = FALSE;
	return cps;
}

@ So here's the specific details parser, then. We return |TRUE| if no syntax
errors occurred, and we change |C| according to what |text| says.

=
int Compatibility::parse_specifics(compatibility_specification *C, text_stream *text) {
	int okay = TRUE;
	match_results mr = Regexp::create_mr();

	compat_parser_state cps = Compatibility::initial_state(C);
	@<Reduce the text to a sequence of tokens@>;

	Regexp::dispose_of(&mr);
	return okay;
}

@ This is essentially simple -- it splits up text like "Z-machine versions 5 or 8"
into tokens, sending them one at a time to //Compatibility::parse_token//.
Note that commas are converted to the token |or|: e.g., "Z-machine versions 5, 6
or 8" would be treated as "Z-machine versions 5 or 6 or 8"; and note also that
"with debugging" and "without debugging" are handled specially.

We end the sequence of tokens with a |NULL|, telling the token-parser that
it has reached the end.

@<Reduce the text to a sequence of tokens@> =
	while (Regexp::match(&mr, text, L"(%C+) (%c+)")) {
		int comma = FALSE;
		if (Str::get_last_char(mr.exp[0]) == ',') {
			comma = TRUE;
			Str::delete_last_character(mr.exp[0]);
			Str::trim_white_space(mr.exp[0]);
		}
		int with = Compatibility::parse_debugging(mr.exp[1]);
		okay = (okay && Compatibility::parse_token(&cps, mr.exp[0], with));
		if (comma) okay = (okay && Compatibility::parse_token(&cps, I"or", with));
		Str::clear(text); Str::copy(text, mr.exp[1]);
	}
	if (Str::len(text) > 0)
		okay = (okay && Compatibility::parse_token(&cps, text, NOT_APPLICABLE));
	okay = (okay && Compatibility::parse_token(&cps, NULL, NOT_APPLICABLE));

@ Returns |TRUE| if the text |T| begins "with debugging", and trims that text
away from |T|; returns |FALSE| if it begins "without debugging", and similarly
trims; and otherwise returns |NOT_APPLICABLE| and leaves |T| unaltered.

=
int Compatibility::parse_debugging(text_stream *T) {
	int with = NOT_APPLICABLE;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, T, L"with debugging,* *(%c*)")) {
		Str::clear(T);
		Str::copy(T, mr.exp[0]);
		with = TRUE;
	} else if (Regexp::match(&mr, T, L"without debugging,* *(%c*)")) {
		Str::clear(T);
		Str::copy(T, mr.exp[0]);
		with = FALSE;
	}
	Regexp::dispose_of(&mr);
	return with;
}

@ Once again we return |TRUE| if no syntax errors occurred, and we change |C|
according to what the |token| says.

=
int Compatibility::parse_token(compat_parser_state *cps, text_stream *token, int with) {
	if (Str::len(token) == 0) @<Construe the token as the end-marker@>;

	if (cps->version_allowed) {
		semantic_version_number V = VersionNumbers::from_text(token);
		if (VersionNumbers::is_null(V)) {
			if (cps->version_required) return FALSE;
		} else {
			if (Str::len(cps->current_family) == 0) return FALSE;
			@<Construe token as a version number@>;
		}
	}

	if (Str::eq_insensitive(token, I"or")) {
		if (with != NOT_APPLICABLE) return FALSE;
		return TRUE;
	}
	if ((Str::eq_insensitive(token, I"version")) ||
		(Str::eq_insensitive(token, I"versions"))) {
		if (with != NOT_APPLICABLE) return FALSE;
		cps->version_required = TRUE;
		cps->version_allowed = TRUE;
		return TRUE;
	}

	cps->version_required = FALSE;
	cps->version_allowed = FALSE;

	int bits = NOT_APPLICABLE;
	if (Str::eq_insensitive(token, I"16-bit")) bits = TRUE;
	if (Str::eq_insensitive(token, I"z-machine")) bits = TRUE;
	if (Str::eq_insensitive(token, I"32-bit")) bits = FALSE;
	if (Str::eq_insensitive(token, I"glulx")) bits = FALSE;
	if (bits != NOT_APPLICABLE) @<Construe token as a bit count@>;

	if (with != NOT_APPLICABLE) @<Construe token as a family name subject to debugging@>;

	@<Construe token as a family name@>;
}

@<Construe token as a version number@> =
	cps->family_used = TRUE;
	target_vm *VM;
	int seen = FALSE;
	LOOP_OVER(VM, target_vm)
		if (TargetVMs::compatible_with(VM, cps->current_family)) {
			seen = TRUE;
			if ((VersionNumbers::eq(VM->version, V)) &&
				((with == NOT_APPLICABLE) || (TargetVMs::debug_enabled(VM) == with)))
				Compatibility::add_exception(cps->C, VM);
		}
	cps->version_required = FALSE;
	return seen;

@<Construe token as a bit count@> =
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (TargetVMs::is_16_bit(VM) == bits)
			if ((with == NOT_APPLICABLE) || (TargetVMs::debug_enabled(VM) == with))
				Compatibility::add_exception(cps->C, VM);
	cps->current_family = NULL;
	cps->family_used = FALSE;
	return TRUE;

@<Construe token as a family name subject to debugging@> =
	int seen = FALSE;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (TargetVMs::compatible_with(VM, token)) {
			seen = TRUE;
			if (TargetVMs::debug_enabled(VM) == with)
				Compatibility::add_exception(cps->C, VM);
		}
	cps->current_family = NULL;
	cps->family_used = FALSE;
	return seen;	

@<Construe token as a family name@> =
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (TargetVMs::compatible_with(VM, token)) {
			cps->current_family = TargetVMs::family(VM);
			return TRUE;
		}
	return FALSE;

@<Construe the token as the end-marker@> =
	if ((cps->family_used == FALSE) && (Str::len(cps->current_family) > 0)) {
		target_vm *VM;
		LOOP_OVER(VM, target_vm)
			if (TargetVMs::compatible_with(VM, cps->current_family))
				Compatibility::add_exception(cps->C, VM);
	}
	return TRUE;

@h Testing.

=
int Compatibility::test(compatibility_specification *C, target_vm *VM) {
	if (C == NULL) return FALSE;
	int decision = C->default_allows;
	target_vm *X;
	LOOP_OVER_LINKED_LIST(X, target_vm, C->exceptions)
		if (VM == X)
			decision = decision?FALSE:TRUE;
	return decision;
}

int Compatibility::test_universal(compatibility_specification *C) {
	if (C == NULL) return FALSE;
	if (LinkedLists::len(C->exceptions) > 0) return FALSE;
	if (C->default_allows == FALSE) return FALSE;
	return TRUE;
}

@ This tests whether at least one VM of the given architecture is compatible.

=
int Compatibility::test_architecture(compatibility_specification *C, inter_architecture *A) {
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Compatibility::test(C, VM)) && (TargetVMs::has_architecture(VM, A)))
			return TRUE;
	return FALSE;
}
