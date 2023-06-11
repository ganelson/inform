[DefineByTable::] Define by Table Requests.

Special sentences declaring that tables amount to massed groups of assertions.

@ Tables lie behind the special "defined by" sentence. These come in three
subtly different versions:

>> (1) Some animals are defined by the Table of Specimens.
>> (2) Some men in the Zoo are defined by the Table of Zookeepers.
>> (3) Some kinds of animal are defined by the Table of Zoology.

The subject in (1) is the name of a kind; in (2), it's a description which
incorporates a kind, but can include relative clauses and adjectives; in (3),
it's something second-order -- a kind of a kind. Given this variety of
possibilities, we treat "defined by" sentences as if they were abbreviations
for a mass of assertion sentences, one for each row of the table. We do
however reject:

>> The okapi is defined by the Table of Short-Necked Giraffes.

where the "okapi" is an existing single animal (or indeed where it's a new
name, meaning as yet unknown).

@ So this function handles the special meaning "X is defined by Y"; it is
a special meaning of "to be", recognised when Y matches --

=
<defined-by-sentence-object> ::=
	defined by <np-as-object>  ==> { pass 1 }

@ =
int DefineByTable::defined_by_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The colours are defined by Table 1." */
		case ACCEPT_SMFT:
			if (<defined-by-sentence-object>(OW)) {
				parse_node *O = <<rp>>;
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
		case PASS_2_SMFT:
			DefineByTable::kind_defined_by_table(V);
			break;
	}
	return FALSE;
}

@ The timing of when to act on defined-by sentences is not completely
straightforward; if it's wrong, entries making cross-references may sometimes
be rejected by Inform for what seem very opaque reasons. Here's the timeline:

(a) Names of tables and their columns are created in the pre-pass.

(b) In pass 1, the names in column 1 of a defined-by table are created: see
below.

(c) Between pass 1 and 2 there's a process called "stocking", in which
cell values of tables are parsed. This finally settles the kind of any columns
where this has to be inferred from the contents.

(d) In pass 2, the property values in columns 2 onwards are assigned to
whatever was named in column 1: see below.

=
void DefineByTable::kind_defined_by_table(parse_node *V) {
	wording SPW = Node::get_text(V->next);
	wording LTW = Node::get_text(V->next->next);
	LOGIF(TABLES, "Traverse %d: I now want to define <%W> by table <%W>\n",
		global_pass_state.pass, SPW, LTW);

	<defined-by-sentence-object-inner>(LTW); if (<<r>> == FALSE) return;
	table *t = Rvalues::to_table(<<rp>>);

	if (global_pass_state.pass == 1) @<Create whatever is in column 1@>;
	@<Assign properties for these values as enumerated in subsequent columns@>;
}

@ The object phrase is required to be a table name value:

=
<defined-by-sentence-object-inner> ::=
	<s-value> |  ==> @<Allow if a table name@>
	...          ==> @<Issue PM_TableUndefined problem@>

@<Allow if a table name@> =
	if (Rvalues::is_CONSTANT_of_kind(RP[1], K_table)) {
		==> { TRUE, RP[1] };
	} else {
		==> { FALSE, - };
	}

@<Issue PM_TableUndefined problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TableUndefined),
	"you can only use 'defined by' in terms of a table",
	"which lists the value names in the first column.");
	==> { FALSE, - };

@ The subject phrase will also have to match:

=
<defined-by-sentence-subject> ::=
	<article> kind/kinds of {<s-type-expression>} | ==> { TRUE, RP[2] }
	kind/kinds of {<s-type-expression>} |           ==> { TRUE, RP[1] }
	<s-type-expression> |                           ==> { FALSE, RP[1] }
	...                                             ==> @<Issue PM_TableDefiningTheImpossible problem@>

@<Issue PM_TableDefiningTheImpossible problem@> =
	@<Actually issue PM_TableDefiningTheImpossible problem@>;
	==> { NOT_APPLICABLE, - };

@ (We're going to need this problem message twice.)

@<Actually issue PM_TableDefiningTheImpossible problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_TableDefiningTheImpossible),
		"you can only use 'defined by' to set up values and things",
		"as created with sentences like 'The tree species are defined by Table 1.' "
		"or 'Some men are defined by the Table of Eligible Bachelors.'");

@h Creation.

@<Create whatever is in column 1@> =
	kind *K = NULL;
	@<Determine the kind of what to make@>;
	@<Check that this is a kind where it makes sense to enumerate new values@>;
	K = Kinds::weaken(K, K_object);
	if (!(Kinds::Behaviour::is_object(K))) RTTables::defines(t, K);
	t->kind_defined_in_this_table = K;
	Tables::Columns::set_kind(t->columns[0].column_identity, t, K);
	@<Create values for this kind as enumerated by names in the first column@>;

