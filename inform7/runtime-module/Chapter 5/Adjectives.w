[RTAdjectives::] Adjectives.

To compile the adjectives submodule for a compilation unit, which contains
_adjective, _adjective_phrase and _measurement packages.

@h Compilation data.
Each |adjective| object contains this data:

=
typedef struct adjective_compilation_data {
	struct inter_name *adaptive_printing_fn_iname;
	struct package_request *aph_package;
	struct linked_list *held_inames[NO_ATOM_TASKS + 1]; /* of |adjective_iname_holder| */
	struct wording index_wording;
} adjective_compilation_data;

typedef struct adjective_iname_holder {
	struct kind *weakened_domain;
	struct inter_name *task_fn_iname;
	CLASS_DEFINITION
} adjective_iname_holder;

@ This is added in the //linguistics// module, where |adjective| is defined.

@d ADJECTIVE_COMPILATION_LINGUISTICS_CALLBACK RTAdjectives::initialise_compilation_data

=
void RTAdjectives::initialise_compilation_data(adjective *adj, wording W) {
	adj->adjective_compilation.aph_package = Hierarchy::local_package(ADJECTIVES_HAP);
	adj->adjective_compilation.adaptive_printing_fn_iname =
		Hierarchy::make_iname_in(ADJECTIVE_HL, adj->adjective_compilation.aph_package);
	for (int i=1; i<=NO_ATOM_TASKS; i++)
		adj->adjective_compilation.held_inames[i] = NEW_LINKED_LIST(adjective_iname_holder);
	adj->adjective_compilation.index_wording = W;
}

@ An adjective can be defined in multiple senses -- "empty" for containers does
not mean the same thing as "empty" for rulebooks -- and so the following can
return a variety of different runtime functions.

The following generates names for functions to carry out adjective tasks on
different domains, though they are distinguished only weakly. So "empty" for
containers will produce the same function as "empty" for doors: it will be for
that task function to distinguish these two senses at runtime. The compiler
cannot do so now because, in general, it cannot prove that an object value
will be a door rather than a container.

=
inter_name *RTAdjectives::task_fn_iname(adjective *adj, int task, kind *K) {
	kind *weak_K = Kinds::weaken(K, K_object);
	adjective_iname_holder *aih;
	LOOP_OVER_LINKED_LIST(aih, adjective_iname_holder,
		adj->adjective_compilation.held_inames[task])
		if (Kinds::eq(weak_K, aih->weakened_domain))
			return aih->task_fn_iname;
	aih = CREATE(adjective_iname_holder);
	aih->weakened_domain = weak_K;
	package_request *PR =
		Hierarchy::package_within(ADJECTIVE_TASKS_HAP, adj->adjective_compilation.aph_package);
	aih->task_fn_iname = Hierarchy::make_iname_in(TASK_FN_HL, PR);
	ADD_TO_LINKED_LIST(aih, adjective_iname_holder, adj->adjective_compilation.held_inames[task]);
	return aih->task_fn_iname;
}

@ The following much less satisfactory function takes a stab in the dark about
what the likely meaning is of an adjective whose name appears without context
inside |(+| and |+)| markers, within what's otherwise |(-| and |-)| inline code.
This "feature" is hardly ever used; the test case |BracketPlus| exercises it,
but a standard Inform installation makes no use of it in any examples.

Since inline Inter code written in I6 notation is typeless, there's no good way
to choose which sense of the adjective is meant, so we really are just guessing.

=
inter_name *RTAdjectives::guess_a_test_function(adjective *adj) {
	if (AdjectiveAmbiguity::schema_for_task(adj, NULL, TEST_ATOM_TASK) == NULL) {
		adjective_meaning *am = AdjectiveAmbiguity::first_meaning(adj);
		if (am == NULL) return NULL;
		kind *am_kind = AdjectiveMeaningDomains::get_kind(am);
		if (am_kind == NULL) return NULL;
		return RTAdjectives::task_fn_iname(adj, TEST_ATOM_TASK, am_kind);
	}
	return RTAdjectives::task_fn_iname(adj, TEST_ATOM_TASK, K_object);
}

@h Compilation.

=
void RTAdjectives::compile(void) {
	AdjectiveMeaningDomains::determine_all(); /* just in case this has not been done */
	adjective *adj;
	LOOP_OVER(adj, adjective) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "adjective "); Adjectives::write(desc, adj);
		Sequence::queue(&RTAdjectives::compilation_agent, STORE_POINTER_adjective(adj), desc);
	}
}

@ So the following makes a single |_adjective| package, and the main contents
will be the task functions given names above.

