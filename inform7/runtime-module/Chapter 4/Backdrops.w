[RTBackdrops::] Backdrops.

@ Just one array will do us:

=
typedef struct backdrop_found_in_notice {
	struct instance *backdrop;
	struct inter_name *found_in_routine_iname;
	int many_places;
	CLASS_DEFINITION
} backdrop_found_in_notice;

parse_node *RTBackdrops::found_in_val(instance *I, int many) {
	backdrop_found_in_notice *notice = CREATE(backdrop_found_in_notice);
	notice->backdrop = I;
	package_request *R = RTInstances::package(I);
	notice->found_in_routine_iname = Hierarchy::make_iname_in(BACKDROP_FOUND_IN_FN_HL, R);
	notice->many_places = many;
	return Rvalues::from_iname(notice->found_in_routine_iname);
}

@ =
void RTBackdrops::write_found_in_routines(void) {
	backdrop_found_in_notice *notice;
	LOOP_OVER(notice, backdrop_found_in_notice) {
		instance *I = notice->backdrop;
		if (notice->many_places)
			@<The object is found in many rooms or in whole regions@>
		else
			@<The object is found nowhere@>;
	}
}

@<The object is found in many rooms or in whole regions@> =
	packaging_state save = Functions::begin(notice->found_in_routine_iname);
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), found_in_inf) {
		instance *loc = Backdrops::get_inferred_location(inf);
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
		if ((K_region) && (Instances::of_kind(loc, K_region))) {
			Produce::inv_call_iname(Emit::tree(),
				Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(LOCATION_HL));
				Produce::val_iname(Emit::tree(), K_object, RTInstances::iname(loc));
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(LOCATION_HL));
				Produce::val_iname(Emit::tree(), K_object, RTInstances::iname(loc));
			Produce::up(Emit::tree());
		}
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::rtrue(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Produce::rfalse(Emit::tree());
		break;
	}
	Functions::end(save);

@<The object is found nowhere@> =
	packaging_state save = Functions::begin(notice->found_in_routine_iname);
	Produce::rfalse(Emit::tree());
	Functions::end(save);
