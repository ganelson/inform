[Rvalues::] Rvalues.

Specific values which can be stored or used at run-time.

@h Testing.
An "rvalue" is a specification of an single piece of data, such as a number,
a text or a choice of object. This detects whether a specification is one:

=
int Rvalues::is_rvalue(parse_node *pn) {
	node_type_metadata *metadata = NodeType::get_metadata(Node::get_type(pn));
	if ((metadata) && (metadata->category == RVALUE_NCAT)) return TRUE;
	return FALSE;
}

@h Named constants.
Constant nodes can store references to many of the structures in this compiler:
for example, each |table *| pointer in Inform corresponds to a constant node
representing the name of that table.

Dealing with these is very repetitive, and we use macros to define the
relevant routines. Firstly, creating a CONSTANT node from one of these
pointers:

@d CONV_FROM(structure, K)
	parse_node *spec = Node::new(CONSTANT_NT);
	Node::set_kind_of_value(spec, K);
	Node::set_constant_##structure(spec, val);
	return spec;

=
parse_node *Rvalues::from_activity(activity *val) { 
		CONV_FROM(activity, Activities::to_kind(val)) }
parse_node *Rvalues::from_binary_predicate(binary_predicate *val) { 
		CONV_FROM(binary_predicate, Kinds::base_construction(CON_relation)) }
parse_node *Rvalues::from_constant_phrase(constant_phrase *val) { 
		CONV_FROM(constant_phrase, Kinds::base_construction(CON_phrase)) }
parse_node *Rvalues::from_equation(equation *val) { 
		CONV_FROM(equation, K_equation) }
parse_node *Rvalues::from_named_rulebook_outcome(named_rulebook_outcome *val) { 
		CONV_FROM(named_rulebook_outcome, K_rulebook_outcome) }
parse_node *Rvalues::from_property(property *val) { 
		CONV_FROM(property, Properties::to_kind(val)) }
parse_node *Rvalues::from_rule(rule *val) { 
		CONV_FROM(rule, Rules::to_kind(val)) }
parse_node *Rvalues::from_rulebook(rulebook *val) { 
		CONV_FROM(rulebook, Rulebooks::to_kind(val)) }
parse_node *Rvalues::from_table(table *val) { 
		CONV_FROM(table, K_table) }
parse_node *Rvalues::from_table_column(table_column *val) { 
		CONV_FROM(table_column, Tables::Columns::to_kind(val)) }
parse_node *Rvalues::from_use_option(use_option *val) { 
		CONV_FROM(use_option, K_use_option) }
parse_node *Rvalues::from_verb_form(verb_form *val) { 
		if (RTVerbs::verb_form_is_instance(val) == FALSE)
			internal_error("created rvalue for non-instance verb form");
		CONV_FROM(verb_form, K_verb) }

@ Contrariwise, here's how to get back again:

@d CONV_TO(structure)
	if (spec == NULL) return NULL;
	structure *val = Node::get_constant_##structure(spec);
	return val;

=
activity *Rvalues::to_activity(parse_node *spec) { 
		CONV_TO(activity) }
binary_predicate *Rvalues::to_binary_predicate(parse_node *spec) { 
		CONV_TO(binary_predicate) }
constant_phrase *Rvalues::to_constant_phrase(parse_node *spec) { 
		CONV_TO(constant_phrase) }
equation *Rvalues::to_equation(parse_node *spec) { 
		CONV_TO(equation) }
named_rulebook_outcome *Rvalues::to_named_rulebook_outcome(parse_node *spec) { 
		CONV_TO(named_rulebook_outcome) }
property *Rvalues::to_property(parse_node *spec) { 
		CONV_TO(property) }
rule *Rvalues::to_rule(parse_node *spec) { 
		CONV_TO(rule) }
