[OrderingInstances::] Ordering Instances.

A simple system for making an ordered list of instances.

@ Here's how to place the instance objects in order. The ordering is used not
only for compilation, but also for instance counting (e.g., marking the
black gate as the 8th instance of "door"), so it's needed earlier than
the compilation phase, too.

They are stored as a linked list with the links in an array indexed by the
allocation IDs of the objects. This could all now alternatively be done with
the |linked_list| type provided by //foundation//, but never mind: it works.

= (early code)
instance *first_instance_in_list = NULL;
instance **next_instance_in_current_list = NULL;
instance *last_instance_in_list = NULL;

@ To build the list, first call //OrderingInstances::begin// then
repeatedly //OrderingInstances::place_next//.

=
void OrderingInstances::begin(void) {
	int i, nc = NUMBER_CREATED(instance);
	if (next_instance_in_current_list == NULL) {
		next_instance_in_current_list = (instance **)
			(Memory::calloc(nc, sizeof(instance *), OBJECT_COMPILATION_MREASON));
	}
	for (i=0; i<nc; i++) next_instance_in_current_list[i] = NULL;
	first_instance_in_list = NULL;
	last_instance_in_list = NULL;
}

void OrderingInstances::place_next(instance *I) {
	if (last_instance_in_list == NULL)
		first_instance_in_list = I;
	else
		next_instance_in_current_list[last_instance_in_list->allocation_id] = I;
	last_instance_in_list = I;
}

@ For instance, here we put them in order of definition, which is the default:

=
void OrderingInstances::objects_in_definition_sequence(void) {
	OrderingInstances::begin();
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		OrderingInstances::place_next(I);
}

@ And we read the order back using these macros:

@d FIRST_IN_INSTANCE_ORDERING first_instance_in_list
@d NEXT_IN_INSTANCE_ORDERING(I) next_instance_in_current_list[I->allocation_id]
@d LOOP_THROUGH_INSTANCE_ORDERING(I)
	for (I=FIRST_IN_INSTANCE_ORDERING; I; I=NEXT_IN_INSTANCE_ORDERING(I))
