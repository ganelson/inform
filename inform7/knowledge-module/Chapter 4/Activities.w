[Activities::] Activities.

To create and manage activities, which are action-like bundles of
rules controlling how the I6 runtime code carries out tasks such as "printing
the name of something". Each has its own page in the I7 documentation. An
activity list is a disjunction of actitivies.

@h Definitions.

=
typedef struct activity {
	struct wording name; /* text of the name of the activity */
	struct rulebook *before_rules; /* rulebooks for when this is followed */
	struct rulebook *for_rules;
	struct rulebook *after_rules;
	struct kind *activity_on_what_kind; /* or null */
	struct stacked_variable_owner *owned_by_av; /* activity variables owned here */
	struct package_request *av_package;
	struct inter_name *av_iname; /* an identifier for a constant identifying this */
	struct wording av_documentation_symbol; /* cross-reference to HTML documentation, if any */
	int activity_indexed; /* has this been indexed yet? */
	struct activity_crossref *cross_references;
	CLASS_DEFINITION
} activity;

typedef struct activity_list {
	struct activity *activity; /* what activity */
	struct parse_node *acting_on; /* the parameter */
	struct parse_node *only_when; /* condition for when this applies */
	int ACL_parity; /* |+1| if meant positively, |-1| if negatively */
	struct activity_list *next; /* next in activity list */
} activity_list;

typedef struct activity_crossref {
	struct phrase *rule_dependent;
	struct activity_crossref *next;
} activity_crossref;

@

@d STARTING_VIRTUAL_MACHINE_ACT 0
@d PRINTING_THE_NAME_ACT 1
@d PRINTING_THE_PLURAL_NAME_ACT 2

@d PRINTING_RESPONSE_ACT 3

@d PRINTING_A_NUMBER_OF_ACT 4
@d PRINTING_ROOM_DESC_DETAILS_ACT 5
@d PRINTING_INVENTORY_DETAILS_ACT 6
@d LISTING_CONTENTS_ACT 7
@d GROUPING_TOGETHER_ACT 8
@d WRITING_A_PARAGRAPH_ABOUT_ACT 9
@d LISTING_NONDESCRIPT_ITEMS_ACT 10

@d PRINTING_NAME_OF_DARK_ROOM_ACT 11
@d PRINTING_DESC_OF_DARK_ROOM_ACT 12
@d PRINTING_NEWS_OF_DARKNESS_ACT 13
@d PRINTING_NEWS_OF_LIGHT_ACT 14
@d REFUSAL_TO_ACT_IN_DARK_ACT 15

@d CONSTRUCTING_STATUS_LINE_ACT 16
@d PRINTING_BANNER_TEXT_ACT 17

@d READING_A_COMMAND_ACT 18
@d DECIDING_SCOPE_ACT 19
@d DECIDING_CONCEALED_POSSESS_ACT 20
@d DECIDING_WHETHER_ALL_INC_ACT 21
@d CLARIFYING_PARSERS_CHOICE_ACT 22
@d ASKING_WHICH_DO_YOU_MEAN_ACT 23
@d PRINTING_A_PARSER_ERROR_ACT 24
@d SUPPLYING_A_MISSING_NOUN_ACT 25
@d SUPPLYING_A_MISSING_SECOND_ACT 26
@d IMPLICITLY_TAKING_ACT 27

@d AMUSING_A_VICTORIOUS_PLAYER_ACT 28
@d PRINTING_PLAYERS_OBITUARY_ACT 29
@d DEALING_WITH_FINAL_QUESTION_ACT 30

@d PRINTING_LOCALE_DESCRIPTION_ACT 31
@d CHOOSING_NOTABLE_LOCALE_OBJ_ACT 32
@d PRINTING_LOCALE_PARAGRAPH_ACT 33

@ Activities are much simpler to create than actions. For example,

>> Announcing something is an activity on numbers.

