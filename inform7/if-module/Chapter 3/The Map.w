[Map::] The Map.

A plugin to provide a geographical model, linking rooms and doors
together in oppositely-paired directions.

@h Introduction.
The map is a complicated data structure, both because it amounts to a
ternary relation (though being implemented by many binary ones) and because
of an ambiguity: a map connection from a room R can lead to another room S,
to a door, or to nothing. Doors come in two sorts, one and two-sided, and
checking the physical realism of all this means we need to produce many
quite specific problem messages.

=
void Map::start(void) {
	Map::create_inference();
	PluginManager::plug(MAKE_SPECIAL_MEANINGS_PLUG, Map::make_special_meanings);
	PluginManager::plug(NEW_ASSERTION_NOTIFY_PLUG, Map::look_for_direction_creation);
	PluginManager::plug(NEW_BASE_KIND_NOTIFY_PLUG, Map::new_base_kind_notify);
	PluginManager::plug(NEW_SUBJECT_NOTIFY_PLUG, Map::new_subject_notify);
	PluginManager::plug(SET_KIND_NOTIFY_PLUG, Map::set_kind_notify);
	PluginManager::plug(SET_SUBKIND_NOTIFY_PLUG, Map::set_subkind_notify);
	PluginManager::plug(ACT_ON_SPECIAL_NPS_PLUG, Map::act_on_special_NPs);
	PluginManager::plug(CHECK_GOING_PLUG, Map::check_going);
	PluginManager::plug(COMPLETE_MODEL_PLUG, Map::complete_model);
	PluginManager::plug(NEW_PROPERTY_NOTIFY_PLUG, Map::new_property_notify);
	PluginManager::plug(INFERENCE_DRAWN_NOTIFY_PLUG, Map::inference_drawn);
	PluginManager::plug(INTERVENE_IN_ASSERTION_PLUG, Map::intervene_in_assertion);
	PluginManager::plug(ADD_TO_WORLD_INDEX_PLUG, IXMap::add_to_World_index);
	PluginManager::plug(ANNOTATE_IN_WORLD_INDEX_PLUG, IXMap::annotate_in_World_index);
	PluginManager::plug(PRODUCTION_LINE_PLUG, Map::production_line);
}

int Map::production_line(int stage, int debugging, stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(RTMap::compile_model_tables);
		BENCH(RTMap::write_door_dir_routines);
		BENCH(RTMap::write_door_to_routines);
	}
	return FALSE;
}

@ This special sentence is used as a hint in making map documents; it has no
effect on the world model itself, and so is dealt with elsewhere, in //EPS Map//.

=
int Map::make_special_meanings(void) {
	SpecialMeanings::declare(PL::EPSMap::index_map_with_SMF, I"index-map-with", 4);
	return FALSE;
}

@ Though it isn't implemented as a special meaning, we do look by hand early
in Inform's run for sentences in the form "X is a direction", so that they can
be "noticed". We need to do that in order to make sense of subsequent sentences
using directions to imply relations, as in "East of Eden is the Land of Nod."

=
parse_node *directions_noticed[MAX_DIRECTIONS];
binary_predicate *direction_relations_noticed[MAX_DIRECTIONS];
int no_directions_noticed = 0;

int Map::look_for_direction_creation(parse_node *pn) {
	if (Node::get_type(pn) != SENTENCE_NT) return FALSE;
	if ((pn->down == NULL) || (pn->down->next == NULL) || (pn->down->next->next == NULL))
		return FALSE;
	if (Node::get_type(pn->down) != VERB_NT) return FALSE;
	if (Node::get_type(pn->down->next) != UNPARSED_NOUN_NT) return FALSE;
	if (Node::get_type(pn->down->next->next) != UNPARSED_NOUN_NT) return FALSE;
	current_sentence = pn;
	pn = pn->down->next;
	if (!((<notable-map-kinds>(Node::get_text(pn->next))) && (<<r>> == 0))) return FALSE;
	if (no_directions_noticed >= MAX_DIRECTIONS) {
		StandardProblems::limit_problem(Task::syntax_tree(), _p_(PM_TooManyDirections),
			"different directions", MAX_DIRECTIONS);
		return FALSE;
	}
	direction_relations_noticed[no_directions_noticed] =
		PL::MapDirections::create_sketchy_mapping_direction(Node::get_text(pn));
	directions_noticed[no_directions_noticed++] = pn;
	return FALSE;
}

