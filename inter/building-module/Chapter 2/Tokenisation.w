[Tokenisation::] Tokenisation.

Turning textual code written in Inform 6 syntax into a linked list of tokens.

@ Our method is to tokenise the source code as if it were Inform 6, but to look
out for the two extra syntaxes allowed, |{-bracing}| and |(+ Inform 7 interpolation +)|.

@e NO_TOKSTATE from 1
@e COMMENT_TOKSTATE			/* currently scanning an I6 comment |! ...| */
@e DQUOTED_TOKSTATE
@e SQUOTED_TOKSTATE
@e WHITE_TOKSTATE
@e TOK_TOKSTATE				/* an actual token */

=
void Tokenisation::go(inter_schema *sch, text_stream *from, int abbreviated,
	int no_quoted_inames, void **quoted_inames) {
	inter_schema_token *preceding_token = NULL;

	int definition_length = Str::len(from);
	text_stream *current_raw = Str::new();
	int tokeniser_state = NO_TOKSTATE;
	int pos = 0;
	if ((abbreviated) && (Str::begins_with_wide_string(from, L"*=-"))) {
		sch->dereference_mode = TRUE; pos = 3;
	}
	for (; pos<definition_length; pos++) {
		int c = Str::get_at(from, pos);
		if (Characters::is_whitespace(c)) {
			if ((tokeniser_state == TOK_TOKSTATE) || (tokeniser_state == NO_TOKSTATE)) {
				@<Absorb raw material, if any@>;
				tokeniser_state = WHITE_TOKSTATE;
				PUT_TO(current_raw, ' ');
			}
		} else {
			if (tokeniser_state == WHITE_TOKSTATE) {
				@<Absorb raw material, if any@>;
				tokeniser_state = NO_TOKSTATE;
			}
		}

		switch (tokeniser_state) {
			 case DQUOTED_TOKSTATE:
			 	if (c == '"') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = NO_TOKSTATE;
			 	} else {
				 	PUT_TO(current_raw, c);
				}
			 	break;
			 case SQUOTED_TOKSTATE:
			 	if (c == '\'') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = NO_TOKSTATE;
			 	} else {
				 	PUT_TO(current_raw, c);
				}
			 	break;
			 case COMMENT_TOKSTATE:
			 	if (c == '\n') tokeniser_state = NO_TOKSTATE;
			 	break;
			 case WHITE_TOKSTATE: break;
			 default:
			 	if (c == '!') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = COMMENT_TOKSTATE; break;
			 	}
			 	if (c == '"') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = DQUOTED_TOKSTATE; break;
			 	}
			 	if (c == '\'') {
			 		@<Absorb raw material, if any@>;
			 		tokeniser_state = SQUOTED_TOKSTATE; break;
			 	}
				if ((c == '{') && (abbreviated == FALSE))
					@<Look for a possible bracing@>
				else if ((c == '*') && (abbreviated == TRUE))
					@<Look for a possible abbreviated command@>
				else if ((c == '(') && (Str::get_at(from, pos+1) == '+') && (abbreviated == FALSE))
					@<Look for a possible Inform 7 fragment@>
				else @<Absorb a raw character@>;
				break;
		}
	}
	@<Absorb raw material, if any@>;
}

@<Absorb a raw character@> =
	tokeniser_state = TOK_TOKSTATE;
	PUT_TO(current_raw, c);

@<Absorb raw material, if any@> =
	if (Str::len(current_raw)) {
		switch (tokeniser_state) {
			case WHITE_TOKSTATE:
				InterSchemas::add_token(sch, InterSchemas::new_token(WHITE_SPACE_ISTT, I" ", 0, 0, -1));
				break;
			case DQUOTED_TOKSTATE:
				Tokenisation::de_escape_text(current_raw);
				InterSchemas::add_token(sch, InterSchemas::new_token(DQUOTED_ISTT, current_raw, 0, 0, -1));
				break;
			case SQUOTED_TOKSTATE:
				InterSchemas::add_token(sch, InterSchemas::new_token(SQUOTED_ISTT, current_raw, 0, 0, -1));
				break;
			default:
				@<Look for individual tokens@>;
				break;
		}
		Str::clear(current_raw);
	}
	tokeniser_state = NO_TOKSTATE;

@ Material in |(+ ... +)| notation is an interpolation of I7 source text.

