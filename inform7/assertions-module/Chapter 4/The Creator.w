[Assertions::Creator::] The Creator.

This is where all objects, kinds of object, named values, kinds of
value and global variables are made.

@h Creations to match unrecognised names.
The model contains objects, their properties and their relationships, and
this section is where all of the objects are created -- not only world
objects (like rooms and people) but also named values.

The model world is initially empty. It grows gradually as sentences are
read in, or to be more accurate as they are traversed in the first major
pass through assertions. For example, we reach:

>> Fifi is in the wicker basket.

The two sides of the assertion are, respectively, |px|:
= (text)
	node:PROPER_NOUN_NT  <fifi> (no article)
=
And |py|:
= (text)
	node:RELATIONSHIP_NT  <in> (type:standard)
	    node:PROPER_NOUN_NT  <wicker basket> (definite)
=
The Creator is not alas a cultured gentleman with a white-pointed beard, a
roll of architect's plans and a set square, perhaps played by an American
character actor in a movie like "The Matrix". It's just a routine which
returns either |TRUE| or |FALSE|, giving permission for reading of the
sentence to continue; and it always grants this permission unless a problem
message had to be issued during its work.

=
int problem_count_when_creator_started;

int Assertions::Creator::consult_the_creator(parse_node *px, parse_node *py) {
	problem_count_when_creator_started = problem_count;
	if (<np-existential>(Node::get_text(px)))
		@<Perform creation duties on a "There is..." sentence@>
	else
		@<Perform creation duties on a copular sentence@>;
	if (problem_count > problem_count_when_creator_started) return FALSE;
	return TRUE;
}

@ This is the simpler case. Usually what goes on in the |px| side affects what
creations we make in the |py| side and vice versa, but here there's no
information on the |px| side, "there" being essentially a meaningless
placeholder in English, like the "it" in "it is raining".

Note that only the most primitive "there is" sentences turn up here.
Something like "There is a man in the Dining Room" is given a tree form
equivalent to "A man is in the Dining Room", and falls into the copular
case below. The only sentences coming here are things like "There is a
room."

@<Perform creation duties on a "There is..." sentence@> =
	Assertions::Creator::noun_creator(py, NULL, NULL);

@ More generally we need to work out what |px| tells us about creations in |py|,
and vice versa. In particular, in terms of the kind of value involved. For
example:

>> A man is in the Dining Room. Red is a colour.

In each case |px| describes something which will need to be created, but |py|
tells us what kind it has: a colour in the second sentence here, but an object
in the first. (We do not need to decide the kind of object here, and
don't: it's sufficient to pin it down as far as "object".) The information
about this kind of value sometimes comes from a particular node somewhere
in |py|, which (if it exists) we'll call its "governing node".

@<Perform creation duties on a copular sentence@> =
	PluginCalls::creation(px, py);
	parse_node *govx = NULL, *govy = NULL;
	kind *kindx = NULL, *kindy = NULL;
	@<Work out the kinds of value expressed by each side, and find their governing nodes@>;
	Assertions::Creator::noun_creator(px, kindy, govy);
	Assertions::Creator::noun_creator(py, kindx, govx);

@ There are two ways to know the kind being expressed. One is that the sentence
makes unambiguous use of a relation which forces the kinds on each side. For
example,

>> The ball is on the box.

uses the binary predicate supports, which requires its terms to be
objects. (In fact it requires them to be a thing and a supporter, but we
weaken those into just "object", since that's all we need to know for
creation purposes.) The code we use here looks asymmetric since it searches
|py| ahead of |px|, but in fact the two sides can't both contain a relation
without throwing a problem message (e.g., "In the trunk is on the table."),
so the code here is completely symmetrical in |px| and |py|.

Containment is a slight exception because, for reasons to do with the
ambiguity between direct and indirect containment, it does not force the
kind of its second term. So we do so on its behalf.

The other way to find the kinds is to look at what the two sides explicitly say:

>> Green is a colour.

@<Work out the kinds of value expressed by each side, and find their governing nodes@> =
	binary_predicate *bp = Assertions::Creator::bp_of_subtree(py);
	if (bp == NULL) bp = Assertions::Creator::bp_of_subtree(px);
	if (bp) {
		kindx = Kinds::weaken(BinaryPredicates::term_kind(bp, 0), K_object);
		kindy = Kinds::weaken(BinaryPredicates::term_kind(bp, 1), K_object);
		#ifdef IF_MODULE
		if ((bp == R_containment) ||
			(BinaryPredicates::get_reversal(bp) == R_containment)) { kindx = K_object; kindy = K_object; }
		#endif
	}
	if ((kindx == NULL) || (kindy == NULL)) {
		kindx = Assertions::Creator::kind_of_subtree(px, &govx);
		kindy = Assertions::Creator::kind_of_subtree(py, &govy);
	}

@ So that just leaves the algorithms for finding the relation of a subtree:

=
binary_predicate *Assertions::Creator::bp_of_subtree(parse_node *p) {
	if ((p) && (Node::get_type(p) == RELATIONSHIP_NT)) return Node::get_relationship(p);
	return NULL;
}

@ And the kind of a subtree.

=
kind *Assertions::Creator::kind_of_subtree(parse_node *p, parse_node **governing) {
	if (p == NULL) return NULL;
	switch (Node::get_type(p)) {
		case AND_NT: @<Recurse downwards, preferring the leftmost item in a list@>;
		case WITH_NT: return Assertions::Creator::kind_of_subtree(p->down, governing); /* the owner, not the property */
		case KIND_NT: @<Handle the kind of a "kind of..." clause@>;
		default: {
			parse_node *spec = Node::get_evaluation(p);
			@<Kinds of variable and of value produce the obvious kind as result@>;
			@<Initially values produce their own weakened kind@>;
			@<Descriptions produce the kind of whatever's described@>;
			@<Property names coinciding with kinds are considered with their kind meanings@>;
		}
	}
	return NULL;
}

