[PL::Player::] The Player.

A plugin to give a special role to the player object.

@h Definitions.

@ Altogether we keep track of four objects, though the first pair often coincide,
and so do the second pair. (|I_yourself| is constant once set, like |K_room| and
other such "constants" in the Inform source code.)

= (early code)
instance *start_room = NULL; /* room in which play begins: e.g., Barber's Shop */
instance *start_object = NULL; /* object in which play begins: e.g., a barber's chair */
instance *player_character_object = NULL; /* the player character object used in this run */

instance *I_yourself = NULL; /* the default player character object, |selfobj| in I6 */

property *P_saved_short_name = NULL;

@ Two variables are also special. The time of day might not look as if it belongs
to this plugin, but the idea is to position the player in both space and time.

= (early code)
nonlocal_variable *player_VAR = NULL; /* initially |player_character_object| and often always |I_yourself| */
nonlocal_variable *time_of_day_VAR = NULL;
nonlocal_variable *score_VAR = NULL;

@h Initialisation.

=
void PL::Player::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_VARIABLE_NOTIFY, PL::Player::player_new_quantity_notify);
	PLUGIN_REGISTER(PLUGIN_VARIABLE_SET_WARNING, PL::Player::player_variable_set_warning);
	PLUGIN_REGISTER(PLUGIN_NEW_INSTANCE_NOTIFY, PL::Player::player_new_instance_notify);
	PLUGIN_REGISTER(PLUGIN_IRREGULAR_GENITIVE, PL::Player::player_irregular_genitive);
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Player::player_complete_model);
	PLUGIN_REGISTER(PLUGIN_REFINE_IMPLICIT_NOUN, PL::Player::player_refine_implicit_noun);
	PLUGIN_REGISTER(PLUGIN_DETECT_BODYSNATCHING, PL::Player::player_detect_bodysnatching);
	PLUGIN_REGISTER(PLUGIN_ANNOTATE_IN_WORLD_INDEX, PL::Player::player_annotate_in_World_index);
}

@h Special objects.
The "yourself" object is special in being tied, or "aliased", to the
"player" variable, so Inform needs to recognise it. (No need to translate; it
is created in English.)

=
<notable-player-instances> ::=
	yourself

@ =
int PL::Player::player_new_instance_notify(instance *inst) {
	wording IW = Instances::get_name(inst, FALSE);
	if (<notable-player-instances>(IW)) {
		I_yourself = inst; player_character_object = I_yourself;
		if (player_VAR) @<Alias the player variable to the yourself object@>;
	}
	return FALSE;
}

instance *PL::Player::get_start_room(void) {
	return start_room;
}

@h Special variables.
"Time of day" is a perfectly normal variable and we only note down its
identity in order to find out the initial time of day intended by the
source text.

"Player", on the other hand, is unusual in two respects. First, it's aliased
to an object; second, it's set in an unusual way. That is, Inform does not
compile

>> now the player is Mr Chasuble;

to something like |player = O31_mr_chasuble|, as it would do for a typical
variable. It's very important that code compiled by Inform 7 doesn't do
this, because if executed it would break the invariants for the various I6
variables about the current situation. The correct thing is always to call
the template routine |ChangePlayer|. We ensure that by supplying an I6
schema which overrides the standard one for setting global variables:

As usual, no need to translate these; they are created in English.

=
<notable-player-variables> ::=
	player |
	score |
	time of day

@ =
int PL::Player::player_new_quantity_notify(nonlocal_variable *nlv) {
	if (<notable-player-variables>(nlv->name)) {
		switch (<<r>>) {
			case 0:
				player_VAR = nlv;
				if (I_yourself) @<Alias the player variable to the yourself object@>;
				NonlocalVariables::set_write_schema(nlv, "ChangePlayer(*2)");
				break;
			case 1:
				score_VAR = nlv;
				NonlocalVariables::make_initalisable(score_VAR);
				break;
			case 2:
				time_of_day_VAR = nlv;
				NonlocalVariables::make_initalisable(time_of_day_VAR);
				break;
		}
	}
	return FALSE;
}

@h Aliasing and bodysnatching.
As can be seen, as soon as both "yourself" (object) and "player" (variable)
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

because an assertion like this causes |player_character_object| to diverge from |I_yourself|;
here of course it becomes the Lord Collingwood object.

