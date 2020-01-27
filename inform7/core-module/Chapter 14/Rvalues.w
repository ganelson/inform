[Rvalues::] RValues.

Utility functions for specifications representing rvalues.

@h Constants.
Constant nodes can store references to many of the structures in this compiler:
for example, each |table *| pointer in Inform corresponds to a constant node
representing the name of that table.

Dealing with these is very repetitive, and we use macros to define the
relevant routines. Firstly, creating a CONSTANT node from one of these
pointers:

@d CONV_FROM(structure, K)
	parse_node *spec = ParseTree::new(CONSTANT_NT);
	ParseTree::set_kind_of_value(spec, K);
	ParseTree::set_constant_##structure(spec, val);
	return spec;

=
#ifdef IF_MODULE
parse_node *Rvalues::from_action_name(action_name *val) { CONV_FROM(action_name, K_action_name) }
parse_node *Rvalues::from_action_pattern(action_pattern *val) {
	if (((PL::Actions::Patterns::is_unspecific(val) == FALSE) &&
		(PL::Actions::Patterns::is_overspecific(val) == FALSE)) ||
		(preform_lookahead_mode)) {
		CONV_FROM(action_pattern, K_stored_action);
	} else {
		CONV_FROM(action_pattern, K_description_of_action);
	}
}
parse_node *Rvalues::from_grammar_verb(grammar_verb *val) { CONV_FROM(grammar_verb, K_understanding) }
parse_node *Rvalues::from_named_action_pattern(named_action_pattern *val) { CONV_FROM(named_action_pattern, K_nil) }
parse_node *Rvalues::from_scene(scene *val) { CONV_FROM(scene, K_scene) }
#endif
parse_node *Rvalues::from_activity(activity *val) { CONV_FROM(activity, Activities::to_kind(val)) }
parse_node *Rvalues::from_binary_predicate(binary_predicate *val) { CONV_FROM(binary_predicate, Kinds::base_construction(CON_relation)) }
parse_node *Rvalues::from_constant_phrase(constant_phrase *val) { CONV_FROM(constant_phrase, Kinds::base_construction(CON_phrase)) }
parse_node *Rvalues::from_equation(equation *val) { CONV_FROM(equation, K_equation) }
parse_node *Rvalues::from_named_rulebook_outcome(named_rulebook_outcome *val) { CONV_FROM(named_rulebook_outcome, K_rulebook_outcome) }
parse_node *Rvalues::from_property(property *val) { CONV_FROM(property, Properties::to_kind(val)) }
parse_node *Rvalues::from_rule(rule *val) { CONV_FROM(rule, Rules::to_kind(val)) }
parse_node *Rvalues::from_rulebook(rulebook *val) { CONV_FROM(rulebook, Rulebooks::to_kind(val)) }
parse_node *Rvalues::from_table(table *val) { CONV_FROM(table, K_table) }
parse_node *Rvalues::from_table_column(table_column *val) { CONV_FROM(table_column, Tables::Columns::to_kind(val)) }
parse_node *Rvalues::from_use_option(use_option *val) { CONV_FROM(use_option, K_use_option) }
parse_node *Rvalues::from_verb_form(verb_form *val) { CONV_FROM(verb_form, K_verb) }

@ Contrariwise, here's how to get back again:

@d CONV_TO(structure)
	if (spec == NULL) return NULL;
	structure *val = ParseTree::get_constant_##structure(spec);
	return val;

