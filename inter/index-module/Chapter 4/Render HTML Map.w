[HTMLMap::] Render HTML Map.

To render the spatial map of rooms as HTML.

@h Building the grids.
Three three-dimensional arrays called "grids" are used to store a rasterised
version of the map before we render this on screen.

The |room_grid| tells us which room can be found at $(x, y, z)$, while the
|icon_grid| is 25 times larger since it splits each room cell into a 5 by 5
subgrid of icons. Bitmaps stored in the 16 icon cells around the perimeter
of the 5 by 5 subgrid tell us which exits to mark (and since we map only 12
kinds of exit, this means that four of them are unused). The central 3 by 3
part of the subgrid is not used: nothing can be plotted there since that's
where the room icon goes, which is made not with an image tag but using the
HTML table routine below. We will often use the wasteful coordinate system
$(x, y, z, i_1, i_2)$ to mean the icon at $(i_1, i_2)$ (with $0\leq i_1,
i_2\leq 4$) associated with the room cell at $(x, y, z)$.

The |exit_grid| stores which direction number is the exit being marked at
this icon position, and has the same indexing as the icon grid.

@d ROOM_GRID_POS(P) Geometry::cuboid_index(P, Universe)
@d ICON_GRID_POS(P, i1, i2) (25*ROOM_GRID_POS(P) + 5*(i1) + (i2))

=
faux_instance **room_grid = NULL;
int *icon_grid = NULL, *exit_grid = NULL;

void HTMLMap::calculate_map_grid(void) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	@<Allocate the three mapping grids@>;
	@<Populate the room grid@>;
	@<Populate the icon and exit grids@>;
	@<Apply the remaining nuance bits to the icon grid@>;
}

@<Allocate the three mapping grids@> =
	int size_needed = Geometry::cuboid_volume(Universe), x;

	room_grid = (faux_instance **)
		(Memory::calloc(size_needed, sizeof(faux_instance *), MAP_INDEX_MREASON));
	for (x=0; x<size_needed; x++) room_grid[x] = NULL;

	icon_grid = (int *)
		(Memory::calloc(25*size_needed, sizeof(int), MAP_INDEX_MREASON));
	exit_grid = (int *)
		(Memory::calloc(25*size_needed, sizeof(int), MAP_INDEX_MREASON));
	for (x=0; x<25*size_needed; x++) {
		icon_grid[x] = 0;
		exit_grid[x] = -1;
	}

@<Populate the room grid@> =
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R)
		room_grid[ROOM_GRID_POS(Room_position(R))] = R;

@<Populate the icon and exit grids@> =
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R) {
		int exit;
		LOOP_OVER_STORY_DIRECTIONS(exit)
			if (SpatialMap::direction_is_mappable(exit)) {
				faux_instance *D = NULL; /* door which the exit passes through, if it does */
				faux_instance *T = SpatialMap::room_exit(R, exit, &D); /* target at the other end */
				if ((T) || (D))
					@<Fill in the grid-square for this exit of room R@>;
			}
	}

@ We next define constants needed for the icon bitmap. The information
we extract from the map exits is recorded in the low four bits as
follows:

@d EXIT_MAPBIT       0x00000001 /* An exit leads this way */
@d DOOR1_MAPBIT      0x00000002 /* Into a 1-sided door */
@d DOOR2_MAPBIT      0x00000004 /* Into a 2-sided door */
@d CONNECTIVE_BITMAP (EXIT_MAPBIT+DOOR1_MAPBIT+DOOR2_MAPBIT)

@ The higher bits are used for the nuances which improve the map when
several rooms are plotted together.

@d ADJACENT_MAPBIT   0x00000008 /* Into the room adjacent in space */
@d ALIGNED_MAPBIT    0x00000010 /* Into a room in correct direction */
@d FADING_MAPBIT     0x00000020 /* There's a broken exit on ... */
@d MEET_MAPBIT       0x00000040 /* This door should meet the adjacent one */
@d CROSSDOOR_MAPBIT  0x00000080 /* There's a door on the diagonal athwart */
@d CROSSDOT_MAPBIT   0x00000100 /* There's a plain exit on ... */

@ Five bits are used for the possible contents of a central square: it may
be occupied by an actual room, or it may have a pile of long straight-line
connections running through it, in any combination.

@d LONGEW_MAPBIT     0x00000200
@d LONGNS_MAPBIT     0x00000400
@d LONGSWNE_MAPBIT   0x00000800
@d LONGNWSE_MAPBIT   0x00001000
@d OCCUPIED_MAPBIT   0x10000000
@d LONGS_BITMAP      (LONGEW_MAPBIT+LONGNS_MAPBIT+LONGSWNE_MAPBIT+LONGNWSE_MAPBIT)

@ The following code calculates the low four bits of the icon bitmap
grid. Note that the main map grid must already be finished before this
stage can even begin.

@<Fill in the grid-square for this exit of room R@> =
	int i1, i2;
	SpatialMap::cell_position_for_direction(exit, &i1, &i2);
	int bitmap = 0;
	if (D) {
		if (T) bitmap |= DOOR2_MAPBIT;
		else bitmap |= DOOR1_MAPBIT;
	}
	if (T) {
		bitmap |= EXIT_MAPBIT;
		vector E = SpatialMap::direction_as_vector(exit);
		if ((Geometry::vec_eq(E, Zero_vector) == FALSE) &&
			(SpatialMap::direction_is_lateral(exit))) {
			@<Set the adjacent or aligned bit if the target lies in the correct direction@>;
			@<Set the fading bit if another room lies where the target ought to be@>;
		}
	}
	icon_grid[ICON_GRID_POS(Room_position(R), i1, i2)] = bitmap;
	exit_grid[ICON_GRID_POS(Room_position(R), i1, i2)] = exit;

@ Suppose we are looking east from the Ballroom to the Kitchens. If the Kitchens
will indeed be plotted at the position directly east of the Ballroom, we award
the "adjacent" bit; if they will be plotted due east, but further away than
a single square distant, then we get the "aligned" bit as a consolation prize.

