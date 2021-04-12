[RTLiteralPatterns::] Literal Patterns at Run Time.

Compiled code to print and parse values expressed as literals.

@h Matching an LP at run-time.
The following routine compiles an I6 general parsing routine (GPR) to match
typed input in the correct notation. It amounts to printing out a version of
the above routine, but ported to I6, and with the token loop "rolled out"
so that no |tc| and |ec| variables are needed at run-time, and simplified
by having the numerical overflow detection removed. (It's a little slow to
perform that check within the VM.)

Properly speaking this is not an entire GPR, but only a segment of one,
and we should compile code which allows execution to reach the end if and only
if we fail to make a match.

=
void RTLiteralPatterns::gpr(gpr_kit *gprk, literal_pattern *lp) {
	int label = lp->allocation_id;
	int tc, ec;
	RTLiteralPatterns::comment_use_of_lp(lp);

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Emit::up();
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
	Emit::up();
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->matched_number_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Emit::up();

	TEMPORARY_TEXT(SL)
	WRITE_TO(SL, ".Succeeded_LP_%d", label);
	inter_symbol *succeeded_label = Produce::reserve_label(Emit::tree(), SL);
	DISCARD_TEXT(SL)
	TEMPORARY_TEXT(FL)
	WRITE_TO(FL, ".Failed_LP_%d", label);
	inter_symbol *failed_label = Produce::reserve_label(Emit::tree(), FL);
	DISCARD_TEXT(FL)

	for (tc=0, ec=0; tc<lp->no_lp_tokens; tc++) {
		int lookahead = -1;
		if ((tc+1<lp->no_lp_tokens) && (lp->lp_tokens[tc+1].lpt_type == CHARACTER_LPT))
			lookahead = (int) (lp->lp_tokens[tc+1].token_char);
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->mid_word_s);
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, gprk->cur_word_s);
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NEXTWORDSTOPPED_HL));
				Emit::up();
				Produce::inv_primitive(Emit::tree(), POSTDECREMENT_BIP);
				Emit::down();
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Emit::up();
				inter_symbol *to_label = NULL;
				if ((lp->lp_elements[ec].preamble_optional) && (lp->lp_tokens[tc].lpt_type == ELEMENT_LPT))
					to_label = failed_label;
				else if (LiteralPatterns::at_optional_break_point(lp, ec, tc))
					to_label = succeeded_label;
				else
					to_label = failed_label;
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->cur_word_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) -1);
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), JUMP_BIP);
						Emit::down();
							Produce::lab(Emit::tree(), to_label);
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();

		switch (lp->lp_tokens[tc].lpt_type) {
			case WORD_LPT: @<Compile I6 code to match a fixed word token within a literal pattern@>; break;
			case CHARACTER_LPT: @<Compile I6 code to match a character token within a literal pattern@>; break;
			case ELEMENT_LPT: @<Compile I6 code to match an element token within a literal pattern@>; break;
			default: internal_error("unknown literal pattern token type");
		}
	}

	Produce::place_label(Emit::tree(), succeeded_label);

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::val_symbol(Emit::tree(), K_value, gprk->mid_word_s);
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), LT_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->sgn_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->matched_number_s);
				if (Kinds::FloatingPoint::uses_floating_point(lp->kind_specified)) {
					Produce::inv_primitive(Emit::tree(), BITWISEOR_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->matched_number_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0x80000000);
					Emit::up();
				} else {
					Produce::inv_primitive(Emit::tree(), TIMES_BIP);
					Emit::down();
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) -1);
						Produce::val_symbol(Emit::tree(), K_value, gprk->matched_number_s);
					Emit::up();
				}
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_iname(Emit::tree(), K_object, Hierarchy::find(PARSED_NUMBER_HL));
		Produce::val_symbol(Emit::tree(), K_value, gprk->matched_number_s);
	Emit::up();

	Kinds::Scalings::compile_quanta_to_value(lp->scaling,
		Hierarchy::find(PARSED_NUMBER_HL), gprk->sgn_s, gprk->x_s, failed_label);

	Produce::inv_primitive(Emit::tree(), IFDEBUG_BIP);
	Emit::down();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), GE_BIP);
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PARSER_TRACE_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Emit::down();
						Produce::val_text(Emit::tree(), I"  [parsed value ");
					Emit::up();
					Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
					Emit::down();
						Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(PARSED_NUMBER_HL));
					Emit::up();
					Produce::inv_primitive(Emit::tree(), PRINT_BIP);
					Emit::down();
						TEMPORARY_TEXT(EXP)
						WRITE_TO(EXP, " by: %W]\n", lp->prototype_text);
						Produce::val_text(Emit::tree(), EXP);
						DISCARD_TEXT(EXP)
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Emit::down();
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPR_NUMBER_HL));
	Emit::up();
	Produce::place_label(Emit::tree(), failed_label);
}

