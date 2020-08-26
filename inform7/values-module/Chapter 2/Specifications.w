[Specifications::] Specifications.

To create, manage and compare specifications.

@h Kinds vs specifications.
Specifications are portions of the parse tree representing data, or conditions
on data, or ways to manipulate it. This chapter contains utility routines
for creating and using them.

Kinds can be faithfully represented as specifications, but not vice versa:

@d VALUE_TO_KIND_FUNCTION Specifications::to_kind
@d RVALUE_TO_KIND_FUNCTION Specifications::rvalue_to_kind

=
parse_node *Specifications::from_kind(kind *K) {
	return Descriptions::from_kind(K, FALSE);
}

kind *Specifications::to_kind(parse_node *spec) {
	if (Node::is(spec, AMBIGUITY_NT)) spec = spec->down;
	if (Specifications::is_description(spec))
		return Descriptions::to_kind(spec);
	if (ParseTreeUsage::is_lvalue(spec)) return Lvalues::to_kind(spec);
	else if (ParseTreeUsage::is_rvalue(spec)) return Rvalues::to_kind(spec);
	return NULL;
}

kind *Specifications::rvalue_to_kind(parse_node *spec) {
	if (ParseTreeUsage::is_rvalue(spec))
		return Rvalues::to_kind(spec);
	return NULL;
}

kind *Specifications::to_true_kind(parse_node *spec) {
	if (ParseTreeUsage::is_lvalue(spec)) return Lvalues::to_kind(spec);
	else if (ParseTreeUsage::is_rvalue(spec)) return Rvalues::to_kind(spec);
	return NULL;
}

kind *Specifications::to_true_kind_disambiguated(parse_node *spec) {
	if (Node::is(spec, AMBIGUITY_NT)) spec = spec->down;
	if (Node::is(spec, TEST_VALUE_NT)) spec = spec->down;
	if (ParseTreeUsage::is_lvalue(spec)) return Lvalues::to_kind(spec);
	else if (ParseTreeUsage::is_rvalue(spec)) return Rvalues::to_kind(spec);
	return NULL;
}

@ We say that a specification is "kind-like" if it's one of those which could
result from |Specifications::from_kind|: for example, the description "numbers"
is kind-like, but "even numbers" is not.

=
int Specifications::is_kind_like(parse_node *spec) {
	if (Descriptions::is_kind_like(spec)) return TRUE;
	return FALSE;
}

@ Another useful characterisation is "description-like". Most nouns are not
description-like, but names of objects are. Thus "Mrs Jones" is description-like,
but "12" is not.

@d NP_IS_DESCRIPTIVE Specifications::is_description_like

=
int Specifications::is_description_like(parse_node *p) {
	int g = FALSE;
	if (Specifications::is_description(p)) g = TRUE;
	if (Rvalues::is_object(p)) g = TRUE;
	if (Rvalues::is_nothing_object_constant(p)) g = FALSE;
	return g;
}

int Specifications::is_description(parse_node *p) {
	if ((Node::is(p, TEST_VALUE_NT)) &&
		(Rvalues::is_CONSTANT_construction(p->down, CON_description))) return TRUE;
	return FALSE;
}

@

@d NP_TO_PROPOSITION Specifications::to_proposition

=
pcalc_prop *Specifications::to_proposition(parse_node *p) {
	if (p == NULL) return NULL;
	if (Specifications::is_description(p))
		return Descriptions::to_proposition(p);
	return Node::get_proposition(p);
}

inference_subject *Specifications::to_subject(parse_node *spec) {
	inference_subject *infs = NULL;
	pcalc_prop *prop = Specifications::to_proposition(spec);
	if (prop) {
		parse_node *val = Propositions::describes_value(prop);
		if (val) {
			infs = InferenceSubjects::from_specification(val);
		} else {
			kind *K = Binding::kind_of_variable_0(prop);
			if (Kinds::Behaviour::is_subkind_of_object(K) == FALSE) K = K_object;
			infs = Kinds::Knowledge::as_subject(K);
		}
	} else infs = InferenceSubjects::from_specification(spec);
	return infs;
}

@ Specifications which talk about objects lie in two different families:
"Mrs Jones" is a CONSTANT with kind "object", but "the open Bronze Gateway"
is a DESCRIPTION. The following extracts the object, if any, from either case:

