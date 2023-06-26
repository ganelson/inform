[RTRelations::] Relations.

To compile the relations submodule for a compilation unit, which contains
_relation packages.

@h The generic/relations package.
A few constants before we get under way. These are permission bits intended to
form a bitmap in arbitrary combinations.

=
void RTRelations::def_bit(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(iname);
	Emit::named_numeric_constant_hex(iname, val);
}

void RTRelations::compile_generic_constants(void) {
	RTRelations::def_bit(RELS_SYMMETRIC_HL,        0x8000);
	RTRelations::def_bit(RELS_EQUIVALENCE_HL,      0x4000);
	RTRelations::def_bit(RELS_X_UNIQUE_HL,         0x2000);
	RTRelations::def_bit(RELS_Y_UNIQUE_HL,         0x1000);
	RTRelations::def_bit(RELS_TEST_HL,             0x0800);
	RTRelations::def_bit(RELS_ASSERT_TRUE_HL,      0x0400);
	RTRelations::def_bit(RELS_ASSERT_FALSE_HL,     0x0200);
	RTRelations::def_bit(RELS_SHOW_HL,             0x0100);
	RTRelations::def_bit(RELS_ROUTE_FIND_HL,       0x0080);
	RTRelations::def_bit(RELS_ROUTE_FIND_COUNT_HL, 0x0040);
	RTRelations::def_bit(RELS_LOOKUP_ANY_HL,       0x0008);
	RTRelations::def_bit(RELS_LOOKUP_ALL_X_HL,     0x0004);
	RTRelations::def_bit(RELS_LOOKUP_ALL_Y_HL,     0x0002);
	RTRelations::def_bit(RELS_LIST_HL,             0x0001);
	RTRelations::def_bit(TTF_SUM_HL,               (0x0800 + 0x0400 + 0x0200));
	/* needs to be RELS_TEST + RELS_ASSERT_TRUE + RELS_ASSERT_FALSE */
	@<Compile the relation long block header size@>;
}

@ This effectively sets the amount of memory used by a newly-created dynamic
relation at runtime. The memory will grow if necessary, but it's inefficient
to force it to grow immediately, so it needs a little space to grow.

The 5 and 6 here are binary logarithms: i.e., these start out with 2^5 = 32
or 2^6 = 64 words of storage.

@<Compile the relation long block header size@> =
	if (TargetVMs::is_16_bit(Task::vm())) {
		RTRelations::def_bit(REL_BLOCK_HEADER_HL, 0x100*5 + 13);
	} else {
		RTRelations::def_bit(REL_BLOCK_HEADER_HL, (0x100*6 + 13)*0x10000);
	}

@h Compilation data.
Each |binary_predicate| object contains this data:

=
typedef struct bp_compilation_data {
	struct package_request *bp_package;
	struct inter_name *data_iname; /* an array of metadata at runtime */
	struct inter_name *handler_iname; /* a function to perform operations at runtime */
	struct inter_name *initialiser_iname; /* if stored in dynamically allocated memory */
	int record_needed; /* we need to compile a small array of details in readable memory */	
	int fast_route_finding; /* use fast rather than slow route-finding algorithm? */
	struct relation_guard *guarding;
} bp_compilation_data;

bp_compilation_data RTRelations::new_compilation_data(binary_predicate *bp) {
	bp_compilation_data bpcd;
	bpcd.bp_package = NULL;
	bpcd.data_iname = NULL;
	bpcd.handler_iname = NULL;
	bpcd.initialiser_iname = NULL;
	bpcd.record_needed = FALSE;
	bpcd.fast_route_finding = FALSE;
	bpcd.guarding = NULL;
	return bpcd;
}

package_request *RTRelations::package(binary_predicate *bp) {
	if (bp == NULL) internal_error("null bp");
	if (bp->compilation_data.bp_package == NULL)
		bp->compilation_data.bp_package =
			Hierarchy::local_package_to(RELATIONS_HAP, bp->bp_created_at);
	return bp->compilation_data.bp_package;
}

@ Some relations are never needed or referred to by runtime code: for example,
reversals of relations used only one way around. It would be wasteful to
compile arrays or functions for those, so we keep track of which have actually
been requested -- it will be just those for which the runtime representation,
i.e., the result of //RTRelations::iname//, has been called for. This can
therefore be forced with:

=
void RTRelations::mark_as_needed(binary_predicate *bp) {
	RTRelations::iname(bp);
}

inter_name *RTRelations::iname(binary_predicate *bp) {
	bp->compilation_data.record_needed = TRUE;
	if (bp->compilation_data.data_iname == NULL)
		bp->compilation_data.data_iname =
			Hierarchy::make_iname_in(RELATION_RECORD_HL,
				RTRelations::package(bp));
	return bp->compilation_data.data_iname;
}

inter_name *RTRelations::initialiser_iname(binary_predicate *bp) {
	if (bp->compilation_data.initialiser_iname == NULL)
		bp->compilation_data.initialiser_iname =
			Hierarchy::make_iname_in(RELATION_INITIALISER_FN_HL,
				RTRelations::package(bp));
	return bp->compilation_data.initialiser_iname;
}

inter_name *RTRelations::handler_iname(binary_predicate *bp) {
	if (bp->compilation_data.handler_iname == NULL)
		bp->compilation_data.handler_iname =
			Hierarchy::make_iname_in(HANDLER_FN_HL,
				RTRelations::package(bp));
	return bp->compilation_data.handler_iname;
}

void RTRelations::use_frf(binary_predicate *bp) {
	bp->compilation_data.fast_route_finding = TRUE;
	bp->reversal->compilation_data.fast_route_finding = TRUE;
}

void RTRelations::guard(binary_predicate *bp, relation_guard *rg) {
	bp->compilation_data.guarding = rg;
}

@h Compilation.
A few built-in relations will have only a minimal presence at runtime: these.

=
int RTRelations::minimal(binary_predicate *bp) {
	if (bp == NULL) return FALSE;
	if ((bp == R_equality) || (bp->reversal == R_equality)) return TRUE;
	if ((bp == R_meaning) || (bp->reversal == R_meaning)) return TRUE;
	if ((bp == R_provision) || (bp->reversal == R_provision)) return TRUE;
	if ((bp == R_universal) || (bp->reversal == R_universal)) return TRUE;
	return FALSE;
}

