[LocalVariables::] Local Variables.

Local variables are used for call parameters, temporary values,
and other ephemeral workspace.

@h Definitions.

@ Each phrase has its own "slate" of local variables. For example, in
the definition "..." of:

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
is called its block scope. When Inform compiles on past the end of the loop,
it doesn't actually delete the local variable structure for "item": it simply
marks it as deallocated.

A slate of locals is stored like so:

=
typedef struct locals_slate {
	struct local_variable *local_variable_allocation; /* linked list of valid locals */
	int it_variable_exists; /* it, he, she, or they, used for adjective definitions */
	int its_form_allowed; /* its, his, her or their, ditto */
	struct wording it_pseudonym; /* a further variation on the same variable */
} locals_slate;

@ Which contains a linked list of variables of the following types:

@d TOKEN_CALL_PARAMETER_LV 1	/* values for the tokens of the phrase being invoked */
@d OTHER_CALL_PARAMETER_LV 2	/* other implied parameters passed during invocation: I6-level only */
@d LET_VALUE_LV 3				/* variables created by "let", "while" or "repeat" */
@d INTERNAL_USE_LV 4			/* workspace needed by our compiled code: I6-level only */

=
typedef struct local_variable {
	int lv_purpose; /* one of the |*_LV| values above */
	struct text_stream *lv_lvalue; /* an Inform lvalue for the variable's run-time storage */
	int index_with_this_purpose; /* what index count it has, within locals of its type */
	char *comment_on_use; /* purely to make the output more legible */

	int allocated; /* in existence at this point in the routine? */
	int duplicated;
	struct wording varname; /* name of local variable */
	int name_hash; /* hash code for this name */
	int block_scope; /* scope of a local - block depth */
	int free_at_end_of_scope; /* whether it holds temporary data on heap */
	struct kind *kind_as_declared; /* data type for the contents */
	int protected; /* from alteration using "let"? */
	int parsed_recently; /* name recognised since this was last wiped? */

	struct local_variable *next; /* on the same slate */
	MEMORY_MANAGEMENT
} local_variable;

@ A local variable needs to be stored somewhere at run-time. The obvious
correspondence is to put these into I6 local variables, which are, in effect,
CPU registers. We won't need to do much in the way of register-allocation,
though; we simply take the opportunity to reuse I6 locals if it presents
itself. The resulting I6 function tends to look like this example:

