[Headings::] Headings.

To keep track of the hierarchy of headings and subheadings found
in the source text.

@h The hierarchy.
Headings in the source text correspond to |HEADING_NT| nodes in syntax
trees, and mostly occur when the user has explicitly typed a heading such as:

>> Part VII - The Ghost of the Aragon

Source text can make whatever headings it likes: no sequence is illegal. It
is not for Inform to decide on behalf of the author that it is eccentric to
place Section C before Section B, for instance. The author might be doing so
deliberately, to put the Chariot-race before the Baths, say. This is a
classic case where Inform trying to be too clever would annoy more often
than assist.

Nevertheless the sequence and relative hierarchy of headings is important.
Compare these two sequences:
= (text)
	Part A               Chapter A
	Chapter B            Chapter B
=
In the first case, B is subordinate to A; in the second it is not, and this
affects the meaning of the program.

@ Headings therefore have a numbered "level" of importance, with lower numbers
more important than higher. The hierarchy runs:
= (text)
	Root = -1 > Implied = 0 > Volume = 1 > Book = 2 > Part = 3 > Chapter = 4 > Section = 5
=
"Root" headings can be ignored -- there's one at the root of the heading tree,
but it's only a hook to hang things from. "Implied" headings are inserted
to mark source file boundaries and the like, and aren't written by the author.
The importance of implied headings is that they ensure that every sentence
of source text ultimately falls under some heading.

The implementation allows even lower levels of subheading, 6 to 9, but these
are currently unused.

@d NO_HEADING_LEVELS 10

@ As an example, a sequence in the primary source text of (Chapter I, Book
Two, Section 5, Chapter I, Section 1, Chapter III) would be formed up into
the heading tree:
= (text)
	(the pseudo-heading)                level -1, indentation -1
	    (Implied: inclusions)           level 0, indentation 0
	    (Implied: Basic Inform)         level 0, indentation 0
	        ...
	    (Implied: primary source text)  level 0, indentation 0
	        Chapter I                   level 4, indentation 1
	        Book Two                    level 2, indentation 1
	            Section 5               level 5, indentation 2
	            Chapter I               level 4, indentation 2
	                Section 1           level 5, indentation 3
	            Chapter III             level 4, indentation 2
	    (Implied: inventions)           level 0, indentation 0
=
Note that the level of a heading is not the same thing as its depth in this
tree, which we call the "indentation", and there is no simple relationship
between the two numbers: see below for how it is calculated.

@h Heading trees.
Enough theory: now some practice. Each syntax tree also has a heading tree,
with one "pseudo-heading" (at notional level $-1$) as root. All nodes are
instances of:

@d NEW_HEADING_TREE_SYNTAX_CALLBACK Headings::initialise_heading_tree
@d HEADING_TREE_SYNTAX_TYPE struct heading_tree

=
typedef struct heading_tree {
	struct parse_node_tree *owning_syntax_tree;
	struct heading heading_root;
	int assembled_at_least_once;
	int last_indentation_above_level[NO_HEADING_LEVELS];
	struct linked_list *subordinates; /* of |heading| */
	int damaged; /* i.e., failed verification */
	CLASS_DEFINITION
} heading_tree;

heading *Headings::root_of_tree(heading_tree *HT) {
	return &(HT->heading_root);
}

heading_tree *Headings::initialise_heading_tree(parse_node_tree *T) {
	heading_tree *HT = CREATE(heading_tree);
	HT->owning_syntax_tree = T;
	HT->assembled_at_least_once = FALSE;
	HT->heading_root.parent_heading = NULL;
	HT->heading_root.child_heading = NULL;
	HT->heading_root.next_heading = NULL;
	HT->heading_root.level = -1;
	HT->heading_root.indentation = -1;
	for (int i=0; i<NO_HEADING_LEVELS; i++) HT->last_indentation_above_level[i] = -1;
	HT->subordinates = NEW_LINKED_LIST(heading);
	HT->damaged = FALSE;
	return HT;
}

@ So now we calculate the indentation of a heading. The level $\ell_n$ of a
heading depends only on its wording (or source file origin), but the indentation
of the $n$th heading, $i_n$, depends on $(\ell_1, \ell_2, ..., \ell_n)$, the
sequence of all levels so far:
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

Which proves the correctness of the following innocent-looking function, called
on each heading in sequence:

=
int Headings::indent_from(heading_tree *HT, int level) {
	int I = HT->last_indentation_above_level[level] + 1;
	for (int i=level+1; i<NO_HEADING_LEVELS; i++) HT->last_indentation_above_level[i] = I;
	return I;
}

@h Heading metadata.
Each heading gets the following metadata:

=
typedef struct heading {
	struct heading_tree *owning_tree;
	struct parse_node *sentence_declaring; /* if any: file starts are undeclared */
	struct source_location start_location; /* first word under this heading is here */
	int level; /* 0 for Volume (highest) to 5 for Section (lowest) */
	int indentation; /* in a hierarchical listing */
	int index_definitions_made_under_this; /* for instance, global variables made here? */
	int for_release; /* include this material in a release version? */
	int omit_material; /* if set, simply ignore all of this */
	int use_with_or_without; /* if TRUE, use with the extension; if FALSE, without */
	int holds_dialogue; /* if TRUE, contains dialogue in a different format */
	struct inbuild_work *for_use_with; /* e.g. "for use with ... by ..." */
	struct wording in_place_of_text; /* e.g. "in place of ... in ... by ..." */
	struct wording heading_text; /* once provisos have been stripped away */
	struct wording external_file; /* e.g. "see ..." */
	struct source_file *external_file_read;
	int external_file_loaded;
	struct noun *list_of_contents; /* tagged names defined under this */
	struct noun *last_in_list_of_contents;
	struct heading *parent_heading;
	struct heading *child_heading;
	struct heading *next_heading;
	int omit_from_tree;
	#ifdef CORE_MODULE
	struct heading_compilation_data compilation_data;
	#endif
	CLASS_DEFINITION
} heading;

@ It is guaranteed that this will be called once for each heading (except the
pseudo-heading, which doesn't count) in sequence order:

=
heading *Headings::new(parse_node_tree *T, parse_node *pn, int level, source_location sl) {
	heading *h = CREATE(heading);
	h->owning_tree = T->headings;
	h->parent_heading = NULL; h->child_heading = NULL; h->next_heading = NULL;
	h->omit_from_tree = FALSE;
	h->list_of_contents = NULL; h->last_in_list_of_contents = NULL;
	h->for_release = NOT_APPLICABLE; h->omit_material = FALSE;
	h->index_definitions_made_under_this = TRUE;
	h->use_with_or_without = NOT_APPLICABLE;
	h->in_place_of_text = EMPTY_WORDING;
	h->external_file = EMPTY_WORDING;
	h->external_file_read = NULL;
	h->external_file_loaded = FALSE;
	h->for_use_with = NULL;
	h->sentence_declaring = pn;
	h->holds_dialogue = FALSE;
	h->start_location = sl;
	h->level = level;
	h->heading_text = EMPTY_WORDING;
	h->indentation = Headings::indent_from(T->headings, level);
	ADD_TO_LINKED_LIST(h, heading, T->headings->subordinates);
	#ifdef CORE_MODULE
	h->compilation_data = CompletionModule::new_compilation_data(h);
	#endif
	return h;
}

@h Declarations.
The following callback function is called by //syntax// each time a new
|HEADING_NT| node is created in the syntax tree for a project. It has to
return |TRUE| or |FALSE| to say whether sentences falling under the current
heading should be included in the project's source text. (For instance,
sentences under a heading with the disclaimer "(for Glulx only)" will not be
included if the target virtual machine on this run of Inform is the Z-machine.)

@d NEW_HEADING_SYNTAX_CALLBACK Headings::place

=
int Headings::place(parse_node_tree *T, parse_node *pn, inform_project *proj) {
	heading *h = Headings::attach(T, pn, (proj)?(proj->as_copy):NULL);
	int are_we_releasing = Projects::currently_releasing(proj);
	if ((h->for_release == TRUE) && (are_we_releasing == FALSE)) return FALSE;
	if ((h->for_release == FALSE) && (are_we_releasing == TRUE)) return FALSE;
	if (h->omit_material) return FALSE;
	return TRUE;
}

@ //Projects::read_source_text_for// also constructs implied super-headings
which do not originate in the sentence-breaker, and which therefore need a
different way in. (These are never skipped.)