@<Recurse downwards, preferring the leftmost item in a list@> =
	kind *left = Assertions::Creator::kind_of_subtree(p->down, governing);
	kind *right = Assertions::Creator::kind_of_subtree(p->down->next, governing);
	if (left) return left;
	return right;

@ Refinement has already parsed a KIND subtree and left the resulting domain
in the node's subject, so this case is easy.

@<Handle the kind of a "kind of..." clause@> =
	*governing = p;
	return KindSubjects::to_kind(Node::get_subject(p));

@ Less surprisingly, "number that varies" and "number" return |K_number|.

@<Kinds of variable and of value produce the obvious kind as result@> =
	if ((Specifications::is_new_variable_like(spec)) ||
		(Specifications::is_kind_like(spec))) {
		kind *found = Specifications::to_kind(spec);
		if (Specifications::is_new_variable_like(spec))
			found = K_value; /* Specifications::kind_of_new_variable_like(spec); */
		else if (Specifications::is_kind_like(spec)) found = Specifications::to_kind(spec);
		if (found) {
			*governing = p;
			if (Kinds::Behaviour::is_object(found)) return K_object;
		}
		return found;
	}

@<Initially values produce their own weakened kind@> =
	if ((prevailing_mood == INITIALLY_CE) || (prevailing_mood == CERTAIN_CE)) {
		if ((Node::is(spec, CONSTANT_NT)) ||
			(Lvalues::is_constant_NONLOCAL_VARIABLE(spec))) {
			*governing = p;
			return Kinds::weaken(Specifications::to_kind(spec), K_object);
		}
	}

@<Property names coinciding with kinds are considered with their kind meanings@> =
	if (Rvalues::is_CONSTANT_construction(spec, CON_property)) {
		property *prn = Rvalues::to_property(spec);
		if ((Properties::is_either_or(prn) == FALSE) &&
			(ValueProperties::coincides_with_kind(prn)))
			return ValueProperties::kind(prn);
	}


@ And similarly "even number" returns |K_number|.

@<Descriptions produce the kind of whatever's described@> =
	if (Specifications::is_description(spec)) {
		*governing = p;
		return Specifications::to_kind(spec);
	}

@h Acting on creations.
Building and refining the parse tree was a compositional process, in a linguistic
sense: what you do at any given position depends only on the current phrase and
its contents, or equivalently, on the current node and its children.

The creator is not compositional. What it does to the phrase "Miss Bianca",
words with no meaning as yet, depends on the rest of the sentence, as these
two alternatives show:

>> [1] Miss Bianca is an animal. [2] Miss Bianca is a number that varies.

Nevertheless, the code has been structured to minimise the extent to which
information moves across the tree rather than upwards. When |Assertions::Creator::noun_creator|
is applied to a given node, it is allowed access to that node and all its
children, and can otherwise see only two pieces of information: the kind
for any creation ("animal" or "number", above) and, in some cases, also
a reference to which node in the tree determined this -- the "governor".

We recurse downwards, looking only for |CALLED_NT| and |CREATED_NT| nodes,
both of which are excised and replaced with |COMMON_NOUN_NT| or
|PROPER_NOUN_NT| nodes as appropriate.

=
table *allow_tabular_definitions_from = NULL;
void Assertions::Creator::tabular_definitions(table *t) {
	allow_tabular_definitions_from = t;
}

void Assertions::Creator::noun_creator(parse_node *p, kind *create_as, parse_node *governor) {
	switch (Node::get_type(p)) {
		case CALLED_NT: @<Check we are sure about this@>; @<Perform creation on a CALLED node@>; return;
		case CREATED_NT: @<Check we are sure about this@>; @<Perform creation on a CREATED node@>; return;
	}
	parse_node *ch;
	for (ch = p->down; ch; ch = ch->next) Assertions::Creator::noun_creator(ch, create_as, governor);
}

@<Check we are sure about this@> =
	if ((prevailing_mood == IMPOSSIBLE_CE) || (prevailing_mood == UNLIKELY_CE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NegativeCreation),
			"sentences are only allowed to say that things do exist",
			"not that they don't.");
	}

@ CALLED nodes allow a much more generous range of names to be used -- that's
the whole point of them. Really they contain the whole language in miniature,
because a "called" clause can specify not only the name but also its kind,
some properties which it has, and so forth. For example:

>> There is a recurring scene called Expedited Banana Shipment.

Thus the CALLED subtree sometimes has "local" information about what to
make which overrides any information coming down from the tree above. This
is important for sentences like:

>> A man called Peter is in the Dining Room.

The tree above mandates that a creation in "A man called Peter" has to be
an object, but we know locally that Peter must further have the kind "man".

@<Perform creation on a CALLED node@> =
	parse_node *what_to_make_node = p->down; /* e.g., "a man" */
	parse_node *called_name_node = p->down->next; /* a |CREATED_NT| node, e.g., "Peter" */

	if ((Node::get_type(what_to_make_node) != COMMON_NOUN_NT) &&
		(Node::get_type(what_to_make_node) != WITH_NT)) {
		@<Complain that nothing else can be called@>; return;
	}

	parse_node *local_governor = NULL;
	kind *local_create_as = Assertions::Creator::kind_of_subtree(what_to_make_node, &local_governor);
	if (local_create_as == NULL) { local_create_as = create_as; local_governor = governor; }
	Assertions::Creator::noun_creator(called_name_node, local_create_as, local_governor);

	@<Replace the CALLED subtree with the new creation, mutatis mutandis@>;
	@<If the CALLED name used the definite article, make a note of that@>;

