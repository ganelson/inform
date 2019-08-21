[PL::Parsing::Lines::] Grammar Lines.

A grammar line is a list of tokens to specify a textual pattern.
For example, the NI source for a grammar line might be |"take [something]
out"|, which is a sequence of three tokens.

@h Definitions.

@ A grammar line is in turn a sequence of tokens. If it matches, it will
result in 0, 1 or 2 parameters, though only if the grammar verb owning
the line is a genuine |GV_IS_COMMAND| command grammar will the case of
2 parameters be possible. (This is for text matching, say, "put X in Y":
the objects X and Y are two parameters resulting.) And in that case (alone),
there will also be a |resulting_action|.

A small amount of disjunction is allowed in a grammar line: for instance,
"look in/inside/into [something]" consists of five tokens, but only three
lexemes, basic units to be matched. (The first is "look", the second
is "one out of in, inside or into", and the third is an object in scope.)
In the following structure we cache the lexeme count since it is fiddly
to calculate, and useful when sorting grammar lines into applicability order.

The individual tokens are stored simply as parse tree nodes of type
|TOKEN_NT|, and are the children of the node |gl->tokens|, which is why
(for now, anyway) there is no grammar token structure.

@d UNCALCULATED_BONUS -1000000

=
typedef struct grammar_line {
	struct grammar_line *next_line; /* linked list in creation order */
	struct grammar_line *sorted_next_line; /* and in applicability order */

	struct parse_node *where_grammar_specified; /* where found in source */
	int original_text; /* the word number of the double-quoted grammar text... */
	struct parse_node *tokens; /* ...which is parsed into this list of tokens */
	int lexeme_count; /* number of lexemes, or |-1| if not yet counted */
	struct wording understand_when_text; /* only when this condition holds */
	struct pcalc_prop *understand_when_prop; /* and when this condition holds */

	int pluralised; /* |GV_IS_OBJECT|: refers in the plural */

	struct action_name *resulting_action; /* |GV_IS_COMMAND|: the action */
	int reversed; /* |GV_IS_COMMAND|: the two arguments are in reverse order */
	int mistaken; /* |GV_IS_COMMAND|: is this understood as a mistake? */
	struct wording mistake_response_text; /* if so, reply thus */

	struct grammar_type gl_type;

	int suppress_compilation; /* has been compiled in a single I6 grammar token already? */
	struct grammar_line *next_with_action; /* used when indexing actions */
	struct grammar_verb *belongs_to_gv; /* similarly, used only in indexing */

	struct inter_name *cond_token_iname; /* for its |Cond_Token_*| routine, if any */
	struct inter_name *mistake_iname; /* for its |Mistake_Token_*| routine, if any */

	int general_sort_bonus; /* temporary values used in grammar line sorting */
	int understanding_sort_bonus;

	MEMORY_MANAGEMENT
} grammar_line;

@ =
typedef struct slash_gpr {
	struct parse_node *first_choice;
	struct parse_node *last_choice;
	struct inter_name *sgpr_iname;
	MEMORY_MANAGEMENT
} slash_gpr;

@ =
grammar_line *PL::Parsing::Lines::new(int wn, action_name *ac,
	parse_node *token_list, int reversed, int pluralised) {
	grammar_line *gl;
	gl = CREATE(grammar_line);
	gl->original_text = wn;
	gl->resulting_action = ac;
	gl->belongs_to_gv = NULL;

	if (ac != NULL) PL::Actions::add_gl(ac, gl);

	gl->mistaken = FALSE;
	gl->mistake_response_text = EMPTY_WORDING;
	gl->next_with_action = NULL;
	gl->next_line = NULL;
	gl->tokens = token_list;
	gl->where_grammar_specified = current_sentence;
	gl->gl_type = PL::Parsing::Tokens::Types::new(TRUE);
	gl->lexeme_count = -1; /* no count made as yet */
	gl->reversed = reversed;
	gl->pluralised = pluralised;
	gl->understand_when_text = EMPTY_WORDING;
	gl->understand_when_prop = NULL;
	gl->suppress_compilation = FALSE;
	gl->general_sort_bonus = UNCALCULATED_BONUS;
	gl->understanding_sort_bonus = UNCALCULATED_BONUS;

	gl->cond_token_iname = NULL;
	gl->mistake_iname = NULL;

	return gl;
}

void PL::Parsing::Lines::log(grammar_line *gl) {
	LOG("<GL%d:%W>", gl->allocation_id, ParseTree::get_text(gl->tokens));
}

void PL::Parsing::Lines::set_single_type(grammar_line *gl, parse_node *gl_value) {
	PL::Parsing::Tokens::Types::set_single_type(&(gl->gl_type), gl_value);
}

@h GL lists.
Grammar lines are themselves generally stored in linked lists (belonging,
for instance, to a GV). Here we add a GL to the back of a list.

=
int PL::Parsing::Lines::list_length(grammar_line *list_head) {
	int c = 0;
	grammar_line *posn;
	for (posn = list_head; posn; posn = posn->next_line) c++;
	return c;
}

grammar_line *PL::Parsing::Lines::list_add(grammar_line *list_head, grammar_line *new_gl) {
	new_gl->next_line = NULL;
	if (list_head == NULL) list_head = new_gl;
	else {
		grammar_line *posn = list_head;
		while (posn->next_line) posn = posn->next_line;
		posn->next_line = new_gl;
	}
	return list_head;
}

grammar_line *PL::Parsing::Lines::list_remove(grammar_line *list_head, action_name *find) {
	grammar_line *prev = NULL, *posn = list_head;
	while (posn) {
		if (posn->resulting_action == find) {
			LOGIF(GRAMMAR_CONSTRUCTION, "Removing grammar line: $g\n", posn);
			if (prev) prev->next_line = posn->next_line;
			else list_head = posn->next_line;
		} else {
			prev = posn;
		}
		posn = posn->next_line;
	}
	return list_head;
}

@h Two special forms of grammar lines.
GLs can have either or both of two orthogonal special forms: they can be
mistaken or conditional. (Mistakes only occur in command grammars, but
conditional GLs can occur in any grammar.) GLs of this kind need special
support, in that I6 general parsing routines need to be compiled for them
to use as tokens: here's where that support is provided. The following
step needs to take place before the command grammar (I6 |Verb| directives,
etc.) is compiled because of I6's requirement that all GPRs be defined
as routines prior to the |Verb| directive using them.

=
void PL::Parsing::Lines::line_list_compile_condition_tokens(grammar_line *list_head) {
	grammar_line *gl;
	for (gl = list_head; gl; gl = gl->next_line) {
		PL::Parsing::Lines::gl_compile_condition_token_as_needed(gl);
		PL::Parsing::Lines::gl_compile_mistake_token_as_needed(gl);
	}
}

@h Conditional lines.
Some grammar lines take effect only when some circumstance holds: most I7
conditions are valid to specify this, with the notation "Understand ... as
... when ...". However, we want to protect new authors from mistakes
like this:

>> Understand "mate" as Fred when asking Fred to do something: ...

where the condition couldn't test anything useful because it's not yet
known what the action will be.

=
<understand-condition> ::=
	<s-non-action-condition> |	==> 0; <<parse_node:cond>> = RP[1];
	<s-condition> |				==> @<Issue PM_WhenAction problem@>
	...								==> @<Issue PM_BadWhen problem@>;

@<Issue PM_WhenAction problem@> =
	Problems::Issue::sentence_problem(_p_(PM_WhenAction),
		"the condition after 'when' involves the current action",
		"but this can never work, because when Inform is still trying to "
		"understand a command, the current action isn't yet decided on.");

