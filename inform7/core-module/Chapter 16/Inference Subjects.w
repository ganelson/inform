[InferenceSubjects::] Inference Subjects.

The different data structures for elements of the model world are
all unified by a single concept, the inference subject, about which facts
can be known.

@ "Creating a program often means that you have to create a small
universe" (Donald Knuth).

Inform's model world is the collection of objects and values which
contingently rather than necessarily exist, together with their properties
and relations. A number such as 267 exists of necessity -- there would be
such a number whatever the source text had said, even if (as it turned out)
the compiled code never actually used it. But a room such as "The Great
Hall of Memphis", or a named value such as "aquamarine", need not exist.
Those are the stuff of the model.

As we have seen, the A-parser reduces assertion sentences in the source text
into logical propositions; these are then asserted in turn, reducing them
to a series of creations (such as that a ball exists) and a series of
inferences (such as that the ball is red). Inferences are elementary facts
about properties and relations, believed with different levels of certainty.

@ An "inference subject" is anything about which an inference can be drawn.
These subjects form a hierarchy. We say that I inherits from J if a fact about I
is necessarily also a fact about J, unless directly contradicted by specific
information about J. For example,

>> The plastic bag is a container. A container is usually opaque. The bag is transparent.

The inference subject for the bag inherits from that for the container, so
without that final sentence, the bag would have been opaque.

@ This is in effect a class with subclasses, but since we are using plain C
we indicate that with an enumeration of constants:

@d FUND_SUB 1 /* one of a few fixed and fundamental subjects (see below) */
@d KIND_SUB 2 /* a kind (number, thing, etc.) */
@d INST_SUB 3 /* an instance (specific objects, scenes, etc.) */
@d VARI_SUB 4 /* a non-local variable */
@d RELN_SUB 5 /* a binary predicate, i.e., a relation */

@d MAX_SUB 5 /* must be the largest of the values above */

@ Technically the hierarchy of inference subjects is a spaghetti stack, not a
tree: that is, all of the links run upwards to a common root (|model_world|).
There is no direct way to access the links downwards from any node -- in other
words, we often want to know what a given subject S inherits from, but we never
ask what other subjects inherit from S.

=
typedef struct inference_subject {
	int kind_of_infs; /* one of the |*_SUB| constants above */
	struct general_pointer represents; /* the individual instance, kind, etc. in question */
	struct parse_node *infs_created_at; /* which sentence created this */
	struct inference *inf_list; /* contingently true: inferences drawn about this subject */
	struct implication *imp_list; /* necessarily true: implications applying to this  */
	int default_certainty; /* by default, how certain are inferences about this? */
	struct property_permission *permissions_list; /* what properties this can have, if any */
	struct assemblies_data assemblies; /* what generalisations have been made about this? */
	struct inference_subject *broader_than; /* see below */
	char *infs_name_in_log; /* solely to make the debugging log more legible */
	struct nonlocal_variable *alias_variable; /* alias to this variable, like "yourself" to "player" */
	void *plugin_subj[MAX_PLUGINS];
	CLASS_DEFINITION
} inference_subject;

@ Recall that plugins are pieces of Inform which provide specialist additions
to the core language; to do this, they often need to attach further data to
(core) Inform's existing data structures. Once again, inference subjects provide
a convenient umbrella for things we're interested in; so we handle this by
allowing plugins to attach (suitably allocated) data structures to the ominous
|void *| slots in the structure above.

It's convenient to hide all of this by accessing the extra fields with the
macros below. Thus |PF_S(balloons, gas)| is the lvalue (and rvalue) for
the |gas| field added to the inference structure by |balloons_plugin|.
The variation |PF_I| is a shorthand to access the structure corresponding
to a given instance -- that's actually what we want, most of the time,
since a lot of the plugins are interested more in IF concepts like rooms,
containers and people than in anything else, and all of those objects
are instances.