@ This is where we act on the miniature sentence implied by the CALLED
subtree. We replace the subtree with a single node -- the result of creation
on the |called_name_node| side -- but then apply to it any kind, proposition
or adjectives specified in the |what_to_make_node| side.

@<Replace the CALLED subtree with the new creation, mutatis mutandis@> =
	parse_node *p_sibling = p->next;
	Node::copy(p, called_name_node); p->down = NULL; p->next = p_sibling;

	inference_subject *new_creation = Node::get_subject(p);
	inference_subject *its_domain = Node::get_subject(what_to_make_node);

	if ((new_creation) && (its_domain))
		Propositions::Abstract::assert_kind_of_subject(new_creation, its_domain,
			Specifications::to_proposition(Node::get_evaluation(what_to_make_node)));

	if (Node::get_type(what_to_make_node) == WITH_NT)
		Assertions::PropertyKnowledge::assert_property_list(p, what_to_make_node->down->next);

@ Ordinarily the use of the definite article doesn't tell us much, but
consider the following two sentences:

>> There is a man called the Assessor. There is a man called Eric Eve.

Clearly "Eric Eve" is a proper name, but "Assessor" is not; the use of
"the" here was significant. (We only allow proper names for objects, which
is why the following only applies to those.)

@<If the CALLED name used the definite article, make a note of that@> =
	#ifdef IF_MODULE
	if ((Node::get_type(called_name_node) == PROPER_NOUN_NT) &&
		(Articles::may_be_definite(Node::get_article(called_name_node)))) {
		inference_subject *subj = Node::get_subject(p);
		if ((InferenceSubjects::is_an_object(subj)) ||
			(InferenceSubjects::is_a_kind_of_object(subj)))
			Naming::object_takes_definite_article(subj);
	}
	#endif

@ Note that even in this problem case, the |CALLED_NT| node is removed. It
disappears from the tree entirely when the creator has finished work.

@<Complain that nothing else can be called@> =
	LOG("$T\n", what_to_make_node);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_CalledWithoutKind),
		"I can only make 'a something called whatever' when the something is a kind I know",
		"possibly qualified with adjectives. For instance, 'an open door called the Marble "
		"Door' is fine because 'door' is the name of a kind and 'open' is an adjective "
		"which means something for doors. But 'a grand archway called the Great Gates' "
		"would not normally mean anything to me, because 'archway' is not one of the "
		"standard kinds in Inform. (Try consulting the Kinds index.)");
	/* now recover from the error as best we can: */
	Node::set_type(p, CREATED_NT);
	Node::set_text(p, Node::get_text(called_name_node));
	p->down = NULL;

@ Names are not permitted to contain brackets, but we do allow them as an indicator
of grammatical gender for languages other than English.

=
<grammatical-gender-marker> ::=
	... ( <grammatical-gender-abbreviation> )  ==> { pass 1 }

<grammatical-gender-abbreviation> ::=
	n |
	m |
	f

@ That's it for callings; on to the main case, where we have a |CREATED_NT|
node which invites us to make something of it. In every case it becomes one
of |COMMON_NOUN_NT| (e.g., "Colour is a kind of value"); or |PROPER_NOUN_NT|
(e.g., "Miss Bianca is an animal"). Thus every |CREATED_NT| node disappears
from the tree.

@<Perform creation on a CREATED node@> =
	wording W = Node::get_text(p);
	if (Wordings::empty(W)) internal_error("CREATED node without name");
	if (<grammatical-gender-marker>(W)) {
		W = GET_RW(<grammatical-gender-marker>, 1);
		Annotations::write_int(p, explicit_gender_marker_ANNOT, <<r>> + 1);
	}
	if (<creation-problem-diagnosis>(W)) W = EMPTY_WORDING;
	Node::set_text(p, W);
	if (((create_as == NULL) || (Kinds::Behaviour::is_object(create_as))) &&
		(prevailing_mood != INITIALLY_CE) &&
		(prevailing_mood != CERTAIN_CE)) {
		instance *recent_creation = NULL;
		if (Wordings::nonempty(W)) @<Create an object or kind of object rather than a value@>;
		if (recent_creation) {
			Refiner::give_subject_to_noun(p, Instances::as_subject(recent_creation));
			Annotations::write_int(p, creation_site_ANNOT, TRUE);
		}
	} else {
		parse_node *val = NULL;
		if (Wordings::nonempty(W)) @<Create a value rather than an object@>;
		Refiner::give_spec_to_noun(p, val);
		if (val) Annotations::write_int(p, creation_site_ANNOT, TRUE);
	}

@ There now follows a pretty tedious trawl through reasons to object to names.
The crash hieroglyphs exist only so that the Inform test suite can verify that
it handles crashes correctly.

