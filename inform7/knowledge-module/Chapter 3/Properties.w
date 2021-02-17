[Properties::] Properties.

Elements of the model world, such as objects, have properties
associated with them. Here we look after the identities of these different
properties.

@ The English word "property" is a little vague. It can mean a particular
property of a given thing -- say, the weight of a car -- or it
can mean the measurement in general terms as applied to a range of
things -- say, the notion of weight.

When we need to distinguish these, we'll call the latter a "property name".
In this and the following sections we will lay down the foundations for
knowledge about things by establishing how property names are created,
what makes some property names unlike others, and so on.

They are divided into two groups: the either/or properties, which something
either has or doesn't have, such as "closed"; and the valued properties,
which something has in degrees or in different flavours, such as "carrying
capacity" or "colour". (These are called "valued" because they associate
a value with the owner; it isn't that either/or properties are unloved.)

=
typedef struct property {
	struct wording name; /* name of property */
	int ambiguous_name; /* does this look like a property test, e.g., "point of view"? */
	struct compilation_unit *owning_module; /* where defined */

	/* the basic nature of this property */
	int either_or; /* is this an either/or property? if not, it is a valued one */
	struct linked_list *applicable_to; /* of |property_permission| */
	int do_not_compile; /* for e.g. the "specification" pseudo-property */
	int include_in_index; /* is this property shown in the indexes? */

	/* runtime implementation */
	int metadata_table_offset; /* position in the |property_metadata| word array at run-time */
	struct package_request *prop_package; /* where to find: */
	struct inter_name *prop_iname; /* the identifier we would like to use at run-time for this property */
	int translated; /* has this been given an explicit translation? */
	int prn_emitted; /* has this been emitted to Inter yet? */

	/* temporary use only */
	int indexed_already; /* and has it been, thus far in index construction? */
	int visited_on_traverse; /* for temporary use when compiling objects */
	struct possession_marker pom; /* for temporary use when checking implications */

	/* used only for either-or properties */
	int implemented_as_attribute; /* if so: is it an I6 attribute at run-time? */
	struct property *negation; /* and which property name (if any) negates it? */
	int stored_in_negation; /* this is the dummy half of an either/or pair */
	struct adjective_meaning *adjectival_meaning_registered; /* and has it been made an adjective yet? */
	struct adjective *adjective_registered; /* similarly */
	#ifdef IF_MODULE
	struct grammar_verb *eo_parsing_grammar; /* exotic forms used in parsing */
	#endif

	/* used only for valued properties */
	struct kind *property_value_kind; /* if not either/or, what kind of value does it hold? */
	struct binary_predicate *setting_bp; /* and which relation sets it? */
	struct binary_predicate *stored_bp; /* does it store the content of a relation? */
	int used_for_non_typesafe_relation; /* expressing, e.g., a 1-1 relation to a kind */
	int also_a_type; /* and is its name the same as that of the kind of value? */
	int run_time_only; /* does not correspond to an I7 property */

	/* used only for condition properties, a special kind of valued properties */
	struct inference_subject *condition_of; /* or is it a condition of an object? */
	int condition_anonymously_named; /* if so, is it named just "... condition"? */

	CLASS_DEFINITION
} property;

@ The only four properties which have special significance to core Inform
(though plugins are interested in many others):

= (early code)
property *P_specification = NULL; /* a pseudo-property for indexing kinds */
property *P_variable_initial_value = NULL; /* a pseudo-property for initialising variables */
property *P_indefinite_appearance_text = NULL;
property *P_description = NULL; /* a text property for holding annotations */
property *P_grammatical_gender = NULL; /* a value property describing names */

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
		prn = Properties::create(W, NULL, NULL);
		if (valued) {
			Properties::Valued::make_setting_relation(prn, W);
			prn->either_or = FALSE;
		} else {
			prn->either_or = TRUE;
		}
	} else {
		prn = Rvalues::to_property(p);
		if ((valued) && (prn->either_or))
			internal_error("either/or property made into valued");
		if ((valued == FALSE) && (prn->either_or == FALSE))
			internal_error("valued property made into either/or");
	}
	return prn;
}

@ And: (2) To create a new structure outright.

