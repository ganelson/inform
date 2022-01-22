[LocalVariables::] Local Variables.

Local variables are used for call parameters, temporary values,
and other ephemeral workspace.

@h Declaration.
When some other part of the //runtime// or //imperative// modules wants to
compile an Inter function, it will need to ensure that any local it creates
is declared as part of that function. This is how, and it returns the Inter
symbol referring to the variable.

=
inter_symbol *LocalVariables::declare(local_variable *lvar) {
	return LocalVariableSlates::declare_one(lvar);
}

@h Call parameters.
These are the ones with names in Inform 7 source text, and generally come
from prototypes of phrases.

=
local_variable *LocalVariables::new_call_parameter(stack_frame *frame,
	wording W, kind *K) {
	local_variable *lvar = LocalVariableSlates::allocate_I7_local(&(frame->local_variables),
		TOKEN_CALL_PARAMETER_LV, W, K, NULL, -1);
	LOGIF(LOCAL_VARIABLES, "Call parameter $k added\n", lvar);
	return lvar;
}

@ These are numbered 0, 1, 2, ..., as created, and the following returns that
index number:

=
int LocalVariables::get_parameter_number(local_variable *lvar) {
	if ((lvar == NULL) || (lvar->lv_purpose != TOKEN_CALL_PARAMETER_LV))
		internal_error("not a call parameter");
	return lvar->index_with_this_purpose;
}

@h Other call parameters.
However, our Inter function may also (or instead) be called with other arguments,
and those are "other call parameters": they have no I7 source text name, and
instead referred to by their Inter identifiers alone.

=
local_variable *LocalVariables::new_other_parameter(text_stream *identifier) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame)
		return LocalVariableSlates::ensure_Inter_identifier(&(frame->local_variables),
			identifier, OTHER_CALL_PARAMETER_LV);
	return NULL;
}

inter_symbol *LocalVariables::new_other_as_symbol(text_stream *identifier) {
	local_variable *v = LocalVariables::new_other_parameter(identifier);
	return LocalVariables::declare(v);
}

@ Finally, when phrase options are used in invoking a phrase, a bitmap is
passed to its Inter routine, and this occupies a pseudo-call-parameter:

=
void LocalVariables::options_parameter_is_needed(stack_frame *frame) {
	LocalVariableSlates::ensure_Inter_identifier(&(frame->local_variables),
		I"phrase_options", OTHER_CALL_PARAMETER_LV);
}

local_variable *LocalVariables::options_parameter(void) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame) 
		return LocalVariableSlates::find_Inter_identifier(&(frame->local_variables),
			I"phrase_options", OTHER_CALL_PARAMETER_LV);
	return NULL;
}

@ Both sorts of parameter count:

=
int LocalVariables::is_parameter(local_variable *lvar) {
	if ((lvar) &&
		((lvar->lv_purpose == TOKEN_CALL_PARAMETER_LV) ||
			(lvar->lv_purpose == OTHER_CALL_PARAMETER_LV)))
		return TRUE;
	return FALSE;
}

@h Let values.
These can only be created in the current frame, and they are immediately
declared.

=
local_variable *LocalVariables::new_let_value(wording W, kind *K) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL) internal_error("tried to add let value without stack frame");
	local_variable *lvar = LocalVariableSlates::allocate_I7_local(&(frame->local_variables),
		LET_VALUE_LV, W, K, NULL, -1);
	if (Produce::function_body_is_open(Emit::tree()))
		LocalVariables::declare(lvar);
	LOGIF(LOCAL_VARIABLES, "Let value $k allocated\n", lvar);
	return lvar;
}

@ Some |LET_VALUE_LV| variables are protected from being changed by "let" or "now" --
that sounds contradictory, but for example loop counters in "repeat" constructs are
also |LET_VALUE_LV| locals, and we want to stop the source text from altering
those. Protection is opt-out for let values: we have to call //LocalVariables::unprotect//
if we want a let value to be modifiable from source text.

Note that |TOKEN_CALL_PARAMETER_LV| locals are unprotected, which means that it's
legal in Inform to modify one of the call parameters to a phrase.[1] Protection
would be meaningless for the other two sorts of local, since they aren't accessible
from I7 source text anyway.

[1] We considered banning this in March 2012, when there were only two instances
in the entire set of documentation Examples making use of this "feature". But
in the end, it didn't seem harmful enough to matter.

=
void LocalVariables::unprotect(local_variable *lvar) {
	lvar->current_usage.protected = FALSE;
}

