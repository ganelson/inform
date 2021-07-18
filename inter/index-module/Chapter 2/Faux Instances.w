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
faux_instance *FauxInstances::new(inter_package *pack) {
	faux_instance *FI = CREATE(faux_instance);
	FI->index_appearances = 0;
	FI->package = pack;
	FI->name = Str::duplicate(Metadata::read_textual(pack, I"^name"));
	FI->printed_name = Str::duplicate(Metadata::read_textual(pack, I"^printed_name"));
	FI->abbrev = Str::duplicate(Metadata::read_textual(pack, I"^abbreviation"));
	FI->kind_text = Str::duplicate(Metadata::read_textual(pack, I"^index_kind"));
	FI->kind_chain = Str::duplicate(Metadata::read_textual(pack, I"^index_kind_chain"));
	FI->other_side = NULL;
	FI->direction_index = -1;

	FI->backdrop_presences = NEW_LINKED_LIST(faux_instance);
	FI->region_enclosing = NULL;
	FI->next_room_in_submap = NULL;
	FI->opposite_direction = NULL;
	FI->object_tree_sibling = NULL;
	FI->object_tree_child = NULL;
	FI->progenitor = NULL;
	FI->incorp_tree_sibling = NULL;
	FI->incorp_tree_child = NULL;

	FI->anchor_text = Str::new();
	WRITE_TO(FI->anchor_text, "fi%d", FI->allocation_id);

	FI->fimd = FauxInstances::new_fimd(FI);
	return FI;
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
fi_map_data FauxInstances::new_fimd(faux_instance *FI) {
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
	ConfigureIndexMap::prepare_map_parameter_scope(&(fimd.local_map_parameters));
	return fimd;
}


@ =
typedef struct faux_instance_set {
	int no_direction_fi;
	int no_room_fi;
	struct linked_list *instances; /* of |faux_instance| */
	struct faux_instance *start_faux_instance;
	struct faux_instance *faux_yourself;
	struct faux_instance *faux_benchmark;
	CLASS_DEFINITION
} faux_instance_set;

@ Iterating over faux instances in a set:
		
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

@

=
faux_instance_set *FauxInstances::make_faux(inter_tree *IT) {
	faux_instance_set *faux_set = CREATE(faux_instance_set);
	faux_set->no_direction_fi = 0;
	faux_set->no_room_fi = 0;
	faux_set->instances = NEW_LINKED_LIST(faux_instance);
	faux_set->start_faux_instance = NULL;
	faux_set->faux_yourself = NULL;
	faux_set->faux_benchmark = NULL;

	tree_inventory *inv = Synoptic::inv(IT);
	TreeLists::sort(inv->instance_nodes, Synoptic::module_order);
	for (int i=0; i<TreeLists::len(inv->instance_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack,  I"^is_object") == 0) continue;
		faux_instance *FI = FauxInstances::new(pack);
		ADD_TO_LINKED_LIST(FI, faux_instance, faux_set->instances);	
		if (FauxInstances::is_a_direction(FI)) FI->direction_index = faux_set->no_direction_fi++;
		if (FauxInstances::is_a_room(FI)) faux_set->no_room_fi++;
		if (Metadata::read_optional_numeric(pack, I"^is_yourself")) faux_set->faux_yourself = FI;
		if (Metadata::read_optional_numeric(pack, I"^is_benchmark_room")) faux_set->faux_benchmark = FI;
		if (Metadata::read_optional_numeric(pack, I"^is_start_room")) faux_set->start_faux_instance = FI;
	}
	faux_instance *FI;
	LOOP_OVER_FAUX_ROOMS(faux_set, FI) {
		inter_package *pack = FI->package;
		inter_tree_node *P = Metadata::read_optional_list(pack, I"^map");
		if (P) {
			for (int i=0; i<MAX_DIRECTIONS; i++) {
				int offset = DATA_CONST_IFLD + 4*i;
				if (offset >= P->W.extent) break;
				inter_ti v1 = P->W.data[offset], v2 = P->W.data[offset+1];
				if (v1 == ALIAS_IVAL) {
					inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack), v2);
					if (s == NULL) internal_error("malformed map metadata");
					FI->fimd.exits[i] = FauxInstances::fis(faux_set, s);
				} else if ((v1 != LITERAL_IVAL) || (v2 != 0)) internal_error("malformed map metadata");
				inter_ti v3 = P->W.data[offset+2], v4 = P->W.data[offset+3];
				if (v3 != LITERAL_IVAL) internal_error("malformed map metadata");
				if (v4) FI->fimd.exits_set_at[i] = (int) v4;
			}
		}
	}
	LOOP_OVER_FAUX_BACKDROPS(faux_set, FI) {
		inter_package *pack = FI->package;
		inter_tree_node *P = Metadata::read_optional_list(pack, I"^backdrop_presences");
		if (P) {
			int offset = DATA_CONST_IFLD;
			while (offset < P->W.extent) {
				inter_ti v1 = P->W.data[offset], v2 = P->W.data[offset+1];
				if (v1 == ALIAS_IVAL) {
					inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack), v2);
					if (s == NULL) internal_error("malformed map metadata");
					faux_instance *FL = FauxInstances::fis(faux_set, s);
					ADD_TO_LINKED_LIST(FI, faux_instance, FL->backdrop_presences);
				} else internal_error("malformed backdrop metadata");
				offset += 2;
			}
		}
	}

	LOOP_OVER_FAUX_INSTANCES(faux_set, FI) {
		FI->region_enclosing = FauxInstances::instance_metadata(faux_set, FI, I"^region_enclosing");
		FI->object_tree_sibling = FauxInstances::instance_metadata(faux_set, FI, I"^sibling");
		FI->object_tree_child = FauxInstances::instance_metadata(faux_set, FI, I"^child");
		FI->progenitor = FauxInstances::instance_metadata(faux_set, FI, I"^progenitor");
		FI->incorp_tree_sibling = FauxInstances::instance_metadata(faux_set, FI, I"^incorp_sibling");
		FI->incorp_tree_child = FauxInstances::instance_metadata(faux_set, FI, I"^incorp_child");
	}
	faux_instance *FR;
	LOOP_OVER_FAUX_DIRECTIONS(faux_set, FR)
		FR->opposite_direction = FauxInstances::instance_metadata(faux_set, FR, I"^opposite_direction");
	faux_instance *FD;
	LOOP_OVER_FAUX_DOORS(faux_set, FD) {
		FD->other_side = FauxInstances::instance_metadata(faux_set, FD, I"^other_side");
		FD->fimd.map_connection_a = FauxInstances::instance_metadata(faux_set, FD, I"^side_a");
		FD->fimd.map_connection_b = FauxInstances::instance_metadata(faux_set, FD, I"^side_b");
	}
	FauxInstances::decode_hints(faux_set, IT, 1);
	return faux_set;
}

