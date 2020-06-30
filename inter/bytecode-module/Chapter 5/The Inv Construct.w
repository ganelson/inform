[Inter::Inv::] The Inv Construct.

Defining the inv construct.

@

@e INV_IST

=
void Inter::Inv::define(void) {
	inter_construct *IC = Inter::Defn::create_construct(
		INV_IST,
		L"inv (%C+)",
		I"inv", I"invs");
	IC->min_level = 1;
	IC->max_level = 100000000;
	IC->usage_permissions = INSIDE_CODE_PACKAGE + CAN_HAVE_CHILDREN;
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, Inter::Inv::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, Inter::Inv::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, Inter::Inv::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, Inter::Inv::write);
	METHOD_ADD(IC, VERIFY_INTER_CHILDREN_MTID, Inter::Inv::verify_children);
}

@

@d BLOCK_INV_IFLD 2
@d METHOD_INV_IFLD 3
@d INVOKEE_INV_IFLD 4

@d EXTENT_INV_IFR 5

@d INVOKED_PRIMITIVE 1
@d INVOKED_ROUTINE 2
@d INVOKED_OPCODE 3

=
void Inter::Inv::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	if (Inter::Annotations::exist(&(ilp->set))) { *E = Inter::Errors::plain(I"__annotations are not allowed", eloc); return; }
	*E = Inter::Defn::vet_level(IBM, INV_IST, ilp->indent_level, eloc);
	if (*E) return;

	inter_package *routine = Inter::Defn::get_latest_block_package();
	if (routine == NULL) { *E = Inter::Errors::plain(I"'inv' used outside function", eloc); return; }

	inter_symbol *invoked_name = Inter::SymbolsTables::symbol_from_name(Inter::Tree::global_scope(Inter::Bookmarks::tree(IBM)), ilp->mr.exp[0]);
	if (invoked_name == NULL) invoked_name = Inter::SymbolsTables::symbol_from_name(Inter::Bookmarks::scope(IBM), ilp->mr.exp[0]);
	if (invoked_name == NULL) { *E = Inter::Errors::quoted(I"'inv' on unknown routine or primitive", ilp->mr.exp[0], eloc); return; }

	if ((Inter::Symbols::is_extern(invoked_name)) ||
		(Inter::Symbols::is_predeclared(invoked_name))) {
		*E = Inter::Inv::new_call(IBM, invoked_name, (inter_ti) ilp->indent_level, eloc);
		return;
	}
	switch (Inter::Symbols::definition(invoked_name)->W.data[ID_IFLD]) {
		case PRIMITIVE_IST:
			*E = Inter::Inv::new_primitive(IBM, invoked_name, (inter_ti) ilp->indent_level, eloc);
			return;
		case CONSTANT_IST:
			if (Inter::Constant::is_routine(invoked_name)) {
				*E = Inter::Inv::new_call(IBM, invoked_name, (inter_ti) ilp->indent_level, eloc);
				return;
			}
			break;
	}
	*E = Inter::Errors::quoted(I"not a function or primitive", ilp->mr.exp[0], eloc);
}

