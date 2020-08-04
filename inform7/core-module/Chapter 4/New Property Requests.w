[NewPropertyRequests::] New Property Requests.

Special sentences creating new either/or properties.

@ Two special meanings can lead to new either/or properties, or to condition
properties: "X is either Y or Z" and "X can be Y or Z". These have the same
effect as each other.

=
<either-sentence-object> ::=
	either <np-unparsed>					==> { pass 1 }

@ =
int NewPropertyRequests::either_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "A room is either dark or lighted." */
		case ACCEPT_SMFT:
			if (<either-sentence-object>(OW)) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			NewPropertyRequests::declare_property_can_be(V);
			break;
	}
	return FALSE;
}

@ =
int NewPropertyRequests::optional_either_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "A room can be dark or lighted." */
		case ACCEPT_SMFT:
			<np-unparsed>(OW);
			parse_node *O = <<rp>>;
			<np-unparsed>(SW);
			V->next = <<rp>>;
			V->next->next = O;
			return TRUE;
		case PASS_1_SMFT:
			NewPropertyRequests::declare_property_can_be(V);
			break;
	}
	return FALSE;
}

@ From a syntax point of view, such sentences come in two forms -- those which
give a range of possible named alternative states, and those which create
named value properties. We'll take the first of those first.

We are concerned here with the syntax of sentences like

>> A container can be stout, standard or fragile (this is its strength property).

The subject (in this example, "a container") is required not to match:

=
<forbidden-property-owners> ::=
	<article> kind |   ==> @<Issue PM_PropertyOfKind1 problem@>
	kind |             ==> @<Issue PM_PropertyOfKind1 problem@>
	<object-pronoun>   ==> @<Issue PM_PropertyOfPronoun problem@>

@<Issue PM_PropertyOfKind1 problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyOfKind1),
		"this seems to give a property to all kinds, rather than to objects or "
		"values",
		"which are the only things capable of having properties. For instance, "
		"'A vehicle has a number called maximum speed' is fine, but not 'A kind "
		"has a number called coolness rating'.");
	==> { -1, - };

@<Issue PM_PropertyOfPronoun problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyOfPronoun),
		"it's often a little ambiguous to declare properties for 'it' "
		"(or some similarly vague pronoun like 'him' or 'her')",
		"so it seems best to spell this out by saying exactly what the "
		"property's owner or owners would be.");
	==> { -1, - };

