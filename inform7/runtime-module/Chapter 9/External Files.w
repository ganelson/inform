[RTExternalFiles::] External Files.

@ External files are written in Inter as their array names:

=
typedef struct external_file_compilation_data {
	struct inter_name *exf_iname;
	struct inter_name *IFID_array_iname;
} external_file_compilation_data;

external_file_compilation_data RTExternalFiles::new_data(wording W) {
	external_file_compilation_data efcd;
	package_request *P = Hierarchy::local_package(EXTERNAL_FILES_HAP);
	efcd.exf_iname = Hierarchy::make_iname_with_memo(FILE_HL, P, W);
	efcd.IFID_array_iname = Hierarchy::make_iname_with_memo(IFID_HL, P, W);
	return efcd;
}

void RTExternalFiles::arrays(void) {
	inter_name *iname = Hierarchy::find(NO_EXTERNAL_FILES_HL);
	Emit::numeric_constant(iname, (inter_ti) (NUMBER_CREATED(files_data)));
	Hierarchy::make_available(Emit::tree(), iname);

	files_data *exf;
	LOOP_OVER(exf, files_data) {
		if (exf->file_ownership == OWNED_BY_SPECIFIC_PROJECT) {
			packaging_state save =
				Emit::named_string_array_begin(exf->compilation_data.IFID_array_iname, K_value);
			TEMPORARY_TEXT(II)
			WRITE_TO(II, "//%S//", exf->IFID_of_owner);
			Emit::array_text_entry(II);
			DISCARD_TEXT(II)
			Emit::array_end(save);
		}
	}

	LOOP_OVER(exf, files_data) {
		packaging_state save = Emit::named_array_begin(exf->compilation_data.exf_iname, K_value);
		Emit::array_iname_entry(Hierarchy::find(AUXF_MAGIC_VALUE_HL));
		Emit::array_iname_entry(Hierarchy::find(AUXF_STATUS_IS_CLOSED_HL));
		if (exf->file_is_binary) Emit::array_numeric_entry(1);
		else Emit::array_numeric_entry(0);
		Emit::array_numeric_entry(0);
		TEMPORARY_TEXT(WW)
		WRITE_TO(WW, "%w", Lexer::word_raw_text(exf->unextended_filename));
		Str::delete_first_character(WW);
		Str::delete_last_character(WW);
		Emit::array_text_entry(WW);
		DISCARD_TEXT(WW)
		switch (exf->file_ownership) {
			case OWNED_BY_THIS_PROJECT: Emit::array_iname_entry(RTBibliographicData::IFID_iname()); break;
			case OWNED_BY_ANOTHER_PROJECT: Emit::array_null_entry(); break;
			case OWNED_BY_SPECIFIC_PROJECT: Emit::array_iname_entry(exf->compilation_data.IFID_array_iname); break;
		}
		Emit::array_end(save);
	}

	iname = Hierarchy::find(TABLEOFEXTERNALFILES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	Emit::array_numeric_entry(0);
	LOOP_OVER(exf, files_data) Emit::array_iname_entry(exf->compilation_data.exf_iname);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}
