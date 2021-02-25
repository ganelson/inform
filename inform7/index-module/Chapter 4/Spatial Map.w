[PL::SpatialMap::] Spatial Map.

To fit the map of the rooms in the game into a cubical grid,
preserving distances and angles where possible, and so to give each
room approximate coordinate locations.

@ We assign $(x, y, z)$ coordinates to each room, aiming to make the
descriptive map connections ("The Ballroom is east of the Old Kitchens")
as plausible as possible in coordinate terms. This is potentially a
research-level problem in graph theory or aesthetics. A problem like it was
recently set in a world programming competition: to turn spatial
coordinates into a simplified subway map. This is almost the reverse, but
has a certain amount in common with it.

We will partition the set of rooms into "components", which are disjoint
nonempty collections of rooms joined together by proximity. This has two
forms:

(i) Map connections in directions along lattice lines (EAST, UP, and so on
but not INSIDE or OUTSIDE);
(ii) Locks placed between rooms by sentences intended to give this algorithm
hints about layout.

As we will see, we will map rooms using a symmetric form of relationships:
if X relates to Y then Y relates to X. This will take some fixing, because
map connections in Inform needn't be symmetrical.

We must then solve two different problems. The first is to place rooms at
grid positions within each individual component. We assign each possible
arrangement a numerical measure of its geometric distortion, and then try
to minimise this, but of course any exhaustive search would be
prohibitively slow. This problem is quite likely NP-complete, and it looks
likely that we can embed notorious problems in complexity theory within it
(say, the bandwidth minimization problem). We do have the advantage of
experience about what IF maps look like, and of not having to deal well
with bizarre maps, but still, we shouldn't expect to achieve a perfect
choice. We must be very careful about running time; it's unacceptable for
the Inform indexer to take longer to run than Inform itself. The code below
is roughly quadratic in the number of rooms, which is a reasonable
compromise given how few works of IF have really enormous room counts.

The second problem is to place the components onto a global grid so that
they make sensible use of space on the index page, but don't get in each
other's way.

@ A "connected submap" is a map formed from some subset of the rooms
in the model world, together with any spatial relationships between them,
such that it's possible to go from any X to any Y in the submap using only
some sequence of these relationships.

Connected submaps will arise initially because we'll take every component
of the map and make it into a connected submap; but then more will exist
temporarily as we cut these up. Each room will, at any given time, belong
to exactly one submap.

At any given point in our calculations each room has a grid location which
is a triple of integers $(x, y, z)$. The position of the origin is
undefined, and not relevant, since only the location of one room relative
to another is important. We will cache the values of the corner points of
the smallest cuboid $(x_0, y_0, z_0)$ to $(x_1, y_1, z_1)$ which contains
all of the rooms in our submap. Similarly, we cache the penalty score for
the current arrangement of rooms relative to each other within the submap
as the "heat", a term to be explained later.

=
typedef struct connected_submap {
	struct instance *first_room_in_submap; /* double-headed linked list of rooms */
	struct instance *last_room_in_submap;
	struct cuboid bounds;
	int heat; /* current penalty score for bad placement of rooms */
	int positioned; /* already placed within the global map grid? */
	int *incidence_cache; /* how many of our rooms occupy each grid position? */
	int incidence_cache_size; /* how large that cache is */
	struct cuboid incidence_cache_bounds; /* bounds of the incidence cache array */
	int superpositions; /* number of pairs of rooms which share the same grid location */
	CLASS_DEFINITION
} connected_submap;

@ Just as each submap has a bounding cuboid, so does the whole assemblage:

=
cuboid Universe;

@ One special room is the "benchmark", from which the map is arranged.
This is usually the room in which the player begins.

=
instance *benchmark_room = NULL;

@ We are going to be iterating through the set of rooms often. Looping over
all rooms can afford to be fairly slow, but it's essential in order to keep
the running time down that we loop through submaps with overhead no worse
than the number of rooms in the submap; this is why we keep the linked list.

@d LOOP_OVER_ROOMS(R)
	LOOP_OVER_INSTANCES(R, K_object)
		if (Spatial::object_is_a_room(R))

@d LOOP_OVER_SUBMAP(R, sub)
	for (R = sub->first_room_in_submap; R; R = MAP_DATA(R)->next_room_in_submap)

@ These algorithms are trying to do something computationally expensive, so
it's useful to keep track of how much time they cost. The unit of currency
here is the "drogna"; 1 drogna is equivalent to a single map or lock lookup,
or a single exit heat calculation.

=
int drognas_spent = 0; /* in order to measure roughly how much work we're doing */
int cutpoint_spending = 0;
int division_spending = 0;
int slide_spending = 0;
int cooling_spending = 0;
int quenching_spending = 0;
int diffusion_spending = 0;
int radiation_spending = 0;
int explosion_spending = 0;

@h Grand strategy.
Here is the six-stage strategy. I estimate that the running time is as
follows, where $R$ is the number of rooms:

(1) Linear time, $O(R)$, so essentially instant.
(2) Linear time, $O(R)$, so essentially instant.
(3) About $O(R^2\log R)$, at worst, but generally better in practical cases.
(4) This could be as bad as $O(R^2)$, but only in bizarre circumstances.
(5) Linear time, $O(R)$, so essentially instant.
(6) In theory about $O(R^{4/3})$, but in practice $O(R)$.

We allow this routine to be called more than once only for the convenience of
the unit test below, which makes spatial positioning happen early in order
to get the results in time to write them in the story file.

=
int spatial_coordinates_established = FALSE;
int partitioned_into_components = FALSE;

void PL::SpatialMap::establish_spatial_coordinates(void) {
	if (spatial_coordinates_established) return;
	if (Log::aspect_switched_on(SPATIAL_MAP_DA)) PL::SpatialMap::log_precis_of_map();
	Universe = Geometry::empty_cuboid();
	@<(1) Create the spatial relationship arrays@>;
	@<(2) Partition the set of rooms into component submaps@>;
	partitioned_into_components = TRUE;
	@<(3) Position the rooms within each component@>;
	@<(4) Position the components in space@>;
	@<(5) Find the universal bounding cuboid@>;
	@<(6) Remove any blank lateral planes@>;
	@<(5) Find the universal bounding cuboid@>;
	spatial_coordinates_established = TRUE;
}

@h Mapping data attached to each room.
The $(x, y, z)$ position, and the submap, are straightforward enough;
during our calculations $(x, y, z)$ are relative coordinates to other rooms
in the same submap, but they are ultimately replaced with absolute
coordinates, once the submaps have themselves been placed in space.

The colour and mapping parameters are used for plotting purposes, so we
won't need them in this section.

=
void PL::SpatialMap::initialise_mapping_data(map_data *md) {
	md->world_index_colour = NULL;
	md->world_index_text_colour = NULL;
	md->position = Zero_vector;
	md->saved_gridpos = Zero_vector;
	md->submap = NULL;
	md->next_room_in_submap = NULL;
	int i;
	for (i=0; i<MAX_DIRECTIONS; i++) md->lock_exits[i] = NULL;
	PL::EPSMap::prepare_map_parameter_scope(&(md->local_map_parameters));
}

@ To make the code less cumbersome to read, all access to the position
will be using the following:

@d Room_position(R) MAP_DATA(R)->position

=
void PL::SpatialMap::set_room_position(instance *R, vector P) {
	vector O = Room_position(R);
	MAP_DATA(R)->position = P;
	if (MAP_DATA(R)->submap) PL::SpatialMap::move_room_within_submap(MAP_DATA(R)->submap, O, P);
}

void PL::SpatialMap::set_room_position_breaking_cache(instance *R, vector P) {
	MAP_DATA(R)->position = P;
}

@ Locking is a way to influence the algorithm in this section by forcing a
given exit to be locked in place, forbidding it to be distorted.

=
void PL::SpatialMap::lock_exit_in_place(instance *I, int exit, instance *I2) {
	PL::SpatialMap::lock_one_exit(I2, exit, I);
	PL::SpatialMap::lock_one_exit(I, PL::SpatialMap::opposite(exit), I2);
}

void PL::SpatialMap::lock_one_exit(instance *F, int exit, instance *T) {
	LOGIF(SPATIAL_MAP, "Mapping clue: put $O to the %s of $O\n",
		T, PL::SpatialMap::usual_Inform_direction_name(exit), F);
	MAP_DATA(F)->lock_exits[exit] = T;
}

@h Page directions.
These are any of the 12 standard IF directions (N, NE, NW, S, SE, SW, E, W,
U, D, IN, OUT), and are indexed with an number between 0 and 11 inclusive.
These are so called because they refer to directions on the page on which
the map will be plotted -- the page direction 6 really means rightwards, not
east, but it's still convenient to think of them that way.

For most Inform projects, page directions correspond to directions in the
story file. But that needn't be true; some story files create exotic directions
like "port" and "starboard". So the following array gives the correspondence
of story directions to page directions; if the value is 12 or more, the direction
won't be shown on the index at all. The initial setup is for the 12 standard
story directions to correspond exactly to the 12 page directions, then, and
for any subsequent story directions to be unshown:

=
int story_dir_to_page_dir[MAX_DIRECTIONS];

void PL::SpatialMap::initialise_page_directions(void) {
	int N = Map::number_of_directions();
	for (int i=0; i<N; i++)
		story_dir_to_page_dir[i] = i;
}

@ If we want to show one of the exotic directions, we can use a sentence like:

>> Index map with starboard mapped as east.

When we read this, we associate direction object 13, say (the starboard
direction) with page direction 6:

=
void PL::SpatialMap::map_direction_as_if(instance *I, instance *I2) {
	story_dir_to_page_dir[MAP_DATA(I)->direction_index] = MAP_DATA(I2)->direction_index;
}

instance *PL::SpatialMap::mapped_as_if(instance *I) {
	int i = MAP_DATA(I)->direction_index;
	if (story_dir_to_page_dir[i] == i) return NULL;
	instance *D;
	LOOP_OVER_INSTANCES(D, K_direction)
		if (MAP_DATA(D)->direction_index == story_dir_to_page_dir[i])
			return D;
	return NULL;
}

@ This is therefore how we know whether a given story direction will actually
be visible on the map we draw:

=
int PL::SpatialMap::direction_is_mappable(int story_direction) {
	if ((story_direction < 0) || (story_direction >= MAX_DIRECTIONS)) return FALSE;
	int page_direction = story_dir_to_page_dir[story_direction];
	if (page_direction >= 12) return FALSE;
	return TRUE;
}

@ Each page direction involves a given offset in lattice coordinates: for
example, direction 6 (E) involves an offset of $(1, 0, 0)$, because a move
in this map direction increases the $x$-coordinate by 1 and leaves $y$ and $z$
unchanged.

=
vector PL::SpatialMap::direction_as_vector(int story_direction) {
	if ((story_direction < 0) || (story_direction >= MAX_DIRECTIONS))
		return Zero_vector;
	int page_direction = story_dir_to_page_dir[story_direction];
	switch(page_direction) {
		case 0: return N_vector;
		case 1: return NE_vector;
		case 2: return NW_vector;
		case 3: return S_vector;
		case 4: return SE_vector;
		case 5: return SW_vector;
		case 6: return E_vector;
		case 7: return W_vector;
		case 8: return U_vector;
		case 9: return D_vector;
	}
	return Zero_vector;
}

@ Page directions all have opposites:

=
int PL::SpatialMap::opposite(int story_direction) {
	if ((story_direction < 0) || (story_direction >= MAX_DIRECTIONS)) return 0;
	int page_direction = story_dir_to_page_dir[story_direction];
	switch(page_direction) {
		case 0: return 3; /* N -- S */
		case 1: return 5; /* NE -- SW */
		case 2: return 4; /* NW -- SE */
		case 3: return 0; /* S -- N */
		case 4: return 2; /* SE -- NW */
		case 5: return 1; /* SW -- NE */
		case 6: return 7; /* E -- W */
		case 7: return 6; /* W -- E */
		case 8: return 9; /* UP -- DOWN */
		case 9: return 8; /* DOWN -- UP */
		case 10: return 11; /* IN -- OUT */
		case 11: return 10; /* OUT -- IN */
	}
	return 0;
}

@ Lateral directions can be rotated clockwise (seen from above), if |way|
is positive; or anticlockwise if it's negative.

=
int PL::SpatialMap::rotate_direction(int story_direction, int way) {
	if ((story_direction < 0) || (story_direction >= MAX_DIRECTIONS)) return 0;
	int page_direction = story_dir_to_page_dir[story_direction];
	int i, N = 1; if (way < 0) N = 7;
	for (i=1; i<=N; i++) {
		switch(page_direction) {
			case 0: page_direction = 1; break; /* N -- NE */
			case 1: page_direction = 6; break; /* NE -- E */
			case 2: page_direction = 0; break; /* NW -- N */
			case 3: page_direction = 5; break; /* S -- SW */
			case 4: page_direction = 3; break; /* SE -- S */
			case 5: page_direction = 7; break; /* SW -- W */
			case 6: page_direction = 4; break; /* E -- SE */
			case 7: page_direction = 2; break; /* W -- NW */
			default: page_direction = -1; break;
		}
	}
	return page_direction;
}

@ Lateral directions are the ones which (a) are mappable, and (b) involve
movement along the $x-y$ grid lines.

=
int PL::SpatialMap::direction_is_lateral(int story_direction) {
	return Geometry::vec_lateral(
			PL::SpatialMap::direction_as_vector(story_direction));
}

@ Along-lattice directions are those which (a) are mappable, and (b) involve
movement along grid lines. Clearly lateral directions are along-lattice, but
not necessarily vice versa.

=
int PL::SpatialMap::direction_is_along_lattice(int story_direction) {
	vector D = PL::SpatialMap::direction_as_vector(story_direction);
	if (Geometry::vec_eq(D, Zero_vector)) return FALSE;
	return TRUE;
}

@ For speed, we don't call these functions when looping through directions;
we use these hard-wired macros instead.

@d LOOP_OVER_DIRECTIONS(i)
	for (i=0; i<12; i++)

@d LOOP_OVER_STORY_DIRECTIONS(i)
	for (i=0; i<Map::number_of_directions(); i++)

@d LOOP_OVER_LATTICE_DIRECTIONS(i)
	for (i=0; i<10; i++)

@d LOOP_OVER_NONLATTICE_DIRECTIONS(i)
	for (i=10; i<12; i++)

@ Strictly speaking the following is more to do with rendering than
calculating, but it seems to belong here. In the HTML map, rooms have a
five-by-five cell grid, and exits are plotted at positions on the
boundary of that grid; for example, a line running in page direction 6
will be plotted with an icon at cell $(4, 2)$.

=
void PL::SpatialMap::cell_position_for_direction(int story_direction, int *mx, int *my) {
	*mx = 0; *my = 0;
	if ((story_direction < 0) || (story_direction >= MAX_DIRECTIONS)) return;
	int page_direction = story_dir_to_page_dir[story_direction];
	switch(page_direction) {
		case 0: *mx = 2; *my = 0; break;
		case 1: *mx = 4; *my = 0; break;
		case 2: *mx = 0; *my = 0; break;
		case 3: *mx = 2; *my = 4; break;
		case 4: *mx = 4; *my = 4; break;
		case 5: *mx = 0; *my = 4; break;
		case 6: *mx = 4; *my = 2; break;
		case 7: *mx = 0; *my = 2; break;
		case 8: *mx = 1; *my = 0; break;
		case 9: *mx = 3; *my = 4; break;
		case 10: *mx = 4; *my = 3; break;
		case 11: *mx = 0; *my = 1; break;
	}
}

@ And similarly:

=
char *PL::SpatialMap::find_icon_label(int story_direction) {
	if ((story_direction < 0) || (story_direction >= MAX_DIRECTIONS)) return NULL;
	int page_direction = story_dir_to_page_dir[story_direction];
	switch(page_direction) {
		case 0: return "n";
		case 1: return "ne";
		case 2: return "nw";
		case 3: return "s";
		case 4: return "se";
		case 5: return "sw";
		case 6: return "e";
		case 7: return "w";
		case 8: return "u";
		case 9: return "d";
		case 10: return "in";
		case 11: return "out";
	}
	return NULL;
}

