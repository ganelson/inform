[Phrases::] Phrases.

To create one |phrase| object for each phrase declaration in the
source text.

@ As noted in the introduction to this chapter, a |phrase| structure is
created for each "To..." definition and each rule in the source text. It is
divided internally into five substructures, the PHTD, PHUD, PHRCD, PHSF
and PHOD.

@ A new abbreviation is MOR, the "manner of return", which is only
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
	struct imperative_defn *from;

	int inline_wn; /* word number of inline I6 definition, or |-1| if not inline */
	struct inter_schema *inter_head_defn; /* inline definition translated to inter, if possible */
	struct inter_schema *inter_tail_defn; /* inline definition translated to inter, if possible */
	int inter_defn_converted; /* has this been tried yet? */
	int inline_mor; /* manner of return for inline I6 definition, or |UNKNOWN_NT| */
	struct wording ph_documentation_symbol; /* cross-reference with documentation */
	struct compilation_unit *owning_module;
	struct package_request *requests_package;

	struct ph_type_data type_data;
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
phrase *Phrases::create_from_preamble(imperative_defn *id) {
	parse_node *p = id->at;
	if ((p == NULL) || (Node::get_type(p) != IMPERATIVE_NT))
		internal_error("a phrase preamble should be at a IMPERATIVE_NT node");
	int inline_wn = -1; 		/* the word number of an inline I6 definition if any */
	int mor = DONT_KNOW_MOR;	/* and its manner of return */
	wording OW = EMPTY_WORDING;	/* the text of the phrase options, if any */
	wording documentation_W = EMPTY_WORDING; /* the documentation reference, if any */

	@<Look for an inline definition@>;

	ph_options_data phod;
	ph_type_data phtd;
	ph_stack_frame phsf;
	ph_runtime_context_data phrcd;

	if ((inline_wn >= 0) && (ImperativeDefinitionFamilies::allows_inline(id) == FALSE))
		@<Inline is for To... phrases only@>;

	@<Construct the PHTD, find the phrase options, find the documentation reference@>;
	@<Construct the PHOD@>;
	@<Construct the PHSF, using the PHTD and PHOD@>;
	@<Construct the PHRCD@>;

	phrase *new_ph;
	@<Create the phrase structure@>;
	return new_ph;
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

@<Construct the PHTD, find the phrase options, find the documentation reference@> =
	wording XW = ToPhraseFamily::get_prototype_text(id);
	documentation_W = Index::DocReferences::position_of_symbol(&XW);
	phtd = Phrases::TypeData::new();
	if (inline_wn >= 0) Phrases::TypeData::make_inline(&phtd);
	ImperativeDefinitionFamilies::to_phtd(id, &phtd, XW, &OW);

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

@<Create the phrase structure@> =
	LOGIF(PHRASE_CREATIONS, "Creating phrase: <%W>\n", id->log_text);

	new_ph = CREATE(phrase);
	new_ph->from = id;

	new_ph->options_data = phod;
	new_ph->runtime_context_data = phrcd;
	new_ph->stack_frame = phsf;
	new_ph->type_data = phtd;

	new_ph->inline_wn = inline_wn;
	new_ph->inter_head_defn = NULL;
	new_ph->inter_tail_defn = NULL;
	new_ph->inter_defn_converted = FALSE;
	new_ph->inline_mor = mor;
	new_ph->ph_iname = NULL;
	new_ph->to_begin = FALSE;
	new_ph->imported = FALSE;
	new_ph->owning_module = CompilationUnits::find(current_sentence);
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

@ That just leaves two problem messages about inline definitions:

@<Forbid overly long inline definitions@> =
	LOG("Inline definition: <%s>\n", inline_defn);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InlineTooLong),
		"the inline definition of this 'to...' phrase is too long",
		"using a quantity of Inform 6 code which exceeds the fairly small limit "
		"allowed. You will need either to write the phrase definition in Inform 7, "
		"or to call an I6 routine which you define elsewhere with an 'Include ...'.");
	inline_defn[MAX_INLINE_DEFN_LENGTH-1] = 0;

@<Inline is for To... phrases only@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_InlineRule),
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
	(- ### - in to only | 			 ==> { DECIDES_NOTHING_MOR, -, <<inlinecode>> = Wordings::first_wn(WR[1]) }
	(- ### - in to decide if only |  ==> { DECIDES_CONDITION_MOR, -, <<inlinecode>> = Wordings::first_wn(WR[1]) }
	(- ### - in to decide only |     ==> { DECIDES_VALUE_MOR, -, <<inlinecode>> = Wordings::first_wn(WR[1]) }
	(- ### |                         ==> { DONT_KNOW_MOR, -, <<inlinecode>> = Wordings::first_wn(WR[1]) }
	(- ### ...                       ==> { DONT_KNOW_MOR, -, <<inlinecode>> = Wordings::first_wn(WR[1]) }; @<Issue PM_TailAfterInline problem@>

@<Issue PM_TailAfterInline problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TailAfterInline),
		"some unexpected text appears after the tail of an inline definition",
		"placed within '(-' and '-)' markers to indicate that it is written in "
		"Inform 6. Here, there seems to be something extra after the '-)'.");
	==> { DONT_KNOW_MOR, - };

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
	return ph->from->at;
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
	stacked_variable_owner_list *legible, to_phrase_request *req, rule *R) {
	if (ph->imported) return;
	if ((req) || (ph->at_least_one_compiled_form_needed)) {
		Routines::Compile::routine(ph, legible, req, R);
		@<Move along the progress bar if it's this phrase's first compilation@>;
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
					StandardProblems::sentence_problem(Task::syntax_tree(), _p_(...),
						"there seem to be multiple 'to begin' phrases",
						"and in Basic mode, Inform expects to see exactly one of "
						"these, specifying where execution should begin.");
				} else {
					if (Phrases::compiled_inline(ph)) {
						StandardProblems::sentence_problem(Task::syntax_tree(), _p_(...),
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
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(...),
				"there seems not to be a 'to begin' phrase",
				"and in Basic mode, Inform expects to see exactly one of "
				"these, specifying where execution should begin.");
		}
		Routines::end(save);
		Hierarchy::make_available(Emit::tree(), iname);
	}
}
