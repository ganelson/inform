[RTVerbs::] Conjugations.

To compile the conjugations submodule for a compilation unit, which contains
_verb, _modal_verb and _verb_form packages.

@h The generic/conjugations package.
A few constants before we get under way:

=
void RTVerbs::compile_generic_constants(void) {
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

@h Compilation data for verbs.
Each |verb| object contains this data:

@d VERB_COMPILATION_LINGUISTICS_CALLBACK RTVerbs::initialise_verb

=
typedef struct verb_compilation_data {
	struct package_request *verb_package;
} verb_compilation_data;

void RTVerbs::initialise_verb(verb *V) {
	V->compilation_data.verb_package = NULL;
}

@ The package is created on demand. It will contain a conjugation function,
and some subpackages for forms:

=
package_request *RTVerbs::package(verb *V, parse_node *where) {
	if (V == NULL) internal_error("no verb identity");
	if (V->compilation_data.verb_package == NULL)
		V->compilation_data.verb_package = Hierarchy::local_package_to(VERBS_HAP, where);
	return V->compilation_data.verb_package;
}

@ But modal verbs, which have no underlying |verb| structure, are also given
conjugation functions. Those have to live somewhere, so they go into free-standing
|_modal_verb| packages:

=
package_request *RTVerbs::modal_package(parse_node *where) {
	return Hierarchy::local_package_to(MVERBS_HAP, where);
}

@h Compilation data for conjugations.
Each |verb_conjugation| object contains this data:

@d VC_COMPILATION_INFLECTIONS_CALLBACK RTVerbs::initialise_vc

=
typedef struct verb_conjugation_compilation_data {
	struct inter_name *vc_iname;
	struct parse_node *where_vc_created;
} verb_conjugation_compilation_data;

void RTVerbs::initialise_vc(verb_conjugation *vc) {
	vc->compilation_data.vc_iname = NULL;
	vc->compilation_data.where_vc_created = current_sentence;
}

@ This produces an iname for the conjugation function, whether it's for a
modal or nonmodal verb:

=
inter_name *RTVerbs::conjugation_fn_iname(verb_conjugation *vc) {
	if (vc->compilation_data.vc_iname == NULL) {
		if (vc->vc_conjugates == NULL) {
			package_request *R = RTVerbs::modal_package(vc->compilation_data.where_vc_created);
			TEMPORARY_TEXT(ANT)
			WRITE_TO(ANT, "%A (modal)",
				&(vc->tabulations[ACTIVE_VOICE].vc_text[IS_TENSE][POSITIVE_SENSE][THIRD_PERSON]));
			Hierarchy::apply_metadata(R, MVERB_NAME_MD_HL, ANT);
			DISCARD_TEXT(ANT)
			TEMPORARY_TEXT(INFT)
			WRITE_TO(INFT, "%A", &(vc->infinitive));
			Hierarchy::apply_metadata(R, MVERB_INFINITIVE_MD_HL, INFT);
			DISCARD_TEXT(INFT)
			Hierarchy::apply_metadata_from_number(R, MVERB_AT_MD_HL,
				(inter_ti) Wordings::first_wn(Node::get_text(vc->compilation_data.where_vc_created)));
			vc->compilation_data.vc_iname = Hierarchy::make_iname_in(MODAL_CONJUGATION_FN_HL, R);
		} else {
			package_request *R =
				RTVerbs::package(vc->vc_conjugates, vc->compilation_data.where_vc_created);
			TEMPORARY_TEXT(ANT)
			WRITE_TO(ANT, "to %A", &(vc->infinitive));
			Hierarchy::apply_metadata(R, VERB_NAME_MD_HL, ANT);
			DISCARD_TEXT(ANT)
			TEMPORARY_TEXT(INFT)
			WRITE_TO(INFT, "%A", &(vc->infinitive));
			Hierarchy::apply_metadata(R, VERB_INFINITIVE_MD_HL, INFT);
			if ((vc->vc_conjugates == NULL) && (vc->auxiliary_only == FALSE) && (vc->instance_of_verb))
				Hierarchy::apply_metadata_from_number(R, VERB_MEANINGLESS_MD_HL, 1);
			else
				Hierarchy::apply_metadata_from_number(R, VERB_MEANINGLESS_MD_HL, 0);
			DISCARD_TEXT(INFT)
			TEMPORARY_TEXT(MEANING)
			RTVerbs::show_meaning(MEANING, vc);
			if (Str::len(MEANING) > 0) Hierarchy::apply_metadata(R, VERB_MEANING_MD_HL, MEANING);
			DISCARD_TEXT(MEANING)
			RTVerbs::tabulate_usages(R, vc, IS_TENSE, VERB_PRESENT_MD_HL);
			RTVerbs::tabulate_usages(R, vc, WAS_TENSE, VERB_PAST_MD_HL);
			RTVerbs::tabulate_usages(R, vc, HASBEEN_TENSE, VERB_PRESENT_PERFECT_MD_HL);
			RTVerbs::tabulate_usages(R, vc, HADBEEN_TENSE, VERB_PAST_PERFECT_MD_HL);
			Hierarchy::apply_metadata_from_number(R, VERB_AT_MD_HL,
				(inter_ti) Wordings::first_wn(Node::get_text(vc->compilation_data.where_vc_created)));
			vc->compilation_data.vc_iname = Hierarchy::make_iname_in(NONMODAL_CONJUGATION_FN_HL, R);
		}
	}
	return vc->compilation_data.vc_iname;
}

void RTVerbs::show_meaning(OUTPUT_STREAM, verb_conjugation *vc) {
	verb_usage *vu;
	LOOP_OVER(vu, verb_usage)
		if (vu->vu_lex_entry == vc) {
			if (vu->where_vu_created)
				IndexUtilities::link(OUT, Wordings::first_wn(Node::get_text(vu->where_vu_created)));
			verb_form *vf = Verbs::base_form(VerbUsages::get_verb(vu));
			RTVerbs::show_relation(OUT, vf);
			return;
		}
	preposition *prep;
	LOOP_OVER(prep, preposition)
		if (prep->prep_lex_entry == vc) {
			if (prep->where_prep_created)
				IndexUtilities::link(OUT, Wordings::first_wn(Node::get_text(prep->where_prep_created)));
			verb_form *vf = Verbs::find_form(copular_verb, prep, NULL);
			RTVerbs::show_relation(OUT, vf);
			return;
		}
	WRITE("(for saying only)");
}

void RTVerbs::show_relation(OUTPUT_STREAM, verb_form *vf) {
	binary_predicate *bp = VerbMeanings::get_regular_meaning_of_form(vf);
	if (bp) {
		if (bp->right_way_round == FALSE) {
			bp = bp->reversal;
			WRITE("reversed ");
		}
		WordAssemblages::index(OUT, &(bp->relation_name));
	} else if (Verbs::has_special_meanings(vf)) {
		WRITE(" (a meaning internal to Inform)");
	} else {
		WRITE(" (for saying only)");
	}
}

void RTVerbs::tabulate_usages(package_request *R, verb_conjugation *vc, int tense, int hl) {
	TEMPORARY_TEXT(USAGES)
	verb_usage *vu; int c = 0;
	LOOP_OVER(vu, verb_usage)
		if ((vu->vu_lex_entry == vc) && (VerbUsages::is_used_negatively(vu) == FALSE)
			 && (VerbUsages::get_tense_used(vu) == tense)) {
			vocabulary_entry *lastword = WordAssemblages::last_word(&(vu->vu_text));
			if (c++ > 0) WRITE_TO(USAGES, "; ");
			if (Wide::cmp(Vocabulary::get_exemplar(lastword, FALSE), U"by") == 0) WRITE_TO(USAGES, "B ");
			else WRITE_TO(USAGES, "A ");
			WordAssemblages::index(USAGES, &(vu->vu_text));
			if (Wide::cmp(Vocabulary::get_exemplar(lastword, FALSE), U"by") == 0) WRITE_TO(USAGES, "A");
			else WRITE_TO(USAGES, "B");
		}
	if (Str::len(USAGES) > 0) Hierarchy::apply_metadata(R, hl, USAGES);
	DISCARD_TEXT(USAGES)
}

@h Compilation.

=
void RTVerbs::compile_conjugations(void) {
	verb_conjugation *vc;
	LOOP_OVER(vc, verb_conjugation) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "conjugation of '%A'", &(vc->infinitive));
		Sequence::queue(&RTVerbs::vc_compilation_agent,
			STORE_POINTER_verb_conjugation(vc), desc);
	}
	preposition *prep;
	LOOP_OVER(prep, preposition) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "preposition '%A'", &(prep->prep_text));
		Sequence::queue(&RTVerbs::prep_compilation_agent,
			STORE_POINTER_preposition(prep), desc);
	}
}

