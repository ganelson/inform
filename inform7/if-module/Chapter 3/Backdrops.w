[Backdrops::] Backdrops.

A plugin to provide support for backdrop objects, which are present
as scenery in multiple rooms at once.

@ While we normally assume that nothing can be in more than one place at
once, backdrops are an exception. These are intended to represent widely
spread, probably background, things, such as the sky, and then placing one
inside something generates |found_in_inf| rather than |parentage_inf|
inferences to avoid piling up bogus inconsistencies.

=
void Backdrops::start(void) {
	Backdrops::create_inference_families();
	PluginManager::plug(NEW_BASE_KIND_NOTIFY_PLUG, Backdrops::new_base_kind_notify);
	PluginManager::plug(NEW_PROPERTY_NOTIFY_PLUG, Backdrops::new_property_notify);
	PluginManager::plug(COMPLETE_MODEL_PLUG, Backdrops::complete_model);
	PluginManager::plug(INTERVENE_IN_ASSERTION_PLUG, Backdrops::intervene_in_assertion);
	PluginManager::plug(PRODUCTION_LINE_PLUG,  Backdrops::production_line);
}

int Backdrops::production_line(int stage, int debugging,
	stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(RTBackdrops::write_found_in_routines);
	}
	return FALSE;
}

@h Kinds.
This a kind name to do with backdrops which Inform provides special support
for; it recognises the English name when defined by the Standard Rules. (So
there is no need to translate this to other languages.)

= (early code)
kind *K_backdrop = NULL;

@ =
<notable-backdrops-kinds> ::=
	backdrop

@ =
int Backdrops::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (<notable-backdrops-kinds>(W)) { K_backdrop = new_base; return TRUE; }
	return FALSE;
}

int Backdrops::object_is_a_backdrop(instance *I) {
	if ((K_backdrop) && (I) && (Instances::of_kind(I, K_backdrop))) return TRUE;
	return FALSE;
}

@h Properties.
This is a property name to do with backdrops which Inform provides special
support for; it recognises the English name when it is defined by the
Standard Rules. (So there is no need to translate this to other languages.)

=
<notable-backdrops-properties> ::=
	scenery

@ =
property *P_scenery = NULL; /* an I7 either/or property marking something as scenery */
int Backdrops::new_property_notify(property *prn) {
	if (<notable-backdrops-properties>(prn->name))
		P_scenery = prn;
	return FALSE;
}

int Backdrops::object_is_scenery(instance *I) {
	if (PropertyInferences::either_or_state(Instances::as_subject(I), P_scenery) > 0)
		return TRUE;
	return FALSE;
}

@ Here we look at "in" and "part of" relationships to see if they concern
backdrops; if they do, then they need to become |found_in_inf| inferences.
Without this intervention, they'd be subject to the usual spatial rules
and text like

>> The sky is in the Grand Balcony. The sky is in the Vizier's Lawn.

would lead to contradiction problem messages.

=
int Backdrops::assert_relations(binary_predicate *relation,
	instance *I0, instance *I1) {

	if ((Instances::of_kind(I1, K_backdrop)) &&
		((relation == R_incorporation) ||
			(relation == R_containment) ||
			(relation == R_regional_containment))) {
		inference_subject *bd = Instances::as_subject(I1);
		inference_subject *loc = Instances::as_subject(I0);
		SpatialInferences::infer_part_of(bd, IMPOSSIBLE_CE, loc);
		SpatialInferences::infer_is_room(bd, IMPOSSIBLE_CE);
		inference *i = Backdrops::new_found_in_inference(loc, CERTAIN_CE);
		Inferences::join_inference(i, bd);
		return TRUE;
	}

	return FALSE;
}

@ For indexing purposes, the following loops are useful:

