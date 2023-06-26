[InstanceCounting::] Instance Counting.

Though a feature, for convenience of implementation, this code is always active
and provides for efficient loops through instances at runtime.

@h Feature startup.
Being a feature, this needs a startup function, and here it is. It is in fact
called on every run: see //core: Core Module//.

=
void InstanceCounting::start(void) {
	PluginCalls::plug(NEW_SUBJECT_NOTIFY_PLUG, InstanceCounting::counting_new_subject_notify);
	PluginCalls::plug(COMPLETE_MODEL_PLUG, InstanceCounting::counting_complete_model);
	PluginCalls::plug(PRODUCTION_LINE_PLUG, InstanceCounting::production_line);
}

int InstanceCounting::production_line(int stage, int debugging, stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(InstanceCounting::define_IK_sequence_start_constants);
	}
	return FALSE;
}

@ Being a plugin, this code can provide extra data on inference subjects. It
will in practice use that only for subjects representing kinds:

@d COUNTING_DATA(subj) FEATURE_DATA_ON_SUBJECT(counting, subj)

=
typedef struct counting_data {
	int has_instances; /* are there any instances of this kind? */
	struct property *IK_count_prop;
	struct property *next_in_IK_sequence_prop; /* the IK-Link property for this kind */
	CLASS_DEFINITION
} counting_data;

@ =
int InstanceCounting::counting_new_subject_notify(inference_subject *subj) {
	ATTACH_FEATURE_DATA_TO_SUBJECT(counting, subj, InstanceCounting::new_data(subj));
	return FALSE;
}

counting_data *InstanceCounting::new_data(inference_subject *subj) {
	counting_data *cd = CREATE(counting_data);
	cd->IK_count_prop = NULL;
	cd->next_in_IK_sequence_prop = NULL;
	cd->has_instances = FALSE;
	return cd;
}

@ =
inter_name *InstanceCounting::IK_count_property(kind *K) {
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		inference_subject *subj = KindSubjects::from_kind(K);
		property *P = COUNTING_DATA(subj)->IK_count_prop;
		if (P) return RTProperties::iname(P);
	}
	return NULL;
}

@h The IK-count.
The IK-count for an instance I of kind K is the result of numbering instances
of that kind upwards from 0. This depends on both I and K, hence the name:
for example, a red car might be thing number 17 but vehicle number 2. Within
each kind, instances are numbered in creation order by the source text.

Before we can store this, we must calculate it, which we do with this less
than elegant two-dimensional array:

@d INSTANCE_COUNT(I, K)
	kind_instance_counts[(I)->allocation_id*max_kind_instance_count +
		Kinds::Behaviour::get_range_number(K)]

=
int *kind_instance_counts = NULL;
int max_kind_instance_count = 0;

void InstanceCounting::calculate_IK_counts(void) {
	@<Allocate the instance count array in memory@>;
	@<Compute the instance count array@>;
}

@<Allocate the instance count array in memory@> =
	max_kind_instance_count = NUMBER_CREATED(inference_subject);
	kind_instance_counts =
		Memory::calloc(max_kind_instance_count*max_kind_instance_count, sizeof(int),
			INSTANCE_COUNTING_MREASON);

@ The following is quadratic in the number of objects, but this has never been
a problem in practice; the number seldom exceeds a few hundred. 

@<Compute the instance count array@> =
	instance *I;
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K))
			LOOP_OVER_INSTANCES(I, K_object)
				INSTANCE_COUNT(I, K) = -1;

	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			int ix_count = 0;
			LOOP_OVER_INSTANCES(I, K)
				INSTANCE_COUNT(I, K) = ix_count++;
		}

@ Instance counts are actually useful to several other features, so we provide
the following. Note that if I is not in fact an instance of K then its IK-count
is by definition -1.

=
int InstanceCounting::IK_count(instance *I, kind *K) {
	if (kind_instance_counts == NULL) internal_error("instance counts not available");
	if (K == NULL) internal_error("instance counts available only for objects");
	return INSTANCE_COUNT(I, K);
}

@h The IK-sequence.
Within each kind K, we form the instances in a linked list called the "IK-sequence".
Again, the list position of I depends on K: the red car might be in one position
in the list of things, and another in the list of vehicles.

