[CodeGen::PLM::] Parse Linked Matter.

To generate the initial state of storage for variables.

@h Pipeline stage.

=
void CodeGen::PLM::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"parse-linked-matter", CodeGen::PLM::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int CodeGen::PLM::run_pipeline_stage(pipeline_step *step) {
	Inter::traverse_tree(step->repository, CodeGen::PLM::visitor, NULL, NULL, 0);
	return TRUE;
}

@h Parsing.

=
void CodeGen::PLM::visitor(inter_tree *I, inter_frame *P, void *state) {
	inter_package *outer = Inter::Packages::container(P);
	if (((outer == NULL) || (Inter::Packages::is_codelike(outer) == FALSE)) && (P->node->W.data[ID_IFLD] == SPLAT_IST)) {
		text_stream *S = Inter::Frame::ID_to_text(P, P->node->W.data[MATTER_SPLAT_IFLD]);
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, S, L" *(%C+) *(%c*);%c*")) {
			inter_t keyword = 0;
			if (Str::eq_insensitive(mr.exp[0], I"#ifdef")) keyword = IFDEF_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"#ifndef")) keyword = IFNDEF_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"#iftrue")) keyword = IFTRUE_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"#ifnot")) keyword = IFNOT_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"#endif")) keyword = ENDIF_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"#stub")) keyword = STUB_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Constant")) keyword = CONSTANT_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Global")) keyword = GLOBAL_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Array")) keyword = ARRAY_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"[")) keyword = ROUTINE_PLM;

			else if (Str::eq_insensitive(mr.exp[0], I"Attribute")) keyword = ATTRIBUTE_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Property")) keyword = PROPERTY_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Verb")) keyword = VERB_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Fake_action")) keyword = FAKEACTION_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Object")) keyword = OBJECT_PLM;
			else if (Str::eq_insensitive(mr.exp[0], I"Default")) keyword = DEFAULT_PLM;

			else { keyword = MYSTERY_PLM; LOG("Mystery: %S\n", mr.exp[0]); }
			P->node->W.data[PLM_SPLAT_IFLD] = keyword;
		} else {
			int keep = FALSE;
			LOOP_THROUGH_TEXT(pos, S)
				if (Characters::is_whitespace(Str::get(pos)) == FALSE)
					keep = TRUE;
			if (keep == FALSE) Inter::Frame::remove_from_tree(P);
		}
	}
}
