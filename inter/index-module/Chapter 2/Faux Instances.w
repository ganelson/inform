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

@ ...Except that it also contains a structure of spatial-mapping data which
is built in the course of making the World map: and this is data which has
no direct connection to data structures in the main Inform compiler.

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

@
		
@d LOOP_OVER_FAUX_INSTANCES(R)
	LOOP_OVER(R, faux_instance)
@d LOOP_OVER_FAUX_ROOMS(R)
	LOOP_OVER(R, faux_instance)
		if (FauxInstances::is_a_room(R))
@d LOOP_OVER_FAUX_DOORS(R)
	LOOP_OVER(R, faux_instance)
		if (FauxInstances::is_a_door(R))
@d LOOP_OVER_FAUX_REGIONS(R)
	LOOP_OVER(R, faux_instance)
		if (FauxInstances::is_a_region(R))
@d LOOP_OVER_FAUX_DIRECTIONS(R)
	LOOP_OVER(R, faux_instance)
		if (FauxInstances::is_a_direction(R))
@d LOOP_OVER_FAUX_BACKDROPS(R)
	LOOP_OVER(R, faux_instance)
		if (FauxInstances::is_a_backdrop(R))

=
int no_direction_fi = 0;
int no_room_fi = 0;

int FauxInstances::no_directions(void) {
	return no_direction_fi;
}

int FauxInstances::no_rooms(void) {
	return no_room_fi;
}


@ =
faux_instance *start_faux_instance = NULL;
faux_instance *faux_yourself = NULL;
faux_instance *faux_benchmark = NULL;

void FauxInstances::make_faux(void) {
	inter_tree *IT = InterpretIndex::get_tree();
	tree_inventory *inv = Synoptic::inv(IT);
	TreeLists::sort(inv->instance_nodes, Synoptic::module_order);
	for (int i=0; i<TreeLists::len(inv->instance_nodes); i++) {
		inter_package *pack = Inter::Package::defined_by_frame(inv->instance_nodes->list[i].node);
		if (Metadata::read_optional_numeric(pack,  I"^is_object") == 0) continue;
		faux_instance *FI = CREATE(faux_instance);
		FI->index_appearances = 0;
		FI->package = pack;
		FI->name = Str::duplicate(Metadata::read_textual(pack,  I"^name"));
		FI->printed_name = Str::duplicate(Metadata::read_textual(pack,  I"^printed_name"));
		FI->abbrev = Str::duplicate(Metadata::read_textual(pack,  I"^abbreviation"));
		FI->kind_text = Str::duplicate(Metadata::read_textual(pack,  I"^index_kind"));
		FI->kind_chain = Str::duplicate(Metadata::read_textual(pack,  I"^index_kind_chain"));
		FI->other_side = NULL;
		if (FauxInstances::is_a_direction(FI)) FI->direction_index = no_direction_fi;
		else FI->direction_index = -1;

		FI->backdrop_presences = NEW_LINKED_LIST(faux_instance);
		FI->region_enclosing = NULL;
		FI->next_room_in_submap = NULL;
		FI->opposite_direction = NULL;
		FI->object_tree_sibling = NULL;
		FI->object_tree_child = NULL;
		FI->progenitor = NULL;
		FI->incorp_tree_sibling = NULL;
		FI->incorp_tree_child = NULL;
		
		if (FauxInstances::is_a_room(FI)) no_room_fi++;
		if (FauxInstances::is_a_direction(FI)) no_direction_fi++;

		FI->anchor_text = Str::new();
		WRITE_TO(FI->anchor_text, "fi%d", FI->allocation_id);

		FI->fimd = FauxInstances::new_fimd(FI);
		FI->fimd.colour = NULL;
		FI->fimd.text_colour = NULL;
		FI->fimd.eps_x = 0;
		FI->fimd.eps_y = 0;

		if (Metadata::read_optional_numeric(pack, I"^is_yourself")) faux_yourself = FI;
		if (Metadata::read_optional_numeric(pack, I"^is_benchmark_room")) faux_benchmark = FI;
		if (Metadata::read_optional_numeric(pack, I"^is_start_room")) start_faux_instance = FI;
	}
	faux_instance *FI;
	LOOP_OVER_FAUX_ROOMS(FI) {
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
					FI->fimd.exits[i] = FauxInstances::fis(s);
				} else if ((v1 != LITERAL_IVAL) || (v2 != 0)) internal_error("malformed map metadata");
				inter_ti v3 = P->W.data[offset+2], v4 = P->W.data[offset+3];
				if (v3 != LITERAL_IVAL) internal_error("malformed map metadata");
				if (v4) FI->fimd.exits_set_at[i] = (int) v4;
			}
		}
	}
	LOOP_OVER_FAUX_BACKDROPS(FI) {
		inter_package *pack = FI->package;
		inter_tree_node *P = Metadata::read_optional_list(pack, I"^backdrop_presences");
		if (P) {
			int offset = DATA_CONST_IFLD;
			while (offset < P->W.extent) {
				inter_ti v1 = P->W.data[offset], v2 = P->W.data[offset+1];
				if (v1 == ALIAS_IVAL) {
					inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack), v2);
					if (s == NULL) internal_error("malformed map metadata");
					faux_instance *FL = FauxInstances::fis(s);
					ADD_TO_LINKED_LIST(FI, faux_instance, FL->backdrop_presences);
				} else internal_error("malformed backdrop metadata");
				offset += 2;
			}
		}
	}

	LOOP_OVER_FAUX_INSTANCES(FI) {
		FI->region_enclosing = FauxInstances::instance_metadata(FI, I"^region_enclosing");
		FI->object_tree_sibling = FauxInstances::instance_metadata(FI, I"^sibling");
		FI->object_tree_child = FauxInstances::instance_metadata(FI, I"^child");
		FI->progenitor = FauxInstances::instance_metadata(FI, I"^progenitor");
		FI->incorp_tree_sibling = FauxInstances::instance_metadata(FI, I"^incorp_sibling");
		FI->incorp_tree_child = FauxInstances::instance_metadata(FI, I"^incorp_child");
	}
	faux_instance *FR;
	LOOP_OVER_FAUX_DIRECTIONS(FR)
		FR->opposite_direction = FauxInstances::instance_metadata(FR, I"^opposite_direction");
	faux_instance *FD;
	LOOP_OVER_FAUX_DOORS(FD) {
		FD->other_side = FauxInstances::instance_metadata(FD, I"^other_side");
		FD->fimd.map_connection_a = FauxInstances::instance_metadata(FD, I"^side_a");
		FD->fimd.map_connection_b = FauxInstances::instance_metadata(FD, I"^side_b");
	}
	FauxInstances::decode_hints(IT, 1);
}

