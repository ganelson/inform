[RTVerbs::] Verbs at Run Time.

To provide run-time access to verbs and their conjugations.

@

=
typedef struct verb_compilation_data {
	struct package_request *verb_package;
} verb_compilation_data;

typedef struct verb_form_compilation_data {
	struct inter_name *vf_iname; /* routine to conjugate this */
	struct parse_node *where_vf_created;
} verb_form_compilation_data;

@

@d VERB_COMPILATION_LINGUISTICS_CALLBACK RTVerbs::initialise_verb
@d VERB_FORM_COMPILATION_LINGUISTICS_CALLBACK RTVerbs::initialise_verb_form

=
void RTVerbs::initialise_verb(verb *V) {
	V->verb_compilation.verb_package = NULL;
}

void RTVerbs::initialise_verb_form(verb_form *VF) {
	VF->verb_form_compilation.vf_iname = NULL;
	VF->verb_form_compilation.where_vf_created = current_sentence;
}

package_request *RTVerbs::package(verb *V, parse_node *where) {
	if (V == NULL) internal_error("no verb identity");
	if (V->verb_compilation.verb_package == NULL)
		V->verb_compilation.verb_package = Hierarchy::local_package_to(VERBS_HAP, where);
	return V->verb_compilation.verb_package;
}

inter_name *RTVerbs::form_iname(verb_form *vf) {
	if (vf->verb_form_compilation.vf_iname == NULL) {
		package_request *R =
			RTVerbs::package(vf->underlying_verb, vf->verb_form_compilation.where_vf_created);
		package_request *R2 = Hierarchy::package_within(VERB_FORMS_HAP, R);
		vf->verb_form_compilation.vf_iname = Hierarchy::make_iname_in(FORM_FN_HL, R2);
	}
	return vf->verb_form_compilation.vf_iname;
}

@h Runtime conjugation.

