[Propositions::Assert::] Assert Propositions.

To declare that a given proposition is a true statement about the
state of the world when play begins.

@ Inside Inform, the term "the model" means the collection of the following:

(1) The inference subjects capable of holding properties, divided into:
(-1a) World objects, such as "Brazilian frog" or "Jungle Clearing"; each
of which belongs to a kind;
(-1b) Kinds of object, such as "animal" or "room"; each of which
is a kind in turn of another kind, even if only "kind", which is its own kind;
(-1c) Named constant values, such as "red" or "Entire Game"; each of which
belongs to a kind of value;
(-1d) Kinds of value whose values are all named, such as "colour" or "scene".

(2) The associated values, divided into:
(-2a) Properties, such as "open" or "carrying capacity", each of which is
held by some subset of the objects -- for instance, containers and people are
permitted to have the "carrying capacity" property;
(-2b) Global variables, such as "time of day".

(3) Relations between the objects (or in some cases between objects and values
outside the model), such as "containment".

Much else lies outside the model: values like |152| or |"alfalfa"|, rules,
rulebooks, phrases, relations which can only be tested (such as "less than"
or "visibility") and so on. Some of this is excluded because it is beyond
the source text's power to decide facts about it (for instance, that 5 is
less than 6); other matter is left out because it only relates to what
happens to the world after its initial creation (for instances, actions
and activities). The model is that which the source text can decide about
the initial state of things.

@ The initial state of the world is built from the model. Properly speaking
a few other things contribute, too -- such as the entries initially found in
table cells -- but these don't need careful handling, since they are explicitly
declared as literals in the source text: there is no need to analyse their
meaning.

To build or change the model, we assert that propositions about it are true,
using |Propositions::Assert::assert_true| or
|Propositions::Assert::assert_true_about|. This is the only way to
create kinds, instances, global variables, and constant values, and also the
only way to attach properties to objects, to set property values or
the kind of a given object or the value of a global variable, or to declare
that relationships hold.

However, creating new property names and new relations does not count as a
change in the model world. (After all, we could create a new property
called "scent" and a new relation called "admiring", but then choose
not to attach scent to anything or to relate any objects by admiring. The
model world would then not have changed at all.) So creating new properties
and new relations is not done by asserting propositions.

@ |Propositions::Assert::assert_true| asserts propositions in which all variables are
bound (or which have no variables); |Propositions::Assert::assert_true_about| asserts
propositions in which $x$ is free but all other variables are bound, and
substitutes either an object $O$ or a value $V$ into $x$ before asserting.
These two procedures are the entire API, so to speak, for growing or changing
the model. They are used by the detailed-look part of the A-parser,
which takes assertion sentences in the source text and
converts them into a series of propositions which it would like to make true.

Either way those requests come in, they all end up in the central
|Propositions::Assert::prop_true_in_model| procedure, one of the most important choke points within
Inform. |Propositions::Assert::prop_true_in_model| and its delegates -- routines to assert the
truth of various adjectives or relations -- are allowed to call routines such
as |Instances::set_kind| and |Instances::new| which are forbidden for use in the
rest of Inform. These are guarded with the following macro, to ensure that
we don't accidentally break this rule:

@d PROTECTED_MODEL_PROCEDURE
	if (ptim_recursion_depth == 0)
		internal_error("protected model-affecting procedure used outside proposition assert");

= (early code)
int ptim_recursion_depth = 0; /* depth of recursion of |Propositions::Assert::prop_true_in_model| */

@h Entrance.
This first entrance is a mere alias for the second.

=
void Propositions::Assert::assert_true(pcalc_prop *prop, int certitude) {
	Propositions::Assert::prop_true_in_world_model_inner(prop, NULL, certitude);
}

void Propositions::Assert::assert_true_about(pcalc_prop *prop, inference_subject *infs,
	int certitude) {
	Propositions::Assert::prop_true_in_world_model_inner(prop, infs, certitude);
}

