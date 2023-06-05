[SplatInstruction::] The Splat Construct.

Defining the splat construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void SplatInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(SPLAT_IST, I"splat");
	InterInstruction::specify_syntax(IC, I"splat OPTIONALIDENTIFIER TEXT TEXT TEXT");
	InterInstruction::data_extent_always(IC, 6);
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

@d MATTER_SPLAT_IFLD         (DATA_IFLD + 0)
@d PLM_SPLAT_IFLD            (DATA_IFLD + 1)
@d I6ANNOTATION_SPLAT_IFLD   (DATA_IFLD + 2)
@d NAMESPACE_SPLAT_IFLD      (DATA_IFLD + 3)
@d PROVENANCEFILE_SPLAT_IFLD (DATA_IFLD + 4)
@d PROVENANCELINE_SPLAT_IFLD (DATA_IFLD + 5)

=
inter_error_message *SplatInstruction::new(inter_bookmark *IBM, text_stream *splatter,
	inter_ti plm, text_stream *annotation, text_stream *namespace,
	filename *file, inter_ti line_number, inter_ti level, inter_error_location *eloc) {
	TEMPORARY_TEXT(file_as_text)
	if (file) WRITE_TO(file_as_text, "%f", file);
	inter_tree_node *P = Inode::new_with_6_data_fields(IBM, SPLAT_IST,
		/* MATTER_SPLAT_IFLD: */       InterWarehouse::create_text_at(IBM, splatter),
		/* PLM_SPLAT_IFLD: */          plm,
		/* I6ANNOTATION_SPLAT_IFLD: */
			(Str::len(annotation) > 0)?(InterWarehouse::create_text_at(IBM, annotation)):0,
		/* NAMESPACE_SPLAT_IFLD: */
			(Str::len(namespace) > 0)?(InterWarehouse::create_text_at(IBM, namespace)):0,
		/* PROVENANCEFILE_SPLAT_IFLD: */
			(Str::len(file_as_text) > 0)?(InterWarehouse::create_text_at(IBM, file_as_text)):0,
		/* PROVENANCELINE_SPLAT_IFLD: */ line_number,
		eloc, level);
	DISCARD_TEXT(file_as_text)
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
	if (P->W.instruction[I6ANNOTATION_SPLAT_IFLD]) {
		*E = VerifyingInter::text_field(owner, P, I6ANNOTATION_SPLAT_IFLD);
		if (*E) return;
	}
}

@h Creating from textual Inter syntax.

=
void SplatInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	text_stream *plm_text = ilp->mr.exp[0];
	text_stream *annot_text = ilp->mr.exp[1];
	text_stream *namespace_text = ilp->mr.exp[2];
	text_stream *splatter_text = ilp->mr.exp[3];

	inter_ti plm = SplatInstruction::parse_plm(plm_text);
	if (SplatInstruction::plm_valid(plm) == FALSE) {
		*E = InterErrors::plain(I"unknown PLM code before text matter", eloc);
		return;
	}
	TEMPORARY_TEXT(raw)
	TEMPORARY_TEXT(raw_annot)
	TEMPORARY_TEXT(raw_ns)
	*E = TextualInter::parse_literal_text(raw, splatter_text, 0, Str::len(splatter_text), eloc);
	if (*E == NULL) {
		*E = TextualInter::parse_literal_text(raw_annot, annot_text, 0, Str::len(annot_text), eloc);
		if (*E == NULL) {
			*E = TextualInter::parse_literal_text(raw_ns, namespace_text, 0, Str::len(annot_text), eloc);
			if (*E == NULL) {
				filename *F = NULL;
				inter_ti lc = 0;
				if (eloc) {
					F = eloc->error_tfp->text_file_filename;
					lc = (inter_ti) eloc->error_tfp->line_count;
				}
				*E = SplatInstruction::new(IBM, raw, plm, raw_annot, raw_ns, F, lc,
					(inter_ti) ilp->indent_level, eloc);
			}
		}
	}
	DISCARD_TEXT(raw)
	DISCARD_TEXT(raw_annot)
	DISCARD_TEXT(raw_ns)
}

@h Writing to textual Inter syntax.

=
void SplatInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("splat ");
	SplatInstruction::write_plm(OUT, SplatInstruction::plm(P));
	TextualInter::write_text(OUT, SplatInstruction::I6_annotation(P));
	WRITE(" ");
	TextualInter::write_text(OUT, SplatInstruction::namespace(P));
	WRITE(" ");
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

text_stream *SplatInstruction::I6_annotation(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, SPLAT_IST)) return NULL;
	return Inode::ID_to_text(P, P->W.instruction[I6ANNOTATION_SPLAT_IFLD]);
}

text_stream *SplatInstruction::namespace(inter_tree_node *P) {
	if (P == NULL) return NULL;
	if (Inode::isnt(P, SPLAT_IST)) return NULL;
	return Inode::ID_to_text(P, P->W.instruction[NAMESPACE_SPLAT_IFLD]);
}

text_provenance SplatInstruction::provenance(inter_tree_node *P) {
	if (P == NULL) return Provenance::nowhere();
	if (Inode::isnt(P, SPLAT_IST)) return Provenance::nowhere();
	return Provenance::at_file_and_line(
		Inode::ID_to_text(P, P->W.instruction[PROVENANCEFILE_SPLAT_IFLD]),
		(int) P->W.instruction[PROVENANCELINE_SPLAT_IFLD]);
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
@e ORIGSOURCE_PLM
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