=
#ifdef IF_MODULE
action_name *Rvalues::to_action_name(parse_node *spec) { CONV_TO(action_name) }
action_pattern *Rvalues::to_action_pattern(parse_node *spec) { CONV_TO(action_pattern) }
grammar_verb *Rvalues::to_grammar_verb(parse_node *spec) { CONV_TO(grammar_verb) }
named_action_pattern *Rvalues::to_named_action_pattern(parse_node *spec) { CONV_TO(named_action_pattern) }
scene *Rvalues::to_scene(parse_node *spec) { CONV_TO(scene) }
#endif
activity *Rvalues::to_activity(parse_node *spec) { CONV_TO(activity) }
binary_predicate *Rvalues::to_binary_predicate(parse_node *spec) { CONV_TO(binary_predicate) }
constant_phrase *Rvalues::to_constant_phrase(parse_node *spec) { CONV_TO(constant_phrase) }
equation *Rvalues::to_equation(parse_node *spec) { CONV_TO(equation) }
named_rulebook_outcome *Rvalues::to_named_rulebook_outcome(parse_node *spec) { CONV_TO(named_rulebook_outcome) }
property *Rvalues::to_property(parse_node *spec) { CONV_TO(property) }
rule *Rvalues::to_rule(parse_node *spec) { CONV_TO(rule) }
rulebook *Rvalues::to_rulebook(parse_node *spec) { CONV_TO(rulebook) }
table *Rvalues::to_table(parse_node *spec) { CONV_TO(table) }
table_column *Rvalues::to_table_column(parse_node *spec) { CONV_TO(table_column) }
use_option *Rvalues::to_use_option(parse_node *spec) { CONV_TO(use_option) }
verb_form *Rvalues::to_verb_form(parse_node *spec) { CONV_TO(verb_form) }

@ With enumerated kinds, the possible values are in general stored as instance
objects.

=
parse_node *Rvalues::from_instance(instance *I) {
	parse_node *val = ParseTree::new(CONSTANT_NT);
	ParseTree::set_kind_of_value(val, Instances::to_kind(I));
	ParseTree::set_constant_instance(val, I);
	ParseTree::annotate_int(val, constant_enumeration_ANNOT, Instances::get_numerical_value(I));
	ParseTree::set_text(val, Instances::get_name(I, FALSE));
	return val;
}

instance *Rvalues::to_instance(parse_node *spec) { CONV_TO(instance) }

@ An instance of a subkind of |K_object| is called an "object":

=
int Rvalues::is_object(parse_node *spec) {
	if ((ParseTree::is(spec, CONSTANT_NT)) &&
		(Kinds::Compare::le(ParseTree::get_kind_of_value(spec), K_object)))
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
	parse_node *spec = ParseTree::new(CONSTANT_NT);
	ParseTree::set_kind_of_value(spec, K_object);
	ParseTree::annotate_int(spec, self_object_ANNOT, TRUE);
	return spec;
}

parse_node *Rvalues::new_nothing_object_constant(void) {
	parse_node *spec = ParseTree::new(CONSTANT_NT);
	ParseTree::set_kind_of_value(spec, K_object);
	ParseTree::annotate_int(spec, nothing_object_ANNOT, TRUE);
	return spec;
}

@ To test for the self/nothing anomalies (that really could be an episode
title from "The Big Bang Theory"),

=
int Rvalues::is_nothing_object_constant(parse_node *spec) {
	if (ParseTree::int_annotation(spec, nothing_object_ANNOT)) return TRUE;
	return FALSE;
}

int Rvalues::is_self_object_constant(parse_node *spec) {
	if (ParseTree::int_annotation(spec, self_object_ANNOT)) return TRUE;
	return FALSE;
}

@h Literals as rvalues.
Notation such as "24 kg" is converted inside Inform into a suitable integer,
perhaps 24000, and the following turns that into an rvalue:

=
parse_node *Rvalues::from_encoded_notation(kind *K, int encoded_value, wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, K);
	ParseTree::annotate_int(spec, explicit_literal_ANNOT, TRUE);
	ParseTree::annotate_int(spec, constant_number_ANNOT, encoded_value);
	return spec;
}

int Rvalues::to_encoded_notation(parse_node *spec) {
	if (ParseTree::int_annotation(spec, explicit_literal_ANNOT))
		return ParseTree::int_annotation(spec, constant_number_ANNOT);
	return 0;
}

@ We can also convert to and from integers, but there we use an integer
annotation, not a pointer one.

=
parse_node *Rvalues::from_int(int n, wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, K_number);
	ParseTree::annotate_int(spec, explicit_literal_ANNOT, TRUE);
	ParseTree::annotate_int(spec, constant_number_ANNOT, n);
	return spec;
}