=
void RTVerbs::ConjugateVerb_invoke_emit(verb_conjugation *vc,
	verb_conjugation *modal, int negated) {
	inter_name *cv_pos = Hierarchy::find(CV_POS_HL);
	inter_name *cv_neg = Hierarchy::find(CV_NEG_HL);
	if (modal) {
		if (negated) {
			EmitCode::call(Conjugation::conj_iname(modal));
			EmitCode::down();
				EmitCode::val_iname(K_value, cv_neg);
				EmitCode::call(Hierarchy::find(PNTOVP_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
				EmitCode::val_iname(K_value, Conjugation::conj_iname(vc));
			EmitCode::up();
		} else {
			EmitCode::call(Conjugation::conj_iname(modal));
			EmitCode::down();
				EmitCode::val_iname(K_value, cv_pos);
				EmitCode::call(Hierarchy::find(PNTOVP_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
				EmitCode::val_iname(K_value, Conjugation::conj_iname(vc));
			EmitCode::up();
		}
	} else {
		if (negated) {
			EmitCode::call(Conjugation::conj_iname(vc));
			EmitCode::down();
				EmitCode::val_iname(K_value, cv_neg);
				EmitCode::call(Hierarchy::find(PNTOVP_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
			EmitCode::up();
		} else {
			EmitCode::call(Conjugation::conj_iname(vc));
			EmitCode::down();
				EmitCode::val_iname(K_value, cv_pos);
				EmitCode::call(Hierarchy::find(PNTOVP_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
			EmitCode::up();
		}
	}
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_number, Hierarchy::find(SAY__P_HL));
		EmitCode::val_number(1);
	EmitCode::up();
}

@ Each VC is represented by a routine at run-time:

=
int RTVerbs::verb_form_is_instance(verb_form *vf) {
	verb_conjugation *vc = vf->underlying_verb->conjugation;
	if ((vc) && (vc->auxiliary_only == FALSE) && (vc->instance_of_verb) &&
		((vf->preposition == NULL) || (vf->underlying_verb != copular_verb)))
		return TRUE;
	return FALSE;
}

void RTVerbs::ConjugateVerbDefinitions(void) {
	inter_name *CV_POS_iname = Hierarchy::find(CV_POS_HL);
	inter_name *CV_NEG_iname = Hierarchy::find(CV_NEG_HL);
	inter_name *CV_MODAL_INAME_iname = Hierarchy::find(CV_MODAL_HL);
	inter_name *CV_MEANING_iname = Hierarchy::find(CV_MEANING_HL);

	Emit::named_numeric_constant_signed(CV_POS_iname, -1);
	Emit::named_numeric_constant_signed(CV_NEG_iname, -2);
	Emit::named_numeric_constant_signed(CV_MODAL_INAME_iname, -3);
	Emit::named_numeric_constant_signed(CV_MEANING_iname, -4);
	
	Hierarchy::make_available(CV_POS_iname);
	Hierarchy::make_available(CV_NEG_iname);
	Hierarchy::make_available(CV_MODAL_INAME_iname);
	Hierarchy::make_available(CV_MEANING_iname);
}

void RTVerbs::ConjugateVerb(void) {
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation)
		@<Compile ConjugateVerb routine@>;
	verb_form *vf;
	LOOP_OVER(vf, verb_form)
		if (RTVerbs::verb_form_is_instance(vf))
			@<Compile ConjugateVerbForm routine@>;
	inter_name *iname = Hierarchy::find(TABLEOFVERBS_HL);
	packaging_state save = EmitArrays::begin(iname, K_value);
	LOOP_OVER(vf, verb_form)
		if (RTVerbs::verb_form_is_instance(vf))
			EmitArrays::iname_entry(RTVerbs::form_iname(vf));
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
}

@<Compile ConjugateVerb routine@> =
	packaging_state save = Functions::begin(Conjugation::conj_iname(vc));
	inter_symbol *fn_s = LocalVariables::new_other_as_symbol(I"fn");
	inter_symbol *vp_s = LocalVariables::new_other_as_symbol(I"vp");
	inter_symbol *t_s = LocalVariables::new_other_as_symbol(I"t");
	inter_symbol *modal_to_s = LocalVariables::new_other_as_symbol(I"modal_to");

	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, fn_s);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(1);
				EmitCode::code();
				EmitCode::down();
					RTVerbs::conj_from_wa(&(vc->infinitive), vc, modal_to_s, 0);
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(2);
				EmitCode::code();
				EmitCode::down();
					RTVerbs::conj_from_wa(&(vc->past_participle), vc, modal_to_s, 0);
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number(3);
				EmitCode::code();
				EmitCode::down();
					RTVerbs::conj_from_wa(&(vc->present_participle), vc, modal_to_s, 0);
				EmitCode::up();
			EmitCode::up();

	int modal_verb = FALSE;
	@<Check for modality@>;

	verb *vi = vc->vc_conjugates;
	verb_meaning *vm = (vi)?VerbMeanings::first_unspecial_meaning_of_verb_form(Verbs::base_form(vi)):NULL;
	binary_predicate *meaning = VerbMeanings::get_regular_meaning(vm);
	inter_name *rel_iname = RTRelations::default_iname();
	if (meaning) {
		RTRelations::mark_as_needed(meaning);
		rel_iname = RTRelations::iname(meaning);
	}

			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(CV_MODAL_HL));
				EmitCode::code();
				EmitCode::down();
					if (modal_verb) EmitCode::rtrue();
					else EmitCode::rfalse();
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(CV_MEANING_HL));
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, rel_iname);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();

	for (int sense = 0; sense < 2; sense++) {
		inter_name *sense_iname = Hierarchy::find(CV_POS_HL);
		if (sense == 1) sense_iname = Hierarchy::find(CV_NEG_HL);
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, sense_iname);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(SWITCH_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, t_s);
						EmitCode::code();
						EmitCode::down();
							@<Compile conjugation in this sense@>;
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
	}
		EmitCode::up();
	EmitCode::up();

	Functions::end(save);

@<Compile ConjugateVerbForm routine@> =
	verb_conjugation *vc = vf->underlying_verb->conjugation;
	packaging_state save = Functions::begin(RTVerbs::form_iname(vf));
	inter_symbol *fn_s = LocalVariables::new_other_as_symbol(I"fn");
	inter_symbol *vp_s = LocalVariables::new_other_as_symbol(I"vp");
	inter_symbol *t_s = LocalVariables::new_other_as_symbol(I"t");
	inter_symbol *modal_to_s = LocalVariables::new_other_as_symbol(I"modal_to");

	TEMPORARY_TEXT(C)
	WRITE_TO(C, "%A", &(vf->infinitive_reference_text));
	EmitCode::comment(C);
	DISCARD_TEXT(C)

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, t_s);
		EmitCode::call(Conjugation::conj_iname(vc));
		EmitCode::down();
			EmitCode::val_symbol(K_value, fn_s);
			EmitCode::val_symbol(K_value, vp_s);
			EmitCode::val_symbol(K_value, t_s);
			EmitCode::val_symbol(K_value, modal_to_s);
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, fn_s);
			EmitCode::val_iname(K_value, Hierarchy::find(CV_MODAL_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, t_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	verb_meaning *vm = &(vf->list_of_senses->vm);
	inter_name *rel_iname = RTRelations::default_iname();
	binary_predicate *meaning = VerbMeanings::get_regular_meaning(vm);
	if (meaning) {
		RTRelations::mark_as_needed(meaning);
		rel_iname = RTRelations::iname(meaning);
	}

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, fn_s);
			EmitCode::val_iname(K_value, Hierarchy::find(CV_MEANING_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, rel_iname);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	if (vf->preposition) {
		TEMPORARY_TEXT(T)
		WRITE_TO(T, " %A", &(vf->preposition->prep_text));
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(T);
		EmitCode::up();
		DISCARD_TEXT(T)
	}

	Functions::end(save);

@<Check for modality@> =
	for (int sense=0; sense<NO_KNOWN_SENSES; sense++)
		for (int tense=0; tense<NO_KNOWN_TENSES; tense++)
			for (int person=0; person<NO_KNOWN_PERSONS; person++)
				for (int number=0; number<NO_KNOWN_NUMBERS; number++)
					if (vc->tabulations[ACTIVE_VOICE].modal_auxiliary_usage[tense][sense][person][number] != 0)
						modal_verb = TRUE;

@<Compile conjugation in this sense@> =
	for (int tense=0; tense<NO_KNOWN_TENSES; tense++) {
		int some_exist = FALSE, some_dont_exist = FALSE,
			some_differ = FALSE, some_except_3PS_differ = FALSE, some_are_modal = FALSE;
		word_assemblage *common = NULL, *common_except_3PS = NULL;
		for (int person=0; person<NO_KNOWN_PERSONS; person++)
			for (int number=0; number<NO_KNOWN_NUMBERS; number++) {
				word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][person][number]);
				if (WordAssemblages::nonempty(*wa)) {
					if (some_exist) {
						if (WordAssemblages::eq(wa, common) == FALSE)
							some_differ = TRUE;
						if ((person != THIRD_PERSON) || (number != SINGULAR_NUMBER)) {
							if (common_except_3PS == NULL) common_except_3PS = wa;
							else if (WordAssemblages::eq(wa, common_except_3PS) == FALSE)
								some_except_3PS_differ = TRUE;
						}
					} else {
						some_exist = TRUE;
						common = wa;
						if ((person != THIRD_PERSON) || (number != SINGULAR_NUMBER))
							common_except_3PS = wa;
					}
					if (vc->tabulations[ACTIVE_VOICE].modal_auxiliary_usage[tense][sense][person][number] != 0)
						some_are_modal = TRUE;
				}
				else some_dont_exist = TRUE;
			}
		if (some_exist) {
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_number((inter_ti) (tense+1));
				EmitCode::code();
				EmitCode::down();
					if ((some_differ) || (some_are_modal)) {
						if ((some_except_3PS_differ) || (some_dont_exist) || (some_are_modal))
							@<Compile a full switch of all six parts@>
						else
							@<Compile a choice between 3PS and the rest@>;
					} else {
						@<Compile for the case where all six parts are the same@>;
					}
				EmitCode::up();
			EmitCode::up();
		}
	}