=
<creation-problem-diagnosis> ::=
	<article> |    ==> @<Issue PM_NameIsArticle problem@>
	(/)/(- *** |    ==> @<Issue PM_NameWithBrackets problem@>
	*** (/)/(- |    ==> @<Issue PM_NameWithBrackets problem@>
	... (/)/(- ... |    ==> @<Issue PM_NameWithBrackets problem@>
	ni--crash--1 |    ==> @<Issue PM_Crash1 problem@>
	ni--crash--10 |    ==> @<Issue PM_Crash10 problem@>
	ni--crash--11 |    ==> @<Issue PM_Crash11 problem@>
	, ... |    ==> @<Issue PM_StartsWithComma problem@>
	... , |    ==> @<Issue PM_EndsWithComma problem@>
	... when/while ... |    ==> @<Issue PM_ObjectIncWhen problem@>
	*** <quoted-text> *** |    ==> @<Issue PM_NameWithText problem@>
	condition |    ==> @<Issue PM_NameReserved problem@>
	conditions |    ==> @<Issue PM_NameReserved problem@>
	storage |    ==> @<Issue PM_NameReserved problem@>
	storages |    ==> @<Issue PM_NameReserved problem@>
	variable |    ==> @<Issue PM_NameReserved problem@>
	variables |    ==> @<Issue PM_NameReserved problem@>
	property-value |    ==> @<Issue PM_NameReserved problem@>
	property-values |    ==> @<Issue PM_NameReserved problem@>
	table-reference |    ==> @<Issue PM_NameReserved problem@>
	table-references |    ==> @<Issue PM_NameReserved problem@>
	list-entry |    ==> @<Issue PM_NameReserved problem@>
	list-entries							==> @<Issue PM_NameReserved problem@>

@<Issue PM_NameIsArticle problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NameIsArticle),
		"this seems to give something a name which consists only of an article",
		"that is, 'a', 'an', 'the' or 'some'. This is not allowed since the "
		"potential for confusion is too high. (If you need, say, a room which "
		"the player sees as just 'A', you can get this effect with: 'A-Room is "
		"a room with printed name \"A\".')");

@<Issue PM_NameWithBrackets problem@> =
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NameWithBrackets),
			"this seems to give something a name which contains brackets '(' or ')'",
			"which is not allowed since the potential for confusion with other uses "
			"for brackets in Inform source text is too high. (If you need, say, a "
			"room which the player sees as 'Fillmore (West)', you can get this "
			"effect with: 'Fillmore West is a room with printed name \"Fillmore "
			"(West)\".')");

@<Issue PM_Crash1 problem@> =
	WRITE_TO(STDERR, "*** Exit(1) requested for testing purposes ***\n");
	STREAM_FLUSH(STDERR);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_Crash1),
		"this uses the first secret hieroglyph of dreadful power",
		"which forces me to crash. (It's for testing the way I crash, in fact. "
		"If this is a genuine inconvenience to you, get in touch with my authors.)");
	ProblemSigils::exit(1);

@<Issue PM_Crash10 problem@> =
	WRITE_TO(STDERR, "*** Exit(10) requested for testing purposes ***\n");
	STREAM_FLUSH(STDERR);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_Crash10),
		"this uses the second secret hieroglyph of dreadful power",
		"which forces me to crash. (It's for testing the way I crash, in fact. "
		"If this is a genuine inconvenience to you, get in touch with my authors.)");
	ProblemSigils::exit(10);

@<Issue PM_Crash11 problem@> =
	WRITE_TO(STDERR, "*** Exit(11) requested for testing purposes ***\n");
	STREAM_FLUSH(STDERR);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_Crash11),
		"this uses the third secret hieroglyph of dreadful power",
		"which forces me to crash. (It's for testing the way I crash, in fact. "
		"If this is a genuine inconvenience to you, get in touch with my authors.)");
	ProblemSigils::exit(11);

@<Issue PM_StartsWithComma problem@> =
	LOG("$T\n", current_sentence);
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_StartsWithComma),
		"this seems to refer to something whose name begins with a comma",
		"which is forbidden. Perhaps you used a comma in punctuating a sentence? "
		"Inform generally doesn't like this because it reserves commas for "
		"specific purposes such as dividing rules or 'if' phrases.");

@<Issue PM_EndsWithComma problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EndsWithComma),
		"this seems to refer to something whose name ends with a comma",
		"which is forbidden. Perhaps you used a comma in punctuating a sentence? "
		"Inform generally doesn't like this because it reserves commas for "
		"specific purposes such as dividing rules or 'if' phrases.");

@<Issue PM_ObjectIncWhen problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ObjectIncWhen));
	Problems::issue_problem_segment(
		"The sentence %1 seems to be talking about a previously unknown room or "
		"thing called %2. Ordinarily, I would create this, but because the name "
		"contains the word 'when' or 'while' I'm going to say no. %P"
		"That's because this far more often happens by mistake than deliberately. "
		"For instance, people sometimes type lines like 'Jumping when the actor "
		"is on the trampoline is high-jumping.' But in fact although 'jumping' "
		"is an action, 'Jumping when...' is not - 'when' can't be used here "
		"(though it can be used in rule preambles). So the sentence is instead "
		"read as making an object 'jumping when the actor' and putting it on top "
		"of another one, 'trampoline is high-jumping'. This can lead to a lot of "
		"confusion. %P"
		"If you genuinely do want an object whose name contains the word 'when', "
		"try something like: 'In the box is a thing called When worlds collide.'");
	Problems::issue_problem_end();

@<Issue PM_NameWithText problem@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_NameWithText),
		"this seems to give something a name which contains "
		"double-quoted text",
		"which is not allowed. If you do need quotes in a name, one option "
		"would be to write something like 'In the Saloon is 'Black' Jacques "
		"Bernoulli.'; but this problem message is often caused by an "
		"accident in punctuation, in which case you never intended to "
		"create an object - you thought that the text ended a sentence "
		"because it finished with sentence-ending punctuation, when in "
		"fact it didn't, so that I read the next words as following on.");

@<Issue PM_NameReserved problem@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_NameReserved),
		"this seems to give something a name which is reserved for Inform's "
		"own internal use",
		"so is not allowed. There are only a few of these - 'storage', "
		"'variable', 'condition', 'phrase' and 'action', for example. But "
		"whatever you were making here, you'll need to call it something "
		"else.");

