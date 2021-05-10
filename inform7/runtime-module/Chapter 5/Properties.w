[RTProperties::] Properties.

To compile the properties submodule for a compilation unit, which contains
_property packages.

@h Compilation data.
Each |property| object contains this data, though in the case of a pair of
negated either-or properties, only the un-negated case has a meaningful
set of compilation data.

=
typedef struct property_compilation_data {
	struct package_request *prop_package; /* where to find: */
	struct inter_name *prop_iname; /* the identifier we would like to use at run-time for this property */
	int do_not_compile; /* for e.g. the "specification" pseudo-property */
	int translated; /* has this been given an explicit translation? */
	int implemented_as_attribute; /* is this an Inter attribute at run-time? */
	int store_in_negation; /* this is the dummy half of an either/or pair */
	int visited_on_traverse; /* for temporary use when compiling objects */
	int use_non_typesafe_0; /* as a default to mean "not set" at run-time */
} property_compilation_data;

void RTProperties::initialise_pcd(property *prn, package_request *pkg, inter_name *iname) {
	prn->compilation_data.prop_package = pkg;
	prn->compilation_data.prop_iname = iname;
	prn->compilation_data.do_not_compile = FALSE;
	prn->compilation_data.translated = FALSE;
	prn->compilation_data.store_in_negation = FALSE;
	prn->compilation_data.implemented_as_attribute = NOT_APPLICABLE;
	prn->compilation_data.visited_on_traverse = -1;
	prn->compilation_data.use_non_typesafe_0 = FALSE;
}

@ And these are created on demand, though some properties come with a given
package already supplied:

=
package_request *RTProperties::package(property *prn) {
	if (prn == NULL) internal_error("tried to find package for null property");
	if ((Properties::is_either_or(prn)) && (prn->compilation_data.store_in_negation))
		return RTProperties::package(EitherOrProperties::get_negation(prn));
	if (prn->compilation_data.prop_package == NULL)
		prn->compilation_data.prop_package =
			Hierarchy::local_package_to(PROPERTIES_HAP, prn->where_created);
	return prn->compilation_data.prop_package;
}

inter_name *RTProperties::iname(property *prn) {
	if (prn == NULL) internal_error("tried to find iname for null property");
	if ((Properties::is_either_or(prn)) && (prn->compilation_data.store_in_negation))
		return RTProperties::iname(EitherOrProperties::get_negation(prn));
	if (prn->compilation_data.prop_iname == NULL)		
		prn->compilation_data.prop_iname =
			Hierarchy::make_iname_with_memo(PROPERTY_HL,
				RTProperties::package(prn), prn->name);
	return prn->compilation_data.prop_iname;
}

@ Only a very few pseudo-properties go uncompiled: see //knowledge: Properties//.

=
void RTProperties::do_not_compile(property *prn) {
	prn->compilation_data.do_not_compile = TRUE;
}

int RTProperties::can_be_compiled(property *prn) {
	if ((prn == NULL) || (prn->compilation_data.do_not_compile)) return FALSE;
	return TRUE;
}

@ When we have a pair of either-or antonyms, as in "A person can be cheery or moody",
we should store the state as either the |cheery| or the |moody| property. Clearly
either could equivalently be used: if a person is indeed in good spirits, we
could represent this either by having a |cheery| property at runtime and storing
|true| in it, or by having a |moody| one and storing |false| in that.

Calling the function //RTProperties::store_in_negation// establishes that the
given property is the one we don't use. That is, if you want to use |cheery|,
call this function on |moody|.

It may seem not to matter, but in fact we sometimes do need to have things one
particular way around in order to make Inform 7 source text play nicely with
already-compiled properties in kits. If the |moody| property is defined by a
kit, we'll have to use that one.

=
int RTProperties::stored_in_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL))
		internal_error("non-EO property");
	return prn->compilation_data.store_in_negation;
}