@<Compile I6 code to match a fixed word token within a literal pattern@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::val_symbol(Emit::tree(), K_value, gprk->mid_word_s);
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), NE_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->cur_word_s);
			TEMPORARY_TEXT(N)
			WRITE_TO(N, "%N", lp->lp_tokens[tc].token_wn);
			Produce::val_dword(Emit::tree(), N);
			DISCARD_TEXT(N)
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
	Emit::down();
		Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
	Emit::up();

@<Compile I6 code to match a character token within a literal pattern@> =
	@<Compile I6 code to enter mid-word parsing if not already in it@>;
	wchar_t lower_form = Characters::tolower(lp->lp_tokens[tc].token_char);
	wchar_t upper_form = Characters::toupper(lp->lp_tokens[tc].token_char);

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		if (upper_form != lower_form) { Produce::inv_primitive(Emit::tree(), AND_BIP); Emit::down(); }
		Produce::inv_primitive(Emit::tree(), NE_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
				Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
				Emit::up();
			Emit::up();
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) lower_form);
		Emit::up();
		if (upper_form != lower_form) {
			Produce::inv_primitive(Emit::tree(), NE_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
					Produce::inv_primitive(Emit::tree(), MINUS_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Emit::up();
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) upper_form);
			Emit::up();
		}
		if (upper_form != lower_form) { Emit::up(); }
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		Emit::up();
	Emit::up();

	@<Compile I6 code to exit mid-word parsing if at end of a word@>;

@<Compile I6 code to match an element token within a literal pattern@> =
	@<Compile I6 code to enter mid-word parsing if not already in it@>;
	literal_pattern_element *lpe = &(lp->lp_elements[ec++]);
	if (ec == 1) {
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Emit::down();
			Produce::ref_symbol(Emit::tree(), K_value, gprk->sgn_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Emit::up();
	}
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
				Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Emit::up();
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) '-');
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
		if ((lp->number_signed) && (ec == 1)) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->sgn_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) -1);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Emit::up();
		} else {
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		}
		Emit::up();
	Emit::up();

	if (Kinds::FloatingPoint::uses_floating_point(lp->kind_specified))
		@<Compile I6 code to match a real number here@>
	else
		@<Compile I6 code to match an integer here@>;
	@<Compile I6 code to exit mid-word parsing if at end of a word@>;

