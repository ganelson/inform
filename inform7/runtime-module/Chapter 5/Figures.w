[RTFigures::] Figures.

@ Just one array will do us:

=
int RTFigures::compile_ResourceIDsOfFigures_array(int stage, int debugging) {
	if (stage != 1) return FALSE;
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFFIGURES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	Emit::array_numeric_entry(0);
	figures_data *bf;
	LOOP_OVER(bf, figures_data) Emit::array_numeric_entry((inter_ti) bf->figure_number);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
	return FALSE;
}
