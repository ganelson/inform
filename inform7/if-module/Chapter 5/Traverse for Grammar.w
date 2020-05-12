[PL::Parsing::] Traverse for Grammar.

To create and manipulate grammar, primarily by parsing and acting
upon Understand... sentences in the source text.

@h Definitions.

@ We cache grammar occurring in the source text in conditions, and so forth:

=
typedef struct cached_understanding {
	struct wording understanding_text; /* word range of the understanding text */
	struct inter_name *cu_iname; /* the runtime name for this |Consult_Grammar_N| routine */
	CLASS_DEFINITION
} cached_understanding;

@ And this will help with parsing:

=
typedef struct understanding_item {
	struct wording quoted_text;
	struct property *quoted_property;
	struct understanding_item *next;
} understanding_item;

typedef struct understanding_reference {
	struct wording reference_text;
	int gv_result;
	int mword;
	int mistaken;
	int pluralised_reference;
	int reversed_reference;
	action_name *an_reference;
	parse_node *spec_reference;
	struct understanding_reference *next;
} understanding_reference;

@ New grammar arrives in the system in two ways: primarily by means of explicit
Understand sentences in the source text, but also secondarily in the form
of table entries or other values used to match against snippets. For example:

>> Understand "drill [something]" as drilling.

>> if the player's command matches "room [number]", ...

@ Understand sentences can also revoke existing grammar, in some cases, as
we shall see. They are not read in the main assertion traverse, since they
depend on too much not known then: they have a traverse of their own, and
so do not use the sentence handler system adopted by the main assertion
traverse.

@ =
int base_problem_count = 0;

int PL::Parsing::understand_as_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Understand... as..." */
		case ACCEPT_SMFT:
			Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
			<nounphrase>(O2W);
			V->next = <<rp>>;
			<nounphrase>(OW);
			V->next->next = <<rp>>;
			return TRUE;
		case TRAVERSE_FOR_GRAMMAR_SMFT:
			base_problem_count = problem_count;
			PL::Parsing::understand_sentence(Node::get_text(V->next), Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

@ =
void PL::Parsing::traverse(void) {
	SyntaxTree::traverse(Task::syntax_tree(), PL::Parsing::visit);
}
void PL::Parsing::visit(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down))
		Assertions::Traverse::try_special_meaning(TRAVERSE_FOR_GRAMMAR_SMFT, p->down);
}

@ The secondary means of acquiring new grammar is used when compiling type
specifications of type |VALUE/UNDERSTANDING| and when compiling the entries
of "topic" columns in tables. These will usually be simple constructions of
individual grammar lines, but they need to belong to a grammar verb (GV)
nevertheless, even if they are the only thing on that GV. Such GVs compile
to routines for parsing snippets, and no pointers exist to them in other
Inform data structures: the result of the routine below, assuming no problems
are issued, is simply that the name of a snippet-parsing routine is printed.

=
void PL::Parsing::compile_understanding(inter_t *val1, inter_t *val2, wording W, int table_entry) {
	if (<nominative-pronoun>(W)) { *val1 = LITERAL_IVAL; *val2 = 0; }
	else {
		cached_understanding *cu;
		LOOP_OVER(cu, cached_understanding)
			if (Wordings::match(cu->understanding_text, W)) {
				Emit::to_ival(val1, val2, cu->cu_iname);
				return;
			}
		base_problem_count = problem_count;
		PL::Parsing::Tokens::General::prepare_consultation_gv();
		if (table_entry) {
			LOOP_THROUGH_WORDING(k, W) {
				if (<quoted-text>(Wordings::one_word(k))) {
					PL::Parsing::understand_block(Wordings::one_word(k), NULL, EMPTY_WORDING, TRUE);
				}
			}
		} else {
			PL::Parsing::understand_block(W, NULL, EMPTY_WORDING, FALSE);
		}
		inter_name *iname = PL::Parsing::Tokens::General::print_consultation_gv_name();
		if (iname) {
			cu = CREATE(cached_understanding);
			cu->understanding_text = W;
			cu->cu_iname = iname;
			Emit::to_ival(val1, val2, iname);
		}
	}
}

@h Dividing Understand into cases.
We will need some context variables.

@d COMMAND_UNDERSTAND_FORM 1
@d PROPERTY_UNDERSTAND_FORM 2
@d GRAMMAR_UNDERSTAND_FORM 3
@d NOTHING_UNDERSTAND_FORM 4
@d NO_UNDERSTAND_FORM 5

@ Understand sentences take three different forms -- so different, in fact,
that we will parse the subject NP to see which form we have, and only then
parse the object NP (using a different grammar for each of the three forms).
As examples:

