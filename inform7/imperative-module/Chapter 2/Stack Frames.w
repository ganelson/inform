[Frames::] Stack Frames.

When Inform compiles phrase invocations, or implied forms of these
such as text substitutions, it does so in the context of a "stack frame".
This provides for local "let" values, manages loop blocks, and in general
looks after any information shared between a whole sequence of invocations.

@ As we've seen, each phrase has its own stack frame, which is a structure
inside the |phrase| structure. But they can also exist independently, for
other occasions when compilation occurs. They keep track of which variables
are visible, and also of the current values of the kind variables A to Z,
if any, and the consequent return kind.

=
typedef struct ph_stack_frame {
	struct locals_slate local_value_variables; /* those in scope here */
	struct stacked_variable_access_list *local_stvol; /* those in scope here */
	struct pointer_allocation *allocated_pointers;
	int no_formal_parameters_needed; /* usually 0, unless there are ambiguities */

	struct kind *kind_returned; /* or |NULL| for no return value */
	struct kind **local_kind_variables; /* points to an array indexed 1 to 26 */

	int determines_past_conditions; /* or rather, in the present, but for future use */
} ph_stack_frame;

@ Stack frames are often made fleetingly and then thrown away, but sometimes
we need to make one and keep it around. For this, we have the ability to box
up a stack frame: by allocating an instance of the following structure, we
can have a permanently valid pointer to a unique new PHSF.

=
typedef struct ph_stack_frame_box {
	struct ph_stack_frame boxed_phsf;
	CLASS_DEFINITION
} ph_stack_frame_box;

@ Within each stack frame is a linked list of notes about pointer values
for which memory allocation and deallocation will be needed:

=
typedef struct pointer_allocation {
	struct heap_allocation allocation; /* needed to compile a function call returning a pointer to a new value */
	struct text_stream *local_reference_code; /* an I6 lvalue for the storage holding the pointer */
	struct text_stream *escaped_local_reference_code; /* the same, but suitable for schema use */
	struct text_stream *schema_for_promotion; /* an I6 schema for promoting this value */
	int offset_index; /* start of small block wrt current stack frame */
	int offset_past; /* just past the end of the small block */
	struct pointer_allocation *next_in_frame; /* within the linked list */
	CLASS_DEFINITION
} pointer_allocation;

@h Creation.
A completely black stack frame...

=
ph_stack_frame Frames::new(void) {
	ph_stack_frame phsf;
	phsf.local_value_variables = LocalVariables::blank_slate();
	phsf.local_kind_variables = NULL;
	phsf.local_stvol = NULL;
	phsf.determines_past_conditions = FALSE;
	phsf.allocated_pointers = NULL;
	phsf.kind_returned = NULL;
	phsf.no_formal_parameters_needed = 0;
	return phsf;
}

@ ...can be useful all by itself. The following is used to make a temporary
stack frame suitable for "nonphrasal" compilation, that is, for when Inform
wants to compile an I6 routine for some purpose other than to define a phrase.

=
int nonphrasal_stack_frame_is_current = FALSE;
ph_stack_frame nonphrasal_stack_frame;

ph_stack_frame *Frames::new_nonphrasal(void) {
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

@ Another way to get hold of a PHSF is to request a boxed one, as noted above:

=
ph_stack_frame *Frames::boxed_frame(ph_stack_frame *phsf) {
	if (phsf == NULL) return NULL;
	ph_stack_frame_box *phsfb;
	phsfb = CREATE(ph_stack_frame_box);
	phsfb->boxed_phsf = *phsf;
	LocalVariables::deep_copy_locals_slate(&(phsfb->boxed_phsf.local_value_variables),
		&(phsf->local_value_variables));
	return &(phsfb->boxed_phsf);
}

@h The current stack frame.
At any given time, a single stack frame is valid for local variable names
and phrase option names used as conditions. It will be the nonphrasal one
if that's active, and otherwise must be set as needed.

=
ph_stack_frame *current_frame = NULL;

ph_stack_frame *Frames::current_stack_frame(void) {
	return current_frame;
}

void Frames::make_current(ph_stack_frame *phsf) {
	if (phsf == NULL) internal_error("can't select null stack frame");
	current_frame = phsf;
}

void Frames::remove_current(void) {
	current_frame = NULL;
}

@h Kinds.
The kind of value we expect to return from within this stack frame, if any.

=
void Frames::set_kind_returned(ph_stack_frame *phsf, kind *K) {
	phsf->kind_returned = K;
}

kind *Frames::get_kind_returned(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return NULL;
	return phsf->kind_returned;
}

@ And the values of the kind variables A to Z:

@d KIND_VARIABLE_FROM_CONTEXT Frames::get_kind_variable

=
void Frames::set_kind_variables(ph_stack_frame *phsf, kind **vars) {
	phsf->local_kind_variables = vars;
}

kind *Frames::get_kind_variable(int N) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if ((phsf) && (phsf->local_kind_variables))
		return phsf->local_kind_variables[N];
	return NULL;
}

kind **Frames::temporarily_set_kvs(kind **vars) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return NULL;
	kind **prev = phsf->local_kind_variables;
	phsf->local_kind_variables = vars;
	return prev;
}

@h Stacked variables.