@<Compile a full switch of all six parts@> =
	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, vp_s);
		EmitCode::code();
		EmitCode::down();
			for (int person=0; person<NO_KNOWN_PERSONS; person++)
				for (int number=0; number<NO_KNOWN_NUMBERS; number++) {
					word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][person][number]);
					if (WordAssemblages::nonempty(*wa)) {
						EmitCode::inv(CASE_BIP);
						EmitCode::down();
							inter_ti part = ((inter_ti) person) + 3*((inter_ti) number) + 1;
							EmitCode::val_number((inter_ti) part);
							EmitCode::code();
							EmitCode::down();
								int mau = vc->tabulations[ACTIVE_VOICE].modal_auxiliary_usage[tense][sense][person][number];
								RTVerbs::conj_from_wa(wa, vc, modal_to_s, mau);
							EmitCode::up();
						EmitCode::up();
					}
				}
		EmitCode::up();
	EmitCode::up();

@<Compile a choice between 3PS and the rest@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, vp_s);
			EmitCode::val_number(3);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][THIRD_PERSON][SINGULAR_NUMBER]);
			RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
			RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		EmitCode::up();
	EmitCode::up();

@<Compile for the case where all six parts are the same@> =
	word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
	RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);

@ =
void RTVerbs::conj_from_wa(word_assemblage *wa, verb_conjugation *vc, inter_symbol *modal_to_s, int mau) {
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		TEMPORARY_TEXT(OUT)
		if ((RTVerbs::takes_contraction_form(wa) == FALSE) && (RTVerbs::takes_contraction_form(&(vc->infinitive))))
			WRITE(" ");
		int i, n;
		vocabulary_entry **words;
		WordAssemblages::as_array(wa, &words, &n);
		for (i=0; i<n; i++) {
			if (i>0) WRITE(" ");
			wchar_t *q = Vocabulary::get_exemplar(words[i], FALSE);
			if ((q[0]) && (q[Wide::len(q)-1] == '*')) {
				TEMPORARY_TEXT(unstarred)
				WRITE_TO(unstarred, "%V", words[i]);
				Str::delete_last_character(unstarred);
				feed_t id = Feeds::begin();
				Feeds::feed_C_string(L" ");
				Feeds::feed_text(unstarred);
				Feeds::feed_C_string(L" ");
				DISCARD_TEXT(unstarred)
				wording W = Feeds::end(id);
				adjective *aph = Adjectives::declare(W, vc->defined_in);
				WRITE("\"; %n(prior_named_noun, (prior_named_list >= 2)); print \"",
					aph->adjective_compilation.aph_iname);
			} else {
				WRITE("%V", words[i]);
			}
		}
		EmitCode::val_text(OUT);
		DISCARD_TEXT(OUT)
	EmitCode::up();
	if (mau != 0) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, modal_to_s);
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(I" ");
				EmitCode::up();
				EmitCode::inv(INDIRECT1V_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, modal_to_s);
					EmitCode::val_number((inter_ti) mau);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}
}