@<Look for a possible Inform 7 fragment@> =
	int save_pos = pos, accept = FALSE;
	TEMPORARY_TEXT(source_text_fragment)
	pos += 2;
	while (Str::get_at(from, pos)) {
		if ((Str::get_at(from, pos-1) == '+') && (Str::get_at(from, pos) == ')')) {
			Str::delete_last_character(source_text_fragment);
			accept = TRUE; break;
		}
		PUT_TO(source_text_fragment, Str::get_at(from, pos++));
	}
	if (accept) {
		@<Absorb raw material, if any@>;
		@<Expand a fragment of Inform 7 text@>;
	} else { int c = '('; @<Absorb a raw character@>; pos = save_pos; }
	DISCARD_TEXT(source_text_fragment)

@ The empty I7 interpolation is legal, but produces no result.

@<Expand a fragment of Inform 7 text@> =
	if (Str::len(source_text_fragment) > 0) {
		InterSchemas::add_token(sch, InterSchemas::new_token(I7_ISTT, source_text_fragment, 0, 0, -1));
	}

@ Material in braces sometimes indicates an inline command, but not always,
because braces often occur innocently in I6 code. So we require the first
character after the open-brace not to be white-space, and also not to be
a pipe (though I've forgotten why). The text inside the braces is called
a "bracing".

@<Look for a possible bracing@> =
	int save_pos = pos++, accept = FALSE;
	TEMPORARY_TEXT(bracing)
	while (TRUE) {
		int c = Str::get_at(from, pos);
		if (c == 0) break;
		if (c == '}') { accept = TRUE; break; }
		PUT_TO(bracing, c);
		pos++;
	}
	int first = Str::get_first_char(bracing);
	if ((accept) && (first != ' ') && (first != '\t') && (first != '\n') && (first != '|')) {
		@<Absorb raw material, if any@>;
		@<Parse a bracing into an inline command@>;
	} else { int c = '{'; @<Absorb a raw character@>; pos = save_pos; }
	DISCARD_TEXT(bracing)

@ That's everything, then, except the one thing that counts: how to expand
a bracing.

@<Parse a bracing into an inline command@> =
	inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, bracing, 0, 0, -1);
	t->bracing = Str::duplicate(bracing);
	t->command = Str::new();
	t->operand = Str::new();
	t->operand2 = Str::new();
	@<Decompose the bracing@>;
	if (Str::len(t->command) > 0) {
		if (Str::eq_wide_string(t->command, L"primitive-definition")) {
			t->inline_command = primitive_definition_ISINC;
			if (Str::eq_wide_string(t->operand, L"repeat-through")) t->inline_subcommand = repeat_through_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"repeat-through-list")) t->inline_subcommand = repeat_through_list_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"number-of")) t->inline_subcommand = number_of_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"random-of")) t->inline_subcommand = random_of_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"total-of")) t->inline_subcommand = total_of_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"extremal")) t->inline_subcommand = extremal_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"function-application")) t->inline_subcommand = function_application_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"description-application")) t->inline_subcommand = description_application_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"solve-equation")) t->inline_subcommand = solve_equation_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"switch")) t->inline_subcommand = switch_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"break")) t->inline_subcommand = break_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"verbose-checking")) t->inline_subcommand = verbose_checking_ISINSC;
		} else if (Str::eq_wide_string(t->command, L"new")) t->inline_command = new_ISINC;
		else if (Str::eq_wide_string(t->command, L"new-list-of")) t->inline_command = new_list_of_ISINC;
		else if (Str::eq_wide_string(t->command, L"printing-routine")) t->inline_command = printing_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"ranger-routine")) t->inline_command = ranger_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"next-routine")) t->inline_command = next_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"previous-routine")) t->inline_command = previous_routine_ISINC;
		else if (Str::eq_wide_string(t->command, L"strong-kind")) t->inline_command = strong_kind_ISINC;
		else if (Str::eq_wide_string(t->command, L"weak-kind")) t->inline_command = weak_kind_ISINC;
		else if (Str::eq_wide_string(t->command, L"backspace")) t->inline_command = backspace_ISINC;
		else if (Str::eq_wide_string(t->command, L"erase")) t->inline_command = erase_ISINC;
		else if (Str::eq_wide_string(t->command, L"open-brace")) t->inline_command = open_brace_ISINC;
		else if (Str::eq_wide_string(t->command, L"close-brace")) t->inline_command = close_brace_ISINC;
		else if (Str::eq_wide_string(t->command, L"label")) t->inline_command = label_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter")) t->inline_command = counter_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-storage")) t->inline_command = counter_storage_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-up")) t->inline_command = counter_up_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-down")) t->inline_command = counter_down_ISINC;
		else if (Str::eq_wide_string(t->command, L"counter-makes-array")) t->inline_command = counter_makes_array_ISINC;
		else if (Str::eq_wide_string(t->command, L"by-reference")) t->inline_command = by_reference_ISINC;
		else if (Str::eq_wide_string(t->command, L"by-reference-blank-out")) t->inline_command = by_reference_blank_out_ISINC;
		else if (Str::eq_wide_string(t->command, L"reference-exists")) t->inline_command = reference_exists_ISINC;
		else if (Str::eq_wide_string(t->command, L"lvalue-by-reference")) t->inline_command = lvalue_by_reference_ISINC;
		else if (Str::eq_wide_string(t->command, L"by-value")) t->inline_command = by_value_ISINC;
		else if (Str::eq_wide_string(t->command, L"box-quotation-text")) t->inline_command = box_quotation_text_ISINC;
		else if (Str::eq_wide_string(t->command, L"try-action")) t->inline_command = try_action_ISINC;
		else if (Str::eq_wide_string(t->command, L"try-action-silently")) t->inline_command = try_action_silently_ISINC;
		else if (Str::eq_wide_string(t->command, L"return-value")) t->inline_command = return_value_ISINC;
		else if (Str::eq_wide_string(t->command, L"return-value-from-rule")) t->inline_command = return_value_from_rule_ISINC;
		else if (Str::eq_wide_string(t->command, L"property-holds-block-value")) t->inline_command = property_holds_block_value_ISINC;
		else if (Str::eq_wide_string(t->command, L"mark-event-used")) t->inline_command = mark_event_used_ISINC;
		else if (Str::eq_wide_string(t->command, L"my")) t->inline_command = my_ISINC;
		else if (Str::eq_wide_string(t->command, L"unprotect")) t->inline_command = unprotect_ISINC;
		else if (Str::eq_wide_string(t->command, L"copy")) t->inline_command = copy_ISINC;
		else if (Str::eq_wide_string(t->command, L"initialise")) t->inline_command = initialise_ISINC;
		else if (Str::eq_wide_string(t->command, L"matches-description")) t->inline_command = matches_description_ISINC;
		else if (Str::eq_wide_string(t->command, L"now-matches-description")) t->inline_command = now_matches_description_ISINC;
		else if (Str::eq_wide_string(t->command, L"arithmetic-operation")) t->inline_command = arithmetic_operation_ISINC;
		else if (Str::eq_wide_string(t->command, L"say")) t->inline_command = say_ISINC;
		else if (Str::eq_wide_string(t->command, L"show-me")) t->inline_command = show_me_ISINC;
		else if (Str::eq_wide_string(t->command, L"segment-count")) t->inline_command = segment_count_ISINC;
		else if (Str::eq_wide_string(t->command, L"final-segment-marker")) t->inline_command = final_segment_marker_ISINC;
		else if (Str::eq_wide_string(t->command, L"list-together")) {
			t->inline_command = list_together_ISINC;
			if (Str::eq_wide_string(t->operand, L"unarticled")) t->inline_subcommand = unarticled_ISINSC;
			else if (Str::eq_wide_string(t->operand, L"articled")) t->inline_subcommand = articled_ISINSC;
		} else if (Str::eq_wide_string(t->command, L"rescale")) t->inline_command = rescale_ISINC;
		else t->inline_command = unknown_ISINC;
	}

	InterSchemas::add_token(sch, t);
	preceding_token = t;

