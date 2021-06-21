[EPSMap::] EPS Map.

To render the spatial map of rooms as an EPS (Encapsulated PostScript) file.

@ EPS-format files are vector art, rather than raster art, and are produced
with the intention that authors can tidy them up afterwards using programs
like Adobe Illustrator. By default they aren't produced, so that the following
flag stays |FALSE|:

=
int write_EPS_format_map = FALSE;

@ The EPS map-maker is really a miniature interpreted programming
language in its own right, and here we define that language's data
types and variables.

The "mapping parameters" amount to being variables. The following
structure defines the type and current value for each variable: see
the Inform documentation for details. But note that variables of the
same name are held by many different objects in the map, and their
values inherited by sub-objects.

@d INT_MDT	1 /* an integer */
@d BOOL_MDT 2 /* true or false */
@d TEXT_MDT 3 /* quoted text */
@d COL_MDT	4 /* an HTML-safe colour */
@d FONT_MDT	5 /* the name of a font */
@d OFF_MDT	6 /* a positional offset in an $(x,y)$ grid */

=
typedef struct plotting_parameter {
	int specified; /* is it explicitly specified at this scope? */
	wchar_t *name; /* name (used only in global scope) */
	int parameter_data_type; /* one of the above types (used only in global scope) */
	wchar_t *string_value; /* string value, if appropriate to this type; */
	struct text_stream *stream_value; /* text value, if appropriate to this type; */
	int numeric_value; /* or numeric value, if appropriate to this type */
} plotting_parameter;

@ A set of variables associated with any map object is called a "scope".
As implied above, the global scope is special: it contains the default
settings passed down to all lower scopes.

@d NO_MAP_PARAMETERS 35

=
typedef struct map_parameter_scope {
	struct map_parameter_scope *wider_scope; /* that is, the scope above this */
	struct plotting_parameter values[NO_MAP_PARAMETERS];
} map_parameter_scope;

map_parameter_scope global_map_scope = {
	NULL,
	{
		{ TRUE, L"font",					FONT_MDT,	L"Helvetica", NULL, 0 },
		{ TRUE, L"minimum-map-width",		INT_MDT,	NULL, 		NULL, 72*5 },
		{ TRUE, L"title",					TEXT_MDT,	L"Map", 	NULL, 0 },
		{ TRUE, L"title-size",				INT_MDT,	NULL, 		NULL, 24 },
		{ TRUE, L"title-font",				FONT_MDT,	L"<font>", 	NULL, 0 },
		{ TRUE, L"title-colour",			COL_MDT,	L"000000", 	NULL, 0 },
		{ TRUE, L"map-outline",				BOOL_MDT,	NULL, 		NULL, 1 },
		{ TRUE, L"border-size",				INT_MDT,	NULL, 		NULL, 12 },
		{ TRUE, L"vertical-spacing",		INT_MDT,	NULL, 		NULL, 6 },
		{ TRUE, L"monochrome",				BOOL_MDT,	NULL, 		NULL, 0 },
		{ TRUE, L"annotation-size",			INT_MDT,	NULL, 		NULL, 8 },
		{ TRUE, L"annotation-length",		INT_MDT,	NULL, 		NULL, 8 },
		{ TRUE, L"annotation-font",			FONT_MDT,	L"<font>", 	NULL, 0 },
		{ TRUE, L"subtitle",				TEXT_MDT,	L"Map", 	NULL, 0 },
		{ TRUE, L"subtitle-size",			INT_MDT,	NULL, 		NULL, 16 },
		{ TRUE, L"subtitle-font",			FONT_MDT,	L"<font>", 	NULL, 0 },
		{ TRUE, L"subtitle-colour",			COL_MDT,	L"000000", 	NULL, 0 },
		{ TRUE, L"grid-size",				INT_MDT,	NULL, 		NULL, 72 },
		{ TRUE, L"route-stiffness",			INT_MDT,	NULL, 		NULL, 100 },
		{ TRUE, L"route-thickness",			INT_MDT,	NULL, 		NULL, 1 },
		{ TRUE, L"route-colour",			COL_MDT,	L"000000", 	NULL, 0 },
		{ TRUE, L"room-offset",				OFF_MDT,	NULL, 		NULL, 0 },
		{ TRUE, L"room-size",				INT_MDT,	NULL, 		NULL, 36 },
		{ TRUE, L"room-colour",				COL_MDT,	L"DDDDDD", 	NULL, 0 },
		{ TRUE, L"room-name",				TEXT_MDT,	L"", 		NULL, 0 },
		{ TRUE, L"room-name-size",			INT_MDT,	NULL, 		NULL, 12 },
		{ TRUE, L"room-name-font",			FONT_MDT,	L"<font>", 	NULL, 0 },
		{ TRUE, L"room-name-colour",		COL_MDT,	L"000000", 	NULL, 0 },
		{ TRUE, L"room-name-length",		INT_MDT,	NULL, 		NULL, 5 },
		{ TRUE, L"room-name-offset",		OFF_MDT,	NULL, 		NULL, 0 },
		{ TRUE, L"room-outline",			BOOL_MDT,	NULL, 		NULL, 1 },
		{ TRUE, L"room-outline-colour",		COL_MDT,	L"000000",	NULL, 0 },
		{ TRUE, L"room-outline-thickness",	INT_MDT,	NULL, 		NULL, 1 },
		{ TRUE, L"room-shape",				TEXT_MDT,	L"square",	NULL, 0 }
	}
};

