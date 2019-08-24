[Rulebooks::] Rulebooks.

To create, manage, compile and index rulebooks, the content of which
is a linked list of booked rules together with some general conventions as to
how they are to be used.

@h Definitions.

@ A rulebook consists of some general properties together with a linked list
of booked rules, which constitute its entries. Some rulebooks are created
explicitly by the user's source text, some are created explicitly by the
Standard Rules, while others are "automatically generated" as a result
of other creations by Inform. For instance, each new scene ending generates
a rulebook. There are numerous other examples because a rulebook is the
natural and most flexible way to provide a "hook" by which to attach
behaviour to a world model.

In some ways phrases and rules are really subsidiary ideas, and the
rulebook is the fundamental level of programming in Inform 7. The reason it
turns up so late in the source code is that many of the other data
structures were building up to this one: a |rulebook| contains |booking|s
which refer to |phrase|s whose usage is defined with |specification|s, and
whose definition is stored in the |parse_node| tree until it can be
resolved as a list of |invocation|s.

@ The semantics of rulebooks have grown over time. At one time they looked
only at the current action, and did something accordingly, but there was
no real sense in which they passed information. They then began to apply
to objects or actions (this was called the "focus") and, in a few cases,
returned information by ending in success, failure or neither (the
"outcome"). Gradually they became more function-like: today, the focus can
be a value of any kind, or else the current action; and the outcome can be
success, failure, neither, a named outcome, or else a value of any kind.
Moreover they can have variables shared by all rules in the current
instantiation of the rulebook. A rulebook is thus able to do anything which
a function $X\to Y$ in a standard programming language can do; in 2009, it
was a particular goal of the rewriting of the kinds system to ensure that
rulebooks could, in principle, do anything which functions could do in a
language such as Haskell.

=
typedef struct rulebook {
	struct wording primary_name; /* name in source text */
	struct wording alternative_name; /* alternative form of name */
	int fragmentation_stem_length; /* to do with parsing, but 0 for most rulebooks */

	struct focus my_focus;
	struct outcomes my_outcomes;

	int automatically_generated; /* so that the index can omit these */
	int runs_during_activities; /* allow "while..." clauses to name these */
	int used_by_future_action_activity; /* like "deciding the scope of something..." */

	struct booking *rule_list; /* linked list of booked rules */

	struct placement_affecting *placement_list; /* linked list of explicit placements */

	struct stacked_variable_owner *owned_by_rb; /* rulebook variables owned here */
	struct stacked_variable_owner_list *accessible_from_rb; /* and which can be named here */
	struct inter_name *stv_creator_iname;

	struct package_request *rb_package;
	struct inter_name *rb_iname; /* run-time storage/routine holding contents */
	MEMORY_MANAGEMENT
} rulebook;

@ The following is used only to store the result of parsing text as a
rulebook name:

=
typedef struct rulebook_match {
	struct rulebook *matched_rulebook;
	int match_from;
	int match_length;
	int advance_words;
	int tail_words;
	int article_used;
	int placement_requested;
} rulebook_match;

@ The contents of rulebooks can be unexpected if sentences are used which
explicitly list, or unlist, rules. To make the index more useful in these
cases, we keep a linked list, for each rulebook, of all sentences which
have affected it in this way:

=
typedef struct placement_affecting {
	struct parse_node *placement_sentence;
	struct placement_affecting *next;
	MEMORY_MANAGEMENT
} placement_affecting;

@ As rulebooks are declared, the first few are quietly copied into
a small array: that way, we can always obtain a pointer to, say, the
turn sequence rules by looking up |built_in_rulebooks[TURN_SEQUENCE_RB]|.

@d MAX_BUILT_IN_RULEBOOKS 32

= (early code)
rulebook *built_in_rulebooks[MAX_BUILT_IN_RULEBOOKS];
struct stacked_variable_owner_list *all_action_processing_vars = NULL;

@ Many of the standard rulebooks need to have numbers which are
predictable, because they need to be referred to by number by the I6
library code. Because of this, it is important not to change the numbers
below without checking the corresponding I6 Constant declarations in the
|Definitions.i6t| file: the two sets of declarations must exactly match. They
must also exactly match the sequence in which these rulebooks are created
in the Standard Rules file.

@d STARTUP_RB 0 /* Startup rules */
@d TURN_SEQUENCE_RB 1 /* Turn sequence rules */
@d SHUTDOWN_RB 2 /* Shutdown rules */
@d SCENE_CHANGING_RB 3 /* Scene changing rules */
@d WHEN_PLAY_BEGINS_RB 4 /* When play begins */
@d WHEN_PLAY_ENDS_RB 5 /* When play ends */
@d WHEN_SCENE_BEGINS_RB 6 /* When play begins */
@d WHEN_SCENE_ENDS_RB 7 /* When play ends */
@d EVERY_TURN_RB 8 /* Every turn */

@d ACTION_PROCESSING_RB 9 /* Action-processing rules */
@d SETTING_ACTION_VARIABLES_RB 10 /* Setting action variables rules */
@d SPECIFIC_ACTION_PROCESSING_RB 11 /* Specific action-processing rules */
@d PLAYERS_ACTION_AWARENESS_RB 12 /* Player's action awareness rules */

@d ACCESSIBILITY_RB 13 /* Accessibility rules */
@d REACHING_INSIDE_RB 14 /* Reaching inside rules */
@d REACHING_OUTSIDE_RB 15 /* Reaching outside rules */
@d VISIBILITY_RB 16 /* Visibility rules */

@d PERSUASION_RB 17 /* Persuasion rules */
@d UNSUCCESSFUL_ATTEMPT_BY_RB 18 /* Unsuccessful attempt by */

@d BEFORE_RB 19 /* Before rules */
@d INSTEAD_RB 20 /* Instead rules */
@d CHECK_RB 21 /* Check */
@d CARRY_OUT_RB 22 /* Carry out rules */
@d AFTER_RB 23 /* After rules */
@d REPORT_RB 24 /* Report */

@d DOES_THE_PLAYER_MEAN_RB 25 /* Does the player mean...? rules */
@d MULTIPLE_ACTION_PROCESSING_RB 26 /* For changing or reordering multiple actions */

@h Construction.
When a rulebook is to be created, we do a little treatment on its name. We
remove any article, and also strip off the suffix "rules" or "rulebook"
as redundant -- see below for why. Since we want to insure that phrase/rule
preambles are unambiguous, we also want to make sure that keywords introducing
phrase definitions and timed events don't open the rulebook name.

=
<new-rulebook-name> ::=
	<definite-article> <new-rulebook-name> |	==> R[2]
	<new-rulebook-name> rules/rulebook |		==> R[1]
	at *** |									==> @<Issue PM_RulebookWithAt problem@>
	to *** |									==> @<Issue PM_RulebookWithTo problem@>
	definition *** |							==> @<Issue PM_RulebookWithDefinition problem@>
	...											==> 0

