[FauxInstances::] Faux Instances.

Some of the more complicated indexing tasks need to build data structures 
cross-referencing the instance packages in the Inter tree: the spatial map,
in particular. For convenience, we create faux-instance objects for them,
which partly correspond to the instance objects in the original compiler.

@ The data structure //faux_instance// consists mostly of cross-references
to other faux instances, and is paraphrased directly from the Inter tree:

=
typedef struct faux_instance {
	struct inter_package *package;
	int index_appearances; /* how many times have I appeared thus far in the World index? */
	struct text_stream *name;
	struct text_stream *printed_name;
	struct text_stream *abbrev;
	int direction_index;
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
	struct fi_map_data fimd;
	CLASS_DEFINITION
} faux_instance;

@ The following function creates a basic //faux_instance// corresponding to
the package |pack|, but one in which none of the cross-references to other
FIs are present: those can only be made once all of the basic FIs have been
created.

=
faux_instance *FauxInstances::new(inter_package *pack, index_session *session) {
	faux_instance *I = CREATE(faux_instance);
	I->index_appearances = 0;
	I->package = pack;
	I->name = Str::duplicate(Metadata::read_textual(pack, I"^name"));
	I->printed_name = Str::duplicate(Metadata::read_textual(pack, I"^printed_name"));
	I->abbrev = Str::duplicate(Metadata::read_textual(pack, I"^abbreviation"));
	I->kind_text = Str::duplicate(Metadata::read_textual(pack, I"^index_kind"));
	I->kind_chain = Str::duplicate(Metadata::read_textual(pack, I"^index_kind_chain"));
	I->other_side = NULL;
	I->direction_index = -1;

	I->backdrop_presences = NEW_LINKED_LIST(faux_instance);
	I->region_enclosing = NULL;
	I->next_room_in_submap = NULL;
	I->opposite_direction = NULL;
	I->object_tree_sibling = NULL;
	I->object_tree_child = NULL;
	I->progenitor = NULL;
	I->incorp_tree_sibling = NULL;
	I->incorp_tree_child = NULL;

	I->anchor_text = Str::new();
	WRITE_TO(I->anchor_text, "fi%d", I->allocation_id);

	I->fimd = FauxInstances::new_fimd(I, session);
	return I;
}

@ Though the FI structure mostly paraphrases data in the Inter tree which in
turn paraphrases data structures in the Inform compiler, it also contains
an //fi_map_data// structure which is more novel, and is used when making
the World map.

@d MAX_DIRECTIONS 100 /* the Standard Rules define only 12, so this is plenty */

