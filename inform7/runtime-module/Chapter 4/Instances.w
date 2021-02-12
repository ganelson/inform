[RTInstances::] Instances.

To compile run-time support for instances.

@

=
int RTInstances::emit_element_of_condition(inference_subject_family *family,
	inference_subject *infs, inter_symbol *t0_s) {
	instance *I = InstanceSubjects::to_instance(infs);
	Produce::inv_primitive(Emit::tree(), EQ_BIP);
	Produce::down(Emit::tree());
		Produce::val_symbol(Emit::tree(), K_value, t0_s);
		Produce::val_iname(Emit::tree(), K_value, Instances::iname(I));
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
	LOOP_OVER_OBJECTS_IN_COMPILATION_SEQUENCE(I)
		RTInstances::emit_one(family, Instances::as_subject(I));
	LOOP_OVER(I, instance)
		if (Kinds::Behaviour::is_object(Instances::to_kind(I)) == FALSE)
			RTInstances::emit_one(family, Instances::as_subject(I));
	#ifdef IF_MODULE
	PL::Naming::compile_small_names();
	#endif
	return TRUE;
}

@ Either way, the actual compilation happens here:

=
void RTInstances::emit_one(inference_subject_family *family, inference_subject *infs) {
	instance *I = InstanceSubjects::to_instance(infs);
	RTInstances::emitted_iname(I);
	Properties::emit_instance_permissions(I);
	Properties::Emit::emit_subject(infs);
}

inter_name *RTInstances::emitted_iname(instance *I) {
	if (I == NULL) return NULL;
	inter_name *iname = Instances::iname(I);
	if (I->instance_emitted == FALSE) {
		I->instance_emitted = TRUE;
		Emit::instance(iname, Instances::to_kind(I), I->enumeration_index);
	}
	return iname;
}

package_request *RTInstances::package(instance *I) {
	Instances::iname(I); // Thus forcing this to exist...
	return I->instance_package;
}
