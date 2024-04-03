# How to Use The Recipe Book

## Preface

^^{extensions: licensing of use}
**The Inform Recipe Book** is one of two interlinked books included with Inform 7: a comprehensive collection of examples, showing the practical use of Inform. The other book is **Writing with Inform**, a systematic manual for the software.

The Recipe Book assumes that the reader already knows the basics covered in Chapters 1 and 2 of *Writing with Inform*: enough to get simple projects working in the Inform application. It's helpful, but not necessary, to have some familiarity with the main ingredients of Inform. For instance, the reader who can play and test the following source text, and who can take a guess at what it ought to do, should be fine:

	"The Power of the Keys"
	
	Afterlife is a room. "Fluffy white clouds gather round you here in the afterlife." The Pearly Gates are a door in Afterlife. "The Pearly Gates - large, white, wrought-iron and splendidly monumental - stand above you." Heaven is a room. The Gates are above the Afterlife and below Heaven.
	
	St Peter is a man in the Afterlife. "St Peter, cheery if absent-minded, studies his celestial clipboard."
	
	Before going through the Pearly Gates:
		say "St Peter coughs disarmingly. 'If you'd read your Bible,' he says, 'you might recall Revelation 21:21 saying that the twelve gates were twelve pearls, each gate being made from a single pearl. I really don't know why people keep imagining it like the entrance to some sort of public park - oh, well. In you go.'";
		end the story.
	
	Test me with "enter gates".

**The Recipe Book** is not a tutorial – it offers advice and examples to crib from, not theory or systematic teaching. The examples here are provided with the express intention that authors cut and paste useful passages into their own works, modifying as they go. This is an excellent way to get things working quickly.

In the traditional saying: good programmers write good code, but great programmers steal it. (Appropriately enough, nobody seems to know who said this first.) For the avoidance of any doubt–the example text is here to be taken. Since it is part of the core Inform distribution, it is legally placed under the Artistic License 2.0, which allows its use with almost no restrictions. Its main stipulation is simply that authors who rework Inform into something different need to give the result a different name. For the avoidance of any doubt, that consideration does not apply to such small fragments of the Inform repository as the examples. So, please feel entirely free to copy and adapt code from the examples: this infringes no copyright, and requires no acknowledgement, even in a commercially sold work.

Many programming languages for conventional computing, such as C, come with elaborate libraries of ready-written code – so elaborate, in fact, that they often need much larger manuals than the language itself, and can be hard to learn. Even expert programmers typically use only a small part of what is available in such libraries, giving up on the rest as too complex to use, or too difficult to find out about, or not quite what they need.

The designers of Inform chose not to go down this road. Rather than providing a general system for liquids (say), which would have to be a quite complicated and opaque program, Inform provides a choice of examples showing how to get different effects. The writer can read the text which achieves these effects, and can simply cut and paste whatever might be useful, and rewrite whatever is not quite wanted.

The wider community of Inform writers has made a great wealth of material available in the form of Extensions, too: we don't cover the Extensions in this book, because it would grow far too long and be a constant labour to maintain, but it's well worth seeing what is out there.

### See Also

- [Acknowledgements] for a chance to try out the cross-referencing links in the *Recipe Book* - click on the red asterisk or the name of the destination to go there.

## Acknowledgements

^^{ifwiki+web+}
^{@David Fisher}'s [Past raif topics](https://www.ifwiki.org/Past_raif_topics) pages on the [Interactive Fiction Wiki](https://www.ifwiki.org/) were an invaluable tool during the early design of these examples, as they catalog an enormous assortment of implementation problems encountered by IF authors over the decades since 1990.

Thanks also go to ^{@Nick Montfort} for several conversations during the development of Inform: these inspired a number of ideas about how the author should be able to control the textual output of a story, and suggested specific problem areas to work on.

^{@Jeff Nyman} provided extensive feedback about using *Writing with Inform* in workshops of aspiring IF authors from both programming and conventional fiction writing backgrounds. His observations about the concerns of conventional writers first encountering IF were especially useful, and had a great influence on the organisation of the *Recipe Book*. While the results may not meet all the needs he identified, we hope to have taken a step in the right direction.

A few examples were contributed by denizens of rec.arts.int-fiction: ^{@Tara McGrew}, ^{@Jon Ingold}, ^{@Mike Tarbert}, ^{@Eric Rossing}, and ^{@Kate McKee} offered such elegant implementations of various tasks that we have folded their contributions (with permission) into the *Recipe Book*.

Finally, these pages owe much to the questions and suggestions of Inform users on rec.arts.int-fiction and IFmud.

## Disenchantment Bay

"Disenchantment Bay" is a simple work of IF used as a running example in the chapter on [Things] of *Writing with Inform*–not so much a tutorial as a convenient hook on which to hang some demonstrations of the basics. Because the resulting examples only use basic features and in the most straightforward way, they make for uninteresting "recipes"–so they are not included in the *Recipe Book* proper. But some readers might like to have all twelve stages of the example gathered on a single page: this is that page.

## Information Only

One last preliminary: a handful of the examples do not show how to do anything at all, but are really sidebars of information. Those examples are gathered below, since they contribute nothing by way of recipes.

# Adaptive Prose

## Varying What Is Written

^^{adaptive displayed text}^^{text substitutions}^^{randomness: text variations}
Before getting to actual recipes, many recipe books begin with intimidating lists of high-end kitchen equipment (carbon-steel pans, a high-temperature range, a Provencal shallot-grater, a set of six pomegranate juicers): fortunately, readers who have downloaded Inform already have the complete kitchen used by the authors. But the other traditional preliminaries, about universal skills such as chopping vegetables, boiling water and measuring quantities, do have an equivalent.

For us, the most basic technique of IF is to craft the text so that it smoothly and elegantly adapts to describe the situation, disguising the machine which is never far beneath the surface. This means using text substitutions so that any response likely to be seen more than once or twice will vary.

[M. Melmoth's Duel] demonstrates three basic techniques: an ever-changing random variation, a random variation changing only after the player has been absent for a while, and a message tweaked to add an extra comment in one special case. (Random choices can be quite specifically constrained, as [Ahem] shows in passing.) [Fifty Ways to Leave Your Larva] and [Fifty Times Fifty Ways] show how a generic message can be given a tweak to make it a better fit for the person it currently talks about. [Curare] picks out an item carried by the player to work into a message, trying to make an apt rather than random choice. [Straw Into Gold] demonstrates how to have Inform parrot back the player's choice of name for an object.

Another reason to vary messages is to avoid unnatural phrasing. [Ballpark] turns needlessly precise numbers–another computerish trait–into more idiomatic English. (Likewise [Numberless], though it is really an example demonstrating how to split behaviour into many cases.) [Prolegomena] shows how to use these vaguer quantifiers any time Inform describes a group of objects (as in ``You can see 27 paper clips here.``).

[Blink], a short but demanding example from the extreme end of *Writing with Inform*, shows how the basic text variation mechanisms of Inform can themselves be extended. [Blackout] demonstrates text manipulation at a lower level, replacing every letter of a room name with "*" when the player is in darkness.

For how to change printed text to upper, lower, sentence, or title casing, see [Rocket Man].

[Variety] and [Variety 2] use a relation between actions and verbs so that, for example, the verb `to eat` could be associated with the action `eating`. This enables some fancy tricks in describing actions. [History Lab] uses such tricks to show how items could be made to remember an appropriate verb to describe whatever last happened to them.

[Olfactory Settings] shows some basic but powerful ways to make text fully adaptive, in the sense that it can change tense or person dynamically in play. [Narrative Register] shows how to make adaptive verbs adapt still further, by becoming more slangy, or more upbeat, and so on.

[Responsive] modifies one of the standard "responses" from the Standard Rules — ``You are carrying nothing.`` [Wesponses] goes very much further, modifying every response to write them as if read out with an exaggerated lisp.

[Relevant Relations] provides a general way to present room descriptions in terms of what relationships exist between the things seen. Inform's regular method is excellent for human-scaled spatial situations, but what about a more abstract story, where things being `on` or `in` other things might not matter, whereas other relationships might?

[Fun with Participles] also has some fun with room descriptions, making the sentences about what is present change during play.

## Varying What Is Read

^^{understanding}^^{understanding: conditionally}^^{understanding: limiting cases where understand rules apply}^^{conditions: for (understand)+sourcepart+}^^{publicly-named / privately-named (object)+adj+} ^^{privately-named / publicly-named (object)+adj+}^^{item described (- object)+glob+}^^{plurals: defining}^^{defining: plurals}^^{English: defining plural forms}^^{pronouns: setting pronouns}^^{(IT), in player commands+commandpart+} ^^{pronouns: (IT), in player commands+commandpart+}^^{(THEM), in player commands+commandpart+} ^^{pronouns: (THEM), in player commands+commandpart+}^^{(HIM), in player commands+commandpart+} ^^{pronouns: (HIM/HER), in player commands+commandpart+}^^{(HER), in player commands+commandpart+}^^{use options: catalogue: |dictionary resolution} ^^{dictionary resolution+useopt+}
Making the printed text adapt to circumstances only makes half of the conversation graceful: the other half is to allow the player's commands to have a similar freedom. The things the player can refer to should always respond to the names which would seem natural to the player. Inform provides a variety of techniques for understanding words always, or only under certain conditions; and, if need be, we can also get direct access to what the player has typed in order to examine it with regular expressions. (This last resort is rarely necessary.)

[First Name Basis] shows how to assign names to things or to kinds of thing–if, for instance, we want the player to be able to refer to any man as ``MAN`` or ``GENTLEMAN``:

	Understand "man" or "gentleman" as a man.

We may also sometimes want to give names that are specifically plural, as in

	A duck is a kind of animal. Understand "birds" as the plural of duck.

or

	Understand "birds" as the plural of the magpie.

[Vouvray] demonstrates.

A common challenge arises when two objects have names that overlap or are related, and we wish Inform to choose sensibly between them: for instance, a cigarette vs. a cigarette case. If a word should apply to something only as part of a phrase (e.g., ``CIGARETTE`` alone should never refer to the cigarette case) we can manage the situation as follows:

	The case is a closed openable container. The printed name is "cigarette case". Understand "cigarette case" as the case.

Because ``CIGARETTE`` here appears only as part of the phrase ``CIGARETTE CASE``, it will be understood only in that context; the conflict with the bare cigarette will not arise.

As a variant, we may want one object only to take precedence over another in naming. If we wanted the player to be allowed to refer casually to the cigarette case as ``CIGARETTE`` when (and only when) the cigarette itself is not in view, we could add

	Understand "cigarette" as the case when the cigarette is not visible.

Tricks which consider the visibility of other objects can be bad for performance if used widely; but for adding finesse to the treatment of a few items, they work very well.

(There may still arise cases where the player uses a name which can legitimately refer to two different things in view. To deal with this situation, we may want the `Does the player mean...` rules, explained in the chapter on [Understanding]; and to change the way the story asks for clarification, see the two activities `Asking which do you mean` and `Clarifying the parser's choice of something`.)

Names of things which contain prepositions can also be tricky because Inform misreads the sentences creating them: [Laura] shows how some awkward cases can be safely overcome.

A more difficult case is to ensure that if we change the description or nature of something in play, then the names we understand for it adapt, too. `Understand... when...` can be all that's needed:

	Understand "king" as Aragorn when we have crowned Aragorn.

Or, similarly, if we want some combination of categories and characteristics to be recognised:

	Understand "giant" as a man when the item described is tall.

`The item described` here refers to the thing being named. `...when` can even be useful in defining new commands, and [Quiz Show] demonstrates how to ask open-ended questions that the player can answer only on the subsequent turn.

Properties can also be matched without fuss:

	Tint is a kind of value. The tints are green, aquamarine and darkish purple. The wallpaper is fixed in place in the Hotel. The wallpaper has a tint. Understand the tint property as describing the wallpaper.

This allows ``EXAMINE AQUAMARINE WALLPAPER`` if, but only if, it happens to be aquamarine at the moment. Relationships can also be matched automatically:

	A box is a kind of container. The red box is a box in the Toyshop. Some crayons are in the red box. Understand "box of [something related by containment]" as a box.

which recognises ``BOX OF CRAYONS`` until they are removed, when it reverts to plain ``BOX`` only.

Greater difficulty arises if, using some variable or property or table to mark that a bottle contains wine, we print messages calling it "bottle of wine". We are then honour-bound to understand commands like ``TAKE BOTTLE OF WINE`` in return, not to insist on ``TAKE BOTTLE``. Almost all "simulation" IF runs in to issues like this, and there is no general solution because simulations are so varied.

A converse challenge arises when we want to *avoid* understanding the player's references to an object under some or all circumstances. This is relatively uncommon, but does sometimes occur. For this situation, Inform provides the `privately-named` property, as in

	The unrecognizable object is a privately-named thing in the Kitchen.

Here `privately-named` tells Inform not to understand the object's source name automatically. It is then up to us to create any understand lines we want to refer to the object, as in

	Understand "oyster fork" as the unrecognizable object when the etiquette book is read.

Of course, if we need an object that the player is never allowed to refer to at all, we can just make this privately-named and then not provide any understand lines at all.

A final source of difficulty is that by default Inform truncates words to nine letters before attempting to identify them. This is no problem in most circumstances and is likely to go unnoticed – until we have two very long words whose names are nearly identical, such as "north-northwest exit" and "north-northeast exit". (To make matters worse, a punctuation mark such as a hyphen counts as two letters on its own.)

When we are compiling for Glulx, the limit is easily changed with a single line, setting the use `dictionary resolution` use option. For instance, if we wanted to raise the limit to 15, we would write

	Use dictionary resolution of 15.

When compiling for the Z-machine, the solution is harder. [North by Northwest] shows how to use the reading a command activity to pre-process very long names, rendering them accessible to the parser again.

Inform also allows the player to refer to the most recently seen objects and people as ``IT``, ``HIM``, ``HER``, and so on. It sets these pronouns by default, but there are times when we wish to override the way it does that. [Pot of Petunias] shows off a way to make Inform recognise an object as IT when it would not otherwise have done so.

(See Using the Player's Input for an example (Mr. Burns' Repast) in which a fish can be called by any arbitrary word as long as it ends in the letters -fish.)

### See Also

- [Liquids] for a resolution of this bottle-of-wine issue.
- [Memory and Knowledge] for a way to refer to characters whom the player knows about but who aren't currently in the room.
- [Clarification and Correction] for ways to improve guesses about what the player means.
- [Alternatives To Standard Parsing] for several esoteric variations on the default behaviour, such as accepting adverbs anywhere in the command, and scanning the player's input for keywords.

## Using the Player's Input

^^{understanding: recording the player's command}^^{text: recording from the player's command}
We may sometimes want to capture specific words the player has used and then feature that text elsewhere in the story.