@d PF_S(name, S)
	((name##_data *) S->plugin_subj[name##_plugin->allocation_id])

@d PF_I(name, I)
	((name##_data *) (Instances::as_subject(I))->plugin_subj[name##_plugin->allocation_id])

@d CREATE_PF_DATA(name, S, creator)
	(S)->plugin_subj[name##_plugin->allocation_id] = (void *) (creator(S));

@ The top of the inference hierarchy contains a number of "fundamental" subjects.
Thus we have:
= (text)
	model_world
	    nonlocal_variables
	        ...all individual globals
	    global_constants
	        ...all kinds, including:
	        K_object
	            K_thing
	                K_container
	                ...
	            K_room
	            ...
=
(Note that objects appear within the hierarchy of values, rather than alongside
it, as in the class hierarchies of languages like Scala.)

For instance, by giving |nonlocal_variables| permission to have the "initial
value" property, we immediately grant the same to every global variable, by
inheritance.

Inheritance forms a directed acyclic graph with |model_world| as the root.

= (early code)
inference_subject *model_world = NULL;
inference_subject *nonlocal_variables = NULL;
inference_subject *global_constants = NULL;
inference_subject *relations = NULL;

@h The fundamentals.
At the start of Inform's run, the subject tree consists only of the
following.

=
void InferenceSubjects::make_built_in(void) {
	model_world = InferenceSubjects::new_fundamental(NULL, "model-world");
	nonlocal_variables = InferenceSubjects::new_fundamental(model_world, "global-variables");
	global_constants = InferenceSubjects::new_fundamental(model_world, "global-constants");
	relations = InferenceSubjects::new_fundamental(model_world, "relations");
	Plugins::Call::create_inference_subjects();
}

inference_subject *InferenceSubjects::new_fundamental(inference_subject *from, char *lname) {
	inference_subject *infs = CREATE(inference_subject);
	InferenceSubjects::infs_initialise(infs, NULL_GENERAL_POINTER, FUND_SUB, LIKELY_CE, from, lname);
	return infs;
}

@h Creation.
Other inference subjects are added during the run, thus:

=
inference_subject *InferenceSubjects::new(inference_subject *from, int KOI,
	general_pointer gp, int cert) {
	inference_subject *infs = CREATE(inference_subject);
	InferenceSubjects::infs_initialise(infs, gp, KOI, cert, from, NULL);
	return infs;
}

@ Either means of creation uses the following:

=
int no_roots = 0;
void InferenceSubjects::infs_initialise(inference_subject *infs,
	general_pointer gp, int KOI, int cert, inference_subject *from, char *lname) {
	if ((from == NULL) && (++no_roots > 1)) {
		InferenceSubjects::log_infs_hierarchy();
		internal_error("subject tree now disconnected");
	}
	if (from == infs) internal_error("made sub-subject of itself");
	infs->infs_created_at = current_sentence;
	infs->represents = gp;
	infs->kind_of_infs = KOI;
	infs->inf_list = NULL;
	infs->imp_list = NULL;
	infs->broader_than = from;
	infs->default_certainty = cert;
	infs->permissions_list = NULL;
	infs->infs_name_in_log = lname;
	infs->alias_variable = NULL;
	Assertions::Assemblies::initialise_assemblies_data(&(infs->assemblies));
	int i;
	for (i=0; i<MAX_PLUGINS; i++) infs->plugin_subj[i] = NULL;
	Plugins::Call::new_subject_notify(infs);
}

@ Renewal is needed to solve a timing problem early in Inform's run, since
subjects for spatial kinds like "room" are needed before the kinds themselves
can be made. Abusing this routine could clearly violate the rule that the
subject tree must remain a connected DAG, so we don't abuse it.

=
void InferenceSubjects::renew(inference_subject *infs,
	inference_subject *from, int KOI, general_pointer gp, int cert) {
	InferenceSubjects::infs_initialise(infs, gp, KOI, cert, from, NULL);
}

@h Aliasing.
This is explained in the "The Player" plugin, which is the only place where
it's needed at present.

=
void InferenceSubjects::alias_to_nonlocal_variable(inference_subject *infs, nonlocal_variable *q) {
	infs->alias_variable = q;
}

int InferenceSubjects::aliased_but_diverted(inference_subject *infs) {
	if (infs->alias_variable) {
		inference_subject *vs =
			Instances::as_subject(
				Rvalues::to_object_instance(
					NonlocalVariables::get_initial_value(
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

@ Now access to the knowledge we possess about subjects, all of which is
read and written from specialist sections of Inform rather than here.

=
parse_node *InferenceSubjects::where_created(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	return infs->infs_created_at;
}

int InferenceSubjects::get_default_certainty(inference_subject *infs) {
	return infs->default_certainty;
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

@ Forward conversions.
Suppose we have a constant value, or more generally, a specification. Does this
correspond to a subject, and if so, which one?

=
inference_subject *InferenceSubjects::from_specification(parse_node *spec) {
	inference_subject *infs = NULL;

	if (Specifications::is_kind_like(spec)) {
		kind *K = Specifications::to_kind(spec);
		infs = Kinds::Knowledge::as_subject(K);
	} else {
		instance *I = Rvalues::to_object_instance(spec);
		if (I) infs = Instances::as_subject(I);
		else {
			instance *nc = Rvalues::to_instance(spec);
			if (nc) infs = Instances::as_subject(nc);
		}
	}
	return infs;
}

@h Back conversions.
In the end subjects are, in part, wrappers to unify a range of other data
structures, and sometimes we want to tear off the wrapper. The following is
almost the inverse of the function above -- for inference subjects or for
specifications they correspond to, they are indeed inverses; for other
specifications, forward conversion returns |NULL| and the question doesn't
arise.

=
parse_node *InferenceSubjects::as_constant(inference_subject *infs) {
	kind *K = InferenceSubjects::domain(infs);
	if (K) return Specifications::from_kind(K);

	instance *I = InferenceSubjects::as_object_instance(infs);
	if (I) return Rvalues::from_instance(I);

	instance *nc = InferenceSubjects::as_nc(infs);
	if (nc) return Rvalues::from_instance(nc);

	return NULL;
}

@ More prosaically:

=
instance *InferenceSubjects::as_instance(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == INST_SUB)) {
		instance *nc = RETRIEVE_POINTER_instance(infs->represents);
		return nc;
	}
	return NULL;
}

instance *InferenceSubjects::as_object_instance(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == INST_SUB)) {
		instance *nc = RETRIEVE_POINTER_instance(infs->represents);
		if (Kinds::Behaviour::is_object(Instances::to_kind(nc)))
			return nc;
	}
	return NULL;
}

kind *InferenceSubjects::as_nonobject_kind(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == KIND_SUB)) {
		kind *K = Kinds::base_construction(
			RETRIEVE_POINTER_kind_constructor(infs->represents));
		if (Kinds::Compare::lt(K, K_object)) return NULL;
		return K;
	}
	return NULL;
}

kind *InferenceSubjects::as_kind(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == KIND_SUB)) {
		kind *K = Kinds::base_construction(
				RETRIEVE_POINTER_kind_constructor(infs->represents));
		return K;
	}
	return NULL;
}

nonlocal_variable *InferenceSubjects::as_nlv(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == VARI_SUB))
		return RETRIEVE_POINTER_nonlocal_variable(infs->represents);
	return NULL;
}

binary_predicate *InferenceSubjects::as_bp(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == RELN_SUB))
		return RETRIEVE_POINTER_binary_predicate(infs->represents);
	return NULL;
}

