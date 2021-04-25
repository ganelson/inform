[Deferrals::] Deciding to Defer.

To decide whether a proposition can be compiled immediately, in the
body of the current function, or whether it must be deferred to a function of
its own, which is merely called from the current function.

@h Reasons for deferral.
There are a number of possible reasons to defer a proposition, depending on
how it is to be used; we may even want to convert a proposition to a
"multipurpose" deferral function, capable of doing any of these on demand
at runtime.

@d CONDITION_DEFER 1       /* "if S", where S is a sentence */
@d NOW_ASSERTION_DEFER 2   /* "now S" */
@d EXTREMAL_DEFER 3        /* "the heaviest X", where X is a description */
@d LOOP_DOMAIN_DEFER 4     /* "repeat with I running through X" */
@d NUMBER_OF_DEFER 5       /* "the number of X" */
@d TOTAL_DEFER 6           /* "the total P of X" */
@d RANDOM_OF_DEFER 7       /* "a random X" */
@d LIST_OF_DEFER 8         /* "the list of X" */

@d MULTIPURPOSE_DEFER 100  /* potentially any of the above */

=
typedef struct pcalc_prop_deferral {
	int reason; /* what we intend to do with it: one of the |*_DEFER| values above */
	struct pcalc_prop *proposition_to_defer;
	struct parse_node *deferred_from; /* remember where it came from, for Problem reports */
	struct general_pointer defn_ref; /* sometimes we must remember other things too */
	struct kind *cinder_kinds[16]; /* the kinds of value being cindered (see below) */
	struct inter_name *ppd_iname; /* function to implement this */
	struct inter_name *rtp_iname; /* compile a string of the origin text for run-time problems? */
	CLASS_DEFINITION
} pcalc_prop_deferral;

@h Deferral requests.
The following fills out the paperwork to request a deferred proposition.

=
pcalc_prop_deferral *Deferrals::new(pcalc_prop *prop, int reason) {
	pcalc_prop_deferral *pdef = CREATE(pcalc_prop_deferral);
	pdef->proposition_to_defer = prop;
	pdef->reason = reason;
	pdef->deferred_from = current_sentence;
	pdef->rtp_iname = NULL;
	pdef->ppd_iname = Enclosures::new_iname(PROPOSITIONS_HAP, PROPOSITION_HL);
	text_stream *desc = Str::new();
	WRITE_TO(desc, "deferred proposition (reason %d) for ", reason);
	Propositions::write(desc, prop);
	Sequence::queue(&DeferredPropositions::compilation_agent,
		STORE_POINTER_pcalc_prop_deferral(pdef), desc);
	return pdef;
}

@ We cache deferral requests in the case of loop domains, because they are typically
needed in the case of repeat-through loops where the same proposition is used three
times in a row.

=
pcalc_prop *cache_loop_proposition = NULL;
pcalc_prop_deferral *cache_loop_pdef = NULL;

pcalc_prop_deferral *Deferrals::defer_loop_domain(pcalc_prop *prop) {
	pcalc_prop_deferral *pdef;
	if (prop == cache_loop_proposition) return cache_loop_pdef;
	pdef = Deferrals::new(prop, LOOP_DOMAIN_DEFER);
	cache_loop_proposition = prop;
	cache_loop_pdef = pdef;
	return pdef;
}

@h Testing, or deferring a test.
This is the first of several functions serving //Compile Propositions//. In
each case we decide whether or not to defer: if so we return |TRUE| and compile
the necessary code to call the deferred function; and if not return |FALSE| and
do nothing. (If we issue a problem message, we should then return |TRUE|.)

We defer the proposition to a test function of its own if and only if it contains
quantification. The test function returns the verdict |true| or |false|, so to
evaluate the condition we just need to call it.

=
int Deferrals::defer_test_of_proposition(parse_node *substitution, pcalc_prop *prop) {
	if (Propositions::contains_quantifier(prop)) {
		pcalc_prop_deferral *pdef;
		CompileConditions::begin();
		int go_up = FALSE;
		@<If the proposition is a negation, take care of that now@>;
		int NC = Deferrals::count_callings_in_condition(prop);
		if (NC > 0) {
			EmitCode::inv(AND_BIP);
			EmitCode::down();
		}
		pdef = Deferrals::new(prop, CONDITION_DEFER);
		@<Compile the call to the deferred function@>;
		if (NC > 0) {
			Deferrals::prepare_to_retrieve_callings_in_test_context(prop);
			Deferrals::retrieve_callings_in_test_context(prop, NC);
		}
		if (NC > 0) EmitCode::up();
		if (go_up) EmitCode::up();
		CompileConditions::end();
		return TRUE;
	}
	return FALSE;
}

