Phrase Definitions.

The phrases making up the Inform language, and in terms of which all
other phrases and rules are defined; and the final sign-off of the Standard
Rules extension, including its minimal documentation.

@ Our last task is to create the phrases: more or less all of them, but that
does need a little qualification. NI has no phrase definitions built in,
but it does contain assumptions about how "say ...", "repeat ...",
"let ...", "otherwise ..." and "end ..." will behave when defined: we
would not be allowed to call these something else, or redefine them in
fundamentally different ways. Apart from that, we are more or less free.

Most of these phrases are defined in terms of I6 code, using the |(-| and
|-)| notation -- it would be too cumbersome to use the "... translates into
I6 as ..." verb for this, too. The fact that phrases are not so much
translated as transliterated was one source of early criticism of Inform 7.
Phrases appeared to have very simplistic definitions, with the natural
language simply being a verbose description of obviously equivalent I6 code.
However, the simplicity is misleading, because the definitions below tend
to conceal where the complexity of the translation process suddenly
increases. If the preamble includes "(c - condition)", and the definition
includes the expansion |{c}|, then the text forming c is translated in a way
much more profound than any simple substitution process could describe.
Type-checking also complicates the code produced below, since NI automatically
generates the code needed to perform run-time type checking at any point where
doubt remains as to the phrase definition which must be used.

@h Say phrases.
We begin with saying phrases: the very first phrase to exist is the one
printing a single value -- literal text, a number, a time, an object, or
really almost anything, since the vast majority of kinds in Inform are
sayable. There used to be separate definitions for saying text, numbers
and unicode characters here, but they were removed in June 2015 as being
redundant. Though they did no harm, they made some problem messages longer
than necessary by obliging them to cite a longer list of possible readings
of a misread phrase.

=
Part SR5 - Phrasebook

Section SR5/1/1a - Saying - Time Values (for interactive fiction language element only)

To say (something - time) in words
	(documented at phs_timewords):
	(- print (PrintTimeOfDayEnglish) {something}; -).


To say here
	(documented at phs_here):
	say "[if story tense is present tense]here[otherwise]there".
To say now
	(documented at phs_now):
	say "[if story tense is present tense]now[otherwise]then".

@ Now some visual effects, which may or may not be rendered the way the user
hopes: that's partly up to the virtual machine, unfortunately.

=
Section SR5/1/7 - Saying - Fonts and visual effects

To display the boxed quotation (Q - text)
	(documented at ph_boxed):
	(- DisplayBoxedQuotation({-box-quotation-text:Q}); -).

@ And now some oddball special texts which must sometimes be said.

=
Section SR5/1/8 - Saying - Some built-in texts

To say the/-- banner text
	(documented at phs_banner):
	(- Banner(); -).
To say the/-- list of extension credits
	(documented at phs_extcredits):
	(- ShowExtensionVersions(); -).
To say the/-- complete list of extension credits
	(documented at phs_compextcredits):
	(- ShowFullExtensionVersions(); -).
To say the/-- player's surroundings
	(documented at phs_surroundings):
	(- SL_Location(true); -).
To say run paragraph on with special look spacing -- running on
	(documented at phs_runparaonsls):
	(- SpecialLookSpacingBreak(); -).
To say command clarification break -- running on
	(documented at phs_clarifbreak):
	(- CommandClarificationBreak(); -).

@h Using the list-writer.
The I7 list-writer resembles the old I6 library one, but has been reimplemented
in a more general way: see the template file "ListWriter.i6t". The following
is the main routine for listing:

=
Section SR5/1/9 - Saying - Saying lists of things

To list the contents of (O - an object),
	with newlines,
	indented,
	giving inventory information,
	as a sentence,
	including contents,
	including all contents,
	tersely,
	giving brief inventory information,
	using the definite article,
	listing marked items only,
	prefacing with is/are,
	not listing concealed items,
	suppressing all articles,
	with extra indentation,
	and/or capitalized
	(documented at ph_listcontents):
	(- WriteListFrom(child({O}), {phrase options}); -).