@<Issue PM_BadWhen problem@> =
	Problems::Issue::sentence_problem(_p_(PM_BadWhen),
		"the condition after 'when' makes no sense to me",
		"although otherwise this worked - it is only the part after 'when' "
		"which I can't follow.");

@ Such GLs have an "understand when" set, as follows.
They compile preceded by a match-no-text token which matches correctly
if the condition holds and incorrectly if it fails. For instance, for
a command grammar, we might have:

|* Cond_Token_26 'draw' noun -> Draw|

=
void PL::Parsing::Lines::set_understand_when(grammar_line *gl, wording W) {
	gl->understand_when_text = W;
}
void PL::Parsing::Lines::set_understand_prop(grammar_line *gl, pcalc_prop *prop) {
	gl->understand_when_prop = prop;
}
int PL::Parsing::Lines::conditional(grammar_line *gl) {
	if ((Wordings::nonempty(gl->understand_when_text)) || (gl->understand_when_prop))
		return TRUE;
	return FALSE;
}

void PL::Parsing::Lines::gl_compile_condition_token_as_needed(grammar_line *gl) {
	if (PL::Parsing::Lines::conditional(gl)) {
		current_sentence = gl->where_grammar_specified;

		package_request *PR = Hierarchy::local_package(COND_TOKENS_HAP);
		gl->cond_token_iname = Hierarchy::make_iname_in(CONDITIONAL_TOKEN_FN_HL, PR);

		packaging_state save = Routines::begin(gl->cond_token_iname);

		parse_node *spec = NULL;
		if (Wordings::nonempty(gl->understand_when_text)) {
			current_sentence = gl->where_grammar_specified;
			if (<understand-condition>(gl->understand_when_text)) {
				spec = <<parse_node:cond>>;
				if (Dash::validate_conditional_clause(spec) == FALSE) {
					@<Issue PM_BadWhen problem@>;
					spec = NULL;
				}
			}
		}
		pcalc_prop *prop = gl->understand_when_prop;

		if ((spec) || (prop)) {
			Emit::inv_primitive(Emit::opcode(IF_BIP));
			Emit::down();
				if ((spec) && (prop)) {
					Emit::inv_primitive(Emit::opcode(AND_BIP));
					Emit::down();
				}
				if (spec) Specifications::Compiler::emit_as_val(K_truth_state, spec);
				if (prop) Calculus::Deferrals::emit_test_of_proposition(Rvalues::new_self_object_constant(), prop);
				if ((spec) && (prop)) {
					Emit::up();
				}
				Emit::code();
				Emit::down();
					Emit::inv_primitive(Emit::opcode(RETURN_BIP));
					Emit::down();
						Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
					Emit::up();
				Emit::up();
			Emit::up();
		}
		Emit::inv_primitive(Emit::opcode(RETURN_BIP));
		Emit::down();
			Emit::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
		Emit::up();

		Routines::end(save);
	}
}

void PL::Parsing::Lines::gl_compile_extra_token_for_condition(gpr_kit *gprk, grammar_line *gl,
	int gv_is, inter_symbol *current_label) {
	if (PL::Parsing::Lines::conditional(gl)) {
		if (gl->cond_token_iname == NULL) internal_error("GL cond token not ready");
		if (gv_is == GV_IS_COMMAND) {
			Emit::array_iname_entry(gl->cond_token_iname);
		} else {
			Emit::inv_primitive(Emit::opcode(IF_BIP));
			Emit::down();
				Emit::inv_primitive(Emit::opcode(EQ_BIP));
				Emit::down();
					Emit::inv_call_iname(gl->cond_token_iname);
					Emit::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(Emit::opcode(JUMP_BIP));
					Emit::down();
						Emit::lab(current_label);
					Emit::up();
				Emit::up();
			Emit::up();
		}
	}
}

@h Mistakes.
These are grammar lines used in command GVs for commands which are accepted
but only in order to print nicely worded rejections. A number of schemes
were tried for this, for instance producing parser errors and setting |pe|
to some high value, but the method now used is for a mistaken line to
produce a successful parse at the I6 level, resulting in the (I6 only)
action |##MistakeAction|. The tricky part is to send information to the
I6 action routine |MistakeActionSub| indicating what the mistake was,
exactly: we do this by including, in the I6 grammar, a token which
matches empty text and returns a "preposition", so that it has no
direct result, but which also sets a special global variable as a
side-effect. Thus a mistaken line "act [thing]" comes out as something
like:

|* Mistake_Token_12 'act' noun -> MistakeAction|

Since the I6 parser accepts the first command which matches, and since
none of this can be recursive, the value of this variable at the end of
I6 parsing is guaranteed to be the one set during the line causing
the mistake.

=
void PL::Parsing::Lines::set_mistake(grammar_line *gl, int wn) {
	gl->mistaken = TRUE;
	gl->mistake_response_text = Wordings::one_word(wn);
	if (gl->mistake_iname == NULL) {
		package_request *PR = Hierarchy::local_package(MISTAKES_HAP);
		gl->mistake_iname = Hierarchy::make_iname_in(MISTAKE_FN_HL, PR);
	}
}

void PL::Parsing::Lines::gl_compile_mistake_token_as_needed(grammar_line *gl) {
	if (gl->mistaken) {
		packaging_state save = Routines::begin(gl->mistake_iname);

		Emit::inv_primitive(Emit::opcode(IF_BIP));
		Emit::down();
			Emit::inv_primitive(Emit::opcode(NE_BIP));
			Emit::down();
				Emit::val_iname(K_object, Hierarchy::find(ACTOR_HL));
				Emit::val_iname(K_object, Hierarchy::find(PLAYER_HL));
			Emit::up();
			Emit::code();
			Emit::down();
				Emit::inv_primitive(Emit::opcode(RETURN_BIP));
				Emit::down();
					Emit::val_iname(K_value, Hierarchy::find(GPR_FAIL_HL));
				Emit::up();
			Emit::up();
		Emit::up();

		Emit::inv_primitive(Emit::opcode(STORE_BIP));
		Emit::down();
			Emit::ref_iname(K_number, Hierarchy::find(UNDERSTAND_AS_MISTAKE_NUMBER_HL));
			Emit::val(K_number, LITERAL_IVAL, (inter_t) (100 + gl->allocation_id));
		Emit::up();

		Emit::inv_primitive(Emit::opcode(RETURN_BIP));
		Emit::down();
			Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
		Emit::up();

		Routines::end(save);
	}
}

void PL::Parsing::Lines::gl_compile_extra_token_for_mistake(grammar_line *gl, int gv_is) {
	if (gl->mistaken) {
		if (gv_is == GV_IS_COMMAND) {
			Emit::array_iname_entry(gl->mistake_iname);
		} else
			internal_error("GLs may only be mistaken in command grammar");
	}
}

inter_name *MistakeAction_iname = NULL;

int PL::Parsing::Lines::gl_compile_result_of_mistake(gpr_kit *gprk, grammar_line *gl) {
	if (gl->mistaken) {
		if (MistakeAction_iname == NULL) internal_error("no MistakeAction yet");
		Emit::array_iname_entry(VERB_DIRECTIVE_RESULT_iname);
		Emit::array_iname_entry(MistakeAction_iname);
		return TRUE;
	}
	return FALSE;
}

