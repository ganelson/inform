[InvocationLists::] Invocation Lists.

Invocation lists are lists of alternate readings of the same wording
to invoke a phrase.

@h Introduction.
Here is a "To..." phrase definition, and then two invocations of it:
= (text as Inform 7)
To advance (the piece - a chess piece) by (N - a number):
	...

Every turn:
	advance the pawn by 2;
	advance false by 10:21 PM.
=
An invocation is a usage of a phrase in a particular case, so here the every
turn rule is making two invocations. Even control structures in Inform are
phrases, so in fact every line of an imperative definition is exactly one
invocation.

Clearly only the first of these invocations makes sense in terms of what the
phrase is being applied to. The truth state "false" is not a chess piece, and
the time "10:21 PM" is not a number. So this invocation will certainly lead
to problem messages being issued, but it is an invocation just the same.

Invocations are stored in the parse tree. The above "every turn" rule comes
out thus:
= (text)
	IMPERATIVE_NT "every turn"
	    CODE_BLOCK_NT
	        INVOCATION_LIST_NT "advance the pawn by 2"
	            INVOCATION_NT "advance the pawn by 2"
	        INVOCATION_LIST_NT "advance the pawn by 2"
	            INVOCATION_NT "advance false by 10:21 PM"
=
Each line of the original definition corresponds to an |INVOCATION_LIST_NT|
node: the possible readings of the text as an invocation are then listed as its
children, which are all |INVOCATION_NT| nodes. In this example the text was
unambiguous, but for a definition like this:
= (text as Inform 7)
Every turn:
	let the good old stand by be a random bishop;
	advance the good old stand by by 1;
=
...the second line can now be read in two different ways:
= (text as Inform 7)
	advance the good old stand by by 1
	        ~~~~~~~~~~~~~~~~~~    ~~~~
	advance the good old stand by by 1
	        ~~~~~~~~~~~~~~~~~~~~~    ~
=
These possibilities each become |INVOCATION_NT| nodes, and therefore the invocation
list for the line has two entries. Those two nodes are joined with |next_alternative|
links, not |next| links, since they are alternative readings of the same text: they
cannot both be right.

Finally, it is worth noting three complications:
(a) Invocation lists arise from expressions as well as from entire code lines,
much as functions in C can be used in expressions, |int x = f(2);| as well
as in void context, |printf("I do have a return value, you know! Nobody cares.")|.
(-1) See //assertions: Imperative Subtrees// for how invocation lists for the body
of imperative definitions are put together.
(-2) See //Conditions and Phrases// for how invocation lists from expressions
are put together.
(b) "Say" phrases are a special case, in that they can perform more than one
invocation. |say "Very cold for [time of day], I think?"| performs three
invocations -- one of |say (T - text)|, one of |say (T - time)|, and then
another of |say (T - text)|. These three invocations are joined by |->next|
not |->next_alternative| links because all three must be performed.
(c) A small number of invocations for adaptive text do not invoke phrases,
but instead print an inflected form of a verb, adjective or similar.

In this section, we provide basic functions for dealing with invocation lists;
similarly, //Invocations// provides tools for dealing with individual invocations;
and in //Parse Invocations// we show how to refine the bare syntax tree for a
definition into the above parse tree structure. But choosing between the
readings, and compiling the result, is done much deeper in the compiler: see
//imperative: Compile Blocks and Lines// for more.

@h Creation and conversion.
Lists are sometimes made new, and sometimes converted from existing but less
thoroughly parsed parts of the syntax tree:

=
parse_node *InvocationLists::new(wording W) {
	parse_node *L = Node::new(INVOCATION_LIST_NT);
	if (Wordings::nonempty(W)) Node::set_text(L, W);
	return L;
}
parse_node *InvocationLists::new_singleton(wording W, parse_node *inv) {
	parse_node *L = InvocationLists::new(W);
	L->down = inv;
	return L;
}
parse_node *InvocationLists::make_into_list_node(parse_node *p) {
	Node::set_type(p, INVOCATION_LIST_NT);
	return p;
}

@h Operations on lists.
Once lists are created, we tend to represent them not by a pointer to the
|INVOCATION_LIST_NT| node but with a pointer to |first_inv|, the first of the
invocations in the list, i.e., the child of the list node.

Using that convention, where |NULL| represents the empty list, this extends
the list by one:

=
parse_node *InvocationLists::add_alternative(parse_node *first_inv, parse_node *inv) {
	if (first_inv == NULL) return inv;
	parse_node *p = first_inv;
	while (p->next_alternative) p = p->next_alternative;
	p->next_alternative = inv;
	return first_inv;
}

@ The following macro abstracts the process of looping through the invocations
in such a list:

