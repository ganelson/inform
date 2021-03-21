[Rulebooks::] Rulebooks.

Rulebooks collate rules and provide an organised way for them to collaborate
on a larger task.

@h Introduction.
We think of a rulebook as being a list of rules, for which see the code in
//Booking Lists//, but it also has a good deal of metadata. Handling that
metadata, and managing the creation of rulebooks, are the tasks here.

The semantics of rulebooks grew from their original mid-00s design of being
simple action-focused sets of game rules (for interactive fiction) to a point
in 2009 where they could essentially perform anything which a function in a
functional programming language such as Haskell could do. Their original
game-based purpose nevertheless still shows through in places, as with the
quaint idea of having enumerated ways in which they finish (see //outcomes//).

=
typedef struct rulebook {
	struct wording primary_name; /* name in source text */
	struct wording alternative_name; /* alternative form of name */
	int action_stem_length; /* to do with parsing, but 0 for most rulebooks */

	struct booking_list *contents; /* the actual rules in the rulebook */

	struct focus my_focus; /* what does the rulebook work on? */
	struct outcomes my_outcomes; /* how can it end? */

	int automatically_generated; /* rather than by explicit Inform 7 source text */
	int runs_during_activities; /* allow "while..." clauses to name these */
	int used_by_future_action_activity; /* like "deciding the scope of something..." */

	struct stacked_variable_owner *my_variables; /* rulebook variables owned here */
	struct stacked_variable_owner_list *accessible_variables; /* and which can be named here */

	struct rulebook_compilation_data compilation_data;
	struct rulebook_indexing_data indexing_data;
	CLASS_DEFINITION
} rulebook;

@ The following creates one:

=
rulebook *Rulebooks::new(kind *create_as, wording W, package_request *R) {
	Hierarchy::markup_wording(R, RULEBOOK_NAME_HMD, W);

	rulebook *B = CREATE(rulebook);
	Rulebooks::set_std(B);

	<new-rulebook-name>(W);
	B->primary_name = GET_RW(<new-rulebook-name>, 1);
	B->alternative_name = EMPTY_WORDING;
	B->action_stem_length = 0;

	B->contents = BookingLists::new();

	B->automatically_generated = FALSE;
	B->used_by_future_action_activity = FALSE;
	B->runs_during_activities = FALSE;

	@<Work out the focus and outcome@>;

	B->my_variables = StackedVariables::new_owner(B->allocation_id);
	B->accessible_variables = StackedVariables::add_owner_to_list(NULL, B->my_variables);

	B->compilation_data =  RTRules::new_rulebook_compilation_data(B, R);
	B->indexing_data =  IXRules::new_rulebook_indexing_data(B);

	@<Make proper nouns so that the rulebook can be a constant value@>;
	return B;
}

@ We must check the supplied (primary) name for sanity:

=
<new-rulebook-name> ::=
	<definite-article> <new-rulebook-name> |  ==> { pass 2 }
	<new-rulebook-name> rules/rulebook |      ==> { pass 1 }
	at *** |                                  ==> @<Issue PM_RulebookWithAt problem@>
	to *** |                                  ==> @<Issue PM_RulebookWithTo problem@>
	definition *** |                          ==> @<Issue PM_RulebookWithDefinition problem@>
	...                                       ==> { -, - }

@<Issue PM_RulebookWithAt problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RulebookWithAt),
		"this would create a rulebook whose name begins with 'at'",
		"which is forbidden since it would lead to ambiguities in the way people write "
		"rules. A rule beginning with 'At' is one which happens at a given time, whereas "
		"a rule belonging to a rulebook starts with the name of that rulebook, so a "
		"rulebook named 'at ...' would make such a rule inscrutable.");

@<Issue PM_RulebookWithTo problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RulebookWithTo),
		"this would create a rulebook whose name begins with 'to'",
		"which is forbidden since it would lead to ambiguities in the way people write "
		"rules. A rule beginning with 'To' is one which defines a phrase, whereas a rule "
		"belonging to a rulebook starts with the name of that rulebook, so a rulebook "
		"named 'to ...' would make such a rule inscrutable.");

@<Issue PM_RulebookWithDefinition problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RulebookWithDefinition),
		"this would create a rulebook whose name begins with 'definition'",
		"which is forbidden since it would lead to ambiguities in the way people write "
		"rules. A rule beginning with 'Definition' is one which defines an adjective, "
		"whereas a rule belonging to a rulebook starts with the name of that rulebook, so "
		"a rulebook named 'to ...' would make such a rule inscrutable.");

