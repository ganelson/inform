[InferenceSubjects::] Inference Subjects.

A unified way to refer to the things propositions talk about.

@h Families.
//inference_subject// is a type which can represent anything in the model
which a proposition can discuss: in particular, kinds, relations, variables
and instances. These have very different implementations, and so subjects
are divided into "families", and general functions on subjects are done
as method calls. There are (currently) five families.

Each family is an instance of:

=
typedef struct inference_subject_family {
	struct method_set *methods;
	CLASS_DEFINITION
} inference_subject_family;

inference_subject_family *InferenceSubjects::new_family(void) {
	inference_subject_family *f = CREATE(inference_subject_family);
	f->methods = Methods::new_set();
	return f;
}

@ The "fundamentals" family will be defined here. As we will see, it is used
only for a few broad concepts. It provides few method functions, because these
subjects serve a mainly organisational role.[1]

[1] Though, for instance, by giving |global_variables| permission to have the
"initial value" property, we immediately grant the same to every global
variable, by inheritance. So fundamental subjects have their uses.

=
inference_subject_family *fundamentals_family = NULL;

inference_subject_family *InferenceSubjects::fundamentals(void) {
	if (fundamentals_family == NULL) {
		fundamentals_family = InferenceSubjects::new_family();
		METHOD_ADD(fundamentals_family, GET_DEFAULT_CERTAINTY_INFS_MTID,
			InferenceSubjects::fundamental_certainty);
	}
	return fundamentals_family;
}

int InferenceSubjects::fundamental_certainty(inference_subject_family *f,
	inference_subject *infs) {
	return LIKELY_CE;	
}

inference_subject *InferenceSubjects::new_fundamental(inference_subject *from,
	char *log_name) {
	return InferenceSubjects::new(from, InferenceSubjects::fundamentals(),
		NULL_GENERAL_POINTER, log_name);
}

@h Hierarchy.
An "inference subject" is anything about which an inference can be drawn.
These subjects form a hierarchy.[1] I "inherits from" J if a fact about I
is necessarily also a fact about J, unless directly contradicted by specific
information about J. For example,

>> The plastic bag is a container. A container is usually opaque. The bag is transparent.

The inference subject for the bag inherits from that for the container, so
without that final sentence, the bag would have been opaque.

Each subject has a link to the narrowest subject which is broader than it is.
For the bag subject, that would be the container subject; for the container
subject, it would be the thing subject; and so on.[2]

[1] A directed acyclic graph of the sort sometimes called a spaghetti stack, in
which all of the links run upwards to a common root -- the |model_world| subject,
which represents the entire model.

[2] The subject hierarchy thus contains the same tree structure of
//kinds: The Lattice of Kinds//, which is not a coincidence -- see
//
but of course it includes instances and much else as well.

@ The top of the inference hierarchy is essentially fixed, and contains a number
of "fundamental" subjects:

= (early code)
inference_subject *model_world = NULL;
inference_subject *global_variables = NULL;
inference_subject *global_constants = NULL;
inference_subject *relations = NULL;

@ And these are set up in a tiny hierarchy, with |model_world| at the top, the
one and only subject with no broader subject:
= (text)
	model_world
	    global_variables
	    global_constants
	    relations
=

=
void InferenceSubjects::make_built_in(void) {
	model_world = InferenceSubjects::new_fundamental(NULL, "model-world");
	global_variables = InferenceSubjects::new_fundamental(model_world, "global-variables");
	global_constants = InferenceSubjects::new_fundamental(model_world, "global-constants");
	relations = InferenceSubjects::new_fundamental(model_world, "relations");
	Plugins::Call::create_inference_subjects();
}

@h Creation of subjects.
Each subject is an instance of:

