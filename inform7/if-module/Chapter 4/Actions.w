[PL::Actions::] Actions.

To define, map to I6 and index individual actions.

@h Definitions.

@ An action is an impulse to do something within the model world, and which
may not be possible. Much of the work of designing an interactive fiction
consists in responding to the actions of the player, sometimes in ways
which the player expects, sometimes not. Design systems for interactive
fiction therefore need to provide flexible and convenient ways to discuss
actions.

An activity is by contrast something done by the run-time code during play:
for instance, printing the name of an object, or asking a disambiguation
question. These tasks must similarly be customisable by the designer, and
a system of rulebooks is used which parallels the treatment of actions.

@ Some fields of this structure reflect the history of NI, and of I6 for
that matter: in particular, very few actions if any now use an I6-library
defined verb routine, but the ability is kept against future need; and
the idea of a flexible number of parameters -- which I6 allowed, thus
parsing "listen" and "listen to the frog" as the same action, with
0 and 1 parameters respectively -- has been dropped in I7. (We use the
activities for selecting missing parameters instead.) So for now the minimum
and maximum below are always equal.

=
typedef struct action_name {
	struct noun *name; /* such as "taking action" */
	struct wording present_name; /* such as "drop" or "take" */
	struct wording past_name; /* such as "dropped" or "taken" */
	int it_optional; /* noun optional when describing the second noun? */
	int abbreviable; /* preposition optional when describing the second noun? */
	int translated;
	struct text_stream *translated_name;
	struct inter_name *an_base_iname; /* e.g., |Take| */
	struct inter_name *an_iname; /* e.g., |##Take| */
	struct inter_name *an_routine_iname; /* e.g., |TakeSub| */
	struct package_request *an_package;

	int out_of_world; /* action is declared as out of world? */
	int use_verb_routine_in_I6_library; /* rather than compiling our own? */

	struct rulebook *check_rules; /* rulebooks private to this action */
	struct rulebook *carry_out_rules;
	struct rulebook *report_rules;
	struct stacked_variable_owner *owned_by_an; /* action variables owned here */

	struct parse_node *designers_specification; /* where created */

	int requires_light; /* does this action require light to be carried out? */
	int min_parameters, max_parameters; /* in the range 0 to 2 */
	int noun_access; /* one of the possibilities below */
	int second_access;
	struct kind *noun_kind; /* if there is at least 1 parameter */
	struct kind *second_kind; /* if there are 2 parameters */

	struct grammar_line *list_with_action; /* list of grammar producing this */

	int an_specification_text_word; /* description used in index */
	int an_index_group; /* paragraph number it belongs to (1, 2, 3, ...) */

	MEMORY_MANAGEMENT
} action_name;

@

= (early code)
stacked_variable_owner_list *all_nonempty_stacked_action_vars = NULL;

@ One action has special rules, to accommodate the "nowhere" syntax:

=
action_name *going_action = NULL;
action_name *waiting_action = NULL;

@ The access possibilities for the noun and second noun are as follows.

@d UNRESTRICTED_ACCESS 0 /* question not meaningful, e.g. for a number */
@d IMPOSSIBLE_ACCESS 1 /* action doesn't take a noun, so no question of access */
@d DOESNT_REQUIRE_ACCESS 2 /* actor need not be able to touch this object */
@d REQUIRES_ACCESS 3 /* actor must be able to touch this object */
@d REQUIRES_POSSESSION 4 /* actor must be carrying this object */

@ |DESCRIPTION_OF_ACTION| is used in type-checking to represent gerunds: that
is, actions described by what appear to be participles but which are in
context nouns ("if taking something, ...").

|ACTION_NAME|. For those rare occasions where we need to identify the
basic underlying action but none of the nouns, etc., thereto. At run-time,
this stores as the I6 action number: e.g. |##Go| for the going action.

|STORED_ACTION| is just what it says it is: a stored action, which can be
tried later. This is a pointer value; see "StoredAction.i6t".

= (early code)
kind *K_description_of_action = NULL;

@ =
void PL::Actions::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_BASE_KIND_NOTIFY, PL::Actions::actions_new_base_kind_notify);
	PLUGIN_REGISTER(PLUGIN_COMPILE_CONSTANT, PL::Actions::actions_compile_constant);
	PLUGIN_REGISTER(PLUGIN_OFFERED_PROPERTY, PL::Actions::actions_offered_property);
	PLUGIN_REGISTER(PLUGIN_OFFERED_SPECIFICATION, PL::Actions::actions_offered_specification);
	PLUGIN_REGISTER(PLUGIN_TYPECHECK_EQUALITY, PL::Actions::actions_typecheck_equality);
	PLUGIN_REGISTER(PLUGIN_FORBID_SETTING, PL::Actions::actions_forbid_setting);

	Vocabulary::set_flags(Vocabulary::entry_for_text(L"doing"), ACTION_PARTICIPLE_MC);
	Vocabulary::set_flags(Vocabulary::entry_for_text(L"asking"), ACTION_PARTICIPLE_MC);
}

@ =
int PL::Actions::actions_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"ACTION_NAME_TY")) {
		K_action_name = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, L"DESCRIPTION_OF_ACTION_TY")) {
		K_description_of_action = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, L"STORED_ACTION_TY")) {
		K_stored_action = new_base; return TRUE;
	}
	return FALSE;
}

@ =
int PL::Actions::actions_compile_constant(value_holster *VH, kind *K, parse_node *spec) {
	if (Plugins::Manage::plugged_in(actions_plugin) == FALSE)
		internal_error("actions plugin inactive");
	if (Kinds::Compare::eq(K, K_action_name)) {
		action_name *an = Rvalues::to_action_name(spec);
		if (Holsters::data_acceptable(VH)) {
			inter_name *N = PL::Actions::iname(an);
			if (N) Emit::holster(VH, N);
		}
		return TRUE;
	}
	if (Kinds::Compare::eq(K, K_description_of_action)) {
		action_pattern *ap = ParseTree::get_constant_action_pattern(spec);
		PL::Actions::Patterns::compile_pattern_match(VH, *ap, FALSE);
		return TRUE;
	}
	if (Kinds::Compare::eq(K, K_stored_action)) {
		action_pattern *ap = ParseTree::get_constant_action_pattern(spec);
		if (TEST_COMPILATION_MODE(CONSTANT_CMODE))
			PL::Actions::Patterns::as_stored_action(VH, ap);
		else {
			PL::Actions::Patterns::emit_try(ap, TRUE);
		}
		return TRUE;
	}
	return FALSE;
}

int PL::Actions::actions_offered_property(kind *K, parse_node *owner, parse_node *what) {
	if (Kinds::Compare::eq(K, K_action_name)) {
		action_name *an = Rvalues::to_action_name(owner);
		if (an == NULL) internal_error("failed to extract action-name structure");
		if (traverse == 1) PL::Actions::an_add_variable(an, what);
		return TRUE;
	}
	return FALSE;
}

int PL::Actions::actions_offered_specification(parse_node *owner, wording W) {
	if (Rvalues::is_CONSTANT_of_kind(owner, K_action_name)) {
		PL::Actions::actions_set_specification_text(Rvalues::to_action_name(owner), Wordings::first_wn(W));
		return TRUE;
	}
	return FALSE;
}

@ A stored action can always be compared to a gerund: for instance,

>> if the current action is taking something...

