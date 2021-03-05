[Assertions::] Assertions.

To infer facts about the model world, or take other action, based on sentences
asserted as being true in the source text.

@h Existential assertions.
These are very much simpler than coupling assertions, and the tree |py|
can contain only a common noun together with requirements on it: for
example, the subtree for "an open door".

=
void Assertions::make_existential(parse_node *py) {
	if (global_pass_state.pass == 1) {
		switch (Node::get_type(py)) {
			case WITH_NT:
				Assertions::make_existential(py->down);
				break;
			case AND_NT:
				Assertions::make_existential(py->down);
				Assertions::make_existential(py->down->next);
				break;
			case COMMON_NOUN_NT:
				if ((InferenceSubjects::is_a_kind_of_object(Node::get_subject(py))) ||
					(Kinds::eq(K_object, KindSubjects::to_kind(Node::get_subject(py)))))
					Assertions::Creator::convert_instance_to_nounphrase(py, NULL);
				else
					StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ThereIsVague),
						"'there is...' can only be used to create objects",
						"and not instances of other kinds.'");
				break;
		}
	}
}

@h Appearance assertions.
The "appearance" is not a property as such. When a quoted piece of text
is given as a whole sentence, it might be:

(a) the "description" of a room or thing;
(b) the title of the whole work, if at the top of the main source; or
(c) the rubric of the extension, or the additional credits for an extension,
if near the top of an extension file.

The title of the work is handled elsewhere, so we worry only about (a) and (c).

=
void Assertions::make_appearance(parse_node *p) {
	int wn = Wordings::first_wn(Node::get_text(p));
	if (global_pass_state.near_start_of_extension >= 1)
		@<This is rubric or credit text for an extension@>;

	inference_subject *infs = Anaphora::get_current_subject();
	if (infs == NULL) @<Issue a problem for appearance without object@>;

	parse_node *spec = Rvalues::from_wording(Wordings::one_word(wn));
	Properties::Appearance::infer(infs, spec);
}

@ The variable |global_pass_state.near_start_of_extension| is always 0 except
at the start of an extension (immediately after the header line), when it is set
to 1. The following increments it to 2 to allow for up to two quoted lines; the
first is the rubric, the second the credit line.

@<This is rubric or credit text for an extension@> =
	source_file *pos = Lexer::file_of_origin(wn);
	inform_extension *E = Extensions::corresponding_to(pos);
	if (E) {
		Word::dequote(wn);
		TEMPORARY_TEXT(txt)
		WRITE_TO(txt, "%W", Wordings::one_word(wn));
		switch (global_pass_state.near_start_of_extension++) {
			case 1: Extensions::set_rubric(E, txt); break;
			case 2: Extensions::set_extra_credit(E, txt);
				global_pass_state.near_start_of_extension = 0; break;
		}
		DISCARD_TEXT(txt)
	}
	return;

@<Issue a problem for appearance without object@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TextWithoutSubject),
		"I'm not sure what you're referring to",
		"that is, I can't decide to what room or thing you intend that text to belong. "
		"Perhaps you could rephrase this more explicitly? ('The description of the Inner "
		"Sanctum is...')");
	return;

@h Copula.
We now come to the main business, which is to act on "copula", that is,
couplings of two subtrees |px| and |py| representing things which are linked
by a copular verb. For example, in:

>> The white marble is a thing.

|px| would be the proper noun "white marble", |py| the common noun "thing",
and the sentence is telling is what kind of value something has.

It is usually said that "to be" is the only copular verb in English, but it
got that way by blurring together several quite different meanings: consider
"I am 5", "I am happy" and "I am Chloe". (In French, for example, one would
say "I have five".) The definition of "to be" occupies 12 columns of the
Oxford English Dictionary; most computer programming languages implement only
|=| and |==|, which correspond to OED's meaning 10, "to exist as the thing
known by a certain name; to be identical with". But Inform implements a much
broader set of meanings. For example, its distinction between spatial and
property knowledge reflects the OED's distinction between meanings 5a ("to
have or occupy a place somewhere") and 9b ("to have a place among the things
distinguished by a specified quality") respectively.

Besides that, we expand the range of possible copula by considering sentences
like:

>> The white marble is in the bamboo box.

as also being copula, but where |py| is now a |RELATIONSHIP_NT| subtree
expressing the sense of being inside the box.

So dealing with copula is not as simple as asserting that two things are
equal, and what we do falls into numerous cases.

@h The Matrix.
What we do depends in the first instance on the node types of the head nodes of
the |px| and |py| subtrees. We want to be sure that we completely understand
this process and that no possibilities escape notice; we therefore use a matrix
of possible cases, as follows. |py| specifies the row and |px| the column.

The record size of this matrix in Inform's history is $15\times 15$ with
58 numbered cases, but today there are "only" 42 cases in a $12\times 12$
grid. The cases are numbered upwards from 1, contiguously. There is no
significance to their ordering so far as the program's working is concerned;
but they are arranged in what seemed the best systematic way to group like
with like, by numbering from the top left to bottom right, and within each
cross-diagonal numbering from the centre outwards. The cases generally
increase in difficulty, with elementary syntax at the top left and quite
tricky semantics at the bottom right.

@d ASSERTION_MATRIX_DIM 12

=
typedef struct matrix_entry {
	node_type_t row_node_type;
	int cases[ASSERTION_MATRIX_DIM];
} matrix_entry;

matrix_entry assertion_matrix[ASSERTION_MATRIX_DIM] = {
                   /*  A,  W, XY,  K,  A, PL,  A,  A,  R,  E, CN, PN */
{ AND_NT,           {  1,  2,  1,  1,  1,  1,  1,  1,  1, 16,  1,  1 } },
{ WITH_NT,          {  3,  4,  3,  3,  3,  3,  3,  3, 14, 16,  3,  3 } },
{ X_OF_Y_NT,        {  5,  2,  6,  7,  9,  7,  7,  7, 20, 16, 23,  7 } },
{ KIND_NT,          {  5,  2,  8,  8,  9,  8,  8,  8,  8, 16,  8,  8 } },
{ ALLOWED_NT,       {  5,  2, 10, 10,  9, 10, 10, 10, 10, 25, 25, 25 } },
{ PROPERTY_LIST_NT, {  5,  2, 11, 12,  9, 18, 22, 19, 20, 16, 18, 18 } },
{ ADJECTIVE_NT,     {  5,  2, 13, 12,  9, 22, 22, 24, 20, 16, 29, 29 } },
{ ACTION_NT,        {  5,  2, 11, 19,  9, 19, 19, 27, 20, 16, 32, 32 } },
{ RELATIONSHIP_NT,  {  5, 15, 21, 20,  9, 20, 42, 20, 28, 31, 34, 36 } },
{ EVERY_NT,         { 17, 17, 17, 17, 17, 17, 17, 17, 17, 33, 17, 17 } },
{ COMMON_NOUN_NT,   {  5,  2, 11, 12,  9, 18, 30, 19, 35, 16, 38, 39 } },
{ PROPER_NOUN_NT,   {  5,  2, 26, 12,  9, 18, 30, 19, 37, 16, 40, 41 } } };

@ The following routine simply looks up which of the cases the current pair
of |px| and |py| falls into. Speed is not very important here.

=
int Assertions::which_assertion_case(parse_node *px, parse_node *py) {
	if (px == NULL) internal_error("make assertion with px NULL");
	if (py == NULL) internal_error("make assertion with py NULL");
	if ((Assertions::allow_node_type(px) == FALSE) ||
		(Assertions::allow_node_type(py) == FALSE)) {
		LOG("$T", px);
		LOG("$T", py);
		internal_error("make assertion with improper nodes");
	}
	int i, x=-1, y=-1;
	node_type_t wx = Node::get_type(px), wy = Node::get_type(py);
	if (wx == PRONOUN_NT) wx = PROPER_NOUN_NT;
	if (wy == PRONOUN_NT) wy = PROPER_NOUN_NT;
	for (i=0; i<ASSERTION_MATRIX_DIM; i++) {
		if (assertion_matrix[i].row_node_type == wx) x=i;
		if (assertion_matrix[i].row_node_type == wy) y=i;
	}
	if ((x<0) || (y<0)) {
		LOG("$T", px);
		LOG("$T", py);
		internal_error("make assertion with node type not in matrix");
	}
	return assertion_matrix[y].cases[x];
}

int Assertions::allow_node_type(parse_node *p) {
	VerifyTree::verify_structure_from(p);
	if (NodeType::has_flag(Node::get_type(p), ASSERT_NFLAG)) return TRUE;
	return FALSE;
}

@h Splitting into cases.

=
void Assertions::make_coupling(parse_node *px, parse_node *py) {
	LOG_INDENT;
	Assertions::make_assertion_recursive_inner(px, py);
	LOG_OUTDENT;
}

void Assertions::make_assertion_recursive_inner(parse_node *px, parse_node *py) {
	@<See if any plugin wants to intervene in this assertion@>;
	if (global_pass_state.pass == 2) @<Reject three forms of assertion@>;
	if (prevailing_mood == INITIALLY_CE) prevailing_mood = LIKELY_CE;

	int ma_case = Assertions::which_assertion_case(px, py);

	LOGIF(ASSERTIONS, "[%W/$N] =%d [%W/$N]\n",
		Node::get_text(px), Node::get_type(px), ma_case,
		Node::get_text(py), Node::get_type(py));

	@<Split the assertion-handler into cases@>;
}

@ If a plugin sees fit to throw a problem message, we abandon the assertion.

@<See if any plugin wants to intervene in this assertion@> =
	int pc = problem_count;
	if (PluginCalls::intervene_in_assertion(px, py)) return;
	if (problem_count > pc) return;

@ These are better taken care of before we split up into cases.

