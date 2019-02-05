[Plugins::Manage::] Plugins.

To manage the interface between core Inform and some of its outlying
or domain-specific components.

@h Definitions.

@

@d MAX_PLUGINS 20

=
typedef struct plugin {
	struct word_assemblage plugin_name;
	int plugin_number;
	struct word_assemblage set_name;
	int set_number;
	void *starter_routine;
	int now_plugged_in;
	int stores_data;
	int has_been_set_explicitly;
	char *has_template_file;
	struct inter_name *IFDEF_iname;
	MEMORY_MANAGEMENT
} plugin;

@

= (early code)
plugin *core_plugin, *IF_plugin, *counting_plugin, *multimedia_plugin,
	*naming_plugin, *parsing_plugin, *actions_plugin,
	*spatial_plugin, *map_plugin, *player_plugin, *regions_plugin, *backdrops_plugin,
	*showme_plugin,
	*times_plugin, *scenes_plugin, *scoring_plugin,
	*figures_plugin, *sounds_plugin, *files_plugin,
	*bibliographic_plugin;

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
	player |
	regions |
	backdrops |
	showme |
	times of day |
	scenes |
	figures |
	sounds |
	glulx external files |
	bibliographic data |
	scoring

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
	P->has_template_file = NULL;
	P->IFDEF_iname = NULL;
	P->has_been_set_explicitly = FALSE;
	registered_plugins[NA] = P;
	if (P->allocation_id >= MAX_PLUGINS) internal_error("Too many plugins");

@

@d CORE_PLUGIN_NAME 0
@d INSTANCE_COUNTING_PLUGIN_NAME 1
@d IF_PLUGIN_NAME 2
@d MULTIMEDIA_PLUGIN_NAME 3
@d NAMING_PLUGIN_NAME 4
@d COMMAND_PLUGIN_NAME 5
@d ACTIONS_PLUGIN_NAME 6
@d SPATIAL_MODEL_PLUGIN_NAME 7
@d MAPPING_PLUGIN_NAME 8
@d PLAYER_PLUGIN_NAME 9
@d REGIONS_PLUGIN_NAME 10
@d BACKDROPS_PLUGIN_NAME 11
@d SHOWME_PLUGIN_NAME 12
@d TIMES_OF_DAY_PLUGIN_NAME 13
@d SCENES_PLUGIN_NAME 14
@d FIGURES_PLUGIN_NAME 15
@d SOUNDS_PLUGIN_NAME 16
@d GLULX_EXTERNAL_FILES_PLUGIN_NAME 17
@d BIBLIOGRAPHIC_DATA_PLUGIN_NAME 18
@d SCORE_PLUGIN_NAME 19

