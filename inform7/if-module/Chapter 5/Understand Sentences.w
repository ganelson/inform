[Understand::] Understand Sentences.

Command parser grammar is laid out in special Understand... sentences.

@h Traversing.
When the "parser" plugin is active, any sentence in the form "Understand...
as..." is considered to be an instruction about the command grammar, which
is a special data structure created by Inform for the use of the command
parser at run-time.

Such sentences share a single special meaning:

=
int Understand::make_special_meanings(void) {
	SpecialMeanings::declare(Understand::understand_as_SMF, I"understand-as", 1);
	return FALSE;
}

@ Understand sentences are not read in the main assertion traverse, since they
depend on too much not known then: they have a traverse of their own. See
//ParsingPlugin::production_line// for how it slots in.

@e TRAVERSE_FOR_GRAMMAR_SMFT

=
void Understand::traverse(void) {
	SyntaxTree::traverse(Task::syntax_tree(), Understand::visit);
}
void Understand::visit(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down))
		MajorNodes::try_special_meaning(TRAVERSE_FOR_GRAMMAR_SMFT, p->down);
}

@ Understand sentences are always accepted: that is, any sentence at all in
the "Understand... as..." shape will pass the |ACCEPT_SMFT| traverse. But
such a sentence is then not acted upon in the regular assertion traverses,
as noted above, and instead we wait until //Understand::visit// causes
the following to be called.

The practical result is that //Understand::understand_sentence// is called
on each such sentence in turn.

=
int base_problem_count = 0;

int Understand::understand_as_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "Understand... as..." */
		case ACCEPT_SMFT:
			<np-unparsed>(O2W);
			V->next = <<rp>>;
			<np-unparsed>(OW);
			V->next->next = <<rp>>;
			return TRUE;
		case TRAVERSE_FOR_GRAMMAR_SMFT:
			base_problem_count = problem_count;
			Understand::understand_sentence(
				Node::get_text(V->next), Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

@h The subject phrase.
Understand sentences take several different forms -- so different, in fact,
that we will parse the subject phrase to see which form we have, and only then
parse the object phrase (using a different grammar for each of the forms).
As examples:
= (text as Inform 7)
Understand nothing as the pot.
Understand the unbroken property as describing the pot.
Understand the command "access" as "open".
Understand "earthenware" as the pot. Understand "photograph [something]" as photographing.
=
<understand-sentence-sp> has, as its integer result, one of these:

@e COMMAND_UNDERSTAND_FORM from 1
@e PROPERTY_UNDERSTAND_FORM
@e GRAMMAR_UNDERSTAND_FORM
@e NOTHING_UNDERSTAND_FORM
@e NO_UNDERSTAND_FORM

@ As its pointer result, it has a pointer to a linked list of the following
objects, which are really just unions of being a text in quotes or a property name:

=
typedef struct understanding_item {
	struct wording quoted_text;
	struct property *quoted_property;
	struct understanding_item *next;
} understanding_item;

understanding_item *Understand::text_item(wording W) {
	if (preform_lookahead_mode) return NULL;
	understanding_item *ui = CREATE(understanding_item);
	ui->quoted_text = W;
	ui->quoted_property = NULL;
	ui->next = NULL;
	return ui;
}

understanding_item *Understand::property_item(property *p) {
	if (preform_lookahead_mode) return NULL;
	understanding_item *ui = CREATE(understanding_item);
	ui->quoted_text = EMPTY_WORDING;
	ui->quoted_property = p;
	ui->next = NULL;
	return ui;
}

understanding_item *Understand::list_ui(understanding_item *ui1, understanding_item *ui2) {
	if (ui1 == NULL) return ui2;
	if (ui2 == NULL) return ui1;
	ui1->next = ui2;
	return ui1;
}

@ So, then, the Preform for the subject phrase is as follows:

=
<understand-sentence-sp> ::=
	nothing |                                        ==> { NOTHING_UNDERSTAND_FORM, NULL }
	<understand-prop-list> |                         ==> { PROPERTY_UNDERSTAND_FORM, RP[1] }
	the command/commands <understand-reg-list> |     ==> { COMMAND_UNDERSTAND_FORM, RP[1] }
	the verb/verbs ... |                             ==> @<Issue PM_OldVerbUsage problem@>
	<understand-reg-list>                            ==> { GRAMMAR_UNDERSTAND_FORM, RP[1] }

<understand-reg-list> ::=
	... |                                            ==> { lookahead }
	<understand-reg-entry> <understand-reg-tail> |   ==> { -, Understand::list_ui(RP[1], RP[2]) }
	<understand-reg-entry>                           ==> { pass 1 }

<understand-reg-tail> ::=
	, _and/or <understand-reg-list> |                ==> { pass 1 }
	_,/and/or <understand-reg-list>                  ==> { pass 1 }

<understand-reg-entry> ::=
	...                                              ==> { -, Understand::text_item(W) }

<understand-prop-list> ::=
	... |                                            ==> { lookahead }
	<understand-prop-entry> <understand-prop-tail> | ==> { -, Understand::list_ui(RP[1], RP[2]) }
	<understand-prop-entry>                          ==> { pass 1 }

<understand-prop-tail> ::=
	, _and/or <understand-prop-list> |               ==> { pass 1 }
	_,/and/or <understand-prop-list>                 ==> { pass 1 }

<understand-prop-entry> ::=
	<property-name> property |                       ==> { -, Understand::property_item(RP[1]) }
	... property                                     ==> @<Issue PM_UnknownUnderstandProperty problem@>

@<Issue PM_OldVerbUsage problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OldVerbUsage),
		"this is an outdated form of words",
		"and Inform now prefers 'Understand the command ...' rather than 'Understand "
		"the verb ...'. (Since this change was made in beta-testing, quite a few old "
		"source texts still use the old form: the authors of Inform apologise for "
		"any nuisance incurred.)");
	==> { NO_UNDERSTAND_FORM, - };

