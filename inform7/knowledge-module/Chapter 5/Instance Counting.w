[PL::Counting::] Instance Counting.

A plugin which maintains run-time-accessible linked lists of instances
of kinds, in order to speed up loops; and instance counts within kinds, in order
to speed up relation storage; and the object-kind hierarchy, in order to speed
up run-time checking of the type safety of property usage.

@ Every subject contains a pointer to its own unique copy of the following
structure, but it only has relevance if the subject represents an object:

@d COUNTING_DATA(subj) PLUGIN_DATA_ON_SUBJECT(counting, subj)

=
typedef struct counting_data {
	struct property *instance_count_prop; /* the (|I6| only) IK-Count property for this kind */
	struct property *instance_link_prop; /* the (|I6| only) IK-Link property for this kind */
	int has_instances; /* are there any instances of this kind? */
	CLASS_DEFINITION
} counting_data;

@ In addition to these I6 properties, two for each kind, there's a single
additional property called |vector| which is needed as run-time storage for
route-finding through relations on objects.

=
property *P_vector = NULL;
property *P_KD_Count = NULL; /* see below */

@h Plugin startup.

=
void PL::Counting::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_SUBJECT_NOTIFY, PL::Counting::counting_new_subject_notify);
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Counting::counting_complete_model);
	PLUGIN_REGISTER(PLUGIN_COMPILE_MODEL_TABLES, PL::Counting::counting_compile_model_tables);
	PLUGIN_REGISTER(PLUGIN_ESTIMATE_PROPERTY_USAGE, PL::Counting::counting_estimate_property_usage);
}

@h Initialising.
Counting data is actually relevant only for kinds, and remains blank for instances.

=
int PL::Counting::counting_new_subject_notify(inference_subject *subj) {
	ATTACH_PLUGIN_DATA_TO_SUBJECT(counting, subj, PL::Counting::new_data);
	return FALSE;
}

counting_data *PL::Counting::new_data(inference_subject *subj) {
	counting_data *cd = CREATE(counting_data);
	cd->instance_count_prop = NULL;
	cd->instance_link_prop = NULL;
	cd->has_instances = FALSE;
	return cd;
}

@h Computing instance counts.
We're going to store these temporarily in an array which must be allocated
dynamically in memory, and this will make lookups quite fiddly, so we
use the following macro to specify the integer lvalue for the instance
count of instance |I| within kind |k|. This depends on both: for example,
the red car might be thing number 17 but vehicle number 2, and will be
door number $-1$, since it isn't a door. The first instance in a kind is
numbered 0.

@d INSTANCE_COUNT(I, K)
	kind_instance_counts[(I)->allocation_id*max_kind_instance_count +
		Kinds::RunTime::I6_classnumber(K)]

=
int *kind_instance_counts = NULL;
int max_kind_instance_count = 0;

void PL::Counting::make_instance_counts(void) {
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
			LOOP_OVER_OBJECT_INSTANCES(I)
				INSTANCE_COUNT(I, K) = -1;

	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			int ix_count = 0;
			LOOP_OVER_INSTANCES(I, K)
				INSTANCE_COUNT(I, K) = ix_count++;
		}

@ Instance counts are actually useful to several other plugins, so we provide:

=
int PL::Counting::instance_count(instance *I, kind *K) {
	if (kind_instance_counts == NULL) internal_error("instance counts not available");
	if (K == NULL) internal_error("instance counts available only for objects");
	return INSTANCE_COUNT(I, K);
}

@h Instance sequences.
At run-time we're going to want to loop through objects in order of their
definition in the I6 code, which is not the same as their creation order in I7.
(This is so that an optimised and an unoptimised loop to perform the same
search will not only iterate through the same set of objects, but in the
same order.)

The following abstracts the linked list in compilation sequence. Note that
it excludes instances which have been "diverted", which is mainly used
to get rid of the |selfobj| object in cases where the source text creates
an explicit player.

=
instance *PL::Counting::next_instance_of(instance *I, kind *k) {
	if (k == NULL) return NULL;
	int resuming = TRUE;
	if (I == NULL) { I = FIRST_IN_COMPILATION_SEQUENCE; resuming = FALSE; }
	while (I) {
		if (resuming) I = NEXT_IN_COMPILATION_SEQUENCE(I);
		resuming = TRUE;
		if (I == NULL) break;
		if (InferenceSubjects::aliased_but_diverted(Instances::as_subject(I)))
			continue; /* |selfobj| may not count */
		if (Instances::of_kind(I, k)) return I;
	}
	return NULL;
}

@ For compilation purposes, it's useful to express this as a specification:

=
parse_node *PL::Counting::next_instance_of_as_value(instance *I, kind *k) {
	instance *next = PL::Counting::next_instance_of(I, k);
	if (next) return Rvalues::from_instance(next);
	return Rvalues::new_nothing_object_constant();
}