@<Work out the focus and outcome@> =
	kind *parameter_kind = NULL;
	kind *producing_kind = NULL;
	Kinds::binary_construction_material(create_as, &parameter_kind, &producing_kind);

	Rulebooks::Outcomes::initialise_focus(&(B->my_focus), parameter_kind);

	int def = NO_OUTCOME;
	if (B == Rulebooks::std(INSTEAD_RB)) def = FAILURE_OUTCOME;
	if (B == Rulebooks::std(AFTER_RB)) def = SUCCESS_OUTCOME;
	if (B == Rulebooks::std(UNSUCCESSFUL_ATTEMPT_BY_RB)) def = SUCCESS_OUTCOME;
	Rulebooks::Outcomes::initialise_outcomes(&(B->my_outcomes), producing_kind, def);

@ Focus and outcome are roughly the $X$ and $Y$ if we think of a rulebook as
being analogous to a function $X\to Y$. 

=
int Rulebooks::focus(rulebook *B) {
	return Rulebooks::Outcomes::get_focus(&(B->my_focus));
}

kind *Rulebooks::get_focus_kind(rulebook *B) {
	return Rulebooks::Outcomes::get_focus_parameter_kind(&(B->my_focus));
}

kind *Rulebooks::get_outcome_kind(rulebook *B) {
	return Rulebooks::Outcomes::get_outcome_kind(&(B->my_outcomes));
}

outcomes *Rulebooks::get_outcomes(rulebook *B) {
	return &(B->my_outcomes);
}

@ During the period when a phrase from a rule in a rulebook is being compiled,
this rather clumsily finds out its return kind. Ideally we would get rid of
the need for this.

=
kind *Rulebooks::kind_from_context(void) {
	rulebook *B;
	if (phrase_being_compiled)
		LOOP_OVER(B, rulebook)
			if (BookingLists::contains_ph(B->contents, phrase_being_compiled))
				return Rulebooks::get_outcome_kind(B);
	return NULL;
}

@ While focus and outcome are each more involved than just being a kind of
value, we reduce them to that when working out the kind of a rulebook and
of the rules in it:

=
kind *Rulebooks::to_kind(rulebook *B) {
	return Kinds::binary_con(CON_rulebook,
		Rulebooks::get_focus_kind(B), Rulebooks::get_outcome_kind(B));
}

kind *Rulebooks::contains_kind(rulebook *B) {
	return Kinds::binary_con(CON_rule,
		Rulebooks::get_focus_kind(B), Rulebooks::get_outcome_kind(B));
}

@ Unsurprisingly, the (primary) name for a rulebook becomes a noun which can be
referred to in Inform 7 source text. In fact two alternative forms of this noun
are also created, which are both synonyms for it. Thus if a "coordination"
rulebook is created, it can be referred to as any of "coordination", "coordination rules"
or "coordination rulebook":

=
<rulebook-name-construction> ::=
	... rules |
	... rulebook

@<Make proper nouns so that the rulebook can be a constant value@> =
	Nouns::new_proper_noun(B->primary_name, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(B), Task::language_of_syntax());
	word_assemblage wa =
		PreformUtilities::merge(<rulebook-name-construction>, 0,
			WordAssemblages::from_wording(B->primary_name));
	wording AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(B), Task::language_of_syntax());
	wa = PreformUtilities::merge(<rulebook-name-construction>, 1,
			WordAssemblages::from_wording(B->primary_name));
	AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(B), Task::language_of_syntax());

@ It can also subsequently be given a further or "alternative" name, and that
too becomes a proper noun, but is not run through <rulebook-name-construction>
to make still further variants. So the rulebook has at most four different
names, one more than cats have.

=
void Rulebooks::set_alt_name(rulebook *B, wording AW) {
	B->alternative_name = AW;
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		RULEBOOK_MC, Rvalues::from_rulebook(B), Task::language_of_syntax());
}

@ And these up to four nouns can be matched with the following nonterminal.

The process of noticing rulebook names inside parts of rule names is much
more complex -- see //Rulebooks::rb_match_from_description// below.

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

@ "Automatic" rulebooks sound fancy, but there's very little going on here.
These are created as a knock-on effect of something else being created: for
example if the source text creates an action, then rulebooks for processing
that action are automatically created, and similarly for activities and scenes.