=
int PL::Actions::actions_typecheck_equality(kind *K1, kind *K2) {
	if ((Kinds::Compare::eq(K1, K_stored_action)) &&
		(Kinds::Compare::eq(K2, K_description_of_action)))
		return TRUE;
	return FALSE;
}

@ It could be argued that this ought to be a typechecking rule, but it applies
only to setting true, so is here instead. The distinction is there because we
can check whether an action is "taking a container" (say) but can't set a
stored action equal to it, because it's too vague: what is the container to be
taken?

=
int PL::Actions::actions_forbid_setting(kind *K) {
	return FALSE;
}

@ The constructor function for action names divides them into two according
to their implementation. Some actions are fully implemented in I6, and do
not have the standard check/carry out/report rulebooks: others are full I7
actions. (As I7 has matured, more and more actions have moved from the
first category to the second.)

@ This is an action name which Inform provides special support for; it
recognises the English name when defined by the Standard Rules. (So there is no
need to translate this to other languages.)

=
<notable-actions> ::=
	waiting |
	going

@ When we want to refer to an action name as a noun, we can use this to
make that explicit: for instance, "taking" becomes "the taking action".

=
<action-name-construction> ::=
	... action

@ =
action_name *PL::Actions::act_new(wording W, int implemented_by_I7) {
	int make_ds = FALSE;
	action_name *an = CREATE(action_name);
	if (<notable-actions>(W)) {
		if ((<<r>> == 1) && (going_action == NULL)) going_action = an;
		if ((<<r>> == 0) && (waiting_action == NULL)) {
			waiting_action = an;
			make_ds = TRUE;
		}
	}
	an->present_name = W;
	an->past_name = PastParticiples::pasturise_wording(an->present_name);
	an->it_optional = TRUE;
	an->abbreviable = FALSE;
	an->translated = FALSE;
	an->translated_name = NULL;

	an->an_package = Hierarchy::local_package(ACTIONS_HAP);
	Hierarchy::markup_wording(an->an_package, ACTION_NAME_HMD, W);
	an->an_base_iname = NULL;
	an->use_verb_routine_in_I6_library = TRUE;
	an->check_rules = NULL;
	an->carry_out_rules = NULL;
	an->report_rules = NULL;
	an->requires_light = FALSE;
	an->noun_access = IMPOSSIBLE_ACCESS;
	an->second_access = IMPOSSIBLE_ACCESS;
	an->min_parameters = 0;
	an->max_parameters = 0;
	an->noun_kind = K_object;
	an->second_kind = K_object;
	an->designers_specification = NULL;
	an->list_with_action = NULL;
	an->out_of_world = FALSE;
	an->an_specification_text_word = -1;

	word_assemblage wa = Preform::Nonparsing::merge(<action-name-construction>, 0,
		WordAssemblages::from_wording(W));
	wording AW = WordAssemblages::to_wording(&wa);
	an->name = Nouns::new_proper_noun(AW, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		MISCELLANEOUS_MC, Rvalues::from_action_name(an));

	Vocabulary::set_flags(Lexer::word(Wordings::first_wn(W)), ACTION_PARTICIPLE_MC);

	Kinds::Behaviour::new_enumerated_value(K_action_name);

	LOGIF(ACTION_CREATIONS, "Created action: %W\n", W);

	if (implemented_by_I7) {
		an->use_verb_routine_in_I6_library = FALSE;

		feed_t id = Feeds::begin();
		Feeds::feed_text_expanding_strings(L"check");
		Feeds::feed_wording(an->present_name);
		wording W = Feeds::end(id);
		package_request *CR = Hierarchy::make_package_in(CHECK_RB_HL, an->an_package);
		an->check_rules =
			Rulebooks::new_automatic(W, K_action_name,
				NO_OUTCOME, TRUE, FALSE, FALSE, CR);
		Rulebooks::fragment_by_actions(an->check_rules, 1);

		id = Feeds::begin();
		Feeds::feed_text_expanding_strings(L"carry out");
		Feeds::feed_wording(an->present_name);
		W = Feeds::end(id);
		package_request *OR = Hierarchy::make_package_in(CARRY_OUT_RB_HL, an->an_package);
		an->carry_out_rules =
			Rulebooks::new_automatic(W, K_action_name,
				NO_OUTCOME, TRUE, FALSE, FALSE, OR);
		Rulebooks::fragment_by_actions(an->carry_out_rules, 2);

		id = Feeds::begin();
		Feeds::feed_text_expanding_strings(L"report");
		Feeds::feed_wording(an->present_name);
		W = Feeds::end(id);
		package_request *RR = Hierarchy::make_package_in(REPORT_RB_HL, an->an_package);
		an->report_rules =
			Rulebooks::new_automatic(W, K_action_name,
				NO_OUTCOME, TRUE, FALSE, FALSE, RR);
		Rulebooks::fragment_by_actions(an->report_rules, 1);

		an->owned_by_an = StackedVariables::new_owner(20000+an->allocation_id);
	} else {
		an->owned_by_an = NULL;
	}

	action_name *an2;
	LOOP_OVER(an2, action_name)
		if (an != an2)
			if (PL::Actions::action_names_overlap(an, an2)) {
				an->it_optional = FALSE;
				an2->it_optional = FALSE;
			}

	return an;
}

/* pointing at, pointing it at */

@ The "action pronoun" use of "it" is to be a placeholder in an action
name to indicate where a noun phrase should appear. Some actions apply to
only one noun: for instance, in

>> taking the box

the action name is "taking". Others apply to two nouns:

>> unlocking the blue door with the key

