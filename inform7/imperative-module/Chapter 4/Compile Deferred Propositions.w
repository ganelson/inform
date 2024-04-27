[DeferredPropositions::] Compile Deferred Propositions.

To compile the Inter functions needed to perform the tests or tasks
deferred as being too difficult in their original contexts.

@h Comment.
The following compiles an Inter comment noting the reason for a deferral.

=
void DeferredPropositions::compile_comment_about_deferral_reason(int reason) {
	switch(reason) {
		case CONDITION_DEFER:
			EmitCode::comment(I"True or false?"); break;
		case NOW_ASSERTION_DEFER:
			EmitCode::comment(I"Force this to be true via 'now':"); break;
		case EXTREMAL_DEFER:
			EmitCode::comment(I"Find the extremal x satisfying:"); break;
		case LOOP_DOMAIN_DEFER:
			EmitCode::comment(I"Find next x satisfying:"); break;
		case LIST_OF_DEFER:
			EmitCode::comment(I"Construct a list of x satisfying:"); break;
		case NUMBER_OF_DEFER:
			EmitCode::comment(I"How many x satisfy this?"); break;
		case TOTAL_DEFER:
			EmitCode::comment(I"Find a total property value over all x satisfying:"); break;
		case TOTAL_REAL_DEFER:
			EmitCode::comment(I"Find a total real property value over all x satisfying:"); break;
		case RANDOM_OF_DEFER:
			EmitCode::comment(I"Find a random x satisfying:"); break;
		case MULTIPURPOSE_DEFER:
			EmitCode::comment(I"Abstraction for set of x such that:"); break;
		default: internal_error("Unknown proposition deferral reason");
	}
}

@h Preliminaries.
Propositions are deferred for diverse reasons: see //Deciding to Defer//. Here
we take our medicine, and actually compile those deferred propositions into
functions. This has to be done by an agent because funny things can happen
when we compile: we can create new text substitutions which create routines
which... and so on. (See //core: How To Compile//.)

=
void DeferredPropositions::compilation_agent(compilation_subtask *t) {
	pcalc_prop_deferral *pdef = RETRIEVE_POINTER_pcalc_prop_deferral(t->data);
	pcalc_prop_deferral *save_current_pdef = current_pdef;
	current_pdef = pdef;
	DeferredPropositions::compile(pdef);
	current_pdef = save_current_pdef;	
}

@ The basic structure of a proposition function is the same for all of the
various reasons, but with considerable variations affecting (mainly) the
initial setup and the returned value.

Note that the unchecked array bounds of 26 are safe here because propositions
may only use 26 different variables at most (|x|, |y|, |z|, |a|, ..., |w|). Only
in very contrived circumstances are there ever more than three quantifiers, so
this is plenty large enough:

@d MAX_QC_VARIABLES 100

=
void DeferredPropositions::compile(pcalc_prop_deferral *pdef) {
	int ct_locals_problem_thrown = FALSE, negated_quantifier_found = FALSE;
	current_sentence = pdef->deferred_from;
	pcalc_prop *proposition = Propositions::copy(pdef->proposition_to_defer);
	int multipurpose_function = (pdef->reason == MULTIPURPOSE_DEFER)?TRUE:FALSE;
	int reason = CONDITION_DEFER; /* redundant assignment to appease compilers */

	inter_symbol *reason_s = NULL;
	inter_symbol *var_s[26], *var_ix_s[26];
	local_variable *var_ix_lv[26];
	inter_symbol *qcy_s[MAX_QC_VARIABLES], *qcn_s[MAX_QC_VARIABLES];

	inter_symbol *best_s = NULL;
	inter_symbol *best_with_s = NULL;
	inter_symbol *counter_s = NULL;
	inter_symbol *list_s = NULL;
	inter_symbol *selection_s = NULL;
	inter_symbol *strong_kind_s = NULL;
	inter_symbol *total_s = NULL;

	inter_symbol *NextOuterLoop_labels[MULTIPURPOSE_DEFER+1];
	for (int r = 0; r < MULTIPURPOSE_DEFER+1; r++) NextOuterLoop_labels[r] = NULL;

	@<Simplify the proposition by flipping negated quantifiers, if possible@>;

	LOGIF(PREDICATE_CALCULUS, "Compiling %n as deferred proposition: %d: reason %d: $D\n",
		pdef->ppd_iname, pdef->allocation_id, pdef->reason, proposition);

	packaging_state save = Functions::begin(pdef->ppd_iname);

	@<Declare the Inter local variables which will be needed by this deferral function@>;
	@<Compile the code inside this deferral function@>;
	@<Issue a problem message if the table-lookup locals were needed@>;
	@<Issue a problem message if a negated quantifier was needed@>;

	Functions::end(save);

	if (pdef->rtp_iname) @<Compile the constant origin text for run-time problem use@>;
}

@ We compile the following only in cases where it seems possible that a
run-time problem message may be needed; compiling it for every deferred
proposition would be wasteful of space in the Z-machine.

@<Compile the constant origin text for run-time problem use@> =
	TEMPORARY_TEXT(COTT)
	if (pdef->deferred_from)
		WRITE_TO(COTT, "%~W", Node::get_text(pdef->deferred_from));
	else
		WRITE_TO(COTT, "not sure where this came from");
	Emit::text_constant(pdef->rtp_iname, COTT);
	DISCARD_TEXT(COTT)

@ Just in case this hasn't already been done:

@<Simplify the proposition by flipping negated quantifiers, if possible@> =
	int changed = FALSE;
	proposition = Simplifications::negated_determiners(proposition, &changed, TRUE);
	if (changed) {
		LOGIF(PREDICATE_CALCULUS, "Simplifications::negated_determiners: $D\n", proposition);
	}

@ While unfortunate in a way, this is for the best, because a successful match
on a condition looking up a table would record the table and row in local
variables within the deferred proposition: they would then be wrong in the
calling function, where they are needed.

@<Issue a problem message if the table-lookup locals were needed@> =
	if ((LocalVariables::are_we_using_table_lookup()) && (!ct_locals_problem_thrown)) {
		ct_locals_problem_thrown = TRUE;
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantLookUpTableInDeferred),
			"I am not able to look up table entries in this complicated condition",
			"which seems to involve making a potentially large number of checks in "
			"rather few words (and may perhaps result from a misunderstanding such as "
			"writing the name of a kind where an individual object is intended?).");
	}

@ This looks like a horrible restriction, but in fact propositions are built
and simplified in such a way that it never bites. (Quantifiers are always
moved outside of negation where possible, and it is almost always possible.)

@<Issue a problem message if a negated quantifier was needed@> =
	if (negated_quantifier_found)
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this involves a very complicated negative thought",
			"which I'm not able to untangle. Perhaps you could rephrase this more simply, "
			"or split it into more than one sentence?");

@<Declare the Inter local variables which will be needed by this deferral function@> =
	if (multipurpose_function)
		reason_s = LocalVariables::new_other_as_symbol(I"reason"); /* no cinders exist here */
	else
		Cinders::declare(proposition, pdef); /* no reason code needed, function does one thing */
	@<Declare the Inter call parameters needed by adaptations to particular deferral cases@>;
	@<Declare locals corresponding to predicate calculus variables@>;
	@<Declare one pair of locals for each quantifier@>;
	@<Declare the Inter locals needed by adaptations to particular deferral cases@>;

@ If the proposition uses |x| and |y|, we will define locals called |x| and |y|
to hold their current values, and so on.

@<Declare locals corresponding to predicate calculus variables@> =
	int var_states[26];
	Binding::determine_status(proposition, var_states, NULL);
	for (int j=0; j<26; j++)
		if (var_states[j] != UNUSED_VST) {
			TEMPORARY_TEXT(letter_var)
			PUT_TO(letter_var, pcalc_vars[j]);
			var_s[j] = LocalVariables::new_internal_as_symbol(letter_var);
			WRITE_TO(letter_var, "_ix");
			var_ix_lv[j] = LocalVariables::new_internal(letter_var);
			var_ix_s[j] = LocalVariables::declare(var_ix_lv[j]);
			DISCARD_TEXT(letter_var)
		} else {
			var_s[j] = NULL;
			var_ix_s[j] = NULL;
			var_ix_lv[j] = NULL;
		}

