[PL::Map::] The Map.

A plugin to provide a geographical model, linking rooms and doors
together in oppositely-paired directions.

@h Definitions.

@ The map is a complicated data structure, both because it amounts to a
ternary relation (though being implemented by many binary ones) and because
of an ambiguity: a map connection from a room R can lead to another room S,
to a door, or to nothing. Doors come in two sorts, one and two-sided, and
checking the physical realism of all this means we need to produce many
quite specific problem messages.

We will use quite a lot of temporary work-space to put all of this
together, but the details can be ignored. If we expected very large numbers
of objects then it would be worth economising here, but profiling suggests
that it really isn't.

=
typedef struct map_data {
	/* these are meaningful for doors only */
	struct instance *map_connection_a;
	struct instance *map_connection_b;
	struct instance *map_direction_a;
	struct instance *map_direction_b;

	/* these are meaningful for directions only */
	int direction_index; /* counts 0, 1, 2, ..., in order of creation */
	struct inter_name *direction_iname; /* for the constant instance ref */
	struct binary_predicate *direction_relation; /* the corresponding "mapped D of" relation */

	/* these are meaningful for rooms only, and are used in making the World index */
	struct instance *exits[MAX_DIRECTIONS];
	struct parse_node *exits_set_at[MAX_DIRECTIONS];
	struct instance *spatial_relationship[12];
	int exit_lengths[MAX_DIRECTIONS];
	struct instance *lock_exits[MAX_DIRECTIONS];
	struct vector position;
	struct vector saved_gridpos;
	int cooled, shifted, zone;
	struct connected_submap *submap;
	struct instance *next_room_in_submap;
	wchar_t *world_index_colour; /* an HTML colour for the room square (rooms only) */
	wchar_t *world_index_text_colour; /* an HTML colour for the room text (rooms only) */
	struct map_parameter_scope local_map_parameters; /* temporary: used in EPS mapping */
	int eps_x, eps_y;

	CLASS_DEFINITION
} map_data;

@ It's obvious why the kinds direction and door are special. It's not so
obvious why "up" and "down" are: the answer is that there are linguistic
features of these which aren't shared by lateral directions. "Above the
garden is the treehouse", for instance, does not directly refer to either
direction, but implies both.

= (early code)
kind *K_direction = NULL;
kind *K_door = NULL;
instance *I_up = NULL;
instance *I_down = NULL;

@ Special properties. The I6 implementation of two-way doors and of what, in
I7, are called backdrops, is quite complicated. See the Inform Designer's Manual,
fourth edition (the "DM4") for explanations. We are essentially trying to
program all of that automatically, which is why these awkward multi-purpose
I6 properties (|door_to|, |found_in|, etc.) have no direct I7 equivalents.

= (early code)
property *P_door = NULL; /* I6 only */
property *P_door_dir = NULL; /* I6 only */
property *P_door_to = NULL; /* I6 only */
property *P_other_side = NULL; /* a value property for the other side of a door */
property *P_opposite = NULL; /* a value property for the reverse of a direction */
property *P_room_index = NULL; /* I6 only: workspace for path-finding through the map */
property *P_found_in = NULL; /* I6 only: needed for multiply-present objects */

@ While we could probably represent map knowledge using relation inferences
in connection with the "mapped D of" relations, it's altogether easier and
makes for more legible code if we use a special inference type of our own:

@d DIRECTION_INF 100 /* where do map connections from O lead? */

@ One useful constant:

@d MAX_WORDS_IN_DIRECTION (MAX_WORDS_IN_ASSEMBLAGE - 4)

@ These little structures are needed to remember routines to compile later:

=
typedef struct door_dir_notice {
	struct inter_name *ddn_iname;
	struct instance *door;
	struct instance *R1;
	struct instance *D1;
	struct instance *D2;
	CLASS_DEFINITION
} door_dir_notice;

typedef struct door_to_notice {
	struct inter_name *dtn_iname;
	struct instance *door;
	struct instance *R1;
	struct instance *R2;
	CLASS_DEFINITION
} door_to_notice;

@h Initialisation.

=
void PL::Map::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_BASE_KIND_NOTIFY, PL::Map::map_new_base_kind_notify);
	PLUGIN_REGISTER(PLUGIN_NEW_SUBJECT_NOTIFY, PL::Map::map_new_subject_notify);
	PLUGIN_REGISTER(PLUGIN_SET_KIND_NOTIFY, PL::Map::map_set_kind_notify);
	PLUGIN_REGISTER(PLUGIN_SET_SUBKIND_NOTIFY, PL::Map::map_set_subkind_notify);
	PLUGIN_REGISTER(PLUGIN_ACT_ON_SPECIAL_NPS, PL::Map::map_act_on_special_NPs);
	PLUGIN_REGISTER(PLUGIN_CHECK_GOING, PL::Map::map_check_going);
	PLUGIN_REGISTER(PLUGIN_COMPILE_MODEL_TABLES, PL::Map::map_compile_model_tables);
	PLUGIN_REGISTER(PLUGIN_ESTIMATE_PROPERTY_USAGE, PL::Map::map_estimate_property_usage);
	PLUGIN_REGISTER(PLUGIN_LOG_INFERENCE_TYPE, PL::Map::map_log_inference_type);
	PLUGIN_REGISTER(PLUGIN_INFERENCES_CONTRADICT, PL::Map::map_inferences_contradict);
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Map::map_complete_model);
	PLUGIN_REGISTER(PLUGIN_NEW_PROPERTY_NOTIFY, PL::Map::map_new_property_notify);
	PLUGIN_REGISTER(PLUGIN_PROPERTY_VALUE_NOTIFY, PL::Map::map_property_value_notify);
	PLUGIN_REGISTER(PLUGIN_INTERVENE_IN_ASSERTION, PL::Map::map_intervene_in_assertion);
	PLUGIN_REGISTER(PLUGIN_ADD_TO_WORLD_INDEX, PL::Map::map_add_to_World_index);
	PLUGIN_REGISTER(PLUGIN_ANNOTATE_IN_WORLD_INDEX, PL::Map::map_annotate_in_World_index);
}

