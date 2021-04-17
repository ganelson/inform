[UnderstandGeneralTokens::] General Parsing Routines.

To compile I6 general parsing routines (GPRs) and/or |parse_name|
properties as required by the I7 grammar.

@h Definitions.

=
typedef struct parse_name_notice {
	struct inter_name *pnn_iname;
	struct inference_subject *parse_subject;
	CLASS_DEFINITION
} parse_name_notice;

@ In this section we compile GPRs, routines to handle |Consult|-like text,
and also |parse_name| routines, which as we shall see come in two different
forms. These routines share a basic protocol for dealing with the I6
library, which makes things considerably easier. In each case, the
routine is compiled as a head and then, subsequently, a tail: the user
of the routines is expected to compile the actual grammar in between
the two. Every head must be followed by exactly one tail of the same
sort; every tail must be preceded by exactly one head of the same sort;
but code to parse at |wn| may be placed in between.

The GPRs compiled to parse literal values of given kinds of values
(for instance, exotic verbal forms of numbers, or verbal names of
the constants for new kinds of value, or literal patterns) are not
compiled here: they are in Tokens Parsing Values.

@h Consult routines.
These are used to parse an explicit range of words (such as traditionally
found in the CONSULT command) at run time, and they are not I6 grammar
tokens, and do not appear in |Verb| declarations: otherwise, such
routines are very similar to GPRs.

First, we need to look after a pointer to the CG used to hold the grammar
being matched against the snippet of words.

=
inter_name *UnderstandGeneralTokens::consult_iname(command_grammar *cg) {
	if (cg == NULL) return NULL;
	if (cg->compilation_data.cg_consult_iname == NULL) {
		current_sentence = cg->where_cg_created;
		package_request *PR = Hierarchy::local_package(CONSULT_TOKENS_HAP);
		cg->compilation_data.cg_consult_iname = Hierarchy::make_iname_in(CONSULT_FN_HL, PR);
	}
	return cg->compilation_data.cg_consult_iname;
}

@h Parse name properties.
One of the major services provided by I7, as compared with I6, is that it
automatically compiles what would otherwise be laborious |parse_name|
routines for its objects. This is messy, because the underlying I6 syntax
is messy. The significant complication is that the I6 parser makes two
quite different uses of |parse_name|: not just for parsing names, but
also for determining whether two objects are visually distinguishable,
something it needs to know in order to make plural objects work properly.

If an object has any actual grammar attached, say a collection of grammar
lines belonging to GV3, we will compile the |parse_name| as an independent
I6 routine with a name like |Parse_Name_GV3|. If not, a |parse_name| may
still be needed, because of the distinguishability problem: if so then we
will simply compile a |parse_name| routine inline, in the usual I6 way.

=
inter_name *UnderstandGeneralTokens::get_gv_parse_name(command_grammar *cg) {
	if (cg->compilation_data.cg_parse_name_iname == NULL) {
		package_request *PR = Hierarchy::local_package_to(PARSE_NAMES_HAP, cg->where_cg_created);
		cg->compilation_data.cg_parse_name_iname = Hierarchy::make_iname_in(PARSE_NAME_FN_HL, PR);
	}
	return cg->compilation_data.cg_parse_name_iname;
}

inter_name *UnderstandGeneralTokens::compile_parse_name_property(inference_subject *subj) {
	inter_name *symb = NULL;
	command_grammar *cg = PARSING_DATA_FOR_SUBJ(subj)->understand_as_this_object;
	if (CommandGrammars::is_empty(cg) == FALSE) {
		symb = UnderstandGeneralTokens::get_gv_parse_name(cg);
	} else {
		if (Visibility::any_property_visible_to_subject(subj, FALSE)) {
			parse_name_notice *notice = CREATE(parse_name_notice);
			package_request *PR = Hierarchy::local_package_to(PARSE_NAMES_HAP, subj->infs_created_at);
			notice->pnn_iname = Hierarchy::make_iname_in(PARSE_NAME_DASH_FN_HL, PR);
			notice->parse_subject = subj;
			symb = notice->pnn_iname;
		}
	}
	return symb;
}

void UnderstandGeneralTokens::write_parse_name_routines(void) {
	parse_name_notice *notice;
	LOOP_OVER(notice, parse_name_notice) {
		gpr_kit gprk = UnderstandValueTokens::new_kit();
		packaging_state save = Emit::new_packaging_state();
		if (UnderstandGeneralTokens::compile_parse_name_head(&save, &gprk,
			notice->parse_subject, NULL, notice->pnn_iname)) {
			UnderstandGeneralTokens::compile_parse_name_tail(&gprk);
			Functions::end(save);
		}
	}
}

