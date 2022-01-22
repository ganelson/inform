[Properties::] Properties.

Subjects in the model world have properties associated with them: some either/or,
others with values.

@h Introduction.
Each differently-named property has a //property// instance. It can be
had by multiple subjects -- usually kinds or instances -- which is why it
has a list of |permissions| saying who can have it, and not just one subject;
but it is the same essential property whoever has it, and in particular has
the same kind. A door and a scene could both have the property "style", but
it would have to hold the same kind of value in each case.

Properties come in two types: either/or, such as "open", which has a named
property acting as its negation, "closed"; or valued, such as "carrying
capacity". These have different semantics, and very different run-time
implementations. In this section of code, we deal with what they have in
common.

=
typedef struct property {
	struct wording name; /* name of property */
	int has_of_in_the_name; /* looks like a property test, e.g., "point of view"? */
	int Inter_level_only; /* i.e., does not correspond to an I7 property */
	struct parse_node *where_created;

	struct linked_list *permissions; /* of |property_permission|: who can have this? */

	/* exactly one of these must be non-|NULL|: */
	struct either_or_property_data *either_or_data; /* for an either/or property */
	struct value_property_data *value_data; /* for a value property */

	struct property_compilation_data compilation_data;

	struct possession_marker pom; /* for temporary use when checking implications */

	CLASS_DEFINITION
} property;

@h Creation.
We have two basic operations: (1) To find the structure corresponding to a
given textual name, creating it afresh if necessary. If we do obtain an
existing one, we need to make absolutely certain that we aren't using an
either/or property where a valued property is wanted, or vice versa.

=
property *Properties::obtain(wording W, int valued) {
	parse_node *p = Lexicon::retrieve(PROPERTY_MC, W);
	property *prn;
	if (p == NULL) {
		prn = Properties::create(W, NULL, NULL, (valued)?FALSE:TRUE, NULL);
		if (valued) ValueProperties::make_setting_bp(prn, W);
	} else {
		prn = Rvalues::to_property(p);
		if ((valued) && (prn->either_or_data))
			internal_error("either/or property made into valued");
		if ((valued == FALSE) && (prn->either_or_data == NULL))
			internal_error("valued property made into either/or");
	}
	return prn;
}

@ And: (2) To create a new structure outright.

=
property *Properties::create(wording W, package_request *using_package,
	inter_name *using_iname, int eo, text_stream *translation) {
	W = Articles::remove_article(W);
	@<Ensure that the new property name is one we can live with@>;
	@<See if the property name already has a meaning, which may or may not be okay@>;

	property *prn = CREATE(property);
	@<Initialise the property name structure@>;
	@<Does the new property have the same name as a kind of value?@>;
	@<Note the significance of this property, if it needs compiler support@>;

	if (Wordings::nonempty(W)) @<Register the property name as a noun@>
	else RTProperties::dont_show_in_index(prn);

	LOGIF(PROPERTY_CREATIONS, "Created property: $Y\n", prn);
	return prn;
}

@<Ensure that the new property name is one we can live with@> =
	int unfortunate = FALSE;
	if ((<k-kind>(W)) && (<<rp>> == K_value)) {
		unfortunate = TRUE;
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(BelievedImpossible),
			"the single word 'value' cannot be used as the name of a property",
			"because it has a much broader meaning already. Inform uses the "
			"word 'value' to mean any number, time of day, name of something, "
			"etcetera: and because of that very broadness, Inform cannot decide "
			"what kind of value a simple 'value' might be. So 'A door has "
			"a value' is not allowed; but 'A door has a number called the "
			"room number' would be fine.");
	}
	if (Wordings::length(W) > MAX_WORDS_IN_ASSEMBLAGE-2) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_PropertyNameTooLong),
			"this is too long a name for a single property to have",
			"and would become unwieldy.");
		W = Wordings::truncate(W, MAX_WORDS_IN_ASSEMBLAGE-2);
	}
	if (<unsuitable-name>(W)) {
		unfortunate = TRUE;
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_PropertyNameUnsuitable));
		Problems::issue_problem_segment(
			"The sentence %1 seems to create a new property called '%2', but "
			"this is not a good name, and I think I must have misread what "
			"you wanted. Maybe the punctuation is wrong?");
		Problems::issue_problem_end();
	}
	if (unfortunate) W = Feeds::feed_C_string(L"problem recovery name");

