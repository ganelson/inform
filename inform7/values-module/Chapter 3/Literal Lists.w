[Lists::] Literal Lists.

Parsing and vetting the kinds of literal lists written in braces.

@ Literal lists in Inform are written in braces: for example,

>> let L be {2, 12, 13};

Here "{2, 12, 13}" is parsed to an rvalue specification. Various syntactic
things can go wrong with those commas and braces, which must be detected, and
Inform must also work out the kind -- here, it's "list of numbers".

Note that the empty list "{}" is valid as a constant, but that it contains
no indication of its kind -- this must be determined from context.

The following Preform grammar handles that:

=
<s-literal-list> ::=
	\{ \} |              ==> { -, Lists::at(Lists::empty_literal(Wordings::last_word(W)), W) }
	\{ <list-conts> \}   ==> { -, Lists::at(RP[1], W) }

<list-conts> ::=
	<list-entry> , <list-conts> |  ==> { 0, Lists::add(RP[1], RP[2], W, R[1]) }
	<list-entry>                   ==> { 0, Lists::add(RP[1], Lists::empty_literal(W), W, R[1]) }

<list-entry> ::=
	<s-value> |  ==> { FALSE, RP[1] }
	......       ==> { TRUE, Specifications::new_UNKNOWN(W) }

@ And the result of this grammar, if it matches, is an rvalue made thus:

=
parse_node *Lists::at(literal_list *L, wording W) {
	return Rvalues::from_wording_of_list(Lists::kind_of_ll(L, FALSE), W);
}

@ Each different literal list (LL) found in the source text generates an
instance of the following structure. Note that:
(1) every LL structure represents a syntactically well-formed list, in which
braces and commas balance; and
(2) there can be at most one LL structure at any word position.

=
typedef struct literal_list {
	struct wording unbraced_text; /* position in the source of quoted text, excluding braces */
	struct parse_node *list_text; /* used for problem reporting only */
	int listed_within_code; /* appears within a phrase, rather than (say) a table entry? */

	struct kind *entry_kind; /* i.e., of the entries, not the list */
	int kinds_known_to_be_inconsistent; /* problem(s) thrown when parsing these */
	struct llist_entry *first_llist_entry; /* linked list of contents */

	struct package_request *ll_package; /* which will be the enclosure for... */
	struct inter_name *ll_iname;

	int list_compiled; /* lists are compiled at several different points: has this one been done? */

	CLASS_DEFINITION
} literal_list;

@ I believe "llath" is the Welsh word for "yard": not sure about "llist".

=
typedef struct llist_entry {
	struct parse_node *llist_entry_value;
	struct llist_entry *next_llist_entry;
	CLASS_DEFINITION
} llist_entry;

@ These structures are built incrementally, adding one |llist_entry| at a time.
They begin with a call to:

=
literal_list *Lists::empty_literal(wording W) {
	literal_list *ll = Lists::find_literal(Wordings::first_wn(W));
	if (ll == NULL) {
		ll = CREATE(literal_list);
		ll->list_compiled = FALSE;
	}
	ll->unbraced_text = W; ll->entry_kind = K_nil;
	ll->listed_within_code = FALSE;
	ll->kinds_known_to_be_inconsistent = FALSE;
	ll->ll_iname = NULL;
	ll->first_llist_entry = NULL;
	ll->list_text = NULL;
	ll->ll_package = Emit::current_enclosure();
	RTKinds::ensure_basic_heap_present();
	return ll;
}

@ Parsing is quadratic in the number of constant lists in the source text,
which is in principle a bad thing, but in practice the following causes no
speed problems even on large-scale tests. If it becomes a problem, we can
easily trade the time spent here for memory, by attaching a pointer to
each word in the source text, or for complexity, by constructing some kind
of binary search tree.

=
literal_list *Lists::find_literal(int incipit) {
	literal_list *ll;
	LOOP_OVER(ll, literal_list)
		if (Wordings::first_wn(ll->unbraced_text) == incipit)
			return ll;
	return NULL;
}

@ Note that the entry kind is initially unknown, and it's not even decided
for sure when we add the first entry. Here's how each entry is added,
recursing right to left (i.e., reversing the direction of reading):

=
literal_list *Lists::add(parse_node *spec, literal_list *ll, wording W, int bad) {
	llist_entry *lle = CREATE(llist_entry);
	lle->next_llist_entry = ll->first_llist_entry;
	ll->first_llist_entry = lle;
	lle->llist_entry_value = spec;
	literal_list *ll2 = Lists::find_literal(Wordings::first_wn(W));
	if (ll2) ll = ll2;
	ll->unbraced_text = W;
	if (bad) ll->kinds_known_to_be_inconsistent = TRUE;
	return ll;
}

@ With all the entries in place, we now have to reconcile their kinds, if
that's possible. Problems are only issued on request, and with the current
sentence cut down to just the list itself -- since otherwise we might be
printing out an entire huge table to report a problem in a single entry
which happens to be a malformed list.