@ If we are working along a proposition and reach, say, $door(x)$, we
can only assert that if we know what the value of $x$ is. We therefore keep
an array (or a pair of arrays) holding our current beliefs about the values
of the variables -- this is called the "identification slate".

=
inference_subject **current_interpretation_as_infs = NULL; /* must point to a 26-element array */
parse_node **current_interpretation_as_spec = NULL; /* must point to a 26-element array */

@ Purely to avoid multiply producing a problem message.

=
parse_node *last_couldnt_assert_at = NULL;

void Propositions::Assert::issue_couldnt_problem(adjective *aph, int parity) {
	if (last_couldnt_assert_at != current_sentence) {
		wording W = Adjectives::get_nominative_singular(aph);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantAssertAdjective));
		if (parity == FALSE) Problems::issue_problem_segment(
			"In the sentence %1, you ask me to arrange for something not to be "
			"'%2' at the start of play. This is only possible when an adjective "
			"talks about an either/or property, like 'open'/'closed' - if there "
			"are three or more possibilities then it's ambiguous. Even if there "
			"are only two possibilities, I can't always fix them just on your "
			"request - 'visible'/'invisible', for instance, is something I can "
			"test during play at any time, but not something I can arrange at "
			"the start.");
		else Problems::issue_problem_segment(
			"In the sentence %1, you ask me to arrange for something to be '%2' "
			"at the start of play. There are some adjectives ('open' or 'dark', "
			"for instance) which I can fix, but others are just too vague. For "
			"example, saying 'Peter is visible.' isn't allowed, because it "
			"doesn't tell me where Peter is. Like 'visible', being '%2' is "
			"something I can test during play at any time, but not something "
			"I can arrange at the start.");
		Problems::issue_problem_end();
		last_couldnt_assert_at = current_sentence;
	}
}

@ The second entrance, then, keeps track of the recursion depth but also
ensures that the identification slate is always correct, stacking them
so that an inner |Propositions::Assert::prop_true_in_model| has an independent slate from an outer
one.

=
void Propositions::Assert::prop_true_in_world_model_inner(pcalc_prop *prop, inference_subject *subject,
	int certainty) {
	inference_subject **saved_interpretation_as_infs = current_interpretation_as_infs;
	parse_node **saved_interpretation_as_spec = current_interpretation_as_spec;
	int saved_prevailing_mood = prevailing_mood;
	if (certainty != UNKNOWN_CE) prevailing_mood = certainty;

	inference_subject *ciawo[26]; parse_node *ciats[26];
	@<Establish a new identification slate for the variables in the proposition@>;

	ptim_recursion_depth++;

	Propositions::Assert::prop_true_in_model(prop);

	ptim_recursion_depth--;

	prevailing_mood = saved_prevailing_mood;
	current_interpretation_as_infs = saved_interpretation_as_infs;
	current_interpretation_as_spec = saved_interpretation_as_spec;
}

@ The slate is initially blank unless substitutions for variable $x$ have
been supplied; $x$ of course is variable number 0.

@<Establish a new identification slate for the variables in the proposition@> =
	int k;
	for (k=0; k<26; k++) { ciawo[k] = NULL; ciats[k] = NULL; }
	ciawo[0] = subject; ciats[0] = NULL;
	current_interpretation_as_infs = ciawo; current_interpretation_as_spec = ciats;

@h Main procedure.
As can be seen, |Propositions::Assert::prop_true_in_model| is a simple procedure. After a little
fuss to check that everything is set up right, we simply run through the
proposition one atom at a time.

This is a modest scheme. We are unable to assert any proposition other
than $\exists$, so that we never see their attendant domain brackets.
We are therefore left with a proposition in the form $P_1\land P_2\land ...
\land P_n$ where each $P_i$ is either a predicate-like atom, an $\exists v$
term for some variable $v$, or else $\lnot(...)$ of a similar conjunction.

