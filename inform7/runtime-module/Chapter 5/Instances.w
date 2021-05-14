[RTInstances::] Instances.

To compile the instances submodule for a compilation unit, which contains
_instance packages.

@h Compilation data.
Each |instance| object contains this data:

=
typedef struct instance_compilation_data {
	struct package_request *instance_package;
	struct inter_name *instance_iname;
} instance_compilation_data;

void RTInstances::new_compilation_data(instance *I) {
	I->icd.instance_package = Hierarchy::local_package(INSTANCES_HAP);
	wording W = Nouns::nominative(I->as_noun, FALSE);
	I->icd.instance_iname = Hierarchy::make_iname_with_memo(INSTANCE_HL,
		I->icd.instance_package, W);
	NounIdentifiers::set_iname(I->as_noun, I->icd.instance_iname);
}

inter_name *RTInstances::value_iname(instance *I) {
	if (I == NULL) return NULL;
	return I->icd.instance_iname;
}

package_request *RTInstances::package(instance *I) {
	return I->icd.instance_package;
}

@h Compilation.
Instances form one of the families of inference subjects, so their compilation
is triggered from there rather than as a step in //core: How To Compile//.

In particular, the following method call on their family generates everything
necessary. It looks tricky only because we need to compile instances in a
set order: objects in containment-tree traversal order, then non-objects in
more or less any order.

=
int RTInstances::compile_all(inference_subject_family *family, int ignored) {
	instance *I;
	LOOP_THROUGH_INSTANCE_ORDERING(I)
		@<Compile a package for I@>;
	LOOP_OVER(I, instance)
		if (Kinds::Behaviour::is_object(Instances::to_kind(I)) == FALSE)
			@<Compile a package for I@>;
	return TRUE;
}

@ This is really all metadata except for the actual instance declaration,
using Inter's |INSTANCE_IST| instruction.

@<Compile a package for I@> =
	Hierarchy::apply_metadata_from_wording(I->icd.instance_package,
		INSTANCE_NAME_MD_HL,
		Nouns::nominative(I->as_noun, FALSE));
	Hierarchy::apply_metadata_from_iname(I->icd.instance_package,
		INSTANCE_VALUE_MD_HL,
		I->icd.instance_iname);
	inter_name *kn_iname = Hierarchy::make_iname_in(INSTANCE_KIND_MD_HL,
		I->icd.instance_package);
	kind *K = Instances::to_kind(I);
	RTKindIDs::define_constant_as_strong_id(kn_iname, K);
	if ((K_scene) && (Kinds::eq(K, K_scene)))
		Hierarchy::apply_metadata_from_number(I->icd.instance_package,
			INSTANCE_IS_SCENE_MD_HL, 1);
	if ((K_sound_name) && (Kinds::eq(K, K_sound_name)))
		Hierarchy::apply_metadata_from_number(I->icd.instance_package,
			INSTANCE_IS_SOUND_MD_HL, 1);
	if ((K_figure_name) && (Kinds::eq(K, K_figure_name)))
		Hierarchy::apply_metadata_from_number(I->icd.instance_package,
			INSTANCE_IS_FIGURE_MD_HL, 1);
	if ((K_external_file) && (Kinds::eq(K, K_external_file)))
		Hierarchy::apply_metadata_from_number(I->icd.instance_package,
			INSTANCE_IS_EXF_MD_HL, 1);

	Emit::instance(RTInstances::value_iname(I), Instances::to_kind(I), I->enumeration_index);
	RTPropertyValues::emit_instance_permissions(I);
	RTPropertyValues::emit_subject(Instances::as_subject(I));

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
