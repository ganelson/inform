[Plugins::Manage::] Plugins.

To manage the interface between core Inform and some of its outlying
or domain-specific components.

@h Definitions.

@

@d MAX_PLUGINS 64

=
typedef struct plugin {
	struct word_assemblage plugin_name;
	int plugin_number;
	struct word_assemblage set_name;
	int set_number;
	void *starter_routine;
	int now_plugged_in;
	int stores_data;
	MEMORY_MANAGEMENT
} plugin;

@

= (early code)
plugin *core_plugin, *IF_plugin, *counting_plugin, *multimedia_plugin,
	*naming_plugin, *parsing_plugin, *actions_plugin,
	*spatial_plugin, *map_plugin, *persons_plugin,
	*player_plugin, *regions_plugin, *backdrops_plugin,
	*devices_plugin, *showme_plugin,
	*times_plugin, *scenes_plugin, *scoring_plugin,
	*figures_plugin, *sounds_plugin, *files_plugin,
	*bibliographic_plugin, *chronology_plugin;

plugin *registered_plugins[MAX_PLUGINS];

#ifdef IF_MODULE
sentence_handler BIBLIOGRAPHIC_SH_handler =
	{ BIBLIOGRAPHIC_NT, -1, 2, PL::Bibliographic::bibliographic_data };
#endif

@h Names of the great plugins.
Although Inform was specifically written to create programs within a complex
and unusual domain (interactive fiction), almost all of its code is quite
general, and could be used for any natural-language programming.

We want to facilitate possible future uses of Inform in domains other than
IF, and in any case it seems good design to isolate generic linguistic
assumptions from those which are based on contextual knowledge of a given
domain.

"Core" is the core of the Inform language, the largest part, which is
compulsorily included. "Interactive fiction" is an anthology of all of
the rest -- using it uses all of them.

For now, at least, these names should not be translated out of English.

=
<plugin-name> ::=
	core |
	instance counting |
	interactive fiction |
	multimedia |
	naming |
	command |
	actions |
	spatial model |
	mapping |
	persons |
	player |
	regions |
	backdrops |
	devices |
	showme |
	times of day |
	scenes |
	figures |
	sounds |
	glulx external files |
	bibliographic data |
	scoring |
	chronology

@ And the following matches if and only if the text in question is (a) a
valid plugin name, and (b) the name of a plugin which is being used at
present.

=
<language-element> ::=
	<plugin-name>	==> TRUE; if ((registered_plugins[R[1]] == NULL) || (registered_plugins[R[1]]->now_plugged_in == FALSE)) *X = FALSE;

@ =
word_assemblage Plugins::Manage::wording(int N) {
	return Preform::Nonparsing::wording(<plugin-name>, N);
}

@h Plugins.

@d CREATE_PLUGIN(P, starter, mem, NA, NA2)
	P = CREATE(plugin);
	P->starter_routine = (void *) (&starter);
	P->now_plugged_in = FALSE;
	P->stores_data = mem;
	P->plugin_name = Plugins::Manage::wording(NA);
	P->plugin_number = NA;
	P->set_name = Plugins::Manage::wording(NA2);
	P->set_number = NA2;
	registered_plugins[NA] = P;
	if (P->allocation_id >= MAX_PLUGINS) internal_error("Too many plugins");

@d CREATE_STARTLESS_PLUGIN(P, mem, NA, NA2)
	P = CREATE(plugin);
	P->starter_routine = NULL;
	P->now_plugged_in = FALSE;
	P->stores_data = mem;
	P->plugin_name = Plugins::Manage::wording(NA);
	P->plugin_number = NA;
	P->set_name = Plugins::Manage::wording(NA2);
	P->set_number = NA2;
	registered_plugins[NA] = P;
	if (P->allocation_id >= MAX_PLUGINS) internal_error("Too many plugins");

@

@e CORE_PLUGIN_NAME from 0
@e INSTANCE_COUNTING_PLUGIN_NAME
@e IF_PLUGIN_NAME
@e MULTIMEDIA_PLUGIN_NAME
@e NAMING_PLUGIN_NAME
@e COMMAND_PLUGIN_NAME
@e ACTIONS_PLUGIN_NAME
@e SPATIAL_MODEL_PLUGIN_NAME
@e MAPPING_PLUGIN_NAME
@e PERSONS_PLUGIN_NAME
@e PLAYER_PLUGIN_NAME
@e REGIONS_PLUGIN_NAME
@e BACKDROPS_PLUGIN_NAME
@e DEVICES_PLUGIN_NAME
@e SHOWME_PLUGIN_NAME
@e TIMES_OF_DAY_PLUGIN_NAME
@e SCENES_PLUGIN_NAME
@e FIGURES_PLUGIN_NAME
@e SOUNDS_PLUGIN_NAME
@e GLULX_EXTERNAL_FILES_PLUGIN_NAME
@e BIBLIOGRAPHIC_DATA_PLUGIN_NAME
@e SCORE_PLUGIN_NAME
@e CHRONOLOGY_PLUGIN_NAME