@ A bracing can take any of the following forms:
= (text)
	{-command}
	{-command:operand}
	{-command:operand:operand2}
	{-command:operand<property name}
	{-command:operand>property name}
	{some text}
	{-annotation:some text}
=
We parse this with the command or annotation in |command|, the "some text"
or operand in |bracing|, the property name (if given) in |extremal_property|,
the direction of the |<| or |>| in |extremal_property_sign|, and the second,
optional, operand in |operand2|.

@<Decompose the bracing@> =
	TEMPORARY_TEXT(pname)
	if (Str::get_first_char(t->bracing) == '-') {
		int portion = 1;
		for (int i=1, L = Str::len(t->bracing); i<L; i++) {
			int c = Str::get_at(t->bracing, i);
			switch(portion) {
				case 1:
					if (c == ':') portion = 2;
					else PUT_TO(t->command, c);
					break;
				case 2:
					if (c == ':') portion = 3;
					#ifdef CORE_MODULE
					else if (c == '<') { t->extremal_property_sign = MEASURE_T_OR_LESS; portion = 4; }
					else if (c == '>') { t->extremal_property_sign = MEASURE_T_OR_MORE; portion = 4; }
					#endif
					else PUT_TO(t->operand, c);
					break;
				case 3:
					PUT_TO(t->operand2, c); break;
				case 4:
					PUT_TO(pname, c); break;
			}
		}
		#ifdef CORE_MODULE
		if (t->extremal_property_sign != MEASURE_T_EXACTLY) {
			wording W = Feeds::feed_text(pname);
			if (<property-name>(W)) t->extremal_property = <<rp>>;
		}
		#endif
		Str::copy(t->bracing, t->operand);
	}
	DISCARD_TEXT(pname)