|[ R_314 t_0 t_1 phrase_options tmp_0 tmp_1 tmp_2 ct_0 ct_1;|

where there are two tokens passed to the routine (|t_0| and |t_1|), and
there are phrase options (whose bitmap is in |phrase_options|), and at
the busiest point in the routine three temporary values are needed at
once (|tmp_0| and so on), and finally table-row selection will be
going on, so that we need to record a choice of table (|ct_0|) and
row number within that table (|ct_1|). A typical invocation of this
example phrase would compile to I6 like so:

|R_314(20, O31_black_marble_slab, 16);|

It is perhaps worth stopping to ask ourselves why it is helpful for
values to be in local variables. Unlike traditional register allocation,
this is not done for any speed gain -- in the Z-machine, there is no
particular advantage to a local vs a global variable. The actual reason
is to place a value in the stack frame for the current routine. For
instance, each phrase must have its own "currently selected table row":
it would not do for one phrase which uses another one to find that the
table row had been deselected as a side-effect. So |ct_0| and |ct_1|
are most conveniently stored as locals, not globals.

@ Tabula rasa:

=
locals_slate LocalVariables::blank_slate(void) {
	locals_slate slate;
	slate.local_variable_allocation = NULL;
	slate.it_pseudonym = EMPTY_WORDING;
	slate.it_variable_exists = FALSE; slate.its_form_allowed = FALSE;
	return slate;
}

@h Boxing.
It's sometimes necessary to "box" a stack frame -- to store the entire current
context of compilation for later use. That includes locals, so:

=
void LocalVariables::deep_copy_locals_slate(locals_slate *slate_to, locals_slate *slate_from) {
	*slate_to = *slate_from;
	slate_to->local_variable_allocation = NULL;
	local_variable *lvar, *tail = NULL;
	for (lvar = slate_from->local_variable_allocation; lvar; lvar=lvar->next) {
		local_variable *dup = CREATE(local_variable); *dup = *lvar;
		dup->duplicated = TRUE;
		dup->next = NULL;
		if (tail) tail->next = dup; else slate_to->local_variable_allocation = dup;
		tail = dup;
	}
}

@h Adding.

=
local_variable *LocalVariables::add_to_locals_slate(locals_slate *slate, int purpose, wording W,
	kind *K, text_stream *override_lvalue, int override_index) {
	int ix = 0; /* the new one will be the 0th, 1st, 2nd, ... with the same purpose */
	local_variable *lvar = NULL;

	if (slate) @<Make use of an unallocated var if possible, but otherwise add a new one@>
	else @<Make a new local variable structure@>;
	if (override_index >= 0) ix = override_index;
	@<Fill in the local variable structure, whether it's new or recycled@>;

	ExParser::warn_expression_cache(); /* the range of parsing possibilities has changed */

	return lvar;
}

@<Make use of an unallocated var if possible, but otherwise add a new one@> =
	local_variable *find = slate->local_variable_allocation;
	if (find == NULL) {
		@<Make a new local variable structure@>;
		slate->local_variable_allocation = lvar;
	} else {
		while (find) {
			if (find->lv_purpose == purpose) {
				if (find->allocated == FALSE) { lvar = find; break; }
				ix++;
			}
			if (find->next == NULL) {
				@<Make a new local variable structure@>;
				find->next = lvar;
				break;
			}
			find = find->next;
		}
	}

@<Make a new local variable structure@> =
	lvar = CREATE(local_variable);
	lvar->next = NULL;
	lvar->duplicated = FALSE;

@<Fill in the local variable structure, whether it's new or recycled@> =
	lvar->lv_purpose = purpose;
	lvar->allocated = TRUE;
	if (override_lvalue) lvar->lv_lvalue = Str::duplicate(override_lvalue);
	else {
		lvar->lv_lvalue = Str::new();
		char *prefix = "unknown";
		switch (purpose) {
			case TOKEN_CALL_PARAMETER_LV: prefix = "t";break;
			case OTHER_CALL_PARAMETER_LV: prefix = "ti"; break;
			case LET_VALUE_LV: prefix = "tmp"; break;
			case INTERNAL_USE_LV: prefix = "misc"; break;
			default: internal_error("unknown local variable purpose");
		}
		WRITE_TO(lvar->lv_lvalue, "%s_%d", prefix, ix);
	}
	lvar->index_with_this_purpose = ix;
	lvar->block_scope = 0; /* by default: universal scope throughout routine */
	lvar->free_at_end_of_scope = FALSE;
	lvar->kind_as_declared = K;
	lvar->protected = TRUE;
	lvar->parsed_recently = FALSE;
	lvar->comment_on_use = NULL;

	if (Wordings::nonempty(W)) {
		if (<unsuitable-name-for-locals>(W)) @<Throw a problem for an unsuitable name@>;
		W = Articles::remove_the(W);
	}
	lvar->varname = W;
	lvar->name_hash = ExcerptMeanings::hash_code(W);

@<Throw a problem for an unsuitable name@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::Issue::handmade_problem(_p_(PM_CalledThe));
	Problems::issue_problem_segment(
		"In %1, you seem to be giving a temporary value a pretty "
		"odd name - '%2', which I won't allow because it would lead to too "
		"many ambiguities.");
	Problems::issue_problem_end();

@ For example, here are the call parameters. If there are three of these,
they compile to the I6 names |t_0|, |t_1| and |t_2|.

=
local_variable *LocalVariables::add_call_parameter(ph_stack_frame *phsf,
	wording W, kind *K) {
	local_variable *lvar = LocalVariables::add_to_locals_slate(&(phsf->local_value_variables),
		TOKEN_CALL_PARAMETER_LV, W, K, NULL, -1);
	LOGIF(LOCAL_VARIABLES, "Call parameter $k added\n", lvar);
	return lvar;
}

inter_symbol *LocalVariables::add_call_parameter_as_symbol(ph_stack_frame *phsf,
	wording W, kind *K) {
	local_variable *v = LocalVariables::add_call_parameter(phsf, W, K);
	return LocalVariables::declare_this(v, FALSE, 8);
}

@ Inversely:

=
int LocalVariables::get_parameter_number(local_variable *lvar) {
	if ((lvar == NULL) || (lvar->lv_purpose != TOKEN_CALL_PARAMETER_LV))
		internal_error("not a call parameter");
	return lvar->index_with_this_purpose;
}

@ And here are the "let" values, which can only be added to the routine
currently being compiled:

=
local_variable *LocalVariables::new(wording W, kind *K) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) internal_error("tried to add let value without stack frame");
	local_variable *lvar = LocalVariables::add_to_locals_slate(&(phsf->local_value_variables),
		LET_VALUE_LV, W, K, NULL, -1);
	if (Emit::emitting_routine())
		LocalVariables::declare_this(lvar, FALSE, 6);
	LOGIF(LOCAL_VARIABLES, "Let value $k allocated\n", lvar);
	return lvar;
}

@ Calling this guarantees the presence, at run-time, of an I6 local variable
with a given name. It won't be connected with any I7 values; it will just be
scratch work-space which can be used in the compiled code.

=
local_variable *LocalVariables::add_internal(locals_slate *slate,
	text_stream *name, int purpose) {
	local_variable *lvar = LocalVariables::find_i6_var(slate, name, purpose);
	if (lvar == NULL) lvar = LocalVariables::add_to_locals_slate(slate, purpose, EMPTY_WORDING, NULL, name, -1);
	return lvar;
}

local_variable *LocalVariables::add_internal_local(text_stream *name) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf)
		return LocalVariables::add_internal(&(phsf->local_value_variables), name,
			INTERNAL_USE_LV);
	return NULL;
}

inter_symbol *LocalVariables::add_internal_local_as_symbol(text_stream *name) {
	local_variable *v = LocalVariables::add_internal_local(name);
	return LocalVariables::declare_this(v, FALSE, 8);
}

inter_symbol *LocalVariables::add_internal_local_as_symbol_noting(text_stream *name, local_variable **lv) {
	local_variable *v = LocalVariables::add_internal_local(name);
	if (lv) *lv = v;
	return LocalVariables::declare_this(v, FALSE, 8);
}

local_variable *LocalVariables::add_named_call(text_stream *name) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf)
		return LocalVariables::add_internal(&(phsf->local_value_variables), name,
			OTHER_CALL_PARAMETER_LV);
	return NULL;
}

inter_symbol *LocalVariables::add_named_call_as_symbol(text_stream *name) {
	local_variable *v = LocalVariables::add_named_call(name);
	return LocalVariables::declare_this(v, FALSE, 8);
}

