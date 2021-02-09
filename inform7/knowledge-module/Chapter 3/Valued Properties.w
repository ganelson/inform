[Properties::Valued::] Valued Properties.

Properties which consist of an attached value, always having a
given kind.

@h Requesting new named properties.
The following asserts that |(w1, w2)| is certainly a property; if it does not
exist, it will be created.

=
property *Properties::Valued::obtain(wording W) {
	return Properties::obtain(W, TRUE);
}

@ Now the same: except that we require the property to have a given kind of
value, so that the process can go awry. (But we are allowed to avoid this
possibility by widening the kind, when this can be done.)

=
property *Properties::Valued::obtain_within_kind(wording W, kind *K) {
	property *prn = NULL;
	if (K == NULL) K = K_object;
	K = Kinds::weaken(K, K_object);
	if (<property-name>(W)) {
		prn = <<rp>>;
		kind *existing_kind = prn->property_value_kind;
		switch(Kinds::compatible(K, existing_kind)) {
			case SOMETIMES_MATCH:
				if (Kinds::compatible(existing_kind, K) != ALWAYS_MATCH)
					@<Issue an incompatible property kind message@>;
				prn->property_value_kind = K; /* widen the kind of the property to make this fit */
				break;
			case NEVER_MATCH:
				@<Issue an incompatible property kind message@>;
		}
	} else {
		prn = Properties::obtain(W, TRUE);
		prn->property_value_kind = K;
	}
	return prn;
}

@<Issue an incompatible property kind message@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BadKOVForRelationProperty),
		"that property already exists and contains a kind of value incompatible with "
		"what we need here",
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

=
property *Properties::Valued::new_nameless(text_stream *I6_form, kind *K) {
	wording W = Feeds::feed_text(I6_form);
	if (K == NULL) internal_error("new nameless property without kind");
	package_request *R = Hierarchy::synoptic_package(PROPERTIES_HAP);
	Hierarchy::markup(R, PROPERTY_NAME_HMD, I6_form);
	inter_name *using_iname = Hierarchy::make_iname_with_memo(PROPERTY_HL, R, W);
	property *prn = Properties::create(EMPTY_WORDING, R, using_iname);
	Properties::exclude_from_index(prn);
	prn->either_or = FALSE;
	Properties::set_translation_S(prn, I6_form);
	prn->property_value_kind = K;
	prn->setting_bp = Properties::SettingRelations::make_set_nameless_property_BP(prn);
	prn->stored_bp = NULL;
	prn->run_time_only = TRUE;
	return prn;
}

property *Properties::Valued::new_nameless_using(kind *K, package_request *R, inter_name *using) {
	if (K == NULL) internal_error("new nameless property without kind");
	property *prn = Properties::create(EMPTY_WORDING, R, using);
	Properties::exclude_from_index(prn);
	prn->either_or = FALSE;
	prn->property_value_kind = K;
	prn->setting_bp = Properties::SettingRelations::make_set_nameless_property_BP(prn);
	prn->stored_bp = NULL;
	prn->run_time_only = TRUE;
	Properties::set_translation_S(prn, Emit::to_text(using));
	return prn;
}

@h Initialising details.

=
void Properties::Valued::initialise(property *prn) {
	prn->property_value_kind = NULL;
	prn->setting_bp = NULL;
	prn->used_for_non_typesafe_relation = FALSE;
	prn->also_a_type = FALSE;
	Properties::Conditions::initialise(prn);
}

void Properties::Valued::make_setting_relation(property *prn, wording W) {
	binary_predicate *bp = Properties::SettingRelations::find_set_property_BP(W);
	if (bp == NULL) bp = Properties::SettingRelations::make_set_property_BP(W);
	Properties::SettingRelations::fix_property_bp(bp);
	Properties::SettingRelations::fix_property_bp(BinaryPredicates::get_reversal(bp));
	prn->setting_bp = bp;
}

@h Details.
The most important fact about a valued property is what the kind of value is:

=
kind *Properties::Valued::kind(property *prn) {
	if ((prn == NULL) || (prn->either_or)) return NULL; /* for better type-checking Problems */
	return prn->property_value_kind;
}

