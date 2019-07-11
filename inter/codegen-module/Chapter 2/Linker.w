[CodeGen::Link::] Linker.

To link inter from I7 with template code.

@h Link.

=
void CodeGen::Link::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"link", CodeGen::Link::run_pipeline_stage, TEMPLATE_FILE_STAGE_ARG);	
}

int CodeGen::Link::run_pipeline_stage(pipeline_step *step) {
	inter_reading_state IRS = Inter::Bookmarks::new_IRS(step->repository);
	IRS.current_package = Inter::Packages::main(step->repository);
	IRS.cp_indent = 1;
	CodeGen::Link::link(&IRS, step->step_argument, step->the_N, step->the_PP, NULL);
	return TRUE;
}

inter_symbols_table *link_search_list[10];
int link_search_list_len = 0;

void CodeGen::Link::link(inter_reading_state *IRS, text_stream *template_file, int N, pathname **PP, inter_package *owner) {
	if (IRS == NULL) internal_error("no inter to link with");
	inter_repository *I = IRS->read_into;
	Inter::Packages::traverse_repository(I, CodeGen::Link::visitor, NULL);

	inter_symbol *TP = Inter::SymbolsTables::url_name_to_symbol(I, NULL, I"/main/template");
	if (TP == NULL) internal_error("unable to find template");
	inter_frame D = TP->definition;
	if (Inter::Frame::valid(&D) == FALSE) internal_error("template definition broken");
	inter_symbol *package_name = Inter::SymbolsTables::symbol_from_frame_data(D, DEFN_PACKAGE_IFLD);

	link_search_list[1] = Inter::Packages::scope(Inter::Packages::main(I));
	link_search_list[0] = Inter::Packages::scope(Inter::Package::which(package_name));
	link_search_list_len = 2;

	inter_reading_state link_bookmark = Inter::Bookmarks::from_package(Inter::Package::which(package_name));

	I6T_kit kit = TemplateReader::kit_out(&link_bookmark, &(CodeGen::Link::receive_raw),  &(CodeGen::Link::receive_command), NULL);
	kit.no_i6t_file_areas = N;
	for (int i=0; i<N; i++) kit.i6t_files[i] = PP[i];
	TEMPORARY_TEXT(T);
	TemplateReader::I6T_file_intervene(T, EARLY_LINK_STAGE, NULL, NULL, &kit);
	CodeGen::Link::receive_raw(T, &kit);
	DISCARD_TEXT(T);
	TemplateReader::extract(template_file, &kit);
}

void CodeGen::Link::visitor(inter_repository *I, inter_frame P, void *state) {
	if (P.data[ID_IFLD] == LINK_IST) {
		text_stream *S1 = Inter::get_text(P.repo_segment->owning_repo, P.data[SEGMENT_LINK_IFLD]);
		text_stream *S2 = Inter::get_text(P.repo_segment->owning_repo, P.data[PART_LINK_IFLD]);
		text_stream *S3 = Inter::get_text(P.repo_segment->owning_repo, P.data[TO_RAW_LINK_IFLD]);
		text_stream *S4 = Inter::get_text(P.repo_segment->owning_repo, P.data[TO_SEGMENT_LINK_IFLD]);
		void *ref = Inter::get_ref(P.repo_segment->owning_repo, P.data[REF_LINK_IFLD]);
		TemplateReader::new_intervention((int) P.data[STAGE_LINK_IFLD], S1, S2, S3, S4, ref);
	}
}

dictionary *linkable_namespace = NULL;
int linkable_namespace_created = FALSE;

inter_symbol *CodeGen::Link::find_in_namespace(inter_repository *I, text_stream *name) {
	if (linkable_namespace_created == FALSE) {
		linkable_namespace_created = TRUE;
		linkable_namespace = Dictionaries::new(512, FALSE);
		for (inter_package *P = Inter::Packages::main(I)->child_package; P; P = P->next_package)
			if (Str::ne(P->package_name->symbol_name, I"template"))
				CodeGen::Link::build_r(P);
	}
	if (Dictionaries::find(linkable_namespace, name))
		return (inter_symbol *) Dictionaries::read_value(linkable_namespace, name);
	return NULL;
}

