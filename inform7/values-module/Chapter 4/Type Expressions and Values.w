[SPType::] Type Expressions and Values.

To parse two forms of noun: a noun phrase in a sentence, and a
description of what text can be written in a given situation.

@ Inform recognises many noun-like constructions, some of which -- out of a noun
context -- look like adjectives, actions or other excerpts which aren't at all
evidently nouns. These many ways to describe nouns are gathered up into two
central constructions. A "type expression" specifies what sort of excerpt
should appear in a given place, whereas a "value" means anything which
can be a noun phrase for a verb. There is considerable overlap between the
two, but they are not the same.

The following example sentences all have expressions embedded in them:
= (text as Inform 7)
                                     EXPRESSION:
if the idea of the gizmo is          taking the fish             , ...
if there are                         three women                 in the Nunnery, ...
Before taking                        the harmonium               , ...
let X be                             the harmonium
now Y is                             the start timers rule
now Z is                             the time of day
let N be                             the number of entries in L
Understand "turn to [                number                      ]" as combination-setting.
To repeat until (C -                 condition                   ): ...
The Zeppelin countdown is a          number that varies
The little red car is a              vehicle
The weight of the Space Shuttle is   68585 kg

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
	<s-desc-uncomposite> |                       ==> { pass 1 }
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
	<s-desc-uncomposite> |          ==> @<Issue PM_TypeUnmaintainable problem@>
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

@h Unusual contexts.
Two pieces of context. "Let" mode is in operation when we are in an equation
written out in the phrase, such as here:

>> let V be given by V = fl;

=
int let_equation_mode = FALSE;
kind *probable_noun_phrase_context = NULL;

@ As mentioned earlier, this changes our conventions on word-breaking.

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
	if (Frames::is_its_enabled(
		Frames::current_stack_frame())) return TRUE;
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
The sequence here is important, in that it resolves ambiguities:

(*) Variable names have highest priority, in order to allow temporary "let"
names to mask existing meanings.
(*) Constants come next: these include literals, but also named constants,
such as names of rooms or things.
(*) Equations are an oddball exceptional case, seldom arising.
(*) Property names are not constants and, as values, they are usually read
as implicitly referring to a property value of something, not as a reference
to the property itself: thus "description" means the actual description of
some object clear from context, not the description property in the abstract.
(*) Table column names present a particular ambiguity arising from tables
which are used to construct instances. In tables like that, the column names
become names of properties owned by those instances; and then there are also
ambiguities like those with property names, as between the column's identity
and the actual contents of the current row.
(*) Phrases to decide a value whose wording mimics a property cause trouble.
I sometimes think it would be better to penalise this sort of wording by
treating it badly, but since the Standard Rules are as guilty as anyone else,
Inform instead tries to cope. Here we parse any phrase whose wording doesn't
look like a property lookup in the form "X of Y"; later we will pick up
any phrase whose wording does.
(*) Similarly we parse descriptions in two rounds: those referring to
physical objects, and others later on. This is because English tends to give
metaphorically physical names to abstract things: for example, the word
"table" for an array of data. We want to make sure sentences like "The
ball is on the table" are not misread through parsing "table" as the
name of the kind. (Type expressions have the opposite convention: there,
kind names always take priority over mere names of things. See above.)
(*) The "member of..." productions are to make it possible to write
description comprehensions without ambiguity or grammatical oddness; for
instance if a "let" name "D" holds a description, it enables us to
write "members of D" instead of just "D", making the wording of some
phrases much more natural. It's the difference between a set and its
membership, which is to say, not really a difference at all.

=
<s-value-uncached> ::=
	( <s-value-uncached> ) |                                 ==> { pass 1 }
	<s-variable> |                                           ==> { -, SPType::val(RP[1], W) }
	<if-table-column-expected> <s-table-column-name> |       ==> { -, SPType::val(RP[2], W) }
	<if-property-name-expected> <s-property-name> |          ==> { -, SPType::val(RP[2], W) }
	<s-constant-value>	|                                    ==> { -, SPType::val(RP[1], W) }
	<s-equation-usage> |                                     ==> { pass 1 }
	<s-property-name> |                                      ==> { -, SPType::val(RP[1], W) }
	<s-action-pattern-as-value> |                            ==> { -, SPType::val(RP[1], W) }
	<s-value-phrase-non-of> |                                ==> { -, SPType::val(RP[1], W) }
	<s-adjective-list-as-desc> |                             ==> { -, SPType::val(RP[1], W) }
	<s-purely-physical-description> |                        ==> { -, SPType::val(RP[1], W) }
	<s-table-reference> |                                    ==> { -, SPType::val(RP[1], W) }
	member/members of <s-description> |                      ==> { -, SPType::val(RP[1], W) }
	member/members of <s-local-variable> |                   ==> { -, SPType::val(RP[1], W) }
	<s-property-name> of <s-value-uncached> |                ==> @<Belonging-to-V prop@>
	<if-pronoun-present> <possessive-third-person> <s-property-name> | ==> @<Belonging-to-it prop@>
	entry <s-value-uncached> of/in/from <s-value-uncached> | ==> @<Make a list entry@>
	<s-description> |                                        ==> { -, SPType::val(RP[1], W) }
	<s-table-column-name> |                                  ==> { -, SPType::val(RP[1], W) }
	<s-value-phrase>                                         ==> { -, SPType::val(RP[1], W) }