@<Issue PM_RulebookWithAt problem@> =
	Problems::Issue::sentence_problem(_p_(PM_RulebookWithAt),
		"this would create a rulebook whose name begins with 'at'",
		"which is forbidden since it would lead to ambiguities in "
		"the way people write rules. A rule beginning with 'At' "
		"is one which happens at a given time, whereas a rule "
		"belonging to a rulebook starts with the name of that "
		"rulebook, so a rulebook named 'at ...' would make such "
		"a rule inscrutable.");

@<Issue PM_RulebookWithTo problem@> =
		Problems::Issue::sentence_problem(_p_(PM_RulebookWithTo),
			"this would create a rulebook whose name begins with 'to'",
			"which is forbidden since it would lead to ambiguities in "
			"the way people write rules. A rule beginning with 'To' "
			"is one which defines a phrase, whereas a rule "
			"belonging to a rulebook starts with the name of that "
			"rulebook, so a rulebook named 'to ...' would make such "
			"a rule inscrutable.");

@<Issue PM_RulebookWithDefinition problem@> =
	Problems::Issue::sentence_problem(_p_(PM_RulebookWithDefinition),
		"this would create a rulebook whose name begins with 'definition'",
		"which is forbidden since it would lead to ambiguities in "
		"the way people write rules. A rule beginning with 'Definition' "
		"is one which defines an adjective, whereas a rule "
		"belonging to a rulebook starts with the name of that "
		"rulebook, so a rulebook named 'to ...' would make such "
		"a rule inscrutable.");

@ When a rulebook is created -- say, "coordination" -- Inform constructs
alternative names for it using the following -- say, making "coordination
rules" and "coordination rulebook":

=
<rulebook-name-construction> ::=
	... rules |
	... rulebook

@ Whereas, at run-time, rulebooks are special cases of rules (they have the
same kind of value, though their I6 values are such as to make it possible
to distinguish them), within I7 rulebooks and rules have entirely different
data structures. There are two constructor functions: a basic one, used
for those created by typical source text, and an advanced one used when
rulebooks are automatically created as a result of other structures being
built (for instance, scene endings).

=
rulebook *Rulebooks::new(kind *create_as, wording W, package_request *R) {
	Hierarchy::markup_wording(R, RULEBOOK_NAME_HMD, W);

	rulebook *rb = CREATE(rulebook);

	<new-rulebook-name>(W);
	W = GET_RW(<new-rulebook-name>, 1);

	rb->primary_name = W;
	rb->alternative_name = EMPTY_WORDING;
	rb->rb_package = R;
	rb->rb_iname = Hierarchy::make_iname_in(RUN_FN_HL, rb->rb_package);

	rb->rule_list = Rules::Bookings::list_new();

	rb->automatically_generated = FALSE;
	rb->used_by_future_action_activity = FALSE;
	rb->runs_during_activities = FALSE;

	kind *parameter_kind = NULL;
	kind *producing_kind = NULL;
	Kinds::binary_construction_material(create_as, &parameter_kind, &producing_kind);

	Rulebooks::Outcomes::initialise_focus(&(rb->my_focus), parameter_kind);

	rb->fragmentation_stem_length = 0;

	int def = NO_OUTCOME;
	if (rb->allocation_id == INSTEAD_RB) def = FAILURE_OUTCOME;
	if (rb->allocation_id == AFTER_RB) def = SUCCESS_OUTCOME;
	if (rb->allocation_id == UNSUCCESSFUL_ATTEMPT_BY_RB) def = SUCCESS_OUTCOME;
	Rulebooks::Outcomes::initialise_outcomes(&(rb->my_outcomes), producing_kind, def);

	rb->placement_list = NULL;

	rb->owned_by_rb = StackedVariables::new_owner(rb->allocation_id);
	rb->accessible_from_rb = StackedVariables::add_owner_to_list(NULL, rb->owned_by_rb);
	rb->stv_creator_iname = NULL;

	if (rb->allocation_id < MAX_BUILT_IN_RULEBOOKS)
		built_in_rulebooks[rb->allocation_id] = rb;

	if (rb == built_in_rulebooks[ACTION_PROCESSING_RB])
		all_action_processing_vars = StackedVariables::add_owner_to_list(NULL, rb->owned_by_rb);

	Nouns::new_proper_noun(rb->primary_name, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb));
	word_assemblage wa =
		Preform::Nonparsing::merge(<rulebook-name-construction>, 0,
			WordAssemblages::from_wording(rb->primary_name));
	wording AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb));
	wa = Preform::Nonparsing::merge(<rulebook-name-construction>, 1,
			WordAssemblages::from_wording(rb->primary_name));
	AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb));

	return rb;
}

outcomes *Rulebooks::get_outcomes(rulebook *rb) {
	return &(rb->my_outcomes);
}

kind *Rulebooks::contains_kind(rulebook *rb) {
	return Kinds::binary_construction(CON_rule,
		Rulebooks::get_parameter_kind(rb),
		Rulebooks::Outcomes::get_outcome_kind(&(rb->my_outcomes)));
}

kind *Rulebooks::to_kind(rulebook *rb) {
	return Kinds::binary_construction(CON_rulebook,
		Rulebooks::get_parameter_kind(rb),
		Rulebooks::Outcomes::get_outcome_kind(&(rb->my_outcomes)));
}

rulebook *Rulebooks::new_automatic(wording W, kind *basis,
	int oc, int ata, int ubfaa, int rda, package_request *R) {
	rulebook *rb = Rulebooks::new(
		Kinds::binary_construction(CON_rulebook, basis, K_nil), W, R);
	Rulebooks::Outcomes::set_default_outcome(&(rb->my_outcomes), oc);
	Rulebooks::Outcomes::set_focus_ata(&(rb->my_focus), ata);
	rb->automatically_generated = TRUE;
	rb->used_by_future_action_activity = ubfaa;
	rb->runs_during_activities = rda;
	return rb;
}

void Rulebooks::set_alt_name(rulebook *rb, wording AW) {
	rb->alternative_name = AW;
	Nouns::new_proper_noun(AW, NEUTER_GENDER,
		REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb));
}

void Rulebooks::fragment_by_actions(rulebook *rb, int wn) {
	rb->fragmentation_stem_length = wn;
}

int Rulebooks::requires_specific_action(rulebook *rb) {
	if (rb == built_in_rulebooks[CHECK_RB]) return TRUE;
	if (rb == built_in_rulebooks[CARRY_OUT_RB]) return TRUE;
	if (rb == built_in_rulebooks[REPORT_RB]) return TRUE;
	if (rb->fragmentation_stem_length > 0) return TRUE;
	return FALSE;
}

@h Affected by placements.
Needed to make a useful index.

=
void Rulebooks::affected_by_placement(rulebook *rb, parse_node *where) {
	placement_affecting *npl = CREATE(placement_affecting);
	npl->placement_sentence = where;
	npl->next = rb->placement_list;
	rb->placement_list = npl;
}

