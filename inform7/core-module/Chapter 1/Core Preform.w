[CorePreform::] Core Preform.

To load, optimise and throw problem messages related to Preform syntax.

@h Reading Preform declarations from Syntax files.
At present we do this only when |L| is English, but the infrastructure is general.

=
int CorePreform::load(inform_language *L) {
	if (L == NULL) internal_error("can't load preform from null language");
	filename *F = Filenames::in(Languages::path_to_bundle(L), I"Syntax.preform");
	int nonterminals_declared = LoadPreform::load(F, L);
	LOG("%d Preform nonterminals read from %f\n", nonterminals_declared, F);
	return nonterminals_declared;
}

@h Converting Preform errors to problems.
Errors in Preform syntax are generated in the //words// module, and are
ordinarily issued in a low-level way, with terse lines printed to |STDERR|.
Providing the following allows us to give the Inform user a fuller message:

@d PREFORM_ERROR_WORDS_CALLBACK CorePreform::preform_error

=
void CorePreform::preform_error(word_assemblage base_text, nonterminal *nt,
	production *pr, char *message) {
	if (pr) {
		LOG("The production at fault is:\n");
		Instrumentation::log_production(pr, FALSE); LOG("\n");
	}
	Problems::quote_nonterminal(1, nt);
	Problems::quote_text(2, message);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
	if (WordAssemblages::nonempty(base_text)) {
		Problems::quote_wa(5, &base_text);
		Problems::issue_problem_segment(
			"I'm having difficulties conjugating the verb '%5'. ");
	}

	TEMPORARY_TEXT(TEMP)
	if (pr) {
		Problems::quote_number(3, &(pr->match_number));
		ptoken *pt;
		for (pt = pr->first_pt; pt; pt = pt->next_pt) {
			Instrumentation::write_ptoken(TEMP, pt);
			if (pt->next_pt) WRITE_TO(TEMP, " ");
		}
		Problems::quote_stream(4, TEMP);
		Problems::issue_problem_segment(
			"There's a problem in Inform's linguistic grammar, which is probably "
			"set by a translation extension. The problem occurs in line %3 of "
			"%1 ('%4'): %2.");
	} else {
		Problems::issue_problem_segment(
			"There's a problem in Inform's linguistic grammar, which is probably "
			"set by a translation extension. The problem occurs in the definition of "
			"%1: %2.");
	}
	Problems::issue_problem_end();
	DISCARD_TEXT(TEMP)
}

@ And similarly for inflections.

@d PREFORM_ERROR_INFLECTIONS_CALLBACK CorePreform::inflections_problem

=
void CorePreform::inflections_problem(nonterminal *nt, inform_language *nl,
	text_stream *err) {
	if (nl) Problems::quote_wording(1, nl->instance_name);
	Problems::quote_stream(2, err);
	Problems::quote_nonterminal(3, nt);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
	Problems::issue_problem_segment(
		"An error occurred with the Preform syntax used to specify the grammar "
		"of source text. If this occurs with English, that's a bug in the compiler, "
		"and should be reported. But if it occurs with languages other than English, "
		"there's an issue with the language definition, which should be reported "
		"to its maintainer. At any rate, this compilation can't go further. ");
	if (nt) {
		Problems::issue_problem_segment(
			"%PThe nonterminal causing problems is %3. ");
	}
	if (nl) {
		Problems::issue_problem_segment(
			"%PThe natural language affected is '%1'. ");
	}
	Problems::issue_problem_segment(
		"%PThe problem as reported by Preform is: %2.");
	Problems::issue_problem_end();
}

@h Optimisation.
The following is fine-tuning for speed: if it weren't here, the compiler would
still function, but would be slower. With that said, it's possible to break
things by making the wrong settings here, so be wary of making changes.

Setting up happens in two stages. Firstly, when this module (and therefore
the compiler) starts up, certain internally-defined Preform nonterminals --
those defined by functions in the code, not loaded from Syntax files -- need
to be marked with NT incidence bits. (See //words: Nonterminal Incidences//.)

=
void CorePreform::set_core_internal_NTIs(void) {
	NTI::give_nt_reserved_incidence_bit(<s-adjective>, ADJECTIVE_RES_NT_BIT);
	NTI::give_nt_reserved_incidence_bit(<s-object-instance>, PROPER_NOUN_RES_NT_BIT);
}

@ Later on, the //words// module calls the following function to mark that a
match to the given nonterminal must contain only words with certain NTI bits:
for example, a match to <k-kind> has to contain words with either the <article>
bit or the <k-kind> bit set, which as we see above is |COMMON_NOUN_RES_NT_BIT|.

@d MORE_PREFORM_OPTIMISER_WORDS_CALLBACK CorePreform::set_core_internal_requirements

=
void CorePreform::set_core_internal_requirements(void) {
	NTI::every_word_in_match_must_have_my_NTI_bit(<s-adjective>);
	CorePreform::mark_nt_as_requiring_itself_articled(<s-object-instance>);
	CorePreform::mark_nt_as_requiring_itself_articled(<k-kind-variable>);
	CorePreform::mark_nt_as_requiring_itself_articled(<k-formal-variable>);
	CorePreform::mark_nt_as_requiring_itself_articled(<k-base-kind>);
	CorePreform::mark_nt_as_requiring_itself_articled(<k-kind-construction>);
	CorePreform::mark_nt_as_requiring_itself_articled(<k-kind>);
	CorePreform::mark_nt_as_requiring_itself_articled(<k-kind-of-kind>);
}

void CorePreform::mark_nt_as_requiring_itself_articled(nonterminal *nt) {
	NTI::every_word_in_match_must_have_my_NTI_bit_or_this_one(nt,
		NTI::nt_incidence_bit(<article>));
}