@<Issue PM_UnknownUnderstandProperty problem@> =
	if (!preform_lookahead_mode)
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnknownUnderstandProperty),
		"I don't understand what property that refers to",
		"but it doesn't seem to be a property I know. An example of "
		"correct usage is 'understand the transparent property as "
		"describing a container.'");

@h Object phrases I: Understand explicit grammar.
We use three different Preform grammars to parse the object phrase depending on
the form of the sentence, and this is the commonest, shared by the
|GRAMMAR_UNDERSTAND_FORM| and |NOTHING_UNDERSTAND_FORM|. It handles sentences like:

>> Understand "take [something]" as taking.

It's not widely known, but the object phrase here can be a list:

>> Understand "broken" as the pot, the shovel or the contract.

The nonterminal <understand-sentence-op> returns |TRUE| or |FALSE| in its
integer return value according to whether a when condition is supplied, or not.
Its pointer return value is once again a linked list of objects, but this time
they are //understanding_reference// objects:

=
typedef struct understanding_reference {
	struct wording reference_text;
	int cg_result;
	int mword;
	int mistaken;
	int pluralised_reference;
	int reversed_reference;
	action_name *an_reference;
	parse_node *spec_reference;
	struct understanding_reference *next;
} understanding_reference;

understanding_reference *Understand::list_ur(understanding_reference *ur1,
	understanding_reference *ur2) {
	if (ur1 == NULL) return ur2;
	if (ur2 == NULL) return ur1;
	ur1->next = ur2;
	return ur1;
}

@ Unlike the case above, though, we will build these more complicated objects
in a multi-stage way. There is always one being built; when we're done, we
call //Understand::preserve_ur// to obtain a permanent record of it.

=
understanding_reference ur_being_parsed;

void Understand::initialise_ur_being_parsed(wording W) {
	ur_being_parsed.reference_text = W;
	ur_being_parsed.mword = -1;
	ur_being_parsed.mistaken = FALSE;
	ur_being_parsed.pluralised_reference = FALSE;
	ur_being_parsed.reversed_reference = FALSE;
	ur_being_parsed.an_reference = NULL;
	ur_being_parsed.spec_reference = NULL;
	ur_being_parsed.next = NULL;
	ur_being_parsed.cg_result = CG_IS_OBJECT;
}

understanding_reference *Understand::preserve_ur(void) {
	understanding_reference *ur = CREATE(understanding_reference);
	*ur = ur_being_parsed;
	return ur;
}

@ Now we turn to the object phrase. 

=
<understand-text-op> ::=
	<understand-text-op-uncond> when/while ... |        ==> { TRUE, RP[1] }
	<understand-text-op-uncond>                         ==> { FALSE, RP[1] }

<understand-text-op-uncond> ::=
	... |                                               ==> { lookahead }
	<understand-text-entry> <understand-text-op-tail> | ==> { -, Understand::list_ur(RP[1], RP[2]) }
	<understand-text-entry>                             ==> { pass 1 }

