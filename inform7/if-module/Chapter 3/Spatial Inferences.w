[SpatialInferences::] Spatial Inferences.

Six families of inference used by the spatial feature.

@ Spatial has no fewer than six of its own inference families, needed to store vague
indications of spatial structure:

= (early code)
inference_family *is_room_inf = NULL;           /* is O a room? */
inference_family *contains_things_inf = NULL;   /* does O contain things? */
inference_family *parentage_inf = NULL;         /* where is O located? */
inference_family *parentage_here_inf = NULL;    /* located vaguely as "here"? */
inference_family *parentage_nowhere_inf = NULL; /* located vaguely as "nowhere"? */
inference_family *part_of_inf = NULL;           /* is O a part of another object? */

@ =
void SpatialInferences::create(void) {
	is_room_inf = Inferences::new_family(I"is_room_inf");
	METHOD_ADD(is_room_inf, EXPLAIN_CONTRADICTION_INF_MTID,
		SpatialInferences::is_room_explain_contradiction);

	contains_things_inf = Inferences::new_family(I"contains_things_inf");

	parentage_inf = Inferences::new_family(I"parentage_inf");
	METHOD_ADD(parentage_inf, LOG_DETAILS_INF_MTID, SpatialInferences::log_parentage_inf);
	METHOD_ADD(parentage_inf, COMPARE_INF_MTID, SpatialInferences::cmp_parentage_inf);
	METHOD_ADD(parentage_inf, EXPLAIN_CONTRADICTION_INF_MTID,
		SpatialInferences::parentage_explain_contradiction);

	parentage_here_inf = Inferences::new_family(I"parentage_here_inf");
	METHOD_ADD(parentage_here_inf, LOG_DETAILS_INF_MTID, SpatialInferences::log_parentage_here);
	METHOD_ADD(parentage_here_inf, COMPARE_INF_MTID, SpatialInferences::cmp_parentage_here);

	parentage_nowhere_inf = Inferences::new_family(I"parentage_nowhere_inf");

	part_of_inf = Inferences::new_family(I"part_of_inf");
	METHOD_ADD(part_of_inf, LOG_DETAILS_INF_MTID, SpatialInferences::log_part_of);
	METHOD_ADD(part_of_inf, COMPARE_INF_MTID, SpatialInferences::cmp_part_of);
}

@ Details for |is_room_inf|:

=
void SpatialInferences::infer_is_room(inference_subject *R, int certitude) {
	Inferences::join_inference(
		Inferences::create_inference(is_room_inf, NULL_GENERAL_POINTER, certitude), R);
}

int SpatialInferences::is_room_explain_contradiction(inference_family *f, inference *A,
	inference *B, int similarity, inference_subject *subj) {
	StandardProblems::two_sentences_problem(_p_(PM_WhenIsARoomNotARoom),
		A->inferred_from,
		"this looks like a contradiction",
		"because apparently something would have to be both a room and not a "
		"room at the same time.");
	return TRUE;
}

@ Details for |contains_things_inf|:

=
void SpatialInferences::infer_contains_things(inference_subject *R, int certitude) {
	Inferences::join_inference(
		Inferences::create_inference(contains_things_inf,
			NULL_GENERAL_POINTER, certitude), R);
}

@ Details for |parentage_inf|:

=
typedef struct parentage_inference_data {
	struct inference_subject *parent;
	CLASS_DEFINITION	
} parentage_inference_data;

void SpatialInferences::infer_parentage(inference_subject *inner, int certitude,
	inference_subject *outer) {
	parentage_inference_data *data = CREATE(parentage_inference_data);
	data->parent = InferenceSubjects::divert(outer);
	inference *i = Inferences::create_inference(parentage_inf,
		STORE_POINTER_parentage_inference_data(data), certitude);
	Inferences::join_inference(i, inner);
}

void SpatialInferences::log_parentage_inf(inference_family *f, inference *inf) {
	parentage_inference_data *data = RETRIEVE_POINTER_parentage_inference_data(inf->data);
	if (data->parent) LOG(" parent:$j", data->parent);
}

