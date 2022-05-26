[NonlocalVariables::] Nonlocal Variables.

To manage variables whose scope is wider than the current rule.

@ The term "nonlocal variable" is less than elegant,[1] but it expresses a basic
truth -- that Inform, in contrast to C-like languages, has two different sorts
of variables:

(*) Local variables exist only in the current stack frame and therefore die
with it; assertions cannot declare their values; they are created with the
"let" phrase or similar, not by assertion sentences.
(*) Nonlocal variables, all of the others, exist across multiple stack frames,
and are longer-lived. We don't call these "global" because intermediate scopes
are also possible: rulebook, activity and action variables, for example, have
a limited scope and lifetime, but are nevertheless not local to any one rule.
These variables are created by assertion sentences.

These semantics are so different that it makes no compelling sense to try to
give them a common implementation inside the compiler; so, nonlocal variables
are handled below, but local variables have a different implementation at
//imperative: Local Variables//.

A pragmatic, but questionable,[2] implementation decision by Inform is that
names created as aliases for constant values are implemented as being variables
that happen not to vary.

Nonlocal variables are stored in all kinds of ways at run-time. See
//runtime: Variables// for more.

[1] At one time the term used here was "quantity", which sounded philosophical
and was too vague.

[2] Does it really make sense to regard named constants as being conceptually
closer to global variables than to literals such as |true| or |false|?

=
typedef struct nonlocal_variable {
	struct wording name; /* text of the name */
	struct kind *nlv_kind; /* what kind of value it holds */

	struct shared_variable *scope; /* where it exists, or |NULL| for everywhere */

	struct inference_subject *as_subject; /* so that assertions can discuss it... */
	struct inference_subject *alias_subject; /* ...or perhaps the thing it aliases */

	int constant_at_run_time; /* for instance, for "story title" */
	int substitution_marker; /* to prevent infinite regress when substituting */

	int var_is_bibliographic; /* one of the bibliographic constants set at the end */
	int var_is_allowed_to_be_zero; /* for an empty enumerated kind, despite non-safety */

	struct variable_compilation_data compilation_data;

	struct parse_node *nlv_created_at; /* sentence creating the variable */
	struct wording var_documentation_symbol; /* reference to manual, if any */

	CLASS_DEFINITION
} nonlocal_variable;

@ We can create a new variable provided we give its name, kind and scope.
When the scope isn't global, the variable is said to be "stacked", which is a
reference to how it's stored at run-time.

Note that we only register the name of the variable as a proper noun if it's
global and will live forever, because nouns are both of those things. Anyone
creating a shared variable will have to make their own arrangements to parse
the names of them.

=
nonlocal_variable *NonlocalVariables::new_global(wording W, kind *K) {
	PROTECTED_MODEL_PROCEDURE;
	nonlocal_variable *nlv = NonlocalVariables::new(W, K, NULL);
	if (Wordings::nonempty(nlv->name)) {
		Nouns::new_proper_noun(nlv->name, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			VARIABLE_MC, Lvalues::new_actual_NONLOCAL_VARIABLE(nlv),
			Task::language_of_syntax());
	}
	return nlv;
}

@ The following then parses for those nouns, and note that it therefore can
only match globals, since variables of lesser scope are not in the lexicon.

=
nonlocal_variable *NonlocalVariables::parse_global(wording W) {
	W = Articles::remove_the(W);
	if (<s-global-variable>(W)) {
		parse_node *val = <<rp>>;
		return Node::get_constant_nonlocal_variable(val);
	}
	return NULL;
}

@ We record the one most recently made:

=
nonlocal_variable *latest_nonlocal_variable = NULL;
nonlocal_variable *NonlocalVariables::get_latest(void) {
	return latest_nonlocal_variable;
}

nonlocal_variable *NonlocalVariables::new(wording W, kind *K, shared_variable *shv) {
	if (K == NULL) internal_error("created variable without kind");
	if (Kinds::Behaviour::definite(K) == FALSE) {
		if (Kinds::get_construct(K) == CON_phrase)
			@<Issue problem message for a phrase used before its kind is known@>
		else
			@<Issue problem message for an indefinite variable@>;
	}

	nonlocal_variable *nlv = CREATE(nonlocal_variable);
	latest_nonlocal_variable = nlv;
	nlv->var_documentation_symbol = DocReferences::position_of_symbol(&W);
	nlv->name = W;
	nlv->nlv_created_at = current_sentence;
	nlv->nlv_kind = K;
	nlv->alias_subject = NULL;
	nlv->constant_at_run_time = FALSE;
	nlv->var_is_allowed_to_be_zero = FALSE;
	nlv->scope = shv;
	nlv->substitution_marker = 0;
	nlv->as_subject = VariableSubjects::new(nlv);
	nlv->compilation_data = RTVariables::new_compilation_data();

	@<Notice a few special variables@>;
	PluginCalls::new_variable_notify(nlv);
	LOGIF(VARIABLE_CREATIONS, "Created nonlocal variable: $Z\n", nlv);

	return nlv;
}

