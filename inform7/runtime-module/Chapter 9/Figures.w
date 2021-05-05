[RTFigures::] Figures.

@ Easy:

=
void RTFigures::compile_metadata(void) {
	figures_data *bf;
	LOOP_OVER(bf, figures_data) {
		inter_name *md_iname = Hierarchy::make_iname_in(INSTANCE_FIGURE_ID_METADATA_HL,
			RTInstances::package(bf->as_instance));
		Emit::numeric_constant(md_iname, (inter_ti) bf->figure_number);
	}
}