=
void Headings::place_implied_level_0(parse_node_tree *T, parse_node *pn, inbuild_copy *for_copy) {
	Headings::attach(T, pn, for_copy);
	Annotations::write_int(pn, heading_level_ANNOT, 0);
	Annotations::write_int(pn, implied_heading_ANNOT, TRUE);
}

@ Either way, we can always get back from the parse node to the heading:

=
heading *Headings::from_node(parse_node *pn) {
	return Node::get_embodying_heading(pn);
}

@ So, then, each |HEADING_NT| node in the parse tree produces a call to this
function, which attaches a new //heading// object to it, and populates that
with the result of parsing any caveats in its wording.

=
inbuild_work *work_identified = NULL; /* temporary variable during parsing below */

heading *Headings::attach(parse_node_tree *T, parse_node *pn, inbuild_copy *for_copy) {
	if ((pn == NULL) || (Wordings::empty(Node::get_text(pn))))
		internal_error("heading at textless node");
	if (Node::get_type(pn) != HEADING_NT) 
		internal_error("declared a non-HEADING node as heading");
	int level = Annotations::read_int(pn, heading_level_ANNOT);
	if ((level < 0) || (level >= NO_HEADING_LEVELS)) internal_error("impossible level");

	heading *h = Headings::new(T, pn, level, Wordings::location(Node::get_text(pn)));
	Node::set_embodying_heading(pn, h);
	if (h->level > 0) @<Parse heading text for release or other stipulations@>;

	for (int i=0; i<h->indentation; i++) LOGIF(HEADINGS, "  ");
	LOGIF(HEADINGS, "Attach heading %W level %d ind %d\n",
		Node::get_text(pn), h->level, h->indentation);

	if (T->headings->assembled_at_least_once)
		Headings::assemble_tree(T, for_copy); /* to include new heading: unlikely but possible */
	return h;
}

@ And these are the aforementioned caveats:

@d PLATFORM_UNMET_HQ 0
@d PLATFORM_MET_HQ 1
@d NOT_FOR_RELEASE_HQ 2
@d FOR_RELEASE_ONLY_HQ 3
@d UNINDEXED_HQ 4
@d USE_WITH_HQ 5
@d USE_WITHOUT_HQ 6
@d IN_PLACE_OF_HQ 7
@d DIALOGUE_HQ 8
@d EXTERNAL_HQ 9

@<Parse heading text for release or other stipulations@> =
	current_sentence = pn;

	wording W = Node::get_text(pn);
	while (<heading-qualifier>(W)) {
		switch (<<r>>) {
			case PLATFORM_UNMET_HQ: h->omit_material = TRUE; break;
			case NOT_FOR_RELEASE_HQ: h->for_release = FALSE; break;
			case FOR_RELEASE_ONLY_HQ: h->for_release = TRUE; break;
			case UNINDEXED_HQ: h->index_definitions_made_under_this = FALSE; break;
			case USE_WITH_HQ: h->use_with_or_without = TRUE; break;
			case USE_WITHOUT_HQ: h->use_with_or_without = FALSE; break;
			case DIALOGUE_HQ:
				if (h->level != 5) {
					copy_error *CE = CopyErrors::new(SYNTAX_CE, DialogueOnSectionsOnly_SYNERROR);
					CopyErrors::supply_node(CE, current_sentence);
					Copies::attach_error(sfsm->ref, CE);
				}
				h->holds_dialogue = TRUE;
				break;
			case IN_PLACE_OF_HQ:
				h->use_with_or_without = TRUE;
				h->in_place_of_text = GET_RW(<extension-qualifier>, 1);
				break;
			case EXTERNAL_HQ:
				h->external_file = GET_RW(<bracketed-heading-qualifier>, 1);
				Word::dequote(Wordings::first_wn(h->external_file));
				inform_project *proj = ProjectBundleManager::from_copy(for_copy);
				if (proj) {
					TEMPORARY_TEXT(leaf)
					WRITE_TO(leaf, "%W", h->external_file);
					Projects::add_heading_source(proj, leaf);
					DISCARD_TEXT(leaf)
				}
				break;
		}
		W = GET_RW(<heading-qualifier>, 1);
	}
	h->heading_text = W;
	h->for_use_with = work_identified;

@ When a heading has been found, we repeatedly try to match it against
<heading-qualifier> to see if it ends with text telling us what to do with
the source text it governs. For example,