has action name "unlocking it with". Inform always places one noun phrase
after the action name, but if it sees <action-pronoun> in the action name
then it places a second noun phrase at that point. (Any accusative pronoun
will do: it doesn't have to be "it".)

=
<action-pronoun> ::=
	<accusative-pronoun>

@ =
int PL::Actions::action_names_overlap(action_name *an1, action_name *an2) {
	wording W = an1->present_name;
	wording XW = an2->present_name;
	for (int i = Wordings::first_wn(W), j = Wordings::first_wn(XW);
		(i <= Wordings::last_wn(W)) && (j <= Wordings::last_wn(XW));
		i++, j++) {
		if ((<action-pronoun>(Wordings::one_word(i))) && (compare_words(i+1, j))) return TRUE;
		if ((<action-pronoun>(Wordings::one_word(j))) && (compare_words(j+1, i))) return TRUE;
		if (compare_words(i, j) == FALSE) return FALSE;
	}
	return FALSE;
}

void PL::Actions::log(action_name *an) {
	if (an == NULL) LOG("<null-action-name>");
	else LOG("%W", an->present_name);
}

@ And the following matches an action name (with no substitution of noun
phrases: "unlocking the door with" won't match the unlocking action; only
"unlocking it with" will do that).

=
<action-name> internal {
	action_name *an;
	LOOP_OVER(an, action_name)
		if (Wordings::match(W, an->present_name)) {
			*XP = an;
			return TRUE;
		}
	LOOP_OVER(an, action_name)
		if (<action-optional-trailing-prepositions>(an->present_name)) {
			wording SHW = GET_RW(<action-optional-trailing-prepositions>, 1);
			if (Wordings::match(W, SHW)) {
				*XP = an;
				return TRUE;
			}
		}
	return FALSE;
}

@ However, <action-name> can also be made to match an action name without
a final preposition, if that preposition is on the following list. For
example, it allows "listening" to match the listening to action; this is
needed because of the almost unique status of "listening" in having an
optional noun. (Unabbreviated action names always win if there's an
ambiguity here: i.e., if there is a second action called just "listening",
then that's what "listening" will match.)

=
<action-optional-trailing-prepositions> ::=
	... to

@ =
action_name *PL::Actions::longest_null(wording W, int tense, int *excess) {
	action_name *an;
	LOOP_OVER(an, action_name)
		if (an->max_parameters == 0) {
			wording AW = (tense == IS_TENSE) ? (an->present_name) : (an->past_name);
			if (Wordings::starts_with(W, AW)) {
				*excess = Wordings::first_wn(W) + Wordings::length(AW);
				return an;
			}
		}
	return NULL;
}

int PL::Actions::it_optional(action_name *an) {
	return an->it_optional;
}

int PL::Actions::abbreviable(action_name *an) {
	return an->abbreviable;
}

text_stream *PL::Actions::identifier(action_name *an) {
	return Emit::to_text(PL::Actions::base_iname(an));
}

action_name *PL::Actions::Wait(void) {
	if (waiting_action == NULL) internal_error("wait action not ready");
	return waiting_action;
}

inter_name *PL::Actions::base_iname(action_name *an) {
	if (an->an_base_iname == NULL) {
		if (waiting_action == an)
			an->an_base_iname = Hierarchy::make_iname_in(WAIT_HL, an->an_package);
		else if (Str::len(an->translated_name) > 0)
			an->an_base_iname = Hierarchy::make_iname_with_specific_name(TRANSLATED_BASE_NAME_HL, an->translated_name, an->an_package);
		else
			an->an_base_iname = Hierarchy::make_iname_with_memo(ACTION_BASE_NAME_HL, an->an_package, an->present_name);
	}
	return an->an_base_iname;
}

inter_name *PL::Actions::double_sharp(action_name *an) {
	if (an->an_iname == NULL) {
		an->an_iname = Hierarchy::derive_iname_in(DOUBLE_SHARP_NAME_HL, PL::Actions::base_iname(an), an->an_package);
		Emit::ds_named_pseudo_numeric_constant(an->an_iname, K_value, (inter_t) an->allocation_id);
		Hierarchy::make_available(Produce::tree(), an->an_iname);
		Produce::annotate_i(an->an_iname, ACTION_IANN, 1);
	}
	return an->an_iname;
}

inter_name *PL::Actions::Sub(action_name *an) {
	if (an->an_routine_iname == NULL) {
		an->an_routine_iname = Hierarchy::derive_iname_in(PERFORM_FN_HL, PL::Actions::base_iname(an), an->an_package);
		Hierarchy::make_available(Produce::tree(), an->an_routine_iname);
	}
	return an->an_routine_iname;
}

inter_name *PL::Actions::iname(action_name *an) {
	return PL::Actions::double_sharp(an);
}

rulebook *PL::Actions::get_fragmented_rulebook(action_name *an, rulebook *rb) {
	if (rb == built_in_rulebooks[CHECK_RB]) return an->check_rules;
	if (rb == built_in_rulebooks[CARRY_OUT_RB]) return an->carry_out_rules;
	if (rb == built_in_rulebooks[REPORT_RB]) return an->report_rules;
	internal_error("asked for peculiar fragmented rulebook"); return NULL;
}

rulebook *PL::Actions::switch_fragmented_rulebook(action_name *new_an, rulebook *orig) {
	action_name *an;
	if (new_an == NULL) return orig;
	LOOP_OVER(an, action_name) {
		if (orig == an->check_rules) return new_an->check_rules;
		if (orig == an->carry_out_rules) return new_an->carry_out_rules;
		if (orig == an->report_rules) return new_an->report_rules;
	}
	return orig;
}

void PL::Actions::actions_set_specification_text(action_name *an, int wn) {
	an->an_specification_text_word = wn;
}
int PL::Actions::an_get_specification_text(action_name *an) {
	return an->an_specification_text_word;
}

@ Most actions are given automatically generated Inform 6 names in the
compiled code: |Q4_green|, for instance. A few must however correspond to
names of significance in the I6 library.

=
void PL::Actions::name_all(void) {
}

void PL::Actions::translates(wording W, parse_node *p2) {
	action_name *an = NULL;
	if (<action-name>(W)) an = <<rp>>;
	else {
		LOG("Tried action name %W\n", W);
		Problems::Issue::sentence_problem(_p_(PM_TranslatesNonAction),
			"this does not appear to be the name of an action",
			"so cannot be translated into I6 at all.");
		return;
	}
	if (an->translated) {
		LOG("Tried action name %W = %n\n", W, PL::Actions::base_iname(an));
		Problems::Issue::sentence_problem(_p_(PM_TranslatesActionAlready),
			"this action has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	if (an->an_base_iname) internal_error("too late for action base name translation");

	an->translated = TRUE;
	an->translated_name = Str::new();
	WRITE_TO(an->translated_name, "%N", Wordings::first_wn(ParseTree::get_text(p2)));
	LOGIF(ACTION_CREATIONS, "Translated action: $l as %n\n", an, PL::Actions::base_iname(an));
}

int PL::Actions::get_stem_length(action_name *an) {
	if (Wordings::empty(an->present_name)) return 0; /* should never happen */
	int s = 0;
	LOOP_THROUGH_WORDING(k, an->present_name)
		if (!(<action-pronoun>(Wordings::one_word(k))))
			s++;
	return s;
}

@h Action variables.
Action variables can optionally be marked as able to extend the grammar of
action patterns. For example, the Standard Rules define:

>> The exiting action has an object called the container exited from (matched as "from").

and this allows "exiting from the cage", say, as an action pattern.

=
<action-variable> ::=
	<action-variable-name> ( matched as {<quoted-text-without-subs>} ) |	==> TRUE
	<action-variable-name> ( ... ) |						==> @<Issue PM_BadMatchingSyntax problem@>
	<action-variable-name>									==> FALSE

@ And the new action variable name is vetted by being run through this:

=
<action-variable-name> ::=
	<unfortunate-name> |									==> @<Issue PM_ActionVarAnd problem@>
	...														==> TRUE

@<Issue PM_BadMatchingSyntax problem@> =
	*X = NOT_APPLICABLE;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_BadMatchingSyntax));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for an action - a value associated "
		"with a action and which has a name. The request seems to "
		"say in parentheses that the name in question is '%2', but "
		"I only recognise the form '(matched as \"some text\")' here.");
	Problems::issue_problem_end();

@<Issue PM_ActionVarAnd problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_ActionVarAnd));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for an action - a value associated "
		"with a action and which has a name. The request seems to "
		"say that the name in question is '%2', but I'd prefer to "
		"avoid 'and', 'or', 'with', or 'having' in such names, please.");
	Problems::issue_problem_end();