void RTVerbs::prep_compilation_agent(compilation_subtask *t) {
	preposition *prep = RETRIEVE_POINTER_preposition(t->data);
	package_request *pack = Hierarchy::local_package_to(PREPOSITIONS_HAP,
		prep->where_prep_created);	
	TEMPORARY_TEXT(ANT)
	WRITE_TO(ANT, "%A", &(prep->prep_text));
	Hierarchy::apply_metadata(pack, PREPOSITION_NAME_MD_HL, ANT);
	DISCARD_TEXT(ANT)
	Hierarchy::apply_metadata_from_number(pack, PREPOSITION_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(prep->where_prep_created)));
}

void RTVerbs::vc_compilation_agent(compilation_subtask *t) {
	verb_conjugation *vc = RETRIEVE_POINTER_verb_conjugation(t->data);
	packaging_state save = Functions::begin(RTVerbs::conjugation_fn_iname(vc));
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
	verb_meaning *vm =
		(vi)?Verbs::first_unspecial_meaning_of_verb_form(Verbs::base_form(vi)):NULL;
	binary_predicate *meaning = VerbMeanings::get_regular_meaning(vm);
	inter_name *rel_iname = Hierarchy::find(MEANINGLESS_RR_HL);
	if ((copular_verb) && (vc == copular_verb->conjugation))
		rel_iname = RTRelations::iname(R_equality);
	else if (meaning) rel_iname = RTRelations::iname(meaning);

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
}

