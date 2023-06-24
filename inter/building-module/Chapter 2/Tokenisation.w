[Tokenisation::] Tokenisation.

Turning textual code written in Inform 6 syntax into a linked list of tokens.

@ The following code was sketched out on a long night flight to Hong Kong, but
there is otherwise nothing exotic about it. In as simple a way as possible, we
take a text |from| and break it into Inform 6 tokens. What we return is not
literally a linked list, but it amounts to the same thing: a single node
holding an unstructured run of tokens --
= (text)
	EXPRESSION_ISNT
		T1
		T2
		T3
		...
=
We follow the syntax of Inform 6, except that we have to look for three extra
syntaxes: |{-braced-commands}|, |(+ Inform 7 interpolation +)|, and, if the
abbreviated syntax is allowed, also some cryptic notations such as |*1|.

The following scanner is basically a finite state machine, and these are the
states:

@e NO_TOKSTATE from 1
@e COMMENT_TOKSTATE  /* currently scanning... an I6 comment |! ...| */
@e DQUOTED_TOKSTATE  /* ...double-quoted text */
@e SQUOTED_TOKSTATE  /* ...single-quoted text */
@e WHITE_TOKSTATE    /* ...whitespace */
@e TOK_TOKSTATE      /* ...an actual token */

=
void Tokenisation::go(inter_schema *sch, text_stream *from, int pos, int abbreviated,
	int no_quoted_inames, void **quoted_inames) {
	inter_schema_token *preceding_token = NULL;

	int definition_length = Str::len(from);
	int line_offset = 0;
	text_stream *current_raw = Str::new();
	int tokeniser_state = NO_TOKSTATE;
	for (; pos<definition_length; pos++) {
		int c = Str::get_at(from, pos);
		if (Characters::is_whitespace(c)) {
			if (c == '\n') line_offset++;
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
			 		@<Absorb raw material, for sure@>;
			 		tokeniser_state = NO_TOKSTATE;
			 	} else {
				 	PUT_TO(current_raw, c);
				}
			 	break;
			 case SQUOTED_TOKSTATE: {
			 	int ends_here = FALSE;
			 	if (c == '\'') {
			 		ends_here = TRUE;
			 		if ((Str::len(current_raw) == 0) && (Str::get_at(from, pos+1) == '\''))
			 			ends_here = FALSE;
			 	}
			 	if (ends_here) {
			 		@<Absorb raw material, for sure@>;
			 		tokeniser_state = NO_TOKSTATE;
			 	} else {
				 	PUT_TO(current_raw, c);
				}
			 	break;
			 }
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
	if (Str::len(current_raw)) @<Absorb raw material, for sure@>;
	tokeniser_state = NO_TOKSTATE;

@<Absorb raw material, for sure@> =
	switch (tokeniser_state) {
		case WHITE_TOKSTATE:
			InterSchemas::add_token(sch,
				InterSchemas::new_token(WHITE_SPACE_ISTT, I" ", 0, 0, -1, line_offset));
			break;
		case DQUOTED_TOKSTATE:
			Tokenisation::de_escape_text(current_raw);
			InterSchemas::add_token(sch,
				InterSchemas::new_token(DQUOTED_ISTT, current_raw, 0, 0, -1, line_offset));
			break;
		case SQUOTED_TOKSTATE:
			Tokenisation::de_escape_sq_text(current_raw);
			InterSchemas::add_token(sch,
				InterSchemas::new_token(SQUOTED_ISTT, current_raw, 0, 0, -1, line_offset));
			break;
		default:
			@<Look for individual tokens@>;
			break;
	}
	Str::clear(current_raw);
	tokeniser_state = NO_TOKSTATE;

@<Process any escape character notation in single quotes@> =
	for (int i=0; i<Str::len(current_raw); i++) {
		wchar_t c = Str::get_at(current_raw, i);
		PUT_TO(unescaped, c);
	}

@<Process any escape character notation in double quotes@> =
	for (int i=0; i<Str::len(current_raw); i++) {
		wchar_t c = Str::get_at(current_raw, i);
		PUT_TO(unescaped, c);
	}

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

@ Note that the empty I7 interpolation is legal, but produces no token.

@<Expand a fragment of Inform 7 text@> =
	if (Str::len(source_text_fragment) > 0) {
		InterSchemas::add_token(sch,
			InterSchemas::new_token(I7_ISTT, source_text_fragment, 0, 0, -1, line_offset));
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
	inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, bracing, 0, 0, -1, line_offset);
	t->bracing = Str::duplicate(bracing);
	t->command = Str::new();
	t->operand = Str::new();
	t->operand2 = Str::new();
	@<Decompose the bracing@>;
	if (Str::len(t->command) > 0) {
		int c = unknown_ISINC, sc = no_ISINSC;
		if (Str::eq_wide_string(t->command, L"primitive-definition")) {
			c = primitive_definition_ISINC;
			if (Str::eq_wide_string(t->operand, L"repeat-through")) {
				sc = repeat_through_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"repeat-through-list")) {
				sc = repeat_through_list_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"number-of")) {
				sc = number_of_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"random-of")) {
				sc = random_of_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"total-of")) {
				sc = total_of_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"extremal")) {
				sc = extremal_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"function-application")) {
				sc = function_application_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"description-application")) {
				sc = description_application_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"solve-equation")) {
				sc = solve_equation_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"switch")) {
				sc = switch_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"break")) {
				sc = break_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"verbose-checking")) {
				sc = verbose_checking_ISINSC;
			}
		} else if (Str::eq_wide_string(t->command, L"new")) {
			c = new_ISINC;
		} else if (Str::eq_wide_string(t->command, L"new-list-of")) {
			c = new_list_of_ISINC;
		} else if (Str::eq_wide_string(t->command, L"printing-routine")) {
			c = printing_routine_ISINC;
		} else if (Str::eq_wide_string(t->command, L"ranger-routine")) {
			c = ranger_routine_ISINC;
		} else if (Str::eq_wide_string(t->command, L"indexing-routine")) {
			c = indexing_routine_ISINC;
		} else if (Str::eq_wide_string(t->command, L"next-routine")) {
			c = next_routine_ISINC;
		} else if (Str::eq_wide_string(t->command, L"previous-routine")) {
			c = previous_routine_ISINC;
		} else if (Str::eq_wide_string(t->command, L"strong-kind")) {
			c = strong_kind_ISINC;
		} else if (Str::eq_wide_string(t->command, L"weak-kind")) {
			c = weak_kind_ISINC;
		} else if (Str::eq_wide_string(t->command, L"backspace")) {
			c = backspace_ISINC;
		} else if (Str::eq_wide_string(t->command, L"erase")) {
			c = erase_ISINC;
		} else if (Str::eq_wide_string(t->command, L"open-brace")) {
			c = open_brace_ISINC;
		} else if (Str::eq_wide_string(t->command, L"close-brace")) {
			c = close_brace_ISINC;
		} else if (Str::eq_wide_string(t->command, L"label")) {
			c = label_ISINC;
		} else if (Str::eq_wide_string(t->command, L"counter")) {
			c = counter_ISINC;
		} else if (Str::eq_wide_string(t->command, L"counter-storage")) {
			c = counter_storage_ISINC;
		} else if (Str::eq_wide_string(t->command, L"counter-up")) {
			c = counter_up_ISINC;
		} else if (Str::eq_wide_string(t->command, L"counter-down")) {
			c = counter_down_ISINC;
		} else if (Str::eq_wide_string(t->command, L"counter-makes-array")) {
			c = counter_makes_array_ISINC;
		} else if (Str::eq_wide_string(t->command, L"by-reference")) {
			c = by_reference_ISINC;
		} else if (Str::eq_wide_string(t->command, L"by-reference-blank-out")) {
			c = by_reference_blank_out_ISINC;
		} else if (Str::eq_wide_string(t->command, L"reference-exists")) {
			c = reference_exists_ISINC;
		} else if (Str::eq_wide_string(t->command, L"lvalue-by-reference")) {
			c = lvalue_by_reference_ISINC;
		} else if (Str::eq_wide_string(t->command, L"by-value")) {
			c = by_value_ISINC;
		} else if (Str::eq_wide_string(t->command, L"box-quotation-text")) {
			c = box_quotation_text_ISINC;
		} else if (Str::eq_wide_string(t->command, L"try-action")) {
			c = try_action_ISINC;
		} else if (Str::eq_wide_string(t->command, L"try-action-silently")) {
			c = try_action_silently_ISINC;
		} else if (Str::eq_wide_string(t->command, L"return-value")) {
			c = return_value_ISINC;
		} else if (Str::eq_wide_string(t->command, L"return-value-from-rule")) {
			c = return_value_from_rule_ISINC;
		} else if (Str::eq_wide_string(t->command, L"property-holds-block-value")) {
			c = property_holds_block_value_ISINC;
		} else if (Str::eq_wide_string(t->command, L"mark-event-used")) {
			c = mark_event_used_ISINC;
		} else if (Str::eq_wide_string(t->command, L"my")) {
			c = my_ISINC;
		} else if (Str::eq_wide_string(t->command, L"unprotect")) {
			c = unprotect_ISINC;
		} else if (Str::eq_wide_string(t->command, L"copy")) {
			c = copy_ISINC;
		} else if (Str::eq_wide_string(t->command, L"initialise")) {
			c = initialise_ISINC;
		} else if (Str::eq_wide_string(t->command, L"matches-description")) {
			c = matches_description_ISINC;
		} else if (Str::eq_wide_string(t->command, L"now-matches-description")) {
			c = now_matches_description_ISINC;
		} else if (Str::eq_wide_string(t->command, L"arithmetic-operation")) {
			c = arithmetic_operation_ISINC;
		} else if (Str::eq_wide_string(t->command, L"say")) {
			c = say_ISINC;
		} else if (Str::eq_wide_string(t->command, L"show-me")) {
			c = show_me_ISINC;
		} else if (Str::eq_wide_string(t->command, L"segment-count")) {
			c = segment_count_ISINC;
		} else if (Str::eq_wide_string(t->command, L"final-segment-marker")) {
			c = final_segment_marker_ISINC;
		} else if (Str::eq_wide_string(t->command, L"list-together")) {
			c = list_together_ISINC;
			if (Str::eq_wide_string(t->operand, L"unarticled")) {
				sc = unarticled_ISINSC;
			} else if (Str::eq_wide_string(t->operand, L"articled")) {
				sc = articled_ISINSC;
			}
		} else if (Str::eq_wide_string(t->command, L"rescale")) {
			c = rescale_ISINC;
		}
		t->inline_command = c;
		t->inline_subcommand = sc;
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
					else if (c == '<') {
						t->extremal_property_sign = MEASURE_T_OR_LESS; portion = 4;
					}
					else if (c == '>') {
						t->extremal_property_sign = MEASURE_T_OR_MORE; portion = 4;
					}
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
of modifiers are allowed. See //calculus: Compilation Schemas//.

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
		case '!': I6Errors::issue_at_node(sch->node_tree, 
			I"the '*!' schema notation has been abolished"); break;
		case '%': iss_bitmap = iss_bitmap | LVALUE_CONTEXT_ISSBM;
				  c = Str::get_at(from, ++at); break;
		case '$': iss_bitmap = iss_bitmap | STORAGE_AS_FUNCTION_ISSBM;
				  c = Str::get_at(from, ++at); break;
		case '#': iss_bitmap = iss_bitmap | GIVE_KIND_ID_ISSBM;
				  c = Str::get_at(from, ++at); break;
		case '_': iss_bitmap = iss_bitmap | GIVE_COMPARISON_ROUTINE_ISSBM;
				  c = Str::get_at(from, ++at); break;
		case '+': iss_bitmap = iss_bitmap | DEREFERENCE_PROPERTY_ISSBM;
				  c = Str::get_at(from, ++at); break;
		case '|': iss_bitmap = iss_bitmap | (DEREFERENCE_PROPERTY_ISSBM + LVALUE_CONTEXT_ISSBM);
				  c = Str::get_at(from, ++at); break;
		case '?': iss_bitmap = iss_bitmap | ADOPT_LOCAL_STACK_FRAME_ISSBM;
				  c = Str::get_at(from, ++at); break;
		case '<': iss_bitmap = iss_bitmap | CAST_TO_KIND_OF_OTHER_TERM_ISSBM;
				  c = Str::get_at(from, ++at); break;
		case '^': iss_bitmap = iss_bitmap | (ADOPT_LOCAL_STACK_FRAME_ISSBM + BY_REFERENCE_ISSBM);
				  c = Str::get_at(from, ++at); break;
		case '>': iss_bitmap = iss_bitmap | BY_REFERENCE_ISSBM;
				  c = Str::get_at(from, ++at); break;
	}
	if (Characters::isdigit(c)) {
		@<Absorb raw material, if any@>;
		TEMPORARY_TEXT(T)
		for (int i=pos; i<=at; i++) PUT_TO(T, Str::get_at(from, i));
		inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, T, 0, 0, -1, line_offset);
		t->bracing = Str::duplicate(T);
		t->inline_command = substitute_ISINC;
		t->inline_modifiers = iss_bitmap;
		t->constant_number = (int) c - (int) '1';
		InterSchemas::add_token(sch, t);
		preceding_token = t;
		DISCARD_TEXT(T)
		pos = at;
	} else if (c == '&') {
		inter_schema_token *t = InterSchemas::new_token(INLINE_ISTT, I"*&", 0, 0, -1, line_offset);
		t->bracing = I"*&";
		t->inline_command = combine_ISINC;
		t->inline_modifiers = iss_bitmap;
		InterSchemas::add_token(sch, t);
		preceding_token = t;
		pos = at;
	} else if (c == '-') {
		I6Errors::issue_at_node(sch->node_tree, 
			I"the '*-' schema notation has been abolished"); 
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
= (text)
	Frog
	WHITE SPACE
	+
	WHITE SPACE
	2
	*
	Toad
	(
=
We scan through the text until we reach the start of a new token, and then break
off what we scanned through since the last time.

@<Look for individual tokens@> =
	int L = Str::len(current_raw);
	int c_start = 0, escaped = FALSE;
	for (int p = 0; p < L; p++) {
		wchar_t c1 = Str::get_at(current_raw, p), c2 = 0, c3 = 0;
		if (p < L-1) c2 = Str::get_at(current_raw, p+1);
		if (p < L-2) c3 = Str::get_at(current_raw, p+2);

		if (escaped == FALSE) {
			if ((c1 == '$') &&
				((p == 0) ||
					(Characters::isalpha(Str::get_at(current_raw, p-1)) == FALSE)))
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
			while (Tokenisation::identchar(Str::get_at(current_raw, y+1)))
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
	x
	-
	1
=
and not as
= (text)
	x
	-1
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
	if ((Tokenisation::identchar(c1)) || (c1 == '_') || (c1 == '$')) monograph = FALSE;
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
	if ((c1 == ':') && (c2 == ':')) digraph = TRUE;

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

		inter_schema_token *n = InterSchemas::new_token(is, T, which, which_rw, which_number, line_offset);
		#ifdef CORE_MODULE
		if (which_quote >= 0) n->as_quoted = quoted_inames[which_quote];
		#endif
		InterSchemas::add_token(sch, n);
		if (n->ist_type != WHITE_SPACE_ISTT) preceding_token = n;
		DISCARD_TEXT(T)
	}

@ Finally, we identify what sort of token we're looking at. It would be elegant
to reimplement this with a trie (e.g. using //foundation: Tries and Avinues//),
but speed is not quite important enough to make it worthwhile.

@d LOWEST_XBIP_VALUE HAS_XBIP

@e HAS_XBIP from 10000
@e HASNT_XBIP
@e READ_XBIP
@e OWNERKIND_XBIP

@d HIGHEST_XBIP_VALUE OWNERKIND_XBIP

@<Identify this new token@> =
	if (Str::get_at(T, 0) == '@') is = OPCODE_ISTT;
	if (Str::get_at(T, 0) == 0x00A7)
		is = IDENTIFIER_ISTT;
	if ((Str::get_at(T, 0) == '#') && (Str::get_at(T, 1) == '#') &&
		(Characters::isalpha(Str::get_at(T, 2)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (c != '#') && (!Tokenisation::identchar(c)))
				is = RAW_ISTT;
		}
	}
	if ((Str::get_at(T, 0) == '#') && (Characters::isalpha(Str::get_at(T, 1)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (c != '#') && (c != '$') && (!Tokenisation::identchar(c)))
				is = RAW_ISTT;
		}
	}
	if ((Str::get_at(T, 0) == '_') && (Characters::isalpha(Str::get_at(T, 1)))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (c != '#') && (!Tokenisation::identchar(c)))
				is = RAW_ISTT;
		}
	}
	if (Characters::isalpha(Str::get_at(T, 0))) {
		is = IDENTIFIER_ISTT;
		LOOP_THROUGH_TEXT(P, T) {
			wchar_t c = Str::get(P);
			if ((c != '_') && (!Tokenisation::identchar(c)))
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
	if (Str::eq_insensitive(T, I"#ORIGSOURCE")) { is = DIRECTIVE_ISTT; which_rw = ORIGSOURCE_I6RW; }

	if (Str::eq(T, I",")) is = COMMA_ISTT;
	if (Str::eq(T, I":")) is = COLON_ISTT;
	if (Str::eq(T, I"(")) is = OPEN_ROUND_ISTT;
	if (Str::eq(T, I")")) is = CLOSE_ROUND_ISTT;
	if (Str::eq(T, I"{")) is = OPEN_BRACE_ISTT;
	if (Str::eq(T, I"}")) is = CLOSE_BRACE_ISTT;
	if (Str::eq(T, I";")) is = DIVIDER_ISTT;

	if (Str::eq(T, I"::")) is = DCOLON_ISTT;

	inter_ti x = I6Operators::notation_to_BIP(T);
	if (x > 0) { is = OPERATOR_ISTT; which = x; }

@ Inform 6 has a baroque set of not very self-consistent escape characters in
its double-quoted text syntax: here we take a deep breath, and plunge in. The
following converts |text| from I6 notation to a (composed) Unicode-encoded
string, in which every character has its literal meaning.

Note that the test case |schemas| of the //building-test// module exercises
the following function.

=
void Tokenisation::de_escape_text(text_stream *text) {
	TEMPORARY_TEXT(raw)
	WRITE_TO(raw, "%S", text);
	Str::clear(text);
	@<Normalise the white space@>;
	@<De-escape raw into text@>;
	DISCARD_TEXT(raw)
}

@ Where a newline occurs inside double-quoted text, all whitespace either side
of it is deleted, and the newline replaced by a single space.

@<Normalise the white space@> =
	int run_start = -1, run_len = 0, run_includes = FALSE;
	for (int i=0; i<Str::len(raw); i++) {
		wchar_t c = Str::get_at(raw, i);
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
				Str::put_at(raw, run_start, ' ');
				for (int j=0; j<run_len-1; j++)
					Str::delete_nth_character(raw, run_start+1);
				i = run_start;
			}
			run_start = -1;
		}
	}

@ I6 does not follow the C-like language convention of using backslash for
string escapes. Instead |^| marks a forced newline and |~| marks a double-quotation
mark. All other string escapes begin with |@|.

@<De-escape raw into text@> =
	for (int i=0; i<Str::len(raw); i++) {
		@<De-escape the Inform 7 unicode escape@>;
		wchar_t c = Str::get_at(raw, i);
		switch (c) {
			case '^': PUT_TO(text, '\n'); break;
			case '~': PUT_TO(text, '\"'); break;
			case '@': {
				TEMPORARY_TEXT(token)
				int skip = 1, decimal = FALSE, hexadecimal = FALSE;
				@<Extract the escape token@>;
				i += skip-1;
				if (hexadecimal) @<Expand hexadecimal Unicode value@>
				else if (decimal) @<Expand decimal ZSCII value@>
				else @<Expand TeX-style digraph@>;
				DISCARD_TEXT(token)
				break;
			}
			default: PUT_TO(text, c); break;
		}
	}

@ This is not an I6 notation at all. If a character outside the range allowed
by I6 in string literals is present in an I7 source text file -- for example,
a capital Cyrillic ef -- then it is converted internally by the compiler to
something like |[unicode 1060]|, with 1060 here being the decimal code point
for the character.

We will recognise this notation and translate it back into Unicode. The reason
for doing this, even though the stand-alone I6 compiler would not, is that
it means I6 source fed into this tokeniser will be treated the same whether
it comes from an Include directive in I7 source text, or whether it comes from
a kit source file.

@<De-escape the Inform 7 unicode escape@> =
	if (Str::includes_at(raw, i, I"[unicode ")) {
		int unicode_point = 0;
		for (int j=i+9; j<Str::len(raw); j++) {
			wchar_t c = Str::get_at(raw, j);
			if (c == ']') {
				unicode_point = Str::atoi(raw, i+9);
				i = j;
				break;
			}
			if (Characters::isdigit(c) == FALSE) break;
		}
		if (unicode_point > 0) {
			PUT_TO(text, unicode_point);
			continue;
		}
	}

@ There are three different forms for an |@|-escape. First, |@{....}| with
hexadecimal digits inside the braces; then |@@...| with decimal digits; and
otherwise |@..| for any of the set of legal digraphs listed below. The
content represented by dots in these syntaxes we will store in |token|,
and |skip| will count the total length of the escape, in raw characters.
Thus for |@{2af4}| the |skip| count would be 7.

@<Extract the escape token@> =
	wchar_t d = Str::get_at(raw, i+1);
	if (d == '{') {
		skip++;
		while (Str::get_at(raw, i+skip)) {
			wchar_t e = Str::get_at(raw, i+skip);
			skip++;
			if (e == '}') break;
			PUT_TO(token, e);
		}
		hexadecimal = TRUE;
	} else if (d == '@') {
		skip++;
		while (Characters::isdigit(Str::get_at(raw, i+skip))) {
			wchar_t e = Str::get_at(raw, i+skip);
			skip++;
			PUT_TO(token, e);
		}
		decimal = TRUE;
	} else {
		PUT_TO(token, d);
		PUT_TO(token, Str::get_at(raw, i+2));
		skip += 2;
	}

@ The hex notation refers directly to Unicode code points, so all we need to
do is convert the token from a string to hex and then put it as a character.

@<Expand hexadecimal Unicode value@> =
	int N = 0;
	LOOP_THROUGH_TEXT(pos, token) {
		wchar_t c = Str::get(pos);
		int D = Tokenisation::hex_val(c);
		if (D == -1) { N = -1; break; }
		N = 16*N + D;
	}
	if (N == -1) WRITE_TO(text, "?ERROR<%S>", token);
	else PUT_TO(text, N);

@ Decimal notation is substantially more annoying, because it uses the ZSCII
character set, not Unicode. ZSCII is (for our purposes at least) the same as
ASCII in the range 0 to 127, but is then very unlike ISO Latin-1 (and thus
Unicode) in the range 128 to 255. (Which is as far as it goes.) The following
therefore converts ZSCII to Unicode code points. Note that ZSCII cannot be
mapped faithfully into ISO Latin-1 alone: it contains the OE ligature, which
is in a different Unicode page. See "Table 2B: Higher ZSCII Character Set"
in the DM4.

@<Expand decimal ZSCII value@> =
	int N = Str::atoi(token, 0);
	if (N<128) PUT_TO(text, N);
	else {
		switch (N) {
			case 155: PUT_TO(text, 0xE4); break; /* a-diarhesis */
			case 156: PUT_TO(text, 0xF6); break; /* o-diarhesis */
			case 157: PUT_TO(text, 0xFC); break; /* u-diarhesis */
			case 158: PUT_TO(text, 0xC4); break; /* A-diarhesis */
			case 159: PUT_TO(text, 0xD6); break; /* O-diarhesis */
			case 160: PUT_TO(text, 0xDC); break; /* U-diarhesis */
			case 161: PUT_TO(text, 0xDF); break; /* sharp s */
			case 162: PUT_TO(text, 0xBB); break; /* close double-angle quotation mark */
			case 163: PUT_TO(text, 0xAB); break; /* open double-angle quotation mark */
			case 164: PUT_TO(text, 0xEB); break; /* e-diarhesis */
			case 165: PUT_TO(text, 0xEF); break; /* i-diarhesis */
			case 166: PUT_TO(text, 0xFF); break; /* y-diarhesis */
			case 167: PUT_TO(text, 0xCB); break; /* E-diarhesis */
			case 168: PUT_TO(text, 0xCF); break; /* I-diarhesis */
			case 169: PUT_TO(text, 0xE1); break; /* a-acute */
			case 170: PUT_TO(text, 0xE9); break; /* e-acute */
			case 171: PUT_TO(text, 0xED); break; /* i-acute */
			case 172: PUT_TO(text, 0xF3); break; /* o-acute */
			case 173: PUT_TO(text, 0xFA); break; /* u-acute */
			case 174: PUT_TO(text, 0xFD); break; /* y-acute */
			case 175: PUT_TO(text, 0xC1); break; /* A-acute */
			case 176: PUT_TO(text, 0xC9); break; /* E-acute */
			case 177: PUT_TO(text, 0xCD); break; /* I-acute */
			case 178: PUT_TO(text, 0xD3); break; /* O-acute */
			case 179: PUT_TO(text, 0xDA); break; /* U-acute */
			case 180: PUT_TO(text, 0xDD); break; /* Y-acute */
			case 181: PUT_TO(text, 0xE0); break; /* a-grave */
			case 182: PUT_TO(text, 0xE8); break; /* e-grave */
			case 183: PUT_TO(text, 0xEC); break; /* i-grave */
			case 184: PUT_TO(text, 0xF2); break; /* o-grave */
			case 185: PUT_TO(text, 0xF9); break; /* u-grave */
			case 186: PUT_TO(text, 0xC0); break; /* A-grave */
			case 187: PUT_TO(text, 0xC8); break; /* E-grave */
			case 188: PUT_TO(text, 0xCC); break; /* I-grave */
			case 189: PUT_TO(text, 0xD2); break; /* O-grave */
			case 190: PUT_TO(text, 0xD9); break; /* U-grave */
			case 191: PUT_TO(text, 0xE2); break; /* a-circumflex */
			case 192: PUT_TO(text, 0xEA); break; /* e-circumflex */
			case 193: PUT_TO(text, 0xEE); break; /* i-circumflex */
			case 194: PUT_TO(text, 0xF4); break; /* o-circumflex */
			case 195: PUT_TO(text, 0xFB); break; /* u-circumflex */
			case 196: PUT_TO(text, 0xC2); break; /* A-circumflex */
			case 197: PUT_TO(text, 0xCA); break; /* E-circumflex */
			case 198: PUT_TO(text, 0xCE); break; /* I-circumflex */
			case 199: PUT_TO(text, 0xD4); break; /* O-circumflex */
			case 200: PUT_TO(text, 0xDB); break; /* U-circumflex */
			case 201: PUT_TO(text, 0xE6); break; /* a-ring */
			case 202: PUT_TO(text, 0xC6); break; /* A-ring */
			case 203: PUT_TO(text, 0xF8); break; /* o-stroke */
			case 204: PUT_TO(text, 0xD8); break; /* O-stroke */
			case 205: PUT_TO(text, 0xE3); break; /* a-tilde */
			case 206: PUT_TO(text, 0xF1); break; /* n-tilde */
			case 207: PUT_TO(text, 0xF5); break; /* o-tilde */
			case 208: PUT_TO(text, 0xC3); break; /* A-tilde */
			case 209: PUT_TO(text, 0xD1); break; /* N-tilde */
			case 210: PUT_TO(text, 0xD5); break; /* O-tilde */
			case 211: PUT_TO(text, 0xE6); break; /* ae */
			case 212: PUT_TO(text, 0xC6); break; /* AE */
			case 213: PUT_TO(text, 0xE7); break; /* c-cedilla */
			case 214: PUT_TO(text, 0xC7); break; /* C-cedilla */
			case 215: PUT_TO(text, 0xFE); break; /* thorn */
			case 216: PUT_TO(text, 0xF0); break; /* eth */
			case 217: PUT_TO(text, 0xDE); break; /* Thorn */
			case 218: PUT_TO(text, 0xD0); break; /* Eth */
			case 219: PUT_TO(text, 0xA3); break; /* pound sterling sign */
			case 220: PUT_TO(text, 0x153); break; /* oe */
			case 221: PUT_TO(text, 0x152); break; /* OE */
			case 222: PUT_TO(text, 0xA1); break; /* inverted ! */
			case 223: PUT_TO(text, 0xBF); break; /* inverted ? */
			default: @<Unknown string token@>; break;
		}
	}

@ Now for the digraphs. For example, |@'a| is an a-acute, while |@ss| is a
German sharp s. Again, see the DM4 for the specification of these. A misprint
in the DM4 means that one part of that manual says that |@cc| is the syntax
for c-cedilla, and another says it is |@,c|. To be on the safe side, we
recognise both. For similar reasons, we recognise both |@/o| and |@\o| as
a Scandinavian o-stroke.

@<Expand TeX-style digraph@> =
	wchar_t c = Str::get_at(token, 0);
	wchar_t d = Str::get_at(token, 1);
	switch (c) {
		case '\'': /* these are acute accents */
			switch (d) {
				case 'a': PUT_TO(text, 0xE1); break;
				case 'e': PUT_TO(text, 0xE9); break;
				case 'i': PUT_TO(text, 0xED); break;
				case 'o': PUT_TO(text, 0xF3); break;
				case 'u': PUT_TO(text, 0xFA); break;
				case 'y': PUT_TO(text, 0xFD); break;
				case 'A': PUT_TO(text, 0xC1); break;
				case 'E': PUT_TO(text, 0xC9); break;
				case 'I': PUT_TO(text, 0xCD); break;
				case 'O': PUT_TO(text, 0xD3); break;
				case 'U': PUT_TO(text, 0xDA); break;
				case 'Y': PUT_TO(text, 0xDD); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case '`': /* these are grave accents */
			switch (d) {
				case 'a': PUT_TO(text, 0xE0); break;
				case 'e': PUT_TO(text, 0xE8); break;
				case 'i': PUT_TO(text, 0xEC); break;
				case 'o': PUT_TO(text, 0xF2); break;
				case 'u': PUT_TO(text, 0xF9); break;
				case 'A': PUT_TO(text, 0xC0); break;
				case 'E': PUT_TO(text, 0xC8); break;
				case 'I': PUT_TO(text, 0xCC); break;
				case 'O': PUT_TO(text, 0xD2); break;
				case 'U': PUT_TO(text, 0xD9); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case '^': /* these are circumflex accents */
			switch (d) {
				case 'a': PUT_TO(text, 0xE2); break;
				case 'e': PUT_TO(text, 0xEA); break;
				case 'i': PUT_TO(text, 0xEE); break;
				case 'o': PUT_TO(text, 0xF4); break;
				case 'u': PUT_TO(text, 0xFB); break;
				case 'A': PUT_TO(text, 0xC2); break;
				case 'E': PUT_TO(text, 0xCA); break;
				case 'I': PUT_TO(text, 0xCE); break;
				case 'O': PUT_TO(text, 0xD4); break;
				case 'U': PUT_TO(text, 0xDB); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case ':': /* these are diarhesis accents, that is, umlauts */
			switch (d) {
				case 'a': PUT_TO(text, 0xE4); break;
				case 'e': PUT_TO(text, 0xEB); break;
				case 'i': PUT_TO(text, 0xEF); break;
				case 'o': PUT_TO(text, 0xF6); break;
				case 'u': PUT_TO(text, 0xFC); break;
				case 'y': PUT_TO(text, 0xFF); break;
				case 'A': PUT_TO(text, 0xC4); break;
				case 'E': PUT_TO(text, 0xCB); break;
				case 'I': PUT_TO(text, 0xCF); break;
				case 'O': PUT_TO(text, 0xD6); break;
				case 'U': PUT_TO(text, 0xDC); break;
				case 'Y': PUT_TO(text, 0x0178); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case '~': /* these are tilde accents */
			switch (d) {
				case 'a': PUT_TO(text, 0xE3); break;
				case 'n': PUT_TO(text, 0xF1); break;
				case 'o': PUT_TO(text, 0xF5); break;
				case 'A': PUT_TO(text, 0xC3); break;
				case 'N': PUT_TO(text, 0xD1); break;
				case 'O': PUT_TO(text, 0xD5); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case ',': case 'c': /* cedilla (a misprint in the DM4 means both are said to work) */
			switch (d) {
				case 'c': PUT_TO(text, 0xE7); break;
				case 'C': PUT_TO(text, 0xC7); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case '\\': case '/': /* the Scandinavian slash thing */
			switch (d) {
				case 'o': PUT_TO(text, 0xF8); break;
				case 'O': PUT_TO(text, 0xD8); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 'a': /* joined ae */
			switch (d) {
				case 'e': PUT_TO(text, 0xE6); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 'A': /* joined AE */
			switch (d) {
				case 'E': PUT_TO(text, 0xC6); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 'e': /* lower-case Icelandic eth */
			switch (d) {
				case 't': PUT_TO(text, 0xF0); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 'E': /* capital Icelandic eth */
			switch (d) {
				case 't': PUT_TO(text, 0xD0); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 't': /* lower-case thorn */
			switch (d) {
				case 'h': PUT_TO(text, 0xFE); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 'T': /* capital thorn */
			switch (d) {
				case 'h': PUT_TO(text, 0xCE); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 'L': /* pound sign */
			switch (d) {
				case 'L': PUT_TO(text, 0xA3); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case '!': /* inverted Spanish exclamation mark */
			if (d == '!') PUT_TO(text, 0xA1);
			else @<Unknown string token@>;
			break;
		case '?': /* inverted Spanish question mark */
			if (d == '?') PUT_TO(text, 0xBF);
			else @<Unknown string token@>;
			break;
		case '<': /* Double-angle open quotation mark */
			if (d == '<') PUT_TO(text, 0xAB);
			else @<Unknown string token@>;
			break;
		case '>': /* Double-angle close quotation mark */
			if (d == '>') PUT_TO(text, 0xBB);
			else @<Unknown string token@>;
			break;
		case 's': /* German sharp s */
			if (d == 's') PUT_TO(text, 0xDF);
			else @<Unknown string token@>;
			break;
		case 'o': /* joined oe and ring accent A */
			switch (d) {
				case 'a': PUT_TO(text, 0xE5); break;
				case 'A': PUT_TO(text, 0xC5); break;
				case 'e': PUT_TO(text, 0x153); break;
				default: @<Unknown string token@>; break;
			}
			break;
		case 'O': /* joined OE */
			switch (d) {
				case 'E': PUT_TO(text, 0x152); break;
				default: @<Unknown string token@>; break;
			}
			break;
		default:
			WRITE_TO(text, "TOKEN<%S>", token);
			break;
	}

@<Unknown string token@> =
	WRITE_TO(text, "@%S", token);

@

=
int Tokenisation::hex_val(wchar_t c) {
	if ((c >= '0') && (c <= '9')) return c - '0';
	if ((c >= 'a') && (c <= 'f')) return c - 'a' + 10;
	if ((c >= 'A') && (c <= 'F')) return c - 'A' + 10;
	return -1;
}

@ And similarly for single-quoted text notation, which shares some of the same
conventions. In fact I6 for some reason does not support the |@@...| decimal
notation within character or dictionary literals, throwing an error if it
is used; but we'll recognise it anyway, for the sake of using the same code as
is given above.

The tricky thing here is that single-quoted literals are characters if they
contain one character and do not have a |//| marker, but dictionary literals
otherwise. We need to know which because |^| is an escape character for a
single quotation mark in a dictionary literal, but not a character literal.

=
void Tokenisation::de_escape_sq_text(text_stream *text) {
	TEMPORARY_TEXT(raw)
	WRITE_TO(raw, "%S", text);
	Str::clear(text);
	int is_dictionary_word = FALSE;
	@<Determine if this is a character or dictionary literal@>;
	@<Expand the literal text@>;
	DISCARD_TEXT(raw)
}

@<Determine if this is a character or dictionary literal@> =
	int char_count = 0;
	for (int i=0; i<Str::len(raw); i++) {
		if ((Str::get_at(raw, i) == '/') && (Str::get_at(raw, i+1) == '/')) {
			is_dictionary_word = TRUE; break;
		}
		char_count++;
		if (Str::get_at(raw, i) == '@') {
			TEMPORARY_TEXT(token)
			int skip = 1, decimal = FALSE, hexadecimal = FALSE;
			@<Extract the escape token@>;
			i += skip-1;
			DISCARD_TEXT(token)
		}
	}
	if (char_count > 1) is_dictionary_word = TRUE;

@<Expand the literal text@> =
	for (int i=0; i<Str::len(raw); i++) {
		wchar_t c = Str::get_at(raw, i);
		if ((c == '/') && (Str::get_at(raw, i+1) == '/'))
			@<Past this point escape characters do not apply@>;
		if (c == '@') {
			TEMPORARY_TEXT(token)
			int skip = 1, decimal = FALSE, hexadecimal = FALSE;
			@<Extract the escape token@>;
			if (hexadecimal) @<Expand hexadecimal Unicode value@>
			else if (decimal) @<Expand decimal ZSCII value@>
			else @<Expand TeX-style digraph@>;
			i += skip-1;
			DISCARD_TEXT(token)
		} else {
			if ((c == '^') && (is_dictionary_word)) PUT_TO(text, '\'');
			else PUT_TO(text, c);
		}
	}

@<Past this point escape characters do not apply@> =
	while (i < Str::len(raw)) {
		PUT_TO(text, Str::get_at(raw, i));
		i++;
	}
	break;

@ Lastly, this defines valid identifier characters:

=
int Tokenisation::identchar(wchar_t c) {
	if ((Characters::isalnum(c)) || (c == '`')) return TRUE;
	return FALSE;
}
