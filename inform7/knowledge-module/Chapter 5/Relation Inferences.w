[RelationInferences::] Relation Inferences.

Inferences that a relation holds between two subjects or values.

@ Relation inferences are made about a relation, and say that two other
subjects or values are related by it. Thus, if Charles "knows" Sebastian,
this fact is an inference about the knowledge relation, not about either
Charles or Sebastian, who are only the terms listed in its data.

= (early code)
inference_family *relation_inf = NULL;

@ =
void RelationInferences::start(void) {
	relation_inf = Inferences::new_family(I"relation_inf");
	METHOD_ADD(relation_inf, LOG_DETAILS_INF_MTID, RelationInferences::log_details);
	METHOD_ADD(relation_inf, COMPARE_INF_MTID, RelationInferences::cmp);
}

@ Terms can be given either as subjects or as arbitrary values. This was a late
change to Inform, which came in with dynamic relations between (say) numbers,
and therefore the need to set up an initial state for those relations.

The terms will either both be subjects, or both be values, so at all times
exactly one of these pairs of pointers is |NULL|.

=
typedef struct relation_inference_data {
	struct inference_subject *terms_as_subjects[2];
	struct parse_node *terms_as_values[2];
	CLASS_DEFINITION
} relation_inference_data;

inference *RelationInferences::new(inference_subject *subj0,
	inference_subject *subj1, parse_node *val0, parse_node *val1) {
	PROTECTED_MODEL_PROCEDURE;
	relation_inference_data *data = CREATE(relation_inference_data);
	data->terms_as_subjects[0] = InferenceSubjects::divert(subj0);
	data->terms_as_subjects[1] = InferenceSubjects::divert(subj1);
	data->terms_as_values[0] = val0;
	data->terms_as_values[1] = val1;
	return Inferences::create_inference(relation_inf,
		STORE_POINTER_relation_inference_data(data), prevailing_mood);
}

@ As promised, these are drawn using either subjects or values, but not both:

=
void RelationInferences::draw(binary_predicate *bp,
	inference_subject *subj0, inference_subject *subj1) {
	inference *i = RelationInferences::new(subj0, subj1, NULL, NULL);
	Inferences::join_inference(i, RelationSubjects::from_bp(bp));
}

void RelationInferences::draw_spec(binary_predicate *bp,
	parse_node *val0, parse_node *val1) {
	if ((val0 == NULL) || (val1 == NULL)) internal_error("malformed value relation");
	inference *i = RelationInferences::new(NULL, NULL, val0, val1);
	Inferences::join_inference(i, RelationSubjects::from_bp(bp));
}

@ And here are the method calls:

=
void RelationInferences::log_details(inference_family *f, inference *inf) {
	relation_inference_data *data = RETRIEVE_POINTER_relation_inference_data(inf->data);
	if (data->terms_as_subjects[0]) LOG("-1:$j", data->terms_as_subjects[0]);
	if (data->terms_as_subjects[1]) LOG("-2:$j", data->terms_as_subjects[1]);
	if (data->terms_as_values[0]) LOG("-s1:$P", data->terms_as_values[0]);
	if (data->terms_as_values[1]) LOG("-s2:$P", data->terms_as_values[1]);
}

@ Note that the topic of a relation inference depends on both terms. If
Charles knows Sebastian and Charles also knows Julia, then these two inferences
both belong to the knowledge relation, but "differ in topic", so that there
is no contradiction. If in fact the knowledge relation wants to make this a
one-to-one relationship, it will have to detect the contradiction of Charles
knowing both of them elsewhere: the inference machinery can't do so for it.

=
int RelationInferences::cmp(inference_family *f, inference *i1, inference *i2) {
	relation_inference_data *data1 = RETRIEVE_POINTER_relation_inference_data(i1->data);
	relation_inference_data *data2 = RETRIEVE_POINTER_relation_inference_data(i2->data);

	int c = Inferences::measure_infs(data1->terms_as_subjects[1]) -
			Inferences::measure_infs(data2->terms_as_subjects[1]);
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;
	c = Inferences::measure_infs(data1->terms_as_subjects[0]) -
		Inferences::measure_infs(data2->terms_as_subjects[0]);
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;
	c = Inferences::measure_pn(data1->terms_as_values[1]) -
		Inferences::measure_pn(data2->terms_as_values[1]);
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;
	c = Inferences::measure_pn(data1->terms_as_values[0]) -
		Inferences::measure_pn(data2->terms_as_values[0]);
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

@ And finally two access functions:

=
void RelationInferences::get_term_subjects(inference *i,
	inference_subject **subj1, inference_subject **infs2) {
	if ((i == NULL) || (i->family != relation_inf)) internal_error("not a relation inf");
	relation_inference_data *data = RETRIEVE_POINTER_relation_inference_data(i->data);
	if (subj1) *subj1 = data->terms_as_subjects[0];
	if (infs2) *infs2 = data->terms_as_subjects[1];
}

void RelationInferences::get_term_specs(inference *i,
	parse_node **val1, parse_node **spec2) {
	if ((i == NULL) || (i->family != relation_inf)) internal_error("not a relation inf");
	relation_inference_data *data = RETRIEVE_POINTER_relation_inference_data(i->data);
	if (val1) *val1 = data->terms_as_values[0];
	if (spec2) *spec2 = data->terms_as_values[1];
}
