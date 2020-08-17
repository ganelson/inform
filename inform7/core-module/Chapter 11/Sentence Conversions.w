[Calculus::Propositions::FromSentences::] Sentence Conversions.

The third of the three sources of propositions to conjure with:
those which arise by the parsing of complex sentence trees in the S-grammar.

@h The meaning of a sentence.
This section provides a single, but crucial, function to the rest of Inform:
it takes a sentence subtree output by the S-parser and turns it into a proposition.

The sentence subtree can be headed by either a |SV_NT|, representing a
whole sentence, which we turn into a proposition with no free variables; or by
an |SN_NT|, representing a description which includes a relative clause,
such as "an animal which can see the player". In this section we will loosely
refer to the text parsed by either sort of subtree as the "sentence".

The basic idea is simple. The sentence will have a verb phrase (VP), together
with two noun phrases: a subject phrase (SP) and object phrase (OP). English
is an SVO language, so phrases (usually) occur in the sequence SP-VP-OP.
In "Katy examines the painting", "Katy" is the SP and "painting" is
the OP. (Although the subject is sometimes the more active participant, that
isn't always the case: in "the painting is examined by Katy", "the painting"
is now the SP. The subject is what the sentence talks about.) At this point
in the program, the S-parser has turned the sentence into a neat tree structure
identifying the SP, VP and OP. We need to find meanings for the SP, VP and OP
independently, and then combine these into a single proposition representing
the meaning of the whole sentence.

=
int conv_log_depth = 0; /* recursion depth: used only to clarify the debugging log */

pcalc_prop *Calculus::Propositions::FromSentences::S_subtree(int SV_not_SN, wording W, parse_node *A, parse_node *B, pcalc_term *subject_of_sentence, int verb_phrase_negated) {
	parse_node *subject_phrase_subtree = NULL, *object_phrase_subtree = NULL;
	pcalc_prop *subject_phrase_prop, *object_phrase_prop;
	pcalc_term subject_phrase_term = Calculus::Terms::new_constant(NULL); /* unnecessary initialization to pacify clang, which can't prove it's unnecessary */
	pcalc_term object_phrase_term = Calculus::Terms::new_constant(NULL);
	binary_predicate *verb_phrase_relation = NULL;
	pcalc_prop *sentence_prop = NULL;

	@<Check the tree position makes sense, and tell the debugging log@>;

	if (A == NULL) {
		@<Handle a THERE subtree, used for "there is/are NP"@>;
	} else {
		@<Find meaning of the VP as a relation and a parity@>;
		@<Find meanings of the SP and OP as propositions and terms@>;
		@<Bind up any free variable in the OP and sometimes the SP, too@>;
		@<Combine the SP, VP and OP meanings into a single proposition for the sentence@>;
	}

	@<Simplify the resultant proposition@>;
	@<Tell the debugging log what the outcome of the sentence was@>;

	if ((A) && (subject_of_sentence)) *subject_of_sentence = subject_phrase_term;
	return sentence_prop;
}

@<Check the tree position makes sense, and tell the debugging log@> =
	if (A) StandardProblems::s_subtree_error_set_position(Task::syntax_tree(), A);
	if (conv_log_depth == 0) LOGIF(PREDICATE_CALCULUS, "-----------\n");
	conv_log_depth++;
	LOGIF(PREDICATE_CALCULUS, "[%d] Starting fs on: <%W>\n", conv_log_depth, W);

@ And similarly, on the way out:

@<Tell the debugging log what the outcome of the sentence was@> =
	LOGIF(PREDICATE_CALCULUS, "[%d] fs: %W --> $D\n",
		conv_log_depth, W, sentence_prop);
	conv_log_depth--;

@ The English verb "to be" has the syntactic quirk that it likes to have
both SP and OP, even when only when thing is being discussed. We say "it is
raining" and "there are seven continents", inserting "it" and "there"
even though they refer to nothing at all, because we don't like to say
"raining is" or "seven continents are".

At any rate Inform parses a sentence in the form "There is X" or "There
are Y" into a simpler form of tree with just one noun phrase, and no verb
phrase at all. We convert the noun phrase to a proposition $\phi$ in which
$x$ is free, then bind it with $\exists x$ to form $\exists x: \phi(x)$,
making an S-proposition as required.

@<Handle a THERE subtree, used for "there is/are NP"@> =
	if (SV_not_SN == FALSE) internal_error("THERE subtree misplaced");
	parse_node *spec = B->down;
	sentence_prop = Calculus::Propositions::from_spec(spec);
	sentence_prop = Calculus::Variables::bind_existential(sentence_prop, NULL);

