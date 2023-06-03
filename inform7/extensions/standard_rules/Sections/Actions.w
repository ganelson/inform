Actions.

The standard stock of actions, along with the rules which define them; and
the command grammar which requests them.

@ Inform comes with no actions built in, and Basic Inform defines none either.
The compiler makes only one (perhaps unexpected) assumption: that the 8th
action defined is "going".

The order, and the subheadings, here are responsible for the order
and subheadings used in the Actions page of the Index.

=

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

@h Taking inventory.

=
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

@ There used to be a rule, documented here, to do with pronouns, and
this was explained in terms of Missee Lee, a black and white cat
living in North Oxford; named for a Cambridge-educated pirate queen in
the South China seas who is the heroine -- or villainess -- of the
tenth in Arthur Ransome's Swallows and Amazons series of children's
books, "Missee Lee" (1941). The rule was then removed, but it
seemed sad to delete the only mention of Missee, and all the more so
since she died (at a grand old age and in mid-spring) in 2008.

@ Carry out.

=
Carry out taking inventory (this is the print empty inventory rule):
	if the first thing held by the player is nothing,
		say "[We] [are] carrying nothing." (A) instead.

Carry out taking inventory (this is the print standard inventory rule):
	say "[We] [are] carrying:[line break]" (A);
	now all things enclosed by the player are unmarked for listing;
	now all things held by the player are marked for listing;
	list the contents of the player, with newlines, indented, giving inventory information, with extra indentation, listing marked items only, not listing concealed items, including contents.

@ Report.

=
Report an actor taking inventory (this is the report other people taking
	inventory rule):
	if the actor is not the player and the action is not silent:
		say "[The actor] [look] through [their] possessions." (A);

@h Taking.

=
Taking is an action applying to one thing.
The taking action is accessible to Inter as "Take".

The specification of the taking action is "The taking action is the only way
an action in the Standard Rules can cause something to be carried by an actor.
It is very simple in operation (the entire carry out stage consists only of
'now the actor carries the noun') but many checks must be performed before it
can be allowed to happen."

@ Check.

