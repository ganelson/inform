[Rulebooks::] Rulebooks.

Rulebooks collate rules and provide an organised way for them to collaborate
on a larger task.

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

	struct booking_list *contents; /* linked list of booked rules */

	struct stacked_variable_owner *owned_by_rb; /* rulebook variables owned here */
	struct stacked_variable_owner_list *accessible_from_rb; /* and which can be named here */

	struct rulebook_compilation_data compilation_data;
	struct rulebook_indexing_data indexing_data;
	CLASS_DEFINITION
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
	struct article *article_used;
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
	CLASS_DEFINITION
} placement_affecting;

@ As rulebooks are declared, the first few are quietly copied into
a small array: that way, we can always obtain a pointer to, say, the
turn sequence rules by looking up |built_in_rulebooks[TURN_SEQUENCE_RB]|.

@d MAX_BUILT_IN_RULEBOOKS 64

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
@d SHUTDOWN_RB 1 /* Shutdown rules */
@d TURN_SEQUENCE_RB 11 /* Turn sequence rules */
@d SCENE_CHANGING_RB 12 /* Scene changing rules */
@d WHEN_PLAY_BEGINS_RB 13 /* When play begins */
@d WHEN_PLAY_ENDS_RB 14 /* When play ends */
@d WHEN_SCENE_BEGINS_RB 15 /* When scene begins */
@d WHEN_SCENE_ENDS_RB 16 /* When scene ends */
@d EVERY_TURN_RB 17 /* Every turn */

@d ACTION_PROCESSING_RB 18 /* Action-processing rules */
@d SETTING_ACTION_VARIABLES_RB 19 /* Setting action variables rules */
@d SPECIFIC_ACTION_PROCESSING_RB 20 /* Specific action-processing rules */
@d PLAYERS_ACTION_AWARENESS_RB 21 /* Player's action awareness rules */

@d ACCESSIBILITY_RB 22 /* Accessibility rules */
@d REACHING_INSIDE_RB 23 /* Reaching inside rules */
@d REACHING_OUTSIDE_RB 24 /* Reaching outside rules */
@d VISIBILITY_RB 25 /* Visibility rules */

@d PERSUASION_RB 26 /* Persuasion rules */
@d UNSUCCESSFUL_ATTEMPT_BY_RB 27 /* Unsuccessful attempt by */

@d BEFORE_RB 28 /* Before rules */
@d INSTEAD_RB 29 /* Instead rules */
@d CHECK_RB 30 /* Check */
@d CARRY_OUT_RB 31 /* Carry out rules */
@d AFTER_RB 32 /* After rules */
@d REPORT_RB 33 /* Report */

@d DOES_THE_PLAYER_MEAN_RB 34 /* Does the player mean...? rules */
@d MULTIPLE_ACTION_PROCESSING_RB 35 /* For changing or reordering multiple actions */

@h Construction.
When a rulebook is to be created, we do a little treatment on its name. We
remove any article, and also strip off the suffix "rules" or "rulebook"
as redundant -- see below for why. Since we want to insure that phrase/rule
preambles are unambiguous, we also want to make sure that keywords introducing
phrase definitions and timed events don't open the rulebook name.

=
<new-rulebook-name> ::=
	<definite-article> <new-rulebook-name> |    ==> { pass 2 }
	<new-rulebook-name> rules/rulebook |    ==> { pass 1 }
	at *** |    ==> @<Issue PM_RulebookWithAt problem@>
	to *** |    ==> @<Issue PM_RulebookWithTo problem@>
	definition *** |    ==> @<Issue PM_RulebookWithDefinition problem@>
	...											==> { 0, - }

@<Issue PM_RulebookWithAt problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RulebookWithAt),
		"this would create a rulebook whose name begins with 'at'",
		"which is forbidden since it would lead to ambiguities in "
		"the way people write rules. A rule beginning with 'At' "
		"is one which happens at a given time, whereas a rule "
		"belonging to a rulebook starts with the name of that "
		"rulebook, so a rulebook named 'at ...' would make such "
		"a rule inscrutable.");

@<Issue PM_RulebookWithTo problem@> =
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RulebookWithTo),
			"this would create a rulebook whose name begins with 'to'",
			"which is forbidden since it would lead to ambiguities in "
			"the way people write rules. A rule beginning with 'To' "
			"is one which defines a phrase, whereas a rule "
			"belonging to a rulebook starts with the name of that "
			"rulebook, so a rulebook named 'to ...' would make such "
			"a rule inscrutable.");