int Rulebooks::rb_no_placements(rulebook *rb) {
	int t = 0;
	placement_affecting *npl = rb->placement_list;
	while (npl) { t++; npl = npl->next; }
	return t;
}

void Rulebooks::rb_index_placements(OUTPUT_STREAM, rulebook *rb) {
	placement_affecting *npl = rb->placement_list;
	while (npl) {
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		HTML_OPEN_WITH("span", "class=\"smaller\"");
		WRITE("<i>NB:</i> %W", ParseTree::get_text(npl->placement_sentence));
		Index::link(OUT, Wordings::first_wn(ParseTree::get_text(npl->placement_sentence)));
		HTML_CLOSE("span");
		HTML_TAG("br");
		npl = npl->next;
	}
}

@h Reading properties of rulebooks.
Those readable from outside the current section.

=
int Rulebooks::focus(rulebook *rb) {
	return Rulebooks::Outcomes::get_focus(&(rb->my_focus));
}

kind *Rulebooks::get_parameter_kind(rulebook *rb) {
	return Rulebooks::Outcomes::get_focus_parameter_kind(&(rb->my_focus));
}

int Rulebooks::used_by_future_actions(rulebook *rb) {
	return rb->used_by_future_action_activity;
}

int Rulebooks::is_empty(rulebook *rb, rule_context rc) {
	if (rb == NULL) return TRUE;
	return Rules::Bookings::list_is_empty(rb->rule_list, rc);
}

int Rulebooks::no_rules(rulebook *rb) {
	if (rb == NULL) return 0;
	return Rules::Bookings::no_rules_in_list(rb->rule_list);
}

int Rulebooks::rule_in_rulebook(rule *R, rulebook *rb) {
	if (rb == NULL) return FALSE;
	return Rules::Bookings::list_contains(rb->rule_list, R);
}

booking *Rulebooks::first_booking(rulebook *rb) {
	if (rb == NULL) return NULL;
	return rb->rule_list;
}

int Rulebooks::runs_during_activities(rulebook *rb) {
	return rb->runs_during_activities;
}

@h Rulebook variables.
Any new rulebook variable name is vetted by being run through this:

=
<rulebook-variable-name> ::=
	<unfortunate-name> |					==> @<Issue PM_RulebookVariableAnd problem@>
	...										==> TRUE

@<Issue PM_RulebookVariableAnd problem@> =
	*X = NOT_APPLICABLE;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_RulebookVariableAnd));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for a rulebook - a value associated "
		"with a rulebook and which has a name. The request seems to "
		"say that the name in question is '%2', but I'd prefer to "
		"avoid 'and', 'or', 'with', or 'having' in such names, please.");
	Problems::issue_problem_end();

@ =
void Rulebooks::add_variable(rulebook *rb, parse_node *cnode) {
	if (ParseTree::get_type(cnode) != PROPERTYCALLED_NT) {
		Problems::quote_source(1, current_sentence);
		Problems::Issue::handmade_problem(_p_(PM_RulebookVarUncalled));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for an rulebook - a value associated "
			"with a action and which has a name. But since you only give "
			"a kind, not a name, I'm stuck. ('The every turn rulebook has a "
			"number called importance' is right, 'The every turn rulebook has a "
			"number' is too vague.)");
		Problems::issue_problem_end();
		return;
	}

	if (<rulebook-variable-name>(ParseTree::get_text(cnode->down->next))) {
		if (<<r>> == NOT_APPLICABLE) return;
	}

	parse_node *spec = NULL;
	if (<s-type-expression>(ParseTree::get_text(cnode->down))) spec = <<rp>>;

	if ((Specifications::is_description(spec)) &&
		(Descriptions::is_qualified(spec))) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(cnode->down));
		Problems::Issue::handmade_problem(_p_(PM_RulebookVariableTooSpecific));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for a rulebook - a value associated "
			"with a rulebook and which has a name. The request seems to "
			"say that the value in question is '%2', but this is too "
			"specific a description. (Instead, a kind of value "
			"(such as 'number') or a kind of object (such as 'room' "
			"or 'thing') should be given. To get a property whose "
			"contents can be any kind of object, use 'object'.)");
		Problems::issue_problem_end();
		return;
	}
	if (ParseTree::is(spec, CONSTANT_NT)) {
		LOG("Offending SP: $T", spec);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(cnode->down));
		Problems::Issue::handmade_problem(_p_(PM_RulebookVariableBadKind));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not the name of a kind of "
			"value which I know (such as 'number' or 'text').");
		Problems::issue_problem_end();
		return;
	}

	kind *K = Specifications::to_kind(spec);
	if (K == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(cnode->down));
		Problems::Issue::handmade_problem(_p_(PM_RulebookVariableKindless));
		Problems::issue_problem_segment(
			"You wrote %1, but I was expecting to see a kind of value there, "
			"and '%2' isn't something I recognise as a kind.");
		Problems::issue_problem_end();
		return;
	}

	if (Kinds::Compare::eq(K, K_value)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(cnode->down));
		Problems::Issue::handmade_problem(_p_(PM_RulebookVariableVague));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a variable is a 'value' "
			"does not give me a clear enough idea what it will hold. "
			"You need to say what kind of value: for instance, 'A door "
			"has a number called street address.' is allowed because "
			"'number' is specific about the kind of value.");
		Problems::issue_problem_end();
		return;
	}

	StackedVariables::add_empty(rb->owned_by_rb, ParseTree::get_text(cnode->down->next), K);
}

void Rulebooks::make_stvs_accessible(rulebook *rb, stacked_variable_owner *stvo) {
	rb->accessible_from_rb = StackedVariables::add_owner_to_list(rb->accessible_from_rb, stvo);
}

inter_name *Rulebooks::get_stv_creator_iname(rulebook *rb) {
	if (rb->stv_creator_iname == NULL)
		rb->stv_creator_iname =
			Hierarchy::make_iname_in(RULEBOOK_STV_CREATOR_FN_HL, rb->rb_package);
	return rb->stv_creator_iname;
}

void Rulebooks::rulebook_var_creators(void) {
	rulebook *rb;
	LOOP_OVER(rb, rulebook)
		if (StackedVariables::owner_empty(rb->owned_by_rb) == FALSE)
			StackedVariables::compile_frame_creator(rb->owned_by_rb,
				Rulebooks::get_stv_creator_iname(rb));

	if (memory_economy_in_force == FALSE) {
		inter_name *iname = Hierarchy::find(RULEBOOK_VAR_CREATORS_HL);
		packaging_state save = Emit::named_array_begin(iname, K_value);
		LOOP_OVER(rb, rulebook) {
			if (StackedVariables::owner_empty(rb->owned_by_rb)) Emit::array_numeric_entry(0);
			else Emit::array_iname_entry(StackedVariables::frame_creator(rb->owned_by_rb));
		}
		Emit::array_numeric_entry(0);
		Emit::array_end(save);
	} else @<Make slow lookup routine@>;
}