The object phrase (here "an activity on numbers") is required to match
<k-kind> and, moreover, to be an activity kind, but we don't parse it
here. What we do instead is to work on the subject phrase (here "announcing
something"):

=
<activity-sentence-subject> ::=
	<activity-noted> ( <documentation-symbol> ) |    ==> { R[1], -, <<ds>> = R[2] }
	<activity-noted> -- <documentation-symbol> -- |  ==> { R[1], -, <<ds>> = R[2] }
	<activity-noted>                                 ==> { R[1], -, <<ds>> = -1 }

<activity-noted> ::=
	<activity-new-name> ( future action ) |          ==> { TRUE, -, <<future>> = TRUE }
	<activity-new-name> ( ... )	|                    ==> @<Issue PM_ActivityNoteUnknown problem@>
	<activity-new-name>                              ==> { TRUE, -, <<future>> = FALSE }

<activity-new-name> ::=
	... of/for something/anything |                  ==> { 0, -, <<any>> = TRUE }
	... something/anything |                         ==> { 0, -, <<any>> = TRUE }
	...                                              ==> { 0, -, <<any>> = FALSE }

@ Once a new activity has been created, the following is used to make a
noun for it; for example, the "announcing activity".

=
<activity-name-construction> ::=
	... activity

@<Issue PM_ActivityNoteUnknown problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActivityNoteUnknown),
		"one of the notes about this activity makes no sense",
		"and should be either 'documented at SYMBOL' or 'future action'.");
	==> { FALSE, - };

@ =
activity *Activities::new(kind *creation_kind, wording W) {
	activity *av = CREATE(activity);
	int future_action_flag = FALSE;
	parse_node *spec;
	creation_kind = Kinds::unary_construction_material(creation_kind);

	if ((Kinds::Behaviour::definite(creation_kind) == FALSE) &&
		(Kinds::eq(creation_kind, K_nil) == FALSE)) {
		LOG("I'm reading the kind as: %u\n", creation_kind);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActivityIndefinite),
			"this is an activity on a kind which isn't definite",
			"and doesn't tell me enough about what sort of value the activity "
			"should work on. For example, 'Divining is an activity on numbers' "
			"is fine because 'numbers' is definite, but 'Divining is an "
			"activity on values' is not allowed.");
		creation_kind = K_object;
	}

	<activity-sentence-subject>(W);
	W = GET_RW(<activity-new-name>, 1);
	av->av_documentation_symbol = Wordings::one_word(<<ds>>);
	future_action_flag = <<future>>;

	if (<<any>>) {
		if (Kinds::eq(creation_kind, K_nil)) creation_kind = K_object;
	} else {
		if (Kinds::eq(creation_kind, K_nil) == FALSE) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ActivityMisnamed),
				"the name of this activity implies that it acts on nothing",
				"which doesn't fit with what you say about it. For example, "
				"'Painting is an activity on brushes' isn't allowed because "
				"the activity's name doesn't end with 'something': it should "
				"be 'Painting something is an activity on brushes'.");
		}
	}

	av->name = W;
	av->av_package = Hierarchy::local_package(ACTIVITIES_HAP);
	Hierarchy::markup_wording(av->av_package, ACTIVITY_NAME_HMD, av->name);
	av->av_iname = Hierarchy::make_iname_with_memo(ACTIVITY_HL, av->av_package, av->name);
	Emit::named_numeric_constant(av->av_iname, (inter_ti) av->allocation_id);

	LOGIF(ACTIVITY_CREATIONS, "Created activity: %n = %W\n", av->av_iname, av->name);

	av->activity_on_what_kind = creation_kind;

	if (<s-value>(av->name)) spec = <<rp>>;
	else spec = Specifications::new_UNKNOWN(av->name);
	if (!(Node::is(spec, UNKNOWN_NT)) && (!(Node::is(spec, PROPERTY_VALUE_NT)))) {
		LOG("%W means $P\n", av->name, spec);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadActivityName),
			"this already has a meaning",
			"and so cannot be the name of a newly created activity.");
	} else {
		Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			ACTIVITY_MC, Rvalues::from_activity(av), Task::language_of_syntax());
		word_assemblage wa =
			PreformUtilities::merge(<activity-name-construction>, 0,
				WordAssemblages::from_wording(av->name));
		wording AW = WordAssemblages::to_wording(&wa);
		Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
			ACTIVITY_MC, Rvalues::from_activity(av), Task::language_of_syntax());
	}

	feed_t id = Feeds::begin();
	Feeds::feed_C_string_expanding_strings(L"before");
	Feeds::feed_wording(av->name);
	wording SW = Feeds::end(id);
	package_request *BR = Hierarchy::make_package_in(BEFORE_RB_HL, av->av_package);
	av->before_rules =
		Rulebooks::new_automatic(SW, av->activity_on_what_kind,
			NO_OUTCOME, FALSE, future_action_flag, TRUE, BR);
	id = Feeds::begin();
	Feeds::feed_C_string_expanding_strings(L"for");
	Feeds::feed_wording(av->name);
	SW = Feeds::end(id);
	package_request *FR = Hierarchy::make_package_in(FOR_RB_HL, av->av_package);
	av->for_rules =
		Rulebooks::new_automatic(SW, av->activity_on_what_kind,
			SUCCESS_OUTCOME, FALSE, future_action_flag, TRUE, FR);
	id = Feeds::begin();
	Feeds::feed_C_string_expanding_strings(L"after");
	Feeds::feed_wording(av->name);
	SW = Feeds::end(id);
	package_request *AR = Hierarchy::make_package_in(AFTER_RB_HL, av->av_package);
	av->after_rules =
		Rulebooks::new_automatic(SW, av->activity_on_what_kind,
			NO_OUTCOME, FALSE, future_action_flag, TRUE, AR);

	av->owned_by_av = StackedVariables::new_owner(10000+av->allocation_id);
	Rulebooks::make_stvs_accessible(av->before_rules, av->owned_by_av);
	Rulebooks::make_stvs_accessible(av->for_rules, av->owned_by_av);
	Rulebooks::make_stvs_accessible(av->after_rules, av->owned_by_av);

	av->activity_indexed = FALSE;
	av->cross_references = NULL;
	return av;
}

