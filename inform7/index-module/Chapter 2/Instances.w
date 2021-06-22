[IXInstances::] Instances.

To index instances.

@
		
@d LOOP_OVER_ROOMS(R)
	LOOP_OVER(R, faux_instance)
		if (R->is_a_room)
@d LOOP_OVER_REGIONS(R)
	LOOP_OVER(R, faux_instance)
		if (R->is_a_region)
@d LOOP_OVER_DIRECTIONS(R)
	LOOP_OVER(R, faux_instance)
		if (R->is_a_direction)
@d LOOP_OVER_BACKDROPS(R)
	LOOP_OVER(R, faux_instance)
		if (R->is_a_backdrop)
@d LOOP_OVER_OBJECTS(R)
	LOOP_OVER(R, faux_instance)

=
typedef struct faux_instance {
	int index_appearances; /* how many times have I appeared thus far in the World index? */
	struct text_stream *name;
	struct text_stream *printed_name;
	struct text_stream *abbrev;
	struct instance *original;
	int is_a_thing;
	int is_a_supporter;
	int is_a_person;
	int is_a_room;
	int is_a_door;
	int is_a_region;
	int is_a_direction;
	int is_a_backdrop;
	int is_everywhere;
	int is_worn;
	int is_a_part;
	int specify_kind;
	int direction_index;
	int direction_number;
	struct linked_list *backdrop_presences; /* of |faux_instance| */
	struct faux_instance *region_enclosing;
	struct faux_instance *next_room_in_submap;
	struct faux_instance *opposite_direction;
	struct faux_instance *object_tree_sibling;
	struct faux_instance *object_tree_child;
	struct faux_instance *progenitor;
	struct faux_instance *incorp_tree_sibling;
	struct faux_instance *incorp_tree_child;
	struct faux_instance *other_side;
	struct text_stream *kind_text;
	struct text_stream *kind_chain;
	struct text_stream *anchor_text;
	int created_at;
	int kind_set_at;
	int region_set_at;
	int progenitor_set_at;
	struct linked_list *usages; /* of |parse_node| */
		
	#ifdef CORE_MODULE
	inference_subject *knowledge;
	#endif
	
	struct fi_map_data fimd;
	CLASS_DEFINITION
} faux_instance;

typedef struct fi_map_data {
	struct connected_submap *submap;
	struct vector position;
	struct vector saved_gridpos;
	int cooled;
	int shifted;
	int zone;
	wchar_t *colour; /* an HTML colour for the room square (rooms only) */
	wchar_t *text_colour; /* an HTML colour for text on that square */
	int eps_x, eps_y;
	struct faux_instance *map_connection_a;
	struct faux_instance *map_connection_b;
	int exit_lengths[MAX_DIRECTIONS];
	struct faux_instance *spatial_relationship[MAX_DIRECTIONS];
	struct faux_instance *exits[MAX_DIRECTIONS];
	struct faux_instance *lock_exits[MAX_DIRECTIONS];
	int exits_set_at[MAX_DIRECTIONS];
	struct map_parameter_scope local_map_parameters; /* temporary: used in EPS mapping */
} fi_map_data;

fi_map_data IXInstances::new_fimd(faux_instance *FI) {
	fi_map_data fimd;
	fimd.submap = NULL;
	fimd.position = Zero_vector;
	fimd.saved_gridpos = Zero_vector;
	fimd.cooled = FALSE;
	fimd.shifted = FALSE;
	fimd.zone = 0;
	fimd.colour = NULL;
	fimd.eps_x = 0;
	fimd.eps_y = 0;
	fimd.map_connection_a = NULL;
	fimd.map_connection_b = NULL;
	for (int i=0; i<MAX_DIRECTIONS; i++) {
		fimd.exit_lengths[i] = 0;
		fimd.exits[i] = NULL;
		fimd.lock_exits[i] = NULL;
		fimd.spatial_relationship[i] = NULL;
		fimd.exits_set_at[i] = -1;
	}
	EPSMap::prepare_map_parameter_scope(&(fimd.local_map_parameters));
	return fimd;
}

@ When names are abbreviated for use on the World Index map (for instance,
"Marble Hallway" becomes "MH") each word is tested against the following
nonterminal; those which match are omitted. So, for instance, "Queen Of The
South" comes out as "QS".

@d ABBREV_ROOMS_TO 2

=
<map-name-abbreviation-omission-words> ::=
	in |
	of |
	<article>