@ This is done purely for the sake of compiling tidier code: if $\phi = \lnot(\psi)$
then we defer $\psi$ instead, negating the result of testing it.

@<If the proposition is a negation, take care of that now@> =
	if (Propositions::is_a_group(prop, NEGATION_OPEN_ATOM)) {
		prop = Propositions::remove_topmost_group(prop);
		EmitCode::inv(NOT_BIP);
		EmitCode::down();
		go_up = TRUE;
	}

@ The first practical problem with deferrals is that the proposition is now
being tested in a different function, with its own stack frame, and that means
that it has no access to the local variables we can see here. Moreover, it
may not even be able to evaluate the term which the proposition is being
applied to. We are therefore going to need to call it as:
= (text)
	f(c_1, ..., c_n, t)
=
where |t| is the term, and |c_1| to |c_n| are any local variables which the
proposition mentions. (We want to avoid the misery of //Local Parking//.)
Those passed values |c_1|, ..., |c_n| are called "cinders", and are covered
more fully in //Cinders and Deferrals//. It is possible, of course, that |n| is
zero, in which case there are no cinders at all.

Note that the term value |t| -- it it exists -- becomes the initial value of
the local variable |x| in the deferred function |f|. This is correct, because
|x| is the free variable in the proposition, so calling the function with |t|
in the |x| argument neatly effects a substitution of $x = t$.

@<Compile the call to the deferred function@> =
	EmitCode::call(pdef->ppd_iname);
	EmitCode::down();
		Cinders::compile_cindered_values(prop, pdef);
		if (substitution) CompileValues::to_code_val(substitution);
	EmitCode::up();

@ The second practical problem concerns callings. If we compile:
= (text as Inform 7)
	if a woman (called the moll) has a weapon (called the gun), ...
=
then we will need to defer the proposition, since it involves quantification
and therefore an implicit search loop. But it is supposed to set two local
variables, "moll" and "gun", with its findings; and they have to end up in
the caller's stack frame, not in the deferred function. Somehow, they need
to be return values of a sort from |f|, but Inter's lack of memory access to
the call stack means that it is impossible for an Inter function to return
multiple values. What to do?

The answer is that |f| copies these values onto a special array called the
"stash of callings". The very last thing that |f| does before it returns
is to fill in this list; the very first thing we do on receiving that return
is to extract what we want from it. Because no other activity takes place in
between, there is no risk that some recursive use of propositions will
overwrite the list.

For example, our call might then become
= (text)
	(f(c_1, ..., c_n, t) && (t_2=stash-->0, t_3=stash-->1, true))
=
which safely transfers the values to locals |t_2| and |t_3| of |R|. Note that
Inter evaluates conditions joined by |&&| from left to right, so we can be
certain that |f| has been called and has returned |true| before we get to the
setting of |t_2| and |t_3|.

@ Here we find out what size of deferred list we will need:

=
int Deferrals::count_callings_in_condition(pcalc_prop *prop) {
	int calling_count = 0;
	TRAVERSE_VARIABLE(atom);
	TRAVERSE_PROPOSITION(atom, prop)
		if (CreationPredicates::is_calling_up_atom(atom))
			calling_count++;
	return calling_count;
}

@ In both cases (a test, or something other), we will compile an expression
whose side-effects of evaluation will set the necessary calling locals. But
the details differ. Here |f| is a test; |g| is some other function returning
a value.
= (text)
	(f(c_1, ..., c_n, t) && (t_2=stash-->0, t_3=stash-->1, true))
	(stash-->26 = g(c_1, ..., c_n, t), t_2=stash-->0, t_3=stash-->1, stash-->26)
=
The return value of |g|, which must emerge unscathed from this expression, is
stored temporarily in |stash-->26|.

The retrieval must be done in two stages. First, call this; then, in the
case which isn't |as_test|, compile the return value of |g|.

=
void Deferrals::prepare_to_retrieve_callings_in_test_context(pcalc_prop *prop) {
	Deferrals::prepare_to_retrieve_callings(prop, TRUE);
}
void Deferrals::prepare_to_retrieve_callings_in_other_context(pcalc_prop *prop) {
	Deferrals::prepare_to_retrieve_callings(prop, FALSE);
}
void Deferrals::prepare_to_retrieve_callings(pcalc_prop *prop, int as_test) {
	inter_name *stash = LocalParking::callings();
	if (CreationPredicates::contains_callings(prop)) {
		if (as_test) {
			EmitCode::inv(SEQUENTIAL_BIP); /* (1) */
			EmitCode::down();
		} else {
			EmitCode::inv(SEQUENTIAL_BIP); /* (2) */
			EmitCode::down();
				EmitCode::inv(STORE_BIP); /* (3) */
				EmitCode::down();
					EmitCode::inv(LOOKUPREF_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, stash);
						EmitCode::val_number(26);
					EmitCode::up();
		}
	}
}

@ Second, call one of the following functions:

=
void Deferrals::retrieve_callings_in_test_context(pcalc_prop *prop, int NC) {
	if (NC > 0) Deferrals::retrieve_callings_inner(prop, NC, TRUE);
}
void Deferrals::retrieve_callings_in_other_context(pcalc_prop *prop) {
	int NC = Deferrals::count_callings_in_condition(prop);
	if (NC > 0) Deferrals::retrieve_callings_inner(prop, NC, FALSE);
}

void Deferrals::retrieve_callings_inner(pcalc_prop *prop, int NC, int as_test) {
	if (as_test == FALSE) {
		EmitCode::up(); /* closes (3) */
		EmitCode::inv(SEQUENTIAL_BIP); /* (4) */
		EmitCode::down();
	}
	inter_name *stash = LocalParking::callings();
	int calling_count = 0, downs = 0;
	TRAVERSE_VARIABLE(atom);
	TRAVERSE_PROPOSITION(atom, prop)
		if (CreationPredicates::is_calling_up_atom(atom))
			@<Retrieve this calling@>;
	while (downs > 0) { EmitCode::up(); downs--; }
	if (as_test) {
		EmitCode::val_true();
		EmitCode::up(); /* closes (1) */
	} else {
		EmitCode::inv(LOOKUP_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, stash);
			EmitCode::val_number(26);
		EmitCode::up();
		EmitCode::up(); /* closes (4) */
		EmitCode::up(); /* closes (2) */
	}
}

@<Retrieve this calling@> =
	wording W = CreationPredicates::get_calling_name(atom);
	local_variable *local =
		LocalVariables::ensure_calling(W, CreationPredicates::what_kind_of_calling(atom));
	calling_count++;
	if (calling_count < NC) {
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
		downs++;
	}
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		inter_symbol *local_s = LocalVariables::declare(local);
		EmitCode::ref_symbol(K_value, local_s);
		EmitCode::inv(LOOKUP_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, stash);
			EmitCode::val_number((inter_ti) (calling_count - 1));
		EmitCode::up();
	EmitCode::up();
	if (as_test) CompileConditions::add_calling(local);

@ The following function can be used when:
(*) we want to force deferral in all cases, regardless of the proposition, and
(*) we want to disallow all callings.

=
inter_name *Deferrals::function_to_test_description(parse_node *spec) {
	pcalc_prop *prop = Specifications::to_proposition(spec);
	if (CreationPredicates::contains_callings(prop)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_CantCallDeferredDescs),
			"'called' can't be used when testing a description",
			"since it would make a name for something which existed only so temporarily "
			"that it couldn't be used anywhere else.");
		return NULL;
	} else {
		pcalc_prop_deferral *pdef = Deferrals::new(prop, CONDITION_DEFER);
		return pdef->ppd_iname;
	}
}

