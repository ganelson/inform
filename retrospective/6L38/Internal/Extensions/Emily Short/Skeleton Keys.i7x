Skeleton Keys by Emily Short begins here.

Section 1 - Multiple locking (in place of Section SR1/9 - Lockability in Standard Rules by Graham Nelson)

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

Lock-fitting relates various things to various things.
The verb to unlock (it unlocks, they unlock, it unlocked, it is unlocked) means
the lock-fitting relation.

Section 2 - (for use without Locksmith by Emily Short)

To fit is a verb.

The right second rule is listed instead of the can't unlock without the
correct key rule in the check unlocking it with rulebook.

The right second rule is listed instead of the can't lock without the correct
key rule in the check locking it with rulebook.

This is the right second rule: 
	if the actor does not carry the second noun:
		if the actor is the player:
			say "[We]['re not] carrying [the second noun]." (A) instead;
		stop the action;
	if the second noun does not unlock the noun:
		say "[The second noun] [do not fit] [the noun]." (B) instead.

Skeleton Keys ends here.

---- DOCUMENTATION ----

This extension replaces the default behavior of Inform, which allows one key per lock, with a more generous system in which unlocking applies to multiple objects. That means that it is possible to write a skeleton key like so:

	Every door is unlocked by the skeleton key.

Because it is possible for more than one key to unlock a given door, the property "matching key" is now meaningless.

The drawback to this arrangement is that it adds more information to every item in the game, which will mean using up several K of dynamic memory. This is not important when compiling to Glulx, but may be problematic for projects targeting the Z-machine.

Skeleton Keys is compatible with, but does not require, Locksmith by Emily Short.

Example: * Vault - Demonstration of a simple skeleton key.

	*: "Vault"

	Include Skeleton Keys by Emily Short.

	The Vault is a room.

	

	The player carries a casket and a box. The casket is a closed locked container. The box is a closed locked container.

	The player carries a silver key. Everything is unlocked by the silver key.



	Test me with "unlock casket with silver / unlock box with silver key / open casket / i / lock casket with silver / close casket / lock casket with silver".

Example: * Cereal Bar Revisited - Demonstrating compatibility with Locksmith.

	*: "Cereal Bar Revisited"

	Include Locksmith by Emily Short. Include Skeleton Keys by Emily Short.

	

	The player carries a passkey called the tin key. The tin key unlocks the tin box. The tin box is closed, openable, lockable, and locked. In the box is a single Cheerio.

	

	Cereality is a room. "The newly-opened 'cereal bar' allows you to mix and match cereal types at will." The box is in Cereality.

	

	The passkey description rule is not listed in any rulebook.



	The description of a passkey is usually "[if the item described unbolts something][The item described] unlocks [the list of things unbolted by the item described][otherwise]You have yet to discover what [the item described] unlocks[end if]."

	The player carries a skeleton key. Every thing is unlocked by the skeleton key.



	Test me with "i / x key / unlock box / i / x key".