@d LOOP_OVER_BACKDROPS_IN(B, P, I)
	LOOP_OVER_INSTANCES(B, K_object)
		if (Backdrops::object_is_a_backdrop(B))
			POSITIVE_KNOWLEDGE_LOOP(I, Instances::as_subject(B), found_in_inf)
				if (Backdrops::get_inferred_location(I) == P)

@d LOOP_OVER_BACKDROPS_EVERYWHERE(B, I)
	LOOP_OVER_INSTANCES(B, K_object)
		if (Backdrops::object_is_a_backdrop(B))
			POSITIVE_KNOWLEDGE_LOOP(I, Instances::as_subject(B), found_everywhere_inf)

@h Everywhere.
Here we defines a form of noun phrase special to Backdrops (because a backdrop
can be said to be "everywhere", which nothing else can).

=
<notable-backdrops-noun-phrases> ::=
	everywhere

@ =
int Backdrops::intervene_in_assertion(parse_node *px, parse_node *py) {
	if ((Node::get_type(py) == EVERY_NT) &&
		(<notable-backdrops-noun-phrases>(Node::get_text(py)))) {
		inference_subject *left_subject = Node::get_subject(px);
		if (left_subject == NULL)
			Problems::Using::assertion_problem(Task::syntax_tree(), _p_(PM_ValueEverywhere),
				"'everywhere' can only be used to place individual backdrops",
				"so although 'The mist is a backdrop. The mist is everywhere.' "
				"would be fine, 'Corruption is everywhere.' would not.");
		else if (KindSubjects::to_kind(left_subject))
			StandardProblems::subject_problem_at_sentence(_p_(PM_KindOfBackdropEverywhere),
				left_subject,
				"seems to be said to be 'everywhere' in some way",
				"which doesn't make sense. An individual backdrop can be 'everywhere', "
				"but here we're talking about a whole kind, and it's not allowed "
				"to talk about general locations of a whole kind of things at once.");
		else Assert::true_about(
			Propositions::Abstract::to_put_everywhere(), left_subject, prevailing_mood);
		return TRUE;
	}
	return FALSE;
}

@h Model completion.
We intervene only at Stage II, the spatial modelling stage.

=
property *P_absent = NULL; /* an I6-only property for backdrops out of play */

int Backdrops::complete_model(int stage) {
	if (stage == WORLD_STAGE_II) {
		P_absent = EitherOrProperties::new_nameless(I"absent");
		RTProperties::recommend_storing_as_attribute(P_absent, TRUE);
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object) {
			parse_node *val_of_found_in = NULL;
			@<If the object is found everywhere, make a found-in property accordingly@>;
			int room_count = 0, region_count = 0;
			@<Find how many rooms or regions the object is found inside@>;
			if ((val_of_found_in == NULL) && (room_count > 0) &&
				(room_count < 16) && (region_count == 0))
				@<The object is found only in a few rooms, and no regions, so make it a list@>;
			if ((val_of_found_in == NULL) && (room_count + region_count > 0))
				@<The object is found in many rooms or in whole regions, so make it a routine@>;
			if ((val_of_found_in == NULL) && (Instances::of_kind(I, K_backdrop)))
				@<The object is found nowhere, so give it a stub found-in property and mark it absent@>;
			if (val_of_found_in) Map::set_found_in(I, val_of_found_in);
		}
	}
	return FALSE;
}

@<If the object is found everywhere, make a found-in property accordingly@> =
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), found_everywhere_inf) {
		val_of_found_in = Rvalues::from_iname(Hierarchy::find(FOUND_EVERYWHERE_HL));
		break;
	}

@<Find how many rooms or regions the object is found inside@> =
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), found_in_inf) {
		instance *loc = Backdrops::get_inferred_location(inf);
		if ((K_region) && (Instances::of_kind(loc, K_region))) region_count++;
		else room_count++;
	}