@ =
parse_node *SPType::val(parse_node *v, wording W) {
	Node::set_text(v, W);
	return v;
}

@ =
<s-equation-usage> ::=
	<if-let-equation-mode> <s-plain-text-with-equals> where <s-plain-text> |  ==> @<An equation@>
	<s-value-uncached> where <s-plain-text> |                ==> @<An equation, if kinds are right@>
	<if-let-equation-mode> <s-plain-text-with-equals>        ==> @<An inline equation@>

@<An equation@> =
	equation *eqn = Equations::new(Node::get_text((parse_node *) RP[2]), TRUE);
	parse_node *eq = Rvalues::from_equation(eqn);
	Equations::set_wherewithal(eqn, Node::get_text((parse_node *) RP[3]));
	Equations::declare_local_variables(eqn);
	Equations::examine(eqn);
	==> { -, SPType::val(eq, W) };

@<An equation, if kinds are right@> =
	parse_node *p = RP[1];
	if (!(Rvalues::is_CONSTANT_of_kind(p, K_equation))) return FALSE;
	parse_node *eq = p;
	equation *eqn = Rvalues::to_equation(eq);
	EquationSolver::set_usage_notes(eqn, Node::get_text((parse_node *) RP[2]));
	Equations::declare_local_variables(eqn);
	Equations::examine(eqn);
	==> { -, SPType::val(eq, W) };

@<An inline equation@> =
	equation *eqn = Equations::new(Node::get_text((parse_node *) RP[2]), TRUE);
	parse_node *eq = Rvalues::from_equation(eqn);
	Equations::declare_local_variables(eqn);
	Equations::examine(eqn);
	==> { -, SPType::val(eq, W) };


@<Belonging-to-it prop@> =
	parse_node *lvspec =
		Lvalues::new_LOCAL_VARIABLE(EMPTY_WORDING,
			LocalVariables::it_variable());
	parse_node *val = SPType::val(lvspec, EMPTY_WORDING);
	==> { -, SPType::val(SPType::p_o_val(RP[3], val), W) };

@<Belonging-to-V prop@> =
	==> { -, SPType::val(SPType::p_o_val(RP[1], RP[2]), W) };

@<Make a list entry@> =
	parse_node *val = Lvalues::new_LIST_ENTRY(RP[2], RP[1]);
	==> { -, SPType::val(val, W) };

@ =
parse_node *SPType::p_o_val(parse_node *A, parse_node *B) {
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
shared variables, which belong to rulebooks, actions or activities; and
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
	( <s-nonglobal-variable> ) |       ==> { pass 1 }
	<s-local-variable> |               ==> { -, SPType::val(RP[1], W) }
	<s-stacked-variable>               ==> { -, SPType::val(RP[1], W) }

<s-variable-as-value> ::=
	<s-variable>                       ==> { -, SPType::val(RP[1], W) }

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
	stack_frame *phsf = Frames::current_stack_frame();
	if (phsf == NULL) { ==> { fail nonterminal }; }
	shared_variable *stv = SharedVariables::parse_from_access_list(
		Frames::get_shared_variable_access_list(), W);
	if (stv) {
		parse_node *spec = Lvalues::new_actual_NONLOCAL_VARIABLE(
			SharedVariables::get_variable(stv));
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
		SPCond::add_ilist(spec, p);
		==> { -, spec }; return TRUE;
	}
	==> { fail nonterminal };
}

<s-value-phrase> internal {
	W = Articles::remove_the(W);
	parse_node *p = Lexicon::retrieve(VALUE_PHRASE_MC, W);
	if (p) {
		parse_node *spec = Node::new_with_words(PHRASE_TO_DECIDE_VALUE_NT, W);
		SPCond::add_ilist(spec, p);
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
	<s-table-column-name> entry |                                           ==> @<Table (a)@>
	<s-table-column-name> in row <s-value-uncached> of <s-value-uncached> | ==> @<Table (b)@>
	<s-table-column-name> listed in <s-value-uncached> |                    ==> @<Table (c)@>
	<s-table-column-name> corresponding to <s-table-column-name> of <s-value-uncached> in <s-value-uncached> | ==> @<Table (d)@>
	<s-table-column-name> of <s-value-uncached> in <s-value-uncached>		==> @<Table (e)@>

@<Table (a)@> =
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

@<Table (b)@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = SPType::arg(RP[1]);
	spec->down->next = SPType::arg(RP[2]);
	spec->down->next->next = SPType::arg(RP[3]);
	==> { -, spec };

@<Table (c)@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = SPType::arg(RP[1]);
	spec->down->next = SPType::arg(RP[2]);
	==> { -, spec };

@<Table (d)@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = SPType::arg(RP[1]);
	spec->down->next = SPType::arg(RP[2]);
	spec->down->next->next = SPType::arg(RP[3]);
	spec->down->next->next->next = SPType::arg(RP[4]);
	==> { -, spec };

@<Table (e)@> =
	parse_node *spec = Lvalues::new_TABLE_ENTRY(W);
	spec->down = SPType::arg(RP[1]);
	spec->down->next = SPType::arg(RP[1]);
	spec->down->next->next = SPType::arg(RP[2]);
	spec->down->next->next->next = SPType::arg(RP[3]);
	==> { -, spec };

@ =
parse_node *SPType::arg(parse_node *val) {
	if (val == NULL) return Specifications::new_UNKNOWN(EMPTY_WORDING);
	return Node::duplicate(val);
}