@<Reject three forms of assertion@> =
	if ((prevailing_mood == INITIALLY_CE) &&
		((Node::get_type(px) != PROPER_NOUN_NT) ||
			(Node::get_type(py) != PROPER_NOUN_NT))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MisplacedInitially),
			"you can only say 'initially' when creating variables using 'is'",
			"so 'The squirrel population is initially 0' is fine, but not "
			"'The acorn is initially carried by Mr Hedges.' - probably you "
			"only need to remove the word 'initially'.");
		return;
	}
	if ((prevailing_mood != UNKNOWN_CE) &&
		(Rvalues::is_CONSTANT_construction(Node::get_evaluation(px), CON_property) == FALSE) &&
		(Lvalues::is_actual_NONLOCAL_VARIABLE(Node::get_evaluation(px)) == FALSE) &&
		(Node::get_type(px) == PROPER_NOUN_NT)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_VagueAboutSpecific),
			"you can only equivocate with 'usually', 'rarely', "
			"'always' and the like when talking about kinds of thing",
			"because when a specific thing is involved you should say "
			"definitely one way or another. 'A cave is usually dark' is "
			"fine, but not 'the Mystic Wood is usually dark'.");
		return;
	}
	if (((Node::get_type(px) == COMMON_NOUN_NT)
		&& (Node::get_evaluation(px)) && (Annotations::read_int(px, multiplicity_ANNOT) > 1)
		&& (Node::get_type(py) != RELATIONSHIP_NT)) ||
		((Node::get_type(py) == COMMON_NOUN_NT)
		&& (Node::get_evaluation(py)) && (Annotations::read_int(py, multiplicity_ANNOT) > 1)
		&& (Node::get_type(px) != RELATIONSHIP_NT))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_MultiplyVague),
			"multiple objects can only be put into relationships",
			"by saying something like 'In the Drawing Room are two women.', "
			"and all other assertions with multiple objects are disallowed: "
			"so 'Three doors are open.' is rejected - I can't tell which three.");
		return;
	}

@ The case names here are systematic and were constructed from the above
matrix by a Perl script, in an attempt to ensure their truthfulness; but they're
just labels, so should they be wrong the only consequence is that the code
in this section will be harder to understand.

@<Split the assertion-handler into cases@> =
	switch(ma_case) {
        case 1: @<Case 1 - Miscellaneous vs AND@>; return;
        case 2: @<Case 2 - WITH vs Miscellaneous@>; return;
        case 3: @<Case 3 - Miscellaneous vs WITH@>; return;
        case 4: @<Case 4 - WITH on both sides@>; return;
        case 5: @<Case 5 - AND vs Miscellaneous@>; return;
        case 6: @<Case 6 - X OF Y on both sides@>; return;
        case 7: @<Case 7 - Miscellaneous vs X OF Y@>; return;
        case 8: @<Case 8 - Miscellaneous vs KIND@>; return;
        case 9: @<Case 9 - ALLOWED vs Miscellaneous@>; return;
        case 10: @<Case 10 - Miscellaneous vs ALLOWED@>; return;
        case 11: @<Case 11 - X OF Y vs PROPERTY LIST, ACTION, COMMON NOUN@>; return;
        case 12: @<Case 12 - KIND vs PROPERTY LIST, ADJECTIVE, COMMON NOUN, PROPER NOUN@>; return;
        case 13: @<Case 13 - X OF Y vs ADJECTIVE@>; return;
        case 14: @<Case 14 - RELATIONSHIP vs WITH@>; return;
        case 15: @<Case 15 - WITH vs RELATIONSHIP@>; return;
        case 16: @<Case 16 - EVERY vs Miscellaneous@>; return;
        case 17: @<Case 17 - Miscellaneous vs EVERY@>; return;
        case 18: @<Case 18 - PROPERTY LIST, COMMON NOUN, PROPER NOUN on both sides@>; return;
        case 19: @<Case 19 - ACTION, KIND, PROPERTY LIST, ADJECTIVE vs PROPERTY LIST, ACTION, COMMON NOUN, PROPER NOUN@>; return;
        case 20: @<Case 20 - Miscellaneous on both sides@>; return;
        case 21: @<Case 21 - X OF Y vs RELATIONSHIP@>; return;
        case 22: @<Case 22 - ADJECTIVE, PROPERTY LIST vs PROPERTY LIST, ADJECTIVE@>; return;
        case 23: @<Case 23 - COMMON NOUN vs X OF Y@>; return;
        case 24: @<Case 24 - ACTION vs ADJECTIVE@>; return;
        case 25: @<Case 25 - EVERY, COMMON NOUN, PROPER NOUN vs ALLOWED@>; return;
        case 26: @<Case 26 - X OF Y vs PROPER NOUN@>; return;
        case 27: @<Case 27 - ACTION on both sides@>; return;
        case 28: @<Case 28 - RELATIONSHIP on both sides@>; return;
        case 29: @<Case 29 - COMMON NOUN, PROPER NOUN vs ADJECTIVE@>; return;
        case 30: @<Case 30 - ADJECTIVE vs COMMON NOUN, PROPER NOUN@>; return;
        case 31: @<Case 31 - EVERY vs RELATIONSHIP@>; return;
        case 32: @<Case 32 - COMMON NOUN, PROPER NOUN vs ACTION@>; return;
        case 33: @<Case 33 - EVERY on both sides@>; return;
        case 34: @<Case 34 - COMMON NOUN vs RELATIONSHIP@>; return;
        case 35: @<Case 35 - RELATIONSHIP vs COMMON NOUN@>; return;
        case 36: @<Case 36 - PROPER NOUN vs RELATIONSHIP@>; return;
        case 37: @<Case 37 - RELATIONSHIP vs PROPER NOUN@>; return;
        case 38: @<Case 38 - COMMON NOUN on both sides@>; return;
        case 39: @<Case 39 - PROPER NOUN vs COMMON NOUN@>; return;
        case 40: @<Case 40 - COMMON NOUN vs PROPER NOUN@>; return;
        case 41: @<Case 41 - PROPER NOUN on both sides@>; return;
        case 42: @<Case 42 - ADJECTIVE vs RELATIONSHIP@>; return;
		default: LOG("Unimplemented assertion case %d\n", ma_case);
			internal_error("No implementation for make assertion case");
	}

@h Case 1. "A is B and C": process as "A is B" then "A is C".

@<Case 1 - Miscellaneous vs AND@> =
	parse_node *across = py->down;
	int np = problem_count;
	while (across) {
		if (np == problem_count) Assertions::make_coupling(px, across);
		across = across->next;
	}

@h Case 2.
"An A with I is B" looks symmetrical with case 3, but is not. We might be
looking at an implication, for example:

>> An open door is usually openable.

We allow this provided the properties I are all adjectival, and so is the
outcome B.

Otherwise we handle case 2 much like case 3, but more simply since the
result will normally be problem messages -- not unreasonably given how
strange sentences like this are:

>> A container with description "Solid." is the solid box.

@<Case 2 - WITH vs Miscellaneous@> =
	if ((Node::get_type(px->down) == COMMON_NOUN_NT) &&
		(Assertions::is_adjlist(px->down->next)) &&
		(Assertions::is_adjlist(py))) {
		Assertions::Implications::new(px, py);
	} else if ((Node::get_type(px->down) == PROPER_NOUN_NT) &&
		(Node::get_type(px->next) == COMMON_NOUN_NT)) {
		int np = problem_count;
		Assertions::make_coupling(px->down, py); /* A is B */
		if (problem_count == np)
			Assertions::make_coupling(px->down, px->down->next); /* A is I */
	} else {
		int np = problem_count;
		Assertions::make_coupling(px->down, py); /* A is B */
		if (problem_count == np)
			Assertions::make_coupling(px->down->next, py); /* I is B */
	}

@h Case 3.
"A is a B with I": process as "A is a B" followed by "A is I", which
works nicely because we bend grammar to allow "is" in place of "has" when
it comes to lists of property values.

>> The wickerwork box is a container with description "Pricy." The bat and ball are things with description "Cricket equipment." A trophy is a kind of container with score for finding 5.

An exception occurs with sentences like:

>> South is a dead end with printed name "Collapsed Dead End".

Here |px|, "south", refers not to the direction but to the room which lies
to the south of the location being talked about, which means that the printed
name must be given to the dead end, not to the direction "south". In this
case, on traverse 2 when properties are set, we process as "A is a B"
followed by "B is I". (On traverse 1, B is still an |COMMON_NOUN_NT| node,
since it hasn't yet been instantiated into an actual but nameless room --
at which point it becomes a |PROPER_NOUN_NT| node.)

@<Case 3 - Miscellaneous vs WITH@> =
	#ifdef IF_MODULE
	if ((Node::get_type(px) == PROPER_NOUN_NT) &&
		(Map::subject_is_a_direction(Node::get_subject(px))) &&
		(Node::get_type(py->down) == PROPER_NOUN_NT)) {
		int np = problem_count;
		Assertions::make_coupling(px, py->down); /* A is a B */
		if (problem_count == np)
			Assertions::make_coupling(py->down, py->down->next); /* B is I */
	} else {
	#endif
		int np = problem_count;
		Assertions::make_coupling(px, py->down); /* A is a B */
		if (problem_count == np)
			Assertions::make_coupling(px, py->down->next); /* A is I */
	#ifdef IF_MODULE
	}
	#endif

@h Case 4. "A with B is C with D" must be incorrect.

>> A container with description "White" is a container with description "Black".

@<Case 4 - WITH on both sides@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_WithIsWith),
		"you can't say that one general description is another ",
		"for instance by writing 'A container with carrying capacity 10 is a "
		"container with description \"Handy.\"'.");

@h Case 5. "A and B are C": process as "A is C" then "B is C".

@<Case 5 - AND vs Miscellaneous@> =
	parse_node *across = px->down;
	int np = problem_count;
	while (across) {
		if (np == problem_count) Assertions::make_coupling(across, py);
		across = across->next;
	}

@h Case 6. Now to begin on the |XOFY_NT| cases, which look syntactically
like properties.

@<Case 6 - X OF Y on both sides@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_XofYisZofW),
		"this seems to say two different properties are not simply equal "
		"but somehow the same thing",
		"like saying that 'the printed name of the millpond is the "
		"printed name of the village pond'. This puts me in a quandary: "
		"which should be changed to match the other, and what if I am "
		"unable to work out the value of either one?");

@h Case 7.

@<Case 7 - Miscellaneous vs X OF Y@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadXofY),
		"this is the wrong way around if you want to specify a property",
		"like saying that '10 is the score of the platinum pyramid', "
		"which is poor style. (Though sweet are the uses of adversity.)");

@h Case 8. "A is a kind of B". Much of the work has already been done at
refinement time. There are really four forms of this:

(a) "Length is a kind of value". Here |px| doesn't refer to an instance.
(b) "A figment is a kind". Here |px| refers to a possibly new-made kind,
and |py| refers to "kind".
(c) "A cart is a kind of vehicle". Ditto, and |py| refers to "vehicle".
(d) "A food is a kind of thing which is edible". Ditto, except |py| refers
of course to "thing", and also has a child node, containing a proposition
specifying its edibility.

