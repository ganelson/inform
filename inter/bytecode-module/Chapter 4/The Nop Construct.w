[NopInstruction::] The Nop Construct.

Defining the nop construct.

@h Definition.
This instruction does nothing at all, has no textual representation and is
nevertheless useful when constructing Inter in memory.

It exists as a convenience used by Inform when it needs to write simultaneously to
multiple positions within the same node's child list -- the idea being that
a nop statement acts as a divider. For example, by placing the A write
position just before a nop N, and the B write position just after, Inform
will generate A1, A2, A3, ..., N, B1, B2, ..., rather than (say) A1, B1, A2,
A3, B2, ... The extra N is simply ignored in code generation, so it causes
no problems to have it.

=
void NopInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(NOP_IST, I"nop");
	InterInstruction::data_extent_always(IC, 0);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, NopInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |nop| instruction consists only of the two
compulsory words -- see //Inter Nodes//.

=
inter_error_message *NopInstruction::new(inter_bookmark *IBM, inter_ti level,
	inter_error_location *eloc) {
	inter_tree_node *P = Inode::new_with_0_data_fields(IBM, NOP_IST,
		eloc, level);
	inter_error_message *E = VerifyingInter::instruction(InterBookmark::package(IBM), P);
	if (E) return E;
	NodePlacement::move_to_moving_bookmark(P, IBM);
	return NULL;
}

@h Writing to textual Inter syntax.
The |nop| construct is not expressible in textual Inter, but can be printed out
all the same, purely so that a stack backtrace will show it.

=
void NopInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P) {
	WRITE("nop");
}
