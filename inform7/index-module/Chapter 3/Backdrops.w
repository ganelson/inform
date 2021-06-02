[IXBackdrops::] Backdrops.

Indexing the player's initial position.

@ Since backdrops are contained using different mechanisms, the following
adds backdrop contents to a room called |loc|, or lists backdrops which are
"everywhere" if |loc| is |NULL|.

=
void IXBackdrops::index_object_further(OUTPUT_STREAM, instance *loc, int depth,
	int details, int how) {
	int discoveries = 0;
	instance *bd;
	inference *inf;
	if (loc) {
		LOOP_OVER_BACKDROPS_IN(bd, loc, inf) {
			if (++discoveries == 1) @<Insert fore-matter@>;
			IXPhysicalWorld::index(OUT, bd, NULL, depth+1, details);
		}
	} else {
		LOOP_OVER_BACKDROPS_EVERYWHERE(bd, inf) {
			if (++discoveries == 1) @<Insert fore-matter@>;
			IXPhysicalWorld::index(OUT, bd, NULL, depth+1, details);
		}
	}
	if (discoveries > 0) @<Insert after-matter@>;
}

@<Insert fore-matter@> =
	switch (how) {
		case 1: HTML_OPEN("p");
				WRITE("<b>Present everywhere:</b>"); HTML_TAG("br"); break;
		case 2: HTML_TAG("br"); break;
	}

@<Insert after-matter@> =
	switch (how) {
		case 1: HTML_CLOSE("p"); HTML_TAG("hr"); HTML_OPEN("p"); break;
		case 2: break;
	}

