[ParseName::] Parse Name Properties.

Functions which are values of the parse_name property for objects.

@h Introduction.
A |parse_name| property can belong to any instance of a kind of object, or to
any kind of object, but not to |K_object| itself. Its value must be a GPR
(see //General Parsing Routines//) which matches as many words as possible from
the command parser's stream of words, beginning at word number |wn|.

The following returns the iname for the function to be used as the |parse_name|
property of an inference subject |subj|, causing it to be compiled later; or
else returns |NULL| is none is needed.

The obvious reason it could be needed is if there is some syntax a player could
type to refer to the subject. But in fact we also need to make a GPR as a
"distinguisher" in a few cases where there is no such syntax, because of the
way the runtime command parser uses |parse_name| functions to determine whether
two objects can be distinguished by anything the player types. Recall that some
properties are "visible", in that the player can use them adjectically in
commands: for instance, if colour is a visible property of a car, then it can be
called "green car" if in fact its colour is green, and so on. The command parser
therefore calls |parse_name| functions at runtime to ask about distinguishability
as well as for parsing, so that's another reason we might need one.

The test case |AwkwardParseNames| may be helpful here.

=
inter_name *ParseName::compile_if_needed(inference_subject *subj) {
	inter_name *iname = Name::get_parse_name_fn_iname(subj);
	command_grammar *cg = PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_subject;
	if (CommandGrammars::is_empty(cg) == FALSE) {
		text_stream *desc = Str::new();
		wording W = InferenceSubjects::get_name_text(subj);
		WRITE_TO(desc, "grammar-parsing GPR for '%W'", W);
		Sequence::queue(&ParseName::parser_agent,
			STORE_POINTER_inference_subject(subj), desc);
		return iname;
	}
	if (Visibility::any_property_visible_to_subject(subj, FALSE)) {
		text_stream *desc = Str::new();
		wording W = InferenceSubjects::get_name_text(subj);
		WRITE_TO(desc, "distinguish-only GPR for '%W'", W);
		Sequence::queue(&ParseName::distinguisher_agent,
			STORE_POINTER_inference_subject(subj), desc);
		return iname;
	}
	return NULL;
}

@ This GPR never matches anything, so is very simple to compile.

=
void ParseName::distinguisher_agent(compilation_subtask *t) {
	inference_subject *subj = RETRIEVE_POINTER_inference_subject(t->data);
	gpr_kit kit = GPRs::new_kit();
	packaging_state save = Functions::begin(Name::get_parse_name_fn_iname(subj));
	ParseName::compile_head(&kit, subj, FALSE);
	ParseName::compile_tail(&kit);
	Functions::end(save);
}

@ This one can be much more elaborate, but is still simple to compile because
all of the work is delegated:

=
void ParseName::parser_agent(compilation_subtask *t) {
	inference_subject *subj = RETRIEVE_POINTER_inference_subject(t->data);
	command_grammar *cg = PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_subject;
	gpr_kit kit = GPRs::new_kit();
	packaging_state save = Functions::begin(Name::get_parse_name_fn_iname(subj));
	ParseName::compile_head(&kit, subj, TRUE);
	RTCommandGrammars::compile_for_subject_GPR(&kit, cg);
	ParseName::compile_tail(&kit);
	Functions::end(save);
}

@h The head.
Either way, then, the head and the tail are mostly the same. Here is the head.

Most of the function lives inside a loop making three passes, with |pass| running
from 1 to 3. In these passes, we will check:

(1) (words in |name| property) (visible property names) (words in |name| property)
(longer grammar) (words in |name| property)
(2) (visible property names) (longer grammar) (words in |name| property)
(3) (longer grammar) (words in |name| property)

Whichever is the longest match over these three passes will be the one taken: 
but note that a match of visible property names alone is rejected unless at least
one property has been declared sufficient to identify the object all by itself.

"Longer grammar" means grammar lines containing 2 or more words, since all
single-fixed-word grammar lines for CGs destined to be |parse_name|s is stripped
out and converted into the |name| property.

=
void ParseName::compile_head(gpr_kit *kit, inference_subject *subj, int there_is_grammar) {
	int test_distinguishability = FALSE;
	if (KindSubjects::to_kind(subj)) test_distinguishability = TRUE;

	GPRs::add_parse_name_vars(kit);
	@<Compile command parser tracing@>;

	@<Quickly disclaim the distinguishability test if possible@>;

	@<Save word number@>;
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->pass_s);
		EmitCode::val_number(1);
	EmitCode::up();
	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::inv(LE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->pass_s);
			EmitCode::val_number(3);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Reset word number@>;
			@<Begin body of the three-pass loop@>;
}