int changed_global_room_colour = FALSE;

@ A "rubric" is a freestanding piece of text written on the map. Typically
it will be a title.

=
typedef struct rubric_holder {
	wchar_t *annotation;
	int point_size;
	wchar_t *font;
	wchar_t *colour;
	int at_offset;
	struct instance *offset_from;
	CLASS_DEFINITION
} rubric_holder;

@ Each horizontal level of the EPS map needs its own storage, not least to
hold the applicable mapping parameters.

=
typedef struct EPS_map_level {
	int width;
	int actual_height;
	int height;
	struct text_stream *titling;
	int titling_point_size;
	int map_level;
	int y_max;
	int y_min;
	int contains_rooms;
	int contains_titling;
	int eps_origin;
	struct map_parameter_scope map_parameters;
	CLASS_DEFINITION
} EPS_map_level;

@ The following are the directions at which arrows for UP, DOWN, IN and OUT
are drawn on EPS maps.

=
vector U_vector_EPS = {2, 3, 0};
vector D_vector_EPS = {-2, -3, 0};
vector IN_vector_EPS = {3, 2, 0};
vector OUT_vector_EPS = {-3, -2, 0};

@ A convenience when parsing:

=
int index_map_with_pass = 0;
parse_node *index_map_with_p = NULL;

@h Map parameters.
We convert a parameter's name to its index in the list; slowly, but that
doesn't matter.

=
int EPSMap::get_map_variable_index(wchar_t *name) {
	int s = EPSMap::get_map_variable_index_forgivingly(name);
	if (s < 0) {
		LOG("Tried to look up <%w>\n", name);
		internal_error("looked up non-existent map variable");
		s = 0;
	}
	return s;
}

int EPSMap::get_map_variable_index_forgivingly(wchar_t *name) {
	for (int s=0; s<NO_MAP_PARAMETERS; s++)
		if ((global_map_scope.values[s].name) &&
			(Wide::cmp(name, global_map_scope.values[s].name) == 0))
			return s;
	return -1;
}

@h Map parameter scopes.
Here goes, then: an initialised set of parameters.

=
void EPSMap::prepare_map_parameter_scope(map_parameter_scope *scope) {
	int s;
	scope->wider_scope = &global_map_scope;
	for (s=0; s<NO_MAP_PARAMETERS; s++) {
		scope->values[s].specified = FALSE;
		scope->values[s].name = NULL;
		scope->values[s].string_value = NULL;
		scope->values[s].numeric_value = 0;
	}
}

@ The following sets a parameter to a given value (the string value if that's
non-|NULL|, the number value otherwise), for a particular scope: this is
slightly wastefully specified either as a |map_parameter_scope| object,
or as a single room, or as a single region, or as a kind of room or region.
If all are null, then the global scope is used.