=
typedef struct inference_subject {
	struct inference_subject *broader_than; /* going up in the hierarchy */

	struct inference_subject_family *infs_family;
	struct general_pointer represents; /* family-specific data */
	void *additional_data_for_plugins[MAX_PLUGINS]; /* and managed by those plugins */

	struct inference *inf_list; /* contingently true: inferences drawn about this subject */
	struct implication *imp_list; /* necessarily true: implications applying to this  */

	struct property_permission *permissions_list; /* what properties this can have, if any */
	struct assemblies_data assemblies; /* what generalisations have been made about this? */
	struct nonlocal_variable *alias_variable; /* in the way that "player" aliases "yourself" */

	struct parse_node *infs_created_at; /* which sentence created this */
	char *infs_name_in_log; /* solely to make the debugging log more legible */
	CLASS_DEFINITION
} inference_subject;

@ The following is provided as two functions, not one, so that a subject can
be reinitialised. (This is used to get around awkward timing problems with some
of the basic kinds in the //if// module: a placeholder subject is made for
"thing" early in the run, and then is reinitialised as the subject for this
kind once the kind itself is created.)

=
inference_subject *InferenceSubjects::new(inference_subject *from,
	inference_subject_family *family, general_pointer gp, char *log_name) {
	inference_subject *infs = CREATE(inference_subject);
	InferenceSubjects::infs_initialise(infs, gp, family, from, log_name);
	return infs;
}

int no_roots = 0;
void InferenceSubjects::infs_initialise(inference_subject *infs,
	general_pointer gp, inference_subject_family *family,
	inference_subject *from, char *log_name) {
	if ((from == NULL) && (++no_roots > 1)) {
		InferenceSubjects::log_infs_hierarchy();
		internal_error("subject tree now disconnected");
	}
	if (from == infs) internal_error("made sub-subject of itself");
	infs->infs_created_at = current_sentence;
	infs->represents = gp;
	infs->infs_family = family;
	infs->inf_list = NULL;
	infs->imp_list = NULL;
	infs->broader_than = from;
	infs->permissions_list = NULL;
	infs->infs_name_in_log = log_name;
	infs->alias_variable = NULL;
	Assertions::Assemblies::initialise_assemblies_data(&(infs->assemblies));
	for (int i=0; i<MAX_PLUGINS; i++) infs->additional_data_for_plugins[i] = NULL;
	Plugins::Call::new_subject_notify(infs);
}

@h Aliasing.
See //if: The Player//, which is the only place where this is needed at present.
It has to do with the difference between "yourself" and "the player".

=
void InferenceSubjects::alias_to_nonlocal_variable(inference_subject *infs, nonlocal_variable *q) {
	infs->alias_variable = q;
}

int InferenceSubjects::aliased_but_diverted(inference_subject *infs) {
	if (infs->alias_variable) {
		inference_subject *vs =
			Instances::as_subject(
				Rvalues::to_object_instance(
					VariableSubjects::get_initial_value(
						infs->alias_variable)));
		if ((vs) && (vs != infs)) return TRUE;
	}
	return FALSE;
}

@h Breadth.
Some subjects are broad, covering many things, and others narrow -- perhaps
used to specify facts about only a single person or value.

Either two different subjects are disjoint or one strictly contains the other.
This makes testing for containment simple:

=
int InferenceSubjects::is_within(inference_subject *smaller, inference_subject *larger) {
	while (smaller) {
		if (smaller == larger) return TRUE;
		smaller = smaller->broader_than;
	}
	return FALSE;
}

int InferenceSubjects::is_strictly_within(inference_subject *subj, inference_subject *larger) {
	if (subj == NULL) return FALSE;
	return InferenceSubjects::is_within(subj->broader_than, larger);
}

@ Where possible, we use the above tests; where we need to perform other
operations scaling the subject tree, we use the following:

=
inference_subject *InferenceSubjects::narrowest_broader_subject(inference_subject *narrow) {
	if (narrow == NULL) return NULL;
	return narrow->broader_than;
}

@ The containment hierarchy is a fluid one, but subjects may only be demoted.
This means that any information derived from a subject's position relative to
other subjects, before the change, continues to be valid. If $S\subseteq T$
before, then this remains true afterwards.

=
void InferenceSubjects::falls_within(inference_subject *narrow, inference_subject *broad) {
	if (InferenceSubjects::is_within(broad, narrow->broader_than) == FALSE)
		internal_error("subject breadth change leads to inconsistency");
	narrow->broader_than = broad;
}

