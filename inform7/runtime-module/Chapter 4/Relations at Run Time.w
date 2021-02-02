[RTRelations::] Relations at Run Time.

Relations need both storage and support code at runtime.

@h Data.
Each binary predicate has an instance of the following attached to it:

=
typedef struct bp_runtime_implementation {
	struct package_request *bp_package;
	struct inter_name *bp_iname; /* when referred to as a constant */
	struct inter_name *handler_iname;
	struct inter_name *initialiser_iname; /* if stored in dynamically allocated memory */
	int record_needed; /* we need to compile a small array of details in readable memory */	
	int fast_route_finding; /* use fast rather than slow route-finding algorithm? */
	CLASS_DEFINITION
} bp_runtime_implementation;

bp_runtime_implementation *RTRelations::implement(binary_predicate *bp) {
	bp_runtime_implementation *imp = CREATE(bp_runtime_implementation);
	imp->bp_package = NULL;
	imp->bp_iname = NULL;
	imp->handler_iname = NULL;
	imp->initialiser_iname = NULL;
	imp->record_needed = FALSE;
	imp->fast_route_finding = FALSE;
	return imp;
}

package_request *RTRelations::package(binary_predicate *bp) {
	if (bp == NULL) internal_error("null bp");
	if (bp->imp->bp_package == NULL)
		bp->imp->bp_package =
			Hierarchy::package(CompilationUnits::find(bp->bp_created_at), RELATIONS_HAP);
	return bp->imp->bp_package;
}

inter_name *RTRelations::initialiser_iname(binary_predicate *bp) {
	if (bp->imp->initialiser_iname == NULL) {
		package_request *P = RTRelations::package(bp);
		bp->imp->initialiser_iname = Hierarchy::make_iname_in(RELATION_INITIALISER_FN_HL, P);
	}
	return bp->imp->initialiser_iname;
}

inter_name *RTRelations::handler_iname(binary_predicate *bp) {
	if (bp->imp->handler_iname == NULL) {
		package_request *R = RTRelations::package(bp);
		bp->imp->handler_iname = Hierarchy::make_iname_in(HANDLER_FN_HL, R);
	}
	return bp->imp->handler_iname;
}

inter_name *RTRelations::iname(binary_predicate *bp) {
	if (bp == NULL) return NULL;
	return bp->imp->bp_iname;
}

inter_name *default_rr = NULL;
inter_name *RTRelations::default_iname(void) {
	return default_rr;
}

void RTRelations::mark_as_needed(binary_predicate *bp) {
	if (bp->imp->record_needed == FALSE) {
		bp->imp->bp_iname = Hierarchy::make_iname_in(RELATION_RECORD_HL, RTRelations::package(bp));
		if (default_rr == NULL) {
			default_rr = bp->imp->bp_iname;
			inter_name *iname = Hierarchy::find(MEANINGLESS_RR_HL);
			Emit::named_iname_constant(iname, K_value, RTRelations::default_iname());
			Hierarchy::make_available(Emit::tree(), iname);
		}
	}
	bp->imp->record_needed = TRUE;
}

void RTRelations::use_frf(binary_predicate *bp) {
	bp->imp->fast_route_finding = TRUE;
	bp->reversal->imp->fast_route_finding = TRUE;
}

@h Relation records.
The template layer needs to be able to perform certain actions on any given
relation, regardless of its mode of storage (if any). We abstract all of this
by giving each relation a "record", which says what it can do, how it does
it, and where it stores its data.

@ The following permissions are intended to form a bitmap in arbitrary
combinations.

=
inter_name *RELS_SYMMETRIC_iname = NULL;
inter_name *RELS_EQUIVALENCE_iname = NULL;
inter_name *RELS_X_UNIQUE_iname = NULL;
inter_name *RELS_Y_UNIQUE_iname = NULL;
inter_name *RELS_TEST_iname = NULL;
inter_name *RELS_ASSERT_TRUE_iname = NULL;
inter_name *RELS_ASSERT_FALSE_iname = NULL;
inter_name *RELS_SHOW_iname = NULL;
inter_name *RELS_ROUTE_FIND_iname = NULL;
inter_name *RELS_ROUTE_FIND_COUNT_iname = NULL;
inter_name *RELS_LOOKUP_ANY_iname = NULL;
inter_name *RELS_LOOKUP_ALL_X_iname = NULL;
inter_name *RELS_LOOKUP_ALL_Y_iname = NULL;
inter_name *RELS_LIST_iname = NULL;
inter_name *REL_BLOCK_HEADER_symbol = NULL;
inter_name *TTF_iname = NULL;

inter_name *RTRelations::compile_defined_relation_constant(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant_hex(iname, val);
	return iname;
}

void RTRelations::compile_defined_relation_constants(void) {
	RELS_SYMMETRIC_iname = RTRelations::compile_defined_relation_constant(RELS_SYMMETRIC_HL, 0x8000);
	RELS_EQUIVALENCE_iname = RTRelations::compile_defined_relation_constant(RELS_EQUIVALENCE_HL, 0x4000);
	RELS_X_UNIQUE_iname = RTRelations::compile_defined_relation_constant(RELS_X_UNIQUE_HL, 0x2000);
	RELS_Y_UNIQUE_iname = RTRelations::compile_defined_relation_constant(RELS_Y_UNIQUE_HL, 0x1000);
	RELS_TEST_iname = RTRelations::compile_defined_relation_constant(RELS_TEST_HL, 0x0800);
	RELS_ASSERT_TRUE_iname = RTRelations::compile_defined_relation_constant(RELS_ASSERT_TRUE_HL, 0x0400);
	RELS_ASSERT_FALSE_iname = RTRelations::compile_defined_relation_constant(RELS_ASSERT_FALSE_HL, 0x0200);
	RELS_SHOW_iname = RTRelations::compile_defined_relation_constant(RELS_SHOW_HL, 0x0100);
	RELS_ROUTE_FIND_iname = RTRelations::compile_defined_relation_constant(RELS_ROUTE_FIND_HL, 0x0080);
	RELS_ROUTE_FIND_COUNT_iname = RTRelations::compile_defined_relation_constant(RELS_ROUTE_FIND_COUNT_HL, 0x0040);
	RELS_LOOKUP_ANY_iname = RTRelations::compile_defined_relation_constant(RELS_LOOKUP_ANY_HL, 0x0008);
	RELS_LOOKUP_ALL_X_iname = RTRelations::compile_defined_relation_constant(RELS_LOOKUP_ALL_X_HL, 0x0004);
	RELS_LOOKUP_ALL_Y_iname = RTRelations::compile_defined_relation_constant(RELS_LOOKUP_ALL_Y_HL, 0x0002);
	RELS_LIST_iname = RTRelations::compile_defined_relation_constant(RELS_LIST_HL, 0x0001);
	if (TargetVMs::is_16_bit(Task::vm())) {
		REL_BLOCK_HEADER_symbol = RTRelations::compile_defined_relation_constant(REL_BLOCK_HEADER_HL, 0x100*5 + 13); /* $2^5 = 32$ bytes block */
	} else {
		REL_BLOCK_HEADER_symbol = RTRelations::compile_defined_relation_constant(REL_BLOCK_HEADER_HL, (0x100*6 + 13)*0x10000);
	}
	TTF_iname = RTRelations::compile_defined_relation_constant(TTF_SUM_HL, (0x0800 + 0x0400 + 0x0200));
	/* i.e., |RELS_TEST + RELS_ASSERT_TRUE + RELS_ASSERT_FALSE| */
}