@<Make slow lookup routine@> =
	inter_name *iname = Hierarchy::find(SLOW_LOOKUP_HL);
	packaging_state save = Routines::begin(iname);
	inter_symbol *rb_s = LocalVariables::add_named_call_as_symbol(I"rb");

	Produce::inv_primitive(Produce::opcode(SWITCH_BIP));
	Produce::down();
		Produce::val_symbol(K_value, rb_s);
		Produce::code();
		Produce::down();

		rulebook *rb;
		LOOP_OVER(rb, rulebook)
			if (StackedVariables::owner_empty(rb->owned_by_rb) == FALSE) {
				Produce::inv_primitive(Produce::opcode(CASE_BIP));
				Produce::down();
					Produce::val(K_value, LITERAL_IVAL, (inter_t) (rb->allocation_id));
					Produce::code();
					Produce::down();
						Produce::inv_primitive(Produce::opcode(RETURN_BIP));
						Produce::down();
							Produce::val_iname(K_value, Rulebooks::get_stv_creator_iname(rb));
						Produce::up();
					Produce::up();
				Produce::up();
			}

		Produce::up();
	Produce::up();
	Produce::inv_primitive(Produce::opcode(RETURN_BIP));
	Produce::down();
		Produce::val(K_number, LITERAL_IVAL, 0);
	Produce::up();

	Routines::end(save);

@h Indexing and logging rulebooks.

=
void Rulebooks::log_name_only(rulebook *rb) {
	LOG("Rulebook %d (%W)", rb->allocation_id, rb->primary_name);
}

void Rulebooks::log(rulebook *rb) {
	Rulebooks::log_name_only(rb);
	LOG(": ");
	Rules::Bookings::list_log(rb->rule_list);
}

rule_context Rulebooks::no_rule_context(void) {
	rule_context rc;
	#ifdef IF_MODULE
	rc.action_context = NULL;
	rc.scene_context = NULL;
	#endif
	#ifndef IF_MODULE
	rc.not_used = NULL;
	#endif
	return rc;
}

int Rulebooks::phrase_fits_rule_context(phrase *ph, rule_context rc) {
	#ifdef IF_MODULE
	if (rc.scene_context == NULL) return TRUE;
	if (ph == NULL) return FALSE;
	if (Phrases::Context::get_scene(&(ph->runtime_context_data)) != rc.scene_context) return FALSE;
	return TRUE;
	#endif
	#ifndef IF_MODULE
	return TRUE;
	#endif
}

#ifdef IF_MODULE
rule_context Rulebooks::action_context(action_name *an) {
	rule_context rc;
	rc.action_context = an;
	rc.scene_context = NULL;
	return rc;
}
rule_context Rulebooks::scene_context(scene *s) {
	rule_context rc;
	rc.action_context = NULL;
	rc.scene_context = s;
	return rc;
}
#endif

int Rulebooks::index(OUTPUT_STREAM, rulebook *rb, char *billing, rule_context rc, int *resp_count) {
	int suppress_outcome = FALSE, t;
	if (rb == NULL) return 0;
	if (billing == NULL) internal_error("No billing for rb index");
	if (billing[0] != 0) {
		#ifdef IF_MODULE
		if (rc.action_context) suppress_outcome = TRUE;
		#endif
		if (Rules::Bookings::list_is_empty(rb->rule_list, rc)) suppress_outcome = TRUE;
	}
	t = Rules::Bookings::list_index(OUT, rb->rule_list, rc, billing, rb, resp_count);
	Rulebooks::Outcomes::index_outcomes(OUT, &(rb->my_outcomes), suppress_outcome);
	Rulebooks::rb_index_placements(OUT, rb);
	return t;
}

#ifdef IF_MODULE
void Rulebooks::index_action_rules(OUTPUT_STREAM, action_name *an, rulebook *rb,
	int code, char *desc, int *resp_count) {
	int t = 0;
	Rules::Bookings::list_suppress_indexed_links();
	if (code >= 0) t += Rulebooks::index(OUT, built_in_rulebooks[code], desc,
		Rulebooks::action_context(an), resp_count);
	if (rb) t += Rulebooks::index(OUT, rb, desc, Rulebooks::no_rule_context(), resp_count);
	Rules::Bookings::list_resume_indexed_links();
	if (t > 0) HTML_TAG("br");
}
#endif

@h Name parsing of rulebooks.
The following internal finds the "stem" of a rule, that is, the part
which identifies which rulebook it will go into. For example, in

>> Before printing the name of the peach: ...
>> Instead of eating: ...

the stems are "before printing the name" and "instead". It makes use
of <rulebook-stem-inner> below, and then does some direct parsing.

=
<rulebook-stem> internal ? {
	rulebook_match rm = Rulebooks::rb_match_from_description(W);
	if (rm.matched_rulebook == NULL) return FALSE;
	parsed_rm = rm;
	return Wordings::first_wn(W) + rm.advance_words - 1;
}

@ Suppose this is our rule:

>> The first rule for printing the name of something: ...

the following grammar peels away the easier-to-read indications at the
front. It notes the use of "The", and the placement "first"; it throws
away other verbiage so that <rulebook-stem-name> matches

>> printing the name of something