@h Access functions.

=
parse_node *InferenceSubjects::where_created(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	return infs->infs_created_at;
}

assemblies_data *InferenceSubjects::get_assemblies_data(inference_subject *infs) {
	if (infs == NULL) internal_error("tried to fetch assembly data for null subject");
	return &(infs->assemblies);
}

inference *InferenceSubjects::get_inferences(inference_subject *infs) {
	return (infs)?(infs->inf_list):NULL;
}

void InferenceSubjects::set_inferences(inference_subject *infs, inference *inf) {
	if (infs == NULL) internal_error("null INFS");
	infs->inf_list = inf;
}

implication *InferenceSubjects::get_implications(inference_subject *infs) {
	return infs->imp_list;
}

void InferenceSubjects::set_implications(inference_subject *infs, implication *imp) {
	infs->imp_list = imp;
}

property_permission **InferenceSubjects::get_permissions(inference_subject *infs) {
	return &(infs->permissions_list);
}

@h Conversions to and from kinds and instances.
Note that the following does not pick up variables (in the form of their lvalue
specifications) or relations (from their rvalue constants): it handles only
kinds and instances.

=
inference_subject *InferenceSubjects::from_specification(parse_node *spec) {
	inference_subject *infs = NULL;
	if (Specifications::is_kind_like(spec)) {
		kind *K = Specifications::to_kind(spec);
		infs = KindSubjects::from_kind(K);
	} else {
		instance *nc = Rvalues::to_instance(spec);
		if (nc) infs = Instances::as_subject(nc);
	}
	return infs;
}

@ And this amounts to a partial inverse of that function:

=
parse_node *InferenceSubjects::as_constant(inference_subject *infs) {
	kind *K = KindSubjects::to_kind(infs);
	if (K) return Specifications::from_kind(K);

	instance *nc = InstanceSubjects::to_instance(infs);
	if (nc) return Rvalues::from_instance(nc);

	return NULL;
}

@ ...and, because it makes conditions more legible,

=
int InferenceSubjects::is_an_object(inference_subject *infs) {
	if (InstanceSubjects::to_object_instance(infs)) return TRUE;
	return FALSE;
}
int InferenceSubjects::is_a_kind_of_object(inference_subject *infs) {
	if (infs) {
		kind *K = KindSubjects::to_kind(infs);
		if ((K) && (Kinds::Behaviour::is_subkind_of_object(K))) return TRUE;
	}
	return FALSE;
}

@h Logging.

=
void InferenceSubjects::log(inference_subject *infs) {
	if (infs == NULL) { LOG("<null infs>"); return; }
	if (infs->infs_name_in_log) { LOG("infs<%s>", infs->infs_name_in_log); return; }

	wording W = InferenceSubjects::get_name_text(infs);
	kind *K = KindSubjects::to_nonobject_kind(infs);
	if (K) { LOG("infs'%u'-k", K); return; }

	if (Wordings::nonempty(W)) { LOG("infs'%W'", W); return; }

	binary_predicate *bp = RelationSubjects::to_bp(infs);
	if (bp) { LOG("infs'%S'", BinaryPredicates::get_log_name(bp)); }

	LOG("infs%d", infs->allocation_id);
}

void InferenceSubjects::log_knowledge_about(inference_subject *infs) {
	inference *inf;
	LOG("Inferences drawn about $j:\n", infs); LOG_INDENT;
	for (inf = InferenceSubjects::get_inferences(infs); inf; inf = inf->next) LOG("$I\n", inf);
	LOG_OUTDENT;
}

@ The subjects hierarchy is unlikely to reach a depth of 20 except by a bug,
but that's exactly when we need the debugging log most, so the following is
coded to ensure that it terminates whether or not the subjects form a connected
DAG.

=
void InferenceSubjects::log_infs_hierarchy(void) {
	LOG("Subjects hierarchy:\n");
	InferenceSubjects::log_subjects_hierarchically(NULL, 0);
}