inter_symbol *LocalVariables::add_named_call_as_symbol_noting(text_stream *name, local_variable **lv) {
	local_variable *v = LocalVariables::add_named_call(name);
	if (lv) *lv = v;
	return LocalVariables::declare_this(v, FALSE, 8);
}

local_variable *LocalVariables::add_internal_local_c(text_stream *name, char *comment) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf) {
		local_variable *lvar =
			LocalVariables::add_internal(&(phsf->local_value_variables),
				name, INTERNAL_USE_LV);
		lvar->comment_on_use = comment;
		return lvar;
	}
	return NULL;
}

inter_symbol *LocalVariables::add_internal_local_c_as_symbol(text_stream *name, char *comment) {
	local_variable *v = LocalVariables::add_internal_local_c(name, comment);
	return LocalVariables::declare_this(v, FALSE, 8);
}

inter_symbol *LocalVariables::add_internal_local_c_as_symbol_noting(text_stream *name, char *comment, local_variable **lv) {
	local_variable *v = LocalVariables::add_internal_local_c(name, comment);
	if (lv) *lv = v;
	return LocalVariables::declare_this(v, FALSE, 8);
}

@ For example, |ct_0| and |ct_1| contain the current table and row selection,
in phrases for which that's relevant.

=
void LocalVariables::add_table_lookup(void) {
	LocalVariables::add_internal_local_c(I"ct_0", "currently selected table");
	LocalVariables::add_internal_local_c(I"ct_1", "currently selected row");
	LOGIF(LOCAL_VARIABLES, "Stack frame acquires CT locals\n");
}

@ Similarly |sw_v| holds a temporary switch value, in some cases.

=
local_variable *LocalVariables::add_switch_value(kind *K) {
	LOGIF(LOCAL_VARIABLES, "Stack frame acquires switch value\n");
	return LocalVariables::add_internal_local_c(I"sw_v", "switch value");
}

@ Finally, when phrase options are used in invoking a phrase, a bitmap is
passed to its I6 routine, and this occupies a pseudo-call-parameter:

=
void LocalVariables::options_parameter_is_needed(ph_stack_frame *phsf) {
	LocalVariables::add_internal(&(phsf->local_value_variables),
		I"phrase_options", OTHER_CALL_PARAMETER_LV);
}

@h Deallocating.
The following is used when a "let" variable falls out of scope: for instance,
a loop counter disappearing when its loop body is finished.

=
void LocalVariables::deallocate(local_variable *lvar) {
	if (lvar->lv_purpose != LET_VALUE_LV)
		internal_error("only let variables can be deallocated");
	lvar->allocated = FALSE;
	lvar->varname = EMPTY_WORDING;
	lvar->name_hash = 0;
	lvar->block_scope = 0;
	lvar->free_at_end_of_scope = FALSE;
}

@ More extremely:

=
void LocalVariables::deallocate_all(ph_stack_frame *phsf) {
	local_variable *lvar;
	for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
		if ((lvar->lv_purpose == LET_VALUE_LV) && (lvar->allocated))
			LocalVariables::deallocate(lvar);
}

@h Extent.

=
int LocalVariables::count(ph_stack_frame *phsf) {
	int ct = 0;
	if (phsf) {
		local_variable *lvar;
		for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
			ct++;
	}
	return ct;
}

@h Copying.
It turns out to be useful to be able to copy one slate's variables to
another, in order to remember the current variable names to make sense
of a text substitution later.

We have to deep-copy the variables, not simply copy the head of the linked
list, because they may include variables which will be deallocated and then
given fresh names in between now and then.

=
void LocalVariables::copy(ph_stack_frame *phsf_to, ph_stack_frame *phsf_from) {
	locals_slate *slate_from = &(phsf_from->local_value_variables);
	locals_slate *slate_to = &(phsf_to->local_value_variables);

	local_variable *lvar;
	for (lvar = slate_from->local_variable_allocation; lvar; lvar = lvar->next) {
		local_variable *copied = LocalVariables::add_to_locals_slate(slate_to,
			lvar->lv_purpose, lvar->varname, lvar->kind_as_declared,
			lvar->lv_lvalue, lvar->index_with_this_purpose);
		Str::copy(copied->lv_lvalue, lvar->lv_lvalue);
	}

	slate_to->it_variable_exists = slate_from->it_variable_exists;
	slate_to->its_form_allowed = slate_from->its_form_allowed;
	slate_to->it_pseudonym = slate_from->it_pseudonym;

	phsf_to->local_stvol = phsf_from->local_stvol;
}

@h Searching.
One way is to search the slate for a scratch variable by its I6 name:

=
local_variable *LocalVariables::find_i6_var(locals_slate *slate, text_stream *name, int purpose) {
	local_variable *lvar;
	for (lvar = slate->local_variable_allocation; lvar; lvar = lvar->next)
		if ((lvar->lv_purpose == purpose) &&
			(Str::eq(lvar->lv_lvalue, name)))
				return lvar;
	return NULL;
}

local_variable *LocalVariables::find_any(locals_slate *slate, text_stream *name) {
	local_variable *lvar;
	for (lvar = slate->local_variable_allocation; lvar; lvar = lvar->next)
		if (Str::eq(lvar->lv_lvalue, name))
			return lvar;
	return NULL;
}

@ Thus:

=
local_variable *LocalVariables::by_name(text_stream *name) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return FALSE;
	return LocalVariables::find_i6_var(&(phsf->local_value_variables), name, INTERNAL_USE_LV);
}

