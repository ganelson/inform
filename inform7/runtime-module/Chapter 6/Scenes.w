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

There is no significance to the return value.

=
void RTScenes::compile_change_functions(void) {
	scene *sc;
	LOOP_OVER(sc, scene) {
		inter_name *iname = 
			Hierarchy::make_iname_in(SCENE_CHANGE_FN_HL, RTInstances::package(sc->as_instance));
		packaging_state save = Functions::begin(iname);
		inter_symbol *ch_s =
			LocalVariables::new_internal_commented_as_symbol(I"ch", I"flag: change made");
		@<Compile code detecting the ends of a specific scene@>;
		EmitCode::rfalse();
		Functions::end(save);
		inter_name *md_iname = Hierarchy::make_iname_in(INSTANCE_SCF_MD_HL, RTInstances::package(sc->as_instance));
		Emit::iname_constant(md_iname, K_value, iname);		
	}
}

@ Recall that ends numbered 1, 2, 3, ... are all ways for the scene to end,
so they are only checked if its status is currently running; end 0 is the
beginning, checked only if it isn't. We give priority to the higher end
numbers so that more abstruse ways to end take precedence over less.

@<Compile code detecting the ends of a specific scene@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(SCENE_STATUS_HL));
				EmitCode::val_number((inter_ti) sc->allocation_id);
			EmitCode::up();
			EmitCode::val_number(1);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			for (int end=sc->no_ends-1; end>=1; end--)
				RTScenes::test_scene_end(sc, end, ch_s);
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(EQ_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(SCENE_STATUS_HL));
				EmitCode::val_number((inter_ti) sc->allocation_id);
			EmitCode::up();
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			RTScenes::test_scene_end(sc, 0, ch_s);
		EmitCode::up();
	EmitCode::up();

@ Individual ends are tested here. There are actually three ways an end can
occur: at start of play (for end 0 only), when an I7 condition holds, or when
another end to which it is anchored also ends. But we only check the first
two, because the third way will be taken care of by the consequences code
below.

=
void RTScenes::test_scene_end(scene *sc, int end, inter_symbol *ch_s) {
	if ((end == 0) && (sc->start_of_play)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::inv(BITWISEAND_BIP);
				EmitCode::down();
					EmitCode::inv(LOOKUP_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_object, Hierarchy::find(SCENE_ENDINGS_HL));
						EmitCode::val_number((inter_ti) sc->allocation_id);
					EmitCode::up();
					EmitCode::val_number(1);
				EmitCode::up();
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				RTScenes::compile_scene_end(sc, 0);
			EmitCode::up();
		EmitCode::up();
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
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		current_sentence = sc->ends[end].anchor_condition_set;
		CompileValues::to_code_val_of_kind(S, K_truth_state);
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, ch_s);
				EmitCode::val_number(1);
			EmitCode::up();
			RTScenes::compile_scene_end(sc, end);
			EmitCode::rtrue();
		EmitCode::up();
	EmitCode::up();

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
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUPREF_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(SCENE_STATUS_HL));
				EmitCode::val_number((inter_ti) sc->allocation_id);
			EmitCode::up();
			EmitCode::val_number(1);
		EmitCode::up();
	} else {
		EmitCode::inv(IFELSE_BIP);
		EmitCode::down();
			inter_name *iname = Hierarchy::find(GPROPERTY_HL);
			EmitCode::call(iname);
			EmitCode::down();
				RTKinds::emit_weak_id_as_val(K_scene);
				EmitCode::val_number((inter_ti) ix+1);
				EmitCode::val_iname(K_value, RTProperties::iname(P_recurring));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::inv(LOOKUPREF_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(SCENE_STATUS_HL));
						EmitCode::val_number((inter_ti) sc->allocation_id);
					EmitCode::up();
					EmitCode::val_number(0);
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::inv(LOOKUPREF_BIP);
					EmitCode::down();
						EmitCode::val_iname(K_value, Hierarchy::find(SCENE_STATUS_HL));
						EmitCode::val_number((inter_ti) sc->allocation_id);
					EmitCode::up();
					EmitCode::val_number(2);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	}

