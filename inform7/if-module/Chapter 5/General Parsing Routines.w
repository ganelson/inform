[PL::Parsing::Tokens::General::] General Parsing Routines.

To compile I6 general parsing routines (GPRs) and/or |parse_name|
properties as required by the I7 grammar.

@h Definitions.

=
typedef struct parse_name_notice {
	inter_name *pnn_iname;
	inference_subject *parse_subject;
	MEMORY_MANAGEMENT
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

First, we need to look after a pointer to the GV used to hold the grammar
being matched against the snippet of words.

=
grammar_verb *consultation_gv = NULL; /* used only in routines below */

grammar_verb *PL::Parsing::Tokens::General::get_consultation_gv(void) {
	if (consultation_gv == NULL) consultation_gv = PL::Parsing::Verbs::consultation_new();
	return consultation_gv;
}

void PL::Parsing::Tokens::General::prepare_consultation_gv(void) {
	consultation_gv = NULL;
}

inter_name *PL::Parsing::Tokens::General::print_consultation_gv_name(void) {
	if (consultation_gv) return PL::Parsing::Tokens::General::consult_iname(consultation_gv);
	return NULL;
}

inter_name *PL::Parsing::Tokens::General::consult_iname(grammar_verb *gv) {
	if (gv->gv_consult_iname == NULL) {
		current_sentence = gv->where_gv_created;
		package_request *PR = Hierarchy::local_package(CONSULT_TOKENS_HAP);
		gv->gv_consult_iname = Hierarchy::make_iname_in(CONSULT_FN_HL, PR);
	}
	return gv->gv_consult_iname;
}

@ We also, at another time, need to compile the routine being named. There
are no timing difficulties here: the routine's name is used in the context of
an I6 constant rather than in a |Verb| declaration, so no predeclaration is
needed.

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
inter_name *PL::Parsing::Tokens::General::get_gv_parse_name(grammar_verb *gv) {
	if (gv->gv_parse_name_iname == NULL) {
		compilation_module *C = Modules::find(gv->where_gv_created);
		package_request *PR = Hierarchy::package(C, PARSE_NAMES_HAP);
		gv->gv_parse_name_iname = Hierarchy::make_iname_in(PARSE_NAME_FN_HL, PR);
	}
	return gv->gv_parse_name_iname;
}

inter_name *PL::Parsing::Tokens::General::compile_parse_name_property(inference_subject *subj) {
	inter_name *symb = NULL;
	grammar_verb *gv = PF_S(parsing, subj)->understand_as_this_object;
	if (PL::Parsing::Verbs::is_empty(gv) == FALSE) {
		symb = PL::Parsing::Tokens::General::get_gv_parse_name(gv);
	} else {
		if (PL::Parsing::Visibility::any_property_visible_to_subject(subj, FALSE)) {
			parse_name_notice *notice = CREATE(parse_name_notice);
			compilation_module *C = Modules::find(subj->infs_created_at);
			package_request *PR = Hierarchy::package(C, PARSE_NAMES_HAP);
			notice->pnn_iname = Hierarchy::make_iname_in(PARSE_NAME_DASH_FN_HL, PR);
			notice->parse_subject = subj;
			symb = notice->pnn_iname;
		}
	}
	return symb;
}

void PL::Parsing::Tokens::General::write_parse_name_routines(void) {
	parse_name_notice *notice;
	LOOP_OVER(notice, parse_name_notice) {
		gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
		packaging_state save = Emit::unused_packaging_state();
		if (PL::Parsing::Tokens::General::compile_parse_name_head(&save, &gprk,
			notice->parse_subject, NULL, notice->pnn_iname)) {
			PL::Parsing::Tokens::General::compile_parse_name_tail(&gprk);
			Routines::end(save);
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
int PL::Parsing::Tokens::General::compile_parse_name_head(packaging_state *save,
	gpr_kit *gprk, inference_subject *subj,
	grammar_verb *gv, inter_name *rname) {
	int test_distinguishability = FALSE, sometimes_has_visible_properties = FALSE;
	inter_name *N = NULL;

	if (subj == NULL) internal_error("compiling parse_name head for null subj");

	if (gv) {
		sometimes_has_visible_properties =
			PL::Parsing::Visibility::any_property_visible_to_subject(subj, TRUE);
		N = PL::Parsing::Tokens::General::get_gv_parse_name(gv);
	} else {
		if (PL::Parsing::Visibility::any_property_visible_to_subject(subj, FALSE)
			== FALSE) return FALSE;
	}

	if (InferenceSubjects::domain(subj)) test_distinguishability = TRUE;

	inter_name *compile_to = rname;
	if (compile_to == NULL) compile_to = N;
	if (compile_to == NULL) internal_error("no parse name routine name given");

	*save = Routines::begin(compile_to);

	PL::Parsing::Tokens::Values::add_parse_name_vars(gprk);

	PL::Parsing::Tokens::General::top_of_head(gprk, N, subj,
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
GVs destined to be |parse_name|s is stripped out and converted into the
|name| property.

There are clearly other possibilities and the above system is something of
a pragmatic compromise (in that to check other cases would be slower and
more complex). I suspect we will return to this.

=
void PL::Parsing::Tokens::General::top_of_head(gpr_kit *gprk, inter_name *gv_iname, inference_subject *subj,
	int test_distinguishability, int sometimes_has_visible_properties, inter_name *given_name) {

	Emit::inv_primitive(ifdebug_interp);
	Emit::down();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(ge_interp);
				Emit::down();
					Emit::val_iname(K_value, Hierarchy::find(PARSER_TRACE_HL));
					Emit::val(K_number, LITERAL_IVAL, 3);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_text(I"Parse_name called\n");
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	if ((gv_iname) && (sometimes_has_visible_properties == FALSE)) {
		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
				Emit::val_iname(K_value, Hierarchy::find(THESAME_HL));
			Emit::up();
			Emit::code();
			Emit::down();
				Emit::inv_primitive(return_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, 0);
				Emit::up();
			Emit::up();
		Emit::up();
	}
	@<Save word number@>;

	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->pass_s);
		Emit::val(K_number, LITERAL_IVAL, 1);
	Emit::up();
	Emit::inv_primitive(while_interp);
	Emit::down();
		Emit::inv_primitive(le_interp);
		Emit::down();
			Emit::val_symbol(K_value, gprk->pass_s);
			Emit::val(K_number, LITERAL_IVAL, 3);
		Emit::up();
		Emit::code();
		Emit::down();
			@<Reset word number@>;
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->try_from_wn_s);
				Emit::val_iname(K_value, Hierarchy::find(WN_HL));
			Emit::up();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->f_s);
				Emit::val(K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->n_s);
				Emit::val(K_number, LITERAL_IVAL, 0);
			Emit::up();
			Emit::inv_primitive(while_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 1);
				Emit::code();
				Emit::down();

					/* On pass 1 only, advance |wn| past name property words */
					/* (but do not do this for |##TheSame|, when |wn| is undefined) */
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(and_interp);
						Emit::down();
							Emit::inv_primitive(ne_interp);
							Emit::down();
								Emit::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
								Emit::val_iname(K_value, Hierarchy::find(THESAME_HL));
							Emit::up();
							Emit::inv_primitive(eq_interp);
							Emit::down();
								Emit::val_symbol(K_value, gprk->pass_s);
								Emit::val(K_number, LITERAL_IVAL, 1);
							Emit::up();
						Emit::up();
						Emit::code();
						Emit::down();
							Emit::inv_primitive(while_interp);
							Emit::down();
								Emit::inv_call_iname(Hierarchy::find(WORDINPROPERTY_HL));
								Emit::down();
									Emit::inv_call_iname(Hierarchy::find(NEXTWORDSTOPPED_HL));
									Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
									Emit::val_iname(K_value, PL::Parsing::Visibility::name_name());
								Emit::up();
								Emit::code();
								Emit::down();
									Emit::inv_primitive(store_interp);
									Emit::down();
										Emit::ref_symbol(K_value, gprk->f_s);
										Emit::val(K_truth_state, LITERAL_IVAL, 1);
									Emit::up();
								Emit::up();
							Emit::up();

							Emit::inv_primitive(postdecrement_interp);
							Emit::down();
								Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
							Emit::up();
							Emit::inv_primitive(store_interp);
							Emit::down();
								Emit::ref_symbol(K_value, gprk->try_from_wn_s);
								Emit::val_iname(K_value, Hierarchy::find(WN_HL));
							Emit::up();
						Emit::up();
					Emit::up();

					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(or_interp);
						Emit::down();
							Emit::inv_primitive(eq_interp);
							Emit::down();
								Emit::val_symbol(K_value, gprk->pass_s);
								Emit::val(K_number, LITERAL_IVAL, 1);
							Emit::up();
							Emit::inv_primitive(eq_interp);
							Emit::down();
								Emit::val_symbol(K_value, gprk->pass_s);
								Emit::val(K_number, LITERAL_IVAL, 2);
							Emit::up();
						Emit::up();
						Emit::code();
						Emit::down();
						PL::Parsing::Tokens::General::consider_visible_properties(gprk, subj, test_distinguishability);
						Emit::up();
					Emit::up();

					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(and_interp);
						Emit::down();
							Emit::inv_primitive(ne_interp);
							Emit::down();
								Emit::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
								Emit::val_iname(K_value, Hierarchy::find(THESAME_HL));
							Emit::up();
							Emit::inv_primitive(eq_interp);
							Emit::down();
								Emit::val_symbol(K_value, gprk->pass_s);
								Emit::val(K_number, LITERAL_IVAL, 1);
							Emit::up();
						Emit::up();
						Emit::code();
						Emit::down();
							Emit::inv_primitive(while_interp);
							Emit::down();
								Emit::inv_call_iname(Hierarchy::find(WORDINPROPERTY_HL));
								Emit::down();
									Emit::inv_call_iname(Hierarchy::find(NEXTWORDSTOPPED_HL));
									Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
									Emit::val_iname(K_value, PL::Parsing::Visibility::name_name());
								Emit::up();
								Emit::code();
								Emit::down();
									Emit::inv_primitive(store_interp);
									Emit::down();
										Emit::ref_symbol(K_value, gprk->f_s);
										Emit::val(K_truth_state, LITERAL_IVAL, 1);
									Emit::up();
								Emit::up();
							Emit::up();

							Emit::inv_primitive(postdecrement_interp);
							Emit::down();
								Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
							Emit::up();
							Emit::inv_primitive(store_interp);
							Emit::down();
								Emit::ref_symbol(K_value, gprk->try_from_wn_s);
								Emit::val_iname(K_value, Hierarchy::find(WN_HL));
							Emit::up();
						Emit::up();
					Emit::up();
}

@<Save word number@> =
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->original_wn_s);
		Emit::val_iname(K_value, Hierarchy::find(WN_HL));
	Emit::up();

@<Reset word number@> =
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
		Emit::val_symbol(K_value, gprk->original_wn_s);
	Emit::up();

@ The head and tail routines can only be understood by knowing that the
following code is used to reset the grammar-line parser after each failure
of a GL to parse.

=
void PL::Parsing::Tokens::General::after_gl_failed(gpr_kit *gprk, inter_symbol *label, int pluralised) {
	if (pluralised) {
		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
			Emit::val_iname(K_value, Hierarchy::find(PLURALFOUND_HL));
		Emit::up();
	}
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->try_from_wn_s);
		Emit::val_iname(K_value, Hierarchy::find(WN_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->f_s);
		Emit::val(K_truth_state, LITERAL_IVAL, 1);
	Emit::up();
	Emit::inv_primitive(continue_interp);

	Emit::place_label(label);
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
		Emit::val_symbol(K_value, gprk->try_from_wn_s);
	Emit::up();
}

@ The interesting point about the tail of the |parse_name| routine is that
it ends on the |]| "close routine" character, in mid-source line. This is
because the routine may be being used inside an |Object| directive, and
would therefore need to be followed by a comma, or in free-standing I6 code,
in which case it would need to be followed by a semi-colon.

=
void PL::Parsing::Tokens::General::compile_parse_name_tail(gpr_kit *gprk) {
					Emit::inv_primitive(break_interp);
				Emit::up();
			Emit::up();

			Emit::inv_primitive(while_interp);
			Emit::down();
				Emit::inv_call_iname(Hierarchy::find(WORDINPROPERTY_HL));
				Emit::down();
					Emit::inv_call_iname(Hierarchy::find(NEXTWORDSTOPPED_HL));
					Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
					Emit::val_iname(K_value, PL::Parsing::Visibility::name_name());
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(postincrement_interp);
					Emit::down();
						Emit::ref_symbol(K_value, gprk->n_s);
					Emit::up();
				Emit::up();
			Emit::up();

			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(or_interp);
				Emit::down();
					Emit::val_symbol(K_value, gprk->f_s);
					Emit::inv_primitive(gt_interp);
					Emit::down();
						Emit::val_symbol(K_value, gprk->n_s);
						Emit::val(K_number, LITERAL_IVAL, 0);
					Emit::up();
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(store_interp);
					Emit::down();
						Emit::ref_symbol(K_value, gprk->n_s);
						Emit::inv_primitive(minus_interp);
						Emit::down();
							Emit::inv_primitive(plus_interp);
							Emit::down();
								Emit::val_symbol(K_value, gprk->n_s);
								Emit::val_symbol(K_value, gprk->try_from_wn_s);
							Emit::up();
							Emit::val_symbol(K_value, gprk->original_wn_s);
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();

			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::val_symbol(K_value, gprk->pass_s);
					Emit::val(K_number, LITERAL_IVAL, 1);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(store_interp);
					Emit::down();
						Emit::ref_symbol(K_value, gprk->pass1_n_s);
						Emit::val_symbol(K_value, gprk->n_s);
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::val_symbol(K_value, gprk->pass_s);
					Emit::val(K_number, LITERAL_IVAL, 2);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(store_interp);
					Emit::down();
						Emit::ref_symbol(K_value, gprk->pass2_n_s);
						Emit::val_symbol(K_value, gprk->n_s);
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(postincrement_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->pass_s);
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(ifdebug_interp);
	Emit::down();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(ge_interp);
				Emit::down();
					Emit::val_iname(K_value, Hierarchy::find(PARSER_TRACE_HL));
					Emit::val(K_number, LITERAL_IVAL, 3);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_text(I"Pass 1: ");
					Emit::up();
					Emit::inv_primitive(printnumber_interp);
					Emit::down();
						Emit::val_symbol(K_value, gprk->pass1_n_s);
					Emit::up();
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_text(I" Pass 2: ");
					Emit::up();
					Emit::inv_primitive(printnumber_interp);
					Emit::down();
						Emit::val_symbol(K_value, gprk->pass2_n_s);
					Emit::up();
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_text(I" Pass 3: ");
					Emit::up();
					Emit::inv_primitive(printnumber_interp);
					Emit::down();
						Emit::val_symbol(K_value, gprk->n_s);
					Emit::up();
					Emit::inv_primitive(print_interp);
					Emit::down();
						Emit::val_text(I"\n");
					Emit::up();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(gt_interp);
		Emit::down();
			Emit::val_symbol(K_value, gprk->pass1_n_s);
			Emit::val_symbol(K_value, gprk->n_s);
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->n_s);
				Emit::val_symbol(K_value, gprk->pass1_n_s);
			Emit::up();
		Emit::up();
	Emit::up();
	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(gt_interp);
		Emit::down();
			Emit::val_symbol(K_value, gprk->pass2_n_s);
			Emit::val_symbol(K_value, gprk->n_s);
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->n_s);
				Emit::val_symbol(K_value, gprk->pass2_n_s);
			Emit::up();
		Emit::up();
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
		Emit::inv_primitive(plus_interp);
		Emit::down();
			Emit::val_symbol(K_value, gprk->original_wn_s);
			Emit::val_symbol(K_value, gprk->n_s);
		Emit::up();
	Emit::up();
	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(eq_interp);
		Emit::down();
			Emit::val_symbol(K_value, gprk->n_s);
			Emit::val(K_number, LITERAL_IVAL, 0);
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(return_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, (inter_t) -1);
			Emit::up();
		Emit::up();
	Emit::up();
	Emit::inv_call_iname(Hierarchy::find(DETECTPLURALWORD_HL));
	Emit::down();
		Emit::val_symbol(K_value, gprk->original_wn_s);
		Emit::val_symbol(K_value, gprk->n_s);
	Emit::up();
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val_symbol(K_value, gprk->n_s);
	Emit::up();
}

