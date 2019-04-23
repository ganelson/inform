[NonlocalVariables::] Nonlocal Variables.

To manage variables whose scope is wider than the current rule.

@h Definitions.

@ Though the following structure is rather cluttered, the idea is simple
enough: a non-local variable -- it may be global, or may belong to a rulebook,
an action, or an activity -- is like a property, but simpler. It belongs to
no particular object, so we don't need to worry about permissions for it to
exist; we can simply record inferences about its value.

=
typedef struct nonlocal_variable_emission {
	struct inter_name *iname_form;
	struct text_stream *textual_form;
	int stv_ID;
	int stv_index;
	int allow_outside;
	int use_own_iname;
} nonlocal_variable_emission;

typedef struct nonlocal_variable {
	struct wording name; /* text of the name */
	struct parse_node *nlv_created_at; /* sentence creating the variable */
	struct wording var_documentation_symbol; /* reference to manual, if any */

	struct stacked_variable *scope; /* where it exists, or |NULL| for everywhere */
	struct kind *nlv_kind; /* what kind of value it holds */
	struct inference_subject *nlv_knowledge; /* what we know about its initial value */

	int constant_at_run_time; /* for instance, for "story title" */

	struct inference_subject *alias_to_infs; /* like "player" to "yourself" */

	int housed_in_variables_array; /* i.e. |FALSE| if stored elsewhere */
	int var_is_initialisable_anyway; /* despite being stored elsewhere, that is */
	int var_is_bibliographic; /* one of the bibliographic constants set at the end */
	int var_is_allowed_to_be_zero; /* for an empty enumerated kind, despite non-safety */
	struct inter_name *nlv_iname;
	int nlv_name_translated; /* has this been given storage as an I6 variable? */
	struct nonlocal_variable_emission rvalue_nve;
	struct nonlocal_variable_emission lvalue_nve;
	char *nlv_write_schema; /* or |NULL| to assign to the L-value form */

	int substitution_marker; /* to prevent infinite regress when substituting */

	MEMORY_MANAGEMENT
} nonlocal_variable;

@ These three special NLVs are used for the "notable" hacky Standard Rules
variables mentioned below:

=
nonlocal_variable *i6_glob_VAR = NULL;
nonlocal_variable *i6_nothing_VAR = NULL; /* the I6 |nothing| constant */
nonlocal_variable *command_prompt_VAR = NULL; /* the command prompt text */

@ We record the one most recently made:

=
nonlocal_variable *latest_nonlocal_variable = NULL;

@ These are variable names which Inform provides special support for; it
recognises the English names when they are defined by the Standard Rules. (So
there is no need to translate this to other languages.) The first two are
hacky constructs which only the SR should ever refer to.

=
<notable-variables> ::=
	i6-varying-global |
	i6-nothing-constant |
	command prompt

@ We can create a new variable provided we give its name, kind and scope.
When the scope isn't global, the variable is said to be "stacked", which is a
reference to how it's stored at run-time.

=
nonlocal_variable *NonlocalVariables::new_global(wording W, kind *K) {
	PROTECTED_MODEL_PROCEDURE;
	return NonlocalVariables::new(W, K, NULL);
}

nonlocal_variable *NonlocalVariables::new_stacked(wording W, kind *K,
	stacked_variable *scope) {
	if (scope == NULL) internal_error("not a stacked nonlocal_variable at all");
	return NonlocalVariables::new(W, K, scope);
}

@ =
nonlocal_variable *NonlocalVariables::new(wording W, kind *K, stacked_variable *scope) {
	if (K == NULL) internal_error("created variable without kind");
	if (Kinds::Behaviour::definite(K) == FALSE) @<Issue problem message for an indefinite variable@>;

	nonlocal_variable *nlv = CREATE(nonlocal_variable);
	@<Actually create the nonlocal variable@>;

	latest_nonlocal_variable = nlv;
	@<Take note if the notable variables turn up here@>;
	Plugins::Call::new_variable_notify(nlv);
	LOGIF(VARIABLE_CREATIONS, "Created non-library variable: $Z\n", nlv);

	return nlv;
}