@<Set the adjacent or aligned bit if the target lies in the correct direction@> =
	vector V = Geometry::vec_minus(Room_position(T), Room_position(R));
	int lambda;
	for (lambda=1; lambda<10; lambda++)
		if (Geometry::vec_eq(V, Geometry::vec_scale(lambda, E))) {
			if (lambda == 1) bitmap |= ADJACENT_MAPBIT;
			else bitmap |= ALIGNED_MAPBIT;
		}

@ If a different room altogether -- say, the Tack Room -- is being plotted one
square east of the Ballroom, even though the map connection leads to the
Kitchens, then we get the "fading" bit. (At one time connections like this
were going to be plotted in a sort of fading-away grey gradient, hence the
name, but in the end a more cartoonish break looked better.) This is not
exclusive with the aligned bit: we might have a situation where the map
be will be plotted left-to-right as B, TR, K, even though the connection
is east from B to K. If so, we get both the fading and aligned bits.

@<Set the fading bit if another room lies where the target ought to be@> =
	vector Farend = Geometry::vec_plus(Room_position(R), E);
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R)
		if ((R != T) && (Geometry::vec_eq(Room_position(R), Farend)))
			bitmap |= FADING_MAPBIT;

@<Apply the remaining nuance bits to the icon grid@> =
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R)
		icon_grid[ICON_GRID_POS(Room_position(R), 2, 2)] = OCCUPIED_MAPBIT;

	LOOP_OVER_FAUX_ROOMS(faux_set, R) {
		vector P = Room_position(R);
		HTMLMap::correct_pair(P, SW_vector, 0, 4, 4, 0);
		HTMLMap::correct_pair(P, W_vector,  0, 2, 4, 2);
		HTMLMap::correct_pair(P, NW_vector, 0, 0, 4, 4);
		HTMLMap::correct_pair(P, S_vector,  2, 4, 2, 0);
		HTMLMap::correct_pair(P, N_vector,  2, 0, 2, 4);
		HTMLMap::correct_pair(P, SE_vector, 4, 4, 0, 0);
		HTMLMap::correct_pair(P, E_vector,  4, 2, 0, 2);
		HTMLMap::correct_pair(P, NE_vector, 4, 0, 0, 4);
	}

@ A process called "pair correction" fills in the nuance bits for all
adjacent icons representing the same exit. Thus the east side icon of
one room may need to be married up with the west side icon of the
adjacent room, and so on. The four by four cornices diagonally in
between rooms require special care. To plot a northeast exit blocked by
a 2-sided door, for instance, requires all four icons to be plotted, but
we need to be careful in case the two icons not occupied by the exit are
needed for something else (if a northwest exit crossed over it, for
faux_instance).

Here $P$ is the position of the room we're looking at, and $D$ an offset
vector to one of its eight neighbouring cell positions on the map. If
$P+D$ lies outside the map altogether, we do nothing.

=
void HTMLMap::correct_pair(vector P, vector D, int from_i1, int from_i2, int to_i1, int to_i2) {
	vector Q = Geometry::vec_plus(P, D);

	if (Geometry::within_cuboid(P, Universe) == FALSE) return; /* should never happen */
	if (Geometry::within_cuboid(Q, Universe) == FALSE) return; /* neighbouring cell outside map */

	int from = icon_grid[ICON_GRID_POS(P, from_i1, from_i2)];
	int to = icon_grid[ICON_GRID_POS(Q, to_i1, to_i2)];

	if ((D.x == 0) || (D.y == 0)) @<Apply nuance bits for a rank or file direction@>
	else @<Apply nuance bits for a diagonal direction@>;

	if (from & ALIGNED_MAPBIT) @<Lay out a long roadway towards our destination cell@>;
}

@ Let's see how the "long" bits are added first, since that's easier. The
following looks disturbingly like an infinite loop: it lays out the roadway,
one cell at a time (adding the direction vector $D$ to our position $P$ each
turn) but stops when it hits an occupied cell -- one with a room plotted in
it. This must eventually happen because the exit is "aligned", which means
that it leads to a room whose position is some multiple of $D$ offset from
the original. So the loop always terminates.

@<Lay out a long roadway towards our destination cell@> =
	while (TRUE) {
		P = Geometry::vec_plus(P, D);
		if (icon_grid[ICON_GRID_POS(P, 2, 2)] & OCCUPIED_MAPBIT) break;
		if ((Geometry::vec_eq(D, E_vector)) || (Geometry::vec_eq(D, W_vector))) {
			icon_grid[ICON_GRID_POS(P, 0, 2)] = EXIT_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 2, 2)] |= LONGEW_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 4, 2)] = EXIT_MAPBIT;
		} else if ((Geometry::vec_eq(D, N_vector)) || (Geometry::vec_eq(D, S_vector))) {
			icon_grid[ICON_GRID_POS(P, 2, 0)] = EXIT_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 2, 2)] |= LONGNS_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 2, 4)] = EXIT_MAPBIT;
		} else if ((Geometry::vec_eq(D, SW_vector)) || (Geometry::vec_eq(D, NE_vector))) {
			icon_grid[ICON_GRID_POS(P, 0, 4)] = EXIT_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 2, 2)] |= LONGSWNE_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 4, 0)] = EXIT_MAPBIT;
		} else if ((Geometry::vec_eq(D, NW_vector)) || (Geometry::vec_eq(D, SE_vector))) {
			icon_grid[ICON_GRID_POS(P, 0, 0)] = EXIT_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 2, 2)] |= LONGNWSE_MAPBIT;
			icon_grid[ICON_GRID_POS(P, 4, 4)] = EXIT_MAPBIT;
		}
	}

@ That leaves just three bits left to set: meet, crossdoor and crossdot.
The meet bit is used to show that the door on a connection should be plotted
symmetrically between the two rooms it connects. This is easy for the
directions N, S, E and W:

@<Apply nuance bits for a rank or file direction@> =
	if ((from == to) && (from & ADJACENT_MAPBIT) && (from & DOOR2_MAPBIT)) {
		icon_grid[ICON_GRID_POS(P, from_i1, from_i2)] |= MEET_MAPBIT;
		icon_grid[ICON_GRID_POS(Q, to_i1, to_i2)] |= MEET_MAPBIT;
	}

