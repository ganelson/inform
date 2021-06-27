[EPSMap::] EPS Map.

To render the spatial map of rooms as an EPS (Encapsulated PostScript) file.

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
	struct text_stream *name; /* name (used only in global scope) */
	wchar_t *name_init; /* name (used only in global scope) */
	int parameter_data_type; /* one of the above types (used only in global scope) */
	struct text_stream *textual_value; /* string value, if appropriate to this type; */
	wchar_t *textual_value_init; /* string value, if appropriate to this type; */
	int numeric_value; /* or numeric value, if appropriate to this type */
} plotting_parameter;

@ A set of variables associated with any map object is called a "scope".
As implied above, the global scope is special: it contains the default
settings passed down to all lower scopes.

@d NO_MAP_PARAMETERS 34

=
typedef struct map_parameter_scope {
	struct map_parameter_scope *wider_scope; /* that is, the scope above this */
	struct plotting_parameter values[NO_MAP_PARAMETERS];
} map_parameter_scope;

int global_map_scope_initialised = FALSE;
map_parameter_scope global_map_scope = {
	NULL,
	{
		{ TRUE, NULL, L"font",					FONT_MDT, NULL,	L"Helvetica", 0 },
		{ TRUE, NULL, L"minimum-map-width",		INT_MDT, NULL,	NULL, 		72*5 },
		{ TRUE, NULL, L"title",					TEXT_MDT, NULL,	L"Map", 	0 },
		{ TRUE, NULL, L"title-size",			INT_MDT, NULL,	NULL, 		24 },
		{ TRUE, NULL, L"title-font",			FONT_MDT, NULL,	L"<font>", 	0 },
		{ TRUE, NULL, L"title-colour",			COL_MDT, NULL,	L"000000", 	0 },
		{ TRUE, NULL, L"map-outline",			BOOL_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, L"border-size",			INT_MDT, NULL,	NULL, 		12 },
		{ TRUE, NULL, L"vertical-spacing",		INT_MDT, NULL,	NULL, 		6 },
		{ TRUE, NULL, L"monochrome",			BOOL_MDT, NULL,	NULL, 		0 },
		{ TRUE, NULL, L"annotation-size",		INT_MDT, NULL,	NULL, 		8 },
		{ TRUE, NULL, L"annotation-length",		INT_MDT, NULL,	NULL, 		8 },
		{ TRUE, NULL, L"annotation-font",		FONT_MDT, NULL,	L"<font>", 	0 },
		{ TRUE, NULL, L"subtitle",				TEXT_MDT, NULL,	L"Map", 	0 },
		{ TRUE, NULL, L"subtitle-size",			INT_MDT, NULL,	NULL, 		16 },
		{ TRUE, NULL, L"subtitle-font",			FONT_MDT, NULL,	L"<font>", 	0 },
		{ TRUE, NULL, L"subtitle-colour",		COL_MDT, NULL,	L"000000", 	0 },
		{ TRUE, NULL, L"grid-size",				INT_MDT, NULL,	NULL, 		72 },
		{ TRUE, NULL, L"route-stiffness",		INT_MDT, NULL,	NULL, 		100 },
		{ TRUE, NULL, L"route-thickness",		INT_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, L"route-colour",			COL_MDT, NULL,	L"000000", 	0 },
		{ TRUE, NULL, L"room-offset",			OFF_MDT, NULL,	NULL, 		0 },
		{ TRUE, NULL, L"room-size",				INT_MDT, NULL,	NULL, 		36 },
		{ TRUE, NULL, L"room-colour",			COL_MDT, NULL,	L"DDDDDD", 	0 },
		{ TRUE, NULL, L"room-name",				TEXT_MDT, NULL,	L"", 		0 },
		{ TRUE, NULL, L"room-name-size",		INT_MDT, NULL,	NULL, 		12 },
		{ TRUE, NULL, L"room-name-font",		FONT_MDT, NULL,	L"<font>", 	0 },
		{ TRUE, NULL, L"room-name-colour",		COL_MDT, NULL,	L"000000", 	0 },
		{ TRUE, NULL, L"room-name-length",		INT_MDT, NULL,	NULL, 		5 },
		{ TRUE, NULL, L"room-name-offset",		OFF_MDT, NULL,	NULL, 		0 },
		{ TRUE, NULL, L"room-outline",			BOOL_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, L"room-outline-colour",	COL_MDT, NULL,	L"000000",	0 },
		{ TRUE, NULL, L"room-outline-thickness",	INT_MDT, NULL,	NULL, 		1 },
		{ TRUE, NULL, L"room-shape",			TEXT_MDT, NULL,	L"square",	0 }
	}
};