@<Compile command parser tracing@> =
	EmitCode::inv(IFDEBUG_BIP);
	EmitCode::down();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(GE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TRACE_HL));
					EmitCode::val_number(3);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I"Parse_name called\n");
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@ If the command parser is giving us the opportunity to say whether objects
with this |parse_name| function are distinguishable, it will do that by
having set |parser_action| to |##TheSame|. Here we return "make no decision"
to that, which disclaims responsibility, and forces the command parser to look
directly at the |name| properties of the objects instead.

@<Quickly disclaim the distinguishability test if possible@> =
	if ((there_is_grammar) &&
		(Visibility::any_property_visible_to_subject(subj, TRUE) == FALSE)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(THESAME_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_number(0);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}

@<Begin body of the three-pass loop@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->try_from_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->f_s);
		EmitCode::val_false();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->n_s);
		EmitCode::val_number(0);
	EmitCode::up();
	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::val_number(1);
		EmitCode::code();
		EmitCode::down();
			@<Begin body of the indefinite loop@>;

@<Begin body of the indefinite loop@> =
	/* On pass 1 only, advance |wn| past name property words */
	/* (but do not do this for |##TheSame|, when |wn| is undefined) */
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(THESAME_HL));
			EmitCode::up();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->pass_s);
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(WHILE_BIP);
			EmitCode::down();
				EmitCode::call(Hierarchy::find(WORDINPROPERTY_HL));
				EmitCode::down();
					EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, RTProperties::iname(ParsingPlugin::name_property()));
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, kit->f_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(POSTDECREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->try_from_wn_s);
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(OR_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->pass_s);
				EmitCode::val_number(1);
			EmitCode::up();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->pass_s);
				EmitCode::val_number(2);
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
		ParseName::consider_visible_properties(kit, subj, test_distinguishability);
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(THESAME_HL));
			EmitCode::up();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->pass_s);
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(WHILE_BIP);
			EmitCode::down();
				EmitCode::call(Hierarchy::find(WORDINPROPERTY_HL));
				EmitCode::down();
					EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, RTProperties::iname(ParsingPlugin::name_property()));
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, kit->f_s);
						EmitCode::val_true();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(POSTDECREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->try_from_wn_s);
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<Save word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();

@<Reset word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit->original_wn_s);
	EmitCode::up();

@h The middle.
That concludes the head. The middle of the |parse_name| function is then made
up of attempts to parse the grammar lines for this subject, one after another,
until one of them works (if it ever does). That code is compiled in
//Command Grammar Lines//, not here, but it calls the following function to
compile code which will safely restore the situation after each failure of a line.

=
void ParseName::compile_reset_code_after_failed_line(gpr_kit *kit, int pluralised) {
	if (pluralised) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
			EmitCode::val_iname(K_value, Hierarchy::find(PLURALFOUND_HL));
		EmitCode::up();
	}
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->try_from_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->f_s);
		EmitCode::val_true();
	EmitCode::up();
	EmitCode::inv(CONTINUE_BIP);

	EmitCode::place_label(kit->fail_label);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit->try_from_wn_s);
	EmitCode::up();
}

@h The tail.

