[Strings::] Responses.

In this section we keep track of response texts.

@h Definitions.

@ Responses are texts -- which may be either literals or text substitutions --
occurring inside the body of rules, and marked out (A), (B), (C), ... within
that rule. This enables them to be manipulated or changed.

=
typedef struct response_message {
	struct rule *responding_rule; /* named rule in which this response occurs */
	int response_marker; /* 0 for A, 1 for B, and so on up */
	struct text_substitution *original_text;
	struct ph_stack_frame *original_stack_frame;
	struct inter_name *resp_iname;
	struct inter_name *constant_iname;
	struct package_request *resp_package;
	int launcher_compiled;
	int via_I6; /* if responding to a rule defined by I6 code, not source text */
	int via_I6_routine_compiled;
	MEMORY_MANAGEMENT
} response_message;

@ Continuing with our naming convention for text resources at runtime, here
is the "launcher" routine for a response:

=
inter_name *Strings::response_launcher_iname(response_message *resp) {
	return resp->resp_iname;
}

@ Each response is itself a value at run-time, and the following compiles
its name in the output code:

=
inter_name *Strings::response_constant_iname(rule *R, int marker) {
	response_message *RM = Rules::rule_defines_response(R, marker);
	if (RM == NULL) return NULL;
	if (RM->constant_iname == NULL) internal_error("no response value");
	return RM->constant_iname;
}

@ The following is called in response to a usage of a text followed by a
response marker; for example,

>> say "You can't open [the noun]." (A);

We compile it as the name of the response's "launcher" routine; that is, as
the launcher for response (A) of the rule currently being compiled.

