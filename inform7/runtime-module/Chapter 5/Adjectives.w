[RTAdjectives::] Adjectives.

To compile run-time support for adjective definitions.

@h Symbols.

=
typedef struct adjective_compilation_data {
	struct inter_name *aph_iname;
	struct package_request *aph_package;
	struct linked_list *held_inames[NO_ATOM_TASKS + 1]; /* of |adjective_iname_holder| */
} adjective_compilation_data;

@

@d ADJECTIVE_COMPILATION_LINGUISTICS_CALLBACK RTAdjectives::initialise_compilation_data

=
void RTAdjectives::initialise_compilation_data(adjective *adj) {
	adj->adjective_compilation.aph_package =
		Hierarchy::local_package(ADJECTIVES_HAP);
	adj->adjective_compilation.aph_iname =
		Hierarchy::make_iname_in(ADJECTIVE_HL, adj->adjective_compilation.aph_package);
	for (int i=1; i<=NO_ATOM_TASKS; i++)
		adj->adjective_compilation.held_inames[i] = NEW_LINKED_LIST(adjective_iname_holder);
}

typedef struct adjective_iname_holder {
	struct inter_name *weak_ID_of_domain;
	struct inter_name *iname_held;
	CLASS_DEFINITION
} adjective_iname_holder;

inter_name *RTAdjectives::iname(adjective *adj, int task, inter_name *weak_id) {
	adjective_iname_holder *aih;
	LOOP_OVER_LINKED_LIST(aih, adjective_iname_holder, adj->adjective_compilation.held_inames[task]) {
		if (aih->weak_ID_of_domain == weak_id) {
			return aih->iname_held;
		}
	}
	aih = CREATE(adjective_iname_holder);
	aih->weak_ID_of_domain = weak_id;
	package_request *PR =
		Hierarchy::package_within(ADJECTIVE_TASKS_HAP, adj->adjective_compilation.aph_package);
	aih->iname_held = Hierarchy::make_iname_in(TASK_FN_HL, PR);
	ADD_TO_LINKED_LIST(aih, adjective_iname_holder, adj->adjective_compilation.held_inames[task]);
	return aih->iname_held;
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
	for (int T=1; T<=NO_ATOM_TASKS; T++) {
		adjective *adj;
		LOOP_OVER(adj, adjective) {
			adjective_meaning *am;
			LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order)
				am->has_been_compiled_in_support_function = FALSE;
			LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order) {
				if ((am->has_been_compiled_in_support_function) ||
					(AdjectiveMeanings::can_generate_in_support_function(am, T) == FALSE))
					continue;
				kind *K = AdjectiveMeaningDomains::get_kind(am);
				if (K) @<Compile adjective definition for this kind@>;
			}
		}
	}
}

@ It's very likely that this sort has already been performed, and that the
domains of each meaning have long since been established. But performing a
"set" one last time can catch problems which could not previously be diagnosed.

@<Ensure, just in case, that domains exist and are sorted on@> =
	adjective *adj;
	LOOP_OVER(adj, adjective) {
		adjective_meaning *am;
		LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_defn_order)
			AdjectiveMeaningDomains::determine(am);
		AdjectiveAmbiguity::sort(adj);
	}

@ The following is a standard way to compile a one-off routine.

@<Compile adjective definition for this kind@> =
	wording W = Adjectives::get_nominative_singular(adj);
	LOGIF(VARIABLE_CREATIONS, "Compiling support code for %W applying to %u, task %d\n",
		W, K, T);

	inter_name *iname = RTAdjectives::iname(adj, T, RTKinds::weak_id_iname(K));
	packaging_state save = Functions::begin(iname);
	@<Add an it-variable to represent the value or object in the domain@>;

	TEMPORARY_TEXT(C)
	WRITE_TO(C, "meaning of \"");
	if (Wordings::nonempty(W)) WRITE_TO(C, "%~W", W);
	else WRITE_TO(C, "<nameless>");
	WRITE_TO(C, "\"");
	EmitCode::comment(C);
	DISCARD_TEXT(C)

	if (problem_count == 0) {
		local_variable *it_lv = LocalVariables::it_variable();
		inter_symbol *it_s = LocalVariables::declare(it_lv);
		RTAdjectives::list_compile(adj, Frames::current_stack_frame(), K, T, it_s);
	}
	EmitCode::rfalse();

	Functions::end(save);

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
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_precedence_order)
		if ((AdjectivesByInterFunction::is_by_Inter_function(am) == FALSE) &&
			(AdjectiveMeaningDomains::weak_match(K, am)))
			add_K = K;

	stack_frame *frame = Frames::current_stack_frame();
	Frames::enable_it(frame, EMPTY_WORDING, add_K);
	Frames::enable_its(frame);

