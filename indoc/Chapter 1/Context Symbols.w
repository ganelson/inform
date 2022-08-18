[Symbols::] Context Symbols.

Provides conditional rendering of text, depending on context.

@h About symbols.
Documentation is allowed to contain rawtext which varies depending on the
context: on what platform it's being written for, or what format it is
being rendered to, for example. The context is defined by which symbol
names have been defined.

Symbols are C-like identifiers (alphanumeric or underscored). The symbol has
been declared if and only if it is an existing key for the following hash,
and the associated value is "y".

=
dictionary *defined_symbols = NULL;

@h Starting up.
The symbol |indoc| is always defined, so that, in theory, other programs
working on rawtext can distinguish themselves from us (by not defining it).
For example,
= (text as Indoc)
	{^indoc:}You'll probably never see this paragraph.
=
provides rawtext visible only if |indoc| isn't the renderer.

=
void Symbols::start_up_symbols(void) {
	Symbols::declare_symbol(I"indoc");
}

@h Making and unmaking.

=
void Symbols::declare_symbol(text_stream *symbol) {
	if (defined_symbols == NULL) defined_symbols = Dictionaries::new(10, TRUE);
	text_stream *entry = Dictionaries::create_text(defined_symbols, symbol);
	Str::copy(entry, I"y");
	LOGIF(SYMBOLS, "Declaring <%S>\n", symbol);
}

void Symbols::undeclare_symbol(text_stream *symbol) {
	text_stream *entry = Dictionaries::get_text(defined_symbols, symbol);
	if (entry == NULL) return;
	Str::copy(entry, I"n");
	LOGIF(SYMBOLS, "Undeclaring <%S>\n", symbol);
}

@h Testing.
This returns 1 if the current context matches the condition given, and 0
otherwise.

=
int Symbols::perform_ifdef(text_stream *cond) {
	for (int i=0, L=Str::len(cond); i<L; i++) {
		int c = Str::get_at(cond, i);
		if (Characters::is_whitespace(c)) {
			Str::delete_nth_character(cond, i);
			i--; L--;
		}
	}
	int v = Symbols::perform_ifdef_inner(cond);
 	LOGIF(SYMBOLS, "Ifdef <%S> --> %s\n", cond, v?"yes":"no");
	return v;
}

@ There is an expression grammar here, which we apply correctly if the
condition is well-formed; if it's a mess, we try to return 0, but don't go
to any trouble to report errors.

Any condition can be bracketed; otherwise we have the unary operator |^|
(negation), the binary |+| (conjunction), and binary |,| (disjunction),
which associate in that order. An atomic condition is true if and only if
it is a declared symbol. So for example

	^alpha,beta+gamma

is true if either alpha is undeclared, or if both beta and gamma are declared.
Whereas

	^(alpha,beta)+gamma
	^alpha+^beta+gamma

are both true if alpha and beta are undeclared but gamma is declared.

=
int Symbols::perform_ifdef_inner(text_stream *cond) {
 	@<Subexpressions can be bracketed@>;
 	@<The comma operator is left-associative and means or@>;
 	@<The plus operator is left-associative and means and@>;
 	@<The caret operator is unary and means not@>;
 	@<A bare symbol name is true if and only if it is declared@>;

 	@<The expression is malformed@>;
}

@<Subexpressions can be bracketed@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, cond, L"%((%c*)%)")) {
		int rv = Symbols::perform_ifdef(mr.exp[0]);
		Regexp::dispose_of(&mr);
		return rv;
	}

@<The comma operator is left-associative and means or@> =
	int k = Symbols::find_operator(cond, ',');
 	if (k >= 0) {
 		TEMPORARY_TEXT(L)
 		TEMPORARY_TEXT(R)
 		Str::copy(L, cond);
 		Str::truncate(L, k);
 		Str::copy_tail(R, cond, k+1);
 		int rv = ((Symbols::perform_ifdef(L)) || (Symbols::perform_ifdef(R)));
 		DISCARD_TEXT(L)
 		DISCARD_TEXT(R)
 		return rv;
 	} else if (k == -2) @<The expression is malformed@>;

@<The plus operator is left-associative and means and@> =
	int k = Symbols::find_operator(cond, '+');
 	if (k >= 0) {
		TEMPORARY_TEXT(L)
 		TEMPORARY_TEXT(R)
 		Str::copy(L, cond);
 		Str::truncate(L, k);
 		Str::copy_tail(R, cond, k+1);
 		int rv = ((Symbols::perform_ifdef(L)) && (Symbols::perform_ifdef(R)));
 		DISCARD_TEXT(L)
 		DISCARD_TEXT(R)
 		return rv;
 	} else if (k == -2) @<The expression is malformed@>;

@<The caret operator is unary and means not@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, cond, L"%^(%c*)")) {
		int rv = Symbols::perform_ifdef(mr.exp[0]);
		Regexp::dispose_of(&mr);
		return rv?FALSE:TRUE;
	}

@<A bare symbol name is true if and only if it is declared@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, cond, L"%i+")) {
		Regexp::dispose_of(&mr);
		text_stream *entry = Dictionaries::get_text(defined_symbols, cond);
		if (Str::eq_wide_string(entry, L"y")) return TRUE;
		return FALSE;
	}

@<The expression is malformed@> =
	Errors::with_text("malformed condition: %S", cond); return 0;

@ The following looks for a single character |op| in any unbracketed interior
parts of the text |cond|, and looks out for mismatched brackets on the way.

=
int Symbols::find_operator(text_stream *cond, int op) {
	int bl = 0;
	for (int k = 0, L = Str::len(cond); k < L; k++) {
		int ch = Str::get_at(cond, k);
		if (ch == '(') bl++;
		if (ch == ')') bl--;
 		if (bl < 0) return -2; /* Too many close brackets */
 		if ((bl == 0) && (k > 0) && (k < L - 1) && (ch == op)) {
 			return k;
		}
	}
	if (bl != 0) return -2; /* Too many open brackets */
	return -1; /* Not found */
}