@h Inform 6 representation.
The main purpose of this plugin is to trade memory for speed at run-time.
Inform source text is rich in implied searches through kinds ("if a red
door is open, ...") and we need these to be as fast as possible; iterating
through all objects would be dangerously slow, so we need a way at run-time
to iterate through the instances of a single kind (in this example, doors).

For each kind we will store a linked list of instances. The first instance
need only be defined as a constant, and need not be stored in a memory word,
since Inform always compiles code which knows which kind it's looping over.

=
inter_name *PL::Counting::first_instance(kind *K) {
	kind_constructor *con = Kinds::get_construct(K);
	inter_name *iname = Kinds::Constructors::first_instance_iname(con);
	if (iname == NULL) {
		iname = Hierarchy::derive_iname_in(FIRST_INSTANCE_HL, Kinds::RunTime::iname(K), Kinds::Behaviour::package(K));
		Kinds::Constructors::set_first_instance_iname(con, iname);
	}
	return iname;
}

inter_name *PL::Counting::next_instance(kind *K) {
	kind_constructor *con = Kinds::get_construct(K);
	inter_name *iname = Kinds::Constructors::next_instance_iname(con);
	if (iname == NULL) {
		iname = Hierarchy::derive_iname_in(NEXT_INSTANCE_HL, Kinds::RunTime::iname(K), Kinds::Behaviour::package(K));
		Kinds::Constructors::set_next_instance_iname(con, iname);
	}
	return iname;
}

inter_name *PL::Counting::instance_count_iname(kind *K) {
	int N = Kinds::RunTime::I6_classnumber(K);
	if (N == 1) return Hierarchy::make_iname_in(COUNT_INSTANCE_1_HL, Kinds::Behaviour::package(K));
	if (N == 2) return Hierarchy::make_iname_in(COUNT_INSTANCE_2_HL, Kinds::Behaviour::package(K));
	if (N == 3) return Hierarchy::make_iname_in(COUNT_INSTANCE_3_HL, Kinds::Behaviour::package(K));
	if (N == 4) return Hierarchy::make_iname_in(COUNT_INSTANCE_4_HL, Kinds::Behaviour::package(K));
	if (N == 5) return Hierarchy::make_iname_in(COUNT_INSTANCE_5_HL, Kinds::Behaviour::package(K));
	if (N == 6) return Hierarchy::make_iname_in(COUNT_INSTANCE_6_HL, Kinds::Behaviour::package(K));
	if (N == 7) return Hierarchy::make_iname_in(COUNT_INSTANCE_7_HL, Kinds::Behaviour::package(K));
	if (N == 8) return Hierarchy::make_iname_in(COUNT_INSTANCE_8_HL, Kinds::Behaviour::package(K));
	if (N == 9) return Hierarchy::make_iname_in(COUNT_INSTANCE_9_HL, Kinds::Behaviour::package(K));
	if (N == 10) return Hierarchy::make_iname_in(COUNT_INSTANCE_10_HL, Kinds::Behaviour::package(K));
	return Hierarchy::derive_iname_in(COUNT_INSTANCE_HL, Kinds::RunTime::iname(K), Kinds::Behaviour::package(K));
}

int PL::Counting::counting_compile_model_tables(void) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			inter_name *iname = PL::Counting::first_instance(K);
			instance *next = PL::Counting::next_instance_of(NULL, K);
			if (next) {
				Emit::named_iname_constant(iname, K_object, Instances::emitted_iname(next));
			} else {
				Emit::named_iname_constant(iname, K_object, NULL);
			}
		}
	return FALSE;
}

@ Counting kinds of object, not very quickly:

=
int PL::Counting::kind_of_object_count(kind *K) {
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

@ So now the compiler can define the start of a linked list of instances
for a given kind, but how can it define the inductive step? The answer is
that every instance of kind number 4 (say) provides an I6 property |IK4_Link|
whose value is the next instance, or else |nothing| if it's the last.

A further property, |IK4_Count|, holds the instance count; this is used for
efficient access to various-to-various relation storage at run-time. If we
have a relation of various doors to various rooms, say, we want to store a
bitmap only $D\times R$ in size, but then to access this quickly given a
specific door and room, we need to convert these quickly to their indices;
this is what |IK4_Count| does.

We create these properties, and assert these property values, during stage IV
of model completion:

=
int PL::Counting::counting_complete_model(int stage) {
	if (stage == 1) {
		@<Create and assert zero values of the vector property@>;
	}
	if (stage == 4) {
		@<Create the two instance properties for each kind of object@>;
		PL::Counting::make_instance_counts();
		@<Assert values of the two instance properties for each instance@>;
	}
	return FALSE;
}

@ The |vector| property exists only at the I6 level, and provides workspace
for the relation-route-finding code at run time.

@<Create and assert zero values of the vector property@> =
	P_vector = Properties::Valued::new_nameless(I"vector", K_number);
	parse_node *zero = Rvalues::from_int(0, EMPTY_WORDING);
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		Properties::Valued::assert(P_vector,
			Instances::as_subject(I), zero, CERTAIN_CE);

@<Create the two instance properties for each kind of object@> =
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Behaviour::is_subkind_of_object(K)) {
			inference_subject *subj = Kinds::Knowledge::as_subject(K);
			inter_name *count_iname = PL::Counting::instance_count_iname(K);

			COUNTING_DATA(subj)->instance_count_prop =
				Properties::Valued::new_nameless_using(K_number, Kinds::Behaviour::package(K), count_iname);

			inter_name *next_iname = PL::Counting::next_instance(K);
			COUNTING_DATA(subj)->instance_link_prop =
				Properties::Valued::new_nameless_using(K_object, Kinds::Behaviour::package(K), next_iname);
		}
	P_KD_Count = Properties::Valued::new_nameless(I"KD_Count", K_number);

