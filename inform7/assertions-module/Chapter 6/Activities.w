[Activities::] Activities.

To create and manage activities, which are bundles of rules for carrying out tasks.

@h Introduction.
An activity is just a triple of rulebooks with related names, a common focus
and a shared set of variables, so this will not be a long section of code.

=
typedef struct activity {
	struct wording name; /* text of the name of the activity */
	struct rulebook *before_rules; /* rulebooks for when this is followed */
	struct rulebook *for_rules;
	struct rulebook *after_rules;
	struct kind *activity_on_what_kind; /* or null */
	struct shared_variable_set *activity_variables; /* activity variables owned here */
	struct activity_compilation_data compilation_data;
	CLASS_DEFINITION
} activity;

@ Whereas rulebooks can turn values into other values, activities are more like
void functions: they work on a value, but produce nothing.

=
kind *Activities::to_kind(activity *av) {
	return Kinds::unary_con(CON_activity, av->activity_on_what_kind);
}

@ Activities are much simpler to create than actions. For example,

>> Announcing something is an activity on numbers.

The object phrase (here "an activity on numbers") matches <k-kind> and needs no
special Preform of its own; here is the subject phrase:

=
<activity-sentence-subject> ::=
	<activity-noted> ( <documentation-symbol> ) |   ==> { R[1], -, <<ds>> = R[2] }
	<activity-noted> -- <documentation-symbol> -- | ==> { R[1], -, <<ds>> = R[2] }
	<activity-noted>                                ==> { R[1], -, <<ds>> = -1 }

<activity-noted> ::=
	<activity-new-name> ( future action ) |         ==> { TRUE, -, <<future>> = TRUE }
	<activity-new-name> ( ... )	|                   ==> @<Issue PM_ActivityNoteUnknown problem@>
	<activity-new-name>                             ==> { TRUE, -, <<future>> = FALSE }

<activity-new-name> ::=
	... of/for something/anything |                 ==> { 0, -, <<any>> = TRUE }
	... something/anything |                        ==> { 0, -, <<any>> = TRUE }
	...                                             ==> { 0, -, <<any>> = FALSE }

@<Issue PM_ActivityNoteUnknown problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActivityNoteUnknown),
		"one of the notes about this activity makes no sense",
		"and should be either 'documented at SYMBOL' or 'future action'.");
	==> { FALSE, - };

@

=
activity *Activities::new(kind *K, wording W) {
	kind *on_kind = Kinds::unary_construction_material(K);
	int kind_given = TRUE;
	if (Kinds::eq(on_kind, K_nil)) {
		kind_given = FALSE; on_kind = K_object;
	}

	<activity-sentence-subject>(W);
	W = GET_RW(<activity-new-name>, 1);
	wording doc_symbol = Wordings::one_word(<<ds>>);
	int future_action_flag = <<future>>;

	@<The name can't have been used before@>;
	@<The kind the activity is performed on, if there is one, must be definite@>;
	@<If it is not of or for something, then it cannot have a kind@>;

	activity *av = CREATE(activity);
	av->name = W;
	av->compilation_data = RTActivities::new_compilation_data(av, doc_symbol);
	av->activity_on_what_kind = on_kind;

	LOGIF(ACTIVITY_CREATIONS, "Created activity '%W'\n", av->name);

	@<Make proper nouns for the activity name@>;

	av->activity_variables = SharedVariables::new_set(av->compilation_data.variables_id);

	av->before_rules = Activities::make_rulebook(av, 0, future_action_flag);
	av->for_rules = Activities::make_rulebook(av, 1, future_action_flag);
	av->after_rules = Activities::make_rulebook(av, 2, future_action_flag);

	Activities::set_std(av);

	PluginCalls::new_activity_notify(av);

	return av;
}

@<The name can't have been used before@> =
	if (<s-value>(W)) {
		parse_node *spec = <<rp>>;
		if (!(Node::is(spec, UNKNOWN_NT)) && (!(Node::is(spec, PROPERTY_VALUE_NT)))) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_BadActivityName),
				"this already has a meaning",
				"and so cannot be the name of a newly created activity.");
			return NULL;
		}
	}

@<The kind the activity is performed on, if there is one, must be definite@> =
	if (Kinds::Behaviour::definite(on_kind) == FALSE) {
		LOG("I'm reading the kind as: %u\n", on_kind);
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ActivityIndefinite),
			"this is an activity on a kind which isn't definite",
			"and doesn't tell me enough about what sort of value the activity should work "
			"on. For example, 'Divining is an activity on numbers' is fine because "
			"'numbers' is definite, but 'Divining is an activity on values' is not "
			"allowed.");
		return NULL;
	}