@h Invocation as inflected text.
Verb conjugations can be invoked in say phrases, as in the text substitution
"[growl]" in the example "The [caged animal] [growl] at the zookeeper." This
function compiles the necessary code, which is basically a function call to
the VC's conjugation function:

=
void RTVerbs::ConjugateVerb_invoke_emit(verb_conjugation *vc,
	verb_conjugation *modal, int negated) {
	inter_name *cv_pos = Hierarchy::find(CV_POS_HL);
	inter_name *cv_neg = Hierarchy::find(CV_NEG_HL);
	if (modal) {
		if (negated) {
			EmitCode::call(RTVerbs::conjugation_fn_iname(modal));
			EmitCode::down();
				EmitCode::val_iname(K_value, cv_neg);
				EmitCode::call(Hierarchy::find(PNTOVP_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
				EmitCode::val_iname(K_value, RTVerbs::conjugation_fn_iname(vc));
			EmitCode::up();
		} else {
			EmitCode::call(RTVerbs::conjugation_fn_iname(modal));
			EmitCode::down();
				EmitCode::val_iname(K_value, cv_pos);
				EmitCode::call(Hierarchy::find(PNTOVP_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
				EmitCode::val_iname(K_value, RTVerbs::conjugation_fn_iname(vc));
			EmitCode::up();
		}
	} else {
		if (negated) {
			EmitCode::call(RTVerbs::conjugation_fn_iname(vc));
			EmitCode::down();
				EmitCode::val_iname(K_value, cv_neg);
				EmitCode::call(Hierarchy::find(PNTOVP_HL));
				EmitCode::val_iname(K_value, Hierarchy::find(STORY_TENSE_HL));
			EmitCode::up();
		} else {
			EmitCode::call(RTVerbs::conjugation_fn_iname(vc));
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

@h Compilation data for verb forms.
Now we turn to the "forms" of a verb; each one makes a |_verb_form| package
inside its verb's |_verb| package. (Modal verbs do not have forms.)

Each |verb_form| object contains this data:

@d VERB_FORM_COMPILATION_LINGUISTICS_CALLBACK RTVerbs::initialise_verb_form

=
typedef struct verb_form_compilation_data {
	struct package_request *vf_package;
	struct inter_name *vf_iname; /* routine to conjugate this */
	struct parse_node *where_vf_created;
} verb_form_compilation_data;

void RTVerbs::initialise_verb_form(verb_form *VF) {
	VF->verb_form_compilation.vf_package = NULL;
	VF->verb_form_compilation.vf_iname = NULL;
	VF->verb_form_compilation.where_vf_created = current_sentence;
}

@ And these too are then filled out on demand. Note that the |_verb_form|
packages occur as sub-packages of the relevant |_verb| packages.

=
package_request *RTVerbs::form_package(verb_form *vf) {
	if (vf->verb_form_compilation.vf_package == NULL) {
		package_request *R = RTVerbs::package(vf->underlying_verb,
			vf->verb_form_compilation.where_vf_created);
		vf->verb_form_compilation.vf_package =
			Hierarchy::package_within(VERB_FORMS_HAP, R);
	}
	return vf->verb_form_compilation.vf_package;
}

inter_name *RTVerbs::form_fn_iname(verb_form *vf) {
	if (vf->verb_form_compilation.vf_iname == NULL)
		vf->verb_form_compilation.vf_iname =
			Hierarchy::make_iname_in(FORM_FN_HL, RTVerbs::form_package(vf));
	return vf->verb_form_compilation.vf_iname;
}

@h Compilation.

=
void RTVerbs::compile_forms(void) {
	verb_form *vf;
	LOOP_OVER(vf, verb_form)
		if (RTVerbs::verb_form_is_instance(vf)) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "form of '%A'",  &(vf->underlying_verb->conjugation->infinitive));
			Sequence::queue(&RTVerbs::vf_compilation_agent,
				STORE_POINTER_verb_form(vf), desc);
		}
}

@ Not every verb form is an instance, that is, gives rise to a value at runtime:

=
int RTVerbs::verb_form_is_instance(verb_form *vf) {
	verb_conjugation *vc = vf->underlying_verb->conjugation;
	if ((vc) && (vc->auxiliary_only == FALSE) && (vc->instance_of_verb) &&
		((vf->preposition == NULL) || (vf->underlying_verb != copular_verb)))
		return TRUE;
	return FALSE;
}

void RTVerbs::vf_compilation_agent(compilation_subtask *t) {
	verb_form *vf = RETRIEVE_POINTER_verb_form(t->data);

	package_request *P = RTVerbs::form_package(vf);
	Emit::iname_constant(Hierarchy::make_iname_in(FORM_VALUE_MD_HL, P), K_value,
		RTVerbs::form_fn_iname(vf));
	Emit::numeric_constant(Hierarchy::make_iname_in(FORM_SORTING_MD_HL, P),
		(inter_ti) vf->allocation_id);

	@<Compile ConjugateVerbForm function@>;
}

@<Compile ConjugateVerbForm function@> =
	verb_conjugation *vc = vf->underlying_verb->conjugation;
	packaging_state save = Functions::begin(RTVerbs::form_fn_iname(vf));
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
		EmitCode::call(RTVerbs::conjugation_fn_iname(vc));
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
	inter_name *rel_iname = Hierarchy::find(MEANINGLESS_RR_HL);
	binary_predicate *meaning = VerbMeanings::get_regular_meaning(vm);
	if ((copular_verb) && (vc == copular_verb->conjugation))
		rel_iname = RTRelations::iname(R_equality);
	else if (meaning) rel_iname = RTRelations::iname(meaning);

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
					if (vc->tabulations[ACTIVE_VOICE].
						modal_auxiliary_usage[tense][sense][person][number] != 0)
						modal_verb = TRUE;

@<Compile conjugation in this sense@> =
	for (int tense=0; tense<NO_KNOWN_TENSES; tense++) {
		int some_exist = FALSE, some_dont_exist = FALSE,
			some_differ = FALSE, some_except_3PS_differ = FALSE, some_are_modal = FALSE;
		word_assemblage *common = NULL, *common_except_3PS = NULL;
		for (int person=0; person<NO_KNOWN_PERSONS; person++)
			for (int number=0; number<NO_KNOWN_NUMBERS; number++) {
				word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].
					vc_text[tense][sense][person][number]);
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
					if (vc->tabulations[ACTIVE_VOICE].
						modal_auxiliary_usage[tense][sense][person][number] != 0)
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
					word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].
						vc_text[tense][sense][person][number]);
					if (WordAssemblages::nonempty(*wa)) {
						EmitCode::inv(CASE_BIP);
						EmitCode::down();
							inter_ti part = ((inter_ti) person) + 3*((inter_ti) number) + 1;
							EmitCode::val_number((inter_ti) part);
							EmitCode::code();
							EmitCode::down();
								int mau = vc->tabulations[ACTIVE_VOICE].
									modal_auxiliary_usage[tense][sense][person][number];
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
			word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].
				vc_text[tense][sense][THIRD_PERSON][SINGULAR_NUMBER]);
			RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			wa = &(vc->tabulations[ACTIVE_VOICE].
				vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
			RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);
		EmitCode::up();
	EmitCode::up();

@<Compile for the case where all six parts are the same@> =
	word_assemblage *wa = &(vc->tabulations[ACTIVE_VOICE].
		vc_text[tense][sense][FIRST_PERSON][SINGULAR_NUMBER]);
	RTVerbs::conj_from_wa(wa, vc, modal_to_s, 0);

@h Utility functions.
Needed by the above:

=
void RTVerbs::conj_from_wa(word_assemblage *wa, verb_conjugation *vc,
	inter_symbol *modal_to_s, int mau) {
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		TEMPORARY_TEXT(OUT)
		if ((RTVerbs::takes_contraction_form(wa) == FALSE) &&
			(RTVerbs::takes_contraction_form(&(vc->infinitive))))
			WRITE(" ");
		int n;
		vocabulary_entry **words;
		WordAssemblages::as_array(wa, &words, &n);
		for (int i=0; i<n; i++) {
			if (i>0) WRITE(" ");
			WRITE("%V", words[i]);
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

@ Used to adjust spacing so that we get |I've|, not |I 've|:

=
int RTVerbs::takes_contraction_form(word_assemblage *wa) {
	vocabulary_entry *ve = WordAssemblages::first_word(wa);
	if (ve == NULL) return FALSE;
	inchar32_t *p = Vocabulary::get_exemplar(ve, FALSE);
	if (p[0] == '\'') return TRUE;
	return FALSE;
}