@ Here we only locate the subject and object subtrees -- their meanings we
leave for later -- but we do find the content of the verb phrase. Given
the combination of verb and preposition usage (the latter optional), we
extract a binary predicate $B$. Note that we ignore the parity (whether
negated or not), because we've been told that from above.

Of course a VU also records the tense of the verb, but we ignore that here.
It has no effect on the proposition, only on the moment in history to which
it can be applied.

@<Find meaning of the VP as a relation and a parity@> =
	subject_phrase_subtree = A;
	if (subject_phrase_subtree == NULL) StandardProblems::s_subtree_error(Task::syntax_tree(), "SP subtree null");
	parse_node *verb_phrase_subtree = B;
	if (verb_phrase_subtree == NULL) StandardProblems::s_subtree_error(Task::syntax_tree(), "VP subtree null");
	if (verb_phrase_subtree->down == NULL) StandardProblems::s_subtree_error(Task::syntax_tree(), "VP subtree broken");
	object_phrase_subtree = verb_phrase_subtree->down;

	verb_usage *vu = Node::get_vu(verb_phrase_subtree);
	if (vu == NULL) StandardProblems::s_subtree_error(Task::syntax_tree(), "verb null");
	if ((SV_not_SN == FALSE) && (VerbUsages::get_tense_used(vu) != IS_TENSE))
		@<Disallow the past tenses in relative clauses@>;

	preposition *prep = Node::get_prep(verb_phrase_subtree);
	preposition *second_prep = Node::get_second_preposition(verb_phrase_subtree);

	verb_phrase_relation = VerbUsages::get_regular_meaning(vu, prep, second_prep);

@ A sad necessity:

@<Disallow the past tenses in relative clauses@> =
	ExParser::Subtrees::throw_past_problem(FALSE);

@ First Rule. The "meaning" of a noun phrase is a pair $(\phi, t)$,
where $\phi$ is a proposition and $t$ is a term. We read this as "$t$ such
that $\phi$ is true". Exactly one of the following will always be true:
(a) If the NP talks about a single definite thing $C$, then $t=C$ and $\phi = T$,
the empty proposition.
(b) If the NP talks about a single definite thing $C$ but imposes conditions about its current
situation, then $t=v$ for some variable $v$ and $\phi = \exists v: {\it is}(v, C)\land\psi$
where $\psi$ is a description of the conditions with no free variables and which
does not use $v$.
(c) If the NP talks about a single but vague thing, identifying it only by its
current situation, then $t=v$ for some variable $v$ and $\phi$ is a proposition having
$v$ as its unique free variable.
(d) If the NP talks about a range, number or proportion of things, then $t=v$
for some variable $v$ and $\phi = Qv : v\in\lbrace v\mid \psi(v)\rbrace$, where
$v$ is the unique free variable of $\psi$, and $Q$ is a generalised quantifier which
is not $\exists$.

@ As examples of all four cases:
(a) "Reverend Green" returns $t=|Green|$, $\phi = T$ -- a single definite thing.
(b) "Colonel Mustard in the Library" returns $t=x$ such that
$\phi = \exists x: {\it is}(x, |Mustard|)\land{\it in}(|Mustard|, |Library|)$ -- a single definite
thing but subject to conditions.
(c) "A suspect carrying the lead piping" returns $t=x$ and
$\phi = {\it suspect}(x)\land{\it carries}(x, |piping|)$ -- a single but vague thing.
(d) "All the weapons in the Billiard Room" returns $t=x$ and
$\phi = \forall x: x\in\lbrace x\mid {\it weapon}(x)\land{\it in}(x, |Billiard|)\rbrace$ --
a range of things.

@ Thus $\phi$ can contain at most 1 free variable, and then only in case (c).
But why does it do so at all? Why do we return "an open door" as
${\it open}(x)\land{\it door}(x)$? It would be more consistent with the way we
handle "two open doors" to return it as $\exists x: {\it open}(x)\land{\it door}(x)$.
The answer is that if we were only parsing whole sentences (SV-trees) then
it would make no difference, because $x$ ends up bound by $\exists x$
anyway when the final sentence is being put together. But we also want to
parse descriptions. Consider:

>> (1) let L be the list of open doors in the Dining Room;
>> (2) let L be the list of two open doors in the Dining Room;