The original text, |"You can't open [the noun]."| is then remembered as if
it were a text substitution -- as of course it is, but it may be supplanted
at run-time, or even before that. (For simplicity we choose to treat the text
as a substitution even if, in fact, it's just literal text.) All of the
problems usually attendant on text substitutions apply here, too; we
need to remember the stack frame for later.

Thus the above source text will produce not only a |TX_R_*| launcher routine,
but also (in most cases) a |TX_S_*| text substitution routine.

=
response_message *Strings::response_cue(value_holster *VH, rule *owner, int marker,
	wording W, ph_stack_frame *phsf, int via_I6) {
	response_message *resp = CREATE(response_message);
	resp->original_stack_frame = Frames::boxed_frame(phsf);
	resp->responding_rule = owner;
	resp->response_marker = marker;
	resp->original_text = Strings::TextSubstitutions::new_text_substitution(W, phsf, owner, marker, Rules::package(owner));
	resp->launcher_compiled = FALSE;
	resp->via_I6 = via_I6;
	resp->via_I6_routine_compiled = FALSE;
	resp->resp_package = Hierarchy::package_within(RESPONSES_HAP, Rules::package(resp->responding_rule));
	resp->resp_iname = InterNames::one_off(I"launcher", resp->resp_package);
	Inter::Symbols::set_flag(InterNames::to_symbol(resp->resp_iname), MAKE_NAME_UNIQUE);
	resp->constant_iname = InterNames::one_off(I"as_constant", resp->resp_package);
	Inter::Symbols::set_flag(InterNames::to_symbol(resp->constant_iname), MAKE_NAME_UNIQUE);
	if (VH) {
		if (Holsters::data_acceptable(VH)) {
			Emit::val_iname(K_value, Strings::response_launcher_iname(resp));
		}
	}
	return resp;
}

@ Response launchers can be compiled in sets, but not quite all at once.
The following code is quadratic in the number of responses, but it really
doesn't matter, since so little is done and the response count can't be
enormous.

=
void Strings::compile_response_launchers(void) {
	response_message *resp;
	LOOP_OVER(resp, response_message) {
		if (resp->launcher_compiled == FALSE) {
			resp->launcher_compiled = TRUE;
			@<Compile the actual launcher@>;
			if ((resp->via_I6) && (resp->via_I6_routine_compiled == FALSE))
				@<If the response is via I6, compile the necessary routine for this rule@>;
		}
	}
}

@ Each response is itself a value, and the launcher routine consists only of
a call to an activity based on that value:

@<Compile the actual launcher@> =
	package_request *R = resp->resp_package;
	inter_name *launcher =
		Packaging::function(InterNames::one_off(I"launcher_fn", R), R, NULL);
	Inter::Symbols::set_flag(InterNames::to_symbol(launcher), MAKE_NAME_UNIQUE);

	packaging_state save = Routines::begin(launcher);

	inter_name *iname = Strings::response_constant_iname(
		resp->responding_rule, resp->response_marker);

	inter_name *rname = Hierarchy::find(RESPONSEVIAACTIVITY_HL);
	Emit::inv_call(InterNames::to_symbol(rname));
	Emit::down();
	Emit::val_iname(K_value, iname);
	Emit::up();

	Routines::end(save);

	save = Packaging::enter(R);
	Emit::named_array_begin(resp->resp_iname, K_value);
	Emit::array_iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
	Emit::array_iname_entry(launcher);
	Emit::array_end();

	Packaging::exit(save);

@ Something skated over above is that responses can also be created when the
source text defines a rule only as an I6 routine. For example:

>> The hack mode rule translates into I6 as "HACK_MODE_ON_R" with "Hack mode on." (A).

Responses like this one are "via I6", and they cause us to create a support
routine for the rule, called in this case |HACK_MODE_ON_RM|. The rule then
calls

	|HACK_MODE_ON_RM('A');|

to produce response (A), or alternatively

	|HACK_MODE_ON_RM('a');|

to return the current text of (A) without printing it. Speed is not of the
essence here.

@<If the response is via I6, compile the necessary routine for this rule@> =
	inter_name *responder_iname = Rules::get_handler_definition(resp->responding_rule);
	packaging_state save = Routines::begin(responder_iname);
	inter_symbol *code_s = LocalVariables::add_named_call_as_symbol(I"code");
	inter_symbol *val_s = LocalVariables::add_named_call_as_symbol(I"val");
	inter_symbol *val2_s = LocalVariables::add_named_call_as_symbol(I"val2");
	inter_symbol *s_s = LocalVariables::add_internal_local_as_symbol(I"s");
	inter_symbol *s2_s = LocalVariables::add_internal_local_as_symbol(I"s2");
	inter_symbol *s3_s = LocalVariables::add_internal_local_as_symbol(I"s3");
	inter_symbol *str_s = LocalVariables::add_internal_local_as_symbol(I"str");
	inter_symbol *f_s = LocalVariables::add_internal_local_as_symbol(I"f");

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(and_interp);
		Emit::down();
			Emit::inv_primitive(ge_interp);
			Emit::down();
				Emit::val_symbol(K_value, code_s);
				Emit::val(K_number, LITERAL_IVAL, (inter_t) 'a');
			Emit::up();
			Emit::inv_primitive(le_interp);
			Emit::down();
				Emit::val_symbol(K_value, code_s);
				Emit::val(K_number, LITERAL_IVAL, (inter_t) 'z');
			Emit::up();
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, f_s);
				Emit::val(K_truth_state, LITERAL_IVAL, 1);
			Emit::up();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, code_s);
				Emit::inv_primitive(minus_interp);
				Emit::down();
					Emit::val_symbol(K_value, code_s);
					Emit::val(K_number, LITERAL_IVAL, (inter_t) ('a'-'A'));
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, s_s);
		Emit::val_iname(K_object, Hierarchy::find(NOUN_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, s2_s);
		Emit::val_iname(K_value, Hierarchy::find(SECOND_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, s3_s);
		Emit::val_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
		Emit::val_symbol(K_value, val_s);
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_object, Hierarchy::find(SECOND_HL));
		Emit::val_symbol(K_value, val2_s);
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
		Emit::val_symbol(K_value, val_s);
	Emit::up();

	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, code_s);
		Emit::code();
		Emit::down();
			response_message *r2;
			LOOP_OVER(r2, response_message) {
				if (r2->responding_rule == resp->responding_rule) {
					Emit::inv_primitive(case_interp);
					Emit::down();
						Emit::val(K_number, LITERAL_IVAL, (inter_t) ('A' + r2->response_marker));
						Emit::code();
						Emit::down();
							Emit::inv_primitive(store_interp);
							Emit::down();
								Emit::ref_symbol(K_value, str_s);
								Emit::val_iname(K_value, r2->resp_iname);
							Emit::up();
						Emit::up();
					Emit::up();
					r2->via_I6_routine_compiled = TRUE;
				}
			}
		Emit::up();
	Emit::up();

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(and_interp);
		Emit::down();
			Emit::val_symbol(K_value, str_s);
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::val_symbol(K_value, f_s);
				Emit::val(K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_call(InterNames::to_symbol(Hierarchy::find(TEXT_TY_SAY_HL)));
			Emit::down();
				Emit::val_symbol(K_value, str_s);
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_object, Hierarchy::find(NOUN_HL));
		Emit::val_symbol(K_value, s_s);
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_object, Hierarchy::find(SECOND_HL));
		Emit::val_symbol(K_value, s2_s);
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_object, Hierarchy::find(PARSED_NUMBER_HL));
		Emit::val_symbol(K_value, s3_s);
	Emit::up();

	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val_symbol(K_value, str_s);
	Emit::up();

	Routines::end(save);