=
void ParseName::compile_tail(gpr_kit *kit) {
					@<End the body of the indefinite loop@>;
				EmitCode::up();
			EmitCode::up();
			@<End the body of the three-pass loop@>;
			EmitCode::inv(POSTINCREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->pass_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	@<Compile command parser tracing for the function end@>;
	@<Set n to the maximum match length found in the three passes@>;
	@<Advance the word position by n@>;
	@<Return to the command parser@>;
}

@ The indefinite loop is iterated only by an explicit |CONTINUE_BIP| instruction.
If execution reaches the end of the loop body, the loop ends at once, because:

@<End the body of the indefinite loop@> =
	EmitCode::inv(BREAK_BIP);

@ This code runs at the end of each pass, then:

@<End the body of the three-pass loop@> =
	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::call(Hierarchy::find(WORDINPROPERTY_HL));
		EmitCode::down();
			EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
			EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::val_iname(K_value, RTProperties::iname(ParsingPlugin::name_property()));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(POSTINCREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->n_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(OR_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->f_s);
			EmitCode::inv(GT_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, kit->n_s);
				EmitCode::val_number(0);
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->n_s);
				EmitCode::inv(MINUS_BIP);
				EmitCode::down();
					EmitCode::inv(PLUS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->n_s);
						EmitCode::val_symbol(K_value, kit->try_from_wn_s);
					EmitCode::up();
					EmitCode::val_symbol(K_value, kit->original_wn_s);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->pass_s);
			EmitCode::val_number(1);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->pass1_n_s);
				EmitCode::val_symbol(K_value, kit->n_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->pass_s);
			EmitCode::val_number(2);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->pass2_n_s);
				EmitCode::val_symbol(K_value, kit->n_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<Compile command parser tracing for the function end@> =
	EmitCode::inv(IFDEBUG_BIP);
	EmitCode::down();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(GE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TRACE_HL));
					EmitCode::val_number(3);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I"Pass 1: ");
					EmitCode::up();
					EmitCode::inv(PRINTNUMBER_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->pass1_n_s);
					EmitCode::up();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I" Pass 2: ");
					EmitCode::up();
					EmitCode::inv(PRINTNUMBER_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->pass2_n_s);
					EmitCode::up();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I" Pass 3: ");
					EmitCode::up();
					EmitCode::inv(PRINTNUMBER_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, kit->n_s);
					EmitCode::up();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I"\n");
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<Set n to the maximum match length found in the three passes@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->pass1_n_s);
			EmitCode::val_symbol(K_value, kit->n_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->n_s);
				EmitCode::val_symbol(K_value, kit->pass1_n_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->pass2_n_s);
			EmitCode::val_symbol(K_value, kit->n_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->n_s);
				EmitCode::val_symbol(K_value, kit->pass2_n_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<Advance the word position by n@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::inv(PLUS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->original_wn_s);
			EmitCode::val_symbol(K_value, kit->n_s);
		EmitCode::up();
	EmitCode::up();

@<Return to the command parser@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->n_s);
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_number((inter_ti) -1);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::call(Hierarchy::find(DETECTPLURALWORD_HL));
	EmitCode::down();
		EmitCode::val_symbol(K_value, kit->original_wn_s);
		EmitCode::val_symbol(K_value, kit->n_s);
	EmitCode::up();
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, kit->n_s);
	EmitCode::up();

@ We generate code suitable for inclusion in a |parse_name| routine which
either tests distinguishability then parses, or else just parses, the
visible properties of a given subject (which may be a kind or instance).
Sometimes we allow visibility to be inherited from a permission given
to a kind, sometimes we require that the permission be given to this
specific object.

=
void ParseName::consider_visible_properties(gpr_kit *kit, inference_subject *subj,
	int test_distinguishability) {
	int phase = 2;
	if (test_distinguishability) phase = 1;
	for (; phase<=2; phase++) {
		property *pr;
		int visible_properties_code_written = FALSE;
		LOOP_OVER(pr, property) {
			if ((Properties::is_either_or(pr)) && (RTProperties::stored_in_negation(pr))) continue;
			property_permission *pp =
				PropertyPermissions::find(subj, pr, TRUE);
			if ((pp) && (Visibility::get_level(pp) > 0)) @<Consider a single property@>;
		}
		if (visible_properties_code_written) {
			if (phase == 1)
				ParseName::finish_distinguishing_visible_properties(kit);
			else
				ParseName::finish_parsing_visible_properties(kit);
		}
	}
}

@<Consider a single property@> =
	if (visible_properties_code_written == FALSE) {
		visible_properties_code_written = TRUE;
		if (phase == 1)
			ParseName::begin_distinguishing_visible_properties(kit);
		else
			ParseName::begin_parsing_visible_properties(kit);
	}

	parse_node *visibility_condition = Visibility::get_condition(pp);
	if (visibility_condition) {
		if (phase == 1)
			ParseName::test_distinguish_visible_property(kit, visibility_condition);
		else
			ParseName::test_parse_visible_property(kit, visibility_condition);
	}

	if (phase == 1)
		ParseName::distinguish_visible_property(kit, pr);
	else
		ParseName::parse_visible_property(kit, subj, pr, Visibility::get_level(pp));

	if (visibility_condition) {
		EmitCode::up(); EmitCode::up();
	}

@h Distinguishing visible properties.
We distinguish two objects P1 and P2 based on the following criteria:
(1) if any property is currently visible for P1 but not P2 or vice versa,
then they are distinguishable;
(2) if any value property is visible but P1 and P2 have different values for
it, then they are distinguishable;
(3) if any either/or property is visible but P1 has it and P2 hasn't,
or vice versa, then they are distinguishable;
(4) and otherwise we disclaim the decision.

