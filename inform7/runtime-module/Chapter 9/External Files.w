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
	files_data *exf;
	LOOP_OVER(exf, files_data) {
		if (exf->file_ownership == OWNED_BY_SPECIFIC_PROJECT) {
			packaging_state save =
				EmitArrays::begin_string(exf->compilation_data.IFID_array_iname, K_value);
			TEMPORARY_TEXT(II)
			WRITE_TO(II, "//%S//", exf->IFID_of_owner);
			EmitArrays::text_entry(II);
			DISCARD_TEXT(II)
			EmitArrays::end(save);
		}
	}

	LOOP_OVER(exf, files_data) {
		packaging_state save = EmitArrays::begin(exf->compilation_data.exf_iname, K_value);
		EmitArrays::iname_entry(Hierarchy::find(AUXF_MAGIC_VALUE_HL));
		EmitArrays::iname_entry(Hierarchy::find(AUXF_STATUS_IS_CLOSED_HL));
		if (exf->file_is_binary) EmitArrays::numeric_entry(1);
		else EmitArrays::numeric_entry(0);
		EmitArrays::numeric_entry(0);
		TEMPORARY_TEXT(WW)
		WRITE_TO(WW, "%w", Lexer::word_raw_text(exf->unextended_filename));
		Str::delete_first_character(WW);
		Str::delete_last_character(WW);
		EmitArrays::text_entry(WW);
		DISCARD_TEXT(WW)
		switch (exf->file_ownership) {
			case OWNED_BY_THIS_PROJECT: EmitArrays::iname_entry(RTBibliographicData::IFID_iname()); break;
			case OWNED_BY_ANOTHER_PROJECT: EmitArrays::null_entry(); break;
			case OWNED_BY_SPECIFIC_PROJECT: EmitArrays::iname_entry(exf->compilation_data.IFID_array_iname); break;
		}
		EmitArrays::end(save);
	}

	LOOP_OVER(exf, files_data) {
		inter_name *md_iname = Hierarchy::make_iname_in(INSTANCE_FILE_VALUE_METADATA_HL,
			RTInstances::package(exf->as_instance));
		Emit::iname_constant(md_iname, K_value, exf->compilation_data.exf_iname);
	}

	inter_name *iname = Hierarchy::find(NO_EXTERNAL_FILES_HL);
	Produce::annotate_i(iname, SYNOPTIC_IANN, NO_EXTERNAL_FILES_SYNID);
	Emit::numeric_constant(iname, (inter_ti) 0);
	Hierarchy::make_available(iname);

	iname = Hierarchy::find(TABLEOFEXTERNALFILES_HL);
	Produce::annotate_i(iname, SYNOPTIC_IANN, TABLEOFEXTERNALFILES_SYNID);
	packaging_state save = EmitArrays::begin(iname, K_value);
	EmitArrays::end(save);
	Hierarchy::make_available(iname);
}