@ The following routine produces one of three outcomes: either (i) the
head of an I6 declaration of a free-standing routine to be used as a
|parse_name| property, or (ii) the head of an I6 inline declaration of a
|parse_name| property as a |with| clause for an |Object| directive, or
(iii) the empty output, in happy cases where neither parsing nor
distinguishability need to be investigated. The routine returns a flag
indicating if a tail need be compiled (i.e., in cases (i) or (ii) but not
(iii)).

In cases (i) and (ii), the head is immediately followed by code which
looks at the names of visible properties. Recall that a visible property
is one which can be used to describe an object: for instance, if colour
is a visible property of a car, then it can be called "green car" if
and only if the current value of the colour of the car is "green", and
so forth. In all such cases, we need to parse the text to look for the
name of the current value.

But if a property can be used as part of the name, then it follows that
two objects with the same grammar (and name words) cease to be
indistinguishable when their values for this property differ. For instance,
given two otherwise identical cars which can only be called "car", we
can distinguish them with the names "red car" and "green car" if one
is red and the other green. The parser needs to know this. It calls the
|parse_name| routine with an I6 global called |parser_action| set to
|##TheSame| in such a case, and we can return 0 to make no decision or
|-2| to say that they are different.

Note that the parser checks this only if two or more objects share the same
|parse_name| routine: which will in I7 happen only if they each inherit it
from the I6 class of a common kind. Because |parse_name| is not additive in
I6, this can only occur if the objects, and any intervening classes for
intervening kinds, define no |parse_name| of their own.

We will test distinguishability only for kinds which have permissions for
visible properties: kinds because no other |parse_name| values can ever
be duplicated in instance objects, and visible properties because these
are the only ways to tell apart instances which have no grammar of their
own. (If either had grammar of its own, it would also have its own
|parse_name| routine.) For all other kinds, we return a make-no-decision
value in response to a |##TheSame| request: this ensures that the I6
parser looks at the |name| properties of the objects instead, and in
the absence of either I7-level grammar lines or visible properties, that
will be the correct decision.

=
int UnderstandGeneralTokens::compile_parse_name_head(packaging_state *save,
	gpr_kit *gprk, inference_subject *subj,
	command_grammar *cg, inter_name *rname) {
	int test_distinguishability = FALSE, sometimes_has_visible_properties = FALSE;
	inter_name *N = NULL;

	if (subj == NULL) internal_error("compiling parse_name head for null subj");

	if (cg) {
		sometimes_has_visible_properties =
			Visibility::any_property_visible_to_subject(subj, TRUE);
		N = UnderstandGeneralTokens::get_gv_parse_name(cg);
	} else {
		if (Visibility::any_property_visible_to_subject(subj, FALSE)
			== FALSE) return FALSE;
	}

	if (KindSubjects::to_kind(subj)) test_distinguishability = TRUE;

	inter_name *compile_to = rname;
	if (compile_to == NULL) compile_to = N;
	if (compile_to == NULL) internal_error("no parse name routine name given");

	*save = Functions::begin(compile_to);

	UnderstandValueTokens::add_parse_name_vars(gprk);

	UnderstandGeneralTokens::top_of_head(gprk, N, subj,
		test_distinguishability, sometimes_has_visible_properties, rname);
	return TRUE;
}

@ The following multi-pass approach checks the possible patterns:

(1) (words in |name| property) (visible property names) (words in |name| property) (longer grammar) (words in |name| property)

(2) (visible property names) (longer grammar) (words in |name| property)

(3) (longer grammar) (words in |name| property)

The longer match is taken: but note that a match of visible property names
alone is rejected unless at least one property has been declared sufficient
to identify the object all by itself. Longer grammar means grammar lines
containing 2 or more words, since all single-fixed-word grammar lines for
CGs destined to be |parse_name|s is stripped out and converted into the
|name| property.

There are clearly other possibilities and the above system is something of
a pragmatic compromise (in that to check other cases would be slower and
more complex). I suspect we will return to this.