@<Compile I6 code to match a real number here@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
	Emit::up();
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->x_s);
		Produce::inv_primitive(Emit::tree(), PLUS_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
			Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
		Emit::up();
	Emit::up();
	@<March forwards through decimal digits@>;
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->cur_word_s);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NEXTWORDSTOPPED_HL));
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Produce::inv_primitive(Emit::tree(), MINUS_BIP);
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
				Emit::up();
			Emit::up();
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, gprk->cur_word_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(THEN1__WD_HL));
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Emit::down();
						Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
						Produce::inv_primitive(Emit::tree(), PLUS_BIP);
						Emit::down();
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
						Emit::up();
					Emit::up();
					Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
					Emit::up();
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
					Emit::up();
					Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
					Emit::up();
					@<Compile I6 code to enter mid-word parsing if not already in it@>;
					@<March forwards through decimal digits@>;
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->tot_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->tot_s);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->cur_word_s);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NEXTWORDSTOPPED_HL));
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
			@<Compile I6 code to enter mid-word parsing if not already in it@>;
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), AND_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LT_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
				Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
					Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) 'x');
			Emit::up();
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
				Produce::inv_primitive(Emit::tree(), PLUS_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), PLUS_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
						Produce::val_symbol(Emit::tree(), K_value, gprk->tot_s);
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
				Emit::up();
			Emit::up();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Emit::up();

			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
					Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
					Emit::up();
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->cur_word_s);
						Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NEXTWORDSTOPPED_HL));
					Emit::up();
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
					Emit::up();
					@<Compile I6 code to enter mid-word parsing if not already in it@>;
				Emit::up();
			Emit::up();

			Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), AND_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LT_BIP);
					Emit::down();
						Produce::inv_primitive(Emit::tree(), PLUS_BIP);
						Emit::down();
							Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
						Emit::up();
						Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
					Emit::up();
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Emit::down();
						Produce::inv_primitive(Emit::tree(), EQ_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
							Emit::down();
								Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
								Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
							Emit::up();
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) '1');
						Emit::up();
						Produce::inv_primitive(Emit::tree(), AND_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), EQ_BIP);
							Emit::down();
								Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
								Emit::down();
									Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
									Produce::inv_primitive(Emit::tree(), PLUS_BIP);
									Emit::down();
										Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
										Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
									Emit::up();
								Emit::up();
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) '0');
							Emit::up();
							Produce::inv_primitive(Emit::tree(), EQ_BIP);
							Emit::down();
								Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
								Emit::down();
									Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
									Produce::inv_primitive(Emit::tree(), PLUS_BIP);
									Emit::down();
										Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
										Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
									Emit::up();
								Emit::up();
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) '^');
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
						Produce::inv_primitive(Emit::tree(), PLUS_BIP);
						Emit::down();
							Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
						Emit::up();
					Emit::up();
					Produce::inv_primitive(Emit::tree(), STORE_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
						Produce::inv_primitive(Emit::tree(), PLUS_BIP);
						Emit::down();
							Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
						Emit::up();
					Emit::up();
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Emit::down();
						Produce::inv_primitive(Emit::tree(), AND_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), LT_BIP);
							Emit::down();
								Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
								Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
							Emit::up();
							Produce::inv_primitive(Emit::tree(), OR_BIP);
							Emit::down();
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Emit::down();
									Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
									Emit::down();
										Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
										Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
									Emit::up();
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) '+');
								Emit::up();
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Emit::down();
									Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
									Emit::down();
										Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
										Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
									Emit::up();
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) '-');
								Emit::up();
							Emit::up();
						Emit::up();
						Produce::code(Emit::tree());
						Emit::down();
							Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
							Emit::down();
								Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
							Emit::up();
							Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
							Emit::down();
								Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
							Emit::up();
						Emit::up();
					Emit::up();
					@<March forwards through decimal digits@>;
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::inv_primitive(Emit::tree(), POSTDECREMENT_BIP);
					Emit::down();
						Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->x_s);
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(FLOATPARSE_HL));
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->x_s);
			Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->x_s);
			Produce::val_symbol(Emit::tree(), K_value, Site::veneer_symbol(Emit::tree(), FLOAT_NAN_VSYMB));
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->matched_number_s);
		Produce::val_symbol(Emit::tree(), K_value, gprk->x_s);
	Emit::up();

@<March forwards through decimal digits@> =
	Produce::inv_primitive(Emit::tree(), WHILE_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), AND_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LT_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
				Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), GE_BIP);
			Emit::down();
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DIGITTOVALUE_HL));
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
						Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
					Emit::up();
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Emit::up();
		Emit::up();
	Emit::up();