@<Compose the abbreviated name@> =
	wording W = Instances::get_name(I, FALSE);
	if (Wordings::nonempty(W)) {
		int c = 0;
		LOOP_THROUGH_WORDING(i, W) {
			if ((i > Wordings::first_wn(W)) && (i < Wordings::last_wn(W)) &&
				(<map-name-abbreviation-omission-words>(Wordings::one_word(i)))) continue;
			wchar_t *p = Lexer::word_raw_text(i);
			if (c++ < ABBREV_ROOMS_TO) PUT_TO(FI->abbrev, Characters::toupper(p[0]));
		}
		LOOP_THROUGH_WORDING(i, W) {
			if ((i > Wordings::first_wn(W)) && (i < Wordings::last_wn(W)) &&
				(<map-name-abbreviation-omission-words>(Wordings::one_word(i)))) continue;
			wchar_t *p = Lexer::word_raw_text(i);
			for (int j=1; p[j]; j++)
				if (Characters::vowel(p[j]) == FALSE)
					if (c++ < ABBREV_ROOMS_TO) PUT_TO(FI->abbrev, p[j]);
			if ((c++ < ABBREV_ROOMS_TO) && (p[1])) PUT_TO(FI->abbrev, p[1]);
		}
	}

@ =
faux_instance *start_faux_instance = NULL;
faux_instance *faux_yourself = NULL;
faux_instance *faux_benchmark = NULL;