This is an ambiguous task if we have to assert $\lnot(P\land Q)$, which is
in effect a form of disjunction: $P\land Q$ fails if either is false, so
which do we falsify? We choose both.

That means we can simply assert each atom in turn, with a parity depending on
its nesting in negation brackets, which is nice and easy to write:

=
void Propositions::Assert::prop_true_in_model(pcalc_prop *prop) {
	if (prop == NULL) return;
	@<Record the proposition in the debugging log@>;
	if (Propositions::contains_nonexistence_quantifier(prop))
		@<Issue a problem message explaining that the proposition isn't exact enough@>;
	@<Typecheck the proposition, in case this has not already been done@>;
	@<Check the identification slate against variable usage in the proposition@>;

	TRAVERSE_VARIABLE(pl);
	int now_negated = FALSE;
	TRAVERSE_PROPOSITION(pl, prop) {
		switch(pl->element) {
			case NEGATION_OPEN_ATOM: case NEGATION_CLOSE_ATOM:
				now_negated = (now_negated)?FALSE:TRUE; break;
			case QUANTIFIER_ATOM: @<Assert the truth or falsity of a QUANTIFIER atom@>; break;
			case KIND_ATOM: @<Assert the truth or falsity of a KIND atom@>; break;
			case PREDICATE_ATOM:
				switch (pl->arity) {
					case 1: @<Assert the truth or falsity of a unary predicate@>; break;
					case 2: @<Assert the truth or falsity of a binary predicate@>; break;
				}
				break;
		}
	}
}

@ The certainty, the initial interpretation slate, and the proposition are
combined into a single line in the log:

@<Record the proposition in the debugging log@> =
	int i;
	LOGIF(ASSERTIONS, "::");
	switch(prevailing_mood) {
		case IMPOSSIBLE_CE: LOGIF(ASSERTIONS, " (impossible)"); break;
		case UNLIKELY_CE: LOGIF(ASSERTIONS, " (unlikely)"); break;
		case UNKNOWN_CE: LOGIF(ASSERTIONS, " (no certainty)"); break;
		case LIKELY_CE: LOGIF(ASSERTIONS, " (likely)"); break;
		case INITIALLY_CE: LOGIF(ASSERTIONS, " (initially)"); break;
		case CERTAIN_CE: break;
		default: LOG(" (unknown certainty)"); break;
	}
	for (i=0; i<26; i++) {
		if (current_interpretation_as_infs[i]) {
			LOGIF(ASSERTIONS, " %c = $j", pcalc_vars[i], current_interpretation_as_infs[i]);
		} else if (current_interpretation_as_spec[i]) {
			LOGIF(ASSERTIONS, " %c = $P", pcalc_vars[i], current_interpretation_as_spec[i]);
		}
	}
	LOGIF(ASSERTIONS, " $D\n", prop);

@ It's surprisingly hard to get this problem message, because the assertion-maker
rejects most of the obvious ways to try it with more direct problems. It took
me about twenty sentences to get there ("The car is a vehicle in most rooms
which are dark" will do it).

@<Issue a problem message explaining that the proposition isn't exact enough@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantAssertQuantifier),
		"the relationship you describe is not exact enough",
		"so that I cannot be sure of the initial situation. A specific "
		"relationship would be something like 'the box is a container in "
		"the Attic', rather than 'the box is a container in a room which "
		"is dark' (fine, but which dark room? You must say).");
	return;

@ Almost all propositions derive from sentences in the source text, but a
crucial exception is the first one to be asserted: $\exists x: isakind(x)$,
which creates the kind "kind". Type-checking problems never arise with this
in any case, so it doesn't matter that we wouldn't know what text to use in them.

@<Typecheck the proposition, in case this has not already been done@> =
	wording W = EMPTY_WORDING;
	if (current_sentence) W = Node::get_text(current_sentence);
	if (Propositions::Checker::type_check(prop,
			Propositions::Checker::tc_problem_reporting(W, "be asserting something"))
		!= ALWAYS_MATCH)
		return;