local_variable *LocalVariables::by_name_any(text_stream *name) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return FALSE;
	return LocalVariables::find_any(&(phsf->local_value_variables), name);
}

local_variable *LocalVariables::phrase_options(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return NULL;
	return LocalVariables::find_i6_var(&(phsf->local_value_variables), I"phrase_options", OTHER_CALL_PARAMETER_LV);
}

@ =
local_variable *LocalVariables::find_pcalc_var(int v) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return NULL;
	local_variable *lvar;
	locals_slate *slate = &(phsf->local_value_variables);
	for (lvar = slate->local_variable_allocation; lvar; lvar = lvar->next)
		if (Str::len(lvar->lv_lvalue) == 1)
			if (Str::get_at(lvar->lv_lvalue, 0) == pcalc_vars[v])
				return lvar;
	return NULL;
}

local_variable *LocalVariables::find_const_var(int v) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return NULL;
	TEMPORARY_TEXT(T);
	WRITE_TO(T, "const_%d", v);
	local_variable *lvar, *found = NULL;
	locals_slate *slate = &(phsf->local_value_variables);
	for (lvar = slate->local_variable_allocation; lvar; lvar = lvar->next)
		if (Str::eq(lvar->lv_lvalue, T))
			found = lvar;
	DISCARD_TEXT(T);
	return found;
}

@ And, a little cheekily,

=
int LocalVariables::are_we_using_table_lookup(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return FALSE;
	if (LocalVariables::find_i6_var(&(phsf->local_value_variables), I"ct_0", INTERNAL_USE_LV)) return TRUE;
	return FALSE;
}

@ Another way to search is by index. The following, for instance, returns
the ith call parameter on the current slate (counting from 0), or |NULL| if
there isn't one.

=
local_variable *LocalVariables::get_ith_parameter(int i) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) internal_error("no stack frame exists");
	local_variable *lvar;
	int c = 0;
	for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
		if (lvar->lv_purpose == TOKEN_CALL_PARAMETER_LV)
			if (c++ == i)
				return lvar;
	return NULL;
}

@ The main way to search the slate, though, is by source-text name: in other
words, by parsing.

Because local variables come and go on the breeze, we parse them by hand
rather than with the excerpt parser's symbols table. (Experiment shows that
this is better, and that there's a reward for not allowing the hash table
of excerpts to grow, contrary to the general experience with C-like
compiler symbols tables.) All the same we make use of the excerpt hashing
function, to reuse as much earlier work as possible, and the following is
very fast.

=
local_variable *LocalVariables::parse(ph_stack_frame *phsf, wording W) {
	if (phsf == NULL) return NULL;
	local_variable *lvar = LocalVariables::parse_inner(phsf, W);
	if (lvar) lvar->parsed_recently = TRUE;
	return lvar;
}

local_variable *LocalVariables::parse_inner(ph_stack_frame *phsf, wording W) {
	if ((phsf->local_value_variables.it_variable_exists) && (<pronoun>(W)))
		return LocalVariables::it_variable();

	if (<definite-article>(W)) return NULL;
	W = Articles::remove_the(W);

	if ((Wordings::nonempty(phsf->local_value_variables.it_pseudonym)) &&
		(Wordings::match(W, phsf->local_value_variables.it_pseudonym)))
		return LocalVariables::it_variable();

	@<Parse the locals directly@>;
	return NULL;
}

@ Earlier builds of Inform went to some trouble to parse these in reverse
creation order, so that if the same name existed both as a loop variable
and outside it, the inner one would always be parsed -- compare C, where
this is legal (if doubtful in style). But since the Inform language no
longer permits local names to be overloaded like this, there's no longer
any need.

@<Parse the locals directly@> =
	int h = ExcerptMeanings::hash_code(W);
	local_variable *lvar;
	for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
		if ((Wordings::nonempty(lvar->varname)) &&
			(h == lvar->name_hash) &&
			(lvar->allocated == TRUE) &&
			(Wordings::match(W, lvar->varname)))
				return lvar;

@ =
int stack_selection_used_recently = FALSE;
void LocalVariables::monitor_local_parsing(ph_stack_frame *phsf) {
	if (phsf) {
		local_variable *lvar;
		for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
			lvar->parsed_recently = FALSE;
	}
	stack_selection_used_recently = FALSE;
}

void LocalVariables::used_stack_selection(void) {
	stack_selection_used_recently = TRUE;
}

int LocalVariables::local_parsed_recently(ph_stack_frame *phsf) {
	if (phsf) {
		local_variable *lvar;
		for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
			if (lvar->parsed_recently) return TRUE;
	}
	if (stack_selection_used_recently) return TRUE;
	return FALSE;
}

@h It.
"It", when it's allowed, refers always to the first call parameter. This is
used, for instance, in defining adjectives by phrases, where the value which
is to be judged goes in to the first call parameter. (The variable's name
is sometimes needed when the stack frame doesn't exist yet, so we occasionally
fake up a call parameter pro tem.)

=
local_variable *LocalVariables::it_variable(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf) return LocalVariables::get_ith_parameter(0);
	return LocalVariables::add_to_locals_slate(NULL, TOKEN_CALL_PARAMETER_LV,
		EMPTY_WORDING, K_value, NULL, 0);
}

@ Sometimes "its", "his", "her" or "their" is allowed too:

=
int LocalVariables::is_possessive_form_of_it_enabled(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf) return phsf->local_value_variables.its_form_allowed;
	return FALSE;
}

void LocalVariables::enable_possessive_form_of_it(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) internal_error("no stack frame exists");
	phsf->local_value_variables.its_form_allowed = TRUE;
}

