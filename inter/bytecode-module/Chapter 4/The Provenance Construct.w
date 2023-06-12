[ProvenanceInstruction::] The Provenance Construct.

Defining the Provenance construct.

@h Definition.
The Provenance construct is a marker in the bytecode which indicates the
source location that generated that bytecode.

=
void ProvenanceInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(PROVENANCE_IST, I"provenance");
	InterInstruction::specify_syntax(IC, I"provenance ANY");
	InterInstruction::data_extent_always(IC, 2);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, ProvenanceInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, ProvenanceInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, ProvenanceInstruction::write);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
}

@h Instructions.
In bytecode, the frame of a |provenance| instruction is laid out with the
compulsory words -- see //Inter Nodes//.

If |ORIGIN_PROVENANCE_IFLD| is zero, the instruction means "Following
bytecode is not from any specific source location." The line number is ignored
in this case.

@d ORIGIN_PROVENANCE_IFLD (DATA_IFLD + 0)
@d LINE_PROVENANCE_IFLD (DATA_IFLD + 1)

=
inter_error_message *ProvenanceInstruction::new(inter_bookmark *IBM,
	inter_symbol *origin, inter_ti line_number,
	inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P;
	if (origin) {
		inter_ti OID = InterSymbolsTable::id_from_symbol(InterBookmark::tree(IBM), NULL, origin);
		P = Inode::new_with_2_data_fields(IBM, PROVENANCE_IST,
			/* ORIGIN_PROVENANCE_IFLD: */ OID,
			/* LINE_PROVENANCE_IFLD: */   line_number,
			eloc, level);
	} else {
		P = Inode::new_with_2_data_fields(IBM, PROVENANCE_IST,
			/* ORIGIN_PROVENANCE_IFLD: */ 0,
			/* LINE_PROVENANCE_IFLD: */   0,
			eloc, level);
	}
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

inter_error_message *ProvenanceInstruction::new_from_provenance(inter_bookmark *IBM,
	text_provenance prov,
	inter_ti level, inter_error_location *eloc) {
	inter_symbol *origin = Origins::filename_to_origin(
		InterBookmark::tree(IBM), prov.textual_filename);
	return ProvenanceInstruction::new(IBM, origin,
		(inter_ti) prov.line_number, level, eloc);
}

@ Rather than using transposition, this instruction has its own way to migrate.
The advantage of doing it this way is that it maintains the position that each
tree has exactly one origin instruction for each distinct filename. There are
probably ways to speed this up, but it seems to work well in practice.

=
void ProvenanceInstruction::migrate(inter_tree_node *P, inter_tree *I) {
	text_provenance prov = ProvenanceInstruction::provenance(P);
	inter_symbol *new_origin = Origins::filename_to_origin(I, prov.textual_filename);
	if (new_origin)
		P->W.instruction[ORIGIN_PROVENANCE_IFLD] =
			InterSymbolsTable::id_from_symbol(I, NULL, new_origin);
}

@ Verification consists only of checking that the origin, if given, was
a symbol defined by an |origin| instruction.

=
void ProvenanceInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	inter_symbol *origin = ProvenanceInstruction::origin(P);
	if (origin) {
		inter_tree_node *D = InterSymbol::definition(origin);
		if ((D == NULL) || (Inode::isnt(D, ORIGIN_IST))) {
			*E = Inode::error(P, I"symbol is not a valid origin", NULL);
			return;
		}
	}
}

@h Creating from textual Inter syntax.

=
void ProvenanceInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *textual = ilp->mr.exp[0];
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, textual, L"@(%C+) (%d+)")) {
		inter_tree *I = InterBookmark::tree(IBM);
		inter_symbol *origin =
			InterSymbolsTable::symbol_from_name(InterTree::global_scope(I), mr.exp[0]);
		if (origin == NULL) *E = InterErrors::plain(I"not an origin", eloc);
		else {
			inter_ti line_number = (inter_ti) Str::atoi(mr.exp[1], 0);
			*E = ProvenanceInstruction::new(IBM, origin, line_number,
				(inter_ti) ilp->indent_level, eloc);
		}
	} else if (Str::eq(textual, I"-")) {
		*E = ProvenanceInstruction::new(IBM, NULL, 0,
			(inter_ti) ilp->indent_level, eloc);	
	} else {
		*E = InterErrors::plain(I"bad provenance syntax", eloc);
	}
	Regexp::dispose_of(&mr);
}

@h Writing to textual Inter syntax.

=
void ProvenanceInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("provenance ");
	inter_symbol *origin = ProvenanceInstruction::origin(P);
	if (origin) {
		WRITE("@%S %d", InterSymbol::identifier(origin),
			(int) P->W.instruction[LINE_PROVENANCE_IFLD]);
	} else {
		WRITE("-");
	}
}

@h Access functions.

=
inter_symbol *ProvenanceInstruction::origin(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, PROVENANCE_IST)) return NULL;
	if (P->W.instruction[ORIGIN_PROVENANCE_IFLD] == 0) return NULL;
	return InterSymbolsTable::symbol_from_ID(
		InterTree::global_scope(Inode::tree(P)), P->W.instruction[ORIGIN_PROVENANCE_IFLD]);
}

text_provenance ProvenanceInstruction::provenance(inter_tree_node *P) {
	inter_symbol *origin = ProvenanceInstruction::origin(P);
	if (origin == NULL) return Provenance::nowhere();
	inter_tree_node *D = InterSymbol::definition(origin);
	return Provenance::at_file_and_line(
		OriginInstruction::filename(D),
		(int) P->W.instruction[LINE_PROVENANCE_IFLD]);
}
