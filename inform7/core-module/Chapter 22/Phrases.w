[Phrases::] Phrases.

To create one |phrase| object for each phrase declaration in the
source text.

@h Definitions.

@ As noted in the introduction to this chapter, a |phrase| structure is
created for each "To..." definition and each rule in the source text. It is
divided internally into five substructures, the PHTD, PHUD, PHRCD, PHSF
and PHOD.

Two more abbreviations appear in this section. The first is the EFF, or
the "effect" of a phrase, which categorises all phrases into four:
"To..." phrases, phrases used to define adjective, rules explicitly naming
a rulebook they belong to, and rules not doing so. (This is called the "effect"
because it decides under what circumstances the phrase will be executed
at run-time.)

@d TO_PHRASE_EFF 1 				/* "To award (some - number) points: ..." */
@d RULE_IN_RULEBOOK_EFF 2 		/* "Before taking a container, ..." */
@d RULE_NOT_IN_RULEBOOK_EFF 3 	/* "At 9 PM: ...", "This is the zap rule: ..." */
@d DEFINITIONAL_PHRASE_EFF 4 	/* "Definition: a container is roomy if: ..." */

@ The second new abbreviation is MOR, the "manner of return", which is only
of interest for "To..." phrases. Some of these decide a value, some decide a
condition, some decide nothing (but exist in order to do something); the
exceptional case is the last, |DECIDES_NOTHING_AND_RETURNS_MOR|, which marks
out a phrase which exits the phrase it is invoked from -- like the statement
|return| in a C function. (There is no way to create such a phrase in source
text without using an inline definition, and the intention is that only the
Standard Rules will ever make phrases like it.)

@d DONT_KNOW_MOR 1						/* but ask me later */
@d DECIDES_NOTHING_MOR 2				/* e.g., "award 4 points" */
@d DECIDES_VALUE_MOR 3					/* e.g., "square root of 16" */
@d DECIDES_CONDITION_MOR 4				/* e.g., "a random chance of 1 in 3 succeeds" */
@d DECIDES_NOTHING_AND_RETURNS_MOR 5	/* e.g., "continue the action" */

@ And here is the structure. Note that the MOR and EFF are stored inside
the sub-structures, and aren't visible here; but they're relevant to the
code below.

=
typedef struct phrase {
	struct parse_node *declaration_node; /* |RULE_NT| node where declared */
	int inline_wn; /* word number of inline I6 definition, or |-1| if not inline */
	struct inter_schema *inter_head_defn; /* inline definition translated to inter, if possible */
	struct inter_schema *inter_tail_defn; /* inline definition translated to inter, if possible */
	int inter_defn_converted; /* has this been tried yet? */
	int inline_mor; /* manner of return for inline I6 definition, or |UNKNOWN_NT| */
	struct wording ph_documentation_symbol; /* cross-reference with documentation */
	struct compilation_module *owning_module;
	struct package_request *requests_package;
	struct package_request *rule_package;

	struct ph_type_data type_data;
	struct ph_usage_data usage_data;
	struct ph_runtime_context_data runtime_context_data;
	struct ph_stack_frame stack_frame;
	struct ph_options_data options_data;

	int at_least_one_compiled_form_needed; /* do we still need to compile this? */
	int compile_with_run_time_debugging; /* in the RULES command */
	struct inter_name *ph_iname; /* or NULL for inline phrases */
	int to_begin; /* for Basic mode only: this is the main routine */
	int imported;

	struct phrase *next_in_logical_order; /* for "to..." phrases only */
	int sequence_count; /* within the logical order list, from 0 */

	CLASS_DEFINITION
} phrase;

@ "To..." phrases, though no others, are listed in logical precedence order:

=
struct phrase *first_in_logical_order = NULL;

@ The life of a |phrase| structure begins when we look at the parse-tree
representation of its declaration in the source text.

A phrase is inline if and only if its definition consists of a single
invocation which is given as verbatim I6.