Here (1) is legal in Inform, (2) is not, because it implies a requirement about
the list which will probably not be satisfied. (Maybe there are three open
doors there, maybe none.) In case (1), |NPstp| applied to "open doors" will
return ${\it open}(x)\land{\it door}(x)$, whose free variable $x$ can
become any single object we might want to test for open-door-ness. But in
case (2), |NPstp| applied to "two open doors" will return
$V_{=2} x: {\it open}(x)\land{\it door}(x)$, and here $x$ is bound, and
can't be set equal to some object being tested.

Or to put this more informally: it's possible for a single item to be an
"open door", but it's not possible for a single item to be (say) "more
than three open doors". So $\phi$ contains a free variable if and only if
the NP describes a single but vague thing.

@ The First Rule is implemented by |Calculus::Propositions::FromSentences::NP_subtree_to_proposition| below, and
we apply it independently to the SP and OP:

@<Find meanings of the SP and OP as propositions and terms@> =
	kind *subject_K = BinaryPredicates::term_kind(verb_phrase_relation, 0);
	if (Kinds::Behaviour::is_subkind_of_object(subject_K)) subject_K = NULL;
 	subject_phrase_prop =
 		Calculus::Propositions::FromSentences::NP_subtree_to_proposition(&subject_phrase_term, subject_phrase_subtree,
			subject_K);

	kind *object_K = BinaryPredicates::term_kind(verb_phrase_relation, 1);
	if (Kinds::Behaviour::is_subkind_of_object(object_K)) object_K = NULL;
	object_phrase_prop =
		Calculus::Propositions::FromSentences::NP_subtree_to_proposition(&object_phrase_term, object_phrase_subtree,
			object_K);

	LOGIF(PREDICATE_CALCULUS, "[%d] subject NP: $0 such that: $D\n",
		conv_log_depth, &subject_phrase_term, subject_phrase_prop);

	LOGIF(PREDICATE_CALCULUS, "[%d] object NP: $0 such that: $D\n",
		conv_log_depth, &object_phrase_term, object_phrase_prop);

@ The First Rule tells us that SP and OP are now each represented by
propositions with either no free variables, or just one, and then only if
the phrase refers to a single but vague thing.

So far we have treated the subject and object exactly alike, running the
same computation on meaning lists generated by the same method. This is
the first point at which the placement as subject rather than object will
start to make a difference:

(i) we always bind a free variable in the object, but
(ii) we only bind a free variable in the subject if we are looking at the
topmost verb in a whole sentence (i.e., for an SV rather than SN subtree).

The SP is called the "subject phrase" because it contributes the subject of
a sentence: what it is a sentence about.
For instance, for an SV-subtree for "a woman is carrying an animal", we
produce $\phi_S = \exists x: {\it woman}(x)$ and $\phi_O = \exists x: {\it animal}(x)$.
But for an SN-subtree for "a woman carrying an animal" -- which vaguely
describes something, in a way that can be tested for any given candidate $x$ --
we produce $\phi_S = {\it woman}(x)$ with $x$ remaining free.

@<Bind up any free variable in the OP and sometimes the SP, too@> =
	if (SV_not_SN) subject_phrase_prop = Calculus::Variables::bind_existential(subject_phrase_prop, &subject_phrase_term);
	object_phrase_prop = Calculus::Variables::bind_existential(object_phrase_prop, &object_phrase_term);

@ Of all the thousands of paragraphs of code in Inform, this is the one which
most sums up "how it works". We started with a sentence in
the source text, and have now extracted the following components of its
meaning: the subject phrase (SP) has become the term $t_S$ subject to the
proposition $\phi_S$ being true; the object phrase (OP) is similarly now a
pair $t_O$ such that $\phi_O$. From the verb phrase (VP), we have found a
binary relation $B$, meant either in a positive sense ($B$ does hold) or a
negative one (it doesn't). And now:

Second Rule. The combined "meaning" $\Sigma$ is as follows:
(1) if we are parsing a whole sentence (i.e., an SV-subtree), or $\phi_S$ is
not in the form $Q x\in\lbrace x\mid\theta(x)\rbrace$, then:
$$ \Sigma = \phi_S \land \phi'_O \land B(t_S, t'_O) $$
if the sense is positive, or
$$ \phi_S \land \lnot(\phi'_O \land B(t_S, t'_O)) $$
if not.
(2) if we are parsing a relative clause (i.e., an SN-subtree), and $\phi_S$ is of the form
$Q x\in\lbrace x\mid\theta(x)\rbrace$, then:
$$ \Sigma = Q x\in\lbrace x\mid\theta(x) \land \phi'_O \land B(t_S, t'_O)\rbrace $$
if the sense is positive, or
$$ Q x\in\lbrace x\mid\theta(x) \land \lnot(\phi'_O \land B(t_S, t'_O)) $$
if not. Here $\phi'_O$ and $t'_O$ are $\phi_O$ and $t_O$ modified to relabel its
variables so that there are no accidental clashes with variables named in
$\phi_S$.

