[Scenes::] Scenes.

A feature to support named periods of time during an interactive story.

@h Introduction.
Scenes are periods of time during play: at any given moment, several may be
going on, or none. They are started and stopped when certain conditions are
met, or by virtue of having been anchored together.

=
void Scenes::start(void) {
	Scenes::declare_annotations();
	PluginCalls::plug(NEW_PROPERTY_NOTIFY_PLUG, Scenes::new_property_notify);
	PluginCalls::plug(NEW_INSTANCE_NOTIFY_PLUG, Scenes::new_named_instance_notify);
	PluginCalls::plug(NEW_BASE_KIND_NOTIFY_PLUG, Scenes::new_base_kind_notify);
	PluginCalls::plug(COMPARE_CONSTANT_PLUG, Scenes::compare_CONSTANT);
	PluginCalls::plug(MAKE_SPECIAL_MEANINGS_PLUG, Scenes::make_special_meanings);
	PluginCalls::plug(NEW_RCD_NOTIFY_PLUG, Scenes::new_rcd);
}

@ This feature needs one extra syntax tree annotation:

@e constant_scene_ANNOT /* |scene|: for constant values */

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(constant_scene, scene)

@ =
MAKE_ANNOTATION_FUNCTIONS(constant_scene, scene)

void Scenes::declare_annotations(void) {
	Annotations::declare_type(constant_scene_ANNOT, Scenes::write_constant_scene_ANNOT);
	Annotations::allow(CONSTANT_NT, constant_scene_ANNOT);
}
void Scenes::write_constant_scene_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_constant_scene(p))
		WRITE(" {scene: %I}", Node::get_constant_scene(p)->as_instance);
}

@ Scenes are the instances of a built-in enumeration kind, created by a
Neptune file belonging to //WorldModelKit//, and this is recognised by its
Inter identifier |SCENE_TY|.

= (early code)
kind *K_scene = NULL;

@ =
int Scenes::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"SCENE_TY")) {
		K_scene = new_base; return TRUE;
	}
	return FALSE;
}

parse_node *Scenes::rvalue_from_scene(scene *val) { CONV_FROM(scene, K_scene) }
scene *Scenes::rvalue_to_scene(parse_node *spec) { CONV_TO(scene) }

int Scenes::compare_CONSTANT(parse_node *spec1, parse_node *spec2, int *rv) {
	kind *K = Node::get_kind_of_value(spec1);
	if (Kinds::eq(K, K_scene)) {
		if (Scenes::rvalue_to_scene(spec1) == Scenes::rvalue_to_scene(spec2)) {
			*rv = TRUE;
		}
		*rv = FALSE;
		return TRUE;
	}
	return FALSE;
}

@ //scene// structures are automatically created whenever a new instance of the
kind "scene" is created, and this is where that happens.

=
int Scenes::new_named_instance_notify(instance *I) {
	if ((K_scene) && (Kinds::eq(Instances::to_kind(I), K_scene))) {
		Scenes::new_scene(I);
		return TRUE;
	}
	return FALSE;
}

@ The following either/or property needs some compiler support:

= (early code)
property *P_recurring = NULL;

@ This is a property name to do with scenes which Inform provides special
support for; it recognises the English name when it is defined by the
Standard Rules. (So there is no need to translate this to other languages.)

=
<notable-scene-properties> ::=
	recurring

@ =
int Scenes::new_property_notify(property *prn) {
	if (<notable-scene-properties>(prn->name)) {
		switch (<<r>>) {
			case 0: P_recurring = prn; break;
		}
	}
	return FALSE;
}