@ The first quantifier gets |qcy_0|, |qcn_0|; the second |qcy_1|, |qcn_1|;
and so on.

@<Declare one pair of locals for each quantifier@> =
	int no_extras = 0;
	TRAVERSE_VARIABLE(pl);
	TRAVERSE_PROPOSITION(pl, proposition)
		if (pl->element == DOMAIN_OPEN_ATOM) {
			if (no_extras >= MAX_QC_VARIABLES) break;
			TEMPORARY_TEXT(q_var)
			WRITE_TO(q_var, "qcy_%d", no_extras);
			qcy_s[no_extras] = LocalVariables::new_internal_as_symbol(q_var);
			Str::clear(q_var);
			WRITE_TO(q_var, "qcn_%d", no_extras);
			qcn_s[no_extras] = LocalVariables::new_internal_as_symbol(q_var);
			DISCARD_TEXT(q_var)
			no_extras++;
		}

@ A multipurpose function |f(x)| has to test whether $\phi(x)$ is true if $x \geq 0$,
but if $x < 0$ then it will be one of the |*_DUSAGE| values, and we switch on which
it is. Each of those switch cases contains code for one of the possibilities;
whereas for a single-purpose function, we just compile the code for that single
possibility.

@<Compile the code inside this deferral function@> =
	if (multipurpose_function) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(GE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, reason_s);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, var_s[0]);
					EmitCode::val_symbol(K_value, reason_s);
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, reason_s);
					EmitCode::val_number((inter_ti) CONDITION_DUSAGE);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();

		EmitCode::inv(SWITCH_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, reason_s);
			EmitCode::code();
			EmitCode::down();
				pcalc_prop *safety_copy = Propositions::copy(proposition);
				for (int use = EXTREMAL_DUSAGE; use <= CONDITION_DUSAGE; use++) {
					if (use > EXTREMAL_DUSAGE) proposition = Propositions::copy(safety_copy);
					switch (use) {
						case CONDITION_DUSAGE: reason = CONDITION_DEFER; break;
						case LOOP_DOMAIN_DUSAGE: reason = LOOP_DOMAIN_DEFER; break;
						case LIST_OF_DUSAGE: reason = LIST_OF_DEFER; break;
						case NUMBER_OF_DUSAGE: reason = NUMBER_OF_DEFER; break;
						case RANDOM_OF_DUSAGE: reason = RANDOM_OF_DEFER; break;
						case TOTAL_DUSAGE: reason = TOTAL_DEFER; break;
						case TOTAL_REAL_DUSAGE: reason = TOTAL_REAL_DEFER; break;
						case EXTREMAL_DUSAGE: reason = EXTREMAL_DEFER; break;
					}
					if ((use == TOTAL_REAL_DUSAGE) &&
						(TargetVMs::supports_floating_point(Task::vm()) == FALSE))
						continue;
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_number((inter_ti) use);
						EmitCode::code();
						EmitCode::down();
							DeferredPropositions::compile_comment_about_deferral_reason(reason);
							@<Compile body of deferred proposition for the given reason@>;
						EmitCode::up();
					EmitCode::up();
				}
			EmitCode::up();
		EmitCode::up();
	} else {
		reason = pdef->reason;
		@<Compile body of deferred proposition for the given reason@>;
	}

@ So from here on we compile code to handle a single function.

What these different cases have in common is that each is basically a search
of all possible values of the bound variables in the expression. There will
be some initialisation, something to do with each successfully found
combination, and eventually some winding-up code. For example, "number of..."
initialises by setting |counter| to 0, on each success it performs |counter++|,
and at the end of the search it performs |return counter|.

@<Compile body of deferred proposition for the given reason@> =
	property *prn = NULL;
	property *def_prn = NULL;
	int def_prn_sign = 0;
	int OL = EmitCode::level();

	switch(reason) {
		case NOW_ASSERTION_DEFER: break;
		case CONDITION_DEFER: @<Initialisation before CONDITION search@>; break;
		case EXTREMAL_DEFER: @<Initialisation before EXTREMAL search@>; break;
		case LOOP_DOMAIN_DEFER: @<Initialisation before LOOP search@>; break;
		case NUMBER_OF_DEFER: @<Initialisation before NUMBER search@>; break;
		case LIST_OF_DEFER: @<Initialisation before LIST search@>; break;
		case TOTAL_DEFER: @<Initialisation before TOTAL search@>; break;
		case TOTAL_REAL_DEFER: @<Initialisation before TOTAL REAL search@>; break;
		case RANDOM_OF_DEFER: @<Initialisation before RANDOM search@>; break;
	}
	@<Compile code to search for valid combinations of variables@>;

	if ((reason != NOW_ASSERTION_DEFER) && (reason != CONDITION_DEFER)) {
		@<Place next outer loop label@>;
		while (EmitCode::level() > OL) EmitCode::up();
	}

	switch(reason) {
		case NOW_ASSERTION_DEFER: break;
		case CONDITION_DEFER: @<Winding-up after CONDITION search@>; break;
		case EXTREMAL_DEFER: @<Winding-up after EXTREMAL search@>; break;
		case LOOP_DOMAIN_DEFER: @<Winding-up after LOOP search@>; break;
		case NUMBER_OF_DEFER: @<Winding-up after NUMBER search@>; break;
		case LIST_OF_DEFER: @<Winding-up after LIST search@>; break;
		case TOTAL_DEFER: @<Winding-up after TOTAL search@>; break;
		case TOTAL_REAL_DEFER: @<Winding-up after TOTAL REAL search@>; break;
		case RANDOM_OF_DEFER: @<Winding-up after RANDOM search@>; break;
	}

@h The Search.
We can now begin the real work. Given $\phi$, we compile Inter code which
contains a magic position M (for "match") such that M is visited exactly
once for every combination of possible substitutions into the bound
variables such that $\phi$ is true. For example,
$$ \exists x: {\it door}(x)\land{\it open}(x)\land \exists y: {\it room}(y)\land{\it in}(x, y) $$
might compile to code in the form:
= (text)
	blah, blah, blah {
	    M
	} rhubarb, rhubarb
=
such that execution reaches |M| exactly once for each combination of open
door $x$ and room $y$ such that $x$ is in $y$. (Position |M| is where we
will place the case-dependent code for what to do on a successful match.)
In the language of model theory, this is a loop over all interpretations
of the variables in which $\phi$ is true.

The algorithm below is, so far as I know, original to Inform, and it is not
simple to prove correct, so the reader will excuse a fairly hefty amount of
commentary here.

Our basic method is to compile the proposition from left to right. If there
are $k$ atoms in $\phi$, then there are $k+1$ positions between atoms,
counting the start and the end. We maintain the following:

(*) Invariant. Let $\psi$ be any syntactically valid subproposition
of $\phi$ (that is, a contiguous sequence of atoms from $\psi$ which would
be a valid proposition in its own right). Then there are before and after
positions |B| and |A| in the compiled Inter code for searching $\phi$ such that
(-a) |A| cannot be reached except from |B|, and
(-b) at execution time, on every occasion |B| is reached, |A| is then reached
exactly once for each combination of possible substitutions into the
$\exists$-bound variables of $\psi$ such that $\psi$ is then true.

In particular, in the case when $\psi = \phi$, |B| is the start of our
compiled Inter code (before anything is done) and |A| is the magic match
position |M|.

@ Lemma: If the Invariant holds for two adjacent syntactically valid
subpropositions $\mu$ and $\nu$, then it holds for the subproposition $\mu\nu$.

Proof of lemma: There are now three positions in the code: |B1|, before $\mu$;
|B2|, before $\nu$, which is the same position as after $\mu$; and |A|, after
$\nu$. Execution reaches |B2| $m$ times for each visit to |B1|, where $m$
is the number of combinations of viable bound variable values in $\mu$.
Execution reaches |A| $n$ times for each visit to |B2|, where $n$ is the
similar number for $\nu$. Therefore execution reaches |A| a total of $nm$
times for each visit to |B1|, the product of the number of variable combinations
in $\mu$ and $\nu$, which is exactly the number of combinations in total.

