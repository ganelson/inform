Version 3 of Rideable Vehicles by Graham Nelson begins here.

"Vehicles which one sits on top of, rather than inside, such as elephants or
motorcycles."

To mount is a verb. To dismount is a verb.

A rideable animal is a kind of animal.
A rideable animal is usually not portable.
Include (-
	has enterable supporter,
	with before [; Go: return 1; ],
-) when defining a rideable animal.

A rideable vehicle is a kind of supporter.
A rideable vehicle is always enterable.
A rideable vehicle is usually not portable.
Include (-
	with before [; Go: return 1; ],
-) when defining a rideable vehicle.

The stand up before going rule is not listed in any rulebook.

Definition: Something is vehicular if it is a vehicle or it is a
rideable animal or it is a rideable vehicle.

Rule for setting action variables for going (this is the allow rideables to be
	going vehicles rule):
	if the actor is carried by a rideable animal (called the steed),
		now the vehicle gone by is the steed;
	if the actor is on a rideable vehicle (called the conveyance),
		now the vehicle gone by is the conveyance.

Mounting is an action applying to one thing.

Before an actor entering a rideable animal (called the steed), try the actor
mounting the steed instead.

Before an actor entering a rideable vehicle (called the conveyance), try the
actor mounting the conveyance instead.

Before an actor getting off a rideable animal (called the steed), try the
actor dismounting instead.

Before an actor getting off a rideable vehicle (called the conveyance), try
the actor dismounting instead.

Before an actor exiting:
	if the actor is carried by a rideable animal, try the actor dismounting instead;
	if the actor is carried by a rideable vehicle, try the actor dismounting instead.