@ =
void PL::Actions::an_add_variable(action_name *an, parse_node *cnode) {
	wording MW = EMPTY_WORDING, NW = EMPTY_WORDING;
	stacked_variable *stv = NULL;

	if (ParseTree::get_type(cnode) != PROPERTYCALLED_NT) {
		Problems::quote_source(1, current_sentence);
		Problems::Issue::handmade_problem(_p_(PM_ActionVarUncalled));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for an action - a value associated "
			"with a action and which has a name. But since you only give "
			"a kind, not a name, I'm stuck. ('The taking action has a "
			"number called tenacity' is right, 'The taking action has a "
			"number' is too vague.)");
		Problems::issue_problem_end();
		return;
	}

	if (an->owned_by_an == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(cnode->down->next));
		Problems::Issue::handmade_problem(_p_(Untestable)); /* since we no longer define such actions */
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for an action - a value associated "
			"with a action and which has a name. But this is a low-level "
			"action implemented internally by the Inform 6 library, and "
			"I am unable to give it any variables. Sorry.");
		Problems::issue_problem_end();
		return;
	}

	NW = ParseTree::get_text(cnode->down->next);

	if (<action-variable>(ParseTree::get_text(cnode->down->next))) {
		if (<<r>> == NOT_APPLICABLE) return;
		NW = GET_RW(<action-variable-name>, 1);
		if (<<r>>) {
			MW = GET_RW(<action-variable>, 1);
			int wn = Wordings::first_wn(MW);
			Word::dequote(wn);
			MW = Feeds::feed_text(Lexer::word_text(wn));
			if (Wordings::length(MW) > 1) {
				Problems::quote_source(1, current_sentence);
				Problems::quote_wording(2, MW);
				Problems::Issue::handmade_problem(_p_(PM_MatchedAsTooLong));
				Problems::issue_problem_segment(
					"You wrote %1, which I am reading as a request to make "
					"a new named variable for an action - a value associated "
					"with a action and which has a name. You say that it should "
					"be '(matched as \"%2\")', but I can only recognise such "
					"matches when a single keyword is used to introduce the "
					"clause, and this is more than one word.");
				Problems::issue_problem_end();
				return;
			}
		}
	}

	kind *K = NULL;
	if (<k-kind>(ParseTree::get_text(cnode->down))) K = <<rp>>;
	else {
		parse_node *spec = NULL;
		if (<s-type-expression>(ParseTree::get_text(cnode->down))) spec = <<rp>>;
		if (Specifications::is_description(spec)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, ParseTree::get_text(cnode->down));
			Problems::Issue::handmade_problem(_p_(PM_ActionVarOverspecific));
			Problems::issue_problem_segment(
				"You wrote %1, which I am reading as a request to make "
				"a new named variable for an action - a value associated "
				"with a action and which has a name. The request seems to "
				"say that the value in question is '%2', but this is too "
				"specific a description. (Instead, a kind of value "
				"(such as 'number') or a kind of object (such as 'room' "
				"or 'thing') should be given. To get a property whose "
				"contents can be any kind of object, use 'object'.)");
			Problems::issue_problem_end();
		} else {
			LOG("Offending SP: $T", spec);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, ParseTree::get_text(cnode->down));
			Problems::Issue::handmade_problem(_p_(PM_ActionVarUnknownKOV));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is not the name of a kind of "
				"value which I know (such as 'number' or 'text').");
			Problems::issue_problem_end();
		}
		return;
	}

	if (Kinds::Compare::eq(K, K_value)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(cnode->down));
		Problems::Issue::handmade_problem(_p_(PM_ActionVarValue));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a variable is a 'value' "
			"does not give me a clear enough idea what it will hold. "
			"You need to say what kind of value: for instance, 'A door "
			"has a number called street address.' is allowed because "
			"'number' is specific about the kind of value.");
		Problems::issue_problem_end();
		return;
	}

	if (StackedVariables::owner_empty(an->owned_by_an)) {
		all_nonempty_stacked_action_vars =
			StackedVariables::add_owner_to_list(all_nonempty_stacked_action_vars, an->owned_by_an);
	}

	stv = StackedVariables::add_empty(an->owned_by_an, NW, K);

	LOGIF(ACTION_CREATIONS, "Created action variable for $l: %W ($u)\n",
		an, ParseTree::get_text(cnode->down->next), K);

	if (Wordings::nonempty(MW)) {
		StackedVariables::set_matching_text(stv, MW);
		LOGIF(ACTION_CREATIONS, "Match with text: %W + SP\n", MW);
	}
}

stacked_variable *PL::Actions::parse_match_clause(action_name *an, wording W) {
	return StackedVariables::parse_match_clause(an->owned_by_an, W);
}

void PL::Actions::compile_action_name_var_creators(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		if ((an->owned_by_an) &&
			(StackedVariables::owner_empty(an->owned_by_an) == FALSE)) {
			inter_name *iname = Hierarchy::make_iname_in(ACTION_STV_CREATOR_FN_HL, an->an_package);
			StackedVariables::compile_frame_creator(an->owned_by_an, iname);
		}
	}
}

@ This handles the special meaning "X is an action...".

=
<new-action-sentence-object> ::=
	<indefinite-article> <new-action-sentence-object-unarticled> |	==> R[2]; *XP = RP[2]
	<new-action-sentence-object-unarticled>							==> R[1]; *XP = RP[1]

<new-action-sentence-object-unarticled> ::=
	action <nounphrase-actionable> |	==> TRUE; *XP = RP[1]
	action								==> @<Issue PM_BadActionDeclaration problem@>

@<Issue PM_BadActionDeclaration problem@> =
	*X = FALSE; *XP = NULL;
	Problems::Issue::assertion_problem(_p_(PM_BadActionDeclaration),
		"it is not sufficient to say that something is an 'action'",
		"without giving the necessary details: for example, 'Unclamping "
		"is an action applying to one thing.'");

@ =
int PL::Actions::new_action_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Taking something is an action." */
		case ACCEPT_SMFT:
			if (<new-action-sentence-object>(OW)) {
				if (<<r>> == FALSE) return FALSE;
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				parse_node *O = <<rp>>;
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
			PL::Actions::act_parse_definition(V);
			break;
	}
	return FALSE;
}

@

@d OOW_ACT_CLAUSE 1
@d PP_ACT_CLAUSE 2
@d APPLYING_ACT_CLAUSE 3
@d LIGHT_ACT_CLAUSE 4
@d ABBREV_ACT_CLAUSE 5

=
action_name *an_being_parsed = NULL;

@ We now come to a quite difficult sentence to parse: the declaration of a
new action.

>> Inserting it into is an action applying to two things.
>> Verifying the story file is an action out of world and applying to nothing.

The subject noun phrase needs little further parsing -- it's the name of the
action to be created.

=
<action-sentence-subject> ::=
	<action-name> |				==> @<Issue PM_ActionAlreadyExists problem@>
	...							==> 0; *XP = PL::Actions::act_new(W, TRUE);

@<Issue PM_ActionAlreadyExists problem@> =
	*XP = NULL;
	Problems::Issue::sentence_problem(_p_(PM_ActionAlreadyExists),
		"that seems to be an action already existing",
		"so it cannot be redefined now. If you would like to reconfigure "
		"an action in the standard set - for instance if you prefer "
		"'unlocking' to apply to only one thing, not two - create a new "
		"action for what you need ('keyless unlocking', perhaps) and then "
		"change the grammar to use the new action rather than the old "
		"('Understand \"unlock [something]\" as keyless unlocking.').");

@ The object NP is trickier, because it is a sequence
of "action clauses" which can occur in any order, which are allowed but
not required to be delimited as a list, and which can inconveniently
contain the word "and"; not only that, but note that in

>> applying to one thing and one number