@d LOOP_THROUGH_INVOCATION_LIST(inv, first_inv)
	LOOP_THROUGH_ALTERNATIVES(inv, first_inv)

@ And again using this convention, we get:

=
parse_node *InvocationLists::first_reading(parse_node *first_inv) {
	return first_inv;
}

int InvocationLists::length(parse_node *first_inv) {
	int L = 0;
	parse_node *inv;
	LOOP_THROUGH_INVOCATION_LIST(inv, first_inv) L++;
	return L;
}

void InvocationLists::log(parse_node *first_inv) {
	parse_node *inv;
	LOG("Invocation list (%d):\n", InvocationLists::length(first_inv));
	int n = 0;
	LOOP_THROUGH_INVOCATION_LIST(inv, first_inv)
		LOG("P%d: $e\n", n++, inv);
}

void InvocationLists::log_in_detail(parse_node *first_inv) {
	parse_node *inv;
	LOG("Invocation list in detail (%d):\n", InvocationLists::length(first_inv));
	int n = 0;
	LOOP_THROUGH_INVOCATION_LIST(inv, first_inv) {
		LOG("P%d: $e\n", n++, inv);
		Invocations::log_tokens(inv);
	}
}

@h Sorting the invocation list.
This is crucial to the correct running of the compiler, since invocations
earlier in the list are more likely to be accepted than later. The list is
never very long, so performance is not an issue here, but it's a nuisance to
sort a linked list: we must stash it into an array called |pigeon_holes|,
sort that, and then convert it back into a linked list again.

=
typedef struct invocation_sort_block {
	struct parse_node *inv_data;
	int unsorted_position;
} invocation_sort_block;

invocation_sort_block *pigeon_holes = NULL;
int number_of_pigeon_holes = 0;

parse_node *InvocationLists::sort(parse_node *first_inv) {
	int L = InvocationLists::length(first_inv);
	if (L > 0) {
		@<Make sure there are at least L pigeonholes available for sorting into@>;
		@<Copy the list of alternatives into the pigeonholes@>;

		qsort(pigeon_holes, (size_t) L, sizeof(invocation_sort_block),
			InvocationLists::sort_cmp);

		@<Copy the pigeonholes back into the list of alternatives@>;
	}
	return first_inv;
}

@ We allocate 1000 pigeonholes in the first instance, then double each time
we run out. (We will quite likely never run out, as 1000 is plenty. But we
want to avoid all possible arbitrary limits.)

@<Make sure there are at least L pigeonholes available for sorting into@> =
	if (L > number_of_pigeon_holes) {
		number_of_pigeon_holes = 2*L;
		if (number_of_pigeon_holes < 1000)
			number_of_pigeon_holes = 1000;
		pigeon_holes =
			Memory::calloc(number_of_pigeon_holes, sizeof(invocation_sort_block),
				INV_LIST_MREASON);
	}

@<Copy the list of alternatives into the pigeonholes@> =
	int i = 0;
	for (parse_node *ent=first_inv; (i<L) && (ent); i++, ent=ent->next_alternative) {
		pigeon_holes[i].inv_data = ent;
		pigeon_holes[i].unsorted_position = i;
	}

@<Copy the pigeonholes back into the list of alternatives@> =
	parse_node *tail = NULL; first_inv = NULL;
	for (int i=0; i<L; i++) {
		parse_node *i_n = pigeon_holes[i].inv_data; i_n->next_alternative = NULL;
		if (tail) tail->next_alternative = i_n; else first_inv = i_n;
		tail = i_n;
	}

@ So much for the mechanism. The sorting order ranks invocations first (a) by
logical priority of phrases -- see //assertions: To Phrase Family//; then,
in cases of a tie, (b) by the order in which the excerpt parser found the
possible reading.

Note that sequence counts for phrases, and unsorted positions in the list,
are both unique. This is important since it means //InvocationLists::sort_cmp//
never produces a tie (i.e. returns 0) unless |i1 == i2|; so the fact that |qsort|
applies an unstable sorting algorithm does not affect the result -- we are
exactly defining the order of the list.

=
int InvocationLists::sort_cmp(const void *i1, const void *i2) {
	invocation_sort_block *isb1 = (invocation_sort_block *) i1;
	invocation_sort_block *isb2 = (invocation_sort_block *) i2;

	/* (a) sort by logical priority of phrases */
	int delta =
		ToPhraseFamily::sequence_count(Node::get_phrase_invoked(isb1->inv_data)) -
		ToPhraseFamily::sequence_count(Node::get_phrase_invoked(isb2->inv_data));
	if (delta != 0) return delta;

	/* (b) sort by creation sequence */
	return isb1->unsorted_position - isb2->unsorted_position;
}
