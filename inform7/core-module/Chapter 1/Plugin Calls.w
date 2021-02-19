[PluginCalls::] Plugin Calls.

To place calls to the plugins.

@h Definitions.

@

@e ACT_ON_SPECIAL_NPS_PCALL from 1
@e ADD_TO_WORLD_INDEX_PCALL
@e ANNOTATE_IN_WORLD_INDEX_PCALL
@e CHECK_GOING_PCALL
@e COMPILE_CONSTANT_PCALL
@e COMPILE_MODEL_TABLES_PCALL
@e COMPILE_OBJECT_HEADER_PCALL
@e COMPLETE_MODEL_PCALL
@e CREATE_INFERENCES_PCALL
@e DEFAULT_APPEARANCE_PCALL
@e DETECT_BODYSNATCHING_PCALL
@e ESTIMATE_PROPERTY_USAGE_PCALL
@e FORBID_SETTING_PCALL
@e INTERVENE_IN_ASSERTION_PCALL
@e IRREGULAR_GENITIVE_PCALL
@e MORE_SPECIFIC_PCALL
@e NAME_TO_EARLY_INFS_PCALL
@e NEW_BASE_KIND_NOTIFY_PCALL
@e NEW_INSTANCE_NOTIFY_PCALL
@e NEW_PERMISSION_NOTIFY_PCALL
@e NEW_PROPERTY_NOTIFY_PCALL
@e NEW_SUBJECT_NOTIFY_PCALL
@e NEW_VARIABLE_NOTIFY_PCALL
@e OFFERED_PROPERTY_PCALL
@e OFFERED_SPECIFICATION_PCALL
@e PARSE_COMPOSITE_NQS_PCALL
@e PROPERTY_VALUE_NOTIFY_PCALL
@e REFINE_IMPLICIT_NOUN_PCALL
@e SET_KIND_NOTIFY_PCALL
@e SET_SUBKIND_NOTIFY_PCALL
@e TYPECHECK_EQUALITY_PCALL
@e VARIABLE_SET_WARNING_PCALL

@

@d MAX_PLUGS 64

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

@d REGISTER(code, R) {
	plugin_call *new = CREATE(plugin_call);
	new->routine = (void *) (&R);
	new->next = NULL;
	if (code >= MAX_PLUGS) internal_error("too many plugin calls");
	if (plugins_stack[code] == NULL) plugins_stack[code] = new;
	else {
		plugin_call *PC = plugins_stack[code];
		while ((PC) && (PC->next)) PC = PC->next;
		PC->next = new;
	}
}

=
void PluginCalls::initialise_calls(void) {
	for (int i=0; i<MAX_PLUGS; i++) plugins_stack[i] = NULL;
}

@ And here goes:

@d NEW_BASE_KINDS_CALLBACK PluginCalls::new_base_kind_notify
@d HIERARCHY_VETO_MOVE_KINDS_CALLBACK PluginCalls::set_subkind_notify

=
int PluginCalls::name_to_early_infs(wording W, inference_subject **infs) {
	PLUGINS_CALL(NAME_TO_EARLY_INFS_PCALL, W, infs);
}

int PluginCalls::new_variable_notify(nonlocal_variable *q) {
	PLUGINS_CALL(NEW_VARIABLE_NOTIFY_PCALL, q);
}

int PluginCalls::new_base_kind_notify(kind *K, kind *super, text_stream *d, wording W) {
	KindSubjects::renew(K, super, W);
	if (<property-name>(W)) {
		property *P = <<rp>>;
		ValueProperties::set_kind(P, K);
		Instances::make_kind_coincident(K, P);
	}
	PLUGINS_CALL(NEW_BASE_KIND_NOTIFY_PCALL, K, d, W);
}

@ =
int PluginCalls::compile_constant(value_holster *VH, kind *K, parse_node *spec) {
	PLUGINS_CALL(COMPILE_CONSTANT_PCALL, VH, K, spec);
}

int PluginCalls::new_subject_notify(inference_subject *subj) {
	PLUGINS_CALL(NEW_SUBJECT_NOTIFY_PCALL, subj);
}

int PluginCalls::new_named_instance_notify(instance *nc) {
	PLUGINS_CALL(NEW_INSTANCE_NOTIFY_PCALL, nc);
}

int PluginCalls::new_permission_notify(property_permission *pp) {
	PLUGINS_CALL(NEW_PERMISSION_NOTIFY_PCALL, pp);
}

