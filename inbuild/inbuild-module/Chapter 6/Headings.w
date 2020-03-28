[Headings::] Headings.

To keep track of the hierarchy of headings and subheadings found
in the source text.

@ Headings in the source text correspond to |HEADING_NT| nodes in syntax
trees, and mostly occur when the user has explicitly typed a heading such as:

>> Part VII - The Ghost of the Aragon

The sentence-breaker called |Headings::declare| each time it found one of
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
of Inform declares at least two File (0) headings, representing the start of
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
	struct inbuild_work *for_use_with; /* e.g. "for use with ... by ..." */
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
for Inform to decide on behalf of the author that it is eccentric to place
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

@ Now, then, the routine |Headings::declare| is called by the sentence-breaker
each time it constructs a new HEADING node. (Note that it is not called to
create the pseudo-heading, which does not come from a node.)

A level 0 heading has text (the first sentence which happens to be in the
new source file), but this has no significance other than its location,
and cannot contain information about releasing or about virtual machines.

=
int last_indentation_above_level[NO_HEADING_LEVELS], lial_made = FALSE;
inbuild_work *work_identified = NULL;

@ =
DECLARE_ANNOTATION_FUNCTIONS(embodying_heading, heading)
MAKE_ANNOTATION_FUNCTIONS(embodying_heading, heading)
DECLARE_ANNOTATION_FUNCTIONS(inclusion_of_extension, inform_extension)
MAKE_ANNOTATION_FUNCTIONS(inclusion_of_extension, inform_extension)

heading *Headings::from_node(parse_node *PN) {
	return ParseTree::get_embodying_heading(PN);
}

@

@d NEW_HEADING_HANDLER Headings::new_heading

=
int Headings::new_heading(parse_node_tree *T, parse_node *new) {
	heading *h = Headings::declare(T, new);
	#ifdef CORE_MODULE
	ParseTree::set_embodying_heading(new, h);
	#endif
	return Headings::include_material(h);
}

heading *Headings::declare(parse_node_tree *T, parse_node *PN) {
	heading *h = CREATE(heading);

	h->parent_heading = NULL; h->child_heading = NULL; h->next_heading = NULL;
	h->list_of_contents = NULL; h->last_in_list_of_contents = NULL;
	h->for_release = NOT_APPLICABLE; h->omit_material = FALSE;
	h->index_definitions_made_under_this = TRUE;
	h->use_with_or_without = NOT_APPLICABLE;
	h->in_place_of_text = EMPTY_WORDING;
	h->for_use_with = NULL;

	if ((PN == NULL) || (Wordings::empty(ParseTree::get_text(PN))))
		internal_error("heading at textless node");
	if (ParseTree::get_type(PN) != HEADING_NT) 
		internal_error("declared a non-HEADING node as heading");
	h->sentence_declaring = PN;
	h->start_location = Wordings::location(ParseTree::get_text(PN));
	h->level = ParseTree::int_annotation(PN, heading_level_ANNOT);
	h->heading_text = EMPTY_WORDING;

	if (h->level > 0) @<Parse heading text for release or other stipulations@>;

	if ((h->level < 0) || (h->level >= NO_HEADING_LEVELS)) internal_error("impossible level");
	@<Determine the indentation from the level@>;

	LOGIF(HEADINGS, "Created heading $H\n", h);
	if (heading_tree_made_at_least_once) Headings::make_tree();
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
				break;
		}
		W = GET_RW(<heading-qualifier>, 1);
	}
	h->heading_text = W;
	h->for_use_with = work_identified;

@

@e UnknownLanguageElement_SYNERROR
@e UnknownVirtualMachine_SYNERROR

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
	<current-virtual-machine> |				==> R[1]
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
	#ifdef CORE_MODULE
	copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
	CE->error_subcategory = UnknownLanguageElement_SYNERROR;
	CE->details_node = current_sentence;
	Copies::attach(sfsm_copy, CE);
	#endif

@<Issue PM_UnknownVirtualMachine problem@> =
	copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
	CE->error_subcategory = UnknownVirtualMachine_SYNERROR;
	CE->details_node = current_sentence;
	Copies::attach(sfsm_copy, CE);

@<Set for-use-with extension identifier@> =
	*X = R[0] + 4;
	TEMPORARY_TEXT(exft);
	TEMPORARY_TEXT(exfa);
	wording TW = GET_RW(<extension-identifier>, 1);
	wording AW = GET_RW(<extension-identifier>, 2);
	WRITE_TO(exft, "%+W", TW);
	WRITE_TO(exfa, "%+W", AW);
	work_identified = Works::new(extension_genre, exft, exfa);
	Works::add_to_database(work_identified, USEWITH_WDBC);
	DISCARD_TEXT(exft);
	DISCARD_TEXT(exfa);