=
void UnderstandGeneralTokens::top_of_head(gpr_kit *gprk, inter_name *cg_iname, inference_subject *subj,
	int test_distinguishability, int sometimes_has_visible_properties, inter_name *given_name) {

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

	if ((cg_iname) && (sometimes_has_visible_properties == FALSE)) {
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
	@<Save word number@>;

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->pass_s);
		EmitCode::val_number(1);
	EmitCode::up();
	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::inv(LE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gprk->pass_s);
			EmitCode::val_number(3);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Reset word number@>;
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->try_from_wn_s);
				EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->f_s);
				EmitCode::val_false();
			EmitCode::up();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->n_s);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::inv(WHILE_BIP);
			EmitCode::down();
				EmitCode::val_number(1);
				EmitCode::code();
				EmitCode::down();

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
								EmitCode::val_symbol(K_value, gprk->pass_s);
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
									EmitCode::val_iname(K_value, RTParsing::name_iname());
								EmitCode::up();
								EmitCode::code();
								EmitCode::down();
									EmitCode::inv(STORE_BIP);
									EmitCode::down();
										EmitCode::ref_symbol(K_value, gprk->f_s);
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
								EmitCode::ref_symbol(K_value, gprk->try_from_wn_s);
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
								EmitCode::val_symbol(K_value, gprk->pass_s);
								EmitCode::val_number(1);
							EmitCode::up();
							EmitCode::inv(EQ_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->pass_s);
								EmitCode::val_number(2);
							EmitCode::up();
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
						UnderstandGeneralTokens::consider_visible_properties(gprk, subj, test_distinguishability);
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
								EmitCode::val_symbol(K_value, gprk->pass_s);
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
									EmitCode::val_iname(K_value, RTParsing::name_iname());
								EmitCode::up();
								EmitCode::code();
								EmitCode::down();
									EmitCode::inv(STORE_BIP);
									EmitCode::down();
										EmitCode::ref_symbol(K_value, gprk->f_s);
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
								EmitCode::ref_symbol(K_value, gprk->try_from_wn_s);
								EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
}

@<Save word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->original_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();

@<Reset word number@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, gprk->original_wn_s);
	EmitCode::up();

@ The head and tail routines can only be understood by knowing that the
following code is used to reset the grammar-line parser after each failure
of a CGL to parse.

=
void UnderstandGeneralTokens::after_gl_failed(gpr_kit *gprk, inter_symbol *label, int pluralised) {
	if (pluralised) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
			EmitCode::val_iname(K_value, Hierarchy::find(PLURALFOUND_HL));
		EmitCode::up();
	}
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->try_from_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->f_s);
		EmitCode::val_true();
	EmitCode::up();
	EmitCode::inv(CONTINUE_BIP);

	EmitCode::place_label(label);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, gprk->try_from_wn_s);
	EmitCode::up();
}

@ The interesting point about the tail of the |parse_name| routine is that
it ends on the |]| "close routine" character, in mid-source line. This is
because the routine may be being used inside an |Object| directive, and
would therefore need to be followed by a comma, or in free-standing I6 code,
in which case it would need to be followed by a semi-colon.

=
void UnderstandGeneralTokens::compile_parse_name_tail(gpr_kit *gprk) {
					EmitCode::inv(BREAK_BIP);
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(WHILE_BIP);
			EmitCode::down();
				EmitCode::call(Hierarchy::find(WORDINPROPERTY_HL));
				EmitCode::down();
					EmitCode::call(Hierarchy::find(NEXTWORDSTOPPED_HL));
					EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
					EmitCode::val_iname(K_value, RTParsing::name_iname());
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(POSTINCREMENT_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->n_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(OR_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->f_s);
					EmitCode::inv(GT_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->n_s);
						EmitCode::val_number(0);
					EmitCode::up();
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->n_s);
						EmitCode::inv(MINUS_BIP);
						EmitCode::down();
							EmitCode::inv(PLUS_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, gprk->n_s);
								EmitCode::val_symbol(K_value, gprk->try_from_wn_s);
							EmitCode::up();
							EmitCode::val_symbol(K_value, gprk->original_wn_s);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->pass_s);
					EmitCode::val_number(1);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->pass1_n_s);
						EmitCode::val_symbol(K_value, gprk->n_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, gprk->pass_s);
					EmitCode::val_number(2);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->pass2_n_s);
						EmitCode::val_symbol(K_value, gprk->n_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(POSTINCREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->pass_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

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
						EmitCode::val_symbol(K_value, gprk->pass1_n_s);
					EmitCode::up();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I" Pass 2: ");
					EmitCode::up();
					EmitCode::inv(PRINTNUMBER_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->pass2_n_s);
					EmitCode::up();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I" Pass 3: ");
					EmitCode::up();
					EmitCode::inv(PRINTNUMBER_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, gprk->n_s);
					EmitCode::up();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I"\n");
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gprk->pass1_n_s);
			EmitCode::val_symbol(K_value, gprk->n_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->n_s);
				EmitCode::val_symbol(K_value, gprk->pass1_n_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gprk->pass2_n_s);
			EmitCode::val_symbol(K_value, gprk->n_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->n_s);
				EmitCode::val_symbol(K_value, gprk->pass2_n_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::inv(PLUS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gprk->original_wn_s);
			EmitCode::val_symbol(K_value, gprk->n_s);
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gprk->n_s);
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
		EmitCode::val_symbol(K_value, gprk->original_wn_s);
		EmitCode::val_symbol(K_value, gprk->n_s);
	EmitCode::up();
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, gprk->n_s);
	EmitCode::up();
}

