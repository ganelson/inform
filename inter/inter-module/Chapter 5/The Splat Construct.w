[Inter::Splat::] The Splat Construct.

Defining the splat construct.

@

@e SPLAT_IST

=
void Inter::Splat::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		SPLAT_IST,
		L"splat (%C*) *&\"(%c*)\"",
		I"splat", I"splats");
	IC->min_level = 0;
	IC->max_level = 100000000;
	IC->usage_permissions = OUTSIDE_OF_PACKAGES + INSIDE_PLAIN_PACKAGE + INSIDE_CODE_PACKAGE;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Splat::read);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Splat::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Splat::write);
}

@

@d BLOCK_SPLAT_IFLD 2
@d MATTER_SPLAT_IFLD 3
@d PLM_SPLAT_IFLD 4

@d EXTENT_SPLAT_IFR 5

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

=
void Inter::Splat::read(inter_construct *IC, inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (ilp->no_annotations > 0) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }

	*E = Inter::Defn::vet_level(IRS, SPLAT_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_symbol *routine = NULL;
	if (ilp->indent_level > 0) {
		routine = Inter::Defn::get_latest_block_symbol();
		if (routine == NULL) { *E = Inter::Errors::plain(I"indented 'splat' used outside function", eloc); return; }
	}

	inter_t plm = Inter::Splat::parse_plm(ilp->mr.exp[0]);
	if (plm == 1000000) { *E = Inter::Errors::plain(I"unknown PLM code before text matter", eloc); return; }

	inter_t SID = Inter::create_text(IRS->read_into);
	text_stream *glob_storage = Inter::get_text(IRS->read_into, SID);
	*E = Inter::Constant::parse_text(glob_storage, ilp->mr.exp[1], 0, Str::len(ilp->mr.exp[1]), eloc);
	if (*E) return;

	*E = Inter::Splat::new(IRS, routine, SID, plm, (inter_t) ilp->indent_level, ilp->terminal_comment, eloc);
}

inter_t Inter::Splat::parse_plm(text_stream *S) {
	if (Str::len(S) == 0) return 0;
	if (Str::eq(S, I"ARRAY")) return ARRAY_PLM;
	if (Str::eq(S, I"ATTRIBUTE")) return ATTRIBUTE_PLM;
	if (Str::eq(S, I"CONSTANT")) return CONSTANT_PLM;
	if (Str::eq(S, I"DEFAULT")) return DEFAULT_PLM;
	if (Str::eq(S, I"ENDIF")) return ENDIF_PLM;
	if (Str::eq(S, I"FAKEACTION")) return FAKEACTION_PLM;
	if (Str::eq(S, I"GLOBAL")) return GLOBAL_PLM;
	if (Str::eq(S, I"IFDEF")) return IFDEF_PLM;
	if (Str::eq(S, I"IFNDEF")) return IFNDEF_PLM;
	if (Str::eq(S, I"IFNOT")) return IFNOT_PLM;
	if (Str::eq(S, I"IFTRUE")) return IFTRUE_PLM;
	if (Str::eq(S, I"OBJECT")) return OBJECT_PLM;
	if (Str::eq(S, I"PROPERTY")) return PROPERTY_PLM;
	if (Str::eq(S, I"ROUTINE")) return ROUTINE_PLM;
	if (Str::eq(S, I"STUB")) return STUB_PLM;
	if (Str::eq(S, I"VERB")) return VERB_PLM;

	if (Str::eq(S, I"MYSTERY")) return MYSTERY_PLM;

	return 1000000;
}

void Inter::Splat::write_plm(OUTPUT_STREAM, inter_t plm) {
	switch (plm) {
		case ARRAY_PLM: WRITE("ARRAY "); break;
		case ATTRIBUTE_PLM: WRITE("ATTRIBUTE "); break;
		case CONSTANT_PLM: WRITE("CONSTANT "); break;
		case DEFAULT_PLM: WRITE("DEFAULT "); break;
		case ENDIF_PLM: WRITE("ENDIF "); break;
		case FAKEACTION_PLM: WRITE("FAKEACTION "); break;
		case GLOBAL_PLM: WRITE("GLOBAL "); break;
		case IFDEF_PLM: WRITE("IFDEF "); break;
		case IFNDEF_PLM: WRITE("IFNDEF "); break;
		case IFNOT_PLM: WRITE("IFNOT "); break;
		case IFTRUE_PLM: WRITE("IFTRUE "); break;
		case OBJECT_PLM: WRITE("OBJECT "); break;
		case PROPERTY_PLM: WRITE("PROPERTY "); break;
		case ROUTINE_PLM: WRITE("ROUTINE "); break;
		case STUB_PLM: WRITE("STUB "); break;
		case VERB_PLM: WRITE("VERB "); break;

		case MYSTERY_PLM: WRITE("MYSTERY "); break;
	}
}

inter_error_message *Inter::Splat::new(inter_reading_state *IRS, inter_symbol *routine, inter_t SID, inter_t plm, inter_t level, inter_t ID, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_3(IRS, SPLAT_IST, 0, SID, plm, eloc, level);
	if (ID) Inter::Frame::attach_comment(P, ID);
	inter_error_message *E = Inter::Defn::verify_construct(IRS->current_package, P); if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

void Inter::Splat::verify(inter_construct *IC, inter_frame P, inter_package *owner, inter_error_message **E) {
	if (P.extent != EXTENT_SPLAT_IFR) { *E = Inter::Frame::error(&P, I"extent wrong", NULL); return; }
	if (P.data[MATTER_SPLAT_IFLD] == 0) { *E = Inter::Frame::error(&P, I"no matter text", NULL); return; }
	if (P.data[PLM_SPLAT_IFLD] > MYSTERY_PLM) { *E = Inter::Frame::error(&P, I"plm out of range", NULL); return; }
}

void Inter::Splat::write(inter_construct *IC, OUTPUT_STREAM, inter_frame P, inter_error_message **E) {
	WRITE("splat ");
	Inter::Splat::write_plm(OUT, P.data[PLM_SPLAT_IFLD]);
	WRITE("&\"");
	Inter::Constant::write_text(OUT, Inter::get_text(P.repo_segment->owning_repo, P.data[MATTER_SPLAT_IFLD]));
	WRITE("\"");
}