Corollary: If the Invariant holds for subpropositions in each of
the following forms, then it will hold overall:
(a) |Exists v|, for some variable $v$, or |Q v IN[ ... IN]|, for some quantifier other than $\exists$.
(b) |NOT[ ... NOT]|.
(c) Any single predicate-like atom.

Proof of corollary: All valid subpropositions are concatenations of (a) to (c),
and we then apply the Lemma inductively.

It follows that if we can prove our algorithm maintains the invariant in
cases (a) to (c), we can be sure it will correctly construct code leading
to the match point |M|.

@ We will make use of four stacks:
(a) The R-stack, which holds the current "reason": the goal being pursued
by the Inter code currently being compiled.
(b) The Q-stack, which holds details of quantifiers being searched on.
(c) The C-stack, which holds details of callings of variables.
(d) The L-stack, which records hierarchical levels in the Inter code generated.
The current stack pointer |L_sp| for this is equivalent to the depth of nesting
of the Inter code being generated.

Each stack begins empty: we want to be absolutely sure that this algorithm
behaves as expected, so internal errors are thrown if any stack underflows,
overflows, or is other than empty again at the end. The maximum capacity in each
case is tied either to the number of distinct predicate calculus variables, or
the number of quantifiers, and in either case is at worst 26. But the R-stack
potentially needs one more slot to hold the outermost reason, so we'll just
give them all a capacity of 27.

@d R_STACK_CAPACITY 27
@d Q_STACK_CAPACITY 27
@d C_STACK_CAPACITY 27
@d L_STACK_CAPACITY 27

=
typedef struct r_stack_data {
	int reason;                /* what task are we performing? A |*_DEFER| value */
	int parity;                /* |TRUE| if we want a match, |FALSE| if we want no match */
} r_stack_data;

typedef struct q_stack_data {
	struct quantifier *quant;  /* which quantifier */
	int parameter;             /* its parameter, e.g., 9 for "more than nine" */
	int C_stack_level;         /* at the point this occurs */
	int L_stack_level;
	int existential;           /* just one solution is needed */
} q_stack_data;

typedef struct c_stack_data {
	struct pcalc_term term;    /* the term to which a calling is being given */
	int stash_index;           /* its index in the stash of callings */
} c_stack_data;

typedef struct l_stack_data {
	int level;                 /* Inter emission level at start of code block */
} l_stack_data;

@<Compile code to search for valid combinations of variables@> =
	r_stack_data R_stack[R_STACK_CAPACITY]; int R_sp = 0;
	q_stack_data Q_stack[Q_STACK_CAPACITY]; int Q_sp = 0;
	c_stack_data C_stack[C_STACK_CAPACITY]; int C_sp = 0;
	l_stack_data L_stack[L_STACK_CAPACITY]; int L_sp = 0;

	@<Push initial reason onto the R-stack@>;
	/* we now begin compiling the search code */
	@<Compile the proposition into a search algorithm@>;
	while (Q_sp > 0) @<Pop the Q-stack@>;
	while (C_sp > 0) @<Pop the C-stack@>;
	/* we are now at the magic match point |M| in the search code */
	@<Pop the R-stack@>;
	while (L_sp > 0) @<Pop the L-stack@>;
	/* we have now finished compiling the search code */

	if (R_sp != 0) internal_error("R-stack failure");
	if (Q_sp != 0) internal_error("Q-stack failure");
	if (C_sp != 0) internal_error("C-stack failure");
	if (L_sp != 0) internal_error("L-stack failure");

@h The R-stack.
This is a sort of "split goals into sub-goals" mechanism. In order to
determine, say, "if all but one of the closed doors are unlocked", the main
goal is to determine the truth of the "are unlocked" part. For that example,
|reason| will be |CONDITION_DEFER|, and it is pushed onto the R-stack at the
start of the compilation:

@<Push initial reason onto the R-stack@> =
	if (R_sp >= R_STACK_CAPACITY) internal_error("R-stack overflow");
	R_stack[R_sp].reason = reason;
	R_stack[R_sp].parity = TRUE;
	R_sp++;

@ But in order to work this out, we have to work out which doors are closed,
and this is a subgoal to which we give the pseudo-reason |FILTER_DEFER|. We
push this new sub-goal onto the R-stack, leaving the original to be resumed
when we're done.

@d FILTER_DEFER 10000 /* pseudo-reason value used only inside this function */

@<Push domain-opening onto the R-stack@> =
	if (R_sp >= R_STACK_CAPACITY) internal_error("R-stack overflow");
	R_stack[R_sp].reason = FILTER_DEFER;
	R_stack[R_sp].parity = TRUE;
	R_sp++;

@ The R-stack is then popped when the goal is accomplished (or rather, when
the Inter code we are compiling has reached a point which will be executed when
its goal has been accomplished).

In the case of |FILTER_DEFER|, when scanning domains of quantifiers, we increment
the count of the domain set size -- the number of closed doors, in the above
example. (See below.)

@<Pop the R-stack@> =
	if (R_sp <= 0) internal_error("R stack underflow");
	R_sp--;

	switch(R_stack[R_sp].reason) {
		case FILTER_DEFER:
			EmitCode::inv(POSTINCREMENT_BIP);
			EmitCode::down();
				if (Q_sp <= 0) internal_error("Q stack underflow");
				EmitCode::ref_symbol(K_value, qcn_s[Q_sp-1]);
			EmitCode::up();
			break;
		case NOW_ASSERTION_DEFER: break;
		case CONDITION_DEFER: @<Act on successful match in CONDITION search@>; break;
		case EXTREMAL_DEFER: @<Act on successful match in EXTREMAL search@>; break;
		case LOOP_DOMAIN_DEFER: @<Act on successful match in LOOP search@>; break;
		case NUMBER_OF_DEFER: @<Act on successful match in NUMBER search@>; break;
		case LIST_OF_DEFER: @<Act on successful match in LIST search@>; break;
		case TOTAL_DEFER: @<Act on successful match in TOTAL search@>; break;
		case TOTAL_REAL_DEFER: @<Act on successful match in TOTAL REAL search@>; break;
		case RANDOM_OF_DEFER: @<Act on successful match in RANDOM search@>; break;
	}

@h Compiling the search.
In the following we run through the proposition from left to right, compiling
Inter code as we go, but preserving the Invariant.

@<Compile the proposition into a search algorithm@> =
	TRAVERSE_VARIABLE(pl);
	int run_of_conditions = 0;
	int no_deferred_callings = 0; /* how many callings found to date */

	TRAVERSE_PROPOSITION(pl, proposition) {
		switch (pl->element) {
			case NEGATION_OPEN_ATOM:
			case NEGATION_CLOSE_ATOM:
				@<End a run of predicate-like conditions, if one is under way@>;
				R_stack[R_sp-1].parity = (R_stack[R_sp-1].parity)?FALSE:TRUE; /* reverse parity */
				break;
			case QUANTIFIER_ATOM:
				@<End a run of predicate-like conditions, if one is under way@>;
				if (R_stack[R_sp-1].parity == FALSE) negated_quantifier_found = TRUE;
				quantifier *quant = pl->quant;
				int param = Atoms::get_quantification_parameter(pl);
				if (quant == exists_quantifier)
					@<Mark the Q-stack to show an inner existential quantifier is in play@>
				else
					@<Push the Q-stack@>;
				@<Compile a loop through possible values of the variable quantified@>;
				break;
			case DOMAIN_OPEN_ATOM:
				@<End a run of predicate-like conditions, if one is under way@>;
				@<Push domain-opening onto the R-stack@>;
				break;
			case DOMAIN_CLOSE_ATOM:
				@<End a run of predicate-like conditions, if one is under way@>;
				@<Pop the R-stack@>;
				break;
			default: {
				if (CreationPredicates::is_calling_up_atom(pl))
					@<Push the C-stack@>
				else if (R_stack[R_sp-1].reason == NOW_ASSERTION_DEFER)
					@<Compile code to force the atom@>
				else {
					int last_in_run = TRUE, first_in_run = TRUE;
					if (run_of_conditions++ > 0) first_in_run = FALSE;
					pcalc_prop *ex = pl->next;
					while ((ex) && (CreationPredicates::is_calling_up_atom(ex))) ex = ex->next;
					if (ex) {
						switch(ex->element) {
							case NEGATION_OPEN_ATOM:
							case NEGATION_CLOSE_ATOM:
							case QUANTIFIER_ATOM:
							case DOMAIN_OPEN_ATOM:
							case DOMAIN_CLOSE_ATOM:
								last_in_run = TRUE;
								break;
							default:
								last_in_run = FALSE;
								break;
						}
					}
					@<Compile code to test the atom@>;
				}
				break;
			}
		}
	}
	@<End a run of predicate-like conditions, if one is under way@>;