@ Name clashes between properties and other constructs are surprisingly often
unproblematic, so we won't reject a name just because it already means
something.

@<See if the property name already has a meaning, which may or may not be okay@> =
	if (<s-type-expression-or-value>(W)) {
		int okay = FALSE;
		parse_node *spec = <<rp>>;
		if (Specifications::is_kind_like(spec)) okay = TRUE;
		if (Rvalues::is_CONSTANT_construction(spec, CON_table_column)) okay = TRUE;
		if (Rvalues::is_CONSTANT_construction(spec, CON_property)) okay = TRUE;
		if (Specifications::is_description(spec)) okay = TRUE;
		if (Node::is(spec, NONLOCAL_VARIABLE_NT)) okay = TRUE;
		if (okay == FALSE) {
			LOG("Existing meaning: $P", spec);
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, W);
			Problems::quote_kind_of(3, spec);
			StandardProblems::handmade_problem(Task::syntax_tree(), 
				_p_(PM_PropertyNameClash));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is not free to be the name of a fresh "
				"property: it already has a meaning (as %3).");
			Problems::issue_problem_end();
		}
	}

@ So by this point the new property will be allowed.

@<Initialise the property name structure@> =
	prn->name = W;
	prn->has_of_in_the_name = <name-looking-like-property-test>(W);
	prn->where_created = current_sentence;
	prn->permissions = NEW_LINKED_LIST(property_permission);
	prn->Inter_level_only = FALSE;
	RTProperties::initialise_pcd(prn, using_package, using_iname, translation);
	if (eo) {
		prn->either_or_data = EitherOrProperties::new_eo_data(prn);
		prn->value_data = NULL;
	} else {
		prn->either_or_data = NULL;
		prn->value_data = ValueProperties::new_value_data(prn);
	}

@<Does the new property have the same name as a kind of value?@> =
	if (<k-kind>(W))
		ValueProperties::make_coincide_with_kind(prn, <<rp>>);

@ A few properties have special significance to core Inform, though plugins
are interested in many others:

= (early code)
property *P_description = NULL; /* a text property for holding annotations */
property *P_specification = NULL; /* a pseudo-property for indexing kinds */
property *P_indefinite_appearance_text = NULL; /* quoted text which seems to describe this */
property *P_variable_initial_value = NULL; /* a pseudo-property for initialising variables */
property *P_grammatical_gender = NULL; /* a value property describing names */

@ The first four of these are recognised by having the names in this Preform
nonterminal; the fifth is detected instead by having the same name as the
kind "grammatical gender" -- see //Instances::make_kind_coincident//.

=
<notable-properties> ::=
	description |
	specification |
	indefinite appearance text |
	variable initial value

@<Note the significance of this property, if it needs compiler support@> =
	if (<notable-properties>(W)) {
		switch (<<r>>) {
			case 0: P_description = prn;
				break;
			case 1: P_specification = prn;
				ValueProperties::set_kind(prn, K_text);
				RTProperties::do_not_compile(prn);
				RTProperties::dont_show_in_index(prn);
				PropertyPermissions::grant(model_world, P_specification, TRUE);
				break;
			case 2: P_indefinite_appearance_text = prn;
				ValueProperties::set_kind(prn, K_text);
				RTProperties::do_not_compile(prn);
				RTProperties::dont_show_in_index(prn);
				PropertyPermissions::grant(global_constants,
					P_indefinite_appearance_text, TRUE);
				break;
			case 3: P_variable_initial_value = prn;
				RTProperties::do_not_compile(prn);
				ValueProperties::set_kind(prn, K_value);
				RTProperties::dont_show_in_index(prn);
				PropertyPermissions::grant(global_variables, P_variable_initial_value, TRUE);
				break;
		}
	}
	PluginCalls::new_property_notify(prn);

@ To clarify their meanings as nouns, the word "property" can be prepended;
thus "the property open", for instance. We achieve this by registering the
name in both forms. The following grammar is used to construct this prefix.

=
<property-name-construction> ::=
	property ...