=
void EPSMap::put_mp(wchar_t *name, map_parameter_scope *scope, instance *scope_I,
	kind *scope_k, wchar_t *put_string, int put_integer) {
	if (scope_I) {
		if (Spatial::object_is_a_room(scope_I))
			scope = EPSMap::scope_for_single_room(scope_I);
		else if (Regions::object_is_a_region(scope_I)) {
			instance *rm;
			LOOP_OVER_INSTANCES(rm, K_room)
				if (EPSMap::obj_in_region(rm, scope_I))
					EPSMap::put_mp(name, NULL, rm, NULL, put_string, put_integer);
			return;
		} else return;
	}
	if (scope_k) {
		instance *I;
		LOOP_OVER_INSTANCES(I, scope_k)
			EPSMap::put_mp(name, NULL, I, NULL, put_string, put_integer);
		return;
	}
	if (scope == NULL) scope = &global_map_scope;
	if (Wide::cmp(name, L"room-colour") == 0) {
		if (scope == &global_map_scope) changed_global_room_colour = TRUE;
		if (scope_I) MAP_DATA(scope_I)->world_index_colour = put_string;
	}
	if (Wide::cmp(name, L"room-name-colour") == 0)
		if (scope_I) MAP_DATA(scope_I)->world_index_text_colour = put_string;
	if (put_string) EPSMap::put_string_mp(name, scope, put_string);
	else EPSMap::put_int_mp(name, scope, put_integer);
}

map_parameter_scope *EPSMap::scope_for_single_room(instance *rm) {
	return &(MAP_DATA(rm)->local_map_parameters);
}

int EPSMap::obj_in_region(instance *I, instance *reg) {
	if ((I == NULL) || (reg == NULL)) return FALSE;
	if (Regions::enclosing(I) == reg) return TRUE;
	return EPSMap::obj_in_region(Regions::enclosing(I), reg);
}

@ String parameters.

=
wchar_t *EPSMap::get_string_mp(wchar_t *name, map_parameter_scope *scope) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	wchar_t *p = scope->values[s].string_value;
	if (Wide::cmp(p, L"<font>") == 0) return EPSMap::get_string_mp(L"font", NULL);
	return p;
}

void EPSMap::put_string_mp(wchar_t *name, map_parameter_scope *scope, wchar_t *val) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	scope->values[s].specified = TRUE;
	scope->values[s].string_value = val;
}

text_stream *EPSMap::get_stream_mp(wchar_t *name, map_parameter_scope *scope) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	return scope->values[s].stream_value;
}

void EPSMap::put_stream_mp(wchar_t *name, map_parameter_scope *scope, text_stream *val) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	scope->values[s].specified = TRUE;
	scope->values[s].stream_value = Str::duplicate(val);
}

@ Integer parameters.

=
int EPSMap::get_int_mp(wchar_t *name, map_parameter_scope *scope) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	return scope->values[s].numeric_value;
}

void EPSMap::put_int_mp(wchar_t *name, map_parameter_scope *scope, int val) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	scope->values[s].specified = TRUE;
	scope->values[s].numeric_value = val;
}

@h Parsing sentences which set map parameters.
This happens in two passes: pass 1 before HTML mapping, pass 2 before EPS mapping.

@e TRAVERSE_FOR_MAP1_SMFT
@e TRAVERSE_FOR_MAP2_SMFT

=
void EPSMap::traverse_for_map_parameters(int pass) {
	if (pass == 1) PL::SpatialMap::initialise_page_directions();
	SyntaxTree::traverse_intp(Task::syntax_tree(), EPSMap::look_for_map_parameters, &pass);
}

void EPSMap::look_for_map_parameters(parse_node *p, int *pass) {
	if ((Node::get_type(p) == SENTENCE_NT)
		&& (p->down)) {
		if (*pass == 1) MajorNodes::try_special_meaning(TRAVERSE_FOR_MAP1_SMFT, p->down);
		else MajorNodes::try_special_meaning(TRAVERSE_FOR_MAP2_SMFT, p->down);
	}
}