@<Issue problem message for an indefinite variable@> =
	Problems::quote_wording(1, W);
	Problems::quote_kind(2, K);
	Problems::Issue::handmade_problem(_p_(PM_IndefiniteVariable));
	Problems::issue_problem_segment(
		"I am unable to create the variable '%1', because its kind (%2) is too "
		"vague. I need to know exactly what kind of value goes into each "
		"variable: for instance, it's not enough to say 'L is a list of values "
		"that varies', because I don't know what the entries have to be - 'L "
		"is a list of numbers that varies' would be better.");
	Problems::issue_problem_end();

@<Take note if the notable variables turn up here@> =
	if (<notable-variables>(W)) {
		switch (<<r>>) {
			case 0: i6_glob_VAR = nlv; break;
			case 1: i6_nothing_VAR = nlv; break;
			case 2: command_prompt_VAR = nlv; break;
		}
	}

@ Note that we only register the name of the variable as a meaning if it's
global, because it otherwise may mean different things in different places.
The knowledge about a variable is initially just that it is certainly a
variable; this means it inherits from the inference subject representing
all variables, and that in turn is good because it means it gets permission
to have the "initial value" property.

@<Actually create the nonlocal variable@> =
	nlv->var_documentation_symbol = Index::DocReferences::position_of_symbol(&W);
	nlv->name = W;
	nlv->nlv_created_at = current_sentence;
	nlv->nlv_kind = K;
	nlv->rvalue_nve.textual_form = Str::new(); /* we won't decide their run-time storage until later */
	nlv->rvalue_nve.iname_form = NULL;
	nlv->lvalue_nve.textual_form = Str::new();
	nlv->lvalue_nve.iname_form = NULL;
	nlv->housed_in_variables_array = FALSE;
	nlv->nlv_iname = NULL;
	nlv->nlv_name_translated = FALSE;
	nlv->alias_to_infs = NULL;
	nlv->nlv_write_schema = NULL;
	nlv->constant_at_run_time = FALSE;
	nlv->var_is_initialisable_anyway = FALSE;
	nlv->var_is_allowed_to_be_zero = FALSE;
	nlv->scope = scope;
	nlv->substitution_marker = 0;
	if ((Wordings::nonempty(W)) && (scope == NULL)) /* that is, if it's a global */
		Nouns::new_proper_noun(W, NEUTER_GENDER,
			REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
			VARIABLE_MC, Lvalues::new_actual_NONLOCAL_VARIABLE(nlv));
	nlv->nlv_knowledge =
		InferenceSubjects::new(nonlocal_variables,
			VARI_SUB, STORE_POINTER_nonlocal_variable(nlv), CERTAIN_CE);

@ So much for creation; and here's how we log them:

=
void NonlocalVariables::log(nonlocal_variable *nlv) {
	if (nlv== NULL) { LOG("<null variable>"); return; }
	LOG("'%W'(%s)[$u]", nlv->name,
		(nlv->constant_at_run_time)?"const":"var",
		nlv->nlv_kind);
}

@ It turns out to be convenient to have this routine around. Note that
parsing only picks up globals (see note on name registration above).

=
nonlocal_variable *NonlocalVariables::parse(wording W) {
	W = Articles::remove_the(W);
	if (<s-global-variable>(W)) {
		parse_node *val = <<rp>>;
		return ParseTree::get_constant_nonlocal_variable(val);
	}
	return NULL;
}

@ We need the flexibility to store the variable's value in a range of
different ways at run-time. One way this is used is to allow the source
text (generally the Standard Rules) to say that an already-existing I6
variable should hold it:

