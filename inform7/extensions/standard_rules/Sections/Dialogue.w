Dialogue.

Miscellaneous phrase and other declarations needed to support the dialogue
director.

@h Dialogue support.

=
Part Eight - Dialogue

Chapter 1 - Fallback Implementation (not for dialogue language element)

Section 1 - Interface to action machinery - unindexed

To abide by dialogue before action choices:
	do nothing.

To abide by dialogue instead action choices:
	do nothing.

To abide by dialogue after action choices:
	do nothing.

Chapter 1 - Full Implementation (for dialogue language element only)

Section 1 - Performance styles

There is a performance style called spoken normally.

Section 2 - Dialogue beats

A dialogue beat can be performed or unperformed. A dialogue beat is usually
unperformed.
A dialogue beat can be recurring or non-recurring. A dialogue beat is usually
non-recurring.
A dialogue beat can be spontaneous or unspontaneous. A dialogue beat is usually
unspontaneous.
A dialogue beat can be voluntary or involuntary. A dialogue beat is usually
voluntary.

The performed property is accessible to Inter as "performed".
The spontaneous property is accessible to Inter as "spontaneous".
The voluntary property is accessible to Inter as "voluntary".
The recurring property is accessible to Inter as "recurring".

Definition: A dialogue beat is available rather than unavailable if Inter routine
	"DirectorBeatAvailable" says so (it meets all its after or before, if and unless conditions).

Definition: A dialogue beat is relevant rather than irrelevant if Inter routine
	"DirectorBeatRelevant" says so (one of the topics it is about is currently live).

Definition: A dialogue beat is being performed if Inter routine
	"DirectorBeatBeingPerformed" says so (it is currently having its lines performed).

Topicality relates a dialogue beat (called B) to an object (called S) when about B matches S.

Performability relates a dialogue beat (called B) to an object (called S) when S can have B performed.

The verb to be about means the topicality relation.

The verb to be performable to means the performability relation.

To decide if about (B - dialogue beat) matches (S - object):
	(- (DirectorBeatAbout({B}, {S})) -).

To decide if (S - object) can have (B - dialogue beat) performed:
	(- (DirectorBeatAccessible({B}, {S})) -).

To decide what list of objects is the list of speakers required by (B - dialogue beat)
	(documented at ph_listofspeakers):
	(- DirectorBeatRequiredList({-new:list of objects}, {B}) -).

To decide what dialogue line is the opening line of (B - dialogue beat):
	(- DirectorBeatOpeningLine({B}) -).

To perform (B - a dialogue beat)
	(documented at ph_performbeat):
	(- DirectorPerformBeat({B}); -).

To decide which object is the first speaker of (B - dialogue beat)
	(documented at ph_firstspeaker):
	(- (DirectorBeatFirstSpeaker({B})) -).

To decide whether dialogue/dialog about (O - an object) intervenes
	(documented at ph_dialogueintervenes):
	(- DirectorIntervenes({O}, nothing) -).
To decide whether dialogue/dialog about (O - an object) led by (P - an object) intervenes
	(documented at ph_dialogueintervenesled):
	(- DirectorIntervenes({O}, {P}) -).

To showme the beat structure of (B - dialogue beat)
	(documented at ph_showmebeat):
	(- DirectorDisassemble({B}); -).

Section 3 - Dialogue lines

A dialogue line can be performed or unperformed. A dialogue line is usually
unperformed.
A dialogue line can be recurring or non-recurring. A dialogue line is usually
non-recurring.
A dialogue line can be elaborated or unelaborated. A dialogue line is usually
unelaborated.

To decide what text is the textual content of (L - dialogue line):
	(- DirectorLineContent({L}, {-new:text}) -).

To decide what object is the current dialogue line speaker:
	(- DirectorCurrentLineSpeaker() -).
To decide what object is the current dialogue line interlocutor:
	(- DirectorCurrentLineInterlocutor() -).

Definition: A dialogue line is available rather than unavailable if Inter routine
	"DirectorLineAvailable" says so (it meets all its if and unless conditions).

Definition: A dialogue line is narrated rather than unnarrated if Inter routine
	"DirectorLineNarrated" says so (it is a Narration line rather than what somebody is saying).

Definition: A dialogue line is non-verbal rather than verbal if Inter routine
	"DirectorLineNonverbal" says so (it is a non-verbal communication, like a gesture).

Section 4 - Dialogue choices

A dialogue choice can be performed or unperformed. A dialogue choice is usually
unperformed.
A dialogue choice can be recurring or non-recurring. A dialogue choice is usually
non-recurring.

Definition: A dialogue choice is flowing rather than offered if Inter routine
	"DirectorChoiceFlowing" says so (it is a flow-control point rather than an option).

Definition: A dialogue choice is story-ending if Inter routine
	"DirectorChoiceStoryEnding" says so (it is a flow marker to an end of the story).

