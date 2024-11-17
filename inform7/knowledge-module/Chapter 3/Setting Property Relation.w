[SettingPropertyRelations::] Setting Property Relation.

Each value property has an associated relation to set its value.

@h Family.
There is exactly one member of this family for each different valued property.

=
bp_family *property_setting_bp_family = NULL;

void SettingPropertyRelations::start(void) {
	property_setting_bp_family = BinaryPredicateFamilies::new();
	METHOD_ADD(property_setting_bp_family, STOCK_BPF_MTID,
		SettingPropertyRelations::stock);
	METHOD_ADD(property_setting_bp_family, TYPECHECK_BPF_MTID,
		SettingPropertyRelations::typecheck);
	METHOD_ADD(property_setting_bp_family, ASSERT_BPF_MTID,
		SettingPropertyRelations::assert);
	METHOD_ADD(property_setting_bp_family, SCHEMA_BPF_MTID,
		SettingPropertyRelations::schema);
}

int SettingPropertyRelations::bp_sets_a_property(binary_predicate *bp) {
	if (bp->relation_family == property_setting_bp_family) return TRUE;
	return FALSE;
}

@h Initial stock.
The case of |n| being 2 is when all properties have been created, making it
the perfect opportunity to go over all of the property-setting BPs:

=
void SettingPropertyRelations::stock(bp_family *self, int n) {
	if (n == 2) {
		binary_predicate *bp;
		LOOP_OVER(bp, binary_predicate)
			if (bp->relation_family == property_setting_bp_family) {
				property_setting_bp_data *PSD =
					RETRIEVE_POINTER_property_setting_bp_data(bp->family_specific);
				if (Wordings::nonempty(PSD->property_pending_text))
					SettingPropertyRelations::fix_property_bp(bp);
			}
	}
}

@h Subsequent creations.
Relations like this lead to a timing problem, because we have to create the
relation early enough that we can make sense of the sentences in the source
text; but at that early time, the properties haven't been created yet. We
therefore store the text (say, "weight") in |property_pending_text| and come
back to it later.

=
typedef struct property_setting_bp_data {
	struct wording property_pending_text; /* temp. version used until props created */
	struct property *set_property; /* asserting $B(x, v)$ sets this prop. of $x$ to $v$ */
	CLASS_DEFINITION
} property_setting_bp_data;

binary_predicate *SettingPropertyRelations::make_set_property_BP(wording W) {
	binary_predicate *bp = BinaryPredicates::make_pair(property_setting_bp_family,
		BPTerms::new(KindSubjects::from_kind(K_object)),
		BPTerms::new(NULL),
		I"set-property", NULL, NULL, NULL, WordAssemblages::lit_0());
	property_setting_bp_data *PSD = CREATE(property_setting_bp_data);
	PSD->property_pending_text = W;
	bp->family_specific = STORE_POINTER_property_setting_bp_data(PSD);
	bp->reversal->family_specific = STORE_POINTER_property_setting_bp_data(PSD);
	return bp;
}

@ Meanwhile, we can't look up the BP with reference to the property, since
the property may not exist yet; we have to use the text of the name of the
property as a key, clumsy as that may seem.

=
binary_predicate *SettingPropertyRelations::find_set_property_BP(wording W) {
	binary_predicate *bp;
	LOOP_OVER(bp, binary_predicate)
		if (bp->relation_family == property_setting_bp_family)
			if (bp->right_way_round) {
				property_setting_bp_data *PSD =
					RETRIEVE_POINTER_property_setting_bp_data(bp->family_specific);
				if (Wordings::match(W, PSD->property_pending_text))
					return bp;
			}
	return NULL;
}

@ ...And now it's "later on". Original-reversal pairs share the setting data, so
that the two can never fall out of step with each other.

=
void SettingPropertyRelations::fix_property_bp(binary_predicate *bp) {
	if (bp->relation_family == property_setting_bp_family) {
		property_setting_bp_data *PSD =
			RETRIEVE_POINTER_property_setting_bp_data(bp->family_specific);
		wording W = PSD->property_pending_text;
		if (Wordings::nonempty(W)) {
			PSD->property_pending_text = EMPTY_WORDING;
			current_sentence = bp->bp_created_at;
			<relation-property-name>(W);
			if (<<r>> == FALSE) return; /* a problem was issued */
			property *prn = <<rp>>;
			PSD->set_property = prn;
			if (bp->right_way_round)
				SettingPropertyRelations::set_property_BP_schemas(bp, prn);
			else
				SettingPropertyRelations::set_property_BP_schemas(bp->reversal, prn);
		}
	}
}