This sequence will be in "declaration order", that is, it will match the order
in which instances are declared in Inter. This is not the same as their creation
order in Inform 7 source text, though it tends to be roughly similar.[1]

The following function abstracts the list, returning the first instance if |I|
is |NULL|, and otherwise the next after |I|. Note that it excludes instances which
have been "diverted".[2]

[1] Declaration order is more trouble to arrange, but we do it so that an optimised
and an unoptimised loop to perform the same search will not only iterate through
the same set of objects, but in the same order.

[2] This is used to get rid of the |selfobj| object in cases where the source text
creates an explicit player.

=
instance *InstanceCounting::next_in_IK_sequence(instance *I, kind *k) {
	if (k == NULL) return NULL;
	int resuming = TRUE;
	if (I == NULL) { I = FIRST_IN_INSTANCE_ORDERING; resuming = FALSE; }
	while (I) {
		if (resuming) I = NEXT_IN_INSTANCE_ORDERING(I);
		resuming = TRUE;
		if (I == NULL) break;
		if (InferenceSubjects::aliased_but_diverted(Instances::as_subject(I)))
			continue; /* |selfobj| may not count */
		if (Instances::of_kind(I, k)) return I;
	}
	return NULL;
}

@ At runtime, we will store the IK sequences by defining their first entries
as constants,[1] and their subsequent entries as property values of instances.
The constants are declared here, and see //InstanceCounting::counting_complete_model//
below for the properties.

[1] We don't need to store these list origins in some table in memory at
runtime because Inform always compiles code which knows which kind it's looping
over: so it never needs to look up an IK-sequence where K is not known at
compile time.

=
void InstanceCounting::define_IK_sequence_start_constants(void) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			inter_name *iname = RTKindConstructors::first_instance_iname(K);
			instance *next = InstanceCounting::next_in_IK_sequence(NULL, K);
			if (next) {
				Emit::iname_constant(iname, K_object, RTInstances::value_iname(next));
			} else {
				Emit::iname_constant(iname, K_object, NULL);
			}
		}
}

@h The KD-count.
This section is supposedly for instance-counting, but it also does a little
kind-counting: specifically we number the subkinds of object. The KD-count of a
kind is this number.[1]

[1] I have completely forgotten what the D stood for. KD-counts are in creation
order, not declaration order, so it can't be D for declaration.

=
int InstanceCounting::KD_count(kind *K) {
	int c = 0;
	if (K == NULL) return 0;
	kind *IK;
	LOOP_OVER_BASE_KINDS(IK)
		if (Kinds::Behaviour::is_subkind_of_object(IK)) {
			c++;
			if (Kinds::eq(IK, K)) return c;
		}
	return 0;
}

@h Properties of instances.
At model completion time, then, we assign a set of low-level properties to
all the object instances. These consume memory without even being visible in
Inform 7 source text: they are all basically optimisations, and are a classic
trade-off of memory for speed. For the most part we care more about memory in
the Inform runtime (one of our target VMs has a very low memory ceiling), but
search loops must run as fast as they possibly can.

=
int InstanceCounting::counting_complete_model(int stage) {
	if (stage == WORLD_STAGE_I) {
		@<Create and assert zero values of the vector property@>;
	}
	if (stage == WORLD_STAGE_V) {
		property *P_KD_Count = ValueProperties::new_nameless(I"KD_Count", K_number);
		@<Create the two instance properties for each kind of object@>;
		InstanceCounting::calculate_IK_counts();
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object) {
			@<Assert the KD count property for I@>;
			@<Assert values of the two instance properties for I@>;
		}
	}
	return FALSE;
}

@ The |vector| property provides workspace for the relation-route-finding code
at runtime: it doesn't actually have anything to do with instance counting as
such, but then again it doesn't deserve its own section of code.

@<Create and assert zero values of the vector property@> =
	property *P_vector = ValueProperties::new_nameless(I"vector", K_number);
	parse_node *zero = Rvalues::from_int(0, EMPTY_WORDING);
	instance *I;
	LOOP_OVER_INSTANCES(I, K_object)
		ValueProperties::assert(P_vector,
			Instances::as_subject(I), zero, CERTAIN_CE);