@h The direction inference.
While we could probably represent map knowledge using relation inferences
in connection with the "mapped D of" relations, it's altogether easier and
makes for more legible code if we use a special inference family of our own:

= (early code)
inference_family *direction_inf = NULL; /* 100; where do map connections from O lead? */

@ =
void Map::create_inference(void) {
	direction_inf = Inferences::new_family(I"direction_inf");
	METHOD_ADD(direction_inf, LOG_DETAILS_INF_MTID, Map::log_direction_inf);
	METHOD_ADD(direction_inf, COMPARE_INF_MTID, Map::cmp_direction_inf);
}

typedef struct direction_inference_data {
	struct inference_subject *to;
	struct inference_subject *dir;
	CLASS_DEFINITION
} direction_inference_data;

inference *Map::new_direction_inference(inference_subject *infs_from,
	inference_subject *infs_to, instance *o_dir) {
	PROTECTED_MODEL_PROCEDURE;
	direction_inference_data *data = CREATE(direction_inference_data);
	data->to = infs_to;
	data->dir = (o_dir)?(Instances::as_subject(o_dir)):NULL;
	return Inferences::create_inference(direction_inf,
		STORE_POINTER_direction_inference_data(data), prevailing_mood);
}

void Map::infer_direction(inference_subject *infs_from, inference_subject *infs_to,
	instance *o_dir) { 
	inference *i = Map::new_direction_inference(infs_from, infs_to, o_dir);
	Inferences::join_inference(i, infs_from);
}

void Map::log_direction_inf(inference_family *f, inference *inf) {
	direction_inference_data *data = RETRIEVE_POINTER_direction_inference_data(inf->data);
	LOG("-to:$j -dir:$j", data->to, data->dir);
}

@ Inferences about different directions from a location are different topics;
but different destinations in the same direction are different in content.

=
int Map::cmp_direction_inf(inference_family *f, inference *i1, inference *i2) {
	direction_inference_data *data1 = RETRIEVE_POINTER_direction_inference_data(i1->data);
	direction_inference_data *data2 = RETRIEVE_POINTER_direction_inference_data(i2->data);

	int c = Inferences::measure_infs(data1->dir) - Inferences::measure_infs(data2->dir);
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;
	c = Inferences::measure_infs(data1->to) - Inferences::measure_infs(data2->to);
	if (c > 0) return CI_DIFFER_IN_CONTENT; if (c < 0) return -CI_DIFFER_IN_CONTENT;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

void Map::get_map_references(inference *i,
	inference_subject **infs1, inference_subject **infs2) {
	if ((i == NULL) || (i->family != direction_inf))
		internal_error("not a direction inf");
	direction_inference_data *data = RETRIEVE_POINTER_direction_inference_data(i->data);
	if (infs1) *infs1 = data->to; if (infs2) *infs2 = data->dir;
}

@h Special kinds.
It's obvious why the kinds direction and door are special.

= (early code)
kind *K_direction = NULL;
kind *K_door = NULL;

@ These are recognised by the English name when defined by the Standard
Rules. (So there is no need to translate this to other languages.)

=
<notable-map-kinds> ::=
	direction |
	door

@ =
int Map::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
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
int Map::set_subkind_notify(kind *sub, kind *super) {
	if ((sub == K_direction) && (super != K_object)) {
		if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DirectionAdrift),
				"'direction' is not allowed to be a kind of anything (other than "
				"'object')",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	if (super == K_direction) {
		if (problem_count == 0)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DirectionSubkinded),
				"'direction' is not allowed to have more specific kinds",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	if ((K_backdrop) && (sub == K_door) &&
		(Kinds::Behaviour::is_object_of_kind(super, K_backdrop))) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_DoorAdrift),
				"'door' is not allowed to be a kind of 'backdrop'",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	if ((K_backdrop) && (sub == K_backdrop) &&
		(Kinds::Behaviour::is_object_of_kind(super, K_door))) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_BackdropAdrift),
				"'backdrop' is not allowed to be a kind of 'door'",
				"because it's too fundamental to the way Inform maps out the "
				"geography of the physical world.");
		return TRUE;
	}
	return FALSE;
}