Check an actor mounting (this is the can't mount when mounted on an animal rule): 
	if the actor is carried by a rideable animal (called the steed):
		if the actor is the player, say "[We] [are] already riding [the steed]." (A);
		stop the action.

Check an actor mounting (this is the can't mount when mounted on a vehicle rule):
	if the actor is on a rideable vehicle (called the conveyance):
		if the actor is the player, say "[We] [are] already riding [the conveyance]." (A);
		stop the action.

Check an actor mounting (this is the can't mount something unrideable rule):
	if the noun is not a rideable animal and the noun is not a rideable vehicle:
		if the actor is the player, say "[The noun] [cannot] be ridden." (A) instead;
		stop the action.

Check an actor mounting (this is the can't mount something carried rule):
	abide by the can't enter something carried rule.

Check an actor mounting (this is the can't mount something unreachable rule):
	abide by the implicitly pass through other barriers rule. 
	
Carry out an actor mounting (this is the standard mounting rule):
	surreptitiously move the actor to the noun.

Report an actor mounting (this is the standard report mounting rule):
	if the actor is the player:
		say "[We] [mount] [the noun]." (A);
		describe locale for the noun;
	otherwise:
		say "[The actor] [mount] [the noun]." (B) instead. 

Unsuccessful attempt by someone trying mounting (this is the mounting excuses rule):
	if the reason the action failed is the can't mount when mounted on an animal rule:
		let the steed be the random rideable animal which carries the person asked;
		say "[The person asked] [are] already riding [the steed]." (A);
	if the reason the action failed is the can't mount when mounted on a vehicle rule:
		let the conveyance be the random rideable vehicle which supports the person asked;
		say "[The person asked] [are] already riding [the conveyance]." (B);
	if the reason the action failed is the can't mount something unrideable rule,
		say "[The noun] [cannot] be ridden." (C).

Understand "ride [something]" as mounting.
Understand "mount [something]" as mounting.

Dismounting is an action applying to nothing.

Check an actor dismounting (this is the can't dismount when not mounted rule):
	if the actor is not carried by a rideable animal and the actor is not on a rideable vehicle:
		if the actor is a player, say "[We] [are] not riding anything." (A);
		stop the action.

Carry out an actor dismounting (this is the standard dismounting rule):
	if the actor is carried by a rideable animal (called the steed),
		now the noun is the steed;
	if the actor is on a rideable vehicle (called the conveyance),
		now the noun is the conveyance;
	let the former exterior be the holder of the noun;
	surreptitiously move the actor to the former exterior.

Report an actor dismounting (this is the standard report dismounting rule):
	if the actor is the player:
		say "[We] [dismount] [the noun].[line break][run paragraph on]" (A);
		produce a room description with going spacing conventions;
	otherwise:
		say "[The actor] [dismount] [the noun]." (B)
	
Unsuccessful attempt by someone trying dismounting (this is the dismounting excuses rule):
	if the reason the action failed is the can't dismount when not mounted rule,
		say "[The person asked] [are] not riding anything." (A);
	otherwise make no decision.

Understand "dismount" as dismounting.

Before asking a rideable animal (called the mount) to try going a
direction (called the way):
	if the player is carried by the mount, try going the way instead.

Rideable Vehicles ends here.

---- DOCUMENTATION ----

Inform's built-in "vehicle" kind assumes that the vehicle is a
container, which is fine for cars or hot-air balloons, but not so
good for a pony or a four-wheeled lawnmower, which one rides rather
than gets inside. Rideable Vehicles is an extension which creates
two more kinds: "rideable animal" (good for the pony) and
"rideable vehicle" (good for the lawnmower).

	The pony is a rideable animal in the Forest Clearing.
	The lawnmover is a rideable vehicle in the Garden Shed.

This means that three different kinds of thing can be used as a
means of travel, which might make it awkward to write a general
rule about them, so we also define the adjective "vehicular" for
any thing of any of these kinds.

	The Transport Museum is a room. "The Museum is filled with means of transport old and new, including [list of vehicular things in the Transport Museum]."

A new action called "mounting" is created, and a new command "mount"
(or "ride") is added for the player to use. Thus:

	Instead of mounting the pony, say "The pony snorts and backs off."

results in

	>ride pony
	The pony snorts and backs off.

And a corresponding "dismounting" action handles the command "dismount".

	>dismount
	You get off the pony.

Moreover, commands such as "get off the pony" or "get on the lawnmower"
are converted into these new actions instead, so that rules like the
following will always work, no matter what command is tried:

	Instead of mounting the tricycle when the transport pass is not carried by the player:
		say "The tricycle can only be ridden by those with a transport pass."

Lastly, a special rule means that "pony, go east" is recognised when
the player is riding the pony. (This works for rideable animals, but not
rideable vehicles.)

Example: * Vehicle Testing Center - An assortment of rideable and other vehicles, with restrictions about which rooms can be entered with what rides.

	*: "Rides" by Emily Short 

	Include Rideable Vehicles by Graham Nelson.

	The Vehicle Testing Center is a room. "A large square of field surrounded by a wall of hay bales. A driveway leads out to the west. The ground slopes down to a pond along the northern edge."

	A sign is a thing in the Center. "The sign advertises experimental rides in the following: [list of vehicular things][clear vehicles]."

	To say clear vehicles:
		now every vehicular thing is unmentioned.

	The red wagon is a vehicle in the Vehicle Testing Center. "There is a lovely red wagon here, complete with an outboard motor."

	The swan is a rideable animal in the Vehicle Testing Center. "At the pond's edge waits a black swan of unusual size, wearing a bridle and a gold-trimmed Mexican hat." The description of the swan is "The swan looks back at you."

	The swan can be fed or unfed.

	Instead of mounting the unfed swan:
		say "The swan gives you a look of disappointment and reproach. Apparently it doesn't work for free."

	Some chow is carried by the player. The description is "Delicious Purina swan chow pellets!"

	Instead of giving the chow to the swan:
		now the swan is fed;
		say "The swan accepts your offering courteously."

	Instead of going to the Dusty Road by swan:
		say "The swan honks indignantly at the very notion."
	
	Instead of going to the Open Sky by swan:
		say "The swan can swim with you aboard, but not lift off." 

	After going somewhere by swan:
		say "The swan honks a lovely Mexican serenade as it paddles you about.";
		continue the action.

	The Pond is north of the Vehicle Testing Center. "Funny, the pond is bigger from the middle than it seemed from the shore. In fact, you can't see any edge but the testing center to the south and a small island to the north."

	Instead of going to the Pond when the player is not carried by the swan: 
		say "You forgot your water skis." 

	Instead of dismounting when the location is the Pond:
		say "You'd fall in!"
	
		
	North of the Pond is the Small Island.

	The glass elevator is a vehicle in the Small Island. It is transparent. "A glass elevator stands in the center, a fantastically strong microfilament connecting it to... something in the sky."

	The Open Sky is above the Small Island. "There's a great view from here, starting with that lovely glass floor. In fact, maybe you'd better not look that way."

	Instead of going a direction (called the way) when the player is in the Elevator:
		if the way is up, continue the action;
		if the way is down, continue the action;
		say "The elevator ascends and descends only."

	Instead of going to the Open Sky when the player is not in the Elevator:
		say "Do you plan to flap your arms, then?"

	Instead of exiting in the Open Sky:
		say "It's a long way down."
	

	The Dusty Road is west of the Vehicle Testing Center. "Off to the east is an enclosed area for the testing of dangerous and improbable vehicles."

	A rideable vehicle called a tricycle is in the Dusty Road.

	Test me with "test wagon / test tricycle / test swan / test elevator".

	Test wagon with "get in wagon / w / e / e / w / out".

	Test tricycle with "get in wagon / mount tricycle /  e / n / w / e / dismount".

	Test swan with "n / get on swan / give chow to swan / mount swan / dismount / mount swan / n / dismount / swan, n / dismount".

	Test elevator with "u / get in elevator / get out / get in elevator / up / get out / d".
