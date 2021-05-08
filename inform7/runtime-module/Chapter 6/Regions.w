[RTRegions::] Regions.

@

=
inter_name *RTRegions::found_in_iname(instance *I) {
	if (REGIONS_DATA(I)->in_region_iname == NULL)
		REGIONS_DATA(I)->in_region_iname =
			Hierarchy::make_iname_in(REGION_FOUND_IN_FN_HL, RTInstances::package(I));
	return REGIONS_DATA(I)->in_region_iname;
}

@ =
void RTRegions::write_found_in_functions(void) {
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		if (Instances::of_kind(I, K_region)) {
			inter_name *iname = RTRegions::found_in_iname(I);
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