@<Case 8 - Miscellaneous vs KIND@> =
	if (global_pass_state.pass == 2) return;
	if ((py->down) && (Node::get_type(py->down) == KIND_NT))
		@<Don't allow a kind of kind@>;
	if ((py->down) && (Node::get_type(py->down) == EVERY_NT))
		@<Don't allow a kind of everything@>;
	if (prevailing_mood != UNKNOWN_CE)
		@<Don't allow a kind declaration to have uncertainty@>;

	inference_subject *inst = Node::get_subject(px);
	inference_subject *kind_of_what = Node::get_subject(py);
	if (kind_of_what == NULL) internal_error("KIND node without subject");

	if ((InferenceSubjects::is_an_object(inst)) ||
		(InferenceSubjects::is_a_kind_of_object(inst))) {
		if ((KindSubjects::to_kind(inst) == FALSE) &&
			(InferenceSubjects::where_created(inst) != current_sentence))
			@<Don't allow an existing object to be declared as a kind over again@>;

		pcalc_prop *subject_to = NULL;
		if (py->down) {
			if (Node::get_type(py->down) == WITH_NT)
				subject_to = Node::get_creation_proposition(py->down);
			else
				subject_to = Specifications::to_proposition(Node::get_evaluation(py->down));
		}

		Propositions::Abstract::assert_kind_of_subject(inst, kind_of_what, subject_to);
		return;
	}

	@<Don't allow an existing property name to be redeclared as a kind@>;
	@<Don't allow any existing actual value to be redeclared as a kind@>;

@<Don't allow an existing object to be declared as a kind over again@> =
	Problems::quote_subject(1, inst);
	Problems::quote_source(2, current_sentence);
	Problems::quote_source(3, InferenceSubjects::where_created(inst));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_InstanceNowKind));
	Problems::issue_problem_segment(
		"You wrote '%2', but that seems to say that some "
		"room or thing already created ('%1', created by '%3') is now to "
		"become a kind. To prevent a variety of possible misunderstandings, "
		"this is not allowed: when a kind is created, the name given has "
		"to be a name not so far used. (Sometimes this happens due to "
		"confusion between names. For instance, if a room called 'Marble "
		"archway' exists, then Inform reads 'An archway is a kind of thing', "
		"Inform will read 'archway' as a reference to the existing room, "
		"not as a new name. To solve this, put the sentences the other way "
		"round.)");
	Problems::issue_problem_end();
	return;

@<Don't allow an existing property name to be redeclared as a kind@> =
	if (Node::get_type(px) == PROPER_NOUN_NT) {
		property *prn = Rvalues::to_property(
			Node::get_evaluation(px));
		if (prn) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_property(2, prn);
			Problems::quote_wording_as_source(3, prn->name);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindAsProperty));
			Problems::issue_problem_segment(
				"You wrote '%1', but that seems to say that a property "
				"(%3) has to be a kind as well. It is sometimes okay for a "
				"property to have the same name as a kind, but only when that "
				"kind is what it stores, and there shouldn't be a sentence "
				"like this one to declare the kind - it will be made when the "
				"property is made, and doesn't need to be made again.");
			Problems::issue_problem_end();
			return;
		}
	}

@<Don't allow any existing actual value to be redeclared as a kind@> =
	if (Node::get_type(px) == PROPER_NOUN_NT) {
		parse_node *val = Node::get_evaluation(px);
		if (Node::is(val, CONSTANT_NT)) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_kind_of(2, val);
			Problems::quote_wording_as_source(3, Node::get_text(px));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindAsActualValue));
			Problems::issue_problem_segment(
				"You wrote '%1', but that seems to say that a value already "
				"in existence (%3) has to be a kind as well. (It's %2.)");
			Problems::issue_problem_end();
			return;
		}
	}

@<Don't allow a kind of kind@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_KindOfKindDisallowed),
		"you aren't allowed to make new kinds of kinds",
		"only kinds of things which already exist. So 'A fox is a kind of animal' "
		"is fine, but 'A tricky kind is a kind of kind' isn't allowed.");
	return;

@<Don't allow a kind of everything@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_KindOfEveryDisallowed),
		"you aren't allowed to make a kind of everything",
		"or of everything matching a description. 'A badger is a kind of animal' "
		"is fine, but 'A gene is a kind of every animal' isn't allowed. (Probably "
		"you just need to get rid of the word 'every'.)");
	return;

@<Don't allow a kind declaration to have uncertainty@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_KindUncertainDisallowed),
		"you aren't allowed to make a kind in a way expressing certainty or doubt",
		"so 'A badger is a kind of animal' is fine, but 'A fungus is usually a "
		"kind of every animal' isn't allowed, and nor is 'A fern is never a kind "
		"of animal'. When you tell me about kinds, you have to tell me certainly.");
	return;

@h Case 9. This can be proven never to happen, but just in case:

@<Case 9 - ALLOWED vs Miscellaneous@> =
	internal_error("Forbidden case 9 in make assertion has occurred.");

@h Case 10. The syntax looks as if we are assigning a new property to something,
but it isn't a case where this would be legal. That doesn't mean it's hopeless:
this is where we assign variables to specific gadgets, which is in a way the
same thing.

>> The before rulebook has a text called the standard demurral.

@<Case 10 - Miscellaneous vs ALLOWED@> =
	if (Node::get_type(px) == KIND_NT)
		@<Issue the too vague to have properties or variables problem message@>
	else
		@<Issue the not allowed to have properties or variables problem message@>;

@h Case 11. This is a catch-all sort of error. It might need narrowing into
further sub-cases later.

>> The description of the Pitch is open.

@<Case 11 - X OF Y vs PROPERTY LIST, ACTION, COMMON NOUN@> =
	if (Node::get_type(py) == COMMON_NOUN_NT) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(py));
		Problems::quote_kind_of(3, Node::get_evaluation(py));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyObj2));
		Problems::issue_problem_segment(
			"In %1 you give a value of a property as '%2', but it "
			"seems to be a general description of a value (%3) rather than "
			"nailing down exactly what the value should be.");
		Problems::issue_problem_end();
		return;
	}
	#ifdef IF_MODULE
	if (Node::get_type(py) == ACTION_NT) {
		action_pattern *ap = Node::get_action_meaning(py);
		if (ap) {
			parse_node *val = Rvalues::from_action_pattern(ap);
			if (Rvalues::is_CONSTANT_of_kind(val, K_stored_action)) {
				Refiner::give_spec_to_noun(py, val);
				Assertions::make_coupling(px, py);
				return;
			}
		}
	}
	#endif
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_PeculiarProperty),
		"that is a very peculiar property value",
		"and ought to be something more definite and explicit.");

@h Case 12.

@<Case 12 - KIND vs PROPERTY LIST, ADJECTIVE, COMMON NOUN, PROPER NOUN@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_KindOfIs),
		"that seems to say that a new kind is the same as something else",
		"like saying 'A kind of container is a canister': which ought to be put the "
		"other way round, 'A canister is a kind of container'.");

@h Case 13. "The colour of the paint is white."

@<Case 13 - X OF Y vs ADJECTIVE@> =
	if (global_pass_state.pass == 1) return;
	unary_predicate *pred = Node::get_predicate(py);
	if (AdjectiveAmbiguity::has_enumerative_meaning(AdjectivalPredicates::to_adjective(pred))) {
		property *prn = ValueProperties::obtain(Node::get_text(px->down->next));
		if (Node::get_type(px->down) == WITH_NT) {
			Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_EOOwnerMutable),
				"either/or properties have to be given to clearly identifiable "
				"owners",
				"rather than to a collection of owners which might vary during "
				"play. (It is possible to get around this using 'implications', "
				"but it's better to avoid the need.)");
		} else {
			Refiner::turn_player_to_yourself(px->down);
			Assertions::PropertyKnowledge::assert_property_value_from_property_subtree_infs(prn,
				Node::get_subject(px->down), py);
		}
	} else {
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_NonAdjectivalProperty),
			"that property can't be used adjectivally as a value",
			"since it is an adjective applying to a thing but is "
			"not a name from a range of possibilities.");
	}

@h Case 14. "In A is a B with I": process as "In A is a B" followed by
"the newly created B is I".

>> In the Pitch is a container with description "Made of wood."

@<Case 14 - RELATIONSHIP vs WITH@> =
	Assertions::make_coupling(px, py->down);
	Assertions::make_coupling(py->down, py->down->next);

@h Case 15. "An A with I is in B": the mirror image case.

@<Case 15 - WITH vs RELATIONSHIP@> =
	Assertions::make_coupling(px->down, py);
	Assertions::make_coupling(px->down, px->down->next);

@h Case 16. "Every K is Y" and other oddities.

@<Case 16 - EVERY vs Miscellaneous@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadEvery),
		"'every' (or 'always') can't be used in that way",
		"and should be reserved for sentences like 'A coin is in every room'.");

@h Case 17. In fact one sentence like this can make sense -- "The mist is
everywhere", or similar -- but is handled by the spatial plugin, if active.
Even then, of course, "everywhere" implicitly means "in every room",
not "every room".

@<Case 17 - Miscellaneous vs EVERY@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadEvery2),
		"'every' can't be used in that way",
		"and should be reserved for sentences like 'A coin is in every room'.");

@h Case 18. This are unlikely to be called as a top-level sentence with "is",
but will instead occur through recursion from |WITH_NT| nodes, or as part of the
handling of "to have" rather than "to be".

Property lists may contain references to things not yet created, if we
assert them during pass 1: so we wait until pass 2.

The oddball exception for rulebooks is to add named outcomes:

>> Reaching inside rules have outcomes allow access (success) and deny access (failure).

which syntactically resembles a property list, though in fact is not.

@<Case 18 - PROPERTY LIST, COMMON NOUN, PROPER NOUN on both sides@> =
	if (global_pass_state.pass == 1) return;
	if ((Node::get_type(px) == PROPER_NOUN_NT) &&
		(Rvalues::is_CONSTANT_construction(Node::get_evaluation(px), CON_rulebook))) {
		Rulebooks::parse_properties(Rvalues::to_rulebook(Node::get_evaluation(px)),
			Wordings::new(Node::left_edge_of(py), Node::right_edge_of(py)));
		return;
	}
	if (Node::get_type(px) == PROPERTY_LIST_NT) Assertions::PropertyKnowledge::assert_property_list(py, px);
	else Assertions::PropertyKnowledge::assert_property_list(px, py);

@h Case 19. This usually occurs as a name-clash, since it's otherwise something
pretty improbable:

>> Taking something is 100. The turn count is taking something.

