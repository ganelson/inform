[LocalVariableSlates::] Local Variable Slates.

The collection of Inter locals belonging to a stack frame.

@h Four varieties.
Each stack frame has its own "slate" of local variables, and there are four
varieties of these. For example, in the definition "..." of:

>> To attract (ferrous item - a thing) with (magnet - a thing), uninsulated: ...

two locals are "ferrous item" and "magnet", of type |TOKEN_CALL_PARAMETER_LV|.
The presence of ", uninsulated" means that another local is "phrase options",
of type |OTHER_CALL_PARAMETER_LV|, because the bitmap of options chosen is
passed as an additional call parameter when the phrase is invoked.

Within the definition, we might have:

>> let Q be the electrical charge;
>> repeat with the item running through things: say "The needle flickers over [the item]."

Here "Q" and "item" are both |LET_VALUE_LV| variables, but whereas "Q" exists
all through the phrase, "item" exists only inside its own repeat loop: this
is called its block scope.

Finally, a handful of inline definitions of phrases create local variables which
have no Inform 7 names but are used instead to implement some low-level feature;
these are of the type |INTERNAL_USE_LV|.

@d TOKEN_CALL_PARAMETER_LV 1	/* values for the tokens of the phrase being invoked */
@d OTHER_CALL_PARAMETER_LV 2	/* other implied parameters passed during invocation: Inter-level only */
@d LET_VALUE_LV 3				/* variables created by "let", "while" or "repeat" */
@d INTERNAL_USE_LV 4			/* workspace needed by our compiled code: Inter-level only */

@h Like register allocation.
We must distinguish between two closely related things:

(1) Inform 7's local variables, which come in four varieties as above.
(2) Locals on the Inter virtual machine's stack frame.

During the time of its existence, each Inform 7 local is stored in a
corresponding Inter local, but this is a little like register allocation in
a conventional compiler. For example, consider this C code:
= (text as C)
	for (int i=0; i<10; i++) printf("%d... ", i);
	printf("A moment of suspense. ");
	for (int j=9; j>=0; j--) printf("%d! ", j);
=
A C compiler will allocate registers in the CPU to hold |i| and |j|, but it is
also likely to notice that |i| ceases to exist before |j| comes into being: and
therefore the same register can be used to hold both. It holds |i| for a while,
and then |j|; and there is a period in between when it is unused, and has no
meaningful contents.

Inside the Inter function we are compiling, Inter VM locals are like registers
in this analogy. Inform 7 source text like this:
= (text as Inform 7)
	repeat with the item running through things:
		say "The needle flickers over [the item]."
	repeat with the watcher running through people in the Laboratory:
		say "[The watcher] looks on anxiously."
=
Here there are two |LET_VALUE_LV| variables, "item" and "watcher", but "watcher"
does not come into being until after "item" has ceased to exist, and Inform
will compile both to use the same Inter local. Note that this causes it not
only to have a different name, but also a different kind: when it is being "item"
it stores a thing, and when it is "watcher" it stores a person. However, Inform
never re-uses an Inter local in a way which changes its purpose: so, once a
|LET_VALUE_LV|, always a |LET_VALUE_LV|. This is very slightly inefficient but
it results in much more legible output.

@ The //local_variable// objects in a locals slate correspond to the Inter
locals, and the |allocated| field is true if they are currently being used to
store an I7 local, or false if they are not (and are therefore free to be reused).

The |current_usage| field contains the I7 local it currently stores, and must
therefore be ignored if |allocated| is |FALSE|.

=
typedef struct local_variable {
	int allocated; /* in existence at this point in the routine? */
	int lv_purpose; /* one of the |*_LV| values above */
	int index_with_this_purpose; /* counting up from 0 within locals of same purpose */
	struct text_stream *identifier; /* for the Inter local */
	struct text_stream *comment_on_use; /* purely to make the output more legible */

	struct I7_local_variable current_usage; /* meaningful only if |allocated| */
	CLASS_DEFINITION
} local_variable;

typedef struct I7_local_variable {
	struct wording varname; /* name of local variable */
	int name_hash; /* hash code for this name */
	struct kind *kind_as_declared; /* data type for the contents */
	int block_scope; /* scope of a local - block depth */
	int free_at_end_of_scope; /* whether it holds temporary data on heap */
	int protected; /* from alteration using "let"? */
	int parsed_recently; /* name recognised since this was last wiped? */
} I7_local_variable;