int Rvalues::to_response_marker(parse_node *spec) { 
	if (Rvalues::is_CONSTANT_of_kind(spec, K_response)) {
		wording SW = Node::get_text(spec);
		if ((Wordings::length(SW) >= 2) &&
			(<response-letter>(Wordings::one_word(Wordings::last_wn(SW)-1))))
			return <<r>>;
	}
	return -1;
}
rulebook *Rvalues::to_rulebook(parse_node *spec) { 
		CONV_TO(rulebook) }
table *Rvalues::to_table(parse_node *spec) { 
		CONV_TO(table) }
table_column *Rvalues::to_table_column(parse_node *spec) { 
		CONV_TO(table_column) }
use_option *Rvalues::to_use_option(parse_node *spec) { 
		CONV_TO(use_option) }
verb_form *Rvalues::to_verb_form(parse_node *spec) { 
		CONV_TO(verb_form) }

@

@d VALUE_TO_RELATION_FUNCTION Rvalues::to_binary_predicate

@ With enumerated kinds, the possible values are in general stored as instance
objects.

=
parse_node *Rvalues::from_instance(instance *I) {
	parse_node *val = Node::new(CONSTANT_NT);
	Node::set_kind_of_value(val, Instances::to_kind(I));
	Node::set_constant_instance(val, I);
	Annotations::write_int(val, constant_enumeration_ANNOT, Instances::get_numerical_value(I));
	Node::set_text(val, Instances::get_name(I, FALSE));
	return val;
}

instance *Rvalues::to_instance(parse_node *spec) { 
		CONV_TO(instance) }

@ An instance of a subkind of |K_object| is called an "object":

=
int Rvalues::is_object(parse_node *spec) {
	if ((Node::is(spec, CONSTANT_NT)) &&
		(Kinds::Behaviour::is_object(Node::get_kind_of_value(spec))))
		return TRUE;
	return FALSE;
}

instance *Rvalues::to_object_instance(parse_node *spec) {
	if (Rvalues::is_object(spec)) return Rvalues::to_instance(spec);
	return NULL;
}

@ There are two pseudo-objects for which no pointers to |instance| can exist:
"self" and "nothing". These cause nothing but trouble and are marked out with
special annotations.

=
parse_node *Rvalues::new_self_object_constant(void) {
	parse_node *spec = Node::new(CONSTANT_NT);
	Node::set_kind_of_value(spec, K_object);
	Annotations::write_int(spec, self_object_ANNOT, TRUE);
	return spec;
}

parse_node *Rvalues::new_nothing_object_constant(void) {
	parse_node *spec = Node::new(CONSTANT_NT);
	Node::set_kind_of_value(spec, K_object);
	Annotations::write_int(spec, nothing_object_ANNOT, TRUE);
	return spec;
}

@ To test for the self/nothing anomalies (that really could be an episode
title from "The Big Bang Theory"),

=
int Rvalues::is_nothing_object_constant(parse_node *spec) {
	if (Annotations::read_int(spec, nothing_object_ANNOT)) return TRUE;
	return FALSE;
}

int Rvalues::is_self_object_constant(parse_node *spec) {
	if (Annotations::read_int(spec, self_object_ANNOT)) return TRUE;
	return FALSE;
}

@h Literals as rvalues.
Notation such as "24 kg" is converted inside Inform into a suitable integer,
perhaps 24000, and the following turns that into an rvalue:

=
parse_node *Rvalues::from_encoded_notation(kind *K, int encoded_value, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, K);
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Annotations::write_int(spec, constant_number_ANNOT, encoded_value);
	return spec;
}

int Rvalues::to_encoded_notation(parse_node *spec) {
	if (Annotations::read_int(spec, explicit_literal_ANNOT))
		return Annotations::read_int(spec, constant_number_ANNOT);
	return 0;
}

@ We can also convert to and from integers, but there we use an integer
annotation, not a pointer one.

=
parse_node *Rvalues::from_int(int n, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, K_number);
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Annotations::write_int(spec, constant_number_ANNOT, n);
	return spec;
}

int Rvalues::to_int(parse_node *spec) {
	if (spec == NULL) return 0;
	if (Annotations::read_int(spec, explicit_literal_ANNOT))
		return Annotations::read_int(spec, constant_number_ANNOT);
	return 0;
}