<understand-text-op-tail> ::=
	, _and/or <understand-text-op-uncond> |             ==> { pass 1 }
	_,/and/or <understand-text-op-uncond>               ==> { pass 1 }

@ The following grammar is applied to each item in the list in turn, and
looks odd but is actually quite simple: if it matches against one of the
possible notations, the temporary |ur_being_parsed| object is annotated;
if this succeeds without problem messages, that temporary object is
converted into a permanent //understanding_reference//.

<understand-as-this> and <understand-ref> has no pointer result, and their
integer result is 0 if no problems were thrown, or -1 if they were.

=
<understand-text-entry> ::=
	<understand-as-this>                        ==> @<Preserve the results@>

<understand-as-this> ::=
	... |                                       ==> @<Begin parsing an understand reference@>
	a mistake |                                 ==> { 0, - }; @<Mistake@>
	a mistake ( <quoted-text> ) |               ==> { 0, - }; @<Mistake with text@>
	a mistake ... |                             ==> @<Issue PM_TextlessMistake problem@>
	the plural of <understand-ref> |            ==> { pass 1 }; @<Pluralise@>
	plural of <understand-ref> |                ==> { pass 1 }; @<Pluralise@>
	<quoted-text> |                             ==> { 0, - }; @<Make into a token@>
	<understand-ref> ( with nouns reversed ) |  ==> { pass 1 }; @<Reverse@>
	<understand-ref>                            ==> { pass 1 }

<understand-ref> ::=
	<action-name> |                             ==> { 0, - }; @<Add action reference@>
	<s-descriptive-type-expression> |           ==> { 0, - }; @<Add specification reference@>
	<s-variable> |                              ==> @<Issue PM_UnderstandVariable problem@>
	...                                         ==> @<Issue PM_UnderstandVague problem@>

@<Begin parsing an understand reference@> =
	Understand::initialise_ur_being_parsed(W);
	return FALSE; /* and thus continue with the nonterminal */

@<Mistake@> =
	ur_being_parsed.cg_result = CG_IS_COMMAND; ur_being_parsed.mistaken = TRUE;

@<Mistake with text@> =
	ur_being_parsed.cg_result = CG_IS_COMMAND; ur_being_parsed.mistaken = TRUE;
	ur_being_parsed.mword = R[1];

@<Pluralise@> =
	ur_being_parsed.pluralised_reference = TRUE;

@<Make into a token@> =
	ur_being_parsed.cg_result = CG_IS_TOKEN;

@<Reverse@> =
	ur_being_parsed.reversed_reference = TRUE;

@<Add action reference@> =
	ur_being_parsed.an_reference = RP[1];

@<Add specification reference@> =
	ur_being_parsed.spec_reference = RP[1];

@<Preserve the results@> =
	if (R[1] == -1) { /* i.e., if a problem was thrown */
		==> { -, NULL };
	} else {
		==> { -, Understand::preserve_ur() };
	}

@<Issue PM_TextlessMistake problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TextlessMistake),
		"when 'understand' results in a mistake it can only be followed by a textual "
		"message in brackets",
		"so for instance 'understand \"take\" as a mistake (\"In this sort of game, "
		"a noun is required there.\").'");
	==> { -1, - };

@<Issue PM_UnderstandVariable problem@> =
	LOG("Offending pseudo-meaning is: %W\n", W);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandVariable),
		"this meaning is a value that varies",
		"whereas I need something fixed. (The most common case of this is saying "
		"that something should be understood as 'the player', which is actually a "
		"variable, because the perspective of play can change. Writing 'yourself' "
		"instead will usually do.)");
	==> { -1, - };

@<Issue PM_UnderstandVague problem@> =
	LOG("Offending pseudo-meaning is: %W\n", W);
	Understand::issue_PM_UnderstandVague();
	==> { -1, - };

@ =
void Understand::issue_PM_UnderstandVague(void) {
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandVague),
		"'understand ... as ...' should be followed by a meaning",
		"which might be an action (e.g., 'understand \"take [something]\" as taking'), "
		"a thing ('understand \"stove\" as the oven') or more generally a value "
		"('understand \"huitante\" as 80'), or a named token for use in further "
		"grammar ('understand \"near [something]\" as \"[location phrase]\"'). "
		"Also, the meaning needs to be precise, so 'understand \"x\" as a number' "
		"is not allowed - it does not say which number.");
}

