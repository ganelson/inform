[RTActionBitmaps::] Action Bitmap Property.

To compile tiny arrays as values of the action_bitmap property.

@ This is all in service of a feature I would quite like to lose: recording,
with a flag, which actions have happened to which objects. We store this bitmap
in 16-bit fields inside an array of words; on a 32-bit VM, that wastes the
remaining bits, but then on a 32-bit VN memory is not scarce in quite that way.

=
parse_node *RTActionBitmaps::compile_action_bitmap_property(inference_subject *subj) {
	package_request *R = RTPropertyPermissions::home(subj);
	inter_name *N = NULL;
	instance *I = InstanceSubjects::to_instance(subj);
	if (I) {
		package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, R);
		N = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	} else {
		package_request *PR = Hierarchy::package_within(KIND_INLINE_PROPERTIES_HAP, R);
		N = Hierarchy::make_iname_in(KIND_INLINE_PROPERTY_HL, PR);
	}
	packaging_state save = EmitArrays::begin_inline(N, K_number);
	for (int i=0; i<=((NUMBER_CREATED(action_name))/16); i++) EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	return Rvalues::from_iname(N);
}