=
void NonlocalVariables::translates(wording W, parse_node *p2) {
	nonlocal_variable *nlv = NonlocalVariables::parse(W);
	if ((nlv == NULL) || (nlv->scope)) {
		LOG("Tried %W\n", W);
		Problems::Issue::sentence_problem(_p_(PM_NonQuantityTranslated),
			"this is not the name of a variable",
			"or at any rate not one global in scope.");
		return;
	}
	if (nlv->nlv_name_translated) {
		Problems::Issue::sentence_problem(_p_(PM_QuantityTranslatedAlready),
			"this variable has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	nlv->nlv_name_translated = TRUE;
	TEMPORARY_TEXT(name);
	WRITE_TO(name, "%N", Wordings::first_wn(ParseTree::get_text(p2)));
	inter_name *as_iname = Hierarchy::find_by_name(name);
	NonlocalVariables::set_I6_identifier(nlv, FALSE, NonlocalVariables::nve_from_iname(as_iname));
	NonlocalVariables::set_I6_identifier(nlv, TRUE, NonlocalVariables::nve_from_iname(as_iname));
	DISCARD_TEXT(name);
	LOGIF(VARIABLE_CREATIONS,
		"Translated variable: $Z as %N\n", nlv, Wordings::first_wn(ParseTree::get_text(p2)));
}

@ In general, the following allows us to set the R-value and L-value forms
of the variable's storage. An R-value is the form of the variable on the
right-hand side of an assignment, that is, when we're reading it; an L-value
is the form used when we're setting it. Often these will be the same, but
not always.

=
void NonlocalVariables::set_I6_identifier(nonlocal_variable *nlv, int left, nonlocal_variable_emission nve) {
	if (Str::len(nve.textual_form) > 30) internal_error("name too long");
	if (nlv == NULL) internal_error("null nlv");
	if (left) nlv->lvalue_nve = nve; else nlv->rvalue_nve = nve;
	nlv->housed_in_variables_array = FALSE;
}

nonlocal_variable_emission NonlocalVariables::new_nve(void) {
	nonlocal_variable_emission nve;
	nve.iname_form = NULL;
	nve.textual_form = Str::new();
	nve.stv_ID = -1;
	nve.stv_index = -1;
	nve.allow_outside = FALSE;
	nve.use_own_iname = FALSE;
	return nve;
}

nonlocal_variable_emission NonlocalVariables::nve_from_iname(inter_name *iname) {
	nonlocal_variable_emission nve = NonlocalVariables::new_nve();
	nve.iname_form = iname;
	WRITE_TO(nve.textual_form, "%n", iname);
	return nve;
}

nonlocal_variable_emission NonlocalVariables::nve_from_mstack(int N, int index, int allow_outside) {
	nonlocal_variable_emission nve = NonlocalVariables::new_nve();
	if (allow_outside)
		WRITE_TO(nve.textual_form, "(MStack-->MstVON(%d,%d))", N, index);
	else
		WRITE_TO(nve.textual_form, "(MStack-->MstVO(%d,%d))", N, index);
	nve.stv_ID = N;
	nve.stv_index = index;
	nve.allow_outside = allow_outside;
	return nve;
}

nonlocal_variable_emission NonlocalVariables::nve_from_pos(void) {
	nonlocal_variable_emission nve = NonlocalVariables::new_nve();
	nve.use_own_iname = TRUE;
	return nve;
}

@ Later, when we actually need to know where these are being stored, we assign
run-time locations to any variable without them:

=
text_stream *NonlocalVariables::identifier(nonlocal_variable *nlv) {
	if (Str::len(nlv->rvalue_nve.textual_form) == 0) NonlocalVariables::allocate_storage();
	if (Str::len(nlv->rvalue_nve.textual_form) == 0) @<Issue a missing meaning problem@>;
	return nlv->rvalue_nve.textual_form;
}

void NonlocalVariables::emit_lvalue(nonlocal_variable *nlv) {
	if (nlv->lvalue_nve.iname_form) {
		Emit::val_iname(K_value, nlv->lvalue_nve.iname_form);
	} else if (nlv->lvalue_nve.stv_ID >= 0) {
		Emit::inv_primitive(lookup_interp);
		Emit::down();
			Emit::val_iname(K_value, Hierarchy::find(MSTACK_HL));
			int ex = MSTVO_HL;
			if (nlv->lvalue_nve.allow_outside) ex = MSTVON_HL;
			Emit::inv_call_iname(Hierarchy::find(ex));
			Emit::down();
				Emit::val(K_number, LITERAL_IVAL, (inter_t) nlv->lvalue_nve.stv_ID);
				Emit::val(K_number, LITERAL_IVAL, (inter_t) nlv->lvalue_nve.stv_index);
			Emit::up();
		Emit::up();
	}  else if (nlv->lvalue_nve.use_own_iname) {
		Emit::val_iname(K_value, NonlocalVariables::iname(nlv));
	} else {
		internal_error("improperly formed nve");
	}
}

@<Issue a missing meaning problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, nlv->name);
	Problems::Issue::handmade_problem(_p_(BelievedImpossible));
	Problems::issue_problem_segment(
		"The sentence %1 seems to need the value '%2', but that currently "
		"has no definition.");
	Problems::issue_problem_end();
	return I"self";

@ And the allocation is done here. Variables not stored anywhere else are
marked to be housed in an array, though it's really up to the code-generator
tp make that decision:

=
void NonlocalVariables::allocate_storage(void) {
	nonlocal_variable *var;
	LOOP_OVER(var, nonlocal_variable)
		if (((Str::len(var->lvalue_nve.textual_form) == 0) || (Str::len(var->rvalue_nve.textual_form) == 0)) &&
			((var->constant_at_run_time == FALSE) || (var->var_is_bibliographic))) {
			NonlocalVariables::set_I6_identifier(var, FALSE, NonlocalVariables::nve_from_pos());
			NonlocalVariables::set_I6_identifier(var, TRUE, NonlocalVariables::nve_from_pos());
			var->housed_in_variables_array = TRUE;
		}
}

@ In extreme cases, even that flexibility isn't enough. For example, the
"location" variable is rigged so that changing it causes code in the I6
template to be called, because the world model must be kept consistent when
the player character moves room. So it's even possible to set an explicit
I6 schema for how to change a variable:

=
void NonlocalVariables::set_write_schema(nonlocal_variable *nlv, char *sch) {
	nlv->nlv_write_schema = sch;
}

char *NonlocalVariables::get_write_schema(nonlocal_variable *nlv) {
	NonlocalVariables::warn_about_change(nlv);
	if (nlv == NULL) return NULL;
	return nlv->nlv_write_schema;
}

void NonlocalVariables::warn_about_change(nonlocal_variable *nlv) {
	#ifdef IF_MODULE
	if (nlv == score_VAR) {
		if ((scoring_option_set == FALSE) || (scoring_option_set == NOT_APPLICABLE)) {
			Problems::Issue::sentence_problem(_p_(PM_CantChangeScore),
				"this is a story with no scoring",
				"so it makes no sense to change the 'score' value. You can add "
				"scoring to the story by including the sentence 'Use scoring.', "
				"in which case this problem message will go away; or you can "
				"remove it with 'Use no scoring.' (Until 2011, the default was "
				"to have scoring, but now it's not to have scoring.)");
		}
	}
	#endif
}

@ Here are the standard routines allowing NLVs to be inference subjects:
there's very little to say.

=
wording NonlocalVariables::SUBJ_get_name_text(inference_subject *from) {
	nonlocal_variable *nlv = InferenceSubjects::as_nlv(from);
	return nlv->name;
}

general_pointer NonlocalVariables::SUBJ_new_permission_granted(inference_subject *from) {
	return NULL_GENERAL_POINTER;
}

void NonlocalVariables::SUBJ_make_adj_const_domain(inference_subject *infs,
	instance *nc, property *prn) {
}

void NonlocalVariables::SUBJ_complete_model(inference_subject *infs) {
}

void NonlocalVariables::SUBJ_check_model(inference_subject *infs) {
}

int NonlocalVariables::SUBJ_emit_element_of_condition(inference_subject *infs, inter_symbol *t0_s) {
	internal_error("NLV in runtime match condition");
	return FALSE;
}

void NonlocalVariables::SUBJ_compile(inference_subject *infs) {
}

inference_subject *NonlocalVariables::get_knowledge(nonlocal_variable *nlv) {
	return nlv->nlv_knowledge;
}

@ The iname is created on demand:

=
inter_name *NonlocalVariables::iname(nonlocal_variable *nlv) {
	if (nlv->nlv_iname == NULL) {
		package_request *R = Hierarchy::package(Modules::find(nlv->nlv_created_at), VARIABLES_HAP);
		Hierarchy::markup_wording(R, VARIABLE_NAME_HMD, nlv->name);
		nlv->nlv_iname = Hierarchy::make_iname_with_memo(VARIABLE_HL, R, nlv->name);
	}
	return nlv->nlv_iname;
}

int NonlocalVariables::SUBJ_compile_all(void) {
	NonlocalVariables::allocate_storage(); /* in case this hasn't happened already */
	@<Verify that externally-stored nonlocals haven't been initialised@>;
	nonlocal_variable *nlv;
	LOOP_OVER(nlv, nonlocal_variable) {
		current_sentence = NonlocalVariables::origin_of_initial_value(nlv);
		if (NonlocalVariables::has_initial_value_set(nlv))
			Assertions::PropertyKnowledge::verify_global_variable(nlv);
	}
	LOOP_OVER(nlv, nonlocal_variable)
		if ((nlv->constant_at_run_time == FALSE) ||
			(nlv->housed_in_variables_array)) {

			BEGIN_COMPILATION_MODE;
			COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);

			inter_name *iname = NonlocalVariables::iname(nlv);
			inter_t v1 = 0, v2 = 0;

			NonlocalVariables::seek_initial_value(iname, &v1, &v2, nlv);

			END_COMPILATION_MODE;

			text_stream *rvalue = NULL;
			if (nlv->housed_in_variables_array == FALSE)
				rvalue = NonlocalVariables::identifier(nlv);
			Emit::variable(iname, nlv->nlv_kind, v1, v2, rvalue);
			if (nlv == command_prompt_VAR) {
				packaging_state save = Routines::begin(Hierarchy::find(COMMANDPROMPTTEXT_HL));
				Emit::inv_primitive(return_interp);
				Emit::down();
					Emit::val_iname(K_text, iname);
				Emit::up();
				Routines::end(save);
			}

		}
	return TRUE;
}

