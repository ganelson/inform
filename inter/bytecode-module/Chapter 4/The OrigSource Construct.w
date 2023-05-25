[OrigSourceInstruction::] The OrigSource Construct.

Defining the OrigSource construct.

@h Definition.
The OrigSource construct is a marker in the bytecode which indicates the
source location that generated that bytecode.

=
void OrigSourceInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(ORIGSOURCE_IST, I"origsource");
	InterInstruction::specify_syntax(IC, I"origsource TEXT NUMBER");
	InterInstruction::data_extent_always(IC, 2);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, OrigSourceInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, OrigSourceInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, OrigSourceInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, OrigSourceInstruction::write);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
}

@h Instructions.
In bytecode, the frame of an |origsource| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d PROVENANCEFILE_ORIGSOURCE_IFLD (DATA_IFLD + 0)
@d PROVENANCELINE_ORIGSOURCE_IFLD (DATA_IFLD + 1)

If |PROVENANCEFILE| is zero, the instruction means "Following bytecode is not
from any specific source location." The line number is ignored in this case.

=
inter_error_message *OrigSourceInstruction::new(inter_bookmark *IBM,
	filename *file, inter_ti line_number,
	inter_error_location *eloc, inter_ti level) {
	inter_ti FID = 0;
	if (file) {
		TEMPORARY_TEXT(file_as_text)
		WRITE_TO(file_as_text, "%f", file);
		inter_warehouse *warehouse = InterBookmark::warehouse(IBM);
		inter_package *pack = InterBookmark::package(IBM);
		FID = InterWarehouse::create_text(warehouse, pack);
		Str::copy(InterWarehouse::get_text(warehouse, FID), file_as_text);
	}
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, ORIGSOURCE_IST,
		/* PROVENANCEFILE_ORIGSOURCE_IFLD: */ FID,
		/* PROVENANCELINE_ORIGSOURCE_IFLD: */ line_number,
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void OrigSourceInstruction::transpose(inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[PROVENANCEFILE_ORIGSOURCE_IFLD] = grid[P->W.instruction[PROVENANCEFILE_ORIGSOURCE_IFLD]];
}

@ Verification consists only of sanity checks.

=
void OrigSourceInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	if (!P->W.instruction[PROVENANCEFILE_ORIGSOURCE_IFLD]) {
		/* (0,anything) is valid */
	}
	else {
		*E = VerifyingInter::text_field(owner, P, PROVENANCEFILE_ORIGSOURCE_IFLD);
	}
	if (*E) return;
}

@h Creating from textual Inter syntax.

=
void OrigSourceInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp,
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *fn = ilp->mr.exp[0];
	text_stream *lc = ilp->mr.exp[1];
	TEMPORARY_TEXT(file_as_text)
	*E = TextualInter::parse_literal_text(file_as_text, fn, 0, Str::len(fn), eloc);
	if (*E == NULL) {
		filename *F = NULL;
		if (Str::len(file_as_text) > 0) F = Filenames::from_text(file_as_text);
		inter_ti line_number = 0;
		if (Str::len(lc) > 0) line_number = (inter_ti) Str::atoi(lc, 0);
		*E = OrigSourceInstruction::new(IBM, F, line_number,
			eloc, (inter_ti) ilp->indent_level);
	}
	DISCARD_TEXT(file_as_text)
}

@h Writing to textual Inter syntax.

=
void OrigSourceInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	if (!P->W.instruction[PROVENANCEFILE_ORIGSOURCE_IFLD]) {
		WRITE("origsource");
	}
	else {
		WRITE("origsource ");
		Provenance::write(OUT, OrigSourceInstruction::provenance(P));
	}
}

@h Access functions.

=
text_provenance OrigSourceInstruction::provenance(inter_tree_node *P) {
	if (P == NULL) return Provenance::nowhere();
	if (Inode::isnt(P, ORIGSOURCE_IST)) return Provenance::nowhere();
	if (!P->W.instruction[PROVENANCEFILE_ORIGSOURCE_IFLD])
		return Provenance::nowhere();
	return Provenance::at_file_and_line(
		Inode::ID_to_text(P, P->W.instruction[PROVENANCEFILE_ORIGSOURCE_IFLD]),
		(int) P->W.instruction[PROVENANCELINE_ORIGSOURCE_IFLD]);
}
