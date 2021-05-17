[RTVariables::] Variables.

To compile the variables submodule for a compilation unit, which contains
_variable packages.

@h NVEs.
While a nonlocal variable, or NLV, looks like a simple storage location from
the perspective of Inform 7 source text -- the author assumes there's some
memory cell somewhere with this name -- it can actually be data expressed in
a range of different ways in Inter code. It might indeed be a global variable,
but then again it might be an array entry, or even a temporary location on
a stack; it might even be a constant.

This range of possible expressions is represented by a //nonlocal_variable_emission//,
or NVE. Each variable in principle has two, a left and a right NVE, though in
practice they are often the same. The left NVE tells Inform how to compile
assignments to the variable (i.e., when using it as an lvalue); the right NVE
how to compile lookups of its value (i.e., as an rvalue).

The NVE structure looks messy, but it's basically a union of four possibilities,
of which the last is the default:

=
typedef struct nonlocal_variable_emission {
	/* access as this Inter constant or global variable */
	struct inter_name *iname_form;

	/* access as the Inter |nothing| constant */
	int nothing_form;

	/* access as this shared variable on the M-stack */
	struct inter_name *shv_set_ID;
	int shv_index;
	int allow_access_even_if_does_not_exist;

	/* access as the iname belonging to the NLV itself */
	int use_own_iname;
} nonlocal_variable_emission;

@ The following is the default:

=
nonlocal_variable_emission RTVariables::default_nve(void) {
	nonlocal_variable_emission nve;
	nve.iname_form = NULL;

	nve.nothing_form = FALSE;

	nve.shv_set_ID = NULL;
	nve.shv_index = -1;
	nve.allow_access_even_if_does_not_exist = FALSE;

	nve.use_own_iname = FALSE;
	return nve;
}

@ So where do these NVEs come from?

=
nonlocal_variable_emission RTVariables::nve_from_nothing(void) {
	nonlocal_variable_emission nve = RTVariables::default_nve();
	nve.nothing_form = TRUE;
	return nve;
}

nonlocal_variable_emission RTVariables::nve_from_iname(inter_name *iname) {
	nonlocal_variable_emission nve = RTVariables::default_nve();
	nve.iname_form = iname;
	return nve;
}

nonlocal_variable_emission RTVariables::nve_from_mstack(inter_name *iname,
	int index, int allow_access_even_if_does_not_exist) {
	nonlocal_variable_emission nve = RTVariables::default_nve();
	nve.shv_set_ID = iname;
	nve.shv_index = index;
	nve.allow_access_even_if_does_not_exist = allow_access_even_if_does_not_exist;
	return nve;
}

nonlocal_variable_emission RTVariables::nve_from_own_iname(void) {
	nonlocal_variable_emission nve = RTVariables::default_nve();
	nve.use_own_iname = TRUE;
	return nve;
}

@ As noted above, the left and right NVEs are usually the same:

=
void RTVariables::set_NVE(nonlocal_variable *nlv, nonlocal_variable_emission nve) {
	if (nlv == NULL) internal_error("null nlv");
	nlv->compilation_data.lvalue_nve = nve;
	nlv->compilation_data.rvalue_nve = nve;
}

@ This is a particularly useful case, where |iname| can be the iname of a
constant or a global variable in Inter:

=
void RTVariables::store_in_this_iname(nonlocal_variable *nlv, inter_name *iname) {
	RTVariables::set_NVE(nlv, RTVariables::nve_from_iname(iname));
}

@ And in particular that's how we handle sentences like "Maximum score translates
into Inter as "MAX_SCORE".":

=
void RTVariables::identifier_translates(nonlocal_variable *nlv, text_stream *name) {
	if (nlv->compilation_data.nlv_name_translated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_QuantityTranslatedAlready),
			"this variable has already been translated",
			"so there must be some duplication somewhere.");
	}
	nlv->compilation_data.nlv_name_translated = TRUE;
	if (Str::eq(name, I"nothing")) {
		RTVariables::set_NVE(nlv, RTVariables::nve_from_nothing());
	} else {
		inter_name *as_iname = Produce::find_by_name(Emit::tree(), name);
		RTVariables::store_in_this_iname(nlv, as_iname);
	}
}