=
void Plugins::Manage::start(void) {
	Plugins::Call::initialise_calls();

	CREATE_STARTLESS_PLUGIN(core_plugin, FALSE, CORE_PLUGIN_NAME, CORE_PLUGIN_NAME);
	CREATE_STARTLESS_PLUGIN(IF_plugin, FALSE, IF_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_STARTLESS_PLUGIN(multimedia_plugin, FALSE, MULTIMEDIA_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);

	CREATE_PLUGIN(counting_plugin, PL::Counting::start, TRUE, INSTANCE_COUNTING_PLUGIN_NAME, CORE_PLUGIN_NAME);

	#ifdef IF_MODULE
	CREATE_PLUGIN(naming_plugin, PL::Naming::start, FALSE, NAMING_PLUGIN_NAME, CORE_PLUGIN_NAME);
	CREATE_PLUGIN(parsing_plugin, PL::Parsing::Visibility::start, FALSE, COMMAND_PLUGIN_NAME, COMMAND_PLUGIN_NAME);
	CREATE_PLUGIN(actions_plugin, PL::Actions::start, FALSE, ACTIONS_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(spatial_plugin, PL::Spatial::start, TRUE, SPATIAL_MODEL_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(map_plugin, PL::Map::start, FALSE, MAPPING_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(persons_plugin, PL::Persons::start, FALSE, PERSONS_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(player_plugin, PL::Player::start, FALSE, PLAYER_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(scoring_plugin, PL::Score::start, FALSE, SCORE_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(regions_plugin, PL::Regions::start, TRUE, REGIONS_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(backdrops_plugin, PL::Backdrops::start, FALSE, BACKDROPS_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(devices_plugin, PL::Devices::start, FALSE, DEVICES_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(showme_plugin, PL::Showme::start, FALSE, SHOWME_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(times_plugin, PL::TimesOfDay::start, FALSE, TIMES_OF_DAY_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(scenes_plugin, PL::Scenes::start, FALSE, SCENES_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(bibliographic_plugin, PL::Bibliographic::start, FALSE, BIBLIOGRAPHIC_DATA_PLUGIN_NAME, IF_PLUGIN_NAME);
	#endif
	CREATE_STARTLESS_PLUGIN(chronology_plugin, FALSE, CHRONOLOGY_PLUGIN_NAME, IF_PLUGIN_NAME);

	#ifdef MULTIMEDIA_MODULE
	CREATE_PLUGIN(figures_plugin, PL::Figures::start, FALSE, FIGURES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	CREATE_PLUGIN(sounds_plugin, PL::Sounds::start, FALSE, SOUNDS_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	CREATE_PLUGIN(files_plugin, PL::Files::start, FALSE, GLULX_EXTERNAL_FILES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	#endif

	#ifndef MULTIMEDIA_MODULE
	CREATE_STARTLESS_PLUGIN(figures_plugin, FALSE, FIGURES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	CREATE_STARTLESS_PLUGIN(sounds_plugin, FALSE, SOUNDS_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	CREATE_STARTLESS_PLUGIN(files_plugin, FALSE, GLULX_EXTERNAL_FILES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	#endif
}

@ Although most of Inform's brain remains the same, the outermost part can
be put together from whatever skills are required: our modular oblongata,
if you will. So, in principle, sentences like:

>> Use regions language element.
>> Use no figures language element.

can change the current setup. (In practice, these aren't very useful at
present, at least, because the I6 template won't compile under most
combinations; so this is really a provisional feature for now.)

"Core" is a special case. It can't be removed; explicitly writing

>> Use core language element.

unplugs all other plugins, reducing Inform to a non-IF language entirely.

The subject noun phrase is an articled list, and each entry is parsed
with the following.

@

=
int Plugins::Manage::parse(text_stream *S) {
	if (Str::eq(S, I"core")) return CORE_PLUGIN_NAME;
	if (Str::eq(S, I"instance counting")) return INSTANCE_COUNTING_PLUGIN_NAME;
	if (Str::eq(S, I"interactive fiction")) return IF_PLUGIN_NAME;
	if (Str::eq(S, I"multimedia")) return MULTIMEDIA_PLUGIN_NAME;
	if (Str::eq(S, I"naming")) return NAMING_PLUGIN_NAME;
	if (Str::eq(S, I"command")) return COMMAND_PLUGIN_NAME;
	if (Str::eq(S, I"actions")) return ACTIONS_PLUGIN_NAME;
	if (Str::eq(S, I"spatial model")) return SPATIAL_MODEL_PLUGIN_NAME;
	if (Str::eq(S, I"mapping")) return MAPPING_PLUGIN_NAME;
	if (Str::eq(S, I"persons")) return PERSONS_PLUGIN_NAME;
	if (Str::eq(S, I"player")) return PLAYER_PLUGIN_NAME;
	if (Str::eq(S, I"regions")) return REGIONS_PLUGIN_NAME;
	if (Str::eq(S, I"backdrops")) return BACKDROPS_PLUGIN_NAME;
	if (Str::eq(S, I"devices")) return DEVICES_PLUGIN_NAME;
	if (Str::eq(S, I"showme")) return SHOWME_PLUGIN_NAME;
	if (Str::eq(S, I"times of day")) return TIMES_OF_DAY_PLUGIN_NAME;
	if (Str::eq(S, I"scenes")) return SCENES_PLUGIN_NAME;
	if (Str::eq(S, I"figures")) return FIGURES_PLUGIN_NAME;
	if (Str::eq(S, I"sounds")) return SOUNDS_PLUGIN_NAME;
	if (Str::eq(S, I"glulx external files")) return GLULX_EXTERNAL_FILES_PLUGIN_NAME;
	if (Str::eq(S, I"bibliographic data")) return BIBLIOGRAPHIC_DATA_PLUGIN_NAME;
	if (Str::eq(S, I"scoring")) return SCORE_PLUGIN_NAME;
	return -1;
}

void Plugins::Manage::activate(int N) {
	if (N < 0) return;
	plugin *P;
	LOOP_OVER(P, plugin)
		if ((P->set_number == N) || (P->plugin_number == N))
			P->now_plugged_in = TRUE;
	#ifndef IF_MODULE
	Plugins::Manage::deactivate(IF_PLUGIN_NAME)
	#endif
	#ifndef MULTIMEDIA_MODULE
	Plugins::Manage::deactivate(MULTIMEDIA_PLUGIN_NAME)
	#endif
}

void Plugins::Manage::deactivate(int N) {
	if (N < 0) return;
	plugin *P;
	LOOP_OVER(P, plugin)
		if ((P->set_number == N) || (P->plugin_number == N)) {
			if (P->set_number == CORE_PLUGIN_NAME) @<Issue problem for trying to remove the core@>
			else P->now_plugged_in = FALSE;
		}
}

@<Issue problem for trying to remove the core@> =
	Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(Untestable),
		"the core of the Inform language cannot be removed",
		"because then what should we do? What should we ever do?");
	return;

@ It's kind of incredible that C's grammar for round brackets is unambiguous.

=
void Plugins::Manage::start_plugins(void) {
	plugin *P;
	LOOP_OVER(P, plugin)
		if (P->now_plugged_in) {
			void (*start)() = (void (*)()) P->starter_routine;
			if (start) (*start)();
		}
}

@h Describing the current VM.

=
void Plugins::Manage::index_innards(OUTPUT_STREAM, target_vm *VM) {
	Plugins::Manage::index_VM(OUT, VM);
	UseOptions::index(OUT);
	HTML_OPEN("p");
	Index::extra_link(OUT, 3);
	WRITE("See some technicalities for Inform maintainers only");
	HTML_CLOSE("p");
	Index::extra_div_open(OUT, 3, 2, "e0e0e0");
	Plugins::Manage::show_configuration(OUT);
	@<Add some paste buttons for the debugging log@>;
	Index::extra_div_close(OUT, "e0e0e0");
}

@ The index provides some hidden paste icons for these:

@<Add some paste buttons for the debugging log@> =
	HTML_OPEN("p");
	WRITE("Debugging log:");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	for (int i=0; i<NO_DEFINED_DA_VALUES; i++) {
		debugging_aspect *da = &(the_debugging_aspects[i]);
		if (Str::len(da->unhyphenated_name) > 0) {
			TEMPORARY_TEXT(is);
			WRITE_TO(is, "Include %S in the debugging log.", da->unhyphenated_name);
			HTML::Javascript::paste_stream(OUT, is);
			WRITE("&nbsp;%S", is);
			DISCARD_TEXT(is);
			HTML_TAG("br");
		}
	}
	HTML_CLOSE("p");

@ =
void Plugins::Manage::index_VM(OUTPUT_STREAM, target_vm *VM) {
	if (VM == NULL) internal_error("target VM not set yet");
	Index::anchor(OUT, I"STORYFILE");
	HTML_OPEN("p"); WRITE("Story file format: ");
	ExtensionCensus::plot_icon(OUT, VM);
	TargetVMs::write(OUT, VM);
	HTML_CLOSE("p");
}

@ =
void Plugins::Manage::show_configuration(OUTPUT_STREAM) {
	HTML_OPEN("p");
	Index::anchor(OUT, I"CONFIG");
	WRITE("Inform language definition:\n");
	Plugins::Manage::show(OUT, "Included", TRUE);
	Plugins::Manage::show(OUT, "Excluded", FALSE);
	HTML_CLOSE("p");
}

void Plugins::Manage::show(OUTPUT_STREAM, char *label, int state) {
	plugin *P;
	int c = 0;
	WRITE("%s: ", label);
	LOOP_OVER(P, plugin) if (P->now_plugged_in == state) {
		if (c > 0) WRITE(", ");
		WRITE("%A", &(P->plugin_name));
		c++;
	}
	if (c == 0) WRITE("<i>none</i>");
	WRITE(".\n");
}

int Plugins::Manage::plugged_in(plugin *P) {
	return P->now_plugged_in;
}
