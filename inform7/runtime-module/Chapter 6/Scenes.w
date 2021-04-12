[RTScenes::] Scenes.

Compiling code to manage scene changes at run-time.

@ At run-time, we need to store information about the current state of each
scene: whether it is currently playing or not, when the last change occurred,
and so on. This data is stored in I6 arrays as follows:

First, each scene has a unique ID number, used as an index |X| to these arrays.
This ID number is what is stored as an I6 value for the kind of value |scene|,
and it agrees with the allocation ID for the I7 scene structure.

|scene_status-->X| is 0 if the scene is not playing, but may do so in future;
1 if the scene is playing; or 2 if the scene is not playing and will never
play again.

|scene_started-->X| is the value of |the_time| when the scene last started,
or 0 if it has never started.

|scene_ended-->X| is the value of |the_time| when the scene last ended,
or 0 if it has never ended. (The "starting" end does not count as ending
for this purpose.)

|scene_endings-->X| is a bitmap recording which ends have been used,
including bit 1 which records whether the scene has started.

|scene_latest_ending-->X| holds the end number of the most recent ending
(or 0 if the scene has never ended).

@h Scene-changing machinery at run-time.
So what are scenes for? Well, they have two uses. One is that the end
rulebooks are run when ends occur, which is a convenient way to time events.
The following generates the necessary code to (a) detect when a scene end
occurs, and (b) act upon it. This is all handled by the following Inter
function.

There is one argument, |chs|: the number of iterations so far. Iterations
occur because each set of scene changes could change the circumstances in such
a way that other scene changes are now required (through external conditions,
not through anchors); we don't want this to lock up, so we will cap recursion.
Within the routine, a second local variable, |ch|, is a flag indicating
whether any change in status has or has not occurred.

There is no significance to the return value.

@d MAX_SCENE_CHANGE_ITERATION 20

=
void RTScenes::DetectSceneChange_routine(void) {
	inter_name *iname = Hierarchy::find(DETECTSCENECHANGE_HL);
	packaging_state save = Functions::begin(iname);
	inter_symbol *chs_s =
		LocalVariables::new_internal_commented_as_symbol(I"chs", I"count of changes made");
	inter_symbol *ch_s =
		LocalVariables::new_internal_commented_as_symbol(I"ch", I"flag: change made");
	inter_symbol *CScene_l = Produce::reserve_label(Emit::tree(), I".CScene");

	scene *sc;
	LOOP_OVER(sc, scene) @<Compile code detecting the ends of a specific scene@>;

	Produce::place_label(Emit::tree(), CScene_l);
	@<Add the scene-change tail@>;

	Functions::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@<Add the scene-change tail@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), GT_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, chs_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
				(inter_ti) MAX_SCENE_CHANGE_ITERATION);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), PRINT_BIP);
			Emit::down();
				Produce::val_text(Emit::tree(), I">--> The scene change machinery is stuck.\n");
			Emit::up();
			Produce::rtrue(Emit::tree());
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), GT_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, ch_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_call_iname(Emit::tree(), iname);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), PREINCREMENT_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, chs_s);
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::rfalse(Emit::tree());

@ Recall that ends numbered 1, 2, 3, ... are all ways for the scene to end,
so they are only checked if its status is currently running; end 0 is the
beginning, checked only if it isn't. We give priority to the higher end
numbers so that more abstruse ways to end take precedence over less.

@<Compile code detecting the ends of a specific scene@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Emit::down();
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCENE_STATUS_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
			Emit::up();
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			for (int end=sc->no_ends-1; end>=1; end--)
				RTScenes::test_scene_end(sc, end, ch_s, CScene_l);
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Emit::down();
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCENE_STATUS_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
			Emit::up();
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			RTScenes::test_scene_end(sc, 0, ch_s, CScene_l);
		Emit::up();
	Emit::up();

@ Individual ends are tested here. There are actually three ways an end can
occur: at start of play (for end 0 only), when an I7 condition holds, or when
another end to which it is anchored also ends. But we only check the first
two, because the third way will be taken care of by the consequences code
below.