@ At this point we do something that might look odd: we check to see if the
text of the |CREATED_NT| node is the name of an object already. That seems
pointless, since |CREATED_NT| nodes are only made when a name is meaningless.
But that was a little while ago, before we started to make creations within
the current sentence.

This all hangs on the interpretation of sentences like so:

>> Malcolm believes Malcolm.

which make the first mentions of "Malcolm". These are both |CREATED_NT|
nodes; the first causes "Malcolm" to be created; and then, when we reach
the second one, we find that |recent_creation| points to it, so we do not
need to make a second creation. The two Malcolms are, in fact, references
to the same object.

We do insist, however, on the names being given in exactly the same form.

>> Malcolm X believes Malcolm.

creates two different objects with different names, even though references
to abbreviated forms of object names are normally allowed.

@<Create an object or kind of object rather than a value@> =
	recent_creation = NULL;
	if (<instance-of-object>(W)) {
		recent_creation = <<rp>>;
		wording RW = Instances::get_name(recent_creation, FALSE);
		if ((Wordings::nonempty(RW)) && (Wordings::match(W, RW) == FALSE))
			recent_creation = NULL;
	}

	if (recent_creation == NULL) @<Actually create a fresh object@>;

@<Actually create a fresh object@> =
	int is_a_kind = FALSE;
	if ((governor) && (Node::get_type(governor) == KIND_NT)) is_a_kind = TRUE;

	pcalc_prop *prop = Propositions::Abstract::to_create_something(K_object, W);
	if (is_a_kind)
		prop = Propositions::concatenate(prop, Propositions::Abstract::to_make_a_kind(K_object));
	Assert::true(prop, CERTAIN_CE);

	if (is_a_kind == FALSE) {
		recent_creation = Instances::latest();
		article_usage *au = Node::get_article(p);
		#ifdef IF_MODULE
		if (au == NULL)
			Naming::object_now_has_proper_name(recent_creation);
		else if (Stock::usage_might_be_singular(au->usage) == FALSE)
			Naming::object_now_has_plural_name(recent_creation);
		#endif
		int g = 0, gender_certainty = UNKNOWN_CE;
		if (au) {
			g = Lcon::get_gender(Stock::first_form_in_usage(au->usage));
			gender_certainty = LIKELY_CE;
		}
		if (Annotations::read_int(p, explicit_gender_marker_ANNOT) != 0) {
			g = Annotations::read_int(p, explicit_gender_marker_ANNOT);
			gender_certainty = CERTAIN_CE;
		}
		if ((g != 0) && (P_grammatical_gender)) {
			instance *GI = Instances::grammatical(g);
			if (GI)
				ValueProperties::assert(P_grammatical_gender,
					Instances::as_subject(recent_creation),
					Rvalues::from_instance(GI),
					gender_certainty);
		}
	} else {
		parse_node *val = Specifications::from_kind(latest_base_kind_of_value);
		Refiner::give_spec_to_noun(p, val);
		Annotations::write_int(p, creation_site_ANNOT, TRUE);
	}

@ Something of a rag-bag, this: it's everything else that can be created.

@<Create a value rather than an object@> =
	parse_node *governing_spec = Node::get_evaluation(governor);
	if ((governor) && (Node::get_type(governor) == KIND_NT))
		@<Create a new kind of value@>
	else if ((Specifications::is_new_variable_like(governing_spec)) ||
		(prevailing_mood == INITIALLY_CE) ||
		(prevailing_mood == CERTAIN_CE))
		@<Create a new variable@>
	else if (Kinds::get_construct(create_as) == CON_rulebook)
		@<Create a new rulebook@>
	else if (Kinds::get_construct(create_as) == CON_activity)
		@<Create a new activity@>
	else if ((Kinds::Behaviour::definite(create_as)) && (Kinds::Behaviour::is_quasinumerical(create_as)))
		@<Issue a problem for trying to create an instance of a unit@>
	else if ((Kinds::Behaviour::definite(create_as)) &&
		(RTKinds::defined_by_table(create_as)) &&
		(RTKinds::defined_by_table(create_as) != allow_tabular_definitions_from))
		@<Issue a problem for trying to create an instance of a table-defined kind@>
	else if ((Kinds::Behaviour::definite(create_as)) && (Kinds::Behaviour::has_named_constant_values(create_as)))
		@<Create an instance of an enumerated kind@>
	else
		@<Issue an unable-to-create problem message@>;
	Index::DocReferences::position_of_symbol(&W);
	Node::set_text(p, W);

@<Create a new kind of value@> =
	pcalc_prop *prop = Propositions::Abstract::to_create_something(NULL, W);
	prop = Propositions::concatenate(prop, Propositions::Abstract::to_make_a_kind(K_value));
	Assert::true(prop, prevailing_mood);
	val = Specifications::from_kind(latest_base_kind_of_value);

@<Create a new variable@> =
	kind *domain = Node::get_kind_of_value(governing_spec);
	if (domain == NULL)
		domain = Kinds::weaken(Specifications::to_kind(governing_spec), K_object);
	if (Specifications::is_new_variable_like(governing_spec))
		domain = Specifications::kind_of_new_variable_like(governing_spec);
	if ((K_understanding) && (Kinds::contains(domain, Kinds::get_construct(K_understanding))))
		@<Issue a problem for topics that vary@>;
	pcalc_prop *prop = Propositions::Abstract::to_create_something(domain, W);
	if (prevailing_mood == CERTAIN_CE)
		prop = Propositions::concatenate(prop, Propositions::Abstract::to_make_a_const());
	else
		prop = Propositions::concatenate(prop, Propositions::Abstract::to_make_a_var());
	Assert::true(prop, prevailing_mood);
	if (NonlocalVariables::get_latest() == NULL) internal_error("failed to create");
	val = Lvalues::new_actual_NONLOCAL_VARIABLE(NonlocalVariables::get_latest());