@ =
void RTRelations::compile_relation_records(void) {
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate) {
		binary_predicate *dbp = bp;
		if (bp->right_way_round == FALSE) dbp = bp->reversal;
		int minimal = FALSE;
		if ((dbp == R_equality) || (dbp == R_meaning) ||
			(dbp == R_provision) || (dbp == R_universal))
			minimal = TRUE;
		if (bp->imp->record_needed) {
			inter_name *handler = NULL;
			if (Relations::Explicit::stored_dynamically(bp) == FALSE)
				@<Write the relation handler routine for this BP@>;
			@<Write the relation record for this BP@>;
		}
	}
	inter_name *iname = Hierarchy::find(CREATEDYNAMICRELATIONS_HL);
	packaging_state save = Routines::begin(iname);
	LocalVariables::add_internal_local_c_as_symbol(I"i", "loop counter");
	LocalVariables::add_internal_local_c_as_symbol(I"rel", "new relation");
	LOOP_OVER(bp, binary_predicate) {
		if ((Relations::Explicit::stored_dynamically(bp)) && (bp->right_way_round)) {

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUECREATE_HL));
			Produce::down(Emit::tree());
				Kinds::RunTime::emit_strong_id_as_val(BinaryPredicates::kind(bp));
				Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
			Produce::up(Emit::tree());

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_NAME_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
				TEMPORARY_TEXT(A)
				WRITE_TO(A, "%A", &(bp->relation_name));
				Produce::val_text(Emit::tree(), A);
				DISCARD_TEXT(A)
			Produce::up(Emit::tree());

			switch(Relations::Explicit::get_form_of_relation(bp)) {
				case Relation_OtoO:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_OTOOADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_OtoV:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_OTOVADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_VtoO:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_VTOOADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_Sym_OtoO:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_OTOOADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_SYMMETRICADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_Equiv:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_EQUIVALENCEADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
				case Relation_VtoV: break;
				case Relation_Sym_VtoV:
					Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELATION_TY_SYMMETRICADJECTIVE_HL));
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
						Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
					break;
			}
			Produce::inv_primitive(Emit::tree(), INDIRECT0V_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, RTRelations::initialiser_iname(bp));
			Produce::up(Emit::tree());
		}
	}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@<Write the relation record for this BP@> =
	if (RTRelations::iname(bp) == NULL) internal_error("no bp symbol");
	packaging_state save = Emit::named_array_begin(RTRelations::iname(bp), K_value);
	if (Relations::Explicit::stored_dynamically(bp)) {
		Emit::array_numeric_entry((inter_ti) 1); /* meaning one entry, which is 0; to be filled in later */
	} else {
		Kinds::RunTime::emit_block_value_header(BinaryPredicates::kind(bp), FALSE, 8);
		Emit::array_null_entry();
		Emit::array_null_entry();
		@<Write the name field of the relation record@>;
		@<Write the permissions field of the relation record@>;
		@<Write the storage field of the relation metadata array@>;
		@<Write the kind field of the relation record@>;
		@<Write the handler field of the relation record@>;
		@<Write the description field of the relation record@>;
	}
	Emit::array_end(save);

@<Write the name field of the relation record@> =
	TEMPORARY_TEXT(NF)
	WRITE_TO(NF, "%A relation", &(bp->relation_name));
	Emit::array_text_entry(NF);
	DISCARD_TEXT(NF)

@<Write the permissions field of the relation record@> =
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) dbp = bp->reversal;
	inter_name *bm_symb = Hierarchy::make_iname_in(ABILITIES_HL, bp->imp->bp_package);
	packaging_state save_sum = Emit::sum_constant_begin(bm_symb, K_value);
	if (RELS_TEST_iname == NULL) internal_error("no RELS symbols yet");
	Emit::array_iname_entry(RELS_TEST_iname);
	if (minimal == FALSE) {
		Emit::array_iname_entry(RELS_LOOKUP_ANY_iname);
		Emit::array_iname_entry(Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
		Emit::array_iname_entry(Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
		Emit::array_iname_entry(RELS_LIST_iname);
	}
	switch(Relations::Explicit::get_form_of_relation(dbp)) {
		case Relation_Implicit:
			if ((minimal == FALSE) && (BinaryPredicates::can_be_made_true_at_runtime(dbp))) {
				Emit::array_iname_entry(RELS_ASSERT_TRUE_iname);
				Emit::array_iname_entry(RELS_ASSERT_FALSE_iname);
				Emit::array_iname_entry(RELS_LOOKUP_ANY_iname); // Really?
			}
			break;
		case Relation_OtoO: Emit::array_iname_entry(RELS_X_UNIQUE_iname); Emit::array_iname_entry(RELS_Y_UNIQUE_iname); @<Throw in the full suite@>; break;
		case Relation_OtoV: Emit::array_iname_entry(RELS_X_UNIQUE_iname); @<Throw in the full suite@>; break;
		case Relation_VtoO: Emit::array_iname_entry(RELS_Y_UNIQUE_iname); @<Throw in the full suite@>; break;
		case Relation_Sym_OtoO:
			Emit::array_iname_entry(RELS_SYMMETRIC_iname);
			Emit::array_iname_entry(RELS_X_UNIQUE_iname);
			Emit::array_iname_entry(RELS_Y_UNIQUE_iname);
			@<Throw in the full suite@>; break;
		case Relation_Equiv: Emit::array_iname_entry(RELS_EQUIVALENCE_iname); @<Throw in the full suite@>; break;
		case Relation_VtoV: @<Throw in the full suite@>; break;
		case Relation_Sym_VtoV: Emit::array_iname_entry(RELS_SYMMETRIC_iname); @<Throw in the full suite@>; break;
		default:
			internal_error("Binary predicate with unknown structural type");
	}
	Emit::array_end(save_sum); /* of the summation, that is */
	Emit::array_iname_entry(bm_symb);

@<Throw in the full suite@> =
	Emit::array_iname_entry(RELS_ASSERT_TRUE_iname);
	Emit::array_iname_entry(RELS_ASSERT_FALSE_iname);
	Emit::array_iname_entry(RELS_SHOW_iname);
	Emit::array_iname_entry(RELS_ROUTE_FIND_iname);

@ The storage field has different meanings for different families of BPs:

@<Write the storage field of the relation metadata array@> =
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) dbp = bp->reversal;
	if (bp->relation_family == by_routine_bp_family) {
		/* Field 0 is the routine used to test the relation */
		by_routine_bp_data *D = RETRIEVE_POINTER_by_routine_bp_data(dbp->family_specific);
		Emit::array_iname_entry(D->bp_by_routine_iname);
	} else {
		switch(Relations::Explicit::get_form_of_relation(dbp)) {
			case Relation_Implicit: /* Field 0 is not used */
				Emit::array_numeric_entry(0); /* which is not the same as |NULL|, unlike in C */
				break;
			case Relation_OtoO:
			case Relation_OtoV:
			case Relation_VtoO:
			case Relation_Sym_OtoO:
			case Relation_Equiv: /* Field 0 is the property used for run-time storage */
				Emit::array_iname_entry(
					Properties::iname(Relations::Explicit::get_i6_storage_property(dbp)));
				break;
			case Relation_VtoV:
			case Relation_Sym_VtoV: {
				/* Field 0 is the bitmap array used for run-time storage */
				explicit_bp_data *ED = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
				if (ED->v2v_bitmap_iname == NULL) internal_error("gaah");
				Emit::array_iname_entry(ED->v2v_bitmap_iname);
				break;
			}
		}
	}

@<Write the kind field of the relation record@> =
	Kinds::RunTime::emit_strong_id(BinaryPredicates::kind(bp));

@<Write the description field of the relation record@> =
	TEMPORARY_TEXT(DF)
	if (Relations::Explicit::get_form_of_relation(bp) == Relation_Implicit)
		WRITE_TO(DF, "%S", BinaryPredicates::get_log_name(bp));
	else CompiledText::from_text(DF, Node::get_text(bp->bp_created_at));
	Emit::array_text_entry(DF);
	DISCARD_TEXT(DF)

@<Write the handler field of the relation record@> =
	Emit::array_iname_entry(handler);

@<Write the relation handler routine for this BP@> =
	text_stream *X = I"X", *Y = I"Y";
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) { X = I"Y"; Y = I"X"; dbp = bp->reversal; }

	handler = RTRelations::handler_iname(bp);
	packaging_state save = Routines::begin(handler);
	inter_symbol *rr_s = LocalVariables::add_named_call_as_symbol(I"rr");
	inter_symbol *task_s = LocalVariables::add_named_call_as_symbol(I"task");
	local_variable *X_lv = NULL, *Y_lv = NULL;
	inter_symbol *X_s = LocalVariables::add_named_call_as_symbol_noting(I"X", &X_lv);
	inter_symbol *Y_s = LocalVariables::add_named_call_as_symbol_noting(I"Y", &Y_lv);
	local_variable *Z1_lv = NULL, *Z2_lv = NULL, *Z3_lv = NULL, *Z4_lv = NULL;
	inter_symbol *Z1_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"Z1", "loop counter", &Z1_lv);
	LocalVariables::add_internal_local_c_as_symbol_noting(I"Z2", "loop counter", &Z2_lv);
	inter_symbol *Z3_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"Z3", "loop counter", &Z3_lv);
	LocalVariables::add_internal_local_c_as_symbol_noting(I"Z4", "loop counter", &Z4_lv);

	annotated_i6_schema asch; i6_schema *i6s = NULL;

	Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, task_s);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), CASE_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					@<The TEST task@>;
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			if (minimal) {
				Produce::inv_primitive(Emit::tree(), DEFAULT_BIP);
				Produce::down(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The default case for minimal relations only@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			} else {
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LOOKUP_ANY_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LOOKUP ANY task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LOOKUP ALL X task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LOOKUP_ALL_Y_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LOOKUP ALL Y task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), CASE_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_LIST_HL));
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						@<The LIST task@>;
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				if (BinaryPredicates::can_be_made_true_at_runtime(bp)) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ASSERT_TRUE_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ASSERT TRUE task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ASSERT_FALSE_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ASSERT FALSE task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
				inter_name *shower = NULL;
				int par = 0;
				switch(Relations::Explicit::get_form_of_relation(dbp)) {
					case Relation_OtoO: shower = Hierarchy::find(RELATION_RSHOWOTOO_HL); break;
					case Relation_OtoV: shower = Hierarchy::find(RELATION_RSHOWOTOO_HL); break;
					case Relation_VtoO: shower = Hierarchy::find(RELATION_SHOWOTOO_HL); break;
					case Relation_Sym_OtoO: shower = Hierarchy::find(RELATION_SHOWOTOO_HL); par = 1; break;
					case Relation_Equiv: shower = Hierarchy::find(RELATION_SHOWEQUIV_HL); break;
					case Relation_VtoV: shower = Hierarchy::find(RELATION_SHOWVTOV_HL); break;
					case Relation_Sym_VtoV: shower = Hierarchy::find(RELATION_SHOWVTOV_HL); par = 1; break;
				}
				if (shower) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_SHOW_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The SHOW task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
				inter_name *emptier = NULL;
				par = 0;
				switch(Relations::Explicit::get_form_of_relation(dbp)) {
					case Relation_OtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_OtoV: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_VtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_Sym_OtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); par = 1; break;
					case Relation_Equiv: emptier = Hierarchy::find(RELATION_EMPTYEQUIV_HL); break;
					case Relation_VtoV: emptier = Hierarchy::find(RELATION_EMPTYVTOV_HL); break;
					case Relation_Sym_VtoV: emptier = Hierarchy::find(RELATION_EMPTYVTOV_HL); par = 1; break;
				}
				if (emptier) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_EMPTY_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The EMPTY task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
				inter_name *router = NULL;
				int id_flag = TRUE;
				int follow = FALSE;
				switch(Relations::Explicit::get_form_of_relation(dbp)) {
					case Relation_OtoO: router = Hierarchy::find(OTOVRELROUTETO_HL); follow = TRUE; break;
					case Relation_OtoV: router = Hierarchy::find(OTOVRELROUTETO_HL); follow = TRUE; break;
					case Relation_VtoO: router = Hierarchy::find(VTOORELROUTETO_HL); follow = TRUE; break;
					case Relation_VtoV:
					case Relation_Sym_VtoV:
						id_flag = FALSE;
						router = Hierarchy::find(VTOVRELROUTETO_HL);
						break;
				}
				if (router) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ROUTE_FIND_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ROUTE FIND task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_ROUTE_FIND_COUNT_HL));
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							@<The ROUTE FIND COUNT task@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
			}
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::rfalse(Emit::tree());
	Routines::end(save);

