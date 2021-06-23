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
} instance_compilation_data;

instance_compilation_data RTInstances::new_compilation_data(instance *I) {
	instance_compilation_data icd;
	icd.instance_package = Hierarchy::local_package(INSTANCES_HAP);
	wording W = Nouns::nominative(I->as_noun, FALSE);
	icd.instance_iname = Hierarchy::make_iname_with_memo(INSTANCE_HL,
		icd.instance_package, W);
	icd.declaration_sequence_number = -1;
	icd.usages = NEW_LINKED_LIST(parse_node);
	NounIdentifiers::set_iname(I->as_noun, icd.instance_iname);
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
	Hierarchy::apply_metadata_from_number(pack, INSTANCE_CHEAT_MD_HL,
		(inter_ti) I->allocation_id);
	TEMPORARY_TEXT(name)
	Instances::write_name(name, I);
	Hierarchy::apply_metadata(pack, INSTANCE_NAME_MD_HL, name);
	DISCARD_TEXT(name)
	Hierarchy::apply_metadata_from_number(pack, INSTANCE_AT_MD_HL,
		(inter_ti) Wordings::first_wn(Node::get_text(I->creating_sentence)));
	Hierarchy::apply_metadata_from_iname(pack, INSTANCE_VALUE_MD_HL, I->compilation_data.instance_iname);
	inter_name *kn_iname = Hierarchy::make_iname_in(INSTANCE_KIND_MD_HL, pack);
	kind *K = Instances::to_kind(I);
	TEMPORARY_TEXT(IK)
	WRITE_TO(IK, "%u", K);
	Hierarchy::apply_metadata(pack, INSTANCE_INDEX_KIND_MD_HL, IK);
	DISCARD_TEXT(IK)
	RTKindIDs::define_constant_as_strong_id(kn_iname, K);
	Hierarchy::apply_metadata_from_iname(pack, INSTANCE_KIND_XREF_MD_HL,
		RTKindConstructors::xref_iname(K->construct));
	if (Kinds::Behaviour::is_subkind_of_object(K))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_OBJECT_MD_HL, 1);
	if ((K_sound_name) && (Kinds::eq(K, K_sound_name)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_SOUND_MD_HL, 1);
	if ((K_figure_name) && (Kinds::eq(K, K_figure_name)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_FIGURE_MD_HL, 1);
	if ((K_external_file) && (Kinds::eq(K, K_external_file)))
		Hierarchy::apply_metadata_from_number(pack,
			INSTANCE_IS_EXF_MD_HL, 1);

	if (RTShowmeCommand::needed_for_instance(I)) {
		inter_name *iname = Hierarchy::make_iname_in(INST_SHOWME_FN_HL,
			RTInstances::package(I));
		RTShowmeCommand::compile_instance_showme_fn(iname, I);
		Hierarchy::apply_metadata_from_iname(RTInstances::package(I),
			INST_SHOWME_MD_HL, iname);
	}

	Emit::instance(RTInstances::value_iname(I), Instances::to_kind(I), I->enumeration_index);
	if (I->compilation_data.declaration_sequence_number >= 0)
		Produce::annotate_i(RTInstances::value_iname(I), DECLARATION_ORDER_IANN,
			(inter_ti) I->compilation_data.declaration_sequence_number);
	RTPropertyPermissions::compile_permissions_for_instance(I);
	RTPropertyValues::compile_values_for_instance(I);

	if (Kinds::Behaviour::is_object(Instances::to_kind(I))) {
		int AC = Spatial::get_definition_depth(I);
		if (AC > 0) Produce::annotate_i(RTInstances::value_iname(I), ARROW_COUNT_IANN,
			(inter_ti) AC);
	}

	RTRegionInstances::compile_extra(I);
	RTBackdropInstances::compile_extra(I);
	RTScenes::compile_extra(I);
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