@ =
void LocalVariableSlates::clear_I7_local(I7_local_variable *I7_local, wording W, kind *K) {
	if (Wordings::empty(W)) {
		I7_local->varname = EMPTY_WORDING;
		I7_local->name_hash = 0;
	} else {
		I7_local->varname = W;
		I7_local->name_hash = Lexicon::wording_hash(W);
	}
	I7_local->block_scope = 0; /* by default: universal scope throughout routine */
	I7_local->free_at_end_of_scope = FALSE;
	I7_local->kind_as_declared = K;
	I7_local->protected = TRUE;
	I7_local->parsed_recently = FALSE;
}

@ Default Inter identifier names are generated as follows. The result is that
a typical Inter function will have locals looking something like this:
= (text)
	t_0  t_1  phrase_options  tmp_0  tmp_1  tmp_2  ct_0  ct_1
=
where the defaults have been overridden for |phrase_options|, |ct_0| and |ct_1|,
but allowed to stand for the rest.

=
void LocalVariableSlates::name_lv(OUTPUT_STREAM, int purpose, int ix) {
	switch (purpose) {
		case TOKEN_CALL_PARAMETER_LV: WRITE("t"); break;
		case OTHER_CALL_PARAMETER_LV: WRITE("ti"); break;
		case LET_VALUE_LV: WRITE("tmp"); break;
		case INTERNAL_USE_LV: WRITE("misc"); break;
		default: internal_error("unknown local variable purpose");
	}
	WRITE("_%d", ix);
}

@h Slates.
Each stack frame has a //locals_slate// object, as follows, which is essentially
just a list of its Inter locals. Each Inter local belongs to exactly one slate.

=
typedef struct locals_slate {
	struct linked_list *local_variable_allocation; /* of |local_variable| */
	int it_variable_exists; /* it, he, she, or they, used for adjective definitions */
	int its_form_allowed; /* its, his, her or their, ditto */
	struct wording it_pseudonym; /* a further variation on the same variable */
} locals_slate;

@ As usual, we make some convenient loop macros for looking through these:

@d LOOP_OVER_LOCALS(lvar, slate)
	LOOP_OVER_LINKED_LIST(lvar, local_variable, slate->local_variable_allocation)

@d LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
	LOOP_OVER_LOCALS(lvar, (&(frame->local_variables)))

=
int LocalVariableSlates::size(stack_frame *frame) {
	int ct = 0;
	if (frame) {
		local_variable *lvar;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame) ct++;
	}
	return ct;
}

@ Tabula rasa:

=
locals_slate LocalVariableSlates::new(void) {
	locals_slate slate;
	slate.local_variable_allocation = NEW_LINKED_LIST(local_variable);
	slate.it_pseudonym = EMPTY_WORDING;
	slate.it_variable_exists = FALSE; slate.its_form_allowed = FALSE;
	return slate;
}

@ It is sometimes necessary to take a snapshot of the current slate, which means
performing a "deep copy".

=
void LocalVariableSlates::deep_copy(locals_slate *slate_to, locals_slate *slate_from) {
	*slate_to = *slate_from;
	slate_to->local_variable_allocation = NEW_LINKED_LIST(local_variable);
	local_variable *lvar;
	LOOP_OVER_LOCALS(lvar, slate_from) {
		local_variable *dup = CREATE(local_variable); *dup = *lvar;
		ADD_TO_LINKED_LIST(dup, local_variable, slate_to->local_variable_allocation);
	}
}

@ A more nuanced technique is to append one frame's variables to another. This
must be done with care, since it runs the risk of a collision between identifier
names of existing frame variables and new ones.

=
void LocalVariableSlates::append(stack_frame *frame_to, stack_frame *frame_from) {
	locals_slate *slate_from = &(frame_from->local_variables);
	locals_slate *slate_to = &(frame_to->local_variables);

	local_variable *lvar;
	LOOP_OVER_LOCALS(lvar, slate_from) {
		local_variable *copied = LocalVariableSlates::allocate_I7_local(slate_to,
			lvar->lv_purpose, lvar->current_usage.varname, lvar->current_usage.kind_as_declared,
			lvar->identifier, lvar->index_with_this_purpose);
		Str::copy(copied->identifier, lvar->identifier);
	}

	if (slate_from->it_variable_exists) {
		slate_to->it_variable_exists = slate_from->it_variable_exists;
		slate_to->its_form_allowed = slate_from->its_form_allowed;
		slate_to->it_pseudonym = slate_from->it_pseudonym;
	}

	if (frame_from->shared_variables) {
		if (frame_to->shared_variables == NULL)
			frame_to->shared_variables = SharedVariables::new_access_list();
		SharedVariables::append_access_list(frame_to->shared_variables,
			frame_from->shared_variables);
	}
}