void RTRelations::compile(void) {
	if (R_empty) {
		inter_name *iname = Hierarchy::find(MEANINGLESS_RR_HL);
		Emit::iname_constant(iname, K_value, RTRelations::iname(R_empty));
		Hierarchy::make_available(iname);
	}

	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate) {
		if (bp->compilation_data.record_needed) {
			text_stream *desc = Str::new();
			WRITE_TO(desc, "relation %A",  &(bp->relation_name));
			Sequence::queue_at(&RTRelations::compilation_agent,
				STORE_POINTER_binary_predicate(bp), desc, bp->bp_created_at);
			if (bp->compilation_data.guarding) {
				text_stream *desc = Str::new();
				WRITE_TO(desc, "relation guard for %A",  &(bp->relation_name));
				Sequence::queue_at(&RTRelations::guard_compilation_agent,
					STORE_POINTER_relation_guard(bp->compilation_data.guarding),
					desc, bp->bp_created_at);
			}
		}
		if ((bp->compilation_data.record_needed) || (bp->right_way_round)) {
			text_stream *mdesc = Str::new();
			WRITE_TO(mdesc, "relation metadata for %A",  &(bp->relation_name));
			Sequence::queue_at(&RTRelations::metadata_agent,
				STORE_POINTER_binary_predicate(bp), mdesc, bp->bp_created_at);
		}
	}
}

@ Metadata packages need to be made even when a relation has no array-like
existence at runtime, for the sake of the index.

=
void RTRelations::metadata_agent(compilation_subtask *t) {
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(t->data);
	package_request *pack = RTRelations::package(bp);
	inter_name *id_iname = Hierarchy::make_iname_in(RELATION_ID_HL, pack);
	Emit::numeric_constant(id_iname, 0);
	if (bp->compilation_data.record_needed) {
		inter_name *md_iname = Hierarchy::make_iname_in(RELATION_VALUE_MD_HL, pack);
		Emit::iname_constant(md_iname, K_value, RTRelations::iname(bp));
	}
	TEMPORARY_TEXT(desc)
	BinaryPredicateFamilies::describe_for_index(desc, bp);
	if (Str::len(desc) > 0)
		Hierarchy::apply_metadata(pack, RELATION_DESCRIPTION_MD_HL, desc);
	DISCARD_TEXT(desc)
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%A", &(bp->relation_name));
	if (Str::len(name) > 0)
		Hierarchy::apply_metadata(pack, RELATION_NAME_MD_HL, name);
	DISCARD_TEXT(name)
	for (int i=0; i<2; i++) {
		TEMPORARY_TEXT(details)
		BPTerms::index(details, &(bp->term_details[i]));
		if (Str::len(details) > 0)
			Hierarchy::apply_metadata(pack,
				(i==0)?RELATION_TERM0_MD_HL:RELATION_TERM1_MD_HL, details);
		DISCARD_TEXT(details)
	}
	Hierarchy::apply_metadata_from_number(pack, RELATION_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(bp->bp_created_at)));
}

@ So the following makes a single |_relation| package.

It might seem that this can never be called on a relation which is the wrong
way round, and in fact it almost never is. But on rare occasions the runtime
does need to represent the value (i.e. the metadata array) for such a relation --
for example, because it's possible for the runtime to determine the meaning
of any verb, and because some verbs can be given a wrong-way-round relation
as their meanings. See the test case |PronounVariation|.

=
void RTRelations::compilation_agent(compilation_subtask *t) {
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(t->data);
	package_request *pack = RTRelations::package(bp);
	inter_name *handler = NULL;

	if (ExplicitRelations::stored_dynamically(bp) == FALSE)
		@<Compile the relation handler function@>;
	if (bp->right_way_round) {
		if (ExplicitRelations::stored_dynamically(bp)) {
			@<Compile the initialiser function@>;
			@<Compile the creator function and its associated metadata@>;
		} else {
			int f = ExplicitRelations::get_form_of_relation(bp);
			if ((f == Relation_VtoV) || (f == Relation_Sym_VtoV))
				RTRelations::compile_vtov_storage(bp);
		}
		if (bp->relation_family == by_function_bp_family) {
			by_function_bp_data *D = RETRIEVE_POINTER_by_function_bp_data(bp->family_specific);
			RTRelations::compile_function_to_decide(D->bp_by_routine_iname,
				D->condition_defn_text, bp->term_details[0], bp->term_details[1]);
		}
	}
	@<Compile the metadata array@>;
}

@<Compile the initialiser function@> =
	packaging_state save = Functions::begin(RTRelations::initialiser_iname(bp));
	inference *i;
	inter_name *rtiname = Hierarchy::find(RELATIONTEST_HL);
	POSITIVE_KNOWLEDGE_LOOP(i, RelationSubjects::from_bp(bp), relation_inf) {
		parse_node *spec0, *spec1;
		RelationInferences::get_term_specs(i, &spec0, &spec1);
		EmitCode::call(rtiname);
		EmitCode::down();
			EmitCode::val_iname(K_value, RTRelations::iname(bp));
			EmitCode::val_iname(K_value, Hierarchy::find(RELS_ASSERT_TRUE_HL));
			CompileValues::to_code_val(spec0);
			CompileValues::to_code_val(spec1);
		EmitCode::up();
	}
	Functions::end(save);

