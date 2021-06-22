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
	struct faux_instance *offset_from;
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
void EPSMap::put_mp(wchar_t *name, map_parameter_scope *scope, faux_instance *scope_I,
	wchar_t *put_string, int put_integer) {
	if (scope == NULL) {
		if (scope_I == NULL) scope = &global_map_scope;
		else scope = IXInstances::get_parameters(scope_I);
	}
	if (Wide::cmp(name, L"room-colour") == 0) {
		if (scope == &global_map_scope) changed_global_room_colour = TRUE;
		if (scope_I) scope_I->fimd.colour = put_string;
	}
	if (Wide::cmp(name, L"room-name-colour") == 0)
		if (scope_I) scope_I->fimd.text_colour = put_string;
	if (put_string) EPSMap::put_string_mp(name, scope, put_string);
	else EPSMap::put_int_mp(name, scope, put_integer);
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
