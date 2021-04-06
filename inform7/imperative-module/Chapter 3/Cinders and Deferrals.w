[Calculus::Deferrals::Cinders::] Cinders and Deferrals.

To compile terms, having carefully preserved any constants which might
have been lost in the process of deferring a proposition (such tricky constants
being called "cinders").

@h About cinders.
Any proposition which includes quantification will, in general, need to be
deferred: the quantifier will become a loop, and the loop variable will be a
local variable in the deferred routine. Instead of compiling explicit code
in the current routine |R|, we will compile a call to, say, |Prop_19|.

It is both good and bad that |Prop_19| has its own set of local variables.
Good because this means it can have loop variables and counters to help it
to implement quantifiers, without having to use up scarce locals in |R|.
(Recall that I6 allows only 15 locals in any one routine.) But bad because
the proposition may itself involve mention of local variables in |R|, which
do not exist inside |Prop_19|.

There are two issues here. Suppose we have:

>> if a dark room contains the painting

This compiles to code quantifying over rooms $x$, requiring a loop, so it
will be deferred to a routine. "The painting" is, in predicate calculus
terms, a constant -- in that it does not depend on $x$ -- but that does not
mean it's a value known at compile time. If it is a local variable in the
current routine, then it won't exist in the deferred one, as mentioned
above. But it might also be a phrase to decide something, which has
side-effects, so that it might be important not to evaluate it more than
once.

Any such constants are compiled into the call to |Prop_19| as parameters:
then, when the latter is compiled, they become locals |const_0|, |const_1|,
..., whose evaluation will be rapid and without side-effects.

@ As part of the deferral process, then, we scan through a proposition to look
for constants which might cause trouble. These are called "cinders", which
is a contraction of "constants in deferred routines".

Within any given proposition, the cinders are numbered 0, 1, 2, ...; these
numbers are recorded in the |cinder| field of the relevant |pcalc_term|
structure. A constant term with |cinder| set to $-1$ is harmless, and
can be compiled in |Prop_19| as it stands: a literal number, for instance.

At any given moment, we can only be working on the compilation of a single
deferred proposition routine. The following records the information noted
down at the time when the proposition was deferred:

=
pcalc_prop_deferral *current_pdef = NULL; /* used only in this section */

@h Finding cinders.
In this operation, conducted when we defer a proposition, we look for
constant terms which need to be cindered, do so, compile their values as
a comma-separated list of I6 expressions (which can be used in a function
call), note down their kinds of value in the record of the deferral, and
return the number of cinders made.

=
int Calculus::Deferrals::Cinders::find_count(pcalc_prop *prop, pcalc_prop_deferral *pdef) {
	TRAVERSE_VARIABLE(pl);
	int cinder_number = 0;
	pcalc_prop_deferral *save_current_pdef = current_pdef;
	current_pdef = pdef;
	TRAVERSE_PROPOSITION(pl, prop)
		for (int i=0; i<pl->arity; i++)
			cinder_number =
				Calculus::Deferrals::Cinders::cind_find_in_term_count(&(pl->terms[i]), cinder_number);

	current_pdef = save_current_pdef;
	return cinder_number;
}

int Calculus::Deferrals::Cinders::find_emit(pcalc_prop *prop, pcalc_prop_deferral *pdef) {
	TRAVERSE_VARIABLE(pl);
	int i, cinder_number = 0, started = FALSE;
	pcalc_prop_deferral *save_current_pdef = current_pdef;
	current_pdef = pdef;
	TRAVERSE_PROPOSITION(pl, prop)
		for (i=0; i<pl->arity; i++)
			cinder_number =
				Calculus::Deferrals::Cinders::cind_find_in_term_emit(&(pl->terms[i]), cinder_number, &started);

	current_pdef = save_current_pdef;
	return cinder_number;
}

int Calculus::Deferrals::Cinders::cind_find_in_term_emit(pcalc_term *pt, int cinder_number, int *started) {
	/* do not clear the local I6 stream */
	if (pt->function)
		return Calculus::Deferrals::Cinders::cind_find_in_term_emit(&(pt->function->fn_of), cinder_number, started);
	if (pt->constant) {
		if (Calculus::Deferrals::Cinders::spec_needs_to_be_cindered(pt->constant)) {
			pt->cinder = cinder_number++;
			CompileSpecifications::to_code_val(K_value, pt->constant);
			current_pdef->cinder_kinds[pt->cinder] =
				Specifications::to_kind(pt->constant);
			*started = TRUE;
		} else pt->cinder = -1;
	}
	return cinder_number;
}