@ =
<current-virtual-machine> internal {
	if (<virtual-machine>(W)) {
		*X = Compatibility::with((compatibility_specification *) <<rp>>, Inbuild::current_vm());
		return TRUE;
	} else {
		*X = FALSE;
		return FALSE;
	}
}

@h The heading tree.
The headings were constructed above as freestanding nodes (except that the
pseudo-heading already existed): here, we assemble them into a tree
structure. Because we want to be able to call this more than once, perhaps
to make revisions if late news comes in of a new heading (see above), we
begin by removing any existing relationships between the heading nodes.

=
void Headings::make_tree(void) {
	heading *h;
	@<Reduce the whole heading tree to a pile of twigs@>;

	LOOP_OVER(h, heading) {
		@<If h is outside the tree, make it a child of the pseudo-heading@>;
		@<Run through subsequent equal or subordinate headings to move them downward@>;
	}

	heading_tree_made_at_least_once = TRUE;
	Headings::verify_heading_tree();
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
		Headings::make_child_heading(h, &pseudo_heading);

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
			Headings::make_child_heading(subseq, h->parent_heading); break; /* ...and becomes h's sibling */
		}
		Headings::make_child_heading(subseq, h); /* all lesser headings in the run become h's children */
	}

@ The above routine, then, calls |Headings::make_child_heading| to attach a heading
to the tree as a child of a given parent:

=
void Headings::make_child_heading(heading *ch, heading *pa) {
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
void Headings::verify_heading_tree(void) {
	Headings::verify_heading_tree_r(&pseudo_heading, -1);
	if (heading_tree_damaged) internal_error("heading tree failed to verify");
}

void Headings::verify_heading_tree_r(heading *h, int depth) {
	if (h == NULL) return;
	if ((h != &pseudo_heading) && (depth != h->indentation)) {
		heading_tree_damaged = TRUE;
		LOG("$H\n*** indentation should be %d ***\n", h, depth);
	}
	Headings::verify_heading_tree_r(h->child_heading, depth+1);
	Headings::verify_heading_tree_r(h->next_heading, depth);
}

@h Miscellaneous heading services.
The first of these we have already seen in use: the sentence-breaker calls
it to ask whether sentences falling under the current heading should be
included in the active source text. (For instance, sentences under a
heading with the disclaimer "(for Glulx only)" will not be included
if the target virtual machine on this run of Inform is the Z-machine.)

=
int Headings::include_material(heading *h) {
	int releasing = Inbuild::currently_releasing();
	if ((h->for_release == TRUE) && (releasing == FALSE)) return FALSE;
	if ((h->for_release == FALSE) && (releasing == TRUE)) return FALSE;
	if (h->omit_material) return FALSE;
	return TRUE;
}

int Headings::indexed(heading *h) {
	if (h == NULL) return TRUE; /* definitions made nowhere are normally indexed */
	return h->index_definitions_made_under_this;
}

@ A utility to do with the file of origin:

=
inform_extension *Headings::get_extension_containing(heading *h) {
	if ((h == NULL) || (h->start_location.file_of_origin == NULL)) return NULL;
	return Extensions::corresponding_to(h->start_location.file_of_origin);
}

@ Although File (0) headings do have text, contrary to the implication of
the routine here, this text is only what happens to be first in the file:
it isn't a heading actually typed by the user, which is all that we are
interested in for this purpose. So we send back a null word range.

=
wording Headings::get_text(heading *h) {
	if ((h == NULL) || (h->level == 0)) return EMPTY_WORDING;
	return h->heading_text;
}

@ This routine determines the (closest) heading to which a scrap of text
belongs, and is important since the parsing of noun phrases is affected by
that choice of heading (as we shall see): to Inform, headings provide something
analogous to the scope of local variables in a conventional programming
language.

Because every file has a File (0) heading registered at line 1, the loop
in the following routine is guaranteed to return a valid heading provided
the original source location is well formed (i.e., has a non-null source
file and a line number of at least 1).

=
heading *Headings::heading_of(source_location sl) {
	heading *h;
	if (sl.file_of_origin == NULL) return NULL;
	LOOP_BACKWARDS_OVER(h, heading)
		if ((sl.file_of_origin == h->start_location.file_of_origin) &&
			(sl.line_number >= h->start_location.line_number)) return h;
	internal_error("unable to determine the heading level of source material");
	return NULL;
}

heading *Headings::of_wording(wording W) {
	return Headings::heading_of(Wordings::location(W));
}

@h Headings with extension dependencies.
If the content under a heading depended on the VM not in use, or was marked
not for release in a release run, we were able to exclude it just by
skipping. The same cannot be done when a heading says that it should be
used only if a given extension is, or is not, being used, because when
the heading is created we don't yet know which extensions are included.
But when the following is called, we do know that.

@e HeadingInPlaceOfUnincluded_SYNERROR
@e UnequalHeadingInPlaceOf_SYNERROR
@e HeadingInPlaceOfSubordinate_SYNERROR
@e HeadingInPlaceOfUnknown_SYNERROR

=
void Headings::satisfy_dependencies(parse_node_tree *T, inbuild_copy *C) {
	heading *h;
	LOOP_OVER(h, heading)
		if (h->use_with_or_without != NOT_APPLICABLE)
			Headings::satisfy_individual_heading_dependency(T, C, h);
}

@ And now the code to check an individual heading's usage. This whole
thing is carefully timed so that we can still afford to cut up and rearrange
the parse tree on quite a large scale, and that's just what we do.

=
void Headings::satisfy_individual_heading_dependency(parse_node_tree *T, inbuild_copy *C, heading *h) {
	if (h->level < 1) return;
	inbuild_work *work = h->for_use_with;
	int loaded = FALSE;
	if (Works::no_times_used_in_context(work, LOADED_WDBC) != 0) loaded = TRUE;
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
						(Works::match(
							Headings::get_extension_containing(h2)->as_copy->edition->work, work))) {
						found = TRUE;
						if (h->level != h2->level)
							@<Can't replace heading unless level matches@>;
						Headings::excise_material_under(T, C, h2, NULL);
						Headings::excise_material_under(T, C, h, h2->sentence_declaring);
						break;
					}
				if (found == FALSE) @<Can't find heading in the given extension@>;
			}
		}
	} else
		if (h->use_with_or_without != loaded) Headings::excise_material_under(T, C, h, NULL);
}