@ That simple rule took the author a long, long time to work out,
so it may be worth a little discussion:

(a) The Second Rule is a generalisation of the way comparison operators like
|==| or |>=| work in conventional programming languages. For if
$t_S$ and $t_O$ are both constants, and $\phi_S$ and $\phi_O$ both
empty, we obtain just $B(t_S, t_O)$ and $\lnot(B(t_S, t_O))$. For instance,
"score is 10" becomes just ${\it is}(|score|, 10)$, which compiles just to
|(score == 10)|.
(b) In general, though, the meaning of an English sentence is not just that
the verb is true, but also that the subject and object make sense. For
"a woman is carrying an animal" to be true, there has to be such a woman,
and such an animal. This is the content of $\phi_S$ and $\phi_O$. So the
formula above can be read as "the subject makes sense, and the object makes
sense, and they relate to each other in the way that the verb claims".
(c) In the case of negation, it's important that we produce
$\phi_S \land \lnot(\phi'_O \land B(t_S, t_O))$ rather than
$\phi_S\land\phi'_O\land\lnot(B(t_S, t_O))$. To see the difference, consider
the sentence "The box does not contain three coins". The first formula,
which is correct, means roughly "it's not true that there are three coins
$x$ such that $x$ is in the box", whereas the second, wrong, means
"three coins $x$ exist such that $x$ is not in the box".
(d) The difference between cases (1) and (2) is actually very slight. Case (2)
arises only when a relative clause is qualifying the range of a collection
of things: for instance, in "every man who is in the Garden", we have
$\phi_S = \forall x\in\lbrace x\mid {\it man}(x)\rbrace$ and then need to
apply the relation ${\it in}(x, |Garden|)$. If we used formula (1)
we would then have
$$ \Sigma = \forall x\in\lbrace x\mid {\it man}(x)\rbrace: {\it in}(x, |Garden|) $$
which means "every man is in the Garden" -- making a statement about
everything covered by $\phi_S$, not restricting the coverage of $\phi_S$,
as a relative clause should. Using formula (2), however, we get:
$$ \Sigma = \forall x\in\lbrace x\mid {\it man}(x)\land {\it in}(x, |Garden|)\rbrace $$
Note that these formulae are identical except for what we might call punctuation.
(e) The modification needed to make $\phi'_O$ out of $\phi_O$ is pretty well
inconsequential. It makes no difference to the meaning of $\phi_O$.
Consider the example "a woman is carrying an animal" once again.
$t_S = x$ and $\phi_S = {\it woman}(x)$, which use $x$; and on the other
hand $t_O = x$ and $\phi_O = {\it animal}(x)$, which also use $x$. Clearly
we don't mean the same $x$ on both sides, so we relabel the OP to get $y$
such that ${\it animal}(y)$. There is not really any asymmetry between the
SP and OP here, because it would have been just as good to relabel the SP.

@ Lemma. The result $\Sigma$ of the Second Rule is a proposition containing
either 0 or 1 free variables; $\Sigma$ has 1 free variable if and only if we
are converting an SN-subtree, and the subject phrase of the sentence describes
a single thing vaguely.

Proof. $\phi_O$ contains no free variables, since we bound it up above,
and the same must be true of its relabelled version $\phi'_O$. If we have
an SV-subtree then $\phi_S$ similarly contains no free variables; we only
leave it unbound for an SN-subtree. In that case, the First Rule tells us that
it has a free variable if and only if the SP describes a single thing vaguely.
The only other content of $\Sigma$ is the predicate $B(t_S, t'_O)$, so extra
free variables can only appear if either $t_S$ or $t'_O$ contains a variable
not already seen in $\phi_S$ and $\phi'_O$. But cases (b), (c) and (d) of
the First Rule make clear that in any pair $(t, \phi)$ arising from a noun
phrase, either $t$ is a constant or else it is a variable appearing in $\phi$.
So the terms of the final $B$ predicate in $\Sigma$ cannot add new free
variables, and the lemma is proved.

By similar argument, if $\phi_S$ and $\phi_O$ are well-formed propositions
(syntactically valid and using variables either freely or within the scope
of quantification) then so is $\Sigma$.

@ Now to implement the Second Rule:

@<Combine the SP, VP and OP meanings into a single proposition for the sentence@> =
	int use_case_2 = FALSE;
	if (SV_not_SN == FALSE)
		subject_phrase_prop = Calculus::Propositions::remove_final_close_domain(subject_phrase_prop, &use_case_2);

	@<Deal with the English irregularity concerning -where words@>;

	LOGIF(PREDICATE_CALCULUS, "[%d] Before renumbering of OP: t = $0, phi = $D\n", conv_log_depth, &object_phrase_term, object_phrase_prop);
	object_phrase_term.variable =
		Calculus::Variables::renumber_bound(object_phrase_prop, subject_phrase_prop, object_phrase_term.variable);
	if (object_phrase_term.variable >= 26) internal_error("bad OP renumbering");
	LOGIF(PREDICATE_CALCULUS, "[%d] After renumbering of OP: t = $0, phi = $D\n", conv_log_depth, &object_phrase_term, object_phrase_prop);

	sentence_prop = subject_phrase_prop;
	if (verb_phrase_negated)
		sentence_prop = Calculus::Propositions::concatenate(sentence_prop, Calculus::Atoms::new(NEGATION_OPEN_ATOM));
	sentence_prop = Calculus::Propositions::concatenate(sentence_prop, object_phrase_prop);
	sentence_prop = Calculus::Propositions::concatenate(sentence_prop,
		Calculus::Atoms::binary_PREDICATE_new(verb_phrase_relation, subject_phrase_term, object_phrase_term));
	if (verb_phrase_negated)
		sentence_prop = Calculus::Propositions::concatenate(sentence_prop, Calculus::Atoms::new(NEGATION_CLOSE_ATOM));

	if (use_case_2)
		sentence_prop = Calculus::Propositions::concatenate(sentence_prop, Calculus::Atoms::new(DOMAIN_CLOSE_ATOM));

	LOGIF(PREDICATE_CALCULUS, "[%d] Initial meaning: $D\n", conv_log_depth, sentence_prop);

@ The following provides for the fact that when one says "X is somewhere",
"X is anywhere", "X is nowhere", or "X is everywhere", one is talking about
the location of X and not X itself. Thus, "the keys are somewhere" means
that they have some location, not that they literally are a location. (This
is irregular because it differs from "something" and "someone".)

@<Deal with the English irregularity concerning -where words@> =
	#ifdef IF_MODULE
	pcalc_prop *k_atom = Calculus::Propositions::composited_kind(object_phrase_prop);
	if ((k_atom) && (Kinds::eq(k_atom->assert_kind, K_room)) &&
		(verb_phrase_relation == R_equality) && (room_containment_predicate)) {
		Calculus::Atoms::set_composited(k_atom, FALSE);
		verb_phrase_relation = BinaryPredicates::get_reversal(room_containment_predicate);
		LOGIF(PREDICATE_CALCULUS, "[%d] Decompositing object: $D\n",
			conv_log_depth, object_phrase_prop);
	}
	#endif

@h Simplification.
Every proposition generated here, whether it arises as "there is/are" plus a
noun phrase or by the Second Rule, is simplified before being returned.
Because of the way the recursion is set up, this means that intermediate
propositions for relative clauses within a sentence are always simplified
before being used to build the whole sentence.

What happens here is that we try a sequence of tactical moves to change
the proposition for the better -- which usually means eliminating bound
variables, where we can: they are a bad thing because they compile to loops
which may be slow and awkward to construct.

Simplifications are allowed to change $\Sigma$ -- indeed that's the whole
idea -- but not $t_S$, the term representing what the sentence talks about.
(Indeed, they aren't even shown what it is.) Moreover, a simplification can
only turn $\Sigma$ to $\Sigma'$ if:

(i) $\Sigma'$ remains a syntactically correct proposition with well-formed
quantifiers,
(ii) $\Sigma'$ has the same number of free variables as $\Sigma$, and
(iii) in all situations and for all possible values of any free variables,
$\Sigma'$ is true if and only if $\Sigma$ is.

Rules (i) and (ii) are checked as we go, with internal errors thrown if ever
they should fail; the checking takes only a trivial amount of time, and I
generally agree with Tony Hoare's maxim that removing checks like this
in the program as shipped to users is like wearing a life-jacket while
learning to sail on dry land, and then taking it off when going to sea.
Still, rule (iii) can only be ensured by writing the routines carefully.

The simplification routines can all be found in "Simplifications".

@d APPLY_SIMPLIFICATION(proposition, simp) {
	int changed = FALSE, NF = Calculus::Variables::number_free(proposition);
	if (proposition) proposition = simp(proposition, &changed);
	if (changed) LOGIF(PREDICATE_CALCULUS, "[%d] %s: $D\n", conv_log_depth, #simp, proposition);
	if ((Calculus::Variables::is_well_formed(proposition) == FALSE) ||
		(NF != Calculus::Variables::number_free(proposition))) {
		LOG("Failed after applying %s: $D", #simp, proposition);
		internal_error(#simp " simplified proposition into one which is not well-formed");
	}
}

@<Simplify the resultant proposition@> =
	if (Calculus::Variables::is_well_formed(sentence_prop) == FALSE) {
		LOG("Failed before simplification: $D", sentence_prop);
		internal_error("tried to simplify proposition which is not well-formed");
	}

	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::nothing_constant);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::use_listed_in);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::negated_determiners_nonex);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::negated_satisfiable);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::make_kinds_of_value_explicit);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::redundant_kinds);

	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::turn_right_way_round);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::region_containment);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::everywhere_and_nowhere);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::reduce_predicates);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::eliminate_redundant_variables);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::not_related_to_something);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::convert_gerunds);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::eliminate_to_have);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::is_all_rooms);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::redundant_kinds);

	Calculus::Variables::renumber(sentence_prop, NULL); /* just for the sake of tidiness */