@<Determine the kind of what to make@> =
	<defined-by-sentence-subject>(SPW); if (<<r>> == NOT_APPLICABLE) return;
	parse_node *what = <<rp>>;
	if (<<r>>) @<Rewrite in a KIND subtree@>;
	int defining_objects = FALSE;
	if (Specifications::is_kind_like(what)) {
		K = Specifications::to_kind(what);
		if (Kinds::Behaviour::is_object(K)) defining_objects = TRUE;
	} else if (Specifications::object_exactly_described_if_any(what)) {
		@<Issue PM_TableDefiningObject problem@>
		return;
	} else if (Specifications::is_description(what)) {
		@<Check that this is a description which in principle can be asserted@>;
		K = Specifications::to_kind(what);
	} else {
		LOG("Error at: $T", what);
		@<Actually issue PM_TableDefiningTheImpossible problem@>;
		return;
	}
	if (t) Tables::use_to_define(t, defining_objects, V->next);

@ This is all a little clumsy, but it rewrites, say, "kinds of snake" in a
little subtree under a |KIND_NT| node with "snake" as |UNPARSED_NOUN_NT|, rather
than leaving "kinds of snake" as a single |UNPARSED_NOUN_NT| node, which would
cause a new object instance to be created with that name.

@<Rewrite in a KIND subtree@> =
	parse_node *old_node = V->next;
	parse_node *to_node = V->next->next;
	parse_node *new_node = Diagrams::new_KIND(SPW, old_node);
	wording KW = GET_RW(<defined-by-sentence-subject>, 1);
	Node::set_text(old_node, KW);
	old_node->next = NULL;
	V->next = new_node;
	V->next->next = to_node;
	what = NULL;
	if (<k-kind>(KW)) what = Descriptions::from_kind(<<rp>>, FALSE);

@<Issue PM_TableDefiningObject problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_TableDefiningObject),
		"you can only use 'defined by' to set up values and things",
		"as created with sentences like 'The tree species are defined by Table 1.' "
		"or 'Some men are defined by the Table of Eligible Bachelors.' - trying to "
		"define a single specific object, as here, is not allowed.");

@<Check that this is a kind where it makes sense to enumerate new values@> =
	if ((Kinds::Behaviour::is_object(K) == FALSE) &&
		(Kinds::Behaviour::has_named_constant_values(K) == FALSE)) {
		LOG("K is %u\n", K);
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableOfBuiltInKind));
		Problems::issue_problem_segment(
			"You wrote %1, but this would mean making each of the names in "
			"the first column %2 that's new. This is a kind which can't have "
			"entirely new values, so I can't make these definitions.");
		Problems::issue_problem_end();
		return;
	}
	if ((Kinds::Behaviour::has_named_constant_values(K)) &&
		(Kinds::Behaviour::is_uncertainly_defined(K) == FALSE)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_TableOfExistingKind));
		Problems::issue_problem_segment(
			"You wrote %1, but this would mean making each of the names in "
			"the first column %2 that's new. That looks reasonable, since this is a "
			"kind which does have named values, but one of the restrictions on "
			"definitions-by-table is that all of the values of the kind have "
			"to be made by the table: you can't have some defined in ordinary "
			"sentences and others in the table.");
		Problems::issue_problem_end();
		return;
	}

@<Check that this is a description which in principle can be asserted@> =
	if (Propositions::contains_quantifier(
		Specifications::to_proposition(what))) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TableOfQuantifiedKind),
			"you can't use 'defined by' a table while also talking about the "
			"number of things to be defined",
			"since that could too easily lead to contradictions. (So 'Six doors are "
			"defined by the Table of Portals' is not allowed - suppose there are ten "
			"rows in the Table, making ten doors?)");
		return;
	}

@ The following code has a curious history: it has evolved backwards from
something much higher-level. When definition by tables began, it was a device
to create new instances -- the names in column 1 would be, say, the instances
of the kind "colour". Inform did this by writing propositions to assert their
existence, in an elegantly high-level way; and all was well. But people also
wanted things like this:

>> Some people on the dais are defined by the Table of Presenters.

and the process of converting that to propositional form, while issuing
a range of intelligible problem messages if anything went wrong, would end
up duplicating what's already done in the assertion parser.