@ When properties are named as part of relation definitions, for instance, like so:

>> The verb to weigh (it weighs, they weigh, it is weighing) implies the weight property.

...then its name (in this case "weight") is required to pass:

=
<relation-property-name> ::=
	<either-or-property-name> |  ==> @<Issue PM_RelationWithEitherOrProperty problem@>
	<value-property-name> |      ==> { TRUE, RP[1] }
	...                          ==> @<Issue PM_RelationWithBadProperty problem@>

@<Issue PM_RelationWithEitherOrProperty problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_RelationWithEitherOrProperty),
		"verbs can only set properties with values",
		"not either/or properties like this one.");
	==> { FALSE, - };

@<Issue PM_RelationWithBadProperty problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(),
		_p_(PM_RelationWithBadProperty),
		"that doesn't seem to be a property",
		"perhaps because you haven't defined it yet?");
	==> { FALSE, - };

@ No such funny business is necessary for a nameless property created within
Inform:

=
binary_predicate *SettingPropertyRelations::make_set_nameless_property_BP(property *prn) {
	binary_predicate *bp = SettingPropertyRelations::make_set_property_BP(EMPTY_WORDING);
	property_setting_bp_data *PSD =
		RETRIEVE_POINTER_property_setting_bp_data(bp->family_specific);
	PSD->set_property = prn;
	SettingPropertyRelations::set_property_BP_schemas(bp, prn);
	return bp;
}

@ Note that we read and write to the property directly, without asking the
template layer to check if the given object has permission to possess that
property. We can afford to do this because type-checking at compile time
guarantees that it does have permission, and as a result we gain some speed
and simplicity.

=
void SettingPropertyRelations::set_property_BP_schemas(binary_predicate *bp,
	property *prn) {
	if (Kinds::Behaviour::uses_block_values(ValueProperties::kind(prn))) {
		bp->task_functions[TEST_ATOM_TASK] =
			Calculus::Schemas::new("ComparePV(*1.%n, *2) == 0", RTProperties::iname(prn));
		bp->task_functions[NOW_ATOM_TRUE_TASK] =
			Calculus::Schemas::new("CopyPV(*1.%n, *2)", RTProperties::iname(prn));
	} else {
		bp->task_functions[TEST_ATOM_TASK] =
			Calculus::Schemas::new("*1.%n == *2", RTProperties::iname(prn));
		bp->task_functions[NOW_ATOM_TRUE_TASK] =
			Calculus::Schemas::new("*1.%n = *2", RTProperties::iname(prn));
	}
	BPTerms::set_domain(&(bp->term_details[1]),
		ValueProperties::kind(prn));
}

@h Typechecking.
Suppose we are setting property $P$ of subject $S$ to value $V$. Then the setting
relation has terms $S$ and $V$. To pass typechecking, we require that $V$ be
valid for the kind of value stored in $P$, and that $S$ have a kind a value
allowing it to possess properties in general. But we don't require
that it possesses this one.

This is because we can't know whether it does or not until model completion,
much later on, because we don't necessarily know the kind of value of $S$.
It might be an object which will eventually be deduced to be a room, for
instance, but hasn't been yet.

=
int SettingPropertyRelations::typecheck(bp_family *self, binary_predicate *bp,
		kind **kinds_of_terms, kind **kinds_required, tc_problem_kit *tck) {
	property_setting_bp_data *PSD =
		RETRIEVE_POINTER_property_setting_bp_data(bp->family_specific);
	property *prn = PSD->set_property;
	kind *val_kind = ValueProperties::kind(prn);
	@<Require the value to be type-safe for storage in the property@>;
	@<Require the subject to be able to have properties@>;
	return ALWAYS_MATCH;
}

@ The following lets just a few type-unsafe cases fall through the net. It's
superficially attractive to reject them here, but (a) that would result in
less specific problem messages which can be issued later on, notably for
the "opposite" property of directions; and (b) we must be careful because
in assertion traverse 2 not every object yet has its final kind -- for
many implicitly created objects, they have yet to be declared as room,
container and supporter.