@h Predicate runs and their negations.
Or, cheating Professor de Morgan.

If we have a run of predicate-like atoms -- say X, Y, Z -- then this amounts
to a conjunction: $X\land Y\land Z$. The obvious way to compile code for this
would be to take one term at a time:
= (text)
	if (X)
	    if (Y)
	        if (Z)
=
That satisfies the Invariant, and is clearly correct. But we want to use the
same mechanism when looking at a negation, and then it would go wrong.

Note that if $\phi$ contains $\lnot(\psi)$ then $\psi$ must be a
conjunction of predicate-like atoms. (Otherwise a problem message would be
issued and in that case it doesn't matter what code we compile, so long as
we don't crash: it will never be run.) Thus we can assume that between
|NEGATION_OPEN_ATOM| and |NEGATION_CLOSE_ATOM| is a predicate run.

Between negation brackets, then, we must interpret X, Y, Z as
$\lnot(X\land Y\land Z)$, and we need to compile that to
= (text)
	if (~~(X && Y && Z))
=
rather than
= (text)
	if (~~X)
	    if (~~Y)
	        if (~~Z)
=
which gets de Morgan's laws wrong.

@ That means a little fancy footwork to start and finish the compound |if|
statement properly:

@<Compile code to test the atom@> =
	if (first_in_run) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();

		if (R_stack[R_sp-1].parity == FALSE) {
			EmitCode::inv(NOT_BIP);
			EmitCode::down();
		}
	}
	if (last_in_run == FALSE) {
		EmitCode::inv(AND_BIP);
		EmitCode::down();
	}
	CompileAtoms::code_to_perform(TEST_ATOM_TASK, pl);

@<End a run of predicate-like conditions, if one is under way@> =
	if (run_of_conditions > 0) {
		while (run_of_conditions > 1) { EmitCode::up(); run_of_conditions--; }
		if (R_stack[R_sp-1].parity == FALSE) { EmitCode::up(); }
		run_of_conditions = 0;
		@<Open a block in the Inter code compiled to perform the search, if variant@>;
	}

@ The |NOW_ASSERTION_DEFER| reason is different from all of the others,
because rather than searching for a given situation it tries force it to
happen (or not to). Forcing rather than testing is easy here: we just supply
a different task when calling //CompileAtoms::code_to_perform//.

In the negated case, we again cheat de Morgan, by falsifying $\phi$ more
aggressively than we need: we force $\lnot(X)\land\lnot(Y)\land\lnot(Z)$ to
be true, though strictly speaking it would be enough to falsify X alone.
(We do it that way for consistency with the same convention when asserting
about the model world.) But we don't need to consider runs of predicates for
that; we can take the atoms one at a time.

@<Compile code to force the atom@> =
	CompileAtoms::code_to_perform(
		(R_stack[R_sp-1].parity)?NOW_ATOM_TRUE_TASK:NOW_ATOM_FALSE_TASK, pl);

@h Quantifiers and the Q-stack.
It remains to deal with quantifiers, and to show that the Invariant is
preserved by them. There are two cases: $\exists$, and everything else.

The existence case is the easiest. Given $\exists v: \psi(v)$ we compile
= (text)
	loop header for v to run through its domain set {
	    ...
=
arranging that execution reaches the start of the loop body once for each
possible choice of $v$, as required by the Invariant.

@<Compile a loop through possible values of the variable quantified@> =
	int level_back_to = EmitCode::level();
	pl = DeferredPropositions::compile_loop_header(
		pl->terms[0].variable, var_ix_lv[pl->terms[0].variable],
		pl,
		(R_stack[R_sp-1].reason == NOW_ASSERTION_DEFER)?TRUE:FALSE,
		(quant != exists_quantifier)?TRUE:FALSE, pdef);
	@<Open a block in the Inter code compiled to perform the search@>;

@ Generalised quantifiers -- "at least three", "all but four", and
so on -- make quantitative statements about the number of valid or invalid
cases over a domain set. These need more elaborate code. Suppose we have
$\phi = Q v\in\lbrace v\mid\psi(v)\rbrace: \theta(v)$, which in memory
looks like this:
= (text)
	QUANTIFIER --> DOMAIN_OPEN --> psi --> DOMAIN_CLOSE --> theta
=
We compile that to code in the following shape:
= (text)
	set count of domain size to 0
	set count of valid cases to 0
	loop header for v to run through its domain set {
	    if psi holds {
	        increment count of domain size
	        if theta holds {
	            increment count of valid cases
	        }
	    }
	}
	if the counts are such that the quantifier is satisfied {
	    ...
=
We don't always need both counts. For instance, to handle "at least three
doors are unlocked" we count both the domain size (the number of doors)
and the number of valid cases (the number of unlocked doors), but only need
the latter. This might be worth optimising some day, to save local variables.

@ The domain size and valid case counts are stored in locals called |qcn_N|
and |qcy_N| respectively, where |N| is the index of the quantifier -- 0 for
the first one in the proposition, 1 for the second and so on.

On reading a non-existence |QUANTIFIER| atom, we compile code to zero the
counts, and push details of the quantifier onto the Q-stack, so that we
can recover them later. We then compile a loop header exactly as above.

The test of $\psi$, which acts as a filter on the domain set -- e.g.,
only doors, not all objects -- is handled by pushing a suitable goal onto
the R-stack, but we don't need to do anything to make that happen here,
because the |DOMAIN_OPEN| atom does it.

@<Push the Q-stack@> =
	if (R_stack[R_sp-1].reason == NOW_ASSERTION_DEFER)
		@<Handle "not exists" as "for all not"@>;

	Q_stack[Q_sp].quant = quant;
	Q_stack[Q_sp].parameter = param;
	Q_stack[Q_sp].L_stack_level = L_sp;
	Q_stack[Q_sp].C_stack_level = C_sp;
	Q_stack[Q_sp].existential = FALSE;
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, qcy_s[Q_sp]);
		EmitCode::val_number(0);
	EmitCode::up();
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, qcn_s[Q_sp]);
		EmitCode::val_number(0);
	EmitCode::up();

	Q_sp++;

@ Existential quantifiers are not pushed to the Q-stack, because they are
by definition about finding the first solution, not counting solutions. But
we need to record their presence anyway:

@<Mark the Q-stack to show an inner existential quantifier is in play@> =
	if (Q_sp > 0) Q_stack[Q_sp-1].existential = TRUE;

@ It is always true that $\not\exists x: \psi(x)$ is equivalent to $\forall x:
\lnot(\phi(x))$, so the following seems pointless. We do this, in the case
of "now" only, in order to make $\not\exists$ legal in a "now", which
it otherwise wouldn't be. Most quantifiers aren't, because they are too vague:
"now fewer than six doors are open", for instance, is not allowed. But we
do want to allow "now nobody likes Mr Wickham", say, which asserts
$\not\exists x: {\it person}(x)\land{\it likes}(x, W)$.

@<Handle "not exists" as "for all not"@> =
	if (quant == not_exists_quantifier) {
		R_stack[R_sp-1].parity = (R_stack[R_sp-1].parity)?FALSE:TRUE;
		quant = for_all_quantifier;
	}

@ To resume the narrative of what happens when we read:
= (text)
	QUANTIFIER --> DOMAIN_OPEN --> psi --> DOMAIN_CLOSE --> theta
