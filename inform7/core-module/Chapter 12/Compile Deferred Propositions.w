[Calculus::Propositions::Deferred::] Compile Deferred Propositions.

To compile the I6 routines needed to perform the tests or tasks
deferred as being too difficult in their original contexts.

@h Comment.
The following compiles an I6 comment noting the reason for a deferral.

=
void Calculus::Propositions::Deferred::compile_comment_about_deferral_reason(int reason) {
	switch(reason) {
		case CONDITION_DEFER:
			Emit::code_comment(I"! True or false?"); break;
		case NOW_ASSERTION_DEFER:
			Emit::code_comment(I"! Force this to be true via 'now':"); break;
		case EXTREMAL_DEFER:
			Emit::code_comment(I"! Find the extremal x satisfying:"); break;
		case LOOP_DOMAIN_DEFER:
			Emit::code_comment(I"! Find next x satisfying:"); break;
		case LIST_OF_DEFER:
			Emit::code_comment(I"! Construct a list of x satisfying:"); break;
		case NUMBER_OF_DEFER:
			Emit::code_comment(I"! How many x satisfy this?"); break;
		case TOTAL_DEFER:
			Emit::code_comment(I"! Find a total property value over all x satisfying:"); break;
		case RANDOM_OF_DEFER:
			Emit::code_comment(I"! Find a random x satisfying:"); break;
		case MULTIPURPOSE_DEFER:
			Emit::code_comment(I"! Abstraction for set of x such that:"); break;
		default: internal_error("Unknown proposition deferral reason");
	}
}

@h Preliminaries.
We have seen that propositions are deferred for diverse reasons. Here we
take our medicine, and actually compile the deferred propositions into
routines. This is part of the phrase-compilation-coroutine process because
funny things can happen when we compile: we can create new text substitutions
which create routines which... and so on.

=
void Calculus::Propositions::Deferred::compile_remaining_deferred(void) {
	Calculus::Propositions::Deferred::compilation_coroutine();
}

pcalc_prop_deferral *latest_pcd = NULL;
int Calculus::Propositions::Deferred::compilation_coroutine(void) {
	int N = 0;
	while (TRUE) {
		pcalc_prop_deferral *pdef;
		if (latest_pcd == NULL)
			pdef = FIRST_OBJECT(pcalc_prop_deferral);
		else pdef = NEXT_OBJECT(latest_pcd, pcalc_prop_deferral);
		if (pdef == NULL) break;
		latest_pcd = pdef;
		@<Compile an individual deferred proposition@>;
		N++;
	}
	return N;
}

@ The basic structure of a proposition routine is the same for all
of the various reasons, but with considerable variations affecting (mainly)
the initial setup and the returned value.

Note that the unchecked array bounds of 26 are safe here because
propositions may only use 26 different variables at most (|x|, |y|, |z|,
|a|, ..., |w|). There therefore can't be more than 26 callings, or 26
quantifiers, either.

@d MAX_QC_VARIABLES 100

@<Compile an individual deferred proposition@> =
	pcalc_prop_deferral *save_current_pdef = current_pdef;
	current_pdef = pdef;

	int ct_locals_problem_thrown = FALSE, negated_quantifier_found = FALSE;
	current_sentence = pdef->deferred_from;
	pcalc_prop *proposition = Calculus::Propositions::copy(pdef->proposition_to_defer);
	int multipurpose_routine = (pdef->reason == MULTIPURPOSE_DEFER)?TRUE:FALSE;
	int reason = CONDITION_DEFER; /* redundant assignment to appease |gcc -O2| */

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

	LOGIF(PREDICATE_CALCULUS, "Compiling deferred proposition: %d: reason %d: $D\n",
		pdef->allocation_id, pdef->reason, proposition);

	packaging_state save = Routines::begin(pdef->ppd_iname);

	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	@<Declare the I6 local variables which will be needed by this deferral routine@>;
	@<Compile the code inside this deferral routine@>;
	@<Issue a problem message if the table-lookup locals were needed@>;
	@<Issue a problem message if a negated quantifier was needed@>;
	END_COMPILATION_MODE;

	Routines::end(save);

	if (pdef->rtp_iname) @<Compile the constant origin text for run-time problem use@>;
	current_pdef = save_current_pdef;

@ We compile the following only in cases where it seems possible that a
run-time problem message may be needed; compiling it for every deferred
proposition would be wasteful of space in the Z-machine.

@<Compile the constant origin text for run-time problem use@> =
	TEMPORARY_TEXT(COTT);
	if (pdef->deferred_from)
		WRITE_TO(COTT, "%~W", ParseTree::get_text(pdef->deferred_from));
	else
		WRITE_TO(COTT, "not sure where this came from");
	Emit::named_string_constant(pdef->rtp_iname, COTT);
	DISCARD_TEXT(COTT);

@ Just in case this hasn't already been done:

@<Simplify the proposition by flipping negated quantifiers, if possible@> =
	int changed = FALSE;
	proposition = Calculus::Simplifications::negated_determiners(proposition, &changed, TRUE);
	if (changed) {
		LOGIF(PREDICATE_CALCULUS, "Calculus::Simplifications::negated_determiners: $D\n", proposition);
	}

@ While unfortunate in a way, this is for the best, because a successful
match on a condition looking up a table would record the table and row
in local variables within the deferred proposition: they would then be
wrong in the calling routine, where they are needed.

@<Issue a problem message if the table-lookup locals were needed@> =
	if ((LocalVariables::are_we_using_table_lookup()) && (!ct_locals_problem_thrown)) {
		ct_locals_problem_thrown = TRUE;
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_CantLookUpTableInDeferred),
			"I am not able to look up table entries in this complicated "
			"condition",
			"which seems to involve making a potentially large number "
			"of checks in rather few words (and may perhaps result from "
			"a misunderstanding such as writing the name of a kind where "
			"an individual object is intended?).");
	}