void RTVariables::set_NVE_from_existing(nonlocal_variable *nlv, nonlocal_variable *other) {
	if (nlv == NULL) internal_error("null nlv");
	if (other == NULL) internal_error("null other");
	RTVariables::set_NVE(nlv, other->compilation_data.rvalue_nve);
}

@ Left and right NVEs may differ in the case where an NLV is tied to a shared
variable which lives fleetingly on the M-stack at runtime. The difference is
essentially that a read of a shared variable (the right NVE) will forgive
the situation in which that variable does not exist; a write to it (the
left NVE) will not. See //BasicInformKit: MStack// for more.

=
void RTVariables::tie_NLV_to_shared_variable(nonlocal_variable *nlv, shared_variable *shv) {
	if (nlv == NULL) internal_error("null nlv");
	if (SharedVariables::is_actor(shv)) {
		RTVariables::store_in_this_iname(nlv, Hierarchy::find(ACTOR_HL));
	} else {
		nlv->compilation_data.lvalue_nve =
			RTVariables::nve_from_mstack(SharedVariables::get_owner_iname(shv),
				SharedVariables::get_index(shv), FALSE);
		nlv->compilation_data.rvalue_nve =
			RTVariables::nve_from_mstack(SharedVariables::get_owner_iname(shv),
				SharedVariables::get_index(shv), TRUE);
	}
}

@ And the following code results from a reference to the NVE.

=
void RTVariables::compile_NVE_as_val(nonlocal_variable *nlv, nonlocal_variable_emission *nve) {
	if (nve->iname_form) {
		EmitCode::val_iname(K_value, nve->iname_form);
	} else if (nve->shv_set_ID) {
		EmitCode::inv(LOOKUP_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(MSTACK_HL));
			int ex = MSTVO_HL;
			if (nve->allow_access_even_if_does_not_exist) ex = MSTVON_HL;
			EmitCode::call(Hierarchy::find(ex));
			EmitCode::down();
				EmitCode::val_iname(K_value, nve->shv_set_ID);
				EmitCode::val_number((inter_ti) nve->shv_index);
			EmitCode::up();
		EmitCode::up();
	} else if (nve->use_own_iname) {
		EmitCode::val_iname(K_value, RTVariables::iname(nlv));
	} else if (nve->nothing_form) {
		EmitCode::val_symbol(K_value, Emit::get_veneer_symbol(NOTHING_VSYMB));
	} else {
		internal_error("improperly formed nve");
	}
}

@h Writing without NVEs.
NVEs are a very flexible way to describe a storage location, but they do assume
that a write can be performed by a |STORE_BIP| instruction applied to a reference
to that location -- in other words, by some form of assignment like so:
= (text)
	Something = value;
	(Somewhere-->20) = value;
=
And here the term on the left is compiled by wrapping the code produced by
//RTVariables::compile_NVE_as_val// in a |REF_IST| to make a reference.
This is all well and good. But suppose the assignment has to be made by
some function instead?
= (text)
	ChangePlayer(value);
	...
	ChangePlayer (val) {
		...
		player = val;
		...
	}
=
An NVE cannot express the need to compile an assignment entirely differently.
So for such cases we provide the ability to set an explicit I6 scheme for
writing. In such a schema, |*1| means the variable, |*2| the value; so, for
example, |ChangePlayer(*2)| could be used in the above example.

=
void RTVariables::set_write_schema(nonlocal_variable *nlv, text_stream *sch) {
	nlv->compilation_data.nlv_write_schema = Str::duplicate(sch);
}

text_stream *RTVariables::get_write_schema(nonlocal_variable *nlv) {
	if (nlv == NULL) return NULL;
	return nlv->compilation_data.nlv_write_schema;
}

@h Compilation data.
Each |nonlocal_variable| object contains this data.

=
typedef struct variable_compilation_data {
	struct package_request *nlv_package;
	struct inter_name *nlv_iname;
	int hierarchy_location_id;
	int nlv_name_translated; /* has this been given storage as an I6 variable? */
	struct nonlocal_variable_emission rvalue_nve;
	struct nonlocal_variable_emission lvalue_nve;
	struct text_stream *nlv_write_schema; /* |NULL| for almost all variables */
	int var_is_initialisable_anyway; /* meaningful only if not stored in own iname */
} variable_compilation_data;