<rulebook-stem> then takes over again and searches for the longest possible
rulebook name at the start of the stem. So if there were a rulebook called
"printing", it wouldn't match here, because "printing the name" is longer.
(<rulebook-stem> doesn't match the "of".)

Productions (a) and (b) of <rulebook-stem-name> are slightly hacky exceptions
to allow for the "when S begins" rulebooks, where S can be any description
of a scene rather than just a scene's name. In effect, the stem here consists
of the two outer words and is discontiguous.

=
<rulebook-stem-inner> ::=
	<indefinite-article> <rulebook-stem-inner-unarticled> |	==> INDEF_ART; <<place>> = R[2]
	<definite-article> <rulebook-stem-inner-unarticled> |	==> DEF_ART; <<place>> = R[2]
	<rulebook-stem-inner-unarticled>						==> NO_ART; <<place>> = R[1]

<rulebook-stem-inner-unarticled> ::=
	rule for/about/on <rulebook-stem-name> |	==> MIDDLE_PLACEMENT; <<len>> = R[1]
	rule <rulebook-stem-name> |					==> MIDDLE_PLACEMENT; <<len>> = R[1]
	first rule <rulebook-stem-name> |			==> FIRST_PLACEMENT; <<len>> = R[1]
	first <rulebook-stem-name> |				==> FIRST_PLACEMENT; <<len>> = R[1]
	last rule <rulebook-stem-name> |			==> LAST_PLACEMENT; <<len>> = R[1]
	last <rulebook-stem-name> |					==> LAST_PLACEMENT; <<len>> = R[1]
	<rulebook-stem-name>						==> MIDDLE_PLACEMENT; <<len>> = R[1]

<rulebook-stem-name> ::=
	{when ... begins} |							==> 2; <<rulebook:m>> = built_in_rulebooks[WHEN_SCENE_BEGINS_RB] /* scenes\_plugin */
	{when ... ends} |							==> 2; <<rulebook:m>> = built_in_rulebooks[WHEN_SCENE_ENDS_RB] /* scenes\_plugin */
	...											==> 0; <<rulebook:m>> = NULL

@ =
rulebook_match Rulebooks::rb_match_from_description(wording W) {
	int initial_w1 = Wordings::first_wn(W), modifier_words;
	int art = NO_ART, pl = MIDDLE_PLACEMENT;
	rulebook *rb;
	rulebook_match rm;

	<rulebook-stem-inner>(W);
	W = GET_RW(<rulebook-stem-name>, 1);
	art = <<r>>; pl = <<place>>;

	modifier_words = Wordings::first_wn(W) - initial_w1;

	rm.match_length = 0;
	rm.advance_words = 0;
	rm.match_from = initial_w1;
	rm.tail_words = 0;
	rm.matched_rulebook = NULL;
	rm.article_used = art;
	rm.placement_requested = pl;

	LOOP_OVER(rb, rulebook) {

		if (rb == <<rulebook:m>>) {
			if (rm.match_length < <<len>>) {
				rm.match_length = <<len>>;
				rm.matched_rulebook = rb;
			}
		} else {
			if (Wordings::starts_with(W, rb->primary_name)) {
				if (rm.match_length < Wordings::length(rb->primary_name)) {
					rm.match_length = Wordings::length(rb->primary_name);
					rm.matched_rulebook = rb;
				}
			} else if (Wordings::starts_with(W, rb->alternative_name)) {
				if (rm.match_length < Wordings::length(rb->alternative_name)) {
					rm.match_length = Wordings::length(rb->alternative_name);
					rm.matched_rulebook = rb;
				}
			}
		}

	}

	if (rm.match_length == 0) return rm;

	rm.advance_words = rm.match_length;

	if (rm.matched_rulebook == <<rulebook:m>>) {
		rm.tail_words = 1;
		rm.match_length = 1;
	}

	if (rm.matched_rulebook->fragmentation_stem_length) {
		int w1a = Wordings::first_wn(W) + rm.match_length - 1;
		if (w1a != Wordings::last_wn(W))
			rm.match_length = rm.matched_rulebook->fragmentation_stem_length;
	}

	rm.match_length += modifier_words;
	rm.advance_words += modifier_words;
	return rm;
}

@h Rule attachments.
The following routine contains a bit of a surprise: that the act of
placing a BR within a given rulebook can change it, by altering the way
it acts on its applicability test. This is a device needed to manage
the parallel rulebooks for action processing for the main player character
and for third parties. Though the code below does not make this apparent,
the changes propagate down through the BR to the phrase structure itself.
This is necessary because they manifest themselves in the compiled code
of the phrase, but it is also unfortunate, because it is possible that
the same phrase is used by more than one BR. If it should happen that
BRs are created to place the same phrase into two different rulebooks,
therefore, and which have different actor-testing settings, the outcome
would be confusing. (As unlikely as this seems, it did once happen to a
user in beta-testing.)

All work on the sequence of rules in rulebooks is delegated to the
sub-section on linked lists of booked rules in the section on Rules.

=
void Rulebooks::attach_rule(rulebook *rb, booking *the_new_rule,
	int placing, int side, rule *ref_rule) {
	LOGIF(RULE_ATTACHMENTS, "Attaching booked rule $b at sentence:\n  $T",
		the_new_rule, current_sentence);
	LOGIF(RULE_ATTACHMENTS, "Rulebook before attachment: $K", rb);

	if (Rules::Bookings::get_rule(the_new_rule) == ref_rule) {
		if (side != INSTEAD_SIDE)
			Problems::Issue::sentence_problem(_p_(PM_BeforeOrAfterSelf),
				"a rule can't be before or after itself",
				"so this makes no sense to me.");
		return;
	}

	#ifdef IF_MODULE
	if ((rb == built_in_rulebooks[BEFORE_RB]) ||
		(rb == built_in_rulebooks[AFTER_RB]) ||
		(rb == built_in_rulebooks[INSTEAD_RB])) {
		phrase *ph = Rules::get_I7_definition(Rules::Bookings::get_rule(the_new_rule));
		if (ph) {
			action_name *an = Phrases::Context::required_action(&(ph->runtime_context_data));
			if ((an) && (PL::Actions::is_out_of_world(an)))
				Problems::Issue::sentence_problem(_p_(PM_OOWinIWRulebook),
					"this rulebook has no effect on actions which happen out of world",
					"so I'm not going to let you file this rule in it. ('Check', "
					"'Carry out' and 'Report' work fine for out of world actions: "
					"but 'Before', 'Instead' and 'After' have no effect on them.)");
		}
	}


	if (rb == built_in_rulebooks[SETTING_ACTION_VARIABLES_RB]) {
		Rules::set_never_test_actor(Rules::Bookings::get_rule(the_new_rule));
	} else {
		Rulebooks::Outcomes::modify_rule_to_suit_focus(&(rb->my_focus),
			Rules::Bookings::get_rule(the_new_rule));
	}

	if (side == INSTEAD_SIDE) {
		LOGIF(RULE_ATTACHMENTS,
			"Copying actor test flags from rule being replaced\n");
		Rules::copy_actor_test_flags(Rules::Bookings::get_rule(the_new_rule), ref_rule);
		LOGIF(RULE_ATTACHMENTS,
			"Copying former rulebook's variable permissions to displaced rule\n");
		Rules::acquire_stvol(ref_rule, rb->accessible_from_rb);
		if (Rulebooks::focus(rb) == ACTION_FOCUS)
			Rules::acquire_action_variables(ref_rule);
	}
	#endif

	Rules::acquire_stvol(Rules::Bookings::get_rule(the_new_rule), rb->accessible_from_rb);
	if (Rulebooks::focus(rb) == ACTION_FOCUS)
		Rules::acquire_action_variables(Rules::Bookings::get_rule(the_new_rule));
	if (rb->fragmentation_stem_length > 0)
		Rules::suppress_action_testing(Rules::Bookings::get_rule(the_new_rule));

	Phrases::Context::ensure_avl(Rules::Bookings::get_rule(the_new_rule));

	Rules::Bookings::list_add(rb->rule_list, the_new_rule, placing, side, ref_rule);
	LOGIF(RULE_ATTACHMENTS, "Rulebook after attachment: $K", rb);
}

void Rulebooks::detach_rule(rulebook *rb, rule *the_new_rule) {
	Rules::Bookings::list_remove(rb->rule_list, the_new_rule);
}

@h Compilation.
We do not actually compile the I6 routines for a rulebook here, but simply
act as a proxy. The I6 arrays making the rulebooks available to run-time
code are the real outcome of the code in this section.

=
void Rulebooks::compile_rule_phrases(rulebook *rb, int *i, int max_i) {
	Rules::Bookings::list_judge_ordering(rb->rule_list);
	if (Rules::Bookings::list_is_empty_of_i7_rules(rb->rule_list)) return;

	Rules::Bookings::list_compile_rule_phrases(rb->rule_list, i, max_i);
}

void Rulebooks::rulebooks_array_array(void) {
	inter_name *iname = Hierarchy::find(RULEBOOKS_ARRAY_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	rulebook *rb;
	LOOP_OVER(rb, rulebook)
		Emit::array_iname_entry(rb->rb_iname);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}

void Rulebooks::compile_rulebooks(void) {
	Rules::Bookings::start_list_compilation();
	rulebook *rb;
	LOOP_OVER(rb, rulebook) {
		int act = FALSE;
		if (Rulebooks::focus(rb) == ACTION_FOCUS) act = TRUE;
		if (rb->automatically_generated) act = FALSE;
		int par = FALSE;
		if (Rulebooks::focus(rb) == PARAMETER_FOCUS) par = TRUE;
		LOGIF(RULEBOOK_COMPILATION, "Compiling rulebook: %W = %n\n",
			rb->primary_name, rb->rb_iname);
		Rules::Bookings::list_compile(rb->rule_list, rb->rb_iname, act, par);
	}
	Rules::check_placement_safety();
}

void Rulebooks::RulebookNames_array(void) {
	inter_name *iname = Hierarchy::find(RULEBOOKNAMES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	if (memory_economy_in_force) {
		Emit::array_numeric_entry(0);
		Emit::array_numeric_entry(0);
	} else {
		rulebook *rb;
		LOOP_OVER(rb, rulebook) {
			TEMPORARY_TEXT(rbt);
			WRITE_TO(rbt, "%~W rulebook", rb->primary_name);
			Emit::array_text_entry(rbt);
			DISCARD_TEXT(rbt);
		}
	}
	Emit::array_end(save);
}

@h Parsing rulebook properties.
Rulebooks do not have properties as such. The syntax which would create these
creates rulebook variables instead, which are much more useful. However, we
do allow the following syntax:

>> Visibility rules have outcomes there is sufficient light (failure) and there is insufficient light (success).

where Inform sees that the subject ("visibility rules") is a rulebook, and
parses the object noun phrase with the following:

=
<rulebook-property> ::=
	outcome/outcomes <rulebook-outcome-list> |	==> TRUE
	default <rulebook-default-outcome>	|	==> FALSE
	...										==> @<Issue PM_NonOutcomeProperty problem@>

@<Issue PM_NonOutcomeProperty problem@> =
	*X = NOT_APPLICABLE;
	Problems::Issue::sentence_problem(_p_(PM_NonOutcomeProperty),
		"the only properties of a rulebook are its outcomes",
		"for the time being at least.");

@ =
outcomes *outcomes_being_parsed = NULL;

void Rulebooks::parse_properties(rulebook *rb, wording W) {
	outcomes_being_parsed = &(rb->my_outcomes);
	<rulebook-property>(W);
}

kind *Rulebooks::kind_from_context(void) {
	phrase *ph = phrase_being_compiled;
	rulebook *rb;
	if (ph == NULL) return NULL;
	LOOP_OVER(rb, rulebook)
		if (Rules::Bookings::list_contains_ph(rb->rule_list, ph))
			return Rulebooks::Outcomes::get_outcome_kind(&(rb->my_outcomes));
	return NULL;
}

@h Rules index.
The Rules page of the index is essentially a trawl through the more
popular rulebooks, showing their contents in logical order.

=
void Rulebooks::index_page(OUTPUT_STREAM, int n) {
	if (n == 1) {
		@<Index the segment for the main action rulebooks@>;
		@<Index the segment for the sequence of play rulebooks@>;
		@<Index the segment for the Understanding rulebooks@>;
		@<Index the segment for the description rulebooks@>;
		@<Index the segment for the accessibility rulebooks@>;
		@<Index the segment for the light and darkness rulebooks@>;
		@<Index the segment for the top-level rulebooks@>;
		@<Index the segment for the action processing rulebooks@>;
		@<Index the segment for the responses@>;
	} else {
		if (Rulebooks::noteworthy_rulebooks(NULL) > 0)
			@<Index the segment for new rulebooks and activities@>;
		extension_file *ef;
		LOOP_OVER(ef, extension_file)
			if (ef != standard_rules_extension)
				if (Rulebooks::noteworthy_rulebooks(ef) > 0)
					@<Index the segment for the rulebooks in this extension@>;
	}
}

@<Index the segment for the top-level rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>The top level</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("An Inform story file spends its whole time working through "
		"these three master rulebooks. They can be altered, just as all "
		"rulebooks can, but it's generally better to leave them alone.");
	HTML_CLOSE("p");
	Rulebooks::index_rules_box(OUT, "Startup rules", EMPTY_WORDING, NULL,
		built_in_rulebooks[STARTUP_RB], NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, STARTING_VIRTUAL_MACHINE_ACT, 2);
	Activities::index_by_number(OUT, PRINTING_BANNER_TEXT_ACT, 2);
	Rulebooks::index_rules_box(OUT, "Turn sequence rules", EMPTY_WORDING, NULL,
		built_in_rulebooks[TURN_SEQUENCE_RB], NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, CONSTRUCTING_STATUS_LINE_ACT, 2);
	Rulebooks::index_rules_box(OUT, "Shutdown rules", EMPTY_WORDING, NULL,
		built_in_rulebooks[SHUTDOWN_RB], NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, AMUSING_A_VICTORIOUS_PLAYER_ACT, 2);
	Activities::index_by_number(OUT, PRINTING_PLAYERS_OBITUARY_ACT, 2);
	Activities::index_by_number(OUT, DEALING_WITH_FINAL_QUESTION_ACT, 2);


@<Index the segment for the sequence of play rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Rules added to the sequence of play</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These rulebooks are the best places to put rules timed to happen "
		"at the start, at the end, or once each turn. (Each is run through at "
		"a carefully chosen moment in the relevant top-level rulebook.) It is "
		"also possible to have rules take effect at specific times of day "
		"or when certain events happen. Those are listed in the Scenes index, "
		"alongside rules taking place when scenes begin or end."); HTML_CLOSE("p");
	Rulebooks::index_rules_box(OUT, "When play begins", EMPTY_WORDING, I"rules_wpb",
		built_in_rulebooks[WHEN_PLAY_BEGINS_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Every turn", EMPTY_WORDING, I"rules_et",
		built_in_rulebooks[EVERY_TURN_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "When play ends", EMPTY_WORDING, I"rules_wpe",
		built_in_rulebooks[WHEN_PLAY_ENDS_RB], NULL, NULL, 1, TRUE);

@<Index the segment for the Understanding rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How commands are understood</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("'Understanding' here means turning a typed command, like GET FISH, "
		"into one or more actions, like taking the red herring. This is all handled "
		"by a single large rule (the parse command rule), but that rule makes use "
		"of the following activities and rulebooks in its work."); HTML_CLOSE("p");
	Rulebooks::index_rules_box(OUT, "Does the player mean", EMPTY_WORDING, I"rules_dtpm",
		built_in_rulebooks[DOES_THE_PLAYER_MEAN_RB], NULL, NULL, 1, TRUE);
	Activities::index_by_number(OUT, READING_A_COMMAND_ACT, 1);
	Activities::index_by_number(OUT, DECIDING_SCOPE_ACT, 1);
	Activities::index_by_number(OUT, DECIDING_CONCEALED_POSSESS_ACT, 1);
	Activities::index_by_number(OUT, DECIDING_WHETHER_ALL_INC_ACT, 1);
	Activities::index_by_number(OUT, CLARIFYING_PARSERS_CHOICE_ACT, 1);
	Activities::index_by_number(OUT, ASKING_WHICH_DO_YOU_MEAN_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_A_PARSER_ERROR_ACT, 1);
	Activities::index_by_number(OUT, SUPPLYING_A_MISSING_NOUN_ACT, 1);
	Activities::index_by_number(OUT, SUPPLYING_A_MISSING_SECOND_ACT, 1);
	Activities::index_by_number(OUT, IMPLICITLY_TAKING_ACT, 1);

@<Index the segment for the main action rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Rules governing actions</b>"); HTML_CLOSE("p");
	HTML_OPEN("p");
	WRITE("These rules are the ones which tell Inform how actions work, "
		"and which affect how they happen in particular cases.");
	HTML_CLOSE("p");
	Rulebooks::index_rules_box(OUT, "Persuasion", EMPTY_WORDING, I"rules_per",
		built_in_rulebooks[PERSUASION_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Unsuccessful attempt by", EMPTY_WORDING, I"rules_fail",
		built_in_rulebooks[UNSUCCESSFUL_ATTEMPT_BY_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Before", EMPTY_WORDING, I"rules_before",
		built_in_rulebooks[BEFORE_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Instead", EMPTY_WORDING, I"rules_instead",
		built_in_rulebooks[INSTEAD_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Check", EMPTY_WORDING, NULL, NULL, NULL,
		"Check rules are tied to specific actions, and there are too many "
		"to index here. For instance, the check taking rules can only ever "
		"affect the taking action, so they are indexed on the detailed index "
		"page for taking.", 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Carry out", EMPTY_WORDING, NULL, NULL, NULL,
		"Carry out rules are tied to specific actions, and there are too many "
		"to index here.", 1, TRUE);
	Rulebooks::index_rules_box(OUT, "After", EMPTY_WORDING, I"rules_after",
		built_in_rulebooks[AFTER_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Report", EMPTY_WORDING, NULL, NULL, NULL,
		"Report rules are tied to specific actions, and there are too many "
		"to index here.", 1, TRUE);

@<Index the segment for the action processing rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How actions are processed</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These form the technical machinery for dealing with actions, and are "
		"called on at least once every turn. They seldom need to be changed."); HTML_CLOSE("p");
	Rulebooks::index_rules_box(OUT, "Action-processing rules", EMPTY_WORDING, NULL,
		built_in_rulebooks[ACTION_PROCESSING_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Specific action-processing rules", EMPTY_WORDING, NULL,
		built_in_rulebooks[SPECIFIC_ACTION_PROCESSING_RB], NULL, NULL, 2, TRUE);
	Rulebooks::index_rules_box(OUT, "Player's action awareness rules", EMPTY_WORDING, NULL,
		built_in_rulebooks[PLAYERS_ACTION_AWARENESS_RB], NULL, NULL, 3, TRUE);

@<Index the segment for the responses@> =
	HTML_OPEN("p"); WRITE("<b>How responses are printed</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("The Standard Rules, and some extensions, reply to the player's "
		"commands with messages which are able to be modified."); HTML_CLOSE("p");
	Activities::index_by_number(OUT, PRINTING_RESPONSE_ACT, 1);

@<Index the segment for the accessibility rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How accessibility is judged</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These rulebooks are used when deciding who can reach what, and "
		"who can see what."); HTML_CLOSE("p");
	Rulebooks::index_rules_box(OUT, "Reaching inside", EMPTY_WORDING, I"rules_ri",
		built_in_rulebooks[REACHING_INSIDE_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Reaching outside", EMPTY_WORDING, I"rules_ri",
		built_in_rulebooks[REACHING_OUTSIDE_RB], NULL, NULL, 1, TRUE);
	Rulebooks::index_rules_box(OUT, "Visibility", EMPTY_WORDING, I"visibility",
		built_in_rulebooks[VISIBILITY_RB], NULL, NULL, 1, TRUE);

@<Index the segment for the light and darkness rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>Light and darkness</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These activities control how we describe darkness."); HTML_CLOSE("p");
	Activities::index_by_number(OUT, PRINTING_NAME_OF_DARK_ROOM_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_DESC_OF_DARK_ROOM_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_NEWS_OF_DARKNESS_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_NEWS_OF_LIGHT_ACT, 1);
	Activities::index_by_number(OUT, REFUSAL_TO_ACT_IN_DARK_ACT, 1);

@<Index the segment for the description rulebooks@> =
	HTML_OPEN("p"); WRITE("<b>How things are described</b>"); HTML_CLOSE("p");
	HTML_OPEN("p"); WRITE("These activities control what is printed when naming rooms or "
		"things, and their descriptions."); HTML_CLOSE("p");
	Activities::index_by_number(OUT, PRINTING_THE_NAME_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_THE_PLURAL_NAME_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_A_NUMBER_OF_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_ROOM_DESC_DETAILS_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_INVENTORY_DETAILS_ACT, 1);
	Activities::index_by_number(OUT, LISTING_CONTENTS_ACT, 1);
	Activities::index_by_number(OUT, GROUPING_TOGETHER_ACT, 1);
	Activities::index_by_number(OUT, WRITING_A_PARAGRAPH_ABOUT_ACT, 1);
	Activities::index_by_number(OUT, LISTING_NONDESCRIPT_ITEMS_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_LOCALE_DESCRIPTION_ACT, 1);
	Activities::index_by_number(OUT, CHOOSING_NOTABLE_LOCALE_OBJ_ACT, 1);
	Activities::index_by_number(OUT, PRINTING_LOCALE_PARAGRAPH_ACT, 1);

@<Index the segment for new rulebooks and activities@> =
	HTML_OPEN("p"); WRITE("<b>From the source text</b>"); HTML_CLOSE("p");
	extension_file *ef = NULL; /* that is, not in an extension at all */
	@<Index rulebooks occurring in this part of the source text@>;

@<Index the segment for the rulebooks in this extension@> =
	HTML_OPEN("p"); WRITE("<b>From the extension ");
	Extensions::IDs::write_to_HTML_file(OUT, Extensions::Files::get_eid(ef), FALSE);
	WRITE("</b>"); HTML_CLOSE("p");
	@<Index rulebooks occurring in this part of the source text@>;

@<Index rulebooks occurring in this part of the source text@> =
	activity *av;
	rulebook *rb;
	LOOP_OVER(rb, rulebook) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(rb->primary_name));
		if (rb->automatically_generated) continue;
		if (((ef == NULL) && (sf == NULL)) ||
			(SourceFiles::get_extension_corresponding(sf) == ef))
			Rulebooks::index_rules_box(OUT, NULL, rb->primary_name, NULL, rb, NULL, NULL, 1, TRUE);
	}
	LOOP_OVER(av, activity) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(av->name));
		if (((ef == NULL) && (sf == NULL)) ||
			(SourceFiles::get_extension_corresponding(sf) == ef))
			Activities::index(OUT, av, 1);
	}

@ =
int Rulebooks::noteworthy_rulebooks(extension_file *ef) {
	int nb = 0;
	activity *av;
	rulebook *rb;
	LOOP_OVER(rb, rulebook) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(rb->primary_name));
		if (rb->automatically_generated) continue;
		if (((ef == NULL) && (sf == NULL)) ||
			(SourceFiles::get_extension_corresponding(sf) == ef)) nb++;
	}
	LOOP_OVER(av, activity) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(av->name));
		if (((ef == NULL) && (sf == NULL)) ||
			(SourceFiles::get_extension_corresponding(sf) == ef)) nb++;
	}
	return nb;
}

void Rulebooks::index_scene(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("<b>The scene-changing machinery</b>"); HTML_CLOSE("p");
	Rulebooks::index_rules_box(OUT, "Scene changing", EMPTY_WORDING, NULL,
		built_in_rulebooks[SCENE_CHANGING_RB], NULL, NULL, 1, FALSE);
}

int unique_xtra_no = 0;
void Rulebooks::index_rules_box(OUTPUT_STREAM, char *name, wording W, text_stream *doc_link,
	rulebook *rb, activity *av, char *text, int indent, int hide_behind_plus) {
	int xtra_no = 0;
	if (rb) xtra_no = rb->allocation_id;
	else if (av) xtra_no = NUMBER_CREATED(rulebook) + av->allocation_id;
	else xtra_no = NUMBER_CREATED(rulebook) + NUMBER_CREATED(activity) + unique_xtra_no++;

	char *col = "e0e0e0";
	if (av) col = "e8e0c0";

	int n = 0;
	if (rb) n = Rulebooks::no_rules(rb);
	if (av) n = Activities::no_rules(av);

	TEMPORARY_TEXT(textual_name);
	if (name) WRITE_TO(textual_name, "%s", name);
	else if (Wordings::nonempty(W)) WRITE_TO(textual_name, "%+W", W);
	else WRITE_TO(textual_name, "nameless");
	string_position start = Str::start(textual_name);
	Str::put(start, Characters::tolower(Str::get(start)));

	if (hide_behind_plus) {
		HTMLFiles::open_para(OUT, indent+1, "tight");
		Index::extra_link(OUT, xtra_no);
		if (n == 0) HTML::begin_colour(OUT, I"808080");
		WRITE("%S", textual_name);
		@<Write the titling line of an index rules box@>;
		WRITE(" (%d rule%s)", n, (n==1)?"":"s");
		if (n == 0) HTML::end_colour(OUT);
		HTML_CLOSE("p");

		Index::extra_div_open(OUT, xtra_no, indent+1, col);
	} else {
		HTMLFiles::open_para(OUT, indent, "");
		HTML::open_coloured_box(OUT, col, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
	}

	HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
	HTML::first_html_column(OUT, 0);


	HTMLFiles::open_para(OUT, 1, "tight");
	WRITE("<b>%S</b>", textual_name);
	@<Write the titling line of an index rules box@>;
	HTML_CLOSE("p");

	HTML::next_html_column_right_justified(OUT, 0);

	HTMLFiles::open_para(OUT, 1, "tight");
	if (av) {
		TEMPORARY_TEXT(skeleton);
		WRITE_TO(skeleton, "Before %S:", textual_name);
		HTML::Javascript::paste_stream(OUT, skeleton);
		WRITE("&nbsp;<i>b</i> ");
		Str::clear(skeleton);
		WRITE_TO(skeleton, "Rule for %S:", textual_name);
		HTML::Javascript::paste_stream(OUT, skeleton);
		WRITE("&nbsp;<i>f</i> ");
		Str::clear(skeleton);
		WRITE_TO(skeleton, "After %S:", textual_name);
		HTML::Javascript::paste_stream(OUT, skeleton);
		WRITE("&nbsp;<i>a</i>");
		DISCARD_TEXT(skeleton);
	} else {
		HTML::Javascript::paste_stream(OUT, textual_name);
		WRITE("&nbsp;<i>name</i>");
	}
	HTML_CLOSE("p");
	DISCARD_TEXT(textual_name);

	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);

	if ((rb) && (Rulebooks::is_empty(rb, Rulebooks::no_rule_context())))
		text = "There are no rules in this rulebook.";
	if (text) {
		HTMLFiles::open_para(OUT, 2, "tight");
		WRITE("%s", text); HTML_CLOSE("p");
	} else {
		if (rb) {
			int ignore_me = 0;
			Rulebooks::index(OUT, rb, "", Rulebooks::no_rule_context(), &ignore_me);
		}
		if (av) Activities::index_details(OUT, av);
	}
	if (hide_behind_plus) {
		Index::extra_div_close(OUT, col);
	} else {
		HTML::close_coloured_box(OUT, col, ROUND_BOX_TOP+ROUND_BOX_BOTTOM);
		HTML_CLOSE("p");
	}
}

@<Write the titling line of an index rules box@> =
	if (Str::len(doc_link) > 0) Index::DocReferences::link(OUT, doc_link);
	WRITE(" ... ");
	if (av) WRITE(" activity"); else {
		if ((rb) && (Rulebooks::get_parameter_kind(rb)) &&
			(Kinds::Compare::eq(Rulebooks::get_parameter_kind(rb), K_action_name) == FALSE)) {
			WRITE(" ");
			Kinds::Textual::write_articled(OUT, Rulebooks::get_parameter_kind(rb));
			WRITE(" based");
		}
		WRITE(" rulebook");
	}
	int wn = -1;
	if (rb) wn = Wordings::first_wn(rb->primary_name);
	else if (av) wn = Wordings::first_wn(av->name);
	if (wn >= 0) Index::link(OUT, wn);