>> Understand "photograph [something]" as photographing.
>> Understand the command "access" as "open".
>> Understand the unbroken property as describing the pot.

=
<understand-sentence-subject> ::=
	nothing |    ==> NOTHING_UNDERSTAND_FORM; *XP = NULL
	<understand-property-list> |    ==> PROPERTY_UNDERSTAND_FORM; *XP = RP[1]
	the command/commands <understand-regular-list> |    ==> COMMAND_UNDERSTAND_FORM; *XP = RP[1]
	the verb/verbs ... |    ==> @<Issue PM_OldVerbUsage problem@>
	<understand-regular-list>							==> GRAMMAR_UNDERSTAND_FORM; *XP = RP[1]

@<Issue PM_OldVerbUsage problem@> =
	*X = NO_UNDERSTAND_FORM;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_OldVerbUsage),
		"this is an outdated form of words",
		"and Inform now prefers 'Understand the command ...' "
		"rather than 'Understand the verb ...'. (Since this "
		"change was made in beta-testing, quite a few old "
		"source texts still use the old form: the authors "
		"of Inform apologise for any nuisance incurred.)");

@ In the first two cases, a list of quoted text appears:

=
<understand-regular-list> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<understand-regular-entry> <understand-regular-tail> |    ==> @<Compose understand item list@>
	<understand-regular-entry>									==> 0; *XP = RP[1];

<understand-regular-tail> ::=
	, _and/or <understand-regular-list> |    ==> 0; *XP = RP[1];
	_,/and/or <understand-regular-list>							==> 0; *XP = RP[1];

<understand-regular-entry> ::=
	...															==> @<Make understand item@>

@ In the third case, the subject NP is a list of property names written in the
formal way (with "property").

=
<understand-property-list> ::=
	... |    ==> 0; *XP = NULL; return preform_lookahead_mode; /* match only when looking ahead */
	<understand-property-entry> <understand-property-tail> |    ==> @<Compose understand item list@>
	<understand-property-entry>									==> 0; *XP = RP[1];

<understand-property-tail> ::=
	, _and/or <understand-property-list> |    ==> 0; *XP = RP[1];
	_,/and/or <understand-property-list>						==> 0; *XP = RP[1];

<understand-property-entry> ::=
	<property-name> property |    ==> @<Make understand property item@>
	... property												==> @<Issue PM_UnknownUnderstandProperty problem@>

@<Issue PM_UnknownUnderstandProperty problem@> =
	if (!preform_lookahead_mode)
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnknownUnderstandProperty),
		"I don't understand what property that refers to",
		"but it doesn't seem to be a property I know. An example of "
		"correct usage is 'understand the transparent property as "
		"describing a container.'");

@<Compose understand item list@> =
	understanding_item *ui1 = RP[1];
	understanding_item *ui2 = RP[2];
	if (ui1 == NULL) { *XP = ui2; }
	else if (ui2 == NULL) { *XP = ui1; }
	else {
		ui1->next = ui2;
		*XP = ui1;
	}

@<Make understand item@> =
	*XP = NULL;
	if (!preform_lookahead_mode) {
		understanding_item *ui = CREATE(understanding_item);
		ui->quoted_text = W;
		ui->quoted_property = NULL;
		ui->next = NULL;
		*XP = ui;
	}

@<Make understand property item@> =
	*XP = NULL;
	if (!preform_lookahead_mode) {
		understanding_item *ui = CREATE(understanding_item);
		ui->quoted_text = EMPTY_WORDING;
		ui->quoted_property = RP[1];
		ui->next = NULL;
		*XP = ui;
	}

@ =
understanding_reference ur_being_parsed;

@ Now we turn to the object phrase. As noted above, we use three different
grammars for this; one for each of the possible subject phrase forms. The
first is the most popularly used:

>> Understand "take [something]" as taking.

It's not widely known, but the object phrase here can be a list.

=
<understand-sentence-object> ::=
	<understand-sentence-object-uncond> when/while ... |    ==> 2; *XP = RP[1]
	<understand-sentence-object-uncond>						==> 1; *XP = RP[1]

<understand-sentence-object-uncond> ::=
	... |    ==> 0; return preform_lookahead_mode; /* match only when looking ahead */
	<understand-sentence-entry> <understand-sentence-object-tail> |    ==> @<Compose understand reference list@>
	<understand-sentence-entry>								==> 0; *XP = RP[1]

<understand-sentence-object-tail> ::=
	, _and/or <understand-sentence-object-uncond> |    ==> 0; *XP = RP[1]
	_,/and/or <understand-sentence-object-uncond>			==> 0; *XP = RP[1]

