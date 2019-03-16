Inanimate Listeners by Emily Short begins here.

"Allows the player to address inanimate objects such as a talking computer, microphone, or telephone in a form such as ASK COMPUTER ABOUT COORDINATES."

Use authorial modesty.

A thing can be addressable. The addressable property translates into I6 as "talkable".

Persuasion rule for asking an addressable thing (called the target) to try doing something (this is the unsuccessful persuasion of inanimate objects rule):
	if the target is a person or the target is not addressable:
		make no decision;
	say "[The target] [cannot] do everything a person can." (A).

Inanimate Listeners ends here.

---- Documentation ----

Ordinarily, if the player tries to speak to an inanimate object, he receives a response such as "You can only do that to something animate." 

Sometimes, however, we'd like to have an item in the game that is not a person but still responds to queries -- much like the shipboard computer on Star Trek.

"Inanimate Listeners" allows us to declare any objects to be addressable, as in 

	The computer is an addressable scenery thing in the Bridge.

Once this is done, the player can ask questions or make remarks to the computer, which we can then handle in the same way we might handle remarks made to a non-player character.

By default, a persuasion rule also prevents us from ordering inanimate objects to do a full range of actions; the player will receive a response like this:

	>computer, n
	The computer cannot do everything a person can.

If we wish to remove this, we need to use the following line:

	*: The unsuccessful persuasion of inanimate objects rule is not listed in any rulebook.

We can then substitute our own persuasion rules allowing the inanimate item to do specific actions.

Example: * Command Chair - A computer that answers questions and responds to comments.

	*: "Command Chair"

	Include Inanimate Listeners by Emily Short.
	
	Bridge is a room. "Beeping and blinking, the computer awaits your instructions and requests."

	The computer is an addressable scenery thing in the Bridge. 

	Instead of asking the computer about "coordinates": say "'Our coordinates are 3,4,5.'" 

	Instead of telling the computer about "coordinates": say "'Space is surprisingly small,' you tell the computer. [paragraph break]'Parse not found,' the computer complains."

	The command chair is an enterable supporter in the Bridge. The player is on the command chair.

	Test me with "ask computer about coordinates / tell computer about coordinates / computer, n / ask chair about coordinates".



