[PropertySentences::] Property Sentences.

To examine assertion sentences for property creation.

@ Inform's syntax for value properties is "X of Y": "the carrying capacity
of the box", say. Because of this, the word "of" is structurally significant
when diagramming assertion sentences. Unfortunately "of" also occurs in many
other situations:

>> Yett of Ptarmigan is a room.

(It's a lookout point on the West Highland Way, not far from the village of
Milton of Buchanan.) We therefore want to subdivide the parse tree at "of"
only when it is preceded by a property name, but this means we need to know
the property names early in Inform's run.

@ We therefore look for this configuration:
= (text)
	SENTENCE_NT "A container has a number called volume"
	    VERB_NT "has"
	    UNPARSED_NOUN_NT "container"
	    CALLED_NT "called"
	        UNPARSED_NOUN_NT "number"
	        UNPARSED_NOUN_NT "volume"
=
...and then extract the bottom-most, rightmost noun-phrase as the name of
a new property. It's sufficient to create it with no other details; the
sentence will be properly parsed later on.

=
void PropertySentences::look_for_property_creation(parse_node *pn) {
	pn = pn->down;
	if ((Node::get_type(pn) == VERB_NT)
		&& (Assertions::Traverse::special(pn) == FALSE)
		&& (pn->next)
		&& (pn->next->next)
		&& (Diagrams::is_possessive_RELATIONSHIP(pn->next->next))
		&& (Node::get_type(pn->next->next->down) == CALLED_NT)
		&& (pn->next->next->down->down)
		&& (pn->next->next->down->down->next)) {
		parse_node *apparent_subject = pn->next;
		wording SW = Node::get_text(apparent_subject);
		if (Node::get_type(apparent_subject) == WITH_NT)
			if (apparent_subject->down) {
				int s1 = Wordings::first_wn(Node::get_text(apparent_subject->down));
				parse_node *C = apparent_subject->down->next;
				if (C)
					SW = Wordings::new(s1, Wordings::last_wn(Node::get_text(C)));
				else
					SW = Wordings::new(s1, Wordings::last_wn(SW));
			}
		wording PW = Node::get_text(pn->next->next->down->down->next);
		if (<prohibited-property-owners>(SW) == FALSE)
			<has-properties-called-sentence-object>(PW);
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

@ Assuming the owner passes that sanity check, the following grammar is then
applied to the presumed property name: note the side-effect of the final
production of <has-property-name>.

=
<has-properties-called-sentence-object> ::=
	<has-property-name> <has-property-name-tail> |
	<has-property-name>

<has-property-name-tail> ::=
	, {_and} <has-properties-called-sentence-object> |
	{_,/and} <has-properties-called-sentence-object>

<has-property-name> ::=
	<article> |                      ==> @<Issue PM_PropertyCalledArticle problem@>
	presence |                       ==> @<Issue PM_PropertyCalledPresence problem@>
	*** , *** |                      ==> @<Issue PM_PropertyNameForbidden problem@>
	*** <quoted-text> *** |          ==> @<Issue PM_PropertyNameForbidden problem@>
	...                              ==> { 0, Properties::Valued::obtain(W) }

@<Issue PM_PropertyCalledArticle problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyCalledArticle),
		"a property name cannot consist only of an article",
		"which this one seems to. It would lead to awful ambiguities. "
		"More likely, the end of the sentence has been lost somehow?");
	==> { 0, - }

@<Issue PM_PropertyCalledPresence problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyCalledPresence),
		"a property name cannot consist only of the word 'presence'",
		"because this would lead to ambiguities with the rule clause "
		"'...in the presence of...' (For instance, when writing something "
		"like 'Instead of eating in the presence of the Queen: ...') "
		"The best way to fix this is probably to add another word or "
		"two to the property name: 'stage presence', say, would be fine.");
	==> { 0, - }

@<Issue PM_PropertyNameForbidden problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyNameForbidden),
		"a property name cannot contain quoted text or a comma",
		"which this one seems to. I think I must be misunderstanding: "
		"possibly you've added a subordinate clause which I can't "
		"make sense of?");
	==> { 0, - }