=
property *Properties::create(wording W, package_request *using_package, inter_name *using_iname) {
	W = Articles::remove_article(W);
	@<Ensure that the new property name is one we can live with@>;
	@<See if the property name already has a meaning, which may or may not be okay@>;

	property *prn = CREATE(property);
	@<Initialise the property name structure@>;
	@<Does the new property have the same name as a kind of value?@>;
	@<Note the significance of this property, if it needs compiler support@>;

	if (Wordings::nonempty(W)) @<Register the property name as a noun@>
	else Properties::exclude_from_index(prn);

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
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PropertyNameTooLong),
			"this is too long a name for a single property to have",
			"and would become unwieldy.");
		W = Wordings::truncate(W, MAX_WORDS_IN_ASSEMBLAGE-2);
	}
	if (<unsuitable-name>(W)) {
		unfortunate = TRUE;
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyNameUnsuitable));
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
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyNameClash));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is not free to be the name of a fresh "
				"property: it already has a meaning (as %3).");
			Problems::issue_problem_end();
		}
	}

@ So by this point the new property will be allowed.

@d UNSET_TABLE_OFFSET -654321

@<Initialise the property name structure@> =
	prn->name = W;
	prn->owning_module = CompilationUnits::find(current_sentence);
	prn->ambiguous_name = <name-looking-like-property-test>(W);
	prn->applicable_to = NEW_LINKED_LIST(property_permission);
	prn->either_or = FALSE;
	prn->prop_package = using_package;
	prn->prop_iname = using_iname;
	prn->prn_emitted = FALSE;
	prn->translated = FALSE;
	prn->do_not_compile = FALSE;
	prn->indexed_already = FALSE;
	prn->visited_on_traverse = -1;
	prn->include_in_index = TRUE;
	prn->metadata_table_offset = UNSET_TABLE_OFFSET;
	prn->run_time_only = FALSE;
	Properties::EitherOr::initialise(prn);
	Properties::Valued::initialise(prn);

@<Does the new property have the same name as a kind of value?@> =
	if (<k-kind>(W))
		Properties::Valued::make_coincide_with_kind(prn, <<rp>>);

@ This is a collection of the English names of some properties which have
special significance to Inform. Each one is recognised as it is created
by the Standard Rules (which are in English, so there's no need to translate
this to any other language).

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
				Properties::Valued::set_kind(prn, K_text);
				prn->do_not_compile = TRUE;
				prn->include_in_index = FALSE;
				PropertyPermissions::grant(model_world, P_specification, TRUE);
				break;
			case 2: P_indefinite_appearance_text = prn;
				Properties::Valued::set_kind(prn, K_text);
				prn->do_not_compile = TRUE;
				prn->include_in_index = FALSE;
				PropertyPermissions::grant(global_constants,
					P_indefinite_appearance_text, TRUE);
				break;
			case 3: P_variable_initial_value = prn;
				prn->do_not_compile = TRUE;
				Properties::Valued::set_kind(prn, K_value);
				prn->include_in_index = FALSE;
				PropertyPermissions::grant(global_variables, P_variable_initial_value, TRUE);
				break;
		}
	}
	Plugins::Call::new_property_notify(prn);

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

@h As kinds.

=
kind *Properties::to_kind(property *prn) {
	if (prn == NULL) internal_error("took kind of null property");
	kind *stored = prn->property_value_kind;
	if (prn->either_or) stored = K_truth_state;
	return Kinds::unary_con(CON_property, stored);
}

@ =
wording Properties::get_name(property *prn) {
	if (prn == NULL) return EMPTY_WORDING;
	return prn->name;
}

@h Parsing property names.
The following matches any property name, optionally preceded by the definite
article:

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

@ With two variants:

=
<either-or-property-name> internal {
	W = Articles::remove_the(W);
	property *prn;
	LOOP_OVER(prn, property)
		if (prn->either_or)
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
		if (prn->either_or == FALSE)
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

@ We call a property name "ambiguous" if, syntactically, it looks like a
reference to a property of something. For example, "point of view" could
be mistaken for the "point" property of something called "view". Formally,
it's ambiguous if it matches the following:

=
<name-looking-like-property-test> ::=
	*** of ***

@ And this internal is exactly like <property-name> except that it only
matches ambiguous cases.

=
<ambiguous-property-name> internal ? {
	property *prn;
	LOOP_OVER(prn, property)
		if (prn->ambiguous_name) {
			if (Wordings::starts_with(W, prn->name)) {
				==> { -, prn };
				return Wordings::first_wn(W) + Wordings::length(prn->name) - 1;
			}
		}
	==> { fail nonterminal };
}

@ But the following slow routine, not used very often, is also convenient for
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

@h Permissions.
Each property has a list of permissions for its usage attached. These are
important enough to have their own section: here, all we do is...

=
linked_list *Properties::get_permissions(property *prn) {
	return prn->applicable_to;
}

@h Logging.

=
void Properties::log(property *prn) {
	Properties::log_basic_pname(prn);
	if ((Streams::I6_escapes_enabled(DL)) || (prn == NULL)) return;
	if (prn->either_or) {
		property *neg = Properties::EitherOr::get_negation(prn);
		if (neg) { LOG("=~"); Properties::log_basic_pname(neg); }
	} else {
		LOG("=%u", Properties::Valued::kind(prn));
	}
}

void Properties::log_basic_pname(property *prn) {
	if (prn == NULL) { LOG("<null-property>"); return; }
	if (Wordings::nonempty(prn->name)) { LOG("'%W'", prn->name); }
	else if (prn->prop_iname) { LOG("%n", prn->prop_iname); }
	else { LOG("nameless"); }
}

@h Access to details.
As we have seen, there are two fundamentally different forms of property,
and for clarity we define two test routines, even though each is the negation
of the other:

=
int Properties::is_either_or(property *prn) {
	return prn->either_or;
}
int Properties::is_value_property(property *prn) {
	if (prn->either_or == FALSE) return TRUE;
	return FALSE;
}

@ More miscellaneously: the following flags correspond to two ways
in which properties can be "unofficial". First, the pseudo-properties
like "indefinite appearance" have no existence at run-time, and can't
be compiled, so:

=
int Properties::can_be_compiled(property *prn) {
	if ((prn == NULL) || (prn->do_not_compile)) return FALSE;
	return TRUE;
}

@ Second, a property might be missed out of the Index pages for clarity's
sake:

=
int Properties::is_shown_in_index(property *prn) {
	return prn->include_in_index;
}
void Properties::exclude_from_index(property *prn) {
	prn->include_in_index = FALSE;
}

@ During indexing we try to avoid mentioning properties more than once:

=
void Properties::set_indexed_already_flag(property *prn, int state) {
	prn->indexed_already = state;
}
int Properties::get_indexed_already_flag(property *prn) {
	return prn->indexed_already;
}

@ Used to support the run-time storage code: see "Properties of Objects".

=
void Properties::offset_in_runtime_metadata_table_is(property *prn, int pos) {
	prn->metadata_table_offset = pos;
}
int Properties::get_offset_in_runtime_metadata_table(property *prn) {
	return prn->metadata_table_offset;
}

@h Translated names of properties.
Some properties have translated names mechanically generated by Inform (indeed
all properties initially have, as we saw above), but others must have names
corresponding to those used in the template: these are, we say, "translated".
The following routine accomplishes that. It is normally used in response to
explicit requests in the source text (see below), but can also be used by
plugins to give their favourite properties names which will help their own
run-time support code to work.

=
void Properties::set_translation(property *prn, wchar_t *t) {
	if (prn == NULL) internal_error("translation set for null property");
	if ((Properties::is_either_or(prn)) && (prn->stored_in_negation)) {
		Properties::set_translation(Properties::EitherOr::get_negation(prn), t);
		return;
	}
	Properties::iname(prn);
	TEMPORARY_TEXT(T)
	for (int i=0; ((t[i]) && (i<31)); i++) {
		if ((Characters::isalpha(t[i])) || (Characters::isdigit(t[i])) || (t[i] == '_'))
			PUT_TO(T, t[i]);
		else
			PUT_TO(T, '_');
	}
	Produce::change_translation(prn->prop_iname, T);
	Hierarchy::make_available(Emit::tree(), prn->prop_iname);
	DISCARD_TEXT(T)
	prn->translated = TRUE;
}

void Properties::set_translation_S(property *prn, text_stream *t) {
	if (prn == NULL) internal_error("translation set for null property");
	if ((Properties::is_either_or(prn)) && (prn->stored_in_negation)) {
		Properties::set_translation_S(Properties::EitherOr::get_negation(prn), t);
		return;
	}
	Properties::iname(prn);
	TEMPORARY_TEXT(T)
	LOOP_THROUGH_TEXT(pos, t) {
		wchar_t c = Str::get(pos);
		if ((isalpha(c)) || (Characters::isdigit(c)) || (c == '_'))
			PUT_TO(T, (int) c);
		else
			PUT_TO(T, '_');
	}
	Str::truncate(T, 31);
	Produce::change_translation(prn->prop_iname, T);
	DISCARD_TEXT(T)
	prn->translated = TRUE;
}

int Properties::has_been_translated(property *prn) {
	return prn->translated;
}

@ And this is the routine which is called by the assertion parser in response
to sentences like:

>> The initial appearance property translates into I6 as "initial".

=
void Properties::translates(wording W, parse_node *p2) {
	property *prn = NULL;
	if (<property-name>(W)) prn = <<rp>>;
	wchar_t *text = Lexer::word_text(Wordings::first_wn(Node::get_text(p2)));

	@<Make sure this is a genuine and previously untranslated property@>;

	Properties::set_translation(prn, text);
	LOGIF(PROPERTY_TRANSLATIONS, "Property <$Y> translates as <%w>\n", prn, text);

	if (prn->either_or)
		@<Check to see if a sense reversal has taken place in translation@>;
}

@<Make sure this is a genuine and previously untranslated property@> =
	if (prn == NULL)  {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonPropertyTranslated),
			"this property does not exist",
			"so cannot be translated.");
		return;
	}
	if ((prn->translated) &&
		(Str::eq_wide_string(Produce::get_translation(Properties::iname(prn)), text) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_TranslatedTwice),
			"this property has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}

@ But there is a kick in the tail, which is that translation can reverse the
run-time parity of an either/or property. The Standard Rules normally say:

>> The open property translates into I6 as "open".

This means that information about openness is stored as |open| within the
template; an open door has |open| set, for instance. If we had written:

>> The closed property translates into I6 as "open".

then the relevant data would still have been stored as |open|, but with the
opposite sense; an open door would now be one with |open| cleared. (Of
course we'd never want to do something so confusing, but the facility
exists because Inform 7 made a few either/or properties opposite in sense
to their analogous Inform 6 ones.)

@<Check to see if a sense reversal has taken place in translation@> =
	property *neg = Properties::EitherOr::get_negation(prn);
	if (neg) {
		Properties::EitherOr::make_stored_in_negation(neg);
		LOGIF(PROPERTY_TRANSLATIONS, "Storing this way round: $Y\n", prn);
	}

@h Traversing properties.
These routines are to help other parts of Inform to visit each property just
once, when working through some complicated search space. (Visiting an either/or
property also visits its negation.)

=
int property_traverse_count = 0;
void Properties::begin_traverse(void) {
	property_traverse_count++;
}

int Properties::visited_in_traverse(property *prn) {
	if (prn->visited_on_traverse == property_traverse_count) return TRUE;
	prn->visited_on_traverse = property_traverse_count;
	if (Properties::is_either_or(prn)) {
		property *prnbar = Properties::EitherOr::get_negation(prn);
		if (prnbar) prnbar->visited_on_traverse = property_traverse_count;
	}
	return FALSE;
}

@ The "possession marker" is similarly used to keep tabs on which either/or
properties things seem to have, but only as temporary data used when working
on implications. Here we only make it available as storage.

=
possession_marker *Properties::get_possession_marker(property *prn) {
	return &(prn->pom);
}

@h Compiling property values.
Small as it may be, this routine contains two important principles: one, that
property values of something are drawn from the most specific knowledge we have
about it; and two, that if we have no knowledge of any specificity, then we fill
in a default value.

=
void Properties::compile_inferred_value(value_holster *VH, inference_subject *infs, property *prn) {
	if ((prn == NULL) || (Properties::can_be_compiled(prn) == FALSE)) return;
	while (infs) {
		if (Properties::compile_property_value_inner(VH, infs, prn)) return;
		infs = InferenceSubjects::narrowest_broader_subject(infs);
	}
	if (Properties::is_either_or(prn))
		Properties::EitherOr::compile_default_value(VH, prn);
	else
		Properties::Valued::compile_default_value(VH, prn);
}

@ Here we look for a specific subject's knowledge about our property, and if
we find it, we compile it and return |TRUE|; if not we do nothing and return
|FALSE|.

=
int Properties::compile_property_value_inner(value_holster *VH, inference_subject *infs, property *prn) {
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, property_inf) {
		if (Inferences::get_inference_type(inf) == property_inf) {
			current_sentence = Inferences::where_inferred(inf);
			int sense = (Inferences::get_certainty(inf) > 0)?TRUE:FALSE;
			property *inferred_property = PropertyInferences::get_property(inf);
			if (Properties::is_either_or(prn)) {
				if (inferred_property == prn) {
					Properties::EitherOr::compile_value(VH, inferred_property, sense);
					return TRUE;
				}
				if (inferred_property == Properties::EitherOr::get_negation(prn)) {
					Properties::EitherOr::compile_value(VH, inferred_property, sense?FALSE:TRUE);
					return TRUE;
				}
			} else {
				if (inferred_property == prn) {
					if (sense) {
						parse_node *val = PropertyInferences::get_value(inf);
						if (val == NULL) internal_error("malformed property inference");
						Properties::Valued::compile_value(VH, inferred_property, val);
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

@h Emitting to Inter.

=
inter_name *Properties::iname(property *prn) {
	if (prn == NULL) internal_error("tried to find iname for null property");
	if ((Properties::is_either_or(prn)) && (prn->stored_in_negation))
		return Properties::iname(Properties::EitherOr::get_negation(prn));
	if (prn->prop_iname == NULL) {
		prn->prop_package = Hierarchy::package(prn->owning_module, PROPERTIES_HAP);
		Hierarchy::markup_wording(prn->prop_package, PROPERTY_NAME_HMD, prn->name);
		prn->prop_iname = Hierarchy::make_iname_with_memo(PROPERTY_HL, prn->prop_package, prn->name);
	}
	return prn->prop_iname;
}

package_request *Properties::package(property *prn) {
	if (prn == NULL) internal_error("tried to find package for null property");
	if ((Properties::is_either_or(prn)) && (prn->stored_in_negation))
		return Properties::package(Properties::EitherOr::get_negation(prn));
	Properties::iname(prn);
	return prn->prop_package;
}

void Properties::emit_single(property *prn) {
	if (prn == NULL) internal_error("tried to find emit single for null property");
	if ((Properties::is_either_or(prn)) && (prn->stored_in_negation)) {
		Properties::emit_single(Properties::EitherOr::get_negation(prn));
		return;
	}
	if (prn->prn_emitted == FALSE) {
		inter_name *iname = Properties::iname(prn);

		kind *K = prn->property_value_kind;
		if (Properties::is_either_or(prn)) K = K_truth_state;
		if (K == NULL) internal_error("kindless property");
		prn->prn_emitted = TRUE;

		Emit::property(iname, K);
		if (prn->run_time_only) Emit::permission(prn, K_object, NULL);
		if (prn->translated) Produce::annotate_i(iname, EXPLICIT_ATTRIBUTE_IANN, 1);
		Produce::annotate_i(iname, SOURCE_ORDER_IANN, (inter_ti) prn->allocation_id);
	}
}

void Properties::emit(void) {
	property *prn;
	LOOP_OVER(prn, property) {
		kind *K = prn->property_value_kind;
		if (Properties::is_either_or(prn)) {
			if (prn->stored_in_negation) continue;
			K = K_truth_state;
		}
		if (K == NULL) internal_error("kindless property");
		Properties::emit_single(prn);
		property_permission *pp;
		LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn) {
			inference_subject *subj = pp->property_owner;
			if (subj == NULL) internal_error("unowned property");
			kind *K = KindSubjects::to_kind(subj);
			if (K) Emit::permission(prn, K, Properties::OfValues::annotate_table_storage(pp));
		}
	}
}

void Properties::emit_default_values(void) {
	property *prn;
	LOOP_OVER(prn, property) {
		kind *K = prn->property_value_kind;
		if (Properties::is_either_or(prn)) {
			if (prn->stored_in_negation) continue;
			K = K_truth_state;
		}
		Emit::ensure_defaultvalue(K);
	}
}

void Properties::annotate_attributes(void) {
	property *prn;
	LOOP_OVER(prn, property) {
		if (Properties::is_either_or(prn)) {
			if (prn->stored_in_negation) continue;
			Produce::annotate_i(Properties::iname(prn), EITHER_OR_IANN, 0);
			if (Properties::EitherOr::implemented_as_attribute(prn)) {
				Produce::annotate_i(Properties::iname(prn), ATTRIBUTE_IANN, 0);
			}
		}
		if (Wordings::nonempty(prn->name))
			Produce::annotate_w(Properties::iname(prn), PROPERTY_NAME_IANN, prn->name);
		if (prn->run_time_only)
			Produce::annotate_i(Properties::iname(prn), RTO_IANN, 0);
	}
	Properties::emit_default_values();
}

void Properties::emit_instance_permissions(instance *I) {
	inference_subject *subj = Instances::as_subject(I);
	property_permission *pp;
	LOOP_OVER_PERMISSIONS_FOR_INFS(pp, subj) {
		property *prn = pp->property_granted;
		if (Properties::is_either_or(prn))
			if (prn->stored_in_negation) continue;
		Emit::instance_permission(prn, RTInstances::emitted_iname(I));
	}
}