@<If it is not of or for something, then it cannot have a kind@> =
	if ((<<any>> == FALSE) && (kind_given)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ActivityMisnamed),
			"the name of this activity implies that it acts on nothing",
			"which doesn't fit with what you say about it. For example, 'Painting is an "
			"activity on brushes' isn't allowed because the activity's name doesn't end "
			"with 'something': it should be 'Painting something is an activity on brushes'.");
		return NULL;
	}

@ Once a new activity has been created, the following is used to make a noun for
it; actually two -- for example, both "announcing" and "announcing activity".

=
<activity-name-construction> ::=
	... activity

@<Make proper nouns for the activity name@> =
	Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		ACTIVITY_MC, Rvalues::from_activity(av), Task::language_of_syntax());
	word_assemblage wa =
		PreformUtilities::merge(<activity-name-construction>, 0,
			WordAssemblages::from_wording(av->name));
	wording AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		ACTIVITY_MC, Rvalues::from_activity(av), Task::language_of_syntax());

@ And its rulebooks are named with these constructions:

=
<activity-rulebook-construction> ::=
	before ... |
	for ... |
	after ...

@ =
rulebook *Activities::make_rulebook(activity *av, int N, int future_action_flag) {
	int def = NO_OUTCOME;
	if (N == 1) def = SUCCESS_OUTCOME;
	word_assemblage wa = PreformUtilities::merge(<activity-rulebook-construction>, N,
		WordAssemblages::from_wording(av->name));
	wording RW = WordAssemblages::to_wording(&wa);
	rulebook *R = Rulebooks::new_automatic(RW, av->activity_on_what_kind,
		def, FALSE, future_action_flag, TRUE, 0, RTActivities::rulebook_package(av, N));
	Rulebooks::grant_access_to_variables(R, av->activity_variables);
	return R;
}

@ And this nonterminal parses individual activity names.

=
<activity-name> internal {
	parse_node *p = Lexicon::retrieve(ACTIVITY_MC, W);
	if (Rvalues::is_CONSTANT_construction(p, CON_activity)) {
		==> { -, Rvalues::to_activity(p) };
		return TRUE;
	}
	==> { fail nonterminal }
}

@h Activity variables.
Any new activity variable name is vetted by being run through this:

=
void Activities::add_variable(activity *av, parse_node *cnode) {
	if (Node::get_type(cnode) == UNPARSED_NOUN_NT) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ActivityVariableNameless));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named variable "
			"for an activity - a value associated with a activity and which has a name. "
			"Here, though, there seems to be no name for the variable as such, only an "
			"indication of its kind. Try something like 'The printing the banner text "
			"activity has a number called the accumulated vanity'.");
		Problems::issue_problem_end();
		return;
	}

	wording SW = Node::get_text(cnode->down);
	wording VW = Node::get_text(cnode->down->next);

	parse_node *spec = NULL; if (<s-type-expression>(SW)) spec = <<rp>>;

	@<The name of the variable must be fortunate@>;
	@<The specification must not be qualified@>;
	@<The specification must be just a kind@>;
	@<That kind must be definite@>;

	SharedVariables::new(av->activity_variables, VW, Specifications::to_kind(spec), FALSE);
}

@<The name of the variable must be fortunate@> =
	if (<unfortunate-name>(VW)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, VW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ActivityVarAnd));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named variable "
			"for an activity - a value associated with a activity and which has a name. "
			"The request seems to say that the name in question is '%2', but I'd prefer "
			"to avoid 'and', 'or', 'with', or 'having' in such names, please.");
		Problems::issue_problem_end();
		return;
	}

@<The specification must not be qualified@> =
	if ((Specifications::is_kind_like(spec) == FALSE) &&
		(Specifications::is_description(spec))) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, SW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ActivityVarOverspecific));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named variable "
			"for an activity - a value associated with a activity and which has a name. "
			"The request seems to say that the value in question is '%2', but this is too "
			"specific a description. (Instead, a kind of value (such as 'number') or a "
			"kind of object (such as 'room' or 'thing') should be given. To get a property "
			"whose contents can be any kind of object, use 'object'.)");
		Problems::issue_problem_end();
		return;
	}

@<The specification must be just a kind@> =
	if (Specifications::is_kind_like(spec) == FALSE) {
		LOG("Offending SP: $T", spec);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, SW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ActivityVarUnknownKOV));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not the name of a kind of value which I know "
			"(such as 'number' or 'text').");
		Problems::issue_problem_end();
		return;
	}