inter_error_message *Inter::Inv::new_primitive(inter_bookmark *IBM, inter_symbol *invoked_name, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_3(IBM, INV_IST, 0, INVOKED_PRIMITIVE, Inter::SymbolsTables::id_from_symbol(Inter::Bookmarks::tree(IBM), NULL, invoked_name),
		eloc, (inter_ti) level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

inter_error_message *Inter::Inv::new_call(inter_bookmark *IBM, inter_symbol *invoked_name, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_3(IBM, INV_IST, 0, INVOKED_ROUTINE, Inter::SymbolsTables::id_from_IRS_and_symbol(IBM, invoked_name), eloc, (inter_ti) level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

inter_error_message *Inter::Inv::new_assembly(inter_bookmark *IBM, inter_ti opcode_storage, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::fill_3(IBM, INV_IST, 0, INVOKED_OPCODE, opcode_storage, eloc, (inter_ti) level);
	inter_error_message *E = Inter::Defn::verify_construct(Inter::Bookmarks::package(IBM), P);
	if (E) return E;
	Inter::Bookmarks::insert(IBM, P);
	return NULL;
}

void Inter::Inv::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti grid_extent, inter_error_message **E) {
	if (P->W.data[METHOD_INV_IFLD] == INVOKED_OPCODE)
		P->W.data[INVOKEE_INV_IFLD] = grid[P->W.data[INVOKEE_INV_IFLD]];
}

void Inter::Inv::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E) {
	if (P->W.extent != EXTENT_INV_IFR) { *E = Inode::error(P, I"extent wrong", NULL); return; }

	switch (P->W.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE:
			*E = Inter::Verify::global_symbol(P, P->W.data[INVOKEE_INV_IFLD], PRIMITIVE_IST); if (*E) return;
			break;
		case INVOKED_OPCODE:
		case INVOKED_ROUTINE:
			break;
		default:
			*E = Inode::error(P, I"bad invocation method", NULL);
			break;
	}
}

void Inter::Inv::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P, inter_error_message **E) {
	if (P->W.data[METHOD_INV_IFLD] == INVOKED_OPCODE) {
		WRITE("inv %S", Inode::ID_to_text(P, P->W.data[INVOKEE_INV_IFLD]));
	} else {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (invokee) {
			WRITE("inv %S", invokee->symbol_name);
		} else { *E = Inode::error(P, I"cannot write inv", NULL); return; }
	}
}

inter_symbol *Inter::Inv::invokee(inter_tree_node *P) {
	if (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)
		return Inter::SymbolsTables::global_symbol_from_frame_data(P, INVOKEE_INV_IFLD);
 	return Inter::SymbolsTables::symbol_from_frame_data(P, INVOKEE_INV_IFLD);
}

void Inter::Inv::verify_children(inter_construct *IC, inter_tree_node *P, inter_error_message **E) {
	int arity_as_invoked=0;
	LOOP_THROUGH_INTER_CHILDREN(C, P) arity_as_invoked++;
	if ((Inter::Inv::arity(P) != -1) &&
		(Inter::Inv::arity(P) != arity_as_invoked)) {
		inter_tree *I = P->tree;
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (Primitives::is_indirect_interp(Primitives::to_bip(I, invokee))) {
			inter_symbol *better = Primitives::get(I, Primitives::indirect_interp(arity_as_invoked - 1));
			P->W.data[INVOKEE_INV_IFLD] = Inter::SymbolsTables::id_from_symbol_F(P, NULL, better);
		} else if (Primitives::is_indirectv_interp(Primitives::to_bip(I, invokee))) {
			inter_symbol *better = Primitives::get(I, Primitives::indirectv_interp(arity_as_invoked - 1));
			P->W.data[INVOKEE_INV_IFLD] = Inter::SymbolsTables::id_from_symbol_F(P, NULL, better);
		}
	}
	if ((Inter::Inv::arity(P) != -1) &&
		(Inter::Inv::arity(P) != arity_as_invoked)) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		text_stream *err = Str::new();
		WRITE_TO(err, "this inv of %S should have %d argument(s), but has %d",
			(invokee)?(invokee->symbol_name):I"<unknown>", Inter::Inv::arity(P), arity_as_invoked);
		*E = Inode::error(P, err, NULL);
		return;
	}
	int i=0;
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		i++;
		if (C->W.data[0] == SPLAT_IST) continue;
		if ((C->W.data[0] != INV_IST) && (C->W.data[0] != REF_IST) && (C->W.data[0] != LAB_IST) &&
			(C->W.data[0] != CODE_IST) && (C->W.data[0] != VAL_IST) && (C->W.data[0] != EVALUATION_IST) &&
			(C->W.data[0] != REFERENCE_IST) && (C->W.data[0] != CAST_IST) && (C->W.data[0] != SPLAT_IST) && (C->W.data[0] != COMMENT_IST)) {
			*E = Inode::error(P, I"only inv, ref, cast, splat, lab, code, concatenate and val can be under an inv", NULL);
			return;
		}
		inter_ti cat_as_invoked = Inter::Inv::evaluated_category(C);
		inter_ti cat_needed = Inter::Inv::operand_category(P, i-1);
		if ((cat_as_invoked != cat_needed) && (P->W.data[METHOD_INV_IFLD] != INVOKED_OPCODE)) {
			inter_symbol *invokee = Inter::Inv::invokee(P);
			text_stream *err = Str::new();
			WRITE_TO(err, "operand %d of inv '%S' should be %s, but this is %s",
				i, (invokee)?(invokee->symbol_name):I"<unknown>",
				Inter::Inv::cat_name(cat_needed), Inter::Inv::cat_name(cat_as_invoked));
			*E = Inode::error(C, err, NULL);
			return;
		}
	}
}

char *Inter::Inv::cat_name(inter_ti cat) {
	switch (cat) {
		case REF_PRIM_CAT: return "ref";
		case VAL_PRIM_CAT: return "val";
		case LAB_PRIM_CAT: return "lab";
		case CODE_PRIM_CAT: return "code";
		case 0: return "void";
	}
	return "<unknown>";
}

int Inter::Inv::arity(inter_tree_node *P) {
	inter_symbol *invokee = Inter::Inv::invokee(P);
	switch (P->W.data[METHOD_INV_IFLD]) {
		case INVOKED_PRIMITIVE:
			return Inter::Primitive::arity(invokee);
		case INVOKED_ROUTINE:
			return -1;
		case INVOKED_OPCODE:
			return -1;
	}
	return 0;
}

inter_ti Inter::Inv::evaluated_category(inter_tree_node *P) {
	if (P->W.data[0] == REF_IST) return REF_PRIM_CAT;
	if (P->W.data[0] == VAL_IST) return VAL_PRIM_CAT;
	if (P->W.data[0] == EVALUATION_IST) return VAL_PRIM_CAT;
	if (P->W.data[0] == REFERENCE_IST) return REF_PRIM_CAT;
	if (P->W.data[0] == CAST_IST) return VAL_PRIM_CAT;
	if (P->W.data[0] == LAB_IST) return LAB_PRIM_CAT;
	if (P->W.data[0] == CODE_IST) return CODE_PRIM_CAT;
	if (P->W.data[0] == INV_IST) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)
			return Inter::Primitive::result_category(invokee);
		return VAL_PRIM_CAT;
	}
	internal_error("impossible operand");
	return 0;
}

inter_ti Inter::Inv::operand_category(inter_tree_node *P, int i) {
	if (P->W.data[0] == REF_IST) return REF_PRIM_CAT;
	if (P->W.data[0] == VAL_IST) return VAL_PRIM_CAT;
	if (P->W.data[0] == EVALUATION_IST) return VAL_PRIM_CAT;
	if (P->W.data[0] == REFERENCE_IST) return REF_PRIM_CAT;
	if (P->W.data[0] == CAST_IST) return VAL_PRIM_CAT;
	if (P->W.data[0] == LAB_IST) return LAB_PRIM_CAT;
	if (P->W.data[0] == INV_IST) {
		inter_symbol *invokee = Inter::Inv::invokee(P);
		if (P->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)
			return Inter::Primitive::operand_category(invokee, i);
		return VAL_PRIM_CAT;
	}
	internal_error("impossible operand");
	return 0;
}