void CodeGen::Link::build_r(inter_package *P) {
	inter_symbols_table *T = Inter::Packages::scope(P);
	if (T) {
		for (int i=0; i<T->size; i++) {
			inter_symbol *S = T->symbol_array[i];
			if ((Inter::Symbols::is_defined(S)) && (S->equated_to == NULL) &&
				(Inter::Symbols::get_flag(S, MAKE_NAME_UNIQUE) == FALSE)) {
				text_stream *name = S->symbol_name;
				if (Str::len(S->translate_text) > 0) name = S->translate_text;
				Dictionaries::create(linkable_namespace, name);
				Dictionaries::write_value(linkable_namespace, name, (void *) S);
			}
		}
	}
	for (P = P->child_package; P; P = P->next_package) CodeGen::Link::build_r(P);
}

inter_symbol *CodeGen::Link::find_name(inter_repository *I, text_stream *S, int deeply) {
	for (int i=0; i<link_search_list_len; i++) {
		inter_symbol *symb = Inter::SymbolsTables::symbol_from_name_not_equating(link_search_list[i], S);
		if (symb) return symb;
	}
	if (deeply) {
		inter_symbol *symb = CodeGen::Link::find_in_namespace(I, S);
		if (symb) return symb;
	}
	return NULL;
}

void CodeGen::Link::log_search_path(void) {
	for (int i=0; i<link_search_list_len; i++) {
		LOG("Search %d: $4\n", i, link_search_list[i]);
	}
}

int link_pie_count = 0;

void CodeGen::Link::guard(inter_error_message *ERR) {
	if (ERR) { Inter::Errors::issue(ERR); internal_error("inter error"); }
}

void CodeGen::Link::entire_splat(inter_reading_state *IRS, text_stream *origin, text_stream *content, inter_t level, inter_symbol *code_block) {
	inter_t SID = Inter::create_text(IRS->read_into);
	text_stream *glob_storage = Inter::get_text(IRS->read_into, SID);
	Str::copy(glob_storage, content);
	CodeGen::Link::guard(Inter::Splat::new(IRS, code_block, SID, 0, level, 0, NULL));
}

@

@d IGNORE_WS_FILTER_BIT 1
@d DQUOTED_FILTER_BIT 2
@d SQUOTED_FILTER_BIT 4
@d COMMENTED_FILTER_BIT 8
@d ROUTINED_FILTER_BIT 16
@d CONTENT_ON_LINE_FILTER_BIT 32

@d SUBORDINATE_FILTER_BITS (COMMENTED_FILTER_BIT + SQUOTED_FILTER_BIT + DQUOTED_FILTER_BIT + ROUTINED_FILTER_BIT)