char *PL::SpatialMap::usual_Inform_direction_name(int story_direction) {
	if ((story_direction < 0) || (story_direction >= MAX_DIRECTIONS)) return "<none>";
	int page_direction = story_dir_to_page_dir[story_direction];
	switch(page_direction) {
		case 0: return "north";
		case 1: return "northeast";
		case 2: return "northwest";
		case 3: return "south";
		case 4: return "southeast";
		case 5: return "southwest";
		case 6: return "east";
		case 7: return "west";
		case 8: return "up";
		case 9: return "down";
		case 10: return "inside";
		case 11: return "outside";
	}
	return "<none>";
}

@h Benchmark room.

=
void PL::SpatialMap::establish_benchmark_room(void) {
	if (benchmark_room == NULL) {
		benchmark_room = Player::get_start_room();
		if (benchmark_room == NULL) {
			instance *R;
			LOOP_OVER_ROOMS(R) { benchmark_room = R; return; }
			internal_error("no room exists in mapping");
		}
	}
}

@h Map reading.
The map is read in the first instance by the |PL::SpatialMap::room_exit|
routine below, which works out what room the exit leads to, perhaps via a
door, which we take a note of if asked to do so.

=
instance *PL::SpatialMap::room_exit(instance *origin, int dir_num, instance **via) {
	if (via) *via = NULL;
	if ((origin == NULL) || (Spatial::object_is_a_room(origin) == FALSE) ||
		(dir_num < 0) || (dir_num >= MAX_DIRECTIONS)) return NULL;
	instance *ultimate_destination = NULL;
	instance *immediate_destination = MAP_EXIT(origin, dir_num);
	if (immediate_destination) {
		if (Spatial::object_is_a_room(immediate_destination))
			ultimate_destination = immediate_destination;
		if (Map::instance_is_a_door(immediate_destination)) {
			if (via) *via = immediate_destination;
			instance *A = NULL, *B = NULL;
			Map::get_door_data(immediate_destination, &A, &B);
			if (A == origin) ultimate_destination = B;
			if (B == origin) ultimate_destination = A;
		}
	}
	return ultimate_destination;
}

instance *PL::SpatialMap::room_exit_as_indexed(instance *origin, int dir_num, instance **via) {
	int j;
	for (j=0; j<MAX_DIRECTIONS; j++) {
		if (story_dir_to_page_dir[j] == dir_num) {
			instance *I = PL::SpatialMap::room_exit(origin, j, via);
			if (I) return I;
		}
	}
	return NULL;
}

@ In practice, the map itself isn't the ideal source of data. It's slow to
keep checking all of that business with doors, and in any case the map is
asymmetrical. Instead, we use the following. The tricky point here is that
we want to record a sort of symmetric version of the map, which takes some
adjudication.

As can be seen, step (1) runs in $O(R)$ time, where $R$ is the number of rooms.

@<(1) Create the spatial relationship arrays@> =
	instance *R;
	LOOP_OVER_ROOMS(R) {
		int i;
		LOOP_OVER_DIRECTIONS(i)
			MAP_DATA(R)->spatial_relationship[i] = NULL;
	}
	LOOP_OVER_ROOMS(R) {
		int i;
		LOOP_OVER_LATTICE_DIRECTIONS(i) {
			instance *T = PL::SpatialMap::room_exit_as_indexed(R, i, NULL);
			if (T) @<Consider this Inform map connection for a spatial relationship@>;
		}
	}

@ We first find a spread of nearly opposite directions: for instance, if |i|
is northeast, then |back| is SW, |cw| is W, |cwcw| is NW, |ccw| is S, |ccwccw|
is SE. We also find the |backstep|, the room you get to if trying to go back
from the destination in the |back| direction; which in a nicely arranged
map will be the room you start from, but that can't be assumed.

The cases below don't exhaust the possibilities. We could be left with a
1-way connection blocked at the other end, in cases where no 2-way
connection exists between rooms |R| and |T|. If so, we shrug and ignore it;
this will be a situation where the connection doesn't help us. (It will still
be plotted on the index page; we just won't use it in our choice of how to
position the rooms.)

@<Consider this Inform map connection for a spatial relationship@> =
	int back = PL::SpatialMap::opposite(i);
	int cw = PL::SpatialMap::rotate_direction(back, 1); /* clockwise one place */
	int cwcw = PL::SpatialMap::rotate_direction(cw, 1); /* clockwise twice */
	int ccw = PL::SpatialMap::rotate_direction(back, -1); /* counterclockwise once */
	int ccwccw = PL::SpatialMap::rotate_direction(ccw, -1); /* counterclockwise twice */

	instance *backstep = PL::SpatialMap::room_exit_as_indexed(T, back, NULL);

	@<Average out a pair of 2-way connections which each bend@>;
	@<Turn a straightforward 2-way connection into a spatial relationship@>;
	@<Average out a pair of 1-way connections which suggest a deformed 2-way connection@>;
	@<Treat a 1-way connection as 2-way if there are no 2-way connections already@>;

@ What we're looking for here is a configuration like:

>> Alpha is east of Beta. Beta is south of Alpha.

This in fact sets up four connections: A is both S and W of B, and B is both
N and E of A. A reasonable interpretation is that A lies SW of B, and so we
form a single (symmetric) spatial relationship between them, in this direction.
We check first clockwise, then counterclockwise.

@<Average out a pair of 2-way connections which each bend@> =
	if ((backstep == R) &&
		(cwcw >= 0) &&
		(PL::SpatialMap::room_exit_as_indexed(T, cwcw, NULL) == R) &&
		(PL::SpatialMap::room_exit_as_indexed(T, cw, NULL) == NULL) &&
		(PL::SpatialMap::room_exit_as_indexed(R, PL::SpatialMap::opposite(cwcw), NULL) == T) &&
		(PL::SpatialMap::room_exit_as_indexed(T, PL::SpatialMap::opposite(cw), NULL) == NULL)) {
		PL::SpatialMap::form_spatial_relationship(R, PL::SpatialMap::opposite(cw), T);
		continue;
	}
	if ((backstep == R) &&
		(ccwccw >= 0) &&
		(PL::SpatialMap::room_exit_as_indexed(T, ccwccw, NULL) == R) &&
		(PL::SpatialMap::room_exit_as_indexed(T, ccw, NULL) == NULL) &&
		(PL::SpatialMap::room_exit_as_indexed(R, PL::SpatialMap::opposite(ccwccw), NULL) == T) &&
		(PL::SpatialMap::room_exit_as_indexed(T, PL::SpatialMap::opposite(ccw), NULL) == NULL)) {
		PL::SpatialMap::form_spatial_relationship(R, PL::SpatialMap::opposite(ccw), T);
		continue;
	}

@ The easiest case:

@<Turn a straightforward 2-way connection into a spatial relationship@> =
	if (backstep == R) {
		PL::SpatialMap::form_spatial_relationship(R, i, T);
		continue;
	}

@ Now perhaps A runs east to B, B runs south to A, but these are both 1-way
connections. We'll regard this as being a single passageway running on average
northeast from A to B:

@<Average out a pair of 1-way connections which suggest a deformed 2-way connection@> =
	/* a deformed 2-way connection made up of 1-way connections */
	if ((cwcw >= 0) &&
		(PL::SpatialMap::room_exit_as_indexed(T, cwcw, NULL) == R) &&
		(PL::SpatialMap::room_exit_as_indexed(T, cw, NULL) == NULL) &&
		(PL::SpatialMap::room_exit_as_indexed(R, PL::SpatialMap::opposite(cwcw), NULL) == T) &&
		(PL::SpatialMap::room_exit_as_indexed(T, PL::SpatialMap::opposite(cw), NULL) == NULL)) {
		PL::SpatialMap::form_spatial_relationship(R, PL::SpatialMap::opposite(cw), T);
		continue;
	}
	if ((ccwccw >= 0) &&
		(PL::SpatialMap::room_exit_as_indexed(T, ccwccw, NULL) == R) &&
		(PL::SpatialMap::room_exit_as_indexed(T, ccw, NULL) == NULL) &&
		(PL::SpatialMap::room_exit_as_indexed(R, PL::SpatialMap::opposite(ccwccw), NULL) == T) &&
		(PL::SpatialMap::room_exit_as_indexed(T, PL::SpatialMap::opposite(ccw), NULL) == NULL)) {
		PL::SpatialMap::form_spatial_relationship(R, PL::SpatialMap::opposite(ccw), T);
		continue;
	}

@ Most of the time, a 1-way connection is fine for mapping purposes; it
establishes as good a spatial relationship as a 2-way one. But we suppress
this if either (a) there are already 2-way connections between the rooms
in general, or (b) the opposite connection exists but is to a different
room (the case where |backstep| is not null here).

@<Treat a 1-way connection as 2-way if there are no 2-way connections already@> =
	int j, two_ways = 0;
	LOOP_OVER_LATTICE_DIRECTIONS(j)
		if ((PL::SpatialMap::room_exit_as_indexed(T, j, NULL) == R) &&
			(PL::SpatialMap::room_exit_as_indexed(R, PL::SpatialMap::opposite(j), NULL) == T))
			two_ways++;
	if ((two_ways == 0) && (backstep == NULL))
		PL::SpatialMap::form_spatial_relationship(R, i, T);

@ The following ensures that SR links are always symmetric, in opposed
pairs of directions:

=
void PL::SpatialMap::form_spatial_relationship(instance *R, int dir, instance *T) {
	MAP_DATA(R)->spatial_relationship[dir] = T;
	MAP_DATA(T)->spatial_relationship[PL::SpatialMap::opposite(dir)] = R;
}

@ The spatial relationships arrays are read only by the following. Note
that |PL::SpatialMap::read_smap| suppresses relationships between different submaps (at
least once the initial map components have been set up). This is done to
make it easy and quick to cut up a submap into two sub-submaps; effectively
severing any links between them. All we need do is move the rooms around
from one submap to another.

|PL::SpatialMap::read_smap_cross| has the ability to read relationships which cross submap
boundaries, and will be needed when we place submaps on the global grid.

=
instance *PL::SpatialMap::read_smap(instance *from, int dir) {
	if (from == NULL) internal_error("tried to read smap at null room");
	drognas_spent++;
	instance *to = MAP_DATA(from)->spatial_relationship[dir];
	if ((partitioned_into_components) && (to) &&
		(MAP_DATA(from)->submap != MAP_DATA(to)->submap))
			to = NULL;
	return to;
}

instance *PL::SpatialMap::read_smap_cross(instance *from, int dir) {
	if (from == NULL) internal_error("tried to read smap at null room");
	drognas_spent++;
	instance *to = PL::SpatialMap::room_exit(from, dir, NULL);
	return to;
}

@ While we're at it:

=
instance *PL::SpatialMap::read_slock(instance *from, int dir) {
	if (from == NULL) internal_error("tried to read slock at null room");
	drognas_spent++;
	return MAP_DATA(from)->lock_exits[dir];
}

@h Submap construction.
Here's an empty submap, with no rooms.

=
connected_submap *PL::SpatialMap::new_submap(void) {
	connected_submap *sub = CREATE(connected_submap);
	sub->bounds = Geometry::empty_cuboid();
	sub->first_room_in_submap = NULL;
	sub->last_room_in_submap = NULL;
	sub->incidence_cache = NULL;
	sub->incidence_cache_bounds = Geometry::empty_cuboid();
	sub->superpositions = 0;
	return sub;
}

@ Doctrinally, a room is always in just one submap, except at the very beginning
when we are forming the original components into submaps, when most of the
rooms aren't yet in any submap. Doctrinally, too, if a room is in a submap,
any room locked to it must always be in the same submap.

That makes the following routine dangerous to use, since it doesn't guarantee
either of those things. Use with care.

Because we keep a double-ended linked list to hold membership, adding a
room to a submap takes constant time with respect to the number of rooms $R$.

=
void PL::SpatialMap::add_room_to_submap(instance *R, connected_submap *sub) {
	if (sub->last_room_in_submap == NULL) {
		sub->last_room_in_submap = R;
		sub->first_room_in_submap = R;
	} else {
		MAP_DATA(sub->last_room_in_submap)->next_room_in_submap = R;
		sub->last_room_in_submap = R;
	}
	MAP_DATA(R)->submap = sub;
	MAP_DATA(R)->next_room_in_submap = NULL;
	PL::SpatialMap::add_room_to_cache(sub, Room_position(R), 1);
}

@ Here is how we read from the incidence cache. Its purpose is to provide
a constant running-time way to find out if a given position would collide
with that of an existing room in the submap -- something we could otherwise
find out only by an $O(R)$ search. If we had to maintain enormous submaps
of rooms, we'd probably want a balanced geographical tree structure, of the
sort used for collision detection in first-person shooters; but as it is,
we have plenty of memory and relatively few possible location coordinate
positions. So we simply keep a cubical array; though it may need to be
resized as the rooms in the submap move around, which complicates things.

Anyway, this returns the number of rooms at position P within the submap.

=
int PL::SpatialMap::occupied_in_submap(connected_submap *sub, vector P) {
	int i = Geometry::cuboid_index(P, sub->incidence_cache_bounds);
	if (i < 0) return 0;
	return sub->incidence_cache[i];
}

@ The cache will be invalidated by any movement of a room, so the following
routine must be notified of any such:

=
void PL::SpatialMap::move_room_within_submap(connected_submap *sub, vector O, vector P) {
	PL::SpatialMap::add_room_to_cache(sub, O, -1);
	PL::SpatialMap::add_room_to_cache(sub, P, 1);
}

@ Here goes, then: the following increments the cached population value at |P|
if |m| is 1, decrements it if $-1$.

=
void PL::SpatialMap::add_room_to_cache(connected_submap *sub, vector P, int m) {
	if (Geometry::within_cuboid(P, sub->incidence_cache_bounds) == FALSE)
		@<Location P lies outside the current incidence cache@>;

	int i = Geometry::cuboid_index(P, sub->incidence_cache_bounds);
	int t = sub->incidence_cache[i];
	if (t+m < 0) t = -m;
	sub->incidence_cache[i] = t+m;
	if (m == 1) sub->superpositions += 2*t;
	if (m == -1) sub->superpositions -= 2*(t-1);
}

@ We make a new incidence cache which is more than large enough to contain
both P and the existing one, and then copy the old one's contents into the
new one before deallocating the old.

This looks as if it has cubic running time, but isn't really that bad,
since the volume of the cuboid is probably about proportional to $R$ rather
than $R^3$ (assuming rooms are fairly evenly distributed through space).
Still, we ought to make sure it happens fairly seldom. We therefore expand
the cuboid by a margin giving us always at least 20 more cells than we need
horizontally, and 3 vertically. Since movements within submaps are modest
and local, this means very few submaps need to expand more than twice at
the most.

@<Location P lies outside the current incidence cache@> =
	cuboid old_cuboid = sub->incidence_cache_bounds;
	cuboid new_cuboid = old_cuboid;
	Geometry::thicken_cuboid(&new_cuboid, P, Geometry::vec(20, 20, 3));
	int extent = Geometry::cuboid_volume(new_cuboid);
	int *new_cache = Memory::calloc(extent, sizeof(int), MAP_INDEX_MREASON);
	int x, y, z;
	for (x = new_cuboid.corner0.x; x <= new_cuboid.corner1.x; x++)
		for (y = new_cuboid.corner0.y; y <= new_cuboid.corner1.y; y++)
			for (z = new_cuboid.corner0.z; z <= new_cuboid.corner1.z; z++) {
				int i = Geometry::cuboid_index(Geometry::vec(x,y,z), new_cuboid);
				new_cache[i] = 0;
			}
	int *old_cache = sub->incidence_cache;
	if (old_cache)
		for (x = old_cuboid.corner0.x; x <= old_cuboid.corner1.x; x++)
			for (y = old_cuboid.corner0.y; y <= old_cuboid.corner1.y; y++)
				for (z = old_cuboid.corner0.z; z <= old_cuboid.corner1.z; z++) {
					int i = Geometry::cuboid_index(Geometry::vec(x,y,z), old_cuboid);
					int t = old_cache[i];
					if (t > 0) {
						int j = Geometry::cuboid_index(Geometry::vec(x,y,z), new_cuboid);
						new_cache[j] = t;
					}
				}
	PL::SpatialMap::free_incidence_cache(sub);
	sub->incidence_cache = new_cache;
	sub->incidence_cache_size = extent*((int) sizeof(int));
	sub->incidence_cache_bounds = new_cuboid;