@ In abbreviated prototypes, |*1| and |*2| are placeholders, but a number
of modifiers are allowed. The full syntax follows:

@d GIVE_KIND_ID_ISSBM					1
@d GIVE_COMPARISON_ROUTINE_ISSBM		2
@d DEREFERENCE_PROPERTY_ISSBM			4
@d ADOPT_LOCAL_STACK_FRAME_ISSBM		8
@d CAST_TO_KIND_OF_OTHER_TERM_ISSBM		16
@d BY_REFERENCE_ISSBM					32
@d LVALUE_CONTEXT_ISSBM	                64
@d STORAGE_AS_FUNCTION_ISSBM            128

@<Look for a possible abbreviated command@> =
	int at = pos;
	wchar_t c = Str::get_at(from, ++at);
	int iss_bitmap = 0;
	switch (c) {
		case '!': internal_error("the '*!' schema notation has been abolished"); break;
		case '%': iss_bitmap = iss_bitmap | LVALUE_CONTEXT_ISSBM; c = Str::get_at(from, ++at); break;
		case '$': iss_bitmap = iss_bitmap | STORAGE_AS_FUNCTION_ISSBM; c = Str::get_at(from, ++at); break;
		case '#': iss_bitmap = iss_bitmap | GIVE_KIND_ID_ISSBM; c = Str::get_at(from, ++at); break;
		case '_': iss_bitmap = iss_bitmap | GIVE_COMPARISON_ROUTINE_ISSBM; c = Str::get_at(from, ++at); break;
		case '+': iss_bitmap = iss_bitmap | DEREFERENCE_PROPERTY_ISSBM; c = Str::get_at(from, ++at); break;
		case '|': iss_bitmap = iss_bitmap | (DEREFERENCE_PROPERTY_ISSBM + LVALUE_CONTEXT_ISSBM); c = Str::get_at(from, ++at); break;
		case '?': iss_bitmap = iss_bitmap | ADOPT_LOCAL_STACK_FRAME_ISSBM; c = Str::get_at(from, ++at); break;
		case '<': iss_bitmap = iss_bitmap | CAST_TO_KIND_OF_OTHER_TERM_ISSBM; c = Str::get_at(from, ++at); break;
		case '^': iss_bitmap = iss_bitmap | (ADOPT_LOCAL_STACK_FRAME_ISSBM + BY_REFERENCE_ISSBM); c = Str::get_at(from, ++at); break;
		case '>': iss_bitmap = iss_bitmap | BY_REFERENCE_ISSBM; c = Str::get_at(from, ++at); break;
	}
	if (Characters::isdigit(c)) {
		@<Absorb raw material, if any@>;
		TEMPORARY_TEXT(T)
		for (int i=pos; i<=at; i++) PUT_TO(T, Str::get_at(from, i));
		inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, T, 0, 0, -1);
		t->bracing = Str::duplicate(T);
		t->inline_command = substitute_ISINC;
		t->inline_modifiers = iss_bitmap;
		t->constant_number = (int) c - (int) '1';
		InterSchemas::add_token(sch, t);
		preceding_token = t;
		DISCARD_TEXT(T)
		pos = at;
	} else if (c == '&') {
		inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, I"*&", 0, 0, -1);
		t->bracing = I"*&";
		t->inline_command = combine_ISINC;
		t->inline_modifiers = iss_bitmap;
		InterSchemas::add_token(sch, t);
		preceding_token = t;
		pos = at;
	} else if (c == '-') {
		internal_error("the '*-' schema notation has been abolished");
	} else if (c == '*') {
		int c = '*'; @<Absorb a raw character@>;
		pos = at;
	} else {
		int c = '{'; @<Absorb a raw character@>;
	}