void RTProperties::store_in_negation(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	property *neg = EitherOrProperties::get_negation(prn);
	if (neg == NULL) internal_error("singleton EO cannot store in negation");

	prn->compilation_data.store_in_negation = TRUE;
	neg->compilation_data.store_in_negation = FALSE;
}

@ The translation of a property is stored in the translation of its iname:

=
void RTProperties::set_translation(property *prn, text_stream *T) {
	inter_name *iname = RTProperties::iname(prn);
	Produce::change_translation(iname, T);
	prn->compilation_data.translated = TRUE;
}

void RTProperties::set_translation_and_make_available(property *prn, text_stream *T) {
	inter_name *iname = RTProperties::iname(prn);
	Produce::change_translation(iname, T);
	Hierarchy::make_available(iname);
	prn->compilation_data.translated = TRUE;
}

int RTProperties::has_been_translated(property *prn) {
	return prn->compilation_data.translated;
}

text_stream *RTProperties::current_translation(property *prn) {
	if (prn->compilation_data.translated == FALSE) return NULL;
	return Produce::get_translation(RTProperties::iname(prn));
}

@h Compilation.

=
void RTProperties::compile(void) {
	property *prn;
	LOOP_OVER(prn, property) {
		if ((Properties::is_either_or(prn)) &&
			(prn->compilation_data.store_in_negation)) continue;
		kind *K = Properties::kind_of_contents(prn);
		if (K == NULL) internal_error("kindless property");
		inter_name *iname = RTProperties::iname(prn);
		Emit::property(iname, K);
		if (prn->Inter_level_only) Emit::permission(prn, K_object, NULL);
		if (prn->compilation_data.translated)
			Produce::annotate_i(iname, EXPLICIT_ATTRIBUTE_IANN, 1);
		Produce::annotate_i(iname, SOURCE_ORDER_IANN, (inter_ti) prn->allocation_id);
		property_permission *pp;
		LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn) {
			inference_subject *subj = pp->property_owner;
			if (subj == NULL) internal_error("unowned property");
			kind *K = KindSubjects::to_kind(subj);
			if (K) Emit::permission(prn, K, RTPropertyValues::annotate_table_storage(pp));
		}
		package_request *pack = RTProperties::package(prn);
		Hierarchy::apply_metadata_from_wording(pack, PROPERTY_NAME_MD_HL, prn->name);
		inter_name *id_iname = Hierarchy::make_iname_in(PROPERTY_ID_HL, pack);
		Emit::numeric_constant(id_iname, 0);
	}
}

@h Attributes.
Inform 6 provides "attributes" as a faster-access, more memory-efficient
form of object properties, stored at run-time in a bitmap rather than as
key-value pairs in a small dictionary. Because the bitmap is inflexibly sized,
only some of our either/or properties will be able to make use of it. See
"Properties of Objects" for how these are chosen; the following simply
keep a flag recording the outcome.

=
int RTProperties::implemented_as_attribute(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	if (prn->compilation_data.implemented_as_attribute == NOT_APPLICABLE) return TRUE;
	return prn->compilation_data.implemented_as_attribute;
}

void RTProperties::implement_as_attribute(property *prn, int state) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	prn->compilation_data.implemented_as_attribute = state;
	if (EitherOrProperties::get_negation(prn)) EitherOrProperties::get_negation(prn)->compilation_data.implemented_as_attribute = state;
}

void RTProperties::annotate_attributes(void) {
	property *prn;
	LOOP_OVER(prn, property) {
		if (Properties::is_either_or(prn)) {
			if (prn->compilation_data.store_in_negation) continue;
			Produce::annotate_i(RTProperties::iname(prn), EITHER_OR_IANN, 0);
			if (RTProperties::implemented_as_attribute(prn)) {
				Produce::annotate_i(RTProperties::iname(prn), ATTRIBUTE_IANN, 0);
			}
		}
		if (Wordings::nonempty(prn->name))
			Produce::annotate_w(RTProperties::iname(prn), PROPERTY_NAME_IANN, prn->name);
		if (prn->Inter_level_only)
			Produce::annotate_i(RTProperties::iname(prn), RTO_IANN, 0);
		kind *K = Properties::kind_of_contents(prn);
		Emit::ensure_defaultvalue(K);
	}
}