<understand-sentence-entry> ::=
	<understand-as-this>									==> 0; if (!preform_lookahead_mode) @<Deal with UT vars@>;

@<Compose understand reference list@> =
	understanding_reference *ui1 = RP[1];
	understanding_reference *ui2 = RP[2];
	if (ui1 == NULL) { *XP = ui2; }
	else if (ui2 == NULL) { *XP = ui1; }
	else {
		ui1->next = ui2;
		*XP = ui1;
	}

@<Deal with UT vars@> =
	if (R[1] == -1) {
		*XP = NULL;
	} else {
		understanding_reference *ur = CREATE(understanding_reference);
		*ur = ur_being_parsed;
		*XP = ur;
	}

@ Each of the items in the object phrase list is matched against:

=
<understand-as-this> ::=
	... |    ==> 0; @<Clear UT vars@>; return preform_lookahead_mode; /* match only when looking ahead */
	a mistake |    ==> 0; ur_being_parsed.gv_result = GV_IS_COMMAND; ur_being_parsed.mistaken = TRUE;
	a mistake ( <quoted-text> ) |    ==> 0; ur_being_parsed.gv_result = GV_IS_COMMAND; ur_being_parsed.mistaken = TRUE; ur_being_parsed.mword = R[1]
	a mistake ... |    ==> @<Issue PM_TextlessMistake problem@>
	the plural of <understand-ref> |    ==> R[1]; ur_being_parsed.pluralised_reference = TRUE;
	plural of <understand-ref> |    ==> R[1]; ur_being_parsed.pluralised_reference = TRUE;
	<quoted-text> |    ==> 0; ur_being_parsed.gv_result = GV_IS_TOKEN;
	<understand-ref> ( with nouns reversed ) |    ==> R[1]; ur_being_parsed.reversed_reference = TRUE;
	<understand-ref>							==> R[1]

<understand-ref> ::=
	<action-name> |    ==> 0; ur_being_parsed.an_reference = RP[1];
	<s-descriptive-type-expression> |    ==> 0; ur_being_parsed.spec_reference = RP[1];
	<s-variable> |    ==> @<Issue PM_UnderstandVariable problem@>
	...											==> @<Issue PM_UnderstandVague problem@>

@<Clear UT vars@> =
	ur_being_parsed.reference_text = W;
	ur_being_parsed.mword = -1;
	ur_being_parsed.mistaken = FALSE;
	ur_being_parsed.pluralised_reference = FALSE;
	ur_being_parsed.reversed_reference = FALSE;
	ur_being_parsed.an_reference = NULL;
	ur_being_parsed.spec_reference = NULL;
	ur_being_parsed.next = NULL;
	ur_being_parsed.gv_result = GV_IS_OBJECT;

@<Issue PM_TextlessMistake problem@> =
	*X = -1;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_TextlessMistake),
		"when 'understand' results in a mistake it can only be "
		"followed by a textual message in brackets",
		"so for instance 'understand \"take\" as a mistake "
		"(\"In this sort of game, a noun is required there.\").'");

@<Issue PM_UnderstandVariable problem@> =
	*X = -1;
	LOG("Offending pseudo-meaning is: %W\n", W);
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandVariable),
		"this meaning is a value that varies",
		"whereas I need something fixed. "
		"(The most common case of this is saying that something should be "
		"understood as 'the player', which is actually a variable, because "
		"the perspective of play can change. Writing 'yourself' instead will "
		"usually do.)");

@<Issue PM_UnderstandVague problem@> =
	*X = -1;
	LOG("Offending pseudo-meaning is: %W\n", W);
	@<Actually issue PM_UnderstandVague problem@>;

@<Actually issue PM_UnderstandVague problem@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandVague),
		"'understand ... as ...' should be followed "
		"by a meaning",
		"which might be an action (e.g., "
		"'understand \"take [something]\" as taking'), a "
		"thing ('understand \"stove\" as the oven') or more "
		"generally a value ('understand \"huitante\" as 80'), "
		"or a named token for use in further grammar "
		"('understand \"near [something]\" as \"[location "
		"phrase]\"'). Also, the meaning needs to be precise, "
		"so 'understand \"x\" as a number' is not "
		"allowed - it does not say which number.");

@ The second form of the sentence has an object phrase like so:

>> Understand the command "snatch" as "take".

Here the grammar is very simple, and the object can't be a list.

=
<understand-command-sentence-object> ::=
	... when/while ... |    ==> @<Issue PM_UnderstandCommandWhen problem@>
	something new |    ==> 0
	<quoted-text> |    ==> Wordings::first_wn(W)
	...								==> @<Issue PM_NotOldCommand problem@>

