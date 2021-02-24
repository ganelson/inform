[PL::Backdrops::] Backdrops.

A plugin to provide support for backdrop objects, which are present
as scenery in multiple rooms at once.

@ While we normally assume that nothing can be in more than one place at
once, backdrops are an exception. These are intended to represent widely
spread, probably background, things, such as the sky, and they placing one
inside something generates |FOUND_IN_INF| rather than |PARENTAGE_INF|
inferences to avoid piling up bogus inconsistencies.

= (early code)
inference_family *FOUND_IN_INF = NULL; /* 56; for backdrop things in many places */
inference_family *FOUND_EVERYWHERE_INF = NULL; /* 57; ditto */

kind *K_backdrop = NULL;
property *P_scenery = NULL; /* an I7 either/or property marking something as scenery */
property *P_absent = NULL; /* an I6-only property for backdrops out of play */

@ =
typedef struct backdrop_found_in_notice {
	struct instance *backdrop;
	struct inter_name *found_in_routine_iname;
	int many_places;
	CLASS_DEFINITION
} backdrop_found_in_notice;

@h Initialisation.

=
void PL::Backdrops::start(void) {
	FOUND_IN_INF = Inferences::new_family(I"FOUND_IN_INF");
	METHOD_ADD(FOUND_IN_INF, LOG_DETAILS_INF_MTID, PL::Backdrops::log);
	METHOD_ADD(FOUND_IN_INF, COMPARE_INF_MTID, PL::Backdrops::cmp);

	FOUND_EVERYWHERE_INF = Inferences::new_family(I"FOUND_EVERYWHERE_INF");

	PluginManager::plug(NEW_BASE_KIND_NOTIFY_PLUG, PL::Backdrops::backdrops_new_base_kind_notify);
	PluginManager::plug(NEW_PROPERTY_NOTIFY_PLUG, PL::Backdrops::backdrops_new_property_notify);
	PluginManager::plug(COMPLETE_MODEL_PLUG, PL::Backdrops::backdrops_complete_model);
	PluginManager::plug(INTERVENE_IN_ASSERTION_PLUG, PL::Backdrops::backdrops_intervene_in_assertion);
	PluginManager::plug(PRODUCTION_LINE_PLUG,  PL::Backdrops::production_line);
}

int PL::Backdrops::production_line(int stage, int debugging,
	stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(PL::Backdrops::write_found_in_routines);
	}
	return FALSE;
}

typedef struct found_in_inference_data {
	struct inference_subject *location;
	CLASS_DEFINITION
} found_in_inference_data;

inference *PL::Backdrops::new_found_in_inference(inference_subject *loc, int certitude) {
	PROTECTED_MODEL_PROCEDURE;
	found_in_inference_data *data = CREATE(found_in_inference_data);
	data->location = InferenceSubjects::divert(loc);
	return Inferences::create_inference(FOUND_IN_INF,
		STORE_POINTER_found_in_inference_data(data), certitude);
}

void PL::Backdrops::log(inference_family *f, inference *inf) {
	found_in_inference_data *data = RETRIEVE_POINTER_found_in_inference_data(inf->data);
	if (data->location) LOG(" in:$j", data->location);
}

int PL::Backdrops::cmp(inference_family *f, inference *i1, inference *i2) {
	found_in_inference_data *data1 = RETRIEVE_POINTER_found_in_inference_data(i1->data);
	found_in_inference_data *data2 = RETRIEVE_POINTER_found_in_inference_data(i2->data);

	int c = Inferences::measure_infs(data1->location) -
			Inferences::measure_infs(data2->location);
	if (c > 0) return CI_DIFFER_IN_TOPIC; if (c < 0) return -CI_DIFFER_IN_TOPIC;

	c = Inferences::measure_inf(i1) - Inferences::measure_inf(i2);
	if (c > 0) return CI_DIFFER_IN_COPY_ONLY; if (c < 0) return -CI_DIFFER_IN_COPY_ONLY;
	return CI_IDENTICAL;
}

instance *PL::Backdrops::get_inferred_location(inference *i) {
	if ((i == NULL) || (i->family != FOUND_IN_INF))
		internal_error("not a FOUND_IN_INF inf");
	found_in_inference_data *data = RETRIEVE_POINTER_found_in_inference_data(i->data);
	return InstanceSubjects::to_instance(data->location);
}

@h Kinds.
This a kind name to do with backdrops which Inform provides special support
for; it recognises the English name when defined by the Standard Rules. (So
there is no need to translate this to other languages.)

=
<notable-backdrops-kinds> ::=
	backdrop

@ =
int PL::Backdrops::backdrops_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (<notable-backdrops-kinds>(W)) {
		K_backdrop = new_base; return TRUE;
	}
	return FALSE;
}