@<Compile the creator function and its associated metadata@> =
	inter_name *iname = Hierarchy::make_iname_in(RELATION_CREATOR_FN_HL, pack);
	packaging_state save = Functions::begin(iname);
	LocalVariables::new_internal_commented_as_symbol(I"i", I"loop counter");
	LocalVariables::new_internal_commented_as_symbol(I"rel", I"new relation");

	EmitCode::call(Hierarchy::find(BLKVALUECREATE_HL));
	EmitCode::down();
		RTKindIDs::emit_strong_ID_as_val(BinaryPredicates::kind(bp));
		EmitCode::val_iname(K_value, RTRelations::iname(bp));
	EmitCode::up();

	EmitCode::call(Hierarchy::find(RELATION_TY_NAME_HL));
	EmitCode::down();
		EmitCode::val_iname(K_value, RTRelations::iname(bp));
		TEMPORARY_TEXT(A)
		WRITE_TO(A, "%A", &(bp->relation_name));
		EmitCode::val_text(A);
		DISCARD_TEXT(A)
	EmitCode::up();

	switch(ExplicitRelations::get_form_of_relation(bp)) {
		case Relation_OtoO:
			EmitCode::call(Hierarchy::find(RELATION_TY_OTOOADJECTIVE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTRelations::iname(bp));
				EmitCode::val_true();
			EmitCode::up();
			break;
		case Relation_OtoV:
			EmitCode::call(Hierarchy::find(RELATION_TY_OTOVADJECTIVE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTRelations::iname(bp));
				EmitCode::val_true();
			EmitCode::up();
			break;
		case Relation_VtoO:
			EmitCode::call(Hierarchy::find(RELATION_TY_VTOOADJECTIVE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTRelations::iname(bp));
				EmitCode::val_true();
			EmitCode::up();
			break;
		case Relation_Sym_OtoO:
			EmitCode::call(Hierarchy::find(RELATION_TY_OTOOADJECTIVE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTRelations::iname(bp));
				EmitCode::val_true();
			EmitCode::up();
			EmitCode::call(Hierarchy::find(RELATION_TY_SYMMETRICADJECTIVE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTRelations::iname(bp));
				EmitCode::val_true();
			EmitCode::up();
			break;
		case Relation_Equiv:
			EmitCode::call(Hierarchy::find(RELATION_TY_EQUIVALENCEADJECTIVE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTRelations::iname(bp));
				EmitCode::val_true();
			EmitCode::up();
			break;
		case Relation_VtoV: break;
		case Relation_Sym_VtoV:
			EmitCode::call(Hierarchy::find(RELATION_TY_SYMMETRICADJECTIVE_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, RTRelations::iname(bp));
				EmitCode::val_true();
			EmitCode::up();
			break;
	}
	EmitCode::inv(INDIRECT0V_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, RTRelations::initialiser_iname(bp));
	EmitCode::up();
	Functions::end(save);
	inter_name *md_iname = Hierarchy::make_iname_in(RELATION_CREATOR_MD_HL, pack);
	Emit::iname_constant(md_iname, K_value, iname);

@<Compile the metadata array@> =
	packaging_state save = EmitArrays::begin_unchecked(RTRelations::iname(bp));
	if (ExplicitRelations::stored_dynamically(bp)) {
		EmitArrays::numeric_entry((inter_ti) 1);
	} else {
		TheHeap::emit_block_value_header(BinaryPredicates::kind(bp), FALSE, 8);
		EmitArrays::null_entry();
		EmitArrays::null_entry();
		@<Write the name field of the relation record@>;
		@<Write the permissions field of the relation record@>;
		@<Write the storage field of the relation metadata array@>;
		@<Write the kind field of the relation record@>;
		@<Write the handler field of the relation record@>;
		@<Write the description field of the relation record@>;
	}
	EmitArrays::end(save);

@<Write the name field of the relation record@> =
	TEMPORARY_TEXT(NF)
	WRITE_TO(NF, "%A relation", &(bp->relation_name));
	EmitArrays::text_entry(NF);
	DISCARD_TEXT(NF)

@<Write the permissions field of the relation record@> =
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) dbp = bp->reversal;
	inter_name *bm_symb = Hierarchy::make_iname_in(ABILITIES_HL, pack);
	packaging_state save_sum = EmitArrays::begin_sum_constant(bm_symb, K_value);
	if (Hierarchy::find(RELS_TEST_HL) == NULL) internal_error("no RELS symbols yet");
	EmitArrays::iname_entry(Hierarchy::find(RELS_TEST_HL));
	if (RTRelations::minimal(bp) == FALSE) {
		EmitArrays::iname_entry(Hierarchy::find(RELS_LOOKUP_ANY_HL));
		EmitArrays::iname_entry(Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
		EmitArrays::iname_entry(Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
		EmitArrays::iname_entry(Hierarchy::find(RELS_LIST_HL));
	}
	switch(ExplicitRelations::get_form_of_relation(dbp)) {
		case Relation_Implicit:
			if ((RTRelations::minimal(bp) == FALSE) &&
				(BinaryPredicates::can_be_made_true_at_runtime(dbp))) {
				EmitArrays::iname_entry(Hierarchy::find(RELS_ASSERT_TRUE_HL));
				EmitArrays::iname_entry(Hierarchy::find(RELS_ASSERT_FALSE_HL));
				EmitArrays::iname_entry(Hierarchy::find(RELS_LOOKUP_ANY_HL));
			}
			break;
		case Relation_OtoO:
			EmitArrays::iname_entry(Hierarchy::find(RELS_X_UNIQUE_HL));
			EmitArrays::iname_entry(Hierarchy::find(RELS_Y_UNIQUE_HL));
			@<Throw in the full suite@>; break;
		case Relation_OtoV: EmitArrays::iname_entry(Hierarchy::find(RELS_X_UNIQUE_HL));
			@<Throw in the full suite@>; break;
		case Relation_VtoO: EmitArrays::iname_entry(Hierarchy::find(RELS_Y_UNIQUE_HL));
			@<Throw in the full suite@>; break;
		case Relation_Sym_OtoO:
			EmitArrays::iname_entry(Hierarchy::find(RELS_SYMMETRIC_HL));
			EmitArrays::iname_entry(Hierarchy::find(RELS_X_UNIQUE_HL));
			EmitArrays::iname_entry(Hierarchy::find(RELS_Y_UNIQUE_HL));
			@<Throw in the full suite@>; break;
		case Relation_Equiv:
			EmitArrays::iname_entry(Hierarchy::find(RELS_EQUIVALENCE_HL));
			@<Throw in the full suite@>; break;
		case Relation_VtoV:
			@<Throw in the full suite@>; break;
		case Relation_Sym_VtoV:
			EmitArrays::iname_entry(Hierarchy::find(RELS_SYMMETRIC_HL));
			@<Throw in the full suite@>; break;
		default:
			internal_error("Binary predicate with unknown structural type");
	}
	EmitArrays::end(save_sum); /* of the summation, that is */
	EmitArrays::iname_entry(bm_symb);

@<Throw in the full suite@> =
	EmitArrays::iname_entry(Hierarchy::find(RELS_ASSERT_TRUE_HL));
	EmitArrays::iname_entry(Hierarchy::find(RELS_ASSERT_FALSE_HL));
	EmitArrays::iname_entry(Hierarchy::find(RELS_SHOW_HL));
	EmitArrays::iname_entry(Hierarchy::find(RELS_ROUTE_FIND_HL));

@ The storage field has different meanings for different families of BPs:

@<Write the storage field of the relation metadata array@> =
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) dbp = bp->reversal;
	if (bp->relation_family == by_function_bp_family) {
		/* Field 0 is the function used to test the relation */
		by_function_bp_data *D = RETRIEVE_POINTER_by_function_bp_data(dbp->family_specific);
		EmitArrays::iname_entry(D->bp_by_routine_iname);
	} else {
		switch(ExplicitRelations::get_form_of_relation(dbp)) {
			case Relation_Implicit: /* Field 0 is not used */
				EmitArrays::numeric_entry(0); /* which is not the same as |NULL|, unlike in C */
				break;
			case Relation_OtoO:
			case Relation_OtoV:
			case Relation_VtoO:
			case Relation_Sym_OtoO:
			case Relation_Equiv: /* Field 0 is the property used for run-time storage */
				EmitArrays::iname_entry(
					RTProperties::iname(ExplicitRelations::get_i6_storage_property(dbp)));
				break;
			case Relation_VtoV:
			case Relation_Sym_VtoV: {
				/* Field 0 is the bitmap array used for run-time storage */
				explicit_bp_data *ED = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
				if (ED->v2v_bitmap_iname == NULL) internal_error("gaah");
				EmitArrays::iname_entry(ED->v2v_bitmap_iname);
				break;
			}
		}
	}

@<Write the kind field of the relation record@> =
	RTKindIDs::strong_ID_array_entry(BinaryPredicates::kind(bp));

@<Write the description field of the relation record@> =
	TEMPORARY_TEXT(DF)
	if (ExplicitRelations::get_form_of_relation(bp) == Relation_Implicit)
		WRITE_TO(DF, "%S", BinaryPredicates::get_log_name(bp));
	else TranscodeText::from_text(DF, Node::get_text(bp->bp_created_at));
	EmitArrays::text_entry(DF);
	DISCARD_TEXT(DF)

@<Write the handler field of the relation record@> =
	EmitArrays::iname_entry(handler);

@<Compile the relation handler function@> =
	text_stream *X = I"X", *Y = I"Y";
	binary_predicate *dbp = bp;
	if (bp->right_way_round == FALSE) { X = I"Y"; Y = I"X"; dbp = bp->reversal; }

	handler = RTRelations::handler_iname(bp);
	packaging_state save = Functions::begin(handler);
	inter_symbol *rr_s = LocalVariables::new_other_as_symbol(I"rr");
	inter_symbol *task_s = LocalVariables::new_other_as_symbol(I"task");
	local_variable *X_lv = LocalVariables::new_other_parameter(I"X");
	local_variable *Y_lv = LocalVariables::new_other_parameter(I"Y");
	inter_symbol *X_s = LocalVariables::declare(X_lv);
	inter_symbol *Y_s = LocalVariables::declare(Y_lv);
	local_variable *Z1_lv = LocalVariables::new_internal_commented(I"Z1", I"loop counter");
	local_variable *Z2_lv = LocalVariables::new_internal_commented(I"Z2", I"loop counter");
	local_variable *Z3_lv = LocalVariables::new_internal_commented(I"Z3", I"loop counter");
	local_variable *Z4_lv = LocalVariables::new_internal_commented(I"Z4", I"loop counter");
	inter_symbol *Z1_s = LocalVariables::declare(Z1_lv);
	LocalVariables::declare(Z2_lv);
	inter_symbol *Z3_s = LocalVariables::declare(Z3_lv);
	LocalVariables::declare(Z4_lv);

	annotated_i6_schema asch; i6_schema *i6s = NULL;
	EmitCode::inv(SWITCH_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, task_s);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(CASE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(RELS_TEST_HL));
				EmitCode::code();
				EmitCode::down();
					@<The TEST task@>;
				EmitCode::up();
			EmitCode::up();
			if (RTRelations::minimal(bp)) {
				EmitCode::inv(DEFAULT_BIP);
				EmitCode::down();
					EmitCode::code();
					EmitCode::down();
						@<The default case for minimal relations only@>;
					EmitCode::up();
				EmitCode::up();
			} else {
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(RELS_LOOKUP_ANY_HL));
					EmitCode::code();
					EmitCode::down();
						@<The LOOKUP ANY task@>;
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(RELS_LOOKUP_ALL_X_HL));
					EmitCode::code();
					EmitCode::down();
						@<The LOOKUP ALL X task@>;
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(RELS_LOOKUP_ALL_Y_HL));
					EmitCode::code();
					EmitCode::down();
						@<The LOOKUP ALL Y task@>;
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(CASE_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(RELS_LIST_HL));
					EmitCode::code();
					EmitCode::down();
						@<The LIST task@>;
					EmitCode::up();
				EmitCode::up();
				if (BinaryPredicates::can_be_made_true_at_runtime(bp)) {
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(RELS_ASSERT_TRUE_HL));
						EmitCode::code();
						EmitCode::down();
							@<The ASSERT TRUE task@>;
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(RELS_ASSERT_FALSE_HL));
						EmitCode::code();
						EmitCode::down();
							@<The ASSERT FALSE task@>;
						EmitCode::up();
					EmitCode::up();
				}
				inter_name *shower = NULL;
				int par = 0;
				switch(ExplicitRelations::get_form_of_relation(dbp)) {
					case Relation_OtoO: shower = Hierarchy::find(RELATION_RSHOWOTOO_HL); break;
					case Relation_OtoV: shower = Hierarchy::find(RELATION_RSHOWOTOO_HL); break;
					case Relation_VtoO: shower = Hierarchy::find(RELATION_SHOWOTOO_HL); break;
					case Relation_Sym_OtoO: shower = Hierarchy::find(RELATION_SHOWOTOO_HL); par = 1; break;
					case Relation_Equiv: shower = Hierarchy::find(RELATION_SHOWEQUIV_HL); break;
					case Relation_VtoV: shower = Hierarchy::find(RELATION_SHOWVTOV_HL); break;
					case Relation_Sym_VtoV: shower = Hierarchy::find(RELATION_SHOWVTOV_HL); par = 1; break;
				}
				if (shower) {
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(RELS_SHOW_HL));
						EmitCode::code();
						EmitCode::down();
							@<The SHOW task@>;
						EmitCode::up();
					EmitCode::up();
				}
				inter_name *emptier = NULL;
				par = 0;
				switch(ExplicitRelations::get_form_of_relation(dbp)) {
					case Relation_OtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_OtoV: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_VtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); break;
					case Relation_Sym_OtoO: emptier = Hierarchy::find(RELATION_EMPTYOTOO_HL); par = 1; break;
					case Relation_Equiv: emptier = Hierarchy::find(RELATION_EMPTYEQUIV_HL); break;
					case Relation_VtoV: emptier = Hierarchy::find(RELATION_EMPTYVTOV_HL); break;
					case Relation_Sym_VtoV: emptier = Hierarchy::find(RELATION_EMPTYVTOV_HL); par = 1; break;
				}
				if (emptier) {
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(RELS_EMPTY_HL));
						EmitCode::code();
						EmitCode::down();
							@<The EMPTY task@>;
						EmitCode::up();
					EmitCode::up();
				}
				inter_name *router = NULL;
				int id_flag = TRUE;
				int follow = FALSE;
				switch(ExplicitRelations::get_form_of_relation(dbp)) {
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
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(RELS_ROUTE_FIND_HL));
						EmitCode::code();
						EmitCode::down();
							@<The ROUTE FIND task@>;
						EmitCode::up();
					EmitCode::up();
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(RELS_ROUTE_FIND_COUNT_HL));
						EmitCode::code();
						EmitCode::down();
							@<The ROUTE FIND COUNT task@>;
						EmitCode::up();
					EmitCode::up();
				}
			}
		EmitCode::up();
	EmitCode::up();

	EmitCode::rfalse();
	Functions::end(save);