@<Register the property name as a noun@> =
	Nouns::new_proper_noun(W, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		PROPERTY_MC, Rvalues::from_property(prn), Task::language_of_syntax());
	word_assemblage wa =
		PreformUtilities::merge(<property-name-construction>, 0,
			WordAssemblages::from_wording(W));
	wording AW = WordAssemblages::to_wording(&wa);
	Nouns::new_proper_noun(AW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		PROPERTY_MC, Rvalues::from_property(prn), Task::language_of_syntax());

@h The kinds of properties and their contents.
For any kind $K$, "$K$-valued property" is also a kind. Note that an either-or
property is treated as if a valued property holding a "truth state".

=
kind *Properties::to_kind(property *prn) {
	if (prn == NULL) internal_error("took kind of null property");
	return Kinds::unary_con(CON_property, Properties::kind_of_contents(prn));
}

kind *Properties::kind_of_contents(property *prn) {
	if (prn == NULL) internal_error("took kind of null property");
	if (prn->either_or_data) return K_truth_state;
	return prn->value_data->property_value_kind;
}

@h Nonterminals for bare property names.
The following are slow nonterminals, but are used only in places where speed
does not matter. They match any property name, optionally preceded by the
definite article; note that they match the name itself, not the confection
made above when the noun "... property" was entered into the lexicon.

=
<property-name> internal {
	W = Articles::remove_the(W);
	property *prn;
	LOOP_OVER(prn, property)
		if (Wordings::match(W, prn->name)) {
			==> { -, prn };
			return Wordings::first_wn(W) + Wordings::length(prn->name) - 1;
		}
	==> { fail nonterminal };
}

@ With two variants, one matching only either-ors and the other only values:

=
<either-or-property-name> internal {
	W = Articles::remove_the(W);
	property *prn;
	LOOP_OVER(prn, property)
		if (prn->either_or_data)
			if (Wordings::match(W, prn->name)) {
				==> { -, prn };
				return TRUE;
			}
	==> { fail nonterminal };
}

<value-property-name> internal {
	W = Articles::remove_the(W);
	property *prn;
	LOOP_OVER(prn, property)
		if (prn->either_or_data == NULL)
			if (Wordings::match(W, prn->name)) {
				==> { -, prn };
				return TRUE;
			}
	==> { fail nonterminal };
}