@<Create an instance of an enumerated kind@> =
	pcalc_prop *prop = Propositions::Abstract::to_create_something(create_as, W);
	pcalc_prop *such_that = Node::get_creation_proposition(governor);
	if (such_that) prop = Propositions::concatenate(prop, such_that);
	Assert::true(prop, prevailing_mood);
	val = Rvalues::from_instance(Instances::latest());

@ Lastly: rulebooks and activities are not part of the model, because they would
make it enormously larger, and because they describe only the run-time evolution
of the state of play and have no effect on the initial state. So we don't create
them by asserting propositions to be true; we act directly.

@<Create a new rulebook@> =
	kind *basis = NULL, *producing = NULL;
	Kinds::binary_construction_material(create_as, &basis, &producing);
	if (Kinds::eq(basis, K_value)) basis = K_action_name;
	if (Kinds::eq(producing, K_value)) producing = K_void;
	create_as = Kinds::binary_con(CON_rulebook, basis, producing);
	if (governor)
		Node::set_evaluation(governor,
			Specifications::from_kind(create_as));
	package_request *P = Hierarchy::local_package(RULEBOOKS_HAP);
	rulebook *rb = Rulebooks::new(create_as, W, P);

	val = Rvalues::from_rulebook(rb);
	Annotations::write_int(current_sentence, clears_pronouns_ANNOT, TRUE);

@<Create a new activity@> =
	activity *av = Activities::new(create_as, W);
	val = Rvalues::from_activity(av);
	Annotations::write_int(current_sentence, clears_pronouns_ANNOT, TRUE);

@ And to wind up, sundry problem messages.

@<Issue a problem for topics that vary@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_NoTopicsThatVary),
		"'topics that vary' are not allowed",
		"that is, a variable is not allowed to have 'topic' as its kind of value. "
		"(This would cause too much ambiguity with text variables, whose values "
		"look exactly the same.)");

@<Issue a problem for trying to create an instance of a unit@> =
	if (<equation-name>(W)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_kind(3, create_as);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_MixedConstantsEquation));
		Problems::issue_problem_segment(
			"The sentence %1 reads to me as if '%2' refers to something "
			"I should create as brand new - %3. But that can't be right, "
			"and I suspect this may be because you've tried to create an "
			"Equation but not given it a new paragraph.");
		Problems::issue_problem_end();
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_kind(3, create_as);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_MixedConstants));
		Problems::issue_problem_segment(
			"The sentence %1 reads to me as if '%2' refers to something "
			"I should create as brand new - %3. But that can't be right, "
			"because this is a kind of value where I can't simply invent "
			"new values. (Just as the numbers are ..., 1, 2, 3, ... and "
			"I can't invent a new one called 'Susan'.)");
		Problems::issue_problem_end();
	}

@<Issue a problem for trying to create an instance of a table-defined kind@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	Problems::quote_kind(3, create_as);
	Problems::quote_table(4, RTKinds::defined_by_table(create_as));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TableOfExistingKind2));
		Problems::issue_problem_segment(
			"The sentence %1 reads to me as if '%2' refers to something "
			"I should create as brand new - %3. That looks reasonable, since "
			"this is a kind which does have named values, but it's not "
			"allowed because this is a kind which is defined by the rows "
			"of a table (%4), not in isolated sentences like this one.");
	Problems::issue_problem_end();

@ This is often a problem already reported, so we issue a fresh message only
if nothing has already been said:

@<Issue an unable-to-create problem message@> =
	if (problem_count_when_creator_started == problem_count) {
		LOG("%W: %u\n$T\n", W, create_as, current_sentence);
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_kind(3, create_as);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_NoNewInstances));
		Problems::issue_problem_segment(
			"The sentence %1 reads to me as if '%2' refers to something "
			"I should create as brand new - %3. But that can't be right, "
			"because this is a kind of value where I can't simply invent "
			"new values. (Just as the numbers are ..., 1, 2, 3, ... and "
			"I can't invent a new one called 'Susan'.) %P"
			"Perhaps you wanted not to invent a constant but to make a "
			"variable - that is, to give a name for a value which will "
			"change during play. If so, try something like 'The bonus "
			"is a number which varies'. %P"
			"Or perhaps you wanted to create a name as an alias for a "
			"constant value. If so, try something like 'The lucky number "
			"is always 8.' But this only makes a new name for the existing "
			"number 8, it doesn't invent a new number.");
		Problems::issue_problem_end();
	}

@ It turns out to be useful to have the same policing rules elsewhere:

=
int Assertions::Creator::vet_name(wording W) {
	if (<creation-problem-diagnosis>(W)) return FALSE;
	return TRUE;
}

@h Creations to instantiate.
The |COMMON_NOUN_NT| node sometimes means to talk about things in general,
sometimes things in particular; consider the two sentences

>> A container is usually open. A container is in the Box Room.

We cannot easily differentiate these meanings. We will only be able to do so
by looking carefully at what the assertion does; studying the two sides of the
tree separately won't be good enough. So instantiation is done only at a few
points in "Make Assertions", and not as part of the process above.

Instantiation only ever creates objects, since values aren't allowed to be
nameless.

So: when it turns out that the |COMMON_NOUN_NT| is to be made into something nameless
but tangible, as in the second sentence above, the following routine is used
to transform it into a suitable |PROPER_NOUN_NT| referring to the newly created
object.

=
int name_stubs_count = 0;