@<Assert values of the two instance properties for each instance@> =
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I) {
		@<Fill in the special IK0-Count property@>;
		inference_subject *infs;
		for (infs = Kinds::Knowledge::as_subject(Instances::to_kind(I));
			infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
			kind *K = Kinds::Knowledge::from_infs(infs);
			if (Kinds::Behaviour::is_subkind_of_object(K)) {
				inference_subject *subj = Kinds::Knowledge::as_subject(K);
				COUNTING_DATA(subj)->has_instances = TRUE;
				@<Fill in this IK-Count property@>;
				@<Fill in this IK-Link property@>;
			}
		}
	}

@ As noted above, |KD_Count| is a special case. This looks as if it should be
the instance count of "kind" itself, but that would be useless, since no
instance object can ever have kind "kind" -- instances aren't kinds.

Instead it holds the kind number of its own (direct) kind. For example, if the
instance object is the red door, its |KD_Count| value will be 4, meaning that
its kind is kind number 4, which according to the |KindHierarchy| array is
|K4_door|. Again, this is needed for rapid checking at run-time that property
usage is legal.

@<Fill in the special IK0-Count property@> =
	int ic = PL::Counting::kind_of_object_count(Instances::to_kind(I));
	parse_node *the_count = Rvalues::from_int(ic, EMPTY_WORDING);
	Properties::Valued::assert(
		P_KD_Count, Instances::as_subject(I), the_count, CERTAIN_CE);

@ And otherwise, for every kind that the instance belongs to (directly or
indirectly) it gets the relevant instance count as a property value. For
example, the red door might have |IK4_Count| set to 3 -- it's door number 3,
let's suppose -- and |IK2_Count| set to 19 -- it's thing number 19. It doesn't
have an |IK7_Count| property at all, since it isn't a backdrop (kind number 7),
and so on for all other kinds.

@<Fill in this IK-Count property@> =
	int ic = INSTANCE_COUNT(I, K);
	parse_node *the_count = Rvalues::from_int(ic, EMPTY_WORDING);
	Properties::Valued::assert(
		COUNTING_DATA(subj)->instance_count_prop,
		Instances::as_subject(I), the_count, CERTAIN_CE);

@ The IK-Link property is never set for kind 0, so there's no special case. It
records the next instance in compilation order:

@<Fill in this IK-Link property@> =
	Properties::Valued::assert(
		COUNTING_DATA(subj)->instance_link_prop,
		Instances::as_subject(I), PL::Counting::next_instance_of_as_value(I, K), CERTAIN_CE);

@ =
inter_name *PL::Counting::instance_count_property_symbol(kind *K) {
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		inference_subject *subj = Kinds::Knowledge::as_subject(K);
		property *P = COUNTING_DATA(subj)->instance_count_prop;
		if (P) return Properties::iname(P);
	}
	return NULL;
}

@h Memory estimation.
We're going to need about 4 words of extra memory to store the two properties
per instance per kind, so:

=
int PL::Counting::counting_estimate_property_usage(kind *k, int *words_used) {
	inference_subject *infs;
	for (infs = InferenceSubjects::narrowest_broader_subject(Kinds::Knowledge::as_subject(k));
		infs; infs = InferenceSubjects::narrowest_broader_subject(infs)) {
		kind *k2 = Kinds::Knowledge::from_infs(infs);
		if (Kinds::Behaviour::is_subkind_of_object(k2))
			*words_used += 4;
	}
	return FALSE;
}

@h Loop optimisation.
Lastly, then, the coup de gr\^ace: here's where we define loop schemas to
perform loops through kinds quickly at run-time. We start from the First
constants, and use the Link constants to progress; we stop at |nothing|.

=
int PL::Counting::optimise_loop(i6_schema *sch, kind *K) {
	if (Plugins::Manage::plugged_in(counting_plugin) == FALSE) return FALSE;
	inference_subject *subj = Kinds::Knowledge::as_subject(K);
	if (COUNTING_DATA(subj)->has_instances == FALSE) /* (to avoid writing misleading code) */
		Calculus::Schemas::modify(sch,
			"for (*1=nothing: false: )");
	else {
		inter_name *first_iname = PL::Counting::first_instance(K);
		inter_name *next_iname = PL::Counting::next_instance(K);
		Calculus::Schemas::modify(sch, "for (*1=%n: *1: *1=*1.%n)", first_iname, next_iname);
	}
	return TRUE;
}