=
typedef struct fi_map_data {
	struct connected_submap *submap;
	struct vector position;
	struct vector saved_gridpos;
	int cooled;
	int shifted;
	int zone;
	struct text_stream *colour; /* an HTML colour for the room square (rooms only) */
	struct text_stream *text_colour; /* an HTML colour for text on that square */
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

@ Data which is blanked out, ready for use, here:

=
fi_map_data FauxInstances::new_fimd(faux_instance *I, index_session *session) {
	fi_map_data fimd;
	fimd.submap = NULL;
	fimd.position = Geometry::zero();
	fimd.saved_gridpos = Geometry::zero();
	fimd.cooled = FALSE;
	fimd.shifted = FALSE;
	fimd.zone = 0;
	fimd.colour = NULL;
	fimd.text_colour = NULL;
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
	ConfigureIndexMap::prepare_map_parameter_scope(&(fimd.local_map_parameters), session);
	return fimd;
}

@h Sets.
Since we might want to index multiple different Inter trees in the same run,
we may need to keep multiple sets of faux instances, one for each tree. So:

=
typedef struct faux_instance_set {
	int no_direction_fi;
	int no_room_fi;
	struct linked_list *instances; /* of |faux_instance| */
	struct faux_instance *start_faux_instance;
	struct faux_instance *faux_yourself;
	struct faux_instance *faux_benchmark;
	struct linked_list *rubrics; /* of |rubric_holder| */
	CLASS_DEFINITION
} faux_instance_set;

@ =
faux_instance_set *FauxInstances::new_empty_set(void) {
	faux_instance_set *faux_set = CREATE(faux_instance_set);
	faux_set->no_direction_fi = 0;
	faux_set->no_room_fi = 0;
	faux_set->instances = NEW_LINKED_LIST(faux_instance);
	faux_set->start_faux_instance = NULL;
	faux_set->faux_yourself = NULL;
	faux_set->faux_benchmark = NULL;
	faux_set->rubrics = NEW_LINKED_LIST(rubric_holder);
	return faux_set;
}

@ Iterating over faux instances in a set can then be done thus:
		
@d LOOP_OVER_FAUX_INSTANCES(faux_set, R)
	LOOP_OVER_LINKED_LIST(R, faux_instance, faux_set->instances)
@d LOOP_OVER_FAUX_ROOMS(faux_set, R)
	LOOP_OVER_FAUX_INSTANCES(faux_set, R)
		if (FauxInstances::is_a_room(R))
@d LOOP_OVER_FAUX_DOORS(faux_set, R)
	LOOP_OVER_FAUX_INSTANCES(faux_set, R)
		if (FauxInstances::is_a_door(R))
@d LOOP_OVER_FAUX_REGIONS(faux_set, R)
	LOOP_OVER_FAUX_INSTANCES(faux_set, R)
		if (FauxInstances::is_a_region(R))
@d LOOP_OVER_FAUX_DIRECTIONS(faux_set, R)
	LOOP_OVER_FAUX_INSTANCES(faux_set, R)
		if (FauxInstances::is_a_direction(R))
@d LOOP_OVER_FAUX_BACKDROPS(faux_set, R)
	LOOP_OVER_FAUX_INSTANCES(faux_set, R)
		if (FauxInstances::is_a_backdrop(R))

@ And here is the code to make a fully cross-referenced set from a given tree:

=
void FauxInstances::make_faux(index_session *session) {
	faux_instance_set *faux_set = FauxInstances::new_empty_set();
	session->set_of_instances = faux_set;

	tree_inventory *inv = Indexing::get_inventory(session);
	InterNodeList::array_sort(inv->instance_nodes, MakeSynopticModuleStage::module_order);
	inter_package *pack;
	LOOP_OVER_INVENTORY_PACKAGES(pack, i, inv->instance_nodes)
		if (Metadata::read_optional_numeric(pack,  I"^is_object"))
			@<Add a faux instance to the set for this object-instance package@>;
	faux_instance *I;
	LOOP_OVER_FAUX_INSTANCES(faux_set, I) {
		inter_package *pack = I->package;
		@<Cross-reference spatial relationships@>;
		if (FauxInstances::is_a_room(I)) @<Cross-reference map relationships@>;
		if (FauxInstances::is_a_backdrop(I)) @<Cross-reference backdrop locations@>;
		if (FauxInstances::is_a_direction(I)) @<Cross-reference diametric directions@>;
		if (FauxInstances::is_a_door(I)) @<Cross-reference door adjacencies@>;
	}

	FauxInstances::decode_hints(session, 1);
}

@<Add a faux instance to the set for this object-instance package@> =
	faux_instance *I = FauxInstances::new(pack, session);
	ADD_TO_LINKED_LIST(I, faux_instance, faux_set->instances);	
	if (FauxInstances::is_a_direction(I)) I->direction_index = faux_set->no_direction_fi++;
	if (FauxInstances::is_a_room(I)) faux_set->no_room_fi++;
	if (Metadata::read_optional_numeric(pack, I"^is_yourself")) faux_set->faux_yourself = I;
	if (Metadata::read_optional_numeric(pack, I"^is_benchmark_room")) faux_set->faux_benchmark = I;
	if (Metadata::read_optional_numeric(pack, I"^is_start_room")) faux_set->start_faux_instance = I;

@<Cross-reference spatial relationships@> =
	I->region_enclosing = FauxInstances::xref(faux_set, I->package, I"^region_enclosing");
	I->object_tree_sibling = FauxInstances::xref(faux_set, I->package, I"^sibling");
	I->object_tree_child = FauxInstances::xref(faux_set, I->package, I"^child");
	I->progenitor = FauxInstances::xref(faux_set, I->package, I"^progenitor");
	I->incorp_tree_sibling = FauxInstances::xref(faux_set, I->package, I"^incorp_sibling");
	I->incorp_tree_child = FauxInstances::xref(faux_set, I->package, I"^incorp_child");

@<Cross-reference map relationships@> =
	inter_tree_node *P = Metadata::read_optional_list(pack, I"^map");
	if (P) {
		for (int i=0; i<MAX_DIRECTIONS; i++) {
			int offset = DATA_CONST_IFLD + 4*i;
			if (offset >= P->W.extent) break;
			inter_pair val = InterValuePairs::get(P, offset);
			if (InterValuePairs::holds_symbol(val)) {
				inter_symbol *S =
					InterValuePairs::symbol_from_data_pair(val, InterPackage::scope(pack));
				if (S == NULL) internal_error("malformed map metadata");
				I->fimd.exits[i] = FauxInstances::symbol_to_faux_instance(faux_set, S);
			} else if (InterValuePairs::is_zero(val) == FALSE)
				internal_error("malformed map metadata");
			inter_pair val2 = InterValuePairs::get(P, offset+2);
			if (InterValuePairs::is_number(val2) == FALSE)
				internal_error("malformed map metadata");
			inter_ti N = InterValuePairs::to_number(val2);
			if (N) I->fimd.exits_set_at[i] = (int) N;
		}
	}

@<Cross-reference backdrop locations@> =
	inter_tree_node *P = Metadata::read_optional_list(pack, I"^backdrop_presences");
	if (P) {
		int offset = DATA_CONST_IFLD;
		while (offset < P->W.extent) {
			inter_pair val = InterValuePairs::get(P, offset);
			if (InterValuePairs::holds_symbol(val)) {
				inter_symbol *S =
					InterValuePairs::symbol_from_data_pair(val, InterPackage::scope(pack));
				if (S == NULL) internal_error("malformed map metadata");
				faux_instance *FL = FauxInstances::symbol_to_faux_instance(faux_set, S);
				ADD_TO_LINKED_LIST(I, faux_instance, FL->backdrop_presences);
			} else internal_error("malformed backdrop metadata");
			offset += 2;
		}
	}

@<Cross-reference diametric directions@> =
	I->opposite_direction = FauxInstances::xref(faux_set, I->package, I"^opposite_direction");

@<Cross-reference door adjacencies@> =
	I->other_side = FauxInstances::xref(faux_set, I->package, I"^other_side");
	I->fimd.map_connection_a = FauxInstances::xref(faux_set, I->package, I"^side_a");
	I->fimd.map_connection_b = FauxInstances::xref(faux_set, I->package, I"^side_b");

@ When the Inter package for one instance wants to refer to another one, say
with the key |other|, it does so by having a symbol |other| defined as the
instance value of the other instance: so we first extract the symbol by looking
|key| up in the first instance's package; then we can find the other instance
package simply by finding the container-package for where |S| is defined.
It is then a simple if not especially quick task to find which //faux_instance//
was made from that package.

=
faux_instance *FauxInstances::xref(faux_instance_set *faux_set, inter_package *pack,
	text_stream *key) {
	return FauxInstances::symbol_to_faux_instance(faux_set,
		Metadata::read_optional_symbol(pack, key));
}

faux_instance *FauxInstances::symbol_to_faux_instance(faux_instance_set *faux_set,
	inter_symbol *S) {
	if (S == NULL) return NULL;
	inter_package *want = InterPackage::container(S->definition);
	faux_instance *I;
	LOOP_OVER_FAUX_INSTANCES(faux_set, I)
		if (I->package == want)
			return I;
	return NULL;
}

@h Decoding map hints.
Mapping hints arise from sentences like "Index with X mapped east of Y", or
some other helpful tip: these are compiled fairly directly into Inter packages,
and this is where we decode those packages and make use of them.

This is done in two passes. |pass| 1 occurs when a new faux set of instances is
being made; |pass| 2 only after the spatial grid layout has been calculated,
and only if needed.

=
void FauxInstances::decode_hints(index_session *session, int pass) {
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	inter_tree *I = Indexing::get_tree(session);
	inter_package *pack = InterPackage::from_URL(I, I"/main/completion/mapping_hints");
	inter_package *hint_pack;
	LOOP_THROUGH_SUBPACKAGES(hint_pack, pack, I"_mapping_hint") {
		faux_instance *from = FauxInstances::xref(faux_set, hint_pack, I"^from");
		faux_instance *to = FauxInstances::xref(faux_set, hint_pack, I"^to");
		faux_instance *dir = FauxInstances::xref(faux_set, hint_pack, I"^dir");
		faux_instance *as_dir = FauxInstances::xref(faux_set, hint_pack, I"^as_dir");
		if ((dir) && (as_dir)) {
			if (pass == 1) @<Decode a hint mapping one direction as if another@>;
			continue;
		}
		if ((from) && (dir)) {
			if (pass == 1) @<Decode a hint mapping one room in a specific direction from another@>;
			continue;
		}
		text_stream *name = Metadata::read_optional_textual(hint_pack, I"^name");
		if (Str::len(name) > 0) {
			int scope_level = (int) Metadata::read_optional_numeric(hint_pack, I"^scope_level");
			faux_instance *scope_I = FauxInstances::xref(faux_set, hint_pack, I"^scope_instance");
			text_stream *text_val = Metadata::read_optional_textual(hint_pack, I"^text");
			int int_val = (int) Metadata::read_optional_numeric(hint_pack, I"^number");
			if (scope_level != 1000000) {
				if (pass == 2) @<Decode a hint setting EPS map parameters relating to levels@>;
			} else {
				if (pass == 1) @<Decode a hint setting EPS map parameters@>;
			}
			continue;
		}
		text_stream *annotation = Metadata::read_optional_textual(hint_pack, I"^annotation");
		if (Str::len(annotation) > 0) {
			if (pass == 1) {
				rubric_holder *rh = CREATE(rubric_holder);
				rh->annotation = annotation;
				rh->point_size = (int) Metadata::read_optional_numeric(hint_pack, I"^point_size");
				rh->font = Metadata::read_optional_textual(hint_pack, I"^font");
				rh->colour = Metadata::read_optional_textual(hint_pack, I"^colour");
				rh->at_offset = (int) Metadata::read_optional_numeric(hint_pack, I"^offset");
				rh->offset_from = FauxInstances::xref(faux_set, hint_pack, I"^offset_from");
				ADD_TO_LINKED_LIST(rh, rubric_holder, faux_set->rubrics);	
			}
			continue;
		}
	}
}

@ For instance, for "starboard" to be mapped as if "east":

@<Decode a hint mapping one direction as if another@> =
	session->story_dir_to_page_dir[dir->direction_index] = as_dir->direction_index;

@ For instance, for the East Room to be mapped east of the Grand Lobby:

@<Decode a hint mapping one room in a specific direction from another@> =
	SpatialMap::lock_exit_in_place(from, dir->direction_index, to, session);

@ Most map parameters (e.g. setting room colours or font sizes) can be set
immediately, i.e., on |pass| 1:

@<Decode a hint setting EPS map parameters@> =
	ConfigureIndexMap::put_mp(name, NULL, scope_I, text_val, int_val, session);

@ ...but not those hints applying to a specific level of the map (e.g., level 4),
since we do not initially know what level any given room actually lives on: that
can only be known once the spatial grid has been found, i.e., on |pass| 2.

@<Decode a hint setting EPS map parameters relating to levels@> =
	map_parameter_scope *scope = NULL;
	linked_list *L = Indexing::get_list_of_EPS_map_levels(session);
	EPS_map_level *eml;
	LOOP_OVER_LINKED_LIST(eml, EPS_map_level, L)
		if ((eml->contains_rooms)
			&& (eml->map_level - SpatialMap::benchmark_level(session) == scope_level))
			scope = &(eml->map_parameters);
	if (scope) ConfigureIndexMap::put_mp(name, scope, scope_I, text_val, int_val, session);

@h Instance set properties.

=
faux_instance *FauxInstances::start_room(index_session *session) {
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	return faux_set->start_faux_instance;
}

faux_instance *FauxInstances::yourself(index_session *session) {
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	return faux_set->faux_yourself;
}

faux_instance *FauxInstances::benchmark(index_session *session) {
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	return faux_set->faux_benchmark;
}

@ =
int FauxInstances::no_directions(index_session *session) {
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	return faux_set->no_direction_fi;
}

int FauxInstances::no_rooms(index_session *session) {
	faux_instance_set *faux_set = Indexing::get_set_of_instances(session);
	return faux_set->no_room_fi;
}

@h Individual instance properties.

=
text_stream *FauxInstances::get_name(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->name;
}

void FauxInstances::write_name(OUTPUT_STREAM, faux_instance *I) {
	WRITE("%S", FauxInstances::get_name(I));
}

void FauxInstances::write_kind(OUTPUT_STREAM, faux_instance *I) {
	WRITE("%S", I->kind_text);
}

void FauxInstances::write_kind_chain(OUTPUT_STREAM, faux_instance *I) {
	WRITE("%S", I->kind_chain);
}

faux_instance *FauxInstances::region_of(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->region_enclosing;
}

faux_instance *FauxInstances::opposite_direction(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->opposite_direction;
}

faux_instance *FauxInstances::other_side_of_door(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->other_side;
}

faux_instance *FauxInstances::sibling(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->object_tree_sibling;
}

faux_instance *FauxInstances::child(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->object_tree_child;
}

faux_instance *FauxInstances::progenitor(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->progenitor;
}

faux_instance *FauxInstances::incorp_child(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->incorp_tree_child;
}

faux_instance *FauxInstances::incorp_sibling(faux_instance *I) {
	if (I == NULL) return NULL;
	return I->incorp_tree_sibling;
}

int FauxInstances::is_a_direction(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_direction")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_room(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_room")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_door(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_door")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_region(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_region")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_backdrop(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_backdrop")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_thing(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_thing")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_supporter(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_supporter")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_person(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_person")) return TRUE;
	return FALSE;
}