=
instance *Specifications::object_exactly_described_if_any(parse_node *spec) {
	if (spec == NULL) return NULL;
	if (Specifications::is_description(spec))
		return Descriptions::to_instance(spec);
	if (Rvalues::is_object(spec)) {
		if (Rvalues::is_nothing_object_constant(spec)) return NULL;
		return Rvalues::to_instance(spec);
	}
	return NULL;
}

@ It's convenient to use specifications to represent the requirement on a
new variable declaration, such as that in "The tally is a number that varies."
We do this with the kind-like specification for "K that varies". Such a node
is called "new-variable-like".

=
parse_node *Specifications::new_new_variable_like(kind *K) {
	K = Kinds::unary_con(CON_variable, K);
	parse_node *spec = Specifications::from_kind(K);
	return spec;
}

kind *Specifications::kind_of_new_variable_like(parse_node *S) {
	kind *K = Specifications::to_kind(S);
	return Kinds::unary_construction_material(K);
}

int Specifications::is_new_variable_like(parse_node *spec) {
	if ((Specifications::is_kind_like(spec)) &&
		(Kinds::get_construct(Specifications::to_kind(spec)) == CON_variable))
		return TRUE;
	return FALSE;
}

@h Pretty-printing specifications.
We need to be able to print legible forms of translations in order to
produce good error messages, and also in order to describe phrases in the
Index; those have to be English language forms.

=
void Specifications::write_out_in_English(OUTPUT_STREAM, parse_node *spec) {
	if (spec == NULL) WRITE("something unknown");
	else if (ParseTreeUsage::is_lvalue(spec)) Lvalues::write_out_in_English(OUT, spec);
	else if (ParseTreeUsage::is_rvalue(spec)) Rvalues::write_out_in_English(OUT, spec);
	else if (ParseTreeUsage::is_condition(spec)) Conditions::write_out_in_English(OUT, spec);
	else if (Node::is(spec, AMBIGUITY_NT)) Specifications::write_out_in_English(OUT, spec->down);
	else WRITE("something unrecognised");
}

@h Sorting.
Some specifications are used to describe the applicability of rules and phrases,
and since those must be sorted in order of how specific they are, we will need
a way of telling when one specification is more specific than another. For
instance, "Will Parker in the vineyard" beats "Will Parker" beats
"a man" beats "a person" beats "an object" beats "a value".

The following is one of Inform's standardised comparison routines, which
takes a pair of objects A, B and returns 1 if A makes a more specific
description than B, 0 if they seem equally specific, or $-1$ if B makes a
more specific description than A. This is transitive, and intended to be
used in sorting algorithms.

=
int cco = 0; /* comparison count: used to make the debugging log vaguely searchable */
text_stream *c_s_stage_law = NULL; /* name of the law being applied, which caused this to be called */

int Specifications::compare_specificity(parse_node *spec1, parse_node *spec2, int *wont_mix) {
	LOGIF(SPECIFICITIES, "Law %S (test %d): comparing $P with $P\n",
		c_s_stage_law, cco++, spec1, spec2);

	@<Existence is itself something specific@>;

	int a = Specifications::is_description(spec1),
		b = Specifications::is_description(spec2);
	instance *I1 = Specifications::object_exactly_described_if_any(spec1);
	instance *I2 = Specifications::object_exactly_described_if_any(spec2);

	@<An actual specification is more specific than a generic one@>;

	@<An exact object is more specific than a vague one@>;
	if (I1) @<Enclosing regions beat enclosed ones, and regions beat rooms@>;

	if (wont_mix) @<If one matches the other, but not vice versa, it must be more specific@>;

	if ((a == TRUE) && (b == TRUE)) { /* case 1: both are descriptions */
		return Descriptions::compare_specificity(spec1, spec2);
	} else if ((a == FALSE) && (b == FALSE)) { /* case 2: neither is a description */
		@<Table entries are more specific than other non-descriptions@>;
	} else { /* case 3: one is a description, the other isn't */
		@<When is a description more specific than a non-description?@>;
	}
	return 0;
}

@ Whether or not, as Bertrand Russell thought in 1894, existence is itself a good
("Great God in Boots! Ð- the ontological argument is sound!"), a specification
which exists is certainly more significant than one which does not; and there
is nothing to choose between two specifications, neither of which exists.

A God who wears boots is an incongruous thought. Sandals, possibly. But maybe
Russell meant the local Cambridge branch of Boots, the chemist's shop. At any
rate he changed his mind in 1896.

@<Existence is itself something specific@> =
	if ((spec1 == NULL) && (spec2 != NULL)) return -1;
	if ((spec1 != NULL) && (spec2 == NULL)) return 1;
	if ((spec1 == NULL) && (spec2 == NULL)) return 0;

