[RTSounds::] Sound Effects.

@ Just one array will do us:

=
void RTSounds::compile_metadata(void) {
	sounds_data *bs;
	LOOP_OVER(bs, sounds_data) {
		inter_name *md_iname = Hierarchy::make_iname_in(INSTANCE_SOUND_ID_METADATA_HL,
			RTInstances::package(bs->as_instance));
		Emit::numeric_constant(md_iname, (inter_ti) bs->sound_number);
	}
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFSOUNDS_HL);
	Produce::annotate_i(iname, SYNOPTIC_IANN, RESOURCEIDSOFSOUNDS_SYNID);
	packaging_state save = EmitArrays::begin(iname, K_value);
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}
