[RTInstances::] Instances.

To compile the instances submodule for a compilation unit, which contains
_instance packages.

@h Compilation data.
Each |instance| object contains this data:

=
typedef struct instance_compilation_data {
	struct package_request *instance_package;
	struct inter_name *instance_iname;
	struct linked_list *usages; /* of |parse_node| */
	int declaration_sequence_number;
	int has_explicit_runtime_value;
	inter_ti explicit_runtime_value;
} instance_compilation_data;

instance_compilation_data RTInstances::new_compilation_data(instance *I) {
	instance_compilation_data icd;
	icd.instance_package = Hierarchy::local_package(INSTANCES_HAP);
	wording W = Nouns::nominative(I->as_noun, FALSE);
	icd.instance_iname = Hierarchy::make_iname_with_memo(INSTANCE_HL,
		icd.instance_package, W);
	icd.declaration_sequence_number = -1;
	icd.has_explicit_runtime_value = FALSE;
	icd.explicit_runtime_value = 0;
	icd.usages = NEW_LINKED_LIST(parse_node);
	NounIdentifiers::set_iname(I->as_noun, icd.instance_iname);
	Hierarchy::make_available_one_per_name_only(icd.instance_iname);
	return icd;
}

inter_name *RTInstances::value_iname(instance *I) {
	if (I == NULL) return NULL;
	return I->compilation_data.instance_iname;
}

package_request *RTInstances::package(instance *I) {
	return I->compilation_data.instance_package;
}

@ It's perhaps ambiguous what a usage of an instance is, or where it occurs,
but this function is called each time the instance |I| is compiled as a
constant value.

=
void RTInstances::note_usage(instance *I, parse_node *NB) {
	if (NB) {
		parse_node *where;
		LOOP_OVER_LINKED_LIST(where, parse_node, I->compilation_data.usages)
			if (NB == where)
				return;
		ADD_TO_LINKED_LIST(NB, parse_node, I->compilation_data.usages);
	}
}

@h Compilation.

=
int RTInstances::compile_all(inference_subject_family *family, int ignored) {
	@<Number instances in declaration order@>;
	instance *I;
	LOOP_OVER(I, instance) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "instance "); Instances::write(desc, I);
		Sequence::queue(&RTInstances::compilation_agent, STORE_POINTER_instance(I), desc);
	}
	return TRUE;
}

@ The code here assigns each instance |I| a sequence number in such a way that
the object instances come out in a well-founded order spatially -- that is,
so that each object X is followed immediately by its children (i.e., the
objects inside or on top of it).

This will be used to annotate the Inter tree so that the declaration order
can be recovered in code-generation, when it would otherwise be lost as
the various instances scatter all over the tree.

@<Number instances in declaration order@> =
	instance *I;
	int n = 0;
	LOOP_THROUGH_INSTANCE_ORDERING(I)
		I->compilation_data.declaration_sequence_number = n++;
	LOOP_OVER(I, instance)
		if (Kinds::Behaviour::is_object(Instances::to_kind(I)) == FALSE)
			I->compilation_data.declaration_sequence_number = n++;

@ This is really all metadata except for the actual instance declaration,
using Inter's |INSTANCE_IST| instruction.

