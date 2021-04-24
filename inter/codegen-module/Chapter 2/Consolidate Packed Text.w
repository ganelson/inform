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

int response_consolidation_list_extent = 0;
int response_consolidation_list_used = 0;
inter_tree_node **response_consolidation_list = NULL;

int CodeGen::PackedText::run_pipeline_stage(pipeline_step *step) {
	InterTree::traverse(step->repository, CodeGen::PackedText::visitor, NULL, NULL, 0);
	InterTree::traverse(step->repository, CodeGen::PackedText::synoptic_visitor, NULL, NULL, 0);
	if (text_consolidation_list_used > 0) {
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
		inter_symbol *con_s =
			InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		if (Inter::Symbols::read_annotation(con_s, TEXT_LITERAL_IANN) == 1) {
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
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = Inter::Package::defined_by_frame(P);
		inter_symbol *ptype = Inter::Packages::type(pack);
		if (ptype == PackageTypes::get(I, I"_response")) {
			if (response_consolidation_list_extent == 0) {
				response_consolidation_list_extent = 16;
				response_consolidation_list = (inter_tree_node **)
					(Memory::calloc(response_consolidation_list_extent,
						sizeof(inter_tree_node *), CODE_GENERATION_MREASON));
			}
			if (response_consolidation_list_used >= response_consolidation_list_extent) {
				int old_extent = response_consolidation_list_extent;
				response_consolidation_list_extent *= 4;
				inter_tree_node **new_list = (inter_tree_node **)
					(Memory::calloc(response_consolidation_list_extent,
						sizeof(inter_tree_node *), CODE_GENERATION_MREASON));
				for (int i=0; i<response_consolidation_list_used; i++)
					new_list[i] = response_consolidation_list[i];
				Memory::I7_free(response_consolidation_list, CODE_GENERATION_MREASON, old_extent);
				response_consolidation_list = new_list;
			}
			response_consolidation_list[response_consolidation_list_used++] = P;
		}
	}
}

@

@e NO_SYNID from 0
@e RESPONSEDIVISIONS_SYNID
@e RESPONSETEXTS_SYNID
@e NO_RESPONSES_SYNID
@e PRINT_RESPONSE_SYNID

void CodeGen::PackedText::synoptic_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == CONSTANT_IST) {
		inter_symbol *con_s =
			InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
		int synid = Inter::Symbols::read_annotation(con_s, SYNOPTIC_IANN);
		if (synid > NO_SYNID) {
			Inter::Symbols::unannotate(con_s, SYNOPTIC_IANN);
			inter_package *pack = Inter::Packages::container(P);
			inter_tree_node *Q = NULL;
			inter_bookmark IBM = Inter::Bookmarks::at_end_of_this_package(pack);
			switch (synid) {
				case RESPONSEDIVISIONS_SYNID:
					Inter::Symbols::strike_definition(con_s);
					@<Define the new ResponseDivisions array as Q@>;
					@<Finish up redefinition@>;
					break;
				case RESPONSETEXTS_SYNID:
					Inter::Symbols::strike_definition(con_s);
					@<Define the new ResponseTexts array as Q@>;
					@<Finish up redefinition@>;
					break;
				case NO_RESPONSES_SYNID:
					Inter::Symbols::strike_definition(con_s);
					inter_error_message *E = CodeGen::PackedText::redef_numeric_constant(con_s, (inter_ti) response_consolidation_list_used, &IBM);
					if (E) {
						Inter::Errors::issue(E);
						internal_error("wouldn't verify");
					}
					break;
				case PRINT_RESPONSE_SYNID: {
					inter_bookmark IBM;
					inter_package *block = CodeGen::PackedText::begin_redefining_function(&IBM, I, P);
					inter_symbol *R_s = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(block), I"R");
					inter_symbol *RPR_s = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(block), I"RPR");
					if (R_s == NULL) internal_error("no R");
					if (RPR_s == NULL) internal_error("no RPR");
					packaging_state save = I->site.current_state;
					Packaging::set_state(I, &IBM, Packaging::enclosure(I));
					LOG("RPR is $3\n", RPR_s);

					LOG("IBM is $5 with $6\n", &IBM, Inter::Packages::container(IBM.R));
					LOG("Bookmark is $5 with $6\n", Packaging::at(I), Inter::Packages::container(Packaging::at(I)->R));

					for (int i=0; i<response_consolidation_list_used; i++) {
						inter_package *pack = Inter::Package::defined_by_frame(response_consolidation_list[i]);
//						inter_symbol *value_s = CodeGen::PackedText::read_symbol_metadata(pack, I"^value");
						inter_ti m = CodeGen::PackedText::read_numeric_metadata(pack, I"^marker");
						inter_symbol *rule_s = CodeGen::PackedText::read_symbol_metadata(pack, I"^rule");
						Produce::inv_primitive(I, IF_BIP);
						Produce::down(I);
							Produce::inv_primitive(I, EQ_BIP);
							Produce::down(I);
								Produce::val_symbol(I, K_value, R_s);
								Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) i+1);
							Produce::up(I);
							Produce::code(I);
							Produce::down(I);
								Produce::inv_call(I, RPR_s);
								Produce::down(I);
									Produce::val_symbol(I, K_value, rule_s);
								Produce::up(I);
								Produce::inv_primitive(I, PRINT_BIP);
								Produce::down(I);
									Produce::val_text(I, I" response (");
								Produce::up(I);
								Produce::inv_primitive(I, PRINTCHAR_BIP);
								Produce::down(I);
									Produce::val(I, K_value, LITERAL_IVAL, (inter_ti) ('A' + m));
								Produce::up(I);
								Produce::inv_primitive(I, PRINT_BIP);
								Produce::down(I);
									Produce::val_text(I, I")");
								Produce::up(I);
							Produce::up(I);
						Produce::up(I);
					}
					Packaging::set_state(I, save.saved_IRS, save.saved_enclosure);
					CodeGen::PackedText::end_redefining_function(I, P);
					
					break;
				}
				default:
					LOG("Couldn't consolidate $3\n", con_s);
					internal_error("symbol cannot be consolidated");
			}
		}
	}
}