int LocalVariables::protected(local_variable *lvar) {
	if ((lvar->lv_purpose == LET_VALUE_LV) && (lvar->current_usage.protected)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, lvar->current_usage.varname);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ProtectedFromLet));
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

@h Internal locals.
"Internals" are Inter locals which do not correspond to anything at the I7
level, and which are used to implement some low-level feature. They can only
be created in the current frame.

=
local_variable *LocalVariables::new_internal(text_stream *identifier) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame)
		return LocalVariableSlates::ensure_Inter_identifier(&(frame->local_variables),
			identifier, INTERNAL_USE_LV);
	return NULL;
}

inter_symbol *LocalVariables::new_internal_as_symbol(text_stream *identifier) {
	local_variable *v = LocalVariables::new_internal(identifier);
	return LocalVariables::declare(v);
}

local_variable *LocalVariables::new_internal_commented(text_stream *identifier,
	text_stream *comment) {
	local_variable *lvar = LocalVariables::new_internal(identifier);
	if (lvar) lvar->comment_on_use = comment;
	return lvar;
}

inter_symbol *LocalVariables::new_internal_commented_as_symbol(text_stream *identifier,
	text_stream *comment) {
	local_variable *v = LocalVariables::new_internal_commented(identifier, comment);
	return LocalVariables::declare(v);
}

@ For example, |ct_0| and |ct_1| contain the current table and row selection,
in phrases for which that's relevant.

=
void LocalVariables::add_table_lookup(void) {
	LocalVariables::new_internal_commented(I"ct_0", I"currently selected table");
	LocalVariables::new_internal_commented(I"ct_1", I"currently selected row");
	LOGIF(LOCAL_VARIABLES, "Stack frame acquires CT locals\n");
}

int LocalVariables::are_we_using_table_lookup(void) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame == NULL) return FALSE;
	if (LocalVariableSlates::find_Inter_identifier(&(frame->local_variables),
		I"ct_0", INTERNAL_USE_LV)) return TRUE;
	return FALSE;
}

@ Similarly |sw_v| holds a temporary switch value, in some cases.

=
local_variable *LocalVariables::add_switch_value(kind *K) {
	LOGIF(LOCAL_VARIABLES, "Stack frame acquires switch value\n");
	return LocalVariables::new_internal_commented(I"sw_v", I"switch value");
}

@ And this retrieves the local on the current stack frame with the given
identifier, if it exists.

=
local_variable *LocalVariables::find_internal(text_stream *identifier) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame)
		return LocalVariableSlates::find_Inter_identifier(&(frame->local_variables),
			identifier, INTERNAL_USE_LV);
	return NULL;
}

@h Searching by identifier.
One way is to search the slate for a scratch variable by its Inter name:

=
local_variable *LocalVariables::by_identifier(text_stream *name) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame) 
		return LocalVariableSlates::find_any_Inter_identifier(&(frame->local_variables), name);
	return NULL;
}

@ Locals used in predicate calculus have the names |x|, |y|, |z|, |a|, |b|, ...;
the following looks for this identifier, where |v| counts from 0 to 25 through
this reordered alphabet.

=
local_variable *LocalVariables::find_pcalc_var(int v) {
	stack_frame *frame = Frames::current_stack_frame();
	if (frame) {
		local_variable *lvar;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
			if (Str::len(lvar->identifier) == 1)
				if (Str::get_at(lvar->identifier, 0) == pcalc_vars[v])
					return lvar;
	}
	return NULL;
}

@h Searching by index.
Another way to search is by index. The following, for instance, returns
the ith call parameter on the current slate (counting from 0), or |NULL| if
there isn't one.

=
local_variable *LocalVariables::get_ith_parameter(stack_frame *frame, int i) {
	local_variable *lvar;
	int c = 0;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
		if (lvar->lv_purpose == TOKEN_CALL_PARAMETER_LV)
			if (c++ == i)
				return lvar;
	return NULL;
}

@ "It", when it's allowed, refers always to the first call parameter. This is
used, for instance, in defining adjectives by phrases, where the value which
is to be judged goes in to the first call parameter.

=
local_variable *LocalVariables::it_variable(void) {
	stack_frame *frame = Frames::current_stack_frame();
	if ((frame) && (frame->local_variables.it_variable_exists))
		return LocalVariables::get_ith_parameter(frame, 0);
	return NULL;
}

