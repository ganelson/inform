[Player::] The Player.

A feature to give a special role to a person who is the protagonist.

@h Introduction.
The player is, in some ways, just another instance of the "person" kind, so
how hard can this be?

One issue is that, uniquely of all instances in the world model, the player is not
explicitly created and located by the source text; it is simply implicit that
there is a player. Except, of course, that an author can sometimes write about
"the player" being a person who is indeed explicitly created; and can write
about "the player" as if this were a constant, when in fact it is a variable
because of the possibility of changing avatar in play. All in all, "the player"
has highly unusual semantics, even though an Inform user is barely aware of that.

=
void Player::start(void) {
	PluginCalls::plug(PRODUCTION_LINE_PLUG, Player::production_line);
	PluginCalls::plug(NEW_VARIABLE_NOTIFY_PLUG, Player::new_variable_notify);
	PluginCalls::plug(VARIABLE_VALUE_NOTIFY_PLUG, Player::variable_set_warning);
	PluginCalls::plug(NEW_INSTANCE_NOTIFY_PLUG, Player::new_instance_notify);
	PluginCalls::plug(IRREGULAR_GENITIVE_IN_ASSEMBLY_PLUG, Player::irregular_genitive);
	PluginCalls::plug(COMPLETE_MODEL_PLUG, Player::complete_model);
	PluginCalls::plug(REFINE_IMPLICIT_NOUN_PLUG, Player::refine_implicit_noun);
	PluginCalls::plug(DETECT_BODYSNATCHING_PLUG, Player::detect_bodysnatching);
}

int Player::production_line(int stage, int debugging,
	stopwatch_timer *sequence_timer) {
	if (stage == TABLES_CSEQ) {
		BENCH(RTPlayer::InitialSituation);
	}
	return FALSE;
}

@h Variables of interest.
"Time of day" is a perfectly normal variable, and we only note down its
identity in order to find out if the author is setting an initial time of day.
"Player", though, behaves quite unusually: see above.

= (early code)
nonlocal_variable *player_VAR = NULL;
nonlocal_variable *time_of_day_VAR = NULL;

@ As usual, no need to translate these; they are created in English.

=
<notable-player-variables> ::=
	player |
	time of day

@ =
int Player::new_variable_notify(nonlocal_variable *nlv) {
	if (<notable-player-variables>(nlv->name)) {
		switch (<<r>>) {
			case 0:
				player_VAR = nlv;
				RTPlayer::player_schema(player_VAR);
				if (I_yourself) @<Alias the player variable to the yourself object@>;
				break;
			case 1:
				time_of_day_VAR = nlv;
				RTVariables::make_initialisable(time_of_day_VAR);
				break;
		}
	}
	return FALSE;
}

@h Instances of interest.
Altogether we keep track of four instances, though the first pair often coincide,
and so do the second pair.

= (early code)
instance *start_room = NULL; /* room in which play begins: e.g., Barber's Shop */
instance *start_object = NULL; /* object in which play begins: e.g., a barber's chair */

instance *player_character_object = NULL; /* the player character object used in this run */
instance *I_yourself = NULL; /* the default player character object, |selfobj| in I6 */

@ The "yourself" instance is special in being tied, or "aliased", to the
"player" variable, so Inform needs to recognise it. (No need to translate; it
is created in English.)

=
<notable-player-instances> ::=
	yourself

@ =
int Player::new_instance_notify(instance *inst) {
	wording IW = Instances::get_name(inst, FALSE);
	if (<notable-player-instances>(IW)) {
		I_yourself = inst; player_character_object = I_yourself;
		if (player_VAR) @<Alias the player variable to the yourself object@>;
	}
	return FALSE;
}

instance *Player::get_start_room(void) {
	return start_room;
}

@ As can be seen, as soon as both "yourself" (object) and "player" (variable)
have been created, they are aliased together. This is a form of tacit pointer
dereferencing, though authors probably don't think of it that way. A normal
object variable is like a pointer to an object, rather than an object itself,
and so the following doesn't make sense:

>> The top prize is an object that varies. The top prize is in the desk drawer.