@h Forcing with now, or deferring the force.
Again, we defer this if and only if there is quantification. But everything
is much easier here: we're in a void context, and we don't have callings.

=
int Deferrals::defer_now_proposition(pcalc_prop *prop) {
	if (Propositions::contains_quantifier(prop)) {
		pcalc_prop_deferral *pdef = Deferrals::new(prop, NOW_ASSERTION_DEFER);
		EmitCode::call(pdef->ppd_iname);
		EmitCode::down();
		Cinders::compile_cindered_values(prop, pdef);
		EmitCode::up();
		return TRUE;
	}
	return FALSE;
}

@h Other uses.
Unlike "now" and testing, the other ways to use propositions -- for example,
counting matches with "the number of ..." -- can take a description which
might not be a constant. The following gives a general way to call a deferred
function for one of those other purposes, allowing for callings.

Callings can indeed occur, as in the example "a random person in a room (called
the haven)". |RandomCalling| is a useful test case for this function.

=
void Deferrals::call_deferred_fn(pcalc_prop *prop,
	int reason, general_pointer data, kind *K) {
	pcalc_prop_deferral *pdef = Deferrals::new(prop, reason);
	pdef->defn_ref = data;
	Deferrals::prepare_to_retrieve_callings_in_other_context(prop);
	int arity = Cinders::count(prop, pdef);
	if (K) arity = arity + 2;
	switch (arity) {
		case 0: EmitCode::inv(INDIRECT0_BIP); break;
		case 1: EmitCode::inv(INDIRECT1_BIP); break;
		case 2: EmitCode::inv(INDIRECT2_BIP); break;
		case 3: EmitCode::inv(INDIRECT3_BIP); break;
		case 4: EmitCode::inv(INDIRECT4_BIP); break;
		default: internal_error("indirect function call with too many arguments");
	}
	EmitCode::down();
	EmitCode::val_iname(K_value, pdef->ppd_iname);
	Cinders::compile_cindered_values(prop, pdef);
	if (K) {
		Frames::emit_new_local_value(K);
		RTKinds::emit_strong_id_as_val(Kinds::unary_construction_material(K));
	}
	EmitCode::up();
	Deferrals::retrieve_callings_in_other_context(prop);
}