@<Issue PM_RulebookWithDefinition problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RulebookWithDefinition),
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

	rb->contents = BookingLists::new();

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

	rb->owned_by_rb = StackedVariables::new_owner(rb->allocation_id);
	rb->accessible_from_rb = StackedVariables::add_owner_to_list(NULL, rb->owned_by_rb);

	rb->compilation_data =  RTRules::new_rulebook_compilation_data(rb, R);
	rb->indexing_data =  IXRules::new_rulebook_indexing_data(rb);

	if (rb->allocation_id < MAX_BUILT_IN_RULEBOOKS)
		built_in_rulebooks[rb->allocation_id] = rb;

	if (rb == built_in_rulebooks[ACTION_PROCESSING_RB])
		all_action_processing_vars = StackedVariables::add_owner_to_list(NULL, rb->owned_by_rb);

	Nouns::new_proper_noun(rb->primary_name, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb), Task::language_of_syntax());
	word_assemblage wa =
		PreformUtilities::merge(<rulebook-name-construction>, 0,
			WordAssemblages::from_wording(rb->primary_name));
	wording AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb), Task::language_of_syntax());
	wa = PreformUtilities::merge(<rulebook-name-construction>, 1,
			WordAssemblages::from_wording(rb->primary_name));
	AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb), Task::language_of_syntax());

	return rb;
}

outcomes *Rulebooks::get_outcomes(rulebook *rb) {
	return &(rb->my_outcomes);
}

kind *Rulebooks::contains_kind(rulebook *rb) {
	return Kinds::binary_con(CON_rule,
		Rulebooks::get_parameter_kind(rb),
		Rulebooks::Outcomes::get_outcome_kind(&(rb->my_outcomes)));
}

kind *Rulebooks::to_kind(rulebook *rb) {
	return Kinds::binary_con(CON_rulebook,
		Rulebooks::get_parameter_kind(rb),
		Rulebooks::Outcomes::get_outcome_kind(&(rb->my_outcomes)));
}

rulebook *Rulebooks::new_automatic(wording W, kind *basis,
	int oc, int ata, int ubfaa, int rda, package_request *R) {
	rulebook *rb = Rulebooks::new(
		Kinds::binary_con(CON_rulebook, basis, K_void), W, R);
	Rulebooks::Outcomes::set_default_outcome(&(rb->my_outcomes), oc);
	Rulebooks::Outcomes::set_focus_ata(&(rb->my_focus), ata);
	rb->automatically_generated = TRUE;
	rb->used_by_future_action_activity = ubfaa;
	rb->runs_during_activities = rda;
	return rb;
}

void Rulebooks::set_alt_name(rulebook *rb, wording AW) {
	rb->alternative_name = AW;
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(rb), Task::language_of_syntax());
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
	return BookingLists::is_contextually_empty(rb->contents, rc);
}

int Rulebooks::no_rules(rulebook *rb) {
	if (rb == NULL) return 0;
	return BookingLists::length(rb->contents);
}

int Rulebooks::rule_in_rulebook(rule *R, rulebook *rb) {
	if (rb == NULL) return FALSE;
	return BookingLists::contains(rb->contents, R);
}

booking *Rulebooks::first_booking(rulebook *rb) {
	if (rb == NULL) return NULL;
	return BookingLists::first(rb->contents);
}

int Rulebooks::runs_during_activities(rulebook *rb) {
	return rb->runs_during_activities;
}

@h Rulebook variables.
Any new rulebook variable name is vetted by being run through this:

=
<rulebook-variable-name> ::=
	<unfortunate-name> |    ==> @<Issue PM_RulebookVariableAnd problem@>
	...										==> { TRUE, - }

@<Issue PM_RulebookVariableAnd problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RulebookVariableAnd));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for a rulebook - a value associated "
		"with a rulebook and which has a name. The request seems to "
		"say that the name in question is '%2', but I'd prefer to "
		"avoid 'and', 'or', 'with', or 'having' in such names, please.");
	Problems::issue_problem_end();
	==> { NOT_APPLICABLE, - };