@ This looks like a horrible restriction, but in fact propositions are
built and simplified in such a way that it never bites. (Quantifiers are
always moved outside of negation where possible, and it is almost always
possible.)

@<Issue a problem message if a negated quantifier was needed@> =
	if (negated_quantifier_found) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"this involves a very complicated negative thought",
			"which I'm not able to untangle. Perhaps you could rephrase "
			"this more simply, or split it into more than one sentence?");
	}

@ Recall that an I6 function header consists of a |[|, then an identifier
name for the function -- in this case always |Prop_N| for some number |N| --
and then a space-delimited list of local variable names, the initial of
which are used to receive function arguments. The order of the variables
is: any cinders (constants evaluated back at deferral time and being
handed forward on the stack as function arguments); then any variables
in the predicate calculus sense, of which the first may or may not be
being used as a function argument, depending on whether or not it is
bound; then the enumeration variables needed to compile generalised
quantifiers, if any; and finally any oddball variables needed by code
specific to particular deferral reasons.

@<Declare the I6 local variables which will be needed by this deferral routine@> =
	int j, var_states[26], no_extras;
	if (multipurpose_routine)
		reason_s = LocalVariables::add_named_call_as_symbol(I"reason"); /* no cinders exist here */
	else
		Calculus::Deferrals::Cinders::declare(proposition, pdef);

	@<Declare the I6 call parameters needed by adaptations to particular deferral cases@>;

	Calculus::Variables::determine_status(proposition, var_states, NULL);
	for (j=0; j<26; j++)
		if (var_states[j] != UNUSED_VST) {
			TEMPORARY_TEXT(letter_var);
			PUT_TO(letter_var, pcalc_vars[j]);
			var_s[j] = LocalVariables::add_internal_local_as_symbol(letter_var);
			WRITE_TO(letter_var, "_ix");
			var_ix_s[j] = LocalVariables::add_internal_local_as_symbol_noting(letter_var, &(var_ix_lv[j]));
			DISCARD_TEXT(letter_var);
		} else {
			var_s[j] = NULL;
			var_ix_s[j] = NULL;
			var_ix_lv[j] = NULL;
		}

	no_extras = 0;
	TRAVERSE_VARIABLE(pl);
	TRAVERSE_PROPOSITION(pl, proposition)
		if (pl->element == DOMAIN_OPEN_ATOM) {
			if (no_extras >= MAX_QC_VARIABLES) break;
			TEMPORARY_TEXT(q_var);
			WRITE_TO(q_var, "qcy_%d", no_extras);
			qcy_s[no_extras] = LocalVariables::add_internal_local_as_symbol(q_var);
			Str::clear(q_var);
			WRITE_TO(q_var, "qcn_%d", no_extras);
			qcn_s[no_extras] = LocalVariables::add_internal_local_as_symbol(q_var);
			DISCARD_TEXT(q_var);
			no_extras++;
		}

	@<Declare the I6 locals needed by adaptations to particular deferral cases@>;


@<Compile the code inside this deferral routine@> =
	if (multipurpose_routine) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), GE_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, reason_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, var_s[0]);
					Produce::val_symbol(Emit::tree(), K_value, reason_s);
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, reason_s);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) CONDITION_DUSAGE);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, reason_s);
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				pcalc_prop *safety_copy = Calculus::Propositions::copy(proposition);
				for (int use = EXTREMAL_DUSAGE; use <= CONDITION_DUSAGE; use++) {
					if (use > EXTREMAL_DUSAGE) proposition = Calculus::Propositions::copy(safety_copy);
					switch (use) {
						case CONDITION_DUSAGE: reason = CONDITION_DEFER; break;
						case LOOP_DOMAIN_DUSAGE: reason = LOOP_DOMAIN_DEFER; break;
						case LIST_OF_DUSAGE: reason = LIST_OF_DEFER; break;
						case NUMBER_OF_DUSAGE: reason = NUMBER_OF_DEFER; break;
						case RANDOM_OF_DUSAGE: reason = RANDOM_OF_DEFER; break;
						case TOTAL_DUSAGE: reason = TOTAL_DEFER; break;
						case EXTREMAL_DUSAGE: reason = EXTREMAL_DEFER; break;
					}
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) use);
						Produce::code(Emit::tree());
						Produce::down(Emit::tree());
							Calculus::Propositions::Deferred::compile_comment_about_deferral_reason(reason);
							@<Compile body of deferred proposition for the given reason@>;
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				}
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	} else {
		reason = pdef->reason;
		@<Compile body of deferred proposition for the given reason@>;
	}

@ From here on, we compile the body of a routine to handle the deferral case
in the variable |reason|.

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
	int OL = Produce::level(Emit::tree());

	switch(reason) {
		case NOW_ASSERTION_DEFER: break;
		case CONDITION_DEFER: @<Initialisation before CONDITION search@>; break;
		case EXTREMAL_DEFER: @<Initialisation before EXTREMAL search@>; break;
		case LOOP_DOMAIN_DEFER: @<Initialisation before LOOP search@>; break;
		case NUMBER_OF_DEFER: @<Initialisation before NUMBER search@>; break;
		case LIST_OF_DEFER: @<Initialisation before LIST search@>; break;
		case TOTAL_DEFER: @<Initialisation before TOTAL search@>; break;
		case RANDOM_OF_DEFER: @<Initialisation before RANDOM search@>; break;
	}
	@<Compile code to search for valid combinations of variables@>;

	if ((reason != NOW_ASSERTION_DEFER) && (reason != CONDITION_DEFER)) {
		@<Place next outer loop label@>;
		while (Produce::level(Emit::tree()) > OL) Produce::up(Emit::tree());
	}

	switch(reason) {
		case NOW_ASSERTION_DEFER: break;
		case CONDITION_DEFER: @<Winding-up after CONDITION search@>; break;
		case EXTREMAL_DEFER: @<Winding-up after EXTREMAL search@>; break;
		case LOOP_DOMAIN_DEFER: @<Winding-up after LOOP search@>; break;
		case NUMBER_OF_DEFER: @<Winding-up after NUMBER search@>; break;
		case LIST_OF_DEFER: @<Winding-up after LIST search@>; break;
		case TOTAL_DEFER: @<Winding-up after TOTAL search@>; break;
		case RANDOM_OF_DEFER: @<Winding-up after RANDOM search@>; break;
	}

