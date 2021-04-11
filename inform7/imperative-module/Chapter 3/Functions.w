[Functions::] Functions.

To compile Inter functions.

@ The code in this section is used throughout the //imperative// and //runtime//
modules whenever an Inter function needs to be compiled. This will often not be
a function corresponding to a definition in the soruce text; more often, it will
be a support function needed to implement some feature at runtime.

However it happens, every function is compiled using code like so:
= (text as InC)
	inter_name *iname = /* work something out here */;
	packaging_state save = Functions::begin(iname);
	/* declare some call parameters */
	/* now compile the code in the function */
	Functions::end(save);
=
This will create a new stack frame for the function, which is usually what is
wanted. If we want to compile it using an existing frame |frame|, then instead
call |Functions::begin_framed(iname, frame)|, not |Functions::begin(iname)|;
and a third version, |Functions::begin_from_idb(iname, frame, idb)| exists
if we are compiling from an imperative definition |idb|.

There are nearly 100 examples of this simple API being used in Inform, so
it's not hard to find code to imitate if you want to compile a new function.

Note that only one function can be compiled at a time: //Functions::end//
must be called before //Functions::begin// (or similar) can be called again.

@ There aren't really three different methods, because:

=
packaging_state Functions::begin(inter_name *iname) {
	return Functions::begin_from_idb(iname, NULL, NULL);
}
packaging_state Functions::begin_framed(inter_name *iname, stack_frame *frame) {
	return Functions::begin_from_idb(iname, frame, NULL);
}

@ Between the beginning and the end, we need to keep track of:

=
typedef struct function_under_compilation {
	struct id_body *from_idb; /* if any -- many functions do not arise this way */
	struct stack_frame *function_stack_frame; /* the stack frame for this function */
	int currently_compiling_nnp; /* is this a nonphrasal stack frame we made ourselves? */
	struct inter_package *into_package; /* where Inter is being emitted to */
	struct inter_name *currently_compiling_iname; /* function we end up with */
	struct linked_list *label_namespaces; /* of |label_namespace| */
} function_under_compilation;

int function_compilation_is_happening_now = FALSE;
function_under_compilation current_function;

@ =
id_body *Functions::defn_being_compiled(void) {
	if (function_compilation_is_happening_now)
		return current_function.from_idb;
	return NULL;
}

parse_node *Functions::line_being_compiled(void) {
	if (function_compilation_is_happening_now)
		return current_sentence;
	return NULL;
}

linked_list *Functions::current_label_namespaces(void) {
	if (function_compilation_is_happening_now) {
		if (current_function.from_idb)
			return current_function.from_idb->compilation_data.label_namespaces;
		return current_function.label_namespaces;
	}
	return NULL;
}

@ If the |frame| argument is set, then we'll use that; otherwise we will
create a new nonphrasal stack frame.

=
packaging_state Functions::begin_from_idb(inter_name *iname, stack_frame *frame,
	id_body *idb) {
	if (iname == NULL) internal_error("no iname for function");
	if (function_compilation_is_happening_now)
		internal_error("functions cannot be compiled simultaneously");
	function_compilation_is_happening_now = TRUE;

	if (frame == NULL) {
		frame = Frames::new_nonphrasal();
		current_function.currently_compiling_nnp = TRUE;
	} else {
		current_function.currently_compiling_nnp = FALSE;
	}
	current_function.function_stack_frame = frame;
	packaging_state save = Emit::unused_packaging_state();
	current_function.into_package = Produce::block(Emit::tree(), &save, iname);
	current_function.currently_compiling_iname = iname;
	current_function.from_idb = idb;
	if (idb) {
		JumpLabels::restart_counters(idb);
		current_function.label_namespaces = NULL;
	} else {
		current_function.label_namespaces = NEW_LINKED_LIST(label_namespace);
	}
	Frames::make_current(frame);
	CodeBlocks::begin_code_blocks();
	LocalVariableSlates::declare_all(frame);
	return save;
}

@ The real work comes at the end. At this point, we have compiled the body of
the code into the Inter package created above, but it is not yet part of an
Inter function.

What we do with this depends on whether any block values were used in the
function, because it they were then we need to worry about memory allocation.
The following pseudocode gives the general idea. Suppose we want to create
a function called |public_name|. If no block values were needed, we do the
obvious thing:
= (text)
    public_name(t1, t2, ..., tn) {
        ... package code here ...
    }
=
But if block values are involved, we make two functions, a "shell" with the
outward-facing name, and a "kernel" which does the actual work. If we suppose
that the kernel returns an ordinary value, then this happens:
= (text)
    public_name(t1, t2, ..., tn) {
        ...allocate memory...
        RV = kernel_name(t1, t2, ..., tn)
        ...deallocate...
        return RV
    }
    kernel_name(I7RBLK, t1, t2, ..., tn) {
        ... package code here ...
    }
=
Since we do not support exceptions in the Inter VM, it follows that whatever
|kernel_name| does -- even if it fails in some way at runtime -- all
allocated memory will safely be deallocated.