So Inform now handles rows in defined-by tables by handing them over to
the assertions system directly. If the name N is in column 1, and the
original sentence read "D are defined by...", then Inform calls the
assertion-maker on the parse tree nodes for N and D exactly as if the
user had written "N is D". Since this explicitly changes the meaning of N
(that's the point), we then re-parse N, and check that it does now refer
to an instance or kind; if it doesn't, then some assertion problem must
have occurred, but if it does then the creation has worked.

@<Create values for this kind as enumerated by names in the first column@> =
	parse_node *name_entry;
	int objections = 0, blank_objections = 0, row_count;
	for (name_entry = t->columns[0].entries->down, row_count = 1; name_entry;
		name_entry=name_entry->next, row_count++) {
		wording NW = Node::get_text(name_entry);
		LOGIF(TABLES, "So I want to create: <%W>\n", NW);
		if (<table-cell-blank>(NW))
			@<Issue a problem for trying to create a blank name@>;
		parse_node *evaluation = NULL;
		if (<s-type-expression>(Node::get_text(name_entry))) evaluation = <<rp>>;
		Refiner::give_spec_to_noun(name_entry, evaluation);
		if (Specifications::is_kind_like(evaluation))
			@<Issue a problem for trying to create an existing kind as a new instance@>;
		if ((evaluation) && (Node::is(evaluation, UNKNOWN_NT) == FALSE))
			@<Issue a problem for trying to create any existing meaning as a new instance@>;
		if ((K_direction) && (<notable-map-noun-phrases>(NW)))
			@<Issue a problem for trying to create above or below as a new instance@>;
		Assertions::Creator::tabular_definitions(t);
		NounPhrases::annotate_by_articles(name_entry);
		ProblemBuffer::redirect_problem_sentence(current_sentence, name_entry, V->next);
		if (Refiner::refine_coupling(name_entry, V->next, FALSE))
			Assertions::make_coupling(name_entry, V->next);
		ProblemBuffer::redirect_problem_sentence(NULL, NULL, NULL);
		Node::set_text(name_entry, NW);
		evaluation = NULL;
		if (<k-kind>(NW))
			evaluation = Specifications::from_kind(<<rp>>);
		else if (<s-type-expression>(Node::get_text(name_entry)))
			evaluation = <<rp>>;
		Refiner::give_spec_to_noun(name_entry, evaluation);
		Assertions::Creator::tabular_definitions(NULL);

		if (Node::get_subject(name_entry) == NULL)
			@<Issue a problem to say that the creation failed@>;
	}
	if (objections > 0) return;

@ Usually if the source text makes this mistake in one row, it makes it in
lots of rows, so we issue the problem just once.

@<Issue a problem for trying to create a blank name@> =
	if (blank_objections == 0) {
		Problems::quote_number(4, &row_count);
		StandardProblems::table_problem(_p_(PM_TableWithBlankNames),
			t, NULL, name_entry,
			"%1 is being used to create values, so that the first column needs "
			"to contain names for these new things. It's not allowed to contain "
			"blanks, but row %4 does (see %3).");
	}
	objections++; blank_objections++; continue;

@ This is a special case of the next problem, but enables a clearer problem
message to be issued. (It's not as unlikely a mistake as it looks, since
kind names can legally be written into other columns to indicate the kinds
of the contents.)

@<Issue a problem for trying to create an existing kind as a new instance@> =
	Problems::quote_number(4, &row_count);
	StandardProblems::table_problem(_p_(PM_TableEntryGeneric),
		t, NULL, name_entry,
		"In row %4 of %1, the entry %3 is the name of a kind of value, "
		"so it can't be the name of a new object.");
	objections++; continue;

@<Issue a problem for trying to create any existing meaning as a new instance@> =
	LOG("Existing meaning was: $P\n", evaluation);
	Problems::quote_source(1, current_sentence);
	Problems::quote_source(2, name_entry);
	Problems::quote_kind_of(3, evaluation);
	Problems::quote_kind(4, K);
	Problems::quote_number(5, &row_count);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TableCreatedClash));
	Problems::issue_problem_segment(
		"You wrote %1, and row %5 of the first column of that table is %2, which "
		"I ought to create as a new value of %4. But I can't do that: it already "
		"has a meaning (as %3).");
	Problems::issue_problem_end();
	objections++; continue;

@<Issue a problem for trying to create above or below as a new instance@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_source(2, name_entry);
	Problems::quote_kind_of(3, evaluation);
	Problems::quote_kind(4, K);
	Problems::quote_number(5, &row_count);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TableCreatedMapClash));
	Problems::issue_problem_segment(
		"You wrote %1, and row %5 of the first column of that table is %2, which "
		"I ought to create as a new value of %4. But I can't do that: it already "
		"has a meaning (it refers to a map direction).");
	Problems::issue_problem_end();
	objections++; continue;

@<Issue a problem to say that the creation failed@> =
	LOG("Eval is $P\n", evaluation);
	Problems::quote_source(4, name_entry);
	Problems::quote_number(5, &row_count);
	StandardProblems::table_problem(_p_(PM_TableDefiningNothing),
		t, NULL, name_entry,
		"In row %5 of %1, the entry %4 seems not to have defined "
		"a thing there, so perhaps the first column did not consist "
		"of new names?");
	objections++; continue;