@h Spotting directions and doors.

=
int Map::subject_is_a_direction(inference_subject *infs) {
	if (K_direction == NULL) return FALSE; /* in particular, if plugin inactive */
	return InferenceSubjects::is_within(infs, KindSubjects::from_kind(K_direction));
}

int Map::instance_is_a_direction(instance *I) {
	if ((PluginManager::active(map_plugin)) && (K_direction) && (I) &&
		(Instances::of_kind(I, K_direction)))
		return TRUE;
	return FALSE;
}

@ =
int Map::subject_is_a_door(inference_subject *infs) {
	return Map::instance_is_a_door(
		InstanceSubjects::to_object_instance(infs));
}

int Map::instance_is_a_door(instance *I) {
	if ((PluginManager::active(map_plugin)) && (K_door) && (I) &&
		(Instances::of_kind(I, K_door)))
		return TRUE;
	return FALSE;
}

@h Directions and their numbers.
Directions play a special role because sentences like "east of the treehouse
is the garden" are parsed differently from sentences like "the nearby place
property of the treehouse is the garden".

For reasons to do with creating direction mapping relations, the lengths of
direction names are capped, though very, very few Inform users have ever
realised this:

@d MAX_WORDS_IN_DIRECTION (MAX_WORDS_IN_ASSEMBLAGE - 4)

@ When a new direction comes into existence (i.e., not when the underlying
instance |I| is created, but when its kind is realised to be "direction"),
we will assign it a number:

=
int registered_directions = 0; /* next direction number to be free */

int Map::number_of_directions(void) {
	return registered_directions;
}

@ "Up" and "down" are not really special among possible direction instances, but
they have linguistic features not shared by lateral directions. "Above the
garden is the treehouse", for instance, does not directly refer to either
direction, but implies both.

=
instance *I_up = NULL;
instance *I_down = NULL;

@ These are recognised by their English names when defined by the Standard Rules.
(So there is no need to translate this to other languages.)

=
<notable-map-directions> ::=
	up |
	down