@h Text substitutions using the list-writer.
These all look (and are) repetitive. We want to avoid passing a description
value to some routine, because that's tricky if the description needs to refer
to a value local to the current stack frame. (There are ways round that, but
it minimises nuisance to avoid the need.) So we mark out the set of objects
matching by giving them, and only them, the |workflag2| attribute.

=
To say a list of (OS - description of objects)
	(documented at phs_alistof): (-
	 	objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		WriteListOfMarkedObjects(ENGLISH_BIT);
	-).
To say A list of (OS - description of objects)
	(documented at phs_Alistof):
	(-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		TEXT_TY_Say_Capitalised((+ "[list-writer list of marked objects]" +));
	-).

To say list of (OS - description of objects)
	(documented at phs_listof): (-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		WriteListOfMarkedObjects(ENGLISH_BIT+NOARTICLE_BIT);
	-).
To say the list of (OS - description of objects)
	(documented at phs_thelistof): (-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		WriteListOfMarkedObjects(ENGLISH_BIT+DEFART_BIT);
	-).
To say The list of (OS - description of objects)
	(documented at phs_Thelistof):
	(-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		TEXT_TY_Say_Capitalised((+ "[list-writer articled list of marked objects]" +));
	-).
To say is-are a list of (OS - description of objects)
	(documented at phs_isalistof): (-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		WriteListOfMarkedObjects(ENGLISH_BIT+ISARE_BIT);
	-).
To say is-are list of (OS - description of objects)
	(documented at phs_islistof): (-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		WriteListOfMarkedObjects(ENGLISH_BIT+ISARE_BIT+NOARTICLE_BIT);
	-).
To say is-are the list of (OS - description of objects)
	(documented at phs_isthelistof): (-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		WriteListOfMarkedObjects(ENGLISH_BIT+DEFART_BIT+ISARE_BIT);
	-).
To say a list of (OS - description of objects) including contents
	(documented at phs_alistofconts): (-
		objectloop({-my:1} ofclass Object)
			if ({-matches-description:1:OS})
				give {-my:1} workflag2;
			else
				give {-my:1} ~workflag2;
		WriteListOfMarkedObjects(ENGLISH_BIT+RECURSE_BIT+PARTINV_BIT+
			TERSE_BIT+CONCEAL_BIT);
	-).

@h Grouping in the list-writer.
See the specifications of |list_together| and |c_style| in the DM4, which are
still broadly accurate.

=
Section SR5/1/10 - Saying - Group in and omit from lists

To group (OS - description of objects) together
	(documented at ph_group): (-
		objectloop({-my:1} provides list_together)
			if ({-matches-description:1:OS})
				BlkValueCopy({-my:1}.list_together, {-list-together:unarticled});
	-).
To group (OS - description of objects) together giving articles
	(documented at ph_groupart): (-
		objectloop({-my:1} provides list_together)
			if ({-matches-description:1:OS})
				BlkValueCopy({-my:1}.list_together, {-list-together:articled});
	-).
To group (OS - description of objects) together as (T - text)
	(documented at ph_grouptext): (-
		{-my:2} = BlkValueCreate(TEXT_TY);
		{-my:2} = TEXT_TY_SubstitutedForm({-my:2}, {-by-reference:T});
		objectloop({-my:1} provides list_together)
			if ({-matches-description:1:OS})
				BlkValueCopy({-my:1}.list_together, {-my:2});
		BlkValueFree({-my:2});
	-).
To omit contents in listing
	(documented at ph_omit):
	(- c_style = c_style &~ (RECURSE_BIT+FULLINV_BIT+PARTINV_BIT); -).

@h Filtering in the list-writer.
Something of a last resort, which is intentionally not documented.
It's needed by the Standard Rules to tidy up an implementation and
avoid I6, but is not an ideal trick and may be dropped in later
builds. Recursion occurs when the list-writer descends to the contents
of, or items supported by, something it lists. Here we can restrict to
just those contents, or supportees, matching a description |D|.