=
void Phrases::create_from_preamble(parse_node *p) {
	if ((p == NULL) || (Node::get_type(p) != RULE_NT))
		internal_error("a phrase preamble should be at a RULE_NT node");
	int inline_wn = -1; 		/* the word number of an inline I6 definition if any */
	int mor = DONT_KNOW_MOR;	/* and its manner of return */
	wording OW = EMPTY_WORDING;	/* the text of the phrase options, if any */
	wording documentation_W = EMPTY_WORDING; /* the documentation reference, if any */

	@<Look for an inline definition@>;

	ph_options_data phod;
	ph_type_data phtd;
	ph_usage_data phud;
	ph_stack_frame phsf;
	ph_runtime_context_data phrcd;

	@<Parse for the PHUD in fine mode@>;

	int effect = Phrases::Usage::get_effect(&phud);
	if ((inline_wn >= 0) && (effect != TO_PHRASE_EFF)) @<Inline is for To... phrases only@>;

	if ((effect != DEFINITIONAL_PHRASE_EFF) && (p->down == NULL))
		@<There seems to be no definition@>;

	@<Construct the PHTD, find the phrase options, find the documentation reference@>;
	@<Construct the PHOD@>;
	@<Construct the PHSF, using the PHTD and PHOD@>;
	@<Construct the PHRCD@>;

	phrase *new_ph;
	@<Create the phrase structure@>;
	@<Tell other parts of Inform about this new phrase@>;
}

@<Look for an inline definition@> =
	if ((p->down) && (p->down->down) && (p->down->down->next == NULL))
		Phrases::parse_possible_inline_defn(
			Node::get_text(p->down->down), &inline_wn, &mor);
	if (inline_wn >= 0) {
		wchar_t *inline_defn = Lexer::word_text(inline_wn);
		if (Wide::len(inline_defn) >= MAX_INLINE_DEFN_LENGTH)
			@<Forbid overly long inline definitions@>;
	}

@<Parse for the PHUD in fine mode@> =
	phud = Phrases::Usage::new(Node::get_text(p), FALSE);

@<Construct the PHTD, find the phrase options, find the documentation reference@> =
	wording XW = Phrases::Usage::get_preamble_text(&phud);
	phtd = Phrases::TypeData::new();
	if (inline_wn >= 0) Phrases::TypeData::make_inline(&phtd);
	switch (effect) {
		case TO_PHRASE_EFF:
			documentation_W = Index::DocReferences::position_of_symbol(&XW);
			Phrases::TypeData::Textual::parse(&phtd, XW, &OW);
			break;
		case DEFINITIONAL_PHRASE_EFF:
			Phrases::TypeData::set_mor(&phtd, DECIDES_CONDITION_MOR, NULL);
			break;
		default:
			Phrases::TypeData::set_mor(&phtd, DECIDES_NOTHING_AND_RETURNS_MOR, NULL);
			break;
	}

@<Construct the PHOD@> =
	phod = Phrases::Options::parse_declared_options(OW);

@ The stack frame needs to know the kind of this phrase -- something like
= (text as Inform 6)
	phrase number -> text
=
-- in order to work out what happens when values are decided by it later on.
We also tell the stack frame if there are phrase options, because then a
special parameter called |{phrase options}| is available when expanding
inline definitions.

@<Construct the PHSF, using the PHTD and PHOD@> =
	phsf = Frames::new();
	Phrases::TypeData::into_stack_frame(&phsf, &phtd,
		Phrases::TypeData::kind(&phtd), TRUE);
	if (Phrases::Options::allows_options(&phod))
		LocalVariables::options_parameter_is_needed(&phsf);

@<Construct the PHRCD@> =
	phrcd = Phrases::Context::new();

@<Tell other parts of Inform about this new phrase@> =
	switch (effect) {
		case TO_PHRASE_EFF:
			if (phud.to_begin) new_ph->to_begin = TRUE;
			Routines::ToPhrases::new(new_ph);
			break;
		case DEFINITIONAL_PHRASE_EFF:
			@<Give this phrase a local variable for the subject of the definition@>;
			break;
		case RULE_IN_RULEBOOK_EFF:
			Rules::request_automatic_placement(
				Phrases::Usage::to_rule(&(new_ph->usage_data), new_ph));
			new_ph->compile_with_run_time_debugging = TRUE;
			break;
		case RULE_NOT_IN_RULEBOOK_EFF:
			Phrases::Usage::to_rule(&(new_ph->usage_data), new_ph);
			new_ph->compile_with_run_time_debugging = TRUE;
			break;
	}

@ If a phrase defines an adjective, like so:

>> Definition: A container is capacious if: ...

we need to make the pronoun "it" a local variable of kind "container" in the
stack frame used to compile the "..." part. If it uses a calling, like so:

>> Definition: A container (called the sack) is capacious if: ...

then we also want the name "sack" to refer to this. Here's where we take care
of it:

@<Give this phrase a local variable for the subject of the definition@> =
	wording CW = EMPTY_WORDING;
	kind *K = NULL;
	Phrases::Phrasal::define_adjective_by_phrase(p, new_ph, &CW, &K);
	LocalVariables::add_pronoun(&(new_ph->stack_frame), CW, K);

