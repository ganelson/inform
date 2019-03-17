[Sentences::Headings::] Headings.

To keep track of the hierarchy of headings and subheadings found
in the source text.

@h Definitions.

@ To take up the narrative of how Inform runs once more, we have read the
source text in from the primary source file and from the extensions it
requested: nothing more will be supplied from disc, and the whole combined
text is arranged as a string of sentence nodes, each direct children of the
root. In this section, we are concerned with HEADING nodes.

Most of these occur when the user has explicitly typed a heading such as:

>> Part VII - The Ghost of the Aragon

The sentence-breaker called |Sentences::Headings::declare| each time it found one of
these, but also when a new source file started, because a file boundary is
construed as beginning with a hidden "heading" of a higher rank than any
other, and the sentence-breaker made a corresponding HEADING node there
too. This is important because the doctrine is that each heading starts
afresh with a new hierarchy of lower-order headings: thus changing the Part
means we can start again with Chapter 1 if we like, and so on. Because each
source file starts with an implicit super-heading, each source file gets
its own independent hierarchy of Volume, and so on. But the convention is
also important because we need to be able to say that every word loaded
from disc ultimately falls under some heading, even if the source text as
typed by the designer does not obviously have any headings in it.

The hierarchy thus runs: File (0), Volume (1), Book (2), Part (3),
Chapter (4), Section (5). (The implementation below allows for even lower
levels of subheading, from 6 to 9, but Inform doesn't use them.) Every run
of NI declares at least two File (0) headings, representing the start of
main text and the start of the Standard Rules, and these latter have a
couple of dozen headings themselves, so the typical number of headings
in a source text is 30 to 100.

@d NO_HEADING_LEVELS 10

@ Although it is implicit in the parse tree already, the heading structure
is not easy to deduce, and so in this section we build a much smaller tree
consisting just of the hierarchy of headings. The heading tree has nodes
made from the following structures:

=
typedef struct heading {
	struct parse_node *sentence_declaring; /* if any: file starts are undeclared */
	struct source_location start_location; /* first word under this heading is here */
	int level; /* 0 for Volume (highest) to 5 for Section (lowest) */
	int indentation; /* in a hierarchical listing */
	int index_definitions_made_under_this; /* for instance, global variables made here? */
	int for_release; /* include this material in a release version? */
	int omit_material; /* if set, simply ignore all of this */
	int use_with_or_without; /* if TRUE, use with the extension; if FALSE, without */
	struct extension_identifier for_use_with; /* e.g. "for use with ... by ..." */
	struct wording in_place_of_text; /* e.g. "in place of ... in ... by ..." */
	struct wording heading_text; /* once provisos have been stripped away */
	struct noun *list_of_contents; /* tagged names defined under this */
	struct noun *last_in_list_of_contents;
	struct heading *parent_heading;
	struct heading *child_heading;
	struct heading *next_heading;
	MEMORY_MANAGEMENT
} heading;

@ The headings and subheadings are formed into a tree in which each heading
contains its lesser-order headings. The pseudo-heading exists to be the root
of this tree; the entire text falls under it. It is not a real heading at all,
and has no "level" or "indentation" as such.

=
heading pseudo_heading; /* The entire source falls under this top-level heading */

@ As an example, a sequence in the primary source text of (Chapter I, Book
Two, Section 5, Chapter I, Section 1, Chapter III) would be formed up into
the heading tree:

	|(the pseudo-heading)  level -1, indentation -1|
	|    (File: Standard Rules)  level 0, indentation 0|
	|        ...|
	|    (File: primary source text)  level 0, indentation 0|
	|        Chapter I  level 4, indentation 1|
	|        Book Two  level 2, indentation 1|
	|            Section 5  level 5, indentation 2|
	|            Chapter I  level 4, indentation 2|
	|                Section 1  level 5, indentation 3|
	|            Chapter III  level 4, indentation 2|

Note that the level of a heading is not the same thing as its depth in this
tree, which we call the "indentation", and there is no simple relationship
between the two numbers. Clearly we want to start at the left margin. If a
new heading is subordinate to its predecessor (i.e., has higher level),
we want to indent further, but by the least amount needed -- a single tap step.
Adjacent equal-level headings are on a par with each other and should have
the same indentation. But when the new heading is lower level than its
predecessor (i.e., more important) then the indentation decreases to
match the last one equally important.

We can secure the last of those properties with a formal definition as
follows. The level $\ell_n$ of a heading depends only on its wording (or
source file origin), but the indentation of the $n$th heading, $i_n$,
depends on $(\ell_1, \ell_2, ..., \ell_n)$, the sequence of all levels so
far:
$$ i_n = i_m + 1 \qquad {\rm where}\qquad m = {\rm max} \lbrace j \mid 0\leq j < n, \ell_j < \ell_n \rbrace $$
where $\ell_0 = i_0 = -1$, so that this set always contains 0 and is
therefore not empty. We deduce that

(a) $i_1 = 0$ and thereafter $i_n \geq 0$, since $\ell_n$ is never negative again,

(b) if $\ell_k = \ell_{k+1}$ then $i_k = i_{k+1}$, since the set over which
the maximum is taken is the same,

(c) if $\ell_{k+1} > \ell_k$, a subheading of its predecessor, then
$i_{k+1} = i_k + 1$, a single tab step outward.

That establishes the other properties we wanted, and shows that $i_n$ is
indeed the number of tab steps we should be determining.

Note that to calculate $i_n$ we do not need the whole of $(\ell_1, ..., \ell_n)$:
we only need to remember the values of
$$ i_{m(K)},\qquad {\rm where}\qquad m(K) = {\rm max} \lbrace j \mid 0\leq j < n, \ell_j < K \rbrace $$
for each possible heading level $K=0, 1, ..., 9$. This requires much less
storage: we call it the "last indentation above level $K$".

This leads to the following algorithm when looking at the headings in any
individual file of source text: at the top of file,

	|for (i=0; i<NO_HEADING_LEVELS; i++) last_indentation_above_level[i] = -1;|

Then parse for headings (they have an easily recognised lexical form); each
time one is found, work out its |level| as 1, ..., 5 for Volume down to Section,
and call:

	|int find_indentation(int level) {|
	|    int i, ind = last_indentation_above_level[level] + 1;|
	|    for (i=level+1; i<NO_HEADING_LEVELS; i++)|
	|        last_indentation_above_level[i] = ind;|
	|    return ind;|
	|}|

While this algorithm is trivially equivalent to finding the depth of a
heading in the tree which we are going to build anyway, it is worth noting
here for the benefit of anyone writing a tool to (let's say) typeset an
Inform source text with a table of contents, or provide a navigation
gadget in the user interface.

@ The primary source text, and indeed the source text in the extensions,
can make whatever headings they like: no sequence is illegal. It is not
for NI to decide on behalf of the author that it is eccentric to place
Section C before Section B, for instance. The author might be doing so
deliberately, to put the Chariot-race before the Baths, say; and the
indexing means that it will be very apparent to the author what the heading
structure currently is, so mistakes are unlikely to last long. This is a
classic case where Inform trying to be too clever would annoy more often
than assist.

@ =
typedef struct name_resolution_data {
	int heading_count; /* used when tallying up objects under their headings */
	struct noun *next_under_heading; /* next in the list under that */
	int search_score; /* used when searching nametags to parse names */
	struct noun *next_to_search; /* similarly */
} name_resolution_data;

@ =
typedef struct contents_entry {
	struct heading *heading_entered;
	struct contents_entry *next;
	MEMORY_MANAGEMENT
} contents_entry;

@h Declarations.
The heading tree is constructed all at once, after most of the sentence-breaking
is done, but since a few sentences can in principle be added later, we watch
for the remote chance of further headings being added, by keeping the following
flag:

=
int heading_tree_made_at_least_once = FALSE;

@ Now, then, the routine |Sentences::Headings::declare| is called by the sentence-breaker
each time it constructs a new HEADING node. (Note that it is not called to
create the pseudo-heading, which does not come from a node.)

A level 0 heading has text (the first sentence which happens to be in the
new source file), but this has no significance other than its location,
and cannot contain information about releasing or about virtual machines.

=
int last_indentation_above_level[NO_HEADING_LEVELS], lial_made = FALSE;

extension_identifier *grammar_eid = NULL;

heading *Sentences::Headings::declare(parse_node *PN) {
	heading *h = CREATE(heading);

	h->parent_heading = NULL; h->child_heading = NULL; h->next_heading = NULL;
	h->list_of_contents = NULL; h->last_in_list_of_contents = NULL;
	h->for_release = NOT_APPLICABLE; h->omit_material = FALSE;
	h->index_definitions_made_under_this = TRUE;
	h->use_with_or_without = NOT_APPLICABLE;
	h->in_place_of_text = EMPTY_WORDING;

	if ((PN == NULL) || (Wordings::empty(ParseTree::get_text(PN))))
		internal_error("heading at textless node");
	internal_error_if_node_type_wrong(PN, HEADING_NT);
	h->sentence_declaring = PN;
	h->start_location = Wordings::location(ParseTree::get_text(PN));
	h->level = ParseTree::int_annotation(PN, heading_level_ANNOT);
	h->heading_text = EMPTY_WORDING;

	if (h->level > 0) @<Parse heading text for release or other stipulations@>;

	if ((h->level < 0) || (h->level >= NO_HEADING_LEVELS)) internal_error("impossible level");
	@<Determine the indentation from the level@>;

	LOGIF(HEADINGS, "Created heading $H\n", h);
	if (heading_tree_made_at_least_once) Sentences::Headings::make_tree();
	return h;
}

@ This implements the indentation algorithm described above.

@<Determine the indentation from the level@> =
	int i;
	if (lial_made == FALSE) {
		for (i=0; i<NO_HEADING_LEVELS; i++) last_indentation_above_level[i] = -1;
		lial_made = TRUE;
	}

	h->indentation = last_indentation_above_level[h->level] + 1;
	for (i=h->level+1; i<NO_HEADING_LEVELS; i++)
	    last_indentation_above_level[i] = h->indentation;

@h Parsing heading qualifiers.

@d PLATFORM_UNMET_HQ 0
@d PLATFORM_MET_HQ 1
@d NOT_FOR_RELEASE_HQ 2
@d FOR_RELEASE_ONLY_HQ 3
@d UNINDEXED_HQ 4
@d USE_WITH_HQ 5
@d USE_WITHOUT_HQ 6
@d IN_PLACE_OF_HQ 7

@<Parse heading text for release or other stipulations@> =
	grammar_eid = &(h->for_use_with);
	current_sentence = PN;

	wording W = ParseTree::get_text(PN);
	while (<heading-qualifier>(W)) {
		switch (<<r>>) {
			case PLATFORM_UNMET_HQ: h->omit_material = TRUE; break;
			case NOT_FOR_RELEASE_HQ: h->for_release = FALSE; break;
			case FOR_RELEASE_ONLY_HQ: h->for_release = TRUE; break;
			case UNINDEXED_HQ: h->index_definitions_made_under_this = FALSE; break;
			case USE_WITH_HQ: h->use_with_or_without = TRUE; break;
			case USE_WITHOUT_HQ: h->use_with_or_without = FALSE; break;
			case IN_PLACE_OF_HQ:
				h->use_with_or_without = TRUE;
				h->in_place_of_text = GET_RW(<extension-qualifier>, 1);
				CoreMain::disable_importation();
				break;
		}
		W = GET_RW(<heading-qualifier>, 1);
	}
	h->heading_text = W;

@ When a heading has been found, we repeatedly try to match it against
<heading-qualifier> to see if it ends with text telling us what to do with
the source text it governs. For example,

>> Section 21 - Frogs (unindexed) (not for Glulx)

would match twice, first registering the VM requirement, then the unindexedness.

It's an unfortunate historical quirk that the unbracketed qualifiers are
allowed; they should probably be withdrawn.

=
<heading-qualifier> ::=
	... ( <bracketed-heading-qualifier> ) |	==>	R[1]
	... not for release |					==>	NOT_FOR_RELEASE_HQ
	... for release only |					==>	FOR_RELEASE_ONLY_HQ
	... unindexed							==>	UNINDEXED_HQ

<bracketed-heading-qualifier> ::=
	not for release |						==>	NOT_FOR_RELEASE_HQ
	for release only |						==>	FOR_RELEASE_ONLY_HQ
	unindexed |								==>	UNINDEXED_HQ
	<platform-qualifier> |					==>	R[1]
	<extension-qualifier>					==> R[1]

<platform-qualifier> ::=
	for <platform-identifier> only |		==>	(R[1])?PLATFORM_MET_HQ:PLATFORM_UNMET_HQ
	not for <platform-identifier>			==>	(R[1])?PLATFORM_UNMET_HQ:PLATFORM_MET_HQ

<platform-identifier> ::=
	<language-element> language element |	==> R[1]
	...... language element |				==>	@<Issue PM_UnknownLanguageElement problem@>
	<virtual-machine> |						==> R[1]
	......									==> @<Issue PM_UnknownVirtualMachine problem@>

<extension-qualifier> ::=
	for use with <extension-identifier> |					==> USE_WITH_HQ
	for use without <extension-identifier> |				==> USE_WITHOUT_HQ
	not for use with <extension-identifier> |				==> USE_WITHOUT_HQ
	in place of (<quoted-text>) in <extension-identifier> |	==> IN_PLACE_OF_HQ
	in place of ...... in <extension-identifier>			==> IN_PLACE_OF_HQ

<extension-identifier> ::=
	...... by ......						==> @<Set for-use-with extension identifier@>

@<Issue PM_UnknownLanguageElement problem@> =
	Problems::Issue::sentence_problem(_p_(PM_UnknownLanguageElement),
		"this heading contains a stipulation about the current "
		"Inform language definition which I can't understand",
		"and should be something like '(for Glulx external files "
		"language element only)'.");

@<Issue PM_UnknownVirtualMachine problem@> =
	Problems::Issue::sentence_problem(_p_(PM_UnknownVirtualMachine),
		"this heading contains a stipulation about the Setting "
		"for story file format which I can't understand",
		"and should be something like '(for Z-machine version 5 "
		"or 8 only)' or '(for Glulx only)'.");

@<Set for-use-with extension identifier@> =
	*X = R[0] + 4;
	TEMPORARY_TEXT(exft);
	TEMPORARY_TEXT(exfa);
	wording TW = GET_RW(<extension-identifier>, 1);
	wording AW = GET_RW(<extension-identifier>, 2);
	WRITE_TO(exft, "%+W", TW);
	WRITE_TO(exfa, "%+W", AW);
	Extensions::IDs::new(grammar_eid, exfa, exft, USEWITH_EIDBC);
	DISCARD_TEXT(exft);
	DISCARD_TEXT(exfa);

@h The heading tree.
The headings were constructed above as freestanding nodes (except that the
pseudo-heading already existed): here, we assemble them into a tree
structure. Because we want to be able to call this more than once, perhaps
to make revisions if late news comes in of a new heading (see above), we
begin by removing any existing relationships between the heading nodes.

=
void Sentences::Headings::make_tree(void) {
	heading *h;
	@<Reduce the whole heading tree to a pile of twigs@>;

	LOOP_OVER(h, heading) {
		@<If h is outside the tree, make it a child of the pseudo-heading@>;
		@<Run through subsequent equal or subordinate headings to move them downward@>;
	}

	heading_tree_made_at_least_once = TRUE;
	Sentences::Headings::verify_heading_tree();
}

@ Note that the loop over headings below loops through all those which were
created by the memory manager: which is to say, all of them except for the
pseudo-heading, which was explicitly placed in static memory above.

@<Reduce the whole heading tree to a pile of twigs@> =
	heading *h;
	pseudo_heading.child_heading = NULL; pseudo_heading.parent_heading = NULL;
	pseudo_heading.next_heading = NULL;
	LOOP_OVER(h, heading) {
		h->parent_heading = NULL; h->child_heading = NULL; h->next_heading = NULL;
	}

@ The idea of the heading loop is that when we place a heading, we also place
subsequent headings of lesser or equal status until we cannot do so any longer.
That means that if we reach h and find that it has no parent, it must be
subordinate to no earlier heading: thus, it must be attached to the pseudo-heading
at the top of the tree.

@<If h is outside the tree, make it a child of the pseudo-heading@> =
	if (h->parent_heading == NULL)
		Sentences::Headings::make_child_heading(h, &pseudo_heading);

@ Note that the following could be summed up as "move subsequent headings as
deep in the tree as we can see they need to be from h's perspective alone".
This isn't always the final position. For instance, given the sequence
Volume 1, Chapter I, Section A, Chapter II, the tree is adjusted twice:

	|when h = Volume 1:        then when h = Chapter I:|
	|Volume 1                  Volume 1|
	|    Chapter I                 Chapter I|
	|    Section A                     Section A|
	|    Chapter II                Chapter II|

since Section A is demoted twice, once by Volume 1, then by Chapter I.
(This algorithm would in principle be quadratic in the number of headings if
the possible depth of the tree were unbounded -- every heading might have to
demote every one of its successors -- but in fact because the depth is at
most 9, it runs in linear time.)

@<Run through subsequent equal or subordinate headings to move them downward@> =
	heading *subseq;
	for (subseq = NEXT_OBJECT(h, heading); /* start from the next heading in source */
		(subseq) && (subseq->level >= h->level); /* for a run with level below or equal h */
		subseq = NEXT_OBJECT(subseq, heading)) { /* in source declaration order */
		if (subseq->level == h->level) { /* a heading of equal status ends the run... */
			Sentences::Headings::make_child_heading(subseq, h->parent_heading); break; /* ...and becomes h's sibling */
		}
		Sentences::Headings::make_child_heading(subseq, h); /* all lesser headings in the run become h's children */
	}

@ The above routine, then, calls |Sentences::Headings::make_child_heading| to attach a heading
to the tree as a child of a given parent:

=
void Sentences::Headings::make_child_heading(heading *ch, heading *pa) {
	heading *former_pa = ch->parent_heading;
	if (former_pa == pa) return;
	@<Detach ch from the heading tree if it is already there@>;
	ch->parent_heading = pa;
	@<Add ch to the end of the list of children of pa@>;
}

@ If ch is present in the tree, it must have a parent, unless it is the
pseudo-heading: but the latter can never be moved, so it isn't. Therefore
we can remove ch by striking it out from the children list of the parent.
(Any children which ch has, grandchildren so to speak, come with it.)

@<Detach ch from the heading tree if it is already there@> =
	if (former_pa) {
		if (former_pa->child_heading == ch)
			former_pa->child_heading = ch->next_heading;
		else {
			heading *sibling;
			for (sibling = former_pa->child_heading; sibling; sibling = sibling->next_heading)
				if (sibling->next_heading == ch) {
					sibling->next_heading = ch->next_heading;
					break;
				}
		}
	}
	ch->next_heading = NULL;

@ Two cases: the new parent is initially childless, or it isn't.

@<Add ch to the end of the list of children of pa@> =
	heading *sibling;
	if (pa->child_heading == NULL) pa->child_heading = ch;
	else
		for (sibling = pa->child_heading; sibling; sibling = sibling->next_heading)
			if (sibling->next_heading == NULL) {
				sibling->next_heading = ch;
				break;
			}

@h Verifying the heading tree.
We have now, in effect, computed the indentation value of each heading twice,
by two entirely different methods: first by the mathematical argument above,
then by observing that it is the depth in the heading tree. Seeing if
these two methods have given the same answer provides a convenient check on
our working.

=
int heading_tree_damaged = FALSE;
void Sentences::Headings::verify_heading_tree(void) {
	Sentences::Headings::verify_heading_tree_recursively(&pseudo_heading, -1);
	if (heading_tree_damaged) internal_error("heading tree failed to verify");
}

void Sentences::Headings::verify_heading_tree_recursively(heading *h, int depth) {
	if (h == NULL) return;
	if ((h != &pseudo_heading) && (depth != h->indentation)) {
		heading_tree_damaged = TRUE;
		LOG("$H\n*** indentation should be %d ***\n", h, depth);
	}
	Sentences::Headings::verify_heading_tree_recursively(h->child_heading, depth+1);
	Sentences::Headings::verify_heading_tree_recursively(h->next_heading, depth);
}

@h Miscellaneous heading services.
The first of these we have already seen in use: the sentence-breaker calls
it to ask whether sentences falling under the current heading should be
included in the active source text. (For instance, sentences under a
heading with the disclaimer "(for Glulx only)" will not be included
if the target virtual machine on this run of NI is the Z-machine.)

=
int Sentences::Headings::include_material(heading *h) {
	if ((h->for_release == TRUE) && (this_is_a_release_compile == FALSE)) return FALSE;
	if ((h->for_release == FALSE) && (this_is_a_release_compile == TRUE)) return FALSE;
	if (h->omit_material) return FALSE;
	return TRUE;
}

int Sentences::Headings::indexed(heading *h) {
	if (h == NULL) return TRUE; /* definitions made nowhere are normally indexed */
	return h->index_definitions_made_under_this;
}

@ A utility to do with the file of origin:

=
extension_file *Sentences::Headings::get_extension_containing(heading *h) {
	if ((h == NULL) || (h->start_location.file_of_origin == NULL)) return NULL;
	return SourceFiles::get_extension_corresponding(h->start_location.file_of_origin);
}

@ Although File (0) headings do have text, contrary to the implication of
the routine here, this text is only what happens to be first in the file:
it isn't a heading actually typed by the user, which is all that we are
interested in for this purpose. So we send back a null word range.

=
wording Sentences::Headings::get_text(heading *h) {
	if ((h == NULL) || (h->level == 0)) return EMPTY_WORDING;
	return h->heading_text;
}

@ This routine determines the (closest) heading to which a scrap of text
belongs, and is important since the parsing of noun phrases is affected by
that choice of heading (as we shall see): to NI, headings provide something
analogous to the scope of local variables in a conventional programming
language.

Because every file has a File (0) heading registered at line 1, the loop
in the following routine is guaranteed to return a valid heading provided
the original source location is well formed (i.e., has a non-null source
file and a line number of at least 1).

=
heading *Sentences::Headings::heading_of(source_location sl) {
	heading *h;
	if (sl.file_of_origin == NULL) return NULL;
	LOOP_BACKWARDS_OVER(h, heading)
		if ((sl.file_of_origin == h->start_location.file_of_origin) &&
			(sl.line_number >= h->start_location.line_number)) return h;
	internal_error("unable to determine the heading level of source material");
	return NULL;
}

heading *Sentences::Headings::of_wording(wording W) {
	return Sentences::Headings::heading_of(Wordings::location(W));
}

@h Headings with extension dependencies.
If the content under a heading depended on the VM not in use, or was marked
not for release in a release run, we were able to exclude it just by
skipping. The same cannot be done when a heading says that it should be
used only if a given extension is, or is not, being used, because when
the heading is created we don't yet know which extensions are included.
But when the following is called, we do know that.

=
void Sentences::Headings::satisfy_dependencies(void) {
	heading *h;
	LOOP_OVER(h, heading)
		if (h->use_with_or_without != NOT_APPLICABLE)
			Sentences::Headings::satisfy_individual_heading_dependency(h);
}

@ And now the code to check an individual heading's usage. This whole
thing is carefully timed so that we can still afford to cut up and rearrange
the parse tree on quite a large scale, and that's just what we do.

=
void Sentences::Headings::satisfy_individual_heading_dependency(heading *h) {
	if (h->level < 1) return;
	extension_identifier *eid = &(h->for_use_with);
	int loaded = FALSE;
	if (Extensions::IDs::no_times_used_in_context(eid, LOADED_EIDBC) != 0) loaded = TRUE;
	LOGIF(HEADINGS, "SIHD on $H: loaded %d: annotation %d: %W: %d\n", h, loaded,
		ParseTree::int_annotation(h->sentence_declaring,
			suppress_heading_dependencies_ANNOT),
		h->in_place_of_text, h->use_with_or_without);
	if (Wordings::nonempty(h->in_place_of_text)) {
		wording S = h->in_place_of_text;
		if (ParseTree::int_annotation(h->sentence_declaring,
			suppress_heading_dependencies_ANNOT) == FALSE) {
			if (<quoted-text>(h->in_place_of_text)) {
				Word::dequote(Wordings::first_wn(S));
				wchar_t *text = Lexer::word_text(Wordings::first_wn(S));
				S = Feeds::feed_text(text);
			}
			heading *h2; int found = FALSE;
			if (loaded == FALSE) @<Can't replace heading in an unincluded extension@>
			else {
				LOOP_OVER(h2, heading)
					if ((Wordings::nonempty(h2->heading_text)) &&
						(Wordings::match_perhaps_quoted(S, h2->heading_text)) &&
						(Extensions::IDs::match(
							Extensions::Files::get_eid(
								Sentences::Headings::get_extension_containing(h2)), eid))) {
						found = TRUE;
						if (h->level != h2->level)
							@<Can't replace heading unless level matches@>;
						Sentences::Headings::excise_material_under(h2, NULL);
						Sentences::Headings::excise_material_under(h, h2->sentence_declaring);
						break;
					}
				if (found == FALSE) @<Can't find heading in the given extension@>;
			}
		}
	} else
		if (h->use_with_or_without != loaded) Sentences::Headings::excise_material_under(h, NULL);
}

@<Can't replace heading in an unincluded extension@> =
	current_sentence = h->sentence_declaring;
	Problems::quote_source(1, current_sentence);
	Problems::quote_extension_id(2, &(h->for_use_with));
	Problems::Issue::handmade_problem(_p_(PM_HeadingInPlaceOfUnincluded));
	Problems::issue_problem_segment(
		"In the sentence %1, it looks as if you intend to replace a section "
		"of source text from the extension '%2', but no extension of that "
		"name has been included - so it is not possible to replace any of its "
		"headings.");
	Problems::issue_problem_end();

@ To excise, we simply prune the heading's contents from the parse tree,
though optionally grafting them to another node rather than discarding them
altogether.

Any heading which is excised is marked so that it won't have its own
dependencies checked. This clarifies several cases, and in particular ensures
that if Chapter X is excised then a subordinate Section Y cannot live on by
replacing something elsewhere (which would effectively delete the content
elsewhere).

=
void Sentences::Headings::excise_material_under(heading *h, parse_node *transfer_to) {
	LOGIF(HEADINGS, "Excision under $H\n", h);
	parse_node *hpn = h->sentence_declaring;
	if (h->sentence_declaring == NULL) internal_error("stipulations on a non-sentence heading");

	if (Wordings::nonempty(h->in_place_of_text)) {
		heading *h2 = Sentences::Headings::find_dependent_heading(hpn->down);
		if (h2) @<Can't replace heading subordinate to another replaced heading@>;
	}

	Sentences::Headings::suppress_dependencies(hpn);
	if (transfer_to) ParseTree::graft(hpn->down, transfer_to);
	hpn->down = NULL;
}

heading *Sentences::Headings::find_dependent_heading(parse_node *pn) {
	if (ParseTree::get_type(pn) == HEADING_NT) {
		heading *h = ParseTree::get_embodying_heading(pn);
		if ((h) && (Wordings::nonempty(h->in_place_of_text))) return h;
	}
	for (parse_node *p = pn->down; p; p = p->next) {
		heading *h = ParseTree::get_embodying_heading(p);
		if (h) return h;
	}
	return NULL;
}

void Sentences::Headings::suppress_dependencies(parse_node *pn) {
	if (ParseTree::get_type(pn) == HEADING_NT)
		ParseTree::annotate_int(pn, suppress_heading_dependencies_ANNOT, TRUE);
	for (parse_node *p = pn->down; p; p = p->next)
		Sentences::Headings::suppress_dependencies(p);
}

@<Can't replace heading subordinate to another replaced heading@> =
	current_sentence = h2->sentence_declaring;
	Problems::quote_source(1, current_sentence);
	Problems::quote_extension_id(2, &(h2->for_use_with));
	Problems::quote_source(3, h->sentence_declaring);
	Problems::quote_extension_id(4, &(h->for_use_with));
	Problems::Issue::handmade_problem(_p_(PM_HeadingInPlaceOfSubordinate));
	Problems::issue_problem_segment(
		"In the sentence %1, it looks as if you intend to replace a section "
		"of source text from the extension '%2', but that doesn't really make "
		"sense because this new piece of source text is part of a superior "
		"heading ('%3') which is already being replaced spliced into '%4'.");
	Problems::issue_problem_end();

@<Can't find heading in the given extension@> =
	current_sentence = h->sentence_declaring;
	Problems::quote_source(1, current_sentence);
	Problems::quote_extension_id(2, &(h->for_use_with));
	Problems::quote_wording(3, h->in_place_of_text);
	Problems::quote_text(4,
		"unspecified, that is, the extension didn't have a version number");
	extension_file *ef;
	LOOP_OVER(ef, extension_file)
		if (Extensions::IDs::match(&(h->for_use_with), Extensions::Files::get_eid(ef)))
			Problems::quote_wording(4,
				Wordings::one_word(Extensions::Files::get_version_wn(ef)));
	Problems::Issue::handmade_problem(_p_(PM_HeadingInPlaceOfUnknown));
	Problems::issue_problem_segment(
		"In the sentence %1, it looks as if you intend to replace a section "
		"of source text from the extension '%2', but that extension does "
		"not seem to have any heading called '%3'. (The version I loaded "
		"was %4.)");
	Problems::issue_problem_end();

@<Can't replace heading unless level matches@> =
	current_sentence = h->sentence_declaring;
	Problems::Issue::sentence_problem(_p_(PM_UnequalHeadingInPlaceOf),
		"these headings are not of the same level",
		"so it is not possible to make the replacement. (Level here means "
		"being a Volume, Book, Part, Chapter or Section: for instance, "
		"only a Chapter heading can be used 'in place of' a Chapter.)");

@h World objects under each heading.
Every heading must carry with it a linked list of the nametags created in
sentences which belong to it. So when any noun is created, the following
is called to let the current sentence's heading know that it has a new
friend.

@d LOOP_OVER_NOUNS_UNDER(nt, h)
	for (nt=h->list_of_contents; nt; nt=Sentences::Headings::name_resolution_data(nt)->next_under_heading)

=
name_resolution_data *Sentences::Headings::name_resolution_data(noun *t) {
	if (t == NULL) internal_error("tried to fetch resolution data for null tag");
	return &(t->name_resolution);
}

int no_tags_attached = 0;
void Sentences::Headings::attach_noun(noun *new_tag) {
	if (current_sentence == NULL) return;
	heading *h = Sentences::Headings::of_wording(ParseTree::get_text(current_sentence));
	if (h == NULL) return;
	no_tags_attached++;
	name_resolution_data *nrd = Sentences::Headings::name_resolution_data(new_tag);
	nrd->next_to_search = NULL;
	if (h->last_in_list_of_contents == NULL) h->list_of_contents = new_tag;
	else Sentences::Headings::name_resolution_data(h->last_in_list_of_contents)->next_under_heading = new_tag;
	nrd->next_under_heading = NULL;
	h->last_in_list_of_contents = new_tag;
}

@ The following verification checks that every noun is listed
in the list for exactly one heading. The point of the check is not so much
to make sure the tag lists are properly formed, as the code making those
is pretty elementary: it's really a test that the source text is well-formed
with everything placed under a heading, and no sentence having fallen
through a crack.

=
void Sentences::Headings::verify_divisions(void) {
	noun *nt; heading *h;
	int total = 0, disaster = FALSE;
	LOOP_OVER(nt, noun)
		Sentences::Headings::name_resolution_data(nt)->heading_count = 0;
	LOOP_OVER(h, heading)
		LOOP_OVER_NOUNS_UNDER(nt, h)
			Sentences::Headings::name_resolution_data(nt)->heading_count++, total++;
	LOOP_OVER(nt, noun)
		if (Sentences::Headings::name_resolution_data(nt)->heading_count > 1) {
			LOG("$z occurs under %d headings\n",
				nt, Sentences::Headings::name_resolution_data(nt)->heading_count);
			disaster = TRUE;
		}
	if (total != no_tags_attached) {
		LOG("%d tags != %d attached\n",
			total, no_tags_attached);
		disaster = TRUE;
	}
	if (disaster) internal_error_tree_unsafe("heading contents list failed verification");
}

@h The noun search list.
Identifying noun phrases is tricky. Many plausible phrases could refer in
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

	|File|
	|    main()|
	|    routine1()|
	|        interior block of a loop|
	|        ...|
	|    routine2()|
	|    ...|

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
	for (nt = nt_search_start; nt; nt = Sentences::Headings::name_resolution_data(nt)->next_to_search)

=
noun *nt_search_start = NULL, *nt_search_finish = NULL;

@ The search sequence is, in effect, a cache storing a former computation,
and like all caches it can fall out of date if the circumstances change so
that the same computation would now produce a different outcome. That can
only happen here if a new noun is to be created: the assertion-maker
calls the following routine to let us know.

=
heading *noun_search_list_valid_for_this_heading = NULL; /* initially it's unbuilt */

void Sentences::Headings::disturb(void) {
	noun_search_list_valid_for_this_heading = NULL;
}

@ Leaving aside the cache, then, we build a list as initially empty, then
all nametags of priority 1 as found by recursively searching headings, then all
nametags of priority 2, and so on.

=
void Sentences::Headings::construct_noun_search_list(void) {
	heading *h = NULL;

	@<Work out the heading from which we wish to search@>;

	if ((h == NULL) || (h == noun_search_list_valid_for_this_heading)) return; /* rely on the cache */

	LOGIF(HEADINGS, "Rebuilding noun search list from: $H\n", h);

	@<Start the search list empty@>;

	int i;
	for (i=1; i<=MAX_NOUN_PRIORITY; i++)
		Sentences::Headings::build_search_list_from(h, NULL, i);

	@<Verify that the search list indeed contains every noun just once@>;

	noun_search_list_valid_for_this_heading = h;
}

@ Basically, we calculate the search list from the point of view of the
current sentence:

@<Work out the heading from which we wish to search@> =
	if ((current_sentence == NULL) || (Wordings::empty(ParseTree::get_text(current_sentence))))
		internal_error("cannot establish position P: there is no current sentence");
	source_location position_P = Wordings::location(ParseTree::get_text(current_sentence));
	h = Sentences::Headings::heading_of(position_P);

@ The pseudo-heading has no list of contents because all objects are created in
source files, each certainly underneath a File (0) heading, so nothing should
ever get that far.

@<Start the search list empty@> =
	nt_search_start = NULL;
	nt_search_finish = NULL;
	pseudo_heading.list_of_contents = NULL; /* should always be true, but just in case */

@ The potential for disaster if this algorithm should be incorrect is high,
so we perform a quick count to see if everything made it onto the list
and produce an internal error if not.

@<Verify that the search list indeed contains every noun just once@> =
	int c = 0; noun *nt;
	LOOP_OVER_NT_SEARCH_LIST(nt) c++;
	if (c != no_tags_attached) {
		LOG("Reordering failed from $H\n", h);
		LOG("%d tags created, %d in ordering\n", no_tags_attached, c);
		Sentences::Headings::log_all_headings();
		LOG("Making fresh tree:\n");
		Sentences::Headings::make_tree();
		Sentences::Headings::log_all_headings();
		internal_error_tree_unsafe("reordering of nametags failed");
	}

@ The following adds all nametags under heading H to the search list, using
its own list of contents, and then recurses to add all objects under
subheadings of H other than the one which has just recursed up to H. With
that done, we recurse up to the superheading of H.

To prove that |Sentences::Headings::build_search_list_from| is called exactly once for each
heading in the tree, forget about the up/down orientation and consider it
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
number of nametags in the source text.

=
void Sentences::Headings::build_search_list_from(heading *within, heading *way_we_came, int p) {
	noun *nt; heading *subhead;

	if (within == NULL) return;

	LOOP_OVER_NOUNS_UNDER(nt, within)
		if (Nouns::priority(nt) == p)
			@<Add tag to the end of the search list@>;

	/* recurse downwards through subordinate headings, other than the way we came up */
	for (subhead = within->child_heading; subhead; subhead = subhead->next_heading)
		if (subhead != way_we_came)
			Sentences::Headings::build_search_list_from(subhead, within, p);

	/* recurse upwards to superior headings, unless we came here through a downward recursion */
	if (within->parent_heading != way_we_came)
		Sentences::Headings::build_search_list_from(within->parent_heading, within, p);
}

@<Add tag to the end of the search list@> =
	if (nt_search_finish == NULL) {
		nt_search_start = nt;
	} else {
		if (Sentences::Headings::name_resolution_data(nt_search_finish)->next_to_search != NULL)
			internal_error("end of tag search list has frayed somehow");
		Sentences::Headings::name_resolution_data(nt_search_finish)->next_to_search = nt;
	}
	Sentences::Headings::name_resolution_data(nt)->next_to_search = NULL;
	nt_search_finish = nt;

@ The search list is used for finding best matches in a particular order, the
order being used to break tie-breaks. Note that we return |NULL| if no noun
in the search list has a positive score.

=
void Sentences::Headings::set_noun_search_score(noun *nt, int v) {
	Sentences::Headings::name_resolution_data(nt)->search_score = v;
}

noun *Sentences::Headings::highest_scoring_noun_searched(void) {
	noun *nt, *best_nt = NULL;
	int best_score = 0;
	LOOP_OVER_NT_SEARCH_LIST(nt) {
		int x = Sentences::Headings::name_resolution_data(nt)->search_score;
		if (x > best_score) { best_nt = nt; best_score = x; }
	}
	return best_nt;
}

@h Handling headings during the main traverses.
Here's what we do when we run into a heading, as we look through the
assertions in the source text: nothing, except to wipe out any meanings of
words like "it" left over from previous sentences. Headings are for
organisation, and are not directly functional in themselves.

=
sentence_handler HEADING_SH_handler =
	{ HEADING_NT, -1, 0, Sentences::Headings::handle_heading };

void Sentences::Headings::handle_heading(parse_node *PN) {
	Assertions::Traverse::new_discussion();
}

@h Describing the heading structure, 1: to the debugging log.
Finally, three ways to describe the run of headings: to the debugging log,
to the index of the project, and to a freestanding XML file.

=
void Sentences::Headings::log(heading *h) {
	if (h==NULL) { LOG("<null heading>\n"); return; }
	if (h==&pseudo_heading) { LOG("<pseudo_heading>\n"); return; }
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
void Sentences::Headings::log_all_headings(void) {
	heading *h;
	LOOP_OVER(h, heading) LOG("$H\n", h);
	LOG("\n");
	Sentences::Headings::log_headings_recursively(&pseudo_heading, 0);
}

void Sentences::Headings::log_headings_recursively(heading *h, int depth) {
	int i;
	if (h==NULL) return;
	for (i=0; i<depth; i++) LOG("  ");
	LOG("$H\n", h);
	if (depth-1 != h->indentation) LOG("*** indentation should be %d ***\n", depth-1);
	Sentences::Headings::log_headings_recursively(h->child_heading, depth+1);
	Sentences::Headings::log_headings_recursively(h->next_heading, depth);
}

@h Describing the heading structure, 2: to the index.

=
int headings_indexed = 0;
void Sentences::Headings::index(OUTPUT_STREAM) {
	#ifdef IF_MODULE
	HTML_OPEN("p");
	WRITE("<b>"); PL::Bibliographic::contents_heading(OUT); WRITE("</b>");
	HTML_CLOSE("p");
	#endif
	HTML_OPEN("p");
	WRITE("CONTENTS");
	HTML_CLOSE("p");
	Sentences::Headings::index_heading_recursively(OUT, pseudo_heading.child_heading);
	contents_entry *ce;
	int min_positive_level = 10;
	LOOP_OVER(ce, contents_entry)
		if ((ce->heading_entered->level > 0) &&
			(ce->heading_entered->level < min_positive_level))
			min_positive_level = ce->heading_entered->level;
	LOOP_OVER(ce, contents_entry)
		@<Index this entry in the contents@>;

	if (NUMBER_CREATED(contents_entry) == 1) {
		HTML_OPEN("p"); WRITE("(This would look more like a contents page if the source text "
			"were divided up into headings.");
		Index::DocReferences::link(OUT, I"HEADINGS");
		WRITE(")");
		HTML_CLOSE("p");
		WRITE("\n");
	}
}

@<Index this entry in the contents@> =
	heading *h = ce->heading_entered;
	/* indent to correct tab position */
	HTML_OPEN_WITH("ul", "class=\"leaders\""); WRITE("\n");
	int ind_used = h->indentation;
	if (h->level == 0) ind_used = 1;
	HTML_OPEN_WITH("li", "class=\"leaded indent%d\"", ind_used);
	HTML_OPEN("span");
	if (h->level == 0) {
		if (NUMBER_CREATED(contents_entry) == 1)
			WRITE("Source text");
		else
			WRITE("Preamble");
	} else {
		/* write the text of the heading title */
		WRITE("%+W", ParseTree::get_text(h->sentence_declaring));
	}
	HTML_CLOSE("span");
	HTML_OPEN("span");
	contents_entry *next_ce = NEXT_OBJECT(ce, contents_entry);
	if (h->level != 0)
		while ((next_ce) && (next_ce->heading_entered->level > ce->heading_entered->level))
			next_ce = NEXT_OBJECT(next_ce, contents_entry);
	int start_word = Wordings::first_wn(ParseTree::get_text(ce->heading_entered->sentence_declaring));
	int end_word = (next_ce)?(Wordings::first_wn(ParseTree::get_text(next_ce->heading_entered->sentence_declaring)))
		: (TextFromFiles::last_lexed_word(FIRST_OBJECT(source_file)));

	int N = 0;
	for (int i = start_word; i < end_word; i++)
		N += TextFromFiles::word_count(i);
	if (h->level > min_positive_level) HTML::begin_colour(OUT, I"808080");
	WRITE("%d words", N);
	if (h->level > min_positive_level) HTML::end_colour(OUT);
	/* place a link to the relevant line of the primary source text */
	Index::link_location(OUT, h->start_location);
	HTML_CLOSE("span");
	HTML_CLOSE("li");
	HTML_CLOSE("ul");
	WRITE("\n");
	@<List all the objects and kinds created under the given heading, one tap stop deeper@>;

@ We index only headings of level 1 and up -- so, not the pseudo-heading or the
File (0) ones -- and which are not within any extensions -- so, are in the
primary source text written by the user.

=
void Sentences::Headings::index_heading_recursively(OUTPUT_STREAM, heading *h) {
	if (h == NULL) return;
	int show_heading = TRUE;
	heading *next = h->child_heading;
	if (next == NULL) next = h->next_heading;
	if ((next) &&
		(SourceFiles::get_extension_corresponding(next->start_location.file_of_origin)))
		next = NULL;
	if (h->level == 0) {
		show_heading = FALSE;
		if ((headings_indexed == 0) &&
			((next == NULL) ||
				(Wordings::first_wn(ParseTree::get_text(next->sentence_declaring)) !=
					Wordings::first_wn(ParseTree::get_text(h->sentence_declaring)))))
			show_heading = TRUE;
	}
	if (SourceFiles::get_extension_corresponding(h->start_location.file_of_origin))
		show_heading = FALSE;
	if (show_heading) {
		contents_entry *ce = CREATE(contents_entry);
		ce->heading_entered = h;
		headings_indexed++;
	}

	Sentences::Headings::index_heading_recursively(OUT, h->child_heading);
	Sentences::Headings::index_heading_recursively(OUT, h->next_heading);
}

@ We skip any objects or kinds without names (i.e., whose |creator| is null).
The rest appear in italic type, and without links to source text since this
in practice strews distractingly many orange berries across the page.

@<List all the objects and kinds created under the given heading, one tap stop deeper@> =
	noun *nt;
	int c = 0;
	LOOP_OVER_NOUNS_UNDER(nt, h) {
		wording W = Nouns::get_name(nt, FALSE);
		if (Wordings::nonempty(W)) {
			if (c++ == 0) {
				HTMLFiles::open_para(OUT, ind_used+1, "hanging");
				HTML::begin_colour(OUT, I"808080");
			} else WRITE(", ");
			WRITE("<i>%+W</i>", W);
		}
	}
	if (c > 0) { HTML::end_colour(OUT); HTML_CLOSE("p"); }

@h Describing the heading structure, 3: to a freestanding XML file.
This is provided as a convenience to the application using NI, which may want
to have a pull-down menu or similar gadget allowing the user to jump to a given
heading. This tells the interface where every heading is, thus saving it from
having to parse the source.

The property list contains a single dictionary, whose keys are the numbers
0, 1, 2, ..., $n-1$, where there are $n$ headings in all. (The pseudo-heading
is not included.) A special key, the only non-numerical one, called "Application
Version", contains the NI build number in its usual form: "4Q34", for instance.

=
void Sentences::Headings::write_as_xml(void) {
	text_stream xf_struct; text_stream *xf = &xf_struct;
	if (STREAM_OPEN_TO_FILE(xf, filename_of_headings, UTF8_ENC) == FALSE)
		Problems::Fatal::filename_related("Can't open headings file", filename_of_headings);
	Sentences::Headings::write_headings_as_xml_inner(xf);
	STREAM_CLOSE(xf);
}

void Sentences::Headings::write_headings_as_xml_inner(OUTPUT_STREAM) {
	heading *h;
	@<Write DTD indication for XML headings file@>;
	WRITE("<plist version=\"1.0\"><dict>\n");
	INDENT;
	WRITE("<key>Application Version</key><string>%B (build %B)</string>\n", FALSE, TRUE);
	LOOP_OVER(h, heading) {
		WRITE("<key>%d</key><dict>\n", h->allocation_id);
		INDENT;
		@<Write the dictionary of properties for a single heading@>;
		OUTDENT;
		WRITE("</dict>\n");
	}
	OUTDENT;
	WRITE("</dict></plist>\n");
}

@ We use a convenient Apple DTD:

@<Write DTD indication for XML headings file@> =
	WRITE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		"<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" "
		"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");

@ Note that a level of 0, and a title of |--|, signifies a File (0) level
heading: external tools can probably ignore such records. Similarly, it is
unlikely that they will ever see a record without a "Filename" key --
this would mean a heading arising from text created internally within NI,
which will only happen if someone has done something funny with |.i6t| files --
but should this arise then the best recourse is to ignore the heading.

@<Write the dictionary of properties for a single heading@> =
	if (h->start_location.file_of_origin)
		WRITE("<key>Filename</key><string>%f</string>\n",
			TextFromFiles::get_filename(h->start_location.file_of_origin));
	WRITE("<key>Line</key><integer>%d</integer>\n", h->start_location.line_number);
	if (Wordings::nonempty(h->heading_text))
		WRITE("<key>Title</key><string>%+W</string>\n", h->heading_text);
	else
		WRITE("<key>Title</key><string>--</string>\n");
	WRITE("<key>Level</key><integer>%d</integer>\n", h->level);
	WRITE("<key>Indentation</key><integer>%d</integer>\n", h->indentation);
