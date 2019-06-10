[CodeGen::Import::] Import.

To import inter from a secondary file.

@h Pipeline stage.

=
void CodeGen::Import::create_pipeline_stage(void) {
	pipeline_stage *im = CodeGen::Stage::new(I"import", CodeGen::Import::run_pipeline_stage, FILE_STAGE_ARG);
	im->port_direction = -1;
}

int CodeGen::Import::run_pipeline_stage(stage_step *step) {
	CodeGen::Import::import(step->repository, step->parsed_filename);
	return TRUE;
}

@h Link.

=
void CodeGen::Import::import(inter_repository *I, filename *F) {
	if (I == NULL) internal_error("no inter to import to");

	inter_repository *I2 = Inter::create(2, 1024);

	LOG("Import inter file: %f\n", F);

	if (Inter::Binary::test_file(F)) Inter::Binary::read(I2, F);
	else Inter::Textual::read(I2, F);

	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I2) {
		if (P.data[ID_IFLD] == CONSTANT_IST) {
			inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			text_stream *S = con_name->symbol_name;
			inter_symbol *already =
				Inter::SymbolsTables::symbol_from_name_in_main_or_basics(I, S);
			if (already) {
				inter_frame P2 = Inter::Symbols::defining_frame(already);
				if ((P.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
					(P2.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
					(P.data[DATA_CONST_IFLD] == LITERAL_IVAL) &&
					(P2.data[DATA_CONST_IFLD] == LITERAL_IVAL) &&
					(P.data[DATA_CONST_IFLD+1] == P2.data[DATA_CONST_IFLD+1])) {
					Inter::Nop::nop_out(I2, P);
				} else {
					Inter::Nop::nop_out(I2, P);
				}
			}
		}
	}

	dictionary *D2 = CodeGen::Import::export_dictionary(I2);

	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == IMPORT_IST) {
			inter_symbol *symbol = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_IMPORT_IFLD);
			inter_t ID = P.data[TEXT_IMPORT_IFLD];
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
			dict_entry *de = Dictionaries::find(D2, S);
			if (de) {
				inter_symbol *symbol2 = (inter_symbol *) Dictionaries::read_value(D2, S);
				LOG("My %S == its %S ('%S')\n", symbol?(symbol->symbol_name):I"NULL", symbol2?(symbol2->symbol_name):I"NULL", S);
				if ((symbol == NULL) || (symbol2 == NULL)) internal_error("null import/export symbols");
				Inter::Symbols::set_bridge(symbol, symbol2);
				Inter::Symbols::set_bridge(symbol2, symbol);
			} else {
				TEMPORARY_TEXT(erm);
				WRITE_TO(erm, "It proved impossible to import the rule '%S' (my symbol %S) in the Standard Rules.\n",
					S, symbol?(symbol->symbol_name):I"NULL");
				WRITE_TO(STDERR, "%S", erm);
				internal_error("importation error");
				DISCARD_TEXT(erm);
			}
		}
}

void CodeGen::Import::cmp_symbol(inter_symbol *symbol, inter_symbol *symbol2, text_stream *S) {
	if ((symbol) && (symbol2)) {
		inter_symbol *cb1 = Inter::Constant::code_block(symbol);
		inter_symbol *cb2 = Inter::Constant::code_block(symbol2);
		LOG("My CB %S == its CB %S\n", cb1?(cb1->symbol_name):I"NULL", cb2?(cb2->symbol_name):I"NULL");

		if ((cb1) && (cb2)) {
			inter_frame_list *ifl1 = Inter::Package::code_list(cb1);
			inter_frame_list *ifl2 = Inter::Package::code_list(cb2);
			if ((ifl1 == NULL) || (ifl2 == NULL)) internal_error("oopsie");

			CodeGen::Import::cmp(ifl1, ifl2, S);
		}
	}
}

void CodeGen::Import::cmp(inter_frame_list *ifl1, inter_frame_list *ifl2, text_stream *S) {
	inter_frame X1;
	inter_frame X2;
	if ((ifl1 == NULL) || (ifl2 == NULL)) { LOG("Null IFLs mean no match\n"); return; }
	inter_frame_list_entry *ifl2_entry = ifl2->first_in_ifl;
	int N = 0;
	LOOP_THROUGH_INTER_FRAME_LIST(X1, ifl1) {
		N++;
		if (Inter::Frame::valid(((X2 = ifl2_entry->listed_frame), &X2))) {
			if (X1.data[ID_IFLD] != X2.data[ID_IFLD]) {
				internal_error("nonmatching ilds");
			}
			LOG("%d: %d\n", N, X1.data[ID_IFLD]);
			Inter::Defn::write_construct_text(DL, X1);
			if (X1.data[ID_IFLD] == LABEL_IST) {
				inter_frame_list *lifl1 = Inter::find_frame_list(X1.repo_segment->owning_repo, X1.data[CODE_LABEL_IFLD]);
				inter_frame_list *lifl2 = Inter::find_frame_list(X2.repo_segment->owning_repo, X2.data[CODE_LABEL_IFLD]);
				CodeGen::Import::cmp(lifl1, lifl2, S);
			}
			if (X1.data[ID_IFLD] == SPLAT_IST) {
				text_stream *S1 = Inter::get_text(X1.repo_segment->owning_repo, X1.data[MATTER_SPLAT_IFLD]);
				text_stream *S2 = Inter::get_text(X2.repo_segment->owning_repo, X2.data[MATTER_SPLAT_IFLD]);
				if (Str::ne(S1, S2)) {
					LOG("Ooops: S1 = %S\nS2 = %S\n", S1, S2);
					WRITE_TO(STDERR, "Bad match: %S\nInternal: %S\nExternal: %S\n", S, S1, S2);
					internal_error("no match");
				} else {
					LOG("They match! %d\n", Str::len(S1));
				}
			}
		} else internal_error("diff lengths");
		ifl2_entry = ifl2_entry->next_in_ifl;
	}
	LOG("Scanned IFL size %d\n", N);
}

dictionary *CodeGen::Import::export_dictionary(inter_repository *I) {
	dictionary *D = Dictionaries::new(INITIAL_INTER_SYMBOLS_ID_RANGE, FALSE);
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I)
		if (P.data[ID_IFLD] == EXPORT_IST) {
			inter_symbol *symbol = Inter::SymbolsTables::symbol_from_frame_data(P, SYMBOL_EXPORT_IFLD);
			inter_t ID = P.data[TEXT_EXPORT_IFLD];
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, ID);
			Dictionaries::create(D, S);
			Dictionaries::write_value(D, S, (void *) symbol);
		}
	return D;
}
