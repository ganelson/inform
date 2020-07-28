[ExParser::] Type Expressions and Values.

To parse two forms of noun: a noun phrase in a sentence, and a
description of what text can be written in a given situation.

@h Definitions.

@ Inform recognises many noun-like constructions, some of which -- out of a noun
context -- look like adjectives, actions or other excerpts which aren't at all
evidently nouns. These many ways to describe nouns are gathered up into two
central constructions. A "type expression" specifies what sort of excerpt
should appear in a given place, whereas a "value" means anything which
can be a noun phrase for a verb. There is considerable overlap between the
two, but they are not the same.

The following example sentences have the relevant phrases in bold.

>> [1] if the idea of the gizmo is {\bf taking the fish}, ...
>> [2] if there are {\bf three women} in the Nunnery, ...
>> [3a: as description] Before taking {\bf the harmonium}, ...
>> [3b: as constant] let X be {\bf the harmonium};
>> [4] now Y is {\bf the can't reach inside rooms rule};
>> [5] now Z is {\bf the time of day};
>> [6] let N be {\bf the number of entries in L};
>> [7] Understand "turn to [{\bf number}]" as combination-setting.
>> [8] To repeat until (C - {\bf condition}): ...
>> [9] The Zeppelin countdown is a {\bf number that varies}.
>> [10] The little red car is a {\bf vehicle}.
>> [11] The weight of the Space Shuttle is {\bf 68585 kg}.

@h Type expressions.
A "type expression" specifies what sort of excerpt of text should appear
in a given context. Sometimes it asks for a particular value, sometimes any
value matching a given description.

This is a concept which does not exist for conventional programming languages,
which would see it as a sort of half-way position between "value" and
"type". In particular, a "type expression" is used to lay out what a
parameter in a phrase definition should be, though it has other uses elsewhere.
That certainly includes cases which traditional programming languages would
call types, so

>> To adjust (X - closed door) by (N - number): ...

includes two type expressions, "closed door" and "number". But a type
expression can also be a constant, which languages like C (for instance) would
consider a value and not a type at all:

>> To adjust (X - closed door) by (N - 11): ...

gives a definition to be used only where the second parameter evaluates to
11. In this way any constant value is regarded as being a type -- the narrow
type representing only its own value.

=
<s-type-expression-uncached> ::=
	<article> <s-type-expression-unarticled> |   ==> { pass 2 }
	<s-type-expression-unarticled>               ==> { pass 1 }

<s-type-expression-unarticled> ::=
	<s-variable-scope> variable/variables |      ==> { pass 1 }
	<s-variable-scope> that/which vary/varies |  ==> { pass 1 }
	<k-kind> |                                   ==> { -, Specifications::from_kind(RP[1]) }
	<s-literal> |                                ==> { pass 1 }
	<s-constant-value> |                         ==> { pass 1 }
	<s-description-uncomposite> |                ==> { pass 1 }
	<s-action-pattern-as-value> |                ==> { pass 1 }
	<s-description>                              ==> { pass 1 }

@ Note that a list of adjectives with no noun does not qualify as a type
expression. It looks as if it never should, on the face of it -- "opaque"
does not make clear what kind of object is to be opaque -- but once again we
are up against the problem that Inform needs to allow some slightly noun-like
adjectives. For instance, this:

>> To adjust (X - scenery): ...

is allowed even though "scenery" is an adjective in Inform.

To allow this, we have a minor variation:

=
<s-descriptive-type-expression-uncached> ::=
	<article> <s-descriptive-type-expression-unarticled> |  ==> { pass 2 }
	<s-descriptive-type-expression-unarticled>              ==> { pass 1 }

<s-descriptive-type-expression-unarticled> ::=
	<s-adjective-list-as-desc> |    ==> { pass 1 }
	<s-type-expression-unarticled>  ==> { pass 1 }

@ And now we parse descriptions of variables such as the one appearing in

>> To increment (V - existing number variable)

where <s-variable-scope> matches "existing number variable".

Note that these forms recurse, so that syntactically we allow "T that
varies" for any type expression T. This would include contradictions in terms
such as "15 that varies" or "number that varies that varies that varies",
but we want to allow the parse here so that a problem message can be issued
higher up in Inform. Ultimately, the text must match <k-kind> in each case.

=
<s-variable-scope> ::=
	global |                        ==> { -, Specifications::new_new_variable_like(NULL) }
	global <s-variable-contents> |  ==> { pass 1 }
	<s-variable-contents>           ==> { pass 1 }

<s-variable-contents> ::=
	<k-kind> |                      ==> { -, Specifications::new_new_variable_like(RP[1]) }
	<s-literal> |                   ==> @<Issue PM_TypeCantVary problem@>
	<s-constant-value> |            ==> @<Issue PM_TypeCantVary problem@>
	<s-description-uncomposite> |   ==> @<Issue PM_TypeUnmaintainable problem@>
	<s-description>                 ==> @<Issue PM_TypeUnmaintainable problem@>

@<Issue PM_TypeCantVary problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TypeCantVary));
	Problems::issue_problem_segment(
		"In %1, '%2' is not a kind of value which a variable can safely have, "
		"as it cannot ever vary.");
	Problems::issue_problem_end();
	==> { -, Specifications::new_new_variable_like(K_object) };