@<Compile I6 code to match an integer here@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->tot_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Emit::up();
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
	Emit::up();

	Produce::inv_primitive(Emit::tree(), WHILE_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), AND_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LT_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
				Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), GE_BIP);
			Emit::down();
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DIGITTOVALUE_HL));
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
						Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
					Emit::up();
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DIGITTOVALUE_HL));
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
						Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
					Emit::up();
				Emit::up();
			Emit::up();
			Kinds::Scalings::compile_scale_and_add(gprk->tot_s, gprk->sgn_s, 10, 0, gprk->f_s, failed_label);
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), failed_label);
			Emit::up();
		Emit::up();
	Emit::up();

	if (lpe->element_index > 0) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), GE_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->tot_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) lpe->element_range);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), JUMP_BIP);
				Emit::down();
					Produce::lab(Emit::tree(), failed_label);
				Emit::up();
			Emit::up();
		Emit::up();
	}

	Kinds::Scalings::compile_scale_and_add(gprk->tot_s, gprk->sgn_s, lpe->element_multiplier, 0, gprk->matched_number_s, failed_label);
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, gprk->matched_number_s);
		Produce::val_symbol(Emit::tree(), K_value, gprk->tot_s);
	Emit::up();

	int M = Kinds::Scalings::get_integer_multiplier(lp->scaling);
	if (M > 1) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
				Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
				Emit::down();
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Emit::up();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, gprk->cur_word_s);
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NEXTWORDSTOPPED_HL));
				Emit::up();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
					Produce::inv_primitive(Emit::tree(), MINUS_BIP);
					Emit::down();
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
					Emit::up();
				Emit::up();
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, gprk->cur_word_s);
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(THEN1__WD_HL));
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
							Produce::inv_primitive(Emit::tree(), PLUS_BIP);
							Emit::down();
								Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
							Emit::up();
						Emit::up();
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
							Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
						Emit::up();
						@<Compile I6 code to enter mid-word parsing if not already in it@>;
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_symbol(Emit::tree(), K_value, gprk->x_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
						Emit::up();
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) M);
						Emit::up();
						Produce::inv_primitive(Emit::tree(), WHILE_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), AND_BIP);
							Emit::down();
								Produce::inv_primitive(Emit::tree(), GT_BIP);
								Emit::down();
									Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
								Emit::up();
								Produce::inv_primitive(Emit::tree(), AND_BIP);
								Emit::down();
									Produce::inv_primitive(Emit::tree(), EQ_BIP);
									Emit::down();
										Produce::inv_primitive(Emit::tree(), MODULO_BIP);
										Emit::down();
											Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
											Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
										Emit::up();
										Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
									Emit::up();
									Produce::inv_primitive(Emit::tree(), GE_BIP);
									Emit::down();
										Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DIGITTOVALUE_HL));
										Emit::down();
											Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
											Emit::down();
												Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
												Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
											Emit::up();
										Emit::up();
										Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
									Emit::up();
								Emit::up();
							Emit::up();
							Produce::code(Emit::tree());
							Emit::down();
								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Emit::down();
									Produce::ref_symbol(Emit::tree(), K_value, gprk->w_s);
									Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
									Emit::down();
										Produce::inv_primitive(Emit::tree(), TIMES_BIP);
										Emit::down();
											Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DIGITTOVALUE_HL));
											Emit::down();
												Produce::inv_primitive(Emit::tree(), LOOKUPBYTE_BIP);
												Emit::down();
													Produce::val_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
													Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
												Emit::up();
											Emit::up();
											Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
										Emit::up();
										Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
									Emit::up();
								Emit::up();
								Kinds::Scalings::compile_scale_and_add(gprk->x_s, gprk->sgn_s,
									1, 0, gprk->w_s, failed_label);
								Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
								Emit::down();
									Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
								Emit::up();
								Produce::inv_primitive(Emit::tree(), STORE_BIP);
								Emit::down();
									Produce::ref_symbol(Emit::tree(), K_value, gprk->f_s);
									Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
									Emit::down();
										Produce::val_symbol(Emit::tree(), K_value, gprk->f_s);
										Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
									Emit::up();
								Emit::up();
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	}