@<Can't replace heading in an unincluded extension@> =
	copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
	CE->error_subcategory = HeadingInPlaceOfUnincluded_SYNERROR;
	CE->details_node = h->sentence_declaring;
	CE->details_work = h->for_use_with;
	Copies::attach(C, CE);

@ To excise, we simply prune the heading's contents from the parse tree,
though optionally grafting them to another node rather than discarding them
altogether.

Any heading which is excised is marked so that it won't have its own
dependencies checked. This clarifies several cases, and in particular ensures
that if Chapter X is excised then a subordinate Section Y cannot live on by
replacing something elsewhere (which would effectively delete the content
elsewhere).

=
void Headings::excise_material_under(parse_node_tree *T, inbuild_copy *C, heading *h, parse_node *transfer_to) {
	LOGIF(HEADINGS, "Excision under $H\n", h);
	parse_node *hpn = h->sentence_declaring;
	if (h->sentence_declaring == NULL) internal_error("stipulations on a non-sentence heading");

	if (Wordings::nonempty(h->in_place_of_text)) {
		heading *h2 = Headings::find_dependent_heading(hpn->down);
		if (h2) @<Can't replace heading subordinate to another replaced heading@>;
	}

	Headings::suppress_dependencies(hpn);
	if (transfer_to) ParseTree::graft(T, hpn->down, transfer_to);
	hpn->down = NULL;
}

heading *Headings::find_dependent_heading(parse_node *pn) {
	if (ParseTree::get_type(pn) == HEADING_NT) {
		heading *h = Headings::from_node(pn);
		if ((h) && (Wordings::nonempty(h->in_place_of_text))) return h;
	}
	for (parse_node *p = pn->down; p; p = p->next) {
		heading *h = Headings::from_node(p);
		if (h) return h;
	}
	return NULL;
}

void Headings::suppress_dependencies(parse_node *pn) {
	if (ParseTree::get_type(pn) == HEADING_NT)
		ParseTree::annotate_int(pn, suppress_heading_dependencies_ANNOT, TRUE);
	for (parse_node *p = pn->down; p; p = p->next)
		Headings::suppress_dependencies(p);
}

@<Can't replace heading subordinate to another replaced heading@> =
	copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
	CE->error_subcategory = HeadingInPlaceOfSubordinate_SYNERROR;
	CE->details_node = h2->sentence_declaring;
	CE->details_work = h2->for_use_with;
	CE->details_work2 = h->for_use_with;
	CE->details_node2 = h->sentence_declaring;
	Copies::attach(C, CE);

@<Can't find heading in the given extension@> =
	TEMPORARY_TEXT(vt);
	WRITE_TO(vt, "unspecified, that is, the extension didn't have a version number");
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Works::match(h->for_use_with, E->as_copy->edition->work)) {
			Str::clear(vt);
			VersionNumbers::to_text(vt, E->as_copy->edition->version);
		}
	copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
	CE->error_subcategory = HeadingInPlaceOfUnknown_SYNERROR;
	CE->details_node = h->sentence_declaring;
	CE->details_work = h->for_use_with;
	CE->details_W = h->in_place_of_text;
	CE->details = Str::duplicate(vt);
	Copies::attach(C, CE);
	DISCARD_TEXT(vt);

@<Can't replace heading unless level matches@> =
	copy_error *CE = Copies::new_error(SYNTAX_CE, NULL);
	CE->error_subcategory = UnequalHeadingInPlaceOf_SYNERROR;
	CE->details_node = h->sentence_declaring;
	Copies::attach(C, CE);