>> Section 21 - Frogs (unindexed) (not for Glulx)

would match twice, first registering the VM requirement, then the unindexedness.

It's an unfortunate historical quirk that the unbracketed qualifiers are
allowed; they should probably be withdrawn.

Properly speaking the annotation "(dialogue)" should be recognised only if
the dialogue feature is active, but there are timing reasons not to do this:
headings are parsed before the set of active compiler features for a project
is determined.

=
<heading-qualifier> ::=
	... ( <bracketed-heading-qualifier> ) |  ==> { pass 1 }
	... not for release |                    ==> { NOT_FOR_RELEASE_HQ, - }
	... for release only |                   ==> { FOR_RELEASE_ONLY_HQ, - }
	... unindexed                            ==> { UNINDEXED_HQ, - }

<bracketed-heading-qualifier> ::=
	not for release |                        ==> { NOT_FOR_RELEASE_HQ, - }
	for release only |                       ==> { FOR_RELEASE_ONLY_HQ, - }
	unindexed |                              ==> { UNINDEXED_HQ, - }
	dialogue |                               ==> { DIALOGUE_HQ, - }
	dialog |                                 ==> { DIALOGUE_HQ, - }
	dialogue during ... |                    ==> { DIALOGUE_HQ, - }
	dialog during ... |                      ==> { DIALOGUE_HQ, - }
	see { <quoted-text> } |                  ==> { EXTERNAL_HQ, - }
	<platform-qualifier> |                   ==> { pass 1 }
	<extension-qualifier>                    ==> { pass 1 }

<platform-qualifier> ::=
	for <platform-identifier> only |         ==> { (R[1])?PLATFORM_MET_HQ:PLATFORM_UNMET_HQ, - }
	not for <platform-identifier>            ==> { (R[1])?PLATFORM_UNMET_HQ:PLATFORM_MET_HQ, - }

<platform-identifier> ::=
	<language-element> language element |    ==> { pass 1 }
	...... language element |                ==> @<Issue PM_UnknownLanguageElement problem@>
	<current-virtual-machine> |              ==> { pass 1 }
	......                                   ==> @<Issue PM_UnknownVirtualMachine problem@>

<extension-qualifier> ::=
	for use with <extension-identifier> |                      ==> { USE_WITH_HQ, - }
	for use without <extension-identifier> |                   ==> { USE_WITHOUT_HQ, - }
	not for use with <extension-identifier> |                  ==> { USE_WITHOUT_HQ, - }
	in place of ( <quoted-text> ) in <extension-identifier> |  ==> { IN_PLACE_OF_HQ, - }
	in place of ...... in <extension-identifier>               ==> { IN_PLACE_OF_HQ, - }

<extension-identifier> ::=
	...... by ......                         ==> @<Set for-use-with extension identifier@>

@<Issue PM_UnknownLanguageElement problem@> =
	#ifdef CORE_MODULE
	copy_error *CE = CopyErrors::new(SYNTAX_CE, UnknownLanguageElement_SYNERROR);
	CopyErrors::supply_node(CE, current_sentence);
	Copies::attach_error(sfsm->ref, CE);
	#endif

@<Issue PM_UnknownVirtualMachine problem@> =
	copy_error *CE = CopyErrors::new(SYNTAX_CE, UnknownVirtualMachine_SYNERROR);
	CopyErrors::supply_node(CE, current_sentence);
	Copies::attach_error(sfsm->ref, CE);

@<Set for-use-with extension identifier@> =
	TEMPORARY_TEXT(exft)
	TEMPORARY_TEXT(exfa)
	wording TW = GET_RW(<extension-identifier>, 1);
	wording AW = GET_RW(<extension-identifier>, 2);
	WRITE_TO(exft, "%+W", TW);
	WRITE_TO(exfa, "%+W", AW);
	work_identified = Works::new(extension_genre, exft, exfa);
	DISCARD_TEXT(exft)
	DISCARD_TEXT(exfa)
	==> { R[0] + 4, - };

@ This nonterminal matches any description of a virtual machine, and produces
the result |TRUE| if the VM we are building for fits that description, |FALSE|
otherwise.