int Rvalues::to_int(parse_node *spec) {
	if (spec == NULL) return 0;
	if (ParseTree::int_annotation(spec, explicit_literal_ANNOT))
		return ParseTree::int_annotation(spec, constant_number_ANNOT);
	return 0;
}

@ Internally we represent parsed reals as unsigned integers holding their
IEEE-754 representations; I just don't sufficiently trust C's implementation
of |float| to be consistent across all Inform's platforms to use it.

=
parse_node *Rvalues::from_IEEE_754(unsigned int n, wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, K_real_number);
	ParseTree::annotate_int(spec, explicit_literal_ANNOT, TRUE);
	ParseTree::annotate_int(spec, constant_number_ANNOT, (int) n);
	return spec;
}

unsigned int Rvalues::to_IEEE_754(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, K_real_number))
		return (unsigned int) ParseTree::int_annotation(spec, constant_number_ANNOT);
	return 0x7F800001; /* which is a NaN value */
}

@ And exactly similarly, truth states:

=
parse_node *Rvalues::from_boolean(int flag, wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, K_truth_state);
	ParseTree::annotate_int(spec, explicit_literal_ANNOT, TRUE);
	ParseTree::annotate_int(spec, constant_number_ANNOT, flag);
	return spec;
}

int Rvalues::to_boolean(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, K_truth_state))
		return ParseTree::int_annotation(spec, constant_number_ANNOT);
	return FALSE;
}

@ And Unicode character values.

=
parse_node *Rvalues::from_Unicode_point(int code_point, wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, K_unicode_character);
	ParseTree::annotate_int(spec, explicit_literal_ANNOT, TRUE);
	ParseTree::annotate_int(spec, constant_number_ANNOT, code_point);
	return spec;
}

int Rvalues::to_Unicode_point(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, K_unicode_character))
		return ParseTree::int_annotation(spec, constant_number_ANNOT);
	return 0;
}

@ In the traditional Inform world model, time is measured in minutes,
reduced modulo 1440, the number of minutes in a day.

=
parse_node *Rvalues::from_time(int minutes_since_midnight, wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, PL::TimesOfDay::kind());
	ParseTree::annotate_int(spec, explicit_literal_ANNOT, TRUE);
	ParseTree::annotate_int(spec, constant_number_ANNOT, minutes_since_midnight);
	return spec;
}

int Rvalues::to_time(parse_node *spec) {
	if (Rvalues::is_CONSTANT_of_kind(spec, PL::TimesOfDay::kind()))
		return ParseTree::int_annotation(spec, constant_number_ANNOT);
	return 0;
}

@ For obscure timing reasons, we store literal lists as just their wordings
together with their kinds:

=
parse_node *Rvalues::from_wording_of_list(kind *K, wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, K);
	return spec;
}

@ Text mostly comes from wordings:

=
parse_node *Rvalues::from_wording(wording W) {
	parse_node *spec = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(spec, K_text);
	return spec;
}

@ It's convenient to have a version for text where square brackets should
be interpreted literally, not as escapes for a text substitution:

=
parse_node *Rvalues::from_unescaped_wording(wording W) {
	parse_node *spec = Rvalues::from_wording(W);
	ParseTree::annotate_int(spec, text_unescaped_ANNOT, TRUE);
	return spec;
}

@ =
parse_node *Rvalues::from_iname(inter_name *I) {
	parse_node *spec = ParseTree::new(CONSTANT_NT);
	ParseTree::set_kind_of_value(spec, K_text);
	ParseTree::annotate_int(spec, explicit_literal_ANNOT, TRUE);
	ParseTree::set_explicit_iname(spec, I);
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
	parse_node *spec = ParseTree::new(CONSTANT_NT);
	ParseTree::set_kind_of_value(spec, K);
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
	parse_node *con = ParseTree::new_with_words(CONSTANT_NT, W);
	ParseTree::set_kind_of_value(con,
		Kinds::unary_construction(CON_description, K_object));
	Rvalues::set_constant_description_proposition(con, prop);
	return con;
}