@ Internally we represent parsed reals as unsigned integers holding their
IEEE-754 representations; I don't sufficiently trust C's implementation
of |float| to be consistent across all Inform's platforms to use that instead.

=
parse_node *Rvalues::from_IEEE_754(unsigned int n, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, K_real_number);
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Annotations::write_int(spec, constant_number_ANNOT, (int) n);
	return spec;
}

unsigned int Rvalues::to_IEEE_754(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, K_real_number))
		return (unsigned int) Annotations::read_int(spec, constant_number_ANNOT);
	return 0x7F800001; /* which is a NaN value */
}

@ And exactly similarly, truth states:

=
parse_node *Rvalues::from_boolean(int flag, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, K_truth_state);
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Annotations::write_int(spec, constant_number_ANNOT, flag);
	return spec;
}

int Rvalues::to_boolean(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, K_truth_state))
		return Annotations::read_int(spec, constant_number_ANNOT);
	return FALSE;
}

@ And Unicode character values.

=
parse_node *Rvalues::from_Unicode(int code_point, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, K_unicode_character);
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Annotations::write_int(spec, constant_number_ANNOT, code_point);
	return spec;
}

int Rvalues::to_Unicode_point(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, K_unicode_character))
		return Annotations::read_int(spec, constant_number_ANNOT);
	return 0;
}

@ Version numbers require three integers.

=
parse_node *Rvalues::from_version(semantic_version_number V, wording W) {
	semantic_version_number_holder *H = CREATE(semantic_version_number_holder);
	H->version = V;
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_constant_version_number(spec, H);
	Node::set_kind_of_value(spec, K_version_number);
	return spec;
}

semantic_version_number Rvalues::to_version(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, K_version_number)) {
		semantic_version_number_holder *H = Node::get_constant_version_number(spec);
		return H->version;
	}
	return VersionNumbers::null();
}

@ In the traditional Inform world model, time is measured in minutes,
reduced modulo 1440, the number of minutes in a day.

=
parse_node *Rvalues::from_time(int minutes_since_midnight, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, TimesOfDay::kind());
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Annotations::write_int(spec, constant_number_ANNOT, minutes_since_midnight);
	return spec;
}

parse_node *Rvalues::from_time_period(int minutes, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, TimesOfDay::time_period());
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Annotations::write_int(spec, constant_number_ANNOT, minutes);
	return spec;
}

int Rvalues::to_time(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, TimesOfDay::kind()))
		return Annotations::read_int(spec, constant_number_ANNOT);
	return 0;
}

int Rvalues::to_time_period(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, TimesOfDay::time_period()))
		return Annotations::read_int(spec, constant_number_ANNOT);
	return 0;
}

@ For obscure timing reasons, we store literal lists as just their wordings
together with their kinds:

=
parse_node *Rvalues::from_wording_of_list(kind *K, wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, K);
	return spec;
}

@ Text mostly comes from wordings:

=
parse_node *Rvalues::from_wording(wording W) {
	parse_node *spec = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(spec, K_text);
	return spec;
}

@ It's convenient to have a version for text where square brackets should
be interpreted literally, not as escapes for a text substitution:

=
parse_node *Rvalues::from_unescaped_wording(wording W) {
	parse_node *spec = Rvalues::from_wording(W);
	Annotations::write_int(spec, text_unescaped_ANNOT, TRUE);
	return spec;
}

@ =
parse_node *Rvalues::from_iname(inter_name *I) {
	parse_node *spec = Node::new(CONSTANT_NT);
	Node::set_kind_of_value(spec, K_text);
	Annotations::write_int(spec, explicit_literal_ANNOT, TRUE);
	Node::set_explicit_iname(spec, I);
	return spec;
}

@h Pairs.
We can also form an r-value by combining two existing values; note that in
Inform, unlike in (say) Perl, a tuple of l-values is only an r-value, not
an l-value.

