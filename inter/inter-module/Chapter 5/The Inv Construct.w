[Inter::Inv::] The Inv Construct.

Defining the inv construct.

@

@e INV_IST

=
void Inter::Inv::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		INV_IST,
		L"inv (%C+)",
		&Inter::Inv::read,
		&Inter::Inv::pass2,
		&Inter::Inv::verify,
		&Inter::Inv::write,
		NULL,
		&Inter::Inv::accept_child,
		&Inter::Inv::no_more_children,
		&Inter::Inv::show_dependencies,
		I"inv", I"invs");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE;
}

@

@d BLOCK_INV_IFLD 2
@d METHOD_INV_IFLD 3
@d INVOKEE_INV_IFLD 4
@d OPERANDS_INV_IFLD 5

@d EXTENT_INV_IFR 6

@d INVOKED_PRIMITIVE 1
@d INVOKED_ROUTINE 2
@d INVOKED_OPCODE 3

=
inter_error_message *Inter::Inv::read(inter_reading_state *IRS, inter_line_parse *ilp, inter_error_location *eloc) {
	if (ilp->no_annotations > 0) return Inter::Errors::plain(I"__annotations are not allowed", eloc);
	inter_error_message *E = Inter::Defn::vet_level(IRS, INV_IST, ilp->indent_level, eloc);
	if (E) return E;

	inter_symbol *routine = Inter::Defn::get_latest_block_symbol();
	if (routine == NULL) return Inter::Errors::plain(I"'inv' used outside function", eloc);

	inter_symbol *invoked_name = Inter::SymbolsTables::symbol_from_name(Inter::get_global_symbols(IRS->read_into), ilp->mr.exp[0]);
	if (invoked_name == NULL) invoked_name = Inter::SymbolsTables::symbol_from_name(Inter::Bookmarks::scope(IRS), ilp->mr.exp[0]);
	if (invoked_name == NULL) return Inter::Errors::quoted(I"'inv' on unknown routine or primitive", ilp->mr.exp[0], eloc);

	if ((Inter::Symbols::is_extern(invoked_name)) ||
		(Inter::Symbols::is_predeclared(invoked_name)))
		return Inter::Inv::new_call(IRS, routine, invoked_name, (inter_t) ilp->indent_level, eloc);
	switch (Inter::Symbols::defining_frame(invoked_name).data[ID_IFLD]) {
		case PRIMITIVE_IST:
			return Inter::Inv::new_primitive(IRS, routine, invoked_name, (inter_t) ilp->indent_level, eloc);
		case CONSTANT_IST:
			if (Inter::Constant::is_routine(invoked_name))
				return Inter::Inv::new_call(IRS, routine, invoked_name, (inter_t) ilp->indent_level, eloc);
			break;
	}
	return Inter::Errors::quoted(I"not a function or primitive", ilp->mr.exp[0], eloc);
}

