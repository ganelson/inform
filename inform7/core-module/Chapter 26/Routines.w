[Routines::] Routines.

To compile the bones of functions, and their local variable declarations.

@ The code following is used throughout Inform, whenever we want to compile
a function. Sometimes that's in order to define a phrase, but often not.

There are two ways to begin a function: specifying a stack frame which has
already been set up, or not. Here's not:

=
packaging_state Routines::begin(inter_name *name) {
	return Routines::begin_framed(name, NULL);
}

@ During the time when we're compiling the body of the routine,
we need to keep track of:

=
ph_stack_frame *currently_compiling_in_frame = NULL; /* the stack frame for this routine */
int currently_compiling_nnp = FALSE; /* is this a nonphrasal stack frame we made ourselves? */
inter_package *currently_compiling_inter_block = NULL; /* where Inter is being emitted to */
inter_name *currently_compiling_iname = NULL; /* routine we end up with */

@ So here is the general version, in which |phsf| may or may not be a
pre-existing stack frame:

=
packaging_state Routines::begin_framed(inter_name *iname, ph_stack_frame *phsf) {
	if (iname == NULL) internal_error("no iname for routine");
	currently_compiling_iname = iname;

	@<Prepare a suitable stack frame@>;

	Frames::Blocks::begin_code_blocks();

	packaging_state save = Emit::unused_packaging_state();
	currently_compiling_inter_block = Emit::block(&save, iname);
	LocalVariables::declare(phsf, FALSE);
	return save;
}

@ If the |phsf| argument is set, then we'll use that; otherwise we will
create a new nonphrasal stack frame.

@<Prepare a suitable stack frame@> =
	if (phsf == NULL) {
		phsf = Frames::new_nonphrasal();
		currently_compiling_nnp = TRUE;
	} else {
		currently_compiling_nnp = FALSE;
	}
	currently_compiling_in_frame = phsf;
	Frames::make_current(phsf);

@ As can be seen, very much more work is involved in finishing a function
than in starting it. This is because we need to split into two cases: one
where the code we've just compiled required allocation of heap memory
(e.g. for dynamic strings or lists), and another simpler case where it
did not.

=
void Routines::end(packaging_state save) {
	kind *R_kind = LocalVariables::deduced_function_kind(currently_compiling_in_frame);

	inter_name *kernel_name = NULL, *public_name = currently_compiling_iname;
	if ((currently_compiling_in_frame->allocated_pointers) ||
		(currently_compiling_in_frame->no_formal_parameters_needed > 0))
		kernel_name = Emit::kernel(public_name);

	int needed = LocalVariables::count(currently_compiling_in_frame);
	if (kernel_name) needed++;
	if (VirtualMachines::allow_this_many_locals(needed) == FALSE)
		@<Issue a problem for too many locals@>;

	LocalVariables::declare(currently_compiling_in_frame, FALSE);
	Emit::end_block();

	Emit::routine(kernel_name?kernel_name:public_name,
		R_kind, currently_compiling_inter_block);

	if (kernel_name) @<Compile an outer shell routine with the public-facing name@>;

	Frames::Blocks::end_code_blocks();
	if (currently_compiling_nnp) Frames::remove_nonphrase_stack_frame();
	Frames::remove_current();
	Emit::end_main_block(save);
}

@<Compile an outer shell routine with the public-facing name@> =
	int returns_block_value =
		Kinds::Behaviour::uses_pointer_values(currently_compiling_in_frame->kind_returned);

	inter_package *block_package = Emit::block(NULL, public_name);
	inter_symbol *I7RBLK_symbol = NULL;
	@<Compile I6 locals for the outer shell@>;
	int NBV = 0;
	@<Compile some setup code to make ready for the kernel@>;
	@<Compile a call to the kernel@>;
	@<Compile some teardown code now that the kernel has finished@>;
	@<Compile a return from the outer shell@>;
	Emit::end_block();
	Emit::routine(public_name, R_kind, block_package);

@ Suppose the routine has to return a list. Then the routine is compiled
with an extra first parameter (called |I7RBLK|), which is a pointer to the
block value in which to write the answer. After that come all of the call
parameters of the phrase (but none of the "let" or scratch-use locals). If,
on the other hand, the routine returns a word value, |I7RBLK| is placed
after the call parameters, and is used only as a scratch variable.