int Calculus::Deferrals::Cinders::cind_find_in_term_count(pcalc_term *pt, int cinder_number) {
	/* do not clear the local I6 stream */
	if (pt->function)
		return Calculus::Deferrals::Cinders::cind_find_in_term_count(&(pt->function->fn_of), cinder_number);
	if (pt->constant) {
		if (Calculus::Deferrals::Cinders::spec_needs_to_be_cindered(pt->constant)) {
			cinder_number++;
		}
	}
	return cinder_number;
}

@ Which leaves us to decide, given any specification, whether it represents
a value needing to be cindered.

If in doubt, we should cinder, but we don't want to go mad since there's a limit
to how many cinders can be passed as parameters. Currently we do cinder these:

(a) phrases to decide values, cindered because they might be slow or have
side-effects to evaluate;
(b) stacked non-local variables, such as variables attached to actions or
activities, cindered because they are only allowed in certain routines, and
the eventual deferred proposition routine might not qualify;
(c) local variables, cindered since they won't exist in the deferred routine;
(d) list and table entries, cindered since they are relatively slow to look up.

But we do not cinder these, since their evaluation never depends on context
and never needs more than a single array entry lookup at run-time:

(a) constants from literal numbers to names of scenes, rulebooks, and so on;
(b) global variables.

=
int Calculus::Deferrals::Cinders::spec_needs_to_be_cindered(parse_node *spec) {
	if (Node::is(spec, CONSTANT_NT)) return FALSE;
	if (Lvalues::is_global_variable(spec)) return FALSE;
	return TRUE;
}

@h Declaring cinder parameters.
Symmetrically, when we come to compiled our deferred proposition routine
|Prop_19|, we need to place suitable cinder variables in its I6 header.
We print their names, separated by spaces, since that's the somewhat
assembler-like syntax used by I6 routine headers.

We also set |current_pdef|, since this is the first action taken in starting
a new deferred routine.

=
void Calculus::Deferrals::Cinders::declare(pcalc_prop *prop, pcalc_prop_deferral *pdef) {
	TRAVERSE_VARIABLE(pl);
	int i, cinder_number = 0;

	pcalc_prop_deferral *save_current_pdef = current_pdef;
	current_pdef = pdef;

	TRAVERSE_PROPOSITION(pl, prop)
		for (i=0; i<pl->arity; i++)
			cinder_number = Calculus::Deferrals::Cinders::cind_declare_in(cinder_number, &(pl->terms[i]));

	current_pdef = save_current_pdef;
}

int Calculus::Deferrals::Cinders::cind_declare_in(int cinder_number, pcalc_term *pt) {
	if (pt->function)
		return Calculus::Deferrals::Cinders::cind_declare_in(cinder_number, &(pt->function->fn_of));
	if ((pt->constant) && (pt->cinder >= 0))
		if (Node::is(pt->constant, CONSTANT_NT) == FALSE) {
			TEMPORARY_TEXT(cinder_name)
			WRITE_TO(cinder_name, "const_%d", cinder_number++);
			LocalVariables::new_other_as_symbol(cinder_name);
			DISCARD_TEXT(cinder_name)
		}
	return cinder_number;
}

@h The kind of terms.
We are now finally able to say what the kind of value of a term to be
compiled is. The only troublesome case is when the term is a cinder; its
kind is then part of the information recorded at deferral time.

=
kind *Calculus::Deferrals::Cinders::kind_of_value_of_term(pcalc_term pt) {
	if (pt.variable >= 0) {
		if (pt.term_checked_as_kind) return pt.term_checked_as_kind;
		return K_object;
	}
	if (pt.constant) {
		if (pt.cinder >= 0) return current_pdef->cinder_kinds[pt.cinder];
		if (Specifications::is_phrasal(pt.constant))
			Dash::check_value(pt.constant, NULL);
		return Specifications::to_kind(pt.constant);
	}
	if (pt.function) return K_object;
	internal_error("Broken pcalc term");
	return NULL;
}

@ =
void Calculus::Deferrals::Cinders::emit(int c) {
	local_variable *lvar = Calculus::Deferrals::Cinders::find_cinder_var(c);
	if (lvar == NULL) internal_error("absent calculus variable");
	inter_symbol *lvar_s = LocalVariables::declare(lvar);
	Produce::val_symbol(Emit::tree(), K_value, lvar_s);
}

local_variable *Calculus::Deferrals::Cinders::find_cinder_var(int v) {
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "const_%d", v);
	local_variable *found = LocalVariables::by_identifier(T);
	DISCARD_TEXT(T)
	return found;
}
