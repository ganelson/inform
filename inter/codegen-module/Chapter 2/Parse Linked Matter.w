[CodeGen::PLM::] Parse Linked Matter.

To generate the initial state of storage for variables.

@h Parsing.

=
void CodeGen::PLM::parse(inter_repository *I) {
	inter_frame P;
	LOOP_THROUGH_FRAMES(P, I) {
		inter_package *outer = Inter::Packages::container(P);
		if (((outer == NULL) || (outer->codelike_package == FALSE)) && (P.data[ID_IFLD] == SPLAT_IST)) {
			text_stream *S = Inter::get_text(P.repo_segment->owning_repo, P.data[MATTER_SPLAT_IFLD]);
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
				P.data[PLM_SPLAT_IFLD] = keyword;
			} else {
				int keep = FALSE;
				LOOP_THROUGH_TEXT(pos, S)
					if (Characters::is_whitespace(Str::get(pos)) == FALSE)
						keep = TRUE;
				if (keep == FALSE) Inter::Nop::nop_out(I, P);
			}
		}
	}
}