@<Compile I6 code to enter mid-word parsing if not already in it@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->mid_word_s);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->wpos_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->cur_addr_s);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(WORDADDRESS_HL));
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Emit::up();
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->cur_len_s);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(WORDLENGTH_HL));
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

@<Compile I6 code to exit mid-word parsing if at end of a word@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, gprk->wpos_s);
			Produce::val_symbol(Emit::tree(), K_value, gprk->cur_len_s);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Emit::down();
				Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(WN_HL));
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, gprk->mid_word_s);
				Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
	Emit::up();

@h Printing the I6 variable |value| out in an LP's notation at run-time.

=
void RTLiteralPatterns::printing_routine(inter_name *iname, literal_pattern *lp_list) {
	packaging_state save = Functions::begin(iname);

	literal_pattern_name *lpn;
	literal_pattern *lp;
	int k;
	inter_symbol *value_s = LocalVariables::new_other_as_symbol(I"value");
	inter_symbol *which_s = LocalVariables::new_other_as_symbol(I"which");
	inter_symbol *rem_s = LocalVariables::new_internal_as_symbol(I"rem");
	inter_symbol *S_s = LocalVariables::new_internal_as_symbol(I"S");

	LOOP_OVER(lpn, literal_pattern_name) {
		if (Wordings::nonempty(lpn->notation_name)) {
			k = 0;
			for (lp = lp_list; lp; lp = lp->next_for_this_kind)
				lp->marked_for_printing = FALSE;
			literal_pattern_name *lpn2;
			for (lpn2 = lpn; lpn2; lpn2 = lpn2->next)
				for (lp = lp_list; lp; lp = lp->next_for_this_kind)
					if (lp == lpn2->can_use_this_lp) {
						k++; lp->marked_for_printing = TRUE;
					}
			if (k > 0) {
				TEMPORARY_TEXT(C)
				WRITE_TO(C, "The named notation: %W", lpn->notation_name);
				Emit::code_comment(C);
				DISCARD_TEXT(C)
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, which_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lpn->allocation_id + 1));
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						@<Compile code to jump to the correct printing pattern@>;
					Emit::up();
				Emit::up();
			}
		}
	}

	@<Choose which patterns are eligible for printing@>;
	@<Compile code to jump to the correct printing pattern@>;

	Produce::rtrue(Emit::tree());

	for (lp = lp_list; lp; lp = lp->next_for_this_kind) {
		@<Print according to this particular literal pattern@>;
		Produce::rtrue(Emit::tree());
	}
	Functions::end(save);
}

@ This was at one time a more complicated criterion, which masked bugs in
the sorting measure.

@<Choose which patterns are eligible for printing@> =
	for (k=0, lp = lp_list; lp; lp = lp->next_for_this_kind) {
		int eligible = FALSE;
		if (lp->equivalent_unit == FALSE) eligible = TRUE;
		if (eligible) k++;
		lp->marked_for_printing = eligible;
	}