void IXInstances::make_faux(void) {
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object) {
		faux_instance *FI = CREATE(faux_instance);
		FI->index_appearances = 0;
		FI->name = Str::new();
		Instances::write_name(FI->name, I);
		FI->abbrev = Str::new();
		@<Compose the abbreviated name@>;
		
		FI->original = I;
		FI->is_a_thing = Instances::of_kind(I, K_thing);
		FI->is_a_supporter = Instances::of_kind(I, K_supporter);
		FI->is_a_person = Instances::of_kind(I, K_person);
		FI->is_a_room = Spatial::object_is_a_room(I);
		FI->is_a_door = Map::instance_is_a_door(I);
		FI->is_a_region = Regions::object_is_a_region(I);
		FI->is_a_direction = Map::object_is_a_direction(I);
		FI->is_a_backdrop = Backdrops::object_is_a_backdrop(I);
		FI->is_everywhere = FALSE;
		FI->is_worn = FALSE;
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), property_inf)
			if (PropertyInferences::get_property(inf) == P_worn)
				FI->is_worn = TRUE;
		FI->is_a_part = SPATIAL_DATA(I)->part_flag;
		FI->backdrop_presences = NEW_LINKED_LIST(faux_instance);
		FI->region_enclosing = NULL;
		FI->next_room_in_submap = NULL;
		FI->opposite_direction = NULL;
		FI->object_tree_sibling = NULL;
		FI->object_tree_child = NULL;
		FI->progenitor = NULL;
		FI->incorp_tree_sibling = NULL;
		FI->incorp_tree_child = NULL;
		FI->direction_index = MAP_DATA(I)->direction_index;
		FI->direction_number = InstanceCounting::IK_count(I, K_direction);
		kind *k = Instances::to_kind(I);
		FI->specify_kind = TRUE;
		if (Kinds::eq(k, K_thing)) FI->specify_kind = FALSE;
		if (Kinds::eq(k, K_room)) FI->specify_kind = FALSE;
		FI->other_side = NULL;
		FI->kind_text = Str::new();
		wording W = Kinds::Behaviour::get_name_in_play(k, FALSE,
			Projects::get_language_of_play(Task::project()));
		WRITE_TO(FI->kind_text, "%+W", W);
		FI->kind_chain = Str::new();
		kind *IK = Instances::to_kind(I);
		int i = 0;
		while ((IK != K_object) && (IK)) {
			i++;
			IK = Latticework::super(IK);
		}
		for (int j=i-1; j>=0; j--) {
			int k; IK = Instances::to_kind(I);
			for (k=0; k<j; k++) IK = Latticework::super(IK);
			if (j != i-1) WRITE_TO(FI->kind_chain, " &gt; ");
			wording W = Kinds::Behaviour::get_name(IK, FALSE);
			WRITE_TO(FI->kind_chain, "%+W", W);
		}
		noun *nt = Instances::get_noun(I);
		FI->anchor_text = Str::duplicate(NounIdentifiers::identifier(nt));
		parse_node *C = Instances::get_creating_sentence(I);
		if (C) FI->created_at = Wordings::first_wn(Node::get_text(C));
		else FI->created_at = -1;
		C = Instances::get_kind_set_sentence(I);
		if (C) FI->kind_set_at = Wordings::first_wn(Node::get_text(C));
		else FI->kind_set_at = -1;
		C = SPATIAL_DATA(I)->progenitor_set_at;
		if (C) FI->progenitor_set_at = Wordings::first_wn(Node::get_text(C));
		else FI->progenitor_set_at = -1;
		FI->region_set_at = -1;
		C = REGIONS_DATA(I)->in_region_set_at;
		if (C) FI->region_set_at = Wordings::first_wn(Node::get_text(C));
		FI->usages = I->compilation_data.usages;
		
		FI->fimd = IXInstances::new_fimd(FI);
		FI->fimd.colour = MAP_DATA(I)->world_index_colour;
		FI->fimd.text_colour = MAP_DATA(I)->world_index_text_colour;
		FI->fimd.eps_x = MAP_DATA(I)->eps_x;
		FI->fimd.eps_y = MAP_DATA(I)->eps_y;
		for (int i=0; i<MAX_DIRECTIONS; i++) {
			parse_node *at = MAP_DATA(I)->exits_set_at[i];
			if (at) FI->fimd.exits_set_at[i] = Wordings::first_wn(Node::get_text(at));
		}
	
		if (I == I_yourself) faux_yourself = FI;
		if (I == Spatial::get_benchmark_room()) faux_benchmark = FI;
		if (I == Player::get_start_room()) start_faux_instance = FI;
		
		TEMPORARY_TEXT(pname)
		parse_node *V = PropertyInferences::value_and_where(
			Instances::as_subject(I), P_printed_name, NULL);
		if ((Rvalues::is_CONSTANT_of_kind(V, K_text)) &&
			(Wordings::nonempty(Node::get_text(V)))) {
			int wn = Wordings::first_wn(Node::get_text(V));
			WRITE_TO(pname, "%+W", Wordings::one_word(wn));
			if (Str::get_first_char(pname) == '\"') Str::delete_first_character(pname);
			if (Str::get_last_char(pname) == '\"') Str::delete_last_character(pname);
		}
		FI->printed_name = Str::duplicate(pname);
		DISCARD_TEXT(pname)
		#ifdef CORE_MODULE
		FI->knowledge = Instances::as_subject(I);
		#endif
	}
	faux_instance *FB;
	LOOP_OVER(FB, faux_instance) {
		if (FB->is_a_backdrop) {
			instance *B = FB->original;
			inference *inf;
			POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(B), found_in_inf) {
				instance *L = Backdrops::get_inferred_location(inf);
				faux_instance *FL = IXInstances::fi(L);
				ADD_TO_LINKED_LIST(FB, faux_instance, FL->backdrop_presences);
			}
			POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(B), found_everywhere_inf) {
				FB->is_everywhere = TRUE;
			}
		}
		for (int i=0; i<MAX_DIRECTIONS; i++) {
			FB->fimd.exits[i] = IXInstances::fi(MAP_EXIT(FB->original, i));
		}
	}
	LOOP_OVER(FB, faux_instance) {
		FB->region_enclosing = IXInstances::fi(Regions::enclosing(FB->original));
		FB->object_tree_sibling = IXInstances::fi(SPATIAL_DATA(FB->original)->object_tree_sibling);
		FB->object_tree_child = IXInstances::fi(SPATIAL_DATA(FB->original)->object_tree_child);
		FB->progenitor = IXInstances::fi(Spatial::progenitor(FB->original));
		FB->incorp_tree_sibling = IXInstances::fi(SPATIAL_DATA(FB->original)->incorp_tree_sibling);
		FB->incorp_tree_child = IXInstances::fi(SPATIAL_DATA(FB->original)->incorp_tree_child);
	}
	faux_instance *FR;
	LOOP_OVER(FR, faux_instance)
		if (FR->is_a_direction) {
			FR->opposite_direction = IXInstances::fi(Map::get_value_of_opposite_property(FR->original));
		}
	faux_instance *FD;
	LOOP_OVER(FD, faux_instance)
		if (FD->is_a_door) {
			parse_node *S = PropertyInferences::value_of(
				Instances::as_subject(I), P_other_side);
			FD->other_side = IXInstances::fi(Rvalues::to_object_instance(S));
			FD->fimd.map_connection_a = IXInstances::fi(MAP_DATA(FD->original)->map_connection_a);
			FD->fimd.map_connection_b = IXInstances::fi(MAP_DATA(FD->original)->map_connection_b);
		}
	IXInstances::decode_hints(1);
}