@ So much for the launchers. We also have to compile the response values,
and some run-time tables which will enable the I6 template code to keep
track of the content of each response.

=
void Strings::compile_responses(void) {
	@<Compile the array holding the current text of each response@>;
	@<Compile the PrintResponse routine@>;
	@<Compile the Response Divisions array@>;
	Strings::TextSubstitutions::compile_text_routines_in_response_mode();
}

@ Note that each rule is allowed to tell us that it already has a better
text for the response than the one we first created.

@<Compile the array holding the current text of each response@> =
	rule *R;
	LOOP_OVER(R, rule) {
		int marker;
		for (marker = 0; marker < 26; marker++) {
			response_message *resp = Rules::rule_defines_response(R, marker);
			if (resp) {
				text_substitution *ts = resp->original_text;
				wording W = Rules::get_response_value(R, marker);
				if (Wordings::nonempty(W)) { /* i.e., if the rule gives us a better text */
					current_sentence = Rules::get_response_sentence(R, marker);
					ts = Strings::TextSubstitutions::new_text_substitution(W,
						NULL, R, marker, Rules::package(R));
					resp->original_text->dont_need_after_all = TRUE;
				}
				inter_name *ts_iname = Strings::TextSubstitutions::text_substitution_iname(ts);
				inter_name *rc_iname = Strings::response_constant_iname(R, marker);
				packaging_state save = Packaging::enter(rc_iname->eventual_owner);
				Emit::response(rc_iname, R, marker, ts_iname);
				Packaging::exit(save);
			}
		}
	}

@ This is in effect a big switch statement, so it's not fast; but as usual
with printing routines it really doesn't need to be. Given a response value,
say |R_14_RESP_B|, we print its current text, say response (B) for |R_14|.

@<Compile the PrintResponse routine@> =
	inter_name *printing_rule_name = Kinds::Behaviour::get_iname(K_response);
	packaging_state save = Routines::begin(printing_rule_name);
	inter_symbol *R_s = LocalVariables::add_named_call_as_symbol(I"R");
	response_message *resp;
	LOOP_OVER(resp, response_message) {
		inter_name *iname = Strings::response_constant_iname(resp->responding_rule,
			resp->response_marker);
		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::val_symbol(K_value, R_s);
				Emit::val_iname(K_value, iname);
			Emit::up();
			Emit::code();
			Emit::down();
				Emit::inv_call(InterNames::to_symbol(Rules::RulePrintingRule()));
				Emit::down();
					Emit::val_iname(K_value, Rules::iname(resp->responding_rule));
				Emit::up();
				Emit::inv_primitive(print_interp);
				Emit::down();
					Emit::val_text(I" response (");
				Emit::up();
				Emit::inv_primitive(printchar_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) ('A' + resp->response_marker));
				Emit::up();
				Emit::inv_primitive(print_interp);
				Emit::down();
					Emit::val_text(I")");
				Emit::up();
			Emit::up();
		Emit::up();
	}
	Routines::end(save);