Clearly something goes in the desk drawer, but it's quite ambiguous what: the
problem is that "top prize" describes some object, but it's not clear which.
(Inform generally disallows this even if the source text explicitly gives a
value for top prize.) But "player" is unusual because Inform authors are
encouraged always to describe the player object that way, and often don't
realise that it's a variable at all -- and most of the time it never changes
its value, of course, but simply remains equal to "yourself" throughout play.
So we want to allow this sort of thing:

>> The player is in the Cage.

even though it has exactly the same problem as the top prize. We get around
this by treating "player", in assertions, as if it were its own initial
value ("yourself") -- in effect, we silently dereference it. This is
aliasing.

@<Alias the player variable to the yourself object@> =
	inference_subject *subj = Instances::as_subject(I_yourself);
	InferenceSubjects::alias_to_nonlocal_variable(subj, player_VAR);
	NonlocalVariables::set_alias(player_VAR, subj);

@ We also, though, want to look out for this sort of thing:

>> The player is Lord Collingwood.

because an assertion like this causes |player_character_object| to diverge from
|I_yourself|; here of course it becomes the Lord Collingwood object.

=
int Player::variable_set_warning(nonlocal_variable *nlv, parse_node *val) {
	if (nlv == player_VAR) {
		instance *npc = Rvalues::to_object_instance(val);
		if (npc) {
			player_character_object = npc;
			return TRUE;
		}
	}
	return FALSE;
}

@ But it gets worse: as well as aliasing, there is bodysnatching. Our problem
is that once the author has written "The player is Lord Collingwood.", it's
clear that the "yourself" object shouldn't appear anywhere. But there are
two problems with that: one, the I6 template code needs it to exist, even if
it isn't in the model world; and two, we've just aliased "player" to it.

Bodysnatching allows one object (the "snatcher") to take over the life of
another (the "victim"), so that inferences made about the victim are diverted
to the snatcher. Thus if the source text reads:

>> The player is Lord Collingwood. The player carries a spyglass.

the second sentence goes through two transformations: first, because of
aliasing, Inform decides to draw an inference about "yourself", rather
than complaining that "player" is indefinite; and second, because of
bodysnatching, the Collingwood object (snatcher) takes over the inference
from the yourself object (victim). So Collingwood gets the spyglass, as
the source text clearly intended.

Bodysnatching is used only when |player_character_object| differs from |I_yourself|,
that is, when the source text explicitly sets a value for "player".

=
int Player::detect_bodysnatching(inference_subject *body, int *snatcher,
	inference_subject **counterpart) {
	if ((player_character_object == I_yourself) ||
		(player_character_object == NULL) || (I_yourself == NULL)) return FALSE;

	kind *KP = Instances::to_kind(player_character_object);
	kind *KY = Instances::to_kind(I_yourself);

	if ((Kinds::conforms_to(KP, KY)) && (Kinds::ne(KP, KY))) {
		if (body == Instances::as_subject(player_character_object)) {
			*snatcher = FALSE;
			*counterpart = Instances::as_subject(I_yourself);
			return TRUE;
		}
		if (body == Instances::as_subject(I_yourself)) {
			*snatcher = TRUE;
			*counterpart = Instances::as_subject(player_character_object);
			return TRUE;
		}
	} else {
		if (body == Instances::as_subject(player_character_object)) {
			*snatcher = TRUE;
			*counterpart = Instances::as_subject(I_yourself);
			return TRUE;
		}
		if (body == Instances::as_subject(I_yourself)) {
			*snatcher = FALSE;
			*counterpart = Instances::as_subject(player_character_object);
			return TRUE;
		}
	}
	return FALSE;
}

@h Linguistic variations.
Thankfully everything else is straightforward. The following is used to
ensure that assemblies such as "A nose is part of every person" produces
"your nose" rather than "yourself's nose":

=
int Player::irregular_genitive(inference_subject *owner, text_stream *genitive,
	int *propriety) {
	if (owner == Instances::as_subject(I_yourself)) {
		WRITE_TO(genitive, "your ");
		*propriety = TRUE;
		return TRUE;
	}
	if ((player_character_object) && (I_yourself) &&
		(player_character_object != I_yourself) &&
		(owner == Instances::as_subject(player_character_object))) {
		WRITE_TO(genitive, "your ");
		*propriety = TRUE;
		return TRUE;
	}
	return FALSE;
}

