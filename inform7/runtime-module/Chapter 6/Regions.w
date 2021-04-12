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
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Emit::down();
					Produce::inv_call_iname(Emit::tree(),
						Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
					Emit::down();
						Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(LOCATION_HL));
						Produce::val_iname(Emit::tree(), K_object, RTInstances::iname(I));
					Emit::up();
				Produce::code(Emit::tree());
				Emit::down();
					Produce::rtrue(Emit::tree());
				Emit::up();
			Emit::up();
			Produce::rfalse(Emit::tree());
			Functions::end(save);
		}
}