@<The default case for minimal relations only@> =
	EmitCode::call(Hierarchy::find(RUNTIMEPROBLEM_HL));
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(RTP_RELMINIMAL_HL));
		EmitCode::val_symbol(K_value, task_s);
		EmitCode::val_number(0);
		EmitCode::val_iname(K_value, RTRelations::iname(bp));
	EmitCode::up();

@<The ASSERT TRUE task@> =
	asch = Calculus::Schemas::blank_asch();
	i6s = BinaryPredicateFamilies::get_schema(NOW_ATOM_TRUE_TASK, dbp, &asch);
	if (i6s == NULL) EmitCode::rfalse();
	else {
		CompileSchemas::from_local_variables_in_void_context(i6s, X_lv, Y_lv);
		EmitCode::rtrue();
	}

@<The ASSERT FALSE task@> =
	asch = Calculus::Schemas::blank_asch();
	i6s = BinaryPredicateFamilies::get_schema(NOW_ATOM_FALSE_TASK, dbp, &asch);
	if (i6s == NULL) EmitCode::rfalse();
	else {
		CompileSchemas::from_local_variables_in_void_context(i6s, X_lv, Y_lv);
		EmitCode::rtrue();
	}

@<The TEST task@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		asch = Calculus::Schemas::blank_asch();
		i6s = BinaryPredicateFamilies::get_schema(TEST_ATOM_TASK, dbp, &asch);
		int adapted = FALSE;
		for (int j=0; j<2; j++) {
			i6_schema *fnsc = BinaryPredicates::get_term_as_fn_of_other(bp, j);
			if (fnsc) {
				if (j == 0) {
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, X_s);
						CompileSchemas::from_local_variables_in_val_context(fnsc, Y_lv, Y_lv);
					EmitCode::up();
					adapted = TRUE;
				} else {
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, Y_s);
						CompileSchemas::from_local_variables_in_val_context(fnsc, X_lv, X_lv);
					EmitCode::up();
					adapted = TRUE;
				}
			}
		}
		if (adapted == FALSE) {
			if (i6s == NULL) EmitCode::val_false();
			else CompileSchemas::from_local_variables_in_val_context(i6s, X_lv, Y_lv);
		}
		EmitCode::code();
		EmitCode::down();
			EmitCode::rtrue();
		EmitCode::up();
	EmitCode::up();
	EmitCode::rfalse();

