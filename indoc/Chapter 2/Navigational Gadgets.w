[Gadgets::] Navigational Gadgets.

To render linking gadgets in HTML forms of documentation, so that
the reader can navigate from section to section.

@h Top.
At the front end of a section, before any of its text.

=
void Gadgets::render_navigation_top(OUTPUT_STREAM, volume *V, section *S) {
	if (V->sections[0] == S) @<Render the volume title@>;

	chapter *C = S->begins_which_chapter;
	if (C) @<Render the chapter title@>;

	if (SET_html_for_Inform_application)
		@<Write HTML comments giving the Inform user interface search assistance@>;

	@<Render the section title@>;
}

@<Write HTML comments giving the Inform user interface search assistance@> =
	WRITE("\n");
	TEMPORARY_TEXT(comment);
	WRITE_TO(comment, "SEARCH TITLE \"%S\"", S->unlabelled_title);
	HTML::comment(OUT, comment);
	Str::clear(comment);
	WRITE_TO(comment, "SEARCH SECTION \"%S\"", S->label);
	HTML::comment(OUT, comment);
	Str::clear(comment);
	WRITE_TO(comment, "SEARCH SORT \"%S\"", S->sort_code);
	HTML::comment(OUT, comment);
	DISCARD_TEXT(comment);

@<Render the volume title@> =
	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_volume_title(OUT, V);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_volume_title(OUT, V);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_volume_title(OUT, V);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_volume_title(OUT, V);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_volume_title(OUT, V);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_volume_title(OUT, V);
	}

@<Render the chapter title@> =
	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_chapter_title(OUT, V, C);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_chapter_title(OUT, V, C);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_chapter_title(OUT, V, C);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_chapter_title(OUT, V, C);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_chapter_title(OUT, V, C);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_chapter_title(OUT, V, C);
	}

@<Render the section title@> =
	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_section_title(OUT, V, S);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_section_title(OUT, V, S);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_section_title(OUT, V, S);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_section_title(OUT, V, S);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_section_title(OUT, V, S);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_section_title(OUT, V, S);
	}

@h Index top.
And this is a variant for index pages, such as the index of examples.

=
void Gadgets::render_navigation_index_top(OUTPUT_STREAM, text_stream *filename, text_stream *title) {
	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_navigation_index_top(OUT, filename, title);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_navigation_index_top(OUT, filename, title);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_navigation_index_top(OUT, filename, title);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_navigation_index_top(OUT, filename, title);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_navigation_index_top(OUT, filename, title);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_navigation_index_top(OUT, filename, title);
	}
}

@h Middle.
At the middle part, when the text is over, but before any example cues.

=
void Gadgets::render_navigation_middle(OUTPUT_STREAM, volume *V, section *S) {
	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_navigation_middle(OUT, V, S);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_navigation_middle(OUT, V, S);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_navigation_middle(OUT, V, S);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_navigation_middle(OUT, V, S);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_navigation_middle(OUT, V, S);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_navigation_middle(OUT, V, S);
	}
}

@h Example top.
This is reached before the first example is rendered, provided at least
one example will be:

=
void Gadgets::render_navigation_example_top(OUTPUT_STREAM, volume *V, section *S) {

	if (SET_format == HTML_FORMAT) {
		HTML::begin_div_with_class_S(OUT, I"bookexamples");
		HTML_OPEN_WITH("p", "class=\"chapterheading\"");
	}

	if (SET_examples_granularity == 2) {
		chapter *C = S->in_which_chapter;
		WRITE("Examples from %S", C->chapter_full_title);
	} else if (SET_examples_granularity == 1) {
		WRITE("Examples");
	}

	if (SET_format == HTML_FORMAT) {
		HTML_CLOSE("p");
	} else { WRITE("\n\n"); }

	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_navigation_example_top(OUT, V, S);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_navigation_example_top(OUT, V, S);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_navigation_example_top(OUT, V, S);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_navigation_example_top(OUT, V, S);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_navigation_example_top(OUT, V, S);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_navigation_example_top(OUT, V, S);
	}
}

@h Example bottom.
Any closing ornament at the end of examples? This is reached after the
last example is rendered, provided at least one example has been.

=
void Gadgets::render_navigation_example_bottom(OUTPUT_STREAM, volume *V, section *S) {

	if (SET_format == PLAIN_FORMAT) {
		WRITE("\n\n");
	}

	if (SET_format == HTML_FORMAT) {
		if (SET_examples_mode != EXMODE_open_internal) { HTMLUtilities::ruled_line(OUT); }
		HTML::end_div(OUT);
	}

	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_navigation_example_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_navigation_example_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_navigation_example_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_navigation_example_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_navigation_example_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_navigation_example_bottom(OUT, V, S);
	}
}

@h Bottom.
At the end of the section, after any example cues and perhaps also example
bodied. (In a section with no examples, this immediately follows the middle.)

=
void Gadgets::render_navigation_bottom(OUTPUT_STREAM, volume *V, section *S) {
	if (SET_format == HTML_FORMAT) {
		HTML::comment(OUT, I"START IGNORE");
	}
	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_navigation_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_navigation_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_navigation_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_navigation_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_navigation_bottom(OUT, V, S);
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_navigation_bottom(OUT, V, S);
	}

	if (SET_format == HTML_FORMAT) {
		HTML::comment(OUT, I"END IGNORE");
	}
}

@h Contents page.
Midnight provides a contents page of its very own.

=
void Gadgets::render_navigation_contents_files(void) {
	if (SET_navigation == NAVMODE_midnight) {
		Midnight::midnight_navigation_contents_files();
	} else if (SET_navigation == NAVMODE_architect) {
		Architect::architect_navigation_contents_files();
	} else if (SET_navigation == NAVMODE_twilight) {
		Twilight::twilight_navigation_contents_files();
	} else if (SET_navigation == NAVMODE_roadsign) {
		Roadsign::roadsign_navigation_contents_files();
	} else if (SET_navigation == NAVMODE_unsigned) {
		Unsigned::unsigned_navigation_contents_files();
	} else if (SET_navigation == NAVMODE_lacuna) {
		Lacuna::lacuna_navigation_contents_files();
	}
}