=
void Frames::set_stvol(ph_stack_frame *phsf, stacked_variable_access_list *stvol) {
	phsf->local_stvol = stvol;
}

stacked_variable_access_list *Frames::get_stvol(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf) return phsf->local_stvol;
	return NULL;
}

@h Past tense.
All we do here is to make a note if anything compiled in this context makes
reference to the past.

=
void Frames::determines_the_past(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) internal_error(
		"tried to determine past where no stack frame exists");
	phsf->determines_past_conditions = TRUE;
	LOGIF(LOCAL_VARIABLES, "Stack frame determines past\n");
}

int Frames::used_for_past_tense(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return FALSE;
	if (phsf->determines_past_conditions) return TRUE;
	return FALSE;
}

@h Logging.

=
void Frames::log(ph_stack_frame *phsf) {
	if (phsf == NULL) { LOG("<null stack frame>\n"); return; }
	LOG("Stack frame at %08x: it:%s, dpc:%s\n",
		phsf,
		(phsf->local_value_variables.it_variable_exists)?"yes":"no",
		(phsf->determines_past_conditions)?"yes":"no");
	local_variable *lvar;
	LOOP_THROUGH_LOCALS_IN_FRAME(lvar, phsf) {
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

@h Formal parameter allocation.
Some stack frames need access to additional variables to handle run-time
invocation ambiguities, and this is how they're requested:

=
void Frames::need_at_least_this_many_formals(int N) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL)
		internal_error("requested formal parameters outside all stack frames");
	if (N > phsf->no_formal_parameters_needed)
		phsf->no_formal_parameters_needed = N;
}

@h Pointer value allocation.
Values such as lists, which have to stored in whole blocks rather than single
words of memory, are sometimes called pointer values because all we can
immediately handle is a pointer to the block. When these arise in the
compilation of a routine, we have to make a note of this, because special
code will be needed to allocate and deallocate the memory storing the block.
The following is the routine called to make this note.

=
pointer_allocation *Frames::add_allocation(kind *K, char *proto) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) {
		LOG("Tried to allocate: %u\n", K);
		internal_error("tried to allocate block kind outside all stack frames");
	}
	pointer_allocation *pall = CREATE(pointer_allocation);
	pall->next_in_frame = phsf->allocated_pointers;
	phsf->allocated_pointers = pall;
	if (pall->next_in_frame == NULL) pall->offset_index = 0;
	else pall->offset_index = pall->next_in_frame->offset_past;
	pall->offset_past = pall->offset_index + Kinds::Behaviour::get_small_block_size(K);

	@<Work out heap allocation code for this pointer value@>;
	@<Work out local reference code for this pointer value@>;
	@<Work out promotion schema for this pointer value@>;

	return pall;
}

void Frames::compile_allocation(OUTPUT_STREAM, kind *K) {
	pointer_allocation *pall = Frames::add_allocation(K, NULL);
	WRITE("%S", Frames::pall_get_local_reference(pall));
}

void Frames::emit_allocation(kind *K) {
	pointer_allocation *pall = Frames::add_allocation(K, NULL);
	i6_schema *all_sch = Calculus::Schemas::new("%S", pall->escaped_local_reference_code);
	EmitSchemas::emit_expand_from_terms(all_sch, NULL, NULL, FALSE);
}

@ The following works out a call to |BlkValueCreate| which will return a
default value of the given kind.

@<Work out heap allocation code for this pointer value@> =
	pall->allocation = RTKinds::make_heap_allocation(K, 0, pall->offset_index);

@ This is the storage used to hold the pointer. For each frame, we have
a subarray of short blocks, indexed by the offset.

@<Work out local reference code for this pointer value@> =
	pall->local_reference_code = Str::new();
	pall->escaped_local_reference_code = Str::new();
	if (pall->offset_index == 0) {
		WRITE_TO(pall->local_reference_code, "I7SFRAME");
		WRITE_TO(pall->escaped_local_reference_code, "I7SFRAME");
	} else if (pall->offset_index == 1) {
		WRITE_TO(pall->local_reference_code, "(I7SFRAME+WORDSIZE)");
		WRITE_TO(pall->escaped_local_reference_code, "(I7SFRAME+WORDSIZE)");
	} else {
		WRITE_TO(pall->local_reference_code, "(I7SFRAME+WORDSIZE*%d)", pall->offset_index);
		WRITE_TO(pall->escaped_local_reference_code, "(I7SFRAME+WORDSIZE**%d)", pall->offset_index);
	}

@<Work out promotion schema for this pointer value@> =
	pall->schema_for_promotion = Str::new();
	if (proto) {
		for (int i=0; proto[i]; i++) {
			if ((proto[i] == '*') && (proto[i+1] == '#') && (proto[i+2] == '#')) {
				WRITE_TO(pall->schema_for_promotion, "%S", pall->escaped_local_reference_code);
				i+=2;
				continue;
			}
			PUT_TO(pall->schema_for_promotion, proto[i]);
		}
	}

@ =
text_stream *Frames::pall_get_local_reference(pointer_allocation *pall) {
	return pall->local_reference_code;
}

text_stream *Frames::pall_get_expanded_schema(pointer_allocation *pall) {
	return pall->schema_for_promotion;
}