@ The following array is used only by the testing command RESPONSES, and
enables the I6 template to print out all known responses at run-time,
divided up by the extensions containing the rules which produce them.

@<Compile the Response Divisions array@> =
	inter_name *iname = Hierarchy::find(RESPONSEDIVISIONS_HL);
	packaging_state save = Packaging::enter_home_of(iname);
	Emit::named_array_begin(iname, K_value);
	extension_file *group_ef = NULL;
	@<Make a ResponseDivisions entry@>;
	LOOP_OVER(group_ef, extension_file)
		@<Make a ResponseDivisions entry@>;
	Emit::array_numeric_entry(0);
	Emit::array_numeric_entry(0);
	Emit::array_numeric_entry(0);
	Emit::array_end();
	Packaging::exit(save);

@<Make a ResponseDivisions entry@> =
	rule *R;
	int tally = 0, contiguous_match = FALSE, no_cms = 0;
	LOOP_OVER(R, rule)
		for (int marker = 0; marker < 26; marker++)
			if (Rules::rule_defines_response(R, marker)) {
				tally++;
				extension_file *ef = SourceFiles::get_extension_corresponding(
					Lexer::file_of_origin(Wordings::first_wn(R->name)));
				if (ef == group_ef) @<Start a possible run of matches@>
				else @<End a possible run of matches@>;
			}
	@<End a possible run of matches@>;

@<Start a possible run of matches@> =
	if (contiguous_match == FALSE) {
		contiguous_match = TRUE;
		if (no_cms++ == 0) {
			TEMPORARY_TEXT(QT);
			WRITE_TO(QT, "%<X", Extensions::Files::get_eid(ef));
			Emit::array_text_entry(QT);
			DISCARD_TEXT(QT);
		} else
			Emit::array_iname_entry(Hierarchy::find(EMPTY_TEXT_PACKED_HL));
		Emit::array_numeric_entry((inter_t) (tally));
	}

@<End a possible run of matches@> =
	if (contiguous_match) {
		Emit::array_numeric_entry((inter_t) (tally-1));
		contiguous_match = FALSE;
	}

@ =
ph_stack_frame *Strings::frame_for_response(response_message *resp) {
	if (resp == NULL) return NULL;
	return resp->original_stack_frame;
}

@ As mentioned above, assertions in the source text can change the text of
a given response even at compile time. But the rules code looks after that:

=
void Strings::assert_response_value(rule *R, int marker, wording W) {
	Rules::now_rule_needs_response(R, marker, W);
}

@ When we index a response, we also provide a paste button for the source
text to assert a change:

=
void Strings::index_response(OUTPUT_STREAM, rule *R, int marker, response_message *resp) {
	WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
	HTML_OPEN_WITH("span",
		"style=\"color: #ffffff; "
		"font-family: 'Courier New', Courier, monospace; background-color: #8080ff;\"");
	WRITE("&nbsp;&nbsp;%c&nbsp;&nbsp; ", 'A' + marker);
	HTML_CLOSE("span");
	HTML_OPEN_WITH("span", "style=\"color: #000066;\"");
	WRITE("%+W", resp->original_text->unsubstituted_text);
	HTML_CLOSE("span");
	WRITE("&nbsp;&nbsp;");
	TEMPORARY_TEXT(S);
	WRITE_TO(S, "%+W response (%c)", R->name, 'A' + marker);
	HTML::Javascript::paste_stream(OUT, S);
	WRITE("&nbsp;<i>name</i>");
	WRITE("&nbsp;");
	Str::clear(S);
	WRITE_TO(S, "The %+W response (%c) is \"New text.\".");
	HTML::Javascript::paste_stream(OUT, S);
	WRITE("&nbsp;<i>set</i>");
	DISCARD_TEXT(S);
}

