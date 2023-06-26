[KindSubjects::] Kind Subjects.

The kinds family of inference subjects.

@ Every base kind gets its own inference subject, making it possible to draw
inferences from sentences such as:

>> A scene has a number called the witness count. The witness count of a scene is usually 4.

=
inference_subject_family *kinds_family = NULL;

inference_subject_family *KindSubjects::family(void) {
	if (kinds_family == NULL) {
		kinds_family = InferenceSubjects::new_family();
		METHOD_ADD(kinds_family, GET_DEFAULT_CERTAINTY_INFS_MTID,
			KindSubjects::certainty);
		METHOD_ADD(kinds_family, GET_NAME_TEXT_INFS_MTID,
			KindSubjects::get_name_text);
		METHOD_ADD(kinds_family, MAKE_ADJ_CONST_DOMAIN_INFS_MTID,
			KindSubjects::make_adj_const_domain);
		METHOD_ADD(kinds_family, NEW_PERMISSION_GRANTED_INFS_MTID,
			KindSubjects::new_permission_granted);

		METHOD_ADD(kinds_family, EMIT_ELEMENT_INFS_MTID, RTKindIDs::emit_element_of_condition);
	}
	return kinds_family;
}

@ Although we speak as if each kind has its own associated subject, it is
actually kind constructors which have subjects, not kinds -- but not all
kind constructors; only the ones corresponding to base kinds. Kind variables
and intermediate results of calculations do not get a subject, since they
cannot sensibly be given properties; likewise proper constructors such as
"list of K".

The //kinds: Kind Constructors// code kindly allows us to use one field
of the |kind_constructor| structure to connect a base kind (i.e., a kind
constructor) with its subject. The following is called when a new constructor
is created.

=
inference_subject *KindSubjects::new(kind_constructor *con) {
	if ((con != CON_KIND_VARIABLE) && (con != CON_INTERMEDIATE) &&
		(con->constructor_arity == 0)) {
		inference_subject *infs = InferenceSubjects::new(global_constants,
			KindSubjects::family(), STORE_POINTER_kind_constructor(con), NULL);
		con->base_as_infs = infs;
		return infs;
	}
	return NULL;
}

@ Going via the constructor makes converting between kinds and their subjects
a little trickier than for other subject families:

=
inference_subject *KindSubjects::from_kind(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->base_as_infs;
}

kind *KindSubjects::to_kind(inference_subject *infs) {
	if ((infs) && (infs->infs_family == kinds_family)) {
		kind *K = Kinds::base_construction(
				RETRIEVE_POINTER_kind_constructor(infs->represents));
		return K;
	}
	return NULL;
}

kind *KindSubjects::to_nonobject_kind(inference_subject *infs) {
	kind *K = KindSubjects::to_kind(infs);
	if ((K) && (Kinds::Behaviour::is_subkind_of_object(K))) return NULL;
	return K;
}

@ This is used to overcome a timing problem. A few inference subjects need to
be defined early in Inform's run to set up relations -- "thing", for example.
So when we do finally create "thing" as a kind of object, it needs to be
matched up with the inference subject already existing.

=
void KindSubjects::renew(kind *K, kind *super, wording W) {
	inference_subject *revised = NULL;
	if (Wordings::nonempty(W)) PluginCalls::name_to_early_infs(W, &revised);
	if (revised) {
		InferenceSubjects::infs_initialise(revised,
			STORE_POINTER_kind_constructor(K->construct), KindSubjects::family(),
			KindSubjects::from_kind(super), NULL);
		K->construct->base_as_infs = revised;
	}
}

@ Even base kinds which do have subjects do not necessarily allow properties
to be given to their values -- "number", for instance, where you cannot give
a property to the number 6.

In general a value can have properties if and only if its kind passes this test:

=
int KindSubjects::has_properties(kind *K) {
	if (K == NULL) return FALSE;
	if (Kinds::Behaviour::is_an_enumeration(K)) return TRUE;
	if (Kinds::Behaviour::is_object(K)) return TRUE;
	return FALSE;
}