@<The default case for minimal relations only@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RUNTIMEPROBLEM_HL));
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RTP_RELMINIMAL_HL));
		Produce::val_symbol(Emit::tree(), K_value, task_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
	Produce::up(Emit::tree());

@<The ASSERT TRUE task@> =
	asch = Atoms::Compile::blank_asch();
	i6s = BinaryPredicateFamilies::get_schema(NOW_ATOM_TRUE_TASK, dbp, &asch);
	if (i6s == NULL) Produce::rfalse(Emit::tree());
	else {
		EmitSchemas::emit_expand_from_locals(i6s, X_lv, Y_lv, TRUE);
		Produce::rtrue(Emit::tree());
	}

@<The ASSERT FALSE task@> =
	asch = Atoms::Compile::blank_asch();
	i6s = BinaryPredicateFamilies::get_schema(NOW_ATOM_FALSE_TASK, dbp, &asch);
	if (i6s == NULL) Produce::rfalse(Emit::tree());
	else {
		EmitSchemas::emit_expand_from_locals(i6s, X_lv, Y_lv, TRUE);
		Produce::rtrue(Emit::tree());
	}

@<The TEST task@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		asch = Atoms::Compile::blank_asch();
		i6s = BinaryPredicateFamilies::get_schema(TEST_ATOM_TASK, dbp, &asch);
		int adapted = FALSE;
		for (int j=0; j<2; j++) {
			i6_schema *fnsc = BinaryPredicates::get_term_as_fn_of_other(bp, j);
			if (fnsc) {
				if (j == 0) {
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, X_s);
						EmitSchemas::emit_val_expand_from_locals(fnsc, Y_lv, Y_lv);
					Produce::up(Emit::tree());
					adapted = TRUE;
				} else {
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, Y_s);
						EmitSchemas::emit_val_expand_from_locals(fnsc, X_lv, X_lv);
					Produce::up(Emit::tree());
					adapted = TRUE;
				}
			}
		}
		if (adapted == FALSE) {
			if (i6s == NULL) Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			else EmitSchemas::emit_val_expand_from_locals(i6s, X_lv, Y_lv);
		}
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::rtrue(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::rfalse(Emit::tree());

@<The ROUTE FIND task@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), INDIRECT3_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, router);
			@<Expand the ID operand@>;
			Produce::val_symbol(Emit::tree(), K_value, X_s);
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<Expand the ID operand@> =
	if (id_flag) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RLNGETF_HL));
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, rr_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RR_STORAGE_HL));
		Produce::up(Emit::tree());
	} else {
		Produce::val_symbol(Emit::tree(), K_value, rr_s);
	}

@<The ROUTE FIND COUNT task@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
	if (follow) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RELFOLLOWVECTOR_HL));
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), INDIRECT3_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, router);
				@<Expand the ID operand@>;
				Produce::val_symbol(Emit::tree(), K_value, X_s);
				Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::up(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, X_s);
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, router);
			@<Expand the ID operand@>;
			Produce::val_symbol(Emit::tree(), K_value, X_s);
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	}
	Produce::up(Emit::tree());