@ This does nothing functional, except that it allows an interpretation as an
instance to trump one as a specification; useful since the A-parser
often specifies $O$ and $V$ as the object and value referred to by a given
node in the parse tree, and since an object is also a value, this often means
that both are given. If we have $O$, then, we cancel $V$.

As we shall see, it's permitted to interpret a bound variable after its
quantifier, but not before, and in particular not at the start of the
proposition. So we require that the slate identify exactly the free
variables, and no others.

@<Check the identification slate against variable usage in the proposition@> =
	int var_states[26];
	int valid = Binding::determine_status(prop, var_states, NULL);
	if (valid == FALSE) internal_error("tried to assert malformed proposition");
	for (int i=0; i<26; i++) {
		int set = FALSE;
		if (current_interpretation_as_spec[i]) set = TRUE;
		if (current_interpretation_as_infs[i]) {
			if (current_interpretation_as_spec[i]) current_interpretation_as_infs[i] = NULL;
			set = TRUE;
		}
		if ((var_states[i] == UNUSED_VST) && (set))
			internal_error("tried to set an unused variable");
		if ((var_states[i] == BOUND_VST) && (set))
			internal_error("tried to set a bound variable");
		if ((var_states[i] == FREE_VST) && (set == FALSE))
			internal_error("failed to set a free variable");
	}

@h Creations.
To assert the truth of $\exists x$, we must create an object to become $x$;
that will provide a value in subsequent uses of $x$ in the same proposition,
so the new value has to be added to the identification slate.

@<Assert the truth or falsity of a QUANTIFIER atom@> =
	int v = pl->terms[0].variable; if (v == -1) internal_error("bad QUANTIFIER atom");
	if (now_negated) internal_error("tried to negate existence");

	wording NW = EMPTY_WORDING;
	int is_a_var = FALSE, is_a_const = FALSE, is_a_kind = FALSE;
	kind *K = NULL;

	@<Scan subsequent atoms to find the name, nature and kind of what is to be created@>;
	@<Create the object and add to the identification slate@>;
	@<Record the new creation in the debugging log@>;

@ Note that all four of these atoms are optional; the proposition might consist
of just $\exists x$ alone, which creates a nameless object, since as usual we
interpret no indication of a kind as meaning "object".

@<Scan subsequent atoms to find the name, nature and kind of what is to be created@> =
	TRAVERSE_VARIABLE(lookahead);
	TRAVERSE_PROPOSITION(lookahead, pl)
		if ((lookahead->arity == 1) && (lookahead->terms[0].variable == v)) {
			if (Atoms::is_CALLED(lookahead)) {
				NW = Atoms::CALLED_get_name(lookahead);
			} else if (lookahead->element == KIND_ATOM) K = lookahead->assert_kind;
			else if ((lookahead->element == PREDICATE_ATOM) && (lookahead->arity == 1)) {
				unary_predicate *up = RETRIEVE_POINTER_unary_predicate(lookahead->predicate);
				if (up->family == is_a_kind_up_family) {
					is_a_kind = TRUE; K = up->assert_kind;
				}
				if (up->family == is_a_var_up_family) {
					is_a_var = TRUE;
				}
				if (up->family == is_a_const_up_family) {
					is_a_const = TRUE;
				}
			}
		}

@ There are really three cases: new kind, new global variable, new instance.

@<Create the object and add to the identification slate@> =
	if (is_a_kind) {
		K = Kinds::new_base(NW, K);
		current_interpretation_as_infs[v] = Kinds::Knowledge::as_subject(K);
		current_interpretation_as_spec[v] = Specifications::from_kind(K);
	} else if ((is_a_var) || (is_a_const)) {
		if (K == NULL) K = K_object;
		nonlocal_variable *q = NonlocalVariables::new_global(NW, K);
		current_interpretation_as_infs[v] = NULL;
		current_interpretation_as_spec[v] = Lvalues::new_actual_NONLOCAL_VARIABLE(q);
		if (is_a_const) NonlocalVariables::make_constant(q, FALSE);
	} else {
		instance *nc = Instances::new(NW, K);
		current_interpretation_as_infs[v] = Instances::as_subject(nc);
		if ((K == NULL) || (Kinds::Behaviour::is_object(K)))
			current_interpretation_as_spec[v] = Rvalues::from_instance(nc);
		else
			current_interpretation_as_spec[v] = Rvalues::from_instance(nc);
	}