@ =
map_data *PL::Map::new_data(inference_subject *subj) {
	map_data *md = CREATE(map_data);
	md->direction_index = -1;
	md->direction_relation = NULL;

	int i;
	for (i=0; i<MAX_DIRECTIONS; i++) {
		md->exits_set_at[i] = NULL;
		md->exits[i] = NULL;
	}
	md->map_connection_a = NULL; md->map_connection_b = NULL;
	md->map_direction_a = NULL; md->map_direction_b = NULL;

	PL::SpatialMap::initialise_mapping_data(md);
	return md;
}

@h Inferences.

=
int PL::Map::map_log_inference_type(int it) {
	switch(it) {
		case DIRECTION_INF: LOG("DIRECTION_INF"); return TRUE;
	}
	return FALSE;
}

@ Two subjects are attached to a direction inference: 1, the destination;
2, the direction. So at the |CI_DIFFER_IN_INFS1| level of similarity, two
different direction inferences disagree about the destination for a given
direction -- this of course is a contradiction.

=
int PL::Map::map_inferences_contradict(inference *A, inference *B, int similarity) {
	switch (World::Inferences::get_inference_type(A)) {
		case DIRECTION_INF:
			if (similarity == CI_DIFFER_IN_INFS1) return TRUE;
			break;
	}
	return FALSE;
}

@h Kinds.
These are kind names to do with mapping which Inform provides special
support for; it recognises the English name when defined by the Standard
Rules. (So there is no need to translate this to other languages.)

=
<notable-map-kinds> ::=
	direction |
	door

@ =
int PL::Map::map_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (<notable-map-kinds>(W)) {
		switch (<<r>>) {
			case 0: K_direction = new_base; return TRUE;
			case 1: K_door = new_base; return TRUE;
		}
	}
	return FALSE;
}

@ Direction needs to be an abstract object, not a thing or a room, so:

=
int PL::Map::map_set_subkind_notify(kind *sub, kind *super) {
	if ((sub == K_direction) && (super != K_object)) {
		if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DirectionAdrift),
				"'direction' is not allowed to be a kind of anything (other than "
				"'object')",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	if (super == K_direction) {
		if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DirectionSubkinded),
				"'direction' is not allowed to have more specific kinds",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	if ((K_backdrop) && (sub == K_door) && (Kinds::Compare::le(super, K_backdrop))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DoorAdrift),
				"'door' is not allowed to be a kind of 'backdrop'",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	if ((K_backdrop) && (sub == K_backdrop) && (Kinds::Compare::le(super, K_door))) {
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BackdropAdrift),
				"'backdrop' is not allowed to be a kind of 'door'",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	return FALSE;
}

@ =
int PL::Map::map_new_subject_notify(inference_subject *subj) {
	CREATE_PF_DATA(map, subj, PL::Map::new_data);
	return FALSE;
}

@ =
int PL::Map::object_is_a_direction(instance *I) {
	if ((Plugins::Manage::plugged_in(map_plugin)) && (K_direction) && (I) &&
		(Instances::of_kind(I, K_direction)))
		return TRUE;
	return FALSE;
}

@ =
int PL::Map::object_is_a_door(instance *I) {
	if ((Plugins::Manage::plugged_in(map_plugin)) && (K_door) && (I) &&
		(Instances::of_kind(I, K_door)))
		return TRUE;
	return FALSE;
}

int PL::Map::subject_is_a_door(inference_subject *infs) {
	return PL::Map::object_is_a_door(
		InferenceSubjects::as_object_instance(infs));
}

@h Directions and their numbers.
Directions play a special role because sentences like "east of the treehouse
is the garden" are parsed differently from sentences like "the nearby place
property of the treehouse is the garden"; they're also one domain of what
amounts to the ternary map relation, though we actually implement it as a
sheaf of binary relations, one for each direction. Anyway:

=
int PL::Map::is_a_direction(inference_subject *infs) {
	if (K_direction == NULL) return FALSE; /* in particular, if we aren't using the IF model */
	return InferenceSubjects::is_within(infs, Kinds::Knowledge::as_subject(K_direction));
}

@ When a new direction comes into existence (i.e., not when the underlying
object |I| is created, but when its kind is first realised to be "direction"),
we need to assign it a number:

=
int registered_directions = 0; /* next direction number to be free */

