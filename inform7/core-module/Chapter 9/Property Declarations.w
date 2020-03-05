[Assertions::Property::] Property Declarations.

To parse sentences which create new properties, or assert that
particular kinds of value can possess them.

@h X can be Y or Z.
Just one ingredient of assertion-parsing is missing: the handling of sentences
which create and assign properties.

First we handle the special meaning of "to be either", as in "X is either
Y or Z...".

=
<either-sentence-object> ::=
	either <nounphrase>					==> TRUE; *XP = RP[1]

@ =
int Assertions::Property::either_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "A room is either dark or lighted." */
		case ACCEPT_SMFT:
			if (<either-sentence-object>(OW)) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				parse_node *O = <<rp>>;
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case 1:
			Assertions::Property::declare_property_can_be(V);
			break;
	}
	return FALSE;
}

@ =
int Assertions::Property::optional_either_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "A room can be dark or lighted." */
		case ACCEPT_SMFT:
			ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
			<nounphrase>(OW);
			parse_node *O = <<rp>>;
			<nounphrase>(SW);
			V->next = <<rp>>;
			V->next->next = O;
			return TRUE;
		case TRAVERSE1_SMFT:
			Assertions::Property::declare_property_can_be(V);
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
	<article> kind |		==> @<Issue PM_PropertyOfKind1 problem@>
	kind |					==> @<Issue PM_PropertyOfKind1 problem@>
	<pronoun>				==> @<Issue PM_PropertyOfPronoun problem@>

@<Issue PM_PropertyOfKind1 problem@> =
	*X = -1;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyOfKind1),
		"this seems to give a property to all kinds, rather than to objects or "
		"values",
		"which are the only things capable of having properties. For instance, "
		"'A vehicle has a number called maximum speed' is fine, but not 'A kind "
		"has a number called coolness rating'.");

@<Issue PM_PropertyOfPronoun problem@> =
	*X = -1;
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyOfPronoun),
		"it's often a little ambiguous to declare properties for 'it'",
		"so it seems best to spell this out by saying exactly what the "
		"property's owner or owners would be.");

@ It might look as if this should always create an either/or property, and
in the speedy/sluggish example that's just what it does, but if there are
three or more alternatives then it has to do something trickier: create a
value property, and a new kind of value of which these alternatives form
the legal range. Such a property is customarily called a "condition" (in
the sense of a state of something, not a test -- as in "this antique is in
good condition", not "you can come in on one condition").

=
void Assertions::Property::declare_property_can_be(parse_node *p) {
	parse_node *the_owner = p->next;
	parse_node *the_list = the_owner->next;

	<can-be-sentence-object>(ParseTree::get_text(the_list));
	int either_flag = <<r>>;
	the_list->down = <<rp>>;
	the_list = the_list->down;

	wording CNW = EMPTY_WORDING;
	if (the_list->next) CNW = ParseTree::get_text(the_list->next);

	Assertions::Refiner::refine(the_owner, FORBID_CREATION);
	@<Possession must be time-independent@>;

	int count = Assertions::Property::list_length(the_list);
	@<An optional condition name can only be given to a condition@>;

	wording FW = EMPTY_WORDING;
	if (count == 1) FW = ParseTree::get_text(the_list);
	else FW = ParseTree::get_text(the_list->down);
	@<Allow the word "either" as syntactic sugar when there are two alternatives@>;
	wording SW = EMPTY_WORDING;
	if (count >= 2) SW = ParseTree::get_text(the_list->down->next);

	if (<forbidden-property-owners>(ParseTree::get_text(the_owner))) return;

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
int Assertions::Property::list_length(parse_node *P) {
	if (P == NULL) internal_error("Ooops");
	if (ParseTree::get_type(P) == AND_NT)
		return Assertions::Property::list_length(P->down) + Assertions::Property::list_length(P->down->next);
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
	either <nounphrase-alternative-list> ( <condition-name> ) |	==> TRUE; *XP = RP[1]; ((parse_node *) RP[1])->next = RP[2];
	<nounphrase-alternative-list> ( <condition-name> ) |		==> FALSE; *XP = RP[1]; ((parse_node *) RP[1])->next = RP[2];
	either <nounphrase-alternative-list> |						==> TRUE; *XP = RP[1]
	<nounphrase-alternative-list>								==> FALSE; *XP = RP[1]

<condition-name> ::=
	this is <condition-name-inner> |		==> 0; *XP = RP[1]
	<condition-name-inner>					==> 0; *XP = RP[1]

<condition-name-inner> ::=
	<article> <condition-name-innermost> |					==> 0; *XP = RP[2]
	<possessive-third-person> <condition-name-innermost> |	==> 0; *XP = RP[2]
	<condition-name-innermost>								==> 0; *XP = RP[1]

<condition-name-innermost> ::=
	<nounphrase> property |					==> 0; *XP = RP[1]
	<nounphrase>							==> 0; *XP = RP[1]

@<An optional condition name can only be given to a condition@> =
	if ((Wordings::nonempty(CNW)) && (count < 3)) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_ThisIsEitherOr),
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
	if (ParseTree::get_type(the_owner) == WITH_NT) {
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_QualifiedCanBe),
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
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_EitherOnThree),
			"that looks like an attempt to use 'either' other than to lay out exactly "
			"two possibilities",
			"which is not allowed. (Technically it ought to be legal to have a property "
			"whose name actually starts with 'either' but the confusion would be just "
			"too awful to contemplate.)");
		return;
	}