@ We generate code suitable for inclusion in a |parse_name| routine which
either tests distinguishability then parses, or else just parses, the
visible properties of a given subject (which may be a kind or instance).
Sometimes we allow visibility to be inherited from a permission given
to a kind, sometimes we require that the permission be given to this
specific object.

=
void UnderstandGeneralTokens::consider_visible_properties(gpr_kit *gprk, inference_subject *subj,
	int test_distinguishability) {
	int phase = 2;
	if (test_distinguishability) phase = 1;
	for (; phase<=2; phase++) {
		property *pr;
		UnderstandGeneralTokens::start_considering_visible_properties(gprk, phase);
		LOOP_OVER(pr, property) {
			if ((Properties::is_either_or(pr)) && (RTProperties::stored_in_negation(pr))) continue;
			property_permission *pp =
				PropertyPermissions::find(subj, pr, TRUE);
			if ((pp) && (Visibility::get_level(pp) > 0))
				UnderstandGeneralTokens::consider_visible_property(gprk, subj, pr, pp, phase);
		}
		UnderstandGeneralTokens::finish_considering_visible_properties(gprk, phase);
	}
}

@h Common handling for distinguishing and parsing.
The top-level considering routines parcel up work and hand it over to
the distinguishing routines if |phase| is 1, and the parsing routines
if |phase| is 2. Note that if there are no sometimes-visible-properties
then the correct behaviour is to call none of the routines below this
level, and to compile nothing to the file.

=
int visible_properties_code_written = FALSE; /* persistent state used only here */

void UnderstandGeneralTokens::start_considering_visible_properties(gpr_kit *gprk, int phase) {
	visible_properties_code_written = FALSE;
}

void UnderstandGeneralTokens::consider_visible_property(gpr_kit *gprk, inference_subject *subj,
	property *pr, property_permission *pp, int phase) {
	int conditional_vis = FALSE;
	parse_node *spec;

	if (visible_properties_code_written == FALSE) {
		visible_properties_code_written = TRUE;
		if (phase == 1)
			UnderstandGeneralTokens::begin_distinguishing_visible_properties(gprk);
		else
			UnderstandGeneralTokens::begin_parsing_visible_properties(gprk);
	}

	spec = Visibility::get_condition(pp);

	if (spec) {
		conditional_vis = TRUE;
		if (phase == 1)
			UnderstandGeneralTokens::test_distinguish_visible_property(gprk, spec);
		else
			UnderstandGeneralTokens::test_parse_visible_property(gprk, spec);
	}

	if (phase == 1)
		UnderstandGeneralTokens::distinguish_visible_property(gprk, pr);
	else
		UnderstandGeneralTokens::parse_visible_property(gprk, subj, pr, Visibility::get_level(pp));

	if (conditional_vis) { EmitCode::up(); EmitCode::up(); }
}

void UnderstandGeneralTokens::finish_considering_visible_properties(gpr_kit *gprk, int phase) {
	if (visible_properties_code_written) {
		if (phase == 1)
			UnderstandGeneralTokens::finish_distinguishing_visible_properties(gprk);
		else
			UnderstandGeneralTokens::finish_parsing_visible_properties(gprk);
	}
}

