[NopInstruction::] The Nop Construct.

Defining the nop construct.

@h Definition.
This instruction does nothing at all.

=
void NopInstruction::define_construct(void) {
	inter_construct *IC = InterInstruction::create_construct(NOP_IST, I"nop");
	InterInstruction::fix_instruction_length_between(IC, 2, 2);
	InterInstruction::allow_in_depth_range(IC, 0, INFINITELY_DEEP);
	InterInstruction::permit(IC, OUTSIDE_OF_PACKAGES_ICUP);
	InterInstruction::permit(IC, INSIDE_PLAIN_PACKAGE_ICUP);
	InterInstruction::permit(IC, INSIDE_CODE_PACKAGE_ICUP);
	METHOD_ADD(IC, CONSTRUCT_WRITE_MTID, NopInstruction::write);
}

@h Instructions.
In bytecode, the frame of a |nop| instruction consists only of the two
compulsory words |ID_IFLD| and |LEVEL_IFLD|.

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
void NopInstruction::write(inter_construct *IC, OUTPUT_STREAM, inter_tree_node *P,
	inter_error_message **E) {
	WRITE("nop");
}