@<Finish up redefinition@> =
	inter_error_message *E = Inter::Defn::verify_construct(pack, Q);
	if (E) {
		Inter::Errors::issue(E);
		internal_error("wouldn't verify");
	}
	Inter::Bookmarks::insert(&IBM, Q);

@<Define the new ResponseDivisions array as Q@> =
	Q = CodeGen::PackedText::redef_array(con_s, &IBM);
	text_stream *current_group = NULL; int start_pos = -1;
	for (int i=0; i<response_consolidation_list_used; i++) {
		inter_package *pack = Inter::Package::defined_by_frame(response_consolidation_list[i]);

//		inter_ti m = CodeGen::PackedText::read_numeric_metadata(pack, I"^marker");
		text_stream *group = CodeGen::PackedText::read_textual_metadata(pack, I"^group");
//		inter_symbol *rule_s = CodeGen::PackedText::read_symbol_metadata(pack, I"^rule");

		if (Str::ne(group, current_group)) {
			if (start_pos >= 0) {
				CodeGen::PackedText::redef_textual_entry(Q, current_group);
				CodeGen::PackedText::redef_numeric_entry(Q, (inter_ti) start_pos + 1);
				CodeGen::PackedText::redef_numeric_entry(Q, (inter_ti) i);
			}
			current_group = group;
			start_pos = i;
		}
	}
	if (start_pos >= 0) {
		CodeGen::PackedText::redef_textual_entry(Q, current_group);
		CodeGen::PackedText::redef_numeric_entry(Q, (inter_ti) start_pos + 1);
		CodeGen::PackedText::redef_numeric_entry(Q, (inter_ti) response_consolidation_list_used);
	}
	CodeGen::PackedText::redef_numeric_entry(Q, 0);
	CodeGen::PackedText::redef_numeric_entry(Q, 0);
	CodeGen::PackedText::redef_numeric_entry(Q, 0);

@<Define the new ResponseTexts array as Q@> =
	Q = CodeGen::PackedText::redef_array(con_s, &IBM);
//	CodeGen::PackedText::redef_numeric_entry(Q, 0);
	for (int i=0; i<response_consolidation_list_used; i++) {
		inter_package *pack = Inter::Package::defined_by_frame(response_consolidation_list[i]);
		inter_symbol *value_s = CodeGen::PackedText::read_symbol_metadata(pack, I"^value");
		CodeGen::PackedText::redef_symbol_entry(Q, value_s);
	}
	CodeGen::PackedText::redef_numeric_entry(Q, 0);
	CodeGen::PackedText::redef_numeric_entry(Q, 0);

@

=
inter_package *CodeGen::PackedText::begin_redefining_function(inter_bookmark *IBM, inter_tree *I, inter_tree_node *P) {
	if (P->W.data[FORMAT_CONST_IFLD] != CONSTANT_ROUTINE) {
		LOG("%d\n", P->W.data[FORMAT_CONST_IFLD]);
		internal_error("not a function");
	}
	inter_package *block = Inode::ID_to_package(P, P->W.data[DATA_CONST_IFLD]);
	inter_tree_node *first_F = NULL;
	LOOP_THROUGH_INTER_CHILDREN(F, block->package_head)
		if (F->W.data[ID_IFLD] == CODE_IST)
			first_F = InterTree::first_child(F);
	if (first_F == NULL) internal_error("failed to find code block");
	Site::set_cir(I, block);
	*IBM = Inter::Bookmarks::after_this_node(I, first_F);
	Produce::push_code_position(I, Produce::new_cip(I, IBM), Inter::Bookmarks::snapshot(Packaging::at(I)));
	return block;
}

