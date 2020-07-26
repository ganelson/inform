[Sentences::Rearrangement::] Of and From.

To verify that "of" and "from" subtrees in assertion sentence
noun phrases are validly used, and reconstruct their sentences without them
if they are not.

@h Definitions.

@ At this point in the narrative, the source text has been parsed into a
large parse tree in which every assertion is represented by a |SENTENCE_NT|
node. This is a child of the root of the tree, and its own children form
a subtree which parses it into a verb phrase and associated noun phrases.
Pretty well whenever it possibly could, the noun-phrase-maker created
|X_OF_Y_NT| subtrees in these noun phrases.

But |X_OF_Y_NT| nodes are valid only when describing a value
property associated with something ("description of the cards"), which
means that the noun-phrase-maker will have been wildly overzealous in
creating these. It had to be: it had no way of knowing, so early in
Inform's run, which handful of the many such nodes it made were actually
valid. It didn't know what the property names were, nor what the direction
names were. (For chicken-and-egg reasons, it couldn't know this.) So it
almost certainly made some spurious noun phrase subtrees like this one:
= (text)
	X_OF_Y_NT "worn patch of carpet"
	    PROPER_NOUN_NT "carpet"
	    PROPERTY_LIST_NT "worn patch"
=
Now comes the reckoning. The existing parse tree may contain a few bogus
nodes, but it's good enough to determine all the property and direction
names. This then enables us to go back and check all the |X_OF_Y_NT|
subtrees, expunging the ones which are spurious.

@h Tidying up ofs and from.
In deciding whether "worn patch of carpet" is to be treated as a single noun,
as a property ("worn patch") belonging to a noun ("carpet"), or as a
direction ("worn patch") relative to a noun ("carpet") -- consider the
cases "description of carpet" and "east of the lawn" -- the key thing
is to understand the meaning of the subject ("worn patch"). Unfortunately,
the model world will not be created, much less named, for quite a long
time to come: so we cannot simply parse the subject as an expression. At this
early stage the best we can do is to scan ahead through the parse tree to
try to find direction and property declarations. We do this with a sequence
of three traversals:

(-1.) Look for property and direction declarations. Create the property
names called for; do not actually create the directions (that will happen
much later), but remember their names.
(-2.) Reconstruct the parse trees of any sentences which refer to
property names which themselves contain an "of" (as may happen if, for
instance, there is a property called "point of view").
(-3.) Look for location phrases like "east from the lawn", which we can
distinguish from other uses of "from" now that we know the direction
names; at the same time look for "X of Y" phrases where the "of" should
not be treated as a possessive, and expunge them.

=
void Sentences::Rearrangement::further_material(void) {
	Sentences::Rearrangement::tidy_up_ofs_and_froms();
	Sentences::RuleSubtrees::register_recently_lexed_phrases();
}

void Sentences::Rearrangement::tidy_up_ofs_and_froms(void) {
	VerifyTree::verify_integrity(Task::syntax_tree());
	SyntaxTree::traverse_wfirst(Task::syntax_tree(), Sentences::Rearrangement::traverse_for_property_names);
	SyntaxTree::traverse(Task::syntax_tree(), Sentences::Rearrangement::traverse_for_nonbreaking_ofs);
}

@ The following array is used only by Traversals 1 to 3, and is how we
remember direction names.

@d MAX_DIRECTIONS 100 /* the Standard Rules define only 12, so this is plenty */

=
parse_node *directions_noticed[MAX_DIRECTIONS];
binary_predicate *direction_relations_noticed[MAX_DIRECTIONS];
int no_directions_noticed = 0;

@h Traversal 1.
We now come to the routine which traverses the entire tree looking for
property declarations.

In this as in the subsequent traversals, we use a loop rather than recursion
to span the width of the tree: otherwise our stack usage goes through the
roof, since it might need to recurse thousands of function calls deep.

=
void Sentences::Rearrangement::traverse_for_property_names(parse_node *pn) {
	if (Node::get_type(pn) == VERB_NT)
		@<See if this assertion creates property names with "... has ... called ..."@>;
}

@ Directions are detected in sentences having the form "D is a direction."

=
void Sentences::Rearrangement::check_sentence_for_direction_creation(parse_node *pn) {
	#ifdef IF_MODULE
	if (Node::get_type(pn) != SENTENCE_NT) return;
	if ((pn->down == NULL) || (pn->down->next == NULL) || (pn->down->next->next == NULL)) return;
	if (Node::get_type(pn->down) != VERB_NT) return;
	if (Node::get_type(pn->down->next) != UNPARSED_NOUN_NT) return;
	if (Node::get_type(pn->down->next->next) != UNPARSED_NOUN_NT) return;
	current_sentence = pn;
	pn = pn->down->next;
	if (!((<notable-map-kinds>(Node::get_text(pn->next)))
			&& (<<r>> == 0))) return;
	if (no_directions_noticed >= MAX_DIRECTIONS) {
		StandardProblems::limit_problem(Task::syntax_tree(), _p_(PM_TooManyDirections),
			"different directions", MAX_DIRECTIONS);
		return;
	}
	direction_relations_noticed[no_directions_noticed] =
		PL::MapDirections::create_sketchy_mapping_direction(Node::get_text(pn));
	directions_noticed[no_directions_noticed++] = pn;
	#endif
}

@ And to extract that sketchy BP later, for completion when possible:

=
binary_predicate *Sentences::Rearrangement::relation_noticed(int i) {
	return direction_relations_noticed[i];
}

@ Typical patterns here are sentences in the form "X has a K called P".
The trouble is that at this stage we can't verify that X is an instance
or kind (they don't exist yet), nor that K is itself a kind (for the same
reason). We must simply rely on the fact that assertions cannot take this
form without being property declarations -- with one exception: see below.

We therefore look for this subtree structure:
= (text)
	SENTENCE_NT "A container has a number called volume"
	    VERB_NT "has"
	    PROPER_NOUN_NT "container" article:indefinite
	    CALLED_NT "called"
	        PROPER_NOUN_NT "number" article:indefinite
	        PROPER_NOUN_NT "volume"
=
...and then extract the bottom-most, rightmost noun-phrase as the name of
the new property.

@<See if this assertion creates property names with "... has ... called ..."@> =
	if ((Annotations::read_int(pn, verb_id_ANNOT) == ASSERT_VB)
		&& (pn->next)
		&& (pn->next->next)
		&& (Assertions::Copular::possessive(pn->next->next))
		&& (Node::get_type(pn->next->next->down) == CALLED_NT)
		&& (pn->next->next->down->down)
		&& (pn->next->next->down->down->next)) {
		parse_node *apparent_subject = pn->next;
		wording SW = Node::get_text(apparent_subject);
		if (Node::get_type(apparent_subject) == WITH_NT)
			if (apparent_subject->down) {
				int s1 = Wordings::first_wn(Node::get_text(apparent_subject->down));
				if (apparent_subject->down->next)
					SW = Wordings::new(s1, Wordings::last_wn(Node::get_text(apparent_subject->down->next)));
				else
					SW = Wordings::new(s1, Wordings::last_wn(SW));
			}

		if (<prohibited-property-owners>(SW) == FALSE) {
			<has-properties-called-sentence-object>(Node::get_text(pn->next->next->down->down->next));
		}
	}

@ A tricky point in detecting property declarations is that they share the
syntax used for action, activity and rulebook variables. For instance:

>> The taking action has a number called the hazard level.

...creates not a property name but an action variable. Fortunately, the names
of such owners have a distinctive look to them:

=
<prohibited-property-owners> ::=
	<action-name-formal> |
	<activity-name-formal> |
	<rulebook-name-formal>

@ And this seems a good place to declare the grammar for our "formal names".
For instance, if we want to talk about the "taking" action in abstract as
a noun, we write it in the formal way "taking action".

=
<action-name-formal> ::=
	... action

<activity-name-formal> ::=
	... activity

<relation-name-formal> ::=
	... relation

<rule-name-formal> ::=
	... rule

<rulebook-name-formal> ::=
	... rulebook

@ We need to know the property names early in parsing in order to make sure
we aren't breaking noun phrases at "of" incorrectly. So the following
grammar is applied to sentences in the form:

>> A vehicle has numbers called seating capacity and fuel efficiency.

...and creates these property names right now. (We also filter out some bad
property names before they can do any damage.)

=
<has-properties-called-sentence-object> ::=
	<has-property-name> <has-property-name-tail> |
	<has-property-name>

<has-property-name-tail> ::=
	, {_and} <has-properties-called-sentence-object> |
	{_,/and} <has-properties-called-sentence-object>

<has-property-name> ::=
	<bad-property-name-diagnosis> |    ==> 0
	...												==> 0; Properties::Valued::obtain(W);

<bad-property-name-diagnosis> ::=
	<article> |    ==> @<Issue PM_PropertyCalledArticle problem@>
	presence |    ==> @<Issue PM_PropertyCalledPresence problem@>
	*** , *** |    ==> @<Issue PM_PropertyNameForbidden problem@>
	*** <quoted-text> ***							==> @<Issue PM_PropertyNameForbidden problem@>

@<Issue PM_PropertyCalledArticle problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyCalledArticle),
		"a property name cannot consist only of an article",
		"which this one seems to. It would lead to awful ambiguities. "
		"More likely, the end of the sentence has been lost somehow?");