@ =
int Map::set_kind_notify(instance *I, kind *k) {
	kind *kw = Instances::to_kind(I);
	if ((!(Kinds::Behaviour::is_object_of_kind(kw, K_direction))) &&
		(Kinds::Behaviour::is_object_of_kind(k, K_direction))) {
		wording IW = Instances::get_name(I, FALSE);
		@<Vet the direction name for acceptability@>;
		if (<notable-map-directions>(IW)) {
			switch (<<r>>) {
				case 0: I_up = I; break;
				case 1: I_down = I; break;
			}
		}
		Naming::object_takes_definite_article(Instances::as_subject(I));
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
	inter_name *dname = RTMap::new_direction_iname();
	MAP_DATA(I)->direction_iname = dname;
	PL::MapDirections::make_mapped_predicate(I);

@h Map data on instances.
We will use quite a lot of temporary work-space to put all of this together,
but the details can be ignored. If we expected very large numbers of instances
then it would be worth economising here, but profiling suggests that it really
isn't.

@d MAP_DATA(I) PLUGIN_DATA_ON_INSTANCE(map, I)

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

@ =
int Map::new_subject_notify(inference_subject *subj) {
	map_data *md = CREATE(map_data);
	md->map_connection_a = NULL; md->map_connection_b = NULL;
	md->map_direction_a = NULL; md->map_direction_b = NULL;

	md->direction_index = -1;
	md->direction_relation = NULL;
	md->direction_iname = NULL;

	for (int i=0; i<MAX_DIRECTIONS; i++) {
		md->exits_set_at[i] = NULL;
		md->exits[i] = NULL;
	}

	PL::SpatialMap::initialise_mapping_data(md);
	ATTACH_PLUGIN_DATA_TO_SUBJECT(map, subj, md);
	return FALSE;
}

@ Special properties. 
These are property names to do with mapping which Inform provides special
support for. Two are visible to I7 authors, and the others are low-level
properties needed for the run-time implementation.

= (early code)
property *P_other_side = NULL; /* a value property for the other side of a door */
property *P_opposite = NULL; /* a value property for the reverse of a direction */

property *P_door = NULL; /* Inter only */
property *P_door_dir = NULL; /* Inter only */
property *P_door_to = NULL; /* Inter only */
property *P_room_index = NULL; /* Inter only: workspace for path-finding through the map */
property *P_found_in = NULL; /* Inter only: needed for multiply-present objects */

@ We recognise these by their English names when they are defined by the
Standard Rules. (So there is no need to translate this to other languages.)

=
<notable-map-properties> ::=
	opposite |
	other side

@ =
int Map::new_property_notify(property *prn) {
	if (<notable-map-properties>(prn->name)) {
		switch (<<r>>) {
			case 0: P_opposite = prn; break;
			case 1: P_other_side = prn; break;
		}
	}
	return FALSE;
}

@ The following is used also by //Backdrops//, since both plugins use a
shared Inter-level property at run-time. But this function will work even if
the map plugin is inactive; so you can still have backdrops without a map.

=
void Map::set_found_in(instance *I, parse_node *val) {
	if (P_found_in == NULL)
		P_found_in = ValueProperties::new_nameless(I"found_in",
			K_value);
	if (PropertyInferences::value_of(
		Instances::as_subject(I), P_found_in))
			internal_error("rival found_in interpretations");
	ValueProperties::assert(P_found_in, Instances::as_subject(I), val, CERTAIN_CE);
}

@ This utility returns the "opposite" property for a direction, which is
always another direction: for example, the opposite of northwest is southeast.

=
instance *Map::get_value_of_opposite_property(instance *I) {
	parse_node *val = PropertyInferences::value_of(
		Instances::as_subject(I), P_opposite);
	if (val) return Rvalues::to_object_instance(val);
	return NULL;
}

@h The exits array.
The bulk of the map is stored in the arrays called |exits|, which hold the
map connections fanning out from each room. The direction numbers carefully
noted above are keys into these arrays.

It might look a little wasteful of I7's memory to expand the direction
inferences, a nicely compact representation, into large and sparse arrays.
But it's convenient, and profiling suggests that the memory overhead is not
significant. It also means that the //Spatial Map// mapping code, which contains
quite crunchy algorithms, has the fastest possible access to the layout.

@d MAP_EXIT(X, Y) MAP_DATA(X)->exits[Y]

=
void Map::build_exits_array(void) {
	instance *I;
	int d = 0;
	LOOP_OVER_INSTANCES(I, K_object) {
		if (Kinds::Behaviour::is_object_of_kind(Instances::to_kind(I), K_direction)) {
			MAP_DATA(I)->direction_index = d++;
		}
	}
	LOOP_OVER_INSTANCES(I, K_object) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), direction_inf) {
			inference_subject *infs1, *infs2;
			Map::get_map_references(inf, &infs1, &infs2);
			instance *to = NULL, *dir = NULL;
			if (infs1) to = InstanceSubjects::to_object_instance(infs1);
			if (infs2) dir = InstanceSubjects::to_object_instance(infs2);
			if ((to) && (dir)) {
				int dn = MAP_DATA(dir)->direction_index;
				if ((dn >= 0) && (dn < MAX_DIRECTIONS)) {
					MAP_EXIT(I, dn) = to;
					MAP_DATA(I)->exits_set_at[dn] = Inferences::where_inferred(inf);
				}
			}
		}
	}
}

@h Door connectivity.
We've seen how most of the map is represented, in the |exits| arrays. The
missing information has to do with doors. If east of the Carousel Room is
the oak door, then |Map_Storage| reveals only that fact, and not what's on
the other side of the door. This will eventually be compiled into the
|door_to| property for the oak door object. In the mean time, every door
object has four pieces of data attached:

=
void Map::get_door_data(instance *door, instance **c1, instance **c2) {
	if (c1) *c1 = MAP_DATA(door)->map_connection_a;
	if (c2) *c2 = MAP_DATA(door)->map_connection_b;
}

@ We would like to deduce from a sentence like

>> The other side of the iron door is the Black Holding Area.

that the "Black Holding Area" is a room; otherwise, if it has no map
connections, Inform may well think it's just a thing. This is where that
deduction is made:

