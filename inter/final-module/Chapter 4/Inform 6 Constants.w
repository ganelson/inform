[I6TargetConstants::] Inform 6 Constants.

To declare I6 constants and arrays.

@ =
void I6TargetConstants::create_generator(code_generator *gtr) {
	METHOD_ADD(gtr, DECLARE_CONSTANT_MTID, I6TargetConstants::declare_constant);
	METHOD_ADD(gtr, BEGIN_ARRAY_MTID, I6TargetConstants::begin_array);
	METHOD_ADD(gtr, ARRAY_ENTRY_MTID, I6TargetConstants::array_entry);
	METHOD_ADD(gtr, END_ARRAY_MTID, I6TargetConstants::end_array);
	METHOD_ADD(gtr, NEW_ACTION_MTID, I6TargetConstants::new_action);
	METHOD_ADD(gtr, COMPILE_DICTIONARY_WORD_MTID, I6TargetConstants::compile_dictionary_word);
	METHOD_ADD(gtr, COMPILE_LITERAL_NUMBER_MTID, I6TargetConstants::compile_literal_number);
	METHOD_ADD(gtr, COMPILE_LITERAL_REAL_MTID, I6TargetConstants::compile_literal_real);
	METHOD_ADD(gtr, COMPILE_LITERAL_TEXT_MTID, I6TargetConstants::compile_literal_text);
	METHOD_ADD(gtr, COMPILE_LITERAL_SYMBOL_MTID, I6TargetConstants::compile_literal_symbol);
}

@h Constant values.
Constants are layered by depth, so that if the initial value for |X| depends
on that for |Y| then the declaration for |Y| will always be placed earlier in the
code than that for |X|. See //Code Generation// for how this is done.

=
void I6TargetConstants::declare_constant(code_generator *gtr, code_generation *gen,
	inter_symbol *const_s, int form, text_stream *val) {
	text_stream *const_name = InterSymbol::trans(const_s);
    @<Leave undeclared any array used as a value of a property@>;
	@<Leave undeclared any constant auto-declared by the I6 compiler@>;

	int depth = 1;
	if (const_s) depth = ConstantInstruction::constant_depth(const_s);
	segmentation_pos saved = CodeGen::select_layered(gen, constants_I7CGS, depth);
	text_stream *OUT = CodeGen::current(gen);

	if (Str::eq(const_name, I"Release")) @<Declare the Release constant with a directive@>;
	if (Str::eq(const_name, I"Serial")) @<Declare the Serial constant with a directive@>;

	int ifndef_me = FALSE;
	@<Certain constants should be declared only if I6 has not already declared them@>;
	if (ifndef_me) WRITE("#ifndef %S;\n", const_name);
		WRITE("Constant %S = ", const_name);
		VanillaConstants::definition_value(gen, form, const_s, val);
		WRITE(";\n");
	if (ifndef_me) WRITE("#endif;\n");
	CodeGen::deselect(gen, saved);
}

@ A curious feature of Inform, going back to the original 1970s design of the
Z-machine VM, is that properties of objects can be small arrays rather than
single values. These are, for some reason, called "inline arrays". The I6
generator is going to take advantage of this feature: if it sees that a
property is actually an address of a small array, it will compile that array
directly into the body of the relevant object or class declaration. It therefore
does not need to declare the name of this small array, and so --

@<Leave undeclared any array used as a value of a property@> =
	if (ConstantInstruction::is_inline(const_s))
		return;

@ We cannot declare these constants because they exist automatically, and
declaring them will therefore throw an error message calling them duplicates.
(The initial values these have in the Inter tree are perfectly correct, and on
other targets they will be compiled normally.)

The |FLOAT_*| constants are defined only when I6 compiles to the Glulx VM,
but then, they are only present in the Inter tree when we are headed that way
anyway.

@<Leave undeclared any constant auto-declared by the I6 compiler@> =
	if ((Str::eq(const_name, I"FLOAT_INFINITY")) ||
		(Str::eq(const_name, I"FLOAT_NINFINITY")) ||
		(Str::eq(const_name, I"FLOAT_NAN")) ||
		(Str::eq(const_name, I"nothing")) ||
		(Str::eq(const_name, I"#dict_par1")) ||
		(Str::eq(const_name, I"#dict_par2")))
		return;

@ In addition to those are constants which are only sometimes auto-declared,
depending on, for example, the choice of virtual machine I6 is compiling to.
Some of this goes back to the fact that support for the Glulx VM was a retrofit
to the I6 compiler some years after its original design: there was no need for
a |TARGET_ZCODE| constant back when Z-code was the only code it could make,
for example.