int PluginCalls::irregular_genitive(inference_subject *owner, text_stream *genitive, int *propriety) {
	PLUGINS_CALL(IRREGULAR_GENITIVE_PCALL, owner, genitive, propriety);
}

int PluginCalls::set_kind_notify(instance *I, kind *k) {
	PLUGINS_CALL(SET_KIND_NOTIFY_PCALL, I, k);
}

int PluginCalls::set_subkind_notify(kind *sub, kind *super) {
	if (Kinds::Behaviour::is_subkind_of_object(sub) == FALSE) return TRUE;
	PLUGINS_CALL(SET_SUBKIND_NOTIFY_PCALL, sub, super);
}

int PluginCalls::complete_model(int stage) {
	// Inferences::diversion_off();
	PLUGINS_CALL(COMPLETE_MODEL_PCALL, stage);
}

int PluginCalls::parse_composite_NQs(wording *W, wording *DW,
	quantifier **quantifier_used, kind **some_kind) {
	PLUGINS_CALL(PARSE_COMPOSITE_NQS_PCALL, W, DW, quantifier_used, some_kind);
}

int PluginCalls::refine_implicit_noun(parse_node *p) {
	PLUGINS_CALL(REFINE_IMPLICIT_NOUN_PCALL, p);
}


int PluginCalls::act_on_special_NPs(parse_node *p) {
	PLUGINS_CALL(ACT_ON_SPECIAL_NPS_PCALL, p);
}

int PluginCalls::new_property_notify(property *prn) {
	PLUGINS_CALL(NEW_PROPERTY_NOTIFY_PCALL, prn);
}

int PluginCalls::property_value_notify(property *prn, parse_node *val) {
	PLUGINS_CALL(PROPERTY_VALUE_NOTIFY_PCALL, prn, val);
}

int PluginCalls::more_specific(instance *I1, instance *I2) {
	PLUGINS_CALL(MORE_SPECIFIC_PCALL, I1, I2);
}

int PluginCalls::intervene_in_assertion(parse_node *px, parse_node *py) {
	PLUGINS_CALL(INTERVENE_IN_ASSERTION_PCALL, px, py);
}

int PluginCalls::estimate_property_usage(kind *k, int *words_used) {
	PLUGINS_CALL(ESTIMATE_PROPERTY_USAGE_PCALL, k, words_used);
}

int PluginCalls::check_going(parse_node *from, parse_node *to,
	parse_node *by, parse_node *through, parse_node *pushing) {
	PLUGINS_CALL(CHECK_GOING_PCALL, from, to, by, through, pushing);
}

int PluginCalls::compile_model_tables(void) {
	PLUGINS_CALLV(COMPILE_MODEL_TABLES_PCALL);
}

int PluginCalls::default_appearance(inference_subject *infs, parse_node *txt) {
	PLUGINS_CALL(DEFAULT_APPEARANCE_PCALL, infs, txt);
}

int PluginCalls::offered_property(kind *K, parse_node *owner, parse_node *what) {
	PLUGINS_CALL(OFFERED_PROPERTY_PCALL, K, owner, what);
}

int PluginCalls::offered_specification(parse_node *owner, wording W) {
	PLUGINS_CALL(OFFERED_SPECIFICATION_PCALL, owner, W);
}

int PluginCalls::typecheck_equality(kind *K1, kind *K2) {
	PLUGINS_CALL(TYPECHECK_EQUALITY_PCALL, K1, K2);
}

int PluginCalls::forbid_setting(kind *K) {
	PLUGINS_CALL(FORBID_SETTING_PCALL, K);
}

int PluginCalls::variable_set_warning(nonlocal_variable *q, parse_node *val) {
	PLUGINS_CALL(VARIABLE_SET_WARNING_PCALL, q, val);
}

int PluginCalls::detect_bodysnatching(inference_subject *body, int *snatcher,
	inference_subject **counterpart) {
	PLUGINS_CALL(DETECT_BODYSNATCHING_PCALL, body, snatcher, counterpart);
}

int PluginCalls::add_to_World_index(OUTPUT_STREAM, instance *O) {
	PLUGINS_CALL(ADD_TO_WORLD_INDEX_PCALL, OUT, O);
}

int PluginCalls::annotate_in_World_index(OUTPUT_STREAM, instance *O) {
	PLUGINS_CALL(ANNOTATE_IN_WORLD_INDEX_PCALL, OUT, O);
}

int PluginCalls::create_inference_subjects(void) {
	PLUGINS_CALLV(CREATE_INFERENCES_PCALL);
}