void PL::Parsing::Lines::MistakeActionSub_routine(void) {
	package_request *MAP = Hierarchy::synoptic_package(SACTIONS_HAP);
	packaging_state save = Routines::begin(Hierarchy::make_iname_in(MISTAKEACTIONSUB_HL, MAP));

	Emit::inv_primitive(Emit::opcode(SWITCH_BIP));
	Emit::down();
		Emit::val_iname(K_value, Hierarchy::find(UNDERSTAND_AS_MISTAKE_NUMBER_HL));
		Emit::code();
		Emit::down();
			grammar_line *gl;
			LOOP_OVER(gl, grammar_line)
				if (gl->mistaken) {
					if (Wordings::nonempty(gl->mistake_response_text)) {
						current_sentence = gl->where_grammar_specified;
						parse_node *spec = NULL;
						if (<s-value>(gl->mistake_response_text))
							spec = <<rp>>;
						else spec = Specifications::new_UNKNOWN(gl->mistake_response_text);
						Emit::inv_primitive(Emit::opcode(CASE_BIP));
						Emit::down();
							Emit::val(K_number, LITERAL_IVAL, (inter_t) (100+gl->allocation_id));
							Emit::code();
							Emit::down();
								Emit::inv_call_iname(Hierarchy::find(PARSERERROR_HL));
								Emit::down();
									Specifications::Compiler::emit_constant_to_kind_as_val(spec, K_text);
								Emit::up();
							Emit::up();
						Emit::up();
					}
				}

			Emit::inv_primitive(Emit::opcode(DEFAULT_BIP));
			Emit::down();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(Emit::opcode(PRINT_BIP));
					Emit::down();
						Emit::val_text(I"I didn't understand that sentence.\n");
					Emit::up();
					Emit::rtrue();
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Emit::inv_primitive(Emit::opcode(STORE_BIP));
	Emit::down();
		Emit::ref_iname(K_number, Hierarchy::find(SAY__P_HL));
		Emit::val(K_number, LITERAL_IVAL, 1);
	Emit::up();

	Routines::end(save);
	
	MistakeAction_iname = Hierarchy::make_iname_in(MISTAKEACTION_HL, MAP);
	Emit::named_pseudo_numeric_constant(MistakeAction_iname, K_action_name, 10000);
	Emit::annotate_i(MistakeAction_iname, ACTION_IANN, 1);
	Hierarchy::make_available(MistakeAction_iname);
}

@h Single word optimisation.
The grammars used to parse names of objects are normally compiled into
|parse_name| routines. But the I6 parser also uses the |name| property,
and it is advantageous to squeeze as much as possible into |name| and
as little as possible into |parse_name|. The only possible candidates
are grammar lines consisting of single unconditional words, as detected
by the following routine:

=
int PL::Parsing::Lines::gl_contains_single_unconditional_word(grammar_line *gl) {
	parse_node *pn = gl->tokens->down;
	if ((pn)
		&& (pn->next == NULL)
		&& (ParseTree::int_annotation(pn, slash_class_ANNOT) == 0)
		&& (ParseTree::int_annotation(pn, grammar_token_literal_ANNOT))
		&& (gl->pluralised == FALSE)
		&& (PL::Parsing::Lines::conditional(gl) == FALSE))
		return Wordings::first_wn(ParseTree::get_text(pn));
	return -1;
}

@ This routine looks through a GL list and marks to suppress all those
GLs consisting only of single unconditional words, which means they
will not be compiled into a |parse_name| routine (or anywhere else).
If the |of| file handle is set, then the words in question are printed
as I6-style dictionary words to it. In practice, this is done when
compiling the |name| property, so that a single scan achieves both
the transfer into |name| and the exclusion from |parse_name| of
affected GLs.

=
grammar_line *PL::Parsing::Lines::list_take_out_one_word_grammar(grammar_line *list_head) {
	grammar_line *gl, *glp;
	for (gl = list_head, glp = NULL; gl; gl = gl->next_line) {
		int wn = PL::Parsing::Lines::gl_contains_single_unconditional_word(gl);
		if (wn >= 0) {
			TEMPORARY_TEXT(content);
			WRITE_TO(content, "%w", Lexer::word_text(wn));
			Emit::array_dword_entry(content);
			DISCARD_TEXT(content);
			gl->suppress_compilation = TRUE;
		} else glp = gl;
	}
	return list_head;
}

@h Phase I: Slash Grammar.
Slashing is an activity carried out on a per-grammar-line basis, so to slash
a list of GLs we simply slash each GL in turn.

=
void PL::Parsing::Lines::line_list_slash(grammar_line *gl_head) {
	grammar_line *gl;
	for (gl = gl_head; gl; gl = gl->next_line) {
		PL::Parsing::Lines::slash_grammar_line(gl);
	}
}

@ Now the actual slashing process, which does not descend to tokens. We
remove any slashes, and fill in positive numbers in the |qualifier| field
corresponding to non-singleton equivalence classes. Thus "take up/in all
washing/laundry/linen" begins as 10 tokens, three of them forward slashes,
and ends as 7 tokens, with |qualifier| values 0, 1, 1, 0, 2, 2, 2, for
four equivalence classes in turn. Each equivalence class is one lexical
unit, or "lexeme", so the lexeme count is then 4.

In addition, if one of the slashed options is "--", then this means the
empty word, and is removed from the token list; but the first token of the
lexeme is annotated accordingly.