@<The ROUTE FIND task@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::inv(INDIRECT3_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, router);
			@<Expand the ID operand@>;
			EmitCode::val_symbol(K_value, X_s);
			EmitCode::val_symbol(K_value, Y_s);
		EmitCode::up();
	EmitCode::up();

@<Expand the ID operand@> =
	if (id_flag) {
		EmitCode::call(Hierarchy::find(RLNGETF_HL));
		EmitCode::down();
			EmitCode::val_symbol(K_value, rr_s);
			EmitCode::val_iname(K_value, Hierarchy::find(RR_STORAGE_HL));
		EmitCode::up();
	} else {
		EmitCode::val_symbol(K_value, rr_s);
	}

@<The ROUTE FIND COUNT task@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
	if (follow) {
		EmitCode::call(Hierarchy::find(RELFOLLOWVECTOR_HL));
		EmitCode::down();
			EmitCode::inv(INDIRECT3_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, router);
				@<Expand the ID operand@>;
				EmitCode::val_symbol(K_value, X_s);
				EmitCode::val_symbol(K_value, Y_s);
			EmitCode::up();
			EmitCode::val_symbol(K_value, X_s);
			EmitCode::val_symbol(K_value, Y_s);
		EmitCode::up();
	} else {
		EmitCode::inv(INDIRECT4_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, router);
			@<Expand the ID operand@>;
			EmitCode::val_symbol(K_value, X_s);
			EmitCode::val_symbol(K_value, Y_s);
			EmitCode::val_true();
		EmitCode::up();
	}
	EmitCode::up();

@<The SHOW task@> =
	EmitCode::inv(INDIRECT2V_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, shower);
		EmitCode::val_symbol(K_value, rr_s);
		if (par) EmitCode::val_true(); else EmitCode::val_false();
	EmitCode::up();
	EmitCode::rtrue();

@<The EMPTY task@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::inv(INDIRECT3_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, emptier);
			EmitCode::val_symbol(K_value, rr_s);
			if (par) EmitCode::val_true(); else EmitCode::val_false();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, X_s);
				EmitCode::val_number(1);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<The LOOKUP ANY task@> =
	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::inv(OR_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, Y_s);
				EmitCode::val_iname(K_value, Hierarchy::find(RLANY_GET_X_HL));
			EmitCode::up();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, Y_s);
				EmitCode::val_iname(K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			int t = 0;
			@<Write rels lookup@>;
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			t = 1;
			@<Write rels lookup@>;
		EmitCode::up();
	EmitCode::up();

@<The LOOKUP ALL X task@> =
	EmitCode::call(Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	EmitCode::down();
		EmitCode::val_symbol(K_value, Y_s);
		EmitCode::val_number(0);
	EmitCode::up();

	int t = 0;
	@<Write rels lookup list@>;

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, Y_s);
	EmitCode::up();

@<The LOOKUP ALL Y task@> =
	EmitCode::call(Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	EmitCode::down();
		EmitCode::val_symbol(K_value, Y_s);
		EmitCode::val_number(0);
	EmitCode::up();

	int t = 1;
	@<Write rels lookup list@>;

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, Y_s);
	EmitCode::up();

@<The LIST task@> =
	EmitCode::call(Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	EmitCode::down();
		EmitCode::val_symbol(K_value, X_s);
		EmitCode::val_number(0);
	EmitCode::up();

	EmitCode::inv(IFELSE_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, Y_s);
			EmitCode::val_iname(K_value, Hierarchy::find(RLIST_ALL_X_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			int t = 0;
			@<Write rels lookup list all@>;
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, Y_s);
					EmitCode::val_iname(K_value, Hierarchy::find(RLIST_ALL_Y_HL));
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					t = 1;
					@<Write rels lookup list all@>;
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, X_s);
	EmitCode::up();

@<Write rels lookup@> =
	kind *K = BinaryPredicates::term_kind(dbp, t);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (K == NULL)) K = K_object;
	#endif
	if (Deferrals::has_finite_domain(K)) {
		i6_schema loop_schema;
		if (CompileLoops::schema(&loop_schema, K)) {
			CompileSchemas::from_local_variables_in_void_context(&loop_schema, Z1_lv, Z2_lv);
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(INDIRECT4_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, RTRelations::handler_iname(dbp));
							EmitCode::val_symbol(K_value, rr_s);
							EmitCode::val_iname(K_value, Hierarchy::find(RELS_TEST_HL));
							if (t == 0) {
								EmitCode::val_symbol(K_value, Z1_s);
								EmitCode::val_symbol(K_value, X_s);
							} else {
								EmitCode::val_symbol(K_value, X_s);
								EmitCode::val_symbol(K_value, Z1_s);
							}
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, Y_s);
									EmitCode::val_iname(K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
								EmitCode::up();
								EmitCode::code();
								EmitCode::down();
									EmitCode::rtrue();
								EmitCode::up();
							EmitCode::up();

							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(EQ_BIP);
								EmitCode::down();
									EmitCode::val_symbol(K_value, Y_s);
									EmitCode::val_iname(K_value, Hierarchy::find(RLANY_CAN_GET_Y_HL));
								EmitCode::up();
								EmitCode::code();
								EmitCode::down();
									EmitCode::rtrue();
								EmitCode::up();
							EmitCode::up();

							EmitCode::inv(RETURN_BIP);
							EmitCode::down();
								EmitCode::val_symbol(K_value, Z1_s);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}
	}

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, Y_s);
			EmitCode::val_iname(K_value, Hierarchy::find(RLANY_CAN_GET_X_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::rfalse();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, Y_s);
			EmitCode::val_iname(K_value, Hierarchy::find(RLANY_CAN_GET_Y_HL));
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::rfalse();
		EmitCode::up();
	EmitCode::up();

	if (K == NULL) EmitCode::rfalse();
	else {
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			EmitCode::call(Hierarchy::find(DEFAULTVALUEOFKOV_HL));
			EmitCode::down();
				RTKindIDs::emit_strong_ID_as_val(K);
			EmitCode::up();
		EmitCode::up();
	}

@<Write rels lookup list@> =
	kind *K = BinaryPredicates::term_kind(dbp, t);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (K == NULL)) K = K_object;
	#endif
	if (Deferrals::has_finite_domain(K)) {
		i6_schema loop_schema;
		if (CompileLoops::schema(&loop_schema, K)) {
			CompileSchemas::from_local_variables_in_void_context(&loop_schema, Z1_lv, Z2_lv);
					EmitCode::inv(IF_BIP);
					EmitCode::down();
						EmitCode::inv(INDIRECT4_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, RTRelations::handler_iname(dbp));
							EmitCode::val_symbol(K_value, rr_s);
							EmitCode::val_iname(K_value, Hierarchy::find(RELS_TEST_HL));
							if (t == 0) {
								EmitCode::val_symbol(K_value, Z1_s);
								EmitCode::val_symbol(K_value, X_s);
							} else {
								EmitCode::val_symbol(K_value, X_s);
								EmitCode::val_symbol(K_value, Z1_s);
							}
						EmitCode::up();
						EmitCode::code();
						EmitCode::down();
							EmitCode::call(Hierarchy::find(LIST_OF_TY_INSERTITEM_HL));
							EmitCode::down();
								EmitCode::val_symbol(K_value, Y_s);
								EmitCode::val_symbol(K_value, Z1_s);
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}
	}