=
void ParseName::begin_distinguishing_visible_properties(gpr_kit *kit) {
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
			EmitCode::val_iname(K_value, Hierarchy::find(THESAME_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(IFDEBUG_BIP);
			EmitCode::down();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(GE_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TRACE_HL));
							EmitCode::val_number(4);
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(PRINT_BIP);
							EmitCode::down();
								EmitCode::val_text(I"p1, p2 = ");
							EmitCode::up();
							EmitCode::inv(PRINTNUMBER_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
							EmitCode::up();
							EmitCode::inv(PRINT_BIP);
							EmitCode::down();
								EmitCode::val_text(I", ");
							EmitCode::up();
							EmitCode::inv(PRINTNUMBER_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
							EmitCode::up();
							EmitCode::inv(PRINT_BIP);
							EmitCode::down();
								EmitCode::val_text(I"\n");
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->ss_s);
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::up();
}

void ParseName::test_distinguish_visible_property(gpr_kit *kit, parse_node *spec) {
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->f_s);
		CompileValues::to_code_val_of_kind(spec, K_truth_state);
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->g_s);
		CompileValues::to_code_val_of_kind(spec, K_truth_state);
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, kit->f_s);
			EmitCode::val_symbol(K_value, kit->g_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Return minus two@>;
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, kit->f_s);
		EmitCode::code();
		EmitCode::down();
}

void ParseName::distinguish_visible_property(gpr_kit *kit, property *prn) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "Distinguishing property %n", RTProperties::iname(prn));
	EmitCode::comment(C);
	DISCARD_TEXT(C)

	if (Properties::is_either_or(prn)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				EmitCode::test_if_iname_has_property(K_value, Hierarchy::find(PARSER_ONE_HL), prn);
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					EmitCode::test_if_iname_has_property(K_value, Hierarchy::find(PARSER_TWO_HL), prn);
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				@<Return minus two@>;
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				EmitCode::test_if_iname_has_property(K_value, Hierarchy::find(PARSER_TWO_HL), prn);
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					EmitCode::test_if_iname_has_property(K_value, Hierarchy::find(PARSER_ONE_HL), prn);
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				@<Return minus two@>;
			EmitCode::up();
		EmitCode::up();
	} else {
		kind *K = ValueProperties::kind(prn);
		inter_name *distinguisher = RTKindConstructors::distinguisher_function_iname(K);
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			if (distinguisher) {
				EmitCode::call(distinguisher);
				EmitCode::down();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
						EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
						EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
				EmitCode::up();
			} else {
				EmitCode::inv(NE_BIP);
				EmitCode::down();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
						EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
						EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
				EmitCode::up();
			}
			EmitCode::code();
			EmitCode::down();
				@<Return minus two@>;
			EmitCode::up();
		EmitCode::up();
	}
}

@<Return minus two@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_number((inter_ti) -2);
	EmitCode::up();

@ =
void ParseName::finish_distinguishing_visible_properties(gpr_kit *kit) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_symbol(K_value, kit->ss_s);
			EmitCode::up();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_number(0);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
}

@h Parsing visible properties.
Here, unlike in distinguishing visible properties, it is unambiguous that
|self| refers to the object being parsed: there is therefore no need to
alter the value of |self| to make any visibility condition work correctly.

=
void ParseName::begin_parsing_visible_properties(gpr_kit *kit) {
	EmitCode::comment(I"Match any number of visible property values");
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->try_from_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->g_s);
		EmitCode::val_true();
	EmitCode::up();
	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, kit->g_s);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, kit->g_s);
				EmitCode::val_false();
			EmitCode::up();
}

void ParseName::test_parse_visible_property(gpr_kit *kit, parse_node *spec) {
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		CompileValues::to_code_val_of_kind(spec, K_truth_state);
		EmitCode::code();
		EmitCode::down();
}

