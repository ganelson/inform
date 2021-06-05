[NameResolution::] Name Resolution.

To resolve abbreviated or ambiguous nouns in context of their headings.

@ Every heading must carry with it a linked list of the nouns created in
sentences which belong to it. So when any noun is created, the following
is called to let the current sentence's heading know that it has a new
friend.

@d LOOP_OVER_NOUNS_UNDER(nt, h)
	for (nt=h->list_of_contents; nt; nt=NameResolution::data(nt)->next_under_heading)

=
typedef struct name_resolution_data {
	int heading_count; /* used when tallying up objects under their headings */
	struct noun *next_under_heading; /* next in the list under that */
	int search_score; /* used when searching nouns to parse names */
	struct noun *next_to_search; /* similarly */
} name_resolution_data;

@ When a noun is created by source text under a heading, its NRD is filled in:

=
int nouns_placed_under_headings = 0;
void NameResolution::initialise(noun *N) {
	if (N == NULL) internal_error("tried to initialise resolution data for null noun");
	NameResolution::disturb();
	if (current_sentence) {
		heading *h = Headings::of_wording(Node::get_text(current_sentence));
		if (h) {
			nouns_placed_under_headings++;
			name_resolution_data *nrd = NameResolution::data(N);
			nrd->next_to_search = NULL;
			if (h->last_in_list_of_contents == NULL) h->list_of_contents = N;
			else NameResolution::data(h->last_in_list_of_contents)->next_under_heading = N;
			nrd->next_under_heading = NULL;
			h->last_in_list_of_contents = N;
		}
	}
	NameResolution::verify_divisions();
}

void NameResolution::attach_noun(noun *N) {
	if (current_sentence == NULL) return;
}

name_resolution_data *NameResolution::data(noun *N) {
	if (N == NULL) internal_error("tried to fetch resolution data for null noun");
	return &(N->name_resolution);
}

@ The following verification checks that every noun is listed in the list for
exactly one heading. This is really a test that the source text is well-formed
with everything placed under a heading, and no sentence having fallen through
a crack.

=
void NameResolution::verify_divisions(void) {
	noun *nt; heading *h;
	int total = 0, disaster = FALSE;
	LOOP_OVER(nt, noun)
		NameResolution::data(nt)->heading_count = 0;
	parse_node_tree *T = Task::syntax_tree();
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates)
		LOOP_OVER_NOUNS_UNDER(nt, h)
			NameResolution::data(nt)->heading_count++, total++;
	LOOP_OVER(nt, noun)
		if (NameResolution::data(nt)->heading_count > 1) {
			LOG("$z occurs under %d headings\n",
				nt, NameResolution::data(nt)->heading_count);
			disaster = TRUE;
		}
	if (total != nouns_placed_under_headings) {
		LOG("%d nouns != %d placed under headings\n", total, nouns_placed_under_headings);
		disaster = TRUE;
	}
	if (disaster) internal_error_tree_unsafe("heading contents list failed verification");
}

@ Identifying noun phrases is tricky. Many plausible phrases could refer in
principle to several different instances: "east", for instance, might
mean the direction or, say, "east garden". And what if the source
mentions many chairs, and now refers simply to "the chair"? This problem
is not so acute for nouns referring to abstractions, where we can simply
forbid duplicate definitions and require an exact wording when talking
about them. But for names of IF objects -- which represent the solid and often
repetitive items and places of a simulated world -- it cannot be ducked.
We can hardly tell an Inform author to create at most one item whose
name contains the word "jar", for instance.

All programming languages face similar problems. In C, for instance, a local
variable named |east| will be recognised in preference to a global one of the
same name (to some extent external linking provides a third level again).
The way this is done is usually explained in terms of the "scope" of a
definition, the part of the source for which it is valid: the winner, in
cases of ambiguity, being the definition of narrowest scope which is valid
at the position in question. In our terms, a stand-alone C program has a
heading tree like so, with two semantically meaningful heading levels,
File (0) and Routine (1), and then sublevels provided by braced blocks:
= (text)
	File
	    main()
	    routine1()
	        interior block of a loop
	        ...
	    routine2()
	    ...
=
The resolution of a name at a given position P is unambiguous: find the
heading H to which P belongs; if the name is defined there, accept that;
if not move H upwards and try again; if it is not defined even at File (0)
level, issue an error: the term is undefined.

Inform is different in two respects, one trivial, the other not. The trivial
difference is that an Inform name can be defined midway through the matter
(though as a result of the PM_ revision, ANSI C now also allows variables
to be created mid-block, in fact: and some C compilers even implement this).

The big difference is that in Inform, names are always visible across
headings. They can be used before being defined; Section 2 of Part II is
free to mention the elephant defined in Section 7 of Part VIII, say.
English text is like this: a typical essay has one great big namespace.

We resolve this by searching backwards through recent noun creations in
the current heading, then in the current heading level above that, and so
on up to the top conceptual level of the source. Thus a "chair" in the
current chapter will always have priority over any in previous chapters,
and so on. However, kinds are always given priority over mere instances,
in order that "door" will retain its generic meaning even if, say,
"an oak door" is created.