@ =
int EPSMap::index_map_with_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Index map with ..." */
		case ACCEPT_SMFT:
			<np-articled-list>(OW);
			V->next = <<rp>>;
			return TRUE;
		case TRAVERSE_FOR_MAP1_SMFT:
			EPSMap::new_map_hint_sentence(1, V->next);
			break;
		case TRAVERSE_FOR_MAP2_SMFT:
			EPSMap::new_map_hint_sentence(2, V->next);
			break;
		case TRAVERSE_FOR_MAP_INDEX_SMFT:
			LOG("\nIndex map with %+W.\n", Node::get_text(V->next));
			break;
	}
	return FALSE;
}

@ This conveniently filters instance names to accept only those of kind
"direction".

=
<direction-name> ::=
	<instance-of-object>		==> { pass 1 }; if (Instances::of_kind(RP[1], K_direction) == FALSE) return FALSE;

@ The subject noun phrase of sentences like this:

>> Index map with Chamber mapped north of Cave and EPS file.

is an articled list of subjects (in this case, two of them); each subject
is parsed with the following grammar, which is almost a mini-language in
itself.

=
<index-map-sentence-subject> ::=
	eps file |                                       ==> { EPSFILE_IMW, - }
	<direction-name> mapped as <direction-name> |    ==> { MAPPED_AS_IMW, -, <<instance:x>> = RP[1], <<instance:y>> = RP[2] }
	... mapped as ... |                              ==> @<Issue PM_MapDirectionClue problem@>
	<instance-of-object> mapped <map-positioning> |  ==> { MAPPED_IMW, -, <<instance:x>> = RP[1], <<instance:y>> = RP[2] }
	... mapped ... |                                 ==> @<Issue PM_MapPlacement problem@>
	<map-setting> set to <map-setting-value> |       ==> { EPSMap::setting(R[1]), -, <<scoping>> = R[1], <<msvtype>> = R[2] }
	<map-setting> set to ... |                       ==> @<Issue PM_MapSettingTooLong problem@>
	... set to ... |                                 ==> @<Issue PM_MapSettingOfUnknown problem@>
	rubric {<quoted-text-without-subs>} *** |        ==> { RUBRIC_IMW, - }
	...                                              ==> @<Issue PM_MapHintUnknown problem@>

<map-positioning> ::=
	<instance-of-object> of/from <instance-of-object> |  ==> { TRUE, RP[2], <<instance:dir>> = RP[1] }
	above <instance-of-object> |                         ==> { TRUE, RP[1], <<instance:dir>> = I_up }
	below <instance-of-object>                           ==> { TRUE, RP[1], <<instance:dir>> = I_down }

@<Issue PM_MapDirectionClue problem@> =
	if (index_map_with_pass == 1)
		StandardProblems::map_problem(_p_(PM_MapDirectionClue),
			index_map_with_p, "You can only say 'Index map with D mapped as E.' "
			"when D and E are directions.");
	==> { NO_IMW, - };

@<Issue PM_MapPlacement problem@> =
	if (index_map_with_pass == 1)
		StandardProblems::map_problem(_p_(PM_MapPlacement),
			index_map_with_p, "The map placement hint should either have the form 'Index map with X "
			"mapped east of Y' or 'Index map with X mapped above/below Y'.");
	==> { NO_IMW, - };

@<Issue PM_MapSettingTooLong problem@> =
	if (index_map_with_pass == 1)
		StandardProblems::map_problem(_p_(PM_MapSettingTooLong),
			index_map_with_p, "The value supplied has to be a single item, a number, a word "
			"or some text in double-quotes: this looks too long to be right.");
	==> { NO_IMW, - };

@<Issue PM_MapSettingOfUnknown problem@> =
	@<Actually issue PM_MapSettingOfUnknown problem@>;
	==> { NO_IMW, - };

@<Issue PM_MapHintUnknown problem@> =
	if (index_map_with_pass == 2)
		StandardProblems::map_problem(_p_(PM_MapHintUnknown),
			index_map_with_p, "The general form for this is 'Index map with ...' and then a "
			"list of clues, such as 'the Ballroom mapped east of the Terrace', "
			"or 'room-size of the Ballroom set to 100'.");
	==> { NO_IMW, - };

@ =
int EPSMap::setting(int N) {
	if (N == NO_IMW) return N;
	return SETTING_IMW;
}

@ Now we parse the setting to be set. For example,

