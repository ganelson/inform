[NewPropertyAssertions::] New Property Assertions.

When regular assertion sentences create properties.

@ The following handles sentences like

>> A container has a number called rating.

in which the "number called rating" construction is a |PROPERTYCALLED_NT|
subtree, and also sentences like

>> A fruit has a colour.

in which there's only a leaf on the left-hand-side -- in fact an |PROPER_NOUN_NT|
node, though of course it's not an object. This is most neatly handled with
a recursive traverse of the left-hand subtree.

(There's no sentence-handler here since "to have" has been implemented already.)

=
property *NewPropertyAssertions::recursively_declare(parse_node *owner_ref,
	parse_node *p) {
	switch(Node::get_type(p)) {
		case AND_NT:
			NewPropertyAssertions::recursively_declare(owner_ref, p->down);
			NewPropertyAssertions::recursively_declare(owner_ref, p->down->next);
			break;
		case PROPERTYCALLED_NT: @<This is a subtree citing a kind of value plus a name@>;
		case UNPARSED_NOUN_NT: @<This is a leaf containing just a property name@>;
		default:
			internal_error("NewPropertyAssertions::recursively_declare on a node of unknown type");
	}
	return NULL;
}

@ Note that the property name may not yet exist; in which case the following
automatically creates it.

@<This is a leaf containing just a property name@> =
	kind *PK = NULL; if (<k-kind>(Node::get_text(p))) PK = <<rp>>;
	if ((PK == K_number) || (PK == K_text)) {
		UsingProblems::assertion_problem(Task::syntax_tree(), _p_(PM_BareProperty),
			"this would create a property called 'number' or 'text'",
			"and although bare names of kinds are usually allowed as properties, "
			"these aren't. Instead, try '... has a number called position.' or "
			"something like that, to give the property a name.");
	}
	if (Kinds::Behaviour::is_object(PK)) {
		UsingProblems::assertion_problem(Task::syntax_tree(), _p_(PM_BareObjectProperty),
			"this would create a property whose name is also the name of a kind of object",
			"and although bare names of kinds are usually allowed as properties, those "
			"can't be names of kinds of object - that becomes too confusing when sentences "
			"involving 'to have' come up. (Suppose we allowed 'A person has a thing.' "
			"to create a new property, with no name, identified only by being a thing. "
			"What would a sentence like 'Dr Jones has a ray gun.' mean, then? Would it "
			"mean Jones has an actual ray gun, or only that his 'thing' property has "
			"the value 'ray gun'? That's too ambiguous. Instead 'A person has a thing "
			"called talisman. Professor Smith has the ray gun. The talisman of Dr Jones "
			"is the ray gun.' is much clearer.)");
	}
	inference_subject *owner_infs = Node::get_subject(owner_ref);
	kind *K = KindSubjects::to_kind(owner_infs);
	Kinds::Behaviour::convert_to_enumeration(K);
	if ((K) && (KindSubjects::has_properties(K) == FALSE))
		@<Disallow this kind as a new owner of a value property@>;
	property *prn = ValueProperties::obtain(Node::get_text(p));
	Assert::true_about(Propositions::Abstract::to_provide_property(prn),
		owner_infs, prevailing_mood);
	return prn;

@<Disallow this kind as a new owner of a value property@> =
	if ((Kinds::eq(K, K_action_name)) ||
		(Kinds::get_construct(K) == CON_activity) ||
		(Kinds::get_construct(K) == CON_rulebook))
	UsingProblems::assertion_problem(Task::syntax_tree(), _p_(PM_ValueCantHaveVProperties2),
		"this is a kind of value which is not allowed to have properties of its own",
		"because this would cause confusion with variables, which are more useful in "
		"most cases. (See the Kinds index for which kinds can have properties.)");
	else
	UsingProblems::assertion_problem(Task::syntax_tree(), _p_(PM_ValueCantHaveVProperties),
		"this is a kind of value which is not allowed to have properties of its own",
		"because this would be impossible to store in any sensible way. For instance, "
		"'A scene has a number called difficulty.' is fine because there are not many "
		"scenes and I know them all, but 'A number has a text called French translation.' "
		"is not allowed, because storing something for every possible number takes an "
		"impossible amount of space. (See the Kinds index for which kinds can have "
		"properties.)");
	owner_infs = KindSubjects::from_kind(K_object);

@<This is a subtree citing a kind of value plus a name@> =
	parse_node *kind_ref = p->down;
	parse_node *prn_ref = p->down->next;
	NewPropertyAssertions::recursively_call(owner_ref, kind_ref, prn_ref);
	return NULL;

@ The following handles a second kind of recursion: using "and" to divide
several property names, e.g., in

>> A door has numbers called length and width.

=
void NewPropertyAssertions::recursively_call(parse_node *owner_ref,
	parse_node *kind_ref, parse_node *prn_ref) {
	switch(Node::get_type(prn_ref)) {
		case AND_NT:
			NewPropertyAssertions::recursively_call(owner_ref, kind_ref, prn_ref->down);
			NewPropertyAssertions::recursively_call(owner_ref, kind_ref, prn_ref->down->next);
			break;
		default:
			@<Deal with an individual property being declared@>;
	}
}

@<Deal with an individual property being declared@> =
	property *prn = NewPropertyAssertions::recursively_declare(owner_ref, prn_ref);
	kind *K = NULL;
	@<Find the kind of value being asked for@>;
	@<Issue a problem message if the property kind is just "value"@>;
	kind *current_kind = ValueProperties::kind(prn);
	if (current_kind == NULL) ValueProperties::set_kind(prn, K);
	else if (Kinds::eq(current_kind, K) == FALSE)
		@<Issue a problem message for giving the wrong kind of an existing property@>;

@<Find the kind of value being asked for@> =
	if (<k-kind>(Node::get_text(kind_ref))) K = <<rp>>;
	else @<Issue a problem message for a non-kind as the property kind@>;

@<Issue a problem message for a non-kind as the property kind@> =
	parse_node *spec = NULL;
	if (<s-type-expression>(Node::get_text(kind_ref)))
		spec = <<rp>>;
	LOG("Offending SP: $T", spec);
	if (Specifications::is_new_variable_like(spec)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(kind_ref));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_RedundantThatVaries));
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
		Problems::quote_wording(2, Node::get_text(kind_ref));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyTooSpecific));
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
		Problems::quote_wording(2, Node::get_text(kind_ref));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyKindUnknown));
		Problems::issue_problem_segment(
			"You wrote %1, but '%2' is not the name of a kind of value which I know (such "
			"as 'number' or 'text').");
		Problems::issue_problem_end();
	}
	return;

@<Issue a problem message if the property kind is just "value"@> =
	if (Kinds::eq(K, K_value)) {
		if (prn == P_variable_initial_value) return;
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(kind_ref));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyKindVague));
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
	Problems::quote_wording(2, Node::get_text(kind_ref));
	Problems::quote_property(3, prn);
	Problems::quote_kind(4, current_kind);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyKindClashes));
	Problems::issue_problem_segment(
		"You wrote %1, but '%2' contradicts what I previously thought about the property "
		"%3, which was that it was %4.");
	Problems::issue_problem_end();
	return;
