[ConfigureIndexMap::] Map Configuration.

To manage configuration parameters for the EPS and HTML maps.

@ The EPS map-maker is really a miniature interpreted programming language in
its own right, and here we define that language's data types and variables.

The "mapping parameters" amount to being variables. The following structure
defines the type and current value for each variable: see the Inform
documentation for details. But note that variables of the same name are held by
many different objects in the map, and their values inherited by sub-objects.

@d INT_MDT	1 /* an integer */
@d BOOL_MDT 2 /* true or false */
@d TEXT_MDT 3 /* quoted text */
@d COL_MDT	4 /* an HTML-safe colour */
@d FONT_MDT	5 /* the name of a font */
@d OFF_MDT	6 /* a positional offset in an $(x,y)$ grid */

=
typedef struct plotting_parameter {
	int specified; /* is it explicitly specified at this scope? */
	struct text_stream *name; /* name (used only in global scope) */
	inchar32_t *name_init; /* name (used only in global scope) */
	int parameter_data_type; /* one of the above types (used only in global scope) */
	struct text_stream *textual_value; /* string value, if appropriate to this type; */
	inchar32_t *textual_value_init; /* string value, if appropriate to this type; */
	int numeric_value; /* or numeric value, if appropriate to this type */
} plotting_parameter;

@ A set of variables associated with any map object is called a "scope". As
implied above, the global scope is special: it contains the default settings
passed down to all lower scopes.

@d NO_MAP_PARAMETERS 34

=
typedef struct map_parameter_scope {
	struct map_parameter_scope *wider_scope; /* that is, the scope above this */
	struct plotting_parameter values[NO_MAP_PARAMETERS];
} map_parameter_scope;

map_parameter_scope initial_global_map_scope = {
	NULL,
	{
		{ TRUE, NULL, U"font",					FONT_MDT, NULL,	U"Helvetica", 0 },
		{ TRUE, NULL, U"minimum-map-width",		INT_MDT, NULL,	NULL, 		72*5 },
		{ TRUE, NULL, U"title",					TEXT_MDT, NULL,	U"Map", 	0 },
		{ TRUE, NULL, U"title-size",			INT_MDT, NULL,	NULL, 		24 },
		{ TRUE, NULL, U"title-font",			FONT_MDT, NULL,	U"<font>", 	0 },
		{ TRUE, NULL, U"title-colour",			COL_MDT, NULL,	U"000000", 	0 },
		{ TRUE, NULL, U"map-outline",			BOOL_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, U"border-size",			INT_MDT, NULL,	NULL, 		12 },
		{ TRUE, NULL, U"vertical-spacing",		INT_MDT, NULL,	NULL, 		6 },
		{ TRUE, NULL, U"monochrome",			BOOL_MDT, NULL,	NULL, 		0 },
		{ TRUE, NULL, U"annotation-size",		INT_MDT, NULL,	NULL, 		8 },
		{ TRUE, NULL, U"annotation-length",		INT_MDT, NULL,	NULL, 		8 },
		{ TRUE, NULL, U"annotation-font",		FONT_MDT, NULL,	U"<font>", 	0 },
		{ TRUE, NULL, U"subtitle",				TEXT_MDT, NULL,	U"Map", 	0 },
		{ TRUE, NULL, U"subtitle-size",			INT_MDT, NULL,	NULL, 		16 },
		{ TRUE, NULL, U"subtitle-font",			FONT_MDT, NULL,	U"<font>", 	0 },
		{ TRUE, NULL, U"subtitle-colour",		COL_MDT, NULL,	U"000000", 	0 },
		{ TRUE, NULL, U"grid-size",				INT_MDT, NULL,	NULL, 		72 },
		{ TRUE, NULL, U"route-stiffness",		INT_MDT, NULL,	NULL, 		100 },
		{ TRUE, NULL, U"route-thickness",		INT_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, U"route-colour",			COL_MDT, NULL,	U"000000", 	0 },
		{ TRUE, NULL, U"room-offset",			OFF_MDT, NULL,	NULL, 		0 },
		{ TRUE, NULL, U"room-size",				INT_MDT, NULL,	NULL, 		36 },
		{ TRUE, NULL, U"room-colour",			COL_MDT, NULL,	U"DDDDDD", 	0 },
		{ TRUE, NULL, U"room-name",				TEXT_MDT, NULL,	U"", 		0 },
		{ TRUE, NULL, U"room-name-size",		INT_MDT, NULL,	NULL, 		12 },
		{ TRUE, NULL, U"room-name-font",		FONT_MDT, NULL,	U"<font>", 	0 },
		{ TRUE, NULL, U"room-name-colour",		COL_MDT, NULL,	U"000000", 	0 },
		{ TRUE, NULL, U"room-name-length",		INT_MDT, NULL,	NULL, 		5 },
		{ TRUE, NULL, U"room-name-offset",		OFF_MDT, NULL,	NULL, 		0 },
		{ TRUE, NULL, U"room-outline",			BOOL_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, U"room-outline-colour",	COL_MDT, NULL,	U"000000",	0 },
		{ TRUE, NULL, U"room-outline-thickness",INT_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, U"room-shape",			TEXT_MDT, NULL,	U"square",	0 }
	}
};

int ConfigureIndexMap::type_of_parameter(int index_of_parameter) {
	return initial_global_map_scope.values[index_of_parameter].parameter_data_type;
}

@ A little dynamic initialisation is needed here, because |I"whatever"| constants
are not in fact legal in constant context in C. So those |L"whatever"| values,
which are legal, are converted to to |I"whatever"| values here:

=
map_parameter_scope ConfigureIndexMap::global_settings(void) {
	for (int p=0; p<NO_MAP_PARAMETERS; p++) {
		initial_global_map_scope.values[p].name = Str::new();
		WRITE_TO(initial_global_map_scope.values[p].name, "%w",
			initial_global_map_scope.values[p].name_init);
		initial_global_map_scope.values[p].textual_value = Str::new();
		if (initial_global_map_scope.values[p].textual_value_init)
			WRITE_TO(initial_global_map_scope.values[p].textual_value, "%w",
				initial_global_map_scope.values[p].textual_value_init);
	}
	return initial_global_map_scope;
}

@ Non-global scopes are initialised here, though it's a much simpler process
because everything starts out blank.

=
void ConfigureIndexMap::prepare_map_parameter_scope(map_parameter_scope *scope,
	index_session *session) {
	scope->wider_scope = Indexing::get_global_map_scope(session);
	for (int s=0; s<NO_MAP_PARAMETERS; s++) {
		scope->values[s].specified = FALSE;
		scope->values[s].name = NULL;
		scope->values[s].textual_value = NULL;
		scope->values[s].numeric_value = 0;
	}
}

@ We convert a parameter's name to its index in the list; slowly, but that
doesn't matter.

=
int ConfigureIndexMap::get_map_variable_index(text_stream *name, index_session *session) {
	int s = ConfigureIndexMap::get_map_variable_index_forgivingly(name, session);
	if (s < 0) {
		LOG("Tried to look up <%S>\n", name);
		internal_error("looked up non-existent map variable");
	}
	return s;
}

int ConfigureIndexMap::get_map_variable_index_from_wchar(inchar32_t *wc_name) {
	for (int s=0; s<NO_MAP_PARAMETERS; s++)
		if ((initial_global_map_scope.values[s].name_init) &&
			(Wide::cmp(wc_name, initial_global_map_scope.values[s].name_init) == 0))
			return s;
	return -1;
}

int ConfigureIndexMap::get_map_variable_index_forgivingly(text_stream *name,
	index_session *session) {
	for (int s=0; s<NO_MAP_PARAMETERS; s++)
		if ((Indexing::get_global_map_scope(session)->values[s].name) &&
			(Str::cmp(name, Indexing::get_global_map_scope(session)->values[s].name) == 0))
			return s;
	return -1;
}

@ The following sets a parameter to a given value (the string value if that's
non-|NULL|, the number value otherwise), for a particular scope: this is
slightly wastefully specified either as a |map_parameter_scope| object,
or as a single room, or as a single region, or as a kind of room or region.
If all are null, then the global scope is used.

=
void ConfigureIndexMap::put_mp(text_stream *name, map_parameter_scope *scope,
	faux_instance *scope_I, text_stream *put_string, int put_integer, index_session *session) {
	if (scope == NULL) {
		if (scope_I == NULL) scope = Indexing::get_global_map_scope(session);
		else scope = FauxInstances::get_parameters(scope_I);
	}
	if (Str::cmp(name, I"room-colour") == 0) {
		if (scope == Indexing::get_global_map_scope(session))
			session->changed_global_room_colour = TRUE;
		if (scope_I) scope_I->fimd.colour = put_string;
	}
	if (Str::cmp(name, I"room-name-colour") == 0)
		if (scope_I) scope_I->fimd.text_colour = put_string;
	if (put_string) ConfigureIndexMap::put_text_mp(name, scope, put_string, session);
	else ConfigureIndexMap::put_int_mp(name, scope, put_integer, session);
}

@ Text parameters.

=
text_stream *ConfigureIndexMap::get_text_mp(text_stream *name, map_parameter_scope *scope,
	index_session *session) {
	int s = ConfigureIndexMap::get_map_variable_index(name, session);
	if (scope == NULL) scope = Indexing::get_global_map_scope(session);
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	if ((Str::ne(name, I"font")) && (Str::eq(scope->values[s].textual_value, I"<font>")))
		return ConfigureIndexMap::get_text_mp(I"font", NULL, session);
	return scope->values[s].textual_value;
}

void ConfigureIndexMap::put_text_mp(text_stream *name, map_parameter_scope *scope,
	text_stream *val, index_session *session) {
	int s = ConfigureIndexMap::get_map_variable_index(name, session);
	if (scope == NULL) scope = Indexing::get_global_map_scope(session);
	scope->values[s].specified = TRUE;
	scope->values[s].textual_value = Str::duplicate(val);
}

@ Integer parameters.

=
int ConfigureIndexMap::get_int_mp(text_stream *name, map_parameter_scope *scope,
	index_session *session) {
	int s = ConfigureIndexMap::get_map_variable_index(name, session);
	if (scope == NULL) scope = Indexing::get_global_map_scope(session);
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	return scope->values[s].numeric_value;
}

void ConfigureIndexMap::put_int_mp(text_stream *name, map_parameter_scope *scope, int val,
	index_session *session) {
	int s = ConfigureIndexMap::get_map_variable_index(name, session);
	if (scope == NULL) scope = Indexing::get_global_map_scope(session);
	scope->values[s].specified = TRUE;
	scope->values[s].numeric_value = val;
}

@h Rubric definitions.
A "rubric" is a freestanding piece of text written on the map. Typically
it will be a title, or "Here Be Monsters", or something like that.

=
typedef struct rubric_holder {
	struct text_stream *annotation;
	int point_size;
	struct text_stream *font;
	struct text_stream *colour;
	int at_offset;
	struct faux_instance *offset_from;
	CLASS_DEFINITION
} rubric_holder;

@h EPS definitions.
Each horizontal level of the EPS map needs its own storage, not least to
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
