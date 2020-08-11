[PL::EPSMap::] EPS Map.

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
int PL::EPSMap::get_map_variable_index(wchar_t *name) {
	int s = PL::EPSMap::get_map_variable_index_forgivingly(name);
	if (s < 0) {
		LOG("Tried to look up <%w>\n", name);
		internal_error("looked up non-existent map variable");
		s = 0;
	}
	return s;
}

int PL::EPSMap::get_map_variable_index_forgivingly(wchar_t *name) {
	for (int s=0; s<NO_MAP_PARAMETERS; s++)
		if ((global_map_scope.values[s].name) &&
			(Wide::cmp(name, global_map_scope.values[s].name) == 0))
			return s;
	return -1;
}

@h Map parameter scopes.
Here goes, then: an initialised set of parameters.

=
void PL::EPSMap::prepare_map_parameter_scope(map_parameter_scope *scope) {
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
void PL::EPSMap::put_mp(wchar_t *name, map_parameter_scope *scope, instance *scope_I,
	kind *scope_k, wchar_t *put_string, int put_integer) {
	if (scope_I) {
		if (PL::Spatial::object_is_a_room(scope_I))
			scope = PL::EPSMap::scope_for_single_room(scope_I);
		else if (PL::Regions::object_is_a_region(scope_I)) {
			instance *rm;
			LOOP_OVER_INSTANCES(rm, K_room)
				if (PL::EPSMap::obj_in_region(rm, scope_I))
					PL::EPSMap::put_mp(name, NULL, rm, NULL, put_string, put_integer);
			return;
		} else return;
	}
	if (scope_k) {
		instance *I;
		LOOP_OVER_INSTANCES(I, scope_k)
			PL::EPSMap::put_mp(name, NULL, I, NULL, put_string, put_integer);
		return;
	}
	if (scope == NULL) scope = &global_map_scope;
	if (Wide::cmp(name, L"room-colour") == 0) {
		if (scope == &global_map_scope) changed_global_room_colour = TRUE;
		if (scope_I) PF_I(map, scope_I)->world_index_colour = put_string;
	}
	if (Wide::cmp(name, L"room-name-colour") == 0)
		if (scope_I) PF_I(map, scope_I)->world_index_text_colour = put_string;
	if (put_string) PL::EPSMap::put_string_mp(name, scope, put_string);
	else PL::EPSMap::put_int_mp(name, scope, put_integer);
}

map_parameter_scope *PL::EPSMap::scope_for_single_room(instance *rm) {
	return &(PF_I(map, rm)->local_map_parameters);
}

int PL::EPSMap::obj_in_region(instance *I, instance *reg) {
	if ((I == NULL) || (reg == NULL)) return FALSE;
	if (PL::Regions::enclosing(I) == reg) return TRUE;
	return PL::EPSMap::obj_in_region(PL::Regions::enclosing(I), reg);
}

@ String parameters.

=
wchar_t *PL::EPSMap::get_string_mp(wchar_t *name, map_parameter_scope *scope) {
	int s = PL::EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	wchar_t *p = scope->values[s].string_value;
	if (Wide::cmp(p, L"<font>") == 0) return PL::EPSMap::get_string_mp(L"font", NULL);
	return p;
}

void PL::EPSMap::put_string_mp(wchar_t *name, map_parameter_scope *scope, wchar_t *val) {
	int s = PL::EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	scope->values[s].specified = TRUE;
	scope->values[s].string_value = val;
}

text_stream *PL::EPSMap::get_stream_mp(wchar_t *name, map_parameter_scope *scope) {
	int s = PL::EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	return scope->values[s].stream_value;
}

void PL::EPSMap::put_stream_mp(wchar_t *name, map_parameter_scope *scope, text_stream *val) {
	int s = PL::EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	scope->values[s].specified = TRUE;
	scope->values[s].stream_value = Str::duplicate(val);
}

@ Integer parameters.

=
int PL::EPSMap::get_int_mp(wchar_t *name, map_parameter_scope *scope) {
	int s = PL::EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	return scope->values[s].numeric_value;
}

void PL::EPSMap::put_int_mp(wchar_t *name, map_parameter_scope *scope, int val) {
	int s = PL::EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = &global_map_scope;
	scope->values[s].specified = TRUE;
	scope->values[s].numeric_value = val;
}

@h Parsing sentences which set map parameters.
This happens in two passes: pass 1 before HTML mapping, pass 2 before EPS mapping.

@e TRAVERSE_FOR_MAP1_SMFT
@e TRAVERSE_FOR_MAP2_SMFT

=
void PL::EPSMap::traverse_for_map_parameters(int pass) {
	if (pass == 1) PL::SpatialMap::initialise_page_directions();
	SyntaxTree::traverse_intp(Task::syntax_tree(), PL::EPSMap::look_for_map_parameters, &pass);
}

void PL::EPSMap::look_for_map_parameters(parse_node *p, int *pass) {
	if ((Node::get_type(p) == SENTENCE_NT)
		&& (p->down)) {
		if (*pass == 1) MajorNodes::try_special_meaning(TRAVERSE_FOR_MAP1_SMFT, p->down);
		else MajorNodes::try_special_meaning(TRAVERSE_FOR_MAP2_SMFT, p->down);
	}
}

@ =
int PL::EPSMap::index_map_with_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Index map with ..." */
		case ACCEPT_SMFT:
			<np-articled-list>(OW);
			V->next = <<rp>>;
			return TRUE;
		case TRAVERSE_FOR_MAP1_SMFT:
			PL::EPSMap::new_map_hint_sentence(1, V->next);
			break;
		case TRAVERSE_FOR_MAP2_SMFT:
			PL::EPSMap::new_map_hint_sentence(2, V->next);
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
	<map-setting> set to <map-setting-value> |       ==> { PL::EPSMap::setting(R[1]), -, <<scoping>> = R[1], <<msvtype>> = R[2] }
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
int PL::EPSMap::setting(int N) {
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
		((i = PL::EPSMap::get_map_variable_index_forgivingly(parameter_name))>=0)) {
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
	==> { PL::EPSMap::parse_eps_map_offset(W), - };
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
void PL::EPSMap::new_map_hint_sentence(int pass, parse_node *p) {
	if (Node::get_type(p) == AND_NT) {
		PL::EPSMap::new_map_hint_sentence(pass, p->down);
		PL::EPSMap::new_map_hint_sentence(pass, p->down->next);
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
		PL::SpatialMap::map_direction_as_if(<<instance:x>>, <<instance:y>>);

@<Parse "Index map with Ballroom mapped north of the Hallway"-style sentences@> =
	if (Instances::of_kind(<<instance:dir>>, K_direction) == FALSE) {
		if (pass == 1) StandardProblems::map_problem(_p_(PM_MapPlacementDirection),
			p, "The direction given as a hint for map placement wasn't "
			"one that I know of.");
		return;
	}

	instance *I = <<instance:x>>;
	instance *I2 = <<instance:y>>;
	int exit = PF_I(map, <<instance:dir>>)->direction_index;

	if ((I == NULL) || (PL::Spatial::object_is_a_room(I) == FALSE)) {
		if (pass == 1) StandardProblems::map_problem(_p_(PM_MapFromNonRoom),
			p, "The first-named thing must be a room (beware ambiguities!).");
		return;
	}
	if ((I2 == NULL) || (PL::Spatial::object_is_a_room(I2) == FALSE)) {
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
	if (pass == 1) PL::SpatialMap::lock_exit_in_place(I, exit, I2);

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
		instance *I = Instances::parse_object(Wordings::from(Node::get_text(p), i));
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
		case FIRST_ROOM_MAP_SCOPE:
			if (benchmark_room) scope_I = benchmark_room;
			break;
		case LEVEL_MAP_SCOPE:
			if (pass == 1) return; /* we'll pick this up on pass 2 when levels exist */
			allow_on_pass_2 = TRUE;
			int ln = <<level>>;
			EPS_map_level *eml;
			LOOP_OVER(eml, EPS_map_level)
				if ((eml->contains_rooms)
					&& (eml->map_level - Room_position(benchmark_room).z == ln))
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
			if ((PL::Spatial::object_is_a_room(<<instance:iscope>>)) ||
				(PL::Regions::object_is_a_region(<<instance:iscope>>)))
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
				PL::EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case OFF_MDT: i_wanted_a = "an offset in the form 34&-450";
			if (type_found == OFF_MDT) {
				PL::EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case BOOL_MDT: i_wanted_a = "'on' or 'off'";
			if (type_found == BOOL_MDT) {
				PL::EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, NULL, <<msvalue>>);
				return;
			}
			break;
		case TEXT_MDT: i_wanted_a = "some text in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				PL::EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, Lexer::word_text(wn), 0);
				return;
			}
			break;
		case FONT_MDT: i_wanted_a = "a font name in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				PL::EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, Lexer::word_text(wn), 0);
				return;
			}
			break;
		case COL_MDT: i_wanted_a = "a colour name in double-quotes";
			if (type_found == TEXT_MDT) {
				Word::dequote(wn);
				wchar_t *col = HTML::translate_colour_name(Lexer::word_text(wn));
				if (col) {
					PL::EPSMap::put_mp(parameter_name, scope, scope_I, scope_k, col, 0);
					return;
				}
			}
			break;
		default: internal_error("Unexpected map parameter data type");
	}
	if (pass == 1) StandardProblems::map_problem_wanted_but(_p_(PM_MapSettingTypeFailed),
		p, i_wanted_a, wn);

@h Offset notation.
The offset parameter $(x, y)$ is stored as the integer $10000y + x$. Except
for the error value, we are required to have $-9999 \leq x, y \leq 9999$, and
the syntax to specify this is two literal numbers divided by an ampersand.
For instance, |28&-125| means $(28, -125)$ which is stored as $-1249972$.

@d ERRONEOUS_OFFSET_VALUE 100000000

=
int PL::EPSMap::parse_eps_map_offset(wording W) {
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

@ =
void PL::EPSMap::render_map_as_EPS(void) {
	@<Create the main EPS map super-level@>;
	int z;
	for (z=Universe.corner1.z; z>=Universe.corner0.z; z--)
		@<Create an EPS map level for this z-slice@>;

	PL::EPSMap::traverse_for_map_parameters(2);
	if (changed_global_room_colour == FALSE)
		@<Inherit EPS room colours from those used in the World Index@>;

	if (write_EPS_format_map) @<Open a stream and write the EPS map to it@>;
}

@<Create the main EPS map super-level@> =
	EPS_map_level *main_eml = CREATE(EPS_map_level);
	main_eml->width = PL::EPSMap::get_int_mp(L"minimum-map-width", NULL);
	main_eml->actual_height = 0;
	main_eml->titling_point_size = PL::EPSMap::get_int_mp(L"title-size", NULL);
	main_eml->titling = Str::new();
	WRITE_TO(main_eml->titling, "Map");
	main_eml->contains_titling = TRUE;
	main_eml->contains_rooms = FALSE;
	PL::EPSMap::prepare_map_parameter_scope(&(main_eml->map_parameters));
	PL::EPSMap::put_stream_mp(L"title", &(main_eml->map_parameters), main_eml->titling);

@<Create an EPS map level for this z-slice@> =
	EPS_map_level *eml = CREATE(EPS_map_level);
	eml->contains_rooms = TRUE;
	eml->map_level = z;

	eml->y_max = -100000, eml->y_min = 100000;
	instance *R;
	LOOP_OVER_ROOMS(R)
		if (Room_position(R).z == z) {
			if (Room_position(R).y < eml->y_min) eml->y_min = Room_position(R).y;
			if (Room_position(R).y > eml->y_max) eml->y_max = Room_position(R).y;
		}

	Str::clear(eml->titling);
	char *level_rubric = "Map"; int par = 0;
	PL::HTMLMap::devise_level_rubric(z, &level_rubric, &par);
	WRITE_TO(eml->titling, level_rubric, par);

	if (Str::len(eml->titling) == 0) eml->contains_titling = FALSE;
	else eml->contains_titling = TRUE;

	PL::EPSMap::prepare_map_parameter_scope(&(eml->map_parameters));
	PL::EPSMap::put_stream_mp(L"subtitle", &(eml->map_parameters), eml->titling);

	LOOP_OVER_ROOMS(R)
		if (Room_position(R).z == z) {
			PF_I(map, R)->local_map_parameters.wider_scope = &(eml->map_parameters);
		}

@<Inherit EPS room colours from those used in the World Index@> =
	instance *R;
	LOOP_OVER_ROOMS(R)
		PL::EPSMap::put_string_mp(L"room-colour", &(PF_I(map, R)->local_map_parameters),
			PF_I(map, R)->world_index_colour);

@<Open a stream and write the EPS map to it@> =
	filename *F = Task::epsmap_file();
	text_stream EPS_struct; text_stream *EPS = &EPS_struct;
	if (STREAM_OPEN_TO_FILE(EPS, F, ISO_ENC) == FALSE)
		Problems::fatal_on_file("Can't open EPS map file", F);
	PL::EPSMap::EPS_compile_map(EPS);
	STREAM_CLOSE(EPS);

@ =
void PL::EPSMap::EPS_compile_map(OUTPUT_STREAM) {
	int blh, /* total height of the EPS map area (not counting border) */
		blw, /* total width of the EPS map area (not counting border) */
		border = PL::EPSMap::get_int_mp(L"border-size", NULL),
		vskip = PL::EPSMap::get_int_mp(L"vertical-spacing", NULL);
	@<Compute the dimensions of the EPS map@>;
	int bounding_box_width = blw+2*border, bounding_box_height = blh+2*border;

	PL::EPSMap::EPS_compile_header(OUT, bounding_box_width, bounding_box_height,
		PL::EPSMap::get_string_mp(L"title-font", NULL), PL::EPSMap::get_int_mp(L"title-size", NULL));

	if (PL::EPSMap::get_int_mp(L"map-outline", NULL))
		@<Draw a big rectangular outline around the entire EPS map@>;

	EPS_map_level *eml;
	LOOP_OVER(eml, EPS_map_level) {
		map_parameter_scope *level_scope = &(eml->map_parameters);
		int mapunit = PL::EPSMap::get_int_mp(L"grid-size", level_scope);
		if (eml->contains_rooms == FALSE)
			if (PL::EPSMap::get_int_mp(L"map-outline", NULL))
				@<Draw an intermediate strut in the big rectangular outline@>;
		if (eml->contains_titling)
			@<Draw the title for this EPS map level@>;
		if (eml->contains_rooms) {
			instance *R;
			LOOP_OVER_ROOMS(R)
				if (Room_position(R).z == eml->map_level)
					@<Establish EPS coordinates for this room@>;
			LOOP_OVER_ROOMS(R)
				if (Room_position(R).z == eml->map_level)
					@<Draw the map connections from this room as EPS paths@>;
			LOOP_OVER_ROOMS(R)
				if (Room_position(R).z == eml->map_level)
					@<Draw the boxes for the rooms themselves@>;
		}
	}

	@<Plot all of the rubrics onto the EPS map@>;
}

@<Compute the dimensions of the EPS map@> =
	int total_chunk_height = 0, max_chunk_width = 0;
	EPS_map_level *eml;
	LOOP_BACKWARDS_OVER(eml, EPS_map_level) {
		map_parameter_scope *level_scope = &(eml->map_parameters);
		int mapunit = PL::EPSMap::get_int_mp(L"grid-size", level_scope);
		int p = PL::EPSMap::get_int_mp(L"title-size", level_scope);
		if (eml->contains_rooms) p = PL::EPSMap::get_int_mp(L"subtitle-size", level_scope);
		eml->titling_point_size = p;
		eml->width = (Universe.corner1.x-Universe.corner0.x+2)*mapunit;
		if (eml->allocation_id == 0) eml->actual_height = 0;
		else eml->actual_height = (eml->y_max-eml->y_min+1)*mapunit;
		eml->eps_origin = total_chunk_height + border;
		eml->height = eml->actual_height + vskip;
		if (eml->contains_rooms) eml->height += vskip;
		if (eml->contains_titling) eml->height += eml->titling_point_size+vskip;
		total_chunk_height += eml->height;
		if (max_chunk_width < eml->width) max_chunk_width = eml->width;
	}
	blh = total_chunk_height;
	blw = max_chunk_width;

@ The outline is a little like drawing the shape of a bookcase: there's a big
rectangle around the whole thing...

@<Draw a big rectangular outline around the entire EPS map@> =
	WRITE("newpath %% Ruled outline outer box of map\n");
	PL::EPSMap::EPS_compile_rectangular_path(OUT, border, border, border+blw, border+blh);
	WRITE("stroke\n");

@ ...and then there are horizontal shelves dividing it into compartments.
(Each map level will be drawn inside one of these compartments.)

@<Draw an intermediate strut in the big rectangular outline@> =
	WRITE("newpath %% Ruled horizontal line\n");
	PL::EPSMap::EPS_compile_horizontal_line_path(OUT, border, blw+border, eml->eps_origin);
	WRITE("stroke\n");

@<Draw the title for this EPS map level@> =
	int y = eml->eps_origin + vskip + eml->actual_height;
	if (eml->contains_rooms) {
		if (PL::EPSMap::get_int_mp(L"monochrome", level_scope)) PL::EPSMap::EPS_compile_set_greyscale(OUT, 0);
		else PL::EPSMap::EPS_compile_set_colour(OUT, PL::EPSMap::get_string_mp(L"subtitle-colour", level_scope));
		PL::EPSMap::plot_stream_at(OUT,
			PL::EPSMap::get_stream_mp(L"subtitle", level_scope),
			NULL, 128,
			PL::EPSMap::get_string_mp(L"subtitle-font", level_scope),
			border*2, y+vskip,
			PL::EPSMap::get_int_mp(L"subtitle-size", level_scope),
			FALSE, FALSE);
	} else {
		if (PL::EPSMap::get_int_mp(L"monochrome", level_scope)) PL::EPSMap::EPS_compile_set_greyscale(OUT, 0);
		else PL::EPSMap::EPS_compile_set_colour(OUT, PL::EPSMap::get_string_mp(L"title-colour", level_scope));
		PL::EPSMap::plot_stream_at(OUT,
			PL::EPSMap::get_stream_mp(L"title", NULL),
			NULL, 128,
			PL::EPSMap::get_string_mp(L"title-font", level_scope),
			border*2, y+2*vskip,
			PL::EPSMap::get_int_mp(L"title-size", level_scope),
			FALSE, TRUE);
	}

@<Establish EPS coordinates for this room@> =
	map_parameter_scope *room_scope = &(PF_I(map, R)->local_map_parameters);
	int bx = Room_position(R).x-Universe.corner0.x;
	int by = Room_position(R).y-eml->y_min;
	int offs = PL::EPSMap::get_int_mp(L"room-offset", room_scope);
	int xpart = offs%10000, ypart = offs/10000;
	while (xpart > 5000) xpart-=10000;
	while (xpart < -5000) xpart+=10000;

	bx = (bx)*mapunit + border + mapunit/2;
	by = (by)*mapunit + eml->eps_origin + vskip + mapunit/2;

	bx += xpart*mapunit/100;
	by += ypart*mapunit/100;

	PF_I(map, R)->eps_x = bx;
	PF_I(map, R)->eps_y = by;

@<Draw the map connections from this room as EPS paths@> =
	map_parameter_scope *room_scope = &(PF_I(map, R)->local_map_parameters);
	PL::EPSMap::EPS_compile_line_width_setting(OUT, PL::EPSMap::get_int_mp(L"route-thickness", room_scope));

	int bx = PF_I(map, R)->eps_x;
	int by = PF_I(map, R)->eps_y;
	int boxsize = PL::EPSMap::get_int_mp(L"room-size", room_scope)/2;
	int R_stiffness = PL::EPSMap::get_int_mp(L"route-stiffness", room_scope);
	int dir;
	LOOP_OVER_STORY_DIRECTIONS(dir) {
		instance *T = PL::SpatialMap::room_exit(R, dir, NULL);
		int exit = story_dir_to_page_dir[dir];
		if (PL::Spatial::object_is_a_room(T))
			@<Draw a single map connection as an EPS arrow@>;
	}
	PL::EPSMap::EPS_compile_line_width_unsetting(OUT);

@<Draw a single map connection as an EPS arrow@> =
	int T_stiffness = PL::EPSMap::get_int_mp(L"route-stiffness", &(PF_I(map, T)->local_map_parameters));
	if (PL::EPSMap::get_int_mp(L"monochrome", level_scope)) PL::EPSMap::EPS_compile_set_greyscale(OUT, 0);
	else PL::EPSMap::EPS_compile_set_colour(OUT, PL::EPSMap::get_string_mp(L"route-colour", level_scope));
	if ((Room_position(T).z == Room_position(R).z) &&
		(PL::SpatialMap::room_exit(T, PL::SpatialMap::opposite(dir), FALSE) == R))
		@<Draw a two-ended arrow for a two-way horizontal connection@>
	else
		@<Draw a one-way arrow for a distant or off-level connection@>;

@ We don't want to draw this twice (once for R, once for T), so we draw it
just for the earlier-defined room.

@<Draw a two-ended arrow for a two-way horizontal connection@> =
	if (R->allocation_id <= T->allocation_id)
		PL::EPSMap::EPS_compile_Bezier_curve(OUT,
			R_stiffness*mapunit, T_stiffness*mapunit,
			bx, by, exit,
			PF_I(map, T)->eps_x, PF_I(map, T)->eps_y, PL::SpatialMap::opposite(exit));

@ A one-way arrow has the destination marked on it textually, since it doesn't
actually go there in any visual way.

@<Draw a one-way arrow for a distant or off-level connection@> =
	int scaled = 1;
	vector E = PL::SpatialMap::direction_as_vector(exit);
	switch(exit) {
		case 8:  E = U_vector_EPS; scaled = 2; break;
		case 9:  E = D_vector_EPS; scaled = 2; break;
		case 10: E = IN_vector_EPS; scaled = 2; break;
		case 11: E = OUT_vector_EPS; scaled = 2; break;
	}
	PL::EPSMap::EPS_compile_dashed_arrow(OUT, boxsize/scaled, E, bx, by);
	PL::EPSMap::plot_text_at(OUT, NULL, T,
		PL::EPSMap::get_int_mp(L"annotation-length", NULL),
		PL::EPSMap::get_string_mp(L"annotation-font", NULL),
		bx+E.x*boxsize*6/scaled/5, by+E.y*boxsize*6/scaled/5,
		PL::EPSMap::get_int_mp(L"annotation-size", NULL),
		TRUE, TRUE);

@<Draw the boxes for the rooms themselves@> =
	map_parameter_scope *room_scope = &(PF_I(map, R)->local_map_parameters);
	int bx = PF_I(map, R)->eps_x;
	int by = PF_I(map, R)->eps_y;
	int boxsize = PL::EPSMap::get_int_mp(L"room-size", room_scope)/2;
	@<Draw the filled box for the room@>;
	@<Draw the outline of the box for the room@>;
	@<Write in the name of the room@>;

@<Draw the filled box for the room@> =
	WRITE("newpath %% Room interior\n");
	if (PL::EPSMap::get_int_mp(L"monochrome", room_scope)) PL::EPSMap::EPS_compile_set_greyscale(OUT, 75);
	else PL::EPSMap::EPS_compile_set_colour(OUT, PL::EPSMap::get_string_mp(L"room-colour", room_scope));
	PL::EPSMap::EPS_compile_room_boundary_path(OUT, bx, by, boxsize, PL::EPSMap::get_string_mp(L"room-shape", room_scope));
	WRITE("fill\n\n");

@<Draw the outline of the box for the room@> =
	if (PL::EPSMap::get_int_mp(L"room-outline", room_scope)) {
		PL::EPSMap::EPS_compile_line_width_setting(OUT, PL::EPSMap::get_int_mp(L"room-outline-thickness", room_scope));
		WRITE("newpath %% Room outline\n");
		if (PL::EPSMap::get_int_mp(L"monochrome", level_scope)) PL::EPSMap::EPS_compile_set_greyscale(OUT, 0);
		else PL::EPSMap::EPS_compile_set_colour(OUT, PL::EPSMap::get_string_mp(L"room-outline-colour", room_scope));
		PL::EPSMap::EPS_compile_room_boundary_path(OUT, bx, by, boxsize, PL::EPSMap::get_string_mp(L"room-shape", room_scope));
		WRITE("stroke\n");
		PL::EPSMap::EPS_compile_line_width_unsetting(OUT);
	}

@<Write in the name of the room@> =
	int offs = PL::EPSMap::get_int_mp(L"room-name-offset", room_scope);
	int xpart = offs%10000, ypart = offs/10000;
	while (xpart > 5000) xpart-=10000;
	while (xpart < -5000) xpart+=10000;
	bx += xpart*mapunit/100;
	by += ypart*mapunit/100;

	if (PL::EPSMap::get_int_mp(L"monochrome", level_scope)) PL::EPSMap::EPS_compile_set_greyscale(OUT, 0);
	else PL::EPSMap::EPS_compile_set_colour(OUT, PL::EPSMap::get_string_mp(L"room-name-colour", room_scope));
	wchar_t *legend = PL::EPSMap::get_string_mp(L"room-name", room_scope);
	instance *room_to_name = NULL;
	if (Wide::cmp(legend, L"") == 0) { room_to_name = R; legend = NULL; }
	PL::EPSMap::plot_text_at(OUT, legend, room_to_name,
		PL::EPSMap::get_int_mp(L"room-name-length", room_scope),
		PL::EPSMap::get_string_mp(L"room-name-font", room_scope),
		bx, by, PL::EPSMap::get_int_mp(L"room-name-size", room_scope),
		TRUE, TRUE);

@<Plot all of the rubrics onto the EPS map@> =
	rubric_holder *rh;
	LOOP_OVER(rh, rubric_holder) {
		int bx = 0, by = 0;
		int xpart = rh->at_offset%10000, ypart = rh->at_offset/10000;
		int mapunit = PL::EPSMap::get_int_mp(L"grid-size", NULL);
		while (xpart > 5000) xpart-=10000;
		while (xpart < -5000) xpart+=10000;
		if (PL::EPSMap::get_int_mp(L"monochrome", NULL)) PL::EPSMap::EPS_compile_set_greyscale(OUT, 0);
		else PL::EPSMap::EPS_compile_set_colour(OUT, rh->colour);
		if (rh->offset_from) {
			bx = PF_I(map, rh->offset_from)->eps_x;
			by = PF_I(map, rh->offset_from)->eps_y;
		}
		bx += xpart*mapunit/100; by += ypart*mapunit/100;
		PL::EPSMap::plot_text_at(OUT, rh->annotation, NULL, 128, rh->font, bx, by, rh->point_size,
			TRUE, TRUE); /* centred both horizontally and vertically */
	}

@h Writing text in EPS.
All of words written on the map -- titles, labels for arrows, rubrics, and so
on -- come from here.

@d MAX_EPS_TEXT_LENGTH 1000
@d MAX_EPS_ABBREVIATED_LENGTH MAX_EPS_TEXT_LENGTH

=
void PL::EPSMap::plot_text_at(OUTPUT_STREAM, wchar_t *text_to_plot, instance *I, int abbrev_to,
	wchar_t *font, int x, int y, int pointsize, int centre_h, int centre_v) {
	TEMPORARY_TEXT(txt)
	if (text_to_plot) {
		WRITE_TO(txt, "%w", text_to_plot);
	} else if (I) {
		@<Try taking the name from the printed name property of the room@>;
		@<If that fails, try taking the name from its source text name@>;
	} else return;
	PL::EPSMap::plot_stream_at(OUT, txt, I, abbrev_to, font, x, y, pointsize, centre_h, centre_v);
	DISCARD_TEXT(txt)
}

@<Try taking the name from the printed name property of the room@> =
	if (P_printed_name) {
		parse_node *V = World::Inferences::get_prop_state_at(
			Instances::as_subject(I), P_printed_name, NULL);
		if ((Rvalues::is_CONSTANT_of_kind(V, K_text)) &&
			(Wordings::nonempty(Node::get_text(V)))) {
			int wn = Wordings::first_wn(Node::get_text(V));
			WRITE_TO(txt, "%+W", Wordings::one_word(wn));
			if (Str::get_first_char(txt) == '\"') Str::delete_first_character(txt);
			if (Str::get_last_char(txt) == '\"') Str::delete_last_character(txt);
		}
	}

@<If that fails, try taking the name from its source text name@> =
	if (Str::len(txt) == 0) {
		wording W = Instances::get_name(I, FALSE);
		if (Wordings::empty(W)) return;
		WRITE_TO(txt, "%+W", W);
	}

@ =
void PL::EPSMap::plot_stream_at(OUTPUT_STREAM, text_stream *text_to_plot, instance *I, int abbrev_to,
	wchar_t *font, int x, int y, int pointsize, int centre_h, int centre_v) {
	TEMPORARY_TEXT(txt)
	Str::copy(txt, text_to_plot);
	@<Abbreviate the text to be printed by stripping dispensable letters@>;
	PL::EPSMap::EPS_compile_text(OUT, txt, x, y, font, pointsize, centre_h, centre_v);
	DISCARD_TEXT(txt)
}

@ The following cuts the text down to the abbreviation length by knocking out,
in sequence: (a) lower-case vowels; (b) spaces; (c) lower-case consonants; (d)
punctuation marks. If that doesn't do it, the text is simply truncated. For
example, "Peisey-Nancroix" abbreviated to 10 is "Pesy-Nncrx" and to 5
is "PsyNn".

@<Abbreviate the text to be printed by stripping dispensable letters@> =
	if (abbrev_to > MAX_EPS_ABBREVIATED_LENGTH) abbrev_to = MAX_EPS_ABBREVIATED_LENGTH;
	while (Str::len(txt) > abbrev_to) {
		int j;
		for (j=Str::len(txt)-1; j>=0; j--)
			if (Characters::vowel(Str::get_at(txt, j))) goto RemoveOne;
		for (j=Str::len(txt)-1; j>=0; j--)
			if (Str::get_at(txt, j) == ' ') goto RemoveOne;
		for (j=Str::len(txt)-1; j>=0; j--)
			if (islower(Str::get_at(txt, j))) goto RemoveOne;
		for (j=Str::len(txt)-1; j>=0; j--)
			if (isupper(Str::get_at(txt, j)) == FALSE) goto RemoveOne;
		Str::truncate(txt, abbrev_to);
		break;
		RemoveOne: Str::delete_nth_character(txt, j);
	}

@h EPS header.
EPS files are identified and version-numbered by a header, as follows.

=
void PL::EPSMap::EPS_compile_header(OUTPUT_STREAM, int bounding_box_width, int bounding_box_height,
	wchar_t *default_font, int default_point_size) {
	WRITE("%%!PS-Adobe EPSF-3.0\n");
	WRITE("%%%%BoundingBox: 0 0 %d %d\n", bounding_box_width, bounding_box_height);
	WRITE("%%%%IncludeFont: %w\n", default_font);
	WRITE("/%w findfont %d scalefont setfont\n", default_font, default_point_size);
}

@h Circles and rectangles.
In EPS files, there's an imaginary pen which traces out "paths". These begin
whenever the pen moves to a new location, and then continue until they are
closed (joined up back to the start position) with a |closepath| command.

=
void PL::EPSMap::EPS_compile_circular_path(OUTPUT_STREAM, int x0, int y0, int radius) {
	WRITE("%d %d moveto %% rightmost point\n", x0+radius, y0);
	WRITE("%d %d %d %d %d arc %% full circle traced anticlockwise\n",
		x0, y0, radius, 0, 360);
	WRITE("closepath\n");
}

void PL::EPSMap::EPS_compile_rectangular_path(OUTPUT_STREAM, int x0, int y0, int x1, int y1) {
	WRITE("%d %d moveto %% bottom left corner\n", x0, y0);
	WRITE("%d %d lineto %% bottom side\n", x1, y0);
	WRITE("%d %d lineto %% right side\n", x1, y1);
	WRITE("%d %d lineto %% top side\n", x0, y1);
	WRITE("closepath\n");
}

@ The boundary of a room is always one of these:

=
void PL::EPSMap::EPS_compile_room_boundary_path(OUTPUT_STREAM, int bx, int by, int boxsize, wchar_t *shape) {
	if (Wide::cmp(shape, L"square") == 0)
		PL::EPSMap::EPS_compile_rectangular_path(OUT, bx-boxsize, by-boxsize, bx+boxsize, by+boxsize);
	else if (Wide::cmp(shape, L"rectangle") == 0)
		PL::EPSMap::EPS_compile_rectangular_path(OUT, bx-2*boxsize, by-boxsize, bx+2*boxsize, by+boxsize);
	else if (Wide::cmp(shape, L"circle") == 0)
		PL::EPSMap::EPS_compile_circular_path(OUT, bx, by, boxsize);
	else
		PL::EPSMap::EPS_compile_rectangular_path(OUT, bx-boxsize, by-boxsize, bx+boxsize, by+boxsize);
}

@h Straight lines.

=
void PL::EPSMap::EPS_compile_horizontal_line_path(OUTPUT_STREAM, int x0, int x1, int y) {
	WRITE("%d %d moveto %% LHS\n", x0, y);
	WRITE("%d %d lineto %% RHS\n", x1, y);
	WRITE("closepath\n");
}

@h Dashed arrows.

=
void PL::EPSMap::EPS_compile_dashed_arrow(OUTPUT_STREAM, int length, vector Dir, int x0, int y0) {
	WRITE("[2 1] 0 setdash %% dashed line for arrow\n");
	WRITE("%d %d moveto %% room centre\n", x0, y0);
	WRITE("%d %d rlineto %% arrow out\n", Dir.x*length, Dir.y*length);
	WRITE("stroke\n");
	WRITE("[] 0 setdash %% back to normal solid lines\n");
}

@h Bezier curves.
The other sort of path we'll need is a Bézier curve, a quadratic curve which
interpolates between vectors. EPS has support for these built-in; see any
reference book on PostScript.

=
void PL::EPSMap::EPS_compile_Bezier_curve(OUTPUT_STREAM, int stiffness0, int stiffness1,
	int x0, int y0, int exit0, int x1, int y1, int exit1) {
	int cx1, cy1, cx2, cy2;
	vector E = PL::SpatialMap::direction_as_vector(exit0);
	cx1 = x0+E.x*stiffness0/100; cy1 = y0+E.y*stiffness0/100;
	E = PL::SpatialMap::direction_as_vector(exit1);
	cx2 = x1+E.x*stiffness1/100; cy2 = y1+E.y*stiffness1/100;
	WRITE("%d %d moveto %% start of Bezier curve\n", x0, y0);
	WRITE("%d %d %d %d %d %d curveto %% control points 1, 2 and end\n",
		cx1, cy1, cx2, cy2, x1, y1);
	WRITE("stroke\n");
}

@h Line thickness.
The following routines should be used in nested pairs, so that the PostScript
stack is kept in order.

=
void PL::EPSMap::EPS_compile_line_width_setting(OUTPUT_STREAM, int new) {
	WRITE("currentlinewidth %% Push old line width onto stack\n");
	WRITE("%d setlinewidth\n", new);
}

void PL::EPSMap::EPS_compile_line_width_unsetting(OUTPUT_STREAM) {
	WRITE("setlinewidth %% Pull old line width from stack\n");
}

@h Text.
In EPS world, text is just another sort of path.

=
void PL::EPSMap::EPS_compile_text(OUTPUT_STREAM, text_stream *text, int x, int y,
	wchar_t *font, int pointsize, int centre_h, int centre_v) {
	WRITE("/%w findfont %d scalefont setfont\n", font, pointsize);
	WRITE("newpath (%S)\n", text);
	if (centre_h) WRITE("dup stringwidth add 2 div %d exch sub %% = X centre-offset\n", x);
	else WRITE("%d %% = X\n", x);
	if (centre_v) WRITE("%d %d 2 div sub %% = Y centre-offset\n", y, pointsize);
	else WRITE("%d %% = Y\n", y);
	WRITE("moveto show\n");
}

@h RGB colours.
Inform internally stores colours as six hexadecimal digits, in traditional
HTML way: |RRGGBB|, with each colour from 0 to 255. In EPS files, colours
are written as triples of floating point numbers $0 \leq b \leq 1$.

EPS uses reverse Polish notation, so the command here is: |R G B setrgbcolor|.

=
void PL::EPSMap::EPS_compile_set_colour(OUTPUT_STREAM, wchar_t *htmlcolour) {
	if (Wide::len(htmlcolour) != 6) internal_error("Improper HTML colour");
	PL::EPSMap::choose_colour_beam(OUT, htmlcolour[0], htmlcolour[1]);
	PL::EPSMap::choose_colour_beam(OUT, htmlcolour[2], htmlcolour[3]);
	PL::EPSMap::choose_colour_beam(OUT, htmlcolour[4], htmlcolour[5]);
	WRITE("setrgbcolor %% From HTML colour %w\n", htmlcolour);
}

void PL::EPSMap::choose_colour_beam(OUTPUT_STREAM, int hex1, int hex2) {
	int k = PL::EPSMap::hex_to_int(hex1)*16 + PL::EPSMap::hex_to_int(hex2);
	WRITE("%.6g ", (double) (((float) k)/255.0));
}

int PL::EPSMap::hex_to_int(int hex) {
	switch(hex) {
		case '0': return 0;
		case '1': return 1;
		case '2': return 2;
		case '3': return 3;
		case '4': return 4;
		case '5': return 5;
		case '6': return 6;
		case '7': return 7;
		case '8': return 8;
		case '9': return 9;
		case 'a': case 'A': return 10;
		case 'b': case 'B': return 11;
		case 'c': case 'C': return 12;
		case 'd': case 'D': return 13;
		case 'e': case 'E': return 14;
		case 'f': case 'F': return 15;
		default: internal_error("Improper character in HTML colour");
	}
	return 0;
}

@ EPS also supports greyscale, where there's only one beam:

=
void PL::EPSMap::EPS_compile_set_greyscale(OUTPUT_STREAM, int N) {
	WRITE("%0.02f setgray %% greyscale %d/100ths of white\n", (float) N/100, N);
}