@ For each subkind of object K to which an instance I belongs, we will store the
IK-count in a numerical property. So the red car, for example, would be given two
property values: one for (red car, thing), one for (red car, vehicle). The
properties in question are the |IK_count_prop| for thing and vehicle.

Similarly for the next terms in the IK-sequences.

@<Create the two instance properties for each kind of object@> =
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			inference_subject *subj = KindSubjects::from_kind(K);
			inter_name *count_iname = RTKindConstructors::base_IK_iname(K);

			COUNTING_DATA(subj)->IK_count_prop =
				ValueProperties::new_nameless_using(K_number,
					RTKindConstructors::kind_package(K), count_iname);

			inter_name *next_iname = RTKindConstructors::next_instance_iname(K);
			COUNTING_DATA(subj)->next_in_IK_sequence_prop =
				ValueProperties::new_nameless_using(K_object,
					RTKindConstructors::kind_package(K), next_iname);
		}

@ For any object instance, the property |KD_Count| holds the KD-count for its
immediate kind. For a red car which was both vehicle and thing, therefore, this
would be the number for "vehicle", not for "thing".

@<Assert the KD count property for I@> =
	int ic = InstanceCounting::KD_count(Instances::to_kind(I));
	parse_node *the_count = Rvalues::from_int(ic, EMPTY_WORDING);
	ValueProperties::assert(
		P_KD_Count, Instances::as_subject(I), the_count, CERTAIN_CE);

@<Assert values of the two instance properties for I@> =
	inference_subject *infs;
	for (infs = KindSubjects::from_kind(Instances::to_kind(I));
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		kind *K = KindSubjects::to_kind(infs);
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			inference_subject *subj = KindSubjects::from_kind(K);
			COUNTING_DATA(subj)->has_instances = TRUE;
			@<Fill in this IK-count property@>;
			@<Fill in this IK-sequence property@>;
		}
	}

@ And otherwise, for every kind that the instance belongs to (directly or
indirectly) it gets the relevant instance count as a property value. For
example, the red door might have |IK4_Count| set to 3 -- it's door number 3,
let's suppose -- and |IK2_Count| set to 19 -- it's thing number 19. It doesn't
have an |IK7_Count| property at all, since it isn't a backdrop (kind number 7),
and so on for all other kinds.

@<Fill in this IK-count property@> =
	int ic = INSTANCE_COUNT(I, K);
	parse_node *the_count = Rvalues::from_int(ic, EMPTY_WORDING);
	ValueProperties::assert(
		COUNTING_DATA(subj)->IK_count_prop,
		Instances::as_subject(I), the_count, CERTAIN_CE);

@ The IK-Link property is never set for kind 0, so there's no special case. It
records the next instance in compilation order:

@<Fill in this IK-sequence property@> =
	instance *next = InstanceCounting::next_in_IK_sequence(I, K);
	parse_node *val = (next)?
		Rvalues::from_instance(next):
		Rvalues::new_nothing_object_constant();
	ValueProperties::assert(
		COUNTING_DATA(subj)->next_in_IK_sequence_prop,
		Instances::as_subject(I), val, CERTAIN_CE);

@h Loop optimisation.
Lastly, then, the coup de grace: here's where we define loop schemas to
perform loops through kinds quickly at run-time. We start from the First
constants, and use the Next constants to progress; and we stop at |nothing|.

There is no actual need to compile the schema differently in the case of
an empty loop, where there are no instances of the kind |K| to loop over:
the regular schema would work fine. But it would make the code somehow
misleading to a human reader.

=
int InstanceCounting::optimise_loop(i6_schema *sch, kind *K) {
	if (FEATURE_INACTIVE(counting)) return FALSE;
	inference_subject *subj = KindSubjects::from_kind(K);
	if (COUNTING_DATA(subj)->has_instances == FALSE) {
		Calculus::Schemas::modify(sch,
			"for (*1=nothing: false: )");
	} else {
		inter_name *first_iname = RTKindConstructors::first_instance_iname(K);
		inter_name *next_iname = RTKindConstructors::next_instance_iname(K);
		Calculus::Schemas::modify(sch, "for (*1=%n: *1: *1=*1.%n)", first_iname, next_iname);
	}
	return TRUE;
}
