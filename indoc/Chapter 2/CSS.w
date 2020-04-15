[CSS::] CSS.

Cascading style sheets for HTML output.

@h Definitions.

@ The whole idea of a CSS file is to provide styling independent from content,
and since |indoc| generates content, it shouldn't meddle with CSS files at
all. It does so for two reasons:

(a) Because the CSS may refer to background images, by URL, and these URLs
depend on the website structure, which may vary according to the instructions
and target chosen. So |indoc| needs to correct such URLs on the fly. What it
does is to replace the word |IMAGES/| with the correct relative path, and this
also means that the image name is flagged as one that will be needed by the
resulting website.

(b) Because the instructions have requested one or more changes, or "tweaks",
to the CSS to be used on a given volume or volumes. Such instructions are
kept in the following hashes:

=
typedef struct CSS_tweak_data {
	struct text_stream *css_style; /* the CSS style name to tweak */
	struct text_stream *css_tweak; /* the instruction */
	int css_tweaked; /* has this instruction happened yet? */
	int css_plus; /* 1 for "augment this style", 0 for "replace this style" */
	int css_to_be_added;
	struct volume *within_volume;
	MEMORY_MANAGEMENT
} CSS_tweak_data;

@ Span notations allow markup such as |this is *dreadful*| to represent
emphasis; and are also used to mark headwords for indexing, as in
|this is ^{nifty}|.

@d MAX_PATTERN_LENGTH 1024

@d MARKUP_SPP 1
@d INDEX_TEXT_SPP 2
@d INDEX_SYMBOLS_SPP 3

=
typedef struct span_notation {
	int sp_purpose;							/* one of the |*_SPP| constants */
	wchar_t sp_left[MAX_PATTERN_LENGTH]; 	/* wide C string: the start pattern */
	int sp_left_len;
	wchar_t sp_right[MAX_PATTERN_LENGTH];	/* wide C string: and end pattern */
	int sp_right_len;
	struct text_stream *sp_style;
	MEMORY_MANAGEMENT
} span_notation;

@h Requesting CSS tweaks.
The null volume means "in all volumes".

=
void CSS::request_css_tweak(volume *V, text_stream *style, text_stream *want, int plus) {
	if (V == NULL) {
		LOOP_OVER(V, volume)
			CSS::request_css_tweak(V, style, want, plus);
	} else {
		CSS_tweak_data *TD = CREATE(CSS_tweak_data);
		TD->css_style = Str::duplicate(style);
		TD->css_tweak = Str::duplicate(want);
		TD->css_tweaked = FALSE;
		TD->css_plus = 1;
		TD->css_to_be_added = FALSE;
		TD->within_volume = V;
		if (plus == 2) TD->css_to_be_added = TRUE;
	}
}

@h Constructing CSS files.
There's one CSS file for each volume.

=
void CSS::write_CSS_files(filename *from) {
	volume *V;
	LOOP_OVER(V, volume) {
		TEMPORARY_TEXT(leafname);
		WRITE_TO(leafname, "indoc");
		if (no_volumes > 1) WRITE_TO(leafname, "_%S", V->vol_abbrev);
		WRITE_TO(leafname, ".css");
		V->vol_CSS_leafname = Str::duplicate(leafname);
		filename *F = Filenames::in(indoc_settings->destination, leafname);

		text_stream CSS_struct;
		text_stream *OUT = &CSS_struct;
		if (Streams::open_to_file(OUT, F, UTF8_ENC) == FALSE)
			Errors::fatal_with_file("can't write CSS file", F);
		if (indoc_settings->verbose_mode) PRINT("[Writing %/f]\n", F);

		@<Construct the CSS for this volume@>;
		@<Add any missing CSS material to this volume@>;
		Streams::close(OUT);
	}
	@<Check that all of the tweaks have had an effect@>;
}

@<Construct the CSS for this volume@> =
	CSS_helper_state chs;
	chs.tx_mode = FALSE;
	chs.this_style = Str::new();
	chs.this_style_tweaked = FALSE;
	chs.V = V;
	chs.OUT = OUT;
	TextFiles::read(from, FALSE, "can't open CSS file model",
		TRUE, CSS::construct_helper, NULL, &chs);