void IXInstances::decode_hints(int pass) {
	mapping_hint *hint;
	LOOP_OVER(hint, mapping_hint) {
		if ((hint->dir) && (hint->as_dir)) {
			if (pass == 1)
				story_dir_to_page_dir[MAP_DATA(hint->dir)->direction_index] =
					MAP_DATA(hint->as_dir)->direction_index;
		} else if ((hint->from) && (hint->dir)) {
			if (pass == 1)
				PL::SpatialMap::lock_exit_in_place(IXInstances::fi(hint->from),
					MAP_DATA(hint->dir)->direction_index, IXInstances::fi(hint->to));
		} else if (hint->name) {
			if (hint->scope_level != 1000000) {
				if (pass == 2) {
					map_parameter_scope *scope = NULL;
					EPS_map_level *eml;
					LOOP_OVER(eml, EPS_map_level)
						if ((eml->contains_rooms)
							&& (eml->map_level - PL::SpatialMap::benchmark_level() == hint->scope_level))
							scope = &(eml->map_parameters);
					if (scope) EPSMap::put_mp(hint->name, scope, IXInstances::fi(hint->scope_I), hint->put_string, hint->put_integer);
				}
			} else {
				if (pass == 1)
					EPSMap::put_mp(hint->name, NULL, IXInstances::fi(hint->scope_I), hint->put_string, hint->put_integer);
			}
		} else if (hint->annotation) {
			rubric_holder *rh = CREATE(rubric_holder);
			rh->annotation = hint->annotation;
			rh->point_size = hint->point_size;
			rh->font = hint->font;
			rh->colour = hint->colour;
			rh->at_offset = hint->at_offset;
			rh->offset_from = IXInstances::fi(hint->offset_from);
		}
	}
}

faux_instance *IXInstances::fi(instance *I) {
	faux_instance *FI;
	LOOP_OVER(FI, faux_instance)
		if (FI->original == I)
			return FI;
	return NULL;
}

faux_instance *IXInstances::start_room(void) {
	return start_faux_instance;
}

faux_instance *IXInstances::yourself(void) {
	return faux_yourself;
}

@h Naming.

=
text_stream *IXInstances::get_name(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->name;
}

void IXInstances::write_name(OUTPUT_STREAM, faux_instance *I) {
	WRITE("%S", IXInstances::get_name(I));
}

void IXInstances::write_kind(OUTPUT_STREAM, faux_instance *I) {
	WRITE("%S", I->kind_text);
}

void IXInstances::write_kind_chain(OUTPUT_STREAM, faux_instance *I) {
	WRITE("%S", I->kind_chain);
}

#ifdef CORE_MODULE
inference_subject *IXInstances::as_subject(faux_instance *FI) {
	if (FI == NULL) return NULL;
	return FI->knowledge;
}
#endif

faux_instance *IXInstances::region_of(faux_instance *FI) {
	if (FI == NULL) return NULL;
	return FI->region_enclosing;
}

faux_instance *IXInstances::opposite_direction(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->opposite_direction;
}

faux_instance *IXInstances::other_side_of_door(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->other_side;
}

faux_instance *IXInstances::sibling(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->object_tree_sibling;
}

faux_instance *IXInstances::child(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->object_tree_child;
}

faux_instance *IXInstances::progenitor(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->progenitor;
}

faux_instance *IXInstances::incorp_child(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->incorp_tree_child;
}

faux_instance *IXInstances::incorp_sibling(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->incorp_tree_sibling;
}

int IXInstances::is_a_direction(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	return FR->is_a_direction;
}

int IXInstances::is_a_room(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	return FR->is_a_room;
}

int IXInstances::is_a_door(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	return FR->is_a_door;
}

int IXInstances::is_a_region(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	return FR->is_a_region;
}

int IXInstances::is_a_thing(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	return FR->is_a_thing;
}

int IXInstances::is_a_supporter(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	return FR->is_a_supporter;
}

int IXInstances::is_a_person(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	return FR->is_a_person;
}

void IXInstances::get_door_data(faux_instance *door, faux_instance **c1, faux_instance **c2) {
	if (c1) *c1 = door->fimd.map_connection_a;
	if (c2) *c2 = door->fimd.map_connection_b;
}

map_parameter_scope *IXInstances::get_parameters(faux_instance *R) {
	if (R == NULL) return NULL;
	return &(R->fimd.local_map_parameters);
}

@h Noun usage.
This simply avoids repetitions in the World index:

=
void IXInstances::increment_indexing_count(faux_instance *I) {
	I->index_appearances++;
}

int IXInstances::indexed_yet(faux_instance *I) {
	if (I->index_appearances > 0) return TRUE;
	return FALSE;
}