@ =
void Rulebooks::add_variable(rulebook *rb, parse_node *cnode) {
	if (Node::get_type(cnode) != PROPERTYCALLED_NT) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RulebookVarUncalled));
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

	if (<rulebook-variable-name>(Node::get_text(cnode->down->next))) {
		if (<<r>> == NOT_APPLICABLE) return;
	}

	parse_node *spec = NULL;
	if (<s-type-expression>(Node::get_text(cnode->down))) spec = <<rp>>;

	if ((Specifications::is_description(spec)) &&
		(Descriptions::is_qualified(spec))) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RulebookVariableTooSpecific));
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
	if (Node::is(spec, CONSTANT_NT)) {
		LOG("Offending SP: $T", spec);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RulebookVariableBadKind));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not the name of a kind of "
			"value which I know (such as 'number' or 'text').");
		Problems::issue_problem_end();
		return;
	}

	kind *K = Specifications::to_kind(spec);
	if (K == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RulebookVariableKindless));
		Problems::issue_problem_segment(
			"You wrote %1, but I was expecting to see a kind of value there, "
			"and '%2' isn't something I recognise as a kind.");
		Problems::issue_problem_end();
		return;
	}

	if (Kinds::eq(K, K_value)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RulebookVariableVague));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a variable is a 'value' "
			"does not give me a clear enough idea what it will hold. "
			"You need to say what kind of value: for instance, 'A door "
			"has a number called street address.' is allowed because "
			"'number' is specific about the kind of value.");
		Problems::issue_problem_end();
		return;
	}

	StackedVariables::add_empty(rb->owned_by_rb, Node::get_text(cnode->down->next), K);
}

void Rulebooks::make_stvs_accessible(rulebook *rb, stacked_variable_owner *stvo) {
	rb->accessible_from_rb = StackedVariables::add_owner_to_list(rb->accessible_from_rb, stvo);
}

@h Indexing and logging rulebooks.

=
void Rulebooks::log_name_only(rulebook *rb) {
	LOG("Rulebook %d (%W)", rb->allocation_id, rb->primary_name);
}