@<Create the phrase structure@> =
	wording XW = Phrases::Usage::get_preamble_text(&phud);
	LOGIF(PHRASE_CREATIONS, "Creating phrase: <%W>\n$U", XW, &phud);

	new_ph = CREATE(phrase);
	new_ph->declaration_node = p;

	new_ph->options_data = phod;
	new_ph->runtime_context_data = phrcd;
	new_ph->stack_frame = phsf;
	new_ph->type_data = phtd;
	new_ph->usage_data = phud;

	new_ph->inline_wn = inline_wn;
	new_ph->inter_head_defn = NULL;
	new_ph->inter_tail_defn = NULL;
	new_ph->inter_defn_converted = FALSE;
	new_ph->inline_mor = mor;
	new_ph->ph_iname = NULL;
	new_ph->to_begin = FALSE;
	new_ph->imported = FALSE;
	new_ph->owning_module = Modules::find(current_sentence);
	new_ph->requests_package = NULL;
	if (inline_wn >= 0) {
		new_ph->at_least_one_compiled_form_needed = FALSE;
	} else {
		new_ph->at_least_one_compiled_form_needed = TRUE;
	}
	new_ph->compile_with_run_time_debugging = FALSE;

	new_ph->next_in_logical_order = NULL;
	new_ph->sequence_count = -1;

	new_ph->ph_documentation_symbol = documentation_W;

@<There seems to be no definition@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_Undefined),
		"there doesn't seem to be any definition here",
		"so I can't see what this rule or phrase would do.");

@ That just leaves two problem messages about inline definitions:

@<Forbid overly long inline definitions@> =
	LOG("Inline definition: <%s>\n", inline_defn);
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_InlineTooLong),
		"the inline definition of this 'to...' phrase is too long",
		"using a quantity of Inform 6 code which exceeds the fairly small limit "
		"allowed. You will need either to write the phrase definition in Inform 7, "
		"or to call an I6 routine which you define elsewhere with an 'Include ...'.");
	inline_defn[MAX_INLINE_DEFN_LENGTH-1] = 0;

@<Inline is for To... phrases only@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_InlineRule),
		"only 'to...' phrases can be given inline Inform 6 definitions",
		"and in particular rules and adjective definitions can't.");