@ It's useful to log the new creation, especially for objects which have
duplicate names to others already made:

@<Record the new creation in the debugging log@> =
	if (current_interpretation_as_spec[v]) {
		LOGIF(ASSERTIONS, ":: %c <-- $P\n", pcalc_vars[v], current_interpretation_as_spec[v]);
	} else if (current_interpretation_as_infs[v]) {
		LOGIF(ASSERTIONS, ":: %c <-- $j\n", pcalc_vars[v], current_interpretation_as_infs[v]);
	}

@h Asserting kinds.
Note that we never assert the kind of non-objects. Typechecking won't allow such
an atom to exist unless it states something already true, so there is no need.

Once again, the problem messages in this section for negated attempts are
really quite hard to generate, because the A-parser usually gets there first.
"There is a banana which is something which is not a door." will fall
through here, but it isn't exactly an everyday sentence.

@<Assert the truth or falsity of a KIND atom@> =
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantAssertNonKind),
			"that seems to say what kind something doesn't have",
			"which is too vague. You must say what kind it does have.");
		return;
	}

	inference_subject *subj = Propositions::Assert::subject_of_term(pl->terms[0]);
	instance *ox = InferenceSubjects::as_object_instance(subj);
	if (ox) Instances::set_kind(ox, pl->assert_kind);
	else {
		kind *K = InferenceSubjects::as_kind(subj);
		if (K) Kinds::make_subkind(K, pl->assert_kind);
	}

@h Asserting predicates.

@<Assert the truth or falsity of a unary predicate@> =
	unary_predicate *up = RETRIEVE_POINTER_unary_predicate(pl->predicate);
	UnaryPredicateFamilies::assert(up, now_negated, pl);

@ Binary predicates, unlike unary ones, can only be asserted positively. This
is because $\lnot P(x)$ tells you something fairly definite, whereas $\lnot Q(x, y)$
gives no information about what $z$ might exist, if any, such that $Q(x, z)$.
For instance, knowing that X is not part of Y gives us no help in determining
where X is.

Another difference is that $R(x, y)$ can give you definite information about
the kinds of $x$ and $y$, where they are objects, because binary predicates
have single definitions. (Knowing $locked(x)$, by contrast, doesn't
tell you whether $x$ is a door or a container -- adjectives can have multiple
domains in which they have differing definitions.) In the case of a
proposition produced by sentence conversion, that information is redundant
since appropriate kind atoms were added to the proposition anyway. But we
also assert propositions generated from tree conversion, which don't have
these kind atoms.

@<Assert the truth or falsity of a binary predicate@> =
	if (now_negated) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CantAssertNegatedRelations),
			"that seems to make a negative statement about a relationship",
			"which is too vague. You must make positive assertions.");
		return;
	}

	binary_predicate *bp;
	pcalc_term pt0, pt1;

	@<Determine the BP and terms to be asserted@>;

	parse_node *spec0 = Propositions::Assert::spec_of_term(pt0), *spec1 = Propositions::Assert::spec_of_term(pt1);
	inference_subject *subj0 = Propositions::Assert::subject_of_term(pt0), *subj1 = Propositions::Assert::subject_of_term(pt1);
	if ((subj0) && (spec0 == NULL)) spec0 = InferenceSubjects::as_constant(subj0);
	if ((subj1) && (spec1 == NULL)) spec1 = InferenceSubjects::as_constant(subj1);

	#ifdef IF_MODULE
	if (bp != R_regional_containment) {
	#endif
		kind *K0 = BinaryPredicates::term_kind(bp, 0);
		kind *K1 = BinaryPredicates::term_kind(bp, 1);
		if (Kinds::Behaviour::is_subkind_of_object(K0)) Propositions::Assert::cautiously_set_kind(subj0, K0);
		if (Kinds::Behaviour::is_subkind_of_object(K1)) Propositions::Assert::cautiously_set_kind(subj1, K1);
	#ifdef IF_MODULE
	}
	#endif

	if (BinaryPredicateFamilies::assert(bp, subj0, spec0, subj1, spec1) == FALSE)
		@<Issue a problem message for failure to assert@>;