@ =
pcalc_prop *Calculus::Propositions::FromSentences::simplify(pcalc_prop *sentence_prop) {
	int conv_log_depth = 1;
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::nothing_constant);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::use_listed_in);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::negated_determiners_nonex);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::negated_satisfiable);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::make_kinds_of_value_explicit);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::redundant_kinds);

	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::turn_right_way_round);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::region_containment);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::everywhere_and_nowhere);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::reduce_predicates);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::eliminate_redundant_variables);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::not_related_to_something);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::convert_gerunds);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::eliminate_to_have);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::is_all_rooms);
	APPLY_SIMPLIFICATION(sentence_prop, Calculus::Simplifications::redundant_kinds);

	Calculus::Variables::renumber(sentence_prop, NULL); /* just for the sake of tidiness */
	return sentence_prop;
}

@h The meaning of a noun phrase.
The First Rule tells us to translate a noun phrase (NP) into a pair of a term $t$
and a proposition $\phi$. We read this as "$t$ such that $\phi$ is true".

For reasons explained below, a small amount of context is supplied: if the
term will need to have a particular kind of value, then that kind is given
to us. (But if it only needs to be an object, or if we don't know anything
about its kind, the |K| argument will be |NULL|.)

As can be seen, an NP subtree consists either of an SN subtree representing
two further NPs joined by a verb to make a relative clause, or one of
three basic noun phrases: a value, a description, or a marker for an implied
but missing noun.

