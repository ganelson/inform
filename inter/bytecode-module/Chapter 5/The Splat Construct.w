[SplatInstruction::] The Splat Construct.

Defining the splat construct.

@

=
void SplatInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(SPLAT_IST, I"splat");
	InterInstruction::specify_syntax(IC, I"splat OPTIONALIDENTIFIER TEXT");
	InterInstruction::fix_instruction_length_between(IC, EXTENT_SPLAT_IFR, EXTENT_SPLAT_IFR);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, SplatInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, SplatInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, SplatInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, SplatInstruction::write);
}

@

@d BLOCK_SPLAT_IFLD 2
@d MATTER_SPLAT_IFLD 3
@d PLM_SPLAT_IFLD 4

@d EXTENT_SPLAT_IFR 5

@e IFDEF_I6DIR from 1
@e IFNDEF_I6DIR
@e IFNOT_I6DIR
@e ENDIF_I6DIR
@e IFTRUE_I6DIR
@e CONSTANT_I6DIR
@e ARRAY_I6DIR
@e GLOBAL_I6DIR
@e STUB_I6DIR
@e ROUTINE_I6DIR
@e ATTRIBUTE_I6DIR
@e PROPERTY_I6DIR
@e VERB_I6DIR
@e FAKEACTION_I6DIR
@e OBJECT_I6DIR
@e DEFAULT_I6DIR
@e MYSTERY_I6DIR
@e WHITESPACE_I6DIR

=
void SplatInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	inter_package *routine = NULL;
	if (ilp->indent_level > 0) {
		routine = InterBookmark::package(IBM);
		if (routine == NULL) { *E = InterErrors::plain(I"indented 'splat' used outside function", eloc); return; }
	}

	inter_ti plm = SplatInstruction::parse_plm(ilp->mr.exp[0]);
	if (plm == 1000000) { *E = InterErrors::plain(I"unknown PLM code before text matter", eloc); return; }

	inter_ti SID = InterWarehouse::create_text(InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
	text_stream *glob_storage = InterWarehouse::get_text(InterBookmark::warehouse(IBM), SID);
	*E = TextualInter::parse_literal_text(glob_storage, ilp->mr.exp[1], 0, Str::len(ilp->mr.exp[1]), eloc);
	if (*E) return;

	*E = SplatInstruction::new(IBM, SID, plm, (inter_ti) ilp->indent_level, eloc);
}

inter_ti SplatInstruction::parse_plm(text_stream *S) {
	if (Str::len(S) == 0) return 0;
	if (Str::eq(S, I"ARRAY")) return ARRAY_I6DIR;
	if (Str::eq(S, I"ATTRIBUTE")) return ATTRIBUTE_I6DIR;
	if (Str::eq(S, I"CONSTANT")) return CONSTANT_I6DIR;
	if (Str::eq(S, I"DEFAULT")) return DEFAULT_I6DIR;
	if (Str::eq(S, I"ENDIF")) return ENDIF_I6DIR;
	if (Str::eq(S, I"FAKEACTION")) return FAKEACTION_I6DIR;
	if (Str::eq(S, I"GLOBAL")) return GLOBAL_I6DIR;
	if (Str::eq(S, I"IFDEF")) return IFDEF_I6DIR;
	if (Str::eq(S, I"IFNDEF")) return IFNDEF_I6DIR;
	if (Str::eq(S, I"IFNOT")) return IFNOT_I6DIR;
	if (Str::eq(S, I"IFTRUE")) return IFTRUE_I6DIR;
	if (Str::eq(S, I"OBJECT")) return OBJECT_I6DIR;
	if (Str::eq(S, I"PROPERTY")) return PROPERTY_I6DIR;
	if (Str::eq(S, I"ROUTINE")) return ROUTINE_I6DIR;
	if (Str::eq(S, I"STUB")) return STUB_I6DIR;
	if (Str::eq(S, I"VERB")) return VERB_I6DIR;

	if (Str::eq(S, I"MYSTERY")) return MYSTERY_I6DIR;

	return 1000000;
}

void SplatInstruction::write_plm(OUTPUT_STREAM, inter_ti plm) {
	switch (plm) {
		case ARRAY_I6DIR: WRITE("ARRAY "); break;
		case ATTRIBUTE_I6DIR: WRITE("ATTRIBUTE "); break;
		case CONSTANT_I6DIR: WRITE("CONSTANT "); break;
		case DEFAULT_I6DIR: WRITE("DEFAULT "); break;
		case ENDIF_I6DIR: WRITE("ENDIF "); break;
		case FAKEACTION_I6DIR: WRITE("FAKEACTION "); break;
		case GLOBAL_I6DIR: WRITE("GLOBAL "); break;
		case IFDEF_I6DIR: WRITE("IFDEF "); break;
		case IFNDEF_I6DIR: WRITE("IFNDEF "); break;
		case IFNOT_I6DIR: WRITE("IFNOT "); break;
		case IFTRUE_I6DIR: WRITE("IFTRUE "); break;
		case OBJECT_I6DIR: WRITE("OBJECT "); break;
		case PROPERTY_I6DIR: WRITE("PROPERTY "); break;
		case ROUTINE_I6DIR: WRITE("ROUTINE "); break;
		case STUB_I6DIR: WRITE("STUB "); break;
		case VERB_I6DIR: WRITE("VERB "); break;

		case MYSTERY_I6DIR: WRITE("MYSTERY "); break;
	}
}

inter_error_message *SplatInstruction::new(inter_bookmark *IBM, inter_ti SID, inter_ti plm, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_3_data_fields(IBM, SPLAT_IST, 0, SID, plm, eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P); if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void SplatInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[MATTER_SPLAT_IFLD] = grid[P->W.instruction[MATTER_SPLAT_IFLD]];
}

void SplatInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.instruction[MATTER_SPLAT_IFLD] == 0) { *E = Inode::error(P, I"no matter text", NULL); return; }
	if (P->W.instruction[PLM_SPLAT_IFLD] > MYSTERY_I6DIR) { *E = Inode::error(P, I"plm out of range", NULL); return; }
}

void SplatInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	WRITE("splat ");
	SplatInstruction::write_plm(OUT, P->W.instruction[PLM_SPLAT_IFLD]);
	TextualInter::write_text(OUT, Inode::ID_to_text(P, P->W.instruction[MATTER_SPLAT_IFLD]));
}