@h The Search.
We can now begin the real work. Given $\phi$, we compile I6 code which
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
in which $\phi$ is true.

We will do this by compiling the proposition from left to right. If there
are $k$ atoms in $\phi$, then there are $k+1$ positions between atoms,
counting the start and the end. Then:

Invariant.\quad Let $\psi$ be any syntactically valid subproposition
of $\phi$ (that is, a contiguous sequence of atoms from $\psi$ which would
be a valid proposition in its own right). Then there are before and after
positions |B| and |A| in the compiled I6 code for searching $\phi$ such that
(a) |A| cannot be reached except from |B|, and
(b) at execution time, on every occasion |B| is reached, |A| is then reached
exactly once for each combination of possible substitutions into the
$\exists$-bound variables of $\psi$ such that $\psi$ is then true.

In particular, in the case when $\psi = \phi$, |B| is the start of our
compiled I6 code (before anything is done) and |A| is the magic match
position |M|.

The restriction to syntactically valid subpropositions is important. Suppose
$\phi$ arises from "all doors are open" and is stored in memory as:
= (text)
	Forall x IN[ door(x) IN] open(x)
=
Then |door(x)| and |Forall x IN[ door(x) IN]| are valid, for instance, but
|IN] open(x)| is not.

Lemma.\quad If the Invariant holds for two adjacent syntactically valid
subpropositions $\mu$ and $\nu$, then it holds for the subproposition $\mu\nu$.

Proof.\quad There are now three positions in the code: |B1|, before $\mu$;
|B2|, before $\nu$, which is the same position as after $\mu$; and |A|, after
$\nu$. Execution reaches |B2| $m$ times for each visit to |B1|, where $m$
is the number of combinations of viable bound variable values in $\mu$.
Execution reaches |A| $n$ times for each visit to |B2|, where $n$ is the
similar number for $\nu$. Therefore execution reaches |A| a total of $nm$
times for each visit to |B1|, the product of the number of variable combinations
in $\mu$ and $\nu$, which is exactly the number of combinations in total.

Corollary.\quad If the Invariant holds for subpropositions in each of
the following forms, then it will hold overall.
(a) |Exists v|, for some variable $v$, or |Q v IN[ ... IN]|, for some quantifier other than $\exists$.
(b) |NOT[ ... NOT]|.
(c) any single predicate-like atom.

Proof.\quad Because all valid subpropositions are concatenations of
these, and we then apply the Lemma.

It follows that if we can prove our algorithm maintains the invariant in
cases (a) to (d), we can be sure it will correctly construct code leading
to the match point |M|.

@ We will make use of three stacks:

(a) The R-stack, which holds the current "reason": the goal being pursued
by the I6 code currently being compiled.
(b) The Q-stack, which holds details of quantifiers being searched on.
(c) The C-stack, which holds details of callings of variables.

Since each is tied to a quantifier, each of which is tied to a distinct
variable, and there are at most 26 variables, we need a worst-case
capacity of 27 slots on the R-stack (counting the initial |reason|) and
26 on the Q-stack and C-stack.

@<Compile code to search for valid combinations of variables@> =
	int block_nesting = 0; /* how many |{| ... |}| blocks are open in I6 code being compiled */

	/* The R-stack */
	int R_stack_reason[27];
	int R_stack_parity[27];
	int R_sp = 0;

	/* The Q-stack */
	quantifier *Q_stack_quantifier[26];
	int Q_stack_parameter[26];
	int Q_stack_C_stack_level[26];
	int Q_stack_block_nesting[26];
	int Q_sp = 0;

	/* The C-stack */
	pcalc_term C_stack_term[26]; /* the term to which a called-name is being given */
	int C_stack_index[26]; /* its index in the |deferred_calling_list| */
	int C_sp = 0;

	/* The L-stack */
	int L_stack_level[26]; /* emission level at start of block */
	/* block_nesting serves at stack pointer here */

	@<Push initial reason onto the R-stack@>;
	/* we now begin compiling the search code */
	@<Compile the proposition into a search algorithm@>;
	while (Q_sp > 0) @<Pop the Q-stack@>;
	while (C_sp > 0) @<Pop the C-stack@>;
	/* we are now at the magic match point |M| in the search code */
	@<Pop the R-stack@>;
	while (block_nesting > 0)
		@<Close a block in the I6 code compiled to perform the search@>;
	/* we have now finished compiling the search code */

	if (R_sp != 0) internal_error("R-stack failure");
	if (Q_sp != 0) internal_error("Q-stack failure");
	if (C_sp != 0) internal_error("C-stack failure");

@h The R-stack.
This is a sort of "split goals into sub-goals" mechanism. In order to
determine

>> if all but one of the closed doors are unlocked, ...

our main goal is to determine the truth of the "are unlocked" part. This
is reason |CONDITION_DEFER|, and it is pushed onto the R-stack at the
start of the compilation:

@<Push initial reason onto the R-stack@> =
	R_stack_reason[R_sp] = reason;
	R_stack_parity[R_sp] = TRUE;
	R_sp++;

@ But in order to work this out, we have to work out which doors are
closed, and this is a subgoal to which we give the pseudo-reason
|FILTER_DEFER|. We push this new sub-goal onto the R-stack, leaving the
original to be resumed when we're done.

@d FILTER_DEFER 10000 /* pseudo-reason value used only inside this routine */

@<Push domain-opening onto the R-stack@> =
	R_stack_reason[R_sp] = FILTER_DEFER;
	R_stack_parity[R_sp] = TRUE;
	R_sp++;