@<The SHOW task@> =
	Produce::inv_primitive(Emit::tree(), INDIRECT2V_BIP);
	Produce::down(Emit::tree());
		Produce::val_iname(Emit::tree(), K_value, shower);
		Produce::val_symbol(Emit::tree(), K_value, rr_s);
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, (inter_ti) par);
	Produce::up(Emit::tree());
	Produce::rtrue(Emit::tree());

@<The EMPTY task@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), INDIRECT3_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, emptier);
			Produce::val_symbol(Emit::tree(), K_value, rr_s);
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, (inter_ti) par);
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, X_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<The LOOKUP ANY task@> =
	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), OR_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, Y_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_GET_X_HL));
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, Y_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			int t = 0;
			@<Write rels lookup@>;
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			t = 1;
			@<Write rels lookup@>;
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@<The LOOKUP ALL X task@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	int t = 0;
	@<Write rels lookup list@>;

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
	Produce::up(Emit::tree());

@<The LOOKUP ALL Y task@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	int t = 1;
	@<Write rels lookup list@>;

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, Y_s);
	Produce::up(Emit::tree());

@<The LIST task@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, X_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLIST_ALL_X_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			int t = 0;
			@<Write rels lookup list all@>;
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, Y_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLIST_ALL_Y_HL));
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					t = 1;
					@<Write rels lookup list all@>;
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, X_s);
	Produce::up(Emit::tree());

@<Write rels lookup@> =
	kind *K = BinaryPredicates::term_kind(dbp, t);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (K == NULL)) K = K_object;
	#endif
	if (Calculus::Deferrals::has_finite_domain(K)) {
		i6_schema loop_schema;
		if (Calculus::Deferrals::write_loop_schema(&loop_schema, K)) {
			EmitSchemas::emit_expand_from_locals(&loop_schema, Z1_lv, Z2_lv, TRUE);
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, RTRelations::handler_iname(dbp));
							Produce::val_symbol(Emit::tree(), K_value, rr_s);
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
							if (t == 0) {
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
								Produce::val_symbol(Emit::tree(), K_value, X_s);
							} else {
								Produce::val_symbol(Emit::tree(), K_value, X_s);
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							}
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, Y_s);
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
								Produce::up(Emit::tree());
								Produce::code(Emit::tree());
								Produce::down(Emit::tree());
									Produce::rtrue(Emit::tree());
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());

							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), EQ_BIP);
								Produce::down(Emit::tree());
									Produce::val_symbol(Emit::tree(), K_value, Y_s);
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_Y_HL));
								Produce::up(Emit::tree());
								Produce::code(Emit::tree());
								Produce::down(Emit::tree());
									Produce::rtrue(Emit::tree());
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());

							Produce::inv_primitive(Emit::tree(), RETURN_BIP);
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::rfalse(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, Y_s);
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RLANY_CAN_GET_Y_HL));
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::rfalse(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	if (K == NULL) Produce::rfalse(Emit::tree());
	else {
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DEFAULTVALUEOFKOV_HL));
			Produce::down(Emit::tree());
				Kinds::RunTime::emit_strong_id_as_val(K);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}

@<Write rels lookup list@> =
	kind *K = BinaryPredicates::term_kind(dbp, t);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (K == NULL)) K = K_object;
	#endif
	if (Calculus::Deferrals::has_finite_domain(K)) {
		i6_schema loop_schema;
		if (Calculus::Deferrals::write_loop_schema(&loop_schema, K)) {
			EmitSchemas::emit_expand_from_locals(&loop_schema, Z1_lv, Z2_lv, TRUE);
					Produce::inv_primitive(Emit::tree(), IF_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
						Produce::down(Emit::tree());
							Produce::val_iname(Emit::tree(), K_value, RTRelations::handler_iname(dbp));
							Produce::val_symbol(Emit::tree(), K_value, rr_s);
							Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
							if (t == 0) {
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
								Produce::val_symbol(Emit::tree(), K_value, X_s);
							} else {
								Produce::val_symbol(Emit::tree(), K_value, X_s);
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							}
						Produce::up(Emit::tree());
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_INSERTITEM_HL));
							Produce::down(Emit::tree());
								Produce::val_symbol(Emit::tree(), K_value, Y_s);
								Produce::val_symbol(Emit::tree(), K_value, Z1_s);
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

@<Write rels lookup list all@> =
	kind *KL = BinaryPredicates::term_kind(dbp, 0);
	kind *KR = BinaryPredicates::term_kind(dbp, 1);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (KL == NULL)) KL = K_object;
	if ((dbp == R_containment) && (KR == NULL)) KR = K_object;
	#endif
	if ((Calculus::Deferrals::has_finite_domain(KL)) && (Calculus::Deferrals::has_finite_domain(KL))) {
		i6_schema loop_schema_L, loop_schema_R;
		if ((Calculus::Deferrals::write_loop_schema(&loop_schema_L, KL)) &&
			(Calculus::Deferrals::write_loop_schema(&loop_schema_R, KR))) {
			EmitSchemas::emit_expand_from_locals(&loop_schema_L, Z1_lv, Z2_lv, TRUE);
					EmitSchemas::emit_expand_from_locals(&loop_schema_R, Z3_lv, Z4_lv, TRUE);

							Produce::inv_primitive(Emit::tree(), IF_BIP);
							Produce::down(Emit::tree());
								Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP);
								Produce::down(Emit::tree());
									Produce::val_iname(Emit::tree(), K_value, RTRelations::handler_iname(dbp));
									Produce::val_symbol(Emit::tree(), K_value, rr_s);
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RELS_TEST_HL));
									Produce::val_symbol(Emit::tree(), K_value, Z1_s);
									Produce::val_symbol(Emit::tree(), K_value, Z3_s);
								Produce::up(Emit::tree());
								Produce::code(Emit::tree());
								Produce::down(Emit::tree());
									Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_INSERTITEM_HL));
									Produce::down(Emit::tree());
										if (t == 0) {
											Produce::val_symbol(Emit::tree(), K_value, X_s);
											Produce::val_symbol(Emit::tree(), K_value, Z1_s);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
										} else {
											Produce::val_symbol(Emit::tree(), K_value, X_s);
											Produce::val_symbol(Emit::tree(), K_value, Z3_s);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
											Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
										}
									Produce::up(Emit::tree());
								Produce::up(Emit::tree());
							Produce::up(Emit::tree());
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
	}

@ And now a variation for default values: for example, an anonymous relation
between numbers and texts.

=
void RTRelations::compile_default_relation(inter_name *identifier, kind *K) {
	packaging_state save = Emit::named_array_begin(identifier, K_value);
	Kinds::RunTime::emit_block_value_header(K, FALSE, 8);
	Emit::array_null_entry();
	Emit::array_null_entry();
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "default value of "); Kinds::Textual::write(DVT, K);
	Emit::array_text_entry(DVT);
	Emit::array_iname_entry(TTF_iname);
	Emit::array_numeric_entry(0);
	Kinds::RunTime::emit_strong_id(K);
	Emit::array_iname_entry(Hierarchy::find(EMPTYRELATIONHANDLER_HL));
	Emit::array_text_entry(DVT);
	DISCARD_TEXT(DVT)
	Emit::array_end(save);
}

void RTRelations::compile_blank_relation(kind *K) {
	Kinds::RunTime::emit_block_value_header(K, FALSE, 34);
	Emit::array_null_entry();
	Emit::array_null_entry();
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "anonymous "); Kinds::Textual::write(DVT, K);
	Emit::array_text_entry(DVT);
	DISCARD_TEXT(DVT)

	Emit::array_iname_entry(TTF_iname);
	Emit::array_numeric_entry(7);
	Kinds::RunTime::emit_strong_id(K);
	kind *EK = Kinds::unary_construction_material(K);
	if (Kinds::Behaviour::uses_pointer_values(EK))
		Emit::array_iname_entry(Hierarchy::find(HASHLISTRELATIONHANDLER_HL));
	else
		Emit::array_iname_entry(Hierarchy::find(DOUBLEHASHSETRELATIONHANDLER_HL));

	Emit::array_text_entry(I"an anonymous relation");

	Emit::array_numeric_entry(0);
	Emit::array_numeric_entry(0);
	for (int i=0; i<24; i++) Emit::array_numeric_entry(0);
}

