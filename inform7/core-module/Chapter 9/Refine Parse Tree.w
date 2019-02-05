[Assertions::Refiner::] Refine Parse Tree.

To determine which subjects are referred to by noun phrases
such as "the table" and "a paper cup" found in assertion sentences being
parsed.

@h How individual nouns are represented after refinement.
The parse tree identifies the primary verb in each sentence, but does only the
most basic work in parsing its noun phrases. It can spot the use of certain
keywords like "called", and constructions like "kind of", but otherwise the
NPs are just left unparsed.

Here we "refine" the subtree for a single noun phrase. Refinement means that
we either annotate it with a meaning or break it down into subtree of further
nodes, thus decomposing the NP into smaller clauses which are refined in turn.

=
void Assertions::Refiner::noun_from_infs(parse_node *p, inference_subject *infs) {
	Assertions::Refiner::pn_make_COMMON_or_PROPER(p, infs);
	ParseTree::set_evaluation(p, InferenceSubjects::as_constant(infs));
}

void Assertions::Refiner::noun_from_value(parse_node *p, parse_node *spec) {
	inference_subject *infs = NULL;
	if (Specifications::to_proposition(spec)) {
		pcalc_prop *prop = Specifications::to_proposition(spec);
		parse_node *val = Calculus::Propositions::describes_value(prop);
		if (val) infs = InferenceSubjects::from_specification(val);
		else {
			kind *K = Calculus::Variables::kind_of_variable_0(prop);
			if (Kinds::Compare::lt(K, K_object) == FALSE) K = K_object;
			infs = Kinds::Knowledge::as_subject(K);
		}
		Assertions::Refiner::pn_noun_details_from_spec(p, spec);
	} else infs = InferenceSubjects::from_specification(spec);
	Assertions::Refiner::pn_make_COMMON_or_PROPER(p, infs);
	ParseTree::set_evaluation(p, spec);
}

@ Furthermore:

(c) If the noun phrase gives a number of items, the |multiplicity| annotation
records how many; thus, for "six lorries" it would be 6.
(d) If the noun phrase describes some properties or relations which must be
true -- "an open door", say, or "a woman in London" -- these are recorded
in a |creation_proposition| field.

=
void Assertions::Refiner::pn_noun_details_from_spec(parse_node *p, parse_node *spec) {
	pcalc_prop *prop = Descriptions::get_quantified_prop(spec);
	ParseTree::set_creation_proposition(p, Calculus::Propositions::copy(prop));
	int N = Descriptions::get_quantification_parameter(spec);
	if (N > 0) ParseTree::annotate_int(p, multiplicity_ANNOT, N);
}

@ And lastly:

(e) The node type is |COMMON_NOUN_NT| if and only if the |subject| field is
an inference subject representing a domain rather than a single instance;
thus, if it is kind of object or a kind of value. In all other cases, the
node type is |PROPER_NOUN_NT|.

The linguistic difference between proper and common nouns is a matter of some
disagreement among semanticists, but to us it's very helpful in distinguishing
cases in the assertion-maker.

=
void Assertions::Refiner::pn_make_COMMON_or_PROPER(parse_node *p, inference_subject *infs) {
	if ((infs) && (InferenceSubjects::domain(infs))) ParseTree::set_type(p, COMMON_NOUN_NT);
	else ParseTree::set_type(p, PROPER_NOUN_NT);
	ParseTree::set_subject(p, infs);
}