=
void RTInstances::compilation_agent(compilation_subtask *t) {
	instance *I = RETRIEVE_POINTER_instance(t->data);
	package_request *pack = I->compilation_data.instance_package;
	TEMPORARY_TEXT(name)
	Instances::write_name(name, I);
	Hierarchy::apply_metadata(pack, INSTANCE_NAME_MD_HL, name);
	DISCARD_TEXT(name)
	TEMPORARY_TEXT(pname)
	parse_node *V = PropertyInferences::value_and_where(
		Instances::as_subject(I), P_printed_name, NULL);
	if ((Rvalues::is_CONSTANT_of_kind(V, K_text)) &&
		(Wordings::nonempty(Node::get_text(V)))) {
		int wn = Wordings::first_wn(Node::get_text(V));
		WRITE_TO(pname, "%+W", Wordings::one_word(wn));
		if (Str::get_first_char(pname) == '\"') Str::delete_first_character(pname);
		if (Str::get_last_char(pname) == '\"') Str::delete_last_character(pname);
	}
	Hierarchy::apply_metadata(pack, INSTANCE_PRINTED_NAME_MD_HL, name);
	DISCARD_TEXT(pname)
	TEMPORARY_TEXT(abbrev)
	@<Compose the abbreviated name@>;
	Hierarchy::apply_metadata(pack, INSTANCE_ABBREVIATION_MD_HL, abbrev);
	DISCARD_TEXT(abbrev)
	Hierarchy::apply_metadata_from_number(pack, INSTANCE_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(I->creating_sentence)));

	parse_node *C = Instances::get_kind_set_sentence(I);
	if (C) Hierarchy::apply_metadata_from_number(pack, INSTANCE_KIND_SET_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(C)));
	
	C = Spatial::progenitor_set_at(I);
	if (C) Hierarchy::apply_metadata_from_number(pack, INSTANCE_PROGENITOR_SET_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(C)));
	C = Regions::in_region_set_at(I);
	if (C) Hierarchy::apply_metadata_from_number(pack, INSTANCE_REGION_SET_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(C)));

	Hierarchy::apply_metadata_from_iname(pack, INSTANCE_VALUE_MD_HL, I->compilation_data.instance_iname);
	inter_name *kn_iname = Hierarchy::make_iname_in(INSTANCE_KIND_MD_HL, pack);
	kind *K = Instances::to_kind(I);
	TEMPORARY_TEXT(KT)
	WRITE_TO(KT, "%u", K);
	Hierarchy::apply_metadata(pack, INSTANCE_INDEX_KIND_MD_HL, KT);
	DISCARD_TEXT(KT)
	TEMPORARY_TEXT(KC)
		kind *IK = Instances::to_kind(I);
		int i = 0;
		while ((IK != K_object) && (IK)) {
			i++;
			IK = Latticework::super(IK);
		}
		for (int j=i-1; j>=0; j--) {
			int k; IK = Instances::to_kind(I);
			for (k=0; k<j; k++) IK = Latticework::super(IK);
			if (j != i-1) WRITE_TO(KC, " &gt; ");
			wording W = Kinds::Behaviour::get_name(IK, FALSE);
			WRITE_TO(KC, "%+W", W);
		}
	Hierarchy::apply_metadata(pack, INSTANCE_INDEX_KIND_CHAIN_MD_HL, KC);
	DISCARD_TEXT(KC)

	RTKindIDs::define_constant_as_strong_id(kn_iname, K);
	Hierarchy::apply_metadata_from_iname(pack, INSTANCE_KIND_XREF_MD_HL,
		RTKindConstructors::xref_iname(K->construct));
	if (Kinds::Behaviour::is_subkind_of_object(K))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_OBJECT_MD_HL, 1);
	if ((K_sound_name) && (Kinds::eq(K, K_sound_name)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_SOUND_MD_HL, 1);
	if ((K_dialogue_beat) && (Kinds::eq(K, K_dialogue_beat)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_DB_MD_HL, 1);
	if ((K_dialogue_line) && (Kinds::eq(K, K_dialogue_line)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_DL_MD_HL, 1);
	if ((K_dialogue_choice) && (Kinds::eq(K, K_dialogue_choice)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_DC_MD_HL, 1);
	if ((K_figure_name) && (Kinds::eq(K, K_figure_name)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_FIGURE_MD_HL, 1);
	if ((K_external_file) && (Kinds::eq(K, K_external_file)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_EXF_MD_HL, 1);
	if ((K_internal_file) && (Kinds::eq(K, K_internal_file)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_INF_MD_HL, 1);
	if (Instances::of_kind(I, K_thing))
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_THING_MD_HL, 1);
	if (Instances::of_kind(I, K_supporter))
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_SUPPORTER_MD_HL, 1);
	if (Instances::of_kind(I, K_person))
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_PERSON_MD_HL, 1);
	if (Spatial::object_is_a_room(I))
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_ROOM_MD_HL, 1);
	if (Map::instance_is_a_door(I)) {
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_DOOR_MD_HL, 1);
		parse_node *S = PropertyInferences::value_of(
			Instances::as_subject(I), P_other_side);
		if (S)
			Hierarchy::apply_metadata_from_iname(pack, INSTANCE_DOOR_OTHER_SIDE_MD_HL,
				RTInstances::value_iname(Rvalues::to_object_instance(S)));
		instance *IA = MAP_DATA(I)->map_connection_a;
		instance *IB = MAP_DATA(I)->map_connection_b;
		if (IA)
			Hierarchy::apply_metadata_from_iname(pack, INSTANCE_DOOR_SIDE_A_MD_HL,
				RTInstances::value_iname(IA));
		if (IB)
			Hierarchy::apply_metadata_from_iname(pack, INSTANCE_DOOR_SIDE_B_MD_HL,
				RTInstances::value_iname(IB));
	}		
	if (Regions::object_is_a_region(I))
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_REGION_MD_HL, 1);
	if (Map::object_is_a_direction(I)) {
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_DIRECTION_MD_HL, 1);
		if (Map::get_value_of_opposite_property(I)) {
			Hierarchy::apply_metadata_from_iname(pack, INSTANCE_OPPOSITE_DIRECTION_MD_HL,
				RTInstances::value_iname(Map::get_value_of_opposite_property(I)));
		}
	}
	if (Backdrops::object_is_a_backdrop(I))
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_BACKDROP_MD_HL, 1);

	RTInstances::xref_metadata(I, INSTANCE_REGION_ENCLOSING_MD_HL, Regions::enclosing(I));
	if (FEATURE_ACTIVE(spatial)) {
		RTInstances::xref_metadata(I, INSTANCE_SIBLING_MD_HL, SPATIAL_DATA(I)->object_tree_sibling);
		RTInstances::xref_metadata(I, INSTANCE_CHILD_MD_HL, SPATIAL_DATA(I)->object_tree_child);
		RTInstances::xref_metadata(I, INSTANCE_PROGENITOR_MD_HL, Spatial::progenitor(I));
		RTInstances::xref_metadata(I, INSTANCE_INCORP_SIBLING_MD_HL, SPATIAL_DATA(I)->incorp_tree_sibling);
		RTInstances::xref_metadata(I, INSTANCE_INCORP_CHILD_MD_HL, SPATIAL_DATA(I)->incorp_tree_child);
	}

	if (Spatial::object_is_a_room(I)) {
		packaging_state save = EmitArrays::begin_word(Hierarchy::make_iname_in(INSTANCE_MAP_MD_HL, pack), K_value);
		for (int i=0; i<Map::no_directions(); i++) {
			instance *T = MAP_EXIT(I, i);
			if (I) EmitArrays::iname_entry(RTInstances::value_iname(T));
			else EmitArrays::numeric_entry(0);
			parse_node *at = MAP_DATA(I)->exits_set_at[i];
			if (at) EmitArrays::numeric_entry((inter_ti) Wordings::first_wn(Node::get_text(at)));
			else EmitArrays::numeric_entry(0);
		}
		EmitArrays::end(save);
	}
	if (Backdrops::object_is_a_backdrop(I)) {
		packaging_state save = EmitArrays::begin_word(Hierarchy::make_iname_in(INSTANCE_BACKDROP_PRESENCES_MD_HL, pack), K_value);
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), found_in_inf) {
			instance *L = Backdrops::get_inferred_location(inf);
			EmitArrays::iname_entry(RTInstances::value_iname(L));
		}
		EmitArrays::end(save);
	}

	packaging_state save = EmitArrays::begin_word(Hierarchy::make_iname_in(INSTANCE_USAGES_MD_HL, pack), K_value);
	int k = 0;
	parse_node *at;
	LOOP_OVER_LINKED_LIST(at, parse_node, I->compilation_data.usages) {
		source_file *sf = Lexer::file_of_origin(Wordings::first_wn(Node::get_text(at)));
		if (Projects::draws_from_source_file(Task::project(), sf)) {
			EmitArrays::numeric_entry((inter_ti) Wordings::first_wn(Node::get_text(at)));
			k++;
		}
	}
	EmitArrays::end(save);

	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), property_inf)
		if (PropertyInferences::get_property(inf) == P_worn) {
			Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_WORN_MD_HL, 1);
			break;
		}
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), found_everywhere_inf) {
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_EVERYWHERE_MD_HL, 1);
		break;
	}
	RTInferences::index(pack, INSTANCE_BRIEF_INFERENCES_MD_HL, Instances::as_subject(I), TRUE);
	RTInferences::index_specific(pack, INSTANCE_SPECIFIC_INFERENCES_MD_HL, Instances::as_subject(I));
	if (FEATURE_ACTIVE(spatial)) {
		if (SPATIAL_DATA(I)->part_flag)
			Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_A_PART_MD_HL, 1);
	}
	if (I == I_yourself)
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_YOURSELF_MD_HL, 1);
	if (I == Spatial::get_benchmark_room())
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_BENCHMARK_ROOM_MD_HL, 1);
	if (I == Player::get_start_room())
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_IS_START_ROOM_MD_HL, 1);

	if (RTShowmeCommand::needed_for_instance(I)) {
		inter_name *iname = Hierarchy::make_iname_in(INST_SHOWME_FN_HL,
			RTInstances::package(I));
		RTShowmeCommand::compile_instance_showme_fn(iname, I);
		Hierarchy::apply_metadata_from_iname(RTInstances::package(I),
			INST_SHOWME_MD_HL, iname);
	}
	
	inter_ti val = (inter_ti) I->enumeration_index;
	int has_value = TRUE;
	if (val == 0) has_value = FALSE;
	if (I->compilation_data.has_explicit_runtime_value)
		val = I->compilation_data.explicit_runtime_value;
	Emit::instance(RTInstances::value_iname(I), Instances::to_kind(I), val, has_value);
	if (I->compilation_data.declaration_sequence_number >= 0) {
		inter_name *iname = RTInstances::value_iname(I);
		package_request *req = InterNames::location(iname);
		Hierarchy::apply_metadata_from_number(req, INSTANCE_DECLARATION_ORDER_MD_HL,
			(inter_ti) I->compilation_data.declaration_sequence_number);
	}
	RTPropertyPermissions::compile_permissions_for_instance(I);
	RTPropertyValues::compile_values_for_instance(I);

	if (Kinds::Behaviour::is_object(Instances::to_kind(I))) {
		int AC = Spatial::get_definition_depth(I);
		inter_name *iname = RTInstances::value_iname(I);
		package_request *req = InterNames::location(iname);
		if (AC > 0) Hierarchy::apply_metadata_from_number(req,
			INSTANCE_SPATIAL_DEPTH_MD_HL, (inter_ti) AC);
	}

	RTRegionInstances::compile_extra(I);
	RTBackdropInstances::compile_extra(I);
	RTScenes::compile_extra(I);
}

