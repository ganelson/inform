[SplatInstruction::] The Splat Construct.

Defining the splat construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void SplatInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(SPLAT_IST, I"splat");
	InterInstruction::specify_syntax(IC, I"splat OPTIONALIDENTIFIER TEXT");
	InterInstruction::fix_instruction_length_between(IC, 4, 4);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, SplatInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, SplatInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, SplatInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, SplatInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |splat| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d MATTER_SPLAT_IFLD (DATA_IFLD + 0)
@d PLM_SPLAT_IFLD    (DATA_IFLD + 1)

=
inter_error_message *SplatInstruction::new(inter_bookmark *IBM, text_stream *splatter,
	inter_ti plm, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, SPLAT_IST,
		/* MATTER_SPLAT_IFLD: */ InterWarehouse::create_text_at(IBM, splatter),
		/* PLM_SPLAT_IFLD: */    plm,
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void SplatInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	P->W.instruction[MATTER_SPLAT_IFLD] = grid[P->W.instruction[MATTER_SPLAT_IFLD]];
}

@ Verification consists only of sanity checks.

=
void SplatInstruction::verify(inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E) {
	*E = VerifyingInter::text_field(owner, P, MATTER_SPLAT_IFLD);
	if (*E) return;
	if (SplatInstruction::plm_valid(P->W.instruction[PLM_SPLAT_IFLD]) == FALSE) {
		*E = Inode::error(P, I"plm out of range", NULL);
		return;
	}
}

@h Creating from textual Inter syntax.

=
void SplatInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *plm_text = ilp->mr.exp[0];
	text_stream *splatter_text = ilp->mr.exp[1];

	inter_ti plm = SplatInstruction::parse_plm(plm_text);
	if (SplatInstruction::plm_valid(plm) == FALSE) {
		*E = InterErrors::plain(I"unknown PLM code before text matter", eloc);
		return;
	}
	TEMPORARY_TEXT(raw)
	*E = TextualInter::parse_literal_text(raw, splatter_text, 0, Str::len(splatter_text), eloc);
	if (*E == NULL)
		*E = SplatInstruction::new(IBM, raw, plm, (inter_ti) ilp->indent_level, eloc);
	DISCARD_TEXT(raw)
}

@h Writing to textual Inter syntax.

=
void SplatInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("splat ");
	SplatInstruction::write_plm(OUT, SplatInstruction::plm(P));
	TextualInter::write_text(OUT, SplatInstruction::splatter(P));
}

@h Access function.

=
inter_ti SplatInstruction::plm(inter_tree_node *P) {
	if (P == NULL) return 0;
	if (Inode::isnt(P, SPLAT_IST)) return 0;
	return P->W.instruction[PLM_SPLAT_IFLD];
}

text_stream *SplatInstruction::splatter(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, SPLAT_IST)) return NULL;
	return Inode::ID_to_text(P, P->W.instruction[MATTER_SPLAT_IFLD]);
}

@h PLMs.
At some point PLM stood for something, but what it was is now forgotten --
perhaps "parse linked matter"? -- so it is now a nonsense-word pronounced
"plum". This is a marker attached to a splat which can indicate which Inform
6-syntax directive the splat contains (if any).

|WHITESPACE_PLM| should be used only if the splat contains nothing but white
space. |MYSTERY_PLM| should be used if its contents are of an unknown syntax.
The other names here are taken from their corresponding I6 directives.

@e IFDEF_PLM from 1
@e IFNDEF_PLM
@e IFNOT_PLM
@e ENDIF_PLM
@e IFTRUE_PLM
@e CONSTANT_PLM
@e ARRAY_PLM
@e GLOBAL_PLM
@e STUB_PLM
@e ROUTINE_PLM
@e ATTRIBUTE_PLM
@e PROPERTY_PLM
@e VERB_PLM
@e FAKEACTION_PLM
@e OBJECT_PLM
@e DEFAULT_PLM
@e MYSTERY_PLM
@e WHITESPACE_PLM

=
int SplatInstruction::plm_valid(inter_ti plm) {
	if ((plm == 0) || (plm > WHITESPACE_PLM)) return FALSE;
	return TRUE;
}

@ Converted to and from text thus. Note that |MYSTERY_PLM| is used in the
case where no PLM is given; so it has the empty textual form, and is not
written.

=
inter_ti SplatInstruction::parse_plm(text_stream *S) {
	if (Str::len(S) == 0)          return MYSTERY_PLM;
	if (Str::eq(S, I"ARRAY"))      return ARRAY_PLM;
	if (Str::eq(S, I"ATTRIBUTE"))  return ATTRIBUTE_PLM;
	if (Str::eq(S, I"CONSTANT"))   return CONSTANT_PLM;
	if (Str::eq(S, I"DEFAULT"))    return DEFAULT_PLM;
	if (Str::eq(S, I"ENDIF"))      return ENDIF_PLM;
	if (Str::eq(S, I"FAKEACTION")) return FAKEACTION_PLM;
	if (Str::eq(S, I"GLOBAL"))     return GLOBAL_PLM;
	if (Str::eq(S, I"IFDEF"))      return IFDEF_PLM;
	if (Str::eq(S, I"IFNDEF"))     return IFNDEF_PLM;
	if (Str::eq(S, I"IFNOT"))      return IFNOT_PLM;
	if (Str::eq(S, I"IFTRUE"))     return IFTRUE_PLM;
	if (Str::eq(S, I"OBJECT"))     return OBJECT_PLM;
	if (Str::eq(S, I"PROPERTY"))   return PROPERTY_PLM;
	if (Str::eq(S, I"ROUTINE"))    return ROUTINE_PLM;
	if (Str::eq(S, I"STUB"))       return STUB_PLM;
	if (Str::eq(S, I"VERB"))       return VERB_PLM;
	if (Str::eq(S, I"WHITESPACE")) return WHITESPACE_PLM;
	return 0;
}

void SplatInstruction::write_plm(OUTPUT_STREAM, inter_ti plm) {
	switch (plm) {
		case ARRAY_PLM:      WRITE("ARRAY "); break;
		case ATTRIBUTE_PLM:  WRITE("ATTRIBUTE "); break;
		case CONSTANT_PLM:   WRITE("CONSTANT "); break;
		case DEFAULT_PLM:    WRITE("DEFAULT "); break;
		case ENDIF_PLM:      WRITE("ENDIF "); break;
		case FAKEACTION_PLM: WRITE("FAKEACTION "); break;
		case GLOBAL_PLM:     WRITE("GLOBAL "); break;
		case IFDEF_PLM:      WRITE("IFDEF "); break;
		case IFNDEF_PLM:     WRITE("IFNDEF "); break;
		case IFNOT_PLM:      WRITE("IFNOT "); break;
		case IFTRUE_PLM:     WRITE("IFTRUE "); break;
		case OBJECT_PLM:     WRITE("OBJECT "); break;
		case PROPERTY_PLM:   WRITE("PROPERTY "); break;
		case ROUTINE_PLM:    WRITE("ROUTINE "); break;
		case STUB_PLM:       WRITE("STUB "); break;
		case VERB_PLM:       WRITE("VERB "); break;
		case WHITESPACE_PLM: WRITE("WHITESPACE "); break;
	}
}