@<Case 19 - ACTION, KIND, PROPERTY LIST, ADJECTIVE vs PROPERTY LIST, ACTION, COMMON NOUN, PROPER NOUN@> =
	if (Node::get_subject(py))
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ActionEquated),
			"an action can't be the same as a thing",
			"so my guess is that this is an attempt to categorise an action which went "
			"wrong because there was already something of that name in existence. For "
			"instance, 'Taking something is theft' would fail if 'theft' was already a "
			"value. (But it can also happen with a sentence which tries to set several "
			"actions at once to a named kind of action, like 'Taking and dropping are "
			"manipulation.' - only one can be named at a time.)");
	else
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ActionEquated2),
			"that means something else already",
			"so it will only confuse things if we use it for a kind of action.");

@h Case 20. Hoovering up a variety of implausible things claimed to have
a spatial location.

>> On the desk is 100. East of the Pitch is a rulebook.

@<Case 20 - Miscellaneous on both sides@> =
	if (Refiner::turn_player_to_yourself(px)) { Assertions::make_coupling(px, py); return; }
	if (Refiner::turn_player_to_yourself(py)) { Assertions::make_coupling(px, py); return; }
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_IntangibleRelated),
		"this seems to give a worldly relationship to something intangible",
		"like saying that 'in the box is a text'. Perhaps it came "
		"to this because you gave something physical a name which was "
		"accidentally something meaningful to me in another context? "
		"If so, you may be able to get around it by rewording ('In the "
		"box is a medieval text') or in extremis by using 'called' "
		"('In the box is a thing called text').");

@h Case 21.

>> The position of the weathervane is east of the church.

@<Case 21 - X OF Y vs RELATIONSHIP@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_XofYRelated),
		"this seems to say that a property of something is not simply equal "
		"to what happens at the moment to satisfy some relationship, but "
		"conceptually the same as that relationship",
		"like saying 'the position of the weathervane is east of the "
		"church'. It would be fine to say 'the position of the weathervane "
		"is east' or 'the position of the weathervane is the meadow', "
		"because 'east' and 'meadow' are definite things.");

@h Case 22. Most of the time, we're here because of an implicatory sentence like:

>> Scenery is usually fixed in place.

But just maybe we have something like

>> Guttering is inadequate.

where we are assigning a property ("inadequate") to a value ("guttering")
which can be used as an adjective, but isn't being so used here. So if it's
possible to coerce the left side to a noun, we will.

@<Case 22 - ADJECTIVE, PROPERTY LIST vs PROPERTY LIST, ADJECTIVE@> =
	Refiner::nominalise_adjective(px);
	if (Node::get_type(px) == PROPER_NOUN_NT) {
		Assertions::make_coupling(px, py);
		return;
	}
	if (global_pass_state.pass == 2) Assertions::Implications::new(px, py);

@h Case 23. And so on.

@<Case 23 - COMMON NOUN vs X OF Y@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_DescriptionIsOther),
		"this seems to say that a general description is something else",
		"like saying that 'a door is 20'.");

@h Case 24. Not as unlikely a mistake as it might seem:

>> Taking something is open.

@<Case 24 - ACTION vs ADJECTIVE@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ActionAdjective),
		"that is already the name of a property",
		"so it will only confuse things if we use it for a kind of action.");

@h Case 25. Here we are declaring a new property -- either to an object, a kind
or a kind of value.

>> A container has a number called security rating.

@<Case 25 - EVERY, COMMON NOUN, PROPER NOUN vs ALLOWED@> =
	if (Refiner::turn_player_to_yourself(px)) {
		Assertions::make_coupling(px, py); return;
	}
	parse_node *spec = Node::get_evaluation(px);
	if ((Node::get_subject(px) == NULL) &&
		(Rvalues::is_CONSTANT_construction(spec, CON_property))) {
		property *prn = Node::get_constant_property(spec);
		if ((prn) && (ValueProperties::coincides_with_kind(prn))) {
			kind *K = ValueProperties::kind(prn);
			Node::set_type_and_clear_annotations(px, COMMON_NOUN_NT);
			Node::set_subject(px, KindSubjects::from_kind(K));
			Node::set_evaluation(px, Specifications::from_kind(K));
		}
	}

	if (Node::get_subject(px) == NULL) {
		kind *K = Specifications::to_kind(spec);
		if (Node::is(spec, CONSTANT_NT)) {
			if (PluginCalls::offered_property(K, spec, py->down)) return;
			if (Kinds::get_construct(K) == CON_activity) @<Assign a new activity variable@>;
			if (Kinds::get_construct(K) == CON_rulebook) @<Assign a new rulebook variable@>;
		}
		@<Issue the not allowed to have properties or variables problem message@>;
	}
	if (global_pass_state.pass == 1) NewPropertyAssertions::recursively_declare(px, py->down);

@ Activities can optionally be referred to without the clarifier "activity",
but not in this context.

@<Assign a new activity variable@> =
	activity *av = Rvalues::to_activity(spec);
	if (av == NULL) internal_error("failed to extract activity structure");
	if (global_pass_state.pass == 2) {
		if (<activity-name-formal>(Node::get_text(px)))
			Activities::add_variable(av, py->down);
		else
			Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadActivityRef),
				"an activity has to be formally referred to in a way making clear that "
				"it is indeed a rulebook when we give it named values",
				"to reduce the risk of ambiguity. So 'The printing the banner text "
				"activity has a number called the accumulated vanity' is fine, but "
				"'Printing the banner text has a number called...' is not. (I'm "
				"insisting on the presence of the word 'activity' because the "
				"syntax is so close to that for giving properties to objects, and "
				"it's important to avoid mistakes here.)");
	}
	return;

@ And similarly for rulebooks.

@<Assign a new rulebook variable@> =
	rulebook *rb = Rvalues::to_rulebook(spec);
	if (rb == NULL) internal_error("failed to extract rulebook structure");
	if (global_pass_state.pass == 2) {
		if (<rulebook-name-formal>(Node::get_text(px)))
			Rulebooks::add_variable(rb, py->down);
		else
			Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadRulebookRef),
				"a rulebook has to be formally referred to in a way making clear that "
				"it is indeed a rulebook when we give it named values",
				"to reduce the risk of ambiguity. So 'The every turn rulebook has a "
				"number called the accumulated bonus' is fine, but 'Every turn has a "
				"number called...' is not. (I'm insisting on the presence of the word "
				"'rulebook' because the syntax is so close to that for giving "
				"properties to objects, and it's important to avoid mistakes here.)");
	}
	return;

@<Issue the too vague to have properties or variables problem message@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_TooVagueForVariables),
		"this is too vague a description of the owner of the property",
		"so that I don't know where to put this. Something like 'A person "
		"has a number called age' is fine, but 'A kind has a number called "
		"age' is not. Which kind?");

@<Issue the not allowed to have properties or variables problem message@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_HasNoVariables),
		"only an object, kind, rulebook, action or activity can be allowed to have "
		"properties or variables",
		"so for instance 'A door has a colour' is fine but not 'A number has a length'.");
	return;

@h Case 26. At last, a correctly set property value.

>> The description of the Pitch is "Verdant." The desk is a container. The carrying capacity of the desk is 10.

Property assignments fall into three sorts, which we handle in this order:
(i) The specification pseudo-property, which looks syntactically like a property
but in fact isn't one;
(ii) Properties of values and kinds of value;
(iii) Properties of objects and kinds of object.

@<Case 26 - X OF Y vs PROPER NOUN@> =
	if (global_pass_state.pass == 1) return;
	Refiner::turn_player_to_yourself(px->down);
	if (<negated-clause>(Node::get_text(py))) {
		StandardProblems::negative_sentence_problem(Task::syntax_tree(), _p_(PM_NonValue)); return;
	}

	parse_node *owner = Node::get_evaluation(px->down);
	property *prn = ValueProperties::obtain(Node::get_text(px->down->next));
	if (prn == P_specification) @<We're setting the specification pseudo-property@>;
	Refiner::nominalise_adjective(px->down);

	if ((Node::get_type(px->down) == PROPER_NOUN_NT) ||
		(Node::get_type(px->down) == COMMON_NOUN_NT)) {
		inference_subject *owner_infs = Node::get_subject(px->down);
		if (owner_infs == NULL) {
			if (<k-kind>(Node::get_text(px->down)))
				owner_infs = KindSubjects::from_kind(<<rp>>);
		}
		if ((Specifications::is_description(owner)) &&
			(Specifications::is_kind_like(owner) == FALSE))
			@<Issue a problem message for setting a property of an overspecified object@>
		else if (owner_infs)
			Assertions::PropertyKnowledge::assert_property_value_from_property_subtree_infs(prn, owner_infs, py);
		else @<Issue a problem message for setting a property of something never having them@>;
		return;
	}

	@<Issue a problem message for setting a property of something not owning one@>;

@ This handles sentences like:

>> The specification of vehicle is "A kind of thing able to move between rooms."

Specification is not a real property and has no existence at run-time; it's used
only to annotate the Index. For the most part it's set the way all other properties
are set, but exceptions are made for action names (which otherwise don't have
properties) and for kinds (which do, but differently).

@<We're setting the specification pseudo-property@> =
	wording W = Node::get_text(py);
	@<Extract the raw text of a specification@>;
	if (Specifications::is_kind_like(owner)) {
		kind *K = Specifications::to_kind(owner);
		if (Kinds::Behaviour::is_subkind_of_object(K) == FALSE) {
			TEMPORARY_TEXT(st)
			WRITE_TO(st, "%+W", Wordings::one_word(Wordings::first_wn(W)));
			Kinds::Behaviour::set_specification_text(K, st);
			DISCARD_TEXT(st)
			return;
		}
	} else if (PluginCalls::offered_specification(owner, W)) {
		return;
	} else if (Node::get_type(px->down) != COMMON_NOUN_NT) {
		LOG("$T\n", current_sentence);
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_Unspecifiable),
			"this tries to set specification text for a particular value",
			"rather than a kind of value. 'Specification' is a special property used "
			"only to annotate the Index, and it makes no sense to set this property for "
			"anything other than a kind of value, a kind of object or an action.");
		return;
	}

@<Extract the raw text of a specification@> =
	if ((<s-literal>(W)) && (Rvalues::is_CONSTANT_of_kind(<<rp>>, K_text))) {
		Word::dequote(Wordings::first_wn(W));
	} else {
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_SpecNotText),
			"this tries to set a specification to something other than literal quoted text",
			"which will not work. 'Specification' is a special property used only to "
			"annotate the Index, and specifically the Kinds index, so it makes no sense to "
			"set this property to anything other than text.");
		return;
	}