=
kind *Lists::kind_of_ll(literal_list *ll, int issue_problems) {
	parse_node *cs = current_sentence;
	if (issue_problems) {
		if (ll->list_text == NULL)
			ll->list_text = Diagrams::new_UNPARSED_NOUN(ll->unbraced_text);
		current_sentence = ll->list_text;
	}
	kind *K = K_nil;
	llist_entry *lle;
	for (lle = ll->first_llist_entry; lle; lle = lle->next_llist_entry) {
		parse_node *spec = lle->llist_entry_value;
		if (!Node::is(spec, UNKNOWN_NT)) {
			if (Conditions::is_TEST_ACTION(spec))
				Dash::check_value_silently(spec, K_stored_action);
			else
				Dash::check_value_silently(spec, NULL);
		}
		spec = NonlocalVariables::substitute_constants(spec);
		kind *E = NULL;
		@<Work out the entry kind E@>;
		if (Kinds::eq(K, K_nil)) K = E;
		else @<Revise K in the light of E@>;
	}
	if (ll->kinds_known_to_be_inconsistent) K = K_nil;
	ll->entry_kind = K;
	current_sentence = cs;
	return Kinds::unary_con(CON_list_of, K);
}

@<Work out the entry kind E@> =
	if (Node::is(spec, UNKNOWN_NT)) {
		if (issue_problems) @<Issue a bad list entry problem@>;
		ll->kinds_known_to_be_inconsistent = TRUE;
		E = K;
	} else if ((Node::is(spec, CONSTANT_NT) == FALSE) &&
		(Lvalues::is_constant_NONLOCAL_VARIABLE(spec) == FALSE)) {
		if (issue_problems) @<Issue a nonconstant list entry problem@>;
		ll->kinds_known_to_be_inconsistent = TRUE;
		E = K;
	} else {
		E = Specifications::to_kind(spec);
		if (E == NULL) {
			if (issue_problems) @<Issue a bad list entry problem@>;
			ll->kinds_known_to_be_inconsistent = TRUE;
		}
	}

@ The following broadens K to include E, if necessary, but never narrows K.
Thus a list containing a person, a woman and a door will see K become
successively "person", "person" (E being narrower), then "thing" (E being
incomparable, and "thing" being the max of "person" and "door").

@<Revise K in the light of E@> =
	kind *previous_K = K;
	K = Latticework::join(E, K);
	if (Kinds::Behaviour::definite(K) == FALSE) {
		if (issue_problems) @<Issue a list entry kind mismatch problem@>;
		ll->kinds_known_to_be_inconsistent = TRUE;
		break;
	}

@<Issue a bad list entry problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(spec));
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_BadConstantListEntry));
	Problems::issue_problem_segment(
		"The constant list %1 contains an entry '%2' which isn't any "
		"form of constant I'm able to read.");
	Problems::issue_problem_segment(
		"%PNote that lists have to be written with spaces after commas, "
		"so I like '{2, 4}' but not '{2,4}', for instance.");
	Problems::issue_problem_end();

@<Issue a nonconstant list entry problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(spec));
	Problems::quote_spec(3, spec);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_NonconstantConstantListEntry));
	Problems::issue_problem_segment(
		"The constant list %1 contains an entry '%2' which does make sense, "
		"but isn't a constant (it's %3). Only constants can appear as entries in "
		"constant lists, i.e., in lists written in braces '{' and '}'.");
	Problems::issue_problem_end();

@<Issue a list entry kind mismatch problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(spec));
	Problems::quote_kind(3, E);
	Problems::quote_kind(4, previous_K);
	StandardProblems::handmade_problem(Task::syntax_tree(),
		_p_(PM_IncompatibleConstantListEntry));
	Problems::issue_problem_segment(
		"The constant list %1 contains an entry '%2' whose kind is '%3', but "
		"that's not compatible with the kind I had established from looking at "
		"earlier entries ('%4').");
	Problems::issue_problem_end();

@ The following allow other parts of Inform to find the kind of a constant
list at a given word position; either to discover the answer, or to force
problem messages out into the open --

=
kind *Lists::kind_of_list_at(wording W) {
	int incipit = Wordings::first_wn(W);
	literal_list *ll = Lists::find_literal(incipit+1);
	if (ll) return Lists::kind_of_ll(ll, FALSE);
	return NULL;
}

void Lists::check_one(wording W) {
	int incipit = Wordings::first_wn(W);
	literal_list *ll = Lists::find_literal(incipit+1);
	if (ll) Lists::kind_of_ll(ll, TRUE);
}

@ And this checks every list, with problem messages on:

=
void Lists::check(void) {
	if (problem_count == 0) {
		literal_list *ll;
		LOOP_OVER(ll, literal_list)
			Lists::kind_of_ll(ll, TRUE);
	}
}