=
parse_node *Rvalues::from_pair(parse_node *X, parse_node *Y) {
	if (X == NULL) X = Specifications::new_UNKNOWN(EMPTY_WORDING);
	if (Y == NULL) Y = Specifications::new_UNKNOWN(EMPTY_WORDING);
	kind *kX = Specifications::to_true_kind_disambiguated(X);
	kind *kY = Specifications::to_true_kind_disambiguated(Y);
	kind *K = Kinds::pair_kind(kX, kY);
	parse_node *spec = Node::new(CONSTANT_NT);
	Node::set_kind_of_value(spec, K);
	spec->down = X; spec->down->next = Y;
	return spec;
}

void Rvalues::to_pair(parse_node *pair, parse_node **X, parse_node **Y) {
	*X = pair->down;
	*Y = pair->down->next;
}

@h Constant descriptions.
Note that whenever we change the proposition, the kind of the constant
may in principle change, since that depends on the free variable's kind
in the proposition.

=
parse_node *Rvalues::constant_description(pcalc_prop *prop, wording W) {
	parse_node *con = Node::new_with_words(CONSTANT_NT, W);
	Node::set_kind_of_value(con,
		Kinds::unary_con(CON_description, K_object));
	Rvalues::set_constant_description_proposition(con, prop);
	return con;
}

void Rvalues::set_constant_description_proposition(parse_node *spec, pcalc_prop *prop) {
	if (Rvalues::is_CONSTANT_construction(spec, CON_description)) {
		Node::set_proposition(spec, prop);
		Node::set_kind_of_value(spec,
			Kinds::unary_con(CON_description,
				Binding::infer_kind_of_variable_0(prop)));
	} else internal_error("set constant description proposition wrongly");
}

@h Testing.

=
int Rvalues::is_CONSTANT_construction(parse_node *spec, kind_constructor *con) {
	if ((Node::is(spec, CONSTANT_NT)) &&
		(Kinds::get_construct(Node::get_kind_of_value(spec)) == con))
		return TRUE;
	return FALSE;
}

int Rvalues::is_CONSTANT_of_kind(parse_node *spec, kind *K) {
	if ((Node::is(spec, CONSTANT_NT)) &&
		(Kinds::eq(Node::get_kind_of_value(spec), K)))
		return TRUE;
	return FALSE;
}

@ Our most elaborate test is a finicky one, checking if two constant values
are equal at compile time -- which is needed when seeing how to mesh table
continuations together, and in rare cases to help the typechecker. This
doesn't need to be especially rapid.

@d COMPARE_CONSTANTS_USING(DATA, STRUCTURE, FETCH)
	if (Kinds::get_construct(K1) == DATA) {
		STRUCTURE *x1 = FETCH(spec1);
		STRUCTURE *x2 = FETCH(spec2);
		if (x1 == x2) return TRUE;
		return FALSE;
	}