=
pcalc_prop *Calculus::Propositions::FromSentences::NP_subtree_to_proposition(pcalc_term *subject_of_NP, parse_node *p,
	kind *K) {
	pcalc_prop *NP_prop = NULL; wording W;
	@<Tell the debugging log about the NP-subtree@>;

	pcalc_term *st = Node::get_subject_term(p);
	if (st) {
		*subject_of_NP = *st;
		NP_prop = Calculus::Propositions::copy(Specifications::to_proposition(p));
	} else {
		if (Specifications::is_description_like(p)) @<This NP was parsed as a description@>
		else if (Node::get_type(p) == UNKNOWN_NT) @<This NP is only a ghostly presence@>
		else @<This NP was parsed as a value@>;
	}

	@<If we have a single adjective which could also be a noun, and a value is required, convert it to a noun@>;
	@<If we have a constant qualified by a substantive proposition, rewrite in terms of variable@>;
	@<Close any open domain group@>;

	@<Verify that the output satisfies the First Rule, throwing internal errors if not@>;
	return NP_prop;
}

@ Just as for SV-subtrees, we tell the debugging log at the start...

@<Tell the debugging log about the NP-subtree@> =
	W = Node::get_text(p);
	conv_log_depth++;
	LOGIF(PREDICATE_CALCULUS, "[%d] Starting Calculus::Propositions::FromSentences::NP_subtree_to_proposition on: <%W>\n",
		conv_log_depth, W);

@ ...and also at the end.