@<Issue PM_TypeUnmaintainable problem@> =
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_TypeUnmaintainable));
	Problems::issue_problem_segment(
		"In %1, '%2' is not a kind of value which a variable can safely have, "
		"as it cannot be guaranteed that the contents will always meet "
		"this criterion.");
	Problems::issue_problem_end();
	==> { -, Specifications::new_new_variable_like(K_object) };

@ Two pieces of context:

=
int let_equation_mode = FALSE;
kind *probable_noun_phrase_context = NULL;

@ That's it for type expressions, and we move on to values. There are
three special circumstances in which we parse differently: while we could write
variant grammars for these situations, they would be very large and almost
identical to <s-value> anyway, so instead we simply use <s-value>.

The following matches only if we are in an equation written out in the phrase:
for example,

>> let V be given by V = fl;

As mentioned earlier, this changes our conventions on word-breaking.

=
<if-let-equation-mode> internal 0 {
	if (let_equation_mode) return TRUE;
	==> { fail nonterminal };
}

@ Next, we are sometimes in a situation where a local variable exists which
can be referred to by a pronoun like "it"; if so, we will enable the use
of possessives like "its" to refer to properties.

=
<if-pronoun-present> internal 0 {
	if (LocalVariables::is_possessive_form_of_it_enabled()) return TRUE;
	==> { fail nonterminal };
}

@ The other possible contexts are where we are expecting a table column or
a property name. This enables us to resolve ambiguities in a helpful way,
but otherwise changes little.

=
<if-table-column-expected> internal 0 {
	if (Kinds::get_construct(probable_noun_phrase_context) == CON_table_column)
		return TRUE;
	==> { fail nonterminal };
}

<if-property-name-expected> internal 0 {
	if (Kinds::get_construct(probable_noun_phrase_context) == CON_property)
		return TRUE;
	==> { fail nonterminal };
}

@h Values.
The boldface terms here are all parsed as values:

>> {\bf The cat} is in {\bf the bag}. The {\bf time of day} is {\bf 11:10 AM}.
>> award {\bf six} points;
>> if {\bf more than three animals} are in {\bf the kennel}, ...

The sequence here is important, in that it resolves ambiguities:

(b) Variable names have highest priority, in order to allow temporary "let"
names to mask existing meanings.

(c) Constants come next: these include literals, but also named constants,
such as names of rooms or things.

(d) Equations are an oddball exceptional case, seldom arising.

(f) Property names are not constants and, as values, they are usually read
as implicitly referring to a property value of something, not as a reference
to the property itself: thus "description" means the actual description of
some object clear from context, not the description property in the abstract.

(g) Table column names present a particular ambiguity arising from tables
which are used to construct instances. In tables like that, the column names
become names of properties owned by those instances; and then there are also
ambiguities like those with property names, as between the column's identity
and the actual contents of the current row.

(i) Phrases to decide a value whose wording mimics a property cause trouble.
I sometimes think it would be better to penalise this sort of wording by
treating it badly, but since the Standard Rules are as guilty as anyone else,
Inform instead tries to cope. Here we parse any phrase whose wording doesn't
look like a property lookup in the form "X of Y"; later we will pick up
any phrase whose wording does.

(k) Similarly we parse descriptions in two rounds: those referring to
physical objects, and others later on. This is because English tends to give
metaphorically physical names to abstract things: for example, the word
"table" for an array of data. We want to make sure sentences like "The
ball is on the table" are not misread through parsing "table" as the
name of the kind. (Type expressions have the opposite convention: there,
kind names always take priority over mere names of things. See above.)

