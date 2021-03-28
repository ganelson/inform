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
typedef struct ph_compilation_data {
	int inline_mor; /* one of the |*_MOR| values above */
	int inline_wn; /* word number of inline I6 definition, or |-1| if not inline */
	int compile_with_run_time_debugging; /* in the RULES command */
	int at_least_one_compiled_form_needed; /* do we still need to compile this? */
	struct compilation_unit *owning_module;
	struct inter_schema *inter_front; /* inline definition translated to inter, if possible */
	struct inter_schema *inter_back; /* inline definition translated to inter, if possible */
	int inter_defn_converted; /* has this been tried yet? */
	struct inter_name *ph_iname; /* or NULL for inline phrases */
	struct package_request *requests_package;
	struct ph_stack_frame stack_frame;
} ph_compilation_data;

@

=
ph_compilation_data Phrases::new_compilation_data(parse_node *p) {
	ph_compilation_data phcd;
	phcd.inline_wn = -1;
	phcd.inter_front = NULL;
	phcd.inter_back = NULL;
	phcd.inter_defn_converted = FALSE;
	phcd.inline_mor = DONT_KNOW_MOR;
	phcd.ph_iname = NULL;
	phcd.owning_module = CompilationUnits::find(p);
	phcd.requests_package = NULL;
	phcd.at_least_one_compiled_form_needed = TRUE;
	phcd.compile_with_run_time_debugging = FALSE;
	phcd.stack_frame = Frames::new();
	return phcd;
}

void Phrases::make_inline(phrase *ph, int inline_wn, int mor) {
	ph->compilation_data.inline_wn = inline_wn;
	ph->compilation_data.inline_mor = mor;
	ph->compilation_data.at_least_one_compiled_form_needed = FALSE;
}

@

=
void Phrases::prepare_stack_frame(phrase *body) {
	Phrases::TypeData::into_stack_frame(&(body->compilation_data.stack_frame), &(body->type_data),
		Phrases::TypeData::kind(&(body->type_data)), TRUE);
	if (Phrases::Options::allows_options(&(body->options_data)))
		LocalVariables::options_parameter_is_needed(&(body->compilation_data.stack_frame));
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
	if (ph->compilation_data.inline_wn < 0) return FALSE;
	return TRUE;
}

wchar_t *Phrases::get_inline_definition(phrase *ph) {
	if (ph->compilation_data.inline_wn < 0)
		internal_error("tried to access inline definition of non-inline phrase");
	return Lexer::word_text(ph->compilation_data.inline_wn);
}

inter_schema *Phrases::get_inter_head(phrase *ph) {
	if (ph->compilation_data.inter_defn_converted == FALSE) {
		if (ph->compilation_data.inline_wn >= 0) {
			InterSchemas::from_inline_phrase_definition(Phrases::get_inline_definition(ph), &(ph->compilation_data.inter_front), &(ph->compilation_data.inter_back));
		}
		ph->compilation_data.inter_defn_converted = TRUE;
	}
	return ph->compilation_data.inter_front;
}

inter_schema *Phrases::get_inter_tail(phrase *ph) {
	if (ph->compilation_data.inter_defn_converted == FALSE) {
		if (ph->compilation_data.inline_wn >= 0) {
			InterSchemas::from_inline_phrase_definition(Phrases::get_inline_definition(ph), &(ph->compilation_data.inter_front), &(ph->compilation_data.inter_back));
		}
		ph->compilation_data.inter_defn_converted = TRUE;
	}
	return ph->compilation_data.inter_back;
}

inter_name *Phrases::iname(phrase *ph) {
	if (ph->compilation_data.ph_iname == NULL) {
		package_request *PR = Hierarchy::package(ph->compilation_data.owning_module, ADJECTIVE_PHRASES_HAP);
		ph->compilation_data.ph_iname = Hierarchy::make_iname_in(DEFINITION_FN_HL, PR);
	}
	return ph->compilation_data.ph_iname;
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
void Phrases::compile(phrase *ph, int *i, int max_i,
	stacked_variable_owner_list *legible, to_phrase_request *req, rule *R) {
	if ((req) || (ph->compilation_data.at_least_one_compiled_form_needed)) {
		Routines::Compile::routine(ph, legible, req, R);
		if (ph->compilation_data.at_least_one_compiled_form_needed) {
			ph->compilation_data.at_least_one_compiled_form_needed = FALSE;
			(*i)++;
			ProgressBar::update(4, ((float) (*i))/((float) max_i));
		}
	}
}