=
Section SR5/1/12 - Saying - Filtering contents - Unindexed

To filter list recursion to (D - description of objects):
	(- list_filter_routine = {D}; -).
To unfilter list recursion:
	(- list_filter_routine = 0; -).

@h Responses.

=
Section SR5/1/13 - Saying - Responses

To say text of (R - response)
	(documented at phs_response):
	carry out the issuing the response text activity with R.

@h Lists.
The following are all for adding and removing values to dynamic lists:

=

@ The multiple object list is a data structure used in the parser when
processing commands like TAKE ALL.

=
To decide what list of objects is the multiple object list
	(documented at ph_multipleobjectlist):
	(- LIST_OF_TY_Mol({-new:list of objects}) -).
To alter the multiple object list to (L - list of objects)
	(documented at ph_altermultipleobjectlist):
	(- LIST_OF_TY_Set_Mol({-by-reference:L}); -).

@ Figures and sound effects.
Ditto, but for "Figures.i6t".

=
Section SR5/2/22 - Values - Figures (for figures language element only)

To display (F - figure name), one time only
	(documented at ph_displayfigure):
	(- DisplayFigure(ResourceIDsOfFigures-->{F}, {phrase options}); -).
To decide which number is the Glulx resource ID of (F - figure name)
	(documented at ph_figureid):
	(- ResourceIDsOfFigures-->{F} -).

Section SR5/2/23 - Values - Sound effects (for sounds language element only)

To play (SFX - sound name), one time only
	(documented at ph_playsf):
	(- PlaySound(ResourceIDsOfSounds-->{SFX}, {phrase options}); -).
To decide which number is the Glulx resource ID of (SFX - sound name)
	(documented at ph_soundid):
	(- ResourceIDsOfSounds-->{SFX} -).

@ The antique forms "yes" and "no" are now somewhat to be regretted, with
"decide yes" and "decide no" being clearer ways to write the same thing.
But we seem to be stuck with them.

=
Section SR5/3/7 - Control phrases - Deciding outcomes

To yes
	(documented at ph_yes):
	(- rtrue; -) - in to decide if only.
To no
	(documented at ph_no):
	(- rfalse; -) - in to decide if only.

@h Actions, activities and rules.
We begin with the firing off of new actions. The current action runs silently
if the I6 global variable |keep_silent| is set, so the result of the
definitions below is that one can go into silence mode, using "try silently",
but not climb out of it again. This is done because many actions try other
actions as part of their normal workings: if we want action $X$ to be tried
silently, then any action $X$ itself tries should also be tried silently.

=
Section SR5/4/1 - Actions, activities and rules - Trying actions (for interactive fiction language element only)

To try (S - action)
	(documented at ph_try):
	(- {-try-action:S} -).
To silently try (S - action)
	(documented at ph_trysilently):
	(- {-try-action-silently:S} -).
To try silently (S - action)
	(documented at ph_trysilently):
	(- {-try-action-silently:S} -).
To decide whether the action is not silent:
	(- (keep_silent == false) -).

@ The requirements of the current action can be tested. The following
may be reimplemented using a verb "to require" at some future point.

=
Section SR5/4/2 - Actions, activities and rules - Action requirements (for interactive fiction language element only)

To decide whether the action requires a touchable noun
	(documented at ph_requirestouch):
	(- (NeedToTouchNoun()) -).
To decide whether the action requires a touchable second noun
	(documented at ph_requirestouch2):
	(- (NeedToTouchSecondNoun()) -).
To decide whether the action requires a carried noun
	(documented at ph_requirescarried):
	(- (NeedToCarryNoun()) -).
To decide whether the action requires a carried second noun
	(documented at ph_requirescarried2):
	(- (NeedToCarrySecondNoun()) -).
To decide whether the action requires light
	(documented at ph_requireslight):
	(- (NeedLightForAction()) -).

