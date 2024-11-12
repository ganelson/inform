[InvInstruction::] The Inv Construct.

Defining the inv construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void InvInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(INV_IST, I"inv");
	InterInstruction::specify_syntax(IC, I"inv TOKEN");
	InterInstruction::data_extent_always(IC, 2);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, InvInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_TRANSPOSE_MTID, InvInstruction::transpose);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_MTID, InvInstruction::verify);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, InvInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, InvInstruction::verify_children);
}

@h Instructions.
In bytecode, the frame of an |inv| instruction is laid out with the
compulsory words -- see //Inter Nodes// -- followed by:

@d METHOD_INV_IFLD  (DATA_IFLD + 0)
@d INVOKEE_INV_IFLD (DATA_IFLD + 1)

@ It's arguably the case that |inv| is three instructions, not one, but it is
also arguable the other way, and here we are. The |METHOD_INV_IFLD| indicates
which variant we are looking at:

@d PRIMITIVE_INVMETH 1
@d FUNCTION_INVMETH 2
@d OPCODE_INVMETH 3

=
inter_error_message *InvInstruction::new_primitive(inter_bookmark *IBM,
	inter_symbol *prim_s, inter_ti level, inter_error_location *eloc) {
	inter_ti GID = InterSymbolsTable::id_from_symbol(InterBookmark::tree(IBM), NULL, prim_s);
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, INV_IST,
		/* METHOD_INV_IFLD:  */ PRIMITIVE_INVMETH,
		/* INVOKEE_INV_IFLD: */ GID,
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

inter_error_message *InvInstruction::new_function_call(inter_bookmark *IBM,
	inter_symbol *function_s, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, INV_IST,
		/* METHOD_INV_IFLD:  */ FUNCTION_INVMETH,
		/* INVOKEE_INV_IFLD: */ InterSymbolsTable::id_at_bookmark(IBM, function_s),
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

inter_error_message *InvInstruction::new_assembly(inter_bookmark *IBM,
	text_stream *opcode_name, inter_ti level, inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_2_data_fields(IBM, INV_IST,
		/* METHOD_INV_IFLD:  */ OPCODE_INVMETH,
		/* INVOKEE_INV_IFLD: */ InterWarehouse::create_text_at(IBM, opcode_name),
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

void InvInstruction::transpose(inter_construct *IC, inter_tree_node *P, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	if (P->W.instruction[METHOD_INV_IFLD] == OPCODE_INVMETH)
		P->W.instruction[INVOKEE_INV_IFLD] = grid[P->W.instruction[INVOKEE_INV_IFLD]];
}

@ Verification consists only of sanity checks.

=
void InvInstruction::verify(inter_construct *IC, inter_tree_node *P, inter_package *owner,
	inter_error_message **E) {
	switch (P->W.instruction[METHOD_INV_IFLD]) {
		case PRIMITIVE_INVMETH:
			*E = VerifyingInter::GSID_field(P, INVOKEE_INV_IFLD, PRIMITIVE_IST);
			if (*E) return;
			break;
		case OPCODE_INVMETH:
			*E = VerifyingInter::text_field(owner, P, INVOKEE_INV_IFLD);
			if (*E) return;
			break;
		case FUNCTION_INVMETH:
			*E = VerifyingInter::SID_field(owner, P, INVOKEE_INV_IFLD, INVALID_IST);
			if (*E) return;
			break;
		default:
			*E = Inode::error(P, I"bad invocation method", NULL);
			break;
	}
}

@ Verification of the child nodes, however, is not entirely passive, as we
shall see.

This function implements a primitive typechecker for invocations, though it is
more notable for what it doesn't check than for what it does: Inter is a very
permissive language. The rules are:
(a) An assembly opcode can have any number of arguments, of any category.
(b) A function call can have any number of arguments, provided they all have
category |val|.
(c) A primitive invocation must have exactly the number of arguments in its
signature, whose categories must be exactly as given in the signature. For
example, if the signature of the primitive invoked at |P| is |ref val val -> void|,
then |P| needs to have exactly three children, of categories |ref|, |val|, |val|.

=
void InvInstruction::verify_children(inter_construct *IC, inter_tree_node *P,
	inter_error_message **E) {
	if (P->W.instruction[METHOD_INV_IFLD] == PRIMITIVE_INVMETH) {
		int arity_as_invoked=0;
		LOOP_THROUGH_INTER_CHILDREN(C, P) arity_as_invoked++;
		inter_tree *I = P->tree;
		inter_symbol *prim_s = InvInstruction::primitive(P);
		@<Opportunistically improve the use of indirect function call primitives@>;
		@<Check there are exactly the right number of arguments@>;
	}
	int i=0;
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		i++;
		if (C->W.instruction[0] == SPLAT_IST) continue;
		if ((C->W.instruction[0] != INV_IST) &&
			(C->W.instruction[0] != REF_IST) &&
			(C->W.instruction[0] != LAB_IST) &&
			(C->W.instruction[0] != CODE_IST) &&
			(C->W.instruction[0] != VAL_IST) &&
			(C->W.instruction[0] != EVALUATION_IST) &&
			(C->W.instruction[0] != REFERENCE_IST) &&
			(C->W.instruction[0] != CAST_IST) &&
			(C->W.instruction[0] != COMMENT_IST) &&
			(C->W.instruction[0] != ASSEMBLY_IST)) {
			*E = Inode::error(P, I"forbidden instruction under an inv", NULL);
			return;
		}
		if (P->W.instruction[METHOD_INV_IFLD] != OPCODE_INVMETH)
			@<Check that the category of the child matches what is expected@>;
	}
}

@ This is the part which is not passive. If we observe an indirect function
call made by invoking a primitive such as |!indirect0|, but with the wrong
number of arguments, then we change it to the version with the right arity.
(For example, if we see |!indirect1| with three arguments, we correct it to
|!indirect3|.)

@<Opportunistically improve the use of indirect function call primitives@> =
	if (PrimitiveInstruction::arity(prim_s) != arity_as_invoked) {
		inter_ti BIP = Primitives::to_BIP(I, prim_s);
		if (Primitives::is_BIP_for_indirect_call_returning_value(BIP)) {
			if (Primitives::arity_too_great_for_indirection(arity_as_invoked-1)) {
				*E = Inode::error(P, I"over-complex indirect call", NULL);
				return;
			}
			prim_s = Primitives::from_BIP(I,
				Primitives::BIP_for_indirect_call_returning_value(arity_as_invoked - 1));
			InvInstruction::write_primitive(I, P, prim_s);
		} else if (Primitives::is_BIP_for_void_indirect_call(BIP)) {
			prim_s = Primitives::from_BIP(I,
				Primitives::BIP_for_void_indirect_call(arity_as_invoked - 1));
			InvInstruction::write_primitive(I, P, prim_s);
		}
	}

@<Check there are exactly the right number of arguments@> =
	if (PrimitiveInstruction::arity(prim_s) != arity_as_invoked) {
		text_stream *err = Str::new();
		WRITE_TO(err, "this inv of %S should have %d argument(s), but has %d",
			(prim_s)?(InterSymbol::identifier(prim_s)):I"<unknown>",
			PrimitiveInstruction::arity(prim_s), arity_as_invoked);
		*E = Inode::error(P, err, NULL);
		return;
	}

@ In effect, this is a limited form of typechecker for invocations. For example,
if the invocation has the signature |ref val -> void|, then we expect its first
child (operand 0) to be a |ref|, and its second (operand 1) to be a |val|.

@<Check that the category of the child matches what is expected@> =
	inter_ti cat_found = InvInstruction::evaluated_category(C);
	inter_ti cat_needed = VAL_PRIM_CAT;
	if (P->W.instruction[METHOD_INV_IFLD] == PRIMITIVE_INVMETH)
		cat_needed = PrimitiveInstruction::operand_category(
			InvInstruction::primitive(P), i-1);
	if (cat_found != cat_needed) {
		inter_symbol *invokee = NULL;
		if (P->W.instruction[METHOD_INV_IFLD] == PRIMITIVE_INVMETH)
			invokee = InvInstruction::primitive(P);
		if (P->W.instruction[METHOD_INV_IFLD] == FUNCTION_INVMETH)
			invokee = InvInstruction::function(P);
		text_stream *err = Str::new();
		WRITE_TO(err, "operand %d of inv '%S' should be %s, but this is %s",
			i, (invokee)?(InterSymbol::identifier(invokee)):I"<unknown>",
			PrimitiveInstruction::cat_name(cat_needed),
			PrimitiveInstruction::cat_name(cat_found));
		*E = Inode::error(C, err, NULL);
		return;
	}

@ So this is the category for the value produced (if any) by an instruction.
The default is 0, which means |void|.

=
inter_ti InvInstruction::evaluated_category(inter_tree_node *P) {
	switch (P->W.instruction[0]) {
		case REF_IST:        return REF_PRIM_CAT;
		case REFERENCE_IST:  return REF_PRIM_CAT;
		case VAL_IST:        return VAL_PRIM_CAT;
		case EVALUATION_IST: return VAL_PRIM_CAT;
		case CAST_IST:       return VAL_PRIM_CAT;
		case ASSEMBLY_IST:   return VAL_PRIM_CAT;
		case LAB_IST:        return LAB_PRIM_CAT;
		case CODE_IST:       return CODE_PRIM_CAT;
		case INV_IST:
			if (P->W.instruction[METHOD_INV_IFLD] == PRIMITIVE_INVMETH)
				return PrimitiveInstruction::result_category(
					InvInstruction::primitive(P));
			return VAL_PRIM_CAT;
	}
	return 0;
}

@h Creating from textual Inter syntax.

=
void InvInstruction::read(inter_construct *IC, inter_bookmark *IBM, inter_line_parse *ilp, 
	inter_error_location *eloc, inter_error_message **E) {
	text_stream *invoked_text = ilp->mr.exp[0];
	switch (Str::get_first_char(invoked_text)) {
		case '!': @<This is a primitive invocation@>;
		case '@': @<This is an assembly opcode invocation@>;
		default: @<This is a function call invocation@>;
	}
}

@<This is a primitive invocation@> =
	inter_tree *I = InterBookmark::tree(IBM);
	inter_symbol *prim_s =
		InterSymbolsTable::symbol_from_name(InterTree::global_scope(I), invoked_text);
	if (prim_s == NULL) {
		prim_s = Primitives::declare_one_named(I,
			&(I->site.strdata.package_types_bookmark), invoked_text);
		if (prim_s == NULL) {
			*E = InterErrors::quoted(I"'inv' on undeclared primitive", invoked_text, eloc);
			return;
		}
	}
	*E = InvInstruction::new_primitive(IBM, prim_s, (inter_ti) ilp->indent_level, eloc);
	return;

@<This is an assembly opcode invocation@> =
	*E = InvInstruction::new_assembly(IBM, invoked_text, (inter_ti) ilp->indent_level, eloc);
	return;

@<This is a function call invocation@> =
	inter_symbol *function_s = TextualInter::find_symbol(IBM, eloc, invoked_text, 0, E);
	if (function_s == NULL) {
		*E = InterErrors::quoted(I"'inv' on unknown function", invoked_text, eloc);
	} else {
		*E = InvInstruction::new_function_call(IBM, function_s,
			(inter_ti) ilp->indent_level, eloc);
	}
	return;

@h Writing to textual Inter syntax.

=
void InvInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	switch (InvInstruction::method(P)) {
		case PRIMITIVE_INVMETH:
			WRITE("inv %S", InterSymbol::identifier(InvInstruction::primitive(P)));
			break;
		case OPCODE_INVMETH:
			WRITE("inv %S", Inode::ID_to_text(P, P->W.instruction[INVOKEE_INV_IFLD]));
			break;
		case FUNCTION_INVMETH:
			WRITE("inv ");
			TextualInter::write_symbol_from(OUT, P, INVOKEE_INV_IFLD);
			break;
	}
}

@h Access functions.

=
inter_ti InvInstruction::method(inter_tree_node *P) {
	if (Inode::is(P, INV_IST)) return P->W.instruction[METHOD_INV_IFLD];
	return 0;
}

inter_symbol *InvInstruction::function(inter_tree_node *P) {
	if ((Inode::is(P, INV_IST)) &&
		(InvInstruction::method(P) == FUNCTION_INVMETH))
		return InterSymbolsTable::symbol_from_ID_at_node(P, INVOKEE_INV_IFLD);
	return NULL;
}

inter_symbol *InvInstruction::primitive(inter_tree_node *P) {
	if ((Inode::is(P, INV_IST)) &&
		(InvInstruction::method(P) == PRIMITIVE_INVMETH))
		return InterSymbolsTable::global_symbol_from_ID_at_node(P, INVOKEE_INV_IFLD);
	return NULL;
}

text_stream *InvInstruction::opcode(inter_tree_node *P) {
	if ((Inode::is(P, INV_IST)) &&
		(InvInstruction::method(P) == OPCODE_INVMETH))
		return Inode::ID_to_text(P, P->W.instruction[INVOKEE_INV_IFLD]);
	return NULL;
}

@ In //Transmigration// and for various other reasons, it's necessary to change
an invocation into a primitive, or a different primitive. So:

=
void InvInstruction::write_primitive(inter_tree *I, inter_tree_node *P, inter_symbol *prim) {
	if (Inode::is(P, INV_IST)) {
		P->W.instruction[METHOD_INV_IFLD] = PRIMITIVE_INVMETH;
		P->W.instruction[INVOKEE_INV_IFLD] = InterSymbolsTable::id_from_symbol(I, NULL, prim);
	} else internal_error("wrote primitive to non-invocation");
}