=
void RTScenes::test_scene_end(scene *sc, int end, inter_symbol *ch_s, inter_symbol *CScene_l) {
	if ((end == 0) && (sc->start_of_play)) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), BITWISEAND_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
					Emit::down();
						Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCENE_ENDINGS_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				RTScenes::compile_scene_end(sc, 0);
			Emit::up();
		Emit::up();
	}
	parse_node *S = sc->ends[end].anchor_condition;
	if (S) {
		@<Reparse the scene end condition in this new context@>;
		@<Compile code to test the scene end condition@>;
	}
}

@<Reparse the scene end condition in this new context@> =
	current_sentence = sc->ends[end].anchor_condition_set;
	if (Node::is(S, UNKNOWN_NT)) {
		if (<s-condition>(Node::get_text(S))) S = <<rp>>;
		sc->ends[end].anchor_condition = S;
	}
	if (Node::is(S, UNKNOWN_NT)) {
		LOG("Condition: $P\n", S);
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ScenesBadCondition),
			"'begins when' and 'ends when' must be followed by a condition",
			"which this does not seem to be, or else 'when play begins', "
			"'when play ends', 'when S begins', or 'when S ends', where "
			"S is the name of any scene.");
		return;
	}

	if (Dash::check_condition(S) == FALSE) return;

@ If the condition holds, we set the change flag |ch| and abort the search
through scenes by jumping past the run of tests. (We can't compile a break
instruction because we're not compiling a loop.)

@<Compile code to test the scene end condition@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		current_sentence = sc->ends[end].anchor_condition_set;
		CompileValues::to_code_val_of_kind(S, K_truth_state);
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, ch_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
			Emit::up();
			RTScenes::compile_scene_end(sc, end);
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), CScene_l);
			Emit::up();
		Emit::up();
	Emit::up();

@ That's everything except for the consequences of a scene end occurring.
Code for that is generated here.

Because one end can cause another, given anchoring, we must guard against
compiler hangs when the source text calls for infinite recursion (since
this would cause us to generate infinitely long code). So the |marker| flags
are used to mark which scenes have already been ended in code generated
for this purpose.

=
void RTScenes::compile_scene_end(scene *sc, int end) {
	scene *sc2;
	LOOP_OVER(sc2, scene) sc2->marker = 0;
	RTScenes::compile_scene_end_dash(sc, end);
}

@ The semantics of scene ending are trickier than they look, because of the
fact that "Ballroom Dance ends merrily" (say, end number 3) is in some
sense a specialisation of "Ballroom Dance ends" (1). The doctrine is that
end 3 causes end 1 to happen first, because a special ending is also a
general ending; but rules taking effect on end 3 come earlier than
those for end 1, because they're more specialised, so they have a right to
take effect first.

=
void RTScenes::compile_scene_end_dash(scene *sc, int end) {
	int ix = sc->allocation_id;
	sc->marker++;
	if (end >= 2) {
		int e = end; end = 1;
		@<Compile code to print text in response to the SCENES command@>;
		@<Compile code to update the scene status@>;
		@<Compile code to update the arrays recording most recent scene ending@>;
		end = e;
	}
	@<Compile code to print text in response to the SCENES command@>;
	@<Compile code to update the scene status@>;
	@<Compile code to run the scene end rulebooks@>
	@<Compile code to update the arrays recording most recent scene ending@>;
	@<Compile code to cause consequent scene ends@>;

	if (end >= 2) {
		int e = end; end = 1;
		@<Compile code to run the scene end rulebooks@>;
		@<Compile code to cause consequent scene ends@>;
		end = e;
	}
}

@ If the scene has the "recurring" either/or property, then any of the
"ends" endings will fail to reset its status. (This doesn't mean that no
end actually occurred.)

@<Compile code to update the scene status@> =
	if (end == 0) {
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
			Emit::down();
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_STATUS_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
			Emit::up();
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Emit::up();
	} else {
		Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
		Emit::down();
			inter_name *iname = Hierarchy::find(GPROPERTY_HL);
			Produce::inv_call_iname(Emit::tree(), iname);
			Emit::down();
				RTKinds::emit_weak_id_as_val(K_scene);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) ix+1);
				Produce::val_iname(Emit::tree(), K_value, RTProperties::iname(P_recurring));
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
					Emit::down();
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_STATUS_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
				Emit::up();
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
					Emit::down();
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_STATUS_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 2);
				Emit::up();
			Emit::up();
		Emit::up();
	}