@ But the case of a diagonal direction is much harder, because we may need
to add cornice-pieces. There are four possible diagonal directions (NE, NW,
SE and SW), and in each case the origin $P$ and the neighbour cell $P+D$
must live in opposite corners of a $2\times 2$ box of cells. We set $N$
to the bottom left cell of this box (which might be one of the two cells
we were originally looking at, or might be one of the other two).

@<Apply nuance bits for a diagonal direction@> =
	vector N = P;
	if (D.x < 0) N.x--;
	if (D.y < 0) N.y--;
	HTMLMap::correct_diagonal(N, TRUE);
	HTMLMap::correct_diagonal(N, FALSE);

@ So now the vector $BL$ represents the bottom left cell (i.e., the southwestern
corner of the box). We can obtain the other three cells of the $2\times 2$ box
by offsetting to N, E and NE. Two of these cells form the diagonal of the
map connection (are "used"), and two are off-diagonal (are "unused").

=
void HTMLMap::correct_diagonal(vector BL, int SW_to_NE) {
	int pos_00, /* corner icon position of lower cell used by the map connection */
		pos_01, /* corner icon position of lower cell not used by the map connection */
		pos_10, /* corner icon position of upper cell not used by the map connection */
		pos_11; /* corner icon position of upper cell used by the map connection */
	if (SW_to_NE) {
		pos_00 = ICON_GRID_POS(BL, 4, 0);
		pos_01 = ICON_GRID_POS(Geometry::vec_plus(BL, N_vector), 4, 4);
		pos_10 = ICON_GRID_POS(Geometry::vec_plus(BL, E_vector), 0, 0);
		pos_11 = ICON_GRID_POS(Geometry::vec_plus(BL, NE_vector), 0, 4);
	} else {
		pos_00 = ICON_GRID_POS(Geometry::vec_plus(BL, E_vector), 0, 0);
		pos_01 = ICON_GRID_POS(Geometry::vec_plus(BL, NE_vector), 0, 4);
		pos_10 = ICON_GRID_POS(BL, 4, 0);
		pos_11 = ICON_GRID_POS(Geometry::vec_plus(BL, N_vector), 4, 4);
	}
	@<Set the relevant bits to support a door, if there is one@>;
	@<Set the relevant bits to put mortice into the notches in a long diagonal@>;
}

@<Set the relevant bits to support a door, if there is one@> =
	int from = icon_grid[pos_00], to = icon_grid[pos_11];
	if (from == to) {
		if ((from & ADJACENT_MAPBIT) && (from & DOOR2_MAPBIT) && ((from & MEET_MAPBIT) == 0)) {
			if ((icon_grid[pos_01] == 0) && (icon_grid[pos_10] == 0))
				@<Make a large, athwart door from icons in all four cells@>
			else
				@<Make a small door from icons in just the two used cells@>;
		}
	}

@ If the off-diagonal cells happen to be free, we can use them to draw a nice
large door which is exactly halfway between the two rooms it connects, and
is perpendicular to the direction of the map connection.

@<Make a large, athwart door from icons in all four cells@> =
	icon_grid[pos_00] |= MEET_MAPBIT;
	icon_grid[pos_11] |= MEET_MAPBIT;
	icon_grid[pos_01] = CROSSDOOR_MAPBIT;
	icon_grid[pos_10] = CROSSDOOR_MAPBIT;

@ But if the off-diagonal cells aren't free, we have no room for that, and
must draw a much smaller door on one end or the other (not both) of the
connection.

@<Make a small door from icons in just the two used cells@> =
	icon_grid[pos_00] = DOOR2_MAPBIT; /* mark the door on the BL half of the exit */
	icon_grid[pos_11] = EXIT_MAPBIT; /* with no door on the other half of the exit */

@ If the off-diagonal cells happen to be free, we can put little single-pixel
icons into them to repair the notches which would otherwise show when the
map connection stripe (3 pixels wide) passes through a cell corner.

@<Set the relevant bits to put mortice into the notches in a long diagonal@> =
	int from = icon_grid[pos_00], to = icon_grid[pos_11];
	if ((from == to) && (from & CONNECTIVE_BITMAP) &&
		(icon_grid[pos_01] == 0) && (icon_grid[pos_10] == 0)) {
		icon_grid[pos_01] = CROSSDOT_MAPBIT;
		icon_grid[pos_10] = CROSSDOT_MAPBIT;
	}

@h Nested HTML Tables.
In 2010 it is considered something of a heresy to be still doing web page
layout using nested tables - supposedly, CSS is now strong enough for all
our needs - but the map is unusually well suited to a table approach since
it consists, in the end, of tessalations of rectangles.

Here's the code we will use to create each HTML table.

=
int map_tables_begun = 2;
void HTMLMap::begin_variable_width_table(OUTPUT_STREAM) {
	@<Include some indentation for a new map table@>;
	map_tables_begun++;
	HTML::begin_html_table(OUT, NULL, FALSE, 0, 0, 0, 0, 0);
}

void HTMLMap::begin_map_table(OUTPUT_STREAM, int width, int height) {
	@<Include some indentation for a new map table@>;
	map_tables_begun++;
	HTML::begin_html_table(OUT, NULL, FALSE, 0, 0, 0, height, width);
}

void HTMLMap::begin_variable_width_table_with_background(OUTPUT_STREAM, char *bg_image) {
	@<Include some indentation for a new map table@>;
	map_tables_begun++;
	HTML::begin_html_table_bg(OUT, NULL, FALSE, 0, 0, 0, 0, 0, bg_image);
}

@ Each table, however begun, concludes with:

=
void HTMLMap::end_map_table(OUTPUT_STREAM) {
	map_tables_begun--;
	@<Include some indentation for a new map table@>;
	HTML::end_html_table(OUT);
	WRITE("\n");
}

@<Include some indentation for a new map table@> =
	WRITE("\n");
	for (int i=0; i<map_tables_begun; i++) WRITE("  ");

@h Icon images.
The icons we use will all be PNGs, and all stored in the |map_icons|
directory. A "tool tip" is the text which appears over the mouse arrow
when it hovers for long enough over the icon.

=
void HTMLMap::plot_map_icon(OUTPUT_STREAM, text_stream *icon_name) {
	HTML_TAG_WITH("img", "border=0 src=inform:/map_icons/%S.png", icon_name);
}