@h Multipurpose descriptions.
Descriptions in the form $\phi(x)$, where $x$ is free, are also sometimes
converted into values -- this is the kind of value "description". The
Inter representation is (the address of) a function |D| which, in general,
performs task $u$ on value $v$ when called as |D(u, v)|, where $u$ is
expected to be one of the following values. (Note that $v$ is only needed
in the first two cases.)

These numbers must be negative, since they need to be different from
every valid member of a quantifiable domain (objects, enumerated kinds, truth
states, times of day, and so on).

@d CONDITION_DUSAGE -1   /* return |true| iff $\phi(v)$ */
@d LOOP_DOMAIN_DUSAGE -2 /* return the next $x$ after $v$ such that $\phi(x)$ */
@d NUMBER_OF_DUSAGE -3   /* return the number of $w$ such that $\phi(w)$ */
@d RANDOM_OF_DUSAGE -4   /* return a random $w$ such that $\phi(w)$, or 0 if none exists */
@d TOTAL_DUSAGE -5       /* return the total value of a property among $w$ such that $\phi(w)$ */
@d EXTREMAL_DUSAGE -6    /* return the maximal property value among such $w$ */
@d LIST_OF_DUSAGE -7     /* return the list of $w$ such that $\phi(w)$ */

@ Multi-purpose description routines are pretty dandy, then, but they have
one big drawback: they can't be passed cinders, because they might be called
from absolutely anywhere. (And, once again, we are trying to avoid having to
capture local values as closures.) Hence the following:

=
void Deferrals::compile_multiple_use_proposition(value_holster *VH,
	parse_node *spec, kind *K) {

	int negate = FALSE;
	quantifier *q = Descriptions::get_quantifier(spec);
	if (q == not_exists_quantifier) negate = TRUE;
	else if ((q) && (q != for_all_quantifier)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_spec(2, spec);
		StandardProblems::handmade_problem(Task::syntax_tree(),	
			_p_(BelievedImpossible));
		Problems::issue_problem_segment(
			"In %1 you wrote the description '%2' in the context of a value, "
			"but descriptions used that way are not allowed to talk about "
			"quantities. For example, it's okay to write 'an even number' "
			"as a description value, but not 'three numbers' or 'most numbers'.");
		Problems::issue_problem_end();
	}
	pcalc_prop *prop = SentencePropositions::from_spec(spec);
	if (negate) {
		prop = Propositions::concatenate(Atoms::new(NEGATION_OPEN_ATOM), prop);
		prop = Propositions::concatenate(prop, Atoms::new(NEGATION_CLOSE_ATOM));
	}
	prop = Propositions::concatenate(
		KindPredicates::new_atom(K, Terms::new_variable(0)), prop);
	if (TypecheckPropositions::type_check(prop,
		TypecheckPropositions::tc_no_problem_reporting()) == NEVER_MATCH) return;
	parse_node *example = NULL;
	if (Binding::detect_locals(prop, &example) > 0) {
		LOG("Offending proposition: $D\n", prop);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(example));
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_LocalInDescription));
		Problems::issue_problem_segment(
			"You wrote %1, but descriptions used as values are not allowed to "
			"contain references to temporary values (defined by 'let', or by loops, "
			"or existing only in certain rulebooks or actions, say) - unfortunately "
			"'%2' is just such a temporary value. The problem is that it may well "
			"not exist any more when the description needs to be used, in another "
			"time and another place.");
		Problems::issue_problem_end();
	} else {
		pcalc_prop_deferral *pdef = Deferrals::new(prop, MULTIPURPOSE_DEFER);
		EmitCode::val_iname(K_value, pdef->ppd_iname);
	}
}