@<Compile code to run the scene end rulebooks@> =
	if (end == 0) {
		EmitCode::call(Hierarchy::find(FOLLOWRULEBOOK_HL));
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(WHEN_SCENE_BEGINS_HL));
			EmitCode::val_number((inter_ti) (sc->allocation_id + 1));
		EmitCode::up();
	}
	EmitCode::call(Hierarchy::find(FOLLOWRULEBOOK_HL));
	EmitCode::down();
		EmitCode::val_iname(K_value, sc->ends[end].end_rulebook->compilation_data.rb_id_iname);
	EmitCode::up();
	if (end == 1) {
		EmitCode::call(Hierarchy::find(FOLLOWRULEBOOK_HL));
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(WHEN_SCENE_ENDS_HL));
			EmitCode::val_number((inter_ti) (sc->allocation_id + 1));
		EmitCode::up();
	}

@<Compile code to update the arrays recording most recent scene ending@> =
	inter_name *sarr = Hierarchy::find(SCENE_ENDED_HL);
	if (end == 0) sarr = Hierarchy::find(SCENE_STARTED_HL);
	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::inv(LOOKUPREF_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, sarr);
			EmitCode::val_number((inter_ti) sc->allocation_id);
		EmitCode::up();
		EmitCode::val_iname(K_number, Hierarchy::find(THE_TIME_HL));
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::inv(LOOKUPREF_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(SCENE_ENDINGS_HL));
			EmitCode::val_number((inter_ti) sc->allocation_id);
		EmitCode::up();
		EmitCode::inv(BITWISEOR_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, Hierarchy::find(SCENE_ENDINGS_HL));
				EmitCode::val_number((inter_ti) sc->allocation_id);
			EmitCode::up();
			EmitCode::val_number((inter_ti) (1 << end));
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(STORE_BIP);
	EmitCode::down();
		EmitCode::inv(LOOKUPREF_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, Hierarchy::find(SCENE_LATEST_ENDING_HL));
			EmitCode::val_number((inter_ti) sc->allocation_id);
		EmitCode::up();
		EmitCode::val_number((inter_ti) end);
	EmitCode::up();

@<Compile code to print text in response to the SCENES command@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, Hierarchy::find(DEBUG_SCENES_HL));
		EmitCode::code();
		EmitCode::down();
			TEMPORARY_TEXT(OUT)
			WRITE("[Scene '");
			if (sc->as_instance) WRITE("%+W", Instances::get_name(sc->as_instance, FALSE));
			WRITE("' ");
			if (end == 0) WRITE("begins"); else WRITE("ends");
			if (end >= 2) WRITE(" %+W", sc->ends[end].end_names);
			WRITE("]\n");
			EmitCode::inv(PRINT_BIP);
			EmitCode::down();
				EmitCode::val_text(OUT);
			EmitCode::up();
			DISCARD_TEXT(OUT)
		EmitCode::up();
	EmitCode::up();

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
						EmitCode::inv(IF_BIP);
						EmitCode::down();
							EmitCode::inv(EQ_BIP);
							EmitCode::down();
								EmitCode::inv(LOOKUP_BIP);
								EmitCode::down();
									EmitCode::val_iname(K_value, Hierarchy::find(SCENE_STATUS_HL));
									EmitCode::val_number((inter_ti) other_scene->allocation_id);
								EmitCode::up();
								if (other_end >= 1)
									EmitCode::val_number(1);
								else
									EmitCode::val_number(0);
							EmitCode::up();
							EmitCode::code();
							EmitCode::down();
								RTScenes::compile_scene_end_dash(other_scene, other_end);
							EmitCode::up();
						EmitCode::up();
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
void RTScenes::compile_show_status_functions(void) {
	scene *sc;
	LOOP_OVER(sc, scene) {
		inter_name *iname = 
			Hierarchy::make_iname_in(SCENE_STATUS_FN_HL, RTInstances::package(sc->as_instance));
		packaging_state save = Functions::begin(iname);
		EmitCode::inv(IFDEBUG_BIP);
		EmitCode::down();
			EmitCode::code();
			EmitCode::down();
				wording NW = Instances::get_name(sc->as_instance, FALSE);

				EmitCode::inv(IFELSE_BIP);
				EmitCode::down();
					EmitCode::inv(EQ_BIP);
					EmitCode::down();
						EmitCode::inv(LOOKUP_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_object, Hierarchy::find(SCENE_STATUS_HL));
							EmitCode::val_number((inter_ti) sc->allocation_id);
						EmitCode::up();
						EmitCode::val_number(1);
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						@<Show status of this running scene@>;
					EmitCode::up();
					EmitCode::code();
					EmitCode::down();
						@<Show status of this non-running scene@>;
					EmitCode::up();
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
		Functions::end(save);
		inter_name *md_iname = Hierarchy::make_iname_in(INSTANCE_SSF_MD_HL, RTInstances::package(sc->as_instance));
		Emit::iname_constant(md_iname, K_value, iname);		
	}
}