@ The R-stack is then popped when the goal is accomplished (or rather, when
the I6 code we are compiling has reached a point which will be executed when
its goal has been accomplished).

In the case of |FILTER_DEFER|, when scanning domains of quantifiers, we
increment the count of the domain set size -- the number of closed doors,
in the above example. (See below.)

@<Pop the R-stack@> =
	R_sp--; if (R_sp < 0) internal_error("R stack underflow");

	switch(R_stack_reason[R_sp]) {
		case FILTER_DEFER:
			Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, qcn_s[Q_sp-1]);
			Produce::up(Emit::tree());
			break;
		case NOW_ASSERTION_DEFER: break;
		case CONDITION_DEFER: @<Act on successful match in CONDITION search@>; break;
		case EXTREMAL_DEFER: @<Act on successful match in EXTREMAL search@>; break;
		case LOOP_DOMAIN_DEFER: @<Act on successful match in LOOP search@>; break;
		case NUMBER_OF_DEFER: @<Act on successful match in NUMBER search@>; break;
		case LIST_OF_DEFER: @<Act on successful match in LIST search@>; break;
		case TOTAL_DEFER: @<Act on successful match in TOTAL search@>; break;
		case RANDOM_OF_DEFER: @<Act on successful match in RANDOM search@>; break;
	}

@h Compiling the search.
In the following we run through the proposition from left to right, compiling
I6 code as we go, but preserving the Invariant.

@<Compile the proposition into a search algorithm@> =
	TRAVERSE_VARIABLE(pl);
	int run_of_conditions = 0;
	int no_deferred_callings = 0; /* how many |CALLED| atoms have been found to date */

	TRAVERSE_PROPOSITION(pl, proposition) {
		switch (pl->element) {
			case NEGATION_OPEN_ATOM:
			case NEGATION_CLOSE_ATOM:
				@<End a run of predicate-like conditions, if one is under way@>;
				R_stack_parity[R_sp-1] = (R_stack_parity[R_sp-1])?FALSE:TRUE; /* reverse parity */
				break;
			case QUANTIFIER_ATOM:
				@<End a run of predicate-like conditions, if one is under way@>;
				if (R_stack_parity[R_sp-1] == FALSE) negated_quantifier_found = TRUE;
				quantifier *quant = RETRIEVE_POINTER_quantifier(pl->predicate);
				int param = Calculus::Atoms::get_quantification_parameter(pl);
				if (quant != exists_quantifier) @<Push the Q-stack@>;
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
			case CALLED_ATOM:
				@<Push the C-stack@>;
				break;
			default: {
				if (R_stack_reason[R_sp-1] == NOW_ASSERTION_DEFER)
					@<Compile code to force the atom@>
				else {
					int last_in_run = TRUE, first_in_run = TRUE;
					if (run_of_conditions++ > 0) first_in_run = FALSE;
					pcalc_prop *ex = pl->next;
					while ((ex) && (ex->element == CALLED_ATOM)) ex = ex->next;
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
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());

		if (R_stack_parity[R_sp-1] == FALSE) {
			Produce::inv_primitive(Emit::tree(), NOT_BIP);
			Produce::down(Emit::tree());
		}
	}
	if (last_in_run == FALSE) {
		Produce::inv_primitive(Emit::tree(), AND_BIP);
		Produce::down(Emit::tree());
	}
	Calculus::Atoms::Compile::emit(TEST_ATOM_TASK, pl, TRUE);

@<End a run of predicate-like conditions, if one is under way@> =
	if (run_of_conditions > 0) {
		while (run_of_conditions > 1) { Produce::up(Emit::tree()); run_of_conditions--; }
		if (R_stack_parity[R_sp-1] == FALSE) { Produce::up(Emit::tree()); }
		run_of_conditions = 0;
		@<Open a block in the I6 code compiled to perform the search, if variant@>;
	}

@ The |NOW_ASSERTION_DEFER| reason is different from all of the others,
because rather than searching for a given situation it tries force it to
happen (or not to). Forcing rather than testing is easy here: we just supply
a different task when calling |Calculus::Atoms::Compile::compile|.

In the negated case, we again cheat de Morgan, by falsifying $\phi$ more
aggressively than we need: we force $\lnot(X)\land\lnot(Y)\land\lnot(Z)$ to
be true, though strictly speaking it would be enough to falsify X alone.
(We do it that way for consistency with the same convention when asserting
about the model world.)

We don't need to consider runs of predicates for that; we can take the atoms
one at a time.

@<Compile code to force the atom@> =
	Calculus::Atoms::Compile::emit((R_stack_parity[R_sp-1])?NOW_ATOM_TRUE_TASK:NOW_ATOM_FALSE_TASK, pl, TRUE);

@h Quantifiers and the Q-stack.
It remains to deal with quantifiers, and to show that the Invariant is
preserved by them. There are two cases: $\exists$, and everything else.

The existence case is the easiest. Given $\exists v: \psi(v)$ we compile
= (text)
	loop header for v to run through its domain set {
	    ...
=
and note that execution reaches the start of the loop body once for each
possible choice of $v$, as required by the Invariant -- indeed the Invariant
pretty much requires that this is what we compile.

@<Compile a loop through possible values of the variable quantified@> =
	int level_back_to = Produce::level(Emit::tree());
	pl = Calculus::Propositions::Deferred::compile_loop_header(
		pl->terms[0].variable, var_ix_lv[pl->terms[0].variable],
		pl,
		(R_stack_reason[R_sp-1] == NOW_ASSERTION_DEFER)?TRUE:FALSE,
		(quant != exists_quantifier)?TRUE:FALSE, pdef);
	@<Open a block in the I6 code compiled to perform the search@>;

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
	if (R_stack_reason[R_sp-1] == NOW_ASSERTION_DEFER)
		@<Handle "not exists" as "for all not"@>;

	Q_stack_quantifier[Q_sp] = quant;
	Q_stack_parameter[Q_sp] = param;
	Q_stack_block_nesting[Q_sp] = block_nesting;
	Q_stack_C_stack_level[Q_sp] = C_sp;
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, qcy_s[Q_sp]);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, qcn_s[Q_sp]);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	Q_sp++;

@ It is always true that $\not\exists x: \psi(x)$ is equivalent to $\forall x:
\lnot(\phi(x))$, so the following seems pointless. We do this, in the case
of "now" only, in order to make $\not\exists$ legal in a "now", which
it otherwise wouldn't be. Most quantifiers aren't, because they are too vague:
"now fewer than six doors are open", for instance, is not allowed. But we
do want to allow "now nobody likes Mr Wickham", say, which asserts
$\not\exists x: {\it person}(x)\land{\it likes}(x, W)$.

@<Handle "not exists" as "for all not"@> =
	if (quant == not_exists_quantifier) {
		R_stack_parity[R_sp-1] = (R_stack_parity[R_sp-1])?FALSE:TRUE;
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
an increment of the valid cases count, because if execution of the I6
code gets to the end of testing $\theta$ then it must have found a valid
case: in the "at least three doors are unlocked" example, it will have
found an unlocked one among the doors making up the domain. We then need
to record any "called" values for later retrieval by whoever called
this proposition routine: see below. That leaves just this part:
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
	Q_sp--; if (Q_sp < 0) internal_error("Q stack underflow");
	Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, qcy_s[Q_sp]);
	Produce::up(Emit::tree());

	while (C_sp > Q_stack_C_stack_level[Q_sp])
		@<Pop the C-stack@>;

	while (block_nesting > Q_stack_block_nesting[Q_sp])
		@<Close a block in the I6 code compiled to perform the search@>;

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
	Quantifiers::emit_test(Q_stack_quantifier[Q_sp], Q_stack_parameter[Q_sp], qcy_s[Q_sp], qcn_s[Q_sp]);
	@<Open a block in the I6 code compiled to perform the search, if variant@>;

@h The C-stack.
When a CALLED atom in the proposition gives a name to a variable, we have to
transcribe that to the |deferred_calling_list| for the benefit of the code
calling this proposition routine. Each time we discover that a term $t$ is
to be given a name, we stack it up. These are not always variables:

>> if a person (called the dupe) is in a dark room (called the lair), ...

gives names to $x$ ("dupe") and $f_{\it in}(x)$ ("lair"), because
simplification has eliminated the variable $y$ which appears to be being
given a name.

@<Push the C-stack@> =
	C_stack_term[C_sp] = pl->terms[0];
	C_stack_index[C_sp] = no_deferred_callings++;
	C_sp++;

@ When does the compiled search code record values into |deferred_calling_list|?
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
	C_sp--; if (C_sp < 0) internal_error("C stack underflow");
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
		Produce::down(Emit::tree());
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(DEFERRED_CALLING_LIST_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) C_stack_index[C_sp]);
		Produce::up(Emit::tree());
		Calculus::Terms::emit(C_stack_term[C_sp]);
	Produce::up(Emit::tree());