@h Conceptual model of scenes.
Scenes are gated intervals of time, but there are more than two gates: for
while there is only one past, there are many possible futures. These gates
are called "ends" in the code below, and are numbered end 0 (the beginning),
end 1 (the usual end), and then any named ends ("ends badly" or "ends
triumphantly", for instance, might be ends 2 and 3). Each end has a condition
which can cause it, or can be "anchored" to any number of ends of other
scenes -- to express which, the //scene_connector// structure is used.

=
typedef struct scene {
	struct instance *as_instance; /* the constant for the name of the scene */
	int once_only; /* cannot repeat during play */
	int start_of_play; /* if begins when play begins */
	int marker; /* used to detect potentially infinite recursion when scene changes occur */
	int no_ends; /* how many ends the scene has */
	struct scene_end ends[MAX_SCENE_ENDS];
	int indexed; /* temporary storage during Scenes index creation */
	CLASS_DEFINITION
} scene;

typedef struct scene_end {
	struct wording end_names; /* for ends 2, 3, ...: e.g. "badly" */
	struct rulebook *end_rulebook; /* rules to apply then */
	struct dialogue_beat *as_beat; /* only for those scenes equated to beats */
	struct parse_node *anchor_condition;
	struct scene_connector *anchor_connectors; /* linked list */
	struct parse_node *anchor_condition_set; /* where set */
	CLASS_DEFINITION
} scene_end;

typedef struct scene_connector {
	struct scene *connect_to; /* scene connected to */
	int end; /* end number: see above */
	struct scene_connector *next; /* next in list of connectors for a scene end */
	struct parse_node *where_said; /* where this linkage was specified in source */
} scene_connector;

scene *SC_entire_game = NULL;

wording Scenes::get_name(scene *sc) {
	return Instances::get_name(sc->as_instance, FALSE);
}

instance *Scenes::get_instance(scene *sc) {
	return sc->as_instance;
}

@ A feature called |xyzzy| generally has a hunk of subject data called |xyzzy_data|,
so we would normally have a structure called |scenes_data|, but in fact that
structure is just going to be //scene//. So:

@d scenes_data scene
@d SCENES_DATA(subj) FEATURE_DATA_ON_SUBJECT(scenes, subj)

@h Scene structures.
As we've seen, the following is called whenever a new instance of "scene"
is created:

=
void Scenes::new_scene(instance *I) {
	scene *sc = CREATE(scene);
	@<Connect the scene structure to the instance@>;
	@<Initialise the scene structure@>;
}

@ A scene begins with two ends, 0 (beginning) and 1 (standard end).

@<Initialise the scene structure@> =
	sc->once_only = TRUE;
	sc->indexed = FALSE;
	sc->no_ends = 2;
	sc->start_of_play = FALSE;
	for (int end=0; end<sc->no_ends; end++) {
		sc->ends[end].anchor_condition = NULL;
		sc->ends[end].as_beat = NULL;
		sc->ends[end].anchor_connectors = NULL;
		Scenes::new_scene_rulebook(sc, end);
	}

@ This is a scene name which Inform provides special support for; it recognises
the English name when it is defined by the Standard Rules. (So there is no need
to translate this to other languages.)

=
<notable-scenes> ::=
	entire game

@<Connect the scene structure to the instance@> =
	sc->as_instance = I;
	ATTACH_FEATURE_DATA_TO_SUBJECT(scenes, I->as_subject, sc);
	wording W = Instances::get_name(I, FALSE);
	if (<notable-scenes>(W)) SC_entire_game = sc;

@ So we sometimes want to be able to get from an instance to its scene structure.

=
scene *Scenes::from_named_constant(instance *I) {
	if (K_scene == NULL) return NULL;
	kind *K = Instances::to_kind(I);
	if (Kinds::eq(K, K_scene)) return FEATURE_DATA_ON_SUBJECT(scenes, I->as_subject);
	return NULL;
}

int Scenes::is_entire_game(instance *I) {
	if ((SC_entire_game) && (Scenes::from_named_constant(I) == SC_entire_game))
		return TRUE;
	return FALSE;
}

@h Creating and parsing ends.

=
int Scenes::parse_scene_end_name(scene *sc, wording EW, int create) {
	for (int i=2; i<sc->no_ends; i++)
		if (Wordings::match(EW, sc->ends[i].end_names))
			return i;
	if (create) {
		int end = sc->no_ends++;
		int max = 31;
		if (TargetVMs::is_16_bit(Task::vm())) max = 15;
		if (end >= max) @<Issue a too-many-ends problem message@>
		else {
			sc->ends[end].end_names = EW;
			Scenes::new_scene_rulebook(sc, end);
			return end;
		}
	}
	return -1;
}

@<Issue a too-many-ends problem message@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ScenesWithTooManyEnds),
		"this scene now has too many different ways to end",
		"and will need to be simplified. (We can have up to 15 ends to a scene "
		"if the project format is for the Z-machine, and 31 for Glulx: see the "
		"project's Settings panel. Note that the ordinary 'begins' and 'ends' "
		"count as two of those, so you can only name up to 13 or 29 more specific "
		"ways for the scene to end.)");

