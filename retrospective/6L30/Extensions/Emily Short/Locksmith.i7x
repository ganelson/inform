Version 12 of Locksmith by Emily Short begins here.

"Implicit handling of doors and containers so that lock manipulation is automatic if the player has the necessary keys."

Use authorial modesty.

To open is a verb. To lack is a verb. To fit is a verb. To lock is a verb. To unlock is a verb.

Volume 1 - Automatic locking and unlocking with necessary actions

Use sequential action translates as (- Constant SEQUENTIAL_ACTION; -).

Before going through a closed door (called the blocking door) (this is the opening doors before entering rule):
	if sequential action option is active:
		try opening the blocking door;
	otherwise:
		say "(first opening [the blocking door])[command clarification break]" (A);
		silently try opening the blocking door;
	if the blocking door is closed, stop the action.

Before locking an open thing (called the door ajar) with something (this is the closing doors before locking rule):
	if sequential action option is active:
		try closing the door ajar;
	otherwise:
		say "(first closing [the door ajar])[command clarification break]" (A);
		silently try closing the door ajar;
	if the door ajar is open, stop the action.
	
Before locking keylessly an open thing (called the door ajar) (this is the closing doors before locking keylessly rule):
	if sequential action option is active:
		try closing the door ajar;
	otherwise:
		say "(first closing [the door ajar])[command clarification break]" (A);
		silently try closing the door ajar;
	if the door ajar is open, stop the action.

Before opening a locked thing (called the sealed chest) (this is the unlocking before opening rule): 
	if sequential action option is active:
		try unlocking keylessly the sealed chest;
	otherwise:
		say "(first unlocking [the sealed chest])[command clarification break]" (A);
		silently try unlocking keylessly the sealed chest;
	if the sealed chest is locked, stop the action.
	
Before someone trying going through a closed door (called the blocking door) (this is the intelligently opening doors rule):
	try the person asked trying opening the blocking door;
	if the blocking door is closed, stop the action.
	
Before someone trying locking an open thing (called the door ajar) with something (this is the intelligently closing doors rule):
	try the person asked trying closing the door ajar;
	if the door ajar is open, stop the action.
	
Before someone trying locking keylessly an open thing (called the door ajar)  (this is the intelligently closing keyless doors rule):
	try the person asked trying closing the door ajar;
	if the door ajar is open, stop the action.
	
Before someone trying opening a locked thing (called the sealed chest) (this is the intelligently opening containers rule):
	try the person asked trying unlocking keylessly the sealed chest;
	if the sealed chest is locked, stop the action.

Volume 2 - Default locking and unlocking

Part 1 - The matching key rule

This is the need a matching key rule:
	if the person asked encloses something (called item) which unlocks the noun:
		now the second noun is the item;
		abide by the must have accessible the second noun rule;
	otherwise if a visible passkey (called item) unbolts the noun: 
		now the second noun is the item;
		abide by the must have accessible the second noun rule;
	otherwise:
		if the player is the person asked, say "[key-refusal for noun]";
		stop the action.

To say key-refusal for (locked-thing - an object):
	carry out the refusing keys activity with the locked-thing.

Refusing keys of something is an activity.

Rule for refusing keys of something (called locked-thing) (this is the standard printing key lack rule):
	say "[We] [lack] a key that fits [the locked-thing]." (A).

Definition: a thing is key-accessible:
	if the person asked carries it, yes;
	if it is on a keychain which is carried by the person asked, yes;
	no.

Part 2 - Unlocking

Section 1 - Regular unlocking

Understand the command "unlock" as something new. Understand "unlock
[something] with [something]" as unlocking it with. Understand "unlock [a
locked lockable thing] with [something]" as unlocking it with. Understand
"unlock [a lockable thing] with [something]" as unlocking it with.

Understand the commands "open" and "uncover" and "unwrap" as something new.
Understand "open [something]" or "uncover [something]" or "unwrap [something]"
as opening. Understand "open [something] with [something]" as unlocking it
with. Understand "open [a locked lockable thing] with [something]" as
unlocking it with. Understand "open [a lockable thing] with [something]" as
unlocking it with.

Check unlocking it with (this is the must be able to reach the key rule):
	abide by the must have accessible the second noun rule.