@ We generate code suitable for inclusion in a |parse_name| routine which
either tests distinguishability then parses, or else just parses, the
visible properties of a given subject (which may be a kind or instance).
Sometimes we allow visibility to be inherited from a permission given
to a kind, sometimes we require that the permission be given to this
specific object.

=
void PL::Parsing::Tokens::General::consider_visible_properties(gpr_kit *gprk, inference_subject *subj,
	int test_distinguishability) {
	int phase = 2;
	if (test_distinguishability) phase = 1;
	for (; phase<=2; phase++) {
		property *pr;
		PL::Parsing::Tokens::General::start_considering_visible_properties(gprk, phase);
		LOOP_OVER(pr, property) {
			if ((Properties::is_either_or(pr)) && (Properties::EitherOr::stored_in_negation(pr))) continue;
			property_permission *pp =
				World::Permissions::find(subj, pr, TRUE);
			if ((pp) && (PL::Parsing::Visibility::get_level(pp) > 0))
				PL::Parsing::Tokens::General::consider_visible_property(gprk, subj, pr, pp, phase);
		}
		PL::Parsing::Tokens::General::finish_considering_visible_properties(gprk, phase);
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

void PL::Parsing::Tokens::General::start_considering_visible_properties(gpr_kit *gprk, int phase) {
	visible_properties_code_written = FALSE;
}

void PL::Parsing::Tokens::General::consider_visible_property(gpr_kit *gprk, inference_subject *subj,
	property *pr, property_permission *pp, int phase) {
	int conditional_vis = FALSE;
	parse_node *spec;

	if (visible_properties_code_written == FALSE) {
		visible_properties_code_written = TRUE;
		if (phase == 1)
			PL::Parsing::Tokens::General::begin_distinguishing_visible_properties(gprk);
		else
			PL::Parsing::Tokens::General::begin_parsing_visible_properties(gprk);
	}

	spec = PL::Parsing::Visibility::get_condition(pp);

	if (spec) {
		conditional_vis = TRUE;
		if (phase == 1)
			PL::Parsing::Tokens::General::test_distinguish_visible_property(gprk, spec);
		else
			PL::Parsing::Tokens::General::test_parse_visible_property(gprk, spec);
	}

	if (phase == 1)
		PL::Parsing::Tokens::General::distinguish_visible_property(gprk, pr);
	else
		PL::Parsing::Tokens::General::parse_visible_property(gprk, subj, pr, PL::Parsing::Visibility::get_level(pp));

	if (conditional_vis) { Emit::up(); Emit::up(); }
}

void PL::Parsing::Tokens::General::finish_considering_visible_properties(gpr_kit *gprk, int phase) {
	if (visible_properties_code_written) {
		if (phase == 1)
			PL::Parsing::Tokens::General::finish_distinguishing_visible_properties(gprk);
		else
			PL::Parsing::Tokens::General::finish_parsing_visible_properties(gprk);
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
void PL::Parsing::Tokens::General::begin_distinguishing_visible_properties(gpr_kit *gprk) {
	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(eq_interp);
		Emit::down();
			Emit::val_iname(K_value, Hierarchy::find(PARSER_ACTION_HL));
			Emit::val_iname(K_value, Hierarchy::find(THESAME_HL));
		Emit::up();
		Emit::code();
		Emit::down();
			Emit::inv_primitive(ifdebug_interp);
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(if_interp);
					Emit::down();
						Emit::inv_primitive(ge_interp);
						Emit::down();
							Emit::val_iname(K_value, Hierarchy::find(PARSER_TRACE_HL));
							Emit::val(K_number, LITERAL_IVAL, 4);
						Emit::up();
						Emit::code();
						Emit::down();
							Emit::inv_primitive(print_interp);
							Emit::down();
								Emit::val_text(I"p1, p2 = ");
							Emit::up();
							Emit::inv_primitive(printnumber_interp);
							Emit::down();
								Emit::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
							Emit::up();
							Emit::inv_primitive(print_interp);
							Emit::down();
								Emit::val_text(I", ");
							Emit::up();
							Emit::inv_primitive(printnumber_interp);
							Emit::down();
								Emit::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
							Emit::up();
							Emit::inv_primitive(print_interp);
							Emit::down();
								Emit::val_text(I"\n");
							Emit::up();
						Emit::up();
					Emit::up();
				Emit::up();
			Emit::up();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->ss_s);
				Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
			Emit::up();
}

void PL::Parsing::Tokens::General::test_distinguish_visible_property(gpr_kit *gprk, parse_node *spec) {
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, Hierarchy::find(SELF_HL));
		Emit::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->f_s);
		Specifications::Compiler::emit_as_val(K_truth_state, spec);
	Emit::up();

	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, Hierarchy::find(SELF_HL));
		Emit::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->g_s);
		Specifications::Compiler::emit_as_val(K_truth_state, spec);
	Emit::up();

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::inv_primitive(ne_interp);
		Emit::down();
			Emit::val_symbol(K_value, gprk->f_s);
			Emit::val_symbol(K_value, gprk->g_s);
		Emit::up();
		Emit::code();
		Emit::down();
			@<Return minus two@>;
		Emit::up();
	Emit::up();

	Emit::inv_primitive(if_interp);
	Emit::down();
		Emit::val_symbol(K_value, gprk->f_s);
		Emit::code();
		Emit::down();
}