@ =
typedef struct CSS_helper_state {
	int tx_mode;
	struct text_stream *this_style;
	int this_style_tweaked;
	struct volume *V;
	struct text_stream *OUT;
} CSS_helper_state;

void CSS::construct_helper(text_stream *line, text_file_position *tfp,
	void *v_chs) {
	CSS_helper_state *chs = (CSS_helper_state *) v_chs;
	text_stream *OUT = chs->OUT;
	Str::trim_white_space_at_end(line);
	if (chs->tx_mode) {
		@<Apply CSS modifications requested by the instructions@>;
		CSS::expand_IMAGES(line);
		WRITE("%S\n", line);
	} else {
		if (Regexp::match(NULL, line, L"%c*BEGIN%c*")) chs->tx_mode = TRUE;
	}
}

@ We detect the style opening and closing in a way which wouldn't work for
all CSS files, but here we know that |base.css| is tidily written.

@<Apply CSS modifications requested by the instructions@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, line, L"(%c*?) *{"))
		Str::copy(chs->this_style, mr.exp[0]);
	else if (Regexp::match(&mr, line, L" *}")) {
		Str::clear(chs->this_style); chs->this_style_tweaked = 0;
	} else {
		CSS_tweak_data *TD;
		LOOP_OVER(TD, CSS_tweak_data) {
			if ((Str::eq(TD->css_style, chs->this_style)) && (TD->within_volume == chs->V)) {
				if (chs->this_style_tweaked == FALSE) @<Add the new CSS lines supplied@>;
				@<Decide whether to keep the original CSS line@>;
			}
		}
	}
	Regexp::dispose_of(&mr);

@<Add the new CSS lines supplied@> =
	TEMPORARY_TEXT(want);
	Str::copy(want, TD->css_tweak);
	CSS::expand_IMAGES(want);
	WRITE("%S", want);
	DISCARD_TEXT(want);
	chs->this_style_tweaked = TRUE;
	TD->css_tweaked = TRUE;
	if (TD->css_plus > 0)
		CSS::alert_CSS_change(I"Augmenting", chs->this_style, chs->V);
	else
		CSS::alert_CSS_change(I"Replacing", chs->this_style, chs->V);

@<Decide whether to keep the original CSS line@> =
	int keep = FALSE;
	if (TD->css_plus > 0) {
		keep = TRUE;
		match_results mr2 = Regexp::create_mr();
		if (Regexp::match(&mr2, line, L" *(%C+):%c*")) {
			text_stream *tag = mr2.exp[0];
			if (Str::includes(TD->css_tweak, tag)) keep = FALSE;
		}
		Regexp::dispose_of(&mr2);
	}
	if (keep == FALSE) { Regexp::dispose_of(&mr); return; }

@<Add any missing CSS material to this volume@> =
	CSS_tweak_data *TD;
	LOOP_OVER(TD, CSS_tweak_data) {
		if ((TD->within_volume == V) && (TD->css_tweaked == FALSE) && (TD->css_to_be_added)) {
			text_stream *tag = TD->css_style;
			CSS::alert_CSS_change(I"Adding", tag, V);
			WRITE("%S {\n", tag);
			TEMPORARY_TEXT(expanded);
			Str::copy(expanded, TD->css_tweak);
			CSS::expand_IMAGES(expanded);
			WRITE("%S}\n", expanded);
			TD->css_tweaked = TRUE;
		}
	}

@<Check that all of the tweaks have had an effect@> =
	CSS_tweak_data *TD;
	LOOP_OVER(TD, CSS_tweak_data) {
		if ((TD->within_volume == V) && (TD->css_tweaked == FALSE)) {
			text_stream *tag = TD->css_style;
			TEMPORARY_TEXT(err);
			WRITE_TO(err, "CSS modification had no effect: failed to ");
			if (TD->css_plus > 0) WRITE_TO(err, "augment");
			else WRITE_TO(err, "replace");
			WRITE_TO(err, " the style \"%S\"", tag);
			Errors::in_text_file_S(err, NULL);
			DISCARD_TEXT(err);
		}
	}

