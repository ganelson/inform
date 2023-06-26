[Understand::] Understand Sentences.

Command parser grammar is laid out in special Understand... sentences.

@h Traversing.
When the "parser" feature is active, any sentence in the form "Understand...
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
	int mistaken;
	struct wording mistake_text;
	int pluralised_reference;
	int reversed_reference;
	struct action_name *an_reference;
	struct parse_node *spec_reference;
	struct property *property_reference;
	struct wording token_text;
	struct wording when_text;
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

void Understand::initialise_ur(understanding_reference *ur, wording W) {
	ur->reference_text = W;
	ur->cg_result = CG_IS_SUBJECT;
	ur->mistaken = FALSE;
	ur->mistake_text = EMPTY_WORDING;
	ur->pluralised_reference = FALSE;
	ur->reversed_reference = FALSE;
	ur->an_reference = NULL;
	ur->spec_reference = NULL;
	ur->property_reference = NULL;
	ur->token_text = EMPTY_WORDING;
	ur->when_text = EMPTY_WORDING;
	ur->next = NULL;
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
	<action-pattern> |                          ==> @<Issue PM_UnderstandActionPattern problem@>
	<s-descriptive-type-expression> |           ==> { 0, - }; @<Add specification reference@>
	<s-variable> |                              ==> @<Issue PM_UnderstandVariable problem@>
	...                                         ==> @<Issue PM_UnderstandVague problem@>

@<Begin parsing an understand reference@> =
	Understand::initialise_ur(&ur_being_parsed, W);
	return FALSE; /* and thus continue with the nonterminal */

@<Mistake@> =
	ur_being_parsed.cg_result = CG_IS_COMMAND; ur_being_parsed.mistaken = TRUE;
	ur_being_parsed.mistake_text = EMPTY_WORDING;

@<Mistake with text@> =
	ur_being_parsed.cg_result = CG_IS_COMMAND; ur_being_parsed.mistaken = TRUE;
	ur_being_parsed.mistake_text = Wordings::one_word(R[1]);

@<Pluralise@> =
	ur_being_parsed.pluralised_reference = TRUE;

@<Make into a token@> =
	ur_being_parsed.cg_result = CG_IS_TOKEN;
	ur_being_parsed.token_text = CGTokens::break(
		Lexer::word_text(Wordings::first_wn(ur_being_parsed.reference_text)), TRUE);

@<Reverse@> =
	ur_being_parsed.reversed_reference = TRUE;

@<Add action reference@> =
	ur_being_parsed.cg_result = CG_IS_COMMAND;
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

@<Issue PM_UnderstandActionPattern problem@> =
	LOG("Offending pseudo-meaning is: %W\n", W);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandActionPattern),
		"this meaning looks like a form of action",
		"but needs to be written more simply, just as the action itself and without "
		"any details about what is acted on. For example, 'Understand ... as examining' "
		"is fine, but 'Understand ... as examining a door' is not. (What will be "
		"examined depends on what is in the actual command this 'Understand' "
		"instruction will try to work on - we cannot know yet whether it will be "
		"a door.)");
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
	referring to <understand-prop-ref> | ==> { REFERRING_TO_VISIBILITY_LEVEL, RP[1] }
	describing <understand-prop-ref> |   ==> { DESCRIBING_VISIBILITY_LEVEL, RP[1] }
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
				ur->when_text = UW;
				Understand::text_block(ui->quoted_text, ur);
			}
		}
	}

@h Command blocks.
We now define the four "block" functions in turn, beginning with command blocks.
Our aim here is only to perform some semantic checks to see if the instruction
makes sense (as well as being syntactically valid), and then delegate the work
to another section: here //CommandGrammars::remove_command// or //CommandGrammars::add_alias//.

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
	command_grammar *cg = CommandGrammars::for_command_verb(W);
	if (cg) CommandGrammars::remove_command(cg, W);

@ But you can only define a command which does exist already if that command has
no meanings at present -- as can happen if it has had every meaning stripped from
it, one at a time, by previous Understand sentences.