=
We zeroed the counters, compiled the loop headers and pushed details to the
Q-stack at the |QUANTIFIER| atom; pushed a filtering goal onto the R-stack
at the |DOMAIN_OPEN| atom; popped it again as accomplished at |DOMAIN_CLOSE|,
compiling a line which increments the domain size to celebrate; and then
compiled code to test $\theta$.

Now we are at the end of the line, and still have the quantifier code
half-done, as we know because the Q-stack is not empty. We first compile
an increment of the valid cases count, because if execution of the Inter
code gets to the end of testing $\theta$ then it must have found a valid
case: in the "at least three doors are unlocked" example, it will have
found an unlocked one among the doors making up the domain. We then need
to record any "called" values for later retrieval by whoever called
this proposition function: see below. That leaves just this part:
= (text)
	        }
	    }
	}
	if the counts are such that the quantifier is satisfied {
	    ...
=
left to compile, and we will be done: execution will reach the |...| if and
only if it is true at run-time that three or more of the doors is unlocked.

Thus this elaborate generalised-quantifier case satisfies the Invariant
because it transfers execution from before to |...| either 0 times (if the
counts don't satisfy us), or once. Unlike in the $\exists v$ case, it's
not a question of enumerating which $v$ work and which do not; the whole
thing works, or doesn't, and is more like testing a single |if|.

@<Pop the Q-stack@> =
	if (Q_sp <= 0) internal_error("Q stack underflow");
	Q_sp--;
	@<Count this as a success@>;

	while (C_sp > Q_stack[Q_sp].C_stack_level)
		@<Pop the C-stack@>;

	while (L_sp > Q_stack[Q_sp].L_stack_level)
		@<Pop the L-stack@>;

	EmitCode::inv(IF_BIP);
	EmitCode::down();
	Quantifiers::emit_test(Q_stack[Q_sp].quant, Q_stack[Q_sp].parameter, qcy_s[Q_sp], qcn_s[Q_sp]);
	@<Open a block in the Inter code compiled to perform the search, if variant@>;

@ Note that if there is an existential quantifier inside the quantifier we
are counting solutions for, then we halt the search as soon as a solution is found;
we don't want to rack up |qcy_s[Q_sp]| to artificially high levels by finding
multiple solutions. See test case |CountInnerExistential|.

@<Count this as a success@> =
	EmitCode::inv(POSTINCREMENT_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, qcy_s[Q_sp]);
	EmitCode::up();
	if (Q_stack[Q_sp].existential)
		EmitCode::inv(BREAK_BIP);

@h The C-stack.
When a CALLED atom in the proposition gives a name to a variable, we have to
transcribe that to the stash of callings for the benefit of the code
calling this proposition function. Each time we discover that a term $t$ is
to be given a name, we stack it up. These are not always variables:

>> if a person (called the dupe) is in a dark room (called the lair), ...

gives names to $x$ ("dupe") and $f_{\it in}(x)$ ("lair"), because
simplification has eliminated the variable $y$ which appears to be being
given a name.

@<Push the C-stack@> =
	if (C_sp >= C_STACK_CAPACITY) internal_error("C-stack overflow");
	C_stack[C_sp].term = pl->terms[0];
	C_stack[C_sp].stash_index = no_deferred_callings++;
	C_sp++;

@ When does the compiled search code record values into the stash of callings?
In two situations:

(a) when a domain-search has successfully found a viable case for a quantifier,
the values of any variables called in that domain are recorded;
(b) and otherwise the values of called variables are recorded just before
point |M|, that is, immediately before acting on a successful match.

For example, when reading:

>> if a person (called the dupe) is in a lighted room which is adjacent to exactly one dark room (called the lair), ...

the value of "dupe" is transferred just before |M|, but the value of "lair"
is transferred as soon as a dark room is found. The code looks like this:
= (text)
	set count of domain size to 1
	loop through domain (i.e., dark rooms adjacent to the person's location) {
	    increment count of domain size
	    record the lair value
	}
	if the count of domain size is 1 {
	    record the dupe value
	    M
	}
=
If we waited until point |M| to record the lair value, it would have disappeared,
because |M| is outside the loop which searches the domain of the "exactly one"
quantifier.

@<Pop the C-stack@> =
	if (C_sp <= 0) internal_error("C stack underflow");
	C_sp--;
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::reference();
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, LocalParking::callings());
				EmitCode::val_number((inter_ti) C_stack[C_sp].stash_index);
			EmitCode::up();
		EmitCode::up();
		CompileSchemas::compile_term(C_stack[C_sp].term, K_value, TRUE);
	EmitCode::up();

@ Opening a block is the same thing as pushing to the L-stack:

@<Open a block in the Inter code compiled to perform the search@> =
	if (L_sp >= L_STACK_CAPACITY) internal_error("L-stack overflow");
	L_stack[L_sp].level = level_back_to;
	L_sp++;

@ Not for a loop body:

@<Open a block in the Inter code compiled to perform the search, if variant@> =
	if (L_sp >= L_STACK_CAPACITY) internal_error("L-stack overflow");
	L_stack[L_sp].level = EmitCode::level()-1;
	EmitCode::code();
	EmitCode::down();
	L_sp++;

@ Close a block in the Inter code compiled to perform the search:

@<Pop the L-stack@> =
	if (L_sp <= 0) internal_error("L-stack underflow");
	while (EmitCode::level() > L_stack[L_sp-1].level) EmitCode::up();
	L_sp--;

@h Adaptations.
That completes the general pattern of searching according to the proposition's
instructions. It remains to adapt it to different needs, by providing, in
each case, some setting-up code; some code to execute when a viable set
of variable values is found; and some winding-up code.

In some of the cases, additional local variables are needed within the
|Prop_N| function, to keep track of counters or totals. These are they:

@<Declare the Inter locals needed by adaptations to particular deferral cases@> =
	if (multipurpose_function) {
		total_s = LocalVariables::new_internal_as_symbol(I"total");
		counter_s = LocalVariables::new_internal_as_symbol(I"counter");
		selection_s = LocalVariables::new_internal_as_symbol(I"selection");
		best_s = LocalVariables::new_internal_as_symbol(I"best");
		best_with_s = LocalVariables::new_internal_as_symbol(I"best_with");
	} else {
		switch (pdef->reason) {
			case NUMBER_OF_DEFER:
				counter_s = LocalVariables::new_internal_as_symbol(I"counter");
				break;
			case RANDOM_OF_DEFER:
				counter_s = LocalVariables::new_internal_as_symbol(I"counter");
				selection_s = LocalVariables::new_internal_as_symbol(I"selection");
				break;
			case TOTAL_DEFER:
				total_s = LocalVariables::new_internal_as_symbol(I"total");
				break;
			case TOTAL_REAL_DEFER:
				total_s = LocalVariables::new_internal_as_symbol(I"total");
				break;
			case LIST_OF_DEFER:
				counter_s = LocalVariables::new_internal_as_symbol(I"counter");
				total_s = LocalVariables::new_internal_as_symbol(I"total");
				break;
			case EXTREMAL_DEFER:
				best_s = LocalVariables::new_internal_as_symbol(I"best");
				best_with_s = LocalVariables::new_internal_as_symbol(I"best_with");
				break;
		}
	}

@<Declare the Inter call parameters needed by adaptations to particular deferral cases@> =
	if ((!multipurpose_function) && (pdef->reason == LIST_OF_DEFER)) {
		list_s = LocalVariables::new_other_as_symbol(I"list");
		strong_kind_s = LocalVariables::new_other_as_symbol(I"strong_kind");
	}

@h Adaptation to CONDITION.
The first and simplest of our cases to understand: where $\phi$ is a sentence,
with all variables bound, and we have to return |true| if it is true and
|false| if it is false. There is no initialisation:

@<Initialisation before CONDITION search@> =
	;

@ As soon as we find any valid combination of the variables, we return |true|:

@<Act on successful match in CONDITION search@> =
	EmitCode::rtrue();

@ So we only reach winding-up if every case failed, and then we return |false|:

@<Winding-up after CONDITION search@> =
	EmitCode::rfalse();

@h Adaptation to NUMBER.
In the remaining cases, $\phi$ has variable $x$ (only) left free, but the use
we want to make will be a loop over all objects $x$, and we compile this
"outer loop" here: the loop opens in the initialisation code, closes in
the winding-up code, and therefore completely encloses the code generated
by the searching mechanism above.

In the first case, we want to count the number of $x$ for which $\phi(x)$
is true. The local |counter| holds the count so far; it starts out automatically
at 0, since all Inter locals do.

@<Initialisation before NUMBER search@> =
	proposition = DeferredPropositions::compile_loop_header(0, var_ix_lv[0],
		proposition, FALSE, FALSE, pdef);

@ Recall that we get here for each possible way that $\phi(x)$ could
be true, that is, once for each viable set of values of bound variables in
$\phi$. But we only want to increment |counter| once, so having done so, we
exit the searching code and continue the outer loop.

The |jump| to a label is forced on us since Inter, unlike, say, Perl, has no
syntax to break or continue a loop other than the innermost one.

@<Act on successful match in NUMBER search@> =
	EmitCode::inv(POSTINCREMENT_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, counter_s);
	EmitCode::up();

	@<Jump to next outer loop for this reason@>;

@<Jump to next outer loop for this reason@> =
	if (NextOuterLoop_labels[reason] == NULL) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".NextOuterLoop_%d", reason);
		NextOuterLoop_labels[reason] = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)
	}
	EmitCode::inv(JUMP_BIP);
	EmitCode::down();
		EmitCode::lab(NextOuterLoop_labels[reason]);
	EmitCode::up();