kind *Activities::to_kind(activity *av) {
	return Kinds::unary_con(CON_activity,
		av->activity_on_what_kind);
}

@h Activity variables.
Any new activity variable name is vetted by being run through this:

=
<activity-variable-name> ::=
	<unfortunate-name> |    ==> @<Issue PM_ActivityVarAnd problem@>
	...										==> { TRUE, - }

@<Issue PM_ActivityVarAnd problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActivityVarAnd));
	Problems::issue_problem_segment(
		"You wrote %1, which I am reading as a request to make "
		"a new named variable for an activity - a value associated "
		"with a activity and which has a name. The request seems to "
		"say that the name in question is '%2', but I'd prefer to "
		"avoid 'and', 'or', 'with', or 'having' in such names, please.");
	Problems::issue_problem_end();
	==> { NOT_APPLICABLE, - };

@ =
void Activities::add_variable(activity *av, parse_node *cnode) {
	parse_node *spec;
	if ((Node::get_type(cnode) != PROPERTYCALLED_NT) &&
		(Node::get_type(cnode) != UNPARSED_NOUN_NT)) {
		LOG("Tree: $T\n", cnode);
		internal_error("ac_add_variable on a node of unknown type");
	}

	if (Node::get_type(cnode) == UNPARSED_NOUN_NT) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActivityVariableNameless));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make "
			"a new named variable for an activity - a value associated "
			"with a activity and which has a name. Here, though, there "
			"seems to be no name for the variable as such, only an indication "
			"of its kind. Try something like 'The printing the banner text "
			"activity has a number called the accumulated vanity'.");
		Problems::issue_problem_end();
		return;
	}

	spec = NULL;
	if (<s-type-expression>(Node::get_text(cnode->down))) spec = <<rp>>;

	if (<activity-variable-name>(Node::get_text(cnode->down->next))) {
		if (<<r>> == NOT_APPLICABLE) return;
	}

	if (Specifications::is_description(spec)) {
		if ((Specifications::to_kind(spec)) &&
			(Descriptions::number_of_adjectives_applied_to(spec) == 0)) {

		} else {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(cnode->down));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActivityVarOverspecific));
			Problems::issue_problem_segment(
				"You wrote %1, which I am reading as a request to make "
				"a new named variable for an activity - a value associated "
				"with a activity and which has a name. The request seems to "
				"say that the value in question is '%2', but this is too "
				"specific a description. (Instead, a kind of value "
				"(such as 'number') or a kind of object (such as 'room' "
				"or 'thing') should be given. To get a property whose "
				"contents can be any kind of object, use 'object'.)");
			Problems::issue_problem_end();
			return;
		}
	}
	if (!(Specifications::is_kind_like(spec))) {
		LOG("Offending SP: $T", spec);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActivityVarUnknownKOV));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not the name of a kind of "
			"value which I know (such as 'number' or 'text').");
		Problems::issue_problem_end();
		return;
	}
	if (Kinds::eq(Specifications::to_kind(spec), K_value)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(cnode->down));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ActivityVarValue));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a variable is a 'value' "
			"does not give me a clear enough idea what it will hold. "
			"You need to say what kind of value: for instance, 'A door "
			"has a number called street address.' is allowed because "
			"'number' is specific about the kind of value.");
		Problems::issue_problem_end();
		return;
	}
	StackedVariables::add_empty(av->owned_by_av, Node::get_text(cnode->down->next),
		Specifications::to_kind(spec));
}