@<Throw a problem if the command to be defined already means something@> =
	command_grammar *cg = CommandGrammars::for_command_verb(W);
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
	command_grammar *as_gv = CommandGrammars::for_command_verb(ASW);
	if (as_gv == NULL) {
		@<Actually issue PM_NotOldCommand problem@>;
	} else {
		CommandGrammars::add_alias(as_gv, W);
	}

@h Property blocks.
Again, some semantic checks, but the real work is delegated to //Visibility::set//.

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
	kind *PK = ValueProperties::kind(pr);
	if ((Properties::is_either_or(pr) == FALSE) &&
		(RTKindConstructors::recognition_only_GPR_provided_by_kit(PK) == FALSE) &&
		((Kinds::Behaviour::is_object(PK)) ||
			(Kinds::Behaviour::is_understandable(PK) == FALSE))) {
		if (Kinds::Behaviour::is_object(PK))
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_ThingReferringProperty),
				"the value of that property is itself a kind of object",
				"so that it cannot be understand as describing or referring to "
				"something. I can understand either/or properties, properties "
				"with a limited list of named possible values, numbers, times "
				"of day, or units.");
		else
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
	if (Visibility::set(pr, subj, level, WHENW) == FALSE) {
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
	if ((ur == NULL) || (ur->an_reference == NULL)) {
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
when it needs to be compiled, the following function is called. As can be
seen, it funnels directly into //Understand::text_block//.

When table cells contain these topics, they are sometimes in the form of a
list: say, "rockets" or "spaceships". We do not police the connectives here,
we simply make any double-quoted text in |W| generate grammar.

=
command_grammar *Understand::consultation(wording W) {
	base_problem_count = problem_count;
	CommandGrammars::prepare_consultation_cg();
	LOOP_THROUGH_WORDING(k, W) {
		wording TW = Wordings::one_word(k);
		if (<quoted-text>(TW)) {
			understanding_reference ur;
			Understand::initialise_ur(&ur, TW);
			ur.cg_result = CG_IS_CONSULT;
			Understand::text_block(TW, &ur);
		}
	}
	return CommandGrammars::get_consultation_cg();
}

@h Text blocks.
And finally, here we perform a lengthy shopping list of checks for validity, but
then in all cases we create a single new CG line with //CGLines::new//
and add it to a suitably chosen CG with //CommandGrammars::add_line//.

=
void Understand::text_block(wording W, understanding_reference *ur) {
	if (problem_count > base_problem_count) return;
	@<The wording W must be a piece of quoted text using square brackets properly@>;
	@<If token text is given, it must be well-formed@>;
	@<Consult grammar cannot have conditions attached@>;

	@<Reference cannot be to an object with a qualified description@>;
	@<Reference cannot be imprecise@>;
	@<Reference cannot be to a value of a kind not supporting parsing at run-time@>;
	
	@<Read a reference to a single positive adjective as a noun@>;

	@<Only objects can be understood in the plural@>;

	cg_token *tokens = NULL; cg_line *cgl = NULL; command_grammar *cg = NULL;
	@<Tokenise the quoted text W into the raw tokens for a CG line@>;
	@<Make the new CG line@>;
	@<Decide which command grammar the new line should go to@>;
	if (cg) CommandGrammars::add_line(cg, cgl);
}

@<The wording W must be a piece of quoted text using square brackets properly@> =
	if (<quoted-text>(W) == FALSE) {
		if (ur->cg_result == CG_IS_CONSULT)
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

@<If token text is given, it must be well-formed@> =
	if (Wordings::nonempty(ur->token_text)) {
		int cc=0;
		LOOP_THROUGH_WORDING(i, ur->token_text)
			if (compare_word(i, COMMA_V)) cc++;
		Word::dequote(Wordings::first_wn(ur->token_text));
		if (*(Lexer::word_text(Wordings::first_wn(ur->token_text))) != 0) @<Token name invalid@>;
		Word::dequote(Wordings::last_wn(ur->token_text));
		if (*(Lexer::word_text(Wordings::last_wn(ur->token_text))) != 0) @<Token name invalid@>;
		if (cc != 2) @<Token name invalid@>;
	}

@<Token name invalid@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnderstandAsCompoundText),
		"if 'understand ... as ...' gives the meaning as text then it must describe "
		"a single new token",
		"so that 'Understand \"group four/five/six\" as \"[department]\"' is legal "
		"(defining a new token \"[department]\", or adding to its definition if it "
		"already existed) but 'Understand \"take [thing]\" as \"drop [thing]\"' is "
		"not allowed, and would not make sense, because \"drop [thing]\" is a "
		"combination of two existing tokens - not a single new one.");
	return;

@<Consult grammar cannot have conditions attached@> =
	if ((Wordings::nonempty(ur->when_text)) && (ur->cg_result == CG_IS_CONSULT)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(BelievedImpossible), /* at present, I7 syntax prevents this anyway */
			"'when' cannot be used with this kind of 'Understand'",
			"for the time being at least.");
		return;
	}

