[PropertyInferences::] Property Inferences.

Inferences that a property of something is true, or has a particular value.

@ We will make:

= (early code)
inference_family *property_inf = NULL;

@

=
void PropertyInferences::start(void) {
	property_inf = Inferences::new_family(I"property_inf");
	METHOD_ADD(property_inf, LOG_DETAILS_INF_MTID, PropertyInferences::log);
	METHOD_ADD(property_inf, COMPARE_INF_MTID, PropertyInferences::cmp);
	METHOD_ADD(property_inf, JOIN_INF_MTID, PropertyInferences::join);
	METHOD_ADD(property_inf, EXPLAIN_CONTRADICTION_INF_MTID, PropertyInferences::explain_contradiction);
}

void PropertyInferences::join(inference_family *f, inference *inf, inference_subject *infs) {
	property_inference_data *data = RETRIEVE_POINTER_property_inference_data(inf->data);
	Plugins::Call::property_value_notify(
		data->inferred_property, data->inferred_property_value);
}

@ By convention, a pair of attached either/or properties which are negations of
each other -- say "open" and "closed" -- are treated as if they were the
same property but with different values.

=
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
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);

	parse_node *val1 = data1->inferred_property_value;
	parse_node *val2 = data2->inferred_property_value;
	if ((data1->inferred_property != data2->inferred_property) || /* in case they are an either-or pair */
		((val1) && (val2) && (Rvalues::compare_CONSTANT(val1, val2) == FALSE))) {
		int M = CI_DIFFER_IN_CONTENT;
		if (Properties::is_either_or(pr1)) M = CI_DIFFER_IN_BOOLEAN_CONTENT;
		if (c > 0) return M;
		if (c < 0) return -M;
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
@h Finding property states.

=
int PropertyInferences::either_or_state(inference_subject *infs, property *prn) {
	if ((prn == NULL) || (infs == NULL)) return UNKNOWN_CE;
	inference_subject *k;
	property *prnbar = NULL;
	if (Properties::is_either_or(prn)) prnbar = Properties::EitherOr::get_negation(prn);
	for (k = infs; k; k = InferenceSubjects::narrowest_broader_subject(k)) {
		inference *inf;
		KNOWLEDGE_LOOP(inf, k, property_inf) {
			property *known = PropertyInferences::get_property(inf);
			int c = Inferences::get_certainty(inf);
			if (known) {
				if ((prn == known) && (c != UNKNOWN_CE)) return c;
				if ((prnbar == known) && (c != UNKNOWN_CE)) return -c;
			}
		}
	}
	return UNKNOWN_CE;
}

int PropertyInferences::either_or_state_without_inheritance(inference_subject *infs,
	property *prn, parse_node **where) {
	if ((prn == NULL) || (infs == NULL)) return UNKNOWN_CE;
	property *prnbar = NULL;
	if (Properties::is_either_or(prn)) prnbar = Properties::EitherOr::get_negation(prn);
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, property_inf) {
		property *known = PropertyInferences::get_property(inf);
		int c = Inferences::get_certainty(inf);
		if (known) {
			if ((prn == known) && (c != UNKNOWN_CE)) {
				if (where) *where = Inferences::where_inferred(inf);
				return c;
			}
			if ((prnbar == known) && (c != UNKNOWN_CE)) {
				if (where) *where = Inferences::where_inferred(inf);
				return -c;
			}
		}
	}
	return UNKNOWN_CE;
}

void PropertyInferences::verify_prop_states(inference_subject *infs) {
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, property_inf) {
		property *prn = PropertyInferences::get_property(inf);
		parse_node *val = PropertyInferences::get_value(inf);
		kind *PK = Properties::Valued::kind(prn);
		kind *VK = Specifications::to_kind(val);
		if (Kinds::compatible(VK, PK) != ALWAYS_MATCH) {
			LOG("Property value given as %u not %u\n", VK, PK);
			current_sentence = inf->inferred_from;
			Problems::quote_source(1, current_sentence);
			Problems::quote_property(2, prn);
			Problems::quote_kind(3, VK);
			Problems::quote_kind(4, PK);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_LateInferenceProblem));
			Problems::issue_problem_segment(
				"You wrote %1, but that tries to set the value of the '%2' "
				"property to %3 - which must be wrong because this property "
				"has to be %4.");
			Problems::issue_problem_end();
		}
	}
}

parse_node *PropertyInferences::get_prop_state(inference_subject *infs, property *prn) {
	if ((prn == NULL) || (infs == NULL)) return NULL;
	inference_subject *k;
	for (k = infs; k; k = InferenceSubjects::narrowest_broader_subject(k)) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, k, property_inf) {
			property *known = PropertyInferences::get_property(inf);
			if (known == prn) return PropertyInferences::get_value(inf);
		}
	}
	return NULL;
}

parse_node *PropertyInferences::get_prop_state_at(inference_subject *infs, property *prn,
	parse_node **where) {
	if ((prn == NULL) || (infs == NULL)) return NULL;
	inference_subject *k;
	for (k = infs; k; k = InferenceSubjects::narrowest_broader_subject(k)) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, k, property_inf) {
			property *known = PropertyInferences::get_property(inf);
			if (known == prn) {
				if (where) *where = Inferences::where_inferred(inf);
				return PropertyInferences::get_value(inf);
			}
		}
	}
	return NULL;
}

parse_node *PropertyInferences::get_prop_state_without_inheritance(inference_subject *infs,
	property *prn, parse_node **where) {
	if ((prn == NULL) || (infs == NULL)) return NULL;
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, property_inf) {
		property *known = PropertyInferences::get_property(inf);
		if (known == prn) {
			if (where) *where = Inferences::where_inferred(inf);
			return PropertyInferences::get_value(inf);
		}
	}
	return NULL;
}

int PropertyInferences::has_or_can_have(inference_subject *infs, property *prn) {
	if (Properties::is_either_or(prn)) {
		int has = PropertyInferences::either_or_state(infs, prn);
		if ((has == UNKNOWN_CE) && (World::Permissions::find(infs, prn, TRUE))) {
			if (Properties::EitherOr::stored_in_negation(prn))
				return LIKELY_CE;
			else
				return UNLIKELY_CE;
		}
		return has;
	}
	if (World::Permissions::find(infs, prn, TRUE)) return LIKELY_CE;
	return UNKNOWN_CE;
}
