[ReferenceInstruction::] The Reference Construct.

Defining the Reference construct.

@h Definition.
For what this does and why it is used, see //inter: Textual Inter//.

=
void ReferenceInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(REFERENCE_IST, I"reference");
	InterInstruction::specify_syntax(IC, I"reference");
	InterInstruction::data_extent_always(IC, 0);
	InterInstruction::allow_in_depth_range(IC, 1, INFINITELY_DEEP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	InterInstruction::permit(IC, CAN_HAVE_CHILDREN_ICUP);
	METHOD_ADD(IC, CONSTRUCT_READ_MTID, ReferenceInstruction::read);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, ReferenceInstruction::write);
	METHOD_ADD(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, ReferenceInstruction::verify_children);
}

@h Instructions.
In bytecode, the frame of a |reference| instruction is laid out with just the two
compulsory words -- see //Inter Nodes//.

=
inter_error_message *ReferenceInstruction::new(inter_bookmark *IBM, int level,
	inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_0_data_fields(IBM, REFERENCE_IST,
		eloc, (inter_ti) level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@ Verification consists only of sanity checks.

=
void ReferenceInstruction::verify_children(inter_construct *IC, inter_tree_node *P,
	inter_error_message **E) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if ((C->W.instruction[0] != INV_IST) &&
			(C->W.instruction[0] != REF_IST) &&
			(C->W.instruction[0] != SPLAT_IST) &&
			(C->W.instruction[0] != VAL_IST) &&
			(C->W.instruction[0] != LABEL_IST)) {
			*E = Inode::error(C, I"instruction cannot be referenced", NULL);
			return;
		}
	}
}

@h Creating from textual Inter syntax.

=
void ReferenceInstruction::read(inter_construct *IC, inter_bookmark *IBM,
	inter_line_parse *ilp, inter_error_location *eloc, inter_error_message **E) {
	*E = ReferenceInstruction::new(IBM, ilp->indent_level, eloc);
}

@h Writing to textual Inter syntax.

=
void ReferenceInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("reference");
}

@h Detection.
This tests whether a node |P| represents a reference to a primitive of a given
BIP. So, for example, it can look for the configuration
= (text as Inter)
	reference
		inv !propertyvalue
			...
=	
by being called with |seek_bip| equal to |PROPERTYVALUE_BIP|.	

=
int ReferenceInstruction::node_is_ref_to(inter_tree *I, inter_tree_node *P,
	inter_ti seek_bip) {
	int reffed = FALSE;
	while (Inode::is(P, REFERENCE_IST)) {
		P = InterTree::first_child(P);
		reffed = TRUE;
	}
	if (Inode::is(P, INV_IST)) {
		if (InvInstruction::method(P) == PRIMITIVE_INVMETH) {
			inter_symbol *prim = InvInstruction::primitive(P);
			inter_ti bip = Primitives::to_BIP(I, prim);
			if ((bip == seek_bip) && (reffed)) return TRUE;
		}
	}
	return FALSE;
}