@h Tie the ends of a scene to a dialogue beat.

=
void Scenes::set_beat(scene *sc, dialogue_beat *db) {
	sc->ends[0].as_beat = db;
	sc->ends[1].as_beat = db;
}

@h Scene end rulebooks.

=
void Scenes::new_scene_rulebook(scene *sc, int end) {
	wording RW = EMPTY_WORDING, AW = EMPTY_WORDING;
	@<Compose a name and alternate name for the new scene end rulebook@>;

	rulebook *rb = Rulebooks::new_automatic(RW, K_action_name,
			NO_OUTCOME, FALSE, FALSE, 0, NULL);
	Rulebooks::set_alt_name(rb, AW);
	sc->ends[end].end_rulebook = rb;

	if (end >= 2) @<Define phrases detecting whether or not the scene has ended this way@>;
}

@ For example, if a scene is called "Banquet Entertainment" and it ends
"merrily", then the rulebook has two names: "when Banquet Entertainment
ends merrily" and "when the Banquet Entertainment ends merrily".

@<Compose a name and alternate name for the new scene end rulebook@> =
	wording NW = Instances::get_name(sc->as_instance, FALSE);

	feed_t id = Feeds::begin();
	Feeds::feed_C_string_expanding_strings(L"when");
	Feeds::feed_wording(NW);
	Feeds::feed_C_string_expanding_strings((end==0)?L"begins":L"ends");
	if (end >= 2) Feeds::feed_wording(sc->ends[end].end_names);
	RW = Feeds::end(id);

	id = Feeds::begin();
	Feeds::feed_C_string_expanding_strings(L"when the");
	NW = Instances::get_name(sc->as_instance, FALSE);
	Feeds::feed_wording(NW);
	Feeds::feed_C_string_expanding_strings((end==0)?L"begins":L"ends");
	if (end >= 2) Feeds::feed_wording(sc->ends[end].end_names);
	AW = Feeds::end(id);

@<Define phrases detecting whether or not the scene has ended this way@> =
	wording NW = Instances::get_name(sc->as_instance, FALSE);

	TEMPORARY_TEXT(i6_code)
	feed_t id = Feeds::begin();
	Feeds::feed_C_string_expanding_strings(L"To decide if (S - ");
	Feeds::feed_wording(NW);
	Feeds::feed_C_string_expanding_strings(L") ended ");
	Feeds::feed_wording(sc->ends[end].end_names);
	Sentences::make_node(Task::syntax_tree(), Feeds::end(id), ':');

	id = Feeds::begin();
	Str::clear(i6_code);
	WRITE_TO(i6_code, " (- (scene_latest_ending-->%d == %d) -) ",
		sc->allocation_id, end);
	Feeds::feed_text_expanding_strings(i6_code);
	Sentences::make_node(Task::syntax_tree(), Feeds::end(id), '.');

	id = Feeds::begin();
	Feeds::feed_C_string_expanding_strings(L"To decide if (S - ");
	Feeds::feed_wording(NW);
	Feeds::feed_C_string_expanding_strings(L") did not end ");
	Feeds::feed_wording(sc->ends[end].end_names);
	Sentences::make_node(Task::syntax_tree(), Feeds::end(id), ':');

	id = Feeds::begin();
	Str::clear(i6_code);
	WRITE_TO(i6_code, " (- (scene_latest_ending-->%d ~= 0 or %d) -) ",
		sc->allocation_id, end);
	Feeds::feed_text_expanding_strings(i6_code);
	Sentences::make_node(Task::syntax_tree(), Feeds::end(id), '.');
	ImperativeSubtrees::accept_all();
	DISCARD_TEXT(i6_code)

@h Anchors.
These are joins between the endings of different scenes, and there are two
assertion sentences to create them:

=
int Scenes::make_special_meanings(void) {
	SpecialMeanings::declare(Scenes::begins_when_SMF, I"scene-begins-when", 1);
	SpecialMeanings::declare(Scenes::ends_when_SMF, I"scene-ends-when", 1);
	return FALSE;
}

