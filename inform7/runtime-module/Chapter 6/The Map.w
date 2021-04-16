[RTMap::] The Map.

@

=
inter_name *RTMap::new_direction_iname(void) {
	package_request *PR = Hierarchy::synoptic_package(DIRECTIONS_HAP);
	return Hierarchy::make_iname_in(DIRECTION_HL, PR);
}

@ One of the few early breaks with I6 practice was that I7 stores the
map differently at run-time compared to earlier I6 games.

=
int RTMap::compile_model_tables(void) {
	@<Declare I6 constants for the directions@>;
	@<Compile the I6 Map-Storage array@>;
	return FALSE;
}

@<Declare I6 constants for the directions@> =
	inter_name *ndi = Hierarchy::find(NO_DIRECTIONS_HL);
	Emit::numeric_constant(ndi, (inter_ti) Map::number_of_directions());
	Hierarchy::make_available(Emit::tree(), ndi);

	instance *I;
	LOOP_OVER_INSTANCES(I, K_direction)
		Emit::iname_constant(MAP_DATA(I)->direction_iname, K_object,
			RTInstances::emitted_iname(I));

@ The |Map_Storage| array consists only of the |exits| arrays written out
one after another. It looks wasteful of memory, since it is almost always
going to be filled mostly with |0| entries (meaning: no exit that way). But
the memory needs to be there because map connections can be added dynamically
at run-time, so we can't know now how many we will need.

@<Compile the I6 Map-Storage array@> =
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		RTInstances::emitted_iname(I);
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
		LOOP_OVER_INSTANCES(I, K_object)
			if (Spatial::object_is_a_room(I)) {
				int N = Map::number_of_directions();
				for (int i=0; i<N; i++) {
					instance *to = MAP_EXIT(I, i);
					if (to)
						Emit::array_iname_entry(RTInstances::iname(to));
					else
						Emit::array_numeric_entry(0);
				}
				words_used++;
				TEMPORARY_TEXT(divider)
				WRITE_TO(divider, "Exits from: %~I", I);
				Emit::array_divider(divider);
				DISCARD_TEXT(divider)
			}
	}
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);

@h Two-sided doors.
The I6 implementation of two-way doors and of what, in I7, are called backdrops,
is quite complicated; and the Inter code we generate follows that traditional
form. See the Inform Designer's Manual, fourth edition (the "DM4") for explanations.
We are essentially trying to program all of that automatically, which is why these
awkward multi-purpose I6 properties (|door_to|, |found_in|, etc.) have no direct
I7 equivalents.

These little structures are needed to remember routines to compile later:

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

parse_node *RTMap::door_dir_for_2_sided(instance *I, instance *R1, instance *D1,
	instance *D2) {
	door_dir_notice *notice = CREATE(door_dir_notice);
	notice->ddn_iname =
		Hierarchy::make_iname_in(TSD_DOOR_DIR_FN_HL, RTInstances::package(I));
	notice->door = I;
	notice->R1 = R1;
	notice->D1 = D1;
	notice->D2 = D2;
	return Rvalues::from_iname(notice->ddn_iname);
}

parse_node *RTMap::door_to_for_2_sided(instance *I, instance *R1, instance *R2) {
	door_to_notice *notice = CREATE(door_to_notice);
	notice->dtn_iname =
		Hierarchy::make_iname_in(TSD_DOOR_TO_FN_HL, RTInstances::package(I));
	notice->door = I;
	notice->R1 = R1;
	notice->R2 = R2;
	return Rvalues::from_iname(notice->dtn_iname);
}

parse_node *RTMap::found_in_for_2_sided(instance *I, instance *R1, instance *R2) {
	package_request *PR =
		Hierarchy::package_within(INLINE_PROPERTIES_HAP, RTInstances::package(I));
	inter_name *S = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	packaging_state save = Emit::named_array_begin(S, K_value);
	Emit::array_iname_entry(RTInstances::iname(R1));
	Emit::array_iname_entry(RTInstances::iname(R2));
	Emit::array_end(save);
	Produce::annotate_i(S, INLINE_ARRAY_IANN, 1);
	return Rvalues::from_iname(S);
}

@ Redeeming those notices:

=
void RTMap::write_door_dir_routines(void) {
	door_dir_notice *notice;
	LOOP_OVER(notice, door_dir_notice) {
		packaging_state save = Functions::begin(notice->ddn_iname);
		local_variable *loc = LocalVariables::new_internal_commented(I"loc", I"room of actor");
		inter_symbol *loc_s = LocalVariables::declare(loc);
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Emit::down();
			Produce::ref_symbol(Emit::tree(), K_value, loc_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LOCATION_HL));
		Emit::up();

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(THEDARK_HL));
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, loc_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(REAL_LOCATION_HL));
				Emit::up();
			Emit::up();
		Emit::up();

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(notice->R1));
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value,
						RTInstances::iname(Map::get_value_of_opposite_property(notice->D1)));
				Emit::up();
			Emit::up();
		Emit::up();

		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Emit::down();
			Produce::val_iname(Emit::tree(), K_value,
				RTInstances::iname(Map::get_value_of_opposite_property(notice->D2)));
		Emit::up();

		Functions::end(save);
	}
}

void RTMap::write_door_to_routines(void) {
	door_to_notice *notice;
	LOOP_OVER(notice, door_to_notice) {
		packaging_state save = Functions::begin(notice->dtn_iname);
		local_variable *loc = LocalVariables::new_internal_commented(I"loc", I"room of actor");
		inter_symbol *loc_s = LocalVariables::declare(loc);
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Emit::down();
			Produce::ref_symbol(Emit::tree(), K_value, loc_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LOCATION_HL));
		Emit::up();

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(THEDARK_HL));
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, loc_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(REAL_LOCATION_HL));
				Emit::up();
			Emit::up();
		Emit::up();

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, loc_s);
				Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(notice->R1));
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(notice->R2));
				Emit::up();
			Emit::up();
		Emit::up();

		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Emit::down();
			Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(notice->R1));
		Emit::up();

		Functions::end(save);
	}
}

@ |ident| is an identifier name for the direction instance. It seems redundant
here because surely if we know |I|, we know its runtime representation; but
that's not true -- we need to call this function at a time when the final
identifier names for instance have not yet been settled.

=
void RTMap::set_map_schemas(binary_predicate *bp, instance *I) {
	inter_name *ident = MAP_DATA(I)->direction_iname;
	bp->task_functions[TEST_ATOM_TASK] =
		Calculus::Schemas::new("(MapConnection(*2,%n) == *1)", ident);
	bp->task_functions[NOW_ATOM_TRUE_TASK] =
		Calculus::Schemas::new("AssertMapConnection(*2,%n,*1)", ident);
	bp->task_functions[NOW_ATOM_FALSE_TASK] =
		Calculus::Schemas::new("AssertMapUnconnection(*2,%n,*1)", ident);
}