@<That kind must be definite@> =
	if (Kinds::Behaviour::definite(Specifications::to_kind(spec)) == FALSE) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, SW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_ActivityVarValue));
		Problems::issue_problem_segment(
			"You wrote %1, but this does not give me a clear enough idea what it will hold. "
			"You need to say what kind of value: for instance, 'A door has a number called "
			"street address.' is allowed because 'number' is specific about the kind of "
			"value.");
		Problems::issue_problem_end();
		return;
	}

@h Standard activities.
As with rulebooks -- see the similar discussion at //Rulebooks::std// -- a few
activities are special to the compiler, though in fact purely for indexing purposes.

These are recognised by the order in which they are declared, which makes it
crucial not to change that order in //basic_inform: Miscellaneous Definitions//
and //standard_rules: Physical World Model// without making matching changes
both here and in //BasicInformKit// and //WorldModelKit//. So: don't casually
change the following numbers.

Note that in the world of Basic Inform only, none of these will exist except
for the first five.

@d STARTING_VIRTUAL_MACHINE_ACT    0
@d PRINTING_THE_NAME_ACT           1
@d PRINTING_THE_PLURAL_NAME_ACT    2
@d PRINTING_RESPONSE_ACT           3
@d PRINTING_A_NUMBER_OF_ACT        4
@d PRINTING_ROOM_DESC_DETAILS_ACT  5
@d PRINTING_INVENTORY_DETAILS_ACT  6
@d LISTING_CONTENTS_ACT            7
@d GROUPING_TOGETHER_ACT           8
@d WRITING_A_PARAGRAPH_ABOUT_ACT   9
@d LISTING_NONDESCRIPT_ITEMS_ACT   10
@d PRINTING_NAME_OF_DARK_ROOM_ACT  11
@d PRINTING_DESC_OF_DARK_ROOM_ACT  12
@d PRINTING_NEWS_OF_DARKNESS_ACT   13
@d PRINTING_NEWS_OF_LIGHT_ACT      14
@d REFUSAL_TO_ACT_IN_DARK_ACT      15
@d CONSTRUCTING_STATUS_LINE_ACT    16
@d PRINTING_BANNER_TEXT_ACT        17
@d READING_A_COMMAND_ACT           18
@d DECIDING_SCOPE_ACT              19
@d DECIDING_CONCEALED_POSSESS_ACT  20
@d DECIDING_WHETHER_ALL_INC_ACT    21
@d CLARIFYING_PARSERS_CHOICE_ACT   22
@d ASKING_WHICH_DO_YOU_MEAN_ACT    23
@d PRINTING_A_PARSER_ERROR_ACT     24
@d SUPPLYING_A_MISSING_NOUN_ACT    25
@d SUPPLYING_A_MISSING_SECOND_ACT  26
@d IMPLICITLY_TAKING_ACT           27
@d AMUSING_A_VICTORIOUS_PLAYER_ACT 28
@d PRINTING_PLAYERS_OBITUARY_ACT   29
@d DEALING_WITH_FINAL_QUESTION_ACT 30
@d PRINTING_LOCALE_DESCRIPTION_ACT 31
@d CHOOSING_NOTABLE_LOCALE_OBJ_ACT 32
@d PRINTING_LOCALE_PARAGRAPH_ACT   33

@ The rest of the compiler should call |Activities::std(N)| to obtain activity |N|.

@d MAX_BUILT_IN_ACTIVITIES 64

=
int built_in_activities_initialised = FALSE;
activity *built_in_activities[MAX_BUILT_IN_ACTIVITIES];

activity *Activities::std(int N) {
	if ((N < 0) || (N >= MAX_BUILT_IN_ACTIVITIES)) internal_error("N out of range");
	if (built_in_activities_initialised == FALSE) {
		built_in_activities_initialised = TRUE;
		for (int i=0; i<MAX_BUILT_IN_ACTIVITIES; i++) built_in_activities[i] = NULL;
	}
	return built_in_activities[N];
}

void Activities::set_std(activity *Av) {
	if (built_in_activities_initialised == FALSE) {
		built_in_activities_initialised = TRUE;
		for (int i=0; i<MAX_BUILT_IN_ACTIVITIES; i++) built_in_activities[i] = NULL;
	}
	if (Av->allocation_id < MAX_BUILT_IN_ACTIVITIES)
		built_in_activities[Av->allocation_id] = Av;
}
