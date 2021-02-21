[RTFigures::] Figures.

@ Just one array will do us:

=
void RTFigures::compile_ResourceIDsOfFigures_array(void) {
	if (PluginManager::active(figures_plugin) == FALSE) return;
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFFIGURES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	Emit::array_numeric_entry(0);
	figures_data *bf;
	LOOP_OVER(bf, figures_data) Emit::array_numeric_entry((inter_ti) bf->figure_number);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}