void CodeGen::PackedText::end_redefining_function(inter_tree *I, inter_tree_node *P) {
	Produce::pop_code_position(I);
	Site::set_cir(I, NULL);
}

inter_error_message *CodeGen::PackedText::redef_numeric_constant(inter_symbol *con_s, inter_ti val, inter_bookmark *IBM) {
	return Inter::Constant::new_numerical(IBM,
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_s),
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, list_of_unchecked_kind_symbol),
		LITERAL_IVAL, val, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1, NULL);
}
inter_tree_node *CodeGen::PackedText::redef_array(inter_symbol *con_s, inter_bookmark *IBM) {
	return Inode::fill_3(IBM, CONSTANT_IST,
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, con_s),
		 InterSymbolsTables::id_from_IRS_and_symbol(IBM, list_of_unchecked_kind_symbol),
		 CONSTANT_INDIRECT_LIST, NULL, (inter_ti) Inter::Bookmarks::baseline(IBM) + 1);
}
void CodeGen::PackedText::redef_numeric_entry(inter_tree_node *Q, inter_ti val2) {
	if (Inode::extend(Q, 2) == FALSE) internal_error("cannot extend");
	Q->W.data[Q->W.extent-2] = LITERAL_IVAL;
	Q->W.data[Q->W.extent-1] = val2;
}
void CodeGen::PackedText::redef_symbol_entry(inter_tree_node *Q, inter_symbol *S) {
	if (Inode::extend(Q, 2) == FALSE) internal_error("cannot extend");
	inter_package *pack = Inter::Packages::container(Q);
	inter_symbol *local_S = InterSymbolsTables::create_with_unique_name(Inter::Packages::scope(pack), S->symbol_name);
	InterSymbolsTables::equate(local_S, S);
	inter_ti val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Packages::tree(pack), pack, local_S, &val1, &val2);
	Q->W.data[Q->W.extent-2] = ALIAS_IVAL;
	Q->W.data[Q->W.extent-1] = val2;
}
void CodeGen::PackedText::redef_textual_entry(inter_tree_node *Q, text_stream *text) {
	if (Inode::extend(Q, 2) == FALSE) internal_error("cannot extend");
	inter_package *pack = Inter::Packages::container(Q);
	inter_tree *I = Inter::Packages::tree(pack);
	inter_ti val2 = Inter::Warehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *glob_storage = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
	Str::copy(glob_storage, text);
	Q->W.data[Q->W.extent-2] = LITERAL_TEXT_IVAL;
	Q->W.data[Q->W.extent-1] = val2;
}

inter_symbol *CodeGen::PackedText::read_symbol_metadata(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) {
		LOG("unable to find metadata key %S in package $6\n", key, pack);
		internal_error("not found");
	}
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) {
		LOG("%d\n", D->W.data[FORMAT_CONST_IFLD]);
		internal_error("not direct");
	}
	if (D->W.data[DATA_CONST_IFLD] != ALIAS_IVAL) internal_error("not symbol");

	inter_symbol *s = InterSymbolsTables::symbol_from_id(Inter::Packages::scope(pack),
		D->W.data[DATA_CONST_IFLD + 1]);
	if (s == NULL) internal_error("no symbol");
	return s;
}

inter_ti CodeGen::PackedText::read_numeric_metadata(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) internal_error("not found");
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_DIRECT) internal_error("not direct");
	if (D->W.data[DATA_CONST_IFLD] != LITERAL_IVAL) internal_error("not literal");
	return D->W.data[DATA_CONST_IFLD + 1];
}

text_stream *CodeGen::PackedText::read_textual_metadata(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTables::symbol_from_name(Inter::Packages::scope(pack), key);
	if (md == NULL) internal_error("not found");
	inter_tree_node *D = md->definition;
	if (D == NULL) internal_error("not defined");
	if (D->W.data[FORMAT_CONST_IFLD] != CONSTANT_INDIRECT_TEXT)  {
		LOG("%d\n", D->W.data[FORMAT_CONST_IFLD]);
		internal_error("not text");
	}
	return Inode::ID_to_text(D, D->W.data[DATA_CONST_IFLD]);
}

@ This is in effect a big switch statement, so it's not fast; but as usual
with printing routines it really doesn't need to be. Given a response value,
say |R_14_RESP_B|, we print its current text, say response (B) for |R_14|.

@ The following array is used only by the testing command RESPONSES, and
enables the Inter template to print out all known responses at run-time,
divided up by the extensions containing the rules which produce them.