@h Support for the RELATIONS command.

=
void RTRelations::IterateRelations(void) {
	inter_name *iname = Hierarchy::find(ITERATERELATIONS_HL);
	packaging_state save = Routines::begin(iname);
	inter_symbol *callback_s = LocalVariables::add_named_call_as_symbol(I"callback");
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate)
		if (bp->imp->record_needed) {
			Produce::inv_primitive(Emit::tree(), INDIRECT1V_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, callback_s);
				Produce::val_iname(Emit::tree(), K_value, RTRelations::iname(bp));
			Produce::up(Emit::tree());
		}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@h The bitmap for various-to-various relations.
It is unavoidable that a general V-to-V relation will take at least $LR$ bits
of storage, where $L$ is the size of the left domain and $R$ the size of the
right domain. (A symmetric V-to-V relation needs only a little over $LR/2$ bits,
though in practice we don't want the nuisance of this memory saving.) Cheaper
implementations would only be possible if we could guarantee that the relation
would have some regularity, or would be sparse, but we can't guarantee any
of that. Our strategy will therefore be to store these $LR$ bits in the most
direct way possible, with as little overhead as possible: in a bitmap.

@ The following code compiles a stream of bits into a sequence of 16-bit
I6 constants written in hexadecimal, padding out with 0s to fill any incomplete
word left at the end. The first bit of the stream becomes the least significant
bit of the first word of the output.

=
int word_compiled = 0, bit_counter = 0, words_compiled;

void RTRelations::begin_bit_stream(void) {
	word_compiled = 0; bit_counter = 0; words_compiled = 0;
}

void RTRelations::compile_bit(int b) {
	word_compiled += (b << bit_counter);
	bit_counter++;
	if (bit_counter == 16) {
		Emit::array_numeric_entry((inter_ti) word_compiled);
		words_compiled++;
		word_compiled = 0; bit_counter = 0;
	}
}

void RTRelations::end_bit_stream(void) {
	while (bit_counter != 0) RTRelations::compile_bit(0);
}

@ As was implied above, the run-time storage for a various to various relation
whose BP has allocation ID number |X| is an I6 word array called |V2V_Bitmap_X|.
This begins with a header of 8 words and is then followed by a bitmap.

=
void RTRelations::compile_vtov_storage(binary_predicate *bp) {
	int left_count = 0, right_count = 0, words_used = 0, bytes_used = 0;
	RTRelations::allocate_index_storage();
	@<Index the left and right domains and calculate their sizes@>;

	inter_name *v2v_iname = NULL;
	if ((left_count > 0) && (right_count > 0))
		@<Allocate a zeroed-out memory cache for relations with fast route-finding@>;

	package_request *P = RTRelations::package(bp);
	explicit_bp_data *ED = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
	ED->v2v_bitmap_iname = Hierarchy::make_iname_in(BITMAP_HL, P);
	packaging_state save = Emit::named_array_begin(ED->v2v_bitmap_iname, K_value);
	@<Compile header information in the V-to-V structure@>;

	if ((left_count > 0) && (right_count > 0))
		@<Compile bitmap pre-initialised to the V-to-V relation at start of play@>;

	Emit::array_end(save);

	RTRelations::free_index_storage();
}

@ We calculate numbers $L$ and $R$, and index the items being related, so that
the possible left values are indexed $0, 1, 2, ..., L-1$ and the possible
right values $0, 1, 2, ..., R-1$. Note that in a relation such as

>> Roominess relates various things to various containers.

the same object (if a container) might be in both the left and right domains,
and be indexed differently on each side: it might be thing number 11 but
container number 6, for instance.

$L$ and $R$ are stored in the variables |left_count| and |right_count|. If
the left domain contains objects, the index of a member |I| is stored in
RI 0; if the right domain does, then in RI 1. If the domain set is an
enumerated kind of value, no index needs to be stored, because the values
are already enumerated $1, 2, 3, ..., N$ for some $N$. The actual work in
this is done by the routine |RTRelations::relation_range| (below).

@<Index the left and right domains and calculate their sizes@> =
	left_count = RTRelations::relation_range(bp, 0);
	right_count = RTRelations::relation_range(bp, 1);

@ See "Relations.i6t" in the template layer for details.

@<Compile header information in the V-to-V structure@> =
	kind *left_kind = BinaryPredicates::term_kind(bp, 0);
	kind *right_kind = BinaryPredicates::term_kind(bp, 1);

	if ((Kinds::Behaviour::is_subkind_of_object(left_kind)) && (left_count > 0)) {
		Emit::array_iname_entry(PL::Counting::instance_count_property_symbol(left_kind));
	} else Emit::array_numeric_entry(0);
	if ((Kinds::Behaviour::is_subkind_of_object(right_kind)) && (right_count > 0)) {
		Emit::array_iname_entry(PL::Counting::instance_count_property_symbol(right_kind));
	} else Emit::array_numeric_entry(0);

	Emit::array_numeric_entry((inter_ti) left_count);
	Emit::array_numeric_entry((inter_ti) right_count);
	Emit::array_iname_entry(Kinds::Behaviour::get_iname(left_kind));
	Emit::array_iname_entry(Kinds::Behaviour::get_iname(right_kind));

	Emit::array_numeric_entry(1); /* Cache broken flag */
	if ((left_count > 0) && (right_count > 0))
		Emit::array_iname_entry(v2v_iname);
	else
		Emit::array_numeric_entry(0);
	words_used += 8;

@ Fast route finding is available only where the left and right domains are
equal, and even then, only when the user asked for it. If so, we allocate
$LR$ bytes as a cache if $L=R<256$, and $LR$ words otherwise. The cache
is initialised to all-zeros, which saves an inordinate amount of nuisance,
and this is why the "cache broken" flag is initially set in the header
above: it forces the template layer to generate the cache when first used.

@<Allocate a zeroed-out memory cache for relations with fast route-finding@> =
	package_request *P = RTRelations::package(bp);
	inter_name *iname = Hierarchy::make_iname_in(ROUTE_CACHE_HL, P);
	kind *left_kind = BinaryPredicates::term_kind(bp, 0);
	kind *right_kind = BinaryPredicates::term_kind(bp, 1);
	if ((bp->imp->fast_route_finding) &&
		(Kinds::eq(left_kind, right_kind)) &&
		(Kinds::Behaviour::is_subkind_of_object(left_kind)) &&
		(left_count == right_count)) {
		if (left_count < 256) {
			v2v_iname = iname;
			packaging_state save = Emit::named_byte_array_begin(iname, K_number);
			Emit::array_numeric_entry((inter_ti) (2*left_count*left_count));
			Emit::array_end(save);
			bytes_used += 2*left_count*left_count;
		} else {
			v2v_iname = iname;
			packaging_state save = Emit::named_array_begin(iname, K_number);
			Emit::array_numeric_entry((inter_ti) (2*left_count*left_count));
			Emit::array_end(save);
			words_used += 2*left_count*left_count;
		}
	} else {
		v2v_iname = Emit::named_numeric_constant(iname, 0);
	}

@ The following routine conveniently determines whether a given INFS is
within the domain of one of the terms of a relation; the rule is that it
mustn't itself express a domain (otherwise, e.g., the kind "woman" would
show up as within the domain of "person" -- we want only instances here,
not kinds); and that it must inherit from the domain of the term.