@<Show status of this running scene@> =
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "Scene '%+W' playing (for ", NW);
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(T);
	EmitCode::up();
	DISCARD_TEXT(T)

	EmitCode::inv(PRINTNUMBER_BIP);
	EmitCode::down();
		EmitCode::inv(MINUS_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_number, Hierarchy::find(THE_TIME_HL));
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(SCENE_STARTED_HL));
				EmitCode::val_number((inter_ti) sc->allocation_id);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(I" mins now)\n");
	EmitCode::up();

@<Show status of this non-running scene@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(SCENE_LATEST_ENDING_HL));
				EmitCode::val_number((inter_ti) sc->allocation_id);
			EmitCode::up();
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Show status of this recently ended scene@>;
		EmitCode::up();
	EmitCode::up();

@<Show status of this recently ended scene@> =
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "Scene '%+W' ended", NW);
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(T);
	EmitCode::up();
	DISCARD_TEXT(T)

	if (sc->no_ends > 2) {
		EmitCode::inv(SWITCH_BIP);
		EmitCode::down();
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_object, Hierarchy::find(SCENE_LATEST_ENDING_HL));
				EmitCode::val_number((inter_ti) sc->allocation_id);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				for (int end=2; end<sc->no_ends; end++) {
					EmitCode::inv(CASE_BIP);
					EmitCode::down();
						EmitCode::val_number((inter_ti) end);
						EmitCode::code();
						EmitCode::down();
							TEMPORARY_TEXT(T)
							WRITE_TO(T, " %+W", sc->ends[end].end_names);
							EmitCode::inv(PRINT_BIP);
							EmitCode::down();
								EmitCode::val_text(T);
							EmitCode::up();
							DISCARD_TEXT(T)
						EmitCode::up();
					EmitCode::up();
				}
			EmitCode::up();
		EmitCode::up();
	}

	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(I"\n");
	EmitCode::up();

@h During clauses.
We've now seen one use of scenes: they kick off rulebooks when they begin or
end. The other use for them is to predicate rules on whether they are currently
playing or not, using a "during" clause.

This is where we compile Inter code to test that a scene matching this is
actually running:

=
void RTScenes::emit_during_clause(parse_node *spec) {
	int stuck = TRUE;
	if (K_scene == NULL) { EmitCode::val_true(); return; }
	if (Rvalues::is_rvalue(spec)) {
		Dash::check_value(spec, K_scene);
		instance *I = Rvalues::to_instance(spec);
		if (Instances::of_kind(I, K_scene)) {
			scene *sc = Scenes::from_named_constant(I);
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::inv(LOOKUP_BIP);
				EmitCode::down();
					EmitCode::val_iname(K_value, Hierarchy::find(SCENE_STATUS_HL));
					EmitCode::val_number((inter_ti) sc->allocation_id);
				EmitCode::up();
				EmitCode::val_number(1);
			EmitCode::up();
			stuck = FALSE;
		}
	} else {
		if (Dash::check_value(spec, Kinds::unary_con(CON_description, K_scene)) == ALWAYS_MATCH) {
			parse_node *desc = Descriptions::to_rvalue(spec);
			if (desc) {
				EmitCode::call(Hierarchy::find(DURINGSCENEMATCHING_HL));
				EmitCode::down();
					CompileValues::to_code_val(desc);
				EmitCode::up();
				stuck = FALSE;
			}
		}
	}
	if (stuck) {
		EmitCode::val_true();
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ScenesBadDuring),
			"'during' must be followed by the name of a scene or of a "
			"description which applies to a single scene",
			"such as 'during Station Arrival' or 'during a recurring scene'.");
		return;
	}
}