int FauxInstances::is_worn(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_worn")) return TRUE;
	return FALSE;
}

int FauxInstances::is_everywhere(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_everywhere")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_part(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Metadata::read_optional_numeric(I->package, I"^is_a_part")) return TRUE;
	return FALSE;
}

int FauxInstances::created_at(faux_instance *I) {
	if (I == NULL) return -1;
	return (int) Metadata::read_optional_numeric(I->package,  I"^at");
}

int FauxInstances::kind_set_at(faux_instance *I) {
	if (I == NULL) return -1;
	return (int) Metadata::read_optional_numeric(I->package,  I"^kind_set_at");
}

int FauxInstances::progenitor_set_at(faux_instance *I) {
	if (I == NULL) return -1;
	return (int) Metadata::read_optional_numeric(I->package,  I"^progenitor_set_at");
}

int FauxInstances::region_set_at(faux_instance *I) {
	if (I == NULL) return -1;
	return (int) Metadata::read_optional_numeric(I->package,  I"^region_set_at");
}

void FauxInstances::get_door_data(faux_instance *door,
	faux_instance **c1, faux_instance **c2) {
	if (c1) *c1 = door->fimd.map_connection_a;
	if (c2) *c2 = door->fimd.map_connection_b;
}

map_parameter_scope *FauxInstances::get_parameters(faux_instance *I) {
	if (I == NULL) return NULL;
	return &(I->fimd.local_map_parameters);
}

int FauxInstances::specify_kind(faux_instance *I) {
	if (I == NULL) return FALSE;
	if (Str::eq(I->kind_text, I"thing")) return FALSE;
	if (Str::eq(I->kind_text, I"room")) return FALSE;
	return TRUE;
}

@h Appearance counts.
This code simply avoids repetitions in the World index:

=
void FauxInstances::increment_indexing_count(faux_instance *I) {
	I->index_appearances++;
}

int FauxInstances::indexed_yet(faux_instance *I) {
	if (I->index_appearances > 0) return TRUE;
	return FALSE;
}