@<Compile code to jump to the correct printing pattern@> =
	literal_pattern *lpb = NULL;
	for (lp = lp_list; lp; lp = lp->next_for_this_kind)
		if (lp->marked_for_printing)
			if (lp->benchmark)
				lpb = lp;

	if ((lpb) && (lpb->singular_form_only == FALSE)) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, value_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), JUMP_BIP);
				Emit::down();
					Produce::lab(Emit::tree(), RTLiteralPatterns::jump_label(lpb));
				Emit::up();
			Emit::up();
		Emit::up();
	}

	literal_pattern *last_lp = NULL, *last_primary = NULL, *last_singular = NULL, *last_plural = NULL;

	for (lp = lp_list; lp; lp = lp->next_for_this_kind) {
		if (lp->marked_for_printing) {
			inter_ti op = GE_BIP; last_lp = lp;
			if (lp->primary_alternative) { last_primary = lp; }
			if (lp->singular_form_only) { last_singular = lp; op = EQ_BIP; }
			if (lp->plural_form_only) { last_plural = lp; op = GT_BIP; }
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
				Kinds::Scalings::compile_threshold_test(lp->scaling, value_s, op);
				Produce::code(Emit::tree());
				Emit::down();
					Produce::inv_primitive(Emit::tree(), JUMP_BIP);
					Emit::down();
						Produce::lab(Emit::tree(), RTLiteralPatterns::jump_label(lp));
					Emit::up();
				Emit::up();
			Emit::up();
		}
	}

	if (last_primary) last_lp = last_primary;
	if (last_lp) {
		if ((last_lp->singular_form_only) &&
			(last_plural) &&
			(Kinds::Scalings::compare(last_plural->scaling, last_lp->scaling) == 0)) {
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), RTLiteralPatterns::jump_label(last_plural));
			Emit::up();
		}
		Produce::inv_primitive(Emit::tree(), JUMP_BIP);
		Emit::down();
			Produce::lab(Emit::tree(), RTLiteralPatterns::jump_label(last_lp));
		Emit::up();
	}

@<Print according to this particular literal pattern@> =
	RTLiteralPatterns::comment_use_of_lp(lp);
	Produce::place_label(Emit::tree(), RTLiteralPatterns::jump_label(lp));

	int ec=0, oc=0;
	for (int tc=0; tc<lp->no_lp_tokens; tc++) {
		if (lp->lp_elements[ec].preamble_optional)
			@<Truncate the printed form here if subsequent numerical parts are zero@>;
		if ((tc>0) && (lp->lp_tokens[tc].new_word_at)) {
			Produce::inv_primitive(Emit::tree(), PRINT_BIP);
			Emit::down();
				Produce::val_text(Emit::tree(), I" ");
			Emit::up();
		}
		switch (lp->lp_tokens[tc].lpt_type) {
			case WORD_LPT: @<Compile I6 code to print a fixed word token within a literal pattern@>; break;
			case CHARACTER_LPT: @<Compile I6 code to print a character token within a literal pattern@>; break;
			case ELEMENT_LPT: @<Compile I6 code to print an element token within a literal pattern@>; break;
			default: internal_error("unknown literal pattern token type");
		}
	}

@<Compile I6 code to print a fixed word token within a literal pattern@> =
	TEMPORARY_TEXT(T)
	CompiledText::from_wide_string(T, Lexer::word_raw_text(lp->lp_tokens[tc].token_wn), CT_RAW);
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Emit::down();
		Produce::val_text(Emit::tree(), T);
	Emit::up();
	DISCARD_TEXT(T)

@<Compile I6 code to print a character token within a literal pattern@> =
	TEMPORARY_TEXT(T)
	TEMPORARY_TEXT(tiny_string)
	PUT_TO(tiny_string, (int) lp->lp_tokens[tc].token_char);
	CompiledText::from_stream(T, tiny_string, CT_RAW);
	DISCARD_TEXT(tiny_string)
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Emit::down();
		Produce::val_text(Emit::tree(), T);
	Emit::up();
	DISCARD_TEXT(T)

