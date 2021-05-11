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
	struct text_stream *translation; /* for the iname */
	int do_not_compile; /* for e.g. the "specification" pseudo-property */
	int translated; /* has this been given an explicit translation? */
	int implemented_as_attribute; /* is this an Inter attribute at run-time? */
	int store_in_negation; /* this is the dummy half of an either/or pair */
	int visited_on_traverse; /* for temporary use when compiling objects */
	int use_non_typesafe_0; /* as a default to mean "not set" at run-time */
} property_compilation_data;

void RTProperties::initialise_pcd(property *prn, package_request *pkg, inter_name *iname,
	text_stream *translation) {
	prn->compilation_data.prop_package = pkg;
	prn->compilation_data.prop_iname = iname;
	prn->compilation_data.translation = Str::duplicate(translation);
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
	if (prn->compilation_data.prop_iname == NULL) {
		wording memo = prn->name;
		if ((Wordings::empty(memo)) &&
			(Str::len(prn->compilation_data.translation) > 0))
			memo = Feeds::feed_text(prn->compilation_data.translation);
		prn->compilation_data.prop_iname =
			Hierarchy::make_iname_with_memo(PROPERTY_HL,
				RTProperties::package(prn), memo);
		if (Str::len(prn->compilation_data.translation) > 0) {
			TEMPORARY_TEXT(T)
			LOOP_THROUGH_TEXT(pos, prn->compilation_data.translation) {
				wchar_t c = Str::get(pos);
				if ((isalpha(c)) || (Characters::isdigit(c)) || (c == '_'))
					PUT_TO(T, (int) c);
				else
					PUT_TO(T, '_');
			}
			Str::truncate(T, 31);
			Produce::change_translation(prn->compilation_data.prop_iname, T);
			prn->compilation_data.translated = TRUE;
			DISCARD_TEXT(T)
		}
	}
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
		Emit::ensure_defaultvalue(K);

		package_request *pack = RTProperties::package(prn);
		inter_name *iname = RTProperties::iname(prn);
		@<Declare the property to Inter@>;
		@<Give it permissions@>;
		@<Compile the property name metadata@>;
		@<Compile the property ID@>;
		@<Annotate the property iname@>;
	}
}

@<Declare the property to Inter@> =
	Emit::property(iname, K);

@<Give it permissions@> =
	property_permission *pp;
	LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn) {
		inference_subject *subj = pp->property_owner;
		if (subj == NULL) internal_error("unowned property");
		kind *K = KindSubjects::to_kind(subj);
		if (K) Emit::permission(prn, K, RTPropertyValues::annotate_table_storage(pp));
	}
	if (prn->Inter_level_only) Emit::permission(prn, K_object, NULL);

@<Compile the property name metadata@> =
	if (Wordings::nonempty(prn->name))
		Hierarchy::apply_metadata_from_wording(pack, PROPERTY_NAME_MD_HL, prn->name);
	else
		Hierarchy::apply_metadata(pack, PROPERTY_NAME_MD_HL, Produce::get_translation(iname));

@ A unique set of values is imposed here during linking.

@<Compile the property ID@> =
	inter_name *id_iname = Hierarchy::make_iname_in(PROPERTY_ID_HL, pack);
	Emit::numeric_constant(id_iname, 0); /* a placeholder */

@ These provide hints to the code-generator, but should possibly be done as
package metadata instead?

@<Annotate the property iname@> =
	Produce::annotate_i(iname, SOURCE_ORDER_IANN, (inter_ti) prn->allocation_id);
	if (prn->compilation_data.translated)
		Produce::annotate_i(iname, EXPLICIT_ATTRIBUTE_IANN, 1);
	if (Properties::is_either_or(prn)) {
		Produce::annotate_i(RTProperties::iname(prn), EITHER_OR_IANN, 0);
		if (RTProperties::recommended_as_attribute(prn)) {
			Produce::annotate_i(RTProperties::iname(prn), ATTRIBUTE_IANN, 0);
		}
	}
	if (Wordings::nonempty(prn->name))
		Produce::annotate_w(RTProperties::iname(prn), PROPERTY_NAME_IANN, prn->name);
	if (prn->Inter_level_only)
		Produce::annotate_i(RTProperties::iname(prn), RTO_IANN, 0);

@h Recommendations to be attributes.
The design of Inter tries to abstract details of how properties are stored
away from us, but we secretly know that on its most likely implementations
some properties are stored as "attributes". These are memory-efficient flags,
suitable only for either-or properties.

On those platforms, only a limited number of attribute slots exists. The main
Inform compiler does not get to decide which either-or properties get to enjoy
these slots (if indeed they exists); but it can use annotations to provide a
hint to the code-generator -- basically saying, "if you have an attribute free,
why not use it on this?"

Inform makes this recommendation only for a few low-level properties which need
to run quickly and with low memory usage.

=
int RTProperties::recommended_as_attribute(property *prn) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	if (prn->compilation_data.implemented_as_attribute == NOT_APPLICABLE) return TRUE;
	return prn->compilation_data.implemented_as_attribute;
}

void RTProperties::recommend_storing_as_attribute(property *prn, int state) {
	if ((prn == NULL) || (prn->either_or_data == NULL)) internal_error("non-EO property");
	prn->compilation_data.implemented_as_attribute = state;
	if (EitherOrProperties::get_negation(prn))
		EitherOrProperties::get_negation(prn)->compilation_data.implemented_as_attribute = state;
}

@h Non-typesafe 0.
When a property is used to store certain forms of relation, it then needs
to store either a value within one of the domains, or else a null value used
to mean "this is not set at the moment". Since that null value isn't
a member of the domain, it follows that the property is breaking type safety
when it stores it. This means we need to relax typechecking to enable this
all to work; the following keep a flag to mark that.

None of this has any effect for either-or properties, since 0 is of course
typesafe for those.

=
void RTProperties::use_non_typesafe_0(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	prn->compilation_data.use_non_typesafe_0 = TRUE;
}

int RTProperties::uses_non_typesafe_0(property *prn) {
	if ((prn == NULL) || (prn->either_or_data)) internal_error("non-value property");
	return prn->compilation_data.use_non_typesafe_0;
}

int RTProperties::compile_vp_default_value(value_holster *VH, property *prn) {
	if (RTProperties::uses_non_typesafe_0(prn)) {
		if (Holsters::non_void_context(VH))
			Holsters::holster_pair(VH, LITERAL_IVAL, 0);
		return TRUE;
	}
	kind *K = ValueProperties::kind(prn);
	return RTKinds::compile_default_value_vh(VH, K, prn->name, "property");
}

@h Schemas.
"Value" properties (those which are not either-or) can be tested or set with
these schemas, which make use of a kit-defined function called |GProperty|
and its analogue for writing, |WriteGProperty|:

=
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

@ Either-or properties are trickier, though only because they use a different
pair of functions at runtime for EO properties of objects than for EO properties
of anything else:

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

@ And finally, provision of a property can be tested at runtime with the
following schemas:

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