=
void Plugins::Manage::start(void) {
	Plugins::Call::initialise_calls();

	CREATE_PLUGIN(core_plugin, Plugins::Manage::start_core, FALSE, CORE_PLUGIN_NAME, CORE_PLUGIN_NAME);
	core_plugin->now_plugged_in = TRUE;
	core_plugin->has_template_file = "Core";
	CREATE_PLUGIN(counting_plugin, PL::Counting::start, TRUE, INSTANCE_COUNTING_PLUGIN_NAME, CORE_PLUGIN_NAME);
	counting_plugin->now_plugged_in = TRUE;

	CREATE_PLUGIN(IF_plugin, Plugins::Manage::deactivated_start, FALSE, IF_PLUGIN_NAME, IF_PLUGIN_NAME);

	CREATE_PLUGIN(multimedia_plugin, Plugins::Manage::deactivated_start, FALSE, MULTIMEDIA_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);

	#ifndef IF_MODULE
	IF_plugin->now_plugged_in = FALSE;
	#endif

	#ifdef IF_MODULE
	IF_plugin->now_plugged_in = TRUE;
	CREATE_PLUGIN(naming_plugin, PL::Naming::start, FALSE, NAMING_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(parsing_plugin, PL::Parsing::Visibility::start, FALSE, COMMAND_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(actions_plugin, PL::Actions::start, FALSE, ACTIONS_PLUGIN_NAME, IF_PLUGIN_NAME);
	actions_plugin->has_template_file = "Actions";
	CREATE_PLUGIN(spatial_plugin, PL::Spatial::start, TRUE, SPATIAL_MODEL_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(map_plugin, PL::Map::start, FALSE, MAPPING_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(player_plugin, PL::Player::start, FALSE, PLAYER_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(scoring_plugin, PL::Score::start, FALSE, SCORE_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(regions_plugin, PL::Regions::start, TRUE, REGIONS_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(backdrops_plugin, PL::Backdrops::start, FALSE, BACKDROPS_PLUGIN_NAME, IF_PLUGIN_NAME);
	CREATE_PLUGIN(showme_plugin, PL::Showme::start, FALSE, SHOWME_PLUGIN_NAME, IF_PLUGIN_NAME);

	CREATE_PLUGIN(times_plugin, PL::TimesOfDay::start, FALSE, TIMES_OF_DAY_PLUGIN_NAME, IF_PLUGIN_NAME);
	times_plugin->has_template_file = "Times";
	CREATE_PLUGIN(scenes_plugin, PL::Scenes::start, FALSE, SCENES_PLUGIN_NAME, IF_PLUGIN_NAME);
	scenes_plugin->has_template_file = "Scenes";

	CREATE_PLUGIN(bibliographic_plugin, PL::Bibliographic::start, FALSE, BIBLIOGRAPHIC_DATA_PLUGIN_NAME, IF_PLUGIN_NAME);
	#endif

	#ifdef MULTIMEDIA_MODULE
	multimedia_plugin->now_plugged_in = TRUE;

	CREATE_PLUGIN(figures_plugin, PL::Figures::start, FALSE, FIGURES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	figures_plugin->has_template_file = "Figures";

	CREATE_PLUGIN(sounds_plugin, PL::Sounds::start, FALSE, SOUNDS_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	sounds_plugin->has_template_file = "Sounds";

	CREATE_PLUGIN(files_plugin, PL::Files::start, FALSE, GLULX_EXTERNAL_FILES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	files_plugin->has_template_file = "Files";
	files_plugin->IFDEF_iname = InterNames::iname(PLUGIN_FILES_INAME);
	#endif

	#ifndef MULTIMEDIA_MODULE
	multimedia_plugin->now_plugged_in = FALSE;
	CREATE_PLUGIN(figures_plugin, Plugins::Manage::deactivated_start, FALSE, FIGURES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	CREATE_PLUGIN(sounds_plugin, Plugins::Manage::deactivated_start, FALSE, SOUNDS_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	CREATE_PLUGIN(files_plugin, Plugins::Manage::deactivated_start, FALSE, GLULX_EXTERNAL_FILES_PLUGIN_NAME, MULTIMEDIA_PLUGIN_NAME);
	#endif
}

void Plugins::Manage::deactivated_start(void) {
}

void Plugins::Manage::start_core(void) {
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

=
<use-language-element-sentence-subject> ::=
	no <plugin-name> |		==> PLUGIN_REMOVAL_OFFSET + R[1]
	<plugin-name> |			==> R[1]
	...						==> @<Issue PM_NoSuchLanguageElement problem@>

@<Issue PM_NoSuchLanguageElement problem@> =
	*X = -1;
	Problems::Issue::sentence_problem(_p_(PM_NoSuchLanguageElement),
		"this seems to ask to include or exclude a language feature which "
		"I don't recognise the name of",
		"possibly because you've borrowed it from a different version of "
		"Inform, or forgotten what these are called? You can see the current "
		"configuration at the bottom of the Contents index.");

@

@d PLUGIN_REMOVAL_OFFSET MAX_PLUGINS+1

=
void Plugins::Manage::plug_in(wording W) {
	plugin *P;
	if (<use-language-element-sentence-subject>(W)) {
		int plugin_number = <<r>>;
		int new_state = TRUE;
		if (plugin_number >= PLUGIN_REMOVAL_OFFSET) {
			new_state = FALSE;
			plugin_number -= PLUGIN_REMOVAL_OFFSET;
		}
		LOOP_OVER(P, plugin) {
			int definiteness = UNKNOWN_CE;
			if (P->plugin_number == plugin_number) definiteness = CERTAIN_CE;
			if (P->set_number == plugin_number) definiteness = LIKELY_CE;
			if (definiteness != UNKNOWN_CE) {
				if ((definiteness == LIKELY_CE) && (P->has_been_set_explicitly)) continue;
				if (P == core_plugin) {
					if (new_state == FALSE) @<Issue problem for trying to remove the core@>;
					plugin *Q;
					LOOP_OVER(Q, plugin) Q->now_plugged_in = FALSE;
				}
				P->now_plugged_in = new_state;
				P->has_been_set_explicitly = TRUE;
			}
		}
	}
	#ifndef IF_MODULE
	LOOP_OVER(P, plugin)
		if (P->set_number == IF_PLUGIN_NAME)
			P->now_plugged_in = FALSE;
	#endif
	#ifndef MULTIMEDIA_MODULE
	LOOP_OVER(P, plugin)
		if (P->set_number == MULTIMEDIA_PLUGIN_NAME)
			P->now_plugged_in = FALSE;
	#endif
}

@<Issue problem for trying to remove the core@> =
	Problems::Issue::sentence_problem(_p_(PM_DontRemoveTheCore),
		"the core of the Inform language cannot be removed",
		"because then what should we do? What should we ever do?");
	return;

@ And, we're as good as our word because --

=
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

@ Similarly:

=
void Plugins::Manage::define_IFDEF_symbols(void) {
	plugin *P;
	LOOP_OVER(P, plugin)
		if ((P->now_plugged_in) && (P->IFDEF_iname))
			Emit::named_numeric_constant(P->IFDEF_iname, 0);
}

@ =
void Plugins::Manage::command(text_stream *command) {
	if (Str::eq_wide_string(command, L"load")) {
		plugin *P;
		LOOP_OVER(P, plugin)
			if (P->now_plugged_in) {
				void (*start)() = (void (*)()) P->starter_routine;
				(*start)();
				if (P->has_template_file) {
					TEMPORARY_TEXT(segment_name);
					WRITE_TO(segment_name, "Load-%s.i6t", P->has_template_file);
					TemplateFiles::interpret(NULL, NULL, segment_name, -1);
					DISCARD_TEXT(segment_name);
				}
			}
		return;
	}
	internal_error("No such plugin command");
}

int Plugins::Manage::plugged_in(plugin *P) {
	return P->now_plugged_in;
}
