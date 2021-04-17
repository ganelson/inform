[RTSounds::] Sound Effects.

@ Just one array will do us:

=
void RTSounds::compile_ResourceIDsOfSounds_array(void) {
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFSOUNDS_HL);
	packaging_state save = EmitArrays::begin(iname, K_number);
	EmitArrays::numeric_entry(0);
	sounds_data *bs;
	LOOP_OVER(bs, sounds_data) EmitArrays::numeric_entry((inter_ti) bs->sound_number);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
}