@ If a variable is said to be the same as, say, |my_var| defined in some
I6 code somewhere out of our reach, then it makes no sense to allow the
source text to specify its initial value -- the initial value is whatever
that faraway I6 code said it was.

@<Verify that externally-stored nonlocals haven't been initialised@> =
	nonlocal_variable *nlv;
	LOOP_OVER(nlv, nonlocal_variable)
		if ((nlv->housed_in_variables_array == FALSE) &&
			(nlv->var_is_initialisable_anyway == FALSE) &&
			(nlv->alias_to_infs == NULL) &&
			(NonlocalVariables::has_initial_value_set(nlv)))
			@<Issue a problem message for an impossible initialisation@>;

@<Issue a problem message for an impossible initialisation@> =
	current_sentence = NonlocalVariables::origin_of_initial_value(nlv);
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, nlv->name);
	Problems::quote_stream(3, nlv->lvalue_nve.textual_form);
	Problems::Issue::handmade_problem(_p_(PM_InaccessibleVariable));
	Problems::issue_problem_segment(
		"The sentence %1 tells me that '%2' has a specific initial value, "
		"but this is a variable which has been translated into an I6 'Global' "
		"called '%3' at the lowest level of Inform. Any initial value must be "
		"given in its I6 definition, not here.");
	Problems::issue_problem_end();

