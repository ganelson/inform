[RenderEPSMap::] Render EPS Map.

To render the spatial map of rooms as an EPS (Encapsulated PostScript) file.

@ =
void RenderEPSMap::prepare_universe(inter_tree *I) {
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	@<Create the main EPS map super-level@>;
	for (int z=Universe.corner1.z; z>=Universe.corner0.z; z--)
		@<Create an EPS map level for this z-slice@>;

	FauxInstances::decode_hints(faux_set, I, 2);
	if (changed_global_room_colour == FALSE)
		@<Inherit EPS room colours from those used in the World Index@>;
}

void RenderEPSMap::render_map_as_EPS(filename *F) {
	inter_tree *I = InterpretIndex::get_tree();
	RenderEPSMap::prepare_universe(I);
	@<Open a stream and write the EPS map to it@>;
}

@<Create the main EPS map super-level@> =
	EPS_map_level *main_eml = CREATE(EPS_map_level);
	main_eml->width = ConfigureIndexMap::get_int_mp(I"minimum-map-width", NULL);
	main_eml->actual_height = 0;
	main_eml->titling_point_size = ConfigureIndexMap::get_int_mp(I"title-size", NULL);
	main_eml->titling = Str::new();
	WRITE_TO(main_eml->titling, "Map");
	main_eml->contains_titling = TRUE;
	main_eml->contains_rooms = FALSE;
	ConfigureIndexMap::prepare_map_parameter_scope(&(main_eml->map_parameters));
	ConfigureIndexMap::put_text_mp(I"title", &(main_eml->map_parameters), main_eml->titling);

@<Create an EPS map level for this z-slice@> =
	EPS_map_level *eml = CREATE(EPS_map_level);
	eml->contains_rooms = TRUE;
	eml->map_level = z;

	eml->y_max = -100000, eml->y_min = 100000;
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R)
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

	ConfigureIndexMap::prepare_map_parameter_scope(&(eml->map_parameters));
	ConfigureIndexMap::put_text_mp(I"subtitle", &(eml->map_parameters), eml->titling);

	LOOP_OVER_FAUX_ROOMS(faux_set, R)
		if (Room_position(R).z == z) {
			FauxInstances::get_parameters(R)->wider_scope = &(eml->map_parameters);
		}

@<Inherit EPS room colours from those used in the World Index@> =
	faux_instance *R;
	LOOP_OVER_FAUX_ROOMS(faux_set, R)
		ConfigureIndexMap::put_text_mp(I"room-colour", FauxInstances::get_parameters(R),
			R->fimd.colour);

@<Open a stream and write the EPS map to it@> =
	text_stream EPS_struct; text_stream *EPS = &EPS_struct;
	if (STREAM_OPEN_TO_FILE(EPS, F, ISO_ENC) == FALSE) {
		#ifdef CORE_MODULE
		Problems::fatal_on_file("Can't open index file", F);
		#endif
		#ifndef CORE_MODULE
		Errors::fatal_with_file("can't open index file", F);
		#endif
	}
	RenderEPSMap::EPS_compile_map(EPS);
	STREAM_CLOSE(EPS);