@<Reference cannot be to an object with a qualified description@> =
	parse_node *spec = ur->spec_reference;
	if (Specifications::object_exactly_described_if_any(spec)) {
		if (Descriptions::is_qualified(spec)) {
			LOG("Offending description: $T", spec);
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_UnderstandAsQualified),
				"I cannot understand text as meaning an object qualified by relative "
				"clauses or properties",
				"only a specific thing, a specific value or a kind. (But the same effect "
				"can usually be achieved with a 'when' clause. For instance, although "
				"'Understand \"bad luck\" as the broken mirror' is not allowed, "
				"'Understand \"bad luck\" as the mirror when the mirror is broken' "
				"produces the desired effect.)");
			return;
		}
	}

@<Reference cannot be imprecise@> =
	parse_node *spec = ur->spec_reference;
	if ((Specifications::is_kind_like(spec)) &&
		(Kinds::Behaviour::is_object(Specifications::to_kind(spec)) == FALSE)) @<Imprecise@>;
	if (Specifications::is_phrasal(spec)) @<Imprecise@>;
	if (Rvalues::is_nothing_object_constant(spec)) @<Imprecise@>;

@<Imprecise@> =
	Understand::issue_PM_UnderstandVague();
	return;

@<Reference cannot be to a value of a kind not supporting parsing at run-time@> =
	parse_node *spec = ur->spec_reference;
	if (Rvalues::is_rvalue(spec)) {
		kind *K = Node::get_kind_of_value(spec);
		if (Kinds::Behaviour::is_subkind_of_object(K) == FALSE) {
			ur->cg_result = CG_IS_VALUE;
			if (Kinds::get_construct(K) == CON_activity) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_UnderstandAsActivity),
					"this 'understand ... as ...' gives text meaning an activity",
					"rather than an action. Since activities happen when Inform decides "
					"they need to happen, not in response to typed commands, this doesn't "
					"make sense.");
				return;
			}
			if (Kinds::Behaviour::is_understandable(K) == FALSE) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(PM_UnderstandAsBadValue),
					"'understand ... as ...' gives text meaning a value whose kind "
					"is not allowed",
					"and should be a value such as 100.");
				return;
			}
		}
	}

@<Read a reference to a single positive adjective as a noun@> =
	parse_node *spec = ur->spec_reference;		
	if (Specifications::is_description(spec)) {
		if ((Descriptions::to_instance(spec) == NULL) &&
			(Kinds::Behaviour::is_subkind_of_object(Specifications::to_kind(spec)) == FALSE)
			&& (Descriptions::number_of_adjectives_applied_to(spec) == 1)
			&& (AdjectivalPredicates::parity(
				Propositions::first_unary_predicate(
					Specifications::to_proposition(spec), NULL)))) {
			adjective *aph =
				AdjectivalPredicates::to_adjective(
					Propositions::first_unary_predicate(
						Specifications::to_proposition(spec), NULL));
			instance *q = AdjectiveAmbiguity::has_enumerative_meaning(aph);
			if (q) {
				ur->cg_result = CG_IS_VALUE;
				ur->spec_reference = Rvalues::from_instance(q);
			} else {
				property *prn = AdjectiveAmbiguity::has_either_or_property_meaning(aph, NULL);
				if (prn) {
					ur->cg_result = CG_IS_PROPERTY_NAME;
					ur->property_reference = prn;
					ur->spec_reference = NULL;
				}
			}
		}
	}

