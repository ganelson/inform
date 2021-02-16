[PropertyInferences::] Property Inferences.

Inferences that a property of something is true, or has a particular value.

@ We will make:

= (early code)
inference_family *property_inf = NULL;

@

=
void PropertyInferences::start(void) {
	property_inf = Inferences::new_family(I"property_inf", CI_DIFFER_IN_PROPERTY_VALUE);
	METHOD_ADD(property_inf, LOG_INF_MTID, PropertyInferences::log);
	METHOD_ADD(property_inf, COMPARE_INF_MTID, PropertyInferences::cmp);
	METHOD_ADD(property_inf, JOIN_INF_MTID, PropertyInferences::join);
	METHOD_ADD(property_inf, EXPLAIN_CONTRADICTION_INF_MTID, PropertyInferences::explain_contradiction);
}

void PropertyInferences::join(inference_family *f, inference *inf, inference_subject *infs) {
	property_inference_data *data = RETRIEVE_POINTER_property_inference_data(inf->data);
	Plugins::Call::property_value_notify(
		data->inferred_property, data->inferred_property_value);
}

int PropertyInferences::cmp(inference_family *f, inference *i1, inference *i2) {
	property_inference_data *data1 = RETRIEVE_POINTER_property_inference_data(i1->data);
	property_inference_data *data2 = RETRIEVE_POINTER_property_inference_data(i2->data);
	property *pr1 = data1->inferred_property;
	property *pr2 = data2->inferred_property;
	if ((pr1) && (Properties::is_either_or(pr1)) &&
		(pr2) && (Properties::is_either_or(pr2)) &&
		((pr1 == Properties::EitherOr::get_negation(pr2)) ||
		 (pr2 == Properties::EitherOr::get_negation(pr1)))) pr2 = pr1;
	int c = Inferences::measure_property(pr1) - Inferences::measure_property(pr2);
	if (c > 0) return CI_DIFFER_IN_PROPERTY; if (c < 0) return -CI_DIFFER_IN_PROPERTY;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);

	parse_node *val1 = data1->inferred_property_value;
	parse_node *val2 = data2->inferred_property_value;
	if ((data1->inferred_property != data2->inferred_property) || /* in case they are an either-or pair */
		((val1) && (val2) && (Rvalues::compare_CONSTANT(val1, val2) == FALSE))) {
		if (c > 0) return CI_DIFFER_IN_PROPERTY_VALUE;
		if (c < 0) return -CI_DIFFER_IN_PROPERTY_VALUE;
	}

	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

int PropertyInferences::explain_contradiction(inference_family *f, inference *A,
	inference *B, int similarity, inference_subject *subj) {
	property_inference_data *A_data = RETRIEVE_POINTER_property_inference_data(A->data);
	property_inference_data *B_data = RETRIEVE_POINTER_property_inference_data(B->data);
	if (B_data->inferred_property == P_variable_initial_value) {
		StandardProblems::two_sentences_problem(_p_(PM_VariableContradiction),
			A->inferred_from,
			"this looks like a contradiction",
			"because the initial value of this variable seems to be being set "
			"in each of these sentences, but with a different outcome.");
	} else {
		if (Properties::is_value_property(B_data->inferred_property)) {
			binary_predicate *bp =
				Properties::Valued::get_stored_relation(B_data->inferred_property);
			if (bp) {
				if (Wordings::match(Node::get_text(current_sentence),
					Node::get_text(A->inferred_from))) {
					Problems::quote_source(1, current_sentence);
					Problems::quote_relation(3, bp);
					Problems::quote_subject(4, subj);
					Problems::quote_spec(5, B_data->inferred_property_value);
					Problems::quote_spec(6, A_data->inferred_property_value);
					StandardProblems::handmade_problem(Task::syntax_tree(),
						_p_(PM_RelationContradiction2));
					Problems::issue_problem_segment(
						"I'm finding a contradiction at the sentence %1, "
						"because it means I can't set up %3. "
						"On the one hand, %4 should relate to %5, but on the other "
						"hand to %6, and this is a relation which doesn't allow "
						"such clashes.");
					Problems::issue_problem_end();
				} else {
					Problems::quote_source(1, current_sentence);
					Problems::quote_source(2, A->inferred_from);
					Problems::quote_relation(3, bp);
					Problems::quote_subject(4, subj);
					Problems::quote_spec(5, B_data->inferred_property_value);
					Problems::quote_spec(6, A_data->inferred_property_value);
					StandardProblems::handmade_problem(Task::syntax_tree(),
						_p_(PM_RelationContradiction));
					Problems::issue_problem_segment(
						"I'm finding a contradiction at the sentences %1 and %2, "
						"because between them they set up rival versions of %3. "
						"On the one hand, %4 should relate to %5, but on the other "
						"hand to %6, and this is a relation which doesn't allow "
						"such clashes.");
					Problems::issue_problem_end();
				}
				return TRUE;
			}
		}
		StandardProblems::two_sentences_problem(_p_(PM_PropertyContradiction),
			A->inferred_from,
			"this looks like a contradiction",
			"because the same property seems to be being set in each of these sentences, "
			"but with a different outcome.");
	}
	return TRUE;
}

void PropertyInferences::log(inference_family *f, inference *inf) {
	property_inference_data *data = RETRIEVE_POINTER_property_inference_data(inf->data);
	LOG("(%W)", data->inferred_property->name);
	if (data->inferred_property_value) LOG(":=$P", data->inferred_property_value);
}

typedef struct property_inference_data {
	struct property *inferred_property; /* property referred to, if any */
	struct parse_node *inferred_property_value; /* and its value, if any */	
	CLASS_DEFINITION
} property_inference_data;

inference *PropertyInferences::new(inference_subject *infs,
	property *prn, parse_node *val) {
	PROTECTED_MODEL_PROCEDURE;
	if (prn == NULL) internal_error("null property inference");

	property_inference_data *data = CREATE(property_inference_data);
	data->inferred_property = prn;
	data->inferred_property_value = val;
	int c = prevailing_mood;
	if (c == UNKNOWN_CE) c = InferenceSubjects::get_default_certainty(infs);
	inference *i = Inferences::create_inference(property_inf,
		STORE_POINTER_property_inference_data(data), c);
	return i;
}

void PropertyInferences::draw(inference_subject *infs, property *prn, parse_node *val) {
	inference *i = PropertyInferences::new(infs, prn, val);
	Inferences::join_inference(i, infs);
}

void PropertyInferences::draw_negated(inference_subject *infs, property *prn, parse_node *val) {
	inference *i = PropertyInferences::new(infs, prn, val);
	i->certainty = -i->certainty;
	Inferences::join_inference(i, infs);
}

property *PropertyInferences::get_property(inference *i) {
	property_inference_data *data = RETRIEVE_POINTER_property_inference_data(i->data);
	return data->inferred_property;
}

parse_node *PropertyInferences::get_value(inference *i) {
	property_inference_data *data = RETRIEVE_POINTER_property_inference_data(i->data);
	return data->inferred_property_value;
}

parse_node *PropertyInferences::set_value_kind(inference *i, kind *K) {
	property_inference_data *data = RETRIEVE_POINTER_property_inference_data(i->data);
	Node::set_kind_of_value(data->inferred_property_value, K);
	return data->inferred_property_value;
}
