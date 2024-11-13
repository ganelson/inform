Version 10.2.0 of the Standard Rules by Graham Nelson begins here.

"The Standard Rules, included in every interactive fiction project, creates
a model world populated by actors who perform actions."

Part One - Preamble

The verb to begin when means the built-in scene-begins-when meaning.
The verb to end when means the built-in scene-ends-when meaning.
The verb to end + when means the built-in scene-ends-when meaning.

The verb to understand + as in the imperative means the built-in understand-as meaning.
The verb to release along with in the imperative means the built-in release-along-with meaning.
The verb to index map with in the imperative means the built-in index-map-with meaning.

Use full-length room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 2 in WorldModelKit.
Use abbreviated room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 3 in WorldModelKit.
Use VERBOSE room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 2 in WorldModelKit.
Use BRIEF room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 1 in WorldModelKit.
Use SUPERBRIEF room descriptions translates as the configuration value
	ROOM_DESC_DETAIL = 3 in WorldModelKit.

Use no scoring translates as the configuration value
	SCORING = 0 in WorldModelKit.
Use scoring translates as the configuration value
	SCORING = 1 in WorldModelKit.

Use default route-finding translates as the configuration value
	ROUTE_FINDING = 0 in WorldModelKit.
Use fast route-finding translates as the configuration value
	ROUTE_FINDING = 1 in WorldModelKit.
Use slow route-finding translates as the configuration value
	ROUTE_FINDING = 2 in WorldModelKit.

Use maximum things understood at once of at least 100 translates as the
	configuration value MULTI_OBJ_LIST_SIZE in WorldModelKit.

Use nameless room descriptions translates as a configuration flag.

Use manual pronouns translates as the configuration flag
	MANUAL_PRONOUNS in CommandParserKit.
Use undo prevention translates as the configuration flag
	UNDO_PREVENTION in CommandParserKit.
Use unabbreviated object names translates as the configuration flag
	UNABBREVIATED_NAMES in CommandParserKit.

Part Two - The Physical World Model

Chapter 1 - Verbs and Relations

The verb to be in means the reversed containment relation.
The verb to be inside means the reversed containment relation.
The verb to be within means the reversed containment relation.
The verb to be held in means the reversed containment relation.
The verb to be held inside means the reversed containment relation.

The verb to contain means the containment relation.
The verb to be contained in means the reversed containment relation.

The verb to be on top of means the reversed support relation.
The verb to be on means the reversed support relation.

The verb to support means the support relation.
The verb to be supported on means the reversed support relation.

The verb to incorporate means the incorporation relation.
The verb to be part of means the reversed incorporation relation.
The verb to be a part of means the reversed incorporation relation.
The verb to be parts of means the reversed incorporation relation.

The verb to enclose means the enclosure relation.

The verb to carry means the carrying relation.
The verb to hold means the holding relation.
The verb to wear means the wearing relation.

Definition: a thing is worn if the player is wearing it.
Definition: a thing is carried if the player is carrying it.
Definition: a thing is held if the player is holding it.

The verb to be able to see means the visibility relation.
The verb to be able to hear means the audibility relation.
The verb to be able to touch means the touchability relation.

Definition: Something is visible rather than invisible if the player can see it.
Definition: Something is audible rather than inaudible if the player can hear it.
Definition: Something is touchable rather than untouchable if the player can touch it.

The verb to conceal (she conceals, they conceal, he concealed, it is concealed,
it is concealing) means the concealment relation.
Definition: Something is concealed rather than unconcealed if the holder of it conceals it.

Definition: a container is obviously-occupied rather than possibly-unoccupied if
I6 routine "ObviouslyOccupied" says so (it contains at least one obvious thing).

Definition: a supporter is obviously-occupied rather than possibly-unoccupied if
I6 routine "ObviouslyOccupied" says so (it supports at least one obvious thing).

Definition: a container (called c) is falsely-unoccupied:
  if the first thing held by it is nothing, no;
  if it is closed and it is opaque and it does not enclose the player, no;
  decide on whether or not it is possibly-unoccupied;

Definition: a supporter is falsely-unoccupied:
  if the first thing held by it is nothing, no;
  if the first thing held by it is the player and the next thing held after the player is nothing, no;
  decide on whether or not it is possibly-unoccupied;

Definition: Something is on-stage rather than off-stage if I6 routine "OnStage"
	makes it so (it is indirectly in one of the rooms).
Definition: An object is offstage if it is not on-stage.

Definition: a scene is happening if I6 condition "scene_status-->(*1-1)==1"
	says so (it is currently taking place).

Chapter 2 - Kinds for the Physical World

Section 1 - Kind Definitions

A room is a kind of object.
A thing is a kind of object.
A direction is a kind of object.
A door is a kind of thing.
A container is a kind of thing.
A supporter is a kind of thing.
A backdrop is a kind of thing.
The plural of person is people. The plural of person is persons.
A person is a kind of thing.
A region is a kind of object.

A concept is a kind of abstract object.

A room can be privately-named or publicly-named. A room is usually publicly-named.
A thing can be privately-named or publicly-named. A thing is usually publicly-named.
A direction can be privately-named or publicly-named. A direction is usually
publicly-named.
A region can be privately-named or publicly-named. A region is usually publicly-named.
A concept can be privately-named or publicly-named. A concept is usually publicly-named.

Section 2 - Rooms

The specification of room is "Represents geographical locations, both indoor
and outdoor, which are not necessarily areas in a building. A player in one
room is mostly unable to sense, or interact with, anything in a different room.
Rooms are arranged in a map."

A room can be lighted or dark. A room is usually lighted.
A room can be visited or unvisited. A room is usually unvisited.

A room has a text called description.

A room has an object called map region. The map region of a room is usually nothing.

The verb to be adjacent to means the reversed adjacency relation.
Definition: A room is adjacent if it is adjacent to the location.

The verb to be regionally in means the reversed regional-containment relation.

The specification of region is "Represents a broader area than a single
room, and allows rules to apply to a whole geographical territory. Each
region can contain many rooms, and regions can even be inside each other,
though they cannot otherwise overlap. For instance, the room Place d'Italie
might be inside the region 13th Arrondissement, which in turn is inside
the region Paris. Regions are useful mainly when the world is a large one,
and are optional."

Section 3 - Things

The specification of thing is "Represents anything interactive in the model
world that is not a room. People, pieces of scenery, furniture, doors and
mislaid umbrellas might all be examples, and so might more surprising things
like the sound of birdsong or a shaft of sunlight."

A thing can be lit or unlit. A thing is usually unlit.
A thing can be edible or inedible. A thing is usually inedible.
A thing can be fixed in place or portable. A thing is usually portable.
A thing can be scenery.
A thing can be wearable.
A thing can be pushable between rooms.

A thing can be handled.

A thing can be undescribed or described. A thing is usually described.
A thing can be marked for listing or unmarked for listing. A thing is usually
unmarked for listing.
A thing can be mentioned or unmentioned. A thing is usually unmentioned.

A thing has a text called a description.
A thing has a text called an initial appearance.

Scenery is usually fixed in place. [An implication.]

Section 4 - Directions

The specification of direction is "Represents a direction of movement, such
as northeast or down. They always occur in opposite, matched pairs: northeast
and southwest, for instance; down and up."

A direction can be marked for listing or unmarked for listing. A direction is
usually unmarked for listing.
A direction can be scenery. A direction is always scenery.

A direction has a direction called an opposite.

The north is a direction.
The northeast is a direction.
The northwest is a direction.
The south is a direction.
The southeast is a direction.
The southwest is a direction.
The east is a direction.
The west is a direction.
The up is a direction.
The down is a direction.
The inside is a direction.
The outside is a direction.

The north has opposite south. Understand "n" as north.
The northeast has opposite southwest. Understand "ne" as northeast.
The northwest has opposite southeast. Understand "nw" as northwest.
The south has opposite north. Understand "s" as south.
The southeast has opposite northwest. Understand "se" as southeast.
The southwest has opposite northeast. Understand "sw" as southwest.
The east has opposite west. Understand "e" as east.
The west has opposite east. Understand "w" as west.
Up has opposite down. Understand "u" as up.
Down has opposite up. Understand "d" as down.
Inside has opposite outside. Understand "in" as inside.
Outside has opposite inside. Understand "out" as outside.

The inside object is accessible to Inter as "in_obj".
The outside object is accessible to Inter as "out_obj".

The verb to be above means the mapping up relation.
The verb to be mapped above means the mapping up relation.
The verb to be below means the mapping down relation.
The verb to be mapped below means the mapping down relation.

Section 5 - Doors