@<Determine the proud owner, and see if it's someone we consider worthy@> =
	parse_node *owner_spec = ParseTree::get_evaluation(the_owner);
	if (Lvalues::is_actual_NONLOCAL_VARIABLE(owner_spec))
		@<Disallow this variable as a new owner of a property@>;
	if (Descriptions::is_qualified(owner_spec))
		@<Disallow this as an owner not time-independent@>;
	owner_infs = ParseTree::get_subject(the_owner);
	if (owner_infs == NULL) {
		owner_spec = NULL;
		if (<s-type-expression>(ParseTree::get_text(the_owner)))
			owner_infs = Kinds::Knowledge::as_subject(Specifications::to_kind(<<rp>>));
	}
	kind *K = InferenceSubjects::domain(owner_infs);
	if ((K) && (Kinds::Behaviour::has_properties(K) == FALSE))
		@<Disallow this kind as a new owner of an either/or or condition@>;

@<Disallow this kind as a new owner of an either/or or condition@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_kind(2, K);
	Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_ValueCantHaveProperties));
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
	Problems::quote_wording(2, ParseTree::get_text(the_owner));
	Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_VariableCantHaveProperties));
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
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_OwnerTimeDependent),
		"ownership of a property is something that has to be always true or "
		"always false",
		"so that 'a room can be secret' is fine - a room is always a room - "
		"but 'a dark room can be secret' is not - a room might be dark some "
		"of the time, and lighted the rest of the time. You need to give a "
		"straightforward owner, and not qualify it with adjectives or "
		"other conditions.");
	return;

@<Issue a problem message for an unworthy owner@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_NonObjectCanBe),
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
		Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_MiscellaneousEOProblem));
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
	Calculus::Propositions::Assert::assert_true_about(Calculus::Propositions::Abstract::to_provide_property(prn),
		owner_infs, prevailing_mood);

@<Make the second option an either/or property which negates the first@> =
	property *prnbar = Properties::EitherOr::obtain(SW, owner_infs);
	Calculus::Propositions::Assert::assert_true_about(Calculus::Propositions::Abstract::to_provide_property(prnbar),
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
	kind *condition_kind = Properties::Valued::kind(prn);
	for (option = the_list; option; option = (option->down)?(option->down->next):NULL) {
		wording PW;
		if (ParseTree::get_type(option) == AND_NT)
			PW = ParseTree::get_text(option->down);
		else
			PW = ParseTree::get_text(option);
		@<Disallow this option name if it clashes with something non-adjectival@>;
		@<Disallow this option name if it clashes with an either-or@>;
		pcalc_prop *prop = Calculus::Propositions::Abstract::to_create_something(condition_kind, PW);
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
			Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyAlreadyKnown));
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
		Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_EOClashesWithCondition));
		Problems::issue_problem_segment(
			"In %1, one of the values you supply as a possibility is '%2', but this "
			"already has a meaning as an either-or property. The same adjective "
			"can't be used both ways, so you'll have to use a different word here.");
		Problems::issue_problem_end();
		return;
	}