=
void PL::Parsing::Lines::slash_grammar_line(grammar_line *gl) {
	parse_node *pn;
	int alternatives_group = 0;

	current_sentence = gl->where_grammar_specified; /* to report problems */

	if (gl->tokens == NULL)
		internal_error("Null tokens on grammar");

	LOGIF(GRAMMAR_CONSTRUCTION, "Preparing grammar line:\n$T", gl->tokens);

	for (pn = gl->tokens->down; pn; pn = pn->next)
		ParseTree::annotate_int(pn, slash_class_ANNOT, 0);

	parse_node *class_start = NULL;
	for (pn = gl->tokens->down; pn; pn = pn->next) {
		if ((pn->next) &&
			(Wordings::length(ParseTree::get_text(pn->next)) == 1) &&
			(Lexer::word(Wordings::first_wn(ParseTree::get_text(pn->next))) == FORWARDSLASH_V)) { /* slash follows: */
			if (ParseTree::int_annotation(pn, slash_class_ANNOT) == 0) {
				class_start = pn; alternatives_group++; /* start new equiv class */
				ParseTree::annotate_int(class_start, slash_dash_dash_ANNOT, FALSE);
			}

			ParseTree::annotate_int(pn, slash_class_ANNOT,
				alternatives_group); /* make two sides of slash equiv */
			if (pn->next->next)
				ParseTree::annotate_int(pn->next->next, slash_class_ANNOT, alternatives_group);
			if ((pn->next->next) &&
				(Wordings::length(ParseTree::get_text(pn->next->next)) == 1) &&
				(Lexer::word(Wordings::first_wn(ParseTree::get_text(pn->next->next))) == DOUBLEDASH_V)) { /* -- follows: */
				ParseTree::annotate_int(class_start, slash_dash_dash_ANNOT, TRUE);
				pn->next = pn->next->next->next; /* excise slash and dash-dash */
			} else {
				pn->next = pn->next->next; /* excise the slash from the token list */
			}
		}
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Regrouped as:\n$T", gl->tokens);

	for (pn = gl->tokens->down; pn; pn = pn->next)
		if ((ParseTree::int_annotation(pn, slash_class_ANNOT) > 0) &&
			(ParseTree::int_annotation(pn, grammar_token_literal_ANNOT) == FALSE)) {
			Problems::Issue::sentence_problem(_p_(PM_OverAmbitiousSlash),
				"the slash '/' can only be used between single literal words",
				"so 'underneath/under/beneath' is allowed but "
				"'beneath/[florid ways to say under]/under' isn't.");
			break;
		}

	gl->lexeme_count = 0;

	for (pn = gl->tokens->down; pn; pn = pn->next) {
		int i = ParseTree::int_annotation(pn, slash_class_ANNOT);
		if (i > 0)
			while ((pn->next) && (ParseTree::int_annotation(pn->next, slash_class_ANNOT) == i))
				pn = pn->next;
		gl->lexeme_count++;
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Slashed as:\n$T", gl->tokens);
}

@h Phase II: Determining Grammar.
Here there is substantial work to do both at the line list level and on
individual lines, and the latter does recurse down to token level too.

The following routine calculates the type of the GL list as the union
of the types of the GLs within it, where union means the narrowest type
such that every GL in the list casts to it. We return null if there
are no GLs in the list, or if the GLs all return null types, or if
an error occurs. (Note that actions in command verb grammars are counted
as null for this purpose, since a grammar used for parsing the player's
commands is not also used to determine a value.)

=
parse_node *PL::Parsing::Lines::line_list_determine(grammar_line *list_head,
	int depth, int gv_is, grammar_verb *gv, int genuinely_verbal) {
	grammar_line *gl;
	int first_flag = TRUE;
	parse_node *spec_union = NULL;
	LOGIF(GRAMMAR_CONSTRUCTION, "Determining GL list for $G\n", gv);

	for (gl = list_head; gl; gl = gl->next_line) {
		parse_node *spec_of_line =
			PL::Parsing::Lines::gl_determine(gl, depth, gv_is, gv, genuinely_verbal);

		if (first_flag) { /* initially no expectations: |spec_union| is meaningless */
			spec_union = spec_of_line; /* so we set it to the first result */
			first_flag = FALSE;
			continue;
		}

		if ((spec_union == NULL) && (spec_of_line == NULL))
			continue; /* we expected to find no result, and did: so no problem */

		if ((spec_union) && (spec_of_line)) {
			if (Dash::compatible_with_description(spec_union, spec_of_line) == ALWAYS_MATCH) {
				spec_union = spec_of_line; /* here |spec_of_line| was a wider type */
				continue;
			}
			if (Dash::compatible_with_description(spec_of_line, spec_union) == ALWAYS_MATCH) {
				continue; /* here |spec_union| was already wide enough */
			}
		}

		if (PL::Parsing::Verbs::allow_mixed_lines(gv)) continue;

		current_sentence = gl->where_grammar_specified;
		Problems::Issue::sentence_problem(_p_(PM_MixedOutcome),
			"grammar tokens must have the same outcome whatever the way they are "
			"reached",
			"so writing a line like 'Understand \"within\" or \"next to "
			"[something]\" as \"[my token]\" must be wrong: one way it produces "
			"a thing, the other way it doesn't.");
		spec_union = NULL;
		break; /* to prevent the problem being repeated for the same grammar */
	}

	LOGIF(GRAMMAR_CONSTRUCTION, "Union: $P\n");
	return spec_union;
}

@ There are three tasks here: to determine the type of the GL, to issue a
problem if this type is impossibly large, and to calculate two numerical
quantities used in sorting GLs: the "general sorting bonus" and the
"understanding sorting bonus" (see below).

=
parse_node *PL::Parsing::Lines::gl_determine(grammar_line *gl, int depth,
	int gv_is, grammar_verb *gv, int genuinely_verbal) {
	parse_node *spec = NULL;
	parse_node *pn, *pn2;
	int nulls_count, i, nrv, line_length;
	current_sentence = gl->where_grammar_specified;

	gl->understanding_sort_bonus = 0;
	gl->general_sort_bonus = 0;

	nulls_count = 0; /* number of tokens with null results */

	pn = gl->tokens->down; /* start from first token */
	if ((genuinely_verbal) && (pn)) pn = pn->next; /* unless it's a command verb */

	for (pn2=pn, line_length=0; pn2; pn2 = pn2->next) line_length++;

	int multiples = 0;
	for (i=0; pn; pn = pn->next, i++) {
		if (ParseTree::get_type(pn) != TOKEN_NT)
			internal_error("Bogus node types on grammar");

		int score = 0;
		spec = PL::Parsing::Tokens::determine(pn, depth, &score);
		LOGIF(GRAMMAR_CONSTRUCTION, "Result of token <%W> is $P\n", ParseTree::get_text(pn), spec);

		if (spec) {
			if ((Specifications::is_kind_like(spec)) &&
				(Kinds::Compare::eq(Specifications::to_kind(spec), K_understanding))) { /* "[text]" token */
				int usb_contribution = i - 100;
				if (usb_contribution >= 0) usb_contribution = -1;
				usb_contribution = 100*usb_contribution + (line_length-1-i);
				gl->understanding_sort_bonus += usb_contribution; /* reduces! */
			}
			gl->general_sort_bonus +=
				PL::Parsing::Tokens::Types::add_type(&(gl->gl_type), spec,
					PL::Parsing::Tokens::is_multiple(pn), score);
		} else nulls_count++;

		if (PL::Parsing::Tokens::is_multiple(pn)) multiples++;
	}

	if (multiples > 1)
		Problems::Issue::sentence_problem(_p_(PM_MultipleMultiples),
			"there can be at most one token in any line which can match "
			"multiple things",
			"so you'll have to remove one of the 'things' tokens and "
			"make it a 'something' instead.");

	nrv = PL::Parsing::Tokens::Types::get_no_resulting_values(&(gl->gl_type));
	if (nrv == 0) gl->general_sort_bonus = 100*nulls_count;
	if (gv_is == GV_IS_COMMAND) spec = NULL;
	else {
		if (nrv < 2) spec = PL::Parsing::Tokens::Types::get_single_type(&(gl->gl_type));
		else Problems::Issue::sentence_problem(_p_(PM_TwoValuedToken),
			"there can be at most one varying part in the definition of a "
			"named token",
			"so 'Understand \"button [a number]\" as \"[button indication]\"' "
			"is allowed but 'Understand \"button [a number] on [something]\" "
			"as \"[button indication]\"' is not.");
	}

	LOGIF(GRAMMAR_CONSTRUCTION,
		"Determined $g: lexeme count %d, sorting bonus %d, arguments %d, "
		"fixed initials %d, type $P\n",
		gl, gl->lexeme_count, gl->general_sort_bonus, nrv,
		gl->understanding_sort_bonus, spec);

	return spec;
}

@h Phase III: Sort Grammar.
Insertion sort is used to take the linked list of GLs and construct a
separate, sorted version. This is not the controversial part.

=
grammar_line *PL::Parsing::Lines::list_sort(grammar_line *list_head) {
	grammar_line *gl, *gl2, *gl3, *sorted_head;

	if (list_head == NULL) return NULL;

	sorted_head = list_head;
	list_head->sorted_next_line = NULL;

	gl = list_head;
	while (gl->next_line) {
		gl = gl->next_line;
		gl2 = sorted_head;
		if (PL::Parsing::Lines::grammar_line_must_precede(gl, gl2)) {
			sorted_head = gl;
			gl->sorted_next_line = gl2;
			continue;
		}
		while (gl2) {
			gl3 = gl2;
			gl2 = gl2->sorted_next_line;
			if (gl2 == NULL) {
				gl3->sorted_next_line = gl;
				break;
			}
			if (PL::Parsing::Lines::grammar_line_must_precede(gl, gl2)) {
				gl3->sorted_next_line = gl;
				gl->sorted_next_line = gl2;
				break;
			}
		}
	}
	return sorted_head;
}

@ This is the controversial part: the routine which decides whether one GL
takes precedence (i.e., is parsed earlier than and thus in preference to)
another GL. This algorithm has been hacked many times to try to reach a
position which pleases all designers: something of a lost cause. The
basic motivation is that we need to sort because the various parsers of
I7 grammar (|parse_name| routines, general parsing routines, the I6 command
parser itself) all work by returning the first match achieved. This means
that if grammar line L2 matches a superset of the texts which grammar line
L1 matches, then L1 should be tried first: trying them in the order L2, L1
would mean that L1 could never be matched, which is surely contrary to the
designer's intention. (Compare the rule-sorting algorithm, which has similar
motivation but is entirely distinct, though both use the same primitive
methods for comparing types of single values, i.e., at stages 5b1 and 5c1
below.)

Recall that each GL has a numerical USB (understanding sort bonus) and
GSB (general sort bonus). The following rules are applied in sequence:

(1) Higher USBs beat lower USBs.

(2a) For sorting GLs in player-command grammar, shorter lines beat longer
lines, where length is calculated as the lexeme count.

(2b) For sorting all other GLs, longer lines beat shorter lines.

(3) Mistaken commands beat unmistaken commands.

(4) Higher GSBs beat lower GSBs.

(5a) Fewer resulting values beat more resulting values.

(5b1) A narrower first result type beats a wider first result type, if
there is a first result.

(5b2) A multiples-disallowed first result type beats a multiples-allowed
first result type, if there is a first result.

(5c1) A narrower second result type beats a wider second result type, if
there is a second result.

(5c2) A multiples-disallowed second result type beats a multiples-allowed
second result type, if there is a second result.

(6) Conditional lines (with a "when" proviso, that is) beat
unconditional lines.

(7) The grammar line defined earlier beats the one defined later.

Rule 1 is intended to resolve awkward ambiguities involved with command
grammar which includes "[text]" tokens. Each such token subtracts 10000 from
the USB of a line but adds back 100 times the token position (which is at least
0 and which we can safely suppose is less than 99: we truncate just in case
so that every |"[text]"| certainly makes a negative contribution of at least
$-100$) and then subtracts off the number of tokens left on the line.

Because a high USB gets priority, and "[text]" tokens make a negative
contribution, the effect is to relegate lines containing "[text]" tokens
to the bottom of the list -- which is good because "[text]" voraciously
eats up words, matching more or less anything, so that any remotely
specific case ought to be tried first. The effect of the curious addition
back in of the token position is that later-placed "[text]" tokens are
tried before earlier-placed ones. Thus |"read chapter [text]"| has a USB
of $-98$, and takes precedence over |"read [text]"| with a USB of $-99$,
but both are beaten by just |"read [something]"| with a USB of 0.
The effect of the subtraction back of the number of tokens remaining
is to ensure that |"read [token] backwards"| takes priority over
|"read [token]"|.

The voracity of |"[text]"|, and its tendency to block out all other
possibilities unless restrained, has to be addressed by this lexically
based numerical calculation because it works in a lexical sort of way:
playing with the types system to prefer |DESCRIPTION/UNDERSTANDING|
over, say, |VALUE/OBJECT| would not be sufficient.

The most surprising point here is the asymmetry in rule 2, which basically
says that when parsing commands typed at the keyboard, shorter beats longer,
whereas in all other settings longer beats shorter. This arises because the
I6 parser, at run time, traditionally works that way: I6 command grammars
are normally stored with short forms first and long forms afterward. The
I6 parser can afford to do this because it is matching text of known length:
if parsing TAKE FROG FROM AQUARIUM, it will try TAKE FROG first but is able
to reject this as not matching the whole text. In other parsing settings,
we are trying to make a maximum-length match against a potentially infinite
stream of words, and it is therefore important to try to match WATERY
CASCADE EFFECT before WATERY CASCADE when looking at text like WATERY
CASCADE EFFECT IMPRESSES PEOPLE, given that the simplistic parsers we
compile generally return the first match found.

Rule 3, that mistakes beat non-mistakes, was in fact rule 1 during 2006: it
seemed logical that since mistakes were exceptional cases, they would be
better checked earlier before moving on to general cases. However, an
example provided by Eric Eve showed that although this was logically correct,
the I6 parser would try to auto-complete lengthy mistakes and thus fail to
check subsequent commands. For this reason, |"look behind [something]"|
as a mistake needs to be checked after |"look"|, or else the I6 parser
will respond to the command LOOK by replying "What do you want to look
behind?" -- and then saying that you are mistaken.

Rule 4 is intended as a lexeme-based tiebreaker. We only get here if there
are the same number of lexemes in the two GLs being compared. Each is
given a GSB score as follows: a literal lexeme, which produces no result,
such as |"draw"| or |"in/inside/within"|, scores 100; all other lexemes
score as follows:

-- |"[things inside]"| scores a GSB of 10 as the first parameter, 1 as the second;

-- |"[things preferably held]"| similarly scores a GSB of 20 or 2;

-- |"[other things]"| similarly scores a GSB of 20 or 2;

-- |"[something preferably held]"| similarly scores a GSB of 30 or 3;

-- any token giving a logical description of some class of objects, such as
|"[open container]"|, similarly scores a GSB of 50 or 5;

-- and any remaining token (for instance, one matching a number or some other
kind of value) scores a GSB of 0.

Literals score highly because they are structural, and differentiate
cases: under the superset rule, |"look up [thing]"| must be parsed before
|"look [direction] [thing]"|, and it is only the number of literals which
differentiates these cases. If two lines have an equal number of literals,
we now look at the first resultant lexeme. Here we find that a lexeme which
specifies an object (with a GSB of at least 10/1) beats a lexeme which only
specifies a value. Thus the same text will be parsed against objects in
preference to values, which is sensible since there are generally few
objects available to the player and they are generally likely to be the
things being referred to. Among possible object descriptions, the very
general catch-all special cases above are given lower GSB scores than
more specific ones, to enable the more specific cases to go first.

Rule 5a is unlikely to have much effect: it is likely to be rare for GL
lists to contain GLs mixing different numbers of results. But Rule 5b1
is very significant: it causes |"draw [animal]"| to have precedence over
|"draw [thing]"|, for instance. Rule 5b2 ensures that |"draw [thing]"|
takes precedence over |"draw [things]"|, which may be useful to handle
multiple and single objects differently.

The motivation for rule 6 is similar to the case of "when" clauses for
rules in rulebooks: it ensures that a match of |"draw [thing]"| when some
condition holds beats a match of |"draw [thing]"| at any time, and this is
necessary under the strict superset principle.

To get to rule 7 looks difficult, given the number of things about the
grammar lines which must match up -- same USB, GSB, number of lexemes,
number of resulting types, equivalent resulting types, same conditional
status -- but in fact it isn't all that uncommon. Equivalent pairs produced
by the Standard Rules include:

|"get off [something]"| and |"get in/into/on/onto [something]"|

|"turn on [something]"| and |"turn [something] on"|

Only the second of these pairs leads to ambiguity, and even then only if
an object has a name like ON VISION ON -- perhaps a book about the antique
BBC children's television programme "Vision On" -- so that the command
TURN ON VISION ON would match both of the alternative GLs.

=
int PL::Parsing::Lines::grammar_line_must_precede(grammar_line *L1, grammar_line *L2) {
	int cs, a, b;

	if ((L1 == NULL) || (L2 == NULL))
		internal_error("tried to sort null GLs");
	if ((L1->lexeme_count == -1) || (L2->lexeme_count == -1))
		internal_error("tried to sort unslashed GLs");
	if ((L1->general_sort_bonus == UNCALCULATED_BONUS) ||
		(L2->general_sort_bonus == UNCALCULATED_BONUS))
		internal_error("tried to sort uncalculated GLs");
	if (L1 == L2) return FALSE;

	a = FALSE; if ((L1->resulting_action) || (L1->mistaken)) a = TRUE;
	b = FALSE; if ((L2->resulting_action) || (L2->mistaken)) b = TRUE;
	if (a != b) {
		LOG("L1 = $g\nL2 = $g\n", L1, L2);
		internal_error("tried to sort on incomparable GLs");
	}

	if (L1->understanding_sort_bonus > L2->understanding_sort_bonus) return TRUE;
	if (L1->understanding_sort_bonus < L2->understanding_sort_bonus) return FALSE;

	if (a) { /* command grammar: shorter beats longer */
		if (L1->lexeme_count < L2->lexeme_count) return TRUE;
		if (L1->lexeme_count > L2->lexeme_count) return FALSE;
	} else { /* all other grammars: longer beats shorter */
		if (L1->lexeme_count < L2->lexeme_count) return FALSE;
		if (L1->lexeme_count > L2->lexeme_count) return TRUE;
	}

	if ((L1->mistaken) && (L2->mistaken == FALSE)) return TRUE;
	if ((L1->mistaken == FALSE) && (L2->mistaken)) return FALSE;

	if (L1->general_sort_bonus > L2->general_sort_bonus) return TRUE;
	if (L1->general_sort_bonus < L2->general_sort_bonus) return FALSE;

	cs = PL::Parsing::Tokens::Types::must_precede(&(L1->gl_type), &(L2->gl_type));
	if (cs != NOT_APPLICABLE) return cs;

	if ((PL::Parsing::Lines::conditional(L1)) && (PL::Parsing::Lines::conditional(L2) == FALSE)) return TRUE;
	if ((PL::Parsing::Lines::conditional(L1) == FALSE) && (PL::Parsing::Lines::conditional(L2))) return FALSE;

	return FALSE;
}

@h Phase IV: Compile Grammar.
At this level we compile the list of GLs in sorted order: this is what the
sorting was all for. In certain cases, we skip any GLs marked as "one word":
these are cases arising from, e.g., "Understand "frog" as the toad.",
where we noticed that the GL was a single word and included it in the |name|
property instead. This is faster and more flexible, besides writing tidier
code.

The need for this is not immediately obvious. After all, shouldn't we have
simply deleted the GL in the first place, rather than leaving it in but
marking it? The answer is no, because of the way inheritance works: values
of the |name| property accumulate from class to instance in I6, since
|name| is additive, but grammar doesn't.

=
void PL::Parsing::Lines::sorted_line_list_compile(gpr_kit *gprk, grammar_line *list_head,
	int gv_is, grammar_verb *gv, int genuinely_verbal) {
	for (grammar_line *gl = list_head; gl; gl = gl->sorted_next_line)
		if (gl->suppress_compilation == FALSE)
			PL::Parsing::Lines::compile_grammar_line(gprk, gl, gv_is, gv, genuinely_verbal);
}

@ The following apparently global variables are used to provide a persistent
state for the routine below, but are not accessed elsewhere. The label
counter is reset at the start of each GV's compilation, though this is a
purely cosmetic effect.

=
int current_grammar_block = 0;
int current_label = 1;
int GV_IS_VALUE_instance_mode = FALSE;

void PL::Parsing::Lines::reset_labels(void) {
	current_label = 1;
}

@ As fancy as the following routine may look, it contains very little.
What complexity there is comes from the fact that command GVs are compiled
very differently to all others (most grammars are compiled in "code mode",
generating procedural I6 statements, but command GVs are compiled to lines
in |Verb| directives) and that GLs resulting in actions (i.e., GLs in
command GVs) have not yet been type-checked, whereas all others have.

=
void PL::Parsing::Lines::compile_grammar_line(gpr_kit *gprk, grammar_line *gl, int gv_is, grammar_verb *gv,
	int genuinely_verbal) {
	parse_node *pn;
	int i;
	int token_values;
	kind *token_value_kinds[2];
	int code_mode, consult_mode;

	LOGIF(GRAMMAR, "Compiling grammar line: $g\n", gl);

	current_sentence = gl->where_grammar_specified;

	if (gv_is == GV_IS_COMMAND) code_mode = FALSE; else code_mode = TRUE;
	if (gv_is == GV_IS_CONSULT) consult_mode = TRUE; else consult_mode = FALSE;

	switch (gv_is) {
		case GV_IS_COMMAND:
		case GV_IS_TOKEN:
		case GV_IS_CONSULT:
		case GV_IS_OBJECT:
		case GV_IS_VALUE:
		case GV_IS_PROPERTY_NAME:
			break;
		default: internal_error("tried to compile unknown GV type");
	}

	current_grammar_block++;
	token_values = 0;
	for (i=0; i<2; i++) token_value_kinds[i] = NULL;

	if (code_mode == FALSE) Emit::array_iname_entry(VERB_DIRECTIVE_DIVIDER_iname);

	inter_symbol *fail_label = NULL;

	if (gprk) {
		TEMPORARY_TEXT(L);
		WRITE_TO(L, ".Fail_%d", current_label);
		fail_label = Emit::reserve_label(L);
		DISCARD_TEXT(L);
	}

	PL::Parsing::Lines::gl_compile_extra_token_for_condition(gprk, gl, gv_is, fail_label);
	PL::Parsing::Lines::gl_compile_extra_token_for_mistake(gl, gv_is);

	pn = gl->tokens->down;
	if ((genuinely_verbal) && (pn)) {
		if (ParseTree::int_annotation(pn, slash_class_ANNOT) != 0) {
			Problems::Issue::sentence_problem(_p_(PM_SlashedCommand),
				"at present you're not allowed to use a / between command "
				"words at the start of a line",
				"so 'put/interpose/insert [something]' is out.");
			return;
		}
		pn = pn->next; /* skip command word: the |Verb| header contains it already */
	}

	if ((gv_is == GV_IS_VALUE) && (GV_IS_VALUE_instance_mode)) {
		Emit::inv_primitive(Emit::opcode(IF_BIP));
		Emit::down();
			Emit::inv_primitive(Emit::opcode(EQ_BIP));
			Emit::down();
				Emit::val_symbol(K_value, gprk->instance_s);
				PL::Parsing::Tokens::Types::compile_to_string(&(gl->gl_type));
			Emit::up();
			Emit::code();
			Emit::down();
	}

	parse_node *pn_from = pn, *pn_to = pn_from;
	for (; pn; pn = pn->next) pn_to = pn;

	PL::Parsing::Lines::compile_token_line(gprk, code_mode, pn_from, pn_to, gv_is, consult_mode, &token_values, token_value_kinds, NULL, fail_label);

	switch (gv_is) {
		case GV_IS_COMMAND:
			if (PL::Parsing::Lines::gl_compile_result_of_mistake(gprk, gl)) break;
			Emit::array_iname_entry(VERB_DIRECTIVE_RESULT_iname);
			Emit::array_action_entry(gl->resulting_action);

			if (gl->reversed) {
				if (token_values < 2) {
					Problems::Issue::sentence_problem(_p_(PM_CantReverseOne),
						"you can't use a 'reversed' action when you supply fewer "
						"than two values for it to apply to",
						"since reversal is the process of exchanging them.");
					return;
				}
				kind *swap = token_value_kinds[0];
				token_value_kinds[0] = token_value_kinds[1];
				token_value_kinds[1] = swap;
				Emit::array_iname_entry(VERB_DIRECTIVE_REVERSE_iname);
			}

			PL::Actions::check_types_for_grammar(gl->resulting_action, token_values,
				token_value_kinds);
			break;
		case GV_IS_PROPERTY_NAME:
		case GV_IS_TOKEN:
			Emit::inv_primitive(Emit::opcode(RETURN_BIP));
			Emit::down();
				Emit::val_symbol(K_value, gprk->rv_s);
			Emit::up();
			Emit::place_label(fail_label);
			Emit::inv_primitive(Emit::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk->rv_s);
				Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Emit::up();
			Emit::inv_primitive(Emit::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
				Emit::val_symbol(K_value, gprk->original_wn_s);
			Emit::up();
			break;
		case GV_IS_CONSULT:
			Emit::inv_primitive(Emit::opcode(IF_BIP));
			Emit::down();
				Emit::inv_primitive(Emit::opcode(OR_BIP));
				Emit::down();
					Emit::inv_primitive(Emit::opcode(EQ_BIP));
					Emit::down();
						Emit::val_symbol(K_value, gprk->range_words_s);
						Emit::val(K_number, LITERAL_IVAL, 0);
					Emit::up();
					Emit::inv_primitive(Emit::opcode(EQ_BIP));
					Emit::down();
						Emit::inv_primitive(Emit::opcode(MINUS_BIP));
						Emit::down();
							Emit::val_iname(K_value, Hierarchy::find(WN_HL));
							Emit::val_symbol(K_value, gprk->range_from_s);
						Emit::up();
						Emit::val_symbol(K_value, gprk->range_words_s);
					Emit::up();
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::inv_primitive(Emit::opcode(RETURN_BIP));
					Emit::down();
						Emit::val_symbol(K_value, gprk->rv_s);
					Emit::up();
				Emit::up();
			Emit::up();

			Emit::place_label(fail_label);
			Emit::inv_primitive(Emit::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_symbol(K_value, gprk->rv_s);
				Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
			Emit::up();
			Emit::inv_primitive(Emit::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
				Emit::val_symbol(K_value, gprk->original_wn_s);
			Emit::up();
			break;
		case GV_IS_OBJECT:
			PL::Parsing::Tokens::General::after_gl_failed(gprk, fail_label, gl->pluralised);
			break;
		case GV_IS_VALUE:
			Emit::inv_primitive(Emit::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(PARSED_NUMBER_HL));
				PL::Parsing::Tokens::Types::compile_to_string(&(gl->gl_type));
			Emit::up();
			Emit::inv_primitive(Emit::opcode(RETURN_BIP));
			Emit::down();
				Emit::val_iname(K_object, Hierarchy::find(GPR_NUMBER_HL));
			Emit::up();
			Emit::place_label(fail_label);
			Emit::inv_primitive(Emit::opcode(STORE_BIP));
			Emit::down();
				Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
				Emit::val_symbol(K_value, gprk->original_wn_s);
			Emit::up();
			break;
	}

	if ((gv_is == GV_IS_VALUE) && (GV_IS_VALUE_instance_mode)) {
			Emit::up();
		Emit::up();
	}

	current_label++;
}

void PL::Parsing::Lines::compile_token_line(gpr_kit *gprk, int code_mode, parse_node *pn, parse_node *pn_to, int gv_is, int consult_mode,
	int *token_values, kind **token_value_kinds, inter_symbol *group_wn_s, inter_symbol *fail_label) {
	int lexeme_equivalence_class = 0;
	int alternative_number = 0;
	int empty_text_allowed_in_lexeme = FALSE;

	inter_symbol *next_reserved_label = NULL;
	inter_symbol *eog_reserved_label = NULL;
	for (; pn; pn = pn->next) {
		if ((PL::Parsing::Tokens::is_text(pn)) && (pn->next) &&
			(PL::Parsing::Tokens::is_literal(pn->next) == FALSE)) {
			Problems::Issue::sentence_problem(_p_(PM_TextFollowedBy),
				"a '[text]' token must either match the end of some text, or "
				"be followed by definitely known wording",
				"since otherwise the run-time parser isn't good enough to "
				"make sense of things.");
		}

		if ((ParseTree::get_grammar_token_relation(pn)) && (gv_is != GV_IS_OBJECT)) {
			Problems::Issue::sentence_problem(_p_(PM_GrammarObjectlessRelation),
				"a grammar token in an 'Understand...' can only be based "
				"on a relation if it is to understand the name of a room or thing",
				"since otherwise there is nothing for the relation to be with.");
			continue;
		}

		int first_token_in_lexeme = FALSE, last_token_in_lexeme = FALSE;

		if (ParseTree::int_annotation(pn, slash_class_ANNOT) != 0) { /* in a multi-token lexeme */
			if ((pn->next == NULL) ||
				(ParseTree::int_annotation(pn->next, slash_class_ANNOT) !=
					ParseTree::int_annotation(pn, slash_class_ANNOT)))
				last_token_in_lexeme = TRUE;
			if (ParseTree::int_annotation(pn, slash_class_ANNOT) != lexeme_equivalence_class) {
				first_token_in_lexeme = TRUE;
				empty_text_allowed_in_lexeme =
					ParseTree::int_annotation(pn, slash_dash_dash_ANNOT);
			}
			lexeme_equivalence_class = ParseTree::int_annotation(pn, slash_class_ANNOT);
			if (first_token_in_lexeme) alternative_number = 1;
			else alternative_number++;
		} else { /* in a single-token lexeme */
			lexeme_equivalence_class = 0;
			first_token_in_lexeme = TRUE;
			last_token_in_lexeme = TRUE;
			empty_text_allowed_in_lexeme = FALSE;
			alternative_number = 1;
		}

		inter_symbol *jump_on_fail = fail_label;

		if (lexeme_equivalence_class > 0) {
			if (code_mode) {
				if (first_token_in_lexeme) {
					Emit::inv_primitive(Emit::opcode(STORE_BIP));
					Emit::down();
						Emit::ref_symbol(K_value, gprk->group_wn_s);
						Emit::val_iname(K_value, Hierarchy::find(WN_HL));
					Emit::up();
				}
				if (next_reserved_label) Emit::place_label(next_reserved_label);
				TEMPORARY_TEXT(L);
				WRITE_TO(L, ".group_%d_%d_%d", current_grammar_block, lexeme_equivalence_class, alternative_number+1);
				next_reserved_label = Emit::reserve_label(L);
				DISCARD_TEXT(L);

				Emit::inv_primitive(Emit::opcode(STORE_BIP));
				Emit::down();
					Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
					Emit::val_symbol(K_value, gprk->group_wn_s);
				Emit::up();

				if ((last_token_in_lexeme == FALSE) || (empty_text_allowed_in_lexeme)) {
					jump_on_fail = next_reserved_label;
				}
			}
		}

		if ((empty_text_allowed_in_lexeme) && (code_mode == FALSE)) {
			slash_gpr *sgpr = CREATE(slash_gpr);
			sgpr->first_choice = pn;
			while ((pn->next) &&
					(ParseTree::int_annotation(pn->next, slash_class_ANNOT) ==
					ParseTree::int_annotation(pn, slash_class_ANNOT))) pn = pn->next;
			sgpr->last_choice = pn;
			package_request *PR = Hierarchy::local_package(SLASH_TOKENS_HAP);
			sgpr->sgpr_iname = Hierarchy::make_iname_in(SLASH_FN_HL, PR);
			Emit::array_iname_entry(sgpr->sgpr_iname);
			last_token_in_lexeme = TRUE;
		} else {
			kind *grammar_token_kind =
				PL::Parsing::Tokens::compile(gprk, pn, code_mode, jump_on_fail, consult_mode);
			if (grammar_token_kind) {
				if (token_values) {
					if (*token_values == 2) {
						internal_error(
							"There can be at most two value-producing tokens and this "
							"should have been detected earlier.");
						return;
					}
					token_value_kinds[(*token_values)++] = grammar_token_kind;
				}
			}
		}

		if (lexeme_equivalence_class > 0) {
			if (code_mode) {
				if (last_token_in_lexeme) {
					if (empty_text_allowed_in_lexeme) {
						@<Jump to end of group@>;
						if (next_reserved_label)
							Emit::place_label(next_reserved_label);
						next_reserved_label = NULL;
						Emit::inv_primitive(Emit::opcode(STORE_BIP));
						Emit::down();
							Emit::ref_iname(K_value, Hierarchy::find(WN_HL));
							Emit::val_symbol(K_value, gprk->group_wn_s);
						Emit::up();
					}
					if (eog_reserved_label) Emit::place_label(eog_reserved_label);
					eog_reserved_label = NULL;
				} else {
					@<Jump to end of group@>;
				}
			} else {
				if (last_token_in_lexeme == FALSE) Emit::array_iname_entry(VERB_DIRECTIVE_SLASH_iname);
			}
		}

		if (pn == pn_to) break;
	}
}

@<Jump to end of group@> =
	if (eog_reserved_label == NULL) {
		TEMPORARY_TEXT(L);
		WRITE_TO(L, ".group_%d_%d_end",
			current_grammar_block, lexeme_equivalence_class);
		eog_reserved_label = Emit::reserve_label(L);
	}
	Emit::inv_primitive(Emit::opcode(JUMP_BIP));
	Emit::down();
		Emit::lab(eog_reserved_label);
	Emit::up();

@ =
void PL::Parsing::Lines::compile_slash_gprs(void) {
	slash_gpr *sgpr;
	LOOP_OVER(sgpr, slash_gpr) {
		packaging_state save = Routines::begin(sgpr->sgpr_iname);
		gpr_kit gprk = PL::Parsing::Tokens::Values::new_kit();
		PL::Parsing::Tokens::Values::add_original(&gprk);
		PL::Parsing::Tokens::Values::add_standard_set(&gprk);

		PL::Parsing::Lines::compile_token_line(&gprk, TRUE, sgpr->first_choice, sgpr->last_choice, GV_IS_TOKEN, FALSE, NULL, NULL, gprk.group_wn_s, NULL);
		Emit::inv_primitive(Emit::opcode(RETURN_BIP));
		Emit::down();
			Emit::val_iname(K_value, Hierarchy::find(GPR_PREPOSITION_HL));
		Emit::up();
		Routines::end(save);
	}
}

@h Indexing by grammar.
This is the more obvious form of indexing: we show the grammar lines which
make up an individual GL. (For instance, this is used in the Actions index
to show the grammar for an individual command word, by calling the routine
below for that command word's GV.) Such an index list is done in sorted
order, so that the order of appearance in the index corresponds to the
order of parsing -- this is what the reader of the index is interested in.

=
void PL::Parsing::Lines::sorted_list_index_normal(OUTPUT_STREAM,
	grammar_line *list_head, text_stream *headword) {
	grammar_line *gl;
	for (gl = list_head; gl; gl = gl->sorted_next_line)
		PL::Parsing::Lines::gl_index_normal(OUT, gl, headword);
}

void PL::Parsing::Lines::gl_index_normal(OUTPUT_STREAM, grammar_line *gl, text_stream *headword) {
	action_name *an = gl->resulting_action;
	if (an == NULL) return;
	Index::anchor(OUT, headword);
	if (PL::Actions::is_out_of_world(an))
		HTML::begin_colour(OUT, I"800000");
	WRITE("&quot;");
	PL::Actions::Index::verb_definition(OUT, Lexer::word_text(gl->original_text),
		headword, EMPTY_WORDING);
	WRITE("&quot;");
	Index::link(OUT, gl->original_text);
	WRITE(" - <i>%+W", an->present_name);
	Index::detail_link(OUT, "A", an->allocation_id, TRUE);
	if (gl->reversed) WRITE(" (reversed)");
	WRITE("</i>");
	if (PL::Actions::is_out_of_world(an))
		HTML::end_colour(OUT);
	HTML_TAG("br");
}

@h Indexing by action.
Grammar lines are typically indexed twice: the other time is when all
grammar lines belonging to a given action are tabulated. Special linked
lists are kept for this purpose, and this is where we unravel them and
print to the index. The question of sorted vs unsorted is meaningless
here, since the GLs appearing in such a list will typically belong to
several different GVs. (As it happens, they appear in order of creation,
i.e., in source text order.)

Tiresomely, all of this means that we need to store "uphill" pointers
in GLs: back up to the GVs that own them. The following routine does
this for a whole list of GLs:

=
void PL::Parsing::Lines::list_assert_ownership(grammar_line *list_head, grammar_verb *gv) {
	grammar_line *gl;
	for (gl = list_head; gl; gl = gl->next_line)
		gl->belongs_to_gv = gv;
}

@ And this routine accumulates the per-action lists of GLs:

=
void PL::Parsing::Lines::list_with_action_add(grammar_line *list_head, grammar_line *gl) {
	if (list_head == NULL) internal_error("tried to add to null action list");
	while (list_head->next_with_action)
		list_head = list_head->next_with_action;
	list_head->next_with_action = gl;
}

@ Finally, here we index an action list of GLs, each getting a line in
the HTML index.

=
int PL::Parsing::Lines::index_list_with_action(OUTPUT_STREAM, grammar_line *gl) {
	int said_something = FALSE;
	while (gl != NULL) {
		if (gl->belongs_to_gv) {
			wording VW = PL::Parsing::Verbs::get_verb_text(gl->belongs_to_gv);
			TEMPORARY_TEXT(trueverb);
			if (Wordings::nonempty(VW))
				WRITE_TO(trueverb, "%W", Wordings::one_word(Wordings::first_wn(VW)));
			HTMLFiles::open_para(OUT, 2, "hanging");
			WRITE("&quot;");
			PL::Actions::Index::verb_definition(OUT,
				Lexer::word_text(gl->original_text), trueverb, VW);
			WRITE("&quot;");
			Index::link(OUT, gl->original_text);
			if (gl->reversed) WRITE(" <i>reversed</i>");
			HTML_CLOSE("p");
			said_something = TRUE;
			DISCARD_TEXT(trueverb);
		}
		gl = gl->next_with_action;
	}
	return said_something;
}

@ And the same, but more simply:

=
void PL::Parsing::Lines::index_list_for_token(OUTPUT_STREAM, grammar_line *gl) {
	int k = 0;
	while (gl != NULL) {
		if (gl->belongs_to_gv) {
			wording VW = PL::Parsing::Verbs::get_verb_text(gl->belongs_to_gv);
			TEMPORARY_TEXT(trueverb);
			if (Wordings::nonempty(VW))
				WRITE_TO(trueverb, "%W", Wordings::one_word(Wordings::first_wn(VW)));
			HTMLFiles::open_para(OUT, 2, "hanging");
			if (k++ == 0) WRITE("="); else WRITE("or");
			WRITE(" &quot;");
			PL::Actions::Index::verb_definition(OUT,
				Lexer::word_text(gl->original_text), trueverb, EMPTY_WORDING);
			WRITE("&quot;");
			Index::link(OUT, gl->original_text);
			if (gl->reversed) WRITE(" <i>reversed</i>");
			HTML_CLOSE("p");
			DISCARD_TEXT(trueverb);
		}
		gl = gl->sorted_next_line;
	}
}
