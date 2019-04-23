[CodeGen::Inventory::] Inventory.

To print a summary of the contents of a repository.

@h The whole shebang.

=
void CodeGen::Inventory::print(OUTPUT_STREAM, inter_repository *I) {
	if (I == NULL) internal_error("no repository");
	inter_package *main_package = Inter::Packages::main(I);
	for (inter_package *M = main_package->child_package; M; M = M->next_package) {
		WRITE("Module '%S'\n", M->package_name->symbol_name);
		text_stream *title = CodeGen::Inventory::read_metadata(M, I"`title");
		if (title) WRITE("From extension '%S by %S' version %S\n", title,
			CodeGen::Inventory::read_metadata(M, I"`author"),
			CodeGen::Inventory::read_metadata(M, I"`version"));
		if (Str::ne(M->package_name->symbol_name, I"template")) {
			INDENT;
			for (inter_package *SM = M->child_package; SM; SM = SM->next_package) {
				if (SM->child_package) {
					WRITE("%S:\n", SM->package_name->symbol_name);
					INDENT;
						for (inter_package *R = SM->child_package; R; R = R->next_package)
							CodeGen::unmark(R->package_name);
						for (inter_package *R = SM->child_package; R; R = R->next_package) {
							if (CodeGen::marked(R->package_name)) continue;
							inter_symbol *ptype = Inter::Packages::type(R);
							OUTDENT;
							WRITE("  %S ", ptype->symbol_name);
							int N = 1;
							for (inter_package *R2 = R->next_package; R2; R2 = R2->next_package)
								if (Inter::Packages::type(R2) == ptype)
									N++;
							WRITE("x %d: ", N);
							INDENT;
							int pos = Str::len(ptype->symbol_name) + 7;
							int first = TRUE;
							for (inter_package *R2 = R; R2; R2 = R2->next_package) {
								if (Inter::Packages::type(R2) == ptype) {
									text_stream *name = CodeGen::Inventory::read_metadata(R2, I"`name");
									if (name == NULL) name = R2->package_name->symbol_name;
									if ((pos > 0) && (first == FALSE)) WRITE(", ");
									pos += Str::len(name) + 2;
									if (pos > 80) { WRITE("\n"); pos = Str::len(name) + 2; }
									WRITE("%S", name);
									CodeGen::mark(R2->package_name);
									first = FALSE;
								}
							}
							if (pos > 0) WRITE("\n");
						}
						for (inter_package *R = SM->child_package; R; R = R->next_package)
							CodeGen::unmark(R->package_name);
					OUTDENT;
				}
			}
			OUTDENT;
		}
	}
}

text_stream *CodeGen::Inventory::read_metadata(inter_package *P, text_stream *key) {
	if (P == NULL) return NULL;
	inter_symbol *found = Inter::SymbolsTables::symbol_from_name(Inter::Packages::scope(P), key);
	if ((found) && (Inter::Symbols::is_defined(found))) {
		inter_frame F = Inter::Symbols::defining_frame(found);
		inter_t val2 = F.data[VAL1_MD_IFLD + 1];
		return Inter::get_text(P->stored_in, val2);
	}
	return NULL;
}