local_variable *LocalVariables::add_pronoun(ph_stack_frame *phsf, wording W, kind *K) {
	phsf->local_value_variables.it_variable_exists = TRUE;
	return LocalVariables::add_call_parameter(phsf, W, K);
}

inter_symbol *LocalVariables::add_pronoun_as_symbol(ph_stack_frame *phsf, wording W, kind *K) {
	phsf->local_value_variables.it_variable_exists = TRUE;
	local_variable *v = LocalVariables::add_call_parameter(phsf, W, K);
	return LocalVariables::declare_this(v, FALSE, 8);
}

void LocalVariables::alias_pronoun(ph_stack_frame *phsf, wording W) {
	phsf->local_value_variables.it_pseudonym = W;
}

@h Local Parking.
This is a tricksy little manoeuvre. Suppose we're about to call a function
in our compiled code, and it's a function with no arguments, but we want
our current locals to be still visible from inside it. What we do is to
park the values of the locals into a little scratch array before the call...

=
void LocalVariables::compile_storage(OUTPUT_STREAM, ph_stack_frame *phsf) {
	local_variable *lvar;
	int j=0;
	for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
		WRITE("(LocalParking-->%d=%~L),", j++, lvar);
}

int LocalVariables::emit_storage(ph_stack_frame *phsf) {
	int NC = 0;
	inter_t j = 0;
	for (local_variable *lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next) {
		NC++;
		Emit::inv_primitive(Produce::opcode(SEQUENTIAL_BIP));
		Emit::down();
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				Emit::inv_primitive(Produce::opcode(LOOKUPREF_BIP));
				Emit::down();
					Emit::val_iname(K_value, Hierarchy::find(LOCALPARKING_HL));
					Emit::val(K_number, LITERAL_IVAL, j++);
				Emit::up();
				inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
				Emit::val_symbol(K_value, lvar_s);
			Emit::up();
	}
	return NC;
}

@ ...and then fish them out again as the first thing happening inside the
function, i.e., immediately after the call.

=
void LocalVariables::compile_retrieval(ph_stack_frame *phsf) {
	inter_name *LP = Hierarchy::find(LOCALPARKING_HL);
	inter_t j=0;
	for (local_variable *lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next) {
		Emit::inv_primitive(Produce::opcode(STORE_BIP));
		Emit::down();
			Emit::ref_symbol(K_value, LocalVariables::declare_this(lvar, FALSE, 1));
			Emit::inv_primitive(Produce::opcode(LOOKUP_BIP));
			Emit::down();
				Emit::val_iname(K_value, LP);
				Emit::val(K_number, LITERAL_IVAL, j++);
			Emit::up();
		Emit::up();
	}
}

@h Equation terms.
Another use for local variables is as the terms in an equation.

=
void LocalVariables::make_available_to_equation(equation *eqn) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf) {
		local_variable *lvar;
		for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
			if (lvar->allocated)
				Equations::declare_local(eqn, lvar->varname, lvar->kind_as_declared);
	}
}

@h Callings.
A "calling" is a declaration of the "(called X)" sort. The word range here is
the text "X":

=
local_variable *LocalVariables::ensure_called_local(wording W, kind *K) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) return NULL; /* in case callings are made from parsing alone */
	<new-called-name>(W);
	local_variable *lvar = <<rp>>;
	if ((lvar) && (K)) LocalVariables::set_kind(lvar, K);
	return lvar;
}

@ The following rather inelegantly picks up any apparent callings in some text.

=
wording last_mnc_wording = EMPTY_WORDING_INIT;
wording PM_CalledWithDash_wording = EMPTY_WORDING_INIT;
void LocalVariables::make_necessary_callings(wording W) {
	if (Wordings::within(W, last_mnc_wording)) return;
	last_mnc_wording = W;
	while (Wordings::nonempty(W)) {
		if (<text-including-a-calling>(W)) {
			wording V = GET_RW(<text-including-a-calling>, 2);
			W = GET_RW(<text-including-a-calling>, 3);
			LocalVariables::ensure_called_local(V, K_object);
		} else break;
	}
}

@ When a calling is found in, for instance, a description like this:

>> a body which is part of a person (called the owner)

the text after "called" is run through the following.

Note that production (b) of <new-called-name-unarticled> checks
to see if the name already has a meaning. However, a match against (b) is
disregarded if the meaning is one of those allowed to be overridden: at
present, a global variable, an object name, a table column name, a property
name or a description.

=
<new-called-name> ::=
	<definite-article> <new-called-name-unarticled> |	==> *X = R[2]; *XP = RP[2]
	<new-called-name-unarticled>						==> *X = R[1]; *XP = RP[1]

<new-called-name-unarticled> ::=
	*** - *** |								==> @<Issue PM_CalledWithDash problem@>
	<existing-local-name> |					==> *X = R[1]; *XP = RP[1]
	<s-type-expression-or-value> |			==> @<Vet to see if this name can be overloaded@>
	...										==> @<Make a new local for this calling@>

<existing-local-name> internal {
	*XP = LocalVariables::parse(Frames::current_stack_frame(), W);
	if (*XP) return TRUE;
	return FALSE;
}

@<Issue PM_CalledWithDash problem@> =
	*X = 0; *XP = NULL;
	if (!(Wordings::eq(PM_CalledWithDash_wording, W))) {
		PM_CalledWithDash_wording = W;
		Problems::Issue::sentence_problem(_p_(PM_CalledWithDash),
			"a '(called ...)' name is not allowed to include a hyphen",
			"since this would look misleadingly like a declaration of kind of value it has.");
	}

