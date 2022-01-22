[RTDoors::] Door Instances.

Property values for two-sided doors to make them interconnect with the map
at runtime.

@ The I6 implementation of two-way doors is quite complicated; see the Inform
Designer's Manual, fourth edition (the "DM4") for explanations, but basically
it means giving instances of such doors three low-level properties --

(*) |door_dir|, the map direction through the door;
(*) |door_to|, the room on the other side;
(*) |found_in|, the two rooms in which the door is located.

We continue to use that implementation because there is no pressing reason to
change it: I7 authors are never even aware of how this is all done, and do not
have to see or think about these properties.

@h Door direction.

=
typedef struct door_dir_notice {
	struct inter_name *ddn_iname;
	struct instance *door;
	struct instance *R1;
	struct instance *D1;
	struct instance *D2;
	CLASS_DEFINITION
} door_dir_notice;

parse_node *RTDoors::door_dir_for_2_sided(instance *I, instance *R1, instance *D1,
	instance *D2) {
	door_dir_notice *notice = CREATE(door_dir_notice);
	notice->ddn_iname =
		Hierarchy::make_iname_in(TSD_DOOR_DIR_FN_HL, RTInstances::package(I));
	notice->door = I;
	notice->R1 = R1;
	notice->D1 = D1;
	notice->D2 = D2;
	text_stream *desc = Str::new();
	WRITE_TO(desc, "door_dir for "); Instances::write(desc, I);
	Sequence::queue(&RTDoors::door_dir_agent, STORE_POINTER_door_dir_notice(notice), desc);
	return Rvalues::from_iname(notice->ddn_iname);
}

@ So, then, this is a function: see the DM4 for specification.

=
void RTDoors::door_dir_agent(compilation_subtask *t) {
	door_dir_notice *notice = RETRIEVE_POINTER_door_dir_notice(t->data);
	packaging_state save = Functions::begin(notice->ddn_iname);
	local_variable *loc = LocalVariables::new_internal_commented(I"loc", I"room of actor");
	inter_symbol *loc_s = LocalVariables::declare(loc);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, loc_s);
		EmitCode::val_iname(K_value, Hierarchy::find(LOCATION_HL));
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, loc_s);
			EmitCode::val_iname(K_value, Hierarchy::find(THEDARK_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, loc_s);
				EmitCode::val_iname(K_value, Hierarchy::find(REAL_LOCATION_HL));
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, loc_s);
			EmitCode::val_iname(K_value, RTInstances::value_iname(notice->R1));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value,
					RTInstances::value_iname(Map::get_value_of_opposite_property(notice->D1)));
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value,
			RTInstances::value_iname(Map::get_value_of_opposite_property(notice->D2)));
	EmitCode::up();

	Functions::end(save);
}

@h Door to.

=
typedef struct door_to_notice {
	struct inter_name *dtn_iname;
	struct instance *door;
	struct instance *R1;
	struct instance *R2;
	CLASS_DEFINITION
} door_to_notice;

parse_node *RTDoors::door_to_for_2_sided(instance *I, instance *R1, instance *R2) {
	door_to_notice *notice = CREATE(door_to_notice);
	notice->dtn_iname =
		Hierarchy::make_iname_in(TSD_DOOR_TO_FN_HL, RTInstances::package(I));
	notice->door = I;
	notice->R1 = R1;
	notice->R2 = R2;
	text_stream *desc = Str::new();
	WRITE_TO(desc, "door_to for "); Instances::write(desc, I);
	Sequence::queue(&RTDoors::door_to_agent, STORE_POINTER_door_to_notice(notice), desc);
	return Rvalues::from_iname(notice->dtn_iname);
}

@ Another function: see the DM4 for specification.

=
void RTDoors::door_to_agent(compilation_subtask *t) {
	door_to_notice *notice = RETRIEVE_POINTER_door_to_notice(t->data);
	packaging_state save = Functions::begin(notice->dtn_iname);
	local_variable *loc = LocalVariables::new_internal_commented(I"loc", I"room of actor");
	inter_symbol *loc_s = LocalVariables::declare(loc);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, loc_s);
		EmitCode::val_iname(K_value, Hierarchy::find(LOCATION_HL));
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, loc_s);
			EmitCode::val_iname(K_value, Hierarchy::find(THEDARK_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, loc_s);
				EmitCode::val_iname(K_value, Hierarchy::find(REAL_LOCATION_HL));
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, loc_s);
			EmitCode::val_iname(K_value, RTInstances::value_iname(notice->R1));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTInstances::value_iname(notice->R2));
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, RTInstances::value_iname(notice->R1));
	EmitCode::up();

	Functions::end(save);
}

@h Found in.
And this is a two-element array, simply giving the two rooms |R1| and |R2|
which the door is found in:

=
parse_node *RTDoors::found_in_for_2_sided(instance *I, instance *R1, instance *R2) {
	package_request *PR =
		Hierarchy::package_within(INLINE_PROPERTIES_HAP, RTInstances::package(I));
	inter_name *S = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	packaging_state save = EmitArrays::begin_word(S, K_value);
	EmitArrays::iname_entry(RTInstances::value_iname(R1));
	EmitArrays::iname_entry(RTInstances::value_iname(R2));
	EmitArrays::end(save);
	InterNames::annotate_i(S, INLINE_ARRAY_IANN, 1);
	return Rvalues::from_iname(S);
}