@ It might look as if this should always create an either/or property, and
in the speedy/sluggish example that's just what it does, but if there are
three or more alternatives then it has to do something trickier: create a
value property, and a new kind of value of which these alternatives form
the legal range. Such a property is customarily called a "condition" (in
the sense of a state of something, not a test -- as in "this antique is in
good condition", not "you can come in on one condition").

=
void NewPropertyRequests::declare_property_can_be(parse_node *p) {
	parse_node *the_owner = p->next;
	parse_node *the_list = the_owner->next;

	<can-be-sentence-object>(Node::get_text(the_list));
	int either_flag = <<r>>;
	the_list->down = <<rp>>;
	the_list = the_list->down;

	wording CNW = EMPTY_WORDING;
	if (the_list->next) CNW = Node::get_text(the_list->next);

	Assertions::Refiner::refine(the_owner, FORBID_CREATION);
	@<Possession must be time-independent@>;

	int count = NewPropertyRequests::list_length(the_list);
	@<An optional condition name can only be given to a condition@>;

	wording FW = EMPTY_WORDING;
	if (count == 1) FW = Node::get_text(the_list);
	else FW = Node::get_text(the_list->down);
	@<Allow the word "either" as syntactic sugar when there are two alternatives@>;
	wording SW = EMPTY_WORDING;
	if (count >= 2) SW = Node::get_text(the_list->down->next);

	if (<forbidden-property-owners>(Node::get_text(the_owner))) return;

	inference_subject *owner_infs = NULL;
	@<Determine the proud owner, and see if it's someone we consider worthy@>;
	if (owner_infs == NULL) @<Issue a problem message for an unworthy owner@>;

	if (count <= 2) @<Be very wary about nameclashes among either/or properties like these@>;

	property *prn = NULL;
	int already_created_instances = FALSE;
	@<Create the property and have the new owner provide it@>;
	if (already_created_instances == FALSE) {
		if (count == 2) @<Make the second option an either/or property which negates the first@>;
		if (count >= 3) @<Make the three or more options the range of possibilities for this new kind@>;
	}
}

@ =
int NewPropertyRequests::list_length(parse_node *P) {
	if (P == NULL) internal_error("Ooops");
	if (Node::get_type(P) == AND_NT)
		return NewPropertyRequests::list_length(P->down) + NewPropertyRequests::list_length(P->down->next);
	return 1;
}

@ And the following parses the object noun phrase of a "can be" sentence,
which might take forms such as:

>> either speedy or sluggish
>> fast or slow
>> allegro, presto, or adagio (the speed property)
>> allegro, presto, or adagio (this is its speed property)

=
<can-be-sentence-object> ::=
	either <np-alternative-list> ( <condition-name> ) |  ==> { TRUE, Node::compose(RP[1], RP[2]) }
	<np-alternative-list> ( <condition-name> ) |         ==> { FALSE, Node::compose(RP[1], RP[2]) }
	either <np-alternative-list> |                       ==> { TRUE, RP[1] }
	<np-alternative-list>                                ==> { FALSE, RP[1] }

<condition-name> ::=
	this is <condition-name-inner> |  ==> { 0, RP[1] }
	<condition-name-inner>            ==> { 0, RP[1] }

<condition-name-inner> ::=
	<article> <condition-name-innermost> |                  ==> { 0, RP[2] }
	<possessive-third-person> <condition-name-innermost> |  ==> { 0, RP[2] }
	<condition-name-innermost>                              ==> { 0, RP[1] }

<condition-name-innermost> ::=
	<np-unparsed> property |  ==> { 0, RP[1] }
	<np-unparsed>             ==> { 0, RP[1] }

@<An optional condition name can only be given to a condition@> =
	if ((Wordings::nonempty(CNW)) && (count < 3)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ThisIsEitherOr),
			"a name can only be supplied using '... (this is...)' when a new property "
			"is being made with three or more named alternatives",
			"whereas here a simpler either/or property is being made with just one or "
			"two possibilities - which means these named outcomes are the property names "
			"themselves. For instance, 'A book can be mint or foxed' makes two either/or "
			"properties, one called 'mint', the other called 'foxed'. So 'A book can "
			"be mint or foxed (this is the cover state)' is not allowed.");
		return;
	}

@<Possession must be time-independent@> =
	if (Node::get_type(the_owner) == WITH_NT) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_QualifiedCanBe),
			"only a room, a thing or a kind can have such adjectives applied to it",
			"and qualifications cannot be used. It makes no sense to say 'An open door "
			"can be rickety or sturdy' because the door still has to have the property "
			"even at times when it is not open: we must instead just say 'A door can be "
			"rickety or sturdy'.");
		return;
	}

@ This allows for natural sentences such as:

>> An animal can be either alive or dead.

Here "either" has a slight sense of emphasis, implying the exclusivity of the
two choices -- the lack of a middle way. That's not useful information for us,
because to Inform all either/or properties have that Aristotelian nature. But
we found in testing that users wrote the word "either" now and then,
regardless of what the documentation said. So we'll allow it but do nothing
differently as a result.

@<Allow the word "either" as syntactic sugar when there are two alternatives@> =
	if ((either_flag) && (count != 2)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EitherOnThree),
			"that looks like an attempt to use 'either' other than to lay out exactly "
			"two possibilities",
			"which is not allowed. (Technically it ought to be legal to have a property "
			"whose name actually starts with 'either' but the confusion would be just "
			"too awful to contemplate.)");
		return;
	}

@<Determine the proud owner, and see if it's someone we consider worthy@> =
	parse_node *owner_spec = Node::get_evaluation(the_owner);
	if (Lvalues::is_actual_NONLOCAL_VARIABLE(owner_spec))
		@<Disallow this variable as a new owner of a property@>;
	if (Descriptions::is_qualified(owner_spec))
		@<Disallow this as an owner not time-independent@>;
	owner_infs = Node::get_subject(the_owner);
	if (owner_infs == NULL) {
		owner_spec = NULL;
		if (<s-type-expression>(Node::get_text(the_owner)))
			owner_infs = Kinds::Knowledge::as_subject(Specifications::to_kind(<<rp>>));
	}
	kind *K = InferenceSubjects::domain(owner_infs);
	if ((K) && (Kinds::Behaviour::has_properties(K) == FALSE))
		@<Disallow this kind as a new owner of an either/or or condition@>;