void Assertions::Creator::convert_instance_to_nounphrase(parse_node *p, binary_predicate *hinge_relation) {
	@<Check we are sure about this@>;
	int confect_name_flag = FALSE;
	if ((hinge_relation) && (BinaryPredicates::is_the_wrong_way_round(hinge_relation)))
		hinge_relation = BinaryPredicates::get_reversal(hinge_relation);
	#ifdef IF_MODULE
	if (hinge_relation == R_incorporation) confect_name_flag = TRUE;
	#endif
	int instance_count;
	wording CW = EMPTY_WORDING; /* the calling */
	if (<text-ending-with-a-calling>(Node::get_text(p))) {
		Node::set_text(p, GET_RW(<text-ending-with-a-calling>, 1)); /* the text before the bracketed clause */
		CW = GET_RW(<text-ending-with-a-calling>, 2); /* the bracketed text */
		if (<article>(CW)) {
			@<Issue a problem for calling something an article@>;
			CW = EMPTY_WORDING;
		}
	}
	kind *instance_kind = K_object;
	if (Specifications::is_kind_like(Node::get_evaluation(p)))
		instance_kind = Specifications::to_kind(Node::get_evaluation(p));
	if ((Kinds::Behaviour::is_object(instance_kind) == FALSE) &&
		(Kinds::Behaviour::has_named_constant_values(instance_kind) == FALSE))
		@<Point out that it's impossible to create values implicitly for this kind@>;
	@<Calculate the instance count, that is, the number of duplicates to be made@>;
	parse_node *list_subtree = Node::new(COMMON_NOUN_NT);
	parse_node *original_next = p->next;
	@<Construct a list subtree containing the right number of duplicates@>;
	Node::copy(p, list_subtree);
	p->next = original_next;
}

@<Point out that it's impossible to create values implicitly for this kind@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, instance_kind);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantCreateImplicitly));
	Problems::issue_problem_segment(
		"The sentence %1 seems to be asking me to create a new value (%2) "
		"in order to be part of a relationship, but this isn't a kind of "
		"value which I can just create new values for.");
	Problems::issue_problem_end();
	instance_kind = K_object;
	Annotations::write_int(p, multiplicity_ANNOT, 1);

@<Issue a problem for calling something an article@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, CW);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CalledArticle));
	Problems::issue_problem_segment(
		"The sentence %1 seems to be asking me to create something whose "
		"name, '%2', is just an article - this isn't allowed.");
	Problems::issue_problem_end();

@ Usually the instance count is 1, but noun phrases such as "six vehicles"
will raise it. The problem message here is almost a bit of social engineering:
we just don't think you're implementing it right if you think you need more
than 100 duplicate objects in one go. (Though it is true what the problem
message says about performance, too.)

@d MAX_DUPLICATES_AT_ONCE 100 /* change the problem message below if this is changed */

@<Calculate the instance count, that is, the number of duplicates to be made@> =
	instance_count = Annotations::read_int(p, multiplicity_ANNOT);
	if (instance_count < 1) instance_count = 1;
	if (instance_count > MAX_DUPLICATES_AT_ONCE) {
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_TooManyDuplicates),
			"at most 100 duplicates can be made at any one time",
			"so '157 chairs are in the UN General Assembly' will not be allowed. The "
			"system for handling duplicates during play becomes too slow and awkward "
			"when there are so many.");
		instance_count = MAX_DUPLICATES_AT_ONCE;
	}

@ For instance, "six vehicles" would make a binary tree here in which the
intermediate nodes are |AND_NT| and the leaves |PROPER_NOUN_NT|, each referring
to a different vehicle object.

@<Construct a list subtree containing the right number of duplicates@> =
	parse_node *attach_to = list_subtree;
	int i;
	for (i=1; i<=instance_count; i++) {
		inference_subject *new_instance = NULL;
		@<Fashion a new object matching the description in the COMMON NOUN node@>;
		if (i < instance_count) {
			Node::set_type_and_clear_annotations(attach_to, AND_NT);
			attach_to->down = Node::new(PROPER_NOUN_NT);
			Refiner::give_subject_to_noun(attach_to->down, new_instance);
			Annotations::write_int(attach_to->down, creation_site_ANNOT, TRUE);
			attach_to->down->next = Node::new(PROPER_NOUN_NT);
			attach_to = attach_to->down->next;
		} else {
			Refiner::give_subject_to_noun(attach_to, new_instance);
			Annotations::write_int(attach_to, creation_site_ANNOT, TRUE);
		}
	}

@<Fashion a new object matching the description in the COMMON NOUN node@> =
	inference_subject *named_after = NULL;
	wording NW = EMPTY_WORDING, NAW = EMPTY_WORDING;
	int propriety = FALSE;
	@<Confect a name for the new object, if that's the bag we're into@>;
	if (Kinds::Behaviour::is_object(instance_kind) == FALSE)
		@<Check that the new name is non-empty and distinct from all existing ones@>;
	NW = Wordings::truncate(NW, 32); /* truncate to the maximum length */
	parse_node *pz = Node::new(PROPER_NOUN_NT);
	pcalc_prop *prop = Propositions::Abstract::to_create_something(instance_kind, NW);
	Assert::true(prop, prevailing_mood);
	new_instance = Instances::as_subject(Instances::latest());
	if (named_after) {
		#ifdef IF_MODULE
		Naming::transfer_details(named_after, new_instance);
		#endif
		Assertions::Assemblies::name_object_after(new_instance, named_after, NAW);
		if ((InferenceSubjects::is_an_object(named_after) == FALSE) &&
			(InferenceSubjects::is_a_kind_of_object(named_after) == FALSE)) propriety = TRUE;
	}
	#ifdef IF_MODULE
	if (propriety) Naming::now_has_proper_name(new_instance);
	#endif
	Refiner::give_subject_to_noun(pz, new_instance);
	Annotations::write_int(pz, creation_site_ANNOT, TRUE);
	Assertions::make_coupling(pz, p);