=
int Map::inference_drawn(inference *I, inference_subject *subj) {
	property *prn = PropertyInferences::get_property(I);
	if ((prn) && (prn == P_other_side)) {
		parse_node *val = PropertyInferences::get_value(I);
		instance *I = Rvalues::to_object_instance(val);
		if (I) SpatialInferences::infer_is_room(Instances::as_subject(I), CERTAIN_CE);
	}
	return FALSE;
}

@h Linguistic extras.
These NPs allow us to refer to the special directions "up" and "down":

=
<notable-map-noun-phrases> ::=
	below |
	above

@ =
int Map::act_on_special_NPs(parse_node *p) {
	if (<notable-map-noun-phrases>(Node::get_text(p))) {
		switch (<<r>>) {
			case 0:
				if (I_down) {
					Refiner::give_subject_to_noun(p, Instances::as_subject(I_down));
					return TRUE;
				}
				break;
			case 1:
				if (I_up) {
					Refiner::give_subject_to_noun(p, Instances::as_subject(I_up));
					return TRUE;
				}
				break;
		}
	}
	return FALSE;
}

@ We also add some optional clauses to the "going" action:

=
int Map::check_going(parse_node *from, parse_node *to,
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
int Map::intervene_in_assertion(parse_node *px, parse_node *py) {
	if ((Node::get_type(px) == PROPER_NOUN_NT) &&
		(Node::get_type(py) == COMMON_NOUN_NT)) {
		inference_subject *left_object = Node::get_subject(px);
		inference_subject *right_kind = Node::get_subject(py);
		if ((Map::subject_is_a_direction(left_object)) &&
			(Map::subject_is_a_direction(right_kind) == FALSE)) {
			Assertions::Creator::convert_instance_to_nounphrase(py, NULL);
			return FALSE;
		}
		if (Annotations::read_int(px, nowhere_ANNOT)) {
			Problems::Using::assertion_problem(Task::syntax_tree(),
				_p_(PM_NowhereDescribed),
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
void Map::enter_one_way_mode(void) { oneway_map_connections_only = TRUE; }
void Map::exit_one_way_mode(void) { oneway_map_connections_only = FALSE; }

@ Note that, in order to make the conjectural reverse map direction, we need
to look up the "opposite" property of the forward one. This relies on all
directions having their opposites defined before any map is built, and is the
reason for Inform's insistence that directions are always created in matched
pairs.

=
void Map::connect(inference_subject *i_from, inference_subject *i_to,
	inference_subject *i_dir) {
	instance *go_from = InstanceSubjects::to_object_instance(i_from);
	instance *go_to = InstanceSubjects::to_object_instance(i_to);
	instance *forwards_dir = InstanceSubjects::to_object_instance(i_dir);
	if (Instances::of_kind(forwards_dir, K_direction) == FALSE)
		internal_error("unknown direction");
	instance *reverse_dir = Map::get_value_of_opposite_property(forwards_dir);
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

	Map::oneway_map_connection(go_from, go_to, forwards_dir, CERTAIN_CE);
	if ((reverse_dir) && (go_to) && (oneway_map_connections_only == FALSE)) {
		if (Instances::of_kind(reverse_dir, K_direction) == FALSE) {
			Problems::quote_object(1, forwards_dir);
			Problems::quote_object(2, reverse_dir);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_OppositeNotDirection));
			Problems::issue_problem_segment(
				"I'm trying to make a map connection in the %1 direction, "
				"which means there ought to be map connection back in the "
				"opposite direction. But the opposite of %1 seems to be %2, "
				"which doesn't make sense since %2 isn't a direction. (Maybe "
				"you forgot to say that it was?)");
			Problems::issue_problem_end();
		} else Map::oneway_map_connection(go_to, go_from, reverse_dir, LIKELY_CE);
	}
}

void Map::oneway_map_connection(instance *go_from, instance *go_to,
	instance *forwards_dir, int certainty_level) {
	binary_predicate *bp = PL::MapDirections::get_mapping_relation(forwards_dir);
	if (bp == NULL) internal_error("map connection in non-direction");
	int x = prevailing_mood;
	prevailing_mood = certainty_level;
	Assert::true_about(
		Propositions::Abstract::to_set_simple_relation(bp, go_to),
		Instances::as_subject(go_from), certainty_level);
	prevailing_mood = x;
}

@h Model completion.
And here begins the fun. It's not as easy to write down the requirements for
the map as might be thought.

=
int Map::complete_model(int stage) {
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
		case 4: Map::build_exits_array(); break;
	}
	return FALSE;
}

@ Every room has a |room_index| property. It has no meaningful contents at
the start of play, and we initialise to $-1$ since this marks the route-finding
cache as being broken. (Route-finding is one of the few really time-critical
tasks at run-time, which is why we keep complicating the I7 code to
accommodate it.)

@<Give each room a room-index property as workspace for route finding@> =
	P_room_index = ValueProperties::new_nameless(I"room_index", K_number);
	parse_node *minus_one = Rvalues::from_int(-1, EMPTY_WORDING);

	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if (Spatial::object_is_a_room(I))
			ValueProperties::assert(P_room_index,
				Instances::as_subject(I), minus_one, CERTAIN_CE);

@ The following code does little if the source is correct: it mostly
checks that various mapping impossibilities do not occur.

@<Ensure that map connections are room-to-room, room-to-door or door-to-room@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), direction_inf) {
			inference_subject *infs1;
			Map::get_map_references(inf, &infs1, NULL);
			instance *to = InstanceSubjects::to_object_instance(infs1);
			if ((Spatial::object_is_a_room(I)) && (to) &&
				(Map::instance_is_a_door(to) == FALSE) &&
				(Spatial::object_is_a_room(to) == FALSE))
				StandardProblems::contradiction_problem(_p_(PM_BadMapCell),
					Instances::get_creating_sentence(to),
					Inferences::where_inferred(inf), to,
					"appears to be something which can be reached via a map "
					"connection, but it seems to be neither a room nor a door",
					"and these are the only possibilities allowed by Inform.");
			if ((Map::instance_is_a_door(I)) &&
				(Spatial::object_is_a_room(to) == FALSE))
				StandardProblems::object_problem(_p_(PM_DoorToNonRoom),
					I,
					"seems to be a door opening on something not a room",
					"but a door must connect one or two rooms (and in particular is "
					"not allowed to connect to another door).");
		}
	}