@<Issue a problem message for setting a property of an overspecified object@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_OverspecifiedSpec),
		"this tries to set a property for something more complicated than a single thing "
		"named without qualifications",
		"and that isn't allowed. For instance, 'The description of the Great Portal is "
		"\"It's open.\"' is fine, but 'The description of the Great Portal in the Palace "
		"is \"It's open.\"' is not allowed, because it tries to qualify 'Great Portal' "
		"with the extra clause 'in the Palace'. (If you need to make a description which "
		"changes based on where something is, or where it is seen from, try using text "
		"substitutions.)");

@<Issue a problem message for setting a property of something never having them@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_BadInferenceSubject),
		"this tries to set a property for a value which can't have properties",
		"and that isn't allowed. For instance, 'The description of the Great Portal is "
		"\"It's open.\"' would be fine, if Great Portal were a room, but 'The description "
		"of 6 is \"Sixish.\"' would not, because the number 6 isn't allowed to have "
		"properties.");

@<Issue a problem message for setting a property of something not owning one@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_GeneralitySpec),
		"this tries to set a property for a complicated generality of items all at once",
		"which can lead to ambiguities. For instance, 'The description of an open door "
		"is \"It's open.\"' is not allowed: if we followed Inform's normal conventions "
		"strictly, that would be an instruction to create a new, nameless, open door and "
		"give it the description. But this is very unlikely to be what the writer "
		"intended, given the presence of the adjective to make it seem as if a particular "
		"door is meant. So in fact we reject such sentences unless they refer only to a "
		"kind, without adjectives: 'The description of a door is \"It's a door.\"' is "
		"fine. (If the idea is actually to make the description change in play, we could "
		"write a rule like 'Instead of examining an open door, say \"It's open.\"'; or "
		"we could set the description of every door to \"[if open]It's open.[otherwise]It's "
		"closed.\".)");

@h Case 27. Beginning some cases to do with actions...

@<Case 27 - ACTION on both sides@> =
	if (global_pass_state.pass == 1) return;
	#ifdef IF_MODULE
	action_pattern *apx = Node::get_action_meaning(px);
	action_pattern *apy = Node::get_action_meaning(py);
	if ((ActionPatterns::is_valid(apy)) &&
		(ActionPatterns::is_named(apy) == FALSE)) {
		LOG("Actions: $A and $A\n", apx, apy);
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ActionsEquated),
			"two actions are rather oddly equated here",
			"which would only make sense if the second were a named pattern of actions "
			"like (say) 'unseemly behaviour'.");
	} else NamedActionPatterns::characterise(apx, Node::get_text(py));
	#endif

@h Case 28. Sentence (1) below is deservedly rejected, but (2) makes a
non-reciprocal map connection: "D of the R is E of the S" is construed as
"D of the R is S" then "R is E of the S". We have to suppress Inform's
tendency to make tentative reciprocal map connections, because even though
they will only be listed as "likely", we know they are in fact impossible
in this case.

>> (1) In the box is on the desk. (2) East of the Pitch is north of the Pavilion.

@<Case 28 - RELATIONSHIP on both sides@> =
	#ifdef IF_MODULE
	if ((MapRelations::get_mapping_relationship(px)) &&
		(MapRelations::get_mapping_relationship(py))) {
		Map::enter_one_way_mode();
		Assertions::make_coupling(px, py->down);
		Assertions::make_coupling(px->down, py);
		Map::exit_one_way_mode();
		return;
	}
	#endif

	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_RelationsEquated),
		"this says that two different relations are the same",
		"like saying that 'in the box is on the table'. (Sometimes this "
		"happens if I misinterpret names of places like 'In Prison' or "
		"'East of Fissure'.)");

@h Case 29. Equating something to a single adjective.

>> The desk is fixed in place. A container is usually fixed in place.

@<Case 29 - COMMON NOUN, PROPER NOUN vs ADJECTIVE@> =
	Refiner::turn_player_to_yourself(px);
	if (global_pass_state.pass == 2) Assertions::PropertyKnowledge::assert_property_list(px, py);

@h Case 30. I am in two minds about the next nit-picking error message.
But really this is a device used in English only for declamatory purposes
or comedic intent. (As in Peter Schickele's spoof example of an 18th-century
opera about a dog, "Collared Is Bowser".)

@<Case 30 - ADJECTIVE vs COMMON NOUN, PROPER NOUN@> =
	if (Node::get_subject(py))
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_AdjectiveIsObject),
			"that seems to say that an adjective is a noun",
			"like saying 'Open are the doubled doors': which I'm picky about, preferring "
			"it written the other way about ('The doubled doors are open'). Less poetic, "
			"but clearer style.");
	else
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_AdjectiveIsValue),
			"that suggests that an adjective has some sort of value",
			"like saying 'Open is a number' or 'Scenery is 5': but of course an adjective "
			"represents something which is either true or false.");

@h Case 31. "Every K is in L."

@<Case 31 - EVERY vs RELATIONSHIP@> =
	if (Diagrams::is_possessive_RELATIONSHIP(py)) {
		if (<k-kind>(Node::get_text(py->down))) {
			Node::set_type(py, ALLOWED_NT);
			Node::set_type(py->down, UNPARSED_NOUN_NT);
			Assertions::make_coupling(px, py);
			return;
		}
		Assertions::make_coupling(px, py->down);
		return;
	}
	if (global_pass_state.pass == 1) Assertions::Assemblies::make_generalisation(px, py);

@h Case 32. A problem message issued purely on stylistic grounds.

@<Case 32 - COMMON NOUN, PROPER NOUN vs ACTION@> =
	if ((Node::get_subject(px)) && (KindSubjects::to_kind(Node::get_subject(px)))) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_source(2, py);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindIsAction));
		Problems::issue_problem_segment(
			"You wrote %1: unfortunately %2 is already the name of an action, "
			"and it would only confuse things if we used it for a value as well.");
		Problems::issue_problem_end();
	} else {
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ObjectIsAction),
			"that is putting the definition back to front",
			"since I need these categorisations of actions to take the form 'Kissing a "
			"woman is love', not 'Love is kissing a woman'. (This is really because it "
			"is better style: love might be many other things too, and we don't want to "
			"imply that the present definition is all-inclusive.)");
	}

@h Case 33. "Every K is every L."

@<Case 33 - EVERY on both sides@> =
	Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_EveryEquated),
		"I can't do that", "Dave.");

@h Case 34. The "Genevieve" problem message is a finicky stylistic one, and
it I suspect it may be disliked. I've always been in two minds about whether
this ought to be allowed...

>> An animal is in the desk.

@<Case 34 - COMMON NOUN vs RELATIONSHIP@> =
	@<Possession of something is allowed@>;
	@<Generalised relationships are allowed@>;
	@<Multiple objects in a relationship are allowed@>;
	@<Certain non-spatial relationships are allowed too@>;
	@<There is... relationships are allowed too@>;

	if (prevailing_mood == CERTAIN_CE) {
		Node::set_subject(px,
			KindSubjects::from_kind(
				Specifications::to_kind(
					Node::get_evaluation(px))));
		Node::set_type(px, EVERY_NT);
		Assertions::make_coupling(px, py);
		return;
	}

	if (Kinds::Behaviour::is_object(Specifications::to_kind(Node::get_evaluation(px))))
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_KindRelated),
			"something described only by its kind should not be given a "
			"specific place or role in the world",
			"to avoid ambiguity. For instance, suppose 'car' is a kind. Then "
			"we are not allowed to say 'a car is in the garage': there's too "
			"much risk of confusion between whether an individual (but "
			"nameless) car is referred to, or whether cars are generically to "
			"be found there. Sentences of this form are therefore prohibited, "
			"though more specific ones like 'a car called Genevieve is in the "
			"garage' are fine, as is the reverse, 'In the garage is a car.'");
	else
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_KOVRelated),
			"this seems to give a worldly relationship to something intangible",
			"possibly due to an accidental clash of names between a kind of "
			"value and something in the real world. "
			"I sometimes read sentences like 'There is a number on the "
			"door' or 'A text is in the prayer-box' literally - thinking "
			"you mean a whole number or a piece of double-quoted text, and "
			"not realising you intended to make a brass number-plate or "
			"an old book. If that's the trouble, you can use 'called': "
			"for instance, 'In the prayer-box is a thing called the text.'");

@

@<Possession of something is allowed@> =
	if (Diagrams::is_possessive_RELATIONSHIP(py)) {
		if (<k-kind>(Node::get_text(py->down))) {
			Node::set_type(py, ALLOWED_NT);
			Node::set_type(py->down, UNPARSED_NOUN_NT);
			Assertions::make_coupling(px, py);
			return;
		}
		Assertions::make_coupling(px, py->down);
		return;
	}

@ For example,

>> An animal is in every desk.

@<Generalised relationships are allowed@> =
	if ((py->down) && (Node::get_type(py->down) == EVERY_NT)) {
		if (global_pass_state.pass == 1) Assertions::Assemblies::make_generalisation(py, px);
		return;
	}

@ For example,

>> Six animals are in the desk.

Note that the default multiplicity is 0, not 1; saying "one door" has a
slightly different meaning from simply saying "a door", since it clarifies
that we're discussing a number of actual objects, not the category of doors
in general.

@<Multiple objects in a relationship are allowed@> =
	if (Annotations::read_int(px, multiplicity_ANNOT) >= 1) {
		Assertions::Creator::convert_instance_to_nounphrase(px, NULL);
		Assertions::make_coupling(py, px);
		return;
	}

@ Further exceptions are made for sentences like:

>> A chair usually allows sitting. A thing usually weighs 1kg.

@<Certain non-spatial relationships are allowed too@> =
	binary_predicate *bp = Node::get_relationship(py);
	if ((bp) && ((SettingPropertyRelations::bp_sets_a_property(bp)) ||
		(Relations::Explicit::relates_values_not_objects(bp)))) {
		if (global_pass_state.pass == 2) Assertions::Relational::assert_subtree_in_relationship(px, py);
		return;
	}

@ And also for "There is..." sentences:

>> There is a coin in the strongbox.

@<There is... relationships are allowed too@> =
	if (Annotations::read_int(current_sentence->down, sentence_is_existential_ANNOT)) {
		Assertions::Creator::convert_instance_to_nounphrase(px, NULL);
		Assertions::make_coupling(py, px);
		return;
	}

@h Case 35.

>> In the desk is a copy of Wisden. On the table is a container.