The right second rule is listed instead of the can't unlock without the
correct key rule in the check unlocking it with rulebook.

This is the right second rule:
	if the second noun does not unlock the noun:
		say "[The second noun] [do not fit] [the noun]." (A) instead.

Section 2 - Keylessly

Understand "unlock [something]" as unlocking keylessly. Understand "unlock [a
locked lockable thing]" as unlocking keylessly. Understand "unlock [a lockable
thing]" as unlocking keylessly.

Unlocking keylessly is an action applying to one thing.
The unlocking
keylessly action has an object called the key unlocked with.

Check an actor unlocking keylessly (this is the check keylessly unlocking rule):
	abide by the can't unlock without a lock rule;
	abide by the can't unlock what's already unlocked rule;
	abide by the need a matching key rule;
	now the key unlocked with is the second noun.

Carry out an actor unlocking keylessly (this is the standard keylessly unlocking rule):
	if sequential action option is active:
		do nothing;
	otherwise if the person asked is the player:
		say "(with [the key unlocked with])[command clarification break]" (A);
	try the person asked unlocking the noun with the key unlocked with.


Part 3 - Locking

Section 1 - Regular locking

Understand the command "lock" as something new. Understand "lock [something]
with [something]" as locking it with. Understand "lock [an unlocked lockable
thing] with [something]" as locking it with. Understand "lock [a lockable
thing] with [something]" as locking it with.

Check locking it with:
	abide by the must have accessible the second noun rule.

The right second rule is listed instead of the can't lock without the correct
key rule in the check locking it with rulebook.

Section 2 - Keylessly

Understand "lock [something]" as locking keylessly. Understand "lock [an
unlocked lockable thing]" as locking keylessly. Understand "lock [a lockable
thing]" as locking keylessly.

Locking keylessly is an action applying to one thing.
The locking keylessly
action has an object called the key locked with.

Check an actor locking keylessly (this is the check keylessly locking rule):
	abide by the can't lock without a lock rule;
	abide by the can't lock what's already locked rule;
	abide by the can't lock what's open rule;
	abide by the need a matching key rule;
	now the key locked with is the second noun.
	
Carry out an actor locking keylessly (this is the standard keylessly locking rule):
	if sequential action option is active:
		do nothing;
	otherwise if the person asked is the player:
		say "(with [the key locked with])[command clarification break]" (A);
	try the person asked locking the noun with the key locked with.

Volume 3 - The Passkey kind, needed only if you want keys to name themselves

A passkey is a kind of thing. The specification of a passkey is "A kind of key
whose inventory listing changes to reflect the player's knowledge about what
it unlocks."

Definition: a passkey is identified if it unbolts something.

Unbolting relates one passkey to various things.

The verb to unbolt means the unbolting relation.

After printing the name of an identified passkey (called the item) while
	taking inventory (this is the identify passkeys in inventory rule):
	now the prior named object is the item;
	say " (which [open] [the list of things unbolted by the item])" (A);
	
After examining an identified passkey (this is the passkey description rule):
	say "[The noun] [unlock] [the list of things unbolted by the noun]." (A).
	
Carry out unlocking something with a passkey (this is the standard passkey unlocking rule):
	if the second noun unlocks the noun, now the second noun unbolts the noun.
	
Report someone trying unlocking something with a passkey (this is the observe someone unlocking rule):
	now the second noun unbolts the noun.
	
Carry out locking something with a passkey (this is the standard passkey locking rule):
	if the second noun unlocks the noun, now the second noun unbolts the noun.

Report someone trying locking something with a passkey (this is the observe someone locking rule):
	now the second noun unbolts the noun.


Volume 4 - The Keychain kind, needed only if you want a keychain



A keychain is a kind of supporter that is portable. The specification of a
keychain is "A keychain which can hold the player's keys without forcing the
player to take them off the ring in order to unlock things."

Instead of putting something which is not a passkey on a keychain (this is the limiting keychains rule):
	say "[The noun] [are] not a key." (A).

The keychain-aware carrying requirements rule is listed instead
	of the carrying requirements rule in the action-processing rules.

This is the keychain-aware carrying requirements rule:
	if locking or unlocking something with something which is on a keychain which is carried by the actor:
		continue the action;
	abide by the carrying requirements rule.
 
Understand "put [passkey] on [keychain]" as putting it on.

