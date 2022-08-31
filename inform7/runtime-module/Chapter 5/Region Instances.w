[RTRegionInstances::] Region Instances.

Some additions to an _instance package for instances of the kind "region".

@h Compilation data.
This additional data is present only if the "regions" feature is active:

=
inter_name *RTRegionInstances::found_in_iname(instance *I) {
	if (REGIONS_DATA(I)->in_region_iname == NULL)
		REGIONS_DATA(I)->in_region_iname =
			Hierarchy::make_iname_in(REGION_FOUND_IN_FN_HL, RTInstances::package(I));
	return REGIONS_DATA(I)->in_region_iname;
}

@h Compilation.
So, we add a single extra function, which performs the test of whether the
player's current location lies in the given region.

=
void RTRegionInstances::compile_extra(instance *I) {
	if ((K_region) && (Instances::of_kind(I, K_region))) {
		inter_name *iname = RTRegionInstances::found_in_iname(I);
		packaging_state save = Functions::begin(iname);
		EmitCode::inv(IF_BIP);
		EmitCode::down();
				EmitCode::call(Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
				EmitCode::down();
					EmitCode::val_iname(K_object, Hierarchy::find(LOCATION_HL));
					EmitCode::val_iname(K_object, RTInstances::value_iname(I));
				EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::rtrue();
			EmitCode::up();
		EmitCode::up();
		EmitCode::rfalse();
		Functions::end(save);
	}
}