As a result, type-unsafe property assertions do occur, and these have to
be caught later on Inform's run.

@<Require the value to be type-safe for storage in the property@> =
	int safe = FALSE;
	int compatible = Kinds::compatible(kinds_of_terms[1], val_kind);
	if (compatible == ALWAYS_MATCH) safe = TRUE;
	if (compatible == SOMETIMES_MATCH) {
		if (Kinds::Behaviour::is_object(val_kind) == FALSE) safe = TRUE;
		#ifdef IF_MODULE
		if ((Kinds::eq(val_kind, K_direction)) ||
			(Kinds::eq(val_kind, K_room)) ||
			(Kinds::eq(val_kind, K_container)) ||
			(Kinds::eq(val_kind, K_supporter))) safe = TRUE;
		#endif
	}

	if (safe == FALSE) {
		kind *K1 = kinds_of_terms[1];
		kind *K2 = val_kind;
		LOG("Property value given as %u not %u\n", K1, K2);
		Problems::quote_kind(4, K1);
		Problems::quote_kind(5, K2);
		if (Kinds::get_construct(K1) == CON_property)
			StandardProblems::tcp_problem(_p_(PM_PropertiesEquated), tck,
				"that seems to say that two different properties are the same - "
				"like saying 'The indefinite article is the printed name': that "
				"might be true for some things, some of the time, but it makes no "
				"sense in a general statement like this one.");
		else if (prn == NULL)
			StandardProblems::tcp_problem(_p_(PM_UnknownPropertyType), tck,
				"that tries to set the value of an unknown property to %4.");
		else {
			Problems::quote_property(6, prn);
			char *msg;
			if (((Kinds::eq(K1, K_time)) && (Kinds::eq(K2, K_time_period))) ||
				((Kinds::eq(K2, K_time)) && (Kinds::eq(K1, K_time_period))))
				msg = "that tries to set the value of the '%6' property to %4 - which "
					"must be wrong because this property has to be %5. Note that "
					"'time period', introduced in Inform in 2024, holds values like "
					"'10 minutes', and is not the same kind as 'time', which is for "
					"times of day like '6:12 PM'. (Before 2024, the same kind was "
					"used for both.)";
			else
				msg = "that tries to set the value of the '%6' property to %4 - which "
					"must be wrong because this property has to be %5.";
			StandardProblems::tcp_problem(_p_(PM_PropertyType), tck, msg);
		}
		return NEVER_MATCH;
	}

@<Require the subject to be able to have properties@> =
	if (KindSubjects::has_properties(kinds_of_terms[0]) == FALSE) {
		LOG("Property value for impossible domain %u\n", kinds_of_terms[0]);
		Problems::quote_kind(4, kinds_of_terms[0]);
		Problems::quote_property(5, prn);
		StandardProblems::tcp_problem(_p_(BelievedImpossible), tck,
			"that tries to set the property '%5' for %4. Values of that kind "
			"are not allowed to have properties. (Some kinds of value are, "
			"some aren't - see the Kinds index for details. It's a matter "
			"of what is practical in terms of how much memory is needed.)");
		return NEVER_MATCH;
	}

@h Assertion.

=
int SettingPropertyRelations::assert(bp_family *self, binary_predicate *bp,
		inference_subject *infs0, parse_node *spec0,
		inference_subject *infs1, parse_node *spec1) {
	property_setting_bp_data *PSD =
		RETRIEVE_POINTER_property_setting_bp_data(bp->family_specific);
	PropertyInferences::draw(infs0, PSD->set_property, spec1);
	return TRUE;
}

@h Compilation.

=
int SettingPropertyRelations::schema(bp_family *self, int task,
	binary_predicate *bp, annotated_i6_schema *asch) {
	property_setting_bp_data *PSD =
		RETRIEVE_POINTER_property_setting_bp_data(bp->family_specific);
	property *prn = PSD->set_property;
	switch (task) {
		case TEST_ATOM_TASK: return RTProperties::test_property_value_schema(asch, prn);
		case NOW_ATOM_FALSE_TASK: break;
		case NOW_ATOM_TRUE_TASK: return RTProperties::set_property_value_schema(asch, prn);
	}
	return FALSE;
}