@ =
void CSS::expand_IMAGES(text_stream *text) {
	match_results mr = Regexp::create_mr();
	if (indoc_settings->suppress_fonts) {
		while (Regexp::match(&mr, text, L"(%c*?)font-family:(%c*?);(%c*)")) {
			text_stream *L = mr.exp[0], *M = NULL, *R = mr.exp[2];
			if (Regexp::match(NULL, mr.exp[1], L"%c*monospace%c*")) M = I"___MONOSPACE___";
			Str::clear(text);
			WRITE_TO(text, "%S%S%S", L, M, R);
		}
		Regexp::replace(text, L"___MONOSPACE___", L"font-family: monospace;", REP_REPEATING);
	}
	while (Regexp::match(&mr, text, L"(%c*?)'IMAGES/(%c*?)'(%c*)")) {
		text_stream *L = mr.exp[0], *name = mr.exp[1], *R = mr.exp[2];
		Str::clear(text);
		WRITE_TO(text, "%S'", L);
		HTMLUtilities::image_URL(text, name);
		WRITE_TO(text, "'%S", R);
	}
	Regexp::dispose_of(&mr);
}

@h Verbosity.

=
void CSS::alert_CSS_change(text_stream *what, text_stream *this_style, volume *V) {
	if (indoc_settings->verbose_mode)
		PRINT("%S CSS style \"%S\" in volume \"%S\"\n", what, this_style, V->vol_title);
}

@h Span notations.

=
void CSS::add_span_notation(text_stream *L, text_stream *R, text_stream *style, int purpose) {
	span_notation *SN = CREATE(span_notation);
	SN->sp_style = Str::duplicate(style);
	Str::copy_to_wide_string(SN->sp_left, L, MAX_PATTERN_LENGTH);
	Str::copy_to_wide_string(SN->sp_right, R, MAX_PATTERN_LENGTH);
	SN->sp_left_len = Str::len(L);
	SN->sp_right_len = Str::len(R);
	SN->sp_purpose = purpose;
}

@ We have to escape any characters which might be special to our regular
expression parser:

=
void CSS::make_regex_safe(text_stream *text) {
	Regexp::replace(text, L"%%", L"%%%", REP_REPEATING);
	Regexp::replace(text, L"%(", L"%%(", REP_REPEATING);
	Regexp::replace(text, L"%)", L"%%)", REP_REPEATING);
	Regexp::replace(text, L"%+", L"%%+", REP_REPEATING);
	Regexp::replace(text, L"%*", L"%%*", REP_REPEATING);
	Regexp::replace(text, L"%?", L"%%?", REP_REPEATING);
	Regexp::replace(text, L"%[", L"%%[", REP_REPEATING);
	Regexp::replace(text, L"%]", L"%%]", REP_REPEATING);
}

@ The following looks slow, but in fact there's no problem in practice.

=
void CSS::expand_spannotations(text_stream *text, int purpose) {
	TEMPORARY_TEXT(modified);
	int changes = 0;
	for (int i=0, L = Str::len(text); i<L; i++) {
		int claimed = FALSE;
		span_notation *SN;
		LOOP_OVER(SN, span_notation)
			if (SN->sp_purpose == purpose) {
				if (Str::includes_wide_string_at(text, SN->sp_left, i)) {
					if (changes++ == 0)
						for (int j=0; j<i; j++) PUT_TO(modified, Str::get_at(text, j));
					int content_from = i + SN->sp_left_len, content_to = -1;
					for (int k2 = content_from; k2<L; k2++)
						if (Str::includes_wide_string_at(text, SN->sp_right, k2)) {
							 content_to = k2; break;
						}
					if (content_to >= 0) {
						WRITE_TO(modified, "___mu___%S___mo___", SN->sp_style);
						for (int j=content_from; j<content_to; j++)
							PUT_TO(modified, Str::get_at(text, j));
						WRITE_TO(modified, "___mc___");
						i = content_to + SN->sp_right_len - 1;
					} else {
						PUT_TO(modified, Str::get_at(text, i));
					}
					claimed = TRUE;
				}
			}
		if ((changes > 0) && (claimed == FALSE))
			PUT_TO(modified, Str::get_at(text, i));
	}
	if (changes > 0) Str::copy(text, modified);
	DISCARD_TEXT(modified);
}