void Activities::activity_var_creators(void) {
	activity *av;
	LOOP_OVER(av, activity) {
		if (StackedVariables::owner_empty(av->owned_by_av) == FALSE) {
			inter_name *iname = Hierarchy::make_iname_in(ACTIVITY_STV_CREATOR_FN_HL, av->av_package);
			StackedVariables::compile_frame_creator(av->owned_by_av, iname);
		}
	}

	inter_name *iname = Hierarchy::find(ACTIVITY_VAR_CREATORS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	int c = 0;
	LOOP_OVER(av, activity) {
		if (StackedVariables::owner_empty(av->owned_by_av)) Emit::array_numeric_entry(0);
		else Emit::array_iname_entry(StackedVariables::frame_creator(av->owned_by_av));
		c++;
	}
	Emit::array_numeric_entry(0);
	if (c == 0) Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@h Activity indexing.

=
void Activities::index_by_number(OUTPUT_STREAM, int id, int indent) {
	activity *av;
	LOOP_OVER(av, activity)
		if (av->allocation_id == id) Activities::index(OUT, av, indent);
}

void Activities::index(OUTPUT_STREAM, activity *av, int indent) {
	int empty = TRUE;
	char *text = NULL;
	if (av->activity_indexed) return;
	av->activity_indexed = TRUE;
	if (Rulebooks::is_empty(av->before_rules, Rulebooks::no_rule_context()) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->for_rules, Rulebooks::no_rule_context()) == FALSE) empty = FALSE;
	if (Rulebooks::is_empty(av->after_rules, Rulebooks::no_rule_context()) == FALSE) empty = FALSE;
	if (av->cross_references) empty = FALSE;
	TEMPORARY_TEXT(doc_link)
	if (Wordings::nonempty(av->av_documentation_symbol))
		WRITE_TO(doc_link, "%+W", Wordings::one_word(Wordings::first_wn(av->av_documentation_symbol)));
	if (empty) text = "There are no rules before, for or after this activity.";
	Rulebooks::index_rules_box(OUT, NULL, av->name, doc_link,
		NULL, av, text, indent, TRUE);
	DISCARD_TEXT(doc_link)
}

int Activities::no_rules(activity *av) {
	int t = 0;
	t += Rulebooks::no_rules(av->before_rules);
	t += Rulebooks::no_rules(av->for_rules);
	t += Rulebooks::no_rules(av->after_rules);
	return t;
}

void Activities::index_details(OUTPUT_STREAM, activity *av) {
	int ignore_me = 0;
	Rulebooks::index(OUT, av->before_rules, "before", Rulebooks::no_rule_context(), &ignore_me);
	Rulebooks::index(OUT, av->for_rules, "for", Rulebooks::no_rule_context(), &ignore_me);
	Rulebooks::index(OUT, av->after_rules, "after", Rulebooks::no_rule_context(), &ignore_me);
	Activities::index_cross_references(OUT, av);
}

inter_name *Activities::iname(activity *av) {
	return av->av_iname;
}

int Activities::count_list(activity_list *avl) {
	int n = 0;
	while (avl) {
		n += 10;
		if (avl->only_when) n += Conditions::count(avl->only_when);
		avl = avl->next;
	}
	return n;
}

@ Run-time contexts are seen in the "while" clauses at the end of rules.
For example:

>> Rule for printing the name of the lemon sherbet while listing contents: ...

Here "listing contents" is the context. These are like action patterns, but
much simpler to parse -- an or-divided list of activities can be given, with or
without operands; "not" can be used to negate the list; and ordinary
conditions are also allowed, as here:

>> Rule for printing the name of the sack while the sack is not carried: ...

where "the sack is not carried" is also a <run-time-context> even though
it mentions no activities.

=
<run-time-context> ::=
	not <activity-list-unnegated> |          ==> { 0, RP[1] }; @<Flip the activity list parities@>;
	<activity-list-unnegated>                ==> { 0, RP[1] }

<activity-list-unnegated> ::=
	... |                                    ==> { lookahead }
	<activity-list-entry> <activity-tail> |  ==> @<Join the activity lists@>;
	<activity-list-entry>                    ==> { 0, RP[1] }

<activity-tail> ::=
	, _or <run-time-context> |               ==> { 0, RP[1] }
	_,/or <run-time-context>                 ==> { 0, RP[1] }

<activity-list-entry> ::=
	<activity-name> |                            ==> @<Make one-entry AL without operand@>
	<activity-name> of/for <activity-operand> |  ==> @<Make one-entry AL with operand@>
	<activity-name> <activity-operand> |         ==> @<Make one-entry AL with operand@>
	^<if-parsing-al-conditions> ... |            ==> @<Make one-entry AL with unparsed text@>
	<if-parsing-al-conditions> <s-condition>     ==> @<Make one-entry AL with condition@>

@ The optional operand handles "something" itself in productions (a) and (b)
in order to prevent it from being read as a description at production (c). This
prevents "something" from being read as "some thing", that is, it prevents
Inform from thinking that the operand value must have kind "thing".

If we do reach (c), the expression is required to be a value, or description of
values, of the kind to which the activity applies.

=
<activity-operand> ::=
	something/anything |          ==> { FALSE, Specifications::new_UNKNOWN(W) }
	something/anything else |     ==> { FALSE, Specifications::new_UNKNOWN(W) }
	<s-type-expression-or-value>  ==> { TRUE, RP[1] }

@<Flip the activity list parities@> =
	activity_list *al = *XP;
	for (; al; al=al->next) {
		al->ACL_parity = (al->ACL_parity)?FALSE:TRUE;
	}

@<Join the activity lists@> =
	activity_list *al1 = RP[1], *al2 = RP[2];
	al1->next = al2;
	==> { -, al1 };

@<Make one-entry AL without operand@> =
	activity_list *al;
	@<Make one-entry AL@>;
	al->activity = RP[1];

@<Make one-entry AL with operand@> =
	activity *an = RP[1];
	if (an->activity_on_what_kind == NULL) return FALSE;
	if ((R[2]) && (Dash::validate_parameter(RP[2], an->activity_on_what_kind) == FALSE))
		return FALSE;
	activity_list *al;
	@<Make one-entry AL@>;
	al->activity = an;
	al->acting_on = RP[2];

@<Make one-entry AL with unparsed text@> =
	parse_node *cond = Specifications::new_UNKNOWN(EMPTY_WORDING);
	activity_list *al;
	@<Make one-entry AL@>;
	al->only_when = cond;

@<Make one-entry AL with condition@> =
	parse_node *cond = RP[2];
	if (Dash::validate_conditional_clause(cond) == FALSE) return FALSE;
	activity_list *al;
	@<Make one-entry AL@>;
	al->only_when = cond;

@<Make one-entry AL@> =
	al = CREATE(activity_list);
	al->acting_on = NULL;
	al->only_when = NULL;
	al->next = NULL;
	al->ACL_parity = TRUE;
	al->activity = NULL;
	==> { -, al };

@ And this parses individual activity names.

=
<activity-name> internal {
	parse_node *p = Lexicon::retrieve(ACTIVITY_MC, W);
	if (Rvalues::is_CONSTANT_construction(p, CON_activity)) {
		==> { -, Rvalues::to_activity(p) };
		return TRUE;
	}
	==> { fail nonterminal }
}

@ =
int parsing_al_conditions = TRUE;

activity_list *Activities::parse_list(wording W) {
	return Activities::parse_list_inner(W, TRUE);
}

@ It's convenient not to look too closely at the condition sometimes.

=
<if-parsing-al-conditions> internal 0 {
	if (parsing_al_conditions) return TRUE;
	==> { fail nonterminal };
}

@ All of which sets up the context for:

=
activity_list *Activities::parse_list_inner(wording W, int state) {
	int save_pac = parsing_al_conditions;
	parsing_al_conditions = state;
	int rv = <run-time-context>(W);
	parsing_al_conditions = save_pac;
	if (rv) return <<rp>>;
	return NULL;
}

void Activities::emit_activity_list(activity_list *al) {
	int negate_me = FALSE, downs = 0;
	if (al->ACL_parity == FALSE) negate_me = TRUE;
	if (negate_me) { Produce::inv_primitive(Emit::tree(), NOT_BIP); Produce::down(Emit::tree()); downs++; }

	int cl = 0;
	for (activity_list *k = al; k; k = k->next) cl++;

	int ncl = 0;
	while (al != NULL) {
		if (++ncl < cl) { Produce::inv_primitive(Emit::tree(), OR_BIP); Produce::down(Emit::tree()); downs++; }
		if (al->activity != NULL) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTACTIVITY_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, al->activity->av_iname);
				if (al->acting_on) {
					if (Specifications::is_description(al->acting_on)) {
						Produce::val_iname(Emit::tree(), K_value, Calculus::Deferrals::compile_deferred_description_test(al->acting_on));
					} else {
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
						Specifications::Compiler::emit_as_val(K_value, al->acting_on);
					}
				}
			Produce::up(Emit::tree());
		}
		else {
			Specifications::Compiler::emit_as_val(K_value, al->only_when);
		}
		al = al->next;
	}

	while (downs > 0) { Produce::up(Emit::tree()); downs--; }
}