@<Certain constants should be declared only if I6 has not already declared them@> =
	if ((Str::eq(const_name, I"WORDSIZE")) ||
		(Str::eq(const_name, I"TARGET_ZCODE")) ||
		(Str::eq(const_name, I"TARGET_GLULX")) ||
		(Str::eq(const_name, I"DICT_WORD_SIZE")) ||
		(Str::eq(const_name, I"DICT_ENTRY_BYTES")) ||
		(Str::eq(const_name, I"DEBUG")) ||
		(Str::eq(const_name, I"cap_short_name"))) {
		ifndef_me = TRUE;
	}

@ The release number is just another constant integer, but in I6 it has to be
declared with the |Release| directive, so:

@<Declare the Release constant with a directive@> =
	WRITE("Release ");
	VanillaConstants::definition_value(gen, form, const_s, val);
	WRITE(";\n");
	return;

@ Likewise the Serial code (e.g., |"211010"|), which must be a double-quoted
literal:

@<Declare the Serial constant with a directive@> =
	WRITE("Serial ");
	VanillaConstants::definition_value(gen, form, const_s, val);
	WRITE(";\n");
	return;

@h Arrays.
Now for arrays, which we turn into |Verb| or |Array| directives in I6. We will
return |FALSE| in the Verb case to tell Vanilla that the entire array has now
been declared, so it need do nothing further; |TRUE| in the more typical |Array|
case, whereupon Vanilla will lead us through the rest of the declaration.

=
int I6TargetConstants::begin_array(code_generator *gtr, code_generation *gen,
	text_stream *array_name, inter_symbol *array_s, inter_tree_node *P, int format,
	int zero_count, segmentation_pos *saved) {
	if (ConstantInstruction::list_format(P) == CONST_LIST_FORMAT_GRAMMAR) {
		@<Write a complete I6 Verb directive@>;
		return FALSE;
	} else {
		@<Begin an I6 Array directive@>;
		return TRUE;
	}
}

@ Here we hijack a command-verb grammar array entirely. |Verb| directives in I6
have a fruity sort of syntax, using reserved words not found elsewhere, and
punctuation markers like |*| and |->|, and constructs like |scope=F| for functions
|F|, and so on; so it's not really practical to create such directives as if
they were any other arrays. Here goes:

@<Write a complete I6 Verb directive@> =
	if (saved) *saved = CodeGen::select(gen, command_grammar_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Verb");
	int marker = NOT_APPLICABLE;
	for (int i=0; i<ConstantInstruction::list_len(P); i++) {
		WRITE(" ");
		inter_pair val = ConstantInstruction::list_entry(P, i);
		if (InterValuePairs::is_symbolic(val)) {
			inter_symbol *A = InterValuePairs::to_symbol_at(val, P);
			if (A == NULL) internal_error("bad aliased symbol");
			text_stream *S = InterSymbol::trans(A);
			     if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_meta_RPSYM))        WRITE("meta");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_divider_RPSYM))     WRITE("\n\t*");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_reverse_RPSYM))     WRITE("reverse");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_slash_RPSYM))       WRITE("/");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_result_RPSYM))      WRITE("->");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_special_RPSYM))     WRITE("special");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_number_RPSYM))      WRITE("number");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_noun_RPSYM))        WRITE("noun");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_multi_RPSYM))       WRITE("multi");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_multiinside_RPSYM)) WRITE("multiinside");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_multiheld_RPSYM))   WRITE("multiheld");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_held_RPSYM))        WRITE("held");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_creature_RPSYM))    WRITE("creature");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_topic_RPSYM))       WRITE("topic");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_multiexcept_RPSYM)) WRITE("multiexcept");
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_noun_filter_RPSYM)) marker = TRUE;
			else if (A == RunningPipelines::get_symbol(gen->from_step, verb_directive_scope_filter_RPSYM)) marker = FALSE;
			else if (Str::begins_with_wide_string(S, U"##")) @<Write without sharps@>
			else {
				if (marker == FALSE) WRITE("scope=");
				if (marker == TRUE)  WRITE("noun=");
				I6TargetConstants::compile_literal_symbol(gtr, gen, A);
				marker = NOT_APPLICABLE;
			}
		} else {
			CodeGen::pair(gen, P, val);
		}
	}
	WRITE(";\n");

@ When an action is named in a |Verb| directive, it appears without its |##| prefix;
so the following ensures that we write, say,
= (text as Inform 6)
	Verb 'help' * -> Help;
=
rather than
= (text as Inform 6)
	Verb 'help' * -> ##Help;
=
which would be a more consistent design, but is a syntax error in I6.

@<Write without sharps@> =
	LOOP_THROUGH_TEXT(pos, S)
		if (pos.index >= 2)
			PUT(Str::get(pos));

@ Enough of verbs. A general array is more straightforward, except for a quirk
(read: blunder) in I6 syntax. In I6,
= (text as Inform 6)
	Array X table 10 20 30;