void HTMLMap::plot_map_icon_with_tip(OUTPUT_STREAM, text_stream *icon_name, text_stream *tool_tip) {
	HTML_TAG_WITH("img", "border=0 src=inform:/map_icons/%S.png %S", icon_name, tool_tip);
}

@h The major map.
Note that we check to see if there is more than one room in the world: if
there isn't, we don't bother with a full map, but we still calculate as far
as the icon grid in order to be sure that the little 1 by 1 map for it (in
the details part of the World Index page) will be all right.

=
void HTMLMap::render_map_as_HTML(OUTPUT_STREAM, localisation_dictionary *LD) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	HTMLMap::calculate_map_grid();

	@<Choose a map colour for each region@>;
	@<Choose a map colour for each room, based on its region membership@>;

	if (FauxInstances::no_rooms() >= 2) {
		WRITE("\n\n");
		HTML::comment(OUT, I"WORLD WRITE MAP BEGINS");
		HTML_OPEN("p");
		WRITE("\n");
		@<Draw an HTML map for the whole Universe of rooms@>;
		HTML_CLOSE("p");
		HTML::comment(OUT, I"WORLD WRITE MAP ENDS");
	}
}

@ We give different colours to the first 20 regions defined, then repeat
the cycle for the next 20, and so on. (It's unlikely that there are that
many regions, but even if there are, regions 20 apart are unlikely to come
into contact, since they would be created in source text a long way distant
from each other.)

@d NO_REGION_COLOURS 20

@<Choose a map colour for each region@> =
	wchar_t *some_map_colours[NO_REGION_COLOURS] = {
		L"Pale Green", L"Light Blue", L"Plum",
		L"Light Sea Green", L"Light Slate Blue", L"Navajo White",
		L"Violet Red", L"Light Cyan", L"Light Coral", L"Light Pink",
		L"Medium Aquamarine", L"Medium Blue", L"Medium Orchid",
		L"Medium Purple", L"Medium Sea Green", L"Medium Slate Blue",
		L"Medium Spring Green", L"Medium Turquoise", L"Medium Violet Red",
		L"Light Golden Rod Yellow" };

	faux_instance *RG;
	int regc = 0;
	LOOP_OVER_FAUX_REGIONS(faux_set, RG)
		if (RG->fimd.colour == NULL) {
			RG->fimd.colour = Str::new();
			WRITE_TO(RG->fimd.colour, "%w", 
				HTML::translate_colour_name(
					some_map_colours[(regc++) % NO_REGION_COLOURS]));
		}

@<Choose a map colour for each room, based on its region membership@> =
	text_stream *default_room_col = Str::new();
	WRITE_TO(default_room_col, "%w", HTML::translate_colour_name(L"Light Grey"));
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R)
		if (R->fimd.colour == NULL) {
			faux_instance *reg = FauxInstances::region_of(R);
			if (reg)
				R->fimd.colour = Str::duplicate(reg->fimd.colour);
			else
				R->fimd.colour = Str::duplicate(default_room_col);
		}

@<Draw an HTML map for the whole Universe of rooms@> =
	HTMLMap::begin_variable_width_table(OUT);
	int z;
	for (z=Universe.corner1.z; z>=Universe.corner0.z; z--) {
		@<Draw the rubric row which labels this level of the map@>;
		@<Draw this level of the map@>;
	}
	@<Draw the baseline rubric row which concludes the map@>;
	HTMLMap::end_map_table(OUT);
	@<Add a paragraph describing how non-standard directions are mapped@>;

@<Draw the rubric row which labels this level of the map@> =
	TEMPORARY_TEXT(level_rubric)
	HTMLMap::devise_level_rubric(z, level_rubric, LD);
	HTML_OPEN("tr"); HTML_OPEN("td");
	int rounding = 0;
	if (z == Universe.corner1.z) rounding = ROUND_BOX_TOP;
	HTML::open_coloured_box(OUT, "e0e0e0", rounding);
	WRITE("<i>%S</i>", level_rubric);
	HTML::close_coloured_box(OUT, "e0e0e0", rounding);
	HTML_CLOSE("td"); HTML_CLOSE("tr");
	DISCARD_TEXT(level_rubric)

@<Draw this level of the map@> =
	int y_max = -1000000000, y_min = 1000000000; /* assuming there are fewer than 1 billion rooms */
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R)
		if (Room_position(R).z == z) {
			if (Room_position(R).y < y_min) y_min = Room_position(R).y;
			if (Room_position(R).y > y_max) y_max = Room_position(R).y;
		}

	if (y_max < y_min) continue;
	LOGIF(SPATIAL_MAP, "Level %d has rooms with %d <= y <= %d\n", z, y_min, y_max);

	HTML_OPEN("tr"); HTML_OPEN("td");
	HTMLMap::plot_map_level(OUT, Universe.corner0.x, Universe.corner1.x, y_min, y_max, z, 1, LD);
	HTML_CLOSE("td"); HTML_CLOSE("tr"); WRITE("\n");

@<Draw the baseline rubric row which concludes the map@> =
	HTML_OPEN("tr"); HTML_OPEN("td");
	HTML::open_coloured_box(OUT, "e0e0e0", ROUND_BOX_BOTTOM);
	HTML::close_coloured_box(OUT, "e0e0e0", ROUND_BOX_BOTTOM);
	HTML_CLOSE("td"); HTML_CLOSE("tr");

@<Add a paragraph describing how non-standard directions are mapped@> =
	faux_instance *D; int k = 0;
	LOOP_OVER_FAUX_DIRECTIONS(faux_set, D) {
		faux_instance *A = SpatialMap::mapped_as_if(D);
		if (A) {
			k++;
			if (k == 1) { HTML_OPEN("p"); } else WRITE("; ");
			Localisation::italic_2(OUT, LD, I"Index.Elements.Mp.MappingAs",
				FauxInstances::get_name(D), FauxInstances::get_name(A));
		}
	}
	if (k > 0) { HTML_CLOSE("p"); }

@h Level rubrics.