@ So, as we've seen, each variable is an inference subject. The initial knowledge
about it is that it's a variable, and as such, has permission to have the
"variable initial value" property. So:

=
parse_node *NonlocalVariables::get_initial_value(nonlocal_variable *nlv) {
	inference *inf;
	inference_subject *infs = NonlocalVariables::get_knowledge(nlv);
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF)
		if (World::Inferences::get_property(inf) == P_variable_initial_value)
			return World::Inferences::get_property_value(inf);
	return Specifications::new_UNKNOWN(EMPTY_WORDING);
}

parse_node *NonlocalVariables::origin_of_initial_value(nonlocal_variable *nlv) {
	inference *inf;
	inference_subject *infs = NonlocalVariables::get_knowledge(nlv);
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF)
		if (World::Inferences::get_property(inf) == P_variable_initial_value)
			return World::Inferences::where_inferred(inf);
	return NULL;
}

int NonlocalVariables::has_initial_value_set(nonlocal_variable *nlv) {
	if ((nlv) && (NonlocalVariables::origin_of_initial_value(nlv))) return TRUE;
	return FALSE;
}

void NonlocalVariables::allow_to_be_zero(nonlocal_variable *nlv) {
	nlv->var_is_allowed_to_be_zero = TRUE;
}

@ Now for some basic properties:

=
int NonlocalVariables::is_global(nonlocal_variable *nlv) {
	if (nlv->scope) return FALSE;
	return TRUE;
}