@ We run through possible meanings of the APH which share the current weak
domain, and compile code which performs the stronger part of the domain
test at run-time. In practice, at present the only weak domain which might
have multiple definitions is "object", but that may change.

=
void RTAdjectives::list_compile(adjective *adj,
	stack_frame *phsf, kind *K, int T, inter_symbol *t0_s) {
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_precedence_order)
		if ((AdjectiveMeanings::can_generate_in_support_function(am, T)) &&
			(AdjectiveMeaningDomains::weak_match(K, am))) {
			current_sentence = am->defined_at;
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				InferenceSubjects::emit_element_of_condition(
					AdjectiveMeaningDomains::get_subject(am), t0_s);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						if ((am->negated_from) && (T == TEST_ATOM_TASK)) {
							EmitCode::inv(NOT_BIP);
							EmitCode::down();
						}
						AdjectiveMeanings::generate_in_support_function(am, T, phsf);
						if ((am->negated_from) && (T == TEST_ATOM_TASK)) {
							EmitCode::up();
						}
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}
}

@ Adaptive text:

=
void RTAdjectives::agreements(void) {
	if (Projects::get_language_of_play(Task::project()) == DefaultLanguage::get(NULL)) return;
	adjective *adj;
	LOOP_OVER(adj, adjective) {
		wording PW = Clusters::get_form_general(adj->adjective_names, Projects::get_language_of_play(Task::project()), 1, -1);
		if (Wordings::empty(PW)) continue;

		packaging_state save = Functions::begin(adj->adjective_compilation.aph_iname);
		inter_symbol *o_s = LocalVariables::new_other_as_symbol(I"o");
		inter_symbol *force_plural_s = LocalVariables::new_other_as_symbol(I"force_plural");
		inter_symbol *gna_s = LocalVariables::new_internal_as_symbol(I"gna");

		EmitCode::inv(IFELSE_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, o_s);
				EmitCode::val_nothing();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gna_s);
					EmitCode::val_number(6);
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, gna_s);
					inter_name *iname = Hierarchy::find(GETGNAOFOBJECT_HL);
					EmitCode::call(iname);
					EmitCode::down();
						EmitCode::val_symbol(K_value, o_s);
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, force_plural_s);
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(IFELSE_BIP);
				EmitCode::down();
					EmitCode::inv(NE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
						EmitCode::val_number((inter_ti) -1);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, gna_s);
							EmitCode::inv(PLUS_BIP);
							EmitCode::down();
								EmitCode::val_number(3);
								EmitCode::val_iname(K_value, Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, gna_s);
							EmitCode::val_number(3);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, gna_s);
			EmitCode::inv(MODULO_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, gna_s);
				EmitCode::val_number(6);
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(SWITCH_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, gna_s);
			EmitCode::code();
			EmitCode::down();
				for (int gna=0; gna<6; gna++) {
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_number((inter_ti) gna);
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(PRINT_BIP);
							EmitCode::down();
								TEMPORARY_TEXT(T)
								int number_sought = 1, gender_sought = NEUTER_GENDER;
								if (gna%3 == 0) gender_sought = MASCULINE_GENDER;
								if (gna%3 == 1) gender_sought = FEMININE_GENDER;
								if (gna >= 3) number_sought = 2;
								wording AW = Clusters::get_form_general(adj->adjective_names,
									Projects::get_language_of_play(Task::project()), number_sought, gender_sought);
								if (Wordings::nonempty(AW)) WRITE_TO(T, "%W", AW);
								else WRITE_TO(T, "%W", PW);
								EmitCode::val_text(T);
								DISCARD_TEXT(T)
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				}
			EmitCode::up();
		EmitCode::up();

		Functions::end(save);
	}
}

void RTAdjectives::emit(adjective *adj) {
	EmitCode::call(adj->adjective_compilation.aph_iname);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(PRIOR_NAMED_NOUN_HL));
		EmitCode::inv(GE_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(PRIOR_NAMED_LIST_HL));
			EmitCode::val_number(2);
		EmitCode::up();
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_iname(K_number, Hierarchy::find(SAY__P_HL));
		EmitCode::val_number(1);
	EmitCode::up();
}