the initial text "applying to one thing" would be valid as it stands.
It's convenient to define a single action clause first:

=
<action-clause> ::=
	out of world |							==> OOW_ACT_CLAUSE
	abbreviable |							==> ABBREV_ACT_CLAUSE
	with past participle ... |				==> PP_ACT_CLAUSE
	applying to <action-applications> |		==> APPLYING_ACT_CLAUSE; <<num>> = R[1]
	requiring light							==> LIGHT_ACT_CLAUSE

<action-applications> ::=
	nothing |							==> 0
	one <act-req> and one <act-req> |	==> 2; <<kind:op1>> = RP[1]; <<ac1>> = R[1]; <<kind:op2>> = RP[2]; <<ac2>> = R[2]
	one <act-req> and <act-req> |		==> 2; <<kind:op1>> = RP[1]; <<ac1>> = R[1]; <<kind:op2>> = RP[2]; <<ac2>> = R[2]
	<act-req> and one <act-req> |		==> 2; <<kind:op1>> = RP[1]; <<ac1>> = R[1]; <<kind:op2>> = RP[2]; <<ac2>> = R[2]
	<act-req> and <act-req> |			==> 2; <<kind:op1>> = RP[1]; <<ac1>> = R[1]; <<kind:op2>> = RP[2]; <<ac2>> = R[2]
	nothing or one <act-req> |			==> -1; <<kind:op1>> = RP[1]; <<ac1>> = R[1]
	one <act-req> |						==> 1; <<kind:op1>> = RP[1]; <<ac1>> = R[1]
	two <act-req>	|					==> 2; <<kind:op1>> = RP[1]; <<ac1>> = R[1]; <<kind:op2>> = RP[1]; <<ac2>> = R[1]
	<act-req> |							==> 1; <<kind:op1>> = RP[1]; <<ac1>> = R[1]
	...									==> @<Issue PM_ActionMisapplied problem@>;

<act-req> ::=
	<action-access> <k-kind> | 			==> R[1]; *XP = RP[2]; @<Check action kind@>;
	<k-kind>							==> UNRESTRICTED_ACCESS; *XP = RP[1]; @<Check action kind@>;

<action-access> ::=
	visible |			==> DOESNT_REQUIRE_ACCESS
	touchable |			==> REQUIRES_ACCESS
	carried				==> REQUIRES_POSSESSION

@ We are now able to define this peculiar form of list of action clauses:

=
<action-sentence-object> ::=
	<action-clauses> |							==> 0
	...											==> @<Issue PM_ActionClauseUnknown problem@>

<action-clauses> ::=
	... |										==> 0; return preform_lookahead_mode; /* match only on lookahead */
	<action-clauses> <action-clause-terminated> |		==> R[2]; @<Act on this action information@>
	<action-clause-terminated>					==> R[1]; @<Act on this action information@>

<action-clause-terminated> ::=
	<action-clause> , and |						==> R[1]
	<action-clause> and |						==> R[1]
	<action-clause> , |							==> R[1]
	<action-clause>								==> R[1]

@<Issue PM_ActionClauseUnknown problem@> =
	Problems::Issue::sentence_problem(_p_(PM_ActionClauseUnknown),
		"the action definition contained text I couldn't follow",
		"and may be too complicated.");

@<Act on this action information@> =
	switch (*X) {
		case OOW_ACT_CLAUSE:
			an_being_parsed->out_of_world = TRUE; break;
		case PP_ACT_CLAUSE: {
			wording C = GET_RW(<action-clause>, 1);
			if (Wordings::length(C) != 1)
				Problems::Issue::sentence_problem(_p_(PM_MultiwordPastParticiple),
					"a past participle must be given as a single word",
					"even if the action name itself is longer than that. "
					"(For instance, the action name 'hanging around until' "
					"should have past participle given just as 'hung'; I "
					"can already deduce the rest.)");
			an_being_parsed->past_name =
				PL::Actions::set_past_participle(an_being_parsed->past_name,
					Wordings::last_wn(C));
			break;
		}
		case APPLYING_ACT_CLAUSE:
			an_being_parsed->noun_access = <<ac1>>; an_being_parsed->second_access = <<ac2>>;
			an_being_parsed->noun_kind = <<kind:op1>>; an_being_parsed->second_kind = <<kind:op2>>;
			an_being_parsed->min_parameters = <<num>>;
			an_being_parsed->max_parameters = an_being_parsed->min_parameters;
			if (an_being_parsed->min_parameters == -1) {
				an_being_parsed->min_parameters = 0;
				an_being_parsed->max_parameters = 1;
			}
			break;
		case LIGHT_ACT_CLAUSE:
			an_being_parsed->requires_light = TRUE;
			break;
		case ABBREV_ACT_CLAUSE:
			an_being_parsed->abbreviable = TRUE;
			break;
	}

@<Check action kind@> =
	if (Kinds::Compare::eq(*XP, K_thing)) {
		if (*X == UNRESTRICTED_ACCESS) *X = REQUIRES_ACCESS;
		*XP = K_object;
	} else if (Kinds::Compare::lt(*XP, K_object)) {
		@<Issue PM_ActionMisapplied problem@>;
	} else {
		if (*X != UNRESTRICTED_ACCESS) @<Issue PM_ActionMisapplied problem@>;
	}

@<Issue PM_ActionMisapplied problem@> =
	*X = REQUIRES_ACCESS; *XP = K_thing;
	Problems::Issue::sentence_problem(_p_(PM_ActionMisapplied),
		"an action can only apply to things or to kinds of value",
		"for instance: 'photographing is an action applying to "
		"one visible thing'.");

@ =
wording PL::Actions::set_past_participle(wording W, int irregular_pp) {
	feed_t id = Feeds::begin();
	Feeds::feed_wording(Wordings::one_word(irregular_pp));
	if (Wordings::length(W) > 1)
		Feeds::feed_wording(Wordings::trim_first_word(W));
	return Feeds::end(id);
}

@ =
void PL::Actions::act_parse_definition(parse_node *p) {
	<action-sentence-subject>(ParseTree::get_text(p->next));
	action_name *an = <<rp>>;
	if (an == NULL) return;

	if (p->next->next) {
		an->designers_specification = p->next->next;

		an_being_parsed = an;
		<<ac1>> = IMPOSSIBLE_ACCESS;
		<<ac2>> = IMPOSSIBLE_ACCESS;
		<<kind:op1>> = K_object;
		<<kind:op2>> = K_object;
		<<num>> = 0;

		<action-sentence-object>(ParseTree::get_text(p->next->next));
	}

	if (an->max_parameters >= 2) {
		if ((Kinds::Compare::le(an->noun_kind, K_object) == FALSE) &&
			(Kinds::Compare::le(an->second_kind, K_object) == FALSE)) {
			Problems::Issue::sentence_problem(_p_(PM_ActionBothValues),
				"this action definition asks to have a single action apply "
				"to two different things which are not objects",
				"and unfortunately a fundamental restriction is that an "
				"action can apply to two objects, or one object and one "
				"value, but not to two values. Sorry about that.");
			return;
		}
	}
}

int PL::Actions::is_out_of_world(action_name *an) {
	if (an->out_of_world) return TRUE;
	return FALSE;
}

kind *PL::Actions::get_data_type_of_noun(action_name *an) {
	return an->noun_kind;
}