int SpatialInferences::cmp_parentage_inf(inference_family *f, inference *i1, inference *i2) {
	parentage_inference_data *data1 = RETRIEVE_POINTER_parentage_inference_data(i1->data);
	parentage_inference_data *data2 = RETRIEVE_POINTER_parentage_inference_data(i2->data);

	int c = Inferences::measure_infs(data1->parent) -
			Inferences::measure_infs(data2->parent);
	if (c > 0) return CI_DIFFER_IN_CONTENT; if (c < 0) return -CI_DIFFER_IN_CONTENT;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

int SpatialInferences::parentage_explain_contradiction(inference_family *f, inference *A,
	inference *B, int similarity, inference_subject *subj) {
	if (SpatialInferences::get_inferred_progenitor(A) !=
		SpatialInferences::get_inferred_progenitor(B)) {
		Problems::quote_source(1, Inferences::where_inferred(A));
		Problems::quote_source(2, Inferences::where_inferred(B));
		Problems::quote_subject(3, subj);
		Problems::quote_object(4, SpatialInferences::get_inferred_progenitor(A));
		Problems::quote_object(5, SpatialInferences::get_inferred_progenitor(B));
		StandardProblems::handmade_problem(Task::syntax_tree(),
			_p_(PM_SpatialContradiction));
		Problems::issue_problem_segment(
			"You wrote %1, but also %2: that seems to be saying that the same "
			"object (%3) must be in two different places (%4 and %5). This "
			"looks like a contradiction. %P"
			"This sometimes happens as a result of a sentence like 'Every person "
			"carries a bag', when Inform doesn't know 'bag' as the name of any "
			"kind - so that it makes only a single thing called 'bag', and then "
			"the sentence looks as if it says everyone is carrying the same bag.");
		Problems::issue_problem_end();
		return TRUE;
	}
	return FALSE;
}

@ Details for |parentage_here_inf|:

=
typedef struct parentage_here_inference_data {
	struct inference_subject *parent;
	CLASS_DEFINITION	
} parentage_here_inference_data;

void SpatialInferences::infer_parentage_here(inference_subject *inner, int certitude,
	inference_subject *outer) {
	parentage_here_inference_data *data = CREATE(parentage_here_inference_data);
	data->parent = InferenceSubjects::divert(outer);
	inference *i = Inferences::create_inference(parentage_here_inf,
		STORE_POINTER_parentage_here_inference_data(data), certitude);
	Inferences::join_inference(i, inner);
}

void SpatialInferences::log_parentage_here(inference_family *f, inference *inf) {
	parentage_here_inference_data *data =
		RETRIEVE_POINTER_parentage_here_inference_data(inf->data);
	if (data->parent) LOG(" parent:$j", data->parent);
}

int SpatialInferences::cmp_parentage_here(inference_family *f, inference *i1,
	inference *i2) {
	parentage_here_inference_data *data1 =
		RETRIEVE_POINTER_parentage_here_inference_data(i1->data);
	parentage_here_inference_data *data2 =
		RETRIEVE_POINTER_parentage_here_inference_data(i2->data);

	int c = Inferences::measure_infs(data1->parent) -
			Inferences::measure_infs(data2->parent);
	if (c > 0) return CI_DIFFER_IN_CONTENT; if (c < 0) return -CI_DIFFER_IN_CONTENT;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

@ Details for |parentage_nowhere_inf|:

=
void SpatialInferences::infer_is_nowhere(inference_subject *R, int certitude) {
	Inferences::join_inference(Inferences::create_inference(parentage_nowhere_inf,
		NULL_GENERAL_POINTER, certitude), R);
}

@ Details for |part_of_inf|:

=
void SpatialInferences::infer_part_of(inference_subject *inner, int certitude,
	inference_subject *outer) {
	part_of_inference_data *data = CREATE(part_of_inference_data);
	data->parent = InferenceSubjects::divert(outer);
	inference *i = Inferences::create_inference(part_of_inf,
		STORE_POINTER_part_of_inference_data(data), certitude);
	Inferences::join_inference(i, inner);
}

typedef struct part_of_inference_data {
	struct inference_subject *parent;
	CLASS_DEFINITION	
} part_of_inference_data;


void SpatialInferences::log_part_of(inference_family *f, inference *inf) {
	part_of_inference_data *data = RETRIEVE_POINTER_part_of_inference_data(inf->data);
	if (data->parent) LOG(" part-of:$j", data->parent);
}

int SpatialInferences::cmp_part_of(inference_family *f, inference *i1, inference *i2) {
	part_of_inference_data *data1 = RETRIEVE_POINTER_part_of_inference_data(i1->data);
	part_of_inference_data *data2 = RETRIEVE_POINTER_part_of_inference_data(i2->data);

	int c = Inferences::measure_infs(data1->parent) -
			Inferences::measure_infs(data2->parent);
	if (c > 0) return CI_DIFFER_IN_CONTENT; if (c < 0) return -CI_DIFFER_IN_CONTENT;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

@ Several of those inferences suggest a progenitor, so it's useful to have a
single function to return this:

=
instance *SpatialInferences::get_inferred_progenitor(inference *inf) {
	if (inf->family == parentage_inf) {
		parentage_inference_data *data =
			RETRIEVE_POINTER_parentage_inference_data(inf->data);
		return InstanceSubjects::to_object_instance(data->parent);
	}
	if (inf->family == parentage_here_inf) {
		parentage_here_inference_data *data =
			RETRIEVE_POINTER_parentage_here_inference_data(inf->data);
		return InstanceSubjects::to_object_instance(data->parent);
	}
	if (inf->family == part_of_inf) {
		part_of_inference_data *data =
			RETRIEVE_POINTER_part_of_inference_data(inf->data);
		return InstanceSubjects::to_object_instance(data->parent);
	}
	return NULL;
}
