[CodeGen::PackedText::] Consolidate Packed Text.

To alphabetise and make unique the packed text constants.

@h Pipeline stage.
This stage...

=
void CodeGen::PackedText::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"consolidate-text",
		CodeGen::PackedText::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int text_consolidation_list_extent = 0;
int text_consolidation_list_used = 0;
inter_tree_node **text_consolidation_list = NULL;

int CodeGen::PackedText::run_pipeline_stage(pipeline_step *step) {
	InterTree::traverse(step->repository, CodeGen::PackedText::visitor, NULL, NULL, 0);
	if (text_consolidation_list_used > 0) {
		LOG("%d text literals:\n", text_consolidation_list_used);

		qsort(text_consolidation_list, (size_t) text_consolidation_list_used, sizeof(inter_tree_node *),
			CodeGen::PackedText::compare_texts);

		inter_tree *I = step->repository;
		inter_package *pack = CodeGen::PackedText::texts_package(I);
		inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);

		text_stream *current = NULL;
		inter_symbol *current_s = NULL;
		for (int i=0, j=0; i<text_consolidation_list_used; i++) {
			inter_tree_node *P = text_consolidation_list[i];
			text_stream *S = CodeGen::PackedText::unpack(P);
			if (Str::cmp(S, current) != 0) {
				LOG("%d: %S\n", j++, S);
				TEMPORARY_TEXT(ALPHA)
				WRITE_TO(ALPHA, "alphabetised_text_%d", j);
				inter_ti ID = Inter::Warehouse::create_text(InterTree::warehouse(I),
					Inter::Bookmarks::package(&IBM));
				Str::copy(Inter::Warehouse::get_text(InterTree::warehouse(I), ID), S);
				inter_symbol *con_s = InterSymbolsTables::create_with_unique_name(Inter::Bookmarks::scope(&IBM), ALPHA);
				Inter::Symbols::annotate_i(con_s, TEXT_LITERAL_IANN, 1);
				Produce::guard(Inter::Constant::new_textual(&IBM,
					InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(&IBM), con_s),
					InterSymbolsTables::id_from_symbol(I, Inter::Bookmarks::package(&IBM), unchecked_kind_symbol),
					ID, (inter_ti) Inter::Bookmarks::baseline(&IBM) + 1, NULL));
				DISCARD_TEXT(ALPHA)
				current_s = con_s;
			}
				
			TEMPORARY_TEXT(ALPHA2)
			WRITE_TO(ALPHA2, "ref_text_%d", i);
			inter_symbol *ref_s = InterSymbolsTables::create_with_unique_name(Inter::Packages::scope(Inter::Packages::container(P)), ALPHA2);
			DISCARD_TEXT(ALPHA2)
			current = S;

			InterSymbolsTables::equate(ref_s, current_s);
			inter_ti val1 = 0, val2 = 0;
			Inter::Symbols::to_data(I, Inter::Packages::container(P), ref_s, &val1, &val2);
			P->W.data[FORMAT_CONST_IFLD] = CONSTANT_DIRECT;
			P->W.data[DATA_CONST_IFLD] = val1;
			P->W.data[DATA_CONST_IFLD+1] = val2;

			inter_symbol *con_name =
				InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			Inter::Symbols::unannotate(con_name, TEXT_LITERAL_IANN);

			LOG("P%d = %d\n", i, j-1);
		}
	}

	return TRUE;
}

inter_package *CodeGen::PackedText::texts_package(inter_tree *I) {
	if (I == NULL) internal_error("no tree for texts");
	inter_package *texts = Site::texts_package(I);
	if (texts == NULL) {
		inter_package *main_package = Site::main_package(I);
		if (main_package == NULL) internal_error("tree without main");
		texts = Inter::Packages::by_name(main_package, I"texts");
		if (texts == NULL) {
			inter_symbol *linkage = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_linkage");
			if (linkage == NULL) internal_error("no linkage ptype");
			inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(main_package);
			Inter::Package::new_package(&IBM, I"texts", linkage,
				(inter_ti) Inter::Bookmarks::baseline(&IBM)+1, NULL, &(texts));
		}
		if (texts == NULL) internal_error("unable to create texts package");
		Site::set_texts_package(I, texts);
		Inter::Packages::make_linklike(texts);
	}
	return texts;
}

int CodeGen::PackedText::compare_texts(const void *ent1, const void *ent2) {
	inter_tree_node *P1 = *((inter_tree_node **) ent1);
	inter_tree_node *P2 = *((inter_tree_node **) ent2);
	if (P1 == P2) return 0;
	text_stream *S1 = CodeGen::PackedText::unpack(P1);
	text_stream *S2 = CodeGen::PackedText::unpack(P2);
	return Str::cmp(S1, S2);
}

text_stream *CodeGen::PackedText::unpack(inter_tree_node *P) {
	if (P->W.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_TEXT) {
		inter_ti val1 = P->W.data[DATA_CONST_IFLD];
		return Inode::ID_to_text(P, val1);
	}
	internal_error("not indirect");
	return NULL;
}

void CodeGen::PackedText::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_name =
			InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		if (Inter::Symbols::read_annotation(con_name, TEXT_LITERAL_IANN) == 1) {
			if (text_consolidation_list_extent == 0) {
				text_consolidation_list_extent = 16;
				text_consolidation_list = (inter_tree_node **)
					(Memory::calloc(text_consolidation_list_extent,
						sizeof(inter_tree_node *), CODE_GENERATION_MREASON));
			}
			if (text_consolidation_list_used >= text_consolidation_list_extent) {
				int old_extent = text_consolidation_list_extent;
				text_consolidation_list_extent *= 4;
				inter_tree_node **new_list = (inter_tree_node **)
					(Memory::calloc(text_consolidation_list_extent,
						sizeof(inter_tree_node *), CODE_GENERATION_MREASON));
				for (int i=0; i<text_consolidation_list_used; i++)
					new_list[i] = text_consolidation_list[i];
				Memory::I7_free(text_consolidation_list, CODE_GENERATION_MREASON, old_extent);
				text_consolidation_list = new_list;
			}
			text_consolidation_list[text_consolidation_list_used++] = P;
		}
	}
}
