[RTInstances::] Instances.

To compile run-time support for instances.

@

=
typedef struct instance_compilation_data {
	struct package_request *instance_package;
	struct inter_name *instance_iname;
	int instance_emitted;
} instance_compilation_data;

void RTInstances::initialise_icd(instance *I) {
	I->icd.instance_package = Hierarchy::local_package(INSTANCES_HAP);
	NounIdentifiers::noun_compose_identifier(I->icd.instance_package,
		I->as_noun, I->allocation_id);
	I->icd.instance_iname = NounIdentifiers::iname(I->as_noun);
	Hierarchy::markup_wording(I->icd.instance_package, INSTANCE_NAME_HMD,
		Nouns::nominative(I->as_noun, FALSE));
	I->icd.instance_emitted = FALSE;
}

inter_name *RTInstances::iname(instance *I) {
	if (I == NULL) return NULL;
	return I->icd.instance_iname;
}

@

=
int RTInstances::emit_element_of_condition(inference_subject_family *family,
	inference_subject *infs, inter_symbol *t0_s) {
	instance *I = InstanceSubjects::to_instance(infs);
	Produce::inv_primitive(Emit::tree(), EQ_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, t0_s);
		Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(I));
	Produce::up(Emit::tree());
	return TRUE;
}

@ Compilation looks tricky only because we need to compile instances in a
set order which is not the order of their creation. (This is because objects
must be compiled in containment-tree traversal order in the final Inform 6
code.) So in reply to a request to compile all instances, we first delegate
the object instances, then compile the non-object ones (all just constant
declarations) and finally return |TRUE| to indicate that the task is finished.

=
int RTInstances::emit_all(inference_subject_family *family, int ignored) {
	instance *I;
	LOOP_THROUGH_INSTANCE_ORDERING(I)
		RTInstances::emit_one(family, Instances::as_subject(I));
	LOOP_OVER(I, instance)
		if (Kinds::Behaviour::is_object(Instances::to_kind(I)) == FALSE)
			RTInstances::emit_one(family, Instances::as_subject(I));
	RTNaming::compile_small_names();
	return TRUE;
}

@ Either way, the actual compilation happens here:

=
void RTInstances::emit_one(inference_subject_family *family, inference_subject *infs) {
	instance *I = InstanceSubjects::to_instance(infs);
	RTInstances::emitted_iname(I);
	RTProperties::emit_instance_permissions(I);
	RTPropertyValues::emit_subject(infs);
}

inter_name *RTInstances::emitted_iname(instance *I) {
	if (I == NULL) return NULL;
	inter_name *iname = RTInstances::iname(I);
	if (I->icd.instance_emitted == FALSE) {
		I->icd.instance_emitted = TRUE;
		Emit::instance(iname, Instances::to_kind(I), I->enumeration_index);
	}
	return iname;
}

package_request *RTInstances::package(instance *I) {
	RTInstances::iname(I); // Thus forcing this to exist...
	return I->icd.instance_package;
}
