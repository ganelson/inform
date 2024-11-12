[World::] The Model World.

Once the assertions have all been read and reduced to inferences,
we try to complete our model world.

@h Introduction.
World-building has five stages, written with Roman numerals I to V in this
source code. The logic in this section is all quite simple, but plugins are
allowed to intervene at each of the five stages, bringing domain-specific
wisdom to the process.

@d WORLD_STAGE_I     1  /* Deduce kinds for object instances */
@d WORLD_STAGE_II    2  /* First chance to add further properties or relationships */
@d WORLD_STAGE_III   3  /* Second chance to add further properties or relationships */
@d WORLD_STAGE_IV    4  /* Perform mutual consistency checks */
@d WORLD_STAGE_V     5  /* Post-game: only implementation details can be added */

=
int current_model_world_stage = 0; /* not yet building the world model */

void World::ask_plugins_at_stage(int S) {
	if (S != current_model_world_stage + 1) internal_error("Stage mistimed");
	current_model_world_stage = S;
	PluginCalls::complete_model(S);
}

int World::current_building_stage(void) {
	return current_model_world_stage;
}

@h Stage I.
Deducing the kind of any object whose kind is not known. The core compiler
has already done the best it can, but then it lacks domain-specific
understanding. So the only business done is by plugins, which understand
certain kinds and relationships better.

Some instances change their kinds in Stage I, and this can result in further
creations by assembly sentences like "A handle is part of every door". Because
of that, Stage I takes place at the end of traverse 2 of the source text and,
uniquely, gets the opportunity to add fresh sentences to the source -- thus
extending the traverse. But by the end of Stage I, all kinds are fixed, and
no further instances can be created.

=
void World::deduce_object_instance_kinds(void) {
	World::ask_plugins_at_stage(WORLD_STAGE_I);
}

@h Stages II and III.
This is an opportunity for plugins to add further properties or relationships
on the basis of contextual understanding. Two stages, and thus two opportunities,
are provided here to avoid timing issues where one plugin has to act earlier
than another.

If a plugin is going to change the compilation order of the objects (as the
spatial-model plugin does), it must do so during Stage III, not Stage II.

=
void World::stages_II_and_III(void) {
	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) {
		InferenceSubjects::complete_model(infs);
		Properties::Appearance::reallocate(infs);
	}
	LOOP_OVER(infs, inference_subject)
		Assertions::Implications::consider_all(infs);
	World::ask_plugins_at_stage(WORLD_STAGE_II);
	World::ask_plugins_at_stage(WORLD_STAGE_III);
	additional_property_set *set;
	LOOP_OVER(set, additional_property_set) {
		text_stream *O = set->owner_name;
		wording W = Feeds::feed_text(O);
		if (<k-kind>(W)) {
			kind *K = <<rp>>;
			additional_property *ap;
			LOOP_OVER_LINKED_LIST(ap, additional_property, set->properties) {
				property *P;
				if (ap->attr) P = EitherOrProperties::new_nameless(ap->property_name);
				else P = ValueProperties::new_nameless(ap->property_name, K_value);
				inter_pair val = InterValuePairs::number_from_I6_notation(ap->value_text, NULL);
				if (InterValuePairs::is_undef(val)) {
					Problems::quote_stream(1, O);
					Problems::quote_stream(2, ap->property_name);
					Problems::quote_stream(3, ap->value_text);
					StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
					Problems::issue_problem_segment(
						"A Neptune file inside one of the kits you're using says "
						"that the kind '%1' should have the Inter-level property '%2' "
						"set to '%3', but I can't read that value.");
					Problems::issue_problem_end();
				}
				int V = (int) InterValuePairs::to_number(val);
				if (ap->attr) {
					int parity = TRUE;
					if (V == 0) parity = FALSE;
					EitherOrProperties::assert(P, KindSubjects::from_kind(K), parity, LIKELY_CE);
				} else {
					parse_node *R = Rvalues::from_int(V, EMPTY_WORDING);
					ValueProperties::assert(P, KindSubjects::from_kind(K), R, CERTAIN_CE);
				}
			}
		} else {
			Problems::quote_stream(1, O);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
			Problems::issue_problem_segment(
				"A Neptune file inside one of the kits you're using says "
				"that the kind '%1' should have certain Inter-level properties, "
				"but no such kind seems to exist.");
			Problems::issue_problem_end();
		}
	}
}

