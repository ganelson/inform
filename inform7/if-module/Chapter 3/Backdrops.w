[PL::Backdrops::] Backdrops.

A plugin to provide support for backdrop objects, which are present
as scenery in multiple rooms at once.

@h Definitions.

@ While we normally assume that nothing can be in more than one place at
once, backdrops are an exception. These are intended to represent widely
spread, probably background, things, such as the sky, and they placing one
inside something generates |FOUND_IN_INF| rather than |PARENTAGE_INF|
inferences to avoid piling up bogus inconsistencies.

@d FOUND_IN_INF 56 /* for backdrop things in many places */
@d FOUND_EVERYWHERE_INF 57 /* ditto */

= (early code)
kind *K_backdrop = NULL;
property *P_scenery = NULL; /* an I7 either/or property marking something as scenery */
property *P_absent = NULL; /* an I6-only property for backdrops out of play */

@ =
typedef struct backdrop_found_in_notice {
	struct instance *backdrop;
	struct inter_name *found_in_routine_iname;
	int many_places;
	MEMORY_MANAGEMENT
} backdrop_found_in_notice;

@h Initialisation.

=
void PL::Backdrops::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_BASE_KIND_NOTIFY, PL::Backdrops::backdrops_new_base_kind_notify);
	PLUGIN_REGISTER(PLUGIN_NEW_PROPERTY_NOTIFY, PL::Backdrops::backdrops_new_property_notify);
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Backdrops::backdrops_complete_model);
	PLUGIN_REGISTER(PLUGIN_LOG_INFERENCE_TYPE, PL::Backdrops::backdrops_log_inference_type);
	PLUGIN_REGISTER(PLUGIN_ESTIMATE_PROPERTY_USAGE, PL::Backdrops::backdrops_estimate_property_usage);
	PLUGIN_REGISTER(PLUGIN_INTERVENE_IN_ASSERTION, PL::Backdrops::backdrops_intervene_in_assertion);
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
	if ((Plugins::Manage::plugged_in(regions_plugin)) && (K_backdrop) && (I) &&
		(Instances::of_kind(I, K_backdrop))) return TRUE;
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
	if (World::Inferences::get_EO_state(Instances::as_subject(I), P_scenery) > 0)
		return TRUE;
	return FALSE;
}

@ Every backdrop needs a single-word property (|found_in| at the I6 level):

=
int PL::Backdrops::backdrops_estimate_property_usage(kind *k, int *words_used) {
	if (Kinds::Compare::eq(k, K_backdrop)) *words_used += 2;
	return FALSE;
}

@h Inferences.

=
int PL::Backdrops::backdrops_log_inference_type(int it) {
	switch(it) {
		case FOUND_IN_INF: LOG("FOUND_IN_INF"); return TRUE;
		case FOUND_EVERYWHERE_INF: LOG("FOUND_EVERYWHERE_INF"); return TRUE;
	}
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
		World::Inferences::draw(PART_OF_INF, bd, IMPOSSIBLE_CE, loc, NULL);
		World::Inferences::draw(IS_ROOM_INF, bd, IMPOSSIBLE_CE, NULL, NULL);
		World::Inferences::draw(FOUND_IN_INF, bd, CERTAIN_CE, loc, loc);
		return TRUE;
	}

	return FALSE;
}

@ For indexing purposes, the following loops are useful:

@d LOOP_OVER_BACKDROPS_IN(B, P, I)
	LOOP_OVER_OBJECT_INSTANCES(B)
		if (PL::Backdrops::object_is_a_backdrop(B))
			POSITIVE_KNOWLEDGE_LOOP(I, Instances::as_subject(B), FOUND_IN_INF)
				if (World::Inferences::get_reference_as_object(I) == P)