@ =
void RenderEPSMap::EPS_compile_map(OUTPUT_STREAM) {
	int blh, /* total height of the EPS map area (not counting border) */
		blw, /* total width of the EPS map area (not counting border) */
		border = ConfigureIndexMap::get_int_mp(I"border-size", NULL),
		vskip = ConfigureIndexMap::get_int_mp(I"vertical-spacing", NULL);
	faux_instance_set *faux_set = InterpretIndex::get_faux_instances();
	@<Compute the dimensions of the EPS map@>;
	int bounding_box_width = blw+2*border, bounding_box_height = blh+2*border;

	RenderEPSMap::EPS_compile_header(OUT, bounding_box_width, bounding_box_height,
		ConfigureIndexMap::get_text_mp(I"title-font", NULL),
		ConfigureIndexMap::get_int_mp(I"title-size", NULL));

	if (ConfigureIndexMap::get_int_mp(I"map-outline", NULL))
		@<Draw a big rectangular outline around the entire EPS map@>;

	EPS_map_level *eml;
	LOOP_OVER(eml, EPS_map_level) {
		map_parameter_scope *level_scope = &(eml->map_parameters);
		int mapunit = ConfigureIndexMap::get_int_mp(I"grid-size", level_scope);
		if (eml->contains_rooms == FALSE)
			if (ConfigureIndexMap::get_int_mp(I"map-outline", NULL))
				@<Draw an intermediate strut in the big rectangular outline@>;
		if (eml->contains_titling)
			@<Draw the title for this EPS map level@>;
		if (eml->contains_rooms) {
			faux_instance *R;
			LOOP_OVER_FAUX_ROOMS(faux_set, R)
				if (Room_position(R).z == eml->map_level)
					@<Establish EPS coordinates for this room@>;
			LOOP_OVER_FAUX_ROOMS(faux_set, R)
				if (Room_position(R).z == eml->map_level)
					@<Draw the map connections from this room as EPS paths@>;
			LOOP_OVER_FAUX_ROOMS(faux_set, R)
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
		int mapunit = ConfigureIndexMap::get_int_mp(I"grid-size", level_scope);
		int p = ConfigureIndexMap::get_int_mp(I"title-size", level_scope);
		if (eml->contains_rooms) p = ConfigureIndexMap::get_int_mp(I"subtitle-size", level_scope);
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
	RenderEPSMap::EPS_compile_rectangular_path(OUT, border, border, border+blw, border+blh);
	WRITE("stroke\n");

@ ...and then there are horizontal shelves dividing it into compartments.
(Each map level will be drawn inside one of these compartments.)

@<Draw an intermediate strut in the big rectangular outline@> =
	WRITE("newpath %% Ruled horizontal line\n");
	RenderEPSMap::EPS_compile_horizontal_line_path(OUT, border, blw+border, eml->eps_origin);
	WRITE("stroke\n");

@<Draw the title for this EPS map level@> =
	int y = eml->eps_origin + vskip + eml->actual_height;
	if (eml->contains_rooms) {
		if (ConfigureIndexMap::get_int_mp(I"monochrome", level_scope)) RenderEPSMap::EPS_compile_set_greyscale(OUT, 0);
		else RenderEPSMap::EPS_compile_set_colour(OUT, ConfigureIndexMap::get_text_mp(I"subtitle-colour", level_scope));
		RenderEPSMap::plot_stream_at(OUT,
			ConfigureIndexMap::get_text_mp(I"subtitle", level_scope),
			NULL, 128,
			ConfigureIndexMap::get_text_mp(I"subtitle-font", level_scope),
			border*2, y+vskip,
			ConfigureIndexMap::get_int_mp(I"subtitle-size", level_scope),
			FALSE, FALSE);
	} else {
		if (ConfigureIndexMap::get_int_mp(I"monochrome", level_scope)) RenderEPSMap::EPS_compile_set_greyscale(OUT, 0);
		else RenderEPSMap::EPS_compile_set_colour(OUT, ConfigureIndexMap::get_text_mp(I"title-colour", level_scope));
		RenderEPSMap::plot_stream_at(OUT,
			ConfigureIndexMap::get_text_mp(I"title", NULL),
			NULL, 128,
			ConfigureIndexMap::get_text_mp(I"title-font", level_scope),
			border*2, y+2*vskip,
			ConfigureIndexMap::get_int_mp(I"title-size", level_scope),
			FALSE, TRUE);
	}

@<Establish EPS coordinates for this room@> =
	map_parameter_scope *room_scope = FauxInstances::get_parameters(R);
	int bx = Room_position(R).x-Universe.corner0.x;
	int by = Room_position(R).y-eml->y_min;
	int offs = ConfigureIndexMap::get_int_mp(I"room-offset", room_scope);
	int xpart = offs%10000, ypart = offs/10000;
	while (xpart > 5000) xpart-=10000;
	while (xpart < -5000) xpart+=10000;

	bx = (bx)*mapunit + border + mapunit/2;
	by = (by)*mapunit + eml->eps_origin + vskip + mapunit/2;

	bx += xpart*mapunit/100;
	by += ypart*mapunit/100;

	R->fimd.eps_x = bx;
	R->fimd.eps_y = by;

@<Draw the map connections from this room as EPS paths@> =
	map_parameter_scope *room_scope = FauxInstances::get_parameters(R);
	RenderEPSMap::EPS_compile_line_width_setting(OUT, ConfigureIndexMap::get_int_mp(I"route-thickness", room_scope));

	int bx = R->fimd.eps_x;
	int by = R->fimd.eps_y;
	int boxsize = ConfigureIndexMap::get_int_mp(I"room-size", room_scope)/2;
	int R_stiffness = ConfigureIndexMap::get_int_mp(I"route-stiffness", room_scope);
	int dir;
	LOOP_OVER_STORY_DIRECTIONS(dir) {
		faux_instance *T = PL::SpatialMap::room_exit(R, dir, NULL);
		int exit = story_dir_to_page_dir[dir];
		if (FauxInstances::is_a_room(T))
			@<Draw a single map connection as an EPS arrow@>;
	}
	RenderEPSMap::EPS_compile_line_width_unsetting(OUT);

@<Draw a single map connection as an EPS arrow@> =
	int T_stiffness = ConfigureIndexMap::get_int_mp(I"route-stiffness", FauxInstances::get_parameters(T));
	if (ConfigureIndexMap::get_int_mp(I"monochrome", level_scope)) RenderEPSMap::EPS_compile_set_greyscale(OUT, 0);
	else RenderEPSMap::EPS_compile_set_colour(OUT, ConfigureIndexMap::get_text_mp(I"route-colour", level_scope));
	if ((Room_position(T).z == Room_position(R).z) &&
		(PL::SpatialMap::room_exit(T, PL::SpatialMap::opposite(dir), FALSE) == R))
		@<Draw a two-ended arrow for a two-way horizontal connection@>
	else
		@<Draw a one-way arrow for a distant or off-level connection@>;

@ We don't want to draw this twice (once for R, once for T), so we draw it
just for the earlier-defined room.

@<Draw a two-ended arrow for a two-way horizontal connection@> =
	if (R->allocation_id <= T->allocation_id)
		RenderEPSMap::EPS_compile_Bezier_curve(OUT,
			R_stiffness*mapunit, T_stiffness*mapunit,
			bx, by, exit,
			T->fimd.eps_x, T->fimd.eps_y, PL::SpatialMap::opposite(exit));

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
	RenderEPSMap::EPS_compile_dashed_arrow(OUT, boxsize/scaled, E, bx, by);
	RenderEPSMap::plot_text_at(OUT, NULL, T,
		ConfigureIndexMap::get_int_mp(I"annotation-length", NULL),
		ConfigureIndexMap::get_text_mp(I"annotation-font", NULL),
		bx+E.x*boxsize*6/scaled/5, by+E.y*boxsize*6/scaled/5,
		ConfigureIndexMap::get_int_mp(I"annotation-size", NULL),
		TRUE, TRUE);

@<Draw the boxes for the rooms themselves@> =
	map_parameter_scope *room_scope = FauxInstances::get_parameters(R);
	int bx = R->fimd.eps_x;
	int by = R->fimd.eps_y;
	int boxsize = ConfigureIndexMap::get_int_mp(I"room-size", room_scope)/2;
	@<Draw the filled box for the room@>;
	@<Draw the outline of the box for the room@>;
	@<Write in the name of the room@>;

@<Draw the filled box for the room@> =
	WRITE("newpath %% Room interior\n");
	if (ConfigureIndexMap::get_int_mp(I"monochrome", room_scope)) RenderEPSMap::EPS_compile_set_greyscale(OUT, 75);
	else RenderEPSMap::EPS_compile_set_colour(OUT, ConfigureIndexMap::get_text_mp(I"room-colour", room_scope));
	RenderEPSMap::EPS_compile_room_boundary_path(OUT, bx, by, boxsize, ConfigureIndexMap::get_text_mp(I"room-shape", room_scope));
	WRITE("fill\n\n");

@<Draw the outline of the box for the room@> =
	if (ConfigureIndexMap::get_int_mp(I"room-outline", room_scope)) {
		RenderEPSMap::EPS_compile_line_width_setting(OUT, ConfigureIndexMap::get_int_mp(I"room-outline-thickness", room_scope));
		WRITE("newpath %% Room outline\n");
		if (ConfigureIndexMap::get_int_mp(I"monochrome", level_scope)) RenderEPSMap::EPS_compile_set_greyscale(OUT, 0);
		else RenderEPSMap::EPS_compile_set_colour(OUT, ConfigureIndexMap::get_text_mp(I"room-outline-colour", room_scope));
		RenderEPSMap::EPS_compile_room_boundary_path(OUT, bx, by, boxsize, ConfigureIndexMap::get_text_mp(I"room-shape", room_scope));
		WRITE("stroke\n");
		RenderEPSMap::EPS_compile_line_width_unsetting(OUT);
	}

@<Write in the name of the room@> =
	int offs = ConfigureIndexMap::get_int_mp(I"room-name-offset", room_scope);
	int xpart = offs%10000, ypart = offs/10000;
	while (xpart > 5000) xpart-=10000;
	while (xpart < -5000) xpart+=10000;
	bx += xpart*mapunit/100;
	by += ypart*mapunit/100;

	if (ConfigureIndexMap::get_int_mp(I"monochrome", level_scope)) RenderEPSMap::EPS_compile_set_greyscale(OUT, 0);
	else RenderEPSMap::EPS_compile_set_colour(OUT, ConfigureIndexMap::get_text_mp(I"room-name-colour", room_scope));
	text_stream *legend = ConfigureIndexMap::get_text_mp(I"room-name", room_scope);
	faux_instance *room_to_name = NULL;
	if (Str::len(legend) == 0) { room_to_name = R; legend = NULL; }
	RenderEPSMap::plot_text_at(OUT, legend, room_to_name,
		ConfigureIndexMap::get_int_mp(I"room-name-length", room_scope),
		ConfigureIndexMap::get_text_mp(I"room-name-font", room_scope),
		bx, by, ConfigureIndexMap::get_int_mp(I"room-name-size", room_scope),
		TRUE, TRUE);

@<Plot all of the rubrics onto the EPS map@> =
	rubric_holder *rh;
	LOOP_OVER_LINKED_LIST(rh, rubric_holder, faux_set->rubrics) {
		int bx = 0, by = 0;
		int xpart = rh->at_offset%10000, ypart = rh->at_offset/10000;
		int mapunit = ConfigureIndexMap::get_int_mp(I"grid-size", NULL);
		while (xpart > 5000) xpart-=10000;
		while (xpart < -5000) xpart+=10000;
		if (ConfigureIndexMap::get_int_mp(I"monochrome", NULL)) RenderEPSMap::EPS_compile_set_greyscale(OUT, 0);
		else RenderEPSMap::EPS_compile_set_colour(OUT, rh->colour);
		faux_instance *O = rh->offset_from;
		if (O) {
			bx = O->fimd.eps_x;
			by = O->fimd.eps_y;
		}
		bx += xpart*mapunit/100; by += ypart*mapunit/100;
		RenderEPSMap::plot_text_at(OUT, rh->annotation, NULL, 128, rh->font, bx, by, rh->point_size,
			TRUE, TRUE); /* centred both horizontally and vertically */
	}

@h Writing text in EPS.
All of words written on the map -- titles, labels for arrows, rubrics, and so
on -- come from here.

@d MAX_EPS_TEXT_LENGTH 1000
@d MAX_EPS_ABBREVIATED_LENGTH MAX_EPS_TEXT_LENGTH

=
void RenderEPSMap::plot_text_at(OUTPUT_STREAM, text_stream *text_to_plot, faux_instance *I, int abbrev_to,
	text_stream *font, int x, int y, int pointsize, int centre_h, int centre_v) {
	TEMPORARY_TEXT(txt)
	if (text_to_plot) {
		WRITE_TO(txt, "%S", text_to_plot);
	} else if (I) {
		@<Try taking the name from the printed name property of the room@>;
		@<If that fails, try taking the name from its source text name@>;
	} else return;
	RenderEPSMap::plot_stream_at(OUT, txt, I, abbrev_to, font, x, y, pointsize, centre_h, centre_v);
	DISCARD_TEXT(txt)
}

@<Try taking the name from the printed name property of the room@> =
	if (Str::len(I->printed_name) > 0) {
		WRITE_TO(txt, "%S", I->printed_name);
	}

@<If that fails, try taking the name from its source text name@> =
	if (Str::len(txt) == 0) {
		text_stream *N = FauxInstances::get_name(I);
		if (Str::len(N)) return;
		WRITE_TO(txt, "%S", N);
	}

@ =
void RenderEPSMap::plot_stream_at(OUTPUT_STREAM, text_stream *text_to_plot, faux_instance *I, int abbrev_to,
	text_stream *font, int x, int y, int pointsize, int centre_h, int centre_v) {
	TEMPORARY_TEXT(txt)
	Str::copy(txt, text_to_plot);
	@<Abbreviate the text to be printed by stripping dispensable letters@>;
	RenderEPSMap::EPS_compile_text(OUT, txt, x, y, font, pointsize, centre_h, centre_v);
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
void RenderEPSMap::EPS_compile_header(OUTPUT_STREAM, int bounding_box_width, int bounding_box_height,
	text_stream *default_font, int default_point_size) {
	WRITE("%%!PS-Adobe EPSF-3.0\n");
	WRITE("%%%%BoundingBox: 0 0 %d %d\n", bounding_box_width, bounding_box_height);
	WRITE("%%%%IncludeFont: %S\n", default_font);
	WRITE("/%S findfont %d scalefont setfont\n", default_font, default_point_size);
}

@h Circles and rectangles.
In EPS files, there's an imaginary pen which traces out "paths". These begin
whenever the pen moves to a new location, and then continue until they are
closed (joined up back to the start position) with a |closepath| command.

=
void RenderEPSMap::EPS_compile_circular_path(OUTPUT_STREAM, int x0, int y0, int radius) {
	WRITE("%d %d moveto %% rightmost point\n", x0+radius, y0);
	WRITE("%d %d %d %d %d arc %% full circle traced anticlockwise\n",
		x0, y0, radius, 0, 360);
	WRITE("closepath\n");
}

void RenderEPSMap::EPS_compile_rectangular_path(OUTPUT_STREAM, int x0, int y0, int x1, int y1) {
	WRITE("%d %d moveto %% bottom left corner\n", x0, y0);
	WRITE("%d %d lineto %% bottom side\n", x1, y0);
	WRITE("%d %d lineto %% right side\n", x1, y1);
	WRITE("%d %d lineto %% top side\n", x0, y1);
	WRITE("closepath\n");
}

@ The boundary of a room is always one of these:

=
void RenderEPSMap::EPS_compile_room_boundary_path(OUTPUT_STREAM, int bx, int by, int boxsize, text_stream *shape) {
	if (Str::cmp(shape, I"square") == 0)
		RenderEPSMap::EPS_compile_rectangular_path(OUT, bx-boxsize, by-boxsize, bx+boxsize, by+boxsize);
	else if (Str::cmp(shape, I"rectangle") == 0)
		RenderEPSMap::EPS_compile_rectangular_path(OUT, bx-2*boxsize, by-boxsize, bx+2*boxsize, by+boxsize);
	else if (Str::cmp(shape, I"circle") == 0)
		RenderEPSMap::EPS_compile_circular_path(OUT, bx, by, boxsize);
	else
		RenderEPSMap::EPS_compile_rectangular_path(OUT, bx-boxsize, by-boxsize, bx+boxsize, by+boxsize);
}

@h Straight lines.

=
void RenderEPSMap::EPS_compile_horizontal_line_path(OUTPUT_STREAM, int x0, int x1, int y) {
	WRITE("%d %d moveto %% LHS\n", x0, y);
	WRITE("%d %d lineto %% RHS\n", x1, y);
	WRITE("closepath\n");
}

@h Dashed arrows.

=
void RenderEPSMap::EPS_compile_dashed_arrow(OUTPUT_STREAM, int length, vector Dir, int x0, int y0) {
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
void RenderEPSMap::EPS_compile_Bezier_curve(OUTPUT_STREAM, int stiffness0, int stiffness1,
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
void RenderEPSMap::EPS_compile_line_width_setting(OUTPUT_STREAM, int new) {
	WRITE("currentlinewidth %% Push old line width onto stack\n");
	WRITE("%d setlinewidth\n", new);
}

void RenderEPSMap::EPS_compile_line_width_unsetting(OUTPUT_STREAM) {
	WRITE("setlinewidth %% Pull old line width from stack\n");
}

@h Text.
In EPS world, text is just another sort of path.

=
void RenderEPSMap::EPS_compile_text(OUTPUT_STREAM, text_stream *text, int x, int y,
	text_stream *font, int pointsize, int centre_h, int centre_v) {
	WRITE("/%S findfont %d scalefont setfont\n", font, pointsize);
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
void RenderEPSMap::EPS_compile_set_colour(OUTPUT_STREAM, text_stream *htmlcolour) {
	if (Str::len(htmlcolour) != 6) internal_error("Improper HTML colour");
	RenderEPSMap::choose_colour_beam(OUT, Str::get_at(htmlcolour, 0), Str::get_at(htmlcolour, 1));
	RenderEPSMap::choose_colour_beam(OUT, Str::get_at(htmlcolour, 2), Str::get_at(htmlcolour, 3));
	RenderEPSMap::choose_colour_beam(OUT, Str::get_at(htmlcolour, 4), Str::get_at(htmlcolour, 5));
	WRITE("setrgbcolor %% From HTML colour %S\n", htmlcolour);
}

void RenderEPSMap::choose_colour_beam(OUTPUT_STREAM, int hex1, int hex2) {
	int k = RenderEPSMap::hex_to_int(hex1)*16 + RenderEPSMap::hex_to_int(hex2);
	WRITE("%.6g ", (double) (((float) k)/255.0));
}

int RenderEPSMap::hex_to_int(int hex) {
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
void RenderEPSMap::EPS_compile_set_greyscale(OUTPUT_STREAM, int N) {
	WRITE("%0.02f setgray %% greyscale %d/100ths of white\n", (float) N/100, N);
}