To anonymously abide by (RL - a rule)
	(documented at ph_abideanon):
	(- if (temporary_value = FollowRulebook({RL})) {
		if (RulebookSucceeded()) ActRulebookSucceeds(temporary_value);
		else ActRulebookFails(temporary_value);
		return 2;
	} -) - in to only.
To anonymously abide by (RL - value of kind K based rule producing a value) for (V - K)
	(documented at ph_abideanon):
	(- if (temporary_value = FollowRulebook({RL}, {V}, true)) {
		if (RulebookSucceeded()) ActRulebookSucceeds(temporary_value);
		else ActRulebookFails(temporary_value);
		return 2;
	} -) - in to only.
To anonymously abide by (RL - a nothing based rule)
	(documented at ph_abideanon):
	(- if (temporary_value = FollowRulebook({RL})) {
		if (RulebookSucceeded()) ActRulebookSucceeds(temporary_value);
		else ActRulebookFails(temporary_value);
		return 2;
	} -) - in to only.

@ Within the rulebooks to do with an action, returning |true| from a rule
is sufficient to stop the rulebook early: there is no need to specify
success or failure because that is determined by the rulebook itself. (For
instance, if the check taking rules stop for any reason, the action failed;
if the after rules stop, it succeeded.) In some rulebooks, notably "instead"
and "after", the default is to stop, so that execution reaching the end of
the I6 routine for a rule will run into an |rtrue|. "Continue the action"
prevents this.

=
Section SR5/4/3 - Actions, activities and rules - Stop or continue (for interactive fiction language element only)

To stop the action
	(documented at ph_stopaction):
	(- rtrue; -) - in to only.
To continue the action
	(documented at ph_continueaction):
	(- rfalse; -) - in to only.

@ =
Section SR5/4/4 - Actions, activities and rules - Actions as values (for interactive fiction language element only)

To decide what action is the current action
	(documented at ph_currentaction):
	(- STORED_ACTION_TY_Current({-new:action}) -).
To decide what action is the action of (A - action)
	(documented at ph_actionof):
	(- {A} -).
To decide if (act - a action) involves (X - an object)
	(documented at ph_involves):
	(- (STORED_ACTION_TY_Involves({-by-reference:act}, {X})) -).
To decide what action name is the action name part of (act - a action)
	(documented at ph_actionpart):
	(- (STORED_ACTION_TY_Part({-by-reference:act}, STORA_ACTION_F)) -).
To decide what object is the noun part of (act - a action)
	(documented at ph_nounpart):
	(- (STORED_ACTION_TY_Part({-by-reference:act}, STORA_NOUN_F)) -).
To decide what object is the second noun part of (act - a action)
	(documented at ph_secondpart):
	(- (STORED_ACTION_TY_Part({-by-reference:act}, STORA_SECOND_F)) -).
To decide what object is the actor part of (act - a action)
	(documented at ph_actorpart):
	(- (STORED_ACTION_TY_Part({-by-reference:act}, STORA_ACTOR_F)) -).

@h The model world.
Phrase definitions with wordings like "the story has ended" are a
necessary evil. The "has" here is parsed literally, not as the present
tense of "to have", so inflected forms like "the story had ended" are
not available: nor is there any value "the story" for the subject noun
phrase to hold... and so on. Ideally, we would word all conditional phrases
so as to avoid the verbs, but natural language just doesn't work that way.

=
Section SR5/5/1 - Model world - Ending the story (for interactive fiction language element only)

To end the story
	(documented at ph_end):
	(- deadflag=3; story_complete=false; -).
To end the story finally
	(documented at ph_endfinally):
	(- deadflag=3; story_complete=true; -).
To end the story saying (finale - text)
	(documented at ph_endsaying):
	(- deadflag={-by-reference:finale}; story_complete=false; -).
To end the story finally saying (finale - text)
	(documented at ph_endfinallysaying):
	(- deadflag={-by-reference:finale}; story_complete=true; -).
To decide whether the story has ended
	(documented at ph_ended):
	(- (deadflag~=0) -).
To decide whether the story has ended finally
	(documented at ph_finallyended):
	(- (story_complete) -).