variable_compilation_data RTVariables::new_compilation_data(void) {
	variable_compilation_data data;
	data.nlv_package = NULL;
	data.hierarchy_location_id = -1;
	data.nlv_iname = NULL;
	data.nlv_name_translated = FALSE;
	data.rvalue_nve = RTVariables::nve_from_own_iname();
	data.lvalue_nve = RTVariables::nve_from_own_iname();
	data.nlv_write_schema = NULL;
	data.var_is_initialisable_anyway = FALSE;
	return data;
}

@ This function should be used immediately after a variable is created, or
(preferably) not at all.

=
void RTVariables::set_hierarchy_location(nonlocal_variable *nlv, int hl) {
	nlv->compilation_data.hierarchy_location_id = hl;
}

package_request *RTVariables::package(nonlocal_variable *nlv) {
	if (nlv->compilation_data.nlv_package == NULL)
		nlv->compilation_data.nlv_package =
			Hierarchy::local_package_to(VARIABLES_HAP,
				nlv->nlv_created_at);
	return nlv->compilation_data.nlv_package;
}

inter_name *RTVariables::iname(nonlocal_variable *nlv) {
	if (nlv->compilation_data.nlv_iname == NULL) {
		if (nlv->compilation_data.hierarchy_location_id >= 0)
			nlv->compilation_data.nlv_iname =
				Hierarchy::find(nlv->compilation_data.hierarchy_location_id);
		else
			nlv->compilation_data.nlv_iname =
				Hierarchy::make_iname_with_memo(VARIABLE_HL,
					RTVariables::package(nlv), nlv->name);
	}
	return nlv->compilation_data.nlv_iname;
}

@ Most variables are stored in the default way, and then they are certainly
initialisable. Those stored in some non-standard way are by default not,
unless a call to the following has been made:

=
void RTVariables::make_initialisable(nonlocal_variable *nlv) {
	nlv->compilation_data.var_is_initialisable_anyway = TRUE;
}

int RTVariables::stored_in_own_iname(nonlocal_variable *nlv) {
	if (nlv->compilation_data.lvalue_nve.use_own_iname) return TRUE;
	return FALSE;
}

int RTVariables::is_initialisable(nonlocal_variable *nlv) {
	if (RTVariables::stored_in_own_iname(nlv)) return TRUE;
	if (nlv->compilation_data.var_is_initialisable_anyway) return TRUE;
	return FALSE;
}

@h Compilation.

=
int RTVariables::compile(inference_subject_family *f, int ignored) {
	nonlocal_variable *nlv;
	LOOP_OVER(nlv, nonlocal_variable) {
		Hierarchy::apply_metadata_from_wording(
			RTVariables::package(nlv), VARIABLE_NAME_MD_HL, nlv->name);
		if ((RTVariables::stored_in_own_iname(nlv)) ||
			(nlv->constant_at_run_time == FALSE)) {
			inter_name *iname = RTVariables::iname(nlv);
			if (RTVariables::stored_in_own_iname(nlv) == FALSE)
				Produce::annotate_i(iname, EXPLICIT_VARIABLE_IANN, 1);
			inter_ti v1 = 0, v2 = 0;
			RTVariables::initial_value_as_pair(iname, &v1, &v2, nlv);
			Emit::variable(iname, nlv->nlv_kind, v1, v2);
			@<Add any anomalous extras@>;
		}
		if (nlv == max_score_VAR) {
			inter_name *iname = Hierarchy::make_iname_in(INITIAL_MAX_SCORE_HL,
				RTVariables::package(nlv));
			Hierarchy::make_available(iname);
			if (VariableSubjects::has_initial_value_set(max_score_VAR)) {
				Emit::initial_value_as_constant(iname, max_score_VAR);
			} else {
				Emit::numeric_constant(iname, 0);
			}
		}
	}
	return TRUE;
}

@ Here, an Inter function is compiled which returns the current value of the
command prompt variable; see //CommandParserKit: Parser//.

