[RTSounds::] Sound Effects.

@ Just one array will do us:

=
int RTSounds::compile_ResourceIDsOfSounds_array(int stage, int debugging) {
	if (stage != 1) return FALSE;
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFSOUNDS_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	Emit::array_numeric_entry(0);
	sounds_data *bs;
	LOOP_OVER(bs, sounds_data) Emit::array_numeric_entry((inter_ti) bs->sound_number);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
	return FALSE;
}