@h Property assignment.
Suppose column 3, say, is called "alarm call" and contains times. Clearly
this is a property, and we have to give those property values to whatever
has been created in their corresponding column 1s. That means those
individual values need permission to have the "alarm call" property. But
what about other values of the same kind which aren't mentioned in the
table: do they get permission as well? We're going to say that they do.

@<Assign properties for these values as enumerated in subsequent columns@> =
	for (int i=1; i<t->no_columns; i++) {
		table_column *tc = t->columns[i].column_identity;
		property *P = NULL;
		@<Ensure that a property with the same name as the column name exists@>;
		if (global_pass_state.pass == 1)
			Assert::true_about(
				Propositions::Abstract::to_provide_property(P),
				KindSubjects::from_kind(t->kind_defined_in_this_table),
				prevailing_mood);
		if (t->contains_property_values_at_run_time)
			@<Passively allow the column to become the property values@>
		else @<Actively assert the column entries as property values@>;
	}

@ It's probably, but not certainly, the case that the column name is new, and
not yet known to be a property. If so, this is where it becomes one. By
traverse 2, if not before, we will be able to give it a kind, since after
table-stocking the column will have a kind for its entries.

@<Ensure that a property with the same name as the column name exists@> =
	wording PW = Nouns::nominative_singular(tc->name);
	<unfortunate-table-column-property>(PW);
	P = ValueProperties::obtain(PW);
	if (ValueProperties::kind(P) == NULL) {
		kind *CK = Tables::Columns::get_kind(tc);
		if ((Kinds::get_construct(CK) == CON_rule) ||
			(Kinds::get_construct(CK) == CON_rulebook)) {
			kind *K1 = NULL, *K2 = NULL;
			Kinds::binary_construction_material(CK, &K1, &K2);
			if ((Kinds::eq(K1, K_value)) && (Kinds::eq(K1, K_value))) {
				CK = Kinds::binary_con(
					Kinds::get_construct(CK), K_action_name, K_nil);
				Tables::Columns::set_kind(tc, t, CK);
			}
		}
		if (CK) ValueProperties::set_kind(P, CK);
	}

@ When a table column is used to create a property of an object, its name
becomes the name of a new property. To avoid confusion, though, there are
some misleading names we don't want to allow for these properties.

=
<unfortunate-table-column-property> ::=
	location  ==> @<Issue PM_TableColumnLocation problem@>

@<Issue PM_TableColumnLocation problem@> =
	Problems::quote_wording(3, W);
	StandardProblems::table_problem(_p_(PM_TableColumnLocation),
		table_being_examined, NULL, table_cell_node,
		"In %1, the column name %3 cannot be used, because there would be too "
		"much ambiguity arising from its ordinary meaning referring to the "
		"physical position of something.");
	==> { NEW_TC_PROBLEM, - };

@ Now for something sneaky. There are two ways we can actually assign the
property values: active, and passive. The passive way is the sneaky one, and
it relies on the observation that if we're going to store the property values
in this same table at run-time then we don't need to do anything at all: the
values are already in their correct places. All we need to do is notify the
property storage mechanisms that we intend this to happen.

(Take care editing this: the call works in quite an ugly way and relies on
following immediately after a permission grant.)

@<Passively allow the column to become the property values@> =
	if (global_pass_state.pass == 1)
		RTPropertyPermissions::set_table_storage_iname(RTTables::tcu_iname(&(t->columns[i])));

@ Active assertions of properties are, once again, a matter of calling the
assertion handler, simulating sentences like "The P of X is Y".

@<Actively assert the column entries as property values@> =
	parse_node *name_entry, *data_entry;
	for (name_entry = t->columns[0].entries->down, data_entry = t->columns[i].entries->down;
		name_entry && data_entry;
		name_entry = name_entry->next,
			data_entry = data_entry->next) {
		ProblemBuffer::redirect_problem_sentence(current_sentence, name_entry, data_entry);
		@<Make an assertion that this name has that property@>;
	}
	ProblemBuffer::redirect_problem_sentence(current_sentence, NULL, NULL);

@ Note that a blank means "don't assert this property", it doesn't mean
"assert a default value for this property". The difference is very small,
but the latter might cause contradiction problem messages if there are
also ordinary sentences about the property value, and the former won't.

@<Make an assertion that this name has that property@> =
	inference_subject *subj = Node::get_subject(name_entry);
	if (global_pass_state.pass == 2) {
		if ((Wordings::nonempty(Node::get_text(data_entry))) &&
			(<table-cell-blank>(Node::get_text(data_entry)) == FALSE)) {
			parse_node *val = Node::get_evaluation(data_entry);
			if (Node::is(val, UNKNOWN_NT)) {
				if (problem_count == 0) internal_error("misevaluated cell");
			} else {
				Refiner::give_spec_to_noun(data_entry, val);
				Assertions::PropertyKnowledge::assert_property_value_from_property_subtree_infs(
					P, subj, data_entry);
			}
		}
	}