@h Object phrases II: Understand the command.
The second form of the sentence has an object phrase like so:

>> Understand the command "snatch" as "take".

Here the grammar is very simple, and the object can't be a list.

=
<understand-command-op> ::=
	... when/while ... |  ==> @<Issue PM_UnderstandCommandWhen problem@>
	something new |       ==> { 0, - }
	<quoted-text> |       ==> { Wordings::first_wn(W), - }
	...                   ==> @<Issue PM_NotOldCommand problem@>

@<Issue PM_UnderstandCommandWhen problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandCommandWhen),
		"'understand the command ... as ...' is not allowed to have a '... when ...' "
		"clause",
		"for the moment at any rate.");
	==> { -1, - };

@<Issue PM_NotOldCommand problem@> =
	@<Actually issue PM_NotOldCommand problem@>;
	==> { -1, - };

@<Actually issue PM_NotOldCommand problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NotOldCommand),
		"'understand the command ... as ...' should end with a command "
		"already defined",
		"as in 'understand the command \"steal\" as \"take\"'. (This problem is "
		"sometimes seen when the wrong sort of Understand... sentence has been used: "
		"'Understand the command \"steal\" as \"take\".' tells me to treat the "
		"command STEAL as a synonym for TAKE when reading the player's commands, "
		"whereas 'Understand \"steal [something]\" as taking.' tells me that here is "
		"a specific grammar for what can be said using the STEAL command.)");

@h Object phrases III: Understand the property.
The third and final form of the sentence has an object phrase like so:

>> Understand the unbroken property as describing the pot.

Once again, the object can't be a list.

=
<understand-prop-op> ::=
	<understand-prop-op-uncond> when/while ... | ==> { -R[1], RP[1] }
	<understand-prop-op-uncond>                  ==> { R[1], RP[1] }

<understand-prop-op-uncond> ::=
	referring to <understand-prop-ref> | ==> { 1, RP[1] }
	describing <understand-prop-ref> |   ==> { 2, RP[1] }
	...                                  ==> @<Issue PM_BadUnderstandProperty problem@>

<understand-prop-ref> ::=
	<k-kind> |                           ==> { -, KindSubjects::from_kind(RP[1]) };
	<instance> |                         ==> { -, Instances::as_subject(RP[1]) }
	...                                  ==> @<Issue PM_BadUnderstandPropertyAs problem@>

@<Issue PM_BadUnderstandProperty problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadUnderstandProperty),
		"'understand the ... property as ...' is only allowed if followed by 'describing "
		"...' or 'referring to ...'",
		"so for instance 'understand the transparent property as describing a container.'");
	==> { 0, - };

@<Issue PM_BadUnderstandPropertyAs problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadUnderstandPropertyAs),
		"I don't understand what single thing or kind of thing that refers to",
		"but it does need to be an object (or kind of object).");
	==> { -, NULL };

@h Handling object phrase depending on subject phrase.
So now we use the above Preform: on the sentence "Understand SP as OP", we
parse the subject phrase SP with <understand-sentence-sp>, and depending
on which of the forms it has, we then use one of <understand-command-op>,
<understand-prop-op> or <understand-text-op> on the OP.

=
void Understand::understand_sentence(wording W, wording ASW) {
	LOGIF(GRAMMAR, "Parsing understand <%W> as <%W>\n", W, ASW);
	if (problem_count > base_problem_count) return;
	<understand-sentence-sp>(W);
	if (problem_count > base_problem_count) return;
	understanding_item *ui_list = <<rp>>;
	int form = <<r>>;
	switch (form) {
		case COMMAND_UNDERSTAND_FORM: @<Process Understand command@>; break;
		case PROPERTY_UNDERSTAND_FORM: @<Process Understand property@>; break;
		case GRAMMAR_UNDERSTAND_FORM: /* fall through to... */
		case NOTHING_UNDERSTAND_FORM: @<Process Understand grammar@>; break;
	}
}

@ In each case we run through the lists of terms in SP and OP, where lists
are permitted, and for every combination we call exactly one of the four
functions //Understand::command_block//, //Understand::property_block//,
//Understand::nothing_block//, or //Understand::text_block//.

@<Process Understand command@> =
	<understand-command-op>(ASW);
	if (problem_count > base_problem_count) return;
	wording W = (<<r>> != 0) ? (Wordings::one_word(<<r>>)) : EMPTY_WORDING;
	for (understanding_item *ui = ui_list; ui; ui = ui->next) {
		if (problem_count > base_problem_count) break;
		Understand::command_block(ui->quoted_text, W);
	}