@<Issue problem message for an indefinite variable@> =
	Problems::quote_wording(1, W);
	Problems::quote_kind(2, K);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_IndefiniteVariable));
	Problems::issue_problem_segment(
		"I am unable to create the variable '%1', because its kind (%2) is too "
		"vague. I need to know exactly what kind of value goes into each "
		"variable: for instance, it's not enough to say 'L is a list of values "
		"that varies', because I don't know what the entries have to be - 'L "
		"is a list of numbers that varies' would be better.");
	Problems::issue_problem_end();

@ This typically arises for timing reasons. At the time the variable has to be
created, and given a kind, the kind of the initial value has not been fully
determined. So |K| here will be something like |phrase value -> value|. If this
case arose often enough it might be worth refactoring everything, but it's
rarely occurring and has an easy workaround. So we will just give a fairly
helpful problem message:

@<Issue problem message for a phrase used before its kind is known@> =
	LOG("W = %W, Domain = %u\n", W, K);
	Problems::quote_wording(1, W);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_IndefiniteVariable2));
	Problems::issue_problem_segment(
		"I am unable to create '%1', because the text was too vague about what "
		"its kind should be - I can see it's a phrase, but not what kind of phrase. "
		"(You may be able to fix this by declaring the kind directly first. For "
		"example, rather than 'The magic word is initially my deluxe phrase.', "
		"something like 'The magic word is a phrase nothing -> nothing variable. "
		"The magic word is initially my deluxe phrase.')");
	Problems::issue_problem_end();

@ Four oddball cases have special behaviour:
(*) |Inter_nothing_VAR| is translated not to an Inter variable, but to the
Inter constant |nothing|.
(*) |temporary_global_VAR| is translated to an Inter global used as temporary
storage space, and which has no fixed kind. An author cannot access this
directly in source text.
(*) |parameter_object_VAR| is translated to an Inter global used during the
run of certain rulebooks, and which has no fixed kind. (This could have been
handled as a rulebook variable, but having it as a global is more efficient.)
(*) |command_prompt_VAR| is a quite ordinary Inform 7 variable, except that
it is compiled in an unusual way, to achieve backwards compatibility with
the code in //CommandParserKit//, which dates back to the era of Inform 1 to 6.

= (early code)
nonlocal_variable *temporary_global_VAR = NULL;
nonlocal_variable *Inter_nothing_VAR = NULL; /* the |nothing| constant */
nonlocal_variable *command_prompt_VAR = NULL; /* the command prompt text */
nonlocal_variable *parameter_object_VAR = NULL;

@ =
nonlocal_variable *NonlocalVariables::nothing_pseudo_variable(void) {
	return Inter_nothing_VAR;
}
nonlocal_variable *NonlocalVariables::command_prompt_variable(void) {
	return command_prompt_VAR;
}
nonlocal_variable *NonlocalVariables::parameter_object_variable(void) {
	return parameter_object_VAR;
}
nonlocal_variable *NonlocalVariables::temporary_global_variable(void) {
	return temporary_global_VAR;
}

@<Notice a few special variables@> =
	if (<notable-variables>(W)) {
		switch (<<r>>) {
			case 0: temporary_global_VAR = nlv; break;
			case 1: Inter_nothing_VAR = nlv; break;
			case 2: command_prompt_VAR = nlv; break;
			case 3: parameter_object_VAR = nlv; break;
		}
	}

@ Inform recognises these special variables by their English names:

=
<notable-variables> ::=
	i6-varying-global |
	i6-nothing-constant |
	command prompt |
	parameter-object

@ So much for creation; and here's how we log and write them:

=
void NonlocalVariables::log(nonlocal_variable *nlv) {
	NonlocalVariables::write(DL, nlv);
}

void NonlocalVariables::write(OUTPUT_STREAM, nonlocal_variable *nlv) {
	if (nlv == NULL) { WRITE("<null variable>"); return; }
	WRITE("'%W'(%s)", nlv->name, (nlv->constant_at_run_time)?"const":"var");
	Kinds::Textual::write(OUT, nlv->nlv_kind);
}

@ The author can demand with a "translates as" sentence that a given
variable is equivalent to an Inter variable supplied in some kit:

=
void NonlocalVariables::translates(wording W, parse_node *p2) {
	nonlocal_variable *nlv = NonlocalVariables::parse_global(W);
	if ((nlv == NULL) || (nlv->scope)) {
		LOG("Tried %W\n", W);
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_NonQuantityTranslated),
			"this is not the name of a variable",
			"or at any rate not one global in scope.");
		return;
	}
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%N", Wordings::first_wn(Node::get_text(p2)));
	RTVariables::identifier_translates(nlv, name);
	DISCARD_TEXT(name)
	LOGIF(VARIABLE_CREATIONS,
		"Translated variable: $Z as %N\n", nlv,
			Wordings::first_wn(Node::get_text(p2)));
}

@ Nonlocal variables are inference subjects in order that they can be given
initial values by inference: see //Variable Subjects// for more.

=
inference_subject *NonlocalVariables::to_subject(nonlocal_variable *nlv) {
	return nlv->as_subject;
}

@ Now for some basic properties:

=
int NonlocalVariables::is_global(nonlocal_variable *nlv) {
	if (nlv->scope) return FALSE;
	return TRUE;
}