@<Case 35 - RELATIONSHIP vs COMMON NOUN@> =
	if ((px->down) && (Node::get_type(px->down) == EVERY_NT)) {
		if (global_pass_state.pass == 1) Assertions::Assemblies::make_generalisation(px, py);
	} else {
		Assertions::Creator::convert_instance_to_nounphrase(py, Node::get_relationship(px));
		Assertions::make_coupling(px, py);
	}

@h Case 36. "A box is on the table." This makes "box" the subject of
discussion. "The Gazebo is west of the Lawn" also falls into this case,
since "west of the Lawn" parses to a |RELATIONSHIP_NT| subtree.

@<Case 36 - PROPER NOUN vs RELATIONSHIP@> =
	if (Refiner::turn_player_to_yourself(px)) {
		Assertions::make_coupling(px, py); return;
	}
	if (Diagrams::is_possessive_RELATIONSHIP(py)) {
		if (<k-kind>(Node::get_text(py->down))) {
			Node::set_type(py, ALLOWED_NT);
			Node::set_type(py->down, UNPARSED_NOUN_NT);
			Assertions::make_coupling(px, py);
			return;
		}
		Assertions::make_coupling(px, py->down);
		return;
	}
	Assertions::instantiate_related_common_nouns(py);
	if (global_pass_state.pass == 2) Assertions::Relational::assert_subtree_in_relationship(px, py);

@h Case 37. "On the table is a box." A mirror image, handling the inversion.

@<Case 37 - RELATIONSHIP vs PROPER NOUN@> =
	if (Refiner::turn_player_to_yourself(py)) { Assertions::make_coupling(px, py); return; }
	Assertions::instantiate_related_common_nouns(px);
	if (global_pass_state.pass == 2) Assertions::Relational::assert_subtree_in_relationship(py, px);

@h Case 38. "A door is a vehicle." This one's never legal; you can't equate
two whole domains. (We have the "kind of..." syntax instead.)

@d NAME_DESCRIPTION_CLASH_NOTE
	"Sometimes this happens because I've read too much into a name - for instance, "
	"'A dark room is a room' makes me read 'dark room' as 'dark' (an adjective I know) "
	"plus 'room', but maybe the writer actually meant a photographer's workshop. "
	"If you need to call something by a name which confuses me, one way is to use "
	"'called': for instance, 'West is a room called the dark room.' Another way is "
	"to call it something else here, and set the 'printed name' property to what you "
	"want the player to see - for instance, 'The photo lab is a room. The printed name "
	"of the photo lab is \"dark room\".'"

@<Case 38 - COMMON NOUN on both sides@> =
	@<Produce a problem if two values that vary are equated@>;
	@<Issue a problem for a namespace clash between a variable name and a kind@>;
	inference_subject *left_object = Node::get_subject(px);
	inference_subject *right_kind = Node::get_subject(py);
	Problems::quote_source(1, current_sentence);
	Problems::quote_subject(2, left_object);
	Problems::quote_subject(3, right_kind);
	if (left_object == right_kind) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SameKindEquated));
		Problems::issue_problem_segment(
			"The sentence %1 seems to be telling me that two descriptions, "
			"both forms of %2, are the same. That's a little puzzling - "
			"like saying that 'An open container is a container.' %P"
			NAME_DESCRIPTION_CLASH_NOTE);
		Problems::issue_problem_end();
	} else {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_DescriptionsEquated));
		Problems::issue_problem_segment(
			"The sentence %1 seems to be telling me that two descriptions, "
			"one a form of %2 and the other of %3, are the same. That's a "
			"little puzzling - like saying that 'An open door is a container.' %P"
			NAME_DESCRIPTION_CLASH_NOTE);
		Problems::issue_problem_end();
	}

@ For example,

>> A number that varies is a text that varies.

@<Produce a problem if two values that vary are equated@> =
	if ((Specifications::is_new_variable_like(Node::get_evaluation(px))) &&
		(Specifications::is_new_variable_like(Node::get_evaluation(py)))) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(px));
		Problems::quote_wording(3, Node::get_text(py));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_VariablesEquated));
		Problems::issue_problem_segment(
			"The sentence %1 seems to tell me that '%2', which describes "
			"a kind of variable, is the same as '%3', another description "
			"of a kind of variable - but that doesn't make sense to me. "
			"(Perhaps you intended one of these to be a specific variable, "
			"but chose a wording which looked accidentally like a "
			"general description?)");
		Problems::issue_problem_end();
		return;
	}

@<Issue a problem for a namespace clash between a variable name and a kind@> =
	if (Specifications::is_new_variable_like(Node::get_evaluation(py))) {
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_VarKOVClash),
			"the name supplied for this new variable is a piece of text "
			"which is not available because it has a rival meaning already",
			"as a result of definitions made elsewhere. (Sometimes these "
			"are indirect: for instance, defining a column in a table "
			"called 'question' can make a name like 'container in question' "
			"suddenly ambiguous and thus unsuitable to be a variable "
			"name.) If you're getting this Problem message in the Standard "
			"Rules or some other extension you need to use, then your "
			"only option is to hunt through your own source text to see "
			"what you have defined which might cause this clash.");
		return;
	}

@h Case 39. Sentences falling into this case have the form "X is a Y."; for
instance,

>> The lacquered box is a container.

It might look as if

>> A dead end is a kind of room. The Pitch is a room. East is a dead end.

would throw the last sentence into this case, which would be wrong, but we
avoid this by having the IF model code intervene. (Clearly this is a quirk
only occurring when we have named directions, an IF-like thing.)

It's usually plain wrong to say that a value has a given kind, because the value
has already been defined and its kind is long since established. (But we do
allow one case, where the declaration is redundant and harmless.)

@<Case 39 - PROPER NOUN vs COMMON NOUN@> =
	if ((InferenceSubjects::is_an_object(Node::get_subject(px))) ||
		(InferenceSubjects::is_a_kind_of_object(Node::get_subject(px)))) {
		if ((Node::get_subject(py) != KindSubjects::from_kind(K_object)) &&
			(InferenceSubjects::is_a_kind_of_object(Node::get_subject(py)) == FALSE))
			Assertions::issue_value_equation_problem(px, py);
		else @<Assert that X is an instance of Y@>;
		return;
	}
	parse_node *g_spec = Node::get_evaluation(py);
	parse_node *a_spec = Node::get_evaluation(px);
	kind *g_kind = Specifications::to_kind(g_spec);
	if (Specifications::is_new_variable_like(g_spec))
		g_kind = Specifications::kind_of_new_variable_like(g_spec);
	kind *a_kind = Specifications::to_kind(a_spec);
	int var_set = FALSE;
	if ((Rvalues::to_instance(a_spec)) ||
		(Lvalues::get_storage_form(a_spec) == NONLOCAL_VARIABLE_NT)) {
		var_set = TRUE;
		if (Specifications::is_new_variable_like(g_spec))
			@<We're declaring the kind of the variable, not setting its value@>;
	}

	if (((Specifications::is_kind_like(g_spec)) ||
			(Specifications::is_new_variable_like(g_spec)) ||
			(Specifications::is_description(g_spec)))
		&& (a_kind)) {
		if (Kinds::eq(a_kind, g_kind))
			@<This sentence redundantly specifies the kind of value for a value@>;
		if (Kinds::get_construct(a_kind) == CON_description)
			@<Issue problem for trying to use a description as a literal@>;
	}
	if (var_set == FALSE) @<Dabble further in ruthless sarcasm@>;

	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(px));
	Problems::quote_kind_of(3, a_spec);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ChangedKind));
	Problems::issue_problem_segment(
		"Before reading %1, I already knew that '%2' is %3, "
		"and it is too late to change now.");
	Problems::issue_problem_end();

@ For example,

>> The current prize value is a number that varies.

We silently allow the kind of a variable to be restated or narrowed, but not
contradicted.

@<We're declaring the kind of the variable, not setting its value@> =
	nonlocal_variable *nlv =
	Node::get_constant_nonlocal_variable(Node::get_evaluation(px));
	parse_node *val = Node::get_evaluation(py);
	kind *kind_as_declared = NonlocalVariables::kind(nlv);
	kind *constant_kind = Specifications::to_kind(val);
	if (Specifications::is_new_variable_like(val))
		constant_kind = Specifications::kind_of_new_variable_like(val);
	if (Kinds::conforms_to(constant_kind, kind_as_declared) == FALSE) {
		LOG("%u, %u\n", kind_as_declared, constant_kind);
		Problems::quote_source(1, current_sentence);
		if (nlv)
			Problems::quote_wording(2, nlv->name);
		else
			Problems::quote_wording(2, Node::get_text(px));
		Problems::quote_kind(3, constant_kind);
		if (nlv)
			Problems::quote_kind(4, kind_as_declared);
		else
			Problems::quote_kind(4, Specifications::to_kind(Node::get_evaluation(px)));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_GlobalRedeclared));
		Problems::issue_problem_segment(
			"The sentence %1 seems to tell me that '%2', which has already been "
			"declared as %4, is instead %3 - but that would be a contradiction.");
		Problems::issue_problem_end();
	} else {
		if (Kinds::eq(kind_as_declared, constant_kind) == FALSE)
			NonlocalVariables::set_kind(nlv, constant_kind);
	}
	return;

@ We allow redundant declarations, except for numbers, where we are
sarcastic because the information is so obvious that it must be a mistake.
In the case of texts, we cause the text to be compiled into the I6 story
file: this may possibly be useful to I6 hackers.

@<This sentence redundantly specifies the kind of value for a value@> =
	if ((var_set == FALSE) && (Kinds::eq(a_kind, K_number))) {
		Problems::quote_source(1, current_sentence);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_Sarcasm1));
		Problems::issue_problem_segment(
			"%1: Grateful as I generally am for your guidance, "
			"I think perhaps I could manage without this sentence.");
		Problems::issue_problem_end();
	}
	if ((var_set == FALSE) && (Kinds::eq(a_kind, K_text))) {
		TextLiterals::compile_literal(NULL, TRUE, Node::get_text(px));
	}
	return;

@ My, aren't we charming?

@<Dabble further in ruthless sarcasm@> =
	if (Kinds::eq(a_kind, K_number)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(px));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_Sarcasm2));
		Problems::issue_problem_segment("%1: That, sir, is a damnable lie. '%2' is a number.");
		Problems::issue_problem_end();
		return;
	}
	if (Kinds::eq(a_kind, K_text)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(px));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_Sarcasm3));
		Problems::issue_problem_segment("%1: And I am the King of Siam. '%2' is some text.");
		Problems::issue_problem_end();
		return;
	}