>> title-size of the first room
>> border-size of level 1
>> room-outline-thickness of the Taj Mahal
>> title-size

=
<map-setting> ::=
	<map-parameter> of <map-setting-scope> |  ==> { R[2], -, <<wchar_t:partext>> = RP[1], <<parindex>> = R[1] }
	<map-parameter> |                         ==> { ENTIRE_MAP_SCOPE, -, <<wchar_t:partext>> = RP[1], <<parindex>> = R[1] }
	... of <map-setting-scope>                ==> @<Issue PM_MapSettingUnknown problem@>

<map-setting-scope> ::=
	<definite-article> <map-setting-scope-unarticled> |  ==> { pass 2 }
	<map-setting-scope-unarticled>                       ==> { pass 1 }

<map-setting-scope-unarticled> ::=
	first room |               ==> { FIRST_ROOM_MAP_SCOPE, - }
	level <cardinal-number> |  ==> { LEVEL_MAP_SCOPE, -, <<level>> = R[1] }
	<k-kind> |                 ==> { KIND_MAP_SCOPE, -, <<kind:kscope>> = RP[1] }
	<instance-of-object>       ==> { INSTANCE_MAP_SCOPE, -, <<instance:iscope>> = RP[1] }

@ The map parameters all have one-word, sometimes hyphenated, names, such
as the following:

>> vertical-spacing, monochrome, annotation-size

For now, at least, these are all in English only.

=
<map-parameter> internal {
	int i;
	wchar_t *parameter_name = Lexer::word_text(Wordings::first_wn(W));
	if ((Wordings::length(W) == 1) &&
		((i = EPSMap::get_map_variable_index_forgivingly(parameter_name))>=0)) {
		==> { i, parameter_name };
		return TRUE;
	}
	==> { fail nonterminal };
}

@<Issue PM_MapSettingUnknown problem@> =
	if (index_map_with_pass == 1)
		StandardProblems::map_problem(_p_(PM_MapSettingUnknown),
			index_map_with_p, "The parameter has to be one of the fixed named set given in "
			"the documentation, like 'room-name'. All parameters are one "
			"word, but many are hyphenated. (Also, note that 'colour' has the "
			"Canadian/English spelling, not the American one 'color'.)");
	==> { NO_IMW, - };

@ The value of map settings is as follows. In retrospect, the "booleans"
perhaps should just have been "true" and "false", not "on" and "off".
Never mind.

=
<map-setting-value> ::=
	<cardinal-number> |      ==> { INT_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }
	<quoted-text> |          ==> { TEXT_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }
	<map-setting-boolean> |  ==> { BOOL_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }
	<map-offset> |           ==> { OFF_MDT, -, <<msvalue>> = R[1], <<msword>> = Wordings::first_wn(W) }; if (R[1] == ERRONEOUS_OFFSET_VALUE) return FALSE;
	###                      ==> { -1, -, <<msword>> = Wordings::first_wn(W) } /* leads to a problem message later */

<map-setting-boolean> ::=
	on |                     ==> { TRUE, - }
	off                      ==> { FALSE, - }

@ Map offsets have a cutesy notation: |10&-30|, for example, written as a
single word. The following nonterminal actually matches any single word
(so that problems can be caught later, not now), returning either a valid
offset or else the |ERRONEOUS_OFFSET_VALUE| sentinel.

=
<map-offset> internal 1 {
	==> { EPSMap::parse_eps_map_offset(W), - };
	return TRUE;
}

@ The one part of the grammar not explicitly spelled out above was what to do
with the optional text which follows a rubric. This is a sequence of any of
the following:

=
<map-rubric> ::=
	size <cardinal-number> *** |               ==> { RUBRIC_SIZE, -, <<rsize>> = R[1], <<edge>> = Wordings::first_wn(WR[1]) }
	font {<quoted-text-without-subs>} *** |    ==> { RUBRIC_FONT, -, <<rfont>> = R[1], <<edge>> = Wordings::first_wn(WR[2]) }
	colour {<quoted-text-without-subs>} *** |  ==> { RUBRIC_COLOUR, -, <<rcol>> = R[1], <<edge>> = Wordings::first_wn(WR[2]) }
	at <map-offset> from ... |                 ==> { RUBRIC_OFFSET, -, <<roff>> = R[1], <<edge>> = Wordings::first_wn(WR[1]) }
	at <map-offset> ***                        ==> { RUBRIC_POSITION, -, <<roff>> = R[1], <<edge>> = Wordings::first_wn(WR[1]) }

