[World::] Complete Model World.

Once the assertions have all been read and reduced to inferences,
and all the creations have been made, we take stock; sometimes we spot
inconsistencies, sometimes we make deductions, and we try to complete our
picture of the model world.

@h Stages II to IV.
The process of using existing facts to infer new ones is vulnerable
to timing bugs, so we organise the "making" process into five numbered
stages, given the Roman numerals I to V. Much of the work is done by plugins,
which can take a hand at any or all of the stages, using their contextual
knowledge to fill in missing properties.

(I) Deducing the kind of any object whose kind is not known. Because this
can result in a change of kind, which can result in further creations by
assembly sentences like "A handle is part of every door", Stage I takes
place at the end of traverse 2 of the source text and, uniquely, gets the
opportunity to add fresh sentences to the source -- thus extending the
traverse. By the end of Stage I, all kinds are fixed.

(II) Stages II and III are for adding further properties or relationships,
which aren't explicit in the source text but which plugins can add on the
basis of contextual understanding. (Two stages are provided here to avoid
timing issues where one plugin has to act earlier than another.)

(III) See (II). If a plugin is going to change the compilation order of
the objects (as the spatial-model plugin does), it must do so during
Stage III.

(IV) A stage for consistency checks or to store away useful data, but where
nothing in the model may be changed -- no properties or relationships
may be added. (Except that the instance-counting plugin is allowed to
add the linked-lists-of-instances properties, used to optimise loops
at run-time; they aren't visible at the I7 level so aren't properly
part of the model world.)

(V) A final chance to add properties which will assist the run-time
implementation of, for instance, the command grammar, but again aren't
really part of the model world. (This can't be done earlier since the
command grammar isn't parsed until after |World::complete|; and we
aren't allowed to add I7-accessible properties.)

The following routine, then, carries out stages II, III and IV.

=
void World::complete(void) {
	@<Stages II and III of the completion process@>;
	@<Stage IV of the completion process@>;
}

@ The model world is a broth with many cooks. On the one hand, we have the
various different INFSs, with their different needs -- a various-to-various
relation, a global variable, and so on -- and on the other hand we also
have the plugins, each of which takes its own global view of the situation.
We give everyone a turn.

@<Stages II and III of the completion process@> =
	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) {
		InferenceSubjects::complete_model(infs);
		Properties::Appearance::reallocate(infs);
	}
	LOOP_OVER(infs, inference_subject)
		Assertions::Implications::consider_all(infs);
	Plugins::Call::complete_model(2);
	Plugins::Call::complete_model(3);

@ Checking what we have, then. Once again each INFS is given an opportunity
to check itself, and then the plugins have a turn.

@<Stage IV of the completion process@> =
	inference_subject *infs;
	LOOP_OVER(infs, inference_subject) {
		InferenceSubjects::check_model(infs);
		@<Check that properties are permitted@>;
		@<Check that properties are not contradictory@>;
	}
	Plugins::Call::complete_model(4);

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
	KNOWLEDGE_LOOP(inf, infs, PROPERTY_INF) {
		property *prn = World::Inferences::get_property(inf);
		if (Wordings::nonempty(prn->name))
			if (World::Permissions::find(infs, prn, TRUE) == NULL)
				StandardProblems::inference_problem(_p_(PM_PropertyNotPermitted),
					infs, inf, "is not allowed to exist",
					"because you haven't said it is. What properties something can "
					"have depends on what kind of thing it is: see the Index for "
					"details.");
	}

@ The following contradiction checks do not apply to properties added
in Stages II and III, since those are often I6 hacks added for run-time
convenience, and don't have to follow the I7 rules.

@<Check that properties are not contradictory@> =
	inference *narrow;
	KNOWLEDGE_LOOP(narrow, infs, PROPERTY_INF) {
		if (World::Inferences::added_in_construction(narrow) == FALSE) {
			property *prn = World::Inferences::get_property(narrow);
			int sign = 1;
			if (World::Inferences::get_certainty(narrow) < 0) sign = -1;
			@<Look for clashes concerning this property from wider inferences@>;
			if ((Properties::is_either_or(prn)) && (Properties::EitherOr::get_negation(prn))) {
				prn = Properties::EitherOr::get_negation(prn);
				sign = -sign;
				@<Look for clashes concerning this property from wider inferences@>;
			}
		}
	}

@<Look for clashes concerning this property from wider inferences@> =
	inference_subject *boss = InferenceSubjects::narrowest_broader_subject(infs);
	while (boss) {
		inference *wide;
		KNOWLEDGE_LOOP(wide, boss, PROPERTY_INF)
			if (World::Inferences::added_in_construction(wide) == FALSE)
				if (prn == World::Inferences::get_property(wide))
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
	int abcw = World::Inferences::get_certainty(wide); if (abcw < 0) abcw = -abcw;
	if (abcw == CERTAIN_CE) {
		int clash = FALSE;
		int wide_sign = 1; if (World::Inferences::get_certainty(wide) < 0) wide_sign = -1;
		if (Properties::is_either_or(prn) == FALSE) {
			parse_node *narrow_val = World::Inferences::get_property_value(narrow);
			parse_node *wide_val = World::Inferences::get_property_value(wide);
			if (Rvalues::compare_CONSTANT(narrow_val, wide_val) == FALSE) {
				LOG("Clash of $P and $P\n  $I\n  $I\n",
					narrow_val, wide_val, narrow, wide);
				clash = TRUE;
			}
		}
		if (sign != wide_sign) clash = (clash)?FALSE:TRUE;
		if (clash) {
			int abcn = World::Inferences::get_certainty(narrow); if (abcn < 0) abcn = -abcn;
			if (abcn == CERTAIN_CE)
				 @<Issue a problem message for clash with wider inference@>
			else
				World::Inferences::set_certainty(narrow, IMPOSSIBLE_CE);
		}
	}

@<Issue a problem message for clash with wider inference@> =
	LOG("Checking infs $j compatible with infs $j for property $Y:\n  $I\n  $I\n",
		infs, boss, prn, narrow, wide);
	StandardProblems::infs_contradiction_problem(_p_(PM_InstanceContradiction),
		World::Inferences::where_inferred(narrow), World::Inferences::where_inferred(wide), infs,
		"therefore has to have two contradictory states of the same property at once",
		"which is impossible. When a kind's definition says that something is 'always' "
		"true, there is no way to override that for particular things of the kind.");

@h Stage V.
See above. This is for the use of plugins only.

=
void World::complete_additions(void) {
	Plugins::Call::complete_model(5);
}