=
int RTRelations::infs_in_domain(inference_subject *infs, binary_predicate *bp, int index) {
	if (InferenceSubjects::domain(infs) != NULL) return FALSE;
	kind *K = BinaryPredicates::term_kind(bp, index);
	if (K == NULL) return FALSE;
	inference_subject *domain_infs = Kinds::Knowledge::as_subject(K);
	if (InferenceSubjects::is_strictly_within(infs, domain_infs)) return TRUE;
	return FALSE;
}

@ Now to assemble the bitmap. We do this by looking at inferences in the world-model
to find out what pairs $(x, y)$ are such that assertions have declared that
$B(x, y)$ is true.

It would be convenient if the inferences could feed us the necessary
information in exactly the right order, but life is not that kind. On the
other hand it would be quicker and easier if we built the entire bitmap in
memory, so that it could send the pairs $(x, y)$ in any order at all, but
that's a little wasteful. We compromise and build the bitmap one row at a
time, requiring us to store a whole row, but allowing the world-model code
to send the pairs in that row in any order.

@<Compile bitmap pre-initialised to the V-to-V relation at start of play@> =
	char *row_flags = Memory::malloc(right_count, RELATION_CONSTRUCTION_MREASON);
	if (row_flags) {
		RTRelations::begin_bit_stream();

		inference_subject *infs;
		LOOP_OVER(infs, inference_subject)
			if (RTRelations::infs_in_domain(infs, bp, 0)) {
				int j;
				for (j=0; j<right_count; j++) row_flags[j] = 0;
				@<Find all pairs belonging to this row, and set the relevant flags@>;
				for (j=0; j<right_count; j++) RTRelations::compile_bit(row_flags[j]);
			}

		RTRelations::end_bit_stream();
		words_used += words_compiled;
		Memory::I7_free(row_flags, RELATION_CONSTRUCTION_MREASON, right_count);
	}

@<Find all pairs belonging to this row, and set the relevant flags@> =
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, World::Inferences::bp_as_subject(bp), ARBITRARY_RELATION_INF) {
		inference_subject *left_infs, *right_infs;
		World::Inferences::get_references(inf, &left_infs, &right_infs);
		if (infs == left_infs) row_flags[RTRelations::get_relation_index(right_infs, 1)] = 1;
	}

@ Lastly on this: the way we count and index the left (|index=0|) or right (1)
domain. We count upwards from 0 (in order of creation).

=
int RTRelations::relation_range(binary_predicate *bp, int index) {
	int t = 0;
	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) {
		if (RTRelations::infs_in_domain(infs, bp, index)) RTRelations::set_relation_index(infs, index, t++);
		else RTRelations::set_relation_index(infs, index, -1);
	}
	return t;
}

@ Tiresomely, we have to store these indices for a little while, so:

=
int *relation_indices = NULL;
void RTRelations::allocate_index_storage(void) {
	int nc = NUMBER_CREATED(inference_subject);
	relation_indices = (int *) (Memory::calloc(nc, 2*sizeof(int), OBJECT_COMPILATION_MREASON));
}

void RTRelations::set_relation_index(inference_subject *infs, int i, int v) {
	if (relation_indices == NULL) internal_error("relation index unallocated");
	relation_indices[2*(infs->allocation_id) + i] = v;
}

int RTRelations::get_relation_index(inference_subject *infs, int i) {
	if (relation_indices == NULL) internal_error("relation index unallocated");
	return relation_indices[2*(infs->allocation_id) + i];
}

void RTRelations::free_index_storage(void) {
	if (relation_indices == NULL) internal_error("relation index unallocated");
	int nc = NUMBER_CREATED(inference_subject);
	Memory::I7_array_free(relation_indices, OBJECT_COMPILATION_MREASON, nc, 2*sizeof(int));
	relation_indices = NULL;
}

@h The partition for an equivalence relation.
An equivalence relation $E$ is such that $E(x, x)$ for all $x$, such that
$E(x, y)$ if and only if $E(y, x)$, and such that $E(x, y)$ and $E(y, z)$
together imply $E(x, z)$: the properties of being reflexive, symmetric
and transitive. The relation constructed by a sentence like

>> Alliance relates people to each other in groups.

is to be an equivalence relation. This means we need to ensure first that
the original state of the relation, resulting from assertions such as...

>>  The verb to be allied to implies the alliance relation. Louis is allied to Otto. Otto is allied to Helene.

...satisfies the reflexive, symmetric and transitive properties; and then
also that these properties are maintained at run-time when the situation
changes as a result of executing phrases such as

>> now Louis is allied to Gustav;

We use the same solution both in the compiler and at run-time, which is to
exploit an elementary theorem about ERs. Let $E$ be an equivalence relation
on the members of a set $S$ (say, the set of people in Central Europe).
Then there is a unique way to divide up $S$ into a "partition" of subsets
called "equivalence classes" such that:

(a) every member of $S$ is in exactly one of the classes,
(b) none of the classes is empty, and
(c) $E(x, y)$ is true if and only if $x$ and $y$ belong to the same class.

Conversely, given any partition of $S$ (i.e., satisfying (a) and (b)),
there is a unique equivalence relation $E$ such that (c) is true. In short:
possible states of an equivalence relation on a set correspond exactly to
possible ways to divide it up into non-empty, non-overlapping pieces.

We therefore store the current state not as some list of which pairs $(x, y)$
for which $E(x, y)$ is true, but instead as a partition of the set $S$. We
store this as a function $p:S\rightarrow \lbrace 1, 2, 3, ...\rbrace$ such
that $x$ and $y$ belong in the same class -- or to put it another way, such
that $E(x, y)$ is true -- if and only if $p(x) = p(y)$. When we are assembling
the initial state, the function $p$ is an array of integers whose address is
stored in the |bp->equivalence_partition| field of the BP structure. It is
then compiled into the storage properties of the I6 objects concerned. For
instance, if we have |p44_alliance| as the storage property for the "alliance"
relation, then |O31_Louis.p44_alliance| and |O32_Otto.p44_alliance| will be
set to the same partition number. The template routines which set and remove
alliance then maintain the collective values of the |p44_alliance| property,
keeping it always a valid partition function for the relation.

@ We calculate the initial partition by starting with the sparsest possible
equivalence relation, $E(x, y)$ if and only if $x=y$, where each member is
related only to itself. (This is the equality relation.) The partition
function here is given by $p(x)$ equals the allocation ID number for object
$x$, plus 1. Since all objects have distinct IDs, $p(x)=p(y)$ if and only
if $x=y$, which is what we want. But note that the objects in $S$ may well
not have contiguous ID numbers. This doesn't matter to us, but it means $p$
may look less tidy than we expect.

For instance, suppose there are five people: Sophie, Ryan, Daisy, Owen and
the player, with a "helping" equivalence relation. We might then generate
the initial partition:
$$ p(P) = 12, p(S) = 23, p(R) = 25, p(D) = 26, p(O) = 31. $$

=
void RTRelations::equivalence_relation_make_singleton_partitions(binary_predicate *bp,
	int domain_size) {
	if (Relations::Explicit::get_form_of_relation(bp) != Relation_Equiv)
		internal_error("attempt to make partition for a non-equivalence relation");
	explicit_bp_data *D = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
	int *partition_array = Memory::calloc(domain_size, sizeof(int), PARTITION_MREASON);
	for (int i=0; i<domain_size; i++) partition_array[i] = i+1;
	D->equiv_data->equivalence_partition = partition_array;
}

@ The A-parser has meanwhile been reading in facts about the helping relation:

>> Sophie helps Ryan. Daisy helps Ryan. Owen helps the player.