@ This one handles the special meaning "X begins when...".

=
int Scenes::begins_when_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "The Ballroom Scene begins when..." */
		case ACCEPT_SMFT:
			<np-unparsed>(OW);
			parse_node *O = <<rp>>;
			<np-unparsed>(SW);
			V->next = <<rp>>;
			V->next->next = O;
			return TRUE;
		case PASS_1_SMFT:
			Scenes::new_scene_anchor(V, 1, 0);
			break;
		case PASS_2_SMFT:
			Scenes::new_scene_anchor(V, 2, 0);
			break;
	}
	return FALSE;
}

@ This handles the special meaning "X ends when...", which sometimes takes
two noun phrases and sometimes three.

=
int Scenes::ends_when_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	wording O2W = (NPs)?(NPs[2]):EMPTY_WORDING;
	switch (task) { /* "The Ballroom Scene ends when..." */
		case ACCEPT_SMFT:
			<np-unparsed>(OW);
			parse_node *O = <<rp>>;
			<np-unparsed>(SW);
			V->next = <<rp>>;
			if (Wordings::nonempty(O2W)) {
				<np-unparsed>(O2W);
				V->next->next = <<rp>>;
				V->next->next->next = O;
			} else {
				V->next->next = O;
			}
			return TRUE;
		case PASS_1_SMFT:
			Scenes::new_scene_anchor(V, 1, 1);
			break;
		case PASS_2_SMFT:
			Scenes::new_scene_anchor(V, 2, 1);
			break;
	}
	return FALSE;
}

@ This rather clumsy global variable is a convenience when parsing the
Preform grammar below.

=
scene *scene_end_of_which_parsed = NULL;

@ Sentences giving scene boundaries have a simple form:

>> The Ballroom Dance begins when the Hallway Greeting ends.
>> The Ballroom Dance ends dramatically when we have dropped the glass slipper.

The sentence has a subject noun phrase (here "Ballroom Dance") and an
object NP: "the Hallway Greeting ends" or "we have dropped the glass
slipper" are the object NPs here. We will call the optional part,
"dramatically" in this example, the adverb, though it doesn't actually
have to be worded as one.

The subject is simple: it has to be a scene name.

=
<scene-ends-sentence-subject> ::=
	<scene-name> |  ==> { TRUE, RP[1] }
	...             ==> @<Issue PM_ScenesOnly problem@>

@<Issue PM_ScenesOnly problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ScenesOnly),
		"'begins when' and 'ends when' can only be applied to scenes",
		"which have already been defined with a sentence like 'The final "
		"confrontation is a scene.'");
	==> { FALSE, NULL };

@ The adverb, if present, always matches, since the scene end is created
if it doesn't already exist:

=
<scene-ends-sentence-adverb> ::=
	<scene-end-name-creating>				==> { pass 1 }

@ The following is elementary enough, but we want to be careful because
there are possible ambiguities: the condition might contain the word "ends"
in a different context, for instance, and could still be valid in that case.

=
<scene-ends-sentence-object> ::=
	<text-including-a-calling> |          ==> @<Issue PM_ScenesDisallowCalled problem@>
	play begins |                         ==> { -1, - }
	play ends |                           ==> @<Issue PM_ScenesNotPlay problem@>
	<scene-name> begins |                 ==> { 0, -, <<scene:named>> = RP[1] }
	<scene-name> ends |                   ==> { 1, -, <<scene:named>> = RP[1] }
	<scene-name> ends <scene-end-name> |  ==> { R[2], -, <<scene:named>> = RP[1] }
	<scene-name> ends ... |               ==> @<Issue PM_ScenesUnknownEnd problem@>
	<s-condition>                         ==> { -2, -, <<parse_node:cond>> = RP[1] }

@<Issue PM_ScenesDisallowCalled problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ScenesDisallowCalled),
		"'(called ...)' is not allowed within conditions for a scene to begin or end",
		"since calling gives only a temporary name to something, for the purpose "
		"of further instructions which immediately follow in. Here there is no room "
		"for such further instructions, so a calling would have no effect. Anyway - "
		"not allowed!");
	==> { -1, - };