int RTVerbs::takes_contraction_form(word_assemblage *wa) {
	vocabulary_entry *ve = WordAssemblages::first_word(wa);
	if (ve == NULL) return FALSE;
	wchar_t *p = Vocabulary::get_exemplar(ve, FALSE);
	if (p[0] == '\'') return TRUE;
	return FALSE;
}

@h Debug log.
The following dumps the entire stock of registered verb and preposition
usages to the debugging log.

=
void RTVerbs::log(verb_usage *vu) {
	VerbUsages::write_usage(DL, vu);
}

void RTVerbs::log_all(void) {
	verb_usage *vu;
	preposition *prep;
	LOG("The current S-grammar has the following verb and preposition usages:\n");
	LOOP_OVER(vu, verb_usage) {
		RTVerbs::log(vu);
		LOG("\n");
	}
	LOOP_OVER(prep, preposition) {
		LOG("$p\n", prep);
	}
}

@h Index tabulation.
The following produces the table of verbs in the Phrasebook Index page.

=
void RTVerbs::tabulate(OUTPUT_STREAM, index_lexicon_entry *lex, int tense, char *tensename) {
	verb_usage *vu; int f = TRUE;
	LOOP_OVER(vu, verb_usage)
		if ((vu->vu_lex_entry == lex) && (VerbUsages::is_used_negatively(vu) == FALSE)
			 && (VerbUsages::get_tense_used(vu) == tense)) {
			vocabulary_entry *lastword = WordAssemblages::last_word(&(vu->vu_text));
			if (f) {
				HTML::open_indented_p(OUT, 2, "tight");
				WRITE("<i>%s:</i>&nbsp;", tensename);
			} else WRITE("; ");
			if (Wide::cmp(Vocabulary::get_exemplar(lastword, FALSE), L"by") == 0) WRITE("B ");
			else WRITE("A ");
			WordAssemblages::index(OUT, &(vu->vu_text));
			if (Wide::cmp(Vocabulary::get_exemplar(lastword, FALSE), L"by") == 0) WRITE("A");
			else WRITE("B");
			f = FALSE;
		}
	if (f == FALSE) HTML_CLOSE("p");
}

void RTVerbs::tabulate_meaning(OUTPUT_STREAM, index_lexicon_entry *lex) {
	verb_usage *vu;
	LOOP_OVER(vu, verb_usage)
		if (vu->vu_lex_entry == lex) {
			if (vu->where_vu_created)
				Index::link(OUT, Wordings::first_wn(Node::get_text(vu->where_vu_created)));
			binary_predicate *bp = VerbMeanings::get_regular_meaning_of_form(Verbs::base_form(VerbUsages::get_verb(vu)));
			if (bp) RTRelations::index_for_verbs(OUT, bp);
			return;
		}
	preposition *prep;
	LOOP_OVER(prep, preposition)
		if (prep->prep_lex_entry == lex) {
			if (prep->where_prep_created)
				Index::link(OUT, Wordings::first_wn(Node::get_text(prep->where_prep_created)));
			binary_predicate *bp = VerbMeanings::get_regular_meaning_of_form(Verbs::find_form(copular_verb, prep, NULL));
			if (bp) RTRelations::index_for_verbs(OUT, bp);
			return;
		}
}