@<Issue problem for trying to use a description as a literal@> =
	Problems::quote_source(1, current_sentence);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_DescAsLiteral));
	Problems::issue_problem_segment("%1: this seems to be using a description "
		"as if it were a constant value, which isn't allowed. (Descriptions "
		"can only be used as values to a limited extent.)");
	Problems::issue_problem_end();
	return;

@ Creation has already taken place, in that X does now exist, but any
stipulations on X -- that it should have certain properties, or be in a
certain place, for instance -- will not yet be enforced. These will be in
the "creation proposition" of Y, and we now assert this to be true about X.

@<Assert that X is an instance of Y@> =
	inference_subject *left_object = Node::get_subject(px);
	pcalc_prop *prop = Node::get_creation_proposition(py);
	if (prop) {
		if ((Binding::number_free(prop) == 0) && (left_object)) {
			LOG("Proposition is: $D\n", prop);
			StandardProblems::subject_problem_at_sentence(_p_(PM_SubjectNotFree),
				left_object,
				"seems to be set equal to something in a complicated relationship "
				"with something else again",
				"which is too much for me. Perhaps you're trying to do two things "
				"at once, and it would be clearer to write it as two sentences?");
			return;
		}
		Assert::true_about(prop, left_object, prevailing_mood);
	} else {
		kind *K = Specifications::to_kind(Node::get_evaluation(py));
		if (K) {
			pcalc_prop *prop = KindPredicates::new_atom(K, Terms::new_variable(0));
			Assert::true_about(prop, left_object, prevailing_mood);
		}
	}

@h Case 40. And so on, with one exemption.

@<Case 40 - COMMON NOUN vs PROPER NOUN@> =
	parse_node *spec = Node::get_evaluation(py);
	@<Silently pass sentences like "The colours are red and blue."@>;
	if (Kinds::Behaviour::is_object(Specifications::to_kind(Node::get_evaluation(py))))
		Assertions::issue_value_equation_problem(py, px);
	else Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_CommonIsProper),
		"this seems to say that a general description is something else",
		"like saying that 'a door is 20'.");

@ Suppose on the left we have a kind ("a colour", say) and on the right
a specific value ("blue", say). We silently allow this if the kinds agree, as
that's the case we fall into if we created "blue" in the Creator earlier;
no further work need be done, and we return to avoid a spurious problem
message.

@<Silently pass sentences like "The colours are red and blue."@> =
	if (Rvalues::to_instance(spec)) {
		kind *c_kind = Instances::to_kind(Rvalues::to_instance(spec));
		kind *v_kind = Specifications::to_kind(Node::get_evaluation(px));
		if ((v_kind == NULL) || (Kinds::eq(c_kind, v_kind))) return;
	}

@h Case 41. In general, an object simply can't be set equal to a value, but
there's one exception: when the value is really an adjectival use implying
a property, rather than a noun. This takes some setting up: only the last of
these sentences falls into case 41.

>> Colour is a kind of value. Green and blue are colours. A thing has a colour. The barn door is green.

There is also one case in which an object can be set equal to another object:

>> East is the Pavilion.

(Of course this will only be true if the map plugin is active.)

@<Case 41 - PROPER NOUN on both sides@> =
	@<Allow the case of a property name, implicitly a property, being assigned to@>;
	@<Allow the case where a constant value is being assigned a property value@>;
	@<Allow the case where a constant response is being assigned a text value@>;
	@<Allow the case of a variable being assigned to@>;
	@<Allow the case of a new value for a kind which coincides with a property name@>;

	kind *K = Specifications::to_kind(Node::get_evaluation(py));
	property *pname = Properties::property_with_same_name_as(K);
	if (pname) {
		if (global_pass_state.pass == 2)
			Assertions::PropertyKnowledge::assert_property_value_from_property_subtree_infs(pname, Node::get_subject(px), py);
		return;
	}

	#ifdef IF_MODULE
	if ((Map::subject_is_a_direction(Node::get_subject(px))) ||
		(Map::subject_is_a_direction(Node::get_subject(py))))
		@<This is a map connection referred to metonymically@>
	else
	#endif
	if (Rvalues::is_object(Node::get_evaluation(py)))
		@<Otherwise it's just wrong to equate objects@>
	else if (Rvalues::is_CONSTANT_construction(Node::get_evaluation(py), CON_property))
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ObjectIsProperty),
			"that seems to say that some object is a property",
			"like saying 'The brick building is the description': if you want to specify "
			"the description of the current object, try putting the sentence the other way "
			"around ('The description is...').");
	else if (Node::get_subject(px)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(px));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ObjectIsValue));
		Problems::issue_problem_segment(
			"I am reading the sentence %1 as saying that a thing called "
			"'%2' is a value, but this makes no sense to me - it would be "
			"like saying 'the chair is 10'.");
		Problems::issue_problem_end();
	}
	else @<Produce a problem to the effect that two values can't be asserted equal@>;

@<This is a map connection referred to metonymically@> =
	if (Anaphora::get_current_subject() == NULL) {
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_NoMapOrigin),
			"no location is under discussion to be the origin of this map connection",
			"so this is like starting with 'North is the Aviary': I can't tell where from.");
		return;
	}
	inference_subject *target = Node::get_subject(py), *way = Node::get_subject(px);
	if (Map::subject_is_a_direction(target)) {
		target = Node::get_subject(px); way = Node::get_subject(py);
	}
	if (global_pass_state.pass == 2) {
		if (target == NULL) {
			Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_MapNonObject),
				"this seems to make a map connection to something which is "
				"not an object",
				"like saying '20 is north'. This is an odd thing "
				"to say, and makes me think that I've misunderstood you.");
		} else {
			Map::connect(Anaphora::get_current_subject(), target, way);
		}
	}

@<Otherwise it's just wrong to equate objects@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(px));
	Problems::quote_wording(3, Node::get_text(py));

	if (Node::get_subject(px) == Node::get_subject(py))
		Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ProperIsItself),
			"this seems to say that something is itself",
			"like saying 'the coin is the coin'. This is an odd thing "
			"to say, and makes me think that I've misunderstood you.");
	else if (<control-structure-phrase>(Node::get_text(px))) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_IfInAssertion));
		Problems::issue_problem_segment(
			"I am reading the sentence %1 as a declaration of the initial "
			"state of the world, so I'm expecting that it will be definite. "
			"The only way I can construe it that way is by thinking that "
			"'%2' and '%3' are two different things, but that doesn't make "
			"sense, and the 'if' makes me think that perhaps you did not "
			"mean this as a definite statement after all. Although 'if...' "
			"is often used in rules and definitions of what to do in given "
			"circumstances, it shouldn't be used in a direct assertion.");
		Problems::issue_problem_end();
	} else if (Rvalues::is_object(
		Node::get_evaluation(px)))
		@<Issue the generic problem message for equating objects@>
	else @<Issue a problem for equating an object to a value@>;

@<Issue a problem for equating an object to a value@> =
	Problems::quote_kind_of(4, Node::get_evaluation(px));
	Problems::quote_kind_of(5, Node::get_evaluation(py));
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ObjectAndValueEquated));
	Problems::issue_problem_segment(
		"The sentence %1 seems to say that '%2', which I think is %4, and "
		"'%3', which I think is %5, are the same. %P"
		"That can't be right, so I must have misunderstood. Perhaps you "
		"intended to make something new, but it accidentally had the same "
		"name as something already existing?");
	Problems::issue_problem_end();

@ This message is seen so often...

@<Issue the generic problem message for equating objects@> =
	@<Choose random antagonists for variety@>;
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_ChalkCheese));
	Problems::issue_problem_segment(
		"The sentence %1 appears to say two things are the same - I am reading '%2' "
		"and '%3' as two different things, and therefore it makes no sense to say "
		"that one is the other: it would be like saying that '%4 is %5'. It would "
		"be all right if the second thing were the name of a kind, perhaps with "
		"properties: for instance '%6 is a lighted room' says that something "
		"called %6 exists and that it is a 'room', which is a kind I know about, "
		"combined with a property called 'lighted' which I also know about.");
	Problems::Using::diagnose_further();
	Problems::issue_problem_end();

@ ...that we vary it randomly for fun. The low bits of the current time are not
exactly a crypto-quality source of entropy, but they'll do for us. (We have
to turn the variability off in fixed-RNG mode for the sake of the test
suite: it would be annoying to verify this problem message otherwise.)

@<Choose random antagonists for variety@> =
	char *P, *Q, *In;
	int variant = 0;
	if (Task::rng_seed() == 0) variant = (time(0))&15;
	switch(variant) {
		case 1: P = "the chalk"; Q = "the cheese"; In = "Dairy Products School"; break;
		case 2: P = "St Peter"; Q = "St Paul"; In = "Pearly Gates"; break;
		case 3: P = "Tom"; Q = "Jerry"; In = "Mouse-Hole"; break;
		case 4: P = "Clark Kent"; Q = "Lex Luthor"; In = "Metropolis"; break;
		case 5: P = "Ron"; Q = "Hermione"; In = "Hogsmeade"; break;
		case 6: P = "Tarzan"; Q = "Jane"; In = "Treehouse"; break;
		case 7: P = "Adam"; Q = "Eve"; In = "Land of Nod"; break;
		case 8: P = "Laurel"; Q = "Hardy"; In = "Blue-Ridge Mountains"; break;
		case 9: P = "Aeschylus"; Q = "Euripides"; In = "Underworld"; break;
		case 10: P = "Choucas"; Q = "Hibou"; In = "The Hall"; break;
		case 11: P = "John"; Q = "Paul"; In = "Abbey Road"; break;
		case 12: P = "Poirot"; Q = "Hastings"; In = "St Mary Mead"; break;
		case 13: P = "House"; Q = "Wilson"; In = "Princeton Plainsboro"; break;
		case 14: P = "Adams"; Q = "Jefferson"; In = "Virginia"; break;
		case 15: P = "Antony"; Q = "Cleopatra"; In = "Alexandria"; break;
		case 16: P = "Emmet"; Q = "Wildstyle"; In = "Bricksburg"; break;
		case 17: P = "Stanley"; Q = "Livingstone"; In = "Africa"; break;
		case 18: P = "Jeeves"; Q = "Wooster"; In = "Totleigh Towers"; break;
		case 19: P = "John"; Q = "Timus"; In = "The Lab"; break;
		default: P = "the hawk"; Q = "the handsaw"; In = "Elsinore"; break;
	}
	Problems::quote_text(4, P); Problems::quote_text(5, Q); Problems::quote_text(6, In);

@ Usually it makes no sense to equate two values: "5 is 10",
for instance, and we produce a variety of more or less scornful errors.