To decide what text is the textual content of (C - dialogue choice):
	(- DirectorChoiceTextContent({C}, {-new:text}) -).

To decide what list of dialogue choices is the current choice list
	(documented at ph_dialoguechoices):
	(- DirectorCurrentChoiceList() -).

Section 5 - List of live conversational subjects

To make (T - an object) a live conversational subject
	(documented at ph_makelive):
	(- DirectorAddLiveSubjectList({T}); -).
To make (T - an object) a dead conversational subject
	(documented at ph_makedead):
	(- DirectorRemoveLiveSubjectList({T}); -).
To clear conversational subjects
	(documented at ph_clearsubjects):
	(- DirectorEmptyLiveSubjectList(); -).
To decide what list of objects is the/-- live conversational subject list
	(documented at ph_getlivelist):
	(- DirectorLiveSubjectList({-new:list of objects}) -).
To alter the/-- live conversational subject list to (L - list of objects)
	(documented at ph_setlivelist):
	(- DirectorAlterLiveSubjectList({-by-reference:L}); -).

Section 7 - The dialogue director

To make the dialogue/dialog director active
	(documented at ph_directoractive):
	(- DirectorActivate(); -).

To make the dialogue/dialog director passive/inactive
	(documented at ph_directorpassive):
	(- DirectorDeactivate(); -).

To decide whether dialogue has been performed this turn
	(documented at ph_dialoguethisturn):
	(- (line_performance_count > 0) -).

The dialogue direction rule is listed in the turn sequence rulebook.
The dialogue direction rule is defined by Inter as "DIALOGUE_DIRECTION_R".

The performing opening dialogue beat rule is listed in the startup rulebook.
The performing opening dialogue beat rule is defined by Inter as "PERFORM_OPENING_BEAT_R".

Section 8 - Interface to action machinery - unindexed

To decide what performance style is the current dialogue line style:
	(- DirectorCurrentLineStyle() -).

To abide by dialogue before action choices:
	(- if (DirectorBeforeAction()) rtrue; -).

To abide by dialogue instead action choices:
	(- if (DirectorInsteadAction()) rtrue; -).

To abide by dialogue after action choices:
	(- if (DirectorAfterAction()) rtrue; -).

Section 9 - Dialogue activities

Offering something (documented at act_offering) is an activity on lists of dialogue choices.
The offering activity is accessible to Inter as "OFFERING_A_DIALOGUE_CHOICE".

Last for offering a list of dialogue choices (called L)
	(this is the default offering dialogue choices rule):
	let N be 0;
	repeat with C running through L:
		increase N by 1;
		say "([N]) [textual content of C][line break]";
	say conditional paragraph break;
	let M be a number chosen by the player from 1 to N;
	set the dialogue selection value to M;
	say "[bold type][textual content of entry M of L][roman type][paragraph break]".

To set the dialogue selection value to (M - a number):
	(- dialogue_selection_value = {M}; -).

Performing something (documented at act_performing) is an activity on dialogue lines.
The performing activity is accessible to Inter as "PERFORMING_DIALOGUE".

The performing activity has an object called the speaker.

The performing activity has an object called the interlocutor.

The performing activity has a performance style called the style.

Before performing a dialogue line:
	now the speaker is the current dialogue line speaker;
	now the interlocutor is the current dialogue line interlocutor;
	now the style is the current dialogue line style.

For performing a dialogue line (called L)
	(this is the default dialogue performance rule):
	if L is narrated or L is elaborated or L is non-verbal:
		say "[textual content of L][line break]";
	otherwise:
		say "[The speaker]";
		if the interlocutor is something:
			say " (to [the interlocutor])";
		say ": '[textual content of L]'[line break]".

@ The dialogue system offers an action "talking about", but not "talking to X about":
this is a model of conversation which is aimed at simulating multi-person encounters,
where lines are spoken more into the room than at any one person.

=
Section 10 - Dialogue-related actions

Talking about is an action applying to one object.

The talking about action has a list of dialogue beats called the leading beats.

The talking about action has a list of dialogue beats called the other beats.

Before an actor talking about an object (called T):
	repeat with B running through available dialogue beats about T:
		if B is performable to the actor:
			if the first speaker of B is the actor:
				add B to the leading beats;
			otherwise:
				add B to the other beats;

Carry out an actor talking about an object (called T)
	(this is the first-declared beat rule):
	if the leading beats is not empty:
		perform entry 1 of the leading beats;
		if dialogue has been performed this turn:
			continue the action;
	if the other beats is not empty:
		perform entry 1 of the other beats;
		if dialogue has been performed this turn:
			continue the action;
	if the player is the actor:
		say "There is no reply." (A);
		stop the action;
	otherwise:
		if the player can hear the actor:
			say "[The actor] [talk] about [T]." (B);
		stop the action.