(m) The "member of..." productions are to make it possible to write
description comprehensions without ambiguity or grammatical oddness; for
instance if a "let" name "D" holds a description, it enables us to
write "members of D" instead of just "D", making the wording of some
phrases much more natural. It's the difference between a set and its
membership, which is to say, really just a syntactic difference.

=
<s-value-uncached> ::=
	( <s-value-uncached> ) |                                            ==> { pass 1 }
	<s-variable> |                                                      ==> { -, ExParser::val(RP[1], W) }
	<if-table-column-expected> <s-table-column-name> |                  ==> { -, ExParser::val(RP[2], W) }
	<if-property-name-expected> <s-property-name> |                     ==> { -, ExParser::val(RP[2], W) }
	<s-constant-value>	|                                               ==> { -, ExParser::val(RP[1], W) }
	<s-equation-usage> |                                                ==> { pass 1 }
	<s-property-name> |                                                 ==> { -, ExParser::val(RP[1], W) }
	<s-action-pattern-as-value> |                                       ==> { -, ExParser::val(RP[1], W) }
	<s-value-phrase-non-of> |                                           ==> { -, ExParser::val(RP[1], W) }
	<s-adjective-list-as-desc> |                                        ==> { -, ExParser::val(RP[1], W) }
	<s-purely-physical-description> |                                   ==> { -, ExParser::val(RP[1], W) }
	<s-table-reference> |                                               ==> { -, ExParser::val(RP[1], W) }
	member/members of <s-description> |                                 ==> { -, ExParser::val(RP[1], W) }
	member/members of <s-local-variable> |                              ==> { -, ExParser::val(RP[1], W) }
	<s-property-name> of <s-value-uncached> |                           ==> @<Make a belonging-to-V property@>
	<if-pronoun-present> <possessive-third-person> <s-property-name> |  ==> @<Make a belonging-to-it property@>
	entry <s-value-uncached> of/in/from <s-value-uncached> |            ==> @<Make a list entry@>
	<s-description> |                                                   ==> { -, ExParser::val(RP[1], W) }
	<s-table-column-name> |                                             ==> { -, ExParser::val(RP[1], W) }
	<s-value-phrase>                                                    ==> { -, ExParser::val(RP[1], W) }

@ =
parse_node *ExParser::val(parse_node *v, wording W) {
	Node::set_text(v, W);
	return v;
}

@ =
<s-equation-usage> ::=
	<if-let-equation-mode> <s-plain-text-with-equals> where <s-plain-text> |  ==> @<Make an equation@>
	<s-value-uncached> where <s-plain-text> |                                 ==> @<Make an equation, if the kinds are right@>
	<if-let-equation-mode> <s-plain-text-with-equals>                         ==> @<Make an inline equation@>

@<Make an equation@> =
	equation *eqn = Equations::new(Node::get_text((parse_node *) RP[2]), TRUE);
	parse_node *eq = Rvalues::from_equation(eqn);
	Equations::set_wherewithal(eqn, Node::get_text((parse_node *) RP[3]));
	Equations::declare_local_variables(eqn);
	Equations::examine(eqn);
	==> { -, ExParser::val(eq, W) };

@<Make an equation, if the kinds are right@> =
	parse_node *p = RP[1];
	if (!(Rvalues::is_CONSTANT_of_kind(p, K_equation))) return FALSE;
	parse_node *eq = p;
	equation *eqn = Rvalues::to_equation(eq);
	Equations::set_usage_notes(eqn, Node::get_text((parse_node *) RP[2]));
	Equations::declare_local_variables(eqn);
	Equations::examine(eqn);
	==> { -, ExParser::val(eq, W) };

@<Make an inline equation@> =
	equation *eqn = Equations::new(Node::get_text((parse_node *) RP[2]), TRUE);
	parse_node *eq = Rvalues::from_equation(eqn);
	Equations::declare_local_variables(eqn);
	Equations::examine(eqn);
	==> { -, ExParser::val(eq, W) };


@<Make a belonging-to-it property@> =
	parse_node *lvspec =
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING,
			LocalVariables::it_variable());
	parse_node *val = ExParser::val(lvspec, EMPTY_WORDING);
	==> { -, ExParser::val(ExParser::p_o_val(RP[3], val), W) };

@<Make a belonging-to-V property@> =
	==> { -, ExParser::val(ExParser::p_o_val(RP[1], RP[2]), W) };