@ =
int PL::Backdrops::object_is_a_backdrop(instance *I) {
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
int PL::Backdrops::backdrops_new_property_notify(property *prn) {
	if (<notable-backdrops-properties>(prn->name))
		P_scenery = prn;
	return FALSE;
}

int PL::Backdrops::object_is_scenery(instance *I) {
	if (PropertyInferences::either_or_state(Instances::as_subject(I), P_scenery) > 0)
		return TRUE;
	return FALSE;
}

@ Here we look at "in" and "part of" relationships to see if they concern
backdrops; if they do, then they need to become |FOUND_IN_INF| inferences.
Without this intervention, they'd be subject to the usual spatial rules
and text like

>> The sky is in the Grand Balcony. The sky is in the Vizier's Lawn.

would lead to contradiction problem messages.

=
int PL::Backdrops::assert_relations(binary_predicate *relation,
	instance *I0, instance *I1) {

	if ((Instances::of_kind(I1, K_backdrop)) &&
		((relation == R_incorporation) ||
			(relation == R_containment) ||
			(relation == R_regional_containment))) {
		inference_subject *bd = Instances::as_subject(I1);
		inference_subject *loc = Instances::as_subject(I0);
		PL::Spatial::infer_part_of(bd, IMPOSSIBLE_CE, loc);
		PL::Spatial::infer_is_room(bd, IMPOSSIBLE_CE);
		inference *i = PL::Backdrops::new_found_in_inference(loc, CERTAIN_CE);
		Inferences::join_inference(i, bd);
		return TRUE;
	}

	return FALSE;
}

@ For indexing purposes, the following loops are useful:

@d LOOP_OVER_BACKDROPS_IN(B, P, I)
	LOOP_OVER_INSTANCES(B, K_object)
		if (PL::Backdrops::object_is_a_backdrop(B))
			POSITIVE_KNOWLEDGE_LOOP(I, Instances::as_subject(B), FOUND_IN_INF)
				if (PL::Backdrops::get_inferred_location(I) == P)

@d LOOP_OVER_BACKDROPS_EVERYWHERE(B, I)
	LOOP_OVER_INSTANCES(B, K_object)
		if (PL::Backdrops::object_is_a_backdrop(B))
			POSITIVE_KNOWLEDGE_LOOP(I, Instances::as_subject(B), FOUND_EVERYWHERE_INF)

@ Since backdrops are contained using different mechanisms, the following
(which does nothing if Backdrops isn't plugged in) adds backdrop contents to
a room called |loc|, or lists backdrops which are "everywhere" if |loc|
is |NULL|.

=
void PL::Backdrops::index_object_further(OUTPUT_STREAM, instance *loc, int depth,
	int details, int how) {
	int discoveries = 0;
	instance *bd;
	inference *inf;
	if (loc) {
		LOOP_OVER_BACKDROPS_IN(bd, loc, inf) {
			if (++discoveries == 1) @<Insert fore-matter@>;
			Data::Objects::index(OUT, bd, NULL, depth+1, details);
		}
	} else {
		LOOP_OVER_BACKDROPS_EVERYWHERE(bd, inf) {
			if (++discoveries == 1) @<Insert fore-matter@>;
			Data::Objects::index(OUT, bd, NULL, depth+1, details);
		}
	}
	if (discoveries > 0) @<Insert after-matter@>;
}

@<Insert fore-matter@> =
	switch (how) {
		case 1: HTML_OPEN("p"); WRITE("<b>Present everywhere:</b>"); HTML_TAG("br"); break;
		case 2: HTML_TAG("br"); break;
	}

@<Insert after-matter@> =
	switch (how) {
		case 1: HTML_CLOSE("p"); HTML_TAG("hr"); HTML_OPEN("p"); break;
		case 2: break;
	}

@h Everywhere.
Here we defines a form of noun phrase special to Backdrops (because a backdrop
can be said to be "everywhere", which nothing else can).

=
<notable-backdrops-noun-phrases> ::=
	everywhere

@ =
int PL::Backdrops::backdrops_intervene_in_assertion(parse_node *px, parse_node *py) {
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

@ And this is where it makes the necessary inference after such a request has
been asserted true:

=
void PL::Backdrops::infer_presence_everywhere(instance *I) {
	if ((I == NULL) || (Instances::of_kind(I, K_backdrop) == FALSE)) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EverywhereNonBackdrop),
			"only a backdrop can be everywhere",
			"and no other kind of object will do. For instance, 'The sky is "
			"a backdrop which is everywhere.' is allowed, but 'The travelator "
			"is a vehicle which is everywhere.' is not.");
		return;
	}
	Inferences::join_inference(Inferences::create_inference(FOUND_EVERYWHERE_INF, NULL_GENERAL_POINTER, prevailing_mood), Instances::as_subject(I));
}