@ Here we throw away the cache, something which must otherwise only be done
when the submap has no rooms...

=
void PL::SpatialMap::free_incidence_cache(connected_submap *sub) {
	if (sub->incidence_cache == NULL) return;
	Memory::I7_free(sub->incidence_cache, MAP_INDEX_MREASON, sub->incidence_cache_size);
	sub->incidence_cache_bounds = Geometry::empty_cuboid();
	sub->incidence_cache = NULL;
}

@ ...such as now:

=
void PL::SpatialMap::empty_submap(connected_submap *sub) {
	sub->first_room_in_submap = NULL;
	sub->last_room_in_submap = NULL;
	PL::SpatialMap::free_incidence_cache(sub);
	sub->superpositions = 0;
}

@ And finally:

=
void PL::SpatialMap::destroy_submap(connected_submap *sub) {
	PL::SpatialMap::free_incidence_cache(sub);
	DESTROY(sub, connected_submap);
}

@ Suppose we want to move all the rooms in a submap at once, and all by the
same vector |D|. Then we can simply move the cache boundaries, too, and not
have to change the contents of the cache at all.

=
void PL::SpatialMap::move_component(connected_submap *sub, vector D) {
	instance *R;
	LOOP_OVER_SUBMAP(R, sub)
		PL::SpatialMap::set_room_position_breaking_cache(R, Geometry::vec_plus(Room_position(R), D));
	Geometry::cuboid_translate(&(sub->bounds), D);
	Geometry::cuboid_translate(&(sub->incidence_cache_bounds), D);
}

@ The following routines will be used in order to divide an existing submap
into two new ones, which we'll call Zone 1 and Zone 2, and then to merge
them back again.

We start with each room in |sub| having a value of |zone| set to either
|Z1_number| or |Z2_number|, the former meaning it is destined for Zone 1,
the latter for Zone 2. It's assumed here that if two rooms are locked together
then they have the same value of |zone|. With that done, we empty |sub|,
since its rooms have all moved out.

=
void PL::SpatialMap::create_submaps_from_zones(connected_submap *sub,
	int Z1_number, connected_submap *Zone1, int Z2_number, connected_submap *Zone2) {
	instance *R;
	LOOP_OVER_ROOMS(R) {
		if (MAP_DATA(R)->zone == Z1_number)
			PL::SpatialMap::add_room_to_submap(R, Zone1);
		else if (MAP_DATA(R)->zone == Z2_number)
			PL::SpatialMap::add_room_to_submap(R, Zone2);
		MAP_DATA(R)->zone = 0;
	}
	PL::SpatialMap::empty_submap(sub);
}

@ Convert membership of Zone 1 or 2 back into value of the zone number: the
reverse process exactly.

=
void PL::SpatialMap::create_zones_from_submaps(connected_submap *sub,
	int Z1_number, connected_submap *Zone1, int Z2_number, connected_submap *Zone2) {
	instance *R;
	LOOP_OVER_ROOMS(R) {
		if (MAP_DATA(R)->submap == Zone1) {
			PL::SpatialMap::add_room_to_submap(R, sub);
			MAP_DATA(R)->zone = Z1_number;
		}
		if (MAP_DATA(R)->submap == Zone2) {
			PL::SpatialMap::add_room_to_submap(R, sub);
			MAP_DATA(R)->zone = Z2_number;
		}
	}
}

@h Partitioning to component submaps.
We can now go back to our strategy. The next task is to partition the map into
components, that is, equivalence classes under the closure of the relation
$R\sim S$ if either $R$ is locked to $S$ or if there is a spatial relationship
between $R$ and $S$.

We ensure that the first-created component is the one containing the
benchmark room.

@<(2) Partition the set of rooms into component submaps@> =
	PL::SpatialMap::create_map_component_around(benchmark_room);
	instance *R;
	LOOP_OVER_ROOMS(R)
		if (MAP_DATA(R)->submap == NULL)
			PL::SpatialMap::create_map_component_around(R);

@ The following grows a component outwards from |at|, so that it also includes
all rooms locked to |at| or with a SR to it. If |at| is currently not in a
component, we start a new submap to hold it.

Note that |PL::SpatialMap::create_map_component_around| has constant running time, i.e., it
doesn't depend on $R$, the number of rooms. It is called exactly once for
each room, so phase (2) has running time $O(R)$.

=
void PL::SpatialMap::create_map_component_around(instance *at) {
	if (MAP_DATA(at)->submap == NULL) PL::SpatialMap::add_room_to_submap(at, PL::SpatialMap::new_submap());

	int i;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *locked_to = PL::SpatialMap::read_slock(at, i);
		if ((locked_to) && (MAP_DATA(locked_to)->submap != MAP_DATA(at)->submap)) {
			PL::SpatialMap::add_room_to_submap(locked_to, MAP_DATA(at)->submap);
			PL::SpatialMap::create_map_component_around(locked_to);
		}
		instance *dest = PL::SpatialMap::read_smap(at, i);
		if ((dest) && (MAP_DATA(dest)->submap != MAP_DATA(at)->submap)) {
			PL::SpatialMap::add_room_to_submap(dest, MAP_DATA(at)->submap);
			PL::SpatialMap::create_map_component_around(dest);
		}
	}
}

@h Movements of single rooms.
Positions are just 3-vectors, so:

=
void PL::SpatialMap::translate_room(instance *R, vector D) {
	PL::SpatialMap::set_room_position(R, Geometry::vec_plus(Room_position(R), D));
}

void PL::SpatialMap::move_room_to(instance *R, vector P) {
	PL::SpatialMap::set_room_position(R, P);
	PL::SpatialMap::move_anything_locked_to(R);
}

@h Synchronising movements of locked rooms.
The next preliminary we need is the implementation of locking. As we've seen,
the source text can instruct us to lock one room so that it lies perfectly
placed with respect to another (in the sense that if there were an exit
between them in that direction then it would have heat 0).

The following is for use after room R has been moved to a new grid position;
it moves anything locked to R (and anything locked to that, and so on) to
corresponding positions.

=
void PL::SpatialMap::move_anything_locked_to(instance *R) {
	connected_submap *sub = MAP_DATA(R)->submap;
	instance *R2;
	LOOP_OVER_SUBMAP(R2, sub)
		MAP_DATA(R2)->shifted = FALSE;
	PL::SpatialMap::move_anything_locked_to_r(R);
}

void PL::SpatialMap::move_anything_locked_to_r(instance *R) {
	if (MAP_DATA(R)->shifted) return;
	MAP_DATA(R)->shifted = TRUE;
	int i;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *F = PL::SpatialMap::read_slock(R, i);
		if (F) {
			vector D = PL::SpatialMap::direction_as_vector(i);
			PL::SpatialMap::set_room_position(F, Geometry::vec_plus(Room_position(R), D));
			PL::SpatialMap::move_anything_locked_to_r(F);
		}
	}
}

@ That allows us to define the initial state of placements in a submap.
All rooms begin at (0,0,0), except that locking may offset a few of them
slightly. This runs in $O(R)$ time.

=
void PL::SpatialMap::lock_positions_in_submap(connected_submap *sub) {
	instance *R;
	LOOP_OVER_SUBMAP(R, sub)
		MAP_DATA(R)->shifted = FALSE;
	LOOP_OVER_SUBMAP(R, sub)
		PL::SpatialMap::move_anything_locked_to_r(R);
}

@h Positioning within components.
This is much more difficult. It's going to be a matter of minimising the
badness of the configuration, but to talk about it it's convenient to have
a better word than "badness". So the "heat" is a penalty score
calculated at each map connection which keeps track of the badness of local
geometric distortion; thus, lowering the temperature improves the geometry.
We want to reduce the total amount of heat, ideally to absolute zero, but
we also to want to avoid hot-spots.

The worst case for running time here is when the entire map is a single component;
the loop over submaps doesn't therefore add to the running time.

@<(3) Position the rooms within each component@> =
	connected_submap *sub;
	int total_accuracy = 0;
	LOOP_OVER(sub, connected_submap) {
		LOGIF(SPATIAL_MAP, "Laying out component %d\n", sub->allocation_id);
		PL::SpatialMap::lock_positions_in_submap(sub); /* $O(R)$ running time */
		PL::SpatialMap::establish_natural_lengths(sub); /* $O(R)$ running time */
		PL::SpatialMap::position_submap(sub);
		total_accuracy += sub->heat;
		LOGIF(SPATIAL_MAP, "Component %d has final heat %d\n", sub->allocation_id, sub->heat);
	}
	LOGIF(SPATIAL_MAP, "\nAll components laid out: total heat %d\n\n", total_accuracy);

	LOGIF(SPATIAL_MAP, "Cost: cutpoint choosing %d drognas\n", cutpoint_spending);
	LOGIF(SPATIAL_MAP, "Cost: dividing %d drognas\n", division_spending);
	LOGIF(SPATIAL_MAP, "Cost: sliding %d drognas\n", slide_spending);
	LOGIF(SPATIAL_MAP, "Cost: cooling %d drognas\n", cooling_spending);
	LOGIF(SPATIAL_MAP, "Cost: quenching %d drognas\n", quenching_spending);
	LOGIF(SPATIAL_MAP, "Cost: diffusion %d drognas\n", diffusion_spending);
	LOGIF(SPATIAL_MAP, "Cost: radiation %d drognas\n", radiation_spending);
	LOGIF(SPATIAL_MAP, "Cost: explosion %d drognas\n\n", explosion_spending);

@ Every spatial relationship has a "length", which is a positive integer.
This is our preferred amount of stretch when laying out the rooms; a
length of 1 means one grid increment, and that's our preference if we
can have it. Initially, all SRs have length 1.

=
void PL::SpatialMap::establish_natural_lengths(connected_submap *sub) {
	instance *R;
	LOOP_OVER_SUBMAP(R, sub) {
		int i;
		LOOP_OVER_LATTICE_DIRECTIONS(i) {
			if (PL::SpatialMap::read_smap(R, i))
				MAP_DATA(R)->exit_lengths[i] = 1;
			else
				MAP_DATA(R)->exit_lengths[i] = -1;
		}
	}
}

@h Heat.
Before we can get any further with (3), we need to be able to measure heat. For
a submap, it's the sum of its room heats, plus additional heat (and a
lot of it) for each pair of rooms occupying the same grid location. We also
refresh the cached value of the smallest squarely oriented cuboid which
contains the component.

The mapmaker behaves slowly if the collision heat penalty is low enough
that large amounts of heat soaked up from ordinary exits can ever exceed it.
On the other hand, for very large maps with horrible tangles the total number
of collisions can be enormous, and quite high heats are observed; I've seen
temperatures over 165,000,000, so temperatures of 1,000,000,000 are not at
all out of the question. So we will be careful, just on the safe side,
not to overflow a single |int|; we'll cap temperatures except to add a tiny
extra heat so that there is still a slight incentive to remove collisions
even in submaps at this unthinkably hot level.

The FHM magazine website informs me that the current (2010) maximal value of
temperature is |CHERYL_COLE|, but I think I'll call it |FUSION_POINT|.

@d OVERLYING_HEAT       20
@d COLLISION_HEAT    50000
@d FUSION_POINT 1000000000

=
int PL::SpatialMap::heat_sum(int h1, int h2) {
	int h = h1+h2;
	if (h > FUSION_POINT) return FUSION_POINT;
	return h;
}

@ Finding the heat of a submap runs in $O(S)$ time, where $S$ is the number
of rooms in the submap; this is the point of having the incidence cache,
without which it would be $O(S^2)$. Even so, we will try to make $S$ a lot
smaller than $R$.)

=
int PL::SpatialMap::find_submap_heat(connected_submap *sub) {
	int heat = 0;
	sub->bounds = Geometry::empty_cuboid();
	instance *R;
	LOOP_OVER_SUBMAP(R, sub) {
		heat = PL::SpatialMap::heat_sum(heat, PL::SpatialMap::find_room_heat(R));
		Geometry::adjust_cuboid(&(sub->bounds), Room_position(R));
	}

	int collisions = sub->superpositions;
	while (collisions >= 1000) {
		heat = PL::SpatialMap::heat_sum(heat, 1000*COLLISION_HEAT);
		collisions -= 1000;
	}
	heat = PL::SpatialMap::heat_sum(heat, collisions*COLLISION_HEAT);
	if (heat == FUSION_POINT) heat = FUSION_POINT + sub->superpositions;
	sub->heat = heat;
	return heat;
}

@ The total heat for a room is in turn the sum of its exit heats. This runs
in constant time.

=
int PL::SpatialMap::find_room_heat(instance *R) {
	int i, h = 0;
	LOOP_OVER_LATTICE_DIRECTIONS(i) h += PL::SpatialMap::find_exit_heat(R, i);
	return h;
}

@ So now we come to it: measuring the heat of an exit, which is a matter of
how much geometric distortion it has in the current layout. This is based
primarily on the angular divergence in direction between the known exit
direction and the grid direction, and only secondarily on distance
anomalies, because when the user typed "the Field is east of the River"
no particular distance was implied. As with Harry Beck's London Underground
map (1931), we may be constrained to use only about eight possible angles but
nevertheless care more about angle than length.

Note that an exit in the lattice (i.e., not IN or OUT) which joins two
different rooms can only have heat 0 if the destination room lies exactly
at the optimal grid offset from the origin room. (In the sense that you'd
expect the room north from $(0,0,0)$ to be at $(0,1,0)$, and so on.) A
component therefore has a total heat of 0 if and only if it has been
aligned perfectly on a grid such that all exits are optimal.

This too runs in constant time.

@d ANGULAR_MULTIPLIER 50

=
int PL::SpatialMap::find_exit_heat(instance *from, int exit) {
	drognas_spent++;

	instance *to = PL::SpatialMap::read_smap(from, exit);
	if (to == NULL) return 0; /* if there's no exit this way, there's no heat */

	if (from == to) return 0; /* an exit from a room to itself doesn't show on the map */

	if (PL::SpatialMap::direction_is_along_lattice(exit) == FALSE) return 0; /* IN, OUT generate no heat */

	vector D = Geometry::vec_minus(Room_position(to), Room_position(from));

	if (Geometry::vec_eq(D, Zero_vector)) return COLLISION_HEAT; /* the two rooms have collided! */

	vector E = PL::SpatialMap::direction_as_vector(exit);
	int distance_distortion = Geometry::vec_length_squared(Geometry::vec_minus(E, D));
	if (distance_distortion == 0) return 0; /* perfect placement */
	int angular_distortion = (int) (ANGULAR_MULTIPLIER*Geometry::vec_angular_separation(E, D));
	int overlying_penalty = 0;
	if ((angular_distortion == 0) && (Geometry::vec_eq(E, Zero_vector) == FALSE)) {
		vector P = Room_position(from);
		int n = 1;
		P = Geometry::vec_plus(P, E);
		while ((n++ < 20) && (Geometry::vec_eq(P, Room_position(to)) == FALSE)) {
			if (PL::SpatialMap::occupied_in_submap(MAP_DATA(from)->submap, P) > 0)
				overlying_penalty += OVERLYING_HEAT;
			P = Geometry::vec_plus(P, E);
		}
	}
	return angular_distortion + distance_distortion + overlying_penalty;
}

@ The following simply tests whether a link is correctly aligned, in that
the destination room lies along a multiple of the exit vector from the
origin. In effect, it tests whether |angular_distortion| is zero.