@h Distinguishing visible properties.
We distinguish two objects P1 and P2 based on the following criteria:
(i) if any property is currently visible for P1 but not P2 or vice versa,
then they are distinguishable; (ii) if any value property is visible
but P1 and P2 have different values for it, then they are distinguishable;
(iii) if any either/or property is visible but P1 has it and P2 hasn't,
or vice versa, then they are distinguishable; and otherwise we revert to
the I6 parser's standard algorithm, which looks at the |name| property.

=
void UnderstandGeneralTokens::begin_distinguishing_visible_properties(gpr_kit *gprk) {
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
				EmitCode::ref_symbol(K_value, gprk->ss_s);
				EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
			EmitCode::up();
}

void UnderstandGeneralTokens::test_distinguish_visible_property(gpr_kit *gprk, parse_node *spec) {
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->f_s);
		CompileValues::to_code_val_of_kind(spec, K_truth_state);
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
		EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->g_s);
		CompileValues::to_code_val_of_kind(spec, K_truth_state);
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(NE_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gprk->f_s);
			EmitCode::val_symbol(K_value, gprk->g_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Return minus two@>;
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, gprk->f_s);
		EmitCode::code();
		EmitCode::down();
}

void UnderstandGeneralTokens::distinguish_visible_property(gpr_kit *gprk, property *prn) {
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "Distinguishing property %n", RTProperties::iname(prn));
	EmitCode::comment(C);
	DISCARD_TEXT(C)

	if (Properties::is_either_or(prn)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				RTPropertyValues::emit_iname_has_property(K_value, Hierarchy::find(PARSER_ONE_HL), prn);
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					RTPropertyValues::emit_iname_has_property(K_value, Hierarchy::find(PARSER_TWO_HL), prn);
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
				RTPropertyValues::emit_iname_has_property(K_value, Hierarchy::find(PARSER_TWO_HL), prn);
				EmitCode::inv(NOT_BIP);
				EmitCode::down();
					RTPropertyValues::emit_iname_has_property(K_value, Hierarchy::find(PARSER_ONE_HL), prn);
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				@<Return minus two@>;
			EmitCode::up();
		EmitCode::up();
	} else {
		kind *K = ValueProperties::kind(prn);
		inter_name *distinguisher = Kinds::Behaviour::get_distinguisher_as_iname(K);
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			if (distinguisher) {
				EmitCode::call(distinguisher);
				EmitCode::down();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
				EmitCode::up();
			} else {
				EmitCode::inv(NE_BIP);
				EmitCode::down();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
					EmitCode::inv(PROPERTYVALUE_BIP);
					EmitCode::down();
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
void UnderstandGeneralTokens::finish_distinguishing_visible_properties(gpr_kit *gprk) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
				EmitCode::val_symbol(K_value, gprk->ss_s);
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
void UnderstandGeneralTokens::begin_parsing_visible_properties(gpr_kit *gprk) {
	EmitCode::comment(I"Match any number of visible property values");
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->try_from_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->g_s);
		EmitCode::val_true();
	EmitCode::up();
	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, gprk->g_s);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, gprk->g_s);
				EmitCode::val_false();
			EmitCode::up();
}

void UnderstandGeneralTokens::test_parse_visible_property(gpr_kit *gprk, parse_node *spec) {
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		CompileValues::to_code_val_of_kind(spec, K_truth_state);
		EmitCode::code();
		EmitCode::down();
}