void InferenceSubjects::log_subjects_hierarchically(inference_subject *infs, int count) {
	if (count > 20) { LOG("*** Pruning: too deep ***\n"); return; }
	if (infs) LOG("$j\n", infs);
	inference_subject *narrower;
	LOOP_OVER(narrower, inference_subject)
		if (narrower->broader_than == infs) {
			LOG_INDENT;
			InferenceSubjects::log_subjects_hierarchically(narrower, count+1);
			LOG_OUTDENT;
		}
}

@h Methods.
The first of these should fill in a name, if one is available, placing the
word range into the wording.

@e GET_NAME_TEXT_INFS_MTID

=
VOID_METHOD_TYPE(GET_NAME_TEXT_INFS_MTID, inference_subject_family *f,
	inference_subject *infs, wording *W)

wording InferenceSubjects::get_name_text(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	wording W = EMPTY_WORDING;
	VOID_METHOD_CALL(infs->infs_family, GET_NAME_TEXT_INFS_MTID, infs, &W);
	LOOP_THROUGH_WORDING(i, W)
		if (Lexer::word(i) == STROKE_V) {
			W = Wordings::up_to(W, i-1);
			break;
		}
	return W;
}

@ The default certainty level is the level assumed in sentences which give
no specific certainty: so it affects "a window is open" but not "a window
is usually open". This depends on the subject rather than the inference,
and in general a subject which is broad will choose to reduce the default
level of certainty.

@e GET_DEFAULT_CERTAINTY_INFS_MTID

=
INT_METHOD_TYPE(GET_DEFAULT_CERTAINTY_INFS_MTID, inference_subject_family *f,
	inference_subject *infs)

int InferenceSubjects::get_default_certainty(inference_subject *infs) {
	int cert = CERTAIN_CE;
	INT_METHOD_CALL(cert, infs->infs_family, GET_DEFAULT_CERTAINTY_INFS_MTID, infs);
	return cert; 
}

@ In general property permissions work just as well whatever subject is getting
the new property, but the following is called to give the subject a chance to
react. It should return a general pointer to any extra data it wants to attach
to the permission, or |NULL_GENERAL_POINTER| if it has nothing to add.

@e NEW_PERMISSION_GRANTED_INFS_MTID

=
VOID_METHOD_TYPE(NEW_PERMISSION_GRANTED_INFS_MTID, inference_subject_family *f,
	inference_subject *infs, general_pointer *G)

general_pointer InferenceSubjects::new_permission_granted(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	general_pointer G = NULL_GENERAL_POINTER;
	VOID_METHOD_CALL(infs->infs_family, NEW_PERMISSION_GRANTED_INFS_MTID, infs, &G);
	return G;
}

@ Suppose there is an instance, such as "green", belonging to a kind of
value which coincides with a property of some subject. Then the following is
called to tell the subject in question that it needs to become the domain
of "green" as an adjective.

@e MAKE_ADJ_CONST_DOMAIN_INFS_MTID

=
VOID_METHOD_TYPE(MAKE_ADJ_CONST_DOMAIN_INFS_MTID, inference_subject_family *f,
	inference_subject *infs, instance *nc, property *prn)

void InferenceSubjects::make_adj_const_domain(inference_subject *infs,
	instance *nc, property *prn) {
	if (infs == NULL) internal_error("null INFS");
	VOID_METHOD_CALL(infs->infs_family, MAKE_ADJ_CONST_DOMAIN_INFS_MTID, infs, nc, prn);
}

@ Part of the process of "completing" the model -- that is, filling in detail
not spelled out explicitly in assertion sentences -- is to ask each subject
to fill in anything missing about itself:

@e COMPLETE_MODEL_INFS_MTID

=
VOID_METHOD_TYPE(COMPLETE_MODEL_INFS_MTID, inference_subject_family *f, inference_subject *infs)

void InferenceSubjects::complete_model(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	VOID_METHOD_CALL(infs->infs_family, COMPLETE_MODEL_INFS_MTID, infs);
}