@<Issue PM_ScenesNotPlay problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ScenesNotPlay),
		"'play' is not really a scene",
		"so although you can write '... when play begins' you cannot write '... "
		"when play ends'. But there's no need to do so, anyway. When play ends, "
		"all scenes end.");
	==> { -1, - };

@<Issue PM_ScenesUnknownEnd problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ScenesUnknownEnd),
		"that's not one of the known ends for that scene",
		"which must be declared with something like 'Confrontation ends happily "
		"when...' or 'Confrontation ends tragically when...'.");
	==> { -1, - };

@ Where the following filters instance names to allow those of scenes only,
and also internally converts the result:

=
<scene-name> ::=
	<definite-article> <scene-name-unarticled> |    ==> { pass 2 }
	<scene-name-unarticled>							==> { pass 1 }

<scene-name-unarticled> ::=
	<instance-of-non-object>	==> @<Convert instance result to scene result, if possible@>

@<Convert instance result to scene result, if possible@> =
	instance *I = <<rp>>;
	if (Instances::of_kind(I, K_scene) == FALSE) return FALSE;
	scene_end_of_which_parsed = Scenes::from_named_constant(I);
	==> { -, scene_end_of_which_parsed };

@ Lastly, scene end names are parsed by these internals. They are identical
except that the creating case will create a new end if need be so that it
never fails.

=
<scene-end-name> internal {
	int end = Scenes::parse_scene_end_name(scene_end_of_which_parsed, W, FALSE);
	if (end < 0) { ==> { fail nonterminal }; }
	==> { end, - };
	return TRUE;
}

<scene-end-name-creating> internal {
	int end = Scenes::parse_scene_end_name(scene_end_of_which_parsed, W, TRUE);
	==> { end, - };
	return TRUE;
}

@ In a sentence like

>> The Ballroom Dance begins when the Hallway Greeting ends.

we will call "the Ballroom Dance begins" this end, and "the Hallway Greeting
ends" the other end.

=
void Scenes::new_scene_anchor(parse_node *p, int phase, int given_end) {
	scene *this_scene = NULL; /* scene whose end is being caused: must be set */
	int end = -1; /* end which is being anchored: must be set */

	scene *other_scene = NULL; /* Either: another scene whose end it connects to */
	int other_end = -1; /* and which end it is... */
	parse_node *external_condition = NULL; /* Or: an absolute condition... */
	int when_play_begins = FALSE; /* Or: anchor to the start of play */

	wording SW = Node::get_text(p->next); /* scene name */
	wording EW = EMPTY_WORDING; /* end name, if any */
	wording CW = EMPTY_WORDING; /* condition for end to occur */
	if (p->next->next->next) {
		EW = Node::get_text(p->next->next);
		CW = Node::get_text(p->next->next->next);
	} else {
		CW = Node::get_text(p->next->next);
	}

	@<Parse the scene and end to be anchored@>;
	if ((this_scene == NULL) || (end < 0)) internal_error("scene misparsed");

	if (phase == 2) {
		@<Parse which form of anchor we have@>;
		if ((this_scene == SC_entire_game) && (external_condition == NULL)) {
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_EntireGameHardwired),
				"the special 'Entire Game' scene cannot have its start or end modified",
				"because it is a built-in scene designed to be going on whenever there "
				"is play going on in the story.");
		} else if (when_play_begins)
			@<Connect this end to the start of play@>
		else if (other_scene)
			@<Connect this end to an end of another scene@>
		else if (external_condition)
			@<Make this an external scene end condition@>
		else internal_error("failed to obtain an anchor condition");
	}
}

@<Connect this end to the start of play@> =
	this_scene->start_of_play = TRUE;

@<Make this an external scene end condition@> =
	if (this_scene->ends[end].anchor_condition)
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ScenesOversetEnd),
			"you have already told me a condition for when that happens",
			"and although a scene can be linked to the beginning or ending "
			"of any number of other scenes, it can only have a single "
			"condition such as 'when the player is in the Dining Car' "
			"to trigger it from outside the scene machinery.");

	this_scene->ends[end].anchor_condition = external_condition;
	this_scene->ends[end].anchor_condition_set = current_sentence;