=
void HTMLMap::devise_level_rubric(int z, text_stream *level_rubric,
	localisation_dictionary *LD) {
	text_stream *key = I"Index.Elements.Mp.DefaultLevel";
	int par = 0;
	switch(Universe.corner1.z - Universe.corner0.z) {
		case 0:
			break;
		case 1: if (z == Universe.corner0.z) key = I"Index.Elements.Mp.LowerLevel";
			 if (z == Universe.corner1.z) key = I"Index.Elements.Mp.UpperLevel";
			break;
		default: {
			int z_offset = z - SpatialMap::benchmark_level();
			switch(z_offset) {
			case 0:  key = I"Index.Elements.Mp.StartingLevel"; break;
			case 1:  key = I"Index.Elements.Mp.FirstLevelUp"; break;
			case -1: key = I"Index.Elements.Mp.FirstLevelDown"; break;
			case 2:  key = I"Index.Elements.Mp.SecondLevelUp"; break;
			case -2: key = I"Index.Elements.Mp.SecondLevelDown"; break;
			case 3:  key = I"Index.Elements.Mp.ThirdLevelUp"; break;
			case -3: key = I"Index.Elements.Mp.ThirdLevelDown"; break;
			default:
				if (z_offset > 0) {
					par = z_offset; key = I"Index.Elements.Mp.LevelUp";
				}
				if (z_offset < 0) {
					par = -z_offset; key = I"Index.Elements.Mp.LevelDown";
				}
				break;
			}
			break;
		}
	}
	Localisation::write_1n(level_rubric, LD, key, par);
}

@h Single-room submaps.
The following provides the "details" portion of the World index: there
are two columns, the first containing a $1\times 1$ submap of just the
room in question, the second containing its indexing details.

This will only work if the main routine above has already been called, so
that the grids are calculated, the region colours decided, and so on.

=
void HTMLMap::render_single_room_as_HTML(OUTPUT_STREAM, faux_instance *R,
	localisation_dictionary *LD) {
	WRITE("\n\n");
	HTML_OPEN("p");
	IndexUtilities::anchor(OUT, R->anchor_text);
	HTML_TAG_WITH("a", "name=wo_%d", R->allocation_id);
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0);
	vector P = Room_position(R);
	HTMLMap::plot_map_level(OUT, P.x, P.x, P.y, P.y, P.z, 2, LD);
	HTML::next_html_column(OUT, 0);
	WRITE("&nbsp;");
	HTML::next_html_column(OUT, 0);
	MapElement::index(OUT, R, 1, FALSE, LD);
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}

@h Plotting a rectangle of the map.
Either way, then, we end up calling the following routine, which plots a
map of a rectangular X-Y area at a given fixed Z coordinate. The pass is 1
for the main mapping, 2 for single-room-only mapping lower down on the
index page.

=
void HTMLMap::plot_map_level(OUTPUT_STREAM, int x0, int x1, int y0, int y1, int z,
	int pass, localisation_dictionary *LD) {
	if (pass == 1)
		LOGIF(SPATIAL_MAP, "Plot: [%d, %d] x [%d, %d] x {%d}\n", x0, x1, y0, y1, z);

	int with_numbering = FALSE;
	if ((pass == 1) && (Universe.corner1.z != Universe.corner0.z)) with_numbering = TRUE;

	WRITE("\n\n");
	HTMLMap::begin_variable_width_table_with_background(OUT, "grid.png");
	int y, just_dislocated = FALSE;
	for (y=y1; y>=y0; y--) {
		int x, c = 0;
		for (x=x0; x<=x1; x++)
			if (room_grid[ROOM_GRID_POS(Geometry::vec(x, y, z))])
				c++;
		if (c == 0) {
			if (just_dislocated == FALSE) {
				just_dislocated = TRUE;
				@<Render a row of grid dislocation icons@>;
			}
			continue;
		}
		just_dislocated = FALSE;
		@<Render a row of map cells@>;
	}
	HTMLMap::end_map_table(OUT);
}

@ Cells in the map as drawn are divided into three stripes. The top stripe
contains the icons for the NW, N, NE exits, the middle stripe the icon for W,
then the central square, then the icon for E, and the bottom stripe the three
icons for SW, S, SE exits. We can therefore divide the pixel width of a cell
as $x_o + x_i + x_o$, where $x_i$ is the width of the central square.

It follows that any icon to be plotted in the four corner positions must
be square and have pixel dimensions $x_o\times x_o$; icons for the E and W
exit positions are $x_o\times x_i$; icons for the N and S positions are
$x_i\times x_o$; and the central square is, of course, $x_i\times x_i$,
though in fact we don't plot an image there.

The grid background must have pixel dimensions $(2x_o+x_i)\times (2x_o+x_i)$.

@d MAP_CELL_OUTER_SIZE 13 /* i.e., $x_o$ */
@d MAP_CELL_INNER_SIZE 27 /* i.e., $x_i$ */
@d MAP_CELL_SIZE (MAP_CELL_OUTER_SIZE + MAP_CELL_INNER_SIZE + MAP_CELL_OUTER_SIZE)

@ This is going to be a height-19 blank row of a table with a different
background image to the regular grid background -- it's an icon of the grid
with breaks in it. So we need to end the existing table, start a new one,
end it again, and start another table like the original.

The cells in a dislocation row have the usual width, but a foreshortened
height, and they're drawn with a single stripe.

@d MAP_DISLOCATION_HEIGHT 19 /* the reduced height */

@<Render a row of grid dislocation icons@> =
	HTMLMap::end_map_table(OUT);
	HTMLMap::begin_variable_width_table_with_background(OUT, "dislocation.png");
	HTML_OPEN("tr");
	int i, cells = x1-x0+1;
	if (with_numbering) cells += 2;
	for (i=0; i<cells; i++) {
		HTML_OPEN("td"); WRITE("\n");
		HTMLMap::begin_map_table(OUT, MAP_CELL_SIZE, MAP_DISLOCATION_HEIGHT);
		HTML_OPEN("tr"); WRITE("\n");
		HTML_OPEN("td"); WRITE("\n");
		HTML_CLOSE("td");
		HTML_CLOSE("tr"); WRITE("\n");
		HTMLMap::end_map_table(OUT);
		WRITE("\n");
		HTML_CLOSE("td");
	}
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTMLMap::begin_variable_width_table_with_background(OUT, "grid.png");