@ That leaves us with just the main case to handle: raw I6 code which is
outside of quotation marks and commentary, and which doesn't include
bracings or I7 interpolations. That might look like, for instance,
= (text as Inform 6)
	Frog + 2*Toad(
=
(there is no reason to suppose that this stretch of code is complete or
matches parentheses); we must tokenise it into

|Frog| |W| |+| |W| |2| |*| |Toad| |(|

where |W| indicates a white space token. What we do is scan through the
text until we reach the start of a new token, and then break off what we
scanned through since the last time.

@<Look for individual tokens@> =
	int L = Str::len(current_raw);
	int c_start = 0, escaped = FALSE;
	for (int p = 0; p < L; p++) {
		wchar_t c1 = Str::get_at(current_raw, p), c2 = 0, c3 = 0;
		if (p < L-1) c2 = Str::get_at(current_raw, p+1);
		if (p < L-2) c3 = Str::get_at(current_raw, p+2);

		if (escaped == FALSE) {
			if ((c1 == '$') && ((p == 0) || (Characters::isalpha(Str::get_at(current_raw, p-1)) == FALSE)))
				@<Break off here for real, binary or hexadecimal notation@>;
			if (c1 == '-') @<Break off here for negative number@>;
			@<Break off here for operators@>;
		}
		if (c1 == 0x00A7) escaped = escaped?FALSE:TRUE;
	}
	if (c_start < L) {
		int x = c_start, y = L-1;
		@<Break off a token@>;
	}

@ Recall that in I6 notation, a dollar introduces a non-decimal number, and
the character after the initial dollar determines which:
= (text)
	$+3.14159E2
	$$1001001
	$1FE6
=

@<Break off here for real, binary or hexadecimal notation@> =
	int x = c_start, y = p-1;
	@<Break off a token@>;
	switch (c2) {
		case '+': case '-':
			x = p; y = p+1;
			while ((Str::get_at(current_raw, y+1) == '.') ||
					(Str::get_at(current_raw, y+1) == 'E') ||
					(Str::get_at(current_raw, y+1) == 'e') ||
					(Characters::isdigit(Str::get_at(current_raw, y+1))))
				y++;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
		case '$':
			x = p; y = p+1;
			while ((Str::get_at(current_raw, y+1) == '0') ||
					(Str::get_at(current_raw, y+1) == '1'))
				y++;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
		default:
			x = p; y = p;
			while (Characters::isalnum(Str::get_at(current_raw, y+1)))
				y++;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
	}

@ A token beginning with a minus sign and continuing with digits may still
not be a negative number: it may be the binary subtraction operator.
For example, we need to tokenise |x-1| as
= (text)
|x| |-| |1|
=
and not as
= (text)
|x| |-1|
=
This requires context, that is, remembering what the previous token was.

@<Break off here for negative number@> =
	if (((preceding_token == NULL) ||
		(preceding_token->ist_type == OPEN_ROUND_ISTT) ||
		(preceding_token->ist_type == OPERATOR_ISTT) ||
		(preceding_token->ist_type == DIVIDER_ISTT)) &&
		(c_start == p) &&
		(!((abbreviated) && (preceding_token->ist_type == INLINE_ISTT)))) {
		int dc = p+1;
		while (Characters::isdigit(Str::get_at(current_raw, dc))) dc++;
		if (dc > p+1) {
			int x = c_start, y = p-1;
			@<Break off a token@>;
			x = p; y = dc - 1;
			@<Break off a token@>;
			p = y;
			c_start = p+1;
			continue;
		}
	}

@ In I6, operators made of non-alphanumeric characters can be up to three
characters long, and we take the longest match: thus |-->| is a trigraph,
not the monograph |-| followed by the digraph |->|.

We treat the |@| sign as if it were alphanumeric for the sake of assembly
language opcodes such as |@pull|.

@<Break off here for operators@> =
	int monograph = TRUE, digraph = FALSE, trigraph = FALSE;
	if ((Characters::isalnum(c1)) || (c1 == '_') || (c1 == '$')) monograph = FALSE;
	if (c1 == 0x00A7) monograph = FALSE;
	if ((c1 == '#') && (Characters::isalpha(c2))) monograph = FALSE;
	if ((c1 == '_') && (Characters::isalpha(c2))) monograph = FALSE;
	if ((c1 == '#') && (c2 == '#') && (Characters::isalpha(c3))) monograph = FALSE;
	if ((c1 == '@') && (Characters::isalpha(c2))) monograph = FALSE;

	if ((c1 == '+') && (c2 == '+')) digraph = TRUE;
	if ((c1 == '-') && (c2 == '-')) digraph = TRUE;
	if ((c1 == '>') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '<') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '=') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '-') && (c2 == '>')) digraph = TRUE;
	if ((c1 == '.') && (c2 == '&')) digraph = TRUE;
	if ((c1 == '.') && (c2 == '#')) digraph = TRUE;
	if ((c1 == '~') && (c2 == '~')) digraph = TRUE;
	if ((c1 == '~') && (c2 == '=')) digraph = TRUE;
	if ((c1 == '&') && (c2 == '&')) digraph = TRUE;
	if ((c1 == '|') && (c2 == '|')) digraph = TRUE;
	if ((c1 == '>') && (c2 == '>')) digraph = TRUE;

	if ((c1 == '-') && (c2 == '-') && (c3 == '>')) trigraph = TRUE;

	if (trigraph) {
		int x = c_start, y = p-1;
		@<Break off a token@>;
		x = p; y = p+2;
		@<Break off a token@>;
		p += 2;
		c_start = p+1;
		continue;
	}

	if (digraph) {
		int x = c_start, y = p-1;
		@<Break off a token@>;
		x = p; y = p+1;
		@<Break off a token@>;
		p++;
		c_start = p+1;
		continue;
	}

	if (monograph) {
		int x = c_start, y = p-1;
		@<Break off a token@>;
		x = p; y = p;
		@<Break off a token@>;
		c_start = p+1;
		continue;
	}