int unique_pvp_counter = 0;
void ParseName::parse_visible_property(gpr_kit *kit,
	inference_subject *subj, property *prn, int visibility_level) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "Parsing property %n", RTProperties::iname(prn));
	EmitCode::comment(C);
	DISCARD_TEXT(C)

	if (Properties::is_either_or(prn)) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".pvp_pass_L_%d", unique_pvp_counter++);
		inter_symbol *pass_label = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)

		ParseName::parse_visible_either_or(
			kit, prn, visibility_level, pass_label);
		property *prnbar = EitherOrProperties::get_negation(prn);
		if (prnbar)
			ParseName::parse_visible_either_or(
				kit, prnbar, visibility_level, pass_label);

		EmitCode::place_label(pass_label);
	} else {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::val_symbol(K_value, kit->try_from_wn_s);
		EmitCode::up();

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->spn_s);
			EmitCode::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->ss_s);
			EmitCode::val_iname(K_value, Hierarchy::find(ETYPE_HL));
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			kind *K = ValueProperties::kind(prn);
			inter_name *recog_gpr = RTKindConstructors::recognition_only_GPR_iname(K);
			if (recog_gpr) {
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::call(recog_gpr);
					EmitCode::down();
						EmitCode::inv(PROPERTYVALUE_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
							EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
							EmitCode::val_iname(K_value, RTProperties::iname(prn));
						EmitCode::up();
					EmitCode::up();
					EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
				EmitCode::up();
			} else if (Kinds::Behaviour::is_understandable(K)) {
				if (RTKindConstructors::GPR_provided_by_kit(K)) {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::call(RTKindConstructors::GPR_iname(K));
							EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
						EmitCode::up();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::inv(PROPERTYVALUE_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
								EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
								EmitCode::val_iname(K_value, RTProperties::iname(prn));
							EmitCode::up();
							EmitCode::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
						EmitCode::up();
					EmitCode::up();
				} else if (Kinds::Behaviour::is_an_enumeration(K)) {
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::call(RTKindConstructors::instance_GPR_iname(K));
						EmitCode::down();
							EmitCode::inv(PROPERTYVALUE_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
								EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
								EmitCode::val_iname(K_value, RTProperties::iname(prn));
							EmitCode::up();
						EmitCode::up();
						EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
					EmitCode::up();
				} else {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::call(RTKindConstructors::GPR_iname(K));
							EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
						EmitCode::up();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::inv(PROPERTYVALUE_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
								EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
								EmitCode::val_iname(K_value, RTProperties::iname(prn));
							EmitCode::up();
							EmitCode::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
						EmitCode::up();
					EmitCode::up();
				}
			} else internal_error("Unable to recognise kind of value in parsing");
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, kit->try_from_wn_s);
					EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, kit->g_s);
					EmitCode::val_true();
				EmitCode::up();
				if (visibility_level == 2) {
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, kit->f_s);
						EmitCode::val_true();
					EmitCode::up();
				}
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
			EmitCode::val_symbol(K_value, kit->spn_s);
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(ETYPE_HL));
			EmitCode::val_symbol(K_value, kit->ss_s);
		EmitCode::up();
	}
}

void ParseName::parse_visible_either_or(gpr_kit *kit, property *prn, int visibility_level,
	inter_symbol *pass_l) {
	command_grammar *cg = EitherOrProperties::get_parsing_grammar(prn);
	@<Begin a PVP test@>;
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		wording W = prn->name;
		int j = 0; LOOP_THROUGH_WORDING(i, W) j++;
		int ands = 0;
		if (j > 0) { EmitCode::inv(AND_BIP); EmitCode::down(); ands++; }
		EmitCode::test_if_iname_has_property(K_value, Hierarchy::find(SELF_HL), prn);
		int k = 0;
		LOOP_THROUGH_WORDING(i, W) {
			if (k < j-1) { EmitCode::inv(AND_BIP); EmitCode::down(); ands++; }
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
				TEMPORARY_TEXT(N)
				WRITE_TO(N, "%N", i);
				EmitCode::val_dword(N);
				DISCARD_TEXT(N)
			EmitCode::up();
			k++;
		}

		for (int a=0; a<ands; a++) EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Pass a PVP test@>;
		EmitCode::up();
	EmitCode::up();
	if (cg) {
		@<Begin a PVP test@>;
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				EmitCode::test_if_iname_has_property(K_value, Hierarchy::find(SELF_HL), prn);
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::call(RTCommandGrammars::get_property_GPR_fn_iname(cg));
					EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				@<Pass a PVP test@>;
			EmitCode::up();
		EmitCode::up();
	}
}

@<Begin a PVP test@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit->try_from_wn_s);
	EmitCode::up();

@<Pass a PVP test@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->try_from_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, kit->g_s);
		EmitCode::val_true();
	EmitCode::up();
	if (visibility_level == 2) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, kit->f_s);
			EmitCode::val_true();
		EmitCode::up();
	}
	if (pass_l) {
		EmitCode::inv(JUMP_BIP);
		EmitCode::down();
			EmitCode::lab(pass_l);
		EmitCode::up();
	}

@ =
void ParseName::finish_parsing_visible_properties(gpr_kit *kit) {
		EmitCode::up();
	EmitCode::up();
	EmitCode::comment(I"try_from_wn is now advanced past any visible property values");
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, kit->try_from_wn_s);
	EmitCode::up();
}