=
void CodeGen::Link::receive_raw(text_stream *S, I6T_kit *kit) {
	text_stream *R = Str::new();
	int mode = IGNORE_WS_FILTER_BIT;
	LOOP_THROUGH_TEXT(pos, S) {
		wchar_t c = Str::get(pos);
		if ((c == 10) || (c == 13)) c = '\n';
		if (mode & IGNORE_WS_FILTER_BIT) {
			if ((c == '\n') || (Characters::is_whitespace(c))) continue;
			mode -= IGNORE_WS_FILTER_BIT;
		}
		if ((c == '!') && (!(mode & (DQUOTED_FILTER_BIT + SQUOTED_FILTER_BIT)))) {
			mode = mode | COMMENTED_FILTER_BIT;
		}
		if (mode & COMMENTED_FILTER_BIT) {
			if (c == '\n') {
				mode -= COMMENTED_FILTER_BIT;
				if (!(mode & CONTENT_ON_LINE_FILTER_BIT)) continue;
			}
			else continue;
		}
		if ((c == '[') && (!(mode & SUBORDINATE_FILTER_BITS))) {
			mode = mode | ROUTINED_FILTER_BIT;
		}
		if (mode & ROUTINED_FILTER_BIT) {
			if ((c == ']') && (!(mode & (DQUOTED_FILTER_BIT + SQUOTED_FILTER_BIT + COMMENTED_FILTER_BIT)))) mode -= ROUTINED_FILTER_BIT;
		}
		if ((c == '\'') && (!(mode & (DQUOTED_FILTER_BIT + COMMENTED_FILTER_BIT)))) {
			if (mode & SQUOTED_FILTER_BIT) mode -= SQUOTED_FILTER_BIT;
			else mode = mode | SQUOTED_FILTER_BIT;
		}
		if ((c == '\"') && (!(mode & (SQUOTED_FILTER_BIT + COMMENTED_FILTER_BIT)))) {
			if (mode & DQUOTED_FILTER_BIT) mode -= DQUOTED_FILTER_BIT;
			else mode = mode | DQUOTED_FILTER_BIT;
		}
		if (c != '\n') {
			if (Characters::is_whitespace(c) == FALSE) mode = mode | CONTENT_ON_LINE_FILTER_BIT;
		} else {
			if (mode & CONTENT_ON_LINE_FILTER_BIT) mode = mode - CONTENT_ON_LINE_FILTER_BIT;
			else if (!(mode & SUBORDINATE_FILTER_BITS)) continue;
		}
		PUT_TO(R, c);
		if ((c == ';') && (!(mode & SUBORDINATE_FILTER_BITS))) {
			CodeGen::Link::chunked_raw(R, kit);
			mode = IGNORE_WS_FILTER_BIT;
		}
	}
	CodeGen::Link::chunked_raw(R, kit);
	Str::clear(S);
}

void CodeGen::Link::chunked_raw(text_stream *S, I6T_kit *kit) {
	if (Str::len(S) == 0) return;
	PUT_TO(S, '\n');
	CodeGen::Link::entire_splat(kit->IRS, I"template", S, (inter_t) (kit->IRS->cp_indent + 1), kit->IRS->current_package->package_name);
	Str::clear(S);
}

void CodeGen::Link::receive_command(OUTPUT_STREAM, text_stream *command, text_stream *argument, I6T_kit *kit) {
	if ((Str::eq_wide_string(command, L"plugin")) ||
		(Str::eq_wide_string(command, L"type")) ||
		(Str::eq_wide_string(command, L"open-file")) ||
		(Str::eq_wide_string(command, L"close-file")) ||
		(Str::eq_wide_string(command, L"lines")) ||
		(Str::eq_wide_string(command, L"endlines")) ||
		(Str::eq_wide_string(command, L"open-index")) ||
		(Str::eq_wide_string(command, L"close-index")) ||
		(Str::eq_wide_string(command, L"index-page")) ||
		(Str::eq_wide_string(command, L"index-element")) ||
		(Str::eq_wide_string(command, L"index")) ||
		(Str::eq_wide_string(command, L"log")) ||
		(Str::eq_wide_string(command, L"log-phase")) ||
		(Str::eq_wide_string(command, L"progress-stage")) ||
		(Str::eq_wide_string(command, L"counter")) ||
		(Str::eq_wide_string(command, L"value")) ||
		(Str::eq_wide_string(command, L"read-assertions")) ||
		(Str::eq_wide_string(command, L"callv")) ||
		(Str::eq_wide_string(command, L"call")) ||
		(Str::eq_wide_string(command, L"array")) ||
		(Str::eq_wide_string(command, L"marker")) ||
		(Str::eq_wide_string(command, L"testing-routine")) ||
		(Str::eq_wide_string(command, L"testing-command"))) {
		LOG("command: <%S> argument: <%S>\n", command, argument);
		TemplateReader::error("the template command '{-%S}' has been withdrawn in this version of Inform", command);
	} else {
		LOG("command: <%S> argument: <%S>\n", command, argument);
		TemplateReader::error("no such {-command} as '%S'", command);
	}
}