void PL::Parsing::Tokens::General::distinguish_visible_property(gpr_kit *gprk, property *prn) {
	TEMPORARY_TEXT(C);
	WRITE_TO(C, "Distinguishing property %n", Properties::iname(prn));
	Emit::code_comment(C);
	DISCARD_TEXT(C);

	if (Properties::is_either_or(prn)) {
		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::inv_primitive(and_interp);
			Emit::down();
				Properties::Emit::emit_iname_has_property(K_value, Hierarchy::find(PARSER_ONE_HL), prn);
				Emit::inv_primitive(not_interp);
				Emit::down();
					Properties::Emit::emit_iname_has_property(K_value, Hierarchy::find(PARSER_TWO_HL), prn);
				Emit::up();
			Emit::up();
			Emit::code();
			Emit::down();
				@<Return minus two@>;
			Emit::up();
		Emit::up();

		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::inv_primitive(and_interp);
			Emit::down();
				Properties::Emit::emit_iname_has_property(K_value, Hierarchy::find(PARSER_TWO_HL), prn);
				Emit::inv_primitive(not_interp);
				Emit::down();
					Properties::Emit::emit_iname_has_property(K_value, Hierarchy::find(PARSER_ONE_HL), prn);
				Emit::up();
			Emit::up();
			Emit::code();
			Emit::down();
				@<Return minus two@>;
			Emit::up();
		Emit::up();
	} else {
		kind *K = Properties::Valued::kind(prn);
		inter_name *distinguisher = Kinds::Behaviour::get_distinguisher_as_iname(K);
		Emit::inv_primitive(if_interp);
		Emit::down();
			if (distinguisher) {
				Emit::inv_call_iname(distinguisher);
				Emit::down();
					Emit::inv_primitive(propertyvalue_interp);
					Emit::down();
						Emit::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
						Emit::val_iname(K_value, Properties::iname(prn));
					Emit::up();
					Emit::inv_primitive(propertyvalue_interp);
					Emit::down();
						Emit::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
						Emit::val_iname(K_value, Properties::iname(prn));
					Emit::up();
				Emit::up();
			} else {
				Emit::inv_primitive(ne_interp);
				Emit::down();
					Emit::inv_primitive(propertyvalue_interp);
					Emit::down();
						Emit::val_iname(K_value, Hierarchy::find(PARSER_ONE_HL));
						Emit::val_iname(K_value, Properties::iname(prn));
					Emit::up();
					Emit::inv_primitive(propertyvalue_interp);
					Emit::down();
						Emit::val_iname(K_value, Hierarchy::find(PARSER_TWO_HL));
						Emit::val_iname(K_value, Properties::iname(prn));
					Emit::up();
				Emit::up();
			}
			Emit::code();
			Emit::down();
				@<Return minus two@>;
			Emit::up();
		Emit::up();
	}
}