@ These are direction names which Inform provides special support for; it
recognises the English names when defined by the Standard Rules. (So there is
no need to translate this to other languages.)

=
<notable-map-directions> ::=
	up |
	down

@ =
int PL::Map::map_set_kind_notify(instance *I, kind *k) {
	kind *kw = Instances::to_kind(I);
	if ((!(Kinds::Compare::le(kw, K_direction))) &&
		(Kinds::Compare::le(k, K_direction))) {
		wording IW = Instances::get_name(I, FALSE);
		@<Vet the direction name for acceptability@>;
		if (<notable-map-directions>(IW)) {
			switch (<<r>>) {
				case 0: I_up = I; break;
				case 1: I_down = I; break;
			}
		}
		PL::Naming::object_takes_definite_article(Instances::as_subject(I));
		@<Assign the object a direction number and a mapped-D-of relation@>;
	}
	return FALSE;
}

@<Vet the direction name for acceptability@> =
	if (Wordings::empty(IW)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NamelessDirection),
			"nameless directions are not allowed",
			"so writing something like 'There is a direction.' is forbidden.");
		return TRUE;
	}
	if (Wordings::length(IW) > MAX_WORDS_IN_DIRECTION) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DirectionTooLong),
			"although direction names can be really quite long in today's Inform",
			"they can't be as long as that.");
		return TRUE;
	}

@<Assign the object a direction number and a mapped-D-of relation@> =
	registered_directions++;
	package_request *PR = Hierarchy::synoptic_package(DIRECTIONS_HAP);
	inter_name *dname = Hierarchy::make_iname_in(DIRECTION_HL, PR);
	PF_I(map, I)->direction_iname = dname;
	PL::MapDirections::make_mapped_predicate(I, dname);

@h The exits array.
The bulk of the map is stored in the arrays called |exits|, which hold the
map connections fanning out from each room. The direction numbers carefully
noted above are keys into these arrays.

It might look a little wasteful of I7's memory to expand the direction
inferences, a nicely compact representation, into large and sparse arrays.
But it's convenient, and profiling suggests that the memory overhead is not
significant. It also means that the World Index mapping code, which contains
quite crunchy algorithms, has the fastest possible access to the layout.

@d MAP_EXIT(X, Y) PF_I(map, X)->exits[Y]

=
void PL::Map::build_exits_array(void) {
	instance *I;
	int d = 0;
	LOOP_OVER_OBJECT_INSTANCES(I) {
		if (Kinds::Compare::le(Instances::to_kind(I), K_direction)) {
			PF_I(map, I)->direction_index = d++;
		}
	}
	LOOP_OVER_OBJECT_INSTANCES(I) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), DIRECTION_INF) {
			inference_subject *infs1, *infs2;
			World::Inferences::get_references(inf, &infs1, &infs2);
			instance *to = NULL, *dir = NULL;
			if (infs1) to = InferenceSubjects::as_object_instance(infs1);
			if (infs2) dir = InferenceSubjects::as_object_instance(infs2);
			if ((to) && (dir)) {
				int dn = PF_I(map, dir)->direction_index;
				if ((dn >= 0) && (dn < MAX_DIRECTIONS)) {
					MAP_EXIT(I, dn) = to;
					PF_I(map, I)->exits_set_at[dn] = World::Inferences::where_inferred(inf);
				}
			}
		}
	}
}

@ This is easy to translate into I6 (though that's partly because I7 doesn't
follow the traditional I6 library way to represent the map):

=
int PL::Map::map_compile_model_tables(void) {
	@<Declare I6 constants for the directions@>;
	@<Compile the I6 Map-Storage array@>;
	return FALSE;
}

@<Declare I6 constants for the directions@> =
	inter_name *ndi = Hierarchy::find(NO_DIRECTIONS_HL);
	Emit::named_numeric_constant(ndi, (inter_t) registered_directions);
	Hierarchy::make_available(Emit::tree(), ndi);

	instance *I;
	LOOP_OVER_INSTANCES(I, K_direction) {
		Emit::named_iname_constant(PF_I(map, I)->direction_iname, K_object, Instances::emitted_iname(I));
	}

@ The |Map_Storage| array consists only of the |exits| arrays written out
one after another. It looks wasteful of memory, since it is almost always
going to be filled mostly with |0| entries (meaning: no exit that way). But
the memory needs to be there because map connections can be added dynamically
at run-time, so we can't know now how many we will need.

@<Compile the I6 Map-Storage array@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		Instances::emitted_iname(I);
	inter_name *iname = Hierarchy::find(MAP_STORAGE_HL);
	packaging_state save = Emit::named_array_begin(iname, K_object);
	int words_used = 0;
	if (Task::wraps_existing_storyfile()) {
		Emit::array_divider(I"minimal, as there are no rooms");
		Emit::array_iname_entry(NULL);
		Emit::array_iname_entry(NULL);
		Emit::array_iname_entry(NULL);
		Emit::array_iname_entry(NULL);
		words_used = 4;
	} else {
		Emit::array_divider(I"one row per room");
		instance *I;
		LOOP_OVER_OBJECT_INSTANCES(I)
			if (PL::Spatial::object_is_a_room(I)) {
				int i;
				for (i=0; i<registered_directions; i++) {
					instance *to = MAP_EXIT(I, i);
					if (to)
						Emit::array_iname_entry(Instances::iname(to));
					else
						Emit::array_numeric_entry(0);
				}
				words_used++;
				TEMPORARY_TEXT(divider);
				WRITE_TO(divider, "Exits from: %~I", I);
				Emit::array_divider(divider);
				DISCARD_TEXT(divider);
			}
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);