And it feeds these facts to us one at a time. It tells us that $A(S, R)$
has to be true by calling the routine below for the helping relation with
the ID numbers of Sophie and Ryan as arguments. Sophie is currently in
class number 23, Ryan in class 25. We merge these two classes so that
anybody whose class number is 25 is moved down to have class number 23, and
so:
$$ p(P) = 12, p(S) = 23, p(R) = 23, p(D) = 26, p(O) = 31. $$
Similarly we now merge Daisy's class with Ryan's:
$$ p(P) = 12, p(S) = 23, p(R) = 23, p(D) = 23, p(O) = 31. $$
And Owen's with the player's:
$$ p(P) = 12, p(S) = 23, p(R) = 23, p(D) = 23, p(O) = 12. $$
This leaves us with the final partition where the two equivalence classes are
$$ \lbrace {\rm player}, {\rm Owen} \rbrace\quad \lbrace {\rm Sophie},
{\rm Daisy}, {\rm Ryan}\rbrace. $$
As mentioned above, it might seem "tidy" to renumber these classes 1 and 2
rather than 12 and 23, but there's really no need and we don't bother.

Note that the A-parser does not allow negative assertions about equivalence
relations to be made:

>> Daisy does not help Ryan.

While we could try to accommodate this (using the same method we use at
run-time to handle "now Daisy does not help Ryan"), it would only invite
users to set up these relations in a stylistically poor way.

=
void RTRelations::equivalence_relation_merge_classes(binary_predicate *bp,
	int domain_size, int ix1, int ix2) {
	if (Relations::Explicit::get_form_of_relation(bp) != Relation_Equiv)
		internal_error("attempt to merge classes for a non-equivalence relation");
	explicit_bp_data *D = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
	if (bp->right_way_round == FALSE) bp = bp->reversal;
	int *partition_array = D->equiv_data->equivalence_partition;;
	if (partition_array == NULL)
		internal_error("attempt to use null equivalence partition array");
	int little, big; /* or, The Fairies' Parliament */
	big = partition_array[ix1]; little = partition_array[ix2];
	if (big == little) return;
	if (big < little) { int swap = little; little = big; big = swap; }
	int i;
	for (i=0; i<domain_size; i++)
		if (partition_array[i] == big)
			partition_array[i] = little;
}

@ Once that process has completed, the code which compiles the
initial state of the I6 object tree calls the following routine to ask it
to fill in the (let's say) |p63_helping| property for each person
in turn.

=
void RTRelations::equivalence_relation_add_properties(binary_predicate *bp) {
	kind *k = BinaryPredicates::term_kind(bp, 1);
	if (Kinds::Behaviour::is_object(k)) {
		instance *I;
		LOOP_OVER_INSTANCES(I, k) {
			inference_subject *infs = Instances::as_subject(I);
			@<Set the partition number property@>;
		}
	} else {
		instance *nc;
		LOOP_OVER_INSTANCES(nc, k) {
			inference_subject *infs = Instances::as_subject(nc);
			@<Set the partition number property@>;
		}
	}
}

@<Set the partition number property@> =
	parse_node *val = Rvalues::from_int(
		RTRelations::equivalence_relation_get_class(bp, infs->allocation_id), EMPTY_WORDING);
	Properties::Valued::assert(Relations::Explicit::get_i6_storage_property(bp),
		infs, val, CERTAIN_CE);

@ Where:

=
int RTRelations::equivalence_relation_get_class(binary_predicate *bp, int ix) {
	if (Relations::Explicit::get_form_of_relation(bp) != Relation_Equiv)
		internal_error("attempt to merge classes for a non-equivalence relation");
	if (bp->right_way_round == FALSE) bp = bp->reversal;
	explicit_bp_data *D = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
	int *partition_array = D->equiv_data->equivalence_partition;;
	if (partition_array == NULL)
		internal_error("attempt to use null equivalence partition array");
	return partition_array[ix];
}

@ The following provides for run-time checking to make sure relations are
not used with the wrong kinds of object. (Compile-time checking excludes
other cases.)

=
typedef struct relation_guard {
	struct binary_predicate *guarding; /* which one is being defended */
	struct kind *check_L; /* or null if no check needed */
	struct kind *check_R; /* or null if no check needed */
	struct i6_schema *inner_test; /* schemas for the relation if check passes */
	struct i6_schema *inner_make_true;
	struct i6_schema *inner_make_false;
	struct i6_schema *f0; /* schemas for the relation's function */
	struct i6_schema *f1;
	struct inter_name *guard_f0_iname;
	struct inter_name *guard_f1_iname;
	struct inter_name *guard_test_iname;
	struct inter_name *guard_make_true_iname;
	struct inter_name *guard_make_false_iname;
	CLASS_DEFINITION
} relation_guard;

@h Generating routines to test relations by condition.
When a relation has to be tested as a condition, we can't simply embed that
condition as the I6 schema for "test relation": it might very well need
local variables, the table row-choosing variables, etc., to evaluate. It
has to be tested in its own context. So we generate a routine called
|Relation_X|, where |X| is the allocation ID number of the BP, which takes
two parameters |t_0| and |t_1| and returns true or false according to
whether or not $R(|t_0|, |t_1|)$.

This is where those routines are compiled.

=
void RTRelations::compile_defined_relations(void) {
	RTRelations::compile_relation_records();
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate)
		if ((bp->relation_family == by_routine_bp_family) && (bp->right_way_round)) {
			current_sentence = bp->bp_created_at;
			TEMPORARY_TEXT(C)
			WRITE_TO(C, "Routine to decide if %S(t_0, t_1)", BinaryPredicates::get_log_name(bp));
			Produce::comment(Emit::tree(), C);
			DISCARD_TEXT(C)
			by_routine_bp_data *D = RETRIEVE_POINTER_by_routine_bp_data(bp->family_specific);
			RTRelations::compile_routine_to_decide(D->bp_by_routine_iname,
				D->condition_defn_text, bp->term_details[0], bp->term_details[1]);
		}
	@<Compile RProperty routine@>;

	relation_guard *rg;
	LOOP_OVER(rg, relation_guard) {
		@<Compile RGuard f0 routine@>;
		@<Compile RGuard f1 routine@>;
		@<Compile RGuard T routine@>;
		@<Compile RGuard MT routine@>;
		@<Compile RGuard MF routine@>;
	}
}

@<Compile RProperty routine@> =
	packaging_state save = Routines::begin(Hierarchy::find(RPROPERTY_HL));
	inter_symbol *obj_s = LocalVariables::add_named_call_as_symbol(I"obj");
	inter_symbol *cl_s = LocalVariables::add_named_call_as_symbol(I"cl");
	inter_symbol *pr_s = LocalVariables::add_named_call_as_symbol(I"pr");

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, obj_s);
			Produce::val_symbol(Emit::tree(), K_value, cl_s);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, obj_s);
					Produce::val_symbol(Emit::tree(), K_value, pr_s);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_nothing(Emit::tree());
	Produce::up(Emit::tree());
	Routines::end(save);

@<Compile RGuard f0 routine@> =
	if (rg->guard_f0_iname) {
		packaging_state save = Routines::begin(rg->guard_f0_iname);
		local_variable *X_lv = NULL;
		inter_symbol *X_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"X", "which is related to at most one object", &X_lv);
		if (rg->f0) {
			if (rg->check_R) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, X_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
			}
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
			EmitSchemas::emit_val_expand_from_locals(rg->f0, X_lv, X_lv);
			Produce::up(Emit::tree());
			if (rg->check_R) {
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Produce::down(Emit::tree());
					Produce::val_nothing(Emit::tree());
				Produce::up(Emit::tree());
			}
		} else {
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_nothing(Emit::tree());
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@<Compile RGuard f1 routine@> =
	if (rg->guard_f1_iname) {
		packaging_state save = Routines::begin(rg->guard_f1_iname);
		local_variable *X_lv = NULL;
		inter_symbol *X_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"X", "which is related to at most one object", &X_lv);
		if (rg->f1) {
			if (rg->check_L) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, X_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
			}
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
			EmitSchemas::emit_val_expand_from_locals(rg->f1, X_lv, X_lv);
			Produce::up(Emit::tree());
			if (rg->check_L) {
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), RETURN_BIP);
				Produce::down(Emit::tree());
					Produce::val_nothing(Emit::tree());
				Produce::up(Emit::tree());
			}
		} else {
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_nothing(Emit::tree());
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@<Compile RGuard T routine@> =
	if (rg->guard_test_iname) {
		packaging_state save = Routines::begin(rg->guard_test_iname);
		local_variable *L_lv = NULL, *R_lv = NULL;
		inter_symbol *L_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"L", "left member of pair", &L_lv);
		inter_symbol *R_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"R", "right member of pair", &R_lv);
		if (rg->inner_test) {
			Produce::inv_primitive(Emit::tree(), IF_BIP);
			Produce::down(Emit::tree());

				int downs = 0;
				if (rg->check_L) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, L_s);
							Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
						Produce::up(Emit::tree());
					downs++;
				}
				if (rg->check_R) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, R_s);
							Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
						Produce::up(Emit::tree());
					downs++;
				}
				EmitSchemas::emit_val_expand_from_locals(rg->inner_test, L_lv, R_lv);
				for (int i=0; i<downs; i++) Produce::up(Emit::tree());

				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::rtrue(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

		}
		Produce::rfalse(Emit::tree());
		Routines::end(save);
	}