=
makes a table array with three entries, so that |X| ends up as a pointer to a
block of four words in memory: |3, 10, 20, 30|. However,
= (text as Inform 6)
	Array X table 10;
=
makes a table with 10 entries, initially zeroes, so that |X| points to the
block |10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0|. We do not want this: there are times
when we genuinely need a 1-entry table array. So we use the alternate syntax,
provided by Inform 6 since at least 2000 but for some reason not documented in
the DM4:
= (text as Inform 6)
	Array X table [ 10 ];
=

@<Begin an I6 Array directive@> =
	if (saved) *saved = CodeGen::select(gen, arrays_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Array %S ", array_name);
	switch (format) {
		case WORD_ARRAY_FORMAT: WRITE("-->"); break;
		case BYTE_ARRAY_FORMAT: WRITE("->"); break;
		case TABLE_ARRAY_FORMAT: WRITE("table"); break;
		case BUFFER_ARRAY_FORMAT: WRITE("buffer"); break;
	}
	if (zero_count >= 0) {
		WRITE(" %d", zero_count);
	} else {
	    WRITE(" [");
	}

@ A further quirk (again, blunder) is that I6 has no delimiter syntax to mark
off one entry from the next -- in most languages, such as C, a comma would be
used, but I6 uses only white space.

That's fine until entries begin with operators which are ambiguously unary
or binary -- in other words, with minus signs. In I6, this:
= (text as Inform 6)
	Array X --> [ 2 4 -5 ];
=
makes a two-element array, with |X| pointing to |2, -1|, because |4 -5| is
read as a binary operation (subtraction), not as 4 followed by a unary
operation (negation) applied to 5.

We avoid this by placing semicolons after every entry, just in case:
= (text as Inform 6)
	Array X --> [ 2; 4; -5; ];
=
Again, though undocumented in the DM4, this is a long-established syntax in I6.

=
void I6TargetConstants::array_entry(code_generator *gtr, code_generation *gen,
	text_stream *entry, int format) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(" %S;", entry);
}

void I6TargetConstants::end_array(code_generator *gtr, code_generation *gen, int format,
	int zero_count, segmentation_pos *saved) {
	text_stream *OUT = CodeGen::current(gen);
	if (zero_count < 0) WRITE(" ];\n");
	else WRITE("; ! blank with extent %d\n", zero_count);
	if (saved) CodeGen::deselect(gen, *saved);
}

@h Actions.
In I6, actions are implicitly created when they are used in command-grammar
syntax (i.e. in |Verb| directives); so if |true_action| is set, we do nothing.

Fake actions, where |true_action| is not set, are those which are valid actions
in principle but which never occur in any command grammar. It follows that these
must be explicitly declared, which we do with the I6 |Fake_Action| directive:

=
void I6TargetConstants::new_action(code_generator *gtr, code_generation *gen,
	text_stream *name, int true_action, int N) {
	if (true_action == FALSE) {
		segmentation_pos saved = CodeGen::select(gen, fake_actions_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("Fake_Action %S;\n", name);
		CodeGen::deselect(gen, saved);
	}
}

@h Literals.
Integer literals are written in the obvious way. In hexadecimal, I6 uses a
single |$| prefix. Real literals also begin with a |$|, but then continue with
a real-number notation including a decimal point. The same notation is used
by Inter, so we need do nothing to modify it here.

=
void I6TargetConstants::compile_literal_number(code_generator *gtr,
	code_generation *gen, inter_ti val, int hex_mode) {
	text_stream *OUT = CodeGen::current(gen);
	if (hex_mode) WRITE("$%x", val);
	else WRITE("%d", val);
}

void I6TargetConstants::compile_literal_real(code_generator *gtr,
	code_generation *gen, text_stream *textual) {
	text_stream *OUT = CodeGen::current(gen);
	if ((Str::get_first_char(textual) != '-') && (Str::get_first_char(textual) != '+'))
		WRITE("$+%S", textual);
	else
		WRITE("$%S", textual);
}

@ Dictionary words -- those used in the command parser grammar -- are written in
single quotation marks and have their own peculiar syntax: see the Inform
Designer's Manual, 4th edition, for more. In particular note that we compile
a one-character dword to, say, |'z//'| not |'z'|: the double-slash is meaningless
there, but distinguishes this from the character constant |'z'|, which evaluates
to the ZSCII code for lower-case Z.

=
void I6TargetConstants::compile_dictionary_word(code_generator *gtr, code_generation *gen,
	text_stream *S, int pluralise) {
	text_stream *OUT = CodeGen::current(gen);
	int n = 0;
	WRITE("'");
	LOOP_THROUGH_TEXT(pos, S) {
		inchar32_t c = Str::get(pos);
		if (c >= 0x100) WRITE("@{%04x}", c);
		else {
			switch(c) {
				case '/': if (Str::len(S) == 1) WRITE("@{2F}"); else WRITE("/"); break;
				case '\'': WRITE("^"); break;
				case '^': WRITE("@{5E}"); break;
				case '~': WRITE("@{7E}"); break;
				case '@': WRITE("@{40}"); break;
				default: PUT(c);
			}
		}
		if ((TargetVMs::is_16_bit(gen->for_VM)) && (n++ > 32)) break;
	}
	if (pluralise) WRITE("//p");
	else if (Str::len(S) == 1) WRITE("//");
	WRITE("'");
}

@ Literal texts, written in double quotation marks, are more of a slog to get
right, and have subtly different escape-character syntax: again, see the DM4.

Note that the |PRINTING_LTM| literal text mode is enabled when the following
is used for text appearing in an I6 |print| statement, rather than as an I6
value.

The |BOX_LTM| mode is used for quotation text appearing in the I6 |box| statement.

If you think it surprising that the escape characters would need to use
different syntaxes in these three cases, I won't argue.

=
void I6TargetConstants::compile_literal_text(code_generator *gtr, code_generation *gen,
	text_stream *S, int escape_mode) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("\"");
	if (escape_mode == FALSE) {
		WRITE("%S", S);
	} else if (gen->literal_text_mode == BOX_LTM) {
		@<Compile literal text in box mode@>;
	} else if (gen->literal_text_mode == PRINTING_LTM) {
		@<Compile literal text in print-statement mode@>;
	} else {
		@<Compile literal text in value mode@>;
	}
	WRITE("\"");
}