@h Door connectivity.
We've seen how most of the map is represented, in the |exits| arrays. The
missing information has to do with doors. If east of the Carousel Room is
the oak door, then |Map_Storage| reveals only that fact, and not what's on
the other side of the door. This will eventually be compiled into the
|door_to| property for the oak door object. In the mean time, every door
object has four pieces of data attached:

=
void PL::Map::get_door_data(instance *door, instance **c1, instance **c2) {
	if (c1) *c1 = PF_I(map, door)->map_connection_a;
	if (c2) *c2 = PF_I(map, door)->map_connection_b;
}

@h Properties.
These are property names to do with mapping which Inform provides special
support for; it recognises the English names when they are defined by the
Standard Rules. (So there is no need to translate this to other languages.)

=
<notable-map-properties> ::=
	opposite |
	other side

@ =
int PL::Map::map_new_property_notify(property *prn) {
	if (<notable-map-properties>(prn->name)) {
		switch (<<r>>) {
			case 0: P_opposite = prn; break;
			case 1: P_other_side = prn; break;
		}
	}
	return FALSE;
}

@ We would like to deduce from a sentence like

>> The other side of the iron door is the Black Holding Area.

that the "Black Holding Area" is a room; otherwise, if it has no map
connections, Inform may well think it's just an object. This is where that
deduction is made:

=
int PL::Map::map_property_value_notify(property *prn, parse_node *val) {
	if (prn == P_other_side) {
		instance *I = Rvalues::to_object_instance(val);
		if (I) {
			World::Inferences::draw(IS_ROOM_INF, Instances::as_subject(I), CERTAIN_CE,
				NULL, NULL);
		}
	}
	return FALSE;
}

@ The I6 |found_in| property is a general mechanism for multiply-present
objects. This causes great complications, and I7 simplifies the model world
by hiding it from the author, and using it internally to implement backdrops
and two-sided doors. Two different plugins therefore need access to it (this
one and Backdrops), and this is where they set it.

=
void PL::Map::set_found_in(instance *I, inter_name *S) {
	if (P_found_in == NULL)
		P_found_in = Properties::Valued::new_nameless(I"found_in",
			K_value);
	if (World::Inferences::get_prop_state(
		Instances::as_subject(I), P_found_in))
			internal_error("rival found_in interpretations");
	Properties::Valued::assert(P_found_in, Instances::as_subject(I),
		Rvalues::from_iname(S), CERTAIN_CE);
}

@ This utility routine which looks for the "opposite"
property in the linked list of inferences belonging to an object.
(This is a property of directions.) Crude, but not time-sensitive,
and there seems little point in writing this any better.

=
instance *PL::Map::get_value_of_opposite_property(instance *I) {
	parse_node *val = World::Inferences::get_prop_state(
		Instances::as_subject(I), P_opposite);
	if (val) return Rvalues::to_object_instance(val);
	return NULL;
}

@ This really is very approximate, but:

=
int PL::Map::map_estimate_property_usage(kind *k, int *words_used) {
	if (Kinds::Compare::eq(k, K_door)) *words_used += 14;
	if (Kinds::Compare::eq(k, K_room)) *words_used += 2;
	return FALSE;
}

@h Linguistic extras.
These NPs allow us to refer to the special directions "up" and "down":

=
<notable-map-noun-phrases> ::=
	below |
	above

@ =
int PL::Map::map_act_on_special_NPs(parse_node *p) {
	if (<notable-map-noun-phrases>(Node::get_text(p))) {
		switch (<<r>>) {
			case 0:
				if (I_down) {
					Assertions::Refiner::noun_from_infs(p, Instances::as_subject(I_down));
					return TRUE;
				}
				break;
			case 1:
				if (I_up) {
					Assertions::Refiner::noun_from_infs(p, Instances::as_subject(I_up));
					return TRUE;
				}
				break;
		}
	}
	return FALSE;
}

@ We also add some optional clauses to the "going" action:

=
int PL::Map::map_check_going(parse_node *from, parse_node *to,
	parse_node *by, parse_node *through, parse_node *pushing) {
	if (PL::Actions::Patterns::check_going(from, "from",
		K_room, K_region) == FALSE) return FALSE;
	if (PL::Actions::Patterns::check_going(to, "to",
		K_room, K_region) == FALSE) return FALSE;
	if (PL::Actions::Patterns::check_going(by, "by",
		K_thing, NULL) == FALSE) return FALSE;
	if (PL::Actions::Patterns::check_going(through, "through",
		K_door, NULL) == FALSE) return FALSE;
	if (PL::Actions::Patterns::check_going(pushing, "with",
		K_thing, NULL) == FALSE) return FALSE;
	return TRUE;
}

@ Consider the sentences:

>> A dead end is a kind of room. The Pitch is a room. East is a dead end.