@<The object is found only in a few rooms, and no regions, so make it a list@> =
	package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, RTInstances::package(I));
	inter_name *iname = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	packaging_state save = EmitArrays::begin(iname, K_value);
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), found_in_inf)
		EmitArrays::iname_entry(RTInstances::value_iname(Backdrops::get_inferred_location(inf)));
	EmitArrays::end(save);
	Produce::annotate_i(iname, INLINE_ARRAY_IANN, 1);
	val_of_found_in = Rvalues::from_iname(iname);

@<The object is found in many rooms or in whole regions, so make it a routine@> =
	val_of_found_in = RTBackdrops::found_in_val(I, TRUE);

@ |absent| is an I6-only attribute which marks a backdrop has having been removed
from the world model. It's not sufficient for an object's |found_in| always to
say no to the question "are you in the current location?"; the I6 template
code, derived from the old I6 library, requires |absent| to be set. So:

@<The object is found nowhere, so give it a stub found-in property and mark it absent@> =
	val_of_found_in = RTBackdrops::found_in_val(I, FALSE);
	EitherOrProperties::assert(
		P_absent, Instances::as_subject(I), TRUE, CERTAIN_CE);

@h Inference families.
Two sorts of inferences are used only for backdrops:

= (early code)
inference_family *found_in_inf = NULL; /* for backdrop things in many places */
inference_family *found_everywhere_inf = NULL; /* ditto */

@ =
void Backdrops::create_inference_families(void) {
	found_in_inf = Inferences::new_family(I"found_in_inf");
	METHOD_ADD(found_in_inf, LOG_DETAILS_INF_MTID, Backdrops::log);
	METHOD_ADD(found_in_inf, COMPARE_INF_MTID, Backdrops::cmp);

	found_everywhere_inf = Inferences::new_family(I"found_everywhere_inf");
}

@ |found_in_inf| infers that the named room is one of the locations of the
backdrop.

=
typedef struct found_in_inference_data {
	struct inference_subject *location;
	CLASS_DEFINITION
} found_in_inference_data;

inference *Backdrops::new_found_in_inference(inference_subject *loc, int certitude) {
	PROTECTED_MODEL_PROCEDURE;
	found_in_inference_data *data = CREATE(found_in_inference_data);
	data->location = InferenceSubjects::divert(loc);
	return Inferences::create_inference(found_in_inf,
		STORE_POINTER_found_in_inference_data(data), certitude);
}

void Backdrops::log(inference_family *f, inference *inf) {
	found_in_inference_data *data = RETRIEVE_POINTER_found_in_inference_data(inf->data);
	if (data->location) LOG(" in:$j", data->location);
}

int Backdrops::cmp(inference_family *f, inference *i1, inference *i2) {
	found_in_inference_data *data1 = RETRIEVE_POINTER_found_in_inference_data(i1->data);
	found_in_inference_data *data2 = RETRIEVE_POINTER_found_in_inference_data(i2->data);

	int c = Inferences::measure_infs(data1->location) -
			Inferences::measure_infs(data2->location);
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

instance *Backdrops::get_inferred_location(inference *i) {
	if ((i == NULL) || (i->family != found_in_inf))
		internal_error("not a found_in_inf inf");
	found_in_inference_data *data = RETRIEVE_POINTER_found_in_inference_data(i->data);
	return InstanceSubjects::to_instance(data->location);
}

@ |found_everywhere_inf| infers that the backdrop is visible in every location.

=
void Backdrops::infer_presence_everywhere(instance *I) {
	if ((I == NULL) || (Instances::of_kind(I, K_backdrop) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_EverywhereNonBackdrop),
			"only a backdrop can be everywhere",
			"and no other kind of object will do. For instance, 'The sky is "
			"a backdrop which is everywhere.' is allowed, but 'The travelator "
			"is a vehicle which is everywhere.' is not.");
		return;
	}
	Inferences::join_inference(Inferences::create_inference(found_everywhere_inf,
		NULL_GENERAL_POINTER, prevailing_mood), Instances::as_subject(I));
}
