[CodeGen::Inventory::] Final Inventory.

To print a summary of the contents of a repository.

@ This target is fairly simple: when we get the message to begin generation,
we simply ask the Inter module to output some text, and return true to
tell the generator that nothing more need be done.

=
void CodeGen::Inventory::create_target(void) {
	code_generation_target *inv_cgt = CodeGen::Targets::new(I"inventory");
	METHOD_ADD(inv_cgt, BEGIN_GENERATION_MTID, CodeGen::Inventory::inv);
}

int CodeGen::Inventory::inv(code_generation_target *cgt, code_generation *gen) {
	if (gen->from_step == NULL) internal_error("temporary generations cannot be output");
	
	Inter::traverse_tree(gen->from, CodeGen::Inventory::visitor,
		gen->from_step->text_out_file, gen->just_this_package, 0);
	return TRUE;
}

void CodeGen::Inventory::visitor(inter_tree *I, inter_frame P, void *state) {
	text_stream *OUT = (text_stream *) state;
	if (P.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *from = Inter::Package::defined_by_frame(P);
		inter_symbol *ptype = Inter::Packages::type(from);

		if (Str::eq(ptype->symbol_name, I"_module")) {
			WRITE("Module '%S'\n", from->package_name->symbol_name);
			text_stream *title = Inter::Packages::read_metadata(from, I"`title");
			if (title) WRITE("From extension '%S by %S' version %S\n", title,
				Inter::Packages::read_metadata(from, I"`author"),
				Inter::Packages::read_metadata(from, I"`version"));
			return;
		}
		
		if (Str::eq(ptype->symbol_name, I"_submodule")) {
			int contents = 0;
			LOOP_THROUGH_INTER_CHILDREN(C, P) contents++;
			if (contents > 0) {
				WRITE("%S:\n", from->package_name->symbol_name);
				INDENT;
					Inter::Packages::unmark_all();
					LOOP_THROUGH_INTER_CHILDREN(C, P) {
						if (C.data[ID_IFLD] == PACKAGE_IST) {
							inter_package *R = Inter::Package::defined_by_frame(C);
							if (CodeGen::marked(R->package_name)) continue;
							inter_symbol *ptype = Inter::Packages::type(R);
							OUTDENT;
							WRITE("  %S ", ptype->symbol_name);
							int N = 0;
							LOOP_THROUGH_INTER_CHILDREN(D, P) {
								if (D.data[ID_IFLD] == PACKAGE_IST) {
									inter_package *R2 = Inter::Package::defined_by_frame(D);
									if (Inter::Packages::type(R2) == ptype) N++;
								}
							}
							WRITE("x %d: ", N);
							INDENT;
							int pos = Str::len(ptype->symbol_name) + 7;
							int first = TRUE;
							LOOP_THROUGH_INTER_CHILDREN(D, P) {
								if (D.data[ID_IFLD] == PACKAGE_IST) {
									inter_package *R2 = Inter::Package::defined_by_frame(D);
									if (Inter::Packages::type(R2) == ptype) {
										text_stream *name = Inter::Packages::read_metadata(R2, I"`name");
										if (name == NULL) name = R2->package_name->symbol_name;
										if ((pos > 0) && (first == FALSE)) WRITE(", ");
										pos += Str::len(name) + 2;
										if (pos > 80) { WRITE("\n"); pos = Str::len(name) + 2; }
										WRITE("%S", name);
										CodeGen::mark(R2->package_name);
										first = FALSE;
									}
								}
							}
							if (pos > 0) WRITE("\n");
						}
					}
					Inter::Packages::unmark_all();
				OUTDENT;
			}
			return;
		}
	}
}