kind *PL::Actions::get_data_type_of_second_noun(action_name *an) {
	return an->second_kind;
}

wording PL::Actions::set_text_to_name_tensed(action_name *an, int tense) {
	if (tense == HASBEEN_TENSE) return an->past_name;
	return an->present_name;
}

int PL::Actions::can_have_parameters(action_name *an) {
	if (an->max_parameters > 0) return TRUE;
	return FALSE;
}

int PL::Actions::get_max_parameters(action_name *an) {
	return an->max_parameters;
}

int PL::Actions::get_min_parameters(action_name *an) {
	return an->min_parameters;
}

@h Past tense.
Simpler actions -- those with no parameter, or a single parameter which is
a thing -- can be tested in the past tense. The run-time support for this
is a general bitmap revealing which actions have ever happened, plus a
bitmap for each object revealing which have ever been applied to the object
in question. This is where we compile the bitmaps in their fresh, empty form.

=
int PL::Actions::can_be_compiled_in_past_tense(action_name *an) {
	if (an->min_parameters > 1) return FALSE;
	if (an->max_parameters > 1) return FALSE;
	if ((an->max_parameters == 1) &&
		(Kinds::Compare::le(an->noun_kind, K_object) == FALSE))
			return FALSE;
	return TRUE;
}

inter_name *PL::Actions::compile_action_bitmap_property(instance *I) {
	package_request *R = NULL;
	inter_name *N = NULL;
	if (I) {
		R = Instances::package(I);
		package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, R);
		N = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	} else {
		R = Kinds::Behaviour::package(K_object);
		package_request *PR = Hierarchy::package_within(KIND_INLINE_PROPERTIES_HAP, R);
		N = Hierarchy::make_iname_in(KIND_INLINE_PROPERTY_HL, PR);
	}
	packaging_state save = Emit::named_array_begin(N, K_number);
	for (int i=0; i<=((NUMBER_CREATED(action_name))/16); i++) Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Produce::annotate_i(N, INLINE_ARRAY_IANN, 1);
	return N;
}

void PL::Actions::ActionHappened(void) {
	inter_name *iname = Hierarchy::find(ACTIONHAPPENED_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	for (int i=0; i<=((NUMBER_CREATED(action_name))/16); i++)
		Emit::array_numeric_entry(0);
	Emit::array_end(save);
}

@h The grammar list.

=
void PL::Actions::add_gl(action_name *an, grammar_line *gl) {
	if (an->list_with_action == NULL) an->list_with_action = gl;
	else PL::Parsing::Lines::list_with_action_add(an->list_with_action, gl);
}

void PL::Actions::remove_gl(action_name *an) {
	an->list_with_action = NULL;
}

@h Typechecking grammar for an action.

=
void PL::Actions::check_types_for_grammar(action_name *an, int tok_values,
	kind **tok_value_kinds) {
	int required = 0; char *failed_on = "<internal error>";

	if (an->noun_access != IMPOSSIBLE_ACCESS)
		required++;
	if (an->second_access != IMPOSSIBLE_ACCESS)
		required++;
	if (required < tok_values) {
		switch(required) {
			case 0:
				failed_on =
					"this action applies to nothing, but you have provided "
					"material in square brackets which expands to something";
				break;
			case 1:
				failed_on =
					"this action applies to just one thing, but you have "
					"put more than one thing in square brackets";
				break;
			default:
				failed_on =
					"this action applies to two things, the maximum possible, "
					"but you have put more than two in square brackets";
				break;
		}
		goto Unmatched;
	}

	if (tok_values >= 1) {
		switch(an->noun_access) {
			case UNRESTRICTED_ACCESS: {
				kind *supplied_data_type = tok_value_kinds[0];
				kind *desired_data_type = an->noun_kind;
				if (Kinds::Compare::compatible(supplied_data_type, desired_data_type)
					!= ALWAYS_MATCH) {
					failed_on =
						"the thing you suggest this action should act on "
						"has the wrong kind of value";
					goto Unmatched;
				}
				break;
			}
			case REQUIRES_ACCESS:
			case REQUIRES_POSSESSION:
			case DOESNT_REQUIRE_ACCESS:
				if (Kinds::Compare::le(tok_value_kinds[0], K_object) == FALSE) {
					failed_on =
						"the thing you suggest this action should act on "
						"is not an object at all";
					goto Unmatched;
				}
				break;
		}
	}
	if (tok_values == 2) {
		switch(an->second_access) {
			case UNRESTRICTED_ACCESS: {
				kind *supplied_data_type = tok_value_kinds[1];
				kind *desired_data_type = an->second_kind;
				if (Kinds::Compare::compatible(supplied_data_type, desired_data_type)
					!= ALWAYS_MATCH) {
					failed_on =
						"the second thing you suggest this action should act on "
						"has the wrong kind of value";
					goto Unmatched;
				}
				break;
			}
			case REQUIRES_ACCESS:
			case REQUIRES_POSSESSION:
			case DOESNT_REQUIRE_ACCESS:
				if (Kinds::Compare::le(tok_value_kinds[1], K_object) == FALSE) {
					failed_on =
						"the second thing you suggest this action should act on "
						"is not an object at all";
					goto Unmatched;
				}
				break;
		}
	}

	return;
	Unmatched:
		LOG("%d token values supplied\n", tok_values);
		{	int i;
			for (i=0; i<tok_values; i++)
				LOG("Token value %d: $u\n", i, tok_value_kinds[i]);
			LOG("Expected noun K: $u\n", an->noun_kind);
			LOG("Expected second K: $u\n", an->second_kind);
			LOG("Noun access level: %d\n", an->noun_access);
			LOG("Second access level: %d\n", an->second_access);
		}
		Problems::quote_source(1, current_sentence);
		if (an->designers_specification == NULL)
			Problems::quote_text(2, "<none given>");
		else
			Problems::quote_wording(2, ParseTree::get_text(an->designers_specification));
		Problems::quote_wording(3, an->present_name);
		Problems::quote_text(4, failed_on);
		Problems::Issue::handmade_problem(_p_(PM_GrammarMismatchesAction));
		Problems::issue_problem_segment("The grammar you give in %1 is not compatible "
			"with the %3 action (defined as '%2') - %4.");
		Problems::issue_problem_end();
}

@h Compiling data about actions.
In I6, there was no common infrastructure for the implementation of
actions: each defined its own |-Sub| routine. Here, we do have a common
infrastructure, and we access it with a single call.

=
void PL::Actions::compile_action_routines(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		if (an->use_verb_routine_in_I6_library) continue;
		inter_name *iname = PL::Actions::Sub(an);
		packaging_state save = Routines::begin(iname);
		Produce::inv_primitive(Produce::opcode(RETURN_BIP));
		Produce::down();
			inter_name *generic_iname = Hierarchy::find(GENERICVERBSUB_HL);
			Produce::inv_call_iname(generic_iname);
			Produce::down();
				Produce::val(K_number, LITERAL_IVAL, (inter_t) an->check_rules->allocation_id);
				Produce::val(K_number, LITERAL_IVAL, (inter_t) an->carry_out_rules->allocation_id);
				Produce::val(K_number, LITERAL_IVAL, (inter_t) an->report_rules->allocation_id);
			Produce::up();
		Produce::up();
		Routines::end(save);
	}
}

@h Compiling data about actions.
There are also collective tables of data about actions.