instance *InferenceSubjects::as_nc(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == INST_SUB))
		return RETRIEVE_POINTER_instance(infs->represents);
	return NULL;
}

@ ...and, because it makes conditions more legible,

=
int InferenceSubjects::is_an_object(inference_subject *infs) {
	if (InferenceSubjects::as_object_instance(infs)) return TRUE;
	return FALSE;
}
int InferenceSubjects::is_a_kind_of_object(inference_subject *infs) {
	if ((infs) && (infs->kind_of_infs == KIND_SUB)) {
		kind *K = Kinds::base_construction(
			RETRIEVE_POINTER_kind_constructor(infs->represents));
		if (Kinds::Compare::lt(K, K_object)) return TRUE;
	}
	return FALSE;
}

@ Finally, just as subjects can represent individual values, so they can
also represent collections of values. (At present, though, only the subjects
from kinds actually do.)

=
kind *InferenceSubjects::domain(inference_subject *infs) {
	return InferenceSubjects::as_kind(infs);
}

@h Logging.

=
void InferenceSubjects::log(inference_subject *infs) {
	if (infs == NULL) { LOG("<null infs>"); return; }
	if (infs->infs_name_in_log) { LOG("infs<%s>", infs->infs_name_in_log); return; }

	wording W = InferenceSubjects::get_name_text(infs);
	kind *K = InferenceSubjects::as_nonobject_kind(infs);
	if (K) { LOG("infs'%u'-k", K); return; }

	if (Wordings::nonempty(W)) { LOG("infs'%W'", W); return; }

	binary_predicate *bp = InferenceSubjects::as_bp(infs);
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
word range into the variables pointed to by |w1| and |w2|.

=
wording InferenceSubjects::get_name_text(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	wording W = EMPTY_WORDING;
	switch (infs->kind_of_infs) {
		case FUND_SUB: break;
		case KIND_SUB: W = Kinds::Knowledge::get_name_text(infs); break;
		case INST_SUB: W = Instances::SUBJ_get_name_text(infs); break;
		case VARI_SUB: W = NonlocalVariables::SUBJ_get_name_text(infs); break;
		case RELN_SUB: W = BinaryPredicates::SUBJ_get_name_text(infs); break;
	}
	LOOP_THROUGH_WORDING(i, W)
		if (Lexer::word(i) == STROKE_V) {
			W = Wordings::up_to(W, i-1);
			break;
		}
	return W;
}

@ In general property permissions work just as well whatever subject is getting
the new property, but the following is called to give the subject a chance to
react. It should return a general pointer to any extra data it wants to attach
to the permission, or |NULL_GENERAL_POINTER| if it has nothing to add.

=
general_pointer InferenceSubjects::new_permission_granted(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	switch (infs->kind_of_infs) {
		case FUND_SUB: break;
		case KIND_SUB: return Kinds::Knowledge::new_permission_granted(infs);
		case INST_SUB: return Instances::SUBJ_new_permission_granted(infs);
		case VARI_SUB: return NonlocalVariables::SUBJ_new_permission_granted(infs);
		case RELN_SUB: return BinaryPredicates::SUBJ_new_permission_granted(infs);
	}
	return NULL_GENERAL_POINTER;
}

@ Suppose there is an instance, such as "green", belonging to a kind of
value which coincides with a property of some subject. Then the following is
called to tell the subject in question that it needs to become the domain
of "green" as an adjective.

=
void InferenceSubjects::make_adj_const_domain(inference_subject *infs,
	instance *nc, property *prn) {
	if (infs == NULL) internal_error("null INFS");
	switch (infs->kind_of_infs) {
		case FUND_SUB: break;
		case KIND_SUB: Kinds::Knowledge::make_adj_const_domain(infs, nc, prn); break;
		case INST_SUB: Instances::SUBJ_make_adj_const_domain(infs, nc, prn); break;
		case VARI_SUB: NonlocalVariables::SUBJ_make_adj_const_domain(infs, nc, prn); break;
		case RELN_SUB: BinaryPredicates::SUBJ_make_adj_const_domain(infs, nc, prn); break;
	}
}

@ Part of the process of "completing" the model -- that is, filling in detail
not spelled out explicitly in assertion sentences -- is to ask each subject
to fill in anything missing about itself:

=
void InferenceSubjects::complete_model(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	switch (infs->kind_of_infs) {
		case FUND_SUB: break;
		case KIND_SUB: Kinds::Knowledge::complete_model(infs); break;
		case INST_SUB: Instances::SUBJ_complete_model(infs); break;
		case VARI_SUB: NonlocalVariables::SUBJ_complete_model(infs); break;
		case RELN_SUB: BinaryPredicates::SUBJ_complete_model(infs); break;
	}
}

@ Each subject also has a chance to check the knowledge about it for
consistency, and to issue problem messages if something is wrong:

=
void InferenceSubjects::check_model(inference_subject *infs) {
	if (infs == NULL) internal_error("null INFS");
	switch (infs->kind_of_infs) {
		case FUND_SUB: break;
		case KIND_SUB: Kinds::Knowledge::check_model(infs); break;
		case INST_SUB: Instances::SUBJ_check_model(infs); break;
		case VARI_SUB: NonlocalVariables::SUBJ_check_model(infs); break;
		case RELN_SUB: BinaryPredicates::SUBJ_check_model(infs); break;
	}
}

@ Here we must compile run-time code which tests whether the value in |t_0|
is a constant which the subject gives information about, given that we already
know it has the right atomic kind. (In some cases there will be nothing to
test -- if we know that |t_0| has kind "number" then it must be what we want.
But in the case of objects, we need to check |t_0| is not |nothing| and that
it has the right kind, and so on. If there's nothing to check, we leave the
condition blank.)

=
void InferenceSubjects::emit_element_of_condition(inference_subject *infs, inter_symbol *t0_s) {
	if (infs == NULL) internal_error("null INFS");

	int written = FALSE;
	switch (infs->kind_of_infs) {
		case FUND_SUB: break;
		case KIND_SUB: written = Kinds::Knowledge::emit_element_of_condition(infs, t0_s); break;
		case INST_SUB: written = Instances::SUBJ_emit_element_of_condition(infs, t0_s); break;
		case VARI_SUB: written = NonlocalVariables::SUBJ_emit_element_of_condition(infs, t0_s); break;
		case RELN_SUB: written = BinaryPredicates::SUBJ_emit_element_of_condition(infs, t0_s); break;
	}
	if (written == FALSE) {
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
	}
}

@ The model world needs to have its complex initial state stored somewhere
at run-time. Each subject may need its own data structure, and we want no
part of thinking about what it looks like.

Each kind of subject has a chance to compile all its subjects at once,
which enables this to be done in a funny order or in some consolidated
array, or else have its subjects compiled one at a time in order of their
creation. |compile_all| should return |TRUE| to indicate the former course.

=
void InferenceSubjects::compile_all(void) {
	inference_subject *infs;

	LOOP_OVER(infs, inference_subject)
		World::Inferences::verify_prop_states(infs);

	int koi;
	for (koi=1; koi<=MAX_SUB; koi++) {
		int done = FALSE;
		switch (koi) {
			case FUND_SUB: break;
			case KIND_SUB: done = Kinds::Knowledge::emit_all(); break;
			case INST_SUB: done = Instances::SUBJ_compile_all(); break;
			case VARI_SUB: done = NonlocalVariables::SUBJ_compile_all(); break;
			case RELN_SUB: done = BinaryPredicates::SUBJ_compile_all(); break;
		}
		if (done) continue;
		inference_subject *infs;
		LOOP_OVER(infs, inference_subject)
			if (infs->kind_of_infs == koi) {
				switch (infs->kind_of_infs) {
					case FUND_SUB: break;
					case KIND_SUB: Kinds::Knowledge::emit(infs); break;
					case INST_SUB: Instances::SUBJ_compile(infs); break;
					case VARI_SUB: NonlocalVariables::SUBJ_compile(infs); break;
					case RELN_SUB: BinaryPredicates::SUBJ_compile(infs); break;
				}
			}
	}
}