=
rulebook *Rulebooks::new_automatic(wording W, kind *basis,
	int default_outcome, int always_test_actor, int ubfaa, int for_activities,
	int stem_length, package_request *R) {
	rulebook *B = Rulebooks::new(Kinds::binary_con(CON_rulebook, basis, K_void), W, R);
	Rulebooks::Outcomes::set_default_outcome(&(B->my_outcomes), default_outcome);
	Rulebooks::Outcomes::set_focus_ata(&(B->my_focus), always_test_actor);
	B->automatically_generated = TRUE;
	B->used_by_future_action_activity = ubfaa;
	B->runs_during_activities = for_activities;
	B->action_stem_length = stem_length;
	return B;
}

@h Access.

=
int Rulebooks::used_by_future_actions(rulebook *B) {
	return B->used_by_future_action_activity;
}

int Rulebooks::requires_specific_action(rulebook *B) {
	if (B == Rulebooks::std(CHECK_RB)) return TRUE;
	if (B == Rulebooks::std(CARRY_OUT_RB)) return TRUE;
	if (B == Rulebooks::std(REPORT_RB)) return TRUE;
	if (B->action_stem_length > 0) return TRUE;
	return FALSE;
}

int Rulebooks::is_empty(rulebook *B, rule_context rc) {
	if (B == NULL) return TRUE;
	return BookingLists::is_contextually_empty(B->contents, rc);
}

int Rulebooks::no_rules(rulebook *B) {
	if (B == NULL) return 0;
	return BookingLists::length(B->contents);
}

int Rulebooks::rule_in_rulebook(rule *R, rulebook *B) {
	if (B == NULL) return FALSE;
	return BookingLists::contains(B->contents, R);
}

booking *Rulebooks::first_booking(rulebook *B) {
	if (B == NULL) return NULL;
	return BookingLists::first(B->contents);
}

int Rulebooks::runs_during_activities(rulebook *B) {
	return B->runs_during_activities;
}

@h Logging.
Just to name it, or giving an inventory of the contents.

=
void Rulebooks::log_name_only(rulebook *B) {
	LOG("Rulebook %d (%W)", B->allocation_id, B->primary_name);
}

void Rulebooks::log(rulebook *B) {
	Rulebooks::log_name_only(B);
	LOG(": ");
	BookingLists::log(B->contents);
}

@h Rulebook variables.
This function is called in response to a sentence like "The consideration rulebook
has a D called W":

=
void Rulebooks::add_variable(rulebook *B, parse_node *cnode) {
	@<The variable has to have a name@>;
	wording D = Node::get_text(cnode->down);
	wording W = Node::get_text(cnode->down->next);

	@<The variable name must be fortunate@>;

	parse_node *spec = NULL;
	if (<s-type-expression>(D)) spec = <<rp>>;

	@<Its description cannot be qualified@>;
	@<Its description cannot be a constant name@>;

	kind *K = Specifications::to_kind(spec);
	@<In fact, its description has to be a kind@>;
	@<And a definite one at that@>;

	StackedVariables::add_empty(B->my_variables, W, K);
}

@<The variable has to have a name@> =
	if (Node::get_type(cnode) != PROPERTYCALLED_NT) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_RulebookVarUncalled));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named variable "
			"for an rulebook - a value associated with a action and which has a name. "
			"But since you only give a kind, not a name, I'm stuck. ('The every turn "
			"rulebook has a number called importance' is right, 'The every turn rulebook "
			"has a number' is too vague.)");
		Problems::issue_problem_end();
		return;
	}

@<The variable name must be fortunate@> =
	if (<unfortunate-name>(W)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_RulebookVariableAnd));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named variable "
			"for a rulebook - a value associated with a rulebook and which has a name. "
			"The request seems to say that the name in question is '%2', but I'd prefer "
			"to avoid 'and', 'or', 'with', or 'having' in such names, please.");
		Problems::issue_problem_end();
		return;
	}

@<Its description cannot be qualified@> =
	if ((Specifications::is_description(spec)) &&
		(Descriptions::is_qualified(spec))) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, D);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_RulebookVariableTooSpecific));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named variable "
			"for a rulebook - a value associated with a rulebook and which has a name. "
			"The request seems to say that the value in question is '%2', but this is "
			"too specific a description. (Instead, a kind of value (such as 'number') or "
			"a kind of object (such as 'room' or 'thing') should be given. To get a "
			"property whose contents can be any kind of object, use 'object'.)");
		Problems::issue_problem_end();
		return;
	}

@<Its description cannot be a constant name@> =
	if (Node::is(spec, CONSTANT_NT)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, D);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_RulebookVariableBadKind));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not the name of a kind of value which I know "
			"(such as 'number' or 'text').");
		Problems::issue_problem_end();
		return;
	}

