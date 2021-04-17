[ValueProperties::] Valued Properties.

Properties which attach values to subjects, with such values always having a
given kind.

@h Initialising details.
Each valued property has the following small block of data attached:

=
typedef struct value_property_data {
	struct kind *property_value_kind; /* if not either/or, what kind of value does it hold? */
	struct binary_predicate *setting_bp; /* and which relation sets it? */
	struct binary_predicate *relation_whose_state_this_stores; /* or |NULL| if it doesn't */
	struct condition_of_subject *as_condition_of_subject; /* or |NULL| if it isn't one */
	int name_coincides_with_kind; /* and is its name the same as that of a kind? */
	CLASS_DEFINITION
} value_property_data;

value_property_data *ValueProperties::new_value_data(property *prn) {
	value_property_data *vod = CREATE(value_property_data);
	vod->property_value_kind = NULL;
	vod->setting_bp = NULL;
	vod->name_coincides_with_kind = FALSE;
	vod->as_condition_of_subject = NULL;
	vod->relation_whose_state_this_stores = NULL;
	return vod;
}

@h Requesting new named properties.
Recall that there is just one property with any given name. This returns it,
or creates it if it doesn't exist. (If it does exist but is either-or, then
//Properties::obtain// will throw an internal error: so be careful.)

=
property *ValueProperties::obtain(wording W) {
	return Properties::obtain(W, TRUE);
}

@ Now the same: except that we require the property to have a given kind of
value, so that the process can go awry. (But we are allowed to avoid this
possibility by widening the kind, when this can be done.)

=
property *ValueProperties::obtain_within_kind(wording W, kind *K) {
	property *prn = NULL;
	if (K == NULL) K = K_object;
	K = Kinds::weaken(K, K_object);
	if (<property-name>(W)) {
		prn = <<rp>>;
		if (prn->value_data == NULL) @<Issue an incompatible property kind message@>;
		kind *existing_kind = prn->value_data->property_value_kind;
		switch(Kinds::compatible(K, existing_kind)) {
			case SOMETIMES_MATCH:
				if (Kinds::compatible(existing_kind, K) != ALWAYS_MATCH)
					@<Issue an incompatible property kind message@>;
				prn->value_data->property_value_kind = K; /* widen the kind */
				break;
			case NEVER_MATCH:
				@<Issue an incompatible property kind message@>;
		}
	} else {
		prn = Properties::obtain(W, TRUE);
		prn->value_data->property_value_kind = K;
	}
	return prn;
}

@<Issue an incompatible property kind message@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_BadKOVForRelationProperty),
		"that property already exists and contains a kind of value incompatible "
		"with what we need here",
		"so you will need to give it a different name.");
	return NULL;

@h Requesting new nameless properties.
Sometimes we will want a property which exists at run-time but which
has no name or visible existence at the Inform source text level. For
instance, the run-time code needs a property called |vector| in which to
store partial results when finding routes through maps, but |vector| is
nameless in the source text, unrecorded in the Index, and generally invisible
to the end user.

Core Inform creates no such properties, but many of the plugins do.

The function comes in two forms: one where we already have an iname we want
the property to have, and one where we just have the text of such a name.

=
property *ValueProperties::new_nameless(text_stream *Inter_identifier, kind *K) {
	if (K == NULL) internal_error("new nameless property without kind");
	property *prn = RTProperties::make_valued_property_identified_thus(Inter_identifier);
	IXProperties::dont_show_in_index(prn);
	@<Initialise this nameless property@>;
	return prn;
}

property *ValueProperties::new_nameless_using(kind *K, package_request *R,
	inter_name *using) {
	if (K == NULL) internal_error("new nameless property without kind");
	property *prn = Properties::create(EMPTY_WORDING, R, using, FALSE);
	RTProperties::set_translation_S(prn, InterNames::to_text(using));
	@<Initialise this nameless property@>;
	return prn;
}

@<Initialise this nameless property@> =
	IXProperties::dont_show_in_index(prn);
	prn->value_data->property_value_kind = K;
	prn->value_data->setting_bp =
		SettingPropertyRelations::make_set_nameless_property_BP(prn);
	prn->Inter_level_only = TRUE;

@h The setting relation.
Every valued property has an associated relation to set it: i.e., where
asserting this relation is the same as asserting that the property value for
term 1 is set to term 2.

=
void ValueProperties::make_setting_bp(property *prn, wording W) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	binary_predicate *bp = SettingPropertyRelations::find_set_property_BP(W);
	if (bp == NULL) bp = SettingPropertyRelations::make_set_property_BP(W);
	SettingPropertyRelations::fix_property_bp(bp);
	SettingPropertyRelations::fix_property_bp(BinaryPredicates::get_reversal(bp));
	prn->value_data->setting_bp = bp;
}

binary_predicate *ValueProperties::get_setting_bp(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	return prn->value_data->setting_bp;
}

@h Details.
The most important fact about a valued property is what kind of value it holds:

=
kind *ValueProperties::kind(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) return NULL; /* for better type-checking Problems */
	return prn->value_data->property_value_kind;
}

void ValueProperties::set_kind(property *prn, kind *K) {
	if (K == NULL) internal_error("tried to set null kind");
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	if ((Kinds::Behaviour::definite(K) == FALSE) && (RTProperties::can_be_compiled(prn))) {
		Problems::quote_wording(1, prn->name);
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_PropertyIndefinite));
		if (current_sentence) {
			Problems::quote_source(3, current_sentence);
			Problems::issue_problem_segment(
				"In the sentence %3, I am unable to create the property '%1', because "
				"it has too vague a kind ('%2'). I need to know exactly what kind of "
				"value goes into each property: for instance, it's not enough to say "
				"'A door has a list of values called the access list', because I don't "
				"know what the entries in this list would have to be - 'A door has a "
				"list of people called the access list' would be better.");
		} else {
			Problems::issue_problem_segment(
				"I am unable to create the property '%1', because it has too vague "
				"a kind ('%2'). I need to know exactly what kind of value goes into each "
				"property: for instance, it's not enough to say 'A door has a list of "
				"values called the access list', because I don't know what the entries "
				"in this list would have to be - 'A door has a list of people called the "
				"access list' would be better.");
		}
		Problems::issue_problem_end();
	}
	prn->value_data->property_value_kind = K;
}

@h Coincidence.
Sometimes the name of a property is the same as that of a kind of value. For
instance, we might define a kind of value called "weight", and then say that a
thing has a weight: that makes a property also called "weight", which is a
value property whose value is always a weight.

=
void ValueProperties::make_coincide_with_kind(property *prn, kind *K) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	ValueProperties::set_kind(prn, K);
	if (Kinds::eq(K, K_grammatical_gender)) P_grammatical_gender = prn;
	prn->value_data->name_coincides_with_kind = TRUE;
	if (Properties::can_name_coincide_with_kind(K))
		Instances::make_kind_coincident(K, prn);
}

int ValueProperties::coincides_with_kind(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	return prn->value_data->name_coincides_with_kind;
}

@h Storing relations.
Some value properties are used for relation storage at run-time:

=
void ValueProperties::set_stored_relation(property *prn, binary_predicate *bp) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	prn->value_data->relation_whose_state_this_stores = bp;
}

binary_predicate *ValueProperties::get_stored_relation(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	return prn->value_data->relation_whose_state_this_stores;
}

@h Assertion.

=
void ValueProperties::assert(property *prn, inference_subject *owner,
	parse_node *val, int certainty) {
	pcalc_prop *prop = Propositions::Abstract::to_set_property(prn, val);
	Assert::true_about(prop, owner, certainty);
}