@d LOOP_OVER_BACKDROPS_EVERYWHERE(B, I)
	LOOP_OVER_OBJECT_INSTANCES(B)
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
	if ((ParseTree::get_type(py) == EVERY_NT) &&
		(<notable-backdrops-noun-phrases>(ParseTree::get_text(py)))) {
		inference_subject *left_subject = ParseTree::get_subject(px);
		if (left_subject == NULL)
			Problems::Issue::assertion_problem(_p_(PM_ValueEverywhere),
				"'everywhere' can only be used to place individual backdrops",
				"so although 'The mist is a backdrop. The mist is everywhere.' "
				"would be fine, 'Corruption is everywhere.' would not.");
		else if (InferenceSubjects::domain(left_subject))
			Problems::Issue::subject_problem_at_sentence(_p_(PM_KindOfBackdropEverywhere),
				left_subject,
				"seems to be said to be 'everywhere' in some way",
				"which doesn't make sense. An individual backdrop can be 'everywhere', "
				"but here we're talking about a whole kind, and it's not allowed "
				"to talk about general locations of a whole kind of things at once.");
		else Calculus::Propositions::Assert::assert_true_about(
			Calculus::Propositions::Abstract::to_put_everywhere(), left_subject, prevailing_mood);
		return TRUE;
	}
	return FALSE;
}

@ And this is where it makes the necessary inference after such a request has
been asserted true:

=
void PL::Backdrops::infer_presence_everywhere(instance *I) {
	if ((I == NULL) || (Instances::of_kind(I, K_backdrop) == FALSE)) {
		Problems::Issue::sentence_problem(_p_(PM_EverywhereNonBackdrop),
			"only a backdrop can be everywhere",
			"and no other kind of object will do. For instance, 'The sky is "
			"a backdrop which is everywhere.' is allowed, but 'The travelator "
			"is a vehicle which is everywhere.' is not.");
		return;
	}
	World::Inferences::draw(FOUND_EVERYWHERE_INF,
		Instances::as_subject(I), prevailing_mood, NULL, NULL);
}

@h Model completion.
We intervene only at Stage II, the spatial modelling stage.

=
int PL::Backdrops::backdrops_complete_model(int stage) {
	if (stage == 2) {
		P_absent = Properties::EitherOr::new_nameless(L"absent");
		Properties::EitherOr::implement_as_attribute(P_absent, TRUE);
		instance *I;
		LOOP_OVER_OBJECT_INSTANCES(I) {
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
		instance *loc = World::Inferences::get_reference_as_object(inf);
		if ((K_region) && (Instances::of_kind(loc, K_region))) region_count++;
		else room_count++;
	}

@<The object is found only in a few rooms, and no regions, so make it a list@> =
	package_request *PR = Hierarchy::package_within(INLINE_PROPERTIES_HAP, Instances::package(I));
	FOUNDIN = Hierarchy::make_iname_in(INLINE_PROPERTY_HL, PR);
	packaging_state save = Packaging::enter_home_of(FOUNDIN);
	Emit::named_array_begin(FOUNDIN, K_value);
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, Instances::as_subject(I), FOUND_IN_INF)
		Emit::array_iname_entry(Instances::iname(World::Inferences::get_reference_as_object(inf)));
	Emit::array_end();
	InterNames::annotate_i(FOUNDIN, INLINE_ARRAY_IANN, 1);
	Packaging::exit(save);

@<The object is found in many rooms or in whole regions, so make it a routine@> =
	backdrop_found_in_notice *notice = CREATE(backdrop_found_in_notice);
	notice->backdrop = I;
	package_request *R = Instances::package(I);
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
	package_request *R = Instances::package(I);
	notice->found_in_routine_iname = Hierarchy::make_iname_in(BACKDROP_FOUND_IN_FN_HL, R);
	notice->many_places = FALSE;
	FOUNDIN = notice->found_in_routine_iname;
	Properties::EitherOr::assert(
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
		instance *loc = World::Inferences::get_reference_as_object(inf);
		Emit::inv_primitive(if_interp);
		Emit::down();
		if ((K_region) && (Instances::of_kind(loc, K_region))) {
			Emit::inv_call_iname(Hierarchy::find(TESTREGIONALCONTAINMENT_HL));
			Emit::down();
				Emit::val_iname(K_object, Hierarchy::find(LOCATION_HL));
				Emit::val_iname(K_object, Instances::iname(loc));
			Emit::up();
		} else {
			Emit::inv_primitive(eq_interp);
			Emit::down();
				Emit::val_iname(K_object, Hierarchy::find(LOCATION_HL));
				Emit::val_iname(K_object, Instances::iname(loc));
			Emit::up();
		}
			Emit::code();
			Emit::down();
				Emit::rtrue();
			Emit::up();
		Emit::up();
		Emit::rfalse();
		break;
	}
	Routines::end(save);

@<The object is found nowhere@> =
	packaging_state save = Routines::begin(notice->found_in_routine_iname);
	Emit::rfalse();
	Routines::end(save);
