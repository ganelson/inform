[RelationInferences::] Relation Inferences.

Inferences that a relation holds between two subjects or values.

@ We will make:

= (early code)
inference_family *arbitrary_relation_inf = NULL;

@

=
void RelationInferences::start(void) {
	arbitrary_relation_inf = Inferences::new_family(I"arbitrary_relation_inf");
	METHOD_ADD(arbitrary_relation_inf, LOG_DETAILS_INF_MTID, RelationInferences::log);
	METHOD_ADD(arbitrary_relation_inf, COMPARE_INF_MTID, RelationInferences::cmp);
}

typedef struct relation_inference_data {
	struct inference_subject *terms_as_subjects[2];
	struct parse_node *terms_as_values[2];
	CLASS_DEFINITION
} relation_inference_data;

inference *RelationInferences::new(inference_subject *infs0,
	inference_subject *infs1, parse_node *spec0, parse_node *spec1) {
	PROTECTED_MODEL_PROCEDURE;
	relation_inference_data *data = CREATE(relation_inference_data);
	data->terms_as_subjects[0] = InferenceSubjects::divert(infs0);
	data->terms_as_subjects[1] = InferenceSubjects::divert(infs1);
	data->terms_as_values[0] = spec0;
	data->terms_as_values[1] = spec1;
	return Inferences::create_inference(arbitrary_relation_inf,
		STORE_POINTER_relation_inference_data(data), prevailing_mood);
}

void RelationInferences::get_term_subjects(inference *i,
	inference_subject **infs1, inference_subject **infs2) {
	if ((i == NULL) || (i->family != arbitrary_relation_inf))
		internal_error("not a relation inf");
	relation_inference_data *data = RETRIEVE_POINTER_relation_inference_data(i->data);
	if (infs1) *infs1 = data->terms_as_subjects[0];
	if (infs2) *infs2 = data->terms_as_subjects[1];
}

void RelationInferences::get_term_specs(inference *i,
	parse_node **spec1, parse_node **spec2) {
	if ((i == NULL) || (i->family != arbitrary_relation_inf))
		internal_error("not a relation inf");
	relation_inference_data *data = RETRIEVE_POINTER_relation_inference_data(i->data);
	if (spec1) *spec1 = data->terms_as_values[0];
	if (spec2) *spec2 = data->terms_as_values[1];
}

void RelationInferences::log(inference_family *f, inference *inf) {
	relation_inference_data *data = RETRIEVE_POINTER_relation_inference_data(inf->data);
	if (data->terms_as_subjects[0]) LOG("-1:$j", data->terms_as_subjects[0]);
	if (data->terms_as_subjects[1]) LOG("-2:$j", data->terms_as_subjects[1]);
	if (data->terms_as_values[0]) LOG("-s1:$P", data->terms_as_values[0]);
	if (data->terms_as_values[1]) LOG("-s2:$P", data->terms_as_values[1]);
}

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

void RelationInferences::draw(binary_predicate *bp,
	inference_subject *infs0, inference_subject *infs1) {
	inference *i = RelationInferences::new(infs0, infs1, NULL, NULL);
	Inferences::join_inference(i, RelationSubjects::from_bp(bp));
}

void RelationInferences::draw_spec(binary_predicate *bp,
	parse_node *spec0, parse_node *spec1) {
	if ((spec0 == NULL) || (spec1 == NULL)) internal_error("malformed value relation");
	inference *i = RelationInferences::new(NULL, NULL, spec0, spec1);
	Inferences::join_inference(i, RelationSubjects::from_bp(bp));
}