@<Make a list entry@> =
	parse_node *val = Lvalues::new_LIST_ENTRY(RP[2], RP[1]);
	==> { -, ExParser::val(val, W) };

@ =
parse_node *ExParser::p_o_val(parse_node *A, parse_node *B) {
	parse_node *pts =
		(Node::get_type(A) == UNKNOWN_NT) ?
			Specifications::new_UNKNOWN(Node::get_text(A)) :
			A;
	parse_node *vts = B;
	parse_node *spec = Lvalues::new_PROPERTY_VALUE(pts, vts);
	wording PW = Node::get_text(A);
	wording VW = Node::get_text(B);
	if ((Wordings::nonempty(PW)) && (Wordings::nonempty(VW))) {
		wording MW = PW;
		if (Wordings::first_wn(MW) > Wordings::first_wn(VW))
			MW = Wordings::from(MW, Wordings::first_wn(VW));
		if (Wordings::last_wn(MW) < Wordings::last_wn(VW))
			MW = Wordings::up_to(MW, Wordings::last_wn(VW));
		Node::set_text(spec, MW);
	}
	return spec;
}

@h Variables.
Internally there
are three sources of these: locals, defined by "let" or "repeat" phrases;
stacked variables, which belong to rulebooks, actions or activities; and
global variables. The narrower in scope take priority over the broader: so
if there are both local and global variables called "grand total", then
the text "grand total" is parsed as the local.

=
<s-variable> ::=
	<definite-article> <s-variable> |  ==> { pass 2 }
	<s-local-variable> |               ==> { pass 1 }
	<s-stacked-variable> |             ==> { pass 1 }
	<s-global-variable>                ==> { pass 1 }

<s-nonglobal-variable> ::=
	( <s-nonglobal-variable> ) |  ==> { pass 1 }
	<s-local-variable> |          ==> { -, ExParser::val(RP[1], W) }
	<s-stacked-variable>          ==> { -, ExParser::val(RP[1], W) }

<s-variable-as-value> ::=
	<s-variable>                  ==> { -, ExParser::val(RP[1], W) }

@ This requires three internals:

=
<s-local-variable> internal {
	local_variable *lvar = LocalVariables::parse(Frames::current_stack_frame(), W);
	if (lvar) {
		parse_node *spec = Lvalues::new_LOCAL_VARIABLE(W, lvar);
		==> { -, spec }; return TRUE;
	}
	==> { fail nonterminal };
}

@ And similarly:

=
<s-stacked-variable> internal {
	ph_stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) { ==> { fail nonterminal }; }
	stacked_variable *stv = StackedVariables::parse_from_owner_list(
		Frames::get_stvol(), W);
	if (stv) {
		parse_node *spec = Lvalues::new_actual_NONLOCAL_VARIABLE(
			StackedVariables::get_variable(stv));
		==> { -, spec }; return TRUE;
	}
	==> { fail nonterminal };
}

@ And:

=
<s-global-variable> internal {
	parse_node *p = Lexicon::retrieve(VARIABLE_MC, W);
	if (p) { ==> { -, p }; return TRUE; }
	==> { fail nonterminal };
}

@ As noted above, we want to parse phrases containing "of" cautiously in
cases where the excerpt being parsed looks as if it might be a property
rather than use of a phrase. Here's how we tell whether it looks that way:

=
<property-of-shape> ::=
	<s-property-name> of ...

@ We implement this by telling the excerpt parser, temporarily, not to match
anything including the word "of":

=
vocabulary_entry *property_word_to_suppress = NULL;

@ And here are the relevant internals:

=
<s-value-phrase-non-of> internal {
	W = Articles::remove_the(W);
	vocabulary_entry *suppression = word_to_suppress_in_phrases;
	if (<property-of-shape>(W)) {
		if (property_word_to_suppress == NULL)
			property_word_to_suppress = PreformUtilities::word(<property-of-shape>, 0);
		word_to_suppress_in_phrases = property_word_to_suppress;
	}
	parse_node *p = Lexicon::retrieve(VALUE_PHRASE_MC, W);
	word_to_suppress_in_phrases = suppression;
	if (p) {
		parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
		ExParser::add_ilist(spec, p);
		==> { -, spec }; return TRUE;
	}
	==> { fail nonterminal };
}