int unique_pvp_counter = 0;
void UnderstandGeneralTokens::parse_visible_property(gpr_kit *gprk,
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

		UnderstandGeneralTokens::parse_visible_either_or(
			gprk, prn, visibility_level, pass_label);
		property *prnbar = EitherOrProperties::get_negation(prn);
		if (prnbar)
			UnderstandGeneralTokens::parse_visible_either_or(
				gprk, prnbar, visibility_level, pass_label);

		EmitCode::place_label(pass_label);
	} else {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
			EmitCode::val_symbol(K_value, gprk->try_from_wn_s);
		EmitCode::up();

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->spn_s);
			EmitCode::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->ss_s);
			EmitCode::val_iname(K_value, Hierarchy::find(ETYPE_HL));
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			kind *K = ValueProperties::kind(prn);
			inter_name *recog_gpr = Kinds::Behaviour::get_recognition_only_GPR_as_iname(K);
			if (recog_gpr) {
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::call(recog_gpr);
					EmitCode::down();
						EmitCode::inv(PROPERTYVALUE_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
							EmitCode::val_iname(K_value, RTProperties::iname(prn));
						EmitCode::up();
					EmitCode::up();
					EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
				EmitCode::up();
			} else if (Kinds::Behaviour::offers_I6_GPR(K)) {
				inter_name *i6_gpr_name = Kinds::Behaviour::get_explicit_I6_GPR_iname(K);
				if (i6_gpr_name) {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::call(i6_gpr_name);
							EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
						EmitCode::up();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::inv(PROPERTYVALUE_BIP);
							EmitCode::down();
								EmitCode::val_iname(K_value, Hierarchy::find(SELF_HL));
								EmitCode::val_iname(K_value, RTProperties::iname(prn));
							EmitCode::up();
							EmitCode::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
						EmitCode::up();
					EmitCode::up();
				} else if (Kinds::Behaviour::is_an_enumeration(K)) {
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::call(RTKinds::get_instance_GPR_iname(K));
						EmitCode::down();
							EmitCode::inv(PROPERTYVALUE_BIP);
							EmitCode::down();
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
							EmitCode::call(RTKinds::get_kind_GPR_iname(K));
							EmitCode::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
						EmitCode::up();
						EmitCode::inv(EQ_BIP);
						EmitCode::down();
							EmitCode::inv(PROPERTYVALUE_BIP);
							EmitCode::down();
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
					EmitCode::ref_symbol(K_value, gprk->try_from_wn_s);
					EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gprk->g_s);
					EmitCode::val_true();
				EmitCode::up();
				if (visibility_level == 2) {
					EmitCode::inv(STORE_BIP);
					EmitCode::down();
						EmitCode::ref_symbol(K_value, gprk->f_s);
						EmitCode::val_true();
					EmitCode::up();
				}
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
			EmitCode::val_symbol(K_value, gprk->spn_s);
		EmitCode::up();
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(ETYPE_HL));
			EmitCode::val_symbol(K_value, gprk->ss_s);
		EmitCode::up();
	}
}

void UnderstandGeneralTokens::parse_visible_either_or(gpr_kit *gprk, property *prn, int visibility_level,
	inter_symbol *pass_l) {
	command_grammar *cg = EitherOrProperties::get_parsing_grammar(prn);
	UnderstandGeneralTokens::pvp_test_begins_dash(gprk);
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		wording W = prn->name;
		int j = 0; LOOP_THROUGH_WORDING(i, W) j++;
		int ands = 0;
		if (j > 0) { EmitCode::inv(AND_BIP); EmitCode::down(); ands++; }
		RTPropertyValues::emit_iname_has_property(K_value, Hierarchy::find(SELF_HL), prn);
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
			UnderstandGeneralTokens::pvp_test_passes_dash(gprk, visibility_level, pass_l);
		EmitCode::up();
	EmitCode::up();
	if (cg) {
		if (cg->compilation_data.cg_prn_iname == NULL) internal_error("no PRN iname");
		UnderstandGeneralTokens::pvp_test_begins_dash(gprk);
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(AND_BIP);
			EmitCode::down();
				RTPropertyValues::emit_iname_has_property(K_value, Hierarchy::find(SELF_HL), prn);
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::call(cg->compilation_data.cg_prn_iname);
					EmitCode::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				UnderstandGeneralTokens::pvp_test_passes_dash(gprk, visibility_level, pass_l);
			EmitCode::up();
		EmitCode::up();
	}
}

void UnderstandGeneralTokens::pvp_test_begins_dash(gpr_kit *gprk) {
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, gprk->try_from_wn_s);
	EmitCode::up();
}

void UnderstandGeneralTokens::pvp_test_passes_dash(gpr_kit *gprk, int visibility_level, inter_symbol *pass_l) {
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->try_from_wn_s);
		EmitCode::val_iname(K_value, Hierarchy::find(WN_HL));
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, gprk->g_s);
		EmitCode::val_true();
	EmitCode::up();
	if (visibility_level == 2) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gprk->f_s);
			EmitCode::val_true();
		EmitCode::up();
	}
	if (pass_l) {
		EmitCode::inv(JUMP_BIP);
		EmitCode::down();
			EmitCode::lab(pass_l);
		EmitCode::up();
	}
}

void UnderstandGeneralTokens::finish_parsing_visible_properties(gpr_kit *gprk) {
		EmitCode::up();
	EmitCode::up();
	EmitCode::comment(I"try_from_wn is now advanced past any visible property values");
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_value, Hierarchy::find(WN_HL));
		EmitCode::val_symbol(K_value, gprk->try_from_wn_s);
	EmitCode::up();
}