=
void RTAdjectives::compilation_agent(compilation_subtask *t) {
	adjective *adj = RETRIEVE_POINTER_adjective(t->data);
	for (int T=1; T<=NO_ATOM_TASKS; T++) {
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
	RTAdjectives::compile_adaptive_printing_fn(adj);
	Hierarchy::apply_metadata_from_raw_wording(adj->adjective_compilation.aph_package,
		ADJECTIVE_TEXT_MD_HL, adj->adjective_compilation.index_wording); 
	TEMPORARY_TEXT(ENTRY)
	int ac = 0;
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_precedence_order)
		ac++;
	int nc = ac;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_precedence_order) {
		ac--;
		if (nc > 1) {
			WRITE_TO(ENTRY, "%d. ", nc-ac);
		}
		RTAdjectives::print(ENTRY, am);
		if (ac >= 1) WRITE_TO(ENTRY, "; ");
	}
	Hierarchy::apply_metadata(adj->adjective_compilation.aph_package,
		ADJECTIVE_INDEX_MD_HL, ENTRY); 
	DISCARD_TEXT(ENTRY)
}

@

=
void RTAdjectives::print(OUTPUT_STREAM, adjective_meaning *am) {
	@<Index the domain of validity of the AM@>;
	if (am->negated_from) {
		wording W = Adjectives::get_nominative_singular(am->negated_from->owning_adjective);
		WRITE(" opposite of </i>%+W<i>", W);
	} else {
		if ((AdjectiveMeanings::nonstandard_index_entry(OUT, am) == FALSE) &&
			(Wordings::nonempty(am->indexing_text)))
			WRITE("%+W", am->indexing_text);
	}
	if (Wordings::nonempty(am->indexing_text))
		IndexUtilities::link(OUT, Wordings::first_wn(am->indexing_text));
}

@ This is supposed to imitate dictionaries, distinguishing meanings by
concisely showing their usage. Thus "empty" would have indexed entries
prefaced "(of a rulebook)", "(of an activity)", and so on.

@<Index the domain of validity of the AM@> =
	if (am->domain.domain_infs)
		WRITE("(of </i>%+W<i>) ",
			InferenceSubjects::get_name_text(am->domain.domain_infs));

@<Compile adjective definition for this kind@> =
	wording W = Adjectives::get_nominative_singular(adj);
	LOGIF(VARIABLE_CREATIONS, "Compiling support code for %W applying to %u, task %d\n",
		W, K, T);

	inter_name *iname = RTAdjectives::task_fn_iname(adj, T, K);
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
		stack_frame *frame = Frames::current_stack_frame();
		@<Compile body of function@>;
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

@ We run through possible meanings of the adjective which share the current
weak domain, and compile code which performs the stronger part of the domain
test at run-time.

@<Compile body of function@> =
	adjective_meaning *am;
	LOOP_OVER_LINKED_LIST(am, adjective_meaning, adj->adjective_meanings.in_precedence_order)
		if ((AdjectiveMeanings::can_generate_in_support_function(am, T)) &&
			(AdjectiveMeaningDomains::weak_match(K, am))) {
			current_sentence = am->defined_at;
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				InferenceSubjects::emit_element_of_condition(
					AdjectiveMeaningDomains::get_subject(am), it_s);
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(RETURN_BIP);
					EmitCode::down();
						if ((am->negated_from) && (T == TEST_ATOM_TASK)) {
							EmitCode::inv(NOT_BIP);
							EmitCode::down();
						}
						AdjectiveMeanings::generate_in_support_function(am, T, frame);
						if ((am->negated_from) && (T == TEST_ATOM_TASK)) {
							EmitCode::up();
						}
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}

@ Adaptive text. This is all disabled for English: let's not argue about blond/blonde,
it is essentially true that adjectives do not inflect in English, and so there is
no point compiling these sometimes long functions to perform that task.