@ Otherwise, each either/or property is stored as either |true| or |false|
in a given cell of memory at run-time -- wastefully since only 1 of the
16 or 32 bits in that memory word is used, but at least rapidly. The
following compiles this |true| or |false| value.

=
void RTProperties::compile_value(value_holster *VH, property *prn, int val) {
	if (val) {
		if (Holsters::non_void_context(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 1);
	} else {
		if (Holsters::non_void_context(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
	}
}

void RTProperties::compile_default_value(value_holster *VH, property *prn) {
	if (Holsters::non_void_context(VH))
		Holsters::holster_pair(VH, LITERAL_IVAL, 0);
}

@h Value property compilation.
When we compile the value of a valued property, the following is called.
In theory the result could depend on the property name; in practice it doesn't.
(But this would enable us to implement certain properties with different
storage methods at run-time if we wanted.)

When a property is used to store certain forms of relation, it then needs
to store either a value within one of the domains, or else a null value used
to mean "this is not set at the moment". Since that null value isn't
a member of the domain, it follows that the property is breaking type safety
when it stores it. This means we need to relax typechecking to enable this
all to work; the following keep a flag to mark that.

=
void RTProperties::use_non_typesafe_0(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	prn->compilation_data.use_non_typesafe_0 = TRUE;
}

int RTProperties::uses_non_typesafe_0(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	return prn->compilation_data.use_non_typesafe_0;
}

void RTProperties::compile_vp_value(value_holster *VH, property *prn, parse_node *val) {
	kind *K = ValueProperties::kind(prn);
	CompileValues::constant_to_holster(VH, val, K);
}

void RTProperties::compile_vp_default_value(value_holster *VH, property *prn) {
	if (RTProperties::uses_non_typesafe_0(prn)) {
		if (Holsters::non_void_context(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		return;
	}
	kind *K = ValueProperties::kind(prn);
	current_sentence = NULL;
	if (RTKinds::compile_default_value_vh(VH, K, prn->name, "property") == FALSE) {
		Problems::quote_wording(1, prn->name);
		StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_PropertyUninitialisable));
		Problems::issue_problem_segment(
			"I am unable to put any value into the property '%1', because "
			"it seems to have a kind of value which has no actual values.");
		Problems::issue_problem_end();
	}
}

@ Now for the methods.

=
void RTProperties::write_either_or_schemas(adjective_meaning *am, property *prn, int T) {
	kind *K = AdjectiveMeaningDomains::get_kind(am);
	if (Kinds::Behaviour::is_object(K))
		@<Set the schemata for an either/or property adjective with objects as domain@>
	else
		@<Set the schemata for an either/or property adjective with some other domain@>;
}

@ The "objects" domain is not really very different, but it's the one used
overwhelmingly most often, so we will call the relevant routines directly rather
than accessing them via the unifying routines |GProperty| and |WriteGProperty| --
which would work just as well, but more slowly.

@<Set the schemata for an either/or property adjective with objects as domain@> =
	if (RTProperties::stored_in_negation(prn)) {
		property *neg = EitherOrProperties::get_negation(prn);
		inter_name *identifier = RTProperties::iname(neg);

		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GetEitherOrProperty(*1, %n) == false", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, true)", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, false)", identifier);
	} else {
		inter_name *identifier = RTProperties::iname(prn);

		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GetEitherOrProperty(*1, %n)", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, false)", identifier);

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "SetEitherOrProperty(*1, %n, true)", identifier);
	}

