[Plugins::Call::] Plugin Calls.

To place calls to the plugins.

@h Definitions.

@

@d PLUGIN_NEW_VARIABLE_NOTIFY 1
@d PLUGIN_IRREGULAR_GENITIVE 4
@d PLUGIN_SET_KIND_NOTIFY 6
@d PLUGIN_COMPLETE_MODEL 11
@d PLUGIN_PARSE_COMPOSITE_NQS 12
@d PLUGIN_REFINE_IMPLICIT_NOUN 14
@d PLUGIN_ACT_ON_SPECIAL_NPS 15
@d PLUGIN_NEW_PROPERTY_NOTIFY 16
@d PLUGIN_PROPERTY_VALUE_NOTIFY 17
@d PLUGIN_MORE_SPECIFIC 18
@d PLUGIN_INFERENCES_CONTRADICT 19
@d PLUGIN_INTERVENE_IN_ASSERTION 20
@d PLUGIN_LOG_INFERENCE_TYPE 21
@d PLUGIN_COMPILE_OBJECT_HEADER 22
@d PLUGIN_ESTIMATE_PROPERTY_USAGE 23
@d PLUGIN_CHECK_GOING 24
@d PLUGIN_COMPILE_MODEL_TABLES 25
@d PLUGIN_DEFAULT_APPEARANCE 26
@d PLUGIN_NEW_PERMISSION_NOTIFY 27
@d PLUGIN_NAME_TO_EARLY_INFS 28
@d PLUGIN_NEW_BASE_KIND_NOTIFY 29
@d PLUGIN_COMPILE_CONSTANT 30
@d PLUGIN_NEW_INSTANCE_NOTIFY 31
@d PLUGIN_OFFERED_PROPERTY 32
@d PLUGIN_OFFERED_SPECIFICATION 33
@d PLUGIN_TYPECHECK_EQUALITY 34
@d PLUGIN_FORBID_SETTING 35
@d PLUGIN_VARIABLE_SET_WARNING 36
@d PLUGIN_DETECT_BODYSNATCHING 37
@d PLUGIN_NEW_SUBJECT_NOTIFY 38
@d PLUGIN_EXPLAIN_CONTRADICTION 39
@d PLUGIN_ADD_TO_WORLD_INDEX 40
@d PLUGIN_ANNOTATE_IN_WORLD_INDEX 41
@d PLUGIN_SET_SUBKIND_NOTIFY 42
@d PLUGIN_CREATE_INFERENCES 43

@

@d MAX_PLUGS 100

=
typedef struct plugin_call {
	void *routine;
	struct plugin_call *next;
} plugin_call;

@

= (early code)
plugin_call *plugins_stack[MAX_PLUGS];

@h Plugin calls.

@d PLUGINS_CALL(code, args...) {
	plugin_call *pc = plugins_stack[code];
	while (pc) {
		int (*R)() = (int (*)()) pc->routine;
		int Q = (*R)(args);
		if (Q) return Q;
		pc = pc->next;
	}
	return FALSE;
}

@d PLUGINS_CALLV(code) {
	plugin_call *pc = plugins_stack[code];
	while (pc) {
		int (*R)() = (int (*)()) pc->routine;
		int Q = (*R)();
		if (Q) return Q;
		pc = pc->next;
	}
	return FALSE;
}

@d PLUGIN_REGISTER(code, R) {
	plugin_call *new = CREATE(plugin_call);
	new->routine = (void *) (&R);
	new->next = NULL;
	if (plugins_stack[code] == NULL) plugins_stack[code] = new;
	else {
		plugin_call *PC = plugins_stack[code];
		while ((PC) && (PC->next)) PC = PC->next;
		PC->next = new;
	}
}

=
void Plugins::Call::initialise_calls(void) {
	int i;
	for (i=0; i<MAX_PLUGS; i++) plugins_stack[i] = NULL;
}

@ And here goes:

@d NEW_BASE_KIND_NOTIFY Plugins::Call::new_base_kind_notify
@d NEW_SUBKIND_NOTIFY Plugins::Call::set_subkind_notify

=
int Plugins::Call::name_to_early_infs(wording W, inference_subject **infs) {
	PLUGINS_CALL(PLUGIN_NAME_TO_EARLY_INFS, W, infs);
}

int Plugins::Call::new_variable_notify(nonlocal_variable *q) {
	PLUGINS_CALL(PLUGIN_NEW_VARIABLE_NOTIFY, q);
}

int Plugins::Call::new_base_kind_notify(kind *K, text_stream *d, wording W) {
	PLUGINS_CALL(PLUGIN_NEW_BASE_KIND_NOTIFY, K, d, W);
}

int Plugins::Call::compile_constant(value_holster *VH, kind *K, parse_node *spec) {
	PLUGINS_CALL(PLUGIN_COMPILE_CONSTANT, VH, K, spec);
}

int Plugins::Call::new_subject_notify(inference_subject *subj) {
	PLUGINS_CALL(PLUGIN_NEW_SUBJECT_NOTIFY, subj);
}

int Plugins::Call::new_named_instance_notify(instance *nc) {
	PLUGINS_CALL(PLUGIN_NEW_INSTANCE_NOTIFY, nc);
}

int Plugins::Call::new_permission_notify(property_permission *pp) {
	PLUGINS_CALL(PLUGIN_NEW_PERMISSION_NOTIFY, pp);
}

