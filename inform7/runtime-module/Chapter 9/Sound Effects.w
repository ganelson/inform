[RTSounds::] Sound Effects.

@ Easy:

=
void RTSounds::compile_metadata(void) {
	sounds_data *bs;
	LOOP_OVER(bs, sounds_data) {
		inter_name *md_iname = Hierarchy::make_iname_in(INSTANCE_SOUND_ID_METADATA_HL,
			RTInstances::package(bs->as_instance));
		Emit::numeric_constant(md_iname, (inter_ti) bs->sound_number);
	}
}