@h Stage IV.
This is for consistency checks or to store away useful data, but where
nothing in the model may be changed -- no properties or relationships
may be added.

=
void World::stage_IV(void) {
	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) {
		InferenceSubjects::check_model(infs);
		@<Check that properties are permitted@>;
		@<Check that properties are not contradictory@>;
		@<Check that relations are permitted@>;
	}
	World::ask_plugins_at_stage(WORLD_STAGE_IV);
}

@ These two checks may seem a little odd. After all, we've been throwing out
impossible inferences with problem messages all along, while reading the
source text. Why not perform these checks then, too?

The answer is that both depend not only on the subject of the inferences
made, but also on what that subject inherits from. Suppose we are told:

>> The cup is in the Yellow Cupboard. The Cupboard is lighted.

When we make the "lighted" inference, we know for certain what subject
it's about -- the Yellow Cupboard -- but not where this lives in the
inference-subject hierarchy, because that depends on the kind of the
Cupboard. Is it a room, or a container? We don't yet know (and won't until
Stage I of model-completion), so we aren't in a position to judge whether
or not it's permitted to have the property "lighted". This is why the
check is postponed until after Stage I, and it seems natural to perform
it here in Stage IV, so that we also catch any accidents due to bugs
in plugins which add inconsistent properties.

A nameless property added in Stages II and III does not need permission.

@<Check that properties are permitted@> =
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, property_inf) {
		property *prn = PropertyInferences::get_property(inf);
		if (Wordings::nonempty(prn->name))
			if (PropertyPermissions::find(infs, prn, TRUE) == NULL)
				StandardProblems::inference_problem(_p_(PM_PropertyNotPermitted),
					infs, inf, "is not allowed to exist",
					"because you haven't said it is. What properties something can "
					"have depends on what kind of thing it is: see the Index for "
					"details.");
	}

@ The following contradiction checks do not apply to properties added
in Stages II and III, since those are often Inter hacks added for run-time
convenience, and don't have to follow the I7 rules.

@<Check that properties are not contradictory@> =
	inference *narrow;
	KNOWLEDGE_LOOP(narrow, infs, property_inf) {
		if (Inferences::during_stage(narrow) == 0) {
			property *prn = PropertyInferences::get_property(narrow);
			int sign = 1;
			if (Inferences::get_certainty(narrow) < 0) sign = -1;
			@<Look for clashes concerning this property from wider inferences@>;
			if ((Properties::is_either_or(prn)) &&
				(EitherOrProperties::get_negation(prn))) {
				prn = EitherOrProperties::get_negation(prn);
				sign = -sign;
				@<Look for clashes concerning this property from wider inferences@>;
			}
		}
	}

@<Look for clashes concerning this property from wider inferences@> =
	inference_subject *boss = InferenceSubjects::narrowest_broader_subject(infs);
	while (boss) {
		inference *wide;
		KNOWLEDGE_LOOP(wide, boss, property_inf)
			if (Inferences::during_stage(wide) == 0)
				if (prn == PropertyInferences::get_property(wide))
					@<Check that these differently scoped inferences do not clash@>;
		boss = InferenceSubjects::narrowest_broader_subject(boss);
	}

@ It's never a problem when a vague fact about something general is contradicted
by a fact about something specific; the problem comes with something like this:

>> A door is always open. The Marble Portal is a closed door.

Here the "wide" property inference, for the "door" kind, is |CERTAIN_CE|
rather than |LIKELY_CE|, and so we can't allow the "narrow" inference,
about the Portal, to stand.

@<Check that these differently scoped inferences do not clash@> =
	int abcw = Inferences::get_certainty(wide); if (abcw < 0) abcw = -abcw;
	if (abcw == CERTAIN_CE) {
		int clash = FALSE;
		int wide_sign = 1; if (Inferences::get_certainty(wide) < 0) wide_sign = -1;
		if (Properties::is_either_or(prn) == FALSE) {
			parse_node *narrow_val = PropertyInferences::get_value(narrow);
			parse_node *wide_val = PropertyInferences::get_value(wide);
			if (Rvalues::compare_CONSTANT(narrow_val, wide_val) == FALSE) {
				LOG("Clash of $P and $P\n  $I\n  $I\n",
					narrow_val, wide_val, narrow, wide);
				clash = TRUE;
			}
		}
		if (sign != wide_sign) clash = (clash)?FALSE:TRUE;
		if (clash) {
			int abcn = Inferences::get_certainty(narrow); if (abcn < 0) abcn = -abcn;
			if (abcn == CERTAIN_CE)
				 @<Issue a problem message for clash with wider inference@>
			else
				Inferences::render_impossible(narrow);
		}
	}