@ That just leaves the blocking, which follows the One True Brace Style. Thus:

@<Open a block in the I6 code compiled to perform the search@> =
	L_stack_level[block_nesting] = level_back_to;
	block_nesting++;

@ Not for a loop body:

@<Open a block in the I6 code compiled to perform the search, if variant@> =
	L_stack_level[block_nesting] = Produce::level(Emit::tree())-1;
	Produce::code(Emit::tree());
	Produce::down(Emit::tree());
	block_nesting++;

@ and:

@<Close a block in the I6 code compiled to perform the search@> =
	while (Produce::level(Emit::tree()) > L_stack_level[block_nesting-1]) Produce::up(Emit::tree());
	block_nesting--;

@h Adaptations.
That completes the general pattern of searching according to the proposition's
instructions. It remains to adapt it to different needs, by providing, in
each case, some setting-up code; some code to execute when a viable set
of variable values is found; and some winding-up code.

In some of the cases, additional local variables are needed within the
|Prop_N| routine, to keep track of counters or totals. These are they:

@<Declare the I6 locals needed by adaptations to particular deferral cases@> =
	if (multipurpose_routine) {
		total_s = LocalVariables::add_internal_local_as_symbol(I"total");
		counter_s = LocalVariables::add_internal_local_as_symbol(I"counter");
		selection_s = LocalVariables::add_internal_local_as_symbol(I"selection");
		best_s = LocalVariables::add_internal_local_as_symbol(I"best");
		best_with_s = LocalVariables::add_internal_local_as_symbol(I"best_with");
	} else {
		switch (pdef->reason) {
			case NUMBER_OF_DEFER:
				counter_s = LocalVariables::add_internal_local_as_symbol(I"counter");
				break;
			case RANDOM_OF_DEFER:
				counter_s = LocalVariables::add_internal_local_as_symbol(I"counter");
				selection_s = LocalVariables::add_internal_local_as_symbol(I"selection");
				break;
			case TOTAL_DEFER:
				total_s = LocalVariables::add_internal_local_as_symbol(I"total");
				break;
			case LIST_OF_DEFER:
				counter_s = LocalVariables::add_internal_local_as_symbol(I"counter");
				total_s = LocalVariables::add_internal_local_as_symbol(I"total");
				break;
			case EXTREMAL_DEFER:
				best_s = LocalVariables::add_internal_local_as_symbol(I"best");
				best_with_s = LocalVariables::add_internal_local_as_symbol(I"best_with");
				break;
		}
	}

@<Declare the I6 call parameters needed by adaptations to particular deferral cases@> =
	if ((!multipurpose_routine) && (pdef->reason == LIST_OF_DEFER)) {
		list_s = LocalVariables::add_named_call_as_symbol(I"list");
		strong_kind_s = LocalVariables::add_named_call_as_symbol(I"strong_kind");
	}

@h Adaptation to CONDITION.
The first and simplest of our cases to understand: where $\phi$ is a sentence,
with all variables bound, and we have to return |true| if it is true and
|false| if it is false. There is no initialisation:

@<Initialisation before CONDITION search@> =
	;

@ As soon as we find any valid combination of the variables, we return |true|:

@<Act on successful match in CONDITION search@> =
	Produce::rtrue(Emit::tree());

@ So we only reach winding-up if every case failed, and then we return |false|:

@<Winding-up after CONDITION search@> =
	Produce::rfalse(Emit::tree());

@h Adaptation to NUMBER.
In the remaining cases, $\phi$ has variable $x$ (only) left free, but the use
we want to make will be a loop over all objects $x$, and we compile this
"outer loop" here: the loop opens in the initialisation code, closes in
the winding-up code, and therefore completely encloses the code generated
by the searching mechanism above.

In the first case, we want to count the number of $x$ for which $\phi(x)$
is true. The local |counter| holds the count so far; it starts out automatically
at 0, since all I6 locals do.

@<Initialisation before NUMBER search@> =
	proposition = Calculus::Propositions::Deferred::compile_loop_header(0, var_ix_lv[0], proposition, FALSE, FALSE, pdef);

@ Recall that we get here for each possible way that $\phi(x)$ could
be true, that is, once for each viable set of values of bound variables in
$\phi$. But we only want to increment |counter| once, so having done so, we
exit the searching code and continue the outer loop.

The |jump| to a label is forced on us since I6, unlike, say, Perl, has no
syntax to break or continue a loop other than the innermost one.

@<Act on successful match in NUMBER search@> =
	Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, counter_s);
	Produce::up(Emit::tree());

	@<Jump to next outer loop for this reason@>;

@<Jump to next outer loop for this reason@> =
	if (NextOuterLoop_labels[reason] == NULL) {
		TEMPORARY_TEXT(L);
		WRITE_TO(L, ".NextOuterLoop_%d", reason);
		NextOuterLoop_labels[reason] = Produce::reserve_label(Emit::tree(), L);
		DISCARD_TEXT(L);
	}
	Produce::inv_primitive(Emit::tree(), JUMP_BIP);
	Produce::down(Emit::tree());
		Produce::lab(Emit::tree(), NextOuterLoop_labels[reason]);
	Produce::up(Emit::tree());

@<Place next outer loop label@> =
	if (NextOuterLoop_labels[reason] == NULL) {
		TEMPORARY_TEXT(L);
		WRITE_TO(L, ".NextOuterLoop_%d", reason);
		NextOuterLoop_labels[reason] = Produce::reserve_label(Emit::tree(), L);
		DISCARD_TEXT(L);
	}
	Produce::place_label(Emit::tree(), NextOuterLoop_labels[reason]);

@ The continue-outer-loop labels are marked with the reason number so that
if code is compiled for each reason in turn within a single routine -- which
is what we do for multipurpose deferred propositions -- the labels do
not have clashing names.

@<Winding-up after NUMBER search@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, counter_s);
	Produce::up(Emit::tree());

@h Adaptation to LIST.
In the next case, we want to form the list of all $x$ for which $\phi(x)$
is true. The local |list| holds the list so far, and already exists.

@<Initialisation before LIST search@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUEWRITE_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, list_s);
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LIST_ITEM_KOV_F_HL));
		Produce::val_symbol(Emit::tree(), K_value, strong_kind_s);
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, total_s);
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_GETLENGTH_HL));
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, list_s);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	proposition = Calculus::Propositions::Deferred::compile_loop_header(0, var_ix_lv[0], proposition, FALSE, FALSE, pdef);

@ Recall that we get here for each possible way that $\phi(x)$ could
be true, that is, once for each viable set of values of bound variables in
$\phi$. But we only want to increment |counter| once, so having done so, we
exit the searching code and continue the outer loop.

The |jump| to a label is forced on us since I6, unlike, say, Perl, has no
syntax to break or continue a loop other than the innermost one.

@<Act on successful match in LIST search@> =
	Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, counter_s);
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), GT_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, counter_s);
			Produce::val_symbol(Emit::tree(), K_value, total_s);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, total_s);
				Produce::inv_primitive(Emit::tree(), PLUS_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), TIMES_BIP);
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 3);
						Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
						Produce::down(Emit::tree());
							Produce::val_symbol(Emit::tree(), K_value, total_s);
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 8);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());

			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, list_s);
				Produce::val_symbol(Emit::tree(), K_value, total_s);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUEWRITE_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, list_s);
		Produce::inv_primitive(Emit::tree(), MINUS_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), PLUS_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, counter_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LIST_ITEM_BASE_HL));
			Produce::up(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
	Produce::up(Emit::tree());

	@<Jump to next outer loop for this reason@>;

@ The continue-outer-loop labels are marked with the reason number so that
if code is compiled for each reason in turn within a single routine -- which
is what we do for multipurpose deferred propositions -- the labels do
not have clashing names.

@<Winding-up after LIST search@> =
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_SETLENGTH_HL));
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, list_s);
		Produce::val_symbol(Emit::tree(), K_value, counter_s);
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, list_s);
	Produce::up(Emit::tree());

@h Adaptation to RANDOM.
To choose a random $x$ such that $\phi(x)$, we essentially run the same code
as for NUMBER searches, but twice over: first to count how many such $x$ there
are, then to run through again to find the $n$th of these, where $n$ is a
uniformly random number such that $1\leq n\leq x$.

This avoids needing to store the full list of matches anywhere, which would
be impossible since (a) it's potentially a lot of storage and (b) it can
only safely live on the current stack frame, and I6 does not allow arrays
on the current stack frame (because of restrictions in the Z-machine).
This means that, on average, the compiled code takes 50\% longer to find
its random $x$ than it ideally would, but we accept the trade-off.

@<Initialisation before RANDOM search@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, selection_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) -1);
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), WHILE_BIP);
	Produce::down(Emit::tree());
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, counter_s);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	Produce::up(Emit::tree());

	proposition = Calculus::Propositions::Deferred::compile_loop_header(0, var_ix_lv[0], proposition, FALSE, FALSE, pdef);