@<Issue PM_PropertyCalledPresence problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyCalledPresence),
		"a property name cannot consist only of the word 'presence'",
		"because this would lead to ambiguities with the rule clause "
		"'...in the presence of...' (For instance, when writing something "
		"like 'Instead of eating in the presence of the Queen: ...') "
		"The best way to fix this is probably to add another word or "
		"two to the property name: 'stage presence', say, would be fine.");

@<Issue PM_PropertyNameForbidden problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyNameForbidden),
		"a property name cannot contain quoted text or a comma",
		"which this one seems to. I think I must be misunderstanding: "
		"possibly you've added a subordinate clause which I can't "
		"make sense of?");

@ Because we might only just have discovered the property names, it's likely
that some of our earlier attempts to break noun phrases were wrong. For
example, not knowing that "point of view" was going to be a property name,
we'll have broken

>> The point of view of Kathy is "All grammar is bunk."

as "((The point) of (view of Kathy)) is...".

So we look back over assertions which might have broken, and if they contain
the text of such a property name, we throw away the existing subtree for the
sentence and build a fresh one. (Very probably smaller and simpler since
it will not now break at what we now suspect to be a bad position.)

In a few cases, where for some other reason the of-break was not taken
anyway, nothing will change -- for instance, "On the table is a book
called My point of view" does not break at the "of" whether it's a good
break or a bad one, because the "called" construction takes priority.
We could with some more work avoid this, but it causes no nuisance and
wastes only a negligible amount of memory.

=
<sentence-needing-second-look> ::=
	*** <ambiguous-property-name> ***

@ And this code effects it:

=
void Sentences::Rearrangement::traverse_for_nonbreaking_ofs(parse_node *pn) {
	if ((Node::get_type(pn) == SENTENCE_NT) &&
		(pn->down) && (Node::get_type(pn->down) == VERB_NT)) {
		int vn = Annotations::read_int(pn->down, verb_id_ANNOT);
		if (((vn == ASSERT_VB) || (Annotations::read_int(pn->down, examine_for_ofs_ANNOT))) &&
			(<sentence-needing-second-look>(Node::get_text(pn)))) {
			current_sentence = pn; /* (just in case any problem messages are issued) */
			pn->down = NULL; /* thus cutting off and forgetting its former subtree */
			Sentences::VPs::seek(pn); /* ...in order to make a new one */
		}
	}
}