=
Check an actor taking (this is the can't take yourself rule):
	if the actor is the noun:
		if the actor is the player, say "[We] [are] always self-possessed." (A);
		stop the action.

Check an actor taking (this is the can't take other people rule):
	if the noun is a person:
		if the actor is the player, say "I don't suppose [the noun] [would care] for that." (A);
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

Check an actor taking (this is the can't take items out of play rule):
	let H be the noun;
	while H is not nothing and H is not a room:
		let H be the not-counting-parts holder of H;
	if H is nothing:
		if the actor is the player:
			say "[regarding the noun][Those] [aren't] available." (A);
		stop the action.

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

Check an actor taking (this is the can only take things rule):
	if the noun is not a thing:
		if the actor is the player:
			say "[We] [cannot] carry [the noun]." (A);
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

@ Carry out.

=
Carry out an actor taking (this is the standard taking rule):
	now the actor carries the noun;
	if the actor is the player, now the noun is handled.

@ Report.

=
Report an actor taking (this is the standard report taking rule):
	if the action is not silent:
		if the actor is the player:
			say "Taken." (A);
		otherwise:
			say "[The actor] [pick] up [the noun]." (B).

@h Removing it from.

=
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

@ Check.

=
Check an actor removing something from (this is the can't remove what's not inside rule):
	if the holder of the noun is not the second noun:
		if the actor is the player:
			say "But [regarding the noun][they] [aren't] there now." (A);
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

@h Dropping.

=
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

@ Check.

=
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
			say "[The noun] [are] already here." (A);
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

@ Carry out.

=
Carry out an actor dropping (this is the standard dropping rule):
	now the noun is held by the holder of the actor.

@ Report.

=
Report an actor dropping (this is the standard report dropping rule):
	if the action is not silent:
	 	if the actor is the player:
			say "Dropped." (A);
		otherwise:
			say "[The actor] [put] down [the noun]." (B);

@h Putting it on.

=
Putting it on is an action applying to two things.
The putting it on action is accessible to Inter as "PutOn".

The specification of the putting it on action is "By this action, an actor puts
something he is holding on top of a supporter: for instance, putting an apple
on a table."

@ Check.

=
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

@ Carry out.

=
Carry out an actor putting something on (this is the standard putting rule):
	now the noun is on the second noun.

@ Report.

=
Report an actor putting something on (this is the concise report putting rule):
	if the action is not silent:
		if the actor is the player and the I6 parser is running multiple actions:
			say "Done." (A);
			stop the action;
	continue the action.

Report an actor putting something on (this is the standard report putting rule):
	if the action is not silent:
		say "[The actor] [put] [the noun] on [the second noun]." (A).

@h Inserting it into.

=
Inserting it into is an action applying to two things.
The inserting it into action is accessible to Inter as "Insert".

The specification of the inserting it into action is "By this action, an actor puts
something he is holding into a container: for instance, putting a coin into a
collection box."

@ Check.

=
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

@ Carry out.

=
Carry out an actor inserting something into (this is the standard inserting rule):
	now the noun is in the second noun.

@ Report.

=
Report an actor inserting something into (this is the concise report inserting rule):
	if the action is not silent:
		if the actor is the player and the I6 parser is running multiple actions:
			say "Done." (A);
			stop the action;
	continue the action.

Report an actor inserting something into (this is the standard report inserting rule):
	if the action is not silent:
		say "[The actor] [put] [the noun] into [the second noun]." (A).

@h Eating.

=
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor eating (this is the standard eating rule):
	now the noun is nowhere.

@ Report.

=
Report an actor eating (this is the standard report eating rule):
	if the action is not silent:
		if the actor is the player:
			say "[We] [eat] [the noun]. Not bad." (A);
		otherwise:
			say "[The actor] [eat] [the noun]." (B).

@h Going.

=
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

@ Check.

=
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

@ Carry out.

=
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

@ Report.

=
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

@h Entering.

=
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor entering (this is the standard entering rule):
	surreptitiously move the actor to the noun.

@ Report.

=
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

@h Exiting.

=
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor exiting (this is the standard exiting rule):
	let the former exterior be the not-counting-parts holder of the container exited from;
	surreptitiously move the actor to the former exterior.

@ Report.

=
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

@h Getting off.

=
Getting off is an action applying to one thing.
The getting off action is accessible to Inter as "GetOff".

The specification of the getting off action is "The getting off action is for
actors who are currently on top of a supporter: perhaps standing on a platform,
but maybe only sitting on a chair or even lying down in bed. Unlike the similar
exiting action, getting off takes a noun: the platform, chair, bed or what
have you."

@ Check.

=
Check an actor getting off (this is the can't get off things rule):
	if the actor is on the noun, continue the action;
	if the actor is carried by the noun, continue the action;
	if the actor is the player:
		say "But [we] [aren't] on [the noun] at the [if story tense is present
			tense]moment[otherwise]time[end if]." (A);
	stop the action.

@ Carry out.

=
Carry out an actor getting off (this is the standard getting off rule):
	let the former exterior be the not-counting-parts holder of the noun;
	surreptitiously move the actor to the former exterior.

@ Report.

=
Report an actor getting off (this is the standard report getting off rule):
	if the action is not silent:
		say "[The actor] [get] off [the noun]." (A);
	continue the action.

Report an actor getting off (this is the describe room stood up into rule):
	if the actor is the player,
		produce a room description with going spacing conventions.

@h Looking.

=
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

@ Carry out.

=
Carry out looking (this is the declare everything unmentioned rule):
	repeat with item running through things:
		now the item is not mentioned.

Carry out looking (this is the room description heading rule):
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

@ Report.

=
Report an actor looking (this is the other people looking rule):
	if the actor is not the player:
		say "[The actor] [look] around." (A).

@h Examining.

=
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

@ Carry out.

=
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

@ Report.

=
Report an actor examining (this is the report other people examining rule):
	if the actor is not the player:
		say "[The actor] [look] closely at [the noun]." (A).

@h Looking under.

=
Looking under is an action applying to one visible thing and requiring light.
The looking under action is accessible to Inter as "LookUnder".

The specification of the looking under action is "The standard Inform world
model does not have a concept of things being under other things, so this
action is only minimally provided by the Standard Rules, but it exists here
for traditional reasons (and because, after all, LOOK UNDER TABLE is the
sort of command which ought to be recognised even if it does nothing useful).
The action ordinarily either tells the player he finds nothing of interest,
or reports that somebody else has looked under something.

The usual way to make this action do something useful is to write a rule
like 'Instead of looking under the cabinet for the first time: now the
player has the silver key; say ...' and so on."

@ Carry out.

=
Carry out an actor looking under (this is the standard looking under rule):
	if the player is the actor:
		say "[We] [find] nothing of interest." (A);
	stop the action.

@ Report.

=
Report an actor looking under (this is the report other people looking under rule):
	if the action is not silent:
		if the actor is not the player:
			say "[The actor] [look] under [the noun]." (A).

@h Searching.

=
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

@ Check.

=
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

@ Report.

=
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

@h Consulting it about.

=
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

@ Report.

=
Report an actor consulting something about (this is the block consulting rule):
	if the actor is the player:
		say "[We] [discover] nothing of interest in [the noun]." (A);
	otherwise:
		say "[The actor] [look] at [the noun]." (B);

@h Locking it with.

=
Section 5 - Standard actions which change the state of things

Locking it with is an action applying to one thing and one carried thing.
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor locking something with (this is the standard locking rule):
	now the noun is locked.

@ Report.

=
Report an actor locking something with (this is the standard report locking rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [lock] [the noun]." (A);
	otherwise:
		if the actor is visible:
			say "[The actor] [lock] [the noun]." (B);

@h Unlocking it with.

=
Unlocking it with is an action applying to one thing and one carried thing.
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor unlocking something with (this is the standard unlocking rule):
	now the noun is not locked.

@ Report.

=
Report an actor unlocking something with (this is the standard report unlocking rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [unlock] [the noun]." (A);
	otherwise:
		if the actor is visible:
			say "[The actor] [unlock] [the noun]." (B);

@h Switching on.

=
Switching on is an action applying to one thing.
The switching on action is accessible to Inter as "SwitchOn".

The specification of the switching on action is "The switching on and switching
off actions are for the simplest kind of machinery operation: they are for
objects representing machines (or more likely parts of machines), which are
considered to be either off or on at any given time.

The actions are intended to be used where the noun is a device, but in fact
they could work just as well with any kind which can be 'switched on' or
'switched off'."

@ Check.

=
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

@ Carry out.

=
Carry out an actor switching on (this is the standard switching on rule):
	now the noun is switched on.

@ Report.

=
Report an actor switching on (this is the standard report switching on rule):
	if the action is not silent:
		say "[The actor] [switch] [the noun] on." (A).

@h Switching off.

=
Switching off is an action applying to one thing.
The switching off action is accessible to Inter as "SwitchOff".

The specification of the switching off action is "The switching off and switching
on actions are for the simplest kind of machinery operation: they are for
objects representing machines (or more likely parts of machines), which are
considered to be either off or on at any given time.

The actions are intended to be used where the noun is a device, but in fact
they could work just as well with any kind which can be 'switched on' or
'switched off'."

@ Check.

=
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

@ Carry out.

=
Carry out an actor switching off (this is the standard switching off rule):
	now the noun is switched off.

@ Report.

=
Report an actor switching off (this is the standard report switching off rule):
	if the action is not silent:
		say "[The actor] [switch] [the noun] off." (A).

@h Opening.

=
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor opening (this is the standard opening rule):
	now the noun is open.

@ Report.

=
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

@h Closing.

=
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor closing (this is the standard closing rule):
	now the noun is closed.

@ Report.

=
Report an actor closing (this is the standard report closing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [close] [the noun]." (A);
	otherwise if the player can see the actor:
		say "[The actor] [close] [the noun]." (B);
	otherwise:
		say "[The noun] [close]." (C);

@h Wearing.

=
Wearing is an action applying to one carried thing.
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

@ Check.

=
Check an actor wearing (this is the can't wear what's not clothing rule):
	if the noun is not a thing or the noun is not wearable:
		if the actor is the player:
			say "[We] [can't wear] [regarding the noun][those]!" (A);
		stop the action.

Check an actor wearing (this is the can't wear what's not held rule):
	if the holder of the noun is not the actor:
		if the actor is the player:
			say "[We] [aren't] holding [regarding the noun][those]!" (A);
		stop the action.

Check an actor wearing (this is the can't wear what's already worn rule):
	if the actor is wearing the noun:
		if the actor is the player:
			say "[We]['re] already wearing [regarding the noun][those]!" (A);
		stop the action.

@ Carry out.

=
Carry out an actor wearing (this is the standard wearing rule):
	now the actor wears the noun.

@ Report.

=
Report an actor wearing (this is the standard report wearing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [put] on [the noun]." (A);
	otherwise:
		say "[The actor] [put] on [the noun]." (B).

@h Taking off.

=
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

@ Check.

=
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

@ Carry out.

=
Carry out an actor taking off (this is the standard taking off rule):
	now the actor carries the noun.

@ Report.

=
Report an actor taking off (this is the standard report taking off rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [take] off [the noun]." (A);
	otherwise:
		say "[The actor] [take] off [the noun]." (B).

@h Giving it to.

=
Section 6 - Standard actions concerning other people

Giving it to is an action applying to one carried thing and one thing.
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

@ Check.

=
Check an actor giving something to (this is the can't give what you haven't got rule):
	if the actor is not the holder of the noun:
		if the actor is the player:
			say "[We] [aren't] holding [the noun]." (A);
		stop the action.

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

@ Carry out.

=
Carry out an actor giving something to (this is the standard giving rule):
	move the noun to the second noun.

@ Report.

=
Report an actor giving something to (this is the standard report giving rule):
	if the actor is the player:
		say "[We] [give] [the noun] to [the second noun]." (A);
	otherwise if the second noun is the player:
		say "[The actor] [give] [the noun] to [us]." (B);
	otherwise:
		say "[The actor] [give] [the noun] to [the second noun]." (C).

@h Showing it to.

=
Showing it to is an action applying to one carried thing and one visible thing.
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

@ Check.

=
Check an actor showing something to (this is the can't show what you haven't
	got rule):
	if the actor is not the holder of the noun:
		if the actor is the player:
			say "[We] [aren't] holding [the noun]." (A);
		stop the action.

Check an actor showing something to (this is the convert show to yourself to
	examine rule):
	if the actor is the second noun:
		convert to the examining action on the noun.

Check an actor showing something to (this is the block showing rule):
	if the actor is the player:
		say "[The second noun] [are] unimpressed." (A);
	stop the action.

@h Waking.

=
Waking is an action applying to one thing.
The waking action is accessible to Inter as "WakeOther".

The specification of the waking action is "This is the act of jostling
a sleeping person to wake him or her up, and it finds its way into the
Standard Rules only for historical reasons. Inform does not by default
provide any model for people being asleep or awake, so this action does
not do anything in the standard implementation: instead, it is always
stopped by the block waking rule."

@ Check.

=
Check an actor waking (this is the block waking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "That [seem] unnecessary." (A);
	stop the action.

@h Throwing it at.

=
Throwing it at is an action applying to one carried thing and one visible thing.
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

@ Check.

=
Check an actor throwing something at (this is the implicitly remove thrown clothing rule):
	if the actor is wearing the noun:
		say "(first taking [the noun] off)[command clarification break]" (A);
		silently try the actor trying taking off the noun;
		if the actor is wearing the noun, stop the action;

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

@h Attacking.

=
Attacking is an action applying to one thing.
The attacking action is accessible to Inter as "Attack".

The specification of the attacking action is "Violence is seldom the answer,
and attempts to attack another person are normally blocked as being unrealistic
or not seriously meant. (I might find a shop assistant annoying, but IF is
not Grand Theft Auto, and responding by killing him is not really one of
my options.) So the Standard Rules simply block attempts to fight people,
but the action exists for rules to make exceptions."

@ Check.

=
Check an actor attacking (this is the block attacking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "Violence [aren't] the answer to this one." (A);
	stop the action.

@h Kissing.

=
Kissing is an action applying to one thing.
The kissing action is accessible to Inter as "Kiss".

The specification of the kissing action is "Possibly because Inform was
originally written by an Englishman, attempts at kissing another person are
normally blocked as being unrealistic or not seriously meant. So the
Standard Rules simply block attempts to kiss people, but the action exists
for rules to make exceptions."

@ Check.

=
Check an actor kissing (this is the kissing yourself rule):
	if the noun is the actor:
		if the actor is the player:
			say "[We] [don't] get much from that." (A);
		stop the action.

Check an actor kissing (this is the block kissing rule):
	if the actor is the player:
		say "[The noun] [might not] like that." (A);
	stop the action.

@h Answering it that.

=
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

@ Report.

=
Report an actor answering something that (this is the block answering rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There] [are] no reply." (A);
	stop the action.

@h Telling it about.

=
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

@ Check.

=
Check an actor telling something about (this is the telling yourself rule):
	if the actor is the noun:
		if the actor is the player:
			say "[We] [talk] to [ourselves] a while." (A);
		stop the action.

@ Report.

=
Report an actor telling something about (this is the block telling rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "This [provoke] no reaction." (A);
	stop the action.

@h Asking it about.

=
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

@ Report.

=
Report an actor asking something about (this is the block asking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There] [are] no reply." (A);
	stop the action.

@h Asking it for.

=
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

@ Check.

=
Check an actor asking something for (this is the asking yourself for something rule):
	if the actor is the noun and the actor is the player:
		try taking inventory instead.

Check an actor asking something for (this is the translate asking for to giving rule):
	convert to request of the noun to perform giving it to action with the second noun and the actor.

@h Waiting.

=
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

@ Report.

=
Report an actor waiting (this is the standard report waiting rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Time [pass]." (A);
	otherwise:
		say "[The actor] [wait]." (B).

@h Touching.

=
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

@ Report.

=
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

@h Waving.

=
Waving is an action applying to one thing.
The waving action is accessible to Inter as "Wave".

The specification of the waving action is "Waving in this sense is like
waving a sceptre: the item to be waved must be directly held (or worn)
by the actor.

In the Standard Rules there are no carry out rules for this action because
nothing in the standard Inform world model which reacts to it. The action
is provided for authors to hang more interesting behaviour onto for special
cases: say, waving a particular rusty iron rod with a star on the end."

@ Check.

=
Check an actor waving (this is the can't wave what's not held rule):
	if the actor is not the holder of the noun:
		if the actor is the player:
			say "But [we] [aren't] holding [regarding the noun][those]." (A);
		stop the action.

@ Report.

=
Report an actor waving (this is the report waving things rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [wave] [the noun]." (A);
	otherwise:
		say "[The actor] [wave] [the noun]." (B).

@h Pulling.

=
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

@ Check.

=
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

@ Report.

=
Report an actor pulling (this is the report pulling rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Nothing obvious [happen]." (A);
	otherwise:
		say "[The actor] [pull] [the noun]." (B).

@h Pushing.

=
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

@ Check.

=
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

@ Report.

=
Report an actor pushing something (this is the report pushing rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Nothing obvious [happen]." (A);
	otherwise:
		say "[The actor] [push] [the noun]." (B).

@h Turning.

=
Turning is an action applying to one thing.
The Turning action is accessible to Inter as "Turn".

The specification of the turning action is "Turning is the act of rotating
something - say, a dial.

In the Standard Rules there are no carry out rules for this action because
nothing in the standard Inform world model which reacts to it. The action
is provided for authors to hang more interesting behaviour onto for special
cases: say, turning a capstan."

@ Check.

=
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

@ Report.

=
Report an actor turning (this is the report turning rule):
	if the actor is the player:
		if the action is not silent:
			now the prior named object is nothing;
			say "Nothing obvious [happen]." (A);
	otherwise:
		say "[The actor] [turn] [the noun]." (B).

@h Pushing it to.

=
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

@ Check.

=
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
			say "[The noun] [cannot] be pushed from here." (A);
		stop the action.

Check an actor pushing something to (this is the standard pushing in directions rule):
	convert to special going-with-push action.

Check an actor pushing something to (this is the block pushing in directions rule):
	if the actor is the player:
		say "[The noun] [cannot] be pushed from place to place." (A);
	stop the action.

@h Squeezing.

=
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

@ Check.

=
Check an actor squeezing (this is the innuendo about squeezing people rule):
	if the noun is a person:
		if the actor is the player:
			say "[The noun] [might not like] that." (A);
		stop the action.

@ Report.

=
Report an actor squeezing (this is the report squeezing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [achieve] nothing by this." (A);
	otherwise:
		say "[The actor] [squeeze] [the noun]." (B).

@h Saying yes.

=
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

@ Check.

=
Check an actor saying yes (this is the block saying yes rule):
	if the actor is the player:
		say "That was a rhetorical question." (A);
	stop the action.

@ Saying no.

=
Saying no is an action applying to nothing.
The Saying no action is accessible to Inter as "No".

The specification of the saying no action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor saying no (this is the block saying no rule):
	if the actor is the player:
		say "That was a rhetorical question." (A);
	stop the action.

@h Burning.

=
Burning is an action applying to one thing.
The Burning action is accessible to Inter as "Burn".

The specification of the burning action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor burning (this is the block burning rule):
	if the actor is the player:
		say "This dangerous act [would achieve] little." (A);
	stop the action.

@h Waking up.

=
Waking up is an action applying to nothing.
The Waking up action is accessible to Inter as "Wake".

The specification of the waking up action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor waking up (this is the block waking up rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "The dreadful truth [are], this [are not] a dream." (A);
	stop the action.

@h Thinking.

=
Thinking is an action applying to nothing.
The Thinking action is accessible to Inter as "Think".

The specification of the thinking action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor thinking (this is the block thinking rule):
	if the actor is the player:
		say "What a good idea." (A);
	stop the action.

@h Smelling.

=
Smelling is an action applying to nothing or one thing.
The Smelling action is accessible to Inter as "Smell".

The specification of the smelling action is
"The Standard Rules define this action in only a minimal way, replying only
that the player smells nothing unexpected."

@ Report.

=
Report an actor smelling (this is the report smelling rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [smell] nothing unexpected." (A);
	otherwise:
		say "[The actor] [sniff]." (B).

@h Listening to.

=
Listening to is an action applying to nothing or one thing and abbreviable.
The Listening to action is accessible to Inter as "Listen".

The specification of the listening to action is
"The Standard Rules define this action in only a minimal way, replying only
that the player hears nothing unexpected."

@ Report.

=
Report an actor listening to (this is the report listening rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [hear] nothing unexpected." (A);
	otherwise:
		say "[The actor] [listen]." (B).

@h Tasting.

=
Tasting is an action applying to one thing.
The Tasting action is accessible to Inter as "Taste".

The specification of the tasting action is
"The Standard Rules define this action in only a minimal way, replying only
that the player tastes nothing unexpected."

@ Report.

=
Report an actor tasting (this is the report tasting rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [taste] nothing unexpected." (A);
	otherwise:
		say "[The actor] [taste] [the noun]." (B).

@h Cutting.

=
Cutting is an action applying to one thing.
The Cutting action is accessible to Inter as "Cut".

The specification of the cutting action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor cutting (this is the block cutting rule):
	if the actor is the player:
		say "Cutting [regarding the noun][them] up [would achieve] little." (A);
	stop the action.

@h Jumping.

=
Jumping is an action applying to nothing.
The Jumping action is accessible to Inter as "Jump".

The specification of the jumping action is
"The Standard Rules define this action in only a minimal way, simply reporting
a little jump on the spot."

@ Report.

=
Report an actor jumping (this is the report jumping rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [jump] on the spot." (A);
	otherwise:
		say "[The actor] [jump] on the spot." (B).

@h Tying it to.

=
Tying it to is an action applying to two things.
The Tying it to action is accessible to Inter as "Tie".

The specification of the tying it to action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor tying something to (this is the block tying rule):
	if the actor is the player:
		say "[We] [would achieve] nothing by this." (A);
	stop the action.

@h Drinking.

=
Drinking is an action applying to one thing.
The Drinking action is accessible to Inter as "Drink".

The specification of the drinking action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor drinking (this is the block drinking rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There's] nothing suitable to drink here." (A);
	stop the action.

@h Saying sorry.

=
Saying sorry is an action applying to nothing.
The Saying sorry action is accessible to Inter as "Sorry".

The specification of the saying sorry action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor saying sorry (this is the block saying sorry rule):
	if the actor is the player:
		say "Oh, don't [if American dialect option is
			active]apologize[otherwise]apologise[end if]." (A);
	stop the action.

@h Swinging.

=
Swinging is an action applying to one thing.
The Swinging action is accessible to Inter as "Swing".

The specification of the swinging action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor swinging (this is the block swinging rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "[There's] nothing sensible to swing here." (A);
	stop the action.

@h Rubbing.

=
Rubbing is an action applying to one thing.
The Rubbing action is accessible to Inter as "Rub".

The specification of the rubbing action is
"The Standard Rules define this action in only a minimal way, simply reporting
that it has happened."

@ Check.

=
Check an actor rubbing (this is the can't rub another person rule):
	if the noun is a person who is not the actor:
		if the actor is the player:
			say "[The noun] [might not like] that." (A);
		stop the action.

@ Report.

=
Report an actor rubbing (this is the report rubbing rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [rub] [the noun]." (A);
	otherwise:
		say "[The actor] [rub] [the noun]." (B).

@h Setting it to.

=
Setting it to is an action applying to one thing and one topic.
The Setting it to action is accessible to Inter as "SetTo".

The specification of the setting it to action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor setting something to (this is the block setting it to rule):
	if the actor is the player:
		say "No, [we] [can't set] [regarding the noun][those] to anything." (A);
	stop the action.

@h Waving hands.

=
Waving hands is an action applying to nothing.
The Waving hands action is accessible to Inter as "WaveHands".

The specification of the waving hands action is
"The Standard Rules define this action in only a minimal way, simply reporting
a little wave of the hands."

@ Report.

=
Report an actor waving hands (this is the report waving hands rule):
	if the actor is the player:
		if the action is not silent:
			say "[We] [wave]." (A);
	otherwise:
		say "[The actor] [wave]." (B).

@h Buying.

=
Buying is an action applying to one thing.
The Buying action is accessible to Inter as "Buy".

The specification of the buying action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor buying (this is the block buying rule):
	if the actor is the player:
		now the prior named object is nothing;
		say "Nothing [are] on sale." (A);
	stop the action.

@h Climbing.

=
Climbing is an action applying to one thing.
The Climbing action is accessible to Inter as "Climb".

The specification of the climbing action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor climbing (this is the block climbing rule):
	if the actor is the player:
		say "Little [are] to be achieved by that." (A);
	stop the action.

@h Sleeping.

=
Sleeping is an action applying to nothing.
The Sleeping action is accessible to Inter as "Sleep".

The specification of the sleeping action is
"The Standard Rules define this action in only a minimal way, blocking it
with a check rule which stops it in all cases. It exists so that before
or instead rules can be written to make it do interesting things in special
cases. (Or to reconstruct the action as something more substantial, unlist
the block rule and supply carry out and report rules, together perhaps
with some further check rules.)"

@ Check.

=
Check an actor sleeping (this is the block sleeping rule):
	if the actor is the player:
		say "[We] [aren't] feeling especially drowsy." (A);
	stop the action.

@h Out of world actions.
We start with a brace of actions which control the (virtual) hardware of
the virtual machine: restore, save, quit, restart, verify, and transcript
on and off. All of these are implemented at the I6 level where, in fact,
they are delegated quickly to assembly language instructions for whichever
is the current VM: so these are close to the metal, as they say.

=
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


@ The VERSION command is not quite so close to the metal -- it is implemented
in I6, at the end of the day -- but it does involve reading the bytes of the
story file header, so it needs to take quite different forms for the
different formats being compiled to.

=
Requesting the story file version is an action out of world and applying to nothing.
The requesting the story file version action is accessible to Inter as "Version".

The announce the story file version rule is listed in the carry out requesting the story
	file version rulebook.
The announce the story file version rule is defined by Inter as "ANNOUNCE_STORY_FILE_VERSION_R".

@ There's really no very good reason why we provide the out-of-world command
SCORE but not (say) TIME, or any one of dozens of other traditional what's-my-status
commands: DIAGNOSE, say, or PLACES. But we are conservative on this; it's easy
for users or extensions to provide these verbs if they want them, and they are
not always appropriate for every project. Even SCORE is questionable, but its
removal would be a gesture too far.

=
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

@ It's perhaps clumsy to have three actions for switching the style of room
description, but this accords with I6 custom (and Infocom's, for that matter),
and does no harm.

=
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

@ Similarly, two different actions handle "notify" and "notify off".

=
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

@ Lastly, the "pronouns" verb, which is perhaps more often used by people
debugging the I6 parser than by actual players.

=
Requesting the pronoun meanings is an action out of world and applying to nothing.
The requesting the pronoun meanings action is accessible to Inter as "Pronouns".

The announce the pronoun meanings rule is listed in the carry out requesting the
	pronoun meanings rulebook.
The announce the pronoun meanings rule is defined by Inter as "ANNOUNCE_PRONOUN_MEANINGS_R" with
	"At the moment, " (A),
	"means " (B),
	"is unset" (C),
	"no pronouns are known to the game." (D).

@ The dialogue system offers an action "talking about", but not "talking to X about":
this is a model of conversation which is aimed at simulating multi-person encounters,
where lines are spoken more into the room than at any one person.

=
Section 10 - Dialogue-related actions (for dialogue language element only)

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
		continue the action;
	if the other beats is not empty:
		perform entry 1 of the other beats;
		continue the action;
	if the player is the actor:
		say "There is no reply.";
		stop the action;
	otherwise:
		say "[The actor] [talk] about [T].";
		stop the action.
