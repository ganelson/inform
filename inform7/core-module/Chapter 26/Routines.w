[Routines::] Routines.

To compile the bones of routines, and their local variable
declarations.

@ The code following is used throughout Inform, whenever we want to compile
an I6 routine. Sometimes that's in order to define a phrase, but often not.

We then compile the body code of our routine, and conclude with:

	|Routines::end_in_current_package();|

=
packaging_state Routines::begin(inter_name *name) {
	packaging_state save = Packaging::enter_home_of(name);
	Routines::begin_framed(name, NULL);
	return save;
}

void Routines::begin_in_current_package(inter_name *name) {
	Routines::begin_framed(name, NULL);
}

@ During the time when we're compiling the body of the routine,
we need to keep track of:

=
ph_stack_frame *currently_compiling_in_frame = NULL; /* the stack frame for this routine */
int currently_compiling_nnp = FALSE; /* is this a nonphrasal stack frame we made ourselves? */
inter_symbol *currently_compiling_inter_block = NULL; /* where Inter is being emitted to */
inter_name *currently_compiling_iname = NULL; /* routine we end up with */

@ So here is the flip:

=
void Routines::begin_framed(inter_name *iname, ph_stack_frame *phsf) {
	if (iname == NULL) internal_error("no iname for routine");
	package_request *R = iname->eventual_owner;
	if ((R == NULL) || (R == Hierarchy::main())) {
		LOG("Routine outside of package: ................................................ %n\n", iname);
		WRITE_TO(STDERR, "Routine outside of package: %n\n", iname);
		internal_error("routine outside of package");
	}
	currently_compiling_iname = iname;
	JumpLabels::reset();

	@<Prepare a suitable stack frame@>;

	Frames::Blocks::begin_code_blocks();

	currently_compiling_inter_block = Emit::block(iname);
	LocalVariables::declare(phsf, FALSE);
}

inter_symbol *Routines::self(void) {
	return currently_compiling_inter_block;
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

@ And here is the flop:

=
void Routines::end(packaging_state save) {
	Routines::end_in_current_package();
	Packaging::exit(save);
}

void Routines::end_in_current_package(void) {
	kind *R_kind = LocalVariables::deduced_function_kind(currently_compiling_in_frame);

	inter_name *kernel_name = NULL, *public_name = currently_compiling_iname;
	if ((currently_compiling_in_frame->allocated_pointers) ||
		(currently_compiling_in_frame->no_formal_parameters_needed > 0)) {
		if (Packaging::houseed_in_function(public_name)) {
			kernel_name = InterNames::one_off(I"kernel", public_name->eventual_owner);
			Inter::Symbols::set_flag(InterNames::to_symbol(kernel_name), MAKE_NAME_UNIQUE);
		} else {
			kernel_name = InterNames::new_in(KERNEL_ROUTINE_INAMEF, InterNames::to_module(public_name));
			LOG("PN is %n\n", public_name);
			internal_error("Routine not in function");
		}
		Packaging::house_with(kernel_name, public_name);
	}

	int needed = LocalVariables::count(currently_compiling_in_frame);
	if (kernel_name) needed++;
	if (VirtualMachines::allow_this_many_locals(needed) == FALSE)
		@<Issue a problem for too many locals@>;

	LocalVariables::declare(currently_compiling_in_frame, FALSE);
	Emit::end_block(currently_compiling_inter_block);

	Emit::routine(kernel_name?kernel_name:public_name,
		R_kind, currently_compiling_inter_block);

	if (kernel_name) @<Compile an outer shell routine with the public-facing name@>;

	Frames::Blocks::end_code_blocks();
	if (currently_compiling_nnp) Frames::remove_nonphrase_stack_frame();
	Frames::remove_current();
}

@<Compile an outer shell routine with the public-facing name@> =
	int returns_block_value =
		Kinds::Behaviour::uses_pointer_values(currently_compiling_in_frame->kind_returned);

	inter_symbol *rsymb = Emit::block(public_name);
	inter_symbol *I7RBLK_symbol = NULL;
	@<Compile I6 locals for the outer shell@>;
	int NBV = 0;
	@<Compile some setup code to make ready for the kernel@>;
	@<Compile a call to the kernel@>;
	@<Compile some teardown code now that the kernel has finished@>;
	@<Compile a return from the outer shell@>;
	Emit::end_block(rsymb);
	Emit::routine(public_name, R_kind, rsymb);

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
	Emit::inv_call(InterNames::to_symbol(iname));
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
	Emit::inv_primitive(store_interp);
	Emit::down();
	Emit::ref_symbol(K_value, I7RBLK_symbol);
	if (returns_block_value) {
		inter_name *iname = Hierarchy::find(BLKVALUECOPY_HL);
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
		Emit::val_symbol(K_number,I7RBLK_symbol);
	}

	Emit::inv_call(InterNames::to_symbol(kernel_name));
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
		Emit::inv_call(InterNames::to_symbol(iname));
		Emit::down();
		Emit::val(K_number, LITERAL_IVAL, (inter_t) pall->offset_index);
		Emit::up();
	}

	Emit::pull(K_value, Hierarchy::find(I7SFRAME_HL));

@<Compile a return from the outer shell@> =
	Emit::inv_primitive(return_interp);
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