Rule for deciding whether all includes passkeys which are on a keychain (this is the don't strip keys rule):
	if the second noun is not a keychain, it does not.

Volume 5 - Support Materials

This is the noun autotaking rule:
	if sequential action option is active:
		if the player is the person asked:
			try taking the noun;
		otherwise:
			try the person asked trying taking the noun;
	otherwise:
		carry out the implicitly taking activity with the noun;

This is the second noun autotaking rule:
	if sequential action option is active:
		if the player is the person asked:
			try taking the second noun;
		otherwise:
			try the person asked trying taking the second noun;
	otherwise:
		carry out the implicitly taking activity with the second noun.

This is the must hold the noun rule:
	if the person asked does not have the noun, follow the noun autotaking rule;
	if the person asked does not have the noun, stop the action; 
	make no decision.

This is the must hold the second noun rule:
	if the person asked does not have the second noun, follow the second noun autotaking rule;
	if the person asked does not have the second noun, stop the action;
	make no decision.

This is the must have accessible the noun rule:
	if the noun is not key-accessible:
		if the noun is on a keychain (called the containing keychain), now the noun is the containing keychain;
		follow the noun autotaking rule;
	if the noun is not key-accessible:
		if the player is the person asked,
			say "Without holding [the noun], [we] [can] do nothing." (A);
		stop the action;
	make no decision.

This is the must have accessible the second noun rule:
	if the second noun is not key-accessible:
		let the held second noun be the second noun;
		if the second noun is on a keychain (called the containing keychain),
			now the second noun is the containing keychain;
		follow the second noun autotaking rule;
		now the second noun is the held second noun;
	if the second noun is not key-accessible:
		if the player is the person asked,
			say "Without holding [the second noun], [we] [can] do nothing." (A);
		stop the action;
	make no decision.


Volume 6 - Unlocking all - Not for release

Understand "unlockall" as universal unlocking.

Universal unlocking is an action applying to nothing.

Carry out universal unlocking (this is the lock debugging rule):
	repeat with item running through locked things:
		now the item is unlocked;
		say "Unlocking [the item]." (A).

Report universal unlocking (this is the report universal unlocking rule):
	say "A loud stereophonic click assures you that everything in the game has been unlocked." (A).

Locksmith ends here.

---- DOCUMENTATION ----

Locksmith adds implicit handling of doors and containers so that lock manipulation is automatic if the player has the necessary keys.  There are five parts of Locksmith.

First, Locksmith will try opening all doors the player tries to pass through; try closing all lockables before locking them; and try unlocking all locked items before opening them. Other characters will follow the same rules. 

By default, these actions are described as other automatic actions usually are in Inform: the player sees something like "(first unlocking...)" before he opens the door. The "Use sequential action" mode is provided for the case where we would prefer to see "You unlock the door." instead. 

If the player tries to open a door but does not have the right key, he receives a key-refusal message, such as "You lack a key that fits the red chest." We can override this by writing other "to say key-refusal for..." phrases, like this:

	To say key-refusal for (locked-thing - a container):
		say "You will be unable to see the contents of [the locked-thing] until you find the appropriate key."

	To say key-refusal for (locked-thing - the red chest):
		say "The red chest resists all your attempts because you do not have the magic orb."

Second, Locksmith tries to provide an intelligent default if no key is specified, so that >LOCK DOOR will work if the player is holding the correct key. 

Third, Locksmith introduces a kind called the passkey.  The passkey is a key which will name itself in inventory listings after use. Once the passkey has been identified, the game also automates taking the key before using it on the door it matches.  Keys the player has never successfully identified, or keys not defined as belonging to the passkey kind, will not behave this way. Passkeys are also renamed if the player has seen another character use them successfully.

The "unbolts" relation is used to keep track of what the player knows about keys. We will probably not need to do this in most cases, but it is possible to change this manually during play to give the player new knowledge (or ignorance) about the functions of keys.

Passkeys can also be used with the keychain kind. Keychains are portable supporters which can have passkeys (but only passkeys) put on them. Keys on a keychain can be used as though they were in the player's hand, and will not be automatically removed for locking and unlocking actions.

Finally, Locksmith provides the debugging command 'unlockall', only identified in debugging compilations of the game.  If during play we type UNLOCKALL, all locks in the game will magically spring open.

One thing Locksmith does not handle is allowing skeleton keys that unlock multiple locks. This functionality costs some memory overhead, so it is not included compulsorily in Locksmith, but if we want it, we can also include Skeleton Keys by Emily Short.

Example: *  Latches - Adding one lock in the game that is managed by latch rather than by a key.

Suppose that most of the doors in our game are locked with normal keys, but one is the kind that simply latches. We can handle this with a specific before rule that fires prior to the more general before rules in Locksmith. We also want to treat LOCK X differently from LOCK X WITH..., so we will treat locking and locking keylessly with separate rules. Locking keylessly is the action invoked if the player types only LOCK X.

	*: "John Malkovich's Toilet"

	Include Locksmith by Emily Short.

	The Bathroom is a room.

	The bathroom door is a door. It is north of the Bathroom and south of the Bedroom. It is lockable and locked. 

	Before unlocking keylessly the bathroom door:
		if the bathroom door is unlocked, say "[The bathroom door] is already unlocked." instead;
		try turning the latch instead.

	Before locking keylessly the bathroom door:
		if the bathroom door is locked, say "[The bathroom door] is already secure." instead;
		try turning the latch instead.
	
	Before locking the bathroom door with something:
		say "The bathroom door locks with a latch, not with a key." instead.
	
	Before unlocking the bathroom door with something:
		say "The bathroom door locks with a latch, not with a key." instead.

	The latch is part of the bathroom door. "A turnable tab that locks the door." Understand "knob" as the latch. The description of the bathroom door is "Uninteresting save for the latch."

	Instead of turning the latch: 
		if the bathroom door is locked begin;
			say "Click! You turn the latch, and the door is unlocked[if the door is open] and open[end if].";
			now the bathroom door is unlocked;
		otherwise;
			say "Click! You turn the latch, and the door is locked[if the door is open], but open; the lock will catch as soon as you shut the door[end if].";
			now the bathroom door is locked;
		end if.

	The little black oval door is a door. It is west of the Bathroom and east of Oblivion. It is lockable and locked. The description of the oval door is "It is in the wall of the shower area, and opens who knows where. You are sure it was not there yesterday."

	The onyx key unlocks the oval door. It is in the Bedroom. "On the floor, jagged black in the square of sunlight, is [an onyx key]." 

	Test me with "x bathroom door / unlock oval door / unlock bathroom door / g / go through bathroom door / get key / lock bathroom door / close bathroom door / s / lock bathroom door with onyx key / w".

Example: **  Tobacco - Passkeys that open more than one thing each.

Here we explore having keys each of which unlocks several items:

	*: "Tobacco"
	
	Include Locksmith by Emily Short.
	
	The Hollow Tree is a room. Below the Hollow Tree is the Vast Hall. Northwest of the Vast Hall is a copper door. The copper door is a locked lockable door. Northwest of the copper door is the Copper Chamber. The Copper Chamber contains a chest and a small dog. The chest contains a large quantity of copper pence. The chest is lockable, closed, openable, and locked. The description of the small dog is "Its eyes are as big as teacups." The small dog is an animal. The copper key unlocks the copper door. It unlocks the chest. The copper key is a passkey. The description of the copper key is "On the head of the key is engraved a precisely delineated teapot."
	
	North of the Vast Hall is a silver door. The silver door is a locked lockable door. North of the silver door is the Silver Chamber. The Silver Chamber contains a sarcophagus and a medium dog. The sarcophagus contains a large quantity of silver pence. The sarcophagus is lockable, closed, openable, and locked. The description of the medium dog is "Its eyes are as big as millwheels." The medium dog is an animal. The silver key unlocks the silver door. It unlocks the sarcophagus. The silver key is a passkey. The description of the silver key is "On the head of the key is engraved a very small but detailed watermill."
	
	Northeast of the Vast Hall is a gold door. The gold door is a locked lockable door. North of the gold door is the Gold Chamber. The Gold Chamber contains a wardrobe and a large dog. The wardrobe contains a large quantity of gold coins. The wardrobe is lockable, closed, openable, and locked. The description of the large dog is "Its eyes are as big as towers, and turn round and round in its head like wheels." The large dog is an animal. The gold key unlocks the gold door. It unlocks the wardrobe. The gold key is a passkey. The description of the gold key is "On the head of the key is engraved a very small but detailed tower."
	
	The tinderbox is in the Vast Hall. The tinderbox contains the silver key, the gold key, and the copper key. The tinderbox is openable and closed.
	
	The player carries some chewing tobacco and an iron ring. The iron ring is a keychain. The description of the iron ring is "A ring to hold keys."
	
	Test me with "test one / test two".
	

	Test one with "d / n / i / get tinderbox / open tinderbox / i / nw / drop key / lock door / drop key / unlock chest / get copper key / unlock chest / put copper on ring / lock chest / drop ring / unlock chest".

	Test two with "enter door / n / i / x silver / put silver on ring / x copper / unlock sarcophagus / x silver key".
	
Example: ** Rekeying - Modifying the way passkey descriptions work.
	
As a default, Locksmith describes what passkeys unlock only after printing their default description. Under some circumstances, however, we might want to override that behavior, like this:

	*: "Rekeying"
	
	Include Locksmith by Emily Short.
	
	The player carries a passkey called the tin key. The tin key unlocks the tin box. The tin box is closed, openable, lockable, and locked. In the box is a single Cheerio.
	
	Cereality is a room. "The newly-opened 'cereal bar' allows you to mix and match cereal types at will." The box is in Cereality.
	
	The passkey description rule is not listed in any rulebook.

	The description of a passkey is usually "[if the item described unbolts something][The item described] unlocks [the list of things unbolted by the item described][otherwise]You have yet to discover what [the item described] unlocks[end if]."

	Test me with "i / x key / unlock box / i / x key".


Example: *** Watchtower - Using sequential actions to make the player's activities more equal with those of another character.

Suppose that instead of the "(first unlocking...)" text, we would like to offer some more interesting flavor text. We might accomplish this by sequential action option is active and then supplying new report rules for specific actions. (Notice that we do not make them After... rules, on the grounds that those would stop the action process. We want to report these actions and allow them to succeed normally.)

	*: "Watchtower"

	Use sequential action. Include Locksmith by Emily Short.
	
	Bridge is a room. "Beneath this long, narrow bridge is a gully full of ice-water from the mountains above. It runs milky at this time of year, and is not fit to drink. The air off it is bitterly cold. Just north of here is the Roman watchtower, built square and still defensible despite several centuries of neglect."
	
	North of Bridge is the tower door. The tower door is a lockable locked door. It is scenery. Understand "watchtower" as the tower door. The tower door is south of the Watchtower. The large iron key unlocks the tower door. The player carries the large iron key.
	
	The description of the Watchtower is "The wooden floor has mostly rotted away, exposing the square pit in which the paymaster used to keep the soldiers['] coin. It is possible to move around the perimeter of the room without falling in, however."
	
	Report unlocking something with something when the player is in Bridge:
		say "Shivering and fumbling, you manage to unlock [the noun] with [the second noun]. Your fingers are very nearly numb." instead.
	
	Report unlocking something with something when the player is in Bridge:
		say "Shivering and fumbling, you manage to unlock [the noun] with [the second noun]. Your fingers are very nearly numb." instead.
		
	Report opening the tower door:
		say "The tower door resists your first shove or two, but then falls open." instead.
		
	Leif is a man in the Bridge. 
	
	A persuasion rule: persuasion succeeds. 
	
	Report someone trying unlocking a door with something:
		say "[The person asked] rattles the handle of [the noun] a few times, then thinks to try [the second noun] on it. 'Bit stiff, this.'" instead.
		
	Report someone trying opening the tower door:
		say "[The person asked] gives [the tower door] several [if the person asked is in the Bridge]shoves[otherwise]firm tugs[end if] before managing to open it." instead.
		
	Test me with "drop key / open door / get key / n / s / lock door / drop key / Leif, get key / Leif, n".
		
Leif will also follow the rules about unlocking and opening doors, and have a few special reports of his own -- though in fact we could also arrange matters so that he is unable to do so, by including the following:

	*: The intelligently opening doors rule is not listed in any rulebook.
	The intelligently closing doors rule is not listed in any rulebook.
	The intelligently closing keyless doors rule is not listed in any rulebook.
	The intelligently opening containers rule is not listed in any rulebook.

...and now he will be too dim to handle the keys himself.