@<Disallow this kind as a new owner of an either/or or condition@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, K);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ValueCantHaveProperties));
	Problems::issue_problem_segment(
		"The sentence %1 looked to me as if it might be trying to create an either/or "
		"property which would be held by all of the values of a rather large kind "
		"(%2). But this is a kind which is not allowed to have properties, because "
		"the storage requirements would be too difficult. For instance, scenes can "
		"have properties like this, but numbers can't: that's because there are only "
		"a few, named scenes, but there is an almost unlimited range of numbers. (That "
		"doesn't mean you can't create adjectives using 'Definition: ...' - it's "
		"only when storage would be needed that this limitation kicks in.)");
	Problems::issue_problem_end();
	return;

@<Disallow this variable as a new owner of a property@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(the_owner));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_VariableCantHaveProperties));
	Problems::issue_problem_segment(
		"The sentence %1 looked to me as if it might be trying to create an either/or "
		"property which would be held by a variable ('%2'). But because '%2' can have "
		"different values at different times, it's not clear who or what should have "
		"the property. "
		"%PThe most common case of this is saying something like 'The player can "
		"be ambitious'. 'The player' is actually a variable, because the perspective "
		"of play can change. Instead either say 'A person can be ambitious' or, if "
		"you really only want the default player to be involved, 'Yourself can be "
		"ambitious'.");
	Problems::issue_problem_end();
	return;

@<Disallow this as an owner not time-independent@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_OwnerTimeDependent),
		"ownership of a property is something that has to be always true or "
		"always false",
		"so that 'a room can be secret' is fine - a room is always a room - "
		"but 'a dark room can be secret' is not - a room might be dark some "
		"of the time, and lighted the rest of the time. You need to give a "
		"straightforward owner, and not qualify it with adjectives or "
		"other conditions.");
	return;

@<Issue a problem message for an unworthy owner@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonObjectCanBe),
		"only a room, a thing or a kind can have such adjectives applied to it",
		"so that 'a dead end can be secret' is fine but 'taking can be secret' would "
		"not be, since 'taking' is an action and not a room, thing or kind.");
	return;

@ There are seven different ways this can go wrong, and they all share a
"miscellaneous" problem message.

@<Be very wary about nameclashes among either/or properties like these@> =
	char *error_text = NULL;

	wording EW = FW;
	property *already = NULL;
	if (<property-name>(FW)) already = <<rp>>;
	@<See if the first option already means something incompatible with this@>;

	if ((count == 2) && (error_text == NULL)) {
		EW = SW;
		@<See if the second option is "not" plus an existing property@>;
		property *alreadybar = NULL;
		if (<property-name>(EW)) alreadybar = <<rp>>;
		@<See if the second option already means something incompatible with this@>;
	}

	if (error_text) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, EW);
		Problems::quote_text(3, error_text);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_MiscellaneousEOProblem));
		Problems::issue_problem_segment(
			"In %1, you proposed the new either/or property '%2': but %3.");
		Problems::issue_problem_end();
		return;
	}

@<See if the first option already means something incompatible with this@> =
	if (already) {
		if (Properties::is_either_or(already) == FALSE)
			error_text = "this already has a meaning as a value property";
	} else {
		if (<s-type-expression-or-value>(FW)) {
			parse_node *spec = <<rp>>;
			if (Specifications::is_description(spec) == FALSE)
				error_text = "this already has a meaning";
		}
	}

@<See if the second option is "not" plus an existing property@> =
	if (<negated-clause>(EW)) {
		wording EPW = GET_RW(<negated-clause>, 1);
		property *not_what = NULL;
		if (<property-name>(EPW)) not_what = <<rp>>;
		if ((not_what) && (not_what != already))
			error_text =
			"this is 'not' compounded with an existing either/or "
			"property, which would cause horrible ambiguities";
	}

@<See if the second option already means something incompatible with this@> =
	if (alreadybar) {
		if (Properties::is_either_or(alreadybar) == FALSE)
			error_text = "this already has a meaning as a value property";
		else if ((already) &&
			(Properties::EitherOr::get_negation(already) != alreadybar))
			error_text = "this is not the same negation as the last "
					"time this either/or property was used";
		else if ((already == NULL) ||
			(Properties::EitherOr::get_negation(already) != alreadybar))
			error_text =
				"this already has a meaning as an either/or property";
	} else {
		if (<s-type-expression-or-value>(EW)) {
			parse_node *spec = <<rp>>;
			if (Specifications::is_description(spec) == FALSE)
				error_text = "this already has a meaning";
		}
	}