@<Place next outer loop label@> =
	if (NextOuterLoop_labels[reason] == NULL) {
		TEMPORARY_TEXT(L)
		WRITE_TO(L, ".NextOuterLoop_%d", reason);
		NextOuterLoop_labels[reason] = EmitCode::reserve_label(L);
		DISCARD_TEXT(L)
	}
	EmitCode::place_label(NextOuterLoop_labels[reason]);

@ The continue-outer-loop labels are marked with the reason number so that
if code is compiled for each reason in turn within a single function -- which
is what we do for multipurpose deferred propositions -- the labels do
not have clashing names.

@<Winding-up after NUMBER search@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, counter_s);
	EmitCode::up();

@h Adaptation to LIST.
In the next case, we want to form the list of all $x$ for which $\phi(x)$
is true. The local |list| holds the list so far, and already exists.

@<Initialisation before LIST search@> =
	EmitCode::call(Hierarchy::find(WRITEPVFIELD_HL));
	EmitCode::down();
		EmitCode::val_symbol(K_value, list_s);
		EmitCode::val_iname(K_value, Hierarchy::find(LIST_ITEM_KOV_F_HL));
		EmitCode::val_symbol(K_value, strong_kind_s);
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, total_s);
		EmitCode::call(Hierarchy::find(LIST_OF_TY_GETLENGTH_HL));
		EmitCode::down();
			EmitCode::val_symbol(K_value, list_s);
		EmitCode::up();
	EmitCode::up();

	proposition = DeferredPropositions::compile_loop_header(0, var_ix_lv[0],
		proposition, FALSE, FALSE, pdef);

@ Recall that we get here for each possible way that $\phi(x)$ could
be true, that is, once for each viable set of values of bound variables in
$\phi$. But we only want to increment |counter| once, so having done so, we
exit the searching code and continue the outer loop.

The |jump| to a label is forced on us since Inter, unlike, say, Perl, has no
syntax to break or continue a loop other than the innermost one.

@<Act on successful match in LIST search@> =
	EmitCode::inv(POSTINCREMENT_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, counter_s);
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, counter_s);
			EmitCode::val_symbol(K_value, total_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, total_s);
				EmitCode::inv(PLUS_BIP);
				EmitCode::down();
					EmitCode::inv(TIMES_BIP);
					EmitCode::down();
						EmitCode::val_number(3);
						EmitCode::inv(DIVIDE_BIP);
						EmitCode::down();
							EmitCode::val_symbol(K_value, total_s);
							EmitCode::val_number(2);
						EmitCode::up();
					EmitCode::up();
					EmitCode::val_number(8);
				EmitCode::up();
			EmitCode::up();

			EmitCode::call(Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
			EmitCode::down();
				EmitCode::val_symbol(K_value, list_s);
				EmitCode::val_symbol(K_value, total_s);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::call(Hierarchy::find(WRITEPVFIELD_HL));
	EmitCode::down();
		EmitCode::val_symbol(K_value, list_s);
		EmitCode::inv(MINUS_BIP);
		EmitCode::down();
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, counter_s);
				EmitCode::val_iname(K_value, Hierarchy::find(LIST_ITEM_BASE_HL));
			EmitCode::up();
			EmitCode::val_number(1);
		EmitCode::up();
		EmitCode::val_symbol(K_value, var_s[0]);
	EmitCode::up();

	@<Jump to next outer loop for this reason@>;

@ The continue-outer-loop labels are marked with the reason number so that
if code is compiled for each reason in turn within a single function -- which
is what we do for multipurpose deferred propositions -- the labels do
not have clashing names.

@<Winding-up after LIST search@> =
	EmitCode::call(Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	EmitCode::down();
		EmitCode::val_symbol(K_value, list_s);
		EmitCode::val_symbol(K_value, counter_s);
	EmitCode::up();

	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, list_s);
	EmitCode::up();

@h Adaptation to RANDOM.
To choose a random $x$ such that $\phi(x)$, we essentially run the same code
as for NUMBER searches, but twice over: first to count how many such $x$ there
are, then to run through again to find the $n$th of these, where $n$ is a
uniformly random number such that $1\leq n\leq x$.

This avoids needing to store the full list of matches anywhere, which would
be impossible since (a) it's potentially a lot of storage and (b) it can
only safely live on the current stack frame, and Inter does not allow arrays
on the current stack frame (because of restrictions in the Z-machine).
This means that, on average, the compiled code takes 50\% longer to find
its random $x$ than it ideally would, but we accept the trade-off.

@<Initialisation before RANDOM search@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, selection_s);
		EmitCode::val_number((inter_ti) -1);
	EmitCode::up();

	EmitCode::inv(WHILE_BIP);
	EmitCode::down();
		EmitCode::val_true();
		EmitCode::code();
		EmitCode::down();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, counter_s);
		EmitCode::val_number(0);
	EmitCode::up();

	proposition = DeferredPropositions::compile_loop_header(0, var_ix_lv[0],
		proposition, FALSE, FALSE, pdef);

@ Again we exit the searcher as soon as a match is found, since that guarantees
that $\phi(x)$.

Note that we can only return here on the second pass, since |selection| is $-1$
throughout the first pass, whereas |counter| is non-negative.

@<Act on successful match in RANDOM search@> =
	EmitCode::inv(POSTINCREMENT_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, counter_s);
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, counter_s);
			EmitCode::val_symbol(K_value, selection_s);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, var_s[0]);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	@<Jump to next outer loop for this reason@>;

@ We return |nothing| -- the non-object -- if |counter| is zero, since that
means the set of possible $x$ is empty. But we also return if |selection|
has been made already, because that means that the second pass has been
completed without a return -- something which in theory cannot happen, but
just might do if testing part of the proposition had some side-effect changing
the state of the objects and thus the size of the set of possibilities.

@<Winding-up after RANDOM search@> =
	EmitCode::down();
	EmitCode::down();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(OR_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, counter_s);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::inv(GE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, selection_s);
				EmitCode::val_number(0);
			EmitCode::up();
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();
				EmitCode::val_nothing();
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, selection_s);
		EmitCode::inv(RANDOM_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, counter_s);
		EmitCode::up();
	EmitCode::up();

@h Adaptation to TOTAL.
Here the task is to sum the values of property $P$ attached to each object
in the domain $\lbrace x\mid \phi(x)\rbrace$.

@<Initialisation before TOTAL search@> =
	proposition = DeferredPropositions::compile_loop_header(0, var_ix_lv[0],
		proposition, FALSE, FALSE, pdef);