=
<current-virtual-machine> internal {
	if (<virtual-machine>(W)) {
		compatibility_specification *vms = (compatibility_specification *) <<rp>>;
		==> { Compatibility::test(vms, Supervisor::current_vm()), - };
		return TRUE;
	} else {
		==> { fail nonterminal };
	}
}

@h The heading tree.
Until //Headings::assemble_tree// runs, the //heading// nodes listed as belonging
to the heading tree are not in fact formed up into a tree structure.

=
void Headings::assemble_tree(parse_node_tree *T, inbuild_copy *for_copy) {
	heading *h;
	@<Disassemble the whole heading tree to a pile of twigs@>;
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates) {
		if (h->omit_from_tree == FALSE) {
			@<If h is outside the tree, make it a child of the pseudo-heading@>;
			@<If h is held in an external file, move those headings to it@>;
			@<Run through subsequent equal or subordinate headings to move them downward@>;
		}
	}
	T->headings->assembled_at_least_once = TRUE;
	Headings::verify_heading_tree(T);
	#ifndef CORE_MODULE
	Copies::list_attached_errors(STDERR, for_copy);
	#endif
	#ifdef CORE_MODULE
	SourceProblems::issue_problems_arising(for_copy);
	#endif
}

@ It's possible to call //Headings::assemble_tree// more than once, to allow
for late news coming in (see //Headings::attach// above), so we always begin by
disassembling the tree, and then we can be sure that we start from nothing.

Note that the pseudo-heading used as a root of the tree is not in the list
of subordinates. Everything else is.

@<Disassemble the whole heading tree to a pile of twigs@> =
	T->headings->heading_root.child_heading = NULL;
	T->headings->heading_root.parent_heading = NULL;
	T->headings->heading_root.next_heading = NULL;
	heading *h;
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates) {
		h->parent_heading = NULL; h->child_heading = NULL; h->next_heading = NULL;
		h->omit_from_tree = FALSE;
	}

@ The idea of the heading loop is that when we place a heading, we also place
subsequent headings of lesser or equal status until we cannot do so any longer.
That means that if we reach h and find that it has no parent, it must be
subordinate to no earlier heading: thus, it must be attached to the pseudo-heading
at the top of the tree.

@<If h is outside the tree, make it a child of the pseudo-heading@> =
	if ((h->parent_heading == NULL) && (h->omit_from_tree == FALSE))
		Headings::move_below(h, &(T->headings->heading_root));

@ A complication is that the source text is read out of conceptual sequence
when headings referring to external files are run into. Because of that, if
we have a heading:
= (text as Inform 7)
	Chapter 7 - Into the Woods (see "woods.i7")
=
and if we then have further headings inside the file |woods.i7|, those
further headings |h2| won't be adjacent to the original heading |h| in
the list. So we fix this up here.

There is a nameless level zero heading marking the change of source file:
we remove that. We also have to throw problems if we find, say, a Book
heading inside a file which is supposed to contain a Chapter.

@e HeadingTooGreat_SYNERROR

@<If h is held in an external file, move those headings to it@> =
	if (h->external_file_read) {
		heading *h2;
		LOOP_OVER_LINKED_LIST(h2, heading, T->headings->subordinates)
			if (h2->start_location.file_of_origin == h->external_file_read) {
				if (h2->level == 0) {
					h2->omit_from_tree = TRUE;
				} else if (h2->level <= h->level) {
					copy_error *CE = CopyErrors::new(SYNTAX_CE, HeadingTooGreat_SYNERROR);
					CopyErrors::supply_node(CE, h2->sentence_declaring);
					Copies::attach_error(for_copy, CE);
					h2->omit_from_tree = TRUE;
				} else {
					Headings::move_below(h2, h);
					h2->indentation++;
				}
			}
	}

@ Note that the following could be summed up as "move subsequent headings as
deep in the tree as we can see they need to be from h's perspective alone".
This isn't always the final position. For instance, given the sequence
Volume 1, Chapter I, Section A, Chapter II, the tree is adjusted twice:
= (text)
	when h = Volume 1:        then when h = Chapter I:
	Volume 1                  Volume 1
	    Chapter I                 Chapter I
	    Section A                     Section A
	    Chapter II                Chapter II
=
since Section A is demoted twice, once by Volume 1, then by Chapter I.
(This algorithm would in principle be quadratic in the number of headings if
the possible depth of the tree were unbounded -- every heading might have to
demote every one of its successors -- but since the depth is at most 9, it
runs in linear time.)