=
void RTAdjectives::compile_adaptive_printing_fn(adjective *adj) {
	if (Projects::get_language_of_play(Task::project()) == DefaultLanguage::get(NULL))
		return; /* adjectives do not inflect */
	wording PW = Clusters::get_form_general(adj->adjective_names,
		Projects::get_language_of_play(Task::project()), 1, -1);
	if (Wordings::empty(PW)) return; /* somehow this was nameless anyway */

	packaging_state save = Functions::begin(adj->adjective_compilation.adaptive_printing_fn_iname);
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
					EmitCode::val_iname(K_value,
						Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
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
							EmitCode::val_iname(K_value,
								Hierarchy::find(PRIOR_NAMED_LIST_GENDER_HL));
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
								Projects::get_language_of_play(Task::project()),
								number_sought, gender_sought);
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

@h Invocation.
Adjectives can be invoked in say phrases: the result is to print out the name
of the adjective, but suitably inflected.

=
void RTAdjectives::invoke(adjective *adj) {
	EmitCode::call(adj->adjective_compilation.adaptive_printing_fn_iname);
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

@h Adjectival phrase packages.
When an adjective is given a |Definition:|, the result will be an |_adjective_phrase|
package, which contains a suitable function defining the adjective:

=
void RTAdjectives::make_adjective_phrase_package(id_body *idb) {
	if (CompileImperativeDefn::iname(idb) == NULL) {
		package_request *R =
			Hierarchy::local_package_to(ADJECTIVE_PHRASES_HAP, idb->head_of_defn->at);
		CompileImperativeDefn::set_iname(idb, Hierarchy::make_iname_in(DEFINITION_FN_HL, R));
	}
}

@h Compiling tasks for adjectives defined by I7 or Inter code.
First, an adjective defined by a condition written in raw Inter code can be
tested (but not asserted) using a schema, since those are also raw Inter coce.
All we do is remove the enrobing quotation marks around the condition.

=
void RTAdjectives::set_schemas_for_raw_Inter_condition(adjective_meaning *am, int wn) {
	i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
	Word::dequote(wn);
	Calculus::Schemas::modify(sch, "(%N)", wn);
}

@ Second, an adjective defined by the bare name of an Inter function. Again,
we remove the quotation marks. But now we can carry out the other tasks as well.

=
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

@ Third, an adjective defined by an imperative body of Inform 7 source text,
i.e., looking like a phrase declaration. Easiest of all: we delegate to the
function that this will compile to.

=
void RTAdjectives::set_schemas_for_I7_phrase(adjective_meaning *am, id_body *idb) {
	RTAdjectives::make_adjective_phrase_package(idb);
	i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
	Calculus::Schemas::modify(sch, "(%n(*1))", CompileImperativeDefn::iname(idb));
}

@ Fourth, and more challengingly, an adjective defined by a condition written
in Inform 7 source text. This cannot easily be done by the schema machinery,
because there's no good way to express the condition in Inform 6 notation; so
instead we must generate code directly, bypassing schemas altogether.

Such conditions are allowed to use the pseudo-variable "it".

=
int RTAdjectives::support_for_I7_condition(adjective_meaning_family *family,
	adjective_meaning *am, int T, int emit_flag, stack_frame *frame) {
	definition *def = RETRIEVE_POINTER_definition(am->family_specific_data);
	switch (T) {
		case TEST_ATOM_TASK:
			if (emit_flag) {
				Frames::alias_it(frame, def->domain_calling);

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

				Frames::alias_it(frame, EMPTY_WORDING);
			}
			return TRUE;
	}
	return FALSE;
}

@h Measurement packages.
The following makes |_measurement| packages for each use of a definition such
as "a container is roomy if its carrying capacity is 20 or more".

=
typedef struct measurement_compilation_data {
	struct inter_name *mdef_iname;
	int property_schema_written; /* I6 schema for testing written yet? */
} measurement_compilation_data;

measurement_compilation_data RTAdjectives::new_measurement_compilation_data(
	measurement_definition *mdef) {
	measurement_compilation_data mcd;
	package_request *P = Hierarchy::local_package(MEASUREMENTS_HAP);
	mcd.mdef_iname = Hierarchy::make_iname_in(MEASUREMENT_FN_HL, P);
	mcd.property_schema_written = FALSE;
	return mcd;
}

void RTAdjectives::make_mdef_test_schema(measurement_definition *mdef, int T) {
	if ((mdef->compilation_data.property_schema_written == FALSE) &&
		(T == TEST_ATOM_TASK)) {
		i6_schema *sch = AdjectiveMeanings::make_schema(
			mdef->headword_as_adjective, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "%n(*1)", mdef->compilation_data.mdef_iname);
		mdef->compilation_data.property_schema_written = TRUE;
	}
}

void RTAdjectives::compile_mdef_test_functions(void) {
	measurement_definition *mdef;
	LOOP_OVER(mdef, measurement_definition)
		if (mdef->compilation_data.property_schema_written) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "measurement definition for '%W'", mdef->headword);
			Sequence::queue(&RTAdjectives::mdef_compilation_agent,
				STORE_POINTER_measurement_definition(mdef), desc);
		}
}

void RTAdjectives::mdef_compilation_agent(compilation_subtask *t) {
	measurement_definition *mdef = RETRIEVE_POINTER_measurement_definition(t->data);
	packaging_state save = Functions::begin(mdef->compilation_data.mdef_iname);
	local_variable *lv = LocalVariables::new_call_parameter(
		Frames::current_stack_frame(),
		EMPTY_WORDING,
		AdjectiveMeaningDomains::get_kind(mdef->headword_as_adjective));
	parse_node *var = Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, lv);
	parse_node *evaluated_prop = Lvalues::new_PROPERTY_VALUE(
		Rvalues::from_property(mdef->prop), var);
	parse_node *val = NULL;
	if (<s-literal>(mdef->region_threshold_text)) val = <<rp>>;
	else internal_error("literal unreadable");
	pcalc_prop *prop = Atoms::binary_PREDICATE_new(
		Measurements::weak_comparison_bp(mdef->region_shape),
		Terms::new_constant(evaluated_prop),
		Terms::new_constant(val));
	if (TypecheckPropositions::type_check(prop,
		TypecheckPropositions::tc_problem_reporting(
			mdef->region_threshold_text,
			"be giving the boundary of the definition")) == ALWAYS_MATCH) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			CompilePropositions::to_test_as_condition(NULL, prop);
			EmitCode::code();
			EmitCode::down();
				EmitCode::rtrue();
			EmitCode::up();
		EmitCode::up();
	}
	EmitCode::rfalse();
	Functions::end(save);
}