@<Issue PM_UnderstandCommandWhen problem@> =
	*X = -1;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandCommandWhen),
		"'understand the command ... as ...' is not allowed to have a "
		"'... when ...' clause",
		"for the moment at any rate.");

@<Issue PM_NotOldCommand problem@> =
	*X = -1;
	@<Actually issue PM_NotOldCommand problem@>;

@ The third and final form of the sentence has an object phrase like so:

>> Understand the unbroken property as describing the pot.

Once again, the object can't be a list. Syntactically the item(s) referred
to or described can be of any kind, but in fact we restrict to kinds of object.

=
<understand-property-sentence-object> ::=
	<understand-property-sentence-object-unconditional> when/while ... |    ==> 2; *XP = RP[1]; <<level>> = R[1]
	<understand-property-sentence-object-unconditional>						==> 1; *XP = RP[1]; <<level>> = R[1]

<understand-property-sentence-object-unconditional> ::=
	referring to <understand-property-reference> |    ==> 1; *XP = RP[1]
	describing <understand-property-reference> |    ==> 2; *XP = RP[1]
	...												==> @<Issue PM_BadUnderstandProperty problem@>

<understand-property-reference> ::=
	<k-kind> |    ==> @<Make reference from kind, if a kind of object@>
	<instance-of-object> |    ==> 0; *XP = Instances::as_subject(RP[1]);
	...						==> @<Issue PM_BadUnderstandPropertyAs problem@>

@<Make reference from kind, if a kind of object@> =
	kind *K = RP[1];
	if (Kinds::Compare::lt(K, K_object)) *XP = Kinds::Knowledge::as_subject(K);
	else return FALSE;

@<Issue PM_BadUnderstandProperty problem@> =
	*X = 0;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_BadUnderstandProperty),
		"'understand the ... property as ...' is only allowed if "
		"followed by 'describing ...' or 'referring to ...'",
		"so for instance 'understand the transparent property as "
		"describing a container.'");

@<Issue PM_BadUnderstandPropertyAs problem@> =
	*XP = NULL;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_BadUnderstandPropertyAs),
		"I don't understand what single thing or kind of thing that refers to",
		"but it does need to be an object (or kind of object) and not "
		"some other sort of value. For instance, 'understand the transparent "
		"property as describing a container.' is okay because 'a container' "
		"is a kind of object.");

@ =
void PL::Parsing::understand_sentence(wording W, wording ASW) {
	LOGIF(GRAMMAR, "Parsing understand <%W> as <%W>\n", W, ASW);
	if (problem_count > base_problem_count) return;
	<understand-sentence-subject>(W);
	if (problem_count > base_problem_count) return;
	understanding_item *ui_list = <<rp>>;
	int form = <<r>>;
	switch (form) {
		case COMMAND_UNDERSTAND_FORM: @<Process Understand command@>; break;
		case PROPERTY_UNDERSTAND_FORM: @<Process Understand property@>; break;
		case GRAMMAR_UNDERSTAND_FORM: /* and */
		case NOTHING_UNDERSTAND_FORM: @<Process Understand grammar@>; break;
	}
}

@<Process Understand command@> =
	<understand-command-sentence-object>(ASW);
	if (problem_count > base_problem_count) return;
	wording W = (<<r>> != 0) ? (Wordings::one_word(<<r>>)) : EMPTY_WORDING;
	for (; ui_list; ui_list = ui_list->next) {
		if (problem_count > base_problem_count) break;
		PL::Parsing::understand_the_command(ui_list->quoted_text, W);
	}

@<Process Understand property@> =
	<understand-property-sentence-object>(ASW);
	if (problem_count > base_problem_count) return;
	wording UW = EMPTY_WORDING;
	inference_subject *subj = <<rp>>;
	if (<<r>> == 2) UW = GET_RW(<understand-property-sentence-object>, 1);
	for (; ui_list; ui_list = ui_list->next) {
		if (problem_count > base_problem_count) break;
		PL::Parsing::understand_property_block(ui_list->quoted_property, <<level>>, subj, UW);
	}

@<Process Understand grammar@> =
	<understand-sentence-object>(ASW);
	if (problem_count > base_problem_count) return;
	understanding_reference *ur_list_from = <<rp>>;
	wording UW = EMPTY_WORDING;
	if (<<r>> == 2) UW = GET_RW(<understand-sentence-object>, 1);
	if (form == NOTHING_UNDERSTAND_FORM) {
		understanding_reference *ur_list;
		for (ur_list = ur_list_from; ur_list; ur_list = ur_list->next) {
			if (problem_count > base_problem_count) break;
			PL::Parsing::understand_nothing(ur_list, UW);
		}
	} else {
		for (; ui_list; ui_list = ui_list->next) {
			understanding_reference *ur_list;
			for (ur_list = ur_list_from; ur_list; ur_list = ur_list->next) {
				if (problem_count > base_problem_count) break;
				PL::Parsing::understand_block(ui_list->quoted_text, ur_list, UW, FALSE);
			}
		}
	}

