[RTAdjectives::] Adjectives.

To compile run-time support for adjective definitions.

@ The following utility is used to loop through the sorted meaning list,
skipping over any which have been dealt with already.

=
adjective_meaning *RTAdjectives::list_next_domain_kind(adjective_meaning *am, kind **K, int T) {
	while ((am) && ((am->defined_already) || (AdjectiveMeanings::compilation_possible(am, T) == FALSE)))
		am = am->next_sorted;
	if (am == NULL) return NULL;
	*K = AdjectiveMeanings::get_domain(am);
	return am->next_sorted;
}

@ And this is where we do the iteration. The idea is that one adjective
definition routine is defined (for each task number) which covers all of
the weakly-domain-equal definitions for the same adjective. Thus one
routine might handle "detailed" for rulebooks, and another might handle
"detailed" for all of its meanings associated with objects -- possibly
many AMs.

=
void RTAdjectives::compile_support_code(void) {
	@<Ensure, just in case, that domains exist and are sorted on@>;
	int T;
	for (T=1; T<=NO_ADJECTIVE_TASKS; T++) {
		adjective *aph;
		LOOP_OVER(aph, adjective) {
			adjective_meaning *am;
			for (am = aph->adjective_meanings.possible_meanings; am; am = am->next_meaning)
				am->defined_already = FALSE;
			for (am = aph->adjective_meanings.sorted_meanings; am; ) {
				kind *K = NULL;
				am = RTAdjectives::list_next_domain_kind(am, &K, T);
				if (K)
					@<Compile adjective definition for this atomic kind of value@>;
			}
		}
	}
}

@ It's unlikely that we have got this far without the domains for the AMs
having been established, but certainly possible. We need the domains to be
known in order to sort.

@<Ensure, just in case, that domains exist and are sorted on@> =
	adjective *aph;
	LOOP_OVER(aph, adjective) {
		adjective_meaning *am;
		for (am = aph->adjective_meanings.possible_meanings; am; am = am->next_meaning) {
			AdjectiveMeanings::set_definition_domain(am, FALSE);
			am->defined_already = FALSE;
		}
		AdjectiveAmbiguity::sort(aph);
	}

@ The following is a standard way to compile a one-off routine.

@<Compile adjective definition for this atomic kind of value@> =
	wording W = Adjectives::get_nominative_singular(aph);
	LOGIF(VARIABLE_CREATIONS, "Compiling support code for %W applying to %u, task %d\n",
		W, K, T);

	inter_name *iname = AdjectiveMeanings::iname(aph, T, RTKinds::weak_id(K));
	packaging_state save = Routines::begin(iname);
	@<Add an it-variable to represent the value or object in the domain@>;

	TEMPORARY_TEXT(C)
	WRITE_TO(C, "meaning of \"");
	if (Wordings::nonempty(W)) WRITE_TO(C, "%~W", W);
	else WRITE_TO(C, "<nameless>");
	WRITE_TO(C, "\"");
	Emit::code_comment(C);
	DISCARD_TEXT(C)

	if (problem_count == 0) {
		local_variable *it_lv = LocalVariables::it_variable();
		inter_symbol *it_s = LocalVariables::declare_this(it_lv, FALSE, 8);
		RTAdjectives::list_compile(aph->adjective_meanings.sorted_meanings, Frames::current_stack_frame(), K, T, it_s);
	}
	Produce::rfalse(Emit::tree());

	Routines::end(save);

@ The stack frame has just one call parameter: the value $x$ which might, or
might not, be such that adjective($x$) is true. We allow this to be called
"it", though it can also have a calling name in some cases (see below).

Clearly it ought to have the kind which defines the domain -- so it's a rulebook
if the domain is all rulebooks, and so on -- but it doesn't always do so. The
exception is that it is bogusly given the kind "number" if the adjective is
being defined only by I6 routines. This is done to avoid compiling very
inefficient code from the Standard Rules. For instance, the SR reads, in
slightly simplified form:

>> Definition: a text is empty if I6 routine |"TEXT\_TY\_Empty"| says so.

rather than the more obvious:

>> Definition: a text is empty if it is not |""|.

Both of these definitions work. But if the routine defining "empty" for text
is allowed to act on a text variable, Inform needs to compile code which acts
on block values held on the memory heap at run-time. That means it needs to
compile a memory heap; and that costs 8K or so of storage, making large
Z-machine games which don't need text alteration or lists impossible to fit into
the 64K array space limit. (There's also a benefit even if we do need a heap;
the adjective can act on a direct pointer to the structure, and no time is
wasted allocating memory and copying the block value first.)

