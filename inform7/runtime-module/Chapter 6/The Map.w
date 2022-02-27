[RTMap::] The Map.

The runtime representation of the spatial map for works of interactive fiction:
that is, how the rooms and doors connect up.

@ One of the few early breaks with I6 practice was that I7 stores the
map differently at run-time compared to earlier I6 games.

The |Map_Storage| array consists only of the |exits| arrays written out
one after another. It looks wasteful of memory, since it is almost always
going to be filled mostly with |0| entries (meaning: no exit that way). But
the memory needs to be there because map connections can be added dynamically
at run-time, so we can't know now how many we will need.

=
int RTMap::compile_model_tables(void) {
	inter_name *ndi = Hierarchy::find(NO_DIRECTIONS_HL);
	Emit::numeric_constant(ndi, (inter_ti) Map::number_of_directions());
	Hierarchy::make_available(ndi);

	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		RTInstances::value_iname(I);
	inter_name *iname = Hierarchy::find(MAP_STORAGE_HL);
	packaging_state save = EmitArrays::begin_word(iname, K_object);
	int words_used = 0;
	if (Task::wraps_existing_storyfile()) {
		EmitArrays::iname_entry(NULL);
		EmitArrays::iname_entry(NULL);
		EmitArrays::iname_entry(NULL);
		EmitArrays::iname_entry(NULL);
		words_used = 4;
	} else {
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object)
			if (Spatial::object_is_a_room(I)) {
				int N = Map::number_of_directions();
				for (int i=0; i<N; i++) {
					instance *to = MAP_EXIT(I, i);
					if (to)
						EmitArrays::iname_entry(RTInstances::value_iname(to));
					else
						EmitArrays::numeric_entry(0);
				}
				words_used++;
			}
	}
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
	return FALSE;
}

@ This may as well be here as anywhere else: it specifies how to read or
change the map, by testing or asserting the "mapped D of" relation for a
given direction D, which appears here in the guise of its instance |I|:

=
void RTMap::set_map_schemas(binary_predicate *bp, instance *I) {
	inter_name *ident = RTInstances::value_iname(I);
	bp->task_functions[TEST_ATOM_TASK] =
		Calculus::Schemas::new("(MapConnection(*2,%n) == *1)", ident);
	bp->task_functions[NOW_ATOM_TRUE_TASK] =
		Calculus::Schemas::new("AssertMapConnection(*2,%n,*1)", ident);
	bp->task_functions[NOW_ATOM_FALSE_TASK] =
		Calculus::Schemas::new("AssertMapUnconnection(*2,%n,*1)", ident);
}