Inform would ordinarily read the third sentence as saying that the "east"
object (a direction) has kind "dead end", and would throw a problem message.

What was actually meant, of course, is that a new instance of "dead end"
exists to the east of the Pitch; in effect, we read it as:

>> Z is a dead end. East is Z.

where Z is a newly created and nameless object.

But we must be careful not to catch "East is a direction" in the same net
because, of course, that does set its kind.

=
int PL::Map::map_intervene_in_assertion(parse_node *px, parse_node *py) {
	if ((Node::get_type(px) == PROPER_NOUN_NT) &&
		(Node::get_type(py) == COMMON_NOUN_NT)) {
		inference_subject *left_object = Node::get_subject(px);
		inference_subject *right_kind = Node::get_subject(py);
		if ((PL::Map::is_a_direction(left_object)) &&
			(PL::Map::is_a_direction(right_kind) == FALSE)) {
			Assertions::Creator::convert_instance_to_nounphrase(py, NULL);
			return FALSE;
		}
		if (Annotations::read_int(px, nowhere_ANNOT)) {
			Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_NowhereDescribed),
				"'nowhere' cannot be made specific",
				"and so cannot have specific properties or be of any given kind.");
			return TRUE;
		}
	}
	return FALSE;
}

@h The map-connector.
Now we come to the code which creates map connections. This needs special
treatment only so that asserting $M(X, Y)$ also asserts $M'(Y, X)$, where
$M'$ is the predicate for the opposite direction to $M$; but since this
is only a guess, it drops from |CERTAIN_CE| to merely |LIKELY_CE|.

However, the map-connector can also run in one-way mode, where it doesn't
make this guess; so we begin with switching in and out.

=
int oneway_map_connections_only = FALSE;
void PL::Map::enter_one_way_mode(void) { oneway_map_connections_only = TRUE; }
void PL::Map::exit_one_way_mode(void) { oneway_map_connections_only = FALSE; }

@ Note that, in order to make the conjectural reverse map direction, we need
to look up the "opposite" property of the forward one. This relies on all
directions having their opposites defined before any map is built, and is the
reason for Inform's insistence that directions are always created in matched
pairs.

=
void PL::Map::connect(inference_subject *i_from, inference_subject *i_to,
	inference_subject *i_dir) {
	instance *go_from = InferenceSubjects::as_object_instance(i_from);
	instance *go_to = InferenceSubjects::as_object_instance(i_to);
	instance *forwards_dir = InferenceSubjects::as_object_instance(i_dir);
	if (Instances::of_kind(forwards_dir, K_direction) == FALSE)
		internal_error("unknown direction");
	instance *reverse_dir = PL::Map::get_value_of_opposite_property(forwards_dir);
	if (go_from == NULL) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_object(2, forwards_dir);
		Problems::quote_object(3, go_to);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_WayFromUnclear));
		Problems::issue_problem_segment(
			"On the basis of %1, I'm trying to make a map connection in the "
			"%2 direction to %3, but I can't make sense of where it goes from.");
		Problems::issue_problem_end();
		return;
	}

	PL::Map::oneway_map_connection(go_from, go_to, forwards_dir, CERTAIN_CE);
	if ((reverse_dir) && (go_to) && (oneway_map_connections_only == FALSE)) {
		if (Instances::of_kind(reverse_dir, K_direction) == FALSE) {
			Problems::quote_object(1, forwards_dir);
			Problems::quote_object(2, reverse_dir);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_OppositeNotDirection));
			Problems::issue_problem_segment(
				"I'm trying to make a map connection in the %1 direction, "
				"which means there ought to be map connection back in the "
				"opposite direction. But the opposite of %1 seems to be %2, "
				"which doesn't make sense since %2 isn't a direction. (Maybe "
				"you forgot to say that it was?)");
			Problems::issue_problem_end();
		} else PL::Map::oneway_map_connection(go_to, go_from, reverse_dir, LIKELY_CE);
	}
}

void PL::Map::oneway_map_connection(instance *go_from, instance *go_to,
	instance *forwards_dir, int certainty_level) {
	binary_predicate *bp = PL::MapDirections::get_mapping_relation(forwards_dir);
	if (bp == NULL) internal_error("map connection in non-direction");
	int x = prevailing_mood;
	prevailing_mood = certainty_level;
	Calculus::Propositions::Assert::assert_true_about(
		Calculus::Propositions::Abstract::to_set_simple_relation(bp, go_to),
		Instances::as_subject(go_from), certainty_level);
	prevailing_mood = x;
}

@h Model completion.
And here begins the fun. It's not as easy to write down the requirements for
the map as might be thought.

=
int PL::Map::map_complete_model(int stage) {
	switch (stage) {
		case 2:
			@<Give each room a room-index property as workspace for route finding@>;
			@<Ensure that map connections are room-to-room, room-to-door or door-to-room@>;
			if (problem_count > 0) break;
			@<Ensure that every door has either one or two connections from it@>;
			if (problem_count > 0) break;
			@<Ensure that no door has spurious other connections to it@>;
			if (problem_count > 0) break;
			@<Ensure that no door uses both map connections and other side@>;
			if (problem_count > 0) break;
			@<Ensure that no door is present in a room to which it does not connect@>;
			if (problem_count > 0) break;
			@<Place any one-sided door inside the room which connects to it@>;
			@<Assert found-in, door-to and door-dir properties for doors@>;
			break;
		case 4: PL::Map::build_exits_array(); break;
	}
	return FALSE;
}