void RTInstances::xref_metadata(instance *I, int hl, instance *X) {
	if (X)
		Hierarchy::apply_metadata_from_iname(RTInstances::package(I), hl,
			RTInstances::value_iname(X));
}

@ Explicit instance numbering is used for enumerative kinds provided by kits,
which exist for the benefit of the Inter layer. Such kinds might have an erratic
series of values such as 2, 6, 17, ... rather than 1, 2, 3, ..., and if so then
an instance with an unexpected runtime value is called "out of place".

=
void RTInstances::set_explicit_runtime_value(instance *I, inter_ti val) {
	I->compilation_data.has_explicit_runtime_value = TRUE;
	I->compilation_data.explicit_runtime_value = val;
}

int RTInstances::out_of_place(instance *I) {
	if (I->compilation_data.has_explicit_runtime_value == FALSE) return FALSE;
	if (I->compilation_data.explicit_runtime_value == (inter_ti) I->enumeration_index)
		return FALSE;
	return TRUE;
}

void RTInstances::set_translation(instance *I, text_stream *identifier) {
	inter_name *iname = RTInstances::value_iname(I);
	InterNames::set_translation(iname, identifier);
	InterNames::clear_flag(iname, MAKE_NAME_UNIQUE_ISYMF);
	Hierarchy::make_available_one_per_name_only(iname);
}

