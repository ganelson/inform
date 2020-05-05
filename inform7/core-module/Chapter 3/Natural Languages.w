[NaturalLanguages::] Natural Languages.

To manage definitions of natural languages, such as English or French,
which may be used either to write Inform or to read the works it compiles.

@h Indexing.

=
void NaturalLanguages::produce_index(void) {
	inform_project *project = Task::project();
	I6T::interpret_indext(
		Filenames::in(
			Languages::path_to_bundle(
				Projects::get_language_of_index(project)),
			Projects::index_structure(project)));
}

@

@d NATURAL_LANGUAGES_PRESENT

@h Parsing.
The following matches the English-language name of a language: for example,
"French". It will only make a match if Inform has successfully found a
bundle for that language during its initial scan.

=
<natural-language> internal {
	inform_language *L;
	LOOP_OVER(L, inform_language)
		if (Wordings::match(W, Wordings::first_word(L->instance_name))) {
			*XP = L; return TRUE;
		}
	return FALSE;
}

@h The natural language kind.
Inform has a kind built in called "natural language", whose values are
enumerated names: English language, French language, German language and so on.
When the kind is created, the following routine makes these instances. We do
this exactly as we would to create any other instance -- we write a logical
proposition claiming its existence, then assert this to be true. It's an
interesting question whether the possibility of the game having been written
in German "belongs" in the model world, if in fact the game wasn't written
in German; but this is how we'll do it, anyway.

=
void NaturalLanguages::stock_nl_kind(kind *K) {
	inform_language *L;
	LOOP_OVER(L, inform_language) {
		pcalc_prop *prop =
			Calculus::Propositions::Abstract::to_create_something(K, L->instance_name);
		Calculus::Propositions::Assert::assert_true(prop, CERTAIN_CE);
		L->nl_instance = latest_instance;
	}
}

@h The adaptive person.
The following is only relevant for the language of play, whose extension will
always be read in. That in turn is expected to contain a declaration like
this one:

>> The adaptive text viewpoint of the French language is second person singular.

The following routine picks up on the result of this declaration. (We cache
this because we need access to it very quickly when parsing text substitutions.)

=
int NaturalLanguages::adaptive_person(inform_language *L) {
	#ifdef IF_MODULE
	if ((L->adaptive_person == -1) && (P_adaptive_text_viewpoint)) {
		instance *I = L->nl_instance;
		parse_node *spec = World::Inferences::get_prop_state(
			Instances::as_subject(I), P_adaptive_text_viewpoint);
		if (ParseTree::is(spec, CONSTANT_NT)) {
			instance *V = ParseTree::get_constant_instance(spec);
			L->adaptive_person = Instances::get_numerical_value(V)-1;
		}
	}
	#endif

	if (L->adaptive_person == -1) return FIRST_PERSON_PLURAL;
	return L->adaptive_person;
}

@h Including Preform syntax.
At present we do this only for English, but some day...

=
wording NaturalLanguages::load_preform(inform_language *L) {
	if (L == NULL) internal_error("can't load preform from null language");
	language_being_read_by_Preform = L;
	filename *preform_file = Filenames::in(Languages::path_to_bundle(L), I"Syntax.preform");
	return Preform::load_from_file(preform_file);
}

@ Preform errors are handled here:

=
void NaturalLanguages::preform_error(word_assemblage base_text, nonterminal *nt,
	production *pr, char *message) {
	if (pr) {
		LOG("The production at fault is:\n");
		Preform::log_production(pr, FALSE); LOG("\n");
	}
	if (nt == NULL)
		Problems::quote_text(1, "(no nonterminal)");
	else
		Problems::quote_wide_text(1, Vocabulary::get_exemplar(nt->nonterminal_id, FALSE));
	Problems::quote_text(2, message);
	Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(Untestable));
	if (WordAssemblages::nonempty(base_text)) {
		Problems::quote_wa(5, &base_text);
		Problems::issue_problem_segment(
			"I'm having difficulties conjugating the verb '%5'. ");
	}

	TEMPORARY_TEXT(TEMP);
	if (pr) {
		Problems::quote_number(3, &(pr->match_number));
		ptoken *pt;
		for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
			Preform::write_ptoken(TEMP, pt);
			if (pt->next_ptoken) WRITE_TO(TEMP, " ");
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
	DISCARD_TEXT(TEMP);
}