@<Compile I6 code to print an element token within a literal pattern@> =
	literal_pattern_element *lpe = &(lp->lp_elements[ec]);
	if (lpe->element_optional)
		@<Truncate the printed form here if subsequent numerical parts are zero@>;
	oc = ec + 1;
	if (lp->no_lp_elements == 1) {
		Kinds::Scalings::compile_print_in_quanta(lp->scaling, value_s, rem_s, S_s);
	} else {
		if (ec == 0) {
			if (lp->number_signed) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Emit::down();
						Produce::inv_primitive(Emit::tree(), LT_BIP);
						Emit::down();
							Produce::val_symbol(Emit::tree(), K_value, value_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
						Emit::up();
						Produce::inv_primitive(Emit::tree(), EQ_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
							Emit::down();
								Produce::val_symbol(Emit::tree(), K_value, value_s);
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lpe->element_multiplier));
							Emit::up();
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
						Emit::up();
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), PRINT_BIP);
						Emit::down();
							Produce::val_text(Emit::tree(), I"-");
						Emit::up();
					Emit::up();
				Emit::up();
			}
			Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, value_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lpe->element_multiplier));
				Emit::up();
			Emit::up();
			if (lp->number_signed) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LT_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, value_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Emit::down();
							Produce::ref_symbol(Emit::tree(), K_value, value_s);
							Produce::inv_primitive(Emit::tree(), MINUS_BIP);
							Emit::down();
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
								Produce::val_symbol(Emit::tree(), K_value, value_s);
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			}
		} else {
			if ((lp->lp_tokens[tc].new_word_at == FALSE) &&
				(lpe->without_leading_zeros == FALSE)) {
				int pow = 1;
				for (pow = 1000000000; pow>1; pow = pow/10)
					if (lpe->element_range > pow) {
						Produce::inv_primitive(Emit::tree(), IF_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), LT_BIP);
							Emit::down();
								Produce::inv_primitive(Emit::tree(), MODULO_BIP);
								Emit::down();
									Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
									Emit::down();
										Produce::val_symbol(Emit::tree(), K_value, value_s);
										Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lpe->element_multiplier));
									Emit::up();
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lpe->element_range));
								Emit::up();
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (pow));
							Emit::up();
							Produce::code(Emit::tree());
							Emit::down();
								Produce::inv_primitive(Emit::tree(), PRINT_BIP);
								Emit::down();
									Produce::val_text(Emit::tree(), I"0");
								Emit::up();
							Emit::up();
						Emit::up();

					}
			}
			Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), MODULO_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, value_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lpe->element_multiplier));
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lpe->element_range));
				Emit::up();
			Emit::up();
		}
	}
	ec++;

@<Truncate the printed form here if subsequent numerical parts are zero@> =
	if (oc == ec) {
		if (ec == 0) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, value_s);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lp->lp_elements[ec].element_multiplier));
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::rtrue(Emit::tree());
				Emit::up();
			Emit::up();
		} else {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), MODULO_BIP);
					Emit::down();
						Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
						Emit::down();
							Produce::val_symbol(Emit::tree(), K_value, value_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lp->lp_elements[ec].element_multiplier));
						Emit::up();
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (lp->lp_elements[ec].element_range));
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::rtrue(Emit::tree());
				Emit::up();
			Emit::up();
		}
		oc = ec + 1;
	}

@ =
inter_symbol *RTLiteralPatterns::jump_label(literal_pattern *lp) {
	if (lp->jump_label == NULL) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, ".Use_LP_%d", lp->allocation_id);
		lp->jump_label = Produce::reserve_label(Emit::tree(), N);
		DISCARD_TEXT(N)
	}
	return lp->jump_label;
}

@ =
void RTLiteralPatterns::comment_use_of_lp(literal_pattern *lp) {
	TEMPORARY_TEXT(W)
	WRITE_TO(W, "%W, ", lp->prototype_text);
	Kinds::Scalings::describe(W, lp->scaling);
	Emit::code_comment(W);
	DISCARD_TEXT(W)
}

@ =
void RTLiteralPatterns::log_lp_debugging_data(literal_pattern *lp) {
	TEMPORARY_TEXT(W)
	WRITE_TO(W, "%s %s LP%d: primary %d, s/p: %d/%d\n",
		(lp->benchmark)?"***":"---",
		(lp->equivalent_unit)?"equiv":"new  ",
		lp->allocation_id, lp->primary_alternative,
		lp->singular_form_only, lp->plural_form_only);
	Emit::code_comment(W);
	DISCARD_TEXT(W)
	RTLiteralPatterns::comment_use_of_lp(lp);
}