@<Initialisation before TOTAL REAL search@> =
	proposition = DeferredPropositions::compile_loop_header(0, var_ix_lv[0],
		proposition, FALSE, FALSE, pdef);

@ The only wrinkle here is the way the compiled code knows which property it
should be totalling. If we know that ourselves, we can compile in a direct
reference. But if we are compiling a multipurpose deferred proposition, then
it might be used to total any property over the domain, and we won't know
which until runtime -- when its identity will be found in the Inter variable
|property_to_be_totalled|.

@<Act on successful match in TOTAL search@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, total_s);
		EmitCode::inv(PLUS_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, total_s);
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_symbol(K_value, var_s[0]);
				if (multipurpose_function) {
					EmitCode::val_iname(K_value,
						Hierarchy::find(PROPERTY_TO_BE_TOTALLED_HL));
				} else {
					prn = RETRIEVE_POINTER_property(pdef->defn_ref);
					EmitCode::val_iname(K_value, RTProperties::iname(prn));
				}
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	@<Jump to next outer loop for this reason@>;

@<Act on successful match in TOTAL REAL search@> =
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::ref_symbol(K_value, total_s);
		EmitCode::call(Hierarchy::find(REAL_NUMBER_TY_PLUS_HL));
		EmitCode::down();
			EmitCode::val_symbol(K_value, total_s);
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_symbol(K_value, var_s[0]);
				if (multipurpose_function) {
					EmitCode::val_iname(K_value,
						Hierarchy::find(PROPERTY_TO_BE_TOTALLED_HL));
				} else {
					prn = RETRIEVE_POINTER_property(pdef->defn_ref);
					EmitCode::val_iname(K_value, RTProperties::iname(prn));
				}
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	@<Jump to next outer loop for this reason@>;

@<Winding-up after TOTAL search@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, total_s);
	EmitCode::up();

@<Winding-up after TOTAL REAL search@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, total_s);
	EmitCode::up();

@h Adaptation to EXTREMAL.
This is rather similar. We find the member of $\lbrace x\mid \phi(x)\rbrace$
which either minimises, or maximises, the value of some property $P$. We use
two local variables: |best|, the extreme $P$ value found so far; and |best_with|,
the member of the domain set which achieves that.

If two or more $x$ achieve the optimal $P$-value, it is deliberately left
undefined which one is returned. The user may be typing "the heaviest thing
on the table", but what he gets is "a heaviest thing on the table".

We open the search with |best_with| equal to |nothing|, the non-object, which
is what we will return if the domain set turns out to be empty; and with
|best| set to the furthest-from-optimal value possible. For a search maximising
$P$, |best| starts at the lowest number representable in the virtual machine;
for a minimisation, it starts at the highest. That way, if any member of the
domain is found, its $P$-value must be at least as good as the starting
value of |best|.

Again the only nuisance is that sometimes we know $P$, and whether we are
maximising or minimising, at compile time; but for a multipurpose function
we don't, and have to look that up at run-time.

@<Initialisation before EXTREMAL search@> =
	if (multipurpose_function) {
		EmitCode::inv(IFELSE_BIP);
		EmitCode::down();
			EmitCode::inv(GT_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value,
					Hierarchy::find(PROPERTY_LOOP_SIGN_HL));
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, best_s);
					EmitCode::val_iname(K_value,
						Hierarchy::find(MIN_NEGATIVE_NUMBER_HL));
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, best_s);
					EmitCode::val_iname(K_value,
						Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		measurement_definition *mdef =
			RETRIEVE_POINTER_measurement_definition(pdef->defn_ref);
		Measurements::read_property_details(mdef, &def_prn, &def_prn_sign);
		if (def_prn_sign == 1) {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, best_s);
				EmitCode::val_iname(K_value,
					Hierarchy::find(MIN_NEGATIVE_NUMBER_HL));
			EmitCode::up();
		} else {
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, best_s);
				EmitCode::val_iname(K_value,
					Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
			EmitCode::up();
		}
	}
	proposition = DeferredPropositions::compile_loop_header(0, var_ix_lv[0],
		proposition, FALSE, FALSE, pdef);

@ It might look as if we could speed up the multipurpose case by
multiplying by |property_loop_sign|, thus combining the max and min
versions into one, and saving an |if|. But (a) the multiplication is as
expensive as the |if| (remember that on a VM there's no real branch
penalty), and (b) we need to watch out because $-1$ times $-32768$, on a
16-bit machine, is $-1$, not $32768$: so it is not always true that
multiplying by $-1$ is order-reversing.

@<Act on successful match in EXTREMAL search@> =
	if (multipurpose_function) {
		EmitCode::inv(IFELSE_BIP);
		EmitCode::down();
			EmitCode::inv(GT_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value,
					Hierarchy::find(PROPERTY_LOOP_SIGN_HL));
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(GE_BIP);
					EmitCode::down();
						@<Emit code for a property lookup@>;
						EmitCode::val_symbol(K_value, best_s);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, best_s);
							@<Emit code for a property lookup@>;
						EmitCode::up();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, best_with_s);
							EmitCode::val_symbol(K_value, var_s[0]);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(IF_BIP);
				EmitCode::down();
					EmitCode::inv(LE_BIP);
					EmitCode::down();
						@<Emit code for a property lookup@>;
						EmitCode::val_symbol(K_value, best_s);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, best_s);
							@<Emit code for a property lookup@>;
						EmitCode::up();
						EmitCode::inv(STORE_BIP);
						EmitCode::down();
							EmitCode::ref_symbol(K_value, best_with_s);
							EmitCode::val_symbol(K_value, var_s[0]);
						EmitCode::up();
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			if (def_prn_sign == 1) EmitCode::inv(GE_BIP);
			else EmitCode::inv(LE_BIP);
			EmitCode::down();
				@<Emit code for a property lookup@>;
				EmitCode::val_symbol(K_value, best_s);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, best_s);
					@<Emit code for a property lookup@>;
				EmitCode::up();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_symbol(K_value, best_with_s);
					EmitCode::val_symbol(K_value, var_s[0]);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}

@<Emit code for a property lookup@> =
	EmitCode::inv(PROPERTYVALUE_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
		EmitCode::val_symbol(K_value, var_s[0]);
		if (multipurpose_function) {
			EmitCode::val_iname(K_value,
				Hierarchy::find(PROPERTY_TO_BE_TOTALLED_HL));
		} else {
			EmitCode::val_iname(K_value,
				RTProperties::iname(def_prn));
		}
	EmitCode::up();

@<Winding-up after EXTREMAL search@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, best_with_s);
	EmitCode::up();

@h Adaptation to LOOP.
Here the proposition is used to iterate through the members of the domain
set $\lbrace x\mid \phi(x)\rbrace$. Two local variables exist: |x| and |x_ix|.
One of the following is true:

(1) The domain set contains only objects, so that |x| is non-zero if it
represents a member of that set. In this case |x_ix| may or may not be used,
and we will not rely on it.
(2) The domain set contains only values, and then |x| might easily be zero,
but |x_ix| is always the index within the domain set: 1 if |x| is the first
value, 2 for the second and so on.

The proposition is called with a pair of values |x|, |x_ix| and returns
the next value |x| in the domain set, or 0 if the domain is exhausted. (In
case (2) it's not safe to regard 0 as an end-of-set sentinel value because
0 can be a valid member of the set; so in looping through (2) we should
first find the size of the set using NUMBER OF, then keep calling for
members until the index reaches the size.) There is no need to return the
next |x_ix| value since it is always the present value plus 1.

If the proposition is called with |x| set to |nothing|, in case (1), or
with |x_ix| equal to 0, in case (2), it returns the first value in the
domain.

@ Snarkily, this is how we do it:
= (text)
	if we're called with a valid member of the domain, go to Z
	loop x over members of the domain {
	    return x
	    label Z is here
	}
=
Which is not really a loop at all, but is a cheap way to extract either the
initial value or the successor value from a loop header.[1]