@<Vet to see if this name can be overloaded@> =
	parse_node *already = <<rp>>;
	if (LocalVariables::permit_as_new_local(already, TRUE) == FALSE) {
		LOG("Meaning already existing: $T\n", already);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		if (Specifications::is_kind_like(already))
			Problems::quote_text(3, "a kind");
		else
			Problems::quote_kind_of(3, already);
		Problems::Issue::handmade_problem(_p_(PM_CalledOverloaded));
		Problems::issue_problem_segment(
			"In %1, it looks as if '%2' is going to be a temporary name which something "
			"will be called. But I can't allow that, because it already has a meaning "
			"as %3.");
		Problems::issue_problem_end();
		*X = 0; *XP = NULL;
	} else return FALSE;

@<Make a new local for this calling@> =
	ph_stack_frame *phsf = Frames::current_stack_frame();
	*X = 0;
	*XP = (phsf)?(LocalVariables::new(W, K_object)):NULL;

@h Permissible names.
This is an interesting issue of policy. Suppose the source text says:

>> let the slate be 1;

and, far away, an object called "the slate" is sitting on a schoolroom desk.
Do we allow this, thus temporarily changing the meaning of "slate", or do
we throw it out with a problem message? If we allow it, we enable source text
to become less clear, since meaning now depends on context. If we forbid it,
we cause all sorts of things to go wrong with extensions (including not least
the Standard Rules): because suppose they contain a local called "slate"
somewhere, and then the unsuspecting user writes

>> The slate is on the desk.

Now there's a conflict, and the user will be baffled, never having read the
extension he's using. So we do allow this, and certain other overloadings
of meanings, too, but it would be too much to say that every phrase has its
own namespace.

Callings get one extra benefit, because they typically exist more fleetingly --
often only for the sentence where they're defined -- and because the syntax
is more explicit. So you can write:

>> if an infected person can see a clean person (called random bystander), ...

even if "random bystander" might otherwise be a request to randomly generate
an instance of the kind "bystander".

=
int LocalVariables::permit_as_new_local(parse_node *found, int as_calling) {
	if (ParseTree::is(found, AMBIGUITY_NT)) found = found->down;
	if ((Specifications::is_kind_like(found)) &&
		(Kinds::Compare::le(Specifications::to_kind(found), K_object) == FALSE)) return FALSE;
	if ((ParseTree::is(found, UNKNOWN_NT)) ||
		(ParseTree::is(found, NONLOCAL_VARIABLE_NT)) ||
		(Specifications::is_description(found)) ||
		(Rvalues::is_object(found)) ||
		(Rvalues::to_instance(found)) ||
		(Rvalues::is_CONSTANT_construction(found, CON_table_column)) ||
		(Rvalues::is_CONSTANT_construction(found, CON_property))) return TRUE;
	if (as_calling)
		if (ParseTreeUsage::is_phrasal(found)) return TRUE;
	return FALSE;
}

@h Logging.

=
void LocalVariables::log(local_variable *lvar) {
	if (lvar->allocated == FALSE) { LOG("LV<unallocated>"); return; }
	if (Wordings::nonempty(lvar->varname)) LOG("LV\"%W\"", lvar->varname);
	else LOG("LV<nameless>");
	LOG("-$u", lvar->kind_as_declared);
}

@ And for run-time debugging in a similar vein:

=
void LocalVariables::describe_repetition_local(OUTPUT_STREAM, local_variable *lvar) {
	if ((lvar) && (lvar->lv_purpose == LET_VALUE_LV)) /* should always be true */
		WRITE("[repetition with %+W set to \", (%n) %~L, \"]^\";\n",
			lvar->varname,
			Kinds::Behaviour::get_iname(lvar->kind_as_declared),
			lvar);
}

@h Kind.
Of a single variable:

=
kind *LocalVariables::kind(local_variable *lvar) {
	if (lvar == NULL) internal_error("Tried to find kind of nonexistent local variable");
	return lvar->kind_as_declared;
}

kind *LocalVariables::unproblematic_kind(local_variable *lvar) {
	if (lvar) return LocalVariables::kind(lvar);
	return NULL;
}

@ Locals are sometimes created before their kinds are known, so this call
exists to fix that:

=
void LocalVariables::set_kind(local_variable *lvar, kind *K) {
	if (lvar == NULL) internal_error("Tried to set kind of nonexistent local variable");
	LOGIF(LOCAL_VARIABLES, "Kind of local $k set to $u\n", lvar, K);
	lvar->kind_as_declared = K;
}

@h Protection.
From being changed by "let", that is. Loop counters are protected, but that's
about it; call parameters aren't, for instance, though it would be a simple
change to make them so. (In the Examples suite as of March 2012, there are
only two points where call parameters are altered. Still, it didn't seem
worth making the change, even though the disruption would be small.)

=
void LocalVariables::unprotect(local_variable *lvar) {
	if (lvar->lv_purpose == LET_VALUE_LV)
		lvar->protected = FALSE;
}

int LocalVariables::protected(local_variable *lvar) {
	if ((lvar->lv_purpose == LET_VALUE_LV) && (lvar->protected)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, lvar->varname);
		Problems::Issue::handmade_problem(_p_(PM_ProtectedFromLet));
		Problems::issue_problem_segment(
			"In %1, it looks as if you want to use 'let' to change the value of "
			"the temporary variable '%2'. Ordinarily that would be fine, but it's "
			"not allowed when the variable is used as the counter in a 'repeat' "
			"loop, or has some other do-not-disturb purpose - this could cause "
			"chaotic effects. The rule is: you can only change an existing value "
			"with 'let' if it was created by 'let' in the first place.");
		Problems::issue_problem_end();
		return TRUE;
	}
	return FALSE;
}