@ Every room has a |room_index| property. It has no meaningful contents at
the start of play, and we initialise to $-1$ since this marks the route-finding
cache as being broken. (Route-finding is one of the few really time-critical
tasks at run-time, which is why we keep complicating the I7 code to
accommodate it.)

@<Give each room a room-index property as workspace for route finding@> =
	P_room_index = Properties::Valued::new_nameless(I"room_index", K_number);
	parse_node *minus_one = Rvalues::from_int(-1, EMPTY_WORDING);

	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if (PL::Spatial::object_is_a_room(I))
			Properties::Valued::assert(P_room_index,
				Instances::as_subject(I), minus_one, CERTAIN_CE);

@ The following code does little if the source is correct: it mostly
checks that various mapping impossibilities do not occur.

@<Ensure that map connections are room-to-room, room-to-door or door-to-room@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), DIRECTION_INF) {
			inference_subject *infs1;
			World::Inferences::get_references(inf, &infs1, NULL);
			instance *to = InferenceSubjects::as_object_instance(infs1);
			if ((PL::Spatial::object_is_a_room(I)) && (to) &&
				(PL::Map::object_is_a_door(to) == FALSE) &&
				(PL::Spatial::object_is_a_room(to) == FALSE))
				StandardProblems::contradiction_problem(_p_(PM_BadMapCell),
					Instances::get_creating_sentence(to),
					World::Inferences::where_inferred(inf), to,
					"appears to be something which can be reached via a map "
					"connection, but it seems to be neither a room nor a door",
					"and these are the only possibilities allowed by Inform.");
			if ((PL::Map::object_is_a_door(I)) &&
				(PL::Spatial::object_is_a_room(to) == FALSE))
				StandardProblems::object_problem(_p_(PM_DoorToNonRoom),
					I,
					"seems to be a door opening on something not a room",
					"but a door must connect one or two rooms (and in particular is "
					"not allowed to connect to another door).");
		}
	}

@<Ensure that every door has either one or two connections from it@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if (PL::Map::object_is_a_door(I)) {
			int connections_in = 0;
			inference *inf;
			parse_node *where[3];
			where[0] = NULL; where[1] = NULL; where[2] = NULL; /* to placate |gcc| */
			inference *front_side_inf = NULL, *back_side_inf = NULL;
			POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), DIRECTION_INF) {
				inference_subject *infs1, *infs2;
				World::Inferences::get_references(inf, &infs1, &infs2);
				instance *to = InferenceSubjects::as_object_instance(infs1);
				instance *dir = InferenceSubjects::as_object_instance(infs2);
				if (to) {
					if (connections_in == 0) {
						PF_I(map, I)->map_connection_a = to;
						PF_I(map, I)->map_direction_a = dir;
						where[0] = World::Inferences::where_inferred(inf);
						front_side_inf = inf;
					}
					if (connections_in == 1) {
						PF_I(map, I)->map_connection_b = to;
						PF_I(map, I)->map_direction_b = dir;
						where[1] = World::Inferences::where_inferred(inf);
						back_side_inf = inf;
					}
					if (connections_in == 2) {
						where[2] = World::Inferences::where_inferred(inf);
					}
					connections_in++;
				}
			}
			if ((front_side_inf) && (back_side_inf)) {
				if (World::Inferences::get_timestamp(front_side_inf) >
					World::Inferences::get_timestamp(back_side_inf)) {
					instance *X = PF_I(map, I)->map_connection_a;
					PF_I(map, I)->map_connection_a = PF_I(map, I)->map_connection_b;
					PF_I(map, I)->map_connection_b = X;
					X = PF_I(map, I)->map_direction_a;
					PF_I(map, I)->map_direction_a = PF_I(map, I)->map_direction_b;
					PF_I(map, I)->map_direction_b = X;
					parse_node *PX = where[0]; where[0] = where[1]; where[1] = PX;
				}
			}
			if (connections_in == 0) @<Issue a problem message for a stranded door@>;
			if (connections_in > 2) @<Issue a problem message for an overactive door@>;
		}

@<Issue a problem message for a stranded door@> =
	StandardProblems::object_problem(_p_(PM_DoorUnconnected),
		I,
		"seems to be a door with no way in or out",
		"so either you didn't mean it to be a door or you haven't specified what's "
		"on each side. You could do this by writing something like 'The blue door is "
		"east of the Library and west of the Conservatory'.");

@<Issue a problem message for an overactive door@> =
	Problems::quote_object(1, I);
	Problems::quote_source(2, where[0]);
	Problems::quote_source(3, where[1]);
	Problems::quote_source(4, where[2]);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_DoorOverconnected));
	Problems::issue_problem_segment(
		"%1 seems to be a door with three ways out (specified %2, %3 and %4), but "
		"you can only have one or two sides to a door in Inform: a one-sided "
		"door means a door which is only touchable and usable from one side, and an "
		"example might be a window through which one falls to the ground below. If "
		"you really need a three-sided cavity, best to make it a room in its own right.");
	Problems::issue_problem_end();