void Rvalues::set_constant_description_proposition(parse_node *spec, pcalc_prop *prop) {
	if (Rvalues::is_CONSTANT_construction(spec, CON_description)) {
		ParseTree::set_proposition(spec, prop);
		ParseTree::set_kind_of_value(spec,
			Kinds::unary_construction(CON_description,
				Calculus::Variables::infer_kind_of_variable_0(prop)));
	} else internal_error("set constant description proposition wrongly");
}

@h Testing.

=
int Rvalues::is_CONSTANT_construction(parse_node *spec, kind_constructor *con) {
	if ((ParseTree::is(spec, CONSTANT_NT)) &&
		(Kinds::get_construct(ParseTree::get_kind_of_value(spec)) == con))
		return TRUE;
	return FALSE;
}

int Rvalues::is_CONSTANT_of_kind(parse_node *spec, kind *K) {
	if ((ParseTree::is(spec, CONSTANT_NT)) &&
		(Kinds::Compare::eq(ParseTree::get_kind_of_value(spec), K)))
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
	if (Kinds::Compare::eq(K1, K_##DATA)) {
		STRUCTURE *x1 = FETCH(spec1);
		STRUCTURE *x2 = FETCH(spec2);
		if (x1 == x2) return TRUE;
		return FALSE;
	}

@d KKCOMPARE_CONSTANTS_USING(DATA, STRUCTURE, FETCH)
	if (Kinds::Compare::le(K1, K_##DATA)) {
		STRUCTURE *x1 = FETCH(spec1);
		STRUCTURE *x2 = FETCH(spec2);
		if (x1 == x2) return TRUE;
		return FALSE;
	}

@d KCOMPARE_CONSTANTS(DATA, STRUCTURE)
	KCOMPARE_CONSTANTS_USING(DATA, STRUCTURE, Rvalues::to_##STRUCTURE)

=
int Rvalues::compare_CONSTANT(parse_node *spec1, parse_node *spec2) {
	if (ParseTree::is(spec1, CONSTANT_NT) == FALSE) return FALSE;
	if (ParseTree::is(spec2, CONSTANT_NT) == FALSE) return FALSE;
	kind *K1 = ParseTree::get_kind_of_value(spec1);
	kind *K2 = ParseTree::get_kind_of_value(spec2);
	if ((Kinds::Compare::le(K1, K2) == FALSE) &&
		(Kinds::Compare::le(K2, K1) == FALSE)) return FALSE;
	if (Kinds::Compare::eq(K1, K_text)) {
		if (Wordings::match_perhaps_quoted(
			ParseTree::get_text(spec1), ParseTree::get_text(spec2))) return TRUE;
		return FALSE;
	}
	switch (Kinds::Behaviour::get_constant_compilation_method(K1)) {
		case LITERAL_CCM:
			if (Rvalues::to_encoded_notation(spec1) == Rvalues::to_encoded_notation(spec2)) return TRUE;
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
			#ifdef IF_MODULE
			KCOMPARE_CONSTANTS(action_name, action_name)
			KCOMPARE_CONSTANTS(scene, scene)
			KCOMPARE_CONSTANTS(understanding, grammar_verb)
			#endif
		}
	}
	return FALSE;
}

@h Pretty-printing.

=
void Rvalues::write_out_in_English(OUTPUT_STREAM, parse_node *spec) {
	switch (ParseTree::get_type(spec)) {
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
			wording W = ParseTree::get_text(spec);
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

@ And for the log:

=
void Rvalues::log(parse_node *spec) {
	switch (ParseTree::get_type(spec)) {
		case CONSTANT_NT: {
			instance *I = Rvalues::to_instance(spec);
			if (I) LOG("(%~I)", I);
			if (Rvalues::is_object(spec)) {
				if (ParseTree::int_annotation(spec, self_object_ANNOT)) LOG("(-self-)");
				else if (ParseTree::int_annotation(spec, nothing_object_ANNOT)) LOG("(-nothing-)");
				else LOG("($O)", Rvalues::to_instance(spec));
			}
		}
	}
}

@h Compilation.
First: clearly everything in this family evaluates, but what kind does the
result have?

=
kind *Rvalues::to_kind(parse_node *spec) {
	if (spec == NULL) internal_error("Rvalues::to_kind on NULL");
	switch (ParseTree::get_type(spec)) {
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
			return ParseTree::get_kind_of_value(spec);
		case PHRASE_TO_DECIDE_VALUE_NT:
			@<Work out the kind returned by a phrase@>;
	}
	internal_error("unknown evaluating VALUE type"); return NULL;
}

@ This is trickier than it looks. What kind shall we say that the constants
"nothing", "Cobbled Crawl", or "animal" have? The answer is the
narrowest we can: "nothing" comes out as "object", "Cobbled Crawl"
as "room" (a kind of object), "animal" as itself (ditto).

@<Work out the kind for a constant object@> =
	if (ParseTree::int_annotation(spec, self_object_ANNOT)) return K_object;
	else if (ParseTree::int_annotation(spec, nothing_object_ANNOT)) return K_object;
	else {
		instance *I = Rvalues::to_instance(spec);
		if (I) return Instances::to_kind(I);
	}

@ Not a base kind:

@<Work out the kind for a constant relation@> =
	binary_predicate *bp = Rvalues::to_binary_predicate(spec);
	return BinaryPredicates::kind(bp);

@<Work out the kind for a constant property name@> =
	property *prn = Rvalues::to_property(spec);
	if (prn->either_or) return Kinds::unary_construction(CON_property, K_truth_state);
	return Kinds::unary_construction(CON_property, Properties::Valued::kind(prn));

@<Work out the kind for a constant list@> =
	return Lists::kind_of_list_at(ParseTree::get_text(spec));

@<Work out the kind for a table column@> =
	return Kinds::unary_construction(CON_table_column,
		Tables::Columns::get_kind(Rvalues::to_table_column(spec)));

@ A timing issue here means that the kind will be vague until the second
assertion traverse:

@<Work out the kind for a constant phrase@> =
	return Phrases::Constants::kind(Rvalues::to_constant_phrase(spec));

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
		phrase *ph = ParseTree::get_phrase_invoked(deciding_inv);
		if ((ph) && (Phrases::TypeData::get_mor(&(ph->type_data)) == DECIDES_VALUE_MOR)) {
			if (Phrases::TypeData::return_decided_dimensionally(&(ph->type_data))) {
				if (ParseTree::get_kind_resulting(deciding_inv)) return ParseTree::get_kind_resulting(deciding_inv);
				return K_value;
			} else {
				if (ParseTree::get_kind_resulting(deciding_inv)) return ParseTree::get_kind_resulting(deciding_inv);
				kind *K = Phrases::TypeData::get_return_kind(&(ph->type_data));
				if (Kinds::Behaviour::definite(K) == FALSE) return K_value;
				return K;
			}
		}
	}
	return NULL;

@ And so to the code for compiling constants.

=
void Rvalues::compile(value_holster *VH, parse_node *spec_found) {
	switch(ParseTree::get_type(spec_found)) {
		case PHRASE_TO_DECIDE_VALUE_NT:
			Invocations::Compiler::compile_invocation_list(VH,
				spec_found->down->down, ParseTree::get_text(spec_found));
			break;
		case CONSTANT_NT: {
			kind *kind_of_constant = ParseTree::get_kind_of_value(spec_found);
			int ccm = Kinds::Behaviour::get_constant_compilation_method(kind_of_constant);
			switch(ccm) {
				case NONE_CCM: /* constant values of this kind cannot exist */
					LOG("SP: $P; kind: $u\n", spec_found, kind_of_constant);
					internal_error("Tried to compile CONSTANT SP for a disallowed kind");
					return;
				case LITERAL_CCM: @<Compile a literal-compilation-mode constant@>; return;
				case NAMED_CONSTANT_CCM: @<Compile a quantitative-compilation-mode constant@>; return;
				case SPECIAL_CCM: @<Compile a special-compilation-mode constant@>; return;
			}
			break;
		}
	}
}

@ There are three basic compilation modes.

Here, the literal-parser is used to resolve the text of the SP to an integer.
I6 is typeless, of course, so it doesn't matter that this is not necessarily
a number: all that matters is that the correct integer value is compiled.

@<Compile a literal-compilation-mode constant@> =
	int N = Rvalues::to_int(spec_found);
	if (Holsters::data_acceptable(VH))
		Holsters::holster_pair(VH, LITERAL_IVAL, (inter_t) N);

@ Whereas here, an instance is attached.

@<Compile a quantitative-compilation-mode constant@> =
	instance *I = ParseTree::get_constant_instance(spec_found);
	if (I) {
		if (Holsters::data_acceptable(VH)) {
			inter_name *N = Instances::emitted_iname(I);
			if (N) Emit::holster(VH, N);
			else internal_error("no iname for instance");
		}
	} else internal_error("no instance");

@ Otherwise there are just miscellaneous different things to do in different
kinds of value:

@<Compile a special-compilation-mode constant@> =
	if (Plugins::Call::compile_constant(VH, kind_of_constant, spec_found))
		return;
	if (Kinds::get_construct(kind_of_constant) == CON_activity) {
		activity *act = Rvalues::to_activity(spec_found);
		inter_name *N = Activities::iname(act);
		if (N) Emit::holster(VH, N);
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_combination) {
		int NC = 0;
		for (parse_node *term = spec_found->down; term; term = term->next) NC++;
		int NT = 0, downs = 0;
		for (parse_node *term = spec_found->down; term; term = term->next) {
			NT++;
			if (NT < NC) {
				Produce::inv_primitive(Emit::tree(), SEQUENTIAL_BIP);
				Produce::down(Emit::tree()); downs++;
			}
			Specifications::Compiler::emit_as_val(K_value, term);
		}
		while (downs > 0) { Produce::up(Emit::tree()); downs--; }
		return;
	}
	if (Kinds::Compare::eq(kind_of_constant, K_equation)) {
		equation *eqn = Rvalues::to_equation(spec_found);
		inter_name *N = Equations::identifier(eqn);
		if (N) Emit::holster(VH, N);
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_description) {
		Calculus::Deferrals::compile_multiple_use_proposition(VH,
			spec_found, Kinds::unary_construction_material(kind_of_constant));
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_list_of) {
		inter_name *N = Lists::compile_literal_list(ParseTree::get_text(spec_found));
		if (N) Emit::holster(VH, N);
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_phrase) {
		constant_phrase *cphr = Rvalues::to_constant_phrase(spec_found);
		inter_name *N = Phrases::Constants::compile(cphr);
		if (N) Emit::holster(VH, N);
		return;
	}
	if (Kinds::Compare::le(kind_of_constant, K_object)) {
		if (ParseTree::int_annotation(spec_found, self_object_ANNOT)) {
			if (Holsters::data_acceptable(VH)) {
				Emit::holster(VH, Hierarchy::find(SELF_HL));
			}
		} else if (ParseTree::int_annotation(spec_found, nothing_object_ANNOT)) {
			if (Holsters::data_acceptable(VH))
				Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		} else {
			instance *I = Rvalues::to_instance(spec_found);
			if (I) {
				inter_name *N = Instances::emitted_iname(I);
				if (N) Emit::holster(VH, N);
			}
			parse_node *NB = Routines::Compile::line_being_compiled();
			if (NB) Instances::note_usage(I, NB);
		}
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_property) {
		@<Compile property constants@>;
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_relation) {
		binary_predicate *bp = Rvalues::to_binary_predicate(spec_found);
		BinaryPredicates::mark_as_needed(bp);
		inter_name *N = BinaryPredicates::iname(bp);
		if (N) Emit::holster(VH, N);
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_rule) {
		rule *R = Rvalues::to_rule(spec_found);
		Emit::holster(VH, Rules::iname(R));
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_rulebook) {
		rulebook *rb = Rvalues::to_rulebook(spec_found);
		if (Holsters::data_acceptable(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, (inter_t) rb->allocation_id);
		return;
	}
	if (Kinds::Compare::eq(kind_of_constant, K_rulebook_outcome)) {
		named_rulebook_outcome *rbno =
			Rvalues::to_named_rulebook_outcome(spec_found);
		Emit::holster(VH, rbno->nro_iname);
		return;
	}
	if (Kinds::Compare::eq(kind_of_constant, K_table)) {
		table *t = Rvalues::to_table(spec_found);
		Emit::holster(VH, Tables::identifier(t));
		return;
	}
	if (Kinds::get_construct(kind_of_constant) == CON_table_column) {
		table_column *tc = Rvalues::to_table_column(spec_found);
		if (Holsters::data_acceptable(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, (inter_t) Tables::Columns::get_id(tc));
		return;
	}
	if (Kinds::Compare::eq(kind_of_constant, K_text)) {
		Strings::compile_general(VH, spec_found);
		return;
	}
	#ifdef IF_MODULE
	if ((K_understanding) && (Kinds::Compare::eq(kind_of_constant, K_understanding))) {
		if (Wordings::empty(ParseTree::get_text(spec_found)))
			internal_error("Text no longer available for CONSTANT/UNDERSTANDING");
		inter_t v1 = 0, v2 = 0;
		PL::Parsing::compile_understanding(&v1, &v2, ParseTree::get_text(spec_found), FALSE);
		if (Holsters::data_acceptable(VH)) {
			Holsters::holster_pair(VH, v1, v2);
		}
		return;
	}
	#endif
	if (Kinds::Compare::eq(kind_of_constant, K_use_option)) {
		use_option *uo = Rvalues::to_use_option(spec_found);
		if (Holsters::data_acceptable(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, (inter_t) uo->allocation_id);
		return;
	}
	if (Kinds::Compare::eq(kind_of_constant, K_verb)) {
		verb_form *vf = Rvalues::to_verb_form(spec_found);
		Emit::holster(VH, Verbs::form_iname(vf));
		return;
	}
	if (Kinds::Compare::eq(kind_of_constant, K_response)) {
		rule *R = Rvalues::to_rule(spec_found);
		int c = ParseTree::int_annotation(spec_found, response_code_ANNOT);
		inter_name *iname = Strings::response_constant_iname(R, c);
		if (iname) Emit::holster(VH, iname);
		else Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		Rules::now_rule_needs_response(R, c, EMPTY_WORDING);
		return;
	}

	LOG("Kov is $u\n", kind_of_constant);
	internal_error("no special ccm provided");

@ The interesting, read "unfortunate", case is that of constant property
names. The curiosity here is that it's legal to store the nameless negation
of an either/or property in a "property" constant. This is purely so that
the following ungainly syntax works:

>> change X to not P;

Recall that in Inform 6 syntax, an attribute |attr| can be negated in sense
in several contexts by using a tilde: |~attr|.

@<Compile property constants@> =
	property *prn = Rvalues::to_property(spec_found);
	if (prn == NULL) internal_error("PROPERTY SP with null property");

	if (Properties::is_either_or(prn)) {
		int parity = 1;
		property *prn_to_eval = prn;
		if (<negated-clause>(ParseTree::get_text(spec_found))) parity = -1;
		if (Properties::EitherOr::stored_in_negation(prn)) {
			parity = -parity;
			prn_to_eval = Properties::EitherOr::get_negation(prn_to_eval);
		}

		if (Holsters::data_acceptable(VH)) {
			if (parity == 1) {
				Emit::holster(VH, Properties::iname(prn_to_eval));
			} else {
				Problems::Issue::sentence_problem(_p_(Untestable),
					"this refers to an either-or property with a negative "
					"that I can't unravel'",
					"which normally never happens. (Are you using 'change' "
					"instead of 'now'?");
			}
		}
	} else {
		if (Holsters::data_acceptable(VH)) {
			Emit::holster(VH, Properties::iname(prn));
		}
	}