@

@d NO_IMW 0
@d EPSFILE_IMW 1
@d MAPPED_AS_IMW 2
@d MAPPED_IMW 3
@d SETTING_IMW 4
@d RUBRIC_IMW 5

@d RUBRIC_SIZE 1
@d RUBRIC_FONT 2
@d RUBRIC_COLOUR 3
@d RUBRIC_OFFSET 4
@d RUBRIC_POSITION 5
@d FIRST_ROOM_MAP_SCOPE 1
@d LEVEL_MAP_SCOPE 2
@d KIND_MAP_SCOPE 3
@d INSTANCE_MAP_SCOPE 4
@d ENTIRE_MAP_SCOPE 5

=
void EPSMap::new_map_hint_sentence(int pass, parse_node *p) {
	if (Node::get_type(p) == AND_NT) {
		EPSMap::new_map_hint_sentence(pass, p->down);
		EPSMap::new_map_hint_sentence(pass, p->down->next);
		return;
	}
	current_sentence = p;
	index_map_with_pass = pass;
	index_map_with_p = p;

	/* the following take effect on pass 1 */
	<index-map-sentence-subject>(Node::get_text(p));
	switch (<<r>>) {
		case EPSFILE_IMW: if (pass == 1) write_EPS_format_map = TRUE;
			break;
		case MAPPED_AS_IMW: @<Parse "Index map with starboard mapped as east"-style sentences@>;
			break;
		case MAPPED_IMW: @<Parse "Index map with Ballroom mapped north of the Hallway"-style sentences@>;
			break;
		case SETTING_IMW: @<Parse "Index map with room size of Ballroom set to 72"-style sentences@>;
			break;
		case RUBRIC_IMW:
			if (pass == 2)
				@<Parse "Index map with rubric "Here Be Dragons""-style sentences@>;
			break;
	}
}

@<Parse "Index map with starboard mapped as east"-style sentences@> =
	if (pass == 1)
		EPSMap::map_direction_as_if(<<instance:x>>, <<instance:y>>);

@<Parse "Index map with Ballroom mapped north of the Hallway"-style sentences@> =
	if (Instances::of_kind(<<instance:dir>>, K_direction) == FALSE) {
		if (pass == 1) StandardProblems::map_problem(_p_(PM_MapPlacementDirection),
			p, "The direction given as a hint for map placement wasn't "
			"one that I know of.");
		return;
	}

	instance *I = <<instance:x>>;
	instance *I2 = <<instance:y>>;
	int exit = MAP_DATA(<<instance:dir>>)->direction_index;

	if ((I == NULL) || (Spatial::object_is_a_room(I) == FALSE)) {
		if (pass == 1) StandardProblems::map_problem(_p_(PM_MapFromNonRoom),
			p, "The first-named thing must be a room (beware ambiguities!).");
		return;
	}
	if ((I2 == NULL) || (Spatial::object_is_a_room(I2) == FALSE)) {
		if (pass == 1) StandardProblems::map_problem(_p_(PM_MapToNonRoom),
			p, "The second-named thing must be a room (beware ambiguities!).");
		return;
	}
	if (PL::SpatialMap::direction_is_lateral(exit) == FALSE) {
		if (pass == 1) StandardProblems::map_problem(_p_(PM_MapNonLateral),
			p, "The direction given as a hint for map placement must be "
			"a lateral direction (not up, down, above, below, inside "
			"or outside).");
		return;
	}
	if (pass == 1) PL::SpatialMap::lock_exit_in_place(IXInstances::fi(I), exit, IXInstances::fi(I2));

