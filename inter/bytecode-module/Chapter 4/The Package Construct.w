[PackageInstruction::] The Package Construct.

Defining the package construct.

@


=
void PackageInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PACKAGE_IST, I"package");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_PACKAGE_IFLD, -1);
	InterInstruction::specify_syntax(IC, I"package IDENTIFIER _IDENTIFIER");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_PACKAGE_IFR, EXTENT_PACKAGE_IFR);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PackageInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, PackageInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PackageInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PackageInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, PackageInstruction::verify_children);
}

@

@d DEFN_PACKAGE_IFLD 2
@d PTYPE_PACKAGE_IFLD 3
@d SYMBOLS_PACKAGE_IFLD 4
@d PID_PACKAGE_IFLD 5

@d EXTENT_PACKAGE_IFR 6

=
void PackageInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *ptype_name = LargeScale::package_type(InterBookmark::tree(IBM), ilp->mr.exp[1]);

	inter_package *pack = NULL;
	*E = PackageInstruction::new_package_named(IBM, ilp->mr.exp[0], FALSE, ptype_name, (inter_ti) ilp->indent_level, eloc, &pack);
	if (*E) return;

	InterBookmark::move_into_package(IBM, pack);
}

inter_error_message *PackageInstruction::new_package_named(inter_bookmark *IBM, text_stream *name, int uniquely,
	inter_symbol *ptype_name, inter_ti level, inter_error_location *eloc, inter_package **created) {
	if (uniquely) {
		TEMPORARY_TEXT(mutable)
		WRITE_TO(mutable, "%S", name);
		inter_package *pack;
		int N = 1, A = 0;
		while ((pack = InterPackage::from_name(InterBookmark::package(IBM), mutable)) != NULL) {
			TEMPORARY_TEXT(TAIL)
			WRITE_TO(TAIL, "_%d", N++);
			if (A > 0) Str::truncate(mutable, Str::len(mutable) - A);
			A = Str::len(TAIL);
			WRITE_TO(mutable, "%S", TAIL);
			Str::truncate(mutable, 31);
			DISCARD_TEXT(TAIL)
		}
		inter_error_message *E = PackageInstruction::new_package(IBM, mutable, ptype_name, level, eloc, created);
		DISCARD_TEXT(mutable)
		return E;
	}
	return PackageInstruction::new_package(IBM, name, ptype_name, level, eloc, created);
}

inter_error_message *PackageInstruction::new_package(inter_bookmark *IBM, text_stream *name_text, inter_symbol *ptype_name, inter_ti level, inter_error_location *eloc, inter_package **created) {
	inter_ti STID = InterWarehouse::create_symbols_table(InterBookmark::warehouse(IBM));
	inter_error_message *E = NULL;
	inter_symbol *package_name = TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), name_text, &E);
	if (E) return E;
	inter_tree_node *P = Inode::new_with_4_data_fields(IBM,
		PACKAGE_IST,
		InterSymbolsTable::id_from_symbol_at_bookmark(IBM, package_name),
		InterSymbolsTable::id_from_symbol(InterBookmark::tree(IBM), NULL, ptype_name),
		STID, 0, eloc, level);
	inter_ti PID = InterWarehouse::create_package(InterBookmark::warehouse(IBM), InterBookmark::tree(IBM));
	inter_package *pack = InterWarehouse::get_package(InterBookmark::warehouse(IBM), PID);
	pack->package_head = P;
	P->W.instruction[PID_PACKAGE_IFLD] = PID;
	InterPackage::set_scope(pack, InterWarehouse::get_symbols_table(InterBookmark::warehouse(IBM), STID));
	InterWarehouse::set_symbols_table_owner(InterBookmark::warehouse(IBM), STID, pack);

	E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);

	LargeScale::note_package_name(InterPackage::tree(InterBookmark::package(IBM)), pack, name_text);
	if (Str::eq(InterSymbol::identifier(ptype_name), I"_code"))
		InterPackage::mark_as_a_function_body(pack);
	if (Str::eq(InterSymbol::identifier(ptype_name), I"_linkage"))
		InterPackage::mark_as_a_linkage_package(pack);

	if (created) *created = pack;
	LOGIF(INTER_SYMBOLS, "Package $6 at IBM $5\n", pack, IBM);

	return NULL;
}

void PackageInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PID_PACKAGE_IFLD] = grid[P->W.instruction[PID_PACKAGE_IFLD]];
	P->W.instruction[SYMBOLS_PACKAGE_IFLD] = grid[P->W.instruction[SYMBOLS_PACKAGE_IFLD]];
}

void PackageInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	inter_package *pack = Inode::ID_to_package(P, P->W.instruction[PID_PACKAGE_IFLD]);
	if (pack) pack->package_head = P; else internal_error("no package in PID field");
	inter_symbols_table *T = InterPackage::scope(owner);
	if (T == NULL) T = Inode::globals(P);
}

void PackageInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	inter_package *pack = PackageInstruction::at_this_head(P);
	inter_symbol *ptype_name = InterSymbolsTable::global_symbol_from_ID_at_node(P, PTYPE_PACKAGE_IFLD);
	if ((pack) && (ptype_name)) {
		WRITE("package %S %S", InterPackage::name(pack), InterSymbol::identifier(ptype_name));
	} else {
		if (pack == NULL) { *E = Inode::error(P, I"package can't be written - no name", NULL); return; }
		*E = Inode::error(P, I"package can't be written - no type", NULL); return;
	}
}

inter_error_message *PackageInstruction::write_symbols(OUTPUT_STREAM, inter_tree_node *P) {
	inter_package *pack = PackageInstruction::at_this_head(P);
	if (pack) {
		inter_symbols_table *locals = InterPackage::scope(pack);
		int L = (int) (P->W.instruction[LEVEL_IFLD] + 1);
		LOOP_OVER_SYMBOLS_TABLE(S, locals) {
			if (InterSymbol::is_plug(S)) {
				PlugInstruction::write_declaration(OUT, S, L);
				WRITE("\n");
			}
		}
		LOOP_OVER_SYMBOLS_TABLE(S, locals) {
			if (InterSymbol::is_socket(S)) {
				PlugInstruction::write_declaration(OUT, S, L);
				WRITE("\n");
			}
		}
	}
	return NULL;
}

int PackageInstruction::is(inter_symbol *package_name) {
	if (package_name == NULL) return FALSE;
	inter_tree_node *D = InterSymbol::definition(package_name);
	if (D == NULL) return FALSE;
	if (D->W.instruction[ID_IFLD] != PACKAGE_IST) return FALSE;
	return TRUE;
}

inter_package *PackageInstruction::which(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(package_name);
	if (D == NULL) return NULL;
	return Inode::ID_to_package(D, D->W.instruction[PID_PACKAGE_IFLD]);
}

inter_package *PackageInstruction::at_this_head(inter_tree_node *D) {
	if (D == NULL) return NULL;
	if (D->W.instruction[ID_IFLD] != PACKAGE_IST) return NULL;
	return Inode::ID_to_package(D, D->W.instruction[PID_PACKAGE_IFLD]);
}

inter_symbol *PackageInstruction::name_symbol(inter_package *pack) {
	if (pack == NULL) return NULL;
	inter_tree_node *D = pack->package_head;
	inter_symbol *package_name = InterSymbolsTable::symbol_from_ID_at_node(D, DEFN_PACKAGE_IFLD);
	return package_name;
}

void PackageInstruction::set_name_symbol(inter_package *pack, inter_symbol *S) {
	if (pack == NULL) internal_error("no package");
	inter_tree_node *D = pack->package_head;
	S->definition = D;
	inter_package *S_pack = InterSymbol::package(S);
	D->W.instruction[DEFN_PACKAGE_IFLD] =
		InterSymbolsTable::id_from_symbol_not_creating(InterPackage::tree(S_pack), S_pack, S);
}

inter_symbol *PackageInstruction::type(inter_package *pack) {
	if (pack == NULL) return NULL;
	inter_tree_node *D = pack->package_head;
	inter_symbol *ptype_name = InterSymbolsTable::global_symbol_from_ID_at_node(D, PTYPE_PACKAGE_IFLD);
	return ptype_name;
}

inter_symbol *PackageInstruction::read_type(inter_tree *I, inter_tree_node *P) {
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST)
		return InterSymbolsTable::symbol_from_ID(
			InterTree::global_scope(I), P->W.instruction[PTYPE_PACKAGE_IFLD]);
	return NULL;
}

void PackageInstruction::write_type(inter_tree *I, inter_tree_node *P, inter_symbol *ptype) {
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST)
		P->W.instruction[PTYPE_PACKAGE_IFLD] = InterSymbolsTable::id_from_symbol(I, NULL, ptype);
	else internal_error("wrote primitive to non-primitive invocation");
}

inter_symbols_table *PackageInstruction::local_symbols(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(package_name);
	if (D == NULL) return NULL;
	if (D->W.instruction[ID_IFLD] != PACKAGE_IST) return NULL;
	return Inode::ID_to_symbols_table(D, D->W.instruction[SYMBOLS_PACKAGE_IFLD]);
}

void PackageInstruction::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	inter_symbol *ptype_name = InterSymbolsTable::global_symbol_from_ID_at_node(P, PTYPE_PACKAGE_IFLD);
	if (Str::eq(InterSymbol::identifier(ptype_name), I"_code")) {
		LOOP_THROUGH_INTER_CHILDREN(C, P) {
			if ((C->W.instruction[0] != LABEL_IST) && (C->W.instruction[0] != LOCAL_IST) && (C->W.instruction[0] != CODE_IST) && (C->W.instruction[0] != COMMENT_IST)) {
				*E = Inode::error(C, I"only a local or a symbol can be at the top level", NULL);
				return;
			}
		}
	}
}