@ Again we exit the searcher as soon as a match is found, since that guarantees
that $\phi(x)$.

Note that we can only return here on the second pass, since |selection| is $-1$
throughout the first pass, whereas |counter| is non-negative.

@<Act on successful match in RANDOM search@> =
	Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, counter_s);
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, counter_s);
			Produce::val_symbol(Emit::tree(), K_value, selection_s);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	@<Jump to next outer loop for this reason@>;

@ We return |nothing| -- the non-object -- if |counter| is zero, since that
means the set of possible $x$ is empty. But we also return if |selection|
has been made already, because that means that the second pass has been
completed without a return -- something which in theory cannot happen, but
just might do if testing part of the proposition had some side-effect changing
the state of the objects and thus the size of the set of possibilities.

@<Winding-up after RANDOM search@> =
	Produce::down(Emit::tree());
	Produce::down(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), OR_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, counter_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			Produce::inv_primitive(Emit::tree(), GE_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, selection_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), RETURN_BIP);
			Produce::down(Emit::tree());
				Produce::val_nothing(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, selection_s);
		Produce::inv_primitive(Emit::tree(), RANDOM_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, counter_s);
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

@h Adaptation to TOTAL.
Here the task is to sum the values of property $P$ attached to each object
in the domain $\lbrace x\mid \phi(x)\rbrace$.

@<Initialisation before TOTAL search@> =
	proposition = Calculus::Propositions::Deferred::compile_loop_header(0, var_ix_lv[0], proposition, FALSE, FALSE, pdef);

@ The only wrinkle here is the way the compiled code knows which property it
should be totalling. If we know that ourselves, we can compile in a direct
reference. But if we are compiling a multipurpose deferred proposition, then
it might be used to total any property over the domain, and we won't know
which until runtime -- when its identity will be found in the I6 variable
|property_to_be_totalled|.

@<Act on successful match in TOTAL search@> =
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Produce::down(Emit::tree());
		Produce::ref_symbol(Emit::tree(), K_value, total_s);
		Produce::inv_primitive(Emit::tree(), PLUS_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, total_s);
			Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
				if (multipurpose_routine) {
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PROPERTY_TO_BE_TOTALLED_HL));
				} else {
					prn = RETRIEVE_POINTER_property(pdef->defn_ref);
					Produce::val_iname(Emit::tree(), K_value, Properties::iname(prn));
				}
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	@<Jump to next outer loop for this reason@>;

@<Winding-up after TOTAL search@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, total_s);
	Produce::up(Emit::tree());

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
maximising or minimising, at compile time; but for a multipurpose routine
we don't, and have to look that up at run-time.

@<Initialisation before EXTREMAL search@> =
	if (multipurpose_routine) {
		Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), GT_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PROPERTY_LOOP_SIGN_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, best_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MIN_NEGATIVE_NUMBER_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, best_s);
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	} else {
		measurement_definition *mdef =
			RETRIEVE_POINTER_measurement_definition(pdef->defn_ref);
		Properties::Measurement::read_property_details(mdef, &def_prn, &def_prn_sign);
		if (def_prn_sign == 1) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, best_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MIN_NEGATIVE_NUMBER_HL));
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, best_s);
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MAX_POSITIVE_NUMBER_HL));
			Produce::up(Emit::tree());
		}
	}
	proposition = Calculus::Propositions::Deferred::compile_loop_header(0, var_ix_lv[0], proposition, FALSE, FALSE, pdef);

@ It might look as if we could speed up the multipurpose case by
multiplying by |property_loop_sign|, thus combining the max and min
versions into one, and saving an |if|. But (a) the multiplication is as
expensive as the |if| (remember that on a VM there's no real branch
penalty), and (b) we need to watch out because $-1$ times $-32768$, on a
16-bit machine, is $-1$, not $32768$: so it is not always true that
multiplying by $-1$ is order-reversing.

@<Act on successful match in EXTREMAL search@> =
	if (multipurpose_routine) {
		Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), GT_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PROPERTY_LOOP_SIGN_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), GE_BIP);
					Produce::down(Emit::tree());
						@<Emit code for a property lookup@>;
						Produce::val_symbol(Emit::tree(), K_value, best_s);
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, best_s);
							@<Emit code for a property lookup@>;
						Produce::up(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, best_with_s);
							Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), IF_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), LE_BIP);
					Produce::down(Emit::tree());
						@<Emit code for a property lookup@>;
						Produce::val_symbol(Emit::tree(), K_value, best_s);
					Produce::up(Emit::tree());
					Produce::code(Emit::tree());
					Produce::down(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, best_s);
							@<Emit code for a property lookup@>;
						Produce::up(Emit::tree());
						Produce::inv_primitive(Emit::tree(), STORE_BIP);
						Produce::down(Emit::tree());
							Produce::ref_symbol(Emit::tree(), K_value, best_with_s);
							Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
						Produce::up(Emit::tree());
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	} else {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			if (def_prn_sign == 1) Produce::inv_primitive(Emit::tree(), GE_BIP);
			else Produce::inv_primitive(Emit::tree(), LE_BIP);
			Produce::down(Emit::tree());
				@<Emit code for a property lookup@>;
				Produce::val_symbol(Emit::tree(), K_value, best_s);
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, best_s);
					@<Emit code for a property lookup@>;
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Produce::down(Emit::tree());
					Produce::ref_symbol(Emit::tree(), K_value, best_with_s);
					Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}

@<Emit code for a property lookup@> =
	Produce::inv_primitive(Emit::tree(), PROPERTYVALUE_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
		if (multipurpose_routine) {
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(PROPERTY_TO_BE_TOTALLED_HL));
		} else {
			Produce::val_iname(Emit::tree(), K_value, Properties::iname(def_prn));
		}
	Produce::up(Emit::tree());