@ This means that, under every heading, the search sequence is different.
So for the sake of efficiency we construct a linked list of world
objects in priority order the first time we search under a new heading,
then simply use that thereafter: we also keep track of the tail of this
list. Sections other than this one cannot read the list itself, and
use the following definition to iterate through it.

@d LOOP_OVER_NT_SEARCH_LIST(nt)
	for (nt = nt_search_start; nt; nt = NameResolution::data(nt)->next_to_search)

=
noun *nt_search_start = NULL, *nt_search_finish = NULL;

@ The search sequence is, in effect, a cache storing a former computation,
and like all caches it can fall out of date if the circumstances change so
that the same computation would now produce a different outcome. That can
only happen here if a new noun is to be created: the assertion-maker
calls the following routine to let us know.

=
heading *noun_search_list_valid_for_this_heading = NULL; /* initially it's unbuilt */

void NameResolution::disturb(void) {
	noun_search_list_valid_for_this_heading = NULL;
}

@ The headings and subheadings are formed into a tree in which each heading
contains its lesser-order headings. The pseudo-heading exists to be the root
of this tree; the entire text falls under it. It is not a real heading at all,
and has no "level" or "indentation" as such.

=
void NameResolution::make_the_tree(void) {
	Headings::assemble_tree(Task::syntax_tree());
}

heading *NameResolution::pseudo_heading(void) {
	return Headings::root_of_tree(Task::syntax_tree()->headings);
}

@ Leaving aside the cache, then, we build a list as initially empty, then
all nouns of priority 1 as found by recursively searching headings, then all
nouns of priority 2, and so on.

=
void NameResolution::construct_noun_search_list(void) {
	heading *h = NULL;

	@<Work out the heading from which we wish to search@>;

	if ((h == NULL) || (h == noun_search_list_valid_for_this_heading)) return; /* rely on the cache */

	LOGIF(HEADINGS, "Rebuilding noun search list from: $H\n", h);

	@<Start the search list empty@>;

	NameResolution::build_search_list_from(h, NULL, COMMON_NOUN);
	NameResolution::build_search_list_from(h, NULL, PROPER_NOUN);

	@<Verify that the search list indeed contains every noun just once@>;

	noun_search_list_valid_for_this_heading = h;
}

@ Basically, we calculate the search list from the point of view of the
current sentence:

@<Work out the heading from which we wish to search@> =
	if ((current_sentence == NULL) || (Wordings::empty(Node::get_text(current_sentence))))
		internal_error("cannot establish position P: there is no current sentence");
	source_location position_P = Wordings::location(Node::get_text(current_sentence));
	h = Headings::of_location(position_P);

@ The pseudo-heading has no list of contents because all objects are created in
source files, each certainly underneath a File (0) heading, so nothing should
ever get that far.

@<Start the search list empty@> =
	nt_search_start = NULL;
	nt_search_finish = NULL;
	heading *pseud = NameResolution::pseudo_heading();
	pseud->list_of_contents = NULL; /* should always be true, but just in case */

@ The potential for disaster if this algorithm should be incorrect is high,
so we perform a quick count to see if everything made it onto the list
and produce an internal error if not.

@<Verify that the search list indeed contains every noun just once@> =
	int c = 0; noun *nt;
	LOOP_OVER_NT_SEARCH_LIST(nt) c++;
	if (c != nouns_placed_under_headings) {
		LOG("Reordering failed from $H\n", h);
		LOG("%d nouns under headings, %d in ordering\n", nouns_placed_under_headings, c);
		NameResolution::log_all_headings();
		LOG("Making fresh tree:\n");
		NameResolution::make_the_tree();
		NameResolution::log_all_headings();
		internal_error_tree_unsafe("reordering of nouns failed");
	}

@ The following adds all nouns under heading H to the search list, using
its own list of contents, and then recurses to add all objects under
subheadings of H other than the one which has just recursed up to H. With
that done, we recurse up to the superheading of H.

To prove that //NameResolution::build_search_list_from// is called exactly once
for each heading in the tree, forget about the up/down orientation and consider it
as a graph instead. At each node we try going to every possible other node,
except the way we came (at the start of the traverse, the "way we came"
being null): clearly this ensures that all of our neighbours have been
visited. Since every heading ultimately depends from the pseudo-heading,
the graph is connected, and therefore every heading must eventually be
visited. No heading can be visited twice, because that would mean that a
cycle of nodes $H_1, H_2, ..., H_i, H_1$ must exist: since we have a tree
structure, there are no loops, and so $H_i = H_2$, $H_{i-1} = H_3$, and so
on -- we must be walking a path and then retracing our steps in reverse.
That being so, there is a point where we turned back: we went from $H_j$ to
$H_{j+1}$ to $H_j$ again. And this violates the principle that at each node
we move outwards in every direction except the way we came, a
contradiction.

The routine looks as if it may have a large recursion depth -- maybe as
deep as the number of headings -- but because we go downwards and then
upwards, the maximum recursion depth of the routine is less than $2L+1$, where
$L$ is the number of levels in the tree other than the pseudo-heading. This
provides an upper bound of about 21, regardless of the size of the source
text. The running time is linear in both the number of headings and the
number of nouns in the source text.