@<Issue a problem message for failure to assert@> =
	LOG("$2 on ($j, $P; $j, $P)\n", bp, subj0, spec0, subj1, spec1);

	if ((Rvalues::is_nothing_object_constant(spec0)) ||
		(Rvalues::is_nothing_object_constant(spec1)))
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_RelationFailedOnNothing),
			"that is an assertion which involves 'nothing'",
			"which looks as if it might be trying to give me negative rather "
			"than positive information. There's no need to tell me something "
			"like 'Nothing is in the box.': just don't put anything in the box, "
			"and then nothing will be in it.");
	else
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"that is an assertion I can't puzzle out",
			"which seems to involve placing two things in some sort of "
			"relationship, but if so then I can't make it work. Perhaps the "
			"sentence is too complicatedly phrased, and could be broken up "
			"into two or more sentences?");

@ The "is" predicate is not usually assertable, but $is(x, f_R(y))$
can be asserted since it is equivalent to $R(x, y)$ -- this is where we
unravel that. We reject compound uses of functions in this way, but in
practice they hardly ever arise, and could only do so with quite complex
sentences where it seems reasonable to tell the user to write something
simpler and clearer.

@<Determine the BP and terms to be asserted@> =
	bp = RETRIEVE_POINTER_binary_predicate(pl->predicate);
	pt0 = pl->terms[0]; pt1 = pl->terms[1];
	if (bp == R_equality) {
		pcalc_func *the_fn = pt0.function; int side = 1;
		if (the_fn == NULL) { the_fn = pt1.function; side = 0; }
		if (the_fn) {
			if ((pl->terms[side].function) || (the_fn->fn_of.function)) {
				StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
					"that is too complicated an assertion",
					"and cannot be declared as part of the initial situation. (It "
					"does make sense, and could be tested with 'if' - it's just "
					"too difficult to get right as an instruction about the starting "
					"situation.");
				return;
			}
			bp = the_fn->bp; pt0 = pl->terms[side]; pt1 = the_fn->fn_of;
		}
	}

@ As we've already seen, we have to be cautious about the mechanism to draw
inferences about kinds based on the relationships which objects have. Some
cases are easy: if A is worn by B, then B is a person. But "in" can be
very problematic. When one region is in another, we want to suppress any
inferences which might wrongly be drawn about "in": this is a different
kind of containment from the three-dimensional spatial one suggested by
containers and rooms. It also complicates things that a backdrop can be
"in" a region. So we play very safe and make no guesses about regions or
the first term of |R_regional_containment|.

We also never deduce "thing" as the kind by this mechanism. This is
because instances of "object" with no apparent declared kind are made into
things by default when we complete the model world anyway; so there is no
need to risk setting the kind here at this stage.

=
void Propositions::Assert::cautiously_set_kind(inference_subject *inst, kind *k) {
	if ((inst == NULL) || (k == NULL)) return;
	#ifdef IF_MODULE
	if (Kinds::eq(k, K_thing)) return;
	#endif
	instance *instance_wo = InferenceSubjects::as_object_instance(inst);
	if (instance_wo == NULL) return;
	Instances::set_kind(instance_wo, k);
}

@h Evaluating terms.
In asserting a proposition, we are in effect acting as an interpreter rather
than a compiler. Given any term, we need to produce either an object $O$ or a
more general value $V$. Recall that a term can be