@<In fact, its description has to be a kind@> =
	if (K == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, D);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_RulebookVariableKindless));
		Problems::issue_problem_segment(
			"You wrote %1, but I was expecting to see a kind of value there, and '%2' "
			"isn't something I recognise as a kind.");
		Problems::issue_problem_end();
		return;
	}

@<And a definite one at that@> =
	if (Kinds::Behaviour::definite(K) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, D);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_RulebookVariableVague));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a variable is something as vague as this does "
			"not give me a clear enough idea what it will hold. You need to say what kind "
			"of value: for instance, 'A door has a number called street address.' is "
			"allowed because 'number' is specific about the kind of value.");
		Problems::issue_problem_end();
		return;
	}

@ Rulebooks can also be given access to other sets of variables which are
defined somewhere else -- but they still don't belong to |B|, so they do not
go into |B->my_variables|.

=
void Rulebooks::grant_access_to_variables(rulebook *B, stacked_variable_owner *set) {
	B->accessible_variables =
		StackedVariables::add_owner_to_list(B->accessible_variables, set);
}

@h Attaching and detaching rules.
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

=
void Rulebooks::attach_rule(rulebook *B, booking *br,
	int placing, int side, rule *ref_rule) {
	LOGIF(RULE_ATTACHMENTS, "Attaching booking $b to rulebook $K", br, B);

	rule *R = RuleBookings::get_rule(br);

	if ((R == ref_rule) && (side != INSTEAD_SIDE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_BeforeOrAfterSelf),
			"a rule can't be before or after itself",
			"so this makes no sense to me.");
		return;
	}

	PluginCalls::rule_placement_notify(R, B, side, ref_rule);

	Rules::put_variables_in_scope(R, B->accessible_variables);
	if (side == INSTEAD_SIDE) {
		LOGIF(RULE_ATTACHMENTS,
			"Copying former rulebook's variable permissions to displaced rule\n");
		Rules::put_variables_in_scope(ref_rule, B->accessible_variables);
	}

	Phrases::Context::ensure_avl(R);

	BookingLists::add(B->contents, br, placing, side, ref_rule);
	LOGIF(RULE_ATTACHMENTS, "Rulebook after attachment: $K", B);
}

@ This at least is easy:

=
void Rulebooks::detach_rule(rulebook *B, rule *R) {
	BookingLists::remove(B->contents, R);
}

@h Name parsing of rulebooks.
The following internal finds the "stem" of a rule, that is, the part
which identifies which rulebook it will go into. For example, in

>> Before printing the name of the peach: ...
>> Instead of eating: ...

the stems are "before printing the name" and "instead". It makes use
of <rulebook-stem-inner> below, and then does some direct parsing.

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

@ =
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
	<indefinite-article> <rulebook-stem-inner-unarticled> |  ==> { R[2], RP[1] }
	<definite-article> <rulebook-stem-inner-unarticled> |    ==> { R[2], RP[1] }
	<rulebook-stem-inner-unarticled>                         ==> { R[1], NULL }

<rulebook-stem-inner-unarticled> ::=
	rule for/about/on <rulebook-stem-name> |  ==> { MIDDLE_PLACEMENT, -, <<len>> = R[1] }
	rule <rulebook-stem-name> |               ==> { MIDDLE_PLACEMENT, -, <<len>> = R[1] }
	first rule <rulebook-stem-name> |         ==> { FIRST_PLACEMENT, -, <<len>> = R[1] }
	first <rulebook-stem-name> |              ==> { FIRST_PLACEMENT, -, <<len>> = R[1] }
	last rule <rulebook-stem-name> |          ==> { LAST_PLACEMENT, -, <<len>> = R[1] }
	last <rulebook-stem-name> |               ==> { LAST_PLACEMENT, -, <<len>> = R[1] }
	<rulebook-stem-name>                      ==> { MIDDLE_PLACEMENT, -, <<len>> = R[1] }

<rulebook-stem-name> ::=
	{when ... begins} |  ==> { 2, -, <<rulebook:m>> = Rulebooks::std(WHEN_SCENE_BEGINS_RB) }
	{when ... ends} |    ==> { 2, -, <<rulebook:m>> = Rulebooks::std(WHEN_SCENE_ENDS_RB) }
	...                  ==> { 0, -, <<rulebook:m>> = NULL }