@ The following is needed when making sense of the I6-to-I7 escape sequence
|(+ adj +)|, where |adj| is the name of an adjective. Since I6 is typeless,
there's no good way to choose which sense of the adjective is meant, so we
don't know which routine to expand out. The convention is: a meaning for
objects, if there is one; otherwise the first-declared meaning.

=
inter_name *RTAdjectives::iname_of_adjective_test_function(adjective *adj) {
	i6_schema *sch;
	inter_name *weak_id = RTKinds::weak_id_iname(K_object);
	sch = AdjectiveAmbiguity::schema_for_task(adj, NULL, TEST_ATOM_TASK);
	if (sch == NULL) {
		adjective_meaning *am = AdjectiveAmbiguity::first_meaning(adj);
		if (am == NULL) return NULL;
		kind *am_kind = AdjectiveMeaningDomains::get_kind(am);
		if (am_kind == NULL) return NULL;
		weak_id = RTKinds::weak_id_iname(am_kind);
	}
	return RTAdjectives::iname(adj, TEST_ATOM_TASK, weak_id);
}

void RTAdjectives::set_schemas_for_raw_Inter_condition(adjective_meaning *am, int wn) {
	i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
	Word::dequote(wn);
	Calculus::Schemas::modify(sch, "(%N)", wn);
}

void RTAdjectives::set_schemas_for_raw_Inter_function(adjective_meaning *am, wording RW,
	int setting) {
	int wn = Wordings::first_wn(RW);
	Word::dequote(wn);
	if (setting) {
		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "*=-(%N(*1, -1))", wn);
		AdjectiveMeanings::perform_task_via_function(am, TEST_ATOM_TASK);
		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "*=-(%N(*1, true))", wn);
		AdjectiveMeanings::perform_task_via_function(am, NOW_ATOM_TRUE_TASK);
		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "*=-(%N(*1, false))", wn);
		AdjectiveMeanings::perform_task_via_function(am, NOW_ATOM_FALSE_TASK);
	} else {
		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "*=-(%N(*1))", wn);
		AdjectiveMeanings::perform_task_via_function(am, TEST_ATOM_TASK);
	}
}

void RTAdjectives::make_iname(id_body *idb) {
	if (CompileImperativeDefn::iname(idb) == NULL) {
		package_request *R = Hierarchy::local_package_to(ADJECTIVE_PHRASES_HAP, idb->head_of_defn->at);
		CompileImperativeDefn::set_iname(idb, Hierarchy::make_iname_in(DEFINITION_FN_HL, R));
	}
}

void RTAdjectives::set_schemas_for_I7_phrase(adjective_meaning *am, id_body *idb) {
	RTAdjectives::make_iname(idb);
	i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
	Calculus::Schemas::modify(sch, "(%n(*1))", CompileImperativeDefn::iname(idb));
}

int RTAdjectives::support_for_I7_condition(adjective_meaning_family *family,
	adjective_meaning *am, int T, int emit_flag, stack_frame *phsf) {
	definition *def = RETRIEVE_POINTER_definition(am->family_specific_data);
	switch (T) {
		case TEST_ATOM_TASK:
			if (emit_flag) {
				Frames::alias_it(phsf, def->domain_calling);

				if (Wordings::nonempty(def->condition_to_match)) {
					current_sentence = def->node;
					parse_node *spec = NULL;
					if (<s-condition>(def->condition_to_match)) spec = <<rp>>;
					if ((spec == NULL) ||
						(Dash::validate_conditional_clause(spec) == FALSE)) {
						LOG("Error on: %W = $T", def->condition_to_match, spec);
						StandardProblems::definition_problem(Task::syntax_tree(),
							_p_(PM_DefinitionBadCondition),
							def->node,
							"that condition makes no sense to me",
							"although the preamble to the definition was properly "
							"written. There must be something wrong after 'if'.");
					} else {
						if (def->format == -1) {
							EmitCode::inv(NOT_BIP);
							EmitCode::down();
						}
						CompileValues::to_code_val_of_kind(spec, K_number);
						if (def->format == -1) {
							EmitCode::up();
						}
					}
				}

				Frames::alias_it(phsf, EMPTY_WORDING);
			}
			return TRUE;
	}
	return FALSE;
}