[Terracottissima Maxima] demonstrates using text to describe objects; [Mr. Burns' Repast] lets the player refer to a fish by any of a number of names, and changes the way the fish is described as a result.

More specialised effects are also possible: [Xot] shows how to collect the player's erroneous input and store the command line to be printed back later. [Igpay Atinlay] shows how to parrot the player's command back in pig Latin form.

### See Also

- [Animals] for a dog which the player can re-name.
- [Traits Determined By the Player] for a way to let the player name the player character.

# Place

## Room Descriptions

^^{looking+action+}^^{rooms+kind+: descriptions}^^{rooms+kind+: printing the room contents}^^{precedence: of displayed items}^^{descriptions (displayed): initial appearance of thing}^^{descriptions (displayed): notable things in room}^^{descriptions (displayed): miscellaneous things in room}^^{descriptions (displayed): room contents}^^{mentioned / unmentioned (thing)+prop+} ^^{unmentioned / mentioned (thing)+prop+} ^^{mentioned (thing)+propcat+} ^^{unmentioned (thing)+propcat+}^^{marked for listing / unmarked for listing (thing)+prop+} ^^{unmarked for listing / marked for listing (thing)+prop+} ^^{marked for listing (thing)+propcat+} ^^{unmarked for listing (thing)+propcat+}^^{writing a paragraph about+descactivity+} ^^{writing a paragraph about+activity+} ^^{writing a paragraph about+activitycat+}^^{listing nondescript items of something+descactivity+} ^^{listing nondescript items of something+activity+} ^^{listing nondescript items of something+activitycat+}^^{printing room description details of something+descactivity+} ^^{printing room description details of something+activity+} ^^{printing room description details of something+activitycat+}^^{printing a locale paragraph about something+descactivity+} ^^{printing a locale paragraph about+activity+} ^^{printing a locale paragraph about+activitycat+}^^{paragraph: writing a paragraph about+activity+}^^{nondescript items: listing nondescript items of something+activity+}^^{room description details: printing room description details of something+activity+}^^{locale paragraph: printing a locale paragraph about something+activity+}
The printing of a room description is a more delicate business than it might initially seem to be: Inform has to consider all the objects that the player might have brought into the room or dropped there, and all the objects on visible supporters, and decide how to group and list them.

All of this behaviour is handled by the looking command, so we find the relevant rules in the `carry out looking` rulebook. To go through the elements step by step:

Looking begins by printing the name and description of the room we're in. We can introduce variations into room names and descriptions by changing their printed name and description properties, as in

	now the printed name of the Church is "Lightning-Struck Ruin";
	now the description of the Church is "The beams overhead have been burnt away and the pews are charred. Only the stone walls remain.";

If we need more drastic effects, we can turn off or change either of these features by altering the rules in the `carry out looking` rulebook. For instance, to remove the name of the location entirely from room descriptions, we would write

	The room description heading rule is not listed in the carry out looking rules.

(A word of warning: there is one other context in which the story prints a room name–when restoring a save or undoing a move. To omit the room title here too, add

	Rule for printing the name of a room: do nothing.)

[Ant-Sensitive Sunglasses] demonstrates how to use activities to make more flexible room description text.

Next, the story determines what items are visible to the player and need to be described. These never include the player himself, or `scenery`, but other things in the environment will be made `marked for listing`. This is also the stage at which Inform chooses the order in which items will be listed.

We are allowed to meddle by changing the priorities of objects, in case we want some things to be described to the player first or last in the room description; [Priority Lab] goes into detail about how. We can also force things to be left out entirely: [Low Light] handles the case of an object that can only be seen when an extra lamp is switched on, even though the room is not otherwise considered dark. [Copper River] implements the idea of "interesting" and "dull" objects: the story determines which items are currently important to the puzzles or narrative and mentions those in the room description, while suppressing everything else.

Then Inform carries out the `writing a paragraph about...` activity with anything that provides one; anything it prints the name of, it tags `mentioned`. Thus

	Rule for writing a paragraph about Mr Wickham:
		say "Mr Wickham looks speculatively at [list of women in the location]."

will count Wickham and everyone he looks at as all having been mentioned, and will not refer to them again through the rest of the room description. More complicated uses of writing a paragraph abound. A developed system for handling supporters that don't list contents appears in [The Eye of the Idol].

Inform then prints the initial appearances of objects that are marked for listing but not already mentioned; and then it performs the listing nondescript items activity, collating the remaining objects into a paragraph like

	You can see a dog, a hen, ...

We can pre-empt items from appearing in this paragraph or change their listing by intervening with a Before listing nondescript items... rule, as in

	Before listing nondescript items when the player needs the watch:
		if the watch is marked for listing:
			say "The watch catches your eye.";
			now the watch is not marked for listing.

If we wanted the watch always to be listed this way, it would be better to give it an initial appearance, but for conditional cases, the listing nondescript items activity is a good place to intervene. For instance, [Rip Van Winkle] uses this activity to incorporate changeable or portable items into the main description text for a room when (and only when) that is appropriate.

The listing nondescript items activity also allows us to replace the ``You can see...`` tag with something else more fitting, if for instance we are in a dimly lit room.

When the story compiles the list of nondescript items, it adds tags such as ``(open)`` or ``(empty)`` or ``(on which is a fish tank)`` to the names of containers and supporters. We can suppress or change the ``(empty)`` tag with the printing room description details of activity, as in

	Rule for printing room description details: stop.

The ``(empty)`` tag can appear when something is *not* truly empty if everything within is concealed or undescribed.

And we can suppress the ``(open)`` and ``(on which is...)`` sorts of tags with the `omit the contents in listing` phrase, as in

	Rule for printing the name of the bottle while not inserting or removing:
		if the bottle contains sand, say "bottle of sand";
		otherwise say "empty bottle";
		omit contents in listing.

Finally, the `looking` command lists visible non-scenery items that sit on scenery supporters, as in

	On the table is a folded newspaper.

These paragraphs can be manipulated with the printing the locale description activity and the printing a locale paragraph about activity.

Another common thing we may want to do is change the description of a room depending on whether we've been there before (as in [Slightly Wrong]) or on how often we've visited (as in [Infiltration]). [Night Sky], meanwhile, changes the description of a room when we've examined another object, so that a player's awareness of their environment is affected by other things the character knows.

### See Also

- [Looking] for ways to change the default length of room descriptions.

## Map

^^{rooms+kind+}^^{rooms+kind+: connections between rooms}^^{directions+kind+}^^{index map}^^{connections between rooms}
A work of IF contains many spectacles and activities, and these must not all present themselves at once, or the player will be overwhelmed. One way to spread them out is in time, by having them available only as a plot develops, but another is to spread them out literally in space. The player has to walk between the Library and the Swimming Pool, and thus bookish and athletic tasks are not both presenting themselves at once. There have been valiant "one-room" IFs, and it forms a respectable sub-genre of the art, but most works of any size need a map.

Inform, following IF conventions, divides the world up into locations called `rooms`, connected together by so-called "map connections" along compass bearings. Thus:

	The Library is east of the Swimming Pool.

The example [Port Royal 1] develops a medium-sized map from such sentences. This develops in [Port Royal 2] to include connections which bend around, allowing the rooms not to lie on an imaginary square grid.

Because it is useful to group rooms together under names describing whole areas, Inform also allows rooms to be placed in "regions". Thus:

	The Campus Area is a region. The Library and the Swimming Pool are in the Campus Area.

[Port Royal 3] demonstrates this further. [A&E] shows how regions can be used to write simple rules which regulate access to and from whole areas of the map.

Many old-school IF puzzles involve journeys through the map which are confused, randomised or otherwise frustrated: see [Bee Chambers] for a typical maze, [Zork II] for a randomised connection, [Prisoner's Dilemma] for a change in the map occurring during play. A completely random map takes us away from traditional IF and more towards a different sort of old-school game, the computerised role-playing game with its endless quests through dungeons with randomly generated treasures and monsters. This style of map–building itself one step at a time, as the player explores–can sometimes be useful to provide an illusion of infinite expanse: see [All Roads Lead To Mars].

While the standard compass directions are conventional in IF, there are times when we may want to replace them without other forms of directional relationship. [Indirection] renames the compass directions to correspond to primary colours, as in Mayan thinking. [The World of Charles S. Roberts] substitutes new ones, instead, introducing a hex-grid map in place of the usual one.

### See Also

- [Going, Pushing Things in Directions] for ways to add more relative directions, such as context-sensitive understanding of ``OUT`` and ``IN``.
- [Room Descriptions] for ways to modify the room description printed.
- [Ships, Trains and Elevators] for rooms which move around in the map and for directions aboard a ship.

## Position Within Rooms

^^{rooms+kind+: divided into smaller areas}
Inform's division of geography into "rooms" is a good compromise for most purposes. The rooms are cut off from each other by (imaginary or actual) walls, while all of the interior of a given room is regarded as the same place.

Suppose we want things to happen differently in different corners of the same room? Inform can already do this a little, in that the player can be inside an enterable container or on an enterable supporter. For instance:

	Instead of opening a door when the player is on the bed, say "You can't reach the handle from the bed."

If we need to have divided-up areas of the floor itself, the standard approach is to define a small number of named positions. We then need to remember at which of these locations the player (or something else) currently stands.

[Further Reasons Why All Poets Are Liars] allows the player to be in different parts of a room by standing on a box which can be in different places: thus only the box needs an internal position, not the player, simplifying matters neatly.

Another interesting case is when one room is entirely inside another (such as a hut in a field, or a booth in a large convention hall), so that the exterior of the room should be visible from another location. [Starry Void] gives a simple demonstration of a magician's booth that can be examined from the outside, opened and closed, and entered to reach a new location.

### See Also

- [Continuous Spaces and The Outdoors] for making the space between rooms continuous.
- [Combat and Death] for the use of position in a room in determining combat maneuvers.
- [Entering and Exiting, Sitting and Standing] for automatically getting up from chairs before going places.
- [The Human Body] for letting the player take different postures on furniture or on the floor.
- [Furniture] for cages, beds, and other kinds of enterable supporters and containers.

## Continuous Spaces and The Outdoors

^^{rooms+kind+: things in more than one room}^^{backdrops+kind+}
Suppose we want to blur the boundaries between rooms, in an environment where there are no walls: out of doors, for instance?

The simplest cases involve making something exceptional visible in more than one place. [Carnivale] features an exceptionally large landmark seen by day; [Eddystone] an exceptionally bright one by night. [Waterworld] allows a very distant object (the Sun) to be seen throughout many rooms, but never approached. [A View of Green Hills] gives the player an explicit command for looking through into an adjacent room.

Three systematic examples then present outdoor landscapes with increasing sophistication. [Tiny Garden] gives the multiple rooms of an extended lawn descriptions which automatically adapt to say which directions lead into further lawn area. [Rock Garden] provides a relation, `connected with`, between rooms, allowing items in one to be seen from the other: an attempt to interact with a visible item in a different area of the garden triggers an implicit going action first. [Stately Gardens] provides a much larger outdoor area, where larger landmarks are visible from further away, and room descriptions are highly adaptive.

In an outdoor environment, the distinction between a one-move journey and a multiple-move journey is also blurred. [Hotel Stechelberg] shows a signpost which treats these equally.

### See Also

- [Position Within Rooms] for making the space within a room continuous.
- [Windows] for another way to see between locations.
- [Doors, Staircases, and Bridges] for still a third way to be told at least what lies adjacent.
- [Passers-By, Weather and Astronomical Events] for more on describing the sky.

## Doors, Staircases, and Bridges

^^{doors+kind+}^^{connections between rooms: doors}^^{Locksmith+ext+} ^^{extensions: specific extensions: Locksmith}
Inform's `door` kind provides for a tangible thing which comes between one room and another. A door can be open or closed, and openable or not: it can be locked or unlocked, and lockable or not. Here we create a conventional door, a natural gap in the rocks, and a (fixed in place) wooden ladder:

	The fire door is an open door. The fire door is east of the Projection Booth and west of the Fire Escape.
	The narrow crevice is an open unopenable door. The crevice is east of the Col du Prafleuri and west of Rocky Knoll Above Arolla.
	The wooden ladder is an open unopenable door. The ladder is above the Stableyard and below the Hay Loft.

Most doors are visible from both sides: they are single objects but present in two rooms at once, which raises a number of complications. Inform normally uses the same description looking from each way, which is not very interesting: [When?] and [Whence?] demonstrate neat ways to describe the two sides differently, and [Whither?] adds the option for the player to refer to doors as ``THE WEST DOOR`` and ``THE EAST DOOR`` automatically.

[Neighbourhood Watch] goes further by making a door behave differently on each side: from the "outside" you need a key, but "inside" it opens on a latch. Finally, [Garibaldi 1] shows how to access information about the two sides of a door.

[Higher Calling] demonstrates doors which automatically open as needed: though using the Inform extension Locksmith by ^{@Emily Short} is probably easier and better. [Elsie], conversely, demonstrates a door that closes one turn after the player has opened it.

Certain complications apply when characters other than the player have to see and interact with doors that exist in other rooms. [Wainwright Acts] demonstrates the syntax needed to handle this technically quirky situation.

[Something Narsty] and [Hayseed] provide a `staircase` kind useful for vertically arranged, always-open doors like staircases and (fixed in place) ladders.

[One Short Plank] implements a precarious plank bridge across a chasm as an open unopenable door.

### See Also

- [Windows] for climbing through a window from one room to another.
- [Ropes] for portable connections between rooms, much of the development of which could be adapted to handle portable ladders. [Doors] are never allowed to move.
- [Magic (Breaking the Laws of Physics)] for a hat that lets the player walk through closed doors.
- [Modifying Existing Commands] for ways to allow the player to unlock with a key that isn't currently being carried.

## Windows

^^{scope}
Calvin Coolidge once described windows as "rectangles of glass." For us, they have two purposes: first, they offer a view of landscape beyond. In the simplest case the view is of an area which will not be interacted with in play, and therefore does not need to adapt to whatever may have changed there:

	The window is scenery in the Turret. "Through the window you see miles and miles of unbroken forest, turning from green to flame in the hard early autumn."

More interesting is to adapt the view a little to provide a changing picture: a forest may not change much, but a street scene will. [Port Royal 4] allows us to glimpse random passers-by.

The trickiest kind of window allows the player to see another room which can also be encountered in play, and to interact with what is there. [Dinner is Served] presents a shop window, allowing people to see inside from the street, and even to reach through.

[Vitrine] handles the complication of a window misting up to become opaque, and thus temporarily hiding its view.

Second, windows provide openings in walls and can act as conduits. [Escape] shows how a `door` in the Inform sense can become a window. [A Haughty Spirit] provides a general kind of window for jumping down out of: ideal for escapers from Colditz-like castles.

### See Also

- [Doors, Staircases, and Bridges] for a door which can be partially seen through.

## Lighting

^^{light} ^^{darkness}^^{lighted / dark (room)+prop+} ^^{dark / lighted (room)+prop+} ^^{lighted (room)+propcat+} ^^{dark (room)+propcat+}^^{lit / unlit (thing)+prop+} ^^{unlit / lit (thing)+prop+} ^^{lit (thing)+propcat+} ^^{unlit (thing)+propcat+}
At any place (room, or inside a container) light is either fully present or fully absent. Inform does not usually try to track intermediate states of lighting, but see [The Undertomb 2] for a single lantern with varying light levels and [Zorn of Zorna] for multiple candles that can be lit for cumulative changes to the light level.

Light can be added to, but not taken away: rooms and things can act as sources of light, by having the `lighted` and `lit` properties respectively, but they cannot be sinks which drain light away. The reason darkness is not a constant hazard in Inform-written games is that rooms always have the `lighted` property unless declared `dark`. (We assume daylight or some always-on electric lighting.) A `dark` room may well still be illuminated if a light source happens to be present:

	The Deep Crypt is a dark room. The candle lantern is a lit thing in the Deep Crypt.

[Hymenaeus] allows us to explicitly refer to torches as `lit` or `unlit`, or (as synonyms) `flaming` or `extinguished`.

For light produced electrically we might want a wall switch, as in [Down Below], or a portable lamp, as in [The Dark Ages Revisited].

The fierce, locally confined light thrown out by a carried lamp has a quality quite unlike weak but ambient daylight, and [Reflections] exploits this to make a lantern feel more realistic.

When the player experiences darkness in a location, Inform is usually very guarded in what it reveals. (``It is pitch dark, and you can't see a thing.``) [Hohmann Transfer] gives darkness a quite different look, and [Four Stars 1] heightens the other senses so that a player in darkness can still detect her surroundings. The first of the two examples in [Peeled] allows exploration of a dark place by touch.

It is sometimes useful to check whether a room that is not the current location happens to contain a light source or be naturally lighted. This poses a few challenges. [Unblinking] demonstrates one way of doing this, so long as there are no backdrop light sources.

[Cloak of Darkness] is a short and sweet game based on a light puzzle.

### See Also

- [Room Descriptions] for an item that can only be seen in bright light, when an extra lamp is switched on.
- [Looking Under and Hiding] for a looking under action which is helped by the fiercer brightness of a light source.
- [Going, Pushing Things in Directions] for making it hazardous to walk around in the dark.
- [Electricity and Magnetism] for batteries to power a torch or flashlight.
- [Fire] for a non-electrical way to produce light.

## Sounds

^^{senses}^^{actions: involving senses}^^{rooms+kind+: listening to (with no object)}^^{listening to+action+}
It is too easily assumed that room descriptions are what the player sees, but as [The Undertomb 1] demonstrates, they might just as easily include ambient sounds.

So Inform's `listening to` action is the audio equivalent of `examining`, rather than `looking`. Despite this the player can type ``LISTEN``, which Inform understands as listening to the everything in the location at once. A simple but effective way to handle this is shown in [The Art of Noise].

[Four Stars 2] adjusts the idea of `visibility` to make it behave differently for listening purposes: this introduces a formal idea of `audibility`.

### See Also

- [Lighting] for heightened hearing in darkness, and the rest of "Four Stars".

## Passers-By, Weather and Astronomical Events

^^{rooms+kind+: things in more than one room}^^{backdrops+kind+}^^{time}
Out of doors, nature is seldom still. Clouds scull by at random, as in [Weathering], and provide some variety in what would otherwise be lifelessly static room descriptions. In much the same way, passers-by and other diversions make a city street a constant bustle: see [Uptown Girls] for this human breeze. A more nagging sense of atmosphere can be experienced in [Full Moon].

[Orange Cones] offers traffic that is present on every road in the story unless a room is marked off with orange cones – and this is allowed to change during play.

[Night and Day] and [Totality] each schedule celestial events to provide a changing display in the sky above, and this time running like clockwork rather than at random.

### See Also

- [Scene Changes] for meteors and a moon-rise.

# Time and Plot

## The Passage Of Time

^^{time}^^{turns: not passing for specific actions}^^{scenes: for the passage of story time}
A story that makes heavy use of time may want to give the player a hint that time is important–and an easy way to keep track of how it's going–by adding the current time to the status line, instead of the score. To do this, we would write

	When play begins:
		now the right hand status line is "[time of day]".

All else being equal, time passes at a rate of one minute per turn. But this need not be so: we can imagine a story where turns take much less time, or much more; or a story in which the passage of time was sometimes suspended, or one in which different actions required different amounts of time to perform.

[Situation Room] provides a way to print 24-hour time, while [Zqlran Era 8] implements a completely new measurement of time, for a story set on an alien world.

[Uptempo] and [The Hang of Thursdays] speed up time's passage: turns take fifteen minutes in the former, or a quarter day in the latter.

[Timeless] makes certain actions instant, so that they don't count against the clock; this is sometimes useful in timed situations where the player needs to review the situation before going on with a tricky puzzle. [Endurance] systematically extends this idea to allow us to assign different durations to any action in the story. [The Big Sainsbury's] goes the opposite direction, and meticulously adds a minute to the clock for all implicit take actions, just so that the player isn't allowed to economise on moves.

An alternative approach to time is not to tell the player specifically what hour of the day it is at all, but to move from one general time period to another as it becomes appropriate–when the player has solved enough puzzles, or worked their way through enough of the plot. To this end we might use scenes representing, say, Thursday afternoon and then Thursday evening; then our scene rules, rather than the clock, would determine when Thursday afternoon stopped and Thursday evening began:

	Thursday afternoon is a scene. Thursday evening is a scene.
	
	Thursday afternoon ends when the player carries the portfolio.
	
	Thursday evening begins when Thursday afternoon ends.
	When Thursday evening begins:
		say "The great clock over St. Margaret's begins to chime 6.";

Though this gives time a loose relation to the number of turns played, it feels surprisingly realistic: players tend to think of time in a story in terms of the number of *significant* moves they made, while the random wandering, taking inventory, and looking at room descriptions while stuck don't make as big an impression. So advancing the story clock alongside the player's puzzle solutions or plot progress can work just as well as any stricter calculation.

### See Also

- [Passers-By, Weather and Astronomical Events] for cycles of day and night scenes.
- [Waiting, Sleeping] for commands to let the player wait until a specific time or for a specific number of minutes.
- [Clocks and Scientific Instruments] for clocks that can be set to times and that have analog or digital read-outs.
- [Timed Input] for discussion of extensions allowing real-time input.

## Scripted Scenes

^^{story structure: scenes with scripted events}^^{scenes: scripting story events in scenes}
Sometimes we want to arrange a scene in which something goes on in the background (as though it were a movie playing) while the player goes about their business; or where a series of things has to happen before the player gets to the end.

The simplest way to arrange background events for a scene is to write the sequence of events into a table and work our way through it, printing one line per turn, until the scene runs out. [Day One] does exactly this.

At other times, we want a scene to last as long as it takes the *player* to do something. [Entrapment] lets the player poke around and explore as much as they like, but ends as soon as they have accomplished the scene's goal–which, unfortunately for them, is to get into an embarrassing situation so that another character can walk in and make fun of them. [The Prague Job] has a scene that requires the player to do a more specific set of tasks, but nags them and hurries them along until they're done.

[Bowler Hats and Baby Geese] assumes that our story is going to be assembled with a number of scenes, some of which will need to prevent the player from leaving the location until the scene is complete: it thus defines a `restricted` property for scenes, so that all such elements of the plot will work in the same way.

For more complex sorts of scripts and schedules, it may be worth consulting the extensions.

### See Also

- [Characters Following a Script] for a character whose conversation with the player is scripted to follow a pattern and then conclude.

## Event Scheduling

^^{time: scripting story events by time}^^{at (time)...+assert+}
We can use a schedule of events to give some life to our environment: if we have a town setting, for instance, it makes sense for shops and libraries to open and close at set times; this is just what we find in [IPA].

[Air Conditioning is Standard] has characters who follow a timed schedule of events to interact with each other, while the player mostly wanders around missing out on the action. (Sometimes life is like that.) The same effects could have been achieved with scenes instead of clock times, but there are occasions when we do want to plan our characters' behaviour to the minute rather than waiting for the player to be in the right place to observe it: in a murder mystery or a time-travel story, the exact timings might be quite significant.

We may also want to add events to the schedule during play, as in

	 Instead of pushing the egg-timer: say "It begins to mark time."; the egg-timer clucks in four turns from now.
	
	At the time when the egg-timer clucks: say "Cluck! Cluck! Cluck! says the egg-timer."

Similarly, we can schedule things during play to happen at a specific time of day, as shown in [Hour of the Wren].

### See Also

- [Scene Changes] for more things that arrive at pre-determined times.
- [Ships, Trains and Elevators] for a train that follows a schedule, carrying the player along if they are aboard.

## Scene Changes

^^{story structure: scenes in different environments}^^{scenes: rules run at beginning}^^{scenes: rules run at end}^^{rules: run at beginning of scene}^^{rules: run at end of scene}^^{rules: for scenes}
In a plot that takes place over multiple locations or has several distinct scenes, we may want to move the player or change the scenery around them. [Age of Steam] brings a train on and off-stage as the plot requires. [Meteoric] similarly brings a meteor into view at a certain time of day, showing off several implementations depending on whether or not the player is supposed to be able to refer to the meteor after it has gone.

[Entrevaux] constructs an organised system such that all scenes have their own lists of props and associated locations, and props are moved on and off automatically. Scene changes are also announced with a pause and a new title, such as "[Chapter 2, Adaptive Prose]: Abduction".

[Space Patrol - Stranded on Jupiter] inserts an interlude in which the player's possessions and clothes are switched for new ones and the player moved to a new location–and then put back where they started from.

### See Also

- [Flashbacks] for more ways to move the player from one level of reality to another.

## Flashbacks

^^{story structure: cut scenes}^^{story structure: flashbacks}^^{Basic Screen Effects+ext+} ^^{extensions: specific extensions: Basic Screen Effects}
The viewpoint character may often need to remember events long past. The easiest way to do this is with a cut-scene, in which at some relevant point we pause the story and print a long passage of text describing the memory. Because large amounts of text can be hard for the player to take in, we may want to include some pauses in the presentation of this material; this facility is provided by the `Basic Screen Effects by Emily Short` extension, and might work something like this:

	Include Basic Screen Effects by Emily Short.
	
	Instead of examining the photograph for the first time:
		say "This reminds you of the summer of '69...";
		wait for any key;
		say "... flashback content...";
		wait for any key.

The `pause the game` phrase in the same extension offers a more dramatic pause that also clears the screen before printing new text.

Cut-scenes are easy to implement but should be used sparingly, since players often get impatient with long uninteractive passages. A slightly more deluxe implementation might insert an interactive scene that simply happens to be set in the past, before going on with another scene set `now`; and, indeed, some IF abandons the idea of `now` entirely, presenting pieces in a non-chronological order and letting the player work out how the sequence works together.

The most challenging case to implement (though still not very hard) is the one where we remove the player from one scenario, let them play through a flashback with past possessions and clothing, and then restore them to the same situation they left, with all of the same possessions and clothing. [Pine 3] shows how to do this: the code to change the player's status is isolated at the end of the example, and might fruitfully be reused.  [Pine 4] expands on the same idea by adding another flashback scene, demonstrating one that can be visited repeatedly and one that can be seen only once.

### See Also

- [Scene Changes] for more uses of stripping and restoring the player.
- [Background] for other ways of introducing information that the player character already knows.
- [Alternate Default Messages] for comments on how to change the tense of an interactive scene.

## Plot Management

^^^{story structure <-- game structure <-- plot structure}^^{story structure: dynamic plot management}
A plot manager (sometimes called a drama manager) is a piece of the program whose job it is to plan out events so that, whatever the player does, the story advances and an interesting narrative results. The plot manager might, for instance, decide that the player has wandered around for too many scenes without making any progress, and might compensate by making something happen that gives them a new hint on his current problem. It might trigger characters to act when it thinks the story should be reaching a crisis point. It might introduce new complications when it determines that the player is running out of problems to solve.

This is a theoretically challenging field. Sophisticated plot management requires that the story make difficult guesses, such as whether the player is "stuck" and what the player is working on right now. The advantage of using such a system is that (done very well) it makes the story extremely responsive to the player's behaviour, which means that they are a real agent in the unwinding of the plot. It also contributes to the replayability, since trying the story a second or third time will produce quite different outcomes. But it is procedurally difficult to design a good plot management system and it requires a huge amount of content, as well: in order for the plot manager to give the player hints, change the course of events to suit his focus, and so on, the story has to have available many, many more scenes than will ever occur in any single playing.

[Fate Steps In] is only a *very* brief sketch in this direction, one in which the "fate" entity is trying to accomplish an end goal and, every turn, looks for ways to push the story towards that conclusion, whatever the player does.

### See Also

- [Goal-Seeking Characters] for alternate ways to make characters act on their own.

# The Viewpoint Character

## The Human Body

^^{assemblies}^^{components: of bodies}^^{body parts}^^{|every: creating assemblies}
By default, Inform gives the player character (and every other person) a simple unitary body, one without hands or feet or any other defined parts. In many games this is adequate; but in others it is not enough, and we may want to endow all people with some more specific physical features, as in

	A face is a kind of thing. A face is part of every person.

Once we've done this, we may invite ambiguities if the player types ``LOOK AT FACE``; it is this challenge that is addressed in [The Night Before].

[rBGH] gives the player a random height and then uses this to determine how the room should be described around them.

[Slouching] lets the player (and other characters as well) take different sitting, standing, and lying down positions.

## Traits Determined By the Player

^^{player: customising name or traits}
Some IF tries to make the viewpoint character more congenial to the player by allowing some customisation.

[Identity Theft] demonstrates asking the player to supply the viewpoint character's name.

[Good or Evil] demonstrates a way to let the player choose a moral position at the start of play: this will mostly be interesting if the rest of the story makes some use of the player's choice. Since that example is written expressly to demonstrate included Inform 6 code, however, we may find it more congenial to generalise from the more flexible [Baritone, Bass].

This is not the only way to go–as we'll see in the next section, there's also something to be said for making the viewpoint character a strongly distinct creature with well-defined preferences and attitudes.

## Characterisation

^^{story structure: characterisation}^^{mistakes, in the player's command}^^{understand (words) as a mistake+assert+} ^^{understanding: mistakes}^^{actions: understanding as mistakes}
Much of the personality of the player character in IF emerges from what they can and cannot (or will and will not) do; part of the pleasure of playing a character arises from this opportunity for role-playing and role-exploration. Some characters are consciousless daredevils, willing to jump off cliffs, crawl through narrow gaps, and rob widows if the player commands it; others are repressed neurotics who barely dare to speak to other characters or touch anything that doesn't belong to them.

[Finishing School] and [Dearth and the Maiden] both treat the case of a character constrained by good manners and a sense of polite society: the former forbids only one action, while the latter condemns a whole range of them.

Constraining the character is only the half of it: we might also want to think about what sorts of unusual actions that character might be especially likely to take, and account for these. Of course, major actions that affect the story world will require some thought and implementation work, and we should consider carefully before making the player a character like, say, the Noble of Glamour, a spirit in human form who can charm all comers, transform bespectacled secretaries into divas, and cause spontaneous cloudbursts of scarlet glitter.

But even simple humans have some characteristic traits and gestures. We will probably want to write some characteristic reaction to ``EXAMINE ME``, as demonstrated in [Bad Hair Day]. We might provide a few pieces of clothing or props that aren't strictly critical in the story, like a policeman's helmet or a feather boa:

	The player is wearing a policeman's helmet.

We can liven up the interactive aspect of characterisation if we give the player a little scope for role-playing: this may mean responding to gestures, like

	Understand "bite nails" as a mistake ("Your only nail remaining is the one on your left thumb, and you're saving it for the AP Calculus exam.").

(Of course, we would need to have hinted to the player that nail-biting is characteristic of the player character.)

### See Also

- [Clothing] for more on dressing characters up.
- [Saying Complicated Things] for conversation, another area in which the player character's personality might come into play.

## Background

^^{story structure: providing background information}^^{knowledge (in story world): player's knowledge}^^^{knowledge (in story world) <-- player: memory <-- information}^^^{knowledge (in story world) <-- memory of player}^^{>FIND} ^^{>THINK ABOUT} ^^{>REMEMBER}
In IF, as in all interactive storytelling, an essential problem is that the player does not begin the story knowing everything that the player character should, and so may implausibly bumble through situations that the player character should be quite comfortable in. If the player character has friends, an unusual job, a home or environment we're not familiar with, a secret past, these will all be a blank to the player.

Some games get around this by making the player character an amnesiac, or positioning them as a newcomer to a strange world in which their disorientation is explicable; but there are stories that cannot be told this way, and so we need other methods of getting the player to know what the player character already does.

Our first opportunity to inform the player about the player character is in the opening text of a story:

	When play begins:
		say "The funeral is exactly a month ago now, but Elise's shoes are still on the shoe tree."

We may also want to write descriptions of objects to give extra background information the first time the player encounters them:

	A thing can be examined or unexamined. A thing is usually unexamined. After examining something: now the noun is examined; continue the action.
	
	The description of the newspaper is "A rolled-up newspaper[if unexamined], and thus a symbol of your newly-single state: Elise always had it open and the Local Metro section next to your plate by the time you got out of the shower[end if]."

To expand on this, we could give the player a ``THINK ABOUT`` or ``REMEMBER`` command, with which they can call up information about people they meet or references they encounter in descriptions, so that they could (for instance) next type ``REMEMBER ELISE``. [Merlin] demonstrates one way to implement a character with memory; [One of Those Mornings] puts a twist on this by letting the player ``FIND`` things which they know the player character possessed at some time before the story started.

## Memory and Knowledge

^^{knowledge (in story world): player's knowledge}^^{Epistemology+ext+} ^^{extensions: specific extensions: Epistemology}^^{scope}^^{any+token+}^^{understanding: things: not in scope with (any)+sourcepart+}^^{grammar tokens: for rooms}^^{grammar tokens: for things not in scope}^^{deciding the scope of something+activity+} ^^{deciding the scope of something+activitycat+}
All of us carry around in our heads an (incomplete, imperfect) model of the world around us: an idea of where we left the keys, whether the oven is on or off, how many clean pairs of socks are left in the drawer, what we look like in our best pair of jeans. The differences between that mental model and reality are to some degree a reflection of personal character: our forgetfulness, our wishful thinking, our innocence or cynicism.

By default, Inform does not keep track of the player character's knowledge (or any other character's knowledge, for that matter) as a separate thing from the model world, relying on descriptive prose rather than modeling to introduce these quirks of characterisation.

All the same, there are often times when we would like to keep track of discrepancies between the world model and the narrator's mental model. Perhaps the most common way to do this is simply to mark everything that the player encounters as "seen" when the player first examines it, thus:

	A thing can be seen or unseen.
	
	Carry out examining a thing:
		now the noun is seen.

or – to have things remembered from the first moment they're mentioned in a room description:

	Rule for printing the name of something (called the target):
		now the target is seen.

The mental model need not always be accurate, of course. We might, for instance, have occasion to keep track of where the player character last saw something, even if the object has since been moved; or keep track of falsehoods the player character has been told in conversation; or make the player refer to a character as ``THE BEARDED MAN`` until he is properly introduced.

Modeling what the player does and does not know is only half the job, of course: we also need that information to affect the behaviour of the story in plausible ways.

One obvious occasion to use player character knowledge is in the output of descriptions. We might want to respond to actions differently depending on what the player has previously done, as in [Tense Boxing], or change the way we describe objects in light of new knowledge about them, as in [Zero]. [Casino Banale] takes that idea much further, with a whole system of facts that can be narrated to the player in a somewhat flexible but interdependent order, as the player looks at relevant objects or notices them in room descriptions.

Along similar lines, we may want an object to change its name for the player depending on what the player knows. That name change should affect both what Inform displays and what it understands about the object. For instance:

	An Amherz Amulet is a thing. It can be known or unknown. It is privately-named.
	
	The printed name is "[if known]Amherz Amulet[otherwise]lizard-shaped pewter charm[end if]".
	
	The description is "[if known]It's a unique and magically powerful pewter charm shaped like a lizard[otherwise]It's some cheap tacky pewter charm shaped like a lizard. At least, as far as you can tell -- it's pretty grubby[end if]."
	
	Understand "amherz" or "amulet" as the Amulet when the Amulet is known.
	
	Understand "lizard" or "lizard-shaped" or "pewter" or "charm" as the Amulet when the Amulet is unknown.
	
	Instead of rubbing the amulet when the amulet is unknown:
		 say "You rub off a bit of the dirt, and... what do you know? It's actually the priceless and fabulously powerful Amherz Amulet!";
		 now the Amherz Amulet is known.

Finally, the player's knowledge may affect how the story interprets commands, in the determining what is called "scope". When Inform tries to make sense of something the player has typed, it makes a list of everything that the player is allowed to refer to at the moment, and then checks whether all of the objects in the player's command refer to items in that list. Only things that are "in scope" are open for discussion.

If the player mentions an object that is not "in scope" – say, a red hat left behind in the next room – Inform will issue the response "You can't see any such thing." This is also Inform's reply if the player mentions a nonsense object (``EXAMINE FURSZWIGGLE``) or an object that does not exist in the story world at all (``EXAMINE CELL PHONE`` in a story set in Carolingian France).

This is not the only possible way for interactive fiction to handle such communication. Some games will respond differently to ``EXAMINE RED HAT`` and ``EXAMINE FURSZWIGGLE``, saying in the first case something like "You can't see that now" and in the second "I don't know the word 'furszwiggle'."

The drawback of such behaviour is that the player can make premature discoveries. If they haven't found a sword yet, but think there may be a sword later in the story, they can type ``EXAMINE SWORD`` and see from the response whether their guess is correct. Nonetheless, there are people who prefer this alternative exactly because it does expose the limits of the story's understanding, preventing fruitless attempts to use a word that is not recognised at all.

Using Inform's default behaviour, however, scope is an ad-hoc way of keeping a list of things that are common knowledge between the story and the player. The player knows many things that the story might not (like what a cell phone is); the story knows a few things the player may not (like the fact that there is a sword in an as-yet unvisited room). Neither of those things can fruitfully enter into commands because they have no mutually agreed-upon referent.

By default, Inform assumes that "scope" includes only those things that are currently visible by line of sight. This works pretty well for a wide range of situations, but there are still plenty of occasions when we want to admit that the story and the player share a knowledge of things not seen. ``GO TO THE KITCHEN`` might be a useful command even when the player can't currently view the kitchen. ``ASK FRED ABOUT THE FOOTPRINTS`` should perhaps work even when the footprints are far away in the garden. ``SMELL STINKY CHEESE`` might need to work even when the cheese is invisibly locked away in a porous container but is exuding a stench. In a dark room, the player can't see their own inventory, but they should still remember that they're carrying it and be able to mention it. And sometimes we might want the story to acknowledge that the player is referring to an object that they have seen somewhere, even if that thing is now out of sight.

In practice, we have two ways to tinker with scope: we can change the scope for a specific command, using a token with any, as in

	Understand "go to [any room]" as approaching.
	Understand "find [any thing]" as finding.
	Understand "ask [someone] about [any known thing]" as interrogating it about.

Or we can add areas and items to scope for all commands, as in

	After deciding the scope of the player when the surveillance camera is switched on:
		place the jail cell in scope.

[Puncak Jaya] demonstrates understanding references to characters who are currently off-stage.

### See Also

- [Helping and Hinting] for objects tagged with a `seen` property when the player first encounters them.
- [Getting Acquainted] for a character whose name is changed during the course of play as the player gets to know them better.
- [Room Descriptions] for more ways to change the description of a room depending on player experience.
- [Going, Pushing Things in Directions] for ways to understand the names of distant rooms and move towards them.
- [Character Knowledge and Reasoning] for models of knowledge for other characters than the player.
- [Sounds] for ways of tracking audible objects separately from visible ones.
- [Lighting] for ways to change what the player knows about and can manipulate in dark rooms.
- [Clocks and Scientific Instruments] for a telescope that lets the player view objects in another location.
- [Continuous Spaces and The Outdoors] for more on seeing into adjacent locations.

## Viewpoint

^^{story structure: changing viewpoint}^^{player: changing the identity of the player}^^{+to+now (a condition): changing the player's identity}^^{tense: of standard responses} ^^{English: tense: of standard responses}^^{narrative viewpoint, of standard responses} ^^{English: narrative viewpoint, of standard responses}
Inform automatically creates a character for the player–a bland, personality-free entity at the outset, as we've seen. But there is no reason why the player need stick to this same identity throughout the story. Conventional fiction often jumps from one viewpoint character to another, and so can IF.

To do this at the most elementary level, we simply at some point

	now the player is Janine;

where Janine is a person we've already defined in the code. Now the player is in whatever location Janine inhabits, carries whatever Janine carries, and wears whatever Janine is wearing. [Terror of the Sierra Madre] shows off this effect, and also demonstrates how to make the command prompt remind the player which character they currently control. Some games instead give this information in the status line or after the name of the location when looking, producing output like

	The Bottomless Acherousia (as Charon)

We could do the same by adding a line such as

	After printing the name of a room while constructing the status line or looking:
		say "[roman type] (as [the player])"

Of course, we'll need a good deal of other work to make Janine a distinct person from whichever character the player was before. The distinction may come from changed capabilities of the new character, which we can express through new rules about actions; e.g.,

	Instead of listening when the player is Janine:
		say "Your childhood accident left you unable to hear any but the loudest noises. Currently there is only silence."

Janine may also have new, different perspective on her surroundings, expressed through the descriptions of the things she looks at; [Uncommon Ground] makes a `by viewpoint` token for text alternatives, allowing us to tag our descriptions to indicate which variations should be shown to which viewpoint characters. [The Crane's Leg 1] and [The Crane's Leg 2] offer more elaborate and specialised ways of customising the player character's observations to depend on how they relate (physically and in attitude) to the things around them.

If we want to change the tense and person of narration from the conventional present second person, we may do this as well:

	When play begins:
		now the story viewpoint is first person plural;
		now the story tense is past tense.

Though this only changes the form of the text produced automatically by Inform (responses such as ``You can't go that way`` might become, say, ``I couldn't go that way``), and all author-written text in the story must be written in the tense and person intended.

# Commands

## Designing New Commands

^^{actions: defining new actions}^^{defining: actions}
Quite a bit of interactive fiction design involves the creation of custom commands to expand on the library's existing set. There is more to know than we can review in this section; instead, this is to serve as an overview of the process, with hints about where in *Writing with Inform* we might find more technical details.

Before we even start to write our source text, we should think about the following things:

1. What words will the player use to make this new action happen?
2. What will the action change about the world model?
3. What circumstances might make the new action go wrong or produce silly outcomes?

To take these one one by one:

(1) We may have a general idea of the phrasing we want the player to use – say we want to add a ``SHOOT`` command which allows the player to fire a gun at something. (This is an intentionally tricky choice of verb, because it shows off so many possibilities.) So we might decide the base form of the action will be

	> SHOOT THE PISTOL AT HENRY

So now we're going to need an action that applies to two objects – the pistol as the noun, and Henry as the second noun. The problem is, though, that there are lots of other ways that the player could reasonably formulate the command, some of which leave out information:

	> SHOOT HENRY
	> SHOOT PISTOL
	> FIRE PISTOL
	> SHOOT AT HENRY
	> SHOOT AT HENRY WITH GUN

To avoid frustrating the player, we should make a guess about what the player means whenever we're sure that guess will be reliable (we might, for instance, have only one gun in the story, so we know that ``SHOOT HENRY`` will always mean ``SHOOT HENRY WITH PISTOL``), but ask the player for clarification whenever there might be ambiguity (``SHOOT PISTOL`` gives no clue about the target, nor can we safely guess, so we want Inform to ask "What do you want to shoot the pistol at?"). The next section goes into more detail about how to handle these variations.

Conversely, there are cases where the player is offering too *much* information for the command we've defined–say we have a ``BURN`` command which doesn't look for a specified fire source, but the player is trying to ``BURN BOX WITH MATCH``. We probably don't want to throw away the extraneous information as though it had never been typed, because the player might have typed something quite specific. ``BURN BOX WITH ACID``, say, should not be cavalierly reinterpreted as ``BURN BOX`` (with a fire source). Instead, we want to give the player a bit of gentle guidance, perhaps using "Understand as a mistake", as in

	Understand "burn [something] with [text]" as a mistake ("Your choice of lighter isn't important in this story: BURN SOMETHING will suffice.")

Finally, there are some cases where we want to understand a phrase to mean a specific form of a more general action. For instance, we might want ``TURN DOWN THE MUSIC`` to mean the same thing as ``SET VOLUME KNOB TO 1``. In this case, we may want to make a sort of dummy action which converts into the main action, as in

	Understand "turn down volume" or "turn down music" or "turn down the volume" or "turn down the music" as lowering the volume. Lowering the volume is an action applying to nothing.
	
	Instead of lowering the volume, try setting the volume knob to 1.

More about this can be found later in this chapter, under Remembering, Converting and Combining Actions.

Sometimes these kinds of details can be caught in play-testing, but it's a good idea to think about them specifically and in advance rather than leaving them to our beta-testers to sort out.

(2) To generalise very broadly, there are two possible kinds of command in IF: those that only exist to give the player new information (like ``EXAMINE``, ``INVENTORY``, ``LOOK``, ``TASTE``), and those that change the world model (like ``TAKE FISH``, ``OPEN DOOR``, ``UNLOCK GATE WITH BLUE KEY``). The Inform library has some commands that really do none of these things by default–commands like ``JUMP`` that do nothing interesting at all most of the time–but those exist as hooks, in case there is ever something important for them to do.

Commands that ask for information are usually easier to implement. Very often we're looking to offer the player a new kind of information about specific objects, and these can be handled by adding new text properties, as in

	A thing has some text called the sacred emanation.
	
	Carry out perceiving something:
		say "[sacred emanation of the noun][paragraph break]".

Commands that affect the world model, on the other hand, can range from simple to very complex indeed. Sometimes we need to do nothing more than add an attribute to an object, like

	A thing can be folded or flat. A thing is usually flat.

so that our ``FOLD`` command can change the object into its folded form. At other times, we need quite intricate rules to account for a subtle multi-stage process–how fire is burning and spreading to objects, say, or how a conversation is progressing. Other parts of the Recipe Book offer solutions to some of these challenges.

(Strictly, we might count a third kind of command: the kind that controls the story itself. The chapter on [Advanced Actions] discusses how to add actions out of world, as these are called, but the difficult ones are already built into Inform–saving, restoring, restarting, undoing a turn, and so on. Mostly when we need to add new actions out of world, they will be help or hint systems of some kind. More about these can be found in the Helping and Hinting section of the Recipe Book, under Out of World Actions and Effects.)

(3) Most commands that change the world require certain preconditions: the player needs to be holding the gun before it can be fired; the gun must be loaded with ammunition; if we're being especially detailed in our simulation, the safety must be off.

Often, there are also subtler details about how the command should interact with special items. For any new command we create, it's worth asking: should anything special happen if the player performs this action...

- On himself?
- On another living character?
- On an object they (or another character) are carrying or wearing?
- On an object they (or another character) are inside or on?
- On a door?
- On an object that is impossible to move (defined as `scenery` or `fixed in place`)?
- On an intangible object (such as a beam of sunlight)?
- On an object far away (such as the sun)?
- On an object that is part of something else (such as a doorknob)?
- On an object that itself has parts (such as a desk with drawers)?
- If there are two objects required by the action, can both the noun and the second noun be the same thing?

For instance, we might have written code so that if the gun is fired at anything but a person or a fragile object, the default response is `"The bullet bounces harmlessly off [the second noun]."` Our checklist would remind us to write special cases to prevent

	> SHOOT GUN AT MY SHOE
	> SHOOT GUN AT ME
	> SHOOT GUN AT GUN

and so on. Actions that destroy objects are especially tricky, because there are many things that aren't safe to destroy without carefully adjusting the world model. (What happens if we burn a door connecting two rooms? a wooden desk with a drawer containing an asbestos vest? the armchair Cousin Fred is sitting on?)

## Writing New Commands

^^{understand (verb) as (action)+assert+} ^^{understanding: verbs}^^{synonyms}^^{actions: requirements for actions}^^{(requiring), in defining actions+sourcepart+}^^{understanding: requirements for objects in actions}^^{grammar tokens}^^{actions: rules for new actions}^^{rules: for new actions}^^{rulebooks: for new actions}^^{RULES+testcmd+} ^^{testing commands: >RULES}
Once we've considered all the design issues pertaining to a new action, we're ready to start writing the source text. First we need to give the player a way to issue the command:

	Understand "smile" as smiling.
	Understand "fold [something]" as folding.
	Understand "shoot [something preferably held] at [something]" as shooting it with.
	Understand "wrap [something preferably held] in [something preferably held]" as wrapping it in.

(Note how `it` stands in for the first item when we have an action requiring two objects.) The things that go in square brackets are called "tokens": they are blank spaces for the player to fill in with story objects. The different kinds of tokens are explained in the chapter on [Understanding].

We can add synonyms with

	Understand the command "grin" as "smile".

and we can create reversed versions of commands with

	Understand "shoot [something] with [something preferably held]" as shooting it with (with nouns reversed).

These variations are also covered in the chapter on [Understanding]. If the action needs to work on things that aren't within the player's sight or reach in the normal way, we may need to use an [any thing] token (see the chapter on [Understanding]), as in

	Understand "contemplate [any thing]" as considering.

We may also need to modify reach or light levels (see Changing reachability and Changing visibility in the chapter on [Advanced Actions]), or rely on the `Deciding the scope of...` activity.

As for guessing the player's intention when a command isn't clear, we may want to consult the `Does the player mean rules` (to help Inform make guesses between multiple possible targets) and the activities `Supplying a missing noun` and `Supplying a missing second noun` (to help Inform guess an appropriate item when the player leaves something entirely out of his command). For instance, if the player typed ``SHOOT HENRY``, it is the supplying a missing noun/second noun activity that would allow us to make Inform draw the obvious conclusion that they shoot Henry with the pistol they are carrying. The `Does the player mean` rules are discussed in the chapter on [Advanced Actions]; the activities in the chapter on [Activities].

Next we need to define our new action, as in

	Smiling is an action applying to nothing.
	Folding is an action applying to one thing.
	Wrapping it in is an action applying to two carried things.

In cases where we're using an `"[any thing]"` token to let the player affect objects that aren't normally visible or reachable, we'll need to define the action to apply to *visible objects*. This tells Inform that the player doesn't have to be able to touch the object for it to work. So for instance

	Considering is an action applying to one visible thing.

For more on this topic, see Visible vs. touchable vs. carried in the chapter on [Advanced Actions].

The next step is to create rules for Inform to follow when the action happens. These can be `check` rules (which make sure that the conditions for the action to occur are fulfilled); `carry out` rules (which perform the action); and `report` rules (which describe the results of the action to the player). Any new action should have at least a `report` rule to let the player know what has happened (if anything), and a `carry out` rule if there are any ramifications for the world model. For instance:

	Carry out folding:
		now the noun is swan-like.
	
	Report folding:
		say "You deftly fold [the noun] into the shape of a swan."

It's important to remember that `report` rules may be describing something whose name is plural, such as papers or shoes, and write our text so that it sounds right either way; see the chapter on [Adaptive Text and Responses].

More about defining actions and creating `carry out` and `report` rules may be found in the chapter on [Advanced Actions].

Meanwhile, the `check` rules give us a chance to provide sensible restrictions on how the command works, as in

	Check folding:
		if the noun is not a napkin:
			say "[The noun] won't bend." instead.
	
	Check shooting something with the noun:
		say "[The noun] is incapable of aiming at itself." instead.
	
	Check burning something which contains the player:
		say "You're not quite desperate enough to make a funeral pyre for yourself just yet." instead.

The chapter on [Advanced Actions] explains how `check` rules work. In the special case where we want the player to take things automatically before using them, we may want to define the action to work only on carried objects, as in

	Wrapping it in is an action applying to two carried things.

The activity Implicitly taking something (documented in the chapter on [Activities]) allows us to modify what should happen during this process.

Lastly, a word or two about trouble-shooting. If a newly created command seems not to be working, we can discover what action Inform is really generating with the ``ACTIONS`` testing command, as in

	> ACTIONS
	Actions listing on.

	> I
	[taking inventory]
	You are carrying nothing.

	[taking inventory - succeeded]

If the desired command is not happening, we may need to review our understand lines. A common problem is that our new action conflicts with one already defined by default. In that case, we may want to check the Actions index and see whether there are already-defined actions which might conflict with it. If so, we may need to redefine a command with a line like

	Understand the command "stand" as something new.

If that's not enough, we can get a comprehensive view of everything that happens during an action with ``RULES``: this will list all the `check`, `carry out`, and `report` rules that Inform is using to perform the command.

### See Also

- [Memory and Knowledge] for more about the any token and the concept of scope to control what the player may refer to in a command.

## Modifying Existing Commands

^^{actions: processing sequence}^^{actions: rules for actions found in rulebooks}^^{rules: for actions found in rulebooks}^^{rulebooks: for actions}^^{before (action)+rb+: in action processing sequence} ^^{rules: before rules}^^{instead of (action)+rb+: in action processing sequence} ^^{rules: instead rules}^^{after (action)+rb+: in action processing sequence} ^^{rules: after rules}^^{check (action)+rb+}^^{carry out (action)+rb+}^^{report (action)+rb+}^^{(instead), to stop the action+sourcepart+}^^{rules: removing}^^{rules: replacing}^^{extensions: Inform 6 template layer}^^{Inform 6 inclusions: Inform 6 template layer}^^{templates, Inform 6 template layer}
Much of the rest of this chapter discusses the behaviour of specific commands in Inform's command library, and how we might change and build on these. This section is instead an overview of the general principles: where and how can one intervene?

Whenever we are dealing with actions, the Actions Index is likely to be useful: it lists all the actions currently implemented, whether in our own source or in extensions or the Standard Rules, and lists the rules pertaining to each.

The lightest and easiest way to change behaviour is with an Instead rule:

	Instead of eating the apple:
		say "It turns out to be made of beeswax, so that's a non-starter."
	
	Instead of tasting an edible thing:
		say "It's delicious!"
		rule succeeds.

The addition of `rule succeeds` tells Inform that the instead action was a success rather than a failure; this is not usually very important with the player's own actions, but can be useful for actions performed by other characters, so that a successfully replaced action is not followed by the disconcerting line

	Clark is unable to do that.

Before and After offer alternative easy forms of modification; the chapter on [Basic Actions] explains all three.

Changing the way an action works in all cases is usually better addressed by changing the main rulebook, rather than with one (or many) instead rules. We may add new `check`, `carry out`, and `report` rules to existing action rulebooks. The chapter on [Advanced Actions] describes these, and ends with some guidelines on when to use `before`, `instead`, and `after`, and when to use `check`, `carry out`, and `report`.

Similarly, we may delete, move, or replace rules that are already present (see the chapter on [Rulebooks]). This is handy if we decide that an action has restrictions that we dislike and want to abolish. If the restriction we need to change is part of the accessibility rules–those which check whether the player can take, see, and touch items–we may need to look at "Changing reachability" or "Changing visibility" in the chapter on [Advanced Actions] (to revise what is allowed), or at `Deciding the scope of something` in the chapter on [Activities] (to influence what the player can refer to in commands, and also what can be seen when).

If, for instance, the player character is a burly fellow who can lift any other character they like:

	The can't take other people rule is not listed in any rulebook.

...and rip knobs off doors:

	The can't take component parts rule is not listed in the check taking rulebook.

...and commit petty theft:

	The new can't take people's possessions rule is listed instead of the can't take people's possessions rule in the check taking rulebook.
	
	This is the new can't take people's possessions rule:
		if someone (called the owner) carries the noun:
			say "(first waiting until [the owner] is distracted)";

The right approach to use also depends a bit on how systematic a change we anticipate. We may find that instead rules become cumbersome when we want to specify behaviour for a very large number of objects. It's fine to have

	Instead of tasting the arsenic:
		say "You'll live to regret this very very shortly.";
		end the story.

but a bit more tedious to have to write

	Instead of tasting the peppermint: ...
	Instead of tasting the plate: ...
	Instead of tasting the banister: ...
	Instead of tasting the donkey: ...
	(etc.)

in a story in which most items have unique flavour descriptions. In that situation, it may be more sensible to overhaul the design of the action: create a new text property for things, and revise `tasting` so that it now consults this property:

	The block tasting rule is not listed in any rulebook.
	
	A thing has some text called the flavor. The flavor of a thing is usually "Nothing special."
	
	Report tasting something:
		if the flavor of the noun is "Nothing special.":
			say "You taste nothing unexpected." instead;
		otherwise:
			say "[the flavor of the noun][paragraph break]" instead.
	
	Report someone tasting something:
		say "[The actor] licks [the noun]."

Finally and most sweepingly, we can rip out whole passages of the Standard Rules and replace them–or not. This is a drastic measure and rarely necessary (or so we hope); but see the chapter on [Extensions] for ways to replace sections of existing source, or even revise the Inform 6 template files on which Inform depends. By these means almost anything can be changed. We can throw out a whole range of existing commands and start from scratch, for instance, if we want Inform to know about a completely new and different command set.

### See Also

- [Magic (Breaking the Laws of Physics)] for a hat that lets the player walk through closed doors, and an NPC able to reach through solid containers.

## Looking

^^{looking+action+}^^{rooms+kind+: descriptions}^^{descriptions (displayed): room contents}^^{use options: catalogue: |VERBOSE room descriptions} ^^{VERBOSE room descriptions+useopt+}^^{use options: catalogue: |BRIEF room descriptions} ^^{BRIEF room descriptions+useopt+}^^{use options: catalogue: |SUPERBRIEF room descriptions} ^^{SUPERBRIEF room descriptions+useopt+}
Looking is quite a complicated command, since the production of a room description takes many steps. A detailed description of this process may be found in the Room Descriptions section.

By convention, a player sees full descriptions of rooms they enter more than once, but may type ``BRIEF`` in order to see shorter descriptions, and ``SUPERBRIEF`` tells the story never to print room descriptions at all. ``VERBOSE`` restores the default behaviour.

These conventions are not always appropriate, however, especially in works where experiencing a changing environment is essential. The use option

	Use brief room descriptions.

changes the default behaviour so that rooms are not always described fully to the player. [Verbosity 1] demonstrates how this works.

The player always has the option of turning room descriptions to ``BRIEF`` or ``SUPERBRIEF`` mode. [Verbosity 2] demonstrates how we might remove the player's ability to change the default behaviour.

### See Also

- [Room Descriptions] for a detailed description of how Inform creates room descriptions and how to change the results.
- [Going, Pushing Things in Directions] for ways to change just those room descriptions that are shown as the result of the player's movement.
- [Memory and Knowledge] for ways to change the room description in response to the player character's knowledge at any given stage of play.

## Examining

^^{examining+action+}^^{devices+kind+: displaying the on/off state}
By default, examining an object shows its description, and–for devices–tells us whether the object is switched on or switched off.

This kind of additional information is not always what we want, so if we have a device whose on/off status we want to conceal, we may write

	The examine devices rule is not listed in any rulebook.

On the other hand, there are times when we may want to add a similar line or two to the descriptions of other kinds of objects. [Crusoe] allows us to append an ``It is charred.`` sentence to the end of descriptions of things we have burned in the fire. Since it works by introducing a `printing the description` activity, Crusoe is also a good example to start from if we want to introduce more complex, flexible descriptions of items throughout our story.

[Odin] rewrites the ``You see nothing special...`` line with other text of our own, for items that otherwise do not have a description.

Finally, we may want to look at multiple things at once. [The Left Hand of Autumn] demonstrates how we might provide a different response for ``EXAMINE PAINTINGS`` than for examining each individually; [Beekeeper's Apprentice] provides a ``SEARCH`` command that will show the descriptions of all the scenery in the current location.

### See Also

- [Actions on Multiple Objects] for an alternative ``EXAMINE ALL`` command.

## Looking Under and Hiding

^^{hiding things under other things <-- concealment+rel+: under other things}^^{searching+action+}
Finding hidden objects is a classic puzzle in IF. [Beachfront] provides the most basic example, an object that becomes visible only when we have searched the papers on a cluttered desk. [Beneath the Surface] takes this further, giving all large furnishings the ability to conceal items, and allowing the player to put things underneath other things, as well as find them. [Flashlight] adds an extra twist to the puzzle by requiring that the player have a flashlight to shine under a bulky object in order to find what lies underneath.

Looking inside an object is generally handled by the `searching` action, and we could extend that to allow the player to search multiple or complex objects. [Matreshka] turns the puzzle on its head by allowing the player to search a whole room systematically with only a single command.

### See Also

- [Kitchen and Bathroom] for the related case of needing to look in a mirror.

## Inventory

^^{inventory: taking inventory+action+} ^^{taking inventory+action+}
Occasionally we would like to change the way the name of something is printed as part of our inventory, and we can do this with a printing the name rule such as

	Rule for printing the name of the dead rat while taking inventory:
		say "dead rat (at arm's length)"

There are also several possibilities for redesigning the inventory list as a whole. [Persephone] shows how to divide an inventory list into two parts, a ``You are carrying: `` section and a ``You are wearing: `` section. [Equipment List] goes further, and shows how we might use Inform's specialised listing functions to create a variety of differently formatted inventories.

Sometimes the way Inform by default lists properties such as ``(closed)`` or ``(open but empty)`` isn't quite what we want. [Oyster Wide Shut] offers a flexible alternative to the standard behaviour, allowing finer control over which properties are listed and how they are described.

[Trying Taking Manhattan] replaces the inventory behaviour for other characters: instead of silently looking through their possessions (but not describing them to the player), they now describe to the player what they're carrying and wearing.

## Taking, Dropping, Inserting and Putting

^^{taking+action+}^^{taking+action+: implicit taking}^^{dropping+action+}^^{inserting it into+action+}^^{putting it on+action+}^^{implicitly taking something+activity+} ^^{implicitly taking something+activitycat+}
We may want to change the default refusal message when the player tries to pick up scenery: [Replanting] demonstrates this case simply.

[Removal] modifies responses to successful ``TAKE`` commands, with the effect that when the player picks up an item, they get a response such as ``You take the book from the shelf.``

[Croft] modifies the ``DROP`` command, so that objects dropped on specific surfaces get reported in a special way. [Celadon] allows the player to drop even objects they are carrying indirectly, for instance on a tray or in a sack.

[Morning After] introduces a simple rule that changes the behaviour of the whole story: whenever the player takes an item they haven't already looked at, they automatically examine it. This picks up the pace of exploration passages where the player is likely to be collecting a large number of objects.

When objects are moved, there are sometimes other actions associated with that which we want to happen as well; see [Democratic Process] for a demonstration of forcing a player to vote before a ballot is placed in a machine.

[Sand] shows how to extend the ordinary command grammar of Inform to allow multiple objects to be inserted or placed in a single command.

Taking also happens as a result of other commands. Such takes can be made unnecessary by turning off the `carrying requirements rule` under particular circumstances, or presented differently using the implicitly taking activity.

## Going, Pushing Things in Directions

^^{going+action+}^^{pushing things: rules for pushing things}^^{things+kind+: pushable between rooms}^^{room-describing action (- action name)+actvar+}^^{directions+kind+}^^{looking+action+: as part of going}^^{exiting+action+}
Going is the most complex of actions after looking (or perhaps including looking): the success of every movement depends on the direction the player goes; the room they start from; the room they intend to reach; whether there are any doors intervening (and, if so, whether these are closed or locked); whether they are travelling by vehicle; and whether they are pushing anything in front of them. When they get there, the description they see is itself generated by a looking command.

Pushing something in a direction is really a sort of going. The command ``PUSH WHEELBARROW WEST`` first checks certain qualifying rules: by default, only things defined as pushable between rooms may be pushed, and they may be pushed only in horizontal directions (not ``UP`` or ``DOWN``) – though these rules can be overridden, as we see in [Zorb]. If the player's `pushing` attempt passes these criteria, the action is translated automatically into a `going` action, with all the usual checks about whether that direction leads anywhere, whether a door is in the way, and so on. The converted action afterward can be caught with such rules as

	Instead of going to the Alpine Meadow with the wheelbarrow:
		say "You don't want to crush the delicate blooms."
	
	Instead of going north with the handcart:
		say "The headwind is so stiff that you are unable to make much northerly progress at all while encumbered by the handcart."

Since the two actions are internally being handled as one, both are discussed here.

It is very common for players to make a mistake and type the wrong direction command, or even to misunderstand the room description and not recognise all the possible exits. [Bumping into Walls] helpfully adds a facility so that when the player tries to go in the wrong direction, the story lists the correct possibilities, as in

	From here, the viable exits are to the south, the east and the west.

Assuming that travel succeeds, another useful technique is to provide some sense of the journey between locations, especially if they are remote from one another or the player has to do something unusual to get from one to the other. [Up and Up] adds a short description of travel when we approach a new room, before the room description is printed; [Veronica], conversely, adds a comment when the player leaves a region of the map. [The Second Oldest Problem] intervenes and kills a player who tries to travel from one dark room to another. [Mattress King] embellishes the description that automatically results from ``PUSH MATTRESS WEST``, adding a line that describes the player pushing the object before describing the new room approached.

We may also want to add a brief comment when we arrive in a new room, after the room description is printed. One trivial way to do this is to append the line to the room's main description, conditionally, like this:

	The Hammock Emporium is a room. "This is Cousin Ed's shop, the big dream he left accounting to pursue. You can't help gawking at the Luxury Leather Space Hammock, made of genuine red buffalo skins[if unvisited]. [paragraph break]So this is why Grampa makes all those 'lying down on the job' jokes every Thanksgiving[end if].".

But often we want our first-glance comment to come after some items in the room are described; and for this effect, we would use the `first look rule` defined in [Saint Eligius].

If these methods are not enough, the looking action has an action-specific variable called `the room-describing action`, which records whether this particular instance of looking comes about because the player typed ``LOOK`` or because the player travelled to a new location. We can consult this variable if we want to make looking work  differently after going, as for instance here:

	Check looking when the room-describing action is the going action:
		say "You are temporarily too blinded to see." instead.

Another category of examples treat how we handle the movement commands themselves. The eight compass directions, with ``UP`` and ``DOWN``, ``IN`` and ``OUT``, are used as standard in most interactive fiction, but they are not the only possible way of navigating, and strike many newcomers to the genre as counter-intuitive, since when strolling around in real life most of us rarely think about our travel in terms of compass orientation. [Misadventure] allows the player to ``GO TO`` a named room, instead, and calculates the best route to reach the destination; [Safari Guide] builds on this by letting the player make the whole trip in a single move, automatically opening any doors that stand in their way en route.

In the same spirit of interpreting the player's intentions sensibly, [Provenance Unknown] modifies the pushing command so that if the player pushes the top object in a stack of objects towards a direction, Inform attempts to move the bottom item instead. This is convenient if, for instance, we have a heavy television on a movable cart and want ``PUSH TELEVISION WEST`` to work just as well as ``PUSH CART WEST``.

We also sometimes want to respond sensibly to terse movement commands or ones that rely on some knowledge of where the player has already been. [Polarity] provides a ``GO BACK`` command, allowing the player to retreat in the direction from which they came, while [Minimal Movement] understands ``LEAVE``, ``GO``, and so on as ``OUT``, in the absence of other information. [Owen's Law] takes this further, calculating from the best routes on a map how to make ``OUT`` mean "move towards the exit of this indoor room", and ``IN`` mean "proceed further into the interior". [Wonderland] assigns altitudes to all rooms and works out the local best meaning of ``UP`` and ``DOWN`` accordingly.

### See Also

- [Map] for how to create other kinds of new direction.
- [Varying What Is Read] for further divisions of the standard compass, such as north-northwest.
- [Ships, Trains and Elevators] for ship-board directions.
- [Bicycles, Cars and Boats] for common vehicles in which to travel the map.

## Entering and Exiting, Sitting and Standing

^^{entering+action+}^^{exiting+action+ <-- standing}
Under ordinary circumstances, Inform does not keep track of the player's posture, nor of their exact location in a room. [Lies] implements a room in which the player can lie in different positions on the floor, getting different views as a result.

Our other examples are all modifications of the way Inform handles player movement to make better default guesses at what they want to do: [Anchorite] adds a ``GET DOWN`` and ``DOWN`` command that work when the player is on a supporter, to accompany ``GET UP``, ``GET OFF``, and ``GET OUT`` (already understood). [Get Axe] makes the player get out of a portable container before attempting to lift it–a consideration that comes up relatively rarely, but that might pertain to inflatable rafts, beanbag chairs, and other lightweight but capacious pieces of furniture.

### See Also

- [Position Within Rooms] for a box the player can push around the room and stand on in different locations.
- [The Human Body] for letting the player sit, stand, or lie down systematically on furniture or on the floor.
- [Furniture] for various objects on which the player can sit or stand.

## Waiting, Sleeping

^^{waiting+action+}^^{time: waiting intervals of time}^^{sleeping+action+}
The standard ``WAIT`` command makes time pass at the same rate that it would anyway–one minute per turn. In a story where events happen at specific times of day, though, we might want to give the player more control. [Nine AM Appointment] shows how to give the player a ``WAIT 10 MINUTES`` command, while [Delayed Gratification] lets them ``WAIT UNTIL`` a specific time of day.

Ordinarily, Inform also refuses to allow the player to ``SLEEP`` and ``WAKE UP``: the commands exist, but have no effect. [Change of Basis] lets the player enter a sleep state in which they cannot do anything. A somewhat more interesting expansion on this idea would be to let the player sleep and have dreams; there are no examples specifically of dream states, but we might consult the examples on scenes about how to disrupt one environment and move the player to another, entirely new one.

### See Also

- [Scene Changes] for ways to move the player to a new environment such as a dream state.

## Other Built-In Actions

Many other actions are themselves very simply implemented and provide only a shell for us to expand on according to the needs of a particular story. Many of these are discussed at more length in sections on various kinds of props and objects; in particular:

### See Also

- [Modifying Existing Commands] for ways to override automatic takes or restrictions on what the player must be able to hold or touch.
- [Sounds] for ``LISTEN``.
- [Barter and Exchange] for ``GIVE`` and ``SHOW``.
- [Combat and Death] for ``ATTACK``.
- [Saying Simple Things] for ``ASK``, ``TELL``, and ``ANSWER``.
- [Food] for ``TASTE`` and ``EAT``.
- [Liquids] for ``DRINK``.
- [Clothing] for ``WEAR`` and ``TAKE OFF``.
- [Bags, Bottles, Boxes and Safes] for ``OPEN``, ``CLOSE``, ``LOCK``, and ``UNLOCK`` as applied to containers.
- [Doors, Staircases, and Bridges] for ``OPEN``, ``CLOSE``, ``LOCK``, and ``UNLOCK`` as applied to doors.
- [Furniture] for things the player can ``ENTER`` and ``GET OUT`` of.
- [Money] for ``BUY``.
- [Fire] for ``BURN``.
- [Glass and Other Damage-Prone Substances] for ``CUT``.

## Magic Words

^^{XYZZY}

^^{Punctuation Removal+ext+} ^^{extensions: specific extensions: Punctuation Removal}^^{punctuation: removing from player's command}^^{magic words}
Many fantasy games incorporate the idea of magic words that can be spoken. In implementing these, we want to be a bit flexible and accept a range of input regardless of whether the player explicitly speaks the command aloud: ``XYZZY``, ``SAY XYZZY``, or perhaps even ``CAST XYZZY``. The inventively named [Xyzzy] demonstrates how we might define such a command.

^^{@Emily Short}

If we want to go even further and to allow the player also to use quotation marks, as in ``SAY XYZZY``, we may want to include Punctuation Removal by Emily Short, which allows for quotation marks to be stripped out of the player's input before it is understood.

## Remembering, Converting and Combining Actions

^^{actions: redirecting actions}
Sometimes we want Inform to apply a player's action to a different target than the one specified: for instance, directing all (or almost all) commands from the doorknob to the door of which it is a part. [Fine Laid] demonstrates how to do this. Along the same lines, [Lucy] shows how to direct a player's conversation action to apply to a new conversation topic.

We can also record a series of actions performed by the player or by another character.

[Cactus Will Outlive Us All] demonstrates characters each of whom reacts to a very specific provocation; [I Didn't Come All The Way From Great Portland Street] implements a game show in which the player is not allowed ever to repeat an action they have already performed; and [Leopard-skin] implements a maze which the player can escape only by performing a specific sequence of actions.

[Anteaters] provides a peculiar gizmo that can remember actions performed in its presence and force the player to reiterate them.

## Actions on Multiple Objects

^^{actions: applying to multiple objects}^^{lists: the multiple object list}^^{+to+multiple object list}^^{deciding whether all includes+activity+} ^^{deciding whether all includes+activitycat+}^^{understanding: deciding whether (ALL) includes something+commandpart+}^^{(ALL), including things in+commandpart+}
Inform allows a handful of actions–``TAKE``, ``DROP``, ``PUT``, ``INSERT``–to apply to more than one item at a time, so that the player can move things around easily.

The general principle is that multiple objects are allowed if the actions are likely to be successful but not interesting most of the time, and if they're things that the player could plausibly do all at once. For most actions, the use of ``ALL`` would seem weirdly indiscriminate: ``EAT ALL``, say, describes very implausible behaviour, and ``EXAMINE ALL`` would likely generate a screenful of text at once.

But this is all under our control. To create an action that uses multiples, or to allow the use of multiple objects with an already-existing action, we need to create an understand statement that uses the `"[things]"` token (note the plural). For instance:

	Understand "give [things] to [someone]" as giving it to.

This would let the existing ``GIVE`` command apply to multiple objects, in just the same way that ``TAKE`` does. [Shawn's Bad Day] demonstrates how we might allow ``EXAMINE ALL`` to print descriptions of every visible item.

Alternatively, we could generate a new action:

	Understand "give [things] to [someone]" as multiply-giving it to. Multiply-giving it to is an action applying to one carried thing and one thing.

(In theory the language here should perhaps be `several carried things` – but Inform is still going to process multiply-giving item by item, unless we redirect it. More about this in a moment.)

When handling an action that uses the `"[things]"` token, the parser makes a list of every item to which it is going to apply the action: this is called the multiple objects list. The multiple objects list can be the result of a vague request (``GET ALL``) or a specific one involving identical multiples (``GET PENNIES``, ``GET THREE APPLES``) or a very specific one involving unique, named nouns (``GET GERBIL, APPLE, AND POMEGRANATE``).

We can manipulate what Inform includes in ``ALL`` in sentences like ``TAKE ALL`` with the `deciding whether all includes...` activity; for instance

	Rule for deciding whether all includes scenery: it does not.

prevents ``TAKE ALL`` from applying to things that can't be moved anyway, avoiding lots of lines like

	tree: That's hardly portable.
	swing set: That's hardly portable.

A slightly tedious technical note: the multiple objects list is not strictly a list in the standard Inform sense, because it is used so frequently in parsing that it would be cumbersome to handle it with the more flexible but less efficient structure used for lists. However, if we want to manipulate the multiple objects list as though it were an ordinary list – that is, sort it, rotate it, truncate it, remove entries from it, etc – we may do so by creating a list like this:

	let L be the multiple object list.

and later after making L conform to our desires:

	alter the multiple object list to L.

Inform next repeatedly runs the action rulebook for the action generated, using each item from the multiple object list as `noun` in turn (or as `second noun`, if that's where the [things] token appeared in the understand line). Since it is possible to alter the multiple object list before the `generate action rule` portion of the turn sequence consults the rulebooks, we can also affect the order in which the player's matched objects are handled; see [Formicidae]. We should not attempt to change the multiple object list after this point, because this is likely to introduce bugs.

Each time Inform tries the action on a new noun, it prefixes the action-attempt with the name of the item it's currently working on. This is where we get such output as ``frog eyeballs:`` and ``newt toes:`` in long lists like

	frog eyeballs: Taken.
	newt toes: Taken.

These names are generated by the `announce items from multiple object lists rule` in the action-handling rules; [Escape from the Seraglio] shows how to alter them. In the context of this rule, the thing we are currently printing the name of can be called `the current item from the multiple object list`.

Suppressing names of objects entirely, while occasionally tempting, may have unintended consequences, especially if some of the attempted actions are prevented by check rules that themselves print things. It is safest to suppress the multiple object names in the case where we already know that the action will succeed wherever it is attempted (more often for observational actions like examining than for manipulative actions like taking, or where we mean to completely override default handling).

Given that our hypothetical `multiply-giving` applies to each given object in turn, it might seem to be useless to create `multiply-giving` as an action different from `giving` – but the convenience is that manipulating the multiple object list makes it possible to group behaviour artificially. The trick here is that, on the first pass of the multiply-giving rulebook, we look at the entire multiple object list, perform actions, print output, and set a flag saying that the action has been handled. The flag tells Inform not to do or print anything for any of the subsequent passes through that action rulebook; thus we artificially create a situation where, instead of performing an action on each object in turn, Inform acts once on the entire group. That allows us to assess the cumulative qualities of the group and have the action respond differently than it might when assessing each item individually.

[The Facts Were These] demonstrates how we might write an action for ``GIVE THREE DOLLARS TO MAN`` or ``GIVE PIE AND HAT TO MAN`` where the man would only accept the collective gift when its total proved satisfactory.

[Western Art History 305] demonstrates how we might allow ``EXAMINE``, which doesn't normally permit multiple objects, to take them, but to give vaguer responses to a mass examination than an individual one.

[The Best Till Last] shows a technique for arranging a multiple-object list into a more narratively satisfying order.

### See Also

- [Examining] for groups of objects that have a collective description different from their individual descriptions, and for commands that search multiple things at once.
- [Dispensers and Supplies of Small Objects] for ways to let the player pick up a number of identical items from a dispenser or supply.

## Alternate Default Messages

^^{responses (library messages)}
Often we will want to replace the text produced by Inform by default: this includes quite a wide range of text, much of which either describes the success of a command or explains why the action failed.

Inform provides the Responses system to enable default messages like ``You can't go that way`` to be changed, and this is capable of making large-scale changes. This is especially useful if we want to give the viewpoint character a distinctive voice and set of mannerisms.

## Clarification and Correction

^^{>USE}^^{disambiguation: of player commands}^^{understanding: error messages for parsing errors}^^{error messages: for player commands}^^{parser error messages}^^{Mistype+ext+} ^^{extensions: specific extensions: Mistype}
Some commands and some objects raise special challenges when it comes to working out the player's intention.

Sometimes this can be done with good rules about the assumptions Inform should make. [Alpaca Farm] demonstrates a ``USE`` command, always a challenge because ``USE`` can mean very different actions with different items.

There are also times when we need to ask the player for more information. [Apples] demonstrates how sensibly to use properties to disambiguate between similar objects, while [Walls and Noses] rephrases the disambiguation question when special objects are involved: examining one of the walls of the room will make the story ask ``In which direction?`` and ``EXAMINE NOSE`` will lead to ``Whose nose do you mean, Frederica's, Betty's, Wilma's or your own?``

At other times, the player types something that is wrong in a predictable way: for instance, we might want to remove all the ``WITH...`` phrases from commands like

	> HIT DOOR WITH FIST
	> KICK DRAGON WITH FOOT
	> LOOK WEST WITH EYES

and merely parse the remainder of the command. (That last command may be unlikely, but novice players do quite often type commands that refer unnecessarily to body parts.) [Cave-troll] demonstrates how.

[WXPQ] demonstrates how to modify the error message the parser gives in response to a command it doesn't understand; this particular example focuses on the ``That noun doesn't make sense in this context`` message that arises from using the `"[any thing]"` or `"[any room]"` tokens, but the techniques could be adapted to handling other parser errors as well.

## Alternatives To Standard Parsing

^^{understanding: alternatives to standard parsing}^^{adverbs}^^{keyword-style parsing}
Very occasionally, for out-of-the-ordinary games, we want to make major changes to the way that Inform ordinarily understands commands.

[Cloves] shows how we might read adverbs in the player's command: adverbs are challenging because they can legitimately appear anywhere in a command structure, so must be found and accounted for before the rest of the command is understood.

[Fragment of a Greek Tragedy] goes further, substituting a keyword-recognition parser for the usual structure of commands and objects.

Less drastically, menus of numbered options can temporarily replace or augment standard commands. [Down in Oodville] demonstrates how to add a list of transporter destinations from which the player may choose by numeral.

### See Also

- [Traits Determined By the Player] for ways to ask the player a question at the beginning of play.
- [Saying Simple Things] for a way to ask the player a yes-no question any time during play.

# Other Characters

## Getting Acquainted

^^{names: of characters}^^{characters (people): names and titles}^^{Punctuation Removal+ext+} ^^{extensions: specific extensions: Punctuation Removal}^^{punctuation: removing from player's command}
Talking about characters presents some special challenges. For one thing, some characters are referred to by a proper name, but others are not: so the story might want to talk about "Jack" but also about "the drunk pedestrian". In the absence of other information, Inform attempts to divine our intentions based on the words with which we defined a new character: but we can always override its guess with an explicit statement, such as

	The Great Malefactor is proper-named.

[Belfry] demonstrates further how titles are set at the start of play.

The relation between the player and the other characters is not always static, however. Sometimes we want the player to learn a character's name part-way through play, and start referring to "the drunk pedestrian" as ``FERNANDO``. Similarly, the status of another character may change due to some twist of the plot. [Gopher-wood] shows how to change the name of a character mid-story, and [Peers] handles changing the character's rank.

Alternatively, of course, the player character may already know some of the other characters when the story begins, even if the player does not. In that case, we may want to add a tag-line or so of identification to a character's name when they first appear in the story. [A Humble Wayside Flower] shows one way of doing this.

Another occasional challenge is dealing with such commands as ``EXAMINE DR. THISBY``. The problem here is that Inform by default will understand the full stop in ``DR.`` to be the end of one command and the beginning of another, and will try to interpret ``THISBY`` as a verb. If we do have a story populated by such formally-addressed characters, we may turn to Punctuation Removal, which provides a phrase to remove the full stops in standard titles before attempting to interpret the command.

Other characters have physical characteristics as well as names, of course, and [Meet Market] demonstrates one way of implementing people with notable features.

Finally, in some IF, the roles of characters may change from playing to playing. If we are writing a replayable murder mystery, we might want to select a new culprit each time the story starts; for this, see [Clueless].

### See Also

- [The Human Body] for more on body parts and physical description.
- [Memory and Knowledge] for a way to refer to characters whom the player knows about but who aren't currently in the room.

## Liveliness

^^{characters (people): acting spontaneously}^^{every turn+rb+}^^{rules: run every turn}
A character who sits still in a chair and does nothing is much less convincingly alive than one who seems to be pursuing some sort of personal agenda. There are all sorts of ways to achieve this, but the least challenging is by introducing some random change to descriptions, and by giving a character some very simple routine behaviour to carry out.

For instance, we'll often want the characters in a room to be described doing different things every time we look at them. [Camp Bethel] shows how this may be done.

Every turn rules lend some sprightliness to otherwise-silent characters, as well:

	Every turn when the player can see Mrs MacGillicuddy:
		say "Mrs. MacGillicuddy vacuums around [a random fixed in place thing which is in the location]."

We might expand on this by providing a whole table of things for Mrs MacG. to cycle through, or a text variation effect that gives her different activities every turn, as in

	Every turn when the player can see Mrs MacGillicuddy:
		say "Mrs. MacGillicuddy [one of]vacuums around the furniture[or]tries to remove gum from the underside of the desks[or]causes a racket by testing the smoke alarm[or]makes a pointed comment or two about them as sit by idly while someone works her fingers to the bone[as decreasingly likely outcomes]."

This is no great innovation in characterisation by itself, but it does at least remind the player that the character is alive and moving about, even when they aren't paying attention to her.

[Annoyotron Jr] demonstrates a character who actively tries to get our attention, and whose routine of behaviour changes just slightly if we show signs of having reacted to them.

[Lean and Hungry] implements a classic thief, a character who doesn't interact with the player much except to pick up valuable objects they find left around the map. Later we will see rather more advanced ways to make characters act on their own goals and plans, but this kind of simple behaviour is easily rigged as part of an every turn rule.

Finally, [Text Foosball] extends the every-turn-rule idea to create an opponent who joins us in a randomised game of table soccer.

With animal characters, this kind of repetitive, semi-random behaviour is often adequate: we don't expect animals to talk, or pursue steady goals, or to take an interest in what we do in their presence (unless it involves a food they like to eat).

For people, we are likely to need an assortment of additional techniques.

### See Also

- [Animals] for a domestic cat and dog.

## Reactive Characters

^^{characters (people): reacting to the player's actions}^^{actions: reactions by other characters}
As we observe characters, so they observe us. Those who seem to have no awareness of what the player is doing often come across more like waxworks than like people. [Zodiac] demonstrates a scenario where the watchful presence of a dangerous criminal keeps the player from doing what they otherwise might, while [Police State] expands on this idea with a policeman who reacts to entire types of behaviour in his presence, regardless of whether the culprit is the player or a third party. [Noisemaking] has a crow who will fly away in response to any loud noises the player makes.

And, of course, we definitely want to have characters react to being looked at or otherwise interfered with. [Search and Seizure] implements a smuggler who reacts when we try to confiscate their possessions. [Pine 1] gives us a sleeping princess who can be woken by a variety of methods.

We wrap up this section with two complete puzzle scenarios that demonstrate what can be achieved by giving characters reactions to the player's behaviour. [A Day For Fresh Sushi] has a fish who watches the player's actions and comments on them, while the live furnishings in [Revenge of the Fussy Table] instead comment every turn on the current state of the world, until the player has successfully sorted out all their complaints.

## Barter and Exchange

^^{characters (people): accepting gifts}^^{giving it to+action+}
By default, Inform characters are a bit grudging about giving and sharing objects: they react with disinterest when they're shown things and refuse everything they're offered.

If we'd like to change this, we can simply remove the default `block giving rule`, as in

	The block giving rule is not listed in the check giving it to rules.

If we do this, giving items to characters will have the result of moving our possessions to the other person's inventory. Of course, without more customisation, the player may not ever be able to persuade the other character to return their possessions. [Bribery] demonstrates a scenario in which a character will accept gifts that interest them, and respond with a changed attitude to the player.

[Barter Barter] expands further on this by allowing other characters to trade things with one another.

### See Also

- [Modifying Existing Commands] for ways to allow the player to give or show things that they aren't currently carrying.
- [Actions on Multiple Objects] for an implementation of giving that allows the player to offer multiple objects at once, where their combined value determines whether they are accepted.
- [Money] for ways to keep track of cash flow, physical money objects, and price negotiations.

## Combat and Death

^^{characters (people): combat}^^{combat}^^{randomness: combat with random results}^^{use options: catalogue: |undo prevention} ^^{undo prevention+useopt+}^^{>UNDO}
Not all characters are friendly, and there are times when we may want to include a fight sequence. There are a number of ways to approach this, depending on whether we want to offer the player a random outcome, a predetermined one, or a combat sequence that depends partly on strategy or on having the proper equipment.

[Lanista 1] demonstrates randomised combat in the style of a role-playing game. The player has a partially random chance of doing any given amount of damage; both the player and their opponent have hit points, and whichever one runs out first dies. [Lanista 2] continues this idea, but includes weapons that affect the amount of of damage done. [Red Cross] by itself implements a command that we might use to find out how strong characters are at the moment.

A word of warning about designing such sequences: a player who gets a roll they don't like always has the option of ``UNDO``-ing a turn and re-rolling. This means that they can always win a random battle sooner or later; bad luck only means that it takes them longer (so they get more bored and irritated as they play through). It is possible to turn off ``UNDO`` implementation with

	Use UNDO prevention.

...but there is a good chance that this will irritate players in itself. Role-playing-style combat scenarios need careful design, lest they actively make a story less fun.

In a slightly more realistic setting, combat leaves physical remains behind, unless we're wielding some kind of futuristic weapon that evaporates our opponents entirely: [Puff of Orange Smoke] demonstrates characters who leave corpses behind when they die, while [Technological Terror] more tamely explodes robots into numerous component parts.

Finally, we can imagine some scenarios in which, instead of allowing characters to strike at each other for random damage, we want to introduce an element of strategy. [Don Pedro's Revenge] shows the rudiments of a system in which the characters can make different kinds of attack depending on where they are in a room filled with perches, barrels, and other swashbuckler props.

### See Also

- [Saving and Undoing] for more discussion of handling random behaviour in games.

## Getting Started with Conversation

^^{dialogue <-- conversation <-- characters (people): dialogue}^^{story structure: dialogue}
Traditionally, conversation is one of the most difficult things to program in interactive fiction, because of the number of factors affecting the outcome of everything the player does. While it's acceptable for ``EXAMINE POT`` to produce the same response every time the player types it, it's a bit less acceptable for ``ASK JOE ABOUT HIS ADULTERY`` to make Joe react the same way every time.

Conversation implementations often need to keep track of a lot of information: what else is going on in the model world, what the character knows, what plot phase we've reached, what mood the character is in, what else we've recently been talking about, whether we've said the same thing before (and how many times); and so on. Later in this chapter we will look at ways to model character knowledge and mood.

Then, too, we have the problem of how the player communicates their conversational intentions to the story. Technology has not yet advanced to the point where a player can simply type in remarks in full natural English and have the character detect the significance, emotional tone, and subtext, if any: so we can't have ``RACHEL, THIS DESSERT TASTES LIKE FEET`` or ``WILL, LOOK! OUR SINISTER METAL FOES ARE APPROACHING!`` or ``BOSS, I WOULD BE DELIGHTED TO FILE ANOTHER TPB REPORT``.

The challenge is to create an interface that is both easy for the player to use and expressive enough to be interesting. We will look at some of the common solutions in [Saying Complicated Things].

The examples in the following sections point out ways to approach common conversation problems. None of them will offer an adequate system if we want to write a very conversationally rich story, however. This is partly because a thorough conversation system requires quite a lot of code in its own right. It's also partly because there is no one right solution to the problem of conversation design. Different games will have quite different requirements. When making decisions about a new story we have planned, it may be useful to glance through the conversation extensions available for Inform: there are quite a few, offering a range of different interfaces. Even if none is exactly suited for our needs, they may suggest ways to solve particular implementation challenges.

At the other end of the scale, though, there are times when Inform's default implementation is too complicated for what we want to do: so we will start with ways to simplify conversation, before moving to all the exotic complexities.

Before we get into these details, though, we have a couple of examples that are literally about getting started with a conversation: [Mimicry] introduces the feature that we must greet other characters before beginning to speak to them; [The Gorge at George] corrects the player's attempts to use a ``TALK TO`` command where a different mode of interaction is appropriate instead.

## Saying Simple Things

^^{dialogue: simple terms}^^{dialogue: with inanimate objects}^^{characters (people): Inanimate Listeners+ext+}^^{(YES), responding to a character+commandpart+}^^{(NO), responding to a character+commandpart+}^^{dialogue: >ASK / TELL}^^{Inanimate Listeners+ext+} ^^{extensions: specific extensions: Inanimate Listeners}^^{Punctuation Removal+ext+} ^^{extensions: specific extensions: Punctuation Removal}^^{punctuation: removing from player's command}
There are times when even the commands ``ASK`` and ``TELL`` are overkill: sometimes the player doesn't have much information to offer, so ``TELL`` is never useful, for instance. If we don't want to make any distinction between modes of conversation, we can conflate the actions so that ``ASK LUCIUS ABOUT OLLIVANDER``, ``TELL LUCIUS ABOUT OLLIVANDER`` and ``LUCIUS, OLLIVANDER`` all do the same thing: see [Sybil 1].

If we are frequently permitting the player to say things like ``LUCIUS, OLLIVANDER`` as shorthand for ``TALK TO LUCIUS ABOUT OLLIVANDER``, then we may also want to allow ``LUCIUS, OLLIVANDER?`` This makes the player character seem a bit slow (or at least Laconic), but it is an effective interface in some cases. The trick is that the question mark at the end of the command may prevent Inform from recognising the keyword; should that problem arise, we may want to use `Punctuation Removal` to erase question marks from the player's command before attempting to interpret it.

Along the same lines, there are situations in conversation where similar commands do not correspond to the same actions within Inform; if we're careless about this, we may force the player to guess which vocabulary we want them to use, which is always vexing. Some cases to look out for:

Inform has actions for `saying yes` and `saying no`. Sometimes this is useful, but sometimes we want ``YES`` and ``SAY YES TO FRED`` to do the same thing. [Sybil 2] shows how to roll these responses into one; [Proposal] expands on the idea to show more ways in which a player could reasonably answer a question put by another character.

Again, if we want ``ASK SYBIL ABOUT CAKE`` to do the same thing as ``SHOW CAKE TO SYBIL``, we might use the technique in [Nameless] to make objects into valid topics of conversation, and to make ``ASK`` and ``SHOW`` behave the same way.

Finally, if we want to be able to ``ASK`` and ``TELL`` an inanimate object – say, a computer – about something, we may use the extension Inanimate Listeners to add this capability.

### See Also

- [Remembering, Converting and Combining Actions] for ways to redirect one conversation command to another conversation topic.
- [Varying What Is Read] for a way of asking the player trivia questions that they can answer only on the next turn.

## Saying Complicated Things

^^{dialogue: >ASK / TELL}^^{dialogue: menu-based dialogue}^^{dialogue: keyword-based dialogue}
As we saw in the overview, there are challenges in choosing the commands with which the player will communicate to the story. Two common approaches are ``ASK``/``TELL`` conversation, where the player can ask or tell characters about keywords, as in ``ASK JILL ABOUT JACK`` or ``TELL FARMER ABOUT CHICKEN COOP``, and menu-based conversation, where the player is offered a list of things to say and must pick one (often by number), as in

``` transcript
1) Ask Jill where Jack went.
2) Tell Jill that the chicken coop was robbed.
```

or, sometimes,

``` transcript
1) "Jill, have you seen your no-good layabout brother Jack anywhere?"
2) "Look, Farmer Jill, I think a fox got into the chickens."
```

The problem with ``ASK``/``TELL`` conversation is that it can feel undirected–if the player doesn't know which keywords to ask or tell about next, they get stuck. It also doesn't always provide much sense of ongoing context or conversational flow, since the player can ask lots of unrelated questions and jump around a lot. What's more, sometimes the thing the player character asks isn't quite the question the player had in mind. If we type ``ASK JILL ABOUT JACK``, Jill could wind up answering any of a number of questions–where Jack is, how old Jack is, whether Jack committed the recent murder, and so on. The player doesn't have much fine control over the conversation. Nonetheless, this is sometimes just what we want: [Farewell] implements a moderately sophisticated system along these lines, which keeps track of what the player has already said and allows them to review past conversation.

Menu-based conversation solves most of these problems: a branching tree of conversation choices maintains a consistent flow of discussion, it's hard for the player to run out of things to say, and the player always knows what their character is about to say. But there are compensating flaws. For one thing, a menu doesn't allow for many surprises. The player can see all the conversation the story has to offer by working methodically through all the menu branches. (This problem is sometimes referred to as the "lawnmower effect", since the process of seeing all the conversation is like the process of running a lawnmower over every inch of the lawn. It becomes a chore rather than an entertainment.) Menu systems can be long-winded to set up and therefore none are exemplified here, but several have been released as extensions for Inform.

Since about 2001, more and more IF has used a sort of compromise method: the player is allowed to ask or tell about keywords, but they're sometimes given prompts about things to say that follow naturally on the conversation they were just having, as in

	You could ask where Jack is.

Moreover, when they ask about a topic where many comments are possible, they'll be allowed to clarify, either using a menu or through a disambiguation question such as

	> ASK JILL ABOUT JACK
	Do you want to ask where Jack is, how old Jack is, or whether Jack committed the recent murder?

[Sweeney] implements one such hybrid type of conversation.

A third option is to take away almost all the player's expressiveness and give them just one command, ``TALK TO``. The player can ``TALK TO`` characters whenever they want, and the story will pick the most appropriate thing for them to talk about. This works best in works with few or simple puzzles and a fast-moving, constrained plot, where the player will keep having new things to talk about. [Cheese-makers] demonstrates this.

Finally, a few extreme games try to fake natural language understanding by looking for keywords in the player's input, rather than an exact grammar. This is perilous, because it is all too easy for the story to completely misunderstand what the player meant to type. Nonetheless, for the sake of example, see [Complimentary Peanuts], in which the incomprehension is partly excused by the fact that the player is talking to someone a bit hard of hearing.

## The Flow of Conversation

^^{dialogue: structure of conversation}^^{story structure: dialogue}
All this discussion of conversation commands and ways to model dialogue doesn't address the higher-level design issue: how do we approach writing this material so that it has a rhythm and flow? How do we know when we've created enough conversation? How can we avoid sounding hopelessly stilted when the nature of IF implementation requires us to break our text into small snippets?

While most authors develop their own approaches, there is some general advice that may help, especially for works that have a strong narrative progression.

It helps to have the plot of the story, with all its component scenes, planned in advance. That doesn't mean there can't be any changes later, but having a list of the different scenes can help us remember the different contexts in which information can appear. If we're using Inform's scenes feature, we may even want to restrict some dialogue to be available only during a given scene.

The next step is to go through scene by scene and create the "spine" of the scene. What *must* be said during this section? Is there anything the player can't leave without knowing? If the player isn't moving the scene forward fast enough, will the other character or characters volunteer information in order to keep the pace going?

It often helps to draft a transcript showing what we imagine as the ideal playthrough of the scene–writing straight through can create a natural flow of dialogue–before dividing the dialogue into pieces for implementation.

Once the scene is complete enough for the player to get through from beginning to end, we can start filling it out. At this point, it sometimes helps to play through the scene a number of times and add new dialogue elements as we think of things that our character might reasonably want to say. Sometimes these additions will turn out to be short tangents from the main flow of a very directed scene; sometimes they might be important branches that lead the scene to an entirely alternate outcome. The main thing is to make sure that, if the scene needs to hit certain points before ending, none of our branches keep the player from returning to the subject at hand.

## Character Emotion

^^{characters (people): characterisation}^^{story structure: characterisation}
In a complex story, characters may evolve strong feelings about the player. Often we want to hint at the character's feelings through gesture and tone of voice–little things woven into dialogue and action sequences that might otherwise be unchanged. [Ferragamo Again] demonstrates creating phrases to give all our characters different ways to express their irritation at the player.

Then again, sometimes a discussion might produce quite spectacular results if a character is in the wrong mood. [Being Peter] shows the bare bones of an implementation in which a character's attitude rulebook is consulted to determine what her response will be–allowing for arbitrarily complicated outcomes.

## Character Knowledge and Reasoning

^^{knowledge (in story world): other characters' knowledge}^^^{knowledge (in story world) <-- characters (people): memory}
A character may be endowed with knowledge and even reasoning skills. Relations form quite a good way of keeping track of such problems: for instance, we can allow characters to be acquainted with one another with a relation such as

	Lucy knows Lady Cardew.

Or we might keep track of more complicated attitudes between characters, as in [Murder on the Orient Express], in which some characters suspect others of the crime.

Alternatively, we might have a list of salient facts that are important in our story. We might declare these as values, and then characters could know, learn, and forget entries as appropriate:

	A fact is a kind of value. Some facts are defined by the Table of All Known Facts.
	
	Knowledge relates various people to various facts. The verb to know (she knows, they know, he knew, it is known) implies the knowledge relation.
	
	Table of All Known Facts
	fact   	summary
	shoe-size   	"Lucy wears a size 9 shoe."
	sunset-time   	"Sunset is at 8:22 PM this evening."
	
	Lucy knows shoe-size.
	Bob knows sunset-time and shoe-size.

Or again we might keep a whole database of information in a table: the characters in [Questionable Revolutions] know dates, countries, and a short description for each of several rebellions and popular uprisings, while in [The Queen of Sheba], Solomon is able to answer who, what, where, when, and why questions about a range of topics. This kind of approach is most useful when the characters need to display a deep knowledge of a particular field. The facts stored in the `Table of All Known Facts`, above, are comparatively sparse, because there we are designing a story in which not all data about the world is equally valuable: Lucy doesn't know the shoe size of every person in the story, because for some reason it is only her own shoe size that matters. On the other hand, the `Table of All Known Facts` can store different kinds of information, whereas the revolutions table has no way of storing shoe sizes or sunset times. And [Murder on the Orient Express] works differently again, because it is storing knowledge that concerns people and things that already exist in the world model, rather than abstract ideas. Our way of modeling character knowledge, in other words, will depend quite a lot on what kind of knowledge it is.

The possibilities of character reasoning are similarly broad, but [The Problem of Edith] introduces one kind: the character has a concept of how different conversation topics relate to one another, so that when she is asked about a new keyword, she picks a response that makes the question most relevant to the conversation already in progress.

We end with a longer scenario, in which we track what the character knows about the player and the conversational state: in [Chronic Hinting Syndrome], the main character guides conversation in the direction they intend it to go, with the player's sometimes-reluctant participation.

### See Also

- [Obedient Characters] for a character who needs to be taught how to perform actions before doing them.
- [Characters Following a Script] for a programmable robot who can be given whole sequences of actions to perform.

## Characters Following a Script

^^{dialogue: scripted conversations}^^{characters (people): scripted conversations}^^{story structure: cut scenes}
So far we've seen characters who will answer questions whenever the player feels like asking, and characters who will use some reasoning procedure to direct the conversation. There is a third option, often useful in IF with a fast-paced narrative: the character follows a conversational script, making sure to cover a series of points before the scene ends.

There are more and less tedious ways to implement this kind of scene. The worst case is one in which the player is not allowed to interrupt or ask any questions; they must merely wait until the character runs out of things to say. This can be useful and plausible in very small doses–say, two or three turns–but if the character has more information than that to impart, we may want to make the scene more interactive.

[Pine 2] partly addresses this challenge: the character has a line of conversation that she wants to follow to its conclusion; we may ask questions along the way, but if we're silent, she'll take up the slack, and the scene won't end until she's done with what she has to say.

Another kind of script is a series of actions for the character to perform. [Robo 1] demonstrates a programmable robot that will observe what the player does, then try to emulate the actions later when switched into play-back mode. [Robo 2] extends this capacity to allow the robot to contain fifteen different scripts which the player can store, list, run, and erase.

[Your Mother Doesn't Work Here] offers a character with a list of tasks but whose plans can be interrupted by more urgent demands. This verges on not being a simple script any more: if we carry the idea to its natural conclusion, we get characters capable of planning scripts for themselves to accomplish their aims. This is conventionally called "goal-seeking".

### See Also

- [Goal-Seeking Characters] for characters that work out plans for themselves in order to accomplish various outcomes.

## Travelling Characters

^^{characters (people): moving around}^^{going+action+: other characters moving around}
There are a number of ways we can make characters navigate our map. We might reasonably want them to approach and follow the player (as in [Van Helsing]); or to allow the player to follow characters who have left the room (as in [Actaeon]).

Characters who are less interested in the player will more likely follow their own courses around the available geography, however. A character may move randomly from room to room, as demonstrated in [Mistress of Animals]; they may follow a path that we have specifically written in advance, as [Odyssey] shows; or, most elegantly, the story may use the "best route" calculation to find the best possible way to a given target room, as seen in [Latris Theon].

This final method is arguably the neatest solution to character movement, allowing for characters to act in sophisticated ways; if we incorporate the Locksmith extension, other characters will even unlock and open doors that are in their way. The chief catch is that it should not be used too profligately with large numbers of characters, since on slow machines the processing power required to plan all their travel will make a noticeable difference to the running speed of the story.

All the same, the constraints are not so severe as to preclude having a moderate number of route-finding characters all wandering around at once. This does introduce a new problem, however: movement descriptions can become hard to follow if every turn produces long reams of reports such as

``` transcript
Joe enters the room from the south.
Lawrence opens the gate.
Lawrence departs to the west.
Lucy comes in from above.
Ted enters the room from the south.
Bill departs to the west.
```

[Patient Zero] tackles this problem by calculating all of the character movement without printing any text; it then combines similar or related events into coherent paragraphs, as in

``` transcript
Rhoda and Antony walk into the Post Office. Rhoda could have been rolling in chocolate and Antony looks as though dipped in french vanilla.
```

or

``` transcript
Antony opens the iron gate. He goes through.
```

### See Also

- [Doors, Staircases, and Bridges] for some technical details of allowing other characters to interact with doors when they're in rooms that don't contain the player.

## Obedient Characters

^^{actions: instructing other people}^^{characters (people): giving instructions to other characters}^^{instructing other characters} ^^{ordering other characters}
Other characters can perform all the same activities that the player can; this does not always mean that they're willing to obey the player's instructions. By default, characters will refuse to obey commands of the form ``JULIA, WEST`` or ``ANTONY, TAKE THE PINCUSHION``. Their objections can be overridden, however, and [The Hypnotist of Blois] implements a hypnotist who can make characters obedient at will.

In [For Demonstration Purposes], the character is only capable of a few actions at the outset, but can be taught new ones if the player performs them first.

Often we want characters' obedience to be more selective. Just as the viewpoint character may be characterised in terms of what they will and will not do, so may others: [Generation X] demonstrates a character who will do what they're told, but who will comment unfavorably when the player asks for a nonsensical or repeated action, and who may eventually get fed up and leave.

Characters can be given moral objections to certain commands, as well: [Virtue] defines a few kinds of actions as bad, so that the character commanded will refuse to perform them.

[Under Contract], more subtly, has the character object if the player's commands implicitly require any behaviour they consider inappropriate: for instance, if the player commands them to put their pants in a container, they will work out that this requires the removal of the pants as a preliminary. If we want to implement a similar character, we may want to simply copy the unsuccessful attempt rule and the table of retorts, then replace the banter with lines of our choosing.

The little example [Latin Lessons] allows us to make characters clever about vague commands: we can, for instance, write rules so that ``CLARK, EAT`` will have Clark sensibly pick something edible, rather than having the parser ask what we want Clark to eat.

Finally, [Northstar] demonstrates how we might make Inform understand commands of the form ``ASK JOSH TO TAKE INVENTORY`` or ``ORDER JOAN TO WEAR THE ARMOR``.

### See Also

- [Characters Following a Script] for a programmable robot who can be given whole sequences of actions to perform.

## Goal-Seeking Characters

^^{characters (people): goal-seeking}
Goal-seeking characters are the most advanced IF life-form: they want to achieve specific outcomes, and they are able to work out plans of approach in order to bring these things about. They walk to rooms, open containers to search for things, use keys and tools, and ask leading questions in conversation.

A really advanced implementation of goal-seeking behaviour is beyond the scope of our examples (though extensions exist that treat the problem more thoroughly). We can accomplish a surprising amount without heavy customisation, though, if we keep in mind three points of technique:

First: it helps to think abstractly and to create broadly-defined actions as a first step to more specific tasks. For instance, a character's goal might be to eat some dinner. They'd be equally satisfied with spaghetti carbonara or with braised lamb shanks, but they need to figure out which is available. So we might have our every turn rule (or whatever we're using to activate the character) say something like

	Every turn when Clark is hungry:
		try Clark dining.

Dining would then be an action we've defined specially, which looks around Clark's environment for suitable food; if it finds food, it issues a

	try Clark eating the suitable food;

command; but if not, it sends Clark off to look for something likely. [The Man of Steel] demonstrates the use of this.

Second: though it doesn't actually contribute to the goal-seeking per se, lively reporting brings characters' generated behaviour to life.

``` transcript
Clark eats a donut.
```

doesn't characterise Clark very much, even though the eating may be part of a subtle, intelligent plan to seduce Lois Lane. We'll do better if we replace a lot of the character reporting rules: to that end, see the example [The Man of Steel Excuses Himself].

Third: goal-seeking characters notice when something is in the way of the action they want to perform. When that happens, they form a plan about how to remove the obstacle. We've already seen this kind of implementation on the player's behalf: the player will pick up items before eating them, say. We can use Before rules to do similar things for other characters, as in

	Before Clark eating the wrapped candy:
		try Clark unwrapping the candy;
		if the candy is wrapped, stop the action.

Here we've set things up so that if Clark tries to eat the wrapped candy, he'll be interrupted by this other command; and if his unwrapping-the-candy attempt fails, he won't go on to eat the thing. [IQ Test] demonstrates a character who shows this kind of planning intelligence.

Because before-rules chain neatly, we can trigger whole plans of behaviour if we have a sensible set, as in

	Before someone entering a closed container: try the person asked opening the noun.
	Before someone opening a locked container: try the person asked unlocking the noun.
	Before someone unlocking a locked container: ...

We must exercise a little bit of care if it is possible for the chain of actions to produce an endless loop–e.g., the character trying to take a key that is inside the transparent, locked box that it opens might repeatedly try to open the box, first unlocking the box, first taking the key, first opening the box, ... [Boston Cream] is a fully-worked scenario that deals with such a set of conundra.

### See Also

- [Travelling Characters] for characters who plan routes to locations and travel towards them.
- [Event Scheduling] for characters who follow a pre-written schedule of activities.
- [Plot Management] for having a central function direct all the characters in order to further the plot.

## Social Groups

^^{characters (people): groups of people}^^{characters (people): reacting to each other}
Crowds of characters introduce new challenges, because we often want to show them interacting with one another, or to describe individuals in less detail when a whole group is present.

[Strictly Ballroom] gives us a set of characters who pair off each turn, making sure to mention each one once, and leaving one unfortunate person behind as a wallflower: this exemplifies how we might use a behavioural rule not to dictate the behaviour of each individual separately but rather to model a whole group together. [Happy Hour] does calculate movements for characters individually, but then collates the descriptions, creating a single paragraph to describe whatever group is currently in the room.

Characters can also have complicated attitudes to one another, and it can be helpful to use relations to track these. [Unthinkable Alliances] demonstrates the grouping of characters into alliance factions, while [The Abolition of Love] provides a host of relations to track love affairs, marriages, memberships in families, and mere mutual respect.

[Emma] combines these two effects: its characters move between social groups depending on how they feel about the others in their particular talking circle, and descriptions change depending on who is where in the room.

[Lugubrious Pete's Delicatessen] simulates a queue at a deli, in which the customers who most impress Pete get served first.

### See Also

- [Travelling Characters] for groups of characters who move around and have their movements collated into a joint description.

# Vehicles, Animals and Furniture

## Bicycles, Cars and Boats

^^{kinds: catalogue: vehicle} ^^{vehicles+kind+}
The vehicle kind in Inform refers to an object which can carry at least one person, but is small enough to fit into a single location:

	In the Garden is a vehicle called the motor mower.

We can then apply different rules to a player going somewhere on foot or in the vehicle. [Peugeot] (a bicycle) is an easy example; [No Relation] (a car) adds an ignition switch to the vehicle; [Straw Boater] (a motorboat) gets around areas of lake where travel on foot is not just slower but impossible.

[Hover] (a sci-fi "hover-bubble") changes the appearance of the landscape when it is seen from inside the vehicle.

### See Also

- [Ships, Trains and Elevators] for larger conveyances.

## Ships, Trains and Elevators

^^{vehicles+kind+: moving rooms}^^{rooms+kind+: moving rooms}^^{directions+kind+: shipboard directions, (FORE/AFT/PORT/STARBOARD)+commandpart+}
This section covers vehicles whose interior consists of at least one entire room. Moving into this room constitutes boarding: there is then some pause while it travels: moving out again disembarks at a different location. The only complication arising is how the player controls the journey (by talking to someone? by pressing buttons? by steering?).

[The Unbuttoned Elevator Affair] provides the simplest possible whole-room vehicle, which ferries between two fixed points. If you are at one of these, it must be the other one you want to get to, so there is no need for controls.

[Dubai] is a much more elaborate elevator, with many possible destinations, chosen using buttons inside the elevator.

[Empire] simulates a train journey. Here there are no controls as such, but the train passes through a sequence of stops spaced apart in time, so the player chooses an exit by getting out at the right moment.

On a very large, slowish craft such as a cruise liner, we are not so much travelling in a vehicle: it's more as if we are visiting a whole building, which becomes our world for the (probably long) duration of the journey. The liner steers around in long, slow curves, changing its orientation in the water, so that (if we think of "north" as a strictly magnetic matter, anyway) north is constantly rotating: something we don't notice on board because our own reference points, provided by the ship itself, stay fixed relative to ourselves. Because of this, some ships in IF are navigated using ``FORE``, ``AFT``, ``PORT`` and ``STARBOARD`` directions rather than ``NORTH``, ``EAST``, ``SOUTH`` and ``WEST``: see [Fore].

### See Also

- [Bicycles, Cars and Boats] for smaller conveyances.

## Animals

^^{animals+kind+}^^{animals+kind+: rideable}^^{Rideable Vehicles+ext+} ^^{extensions: specific extensions: Rideable Vehicles}
Animals exhibit a wide range of behaviour: much of the chapter on [Other Characters] applies just as well to animals as to human beings, with the exception of the material on conversation. But two examples here, both fairly simple, show how a fairly convincing domestic pet can be achieved simply by reacting to certain events going on nearby: [Feline Behaviour] (a cat) and [Today Tomorrow] (a dog).

[Fido] provides a dog which the player can re-name at will.

For animals that we can sit on and ride–a camel or a horse, say–we may want to use the Rideable Vehicles extension by Graham Nelson, which also provides a rideable animal kind.

### See Also

- [Liveliness] for pets that change what they're doing every time the player looks.
- [Bags, Bottles, Boxes and Safes] for a cat that eats food put in its container.

## Furniture

^^{containers+kind+}^^{supporters+kind+}
Most domestic furniture consists of supporters and containers of one size or another. This means that the simplest furniture needs no elaborate instructions:

	The candlestick is on the dining table. The dining table is fixed in place.
	
	The silver salt cellar is on the serving trolley. The serving trolley is pushable between rooms.
	
	The pillow is on the bed. The bed is enterable and fixed in place.

The examples below are therefore mostly ways to get around the usual restrictions on containers (that they only have one interior) and supporters (that they cannot simultaneously be containers as well).

[Yolk of Gold] provides a set of drawers, that is, a container with multiple interiors.

[U-Stor-It] provides a way to have containers with a lid which is also a supporter.

[Swigmore U.] provides a supporter which holds up the player, but has no top surface as such, and cannot hold up anything else. [Kiwi] demonstrates a kind of high shelf, whose objects cannot be seen or used unless the player stands on a ladder.

[Princess and the Pea] shows how a pile of supporters, each on top of the last, could be managed.

[Tamed] demonstrates furniture large enough to get inside, or on top of.

[Circle of Misery] demonstrates a conveyor belt, which can hold multiple items but only brings one of them within the player's reach at a time.

### See Also

- [Position Within Rooms] for a box that can be positioned and used as a stepping stool.
- [The Human Body] for letting the player take different postures on furniture or on the floor.
- [Room Descriptions] for tables and other furniture whose content listing is suppressed or modified in a room description.
- [Entering and Exiting, Sitting and Standing] for making the player automatically rise from a seat before leaving the room.
- [Clocks and Scientific Instruments] for a grandfather clock.
- [Kitchen and Bathroom] for a mirror the player can look into.

## Kitchen and Bathroom

Before implementing elaborate mechanisms to handle plumbing, we should pause to ask ourselves: how much of this do we need? Is it really necessary to simulate the complete set of fixtures and fittings?

This turns out to be a little tricky to do, and also rather dull to set out. The example [Modern Conveniences] was actually written as a demonstration of how an extension to Inform might be written to provide a general "kitchens and bathrooms service" for writers, but it contains a nice implementation well worth borrowing. The idea is to provide a "kitchen" kind of room and a "bathroom" kind of room. All kitchens created automatically contain standard kitchen appliances: fridge, freezer, sink with taps, counters, cabinets, and a stovetop with built-in oven. Similarly, all bathrooms will have sinks, baths, cabinets, and toilets, and respond to some standard interactions.

Another common feature of bathrooms is a mirror: [Versailles] demonstrates how to create a simple one.

# Props: Food, Clothing, Money, Toys, Books, Electronics

## Food

^^{food}^^{eating+action+}^^{edible / inedible (thing)+prop+} ^^{inedible / edible (thing)+prop+} ^^{edible (thing)+propcat+} ^^{inedible (thing)+propcat+}
Inform provides an either/or property called `edible` and an action, `eating`, for consuming edible things:

	The lardy cake is edible. After eating the lardy cake, say "Sticky but delicious."

For eating something not immediately to hand, see [Lollipop Guild]. [Delicious, Delicious Rocks], conversely, adds a sanity check which prevents the player from automatically taking inedible things only to be told they can't be eaten.

Inform does not normally simulate taste or digestion, but to provide foods with a range of flavours, see [Would you...?]; to make eating different foods affect the player differently, see [Stone], or for the extreme case of poisoning foods, [Candy]. In [MRE], hunger causes the player problems unless they regularly find and eat food.

### See Also

- [Liquids] for things to drink.
- [Dispensers and Supplies of Small Objects] for a pizza buffet table from which the player may take all the slices they want.

## Bags, Bottles, Boxes and Safes

^^{containers+kind+}^^{open / closed (container/door)+prop+} ^^{closed / open (container/door)+prop+} ^^{open (container/door)+propcat+} ^^{closed (container/door)+propcat+}^^{openable / unopenable (container)+prop+} ^^{unopenable / openable (container)+prop+} ^^{openable (container)+propcat+} ^^{unopenable (container)+propcat+}^^{locked / unlocked (container/door)+prop+} ^^{unlocked / locked (container/door)+prop+} ^^{locked (container/door)+propcat+} ^^{unlocked (container/door)+propcat+}^^{lockable (container/door)+prop+} ^^{lockable (container/door)+propcat+}^^{enterable (container)+prop+} ^^{enterable (container)+propcat+}^^{transparent / opaque (container)+prop+} ^^{opaque / transparent (container)+prop+} ^^{transparent (container)+propcat+} ^^{opaque (container)+propcat+}^^{Locksmith+ext+} ^^{extensions: specific extensions: Locksmith}^^{Skeleton Keys+ext+} ^^{extensions: specific extensions: Skeleton Keys}
The kind `container` allows one thing to contain others. Things are sometimes containers automatically, sometimes by instruction:

	The match is in the matchbox. The bucket is a container.

The matchbox, like the bucket, is a container. Containers come in all sizes and have a variety of behaviours, mainly controlled by the properties we give them: they can be `open` or `closed`, `opaque` or `transparent` (when closed), `openable` or not, `lockable` or not, `enterable` or not. The basic ideas of containment are to do with carrying and sometimes hiding the contents, and Inform makes this easy. Allowing for locking and unlocking is again straightforward:

	The strongbox is a locked container. The little steel key unlocks the strongbox.

For a container with a combination lock, rather than a key, see [Safety]; for a more sophisticated safe requiring digits dialed over multiple turns, see [Eyes, Fingers, Toes].

[Trachypachidae Maturin 1803] provides a bottle that is stoppered with a cork: when it is closed, the cork is part of the bottle, but otherwise the cork becomes a separate object we can carry around.

The normal assumption is that there is no problem with any two portable items being carried together, but in reality they may affect each other. (For effects like magnetism, or getting each other wet, or setting each other on fire, see the Physics chapter.) Here is a cat which, if boxed up with one or more items of food, will eat something each turn until all is gone:

	The player carries a wicker basket and a scarlet fish. The cat is an animal in the wicker basket. The fish is edible.
	
	Every turn when the cat is in a container (called the bag) and something edible (called the foodstuff) is in the bag:
		remove the foodstuff from play;
		say "With mingled sounds of mewing and chomping, the cat nibbles up [the foodstuff]."

The examples below provide subtler effects, adapting text to the current situation. In [Cinco], the container's name changes depending on what it contains: putting beef in a taco allows the player to call it a ``SHREDDED BEEF TACO``. In [Unpeeled] and [Shipping Trunk], the description of something inside a container changes according to other things are alongside it. This is taken further in [Hudsucker Industries], which describes the contents of a container as a group.

Finally, any action that destroys a container has to consider what to do with the things inside. [Fallout Enclosure] demonstrates a zapping action that destroys cash registers and shelves but leaves their contents tidily behind.

### See Also

- [Liquids] for a SHAKE command that makes containers rattle when there are contents.
- [Glass and Other Damage-Prone Substances] for opening containers by cutting into them.
- [Fire] for fire damage that spreads between containers and their contents, leaving fireproof objects intact.
- [Volume, Height, Weight] for containers breaking under the weight of their contents.
- [Heat] for keeping things warm in insulated containers.
- [Furniture] for chests with lids that can support other objects.
- [Modifying Existing Commands] for ways to allow the player to unlock with a key that isn't currently being carried.

## Clothing

^^{wearable (thing)+prop+} ^^{wearable (thing)+propcat+}^^{containers+kind+: pockets in clothing}
A person can wear any (portable) thing which has the `wearable` property. (This property seldom needs to be quoted because it is deduced automatically from sentences like `Trevor wears a red hat.`)

In most traditional IF, clothing is only used when it is exceptional in some way. That is, we ignore the three to eight different garments most people are wearing at any given time–the everyday clothes which people wear without thinking about them–and only simulate the unexpected extras: a borrowed jaunty red hat, a radiation-proof space suit, and so on.

These unusual garments turn up only occasionally in play and usually one at a time, so Inform does not normally provide rules to restrict how much or little is worn, or in what unlikely combinations. [Get Me to the Church on Time] categorises clothing by body area (trousers for lower body, shirts for upper); [Bogart] by layer, distinguishing underwear from outer garments. [What Not To Wear] combines both into a general-purpose system adequate for most kinds of clothing situations.

[Hays Code] is a somewhat stripped down version.

Clothes are normally single things which have no function other than display and concealment, but [Being Prepared] gives them pockets which act as containers, and [Some Assembly Required] allows clothes to be stitched together from pieces of cloth.

### See Also

- [Kitchen and Bathroom] for a simple mirror implementation, which could be adapted to reflect what the player is currently wearing.

## Money

^^{money (implementing)}^^{buying+action+}^^{characters (people): accepting gifts}
Money could be anything which the two people in a bargain both agree is valuable. Here, the player and an ogre agree on a copper coin as money:

	The player carries a copper coin. The ogre carries a rock cake. The cake is edible.
	
	Instead of giving the coin to the ogre:
		now the ogre carries the coin;
		now the player carries the cake;
		say "The ogre grunts and hands you a rock cake."

Now Inform does provide an action, `buying`, and a command for it, ``BUY``, but they ordinarily respond simply ``Nothing is on sale.`` This is no longer true, so we should make ``BUY CAKE`` work. The difficulty here is that a command like ``BUY CAKE`` does not specify what should be handed over in exchange. Here we just check that the player has the coin, but in principle we could check for any of a range of monetary tokens–coins, notes, cheque book, debit card, and so on.

	Instead of buying the cake:
		if the player has the coin, try giving the coin to the ogre;
		otherwise say "You have no money."

In more advanced economies, where shopping replaces barter, the seller will stock a wide range of differently priced goods. For a tabulated catalogue of wares, see [Introduction to Juggling]: to allow the player to negotiate prices, see [Money for Nothing]. In both of those examples, the player's current financial worth is simulated only as a current total amount of money carried–say, $2.50. This is typical, because in most situations what matters is how much money is in the pocket, not how it is made up. Money behaves more like a liquid than a set of items: hence terms like "liquidity", "cash flow" or [Frozen Assets]–the name of the simplest example demonstrating this. If we really need a comprehensive simulation down to pieces of currency–where it makes a difference carrying four quarters rather than a dollar bill, because the quarters can be fed into a vending machine–see [Nickel and Dimed].

[Fabrication] takes the problem in a different direction, making calculations about the cost of a new garment based on the price of the pattern, the quantity of fabric required, and the value of the fabric type chosen – showing off what we can do with unit multiplication in Inform.

[Widget Enterprises] explores the challenge of pricing widgets for maximum profit, given certain necessary costs and customers with varying willingness to pay.

### See Also

- [Actions on Multiple Objects] for an implementation of giving that allows the player to offer multiple objects at once, where their combined value determines whether they are accepted.

## Dice and Playing Cards

^^{randomness: dice and cards}^^{games, dice and cards (implementing)}
Most toys are single things, and no harder to create than any other small items, but games often require a multitude of tokens to be combined, and this can be logistically tricky.

The classic example is a pack of playing cards, where the player must individually control 52 items but without fussy commands or verbose text being printed back. [Jokers Wild] provides a simple "one card at a time" approach; [Tilt 1] is more sophisticated, with 52 independently accessible cards; [Tilt 2] can further judge the value of a selection of cards–the ranking of a poker hand.

Drawing cards from a shuffled pack is only one source of randomness. Games of chance also involve items drawn from a bag: [Wonka's Revenge] provides just such a lottery. More often, dice are thrown. A single die is easy enough:

	The die is carried by the player. After dropping the die: say "It lands with [a random number from 1 to 6] uppermost." Understand "roll [something]" as dropping.

Quick, but not very good. Most dice games involve rolling more than one die at a time, to get a more interesting distribution of outcomes: they may also involve special rules applying to doubles, for instance. See [Do Pass Go].

### See Also

- [Typography] for on-screen notations for chess and card games.

## Reading Matter

^^{books (implementing)}^^{books (implementing): with pages}^^{books (implementing): consulting}^^^{examining+action+ <-- reading}^^{examining+action+: handling (READ) separately+commandpart+}^^{Inanimate Listeners+ext+} ^^{extensions: specific extensions: Inanimate Listeners}
Many things can be read, from warning notices to encyclopaedias, and a range of techniques is needed to provide them because the quantity of text, and how it presents itself, can vary so much. With a small amount of very large type, the player should not need any command at all to read the text:

	The road sign is in the Junction. The road sign is fixed in place. "A road sign points north: 'Weston on the Green - 6'."

If the print is smaller, or the object portable, the player will expect to use the ``EXAMINE`` command:

	The business card is in the Junction. The description is "'Peter de Sèvres: consultant mnemonicist.'"

But if the object is a leaflet, say, ``EXAMINE`` should only describe the cover: ``READ`` would be the command a player would expect to use to get at the text itself. Inform normally defines ``READ`` to be the same command as ``EXAMINE``, which is good for things like the business card, but counter-productive here. [The Trouble with Printing] shows how to separate these two commands, allowing any thing to have a property called its `printing` for text produced by ``READ``, which will be different from its `description`, the text produced by ``EXAMINE``.

If the object is a lengthy diary, say, nobody would read it from cover to cover in a single IF turn. We might then want to allow the player to turn the pages one by one, with commands like ``READ PAGE 4 IN DIARY`` or ``READ THE NEXT PAGE``: see [Pages].

If the object is an encyclopaedic reference work, the player would consult named entries: see [Costa Rican Ornithology], which allows commands like ``LOOK UP QUETZAL IN GUIDE``.

Still larger sources of text often occur in IF: libraries or bookshelves, where many books are found together, and it is clumsy to write them as many individual items. One approach is to simulate an entire bookshelf with a single thing: see [Bibliophilia]. (This is much like looking up topics in a single book, except that each topic is a book in itself.) Another is to provide each book as an individual item, but have them automatically join together into a single portable collection: see [AARP-Gnosis].

Signs, leaflets and encyclopaedias, being printed, have a wording which will never change during play. But sometimes the player reads something which acts of its own accord. Text substitutions are usually all that is needed to achieve this:

	The computer display is on the desk. The description is "Giant green digits read: [the time of day]."

This is easy because we know all the variations we want. But what if we want the player to write their own text, for instance, adding to a diary? This is trickier, because it means storing text as the player typed it, and replaying it later. (And suppose the player types reams and reams of text, not just a few words as we might have hoped?) [The Fourth Body] and [The Fifth Body] show how to use an external file–a multimedia trick requiring features only available if the project is set to the Glulx story file format–to handle even the most difficult cases.

## Painting and Labelling Devices

^^{paint (implementing)}
Writing on something is only one way a player can change its visual appearance. IF authors have long been wary of paint brushes, because a sufficiently motivated player could go through a whole landscape like a graffiti artist with a railway bridge. We want to give the player the illusion of freedom of action, while avoiding a situation where unlimited numbers of different decorations might be needed–that would need a table of potentially unlimited size.

One approach is to limit the number of items which can be decorated. In [Palette], only the canvas can be painted, and each image overlays the last. [Early Childhood] increases the range to allow a whole kind (`block`) to be painted, and also shows how the changing colours can be used to distinguish between otherwise identical objects.

[Brown] finds a different way to limit the number of simultaneous decorations: almost anything can have a red sticky label attached, but there is only one red sticky label. (So to decorate a new item, the player must first un-decorate an old one.)

### See Also

- [Electricity and Magnetism] for another form of stickiness.

## Simple Machines

^^{kinds: catalogue: device} ^^{devices+kind+}^^{machines (implementing)}^^{assemblies}^^{components: of machines}^^{turning devices on / off}^^{switched on / off (device)+prop+} ^^{switched on (device)+propcat+} ^^{switched off (device)+propcat+}
The `device` kind provides for the simplest form of machine: one which is, at any given moment, switched on or switched off. Inform looks after this state, but leaves it to us to make the machine actually do something:

	The air-conditioning unit is a device in the Florist's Shop. The air-conditioning is fixed in place and switched on.
	
	Every turn when the location is the Florist's Shop:
		if the air-conditioning is switched off, say "You worry about the cut flowers in this jungle-hot air.";
		otherwise say "There is an low susurration from the air-conditioning unit."

One primary dictionary definition for a machine is "an apparatus using or applying mechanical power and having several parts", and we often use the `part of` relationship to build machinery. [Control Center] provides a neat way to display the component parts of a machine to the player who examines it.

One component almost always part of an electrical machine is the (literal) switch, lever or button to control whether it is switched on or off. In [Model Shop] just such an on/off button is automatically made part of every device.

While an electrical device has only two states, a mechanical machine might have many, and for these the best approach is to define a kind of value naming the possibilities: see [Signs and Portents], where the states are the possible destinations pointed towards.

Perhaps stretching the definition of "machine", [What Makes You Tick] demonstrates a fishing pole which the player can put together from several pieces.

### See Also

- [Bags, Bottles, Boxes and Safes] for a safe that can be dialed to different combinations.

## Televisions and Radios

^^{televisions (implementing)}^^{radios (implementing)}
IF authors often provide clues or background information to the player by means of radio broadcasts, TV shows or video tapes because they can talk to the player without needing to listen back, or to react to what the player does. The simplest radio set, like the one in [Aftershock], really only has one thing to say: which is serendipitously being broadcast just at the moment the player tunes in (regardless of when that is). The next simplest approach is to spool a broadcast on an endless loop taking several turns to play through, as in [Radio Daze].

Televisions come in all shapes and sizes, and [Aspect] allows their shape ("aspect ratio") to be described by the player.

In [Channel 1], we can also refer to the television by what it is currently showing: thus ``WATCH CHANNEL 4`` will work if the set is indeed tuned to 4. In [Channel 2], numbered channel changing is taken further: we can now ``TUNE TV TO CHANNEL 3``, as well. [Channel 2] is a reasonable base implementation of a television for many purposes.

## Telephones

^^{telephones (implementing)}
Telephones are much harder to achieve than televisions and in some ways as difficult to make convincing as a human character is–though of course there are corners which can be cut: we could have the reception drop off, or the other party hang up in a misunderstanding, and so on.

A single telephone line is tricky enough to provide that one might just as well have a general solution providing a whole network. [Four Cheeses] demonstrates a system where we can dial either people or numbers: ``CALL JANET ON TELEPHONE``, or ``CALL 7103``, for instance.

While [Four Cheeses] provides only four-digit phone numbers, like internal company extensions, [Alias] shows how to manage seven-digit numbers.

Finally, we might occasionally want the player to be able to address a microphone or telephone receiver directly when the identity of the person on the other end is unknown, in the form ``TELL MICROPHONE ABOUT CRIME``. Ordinarily Inform will disallow this because we're not allowed to talk to inanimate objects, but the extension Inanimate Listeners provides more options.

### See Also

- [Saying Complicated Things] for more approaches to conversation.

## Clocks and Scientific Instruments

^^{clocks (implementing)}^^{time: clocks (implementing)}
The simplest form of clock is a wrist watch. Here is a choice of analogue or digital:

	The player wears a wrist watch. The description of the wrist watch is "It is [the time of day in words]."
	
	The player wears a digital watch. The description of the digital watch is "It is [the time of day]."

Better clocks would allow us also to set the time, and to stop and start them: see [Tom's Midnight Garden].

Scientific instruments provide sharper versions of our own senses. In the case of vision, they allow us to see closer up, or further away. It's a convention of IF that people can normally see only the current location, that is, they cannot see from one location into another. The boundary of the current room is like a horizon, even out of doors (though it's true that there are ways to disguise that with a continuous outdoor landscape). [Ginger Beer] provides a telescope able to see into other rooms.

[Witnessed 2] provides a meter which measures how close a ghost is to the player.

### See Also

- [Continuous Spaces and The Outdoors] for more on seeing into adjacent locations.
- [Heat] for infrared goggles.

## Cameras and Recording Devices

^^{recording devices (implementing)}
Recording what is going on, for later playing back or examination, is difficult because the range of situations is very complex. Exactly how much information should we store when we make a recording, and will this require problematically large tables? Will it be difficult even to do at all?

The usual approach is to record only basic details of events or situations. In [If It Hadn't Been For...] the tape recorder preserves only a few different sounds–footsteps, creaking, rustling–rather than capturing exactly the sound of every action taking place in earshot. In [Claims Adjustment], we can take up to 36 Polaroid-style photographs, but each is described only by saying what it is a photo of. Thus we can have a photograph of a vase, or even a photograph of a photograph of a vase (because that too is a thing), but not a photograph of a still life in which several items have been gathered together by the player. That would ordinarily require too much storage.

A similar trick, though involving impromptu sculpture rather than photography, can be found in [Originals]. (The artist magically "manifests" these models rather than sculpting the conventional way in order to avoid the nuisance of carrying around raw materials–wax maquettes and so forth–which would clutter up the example.)

Text, of course, can store arbitrary descriptions. [Mirror, Mirror] provides a perfect visual recorder: it remembers a room description exactly as the player saw it at the time.

[Actor's Studio] provides a video camera that records and time stamps all actions performed in its presence while it is set to record.

### See Also

- [Telephones] for ways to speak to inanimate objects, which might be appropriate when, say, tape-recording a confession.

# Physics: Substances, Ropes, Energy and Weight

## Gases

^^{gases (implementing)}^^{smoke (implementing)}
Inform normally assumes that everything is solid. It has no built-in support for gases or liquids, because they have so many different behaviours. For instance, is the important thing about gas that it diffuses, or that we breathe it, or that it mixes with other gases to react, or that it sometimes obscures vision? The answer depends on what we are trying to write, and for this reason Inform leaves it up to us.

Gases are easier to deal with than liquids, because they tend to be everywhere in their location at once (unlike a liquid which might form a pool on the floor) and because they diffuse and mix by themselves (rather than being carried around or brought into contact with each other by the player). On the other hand, unlike liquids, gases are compressible: they can be present at low or high pressures, that is, in low or high concentrations.

The simplest approach is the one in [Only You...], where rooms are either filled with smoke or else smoke-free. Smoke gradually fills through the map, obscuring vision: no attempt is made to conserve the total quantity of smoke, as we assume that some fire is churning it out continuously to replace what diffuses away.

[Lethal Concentration 1] and [Lethal Concentration 2] simulate a gas diffusing through a three-dimensional maze of rooms, and becoming dangerous above certain concentrations. There is just one possible gas, and it is modelled by giving each room a number which represents the concentration (in parts per million). This enables us to conserve the total amount of gas, or to have it released or captured by sources and sinks of given capacity.

This could be extended by giving each room similar concentration levels for other gases, and providing for the diffusion rule to notice when different gases come into contact; or by giving a concentration (and also, for realism, a volume) to each closed container, applying rules for capturing and releasing gases as containers are opened and closed.

## Liquids

^^{liquids (implementing) <-- water <-- fluids}^^{containers+kind+: liquids in containers}^^{drinking+action+}
Liquids are notoriously difficult to simulate well. A fully thorough approach consumes endless storage and can be very finicky to write and keep realistic. It is essential to decide what aspect of a liquid's behaviour is actually needed in a given story, and to simulate only that. For instance, if we only need a little chemistry, where a player can add (say) water to salt and make a solution, we do not want to fool around with calculating quantities or concentrations: what's important is that `some water` (amount unspecified) combines with `some salt` to produce `some salty water`. We should no more calculate precisely here than we would work out where all the furniture is to the nearest inch. Good advice for handling liquids is to simulate the least amount of realism possible, but no less.

Sometimes all we want is a down-in-one drink: we needn't simulate the actual liquid, just the bottle it comes in, and all we need is to handle the `drinking` action. See [Beverage Service], and also [3 AM], where carbonated drinks can be shaken–again simulating the vessel, not the liquid.

Some elementary biochemistry in [Xylan] is done simply by... well, the point is that two different liquids are represented by single things each, and a chemical reaction simply switches one for the other.

In [Frizz], we allow any container to be filled with water (only) and we simulate what happens to any solid objects also inside: some waterproof, some not. [Flotation] provides a well (always full of water), with rules to determine whether things dropped into it should sink or float.

Next we move up to quantitative approaches, where we remember not just whether a liquid is present, but how much of it. In its simplest form, we could have a drinking vessel from which we draw in sips, so that it can be full, half-empty or empty: see [Thirst].

The example with the best compromise between simulation quality and complexity is [Lemonade]. Here we provide a kind of container called a `fluid container`, not just a single cup, and each such vessel has a given `fluid capacity`. Each holds only a single liquid at a time (so no mixtures) and can be empty or full to any level (rounded off to the nearest 0.1 fl oz). We can fill one vessel from another (unless it would make a mixture). But liquids leaving these vessels must be consumed–drunk or poured away without trace: we cannot make pools on the floor, or carry liquids in our cupped hands. There is no object representing "lemonade": there are only fluid containers, but which can be called ``LEMONADE`` if that is what they now contain.

[Savannah] is a light elaboration of Lemonade, showing how liquids might be poured on other objects, as for instance to extinguish a fire.

[Noisy Cricket] extends [Lemonade] to allow for mixing, though then the number of different possible mixtures is so large that complexity increases greatly. [Lakeside Living] extends [Lemonade] differently to add a `liquid source` kind, a form of fluid container which has infinite fluid capacity and is scenery–ideal for a lake, river or spring.

### See Also

- [Bags, Bottles, Boxes and Safes] for stoppered bottles which could also be used for carrying liquids around in.
- [Heat] for keeping liquids warm in insulated containers.

## Dispensers and Supplies of Small Objects

^^{duplicates: taken from a dispenser}
A slightly tricky situation arises in IF when we want to offer the player a simulation of a near-infinite supply of something: a napkin dispenser from which they can keep taking more napkins, or an infinite selection of pebbles on a beach, or something of that nature.

One approach is simply to limit the number of items the player is allowed to pick up at a time, while maintaining the fiction that there are more of these items in existence than the player is allowed to interact with. [Extra Supplies] demonstrates this.

The task becomes harder if we do want to let the player have as many napkins as they want. In some languages, it is possible to generate new objects on the fly after the story has begun (called "dynamic object creation"), and something like this is possible if we are compiling for Glulx. (See the Inform extensions site for examples.) Usually, though, it is less complicated and almost as effective simply to have a very large supply of existing objects, which are moved in and out of play as the player needs them. [Pizza Prince] demonstrates how to do this with slices of pizza.

### See Also

- [Ropes] for an example involving divisible pieces of string, which relies on similar techniques.

## Glass and Other Damage-Prone Substances

^^{breakable things (implementing)}^^{fragile things (implementing)}^^{damaging things (implementing)}^^{components: breaking apart}
Just as Inform normally assumes everything is solid, it also assumes that these solid objects will not buckle, crack, break or deform under pressure, and cannot be fragmented. But breakability adds realism, and breakage need not be negative: sometimes we want the player to break her way in to something.

In IF the word ``DROP`` is more often used to mean "put down" or "leave behind" than "let go from a height": so it is perhaps unfair that in [Ming Vase] something fragile, when dropped, shatters (into nothing). In [Spring Cleaning], fragile objects must be explicitly attacked by the player in order to break, and although they leave no tangible debris behind, their loss is at least remembered. [Kyoto] provides a general-purpose model for things being thrown at other things, with consequences including things moving (even between rooms) as well as breaking each other.

Debris from breakages is to be avoided if possible because it means keeping track of increasing numbers of objects. But we can increase realism by allowing something to have a visibly `broken` state, which it changes to when it breaks, rather than simply vanishing. [Terracottissima] provides for `broken` and `unbroken` flowerpots in this way.

Since `part of` allows us to have two objects joined together into what the player sees as one, it also gives us a natural seam which allows the whole to be broken back down into its component parts, and this is the neatest way of providing a breakage into pieces. [Paddington] demonstrates a cutting action which allows component parts to be cut away from their holders but will only make small surface gashes in any individual thing: so the player can cut something up, but only into the pieces we specifically choose to allow. Cutting also forces an opening into containers.

### See Also

- [Combat and Death] for a robot that breaks into its component limbs when shot with a blaster.
- [Goal-Seeking Characters] for a character who eats donuts, leaving crumbs on the floor.
- [Volume, Height, Weight] for containers breaking under the weight of their contents.
- [Ropes] for cutting up string into up to 35 different pieces of different lengths - a limit the player is unlikely to find out about, but a limit all the same, and an expensive solution since we need 35 different things for the "debris" when string is `broken`.

## Volume, Height, Weight

^^{containers+kind+: carrying capacity}^^{carrying capacity of (container/supporter/person)+prop+} ^^{carrying capacity of (container/supporter/person)+propcat+}^^{units of measure: for capacity of containers}
What should fit into what? Inform has basically three sizes: small, person-sized, and room-sized. The difference between "small" and "person-sized" doesn't appear much, but it's the difference between an ordinary container and an enterable container; the fact that a person cannot get inside an ordinary container is one of the few size-related rules built into Inform. It will not object to, say, a fishing rod being put inside a matchbox.

Inform does have one built-in measure of the size of a container: its `carrying capacity`. This is a maximum number of contents:

	The carrying capacity of the rucksack is 3.

This of course allows three anvils, while forbidding four postage stamps. To do better, we need units of measurement, and [Dimensions] demonstrates setting these up. [The Speed of Thought], meanwhile, ventures into the area of unit conversion: having multiple types of unit and being able to express them to the player, or parse these in the player's input.

To be fully realistic in what will fit into what, we need sophisticated three-dimensional models of shapes, both of the items being carried and of the free space remaining inside containers. [Depth] elegantly simplifies this by approximating items as cuboids, with a given width, length and height: these multiply to give a volume. To fit in a container, a new item's volume must not exceed the volume remaining inside the container, and in addition its three dimensions must also fit in one of the possible arrangements at right angles to the sides. (So this system would indeed prevent a 1x1x100 fishing rod from being put inside a 5x2x1 matchbox, but would also prevent a 12x1x1 pencil from being put into a 10x10x1 box, because it would need to be turned diagonally to fit.)

[Lead Cuts Paper] provides a different constraint: here we do not let light-weight containers hold heavy objects.

Weight comes in a different way into [Swerve left? Swerve right? Or think about it and die?], which exploits up/down map connections to work out which way gravity would take a rolling marble.

### See Also

- [Liquids] for containers with liquid capacity.

## Ropes

^^{ropes (implementing) <-- string}
Ropes, chains and similar long, thin, bendable items present three problems: they are like a liquid in that (unless unbreakable) they can be divided arbitrarily into smaller and smaller portions of themselves, they can be in two or more places at once (even in two or more rooms at once), and they can be tied down at either or both ends, allowing them to occupy an uneasy state in between being `portable` and `fixed in place`. Even when all this is simulated, they allow us to pull on one end and so to exert force at the other–allowing action-at-a-distance which Inform's realism rules would ordinarily forbid. Ropes are hard. And it is very difficult to imagine everything a player might try when given a fully practical rope with which to solve puzzles.

[Snip] solves the divisibility question, allowing string to be cut or retied into lengths of any size, with all the consequences for describing and understanding that this entails.

[Otranto] provides a lengthy but straightforward approach to the other rope-related issues, subject to the simplifying assumptions that a rope is indivisible, has about the length of the distance between two adjacent rooms, and cannot be tied to another rope.

## Electricity and Magnetism

^^{kinds: catalogue: device} ^^{devices+kind+}^^{machines (implementing)}^^{electricity (implementing)}^^{magnets (implementing)}^^{turning devices on / off}^^{switched on / off (device)+prop+} ^^{switched on (device)+propcat+} ^^{switched off (device)+propcat+}
Electrons are so tiny, and move so fast, that we will never want to simulate them in ordinary IF. So we simply regard electricity and magnetism as behaviours which are either present or not present, and which have instantaneous effects.

In [Witnessed 1], batteries provide electricity to enable a `device` to work. Even if switched on, a device with no battery will be ineffective.

Larger voltages are exposed in [Electrified], which makes certain items untouchable, and ensures that an experienced electrician will not even try.

[Rules of Attraction] provides for a magnet which attracts metallic items just strongly enough to stick together until pulled apart for any reason.

## Fire

^^{fire (implementing)}^^{burning+action+}^^{heat: on fire}
Fire exhibits some of the properties of a gas: it is only vaguely located and tends to spread out, though it passes by touch rather than on the air. It is hazardous to life, through direct contact, heat, and smoke. Better governed, it provides light and warmth. Worse governed, it consumes almost anything it comes into contact with. Here the problem with "debris" is not so much that we need potentially hundreds of new objects to represent broken items: instead, fire could sweep through a work of IF destroying so much that no play is possible any longer. Setting up a problem in which the player must defeat a fully-capable fire is difficult to balance.

As with liquids, it is best to simulate the least amount of fire that the design will allow. [Bruneseau's Journey] provides a single candle which can be lit, or blown out, but where fire can never transfer from the candle's end to anything else–or vice versa: the player's source of fire, with which to light the candle, is discreetly neglected.

In the more realistic [Thirst 2], a campfire is lit using a tinderbox, so that fire does transfer from one thing (tinder) to another (the campfire): but it is always confined to just these two items, and can be used only for light and warmth.

[The Cow Exonerated] provides a class of matches that can light any flammable object, but assumes that burning objects requires only one turn; lighting one thing does not burn another.

[In Fire or in Flood] provides a complete simulation of what we might call "wild-fire": combustion which spreads through arbitrary objects and rooms, destroying all in its path.

### See Also

- [Examining] for a way to describe objects as charred once they have been partly burnt.
- [Heat] for one consequence of fire having touched something.
- [Gases] for an implementation of smoke without fire, if this can exist.
- [Liquids] for water being used to extinguish a simple fire.
- [Lighting] for other uses of candles and torches as light sources.

## Heat

^^{heat: too hot to touch}
Since we prefer not to simulate burnt skin, and it is unsporting to kill a player outright merely for touching a hot object, heat is mostly used as a reason why something cannot be picked up at a given moment. This very basic puzzle is demonstrated in [Grilling].

With the naked eye, it is not always easy to detect what is too hot to touch–a point made in both [Masochism Deli], where the only solution is to keep picking up potatoes until one doesn't burn, and in [Hot Glass Looks Like Cold Glass], where infrared goggles turn the scales.

If a hot object is not to be touched, will it stay hot forever? It might well, if it is a steak on an electric grill, but not if it is a recently-baked apple pie sitting on a window-sill. [Entropy] simulates the gradual return of temperature to equilibrium.

### See Also

- [Electricity and Magnetism] for items which shouldn't be touched because they are hot in a different way.

## Magic (Breaking the Laws of Physics)

^^{ACTIONS+testcmd+} ^^{testing commands: >ACTIONS}
Every previous section of this chapter has been about adding further realism constraints to Inform, to give it a more advanced understanding of physics (and chemistry). But Inform has plenty of physical laws built into it already, even if they are more mundane: inanimate objects do not spontaneously move or change, one solid object cannot pass through another, there are opaque barriers through which light cannot pass, and so on. These rules stop many attempted actions. (``GO EAST``–``The oak door is closed.`` ``GET EMERALD``–``You can't, since the glass display case is in the way.``)

In the real world, physics is not negotiable. ("Gravity: it's not just a good idea, it's the law.") But in stories, magic can sometimes happen, and in these examples some of the rules built into Inform are waived in special circumstances, which in effect cancel certain physical laws. Very many other magical tricks could be achieved: if you want to make a given command work despite realism constraints, try typing ``ACTIONS``–a testing command which reveals what is happening behind the scenes–and then typing the command you want. This should reveal which named rule is stopping it: you can then try suspending that rule, and seeing if the effect now works.

### See Also

- [Magic Words] for ways to create new single-word spell commands.

## Mathematics

^^{calculation}
It is uncommon, but not absolutely unheard-of, to need to do detailed mathematical calculations in interactive fiction.

[The Fibonacci Sequence] demonstrates the calculation of a series of numbers; [Sieve of Eratosthenes] shows off how to calculate the prime numbers within a certain range.

[Number Study] demonstrates conditional relations between numbers.

[Olympic Medals] shows a non-standard way to sort a table of data numerically.

# Out Of World Actions and Effects

## Start-Up Features

^^{banner text}^^{when play begins+rb+}^^{rules: run at beginning of story}^^{initial state of the world: setting in (when play begins)+sourcepart+}^^{starting conditions: setting in (when play begins)+sourcepart+}^^{story structure: beginning}^^{files (data files): loading initial state from a data file}^^{randomness: randomising the initial state of the world}
When the story file starts up, it often prints a short introductory passage of text (the "overture") and then a heading describing itself, together with some version numbering (the "banner"). But it's possible to have a multi-turn prologue before the banner finally appears, and marks the start of play in earnest. [Bikini Atoll] demonstrates how to do this.

At one time, the Inform licence required all Inform-written stories to display the banner sooner or later. That requirement disappeared when Inform adopted the Artistic License 2.0 as its terms of use. So authors are now free to abolish the banner entirely. All the same, it remains a culturally useful convention, in the same way that almost all television dramas past and present contain some form of opening titles, even if just a title card, and even if delayed until after a cold open.

If a story file represents the latest in a sequence of story files representing chapters in some larger narrative, it will need some way to pick up where its predecessor left off. This can be done with the aid of external files (in the Glulx format, at least). [Alien Invasion Part 23] shows how.

Another task we might want to perform a the beginning of play is to arrange any randomised features that are supposed to change from one playing to the next. We can add such instructions with `When play begins` rule, as in:

	When play begins:
		now the priceless treasure is in a random room.

Since we may want to do something a bit more complicated than this, [Hatless] demonstrates effective and ineffective methods of distributing multiple objects (in this case, one randomly-selected hat per person).

### See Also

- [Map] for a way to generate a randomised maze at the start of play.
- [Food] for a way to choose a random piece of candy to be poisonous.
- [Getting Acquainted] for a way to choose a murderer from among the characters at the start of each story.

## Saving and Undoing

^^{use options: catalogue: |undo prevention} ^^{undo prevention+useopt+}^^{>UNDO}
A very few titles in the IF literature–very few being still too many, some would say–restrict the player's ability to save the story.

Removing the player's ability to ``UNDO`` is also a risky choice. Inform does provide the facility with the use option

	Use undo prevention.

which makes it impossible to ``UNDO`` at any time (unless, that is, the player is playing on an interpreter that itself has a built-in ``UNDO`` feature – these do exist). When it works, undo prevention safeguards a randomised story or combat session against brute-force solutions, but it also means that the player who makes even a minor mistake of typing will be stuck with the undesired results.

In many cases it may be preferable to use some subtler method to enforce random effects in a story. Several extensions exist for Inform that either allow selective manipulation of the ``UNDO`` command or rig randomisation to prevent ``UNDO`` and replay attempts.

## Helping and Hinting

^^{help systems}^^{hint systems}
IF is difficult to play: often harder than the writer ever suspects. Players are held up by what is "obvious", and they stumble into unforeseen combinations, or spend inordinate amounts of time working on the "wrong" problems. Too much of this and they give up, or post questions on online forums. Against this, many IF authors like to include in-story hints.

There are many approaches, which differ on two main issues.

First: do we spontaneously offer help to the player? The difficulty here is detecting the player's need: [Y ask Y?] tries to spot aimlessness, while [Solitude] has a novice mode where it is reasonable to assume that help is almost always needed. On the other hand, suppose we require that the initiative come from the player. Will a novice know to type ``HELP``? [Query] shows how to redirect any attempt to ask a direct question into a ``HELP`` request. At the other end of the scale, wearily experienced players may type ``HELP`` all the time, out of habit, cheating themselves of the fun of frustration: if so, [Real Adventurers Need No Help] provides the nicotine patch against this addiction.

Second: how do we decide what help is needed? Normally the player only types ``HELP``, which is unspecific. The simplest approach offers a menu, diagnosing the player's problem by obliging them to make choices: see [Food Network Interactive]. Listing all the possible problems in the story may give away too much, though, since players may not have reached the puzzles in question yet; so some authors prefer to create menus that adapt to the current state of the story (commonly called "adaptive hints").

Failing this, we can also try to parse commands like ``HELP ABOUT MICRODOT``, as in [Ish.] [Trieste] takes a similar tack, except that instead of offering hints about puzzles, it offers help on story features (such as how to save), and lists all the available topics if the player types simply ``HELP``.

Finally, and perhaps most stylishly, we can try to deduce what the player is stuck on from their immediate circumstances and from what is not yet solved: this needs a powerful adaptive hints system like the one in [The Unexamined Life].

### See Also

- [Getting Started with Conversation] for a way to redirect a player using the wrong conversation commands.
- [Footnotes] for another medium by which hints could perhaps be transmitted.

## Scoring

^^{use options: catalogue: |scoring} ^^{scoring+useopt+}^^{scoring}^^{scoring: reporting during story}^^{score (- number)+glob+}^^{maximum score (- number)+glob+}^^{>NOTIFY ON/OFF}^^{time: counting actions with (for the Nth time)+sourcepart+}^^{counting: actions with (for the Nth time)+sourcepart+}
Not every work of IF allots a numerical score to the player: for some authors, this emphasises the idea of a story rather than a narrative. The simple sentence

	Use scoring.

introduces the concept. Once this is included, Inform will provide built-in support for a single number measuring progress (`score`), and will expect to measure this against a maximum possible (`maximum score`, which can either be set by hand or worked out automatically from a table of ranks).

In a story in which scoring exists, the player may choose to turn score notifications (such as `"[Your score has just gone up by one point.]"`) on or off. The commands to do this are ``NOTIFY ON`` and ``NOTIFY OFF``; the actions are called switching score notification on and switching score notification off. In the event that we need to amend the behaviour of notification, we could do so by adding, removing, or modifying the elements of the check and carry out rulebooks for these commands; as in

	Check switching score notification off:
		if the turn count is less than 10:
			say "You are still a novice, grasshopper. Allow your teacher to give you advice until such time as you are ready to go on alone."

If we wish to change the wording of the default message (``[Your score has...``), we may want to use the Responses system.

An especially insidious style of bug allows the player to type the same sequence of commands over and over, earning score endlessly for the same insight, and to avoid this it is usually safest to write source like:

	After taking the Picasso miniature when the Picasso miniature is not handled:
		increase the score by 10;
		say "As they say in Montmartre: dude!"

We might also write our condition with `for the first time`, like so:

	After jumping for the first time:
		increase the score by 5;
		say "Boing! That was certainly entertaining."

But we should be careful not to use `for the first time` in scoring situations where it's possible for the player to try the action but fail. Inform counts even unsuccessful attempts towards the number of times an action is understood to have occurred, so if the player tries to jump and fails, their `for the first time` will be used up and they will never receive the score points.

If there are many "treasure" items like the Picasso miniature, it is best to be systematic, as in [No Place Like Home]. [Bosch] takes another approach to the same idea, by creating a table of point-earning actions that the player will be rewarded for doing; the ``FULL SCORE`` command will then play these back.

[Mutt's Adventure] demonstrates how we might add a scored room feature, such that the player earns a point when they first arrive at a special room.

A single number does not really sum up a life, or even an afternoon, and [Goat-Cheese and Sage Chicken] and [Panache] offer more detailed citations. Works that are more story than story may prefer to offer a plot summary of the player's experience to date in lieu of more conventional scoring.

Finally, [Rubies] provides a scoreboard that keeps track of the ten highest-scoring players from one playthrough to the next.

## Settings and Status Checks During Play

^^{>NOTIFY ON/OFF}^^{>VERIFY}^^{>VERSION}^^{>PRONOUNS}^^{>TRANSCRIPT ON/OFF}^^{scoring: reporting during story}^^{banner text}^^{bibliographic data}^^{IFID+biblio+}^^{extensions: listing credits for}^^{pronouns: displaying with (PRONOUNS)+commandpart+}^^{VERBOSE room descriptions+useopt+}^^{BRIEF room descriptions+useopt+}^^{SUPERBRIEF room descriptions+useopt+}
Several default actions allow the player some control over the presentation of the story, or permit the player to request information about what is going on. In addition to the standard commands described elsewhere in this section (``SCORE``, ``SAVE``, ``UNDO``, ``QUIT``, ``RESTART``, and ``RESTORE``), Inform has the following actions that control the player's experience:

- Preferring abbreviated room descriptions (``SUPERBRIEF``)
- Preferring unabbreviated room descriptions (``VERBOSE``)
- Preferring sometimes abbreviated room descriptions (``BRIEF``)
- Switching score notification on (``NOTIFY ON``)
- Switching score notification off (``NOTIFY OFF``)

The first three of these allow the player to change the way rooms are described on first and subsequent versions; the last two, when used in a story that provides a score feature, toggle on and off reports such as `"[Your score has just gone up by three points.]"` These are discussed elsewhere in the Recipe Book (see cross-references below).

These provide immediate feedback about the status of the story file being played:

- Verifying the story file (``VERIFY``)
- Requesting the story file version (``VERSION``)
- Requesting the pronoun meanings (``PRONOUNS``)

``VERIFY`` examines checksums to make sure that the story file being run is intact and correct. This is less often an issue now than it was in the days when story files were distributed by highly corruptible floppy disk, but the command persists and is very occasionally useful. ``VERSION`` gives the full banner text associated with the story, including title, author, release number, IFID, and other bibliographical data; it follows this with a list of the included extensions.

``PRONOUNS`` announces to the player what the story is currently understanding as the antecedents of ``HIM``, ``HER``, ``IT``, and ``THEM``. This is often useful during testing, but sometimes also during play.

The following allow the player (when supported by the interpreter in use) to create a log of play:

- Switching the story transcript on (``TRANSCRIPT ON``)
- Switching the story transcript off (``TRANSCRIPT OFF``)

It is rarely a good idea to change the default performance of such commands: they are often finicky and closely tied to the interpreter in which the story runs. Moreover, disabling the ``VERSION`` command means that the story file is not able to display attribution information for Inform and any included extensions, in violation of their respective licenses.

### See Also

- [Looking] for a way to set the story's verbosity level for the player.
- [Scoring] for a discussion of score notification.
- [Testing] for some examples of status-check commands created for alpha- or beta-testing of a story.

## Ending The Story

^^{when play ends+rb+}^^{rules: run at end of story}^^{end of story} ^^{victory} ^^{death} ^^{winning the story} ^^{losing the story}^^{(finally), ending the story+sourcepart+}^^{>AMUSING}^^{story structure: ending}^^{+to+end the story}^^{+to+end the story finally}^^{+to+end the story saying (text)}^^{+to+end the story finally saying (text)}^^{files (data files): storing records of death in a data file}^^{scoring: reporting at end of story}^^{|Table of Final Question Options} ^^{|Final Question Options: Table of Final Question Options}^^{>RESTART}^^{>RESTORE}^^{>QUIT}^^{>UNDO}
Play can end in many ways, at the writer's discretion:

	end the story;
	end the story finally;
	end the story saying "You have reached an impasse, a stalemate";
	end the story finally saying "You have succeeded.";

The phrase `end the story` by itself will finish play, printing ``*** The End ***``. Using one of the phrases with `saying...` allows us to specify some other text with which to conclude. Including `finally` means that the player has earned access to ``AMUSING`` text and other notes, if any of these are provided.

We can eliminate the asterisked headline entirely by removing the rule that prints it, thus:

	The print obituary headline rule is not listed in any rulebook.

The next step is to print the player's score and, if applicable, the rank they achieved. By default a story doesn't feature scoring, but the following use option will incorporate it:

	Use scoring.

Then, if we want to allow a score but alter the way it is reported, we may remove or modify the print final score rule, as in

	The print final score rule is not listed in any rulebook.

or perhaps something like

	The chatty final score rule is listed instead of the print final score rule in for printing the player's obituary.
	
	This is the chatty final score rule: say "Wow, you achieved a whole [score in words] point[s] out of a possible [maximum score in words]! I'm very proud of you. This was a triumph. I'm being so sincere right now."

What happens next is normally that the player is invited to ``RESTART``, ``RESTORE`` (from a saved story), ``QUIT`` or ``UNDO`` the last command. The presence of the question can somewhat undercut a tragedy, and [Battle of Ridgefield] shows another way to go out.

If we do leave the question in, the text is formed by the Table of Final Question Options, which by default looks like this:

	Table of Final Question Options
	final question wording	only if victorious	topic		final response rule		final response activity
	"RESTART"				false				"restart"	immediately restart the VM rule	--
	"RESTORE a saved story"	false				"restore"	immediately restore saved story rule	--
	"see some suggestions for AMUSING things to do"	true	"amusing"	--	amusing a victorious player
	"QUIT"					false				"quit"		immediately quit rule	--
	"UNDO the last command"						false				"undo"		immediately undo rule	--

Because this is a table, we may alter the behaviour by changing entries or continuing the table. [Finality] shows how we might take out the option to ``UNDO`` the last command, for instance.

Using an ending phrase that includes `finally` tells Inform to include the options that are marked `only if victorious`. One common use is to let the player read some special bit of additional text, perhaps describing easter eggs they might have missed in the story or presenting some authorial notes. [Xerxes] demonstrates a simple ``AMUSING`` command to read final information, while [Jamaica 1688] shows how to add completely new elements to the list of options.

Old-school adventures expected their adventurers to die early and die often. [Labyrinth of Ghosts] shows how the residue of such past attempts can be preserved into subsequent attempts, using an external file. [Big Sky Country] shows how a player can be resurrected by, let us say, some beneficent god, so that a player can even die more than once in the same attempt.

# Typography, Layout, and Multimedia Effects

## Typography

^^{proportional-spaced text}^^{monospaced text}^^{fonts: fixed-width / variable-width}^^{fonts: italic / bold / roman}^^{characters (letters): Unicode (arbitrary symbols)}^^{+to+say "[bold type]"} ^^{+tosay+"[bold type]"}^^{+to+say "[italic type]"} ^^{+tosay+"[italic type]"}^^{+to+say "[roman type]"} ^^{+tosay+"[roman type]"}^^{+to+say "[fixed letter spacing]"} ^^{+tosay+"[fixed letter spacing]"}^^{+to+say "[variable letter spacing]"} ^^{+tosay+"[variable letter spacing]"}
Story files produced by Inform tend not to contain elaborate typographical effects. They would only distract. Like a novel, a classic work of IF is best presented in an elegant but unobtrusive font. Inform does, however, provide for italic and bold-face, and also for a typewriter-style fixed pitch of lettering:

	"This is an [italic type]italicised[roman type] word."
	"This is an [bold type]emboldened[roman type] word."
	"This is a [fixed letter spacing]typewritten[variable letter spacing] word."

Authors making very frequent use of these might like to borrow the briefer definitions in [Chanel Version 1].

A very wide range of letter-forms is normally available (and even more in quoted text), so that the writer seldom needs to not worry whether, say, a sentence like

	A ticket to Tromsø via Østfold is in the Íslendingabók.

will work. [The Über-complète clavier] is an exhaustive test of such exotica.

Coloured type is trickier, and its availability depends on the story file format. For a Z-machine story, [Garibaldi 2] demonstrates this.

Finally, [Tilt 3] combines unusual letterforms (suit symbols) with red and black colours to render hands of cards typographically.

## The Status Line

^^{status line}^^{screen top}^^{left hand status line (- text)+glob+}^^{right hand status line (- text)+glob+}
The status line is the reverse-coloured bar along the top of the window during play, which conventionally, but not necessarily, shows the current location, the score (or sometimes the time of day) and the number of turns so far. It has been highly traditional since the early 1980s (^{Infocom}'s customer newsletter was for many years called _The Status Line_): it has become the visual identifier of IF. It plays the same role for IF that a header with chapter name and page number plays in a printed book.

The status line is ordinarily printed from two named pieces of text, the `left hand status line` and the `right hand status line`. These can be changed during play, so for instance,

	When play begins:
		now the right hand status line is "Time: [time of day]".

The examples below offer miscellaneous alternatives, and are fairly self-descriptive.

### See Also

- [Viewpoint] for a way to make the status line list the player's current identity.

## Footnotes

^^{footnotes (implementing)}
[Ibid.] provides a version of the traditional ^{Infocom}-style approach to footnotes, which number off in the order encountered.

## Timed Input

^^{time: timed input}^^{Real Time Delays+ext+} ^^{extensions: specific extensions: Real Time Delays}
Inform normally expects a purely turn-based story: the player acts, the story responds and waits for the player to act again.

Occasionally, however, we may want to offer a different mode of interaction, for instance with turns in which the player has limited time to come up with the next action. Likewise, we might want to have text that printed itself to the screen gradually, to represent dialogue with pauses, or the speed of a typewriter placing letters on a page.

It's best to be careful with these effects: overdone, they can be very annoying to players who prefer to read at a faster speed. Nonetheless, they do have their uses.

^^{@Erik Temple}

Inform does not have standard syntax to handle real-time delays and output, but there are several extensions that provide this capacity. Erik Temple's extension Real Time Delays, for instance, allows us to specify a delay in milliseconds before continuing with whatever aspect of the story is currently in progress.

### See Also

- [The Passage Of Time] for ways to keep track of clock-time within the story.

## Glulx Multimedia Effects

^^{Glulx: required for multimedia}^^{Z-machine: no support for multimedia}^^{virtual machine: multimedia support}^^{figures}^^{sounds}^^{files (data files)}^^{windows, extra story windows}
Glulx is one of the two basic story file formats to which Inform can work. It is the more powerful of the two, and modern-day Inform uses it by default. At one time it was a less universally playable format, but today players rarely have any trouble getting it to work.

Among its powers are the ability to display images, play back sound effects, and read and write external files to the disc. With care and a certain amount of fuss, this can even give a playing story file limited Internet connectivity, although it should be stressed that this can only be done if the player sets up their computer just right and runs an auxiliary program beside the story itself. That will mostly be too much to ask, if the player is playing offline, but when the story file is being run on an interpreter running at a server–so that the player simply sends commands to it and sees responses back on a web page–one could easily imagine setting up the server to provide these auxiliary programs, without any extra difficulty for the player.

Many of the more advanced multimedia abilities of Glulx are best unlocked using extensions available from the Inform website or the Public Library. As of this writing, extensions exist to help authors create complex multi-windowed displays (including per-location pictures, visual status bars, and even limited animations and gradually-revealed maps).

There is also work in progress on sound-management to allow the author to play sounds in multiple channels at once, to change sound volumes, and to create fade-in and fade-out effects.

Without extensions, all these abilities are within reach for an author who is willing to do some fairly advanced programming.

# Testing and Publishing

## Testing

^^{user interface: Skein panel} ^^{Skein panel+ui+}^^{SHOWME+testcmd+} ^^{testing commands: >SHOWME}^^{ACTIONS+testcmd+} ^^{testing commands: >ACTIONS}^^{SCENES+testcmd+} ^^{testing commands: >SCENES}^^{release version (of the story)}^^{test version (of the story)}^^{omitting code, for release version}^^{|not for release}^^{|for release only}^^{testing commands}^^{testing commands: defining} ^^{defining: testing commands}^^{testing commands: comments in transcripts from beta testers}^^{comments: in transcripts from beta testers}
There are no recipes for testing, alas, although most experienced IF authors have their preferred ways of going about it. Briefly: the best advice is to build and maintain a Skein which holds complete play-throughs of the piece, so that it is easy to check with a single click that all is still well; to have beta-testers who play through (substantial) drafts and send back their transcripts of play, along with suggestions; and to listen to these suggestions, and treat the beta-testers as editors rather than galley slaves.

[Alpha] shows a way to gracefully accept beta-testers' annotations without advancing time in the story.

Most large works of IF have historically provided secret commands for testing and debugging–commands removed (or sometimes accidentally not) in the final released product. Inform does this automatically: the commands ``SHOWME``, ``ACTIONS`` and ``SCENES`` are always present except in a released story file. It also allows us to write passages of source text which apply only for the testing phase, so that we can define new testing commands, or other checks that all is well: [Bic] demonstrates this, and is also useful in its own right.

## Publishing

^^{materials folder: map}^^{index map: customising for release}
These three examples simply show what can be done using Inform's EPS-format map output, if one is willing to tweak the design in some vector-art program. Unfortunately, at present, there are few alternatives to Adobe Illustrator–a superb but very expensive program–in the field of EPS editing, and indeed, of vector art generally: this is especially the case for Windows users. Inkscape is a usable free alternative, but it needs to have EPS files translated to PDFs before they can be used. On Mac OS X, the built-in Preview application can do this; otherwise the open-source Ghostscript might be used, but it can be a pain to install. Still, for the IF author who does have EPS editing facilities available, Inform will play nicely with them.