@<Run through subsequent equal or subordinate headings to move them downward@> =
	heading *subseq;
	for (subseq = NEXT_OBJECT(h, heading); /* start from the next heading in source */
		(subseq) && (subseq->level >= h->level); /* for a run with level below or equal h */
		subseq = NEXT_OBJECT(subseq, heading)) { /* in source declaration order */
		if (subseq->level == h->level) { /* a heading of equal status ends the run... */
			Headings::move_below(subseq, h->parent_heading); break; /* ...becoming h's sibling */
		}
		Headings::move_below(subseq, h); /* all lesser headings in the run become h's children */
	}

@ The above function, then, calls |Headings::move_below| to attach a heading
to the tree as a child of a given parent:

=
void Headings::move_below(heading *ch, heading *pa) {
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
		else
			for (heading *sib = former_pa->child_heading; sib; sib = sib->next_heading)
				if (sib->next_heading == ch) {
					sib->next_heading = ch->next_heading;
					break;
				}
	}
	ch->next_heading = NULL;

@ Two cases: the new parent is initially childless, or it isn't.

@<Add ch to the end of the list of children of pa@> =
	if (pa->child_heading == NULL) pa->child_heading = ch;
	else
		for (heading *sib = pa->child_heading; sib; sib = sib->next_heading)
			if (sib->next_heading == NULL) {
				sib->next_heading = ch;
				break;
			}

@h Verifying the heading tree.
We have now, in effect, computed the indentation value of each heading twice,
by two entirely different methods: first by the mathematical argument above,
then by observing that it is the depth in the heading tree. Seeing if
these two methods have given the same answer provides a convenient check on
our working.

=
void Headings::verify_heading_tree(parse_node_tree *T) {
	Headings::verify_heading_tree_r(T,
		&(T->headings->heading_root), &(T->headings->heading_root), -1);
	if (T->headings->damaged) internal_error("heading tree failed to verify");
}

void Headings::verify_heading_tree_r(parse_node_tree *T, heading *root, heading *h,
	int depth) {
	if (h == NULL) return;
	if ((h != root) && (depth != h->indentation)) {
		T->headings->damaged = TRUE;
		LOG("$H\n*** indentation should be %d ***\n", h, depth);
	}
	Headings::verify_heading_tree_r(T, root, h->child_heading, depth+1);
	Headings::verify_heading_tree_r(T, root, h->next_heading, depth);
}

@h Falling under headings.
Given a position in the source code, or an excerpt of source text, which
heading does it fall under?

This question matters since the parsing of noun phrases is affected by
that choice of heading: to Inform, headings provide something analogous to
the scope of local variables in a conventional programming language. It also
affects problem messages.

Because every file has an Implied (0) heading registered at line 1, the loop
in the following function is guaranteed to return a valid heading provided
the original source location is well formed (i.e., has a non-null source
file and a line number of at least 1).

=
heading *Headings::of_location(source_location sl) {
	if (sl.file_of_origin == NULL) return NULL;
	heading *h;
	LOOP_BACKWARDS_OVER(h, heading)
		if ((sl.file_of_origin == h->start_location.file_of_origin) &&
			(sl.line_number >= h->start_location.line_number)) return h;
	internal_error("unable to determine the heading level of source material");
	return NULL;
}

heading *Headings::of_wording(wording W) {
	return Headings::of_location(Wordings::location(W));
}

@h Miscellaneous other services.

=
int Headings::indexed(heading *h) {
	if (h == NULL) return TRUE; /* definitions made nowhere are normally indexed */
	return h->index_definitions_made_under_this;
}

inform_extension *Headings::get_extension_containing(heading *h) {
	if ((h == NULL) || (h->start_location.file_of_origin == NULL)) return NULL;
	return Extensions::corresponding_to(h->start_location.file_of_origin);
}

@ Although Implied (0) headings do have text, contrary to the implication of
the function here, this text is only what happens to be first in the file,
or else is something supplied by //supervisor// purely to make the debugging
log comprehensible: it isn't a heading typed as such by the user, which is all
that we are interested in for this purpose. So we send back a null word range.

=
wording Headings::get_text(heading *h) {
	if ((h == NULL) || (h->level == 0)) return EMPTY_WORDING;
	return h->heading_text;
}