@h Allocating.
Adding a new I7 local variable to a slate may, or may not, result in the
creation of a new //local_variable// object -- if we can reuse one that is no
longer needed, we will.

=
local_variable *LocalVariableSlates::allocate_I7_local(locals_slate *slate, int purpose,
	wording W, kind *K, text_stream *override_identifier, int override_index) {
	if (slate == NULL) internal_error("no slate");
	local_variable *lvar = NULL;
	@<Allocate an Inter local for this@>;
	@<Fill in the I7 local variable details@>;
	PreformCache::warn_of_changes(); /* since the range of parsing possibilities has changed */
	return lvar;
}

@<Allocate an Inter local for this@> =
	int ix = 0; /* the new one will be the 0th, 1st, 2nd, ... with the same purpose */
	if (override_index >= 0) {
		ix = override_index;
	} else {
		local_variable *find;
		LOOP_OVER_LOCALS(find, slate)
			if (find->lv_purpose == purpose) {
				if (find->allocated == FALSE) { lvar = find; break; }
				ix++;
			}
	}
	if (lvar == NULL) {
		lvar = CREATE(local_variable);
		lvar->comment_on_use = NULL;
		ADD_TO_LINKED_LIST(lvar, local_variable, slate->local_variable_allocation);
	}
	lvar->lv_purpose = purpose;
	lvar->allocated = TRUE;
	if (Str::len(override_identifier) > 0) {
		lvar->identifier = Str::duplicate(override_identifier);
	} else {
		lvar->identifier = Str::new();
		LocalVariableSlates::name_lv(lvar->identifier, purpose, ix);
	}
	lvar->index_with_this_purpose = ix;
	if ((purpose == LET_VALUE_LV) || (purpose == TOKEN_CALL_PARAMETER_LV)) {
		if (lvar->comment_on_use == NULL) lvar->comment_on_use = Str::new();
		else WRITE_TO(lvar->comment_on_use, ", ");
		WRITE_TO(lvar->comment_on_use, "%+W:%u", W, K);
	}

@<Fill in the I7 local variable details@> =
	if (Wordings::nonempty(W)) {
		if (<unsuitable-name-for-locals>(W)) @<Throw a problem for an unsuitable name@>;
		W = Articles::remove_the(W);
	}
	LocalVariableSlates::clear_I7_local(&(lvar->current_usage), W, K);

@<Throw a problem for an unsuitable name@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CalledThe));
	Problems::issue_problem_segment(
		"In %1, you seem to be giving a temporary value a pretty odd name - '%2', which "
		"I won't allow because it would lead to too many ambiguities.");
	Problems::issue_problem_end();

@ We can also use the above mechanism to create locals at the Inter level only,
where the wording of the name is empty because they cannot be referred to in
source text, and the identifier is something chosen specially.

=
local_variable *LocalVariableSlates::find_Inter_identifier(locals_slate *slate,
	text_stream *identifier, int purpose) {
	if (slate) {
		local_variable *lvar;
		LOOP_OVER_LOCALS(lvar, slate)
			if ((lvar->lv_purpose == purpose) &&
				(Str::eq(lvar->identifier, identifier)))
					return lvar;
	}
	return NULL;
}

local_variable *LocalVariableSlates::find_any_Inter_identifier(locals_slate *slate,
	text_stream *name) {
	if (slate) {
		local_variable *lvar;
		LOOP_OVER_LOCALS(lvar, slate)
			if (Str::eq(lvar->identifier, name))
				return lvar;
	}
	return NULL;
}

local_variable *LocalVariableSlates::ensure_Inter_identifier(locals_slate *slate,
	text_stream *identifier, int purpose) {
	local_variable *lvar =
		LocalVariableSlates::find_Inter_identifier(slate, identifier, purpose);
	if (lvar == NULL)
		lvar = LocalVariableSlates::allocate_I7_local(slate, purpose, EMPTY_WORDING, NULL,
			identifier, -1);
	return lvar;
}

@h Deallocating.
The following is used when a "let" variable falls out of scope: for instance,
a loop counter disappearing when its loop body is finished.