@ For tiresome internal reasons, we also need a version which is voracious
(and doesn't accept the definite article):

=
<property-name-v> internal ? {
	property *prn;
	LOOP_OVER(prn, property)
		if (Wordings::starts_with(W, prn->name)) {
			==> { -, prn };
			return Wordings::first_wn(W) + Wordings::length(prn->name) - 1;
		}
	==> { fail nonterminal };
}

@ The trickiest property names are those which syntactically look like a
value of a property and not just a name. For example, a property called
"point of view" could easily be mistaken for the "point" property of something
called "view". The following should match anything with that potential
ambiguity:

=
<name-looking-like-property-test> ::=
	*** of ***

@ And this internal is exactly like <property-name-v> except that it only
matches ambiguous cases.

=
<ambiguous-property-name> internal ? {
	property *prn;
	LOOP_OVER(prn, property)
		if (prn->has_of_in_the_name) {
			if (Wordings::starts_with(W, prn->name)) {
				==> { -, prn };
				return Wordings::first_wn(W) + Wordings::length(prn->name) - 1;
			}
		}
	==> { fail nonterminal };
}

@ The following slow function, also not used very often, is also convenient for
finding the length of the longest property name at the start of an excerpt.
(The assertion parser uses this to break text like "carrying capacity 20".)

=
int Properties::match_longest(wording W) {
	int maxlen = -1;
	property *prn;
	LOOP_OVER(prn, property)
		if (Wordings::starts_with(W, prn->name))
			if (maxlen < Wordings::length(prn->name))
				maxlen = Wordings::length(prn->name);
	return maxlen;
}

@h Access functions.

=
linked_list *Properties::get_permissions(property *prn) {
	return prn->permissions;
}

wording Properties::get_name(property *prn) {
	if (prn == NULL) return EMPTY_WORDING;
	return prn->name;
}

@ The "possession marker" is used to keep tabs on which either/or properties
things seem to have, but only as temporary workspace: see //assertions: Implications//.

=
possession_marker *Properties::get_possession_marker(property *prn) {
	return &(prn->pom);
}

@ These are frequently used. As noted above, exactly one of |either_or_data|
and |value_data| is |NULL|, so these are in fact antonyms:

=
int Properties::is_either_or(property *prn) {
	return (prn->either_or_data)?TRUE:FALSE;
}
int Properties::is_value_property(property *prn) {
	return (prn->value_data)?TRUE:FALSE;
}

@h Logging.

=
void Properties::log(property *prn) {
	Properties::log_basic_pname(prn);
	if ((Streams::I6_escapes_enabled(DL)) || (prn == NULL)) return;
	if (prn->either_or_data) {
		property *neg = EitherOrProperties::get_negation(prn);
		if (neg) { LOG("=~"); Properties::log_basic_pname(neg); }
	} else {
		LOG("=%u", ValueProperties::kind(prn));
	}
}

void Properties::log_basic_pname(property *prn) {
	if (prn == NULL) { LOG("<null-property>"); return; }
	if (Wordings::nonempty(prn->name)) { LOG("'%W'", prn->name); }
	else if (prn->compilation_data.prop_iname) { LOG("%n", prn->compilation_data.prop_iname); }
	else { LOG("nameless"); }
}

@h Inter translation requests.
This is the function which is called by the assertion parser in response
to sentences like:

>> The initial appearance property translates into Inter as "initial".

=
void Properties::translates(wording W, parse_node *p2) {
	property *prn = NULL;
	if (<property-name>(W)) prn = <<rp>>;
	wchar_t *text = Lexer::word_text(Wordings::first_wn(Node::get_text(p2)));

	@<Make sure this is a genuine and previously untranslated property@>;

	Properties::set_translation(prn, text);
	LOGIF(PROPERTY_TRANSLATIONS, "Property <$Y> translates as <%w>\n", prn, text);

	if (prn->either_or_data)
		@<Check to see if a sense reversal has taken place in translation@>;
}

@<Make sure this is a genuine and previously untranslated property@> =
	if (prn == NULL)  {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_NonPropertyTranslated),
			"this property does not exist",
			"so cannot be translated.");
		return;
	}
	if ((RTProperties::has_been_translated(prn)) &&
		(Str::eq_wide_string(RTProperties::current_translation(prn), text) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TranslatedTwice),
			"this property has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}

@ But there is a kick in the tail, which is that translation can reverse the
run-time parity of an either/or property. The Standard Rules normally say:

>> The open property translates into Inter as "open".

This means that information about openness is stored as |open| within the
template; an open door has |open| set, for instance. If we had written:

>> The closed property translates into Inter as "open".

then the relevant data would still have been stored as |open|, but with the
opposite sense; an open door would now be one with |open| cleared.[1]

[1] Of course we'd never want to do something so confusing, but the facility
exists because Inform 7 made a few either/or properties opposite in sense
to their analogous Inform 6 ones.

@<Check to see if a sense reversal has taken place in translation@> =
	property *neg = EitherOrProperties::get_negation(prn);
	if (neg) {
		RTProperties::store_in_negation(neg);
		LOGIF(PROPERTY_TRANSLATIONS, "Storing this way round: $Y\n", prn);
	}

@h Compiling property values.
Small as it may be, this function contains two important principles: one, that
property values of something are drawn from the most specific knowledge we have
about it; and two, that if we have no knowledge of any specificity, then we fill
in a default value.

=
void Properties::compile_inferred_value(value_holster *VH, inference_subject *infs,
	property *prn) {
	if ((prn == NULL) || (RTProperties::can_be_compiled(prn) == FALSE)) return;
	while (infs) {
		if (Properties::compile_property_value_inner(VH, infs, prn)) return;
		infs = InferenceSubjects::narrowest_broader_subject(infs);
	}
	if (Properties::is_either_or(prn)) {
		if (Holsters::value_pair_allowed(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
	} else {
		current_sentence = NULL;
		if (RTProperties::compile_vp_default_value(VH, prn) == FALSE) {
			Problems::quote_wording(1, prn->name);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_PropertyUninitialisable));
			Problems::issue_problem_segment(
				"I am unable to put any value into the property '%1', because "
				"it seems to have a kind of value which has no actual values.");
			Problems::issue_problem_end();
		}
	}
}

@ Here we look for a specific subject's knowledge about our property, and if
we find it, we compile it and return |TRUE|; if not we do nothing and return
|FALSE|.

=
int Properties::compile_property_value_inner(value_holster *VH, inference_subject *infs,
	property *prn) {
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, property_inf) {
		if (Inferences::get_inference_type(inf) == property_inf) {
			current_sentence = Inferences::where_inferred(inf);
			int sense = (Inferences::get_certainty(inf) > 0)?TRUE:FALSE;
			property *inferred_property = PropertyInferences::get_property(inf);
			if (Properties::is_either_or(prn)) {
				if (inferred_property == prn) {
					if (Holsters::value_pair_allowed(VH))
						Holsters::holster_pair(VH, LITERAL_IVAL, (sense)?1:0);
					return TRUE;
				}
				if (inferred_property == EitherOrProperties::get_negation(prn)) {
					if (Holsters::value_pair_allowed(VH))
						Holsters::holster_pair(VH, LITERAL_IVAL, (sense)?0:1);
					return TRUE;
				}
			} else {
				if (inferred_property == prn) {
					if (sense) {
						parse_node *val = PropertyInferences::get_value(inf);
						if (val == NULL) internal_error("malformed property inference");
						CompileValues::constant_to_holster(VH, val,
							ValueProperties::kind(inferred_property));
						return TRUE;
					} else {
						internal_error("valued property with negative certainty");
					}
				}
			}
		}
	}
	return FALSE;
}