=
int PL::SpatialMap::exit_aligned(instance *from, int exit) {
	drognas_spent++;

	instance *to = PL::SpatialMap::read_smap(from, exit);
	if (to == NULL) return TRUE; /* at any rate, not misaligned */
	if (from == to) return TRUE; /* ditto */
	if (PL::SpatialMap::direction_is_along_lattice(exit) == FALSE) return TRUE; /* IN, OUT are always aligned */

	vector D = Geometry::vec_minus(Room_position(to), Room_position(from));
	if (Geometry::vec_eq(D, Zero_vector)) return TRUE; /* bad, but not for alignment reasons */

	vector E = PL::SpatialMap::direction_as_vector(exit);
	int angular_distortion = (int) (ANGULAR_MULTIPLIER*Geometry::vec_angular_separation(E, D));
	if (angular_distortion == 0) return TRUE;
	return FALSE;
}

@h Subdividing our submap.
Any remotely good algorithm for this task will have a dangerous running time
if let loose on the entire map, and in any case, the entirety may have such
a complex layout that it defeats our tactics. So we need a divide-and-rule
method; one which cuts the map into two pieces, positions each piece, and
then glues them back together again.

We will eventually use five tactics: cooling, quenching, diffusion,
radiation and explosion. Cooling is quick and useful, so we'll try that
first even before looking for subdivisions.

=
int unique_Z_number = 1;

void PL::SpatialMap::position_submap(connected_submap *sub) {
	int initial_heat = PL::SpatialMap::find_submap_heat(sub), initial_spending = drognas_spent;
	LOGIF(SPATIAL_MAP, "\nPOSITIONING submap %d: initial heat %d",
		sub->allocation_id, sub->heat);
	if (sub->heat == 0) LOGIF(SPATIAL_MAP, ": nothing to do");
	if (Log::aspect_switched_on(SPATIAL_MAP_DA)) {
		instance *R; int n = 0;
		LOOP_OVER_SUBMAP(R, sub) {
			if ((n++) % 8 == 0) LOG("\n    ");
			LOG(" $O", R);
		}
		LOG("\n");
	}
	if (sub->heat > 0) {
		PL::SpatialMap::cool_submap(sub);
		PL::SpatialMap::find_submap_heat(sub);
		if (sub->heat > 0) {
			@<Attempt to divide the current submap in two@>;
			PL::SpatialMap::find_submap_heat(sub);
		}
		LOGIF(SPATIAL_MAP, "\nPOSITIONING submap %d done: cooled by %d to %d "
			"at cost of %d drognas\n\n",
			sub->allocation_id, initial_heat - sub->heat, sub->heat,
			drognas_spent - initial_spending);
	}
}

@ We will look for a way to divide the rooms up into two subsets, allocating
each subset a unique zone number. (We must remember that all of this code is
running recursively.)

There are three cases: sometimes the |PL::SpatialMap::work_out_optimal_cutpoint| function
recommends cutting a single spatial relationship, from |div_F1| to |div_T1|,
and sometimes it recommends cutting a pair. Then again, sometimes it finds
no good cutpoint.

@<Attempt to divide the current submap in two@> =
	int Z1_number = unique_Z_number++, Z2_number = unique_Z_number++;
	instance *div_F1 = NULL, *div_T1 = NULL; int div_dir1 = -1;
	instance *div_F2 = NULL, *div_T2 = NULL; int div_dir2 = -1;
	int initial_spending = drognas_spent;
	int found = PL::SpatialMap::work_out_optimal_cutpoint(sub, &div_F1, &div_T1, &div_dir1,
		&div_F2, &div_T2, &div_dir2);
	cutpoint_spending += drognas_spent - initial_spending;
	if (found) {
		@<Set the zone numbers throughout the two soon-to-be zones@>;
		@<Divide the submap into zones, recurse to position those, then merge back@>;
		@<Slide the two former zones together along the F1-to-T1 line, minimising heat@>;
		if (PL::SpatialMap::find_submap_heat(sub) > 0) PL::SpatialMap::radiate_submap(sub);
	} else
		@<Position this indivisible component@>;

@ When we can't divide, we use our remaining three tactics, stopping if the
submap should reach absolute zero:

@<Position this indivisible component@> =
	if (PL::SpatialMap::find_submap_heat(sub) > 0) {
		PL::SpatialMap::quench_submap(sub, NULL, NULL);
		if (PL::SpatialMap::find_submap_heat(sub) > 0) {
			PL::SpatialMap::diffuse_submap(sub);
			if (PL::SpatialMap::find_submap_heat(sub) > 0) {
				PL::SpatialMap::quench_submap(sub, NULL, NULL);
				if (PL::SpatialMap::find_submap_heat(sub) > 0) {
					PL::SpatialMap::radiate_submap(sub);
					if (PL::SpatialMap::find_submap_heat(sub) >= COLLISION_HEAT)
						PL::SpatialMap::explode_submap(sub);
				}
			}
		}
	}

@ Supposing we can divide, though, we need to set zone numbers throughout
the submap, and the procedure is different depending on whether we're
dividing at one relationship F1-to-T1 or at two, F1-to-T1 and F2-to-T2.

@<Set the zone numbers throughout the two soon-to-be zones@> =
	int Z1_count = 0, Z2_count = 0;
	if (div_F2) {
		int predivision_spending = drognas_spent;
		PL::SpatialMap::divide_into_zones_twocut(div_F1, div_T1, div_F2, div_T2, Z1_number, Z2_number);
		instance *R;
		LOOP_OVER_SUBMAP(R, sub) {
			if (MAP_DATA(R)->zone == Z1_number) Z1_count++;
			if (MAP_DATA(R)->zone == Z2_number) Z2_count++;
		}
		LOGIF(SPATIAL_MAP, "Making a double cut: $O %s to $O and $O %s to $O at cost %d\n",
			div_F1, PL::SpatialMap::usual_Inform_direction_name(div_dir1), div_T1,
			div_F2, PL::SpatialMap::usual_Inform_direction_name(div_dir2), div_T2,
			drognas_spent - predivision_spending);
		division_spending += drognas_spent - predivision_spending;
	} else {
		int predivision_spending = drognas_spent;
		PL::SpatialMap::divide_into_zones_onecut(sub, div_F1, div_T1,
			&Z1_count, &Z2_count, Z1_number, Z2_number);
		LOGIF(SPATIAL_MAP, "Making a single cut: $O %s to $O at cost %d\n",
			div_F1, PL::SpatialMap::usual_Inform_direction_name(div_dir1), div_T1,
			drognas_spent - predivision_spending);
		division_spending += drognas_spent - predivision_spending;
	}
	LOGIF(SPATIAL_MAP, "This produces two zones of sizes %d and %d\n",
		Z1_count, Z2_count);

@<Divide the submap into zones, recurse to position those, then merge back@> =
	connected_submap *Zone1 = PL::SpatialMap::new_submap();
	connected_submap *Zone2 = PL::SpatialMap::new_submap();
	PL::SpatialMap::create_submaps_from_zones(sub, Z1_number, Zone1, Z2_number, Zone2);
	LOGIF(SPATIAL_MAP, "Zone 1 becomes submap %d; zone 2 becomes submap %d\n",
		Zone1->allocation_id, Zone2->allocation_id);
	LOG_INDENT;
	PL::SpatialMap::position_submap(Zone1);
	PL::SpatialMap::position_submap(Zone2);
	LOG_OUTDENT;
	PL::SpatialMap::create_zones_from_submaps(sub, Z1_number, Zone1, Z2_number, Zone2);
	LOGIF(SPATIAL_MAP, "Destroying submaps %d and %d\n",
		Zone1->allocation_id, Zone2->allocation_id);
	PL::SpatialMap::destroy_submap(Zone1);
	PL::SpatialMap::destroy_submap(Zone2);

@ The zone-1 rooms are now correctly placed with respect to each other, and
vice versa, but we might have a horrendous breakage where the two sets of
rooms meet. We need to rejoin them, and we do this by stretching the
F1-to-T1 line segment to that length which minimises the total heat of
the submap. For a single cut, this is clearly the smallest length such
that there's no collision between old zone-1 and old zone-2 rooms.

The worst case is a configuration like so:

>> X is west of Y. X1 is northeast of X. X2 is northeast of X. Y1 is northwest of Y. Y2 is northwest of Y1.

We've cut between X and Y. To give clearance so that X2 and Y2 do not collide,
the new length X to Y needs to be 5.

However, it's computationally too expensive to check every possible length
as high as that: it would run in $O(S^2)$ time, and we must remember that
this is the divide-and-rule code running on even the largest submaps, so
that this is effectively an $O(R^2)$ algorithm. On a 300-room example source
text (the entire London Underground map, zones 1 to 7) this results in
sliding taking up about 80 percent of our time, which is unacceptable.

We therefore cap the length once we have reduced below the collision penalty.

@d CAP_ON_SLIDE_LENGTHS 10

@<Slide the two former zones together along the F1-to-T1 line, minimising heat@> =
	int preslide_spending = drognas_spent;
	vector Axis = PL::SpatialMap::direction_as_vector(div_dir1);

	int worst_case_length = 0;
	instance *R;
	LOOP_OVER_SUBMAP(R, sub) worst_case_length++;
	worst_case_length--;

	int L, coolest_L = 1, coolest_temperature = -1;
	for (L = 1; L <= worst_case_length; L++) {
		PL::SpatialMap::save_component_positions(sub);
		@<Displace zone 2 relative to zone 1@>;
		int h = PL::SpatialMap::find_submap_heat(sub);
		if ((h < coolest_temperature) || (coolest_temperature == -1)) {
			coolest_temperature = h;
			coolest_L = L;
		}
		PL::SpatialMap::restore_component_positions(sub);
		if ((coolest_temperature >= 0) && (coolest_temperature < COLLISION_HEAT) &&
			(L == CAP_ON_SLIDE_LENGTHS))
			break;
	}
	LOGIF(SPATIAL_MAP, "Optimal axis length for cut-exit is %d (heat %d), found at cost %d.\n",
		coolest_L, coolest_temperature, drognas_spent - preslide_spending);
	slide_spending += drognas_spent - preslide_spending;
	L = coolest_L;
	@<Displace zone 2 relative to zone 1@>;

@ Here we slide rooms which came from Zone 2 so that they retain their
positions with respect to each other, and therefore to T1, and so that T1
is placed correctly aligned along the axis from F1 with length L.

Because there can never be locks across zone boundaries, this process
can't break a lock between two rooms.

@<Displace zone 2 relative to zone 1@> =
	MAP_DATA(div_F1)->exit_lengths[div_dir1] = L;
	vector D = Geometry::vec_plus(
		Geometry::vec_scale(L, Axis),
		Geometry::vec_minus(Room_position(div_F1), Room_position(div_T1)));
	instance *Z2;
	LOOP_OVER_SUBMAP(Z2, sub)
		if (MAP_DATA(Z2)->zone == Z2_number)
			PL::SpatialMap::translate_room(Z2, D);

@h Finding how to divide.
That completes the logic for how we divide and conquer the submaps, except,
of course, that some of the critical steps weren't spelled out. We do that
now. First, the code to find good cutpoint(s): map connection(s) which, if
removed, would divide the submap efficiently. We prefer single cuts if
possible, but can live with double cuts; we want as evenly spread a
division as possible. (The "spread" is the difference in room count
of the larger zone compared to the smaller zone; we want to minimise this.)

Here is the basic idea. We will recursively spread a generation count out
into the submap, with the first room (|first| below) belonging to generation 1.
We'll use the |zone| field to store this, since it's an integer attached to
each room which isn't yet in use. |PL::SpatialMap::assign_generation_count| is recursively
called so that it visits each room exactly once, and increases the generation
on each call. Thus a line of rooms from |first| would have generations 1, 2,
3, ... When |PL::SpatialMap::assign_generation_count| finds a connection from its current
position to a room with a lower generation, we say that there's a "contact".

What makes the routine so effective is that it returns a great deal of data
about the high-spots of the history after it was called. The mechanism for
this, though, is that the caller has to set up a pile of arrays, and then
pass pointers to |PL::SpatialMap::assign_generation_count|; on its exit, the arrays are
then populated with answers.

This calculation runs in $O(S)$ time, where $S$ is the number of rooms in
the submap. It's guaranteed to find the optimal single cut, if one exists;
it's not guaranteed to find the optimal double cut -- I suspect this is
not possible in $O(S)$ running time, though possibly in $O(S\log S)$ -- but
in any case we have heuristic reasons why we don't always want the optimal
double cut. What can be said is that we at least try to find good spreads,
usually succeed in practice, and are guaranteed to find at least one double
cut if any exists.

The guarantees are void in a small number of cases where locks have been
applied: for instance, if the entire submap is locked together, nothing can
ever be cut. Should that happen, the user will find that the map-maker may
run slowly; it's his own fault.

@d EXPLORATION_RECORDS 3 /* how much we keep track of */
@d BEST_ONECUT_ER 0 /* what's the best-known single link to cut? */
@d BEST_PARALLEL_TWOCUT_ER 1 /* what's the best-known pair of links equal in direction? */
@d BEST_TWOCUT_ER 2 /* and in general? */

@d CLIPBOARD_SIZE 3 /* a term to be explained below */

=
int PL::SpatialMap::work_out_optimal_cutpoint(connected_submap *sub,
	instance **from, instance **to, int *way,
	instance **from2, instance **to2, int *way2) {
	instance *first = NULL; int size = 0;

	@<Find the size of and first room in the submap, and give all rooms generation 0@>;
	MAP_DATA(first)->zone = 1;

	int best_spread[EXPLORATION_RECORDS];
	instance *best_from1[EXPLORATION_RECORDS], *best_to1[EXPLORATION_RECORDS];
	int best_dir1[EXPLORATION_RECORDS];
	instance *best_from2[EXPLORATION_RECORDS], *best_to2[EXPLORATION_RECORDS];
	int best_dir2[EXPLORATION_RECORDS];

	int outer_contact_generation[CLIPBOARD_SIZE], outer_contact_dir[CLIPBOARD_SIZE];
	instance *outer_contact_from[CLIPBOARD_SIZE], *outer_contact_to[CLIPBOARD_SIZE];
	@<Initialise all this cutpoint search workspace@>;

	PL::SpatialMap::assign_generation_count(first, NULL, size,
		best_spread,
		best_from1, best_to1, best_dir1,
		best_from2, best_to2, best_dir2,
		outer_contact_generation, outer_contact_from, outer_contact_to, outer_contact_dir);

	@<Look at the results and return connections to cut, if any look good enough@>;
	return FALSE;
}

@<Find the size of and first room in the submap, and give all rooms generation 0@> =
	instance *R;
	LOOP_OVER_SUBMAP(R, sub) {
		MAP_DATA(R)->zone = 0; /* i.e., not yet given a generation */
		size++;
		if (first == NULL) first = R;
	}
	if (size == 0) return FALSE;

@ See below.

@<Initialise all this cutpoint search workspace@> =
	int i;
	for (i = 0; i < CLIPBOARD_SIZE; i++) {
		outer_contact_generation[i] = -1;
		outer_contact_from[i] = NULL; outer_contact_to[i] = NULL; outer_contact_dir[i] = -1;
	}
	for (i = 0; i < EXPLORATION_RECORDS; i++) {
		best_spread[i] = size+1; /* an impossibly high value */
		best_from1[i] = NULL; best_to1[i] = NULL; best_dir1[i] = -1;
		best_from2[i] = NULL; best_to2[i] = NULL; best_dir2[i] = -1;
	}

@ Suppose the larger and smaller zones have sizes $X$ and $Y$. Then clearly
$X+Y = T$, where $T$ is the total number of rooms (called |size| below). The
spread is by definition $S = X-Y$. Therefore the size of the smaller zone
is given by $Y = (T-S)/2$. We use this to ensure that the division is worth
the time it takes.

@d MIN_ONECUT_ZONE_SIZE 2
@d MIN_TWOCUT_ZONE_SIZE 3

