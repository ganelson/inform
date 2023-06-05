Physical World Model.

Spatial relationships; the hierarchy of kinds used to model things and places,
and their properties.

@h Verbs and Relations.
We first extend our suite of verbs and meanings to cover standard
world-modelling terms.

=
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

@ The enclosure relation, indirectly defined in terms of the above more
fundamental ones, has a verb but no prepositions (though of course "to be
enclosed by" is in effect a prepositional expression of this).

=
The verb to enclose means the enclosure relation.

@ Those three relations expressed how the inanimate world is arranged, on
the small scale: the relationships become a little more complicated once
living beings are involved.

=
The verb to carry means the carrying relation.
The verb to hold means the holding relation.
The verb to wear means the wearing relation.

@ One living being is special to our language -- the protagonist character,
that is, the "player" -- and so these three verbs all have adjectival forms
which imply the player as the missing term.

=
Definition: a thing is worn if the player is wearing it.
Definition: a thing is carried if the player is carrying it.
Definition: a thing is held if the player is holding it.

@ Animate beings also have the ability to see and touch their surroundings,
but note that we only model the ability to do these things -- we do not attempt
to track what they actually do see or touch at any given moment, so there are
no built-in verbs "to see" or "to touch".

=
The verb to be able to see means the visibility relation.
The verb to be able to hear means the audibility relation.
The verb to be able to touch means the touchability relation.

@ The special status of the player as the sensory focus, so to speak, is
again shown in the adjectives defined here:

=
Definition: Something is visible rather than invisible if the player can see it.
Definition: Something is touchable rather than untouchable if the player can touch it.

@ While many of the world-modelling assumptions in I7 are carried over from
those tried and tested by I6, the idea of concealment is an exception. The
old I6 attribute |concealed| simply marked some objects (which we would
call "things") as being hidden from view in some way, but was never very
satisfactory. What does hidden mean, exactly -- to whose eyes, and in what
way? Should you be able to take something which is hidden, if you happen to
know it's there? And so on. It was the muddiest of all the attributes, and
widely disused as a result. In I7, we instead took the view that
concealment required an active agent continuously doing the concealing: it
applies, for instance, to a dagger which someone intentionally hides
beneath a cloak, but not to a key placed at the back of a shelf by somebody
long gone.

=
The verb to conceal (he conceals, they conceal, he concealed, it is concealed,
he is concealing) means the concealment relation.
Definition: Something is concealed rather than unconcealed if the holder of it conceals it.

@ If a supporter or container has something on/in it, but all the contents are concealed or
undescribed, default behavior should be the same to what it would be if it were empty. The
following adjectives assist the maintenance of the deceit.

Something is obviously-occupied if it has at least one obvious (neither concealed nor
undescribed) thing in it, but closed opaque containers the player is outside of aren't
obviously-occupied because their status isn't obvious. The player is undescribed and so
the player's own presence in an enterable supporter or container doesn't count toward it
being considered occupied. The opposite of obviously-occupied is possibly-unoccupied.
Something is possibly-unoccupied if it's truly empty, or the only things in it are concealed
or undescribed (or both), or it's a closed opaque container the player is outside of.

Something is falsely-unoccupied if it's not a closed opaque continer the player is outside
of and it's not truly empty but everything in it is concealed or undescribed. Note that
falsely-unoccupied is not the opposite of obviously-occupied. Possibly-occupied is the
opposite of obviously-occupied; falsely-occupied is something different.

None of this considers visibility per se and they behave the same way in light or
darkness. The presumption is that if the game is evaluating whether the player can perceive
the contents of a thing, it has already been determined that they can perceive that
thing.

These tests only consider what's directly contained or supported. If there's an obvious
thing its contents can't make it any less obvious; if something is undescribed or
concealed, it's assumed that the game shouldn't be calling attention to their contents.

These adjectives are not defined for people. Things directly held by the player are always
perceptible by the player. Things possessed by other people aren't mentioned by default
in room descriptions or when searching or examining them, but only through whatever rules
an author adds to do so, so the details are left to the author.

=
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

@ A final sort of pseudo-containment: does the entire world contain
something, or not? (For things destroyed during play, or not yet created, the
answer would be no.)

=
Definition: Something is on-stage rather than off-stage if I6 routine "OnStage"
	makes it so (it is indirectly in one of the rooms).
Definition: Something is offstage if it is off-stage.

Definition: a scene is happening if I6 condition "scene_status-->(*1-1)==1"
	says so (it is currently taking place).

@h Kinds.
Basic Inform provides the kind "object", but no specialisations of it. We
will use objects to represent physical objects and locations, with the
hierarchy given below. (The template code assumes these kinds will be
declared in this order, so be careful rearranging them.)

Note the two alternative plural definitions for the word "person", with
"people" being defined earlier to make it the default: "persons" is
correct, but "people" is more idiomatically usual.

=
Chapter 2 - Kinds for the Physical World

Section 1 - Kind Definitions

A room is a kind.
A thing is a kind.
A direction is a kind.
A door is a kind of thing.
A container is a kind of thing.
A supporter is a kind of thing.
A backdrop is a kind of thing.
The plural of person is people. The plural of person is persons.
A person is a kind of thing.
A region is a kind.

@ At this point, then, the hierarchy looks like so:
= (text)
	kind
	    room
	    thing
	        door
	        container
	        supporter
	        backdrop
	        person
	    direction
	    region
=
This framework is the minimum kit needed in order for Inform to be able to
manage the spatial relationships arising from its basic verbs. Room and thing
are needed to distinguish places and objects; door and backdrop because they
need to violate the basic rule that an object can only be in one place at once
-- a door is "in" both of the rooms it faces onto -- and this requires special
handling by Inform; region because it violates the rule that rooms are not
themselves subject to being contained in other objects, and again this
requires special handling. That leaves "direction", "container", "supporter"
and "person", and these are needed to express the concepts inherent in the
sentences "A is east of B", "A is in B", "A is on B" and "A is carried by B".
(We also need room and person in order to make sense of the words "somewhere"
and "someone", for instance.)

Although further kinds will be created later ("vehicle", for instance),
those are merely design choices, and Inform would not be troubled by their
absence.

@

=
Section 1a - Concepts (for concepts language element only)

A concept is a kind.
A concept can be privately-named or publicly-named. A concept is usually publicly-named.

@h Rooms.
We now detail each of the fundamental kinds in turn, in order of their
declaration, and thus beginning with rooms.

=
Section 2 - Rooms

The specification of room is "Represents geographical locations, both indoor
and outdoor, which are not necessarily areas in a building. A player in one
room is mostly unable to sense, or interact with, anything in a different room.
Rooms are arranged in a map."

@ Rooms have rather few properties built in; this reflects their usual role
in IF as ambient environments in which interesting things happen, rather
than being direct participants.

=
A room can be privately-named or publicly-named. A room is usually publicly-named.
A room can be lighted or dark. A room is usually lighted.
A room can be visited or unvisited. A room is usually unvisited.

A room has a text called description.

@ Note that the "map region" property here is created with the type
"object", not "region", even though we think of it as always being a
region. This is because of I7's type-checking rule: the type "object" can
legally hold 0, meaning "nothing", but more specific object types -- in
this case "region" -- cannot. That would make them illegal to use in a
situation where no regions were created, because variables or properties of
this kind couldn't be initialised. This is why the Standard Rules almost
always declare object properties as "object" rather than anything more
specific.

=
A room has an object called map region. The map region of a room is usually nothing.

@ Rooms have two specialised spatial relationships of their own, which again
we need verbal forms of:

=
The verb to be adjacent to means the reversed adjacency relation.
Definition: A room is adjacent if it is adjacent to the location.

The verb to be regionally in means the reversed regional-containment relation.

@ There's no detailed writeup of regions, since they have no properties
in the usual setup. So let's add this here for the Kinds index:

=
The specification of region is "Represents a broader area than a single
room, and allows rules to apply to a whole geographical territory. Each
region can contain many rooms, and regions can even be inside each other,
though they cannot otherwise overlap. For instance, the room Place d'Italie
might be inside the region 13th Arrondissement, which in turn is inside
the region Paris. Regions are useful mainly when the world is a large one,
and are optional."

A region can be privately-named or publicly-named. A region is usually publicly-named.

@h Things.
Things are ubiquitous:

=
Section 3 - Things

The specification of thing is "Represents anything interactive in the model
world that is not a room. People, pieces of scenery, furniture, doors and
mislaid umbrellas might all be examples, and so might more surprising things
like the sound of birdsong or a shaft of sunlight."

@ The large number of either/or properties things can have reflects the
flexibility of the I6 world model, which we largely adopt for I7 too. That
is, you can have any combination of lit/unlit, edible/inedible, fixed in
place/portable, and so on. We can divide them into three broad categories:
first, physical properties. Things come in $2^6 = 64$ physically different
varieties, which is rather a lot, but although some combinations are very
rare (edible lit pushable between rooms scenery is not met with often)
this flexibility is helpful in mitigating the rigidity of the kinds
structure, given that we have single inheritance of kinds. Note that,
except for "lit", these are all really to do with whether and how people
can move things around -- even edibility, which is the ability to be removed
from the world model entirely.

=
A thing can be lit or unlit. A thing is usually unlit.
A thing can be edible or inedible. A thing is usually inedible.
A thing can be fixed in place or portable. A thing is usually portable.
A thing can be scenery.
A thing can be wearable.
A thing can be pushable between rooms.

@ Second, status properties, which in effect refer to the past history of an
item without our needing to use the past tenses, which can be tricky or
inefficient. "Handled" means that the player has at some time carried the
thing in question. (We used to have "initially carried" here, too, but that's
now considered a part of the verb "to carry" rather than an adjective.)

=
A thing can be handled.

@ Third, linguistic properties, influencing when and how the thing's name
will be included in lists. ("Mentioned" goes here rather than as a status
property because it refers only to the current room description, so it carries
no long-term historic information. "Marked for listing", similarly, carries
only short-term information and is used as workspace by the I6 library and
also by some of the I7 template routines.)

=
A thing can be privately-named or publicly-named. A thing is usually publicly-named.
A thing can be undescribed or described. A thing is usually described.
A thing can be marked for listing or unmarked for listing. A thing is usually
unmarked for listing.
A thing can be mentioned or unmentioned. A thing is usually mentioned.

@ We now have a mixed bag of value properties, all descriptive -- it's an
interesting reflection on how qualitative English text usually is that the
world model so seldom needs quantitative properties (sizes, weights, distances,
and so on).

=
A thing has a text called a description.
A thing has a text called an initial appearance.

@ Lastly on things: an implication about scenery. The following sentence looks
like an assertion much like others above ("A thing is usually inedible", for
instance) -- but in fact it is an "implication": it says that an object having
one property also probably has another. The Standard Rules make only very
sparing use of implications. They can trip up the user (who may quite
reasonably say that it is up to him what properties something has): but they
are invaluable if they cause Inform to make deductions which any human reader
would always make without thought.

They can of course be overruled by explicit sentences in the source text,
just as every sentence qualified by "usually" can.

=
Scenery is usually fixed in place. [An implication.]

@h Directions.
The first important point about directions is that they are not things and
not rooms. They are not positions in the world, but imaginary arrows pointing
in different ways one could go from those positions. In the language of
geometry, we could call them tangent vectors which can be taken anywhere
in space by parallel transport without altering them: that's to say, the
"north" in one place is the same as the "north" anywhere else. (This
is how we get away with having just one set of 12 direction objects, not
12 different ones for every location.) Implicit in that assumption is that
the model world occupies a "flat" Euclidean space, to use further
mathematical jargon: it doesn't wrap around on itself, and there are no
bad positions where the directions fail. (Compare the Infocom game "Leather
Goddesses of Phobos", in which the South Pole of Mars is just such a
singularity: there are three routes out of this location, all of them
"north". This of course required special programming, and so it would in
an Inform 7 work, too.) More concisely:

=
Section 4 - Directions

The specification of direction is "Represents a direction of movement, such
as northeast or down. They always occur in opposite, matched pairs: northeast
and southwest, for instance; down and up."

A direction can be privately-named or publicly-named. A direction is usually
publicly-named.
A direction can be marked for listing or unmarked for listing. A direction is
usually unmarked for listing.
A direction can be scenery. A direction is always scenery.

@ The following value property expresses that all directions in I7 come in
matched, diametrically opposing pairs -- north/south, up/down and so on.
This is a concept we need to provide so that I7 can apply its assumption
that if room X is north of room Y, then probably room Y is also south of
room X, and so on. (Geometrically, this is the operation of negation in
the tangent bundle.) Note that the kind of value here is "direction",
not "object": a value of 0, meaning "there's no opposite", is illegal.

=
A direction has a direction called an opposite.

@ The Standard Rules define only thirteen I7 objects, and here we go with
twelve of them: the standard set of directions, which come in six pairs
of opposites.

The following set -- N/S, NE/SW, E/W, SE/NW, U/D, IN/OUT -- is rooted in IF
tradition. It seems unlikely that people would make IN/OUT a pair of
directions today if starting from a clean slate: this is really a residue
of the traditional implementation, in 70s and 80s IF, of commands which
moved the player in unorthodox way. Outside the cave mouth, typing IN
should take you inside; in the Y2 Rock Room, typing the magic word PLUGH
should take you far away. The most convenient way to implement such
commands in as few instructions as possible was to regard these as
little-used compass directions rather than independent commands (some
implementations of the original Adventure regarded XYZZY, PLUGH, PLOVER as
all being directions, thus using 15 of the 16 possibilities which could be
represented in a 4-bit field). In the 90s this was seen to be a little
bogus, but since IN and OUT clearly applied in a variety of settings, they
continued to be regarded as bona fide directions. In effect, they allow for
one location to surround another: the canonical example would be a small
white building in the middle of a field. Anyway, I7 accepts the current
orthodoxy, so IN/OUT are allowed, even though they cause headaches for the
interpretation of words like "inside" which might refer either to the
"horizontal" or "vertical" spatial models as a result.

Of the rest, N/S, NE/SW, E/W, SE/NW and U/D, it's noteworthy that this
choice imposes a cubical grid on the world, simply because the compass
directions are at 45 and 90 degree angles to each other: a hexagonal
tessellation would be more faithful to distances (it would get rid of the
awkward point that a NE move is root 2 times the length of a N move),
but in practice the world model doesn't care much about distances, another
example of its qualitative nature. A further point is that, in a
three-dimensional cubic lattice, we ought to have another eight pairs
of directions for "up and northeast", "down and west" and so on --
instead of which U/D are the only ways out of the horizontal plane.
But natural language doesn't work that way: it overwhelmingly provides
words for horizontal travel, because that's the plane in which our eyes
normally see, and in which we normally walk. Linguistically, "north"
genuinely means north, but "up" allows for any amount of lateral
movement into the bargain. It's a doctrine of I7 that linguistic bias is
a good guide to what's worth modelling and what is not, so we will now
stop worrying about this and declare the actual objects.

The order of definition of the directions affects the way lists come out:
the traditional order is N, NE, NW, S, SE, SW, E, W, U, D, IN, OUT.

=
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

@h Doors.
Doors are, literally, a difficult edge case for the world model of IF, since
they occupy the awkward junction between the two different ways of dividing
up space: the "vertical" model of objects containing and supporting each
other, all within a tree rooted by the room which represents, for the moment,
the entire stage-set for the play; and the "horizontal" model of rooms
stitched together at compass directions into a map. The difficulty arises
because in order for a door to make sense in the horizontal model, it needs
to be present in two different rooms at the same time, and then it doesn't
make sense in the vertical model any more, because which object tree is it
to be in?

=
Section 5 - Doors

The specification of door is "Represents a conduit joining two rooms, most
often a door or gate but sometimes a plank bridge, a slide or a hatchway.
Usually visible and operable from both sides (for instance if you write
'The blue door is east of the Ballroom and west of the Garden.'), but
sometimes only one-way (for instance if you write 'East of the Ballroom is
the long slide. Through the long slide is the cellar.')."

@ This is the first kind we have declared to be a kind of something else:
a door is a kind of thing. That means a door inherits all of the properties
of a thing, but in a way which allows us to change the normal expectations.
So here we see the first case of assertions which contradict earlier ones,
but in a narrower domain: a thing is usually portable, but a door is usually
fixed in place.

Our difficulty with doors being multiply present would be enormously worse
if we allowed anybody to move them around during play. So:

=
A door is always fixed in place.
A door is never pushable between rooms.

@ "Every exit is an entrance somewhere else," as Stoppard's play
"Rosencrantz and Guildenstern are Dead" puts it: and though not all
I7 doors are present on both sides, they do nevertheless have two sides.
The representation of this is quite tricky because, as Stoppard implies,
it's all a matter of which side you look at it from. What we call the
"other side", and whether or not we say that "the Ballroom is through
the green door", depends entirely on which side of the green door we
stand. The awkward truth is that these expressions are undefined unless
the player is in one of the (possibly) two rooms in which the green
door is present; and then they are defined relative to him.

The leading-through relation is built in to Inform. This has to be stored
in the property "door_to", but we don't want to give authors direct access
to this property, since its contents are strictly speaking not typesafe.
(It stores a value to which a message can be sent which must return an object:
but that is not always the same thing as storing an object.)

Until 2021, the storage property was called "other side", and was useful
in as much as "the other side of D" would helpfully evaluate to the location
on the other side of a door. But that only worked because of a hacky exception
in the code handling property evaluation which made "door_to" a special case,
and this led to other problems. Instead, a new phrase "other side of (D - door)"
has been added to the Standard Rules, and this avoids directly evaluating "door_to".

=
A door has an object called leading-through destination.
The leading-through destination property is defined by Inter as "door_to".
Leading-through relates one room (called the leading-through destination) to
various doors. The verb to be through means the leading-through relation.

@h Containers and supporters.
The carrying capacity property is the exception to the remarks above about
the qualitative nature of the world model: here for the first and only time
we have a value which can be meaningfully compared.

=
Section 6 - Containers

The specification of container is "Represents something into which portable
things can be put, such as a teachest or a handbag. Something with a really
large immobile interior, such as the Albert Hall, had better be a room
instead."

A container can be enterable.
A container can be transparent or opaque. A container is usually opaque.
A container has a number called carrying capacity.
The carrying capacity of a container is usually 100.

@ The most interesting thing to note here (and we will see it again in the
definition of "people") is that "transparent" the I7 property is not
a direct match onto |transparent| the I6 attribute. In I7, the term is
applicable only to containers (a reform made in January 2008, but clarifying
what was already de facto the case). In I6, the |transparent| attribute
means that child-objects in the object tree are in scope whenever the parent
object is: in the I7 world model that's always true for supporters, so we
oblige all supporters to have the attribute |transparent| in their I6
compiled forms. The same will be true for people. That doesn't in practice
mean that I7 never has high shelves or people with daggers concealed
beneath cloaks -- just that we no longer use I6's mechanism for hiding
these things, and expect the user to write activity rules instead.

=
Section 7 - Supporters

The specification of supporter is "Represents a surface on which things can be
placed, such as a table."

A supporter can be enterable.
A supporter has a number called carrying capacity.
The carrying capacity of a supporter is usually 100.

A supporter is usually fixed in place.
A supporter can be transparent. A supporter is always transparent.

@h Kinds vs patterns.
A problem faced by all object-oriented systems is "fear of the diamond",
the problematic diagram of inheritance which results when we have two
different subclasses B and C of a class A, which represent quite different
ideas, but then we also turn out to want some behaviour D which is shared
between some of the Bs and some of the Cs. For instance, we might have one
class for people and another for buildings, but want to use the same
code when it comes to (say) printing out top ten lists of basketball
players (people) and skyscrapers (buildings) in height order: why not?
But then again, what does D conceptually represent? Surely we aren't saying
there's a natural concept of "basketball player/skyscraper"?

There are various responses, of which the most widely used now is probably
that of |C++|'s notion of templates. We would define our top-ten business
by writing a function applying to a list of objects of any class $T$ such
that $T$ provided a height: there would then be no need for "basketball
player/skyscraper" to be a class in its own right. Instead, we would
define the behaviour as being available to anything for which it makes
sense.

This is broadly what Inform 7 does, too, though not so formally. We use the
term "pattern" for this, and have actually seen two patterns already --
the way that containers and supporters share the "carrying capacity"
limit, and also the notion of transparency -- and it's by providing two
patterns that we are able to deal with the likeness and also unlikeness of
doors and containers. Their unlikeness is obvious; but their likeness is
that they both grant or withhold access to some extent of space bordering
on the current one. (Doors do this for the "horizontal" spatial model
between rooms, whereas containers do it for the "vertical" spatial model
of objects enclosing each other.)

@h The openability pattern.
To satisfy the openability pattern, a thing has to provide both of the
either/or properties "open" and "openable". This entitles it to be
opened and closed by the opening and closing actions, defined below.
Note that I7 has no formal concept of patterns as part of its type-checking:
instead, the rules for these actions explicitly check that they are being
applied to things matching the pattern, as we shall see.

Doors and containers have, as it happens, exactly opposite conventions
about the default values of these properties: but that doesn't mean they
don't share the pattern.

=
Section 8 - Openability

A door can be open or closed. A door is usually closed.
A door can be openable or unopenable. A door is usually openable.

A container can be open or closed. A container is usually open.
A container can be openable or unopenable. A container is usually unopenable.

@h The lockability pattern.
And similarly for lockability, because a principle of the world model is
that any spatial barrier can be given a lock if the designer so chooses. To
satisfy this pattern, a thing must

(i) satisfy the openability pattern, and
(ii) provide both the either/or properties "lockable" and "locked",
and also the value property "matching key".

Both doors and containers make some implications so that the words "lockable"
and "locked" carry the implied meanings which human readers expect, but
this is not essential to the functioning of lockability: it's only a graceful
addition.

=
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

@ Note that the lock-fitting relation has, as its domains, "thing" and
"thing". That means that compile-time typechecking will not reject an
attempt to apply the relation to (say) two vehicles. At run time, evaluating
"if X unlocks P" where P is a peculiar thing with no possibility of a lock
will always come out false; but trying to force it with "now X unlocks P"
will cause a run-time problem. In short, patterns are defended at run-time,
not at compile-time.

=
Lock-fitting relates one thing (called the matching key) to various things.
The verb to unlock means the lock-fitting relation.

@h Backdrops.
The true subtlety of backdrops is not visible in the brief description here:
but they require careful handling both in Inform and in the template layer code,
because they can be in many rooms at once.

=
Section 10 - Backdrops

The specification of backdrop is "Represents an aspect of the landscape
or architecture which extends across more than one room: for instance,
a stream, the sky or a long carpet."

A backdrop is usually scenery.
A backdrop is always fixed in place.
A backdrop is never pushable between rooms.

@h People.
From a compilation point of view, people are surprisingly easy to deal with.
It may well be argued that this is because the I6 world model is so sketchy
in modelling them, but that may actually be a good thing, because it's not at
all obvious that any single model will be sensible for what different
authors want to do with their characters.

On gender, see also the "man" and "woman" kinds below. Note that we have
three gender choices available -- male, female and neuter -- but these are,
for historical reasons to do with how gender is handled by the I6 library,
managed using either/or properties rather than a single three-way value
property. This doesn't in practice cause trouble. (Specifying something as
neuter overrides the male/female choice, if anyone does both for the same
object, but in practice nobody does.) When nothing is said about a person's
gender, it is assumed male, though this is used only linguistically (for
instance, the pronoun HIM can be used in commands about the object, rather
than HER or IT). There has to be some convention here, and in a case where
we don't know our linguistic ground, opting for the least surprising
behaviour seems wisest.

The Inform compiler automatically applies the either-or property |animate|
and the valued property |before| to a person, giving that value as just
|NULL|. This allows any person to become the protagonist during play
(using I6's |ChangePlayer| routine).

=
Section 11 - People

The specification of person is "Despite the name, not necessarily a human
being, but anything animate enough to envisage having a conversation with, or
bartering with."

A person can be female or male. A person is usually male.
A person can be neuter. A person is usually not neuter.

A person has a number called carrying capacity.
The carrying capacity of a person is usually 100.

A person can be transparent. A person is always transparent.

@ One among the people is special: the enigmatic default protagonist, whose
name is not "player" but "yourself". (The I6 library requires this object to
be created as |selfobj|, but that's not a name that is ever printed or parsed:
it's a constant value used only in I6 source code.)

The |yourself| object has to be proper-named to prevent the I6 library
from talking about "the yourself", as it otherwise might. "Undescribed"
in this context means that "yourself" is not described as being present
in room descriptions: this would be redundant and annoying.

The I6 property |saved_short_name| property is an implementation convenience
for use if there is ever a change of player, in which case the printed name
of the object will cease to be "yourself" and become "your former self"
instead. When this happens, the previous printed name (or |short_name| in
I6 terms) is stored in |saved_short_name| so that it can recovered later.
(We can't assume it was necessarily "yourself" because the source text
might have overridden this with a sentence like "The printed name of the
player is "your dreary self".") The Inform compiler automatically generates
that property for the "yourself" object, so we need do nothing here.

=
The yourself is an undescribed person. The yourself is proper-named.

The yourself is privately-named.
Understand "your former self" or "my former self" or "former self" or
	"former" as yourself when the player is not yourself.

The description of yourself is usually "As good-looking as ever."

The yourself object is accessible to Inter as "selfobj".

@h Non-fundamental kinds.
We have now finished defining the nine fundamental kinds which Inform requires
in order for it to function. There are six more to define, but it's worth
emphasising that none of these is required or assumed by either Inform or
its template layer of I6 code. So any of them could be changed drastically
or got rid of entirely simply by amending the Standard Rules. (Like the
"player-character" kind, born early 2003, died July 2007.)

Equally, we could add others if we wanted. The judgement of what ought to be
part of the basic hierarchy of kinds created by the Standard Rules isn't
easy. The maximalist position is that users welcome a plethora of kinds to
simulate many facets of real life, from canal-boats to candles. The minimalist
position is that kinds are necessary only as the domain of relations (so that
person is necessary as the domain of P in "P carries X", for instance), and
that too many kinds confuses the picture and imposes what may be a constraining
structure on the user, who should be free to decide for himself what concepts
are most helpful to organise. These arguments are discussed further in the
white paper, "Natural Language, Semantic Analysis and Interactive Fiction"
(2005), but briefly: we are minimalist but not puritanically so.

@h Men, women and animals.
Of these discretionary kinds, so to speak, "man" and "woman" are perhaps
the least challengeable. They are not obviously the domains of any
natural relation (unless one takes a very old-fashioned idea of gender
identity and supposes that, oh, "X keeps Y" implies that X is a wealthy
man and Y a mistress). But they are so linguistically natural in story-telling:
who would ever write "Jack is a person in the House. Jack is male." in
preference to "Jack is a man in the House."

An awkward point here is that, of course, most people would simply say "Jack
is in the House." and expect us to infer that Jack is a person from the fact
that this is more often a human name than, say, a proprietary brand of
microphone plug; and that Jack is male, because relatively few girls called
Jacqueline are nicknamed Jack. As it happens the Inform compiler doesn't allow
for tentative statements about the kinds of objects (only about their
property values), but it wouldn't be too hard to add such a system, with
a little care. The trouble is that we would then need a large dictionary of
boys' and girls' names, valid across American, Canadian, Australian and
British English (together with a selection from foreign tongues), and this
would always lead to puzzling omissions (why isn't "Glanville" recognised?)
or ambiguities (why is "Pat" a man?). And similarly for titles: "Mr",
"Mrs" and "Ms" are fairly indicative of gender, except in certain
military contexts, but what about (say) "Admiral" or "Reverend", where
there is a strong likelihood of masculinity but no more than that?
So Inform 7's compromise position is that the user does have to specify
gender explicitly, but that the kinds "man" and "woman" provide
conveniently abbreviated ways to do so. (We consider male and female
children to qualify in these categories.)

Anyway, we set out the Anglo-Saxon plurals, and then declare these kinds
purely in terms of gender: they have no distinguishing behaviour.

=
Section 12 - Animals, men and women

The plural of man is men. The plural of woman is women.

A man is a kind of person.
The specification of man is "Represents a man or boy."
A man is always male. A man is never neuter.

A woman is a kind of person.
The specification of woman is "Represents a woman or girl."
A woman is always female. A woman is never neuter.

@ But what about "animal"? Animals turn up often in IF, and of course
domestic animals have been part of human society since prehistoric times:
but then again, the same can be said for stoves and larders, and we aren't
declaring kinds for those.

The reason "animal" exists is mainly because it is almost always peculiar
to write "P is a person". Now that we have "man" and "woman" taken
care of, the remaining objects we might want to declare will almost always
fall into this category: it's intended to be used for "people" who are
animate but probably not intelligent, or anyway, not participants in human
society. It seems unusual to write "The black Labrador is a person."
because that sounds like an insistent assertion of rights and thus a quite
different sort of statement. (Don't drown that Labrador! He's a person.)

As can be seen from the tiny definition of "animal", though, it's really
nothing more than a name for a position in the kinds hierarchy. There is
not even any implication for gender.

=
An animal is a kind of person.

The specification of animal is "Represents an animal, or at any rate a
non-human living creature reasonably large and possible to interact with: a
giant Venus fly-trap might qualify, but not a patch of lichen."

@h Devices.
The justification for providing a "device" kind is much thinner. It's done
largely for traditional reasons -- such a concept existed in the I6 library,
which in turn followed Infocom conventions dating from the early 1980s.
The inclusion is defensible as representing a common linguistic category
found in everyday situations, where an inanimate object nevertheless does
something while under direct or indirect human control: we can also imagine
relations for which it could be a domain ("X is able to work D" meaning
that person X understands how to use the controls of device D, say). It
could equally be attacked as having a rather flimsy world model -- it's just
an on/off switch -- and representing a pretty inchoate mass of concepts,
from a mousetrap to a nuclear reactor.

=
Section 13 - Devices

A device is a kind of thing.

A device can be switched on or switched off. A device is usually switched off.

The specification of device is "Represents a machine or contrivance of some
kind which can be switched on or off."

@h Vehicles.
Here again the justification boils down to tradition. Vehicles were a
staple ingredient of the Infocom classics, largely because of code
originally written for the inflatable boat in the 1978-79 mainframe version
of "Zork", which was then copied through into later titles. Unlike
devices, though, vehicles are genuinely difficult to model, and the
implementation provided by the Standard Rules would be quite a lot of
work for a user to manage alone. (Consider, for instance, the case when
the player is sitting in an open basket when Bill, driving a fork-lift
truck, uses his vehicle to push the basket into another room.) There
might perhaps be a case for moving all of the vehicles material into
an extension, but it would have to be an extension supplied as part of
the built-in set, and whenever it was used the result would be that
the going action would rely on a pretty complicated interlacing of rules
as between this extension and the Standard Rules.

Turning to implementation, I6 -- surprisingly, perhaps -- doesn't have
a |vehicle| attribute: a vehicle is an object which is |enterable| and
whose |before| rule for the I6 |##Go| action returns the magic value 1.
A troublesome point here is that I6 makes no distinction between vehicles
which contain and vehicles which support. But we do, because once we have
decided to make "vehicle" a kind, it has to be either a kind of container
or a kind of supporter: it can't be both. We get around this by providing
for container-vehicles in the Standard Rules, as being the more commonly
occurring case, while providing for the other with the extension Rideable
Vehicles by Graham Nelson, which is in effect an offshoot of the Standard
Rules and is built-in to every installation of Inform 7. This also provides
for animals used as vehicles.

The alternative approach here would be to make "vehicle" not a kind but
an either/or property of things, so as to provide a pattern of behaviour
common to certain animals, containers and supporters. We could then move
Rideable Vehicles back into the Standard Rules, but that would add a fair
amount of code, and besides, it is unclear that "vehicleness" is something
we want to come and go during play, or that it's appropriate as an either/or
property of (for instance) a door or a person.

=
Section 14 - Vehicles

A vehicle is a kind of container.

The specification of vehicle is "Represents a container large enough for
a person to enter, and which can then move between rooms at the driver's
instruction. (If a supporter is needed instead, try the extension
Rideable Vehicles by Graham Nelson.)"

A vehicle is always enterable.

@ The part about vehicles not usually being portable is simply for realism's
sake: generally speaking if something can hold human weight it's pretty
large and heavy. (A bicycle is an edge case, and a skateboard is clearly
an exception, but that's why the rule is only "usually".)

If all vehicles were wheeled, there would be a case for a rule such as
"A vehicle is usually pushable between rooms." But this seems more likely
to trip up the designer with a surprise discovery in beta-testing than to
help him achieve realism. We don't want to be able to push hot-air balloons,
boats or spacecraft between rooms.

=
A vehicle is usually not portable.

@h Player's holdalls.
This is the final kind created in the Standard Rules, and probably the most
doubtful of all. It simply provides a hook to a cute and traditional feature
of the I6 library whereby spare possessions are automatically cleared out
of the player's way: it derives from the rucksack in the 1993 IF title "Curses".

=
Section 15 - Player's holdall

A player's holdall is a kind of container.

The specification of player's holdall is "Represents a container which the
player can carry around as a sort of rucksack, into which spare items are
automatically stowed away."

A player's holdall is always portable.
A player's holdall is usually openable.

@h Correspondence between I6 and I7 property and attribute names.
All of the kinds, objects and properties which make up the standard kit
provided to every source text are now complete. We conclude Section SR1 by
giving the Inform compiler a dictionary to tell it how I7's names for
properties -- some value properties, some either/or -- mesh with those
in the I6 library.

Ordinarily, a new value property such as "astral significance" would
be compiled by Inform into an I6 property called something like
= (text)
	P73_astral_significance
=
whereas a new either/or property might become either an I6 attribute or an
I6 property holding only |true| or |false|, at the compiler's discretion.
(It needs to use this discretion because I6 has a hard limit on the number
of attributes, whereas there are no limits on the number of properties used
in I7.) And if "astral significance" is a concept handled only by I7
source text, that's fine.

But we want our "printed name" property, for instance, to be the text
which the I6 library prints out whenever it uses the |short_name| of an
object: so we want the Inform compiler to use the I6 identifier |short_name|
for "printed name", not to invent a new one. Inform therefore maintains a
dictionary of equivalents, and here it is. (Any I7 property not named is
handled purely by I7 source text in the remainder of the Standard Rules.)

@ First, equivalents where I7 either/or properties map directly onto
I6 attributes. Note the way "lit" (for things) and "lighted" (for rooms)
both map onto the same I6 attribute, |light|. Attributes were in scarce
supply in I6 (with a limit of 32 in the early days, later raised to 48) and
this sort of reuse seemed sensible in the early 1990s, especially as the
meanings were basically similar.

=
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

@ Second, the I7 value properties mapping onto I6 properties. Again,
|map_region| is a new I6 property of our own, while the rest are I6 staples.
And see also "other side", which is translated above for timing reasons.

=
The carrying capacity property is defined by Inter as "capacity".
The description property is defined by Inter as "description".
The initial appearance property is defined by Inter as "initial".
The map region property is defined by Inter as "map_region".
The matching key property is defined by Inter as "with_key".
