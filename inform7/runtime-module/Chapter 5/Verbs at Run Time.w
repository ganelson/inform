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
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(modal));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_neg);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
				Produce::val_iname(Emit::tree(), K_value, Conjugation::conj_iname(vc));
			Produce::up(Emit::tree());
		} else {
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(modal));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_pos);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
				Produce::val_iname(Emit::tree(), K_value, Conjugation::conj_iname(vc));
			Produce::up(Emit::tree());
		}
	} else {
		if (negated) {
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(vc));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_neg);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
			Produce::up(Emit::tree());
		} else {
			Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(vc));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, cv_pos);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(PNTOVP_HL));
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(STORY_TENSE_HL));
			Produce::up(Emit::tree());
		}
	}
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(SAY__P_HL));
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
	Produce::up(Emit::tree());
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
	
	Hierarchy::make_available(Emit::tree(), CV_POS_iname);
	Hierarchy::make_available(Emit::tree(), CV_NEG_iname);
	Hierarchy::make_available(Emit::tree(), CV_MODAL_INAME_iname);
	Hierarchy::make_available(Emit::tree(), CV_MEANING_iname);
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
	packaging_state save = Emit::named_array_begin(iname, K_value);
	LOOP_OVER(vf, verb_form)
		if (RTVerbs::verb_form_is_instance(vf))
			Emit::array_iname_entry(RTVerbs::form_iname(vf));
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}

@<Compile ConjugateVerb routine@> =
	packaging_state save = Functions::begin(Conjugation::conj_iname(vc));
	inter_symbol *fn_s = LocalVariables::new_other_as_symbol(I"fn");
	inter_symbol *vp_s = LocalVariables::new_other_as_symbol(I"vp");
	inter_symbol *t_s = LocalVariables::new_other_as_symbol(I"t");
	inter_symbol *modal_to_s = LocalVariables::new_other_as_symbol(I"modal_to");

	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, fn_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					RTVerbs::conj_from_wa(&(vc->infinitive), vc, modal_to_s, 0);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					RTVerbs::conj_from_wa(&(vc->past_participle), vc, modal_to_s, 0);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					RTVerbs::conj_from_wa(&(vc->present_participle), vc, modal_to_s, 0);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

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

			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MODAL_HL));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					if (modal_verb) Produce::rtrue(Emit::tree());
					else Produce::rfalse(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MEANING_HL));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, rel_iname);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

	for (int sense = 0; sense < 2; sense++) {
		inter_name *sense_iname = Hierarchy::find(CV_POS_HL);
		if (sense == 1) sense_iname = Hierarchy::find(CV_NEG_HL);
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, sense_iname);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, t_s);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<Compile conjugation in this sense@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
	}
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

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
	Emit::code_comment(C);
	DISCARD_TEXT(C)

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, t_s);
		Produce::inv_call_iname(Emit::tree(), Conjugation::conj_iname(vc));
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, fn_s);
			Produce::val_symbol(Emit::tree(), K_value, vp_s);
			Produce::val_symbol(Emit::tree(), K_value, t_s);
			Produce::val_symbol(Emit::tree(), K_value, modal_to_s);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, fn_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MODAL_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, t_s);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	verb_meaning *vm = &(vf->list_of_senses->vm);
	inter_name *rel_iname = RTRelations::default_iname();
	binary_predicate *meaning = VerbMeanings::get_regular_meaning(vm);
	if (meaning) {
		RTRelations::mark_as_needed(meaning);
		rel_iname = RTRelations::iname(meaning);
	}

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, fn_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CV_MEANING_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, rel_iname);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	if (vf->preposition) {
		TEMPORARY_TEXT(T)
		WRITE_TO(T, " %A", &(vf->preposition->prep_text));
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), T);
		Produce::up(Emit::tree());
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
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (tense+1));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					if ((some_differ) || (some_are_modal)) {
						if ((some_except_3PS_differ) || (some_dont_exist) || (some_are_modal))
							@<Compile a full switch of all six parts@>
						else
							@<Compile a choice between 3PS and the rest@>;
					} else {
						@<Compile for the case where all six parts are the same@>;
					}
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

@<Compile a full switch of all six parts@> =
	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, vp_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			for (int person=0; person<NO_KNOWN_PERSONS; person++)
				for (int number=0; number<NO_KNOWN_NUMBERS; number++) {
					word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][person][number]);
					if (WordAssemblages::nonempty(*wa)) {
						Produce::inv_primitive(Emit::tree(), CASE_BIP);
						Produce::down(Emit::tree());
							inter_ti part = ((inter_ti) person) + 3*((inter_ti) number) + 1;
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) part);
							Produce::code(Emit::tree());
							Produce::down(Emit::tree());
								int mau = vc->tabulations[ACTIVE_VOICE].modal_auxiliary_usage[tense][sense][person][number];
								RTVerbs::conj_from_wa(wa, vc, modal_to_s, mau);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					}
				}
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Compile a choice between 3PS and the rest@> =
	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, vp_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][THIRD_PERSON][SINGULAR_NUMBER]);
			RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
			RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Compile for the case where all six parts are the same@> =
	word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
	RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);

@ =
void RTVerbs::conj_from_wa(word_assemblage *wa, verb_conjugation *vc, inter_symbol *modal_to_s, int mau) {
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Produce::down(Emit::tree());
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
		Produce::val_text(Emit::tree(), OUT);
		DISCARD_TEXT(OUT)
	Produce::up(Emit::tree());
	if (mau != 0) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, modal_to_s);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PRINT_BIP);
				Produce::down(Emit::tree());
					Produce::val_text(Emit::tree(), I" ");
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), INDIRECT1V_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, modal_to_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) mau);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
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