@<Look at the results and return connections to cut, if any look good enough@> =
	if ((size - best_spread[BEST_ONECUT_ER])/2 >= MIN_ONECUT_ZONE_SIZE) {
		*from = best_from1[BEST_ONECUT_ER];
		*to = best_to1[BEST_ONECUT_ER];
		*way = best_dir1[BEST_ONECUT_ER];
		return TRUE;
	}
	if ((size - best_spread[BEST_PARALLEL_TWOCUT_ER])/2 >= MIN_TWOCUT_ZONE_SIZE) {
		*from = best_from1[BEST_PARALLEL_TWOCUT_ER];
		*to = best_to1[BEST_PARALLEL_TWOCUT_ER];
		*way = best_dir1[BEST_PARALLEL_TWOCUT_ER];
		*from2 = best_from2[BEST_PARALLEL_TWOCUT_ER];
		*to2 = best_to2[BEST_PARALLEL_TWOCUT_ER];
		*way2 = best_dir2[BEST_PARALLEL_TWOCUT_ER];
		return TRUE;
	}
	if ((size - best_spread[BEST_TWOCUT_ER])/2 >= MIN_TWOCUT_ZONE_SIZE) {
		*from = best_from1[BEST_TWOCUT_ER];
		*to = best_to1[BEST_TWOCUT_ER];
		*way = best_dir1[BEST_TWOCUT_ER];
		*from2 = best_from2[BEST_TWOCUT_ER];
		*to2 = best_to2[BEST_TWOCUT_ER];
		*way2 = best_dir2[BEST_TWOCUT_ER];
		return TRUE;
	}

@ The return value of |PL::SpatialMap::assign_generation_count| is the number of rooms which
it, and its recursive incarnations, visit in total. But as noted above, it
also records data in the arrays it is passed pointers to; that's what the
last eleven arguments are for. Otherwise: |at| is the room we are currently at,
and |from| is the one we've just come from, or |NULL| if this is the opening
call; |size| is the number of rooms in the submap.

=
int PL::SpatialMap::assign_generation_count(instance *at, instance *from, int size,
	int *best_spread,
	instance **best_from1, instance **best_to1, int *best_dir1,
	instance **best_from2, instance **best_to2, int *best_dir2,
	int *contact_generation,
	instance **contact_from, instance **contact_to, int *contact_dir) {
	int rooms_visited = 0;
	int generation = MAP_DATA(at)->zone, i;
	LOG_INDENT;
	int locking_to_neighbours = TRUE;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_slock(at, i);
		if (T) {
			@<Exclude generating this way if we don't need to@>;
			@<Actually generate this way@>;
		}
	}
	locking_to_neighbours = FALSE;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_smap(at, i);
		if (T) {
			@<Exclude generating this way if we don't need to@>;
			@<Actually generate this way@>;
		}
	}
	LOG_OUTDENT;
	return rooms_visited + 1;
}

@ We eliminate: routes from the current room to itself, or back the way
we just came to get here; routes to rooms with equal or higher generation
counts than the current one -- those are places already visited; and
routes to rooms with lower generations -- but those are contacts, so
we may need to record them before moving on.

What this leaves is cases where |T_generation| is zero, that is, where
|T| is a room with no generation count. This ensures |PL::SpatialMap::assign_generation_count|
is called at most once on each room.

@<Exclude generating this way if we don't need to@> =
	if ((T == at) || (T == from)) continue;
	int T_generation = MAP_DATA(T)->zone;
	if (T_generation >= generation) continue;
	if ((T_generation > 0) && (T_generation < generation)) {
		int observed_generation = T_generation;
		instance *observed_from = at;
		instance *observed_to = T;
		int observed_dir = i;
		@<Contact hasss been made@>;
		continue;
	}

@ At this point, it's as if we have been sent out to explore a labyrinth.
One problem we have is that we can't see what lies beyond here, with our
own eyes. "The underground rooms I can speak of only from report, because
the Egyptians in charge refused to let me see them, as they contain the
tombs of the kings who built the labyrinth, and also the tombs of the
sacred crocodiles" (Herodotus). So we must send out explorers who will
report back, but that costs us resources. "One doctrine called for
guarding every intersection such as this one. But I had already used two
men to guard our escape hole; if I left 10 per cent of my force at each
intersection, mighty soon I would be ten-percented to death" (Heinlein).
We must be careful of men, too: we can't afford to send out explorers
indefinitely because the running time and stack consumption would then be
prohibitive. The traditional approach is to unwind a ball of wool to avoid
going around in circles, but we'll instead use the generation counts -- we
might imagine writing these on the ground everywhere we go.

So let us think of ourselves as dividing the party, and sending out a team of
explorers across the bridge from |at| to |T|, telling them to explore every
possible avenue, and record any contacts they make with the world we
already know about. We will wait here until they get back, and ask them how
many new places they managed to visit. Maybe there's a whole world over
there, maybe just a broom cupboard.

@<Actually generate this way@> =
	int inner_contact_generation[CLIPBOARD_SIZE], inner_contact_dir[CLIPBOARD_SIZE];
	instance *inner_contact_from[CLIPBOARD_SIZE], *inner_contact_to[CLIPBOARD_SIZE];
	@<Give the new team of explorers a fresh clipboard@>;

	MAP_DATA(T)->zone = generation + 1;
	int rooms_explored_in_the_beyond = PL::SpatialMap::assign_generation_count(T, at, size,
		best_spread,
		best_from1, best_to1, best_dir1,
		best_from2, best_to2, best_dir2,
		inner_contact_generation, inner_contact_from, inner_contact_to, inner_contact_dir);
	rooms_visited += rooms_explored_in_the_beyond;

	@<Copy interesting items from the returning team's clipboard to ours@>;
	if (locking_to_neighbours == FALSE)
		@<Consider this link as a potential cut-position@>;

@ Each fresh team of explorers gets a fresh clipboard on which to record what
they see -- hence the new set of |inner_contact_*| arrays. (They don't get
individual copies of the |best_*| arrays, though -- that's the point of these;
they're shared in common among all of the explorers.)

@<Give the new team of explorers a fresh clipboard@> =
	int j;
	for (j = 0; j < CLIPBOARD_SIZE; j++) {
		inner_contact_generation[j] = -1;
		inner_contact_from[j] = NULL; inner_contact_to[j] = NULL; inner_contact_dir[j] = -1;
	}

@ When the explorers get back, tired but happy, we look at their clipboard,
and see if those contacts excite us too -- which they may not, because what
seemed to them a rediscovery might not seem that way to us; they've seen
more of the world than we have. So we copy their contacts onto our own
clipboard only if they are contacts to places we know about, too.

@<Copy interesting items from the returning team's clipboard to ours@> =
	int j;
	for (j = 0; j < CLIPBOARD_SIZE; j++) {
		int observed_generation = inner_contact_generation[j];
		if ((observed_generation > 0) && (observed_generation < generation)) {
			instance *observed_from = inner_contact_from[j];
			instance *observed_to = inner_contact_to[j];
			int observed_dir = inner_contact_dir[j];
			@<Contact hasss been made@>;
		}
	}

@ Our clipboard contains a short list of observed contacts, sorted with
lowest observed generation first. (If more contacts are observed than will
fit on the clipboard, they're thrown away.)

@<Consider this link as a potential cut-position@> =
	int no_contacts_found = 0;
	int j;
	for (j = 0; j < CLIPBOARD_SIZE; j++)
		if (inner_contact_generation[j] > 0)
			no_contacts_found++;

	if (no_contacts_found < CLIPBOARD_SIZE) {
		int spread = size - 2*rooms_explored_in_the_beyond;
		if (spread < 0) spread = -spread;
		if (no_contacts_found == 0)
			@<Cutting on this link would disconnect the submap@>
		else if (no_contacts_found == 1)
			@<Cutting on this link and the contact found would disconnect the submap@>;
	}

@ If exploration outward from here never resulted in a contact with known
territory, then cutting this link strands the far side as a disconnected zone.

@<Cutting on this link would disconnect the submap@> =
	if (spread < best_spread[BEST_ONECUT_ER]) {
		best_spread[BEST_ONECUT_ER] = spread;
		best_from1[BEST_ONECUT_ER] = at;
		best_to1[BEST_ONECUT_ER] = T;
		best_dir1[BEST_ONECUT_ER] = i;
	}

@ If exploration found just one contact, then that link, plus this one, would
if both removed cut off the far side. We have to be careful that we never
cut along locks, only along map connections; we know that the |at| to |T|
link isn't a lock, because we never come here in |locking_to_neighbours|
mode. But we don't know that for the observed contact, so we check by hand.

The division is "parallel" if the two links are in the same or opposite
direction, like the two long tubes of a trombone; this makes it easier to
slide the zones to and fro without angular distortion, so we prefer it if
we can get it.

@<Cutting on this link and the contact found would disconnect the submap@> =
	if (PL::SpatialMap::read_slock(inner_contact_from[0], inner_contact_dir[0]) == inner_contact_to[0]) break;
	int r = BEST_TWOCUT_ER;
	if ((inner_contact_dir[0] == i) || (inner_contact_dir[0] == PL::SpatialMap::opposite(i)))
		r = BEST_PARALLEL_TWOCUT_ER;
	if (spread < best_spread[r]) {
		best_spread[r] = spread;
		best_from1[r] = at; best_to1[r] = T; best_dir1[r] = i;
		best_from2[r] = inner_contact_from[0];
		best_to2[r] = inner_contact_to[0];
		best_dir2[r] = inner_contact_dir[0];
	}

@ This is a piece of code used twice in the above routine: it puts the
contact |observed_from| to |observed_to| onto our clipboard, provided that
there's room and/or it is interesting enough. We use an insertion-sort to
keep the clipboard in ascending generation order: this would be slow if the
contact arrays were large, but |CLIPBOARD_SIZE| is tiny.

@<Contact hasss been made@> =
	int k;
	for (k = 0; k < CLIPBOARD_SIZE; k++)
		if ((contact_generation[k] == -1) ||
			(observed_generation <= contact_generation[k])) {
			int l;
			for (l = CLIPBOARD_SIZE-1; l > k; l--) {
				contact_generation[l] = contact_generation[l-1];
				contact_from[l] = contact_from[l-1]; contact_to[l] = contact_to[l-1];
				contact_dir[l] = contact_dir[l-1];
			}
			contact_generation[k] = observed_generation;
			contact_from[k] = observed_from; contact_to[k] = observed_to;
			contact_dir[k] = observed_dir;
			break;
		}

@h Zones 1 and 2 for a single cut.
Suppose we have decided to cut the submap between rooms |R1| and |R2|, in the
belief that this will disconnect the submap into two components. If that in
fact proves to be the case (as it always should) then we set the |zone| field
to |Z1| for all rooms in the R1 component, and |Z2| on the R1 side. We set
|Z1_count| and |Z2_count| to the sizes of these components, and return |TRUE|.
If, however, cutting does not disconnect the submap, then some mistake has
been made; we return |FALSE| and the rest is undefined.

It is essential for |Z1| and |Z2| to be different. What we will do is to
spread out these zone values from |R1| and |R2| along all spatial
relationships not being cut; if this results in R2 being hit by the flood
from R1, or vice versa, then we're in the |FALSE| case.

=
int PL::SpatialMap::divide_into_zones_onecut(connected_submap *sub, instance *R1, instance *R2,
	int *Z1_count, int *Z2_count, int Z1, int Z2) {
	if (R1 == R2) internal_error("can't divide");
	instance *R;
	LOOP_OVER_SUBMAP(R, sub) MAP_DATA(R)->zone = 0;
	MAP_DATA(R1)->zone = Z1; MAP_DATA(R2)->zone = Z2;
	*Z1_count = 0; *Z2_count = 0;
	int contacts = 0;
	*Z1_count = PL::SpatialMap::divide_into_zones_onecut_r(R1, NULL, R1, R2, &contacts);
	if (contacts > 0) return FALSE;
	*Z2_count = PL::SpatialMap::divide_into_zones_onecut_r(R2, NULL, R2, R1, &contacts);
	LOOP_OVER_SUBMAP(R, sub)
		if (MAP_DATA(R)->zone == 0)
			MAP_DATA(R)->zone = Z1;
	if ((MAP_DATA(R1)->zone == Z1) && (MAP_DATA(R2)->zone == Z2) &&
		((*Z1_count) > 1) && ((*Z2_count) > 1)) return TRUE;
	return FALSE;
}

@ And this is the recursive flooding routine -- essentially it's a much
simplified version of the exploration code above. |from| is the room we're
currently at; |zone_capital| is the one we started from, within our zone;
|foreign_capital| is corresponding room of the other zone, so (a) we
mustn't travel on the direct route between the capitals -- that's the line
which has been cut -- and (b) we abandon the moment we find our zone
impinging on the foreign zone, because that means there's no way to divide
our original component into two disjoint connected zones.

=
int PL::SpatialMap::divide_into_zones_onecut_r(instance *at, instance *from,
	instance *our_capital, instance *foreign_capital, int *borders) {
	int rooms_visited = 0;
	int our_zone = MAP_DATA(at)->zone, i;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_slock(at, i);
		if (T) @<Consider whether to spread the zone to room T@>;
	}
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_smap(at, i);
		if (T) @<Consider whether to spread the zone to room T@>;
	}
	return rooms_visited + 1;
}

@<Consider whether to spread the zone to room T@> =
	int T_zone = MAP_DATA(T)->zone, foreign_zone = MAP_DATA(foreign_capital)->zone;
	if (T_zone == our_zone) continue;
	if ((at == our_capital) && (T == foreign_capital)) continue;
	if ((at == foreign_capital) && (T == our_capital)) continue;
	if (T_zone == foreign_zone) { (*borders)++; continue; }
	MAP_DATA(T)->zone = our_zone;
	rooms_visited +=
		PL::SpatialMap::divide_into_zones_onecut_r(T, at, our_capital, foreign_capital, borders);

@h Zones 1 and 2 for a double cut.
This is more or less the same, but simpler, since it can't determine whether
we've chosen the cuts correctly, so doesn't even try.

=
void PL::SpatialMap::divide_into_zones_twocut(instance *div_F1, instance *div_T1,
	instance *other_F, instance *div_T2, int Z1, int Z2) {
	connected_submap *sub = MAP_DATA(div_F1)->submap;
	instance *R;
	LOOP_OVER_SUBMAP(R, sub) MAP_DATA(R)->zone = 0;
	MAP_DATA(div_F1)->zone = Z1; MAP_DATA(div_T1)->zone = Z2;
	PL::SpatialMap::divide_into_zones_twocut_r(div_F1, div_F1, div_T1, other_F, div_T2);
	PL::SpatialMap::divide_into_zones_twocut_r(div_T1, div_F1, div_T1, other_F, div_T2);
}

@ =
void PL::SpatialMap::divide_into_zones_twocut_r(instance *at, instance *not_X1, instance *not_Y1,
	instance *not_X2, instance *not_Y2) {
	int Z = MAP_DATA(at)->zone, i;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_slock(at, i);
		if (T) @<Consider once again whether to spread the zone to room T@>;
	}
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_smap(at, i);
		if (T) @<Consider once again whether to spread the zone to room T@>;
	}
}

@<Consider once again whether to spread the zone to room T@> =
	if ((T != at) && (MAP_DATA(T)->zone == 0)) {
		if (((at == not_X1) && (T == not_Y1)) || ((at == not_Y1) && (T == not_X1)))
			continue;
		if (((at == not_X2) && (T == not_Y2)) || ((at == not_Y2) && (T == not_X2)))
			continue;
		MAP_DATA(T)->zone = Z;
		PL::SpatialMap::divide_into_zones_twocut_r(T, not_X1, not_Y1, not_X2, not_Y2);
	}

@h Tactics.
At long last we can forget about dividing submaps, and concentrate on the
four tactics for improving the layout of a given submap. We're going to do
all kinds of heuristic things here, some of them with iffy running times,
which is one reason why the above divide-and-conquer tricks were wise
(the other that divisions also reduce the complexity of the pieces we
need to work on).

We'll often experimentally change something, see what that does, then
change our minds. For really large-scale experimental changes to the grid
it's convenient to have a sort of global undo. Note that lock positions
after restoration must be consistent, since they were consistent at save
time.

