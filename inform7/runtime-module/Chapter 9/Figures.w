[RTFigures::] Figures.

@ Just one array will do us:

=
void RTFigures::compile_ResourceIDsOfFigures_array(void) {
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFFIGURES_HL);
	packaging_state save = EmitArrays::begin(iname, K_number);
	EmitArrays::numeric_entry(0);
	figures_data *bf;
	LOOP_OVER(bf, figures_data) EmitArrays::numeric_entry((inter_ti) bf->figure_number);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
}