@<Process Understand property@> =
	<understand-prop-op>(ASW);
	if (problem_count > base_problem_count) return;
	wording UW = EMPTY_WORDING;
	inference_subject *subj = <<rp>>;
	if (<<r>> < 0) UW = GET_RW(<understand-prop-op>, 1);
	int level = <<r>>; if (level < 0) level = -level;
	for (understanding_item *ui = ui_list; ui; ui = ui->next) {
		if (problem_count > base_problem_count) break;
		Understand::property_block(ui->quoted_property, level, subj, UW);
	}

@<Process Understand grammar@> =
	<understand-text-op>(ASW);
	if (problem_count > base_problem_count) return;
	understanding_reference *ur_list = <<rp>>;
	wording UW = EMPTY_WORDING;
	if (<<r>> == TRUE) UW = GET_RW(<understand-text-op>, 1);
	if (form == NOTHING_UNDERSTAND_FORM) {
		for (understanding_reference *ur = ur_list; ur; ur = ur->next) {
			if (problem_count > base_problem_count) break;
			Understand::nothing_block(ur, UW);
		}
	} else {
		for (understanding_item *ui = ui_list; ui; ui = ui->next) {
			for (understanding_reference *ur = ur_list; ur; ur = ur->next) {
				if (problem_count > base_problem_count) break;
				Understand::text_block(ui->quoted_text, ur, UW);
			}
		}
	}

@h Command blocks.
We now define the four "block" functions in turn, beginning with command blocks.
Our aim here is only to perform some semantic checks to see if the instruction
makes sense (as well as being syntactically valid), and then delegate the work
to another section: here //CommandGrammars::remove_command// or //CommandGrammars::add_command//.

=
void Understand::command_block(wording W, wording ASW) {
	W = Wordings::last_word(W);
	Word::dequote(Wordings::first_wn(W));
	wchar_t *p = Lexer::word_text(Wordings::first_wn(W));
	for (int i=0; p[i]; i++)
		if (p[i] == ' ') {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_SpacyCommand),
				"'understand the command ... as ...' is only allowed when the old "
				"command is a single word",
				"so for instance 'understand the command \"capture\" as \"get\"' is "
				"okay, but 'understand the command \"capture the flag\" as \"get\"' "
				"is not.");
			break;
		}

	if (Wordings::empty(ASW)) {
		@<Revoke the command@>;
	} else {
		@<Throw a problem if the command to be defined already means something@>;
		@<Define the command@>;
	}
}

@ After some debate, we decided that it ought to be legal to declare "Understand the
command "wibble" as something new" even in cases where no "wibble" command existed
already: extensions might want this to assure that they have exclusive use of a
command, for instance. So the following does nothing if |cg| comes back |NULL|, but
does not issue a problem message in that case either.

@<Revoke the command@> =
	command_grammar *cg = CommandGrammars::find_command(W);
	if (cg) CommandGrammars::remove_command(cg, W);

@ But you can only define a command which does exist already if that command has
no meanings at present -- as can happen if it has had every meaning stripped from
it, one at a time, by previous Understand sentences.

@<Throw a problem if the command to be defined already means something@> =
	command_grammar *cg = CommandGrammars::find_command(W);
	if (cg)	{
		if (CommandGrammars::is_empty(cg)) {
			DESTROY(cg, command_grammar);
		} else {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NotNewCommand),
				"'understand the command ... as ...' is only allowed when the new "
				"command has no meaning already",
				"so for instance 'understand \"drop\" as \"throw\"' is not allowed "
				"because \"drop\" already has a meaning.");
			return;
		}
	}

@<Define the command@> =
	@<Throw a problem if the command to be defined already means something@>;
	Word::dequote(Wordings::first_wn(ASW));
	command_grammar *as_gv = CommandGrammars::find_command(ASW);
	if (as_gv == NULL) {
		@<Actually issue PM_NotOldCommand problem@>;
	} else {
		CommandGrammars::add_command(as_gv, W);
	}

@h Property blocks.
Again, some semantic checks, but the real work is delegated to //Visibility::seek//.