@<Verify that the output satisfies the First Rule, throwing internal errors if not@> =
	if (Calculus::Variables::is_well_formed(NP_prop) == FALSE) internal_error("malformed NP proposition");
	int NF = Calculus::Variables::number_free(NP_prop);
	if (NF >= 2) internal_error("two or more free variables from NP");
	if (subject_of_NP->constant) {
		if (NP_prop) internal_error("constant plus substantive prop from NP");
	} else if (NF == 1) {
		int v = Calculus::Terms::variable_underlying(subject_of_NP);
		if (Calculus::Variables::status(NP_prop, v) != FREE_VST)
			internal_error("free variable from NP but not the preferred term");
	}
	LOGIF(PREDICATE_CALCULUS, "[%d] Calculus::Propositions::FromSentences::NP_subtree_to_proposition: %W --> t = $0, phi = $D\n",
		conv_log_depth, W, subject_of_NP, NP_prop);
	conv_log_depth--;

@ Here we find a constant $C$ and return $t=C$ with a null $\phi$, except
in one case: where $C$ is the name of an either/or property, such as
"closed". In the context of a value, this is a noun -- it identifies
which property we are talking about -- and this is why
|ExParser::Conversion::VAL_subtree_to_spec| returns it as a constant. But inside a sentence, it
has to be considered an adjective, so rather than returning $t = |closed|,
\phi = T$, we return $t=x$ and $\phi = {\it closed}(x)$. If we didn't do
this, text like "the trapdoor is closed" would translate to the
proposition ${\it is}(|trapdoor|, |closed|)$, which would then fail in
type-checking.

(Note that this is a different sort of noun/adjective ambiguity than the
one arising below, which is to do with enumerated value properties.)

@<This NP was parsed as a value@> =
	parse_node *spec = p;
	*subject_of_NP = Calculus::Terms::new_constant(spec);

	if (Rvalues::is_CONSTANT_construction(spec, CON_property)) {
		property *prn = Rvalues::to_property(spec);
		if (Properties::is_either_or(prn)) {
			*subject_of_NP = Calculus::Terms::new_variable(0);
			NP_prop = Calculus::Atoms::unary_PREDICATE_from_aph(Properties::EitherOr::get_aph(prn), FALSE);
		} else if (Properties::Valued::coincides_with_kind(prn)) {
			*subject_of_NP = Calculus::Terms::new_variable(0);
			kind *K = Properties::Valued::kind(prn);
			NP_prop = Calculus::Atoms::KIND_new(K, Calculus::Terms::new_variable(0));
		}
	}

@ If |Calculus::Propositions::from_spec| is given a constant value $C$ then it returns the
proposition ${\it is}(x, C)$: we look out for this and translate it to
$t=C, \phi = T$. Otherwise, $\phi$ can be exactly the proposition returned,
and the first term occurring in it will be chosen as the subject $t$. (In
particular, if $\phi$ opens with a quantifier then $t$ will be the variable
it binds.)

@<This NP was parsed as a description@> =
	parse_node *spec = p;
	NP_prop = Calculus::Propositions::copy(Calculus::Propositions::from_spec(spec));

	if (Calculus::Propositions::match(NP_prop, 2, PREDICATE_ATOM, NULL, END_PROP_HERE, NULL)) {
		pcalc_term *pt = Calculus::Atoms::is_x_equals(NP_prop);
		if (pt) { *subject_of_NP = *pt; NP_prop = NULL; }
	}

	if ((Calculus::Propositions::match(NP_prop, 2, KIND_ATOM, NULL, END_PROP_HERE, NULL)) &&
		(<k-formal-variable-singular>(W))) {
		Calculus::Atoms::set_unarticled(NP_prop, TRUE);
	}

	if (NP_prop) *subject_of_NP = Calculus::Propositions::get_first_cited_term(NP_prop);

@ When Inform reads a condition so abbreviated that both the subject and
the verb have been left out, it assumes the verb is "to be" and that the
subject will be whatever is being worked on. For instance,

>> if an unlocked container, ...

is read as the verb phrase "is" with |ABSENT_SUBJECT_NT| as SP
and "an unlocked container" as OP.

|ABSENT_SUBJECT_NT| nodes are easy to deal with since they translate to the I6
variable |self| in the final compiled code; the |Rvalues::new_self_object_constant| routine
returns a specification which refers to this. From a predicate
calculus point of view, this is just another constant.

@<This NP is only a ghostly presence@> =
	*subject_of_NP = Calculus::Terms::new_constant(Rvalues::new_self_object_constant());