@<Compile code to run the scene end rulebooks@> =
	if (end == 0) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(FOLLOWRULEBOOK_HL));
		Emit::down();
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WHEN_SCENE_BEGINS_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (sc->allocation_id + 1));
		Emit::up();
	}
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(FOLLOWRULEBOOK_HL));
	Emit::down();
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (sc->ends[end].end_rulebook->allocation_id));
	Emit::up();
	if (end == 1) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(FOLLOWRULEBOOK_HL));
		Emit::down();
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(WHEN_SCENE_ENDS_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (sc->allocation_id + 1));
		Emit::up();
	}

@<Compile code to update the arrays recording most recent scene ending@> =
	inter_name *sarr = Hierarchy::find(SCENE_ENDED_HL);
	if (end == 0) sarr = Hierarchy::find(SCENE_STARTED_HL);
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
		Emit::down();
			Produce::val_iname(Emit::tree(), K_value, sarr);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
		Emit::up();
		Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(THE_TIME_HL));
	Emit::up();

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
		Emit::down();
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_ENDINGS_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
		Emit::up();
		Produce::inv_primitive(Emit::tree(), BITWISEOR_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Emit::down();
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_ENDINGS_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
			Emit::up();
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (1 << end));
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
		Emit::down();
			Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_LATEST_ENDING_HL));
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
		Emit::up();
		Produce::val(Emit::tree(), K_value, LITERAL_IVAL, (inter_ti) end);
	Emit::up();

@<Compile code to print text in response to the SCENES command@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(DEBUG_SCENES_HL));
		Produce::code(Emit::tree());
		Emit::down();
			TEMPORARY_TEXT(OUT)
			WRITE("[Scene '");
			if (sc->as_instance) WRITE("%+W", Instances::get_name(sc->as_instance, FALSE));
			WRITE("' ");
			if (end == 0) WRITE("begins"); else WRITE("ends");
			if (end >= 2) WRITE(" %+W", sc->ends[end].end_names);
			WRITE("]\n");
			Produce::inv_primitive(Emit::tree(), PRINT_BIP);
			Emit::down();
				Produce::val_text(Emit::tree(), OUT);
			Emit::up();
			DISCARD_TEXT(OUT)
		Emit::up();
	Emit::up();

@ In general, the marker count is used to ensure that |RTScenes::compile_scene_end_dash|
never calls itself for a scene it has been called with before on this round.
This prevents Inform locking up generating infinite amounts of code. However,
one exception is allowed, in very limited circumstances. Suppose we want to
make a scene recur, but only if it ends in a particular way. Then we might
type:

>> Brisk Quadrille begins when Brisk Quadrille ends untidily.

This is allowed; it's a case where the "tolerance" below is raised.

@<Compile code to cause consequent scene ends@> =
	scene *other_scene;
	LOOP_OVER(other_scene, scene) {
		int tolerance = 1;
		if (sc == other_scene) tolerance = sc->no_ends;
		if (other_scene->marker < tolerance) {
			int other_end;
			for (other_end = 0; other_end < other_scene->no_ends; other_end++) {
				scene_connector *scon;
				for (scon = other_scene->ends[other_end].anchor_connectors; scon; scon = scon->next) {
					if ((scon->connect_to == sc) && (scon->end == end)) {
						Produce::inv_primitive(Emit::tree(), IF_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), EQ_BIP);
							Emit::down();
								Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
								Emit::down();
									Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_STATUS_HL));
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) other_scene->allocation_id);
								Emit::up();
								if (other_end >= 1)
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
								else
									Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
							Emit::up();
							Produce::code(Emit::tree());
							Emit::down();
								RTScenes::compile_scene_end_dash(other_scene, other_end);
							Emit::up();
						Emit::up();
					}
				}
			}
		}
	}

@h More SCENES output.
As we've seen, when the SCENES command has been typed, Inform prints a notice
out at run-time when any scene end occurs. It also prints a run-down of the
scene status at the moment the command is typed, and the following code is
what handles this.