@<Create the property and have the new owner provide it@> =
	if (count <= 2) prn = Properties::EitherOr::obtain(FW, owner_infs);
	else prn = Properties::Conditions::new(owner_infs, CNW, the_list,
		&already_created_instances);
	Calculus::Propositions::Assert::assert_true_about(
		Calculus::Propositions::Abstract::to_provide_property(prn),
		owner_infs, prevailing_mood);

@<Make the second option an either/or property which negates the first@> =
	property *prnbar = Properties::EitherOr::obtain(SW, owner_infs);
	Calculus::Propositions::Assert::assert_true_about(
		Calculus::Propositions::Abstract::to_provide_property(prnbar),
		owner_infs, prevailing_mood);
	Properties::EitherOr::make_negations(prn, prnbar);

@ An interesting anomaly in the language here is that when an either/or
pair is created, like so:

>> A vehicle can be speedy or sluggish.

the convention is that the first-named term is the more surprising one,
so that the default is the second. That seems natural, because if there's
just one named alternative, like this:

>> A vehicle can be fabulously racy.

then the default is for this property not to be had. But when there are
three or more alternatives, like so:

>> A vehicle can be petrol, diesel, electric or hybrid.

the default is the first option -- petrol. This accords with the
convention that the first-created value for an enumerated kind is always
its default value.

But the beta-testers felt that this was an anomaly in the language. I
suspect they're right, but it isn't obvious to me what a better system
would be. And there does seem to be some subtle difference in English
meaning as to the suggested likelihood of possibilities, here. "You can
be useful" has the sense that you aren't useful right at the moment,
but "it can be blue, green or purple" tends to favour the front end
of the list as likelier, if anything -- as when people offer an
exaggeratedly unlikely final choice: "you can be black, white, brown,
or sky blue pink".

@<Make the three or more options the range of possibilities for this new kind@> =
	parse_node *option;
	kind *cnd_kind = Properties::Valued::kind(prn);
	for (option = the_list; option; option = (option->down)?(option->down->next):NULL) {
		wording PW;
		if (Node::get_type(option) == AND_NT)
			PW = Node::get_text(option->down);
		else
			PW = Node::get_text(option);
		@<Disallow this option name if it clashes with something non-adjectival@>;
		@<Disallow this option name if it clashes with an either-or@>;
		pcalc_prop *prop = Calculus::Propositions::Abstract::to_create_something(cnd_kind, PW);
		Calculus::Propositions::Assert::assert_true(prop, prevailing_mood);
	}

@ The interesting thing here is that we do allow name-clashes with either/or
properties, with other condition values (since those are adjectival and
therefore parse to description specifications), and indeed adjectives
in general. What we don't want is for it to clash with a noun, because then
there would be horrible ambiguities in parsing.

@<Disallow this option name if it clashes with something non-adjectival@> =
	if (<s-type-expression-or-value>(PW)) {
		parse_node *spec = <<rp>>;
		int exempt = FALSE;
		if ((Specifications::is_description(spec)) &&
			(Descriptions::is_qualified(spec))) exempt = TRUE;
		if (Rvalues::is_CONSTANT_construction(spec, CON_property)) exempt = TRUE;
		if (exempt == FALSE) {
			LOG("Already means: $P\n", spec);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, PW);
			Problems::quote_spec(3, spec);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_PropertyAlreadyKnown));
			Problems::issue_problem_segment(
				"In %1, one of the values you supply as a possibility is '%2', but this "
				"already has a meaning (as %3).");
			Problems::issue_problem_end();
			return;
		}
	}

@ And similarly:

@<Disallow this option name if it clashes with an either-or@> =
	property *already = NULL;
	if (<property-name>(PW)) already = <<rp>>;
	if ((already) && (Properties::is_either_or(already))) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, PW);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_EOClashesWithCondition));
		Problems::issue_problem_segment(
			"In %1, one of the values you supply as a possibility is '%2', but this "
			"already has a meaning as an either-or property. The same adjective "
			"can't be used both ways, so you'll have to use a different word here.");
		Problems::issue_problem_end();
		return;
	}
