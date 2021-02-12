[InstanceSubjects::] Instance Subjects.

The instances family of inference subjects.

@ See //Instances// and //runtime: Instances// for more; this section is only
a go-between.

=
inference_subject_family *instances_family = NULL;

inference_subject_family *InstanceSubjects::family(void) {
	if (instances_family == NULL) {
		instances_family = InferenceSubjects::new_family();
		METHOD_ADD(instances_family,
			GET_DEFAULT_CERTAINTY_INFS_MTID, InstanceSubjects::certainty);
		METHOD_ADD(instances_family,
			GET_NAME_TEXT_INFS_MTID, InstanceSubjects::get_name);
		METHOD_ADD(instances_family,
			MAKE_ADJ_CONST_DOMAIN_INFS_MTID, InstanceSubjects::make_adj_const_domain);
		METHOD_ADD(instances_family,
			NEW_PERMISSION_GRANTED_INFS_MTID, InstanceSubjects::new_permission_granted);

		METHOD_ADD(instances_family,
			EMIT_ALL_INFS_MTID, RTInstances::emit_all);
		METHOD_ADD(instances_family,
			EMIT_ONE_INFS_MTID, RTInstances::emit_one);
		METHOD_ADD(instances_family,
			EMIT_ELEMENT_INFS_MTID, RTInstances::emit_element_of_condition);
	}
	return instances_family;
}

int InstanceSubjects::certainty(inference_subject_family *f, inference_subject *infs) {
	return CERTAIN_CE;	
}

inference_subject *InstanceSubjects::new(instance *I, kind *K) {
	return InferenceSubjects::new(KindSubjects::from_kind(K),
		InstanceSubjects::family(), STORE_POINTER_instance(I), NULL);
}

instance *InstanceSubjects::to_instance(inference_subject *infs) {
	if ((infs) && (infs->infs_family == instances_family))
		return RETRIEVE_POINTER_instance(infs->represents);
	return NULL;
}

instance *InstanceSubjects::to_object_instance(inference_subject *infs) {
	instance *I = InstanceSubjects::to_instance(infs);
	if ((I) && (Kinds::Behaviour::is_object(Instances::to_kind(I)))) return I;
	return NULL;
}

void InstanceSubjects::get_name(inference_subject_family *family,
	inference_subject *from, wording *W) {
	instance *I = InstanceSubjects::to_instance(from);
	*W = Instances::get_name(I, FALSE);
}

void InstanceSubjects::new_permission_granted(inference_subject_family *f,
	inference_subject *from, general_pointer *G) {
	*G = STORE_POINTER_property_of_value_storage(Properties::OfValues::get_storage());
}

void InstanceSubjects::make_adj_const_domain(inference_subject_family *family,
	inference_subject *S, instance *I, property *P) {
	Instances::make_adj_const_domain(I, P, NULL, InstanceSubjects::to_instance(S));
}