@ Because multipurpose descriptions have this big drawback, we want to avoid them
if we possibly can. Fortunately something much simpler will often do. For example,
consider:
= (text)
(1) the number of members of S
(2) the number of closed doors
=
where S, in (1), is a description which appears as a parameter in a phrase.
In (1) we have no way of knowing what S might be, but we can safely assume
that it has been compiled as a multi-purpose description function |D|, and
therefore compile the function call:
= (text as Inform 6)
	D(NUMBER_OF_DUSAGE)
=
But in case (2) it is sufficient to take $\phi(x) = {\it door}(x)\land{\it closed}(x)$,
defer it to function |f| with reason |NUMBER_OF_DEFER|, and then compile just |f()|
to perform the calculation. We never need a multi-purpose description routine for
$\phi(x)$ because it only occurs in this one context.

@ We now perform this trick for "number of":

=
int Deferrals::defer_number_of_matches(parse_node *spec) {
	if (Deferrals::spec_is_variable_of_kind_description(spec)) {
		EmitCode::inv(INDIRECT1_BIP);
		EmitCode::down();
			CompileValues::to_code_val(spec);
			EmitCode::val_number((inter_ti) NUMBER_OF_DUSAGE);
		EmitCode::up();
	} else {
		pcalc_prop *prop = SentencePropositions::from_spec(spec);
		CompilePropositions::verify_descriptive(prop,
			"a number of things matching a description", spec);
		Deferrals::call_deferred_fn(prop, NUMBER_OF_DEFER, NULL_GENERAL_POINTER, NULL);
	}
	return TRUE;
}

@ By "variable", we actually mean any stored value:

=
int Deferrals::spec_is_variable_of_kind_description(parse_node *spec) {
	if ((Lvalues::is_lvalue(spec)) &&
		(Kinds::get_construct(Specifications::to_kind(spec)) == CON_description))
		return TRUE;
	return FALSE;
}

@ And now for "list of":

=
int Deferrals::defer_list_of_matches(parse_node *spec, kind *K) {
	if (Deferrals::spec_is_variable_of_kind_description(spec)) {
		EmitCode::call(Hierarchy::find(LIST_OF_TY_DESC_HL));
		EmitCode::down();
			Frames::emit_new_local_value(K);
			CompileValues::to_code_val(spec);
			RTKinds::emit_strong_id_as_val(Kinds::unary_construction_material(K));
		EmitCode::up();
	} else {
		pcalc_prop *prop = SentencePropositions::from_spec(spec);
		CompilePropositions::verify_descriptive(prop,
			"a list of things matching a description", spec);
		Deferrals::call_deferred_fn(prop, LIST_OF_DEFER, NULL_GENERAL_POINTER, K);
	}
	return TRUE;
}

@ And similarly for "a random ...":

=
int Deferrals::defer_random_match(parse_node *spec) {
	if (Deferrals::spec_is_variable_of_kind_description(spec)) {
		EmitCode::inv(INDIRECT1_BIP);
		EmitCode::down();
			CompileValues::to_code_val(spec);
			EmitCode::val_number((inter_ti) RANDOM_OF_DUSAGE);
		EmitCode::up();
	} else {
		pcalc_prop *prop = SentencePropositions::from_spec(spec);
		CompilePropositions::verify_descriptive(prop,
			"a random thing matching a description", spec);
		kind *K = Propositions::describes_kind(prop);
		if ((K) && (Deferrals::has_finite_domain(K) == FALSE))
			@<Issue random impossible problem@>;
		Deferrals::call_deferred_fn(prop, RANDOM_OF_DEFER, NULL_GENERAL_POINTER, NULL);
	}
	return TRUE;
}