To decide whether the story has not ended
	(documented at ph_notended):
	(- (deadflag==0) -).
To decide whether the story has not ended finally
	(documented at ph_notfinallyended):
	(- (story_complete==false) -).
To resume the story
	(documented at ph_resume):
	(- resurrect_please = true; -).

@ Times of day.

=
Section SR5/5/2 - Model world - Times of day (for interactive fiction language element only)

To decide which number is the minutes part of (t - time)
	(documented at ph_minspart):
	(- ({t}%ONE_HOUR) -).
To decide which number is the hours part of (t - time)
	(documented at ph_hourspart):
	(- ({t}/ONE_HOUR) -).

@ Comparing times of day is inherently odd, because the day is
circular. Every 2 PM comes after a 1 PM, but it also comes before
another 1 PM. Where do we draw the meridian on this circle? The legal
day divides at midnight but for other purposes (daylight savings time,
for instance) society often chooses 2 AM as the boundary. Inform uses
4 AM instead as the least probable time through which play continues.
(Modulo a 24-hour clock, adding 20 hours is equivalent to subtracting
4 AM from the current time: hence the use of |20*ONE_HOUR| below.)
Thus 3:59 AM is after 4:00 AM, the former being at the very end of a
day, the latter at the very beginning.

=
To decide if (t - time) is before (t2 - time)
	(documented at ph_timebefore):
	(- ((({t}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))<(({t2}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))) -).
To decide if (t - time) is after (t2 - time)
	(documented at ph_timeafter):
	(- ((({t}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))>(({t2}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))) -).
To decide which time is (t - time) before (t2 - time)
	(documented at ph_shiftbefore):
	(- (({t2}-{t}+TWENTY_FOUR_HOURS)%(TWENTY_FOUR_HOURS)) -).
To decide which time is (t - time) after (t2 - time)
	(documented at ph_shiftafter):
	(- (({t2}+{t}+TWENTY_FOUR_HOURS)%(TWENTY_FOUR_HOURS)) -).

@ Durations are in effect casts from "number" to "time".

=
Section SR5/5/3 - Model world - Durations (for interactive fiction language element only)

To decide which time is (n - number) minutes
	(documented at ph_durationmins):
	(- (({n})%(TWENTY_FOUR_HOURS)) -).
To decide which time is (n - number) hours
	(documented at ph_durationhours):
	(- (({n}*ONE_HOUR)%(TWENTY_FOUR_HOURS)) -).

@ Timed events.

=
Section SR5/5/4 - Model world - Timed events (for interactive fiction language element only)

To (R - rule) in (t - number) turn/turns from now
	(documented at ph_turnsfromnow):
	(- SetTimedEvent({-mark-event-used:R}, {t}+1, 0); -).
To (R - rule) at (t - time)
	(documented at ph_attime):
	(- SetTimedEvent({-mark-event-used:R}, {t}, 1); -).
To (R - rule) in (t - time) from now
	(documented at ph_timefromnow):
	(- SetTimedEvent({-mark-event-used:R}, (the_time+{t})%(TWENTY_FOUR_HOURS), 1); -).

@ Scenes.

=
Section SR5/5/5 - Model world - Scenes (for interactive fiction language element only)

To decide if (sc - scene) has happened
	(documented at ph_hashappened):
	(- (scene_endings-->({sc}-1)) -).
To decide if (sc - scene) has not happened
	(documented at ph_hasnothappened):
	(- (scene_endings-->({sc}-1) == 0) -).
To decide if (sc - scene) has ended
	(documented at ph_hasended):
	(- (scene_endings-->({sc}-1) > 1) -).
To decide if (sc - scene) has not ended
	(documented at ph_hasnotended):
	(- (scene_endings-->({sc}-1) <= 1) -).

@ Timing of scenes.

=
Section SR5/5/6 - Model world - Timing of scenes (for interactive fiction language element only)

To decide which time is the time since (sc - scene) began
	(documented at ph_scenetimesincebegan):
	(- (SceneUtility({sc}, 1)) -).