@ =
int Strings::get_marker_from_response_spec(parse_node *rs) {
	if (Rvalues::is_CONSTANT_of_kind(rs, K_response)) {
		wording SW = ParseTree::get_text(rs);
		if ((Wordings::length(SW) >= 2) && (<response-letter>(Wordings::one_word(Wordings::last_wn(SW)-1))))
			return <<r>>;
	}
	return -1;
}

@ To complete the code on strings, we just need the top-level routine which
handles the compilation of a general string literal. There are actually three
ways we might not even be compiling an I7 text value here:

(a) If the specification is flagged "explicit", we're using this as a device
to hold low-level I6 property values such as |parse_name| routines, and we
simply compile the text raw.
(b) If we're in quotation mode, that means the text is destined to be in an
I6 "box" statement, which needs it to be formed in an eccentric way.
(c) If we're in bibliographic mode, we're compiling not to the I6 program
but to something like an XML description of its metadata, where again the
text needs to be printed in a particular way.

=
void Strings::compile_general(value_holster *VH, parse_node *str) {
	wording SW = ParseTree::get_text(str);
	if (ParseTree::int_annotation(str, explicit_literal_ANNOT)) {
		if (ParseTree::get_explicit_iname(str)) {
			if (Holsters::data_acceptable(VH)) {
				InterNames::holster(VH, ParseTree::get_explicit_iname(str));
			} else internal_error("unvalued SCG");
		} else {
			int A = ParseTree::int_annotation(str, constant_number_ANNOT);
			if (Holsters::data_acceptable(VH))
				Holsters::holster_pair(VH, LITERAL_IVAL, (inter_t) A);
		}
	} else {
		if (Wordings::empty(SW)) internal_error("Text no longer available for CONSTANT/TEXT");
		if (TEST_COMPILATION_MODE(COMPILE_TEXT_TO_QUOT_CMODE)) {
			Strings::TextLiterals::compile_quotation(VH, SW);
		} else @<This is going to make a valid I7 text value@>;
	}
}

@ Responses take the form

	|"blah blah blah" ( letter )|

so the penultimate word, if it's there, is the letter.

@<This is going to make a valid I7 text value@> =
	if ((Wordings::length(SW) >= 2) && (<response-letter>(Wordings::one_word(Wordings::last_wn(SW)-1))))
		@<This is a response@>
	else @<This isn't a response@>;

@<This is a response@> =
	int code = <<r>>;
	if ((rule_being_compiled == NULL) ||
		(Rules::rule_is_named(rule_being_compiled) == FALSE)) {
		Problems::Issue::sentence_problem(_p_(PM_ResponseContextWrong),
			"lettered responses can only be used in named rules",
			"not in any of the other contexts in which quoted text can appear.");
		return;
	}
	if (Rules::rule_defines_response(rule_being_compiled, code)) {
		Problems::Issue::sentence_problem(_p_(PM_ResponseDuplicated),
			"this duplicates a response letter",
			"which is not allowed: if a bracketed letter like (A) is used to mark "
			"some text as a response, then it can only occur once in its rule.");
		return;
	}
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (Holsters::data_acceptable(VH)) {
		int downs = LocalVariables::emit_storage(phsf);
		response_message *resp =
			Strings::response_cue(VH, rule_being_compiled, code, SW,
				Frames::boxed_frame(phsf), FALSE);
		Rules::now_rule_defines_response(rule_being_compiled, code, resp);
		while (downs > 0) { Emit::up(); downs--; }
	}

@<This isn't a response@> =
	if (ParseTree::int_annotation(str, text_unescaped_ANNOT)) {
		literal_text *lt = Strings::TextLiterals::compile_literal_sb(VH, SW);
		Strings::TextLiterals::mark_as_unescaped(lt);
	} else if (Vocabulary::test_flags(Wordings::first_wn(SW), TEXTWITHSUBS_MC)) {
		Strings::TextSubstitutions::text_substitution_cue(VH, SW);
	} else {
		Strings::TextLiterals::compile_literal_sb(VH, SW);
	}