@h Searching by I7 source name.
Because local variables come and go on the breeze, we parse them by hand rather
than with the excerpt parser's symbols table.[1] All the same we make use of the
excerpt hashing function, to reuse as much earlier work as possible, and the
following is very fast.

[1] Experiment shows that this is better, and that there's a reward for not allowing
the hash table of excerpts to grow, contrary to the general experience with C-like
compiler symbols tables.

=
local_variable *LocalVariables::parse(stack_frame *frame, wording W) {
	if (frame == NULL) return NULL;
	local_variable *lvar = LocalVariables::parse_inner(frame, W);
	if (lvar) lvar->current_usage.parsed_recently = TRUE;
	return lvar;
}

local_variable *LocalVariables::parse_inner(stack_frame *frame, wording W) {
	@<Recognise the pronoun it as parameter 0@>;
	@<Remove the definite article@>;
	@<Recognise the it-pseudonym as parameter 0@>;
	@<Parse the locals directly@>;
	return NULL;
}

@<Recognise the pronoun it as parameter 0@> =
	if (frame->local_variables.it_variable_exists)
		if (<agent-pronoun>(W)) {
			pronoun_usage *pu = <<rp>>;
			if (Stock::usage_might_be_third_person(pu->usage))
				return LocalVariables::it_variable();
		}

@<Remove the definite article@> =
	if (<definite-article>(W)) return NULL;
	W = Articles::remove_the(W);

@ Only a few stack frames allow "it" and only some of those also have a pseudonym
for it, so it doesn't seem worth hashing this:

@<Recognise the it-pseudonym as parameter 0@> =
	if ((Wordings::nonempty(frame->local_variables.it_pseudonym)) &&
		(Wordings::match(W, frame->local_variables.it_pseudonym)))
		return LocalVariables::it_variable();

@ Earlier builds of Inform went to some trouble to parse these in reverse
creation order, so that if the same name existed both as a loop variable
and outside it, the inner one would always be parsed -- compare C, where
this is legal (if doubtful in style). But since the Inform language no
longer permits local names to be overloaded like this, there's no longer
any need.

@<Parse the locals directly@> =
	int h = Lexicon::wording_hash(W);
	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
		if ((Wordings::nonempty(lvar->current_usage.varname)) &&
			(h == lvar->current_usage.name_hash) &&
			(lvar->allocated == TRUE) &&
			(Wordings::match(W, lvar->current_usage.varname)))
				return lvar;

@ And this is much the same function in a Preform wrapper:

=
<existing-local-name> internal {
	local_variable *lvar = LocalVariables::parse(Frames::current_stack_frame(), W);
	if (lvar) {
		==> { -, lvar };
		return TRUE;
	}
	==> { fail nonterminal };
}

@h Monitoring parsing.
It turns out to be useful to check whether local variables are ever accessed
by something we're compiling. To do this, call //LocalVariables::monitor_local_parsing//,
compile some code, and then call //LocalVariables::local_parsed_recently// to
see whether that code ever accessed the locals (or the two ct table-selection
variables).

=
int stack_selection_used_recently = FALSE;
void LocalVariables::monitor_local_parsing(stack_frame *frame) {
	if (frame) {
		local_variable *lvar;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
			lvar->current_usage.parsed_recently = FALSE;
	}
	stack_selection_used_recently = FALSE;
}

void LocalVariables::used_ct_locals(void) {
	stack_selection_used_recently = TRUE;
}

int LocalVariables::local_parsed_recently(stack_frame *frame) {
	if (frame) {
		local_variable *lvar;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame)
			if (lvar->current_usage.parsed_recently) return TRUE;
	}
	if (stack_selection_used_recently) return TRUE;
	return FALSE;
}

@h Callings.
A "calling" is a declaration of the sort found in text like "a body which is part
of a person (called the owner)". This will need to create a local variable with
the name "the owner". Here |W| would be that name, and |K| would be |K_body|:

=
wording PM_CalledWithDash_wording = EMPTY_WORDING_INIT;

local_variable *LocalVariables::ensure_calling(wording W, kind *K) {
	if ((Frames::current_stack_frame()) && (<new-calling>(W))) {
		local_variable *lvar = <<rp>>;
		if ((K) && (lvar)) LocalVariables::set_kind(lvar, K);
		return lvar;
	}
	return NULL;
}

@ The work is done by this Preform grammar:

=
<new-calling> ::=
	<definite-article> <new-calling-unarticled> | ==> { pass 2 }
	<new-calling-unarticled>                      ==> { pass 1 }