@

=
void FauxInstances::decode_hints(faux_instance_set *faux_set, inter_tree *I, int pass) {
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/mapping_hints");
	inter_symbol *wanted = PackageTypes::get(I, I"_mapping_hint");
	inter_tree_node *D = Inter::Packages::definition(pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				faux_instance *from = FauxInstances::fis(faux_set, Metadata::read_optional_symbol(entry, I"^from"));
				faux_instance *to = FauxInstances::fis(faux_set, Metadata::read_optional_symbol(entry, I"^to"));
				faux_instance *dir = FauxInstances::fis(faux_set, Metadata::read_optional_symbol(entry, I"^dir"));
				faux_instance *as_dir = FauxInstances::fis(faux_set, Metadata::read_optional_symbol(entry, I"^as_dir"));
				if ((dir) && (as_dir)) {
					if (pass == 1)
						story_dir_to_page_dir[dir->direction_index] = as_dir->direction_index;
					continue;
				}
				if ((from) && (dir)) {
					if (pass == 1)
						PL::SpatialMap::lock_exit_in_place(from, dir->direction_index, to);
					continue;
				}
				text_stream *name = Metadata::read_optional_textual(entry, I"^name");
				if (Str::len(name) > 0) {
					int scope_level = (int) Metadata::read_optional_numeric(entry, I"^scope_level");
					faux_instance *scope_I = FauxInstances::fis(faux_set, Metadata::read_optional_symbol(entry, I"^scope_instance"));
					text_stream *text_val = Metadata::read_optional_textual(entry, I"^text");
					int int_val = (int) Metadata::read_optional_numeric(entry, I"^number");
					if (scope_level != 1000000) {
						if (pass == 2) {
							map_parameter_scope *scope = NULL;
							EPS_map_level *eml;
							LOOP_OVER(eml, EPS_map_level)
								if ((eml->contains_rooms)
									&& (eml->map_level - PL::SpatialMap::benchmark_level() == scope_level))
									scope = &(eml->map_parameters);
							if (scope) ConfigureIndexMap::put_mp(name, scope, scope_I, text_val, int_val);
						}
					} else {
						if (pass == 1)
							ConfigureIndexMap::put_mp(name, NULL, scope_I, text_val, int_val);
					}
					continue;
				}
				text_stream *annotation = Metadata::read_optional_textual(entry, I"^annotation");
				if (Str::len(annotation) > 0) {
					if (pass == 1) {
						rubric_holder *rh = CREATE(rubric_holder);
						rh->annotation = annotation;
						rh->point_size = (int) Metadata::read_optional_numeric(entry, I"^point_size");
						rh->font = Metadata::read_optional_textual(entry, I"^font");
						rh->colour = Metadata::read_optional_textual(entry, I"^colour");
						rh->at_offset = (int) Metadata::read_optional_numeric(entry, I"^offset");
						rh->offset_from = FauxInstances::fis(faux_set, Metadata::read_optional_symbol(entry, I"^offset_from"));
					}
					continue;
				}
			}
		}
	}
}