@<Render a row of map cells@> =
	@<Render the top stripe of the map row@>;
	@<Render the middle stripe of the map row@>;
	@<Render the bottom stripe of the map row@>;

@ The top stripe has height $x_o$.

@<Render the top stripe of the map row@> =
	HTML_OPEN("tr");
	if (with_numbering) @<Render a top or bottom stripe for a blank cell@>;
	for (x=x0; x<=x1; x++) @<Render a top stripe for a substantive cell@>;
	if (with_numbering) @<Render a top or bottom stripe for a blank cell@>
	HTML_CLOSE("tr");

@ The middle stripe has height $x_i$.

@<Render the middle stripe of the map row@> =
	HTML_OPEN("tr");
	if (with_numbering) @<Render a middle stripe for a numbering cell@>;
	for (x=x0; x<=x1; x++) @<Render a middle stripe for a substantive cell@>;
	if (with_numbering) @<Render a middle stripe for a numbering cell@>;
	HTML_CLOSE("tr");

@ The bottom stripe has height $x_o$.

@<Render the bottom stripe of the map row@> =
	HTML_OPEN("tr");
	if (with_numbering) @<Render a top or bottom stripe for a blank cell@>
	for (x=x0; x<=x1; x++) @<Render a bottom stripe for a substantive cell@>;
	if (with_numbering) @<Render a top or bottom stripe for a blank cell@>
	HTML_CLOSE("tr");

@h Substantive cells.