@<Write rels lookup list all@> =
	kind *KL = BinaryPredicates::term_kind(dbp, 0);
	kind *KR = BinaryPredicates::term_kind(dbp, 1);
	#ifdef IF_MODULE
	if ((dbp == R_containment) && (KL == NULL)) KL = K_object;
	if ((dbp == R_containment) && (KR == NULL)) KR = K_object;
	#endif
	if ((Deferrals::has_finite_domain(KL)) && (Deferrals::has_finite_domain(KL))) {
		i6_schema loop_schema_L, loop_schema_R;
		if ((CompileLoops::schema(&loop_schema_L, KL)) &&
			(CompileLoops::schema(&loop_schema_R, KR))) {
			CompileSchemas::from_local_variables_in_void_context(&loop_schema_L, Z1_lv, Z2_lv);
					CompileSchemas::from_local_variables_in_void_context(&loop_schema_R, Z3_lv, Z4_lv);

							EmitCode::inv(IF_BIP);
							EmitCode::down();
								EmitCode::inv(INDIRECT4_BIP);
								EmitCode::down();
									EmitCode::val_iname(K_value, RTRelations::handler_iname(dbp));
									EmitCode::val_symbol(K_value, rr_s);
									EmitCode::val_iname(K_value, Hierarchy::find(RELS_TEST_HL));
									EmitCode::val_symbol(K_value, Z1_s);
									EmitCode::val_symbol(K_value, Z3_s);
								EmitCode::up();
								EmitCode::code();
								EmitCode::down();
									EmitCode::call(Hierarchy::find(LIST_OF_TY_INSERTITEM_HL));
									EmitCode::down();
										if (t == 0) {
											EmitCode::val_symbol(K_value, X_s);
											EmitCode::val_symbol(K_value, Z1_s);
											EmitCode::val_false();
											EmitCode::val_number(0);
											EmitCode::val_true();
										} else {
											EmitCode::val_symbol(K_value, X_s);
											EmitCode::val_symbol(K_value, Z3_s);
											EmitCode::val_false();
											EmitCode::val_number(0);
											EmitCode::val_true();
										}
									EmitCode::up();
								EmitCode::up();
							EmitCode::up();
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		}
	}

@h Default values of relation kinds.
The following will be called just once for each different relation kind needing
a default value; for example, |K| might be "relation of texts to numbers". We
need to compile an array at |iname| which will have the meaning of an empty
relation of the right kind.

=
void RTRelations::default_value_of_relation_kind(inter_name *identifier, kind *K) {
	packaging_state save = EmitArrays::begin_unchecked(identifier);
	TheHeap::emit_block_value_header(K, FALSE, 8);
	EmitArrays::null_entry();
	EmitArrays::null_entry();
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "default value of "); Kinds::Textual::write(DVT, K);
	EmitArrays::text_entry(DVT);
	EmitArrays::iname_entry(Hierarchy::find(TTF_SUM_HL));
	EmitArrays::numeric_entry(0);
	RTKindIDs::strong_ID_array_entry(K);
	EmitArrays::iname_entry(Hierarchy::find(EMPTYRELATIONHANDLER_HL));
	EmitArrays::text_entry(DVT);
	DISCARD_TEXT(DVT)
	EmitArrays::end(save);
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
		EmitArrays::numeric_entry((inter_ti) word_compiled);
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
	packaging_state save = EmitArrays::begin_word(ED->v2v_bitmap_iname, K_value);
	@<Compile header information in the V-to-V structure@>;

	if ((left_count > 0) && (right_count > 0))
		@<Compile bitmap pre-initialised to the V-to-V relation at start of play@>;

	EmitArrays::end(save);

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
this is done by the function |RTRelations::relation_range| (below).

@<Index the left and right domains and calculate their sizes@> =
	left_count = RTRelations::relation_range(bp, 0);
	right_count = RTRelations::relation_range(bp, 1);

@ See "Relations.i6t" in the template layer for details.