@d KCOMPARE_CONSTANTS_USING(DATA, STRUCTURE, FETCH)
	if (Kinds::eq(K1, K_##DATA)) {
		STRUCTURE *x1 = FETCH(spec1);
		STRUCTURE *x2 = FETCH(spec2);
		if (x1 == x2) return TRUE;
		return FALSE;
	}

@d KKCOMPARE_CONSTANTS_USING(DATA, STRUCTURE, FETCH)
	if (Kinds::conforms_to(K1, K_##DATA)) {
		STRUCTURE *x1 = FETCH(spec1);
		STRUCTURE *x2 = FETCH(spec2);
		if (x1 == x2) return TRUE;
		return FALSE;
	}

@d KCOMPARE_CONSTANTS(DATA, STRUCTURE)
	KCOMPARE_CONSTANTS_USING(DATA, STRUCTURE, Rvalues::to_##STRUCTURE)

=
int Rvalues::compare_CONSTANT(parse_node *spec1, parse_node *spec2) {
	if (Node::is(spec1, CONSTANT_NT) == FALSE) return FALSE;
	if (Node::is(spec2, CONSTANT_NT) == FALSE) return FALSE;
	kind *K1 = Node::get_kind_of_value(spec1);
	kind *K2 = Node::get_kind_of_value(spec2);
	if ((Kinds::conforms_to(K1, K2) == FALSE) &&
		(Kinds::conforms_to(K2, K1) == FALSE)) return FALSE;
	if (Kinds::eq(K1, K_text)) {
		if (Wordings::match_perhaps_quoted(
			Node::get_text(spec1), Node::get_text(spec2))) return TRUE;
		return FALSE;
	}
	switch (Kinds::Behaviour::get_constant_compilation_method(K1)) {
		case LITERAL_CCM:
			if (Rvalues::to_encoded_notation(spec1) ==
				Rvalues::to_encoded_notation(spec2)) return TRUE;
			return FALSE;
		case NAMED_CONSTANT_CCM: {
			instance *I1 = Rvalues::to_instance(spec1);
			instance *I2 = Rvalues::to_instance(spec2);
			if (I1 == I2) return TRUE;
			return FALSE;
		}
		case SPECIAL_CCM: {
			COMPARE_CONSTANTS_USING(CON_activity, activity, Rvalues::to_activity)
			KKCOMPARE_CONSTANTS_USING(object, instance, Rvalues::to_object_instance)
			COMPARE_CONSTANTS_USING(CON_phrase, constant_phrase, Rvalues::to_constant_phrase)
			COMPARE_CONSTANTS_USING(CON_property, property, Rvalues::to_property)
			COMPARE_CONSTANTS_USING(CON_rule, rule, Rvalues::to_rule)
			COMPARE_CONSTANTS_USING(CON_rulebook, rulebook, Rvalues::to_rulebook)
			COMPARE_CONSTANTS_USING(CON_table_column, table_column, Rvalues::to_table_column)
			KCOMPARE_CONSTANTS(equation, equation)
			COMPARE_CONSTANTS_USING(CON_relation, binary_predicate, Rvalues::to_binary_predicate)
			KCOMPARE_CONSTANTS(rulebook_outcome, named_rulebook_outcome)
			KCOMPARE_CONSTANTS(table, table)
			KCOMPARE_CONSTANTS(use_option, use_option)
			int rv = NOT_APPLICABLE;
			PluginCalls::compare_constant(spec1, spec2, &rv);
			if (rv != NOT_APPLICABLE) return rv;
		}
	}
	return FALSE;
}

@h Pretty-printing.

=
void Rvalues::write_out_in_English(OUTPUT_STREAM, parse_node *spec) {
	switch (Node::get_type(spec)) {
		case PHRASE_TO_DECIDE_VALUE_NT: {
			kind *dtr = Specifications::to_kind(spec);
			if (dtr == NULL) WRITE("a phrase");
			else {
				WRITE("an instruction to work out ");
				Kinds::Textual::write_articled(OUT, dtr);
			}
			break;
		}
		case CONSTANT_NT: {
			wording W = Node::get_text(spec);
			if (Rvalues::is_CONSTANT_construction(spec, CON_property)) {
				if (Wordings::nonempty(W)) WRITE("%+W", W);
				else WRITE("the name of a property");
				return;
			}
			if (Wordings::nonempty(W)) WRITE("%+W", W);
			else {
				WRITE("a nameless ");
				kind *dtr = Specifications::to_kind(spec);
				Kinds::Textual::write(OUT, dtr);
			}
			break;
		}
	}
}

@h Kind.
Clearly everything in this family evaluates, but what kind does the result have?

=
kind *Rvalues::to_kind(parse_node *spec) {
	if (spec == NULL) internal_error("Rvalues::to_kind on NULL");
	switch (Node::get_type(spec)) {
		case CONSTANT_NT:
			if (Rvalues::is_object(spec))
				@<Work out the kind for a constant object@>;
			if (Rvalues::is_CONSTANT_construction(spec, CON_relation))
				@<Work out the kind for a constant relation@>;
			if (Rvalues::is_CONSTANT_construction(spec, CON_property))
				@<Work out the kind for a constant property name@>;
			if (Rvalues::is_CONSTANT_construction(spec, CON_phrase))
				@<Work out the kind for a constant phrase@>;
			if (Rvalues::is_CONSTANT_construction(spec, CON_list_of))
				@<Work out the kind for a constant list@>;
			if (Rvalues::is_CONSTANT_construction(spec, CON_table_column))
				@<Work out the kind for a table column@>;
			return Node::get_kind_of_value(spec);
		case PHRASE_TO_DECIDE_VALUE_NT:
			@<Work out the kind returned by a phrase@>;
	}
	internal_error("unknown evaluating VALUE type"); return NULL;
}

@<Work out the kind for a constant object@> =
	if (Annotations::read_int(spec, self_object_ANNOT)) return K_object;
	else if (Annotations::read_int(spec, nothing_object_ANNOT)) return K_object;
	else {
		instance *I = Rvalues::to_instance(spec);
		if (I) return Instances::to_kind(I);
	}

@<Work out the kind for a constant relation@> =
	binary_predicate *bp = Rvalues::to_binary_predicate(spec);
	return BinaryPredicates::kind(bp);

@<Work out the kind for a constant property name@> =
	property *prn = Rvalues::to_property(spec);
	if (prn->either_or_data) return Kinds::unary_con(CON_property, K_truth_state);
	return Kinds::unary_con(CON_property, ValueProperties::kind(prn));

@<Work out the kind for a constant list@> =
	return Lists::kind_of_list_at(Node::get_text(spec));

@<Work out the kind for a table column@> =
	return Kinds::unary_con(CON_table_column,
		Tables::Columns::get_kind(Rvalues::to_table_column(spec)));

@ A timing issue here means that the kind will be vague until the second
assertion traverse:

@<Work out the kind for a constant phrase@> =
	return ToPhraseFamily::kind(Rvalues::to_constant_phrase(spec));

@ This too is tricky. Some phrases to decide values are unambiguous. If
they say they are "To decide a rule: ...", then clearly the return value
will be a rule. But others are "polymorphic" -- Greek for many-shaped,
but in this context, it means that the return value's kind depends on the
kinds of its arguments; addition is like this, for instance.

Compounding the problem is that we don't actually know which phrase will be
invoked -- we only have a list of possibilities. All of them return values,
but those may have different kinds, and some may be polymorphic.

So what are we to do? First, we find the "deciding invocation": the first
entry in the list which has been passed by the type-checker, or if none of
them has, then the first entry of all. If the deciding invocation is of a
phrase with an unambiguous kind, then that's of course the answer. If it is
polymorphic, then we look to see if typechecking has already resolved the
difficulty by showing the result, and if so, then that's the answer. The
worst case, then, is when we have a polymorphic phrase and typechecking
hasn't yet sorted matters out -- in that event we return simply "value"
as the kind, an extremely weak if certainly true answer.

We resort to returning |NULL|, an unknown kind, only when the invocation list
is empty. This should never happen except possibly after recovering from
some problem message.

@<Work out the kind returned by a phrase@> =
	parse_node *deciding_inv = spec->down->down;
	if (deciding_inv) {
		id_body *idb = Node::get_phrase_invoked(deciding_inv);
		if ((idb) && (IDTypeData::get_mor(&(idb->type_data)) == DECIDES_VALUE_MOR)) {
			if (IDTypeData::return_decided_dimensionally(&(idb->type_data))) {
				if (Node::get_kind_resulting(deciding_inv))
					return Node::get_kind_resulting(deciding_inv);
				return K_value;
			} else {
				if (Node::get_kind_resulting(deciding_inv))
					return Node::get_kind_resulting(deciding_inv);
				kind *K = IDTypeData::get_return_kind(&(idb->type_data));
				if (Kinds::Behaviour::definite(K) == FALSE) return K_value;
				return K;
			}
		}
	}
	return NULL;