(a) a constant $C$,
(b) a variable $v$, or
(c) a function $f_R(t)$ for another term $t$.

We are unable, at compile-time, to evaluate $f_R(t)$ for any relation $R$,
and won't even try. We can evaluate a variable using the interpretation
slate -- that was its whole purpose. So the only case left is a constant:

=
parse_node *Propositions::Assert::spec_of_term(pcalc_term pt) {
	if (pt.function) return NULL;
	if (pt.variable >= 0) return current_interpretation_as_spec[pt.variable];
	return pt.constant;
}

@ The analogous routine to extract an instance, which normally takes
precedence, is more convoluted. First, we could be looking at the name of a
kind -- in "A door is usually closed", "door" will appear here as a
description node, and we need to extract the instance of the kind as our
return value. Second, we want to divert all assertions about "the player" so
that they refer to the player object, not to the global variable "the player".

Users tend to expect that they can talk about properties of things as
values, when setting up the world, and since a property value might be
an object, we are going to be careful to reject a |PROPERTY_VALUE_NT|
type with a problem message. In practice the A-parser gets there first,
but just in case.

=
inference_subject *Propositions::Assert::subject_of_term(pcalc_term pt) {
	if (pt.function) return NULL;
	if (pt.variable >= 0) return current_interpretation_as_infs[pt.variable];

	parse_node *spec = pt.constant;

	if (Node::is(spec, CONSTANT_NT))
		return InferenceSubjects::from_specification(spec);

	if (Specifications::is_description(spec)) {
		if (Descriptions::to_instance(spec))
			return Instances::as_subject(Descriptions::to_instance(spec));
		if (Specifications::to_kind(spec))
			return Kinds::Knowledge::as_subject(Specifications::to_kind(spec));
	}

	if (Node::is(spec, NONLOCAL_VARIABLE_NT)) {
		inference_subject *diversion =
			NonlocalVariables::get_alias(Node::get_constant_nonlocal_variable(spec));
		if (diversion) return diversion;
	}

	return NULL;
}

@h Testing at compile-time.
We can, to a more limited extent, also test whether a given proposition is true
of a given inference subject at the current stage of the world model. (This is
necessary for the implications code to work.)

=
int Propositions::Assert::testable_at_compile_time(pcalc_prop *prop) {
	TRAVERSE_VARIABLE(pl);
	TRAVERSE_PROPOSITION(pl, prop) {
		switch(pl->element) {
			case KIND_ATOM: break;
			case PREDICATE_ATOM:
				switch (pl->arity) {
					case 1: @<See if this unary predicate can be tested@>; break;
					case 2: return FALSE;
				}
				break;
			default: return FALSE;
		}
	}
	return TRUE;
}

@<See if this unary predicate can be tested@> =
	unary_predicate *up = RETRIEVE_POINTER_unary_predicate(pl->predicate);
	if (UnaryPredicateFamilies::testable(up) == FALSE) return FALSE;

@ And the actual test:

=
int Propositions::Assert::test_at_compile_time(pcalc_prop *prop, inference_subject *about) {
	if (Propositions::Assert::testable_at_compile_time(prop) == FALSE) return NOT_APPLICABLE;
	TRAVERSE_VARIABLE(pl);
	TRAVERSE_PROPOSITION(pl, prop) {
		switch(pl->element) {
			case KIND_ATOM: @<Test if this kind atom is true@>; break;
			case PREDICATE_ATOM:
				switch (pl->arity) {
					case 1: @<Test if this unary predicate is true@>; break;
				}
				break;
		}
	}
	return TRUE;
}

@<Test if this kind atom is true@> =
	;

@<Test if this unary predicate is true@> =
	unary_predicate *up = RETRIEVE_POINTER_unary_predicate(pl->predicate);
	if (UnaryPredicateFamilies::test(up, about) == FALSE) return FALSE;