@<Compile header information in the V-to-V structure@> =
	kind *left_kind = BinaryPredicates::term_kind(bp, 0);
	kind *right_kind = BinaryPredicates::term_kind(bp, 1);

	if ((Kinds::Behaviour::is_subkind_of_object(left_kind)) && (left_count > 0)) {
		EmitArrays::iname_entry(InstanceCounting::IK_count_property(left_kind));
	} else EmitArrays::numeric_entry(0);
	if ((Kinds::Behaviour::is_subkind_of_object(right_kind)) && (right_count > 0)) {
		EmitArrays::iname_entry(InstanceCounting::IK_count_property(right_kind));
	} else EmitArrays::numeric_entry(0);

	EmitArrays::numeric_entry((inter_ti) left_count);
	EmitArrays::numeric_entry((inter_ti) right_count);
	EmitArrays::iname_entry(RTKindConstructors::printing_fn_iname(left_kind));
	EmitArrays::iname_entry(RTKindConstructors::printing_fn_iname(right_kind));

	EmitArrays::numeric_entry(1); /* Cache broken flag */
	if ((left_count > 0) && (right_count > 0))
		EmitArrays::iname_entry(v2v_iname);
	else
		EmitArrays::numeric_entry(0);
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
	if ((bp->compilation_data.fast_route_finding) &&
		(Kinds::eq(left_kind, right_kind)) &&
		(Kinds::Behaviour::is_subkind_of_object(left_kind)) &&
		(left_count == right_count)) {
		if (left_count < 256) {
			v2v_iname = iname;
			packaging_state save = EmitArrays::begin_byte_by_extent(iname, K_number);
			EmitArrays::numeric_entry((inter_ti) (2*left_count*left_count));
			EmitArrays::end(save);
			bytes_used += 2*left_count*left_count;
		} else {
			v2v_iname = iname;
			packaging_state save = EmitArrays::begin_word_by_extent(iname, K_number);
			EmitArrays::numeric_entry((inter_ti) (2*left_count*left_count));
			EmitArrays::end(save);
			words_used += 2*left_count*left_count;
		}
	} else {
		v2v_iname = Emit::numeric_constant(iname, 0);
	}

@ The following function conveniently determines whether a given INFS is
within the domain of one of the terms of a relation; the rule is that it
mustn't itself express a domain (otherwise, e.g., the kind "woman" would
show up as within the domain of "person" -- we want only instances here,
not kinds); and that it must inherit from the domain of the term.

=
int RTRelations::infs_in_domain(inference_subject *infs, binary_predicate *bp, int index) {
	if (KindSubjects::to_kind(infs) != NULL) return FALSE;
	kind *K = BinaryPredicates::term_kind(bp, index);
	if (K == NULL) return FALSE;
	inference_subject *dom_infs = KindSubjects::from_kind(K);
	if (InferenceSubjects::is_strictly_within(infs, dom_infs)) return TRUE;
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
	POSITIVE_KNOWLEDGE_LOOP(inf, RelationSubjects::from_bp(bp), relation_inf) {
		inference_subject *left_infs, *right_infs;
		RelationInferences::get_term_subjects(inf, &left_infs, &right_infs);
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
set to the same partition number. The template functions which set and remove
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
	if (ExplicitRelations::get_form_of_relation(bp) != Relation_Equiv)
		internal_error("attempt to make partition for a non-equivalence relation");
	explicit_bp_data *D = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
	int *partition_array = Memory::calloc(domain_size, sizeof(int), PARTITION_MREASON);
	for (int i=0; i<domain_size; i++) partition_array[i] = i+1;
	D->equiv_data->equivalence_partition = partition_array;
}

@ The A-parser has meanwhile been reading in facts about the helping relation:

>> Sophie helps Ryan. Daisy helps Ryan. Owen helps the player.

And it feeds these facts to us one at a time. It tells us that $A(S, R)$
has to be true by calling the function below for the helping relation with
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
	if (ExplicitRelations::get_form_of_relation(bp) != Relation_Equiv)
		internal_error("attempt to merge classes for a non-equivalence relation");
	explicit_bp_data *D = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
	if (bp->right_way_round == FALSE) bp = bp->reversal;
	int *partition_array = D->equiv_data->equivalence_partition;
	if (partition_array == NULL)
		internal_error("attempt to use null equivalence partition array");
	int little, big; /* or, The Fairies' Parliament */
	big = partition_array[ix1]; little = partition_array[ix2];
	if (big == little) return;
	if (big < little) { int swap = little; little = big; big = swap; }
	for (int i=0; i<domain_size; i++)
		if (partition_array[i] == big)
			partition_array[i] = little;
}

@ Once that process has completed, the code which compiles the
initial state of the I6 object tree calls the following function to ask it
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
	ValueProperties::assert(ExplicitRelations::get_i6_storage_property(bp),
		infs, val, CERTAIN_CE);

@ Where:

=
int RTRelations::equivalence_relation_get_class(binary_predicate *bp, int ix) {
	if (ExplicitRelations::get_form_of_relation(bp) != Relation_Equiv)
		internal_error("attempt to merge classes for a non-equivalence relation");
	if (bp->right_way_round == FALSE) bp = bp->reversal;
	explicit_bp_data *D = RETRIEVE_POINTER_explicit_bp_data(bp->family_specific);
	int *partition_array = D->equiv_data->equivalence_partition;;
	if (partition_array == NULL)
		internal_error("attempt to use null equivalence partition array");
	return partition_array[ix];
}

@h Relation guards.
The following provides for run-time checking to make sure relations are
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

@ 

=
void RTRelations::guard_compilation_agent(compilation_subtask *t) {
	relation_guard *rg = RETRIEVE_POINTER_relation_guard(t->data);
	@<Compile RGuard f0 function@>;
	@<Compile RGuard f1 function@>;
	@<Compile RGuard T function@>;
	@<Compile RGuard MT function@>;
	@<Compile RGuard MF function@>;
}

@<Compile RGuard f0 function@> =
	if (rg->guard_f0_iname) {
		packaging_state save = Functions::begin(rg->guard_f0_iname);
		local_variable *X_lv =
			LocalVariables::new_internal_commented(I"X", I"which is related to at most one object");
		inter_symbol *X_s = LocalVariables::declare(X_lv);
		if (rg->f0) {
			if (rg->check_R) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(OFCLASS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, X_s);
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_R));
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
			}
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
			CompileSchemas::from_local_variables_in_val_context(rg->f0, X_lv, X_lv);
			EmitCode::up();
			if (rg->check_R) {
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_nothing();
				EmitCode::up();
			}
		} else {
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_nothing();
			EmitCode::up();
		}
		Functions::end(save);
	}

@<Compile RGuard f1 function@> =
	if (rg->guard_f1_iname) {
		packaging_state save = Functions::begin(rg->guard_f1_iname);
		local_variable *X_lv =
			LocalVariables::new_internal_commented(I"X", I"which is related to at most one object");
		inter_symbol *X_s = LocalVariables::declare(X_lv);
		if (rg->f1) {
			if (rg->check_L) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(OFCLASS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, X_s);
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_L));
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
			}
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
			CompileSchemas::from_local_variables_in_val_context(rg->f1, X_lv, X_lv);
			EmitCode::up();
			if (rg->check_L) {
					EmitCode::up();
				EmitCode::up();
				EmitCode::inv(RETURN_BIP);
				EmitCode::down();
					EmitCode::val_nothing();
				EmitCode::up();
			}
		} else {
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_nothing();
			EmitCode::up();
		}
		Functions::end(save);
	}