@ Each subject also has a chance to check the knowledge about it for
consistency, and to issue problem messages if something is wrong:

@e CHECK_MODEL_INFS_MTID

=
VOID_METHOD_TYPE(CHECK_MODEL_INFS_MTID, inference_subject_family *f, inference_subject *infs)

void InferenceSubjects::check_model(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	VOID_METHOD_CALL(infs->infs_family, CHECK_MODEL_INFS_MTID, infs);
}

@ Here we must compile run-time code which tests whether the value in |t_0|
is a constant which the subject gives information about, given that we already
know it has the right atomic kind. (In some cases there will be nothing to
test -- if we know that |t_0| has kind "number" then it must be what we want.
But in the case of objects, we need to check |t_0| is not |nothing| and that
it has the right kind, and so on. If there's nothing to check, we leave the
condition blank.)

@e EMIT_ELEMENT_INFS_MTID

=
INT_METHOD_TYPE(EMIT_ELEMENT_INFS_MTID, inference_subject_family *f,
	inference_subject *infs, inter_symbol *t0_s)

void InferenceSubjects::emit_element_of_condition(inference_subject *infs,
	inter_symbol *t0_s) {
	if (infs == NULL) internal_error("null INFS");

	int written = FALSE;
	INT_METHOD_CALL(written, infs->infs_family, EMIT_ELEMENT_INFS_MTID, infs, t0_s);
	if (written == FALSE) {
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
	}
}

@ The model world needs to have its complex initial state stored somewhere
at run-time. Each subject may need its own data structure, and we want no
part of thinking about what it looks like.

@ |EMIT_ALL_INFS_MTID| has a chance to compile all its subjects at once,
which enables this to be done in a funny order or in some consolidated
array, or else have its subjects compiled one at a time in order of their
creation. |EMIT_ALL_INFS_MTID| should return |TRUE| to indicate the former
course. And otherwise, the method |EMIT_ONE_INFS_MTID| should do the job
for an individual subject.

@e EMIT_ALL_INFS_MTID
@e EMIT_ONE_INFS_MTID

=
INT_METHOD_TYPE(EMIT_ALL_INFS_MTID, inference_subject_family *f, int ignored)
VOID_METHOD_TYPE(EMIT_ONE_INFS_MTID, inference_subject_family *f, inference_subject *infs)

=
void InferenceSubjects::emit_all(void) {
	inference_subject *infs;

	LOOP_OVER(infs, inference_subject)
		World::Inferences::verify_prop_states(infs);

	inference_subject_family *family;
	LOOP_OVER(family, inference_subject_family) {
		int done = FALSE;
		INT_METHOD_CALL(done, family, EMIT_ALL_INFS_MTID, 0);
		if (done == FALSE) {
			inference_subject *infs;
			LOOP_OVER(infs, inference_subject)
				if (infs->infs_family == family) {
					VOID_METHOD_CALL(family, EMIT_ONE_INFS_MTID, infs);
				}
		}
	}
}

@h Plugin data.
See //runtime: Plugins//, but to recap, plugins are inessential components
of Inform which might or might not be in use for any given compilation run.

If a plugin is in use, it may need to attach data of its own to a subject,
and the following macro does that. |name| should be the name of the plugin,
say |spatial|; |creator| a function to create and initialise the data structure,
returning a pointer to it.

@d ATTACH_PLUGIN_DATA_TO_SUBJECT(name, S, val)
	(S)->additional_data_for_plugins[name##_plugin->allocation_id] = (void *) (val);

@ Then, to access that same data, the following -- though in practice each
plugin will define further macros to make more abbreviated forms. Many of
the plugins from the //if// module are concerned only with instances -- rooms
and doors, say -- so |PLUGIN_DATA_ON_INSTANCE| pays its way.

@d PLUGIN_DATA_ON_SUBJECT(name, S)
	((name##_data *) (S)->additional_data_for_plugins[name##_plugin->allocation_id])

@d PLUGIN_DATA_ON_INSTANCE(name, I)
	PLUGIN_DATA_ON_SUBJECT(name, Instances::as_subject(I))