void Activities::compile_activity_constants(void) {
}

void Activities::Activity_before_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_BEFORE_RULEBOOKS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) av->before_rules->allocation_id);
		i++;
	}
	if (i==0) Emit::array_null_entry();
	Emit::array_null_entry();
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void Activities::Activity_for_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_FOR_RULEBOOKS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) av->for_rules->allocation_id);
		i++;
	}
	if (i==0) Emit::array_null_entry();
	Emit::array_null_entry();
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void Activities::Activity_after_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_AFTER_RULEBOOKS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) av->after_rules->allocation_id);
		i++;
	}
	if (i==0) Emit::array_null_entry();
	Emit::array_null_entry();
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void Activities::Activity_atb_rulebooks_array(void) {
	inter_name *iname = Hierarchy::find(ACTIVITY_ATB_RULEBOOKS_HL);
	packaging_state save = Emit::named_byte_array_begin(iname, K_number);
	activity *av; int i = 0;
	LOOP_OVER(av, activity) {
		Emit::array_numeric_entry((inter_ti) Rulebooks::used_by_future_actions(av->before_rules));
		i++;
	}
	if (i==0) Emit::array_numeric_entry(255);
	Emit::array_numeric_entry(255);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void Activities::annotate_list_for_cross_references(activity_list *avl, phrase *ph) {
	for (; avl; avl = avl->next)
		if (avl->activity) {
			activity *av = avl->activity;
			activity_crossref *acr = CREATE(activity_crossref);
			acr->next = av->cross_references;
			av->cross_references = acr;
			acr->rule_dependent = ph;
		}
}

void Activities::index_cross_references(OUTPUT_STREAM, activity *av) {
	activity_crossref *acr;
	for (acr = av->cross_references; acr; acr = acr->next) {
		phrase *ph = acr->rule_dependent;
		if ((ph->declaration_node) && (Wordings::nonempty(Node::get_text(ph->declaration_node)))) {
			HTML::open_indented_p(OUT, 2, "tight");
			WRITE("NB: %W", Node::get_text(ph->declaration_node));
			Index::link(OUT, Wordings::first_wn(Node::get_text(ph->declaration_node)));
			HTML_CLOSE("p");
		}
	}
}