=
void PL::Actions::ActionData(void) {
	PL::Actions::compile_action_name_var_creators();
	action_name *an;
	int mn, ms, ml, mnp, msp, hn, hs, record_count = 0;

	inter_name *iname = Hierarchy::find(ACTIONDATA_HL);
	packaging_state save = Emit::named_table_array_begin(iname, K_value);
	LOOP_OVER(an, action_name) {
		if (an->use_verb_routine_in_I6_library) continue;
		mn = 0; ms = 0; ml = 0; mnp = 1; msp = 1; hn = 0; hs = 0;
		if (an->requires_light) ml = 1;
		if (an->noun_access == REQUIRES_ACCESS) mn = 1;
		if (an->second_access == REQUIRES_ACCESS) ms = 1;
		if (an->noun_access == REQUIRES_POSSESSION) { mn = 1; hn = 1; }
		if (an->second_access == REQUIRES_POSSESSION) { ms = 1; hs = 1; }
		if (an->noun_access == IMPOSSIBLE_ACCESS) mnp = 0;
		if (an->second_access == IMPOSSIBLE_ACCESS) msp = 0;
		record_count++;
		Emit::array_action_entry(an);
		inter_t bitmap = (inter_t) (mn + ms*0x02 + ml*0x04 + mnp*0x08 +
			msp*0x10 + ((an->out_of_world)?1:0)*0x20 + hn*0x40 + hs*0x80);
		Emit::array_numeric_entry(bitmap);
		Kinds::RunTime::emit_strong_id(an->noun_kind);
		Kinds::RunTime::emit_strong_id(an->second_kind);
		if ((an->owned_by_an) &&
				(StackedVariables::owner_empty(an->owned_by_an) == FALSE))
			Emit::array_iname_entry(StackedVariables::frame_creator(an->owned_by_an));
		else Emit::array_numeric_entry(0);
		Emit::array_numeric_entry((inter_t) (20000+an->allocation_id));
	}
	Emit::array_end(save);
	inter_name *ad_iname = Hierarchy::find(AD_RECORDS_HL);
	Emit::named_numeric_constant(ad_iname, (inter_t) record_count);

	VirtualMachines::note_usage("action", EMPTY_WORDING, NULL, 12, 0, TRUE);

	inter_name *DB_Action_Details_iname = Hierarchy::find(DB_ACTION_DETAILS_HL);
	save = Routines::begin(DB_Action_Details_iname);
	inter_symbol *act_s = LocalVariables::add_named_call_as_symbol(I"act");
	inter_symbol *n_s = LocalVariables::add_named_call_as_symbol(I"n");
	inter_symbol *s_s = LocalVariables::add_named_call_as_symbol(I"s");
	inter_symbol *for_say_s = LocalVariables::add_named_call_as_symbol(I"for_say");
	Produce::inv_primitive(Produce::opcode(SWITCH_BIP));
	Produce::down();
		Produce::val_symbol(K_value, act_s);
		Produce::code();
		Produce::down();

	LOOP_OVER(an, action_name) {
		if (an->use_verb_routine_in_I6_library) continue;
			Produce::inv_primitive(Produce::opcode(CASE_BIP));
			Produce::down();
				Produce::val_iname(K_value, PL::Actions::double_sharp(an));
				Produce::code();
				Produce::down();

				int j = Wordings::first_wn(an->present_name), j0 = -1, somethings = 0, clc = 0;
				while (j <= Wordings::last_wn(an->present_name)) {
					if (<action-pronoun>(Wordings::one_word(j))) {
						if (j0 >= 0) {
							@<Insert a space here if needed to break up the action name@>;

							TEMPORARY_TEXT(AT);
							PL::Actions::print_action_text_to(Wordings::new(j0, j-1), Wordings::first_wn(an->present_name), AT);
							Produce::inv_primitive(Produce::opcode(PRINT_BIP));
							Produce::down();
								Produce::val_text(AT);
							Produce::up();
							DISCARD_TEXT(AT);

							j0 = -1;
						}
						@<Insert a space here if needed to break up the action name@>;
						Produce::inv_primitive(Produce::opcode(IFELSE_BIP));
						Produce::down();
							Produce::inv_primitive(Produce::opcode(EQ_BIP));
							Produce::down();
								Produce::val_symbol(K_value, for_say_s);
								Produce::val(K_number, LITERAL_IVAL, 2);
							Produce::up();
							Produce::code();
							Produce::down();
								Produce::inv_primitive(Produce::opcode(PRINT_BIP));
								Produce::down();
									Produce::val_text(I"it");
								Produce::up();
							Produce::up();
							Produce::code();
							Produce::down();
								PL::Actions::cat_something2(an, somethings++, n_s, s_s);
							Produce::up();
						Produce::up();
					} else {
						if (j0<0) j0 = j;
					}
					j++;
				}
				if (j0 >= 0) {
					@<Insert a space here if needed to break up the action name@>;
					TEMPORARY_TEXT(AT);
					PL::Actions::print_action_text_to(Wordings::new(j0, j-1), Wordings::first_wn(an->present_name), AT);
					Produce::inv_primitive(Produce::opcode(PRINT_BIP));
					Produce::down();
						Produce::val_text(AT);
					Produce::up();
					DISCARD_TEXT(AT);
				}
				if (somethings < an->max_parameters) {
					Produce::inv_primitive(Produce::opcode(IF_BIP));
					Produce::down();
						Produce::inv_primitive(Produce::opcode(NE_BIP));
						Produce::down();
							Produce::val_symbol(K_value, for_say_s);
							Produce::val(K_number, LITERAL_IVAL, 2);
						Produce::up();
						Produce::code();
						Produce::down();
							@<Insert a space here if needed to break up the action name@>;
							PL::Actions::cat_something2(an, somethings++, n_s, s_s);
						Produce::up();
					Produce::up();
				}

				Produce::up();
			Produce::up();
	}

		Produce::up();
	Produce::up();
	Routines::end(save);
}

@<Insert a space here if needed to break up the action name@> =
	if (clc++ > 0) {
		Produce::inv_primitive(Produce::opcode(PRINT_BIP));
		Produce::down();
			Produce::val_text(I" ");
		Produce::up();
	}

@ =
void PL::Actions::cat_something2(action_name *an, int n, inter_symbol *n_s, inter_symbol *s_s) {
	kind *K = an->noun_kind;
	inter_symbol *var = n_s;
	if (n > 0) {
		K = an->second_kind; var = s_s;
	}
	if (Kinds::Compare::le(K, K_object) == FALSE)
		var = InterNames::to_symbol(Hierarchy::find(PARSED_NUMBER_HL));
	Produce::inv_primitive(Produce::opcode(INDIRECT1V_BIP));
	Produce::down();
		Produce::val_iname(K_value, Kinds::Behaviour::get_name_of_printing_rule_ACTIONS(K));
		if (Kinds::Compare::eq(K, K_understanding)) {
			Produce::inv_primitive(Produce::opcode(PLUS_BIP));
			Produce::down();
				Produce::inv_primitive(Produce::opcode(TIMES_BIP));
				Produce::down();
					Produce::val(K_number, LITERAL_IVAL, 100);
					Produce::val_iname(K_number, Hierarchy::find(CONSULT_FROM_HL));
				Produce::up();
				Produce::val_iname(K_number, Hierarchy::find(CONSULT_WORDS_HL));
			Produce::up();
		} else {
			Produce::val_symbol(K_value, var);
		}
	Produce::up();
}