@ Since map connections are not always reversible (only most of the time), we
can't assume that having at most two ways out means there are at most two ways
in. So we check here that any way in to a door corresponds to one of its ways
out. (The reverse need not be true: it's possible for a door to lead to a room
from which there's no way back.)

@<Ensure that no door has spurious other connections to it@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if (PL::Spatial::object_is_a_room(I)) {
			inference *inf;
			POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), DIRECTION_INF) {
				inference_subject *infs1;
				World::Inferences::get_references(inf, &infs1, NULL);
				instance *to = InferenceSubjects::as_object_instance(infs1);
				if (PL::Map::object_is_a_door(to)) {
					instance *exit1 = PF_I(map, to)->map_connection_a;
					instance *exit2 = PF_I(map, to)->map_connection_b;
					if ((I != exit1) && (exit2 == NULL)) {
						Problems::quote_object(1, I);
						Problems::quote_object(2, to);
						Problems::quote_object(3, exit1);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RoomTwistyDoor));
						Problems::issue_problem_segment(
							"%1, a room, seems to have a map connection which goes "
							"through %2, a door: but that doesn't seem physically "
							"possible, since %2 seems to connect to %3 in the same "
							"direction. Something's twisty here.");
						Problems::issue_problem_end();
					} else if ((I != exit1) && (I != exit2)) {
						Problems::quote_object(1, I);
						Problems::quote_object(2, to);
						Problems::quote_object(3, exit1);
						Problems::quote_object(4, exit2);
						StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RoomMissingDoor));
						Problems::issue_problem_segment(
							"%1, a room, seems to have a map connection which goes "
							"through %2, a door: but that doesn't seem physically "
							"possible, since the rooms on each side of %2 have "
							"been established as %3 and %4.");
						Problems::issue_problem_end();
					}
				}
			}
		}

@<Ensure that no door uses both map connections and other side@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if ((PL::Map::object_is_a_door(I)) &&
			(PF_I(map, I)->map_connection_a) &&
			(PF_I(map, I)->map_connection_b) &&
			(World::Inferences::get_prop_state(
				Instances::as_subject(I), P_other_side)))
				StandardProblems::object_problem(_p_(PM_BothWaysDoor),
					I, "seems to be a door whose connections have been given in both "
					"of the alternative ways at once",
					"by directly giving its map connections (the normal way to set up "
					"a two-sided door) and also by saying what is through it (the normal "
					"way to set up a one-sided door). As a door can't be both one- and "
					"two-sided at once, I'm going to object to this.");

@ The Spatial model requires that rooms are free-standing, that is, not in, on
or part of anything else; but it knows nothing of doors. So if we are not
careful, the source text could put a door on a shelf, or make it part of a
robot, or something like that. (Testing showed, in fact, that some authors
actually wanted to do this, though the result was a horribly inconsistent
model at run-time.) This is where we apply the kill-joy rule in question:

@<Ensure that no door is present in a room to which it does not connect@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if ((PL::Map::object_is_a_door(I)) &&
			(PL::Spatial::progenitor(I)) &&
			(PL::Spatial::progenitor(I) != PF_I(map, I)->map_connection_a) &&
			(PL::Spatial::progenitor(I) != PF_I(map, I)->map_connection_b))
			StandardProblems::object_problem(_p_(PM_DoorInThirdRoom),
				I, "seems to be a door which is present in a room to which it is not connected",
				"but this is not allowed. A door must be in one or both of the rooms it is "
				"between, but not in a third place altogether.");

@ We don't need to do the following for two-sided doors since they will bypass
the object tree and use I6's |found_in| to be present in both rooms connecting
to them.

@<Place any one-sided door inside the room which connects to it@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if ((PL::Map::object_is_a_door(I)) &&
			(PF_I(map, I)->map_connection_b == NULL) &&
			(PL::Spatial::progenitor(I) == NULL))
			PL::Spatial::set_progenitor(I, PF_I(map, I)->map_connection_a, NULL);

@ At this point we know that the doors are correctly plumbed in, and all we
need to do is compile properties to implement them. See the DM4 for details
of how to compile one and two-sided doors in I6. Alternatively, take it on
trust that there is nothing surprising here.

@<Assert found-in, door-to and door-dir properties for doors@> =
	P_door = Properties::EitherOr::new_nameless(L"door");
	Properties::EitherOr::implement_as_attribute(P_door, TRUE);
	P_door_dir = Properties::Valued::new_nameless(I"door_dir", K_value);
	P_door_to = Properties::Valued::new_nameless(I"door_to", K_value);

	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		if (PL::Map::object_is_a_door(I)) {
			Properties::EitherOr::assert(
				P_door, Instances::as_subject(I), TRUE, CERTAIN_CE);
			instance *R1 = PF_I(map, I)->map_connection_a;
			instance *R2 = PF_I(map, I)->map_connection_b;
			instance *D1 = PF_I(map, I)->map_direction_a;
			instance *D2 = PF_I(map, I)->map_direction_b;
			if (R1 && R2) {
				@<Assert found-in for a two-sided door@>;
				@<Assert door-dir for a two-sided door@>;
				@<Assert door-to for a two-sided door@>;
			} else if (R1) {
				@<Assert door-dir for a one-sided door@>;
			}
		}