@<Set the schemata for an either/or property adjective with some other domain@> =
	if (RTProperties::stored_in_negation(prn)) {
		property *neg = EitherOrProperties::get_negation(prn);

		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GProperty(%k, *1, %n) == false", K,
			RTProperties::iname(neg));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n)", K,
			RTProperties::iname(neg));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n, true)", K,
			RTProperties::iname(neg));
	} else {
		i6_schema *sch = AdjectiveMeanings::make_schema(am, TEST_ATOM_TASK);
		Calculus::Schemas::modify(sch, "GProperty(%k, *1, %n)", K,
			RTProperties::iname(prn));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_TRUE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n, true)", K,
			RTProperties::iname(prn));

		sch = AdjectiveMeanings::make_schema(am, NOW_ATOM_FALSE_TASK);
		Calculus::Schemas::modify(sch, "WriteGProperty(%k, *1, %n)", K,
			RTProperties::iname(prn));
	}

@

=
property *RTProperties::make_valued_property_identified_thus(text_stream *Inter_identifier) {
	wording W = Feeds::feed_text(Inter_identifier);
	package_request *R = Hierarchy::synoptic_package(PROPERTIES_HAP);
	Hierarchy::apply_metadata(R, PROPERTY_NAME_MD_HL, Inter_identifier);
	inter_name *using_iname = Hierarchy::make_iname_with_memo(PROPERTY_HL, R, W);
	property *prn = Properties::create(EMPTY_WORDING, R, using_iname, FALSE);
	Properties::set_translation_from_text(prn, Inter_identifier);
	return prn;
}

@

=
int RTProperties::test_provision_schema(annotated_i6_schema *asch) {
	kind *K = Cinders::kind_of_term(asch->pt0);
	property *prn = Rvalues::to_property(asch->pt1.constant);
	if (K) {
		if (prn) {
			if (Kinds::Behaviour::is_object(K))
				@<Compile a run-time test of property provision@>
			else
				@<Determine the result now, since we know already, and compile only the outcome@>;
			return TRUE;
		} else if (Kinds::Behaviour::is_object(K)) {
			kind *PK = Cinders::kind_of_term(asch->pt1);
			if (Kinds::get_construct(PK) == CON_property) {
				if (Kinds::eq(K_truth_state, Kinds::unary_construction_material(PK)))
					Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, true, *2)");
				else
					Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, false, *2)");
				return TRUE;
			}
		}
	}
	return FALSE;
}

@ Since type-checking for "object" is too weak to make it certain what kind
of object the left operand is, we can only test property provision at run-time:

@<Compile a run-time test of property provision@> =
	if (Properties::is_value_property(prn))
		Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, false, *2)");
	else
		Calculus::Schemas::modify(asch->schema, "WhetherProvides(*1, true, *2)");

@ For all other kinds, type-checking is strong enough that we can prove the
answer now.

@<Determine the result now, since we know already, and compile only the outcome@> =
	if (PropertyPermissions::find(KindSubjects::from_kind(K), prn, TRUE))
		Calculus::Schemas::modify(asch->schema, "true");
	else
		Calculus::Schemas::modify(asch->schema, "false");

@ =
int RTProperties::test_property_value_schema(annotated_i6_schema *asch, property *prn) {
	kind *K = Cinders::kind_of_term(asch->pt0);
	if (Kinds::Behaviour::is_object(K)) return FALSE;
	Calculus::Schemas::modify(asch->schema,
		"GProperty(%k, *1, %n) == *2", K, RTProperties::iname(prn));
	return TRUE;
}

int RTProperties::set_property_value_schema(annotated_i6_schema *asch, property *prn) {
	kind *K = Cinders::kind_of_term(asch->pt0);
	if (Kinds::Behaviour::is_object(K)) return FALSE;
	Calculus::Schemas::modify(asch->schema,
		"WriteGProperty(%k, *1, %n, *2)", K, RTProperties::iname(prn));
	return TRUE;
}
