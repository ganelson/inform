[CodeBlocks::] Code Blocks.

Blocks of code are used to give conditionals and loops greater
scope, as in more traditional programming languages.

@ During code compilation, we must keep track of statement blocks: those
forming the body of "if", "while" or "repeat". The phrase as a whole does
not count as a block as such, unlike in C. In the following example, |S|
is the "scope level", i.e., the number of blocks currently open:
= (text as Inform 7)
To show what this means:
    if the player is in the Arboretum:                                   [S = 0]
        say "You are surrounded by trees.";                              [S = 1]
        repeat with the menace running through trees in the Arboretum:   [S = 1]
            say "[The menace] crowds in.";                               [S = 2]
    otherwise:                                                           [S = 0]
    	say "This is a thankfully open space."                           [S = 1]
=
In principle, this information belongs to the current stack frame, since
it's within the context of a stack frame that code is compiled. But it
would be wasteful to store arrays for statement blocks inside every stack
frame structure, because in practice we only compile within one stack
frame at a time, and we finish each before beginning the next. So we
store the block stack in the only instance of a private structure.

@d MAX_BLOCK_NESTING 50 /* largest possible value of S at any position */

=
typedef struct block_stack {
	int pb_sp; /* stack pointer for the block stack which follows: */
	struct phrase_block pb_stack[MAX_BLOCK_NESTING+1];
} block_stack;

typedef struct phrase_block {
	struct control_structure_phrase *from_structure; /* e.g., "if" or "while" */
	struct parse_node *block_location; /* where block begins */
	struct parse_node *switch_val; /* for a switch statement */
	struct inter_schema *tail_schema; /* code to add when the block closes */
	struct csi_state compilation_state; /* details needed to compile that code */
	int label_following; /* or -1 if none is used */
} phrase_block;

@h Pushing, popping.
We need to keep track of two positions on the stack: the top (filled) entry,
and, sometimes, the one above it.

=
block_stack current_block_stack;
phrase_block *block_being_compiled = NULL; /* the one being compiled, if any */
phrase_block *block_being_opened = NULL; /* the one about to open, if any */

@ We need to be careful changing any of these without keeping the others in
line, so the only code allowed to change them is here:

=
void CodeBlocks::empty_stack(void) {
	current_block_stack.pb_sp = 0;
	block_being_compiled = NULL;
	block_being_opened = NULL;
}

@ Pushing happens in two stages. First we make a pointer to what will be, but
is not yet, the top of the stack:

=
void CodeBlocks::prepush_stack(void) {
	block_being_opened = &(current_block_stack.pb_stack[current_block_stack.pb_sp]);
}

@ And then we actually increment the stack pointer:

=
void CodeBlocks::push_stack(void) {
	current_block_stack.pb_sp++;
	block_being_compiled = block_being_opened;
	block_being_opened = NULL;
}

@ Popping is easier:

=
void CodeBlocks::pop_stack(void) {
	current_block_stack.pb_sp--;
	if (current_block_stack.pb_sp > 0)
		block_being_compiled = &(current_block_stack.pb_stack[current_block_stack.pb_sp - 1]);
	else
		block_being_compiled = NULL;
	block_being_opened = NULL; /* which should be true anyway */
}

@h Activation and deactivation.
If a phrase needs code blocks, Inform should call this when compilation
begins:

=
void CodeBlocks::begin_code_blocks(void) {
	if (Frames::current_stack_frame() == NULL)
		internal_error("tried to use blocks outside stack frame");
	if (block_being_compiled)
		internal_error("tried to begin block stack already in use");
	CodeBlocks::empty_stack(); /* which it should be anyway */
	LOGIF(LOCAL_VARIABLES, "Block stack now active\n");
}

@ And this when it ends. The stack should in fact be empty, but just in
case we are recovering from some kind of problem, we'll empty anything
somehow left on it.

=
void CodeBlocks::end_code_blocks(void) {
	while (block_being_compiled) {
		current_sentence = block_being_compiled->block_location;
		CodeBlocks::pop_stack();
	}
	block_being_compiled = NULL;
	LOGIF(LOCAL_VARIABLES, "Block stack now inactive\n");
}

@h The life of a block.
So now let's follow what happens when a block is being compiled. Suppose
we have:

>> repeat through the Table of Odds:

When Inform begins to compile this invocation, it observes that the phrase
being invoked is followed by a code block, and calls the following routine
to warn us. (That doesn't mean the block is opening yet: the setup code
for the loop hasn't been compiled yet.)

=
void CodeBlocks::beginning_block_phrase(control_structure_phrase *csp) {
	if (current_block_stack.pb_sp == MAX_BLOCK_NESTING) {
		if (problem_count == 0) internal_error("block stack overflow");
		CodeBlocks::pop_stack();
	}
	CodeBlocks::prepush_stack();
	if (block_being_opened) @<Construct the next phrase block@>;
}

@ In the case of a repeat through a Table, we need to create two loop
variables. In addition to those, the loop we're compiling will inevitably
change the two row selection variables (always called |ct_0| and |ct_1|),
so we need to protect their contents; we push them onto the stack before
the loop begins, and pull them again when it finishes.

@<Construct the next phrase block@> =
	block_being_opened->switch_val = NULL;
	block_being_opened->tail_schema = NULL;
	block_being_opened->block_location = current_sentence;
	block_being_opened->from_structure = csp;
	block_being_opened->label_following = -1;

@ Slightly later on, we know these:

=
int CodeBlocks::attach_back_schema(inter_schema *I, csi_state CSIS) {
	if (block_being_opened) {
		block_being_opened->switch_val = NULL;
		if (Invocations::get_no_tokens(CSIS.inv) > 0)
			block_being_opened->switch_val = CSIS.tokens->token_vals[0];
		block_being_opened->tail_schema = I;
		block_being_opened->compilation_state = CSIS;
		return TRUE;
	}
	return FALSE;
}

@ At this next stage, the preliminary code for the loop (if it's a loop)
has been compiled, and we're ready to open the actual block:

=
void CodeBlocks::open_code_block(void) {
	if (current_block_stack.pb_sp != MAX_BLOCK_NESTING) CodeBlocks::push_stack();
	LOGIF(LOCAL_VARIABLES, "Start of block level %d\n", current_block_stack.pb_sp);
}

@ A division in a code block occurs at the "otherwise" point of an "if",
for example, but also for cases in a switch-style "if", so there can be
many of them.

=
void CodeBlocks::divide_code_block(void) {
	if (block_being_compiled == NULL) return; /* for problem recovery only */
	LOGIF(LOCAL_VARIABLES, "Division in block level %d\n", current_block_stack.pb_sp);
	LocalVariableSlates::end_scope(current_block_stack.pb_sp);
}

@ Whatever we pushed earlier, we now pull:

=
void CodeBlocks::close_code_block(void) {
	if (block_being_compiled == NULL) return; /* for problem recovery only */
	if (block_being_compiled->label_following >= 0) {
		TEMPORARY_TEXT(TL)
		WRITE_TO(TL, ".loop_break_%d", block_being_compiled->label_following);
		EmitCode::place_label(EmitCode::reserve_label(TL));
		DISCARD_TEXT(TL)
	}

	LOGIF(LOCAL_VARIABLES, "End of block level %d\n", current_block_stack.pb_sp);
	LocalVariableSlates::end_scope(current_block_stack.pb_sp);
	CSIInline::csi_inline_back(block_being_compiled->tail_schema,
		&(block_being_compiled->compilation_state));
	CodeBlocks::pop_stack();
}

@h Bodies.
Are we in the body of a loop, perhaps indirectly?

=
int CodeBlocks::inside_a_loop_body(void) {
	int i;
	for (i = current_block_stack.pb_sp-1; i >= 0; i--)
		if (ControlStructures::is_a_loop(current_block_stack.pb_stack[i].from_structure))
			return TRUE;
	return FALSE;
}

@ What can we find about the block we are most immediately in? Note that
if there is no current block stack, we behave as if the block stack were
empty, but (as long as nobody tries to open or close any blocks) no
internal errors are issued. This allows the typechecker to run even when
there is no current block stack, which is important when typechecking an
expression whose evaluation requires the use of a phrase.

=
int CodeBlocks::current_block_level(void) {
	return current_block_stack.pb_sp;
}

inchar32_t *CodeBlocks::name_of_current_block(void) {
	if (block_being_compiled == NULL) return NULL;
	return ControlStructures::incipit(block_being_compiled->from_structure);
}

parse_node *CodeBlocks::start_of_current_block(void) {
	if (block_being_compiled == NULL) return NULL;
	return block_being_compiled->block_location;
}

parse_node *CodeBlocks::switch_value(void) {
	if (block_being_compiled == NULL) return NULL;
	return block_being_compiled->switch_val;
}

@h Breakage.
We break out of the current loop by jumping to a label placed just after the loop ends.

=
int unique_breakage_count = 0;
void CodeBlocks::emit_break(void) {
	for (int i = current_block_stack.pb_sp-1; i >= 0; i--)
		if (ControlStructures::permits_break(current_block_stack.pb_stack[i].from_structure)) {
			if (current_block_stack.pb_stack[i].label_following == -1)
				current_block_stack.pb_stack[i].label_following =
					unique_breakage_count++;
			EmitCode::inv(JUMP_BIP);
			EmitCode::down();
				TEMPORARY_TEXT(TL)
				WRITE_TO(TL, ".loop_break_%d", current_block_stack.pb_stack[i].label_following);
				EmitCode::lab(EmitCode::reserve_label(TL));
				DISCARD_TEXT(TL)
			EmitCode::up();
			return;
		}
	internal_error("not inside a loop block");
}

@h Blocks and scope.
When "let" creates something, this is called:

=
void CodeBlocks::set_scope_to_current_block(local_variable *lvar) {
	if (Frames::current_stack_frame())
		LocalVariableSlates::set_scope_to(lvar,
			current_block_stack.pb_sp);
}

@ But when loops create something, this is called instead, because the loop
counter exists in one scope level inside the one holding the loop header
phrase:

=
void CodeBlocks::set_scope_to_block_about_to_open(local_variable *lvar) {
	if (Frames::current_stack_frame())
		LocalVariableSlates::set_scope_to(lvar,
			current_block_stack.pb_sp + 1);
}