@ The kind can in fact be changed after creation, though this never happens
to variables declared in source text: it allows us to have a few globals which
are reused for different purposes and are typeless.

=
void NonlocalVariables::set_kind(nonlocal_variable *nlv, kind *K) {
	if (nlv == NULL) internal_error("set kind for null variable");
	nlv->nlv_kind = K;
}

kind *NonlocalVariables::kind(nonlocal_variable *nlv) {
	if (nlv == NULL) return NULL;
	return nlv->nlv_kind;
}

@ Here's an example of that kind-setting in action:

=
nonlocal_variable *NonlocalVariables::temporary_from_iname(inter_name *temp_iname, kind *K) {
	NonlocalVariables::set_I6_identifier(i6_glob_VAR, FALSE, NonlocalVariables::nve_from_iname(temp_iname));
	NonlocalVariables::set_I6_identifier(i6_glob_VAR, TRUE, NonlocalVariables::nve_from_iname(temp_iname));
	NonlocalVariables::set_kind(i6_glob_VAR, K);
	return i6_glob_VAR;
}

nonlocal_variable *NonlocalVariables::temporary_from_nve(nonlocal_variable_emission nve, kind *K) {
	NonlocalVariables::set_I6_identifier(i6_glob_VAR, FALSE, nve);
	NonlocalVariables::set_I6_identifier(i6_glob_VAR, TRUE, nve);
	NonlocalVariables::set_kind(i6_glob_VAR, K);
	return i6_glob_VAR;
}

int formal_par_vars_made = FALSE;
nonlocal_variable *formal_par_VAR[8];
nonlocal_variable *NonlocalVariables::temporary_formal(int i) {
	if (formal_par_vars_made == FALSE) {
		for (int i=0; i<8; i++) {
			formal_par_VAR[i] = NonlocalVariables::new(EMPTY_WORDING, K_object, NULL);
			inter_name *iname = NonlocalVariables::formal_par(i);
			formal_par_VAR[i]->nlv_iname = iname;
			NonlocalVariables::set_I6_identifier(formal_par_VAR[i], FALSE, NonlocalVariables::nve_from_iname(iname));
			NonlocalVariables::set_I6_identifier(formal_par_VAR[i], TRUE, NonlocalVariables::nve_from_iname(iname));
		}
		formal_par_vars_made = TRUE;
	}
	nonlocal_variable *nlv = formal_par_VAR[i];
	return nlv;
}

inter_name *NonlocalVariables::formal_par(int n) {
	switch (n) {
		case 0: return Hierarchy::find(formal_par0_HL);
		case 1: return Hierarchy::find(formal_par1_HL);
		case 2: return Hierarchy::find(formal_par2_HL);
		case 3: return Hierarchy::find(formal_par3_HL);
		case 4: return Hierarchy::find(formal_par4_HL);
		case 5: return Hierarchy::find(formal_par5_HL);
		case 6: return Hierarchy::find(formal_par6_HL);
		case 7: return Hierarchy::find(formal_par7_HL);
	}
	internal_error("bad formal par number");
	return NULL;
}

@ This is a curiosity, used to force the textual contents of a bibliographic
data variable (such as "story title") to be treated as text.

=
wording NonlocalVariables::treat_as_plain_text_word(nonlocal_variable *nlv) {
	inference *inf;
	inference_subject *infs = NonlocalVariables::get_knowledge(nlv);
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF)
		if (World::Inferences::get_property(inf) == P_variable_initial_value)
			return ParseTree::get_text(
				World::Inferences::set_property_value_kind(inf, K_text));
	return EMPTY_WORDING;
}

@ "Constant" means that no change is permitted at run-time; "initialisable"
means that a value can be set by an assertion in the source text.

=
void NonlocalVariables::make_constant(nonlocal_variable *nlv, int bib) {
	if (nlv == NULL) internal_error("no such var");
	nlv->constant_at_run_time = TRUE;
	nlv->var_is_initialisable_anyway = TRUE;
	nlv->var_is_bibliographic = bib;
}

void NonlocalVariables::make_initalisable(nonlocal_variable *nlv) {
	nlv->var_is_initialisable_anyway = TRUE;
}

int NonlocalVariables::is_constant(nonlocal_variable *nlv) {
	if (nlv == NULL) internal_error("no such var");
	return nlv->constant_at_run_time;
}