@<Add any anomalous extras@> =
	if (nlv == NonlocalVariables::command_prompt_variable()) {
		inter_name *iname = RTVariables::iname(nlv);
		inter_name *cpt_iname =
			Hierarchy::make_iname_in(COMMANDPROMPTTEXT_HL, InterNames::location(iname));
		packaging_state save = Functions::begin(cpt_iname);
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_text, iname);
		EmitCode::up();
		Functions::end(save);
		Hierarchy::make_available(cpt_iname);
	}

@h Initial values.
Three functions which all compile the initial value of a variable, in different
ways:

=
void RTVariables::initial_value_as_array_entry(nonlocal_variable *nlv) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	RTVariables::holster_initial_value(&VH, nlv);
	inter_ti v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	EmitArrays::generic_entry(v1, v2);
}

void RTVariables::initial_value_as_val(nonlocal_variable *nlv) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	RTVariables::holster_initial_value(&VH, nlv);
	Holsters::unholster_to_code_val(Emit::tree(), &VH);
}

void RTVariables::initial_value_as_pair(inter_name *iname, inter_ti *v1,
	inter_ti *v2, nonlocal_variable *nlv) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	packaging_state save = Packaging::enter_home_of(iname);
	RTVariables::holster_initial_value(&VH, nlv);
	Holsters::unholster_pair(&VH, v1, v2);
	Packaging::exit(Emit::tree(), save);
}

@ Which are all powered by the following function.

If the variable has no known initial value, it is given the initial
value for its kind where possible: but note that this may not be possible
if the source text says something like

>> Thickness is a kind of value. The carpet nap is a thickness that varies.

without specifying any thicknesses. If that's so, the set of legal thickness
values is empty, so the "carpet nap" variable cannot be created in a way
which makes its kind safe.

=
void RTVariables::holster_initial_value(value_holster *VH, nonlocal_variable *nlv) {
	parse_node *val =
		NonlocalVariables::substitute_constants(
			VariableSubjects::get_initial_value(
				nlv));
	if (Node::is(val, UNKNOWN_NT)) {
		current_sentence = nlv->nlv_created_at;
		@<Initialise with the default value of its kind@>
	} else {
		current_sentence = VariableSubjects::origin_of_initial_value(nlv);
		if (Lvalues::get_storage_form(val) == NONLOCAL_VARIABLE_NT)
			@<Issue a problem for one variable set equal to another@>
		else CompileValues::constant_to_holster(VH, val, nlv->nlv_kind);
	}
}

@<Initialise with the default value of its kind@> =
	if (DefaultValues::to_holster(VH, nlv->nlv_kind, nlv->name, "variable") == FALSE) {
		if (nlv->var_is_allowed_to_be_zero) {
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		} else {
			wording W = Kinds::Behaviour::get_name(nlv->nlv_kind, FALSE);
			Problems::quote_wording(1, nlv->name);
			Problems::quote_wording(2, W);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_EmptyDataType));
			Problems::issue_problem_segment(
				"I am unable to put any value into the variable '%1', because "
				"%2 is a kind of value with no actual values.");
			Problems::issue_problem_end();
		}
	}

@<Issue a problem for one variable set equal to another@> =
	nonlocal_variable *the_other = Node::get_constant_nonlocal_variable(val);
	if (the_other == NULL) internal_error(
		"Tried to compile initial value of variable as null variable");
	if (the_other == nlv) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, nlv->name);
		Problems::quote_kind(3, nlv->nlv_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_InitialiseQ2));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2', which should be %3 "
			"that varies, is to have an initial value equal to itself - "
			"this is such an odd thing to say that I think I must have "
			"misunderstood.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, nlv->name);
		Problems::quote_kind(3, nlv->nlv_kind);
		Problems::quote_wording(4, the_other->name);
		Problems::quote_kind(5, the_other->nlv_kind);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_InitialiseQ1));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2', which should be %3 "
			"that varies, is to have an initial value equal to '%4', "
			"which in turn is %5 that varies. At the start of play, "
			"variable values have to be set equal to definite constants, "
			"so this is not allowed.");
		Problems::issue_problem_end();
	}