@ Whence:

@d WORDING_FOR_HEADING_NODE_PROBLEMS_CALLBACK Headings::wording_for_heading_node

=
wording Headings::wording_for_heading_node(parse_node *p) {
	return Headings::get_text(Headings::from_node(p));
}

@h Headings with extension dependencies.
If the content under a heading depended on a VM not in use, or was marked
not for release in a release run, we were able to exclude it just by
skipping. The same cannot be done when a heading says that it should be
used only if a given extension is, or is not, being used, because when
the heading is created we don't yet know which extensions are included.
But when the following is called, we do know that.

=
void Headings::satisfy_dependencies(inform_project *proj, parse_node_tree *T,
	inbuild_copy *C) {
	heading *h;
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates)
		if (h->use_with_or_without != NOT_APPLICABLE)
			Headings::satisfy_individual_heading_dependency(proj, T, C, h);
}

@ And now the code to check an individual heading's usage. This whole
thing is carefully timed so that we can still afford to cut up and rearrange
the parse tree on quite a large scale, and that's just what we do.

=
void Headings::satisfy_individual_heading_dependency(inform_project *proj,
	parse_node_tree *T, inbuild_copy *C, heading *h) {
	if (h->level < 1) return;
	inbuild_work *work = h->for_use_with;
	int loaded = FALSE;
	if (work) {
		inform_extension *E;
		LOOP_OVER_LINKED_LIST(E, inform_extension, proj->extensions_included) {
			if (Works::match(E->as_copy->edition->work, work))
				loaded = TRUE;
		}
	}
	LOGIF(HEADINGS, "SIHD on $H: loaded %d: annotation %d: %W: %d\n", h, loaded,
		Annotations::read_int(h->sentence_declaring,
			suppress_heading_dependencies_ANNOT),
		h->in_place_of_text, h->use_with_or_without);
	if (Wordings::nonempty(h->in_place_of_text)) {
		wording S = h->in_place_of_text;
		if (Annotations::read_int(h->sentence_declaring,
			suppress_heading_dependencies_ANNOT) == FALSE) {
			if (<quoted-text>(h->in_place_of_text)) {
				Word::dequote(Wordings::first_wn(S));
				inchar32_t *text = Lexer::word_text(Wordings::first_wn(S));
				S = Feeds::feed_C_string(text);
			}
			if (loaded == FALSE) @<Can't replace heading in an unincluded extension@>
			else {
				heading *h2;
				int found = FALSE;
				LOOP_OVER_LINKED_LIST(h2, heading, T->headings->subordinates) {
					inform_extension *ext = Headings::get_extension_containing(h2);
					if ((Wordings::nonempty(h2->heading_text)) &&
						(Wordings::match_perhaps_quoted(S, h2->heading_text)) &&
						(Works::match(ext->as_copy->edition->work, work))) {
						found = TRUE;
						if (h->level != h2->level)
							@<Can't replace heading unless level matches@>;
						Headings::excise_material_under(T, C, h2, NULL);
						Headings::excise_material_under(T, C, h, h2->sentence_declaring);
						break;
					}
				}
				if (found == FALSE) @<Can't find heading in the given extension@>;
			}
		}
	} else if (h->use_with_or_without != loaded) {
		Headings::excise_material_under(T, C, h, NULL);
	}
}

@<Can't replace heading in an unincluded extension@> =
	copy_error *CE = CopyErrors::new(SYNTAX_CE, HeadingInPlaceOfUnincluded_SYNERROR);
	CopyErrors::supply_node(CE, h->sentence_declaring);
	CopyErrors::supply_work(CE, h->for_use_with);
	Copies::attach_error(C, CE);

@ To excise, we simply prune the heading's contents from the parse tree,
though optionally grafting them to another node rather than discarding them
altogether.

Any heading which is excised is marked so that it won't have its own
dependencies checked. This clarifies several cases, and in particular ensures
that if Chapter X is excised then a subordinate Section Y cannot live on by
replacing something elsewhere (which would effectively delete the content
elsewhere).