To decide which time is the time when (sc - scene) began
	(documented at ph_scenetimewhenbegan):
	(- (SceneUtility({sc}, 2)) -).
To decide which time is the time since (sc - scene) ended
	(documented at ph_scenetimesinceended):
	(- (SceneUtility({sc}, 3)) -).
To decide which time is the time when (sc - scene) ended
	(documented at ph_scenetimewhenended):
	(- (SceneUtility({sc}, 4)) -).

@ Player's identity and location.

=
Section SR5/5/7 - Model world - Player's identity and location (for interactive fiction language element only)

To decide whether in darkness
	(documented at ph_indarkness):
	(- (location==thedark) -).

@ Moving and removing things.

=
Section SR5/5/8 - Model world - Moving and removing things (for interactive fiction language element only)

To move (something - object) to (something else - object),
	without printing a room description
	or printing an abbreviated room description
	(documented at ph_move):
	(- MoveObject({something}, {something else}, {phrase options}, false); -).
To remove (something - object) from play
	(deprecated)
	(documented at ph_remove):
	(- RemoveFromPlay({something}); -).
To move (O - object) backdrop to all (D - description of objects)
	(documented at ph_movebackdrop):
	(- MoveBackdrop({O}, {D}); -).
To update backdrop positions
	(documented at ph_updatebackdrop):
	(- MoveFloatingObjects(); -).

@ The map.

=
Section SR5/5/9 - Model world - The map (for interactive fiction language element only)

To decide which room is location of (O - object)
	(documented at ph_locationof):
	(- LocationOf({O}) -).
To decide which room is room (D - direction) from/of (R1 - room)
	(documented at ph_roomdirof):
	(- MapConnection({R1},{D}) -).
To decide which door is door (D - direction) from/of (R1 - room)
	(documented at ph_doordirof):
	(- DoorFrom({R1},{D}) -).
To decide which object is the other side of (D - door) from (R1 - room)
	(documented at ph_othersideof):
	(- OtherSideOfDoor({D},{R1}) -).
To decide which object is the direction of (D - door) from (R1 - room)
	(documented at ph_directionofdoor):
	(- DirectionDoorLeadsIn({D},{R1}) -).
To decide which object is room-or-door (D - direction) from/of (R1 - room)
	(documented at ph_roomordoor):
	(- RoomOrDoorFrom({R1},{D}) -).
To change (D - direction) exit of (R1 - room) to (R2 - room)
	(documented at ph_changeexit):
	(- AssertMapConnection({R1},{D},{R2}); -).
To change (D - direction) exit of (R1 - room) to nothing/nowhere
	(documented at ph_changenoexit):
	(- AssertMapConnection({R1},{D},nothing); -).
To decide which room is the front side of (D - object)
	(documented at ph_frontside):
	(- FrontSideOfDoor({D}) -).
To decide which room is the back side of (D - object)
	(documented at ph_backside):
	(- BackSideOfDoor({D}) -).

@ Route-finding.

=
Section SR5/5/10 - Model world - Route-finding (for interactive fiction language element only)

To decide which object is best route from (R1 - object) to (R2 - object),
	using doors or using even locked doors
	(documented at ph_bestroute):
	(- MapRouteTo({R1},{R2},0,{phrase options}) -).
To decide which number is number of moves from (R1 - object) to (R2 - object),
	using doors or using even locked doors
	(documented at ph_bestroutelength):
	(- MapRouteTo({R1},{R2},0,{phrase options},true) -).
To decide which object is best route from (R1 - object) to (R2 - object) through
	(RS - description of objects),
	using doors or using even locked doors
	(documented at ph_bestroutethrough):
	(- MapRouteTo({R1},{R2},{RS},{phrase options}) -).
To decide which number is number of moves from (R1 - object) to (R2 - object) through
	(RS - description of objects),
	using doors or using even locked doors
	(documented at ph_bestroutethroughlength):
	(- MapRouteTo({R1},{R2},{RS},{phrase options},true) -).

@ The object tree.