@<Compile I6 locals for the outer shell@> =
	if (returns_block_value) I7RBLK_symbol = Emit::local(K_number, I"I7RBLK", 0, I"pointer to return value");
	LocalVariables::declare(currently_compiling_in_frame, TRUE);
	if (!returns_block_value) I7RBLK_symbol = Emit::local(K_number, I"I7RBLK", 0, I"pointer to stack frame");

@ We allocate memory for each pointer value used in the stack frame:

@<Compile some setup code to make ready for the kernel@> =
	Emit::push(K_value, Hierarchy::find(I7SFRAME_HL));

	for (pointer_allocation *pall=currently_compiling_in_frame->allocated_pointers; pall; pall=pall->next_in_frame) {
		if (pall->offset_past > NBV) NBV = pall->offset_past;
	}
	inter_name *iname = Hierarchy::find(STACKFRAMECREATE_HL);
	Emit::inv_call_iname(iname);
	Emit::down();
	Emit::val(K_number, LITERAL_IVAL, (inter_t) NBV);
	Emit::up();

	for (pointer_allocation *pall=currently_compiling_in_frame->allocated_pointers; pall; pall=pall->next_in_frame)
		Kinds::RunTime::emit_heap_allocation(pall->allocation);

	for (int i=0; i<currently_compiling_in_frame->no_formal_parameters_needed; i++) {
		nonlocal_variable *nlv = NonlocalVariables::temporary_formal(i);
		Emit::push(K_value, NonlocalVariables::iname(nlv));
	}

@<Compile a call to the kernel@> =
	Emit::inv_primitive(Emit::opcode(STORE_BIP));
	Emit::down();
	Emit::ref_symbol(K_value, I7RBLK_symbol);
	if (returns_block_value) {
		inter_name *iname = Hierarchy::find(BLKVALUECOPY_HL);
		Emit::inv_call_iname(iname);
		Emit::down();
		Emit::val_symbol(K_number,I7RBLK_symbol);
	}

	Emit::inv_call_iname(kernel_name);
	Emit::down();
	LocalVariables::emit_parameter_list(currently_compiling_in_frame);
	Emit::up();

	if (returns_block_value) {
		Emit::up();
	}
	Emit::up();

@ Here we deallocate all the memory allocated earlier.

@<Compile some teardown code now that the kernel has finished@> =
	for (int i=currently_compiling_in_frame->no_formal_parameters_needed-1; i>=0; i--) {
		nonlocal_variable *nlv = NonlocalVariables::temporary_formal(i);
		Emit::pull(K_value, NonlocalVariables::iname(nlv));
	}

	for (pointer_allocation *pall=currently_compiling_in_frame->allocated_pointers; pall; pall=pall->next_in_frame) {
		inter_name *iname = Hierarchy::find(BLKVALUEFREEONSTACK_HL);
		Emit::inv_call_iname(iname);
		Emit::down();
		Emit::val(K_number, LITERAL_IVAL, (inter_t) pall->offset_index);
		Emit::up();
	}

	Emit::pull(K_value, Hierarchy::find(I7SFRAME_HL));

@<Compile a return from the outer shell@> =
	Emit::inv_primitive(Emit::opcode(RETURN_BIP));
	Emit::down();
		Emit::val_symbol(K_value, I7RBLK_symbol);
	Emit::up();

@<Issue a problem for too many locals@> =
	Problems::Issue::sentence_problem(_p_(PM_TooManyLocals),
		"there are too many temporarily-named values in this phrase",
		"which may be a sign that it is complicated enough to need breaking up "
		"into smaller phrases making use of each other. "
		"The limit is 15 at a time for a Z-machine project (see the Settings) "
		"and 256 at a time for Glulx. That has to include both values created in the "
		"declaration of a phrase (e.g. the 'N' in 'To deduct (N - a number) points: "
		"...', or the 'watcher' in 'Instead of taking something in the presence of "
		"a man (called the watcher): ...'), and also values created with 'let' or "
		"'repeat' (each 'repeat' loop claiming two such values) - not to mention "
		"one or two values occasionally needed to work with Tables. Because of all "
		"this, it's best to keep the complexity to a minimum within any single phrase.");