@<Parse "Index map with rubric "Here Be Dragons""-style sentences@> =
	wording RW = GET_RW(<index-map-sentence-subject>, 1);
	wording RESTW = GET_RW(<index-map-sentence-subject>, 2);
	Word::dequote(Wordings::first_wn(RW));
	rubric_holder *rh = CREATE(rubric_holder);
	rh->annotation = Lexer::word_text(Wordings::first_wn(RW));
	rh->point_size = 12; /* 12-point type */
	rh->font = L"<font>"; /* meaning the default font */
	rh->colour = L"000000"; /* black */
	rh->at_offset = 10001; /* the offset $(1, 1)$ */
	rh->offset_from = NULL;
	int i = Wordings::first_wn(RESTW);
	while (i <= Wordings::last_wn(RESTW)) {
		if (<map-rubric>(Wordings::from(RESTW, i))) {
			i = <<edge>>;
			switch (<<r>>) {
				case RUBRIC_SIZE:
					rh->point_size = <<rsize>>;
					break;
				case RUBRIC_FONT:
					Word::dequote(<<rfont>>);
					rh->font = Lexer::word_text(<<rfont>>);
					break;
				case RUBRIC_COLOUR:
					@<Make a rubric colour setting@>; break;
				case RUBRIC_OFFSET:
				case RUBRIC_POSITION:
					@<Make a rubric offset setting@>; break;
			}
		} else {
			StandardProblems::map_problem(_p_(PM_MapBadRubric),
				p, "Unfortunately the details of that rubric seem to be "
				"in error (a lame message, but an accurate one).");
			break;
		}
	}

@<Make a rubric colour setting@> =
	Word::dequote(<<rcol>>);
	wchar_t *thec = HTML::translate_colour_name(Lexer::word_text(<<rcol>>));
	if (thec == NULL) {
		StandardProblems::map_problem(_p_(PM_MapUnknownColour), p, "There's no such map colour.");
		return;
	}
	rh->colour = thec;

@<Make a rubric offset setting@> =
	if (<<roff>> == ERRONEOUS_OFFSET_VALUE) {
		StandardProblems::map_problem(_p_(PM_MapUnknownOffset), p, "There's no such offset.");
		return;
	}
	rh->at_offset = <<roff>>;

	if (<<r>> == RUBRIC_OFFSET) {
		wording RW = Wordings::from(Node::get_text(p), i);
		instance *I = NULL;
		if (<instance-of-object>(RW)) I = <<rp>>;
		i = Wordings::last_wn(RESTW) + 1;
		if (I == NULL) {
			StandardProblems::map_problem(_p_(PM_MapUnknownOffsetBase),
				p, "There's no such room to be offset from.");
			return;
		}
		rh->offset_from = I;
	}

@ Finally, then, sentences which set parameters for the EPS map-maker.

@<Parse "Index map with room size of Ballroom set to 72"-style sentences@> =
	int allow_on_pass_2 = FALSE;
	map_parameter_scope *scope = NULL;
	instance *scope_I = NULL;
	kind *scope_k = NULL;
	@<Determine the scope for which the parameter is being set@>;
	if ((allow_on_pass_2 == FALSE) && (pass == 2)) return;
	wchar_t *parameter_name = <<wchar_t:partext>>;
	int index_of_parameter = <<parindex>>;
	@<Check that the value has the right type for this map parameter, and set it@>;

@<Determine the scope for which the parameter is being set@> =
	int bad_scope = FALSE;
	switch (<<scoping>>) {
		case FIRST_ROOM_MAP_SCOPE: {
			instance *first = Spatial::get_benchmark_room();
			if (first) scope_I = first;
			break;
		}
		case LEVEL_MAP_SCOPE:
			if (pass == 1) return; /* we'll pick this up on pass 2 when levels exist */
			allow_on_pass_2 = TRUE;
			int ln = <<level>>;
			EPS_map_level *eml;
			LOOP_OVER(eml, EPS_map_level)
				if ((eml->contains_rooms)
					&& (eml->map_level - PL::SpatialMap::benchmark_level() == ln))
					scope = &(eml->map_parameters);
			if (scope == NULL) {
				StandardProblems::map_problem(_p_(PM_MapLevelMisnamed),
					p, "Layers of the map must be called 'level N', where "
					"N is a number, and level 0 is the one which contains "
					"the first room.");
				return;
			}
			break;
		case KIND_MAP_SCOPE:
			scope_k = <<kind:kscope>>;
			if (Kinds::Behaviour::is_subkind_of_object(scope_k) == FALSE) scope_k = NULL;
			if ((scope_k) &&
				((Kinds::Behaviour::is_object_of_kind(scope_k, K_room)) ||
					(Kinds::Behaviour::is_object_of_kind(scope_k, K_region)))) {
				LOGIF(SPATIAL_MAP, "Setting for kind %u\n", scope_k);
			} else bad_scope = TRUE;
			break;
		case INSTANCE_MAP_SCOPE:
			if ((Spatial::object_is_a_room(<<instance:iscope>>)) ||
				(Regions::object_is_a_region(<<instance:iscope>>)))
				scope_I = <<instance:iscope>>;
			if (scope_I) {
				LOGIF(SPATIAL_MAP, "Setting for object $O\n", scope_I);
			} else bad_scope = TRUE;
			break;
		case ENTIRE_MAP_SCOPE:
			scope_k = K_room;
			break;
	}

	if (bad_scope) {
		@<Actually issue PM_MapSettingOfUnknown problem@>;
		return;
	}