@ As noted above, a POVS structure is attached to every property permission
concerning our kind.

=
void KindSubjects::new_permission_granted(inference_subject_family *f,
	inference_subject *from, property_permission *pp) {
	kind *K = KindSubjects::to_kind(from);
	if (RTKindConstructors::is_nonstandard_enumeration(K))
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(Untestable),
			"this kind cannot have properties",
			"since it is an enumeration provided by a kit.");
	RTPropertyPermissions::new_storage(pp);
}

@ When a property value comes along which might have an adjectival use -- say,
"green" out of a range of possible colour nouns -- the following is called.
We simply pass the request along to the appropriate code.

=
void KindSubjects::make_adj_const_domain(inference_subject_family *family,
	inference_subject *infs, instance *I, property *prn) {
	kind *K = KindSubjects::to_kind(infs);
	InstanceAdjectives::make_adjectival(I, prn, K, NULL);
}

@ =
void KindSubjects::get_name_text(inference_subject_family *family,
	inference_subject *from, wording *W) {
	kind *K = KindSubjects::to_kind(from);
	*W = Kinds::Behaviour::get_name(K, FALSE);
}

@ Inferences about kinds are considered only likely to be true of something
of that kind, not certain:

=
int KindSubjects::certainty(inference_subject_family *f, inference_subject *infs) {
	return LIKELY_CE;	
}

@ The //kinds// module, and specifically //kinds: The Lattice of Kinds//,
places kinds into a hierarchy. But as noted in //Inference Subjects//,
subjects also form a hierarchy. How do these match up?

The answer is that the subjects hierarchy is larger, but that the part of
it made of kinds subjects is the same graph as the kinds lattice. Not just
a copy of it; actually the thing itself, because of the following functions,
which tell the //kinds// module to use the subjects hierarchy when it wants
to know if one base kind contains another.

@d HIERARCHY_GET_SUPER_KINDS_CALLBACK KindSubjects::super
@d HIERARCHY_ALLOWS_SOMETIMES_MATCH_KINDS_CALLBACK KindSubjects::allow_sometimes
@d HIERARCHY_MOVE_KINDS_CALLBACK KindSubjects::move_within

=
kind *KindSubjects::super(kind *K) {
	inference_subject *infs = KindSubjects::from_kind(K);
	return KindSubjects::to_kind(InferenceSubjects::narrowest_broader_subject(infs));
}

void KindSubjects::move_within(kind *sub, kind *super) {
	if (Kinds::Behaviour::is_object(super))
		InferenceSubjects::falls_within(
			KindSubjects::from_kind(sub), KindSubjects::from_kind(super));
}

int KindSubjects::allow_sometimes(kind *from) {
	while (from) {
		if (Kinds::eq(from, K_object)) return TRUE;
		from = Latticework::super(from);
	}
	return FALSE;
}

@ Lastly, a bridge to the //kinds// module: the main compiler has to provide
callbacks for it, as follows. When the //kinds// module creates a new base kind,
it calls this:

@d NEW_BASE_KINDS_CALLBACK KindSubjects::new_base_kind_notify

=
int KindSubjects::new_base_kind_notify(kind *K, kind *super, text_stream *d, wording W) {
	KindSubjects::renew(K, super, W);
	if (<property-name>(W)) {
		property *P = <<rp>>;
		ValueProperties::set_kind(P, K);
		Instances::make_kind_coincident(K, P);
	}
	PluginCalls::new_base_kind_notify(K, super, d, W);
	return FALSE;
}

@ And here goes:

@d HIERARCHY_VETO_MOVE_KINDS_CALLBACK KindSubjects::set_subkind_notify

=
int KindSubjects::set_subkind_notify(kind *sub, kind *super) {
	if (Kinds::Behaviour::is_subkind_of_object(sub) == FALSE) return TRUE;
	return PluginCalls::set_subkind_notify(sub, super);
}