=
void LocalVariableSlates::deallocate_I7_local(local_variable *lvar) {
	if (lvar->lv_purpose != LET_VALUE_LV)
		internal_error("only let variables can be deallocated");
	if (lvar->allocated)
		WRITE_TO(lvar->comment_on_use, " (later deallocated)");
	lvar->allocated = FALSE;
	LocalVariableSlates::clear_I7_local(&(lvar->current_usage), EMPTY_WORDING, NULL); 
	PreformCache::warn_of_changes();
}

@ And this jettisons everything:

=
void LocalVariableSlates::deallocate_all(stack_frame *frame) {
	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
		if ((lvar->lv_purpose == LET_VALUE_LV) && (lvar->allocated))
			LocalVariableSlates::deallocate_I7_local(lvar);
}

@ Variables can be marked to have a lifetime which expires at the end of the
current level |s| code block:

=
void LocalVariableSlates::set_scope_to(local_variable *lvar, int s) {
	if ((s > 0) && (lvar) && (lvar->lv_purpose == LET_VALUE_LV)) {
		lvar->current_usage.block_scope = s;
		LOGIF(LOCAL_VARIABLES, "Setting scope of $k to block level %d\n", lvar, s);
	}
}

@ Some local variables have their lifetimes limited to the current block, so
there can be something to do when a block ends.

=
void LocalVariableSlates::free_at_end_of_scope(local_variable *lvar) {
	lvar->current_usage.free_at_end_of_scope = TRUE;
}

@ And here is that reckoning. We deallocate any locals whose lives are now up,
and compile any necessary code to free their memory.

=
void LocalVariableSlates::end_scope(int s) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL) internal_error("relinquishing locals where no stack frame exists");
	if (s <= 0) internal_error("the outermost scope cannot end");

	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
		if ((lvar->lv_purpose == LET_VALUE_LV) &&
			(lvar->allocated) && (lvar->current_usage.block_scope >= s)) {
			LOGIF(LOCAL_VARIABLES, "De-allocating $k at end of block\n", lvar);
			if (lvar->current_usage.free_at_end_of_scope) {
				inter_name *iname = Hierarchy::find(DESTROYPV_HL);
				inter_symbol *LN = LocalVariables::declare(lvar);
				EmitCode::call(iname);
				EmitCode::down();
					EmitCode::val_symbol(K_value, LN);
				EmitCode::up();
			}
			LocalVariableSlates::deallocate_I7_local(lvar);
		}
//	PreformCache::warn_of_changes();
}

@h Declaration.

=
void LocalVariableSlates::declare_all_parameters(stack_frame *frame) {
	LocalVariableSlates::declare_all_with_purpose(frame, TOKEN_CALL_PARAMETER_LV);
	LocalVariableSlates::declare_all_with_purpose(frame, OTHER_CALL_PARAMETER_LV);
}

void LocalVariableSlates::declare_all(stack_frame *frame) {
	LocalVariableSlates::declare_all_with_purpose(frame, TOKEN_CALL_PARAMETER_LV);
	LocalVariableSlates::declare_all_with_purpose(frame, OTHER_CALL_PARAMETER_LV);
	LocalVariableSlates::declare_all_with_purpose(frame, LET_VALUE_LV);
	LocalVariableSlates::declare_all_with_purpose(frame, INTERNAL_USE_LV);
}

void LocalVariableSlates::declare_all_with_purpose(stack_frame *frame, int p) {
	if (frame) {
		local_variable *lvar;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
			if (lvar->lv_purpose == p)
				LocalVariableSlates::declare_one(lvar);
	}
}

inter_symbol *LocalVariableSlates::declare_one(local_variable *lvar) {
	inter_symbol *S = Produce::local_exists(Emit::tree(), lvar->identifier);
	if (S == NULL) S = Produce::local(Emit::tree(), lvar->current_usage.kind_as_declared,
		lvar->identifier, lvar->comment_on_use);
	return S;
}

@ And this emits a sequence of values for the call parameters:

=
void LocalVariableSlates::emit_all_parameters(stack_frame *frame) {
	LocalVariableSlates::emit_all_with_purpose(frame, TOKEN_CALL_PARAMETER_LV);
	LocalVariableSlates::emit_all_with_purpose(frame, OTHER_CALL_PARAMETER_LV);
}

void LocalVariableSlates::emit_all_with_purpose(stack_frame *frame, int p) {
	if (frame) {
		local_variable *lvar;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
			if (lvar->lv_purpose == p) {
				inter_symbol *vs = LocalVariables::declare(lvar);
				EmitCode::val_symbol(K_value, vs);
			}
	}
}