@ When names are abbreviated for use on the World Index map (for instance,
"Marble Hallway" becomes "MH") each word is tested against the following
nonterminal; those which match are omitted. So, for instance, "Queen Of The
South" comes out as "QS".

@d ABBREV_ROOMS_TO 2

=
<map-name-abbreviation-omission-words> ::=
	in |
	of |
	<article>

@<Compose the abbreviated name@> =
	wording W = Instances::get_name(I, FALSE);
	if (Wordings::nonempty(W)) {
		int c = 0;
		LOOP_THROUGH_WORDING(i, W) {
			if ((i > Wordings::first_wn(W)) && (i < Wordings::last_wn(W)) &&
				(<map-name-abbreviation-omission-words>(Wordings::one_word(i)))) continue;
			wchar_t *p = Lexer::word_raw_text(i);
			if (c++ < ABBREV_ROOMS_TO) PUT_TO(abbrev, Characters::toupper(p[0]));
		}
		LOOP_THROUGH_WORDING(i, W) {
			if ((i > Wordings::first_wn(W)) && (i < Wordings::last_wn(W)) &&
				(<map-name-abbreviation-omission-words>(Wordings::one_word(i)))) continue;
			wchar_t *p = Lexer::word_raw_text(i);
			for (int j=1; p[j]; j++)
				if (Characters::vowel(p[j]) == FALSE)
					if (c++ < ABBREV_ROOMS_TO) PUT_TO(abbrev, p[j]);
			if ((c++ < ABBREV_ROOMS_TO) && (p[1])) PUT_TO(abbrev, p[1]);
		}
	}

@h Condition element.
This compiles a test of whether or not |t0_s| is equal to an instance.

=
int RTInstances::emit_element_of_condition(inference_subject_family *family,
	inference_subject *infs, inter_symbol *t0_s) {
	instance *I = InstanceSubjects::to_instance(infs);
	EmitCode::inv(EQ_BIP);
	EmitCode::down();
		EmitCode::val_symbol(K_value, t0_s);
		EmitCode::val_iname(K_value, RTInstances::value_iname(I));
	EmitCode::up();
	return TRUE;
}