The specification of door is "Represents a conduit joining two rooms, most
often a door or gate but sometimes a plank bridge, a slide or a hatchway.
Usually visible and operable from both sides (for instance if you write
'The blue door is east of the Ballroom and west of the Garden.'), but
sometimes only one-way (for instance if you write 'East of the Ballroom is
the long slide. Through the long slide is the cellar.')."

A door is always fixed in place.
A door is never pushable between rooms.

A door has an object called leading-through destination.
The leading-through destination property is defined by Inter as "door_to".
Leading-through relates one room (called the leading-through destination) to
various doors. The verb to be through means the leading-through relation.

Section 6 - Containers

The specification of container is "Represents something into which portable
things can be put, such as a teachest or a handbag. Something with a really
large immobile interior, such as the Albert Hall, had better be a room
instead."

A container can be enterable.
A container can be transparent or opaque. A container is usually opaque.
A container has a number called carrying capacity.
The carrying capacity of a container is usually 100.

Section 7 - Supporters

The specification of supporter is "Represents a surface on which things can be
placed, such as a table."

A supporter can be enterable.
A supporter has a number called carrying capacity.
The carrying capacity of a supporter is usually 100.

A supporter is usually fixed in place.
A supporter can be transparent. A supporter is always transparent.

Section 8 - Openability

A door can be open or closed. A door is usually closed.
A door can be openable or unopenable. A door is usually openable.

A container can be open or closed. A container is usually open.
A container can be openable or unopenable. A container is usually unopenable.

Section 9 - Lockability

A door can be lockable. A door is usually not lockable.
A door can be locked or unlocked. A door is usually unlocked.
A door has an object called a matching key.
A locked door is usually lockable. [An implication.]
A locked door is usually closed. [An implication.]
A lockable door is usually openable. [An implication.]

A container can be lockable. A container is usually not lockable.
A container can be locked or unlocked. A container is usually unlocked.
A container has an object called a matching key.
A locked container is usually lockable. [An implication.]
A locked container is usually closed. [An implication.]
A lockable container is usually openable. [An implication.]

Lock-fitting relates one thing (called the matching key) to various things.
The verb to unlock means the lock-fitting relation.

Section 10 - Backdrops

The specification of backdrop is "Represents an aspect of the landscape
or architecture which extends across more than one room: for instance,
a stream, the sky or a long carpet."

A backdrop is usually scenery.
A backdrop is always fixed in place.
A backdrop is never pushable between rooms.

Section 11 - People

The specification of person is "Despite the name, not necessarily a human
being, but anything animate enough to envisage having a conversation with, or
bartering with."

A person can be female or male. A person is usually male.
A person can be neuter. A person is usually not neuter.

A person has a number called carrying capacity.
The carrying capacity of a person is usually 100.

A person can be transparent. A person is always transparent.

The yourself is an undescribed person. The yourself is proper-named.

The yourself is privately-named.
Understand "your former self" or "my former self" or "former self" or
	"former" as yourself when the player is not yourself.

The description of yourself is usually "As good-looking as ever."

The yourself object is accessible to Inter as "selfobj".

Section 12 - Animals, men and women

The plural of man is men. The plural of woman is women.

A man is a kind of person.
The specification of man is "Represents a man or boy."
A man is always male. A man is never neuter.

A woman is a kind of person.
The specification of woman is "Represents a woman or girl."
A woman is always female. A woman is never neuter.

An animal is a kind of person.

The specification of animal is "Represents an animal, or at any rate a
non-human living creature reasonably large and possible to interact with: a
giant Venus fly-trap might qualify, but not a patch of lichen."

Section 13 - Devices

A device is a kind of thing.

A device can be switched on or switched off. A device is usually switched off.

The specification of device is "Represents a machine or contrivance of some
kind which can be switched on or off."

Section 14 - Vehicles

A vehicle is a kind of container.

The specification of vehicle is "Represents a container large enough for
a person to enter, and which can then move between rooms at the driver's
instruction. (If a supporter is needed instead, try the extension
Rideable Vehicles by Graham Nelson.)"

A vehicle is always enterable.

A vehicle is usually not portable.

Section 15 - Player's holdall

A player's holdall is a kind of container.

The specification of player's holdall is "Represents a container which the
player can carry around as a sort of rucksack, into which spare items are
automatically stowed away."

A player's holdall is always portable.
A player's holdall is usually openable.

Section 16 - Inter identifier equivalents

The wearable property is defined by Inter as "clothing".
The undescribed property is defined by Inter as "concealed".
The edible property is defined by Inter as "edible".
The enterable property is defined by Inter as "enterable".
The female property is defined by Inter as "female".
The mentioned property is defined by Inter as "mentioned".
The lit property is defined by Inter as "light".
The lighted property is defined by Inter as "light".
The lockable property is defined by Inter as "lockable".
The locked property is defined by Inter as "locked".
The handled property is defined by Inter as "moved".
The neuter property is defined by Inter as "neuter".
The switched on property is defined by Inter as "on".
The open property is defined by Inter as "open".
The openable property is defined by Inter as "openable".
The privately-named property is defined by Inter as "privately_named".
The pushable between rooms property is defined by Inter as "pushable".
The scenery property is defined by Inter as "scenery".
The fixed in place property is defined by Inter as "static".
The transparent property is defined by Inter as "transparent".
The visited property is defined by Inter as "visited".
The marked for listing property is defined by Inter as "workflag".
The list grouping key property is defined by Inter as "list_together".

The carrying capacity property is defined by Inter as "capacity".
The description property is defined by Inter as "description".
The initial appearance property is defined by Inter as "initial".
The map region property is defined by Inter as "map_region".
The matching key property is defined by Inter as "with_key".

A time minus a time specifies a time period.



Part Three - Variables and Rulebooks

Chapter 1 - Variables

Section 1 - Situation

The player is a person that varies.
The player variable is defined by Inter as "player".

The location -- documented at var_location -- is an object that varies.
The score -- documented at var_score -- is a number that varies.
The last notified score is a number that varies.
The maximum score is a number that varies.
The turn count is a number that varies.
The time of day -- documented at var_time -- is a time that varies.
The darkness witnessed is a truth state that varies.

The location variable is defined by Inter as "real_location".
The score variable is defined by Inter as "score".
The last notified score variable is defined by Inter as "last_score".
The maximum score variable is defined by Inter as "MAX_SCORE".
The turn count variable is defined by Inter as "turns".
The time of day variable is defined by Inter as "the_time".

Section 2 - Current action

The noun -- documented at var_noun -- is an object that varies.
The second noun is an object that varies.
The person asked -- documented at var_person_asked -- is an object that varies.
The reason the action failed -- documented at var_reason -- is an action
based rule producing nothing that varies.
The item described is an object that varies.

The noun variable is defined by Inter as "noun".
The second noun variable is defined by Inter as "second".
The person asked variable is defined by Inter as "actor".
The reason the action failed variable is defined by Inter as "reason_the_action_failed".
The item described variable is defined by Inter as "self".

Section 3 - Used when ruling on accessibility

The person reaching -- documented at var_person_reaching -- is an object that varies.
The container in question is an object that varies.
The supporter in question is an object that varies.
The particular possession -- documented at var_particular -- is a thing that varies.

The person reaching variable is defined by Inter as "actor".
The container in question variable is defined by Inter as "parameter_object".
The supporter in question variable is defined by Inter as "parameter_object".
The particular possession variable is defined by Inter as "particular_possession".

Section 4 - Used when understanding typed commands

The player's command -- documented at var_command -- is a snippet that varies.
The matched text is a snippet that varies.
The topic understood is a snippet that varies.
The current item from the multiple object list is an object that varies.

The player's command variable is defined by Inter as "players_command".
The matched text variable is defined by Inter as "matched_text".
The topic understood variable is defined by Inter as "parsed_number".
The current item from the multiple object list variable is defined by Inter as
	"multiple_object_item".

Section 5 - Presentation on screen

The command prompt -- documented at var_prompt -- is a text that varies.
The command prompt is ">".

The left hand status line -- documented at var_sl -- is a text that varies.
The right hand status line is a text that varies.

The left hand status line variable is defined by Inter as "left_hand_status_line".
The right hand status line variable is defined by Inter as "right_hand_status_line".

The default status line rule is listed in the for constructing the status line rules.
The default status line rule is defined by Inter as "DEFAULT_STATUS_LINE_R".

The listing group size is a number that varies.
The listing group size variable is defined by Inter as "listing_size".

Section 6 - Language generation

The prior named object is an object that varies.
The prior named object variable is defined by Inter as "prior_named_noun".
An object has a text called list grouping key.

Section 7 - Unindexed Standard Rules variables - Unindexed

The story title, the story author, the story headline, the story genre
and the story description are text variables. [*****]
The release number and the story creation year are number variables. [**]
The story licence, the story copyright, the story origin URL, and the
story rights history are text variables. [****]

The release number is usually 1.
The story headline is usually "An Interactive Fiction".
The story genre is usually "Fiction".

The story title variable is defined by Inter as "Story".

Section SR2/6b - Unindexed Standard Rules variables - Unindexed (for figures language element only)

Figure of cover is the file of cover art ("The cover art.").

Section 8 - Unindexed Standard Rules variables - Unindexed

The I6-nothing-constant is an object that varies.
The I6-nothing-constant variable is defined by Inter as "nothing".

The I6-varying-global is an object that varies.
The I6-varying-global variable is defined by Inter as "nothing".

The item-pushed-between-rooms is an object that varies.
The item-pushed-between-rooms variable is defined by Inter as "move_pushing".

The actor-location is an object that varies. [*]
The actor-location variable is defined by Inter as "actor_location".

The scene being changed is a scene that varies. [*]
The scene being changed variable is defined by Inter as "parameter_value".

Chapter 2 - Rulebooks

Section 1 - The Standard Rulebooks

Turn sequence rules is a nothing based rulebook.
The turn sequence rulebook is accessible to Inter as "TURN_SEQUENCE_RB".

Scene changing rules is a rulebook.
The scene changing rulebook is accessible to Inter as "SCENE_CHANGING_RB".
When play begins is a rulebook.
The when play begins rulebook is accessible to Inter as "WHEN_PLAY_BEGINS_RB".
When play ends is a rulebook.
The when play ends rulebook is accessible to Inter as "WHEN_PLAY_ENDS_RB".
When scene begins is a scene based rulebook.
The when scene begins rulebook is accessible to Inter as "WHEN_SCENE_BEGINS_RB".
When scene ends is a scene based rulebook.
The when scene ends rulebook is accessible to Inter as "WHEN_SCENE_ENDS_RB".
Every turn rules is a rulebook.
The every turn rulebook is accessible to Inter as "EVERY_TURN_RB".

Action-processing rules is a rulebook.
The action-processing rulebook is accessible to Inter as "ACTION_PROCESSING_RB".
The action-processing rulebook has a person called the actor.
Setting action variables is a rulebook.
The setting action variables rulebook is accessible to Inter as "SETTING_ACTION_VARIABLES_RB".
The specific action-processing rules is a rulebook.
The specific action-processing rulebook is accessible to Inter as "SPECIFIC_ACTION_PROCESSING_RB".
The specific action-processing rulebook has a truth state called action in world.
The specific action-processing rulebook has a truth state called action keeping silent.
The specific action-processing rulebook has a rulebook called specific check rulebook.
The specific action-processing rulebook has a rulebook called specific carry out rulebook.
The specific action-processing rulebook has a rulebook called specific report rulebook.
The specific action-processing rulebook has a truth state called within the player's sight.
The player's action awareness rules is a rulebook.
The player's action awareness rulebook is accessible to Inter as "PLAYERS_ACTION_AWARENESS_RB".

Accessibility rules is a rulebook.
The accessibility rulebook is accessible to Inter as "ACCESSIBILITY_RB".
Reaching inside rules is an object-based rulebook.
The reaching inside rulebook is accessible to Inter as "REACHING_INSIDE_RB".
Reaching inside rules have outcomes allow access (success) and deny access (failure).
Reaching outside rules is an object-based rulebook.
The reaching outside rulebook is accessible to Inter as "REACHING_OUTSIDE_RB".
Reaching outside rules have outcomes allow access (success) and deny access (failure).
Visibility rules is a rulebook.
The visibility rulebook is accessible to Inter as "VISIBLE_RB".
Visibility rules have outcomes there is sufficient light (failure) and there is
insufficient light (success).

Persuasion rules is a rulebook.
The persuasion rulebook is accessible to Inter as "PERSUADE_RB".
Persuasion rules have outcomes persuasion succeeds (success) and persuasion fails (failure).
Unsuccessful attempt by is a rulebook.
The unsuccessful attempt by rulebook is accessible to Inter as "UNSUCCESSFUL_ATTEMPT_RB".

Before rules is a rulebook.
The before rulebook is accessible to Inter as "BEFORE_RB".
Instead rules is a rulebook.
The instead rulebook is accessible to Inter as "INSTEAD_RB".
Check rules is a rulebook.
The check rulebook is accessible to Inter as "CHECK_RB".
Carry out rules is a rulebook.
The carry out rulebook is accessible to Inter as "CARRY_OUT_RB".
After rules is a rulebook.
The after rulebook is accessible to Inter as "AFTER_RB".
Report rules is a rulebook.
The report rulebook is accessible to Inter as "REPORT_RB".

The does the player mean rules is a rulebook.
The does the player mean rulebook is accessible to Inter as "DOES_THE_PLAYER_MEAN_RB".
The does the player mean rules have outcomes it is very likely, it is likely, it is possible,
it is unlikely and it is very unlikely.

The multiple action processing rules is a rulebook.
The multiple action processing rulebook is accessible to Inter as "MULTIPLE_ACTION_PROCESSING_RB".

Section 2 - The Standard Rules

The little-used do nothing rule is defined by Inter as "LITTLE_USED_DO_NOTHING_R".

The initial whitespace rule is listed in the after starting the virtual machine rules.
The initial whitespace rule translates into Inter as "INITIAL_WHITESPACE_R".

The update chronological records rule is listed in the after starting the virtual machine rules.
The update chronological records rule translates into Inter as "UPDATE_CHRONOLOGICAL_RECORDS_R".

The position player in model world rule is listed in the after starting the virtual machine rules.
The position player in model world rule translates into Inter as "POSITION_PLAYER_IN_MODEL_R".

The start in the correct scenes rule is listed in the after starting the virtual machine rules.
This is the start in the correct scenes rule:
	follow the scene changing rules.

Startup rule (this is the when play begins stage rule):
	follow the when play begins rulebook.

Startup rule (this is the fix baseline scoring rule):
	now the last notified score is the score.

Startup rule (this is the display banner rule):
	say "[banner text]".

Startup rule (this is the initial room description rule):
	surreptitiously reckon darkness;
	try looking.

A first turn sequence rule (this is the every turn stage rule):
	follow the every turn rules. [5th.]
A first turn sequence rule (this is the early scene changing stage rule):
	follow the scene changing rules. [4th.]
The generate action rule is listed first in the turn sequence rulebook. [3rd.]
This is the declare everything initially unmentioned rule:
	repeat with item running through things:
		now the item is not mentioned.
The declare everything initially unmentioned rule is listed first in the turn sequence rulebook. [2nd.]
The parse command rule is listed first in the turn sequence rulebook. [1st.]

The timed events rule is listed in the turn sequence rulebook.
The advance time rule is listed in the turn sequence rulebook.
The update chronological records rule is listed in the turn sequence rulebook.

A last turn sequence rule (this is the late scene changing stage rule):
	follow the scene changing rules. [3rd from last.]
The adjust light rule is listed last in the turn sequence rulebook. [2nd from last.]
The note object acquisitions rule is listed last in the turn sequence rulebook. [Penultimate.]
The notify score changes rule is listed last in the turn sequence rulebook. [Last.]

This is the notify score changes rule:
	if the score is not the last notified score:
		issue score notification message;
		now the last notified score is the score;

The adjust light rule is defined by Inter as "ADJUST_LIGHT_R" with
	"[It] [are] [if story tense is present tense]now [end if]pitch dark in [here]!" (A).
The advance time rule is defined by Inter as "ADVANCE_TIME_R".
The generate action rule is defined by Inter as "GENERATE_ACTION_R" with
	"(considering the first sixteen objects only)[command clarification break]" (A),
	"Nothing to do!" (B).

The note object acquisitions rule is defined by Inter as "NOTE_OBJECT_ACQUISITIONS_R".
The parse command rule is defined by Inter as "PARSE_COMMAND_R".
The timed events rule is defined by Inter as "TIMED_EVENTS_R".

The when play ends stage rule is listed first in the shutdown rulebook.
The resurrect player if asked rule is listed last in the shutdown rulebook.
The print player's obituary rule is listed last in the shutdown rulebook.
The ask the final question rule is listed last in the shutdown rulebook.

This is the when play ends stage rule: follow the when play ends rulebook.
This is the print player's obituary rule:
	carry out the printing the player's obituary activity.

The resurrect player if asked rule is defined by Inter as "RESURRECT_PLAYER_IF_ASKED_R".
The ask the final question rule is defined by Inter as "ASK_FINAL_QUESTION_R".

The scene change machinery rule is listed last in the scene changing rulebook.

The scene change machinery rule is defined by Inter as "SCENE_CHANGE_MACHINERY_R".

Section 3 - The Entire Game scene

The Entire Game is a scene.
The Entire Game begins when the story has not ended.
The Entire Game ends when the story has ended.

Section 4 - Action processing

The before stage rule is listed first in the action-processing rules. [3rd.]
The set pronouns from items from multiple object lists rule is listed first in the
	action-processing rules. [2nd.]
The announce items from multiple object lists rule is listed first in the
	action-processing rules. [1st.]
The basic visibility rule is listed in the action-processing rules.
The basic tangibility rule is listed in the action-processing rules.
The basic accessibility rule is listed in the action-processing rules.
The carrying requirements rule is listed in the action-processing rules.
The instead stage rule is listed last in the action-processing rules. [4th from last.]
The requested actions require persuasion rule is listed last in the action-processing rules.
The carry out requested actions rule is listed last in the action-processing rules.
The descend to specific action-processing rule is listed last in the action-processing rules.
The end action-processing in success rule is listed last in the action-processing rules. [Last.]

This is the set pronouns from items from multiple object lists rule:
	if the current item from the multiple object list is not nothing,
		set pronouns from the current item from the multiple object list.

This is the announce items from multiple object lists rule:
	if the current item from the multiple object list is not nothing,
		say "[current item from the multiple object list]: [run paragraph on]" (A).

This is the before stage rule:
	abide by dialogue before action choices;
	abide by the before rules.
This is the instead stage rule:
	abide by dialogue instead action choices;
	abide by the instead rules.

This is the end action-processing in success rule: rule succeeds.

This is the basic tangibility rule:
	unless the action makes a request:
		if action requires a touchable noun and the noun is not a thing:
			if an actor listening to a room or an actor smelling a room, continue the action;
			if the actor is the player, say "You must name something more substantial than [the noun]." (A);
			now the reason the action failed is the basic tangibility rule;
			rule fails;
		if action requires a touchable second noun and the second noun is not a thing:
			if the actor is the player, say "You must name something more substantial than [the second noun]." (B);
			now the reason the action failed is the basic tangibility rule;
			rule fails;

The basic accessibility rule is defined by Inter as "BASIC_ACCESSIBILITY_R" with
	"You must name something more substantial." (A).
The basic visibility rule is defined by Inter as "BASIC_VISIBILITY_R" with
	"[It] [are] pitch dark, and [we] [can't see] a thing." (A).
The carrying requirements rule is defined by Inter as "CARRYING_REQUIREMENTS_R".
The requested actions require persuasion rule is defined by Inter as
	"REQUESTED_ACTIONS_REQUIRE_R" with
	 "[The noun] [have] better things to do." (A).
The carry out requested actions rule is defined by Inter as
	"CARRY_OUT_REQUESTED_ACTIONS_R" with
	"[The noun] [are] unable to do that." (A).
The descend to specific action-processing rule is defined by Inter as
"DESCEND_TO_SPECIFIC_ACTION_R".

The work out details of specific action rule is listed first in the specific
action-processing rules.

A specific action-processing rule
	(this is the investigate player's awareness before action rule):
	follow the player's action awareness rules;
	if rule succeeded, now within the player's sight is true;
	otherwise now within the player's sight is false.

A specific action-processing rule (this is the check stage rule):
	anonymously abide by the specific check rulebook.

A specific action-processing rule (this is the carry out stage rule):
	follow the specific carry out rulebook.

A specific action-processing rule (this is the after stage rule):
	if action in world is true:
		abide by the after rules.

A specific action-processing rule
	(this is the investigate player's awareness after action rule):
	if within the player's sight is false:
		follow the player's action awareness rules;
		if rule succeeded, now within the player's sight is true;

A specific action-processing rule (this is the report stage rule):
	if within the player's sight is true and action keeping silent is false,
		follow the specific report rulebook;

The last specific action-processing rule (this is the default action success rule):
	rule succeeds.

The work out details of specific action rule is defined by Inter as
"WORK_OUT_DETAILS_OF_SPECIFIC_R".

A player's action awareness rule
	(this is the player aware of their own actions rule):
	if the player is the actor, rule succeeds.
A player's action awareness rule
	(this is the player aware of actions by visible actors rule):
	if the player is not the actor and the player can see the actor, rule succeeds.
A player's action awareness rule
	(this is the player aware of actions on visible nouns rule):
	if the noun is a thing and the player can see the noun, rule succeeds.
A player's action awareness rule
	(this is the player aware of actions on visible second nouns rule):
	if the second noun is a thing and the player can see the second noun, rule succeeds.

Section 5 - Accessibility

The access through barriers rule is listed last in the accessibility rules.

The access through barriers rule is defined by Inter as
	"ACCESS_THROUGH_BARRIERS_R" with
	"[regarding the noun][Those] [aren't] available." (A).

The can't reach inside rooms rule is listed last in the reaching inside rules. [Penultimate.]
The can't reach inside closed containers rule is listed last in the reaching
inside rules. [Last.]

The can't reach inside closed containers rule is defined by Inter as
	"CANT_REACH_INSIDE_CLOSED_R" with
	"[The noun] [aren't] open." (A).
The can't reach inside rooms rule is defined by Inter as
	"CANT_REACH_INSIDE_ROOMS_R" with
	"[We] [can't] reach into [the noun]." (A).

The can't reach outside closed containers rule is listed last in the reaching outside rules.

The can't reach outside closed containers rule is defined by Inter as
	"CANT_REACH_OUTSIDE_CLOSED_R" with
	"[The noun] [aren't] open." (A).

The can't act in the dark rule is listed last in the visibility rules.

The last visibility rule (this is the can't act in the dark rule): if in darkness, rule succeeds.

Does the player mean taking something which is carried by the player
	(this is the very unlikely to mean taking what's already carried rule):
	it is very unlikely.

Section 6 - Adjectival definitions

A scene can be recurring or non-recurring. A scene is usually non-recurring.
The Entire Game is recurring.

Section 7 - Scene descriptions

A scene has a text called description.
When a scene (called the event) begins (this is the scene description text rule):
	if the description of the event is not "",
		say "[description of the event][paragraph break]".

Section 8 - Command parser errors

A command parser error is a kind of value. The command parser errors are
	didn't understand error,
	only understood as far as error,
	didn't understand that number error,
	can only do that to something animate error,
	can't see any such thing error,
	said too little error,
	aren't holding that error,
	can't use multiple objects error,
	can only use multiple objects error,
	not sure what it refers to error,
	excepted something not included error,
	not a verb I recognise error,
	not something you need to refer to error,
	can't see it at the moment error,
	didn't understand the way that finished error,
	not enough of those available error,
	nothing to do error,
	referred to a determination of scope error,
	noun did not make sense in that context error,
	I beg your pardon error,
	can't again the addressee error,
	comma can't begin error,
	can't see whom to talk to error,
	can't talk to inanimate things error, and
	didn't understand addressee's last name error.

The latest parser error is a command parser error that varies.
The latest parser error variable is defined by Inter as "etype".

Section 9 - Responses for internal rules

The list writer internal rule is defined by Inter as
	"LIST_WRITER_INTERNAL_R" with
	" (" (A),
	")" (B),
	" and " (C),
	"providing light" (D),
	"closed" (E),
	"empty" (F),
	"closed and empty" (G),
	"closed and providing light" (H),
	"empty and providing light" (I),
    "closed, empty[if serial comma option is active],[end if] and providing light" (J),
	"providing light and being worn" (K),
	"being worn" (L),
	"open" (M),
	"open but empty" (N),
	"closed" (O),
	"closed and locked" (P),
	"containing" (Q),
	"on [if the noun is a person]whom[otherwise]which[end if] " (R),
	", on top of [if the noun is a person]whom[otherwise]which[end if] " (S),
	"in [if the noun is a person]whom[otherwise]which[end if] " (T),
	", inside [if the noun is a person]whom[otherwise]which[end if] " (U),
	"[regarding list writer internals][are]" (V),
	"[regarding list writer internals][are] nothing" (W),
	"Nothing" (X),
	"nothing" (Y).

The action processing internal rule is defined by Inter as
	"ACTION_PROCESSING_INTERNAL_R" with
	"[bracket]That command asks to do something outside of play, so it can
    only make sense from you to me. [The noun] cannot be asked to do this.[close
    bracket]" (A),
	"You must name an object." (B),
	"You may not name an object." (C),
	"You must supply a noun." (D),
	"You may not supply a noun." (E),
	"You must name a second object." (F),
	"You may not name a second object." (G),
	"You must supply a second noun." (H),
	"You may not supply a second noun." (I),
	"(Since something dramatic has happened, your list of commands has been
	cut short.)" (J),
	"I didn't understand that instruction." (K).

The parser error internal rule is defined by Inter as
	"PARSER_ERROR_INTERNAL_R" with
	"I didn't understand that sentence." (A),
	"I only understood you as far as wanting to " (B),
	"I only understood you as far as wanting to (go) " (C),
	"I didn't understand that number." (D),
	"[We] [can't] see any such thing." (E),
	"You seem to have said too little!" (F),
	"[We] [aren't] holding that!" (G),
	"You can't use multiple objects with that verb." (H),
	"You can only use multiple objects once on a line." (I),
	"I'm not sure what ['][pronoun i6 dictionary word]['] refers to." (J),
	"[We] [can't] see ['][pronoun i6 dictionary word]['] ([the noun]) at the moment." (K),
	"You excepted something not included anyway!" (L),
	"You can only do that to something animate." (M),
	"That's not a verb I [if American dialect option is
		active]recognize[otherwise]recognise[end if]." (N),
	"That's not something you need to refer to in the course of this game." (O),
	"I didn't understand the way that finished." (P),
	"[if number understood is 0]None[otherwise]Only [number understood in words][end if]
		of those [regarding the number understood][are] available." (Q),
	"That noun did not make sense in this context." (R),
	"To repeat a command like 'frog, jump', just say 'again', not 'frog, again'." (S),
	"You can't begin with a comma." (T),
	"You seem to want to talk to someone, but I can't see whom." (U),
	"You can't talk to [the noun]." (V),
	"To talk to someone, try 'someone, hello' or some such." (W),
	"I beg your pardon?" (X).

The parser nothing error internal rule is defined by Inter as
	"PARSER_N_ERROR_INTERNAL_R" with
	"Nothing to do!" (A),
	"[There] [adapt the verb are from the third person plural] none at all available!" (B),
	"[The noun] [have] nothing." (C),
	"[regarding the noun][Those] [can't] contain things." (D),
	"[The noun] [aren't] open." (E),
	"[The noun] [are] empty." (F).

The darkness name internal rule is defined by Inter as "DARKNESS_NAME_INTERNAL_R" with
	"Darkness" (A).

The parser command internal rule is defined by Inter as
	"PARSER_COMMAND_INTERNAL_R" with
	"Sorry, that can't be corrected." (A),
	"Think nothing of it." (B),
	"'Oops' can only correct a single word." (C),
	"You can hardly repeat that." (D).

The parser clarification internal rule is defined by Inter as
	"PARSER_CLARIF_INTERNAL_R" with
	"Who do you mean, " (A),
	"Which do you mean, " (B),
	"Sorry, you can only have one item here. Which exactly?" (C),
	"Whom do you want [if the noun is not the player][the noun] [end if]to
		[parser command so far]?" (D),
	"What do you want [if the noun is not the player][the noun] [end if]to
		[parser command so far]?" (E),
	"those things" (F),
	"that" (G),
	" or " (H).

The yes or no question internal rule is defined by Inter as
	"YES_OR_NO_QUESTION_INTERNAL_R" with
	"Please answer yes or no." (A).

The pick a number internal rule is defined by Inter as
	"PICK_A_NUMBER_INTERNAL_R" with
	"(Please type an option in the range 1 to [number understood] and press return.)" (A).

The print protagonist internal rule is defined by Inter as
	"PRINT_PROTAGONIST_INTERNAL_R" with
	"[We]" (A),
	"[ourselves]" (B),
	"[our] former self" (C).

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

Part Four - Activities

Section 1 - Responses

Issuing the response text of something -- hidden in RULES command -- -- documented at act_resp -- is an
activity on responses.
The issuing the response text activity is accessible to Inter as "PRINTING_RESPONSE_ACT".

The standard issuing the response text rule is listed last in for issuing the
response text.

The standard issuing the response text rule is defined by Inter as
"STANDARD_RESPONSE_ISSUING_R".

Section 2 - Naming and Listing

Before printing the name of a thing (called the item being printed)
	(this is the make named things mentioned rule):
	if expanding text for comparison purposes, continue the activity;
	now the item being printed is mentioned.

Printing a number of something (documented at act_pan) is an activity.
The printing a number activity is accessible to Inter as "PRINTING_A_NUMBER_OF_ACT".

Rule for printing a number of something (called the item) (this is the standard
	printing a number of something rule):
	say "[listing group size in words] ";
	carry out the printing the plural name activity with the item.
The standard printing a number of something rule is listed last in the for printing
a number rulebook.

Printing room description details of something (hidden in RULES command) (documented at act_details) is an activity.
The printing room description details activity is accessible to Inter as "PRINTING_ROOM_DESC_DETAILS_ACT".

For printing room description details of a container (called the box) when the box is falsely-unoccupied (this is the falsely-unoccupied container room description details rule):
  say text of list writer internal rule response (A); [ " (" ]
  if the box is lit and the location is unlit begin;
    if the box is closed, say text of list writer internal rule response (J); [ "closed, empty[if serial comma option is active],[end if] and providing light" ]
    else say text of list writer internal rule response (I); [ "empty and providing light" ]
  else;
    if the box is closed, say text of list writer internal rule response (E); [ "closed" ]
    else say text of list writer internal rule response (F); [ "empty" ]
  end if;
  say text of list writer internal rule response (B); [ ")" ]

Printing inventory details of something (hidden in RULES command) (documented at act_idetails) is an activity.
The printing inventory details activity is accessible to Inter as "PRINTING_INVENTORY_DETAILS_ACT".


To say the deceitfully empty inventory details of (box - a container):
  let inventory text printed be false;
  if the box is lit begin;
    if the box is worn, say text of list writer internal rule response (K); [ "providing light and being worn" ]
    else say text of list writer internal rule response (D); [ "providing light" ]
    now inventory text printed is true;
  else if the box is worn;
    say text of list writer internal rule response (L); [ "being worn" ]
    now inventory text printed is true;
  end if;
  if the box is openable begin;
    if inventory text printed is true begin;
      if the serial comma option is active, say ",";
      say text of list writer internal rule response (C); [ "and" ]
    end if;
    if the box is open begin;
      say text of list writer internal rule response (N); [ "open but empty" ]
    else; [ it's closed ]
      if the box is locked, say text of list writer internal rule response (P); [ "closed and locked" ]
      else say text of list writer internal rule response (O); [ "closed" ]
      now inventory text printed is true;
    end if;
  else; [ it's not openable ]
    if the box is transparent begin;
      if inventory text printed is true, say text of list writer internal rule response (C); [ "and" ]
      say text of list writer internal rule response (F); [ "empty" ]
      now inventory text printed is true; [ not relevant unless code is added ]
    end if;
  end if;

For printing inventory details of a container (called the box) when the box is falsely-unoccupied (this is the falsely-unoccupied container inventory details rule):
    let the tag be "[the deceitfully empty inventory details of box]";
    if tag is not empty begin;
      say text of list writer internal rule response (A); [ "(" ]
      say tag;
      say text of list writer internal rule response (B); [ ")" ]
    end if;

Listing contents of something (hidden in RULES command) (documented at act_lc) is an activity.
The listing contents activity is accessible to Inter as "LISTING_CONTENTS_ACT".
The standard contents listing rule is listed last in the for listing contents rulebook.
The standard contents listing rule is defined by Inter as "STANDARD_CONTENTS_LISTING_R".
Grouping together something (hidden in RULES command) (documented at act_gt) is an activity.
The grouping together activity is accessible to Inter as "GROUPING_TOGETHER_ACT".


Writing a paragraph about something (documented at act_wpa) is an activity.
The writing a paragraph about activity is accessible to Inter as "WRITING_A_PARAGRAPH_ABOUT_ACT".

Listing nondescript items of something (documented at act_lni) is an activity.
The listing nondescript items activity is accessible to Inter as "LISTING_NONDESCRIPT_ITEMS_ACT".

Printing the name of a dark room (documented at act_darkname) is an activity.
The printing the name of a dark room activity is accessible to Inter as "PRINTING_NAME_OF_DARK_ROOM_ACT".
Printing the description of a dark room (documented at act_darkdesc) is an activity.
The printing the description of a dark room activity is accessible to Inter as "PRINTING_DESC_OF_DARK_ROOM_ACT".
Printing the announcement of darkness (documented at act_nowdark) is an activity.
The printing the announcement of darkness activity is accessible to Inter as "PRINTING_NEWS_OF_DARKNESS_ACT".
Printing the announcement of light (documented at act_nowlight) is an activity.
The printing the announcement of light activity is accessible to Inter as "PRINTING_NEWS_OF_LIGHT_ACT".
Printing a refusal to act in the dark (documented at act_toodark) is an activity.
The printing a refusal to act in the dark activity is accessible to Inter as "REFUSAL_TO_ACT_IN_DARK_ACT".

The look around once light available rule is listed last in for printing the
announcement of light.

This is the look around once light available rule:
	try looking.

Printing the banner text (documented at act_banner) is an activity.
The printing the banner text activity is accessible to Inter as "PRINTING_BANNER_TEXT_ACT".

Section 3 - Command parsing

Reading a command (documented at act_reading) is an activity.
The reading a command activity is accessible to Inter as "READING_A_COMMAND_ACT".
Deciding the scope of something (future action) (documented at act_ds) is an activity.
The deciding the scope activity is accessible to Inter as "DECIDING_SCOPE_ACT".
Deciding the concealed possessions of something (documented at act_con) is an activity.
The deciding the concealed possessions activity is accessible to Inter as "DECIDING_CONCEALED_POSSESS_ACT".
Deciding whether all includes something (future action) (documented at act_all)
	is an activity.
The deciding whether all includes activity is accessible to Inter as "DECIDING_WHETHER_ALL_INC_ACT".
The for deciding whether all includes rules have outcomes it does not (failure) and
	it does (success).
Clarifying the parser's choice of something (future action) (documented at act_clarify)
	is an activity.
The clarifying the parser's choice activity is accessible to Inter as "CLARIFYING_PARSERS_CHOICE_ACT".
Asking which do you mean (future action) (documented at act_which) is an activity.
The asking which do you mean activity is accessible to Inter as "ASKING_WHICH_DO_YOU_MEAN_ACT".
Printing a parser error (documented at act_parsererror) is an activity.
The printing a parser error activity is accessible to Inter as "PRINTING_A_PARSER_ERROR_ACT".
Supplying a missing noun (documented at act_smn) is an activity.
The supplying a missing noun activity is accessible to Inter as "SUPPLYING_A_MISSING_NOUN_ACT".
Supplying a missing second noun (documented at act_smn) is an activity.
The supplying a missing second noun activity is accessible to Inter as "SUPPLYING_A_MISSING_SECOND_ACT".
Implicitly taking something (documented at act_implicitly) is an activity.
The implicitly taking activity is accessible to Inter as "IMPLICITLY_TAKING_ACT".

Rule for deciding whether all includes scenery while an actor taking or taking off or
	removing (this is the exclude scenery from take all rule): it does not.
Rule for deciding whether all includes people while an actor taking or taking off or
	removing (this is the exclude people from take all rule): it does not.
Rule for deciding whether all includes fixed in place things while an actor taking or
	taking off or removing (this is the exclude fixed in place things from
	take all rule): it does not.
Rule for deciding whether all includes things enclosed by the person reaching
	while an actor taking or taking off (this is the exclude indirect possessions from
	take all rule): it does not.
Rule for deciding whether all includes a person while an actor dropping or throwing
	or inserting or putting (this is the exclude people from drop all rule):
	it does not.

Rule for supplying a missing noun while an actor smelling (this is the ambient odour rule):
	now the noun is the touchability ceiling of the player.

Rule for supplying a missing noun while an actor listening (this is the ambient sound rule):
	now the noun is the touchability ceiling of the player.

Rule for supplying a missing noun while an actor going (this is the block vaguely going rule):
	say "You'll have to say which compass direction to go in." (A).

The standard implicit taking rule is listed last in for implicitly taking.

The standard implicit taking rule is defined by Inter as "STANDARD_IMPLICIT_TAKING_R" with
	"(first taking [the noun])[command clarification break]" (A),
	"([the second noun] first taking [the noun])[command clarification break]" (B).

Section 4 - Posthumous activities

Amusing a victorious player (documented at act_amuse) is an activity.
The amusing a victorious player activity is accessible to Inter as "AMUSING_A_VICTORIOUS_PLAYER_ACT".

Printing the player's obituary (documented at act_obit) is an activity.
The printing the player's obituary activity is accessible to Inter as "PRINTING_PLAYERS_OBITUARY_ACT".
The print obituary headline rule is listed last in for printing the player's obituary.
The print final score rule is listed last in for printing the player's obituary.
The display final status line rule is listed last in for printing the player's obituary.

The print obituary headline rule is defined by Inter as "PRINT_OBITUARY_HEADLINE_R"
	with " You have died " (A),
		" You have won " (B),
		" The End " (C).
The print final score rule is defined by Inter as "PRINT_FINAL_SCORE_R".
The display final status line rule is defined by Inter as "DISPLAY_FINAL_STATUS_LINE_R".

Handling the final question is an activity.
The handling the final question activity is accessible to Inter as "DEALING_WITH_FINAL_QUESTION_ACT".

The immediately restart the VM rule is defined by Inter as "IMMEDIATELY_RESTART_VM_R".
The immediately restore saved game rule is defined by Inter as "IMMEDIATELY_RESTORE_SAVED_R".
The immediately quit rule is defined by Inter as "IMMEDIATELY_QUIT_R".
The immediately undo rule is defined by Inter as "IMMEDIATELY_UNDO_R" with
	"The use of 'undo' is forbidden in this story." (A),
	"You can't 'undo' what hasn't been done!" (B),
	"Your interpreter does not provide 'undo'. Sorry!" (C),
	"'Undo' failed. Sorry!" (D),
	"[bracket]Previous turn undone.[close bracket]" (E),
	"'Undo' capacity exhausted. Sorry!" (F).

The print the final question rule is listed in before handling the final question.
The print the final prompt rule is listed in before handling the final question.
The read the final answer rule is listed last in before handling the final question.
The standard respond to final question rule is listed last in for handling the final question.

This is the print the final prompt rule: say "> [run paragraph on]" (A).

The read the final answer rule is defined by Inter as "READ_FINAL_ANSWER_R".

Section 5 - The Final Question

This is the print the final question rule:
	let named options count be 0;
	repeat through the Table of Final Question Options:
		if the only if victorious entry is false or the story has ended finally:
			if there is a final response rule entry
				or the final response activity entry is not empty:
				if there is a final question wording entry, increase named options count by 1;
	if the named options count is less than 1, abide by the immediately quit rule;
	say "Would you like to " (A);
	repeat through the Table of Final Question Options:
		if the only if victorious entry is false or the story has ended finally:
			if there is a final response rule entry
				or the final response activity entry is not empty:
				if there is a final question wording entry:
					say final question wording entry;
					decrease named options count by 1;
					if the named options count is 1:
						if the serial comma option is active, say ",";
						say " or " (B);
					otherwise if the named options count is 0:
						say "?[line break]";
					otherwise:
						say ", ";

This is the standard respond to final question rule:
	repeat through the Table of Final Question Options:
		if the only if victorious entry is false or the story has ended finally:
			if there is a final response rule entry
				or the final response activity entry is not empty:
				if the player's command matches the topic entry:
					if there is a final response rule entry, abide by final response rule entry;
					otherwise carry out the final response activity entry activity;
					rule succeeds;
	say "Please give one of the answers above." (A).

Section 6 - Final question options

Table of Final Question Options
final question wording	only if victorious	topic		final response rule		final response activity
"RESTART"				false				"restart"	immediately restart the VM rule	--
"RESTORE a saved game"	false				"restore"	immediately restore saved game rule	--
"see some suggestions for AMUSING things to do"	true	"amusing"	--	amusing a victorious player
"QUIT"					false				"quit"		immediately quit rule	--
"UNDO the last command"	false				"undo"		immediately undo rule	--

Section 7 - Locale descriptions - Unindexed

Table of Locale Priorities
notable-object (an object)	locale description priority (a number)
--							--
with blank rows for each thing.

To describe locale for (O - object):
	carry out the printing the locale description activity with O.

To set the/-- locale priority of (O - an object) to (N - a number):
	if O is a thing:
		if N is at most 0, now O is mentioned;
		if there is a notable-object of O in the Table of Locale Priorities:
			choose row with a notable-object of O in the Table of Locale Priorities;
			if N is at most 0, blank out the whole row;
			otherwise now the locale description priority entry is N;
		otherwise:
			if N is greater than 0:
				choose a blank row in the Table of Locale Priorities;
				now the notable-object entry is O;
				now the locale description priority entry is N;

Printing the locale description of something (documented at act_pld) is an activity.

The printing the locale description activity is accessible to Inter as
"PRINTING_LOCALE_DESCRIPTION_ACT".

The locale paragraph count is a number that varies.

Before printing the locale description (this is the initialise locale description rule):
	now the locale paragraph count is 0;
	repeat through the Table of Locale Priorities:
		blank out the whole row.

Before printing the locale description (this is the find notable locale objects rule):
	let the domain be the parameter-object;
	carry out the choosing notable locale objects activity with the domain;
	continue the activity.

For printing the locale description (this is the interesting locale paragraphs rule):
	let the domain be the parameter-object;
	sort the Table of Locale Priorities in locale description priority order;
	repeat through the Table of Locale Priorities:
		carry out the printing a locale paragraph about activity with the notable-object entry;
	continue the activity.

For printing the locale description (this is the you-can-also-see rule):
	let the domain be the parameter-object;
	let the mentionable count be 0;
	if the domain is a thing and the domain holds the player and the domain is falsely-unoccupied, continue the activity;
	repeat with item running through things:
		now the item is not marked for listing;
	repeat through the Table of Locale Priorities:
		if the locale description priority entry is greater than 0,
			now the notable-object entry is marked for listing;
		increase the mentionable count by 1;
	if the mentionable count is greater than 0:
		repeat with item running through things:
			if the item is mentioned:
				now the item is not marked for listing;
		begin the listing nondescript items activity with the domain;
		if the number of marked for listing things is 0:
			abandon the listing nondescript items activity with the domain;
		otherwise:
			if handling the listing nondescript items activity with the domain:
				if the domain is the location:
					say "[We] " (A);
				otherwise if the domain is a supporter or the domain is an animal:
					say "On [the domain] [we] " (B);
				otherwise:
					say "In [the domain] [we] " (C);
				if the locale paragraph count is greater than 0:
					say "[regarding the player][can] also see " (D);
				otherwise:
					say "[regarding the player][can] see " (E);
				let the common holder be nothing;
				let contents form of list be true;
				repeat with list item running through marked for listing things:
					if the holder of the list item is not the common holder:
						if the common holder is nothing,
							now the common holder is the holder of the list item;
						otherwise now contents form of list is false;
					if the list item is mentioned, now the list item is not marked for listing;
				filter list recursion to unmentioned things;
				if contents form of list is true and the common holder is not nothing,
					list the contents of the common holder, as a sentence, including contents,
						giving brief inventory information, tersely, not listing
						concealed items, listing marked items only;
				otherwise say "[a list of marked for listing things including contents]";
				if the domain is the location, say " [here]" (F);
				say ".[paragraph break]";
				unfilter list recursion;
			end the listing nondescript items activity with the domain;
	continue the activity.

Choosing notable locale objects of something (documented at act_cnlo) is an activity.
The choosing notable locale objects activity is accessible to Inter as "CHOOSING_NOTABLE_LOCALE_OBJ_ACT".

For choosing notable locale objects (this is the standard notable locale objects rule):
	let the domain be the parameter-object;
	let the held item be the first thing held by the domain;
	while the held item is a thing:
		set the locale priority of the held item to 5;
		now the held item is the next thing held after the held item;
	continue the activity.

Printing a locale paragraph about something (documented at act_plp) is an activity.
The printing a locale paragraph about activity is accessible to Inter as "PRINTING_LOCALE_PARAGRAPH_ACT".

For printing a locale paragraph about a thing (called the item)
	(this is the don't mention player's supporter in room descriptions rule):
	if the item encloses the player, set the locale priority of the item to 0;
	continue the activity.

For printing a locale paragraph about a thing (called the item)
	(this is the don't mention scenery in room descriptions rule):
	if the item is scenery, set the locale priority of the item to 0;
	continue the activity.

For printing a locale paragraph about a thing (called the item)
	(this is the don't mention undescribed items in room descriptions rule):
	if the item is undescribed:
		set the locale priority of the item to 0;
	continue the activity.

For printing a locale paragraph about a thing (called the item)
	(this is the set pronouns from items in room descriptions rule):
	if the item is not mentioned, set pronouns from the item;
	continue the activity.

For printing a locale paragraph about a thing (called the item)
	(this is the offer items to writing a paragraph about rule):
	if the item is not mentioned:
		if a paragraph break is pending, say "[conditional paragraph break]";
		carry out the writing a paragraph about activity with the item;
		if a paragraph break is pending:
			increase the locale paragraph count by 1;
			now the item is mentioned;
			say "[conditional paragraph break]";
	continue the activity.

For printing a locale paragraph about a thing (called the item)
	(this is the use initial appearance in room descriptions rule):
	if the item is not mentioned:
		if the item provides the property initial appearance and the
			item is not handled and the initial appearance of the item is
			not "":
			increase the locale paragraph count by 1;
			say "[initial appearance of the item]";
			say "[paragraph break]";
			if a locale-supportable thing is on the item:
				repeat with possibility running through things on the item:
					now the possibility is marked for listing;
					if the possibility is mentioned:
						now the possibility is not marked for listing;
				say "On [the item] " (A);
				list the contents of the item, as a sentence, including contents,
					giving brief inventory information, tersely, not listing
					concealed items, prefacing with is/are, listing marked items only;
				say ".[paragraph break]";
			now the item is mentioned;
	continue the activity.

For printing a locale paragraph about a supporter (called the tabletop)
	(this is the initial appearance on supporters rule):
	repeat with item running through not handled things on the tabletop which
		provide the property initial appearance:
		if the item is not a person and the initial appearance of the item is not ""
			and the item is not undescribed:
			now the item is mentioned;
			say initial appearance of the item;
			say paragraph break;
	continue the activity.

Definition: a thing (called the item) is locale-supportable if the item is not
scenery and the item is not mentioned and the item is not undescribed.

For printing a locale paragraph about a thing (called the platform)
	(this is the describe what's on scenery supporters in room descriptions rule):
    if the platform is not a scenery supporter that does not enclose the player, continue the activity;
    let print a paragraph be false;
    let item be the first thing held by the platform;
    while item is not nothing begin;
      if the item is not scenery and the item is described and the platform does not conceal the item begin;
        if the item is mentioned begin;
          now the item is not marked for listing;
        else;
          now the item is marked for listing;
          now print a paragraph is true;
        end if;
      end if;
      now the item is the next thing held after the item;
    end while;
    if print a paragraph is true begin;
      set pronouns from the platform;
      increase the locale paragraph count by 1;
      say "On [the platform] " (A);
      list the contents of the platform, as a sentence, including contents,
        giving brief inventory information, tersely, not listing
        concealed items, prefacing with is/are, listing marked items only;
      say ".[paragraph break]";
    end if;
    continue the activity

For printing a locale paragraph about a thing (called the item)
	(this is the describe what's on mentioned supporters in room descriptions rule):
	if the item is mentioned and the item is not undescribed and the item is
		not scenery and the item does not enclose the player:
		if a locale-supportable thing is on the item:
			set pronouns from the item;
			repeat with possibility running through things on the item:
				now the possibility is marked for listing;
				if the possibility is mentioned:
					now the possibility is not marked for listing;
			increase the locale paragraph count by 1;
			say "On [the item] " (A);
			list the contents of the item, as a sentence, including contents,
				giving brief inventory information, tersely, not listing
				concealed items, prefacing with is/are, listing marked items only;
			say ".[paragraph break]";
	continue the activity.


Part Five - Actions

Section 1 - Verbs needed for adaptive text

To achieve is a verb. To appreciate is a verb. To arrive is a verb. To care is a verb.
To close is a verb. To die is a verb. To discover is a verb. To drop is a verb.
To eat is a verb. To feel is a verb. To find is a verb. To get is a verb.
To give is a verb. To go is a verb. To happen is a verb. To hear is a verb.
To jump is a verb. To lack is a verb. To lead is a verb. To like is a verb.
To listen is a verb. To lock is a verb. To look is a verb. To need is a verb.
To open is a verb. To pass is a verb. To pick is a verb. To provoke is a verb.
To pull is a verb. To push is a verb. To put is a verb. To rub is a verb.
To say is a verb. To search is a verb. To see is a verb. To seem is a verb.
To set is a verb. To smell is a verb. To sniff is a verb. To squeeze is a verb.
To switch is a verb. To take is a verb. To talk is a verb. To taste is a verb.
To touch is a verb. To turn is a verb. To wait is a verb. To wave is a verb.
To win is a verb.

Section 2 - Standard actions concerning the actor's possessions

Taking inventory is an action applying to nothing.
The taking inventory action is accessible to Inter as "Inv".

The specification of the taking inventory action is "Taking an inventory of
one's immediate possessions: the things being carried, either directly or in
any containers being carried. When the player performs this action, either
the inventory listing, or else a special message if nothing is being carried
or worn, is printed during the carry out rules: nothing happens at the report
stage. The opposite happens for other people performing the action: nothing
happens during carry out, but a report such as 'Mr X looks through his
possessions.' is produced (provided Mr X is visible)."

Carry out taking inventory (this is the print empty inventory rule):
	if the first thing held by the player is nothing,
		say "[We] [are] carrying nothing." (A) instead.

Carry out taking inventory (this is the print standard inventory rule):
	say "[We] [are] carrying:[line break]" (A);
	now all things enclosed by the player are unmarked for listing;
	now all things held by the player are marked for listing;
	list the contents of the player, with newlines, indented, giving inventory information, with extra indentation, listing marked items only, not listing concealed items, including contents.

Report an actor taking inventory (this is the report other people taking
	inventory rule):
	if the actor is not the player and the action is not silent:
		say "[The actor] [look] through [their] possessions." (A);

Taking is an action applying to one thing.
The taking action is accessible to Inter as "Take".

The specification of the taking action is "The taking action is the only way
an action in the Standard Rules can cause something to be carried by an actor.
It is very simple in operation (the entire carry out stage consists only of
'now the actor carries the noun') but many checks must be performed before it
can be allowed to happen."

Check an actor taking (this is the can't take yourself rule):
	if the actor is the noun:
		if the actor is the player, say "[We] [are] always self-possessed." (A);
		stop the action.

Check an actor taking (this is the can't take other people rule):
	if the noun is a person:
		if the actor is the player, say "[We] [don't] suppose [the noun] [would care] for that." (A);
		stop the action.

Check an actor taking (this is the can't take component parts rule):
	if the noun is part of something (called the whole):
		if the actor is the player:
			say "[regarding the noun][Those] [seem] to be a part of [the whole]." (A);
		stop the action.

Check an actor taking (this is the can't take people's possessions rule):
	let the local ceiling be the common ancestor of the actor with the noun;
	let the owner be the not-counting-parts holder of the noun;
	while the owner is not nothing and the owner is not the local ceiling:
		if the owner is a person:
			if the actor is the player:
				say "[regarding the noun][Those] [seem] to belong to [the owner]." (A);
			stop the action;
		let the owner be the not-counting-parts holder of the owner;

Check an actor taking (this is the can't take what you're inside rule):
	let the local ceiling be the common ancestor of the actor with the noun;
	if the local ceiling is the noun:
		if the actor is the player:
			say "[We] [would have] to get
				[if noun is a supporter]off[otherwise]out of[end if] [the noun] first." (A);
		stop the action.

Check an actor taking (this is the can't take what's already taken rule):
	if the actor is carrying the noun or the actor is wearing the noun:
		if the actor is the player:
			say "[We] already [have] [regarding the noun][those]." (A);
		stop the action.

Check an actor taking (this is the can't take scenery rule):
	if the noun is scenery:
		if the actor is the player:
			say "[regarding the noun][They're] hardly portable." (A);
		stop the action.

Check an actor taking (this is the can't take what's fixed in place rule):
	if the noun is fixed in place:
		if the actor is the player:
			say "[regarding the noun][They're] fixed in place." (A);
		stop the action.

Check an actor taking (this is the use player's holdall to avoid exceeding
	carrying capacity rule):
	if the number of things carried by the actor is at least the
		carrying capacity of the actor:
		if the actor is holding a player's holdall (called the current working sack):
			let the transferred item be nothing;
			repeat with the possible item running through things carried by
				the actor:
				if the possible item is not lit and the possible item is not
					the current working sack, let the transferred item be the possible item;
			if the transferred item is not nothing:
				if the actor is the player:
					say "(putting [the transferred item] into [the current working sack]
						to make room)[command clarification break]" (A);
				silently try the actor trying inserting the transferred item
					into the current working sack;
				if the transferred item is not in the current working sack:
					stop the action.

Check an actor taking (this is the can't exceed carrying capacity rule):
	if the number of things carried by the actor is at least the
		carrying capacity of the actor:
		if the actor is the player:
			say "[We]['re] carrying too many things already." (A);
		stop the action.

Carry out an actor taking (this is the standard taking rule):
	now the actor carries the noun;
	if the actor is the player, now the noun is handled.

Report an actor taking (this is the standard report taking rule):
	if the action is not silent:
		if the actor is the player:
			say "Taken." (A);
		otherwise:
			say "[The actor] [pick] up [the noun]." (B).

Removing it from is an action applying to two things.
The removing it from action is accessible to Inter as "Remove".

The specification of the removing it from action is "Removing is not really
an action in its own right. Whereas there are many ways to put something down
(on the floor, on top of something, inside something else, giving it to
somebody else, and so on), Inform has only one way to take something: the
taking action. Removing exists only to provide some nicely worded replies
to impossible requests, and in all sensible cases is converted into taking.
Because of this, it's usually a bad idea to write rules about removing:
if you write a rule such as 'Instead of removing the key, ...' then it
won't apply if the player simply types TAKE KEY instead. The safe way to
do this is to write a rule about taking, which covers all possibilities."

Check an actor removing something from (this is the can't remove what's not inside rule):
	if the holder of the noun is not the second noun:
		if the actor is the player:
			say "But [regarding the noun][they] [aren't] there [now]." (A);
		stop the action.

Check an actor removing something from (this is the can't remove from people rule):
	let the owner be the holder of the noun;
	if the owner is a person:
		if the owner is the actor, convert to the taking off action on the noun;
		if the actor is the player:
			say "[regarding the noun][Those] [seem] to belong to [the owner]." (A);
		stop the action.

Check an actor removing something from (this is the convert remove to take rule):
	convert to the taking action on the noun.

The can't take component parts rule is listed before the can't remove what's not
inside rule in the check removing it from rules.

Dropping is an action applying to one thing.
The dropping action is accessible to Inter as "Drop".

The specification of the dropping action is "Dropping is one of five actions
by which an actor can get rid of something carried: the others are inserting
(into a container), putting (onto a supporter), giving (to someone else) and
eating. Dropping means dropping onto the actor's current floor, which is
usually the floor of a room - but might be the inside of a box if the actor
is also inside that box, and so on.

The can't drop clothes being worn rule silently tries the taking off action
on any clothing being dropped: unlisting this rule removes both this behaviour
and also the requirement that clothes cannot simply be dropped."

Check an actor dropping (this is the can't drop yourself rule):
	if the noun is the actor:
		if the actor is the player:
			say "[We] [lack] the dexterity." (A);
		stop the action.

Check an actor dropping something which is part of the actor (this is the
	can't drop body parts rule):
	if the actor is the player:
		say "[We] [can't drop] part of [ourselves]." (A);
	stop the action.

Check an actor dropping (this is the can't drop what's already dropped rule):
	if the noun is in the holder of the actor:
		if the actor is the player:
			say "[The noun] [are] already [here]." (A);
		stop the action.

Check an actor dropping (this is the can't drop what's not held rule):
	if the actor is carrying the noun, continue the action;
	if the actor is wearing the noun, continue the action;
	if the actor is the player:
		say "[We] [haven't] got [regarding the noun][those]." (A);
	stop the action.

Check an actor dropping (this is the can't drop clothes being worn rule):
	if the actor is wearing the noun:
		if the actor is the player:
			say "(first taking [the noun] off)[command clarification break]" (A);
		silently try the actor trying taking off the noun;
		if the actor is wearing the noun, stop the action;

Check an actor dropping (this is the can't drop if this exceeds carrying
	capacity rule):
	let the receptacle be the holder of the actor;
	if the receptacle is a room, continue the action; [room floors have infinite capacity]
	if the receptacle provides the property carrying capacity:
		if the receptacle is a supporter:
			if the number of things on the receptacle is at least the carrying
				capacity of the receptacle:
				if the actor is the player:
					now the prior named object is nothing;
					say "[There] [are] no more room on [the receptacle]." (A);
				stop the action;
		otherwise if the receptacle is a container:
			if the number of things in the receptacle is at least the carrying
				capacity of the receptacle:
				if the actor is the player:
					now the prior named object is nothing;
					say "[There] [are] no more room in [the receptacle]." (B);
				stop the action;

Carry out an actor dropping (this is the standard dropping rule):
	now the noun is held by the holder of the actor.

Report an actor dropping (this is the standard report dropping rule):
	if the action is not silent:
	 	if the actor is the player:
			say "Dropped." (A);
		otherwise:
			say "[The actor] [put] down [the noun]." (B);

Putting it on is an action applying to two things.
The putting it on action is accessible to Inter as "PutOn".

The specification of the putting it on action is "By this action, an actor puts
something they are holding on top of a supporter: for instance, putting an apple
on a table."

Check an actor putting something on (this is the convert put to drop where possible rule):
	if the second noun is down or the actor is on the second noun,
		convert to the dropping action on the noun.

Check an actor putting something on (this is the can't put what's not held rule):
	if the actor is carrying the noun, continue the action;
	if the actor is wearing the noun, continue the action;
	carry out the implicitly taking activity with the noun;
	if the actor is carrying the noun, continue the action;
	stop the action.

Check an actor putting something on (this is the can't put something on itself rule):
	let the noun-CPC be the component parts core of the noun;
	let the second-CPC be the component parts core of the second noun;
	let the transfer ceiling be the common ancestor of the noun-CPC with the second-CPC;
	if the transfer ceiling is the noun-CPC:
		if the actor is the player:
			say "[We] [can't put] something on top of itself." (A);
		stop the action.

Check an actor putting something on (this is the can't put onto what's not a supporter rule):
	if the second noun is not a supporter:
		if the actor is the player:
			say "Putting things on [the second noun] [would achieve] nothing." (A);
		stop the action.

Check an actor putting something on (this is the can't put clothes being worn rule):
	if the actor is wearing the noun:
		if the actor is the player:
			say "(first taking [regarding the noun][them] off)[command clarification break]" (A);
		silently try the actor trying taking off the noun;
		if the actor is wearing the noun, stop the action.

Check an actor putting something on (this is the can't put if this exceeds
	carrying capacity rule):
	if the second noun provides the property carrying capacity:
		if the number of things on the second noun is at least the carrying capacity
			of the second noun:
			if the actor is the player:
				say "[There] [are] no more room on [the second noun]." (A);
			stop the action.

Carry out an actor putting something on (this is the standard putting rule):
	now the noun is on the second noun.

Report an actor putting something on (this is the concise report putting rule):
	if the action is not silent:
		if the actor is the player and the I6 parser is running multiple actions:
			say "Done." (A);
			stop the action;
	continue the action.

Report an actor putting something on (this is the standard report putting rule):
	if the action is not silent:
		say "[The actor] [put] [the noun] on [the second noun]." (A).

Inserting it into is an action applying to two things.
The inserting it into action is accessible to Inter as "Insert".

The specification of the inserting it into action is "By this action, an actor puts
something they are holding into a container: for instance, putting a coin into a
collection box."


Check an actor inserting something into (this is the convert insert to drop where
	possible rule):
	if the second noun is down or the actor is in the second noun,
		convert to the dropping action on the noun.

Check an actor inserting something into (this is the can't insert what's already inserted rule):
	if the noun is in the second noun:
		if the actor is the player:
			say "[The noun] [are] already there." (A);
		stop the action.

Check an actor inserting something into (this is the can't insert something into itself rule):
	let the noun-CPC be the component parts core of the noun;
	let the second-CPC be the component parts core of the second noun;
	let the transfer ceiling be the common ancestor of the noun-CPC with the second-CPC;
	if the transfer ceiling is the noun-CPC:
		if the actor is the player:
			say "[We] [can't put] something inside itself." (A);
		stop the action.

Check an actor inserting something into (this is the can't insert what's not held rule):
	if the actor is carrying the noun, continue the action;
	if the actor is wearing the noun, continue the action;
	carry out the implicitly taking activity with the noun;
	if the actor is carrying the noun, continue the action;
	stop the action.

Check an actor inserting something into (this is the can't insert into closed containers rule):
	if the second noun is a closed container:
		if the actor is the player:
			say "[The second noun] [are] closed." (A);
		stop the action.

Check an actor inserting something into (this is the can't insert into what's not a
	container rule):
	if the second noun is not a container:
		if the actor is the player:
			say "[regarding the second noun][Those] [can't contain] things." (A);
		stop the action.

Check an actor inserting something into (this is the can't insert clothes being worn rule):
	if the actor is wearing the noun:
		if the actor is the player:
			say "(first taking [regarding the noun][them] off)[command clarification break]" (A);
		silently try the actor trying taking off the noun;
		if the actor is wearing the noun, stop the action;

Check an actor inserting something into (this is the can't insert if this exceeds
	carrying capacity rule):
	if the second noun provides the property carrying capacity:
		if the number of things in the second noun is at least the carrying capacity
		of the second noun:
			if the actor is the player:
				now the prior named object is nothing;
				say "[There] [are] no more room in [the second noun]." (A);
			stop the action.

Carry out an actor inserting something into (this is the standard inserting rule):
	now the noun is in the second noun.

Report an actor inserting something into (this is the concise report inserting rule):
	if the action is not silent:
		if the actor is the player and the I6 parser is running multiple actions:
			say "Done." (A);
			stop the action;
	continue the action.

Report an actor inserting something into (this is the standard report inserting rule):
	if the action is not silent:
		say "[The actor] [put] [the noun] into [the second noun]." (A).

Eating is an action applying to one thing.
The eating action is accessible to Inter as "Eat".

The specification of the eating action is "Eating is the only one of the
built-in actions which can, in effect, destroy something: the carry out
rule removes what's being eaten from play, and nothing in the Standard
Rules can then get at it again.

Note that, uncontroversially, one can only eat things with the 'edible'
either/or property. Until 2011, the action also required that the foodstuff
had to be carried by the eater, which meant that a player standing next
to a bush with berries who typed EAT BERRIES would force a '(first taking
the berries)' action. This is no longer true. Taking is now only forced if
the foodstuff is portable."

Check an actor eating (this is the can't eat unless edible rule):
	if the noun is not a thing or the noun is not edible:
		if the actor is the player:
			say "[regarding the noun][They're] plainly inedible." (A);
		stop the action.

Check an actor eating (this is the can't eat clothing without removing it first rule):
	if the actor is wearing the noun:
		if the actor is the player:
			say "(first taking [the noun] off)[command clarification break]" (A);
		try the actor trying taking off the noun;
		if the actor is wearing the noun, stop the action.

Check an actor eating (this is the can't eat other people's food rule):
	if the actor does not hold the noun and the noun is enclosed by a person:
		let the owner be the holder of the noun;
		while the owner is not a person:
			now the owner is the holder of the owner;
		if the owner is not the actor:
			if the actor is the player and the action is not silent:
				say "[The owner] [might not appreciate] that." (A);
			stop the action;

Check an actor eating (this is the can't eat portable food without carrying it rule):
	if the noun is portable and the actor is not carrying the noun:
		carry out the implicitly taking activity with the noun;
		if the actor is not carrying the noun, stop the action.

Carry out an actor eating (this is the standard eating rule):
	now the noun is nowhere.

Report an actor eating (this is the standard report eating rule):
	if the action is not silent:
		if the actor is the player:
			say "[We] [eat] [the noun]. Not bad." (A);
		otherwise:
			say "[The actor] [eat] [the noun]." (B).

Section 3 - Standard actions which move the actor

Going is an action applying to one visible thing.
The going action is accessible to Inter as "Go".

The specification of the going action is "This is the action which allows people
to move from one room to another, using whatever map connections and doors are
to hand. The Standard Rules are written so that the noun can be either a
direction or a door in the location of the actor: while the player's commands
only lead to going actions with directions as nouns, going actions can also
happen as a result of entering actions, and then the noun can indeed be
a door."

The going action has a room called the room gone from (matched as "from").
The going action has an object called the room gone to (matched as "to").
The going action has an object called the door gone through (matched as "through").
The going action has an object called the vehicle gone by (matched as "by").
The going action has an object called the thing gone with (matched as "with").

Rule for setting action variables for going (this is the standard set going variables rule):
	now the thing gone with is the item-pushed-between-rooms;
	now the room gone from is the location of the actor;
	if the actor is in an enterable vehicle (called the carriage),
		now the vehicle gone by is the carriage;
	let the target be nothing;
	if the noun is a direction:
		let direction D be the noun;
		let the target be the room-or-door direction D from the room gone from;
	otherwise:
		if the noun is a door, let the target be the noun;
	if the target is a door:
		now the door gone through is the target;
		now the target is the other side of the target from the room gone from;
	now the room gone to is the target.

Check an actor going when the actor is on a supporter (called the chaise)
	(this is the stand up before going rule):
	if the actor is the player:
		say "(first getting off [the chaise])[command clarification break]" (A);
	silently try the actor exiting.

Check an actor going (this is the can't travel in what's not a vehicle rule):
	let nonvehicle be the holder of the actor;
	if nonvehicle is the room gone from, continue the action;
	if nonvehicle is the vehicle gone by, continue the action;
	if the actor is the player:
		if nonvehicle is a supporter:
			say "[We] [would have] to get off [the nonvehicle] first." (A);
		otherwise:
 			say "[We] [would have] to get out of [the nonvehicle] first." (B);
	stop the action.

Check an actor going (this is the can't go through undescribed doors rule):
	if the door gone through is not nothing and the door gone through is undescribed:
		if the actor is the player:
			say "[We] [can't go] that way." (A);
		stop the action.

Check an actor going (this is the can't go through closed doors rule):
	if the door gone through is not nothing and the door gone through is closed:
		if the actor is the player:
			say "(first opening [the door gone through])[command clarification break]" (A);
		silently try the actor opening the door gone through;
		if the door gone through is open, continue the action;
		stop the action.

Check an actor going (this is the determine map connection rule):
	let the target be nothing;
	if the noun is a direction:
		let direction D be the noun;
		let the target be the room-or-door direction D from the room gone from;
	otherwise:
		if the noun is a door, let the target be the noun;
	if the target is a door:
		now the target is the other side of the target from the room gone from;
	now the room gone to is the target.

Check an actor going (this is the can't go that way rule):
	if the room gone to is nothing:
		if the door gone through is nothing:
			if the actor is the player:
				say "[We] [can't go] that way." (A);
			stop the action;
		if the actor is the player:
			say "[We] [can't], since [the door gone through] [lead] nowhere." (B);
		stop the action.

Carry out an actor going (this is the move player and vehicle rule):
	if the vehicle gone by is nothing,
		surreptitiously move the actor to the room gone to during going;
	otherwise
		surreptitiously move the vehicle gone by to the room gone to during going;
	if the location is not the location of the player:
		now the location is the location of the player.

Carry out an actor going (this is the move floating objects rule):
	if the actor is the player or the player is within the vehicle gone by
		or the player is within the thing gone with:
		update backdrop positions.

Carry out an actor going (this is the check light in new location rule):
	if the actor is the player or the player is within the vehicle gone by
		or the player is within the thing gone with:
		surreptitiously reckon darkness.

Report an actor going (this is the describe room gone into rule):
	if the player is the actor:
		if the action is not silent:
			produce a room description with going spacing conventions;
	otherwise:
		if the noun is a direction:
			if the location is the room gone from or the player is within the
				vehicle gone by or the player is within the thing gone with:
				if the room gone from is the room gone to:
					continue the action;
				otherwise:
					if the noun is up:
						say "[The actor] [go] up" (A);
					otherwise if the noun is down:
						say "[The actor] [go] down" (B);
					otherwise:
						say "[The actor] [go] [noun]" (C);
			otherwise:
				let the back way be the opposite of the noun;
				if the location is the room gone to:
					let the room back the other way be the room back way from the
						location;
					let the room normally this way be the room noun from the
						room gone from;
					if the room back the other way is the room gone from or
						the room back the other way is the room normally this way:
						if the back way is up:
							say "[The actor] [arrive] from above" (D);
						otherwise if the back way is down:
							say "[The actor] [arrive] from below" (E);
						otherwise:
							say "[The actor] [arrive] from [the back way]" (F);
					otherwise:
						say "[The actor] [arrive]" (G);
				otherwise:
					if the back way is up:
						say "[The actor] [arrive] at [the room gone to] from above" (H);
					otherwise if the back way is down:
						say "[The actor] [arrive] at [the room gone to] from below" (I);
					otherwise:
						say "[The actor] [arrive] at [the room gone to] from [the back way]" (J);
		otherwise if the location is the room gone from:
			say "[The actor] [go] through [the noun]" (K);
		otherwise:
			say "[The actor] [arrive] from [the noun]" (L);
		if the vehicle gone by is not nothing:
			say " ";
			if the vehicle gone by is a supporter:
				say "on [the vehicle gone by]" (M);
			otherwise:
				say "in [the vehicle gone by]" (N);
		if the thing gone with is not nothing:
			if the player is within the thing gone with:
				say ", pushing [the thing gone with] in front, and [us] along too" (O);
			otherwise if the player is within the vehicle gone by:
				say ", pushing [the thing gone with] in front" (P);
			otherwise if the location is the room gone from:
				say ", pushing [the thing gone with] away" (Q);
			otherwise:
				say ", pushing [the thing gone with] in" (R);
		if the player is within the vehicle gone by and the player is not
			within the thing gone with:
			say ", taking [us] along" (S);
			say ".";
			try looking;
			continue the action;
		say ".";

Entering is an action applying to one thing.
The entering action is accessible to Inter as "Enter".

The specification of the entering action is "Whereas the going action allows
people to move from one location to another in the model world, the entering
action is for movement inside a location: for instance, climbing into a cage
or sitting on a couch. (Entering is not allowed to change location, so any
attempt to enter a door is converted into a going action.) What makes
entering trickier than it looks is that the player may try to enter an
object which is itself inside, or part of, something else, which might in
turn be... and so on. To preserve realism, the implicitly pass through other
barriers rule automatically generates entering and exiting actions needed
to pass between anything which might be in the way: for instance, in a
room with two open cages, an actor in cage A who tries entering cage B first
has to perform an exiting action."

Rule for supplying a missing noun while entering (this is the find what to enter
rule):
	if something enterable (called the box) is in the location,
		now the noun is the box;
	otherwise continue the activity.

The find what to enter rule is listed last in the for supplying a missing noun
rulebook.

Check an actor entering (this is the convert enter door into go rule):
	if the noun is a door, convert to the going action on the noun.

Check an actor entering (this is the convert enter compass direction into go rule):
	if the noun is a direction, convert to the going action on the noun.

Check an actor entering (this is the can't enter what's already entered rule):
	if the actor is the noun, make no decision;
	let the local ceiling be the common ancestor of the actor with the noun;
	if the local ceiling is the noun:
		if the player is the actor:
			if the noun is a supporter:
				say "But [we]['re] already on [the noun]." (A);
			otherwise:
				say "But [we]['re] already in [the noun]." (B);
		stop the action.

Check an actor entering (this is the can't enter what's not enterable rule):
	if the noun is not enterable:
		if the player is the actor:
			if the player's command includes "stand":
				say "[regarding the noun][They're] not something [we] [can] stand on." (A);
			otherwise if the player's command includes "sit":
				say "[regarding the noun][They're] not something [we] [can] sit down on." (B);
			otherwise if the player's command includes "lie":
				say "[regarding the noun][They're] not something [we] [can] lie down on." (C);
			otherwise:
				say "[regarding the noun][They're] not something [we] [can] enter." (D);
		stop the action.

Check an actor entering (this is the can't enter closed containers rule):
	if the noun is a closed container:
		if the player is the actor:
			say "[We] [can't get] into the closed [noun]." (A);
		stop the action.

Check an actor entering (this is the can't enter if this exceeds carrying
	capacity rule):
	if the noun provides the property carrying capacity:
		if the noun is a supporter:
			if the number of things on the noun is at least the carrying
				capacity of the noun:
				if the actor is the player:
					now the prior named object is nothing;
					say "[There] [are] no more room on [the noun]." (A);
				stop the action;
		otherwise if the noun is a container:
			if the number of things in the noun is at least the carrying
				capacity of the noun:
				if the actor is the player:
					now the prior named object is nothing;
					say "[There] [are] no more room in [the noun]." (B);
				stop the action;

Check an actor entering (this is the can't enter something carried rule):
	let the local ceiling be the common ancestor of the actor with the noun;
	if the local ceiling is the actor:
		if the player is the actor:
			say "[We] [can] only get into something free-standing." (A);
		stop the action.

Check an actor entering (this is the implicitly pass through other barriers rule):
	if the holder of the actor is the holder of the noun, continue the action;
	let the local ceiling be the common ancestor of the actor with the noun;
	while the holder of the actor is not the local ceiling:
		let the current home be the holder of the actor;
		if the player is the actor:
			if the current home is a supporter or the current home is an animal:
				say "(getting off [the current home])[command clarification break]" (A);
			otherwise:
				say "(getting out of [the current home])[command clarification break]" (B);
		silently try the actor trying exiting;
		if the holder of the actor is the current home, stop the action;
	if the holder of the actor is the noun, stop the action;
	if the holder of the actor is the holder of the noun, continue the action;
	let the target be the holder of the noun;
	if the noun is part of the target, let the target be the holder of the target;
	while the target is a thing:
		if the holder of the target is the local ceiling:
			if the player is the actor:
				if the target is a supporter:
					say "(getting onto [the target])[command clarification break]" (C);
				otherwise if the target is a container:
					say "(getting into [the target])[command clarification break]" (D);
				otherwise:
					say "(entering [the target])[command clarification break]" (E);
			silently try the actor trying entering the target;
			if the holder of the actor is not the target, stop the action;
			convert to the entering action on the noun;
			continue the action;
		let the target be the holder of the target;

Carry out an actor entering (this is the standard entering rule):
	surreptitiously move the actor to the noun.

Report an actor entering (this is the standard report entering rule):
	if the actor is the player:
		if the action is not silent:
			if the noun is a supporter:
				say "[We] [get] onto [the noun]." (A);
			otherwise:
				say "[We] [get] into [the noun]." (B);
	otherwise if the noun is a container:
		say "[The actor] [get] into [the noun]." (C);
	otherwise:
		say "[The actor] [get] onto [the noun]." (D);
	continue the action.

Report an actor entering (this is the describe contents entered into rule):
	if the actor is the player, describe locale for the noun.

Exiting is an action applying to nothing.
The exiting action is accessible to Inter as "Exit".
The exiting action has an object called the container exited from (matched as "from").

The specification of the exiting action is "Whereas the going action allows
people to move from one location to another in the model world, and the
entering action is for movement deeper inside the objects in a location,
the exiting action is for movement back out towards the main floor area.
Climbing out of a cupboard, for instance, is an exiting action. Exiting
when already in the main floor area of a room with a map connection to
the outside is converted to a going action. Finally, note that whereas
entering works for either containers or supporters, exiting is purely for
getting oneself out of containers: if the actor is on top of a supporter
instead, an exiting action is converted to the getting off action."

Setting action variables for exiting (this is the standard set exiting variables rule):
	now the container exited from is the holder of the actor.

Check an actor exiting (this is the convert exit into go out rule):
	let the local room be the location of the actor;
	if the container exited from is the local room:
		if the room-or-door outside from the local room is not nothing,
			convert to the going action on the outside;

Check an actor exiting (this is the can't exit when not inside anything rule):
	let the local room be the location of the actor;
	if the container exited from is the local room:
		if the player is the actor:
			say "But [we] [aren't] in anything at the [if story tense is present
				tense]moment[otherwise]time[end if]." (A);
		stop the action.

Check an actor exiting (this is the can't exit closed containers rule):
	if the actor is in a closed container (called the cage):
		if the player is the actor:
			say "You can't get out of the closed [cage]." (A);
		stop the action.

Check an actor exiting (this is the convert exit into get off rule):
	if the actor is on a supporter (called the platform),
		convert to the getting off action on the platform.

Carry out an actor exiting (this is the standard exiting rule):
	let the former exterior be the not-counting-parts holder of the container exited from;
	surreptitiously move the actor to the former exterior.

Report an actor exiting (this is the standard report exiting rule):
	if the action is not silent:
		if the actor is the player:
			if the container exited from is a supporter:
				say "[We] [get] off [the container exited from]." (A);
			otherwise:
 				say "[We] [get] out of [the container exited from]." (B);
		otherwise:
 			say "[The actor] [get] out of [the container exited from]." (C);
	continue the action.

Report an actor exiting (this is the describe room emerged into rule):
	if the actor is the player:
		surreptitiously reckon darkness;
		produce a room description with going spacing conventions.

Getting off is an action applying to one thing.
The getting off action is accessible to Inter as "GetOff".

The specification of the getting off action is "The getting off action is for
actors who are currently on top of a supporter: perhaps standing on a platform,
but maybe only sitting on a chair or even lying down in bed. Unlike the similar
exiting action, getting off takes a noun: the platform, chair, bed or what
have you."

Check an actor getting off (this is the can't get off things rule):
	if the actor is on the noun, continue the action;
	if the actor is carried by the noun, continue the action;
	if the actor is the player:
		say "But [we] [aren't] on [the noun] at the [if story tense is present
			tense]moment[otherwise]time[end if]." (A);
	stop the action.

Carry out an actor getting off (this is the standard getting off rule):
	let the former exterior be the not-counting-parts holder of the noun;
	surreptitiously move the actor to the former exterior.

Report an actor getting off (this is the standard report getting off rule):
	if the action is not silent:
		say "[The actor] [get] off [the noun]." (A);
	continue the action.

Report an actor getting off (this is the describe room stood up into rule):
	if the actor is the player,
		produce a room description with going spacing conventions.

Section 4 - Standard actions concerning the actor's vision

Looking is an action applying to nothing.
The looking action is accessible to Inter as "Look".

The specification of the looking action is "The looking action describes the
player's current room and any visible items, but is made more complicated
by the problem of visibility. Inform calculates this by dividing the room
into visibility levels. For an actor on the floor of a room, there is only
one such level: the room itself. But an actor sitting on a chair inside
a packing case which is itself on a gantry would have four visibility levels:
chair, case, gantry, room. The looking rules use a special phrase, 'the
visibility-holder of X', to go up from one level to the next: thus the
visibility-holder of the case is the gantry.

The 'visibility level count' is the number of levels which the player can
actually see, and the 'visibility ceiling' is the uppermost visible level.
For a player standing on the floor of a lighted room, this will be a count
of 1 with the ceiling set to the room. But a player sitting on a chair in
a closed opaque packing case would have visibility level count 2, and
visibility ceiling equal to the case. Moreover, light has to be available
in order to see anything at all: if the player is in darkness, the level
count is 0 and the ceiling is nothing.

Finally, note that several actions other than looking also produce room
descriptions in some cases. The most familiar is going, but exiting a
container or getting off a supporter will also generate a room description.
(The phrase used by the relevant rules is 'produce a room description with
going spacing conventions' and carry out or report rules for newly written
actions are welcome to use this too if they would like to. The spacing
conventions affect paragraph division, and note that the main description
paragraph may be omitted for a place not newly visited, depending on the
VERBOSE settings.) Room descriptions like this are produced by running the
check, carry out and report rules for looking, but are not subject to
before, instead or after rules: so they do not count as a new action. The
looking variable 'room-describing action' holds the action name of the
reason a room description is currently being made: if the player typed
LOOK, this will indeed be set to the looking action, but if we're
describing a room just reached by GO EAST, say, it will be set to the going
action. This can be used to customise carry out looking rules so that
different forms of description are used on going to a room as compared with
looking around while already there."

The looking action has an action name called the room-describing action.
The looking action has a truth state called abbreviated form allowed.
The looking action has a number called the visibility level count.
The looking action has an object called the visibility ceiling.

Setting action variables for looking (this is the determine visibility ceiling
	rule):
	if the actor is the player, calculate visibility ceiling at low level;
	now the visibility level count is the visibility ceiling count calculated;
	now the visibility ceiling is the visibility ceiling calculated;
	now the room-describing action is the looking action.

Carry out looking (this is the declare everything unmentioned rule):
	repeat with item running through things:
		now the item is not mentioned.

Carry out looking (this is the room description heading rule):
	if nameless room descriptions option is not active:
		say bold type;
		if the visibility level count is 0:
			begin the printing the name of a dark room activity;
			if handling the printing the name of a dark room activity:
				say "Darkness" (A);
			end the printing the name of a dark room activity;
		otherwise if the visibility ceiling is the location:
			say "[visibility ceiling]";
		otherwise:
			say "[The visibility ceiling]";
		say roman type;
		let intermediate level be the visibility-holder of the actor;
		repeat with intermediate level count running from 2 to the visibility level count:
			if the intermediate level is a supporter or the intermediate level is an animal:
				say " (on [the intermediate level])" (B);
			otherwise:
				say " (in [the intermediate level])" (C);
			let the intermediate level be the visibility-holder of the intermediate level;
		say line break;
		say run paragraph on with special look spacing.

Carry out looking (this is the room description body text rule):
	if the visibility level count is 0:
		if set to abbreviated room descriptions, continue the action;
		if set to sometimes abbreviated	room descriptions and
			abbreviated form allowed is true and
			darkness witnessed is true,
			continue the action;
		begin the printing the description of a dark room activity;
		if handling the printing the description of a dark room activity:
			now the prior named object is nothing;
			say "[It] [are] pitch dark, and [we] [can't see] a thing." (A);
		end the printing the description of a dark room activity;
	otherwise if the visibility ceiling is the location:
		if set to abbreviated room descriptions, continue the action;
		if set to sometimes abbreviated	room descriptions and abbreviated form
			allowed is true and the location is visited, continue the action;
		print the location's description;

Carry out looking (this is the room description paragraphs about objects rule):
	if the visibility level count is greater than 0:
		let the intermediate position be the actor;
		let the IP count be the visibility level count;
		while the IP count is greater than 0:
			now the intermediate position is marked for listing;
			let the intermediate position be the visibility-holder of the
				intermediate position;
			decrease the IP count by 1;
		let the top-down IP count be the visibility level count;
		while the top-down IP count is greater than 0:
			let the intermediate position be the actor;
			let the IP count be 0;
			while the IP count is less than the top-down IP count:
				let the intermediate position be the visibility-holder of the
					intermediate position;
				increase the IP count by 1;
			describe locale for the intermediate position;
			decrease the top-down IP count by 1;
	continue the action;

Carry out looking (this is the check new arrival rule):
	if in darkness:
		now the darkness witnessed is true;
	otherwise:
		if the location is a room, now the location is visited;

Report an actor looking (this is the other people looking rule):
	if the actor is not the player:
		say "[The actor] [look] around." (A).

Examining is an action applying to one visible thing and requiring light.
The examining action is accessible to Inter as "Examine".

The specification of the examining action is "The act of looking closely at
something. Note that the noun could be either a direction or a thing, which
is why the Standard Rules include the 'examine directions rule' to deal with
directions: it simply says 'You see nothing unexpected in that direction.'
and stops the action. (If you would like to handle directions differently,
list another rule instead of this one in the carry out examining rules.)

Some things have no description property, or rather, have only a blank text
as one. It's possible that something interesting may be said anyway (see
the rules for directions, containers, supporters and devices), but if not,
we give up with a bland response. This is done by the examine undescribed
things rule."

The examining action has a truth state called examine text printed.

Carry out examining (this is the standard examining rule):
	if the noun provides the property description and the description of the noun is not "":
		say "[description of the noun][line break]";
		now examine text printed is true.

Carry out examining (this is the examine directions rule):
	if the noun is a direction:
		say "[We] [see] nothing unexpected in that direction." (A);
		now examine text printed is true.

Carry out examining (this is the examine containers rule):
	if the noun is a container:
		if the noun is closed and the noun is opaque, make no decision;
		if something described which is not scenery is in the noun and something which
			is not the player is in the noun and the noun is not falsely-unoccupied:
			say "In [the noun] " (A);
			list the contents of the noun, as a sentence, tersely, not listing
				concealed items, prefacing with is/are;
			say ".";
			now examine text printed is true;
		otherwise if examine text printed is false:
			if the player is in the noun:
				make no decision;
			say "[The noun] [are] empty." (B);
			now examine text printed is true;

Carry out examining (this is the examine supporters rule):
	if the noun is a supporter and the noun is not falsely-unoccupied:
		if something described which is not scenery is on the noun and something which is
			not the player is on the noun:
			say "On [the noun] " (A);
			list the contents of the noun, as a sentence, tersely, not listing
				concealed items, prefacing with is/are, including contents,
				giving brief inventory information;
			say ".";
			now examine text printed is true.

Carry out examining (this is the examine devices rule):
	if the noun provides the property switched on:
		say "[The noun] [are] [if story tense is present tense]currently [end if]switched
			[if the noun is switched on]on[otherwise]off[end if]." (A);
		now examine text printed is true.

Carry out examining (this is the examine undescribed things rule):
	if examine text printed is false:
		say "[We] [see] nothing special about [the noun]." (A).

Report an actor examining (this is the report other people examining rule):
	if the actor is not the player:
		say "[The actor] [look] closely at [the noun]." (A).

Looking under is an action applying to one visible thing and requiring light.
The looking under action is accessible to Inter as "LookUnder".

The specification of the looking under action is "The standard Inform world
model does not have a concept of things being under other things, so this
action is only minimally provided by the Standard Rules, but it exists here
for traditional reasons (and because, after all, LOOK UNDER TABLE is the
sort of command which ought to be recognised even if it does nothing useful).
The action ordinarily either tells the player that they find nothing of
interest, or reports that somebody else has looked under something.

The usual way to make this action do something useful is to write a rule
like 'Instead of looking under the cabinet for the first time: now the
player has the silver key; say ...' and so on."

Carry out an actor looking under (this is the standard looking under rule):
	if the player is the actor:
		say "[We] [find] nothing of interest." (A);
	stop the action.

Report an actor looking under (this is the report other people looking under rule):
	if the action is not silent:
		if the actor is not the player:
			say "[The actor] [look] under [the noun]." (A).

Searching is an action applying to one thing and requiring light.
The searching action is accessible to Inter as "Search".

The specification of the searching action is "Searching looks at the contents
of an open or transparent container, or at the items on top of a supporter.
These are often mentioned in room descriptions already, and then the action
is unnecessary, but that wouldn't be true for something like a kitchen
cupboard which is scenery - mentioned in passing in a room description, but
not made a fuss of. Searching such a cupboard would then, by listing its
contents, give the player more information than the ordinary room description
shows.

The usual check rules restrict searching to containers and supporters: so
the Standard Rules do not allow the searching of people, for instance. But
it is easy to add instead rules ('Instead of searching Dr Watson: ...') or
even a new carry out rule ('Check searching someone (called the suspect): ...')
to extend the way searching normally works."

Check an actor searching (this is the can't search unless container or supporter rule):
	if the noun is not a container and the noun is not a supporter:
		if the player is the actor:
			say "[We] [find] nothing of interest." (A);
		stop the action.

Check an actor searching (this is the can't search closed opaque containers rule):
	if the noun is a closed opaque container:
		if the player is the actor:
			say "[We] [can't see] inside, since [the noun] [are] closed." (A);
		stop the action.

Report searching a container (this is the standard search containers rule):
	if the noun contains a described thing which is not scenery:
		say "In [the noun] " (A);
		list the contents of the noun, as a sentence, tersely, not listing
			concealed items, prefacing with is/are;
		say ".";
	otherwise:
		say "[The noun] [are] empty." (B).

Report searching a supporter (this is the standard search supporters rule):
	if the noun supports a described thing which is not scenery:
		say "On [the noun] " (A);
		list the contents of the noun, as a sentence, tersely, not listing
			concealed items, prefacing with is/are;
		say ".";
	otherwise:
		now the prior named object is nothing;
		say "[There] [are] nothing on [the noun]." (B).

Report an actor searching (this is the report other people searching rule):
	if the actor is not the player:
		say "[The actor] [search] [the noun]." (A).

Consulting it about is an action applying to one thing and one topic.
The consulting it about action is accessible to Inter as "Consult".

The specification of the consulting it about action is "Consulting is a very
flexible and potentially powerful action, but only because it leaves almost
all of the work to the author to deal with directly. The idea is for it to
respond to commands such as LOOK UP HENRY FITZROY IN HISTORY BOOK, where
the topic would be the snippet of command HENRY FITZROY and the thing would
be the book.

The Standard Rules simply parry such requests by saying that the player finds
nothing of interest. All interesting responses must be provided by the author,
using rules like 'Instead of consulting the history book about...'"

Report an actor consulting something about (this is the block consulting rule):
	if the actor is the player:
		say "[We] [discover] nothing of interest in [the noun]." (A);
	otherwise:
		say "[The actor] [look] at [the noun]." (B);

Section 5 - Standard actions which change the state of things

Locking it with is an action applying to two things.
The locking it with action is accessible to Inter as "Lock".

The specification of the locking it with action is "Locking is the act of
using an object such as a key to ensure that something such as a door or
container cannot be opened unless first unlocked. (Only closed things can be
locked.)

Locking can be performed on any kind of thing which provides the either/or
properties lockable, locked, openable and open. The 'can't lock without a lock
rule' tests to see if the noun both provides the lockable property, and if
it is in fact lockable: it is then assumed that the other properties can
safely be checked. In the Standard Rules, the container and door kinds both
satisfy these requirements.

We can create a new kind on which opening, closing, locking and unlocking
will work thus: 'A briefcase is a kind of thing. A briefcase can be openable.
A briefcase can be open. A briefcase can be lockable. A briefcase can be
locked. A briefcase is usually openable, lockable, open and unlocked.'

Inform checks whether the key fits using the 'can't lock without the correct
key rule'. To satisfy this, the actor must be directly holding the second
noun, and it must be the current value of the 'matching key' property for
the noun. (This property is seldom referred to directly because it is
automatically set by assertions like 'The silver key unlocks the wicket
gate.')

The Standard Rules provide locking and unlocking actions at a fairly basic
level: they can be much enhanced using the extension Locksmith by Emily
Short, which is included with all distributions of Inform."

First check an actor locking something with (this is the can't lock without holding the key rule):
	if the holder of the second noun is not the actor:
		carry out the implicitly taking activity with the second noun;
		if the actor is not the holder of the second noun, stop the action.

Check an actor locking something with (this is the can't lock without a lock rule):
	if the noun provides the property lockable and the noun is lockable:
		continue the action;
	if the actor is the player:
		say "[regarding the noun][Those] [don't] seem to be something [we] [can] lock." (A);
	stop the action.

Check an actor locking something with (this is the can't lock what's already
	locked rule):
	if the noun is locked:
		if the actor is the player:
			say "[regarding the noun][They're] locked at the [if story tense is present
				tense]moment[otherwise]time[end if]." (A);
		stop the action.

Check an actor locking something with (this is the can't lock what's open rule):
	if the noun is open:
		if the actor is the player:
			say "First [we] [would have] to close [the noun]." (A);
		stop the action.

Check an actor locking something with (this is the can't lock without the correct key rule):
	if the holder of the second noun is not the actor or
		the noun does not provide the property matching key or
		the matching key of the noun is not the second noun:
		if the actor is the player:
			say "[regarding the second noun][Those] [don't] seem to fit the lock." (A);
		stop the action.

Carry out an actor locking something with (this is the standard locking rule):
	now the noun is locked.

Report an actor locking something with (this is the standard report locking rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [lock] [the noun]." (A);
	otherwise:
		if the actor is visible:
			say "[The actor] [lock] [the noun]." (B);

Unlocking it with is an action applying to two things.
The unlocking it with action is accessible to Inter as "Unlock".

The specification of the unlocking it with action is "Unlocking undoes the
effect of locking, and renders the noun openable again provided that the
actor is carrying the right key (which must be the second noun).

Unlocking can be performed on any kind of thing which provides the either/or
properties lockable, locked, openable and open. The 'can't unlock without a lock
rule' tests to see if the noun both provides the lockable property, and if
it is in fact lockable: it is then assumed that the other properties can
safely be checked. In the Standard Rules, the container and door kinds both
satisfy these requirements.

We can create a new kind on which opening, closing, locking and unlocking
will work thus: 'A briefcase is a kind of thing. A briefcase can be openable.
A briefcase can be open. A briefcase can be lockable. A briefcase can be
locked. A briefcase is usually openable, lockable, open and unlocked.'

Inform checks whether the key fits using the 'can't unlock without the correct
key rule'. To satisfy this, the actor must be directly holding the second
noun, and it must be the current value of the 'matching key' property for
the noun. (This property is seldom referred to directly because it is
automatically set by assertions like 'The silver key unlocks the wicket
gate.')

The Standard Rules provide locking and unlocking actions at a fairly basic
level: they can be much enhanced using the extension Locksmith by Emily
Short, which is included with all distributions of Inform."

First check an actor unlocking something with (this is the can't unlock without holding the key rule):
	if the holder of the second noun is not the actor:
		carry out the implicitly taking activity with the second noun;
		if the actor is not the holder of the second noun, stop the action.

Check an actor unlocking something with (this is the can't unlock without a lock rule):
	if the noun provides the property lockable and the noun is lockable:
		continue the action;
	if the actor is the player:
		say "[regarding the noun][Those] [don't] seem to be something [we] [can] unlock." (A);
	stop the action.

Check an actor unlocking something with (this is the can't unlock what's already unlocked rule):
	if the noun is not locked:
		if the actor is the player:
			say "[regarding the noun][They're] unlocked at the [if story tense is present
				tense]moment[otherwise]time[end if]." (A);
		stop the action.

Check an actor unlocking something with (this is the can't unlock without the correct key rule):
	if the holder of the second noun is not the actor or
		the noun does not provide the property matching key or
		the matching key of the noun is not the second noun:
		if the actor is the player:
			say "[regarding the second noun][Those] [don't] seem to fit the lock." (A);
		stop the action.

Carry out an actor unlocking something with (this is the standard unlocking rule):
	now the noun is not locked.

Report an actor unlocking something with (this is the standard report unlocking rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [unlock] [the noun]." (A);
	otherwise:
		if the actor is visible:
			say "[The actor] [unlock] [the noun]." (B);

Switching on is an action applying to one thing.
The switching on action is accessible to Inter as "SwitchOn".

The specification of the switching on action is "The switching on and switching
off actions are for the simplest kind of machinery operation: they are for
objects representing machines (or more likely parts of machines), which are
considered to be either off or on at any given time.

The actions are intended to be used where the noun is a device, but in fact
they could work just as well with any kind which can be 'switched on' or
'switched off'."

Check an actor switching on (this is the can't switch on unless switchable rule):
	if the noun provides the property switched on, continue the action;
	if the actor is the player:
		say "[regarding the noun][They] [aren't] something [we] [can] switch." (A);
	stop the action.

Check an actor switching on (this is the can't switch on what's already on rule):
	if the noun is switched on:
		if the actor is the player:
			say "[regarding the noun][They're] already on." (A);
		stop the action.

Carry out an actor switching on (this is the standard switching on rule):
	now the noun is switched on.

Report an actor switching on (this is the standard report switching on rule):
	if the action is not silent:
		say "[The actor] [switch] [the noun] on." (A).

Switching off is an action applying to one thing.
The switching off action is accessible to Inter as "SwitchOff".

The specification of the switching off action is "The switching off and switching
on actions are for the simplest kind of machinery operation: they are for
objects representing machines (or more likely parts of machines), which are
considered to be either off or on at any given time.

The actions are intended to be used where the noun is a device, but in fact
they could work just as well with any kind which can be 'switched on' or
'switched off'."

Check an actor switching off (this is the can't switch off unless switchable rule):
	if the noun provides the property switched on, continue the action;
	if the actor is the player:
		say "[regarding the noun][They] [aren't] something [we] [can] switch." (A);
	stop the action.

Check an actor switching off (this is the can't switch off what's already off rule):
	if the noun is switched off:
		if the actor is the player:
			say "[regarding the noun][They're] already off." (A);
		stop the action.

Carry out an actor switching off (this is the standard switching off rule):
	now the noun is switched off.

Report an actor switching off (this is the standard report switching off rule):
	if the action is not silent:
		say "[The actor] [switch] [the noun] off." (A).

Opening is an action applying to one thing.
The opening action is accessible to Inter as "Open".

The specification of the opening action is "Opening makes something no longer
a physical barrier. The action can be performed on any kind of thing which
provides the either/or properties openable and open. The 'can't open unless
openable rule' tests to see if the noun both can be and actually is openable.
(It is assumed that anything which can be openable can also be open.)
In the Standard Rules, the container and door kinds both satisfy these
requirements.

In the event that the thing to be opened is also lockable, we are forbidden
to open it when it is locked. Both containers and doors can be lockable,
but the opening and closing actions would also work fine with kinds which
cannot be.

We can create a new kind on which opening and closing will work thus:
'A case file is a kind of thing. A case file can be openable.
A case file can be open. A case file is usually openable and closed.'

The meaning of open and closed is different for different kinds of thing.
When a container is closed, that means people outside cannot reach in,
and vice versa; when a door is closed, people cannot use the 'going' action
to pass through it. If we were to create a new kind such as 'case file',
we would also need to write rules to make the open and closed properties
interesting for this kind."

Check an actor opening (this is the can't open unless openable rule):
	if the noun provides the property openable and the noun is openable:
		continue the action;
	if the actor is the player:
		say "[regarding the noun][They] [aren't] something [we] [can] open." (A);
	stop the action.

Check an actor opening (this is the can't open what's locked rule):
	if the noun provides the property lockable and the noun is locked:
		if the actor is the player:
			say "[regarding the noun][They] [seem] to be locked." (A);
		stop the action.

Check an actor opening (this is the can't open what's already open rule):
	if the noun is open:
		if the actor is the player:
			say "[regarding the noun][They're] already open." (A);
		stop the action.

Carry out an actor opening (this is the standard opening rule):
	now the noun is open.

Report an actor opening (this is the reveal any newly visible interior rule):
	if the actor is the player and
		the noun is an opaque container and
		the noun is obviously-occupied and
		the noun does not enclose the actor:
		if the action is not silent:
			if the actor is the player:
				say "[We] [open] [the noun], revealing " (A);
				list the contents of the noun, as a sentence, tersely, not listing
					concealed items;
				say ".";
		stop the action.

Report an actor opening (this is the standard report opening rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [open] [the noun]." (A);
	otherwise if the player can see the actor:
		say "[The actor] [open] [the noun]." (B);
	otherwise:
		say "[The noun] [open]." (C);

Closing is an action applying to one thing.
The closing action is accessible to Inter as "Close".

The specification of the closing action is "Closing makes something into
a physical barrier. The action can be performed on any kind of thing which
provides the either/or properties openable and open. The 'can't close unless
openable rule' tests to see if the noun both can be and actually is openable.
(It is assumed that anything which can be openable can also be open, and
hence can also be closed.) In the Standard Rules, the container and door
kinds both satisfy these requirements.

We can create a new kind on which opening and closing will work thus:
'A case file is a kind of thing. A case file can be openable.
A case file can be open. A case file is usually openable and closed.'

The meaning of open and closed is different for different kinds of thing.
When a container is closed, that means people outside cannot reach in,
and vice versa; when a door is closed, people cannot use the 'going' action
to pass through it. If we were to create a new kind such as 'case file',
we would also need to write rules to make the open and closed properties
interesting for this kind."

Check an actor closing (this is the can't close unless openable rule):
	if the noun provides the property openable and the noun is openable:
		continue the action;
	if the actor is the player:
		say "[regarding the noun][They] [aren't] something [we] [can] close." (A);
	stop the action.

Check an actor closing (this is the can't close what's already closed rule):
	if the noun is closed:
		if the actor is the player:
			say "[regarding the noun][They're] already closed." (A);
		stop the action.

Carry out an actor closing (this is the standard closing rule):
	now the noun is closed.

Report an actor closing (this is the standard report closing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [close] [the noun]." (A);
	otherwise if the player can see the actor:
		say "[The actor] [close] [the noun]." (B);
	otherwise:
		say "[The noun] [close]." (C);

Wearing is an action applying to one thing.
The wearing action is accessible to Inter as "Wear".

The specification of the wearing action is "The Standard Rules give Inform
only a simple model of clothing. A thing can be worn only if it has the
either/or property of being 'wearable'. (Typing a sentence like 'Mr Jones
wears the Homburg hat.' automatically implies that the hat is wearable,
which is why we only seldom need to use the word 'wearable' directly.)
There is no checking of how much or how little any actor is wearing, or
how incongruous this may appear: nor any distinction between under or
over-clothes.

To put on an article of clothing, the actor must be directly carrying it,
as enforced by the 'can't wear what's not held rule'."

First check an actor wearing (this is the can't wear what's not held rule):
	if the holder of the noun is not the actor:
		carry out the implicitly taking activity with the noun;
		if the actor is not the holder of the noun, stop the action.

Check an actor wearing (this is the can't wear what's not clothing rule):
	if the noun is not a thing or the noun is not wearable:
		if the actor is the player:
			say "[We] [can't wear] [regarding the noun][those]!" (A);
		stop the action.

Check an actor wearing (this is the can't wear what's already worn rule):
	if the actor is wearing the noun:
		if the actor is the player:
			say "[We]['re] already wearing [regarding the noun][those]!" (A);
		stop the action.

Carry out an actor wearing (this is the standard wearing rule):
	now the actor wears the noun.

Report an actor wearing (this is the standard report wearing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [put] on [the noun]." (A);
	otherwise:
		say "[The actor] [put] on [the noun]." (B).

Taking off is an action applying to one thing.
The taking off action is accessible to Inter as "Disrobe".

Does the player mean taking off something worn: it is very likely.

The specification of the taking off action is "The Standard Rules give Inform
only a simple model of clothing. A thing can be worn only if it has the
either/or property of being 'wearable'. (Typing a sentence like 'Mr Jones
wears the Homburg hat.' automatically implies that the hat is wearable,
which is why we only seldom need to use the word 'wearable' directly.)
There is no checking of how much or how little any actor is wearing, or
how incongruous this may appear: nor any distinction between under or
over-clothes.

When an article of clothing is taken off, it becomes a thing directly
carried by its former wearer, rather than being (say) dropped onto the floor."

Check an actor taking off (this is the can't take off what's not worn rule):
	if the actor is not wearing the noun:
		if the actor is the player:
			say "[We] [aren't] wearing [the noun]." (A);
		stop the action.

Check an actor taking off (this is the can't exceed carrying capacity when taking off rule):
	if the number of things carried by the actor is at least the carrying capacity of the actor:
		if the actor is the player:
			say "[We]['re] carrying too many things already." (A);
		stop the action.

Carry out an actor taking off (this is the standard taking off rule):
	now the actor carries the noun.

Report an actor taking off (this is the standard report taking off rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [take] off [the noun]." (A);
	otherwise:
		say "[The actor] [take] off [the noun]." (B).

Section 6 - Standard actions concerning other people

Giving it to is an action applying to two things.
The giving it to action is accessible to Inter as "Give".

The specification of the giving it to action is "This action is indexed by
Inform under 'Actions concerning other people', but it could just as easily
have gone under 'Actions concerning the actor's possessions' because -
like dropping, putting it on or inserting it into - this is an action
which gets rid of something being carried.

The Standard Rules implement this action fully - if it reaches the carry
out and report rulebooks, then the item is indeed transferred to the
recipient, and this is properly reported. But giving something to
somebody is not like putting something on a shelf: the recipient has
to agree. The final check rule, the 'block giving rule', assumes that
the recipient does not consent - so the gift fails to happen. The way
to make the giving action use its abilities fully is to replace the
block giving rule with a rule which makes a more sophisticated decision
about who will accept what from whom, and only blocks some attempts,
letting others run on into the carry out and report rules."

First check an actor giving something to (this is the can't give what you haven't got rule):
	if the actor is not the holder of the noun:
		carry out the implicitly taking activity with the noun;
		if the actor does not hold the noun, stop the action.

Check an actor giving something to (this is the can't give to yourself rule):
	if the actor is the second noun:
		if the actor is the player:
			say "[We] [can't give] [the noun] to [ourselves]." (A);
		stop the action.

Check an actor giving something to (this is the can't give to a non-person rule):
	if the second noun is not a person:
		if the actor is the player:
			say "[The second noun] [aren't] able to receive things." (A);
		stop the action.

Check an actor giving something to (this is the can't give clothes being worn rule):
	if the actor is wearing the noun:
		say "(first taking [the noun] off)[command clarification break]" (A);
		silently try the actor trying taking off the noun;
		if the actor is wearing the noun, stop the action;

Check an actor giving something to (this is the block giving rule):
	if the actor is the player:
		say "[The second noun] [don't] seem interested." (A);
	stop the action.

Check an actor giving something to (this is the can't exceed carrying capacity
	when giving rule):
	if the number of things carried by the second noun is at least the carrying
		capacity of the second noun:
		if the actor is the player:
			say "[The second noun] [are] carrying too many things already." (A);
		stop the action.

Carry out an actor giving something to (this is the standard giving rule):
	move the noun to the second noun.

Report an actor giving something to (this is the standard report giving rule):
	if the actor is the player:
		say "[We] [give] [the noun] to [the second noun]." (A);
	otherwise if the second noun is the player:
		say "[The actor] [give] [the noun] to [us]." (B);
	otherwise:
		say "[The actor] [give] [the noun] to [the second noun]." (C).

Showing it to is an action applying to one thing and one visible thing.
The showing it to action is accessible to Inter as "Show".

The specification of the showing it to action is "Anyone can show anyone
else something which they are carrying, but not some nearby piece of
scenery, say - so this action is suitable for showing the emerald locket
to Katarina, but not showing the Orange River Rock Room to Mr Douglas.

The Standard Rules implement this action in only a minimal way, checking
that it makes sense but then blocking all such attempts with a message
such as 'Katarina is not interested.' - this is the task of the 'block
showing rule'. As a result, there are no carry out or report rules. To
make it into a systematic and interesting action, we would need to
unlist the block showing rule and then to write carry out and report
rules: but usually for IF purposes we only need to make a handful of
special cases of showing work properly, and for those we can simply
write Instead rules to handle them."

Check an actor showing something to (this is the can't show what you haven't
	got rule):
	if the actor is not the holder of the noun:
		carry out the implicitly taking activity with the noun;
		if the actor is not the holder of the noun, stop the action.

Check an actor showing something to (this is the convert show to yourself to
	examine rule):
	if the actor is the second noun:
		convert to the examining action on the noun.

Check an actor showing something to (this is the block showing rule):
	if the actor is the player:
		say "[The second noun] [are] unimpressed." (A);
	stop the action.

Waking is an action applying to one thing.
The waking action is accessible to Inter as "WakeOther".

The specification of the waking action is "This is the act of jostling
a sleeping person to wake them up, and it finds its way into the Standard
Rules only for historical reasons. Inform does not by default provide
any model for people being asleep or awake, so this action doesnot do
anything in the standard implementation: instead, it is always stopped by
the block waking rule."

Check an actor waking (this is the block waking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "That [seem] unnecessary." (A);
	stop the action.

Throwing it at is an action applying to one thing and one visible thing.
The throwing it at action is accessible to Inter as "ThrowAt".

The specification of the throwing it at action is "Throwing something at
someone or something is difficult for Inform to model. So many considerations
apply: just because the actor can see the target, does it follow that the
target can accurately hit it? What if the projectile is heavy, like an
anvil, or something not easily aimable, like a feather? What if there
is a barrier in the way, like a cage with bars spaced so that only items
of a certain size get through? And then: what should happen as a result?
Will the projectile break, or do damage, or fall to the floor, or into
a container or onto a supporter? And so on.

Because it seems hopeless to try to model this in any general way,
Inform instead provides the action for the user to attach specific rules to.
The check rules in the Standard Rules simply require that the projectile
is not an item of clothing still worn (this will be relevant for women
attending a Tom Jones concert) but then, in either the 'futile to throw
things at inanimate objects rule' or the 'block throwing at rule', will
refuse to carry out the action with a bland message.

To make throwing do something, then, we must either write Instead rules
for special circumstances, or else unlist these check rules and write
suitable carry out and report rules to pick up the thread."

Check an actor throwing something at (this is the implicitly remove thrown clothing rule):
	if the actor is wearing the noun:
		say "(first taking [the noun] off)[command clarification break]" (A);
		silently try the actor trying taking off the noun;
		if the actor is wearing the noun, stop the action;

Check an actor throwing something at (this is the implicitly take thrown object rule):
	if the actor is not the holder of the noun:
		carry out the implicitly taking activity with the noun;
		if the actor is not the holder of the noun, stop the action.

Check an actor throwing something at (this is the futile to throw things at inanimate
	objects rule):
	if the second noun is not a person:
		if the actor is the player:
			say "Futile." (A);
		stop the action.

Check an actor throwing something at (this is the block throwing at rule):
	if the actor is the player:
		say "[We] [lack] the nerve when it [if story tense is the past
			tense]came[otherwise]comes[end if] to the crucial moment." (A);
	stop the action.

Attacking is an action applying to one thing.
The attacking action is accessible to Inter as "Attack".

The specification of the attacking action is "Violence is seldom the answer,
and attempts to attack another person are normally blocked as being unrealistic
or not seriously meant. (I might find a shop assistant annoying, but IF is
not Grand Theft Auto, and responding by killing them is not really one of
my options.) So the Standard Rules simply block attempts to fight people,
but the action exists for rules to make exceptions."

Check an actor attacking (this is the block attacking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "Violence [aren't] the answer to this one." (A);
	stop the action.

Kissing is an action applying to one thing.
The kissing action is accessible to Inter as "Kiss".

The specification of the kissing action is "Possibly because Inform was
originally written by an Englishman, attempts at kissing another person are
normally blocked as being unrealistic or not seriously meant. So the
Standard Rules simply block attempts to kiss people, but the action exists
for rules to make exceptions."

Check an actor kissing (this is the kissing yourself rule):
	if the noun is the actor:
		if the actor is the player:
			say "[We] [don't] get much from that." (A);
		stop the action.

Check an actor kissing (this is the block kissing rule):
	if the actor is the player:
		say "[The noun] [might not] like that." (A);
	stop the action.

Answering it that is an action applying to one thing and one topic.
The answering it that action is accessible to Inter as "Answer".

The specification of the answering it that action is "The Standard Rules do
not include any systematic way to handle conversation: instead, Inform is
set up so that it is as easy as we can make it to write specific rules
handling speech in particular games, and so that if no such rules are
written then all attempts to communicate are gracefully if not very
interestingly rejected.

The topic here can be any double-quoted text, which can itself contain
tokens in square brackets: see the documentation on Understanding.

Answering is an action existing so that the player can say something free-form
to somebody else. A convention of IF is that a command such as DAPHNE, TAKE
MASK is a request to Daphne to perform an action: if the persuasion rules in
force mean that she consents, the action 'Daphne taking the mask' does
indeed then result. But if the player types DAPHNE, 12375 or DAPHNE, GREAT
HEAVENS - or anything else not making sense as a command - the action
'answering Daphne that ...' will be generated.

The name of the action arises because it is also caused by typing, say,
ANSWER 12375 when Daphne (say) has asked a question."

Report an actor answering something that (this is the block answering rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There] [are] no reply." (A);
	stop the action.

Telling it about is an action applying to one thing and one topic.
The telling it about action is accessible to Inter as "Tell".

The specification of the telling it about action is "The Standard Rules do
not include any systematic way to handle conversation: instead, Inform is
set up so that it is as easy as we can make it to write specific rules
handling speech in particular games, and so that if no such rules are
written then all attempts to communicate are gracefully if not very
interestingly rejected.

The topic here can be any double-quoted text, which can itself contain
tokens in square brackets: see the documentation on Understanding.

Telling is an action existing only to catch commands like TELL ALEX ABOUT
GUITAR. Customarily in IF, such a command is shorthand which the player
accepts as a conventional form: it means 'tell Alex what I now know about
the guitar' and would make sense if the player had himself recently
discovered something significant about the guitar which might interest
Alex."

Check an actor telling something about (this is the telling yourself rule):
	if the actor is the noun:
		if the actor is the player:
			say "[We] [talk] to [ourselves] a while." (A);
		stop the action.

Report an actor telling something about (this is the block telling rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "This [provoke] no reaction." (A);
	stop the action.

Asking it about is an action applying to one thing and one topic.
The asking it about action is accessible to Inter as "Ask".

The specification of the asking it about action is "The Standard Rules do
not include any systematic way to handle conversation: instead, Inform is
set up so that it is as easy as we can make it to write specific rules
handling speech in particular games, and so that if no such rules are
written then all attempts to communicate are gracefully if not very
interestingly rejected.

The topic here can be any double-quoted text, which can itself contain
tokens in square brackets: see the documentation on Understanding.

Asking is an action existing only to catch commands like ASK STEPHEN ABOUT
PENELOPE. Customarily in IF, such a command is shorthand which the player
accepts as a conventional form: it means 'engage Mary in conversation and
try to find out what she might know about'. It's understood as a convention
of the genre that Mary should not be expected to respond in cases where
there is no reason to suppose that she has anything relevant to pass on -
ASK JANE ABOUT RICE PUDDING, for instance, need not conjure up a recipe
even if Jane is a 19th-century servant and therefore almost certainly
knows one."

Report an actor asking something about (this is the block asking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There] [are] no reply." (A);
	stop the action.

Asking it for is an action applying to two things.
The asking it for action is accessible to Inter as "AskFor".

The specification of the asking it for action is "The Standard Rules do
not include any systematic way to handle conversation, but this is
action is not quite conversation: it doesn't involve any spoken text as
such. It exists to catch commands like ASK SALLY FOR THE EGG WHISK,
where the whisk is something which Sally has and the player can see.

Slightly oddly, but for historical reasons, an actor asking himself for
something is treated to an inventory listing instead. All other cases
are converted to the giving action: that is, ASK SALLY FOR THE EGG WHISK
is treated as if it were SALLY, GIVE ME THE EGG WHISK - an action for
Sally to perform and which then follows rules for giving.

To ask for information or something intangible, see the asking it about
action."

Check an actor asking something for (this is the asking yourself for something rule):
	if the actor is the noun and the actor is the player:
		try taking inventory instead.

Check an actor asking something for (this is the translate asking for to giving rule):
	convert to request of the noun to perform giving it to action with the second noun and the actor.

Section 7 - Standard actions which are checked but then do nothing unless rules intervene

Waiting is an action applying to nothing.
The waiting action is accessible to Inter as "Wait".

The specification of the waiting action is "The inaction action: where would
we be without waiting? Waiting does not cause time to pass by - that happens
anyway - but represents a positive choice by the actor not to fill that time.
It is an action so that rules can be attached to it: for instance, we could
imagine that a player who consciously decides to sit and wait might notice
something which a busy player does not, and we could write a rule accordingly.

Note the absence of check or carry out rules - anyone can wait, at any time,
and it makes nothing happen."

Report an actor waiting (this is the standard report waiting rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Time [pass]." (A);
	otherwise:
		say "[The actor] [wait]." (B).

Touching is an action applying to one thing.
The touching action is accessible to Inter as "Touch".

The specification of the touching action is "Touching is just that, touching
something without applying pressure: a touch-sensitive screen or a living
creature might react, but a standard push-button or lever will probably not.

In the Standard Rules there are no check touching rules, since touchability
is already a requirement of the noun for the action anyway, and no carry out
rules because nothing in the standard Inform world model reacts to
a mere touch - though report rules do mean that attempts to touch other
people provoke a special reply."

Report an actor touching (this is the report touching yourself rule):
	if the noun is the actor:
		if the actor is the player:
			if the action is not silent:
				say "[We] [achieve] nothing by this." (A);
		otherwise:
			say "[The actor] [touch] [themselves]." (B);
		stop the action;
	continue the action.

Report an actor touching (this is the report touching other people rule):
	if the noun is a person:
		if the actor is the player:
			if the action is not silent:
				say "[The noun] [might not like] that." (A);
		otherwise if the noun is the player:
			say "[The actor] [touch] [us]." (B);
		otherwise:
			say "[The actor] [touch] [the noun]." (C);
		stop the action;
	continue the action.

Report an actor touching (this is the report touching things rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [feel] nothing unexpected." (A);
	otherwise:
		say "[The actor] [touch] [the noun]." (B).

Waving is an action applying to one thing.
The waving action is accessible to Inter as "Wave".

The specification of the waving action is "Waving in this sense is like
waving a sceptre: the item to be waved must be directly held (or worn)
by the actor.

In the Standard Rules there are no carry out rules for this action because
nothing in the standard Inform world model which reacts to it. The action
is provided for authors to hang more interesting behaviour onto for special
cases: say, waving a particular rusty iron rod with a star on the end."

Check an actor waving (this is the can't wave what's not held rule):
	if the actor is not the holder of the noun:
		if the actor is the player:
			say "But [we] [aren't] holding [regarding the noun][those]." (A);
		stop the action.

Report an actor waving (this is the report waving things rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [wave] [the noun]." (A);
	otherwise:
		say "[The actor] [wave] [the noun]." (B).

Pulling is an action applying to one thing.
The Pulling action is accessible to Inter as "Pull".

The specification of the pulling action is "Pulling is the act of pulling
something not grossly larger than the actor by an amount which would not
substantially move it.

In the Standard Rules there are no carry out rules for this action because
nothing in the standard Inform world model which reacts to it. The action
is provided for authors to hang more interesting behaviour onto for special
cases: say, pulling a lever. ('The big red lever is a fixed in place device.
Instead of pulling the big red lever, try switching on the lever. Instead
of pushing the big red lever, try switching off the lever.')"

Check an actor pulling (this is the can't pull what's fixed in place rule):
	if the noun is fixed in place:
		if the actor is the player:
			say "[regarding the noun][They] [are] fixed in place." (A);
		stop the action.

Check an actor pulling (this is the can't pull scenery rule):
	if the noun is scenery:
		if the actor is the player:
			say "[We] [are] unable to." (A);
		stop the action.

Check an actor pulling (this is the can't pull people rule):
	if the noun is a person:
		if the actor is the player:
			say "[The noun] [might not like] that." (A);
		stop the action.

Report an actor pulling (this is the report pulling rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Nothing obvious [happen]." (A);
	otherwise:
		say "[The actor] [pull] [the noun]." (B).

Pushing is an action applying to one thing.
The Pushing action is accessible to Inter as "Push".

The specification of the pushing action is "Pushing is the act of pushing
something not grossly larger than the actor by an amount which would not
substantially move it. (See also the pushing it to action, which involves
a longer-distance push between rooms.)

In the Standard Rules there are no carry out rules for this action because
nothing in the standard Inform world model which reacts to it. The action
is provided for authors to hang more interesting behaviour onto for special
cases: say, pulling a lever. ('The big red lever is a fixed in place device.
Instead of pulling the big red lever, try switching on the lever. Instead
of pushing the big red lever, try switching off the lever.')"

Check an actor pushing something (this is the can't push what's fixed in place rule):
	if the noun is fixed in place:
		if the actor is the player:
			say "[regarding the noun][They] [are] fixed in place." (A);
		stop the action.

Check an actor pushing something (this is the can't push scenery rule):
	if the noun is scenery:
		if the actor is the player:
			say "[We] [are] unable to." (A);
		stop the action.

Check an actor pushing something (this is the can't push people rule):
	if the noun is a person:
		if the actor is the player:
			say "[The noun] [might not like] that." (A);
		stop the action.

Report an actor pushing something (this is the report pushing rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Nothing obvious [happen]." (A);
	otherwise:
		say "[The actor] [push] [the noun]." (B).

Turning is an action applying to one thing.
The Turning action is accessible to Inter as "Turn".

The specification of the turning action is "Turning is the act of rotating
something - say, a dial.

In the Standard Rules there are no carry out rules for this action because
nothing in the standard Inform world model which reacts to it. The action
is provided for authors to hang more interesting behaviour onto for special
cases: say, turning a capstan."

Check an actor turning (this is the can't turn what's fixed in place rule):
	if the noun is fixed in place:
		if the actor is the player:
			say "[regarding the noun][They] [are] fixed in place." (A);
		stop the action.

Check an actor turning (this is the can't turn scenery rule):
	if the noun is scenery:
		if the actor is the player:
			say "[We] [are] unable to." (A);
		stop the action.

Check an actor turning (this is the can't turn people rule):
	if the noun is a person:
		if the actor is the player:
			say "[The noun] [might not like] that." (A);
		stop the action.

Report an actor turning (this is the report turning rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Nothing obvious [happen]." (A);
	otherwise:
		say "[The actor] [turn] [the noun]." (B).

Pushing it to is an action applying to one thing and one visible thing.
The Pushing it to action is accessible to Inter as "PushDir".

The specification of the pushing it to action is "This action covers pushing
a large object, not being carried, so that the actor pushes it from one room
to another: for instance, pushing a bale of hay to the east.

This is rapidly converted into a special form of the going action. If the
noun object has the either/or property 'pushable between rooms', then the
action is converted to going by the 'standard pushing in directions rule'.
If that going action succeeds, then the original pushing it to action
stops; it's only if that fails that we run on into the 'block pushing in
directions rule', which then puts an end to the matter."

Check an actor pushing something to (this is the can't push unpushable things rule):
	if the noun is not pushable between rooms:
		if the actor is the player:
			say "[The noun] [cannot] be pushed from place to place." (A);
		stop the action.

Check an actor pushing something to (this is the can't push to non-directions rule):
	if the second noun is not a direction:
		if the actor is the player:
			say "[regarding the noun][They] [aren't] a direction." (A);
		stop the action.

Check an actor pushing something to (this is the can't push vertically rule):
	if the second noun is up or the second noun is down:
		if the actor is the player:
			say "[The noun] [cannot] be pushed up or down." (A);
		stop the action.

Check an actor pushing something to (this is the can't push from within rule):
	if the noun encloses the actor:
		if the actor is the player:
			say "[The noun] [cannot] be pushed from [here]." (A);
		stop the action.

Check an actor pushing something to (this is the standard pushing in directions rule):
	convert to special going-with-push action.

Check an actor pushing something to (this is the block pushing in directions rule):
	if the actor is the player:
		say "[The noun] [cannot] be pushed from place to place." (A);
	stop the action.

Squeezing is an action applying to one thing.
The Squeezing action is accessible to Inter as "Squeeze".

The specification of the squeezing action is "Squeezing is an action which
can conveniently vary from squeezing something hand-held, like a washing-up
liquid bottle, right up to squeezing a pillar in a bear hug.

In the Standard Rules there are no carry out rules for this action because
nothing in the standard Inform world model which reacts to it. The action
is provided for authors to hang more interesting behaviour onto for special
cases. A mildly fruity message is produced to players who attempt to
squeeze people, which is blocked by a check squeezing rule."

Check an actor squeezing (this is the innuendo about squeezing people rule):
	if the noun is a person:
		if the actor is the player:
			say "[The noun] [might not like] that." (A);
		stop the action.

Report an actor squeezing (this is the report squeezing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [achieve] nothing by this." (A);
	otherwise:
		say "[The actor] [squeeze] [the noun]." (B).

Section 8 - Standard actions which always do nothing unless rules intervene

Saying yes is an action applying to nothing.
The Saying yes action is accessible to Inter as "Yes".

The specification of the saying yes action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor saying yes (this is the block saying yes rule):
	if the actor is the player:
		say "That was a rhetorical question." (A);
	stop the action.

Saying no is an action applying to nothing.
The Saying no action is accessible to Inter as "No".

The specification of the saying no action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor saying no (this is the block saying no rule):
	if the actor is the player:
		say "That was a rhetorical question." (A);
	stop the action.

Burning is an action applying to one thing.
The Burning action is accessible to Inter as "Burn".

The specification of the burning action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor burning (this is the block burning rule):
	if the actor is the player:
		say "This dangerous act [would achieve] little." (A);
	stop the action.

Waking up is an action applying to nothing.
The Waking up action is accessible to Inter as "Wake".

The specification of the waking up action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor waking up (this is the block waking up rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "The dreadful truth [are], this [are not] a dream." (A);
	stop the action.

Thinking is an action applying to nothing.
The Thinking action is accessible to Inter as "Think".

The specification of the thinking action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor thinking (this is the block thinking rule):
	if the actor is the player:
		say "What a good idea." (A);
	stop the action.

Smelling is an action applying to nothing or one thing.
The Smelling action is accessible to Inter as "Smell".

The specification of the smelling action is
"The Standard Rules define this action in only a minimal way, replying only
that the player smells nothing unexpected."

Report an actor smelling (this is the report smelling rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [smell] nothing unexpected." (A);
	otherwise:
		say "[The actor] [sniff]." (B).

Listening to is an action applying to nothing or one thing and abbreviable.
The Listening to action is accessible to Inter as "Listen".

The specification of the listening to action is
"The Standard Rules define this action in only a minimal way, replying only
that the player hears nothing unexpected."

Report an actor listening to (this is the report listening rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [hear] nothing unexpected." (A);
	otherwise:
		say "[The actor] [listen]." (B).

Tasting is an action applying to one thing.
The Tasting action is accessible to Inter as "Taste".

The specification of the tasting action is
"The Standard Rules define this action in only a minimal way, replying only
that the player tastes nothing unexpected."

Report an actor tasting (this is the report tasting rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [taste] nothing unexpected." (A);
	otherwise:
		say "[The actor] [taste] [the noun]." (B).

Cutting is an action applying to one thing.
The Cutting action is accessible to Inter as "Cut".

The specification of the cutting action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor cutting (this is the block cutting rule):
	if the actor is the player:
		say "Cutting [regarding the noun][them] up [would achieve] little." (A);
	stop the action.

Jumping is an action applying to nothing.
The Jumping action is accessible to Inter as "Jump".

The specification of the jumping action is
"The Standard Rules define this action in only a minimal way, simply reporting
a little jump on the spot."

Report an actor jumping (this is the report jumping rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [jump] on the spot." (A);
	otherwise:
		say "[The actor] [jump] on the spot." (B).

Tying it to is an action applying to two things.
The Tying it to action is accessible to Inter as "Tie".

The specification of the tying it to action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor tying something to (this is the block tying rule):
	if the actor is the player:
		say "[We] [would achieve] nothing by this." (A);
	stop the action.

Drinking is an action applying to one thing.
The Drinking action is accessible to Inter as "Drink".

The specification of the drinking action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor drinking (this is the block drinking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There's] nothing suitable to drink [here]." (A);
	stop the action.

Saying sorry is an action applying to nothing.
The Saying sorry action is accessible to Inter as "Sorry".

The specification of the saying sorry action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor saying sorry (this is the block saying sorry rule):
	if the actor is the player:
		say "Oh, don't [if American dialect option is
			active]apologize[otherwise]apologise[end if]." (A);
	stop the action.

Swinging is an action applying to one thing.
The Swinging action is accessible to Inter as "Swing".

The specification of the swinging action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor swinging (this is the block swinging rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There's] nothing sensible to swing [here]." (A);
	stop the action.

Rubbing is an action applying to one thing.
The Rubbing action is accessible to Inter as "Rub".

The specification of the rubbing action is
"The Standard Rules define this action in only a minimal way, simply reporting
that it has happened."

Check an actor rubbing (this is the can't rub another person rule):
	if the noun is a person who is not the actor:
		if the actor is the player:
			say "[The noun] [might not like] that." (A);
		stop the action.

Report an actor rubbing (this is the report rubbing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [rub] [the noun]." (A);
	otherwise:
		say "[The actor] [rub] [the noun]." (B).

Setting it to is an action applying to one thing and one topic.
The Setting it to action is accessible to Inter as "SetTo".

The specification of the setting it to action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor setting something to (this is the block setting it to rule):
	if the actor is the player:
		say "No, [we] [can't set] [regarding the noun][those] to anything." (A);
	stop the action.

Waving hands is an action applying to nothing.
The Waving hands action is accessible to Inter as "WaveHands".

The specification of the waving hands action is
"The Standard Rules define this action in only a minimal way, simply reporting
a little wave of the hands."

Report an actor waving hands (this is the report waving hands rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [wave]." (A);
	otherwise:
		say "[The actor] [wave]." (B).

Buying is an action applying to one thing.
The Buying action is accessible to Inter as "Buy".

The specification of the buying action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor buying (this is the block buying rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "Nothing [are] on sale." (A);
	stop the action.

Climbing is an action applying to one thing.
The Climbing action is accessible to Inter as "Climb".

The specification of the climbing action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor climbing (this is the block climbing rule):
	if the actor is the player:
		say "Little [are] to be achieved by that." (A);
	stop the action.

Sleeping is an action applying to nothing.
The Sleeping action is accessible to Inter as "Sleep".

The specification of the sleeping action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

Check an actor sleeping (this is the block sleeping rule):
	if the actor is the player:
		say "[We] [aren't] feeling especially drowsy." (A);
	stop the action.

Section 9 - Standard actions which happen out of world

Quitting the game is an action out of world and applying to nothing.
The quitting the game action is accessible to Inter as "Quit".

The quit the game rule is listed in the carry out quitting the game rulebook.
The quit the game rule is defined by Inter as "QUIT_THE_GAME_R" with
	"Are you sure you want to quit? " (A).

Saving the game is an action out of world and applying to nothing.
The saving the game action is accessible to Inter as "Save".

The save the game rule is listed in the carry out saving the game rulebook.
The save the game rule is defined by Inter as "SAVE_THE_GAME_R" with
	"Save failed." (A),
	"Ok." (B).

Restoring the game is an action out of world and applying to nothing.
The restoring the game action is accessible to Inter as "Restore".

The restore the game rule is listed in the carry out restoring the game rulebook.
The restore the game rule is defined by Inter as "RESTORE_THE_GAME_R" with
	"Restore failed." (A),
	"Ok." (B).

Restarting the game is an action out of world and applying to nothing.
The restarting the game action is accessible to Inter as "Restart".

The restart the game rule is listed in the carry out restarting the game rulebook.
The restart the game rule is defined by Inter as "RESTART_THE_GAME_R" with
	"Are you sure you want to restart? " (A),
	"Failed." (B).

Verifying the story file is an action out of world and applying to nothing.
The verifying the story file action is accessible to Inter as "Verify".

The verify the story file rule is listed in the carry out verifying the story file rulebook.
The verify the story file rule is defined by Inter as "VERIFY_THE_STORY_FILE_R" with
	"The game file has verified as intact." (A),
	"The game file did not verify as intact, and may be corrupt." (B).

Switching the story transcript on is an action out of world and applying to nothing.
The switching the story transcript on action is accessible to Inter as "ScriptOn".

The switch the story transcript on rule is listed in the carry out switching the story
	transcript on rulebook.
The switch the story transcript on rule is defined by Inter as "SWITCH_TRANSCRIPT_ON_R" with
    "Transcripting is already on." (A),
    "Start of a transcript of:" (B),
    "Attempt to begin transcript failed." (C).

Switching the story transcript off is an action out of world and applying to nothing.
The switching the story transcript off action is accessible to Inter as "ScriptOff".

The switch the story transcript off rule is listed in the carry out switching the story
	transcript off rulebook.
The switch the story transcript off rule is defined by Inter as "SWITCH_TRANSCRIPT_OFF_R" with
    "Transcripting is already off." (A),
    "[line break]End of transcript." (B),
    "Attempt to end transcript failed." (C).


Requesting the story file version is an action out of world and applying to nothing.
The requesting the story file version action is accessible to Inter as "Version".

The announce the story file version rule is listed in the carry out requesting the story
	file version rulebook.
The announce the story file version rule is defined by Inter as "ANNOUNCE_STORY_FILE_VERSION_R".


Requesting copyright licences is an action out of world and applying to nothing.
The requesting copyright licences action is accessible to Inter as "Copyright".

The announce the copyright licences rule is listed in the carry out requesting
	copyright licences rulebook.
The announce the copyright licences rule is defined by Inter as "ANNOUNCE_COPYRIGHT_LICENCES_R".

Requesting the score is an action out of world and applying to nothing.
The requesting the score action is accessible to Inter as "Score".

The announce the score rule is listed in the carry out requesting the score rulebook.
The announce the score rule is defined by Inter as "ANNOUNCE_SCORE_R" with
	"[if the story has ended]In that game you scored[otherwise]You have so far scored[end if]
	[score] out of a possible [maximum score], in [turn count] turn[s]" (A),
    ", earning you the rank of " (B),
	"[There] [are] no score in this story." (C),
	"[bracket]Your score has just gone up by [number understood in words]
		point[s].[close bracket]" (D),
	"[bracket]Your score has just gone down by [number understood in words]
		point[s].[close bracket]" (E).

Preferring abbreviated room descriptions is an action out of world and applying to nothing.
The preferring abbreviated room descriptions action is accessible to Inter as "LMode3".

The prefer abbreviated room descriptions rule is listed in the carry out preferring
	abbreviated room descriptions rulebook.
The prefer abbreviated room descriptions rule is defined by Inter as "PREFER_ABBREVIATED_R".

The standard report preferring abbreviated room descriptions rule is listed in the
	report preferring abbreviated room descriptions rulebook.
The standard report preferring abbreviated room descriptions rule is defined by
	Inter as "REP_PREFER_ABBREVIATED_R" with
	" is now in its 'superbrief' mode, which always gives short descriptions
	of locations (even if you haven't been there before)." (A).

Preferring unabbreviated room descriptions is an action out of world and applying to nothing.
The preferring unabbreviated room descriptions action is accessible to Inter as "LMode2".

The prefer unabbreviated room descriptions rule is listed in the carry out preferring
	unabbreviated room descriptions rulebook.
The prefer unabbreviated room descriptions rule is defined by Inter as "PREFER_UNABBREVIATED_R".

The standard report preferring unabbreviated room descriptions rule is listed in the
	report preferring unabbreviated room descriptions rulebook.
The standard report preferring unabbreviated room descriptions rule is defined by
	Inter as "REP_PREFER_UNABBREVIATED_R" with
	" is now in its 'verbose' mode, which always gives long descriptions of
	locations (even if you've been there before)." (A).

Preferring sometimes abbreviated room descriptions is an action out of world and
	applying to nothing.
The preferring sometimes abbreviated room descriptions action is accessible to Inter as "LMode1".

The prefer sometimes abbreviated room descriptions rule is listed in the carry out
	preferring sometimes abbreviated room descriptions rulebook.
The prefer sometimes abbreviated room descriptions rule is defined by Inter as
	"PREFER_SOMETIMES_ABBREVIATED_R".

The standard report preferring sometimes abbreviated room descriptions rule is listed
	in the report preferring sometimes abbreviated room descriptions rulebook.
The standard report preferring sometimes abbreviated room descriptions rule
	is defined by Inter as "REP_PREFER_SOMETIMES_ABBR_R" with
	" is now in its 'brief' printing mode, which gives long descriptions
    of places never before visited and short descriptions otherwise." (A).

Switching score notification on is an action out of world and applying to nothing.
The switching score notification on action is accessible to Inter as "NotifyOn".

The switch score notification on rule is listed in the carry out switching score
	notification on rulebook.
The switch score notification on rule is defined by Inter as "SWITCH_SCORE_NOTIFY_ON_R".

The standard report switching score notification on rule is listed in the report
	switching score notification on rulebook.
The standard report switching score notification on rule is defined by
	Inter as "REP_SWITCH_NOTIFY_ON_R" with "Score notification on." (A).

Switching score notification off is an action out of world and applying to nothing.
The switching score notification off action is accessible to Inter as "NotifyOff".

The switch score notification off rule is listed in the carry out switching score
	notification off rulebook.
The switch score notification off rule is defined by Inter as "SWITCH_SCORE_NOTIFY_OFF_R".

The standard report switching score notification off rule is listed in the report
	switching score notification off rulebook.
The standard report switching score notification off rule is defined by
	Inter as "REP_SWITCH_NOTIFY_OFF_R" with "Score notification off." (A).

Requesting the pronoun meanings is an action out of world and applying to nothing.
The requesting the pronoun meanings action is accessible to Inter as "Pronouns".

The announce the pronoun meanings rule is listed in the carry out requesting the
	pronoun meanings rulebook.
The announce the pronoun meanings rule is defined by Inter as "ANNOUNCE_PRONOUN_MEANINGS_R" with
	"At the moment, " (A),
	"means " (B),
	"is unset" (C),
	"no pronouns are known to the game." (D).

Part Six - Grammar

Understand "take [things]" as taking.
Understand "take off [something]" as taking off.
Understand "take [something] off" as taking off.
Understand "take [things inside] from [something]" as removing it from.
Understand "take [something] from [something]" as removing it from. [For better error messages.]
Understand "take [things inside] off [something]" as removing it from.
Understand "take [something] off [something]" as removing it from. [For better error messages.]
Understand "take inventory" as taking inventory.
Understand the commands "carry" and "hold" as "take".

Understand "get in/on" as entering.
Understand "get out/off/down/up" as exiting.
Understand "get [things]" as taking.
Understand "get in/into/on/onto [something]" as entering.
Understand "get off/down [something]" as getting off.
Understand "get [things inside] from [something]" as removing it from.
Understand "get [something] from [something]" as removing it from. [For better error messages.]

Understand "pick up [things]" or "pick [things] up" as taking.

Understand "stand" or "stand up" as exiting.
Understand "stand on [something]" as entering.

Understand "remove [something preferably held]" as taking off.
Understand "remove [things inside] from [something]" as removing it from.
Understand "remove [something] from [something]" as removing it from. [For better error messages.]

Understand "shed [something preferably held]" as taking off.
Understand the commands "doff" and "disrobe" as "shed".

Understand "wear [something preferably held]" as wearing.
Understand the command "don" as "wear".

Understand "put [other things] in/inside/into [something]" as inserting it into.
Understand "put [other things] on/onto [something]" as putting it on.
Understand "put on [something preferably held]" as wearing.
Understand "put [something preferably held] on" as wearing.
Understand "put down [things preferably held]" or "put [things preferably held] down" as dropping.

Understand "insert [other things] in/into [something]" as inserting it into.

Understand "drop [things preferably held]" as dropping.
Understand "drop [other things] in/into/down [something]" as inserting it into.
Understand "drop [other things] on/onto [something]" as putting it on.
Understand "drop [something preferably held] at/against [something]" as throwing it at.
Understand the commands "throw" and "discard" as "drop".

Understand "give [something preferably held] to [someone]" as giving it to.
Understand "give [someone] [something preferably held]" as giving it to (with nouns reversed).
Understand the commands "pay" and "offer" and "feed" as "give".

Understand "show [someone] [something preferably held]" as showing it to (with nouns reversed).
Understand "show [something preferably held] to [someone]" as showing it to.
Understand the commands "present" and "display" as "show".

Understand "go" as going.
Understand "go [direction]" as going.
Understand "go [something]" as entering.
Understand "go into/in/inside/through [something]" as entering.
Understand the commands "walk" and "run" as "go".

Understand "inventory" as taking inventory.
Understand the commands "i" and "inv" as "inventory".

Understand "look" as looking.
Understand "look at [something]" as examining.
Understand "look [something]" as examining.
Understand "look inside/in/into/through [something]" as searching.
Understand "look under [something]" as looking under.
Understand "look up [text] in [something]" as consulting it about (with nouns reversed).
Understand the command "l" as "look".

Understand "consult [something] on/about [text]" as consulting it about.

Understand "open [something]" as opening.
Understand "open [something] with [something preferably held]" as unlocking it with.
Understand the commands "unwrap", "uncover" as "open".

Understand "close [something]" as closing.
Understand "close up [something]" as closing.
Understand "close off [something]" as switching off.
Understand the commands "shut" and "cover" as "close".

Understand "enter" as entering.
Understand "enter [something]" as entering.
Understand the command "cross" as "enter".

Understand "sit on top of [something]" as entering.
Understand "sit on/in/inside [something]" as entering.

Understand "exit" as exiting.
Understand the commands "leave" and "out" as "exit".

Understand "examine [something]" as examining.
Understand the commands "x", "watch", "describe" and "check" as "examine".

Understand "read [something]" as examining.
Understand "read about [text] in [something]" as consulting it about (with nouns reversed).
Understand "read [text] in [something]" as consulting it about (with nouns reversed).

Understand "yes" as saying yes.
Understand the command "y" as "yes".

Understand "no" as saying no.

Understand "sorry" as saying sorry.

Understand "search [something]" as searching.

Understand "wave" as waving hands.

Understand "wave [something]" as waving.

Understand "set [something] to [text]" as setting it to.
Understand the command "adjust" as "set".

Understand "pull [something]" as pulling.
Understand the command "drag" as "pull".

Understand "push [something]" as pushing.
Understand "push [something] [direction]" or "push [something] to [direction]" as pushing it to.
Understand the commands "move", "shift", "clear" and "press" as "push".

Understand "turn [something]" as turning.
Understand "turn [something] on" or "turn on [something]" as switching on.
Understand "turn [something] off" or "turn off [something]" as switching off.
Understand the commands "rotate", "twist", "unscrew" and "screw" as "turn".

Understand "switch [something switched on]" as switching off.
Understand "switch [something]" or "switch on [something]" or "switch [something] on" as
	switching on.
Understand "switch [something] off" or "switch off [something]" as switching off.

Understand "lock [something] with [something preferably held]" as locking it with.

Understand "unlock [something] with [something preferably held]" as unlocking it with.

Understand "attack [something]" as attacking.
Understand the commands "break", "smash", "hit", "fight", "torture", "wreck", "crack", "destroy",
	"murder", "kill", "punch" and "thump" as "attack".

Understand "wait" as waiting.
Understand the command "z" as "wait".

Understand "answer [text] to [someone]" as answering it that (with nouns reversed).
Understand the commands "say", "shout" and "speak" as "answer".

Understand "tell [someone] about [text]" as telling it about.

Understand "ask [someone] about [text]" as asking it about.
Understand "ask [someone] for [something]" as asking it for.

Understand "eat [something preferably held]" as eating.

Understand "sleep" as sleeping.
Understand the command "nap" as "sleep".

Understand "climb [something]" or "climb up/over [something]" as climbing.
Understand the command "scale" as "climb".

Understand "buy [something]" as buying.
Understand the command "purchase" as "buy".

Understand "squeeze [something]" as squeezing.
Understand the command "squash" as "squeeze".

Understand "swing [something]" or "swing on [something]" as swinging.

Understand "wake" or "wake up" as waking up.
Understand "wake [someone]" or "wake [someone] up" or "wake up [someone]" as waking.
Understand the commands "awake" and "awaken" as "wake".

Understand "kiss [someone]" as kissing.
Understand the commands "embrace" and "hug" as "kiss".

Understand "think" as thinking.

Understand "smell" as smelling.
Understand "smell [something]" as smelling.
Understand the command "sniff" as "smell".

Understand "listen" as listening to.
Understand "hear [something]" as listening to.
Understand "listen to [something]" as listening to.

Understand "taste [something]" as tasting.

Understand "touch [something]" as touching.
Understand the command "feel" as "touch".

Understand "rub [something]" as rubbing.
Understand the commands "shine", "polish", "sweep", "clean", "dust", "wipe" and "scrub" as "rub".

Understand "tie [something] to [something]" as tying it to.
Understand the commands "attach" and "fasten" as "tie".

Understand "burn [something]" as burning.
Understand the command "light" as "burn".

Understand "drink [something]" as drinking.
Understand the commands "swallow" and "sip" as "drink".

Understand "cut [something]" as cutting.
Understand the commands "slice", "prune" and "chop" as "cut".

Understand "jump" as jumping.
Understand the commands "skip" and "hop" as "jump".

Understand "score" as requesting the score.
Understand "quit" or "q" as quitting the game.
Understand "save" as saving the game.
Understand "restart" as restarting the game.
Understand "restore" as restoring the game.
Understand "verify" as verifying the story file.
Understand "version" as requesting the story file version.
Understand "copyright" as requesting copyright licences.
Understand "script" or "script on" or "transcript" or "transcript on" as switching the story
	transcript on.
Understand "script off" or "transcript off" as switching the story transcript off.
Understand "superbrief" or "short" as preferring abbreviated room descriptions.
Understand "verbose" or "long" as preferring unabbreviated room descriptions.
Understand "brief" or "normal" as preferring sometimes abbreviated room descriptions.
Understand "nouns" or "pronouns" as requesting the pronoun meanings.
Understand "notify" or "notify on" as switching score notification on.
Understand "notify off" as switching score notification off.

Section 2 - Dialogue-related grammar (for dialogue language element only)

Understand "ask about [concept]" as talking about.
Understand "ask about [visible thing]" as talking about.
Understand "talk about [concept]" as talking about.
Understand "talk about [visible thing]" as talking about.

Part Seven - Phrasebook

Chapter 1 - Saying

Section 1 - Time Values

To say (something - time) in words
	(documented at phs_timewords):
	(- print (PrintTimeOfDayEnglish) {something}; -).
To say here
	(documented at phs_here):
	say "[if story tense is present tense]here[otherwise]there".
To say now
	(documented at phs_now):
	say "[if story tense is present tense]now[otherwise]then".

Section 2 - Boxed quotations

To display the/-- boxed quotation (Q - text)
	(documented at ph_boxed):
	(- DisplayBoxedQuotation({-box-quotation-text:Q}); -).

Section 3 - Some built-in texts

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

Section 4 - Responses

To say the/-- text of (R - response)
	(documented at phs_response):
	carry out the issuing the response text activity with R.

Section 5 - Saying lists of things

To list the/-- contents of (O - an object),
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

Section 6 - Group in and omit from lists

To group (OS - description of objects) together
	(documented at ph_group): (-
		objectloop({-my:1} provides list_together)
			if ({-matches-description:1:OS})
				CopyPV({-my:1}.list_together, {-list-together:unarticled});
	-).
To group (OS - description of objects) together giving articles
	(documented at ph_groupart): (-
		objectloop({-my:1} provides list_together)
			if ({-matches-description:1:OS})
				CopyPV({-my:1}.list_together, {-list-together:articled});
	-).
To group (OS - description of objects) together as (T - text)
	(documented at ph_grouptext): (-
		{-my:2} = CreatePV(TEXT_TY);
		{-my:2} = TEXT_TY_SubstitutedForm({-my:2}, {-by-reference:T});
		objectloop({-my:1} provides list_together)
			if ({-matches-description:1:OS})
				CopyPV({-my:1}.list_together, {-my:2});
		DestroyPV({-my:2});
	-).
To omit contents in listing
	(documented at ph_omit):
	(- c_style = c_style &~ (RECURSE_BIT+FULLINV_BIT+PARTINV_BIT); -).

Section 7 - Filtering contents of lists - Unindexed

To filter list recursion to (D - description of objects):
	(- list_filter_routine = {D}; -).
To unfilter list recursion:
	(- list_filter_routine = 0; -).

Chapter 2 - Multimedia

Section 1 - Figures (for figures language element only)

To display (F - figure name), one time only
	(documented at ph_displayfigure):
	(- DisplayFigure(ResourceIDsOfFigures-->{F}, {phrase options}); -).
To decide which number is the Glulx resource ID of (F - figure name)
	(documented at ph_figureid):
	(- ResourceIDsOfFigures-->{F} -).

Section 2 - Sound effects (for sounds language element only)

To play (SFX - sound name), one time only
	(documented at ph_playsf):
	(- PlaySound(ResourceIDsOfSounds-->{SFX}, {phrase options}); -).
To decide which number is the Glulx resource ID of (SFX - sound name)
	(documented at ph_soundid):
	(- ResourceIDsOfSounds-->{SFX} -).

Chapter 3 - Actions, activities and rules

Section 1 - Trying actions

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

Section 2 - Action requirements

To decide whether the action requires a/-- touchable noun
	(documented at ph_requirestouch):
	(- (NeedToTouchNoun()) -).
To decide whether the action requires a/-- touchable second noun
	(documented at ph_requirestouch2):
	(- (NeedToTouchSecondNoun()) -).
To decide whether the action requires a/-- carried noun
	(documented at ph_requirescarried):
	(- (NeedToCarryNoun()) -).
To decide whether the action requires a/-- carried second noun
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

Section 3 - Stop or continue

To stop the/-- action
	(documented at ph_stopaction):
	(- rtrue; -) - in to only.
To continue the/-- action
	(documented at ph_continueaction):
	(- rfalse; -) - in to only.

Section 4 - Actions as values

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

Chapter 4 - The Model World

Section 1 - Ending the story

To end the/-- story
	(documented at ph_end):
	(- deadflag=3; story_complete=false; -).
To end the/-- story finally
	(documented at ph_endfinally):
	(- deadflag=3; story_complete=true; -).
To end the/-- story saying (finale - text)
	(documented at ph_endsaying):
	(- deadflag={-by-reference:finale}; BlkValueIncRefCountPrimitive(deadflag); story_complete=false; -).
To end the/-- story finally saying (finale - text)
	(documented at ph_endfinallysaying):
	(- deadflag={-by-reference:finale}; BlkValueIncRefCountPrimitive(deadflag); story_complete=true; -).
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
To resume the/-- story
	(documented at ph_resume):
	(- resurrect_please = true; -).

Section 2 - Times of day

To decide which number is the minutes part of (t - time)
	(documented at ph_minspart):
	(- ({t}%ONE_HOUR) -).
To decide which number is the hours part of (t - time)
	(documented at ph_hourspart):
	(- ({t}/ONE_HOUR) -).

To decide if (t - time) is before (t2 - time)
	(documented at ph_timebefore):
	(- ((({t}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))<(({t2}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))) -).
To decide if (t - time) is after (t2 - time)
	(documented at ph_timeafter):
	(- ((({t}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))>(({t2}+20*ONE_HOUR)%(TWENTY_FOUR_HOURS))) -).
To decide which time is (t - time period) before (t2 - time)
	(documented at ph_shiftbefore):
	(- (({t2}-{t}+TWENTY_FOUR_HOURS)%(TWENTY_FOUR_HOURS)) -).
To decide which time is (t - time period) after (t2 - time)
	(documented at ph_shiftafter):
	(- (({t2}+{t}+TWENTY_FOUR_HOURS)%(TWENTY_FOUR_HOURS)) -).

Section 3 - Durations

To decide which time period is (n - number) minutes
	(documented at ph_durationmins):
	(- ({n}) -).
To decide which time period is (n - number) hours
	(documented at ph_durationhours):
	(- ({n}*ONE_HOUR) -).
To decide which time period is (n - number) hours (m - number) minutes
	(documented at ph_durationhours):
	(- ({n}*ONE_HOUR + {m}) -).

Section 4 - Timed events

To (R - rule) in (t - number) turn/turns from now
	(documented at ph_turnsfromnow):
	(- SetTimedEvent({-mark-event-used:R}, {t}+1, 0); -).
To (R - rule) at (t - time)
	(documented at ph_attime):
	(- SetTimedEvent({-mark-event-used:R}, {t}, 1); -).
To (R - rule) in (t - time period) from now
	(documented at ph_timefromnow):
	(- SetTimedEvent({-mark-event-used:R}, (the_time+{t})%(TWENTY_FOUR_HOURS), 1); -).

Section 5 - Scenes

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

Section 6 - Timing of scenes

To decide which time period is the time since (sc - scene) began
	(documented at ph_scenetimesincebegan):
	(- (SceneUtility({sc}, 1)) -).
To decide which time is the time when (sc - scene) began
	(documented at ph_scenetimewhenbegan):
	(- (SceneUtility({sc}, 2)) -).
To decide which time period is the time since (sc - scene) ended
	(documented at ph_scenetimesinceended):
	(- (SceneUtility({sc}, 3)) -).
To decide which time is the time when (sc - scene) ended
	(documented at ph_scenetimewhenended):
	(- (SceneUtility({sc}, 4)) -).

Section 7 - Player's identity and location

To decide whether in darkness
	(documented at ph_indarkness):
	(- (location==thedark) -).

Section 8 - Moving and removing things

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

Section 9 - The map

To decide which room is location of (O - object)
	(documented at ph_locationof):
	(- LocationOf({O}) -).
To decide which room is room (D - direction) from/of (R1 - room)
	(documented at ph_roomdirof):
	(- MapConnection({R1},{D}) -).
To decide which door is door (D - direction) from/of (R1 - room)
	(documented at ph_doordirof):
	(- DoorFrom({R1},{D}) -).
To decide which object is the other side of (D - door)
	(documented at ph_othersideof):
	(- OtherSideOfDoor({D}, location) -).
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

Section 10 - Route-finding

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

Section 11 - The object tree

To decide which object is holder of (something - object)
	(documented at ph_holder):
	(- (HolderOf({something})) -).
To decide which object is next thing held after (something - object)
	(documented at ph_nextheld):
	(- (sibling({something})) -).
To decide which object is first thing held by (something - object)
	(documented at ph_firstheld):
	(- (child({something})) -).

Chapter 5 - Understanding

Section 1 - Asking yes/no questions

To decide whether player consents
	(documented at ph_consents):
		(- YesOrNo() -).

To decide what number is a/-- number chosen by the player from 1 to (N - number)
	(documented at ph_numberchosen):
		(- NumberChosenByPlayer({N}) -).

Section 2 - The player's command

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

Section 3 - Changing the player's command

To change the text of the/-- player's command to (T - text)
	(documented at ph_changecommand):
	(- SetPlayersCommand({-by-reference:T}); -).
To replace (S - a snippet) with (T - text)
	(documented at ph_replacesnippet):
	(- SpliceSnippet({S}, {-by-reference:T}); -).
To cut (S - a snippet)
	(documented at ph_cutsnippet):
	(- SpliceSnippet({S}, 0); -).
To reject the/-- player's command
	(documented at ph_rejectcommand):
	(- RulebookFails(); rtrue; -) - in to only.

Section 4 - Scope and pronouns

To place (O - an object) in scope, but not its contents
	(documented at ph_placeinscope):
	(- PlaceInScope({O}, {phrase options}); -).
To place the/-- contents of (O - an object) in scope
	(documented at ph_placecontentsinscope):
	(- ScopeWithin({O}); -).
To set pronouns from (O - an object)
	(documented at ph_setpronouns):
	(- PronounNotice({O}); -).

Section 5 - The multiple object list

To decide what list of objects is the multiple object list
	(documented at ph_multipleobjectlist):
	(- LIST_OF_TY_Mol({-new:list of objects}) -).
To alter the/-- multiple object list to (L - list of objects)
	(documented at ph_altermultipleobjectlist):
	(- LIST_OF_TY_Set_Mol({-by-reference:L}); -).

Section SR5/8/1 - Message support - Issuance - Unindexed

To issue score notification message:
	(- NotifyTheScore(); -).
To say pronoun dictionary word:
	(- print (address) pronoun_word; -).
To say recap of command:
	(- PrintCommand(); -).
The pronoun reference object is an object that varies.
The pronoun reference object variable is defined by Inter as "pronoun_obj".

To say pronoun i6 dictionary word:
	(- print (address) pronoun_word; -).

To say parser command so far:
	(- PrintCommand(); -).

Chapter 6 - Deprecated or private phrases - Unindexed

Section 1 - Spatial modelling - Unindexed

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

To decide which number is the visibility ceiling count calculated:
	(- visibility_levels -).
To decide which object is the visibility ceiling calculated:
	(- visibility_ceiling -).

Section 2 - Room descriptions - Unindexed

To produce a room description with going spacing conventions:
	(- LookAfterGoing(); -).

To print the location's description:
	(- PrintOrRun(location, description); -).

To decide if set to sometimes abbreviated room descriptions:
	(- (lookmode == 1) -).
To decide if set to unabbreviated room descriptions:
	(- (lookmode == 2) -).
To decide if set to abbreviated room descriptions:
	(- (lookmode == 3) -).

Section 3 - Action conversion - Unindexed

To convert to (AN - an action name) on (O - an object):
	(- return GVS_Convert({AN},{O},0); -) - in to only.
To convert to (AN - an action name) on (O - an object) with (T - a snippet):
	(- return GVS_Convert({AN},{O},{T}); -) - in to only.
To convert to request of (X - object) to perform (AN - action name) with
	(Y - object) and (Z - object):
	(- return ConvertToRequest({X}, {AN}, {Y}, {Z}); -).
To convert to special going-with-push action:
	(- return ConvertToGoingWithPush(); -).
To decide whether the action makes a request:
	(- (act_requester) -).

Section 4 - Surreptitious violation of invariants - Unindexed

To surreptitiously move (something - object) to (something else - object):
	(- move {something} to {something else}; -).
To surreptitiously move (something - object) to (something else - object) during going:
	(- MoveDuringGoing({something}, {something else}); -).
To surreptitiously reckon darkness:
	(- SilentlyConsiderLight(); -).

Section 5 - Capitalised list-writing - Unindexed

To say list-writer list of marked objects: (-
	 	WriteListOfMarkedObjects(ENGLISH_BIT);
	-).
To say list-writer articled list of marked objects: (-
	 	WriteListOfMarkedObjects(ENGLISH_BIT+DEFART_BIT+CFIRSTART_BIT);
	-).

Section 6 - Printing names - Unindexed

To decide if expanding text for comparison purposes:
	(- say__comp -).

Section 7 - Command parsing - Unindexed

To decide whether the I6 parser is running multiple actions:
	(- (multiflag==1) -).

Section 8 - Deprecated Inform - unindexed

To yes
	(documented at ph_yes):
	(- rtrue; -) - in to decide if only.
To no
	(documented at ph_no):
	(- rfalse; -) - in to decide if only.

Section 9 - Debugging Inform - Unindexed

To ***:
	(- {-primitive-definition:verbose-checking} -).
To *** (T - text):
	(- {-primitive-definition:verbose-checking} -).

The Standard Rules end here.