<new-calling-unarticled> ::=
	*** - *** |                                   ==> @<Issue PM_CalledWithDash problem@>
	<existing-local-name> |                       ==> { pass 1 }
	<s-type-expression-or-value> |                ==> @<Vet to see if this name can be overloaded@>
	...                                           ==> { 0, LocalVariables::new_let_value(W, K_object) }

@<Issue PM_CalledWithDash problem@> =
	if (!(Wordings::eq(PM_CalledWithDash_wording, W))) {
		PM_CalledWithDash_wording = W;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CalledWithDash),
			"a '(called ...)' name is not allowed to include a hyphen",
			"since this would look misleadingly like a declaration of kind of value it has.");
	}
	==> { 0, NULL }

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
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CalledOverloaded));
		Problems::issue_problem_segment(
			"In %1, it looks as if '%2' is going to be a temporary name which something "
			"will be called. But I can't allow that, because it already has a meaning "
			"as %3.");
		Problems::issue_problem_end();
		==> { 0, NULL }
	} else return FALSE;

@ The following rather inelegantly picks up any apparent callings in some text,
making all of them objects.

=
wording last_mnc_wording = EMPTY_WORDING_INIT;
void LocalVariables::make_necessary_callings(wording W) {
	if (Wordings::within(W, last_mnc_wording)) return;
	last_mnc_wording = W;
	while (Wordings::nonempty(W)) {
		if (<text-including-a-calling>(W)) {
			wording V = GET_RW(<text-including-a-calling>, 2);
			W = GET_RW(<text-including-a-calling>, 3);
			LocalVariables::ensure_calling(V, K_object);
		} else break;
	}
}

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

>> if an infected person can see a healthy person (called random bystander), ...

even if "random bystander" might otherwise be a request to randomly generate
an instance of the kind "bystander".

=
int LocalVariables::permit_as_new_local(parse_node *found, int as_calling) {
	if (Node::is(found, AMBIGUITY_NT)) found = found->down;
	if ((Specifications::is_kind_like(found)) &&
		(Kinds::Behaviour::is_object(Specifications::to_kind(found)) == FALSE)) return FALSE;
	if ((Node::is(found, UNKNOWN_NT)) ||
		(Node::is(found, NONLOCAL_VARIABLE_NT)) ||
		(Specifications::is_description(found)) ||
		(Rvalues::is_object(found)) ||
		(Rvalues::to_instance(found)) ||
		(Rvalues::is_CONSTANT_construction(found, CON_table_column)) ||
		(Rvalues::is_CONSTANT_construction(found, CON_property))) return TRUE;
	if (as_calling)
		if (Specifications::is_phrasal(found)) return TRUE;
	return FALSE;
}

@h Kind.
Of a single variable:

=
kind *LocalVariables::kind(local_variable *lvar) {
	if (lvar) return lvar->current_usage.kind_as_declared;
	return NULL;
}

@ Locals are sometimes created before their kinds are known, so this call
exists to fix that:

=
void LocalVariables::set_kind(local_variable *lvar, kind *K) {
	if (lvar == NULL) internal_error("Tried to set kind of nonexistent local variable");
	LOGIF(LOCAL_VARIABLES, "Kind of local $k set to %u\n", lvar, K);
	lvar->current_usage.kind_as_declared = K;
}

@h Logging.

=
void LocalVariables::log(local_variable *lvar) {
	LocalVariables::write(DL, lvar);
}

void LocalVariables::writer(OUTPUT_STREAM, char *format_string, void *vL) {
	local_variable *lvar = (local_variable *) vL;
	if (lvar == NULL) internal_error("no such variable");
	switch (format_string[0]) {
		case 'L': /* bare |%L| means the same as |%+L|, so fall through to... */
		case '+': WRITE("%+W", lvar->current_usage.varname); break;
		case '-': WRITE("%-W", lvar->current_usage.varname); break;
		case '~': WRITE("%S", lvar->identifier); break;
		default: internal_error("bad %L modifier");
	}
}

void LocalVariables::write(OUTPUT_STREAM, local_variable *lvar) {
	if (lvar->allocated == FALSE) { WRITE("LV<unallocated>"); return; }
	if (Wordings::nonempty(lvar->current_usage.varname)) WRITE("LV\"%W\"", lvar->current_usage.varname);
	else WRITE("LV<nameless>");
	WRITE("-");
	Kinds::Textual::write(OUT, lvar->current_usage.kind_as_declared);
}