int Plugins::Call::irregular_genitive(inference_subject *owner, text_stream *genitive, int *propriety) {
	PLUGINS_CALL(PLUGIN_IRREGULAR_GENITIVE, owner, genitive, propriety);
}

int Plugins::Call::set_kind_notify(instance *I, kind *k) {
	PLUGINS_CALL(PLUGIN_SET_KIND_NOTIFY, I, k);
}

int Plugins::Call::set_subkind_notify(kind *sub, kind *super) {
	PLUGINS_CALL(PLUGIN_SET_SUBKIND_NOTIFY, sub, super);
}

int Plugins::Call::complete_model(int stage) {
	World::Inferences::diversion_off();
	PLUGINS_CALL(PLUGIN_COMPLETE_MODEL, stage);
}

int Plugins::Call::parse_composite_NQs(wording *W, wording *DW,
	quantifier **quantifier_used, kind **some_kind) {
	PLUGINS_CALL(PLUGIN_PARSE_COMPOSITE_NQS, W, DW, quantifier_used, some_kind);
}

int Plugins::Call::refine_implicit_noun(parse_node *p) {
	PLUGINS_CALL(PLUGIN_REFINE_IMPLICIT_NOUN, p);
}


int Plugins::Call::act_on_special_NPs(parse_node *p) {
	PLUGINS_CALL(PLUGIN_ACT_ON_SPECIAL_NPS, p);
}

int Plugins::Call::new_property_notify(property *prn) {
	PLUGINS_CALL(PLUGIN_NEW_PROPERTY_NOTIFY, prn);
}

int Plugins::Call::property_value_notify(property *prn, parse_node *val) {
	PLUGINS_CALL(PLUGIN_PROPERTY_VALUE_NOTIFY, prn, val);
}

int Plugins::Call::more_specific(instance *I1, instance *I2) {
	PLUGINS_CALL(PLUGIN_MORE_SPECIFIC, I1, I2);
}

int Plugins::Call::inferences_contradict(inference *A, inference *B, int similarity) {
	PLUGINS_CALL(PLUGIN_INFERENCES_CONTRADICT, A, B, similarity);
}

int Plugins::Call::explain_contradiction(inference *A, inference *B, int similarity,
	inference_subject *subj) {
	PLUGINS_CALL(PLUGIN_EXPLAIN_CONTRADICTION, A, B, similarity, subj);
}

int Plugins::Call::intervene_in_assertion(parse_node *px, parse_node *py) {
	PLUGINS_CALL(PLUGIN_INTERVENE_IN_ASSERTION, px, py);
}

int Plugins::Call::log_inference_type(int it) {
	PLUGINS_CALL(PLUGIN_LOG_INFERENCE_TYPE, it);
}

int Plugins::Call::estimate_property_usage(kind *k, int *words_used) {
	PLUGINS_CALL(PLUGIN_ESTIMATE_PROPERTY_USAGE, k, words_used);
}

int Plugins::Call::check_going(parse_node *from, parse_node *to,
	parse_node *by, parse_node *through, parse_node *pushing) {
	PLUGINS_CALL(PLUGIN_CHECK_GOING, from, to, by, through, pushing);
}

int Plugins::Call::compile_model_tables(void) {
	PLUGINS_CALLV(PLUGIN_COMPILE_MODEL_TABLES);
}

int Plugins::Call::default_appearance(inference_subject *infs, parse_node *txt) {
	PLUGINS_CALL(PLUGIN_DEFAULT_APPEARANCE, infs, txt);
}

int Plugins::Call::offered_property(kind *K, parse_node *owner, parse_node *what) {
	PLUGINS_CALL(PLUGIN_OFFERED_PROPERTY, K, owner, what);
}

int Plugins::Call::offered_specification(parse_node *owner, wording W) {
	PLUGINS_CALL(PLUGIN_OFFERED_SPECIFICATION, owner, W);
}

int Plugins::Call::typecheck_equality(kind *K1, kind *K2) {
	PLUGINS_CALL(PLUGIN_TYPECHECK_EQUALITY, K1, K2);
}

int Plugins::Call::forbid_setting(kind *K) {
	PLUGINS_CALL(PLUGIN_FORBID_SETTING, K);
}

int Plugins::Call::variable_set_warning(nonlocal_variable *q, parse_node *val) {
	PLUGINS_CALL(PLUGIN_VARIABLE_SET_WARNING, q, val);
}

int Plugins::Call::detect_bodysnatching(inference_subject *body, int *snatcher,
	inference_subject **counterpart) {
	PLUGINS_CALL(PLUGIN_DETECT_BODYSNATCHING, body, snatcher, counterpart);
}

int Plugins::Call::add_to_World_index(OUTPUT_STREAM, instance *O) {
	PLUGINS_CALL(PLUGIN_ADD_TO_WORLD_INDEX, OUT, O);
}

int Plugins::Call::annotate_in_World_index(OUTPUT_STREAM, instance *O) {
	PLUGINS_CALL(PLUGIN_ANNOTATE_IN_WORLD_INDEX, OUT, O);
}

int Plugins::Call::create_inference_subjects(void) {
	PLUGINS_CALLV(PLUGIN_CREATE_INFERENCES);
}