@<Actually issue PM_MapSettingOfUnknown problem@> =
	if (index_map_with_pass == 1) {
		StandardProblems::map_problem(_p_(PM_MapSettingOfUnknown),
			index_map_with_p, "The parameter has to be 'of' either 'the first room' "
			"or a specific named room (beware ambiguities!) or "
			"a level such as 'level 0' (the first room is by "
			"definition on level 0), or a region, or a kind of room.");
	}

@<Check that the value has the right type for this map parameter, and set it@> =
	int type_wanted = global_map_scope.values[index_of_parameter].parameter_data_type;
	int type_found = <<msvtype>>;
	char *i_wanted_a = "";
	int wn = <<msword>>;
	switch(type_wanted) {
		case INT_MDT: i_wanted_a = "an integer";
			if (type_found == INT_MDT) {
				EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case OFF_MDT: i_wanted_a = "an offset in the form 34&-450";
			if (type_found == OFF_MDT) {
				EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case BOOL_MDT: i_wanted_a = "'on' or 'off'";
			if (type_found == BOOL_MDT) {
				EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case TEXT_MDT: i_wanted_a = "some text in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, Lexer::word_text(wn), 0);
				return;
			}
			break;
		case FONT_MDT: i_wanted_a = "a font name in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, Lexer::word_text(wn), 0);
				return;
			}
			break;
		case COL_MDT: i_wanted_a = "a colour name in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				wchar_t *col = HTML::translate_colour_name(Lexer::word_text(wn));
				if (col) {
					EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, col, 0);
					return;
				}
			}
			break;
		default: internal_error("Unexpected map parameter data type");
	}
	if (pass == 1) StandardProblems::map_problem_wanted_but(_p_(PM_MapSettingTypeFailed),
		p, i_wanted_a, wn);

@ 

=
void EPSMap::map_direction_as_if(instance *I, instance *I2) {
	story_dir_to_page_dir[MAP_DATA(I)->direction_index] = MAP_DATA(I2)->direction_index;
}

@h Offset notation.
The offset parameter $(x, y)$ is stored as the integer $10000y + x$. Except
for the error value, we are required to have $-9999 \leq x, y \leq 9999$, and
the syntax to specify this is two literal numbers divided by an ampersand.
For instance, |28&-125| means $(28, -125)$ which is stored as $-1249972$.

@d ERRONEOUS_OFFSET_VALUE 100000000

=
int EPSMap::parse_eps_map_offset(wording W) {
	TEMPORARY_TEXT(offs)
	WRITE_TO(offs, "%W", Wordings::one_word(Wordings::first_wn(W)));
	if (Str::len(offs) >= 30) return ERRONEOUS_OFFSET_VALUE;
	match_results mr = Regexp::create_mr();
	int xbit = 0, ybit = 0;
	if (Regexp::match(&mr, offs, L"(%c*?)&(%c*)")) {
		xbit = Str::atoi(mr.exp[0], 0), ybit = Str::atoi(mr.exp[1], 0);
		Regexp::dispose_of(&mr);
	} else return ERRONEOUS_OFFSET_VALUE;
	DISCARD_TEXT(offs)
	return xbit + ybit*10000;
}