=
void Understand::property_block(property *pr, int level, inference_subject *subj, wording WHENW) {
	kind *K = KindSubjects::to_kind(subj);
	if (K == NULL) {
		instance *I = InstanceSubjects::to_instance(subj);
		K = Instances::to_kind(I);
	}
	if ((K) && (Kinds::Behaviour::is_subkind_of_object(K) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UnderstandPropertyAsNonObjectKind),
			"a property can be understood as referring to a single object (or a kind of "
			"object) but not to something of any other kind",
			"and this refers to something which is not an object.");
		return;
	}
	if ((Properties::is_either_or(pr) == FALSE) &&
		(Str::len(Kinds::Behaviour::get_recognition_only_GPR(ValueProperties::kind(pr))) == 0) &&
		((Kinds::Behaviour::is_object(ValueProperties::kind(pr))) ||
			(Kinds::Behaviour::request_I6_GPR(ValueProperties::kind(pr)) == FALSE))) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_BadReferringProperty),
			"that property is of a kind which I can't recognise in "
			"typed commands",
			"so that it cannot be understand as describing or referring to "
			"something. I can understand either/or properties, properties "
			"with a limited list of named possible values, numbers, times "
			"of day, or units; but certain built-into-Inform kinds of value "
			"(like snippet or rulebook, for instance) I can't use.");
	}
	if (Visibility::seek(pr, subj, level, WHENW) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UnknownUnpermittedProperty),
			"that property is not allowed for the thing or kind in question",
			"just as (ordinarily) 'understand the open property as describing a "
			"device' would not be allowed because it makes no sense to call a "
			"device 'open'.");
	}
}

@h Nothing blocks.
Again, some semantic checks, but the real work is delegated to
//Actions::remove_all_command_grammar//.

=
void Understand::nothing_block(understanding_reference *ur, wording WHENW) {
	if ((ur == NULL) || (ur->cg_result != CG_IS_OBJECT) || (ur->an_reference == NULL)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UnderstandNothingNonAction),
			"'Understand nothing as ...' must be followed by an action",
			"such as 'Understand nothing as taking.'");
	} else if (Wordings::nonempty(WHENW)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UnderstandNothingWhen),
			"'Understand nothing as ...' must be unconditional",
			"so your 'when' or 'while' condition will have to go.");
	} else {
		action_name *an = ur->an_reference;
		LOGIF(GRAMMAR_CONSTRUCTION, "Understand nothing as: $l\n", an);
		Actions::remove_all_command_grammar(an);
	}
}

@h The other way quoted grammar arises.
This section is primarily about Understand sentences, but Inform also receives
grammar in some other contexts, such as in a table where one column contains
conversation topics to be matched, or in the condition:

>> if the player's command matches "room [number]", ...

The quoted text here becomes a constant of the kind |K_understanding|, and
when it needs to be compiled, the following function is called.[1] As can be
seen, it funnels directly into //Understand::text_block//.

[1] The term "consultation" goes back to the origins of this feature in the
CONSULT command, which in turn goes right back to a game called "Curses" (1993),
in which players consulted a biographical dictionary of the Meldrew family.

=
void Understand::consultation(wording W, int table_entry) {
	base_problem_count = problem_count;
	if (table_entry) {
		LOOP_THROUGH_WORDING(k, W) {
			if (<quoted-text>(Wordings::one_word(k))) {
				Understand::text_block(Wordings::one_word(k), NULL, EMPTY_WORDING);
			}
		}
	} else {
		Understand::text_block(W, NULL, EMPTY_WORDING);
	}
}

@h Text blocks.
And finally, here we perform some checks and then delegate to
//CommandGrammarSource::in//.

=
void Understand::text_block(wording W, understanding_reference *ur, wording WHENW) {
	if (problem_count > base_problem_count) return;
	if (<quoted-text>(W) == FALSE) {
		if (TEST_COMPILATION_MODE(SPECIFICATIONS_CMODE))
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
				"the topic here should be in the form of a textual description",
				"as in 'asking about \"[something]\"'.");
		else
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NontextualUnderstand),
				"'understand' should be followed by a textual description",
				"as in 'understand \"take [something]\" as taking the noun'.");
		return;
	}
	if (Word::well_formed_text_routine(Lexer::word_text(Wordings::first_wn(W))) == FALSE) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandMismatch),
			"'understand' should be followed by text in which brackets '[' and ']' match",
			"so for instance 'understand \"take [something]\" as taking the noun' "
			"is fine, but 'understand \"take]\" as taking' is not.");
		return;
	}
	CommandGrammarSource::in(W, ur, WHENW);
}