@ The adjectives "worn" and "carried" -- as in, "The nautical chart is
carried." -- implicitly refer to the player as the unstated term in the
relationship; that makes them our business here. "Initially carried" is
now deprecated, but is provided as synonymous with "carried" because it
was once an either/or property in the clumsier early stages of Inform 7,
and people still sometimes type it.

=
<implicit-player-relationship> ::=
	worn |
	carried |
	initially carried

@ =
int Player::refine_implicit_noun(parse_node *p) {
	if (<implicit-player-relationship>(Node::get_text(p))) {
		Refiner::give_subject_to_noun(p, Instances::as_subject(player_character_object));
		return TRUE;
	}
	return FALSE;
}

@h Model completion.
At stage III, we add a property to make things work out nicely in the event
of a change of player.

Otherwise we take no interest until stage IV, a point at which kinds of
objects and the spatial model for them are both completely worked out. We
won't change anything: all we will do is calculate the start object and the
start room by looking at where the player sits in the spatial model.

Very often, the source text doesn't specify where the player is, and then
we assume he is freestanding in the earliest defined room.

=
int Player::complete_model(int stage) {
	if ((stage == WORLD_STAGE_III) && (I_yourself)) {
		property *P_ssn = ValueProperties::new_nameless(I"saved_short_name", K_text);
		ValueProperties::assert(P_ssn, Instances::as_subject(I_yourself),
			Rvalues::from_unescaped_wording(Feeds::feed_text(I"yourself")), CERTAIN_CE);
	}
	if (stage == WORLD_STAGE_IV) {
		@<Set the start room to the earliest room defined in the source text@>;
		@<If the start room is still null, there's no room, so issue a problem@>;
		@<Otherwise see if the player has explicitly been placed in the model world@>;
	}
	return FALSE;
}

@<Set the start room to the earliest room defined in the source text@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if ((Spatial::object_is_a_room(I)) && (start_room == NULL)
			&& (Projects::draws_from_source_file(Task::project(),
				Instances::get_creating_file(I))))
			start_room = I;
	LOOP_OVER_INSTANCES(I, K_object)
		if ((Spatial::object_is_a_room(I)) && (start_room == NULL))
			start_room = I;
	start_object = start_room;

@<If the start room is still null, there's no room, so issue a problem@> =
	if ((start_room == NULL) && (Task::wraps_existing_storyfile() == FALSE)) {
		StandardProblems::unlocated_problem(Task::syntax_tree(), _p_(PM_NoStartRoom),
			"There doesn't seem to be any location in this story, so there's "
			"nowhere for the player to begin. This may be because I have "
			"misunderstood what was meant to be a room and what wasn't: I "
			"only know something is a room if you tell me explicitly ('The "
			"Observatory is a room') or if you imply it by giving map "
			"directions ('East of the Observatory is the Planetarium').");
		return FALSE;
	}

@ If the source text said nothing about the player's location, then the
player object will be a disconnected node in the containment tree: it will,
in fact, have no progenitor. In that event, the start room already calculated
will do. But otherwise:

@<Otherwise see if the player has explicitly been placed in the model world@> =
	if (player_character_object) {
		start_object = Spatial::progenitor(player_character_object);
		if (start_object) {
			start_room = start_object;
			while ((start_room) && (Spatial::progenitor(start_room)))
				start_room = Spatial::progenitor(start_room);
			if ((start_room) && (Spatial::object_is_a_room(start_room) == FALSE)) {
				StandardProblems::object_problem(_p_(PM_StartsOutsideRooms),
					start_object,
					"seems to be where the player is supposed to begin",
					"but (so far as I know) it is not a room, nor is it ultimately "
					"contained inside a room.");
			}
			inference *inf;
			POSITIVE_KNOWLEDGE_LOOP(inf,
				Instances::as_subject(player_character_object), part_of_inf) {
				StandardProblems::object_problem(_p_(PM_PlayerIsPart),
					start_object,
					"seems to have the player attached as a component part",
					"which is not allowed. The player can be in a room, or "
					"inside a container, or on a supporter, but can't be part "
					"of something.");
			}
		}
	}