=
void PL::SpatialMap::save_component_positions(connected_submap *sub) {
	instance *R;
	LOOP_OVER_SUBMAP(R, sub)
		MAP_DATA(R)->saved_gridpos = Room_position(R);
}

void PL::SpatialMap::restore_component_positions(connected_submap *sub) {
	instance *R;
	LOOP_OVER_SUBMAP(R, sub)
		PL::SpatialMap::set_room_position(R, MAP_DATA(R)->saved_gridpos);
}

@h The cooling tactic.
The whole universe was in a hot dense state: as we begin each component,
every room is at (0,0,0) unless locking causes it to offset slightly, so that
almost every exit is very hot indeed. We now enter the era of cooling,
when a great expansion occurs.

This is an iterative process, and if we ran this algorithm indefinitely it
would very likely lock up, continually moving rooms back and forth but never
solving its underlying geometric problems. So cooling may only continue so
long as component heat is strictly reduced on each round.

Cooling has the great virtue that each round runs in $O(S)$ time, where $S$
is the number of rooms in the submap. It's quite hard to estimate the
total running time, but in practice the number of rounds seldom exceeds
3 or 4, even on quite bad maps, and because cooling is essentially a
local process there's no reason to expect the number of rounds to grow much
if $S$ grows. So my guess is that cooling is $O(S)$ in practice.

Another virtue is that cooling alone works in many easy cases. If there are
no locks, and no multiple exits between pairs of rooms A to B, then cooling
is guaranteed to find a perfect (heat 0) grid positioning if one exists.
There are plenty of Inform projects for which that happens: "Bronze",
for instance, has a single component of 55 rooms, and one round of cooling
reduces this to absolute zero.

=
void PL::SpatialMap::cool_submap(connected_submap *sub) {
	int initial_heat = PL::SpatialMap::find_submap_heat(sub), initial_spending = drognas_spent;
	LOGIF(SPATIAL_MAP, "\nTACTIC: Cooling submap %d: initial heat %d\n",
		sub->allocation_id, sub->heat);
	int heat_before_round = initial_heat;
	int rounds = 0;
	while (TRUE) {
		LOGIF(SPATIAL_MAP, "Cooling round %d.\n", ++rounds);
		instance *R;
		LOOP_OVER_SUBMAP(R, sub) MAP_DATA(R)->cooled = FALSE;
		PL::SpatialMap::save_component_positions(sub);
		LOOP_OVER_SUBMAP(R, sub) PL::SpatialMap::cool_component_from(sub, R);
		PL::SpatialMap::find_submap_heat(sub);
		if (sub->heat == 0) break;
		if (sub->heat >= heat_before_round) {
			PL::SpatialMap::restore_component_positions(sub);
			PL::SpatialMap::find_submap_heat(sub);
			LOGIF(SPATIAL_MAP, "Cooling round %d raised heat, so undone.\n", rounds);
			break;
		} else {
			LOGIF(SPATIAL_MAP, "Cooling round %d leaves penalty %d.\n", rounds, sub->heat);
		}
		heat_before_round = sub->heat;
	}
	LOGIF(SPATIAL_MAP,
		"Cooling submap %d done (%d round(s)): cooled by %d at cost of %d drognas\n\n",
		sub->allocation_id, rounds,
		initial_heat - sub->heat, drognas_spent - initial_spending);
	cooling_spending += drognas_spent - initial_spending;
}

@ Cooling is done room by room within the component, but we get slightly
better results if it is allowed to spread through the component along exits
as they cool than if it is simply performed on the rooms in creation order.
Since the map likely contains circular routes, rooms are flagged so that they
can only be cooled once in a given round.

=
void PL::SpatialMap::cool_component_from(connected_submap *sub, instance *R) {
	if (MAP_DATA(R)->cooled) return;
	MAP_DATA(R)->cooled = TRUE;

	int exit_heats[MAX_DIRECTIONS];
	instance *exit_rooms[MAX_DIRECTIONS];
	@<Find the exits from this room and their current heats@>;
	@<Iteratively cool as many exits as possible@>;
}

@<Find the exits from this room and their current heats@> =
	int i;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		exit_heats[i] = PL::SpatialMap::find_exit_heat(R, i);
		exit_rooms[i] = PL::SpatialMap::read_smap(R, i);
	}

@ An important point here is that we don't re-measure the heat of the exits
after cooling. If we did, we might find that cooling is having no effect, and
then lock up. We're simply trying to deal with the heat as it looked at the
start of the process; this means there are at most 12 iterations.

The reason we do this in what looks an indirect way (why iterate at all?) is
to cope better with cases where there are two different exits from R to S.
This frequently happens in IF maps:

>> The Exalted Throne is above the Ziggurat. [...] South from the Throne is the Ziggurat.

Now there are two exits from Z to E: up and north. They cannot simultaneously
be cooled. The rule we follow is that we never cool an exit if another exit
between the two rooms is already cold -- this keeps us from endless flipping
our choice (up from Z to E on cooling round 1, then north on round 2, then up
on round 3, and so on).

However, it makes a big difference to the style of the map we produce which
choice we make. Because the code below tries the exits in direction number
order, and because lateral directions (N, NE, E, SE, S, SW, W, NW) have
lower direction numbers than vertical (U, D), the effect is to prefer lateral
choices over vertical ones. This is a good choice for two reasons: (i) given
the way we're going to plot the map on a web page, vertical offsets are
harder to judge by eye; and (ii) IF authors often use "both N and U"-style
connections to convey that the landscape isn't totally flat, but they're
still talking about a two-dimensional surface. (Cartographers have always
done this. The French map IGN 3535 OT, N\'evache-Mont Thabor, shows the
Rois Mages mountains as if you could walk southeast from Modane and take in
all three in an afternoon stroll.)

@<Iteratively cool as many exits as possible@> =
	while (TRUE) {
		int i, exits_cooled = 0;
		LOOP_OVER_LATTICE_DIRECTIONS(i)
			if (exit_heats[i] > 0) {
				int j;
				LOOP_OVER_LATTICE_DIRECTIONS(j)
					if ((exit_heats[j] == 0) && (exit_rooms[i] == exit_rooms[j])) {
						exit_heats[i] = 0; exits_cooled++;
					}
				if (exit_heats[i] > 0) {
					PL::SpatialMap::cool_exit(R, i);
					exit_heats[i] = 0; exits_cooled++;
					PL::SpatialMap::cool_component_from(sub, exit_rooms[i]);
					LOOP_OVER_LATTICE_DIRECTIONS(j)
						if ((exit_heats[j] > 0) && (exit_rooms[i] == exit_rooms[j])) {
							exit_heats[j] = 0; exits_cooled++;
						}
				}
			}
		if (exits_cooled == 0) break;
	}

@ To cool an exit is to move the destination room into the perfect grid
position so that the exit's heat is 0. Note that we must always maintain
locking, and that we provide a convenient "undo" mechanism in case the
result made matters worse. (Cooling one exit may simply make other exits
hotter, since the destination room falls out of alignment with its other
neighbours.)

=
instance *saved_to; vector Saved_position;
void PL::SpatialMap::undo_cool_exit(void) {
	PL::SpatialMap::move_room_to(saved_to, Saved_position);
	LOGIF(SPATIAL_MAP_WORKINGS, "Undoing move of $O\n", saved_to);
}

void PL::SpatialMap::cool_exit(instance *R, int exit) {
	instance *to = PL::SpatialMap::read_smap(R, exit);
	saved_to = to; Saved_position = Room_position(to);

	vector D = PL::SpatialMap::direction_as_vector(exit);

	int length = MAP_DATA(R)->exit_lengths[exit];
	vector N = Geometry::vec_plus(Room_position(R), Geometry::vec_scale(length, D));

	if (Geometry::vec_eq(Room_position(to), N)) return;

	PL::SpatialMap::move_room_to(saved_to, N);
	LOGIF(SPATIAL_MAP_WORKINGS, "Moving $O %s from $O: now at (%d,%d,%d)\n",
		to, PL::SpatialMap::find_icon_label(exit), R, N.x, N.y, N.z);
}

@h The quenching tactic.
After the age of cooling, we can expect the universe to be mostly cold, but
with local hot-spots where the geometry is distorted because the map is
simply awkward nearby. Because this tends to be a local problem, we try to
find a local solution -- it's actually just individualised exit cooling.

This theoretically runs in $O(S^3)$ time: note that the measurement of
submap heat is itself $O(S)$, and we perform this inside a loop of $O(S)$,
which in turn happens within a repetition which might run for every link
in the map, also $O(S)$. In practice, there are never many quenching rounds,
so it's really "only" $O(S^2)$. Still, this is why we don't want to quench
on large connected submaps.

=
void PL::SpatialMap::quench_submap(connected_submap *sub, instance *avoid1, instance *avoid2) {
	int initial_heat = PL::SpatialMap::find_submap_heat(sub), initial_spending = drognas_spent;
	LOGIF(SPATIAL_MAP, "\nTACTIC: Quenching submap %d: initial heat %d\n",
		sub->allocation_id, sub->heat);
	instance *R;
	int heat = sub->heat, last_heat = sub->heat + 1, rounds = 0;
	while (heat < last_heat) {
		LOGIF(SPATIAL_MAP, "Quenching round %d begins with heat at %d.\n", ++rounds, heat);
		LOG_INDENT;
		last_heat = heat;
		int successes = 0;
		LOOP_OVER_SUBMAP(R, sub) {
			int i;
			LOOP_OVER_LATTICE_DIRECTIONS(i)
				if (PL::SpatialMap::find_exit_heat(R, i) > 0)
					@<Attempt to quench this heated link@>;
		}
		LOG_OUTDENT;
		LOGIF(SPATIAL_MAP, "Quenching round %d had %d success(es).\n", rounds, successes);
	}
	LOGIF(SPATIAL_MAP, "Quenching submap %d done: cooled by %d at cost of %d drognas\n",
		sub->allocation_id, initial_heat - sub->heat, drognas_spent - initial_spending);
	quenching_spending += drognas_spent - initial_spending;
}

@<Attempt to quench this heated link@> =
	instance *T = PL::SpatialMap::read_smap(R, i);
	if ((T == avoid1) && (R == avoid2)) continue;
	if ((T == avoid2) && (R == avoid1)) continue;
	LOGIF(SPATIAL_MAP_WORKINGS, "Quenching $O %s to $O.\n",
		R, PL::SpatialMap::find_icon_label(i), T);
	PL::SpatialMap::cool_exit(R, i);
	int h = PL::SpatialMap::find_submap_heat(sub);
	if (h >= heat) {
		PL::SpatialMap::undo_cool_exit();
		LOGIF(SPATIAL_MAP_WORKINGS, "Undoing: would have resulted in heat %d\n", h);
	} else {
		heat = h;
		LOGIF(SPATIAL_MAP_WORKINGS, "Accepting: reduces heat to %d\n", h);
		successes++;
	}

@h The diffusion tactic.
Where quenching fails to help much, this is usually because rooms are packed
too tightly together, and need to be eased apart. This makes space for
more interesting configurations and makes it easier to get rid of the very
large collision heats, though the heat of some individual links actually
rises, since there's a penalty for increasing length.

We call this process diffusion, since the heat eddies away into the local
neighbourhood as the rooms shimmy apart.

=
void PL::SpatialMap::diffuse_submap(connected_submap *sub) {
	int initial_heat = PL::SpatialMap::find_submap_heat(sub), initial_spending = drognas_spent;
	LOGIF(SPATIAL_MAP, "\nTACTIC: Diffusing submap %d: initial heat %d\n",
		sub->allocation_id, sub->heat);
	instance *R;
	int heat = sub->heat, last_heat = sub->heat + 1, rounds = 0;
	while (heat < last_heat) {
		LOGIF(SPATIAL_MAP, "Diffusion round %d with heat at %d.\n", ++rounds, heat);
		LOG_INDENT;
		last_heat = heat;
		LOOP_OVER_SUBMAP(R, sub) {
			int i;
			LOOP_OVER_LATTICE_DIRECTIONS(i) {
				instance *T = PL::SpatialMap::read_smap(R, i);
				if (T)
					@<Try diffusion along this link@>;
			}
		}
		LOG_OUTDENT;
	}
	LOGIF(SPATIAL_MAP, "Diffusing submap %d done after %d round(s): "
		"cooled by %d at cost of %d drognas\n",
		sub->allocation_id, rounds,
		initial_heat - sub->heat, drognas_spent - initial_spending);
	diffusion_spending += drognas_spent - initial_spending;
}

@ Essentially we try lengthening the link by 1 unit, and see if that makes
things better; however, it tends to be useless just moving one room, because
that's very likely only moving a collision heat (let's say) one place down
the grid. So we move not only the room but also a whole clump of nearby
rooms whose exits are cold (or which are locked to each other).

@<Try diffusion along this link@> =
	int L = MAP_DATA(R)->exit_lengths[i];
	if (L > -1) {
		LOGIF(SPATIAL_MAP_WORKINGS, "Lengthening $O %s to $O to %d.\n",
			R, PL::SpatialMap::find_icon_label(i), T, L+1);
		LOG_INDENT;
		PL::SpatialMap::save_component_positions(sub);

		vector O = Room_position(R);
		MAP_DATA(R)->exit_lengths[i] = L+1;
		PL::SpatialMap::cool_exit(R, i);
		vector D = Geometry::vec_minus(Room_position(R), O);
		instance *S;
		LOOP_OVER_SUBMAP(S, sub) MAP_DATA(S)->zone = 1;
		PL::SpatialMap::diffuse_across(R, T);
		LOOP_OVER_SUBMAP(S, sub)
			if ((MAP_DATA(S)->zone == 2) && (S != R))
				PL::SpatialMap::translate_room(S, D);
		PL::SpatialMap::find_submap_heat(sub);

		if (sub->heat >= heat) {
			PL::SpatialMap::restore_component_positions(sub);
			MAP_DATA(R)->exit_lengths[i] = L;
			PL::SpatialMap::find_submap_heat(sub);
			LOGIF(SPATIAL_MAP_WORKINGS, "Lengthening left heat undecreased at %d.\n", sub->heat);
			LOG_OUTDENT;
		} else {
			LOGIF(SPATIAL_MAP_WORKINGS, "Lengthening reduced heat to %d.\n", sub->heat);
			heat = sub->heat;
			LOG_OUTDENT;
			break;
		}
	}

@ This recursively expands zone 2 to include rooms connected by cold links,
except that it's forbidden to including |avoiding| (the room we are trying
to lengthen away from).

=
void PL::SpatialMap::diffuse_across(instance *at, instance *avoiding) {
	MAP_DATA(at)->zone = 2;
	int i;
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_slock(at, i);
		if ((T) && (MAP_DATA(T)->zone == 1)) PL::SpatialMap::diffuse_across(T, avoiding);
	}
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_smap(at, i);
		if ((T) && (MAP_DATA(T)->zone == 1) && (T != avoiding) &&
			(PL::SpatialMap::find_exit_heat(at, i) == 0))
			PL::SpatialMap::diffuse_across(T, avoiding);
	}
}

@h The radiation tactic.
Here, we look for misaligned links, because they'll look broken to the eye,
and see if it's possible to slide a block of rooms in one of the compass
directions so that the link becomes aligned again.

This is such a neat trick, and so (relatively!) fast, that we apply it in
two circumstances: not only when tidying up after diffusion, but also after
we have rejoined a divided submap. (It's especially good for that because
after a two-point cut we often have a situation where one of the cut links
is put back tidily but the other is dislocated.)

It's hard to prove that radiation is rapid, because it certainly wouldn't be
if used earlier on. What saves us is that by now there are few misaligned
links.