@ Box mode and value mode are the same except for their handling of newlines.
Note that the two-digit hex values in braces are the ASCII values of the
characters being written.

@<Compile literal text in box mode@> =
	LOOP_THROUGH_TEXT(pos, S) {
		inchar32_t c = Str::get(pos);
		if (c >= 0x100) WRITE("@{%04x}", c);
		else {
			switch(c) {
				case '@': WRITE("@{40}"); break;
				case '"': WRITE("~"); break;
				case '^': WRITE("@{5E}"); break;
				case '~': WRITE("@{7E}"); break;
				case '\\': WRITE("@{5C}"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("\"\n\""); break;
				case NEWLINE_IN_STRING: WRITE("\"\n\""); break;
				default: PUT(c);
			}
		}
	}

@<Compile literal text in value mode@> =
	LOOP_THROUGH_TEXT(pos, S) {
		inchar32_t c = Str::get(pos);
		if (c >= 0x100) WRITE("@{%04x}", c);
		else {
			switch(c) {
				case '@': WRITE("@{40}"); break;
				case '"': WRITE("~"); break;
				case '^': WRITE("@{5E}"); break;
				case '~': WRITE("@{7E}"); break;
				case '\\': WRITE("@{5C}"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("^"); break;
				case NEWLINE_IN_STRING: WRITE("^"); break;
				default: PUT(c);
			}
		}
	}

@ Print mode is like value mode except that, for obscure implementation reasons
inside the I6 compiler, |@{40}|, |@{5E}| and |@{7E}| cannot be used to escape
those character codes, and instead the |@@| decimal notation has to be used
instead. But that can take a decimal value of arbitrary length and has no
brace delimiters; so we must be careful not to encode |^1| as |"@@941"| because
that would ask for character 941, not for character 94 and then a |1|. Instead
we encode it as |"@@94@{31}"|, since the ASCII code for a digit 1 is 31 in
hexadecimal.

@<Compile literal text in print-statement mode@> =
	int esc_char = FALSE;
	LOOP_THROUGH_TEXT(pos, S) {
		inchar32_t c = Str::get(pos);
		if (c >= 0x100) WRITE("@{%04x}", c);
		else {
			switch(c) {
				case '@': WRITE("@@64"); esc_char = TRUE; continue;
				case '"': WRITE("~"); break;
				case '^': WRITE("@@94"); esc_char = TRUE; continue;
				case '~': WRITE("@@126"); esc_char = TRUE; continue;
				case '\\': WRITE("@{5C}"); break;
				case '\t': WRITE(" "); break;
				case '\n': WRITE("^"); break;
				case NEWLINE_IN_STRING: WRITE("^"); break;
				default: {
					if (esc_char) WRITE("@{%02x}", c);
					else PUT(c);
				}
			}
		}
		esc_char = FALSE;
	}

@ Finally, names of constants are compiled just as themselves:

=
void I6TargetConstants::compile_literal_symbol(code_generator *gtr, code_generation *gen,
	inter_symbol *A) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("%S", InterSymbol::trans(A));
}