=
int PL::Player::player_variable_set_warning(nonlocal_variable *nlv, parse_node *val) {
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
int PL::Player::player_detect_bodysnatching(inference_subject *body, int *snatcher,
	inference_subject **counterpart) {
	if ((player_character_object == I_yourself) ||
		(player_character_object == NULL) || (I_yourself == NULL)) return FALSE;

	kind *KP = Instances::to_kind(player_character_object);
	kind *KY = Instances::to_kind(I_yourself);

	if (Kinds::Compare::lt(KP, KY)) {
		if (body == Instances::as_subject(player_character_object)) {
			*snatcher = FALSE; *counterpart = Instances::as_subject(I_yourself); return TRUE; }
		if (body == Instances::as_subject(I_yourself)) {
			*snatcher = TRUE; *counterpart = Instances::as_subject(player_character_object); return TRUE; }
	} else {
		if (body == Instances::as_subject(player_character_object)) {
			*snatcher = TRUE; *counterpart = Instances::as_subject(I_yourself); return TRUE; }
		if (body == Instances::as_subject(I_yourself)) {
			*snatcher = FALSE; *counterpart = Instances::as_subject(player_character_object); return TRUE; }
	}
	return FALSE;
}

@h Linguistic variations.
Thankfully everything else is straightforward. The following is used to
ensure that assemblies such as "A nose is part of every person" produces
"your nose" rather than "yourself's nose":

=
int PL::Player::player_irregular_genitive(inference_subject *owner, text_stream *genitive, int *propriety) {
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
int PL::Player::player_refine_implicit_noun(parse_node *p) {
	if (<implicit-player-relationship>(Node::get_text(p))) {
		Assertions::Refiner::noun_from_infs(p, Instances::as_subject(player_character_object));
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
int PL::Player::player_complete_model(int stage) {
	if ((stage == 3) && (I_yourself)) {
		P_saved_short_name = Properties::Valued::new_nameless(I"saved_short_name", K_text);
		Properties::Valued::assert(P_saved_short_name, Instances::as_subject(I_yourself),
			Rvalues::from_unescaped_wording(Feeds::feed_text(I"yourself")), CERTAIN_CE);
	}
	if (stage == 4) {
		@<Set the start room to the earliest room defined in the source text@>;
		@<If the start room is still null, there's no room, so issue a problem@>;
		@<Otherwise see if the player has explicitly been placed in the model world@>;
	}
	return FALSE;
}

@<Set the start room to the earliest room defined in the source text@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if ((PL::Spatial::object_is_a_room(I)) && (start_room == NULL)
			&& (Projects::draws_from_source_file(Task::project(), Instances::get_creating_file(I))))
			start_room = I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if ((PL::Spatial::object_is_a_room(I)) && (start_room == NULL))
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
		start_object = PL::Spatial::progenitor(player_character_object);
		if (start_object) {
			start_room = start_object;
			while ((start_room) && (PL::Spatial::progenitor(start_room)))
				start_room = PL::Spatial::progenitor(start_room);
			if ((start_room) && (PL::Spatial::object_is_a_room(start_room) == FALSE)) {
				StandardProblems::object_problem(_p_(PM_StartsOutsideRooms),
					start_object,
					"seems to be where the player is supposed to begin",
					"but (so far as I know) it is not a room, nor is it ultimately "
					"contained inside a room.");
			}
			inference *inf;
			POSITIVE_KNOWLEDGE_LOOP(inf,
				Instances::as_subject(player_character_object), PART_OF_INF) {
				StandardProblems::object_problem(_p_(PM_PlayerIsPart),
					start_object,
					"seems to have the player attached as a component part",
					"which is not allowed. The player can be in a room, or "
					"inside a container, or on a supporter, but can't be part "
					"of something.");
			}
		}
	}

@h Initial time and place.
Well: the point of tracking all of those variables was solely to be able to
compile this little array, which provides enough details for the I6 template
code to set things up correctly at run-time.

=
void PL::Player::InitialSituation_define(int id, int val) {
	inter_name *iname = Hierarchy::find(id);
	Emit::named_array_begin(iname, K_value);
	Emit::named_numeric_constant(iname, (inter_ti) val);
	Hierarchy::make_available(Emit::tree(), iname);
}

void PL::Player::InitialSituation(void) {
	if (Plugins::Manage::plugged_in(player_plugin)) {
		PL::Player::InitialSituation_define(PLAYER_OBJECT_INIS_HL, 0);
		PL::Player::InitialSituation_define(START_OBJECT_INIS_HL, 1);
		PL::Player::InitialSituation_define(START_ROOM_INIS_HL, 2);
		PL::Player::InitialSituation_define(START_TIME_INIS_HL, 3);
		PL::Player::InitialSituation_define(DONE_INIS_HL, 4);
	
		inter_name *iname = Hierarchy::find(INITIALSITUATION_HL);
		packaging_state save = Emit::named_array_begin(iname, K_value);
		NonlocalVariables::emit_initial_value(player_VAR);
		if (start_object == NULL) Emit::array_numeric_entry(0);
		else Emit::array_iname_entry(Instances::iname(start_object));
		if (start_room == NULL) Emit::array_numeric_entry(0);
		else Emit::array_iname_entry(Instances::iname(start_room));
		NonlocalVariables::emit_initial_value(time_of_day_VAR);
		Emit::array_numeric_entry(0);
		Emit::array_end(save);
		Hierarchy::make_available(Emit::tree(), iname);
	}
}

@h World Index details.
We explicitly mention the player in the World index, since otherwise it won't
usually appear anywhere.

=
void PL::Player::index_object_further(OUTPUT_STREAM, instance *I, int depth, int details) {
	if ((I == start_room) && (I_yourself) &&
		(Instances::indexed_yet(I_yourself) == FALSE))
		Data::Objects::index(OUT, I_yourself, NULL, depth+1, details);
}

int PL::Player::player_annotate_in_World_index(OUTPUT_STREAM, instance *I) {
	if (I == PL::Player::get_start_room()) {
		WRITE(" - <i>room where play begins</i>");
		Index::DocReferences::link(OUT, I"ROOMPLAYBEGINS");
		return TRUE;
	}
	return FALSE;
}