@h X has a K called P.
The following handles sentences like

>> A container has a number called rating.

in which the "number called rating" construction is a |PROPERTYCALLED_NT|
subtree, and also sentences like

>> A fruit has a colour.

in which there's only a leaf on the left-hand-side -- in fact an |PROPER_NOUN_NT|
node, though of course it's not an object. This is most neatly handled with
a recursive traverse of the left-hand subtree.

(There's no sentence-handler here since "to have" has been implemented already.)

=
property *Assertions::Property::recursively_declare_properties(parse_node *owner_ref, parse_node *p) {
	switch(ParseTree::get_type(p)) {
		case AND_NT:
			Assertions::Property::recursively_declare_properties(owner_ref, p->down);
			Assertions::Property::recursively_declare_properties(owner_ref, p->down->next);
			break;
		case PROPERTYCALLED_NT: @<This is a subtree citing a kind of value plus a name@>;
		case PROPER_NOUN_NT: @<This is a leaf containing just a property name@>;
		default:
			internal_error("Assertions::Property::recursively_declare_properties on a node of unknown type");
	}
	return NULL;
}

@ Note that the property name may not yet exist; in which case the following
automatically creates it.

@<This is a leaf containing just a property name@> =
	if ((<k-kind>(ParseTree::get_text(p))) &&
		((<<rp>> == K_number) || (<<rp>> == K_text))) {
		Problems::Issue::assertion_problem(Task::syntax_tree(), _p_(PM_BareProperty),
			"this would create a property called 'number' or 'text'",
			"and although bare names of kinds are usually allowed as properties, "
			"these aren't. Instead, try '... has a number called position.' or "
			"something like that, to give the property a name.");
	}
	inference_subject *owner_infs = ParseTree::get_subject(owner_ref);
	kind *K = InferenceSubjects::domain(owner_infs);
	Kinds::Behaviour::convert_to_enumeration(Task::syntax_tree(), K); /* if that's possible; does nothing if not */
	if ((K) && (Kinds::Behaviour::has_properties(K) == FALSE))
		@<Disallow this kind as a new owner of a value property@>;
	property *prn = Properties::Valued::obtain(ParseTree::get_text(p));
	Calculus::Propositions::Assert::assert_true_about(Calculus::Propositions::Abstract::to_provide_property(prn),
		owner_infs, prevailing_mood);
	return prn;

@<Disallow this kind as a new owner of a value property@> =
	if ((Kinds::Compare::eq(K, K_action_name)) ||
		(Kinds::get_construct(K) == CON_activity) ||
		(Kinds::get_construct(K) == CON_rulebook))
	Problems::Issue::assertion_problem(Task::syntax_tree(), _p_(PM_ValueCantHaveVProperties2),
		"this is a kind of value which is not allowed to have properties of its own",
		"because this would cause confusion with variables, which are more useful in "
		"most cases. (See the Kinds index for which kinds can have properties.)");
	else
	Problems::Issue::assertion_problem(Task::syntax_tree(), _p_(PM_ValueCantHaveVProperties),
		"this is a kind of value which is not allowed to have properties of its own",
		"because this would be impossible to store in any sensible way. For instance, "
		"'A scene has a number called difficulty.' is fine because there are not many "
		"scenes and I know them all, but 'A number has a text called French translation.' "
		"is not allowed, because storing something for every possible number takes an "
		"impossible amount of space. (See the Kinds index for which kinds can have "
		"properties.)");
	owner_infs = Kinds::Knowledge::as_subject(K_object);

@<This is a subtree citing a kind of value plus a name@> =
	parse_node *kind_ref = p->down;
	parse_node *prn_ref = p->down->next;
	Assertions::Property::recursively_call_properties(owner_ref, kind_ref, prn_ref);
	return NULL;

@ The following handles a second kind of recursion: using "and" to divide
several property names, e.g., in

>> A door has numbers called length and width.

=
void Assertions::Property::recursively_call_properties(parse_node *owner_ref, parse_node *kind_ref, parse_node *prn_ref) {
	switch(ParseTree::get_type(prn_ref)) {
		case AND_NT:
			Assertions::Property::recursively_call_properties(owner_ref, kind_ref, prn_ref->down);
			Assertions::Property::recursively_call_properties(owner_ref, kind_ref, prn_ref->down->next);
			break;
		default:
			@<Deal with an individual property being declared@>;
	}
}

@<Deal with an individual property being declared@> =
	property *prn = Assertions::Property::recursively_declare_properties(owner_ref, prn_ref);
	kind *K = NULL;
	@<Find the kind of value being asked for@>;
	@<Issue a problem message if the property kind is just "value"@>;
	kind *current_kind = Properties::Valued::kind(prn);
	if (current_kind == NULL) Properties::Valued::set_kind(prn, K);
	else if (Kinds::Compare::eq(current_kind, K) == FALSE)
		@<Issue a problem message for giving the wrong kind of an existing property@>;

@<Find the kind of value being asked for@> =
	if (<k-kind>(ParseTree::get_text(kind_ref))) K = <<rp>>;
	else @<Issue a problem message for a non-kind as the property kind@>;

@<Issue a problem message for a non-kind as the property kind@> =
	parse_node *spec = NULL;
	if (<s-type-expression>(ParseTree::get_text(kind_ref)))
		spec = <<rp>>;
	LOG("Offending SP: $T", spec);
	if (Specifications::is_new_variable_like(spec)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(kind_ref));
		Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_RedundantThatVaries));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named property - "
			"a value associated with an object and which has a name. But you write this "
			"as if it were a variable, which is not allowed because it would confuse "
			"things. For example, 'A scene has a number that varies called the completion "
			"bonus.' is not allowed - it should just be 'A scene has a number called "
			"the completion bonus.', that is, without the 'that varies'.");
		Problems::issue_problem_end();
	} else if (Specifications::is_description(spec)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(kind_ref));
		Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyTooSpecific));
		Problems::issue_problem_segment(
			"You wrote %1, which I am reading as a request to make a new named property - "
			"a value associated with an object and which has a name. The request seems to "
			"say that the value in question is '%2', but this is too specific a description. "
			"(Instead, a kind of value (such as 'number') or a kind of object (such as 'room' "
			"or 'thing') should be given. To get a property whose contents can be any kind "
			"of object, use 'object'.)");
		Problems::issue_problem_end();
	} else {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(kind_ref));
		Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyKindUnknown));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not the name of a kind of value which I know (such "
			"as 'number' or 'text').");
		Problems::issue_problem_end();
	}
	return;

@<Issue a problem message if the property kind is just "value"@> =
	if (Kinds::Compare::eq(K, K_value)) {
		if (prn == P_variable_initial_value) return;
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, ParseTree::get_text(kind_ref));
		Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyKindVague));
		Problems::issue_problem_segment(
			"You wrote %1, but saying that a property is a 'value' does not give me a clear "
			"enough idea what it will hold. You need to say what kind of value: for instance, "
			"'A door has a number called street address.' is allowed because 'number' is "
			"specific about the kind of value.");
		Problems::issue_problem_end();
		return;
	}

@<Issue a problem message for giving the wrong kind of an existing property@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, ParseTree::get_text(kind_ref));
	Problems::quote_property(3, prn);
	Problems::quote_kind(4, current_kind);
	Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyKindClashes));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2' contradicts what I previously thought about the property "
		"%3, which was that it was %4.");
	Problems::issue_problem_end();
	return;