=
void PL::SpatialMap::radiate_submap(connected_submap *sub) {
	int initial_heat = PL::SpatialMap::find_submap_heat(sub), initial_spending = drognas_spent;
	LOGIF(SPATIAL_MAP, "\nTACTIC: Radiating submap %d: initial heat %d\n",
		sub->allocation_id, sub->heat);
	instance *R;
	int heat = sub->heat, last_heat = sub->heat + 1, rounds = 0;
	while (heat < last_heat) {
		LOGIF(SPATIAL_MAP, "Radiation round %d with heat at %d.\n", ++rounds, heat);
		LOG_INDENT;
		last_heat = heat;
		LOOP_OVER_SUBMAP(R, sub) {
			int i;
			LOOP_OVER_LATTICE_DIRECTIONS(i) {
				instance *T = PL::SpatialMap::read_smap(R, i);
				if (T) {
					if (PL::SpatialMap::exit_aligned(R, i) == FALSE)
						@<Attempt to radiate from this misaligned link@>;
				}
			}
		}
		LOG_OUTDENT;
	}
	PL::SpatialMap::find_submap_heat(sub);
	LOGIF(SPATIAL_MAP, "Radiating submap %d done after %d round(s): "
		"cooled by %d at cost of %d drognas\n",
		sub->allocation_id, rounds,
		initial_heat - sub->heat, drognas_spent - initial_spending);
	radiation_spending += drognas_spent - initial_spending;
}

@ We try some 40 possible translations of the R end of the link, hoping to
find that one or more of them will align with the T end. T will stay
fixed: note that by symmetry, if this doesn't work, we'll end up testing
the same link with the roles of R and T reversed later. Typically, there
are only three or four viable new positions for R.

@d MAX_RADIATION_DISTANCE 5

@<Attempt to radiate from this misaligned link@> =
	LOGIF(SPATIAL_MAP_WORKINGS, "Map misaligned on $O %s to $O.\n",
		R, PL::SpatialMap::find_icon_label(i), T);
	LOG_INDENT;
	int j;
	vector O = Room_position(R);
	LOOP_OVER_LATTICE_DIRECTIONS(j) {
		vector E = PL::SpatialMap::direction_as_vector(j);
		int L;
		for (L = 1; L <= MAX_RADIATION_DISTANCE; L++) {
			vector D = Geometry::vec_scale(L, E);
			PL::SpatialMap::set_room_position(R, Geometry::vec_plus(O, D));
			if (PL::SpatialMap::exit_aligned(R, i))
				@<Radiation is geometrically possible here@>;
		}
		PL::SpatialMap::set_room_position(R, O);
	}
	Escape: ;
	LOG_OUTDENT;

@ At this point setting this up is much the same as for diffusion:

@<Radiation is geometrically possible here@> =
	LOGIF(SPATIAL_MAP_WORKINGS, "Aligned at offset %d, %d, %d\n", D.x, D.y, D.z);
	PL::SpatialMap::save_component_positions(sub);
	instance *S;
	LOOP_OVER_SUBMAP(S, sub) MAP_DATA(S)->zone = 1;
	PL::SpatialMap::radiate_across(R, T, j);
	LOOP_OVER_SUBMAP(S, sub)
		if ((MAP_DATA(S)->zone == 2) && (S != R)) {
			LOGIF(SPATIAL_MAP_WORKINGS, "Comoving $O\n", S);
			PL::SpatialMap::translate_room(S, D);
		}
	PL::SpatialMap::find_submap_heat(sub);
	if (sub->heat >= heat) {
		PL::SpatialMap::restore_component_positions(sub);
		LOGIF(SPATIAL_MAP_WORKINGS,
			"Radiating left heat undecreased at %d.\n", sub->heat);
	} else {
		LOGIF(SPATIAL_MAP_WORKINGS,
			"Radiating reduced heat to %d.\n", sub->heat);
		heat = sub->heat;
		goto Escape;
	}

@ This is the clever part of radiation, and the reason why we only allow R
to radiate outward on cardinal points of the compass. Once again we will
move a whole clump of R's neighbours along with it, preserving their positions
relative to each other; but this time we define the boundary of the clump
by links in the radiation direction, or its opposite. The result is that
no exit can ever become misaligned during radiation; the only movements
happen parallel to the only links whose endpoints move with respect to each
other. (With just one exception, of course: the link between R and T,
where by construction the movement will make a previously unaligned link
become aligned.)

It follows that radiation can never increase the number of unaligned links.

=
void PL::SpatialMap::radiate_across(instance *at, instance *avoiding, int not_this_way) {
	MAP_DATA(at)->zone = 2;
	int i, not_this_way_either = PL::SpatialMap::opposite(not_this_way);
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_slock(at, i);
		if ((T) && (MAP_DATA(T)->zone == 1))
			PL::SpatialMap::radiate_across(T, avoiding, not_this_way);
	}
	LOOP_OVER_LATTICE_DIRECTIONS(i) {
		instance *T = PL::SpatialMap::read_smap(at, i);
		if ((T) && (MAP_DATA(T)->zone == 1) && (T != avoiding) &&
			(i != not_this_way) && (i != not_this_way_either))
			PL::SpatialMap::radiate_across(T, avoiding, not_this_way);
	}
}

@h The explosion tactic.
Sometimes, in the direst emergency, there's one tried and tested way to
get rid of a lot of concentrated heat: to explode. Specifically, we get
rid of collisions between rooms (which we absolutely forbid) by moving them
apart until there are no further collisions. We do this even if it should
increase the heat measure, though in practice the penalty for room collisions
is so high that this is unlikely to be an issue.

@d MAX_EXPLOSION_DISTANCE 3

=
void PL::SpatialMap::explode_submap(connected_submap *sub) {
	int initial_heat = PL::SpatialMap::find_submap_heat(sub), initial_spending = drognas_spent;
	LOGIF(SPATIAL_MAP, "\nTACTIC: Exploding submap %d: initial heat %d\n",
		sub->allocation_id, sub->heat);
	int keep_trying = TRUE, moves = 0;
	while (keep_trying) {
		keep_trying = FALSE;
		instance *R;
		LOOP_OVER_SUBMAP(R, sub) {
			vector At = Room_position(R);
			if (PL::SpatialMap::occupied_in_submap(sub, At) >= 2) {
				LOGIF(SPATIAL_MAP, "Collision: pushing $O away\n", R);
				int x, y, coldest = FUSION_POINT;
				vector Coldest = Geometry::vec(MAX_EXPLOSION_DISTANCE + 1, 0, 0);
				for (x = -MAX_EXPLOSION_DISTANCE; x<=MAX_EXPLOSION_DISTANCE; x++)
					for (y = -MAX_EXPLOSION_DISTANCE; y<=MAX_EXPLOSION_DISTANCE; y++)
						if ((x != 0) || (y != 0)) {
							vector V = Geometry::vec_plus(At, Geometry::vec(x, y, 0));
							if (PL::SpatialMap::occupied_in_submap(sub, V) == 0) {
								PL::SpatialMap::move_room_to(R, V);
								int h = PL::SpatialMap::find_submap_heat(sub);
								if (h < coldest) { Coldest = V; coldest = h; }
							}
						}
				PL::SpatialMap::move_room_to(R, Geometry::vec_plus(At, Coldest));
				LOGIF(SPATIAL_MAP, "Moving $O to blank offset (%d,%d,%d) for heat %d\n",
					R, Coldest.x, Coldest.y, Coldest.z, coldest);
				keep_trying = TRUE;
				moves++;
				break;
			}
		}
	}
	PL::SpatialMap::find_submap_heat(sub);
	LOGIF(SPATIAL_MAP, "Exploding submap %d done after %d move(s): "
		"cooled by %d at cost of %d drognas\n",
		sub->allocation_id, moves,
		initial_heat - sub->heat, drognas_spent - initial_spending);
	explosion_spending += drognas_spent - initial_spending;
}

@h Stage 3, positioning the components.
Having cooled and diffused each component, we now treat them as rigid
bodies, but still have to establish their spatial relationship to each
other. We ensure that the components do not overlap by the crude method of
making their bounding cuboids disjoint, even though this will often mean
that there is wasted space on the page. (Thus we do not, for instance, use
the trick adopted by the British Ordnance Survey in mapping the outlying
island of St Kilda on an inset square of what would otherwise be empty
ocean on OS18 "Sound of Harris", despite its being separated by about
60km from the position shown.)

@<(4) Position the components in space@> =
	int ncom = NUMBER_CREATED(connected_submap);
	connected_submap **sorted =
		Memory::calloc(ncom, sizeof(connected_submap *), INDEX_SORTING_MREASON);
	@<Sort the components into decreasing order of size@>;

	connected_submap *sub, *previous_mc = NULL;
	int i, j;
	vector Drill_square_O = Zero_vector;
	vector Drill_square_At = Zero_vector;
	int drill_square_side = 0;
	cuboid box = Geometry::empty_cuboid();
	for (i=0; i<ncom; i++) {
		sub = sorted[i];
		if (sub->positioned == FALSE) {
			@<Position this map component in space@>;
			for (j=ncom-1; j>=0; j--) {
				sub = sorted[j];
				if ((sub->positioned == FALSE) &&
					(PL::SpatialMap::no_links_to_placed_components(sub) == 1)) {
					@<Position this map component in space@>;
				}
			}
		}
	}

	Memory::I7_array_free(sorted, INDEX_SORTING_MREASON, ncom, sizeof(connected_submap *));

@<Position this map component in space@> =
	if (previous_mc) {
		int x_max = box.corner1.x - sub->bounds.corner0.x + 1;
		if ((sub->bounds.population == 1) && (PL::SpatialMap::component_is_isolated(sub)))
			@<Use the drill-square strategy to place this component@>
		else if (PL::SpatialMap::component_is_adjoining(sub))
			@<Use the optimised inset strategy to place this component@>
		else
			@<Use the side-by-side strategy to place this component@>;
	}
	Geometry::merge_cuboid(&box, sub->bounds);
	previous_mc = sub;
	sub->positioned = TRUE;

@ Here we simply place the component immediately to the right of its
predecessor, with the same baseline, and on the level of the benchmark room.

@<Use the side-by-side strategy to place this component@> =
	LOGIF(SPATIAL_MAP, "Component %d (size %d): side by side strategy\n",
		sub->allocation_id, sub->bounds.population);
	PL::SpatialMap::move_component(sub,
		Geometry::vec(x_max, box.corner0.y - sub->bounds.corner0.y,
			Room_position(benchmark_room).z - sub->bounds.corner0.z));

@ The drill square is a way to place large numbers of single-room components,
such as exist in IF works where rooms are being plaited together live during
play and have no initial map. Side-by-side placement would be horrible for
such rooms. We will form the most nearly square rectangle which can hold
them, arranged so that it's slightly wider than it is tall. In effect, this
rectangle -- the "drill square" -- is then placed side-by-side as if it's
one big component.

@<Use the drill-square strategy to place this component@> =
	LOGIF(SPATIAL_MAP, "Component %d (size %d): drill square strategy\n",
		sub->allocation_id, sub->bounds.population);
	if (drill_square_side == 0) {
		Drill_square_O =
			Geometry::vec(box.corner1.x + 1, box.corner0.y, Room_position(benchmark_room).z);
		Drill_square_At = Drill_square_O;
		connected_submap *sing;
		int N = 0;
		LOOP_OVER(sing, connected_submap)
			if ((sing->bounds.population == 1) && (PL::SpatialMap::component_is_isolated(sing)))
				N++;
		while (drill_square_side*drill_square_side < N) drill_square_side++;
		if (drill_square_side*drill_square_side > N) drill_square_side--;
		LOGIF(SPATIAL_MAP, "Drill square: side %d\n", drill_square_side);
	}
	PL::SpatialMap::move_component(sub, Geometry::vec_minus(Drill_square_At, sub->bounds.corner0));
	Drill_square_At = Geometry::vec_plus(Drill_square_At, Geometry::vec(0, 1, 0));
	if (Drill_square_At.y - Drill_square_O.y == drill_square_side)
		Drill_square_At = Geometry::vec_plus(Drill_square_At,
			Geometry::vec(1, -drill_square_side, 0));

@ Insetting is used if our new component has a map connection in the IN or
OUT directions with an already-placed component; if we can, we want to place
the new component into the map as close as possible to the room it connects
with.

@d MAX_OFFSET 1

@<Use the optimised inset strategy to place this component@> =
	LOGIF(SPATIAL_MAP, "Component %d (size %d): optimised inset strategy\n",
		sub->allocation_id, sub->bounds.population);
	instance *outer = NULL, *inner = NULL;
	PL::SpatialMap::find_link_to_placed_components(sub, &outer, &inner);
	vector Best_offset =
		Geometry::vec(x_max, box.corner0.y - sub->bounds.corner0.y,
			Room_position(benchmark_room).z - sub->bounds.corner0.z);
	if ((outer) && (inner)) {
		int dx = 0, dy = 0, dz = 0, min_s = FUSION_POINT;
		for (dx = -MAX_OFFSET; dx <= MAX_OFFSET; dx++)
			for (dy = -MAX_OFFSET; dy <= MAX_OFFSET; dy++)
				for (dz = -MAX_OFFSET; dz <= MAX_OFFSET; dz++) {
					if ((dx == 0) && (dy == 0) && (dz == 0)) continue;
					vector Offset =
						Geometry::vec_plus(
							Geometry::vec_minus(Room_position(outer), Room_position(inner)),
							Geometry::vec(dx, dy, dz));
					@<Try this possible offset component position@>;
				}
	}
	PL::SpatialMap::move_component(sub, Best_offset);

@<Try this possible offset component position@> =
	PL::SpatialMap::move_component(sub, Offset);
	int s = PL::SpatialMap::find_component_placement_heat(sub);
	if (s < min_s) {
		min_s = s; Best_offset = Offset;
	}
	PL::SpatialMap::move_component(sub, Geometry::vec_negate(Offset));

@<Sort the components into decreasing order of size@> =
	connected_submap *sub;
	LOOP_OVER(sub, connected_submap) sub->positioned = FALSE;

	int i = 0;
	LOOP_OVER(sub, connected_submap) sorted[i++] = sub;
	qsort(sorted, (size_t) ncom, sizeof(connected_submap *), PL::SpatialMap::compare_components);

@ The following means the components are sorted in descending size order,
but in order of creation within each size; when we get down to the
singletons, we sort by order of creation of the single rooms they
contain.

=
int PL::SpatialMap::compare_components(const void *ent1, const void *ent2) {
	const connected_submap *mc1 = *((const connected_submap **) ent1);
	const connected_submap *mc2 = *((const connected_submap **) ent2);
	int d = mc2->bounds.population - mc1->bounds.population;
	if (d != 0) return d;
	if (mc1->bounds.population == 1) {
		instance *R1 = mc1->first_room_in_submap;
		instance *R2 = mc2->first_room_in_submap;
		if ((R1) && (R2)) { /* which should always happen, but just in case of an error */
			instance *reg1 = Regions::enclosing(R1);
			instance *reg2 = Regions::enclosing(R2);
			if ((reg1) && (reg2 == NULL)) return -1;
			if ((reg1 == NULL) && (reg2)) return 1;
			if (reg1) {
				d = reg1->allocation_id - reg2->allocation_id;
				if (d != 0) return d;
			}
			d = R1->allocation_id - R2->allocation_id;
			if (d != 0) return d;
		}
	}
	return mc1->allocation_id - mc2->allocation_id;
}

@ We should define what we mean by "adjoining" and "isolated". The first
means it has a link (which must be IN or OUT) to an already-positioned
component; the second means it has no link at all to any other component.

=
int PL::SpatialMap::component_is_adjoining(connected_submap *sub) {
	if (PL::SpatialMap::no_links_to_placed_components(sub) > 0) return TRUE;
	return FALSE;
}

int PL::SpatialMap::component_is_isolated(connected_submap *sub) {
	if (PL::SpatialMap::no_links_to_other_components(sub) == 0) return TRUE;
	return FALSE;
}

@ In theory this has $O(R^2)$ running time, but it's very unlikely that there
are $R$ components of size 1, so in practice it's much better than that.

