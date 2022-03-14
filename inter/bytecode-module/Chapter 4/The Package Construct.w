[PackageInstruction::] The Package Construct.

Defining the package construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void PackageInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PACKAGE_IST, I"package");
	InterInstruction::defines_symbol_in_fields(IC, DEFN_PACKAGE_IFLD, TYPE_PACKAGE_IFLD);
	InterInstruction::specify_syntax(IC, I"package TOKENS _IDENTIFIER");
	InterInstruction::data_extent_always(IC, 5);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, PackageInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, PackageInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, PackageInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, PackageInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, PackageInstruction::verify_children);
}

@h Instructions.
In bytecode, the frame of a |package| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d DEFN_PACKAGE_IFLD    (DATA_IFLD + 0)
@d TYPE_PACKAGE_IFLD    (DATA_IFLD + 1)
@d PTYPE_PACKAGE_IFLD   (DATA_IFLD + 2)
@d SYMBOLS_PACKAGE_IFLD (DATA_IFLD + 3)
@d PID_PACKAGE_IFLD     (DATA_IFLD + 4)

@ If you try to create uniquely-named subpackages all called |bag| inside the
same package, you'll get |bag|, then |bag_1|, |bag_2|, and so on.

=
inter_error_message *PackageInstruction::new(inter_bookmark *IBM,
	text_stream *name, inter_type type, int uniquely, inter_symbol *ptype_name, inter_ti level,
	inter_error_location *eloc, inter_package **created) {
	inter_error_message *E;
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
		E = PackageInstruction::new_inner(IBM, mutable, type, ptype_name, level, eloc, created);
		DISCARD_TEXT(mutable)
	} else {
		E = PackageInstruction::new_inner(IBM, name, type, ptype_name, level, eloc, created);
	}
	return E;
}

@ The actual instruction is made here:

=
inter_error_message *PackageInstruction::new_inner(inter_bookmark *IBM,
	text_stream *name_text, inter_type type, inter_symbol *ptype_name, inter_ti level,
	inter_error_location *eloc, inter_package **created) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
	inter_ti STID = InterWarehouse::create_symbols_table(warehouse);
	inter_error_message *E = NULL;
	inter_symbol *package_name =
		TextualInter::new_symbol(eloc, InterBookmark::scope(IBM), name_text, &E);
	if (E) return E;
	inter_tree_node *P = Inode::new_with_5_data_fields(IBM, PACKAGE_IST,
		/* DEFN_PACKAGE_IFLD: */    InterSymbolsTable::id_at_bookmark(IBM, package_name),
		/* TYPE_PACKAGE_IFLD: */    InterTypes::to_TID_at(IBM, type),
		/* PTYPE_PACKAGE_IFLD: */   InterSymbolsTable::id_from_symbol(I, NULL, ptype_name),
		/* SYMBOLS_PACKAGE_IFLD: */ STID,
		/* PID_PACKAGE_IFLD: */     0, /* but see just below... */
		eloc, level);
	inter_ti PID = InterWarehouse::create_package(warehouse, I);
	inter_package *pack = InterWarehouse::get_package(warehouse, PID);
	pack->package_head = P;
	P->W.instruction[PID_PACKAGE_IFLD] = PID;
	InterPackage::set_scope(pack, InterWarehouse::get_symbols_table(warehouse, STID));
	InterWarehouse::set_symbols_table_owner(warehouse, STID, pack);

	E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);

	LargeScale::note_package_name(I, pack, name_text);
	if (Str::eq(InterSymbol::identifier(ptype_name), I"_code"))
		InterPackage::mark_as_a_function_body(pack);
	if (Str::eq(InterSymbol::identifier(ptype_name), I"_linkage"))
		InterPackage::mark_as_a_linkage_package(pack);

	if (created) *created = pack;
	LOGIF(INTER_SYMBOLS, "Package $6 at IBM $5\n", pack, IBM);

	return NULL;
}

void PackageInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PID_PACKAGE_IFLD] = grid[P->W.instruction[PID_PACKAGE_IFLD]];
	P->W.instruction[SYMBOLS_PACKAGE_IFLD] = grid[P->W.instruction[SYMBOLS_PACKAGE_IFLD]];
}

@ Verification begins with sanity checks, but then does something crucial: makes
sure that the link between the package and its head node is in place. If the
instruction has just been created by //PackageInstruction::new// then
that will be done already -- but not if the instruction has been loaded from
a binary Inter file.

=
void PackageInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner,
	inter_error_message **E) {
	*E = VerifyingInter::SID_field(owner, P, DEFN_PACKAGE_IFLD, PACKAGE_IST);
	if (*E) return;
	*E = VerifyingInter::TID_field(owner, P, TYPE_PACKAGE_IFLD);
	if (*E) return;
	*E = VerifyingInter::GSID_field(P, PTYPE_PACKAGE_IFLD, PACKAGETYPE_IST);
	if (*E) return;
	*E = VerifyingInter::symbols_table_field(owner, P, SYMBOLS_PACKAGE_IFLD);
	if (*E) return;
	*E = VerifyingInter::package_field(owner, P, PID_PACKAGE_IFLD);
	if (*E) return;

	inter_package *pack = Inode::ID_to_package(P, P->W.instruction[PID_PACKAGE_IFLD]);
	if (pack) pack->package_head = P; else internal_error("no package in PID field");
}