A slight variation is needed if the kernel returns a block value, as follows:
= (text)
    public_name(t1, t2, ..., tn) {
        ...allocate memory...
        BlkValueCopy(BRV, kernel_name(t1, t2, ..., tn))
        ...deallocate...
        return BRV
    }
    kernel_name(BRV, t1, t2, ..., tn) {
        ... package code here ...
    }
=
Here |BRV| is a pointer to memory in which to write the return value: note that
we copy it before we deallocate any of the memory which was likely used to
generate it.

=
void Functions::end(packaging_state save) {
	if (function_compilation_is_happening_now == FALSE)
		internal_error("function compilation has not started, so cannot end");

	stack_frame *frame = current_function.function_stack_frame;
	inter_name *kernel_name = NULL;
	inter_name *public_name = current_function.currently_compiling_iname;
	if ((Frames::uses_local_block_values(frame)) ||
		(frame->no_formal_parameters_needed > 0))
		kernel_name = Produce::kernel(Emit::tree(), public_name);
	
	kind *F_kind = Frames::deduced_function_kind(frame);

	int needed = LocalVariableSlates::size(frame);
	if (kernel_name) needed++;
	if (TargetVMs::allow_this_many_locals(Task::vm(), needed) == FALSE)
		@<Issue a problem for too many locals@>;

	LocalVariableSlates::declare_all(frame);
	Produce::end_block(Emit::tree());

	Emit::function(kernel_name?kernel_name:public_name, F_kind, current_function.into_package);

	if (kernel_name) @<Compile an outer shell function with the public-facing name@>;

	CodeBlocks::end_code_blocks();
	if (current_function.currently_compiling_nnp) Frames::remove_nonphrase_stack_frame();
	Frames::remove_current();
	Produce::end_main_block(Emit::tree(), save);
	JumpLabels::compile_necessary_storage();

	function_compilation_is_happening_now = FALSE;
	current_function.currently_compiling_nnp = FALSE;
	current_function.function_stack_frame = NULL;
	current_function.into_package = NULL;
	current_function.currently_compiling_iname = NULL;
	current_function.from_idb = NULL;
}

@<Compile an outer shell function with the public-facing name@> =
	int returns_block_value =
		Kinds::Behaviour::uses_pointer_values(frame->kind_returned);

	inter_package *block_package = Produce::block(Emit::tree(), NULL, public_name);
	inter_symbol *rv_symbol = NULL;
	@<Compile I6 locals for the outer shell@>;
	@<Compile some setup code to make ready for the kernel@>;
	@<Compile a call to the kernel@>;
	@<Compile some teardown code now that the kernel has finished@>;
	@<Compile a return from the outer shell@>;
	Produce::end_block(Emit::tree());
	Emit::function(public_name, F_kind, block_package);

@ Suppose the function has to return a list. Then the function is compiled
with an extra first parameter (called |I7RBLK|), which is a pointer to the
block value in which to write the answer. After that come all of the call
parameters of the phrase (but none of the "let" or scratch-use locals). If,
on the other hand, the function returns a word value, |I7RBLK| is placed
after the call parameters, and is used only as a scratch variable.

@<Compile I6 locals for the outer shell@> =
	if (returns_block_value)
		rv_symbol = Emit::local(K_number, I"BRV", 0, I"block return value");
	LocalVariableSlates::declare_all_parameters(frame);
	if (!returns_block_value)
		rv_symbol = Emit::local(K_number, I"RV", 0, I"return value");

@ We allocate memory for each pointer value used in the stack frame:

@<Compile some setup code to make ready for the kernel@> =
	Frames::compile_lbv_setup(frame);

	for (int i=0; i<frame->no_formal_parameters_needed; i++) {
		nonlocal_variable *nlv = RTTemporaryVariables::formal_parameter(i);
		Produce::push(Emit::tree(), RTVariables::iname(nlv));
	}

@<Compile a call to the kernel@> =
	if (returns_block_value) {
		inter_name *iname = Hierarchy::find(BLKVALUECOPY_HL);
		Produce::inv_call_iname(Emit::tree(), iname);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_number, rv_symbol);
			Produce::inv_call_iname(Emit::tree(), kernel_name);
			Produce::down(Emit::tree());
				LocalVariableSlates::emit_all_parameters(frame);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, rv_symbol);
			Produce::inv_call_iname(Emit::tree(), kernel_name);
			Produce::down(Emit::tree());
				LocalVariableSlates::emit_all_parameters(frame);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}

@ Here we deallocate all the memory allocated earlier.

@<Compile some teardown code now that the kernel has finished@> =
	for (int i=frame->no_formal_parameters_needed-1; i>=0; i--) {
		nonlocal_variable *nlv = RTTemporaryVariables::formal_parameter(i);
		Produce::pull(Emit::tree(), RTVariables::iname(nlv));
	}
	Frames::compile_lbv_teardown(frame);

@<Compile a return from the outer shell@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, rv_symbol);
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