@<Return minus two@> =
	Emit::inv_primitive(return_interp);
	Emit::down();
		Emit::val(K_number, LITERAL_IVAL, (inter_t) -2);
	Emit::up();

@ =
void PL::Parsing::Tokens::General::finish_distinguishing_visible_properties(gpr_kit *gprk) {
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(SELF_HL));
				Emit::val_symbol(K_value, gprk->ss_s);
			Emit::up();
			Emit::inv_primitive(return_interp);
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
	Emit::up();
}

@h Parsing visible properties.
Here, unlike in distinguishing visible properties, it is unambiguous that
|self| refers to the object being parsed: there is therefore no need to
alter the value of |self| to make any visibility condition work correctly.

=
void PL::Parsing::Tokens::General::begin_parsing_visible_properties(gpr_kit *gprk) {
	Emit::code_comment(I"Match any number of visible property values");
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->try_from_wn_s);
		Emit::val_iname(K_value, Hierarchy::find(WN_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->g_s);
		Emit::val(K_truth_state, LITERAL_IVAL, 1);
	Emit::up();
	Emit::inv_primitive(while_interp);
	Emit::down();
		Emit::val_symbol(K_value, gprk->g_s);
		Emit::code();
		Emit::down();
			Emit::inv_primitive(store_interp);
			Emit::down();
				Emit::ref_symbol(K_value, gprk->g_s);
				Emit::val(K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
}

void PL::Parsing::Tokens::General::test_parse_visible_property(gpr_kit *gprk, parse_node *spec) {
	Emit::inv_primitive(if_interp);
	Emit::down();
		Specifications::Compiler::emit_as_val(K_truth_state, spec);
		Emit::code();
		Emit::down();
}

int unique_pvp_counter = 0;
void PL::Parsing::Tokens::General::parse_visible_property(gpr_kit *gprk,
	inference_subject *subj, property *prn, int visibility_level) {
	TEMPORARY_TEXT(C);
	WRITE_TO(C, "Parsing property %n", Properties::iname(prn));
	Emit::code_comment(C);
	DISCARD_TEXT(C);

	if (Properties::is_either_or(prn)) {
		TEMPORARY_TEXT(L);
		WRITE_TO(L, ".pvp_pass_L_%d", unique_pvp_counter++);
		inter_symbol *pass_label = Emit::reserve_label(L);
		DISCARD_TEXT(L);

		PL::Parsing::Tokens::General::parse_visible_either_or(
			gprk, prn, visibility_level, pass_label);
		property *prnbar = Properties::EitherOr::get_negation(prn);
		if (prnbar)
			PL::Parsing::Tokens::General::parse_visible_either_or(
				gprk, prnbar, visibility_level, pass_label);

		Emit::place_label(pass_label);
	} else {
		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
			Emit::val_symbol(K_value, gprk->try_from_wn_s);
		Emit::up();

		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_symbol(K_value, gprk->spn_s);
			Emit::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
		Emit::up();
		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_symbol(K_value, gprk->ss_s);
			Emit::val_iname(K_value, Hierarchy::find(ETYPE_HL));
		Emit::up();

		Emit::inv_primitive(if_interp);
		Emit::down();
			kind *K = Properties::Valued::kind(prn);
			inter_name *recog_gpr = Kinds::Behaviour::get_recognition_only_GPR_as_iname(K);
			if (recog_gpr) {
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::inv_call_iname(recog_gpr);
					Emit::down();
						Emit::inv_primitive(propertyvalue_interp);
						Emit::down();
							Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
							Emit::val_iname(K_value, Properties::iname(prn));
						Emit::up();
					Emit::up();
					Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
				Emit::up();
			} else if (Kinds::Behaviour::offers_I6_GPR(K)) {
				inter_name *i6_gpr_name = Kinds::Behaviour::get_explicit_I6_GPR_iname(K);
				if (i6_gpr_name) {
					Emit::inv_primitive(and_interp);
					Emit::down();
						Emit::inv_primitive(eq_interp);
						Emit::down();
							Emit::inv_call_iname(i6_gpr_name);
							Emit::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
						Emit::up();
						Emit::inv_primitive(eq_interp);
						Emit::down();
							Emit::inv_primitive(propertyvalue_interp);
							Emit::down();
								Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
								Emit::val_iname(K_value, Properties::iname(prn));
							Emit::up();
							Emit::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
						Emit::up();
					Emit::up();
				} else if (Kinds::Behaviour::is_an_enumeration(K)) {
					Emit::inv_primitive(eq_interp);
					Emit::down();
						Emit::inv_call_iname(Kinds::RunTime::get_instance_GPR_iname(K));
						Emit::down();
							Emit::inv_primitive(propertyvalue_interp);
							Emit::down();
								Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
								Emit::val_iname(K_value, Properties::iname(prn));
							Emit::up();
						Emit::up();
						Emit::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
					Emit::up();
				} else {
					Emit::inv_primitive(and_interp);
					Emit::down();
						Emit::inv_primitive(eq_interp);
						Emit::down();
							Emit::inv_call_iname(Kinds::RunTime::get_kind_GPR_iname(K));
							Emit::val_iname(K_value, Hierarchy::find(GPR_NUMBER_HL));
						Emit::up();
						Emit::inv_primitive(eq_interp);
						Emit::down();
							Emit::inv_primitive(propertyvalue_interp);
							Emit::down();
								Emit::val_iname(K_value, Hierarchy::find(SELF_HL));
								Emit::val_iname(K_value, Properties::iname(prn));
							Emit::up();
							Emit::val_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
						Emit::up();
					Emit::up();
				}
			} else internal_error("Unable to recognise kind of value in parsing");
			Emit::code();
			Emit::down();
				Emit::inv_primitive(store_interp);
				Emit::down();
					Emit::ref_symbol(K_value, gprk->try_from_wn_s);
					Emit::val_iname(K_value, Hierarchy::find(WN_HL));
				Emit::up();
				Emit::inv_primitive(store_interp);
				Emit::down();
					Emit::ref_symbol(K_value, gprk->g_s);
					Emit::val(K_truth_state, LITERAL_IVAL, 1);
				Emit::up();
				if (visibility_level == 2) {
					Emit::inv_primitive(store_interp);
					Emit::down();
						Emit::ref_symbol(K_value, gprk->f_s);
						Emit::val(K_truth_state, LITERAL_IVAL, 1);
					Emit::up();
				}
			Emit::up();
		Emit::up();

		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
			Emit::val_symbol(K_value, gprk->spn_s);
		Emit::up();
		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_iname(K_value, Hierarchy::find(ETYPE_HL));
			Emit::val_symbol(K_value, gprk->ss_s);
		Emit::up();
	}
}

void PL::Parsing::Tokens::General::parse_visible_either_or(gpr_kit *gprk, property *prn, int visibility_level,
	inter_symbol *pass_l) {
	grammar_verb *gv = Properties::EitherOr::get_parsing_grammar(prn);
	PL::Parsing::Tokens::General::pvp_test_begins_dash(gprk);
	Emit::inv_primitive(if_interp);
	Emit::down();
		wording W = prn->name;
		int j = 0; LOOP_THROUGH_WORDING(i, W) j++;
		int ands = 0;
		if (j > 0) { Emit::inv_primitive(and_interp); Emit::down(); ands++; }
		Properties::Emit::emit_iname_has_property(K_value, Hierarchy::find(SELF_HL), prn);
		int k = 0;
		LOOP_THROUGH_WORDING(i, W) {
			if (k < j-1) { Emit::inv_primitive(and_interp); Emit::down(); ands++; }
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::inv_call_iname(Hierarchy::find(NEXTWORDSTOPPED_HL));
				TEMPORARY_TEXT(N);
				WRITE_TO(N, "%N", i);
				Emit::val_dword(N);
				DISCARD_TEXT(N);
			Emit::up();
			k++;
		}

		for (int a=0; a<ands; a++) Emit::up();
		Emit::code();
		Emit::down();
			PL::Parsing::Tokens::General::pvp_test_passes_dash(gprk, visibility_level, pass_l);
		Emit::up();
	Emit::up();
	if (gv) {
		if (gv->gv_prn_iname == NULL) internal_error("no PRN iname");
		PL::Parsing::Tokens::General::pvp_test_begins_dash(gprk);
		Emit::inv_primitive(if_interp);
		Emit::down();
			Emit::inv_primitive(and_interp);
			Emit::down();
				Properties::Emit::emit_iname_has_property(K_value, Hierarchy::find(SELF_HL), prn);
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::inv_call_iname(gv->gv_prn_iname);
					Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
				Emit::up();
			Emit::up();
			Emit::code();
			Emit::down();
				PL::Parsing::Tokens::General::pvp_test_passes_dash(gprk, visibility_level, pass_l);
			Emit::up();
		Emit::up();
	}
}

void PL::Parsing::Tokens::General::pvp_test_begins_dash(gpr_kit *gprk) {
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
		Emit::val_symbol(K_value, gprk->try_from_wn_s);
	Emit::up();
}

void PL::Parsing::Tokens::General::pvp_test_passes_dash(gpr_kit *gprk, int visibility_level, inter_symbol *pass_l) {
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->try_from_wn_s);
		Emit::val_iname(K_value, Hierarchy::find(WN_HL));
	Emit::up();
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_symbol(K_value, gprk->g_s);
		Emit::val(K_truth_state, LITERAL_IVAL, 1);
	Emit::up();
	if (visibility_level == 2) {
		Emit::inv_primitive(store_interp);
		Emit::down();
			Emit::ref_symbol(K_value, gprk->f_s);
			Emit::val(K_truth_state, LITERAL_IVAL, 1);
		Emit::up();
	}
	if (pass_l) {
		Emit::inv_primitive(jump_interp);
		Emit::down();
			Emit::lab(pass_l);
		Emit::up();
	}
}

void PL::Parsing::Tokens::General::finish_parsing_visible_properties(gpr_kit *gprk) {
		Emit::up();
	Emit::up();
	Emit::code_comment(I"try_from_wn is now advanced past any visible property values");
	Emit::inv_primitive(store_interp);
	Emit::down();
		Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
		Emit::val_symbol(K_value, gprk->try_from_wn_s);
	Emit::up();
}
