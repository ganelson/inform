[CodeGen::Eliminate::] Eliminate Redundant Matter.

To reconcile clashes between assimilated and originally generated verbs.

@h Parsing.

=
int notes_made = 0;
void CodeGen::Eliminate::go(inter_repository *I) {
	CodeGen::Eliminate::keep(I, I"Main");
	CodeGen::Eliminate::keep(I, I"DefArt");
	CodeGen::Eliminate::keep(I, I"CDefArt");
	CodeGen::Eliminate::keep(I, I"IndefArt");
	CodeGen::Eliminate::keep(I, I"I7_String");
	CodeGen::Eliminate::keep(I, I"R_Process");

	inter_repository *repos[MAX_REPOS_AT_ONCE];
	int no_repos = CodeGen::repo_list(I, repos);

	for (int j=0; j<no_repos; j++) {
		inter_repository *J = repos[j];
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, J) {
			Inter::Defn::callback_dependencies(P, &(CodeGen::Eliminate::note), I);
		}
		LOOP_THROUGH_FRAMES(P, J) {
			if (P.data[ID_IFLD] == CONSTANT_IST) {
				inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
				if ((con_name) && (Inter::Symbols::get_flag(con_name, USED_MARK_BIT)) &&
					(Inter::Symbols::read_annotation(con_name, ACTION_IANN) == 1)) {
					TEMPORARY_TEXT(blurg);
					WRITE_TO(blurg, "%SSub", con_name->symbol_name);
					Str::delete_first_character(blurg);
					Str::delete_first_character(blurg);
					inter_symbol *IS = Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope_of(P), blurg);
					if (IS) Inter::Symbols::set_flag(IS, USED_MARK_BIT);
					DISCARD_TEXT(blurg);
				}
			}
		}
	}
//	LOG("notes_made = %d\n", notes_made);
//	LOG("The following routines are unnecessary:\n");
	for (int j=0; j<no_repos; j++) {
		inter_repository *J = repos[j];
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, J) {
			if (P.data[ID_IFLD] == CONSTANT_IST) {
				inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
				if ((con_name) && (Inter::Constant::is_routine(con_name)) &&
					(Inter::Symbols::get_flag(con_name, USED_MARK_BIT) == FALSE)) {
					int consecutives = 0, keep_me = FALSE;
					LOOP_THROUGH_TEXT(pos, con_name->symbol_name) {
						if (Str::get(pos) == '_') consecutives++;
						else if (consecutives >= 2) keep_me = TRUE;
						else consecutives = 0;
					}
					if (keep_me == FALSE) {
//						LOG("-- %S %08x\n", con_name->symbol_name, con_name);
						Inter::Nop::nop_out(J, P);
					}
				}
			}
		}
	}

//	LOG("The following table arrays are unnecessary:\n");
	for (int j=0; j<no_repos; j++) {
		inter_repository *J = repos[j];
		inter_frame P;
		LOOP_THROUGH_FRAMES(P, J) {
			if (P.data[ID_IFLD] == CONSTANT_IST) {
				inter_symbol *con_name = Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
				if ((con_name) && (P.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_LIST) &&
					(Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == FALSE) &&
					(Inter::Symbols::get_flag(con_name, USED_MARK_BIT) == FALSE)) {
					int consecutives = 0, keep_me = FALSE;
					LOOP_THROUGH_TEXT(pos, con_name->symbol_name) {
						if (Str::get(pos) == '_') consecutives++;
						else if (consecutives >= 2) keep_me = TRUE;
						else consecutives = 0;
					}
					if (keep_me == FALSE) {
//						LOG("-- %S\n", con_name->symbol_name);
						Inter::Nop::nop_out(J, P);
					}
				}
			}
		}
	}
}

void CodeGen::Eliminate::keep(inter_repository *I, text_stream *N) {
	inter_symbol *S = Inter::SymbolsTables::symbol_from_name_in_main(I, N);
	if (S) Inter::Symbols::set_flag(S, USED_MARK_BIT);
}

void CodeGen::Eliminate::note(inter_symbol *S, inter_symbol *T, void *state) {
	inter_repository *I = (inter_repository *) state;
	inter_symbol *Tdash = Inter::SymbolsTables::symbol_from_name_in_main(I, T->symbol_name);
	if (Tdash) {
		Inter::Symbols::set_flag(Tdash, USED_MARK_BIT);
//		LOG("Note %S %08x\n", Tdash?(Tdash->symbol_name):I"<null>", Tdash);
	} else {
		Inter::Symbols::set_flag(T, USED_MARK_BIT);
	}

	notes_made++;
}