@h Understand command verbs.
These sentences allow us to control the assignment of command verbs such
as TAKE or EXAMINE to grammars, which will normally be an automatic process
based on grammar lines (see below). We can make one command verb an alias
for another, or revoke this by making it "something new".

After some debate, we decided that it ought to be legal to declare
"Understand the command "wibble" as something new" even in cases
where no "wibble" command existed already: extensions might want this
to assure that they have exclusive use of a command, for instance. So the
problem message for this case is now commented out.

=
void PL::Parsing::understand_the_command(wording W, wording ASW) {
	W = Wordings::last_word(W);
	Word::dequote(Wordings::first_wn(W));
	wchar_t *p = Lexer::word_text(Wordings::first_wn(W));
	for (int i=0; p[i]; i++)
		if (p[i] == ' ') {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_SpacyCommand),
				"'understand the command ... as ...' is only allowed when "
				"the old command is a single word",
				"so for instance 'understand the command \"capture\" as \"get\"' "
				"is okay, but 'understand the command \"capture the flag\" as "
				"\"get\"' is not.");
			break;
		}
	grammar_verb *gv = PL::Parsing::Verbs::find_command(W);

	if (Wordings::empty(ASW)) {
		if (gv) PL::Parsing::Verbs::remove_command(gv, W);
	} else {
		if (gv)	{
			if (PL::Parsing::Verbs::is_empty(gv)) {
				DESTROY(gv, grammar_verb);
				gv = NULL;
			} else {
				Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_NotNewCommand),
					"'understand the command ... as ...' is only allowed when "
					"the new command has no meaning already",
					"so for instance 'understand \"drop\" as \"throw\"' is not "
					"allowed because \"drop\" already has a meaning.");
				return;
			}
		}
		Word::dequote(Wordings::first_wn(ASW));
		gv = PL::Parsing::Verbs::find_command(ASW);
		if (gv == NULL) {
			@<Actually issue PM_NotOldCommand problem@>;
		} else {
			PL::Parsing::Verbs::add_command(gv, W);
		}
	}
}

@<Actually issue PM_NotOldCommand problem@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_NotOldCommand),
		"'understand the command ... as ...' should end with a command "
		"already defined",
		"as in 'understand the command \"steal\" as \"take\"'. (This "
		"problem is sometimes seen when the wrong sort of Understand... "
		"sentence has been used: 'Understand the command \"steal\" as "
		"\"take\".' tells me to treat the command STEAL as a "
		"synonym for TAKE when reading the player's commands, whereas "
		"'Understand \"steal [something]\" as taking.' tells me that "
		"here is a specific grammar for what can be said using the "
		"STEAL command.)");

@h Understand property names.

=
void PL::Parsing::understand_property_block(property *pr, int level, inference_subject *subj, wording WHENW) {
	if ((Properties::is_either_or(pr) == FALSE) &&
		(Str::len(Kinds::Behaviour::get_recognition_only_GPR(Properties::Valued::kind(pr))) == 0) &&
		((Kinds::Compare::le(Properties::Valued::kind(pr), K_object)) ||
			(Kinds::Behaviour::request_I6_GPR(Properties::Valued::kind(pr)) == FALSE))) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_BadReferringProperty),
			"that property is of a kind which I can't recognise in "
			"typed commands",
			"so that it cannot be understand as describing or referring to "
			"something. I can understand either/or properties, properties "
			"with a limited list of named possible values, numbers, times "
			"of day, or units; but certain built-into-Inform kinds of value "
			"(like snippet or rulebook, for instance) I can't use.");
	}
	if (PL::Parsing::Visibility::seek(pr, subj, level, WHENW) == FALSE) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnknownUnpermittedProperty),
			"that property is not allowed for the thing or kind in question",
			"just as (ordinarily) 'understand the open property as describing a "
			"device' would not be allowed because it makes no sense to call a "
			"device 'open'.");
	}
	return;
}