kind *NonlocalVariables::kind(nonlocal_variable *nlv) {
	if (nlv == NULL) return NULL;
	return nlv->nlv_kind;
}

void NonlocalVariables::allow_to_be_zero(nonlocal_variable *nlv) {
	nlv->var_is_allowed_to_be_zero = TRUE;
}

@ The kind can in fact be changed after creation, though this never happens
to variables declared in source text: it allows us to have a few globals which
are reused for different purposes and are typeless.

=
void NonlocalVariables::set_kind(nonlocal_variable *nlv, kind *K) {
	if (nlv == NULL) internal_error("set kind for null variable");
	nlv->nlv_kind = K;
}

@ This is a curiosity, used to force the textual contents of a bibliographic
data variable (such as "story title") to be treated as text.

=
wording NonlocalVariables::initial_value_as_plain_text(nonlocal_variable *nlv) {
	inference *inf;
	inference_subject *infs = NonlocalVariables::to_subject(nlv);
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, property_inf)
		if (PropertyInferences::get_property(inf) == P_variable_initial_value)
			return Node::get_text(
				PropertyInferences::set_value_kind(inf, K_text));
	return EMPTY_WORDING;
}

@ "Constant" means that no change is permitted at run-time; "initialisable"
means that a value can be set by an assertion in the source text.

=
void NonlocalVariables::make_constant(nonlocal_variable *nlv, int bib) {
	if (nlv == NULL) internal_error("no such var");
	nlv->constant_at_run_time = TRUE;
	nlv->var_is_bibliographic = bib;
	RTVariables::make_initialisable(nlv);
}

int NonlocalVariables::is_constant(nonlocal_variable *nlv) {
	if (nlv == NULL) internal_error("no such var");
	return nlv->constant_at_run_time;
}

int NonlocalVariables::must_be_constant(nonlocal_variable *nlv) {
	if (nlv->constant_at_run_time) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantChangeConstants),
			"this is a name for a value which never changes during the story",
			"so it can't be altered with 'now'.");
		return TRUE;
	}
	return FALSE;
}

void NonlocalVariables::warn_about_change(nonlocal_variable *nlv) {
	if ((score_VAR) && (nlv == score_VAR)) {
		if ((global_compilation_settings.scoring_option_set == FALSE) ||
			(global_compilation_settings.scoring_option_set == NOT_APPLICABLE)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_CantChangeScore),
				"this is a story with no scoring",
				"so it makes no sense to change the 'score' value. You can add "
				"scoring to the story by including the sentence 'Use scoring.', "
				"in which case this problem message will go away; or you can "
				"remove it with 'Use no scoring.' (Until 2011, the default was "
				"to have scoring, but now it's not to have scoring.)");
		}
	}
}

@ Substitution is the down-side if handling constants as if they were variables.
At some point, the constant has to be replaced by its value, and this is where.
Note that it's easy to imagine a chain of constants defined each as being
equal to the next, but that a cycle of those is illegal.

=
int substitution_session_id = 0;
parse_node *NonlocalVariables::substitute_constants(parse_node *spec) {
	substitution_session_id++;
	while (TRUE) {
		nonlocal_variable *nlv = Lvalues::get_nonlocal_variable_if_any(spec);
		if ((nlv) && (nlv->constant_at_run_time)) {
			if (nlv->substitution_marker == substitution_session_id) {
				Problems::quote_source(1, nlv->nlv_created_at);
				Problems::quote_wording(2, nlv->name);
				Problems::quote_kind(3, nlv->nlv_kind);
				StandardProblems::handmade_problem(Task::syntax_tree(),
					_p_(PM_MeaningRecursive));
				Problems::issue_problem_segment(
					"The sentence %1 tells me that '%2', which should be %3 "
					"that varies, is to have an initial value which can't "
					"be worked out without going round in circles.");
				Problems::issue_problem_end();
				spec = Specifications::new_UNKNOWN(Node::get_text(spec));
				break;
			}
			nlv->substitution_marker = substitution_session_id;
			parse_node *sspec = VariableSubjects::get_initial_value(nlv);
			if (Node::is(sspec, UNKNOWN_NT) == FALSE) { spec = sspec; continue; }
		}
		break;
	}
	return spec;
}

@ "Aliasing" is the ability to divert inferences about a variable to
inferences about something else. Inform uses this for interactive fiction
projects with "the player"; authors tend to think "the player" is an instance
and they write assertions accordingly, but in fact it's a variable. Because
of this aliasing, however, an inference about "the player" is diverted to
become an inference about "yourself", the actual default player instance.

At present this is the only use made of aliasing.

=
inference_subject *NonlocalVariables::get_alias(nonlocal_variable *nlv) {
	if (nlv) {
		parse_node *val = VariableSubjects::get_initial_value(nlv);
		inference_subject *vals = InferenceSubjects::from_specification(val);
		if (vals) return vals;
		return nlv->alias_subject;
	}
	return NULL;
}

void NonlocalVariables::set_alias(nonlocal_variable *nlv, inference_subject *infs) {
	nlv->alias_subject = infs;
}