@<Issue random impossible problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RandomImpossible),
		"this asks to find a random choice from a range which is too large or "
		"impractical",
		"so can't be done. For instance, 'a random person' is fine - it's clear "
		"exactly who all the people are, and the supply is limited - but not 'a "
		"random text'.");
	return TRUE;

@ Some kinds are such that all legal values can efficiently be looped through
at run-time, some are not: we can sensibly loop over all scenes, but not
over all texts. We use the term "domain" to mean the set of values which
a loop traverses.

=
int Deferrals::has_finite_domain(kind *K) {
	if (K == NULL) return FALSE;
	if (Kinds::Behaviour::is_object(K)) return TRUE;
	if (Kinds::Behaviour::is_an_enumeration(K)) return TRUE;
	if (Str::len(K->construct->loop_domain_schema) > 0) return TRUE;
	return FALSE;
}

@ And similarly for "total of":

=
int Deferrals::defer_total_of_matches(property *prn, parse_node *spec) {
	if (prn == NULL) internal_error("total of on non-property");
	if (Deferrals::spec_is_variable_of_kind_description(spec)) {
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value,
					Hierarchy::find(PROPERTY_TO_BE_TOTALLED_HL));
				EmitCode::val_iname(K_value, RTProperties::iname(prn));
			EmitCode::up();
			EmitCode::inv(INDIRECT1_BIP);
			EmitCode::down();
				CompileValues::to_code_val(spec);
				EmitCode::val_number((inter_ti) TOTAL_DUSAGE);
			EmitCode::up();
		EmitCode::up();
	} else {
		pcalc_prop *prop = SentencePropositions::from_spec(spec);
		CompilePropositions::verify_descriptive(prop,
			"a total property value for things matching a description", spec);
		Deferrals::call_deferred_fn(prop, TOTAL_DEFER,
			STORE_POINTER_property(prn), NULL);
	}
	return TRUE;
}

@ And the extremal case is pretty well the same, too, with only some fuss over
identifying which superlative is meant. We get here from code like "let X be
the heaviest thing in the wooden box" where there has previously been a
definition of "heavy".

=
int Deferrals::defer_extremal_match(parse_node *spec,
	property *prn, int sign) {
	if (prn == NULL) internal_error("extremal of on non-property");
	if (Deferrals::spec_is_variable_of_kind_description(spec)) {
		EmitCode::inv(SEQUENTIAL_BIP);
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_iname(K_value,
					Hierarchy::find(PROPERTY_TO_BE_TOTALLED_HL));
				EmitCode::val_iname(K_value, RTProperties::iname(prn));
			EmitCode::up();
			EmitCode::inv(SEQUENTIAL_BIP);
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::ref_iname(K_value,
						Hierarchy::find(PROPERTY_LOOP_SIGN_HL));
					EmitCode::val_number((inter_ti) sign);
				EmitCode::up();
				EmitCode::inv(INDIRECT1_BIP);
				EmitCode::down();
					CompileValues::to_code_val(spec);
					EmitCode::val_number((inter_ti) EXTREMAL_DUSAGE);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		measurement_definition *mdef_found = Measurements::retrieve(prn, sign);
		if (mdef_found) {
			pcalc_prop *prop = SentencePropositions::from_spec(spec);
			CompilePropositions::verify_descriptive(prop,
				"an extreme case of something matching a description", spec);
			Deferrals::call_deferred_fn(prop, EXTREMAL_DEFER,
				STORE_POINTER_measurement_definition(mdef_found), NULL);
		}
	}
	return TRUE;
}

@ Finally, the occasionally useful task of seeing if the current value of
the "substitution variable") is within the domain.

=
int Deferrals::defer_if_matches(parse_node *in, parse_node *spec) {
	if (Deferrals::spec_is_variable_of_kind_description(spec)) {
		EmitCode::inv(INDIRECT2_BIP);
		EmitCode::down();
			CompileValues::to_code_val(spec);
			EmitCode::val_number((inter_ti) CONDITION_DUSAGE);
			CompileValues::to_code_val(in);
		EmitCode::up();
	} else {
		CompilePropositions::to_test_as_condition(
			in, SentencePropositions::from_spec(spec));
	}
	return TRUE;
}