@<Ensure that every door has either one or two connections from it@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if (Map::instance_is_a_door(I)) {
			int connections_in = 0;
			inference *inf;
			parse_node *where[3];
			where[0] = NULL; where[1] = NULL; where[2] = NULL; /* to placate |gcc| */
			inference *front_side_inf = NULL, *back_side_inf = NULL;
			POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), direction_inf) {
				inference_subject *infs1, *infs2;
				Map::get_map_references(inf, &infs1, &infs2);
				instance *to = InstanceSubjects::to_object_instance(infs1);
				instance *dir = InstanceSubjects::to_object_instance(infs2);
				if (to) {
					if (connections_in == 0) {
						MAP_DATA(I)->map_connection_a = to;
						MAP_DATA(I)->map_direction_a = dir;
						where[0] = Inferences::where_inferred(inf);
						front_side_inf = inf;
					}
					if (connections_in == 1) {
						MAP_DATA(I)->map_connection_b = to;
						MAP_DATA(I)->map_direction_b = dir;
						where[1] = Inferences::where_inferred(inf);
						back_side_inf = inf;
					}
					if (connections_in == 2) {
						where[2] = Inferences::where_inferred(inf);
					}
					connections_in++;
				}
			}
			if ((front_side_inf) && (back_side_inf)) {
				if (front_side_inf->allocation_id > back_side_inf->allocation_id) {
					instance *X = MAP_DATA(I)->map_connection_a;
					MAP_DATA(I)->map_connection_a = MAP_DATA(I)->map_connection_b;
					MAP_DATA(I)->map_connection_b = X;
					X = MAP_DATA(I)->map_direction_a;
					MAP_DATA(I)->map_direction_a = MAP_DATA(I)->map_direction_b;
					MAP_DATA(I)->map_direction_b = X;
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
	LOOP_OVER_INSTANCES(I, K_object)
		if (Spatial::object_is_a_room(I)) {
			inference *inf;
			POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), direction_inf) {
				inference_subject *infs1;
				Map::get_map_references(inf, &infs1, NULL);
				instance *to = InstanceSubjects::to_object_instance(infs1);
				if (Map::instance_is_a_door(to)) {
					instance *exit1 = MAP_DATA(to)->map_connection_a;
					instance *exit2 = MAP_DATA(to)->map_connection_b;
					if ((I != exit1) && (exit2 == NULL)) {
						Problems::quote_object(1, I);
						Problems::quote_object(2, to);
						Problems::quote_object(3, exit1);
						StandardProblems::handmade_problem(Task::syntax_tree(),
							_p_(PM_RoomTwistyDoor));
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
						StandardProblems::handmade_problem(Task::syntax_tree(),
							_p_(PM_RoomMissingDoor));
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
	LOOP_OVER_INSTANCES(I, K_object)
		if ((Map::instance_is_a_door(I)) &&
			(MAP_DATA(I)->map_connection_a) &&
			(MAP_DATA(I)->map_connection_b) &&
			(PropertyInferences::value_of(
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
	LOOP_OVER_INSTANCES(I, K_object)
		if ((Map::instance_is_a_door(I)) &&
			(Spatial::progenitor(I)) &&
			(Spatial::progenitor(I) != MAP_DATA(I)->map_connection_a) &&
			(Spatial::progenitor(I) != MAP_DATA(I)->map_connection_b))
			StandardProblems::object_problem(_p_(PM_DoorInThirdRoom),
				I, "seems to be a door which is present in a room to which it is not connected",
				"but this is not allowed. A door must be in one or both of the rooms it is "
				"between, but not in a third place altogether.");

@ We don't need to do the following for two-sided doors since they will bypass
the object tree and use I6's |found_in| to be present in both rooms connecting
to them.

@<Place any one-sided door inside the room which connects to it@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if ((Map::instance_is_a_door(I)) &&
			(MAP_DATA(I)->map_connection_b == NULL) &&
			(Spatial::progenitor(I) == NULL))
			Spatial::set_progenitor(I, MAP_DATA(I)->map_connection_a, NULL);

@ At this point we know that the doors are correctly plumbed in, and all we
need to do is compile properties to implement them. See the DM4 for details
of how to compile one and two-sided doors in I6. Alternatively, take it on
trust that there is nothing surprising here.

@<Assert found-in, door-to and door-dir properties for doors@> =
	P_door = EitherOrProperties::new_nameless(L"door");
	RTProperties::implement_as_attribute(P_door, TRUE);
	P_door_dir = ValueProperties::new_nameless(I"door_dir", K_value);
	P_door_to = ValueProperties::new_nameless(I"door_to", K_value);

	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if (Map::instance_is_a_door(I)) {
			EitherOrProperties::assert(
				P_door, Instances::as_subject(I), TRUE, CERTAIN_CE);
			instance *R1 = MAP_DATA(I)->map_connection_a;
			instance *R2 = MAP_DATA(I)->map_connection_b;
			instance *D1 = MAP_DATA(I)->map_direction_a;
			instance *D2 = MAP_DATA(I)->map_direction_b;
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
	parse_node *val = RTMap::found_in_for_2_sided(I, R1, R2);
	Map::set_found_in(I, val);

@ Here |door_dir| is a routine looking at the current location and returning
always the way to the other room -- the one we are not in.

@<Assert door-dir for a two-sided door@> =
	parse_node *val = RTMap::door_dir_for_2_sided(I, R1, D1, D2);
	ValueProperties::assert(P_door_dir, Instances::as_subject(I), val, CERTAIN_CE);

@ Here |door_to| is a routine looking at the current location and returning
always the other room -- the one we are not in.

@<Assert door-to for a two-sided door@> =
	parse_node *val = RTMap::door_to_for_2_sided(I, R1, R2);
	ValueProperties::assert(P_door_to, Instances::as_subject(I), val, CERTAIN_CE);

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
	instance *backwards = Map::get_value_of_opposite_property(D1);
	if (backwards)
		ValueProperties::assert(P_door_dir, Instances::as_subject(I),
			Rvalues::from_iname(RTInstances::emitted_iname(backwards)), CERTAIN_CE);
