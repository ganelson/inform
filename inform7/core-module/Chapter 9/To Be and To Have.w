[Assertions::Copular::] To Be and To Have.

To handle sentences with primary verb "to be" or "to have".

@h Definitions.

@ "To Be and To Have" ought to be the name of an incomprehensible
book by Sartre which dismisses Heidegger's seminal "To Have and To Be",
or something like that, but instead it is the name of a section which contains
the most important sentence handler: the one for assertions.

This will turn out to be quite a lot of work, occupying four sections of
code in all. For etymological reasons, the English verb "to be" is a mixture
of several different verbs which have blurred together into one: consider "I
am 5", "I am happy" and "I am Chloe". Even the definition occupies some
12 columns of the "Oxford English Dictionary" and they make interesting
reading in clarifying the problem. Most computer programming languages
implement only |=| and |==|, which correspond to OED's meaning 10, "to exist
as the thing known by a certain name; to be identical with". But Inform
implements a much broader set of meanings. For example, its distinction
between spatial and property knowledge reflects the OED's distinction between
meanings 5a ("to have or occupy a place somewhere") and 9b ("to have a
place among the things distinguished by a specified quality") respectively.

@ Here, and in the sections which follow, we conventionally write |px| and
|py| for the subtrees representing subject and object sides of the verb. Thus

>> The white marble is in the bamboo box.

will result in |px| representing "white marble" and |py| "in the bamboo
box" (not just a leaf, since it will be a tree showing the containment
relationship as well as the noun).

=
sentence_handler ASSERT_SH_handler = { SENTENCE_NT, ASSERT_VB, 0, Assertions::Copular::assertion };

void Assertions::Copular::assertion(parse_node *pv) {
	if (ParseTree::int_annotation(pv->down, possessive_verb_ANNOT))
		Assertions::Copular::to_have(pv);
	else
		Assertions::Copular::to_be(pv);
}

void Assertions::Copular::to_be(parse_node *pv) {
	parse_node *px = pv->down->next;
	parse_node *py = pv->down->next->next;
	if ((Wordings::length(ParseTree::get_text(px)) > 1)
		&& (Vocabulary::test_flags(
			Wordings::first_wn(ParseTree::get_text(px)), TEXT_MC+TEXTWITHSUBS_MC))) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_TextNotClosing),
			"it looks as if perhaps you did not intend that to read as a "
			"single sentence",
			"and possibly the text in quotes was supposed to stand as "
			"as a sentence on its own? (The convention is that if text "
			"ends in a full stop, exclamation or question mark, perhaps "
			"with a close bracket or quotation mark involved as well, then "
			"that punctuation mark also closes the sentence to which the "
			"text belongs: but otherwise the words following the quoted "
			"text are considered part of the same sentence.)");
		return;
	}
	Assertions::Copular::make_assertion(px, py);
}

@ "To have" may seem as if it ought to be an entirely different verb from
"to be", but in fact they have heavily overlapping meanings, and we will
implement them with a great deal of common code. (English is unusual in the
way that "to be" has taken over some of the functions which "to have"
has in other languages -- compare the French "j'ai fatigu\'e", literally
"I have tired" rather than "I am tired", which is arguably more logical
since it talks about the possession of a property.)

On traverse 1 we therefore alter the tree judiciously to convert any use of
"to have" into a use of "to be"; it follows that |Assertions::Copular::to_have| can never be
called in traverse 2, when there are no uses of "to have" left in the tree.

=
void Assertions::Copular::to_have(parse_node *pv) {
	parse_node *px = pv->down->next;
	parse_node *py = pv->down->next->next;

	@<Reject two ungrammatical forms of "to have"@>;

	if (ParseTree::get_type(py) == CALLED_NT)
		@<Handle "X has an A called B"@>
	else if (<k-kind>(ParseTree::get_text(py)))
		@<Handle "X has a V" where V is a kind of value which is also a property@>
	else
		@<Handle "X has P" where P is a list of properties@>;

	ParseTree::annotate_int(pv->down, possessive_verb_ANNOT, FALSE);
	Assertions::Copular::to_be(pv); /* and start again as if it had never been possessive */
}