faux_instance *FauxInstances::instance_metadata(faux_instance_set *faux_set,
	faux_instance *I, text_stream *key) {
	if (I == NULL) return I;
	inter_symbol *val_s = Metadata::read_optional_symbol(I->package, key);
	return FauxInstances::fis(faux_set, val_s);
}

faux_instance *FauxInstances::fis(faux_instance_set *faux_set, inter_symbol *S) {
	if (S == NULL) return NULL;
	inter_package *want = Inter::Packages::container(S->definition);
	faux_instance *FI;
	LOOP_OVER_FAUX_INSTANCES(faux_set, FI)
		if (FI->package == want)
			return FI;
	return NULL;
}

faux_instance *FauxInstances::start_room(void) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	return faux_set->start_faux_instance;
}

faux_instance *FauxInstances::yourself(void) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	return faux_set->faux_yourself;
}

faux_instance *FauxInstances::benchmark(void) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	return faux_set->faux_benchmark;
}

@

=

int FauxInstances::no_directions(void) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	return faux_set->no_direction_fi;
}

int FauxInstances::no_rooms(void) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	return faux_set->no_room_fi;
}

@h Naming.

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

faux_instance *FauxInstances::region_of(faux_instance *FI) {
	if (FI == NULL) return NULL;
	return FI->region_enclosing;
}

faux_instance *FauxInstances::opposite_direction(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->opposite_direction;
}

faux_instance *FauxInstances::other_side_of_door(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->other_side;
}

faux_instance *FauxInstances::sibling(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->object_tree_sibling;
}

faux_instance *FauxInstances::child(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->object_tree_child;
}

faux_instance *FauxInstances::progenitor(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->progenitor;
}

faux_instance *FauxInstances::incorp_child(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->incorp_tree_child;
}

faux_instance *FauxInstances::incorp_sibling(faux_instance *FR) {
	if (FR == NULL) return NULL;
	return FR->incorp_tree_sibling;
}

int FauxInstances::is_a_direction(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_direction")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_room(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_room")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_door(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_door")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_region(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_region")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_backdrop(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_backdrop")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_thing(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_thing")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_supporter(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_supporter")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_person(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_person")) return TRUE;
	return FALSE;
}

int FauxInstances::is_worn(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_worn")) return TRUE;
	return FALSE;
}

int FauxInstances::is_everywhere(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_everywhere")) return TRUE;
	return FALSE;
}

int FauxInstances::is_a_part(faux_instance *FR) {
	if (FR == NULL) return FALSE;
	if (Metadata::read_optional_numeric(FR->package, I"^is_a_part")) return TRUE;
	return FALSE;
}

int FauxInstances::created_at(faux_instance *FR) {
	if (FR == NULL) return -1;
	return (int) Metadata::read_optional_numeric(FR->package,  I"^at");
}

int FauxInstances::kind_set_at(faux_instance *FR) {
	if (FR == NULL) return -1;
	return (int) Metadata::read_optional_numeric(FR->package,  I"^kind_set_at");
}

int FauxInstances::progenitor_set_at(faux_instance *FR) {
	if (FR == NULL) return -1;
	return (int) Metadata::read_optional_numeric(FR->package,  I"^progenitor_set_at");
}

int FauxInstances::region_set_at(faux_instance *FR) {
	if (FR == NULL) return -1;
	return (int) Metadata::read_optional_numeric(FR->package,  I"^region_set_at");
}

void FauxInstances::get_door_data(faux_instance *door, faux_instance **c1, faux_instance **c2) {
	if (c1) *c1 = door->fimd.map_connection_a;
	if (c2) *c2 = door->fimd.map_connection_b;
}

map_parameter_scope *FauxInstances::get_parameters(faux_instance *R) {
	if (R == NULL) return NULL;
	return &(R->fimd.local_map_parameters);
}

int FauxInstances::specify_kind(faux_instance *FI) {
	if (FI == NULL) return FALSE;
	if (Str::eq(FI->kind_text, I"thing")) return FALSE;
	if (Str::eq(FI->kind_text, I"room")) return FALSE;
	return TRUE;
}

@h Noun usage.
This simply avoids repetitions in the World index:

=
void FauxInstances::increment_indexing_count(faux_instance *I) {
	I->index_appearances++;
}

int FauxInstances::indexed_yet(faux_instance *I) {
	if (I->index_appearances > 0) return TRUE;
	return FALSE;
}