>> 10 is 15. 14 is a number. "Fish" is text. The turn count is a text. 19 is a rulebook. "Frog" is a number. Before rules is a rule.

But we do take polite notice when X is a variable name and Y is an
initial value with a compatible type, as in the second sentence here:

>> The innings total is a number that varies. The innings total is 101.

We set such variables on traverse 2 because not all of the object values exist
yet during traverse 1.

@<Allow the case of a variable being assigned to@> =
	if (Lvalues::get_storage_form(Node::get_evaluation(px)) == NONLOCAL_VARIABLE_NT) {
		nonlocal_variable *nlv = Node::get_constant_nonlocal_variable(Node::get_evaluation(px));
		if (nlv) {
			parse_node *val = Node::get_evaluation(py);
			if (val) Node::set_text(val, Node::get_text(py));
			val = NonlocalVariables::substitute_constants(val);
			if (global_pass_state.pass == 2) {
				Assertions::PropertyKnowledge::initialise_global_variable(nlv, val);
			} else {
				if (Node::is(val, CONSTANT_NT))
					if (PluginCalls::variable_set_warning(nlv, val))
						Assertions::PropertyKnowledge::initialise_global_variable(nlv, val);
			}
			return;
		}
	}

@<Allow the case of a property name, implicitly a property, being assigned to@> =
	if (Rvalues::is_CONSTANT_construction(Node::get_evaluation(px), CON_property)) {
		inference_subject *talking_about = Anaphora::get_current_subject();
		if (talking_about == NULL)
			Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_NothingDiscussed),
				"nothing is under discussion which might have this property",
				"so this is like starting with 'The description is \"Orange.\"': "
				"I can't tell what of.");
		else if (global_pass_state.pass == 2) {
				if (<negated-clause>(Node::get_text(py)))
					StandardProblems::negative_sentence_problem(Task::syntax_tree(), _p_(PM_NonValue2));
				else Assertions::PropertyKnowledge::assert_property_value_from_property_subtree_infs(
				Rvalues::to_property(Node::get_evaluation(px)), talking_about, py);
		}
		return;
	}

@ Here we're watching out for assertions like:

>> The Abruzzi Spur route is grade 5.

where "Abruzzi Spur route" is a value of kind "K2 ascent route", and values
of this kind have been given a property "difficulty rating" which is also
the name of a kind in turn, one value of which is "grade 5". To the A-parser
both sides are |VALUE| nodes; "grade 5" is being used adjectivally here,
but that's not evident without a lot of contextual checking.

@<Allow the case where a constant value is being assigned a property value@> =
	parse_node *constant = Node::get_evaluation(px);
	if ((Rvalues::to_instance(constant)) ||
		(Specifications::is_kind_like(constant))) {
		instance *q = Rvalues::to_instance(Node::get_evaluation(py));
		property *pname = Properties::property_with_same_name_as(Instances::to_kind(q));
		if (pname) {
			if (global_pass_state.pass == 2)
				Assertions::PropertyKnowledge::assert_property_value_from_property_subtree_infs(pname, Instances::as_subject(q), py);
			return;
		}
	}

@<Allow the case where a constant response is being assigned a text value@> =
	parse_node *constant = Node::get_evaluation(px);
	parse_node *val = Node::get_evaluation(py);
	if ((Rvalues::is_CONSTANT_of_kind(constant, K_response)) &&
		(Rvalues::is_CONSTANT_of_kind(val, K_text))) {
		rule *R = Rvalues::to_rule(constant);
		int c = Annotations::read_int(constant, response_code_ANNOT);
		Strings::assert_response_value(R, c, Node::get_text(val));
		return;
	}

@ This is to cope with text such as

>> Plastic is a material.

where "material" is the name of both a kind of value, and also a property.
We find ourselves here because we've been considering "material" as the
property name (a proper noun), not the kind name (a common noun), and we
need to switch interpretations to avoid the problem message.

@<Allow the case of a new value for a kind which coincides with a property name@> =
	if (Rvalues::is_CONSTANT_construction(Node::get_evaluation(py), CON_property)) {
		property *prn = Rvalues::to_property(Node::get_evaluation(py));
		if ((Properties::is_either_or(prn) == FALSE) &&
			(ValueProperties::coincides_with_kind(prn))) {
			kind *K = ValueProperties::kind(prn);
			Node::set_type_and_clear_annotations(py, COMMON_NOUN_NT);
			Node::set_evaluation(py, Specifications::from_kind(K));
			Assertions::make_coupling(px, py);
			return;
		}
	}

@ All other attempts are doomed.

@<Produce a problem to the effect that two values can't be asserted equal@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, Node::get_text(px));
	Problems::quote_wording(3, Node::get_text(py));
	Problems::quote_kind_of(4, Node::get_evaluation(px));
	Problems::quote_kind_of(5, Node::get_evaluation(py));

	if (Kinds::eq(Specifications::to_kind(Node::get_evaluation(px)),
			Specifications::to_kind(Node::get_evaluation(py)))) {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_SimilarValuesEquated));
		Problems::issue_problem_segment(
			"Before reading %1, I already knew that '%2' is %4 and "
			"'%3' likewise: so they are specific values, and saying "
			"that they are equal will not make it so.");
		Problems::issue_problem_end();
	} else {
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_DissimilarValuesEquated));
		Problems::issue_problem_segment(
			"Before reading %1, I already knew that '%2' is %4 and "
			"'%3' is %5: so they are specific values, and saying "
			"that they are equal will not make it so.");
		Problems::issue_problem_end();
	}

@ Equating values in an assertion is never allowed, but there are a variety of
possible problem messages, because it usually occurs as a symptom of a failed
attempt to create something. The following is used to pick up sentences like

>> Something called mauve is a colour.

which fail because Inform reads "something" as "some thing", i.e., as
referring to a thing which then can't be equated with a colour.

=
<something-loose-diagnosis> ::=
	*** something ***		==> @<Issue PM_EquatesSomethingToValue problem@>;

@<Issue PM_EquatesSomethingToValue problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EquatesSomethingToValue),
		"that seems to say that an object is the same as a value",
		"which must be wrong. This can happen if the word 'something' is "
		"used loosely - I read it as 'some thing', so I think it has to "
		"refer to a thing, which is a kind of object. A sentence like "
		"'Something called mauve is a colour' trips me up because mauve "
		"is a value, so it isn't an object, and doesn't match 'something'.");

@h Case 42. This is possibly a variation on 41 where an adjective is also
in some contexts a noun. For example:

>> Hostile hates friendly.

where "hostile" and "friendly" are values of an enumerated kind but which
can also be used adjectivally.

@<Case 42 - ADJECTIVE vs RELATIONSHIP@> =
	if ((Refiner::nominalise_adjective(px)) ||
		(Refiner::nominalise_adjective(py->down))) {
		Assertions::make_coupling(px, py);
		return;
	}

	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
		"that seems to relate an adjective to something",
		"which must be wrong. (This can sometimes happen if the same word can "
		"be used both as an adjective and a noun, and I misunderstand.)");

@ =
void Assertions::issue_value_equation_problem(parse_node *px, parse_node *py) {
	if ((current_sentence) &&
		(<something-loose-diagnosis>(Node::get_text(current_sentence))))
		return;

	if ((Node::get_type(px) != PROPER_NOUN_NT) ||
		((Node::get_type(py) != PROPER_NOUN_NT) && (Node::get_type(py) != COMMON_NOUN_NT))) {
		LOG("$T", px); LOG("$T", py);
		internal_error("Assert PX of type PY on bad node types");
	}
	LOG("$T", px); LOG("$T", py);

	if ((Node::get_subject(px)) &&
		(InferenceSubjects::where_created(Node::get_subject(px)) != current_sentence)) {
		Problems::quote_wording(1, Node::get_text(px));
		Problems::quote_source(2, current_sentence);
		Problems::quote_source(3, InferenceSubjects::where_created(Node::get_subject(px)));
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_CantUncreate));
		Problems::issue_problem_segment(
			"In order to act on %2, I seem to need to give "
			"a new meaning to '%1', something which was created by the earlier "
			"sentence %3. That must be wrong somehow: I'm guessing that there "
			"is an accidental clash of names. This sometimes happens when "
			"adjectives are being made after objects whose names include them: "
			"for instance, defining 'big' as an adjective after having already "
			"made a 'big top'. The simplest way to avoid this is to define "
			"the adjectives in question first.");
		Problems::issue_problem_end();
		return;
	}

	if ((Node::get_type(px) == PROPER_NOUN_NT) && (Node::get_type(py) == COMMON_NOUN_NT)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, Node::get_text(py));
		if (Wordings::nonempty(Node::get_text(px))) Problems::quote_wording(3, Node::get_text(px));
		else Problems::quote_text(3, "(something not given an explicit name)");
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_IdentityUnclear));
		Problems::issue_problem_segment(
			"The sentence %1 seems to tell me that '%2' and '%3' have to be "
			"the same, but it looks odd to me. '%2' is something generic - "
			"not something definite; but '%3' is (presumably) something "
			"specific. So it's as if you'd written 'A room is the Sydney "
			"Opera House'. (Which room, exactly? You see the trouble.)");
		Problems::issue_problem_end();
		return;
	}

	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
		"that seems to say that an object is the same as a value",
		"which must be wrong.");
}

@h Instantiation of related kinds.

=
void Assertions::instantiate_related_common_nouns(parse_node *p) {
	Assertions::instantiate_related_common_nouns_r(p, p->down);
}

void Assertions::instantiate_related_common_nouns_r(parse_node *from, parse_node *at) {
	if (at == NULL) return;
	if (Node::get_type(at) == COMMON_NOUN_NT)
		Assertions::Creator::convert_instance_to_nounphrase(at,
			Node::get_relationship(from));
	if (Node::get_type(at) == AND_NT) {
		Assertions::instantiate_related_common_nouns_r(from, at->down);
		Assertions::instantiate_related_common_nouns_r(from, at->down->next);
	}
	if (Node::get_type(at) == WITH_NT) {
		Assertions::instantiate_related_common_nouns_r(from, at->down);
		Assertions::PropertyKnowledge::assert_property_list(at->down, at->down->next);
	}
}

@h Adjective list trees.

=
int Assertions::is_adjlist(parse_node *p) {
	if (p == NULL) return FALSE;
	switch (Node::get_type(p)) {
		case ADJECTIVE_NT: return TRUE;
		case AND_NT: return ((Assertions::is_adjlist(p->down)) && (Assertions::is_adjlist(p->down->next)));
		default: return FALSE;
	}
}
