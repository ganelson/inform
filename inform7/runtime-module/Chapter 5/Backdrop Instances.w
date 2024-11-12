[RTBackdropInstances::] Backdrop Instances.

Some additions to an _instance package for instances of the kind "backdrop".

@h Compilation data.
This additional data is present only if the "backdrops" feature is active:

=
inter_name *RTBackdropInstances::found_in_val(instance *I, int many) {
	if (BACKDROPS_DATA(I)->found_in_fn_iname == NULL)
		BACKDROPS_DATA(I)->found_in_fn_iname =
			Hierarchy::make_iname_in(BACKDROP_FOUND_IN_FN_HL, RTInstances::package(I));
	BACKDROPS_DATA(I)->many_places = many;
	return BACKDROPS_DATA(I)->found_in_fn_iname;
}

@h Compilation.
We add a |found_in| function to test whether the given backdrop is found in
the current |location| or not.

=
void RTBackdropInstances::compile_extra(instance *I) {
	if ((K_backdrop) && (Instances::of_kind(I, K_backdrop)) &&
		(BACKDROPS_DATA(I)->found_in_fn_iname)) {
		if (BACKDROPS_DATA(I)->many_places)
			@<The object is found in many rooms or in whole regions@>
		else
			@<The object is found nowhere@>;		
	}
}

@<The object is found in many rooms or in whole regions@> =
	packaging_state save = Functions::begin(BACKDROPS_DATA(I)->found_in_fn_iname);
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), found_in_inf) {
		instance *loc = Backdrops::get_inferred_location(inf);
		EmitCode::inv(IF_BIP);
		EmitCode::down();
		if ((K_region) && (Instances::of_kind(loc, K_region))) {
			EmitCode::call(Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(LOCATION_HL));
				EmitCode::val_iname(K_object, RTInstances::value_iname(loc));
			EmitCode::up();
		} else {
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(LOCATION_HL));
				EmitCode::val_iname(K_object, RTInstances::value_iname(loc));
			EmitCode::up();
		}
			EmitCode::code();
			EmitCode::down();
				EmitCode::rtrue();
			EmitCode::up();
		EmitCode::up();
	}
	EmitCode::rfalse();
	Functions::end(save);

@<The object is found nowhere@> =
	packaging_state save = Functions::begin(BACKDROPS_DATA(I)->found_in_fn_iname);
	EmitCode::rfalse();
	Functions::end(save);