@h Model completion.
We intervene only at Stage II, the spatial modelling stage.

=
int PL::Backdrops::backdrops_complete_model(int stage) {
	if (stage == WORLD_STAGE_II) {
		P_absent = EitherOrProperties::new_nameless(L"absent");
		RTProperties::implement_as_attribute(P_absent, TRUE);
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object) {
			inter_name *FOUNDIN = NULL;
			@<If the object is found everywhere, make a found-in property accordingly@>;
			int room_count = 0, region_count = 0;
			@<Find how many rooms or regions the object is found inside@>;
			if ((FOUNDIN == NULL) && (room_count > 0) && (room_count < 16) && (region_count == 0))
				@<The object is found only in a few rooms, and no regions, so make it a list@>;
			if ((FOUNDIN == NULL) && (room_count + region_count > 0))
				@<The object is found in many rooms or in whole regions, so make it a routine@>;
			if ((FOUNDIN == NULL) && (Instances::of_kind(I, K_backdrop)))
				@<The object is found nowhere, so give it a stub found-in property and mark it absent@>;
			if (FOUNDIN) PL::Map::set_found_in(I, FOUNDIN);
		}
	}
	return FALSE;
}

@<If the object is found everywhere, make a found-in property accordingly@> =
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), FOUND_EVERYWHERE_INF) {
		FOUNDIN = Hierarchy::find(FOUND_EVERYWHERE_HL);
		break;
	}

@<Find how many rooms or regions the object is found inside@> =
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), FOUND_IN_INF) {
		instance *loc = PL::Backdrops::get_inferred_location(inf);
		if ((K_region) && (Instances::of_kind(loc, K_region))) region_count++;
		else room_count++;
	}

@<The object is found only in a few rooms, and no regions, so make it a list@> =
	package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, RTInstances::package(I));
	FOUNDIN = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	packaging_state save = Emit::named_array_begin(FOUNDIN, K_value);
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), FOUND_IN_INF)
		Emit::array_iname_entry(RTInstances::iname(PL::Backdrops::get_inferred_location(inf)));
	Emit::array_end(save);
	Produce::annotate_i(FOUNDIN, INLINE_ARRAY_IANN, 1);

@<The object is found in many rooms or in whole regions, so make it a routine@> =
	backdrop_found_in_notice *notice = CREATE(backdrop_found_in_notice);
	notice->backdrop = I;
	package_request *R = RTInstances::package(I);
	notice->found_in_routine_iname = Hierarchy::make_iname_in(BACKDROP_FOUND_IN_FN_HL, R);
	notice->many_places = TRUE;
	FOUNDIN = notice->found_in_routine_iname;

@ |absent| is an I6-only attribute which marks a backdrop has having been removed
from the world model. It's not sufficient for an object's |found_in| always to
say no to the question "are you in the current location?"; the I6 template
code, derived from the old I6 library, requires |absent| to be set. So:

@<The object is found nowhere, so give it a stub found-in property and mark it absent@> =
	backdrop_found_in_notice *notice = CREATE(backdrop_found_in_notice);
	notice->backdrop = I;
	package_request *R = RTInstances::package(I);
	notice->found_in_routine_iname = Hierarchy::make_iname_in(BACKDROP_FOUND_IN_FN_HL, R);
	notice->many_places = FALSE;
	FOUNDIN = notice->found_in_routine_iname;
	EitherOrProperties::assert(
		P_absent, Instances::as_subject(I), TRUE, CERTAIN_CE);

@ =
void PL::Backdrops::write_found_in_routines(void) {
	backdrop_found_in_notice *notice;
	LOOP_OVER(notice, backdrop_found_in_notice) {
		instance *I = notice->backdrop;
		if (notice->many_places)
			@<The object is found in many rooms or in whole regions@>
		else
			@<The object is found nowhere@>;
	}
}

@<The object is found in many rooms or in whole regions@> =
	packaging_state save = Routines::begin(notice->found_in_routine_iname);
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), FOUND_IN_INF) {
		instance *loc = PL::Backdrops::get_inferred_location(inf);
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
		if ((K_region) && (Instances::of_kind(loc, K_region))) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(LOCATION_HL));
				Produce::val_iname(Emit::tree(), K_object, RTInstances::iname(loc));
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(LOCATION_HL));
				Produce::val_iname(Emit::tree(), K_object, RTInstances::iname(loc));
			Produce::up(Emit::tree());
		}
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				Produce::rtrue(Emit::tree());
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
		Produce::rfalse(Emit::tree());
		break;
	}
	Routines::end(save);

@<The object is found nowhere@> =
	packaging_state save = Routines::begin(notice->found_in_routine_iname);
	Produce::rfalse(Emit::tree());
	Routines::end(save);