=
Section SR5/5/11 - Model world - The object tree (for interactive fiction language element only)

To decide which object is holder of (something - object)
	(documented at ph_holder):
	(- (HolderOf({something})) -).
To decide which object is next thing held after (something - object)
	(documented at ph_nextheld):
	(- (sibling({something})) -).
To decide which object is first thing held by (something - object)
	(documented at ph_firstheld):
	(- (child({something})) -).

@h Understanding.
First, asking yes/no questions.

=
Section SR5/6/1 - Understanding - Asking yes/no questions

To decide whether player consents
	(documented at ph_consents):
		(- YesOrNo() -).

@ Support for snippets, which are substrings of the player's command.

=
Section SR5/6/2 - Understanding - The player's command (for interactive fiction language element only)

To decide if (S - a snippet) matches (T - a topic)
	(documented at ph_snippetmatches):
	(- (SnippetMatches({S}, {T})) -).
To decide if (S - a snippet) does not match (T - a topic)
	(documented at ph_snippetdoesnotmatch):
	(- (SnippetMatches({S}, {T}) == false) -).
To decide if (S - a snippet) includes (T - a topic)
	(documented at ph_snippetincludes):
	(- (matched_text=SnippetIncludes({T},{S})) -).
To decide if (S - a snippet) does not include (T - a topic)
	(documented at ph_snippetdoesnotinclude):
	(- (SnippetIncludes({T},{S})==0) -).

@ Changing the player's command.

=
Section SR5/6/3 - Understanding - Changing the player's command (for interactive fiction language element only)

To change the text of the player's command to (T - text)
	(documented at ph_changecommand):
	(- SetPlayersCommand({-by-reference:T}); -).
To replace (S - a snippet) with (T - text)
	(documented at ph_replacesnippet):
	(- SpliceSnippet({S}, {-by-reference:T}); -).
To cut (S - a snippet)
	(documented at ph_cutsnippet):
	(- SpliceSnippet({S}, 0); -).
To reject the player's command
	(documented at ph_rejectcommand):
	(- RulebookFails(); rtrue; -) - in to only.

@ Scope and pronouns.

=
Section SR5/6/4 - Understanding - Scope and pronouns (for interactive fiction language element only)

To place (O - an object) in scope, but not its contents
	(documented at ph_placeinscope):
	(- PlaceInScope({O}, {phrase options}); -).
To place the/-- contents of (O - an object) in scope
	(documented at ph_placecontentsinscope):
	(- ScopeWithin({O}); -).
To set pronouns from (O - an object)
	(documented at ph_setpronouns):
	(- PronounNotice({O}); -).

@h Message support.
"Unindexed" here is a euphemism for "undocumented". This is where
experimental or intermediate phrases go: things we don't want people
to use because we will probably revise them heavily in later builds of
Inform. For now, the Standard Rules do make use of these phrases, but
nobody else should. They will change without comment in the change
log.

=
Section SR5/8/1 - Message support - Issuance - Unindexed

To issue score notification message:
	(- NotifyTheScore(); -).
To say pronoun dictionary word:
	(- print (address) pronoun_word; -).
To say recap of command:
	(- PrintCommand(); -).
The pronoun reference object is an object that varies.
The pronoun reference object variable translates into I6 as "pronoun_obj".

To say pronoun i6 dictionary word:
	(- print (address) pronoun_word; -).

To say parser command so far:
	(- PrintCommand(); -).

@h Miscellaneous other phrases.
Again, these are not part of Inform's public specification.

=
Section SR5/9/1 - Miscellaneous other phrases - Unindexed (for interactive fiction language element only)

@ These are actually sensible concepts in the world model, and could even
be opened to public use, but they're quite complicated to explain.

=
To decide which object is the component parts core of (X - an object):
	(- CoreOf({X}) -).
To decide which object is the common ancestor of (O - an object) with
	(P - an object):
	 (- (CommonAncestor({O}, {P})) -).
To decide which object is the not-counting-parts holder of (O - an object):
	 (- (CoreOfParentOfCoreOf({O})) -).