@<Only objects can be understood in the plural@> =
	if ((ur->pluralised_reference) && (ur->cg_result != CG_IS_SUBJECT)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UnderstandPluralValue),
			"'understand' as a plural can only apply to things, rooms or kinds "
			"of things or rooms",
			"so 'Understand \"paperwork\" as the plural of a document.' is fine "
			"(assuming a document is a kind of thing), but 'Understand \"dozens\" "
			"as the plural of 12' is not.");
		return;
	}

@<Tokenise the quoted text W into the raw tokens for a CG line@> =
	int np = problem_count;
	tokens = CGTokens::tokenise(W);
	if (problem_count > np) return;

@<Make the new CG line@> =
	cgl = CGLines::new(W, ur->an_reference, tokens,
		ur->reversed_reference, ur->pluralised_reference);
	if (ur->mistaken) CGLines::set_mistake(cgl, ur->mistake_text);
	if (Wordings::nonempty(ur->when_text))
		CGLines::set_understand_when(cgl, ur->when_text);
	if (Descriptions::is_qualified(ur->spec_reference))
		CGLines::set_understand_prop(cgl,
			Propositions::copy(Descriptions::to_proposition(ur->spec_reference)));
	LOGIF(GRAMMAR_CONSTRUCTION, "Line: $g\n", cgl);

@<Decide which command grammar the new line should go to@> =
	switch(ur->cg_result) {
		case CG_IS_TOKEN:
			LOGIF(GRAMMAR_CONSTRUCTION, "Add to command grammar of token %W: ", ur->token_text);
			cg = CommandGrammars::new_named_token(
				Wordings::trim_both_ends(Wordings::trim_both_ends(ur->token_text)));
			break;
		case CG_IS_COMMAND: {
			wording command_W = EMPTY_WORDING; /* implies the no verb verb */
			if (CGTokens::is_literal(tokens))
				command_W = Wordings::first_word(CGTokens::text(tokens));
			LOGIF(GRAMMAR_CONSTRUCTION, "Add to command grammar of command '%W': ", command_W);
			cg = CommandGrammars::for_command_verb_creating(command_W);
			break;
		}
		case CG_IS_SUBJECT: {
			inference_subject *cg_owner = NULL;
			parse_node *spec = ur->spec_reference;
			instance *target = Specifications::object_exactly_described_if_any(spec);
			if (target) {
				cg_owner = Instances::as_subject(target);
			} else if (Specifications::is_description(spec)) {
				kind *K = Specifications::to_kind(spec);
				if (K) cg_owner = KindSubjects::from_kind(K);
			}
			if (cg_owner == NULL) {
				StandardProblems::sentence_problem(Task::syntax_tree(),
					_p_(BelievedImpossible),
					"that's not something I can 'Understand ... as ...'",
					"and should normally be an action or a thing.");
			} else {
				LOGIF(GRAMMAR_CONSTRUCTION, "Add to command grammar of subject $j: ", cg_owner);
				cg = CommandGrammars::for_subject(cg_owner);
			}
			break;
		}
		case CG_IS_VALUE:
			LOGIF(GRAMMAR_CONSTRUCTION, "Add to command grammar of value $P: ",
				ur->spec_reference);
			CGLines::set_single_term(cgl, ur->spec_reference);
			cg = CommandGrammars::for_kind(Node::get_kind_of_value(ur->spec_reference));
			break;
		case CG_IS_PROPERTY_NAME:
			LOGIF(GRAMMAR_CONSTRUCTION, "Add to command grammar of property $Y: ",
				ur->property_reference);
			cg = CommandGrammars::for_prn(ur->property_reference);
			break;
		case CG_IS_CONSULT:
			LOGIF(GRAMMAR_CONSTRUCTION, "Add to a consultation grammar: ");
			cg = CommandGrammars::get_consultation_cg();
			break;
	}
	LOGIF(GRAMMAR_CONSTRUCTION, "$G\n", cg);