@h Block scope.
At every position in a phrase definition we have a "scope level" number S.
This begins at 0; when a block begins, usually as a loop body, it increments,
and when the block ends it decrements.

=
void LocalVariables::set_scope_to(local_variable *lvar, int s) {
	if ((s > 0) && (lvar) && (lvar->lv_purpose == LET_VALUE_LV)) {
		lvar->block_scope = s;
		LOGIF(LOCAL_VARIABLES, "Setting scope of $k to block level %d\n", lvar, s);
	}
}

@ And here is the reckoning when scope level S ends:

=
void LocalVariables::mark_to_free_at_end_of_scope(local_variable *lvar) {
	lvar->free_at_end_of_scope = TRUE;
}

void LocalVariables::end_scope(int s) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) internal_error("relinquishing locals where no stack frame exists");
	if (s <= 0) internal_error("the outermost scope cannot end");

	local_variable *lvar;
	for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
		if ((lvar->lv_purpose == LET_VALUE_LV) &&
			(lvar->allocated) && (lvar->block_scope >= s)) {
			LOGIF(LOCAL_VARIABLES, "De-allocating $k at end of block\n", lvar);
			if (lvar->free_at_end_of_scope) {
				inter_name *iname = Hierarchy::find(BLKVALUEFREE_HL);
				inter_symbol *LN = LocalVariables::declare_this(lvar, FALSE, 2);
				Emit::inv_call_iname(iname);
				Emit::down();
					Emit::val_symbol(K_value, LN);
				Emit::up();
			}
			LocalVariables::deallocate(lvar);
		}
	ExParser::warn_expression_cache();
}

@ This rather fatuous routine is used only for describing repetitions in
testing output (see above): in other circumstances it wouldn't give the
right result, so don't use it for anything else.

=
local_variable *LocalVariables::latest_repeat_variable(void) {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf) {
		int s = Frames::Blocks::current_block_level();
		local_variable *lvar;
		for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
			if ((lvar->lv_purpose == LET_VALUE_LV) &&
				(lvar->allocated) && (lvar->block_scope == s))
				return lvar;
	}
	return NULL;
}

@h Callings.
We need to keep track of the callings made in any condition so that the
variables, which generally have a scope extending beyond that condition,
can't be left with kind-unsafe (or no) values. For example, if:

>> if a device (called the mechanism) is switched on: ...

turns out false, then "mechanism" has to be safely defused to some kind-safe
value.

@d MAX_CALLINGS_IN_MATCH 128

=
int current_session_number = -1;
int callings_in_condition_sp = 0;
int callings_session_number[MAX_CALLINGS_IN_MATCH];
local_variable *callings_in_condition[MAX_CALLINGS_IN_MATCH];

void LocalVariables::add_calling_to_condition(local_variable *lvar) {
	if (current_session_number < 0) internal_error("no PM session");
	if (callings_in_condition_sp + 1 == MAX_CALLINGS_IN_MATCH)
		Problems::Issue::sentence_problem(_p_(BelievedImpossible), /* or very hard, anyway */
		"that makes too complicated a condition to test",
		"with all of those clauses involving 'called' values.");
	else {
		callings_session_number[callings_in_condition_sp] = current_session_number;
		callings_in_condition[callings_in_condition_sp++] = lvar;
	}
}

void LocalVariables::begin_condition_emit(void) {
	current_session_number++;
	Emit::inv_primitive(Produce::opcode(OR_BIP));
	Emit::down();
}

void LocalVariables::end_condition_emit(void) {
	if (current_session_number < 0) internal_error("unstarted PM session");

	int NC = 0, x = callings_in_condition_sp, downs = 1;
	while ((x > 0) &&
		(callings_session_number[x-1] == current_session_number)) {
		NC++;
		x--;
	}

	if (NC == 0) {
		Emit::val(K_truth_state, LITERAL_IVAL, 0);
	} else {
		Emit::inv_primitive(Produce::opcode(SEQUENTIAL_BIP));
		Emit::down(); downs++;
		int NM = 0, inner_downs = 0;;
		while ((callings_in_condition_sp > 0) &&
			(callings_session_number[callings_in_condition_sp-1] == current_session_number)) {
			NM++;
			local_variable *lvar = callings_in_condition[callings_in_condition_sp-1];
			if (NM < NC) { Emit::inv_primitive(Produce::opcode(SEQUENTIAL_BIP)); Emit::down(); inner_downs++; }
			Emit::inv_primitive(Produce::opcode(STORE_BIP));
			Emit::down();
				inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
				Emit::ref_symbol(K_value, lvar_s);
				kind *K = LocalVariables::kind(lvar);
				if ((K == NULL) ||
					(Kinds::Compare::le(K, K_object)) ||
					(Kinds::Behaviour::definite(K) == FALSE) ||
					(Kinds::RunTime::emit_default_value_as_val(K, EMPTY_WORDING, "'called' value") != TRUE))
					Emit::val(K_truth_state, LITERAL_IVAL, 0);
			Emit::up();
			callings_in_condition_sp--;
		}
		while (inner_downs > 0) { inner_downs--; Emit::up(); }
		Emit::val(K_truth_state, LITERAL_IVAL, 0);
	}
	current_session_number--;
	while (downs > 0) { downs--; Emit::up(); }
}