@<Add an it-variable to represent the value or object in the domain@> =
	kind *add_K = K_number;
	adjective_meaning *am;
	for (am = aph->adjective_meanings.sorted_meanings; am; am = am->next_sorted)
		if ((Phrases::RawPhrasal::is_by_Inter_function(am) == FALSE) &&
			(AdjectiveMeanings::domain_weak_match(K, AdjectiveMeanings::get_domain(am))))
			add_K = K;

	LocalVariables::add_pronoun(Frames::current_stack_frame(), EMPTY_WORDING, add_K);
	LocalVariables::enable_possessive_form_of_it();

@ We run through possible meanings of the APH which share the current weak
domain, and compile code which performs the stronger part of the domain
test at run-time. In practice, at present the only weak domain which might
have multiple definitions is "object", but that may change.

=
void RTAdjectives::list_compile(adjective_meaning *list_head,
	ph_stack_frame *phsf, kind *K, int T, inter_symbol *t0_s) {
	adjective_meaning *am;
	for (am = list_head; am; am = am->next_sorted)
		if ((AdjectiveMeanings::compilation_possible(am, T)) &&
			(AdjectiveMeanings::domain_weak_match(K, AdjectiveMeanings::get_domain(am)))) {
			current_sentence = am->defined_at;
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				InferenceSubjects::emit_element_of_condition(am->domain_infs, t0_s);
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), RETURN_BIP);
					Produce::down(Emit::tree());
						if ((am->meaning_parity == FALSE) && (T == TEST_ADJECTIVE_TASK)) {
							Produce::inv_primitive(Emit::tree(), NOT_BIP);
							Produce::down(Emit::tree());
						}
						AdjectiveMeanings::emit_meaning(am, T, phsf);
						am->defined_already = TRUE;
						if ((am->meaning_parity == FALSE) && (T == TEST_ADJECTIVE_TASK)) {
							Produce::up(Emit::tree());
						}
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
}

@ Adaptive text:

=
void RTAdjectives::agreements(void) {
	if (Projects::get_language_of_play(Task::project()) == DefaultLanguage::get(NULL)) return;
	adjective *aph;
	LOOP_OVER(aph, adjective) {
		wording PW = Clusters::get_form_general(aph->adjective_names, Projects::get_language_of_play(Task::project()), 1, -1);
		if (Wordings::empty(PW)) continue;

		packaging_state save = Routines::begin(aph->adjective_compilation.aph_iname);
		inter_symbol *o_s = LocalVariables::add_named_call_as_symbol(I"o");
		inter_symbol *force_plural_s = LocalVariables::add_named_call_as_symbol(I"force_plural");
		inter_symbol *gna_s = LocalVariables::add_internal_local_as_symbol(I"gna");

		Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, o_s);
				Produce::val_nothing(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gna_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 6);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, gna_s);
					inter_name *iname = Hierarchy::find(GETGNAOFOBJECT_HL);
					Produce::inv_call_iname(Emit::tree(), iname);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, o_s);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, force_plural_s);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), NE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) -1);
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, gna_s);
							Produce::inv_primitive(Emit::tree(), PLUS_BIP);
							Produce::down(Emit::tree());
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
								Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, gna_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, gna_s);
			Produce::inv_primitive(Emit::tree(), MODULO_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, gna_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 6);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, gna_s);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				for (int gna=0; gna<6; gna++) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) gna);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), PRINT_BIP);
							Produce::down(Emit::tree());
								TEMPORARY_TEXT(T)
								int number_sought = 1, gender_sought = NEUTER_GENDER;
								if (gna%3 == 0) gender_sought = MASCULINE_GENDER;
								if (gna%3 == 1) gender_sought = FEMININE_GENDER;
								if (gna >= 3) number_sought = 2;
								wording AW = Clusters::get_form_general(aph->adjective_names,
									Projects::get_language_of_play(Task::project()), number_sought, gender_sought);
								if (Wordings::nonempty(AW)) WRITE_TO(T, "%W", AW);
								else WRITE_TO(T, "%W", PW);
								Produce::val_text(Emit::tree(), T);
								DISCARD_TEXT(T)
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Routines::end(save);
	}
}

void RTAdjectives::emit(adjective *aph) {
	Produce::inv_call_iname(Emit::tree(), aph->adjective_compilation.aph_iname);
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_NOUN_HL));
		Produce::inv_primitive(Emit::tree(), GE_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PRIOR_NAMED_LIST_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_iname(Emit::tree(), K_number, Hierarchy::find(SAY__P_HL));
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
	Produce::up(Emit::tree());
}