inter_error_message *Inter::Inv::new_primitive(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *invoked_name, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS, INV_IST, 0, INVOKED_PRIMITIVE, Inter::SymbolsTables::id_from_symbol(IRS->read_into, NULL, invoked_name),
		Inter::create_frame_list(IRS->read_into), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Inv::new_call(inter_reading_state *IRS, inter_symbol *routine, inter_symbol *invoked_name, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS, INV_IST, 0, INVOKED_ROUTINE, Inter::SymbolsTables::id_from_IRS_and_symbol(IRS, invoked_name), Inter::create_frame_list(IRS->read_into), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Inv::new_assembly(inter_reading_state *IRS, inter_symbol *routine, inter_t opcode_storage, inter_t level, inter_error_location *eloc) {
	inter_frame P = Inter::Frame::fill_4(IRS, INV_IST, 0, INVOKED_OPCODE, opcode_storage, Inter::create_frame_list(IRS->read_into), eloc, (inter_t) level);
	inter_error_message *E = Inter::Defn::verify_construct(P);
	if (E) return E;
	Inter::Frame::insert(P, IRS);
	return NULL;
}

inter_error_message *Inter::Inv::verify(inter_frame P) {
	if (P.extent != EXTENT_INV_IFR) return Inter::Frame::error(&P, I"extent wrong", NULL);
	inter_symbols_table *locals = Inter::Packages::scope_of(P);
	if (locals == NULL) return Inter::Frame::error(&P, I"function has no symbols table", NULL);

	switch (P.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE: {
			inter_error_message *E = Inter::Verify::global_symbol(P, P.data[INVOKEE_INV_IFLD], PRIMITIVE_IST); if (E) return E;
			break;
		}
		case INVOKED_OPCODE:
		case INVOKED_ROUTINE:
			break;
		default:
			return Inter::Frame::error(&P, I"bad invocation method", NULL);
	}

	return NULL;
}

inter_error_message *Inter::Inv::pass2(inter_frame P) {
	if (P.data[METHOD_INV_IFLD] == INVOKED_ROUTINE) {
		inter_error_message *E = Inter::Verify::symbol(P, P.data[INVOKEE_INV_IFLD], CONSTANT_IST);
		if (E) return E;
	}
	return NULL;
}

inter_error_message *Inter::Inv::write(OUTPUT_STREAM, inter_frame P) {
	if (P.data[METHOD_INV_IFLD] == INVOKED_OPCODE) {
		WRITE("inv %S", Inter::get_text(P.repo_segment->owning_repo, P.data[INVOKEE_INV_IFLD]));
	} else {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (invokee) {
			WRITE("inv %S", invokee->symbol_name);
		} else return Inter::Frame::error(&P, I"cannot write inv", NULL);
	}
	return NULL;
}

void Inter::Inv::show_dependencies(inter_frame P, void (*callback)(struct inter_symbol *, struct inter_symbol *, void *), void *state) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *routine = pack->package_name;
	if (P.data[METHOD_INV_IFLD] == INVOKED_ROUTINE) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		(*callback)(routine, invokee, state);
	}
}

inter_frame_list *Inter::Inv::children_of_frame(inter_frame P) {
	return Inter::find_frame_list(P.repo_segment->owning_repo, P.data[OPERANDS_INV_IFLD]);
}

inter_error_message *Inter::Inv::accept_child(inter_frame P, inter_frame C) {
	if ((C.data[0] != INV_IST) && (C.data[0] != REF_IST) && (C.data[0] != LAB_IST) &&
		(C.data[0] != CODE_IST) && (C.data[0] != VAL_IST) && (C.data[0] != CONCATENATE_IST) &&
		(C.data[0] != REFCATENATE_IST) && (C.data[0] != CAST_IST) && (C.data[0] != SPLAT_IST))
		return Inter::Frame::error(&P, I"only inv, ref, cast, splat, lab, code, concatenate and val can be under an inv", NULL);
	Inter::add_to_frame_list(Inter::find_frame_list(P.repo_segment->owning_repo, P.data[OPERANDS_INV_IFLD]), C, NULL);
	return NULL;
}

inter_symbol *Inter::Inv::invokee(inter_frame P) {
	if (P.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)
		return Inter::SymbolsTables::global_symbol_from_frame_data(P, INVOKEE_INV_IFLD);
 	return Inter::SymbolsTables::symbol_from_frame_data(P, INVOKEE_INV_IFLD);
 }