@<Reject two ungrammatical forms of "to have"@> =
	if (ParseTree::get_type(py) == X_OF_Y_NT) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_SuperfluousOf),
			"the 'of' here appears superfluous",
			"assuming the sentence aims to give a property value of something. "
			"(For instance, if we want to declare the carrying capacity of "
			"something, the normal Inform practice is to say 'The box has "
			"carrying capacity 10' rather than 'The box has a carrying capacity "
			"of 10'.)");
		return;
	}
	if (ParseTree::get_type(py) == WITH_NT) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_SuperfluousWith),
			"the 'has ... with' here appears to be a mixture of two ways to "
			"give something properties",
			"that is, 'The box is a container with capacity 10.' and 'The box "
			"has capacity 10.'");
		return;
	}

@ Here |py| is a |CALLED_NT| subtree for "an A called B", which we relabel
as a |PROPERTYCALLED_NT| subtree and hang beneath an |ALLOWED_NT| node.

@<Handle "X has an A called B"@> =
	if (Wordings::match(ParseTree::get_text(py->down->next), ParseTree::get_text(py->down))) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_SuperfluousCalled),
			"'called' should be used only when the name is different from the kind",
			"so this sentence should be simplified. For example, 'A door has a "
			"colour called colour' should be written more simply as 'A door has "
			"a colour'; but 'called' can be used for something like 'A door has "
			"a number called the street number'.");
		return;
	} else {
		ParseTree::set_type(py, PROPERTYCALLED_NT);
		if (ParseTree::get_type(py->down) == AND_NT) {
			int L = ParseTree::left_edge_of(py->down),
				R = ParseTree::right_edge_of(py->down);
			<nounphrase-articled>(Wordings::new(L, R));
			parse_node *pn = <<rp>>;
			pn->next = py->down->next;
			py->down = pn;
			LOG("Thus $T", py);
		}
		px->next = ParseTree::new(ALLOWED_NT);
		px->next->down = py;
		int prohibited = <prohibited-property-owners>(ParseTree::get_text(px));
		if (!prohibited) {
			<nounphrase-articled-list>(ParseTree::get_text(py->down->next));
			py->down->next = <<rp>>;
		}
	}
	py = px->next;

@ More directly, here we simply relegate |py| by hanging it from a new |ALLOWED_NT|
node. This is for something like

>> A thing has a colour.

where "colour" is the name of both a kind of value and (soon) a property.

@<Handle "X has a V" where V is a kind of value which is also a property@> =
	px->next = ParseTree::new(ALLOWED_NT);
	px->next->down = py;
	py = px->next;

@ And here we just mark |py| as a property list. Typically the sentence would
be "The player has carrying capacity 7."

@<Handle "X has P" where P is a list of properties@> =
	ParseTree::set_type(py, PROPERTY_LIST_NT);

@ In either case, then, we end up going through |Assertions::Copular::to_be| and then to the
following routine, which asserts that subtree |px| "is" |py|.

During traverse 1, this takes place in a three-stage process:

(a) The two subtrees are each individually "refined", which clarifies the
meaning of the noun phrases used in them, and tidies up the tree (see
"Refine Parse Tree").

(b) The Creator is invited to create new objects, variables and so on to
ensure that unrecognised noun phrases are made meaningful (see "The Creator").

(c) In a "there is X" sentence, where |px| is a meaningless placeholder,
we cause X to be created, but otherwise do nothing; otherwise, we call
the massive |Assertions::Maker::make_assertion_recursive| routine (see "Make Assertions").

In traverse 2, only (c) takes place; (a) and (b) are one-time events.