@ It's useful to have a safe way of transferring the complete noun details
from one node to another, without breaking the above invariant. (The
|nowhere| annotation is used by the spatial model plugin, if active, and
it probably never needs to be copied, but we do so for safety's sake.)

=
void Assertions::Refiner::copy_noun_details(parse_node *to, parse_node *from) {
	ParseTree::set_type(to, ParseTree::get_type(from));
	ParseTree::set_evaluation(to, ParseTree::get_evaluation(from));
	ParseTree::set_creation_proposition(to, ParseTree::get_creation_proposition(from));
	ParseTree::set_subject(to, ParseTree::get_subject(from));
	ParseTree::annotate_int(to, multiplicity_ANNOT, ParseTree::int_annotation(from, multiplicity_ANNOT));
	ParseTree::annotate_int(to, nowhere_ANNOT, ParseTree::int_annotation(from, nowhere_ANNOT));
	ParseTree::annotate_int(to, creation_site_ANNOT, ParseTree::int_annotation(from, creation_site_ANNOT));
}

@h Representation of single adjectives.
Individual adjective nodes are made as follows. Note that we append noun
details to the nodes so that sentences like this one...

>> Scenery is usually fixed in place.

...can work; here "scenery", though an adjective, is effectively a common
noun in disguise. (It's a deficiency of English that a surprising number of
common things, which ought to have count nouns, in fact have mass nouns --
compare "clothing" and "clothes", which has no adequate singular.)

=
void Assertions::Refiner::pn_make_adjective(parse_node *p, adjective_usage *ale, parse_node *spec) {
	adjectival_phrase *aph = AdjectiveUsages::get_aph(ale);
	ParseTree::set_type(p, ADJECTIVE_NT);
	ParseTree::set_aph(p, aph);
	ParseTree::set_evaluation(p, NULL);
	Assertions::Refiner::pn_noun_details_from_spec(p, spec);
	if (AdjectiveUsages::get_parity(ale)) ParseTree::annotate_int(p, negated_boolean_ANNOT, FALSE);
	else ParseTree::annotate_int(p, negated_boolean_ANNOT, TRUE);
}

@ A different reason why adjective and nouns overlap is due to words like
"green", which describe a state and also suggest that something possesses it.

=
void Assertions::Refiner::coerce_adjectival_usage_to_noun(parse_node *leaf) {
	if ((leaf) && (ParseTree::get_type(leaf) == ADJECTIVE_NT)) {
		instance *q = Adjectives::Meanings::has_ENUMERATIVE_meaning(ParseTree::get_aph(leaf));
		if (q) Assertions::Refiner::noun_from_value(leaf, Rvalues::from_instance(q));
	}
}

@h The refinery itself.
Time to get started, then. Each subtree can be refined only once.

The |creation_rule| can have three values:

@d FORBID_CREATION 0 /* never create an object with this name */
@d ALLOW_CREATION 1 /* create an object with this name if that looks sensible */
@d MANDATE_CREATION 2 /* always create an object with this name, except for "it" */

@ =
int forbid_nowhere = FALSE;
void Assertions::Refiner::refine(parse_node *p, int creation_rule) {
	if (p == NULL) internal_error("Refine parse tree on null pn");

	if (ParseTree::int_annotation(p, resolved_ANNOT)) return;
	ParseTree::annotate_int(p, resolved_ANNOT, TRUE);

	LOGIF(NOUN_RESOLUTION, "Refine subtree (%s creation):\n$T",
		((creation_rule == FORBID_CREATION)?"forbid":
			((creation_rule == ALLOW_CREATION)?"allow":"mandate")), p);
	LOG_INDENT;

	Assertions::Refiner::refine_parse_tree_inner(p, creation_rule);

	LOG_OUTDENT;
	LOGIF(NOUN_RESOLUTION, "Refined subtree is:\n$T", p);
}

@ What we do depends on the crude structure already found.

=
void Assertions::Refiner::refine_parse_tree_inner(parse_node *p, int creation_rule) {
	switch(ParseTree::get_type(p)) {
		case X_OF_Y_NT: @<Refine an X-of-Y subtree@>; return;
		case WITH_NT: @<Refine an X-with-Y subtree@>; return;
		case AND_NT: @<Refine an X-and-Y subtree@>; return;
		case RELATIONSHIP_NT: @<Refine a relationship subtree@>; return;
		case CALLED_NT: @<Refine a calling subtree@>; return;
		case KIND_NT: @<Refine a kind subtree@>; return;
		case PROPER_NOUN_NT: @<Refine what seems to be a noun phrase@>; return;
	}
}

@ Recall that an |X_OF_Y_NT| subtree has the form owner followed by
property name, so we forbid creation of a new object from the property name
subtree.

@<Refine an X-of-Y subtree@> =
	Assertions::Refiner::refine(p->down, creation_rule);
	Assertions::Refiner::refine(p->down->next, FORBID_CREATION);

@ |WITH_NT| is used to create something with a list of properties. This
leads to some awkward cases -- for instance, where a "with" in an action
pattern like "doing something with the bucket" has been misinterpreted.
We fix those cases by hand, by reconstructing the text before it was
divided, to form the word range $(a_1, a_2)$; then parsing it as an action
pattern; if it works, that reading is allowed to stand.

@<Refine an X-with-Y subtree@> =
	Assertions::Refiner::refine(p->down, creation_rule);
	Assertions::Refiner::perform_with_surgery(p);
	if (ParseTree::get_type(p) == WITH_NT) {
		#ifdef IF_MODULE
		wording W = Wordings::new(Wordings::first_wn(ParseTree::get_text(p->down)),
			Wordings::last_wn(ParseTree::get_text(p->down->next)));
		if (Wordings::nonempty(W)) {
			if (<action-pattern>(W)) {
				ParseTree::set_type(p, ACTION_NT);
				ParseTree::set_action_meaning(p, <<rp>>);
				ParseTree::set_text(p, W); p->down = NULL;
			}
		}
		#endif
	}
	if (ParseTree::int_annotation(p, resolved_ANNOT) == FALSE) @<Start the refinement over@>;

@ After surgery on the tree, it's usually best to start over again:

@<Start the refinement over@> =
	ParseTree::annotate_int(p, resolved_ANNOT, FALSE);
	Assertions::Refiner::refine(p, creation_rule);
	return;

@ |AND_NT| is easy, except for "and surgery", of which more below.

@<Refine an X-and-Y subtree@> =
	Assertions::Refiner::refine(p->down, creation_rule);
	Assertions::Refiner::refine(p->down->next, creation_rule);
	Assertions::Refiner::perform_and_surgery(p);

@ A |CALLED_NT| node has two children: in the phrase "an X called Y", they
will represent X and Y respectively. Y must be created afresh whatever its
name, since the whole point of "called" is that it enables the designer
to use names which would otherwise be interpreted as meaning something
significant: it is a sort of literal escape, like the backslash character
in C strings. X is never something new: it is expected to be a kind.
We convert the whole node into a simple |PROPER_NOUN_NT| with the name
of Y and the kind of X. In this way, all |CALLED_NT| nodes are removed
from the tree.

@<Refine a calling subtree@> =
	if ((ParseTree::get_type(p->down) == RELATIONSHIP_NT) && (p->down->down)) {
		Assertions::Refiner::perform_called_surgery(p);
		@<Start the refinement over@>;
	}
	Assertions::Refiner::refine(p->down, FORBID_CREATION);
	if (ParseTree::int_annotation(p->down, multiplicity_ANNOT) > 1) {
		Problems::Issue::sentence_problem(_p_(PM_MultipleCalled),
			"I can only make a single 'called' thing at a time",
			"or rather, the 'called' is only allowed to apply to one thing "
			"at a time. For instance, 'A thing called a vodka and tonic is "
			"on the table.' is allowed, but 'Two things called vodka and tonic' "
			"is not.");
	}
	forbid_nowhere = TRUE;
	if (creation_rule == FORBID_CREATION)
		Problems::Issue::sentence_problem(_p_(BelievedImpossible),
			"'called' can't be used in this context",
			"and is best reserved for full sentences.");
	else Assertions::Refiner::refine(p->down->next, MANDATE_CREATION);
	forbid_nowhere = FALSE;

@ A |RELATIONSHIP_NT| node may have no children, representing "here"; or
it may have one child, a room or door which lies in some map direction. But
in general it has two children: for instance "a green marble in a blue box"
has the marble and the box as its children, the relationship being containment.

@<Refine a relationship subtree@> =
	Assertions::Refiner::perform_location_surgery(p);
	if (ParseTree::get_type(p) == AND_NT) @<Start the refinement over@>;

	if (p->down) {
		Assertions::Refiner::refine(p->down, creation_rule);
		#ifdef IF_MODULE
		binary_predicate *bp = ParseTree::get_relationship(p);
		if (bp) {
			instance *dir = PL::MapDirections::get_mapping_direction(BinaryPredicates::get_reversal(bp));
			if (dir == NULL) dir = PL::MapDirections::get_mapping_direction(bp);
			if (dir) @<Make the relation one which refers to a map direction@>;
		}
		#endif
		if (p->down->next) Assertions::Refiner::refine(p->down->next, creation_rule);
	}

@ This handles the case of a one-child node representing a map direction,
but fills in a second child as the direction object in question. Thus if
the relation is mapped-north-of, then the second child will become the
direction object for "north".

@<Make the relation one which refers to a map direction@> =
	LOGIF(NOUN_RESOLUTION, "Directional predicate with BP %S ($O)\n",
		BinaryPredicates::get_log_name(bp), dir);
	ParseTree::annotate_int(p, relationship_node_type_ANNOT, DIRECTION_RELN);
	wording DW = Instances::get_name(dir, FALSE);
	p->down->next = NounPhrases::new_raw(DW);
	Assertions::Refiner::noun_from_infs(p->down->next, Instances::as_subject(dir));
	ParseTree::annotate_int(p->down->next, resolved_ANNOT, TRUE);

@ A |KIND_NT| node may have no children, and if so it represents the bare
word "kind": the reference must be to the kind "kind" itself.
Otherwise it has one child -- the name of an existing kind of value or
object. After refinement, it will be annotated with a valid non-null
inference subject representing the domain to which any new kind would belong.

@<Refine a kind subtree@> =
	inference_subject *kind_of_what = Kinds::Knowledge::as_subject(K_object);
	if (p->down) {
		parse_node *what = p->down;
		Assertions::Refiner::refine(what, FORBID_CREATION);
		kind_of_what = ParseTree::get_subject(what);
	}
	if ((kind_of_what == NULL) || (InferenceSubjects::domain(kind_of_what) == NULL))
		@<Issue a problem message for a kind of instance@>;
	if ((InferenceSubjects::as_nonobject_kind(kind_of_what)) &&
		(kind_of_what != Kinds::Knowledge::as_subject(K_value)) &&
		(kind_of_what != Kinds::Knowledge::as_subject(K_object)))
			@<Issue a problem message for a disallowed subkind@>;
	ParseTree::set_subject(p, kind_of_what);

@<Issue a problem message for a kind of instance@> =
	if ((InferenceSubjects::is_an_object(kind_of_what)) ||
		(InferenceSubjects::is_a_kind_of_object(kind_of_what))) {
		Problems::Issue::sentence_problem(_p_(PM_KindOfInstance),
			"kinds can only be made from other kinds",
			"so 'a kind of container' is allowed but 'a kind of Mona Lisa' (where "
			"Mona Lisa is a specific thing you've already made), wouldn't be "
			"allowed. There is only one Mona Lisa.");
		kind_of_what = Kinds::Knowledge::as_subject(K_object);
	} else {
		Problems::Issue::sentence_problem(_p_(PM_KindOfActualValue),
			"I don't recognise that as a kind",
			"such as 'room' or 'door': it would need to be straightforwardly the name "
			"of a kind, and not be qualified with adjectives like 'open'.");
		kind_of_what = Kinds::Knowledge::as_subject(K_value);
	}

@<Issue a problem message for a disallowed subkind@> =
	Problems::Issue::sentence_problem(_p_(PM_KindOfExotica),
		"you are only allowed to create kinds of objects (things, rooms, and "
		"so on) and kinds of 'value'",
		"so for example 'colour is a kind of value' is allowed but 'prime is "
		"a kind of number' is not.");
	kind_of_what = Kinds::Knowledge::as_subject(K_value);

@ The simple description of what happens to a |PROPER_NOUN_NT| node is that
if it's an existing object or value, then it should be annotated with a
reference to that object or value; and if not, then a new object should be
created with that name. (We don't actually create here, though: we just mark
such a noun phrase by changing its node type to |CREATED_NT|.) The more
complicated description is as follows:

@<Refine what seems to be a noun phrase@> =
	@<Act on the special no-words word range which implies the player@>;
	@<Act on a newly-discovered property of something@>;
	@<Act on the special noun phrases "it" and "they"@>;
	if (forbid_nowhere == FALSE) @<Act on any special noun phrases significant to plugins@>;

	if (creation_rule != MANDATE_CREATION)
		@<Interpret this as an existing noun if possible@>;

	if (creation_rule != FORBID_CREATION) ParseTree::set_type(p, CREATED_NT);
	else ParseTree::set_subject(p, NULL);

@ There's just one case where an empty word range can be used as a noun
phrase -- when it represents an implicit noun, as here, where the person
doing the carrying is implicit:

>> The black box is carried.

@<Act on the special no-words word range which implies the player@> =
	if (ParseTree::int_annotation(p, implicitly_refers_to_ANNOT)) {
		Plugins::Call::refine_implicit_noun(p);
		return;
	}

	if (Wordings::empty(ParseTree::get_text(p))) {
		LOG("$T", current_sentence);
		internal_error("Tried to resolve malformed noun-phrase");
	}

@ The following is needed to handle something like "colour of the box",
where "colour" is a property name. We must be careful, though, to avoid
confusion with variable declarations:

>> The interesting var is a description of numbers that varies.

which would otherwise be misread as an attempt to set the "description"
property of something.

=
<newfound-property-of> ::=
	in the presence of ... |		==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	... that varies |				==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	... variable |					==> 0; return FAIL_NONTERMINAL + Wordings::first_wn(WR[1]) - Wordings::first_wn(W);
	{<property-name-v>} of ...		==> 0; *XP = RP[1]

@<Act on a newly-discovered property of something@> =
	property *prn = NULL;
	wording PW = EMPTY_WORDING, OW = EMPTY_WORDING;
	if (<newfound-property-of>(ParseTree::get_text(p))) {
		prn = <<rp>>;
		PW = GET_RW(<newfound-property-of>, 1);
		OW = GET_RW(<newfound-property-of>, 2);
	}
	if ((prn) && (Properties::is_value_property(prn)) /* &&
		(Properties::Valued::coincides_with_kind(prn)) */) {
		LOGIF(NOUN_RESOLUTION, "Resolving new-property of: $Y\n", prn);
		ParseTree::set_type(p, X_OF_Y_NT);
		<nounphrase-articled>(OW);
		p->down = <<rp>>;
		<nounphrase-as-object>(PW);
		p->down->next = <<rp>>;
		ParseTree::annotate_int(p, resolved_ANNOT, FALSE);
		LOGIF(NOUN_RESOLUTION, "Resolved new-property to:\n$T\n", p);
		Assertions::Refiner::refine(p, creation_rule);
		return;
	}

@ A noun phrase consisting of a pronoun has |refers| set to the relevant
thing. (If we had more and better pronouns, they would go here.)

@<Act on the special noun phrases "it" and "they"@> =
	if (ParseTree::int_annotation(p, nounphrase_article_ANNOT) == IT_ART) {
		if ((<nominative-pronoun>(ParseTree::get_text(p))) &&
			(<<r>> == 2) &&
			(Assertions::Traverse::get_current_subject_plurality())) {
			Problems::Issue::sentence_problem(_p_(PM_EnigmaticThey),
				"I'm unable to handle 'they' here",
				"since it looks as if it needs to refer to more than one "
				"object here, and that's something I can't manage.");
			return;
		}
		if (Assertions::Traverse::get_current_object() == NULL) {
			Problems::Issue::sentence_problem(_p_(PM_EnigmaticPronoun),
				"I'm not sure what to make of the pronoun here",
				"since it is unclear what previously mentioned thing "
				"is being referred to. In general, it's best only to use "
				"'it' where it's unambiguous, and it may be worth noting "
				"that 'they' is not allowed to stand for more than one "
				"object at a time.");
			return;
		}
		inference_subject *referent = Assertions::Traverse::get_current_object();
		if (referent) Assertions::Refiner::noun_from_infs(p, referent);
		LOGIF(PRONOUNS, "Interpreting 'it' as $j\n$P", referent, current_sentence);
		return;
	}

@ For example, "above" and "below" become significant if the mapping plugin
is active, and "nowhere" if the spatial one is.

@<Act on any special noun phrases significant to plugins@> =
	if (Plugins::Call::act_on_special_NPs(p)) return;

@<Interpret this as an existing noun if possible@> =
	parse_node *spec = NULL;
	@<Parse the noun phrase as a value property name@>;
	if (spec == NULL) @<Parse the noun phrase as a value@>;
	if ((ParseTree::is(spec, NONLOCAL_VARIABLE_NT)) ||
		(ParseTree::is(spec, CONSTANT_NT))) {
		Assertions::Refiner::noun_from_value(p, spec);
		return;
	}
	if (Specifications::is_description(spec))
		@<Act on a description used as a noun phrase@>;
	@<Act on an action pattern used as a noun phrase@>;

@ Perhaps it is the name of a valued property? If so, it is used as a noun,
without obvious reference to any owner: we convert it to a noun node.

(This is the next priority so that "description" will be read as its
property name meaning, not as the name of a kind of value.)

@<Parse the noun phrase as a value property name@> =
	if (<value-property-name>(ParseTree::get_text(p)))
		spec = Rvalues::from_property(<<rp>>);

@<Issue PM_VagueVariable problem@> =
	*X = FALSE;
	Problems::Issue::sentence_problem(_p_(PM_VagueVariable),
		"'variable' is too vague a description",
		"because it doesn't say what kind of value should go into the variable. "
		"'number variable' or 'a number that varies' - whatever kind of value you "
		"need - would be much clearer.");

@ When a noun phrase in an assertion represents a value, it's normally a
constant ("13") or else something like a description of values ("a number").
It wouldn't make sense to refer to a temporary value like a local variable,
but a global ("player" or "time of day") is possible.

The "action of taking something" syntax is provided as a way of escaping
the usual handling of action patterns; it enables "taking something" to be
a noun instead of a condition testing the current action.

=
<assertion-np-as-value> ::=
	variable |									==> @<Issue PM_VagueVariable problem@>
	action of <s-explicit-action>	|					==> TRUE; *XP = RP[1]
	<s-descriptive-type-expression> |		==> TRUE; *XP = RP[1]
	<s-global-variable>							==> TRUE; *XP = RP[1]

@<Parse the noun phrase as a value@> =
	if (<assertion-np-as-value>(ParseTree::get_text(p))) {
		if (<<r>> == FALSE) return;
		spec = <<rp>>;
	} else {
		spec = Specifications::new_UNKNOWN(ParseTree::get_text(p));
	}
	if (Descriptions::get_quantifier(spec))
		@<Check that this noun phrase is allowed a quantifier@>;
	LOGIF(NOUN_RESOLUTION, "Noun phrase %W parsed as value: $P\n", ParseTree::get_text(p), spec);

@<Issue a problem for a variable described without a kind@> =
	return;

@<Check that this noun phrase is allowed a quantifier@> =
	if (Quantifiers::can_be_used_in_assertions(Descriptions::get_quantifier(spec)) == FALSE) {
		LOG("$T\nSo $D\n", current_sentence, Specifications::to_proposition(spec));
		Problems::Issue::sentence_problem(_p_(PM_ComplexDeterminer),
			"complicated determiners are not allowed in assertions",
			"so for instance 'More than three people are in the Dining Room' "
			"or 'None of the containers is open' will be rejected. Only "
			"simple numbers will be allowed, as in examples like 'Three "
			"people are in the Dining Room.'");
		return;
	}
	if (Descriptions::get_quantifier(spec) == for_all_quantifier) {
		kind *K = Specifications::to_kind(spec);
		if ((K) &&
			(Descriptions::to_instance(spec) == NULL) &&
			(Descriptions::number_of_adjectives_applied_to(spec) == 0)) {
			ParseTree::set_subject(p, Kinds::Knowledge::as_subject(K));
			ParseTree::set_type(p, EVERY_NT);
			return;
		}
		Problems::Issue::sentence_problem(_p_(PM_ComplexEvery),
			"in an assertion 'every' or 'all' can only be used with a kind",
			"so for instance 'A coin is in every container' is all right, "
			"because 'container' is a kind, but not 'A coin is in every "
			"open container', because 'open container' is now a kind "
			"qualified by a property which may come or go during play. "
			"(This problem sometimes happens because a thing has been "
			"called something like an 'all in one survival kit' - if you "
			"need that sort of name, try using 'called' to set it.)");
		return;
	}

@ If the noun phrase is a valid action pattern, such as "taking something",
we change it to a new node type to mark this. We don't keep the pattern:
it will be reparsed much later on.

We have to be a little cautious, because of the way English allows participles
as nouns to mean the result of some action having taken place on something --
consider "the scoring", for instance, in the sense of a mark scored on a
piece of wood. So we parse action patterns with a lower priority than values
here, given that we know we are looking for a noun.

@<Act on an action pattern used as a noun phrase@> =
	#ifdef IF_MODULE
	if (ParseTree::int_annotation(p, nounphrase_article_ANNOT) == NO_ART) {
		if (<action-pattern>(ParseTree::get_text(p))) {
			ParseTree::set_type(p, ACTION_NT);
			ParseTree::set_action_meaning(p, <<rp>>);
			return;
		}
	}
	#endif

@ This case has been left to last, since it's so much the most difficult.
Descriptions have to be converted into a surprising range of different
subtrees -- otherwise it will not be possible to issue a wide range of
to-the-point problem messages for badly constructed sentences.

Oddly, it's not the complicated descriptions which give trouble...

@<Act on a description used as a noun phrase@> =
	ParseTree::set_subject(p, NULL);
	if (Descriptions::is_complex(spec)) {
		Assertions::Refiner::noun_from_value(p, spec);
		return;
	}
	@<Act on a simple description@>;

@ ...it's the shorter phrases where, perversely, the risk of a
misunderstanding is higher. For one thing, we deliberately ignore a valid
description in two cases:

(a) Adjective(s) followed by the name of a specific object.
(b) An indefinite article followed by the name of a specific object.

For (a), see the example "Goat-Cheese and Sage Chicken". This contains a
kettle which can be in several states, described adjectivally, and one of
those is "heating". This means the S-parser reads "heating kettle" as if it
meant "the kettle when in the heating state". But we don't want this to be
recognised in an assertion, because it's not useful to talk about individual
objects in particular states when setting up the initial state -- the kettle
either starts out as heating, or it doesn't. Moreover, we don't want to
misread a line like:

>> Heating Kettle is a scene.

(also a sentence from "Goat-Cheese and Sage Chicken"). Because of this and
similar ambiguities, we ignore the S-parser's recommendation of reading
adjective(s) plus proper noun as a reference to that noun in a special state.

Case (b) comes out of a point of difference between proper and common nouns:
use of an indefinite article is fine with common nouns -- "a container", for
example -- but not with proper nouns: talking about "a silver bar" suggests
that this is {\it not} the same silver bar referred to in some previous
sentence.

@<Act on a simple description@> =
	if (!((Descriptions::to_instance(spec)) &&
		((Descriptions::number_of_adjectives_applied_to(spec) > 0) ||
			(ParseTree::int_annotation(p, nounphrase_article_ANNOT) != DEF_ART)))) {
		Assertions::Refiner::refine_from_simple_description(p, spec);
		return;
	}

@ The following turns the node |p| into a subtree representing the content of
a simple description in |spec|. Besides being used above, it's also convenient
for assemblies.

Depending on the circumstances, we get a subtree in which the headword if any
is represented by an |COMMON_NOUN_NT| node (where the headword is a kind of
object) or a |PROPER_NOUN_NT| (where the headword is a specific object), and
where the adjectives each become |ADJECTIVE_NT| nodes.

=
void Assertions::Refiner::refine_from_simple_description(parse_node *p, parse_node *spec) {
	inference_subject *head = NULL;
	@<Set the attachment node to the headword, if there is one@>;
	if (Descriptions::number_of_adjectives_applied_to(spec) > 0) {
		if (head) @<Insert a WITH node joining adjective tree to headword@>;
		@<Place a subtree of adjectives at the attachment node@>;
	}
}

@ Crucially, the headword node gets one extra annotation: its "full phrase
evaluation", which retains the original description information -- in
particular, quantification data such as that in "four doors", which
would be lost if we simply applied |Assertions::Refiner::noun_from_infs| to the inference
subject for "door".

If |head| is not set, it doesn't matter what we do, because there'll be
no headword node -- this is why we don't bother to find any subject to
set for it.

@<Set the attachment node to the headword, if there is one@> =
	if (Descriptions::to_instance(spec)) {
		head = Instances::as_subject(Descriptions::to_instance(spec));
		if (head) {
			Assertions::Refiner::noun_from_infs(p, head);
			Assertions::Refiner::pn_noun_details_from_spec(p, spec);
		}
	} else if (Descriptions::makes_kind_explicit(spec)) {
		kind *K = Specifications::to_kind(spec);
		head = Kinds::Knowledge::as_subject(K);
		Assertions::Refiner::noun_from_infs(p, head);
		ParseTree::set_evaluation(p, Specifications::from_kind(K));
		Assertions::Refiner::pn_noun_details_from_spec(p, spec);
	}

@ We put a WITH node in the attachment position, displacing the headword
content to its first child, and making its second child the new attachment
position -- so that that is where the adjectives subtree will go.

@<Insert a WITH node joining adjective tree to headword@> =
	parse_node *lower_copy = ParseTree::new(PROPER_NOUN_NT);
	ParseTree::copy(lower_copy, p);
	ParseTree::set_type(p, WITH_NT);
	p->down = lower_copy;
	lower_copy->next = ParseTree::new(PROPER_NOUN_NT);
	p = lower_copy->next;

@ When there are two or more adjectives, they must occur as leaves of a
binary tree whose non-leaf nodes are |AND_NT|. We do this pretty inefficiently,
making no effort to balance the tree, since it has negligible effect on speed
or memory.

@<Place a subtree of adjectives at the attachment node@> =
	int no_adjectives = Descriptions::number_of_adjectives_applied_to(spec);
	if (no_adjectives == 1) {
		Assertions::Refiner::pn_make_adjective(p,
			Descriptions::first_adjective_usage(spec), spec);
	} else {
		ParseTree::set_type_and_clear_annotations(p, AND_NT);
		adjective_usage *ale;
		int i = 0;
		parse_node *AND_p = p;
		pcalc_prop *ale_prop = NULL;
		LOOP_THROUGH_ADJECTIVE_LIST(ale, ale_prop, spec) {
			i++;
			parse_node *p3 = ParseTree::new(ADJECTIVE_NT);
			Assertions::Refiner::pn_make_adjective(p3, ale, spec);
			if (i < no_adjectives) {
				AND_p->down = p3;
				if (i+1 < no_adjectives) {
					p3->next = ParseTree::new(AND_NT);
					AND_p = p3->next;
				}
			} else {
				AND_p->down->next = p3;
			}
		}
	}

@h About surgeries.
The rest of this section is taken up with four local surgical operations
performed on the tree in the light of what we can now see. In each case, the
problem is that two clausal constructions implied by the nodes inserted
earlier have been applied the wrong way round:

(1) "And surgery": |AND_NT| and |WITH_NT| the wrong way round.

(2) "With surgery": |WITH_NT| and |WITH_NT| where just one will do, though
in disguised form this is another clash with |AND_NT|.

(3) "Location surgery": |AND_NT| and |RELATIONSHIP_NT| the wrong way round.

(4) "Called surgery": |CALLED_NT| and |RELATIONSHIP_NT| the wrong way round.

@h And surgery.
"And surgery" is a fiddly operation to correct the parse tree after
resolution of all the nouns in a phrase which involves both "and" and
"with" in a particular way. There's no problem with either of these:

>> In the Pitch are a bat and ball with score for finding 10. In the Pitch is a sweater with score for finding 5 and description "White wool."

neither of which is altered by and surgery. The difficulty arises with

>> In the Pitch is an openable and open door with description "The Hut door."

which, we notice, has exactly the same grammatical structure as the first of
the two sentences above, yet a very different meaning, since "openable" is a
property whereas "bat" was an object. We perform surgery on:

	|AND_NT|
	|    ADJECTIVE_NT prop:p46_openable|
	|    WITH_NT|
	|        COMMON_NOUN_NT K4_door|
	|        ADJECTIVE_NT prop:p44_open|

to restructure the nodes as:

	|WITH_NT|
	|    COMMON_NOUN_NT K4_door|
	|    AND_NT|
	|        ADJECTIVE_NT prop:p46_openable|
	|        ADJECTIVE_NT prop:p44_open|

This innocent-looking little routine involved drawing a {\it lot} of diagrams
on the back of an envelope. Change at your peril.

=
void Assertions::Refiner::perform_and_surgery(parse_node *p) {
	parse_node *x, *a_p, *w_p, *p1_p, *p2_p, *i_p;
	if ((ParseTree::get_type(p->down) == ADJECTIVE_NT)
		&& (ParseTree::get_type(p->down->next) == WITH_NT)) {
		a_p = p; p1_p = p->down; w_p = p->down->next;
		i_p = w_p->down; p2_p = i_p->next;

		ParseTree::set_type(a_p, WITH_NT);
		ParseTree::set_type_and_clear_annotations(w_p, AND_NT);
		ParseTree::set_subject(a_p, ParseTree::get_subject(w_p));
		ParseTree::set_subject(w_p, NULL);
		x = a_p; a_p = w_p; w_p = x;

		w_p->down = i_p;
		i_p->next = a_p;
		a_p->down = p1_p;
		a_p->down->next = p2_p;
	}
}

@h With surgery.
This is a less traumatic operation, motivated by sentences like:

>> In the Pitch is an open container with description "The box of stumps and bails."

The initial parse tree for such a sentence will have two nested |WITH_NT|
clauses, which is arguably correct -- "a (container with property open)
with description ..." -- but which is inconvenient for our implementation
of |WITH_NT| later on. So we construe the sentence instead with a single
"with", as "a container with properties open and description ..." In
terms of the tree,

	|WITH_NT|
	|    WITH_NT|
	|        COMMON_NOUN_NT K4_container|
	|        ADJECTIVE_NT prop:p44_open|
	|    PROPERTY_LIST_NT "The box..."|

is reconstructed as:

	|WITH_NT|
	|    COMMON_NOUN_NT K4_container|
	|    AND_NT|
	|        ADJECTIVE_NT prop:p44_open|
	|        PROPERTY_LIST_NT "The box..."|

=
void Assertions::Refiner::perform_with_surgery(parse_node *p) {
	parse_node *inst, *prop_1, *prop_2;
	if ((ParseTree::get_type(p) == WITH_NT) && (ParseTree::get_type(p->down) == WITH_NT)) {
		inst = p->down->down;
		prop_1 = p->down->down->next;
		prop_2 = p->down->next;
		p->down = inst;
		p->down->next = ParseTree::new(AND_NT);
		p->down->next->down = prop_1;
		p->down->next->down->next = prop_2;
	}
}

@h Location surgery. This is needed to make sentences like the second one
here work:

>> The escalator is a door. It is below the Kudamm and above the U-Bahn.

	|    RELATIONSHIP_NT <below> (CONTAINS_THINGS_INF)|
	|        AND_NT|
	|            PROPER_NOUN_NT <kudamm> (definite)|
	|            RELATIONSHIP_NT <above> (CONTAINS_THINGS_INF)|
	|                PROPER_NOUN_NT <u-bahn> (definite)|

into:

	|    AND_NT|
	|        RELATIONSHIP_NT <below> (CONTAINS_THINGS_INF)|
	|            PROPER_NOUN_NT <kudamm> (definite)|
	|        RELATIONSHIP_NT <above> (CONTAINS_THINGS_INF)|
	|            PROPER_NOUN_NT <u-bahn> (definite)|

=
void Assertions::Refiner::perform_location_surgery(parse_node *p) {
	parse_node *old_and, *old_np1, *old_loc2;
	if ((ParseTree::get_type(p) == RELATIONSHIP_NT) &&
		(p->down) && (ParseTree::get_type(p->down) == AND_NT) &&
		(p->down->down) && (p->down->down->next) &&
		(ParseTree::get_type(p->down->down->next) == RELATIONSHIP_NT)) {
		ParseTree::annotate_int(p, resolved_ANNOT, FALSE); /* otherwise this will be wrongly copied */
		old_and = p->down;
		old_np1 = old_and->down;
		old_loc2 = old_and->down->next;
		ParseTree::copy(old_and, p); /* making this the new first location node */
		ParseTree::set_type_and_clear_annotations(p, AND_NT); /* and this is new AND */
		p->down = old_and;
		old_and->down = old_np1;
		old_and->next = old_loc2;
		old_np1->next = NULL;
	}
}

@h Called surgery.
The following case occurs very rarely, on a noun phrase such as
"north of a room called the Hot and Cold Room". The problem, as usual, is
the two clauses are the wrong way around, so we perform surgery to turn:

	|CALLED_NT  <called>|
	|	RELATIONSHIP_NT  <north of a room> (type:direction)|
    |		PROPER_NOUN_NT  <room> (indefinite)|
	|		PROPER_NOUN_NT  <north> (no article)|
	|	PROPER_NOUN_NT  <hot and cold room> (definite)|

into:

	|RELATIONSHIP_NT  <called> (type:direction)|
	|	CALLED_NT  <north of a room>|
    |		COMMON_NOUN_NT  <room>|
    |		CREATED_NT  <hot and cold room>|
    |	PROPER_NOUN_NT  <north> (no article)|

=
void Assertions::Refiner::perform_called_surgery(parse_node *p) {
	parse_node *x_pn = p->down->down->next; /* "north" in the example */
	parse_node *name_pn = p->down->next; /* "hot and cold room" in the example */
	ParseTree::set_type(p, RELATIONSHIP_NT);
	ParseTree::annotate_int(p, relationship_node_type_ANNOT,
		ParseTree::int_annotation(p->down, relationship_node_type_ANNOT));
	ParseTree::set_type(p->down, CALLED_NT);
	p->down->next = x_pn;
	p->down->down->next = name_pn;
}

@h The player is not yourself.
The following routine handles a feature added to Inform to handle just one
peculiarity of syntax: that the source text will often talk about "the
player" to mean the object which represents the player at the start of
play (properly called "yourself"), not the variable whose value is the
object currently representing the player.

But no explicit mention of this case appears here; in theory any plugin
can set up aliases of variable names to constants like this.

=
int Assertions::Refiner::turn_player_to_yourself(parse_node *pn) {
	if ((Wordings::nonempty(ParseTree::get_text(pn))) &&
		(ParseTree::get_type(pn) == PROPER_NOUN_NT) &&
		(ParseTree::int_annotation(pn, turned_already_ANNOT) == FALSE)) {
		nonlocal_variable *q = NonlocalVariables::parse(ParseTree::get_text(pn));
		inference_subject *diversion = NonlocalVariables::get_alias(q);
		if (diversion) {
			Assertions::Refiner::noun_from_infs(pn, diversion);
			ParseTree::annotate_int(pn, turned_already_ANNOT, TRUE);
			return TRUE;
		}
	}
	return FALSE;
}