@ Inline definitions open with a raw Inform 6 inclusion. The lexer processes
those as two words: first |(-|, which serves as a marker, and then the raw
text of the inclusion treated as a single "word".

Some inline definitions also mark themselves to be included only in To phrases
of the right sort: it makes no sense to respond "yes" to a phrase "To decide
what number is...", for instance.

=
<inline-phrase-definition> ::=
	(- ### - in to only | 			==> DECIDES_NOTHING_MOR; <<inlinecode>> = Wordings::first_wn(WR[1])
	(- ### - in to decide if only |    ==> DECIDES_CONDITION_MOR; <<inlinecode>> = Wordings::first_wn(WR[1])
	(- ### - in to decide only |    ==> DECIDES_VALUE_MOR; <<inlinecode>> = Wordings::first_wn(WR[1])
	(- ### |    ==> DONT_KNOW_MOR; <<inlinecode>> = Wordings::first_wn(WR[1])
	(- ### ...						==> DONT_KNOW_MOR; <<inlinecode>> = Wordings::first_wn(WR[1]); @<Issue PM_TailAfterInline problem@>

@<Issue PM_TailAfterInline problem@> =
	*X = DONT_KNOW_MOR;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_TailAfterInline),
		"some unexpected text appears after the tail of an inline definition",
		"placed within '(-' and '-)' markers to indicate that it is written in "
		"Inform 6. Here, there seems to be something extra after the '-)'.");

@ And this is used when the preamble is first looked at:

=
void Phrases::parse_possible_inline_defn(wording W, int *wn, int *mor) {
	LOGIF(MATCHING, "form of inline: %W\n", W);
	*wn = -1;
	if (<inline-phrase-definition>(W)) { *wn = <<inlinecode>>; *mor = <<r>>; }
}

@h Miscellaneous.
That completes the process of creation. Here's how we log them:

=
void Phrases::log(phrase *ph) {
	if (ph == NULL) { LOG("RULE:NULL"); return; }
	LOG("%n", Phrases::iname(ph));
	Phrases::Usage::log_rule_name(&(ph->usage_data));
}

void Phrases::log_briefly(phrase *ph) {
	Phrases::TypeData::Textual::log_briefly(&(ph->type_data));
}

@ Relatedly, for indexing purposes:

=
void Phrases::write_HTML_representation(OUTPUT_STREAM, phrase *ph, int format) {
	Phrases::TypeData::Textual::write_HTML_representation(OUT, &(ph->type_data), format, NULL);
}

@ Some access functions:

=
int Phrases::compiled_inline(phrase *ph) {
	if (ph->inline_wn < 0) return FALSE;
	return TRUE;
}

wchar_t *Phrases::get_inline_definition(phrase *ph) {
	if (ph->inline_wn < 0)
		internal_error("tried to access inline definition of non-inline phrase");
	return Lexer::word_text(ph->inline_wn);
}

inter_schema *Phrases::get_inter_head(phrase *ph) {
	if (ph->inter_defn_converted == FALSE) {
		if (ph->inline_wn >= 0) {
			InterSchemas::from_inline_phrase_definition(Phrases::get_inline_definition(ph), &(ph->inter_head_defn), &(ph->inter_tail_defn));
		}
		ph->inter_defn_converted = TRUE;
	}
	return ph->inter_head_defn;
}

inter_schema *Phrases::get_inter_tail(phrase *ph) {
	if (ph->inter_defn_converted == FALSE) {
		if (ph->inline_wn >= 0) {
			InterSchemas::from_inline_phrase_definition(Phrases::get_inline_definition(ph), &(ph->inter_head_defn), &(ph->inter_tail_defn));
		}
		ph->inter_defn_converted = TRUE;
	}
	return ph->inter_tail_defn;
}

inter_name *Phrases::iname(phrase *ph) {
	if (ph->ph_iname == NULL) {
		package_request *PR = Hierarchy::package(ph->owning_module, ADJECTIVE_PHRASES_HAP);
		ph->ph_iname = Hierarchy::make_iname_in(DEFINITION_FN_HL, PR);
	}
	return ph->ph_iname;
}

parse_node *Phrases::declaration_node(phrase *ph) {
	return ph->declaration_node;
}

@h Compilation.
The following is called to give us an opportunity to compile a routine defining
a phrase. As was mentioned in the introduction, "To..." phrases are sometimes
compiled multiple times, for different kinds of tokens, and are compiled in
response to "requests". All other phrases are compiled just once.

=
void Phrases::import(phrase *ph) {
	ph->imported = TRUE;
}

void Phrases::compile(phrase *ph, int *i, int max_i,
	stacked_variable_owner_list *legible, to_phrase_request *req, applicability_condition *acl) {
	if (ph->imported) return;
	int effect = Phrases::Usage::get_effect(&(ph->usage_data));
	if (effect == RULE_NOT_IN_RULEBOOK_EFF) effect = RULE_IN_RULEBOOK_EFF;
	if (effect == TO_PHRASE_EFF) {
		Routines::Compile::routine(ph, legible, req, acl);
		@<Move along the progress bar if it's this phrase's first compilation@>;
	} else {
		if (ph->at_least_one_compiled_form_needed) {
			Routines::Compile::routine(ph, legible, NULL, acl);
			@<Move along the progress bar if it's this phrase's first compilation@>;
		}
	}
}

@<Move along the progress bar if it's this phrase's first compilation@> =
	if (ph->at_least_one_compiled_form_needed) {
		ph->at_least_one_compiled_form_needed = FALSE;
		(*i)++;
		ProgressBar::update(4, ((float) (*i))/((float) max_i));
	}

@h Basic mode main.

=
void Phrases::invoke_to_begin(void) {
	if (Task::begin_execution_at_to_begin()) {
		inter_name *iname = Hierarchy::find(SUBMAIN_HL);
		packaging_state save = Routines::begin(iname);
		int n = 0;
		phrase *ph;
		LOOP_OVER(ph, phrase)
			if (ph->to_begin) {
				n++;
				if (n > 1) {
					Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(...),
						"there seem to be multiple 'to begin' phrases",
						"and in Basic mode, Inform expects to see exactly one of "
						"these, specifying where execution should begin.");
				} else {
					if (Phrases::compiled_inline(ph)) {
						Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(...),
							"the 'to begin' phrase seems to be defined inline",
							"which in Basic mode is not allowed.");
					} else {
						kind *void_kind = Kinds::function_kind(0, NULL, K_nil);
						inter_name *IS = Routines::Compile::iname(ph,
							Routines::ToPhrases::make_request(ph,
								void_kind,
								NULL,
								EMPTY_WORDING));
						Produce::inv_call_iname(Emit::tree(), IS);
					}
				}
			}
		if (n == 0) {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(...),
				"there seems not to be a 'to begin' phrase",
				"and in Basic mode, Inform expects to see exactly one of "
				"these, specifying where execution should begin.");
		}
		Routines::end(save);
		Hierarchy::make_available(Emit::tree(), iname);
	}
}