=
void Assertions::Copular::make_assertion(parse_node *px, parse_node *py) {
	if (traverse == 1) {
		int pc = problem_count;
		if (!(<s-existential-np>(ParseTree::get_text(px))))
			Assertions::Refiner::refine(px, ALLOW_CREATION);
		Assertions::Refiner::refine(py, ALLOW_CREATION);
		if (problem_count > pc) return;
		if (Assertions::Creator::consult_the_creator(px, py) == FALSE) return;
	}

	if (trace_sentences) LOG("$T", current_sentence);
	if (<s-existential-np>(ParseTree::get_text(px))) {
		if (traverse == 1) Assertions::Copular::make_existential_assertion(py);
		px = py;
	} else {
		Assertions::Maker::make_assertion_recursive(px, py);
	}
	@<Change the discussion topic for subsequent sentences@>;
}

@ The slight asymmetry in what follows is partly pragmatic, partly the result
of subject-verb inversion ("in the bag is the ball" not "the ball is in the
bag"). We extract a subject from a relationship node on the left, but not on
the right, and we don't extract an object from one. Consider:

>> A billiards table is in the Gazebo. On it is a trophy cup.

What does "it" mean, and why? A human reader goes for the billiards table at
once, because it seems more likely as a supporter than the Gazebo, but that's
not how Inform gets the same answer. It all hangs on "billiards table" being
the object of the first sentence, not the Gazebo; if we descended the RHS,
which is |RELATIONSHIP_NT -> PROPER_NOUN_NT| pointing to the Gazebo, that's the
conclusion we would have reached.

@<Change the discussion topic for subsequent sentences@> =
	inference_subject *infsx = NULL, *infsy = NULL, *infsy_full = NULL;
	infsx = Assertions::Copular::discussed_at_node(px);
	infsy_full = Assertions::Copular::discussed_at_node(py);
	if (ParseTree::get_type(py) != KIND_NT) infsy = ParseTree::get_subject(py);
	Assertions::Traverse::change_discussion_topic(infsx, infsy, infsy_full);
	if (ParseTree::get_type(px) == AND_NT) Assertions::Traverse::subject_of_discussion_a_list();
	if (ParseTree::int_annotation(current_sentence, clears_pronouns_ANNOT))
		Assertions::Traverse::new_discussion();

@ =
inference_subject *Assertions::Copular::discussed_at_node(parse_node *pn) {
	inference_subject *infs = NULL;
	if (ParseTree::get_type(pn) != KIND_NT) infs = ParseTree::get_subject(pn);
	if ((ParseTree::get_type(pn) == RELATIONSHIP_NT) && (pn->down) &&
		(ParseTree::get_type(pn->down) == PROPER_NOUN_NT))
		infs = ParseTree::get_subject(pn->down);
	if ((ParseTree::get_type(pn) == WITH_NT) && (pn->down) &&
		(ParseTree::get_type(pn->down) == PROPER_NOUN_NT))
		infs = ParseTree::get_subject(pn->down);
	return infs;
}

@ =
void Assertions::Copular::make_existential_assertion(parse_node *py) {
	if (ParseTree::get_type(py) == WITH_NT) {
		Assertions::Copular::make_existential_assertion(py->down); return;
	}
	if (ParseTree::get_type(py) == AND_NT) {
		Assertions::Copular::make_existential_assertion(py->down);
		Assertions::Copular::make_existential_assertion(py->down->next);
		return;
	}
	if (ParseTree::get_type(py) == COMMON_NOUN_NT) {
		if ((InferenceSubjects::is_a_kind_of_object(ParseTree::get_subject(py))) ||
			(Kinds::Compare::eq(K_object, InferenceSubjects::as_kind(ParseTree::get_subject(py)))))
			Assertions::Creator::convert_instance_to_nounphrase(py, NULL);
		else
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_ThereIsVague),
				"'there is...' can only be used to create objects",
				"and not instances of other kinds.'");
	}
}