@<Connect this end to an end of another scene@> =
	scene_connector *scon = CREATE(scene_connector);
	scon->connect_to = other_scene;
	scon->end = other_end;
	scon->where_said = current_sentence;
	scon->next = this_scene->ends[end].anchor_connectors;
	this_scene->ends[end].anchor_connectors = scon;

@<Parse the scene and end to be anchored@> =
	<scene-ends-sentence-subject>(SW);
	if (<<r>> == FALSE) return;
	this_scene = <<rp>>;
	scene_end_of_which_parsed = this_scene;

	if (Wordings::nonempty(EW)) {
		<scene-ends-sentence-adverb>(EW);
		end = <<r>>;
	} else end = given_end;
	if (end < 0) return; /* to recover from any parsing Problems */

@<Parse which form of anchor we have@> =
	if (<scene-ends-sentence-object>(CW)) {
		int end = <<r>>;
		switch (end) {
			case -2: external_condition = <<parse_node:cond>>; break;
			case -1: when_play_begins = TRUE; break;
			default: other_end = end; other_scene = <<scene:named>>; break;
		}
	} else external_condition = Specifications::new_UNKNOWN(CW);

@ One use of scenes is to kick off rulebooks when they begin or end. The other
use for them is to predicate rules on whether they are currently playing or
not, using a "during" clause, and this is used when parsing those in rule
headers. Note that a match here can name a specific scene, or describe a
collection of them:

=
<s-scene-description> ::=
	<s-value>		==> @<Filter to force this to be a scene description@>

@<Filter to force this to be a scene description@> =
	if (K_scene == NULL) return FALSE;
	parse_node *spec = RP[1];
	instance *I = Rvalues::to_instance(spec);
	if (((I) && (Instances::of_kind(I, K_scene))) ||
		((Specifications::is_description(spec)) &&
			(Kinds::eq(Specifications::to_kind(spec), K_scene)))) {
		==> { -, spec };
	} else return FALSE;

@h Rules predicated on scenes.
Rules can be set to fire only during a certain scene, or a scene matching some
description. This is stored in the following scenes-feature corner of the
//assertions: Runtime Context Data// for the rule:

=
typedef struct scenes_rcd_data {
	struct parse_node *during_scene; /* ...happens only during a scene matching this? */
	CLASS_DEFINITION
} scenes_rcd_data;

scenes_rcd_data *Scenes::new_rcd_data(id_runtime_context_data *idrcd) {
	scenes_rcd_data *srd = CREATE(scenes_rcd_data);
	srd->during_scene = NULL;
	return srd;
}

int Scenes::new_rcd(id_runtime_context_data *idrcd) {
	CREATE_RCD_FEATURE_DATA(scenes, idrcd, Scenes::new_rcd_data)
	return FALSE;
}

void Scenes::set_rcd_spec(id_runtime_context_data *idrcd, parse_node *to_match) {
	scenes_rcd_data *srcd = RCD_FEATURE_DATA(scenes, idrcd);
	if (srcd) {
		srcd->during_scene = to_match;
	}
}

parse_node *Scenes::get_rcd_spec(id_runtime_context_data *idrcd) {
	scenes_rcd_data *srcd = RCD_FEATURE_DATA(scenes, idrcd);
	if (srcd) return srcd->during_scene;
	return NULL;
}

@ The reason we store a whole specification, rather than a scene constant,
here is that we sometimes want rules which happen during "a recurring scene",
or some other description of scenes in general. But the following function
extracts a single specified scene if there is one:

=
scene *Scenes::rcd_scene(id_runtime_context_data *idrcd) {
	if (idrcd == NULL) return NULL;
	scenes_rcd_data *srcd = RCD_FEATURE_DATA(scenes, idrcd);
	if (srcd) {
		if (Rvalues::is_rvalue(srcd->during_scene)) {
			instance *q = Rvalues::to_instance(srcd->during_scene);
			if (q) return Scenes::from_named_constant(q);
		}
	}
	return NULL;
}

@ And this is used to make metadata for indexing.

=
wording Scenes::during_wording(id_runtime_context_data *idrcd) {
	if (idrcd) {
		scenes_rcd_data *srcd = RCD_FEATURE_DATA(scenes, idrcd);
		if (srcd) return Node::get_text(srcd->during_scene);
	}
	return EMPTY_WORDING;
}
