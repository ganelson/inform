[Frames::] Stack Frames.

When Inform compiles imperative code, it does so in the context of a "stack frame".

@h Introduction.
The term "stack frame" is traditional in computer science. The idea is that
there is a stack holding temporary data needed by the functions currently
running. Each function, as it begins, claims a "frame" of memory on the stack,
thus pushing the stack higher; when it ends, the memory in that frame is
given up. It can thus be used only for temporary data.

Our object code, Inter, is designed for use with virtual machines on which the
call stack is not directly addressable, so the term "stack frame" here is used
a little loosely. What we mean is: the collection of everything that is distinctive
about the function currently being compiled. In particular:
(*) its local variables;
(*) what shared variables it can see;
(*) what interpretations to place on the kind variables |A| to |Z|, if any;
(*) what kind of value we should be returning, if anything.

@ Code can only be compiled "inside" a stack frame, and at any given time
(when code is being compiled, anyway) there is a "current" frame.

=
stack_frame *current_frame = NULL;

stack_frame *Frames::current_stack_frame(void) {
	return current_frame;
}

@ This must be imposed and removed manually:

=
void Frames::make_current(stack_frame *frame) {
	if (frame == NULL) internal_error("can't select null stack frame");
	current_frame = frame;
}

void Frames::remove_current(void) {
	current_frame = NULL;
}

@ There are three ways to get stack frames. First, every phrase or rule has
one of its own. Second, though, we will also need a stack frame in order to
compile the many functions which aren't directly corresponding to phrases or
rules at all. Such a frame is called "nonphrasal":

=
int nonphrasal_stack_frame_is_current = FALSE;
stack_frame nonphrasal_stack_frame;

stack_frame *Frames::new_nonphrasal(void) {
	if (nonphrasal_stack_frame_is_current)
		internal_error("can't nest nonphrasal stack frames");
	nonphrasal_stack_frame = Frames::new();
	nonphrasal_stack_frame_is_current = TRUE;
	Frames::make_current(&nonphrasal_stack_frame);
	return &nonphrasal_stack_frame;
}

void Frames::remove_nonphrase_stack_frame(void) {
	nonphrasal_stack_frame = Frames::new(); /* to prevent accidental lucky misuse */
	nonphrasal_stack_frame_is_current = FALSE;
	Frames::remove_current();
}

@ //stack_frame// is a small and potentially throwaway structure, and can
sometimes exist only fleetingly in the compiler. If we want to preserve it,
or take a snapshot of its current state, we need to make a "boxed" copy, and
this is the third sort of stack frame which exists.

The following does so. //stack_frame_box// objects provide a convenient permanent
place in memory to stash these; pointers to them otherwise don't exist.

=
typedef struct stack_frame_box {
	struct stack_frame boxed_phsf;
	CLASS_DEFINITION
} stack_frame_box;

stack_frame *Frames::boxed_frame(stack_frame *old_frame) {
	if (old_frame == NULL) return NULL;
	stack_frame_box *box = CREATE(stack_frame_box);
	stack_frame *new_frame = &(box->boxed_phsf);
	*new_frame = *old_frame;
	LocalVariableSlates::deep_copy(&(new_frame->local_variables),
		&(old_frame->local_variables));
	return new_frame;
}

@h Creation.

=
typedef struct stack_frame {
	struct locals_slate local_variables; /* those in scope here */
	struct shared_variable_access_list *shared_variables; /* those in scope here */
	struct linked_list *local_block_values; /* of |local_block_value| */
	int no_formal_parameters_needed; /* usually 0, unless there are ambiguities */

	struct kind *kind_returned; /* or |NULL| for no return value */
	struct kind **local_kind_variables; /* points to an array indexed 1 to 26 */

	int determines_past_conditions; /* or rather, in the present, but for future use */
} stack_frame;

stack_frame Frames::new(void) {
	stack_frame frame;
	frame.local_variables = LocalVariableSlates::new();
	frame.local_kind_variables = NULL;
	frame.shared_variables = NULL;
	frame.determines_past_conditions = FALSE;
	frame.local_block_values = NEW_LINKED_LIST(local_block_value);
	frame.kind_returned = NULL;
	frame.no_formal_parameters_needed = 0;
	return frame;
}

@h Kinds.
The kind of value we expect to return from within this stack frame, if any.

=
void Frames::set_kind_returned(stack_frame *frame, kind *K) {
	frame->kind_returned = K;
}

kind *Frames::get_kind_returned(void) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL) return NULL;
	return frame->kind_returned;
}

@ And the values of the kind variables A to Z:

@d KIND_VARIABLE_FROM_CONTEXT Frames::get_kind_variable

=
void Frames::set_kind_variables(stack_frame *frame, kind **vars) {
	frame->local_kind_variables = vars;
}

kind *Frames::get_kind_variable(int N) {
	stack_frame *frame = Frames::current_stack_frame();
	if ((frame) && (frame->local_kind_variables))
		return frame->local_kind_variables[N];
	return NULL;
}