@<Render a top stripe for a substantive cell@> =
	vector P = Geometry::vec(x, y, z);
	HTML_OPEN("td");
	HTMLMap::begin_map_table(OUT, MAP_CELL_SIZE, MAP_CELL_OUTER_SIZE);
	HTML_OPEN("tr");
	HTML_OPEN("td");
	HTMLMap::plot_map_cell(OUT, pass, P, 0, 0, 2, LD);
	if (icon_grid[ICON_GRID_POS(P, 0, 0)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"s_dot"); else HTMLMap::plot_map_icon(OUT, I"ns_spacer");
	HTMLMap::plot_map_cell(OUT, pass, P, 1, 0, 8, LD);
	HTMLMap::plot_map_cell(OUT, pass, P, 2, 0, 0, LD);
	HTMLMap::plot_map_cell(OUT, pass, P, 3, 0, -1, LD);
	if (icon_grid[ICON_GRID_POS(P, 4, 0)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"s_dot"); else HTMLMap::plot_map_icon(OUT, I"ns_spacer");
	HTMLMap::plot_map_cell(OUT, pass, P, 4, 0, 1, LD);
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTML_CLOSE("td");

@<Render a middle stripe for a substantive cell@> =
	vector P = Geometry::vec(x, y, z);
	HTML_OPEN("td");
	HTMLMap::begin_map_table(OUT, MAP_CELL_SIZE, MAP_CELL_INNER_SIZE);
	HTML_OPEN("tr");
	HTML_OPEN("td");
	HTMLMap::begin_variable_width_table(OUT);
	HTML_OPEN("tr");
	HTML_OPEN("td");
	if (icon_grid[ICON_GRID_POS(P, 0, 0)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"e_dot"); else HTMLMap::plot_map_icon(OUT, I"ew_spacer");
	HTML_TAG("br");
	HTMLMap::plot_map_cell(OUT, pass, P, 0, 1, 11, LD);
	HTML_TAG("br");
	HTMLMap::plot_map_cell(OUT, pass, P, 0, 2, 7, LD);
	HTML_TAG("br");
	HTMLMap::plot_map_cell(OUT, pass, P, 0, 3, -1, LD);
	HTML_TAG("br");
	if (icon_grid[ICON_GRID_POS(P, 0, 4)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"e_dot"); else HTMLMap::plot_map_icon(OUT, I"ew_spacer");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTML_CLOSE("td");

	@<Render the central square for a substantive cell@>;

	HTML_OPEN("td");
	HTMLMap::begin_map_table(OUT, MAP_CELL_OUTER_SIZE, MAP_CELL_INNER_SIZE);
	HTML_OPEN("tr");
	HTML_OPEN("td");
	if (icon_grid[ICON_GRID_POS(P, 4, 0)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"w_dot"); else HTMLMap::plot_map_icon(OUT, I"ew_spacer");
	HTML_TAG("br");
	HTMLMap::plot_map_cell(OUT, pass, P, 4, 1, -1, LD);
	HTML_TAG("br");
	HTMLMap::plot_map_cell(OUT, pass, P, 4, 2, 6, LD);
	HTML_TAG("br");
	HTMLMap::plot_map_cell(OUT, pass, P, 4, 3, 10, LD);
	HTML_TAG("br");
	if (icon_grid[ICON_GRID_POS(P, 4, 4)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"w_dot"); else HTMLMap::plot_map_icon(OUT, I"ew_spacer");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTML_CLOSE("td");

@ The centre of a cell might be a room, or it might be an icon showing the
continuation of one or more long connections running through this cell.
There are 15 possibilities, and their icons are named as the following shows:

@<Render the central square for a substantive cell@> =
	HTML_OPEN("td");
	int bits = (icon_grid[ICON_GRID_POS(P, 2, 2)]) & LONGS_BITMAP;
	if (bits == 0)
		HTMLMap::index_room_square(OUT, room_grid[ROOM_GRID_POS(P)], pass);
	else {
		TEMPORARY_TEXT(icon_name)
		WRITE_TO(icon_name, "long");
		if (bits & LONGEW_MAPBIT) WRITE_TO(icon_name, "_ew");
		if (bits & LONGNS_MAPBIT) WRITE_TO(icon_name, "_ns");
		if (bits & LONGSWNE_MAPBIT) WRITE_TO(icon_name, "_swne");
		if (bits & LONGNWSE_MAPBIT) WRITE_TO(icon_name, "_nwse");
		HTMLMap::plot_map_icon(OUT, icon_name);
		DISCARD_TEXT(icon_name)
	}
	HTML_CLOSE("td");

@<Render a bottom stripe for a substantive cell@> =
	vector P = Geometry::vec(x, y, z);
	HTML_OPEN("td");
	HTMLMap::begin_map_table(OUT, MAP_CELL_SIZE, MAP_CELL_OUTER_SIZE);
	HTML_OPEN("tr");
	HTML_OPEN("td");
	HTMLMap::plot_map_cell(OUT, pass, P, 0, 4, 5, LD);
	if (icon_grid[ICON_GRID_POS(P, 0, 4)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"n_dot"); else HTMLMap::plot_map_icon(OUT, I"ns_spacer");
	HTMLMap::plot_map_cell(OUT, pass, P, 1, 4, -1, LD);
	HTMLMap::plot_map_cell(OUT, pass, P, 2, 4, 3, LD);
	HTMLMap::plot_map_cell(OUT, pass, P, 3, 4, 9, LD);
	if (icon_grid[ICON_GRID_POS(P, 4, 4)] & CONNECTIVE_BITMAP)
		HTMLMap::plot_map_icon(OUT, I"n_dot"); else HTMLMap::plot_map_icon(OUT, I"ns_spacer");
	HTMLMap::plot_map_cell(OUT, pass, P, 4, 4, 4, LD);
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTML_CLOSE("td");

@h Numbering cells.
If we're displaying a numbering in the map, that means there are two
columns -- the first and last -- which don't contain rooms or exits, but
are simply blank except for an italic row number.

@<Render a top or bottom stripe for a blank cell@> =
	HTML_OPEN("td");
	HTMLMap::begin_map_table(OUT, MAP_CELL_SIZE, MAP_CELL_OUTER_SIZE);
	HTML_OPEN("tr");
	HTML_OPEN("td");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTML_CLOSE("td");

@ Note that the row number is with respect to the entire Universe, not to
the current rectangle being rendered. The two aren't the same, because the
rectangle may be for a level in which we've omitted blank rows at the north
and south ends.

@<Render a middle stripe for a numbering cell@> =
	HTML_OPEN("td");
	HTMLMap::begin_map_table(OUT, MAP_CELL_SIZE, MAP_CELL_INNER_SIZE);
	HTML_OPEN("tr");
	HTML_OPEN("td");
	HTML::begin_colour(OUT, I"c0c0c0");
	#ifdef HTML_MAP_FONT_SIZE
	HTML_OPEN_WITH("span", "style=\"font-size:%dpx;\"", HTML_MAP_FONT_SIZE);
	#endif
	HTML_OPEN("center");
	HTML_OPEN("i");
	WRITE("%d", y-Universe.corner0.y+1);
	HTML_CLOSE("i");
	HTML_CLOSE("center");
	#ifdef HTML_MAP_FONT_SIZE
	HTML_CLOSE("span");
	#endif
	HTML::end_colour(OUT);
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTMLMap::end_map_table(OUT);
	HTML_CLOSE("td");

@h Plotting the eight exterior icons.
That leaves just the low-level routines to handle the nine individual pieces
of the cell. First, the eight cells around the outside:

=
void HTMLMap::plot_map_cell(OUTPUT_STREAM, int pass, vector P, int i1, int i2,
	int faux_exit, localisation_dictionary *LD) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	int bitmap = icon_grid[ICON_GRID_POS(P, i1, i2)];
	if (pass == 2) bitmap &= CONNECTIVE_BITMAP;
	if (bitmap == 0) @<This map cell is empty@>
	else @<There's something in this map cell@>;
}

@<This map cell is empty@> =
	if ((i1 == 1) || (i1 == 3)) HTMLMap::plot_map_icon(OUT, I"blank_ns");
	else {
		if ((i2 == 1) || (i2 == 3)) HTMLMap::plot_map_icon(OUT, I"blank_ew");
		else HTMLMap::plot_map_icon(OUT, I"blank_square");
	}

@<There's something in this map cell@> =
	int exit = exit_grid[ICON_GRID_POS(P, i1, i2)];

	TEMPORARY_TEXT(icon_name)
	TEMPORARY_TEXT(tool_tip)

	@<Compose the icon name for this exit@>;
	@<Compose a tool tip for this exit icon@>;

	if (Str::len(tool_tip) > 0) HTMLMap::plot_map_icon_with_tip(OUT, icon_name, tool_tip);
	else HTMLMap::plot_map_icon(OUT, icon_name);

	DISCARD_TEXT(icon_name)
	DISCARD_TEXT(tool_tip)

@<Compose the icon name for this exit@> =
	char *clue = SpatialMap::find_icon_label(exit);
	if (clue == NULL) clue = SpatialMap::find_icon_label(faux_exit);
	if (clue == NULL) clue = ""; /* should never happen */

	char *addendum = "";
	if (bitmap & DOOR2_MAPBIT) {
		addendum = "_door";
		if (bitmap & MEET_MAPBIT) addendum = "_door_meet";
	}
	if (bitmap & DOOR1_MAPBIT) addendum = "_door_blocked";
	if (bitmap & CROSSDOOR_MAPBIT) addendum = "_corner_door";
	if (bitmap & CROSSDOT_MAPBIT) addendum = "_dot";
	if ((addendum[0] == 0) && (bitmap & FADING_MAPBIT)) addendum = "_fading";

	WRITE_TO(icon_name, "%s_arrow%s", clue, addendum);

@<Compose a tool tip for this exit icon@> =
	faux_instance *D = NULL;
	faux_instance *I3 = SpatialMap::room_exit(room_grid[ROOM_GRID_POS(P)], exit, &D);
	if ((I3) || (D)) {
		WRITE_TO(tool_tip, "title=\"");
		TEMPORARY_TEXT(direction_name)
		TEMPORARY_TEXT(door_name)
		TEMPORARY_TEXT(destination_name)
		faux_instance *I;
		LOOP_OVER_FAUX_INSTANCES(faux_set, I)
			if (I->direction_index == exit) {
				FauxInstances::write_name(direction_name, I);
				break;
			}
		if (D) FauxInstances::write_name(door_name, D);
		if (I3) FauxInstances::write_name(destination_name, I3);

		if (D) {
			if (I3) Localisation::write_3(tool_tip, LD, I"Index.Elements.Mp.ExitThroughTooltip",
				direction_name, door_name, destination_name);
			else Localisation::write_2(tool_tip, LD, I"Index.Elements.Mp.ExitBlockedTooltip",
				direction_name, door_name);
		} else {
			if (I3) Localisation::write_2(tool_tip, LD, I"Index.Elements.Mp.ExitTooltip",
				direction_name, destination_name);
		}
		WRITE_TO(tool_tip, "\"");
		DISCARD_TEXT(direction_name)
		DISCARD_TEXT(door_name)
		DISCARD_TEXT(destination_name)
	}

@h Plotting the single central square.
The following routine renders the square icons for the rooms themselves,
which are bordered and coloured single-cell tables.

@d ROOM_BORDER_SIZE 1
@d B_ROOM_BORDER_SIZE 2
@d ROOM_BORDER_COLOUR "000000"
@d ROOM_TEXT_COLOUR "000000"

=
void HTMLMap::index_room_square(OUTPUT_STREAM, faux_instance *I, int pass) {
	if (I) {
		int b = ROOM_BORDER_SIZE;
		if ((I == FauxInstances::benchmark()) && (pass == 1)) b = B_ROOM_BORDER_SIZE;
		HTML_OPEN_WITH("table",
			"border=\"%d\" cellpadding=\"0\" cellspacing=\"0\" "
			"bordercolor=\"#%s\" width=\"%d\" height=\"%d\" title=\"%S\"",
			b, ROOM_BORDER_COLOUR, MAP_CELL_INNER_SIZE, MAP_CELL_INNER_SIZE,
			FauxInstances::get_name(I));
		HTML_OPEN("tr");
		HTML_OPEN_WITH("td", "valign=\"middle\" align=\"center\" bgcolor=\"#%S\"",
			I->fimd.colour);
		TEMPORARY_TEXT(col)
		if (I->fimd.text_colour)
			WRITE_TO(col, "%S", I->fimd.text_colour);
		else
			WRITE_TO(col, "%s", ROOM_TEXT_COLOUR);
		HTML::begin_colour(OUT, col);
		@<Write the text of the abbreviated name of the room@>;
		HTML::end_colour(OUT);
		HTML_CLOSE("td");
		HTML_CLOSE("tr");
		HTML_CLOSE("table");
		WRITE("\n");
		DISCARD_TEXT(col)
	}
}

@<Write the text of the abbreviated name of the room@> =
	if (pass == 1) {
		HTML_OPEN_WITH("a", "href=#wo_%d style=\"text-decoration: none\"",
			I->allocation_id);
		HTML::begin_colour(OUT, col);
	}
	if ((pass == 1) && (I == FauxInstances::benchmark())) HTML_OPEN("b");
	TEMPORARY_TEXT(abbrev)
	WRITE_TO(abbrev, "%S", I->abbrev);
	#ifdef HTML_MAP_FONT_SIZE
	HTML_OPEN_WITH("span", "style=\"font-size:%dpx;\"", HTML_MAP_FONT_SIZE);
	#endif
	LOOP_THROUGH_TEXT(pos, abbrev)
		HTML::put(OUT, Str::get(pos));
	#ifdef HTML_MAP_FONT_SIZE
	HTML_CLOSE("span");
	#endif
	if ((pass == 1) && (I == FauxInstances::benchmark())) HTML_CLOSE("b");
	if (pass == 1) { HTML::end_colour(OUT); HTML_CLOSE("a"); }
	DISCARD_TEXT(abbrev)

@h The colour chip.
The first of two extras, which aren't strictly speaking part of the HTML map.
This is the chip shown on the "details" box for a room in the World Index.

=
void HTMLMap::colour_chip(OUTPUT_STREAM, faux_instance *I, faux_instance *Reg, int at) {
	HTML_OPEN_WITH("table",
		"border=\"%d\" cellpadding=\"0\" cellspacing=\"0\" "
		"bordercolor=\"#%s\" height=\"%d\"",
		ROOM_BORDER_SIZE, ROOM_BORDER_COLOUR, MAP_CELL_INNER_SIZE);
	HTML_OPEN("tr");
	HTML_OPEN_WITH("td", "valign=\"middle\" align=\"center\" bgcolor=\"#%S\"",
		Reg->fimd.colour);
	WRITE("&nbsp;");
	FauxInstances::write_name(OUT, Reg); WRITE(" region");
	if (at > 0) IndexUtilities::link(OUT, at);
	WRITE("&nbsp;");
	HTML_CLOSE("td");
	HTML_CLOSE("tr");
	HTML_CLOSE("table");
	WRITE("\n");
}

@h The regions key.
The part of the World Index showing which rooms belong to which regions. Note
that nothing is shown if all of the rooms are outside of regions.

=
void HTMLMap::add_region_key(OUTPUT_STREAM) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	faux_instance *reg; int count = 0;
	LOOP_OVER_FAUX_REGIONS(faux_set, reg)
		count += HTMLMap::add_key_for(OUT, reg);
	if (count > 0) count += HTMLMap::add_key_for(OUT, NULL);
	if (count > 0) HTML_TAG("hr");
}

int HTMLMap::add_key_for(OUTPUT_STREAM, faux_instance *reg) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	int count = 0;
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R) {
		if (FauxInstances::region_of(R) == reg) {
			if (count++ == 0) {
				@<Start the region key table for this region@>;
			} else {
				WRITE(", ");
			}
			WRITE("%S", FauxInstances::get_name(R));
		}
	}
	if (count > 0) @<End the region key table for this region@>;
	return count;
}

@<Start the region key table for this region@> =
	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);
	HTML_OPEN("tr"); WRITE("\n");
	HTML_OPEN_WITH("td", "width=\"40\" valign=\"middle\" align=\"left\"");
	HTMLMap::index_room_square(OUT, R, 1);
	HTML_CLOSE("td"); WRITE("\n");
	HTML_OPEN_WITH("td", "valign=\"middle\" align=\"left\"");
	WRITE("<b>");
	if (reg) WRITE("%S", FauxInstances::get_name(reg));
	else WRITE("<i>Not in any region</i>");
	WRITE("</b>: ");

@<End the region key table for this region@> =
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