=
void Headings::excise_material_under(parse_node_tree *T, inbuild_copy *C,
	heading *h, parse_node *transfer_to) {
	LOGIF(HEADINGS, "Excision under $H\n", h);
	parse_node *hpn = h->sentence_declaring;
	if (h->sentence_declaring == NULL)
		internal_error("stipulations on a non-sentence heading");

	if (Wordings::nonempty(h->in_place_of_text)) {
		heading *h2 = Headings::find_dependent_heading(hpn->down);
		if (h2) @<Can't replace heading subordinate to another replaced heading@>;
	}

	Headings::suppress_dependencies(hpn);
	if ((transfer_to) && (hpn->down)) SyntaxTree::graft(T, hpn->down, transfer_to);
	hpn->down = NULL;
}

@ =
heading *Headings::find_dependent_heading(parse_node *pn) {
	if (pn == NULL) return NULL;
	if (Node::get_type(pn) == HEADING_NT) {
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
	if (Node::get_type(pn) == HEADING_NT)
		Annotations::write_int(pn, suppress_heading_dependencies_ANNOT, TRUE);
	for (parse_node *p = pn->down; p; p = p->next)
		Headings::suppress_dependencies(p);
}

@<Can't replace heading subordinate to another replaced heading@> =
	copy_error *CE = CopyErrors::new(SYNTAX_CE, HeadingInPlaceOfSubordinate_SYNERROR);
	CopyErrors::supply_works(CE, h2->for_use_with, h->for_use_with);
	CopyErrors::supply_nodes(CE, h2->sentence_declaring, h->sentence_declaring);
	Copies::attach_error(C, CE);

@<Can't find heading in the given extension@> =
	TEMPORARY_TEXT(vt)
	WRITE_TO(vt, "unspecified, that is, the extension didn't have a version number");
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Works::match(h->for_use_with, E->as_copy->edition->work)) {
			Str::clear(vt);
			VersionNumbers::to_text(vt, E->as_copy->edition->version);
		}
	copy_error *CE = CopyErrors::new_T(SYNTAX_CE, HeadingInPlaceOfUnknown_SYNERROR, vt);
	CopyErrors::supply_node(CE, h->sentence_declaring);
	CopyErrors::supply_work(CE, h->for_use_with);
	CopyErrors::supply_wording(CE, h->in_place_of_text);
	Copies::attach_error(C, CE);
	DISCARD_TEXT(vt)

@<Can't replace heading unless level matches@> =
	copy_error *CE = CopyErrors::new(SYNTAX_CE, UnequalHeadingInPlaceOf_SYNERROR);
	CopyErrors::supply_node(CE, h->sentence_declaring);
	Copies::attach_error(C, CE);

@h The XML file.
This is provided as a convenience to the application using Inform, which may want
to have a pull-down menu or similar gadget allowing the user to jump to a given
heading. This tells the interface where every heading is, thus saving it from
having to parse the source.

The property list contains a single dictionary, whose keys are the numbers
0, 1, 2, ..., $n-1$, where there are $n$ headings in all.

A special key, the only non-numerical one, called "Application Version", contains
the Inform build number.

=
void Headings::write_as_XML(parse_node_tree *T, filename *F) {
	text_stream xf_struct; text_stream *OUT = &xf_struct;
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE) {
		#ifdef CORE_MODULE
		Problems::fatal_on_file("Can't open headings file", F);
		#endif
		#ifndef CORE_MODULE
		Errors::fatal_with_file("can't open headings file", F);
		#endif
	}
	heading *h;
	@<Write DTD indication for XML headings file@>;
	WRITE("<plist version=\"1.0\"><dict>\n");
	INDENT;
	WRITE("<key>Application Version</key><string>%B (build %B)</string>\n", FALSE, TRUE);
	LOOP_OVER_LINKED_LIST(h, heading, T->headings->subordinates) {
		WRITE("<key>%d</key><dict>\n", h->allocation_id);
		INDENT;
		@<Write the dictionary of properties for a single heading@>;
		OUTDENT;
		WRITE("</dict>\n");
	}
	OUTDENT;
	WRITE("</dict></plist>\n");
	STREAM_CLOSE(OUT);
}

@ We use a convenient Apple DTD:

@<Write DTD indication for XML headings file@> =
	WRITE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		"<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" "
		"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");

@ Note that a level of 0, and a title of |--|, signifies a File (0) level
heading: external tools can probably ignore such records. Similarly, it is
unlikely that they will ever see a record without a "Filename" key, but they
are optional all the same.

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
