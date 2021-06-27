[Geometry::] Spatial Geometry.

To deal with vectors and cuboids in a three-dimensional integer lattice.

@ We will store 3-vectors in the obvious way:

=
typedef struct vector {
	int x, y, z;
} vector;

@ Some useful constant vectors, including those pointing in each direction.
Note that these are not of unit length -- rather, they are the ideal grid
offsets on the map we will eventually draw.

=
vector Zero_vector = {0, 0, 0};

=
vector Geometry::zero(void) {
	return Zero_vector;
}

@

=
vector N_vector = {0, 1, 0};
vector NE_vector = {1, 1, 0};
vector NW_vector = {-1, 1, 0};
vector S_vector = {0, -1, 0};
vector SE_vector = {1, -1, 0};
vector SW_vector = {-1, -1, 0};
vector E_vector = {1, 0, 0};
vector W_vector = {-1, 0, 0};
vector U_vector = {0, 0, 1};
vector D_vector = {0, 0, -1};

@ A cuboid is a volume of space with opposing corners at integer grid
positions which form a tightest-possible bounding box around a finite
number of points (of size |population|); when this is 0, of course, the
corners are meaningless and are by convention at the origin.

=
typedef struct cuboid {
	int population;
	struct vector corner0;
	struct vector corner1;
} cuboid;

@h Vectors.

=
vector Geometry::vec(int x, int y, int z) {
	vector R;
	R.x = x; R.y = y; R.z = z;
	return R;
}

@ A vector is "lateral" if lies in the $x$-$y$ plane.

=
int Geometry::vec_eq(vector U, vector V) {
	if ((U.x == V.x) && (U.y == V.y) && (U.z == V.z)) return TRUE;
	return FALSE;
}

int Geometry::vec_lateral(vector V) {
	if ((V.x == 0) && (V.y == 0)) return FALSE;
	return TRUE;
}

@ The vector space operations:

=
vector Geometry::vec_plus(vector U, vector V) {
	vector R;
	R.x = U.x + V.x; R.y = U.y + V.y; R.z = U.z + V.z;
	return R;
}

vector Geometry::vec_minus(vector U, vector V) {
	vector R;
	R.x = U.x - V.x; R.y = U.y - V.y; R.z = U.z - V.z;
	return R;
}

vector Geometry::vec_negate(vector V) {
	vector R;
	R.x = -V.x; R.y = -V.y; R.z = -V.z;
	return R;
}

vector Geometry::vec_scale(int lambda, vector V) {
	vector R;
	R.x = lambda*V.x; R.y = lambda*V.y; R.z = lambda*V.z;
	return R;
}

@h Lengths.

=
int Geometry::vec_length_squared(vector V) {
	return V.x*V.x + V.y*V.y + V.z*V.z;
}

float Geometry::vec_length(vector V) {
	return (float) (sqrt(Geometry::vec_length_squared(V)));
}

@h Angles.
We compute unit vectors in the D and E directions and then the squared
length of their difference. This is a fairly sharply increasing function of
the absolute value of the angular difference between D and E, and is such
that if the angles are equal then the result is zero; and it's cheap to
compute. So although it might seem nicer to calculate actual angles, this
is better.

=
float Geometry::vec_angular_separation(vector E, vector D) {
	float E_distance = Geometry::vec_length(E);
	float uex = E.x/E_distance, uey = E.y/E_distance, uez = E.z/E_distance;
	float D_distance = Geometry::vec_length(D);
	float udx = D.x/D_distance, udy = D.y/D_distance, udz = D.z/D_distance;
	return (uex-udx)*(uex-udx) + (uey-udy)*(uey-udy) + (uez-udz)*(uez-udz);
}

@h Cuboids.
To form a populated cuboid, first request an empty one, and then adjust it
for each vector to join the population.

=
cuboid Geometry::empty_cuboid(void) {
	cuboid C;
	C.population = 0;
	C.corner0 = Zero_vector; C.corner1 = Zero_vector;
	return C;
}

void Geometry::adjust_cuboid(cuboid *C, vector V) {
	if (C->population++ == 0) {
		C->corner0 = V; C->corner1 = V;
	} else {
		if (V.x < C->corner0.x) C->corner0.x = V.x;
		if (V.x > C->corner1.x) C->corner1.x = V.x;
		if (V.y < C->corner0.y) C->corner0.y = V.y;
		if (V.y > C->corner1.y) C->corner1.y = V.y;
		if (V.z < C->corner0.z) C->corner0.z = V.z;
		if (V.z > C->corner1.z) C->corner1.z = V.z;
	}
}

@ The following expands $C$ minimally so that it contains $X$.

=
void Geometry::merge_cuboid(cuboid *C, cuboid X) {
	if (X.population > 0) {
		if (C->population == 0) {
			*C = X;
		} else {
			Geometry::adjust_cuboid(C, X.corner0);
			Geometry::adjust_cuboid(C, X.corner1);
			C->population += X.population - 2;
		}
	}
}

@ Here we shift an entire cuboid over (assuming all of the points inside
it have made the same shift).

=
void Geometry::cuboid_translate(cuboid *C, vector D) {
	if (C->population > 0) {
		C->corner0 = Geometry::vec_plus(C->corner0, D);
		C->corner1 = Geometry::vec_plus(C->corner1, D);
	}
}

@ =
int Geometry::within_cuboid(vector P, cuboid C) {
	if (C.population == 0) return FALSE;
	if (P.x < C.corner0.x) return FALSE;
	if (P.x > C.corner1.x) return FALSE;
	if (P.y < C.corner0.y) return FALSE;
	if (P.y > C.corner1.y) return FALSE;
	if (P.z < C.corner0.z) return FALSE;
	if (P.z > C.corner1.z) return FALSE;
	return TRUE;
}

@ Suppose we have a one-dimensional array whose entries correspond to the
integer grid positions within a cuboid (including its faces and corners).
The following returns $-1$ if a point is outside the cuboid, or returns
the index if it is.

=
int Geometry::cuboid_index(vector P, cuboid C) {
	if (Geometry::within_cuboid(P, C) == FALSE) return -1;
	vector O = Geometry::vec_minus(P, C.corner0);
	int width  = C.corner1.x - C.corner0.x + 1;
	int height = C.corner1.y - C.corner0.y + 1;
	return O.x + O.y*width + O.z*width*height;
}

int Geometry::cuboid_volume(cuboid C) {
	if (C.population == 0) return 0;
	int width  = C.corner1.x - C.corner0.x + 1;
	int height = C.corner1.y - C.corner0.y + 1;
	int depth  = C.corner1.z - C.corner0.z + 1;
	return width*height*depth;
}

@ Thickening a cuboid is a little more than adjusting; we give it some
extra room. (The result is thus no longer minimally bounding, but we
sacrifice that.)

=
void Geometry::thicken_cuboid(cuboid *C, vector V, vector S) {
	if (C->population++ == 0) {
		C->corner0 = Geometry::vec_minus(V, S);
		C->corner1 = Geometry::vec_plus(V, S);
	} else {
		if (V.x < C->corner0.x) C->corner0.x = V.x - S.x;
		if (V.x > C->corner1.x) C->corner1.x = V.x + S.x;
		if (V.y < C->corner0.y) C->corner0.y = V.y - S.y;
		if (V.y > C->corner1.y) C->corner1.y = V.y + S.y;
		if (V.z < C->corner0.z) C->corner0.z = V.z - S.z;
		if (V.z > C->corner1.z) C->corner1.z = V.z + S.z;
	}
}