@ =
rulebook_match Rulebooks::rb_match_from_description(wording W) {
	int initial_w1 = Wordings::first_wn(W), modifier_words;
	int pl = MIDDLE_PLACEMENT;
	rulebook *rb;
	rulebook_match rm;

	<rulebook-stem-inner>(W);
	W = GET_RW(<rulebook-stem-name>, 1);
	article_usage *au = (article_usage *) <<rp>>; pl = <<r>>;

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

	if (rm.matched_rulebook->action_stem_length) {
		int w1a = Wordings::first_wn(W) + rm.match_length - 1;
		if (w1a != Wordings::last_wn(W))
			rm.match_length = rm.matched_rulebook->action_stem_length;
	}

	rm.match_length += modifier_words;
	rm.advance_words += modifier_words;
	return rm;
}

@h Standard rulebooks.
A few rulebooks are special to Inform, in that they have built-in support either
from the compiler, or from one of the kits, or both. The list below looks long,
but actually most of these are special only in that they are shown in their
own part of the Index; it's not that the compiler treats them differently from
other rulebooks.

These are recognised by the order in which they are declared, which makes it
crucial not to change that order in //basic_inform: Miscellaneous Definitions//
and //standard_rules: Physical World Model// without making matching changes
both here and in //BasicInformKit// and //WorldModelKit//. So: don't casually
change the following numbers.

Note that in the world of Basic Inform only, none of these will exist except
for the first two.

@d STARTUP_RB                     0 /* Startup rules */
@d SHUTDOWN_RB                    1 /* Shutdown rules */

@d TURN_SEQUENCE_RB              11 /* Turn sequence rules */
@d SCENE_CHANGING_RB             12 /* Scene changing rules */
@d WHEN_PLAY_BEGINS_RB           13 /* When play begins */
@d WHEN_PLAY_ENDS_RB             14 /* When play ends */
@d WHEN_SCENE_BEGINS_RB          15 /* When scene begins */
@d WHEN_SCENE_ENDS_RB            16 /* When scene ends */
@d EVERY_TURN_RB                 17 /* Every turn */
@d ACTION_PROCESSING_RB          18 /* Action-processing rules */
@d SETTING_ACTION_VARIABLES_RB   19 /* Setting action variables rules */
@d SPECIFIC_ACTION_PROCESSING_RB 20 /* Specific action-processing rules */
@d PLAYERS_ACTION_AWARENESS_RB   21 /* Player's action awareness rules */
@d ACCESSIBILITY_RB              22 /* Accessibility rules */
@d REACHING_INSIDE_RB            23 /* Reaching inside rules */
@d REACHING_OUTSIDE_RB           24 /* Reaching outside rules */
@d VISIBILITY_RB                 25 /* Visibility rules */
@d PERSUASION_RB                 26 /* Persuasion rules */
@d UNSUCCESSFUL_ATTEMPT_BY_RB    27 /* Unsuccessful attempt by */
@d BEFORE_RB                     28 /* Before rules */
@d INSTEAD_RB                    29 /* Instead rules */
@d CHECK_RB                      30 /* Check */
@d CARRY_OUT_RB                  31 /* Carry out rules */
@d AFTER_RB                      32 /* After rules */
@d REPORT_RB                     33 /* Report */
@d DOES_THE_PLAYER_MEAN_RB       34 /* Does the player mean...? rules */
@d MULTIPLE_ACTION_PROCESSING_RB 35 /* For changing or reordering multiple actions */

@ The rest of the compiler should call |Rulebooks::std(N)| to obtain rulebook |N|.

@d MAX_BUILT_IN_RULEBOOKS 64

=
int built_in_rulebooks_initialised = FALSE;
rulebook *built_in_rulebooks[MAX_BUILT_IN_RULEBOOKS];

rulebook *Rulebooks::std(int rb) {
	if ((rb < 0) || (rb >= MAX_BUILT_IN_RULEBOOKS)) internal_error("rb out of range");
	if (built_in_rulebooks_initialised == FALSE) {
		built_in_rulebooks_initialised = TRUE;
		for (int i=0; i<MAX_BUILT_IN_RULEBOOKS; i++) built_in_rulebooks[i] = NULL;
	}
	return built_in_rulebooks[rb];
}

void Rulebooks::set_std(rulebook *B) {
	if (built_in_rulebooks_initialised == FALSE) {
		built_in_rulebooks_initialised = TRUE;
		for (int i=0; i<MAX_BUILT_IN_RULEBOOKS; i++) built_in_rulebooks[i] = NULL;
	}
	if (B->allocation_id < MAX_BUILT_IN_RULEBOOKS)
		built_in_rulebooks[B->allocation_id] = B;
}