void PL::Actions::print_action_text_to(wording W, int start, OUTPUT_STREAM) {
	if (Wordings::first_wn(W) == start) {
		WRITE("%W", Wordings::first_word(W));
		W = Wordings::trim_first_word(W);
		if (Wordings::empty(W)) return;
		WRITE(" ");
	}
	WRITE("%+W", W);
}

void PL::Actions::ActionCoding_array(void) {
	inter_name *iname = Hierarchy::find(ACTIONCODING_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	action_name *an;
	LOOP_OVER(an, action_name) {
		if (Str::get_first_char(PL::Actions::identifier(an)) == '_') Emit::array_numeric_entry(0);
		else Emit::array_action_entry(an);
	}
	Emit::array_end(save);
}

@h Indexing.

=
int PL::Actions::index(OUTPUT_STREAM, action_name *an, int pass,
	extension_file **ext, heading **current_area, int f, int *new_par, int bold,
	int on_details_page) {
	if (an->use_verb_routine_in_I6_library) return f;
	heading *definition_area = Sentences::Headings::of_wording(an->present_name);
	*new_par = FALSE;
	if (pass == 1) {
		extension_file *this_extension =
			Sentences::Headings::get_extension_containing(definition_area);
		if (*ext != this_extension) {
			*ext = this_extension;
			if (*ext == NULL) {
				if (f) HTML_CLOSE("p");
				HTML_OPEN("p");
				WRITE("<b>New actions defined in the source</b>");
				HTML_TAG("br");
				f = FALSE;
				*new_par = TRUE;
			} else if (*ext != standard_rules_extension) {
				if (f) HTML_CLOSE("p");
				HTML_OPEN("p");
				WRITE("<b>Actions defined by the extension ");
				Extensions::Files::write_name_to_file(*ext, OUT);
				WRITE(" by ");
				Extensions::Files::write_author_to_file(*ext, OUT);
				WRITE("</b>");
				HTML_TAG("br");
				f = FALSE;
				*new_par = TRUE;
			}
		}
		if ((definition_area != *current_area) && (*ext == standard_rules_extension)) {
			if (f) HTML_CLOSE("p");
			HTML_OPEN("p");
			wording W = Sentences::Headings::get_text(definition_area);
			if (Wordings::nonempty(W)) {
				Phrases::Index::index_definition_area(OUT, W, TRUE);
			} else if (*ext == NULL) {
				WRITE("<b>");
				WRITE("New actions");
				WRITE("</b>");
				HTML_TAG("br");
			}
			f = FALSE;
			*new_par = TRUE;
		}
	}
	if (pass == 1) {
		if (f) WRITE(", "); else {
			if (*new_par == FALSE) {
				HTML_OPEN("p");
				*new_par = TRUE;
			}
		}
	}

	f = TRUE;
	*current_area = definition_area;
	if (pass == 2) {
		HTML_OPEN("p");
	}
	if (an->out_of_world) HTML::begin_colour(OUT, I"800000");
	if (pass == 1) {
		if (bold) WRITE("<b>");
		WRITE("%+W", an->present_name);
		if (bold) WRITE("</b>");
	} else {
		WRITE("<b>");
		int j = Wordings::first_wn(an->present_name);
		int somethings = 0;
		while (j <= Wordings::last_wn(an->present_name)) {
			if (<action-pronoun>(Wordings::one_word(j))) {
				PL::Actions::act_index_something(OUT, an, somethings++);
			} else {
				WRITE("%+W ", Wordings::one_word(j));
			}
			j++;
		}
		if (somethings < an->max_parameters)
			PL::Actions::act_index_something(OUT, an, somethings++);
	}
	if (an->out_of_world) HTML::end_colour(OUT);
	if (pass == 2) {
		int swn = PL::Actions::an_get_specification_text(an);
		WRITE("</b>");
		Index::link(OUT, Wordings::first_wn(ParseTree::get_text(an->designers_specification)));
		Index::anchor(OUT, PL::Actions::identifier(an));
		if (an->requires_light) WRITE(" (requires light)");
		WRITE(" (<i>past tense</i> %+W)", an->past_name);
		HTML_CLOSE("p");
		if (swn >= 0) { HTML_OPEN("p"); WRITE("%W", Wordings::one_word(swn)); HTML_CLOSE("p"); }
		HTML_TAG("hr");
		HTML_OPEN("p"); WRITE("<b>Typed commands leading to this action</b>\n"); HTML_CLOSE("p");
		HTML_OPEN("p");
		if (PL::Parsing::Lines::index_list_with_action(OUT, an->list_with_action) == FALSE)
			WRITE("<i>None</i>");
		HTML_CLOSE("p");
		if (StackedVariables::owner_empty(an->owned_by_an) == FALSE) {
			HTML_OPEN("p"); WRITE("<b>Named values belonging to this action</b>\n"); HTML_CLOSE("p");
			StackedVariables::index_owner(OUT, an->owned_by_an);
		}

		HTML_OPEN("p"); WRITE("<b>Rules controlling this action</b>"); HTML_CLOSE("p");
		HTML_OPEN("p");
		WRITE("\n");
		int resp_count = 0;
		if (an->out_of_world == FALSE) {
			Rulebooks::index_action_rules(OUT, an, NULL, PERSUASION_RB, "persuasion", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, UNSUCCESSFUL_ATTEMPT_BY_RB, "unsuccessful attempt", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, SETTING_ACTION_VARIABLES_RB, "set action variables for", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, BEFORE_RB, "before", &resp_count);
			Rulebooks::index_action_rules(OUT, an, NULL, INSTEAD_RB, "instead of", &resp_count);
		}
		Rulebooks::index_action_rules(OUT, an, an->check_rules, CHECK_RB, "check", &resp_count);
		Rulebooks::index_action_rules(OUT, an, an->carry_out_rules, CARRY_OUT_RB, "carry out", &resp_count);
		if (an->out_of_world == FALSE)
			Rulebooks::index_action_rules(OUT, an, NULL, AFTER_RB, "after", &resp_count);
		Rulebooks::index_action_rules(OUT, an, an->report_rules, REPORT_RB, "report", &resp_count);
		if (resp_count > 1) {
			WRITE("Click on the speech-bubble icons to see the responses, "
				"or here to see all of them:");
			WRITE("&nbsp;");
			Index::extra_link_with(OUT, 2000000, "responses");
			WRITE("%d", resp_count);
		}
		HTML_CLOSE("p");
	} else {
		Index::link(OUT, Wordings::first_wn(ParseTree::get_text(an->designers_specification)));
		Index::detail_link(OUT, "A", an->allocation_id, (on_details_page)?FALSE:TRUE);
	}
	return f;
}

void PL::Actions::act_index_something(OUTPUT_STREAM, action_name *an, int argc) {
	kind *K = NULL; /* redundant assignment to appease |gcc -O2| */
	HTML::begin_colour(OUT, I"000080");
	if (argc == 0) K = an->noun_kind;
	if (argc == 1) K = an->second_kind;
	if (Kinds::Compare::le(K, K_object)) WRITE("something");
	else if (Kinds::Compare::eq(K, K_understanding)) WRITE("some text");
	else Kinds::Textual::write(OUT, K);
	HTML::end_colour(OUT);
	WRITE(" ");
}
