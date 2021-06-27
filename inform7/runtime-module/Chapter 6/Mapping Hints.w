[RTMappingHints::] Mapping Hints.

To transcribe mapping hints for the World Index into suitable packages.

@ To put it mildly, this does nothing at all clever:

=
void RTMappingHints::compile(void) {
	mapping_hint *hint;
	LOOP_OVER(hint, mapping_hint) {
		package_request *P = Hierarchy::completion_package(MAPPING_HINTS_HAP);
		if ((hint->dir) && (hint->as_dir)) {
			Hierarchy::apply_metadata_from_iname(P, MH_DIR_HL,
				RTInstances::value_iname(hint->dir));
			Hierarchy::apply_metadata_from_iname(P, MH_AS_DIR_HL,
				RTInstances::value_iname(hint->as_dir));
		} else if ((hint->from) && (hint->dir)) {
			Hierarchy::apply_metadata_from_iname(P, MH_FROM_HL,
				RTInstances::value_iname(hint->from));
			Hierarchy::apply_metadata_from_iname(P, MH_TO_HL,
				RTInstances::value_iname(hint->to));
			Hierarchy::apply_metadata_from_iname(P, MH_DIR_HL,
				RTInstances::value_iname(hint->dir));
		} else if (hint->name) {
			RTMappingHints::apply_metadata_from_wide_string(P, MH_NAME_HL, hint->name);
			Hierarchy::apply_metadata_from_number(P, MH_SCOPE_LEVEL_HL,
				(inter_ti) (hint->scope_level));
			Hierarchy::apply_metadata_from_iname(P, MH_SCOPE_INSTANCE_HL,
				RTInstances::value_iname(hint->scope_I));
			RTMappingHints::apply_metadata_from_wide_string(P, MH_TEXT_HL, hint->put_string);
			Hierarchy::apply_metadata_from_number(P, MH_NUMBER_HL,
				(inter_ti) (hint->put_integer));
		} else if (hint->annotation) {
			RTMappingHints::apply_metadata_from_wide_string(P, MH_ANNOTATION_HL, hint->annotation);
			Hierarchy::apply_metadata_from_number(P, MH_POINT_SIZE_HL,
				(inter_ti) (hint->point_size));
			RTMappingHints::apply_metadata_from_wide_string(P, MH_FONT_HL, hint->font);
			RTMappingHints::apply_metadata_from_wide_string(P, MH_COLOUR_HL, hint->colour);
			Hierarchy::apply_metadata_from_number(P, MH_OFFSET_HL,
				(inter_ti) (hint->at_offset));
			Hierarchy::apply_metadata_from_iname(P, MH_OFFSET_FROM_HL,
				RTInstances::value_iname(hint->offset_from));
		}
	}
}

void RTMappingHints::apply_metadata_from_wide_string(package_request *P, int hl, wchar_t *wide) {
	text_stream *S = Str::new();
	WRITE_TO(S, "%w", wide);
	Hierarchy::apply_metadata(P, hl, S);
}
