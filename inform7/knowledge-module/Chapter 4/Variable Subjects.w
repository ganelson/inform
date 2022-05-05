[VariableSubjects::] Variable Subjects.

The global variables family of inference subjects.

@ Variables are subjects for one purpose only: so that their purported initial
values can be declared and checked as being property values, of the special
property |P_variable_initial_value|.

=
inference_subject_family *nlv_family = NULL;

inference_subject_family *VariableSubjects::family(void) {
	if (nlv_family == NULL) {
		nlv_family = InferenceSubjects::new_family();
		METHOD_ADD(nlv_family, GET_DEFAULT_CERTAINTY_INFS_MTID, VariableSubjects::certainty);
		METHOD_ADD(nlv_family, CHECK_MODEL_INFS_MTID, VariableSubjects::check_model);
		METHOD_ADD(nlv_family, GET_NAME_TEXT_INFS_MTID, VariableSubjects::get_name);

		METHOD_ADD(nlv_family, EMIT_ALL_INFS_MTID, RTVariables::compile);
	}
	return nlv_family;
}

int VariableSubjects::certainty(inference_subject_family *f, inference_subject *infs) {
	return CERTAIN_CE;	
}

nonlocal_variable *VariableSubjects::to_variable(inference_subject *infs) {
	if ((infs) && (infs->infs_family == nlv_family))
		return RETRIEVE_POINTER_nonlocal_variable(infs->represents);
	return NULL;
}

inference_subject *VariableSubjects::new(nonlocal_variable *nlv) {
	return InferenceSubjects::new(global_variables,
		VariableSubjects::family(), STORE_POINTER_nonlocal_variable(nlv), NULL);
}

void VariableSubjects::get_name(inference_subject_family *family,
	inference_subject *from, wording *W) {
	nonlocal_variable *nlv = VariableSubjects::to_variable(from);
	*W = nlv->name;
}

@ The initial value of a variable is stored as the value of the subject's
property |P_variable_initial_value|. Attempts to store two different
values in the same variable are thus rejected as contradictory inferences
about the same subject.

=
inference *VariableSubjects::get_initial_value_inference(nonlocal_variable *nlv) {
	if (nlv) {
		inference_subject *infs = NonlocalVariables::to_subject(nlv);
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, infs, property_inf)
			if (PropertyInferences::get_property(inf) == P_variable_initial_value)
				return inf;
	}
	return NULL;
}

parse_node *VariableSubjects::get_initial_value(nonlocal_variable *nlv) {
	inference *inf = VariableSubjects::get_initial_value_inference(nlv);
	if (inf) return PropertyInferences::get_value(inf);
	return Specifications::new_UNKNOWN(EMPTY_WORDING);
}

parse_node *VariableSubjects::origin_of_initial_value(nonlocal_variable *nlv) {
	inference *inf = VariableSubjects::get_initial_value_inference(nlv);
	if (inf) return Inferences::where_inferred(inf);
	return NULL;
}

int VariableSubjects::has_initial_value_set(nonlocal_variable *nlv) {
	if ((nlv) && (VariableSubjects::origin_of_initial_value(nlv))) return TRUE;
	return FALSE;
}