[1] This trick caused some consternation for I6 hackers when early drafts of
I7 came out, because they had been experimenting with a patch to I6 which
protected |objectloop| from object-tree rearrangements but which assumed that
nobody ever used |jump| to enter a loop body bypassing its header. But the DM4,
which defines I6, does not forbid this, and nor does Inter.

@<Initialisation before LOOP search@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, var_ix_s[0]);
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(POSTDECREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, var_ix_s[0]);
			EmitCode::up();
			@<Jump to next outer loop for this reason@>;
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, var_s[0]);
		EmitCode::code();
		EmitCode::down();
			@<Jump to next outer loop for this reason@>;
		EmitCode::up();
	EmitCode::up();

	proposition = DeferredPropositions::compile_loop_header(0, var_ix_lv[0], proposition,
		FALSE, FALSE, pdef);

@<Act on successful match in LOOP search@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, var_s[0]);
	EmitCode::up();

@<Winding-up after LOOP search@> =
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_nothing();
	EmitCode::up();

@h Compiling loop headers.
The final task of this entire chapter is to compile an Inter loop header which
causes a given variable $v$ to range through a domain set $D$ -- which we
have to deduce by looking at the proposition $\psi$ in front of us.

We want this loop to run as quickly as possible: efficiency here makes a very
big difference to the running time of compiled I7 code. Consider compiling
"everyone in the Dining Room can see an animal". Code like this would run very
slowly:
= (text)
	loop over objects (x)
	    loop over objects (y)
	        if x is a person
	            if x is in the Dining Room
	                if y is an animal
	                    if x can see y
	                        success!
=
This is folly in so many ways. Most objects are not people or animals, so
almost all combinations of $x$ and $y$ are wasted. We test the eligibility
of $x$ for every possible $y$. And there are quick ways to find what is in
the Dining Room, so we're missing a trick there, too. What we want is:
= (text)
	loop over objects in the Dining Room (x)
	    if x is a person
	        loop over animals (y)
	            if x can see y
	                success!
=
@ Part of the work is done already: we generate propositions with
quantifiers as far forwards as they can be, so we won't loop over $y$ before
checking the validity of $x$. The rest of the work comes from two basic
optimisations:

(1) "Kind optimisation." If a loop over $v$ is such that $K(v)$ holds in every case,
where $K$ is a kind, then loop $v$ over $K$ rather than all objects, and
(2) "Parent optimisation." If a loop over $v$ is such that $R(v, t)$ holds in
every case, then loop over all $v$ such that $R(v, t)$ in cases where $R$ has a
run-time representation making this quick and easy.

In either case we can then delete $K(v)$ or $R(v, t)$ from the proposition
as redundant, since the loop header has taken care of it. "Parent optimisation"
is so called because the original use of this was to do with the IF world model's
containment tree, where one object containing another is called its "parent"; but
in fact it can be applied to any suitable relation $R$.

Parent optimisation cannot be used if we are compiling code to force a proposition,
rather than test it, because then $R(v, t)$ is not an accomplished fact but is
something we have yet to make come true. This is why the function below needs a
flag |avoid_parent_optimisation|. Case (1) doesn't suffer from this since
kinds cannot be changed at run-time.

=
i6_schema loop_schema;
pcalc_prop *DeferredPropositions::compile_loop_header(int var, local_variable *index_var,
	pcalc_prop *proposition,
	int avoid_parent_optimisation, int grouped, pcalc_prop_deferral *pdef) {

	kind *K = NULL;
	pcalc_prop *kind_position = NULL;
	pcalc_term var_term = Terms::new_variable(var);
	pcalc_term second_term = Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, index_var));

	int parent_optimised = FALSE;

	/* the default, if we are unable to provide either kind or parent optimisation */
	Calculus::Schemas::modify(&loop_schema, "objectloop (*1 ofclass Object)");

	@<Scan the proposition to find the domain of the loop, and look for opportunities@>;

	if ((K) && (parent_optimised == FALSE)) { /* parent optimisation is stronger, so we prefer that */
		if (CompileLoops::schema(&loop_schema, K) == FALSE) {
			if (pdef->rtp_iname == NULL)
				pdef->rtp_iname =
					Hierarchy::make_iname_in(RTP_HL, InterNames::location(pdef->ppd_iname));
			Calculus::Schemas::modify(&loop_schema, "if (IssueIterationRTP(%n))",
				pdef->rtp_iname);
		}
		proposition = Propositions::delete_atom(proposition, kind_position);
	}

	CompileSchemas::from_terms_in_void_context(&loop_schema, &var_term, &second_term);

	return proposition;
}

@ The following looks more complicated than it really is. Sometimes it's
called to compile a loop arising from a quantifier with a domain, in
which case |grouped| is set and |proposition| points to:
= (text)
	QUANTIFIER --> DOMAIN_OPEN --> psi --> DOMAIN_CLOSE --> ...
=
so that $\psi$, the part in the domain group, defines the range of the
variable. But sometimes the call is to compile a loop not arising from a
quantifier, so there is no domain group to scan; instead the whole
proposition makes up $\psi$, and now |grouped| is clear.

@<Scan the proposition to find the domain of the loop, and look for opportunities@> =
	int bl = 0, enabled = FALSE;
	TRAVERSE_VARIABLE(pl);
	TRAVERSE_PROPOSITION(pl, proposition) {
		if (Atoms::is_opener(pl->element)) bl++;
		if (Atoms::is_closer(pl->element)) bl--;
		if (grouped) {
			if (pl->element == DOMAIN_OPEN_ATOM) enabled = TRUE;
			if (pl->element == DOMAIN_CLOSE_ATOM) enabled = FALSE;
			if (bl < 0) break;
			if (enabled == FALSE) continue;
			if (bl != 1) continue;
		} else {
			if (bl < 0) break;
			if (bl > 0) continue;
		}
		@<Scan the part of the proposition establishing the domain@>;
	}

@ In either case, we scan $\psi$ looking for $K(v)$ atoms, which would tell
us the domain set for the variable $v$, or for $R(v, t)$ atoms for
parent-optimisable relations $R$.

@<Scan the part of the proposition establishing the domain@> =
	if ((KindPredicates::is_kind_atom(pl)) && (pl->terms[0].variable == var)) {
		K = KindPredicates::get_kind(pl);
		kind_position = pl_prev;
	}

	if ((avoid_parent_optimisation == FALSE) &&
		(pl->element == PREDICATE_ATOM) && (pl->arity == 2))
		@<Consider parent optimisation on this binary predicate@>;

@ We give the relation $R$ an opportunity to write a loop which runs $v$
through all possible $x$ such that $R(x, t)$, by writing a schema for the
loop in which |*1| denotes the variable $v$ and |*2| the term $t$.

For example, the worn-by relation writes the schema:
= (text)
	objectloop (*1 in *2) if (WearerOf(*1)==parent(*1))
=
where $v$ runs quickly through the object-tree children of $t$, but items
carried rather than worn are skipped.

We have to check three possible cases: $R(v, t)$ direct, and then
${\it is}(f_R(v), t)$ or ${\it is}(t, f_R(v))$, which can arise from
simplifications. We set |optimise_on| to $R$ and |parent| to $t$.

@<Consider parent optimisation on this binary predicate@> =
	binary_predicate *bp = RETRIEVE_POINTER_binary_predicate(pl->predicate);
	if (bp == R_equality) {
		int chk;
		for (chk=0; chk<=1; chk++) {
			pcalc_func *pf = pl->terms[chk].function;
			if ((pf) && (pf->fn_of.variable == var) &&
				(BinaryPredicates::write_optimised_loop_schema(&loop_schema, pf->bp))) {
				second_term = pl->terms[1-chk];
				parent_optimised = TRUE;
				proposition = Propositions::delete_atom(proposition, pl_prev);
				break;
			}
		}
	} else if ((pl->terms[0].variable == var) &&
		(BinaryPredicates::write_optimised_loop_schema(&loop_schema, bp))) {
		second_term = pl->terms[1];
		parent_optimised = TRUE;
		proposition = Propositions::delete_atom(proposition, pl_prev);
	}

@ And that finally concludes the predicate-calculus engine at the heart of Inform.