=
void NameResolution::build_search_list_from(heading *within, heading *way_we_came, int p) {
	noun *nt; heading *subhead;

	if (within == NULL) return;

	LOOP_OVER_NOUNS_UNDER(nt, within)
		if (Nouns::subclass(nt) == p)
			@<Add noun to the end of the search list@>;

	/* recurse downwards through subordinate headings, other than the way we came up */
	for (subhead = within->child_heading; subhead; subhead = subhead->next_heading)
		if (subhead != way_we_came)
			NameResolution::build_search_list_from(subhead, within, p);

	/* recurse upwards to superior headings, unless we came here through a downward recursion */
	if (within->parent_heading != way_we_came)
		NameResolution::build_search_list_from(within->parent_heading, within, p);
}

@<Add noun to the end of the search list@> =
	if (nt_search_finish == NULL) {
		nt_search_start = nt;
	} else {
		if (NameResolution::data(nt_search_finish)->next_to_search != NULL)
			internal_error("end of noun search list has frayed somehow");
		NameResolution::data(nt_search_finish)->next_to_search = nt;
	}
	NameResolution::data(nt)->next_to_search = NULL;
	nt_search_finish = nt;

@ The search list is used for finding best matches in a particular order, the
order being used to break tie-breaks. Note that we return |NULL| if no noun
in the search list has a positive score.

=
void NameResolution::set_noun_search_score(noun *nt, int v) {
	NameResolution::data(nt)->search_score = v;
}

noun *NameResolution::highest_scoring_noun_searched(void) {
	noun *nt, *best_nt = NULL;
	int best_score = 0;
	LOOP_OVER_NT_SEARCH_LIST(nt) {
		int x = NameResolution::data(nt)->search_score;
		if (x > best_score) { best_nt = nt; best_score = x; }
	}
	return best_nt;
}

@ It's a tricky task to choose from a list of possible nouns which might have
been intended by text such as "chair". If the list is empty or contains only
one choice, no problem. Otherwise we will probably have to reorder the noun
search list, and then run through it. The code below looks as if it picks out
the match with highest score, so that the ordering is unimportant, but in fact
the score assigned to a match is based purely on the number of words missed
out (see later): that means that ambiguities often arise between two lexically
similar objects, e.g., a "blue chair" or a "red chair" when the text simply
specifies "chair". Since the code below accepts the first noun with the
highest score, the outcome is thus determined by which of the blue and red
chairs ranks highest in the search list: and that is why the search list is so
important.

@d NOUN_DISAMBIGUATION_LINGUISTICS_CALLBACK NameResolution::choose_highest_scoring_noun

=
noun_usage *NameResolution::choose_highest_scoring_noun(parse_node *p, int common_only) {
	NameResolution::construct_noun_search_list();
	noun *nt;
	LOOP_OVER(nt, noun) NameResolution::set_noun_search_score(nt, 0);
	for (parse_node *p2 = p; p2; p2 = p2->next_alternative) {
		noun_usage *nu = Nouns::usage_from_excerpt_meaning(Node::get_meaning(p2));
		if (Nouns::is_eligible_match(nu->noun_used, common_only))
			NameResolution::set_noun_search_score(nu->noun_used, Node::get_score(p2));
	}
	nt = NameResolution::highest_scoring_noun_searched();
	for (parse_node *p2 = p; p2; p2 = p2->next_alternative) {
		noun_usage *nu = Nouns::usage_from_excerpt_meaning(Node::get_meaning(p2));
		if (nu->noun_used == nt) return nu;
	}
	return NULL; /* should never in fact happen */
}

@h The debugging log.
This is really just for checking the correctness of the code above.

=
void NameResolution::log_headings(heading *h) {
	if (h==NULL) { LOG("<null heading>\n"); return; }
	heading *pseud = NameResolution::pseudo_heading();
	if (h == pseud) { LOG("<pseudo_heading>\n"); return; }
	LOG("H%d ", h->allocation_id);
	if (h->start_location.file_of_origin)
		LOG("<%f, line %d>",
			TextFromFiles::get_filename(h->start_location.file_of_origin),
			h->start_location.line_number);
	else LOG("<nowhere>");
	LOG(" level:%d indentation:%d", h->level, h->indentation);
}

@ And here we log the whole heading tree by recursing through it, and
surreptitiously check that it is correctly formed at the same time.

=
void NameResolution::log_all_headings(void) {
	heading *h;
	parse_node_tree *T = Task::syntax_tree();
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates) LOG("$H\n", h);
	LOG("\n");
	NameResolution::log_heading_recursively(NameResolution::pseudo_heading(), 0);
}

void NameResolution::log_heading_recursively(heading *h, int depth) {
	if (h == NULL) return;
	for (int i=0; i<depth; i++) LOG("  ");
	LOG("$H\n", h);
	if (depth-1 != h->indentation) LOG("*** indentation should be %d ***\n", depth-1);
	NameResolution::log_heading_recursively(h->child_heading, depth+1);
	NameResolution::log_heading_recursively(h->next_heading, depth);
}