@ Here |found_in| is a two-entry list.

@<Assert found-in for a two-sided door@> =
	package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, Instances::package(I));
	inter_name *S = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	packaging_state save = Emit::named_array_begin(S, K_value);
	Emit::array_iname_entry(Instances::iname(R1));
	Emit::array_iname_entry(Instances::iname(R2));
	Emit::array_end(save);
	Produce::annotate_i(S, INLINE_ARRAY_IANN, 1);
	PL::Map::set_found_in(I, S);

@ Here |door_dir| is a routine looking at the current location and returning
always the way to the other room -- the one we are not in.

@<Assert door-dir for a two-sided door@> =
	door_dir_notice *notice = CREATE(door_dir_notice);
	notice->ddn_iname = Hierarchy::make_iname_in(TSD_DOOR_DIR_FN_HL, Instances::package(I));
	notice->door = I;
	notice->R1 = R1;
	notice->D1 = D1;
	notice->D2 = D2;
	Properties::Valued::assert(P_door_dir, Instances::as_subject(I),
		Rvalues::from_iname(notice->ddn_iname), CERTAIN_CE);

@ Here |door_to| is a routine looking at the current location and returning
always the other room -- the one we are not in.

@<Assert door-to for a two-sided door@> =
	door_to_notice *notice = CREATE(door_to_notice);
	notice->dtn_iname = Hierarchy::make_iname_in(TSD_DOOR_TO_FN_HL, Instances::package(I));
	notice->door = I;
	notice->R1 = R1;
	notice->R2 = R2;
	Properties::Valued::assert(P_door_to, Instances::as_subject(I),
		Rvalues::from_iname(notice->dtn_iname), CERTAIN_CE);

@ The reversal of direction here looks peculiar, but is correct. Suppose
the Drainage Room contains a one-sided door called the iron grating, and
the iron grating is east of the Drainage Room. To get through, the player
will type EAST. But that means the iron grating has one exit, west to the
Drainage Room; so Inform looks at this exit, reverses west to east, and
compiles east into the |door_dir| property.

As for what lies beyond the iron grating, that's stored in the "other side"
property for the door; "other side" is an alias for |door_to|, which is
why we don't need to compile |door_to| here.

@<Assert door-dir for a one-sided door@> =
	instance *backwards = PL::Map::get_value_of_opposite_property(D1);
	if (backwards)
		Properties::Valued::assert(P_door_dir, Instances::as_subject(I),
			Rvalues::from_iname(Instances::emitted_iname(backwards)), CERTAIN_CE);

@h Redeeming those notices.

=
void PL::Map::write_door_dir_routines(void) {
	door_dir_notice *notice;
	LOOP_OVER(notice, door_dir_notice) {
		packaging_state save = Routines::begin(notice->ddn_iname);
		local_variable *loc = LocalVariables::add_internal_local_c(I"loc", "room of actor");
		inter_symbol *loc_s = LocalVariables::declare_this(loc, FALSE, 8);
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, loc_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LOCATION_HL));
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(THEDARK_HL));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, loc_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(REAL_LOCATION_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, Instances::iname(notice->R1));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value,
						Instances::iname(PL::Map::get_value_of_opposite_property(notice->D1)));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value,
				Instances::iname(PL::Map::get_value_of_opposite_property(notice->D2)));
		Produce::up(Emit::tree());

		Routines::end(save);
	}
}

void PL::Map::write_door_to_routines(void) {
	door_to_notice *notice;
	LOOP_OVER(notice, door_to_notice) {
		packaging_state save = Routines::begin(notice->dtn_iname);
		local_variable *loc = LocalVariables::add_internal_local_c(I"loc", "room of actor");
		inter_symbol *loc_s = LocalVariables::declare_this(loc, FALSE, 8);
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, loc_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LOCATION_HL));
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(THEDARK_HL));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, loc_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(REAL_LOCATION_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, Instances::iname(notice->R1));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Instances::iname(notice->R2));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Instances::iname(notice->R1));
		Produce::up(Emit::tree());

		Routines::end(save);
	}
}

@h Indexing.

=
int PL::Map::map_add_to_World_index(OUTPUT_STREAM, instance *O) {
	if ((O) && (Instances::of_kind(O, K_room))) {
		PL::SpatialMap::index_room_connections(OUT, O);
	}
	return FALSE;
}

int PL::Map::map_annotate_in_World_index(OUTPUT_STREAM, instance *O) {
	if ((O) && (Instances::of_kind(O, K_door))) {
		instance *A = NULL, *B = NULL;
		PL::Map::get_door_data(O, &A, &B);
		if ((A) && (B)) WRITE(" - <i>door to ");
		else WRITE(" - <i>one-sided door to ");
		instance *X = A;
		if (A == indexing_room) X = B;
		if (X == NULL) {
			parse_node *S = World::Inferences::get_prop_state(
				Instances::as_subject(O), P_other_side);
			X = Rvalues::to_object_instance(S);
		}
		if (X == NULL) WRITE("nowhere");
		else Instances::index_name(OUT, X);
		WRITE("</i>");
		return TRUE;
	}
	return FALSE;
}