<s-value-phrase> internal {
	W = Articles::remove_the(W);
	parse_node *p = Lexicon::retrieve(VALUE_PHRASE_MC, W);
	if (p) {
		parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
		ExParser::add_ilist(spec, p);
		==> { -, spec }; return TRUE;
	}
	==> { fail nonterminal };
}

@h Table references.
Table references come in five different forms:

(a) For instance, "atomic number entry", meaning the entry in that column
and implicitly in the table and row currently selected.
(b) For instance, "atomic number in row 4 of the Table of Elements".
(c) For instance, "an atomic number listed in the Table of Elements" in the
sentence "if 101 is an atomic number listed in the Table of Elements". This
is part of a condition, and can't evaluate.
(d) For instance, "atomic weight corresponding to an atomic number of 57 in
the Table of Elements".
(e) For instance, "atomic weight of 20 in the Table of Elements" in the
sentence "if there is an atomic weight of 20 in the Table of Elements".
Again, this is part of a condition, and can't evaluate.

=
<s-table-reference> ::=
	<s-table-column-name> entry |    ==> @<Make table entry value@>
	<s-table-column-name> in row <s-value-uncached> of <s-value-uncached> |    ==> @<Make table in row of value@>
	<s-table-column-name> listed in <s-value-uncached> |    ==> @<Make table listed in value@>
	<s-table-column-name> corresponding to <s-table-column-name> of <s-value-uncached> in <s-value-uncached> |    ==> @<Make table corresponding to value@>
	<s-table-column-name> of <s-value-uncached> in <s-value-uncached>											==> @<Make table of in value@>

@<Make table entry value@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = RP[1];
	if ((LocalVariables::are_we_using_table_lookup() == FALSE) &&
		(problem_count == 0)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NoRowSelected),
			"no row seems to have been chosen at this point",
			"so it doesn't make sense to talk about the entries "
			"within it. (By 'at this point', I mean the point "
			"when the table will have to be looked at. This "
			"might be at another time altogether if we are "
			"storing away instructions for later in a text "
			"substitution, e.g., writing 'now the description "
			"of the player is \"Thoroughly [vanity entry].\";' "
			"- remember that the substitution is acted on "
			"when the text is printed, which could be at any "
			"time, and no row will be chosen then.)");
	}
	==> { -, spec };

@<Make table in row of value@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = ExParser::arg(RP[1]);
	spec->down->next = ExParser::arg(RP[2]);
	spec->down->next->next = ExParser::arg(RP[3]);
	==> { -, spec };

@<Make table listed in value@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = ExParser::arg(RP[1]);
	spec->down->next = ExParser::arg(RP[2]);
	==> { -, spec };

@<Make table corresponding to value@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = ExParser::arg(RP[1]);
	spec->down->next = ExParser::arg(RP[2]);
	spec->down->next->next = ExParser::arg(RP[3]);
	spec->down->next->next->next = ExParser::arg(RP[4]);
	==> { -, spec };

@<Make table of in value@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = ExParser::arg(RP[1]);
	spec->down->next = ExParser::arg(RP[1]);
	spec->down->next->next = ExParser::arg(RP[2]);
	spec->down->next->next->next = ExParser::arg(RP[3]);
	==> { -, spec };

@ =
parse_node *ExParser::arg(parse_node *val) {
	if (val == NULL) return Specifications::new_UNKNOWN(EMPTY_WORDING);
	return Node::duplicate(val);
}

@ Action patterns, such as "taking a container" or "opening a closed door",
are parsed by code in the chapter on Actions; all we do here is to wrap the
result.

=
<s-action-pattern-as-value> internal {
	#ifdef IF_MODULE
	if (Wordings::mismatched_brackets(W)) { ==> { fail nonterminal }; }
	if (Lexer::word(Wordings::first_wn(W)) == OPENBRACE_V) { ==> { fail nonterminal }; }
	int pto = permit_trying_omission;
	if (<definite-article>(Wordings::first_word(W)) == FALSE) permit_trying_omission = TRUE;
	int r = <action-pattern>(W);
	permit_trying_omission = pto;
	if (r) {
		action_pattern *ap = <<rp>>;
		if ((ap->actor_spec) &&
			(Dash::validate_parameter(ap->actor_spec, K_person) == FALSE)) {
			r = <action-pattern>(W);
		}
	}
	if (r) {
		==> { -, Conditions::new_TEST_ACTION(<<rp>>, W) };
		return TRUE;
	}
	#endif
	==> { fail nonterminal };
}