@<Issue a problem message for clash with wider inference@> =
	LOG("Checking infs $j compatible with infs $j for property $Y:\n  $I\n  $I\n",
		infs, boss, prn, narrow, wide);
	StandardProblems::infs_contradiction_problem(_p_(PM_InstanceContradiction),
		Inferences::where_inferred(narrow), Inferences::where_inferred(wide), infs,
		"therefore has to have two contradictory states of the same property at once",
		"which is impossible. When a kind's definition says that something is 'always' "
		"true, there is no way to override that for particular things of the kind.");

@ This is a last line of defence. Suppose we define "to connect to" as a relation
between things and things, and then write "X connects to Y". Inform must clearly
check that X and Y are both things. It does indeed make some checks along those
lines earlier on in compilation, but there are objects whose kinds are not known
until model completion time -- in particular, there can be objects which might
be things or might be rooms, so that we cannot know if "X connects to Y" is
legal until after the model is completed.

But that's now! And so we make one last check, just in case.

@<Check that relations are permitted@> =
	inference *inf;
	POSITIVE_KNOWLEDGE_LOOP(inf, infs, relation_inf) {
		binary_predicate *bp = RelationSubjects::to_bp(infs);
		inference_subject *left_infs = NULL;
		inference_subject *right_infs = NULL;
		RelationInferences::get_term_subjects(inf, &left_infs, &right_infs);
		instance *left_instance = InstanceSubjects::to_instance(left_infs);
		instance *right_instance = InstanceSubjects::to_instance(right_infs);
		kind *left_kind = Instances::to_kind(left_instance);
		kind *right_kind = Instances::to_kind(right_instance);
		kind *left_needed_kind = BinaryPredicates::term_kind(bp, 0);
		kind *right_needed_kind = BinaryPredicates::term_kind(bp, 1);
		if ((left_instance) && (Kinds::conforms_to(left_kind, left_needed_kind) == FALSE)) {
			current_sentence = Inferences::where_inferred(inf);
			Problems::quote_source(1, current_sentence);
			Problems::quote_object(2, left_instance);
			Problems::quote_kind(3, left_kind);
			Problems::quote_kind(4, left_needed_kind);
			Problems::quote_kind(5, right_needed_kind);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_LateLeftTermWrongKind));
			Problems::issue_problem_segment(
				"You wrote %1, but I think the kind of %2 is %3, and not %4, "
				"which is what this relationship would need it to be. (It "
				"relates %4 to %5.)");
			Problems::issue_problem_end();
		}
		if ((right_instance) && (Kinds::conforms_to(right_kind, right_needed_kind) == FALSE)) {
			current_sentence = Inferences::where_inferred(inf);
			Problems::quote_source(1, current_sentence);
			Problems::quote_object(2, right_instance);
			Problems::quote_kind(3, right_kind);
			Problems::quote_kind(4, left_needed_kind);
			Problems::quote_kind(5, right_needed_kind);
			StandardProblems::handmade_problem(Task::syntax_tree(),
				_p_(PM_LateRightTermWrongKind));
			Problems::issue_problem_segment(
				"You wrote %1, but I think the kind of %2 is %3, and not %5, "
				"which is what this relationship would need it to be. (It "
				"relates %4 to %5.)");
			Problems::issue_problem_end();
		}
	}

@h Stage V.
A final chance to add properties which may assist the run-time implementation
of whatever a plugin is concerned with, but which is not allowed to make
changes to the model as it would be understood by the author.

For example, the //runtime: Instance Counting// plugin adds low-level properties
to improve run-time performance, but they have no names and cannot be referred
to or accessed by code written in Inform 7; they exist at the level of Inter only.

=
void World::stage_V(void) {
	World::ask_plugins_at_stage(WORLD_STAGE_V);
}
