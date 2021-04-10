[Cinders::] Cinders and Deferrals.

Cinders are constants in deferred propositions referring to values in the
original stack frame.

@ The issues giving rise to cinders are explained in //Deciding to Defer//.
When a proposition contains a constant -- in the predicate calculus sense;
it may well be a variable or even a function call in Inform -- and this
cannot be accessed from the stack frame of the proposition's deferral
function, the constant is a "cinder".[1]

Clearly genuine constants -- literal numbers, names of rules, and so on -- and
global variables need not be cindered: those are the same in any stack frame
and can be evaluated without side-effects. We cinder everything else, which
seems only prudent. For example:
(a) phrases to decide values, cindered because they might be slow or have
side-effects to evaluate;
(b) shared non-local variables, such as variables attached to actions or
activities, cindered because they are only allowed in certain routines, and
the eventual deferred proposition routine might not qualify;
(c) local variables, cindered since they won't exist in the deferred routine;
(d) list and table entries, cindered since they are relatively slow to look up.

[1] Originally a contraction of "constant in deferred routine".

=
int Cinders::needs_to_be_cindered(parse_node *spec) {
	if (Node::is(spec, CONSTANT_NT)) return FALSE;
	if (Lvalues::is_global_variable(spec)) return FALSE;
	return TRUE;
}

@ At any given moment, we can only be working on the compilation of a single
deferred proposition function, so we store its identity in the following
rather than waste space giving each |pcalc_term| a pointer to it:

=
pcalc_prop_deferral *current_pdef = NULL; /* used only in this section */

@ Within any given proposition, the cinders are numbered 0, 1, 2, ...; these
numbers are recorded in the |cinder| field of the relevant |pcalc_term| structure.
A term with |cinder| set to $-1$ is not a cinder.

Here we count the cinders in a proposition, but compile nothing and change nothing:

=
int Cinders::count(pcalc_prop *prop, pcalc_prop_deferral *pdef) {
	int N = 0;
	TRAVERSE_VARIABLE(atom);
	TRAVERSE_PROPOSITION(atom, prop)
		for (int i=0; i<atom->arity; i++)
			N = Cinders::count_in_term(&(atom->terms[i]), N);
	return N;
}

int Cinders::count_in_term(pcalc_term *pt, int N) {
	if (pt->function) return Cinders::count_in_term(&(pt->function->fn_of), N);
	if (pt->constant)
		if (Cinders::needs_to_be_cindered(pt->constant))
			N++;
	return N;
}

@ This more ambitious function sets the |cinder| field for each term, and also
sets the kinds of the cinder values in the deferred function.

=
int Cinders::compile_cindered_values(pcalc_prop *prop, pcalc_prop_deferral *pdef) {
	pcalc_prop_deferral *save_current_pdef = current_pdef;
	current_pdef = pdef;
	int N = 0;
	TRAVERSE_VARIABLE(atom);
	TRAVERSE_PROPOSITION(atom, prop)
		for (int i=0; i<atom->arity; i++)
			N = Cinders::compile_cindered_value_in_term(&(atom->terms[i]), N);
	current_pdef = save_current_pdef;
	return N;
}

int Cinders::compile_cindered_value_in_term(pcalc_term *pt, int N) {
	if (pt->function)
		return Cinders::compile_cindered_value_in_term(&(pt->function->fn_of), N);
	if (pt->constant) {
		if (Cinders::needs_to_be_cindered(pt->constant)) {
			pt->cinder = N++;
			CompileValues::to_code_val(pt->constant);
			current_pdef->cinder_kinds[pt->cinder] = Specifications::to_kind(pt->constant);
		} else {
			pt->cinder = -1;
		}
	}
	return N;
}

@ Symmetrically, when we come to compiled our deferred proposition function,
we need to declare local variables to hold these cinders.

=
void Cinders::declare(pcalc_prop *prop, pcalc_prop_deferral *pdef) {
	pcalc_prop_deferral *save_current_pdef = current_pdef;
	current_pdef = pdef;
	int N = 0;
	TRAVERSE_VARIABLE(atom);
	TRAVERSE_PROPOSITION(atom, prop)
		for (int i=0; i<atom->arity; i++)
			N = Cinders::cind_declare_in_term(N, &(atom->terms[i]));
	current_pdef = save_current_pdef;
}

int Cinders::cind_declare_in_term(int N, pcalc_term *pt) {
	if (pt->function)
		return Cinders::cind_declare_in_term(N, &(pt->function->fn_of));
	if ((pt->constant) && (pt->cinder >= 0)) {
		TEMPORARY_TEXT(cinder_name)
		WRITE_TO(cinder_name, "const_%d", N++);
		LocalVariables::new_other_as_symbol(cinder_name);
		DISCARD_TEXT(cinder_name)
	}
	return N;
}

@ Given, say, |v == 2|, we return the local variable |const_2| holding cindered
value 2. Speed is not critical here.

=
local_variable *Cinders::find_cinder_var(int v) {
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "const_%d", v);
	local_variable *found = LocalVariables::by_identifier(T);
	DISCARD_TEXT(T)
	return found;
}

@h The kind of terms.
We are now finally able to say what the kind of value of a term to be
compiled is. The only troublesome case is when the term is a cinder; its
kind is then part of the information recorded at deferral time.

=
kind *Cinders::kind_of_term(pcalc_term pt) {
	if (pt.variable >= 0) {
		if (pt.term_checked_as_kind) return pt.term_checked_as_kind;
		return K_object;
	}
	if (pt.constant) {
		if (pt.cinder >= 0) {
			if (current_pdef == NULL)
				internal_error("cindered term outside of deferral");
			return current_pdef->cinder_kinds[pt.cinder];
		}
		if (Specifications::is_phrasal(pt.constant))
			Dash::check_value(pt.constant, NULL);
		return Specifications::to_kind(pt.constant);
	}
	if (pt.function) return K_object;
	return NULL; /* never reached, though compilers cannot prove that */
}