@ Suppose we have a situation like this:

>> Texture is a kind of value. Rough, smooth and jagged are textures.  A thing has a texture.
>> Feeling relates various rooms to one texture. The verb to feel (he feels) implies the feeling relation.

and consider the sentences:

>> [1] the broken bottle is jagged    [2] the Spiky Cavern feels jagged

Now suppose we are working on the NP "jagged". In (1), it's an adjective: we
are talking about a quality of the bottle. But in (2), it's a noun: we are
establishing a relation between two values, the Cavern and the jagged texture.

Up to this point, "jagged" will have produced $t=x$, $\phi={\it jagged}(x)$
in both cases -- the adjectival reading of the word. The way we can tell if we
are in case (2) is if a value of a specific kind (and not an object) is
expected as the outcome. In the case of the equality relation used in (1),
"is", the terms can be anything; but in the case of the feeling relation
used in (2), the second term, corresponding to the noun phrase "jagged" in
this sentence, has to have the kind of value "texture". So we convert it
into noun form, and return $t=|texture|, \phi = T$.

(Note that this is a different sort of noun/adjective ambiguity than the
one arising above, which is to do with either/or properties.)

Another case which can occur is:

>> the bottle provides the property closed

where the presence of the words "the property" needs to alert us that
"closed" is a noun referring to the property itself, not to a nameless
object possessing that property. When the S-parser matches a property in
that way, it assigns a score value of |TRUE| to the relevant ML entry to
show this. (Score values otherwise aren't used for property names.)

@<If we have a single adjective which could also be a noun, and a value is required, convert it to a noun@> =
	if (((Rvalues::is_CONSTANT_construction(p, CON_property)) &&
		(Annotations::read_int(p, property_name_used_as_noun_ANNOT))) || (K)) {
		pcalc_term pct = Calculus::Propositions::convert_adj_to_noun(NP_prop);
		if (pct.constant) { *subject_of_NP = pct; NP_prop = NULL; }
	}


@ If we have so far produced a constant term $t = C$ and a non-null proposition
$\phi$, then we convert $t$ to a new free variable, say $t = y$, we then bind
any free variable in the old $\phi$ and then change to $\exists y: {\it is}(y, C)\land\phi$.
For instance, if we are working on the OP "the box in a room" from this:

>> a thing in the box in a room

then the constant is $C = |box|$, and Sstp returned
$\phi = \exists x: {\it room}(x)\land{\it is}(x, |ContainerOf(box)|)$.

@<If we have a constant qualified by a substantive proposition, rewrite in terms of variable@> =
	if ((subject_of_NP->constant) && (NP_prop)) {
		int y = Calculus::Variables::find_unused(NP_prop);
		LOGIF(PREDICATE_CALCULUS,
			"[%d] Rewriting qualified constant t = $0 (new var %d)\n", conv_log_depth, subject_of_NP, y);
		NP_prop = Calculus::Propositions::concatenate(
			Calculus::Atoms::binary_PREDICATE_new(R_equality, *subject_of_NP, Calculus::Terms::new_variable(y)),
			NP_prop);
		*subject_of_NP = Calculus::Terms::new_variable(y);
		NP_prop = Calculus::Variables::bind_existential(NP_prop, subject_of_NP);
		LOGIF(PREDICATE_CALCULUS,
			"[%d] Rewriting qualified constant: <%W> --> t = $0, phi = $D\n",
			conv_log_depth, W, subject_of_NP, NP_prop);
	}

@ If the NP was something like "at least four open doors", we will so far
have built |QUANTIFIER --> DOMAIN_OPEN --> KIND --> PREDICATE|, and now that
we have reached the end of the noun phrase we need to add a |DOMAIN_CLOSE|
atom. The following is written in a way that guarantees all such open groups
are closed, but in fact there should only ever be one open, so |nq| should
always evaluate to 0 or 1.

@<Close any open domain group@> =
	int i, nq = 0;
	TRAVERSE_VARIABLE(p);
	TRAVERSE_PROPOSITION(p, NP_prop)
		switch (p->element) {
			case DOMAIN_OPEN_ATOM: nq++; break;
			case DOMAIN_CLOSE_ATOM: nq--; break;
		}
	if (nq < 0) internal_error("malformed proposition with too many domain ends");
	for (i=1; i<=nq; i++)
		NP_prop = Calculus::Propositions::concatenate(NP_prop, Calculus::Atoms::new(DOMAIN_CLOSE_ATOM));