To decide which object is the visibility-holder of (O - object):
	(- VisibilityParent({O}) -).
To calculate visibility ceiling at low level:
	(- FindVisibilityLevels(); -).
To decide which object is the touchability ceiling of (O - object):
	(- TouchabilityCeiling({O}) -).

@ These are in effect global variables, but aren't defined as such, to
prevent people using them. Their contents are only very briefly meaningful,
and they would be dangerous friends to know.

=
To decide which number is the visibility ceiling count calculated:
	(- visibility_levels -).
To decide which object is the visibility ceiling calculated:
	(- visibility_ceiling -).

@ This is a unique quasi-action, using the secondary action processing
stage only. A convenience, but also an anomaly, and let's not encourage
its further use.

=
To produce a room description with going spacing conventions:
	(- LookAfterGoing(); -).

@ An ugly little trick needed because of the mismatch between I6 and I7
property implementation, and because of legacy code from the old I6 library.
Please don't touch.

=
To print the location's description:
	(- PrintOrRun(location, description); -).

@ This avoids "mentioned" being given to items printed only internally for
the sake of a string comparison, and not shown on screen.

=
To decide if expanding text for comparison purposes:
	(- say__comp -).

@ This is a bit trickier than it looks, because it isn't always set when
one thinks it is.

=
To decide whether the I6 parser is running multiple actions:
	(- (multiflag==1) -).

@ Again, the following cries out for an enumerated kind of value.

=
To decide if set to sometimes abbreviated room descriptions:
	(- (lookmode == 1) -).
To decide if set to unabbreviated room descriptions:
	(- (lookmode == 2) -).
To decide if set to abbreviated room descriptions:
	(- (lookmode == 3) -).

@ Action conversion is a trick used in the Standard Rules to simplify the
implementation of actions: it allows one action to become another one
mid-way, without causing spurious action failures. (There are better ways
to make user-defined actions convert, and some of the examples show this.)

=
To convert to (AN - an action name) on (O - an object):
	(- return GVS_Convert({AN},{O},0); -) - in to only.
To convert to request of (X - object) to perform (AN - action name) with
	(Y - object) and (Z - object):
	(- return ConvertToRequest({X}, {AN}, {Y}, {Z}); -).
To convert to special going-with-push action:
	(- return ConvertToGoingWithPush(); -).

@ The "surreptitiously" phrases shouldn't be used except in the Standard Rules
because they temporarily violate invariants for the object tree and the
light variables; the SR uses them carefully in situations where it's known to
work out all right.

=
To surreptitiously move (something - object) to (something else - object):
	(- move {something} to {something else}; -).
To surreptitiously move (something - object) to (something else - object) during going:
	(- MoveDuringGoing({something}, {something else}); -).
To surreptitiously reckon darkness:
	(- SilentlyConsiderLight(); -).

@ These are text substitutions needed to make the capitalised lists work.

=
To say list-writer list of marked objects: (-
	 	WriteListOfMarkedObjects(ENGLISH_BIT);
	-).
To say list-writer articled list of marked objects: (-
	 	WriteListOfMarkedObjects(ENGLISH_BIT+DEFART_BIT+CFIRSTART_BIT);
	-).

@ This is convenient for debugging Inform, but for no other purpose. It
toggles verbose logging of the type-checker.

=
Section SR5/9/2 - Debugging Inform - Unindexed

To ***:
	(- {-primitive-definition:verbose-checking} -).
To *** (T - text):
	(- {-primitive-definition:verbose-checking} -).

@ And so, at last...

=
The Standard Rules end here.

@ ...except that this is not quite true, because like most extensions they
then quote some documentation for Inform to weave into index pages: though
here it's more of a polite refusal than a manual, since the entire system
documentation is really the description of what was defined in this
extension.

=
---- DOCUMENTATION ----

Unlike other extensions, the Standard Rules are compulsorily included
with every project. They define the phrases, kinds and relations which
are basic to Inform, and which are described throughout the documentation.
