[CodeGen::MergeTemplate::] Linker.

To link inter from I7 with template code.

@h Link.

=
void CodeGen::MergeTemplate::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"merge-template", CodeGen::MergeTemplate::run_pipeline_stage, TEMPLATE_FILE_STAGE_ARG, TRUE);	
}

int CodeGen::MergeTemplate::run_pipeline_stage(pipeline_step *step) {
	inter_package *main_package = Site::main_package_if_it_exists(step->repository);
	inter_bookmark IBM;
	if (main_package) IBM = Inter::Bookmarks::at_end_of_this_package(main_package);
	else IBM = Inter::Bookmarks::at_start_of_this_repository(step->repository);
	CodeGen::MergeTemplate::link(&IBM, step->step_argument, step->the_PP, NULL);
	return TRUE;
}

void CodeGen::MergeTemplate::link(inter_bookmark *IBM, text_stream *template_file, linked_list *PP, inter_package *owner) {
	if (IBM == NULL) internal_error("no inter to link with");
	inter_tree *I = Inter::Bookmarks::tree(IBM);
	if (Str::eq(template_file, I"none"))
		Inter::Tree::traverse(I, CodeGen::MergeTemplate::catch_all_visitor, NULL, NULL, 0);
	else
		Inter::Tree::traverse(I, CodeGen::MergeTemplate::visitor, NULL, NULL, 0);

	inter_package *template_package = Site::ensure_assimilation_package(I, plain_ptype_symbol);	
	
	inter_bookmark link_bookmark =
		Inter::Bookmarks::at_end_of_this_package(template_package);

	I6T_kit kit = TemplateReader::kit_out(&link_bookmark, &(CodeGen::MergeTemplate::receive_raw),  &(CodeGen::MergeTemplate::receive_command), NULL);
	kit.no_i6t_file_areas = LinkedLists::len(PP);
	pathname *P;
	int i=0;
	LOOP_OVER_LINKED_LIST(P, pathname, PP)
		kit.i6t_files[i] = Pathnames::down(P, I"Sections");
	int stage = EARLY_LINK_STAGE;
	if (Str::eq(template_file, I"none")) stage = CATCH_ALL_LINK_STAGE;
	TEMPORARY_TEXT(T);
	TemplateReader::I6T_file_intervene(T, stage, NULL, NULL, &kit);
	CodeGen::MergeTemplate::receive_raw(T, &kit);
	DISCARD_TEXT(T);
	if (Str::ne(template_file, I"none"))
		TemplateReader::extract(template_file, &kit);
}

void CodeGen::MergeTemplate::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == LINK_IST) {
		text_stream *S1 = Inode::ID_to_text(P, P->W.data[SEGMENT_LINK_IFLD]);
		text_stream *S2 = Inode::ID_to_text(P, P->W.data[PART_LINK_IFLD]);
		text_stream *S3 = Inode::ID_to_text(P, P->W.data[TO_RAW_LINK_IFLD]);
		text_stream *S4 = Inode::ID_to_text(P, P->W.data[TO_SEGMENT_LINK_IFLD]);
		void *ref = Inode::ID_to_ref(P, P->W.data[REF_LINK_IFLD]);
		TemplateReader::new_intervention((int) P->W.data[STAGE_LINK_IFLD], S1, S2, S3, S4, ref);
	}
}

void CodeGen::MergeTemplate::catch_all_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == LINK_IST) {
		text_stream *S1 = NULL;
		text_stream *S2 = NULL;
		text_stream *S3 = Inode::ID_to_text(P, P->W.data[TO_RAW_LINK_IFLD]);
		text_stream *S4 = Inode::ID_to_text(P, P->W.data[TO_SEGMENT_LINK_IFLD]);
		void *ref = Inode::ID_to_ref(P, P->W.data[REF_LINK_IFLD]);
		TemplateReader::new_intervention((int) P->W.data[STAGE_LINK_IFLD], S1, S2, S3, S4, ref);
	}
}

void CodeGen::MergeTemplate::entire_splat(inter_bookmark *IBM, text_stream *origin, text_stream *content, inter_t level) {
	inter_t SID = Inter::Warehouse::create_text(Inter::Bookmarks::warehouse(IBM), Inter::Bookmarks::package(IBM));
	text_stream *glob_storage = Inter::Warehouse::get_text(Inter::Bookmarks::warehouse(IBM), SID);
	Str::copy(glob_storage, content);
	Produce::guard(Inter::Splat::new(IBM, SID, 0, level, 0, NULL));
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
void CodeGen::MergeTemplate::receive_raw(text_stream *S, I6T_kit *kit) {
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
			CodeGen::MergeTemplate::chunked_raw(R, kit);
			mode = IGNORE_WS_FILTER_BIT;
		}
	}
	CodeGen::MergeTemplate::chunked_raw(R, kit);
	Str::clear(S);
}

void CodeGen::MergeTemplate::chunked_raw(text_stream *S, I6T_kit *kit) {
	if (Str::len(S) == 0) return;
	PUT_TO(S, '\n');
	CodeGen::MergeTemplate::entire_splat(kit->IBM, I"template", S, (inter_t) (Inter::Bookmarks::baseline(kit->IBM) + 1));
	Str::clear(S);
}

void CodeGen::MergeTemplate::receive_command(OUTPUT_STREAM, text_stream *command, text_stream *argument, I6T_kit *kit) {
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