map_parameter_scope *EPSMap::global(void) {
	if (global_map_scope_initialised == FALSE) {
		for (int p=0; p<NO_MAP_PARAMETERS; p++) {
			global_map_scope.values[p].name = Str::new();
			WRITE_TO(global_map_scope.values[p].name, "%w", global_map_scope.values[p].name_init);
			global_map_scope.values[p].textual_value = Str::new();
			if (global_map_scope.values[p].textual_value_init)
				WRITE_TO(global_map_scope.values[p].textual_value, "%w", global_map_scope.values[p].textual_value_init);
		}
		global_map_scope_initialised = TRUE;
	}
	return &global_map_scope;
}

int changed_global_room_colour = FALSE;

@ A "rubric" is a freestanding piece of text written on the map. Typically
it will be a title.

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
int EPSMap::get_map_variable_index(text_stream *name) {
	int s = EPSMap::get_map_variable_index_forgivingly(name);
	if (s < 0) {
		LOG("Tried to look up <%S>\n", name);
		internal_error("looked up non-existent map variable");
		s = 0;
	}
	return s;
}

int EPSMap::get_map_variable_index_from_wchar(wchar_t *wc_name) {
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%w", wc_name);
	int rv = EPSMap::get_map_variable_index_forgivingly(name);
	DISCARD_TEXT(name)
	return rv;
}

int EPSMap::get_map_variable_index_forgivingly(text_stream *name) {
	for (int s=0; s<NO_MAP_PARAMETERS; s++)
		if ((EPSMap::global()->values[s].name) &&
			(Str::cmp(name, EPSMap::global()->values[s].name) == 0))
			return s;
	return -1;
}

@h Map parameter scopes.
Here goes, then: an initialised set of parameters.

=
void EPSMap::prepare_map_parameter_scope(map_parameter_scope *scope) {
	int s;
	scope->wider_scope = EPSMap::global();
	for (s=0; s<NO_MAP_PARAMETERS; s++) {
		scope->values[s].specified = FALSE;
		scope->values[s].name = NULL;
		scope->values[s].textual_value = NULL;
		scope->values[s].numeric_value = 0;
	}
}

@ The following sets a parameter to a given value (the string value if that's
non-|NULL|, the number value otherwise), for a particular scope: this is
slightly wastefully specified either as a |map_parameter_scope| object,
or as a single room, or as a single region, or as a kind of room or region.
If all are null, then the global scope is used.

=
void EPSMap::put_mp(text_stream *name, map_parameter_scope *scope, faux_instance *scope_I,
	text_stream *put_string, int put_integer) {
	if (scope == NULL) {
		if (scope_I == NULL) scope = EPSMap::global();
		else scope = IXInstances::get_parameters(scope_I);
	}
	if (Str::cmp(name, I"room-colour") == 0) {
		if (scope == EPSMap::global()) changed_global_room_colour = TRUE;
		if (scope_I) scope_I->fimd.colour = put_string;
	}
	if (Str::cmp(name, I"room-name-colour") == 0)
		if (scope_I) scope_I->fimd.text_colour = put_string;
	if (put_string) EPSMap::put_text_mp(name, scope, put_string);
	else EPSMap::put_int_mp(name, scope, put_integer);
}

@ String parameters.

=
text_stream *EPSMap::get_text_mp(text_stream *name, map_parameter_scope *scope) {
	if (Str::eq(name, I"<font>")) return EPSMap::get_text_mp(I"font", NULL);
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = EPSMap::global();
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	return scope->values[s].textual_value;
}

void EPSMap::put_text_mp(text_stream *name, map_parameter_scope *scope, text_stream *val) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = EPSMap::global();
	scope->values[s].specified = TRUE;
	scope->values[s].textual_value = Str::duplicate(val);
}

@ Integer parameters.

=
int EPSMap::get_int_mp(text_stream *name, map_parameter_scope *scope) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = EPSMap::global();
	while (scope->values[s].specified == FALSE) {
		scope = scope->wider_scope;
		if (scope == NULL) internal_error("scope exhausted in looking up map parameter");
	}
	return scope->values[s].numeric_value;
}

void EPSMap::put_int_mp(text_stream *name, map_parameter_scope *scope, int val) {
	int s = EPSMap::get_map_variable_index(name);
	if (scope == NULL) scope = EPSMap::global();
	scope->values[s].specified = TRUE;
	scope->values[s].numeric_value = val;
}