@<Compile RGuard MT routine@> =
	if (rg->guard_make_true_iname) {
		packaging_state save = Routines::begin(rg->guard_make_true_iname);
		local_variable *L_lv = NULL, *R_lv = NULL;
		inter_symbol *L_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"L", "left member of pair", &L_lv);
		inter_symbol *R_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"R", "right member of pair", &R_lv);
		if (rg->inner_make_true) {
			int downs = 1;
			if ((rg->check_L == NULL) && (rg->check_R == NULL)) downs = 0;

			if (downs > 0) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());

				if ((rg->check_L) && (rg->check_R)) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
					downs = 2;
				}

				if (rg->check_L) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, L_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
					Produce::up(Emit::tree());
				}
				if (rg->check_R) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, R_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
					Produce::up(Emit::tree());
				}
				for (int i=0; i<downs-1; i++) Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
			}

			EmitSchemas::emit_expand_from_locals(rg->inner_make_true, L_lv, R_lv, TRUE);
			Produce::rtrue(Emit::tree());

			if (downs > 0) { Produce::up(Emit::tree()); Produce::up(Emit::tree()); }

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RUNTIMEPROBLEM_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RTP_RELKINDVIOLATION_HL));
				Produce::val_symbol(Emit::tree(), K_value, L_s);
				Produce::val_symbol(Emit::tree(), K_value, R_s);
				Produce::val_iname(Emit::tree(), K_value, rg->guarding->imp->bp_iname);
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@<Compile RGuard MF routine@> =
	if (rg->guard_make_false_iname) {
		packaging_state save = Routines::begin(rg->guard_make_false_iname);
		local_variable *L_lv = NULL, *R_lv = NULL;
		inter_symbol *L_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"L", "left member of pair", &L_lv);
		inter_symbol *R_s = LocalVariables::add_internal_local_c_as_symbol_noting(I"R", "right member of pair", &R_lv);
		if (rg->inner_make_false) {
			int downs = 1;
			if ((rg->check_L == NULL) && (rg->check_R == NULL)) downs = 0;

			if (downs > 0) {
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());

				if ((rg->check_L) && (rg->check_R)) {
					Produce::inv_primitive(Emit::tree(), AND_BIP);
					Produce::down(Emit::tree());
					downs = 2;
				}

				if (rg->check_L) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, L_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_L));
					Produce::up(Emit::tree());
				}
				if (rg->check_R) {
					Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
					Produce::down(Emit::tree());
						Produce::val_symbol(Emit::tree(), K_value, R_s);
						Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(rg->check_R));
					Produce::up(Emit::tree());
				}
				for (int i=0; i<downs-1; i++) Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
			}

			EmitSchemas::emit_expand_from_locals(rg->inner_make_false, L_lv, R_lv, TRUE);
			Produce::rtrue(Emit::tree());

			if (downs > 0) { Produce::up(Emit::tree()); Produce::up(Emit::tree()); }

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(RUNTIMEPROBLEM_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(RTP_RELKINDVIOLATION_HL));
				Produce::val_symbol(Emit::tree(), K_value, L_s);
				Produce::val_symbol(Emit::tree(), K_value, R_s);
				Produce::val_iname(Emit::tree(), K_value, rg->guarding->imp->bp_iname);
			Produce::up(Emit::tree());
		}
		Routines::end(save);
	}

@ =
void RTRelations::compile_routine_to_decide(inter_name *rname,
	wording W, bp_term_details par1, bp_term_details par2) {

	packaging_state save = Routines::begin(rname);

	ph_stack_frame *phsf = Frames::current_stack_frame();
	RTRelations::add_term_as_call_parameter(phsf, par1);
	RTRelations::add_term_as_call_parameter(phsf, par2);

	LocalVariables::enable_possessive_form_of_it();

	parse_node *spec = NULL;
	if (<s-condition>(W)) spec = <<rp>>;
	if ((spec == NULL) || (Dash::validate_conditional_clause(spec) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadRelationCondition),
			"the condition defining this relation makes no sense to me",
			"although the definition was properly formed - it is only "
			"the part after 'when' which I can't follow.");
	} else {
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());
			Specifications::Compiler::emit_as_val(K_value, spec);
		Produce::up(Emit::tree());
	}

	Routines::end(save);
}

@ The following routine adds the given BP term as a call parameter to the
routine currently being compiled, deciding that something is an object if
its kind indications are all blank, but verifying that the value supplied
matches the specific necessary kind of object if there is one.

=
void RTRelations::add_term_as_call_parameter(ph_stack_frame *phsf,
	bp_term_details bptd) {
	kind *K = BPTerms::kind(&bptd);
	kind *PK = K;
	if ((PK == NULL) || (Kinds::Behaviour::is_subkind_of_object(PK))) PK = K_object;
	inter_symbol *lv_s = LocalVariables::add_call_parameter_as_symbol(phsf,
		bptd.called_name, PK);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), NOT_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, lv_s);
					Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(K));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::rfalse(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}
}

@h Indexing relations.
A brief table of relations appears on the Phrasebook Index page.

=
void RTRelations::index_table(OUTPUT_STREAM) {
	binary_predicate *bp;
	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0); WRITE("<i>name</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>category</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>relates this...</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>...to this</i>");
	HTML::end_html_row(OUT);
	LOOP_OVER(bp, binary_predicate)
		if (bp->right_way_round) {
			TEMPORARY_TEXT(type)
			BinaryPredicateFamilies::describe_for_index(type, bp);
			if ((Str::len(type) == 0) || (WordAssemblages::nonempty(bp->relation_name) == FALSE)) continue;
			HTML::first_html_column(OUT, 0);
			WordAssemblages::index(OUT, &(bp->relation_name));
			if (bp->bp_created_at) Index::link(OUT, Wordings::first_wn(Node::get_text(bp->bp_created_at)));
			HTML::next_html_column(OUT, 0);
			if (Str::len(type) > 0) WRITE("%S", type); else WRITE("--");
			HTML::next_html_column(OUT, 0);
			BPTerms::index(OUT, &(bp->term_details[0]));
			HTML::next_html_column(OUT, 0);
			BPTerms::index(OUT, &(bp->term_details[1]));
			HTML::end_html_row(OUT);
		}
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}

@ And a briefer note still for the table of verbs.

=
void RTRelations::index_for_verbs(OUTPUT_STREAM, binary_predicate *bp) {
	WRITE(" ... <i>");
	if (bp == NULL) WRITE("(a meaning internal to Inform)");
	else {
		if (bp->right_way_round == FALSE) {
			bp = bp->reversal;
			WRITE("reversed ");
		}
		WordAssemblages::index(OUT, &(bp->relation_name));
	}
	WRITE("</i>");
}