@ Hard to argue with this one: "34", for instance, is more specific than
"a number". (We might quibble about whether or not "a number which equals
34" is really less specific than "34" -- Inform says it is; but in fact
it doesn't much matter either way.)

@<An actual specification is more specific than a generic one@> =
	int aa = TRUE;
	if ((a) && (I1 == NULL)) aa = FALSE;
	int ba = TRUE;
	if ((b) && (I2 == NULL)) ba = FALSE;
	if ((aa) && (!ba)) return 1;
	if ((!aa) && (ba)) return -1;

@ For instance, "the open Marble Door" is more specific than "an open door"
or even just "a door", even though the latter is linguistically simpler.

@<An exact object is more specific than a vague one@> =
	if ((I1) && (I2 == NULL)) return 1;
	if ((I1 == NULL) && (I2)) return -1;

@ Suppose both specifications exactly describe objects, |I1| and |I2|, and
all other considerations are equal. It's not quite true that one object is as
good as another, because a region can be thought of as a set of rooms.
(Without the following criterion, rules such as "After waiting in Russia"
and "After waiting in Vladivostok Railway Station Waiting Room" would have
equal status.)

@<Enclosing regions beat enclosed ones, and regions beat rooms@> =
	LOGIF(SPECIFICITIES, "Test %d: Comparing specificity of instances $O and $O\n",
		cco, I1, I2);
	int pref = Plugins::Call::more_specific(I1, I2);
	if (pref != 0) return pref;

@<If one matches the other, but not vice versa, it must be more specific@> =
	int ev1 = ((a) || (ParseTreeUsage::is_value(spec1)));
	int ev2 = ((b) || (ParseTreeUsage::is_value(spec2)));
	if (Lvalues::get_storage_form(spec1) == PROPERTY_VALUE_NT) ev1 = FALSE;
	if (Lvalues::get_storage_form(spec2) == PROPERTY_VALUE_NT) ev2 = FALSE;
	if ((ev1) && (ev2)) {
		int x = Dash::compatible_with_description(spec1, spec2);
		int y = Dash::compatible_with_description(spec2, spec1);
		if (x == ALWAYS_MATCH) {
			if (y == ALWAYS_MATCH) return 0;
			else return 1;
		}
		if (y == ALWAYS_MATCH) {
			if (x == ALWAYS_MATCH) return 0;
			else return -1;
		}
		if (wont_mix) *wont_mix = TRUE;
	}

@ Here neither specification is a description or an actual object.
For the most part, then, we're left with two specifications of about equal
merit, and we don't choose between them. But in one case we do intervene: a
table entry reference beats anything else left, so that "Instead of taking
the magic key corresponding to Merlin in the Table of Arcana" is more
specific than "Instead of taking the brass key". It's questionable whether
this is a good convention, but users reported the previous absence of such
a convention as a bug, which is usually telling.

@<Table entries are more specific than other non-descriptions@> =
	int t1 = Node::is(spec1, TABLE_ENTRY_NT);
	int t2 = Node::is(spec2, TABLE_ENTRY_NT);
	if ((t1 == TRUE) && (t2 == FALSE)) return 1;
	if ((t1 == FALSE) && (t2 == TRUE)) return -1;

@ To explicate the following: a description of an exact object beats any
non-description -- thus "the open Marble Door" (a description) beats "the
Marble Door" (a constant instance). But any non-description beats a
description which is vague about the object -- thus "the Marble Door" beats
"an open door", which is not news since rules above would enact that anyway,
but also "the tallest door in the Castle" (a phrase) beats "an open door".

@<When is a description more specific than a non-description?@> =
	if (I1) { if (a == TRUE) return 1; else return -1; }
	else { if (a == TRUE) return -1; else return 1; }

@h Nothingness.

@d DETECT_NOTHING_VALUE Rvalues::is_nothing_object_constant
@d PRODUCE_NOTHING_VALUE Specifications::nothing

=
nonlocal_variable *i6_nothing_VAR = NULL; /* the I6 |nothing| constant */
parse_node *Specifications::nothing(void) {
	return Lvalues::new_actual_NONLOCAL_VARIABLE(i6_nothing_VAR);
}

@h The Unknown.
We begin with s-nodes used to represent text not yet parsed, or for which no
meaning could be found.

=
parse_node *Specifications::new_UNKNOWN(wording W) {
	return Node::new_with_words(UNKNOWN_NT, W);
}

