[Routines::] Routines.

To compile the bones of functions, and their local variable declarations.

@ To... phrases live here:

=
void Routines::prepare_for_requests(id_body *idb) {
	idb->compilation_data.requests_package = Hierarchy::package(idb->compilation_data.owning_module, PHRASES_HAP);
}

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
stack_frame *currently_compiling_in_frame = NULL; /* the stack frame for this routine */
int currently_compiling_nnp = FALSE; /* is this a nonphrasal stack frame we made ourselves? */
inter_package *currently_compiling_inter_block = NULL; /* where Inter is being emitted to */
inter_name *currently_compiling_iname = NULL; /* routine we end up with */

@ So here is the general version, in which |phsf| may or may not be a
pre-existing stack frame:

=
packaging_state Routines::begin_framed(inter_name *iname, stack_frame *phsf) {
	if (iname == NULL) internal_error("no iname for routine");
	currently_compiling_iname = iname;

	@<Prepare a suitable stack frame@>;

	Frames::Blocks::begin_code_blocks();

	packaging_state save = Emit::unused_packaging_state();
	currently_compiling_inter_block = Produce::block(Emit::tree(), &save, iname);
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
	if ((Frames::uses_local_block_values(currently_compiling_in_frame)) ||
		(currently_compiling_in_frame->no_formal_parameters_needed > 0))
		kernel_name = Produce::kernel(Emit::tree(), public_name);

	int needed = LocalVariables::count(currently_compiling_in_frame);
	if (kernel_name) needed++;
	if (TargetVMs::allow_this_many_locals(Task::vm(), needed) == FALSE)
		@<Issue a problem for too many locals@>;

	LocalVariables::declare(currently_compiling_in_frame, FALSE);
	Produce::end_block(Emit::tree());

	Emit::routine(kernel_name?kernel_name:public_name,
		R_kind, currently_compiling_inter_block);

	if (kernel_name) @<Compile an outer shell routine with the public-facing name@>;

	Frames::Blocks::end_code_blocks();
	if (currently_compiling_nnp) Frames::remove_nonphrase_stack_frame();
	Frames::remove_current();
	Produce::end_main_block(Emit::tree(), save);
}

@<Compile an outer shell routine with the public-facing name@> =
	int returns_block_value =
		Kinds::Behaviour::uses_pointer_values(currently_compiling_in_frame->kind_returned);

	inter_package *block_package = Produce::block(Emit::tree(), NULL, public_name);
	inter_symbol *I7RBLK_symbol = NULL;
	@<Compile I6 locals for the outer shell@>;
	@<Compile some setup code to make ready for the kernel@>;
	@<Compile a call to the kernel@>;
	@<Compile some teardown code now that the kernel has finished@>;
	@<Compile a return from the outer shell@>;
	Produce::end_block(Emit::tree());
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
	Frames::compile_lbv_setup(currently_compiling_in_frame);

	for (int i=0; i<currently_compiling_in_frame->no_formal_parameters_needed; i++) {
		nonlocal_variable *nlv = RTTemporaryVariables::formal_parameter(i);
		Produce::push(Emit::tree(), RTVariables::iname(nlv));
	}

@<Compile a call to the kernel@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
	Produce::ref_symbol(Emit::tree(), K_value, I7RBLK_symbol);
	if (returns_block_value) {
		inter_name *iname = Hierarchy::find(BLKVALUECOPY_HL);
		Produce::inv_call_iname(Emit::tree(), iname);
		Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_number,I7RBLK_symbol);
	}

	Produce::inv_call_iname(Emit::tree(), kernel_name);
	Produce::down(Emit::tree());
	LocalVariables::emit_parameter_list(currently_compiling_in_frame);
	Produce::up(Emit::tree());

	if (returns_block_value) {
		Produce::up(Emit::tree());
	}
	Produce::up(Emit::tree());

@ Here we deallocate all the memory allocated earlier.

@<Compile some teardown code now that the kernel has finished@> =
	for (int i=currently_compiling_in_frame->no_formal_parameters_needed-1; i>=0; i--) {
		nonlocal_variable *nlv = RTTemporaryVariables::formal_parameter(i);
		Produce::pull(Emit::tree(), RTVariables::iname(nlv));
	}
	Frames::compile_lbv_teardown(currently_compiling_in_frame);

@<Compile a return from the outer shell@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, I7RBLK_symbol);
	Produce::up(Emit::tree());

@<Issue a problem for too many locals@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TooManyLocals),
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