int NonlocalVariables::must_be_constant(nonlocal_variable *nlv) {
	if (nlv->constant_at_run_time) {
		Problems::Issue::sentence_problem(_p_(PM_CantChangeConstants),
			"this is a name for a value which never changes during the story",
			"so it can't be altered with 'now'.");
		return TRUE;
	}
	return FALSE;
}

@ Substitution is the process of replacing a constant variable with its value,
and leaving everything else alone.

=
int substitution_session_id = 0;
parse_node *NonlocalVariables::substitute_constants(parse_node *spec) {
	int depth = 0;
	substitution_session_id++;
	while (TRUE) {
		if (depth++ > 20) internal_error("ill-founded constants");
		nonlocal_variable *nlv = Lvalues::get_nonlocal_variable_if_any(spec);
		if ((nlv) && (nlv->constant_at_run_time)) {
			if (nlv->substitution_marker == substitution_session_id) {
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, nlv->name);
				Problems::quote_kind(3, nlv->nlv_kind);
				Problems::Issue::handmade_problem(_p_(PM_MeaningRecursive));
				Problems::issue_problem_segment(
					"The sentence %1 tells me that '%2', which should be %3 "
					"that varies, is to have an initial value which can't "
					"be worked out without going round in circles.");
				Problems::issue_problem_end();
				break;
			}
			nlv->substitution_marker = substitution_session_id;
			parse_node *sspec = NonlocalVariables::get_initial_value(nlv);
			if (ParseTree::is(sspec, UNKNOWN_NT) == FALSE) { spec = sspec; continue; }
		}
		break;
	}
	return spec;
}

@ From the point of view of computer science, aliasing is a terrible thing.
This is the ability to tie the name of a variable to that of something
else, and is motivated by the existence of nouns in English which are
neither quite proper nor common; "the player" in Inform is an example.

=
inference_subject *NonlocalVariables::get_alias(nonlocal_variable *nlv) {
	if (nlv) {
		parse_node *val = NonlocalVariables::get_initial_value(nlv);
		inference_subject *vals = InferenceSubjects::from_specification(val);
		if (vals) return vals;
		return nlv->alias_to_infs;
	}
	return NULL;
}

void NonlocalVariables::set_alias(nonlocal_variable *nlv, inference_subject *infs) {
	nlv->alias_to_infs = infs;
}

@ The following routine compiles the correct initial value for the given
variable. If it has no known initial value, it is given the initial
value for its kind where possible: note that this may not be possible
if the source text says something like

>> Thickness is a kind of value. The carpet nap is a thickness that varies.

without specifying any thicknesses: the set of legal thickness values
is empty, so the carpet nap variable cannot be created in a way
which makes its kind safe. Hence the error messages.

=
void NonlocalVariables::emit_initial_value(nonlocal_variable *nlv) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	NonlocalVariables::compile_initial_value_vh(&VH, nlv);
	inter_t v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	Emit::array_generic_entry(v1, v2);
}

void NonlocalVariables::emit_initial_value_as_val(nonlocal_variable *nlv) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	NonlocalVariables::compile_initial_value_vh(&VH, nlv);
	Holsters::to_val_mode(&VH);
}

void NonlocalVariables::seek_initial_value(inter_name *iname, inter_t *v1, inter_t *v2, nonlocal_variable *nlv) {
	ival_emission IE = Emit::begin_ival_emission(iname);
	NonlocalVariables::compile_initial_value_vh(Emit::ival_holster(&IE), nlv);
	Emit::end_ival_emission(&IE, v1, v2);
}

void NonlocalVariables::compile_initial_value_vh(value_holster *VH, nonlocal_variable *nlv) {
	parse_node *val =
		NonlocalVariables::substitute_constants(
			NonlocalVariables::get_initial_value(
				nlv));
	if (ParseTree::is(val, UNKNOWN_NT)) {
		current_sentence = nlv->nlv_created_at;
		@<Initialise with the default value of its kind@>
	} else {
		current_sentence = NonlocalVariables::origin_of_initial_value(nlv);
		if (Lvalues::get_storage_form(val) == NONLOCAL_VARIABLE_NT)
			@<Issue a problem for one variable set equal to another@>
		else Specifications::Compiler::compile_constant_to_kind_vh(VH, val, nlv->nlv_kind);
	}
}