@ The following is used only in assemblies, where the instance count is always
1, and confects a name like "Cleopatra's nose" from an owner object, "Cleopatra",
and an |COMMON_NOUN_NT| node, "nose".

@<Confect a name for the new object, if that's the bag we're into@> =
	inference_subject *owner = Node::get_implicit_in_creation_of(current_sentence);
	if ((owner) && (instance_count == 1) &&
		((confect_name_flag) ||
		(Kinds::Behaviour::is_object(instance_kind) == FALSE) || (Wordings::nonempty(CW)))) {
		wording OW = InferenceSubjects::get_name_text(owner);

		inference_subject *subject_here = Node::get_subject(p);
		if (subject_here) {
			NW = InferenceSubjects::get_name_text(subject_here);
		}
		if ((Wordings::nonempty(OW)) && (Wordings::nonempty(NW)) && (Wordings::empty(CW))) {
			feed_t id = Feeds::begin();
			Feeds::feed_C_string_expanding_strings(L" its ");
			Feeds::feed_wording(NW);
			CW = Feeds::end(id);
		}
		if (Wordings::nonempty(CW)) {
			named_after = owner;
			NAW = NW;
			feed_t id = Feeds::begin();
			LOOP_THROUGH_WORDING(j, CW) {
				if (<possessive-third-person>(Wordings::one_word(j)))
					@<Insert the appropriate possessive@>
				else if (<agent-pronoun>(Wordings::one_word(j)))
					@<Insert the appropriate name@>
				else Feeds::feed_wording(Wordings::one_word(j));
			}
			NW = Feeds::end(id);
			LOGIF(NOUN_RESOLUTION, "Confecting the name: <%W>\n", NW);
		} else {
			NW = EMPTY_WORDING;
		}
	}

@<Insert the appropriate possessive@> =
	TEMPORARY_TEXT(genitive_form)
	if (PluginCalls::irregular_genitive(owner, genitive_form, &propriety) == FALSE) {
		if (Wordings::nonempty(OW)) {
			if (Wordings::length(OW) > 1)
				Feeds::feed_wording(Wordings::trim_last_word(OW));
			WRITE_TO(genitive_form, "%+W's ", Wordings::one_word(Wordings::last_wn(OW)));
		}
	}
	Feeds::feed_text_expanding_strings(genitive_form);
	DISCARD_TEXT(genitive_form)

@<Insert the appropriate name@> =
	Feeds::feed_wording(OW);

@<Check that the new name is non-empty and distinct from all existing ones@> =
	wording SW = EMPTY_WORDING;
	if (Wordings::empty(NW))
		SW = InferenceSubjects::get_name_text(KindSubjects::from_kind(instance_kind));
	else if (<s-constant-value>(NW)) SW = NW;
	if (Wordings::nonempty(SW)) {
		TEMPORARY_TEXT(textual_count)
		WRITE_TO(textual_count, " %d ", ++name_stubs_count);
		feed_t id = Feeds::begin();
		Feeds::feed_wording(SW);
		Feeds::feed_text_expanding_strings(textual_count);
		NW = Feeds::end(id);
		DISCARD_TEXT(textual_count)
	}

@ This is how callings are parsed, both in assertions and conditions: that is,
names occurring in noun phrases with the shape "blah blah (called the rhubarb
rhubarb)". (For tedious reasons it would be inefficient to parse the second
of these using the first.)

=
<text-ending-with-a-calling> ::=
	... ( called the ... ) |
	... ( called ... )

<text-including-a-calling> ::=
	... ( called ... ) ***

@ Many names are rejected because they clash unfortunately with other things,
or for other high-level reasons, but there are also some basic syntactic
blunders. Most of the time those are caught by the Creator above, but in a few
cases (declaring new figures, for instance) it's possible to get around
the standard checks, and in that case problems are picked up here.

<unfortunate-name> is a stricter test than <unsuitable-name>.
For example, property names can't be unsuitable, but they can be unfortunate.

=
<unsuitable-name> ::=
	<article> |
	*** (/)/{/}/,/./(- *** |
	*** <quoted-text> ***

<unsuitable-name-for-locals> ::=
	<definite-article> |
	*** (/)/{/}/,/. *** |
	*** <quoted-text> ***

<unfortunate-name> ::=
	... with/having/and/or ... |
	<unsuitable-name>

@ Which powers:

=
int Assertions::Creator::vet_name_for_noun(wording W) {
	if (<unfortunate-name>(W)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NameBestAvoided),
			"this is a name which is best avoided",
			"because it would lead to confusion inside Inform. In general, try "
			"to avoid punctuation, quotation marks, or the words 'with' or "
			"'having' in names like this. (Hyphens are fine, so by all means "
			"use a name like 'Church-with-Spire', if that will help.)");
		return FALSE;
	}
	return TRUE;
}

@h The natural language kind.
Inform has a kind built in called "natural language", whose values are
enumerated names: English language, French language, German language and so on.
When the kind is created, the following routine makes these instances. We do
this exactly as we would to create any other instance -- we write a logical
proposition claiming its existence, then assert it to be true.

@d NOTIFY_NATURAL_LANGUAGE_KINDS_CALLBACK Assertions::Creator::stock_nl_kind

=
void Assertions::Creator::stock_nl_kind(kind *K) {
	inform_language *L;
	LOOP_OVER(L, inform_language) {
		pcalc_prop *prop =
			Propositions::Abstract::to_create_something(K, L->instance_name);
		Assert::true(prop, CERTAIN_CE);
		L->nl_instance = Instances::latest();
	}
}