void PackageInstruction::verify_children(inter_construct *IC, inter_tree_node *P,
	inter_error_message **E) {
	if (InterPackage::is_a_function_body(PackageInstruction::at_this_head(P))) {
		LOOP_THROUGH_INTER_CHILDREN(C, P) {
			if ((C->W.instruction[0] != LABEL_IST) &&
				(C->W.instruction[0] != LOCAL_IST) &&
				(C->W.instruction[0] != CODE_IST) &&
				(C->W.instruction[0] != COMMENT_IST)) {
				*E = Inode::error(C, I"instruction not permitted at the top level", NULL);
				return;
			}
		}
	}
}

@h Creating from textual Inter syntax.

=
void PackageInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	inter_symbol *ptype_name = LargeScale::package_type(InterBookmark::tree(IBM), ilp->mr.exp[1]);

	inter_type type = InterTypes::unchecked();
	text_stream *identifier = ilp->mr.exp[0];
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, identifier, L"%((%c+)%) (%c+)")) {
		type = InterTypes::parse_simple(InterBookmark::scope(IBM), eloc, mr.exp[0], E);
		identifier = mr.exp[1];
	}
	if (*E == NULL) {
		inter_package *pack = NULL;
		*E = PackageInstruction::new(IBM, identifier, type, FALSE, ptype_name,
			(inter_ti) ilp->indent_level, eloc, &pack);
		if (*E == NULL) InterBookmark::move_into_package(IBM, pack);
	}
	Regexp::dispose_of(&mr);
}

@h Writing to textual Inter syntax.

=
void PackageInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	inter_package *pack = PackageInstruction::at_this_head(P);
	inter_symbol *ptype_name =
		InterSymbolsTable::global_symbol_from_ID_at_node(P, PTYPE_PACKAGE_IFLD);
	WRITE("package ");
	TextualInter::write_optional_type_marker(OUT, P, TYPE_PACKAGE_IFLD);
	WRITE("%S %S", InterPackage::name(pack), InterSymbol::identifier(ptype_name));
}

@ With the addendum of writing out the pseudo-constructs |plug| and |socket|
to ensure that any in the symbols table are recorded in the textual output:

=
inter_error_message *PackageInstruction::write_plugs_and_sockets(OUTPUT_STREAM,
	inter_tree_node *P) {
	inter_package *pack = PackageInstruction::at_this_head(P);
	if (pack) {
		inter_symbols_table *locals = InterPackage::scope(pack);
		int L = Inode::get_level(P) + 1;
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

@h Package vs its head vs its name symbol.
Three ways to identify a package, all inter-convertible.

=
int PackageInstruction::is(inter_symbol *package_name) {
	if (package_name == NULL) return FALSE;
	inter_tree_node *D = InterSymbol::definition(package_name);
	if (D == NULL) return FALSE;
	if (Inode::isnt(D, PACKAGE_IST)) return FALSE;
	return TRUE;
}

int PackageInstruction::is_function(inter_symbol *package_name) {
	if (package_name == NULL) return FALSE;
	inter_tree_node *D = InterSymbol::definition(package_name);
	return InterPackage::is_a_function_body(PackageInstruction::at_this_head(D));
}

inter_package *PackageInstruction::which(inter_symbol *package_name) {
	if (package_name == NULL) return NULL;
	inter_tree_node *D = InterSymbol::definition(package_name);
	if (D == NULL) return NULL;
	return Inode::ID_to_package(D, D->W.instruction[PID_PACKAGE_IFLD]);
}

inter_package *PackageInstruction::at_this_head(inter_tree_node *D) {
	if (D == NULL) return NULL;
	if (Inode::isnt(D, PACKAGE_IST)) return NULL;
	return Inode::ID_to_package(D, D->W.instruction[PID_PACKAGE_IFLD]);
}

inter_symbol *PackageInstruction::name_symbol(inter_package *pack) {
	if (pack == NULL) return NULL;
	inter_tree_node *D = pack->package_head;
	inter_symbol *package_name =
		InterSymbolsTable::symbol_from_ID_at_node(D, DEFN_PACKAGE_IFLD);
	return package_name;
}

@ And the type:

=
inter_symbol *PackageInstruction::get_type_of(inter_tree *I, inter_tree_node *P) {
	if (Inode::is(P, PACKAGE_IST))
		return InterSymbolsTable::symbol_from_ID(
			InterTree::global_scope(I), P->W.instruction[PTYPE_PACKAGE_IFLD]);
	return NULL;
}

@ These look invariant-busting and dubious: see //Transmigration// for why they
are needed. And see also //imperative: Functions//.

=
void PackageInstruction::set_type(inter_tree *I, inter_tree_node *P, inter_symbol *ptype) {
	if (Inode::is(P, PACKAGE_IST))
		P->W.instruction[PTYPE_PACKAGE_IFLD] = InterSymbolsTable::id_from_symbol(I, NULL, ptype);
	else internal_error("wrote primitive to non-primitive invocation");
}

void PackageInstruction::set_name_symbol(inter_package *pack, inter_symbol *S) {
	if (pack == NULL) internal_error("no package");
	inter_tree_node *D = pack->package_head;
	S->definition = D;
	inter_package *S_pack = InterSymbol::package(S);
	D->W.instruction[DEFN_PACKAGE_IFLD] =
		InterSymbolsTable::id_from_symbol_not_creating(InterPackage::tree(S_pack), S_pack, S);
}

void PackageInstruction::set_data_type(inter_package *pack, inter_type type) {
	if (pack == NULL) internal_error("no package");
	inter_tree_node *D = pack->package_head;
	D->W.instruction[TYPE_PACKAGE_IFLD] =
		InterTypes::to_TID(InterPackage::scope(InterPackage::parent(pack)), type);
}