@ =
void PL::Parsing::understand_nothing(understanding_reference *ur, wording WHENW) {
	if ((ur == NULL) || (ur->gv_result != GV_IS_OBJECT) || (ur->an_reference == NULL)) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandNothingNonAction),
			"'Understand nothing as ...' must be followed by an action",
			"such as 'Understand nothing as taking.'");
	} else if (Wordings::nonempty(WHENW)) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandNothingWhen),
			"'Understand nothing as ...' must be unconditional",
			"so your 'when' or 'while' condition will have to go.");
	} else {
		action_name *an = ur->an_reference;
		LOGIF(GRAMMAR_CONSTRUCTION, "Understand nothing as: $l\n", an);
		PL::Actions::remove_gl(an);
		grammar_verb *gv;
		LOOP_OVER(gv, grammar_verb) PL::Parsing::Verbs::remove_action(gv, an);
	}
}

@ =
void PL::Parsing::understand_block(wording W, understanding_reference *ur, wording WHENW,
	int table_entry) {
	int gv_is = GV_IS_COMMAND,
		reversed = FALSE, mistake_text_at = 0, mistakenly = FALSE, pluralised = FALSE;
	wording file_under = EMPTY_WORDING;
	wording XW = EMPTY_WORDING;
	kind *K = NULL;
	action_name *an = NULL;
	grammar_line *gl = NULL;
	parse_node *to_pn = NULL;
	inference_subject *subj = NULL;
	property *gv_prn = NULL;
	parse_node *gl_value = NULL;
	pcalc_prop *u_prop = NULL;

	if (problem_count > base_problem_count) return;
	if (<quoted-text>(W) == FALSE) {
		if (table_entry)
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"a table entry in a 'topic' column must be a single double-quoted "
				"text",
				"such as \"eternity\" or \"peruvian skies\".");
		else if (TEST_COMPILATION_MODE(SPECIFICATIONS_CMODE))
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_NontextualUnderstandInAP),
				"the topic here should be in the form of a textual description",
				"as in 'asking about \"[something]\"'.");
		else
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_NontextualUnderstand),
				"'understand' should be followed by a textual description",
				"as in 'understand \"take [something]\" as taking the noun'.");
		return;
	}
	if (Word::well_formed_text_routine(Lexer::word_text(Wordings::first_wn(W))) == FALSE) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandMismatch),
			"'understand' should be followed by text in which brackets "
			"'[' and ']' match",
			"so for instance 'understand \"take [something]\" as taking the noun' "
			"is fine, but 'understand \"take]\" as taking' is not.");
		return;
	}
	mistake_text_at = 0;
	mistakenly = FALSE;
	if (ur == NULL) gv_is = GV_IS_CONSULT;
	else {
		an = ur->an_reference;
		pluralised = ur->pluralised_reference;
		reversed = ur->reversed_reference;
		if (ur->mword >= 0) mistake_text_at = ur->mword;
		if (ur->mistaken) mistakenly = TRUE;
		gv_is = ur->gv_result;

		if (gv_is == GV_IS_OBJECT) {
			gv_is = GV_IS_COMMAND;
			if (an == NULL) {
				instance *target;
				parse_node *spec = ur->spec_reference;
				target = Specifications::object_exactly_described_if_any(spec);
				if (target) {
					subj = Instances::as_subject(target);
					gv_is = GV_IS_OBJECT;
					if (Descriptions::is_qualified(spec)) {
						LOG("Offending description: $T", spec);
						Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsQualified),
							"I cannot understand text as meaning an object "
							"qualified by relative clauses or properties",
							"only a specific thing, a specific value or a kind. "
							"(But the same effect can usually be achieved with "
							"a 'when' clause. For instance, although 'Understand "
							"\"bad luck\" as the broken mirror' is not allowed, "
							"'Understand \"bad luck\" as the mirror when the "
							"mirror is broken' produces the desired effect.)");
						return;
					}
				} else {
					RetryValue:
					LOGIF(GRAMMAR_CONSTRUCTION, "Understand as specification: $T", spec);
					if ((Specifications::is_kind_like(spec)) &&
						(Kinds::Compare::le(Specifications::to_kind(spec), K_object) == FALSE)) goto ImpreciseProblemMessage;
					if (ParseTreeUsage::is_phrasal(spec)) goto ImpreciseProblemMessage;
					if (Rvalues::is_nothing_object_constant(spec)) goto ImpreciseProblemMessage;
					if (ParseTreeUsage::is_rvalue(spec)) {
						K = Node::get_kind_of_value(spec);
						if (Kinds::Behaviour::request_I6_GPR(K)) {
							gl_value = spec;
							gv_is = GV_IS_VALUE;
						} else {
							if (Kinds::get_construct(K) == CON_activity)
							Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsActivity),
								"this 'understand ... as ...' gives text "
								"meaning an activity",
								"rather than an action. Since activities "
								"happen when Inform decides they need to "
								"happen, not in response to typed commands, "
								"this doesn't make sense.");
							else
							Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsBadValue),
								"'understand ... as ...' gives text "
								"meaning a value whose kind is not allowed",
								"and should be a value such as 100.");
							return;
						}
					} else if (Specifications::is_description(spec)) {
						if ((Descriptions::to_instance(spec) == NULL) &&
							(Kinds::Compare::lt(Specifications::to_kind(spec),
								K_object) == FALSE)
							&& (Descriptions::number_of_adjectives_applied_to(spec) == 1)
							&& (AdjectiveUsages::get_parity(Calculus::Propositions::first_adjective_usage(Specifications::to_proposition(spec), NULL)))) {
							adjectival_phrase *aph =
								AdjectiveUsages::get_aph(Calculus::Propositions::first_adjective_usage(Specifications::to_proposition(spec), NULL));
							instance *q = Adjectives::Meanings::has_ENUMERATIVE_meaning(aph);
							if (q) {
								spec = Rvalues::from_instance(q);
								goto RetryValue;
							}
							property *prn = Adjectives::Meanings::has_EORP_meaning(aph, NULL);
							if (prn) {
								gv_is = GV_IS_PROPERTY_NAME;
								gv_prn = prn;
								LOGIF(GRAMMAR_CONSTRUCTION, "Grammar confirmed for property $Y\n", gv_prn);
							}
						}
						if ((Descriptions::is_qualified(spec)) && (gv_prn == NULL)) {
							u_prop = Calculus::Propositions::copy(Descriptions::to_proposition(spec));
							spec = Specifications::from_kind(Specifications::to_kind(spec));
						}
						kind *K = Specifications::to_kind(spec);
						if ((K) && (Kinds::Compare::lt(K, K_object))) {
							subj = Kinds::Knowledge::as_subject(K);
							gv_is = GV_IS_OBJECT;
						} else if (gv_prn == NULL) goto ImpreciseProblemMessage;
					} else {
						ImpreciseProblemMessage:
						LOG("Offending pseudo-meaning is: $T", spec);
						@<Actually issue PM_UnderstandVague problem@>;
						return;
					}
				}
			}
		}
	}

	if ((pluralised) && (gv_is != GV_IS_OBJECT)) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandPluralValue),
			"'understand' as a plural can only apply to things, rooms or kinds "
			"of things or rooms",
			"so 'Understand \"paperwork\" as the plural of a document.' is "
			"fine (assuming a document is a kind of thing), but 'Understand "
			"\"dozens\" as the plural of 12' is not.");
		return;
	}

	int i, skip = FALSE, literal_punct = FALSE; wchar_t *p = Lexer::word_text(Wordings::first_wn(W));
	for (i=0; p[i]; i++) {
		if (p[i] == '[') skip = TRUE;
		if (p[i] == ']') skip = FALSE;
		if (skip) continue;
		if ((p[i] == '.') || (p[i] == ',') ||
			(p[i] == '!') || (p[i] == '?') || (p[i] == ':') || (p[i] == ';'))
			literal_punct = TRUE;
	}
	if (literal_punct) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_LiteralPunctuation),
			"'understand' text cannot contain literal punctuation",
			"or more specifically cannot contain any of these: . , ! ? : ; "
			"since they are already used in various ways by the parser, and "
			"would not correctly match here.");
		return;
	}

	XW = Feeds::feed_C_string_full(Lexer::word_text(Wordings::first_wn(W)), TRUE, GRAMMAR_PUNCTUATION_MARKS);
	to_pn = NounPhrases::new_raw(W);
	PL::Parsing::Tokens::break_into_tokens(to_pn, XW);
	if (to_pn->down == NULL) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandEmptyText),
			"'understand' should be followed by text which contains at least "
			"one word or square-bracketed token",
			"so for instance 'understand \"take [something]\" as taking' "
			"is fine, but 'understand \"\" as the fog' is not. The same "
			"applies to the contents of 'topic' columns in tables, since "
			"those are also instructions for understanding.");
		return;
	}
	if (gv_is == GV_IS_COMMAND) {
		LOGIF(GRAMMAR_CONSTRUCTION, "Command grammar: $T\n", to_pn);

		LOOP_THROUGH_WORDING(i, XW)
			if (i < Wordings::last_wn(XW))
				if ((compare_word(i, COMMA_V)) && (compare_word(i+1, COMMA_V))) {
					Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandCommaCommand),
						"'understand' as an action cannot involve a comma",
						"since a command leading to an action never does. "
						"(Although Inform understands commands like 'PETE, LOOK' "
						"only the part after the comma is read as an action command: "
						"the part before the comma is read as the name of someone, "
						"according to the usual rules for parsing a name.) "
						"Because of the way Inform processes text with square "
						"brackets, this problem message is also sometimes seen "
						"if empty square brackets are used, as in 'Understand "
						"\"bless []\" as blessing.'");
					return;
				}

		if (PL::Parsing::Tokens::is_literal(to_pn->down) == FALSE)
			file_under = EMPTY_WORDING; /* this will go into the no verb verb */
		else file_under = Wordings::first_word(Node::get_text(to_pn->down));
	}
	LOGIF(GRAMMAR, "GV is %d, an is $l, file under is %W\n", gv_is, an, file_under);
	if (gv_is != GV_IS_COMMAND) gl = PL::Parsing::Lines::new(Wordings::first_wn(W), NULL, to_pn, reversed, pluralised);
	else gl = PL::Parsing::Lines::new(Wordings::first_wn(W), an, to_pn, reversed, pluralised);
	if (mistakenly) PL::Parsing::Lines::set_mistake(gl, mistake_text_at);
	if (Wordings::nonempty(WHENW)) {
		PL::Parsing::Lines::set_understand_when(gl, WHENW);
		if (gv_is == GV_IS_CONSULT) {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* at present, I7 syntax prevents this anyway */
				"'when' cannot be used with this kind of 'Understand'",
				"for the time being at least.");
			return;
		}
	}
	if (Wordings::nonempty(WHENW)) {
		PL::Parsing::Lines::set_understand_when(gl, WHENW);
		if (gv_is == GV_IS_CONSULT) {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* at present, I7 syntax prevents this anyway */
				"'when' cannot be used with this kind of 'Understand'",
				"for the time being at least.");
			return;
		}
	}
	if (u_prop) {
		PL::Parsing::Lines::set_understand_prop(gl, u_prop);
		if (gv_is == GV_IS_CONSULT) {
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible), /* at present, I7 syntax prevents this anyway */
				"'when' cannot be used with this kind of 'Understand'",
				"for the time being at least.");
			return;
		}
	}

	switch(gv_is) {
		case GV_IS_TOKEN:
			XW = Feeds::feed_C_string_full(Lexer::word_text(Wordings::first_wn(ur->reference_text)), TRUE, GRAMMAR_PUNCTUATION_MARKS);
			LOGIF(GRAMMAR_CONSTRUCTION, "GV_IS_TOKEN as words: %W\n", XW);
			if (PL::Parsing::valid_new_token_name(XW) == FALSE) {
				Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsCompoundText),
					"if 'understand ... as ...' gives the meaning as text "
					"then it must describe a single new token",
					"so that 'Understand \"group four/five/six\" as "
					"\"[department]\"' is legal (defining a new token "
					"\"[department]\", or adding to its definition if it "
					"already existed) but 'Understand \"take [thing]\" "
					"as \"drop [thing]\"' is not allowed, and would not "
					"make sense, because \"drop [thing]\" is a combination "
					"of two existing tokens - not a single new one.");
			}
			PL::Parsing::Verbs::add_line(PL::Parsing::Verbs::named_token_new(Wordings::trim_both_ends(Wordings::trim_both_ends(XW))), gl);
			break;
		case GV_IS_COMMAND:
			PL::Parsing::Verbs::add_line(PL::Parsing::Verbs::find_or_create_command(file_under), gl);
			break;
		case GV_IS_OBJECT:
			PL::Parsing::Verbs::add_line(PL::Parsing::Verbs::for_subject(subj), gl);
			break;
		case GV_IS_VALUE:
			PL::Parsing::Lines::set_single_type(gl, gl_value);
			PL::Parsing::Verbs::add_line(PL::Parsing::Verbs::for_kind(K), gl);
			break;
		case GV_IS_PROPERTY_NAME:
			PL::Parsing::Verbs::add_line(PL::Parsing::Verbs::for_prn(gv_prn), gl);
			break;
		case GV_IS_CONSULT:
			PL::Parsing::Lines::set_single_type(gl, gl_value);
			PL::Parsing::Verbs::add_line(
				PL::Parsing::Tokens::General::get_consultation_gv(), gl);
			break;
	}
}

int PL::Parsing::valid_new_token_name(wording W) {
	int cc=0;
	LOOP_THROUGH_WORDING(i, W)
		if (compare_word(i, COMMA_V)) cc++;
	Word::dequote(Wordings::first_wn(W));
	if (*(Lexer::word_text(Wordings::first_wn(W))) != 0) return FALSE;
	Word::dequote(Wordings::last_wn(W));
	if (*(Lexer::word_text(Wordings::last_wn(W))) != 0) return FALSE;
	if (cc != 2) return FALSE;
	return TRUE;
}