@

=
void FauxInstances::decode_hints(inter_tree *I, int pass) {
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/mapping_hints");
	inter_symbol *wanted = PackageTypes::get(I, I"_mapping_hint");
	inter_tree_node *D = Inter::Packages::definition(pack);
	LOOP_THROUGH_INTER_CHILDREN(C, D) {
		if (C->W.data[ID_IFLD] == PACKAGE_IST) {
			inter_package *entry = Inter::Package::defined_by_frame(C);
			if (Inter::Packages::type(entry) == wanted) {
				faux_instance *from = FauxInstances::fis(Metadata::read_optional_symbol(entry, I"^from"));
				faux_instance *to = FauxInstances::fis(Metadata::read_optional_symbol(entry, I"^to"));
				faux_instance *dir = FauxInstances::fis(Metadata::read_optional_symbol(entry, I"^dir"));
				faux_instance *as_dir = FauxInstances::fis(Metadata::read_optional_symbol(entry, I"^as_dir"));
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
					faux_instance *scope_I = FauxInstances::fis(Metadata::read_optional_symbol(entry, I"^scope_instance"));
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
						rh->offset_from = FauxInstances::fis(Metadata::read_optional_symbol(entry, I"^offset_from"));
					}
					continue;
				}
			}
		}
	}
}

faux_instance *FauxInstances::instance_metadata(faux_instance *I, text_stream *key) {
	if (I == NULL) return I;
	inter_symbol *val_s = Metadata::read_optional_symbol(I->package, key);
	return FauxInstances::fis(val_s);
}

faux_instance *FauxInstances::fis(inter_symbol *S) {
	if (S == NULL) return NULL;
	inter_package *want = Inter::Packages::container(S->definition);
	faux_instance *FI;
	LOOP_OVER_FAUX_INSTANCES(FI)
		if (FI->package == want)
			return FI;
	return NULL;
}

faux_instance *FauxInstances::start_room(void) {
	return start_faux_instance;
}

faux_instance *FauxInstances::yourself(void) {
	return faux_yourself;
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