=
int PL::SpatialMap::find_component_placement_heat(connected_submap *sub) {
	connected_submap *other;
	LOOP_OVER(other, connected_submap)
		if (other->positioned) {
			instance *R;
			LOOP_OVER_SUBMAP(R, sub)
				if (PL::SpatialMap::occupied_in_submap(other, Room_position(R)))
					return FUSION_POINT;
		}
	int heat = PL::SpatialMap::find_cross_component_heat(sub);
	if (heat >= FUSION_POINT) heat = FUSION_POINT - 1;
	return heat;
}

@ Where:

=
int PL::SpatialMap::find_cross_component_heat(connected_submap *sub) {
	int heat = 0;
	PL::SpatialMap::cross_component_links(sub, NULL, NULL, &heat, TRUE);
	return heat;
}

void PL::SpatialMap::find_link_to_placed_components(connected_submap *sub,
	instance **outer, instance **inner) {
	PL::SpatialMap::cross_component_links(sub, outer, inner, NULL, TRUE);
}

int PL::SpatialMap::no_links_to_placed_components(connected_submap *sub) {
	return PL::SpatialMap::cross_component_links(sub, NULL, NULL, NULL, TRUE);
}

int PL::SpatialMap::no_links_to_other_components(connected_submap *sub) {
	return PL::SpatialMap::cross_component_links(sub, NULL, NULL, NULL, FALSE);
}

@ So, now we have to define our Swiss-army-knife routine to cope with all
these requirements. We not only count non-lattice connections to other
components (IN and OUT links, basically), but also score how bad they are,
if requested, and record the first we find, if requested.

There can't be any lattice connections to other components, because two
rooms connected that way are by definition in the same component.

=
int PL::SpatialMap::cross_component_links(connected_submap *sub, instance **outer, instance **inner,
	int *heat, int posnd) {
	int no_links = 0;
	if (heat) *heat = 0;
	instance *R;
	LOOP_OVER_SUBMAP(R, sub) {
		int d;
		LOOP_OVER_NONLATTICE_DIRECTIONS(d) {
			instance *R2 = PL::SpatialMap::read_smap_cross(R, d);
			if ((R2) && (MAP_DATA(R2)->submap != sub)) {
				if ((posnd == FALSE) || (MAP_DATA(R2)->submap->positioned)) {
					no_links++;
					if (inner) *inner = R; if (outer) *outer = R2;
					if (heat) *heat = PL::SpatialMap::heat_sum(*heat, PL::SpatialMap::find_cross_link_heat(R, R2, d));
				}
			}
		}
		instance *S;
		LOOP_OVER_ROOMS(S) {
			if (MAP_DATA(S)->submap == sub) continue;
			if ((posnd) && (MAP_DATA(S)->submap->positioned == FALSE)) continue;
			int d;
			LOOP_OVER_NONLATTICE_DIRECTIONS(d) {
				instance *R2 = PL::SpatialMap::read_smap_cross(S, d);
				if ((R2) && (MAP_DATA(R2)->submap == sub)) {
					no_links++;
					if (outer) *outer = S; if (inner) *inner = R2;
					if (heat) *heat = PL::SpatialMap::heat_sum(*heat, PL::SpatialMap::find_cross_link_heat(S, R2, d));
				}
			}
		}
	}
	if (no_links == 0) @<Look for van der Waals forces@>;
	return no_links;
}

@ When there are no map connections or locks, there may still be a very weak
bond between rooms simply because they belong to the same region. We only
look at these weak bonds for singleton regions, for simplicity and to keep
running time in check.

@<Look for van der Waals forces@> =
	if (sub->bounds.population == 1) {
		instance *R = sub->first_room_in_submap;
		if (R) { /* which should always happen, but just in case of an error */
			instance *reg = Regions::enclosing(R);
			if (reg) {
				instance *S, *closest_S = NULL;
				int closest = 0;
				LOOP_OVER_ROOMS(S)
					if ((S != R) && (Regions::enclosing(S) == reg))
						if ((posnd == FALSE) || (MAP_DATA(S)->submap->positioned)) {
							int diff = 2*(R->allocation_id - S->allocation_id);
							if (diff < 0) diff = 1-diff;
							if ((closest_S == NULL) || (diff < closest)) {
								closest = diff; closest_S = S;
							}
						}
				if (closest_S) {
					LOGIF(SPATIAL_MAP, "vdW force between $O and $O\n", R, closest_S);
					no_links++;
					if (outer) *outer = closest_S; if (inner) *inner = R;
					if (heat) *heat = PL::SpatialMap::heat_sum(*heat, PL::SpatialMap::find_cross_link_heat(closest_S, R, 3));
				}
			}
		}
	}

@ "How bad they are" uses another heat-like measure. This one gives an
enormous penalty for being wrong vertically; people just don't like
reading maps where an inside room is displayed on the floor above or below.
It also gives preference to the green jagged arrow directions when placing
insets -- this makes the map line up elegantly.

=
int PL::SpatialMap::find_cross_link_heat(instance *R, instance *S, int dir) {
	if ((R == NULL) || (S == NULL)) internal_error("bad room distance");
	return PL::SpatialMap::component_metric(Room_position(R), Room_position(S), dir);
}

int PL::SpatialMap::component_metric(vector P1, vector P2, int dir) {
	vector D = Geometry::vec_minus(P1, P2);
	int b = 0;
	if ((dir == 10) || (dir == 11)) { /* IN and OUT respectively */
		if (D.x > 0) b++;
		if (D.x < 0) b--;
		if (D.y > 0) b--;
		if (D.y < 0) b++;
		if (dir == 11) b = -b;
		b += 2;
	}
	if (dir == 3) { /* SOUTH, the notional direction for van der Waals forces */
		if (D.y > 0) b++;
		if (D.y < 0) b--;
		b += 2;
	}
	return 2*b + D.x*D.x + D.y*D.y + 100*D.z*D.z;
}

@h Stage 5, bounding the universe.
Short and sweet. We make |Universe| the minimal-sized cuboid containing each room.

@<(5) Find the universal bounding cuboid@> =
	Universe = Geometry::empty_cuboid();
	instance *R;
	LOOP_OVER_ROOMS(R)
		Geometry::adjust_cuboid(&Universe, Room_position(R));

@h Stage 6, removing blank planes.
We need to avoid what might be an infinite loop in awkward cases where
locking means that blank planes are inevitable.

@<(6) Remove any blank lateral planes@> =
	int safety_count = NUMBER_CREATED(instance);
	while (safety_count-- >= 0) {
		int blank_z = 0, blank_plane_found = FALSE;
		int z;
		for (z = Universe.corner1.z - 1; z >= Universe.corner0.z + 1; z--) {
			int occupied = FALSE;
			instance *R;
			LOOP_OVER_ROOMS(R)
				if (Room_position(R).z == z) occupied = TRUE;
			if (occupied == FALSE) {
				blank_z = z;
				blank_plane_found = TRUE;
			}
		}
		if (blank_plane_found == FALSE) break;
		instance *R;
		LOOP_OVER_ROOMS(R)
			if (Room_position(R).z > blank_z)
				PL::SpatialMap::translate_room(R, D_vector);
	}

@h Precis.
It turns out to be useful to test the above algorithm on maps of actual IF
works. But they tend to have large source texts full of irrelevancies to
the spatial layout, so in order to extract the arrangement cleanly, we
can make use of the following:

=
void PL::SpatialMap::log_precis_of_map(void) {
	LOG("[Precis of source text giving map layout follows.]\n\n");
	instance *R;
	LOOP_OVER_INSTANCES(R, K_object) MAP_DATA(R)->zone = 1;
	LOOP_OVER_INSTANCES(R, K_object) {
		@<Declare the regions and doors in the precis@>;
		@<Declare the rooms in the precis, starting with the start room@>;
		MAP_DATA(R)->zone = 0;
	}
	@<Declare the map connections in the precis@>;
	SyntaxTree::traverse(Task::syntax_tree(), PL::SpatialMap::visit_to_transcribe);
	LOG("\n[Precis complete.]\n\n");
}

@<Declare the regions and doors in the precis@> =
	if ((Instances::of_kind(R, K_direction)) &&
		(MAP_DATA(R)->direction_index >= 12)) {
		wording W = Instances::get_name(R, FALSE);
		wording OW = Instances::get_name(Map::get_value_of_opposite_property(R), FALSE);
		LOG("%+W is a direction. The opposite of %+W is %+W.\n", W, W, OW);
	}
	if (Instances::of_kind(R, K_region)) {
		wording W = Instances::get_name(R, FALSE);
		LOG("%+W is a region.\n", W);
	}
	if (Instances::of_kind(R, K_door)) {
		wording W = Instances::get_name(R, FALSE);
		LOG("%+W is a door.\n", W);
		parse_node *S = PropertyInferences::value_of(
			Instances::as_subject(R), P_other_side);
		instance *X = Rvalues::to_object_instance(S);
		if (X) {
			wording XW = Instances::get_name(X, FALSE);
			LOG("The other side of %+W is %+W.\n", W, XW);
		}
	}

@<Declare the rooms in the precis, starting with the start room@> =
	if (Instances::of_kind(R, K_room)) {
		wording RW = Instances::get_name(R, FALSE);
		LOG("%+W is a room.\n", RW);
		instance *reg = Regions::enclosing(R);
		if (reg) {
			wording RGW = Instances::get_name(reg, FALSE);
			if (MAP_DATA(reg)->zone == 1) {
				LOG("%+W is a region.\n", RGW);
				MAP_DATA(reg)->zone = 0;
			}
			LOG("%+W is in %+W.\n", RW, RGW);
		}
		instance *start = Player::get_start_room();
		if (R == start) {
			LOG("The player is in %+W.\n", RW);
		}
	}

@<Declare the map connections in the precis@> =
	instance *R;
	LOOP_OVER_ROOMS(R) {
		wording RW = Instances::get_name(R, FALSE);
		int i;
		LOOP_OVER_STORY_DIRECTIONS(i) {
			instance *D = NULL;
			instance *S = PL::SpatialMap::room_exit(R, i, &D);
			if ((S) || (D)) {
				wording OW = EMPTY_WORDING;
				if (D) OW = Instances::get_name(D, FALSE);
				else OW = Instances::get_name(S, FALSE);
				if (i < 12) {
					char *n = PL::SpatialMap::usual_Inform_direction_name(i);
					int opp = PL::SpatialMap::opposite(i);
					LOG("%+W is %s of %+W.\n", OW, n, RW);
					if ((S) && (PL::SpatialMap::room_exit(S, opp, NULL) == NULL))
						LOG("%s of %+W is nowhere.\n",
							PL::SpatialMap::usual_Inform_direction_name(opp), OW);
				} else {
					instance *dir;
					LOOP_OVER_INSTANCES(dir, K_direction)
						if (MAP_DATA(dir)->direction_index == i) {
							wording DW = Instances::get_name(dir, FALSE);
							LOG("%+W is %W of %+W.\n", OW, DW, RW);
							instance *opp = Map::get_value_of_opposite_property(dir);
							int od = MAP_DATA(opp)->direction_index;
							if ((S) && (PL::SpatialMap::room_exit(S, od, NULL) == NULL)) {
								wording OPW = Instances::get_name(dir, FALSE);
								LOG("%W of %+W is nowhere.\n", OPW, OW);
							}
						}
				}
			}
		}
	}

@ 

@e TRAVERSE_FOR_MAP_INDEX_SMFT

=
void PL::SpatialMap::visit_to_transcribe(parse_node *p) {
	if ((Node::get_type(p) == SENTENCE_NT) && (p->down)) {
		MajorNodes::try_special_meaning(TRAVERSE_FOR_MAP_INDEX_SMFT, p->down);
	}
}

@ Rather similar code is used for details on the World index.

=
void PL::SpatialMap::index_room_connections(OUTPUT_STREAM, instance *R) {
	wording RW = Instances::get_name(R, FALSE); /* name of the origin room */
	instance *dir;
	LOOP_OVER_INSTANCES(dir, K_direction) {
		int i = MAP_DATA(dir)->direction_index;
		instance *opp = Map::get_value_of_opposite_property(dir);
		int od = opp?(MAP_DATA(opp)->direction_index):(-1);
		instance *D = NULL;
		instance *S = PL::SpatialMap::room_exit(R, i, &D);
		if ((S) || (D)) {
			HTML::open_indented_p(OUT, 1, "tight");
			char *icon = "e_arrow";
			if ((S) && (D)) icon = "e_arrow_door";
			else if (D) icon = "e_arrow_door_blocked";
			HTML_TAG_WITH("img", "border=0 src=inform:/map_icons/%s.png", icon);
			WRITE("&nbsp;");
			IXInstances::index_name(OUT, dir);
			WRITE(" to ");
			if (S) {
				IXInstances::index_name(OUT, S);
				if (D) {
					WRITE(" via ");
					IXInstances::index_name(OUT, D);
				}
			} else {
				IXInstances::index_name(OUT, D);
				WRITE(" (a door)");
			}
			if (S) {
				instance *B = opp?(PL::SpatialMap::room_exit(S, od, NULL)):NULL;
				if (B == NULL) {
					WRITE(" (but ");
					IXInstances::index_name(OUT, opp);
					WRITE(" from ");
					IXInstances::index_name(OUT, S);
					WRITE(" is nowhere)");
				} else if (B != R) {
					WRITE(" (but ");
					IXInstances::index_name(OUT, opp);
					WRITE(" from ");
					IXInstances::index_name(OUT, S);
					WRITE(" is ");
					IXInstances::index_name(OUT, B);
					WRITE(")");
				}
			}
			parse_node *at = MAP_DATA(R)->exits_set_at[i];
			if (at) Index::link(OUT, Wordings::first_wn(Node::get_text(at)));
			HTML_CLOSE("p");
		}
	}
	int k = 0;
	LOOP_OVER_INSTANCES(dir, K_direction) {
		int i = MAP_DATA(dir)->direction_index;
		if (PL::SpatialMap::room_exit(R, i, NULL)) continue;
		wording DW = Instances::get_name(dir, FALSE); /* name of the direction */
		k++;
		if (k == 1) {
			HTML::open_indented_p(OUT, 1, "hanging");
			WRITE("<i>add:</i> ");
		} else {
			WRITE("; ");
		}
		TEMPORARY_TEXT(TEMP)
		wchar_t *p = Lexer::word_raw_text(Wordings::first_wn(DW));
		for (int j=0; p[j]; j++) {
			if (j==0) PUT_TO(TEMP, Characters::toupper(p[j]));
			else PUT_TO(TEMP, p[j]);
		}
		if (Wordings::length(DW) > 1)
			WRITE_TO(TEMP, " %+W", Wordings::trim_first_word(DW));
		WRITE_TO(TEMP, " from ");
		if (Wordings::nonempty(RW)) WRITE_TO(TEMP, "%+W", RW);
		else WRITE_TO(TEMP, "here");
		WRITE_TO(TEMP, " is .[=0x000A=]");
		PasteButtons::paste_text(OUT, TEMP);
		DISCARD_TEXT(TEMP)
		WRITE("&nbsp;%+W", DW);
	}
	if (k>0) HTML_CLOSE("p");
}

@h Unit testing.
The internal test case "map" produces a list of spatial coordinates for
rooms:

=
void PL::SpatialMap::log_spatial_layout(void) {
	PL::SpatialMap::establish_benchmark_room();
	PL::EPSMap::traverse_for_map_parameters(1);
	PL::SpatialMap::establish_spatial_coordinates();
	connected_submap *sub;
	LOOP_OVER(sub, connected_submap) {
		LOG("\nMap component %d: "
			"extent (%d...%d, %d...%d, %d...%d): population %d\n",
			sub->allocation_id,
			sub->bounds.corner0.x, sub->bounds.corner1.x,
			sub->bounds.corner0.y, sub->bounds.corner1.y,
			sub->bounds.corner0.z, sub->bounds.corner1.z,
			sub->bounds.population);
		instance *R;
		LOOP_OVER_SUBMAP(R, sub) {
			wording W = Instances::get_name(R, FALSE);
			if (R == benchmark_room) LOG("Benchmark: ");
			LOG("%W: %d, %d, %d\n", W,
				Room_position(R).x,
				Room_position(R).y,
				Room_position(R).z);
		}
	}
}