@ In this code, the new token is between character positions |x| and |y|
inclusive; we ignore an empty token.

@<Break off a token@> =
	if (y >= x) {
		TEMPORARY_TEXT(T)
		for (int i = x; i <= y; i++) PUT_TO(T, Str::get_at(current_raw, i));

		int is = RAW_ISTT;
		inter_ti which = 0;
		int which_rw = 0, which_number = -1, which_quote = -1;
		@<Identify this new token@>;

		inter_schema_token *n = InterSchemas::new_token(is, T, which, which_rw, which_number);
		#ifdef CORE_MODULE
		if (which_quote >= 0) n->as_quoted = quoted_inames[which_quote];
		#endif
		InterSchemas::add_token(sch, n);
		if (n->ist_type != WHITE_SPACE_ISTT) preceding_token = n;
		DISCARD_TEXT(T)
	}

@ Finally, we identify what sort of token we're looking at.

@e HAS_XBIP from 10000
@e HASNT_XBIP
@e READ_XBIP
@e OWNERKIND_XBIP

@<Identify this new token@> =
	if (Str::get_at(T, 0) == '@') is = OPCODE_ISTT;
	if (Str::get_at(T, 0) == 0x00A7)
		is = IDENTIFIER_ISTT;
	if ((Str::get_at(T, 0) == '#') && (Str::get_at(T, 1) == '#') && (Characters::isalpha(Str::get_at(T, 2)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (c != '#') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
	}
	if ((Str::get_at(T, 0) == '#') && (Characters::isalpha(Str::get_at(T, 1)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (c != '#') && (c != '$') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
	}
	if ((Str::get_at(T, 0) == '_') && (Characters::isalpha(Str::get_at(T, 1)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (c != '#') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
	}
	if (Characters::isalpha(Str::get_at(T, 0))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (!Characters::isalnum(c)))
				is = RAW_ISTT;
		}
		if (Str::begins_with_wide_string(T, L"QUOTED_INAME_0_")) which_quote = 0;
		else if (Str::begins_with_wide_string(T, L"QUOTED_INAME_1_")) which_quote = 1;
		if (Str::eq(T, I"I7_string")) { Str::clear(T); WRITE_TO(T, "I7_String"); }
		if (Str::eq(T, I"COMMA_WORD")) { Str::clear(T); WRITE_TO(T, "comma_word"); }
	}
	if (Characters::isdigit(Str::get_at(T, 0))) {
		is = NUMBER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if (!Characters::isdigit(c))
				is = RAW_ISTT;
		}
	}
	if (Str::get_at(T, 0) == '$') {
		is = HEX_NUMBER_ISTT;
		wchar_t c = Str::get_at(T, 1);
		if (c == '$') is = BIN_NUMBER_ISTT;
		if (c == '+') is = REAL_NUMBER_ISTT;
		if (c == '-') is = REAL_NUMBER_ISTT;
	}
	if (Str::get_at(T, 0) == '-') is = NUMBER_ISTT;

	if (Str::eq(T, I"false")) { is = NUMBER_ISTT; which_number = 0; }
	if (Str::eq(T, I"true")) { is = NUMBER_ISTT; which_number = 1; }
	if (Str::eq(T, I"nothing")) { is = NUMBER_ISTT; which_number = 0; }

	if (Str::eq(T, I"if")) { is = RESERVED_ISTT; which_rw = IF_I6RW; }
	if (Str::eq(T, I"else")) { is = RESERVED_ISTT; which_rw = ELSE_I6RW; }
	if (Str::eq(T, I"style")) { is = RESERVED_ISTT; which_rw = STYLE_I6RW; }
	if (Str::eq(T, I"return")) { is = RESERVED_ISTT; which_rw = RETURN_I6RW; }
	if (Str::eq(T, I"rtrue")) { is = RESERVED_ISTT; which_rw = RTRUE_I6RW; }
	if (Str::eq(T, I"rfalse")) { is = RESERVED_ISTT; which_rw = RFALSE_I6RW; }
	if (Str::eq(T, I"for")) { is = RESERVED_ISTT; which_rw = FOR_I6RW; }
	if (Str::eq(T, I"objectloop")) { is = RESERVED_ISTT; which_rw = OBJECTLOOP_I6RW; }
	if (Str::eq(T, I"while")) { is = RESERVED_ISTT; which_rw = WHILE_I6RW; }
	if (Str::eq(T, I"do")) { is = RESERVED_ISTT; which_rw = DO_I6RW; }
	if (Str::eq(T, I"until")) { is = RESERVED_ISTT; which_rw = UNTIL_I6RW; }
	if (Str::eq(T, I"print")) { is = RESERVED_ISTT; which_rw = PRINT_I6RW; }
	if (Str::eq(T, I"print_ret")) { is = RESERVED_ISTT; which_rw = PRINTRET_I6RW; }
	if (Str::eq(T, I"new_line")) { is = RESERVED_ISTT; which_rw = NEWLINE_I6RW; }
	if (Str::eq(T, I"give")) { is = RESERVED_ISTT; which_rw = GIVE_I6RW; }
	if (Str::eq(T, I"move")) { is = RESERVED_ISTT; which_rw = MOVE_I6RW; }
	if (Str::eq(T, I"remove")) { is = RESERVED_ISTT; which_rw = REMOVE_I6RW; }
	if (Str::eq(T, I"jump")) { is = RESERVED_ISTT; which_rw = JUMP_I6RW; }
	if (Str::eq(T, I"switch")) { is = RESERVED_ISTT; which_rw = SWITCH_I6RW; }
	if (Str::eq(T, I"default")) { is = RESERVED_ISTT; which_rw = DEFAULT_I6RW; }
	if (Str::eq(T, I"font")) { is = RESERVED_ISTT; which_rw = FONT_I6RW; }
	if (Str::eq(T, I"continue")) { is = RESERVED_ISTT; which_rw = CONTINUE_I6RW; }
	if (Str::eq(T, I"break")) { is = RESERVED_ISTT; which_rw = BREAK_I6RW; }
	if (Str::eq(T, I"quit")) { is = RESERVED_ISTT; which_rw = QUIT_I6RW; }
	if (Str::eq(T, I"restore")) { is = RESERVED_ISTT; which_rw = RESTORE_I6RW; }
	if (Str::eq(T, I"spaces")) { is = RESERVED_ISTT; which_rw = SPACES_I6RW; }
	if (Str::eq(T, I"read")) { is = RESERVED_ISTT; which_rw = READ_I6RW; }
	if (Str::eq(T, I"inversion")) { is = RESERVED_ISTT; which_rw = INVERSION_I6RW; }

	if (Str::eq_insensitive(T, I"#IFDEF")) { is = DIRECTIVE_ISTT; which_rw = IFDEF_I6RW; }
	if (Str::eq_insensitive(T, I"#IFNDEF")) { is = DIRECTIVE_ISTT; which_rw = IFNDEF_I6RW; }
	if (Str::eq_insensitive(T, I"#IFTRUE")) { is = DIRECTIVE_ISTT; which_rw = IFTRUE_I6RW; }
	if (Str::eq_insensitive(T, I"#IFFALSE")) { is = DIRECTIVE_ISTT; which_rw = IFFALSE_I6RW; }
	if (Str::eq_insensitive(T, I"#IFNOT")) { is = DIRECTIVE_ISTT; which_rw = IFNOT_I6RW; }
	if (Str::eq_insensitive(T, I"#ENDIF")) { is = DIRECTIVE_ISTT; which_rw = ENDIF_I6RW; }

	if (Str::eq(T, I",")) is = COMMA_ISTT;
	if (Str::eq(T, I":")) is = COLON_ISTT;
	if (Str::eq(T, I"(")) is = OPEN_ROUND_ISTT;
	if (Str::eq(T, I")")) is = CLOSE_ROUND_ISTT;
	if (Str::eq(T, I"{")) is = OPEN_BRACE_ISTT;
	if (Str::eq(T, I"}")) is = CLOSE_BRACE_ISTT;
	if (Str::eq(T, I";")) is = DIVIDER_ISTT;

	if (Str::eq(T, I".")) { is = OPERATOR_ISTT; which = PROPERTYVALUE_BIP; }
	if (Str::eq(T, I".&")) { is = OPERATOR_ISTT; which = PROPERTYARRAY_BIP; }
	if (Str::eq(T, I".#")) { is = OPERATOR_ISTT; which = PROPERTYLENGTH_BIP; }
	if (Str::eq(T, I">>")) { is = OPERATOR_ISTT; which = OWNERKIND_XBIP; }

	if (Str::eq(T, I"=")) { is = OPERATOR_ISTT; which = STORE_BIP; }

	if (Str::eq(T, I"+")) { is = OPERATOR_ISTT; which = PLUS_BIP; }
	if (Str::eq(T, I"-")) { is = OPERATOR_ISTT; which = MINUS_BIP; }
	if (Str::eq(T, I"*")) { is = OPERATOR_ISTT; which = TIMES_BIP; }
	if (Str::eq(T, I"/")) { is = OPERATOR_ISTT; which = DIVIDE_BIP; }
	if (Str::eq(T, I"%")) { is = OPERATOR_ISTT; which = MODULO_BIP; }

	if (Str::eq(T, I">")) { is = OPERATOR_ISTT; which = GT_BIP; }
	if (Str::eq(T, I">=")) { is = OPERATOR_ISTT; which = GE_BIP; }
	if (Str::eq(T, I"<")) { is = OPERATOR_ISTT; which = LT_BIP; }
	if (Str::eq(T, I"<=")) { is = OPERATOR_ISTT; which = LE_BIP; }
	if (Str::eq(T, I"==")) { is = OPERATOR_ISTT; which = EQ_BIP; }
	if (Str::eq(T, I"~=")) { is = OPERATOR_ISTT; which = NE_BIP; }

	if (Str::eq(T, I"~~")) { is = OPERATOR_ISTT; which = NOT_BIP; }
	if (Str::eq(T, I"&&")) { is = OPERATOR_ISTT; which = AND_BIP; }
	if (Str::eq(T, I"||")) { is = OPERATOR_ISTT; which = OR_BIP; }
	if (Str::eq(T, I"or")) { is = OPERATOR_ISTT; which = ALTERNATIVE_BIP; }

	if (Str::eq(T, I"ofclass")) { is = OPERATOR_ISTT; which = OFCLASS_BIP; }
	if (Str::eq(T, I"has")) { is = OPERATOR_ISTT; which = HAS_XBIP; }
	if (Str::eq(T, I"hasnt")) { is = OPERATOR_ISTT; which = HASNT_XBIP; }
	if (Str::eq(T, I"provides")) { is = OPERATOR_ISTT; which = PROPERTYEXISTS_BIP; }
	if (Str::eq(T, I"in")) { is = OPERATOR_ISTT; which = IN_BIP; }
	if (Str::eq(T, I"notin")) { is = OPERATOR_ISTT; which = NOTIN_BIP; }

	if (Str::eq(T, I"|")) { is = OPERATOR_ISTT; which = BITWISEOR_BIP; }
	if (Str::eq(T, I"&")) { is = OPERATOR_ISTT; which = BITWISEAND_BIP; }
	if (Str::eq(T, I"~")) { is = OPERATOR_ISTT; which = BITWISENOT_BIP; }

	if (Str::eq(T, I"++")) { is = OPERATOR_ISTT; which = POSTINCREMENT_BIP; }
	if (Str::eq(T, I"--")) { is = OPERATOR_ISTT; which = POSTDECREMENT_BIP; }

	if (Str::eq(T, I"->")) { is = OPERATOR_ISTT; which = LOOKUPBYTE_BIP; }
	if (Str::eq(T, I"-->")) { is = OPERATOR_ISTT; which = LOOKUP_BIP; }

@

=
void Tokenisation::de_escape_text(text_stream *m) {
	int run_start = -1, run_len = 0, run_includes = FALSE;
	for (int i=0; i<Str::len(m); i++) {
		wchar_t c = Str::get_at(m, i);
		if ((c == ' ') || (c == '\t') || (c == '\n')) {
			if (run_start == -1) {
				run_start = i;
				run_len = 0;
				run_includes = FALSE;
			}
			run_len++;
			if (c == '\n') run_includes = TRUE;
		} else {
			if ((run_start >= 0) && (run_includes)) {
				Str::put_at(m, run_start, ' ');
				for (int j=0; j<run_len-1; j++)
					Str::delete_nth_character(m, run_start+1);
				i = run_start;
			}
			run_start = -1;
		}
	}
	LOOP_THROUGH_TEXT(P, m) {
		if (Str::get(P) == '^')
			Str::put(P, '\n');
		if (Str::get(P) == '~')
			Str::put(P, '\"');
	}
}