inter_error_message *Inter::Inv::no_more_children(inter_frame P) {
	inter_repository *I = P.repo_segment->owning_repo;
	inter_frame_list *ifl = Inter::find_frame_list(I, P.data[OPERANDS_INV_IFLD]);
	int arity_as_invoked = Inter::size_of_frame_list(ifl);
	#ifdef CORE_MODULE
	if ((Inter::Inv::arity(P) != -1) &&
		(Inter::Inv::arity(P) != arity_as_invoked)) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (Emit::is_indirect_interp(invokee)) {
			inter_symbol *better = Emit::indirect_interp(arity_as_invoked - 1);
			P.data[INVOKEE_INV_IFLD] = Inter::SymbolsTables::id_from_symbol(I, NULL, better);
		} else if (Emit::is_indirectv_interp(invokee)) {
			inter_symbol *better = Emit::indirectv_interp(arity_as_invoked - 1);
			P.data[INVOKEE_INV_IFLD] = Inter::SymbolsTables::id_from_symbol(I, NULL, better);
		}
	}
	#endif
	if ((Inter::Inv::arity(P) != -1) &&
		(Inter::Inv::arity(P) != arity_as_invoked)) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		text_stream *err = Str::new();
		WRITE_TO(err, "this inv of %S should have %d argument(s), but has %d",
			(invokee)?(invokee->symbol_name):I"<unknown>", Inter::Inv::arity(P), arity_as_invoked);
		return Inter::Frame::error(&P, err, NULL);
	}
	int i=0;
	inter_frame C;
	LOOP_THROUGH_INTER_FRAME_LIST(C, ifl) {
		i++;
		if (C.data[0] == SPLAT_IST) continue;
		inter_t cat_as_invoked = Inter::Inv::evaluated_category(C);
		inter_t cat_needed = Inter::Inv::operand_category(P, i-1);
		if (cat_as_invoked != cat_needed) {
			inter_symbol *invokee = Inter::Inv::invokee(P);
			text_stream *err = Str::new();
			WRITE_TO(err, "operand %d of inv '%S' should be %s, but this is %s",
				i, (invokee)?(invokee->symbol_name):I"<unknown>",
				Inter::Inv::cat_name(cat_needed), Inter::Inv::cat_name(cat_as_invoked));
			return Inter::Frame::error(&C, err, NULL);
		}
	}
	return NULL;
}

char *Inter::Inv::cat_name(inter_t cat) {
	switch (cat) {
		case REF_PRIM_CAT: return "ref";
		case VAL_PRIM_CAT: return "val";
		case LAB_PRIM_CAT: return "lab";
		case CODE_PRIM_CAT: return "code";
		case 0: return "void";
	}
	return "<unknown>";
}

int Inter::Inv::arity(inter_frame P) {
	inter_symbol *invokee = Inter::Inv::invokee(P);
	switch (P.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE:
			return Inter::Primitive::arity(invokee);
		case INVOKED_ROUTINE:
			return -1;
		case INVOKED_OPCODE:
			return -1;
	}
	return 0;
}

inter_t Inter::Inv::evaluated_category(inter_frame P) {
	if (P.data[0] == REF_IST) return REF_PRIM_CAT;
	if (P.data[0] == VAL_IST) return VAL_PRIM_CAT;
	if (P.data[0] == CONCATENATE_IST) return VAL_PRIM_CAT;
	if (P.data[0] == REFCATENATE_IST) return REF_PRIM_CAT;
	if (P.data[0] == CAST_IST) return VAL_PRIM_CAT;
	if (P.data[0] == LAB_IST) return LAB_PRIM_CAT;
	if (P.data[0] == CODE_IST) return CODE_PRIM_CAT;
	if (P.data[0] == INV_IST) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (P.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)
			return Inter::Primitive::result_category(invokee);
		return VAL_PRIM_CAT;
	}
	internal_error("impossible operand");
	return 0;
}

inter_t Inter::Inv::operand_category(inter_frame P, int i) {
	if (P.data[0] == REF_IST) return REF_PRIM_CAT;
	if (P.data[0] == VAL_IST) return VAL_PRIM_CAT;
	if (P.data[0] == CONCATENATE_IST) return VAL_PRIM_CAT;
	if (P.data[0] == REFCATENATE_IST) return REF_PRIM_CAT;
	if (P.data[0] == CAST_IST) return VAL_PRIM_CAT;
	if (P.data[0] == LAB_IST) return LAB_PRIM_CAT;
	if (P.data[0] == INV_IST) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (P.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)
			return Inter::Primitive::operand_category(invokee, i);
		return VAL_PRIM_CAT;
	}
	internal_error("impossible operand");
	return 0;
}