@h Coincidence.
Coincidence of kinds and properties occurs where a kind has the same name
exactly as a property, allowing the same name to be used grammatically in
two different contexts. We say that the kind and the property "coincide".
In particular, this happens with conditions:

>> Brightness is a kind of value. The brightnesses are guttering, weak, radiant and blazing. The lantern has a brightness. The lantern is blazing.

Here "brightness" becomes the name of a new kind, but "brightness" also
becomes the name of a property.

=
int Properties::can_name_coincide_with_kind(kind *K) {
	if (K == NULL) return FALSE;
	return K->construct->can_coincide_with_property;
}

property *Properties::property_with_same_name_as(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->coinciding_property;
}

void Properties::mark_kind_as_having_same_name_as(kind *K, property *P) {
	if (K == NULL) return;
	K->construct->coinciding_property = P;
}

@h Translated names of properties.
Some properties named in new source text need to be the same as those
defined in a kit of Inter code, and "P translates into Inter as N" will
arrange for that. Such translations can be done with one of two functions:

=
void Properties::set_translation(property *prn, wchar_t *t) {
	if (prn == NULL) internal_error("translation set for null property");
	if ((Properties::is_either_or(prn)) && (prn->compilation_data.store_in_negation)) {
		Properties::set_translation(EitherOrProperties::get_negation(prn), t);
		return;
	}
	TEMPORARY_TEXT(T)
	for (int i=0; ((t[i]) && (i<31)); i++) {
		if ((Characters::isalpha(t[i])) || (Characters::isdigit(t[i])) || (t[i] == '_'))
			PUT_TO(T, t[i]);
		else
			PUT_TO(T, '_');
	}
	RTProperties::set_translation_and_make_available(prn, T);
	DISCARD_TEXT(T)
}

void Properties::set_translation_from_text(property *prn, text_stream *t) {
	if (prn == NULL) internal_error("translation set for null property");
	if ((Properties::is_either_or(prn)) && (prn->compilation_data.store_in_negation)) {
		Properties::set_translation_from_text(EitherOrProperties::get_negation(prn), t);
		return;
	}
	RTProperties::iname(prn);
	TEMPORARY_TEXT(T)
	LOOP_THROUGH_TEXT(pos, t) {
		wchar_t c = Str::get(pos);
		if ((isalpha(c)) || (Characters::isdigit(c)) || (c == '_'))
			PUT_TO(T, (int) c);
		else
			PUT_TO(T, '_');
	}
	Str::truncate(T, 31);
	RTProperties::set_translation(prn, T);
	DISCARD_TEXT(T)
}