@<Initialise with the default value of its kind@> =
	if (Kinds::RunTime::compile_default_value_vh(VH, nlv->nlv_kind, nlv->name, "variable") == FALSE) {
		if (nlv->var_is_allowed_to_be_zero) {
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		} else {
			wording W = Kinds::Behaviour::get_name(nlv->nlv_kind, FALSE);
			Problems::quote_wording(1, nlv->name);
			Problems::quote_wording(2, W);
			Problems::Issue::handmade_problem(_p_(PM_EmptyDataType));
			Problems::issue_problem_segment(
				"I am unable to put any value into the variable '%1', because "
				"%2 is a kind of value with no actual values.");
			Problems::issue_problem_end();
		}
	}

@<Issue a problem for one variable set equal to another@> =
	nonlocal_variable *the_other = ParseTree::get_constant_nonlocal_variable(val);
	if (the_other == NULL) internal_error(
		"Tried to compile initial value of variable as null variable");
	if (the_other == nlv) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, nlv->name);
		Problems::quote_kind(3, nlv->nlv_kind);
		Problems::Issue::handmade_problem(_p_(PM_InitialiseQ2));
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
		Problems::Issue::handmade_problem(_p_(PM_InitialiseQ1));
		Problems::issue_problem_segment(
			"The sentence %1 tells me that '%2', which should be %3 "
			"that varies, is to have an initial value equal to '%4', "
			"which in turn is %5 that varies. At the start of play, "
			"variable values have to be set equal to definite constants, "
			"so this is not allowed.");
		Problems::issue_problem_end();
	}

@ The index of all the global variables doesn't actually include all of them,
because there are "K understood" variables for every kind which can be
understood, and a list of those would be tediously repetitive -- it would
duplicate most of the list of base kinds. So the index shows just one such
variable. Inform recognises these variables by parsing their names against
the following:

=
<value-understood-variable-name> ::=
	<k-kind> understood

@ And here is the indexing code:

=
void NonlocalVariables::index_all(OUTPUT_STREAM) {
	nonlocal_variable *nlv;
	heading *definition_area, *current_area = NULL;
	HTML_OPEN("p");
	Index::anchor(OUT, I"NAMES");
	int understood_note_given = FALSE;
	LOOP_OVER(nlv, nonlocal_variable)
		if ((Wordings::first_wn(nlv->name) >= 0) && (NonlocalVariables::is_global(nlv))) {
			if (<value-understood-variable-name>(nlv->name))
				@<Index a K understood variable@>
			else
				@<Index a regular variable@>;
		}
	HTML_CLOSE("p");
}

@<Index a K understood variable@> =
	if (understood_note_given == FALSE) {
		understood_note_given = TRUE;
		WRITE("<i>kind</i> understood - <i>value</i>");
		HTML_TAG("br");
	}

@<Index a regular variable@> =
	definition_area = Sentences::Headings::of_wording(nlv->name);
	if (Sentences::Headings::indexed(definition_area) == FALSE) continue;
	if (definition_area != current_area) {
		wording W = Sentences::Headings::get_text(definition_area);
		HTML_CLOSE("p");
		HTML_OPEN("p");
		if (Wordings::nonempty(W)) Phrases::Index::index_definition_area(OUT, W, FALSE);
	}
	current_area = definition_area;
	NonlocalVariables::index_single(OUT, nlv);
	HTML_TAG("br");

@ =
void NonlocalVariables::index_single(OUTPUT_STREAM, nonlocal_variable *nlv) {
	WRITE("%+W", nlv->name);
	Index::link(OUT, Wordings::first_wn(nlv->name));
	if (Wordings::nonempty(nlv->var_documentation_symbol)) {
		TEMPORARY_TEXT(ixt);
		WRITE_TO(ixt, "%+W", Wordings::one_word(Wordings::first_wn(nlv->var_documentation_symbol)));
		Index::DocReferences::link(OUT, ixt);
		DISCARD_TEXT(ixt);
	}
	WRITE(" - <i>");
	Kinds::Textual::write(OUT, nlv->nlv_kind);
	WRITE("</i>");
}