@ Initial values are typechecked twice: once when the assertions machinery
actually generates them (see //assertions: Property Knowledge//) and then
again at model completion time. This looks wasteful -- why not typecheck them
just the once, at completion time?

The reason we don't is that the initial check produces more specific problem
messages, earlier on. For example, if we have:

>> The tally is a number that varies. The tally is the Entire Game.

At model-checking time we would detect this as a problematic comparison
between "tally" and "Entire Game", and the problem message will thus be
slightly vague, and not make clear that Inform realises we were trying to set
a variable.

On the other hand, we can't only do the initial check, because when assertions
are being worked through, some objects still have uncertain kinds.[1] So we
perform only a weaker test at assertion time, and a full-strength test at
model-checking time.

[1] For example, it may not be known whether something containing something else
is a "container" or a "room". Assigning that object to a variable whose kind
is "room" would therefore be uncheckable at assertion time.

=
int VariableSubjects::typecheck_initial_value(nonlocal_variable *nlv, parse_node *val,
	int model_checking_stage) {
	if (nlv == NULL) internal_error("tried to initialise null variable");

	kind *kind_as_declared = NonlocalVariables::kind(nlv);
	kind *constant_kind = Specifications::to_kind(val);

	@<Cast the empty list to whatever kind of list is expected@>;

	int outcome = Kinds::compatible(constant_kind, kind_as_declared);

	int throw_problem = FALSE;
	if (outcome == NEVER_MATCH) throw_problem = TRUE;
	if ((model_checking_stage) && (outcome == SOMETIMES_MATCH)) throw_problem = TRUE;
	if (throw_problem)
		@<The value doesn't match the kind of the variable@>;
	return TRUE;
}

@<Cast the empty list to whatever kind of list is expected@> =
	if ((Kinds::get_construct(constant_kind) == CON_list_of) &&
		(Kinds::eq(Kinds::unary_construction_material(constant_kind), K_nil)) &&
		(Lists::length_of_ll(Node::get_text(val)) == 0) &&
		(Kinds::get_construct(kind_as_declared) == CON_list_of)) {
		Lists::set_kind_of_list_at(Node::get_text(val), kind_as_declared);
		Node::set_kind_of_value(val, kind_as_declared);
		constant_kind = kind_as_declared;
	}

@<The value doesn't match the kind of the variable@> =
	LOG("Variable: %u; constant: %u\n", kind_as_declared, constant_kind);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, nlv->name);
	Problems::quote_wording(3, Node::get_text(val));
	Problems::quote_kind(4, kind_as_declared);
	Problems::quote_kind(5, constant_kind);
	if ((Kinds::Behaviour::is_subkind_of_object(kind_as_declared)) &&
		(Rvalues::is_nothing_object_constant(val))) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_QuantityKindNothing));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2', which should be %4 that varies, is to "
			"have the initial value 'nothing'. This is allowed as an 'object which varies', "
			"but the rules are stricter for %4.");
		Problems::issue_problem_end();
	} else {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GlobalKindWrong));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2', which is %4 that varies, "
			"should start out with the value '%3', but this is %5 and not %4.");
		if ((Kinds::Behaviour::is_object(constant_kind)) &&
			(!Kinds::Behaviour::is_object(kind_as_declared)))
			Problems::issue_problem_segment(
				" %PIn sentences like this, when I can't understand some text, "
				"I often assume that it's meant to be a new object. So it may "
				"be that you intended '%3' to be something quite different, "
				"but I just didn't get it.");
		UsingProblems::diagnose_further();
		Problems::issue_problem_end();
	}
	return FALSE;

@ At model-checking stage, we give variables their initial values. Note
that the //assertions: Property Knowledge// code will throw problem
messages if these have the wrong kind, so we don't need to.

=
void VariableSubjects::check_model(inference_subject_family *family,
	inference_subject *infs) {
	nonlocal_variable *nlv = VariableSubjects::to_variable(infs);
	if (nlv) {
		@<Verify that externally-stored nonlocals haven't been initialised@>;
		current_sentence = VariableSubjects::origin_of_initial_value(nlv);
		if (VariableSubjects::has_initial_value_set(nlv)) {
			parse_node *init = VariableSubjects::get_initial_value(nlv);
			VariableSubjects::typecheck_initial_value(nlv, init, TRUE);
		}
	}
}

@ If a variable is said to be the same as, say, |my_var| defined in some kit
of Inter code somewhere out of our reach, then it makes no sense to allow the
source text to specify its initial value -- the initial value is whatever
that faraway Inter code said it was.

@<Verify that externally-stored nonlocals haven't been initialised@> =
	if ((RTVariables::is_initialisable(nlv) == FALSE) &&
		(nlv->alias_subject == NULL) &&
		(VariableSubjects::has_initial_value_set(nlv))) {
		current_sentence = VariableSubjects::origin_of_initial_value(nlv);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, nlv->name);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_InaccessibleVariable));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2' has a specific initial value, "
			"but this is a variable which has been translated into an Inter variable "
			"defined in a kit. Any initial value must be given there, and not here.");
		Problems::issue_problem_end();
	}