@h Writer.
Lastly we get to run-time compilation. Writing |%~L| gives code for an I6
lvalue which can be used to evaluate or assign to the variable:

=
void LocalVariables::writer(OUTPUT_STREAM, char *format_string, void *vL) {
	local_variable *lvar = (local_variable *) vL;
	if (lvar == NULL) internal_error("no such variable");
	switch (format_string[0]) {
		case 'L': /* bare |%L| means the same as |%+L|, so fall through to... */
		case '+': WRITE("%+W", lvar->varname); break;
		case '-': WRITE("%-W", lvar->varname); break;
		case '~': WRITE("%S", lvar->lv_lvalue); break;
		default: internal_error("bad %L modifier");
	}
}

@ And here is a comma-separated list (possibly empty) of just the call
parameters:

=
void LocalVariables::compile_parameter_list(OUTPUT_STREAM, ph_stack_frame *phsf, int no_vars) {
	int purpose;
	for (purpose = TOKEN_CALL_PARAMETER_LV; purpose <= OTHER_CALL_PARAMETER_LV; purpose++) {
		local_variable *lvar;
		for (lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
			if (lvar->lv_purpose == purpose) {
				if (no_vars++ > 0) WRITE(", ");
				WRITE("%~L", lvar);
			}
	}
}

void LocalVariables::emit_parameter_list(ph_stack_frame *phsf) {
	for (int purpose = TOKEN_CALL_PARAMETER_LV; purpose <= OTHER_CALL_PARAMETER_LV; purpose++) {
		for (local_variable *lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
			if (lvar->lv_purpose == purpose) {
				inter_symbol *vs = LocalVariables::declare_this(lvar, TRUE, 3);
				Emit::val_symbol(K_value, vs);
			}
	}
}

@ =
kind *LocalVariables::deduced_function_kind(ph_stack_frame *phsf) {
	int pc = 0;
	for (local_variable *lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
		if ((lvar->lv_purpose == TOKEN_CALL_PARAMETER_LV) || (lvar->lv_purpose == OTHER_CALL_PARAMETER_LV))
			pc++;
	kind *K_array[128];
	pc = 0;
	for (local_variable *lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
		if ((lvar->lv_purpose == TOKEN_CALL_PARAMETER_LV) || (lvar->lv_purpose == OTHER_CALL_PARAMETER_LV))
			if (pc < 128) {
				kind *OK = lvar->kind_as_declared;
				if ((OK == NULL) || (OK == K_nil)) OK = K_number;
				K_array[pc++] = OK;
			}
	return Kinds::function_kind(pc, K_array, phsf->kind_returned);
}

@ Finally, I6 local variable declarations for the temporary values we will
need in the compilation of any given routine:

=
void LocalVariables::declare(ph_stack_frame *phsf, int shell_mode) {
	int purpose, from = TOKEN_CALL_PARAMETER_LV, to = INTERNAL_USE_LV;
	if (shell_mode) to = OTHER_CALL_PARAMETER_LV;
	if (phsf)
		for (purpose = from; purpose <= to; purpose++) {
			for (local_variable *lvar = phsf->local_value_variables.local_variable_allocation; lvar; lvar = lvar->next)
				if (lvar->lv_purpose == purpose) {
					LocalVariables::declare_this(lvar, shell_mode, 4);
				}
		}
}

inter_symbol *LocalVariables::declare_this(local_variable *lvar, int shell_mode, int reason) {
	inter_symbol *S = Emit::local_exists(lvar->lv_lvalue);
	if (S) {
		return S;
	}

	inter_t annot = 0;
	switch (lvar->lv_purpose) {
		case TOKEN_CALL_PARAMETER_LV: annot = CALL_PARAMETER_IANN; break;
		case OTHER_CALL_PARAMETER_LV: annot = IMPLIED_CALL_PARAMETER_IANN; break;
	}
	TEMPORARY_TEXT(comment);
	LocalVariables::comment_on(comment, lvar, lvar->lv_purpose);
	inter_symbol *symb = Emit::local(lvar->kind_as_declared, lvar->lv_lvalue, annot, comment);
	DISCARD_TEXT(comment);
	return symb;
}

inter_symbol *LocalVariables::create_and_declare(text_stream *name, kind *K) {
	local_variable *lvar = LocalVariables::add_named_call(name);
	LocalVariables::set_kind(lvar, K);
	return LocalVariables::declare_this(lvar, FALSE, 5);
}

@ Note that a deallocated "let" variable retains its most recent name.

=
void LocalVariables::comment_on(OUTPUT_STREAM, local_variable *lvar, int purpose) {
	switch (purpose) {
		case TOKEN_CALL_PARAMETER_LV:
			if (Wordings::nonempty(lvar->varname))
				WRITE("'%+W': ", lvar->varname);
			Kinds::Textual::write(OUT, lvar->kind_as_declared);
			break;
		case OTHER_CALL_PARAMETER_LV:
			break;
		case LET_VALUE_LV:
			if (Wordings::nonempty(lvar->varname))
				WRITE("e.g., '%+W'", lvar->varname);
			if (lvar->allocated) {
				WRITE(": ");
				Kinds::Textual::write(OUT, lvar->kind_as_declared);
			} else {
				WRITE(" (deallocated by end of phrase)");
			}
			break;
		case INTERNAL_USE_LV:
			if (lvar->comment_on_use)
				WRITE("%s", lvar->comment_on_use);
			else
				WRITE("internal use only");
			break;
	}
}