=
void RTScenes::ShowSceneStatus_routine(void) {
	inter_name *iname = Hierarchy::find(SHOWSCENESTATUS_HL);
	packaging_state save = Functions::begin(iname);
	Produce::inv_primitive(Emit::tree(), IFDEBUG_BIP);
	Emit::down();
		Produce::code(Emit::tree());
		Emit::down();
			scene *sc;
			LOOP_OVER(sc, scene) {
				wording NW = Instances::get_name(sc->as_instance, FALSE);

				Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), EQ_BIP);
					Emit::down();
						Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
						Emit::down();
							Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCENE_STATUS_HL));
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
						Emit::up();
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						@<Show status of this running scene@>;
					Emit::up();
					Produce::code(Emit::tree());
					Emit::down();
						@<Show status of this non-running scene@>;
					Emit::up();
				Emit::up();
			}
		Emit::up();
	Emit::up();
	Functions::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@<Show status of this running scene@> =
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "Scene '%+W' playing (for ", NW);
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Emit::down();
		Produce::val_text(Emit::tree(), T);
	Emit::up();
	DISCARD_TEXT(T)

	Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), MINUS_BIP);
		Emit::down();
			Produce::val_iname(Emit::tree(), K_number, Hierarchy::find(THE_TIME_HL));
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Emit::down();
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCENE_STARTED_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Emit::down();
		Produce::val_text(Emit::tree(), I" mins now)\n");
	Emit::up();

@<Show status of this non-running scene@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), GT_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Emit::down();
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCENE_LATEST_ENDING_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
			Emit::up();
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			@<Show status of this recently ended scene@>;
		Emit::up();
	Emit::up();

@<Show status of this recently ended scene@> =
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "Scene '%+W' ended", NW);
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Emit::down();
		Produce::val_text(Emit::tree(), T);
	Emit::up();
	DISCARD_TEXT(T)

	if (sc->no_ends > 2) {
		Produce::inv_primitive(Emit::tree(), SWITCH_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
			Emit::down();
				Produce::val_iname(Emit::tree(), K_object, Hierarchy::find(SCENE_LATEST_ENDING_HL));
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				for (int end=2; end<sc->no_ends; end++) {
					Produce::inv_primitive(Emit::tree(), CASE_BIP);
					Emit::down();
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) end);
						Produce::code(Emit::tree());
						Emit::down();
							TEMPORARY_TEXT(T)
							WRITE_TO(T, " %+W", sc->ends[end].end_names);
							Produce::inv_primitive(Emit::tree(), PRINT_BIP);
							Emit::down();
								Produce::val_text(Emit::tree(), T);
							Emit::up();
							DISCARD_TEXT(T)
						Emit::up();
					Emit::up();
				}
			Emit::up();
		Emit::up();
	}

	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Emit::down();
		Produce::val_text(Emit::tree(), I"\n");
	Emit::up();

@h During clauses.
We've now seen one use of scenes: they kick off rulebooks when they begin or
end. The other use for them is to predicate rules on whether they are currently
playing or not, using a "during" clause.

This is where we compile Inter code to test that a scene matching this is
actually running:

=
void RTScenes::emit_during_clause(parse_node *spec) {
	int stuck = TRUE;
	if (K_scene == NULL) { Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1); return; }
	if (Rvalues::is_rvalue(spec)) {
		Dash::check_value(spec, K_scene);
		instance *I = Rvalues::to_instance(spec);
		if (Instances::of_kind(I, K_scene)) {
			scene *sc = Scenes::from_named_constant(I);
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SCENE_STATUS_HL));
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc->allocation_id);
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
			Emit::up();
			stuck = FALSE;
		}
	} else {
		if (Dash::check_value(spec, Kinds::unary_con(CON_description, K_scene)) == ALWAYS_MATCH) {
			parse_node *desc = Descriptions::to_rvalue(spec);
			if (desc) {
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(DURINGSCENEMATCHING_HL));
				Emit::down();
					CompileValues::to_code_val(desc);
				Emit::up();
				stuck = FALSE;
			}
		}
	}
	if (stuck) {
		Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ScenesBadDuring),
			"'during' must be followed by the name of a scene or of a "
			"description which applies to a single scene",
			"such as 'during Station Arrival' or 'during a recurring scene'.");
		return;
	}
}