void Properties::Valued::set_kind(property *prn, kind *K) {
	if (K == NULL) internal_error("tried to set null kind");
	if ((prn == NULL) || (prn->either_or)) internal_error("non-value property");
	if ((Kinds::Behaviour::definite(K) == FALSE) && (prn->do_not_compile == FALSE)) {
		Problems::quote_wording(1, prn->name);
		Problems::quote_kind(2, K);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyIndefinite));
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
				"property: for instance, it's not enough to say 'A door has a list of values "
				"called the access list', because I don't know what the entries in this "
				"list would have to be - 'A door has a list of people called the access "
				"list' would be better.");
		}
		Problems::issue_problem_end();
	}
	prn->property_value_kind = K;
}

@ Sometimes the name of a property is the same as that of a kind of value.
For instance, we might define a kind of value called "weight", and
then say that a thing has a weight: that makes a property also called
"weight", which is a value property whose value is always a weight.

=
void Properties::Valued::make_coincide_with_kind(property *prn, kind *K) {
	Properties::Valued::set_kind(prn, K);
	if (Kinds::eq(K, K_grammatical_gender)) P_grammatical_gender = prn;
	prn->also_a_type = TRUE;
	if (Properties::Conditions::name_can_coincide_with_property(K))
		Instances::make_kind_coincident(K, prn);
}

int Properties::Valued::coincides_with_kind(property *prn) {
	if ((prn == NULL) || (prn->either_or)) internal_error("non-value property");
	return prn->also_a_type;
}

@ Every valued property has an associated relation to set its value.

=
binary_predicate *Properties::Valued::get_setting_bp(property *prn) {
	if ((prn == NULL) || (prn->either_or)) internal_error("non-value property");
	return prn->setting_bp;
}

@ Some value properties are used for relation storage:

=
void Properties::Valued::set_stored_relation(property *prn, binary_predicate *bp) {
	if ((prn == NULL) || (prn->either_or)) internal_error("non-value property");
	prn->stored_bp = bp;
}

binary_predicate *Properties::Valued::get_stored_relation(property *prn) {
	if ((prn == NULL) || (prn->either_or)) internal_error("non-value property");
	return prn->stored_bp;
}

@ When a property is used to store certain forms of relation, it then needs
to store either a value within one of the domains, or else a null value used
to mean "this is not set at the moment". Since that null value isn't
a member of the domain, it follows that the property is breaking type safety
when it stores it. This means we need to relax typechecking to enable this
all to work; the following keep a flag to mark that.

=
void Properties::Valued::now_used_for_non_typesafe_relation(property *prn) {
	if ((prn == NULL) || (prn->either_or)) internal_error("non-value property");
	prn->used_for_non_typesafe_relation = TRUE;
}

int Properties::Valued::is_used_for_non_typesafe_relation(property *prn) {
	if ((prn == NULL) || (prn->either_or)) internal_error("non-value property");
	return prn->used_for_non_typesafe_relation;
}

@h Assertion.

=
void Properties::Valued::assert(property *prn, inference_subject *owner,
	parse_node *val, int certainty) {
	pcalc_prop *prop = Propositions::Abstract::to_set_property(prn, val);
	Assert::true_about(prop, owner, certainty);
}

@h Compilation.
When we compile the value of a valued property, the following is called.
In theory the result could depend on the property name; in practice it doesn't.
(But this would enable us to implement certain properties with different
storage methods at run-time if we wanted.)

=
void Properties::Valued::compile_value(value_holster *VH, property *prn, parse_node *val) {
	kind *K = Properties::Valued::kind(prn);
	if (K) Specifications::Compiler::compile_constant_to_kind_vh(VH, val, K);
	else {
		BEGIN_COMPILATION_MODE;
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
		Specifications::Compiler::compile_inner(VH, val);
		END_COMPILATION_MODE;
	}
}

void Properties::Valued::compile_default_value(value_holster *VH, property *prn) {
	if (Properties::Valued::is_used_for_non_typesafe_relation(prn)) {
		if (Holsters::data_acceptable(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		return;
	}
	kind *K = Properties::Valued::kind(prn);
	current_sentence = NULL;
	if (Kinds::RunTime::compile_default_value_vh(VH, K, prn->name, "property") == FALSE) {
		Problems::quote_wording(1, prn->name);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyUninitialisable));
		Problems::issue_problem_segment(
			"I am unable to put any value into the property '%1', because "
			"it seems to have a kind of value which has no actual values.");
		Problems::issue_problem_end();
	}
}