kind **Frames::temporarily_set_kvs(kind **vars) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL) return NULL;
	kind **prev = frame->local_kind_variables;
	frame->local_kind_variables = vars;
	return prev;
}

@ The "deduced kind" is what the kind of the code in this stack frame would
be, if it were seen as a function from its parameter variables to its return value.

=
kind *Frames::deduced_function_kind(stack_frame *frame) {
	int pc = 0;
	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
		if (LocalVariables::is_parameter(lvar))
			pc++;
	kind *K_array[128];
	pc = 0;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
		if (LocalVariables::is_parameter(lvar))
			if (pc < 128) {
				kind *OK = lvar->current_usage.kind_as_declared;
				if ((OK == NULL) || (OK == K_nil)) OK = K_number;
				K_array[pc++] = OK;
			}
	return Kinds::function_kind(pc, K_array, frame->kind_returned);
}

@h Shared variables.
See //assertions: Shared Variables// for more on this.

=
void Frames::set_shared_variable_access_list(stack_frame *frame,
	shared_variable_access_list *access) {
	frame->shared_variables = access;
}

shared_variable_access_list *Frames::get_shared_variable_access_list(void) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame) return frame->shared_variables;
	return NULL;
}

@h Past tense.
It turns out to be convenient to remember whether the current function makes
any reference to the past, which we do here:

=
void Frames::determines_the_past(void) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL) internal_error(
		"tried to determine past where no stack frame exists");
	frame->determines_past_conditions = TRUE;
	LOGIF(LOCAL_VARIABLES, "Stack frame determines past\n");
}

int Frames::used_for_past_tense(void) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL) return FALSE;
	if (frame->determines_past_conditions) return TRUE;
	return FALSE;
}

@h Formal parameters.
Some stack frames need access to additional Inter function parameters to handle
runtime invocation ambiguities, and this is how they're requested:

=
void Frames::need_at_least_this_many_formals(int N) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL)
		internal_error("requested formal parameters outside all stack frames");
	if (N > frame->no_formal_parameters_needed)
		frame->no_formal_parameters_needed = N;
}

@h It.
In some stack frames, the pronoun "it" (perhaps inflected) is allowed to stand
for the first call parameter to the function being compiled; and in others not.

=
local_variable *Frames::enable_it(stack_frame *frame, wording W, kind *K) {
	if (frame == NULL) internal_error("no stack frame exists");
	frame->local_variables.it_variable_exists = TRUE;
	return LocalVariables::new_call_parameter(frame, W, K);
}

@ If so, sometimes "its", "his", "her" or "their" are allowed too, but sometimes
not. 

=
int Frames::is_its_enabled(stack_frame *frame) {
	if (frame) return frame->local_variables.its_form_allowed;
	return FALSE;
}

void Frames::enable_its(stack_frame *frame) {
	if (frame == NULL) internal_error("no stack frame exists");
	frame->local_variables.its_form_allowed = TRUE;
}

@ In addition, a special name can optionally be given to the "it". This is only
likely to be useful if the first call parameter is nameless -- but that does
sometimes happen.

=
void Frames::alias_it(stack_frame *frame, wording W) {
	if (frame == NULL) internal_error("no stack frame exists");
	frame->local_variables.it_pseudonym = W;
}

@h Local block values.
Simple data at runtime, such as values of |K_number| or |K_truth_state|, occupy
a single Inter word. More involved data, such as values of |K_text| or
|K_stored_action|, cannot. Those are called "block values", because they occupy
entire multiple-word blocks of memory to store.

So when such data must be stored in a local variable, or some other memory location,
we will store the data itself if the kind is sufficiently simple, but a pointer
to an appropriate block of memory if not.

This is a particular issue for functions whose local variables need to have
block-value kinds, because that means the function must allocate suitable memory
when called and deallocate it on exit. Each stack frame must therefore track
what local block values it will need:

=
local_block_value *Frames::allocate_local_block_value(kind *K) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL)
		internal_error("tried to allocate block kind outside all stack frames");
	local_block_value *last =
		LAST_IN_LINKED_LIST(local_block_value, frame->local_block_values);
	local_block_value *bv = Frames::new_lbv(K, last);
	ADD_TO_LINKED_LIST(bv, local_block_value, frame->local_block_values);
	return bv;
}

int Frames::uses_local_block_values(stack_frame *frame) {
	if ((frame) && (LinkedLists::len(frame->local_block_values) > 0)) return TRUE;
	return FALSE;
}

@ Where should temporary block values live, during the perhaps very brief
period while a function is running? We can't put it onto the virtual machine's
call stack, because it doesn't live in the VM's memory at all, and therefore
cannot be written or read. We could put it on the heap, but then allocation
and deallocation would be expensive.

Instead we put just the small blocks on a stack in memory: it fills downwards,
and at runtime the Inter identifier |I7SFRAME| points to the current and therefore
bottom-most frame on this stack. So, for example, if the current stack frame has
just two local block values, a |K_text| and a |K_stored_action|, then we would have:

= (text)
                 ...free space...
    I7SFRAME --> 0      } small block 0 (for a K_text),               offset index 0
                 1      }        may then --> more data on the heap   offset past  2

                 2      } small block 1 (for a K_stored_action)       offset index 2
                 3      }        similarly --> more data on the heap  offset past  8
                 4      }
                 5      }
                 6      }
                 7      }
                 ...frames belonging to functions calling this one...
=
These small blocks may well point to larger blocks elsewhere on the heap (for
example, to accommodate the actual contents of a text, if they are non-constant).
But small blocks have the virtue of being of a size which is fixed for each
kind, and we can allocate space for them essentially immediately just by raising
the |I7SFRAME| sufficiently.

Each local block value is kept track of with one of these:
=
typedef struct local_block_value {
	struct heap_allocation allocation; /* needed to compile a function call returning a pointer to a new value */
	struct i6_schema *to_refer; /* a schema to access this data */
	int offset_index; /* start of small block wrt current stack frame */
	int offset_past; /* just past the end of the small block */
	CLASS_DEFINITION
} local_block_value;

@ Note that the schemas below for calculating offset positions from |I7SFRAME|
will end up only as a single addition at runtime, because the multiplication of
|WORDSIZE| by a literal positive integer will be constant-folded in code
generation.

=
local_block_value *Frames::new_lbv(kind *K, local_block_value *last) {
	local_block_value *bv = CREATE(local_block_value);
	if (last == NULL) bv->offset_index = 0;
	else bv->offset_index = last->offset_past;
	bv->allocation = TheHeap::make_allocation(K, 0, bv->offset_index);
	bv->offset_past = bv->offset_index + Kinds::Behaviour::get_small_block_size(K);
	TEMPORARY_TEXT(ref)
	if (bv->offset_index == 0) {
		WRITE_TO(ref, "I7SFRAME");
	} else if (bv->offset_index == 1) {
		WRITE_TO(ref, "(I7SFRAME+WORDSIZE)");
	} else {
		WRITE_TO(ref, "(I7SFRAME+WORDSIZE**%d)", bv->offset_index);
	}
	bv->to_refer = Calculus::Schemas::new("%S", ref);
	DISCARD_TEXT(ref)
	return bv;
}

@ The following code is executed when the stack frame is entered: we push the
old value of |I7SFRAME_HL| to the call stack to save it; then call a function
in //BasicInformKit: BlockValues// to make space for the small
blocks we need, which will move |I7SFRAME_HL| downwards by |size| words; and
then initialise the small blocks one by one to default values.

=
void Frames::compile_lbv_setup(stack_frame *frame) {
	EmitCode::push(Hierarchy::find(I7SFRAME_HL));

	int size = 0;
	local_block_value *lbv;
	LOOP_OVER_LINKED_LIST(lbv, local_block_value, frame->local_block_values) {
		if (lbv->offset_past > size) size = lbv->offset_past;
	}
	EmitCode::call(Hierarchy::find(STACKFRAMECREATE_HL));
	EmitCode::down();
		EmitCode::val_number((inter_ti) size);
	EmitCode::up();

	LOOP_OVER_LINKED_LIST(lbv, local_block_value, frame->local_block_values)
		TheHeap::emit_allocation(lbv->allocation);
}

@ Symmetrically, this teardown code is executed when the stack frame is exited.
We deallocate each small block, and then restore |I7SFRAME_HL| by pulling the
value we pushed earlier.

=
void Frames::compile_lbv_teardown(stack_frame *frame) {
	local_block_value *lbv;
	LOOP_OVER_LINKED_LIST(lbv, local_block_value, frame->local_block_values) {
		inter_name *iname = Hierarchy::find(BLKVALUEFREEONSTACK_HL);
		EmitCode::call(iname);
		EmitCode::down();
			EmitCode::val_number((inter_ti) lbv->offset_index);
		EmitCode::up();
	}

	EmitCode::pull(Hierarchy::find(I7SFRAME_HL));
}

@ The net effect is that when the rest of Inform needs to compile the address
of a newly-allocated value of a block kind |K|, it can simply call the
following, without having to worry about how any of this works:

=
void Frames::emit_new_local_value(kind *K) {
	local_block_value *bv = Frames::allocate_local_block_value(K);
	CompileSchemas::from_terms_in_val_context(bv->to_refer, NULL, NULL);
}

@h Logging.

=
void Frames::log(stack_frame *frame) {
	if (frame == NULL) { LOG("<null stack frame>\n"); return; }
	LOG("Stack frame at %08x: it:%s, dpc:%s\n",
		(unsigned int)(pointer_sized_int)frame,
		(frame->local_variables.it_variable_exists)?"yes":"no",
		(frame->determines_past_conditions)?"yes":"no");
	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame) {
		switch (lvar->lv_purpose) {
			case LET_VALUE_LV: LOG("Let/loop value: "); break;
			case TOKEN_CALL_PARAMETER_LV: LOG("Call value: "); break;
			case INTERNAL_USE_LV: LOG("Internal use: "); break;
			default: LOG("Other: "); break;
		}
		LOG("%~L: ", lvar);
		LocalVariables::log(lvar); LOG("\n");
	}
}