@<Compile RGuard T function@> =
	if (rg->guard_test_iname) {
		packaging_state save = Functions::begin(rg->guard_test_iname);
		local_variable *L_lv = LocalVariables::new_internal_commented(I"L", I"left member of pair");
		local_variable *R_lv = LocalVariables::new_internal_commented(I"R", I"right member of pair");
		inter_symbol *L_s = LocalVariables::declare(L_lv);
		inter_symbol *R_s = LocalVariables::declare(R_lv);
		if (rg->inner_test) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();

				int downs = 0;
				if (rg->check_L) {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
						EmitCode::inv(OFCLASS_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, L_s);
							EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_L));
						EmitCode::up();
					downs++;
				}
				if (rg->check_R) {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
						EmitCode::inv(OFCLASS_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, R_s);
							EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_R));
						EmitCode::up();
					downs++;
				}
				CompileSchemas::from_local_variables_in_val_context(rg->inner_test, L_lv, R_lv);
				for (int i=0; i<downs; i++) EmitCode::up();

				EmitCode::code();
				EmitCode::down();
					EmitCode::rtrue();
				EmitCode::up();
			EmitCode::up();

		}
		EmitCode::rfalse();
		Functions::end(save);
	}

@<Compile RGuard MT function@> =
	if (rg->guard_make_true_iname) {
		packaging_state save = Functions::begin(rg->guard_make_true_iname);
		local_variable *L_lv = LocalVariables::new_internal_commented(I"L", I"left member of pair");
		local_variable *R_lv = LocalVariables::new_internal_commented(I"R", I"right member of pair");
		inter_symbol *L_s = LocalVariables::declare(L_lv);
		inter_symbol *R_s = LocalVariables::declare(R_lv);
		if (rg->inner_make_true) {
			int downs = 1;
			if ((rg->check_L == NULL) && (rg->check_R == NULL)) downs = 0;

			if (downs > 0) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();

				if ((rg->check_L) && (rg->check_R)) {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
					downs = 2;
				}

				if (rg->check_L) {
					EmitCode::inv(OFCLASS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, L_s);
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_L));
					EmitCode::up();
				}
				if (rg->check_R) {
					EmitCode::inv(OFCLASS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, R_s);
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_R));
					EmitCode::up();
				}
				for (int i=0; i<downs-1; i++) EmitCode::up();
				EmitCode::code();
				EmitCode::down();
			}

			CompileSchemas::from_local_variables_in_void_context(rg->inner_make_true, L_lv, R_lv);
			EmitCode::rtrue();

			if (downs > 0) { EmitCode::up(); EmitCode::up(); }

			EmitCode::call(Hierarchy::find(RUNTIMEPROBLEM_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(RTP_RELKINDVIOLATION_HL));
				EmitCode::val_symbol(K_value, L_s);
				EmitCode::val_symbol(K_value, R_s);
				EmitCode::val_iname(K_value, RTRelations::iname(rg->guarding));
			EmitCode::up();
		}
		Functions::end(save);
	}

@<Compile RGuard MF function@> =
	if (rg->guard_make_false_iname) {
		packaging_state save = Functions::begin(rg->guard_make_false_iname);
		local_variable *L_lv = LocalVariables::new_internal_commented(I"L", I"left member of pair");
		local_variable *R_lv = LocalVariables::new_internal_commented(I"R", I"right member of pair");
		inter_symbol *L_s = LocalVariables::declare(L_lv);
		inter_symbol *R_s = LocalVariables::declare(R_lv);
		if (rg->inner_make_false) {
			int downs = 1;
			if ((rg->check_L == NULL) && (rg->check_R == NULL)) downs = 0;

			if (downs > 0) {
				EmitCode::inv(IF_BIP);
				EmitCode::down();

				if ((rg->check_L) && (rg->check_R)) {
					EmitCode::inv(AND_BIP);
					EmitCode::down();
					downs = 2;
				}

				if (rg->check_L) {
					EmitCode::inv(OFCLASS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, L_s);
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_L));
					EmitCode::up();
				}
				if (rg->check_R) {
					EmitCode::inv(OFCLASS_BIP);
					EmitCode::down();
						EmitCode::val_symbol(K_value, R_s);
						EmitCode::val_iname(K_value, RTKindDeclarations::iname(rg->check_R));
					EmitCode::up();
				}
				for (int i=0; i<downs-1; i++) EmitCode::up();
				EmitCode::code();
				EmitCode::down();
			}

			CompileSchemas::from_local_variables_in_void_context(rg->inner_make_false, L_lv, R_lv);
			EmitCode::rtrue();

			if (downs > 0) { EmitCode::up(); EmitCode::up(); }

			EmitCode::call(Hierarchy::find(RUNTIMEPROBLEM_HL));
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(RTP_RELKINDVIOLATION_HL));
				EmitCode::val_symbol(K_value, L_s);
				EmitCode::val_symbol(K_value, R_s);
				EmitCode::val_iname(K_value, RTRelations::iname(rg->guarding));
			EmitCode::up();
		}
		Functions::end(save);
	}

@h Relations tested by an I7 condition.
When a relation has to be tested as a condition (in the wording |W|), we can't
simply embed that condition as the Inter schema for "test relation": it might
very well need local variables, the table row-choosing variables, etc., to
evaluate. It has to be tested in its own context. So we generate a function
which takes two parameters |t_0| and |t_1| and returns true or false according
to whether or not $R(|t_0|, |t_1|)$.

This is where those functions are compiled.

=
void RTRelations::compile_function_to_decide(inter_name *rname,
	wording W, bp_term_details par1, bp_term_details par2) {

	packaging_state save = Functions::begin(rname);

	stack_frame *phsf = Frames::current_stack_frame();
	RTRelations::add_term_as_call_parameter(phsf, par1);
	RTRelations::add_term_as_call_parameter(phsf, par2);

	Frames::enable_its(phsf);

	parse_node *spec = NULL;
	if (<s-condition>(W)) spec = <<rp>>;
	if ((spec == NULL) || (Dash::validate_conditional_clause(spec) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadRelationCondition),
			"the condition defining this relation makes no sense to me",
			"although the definition was properly formed - it is only the part after "
			"'when' which I can't follow.");
	} else {
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();
			CompileValues::to_code_val(spec);
		EmitCode::up();
	}

	Functions::end(save);
}

@ And that needs this, which adds the given BP term as a call parameter to the
function currently being compiled, deciding that something is an object if
its kind indications are all blank, but verifying that the value supplied
matches the specific necessary kind of object if there is one.

=
void RTRelations::add_term_as_call_parameter(stack_frame *phsf,
	bp_term_details bptd) {
	kind *K = BPTerms::kind(&bptd);
	kind *PK = K;
	if ((PK == NULL) || (Kinds::Behaviour::is_subkind_of_object(PK))) PK = K_object;
	local_variable *lv = LocalVariables::new_call_parameter(phsf, bptd.called_name, PK);
	inter_symbol *lv_s = LocalVariables::declare(lv);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NOT_BIP);
			EmitCode::down();
				EmitCode::inv(OFCLASS_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, lv_s);
					EmitCode::val_iname(K_value, RTKindDeclarations::iname(K));
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::rfalse();
			EmitCode::up();
		EmitCode::up();
	}
}