void Rulebooks::log(rulebook *rb) {
	Rulebooks::log_name_only(rb);
	LOG(": ");
	BookingLists::log(rb->contents);
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
	if (rm.matched_rulebook == NULL) { ==> { fail nonterminal }; }
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
	<indefinite-article> <rulebook-stem-inner-unarticled> |  ==> { 0, RP[1], <<place>> = R[2] }
	<definite-article> <rulebook-stem-inner-unarticled> |    ==> { 0, RP[1], <<place>> = R[2] }
	<rulebook-stem-inner-unarticled>                         ==> { 0, NULL, <<place>> = R[1] }

<rulebook-stem-inner-unarticled> ::=
	rule for/about/on <rulebook-stem-name> |  ==> { MIDDLE_PLACEMENT, -, <<len>> = R[1] }
	rule <rulebook-stem-name> |               ==> { MIDDLE_PLACEMENT, -, <<len>> = R[1] }
	first rule <rulebook-stem-name> |         ==> { FIRST_PLACEMENT, -, <<len>> = R[1] }
	first <rulebook-stem-name> |              ==> { FIRST_PLACEMENT, -, <<len>> = R[1] }
	last rule <rulebook-stem-name> |          ==> { LAST_PLACEMENT, -, <<len>> = R[1] }
	last <rulebook-stem-name> |               ==> { LAST_PLACEMENT, -, <<len>> = R[1] }
	<rulebook-stem-name>                      ==> { MIDDLE_PLACEMENT, -, <<len>> = R[1] }

<rulebook-stem-name> ::=
	{when ... begins} |  ==> { 2, -, <<rulebook:m>> = built_in_rulebooks[WHEN_SCENE_BEGINS_RB] }
	{when ... ends} |    ==> { 2, -, <<rulebook:m>> = built_in_rulebooks[WHEN_SCENE_ENDS_RB] }
	...                  ==> { 0, -, <<rulebook:m>> = NULL }

@ =
rulebook_match Rulebooks::rb_match_from_description(wording W) {
	int initial_w1 = Wordings::first_wn(W), modifier_words;
	int pl = MIDDLE_PLACEMENT;
	rulebook *rb;
	rulebook_match rm;

	<rulebook-stem-inner>(W);
	W = GET_RW(<rulebook-stem-name>, 1);
	article_usage *au = (article_usage *) <<rp>>; pl = <<place>>;

	modifier_words = Wordings::first_wn(W) - initial_w1;

	rm.match_length = 0;
	rm.advance_words = 0;
	rm.match_from = initial_w1;
	rm.tail_words = 0;
	rm.matched_rulebook = NULL;
	rm.article_used = (au)?(au->article_used):NULL;
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

	if (RuleBookings::get_rule(the_new_rule) == ref_rule) {
		if (side != INSTEAD_SIDE)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BeforeOrAfterSelf),
				"a rule can't be before or after itself",
				"so this makes no sense to me.");
		return;
	}

	#ifdef IF_MODULE
	if ((rb == built_in_rulebooks[BEFORE_RB]) ||
		(rb == built_in_rulebooks[AFTER_RB]) ||
		(rb == built_in_rulebooks[INSTEAD_RB])) {
		phrase *ph = Rules::get_defn_as_phrase(RuleBookings::get_rule(the_new_rule));
		if (ph) {
			action_name *an = Phrases::Context::required_action(&(ph->runtime_context_data));
			if ((an) && (ActionSemantics::is_out_of_world(an)))
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OOWinIWRulebook),
					"this rulebook has no effect on actions which happen out of world",
					"so I'm not going to let you file this rule in it. ('Check', "
					"'Carry out' and 'Report' work fine for out of world actions: "
					"but 'Before', 'Instead' and 'After' have no effect on them.)");
		}
	}


	if (rb == built_in_rulebooks[SETTING_ACTION_VARIABLES_RB]) {
		Rules::set_never_test_actor(RuleBookings::get_rule(the_new_rule));
	} else {
		Rulebooks::Outcomes::modify_rule_to_suit_focus(&(rb->my_focus),
			RuleBookings::get_rule(the_new_rule));
	}

	if (side == INSTEAD_SIDE) {
		LOGIF(RULE_ATTACHMENTS,
			"Copying actor test flags from rule being replaced\n");
		Rules::copy_actor_test_flags(RuleBookings::get_rule(the_new_rule), ref_rule);
		LOGIF(RULE_ATTACHMENTS,
			"Copying former rulebook's variable permissions to displaced rule\n");
		Rules::put_variables_in_scope(ref_rule, rb->accessible_from_rb);
		if (Rulebooks::focus(rb) == ACTION_FOCUS)
			Rules::put_action_variables_in_scope(ref_rule);
	}
	#endif

	Rules::put_variables_in_scope(RuleBookings::get_rule(the_new_rule), rb->accessible_from_rb);
	if (Rulebooks::focus(rb) == ACTION_FOCUS)
		Rules::put_action_variables_in_scope(RuleBookings::get_rule(the_new_rule));
	if (rb->fragmentation_stem_length > 0)
		Rules::suppress_action_testing(RuleBookings::get_rule(the_new_rule));

	Phrases::Context::ensure_avl(RuleBookings::get_rule(the_new_rule));

	BookingLists::add(rb->contents, the_new_rule, placing, side, ref_rule);
	LOGIF(RULE_ATTACHMENTS, "Rulebook after attachment: $K", rb);
}

void Rulebooks::detach_rule(rulebook *rb, rule *the_new_rule) {
	BookingLists::remove(rb->contents, the_new_rule);
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
	outcome/outcomes <rulebook-outcome-list> |    ==> { TRUE, - }
	default <rulebook-default-outcome>	|    ==> { FALSE, - }
	...										==> @<Issue PM_NonOutcomeProperty problem@>

@<Issue PM_NonOutcomeProperty problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonOutcomeProperty),
		"the only properties of a rulebook are its outcomes",
		"for the time being at least.");
	==> { NOT_APPLICABLE, - };

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
		if (BookingLists::contains_ph(rb->contents, ph))
			return Rulebooks::Outcomes::get_outcome_kind(&(rb->my_outcomes));
	return NULL;
}

@ In order to parse sentences about how rules are placed in rulebooks, we
need to be able to parse the relevant names. (The definite article can
optionally be used.)

=
<rulebook-name> internal {
	W = Articles::remove_the(W);
	parse_node *p = Lexicon::retrieve(RULEBOOK_MC, W);
	if (Rvalues::is_CONSTANT_construction(p, CON_rulebook)) {
		==> { -, Rvalues::to_rulebook(p) };
		return TRUE;
	}
	==> { fail nonterminal };
}