@<Winding-up after EXTREMAL search@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, best_with_s);
	Produce::up(Emit::tree());

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
initial value or the successor value from a loop header. (The trick actually
caused some consternation for I6 hackers when early drafts of I7 came out,
because they had been experimenting with a patch to I6 which protected
|objectloop| from object-tree rearrangements but which assumed that nobody
ever used |jump| to enter a loop body bypassing its header. But the DM4,
which defines I6, doesn't forbid this. The designer of I6 has learned his
lesson, though: I7 has no goto or jump instruction, and I7 loops can be
proved to be entered and exited cleanly.)

@<Initialisation before LOOP search@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), GT_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, var_ix_s[0]);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), POSTDECREMENT_BIP);
			Produce::down(Emit::tree());
				Produce::ref_symbol(Emit::tree(), K_value, var_ix_s[0]);
			Produce::up(Emit::tree());
			@<Jump to next outer loop for this reason@>;
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			@<Jump to next outer loop for this reason@>;
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	proposition = Calculus::Propositions::Deferred::compile_loop_header(0, var_ix_lv[0], proposition, FALSE, FALSE, pdef);

@<Act on successful match in LOOP search@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, var_s[0]);
	Produce::up(Emit::tree());

@<Winding-up after LOOP search@> =
	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val_nothing(Emit::tree());
	Produce::up(Emit::tree());

@h Compiling loop headers.
The final task of this entire chapter is to compile an I6 loop header which
causes a given variable $v$ to range through a domain set $D$ -- which we
have to deduce by looking at the proposition $\psi$ in front of us.

We want this loop to run as quickly as possible: efficiency here makes
a very big difference to the running time of compiled I7 code. Most
optimisations aren't worth the risk in added complexity -- but these are.

Loops through kinds of value are not in general optimisable. The problem cases
involve loops through objects. Consider:

>> if everyone in the Dining Room can see an animal, ...

Code like this will run very slowly:
= (text)
	loop over objects (x)
	    loop over objects (y)
	        if x is a person
	            if x is in the Dining Room
	                if y is an animal
	                    if x can see y
	                        success!
=
This is folly in so many ways. Most objects aren't people or animals, so
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

(1) if a loop over $v$ is such that $K(v)$ holds in every case, where $K$
is a kind, then loop $v$ over $K$ rather than all objects, and
(2) if a loop over $v$ is such that $R(v, t)$ holds in every case, then loop over
all $v$ such that $R(v, t)$ in cases where $R$ has a run-time representation
making this quick and easy.

In each case we can then delete $K(v)$ or $R(v, t)$ from the proposition
as redundant, since the loop header has taken care of it.

Case (1) is called "kind optimisation"; case (2), "parent
optimisation", because the prototype case is $R$ being containment -- we
exploit that the object-tree parent of $v$ is known, and that I6 has a fast
form of |objectloop| to visit the children of a given node in the object
tree. Case (2) has to be avoided if we are compiling code to force a
proposition, rather than test it, because then $R(v, t)$ is not an
accomplished fact but is something we have yet to make come true. This is
why the loop-compiler takes a flag |avoid_parent_optimisation|. Case (1)
doesn't suffer from this since kinds cannot be changed at run-time.

@ So here is the code. We write an I6 schema for the loop into |loop_schema|,
then expand it into the output.

=
i6_schema loop_schema;
pcalc_prop *Calculus::Propositions::Deferred::compile_loop_header(int var, local_variable *index_var,
	pcalc_prop *proposition,
	int avoid_parent_optimisation, int grouped, pcalc_prop_deferral *pdef) {

	kind *K = NULL;
	pcalc_prop *kind_position = NULL;
	pcalc_term var_term = Calculus::Terms::new_variable(var);
	pcalc_term second_term = Calculus::Terms::new_constant(
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING, index_var));

	int parent_optimised = FALSE;

	/* the default, if we are unable to provide either kind or parent optimisation */
	Calculus::Schemas::modify(&loop_schema, "objectloop (*1 ofclass Object)");

	@<Scan the proposition to find the domain of the loop, and look for opportunities@>;

	if ((K) && (parent_optimised == FALSE)) { /* parent optimisation is stronger, so we prefer that */
		if (Calculus::Deferrals::write_loop_schema(&loop_schema, K) == FALSE) {
			if (pdef->rtp_iname == NULL) {
				pdef->rtp_iname = Hierarchy::make_iname_in(RTP_HL, pdef->ppd_package);
			}
			Calculus::Schemas::modify(&loop_schema, "if (RunTimeProblem(RTP_CANTITERATE, %n))",
				pdef->rtp_iname);
		}
		proposition = Calculus::Propositions::delete_atom(proposition, kind_position);
	}

	Calculus::Schemas::emit_expand_from_terms(&loop_schema, &var_term, &second_term, TRUE);

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
		switch (Calculus::Atoms::element_get_group(pl->element)) {
			case OPEN_OPERATORS_GROUP: bl++; break;
			case CLOSE_OPERATORS_GROUP: bl--; break;
		}
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
		@<Scan $\psi$, the part of the proposition establishing the domain@>;
	}

@ In either case, we scan $\psi$ looking for $K(v)$ atoms, which would tell
us the domain set for the variable $v$, or for $R(v, t)$ atoms for
parent-optimisable relations $R$.

@<Scan $\psi$, the part of the proposition establishing the domain@> =
	if ((pl->element == KIND_ATOM) && (pl->terms[0].variable == var)) {
		K = pl->assert_kind;
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
				proposition = Calculus::Propositions::delete_atom(proposition, pl_prev);
				break;
			}
		}
	} else if ((pl->terms[0].variable == var) &&
		(BinaryPredicates::write_optimised_loop_schema(&loop_schema, bp))) {
		second_term = pl->terms[1];
		parent_optimised = TRUE;
		proposition = Calculus::Propositions::delete_atom(proposition, pl_prev);
	}

@ And that concludes the predicate-calculus engine at the heart of Inform.
