[StarTemplates::] Star Templates.

Allowing Neptune files to generate additional source text.

@ Each "recorded" invention, a.k.a., "star template", generates one of the following:

=
typedef struct kind_template_definition {
	struct text_stream *template_name; /* including the asterisk, e.g., |"*PRINTING-ROUTINE"| */
	struct text_stream *template_text;
	CLASS_DEFINITION
} kind_template_definition;

kind_template_definition *StarTemplates::new(text_stream *name) {
	kind_template_definition *ttd = CREATE(kind_template_definition);
	ttd->template_name = Str::duplicate(name);
	return ttd;
}

kind_template_definition *StarTemplates::parse_name(text_stream *name) {
	kind_template_definition *ttd;
	LOOP_OVER(ttd, kind_template_definition)
		if (Str::eq(name, ttd->template_name))
			return ttd;
	return NULL;
}

@ Here is the code which records templates, reading them as one line of plain
text at a time. (In the above example, |StarTemplates::record_line| would be
called just once, with the single source text line.)

=
kind_template_definition *current_kind_template = NULL; /* the one now being recorded */

int StarTemplates::recording(void) {
	if (current_kind_template) return TRUE;
	return FALSE;
}

void StarTemplates::begin(text_stream *name, text_file_position *tfp) {
	if (current_kind_template) NeptuneFiles::error(name, I"first stt still recording", tfp);
	if (StarTemplates::parse_name(name))
		NeptuneFiles::error(name, I"duplicate definition of source text template", tfp);
	current_kind_template = StarTemplates::new(name);
	current_kind_template->template_text = StarTemplates::open_spool();
}

void StarTemplates::record_line(text_stream *line, text_file_position *tfp) {
	StarTemplates::record_to_spool(line, tfp);
}

void StarTemplates::end(text_stream *command, text_file_position *tfp) {
	if (current_kind_template == NULL)
		NeptuneFiles::error(command, I"no stt currently recording", tfp);
	else
		StarTemplates::close_spool();
	current_kind_template = NULL;
}

@ So much for recording a template. To "play back", we need to take its text
and squeeze it into the main source text. This happens in two stages: first,
we simply record the user's intention:

=
typedef struct star_invention {
	struct kind_template_definition *template;
	struct kind_constructor *apropos;
	struct text_file_position *origin;
	CLASS_DEFINITION
} star_invention;

void StarTemplates::note(kind_template_definition *ttd, kind_constructor *con,
	text_file_position *tfp) {
	star_invention *I = CREATE(star_invention);
	I->template = ttd;
	I->apropos = con;
	I->origin = tfp;
}

@ Later on, we act on these intentions. Note that a template applied to a
protocol is applied to all of the base kinds conforming to that protocol.
(Inform's standard installation uses this to construct variables of the
"K understood" variety for each understandable kind K.)

=
void StarTemplates::transcribe_all(parse_node_tree *T) {
	star_invention *I;
	LOOP_OVER(I, star_invention) {
		if (I->apropos->group == PROTOCOL_GRP) {
			kind *K;
			LOOP_OVER_BASE_KINDS(K)
				if ((Kinds::Behaviour::definite(K)) &&
					(Kinds::eq(K, K_nil) == FALSE) &&
					(Kinds::eq(K, K_void) == FALSE) &&
					(Kinds::conforms_to(K, Kinds::base_construction(I->apropos))))
					StarTemplates::transcribe(T, I->template, K->construct, I->origin);
		} else {
			StarTemplates::transcribe(T, I->template, I->apropos, I->origin);
		}
	}
}

@ So this applies a single template to a definitely known kind constructor.

=
void StarTemplates::transcribe(parse_node_tree *T,
	kind_template_definition *ttd, kind_constructor *con, text_file_position *tfp) {
	if (ttd == NULL) {
		NeptuneFiles::error(NULL, I"tried to transcribe missing source text template", tfp);
		return;
	}
	#ifdef CORE_MODULE
	if ((FEATURE_INACTIVE(parsing)) &&
		(Str::eq(ttd->template_name, I"*UNDERSTOOD-VARIABLE")))
		return;
	#endif
	text_stream *p = ttd->template_text;
	int i = 0;
	while (Str::get_at(p, i)) {
		if ((Str::get_at(p, i) == '\n') || (Str::get_at(p, i) == ' ')) { i++; continue; }
		TEMPORARY_TEXT(template_line_buffer)
		int terminator = 0;
		@<Transcribe one line of the template into the line buffer@>;
		if (Str::len(template_line_buffer) > 0) {
			wording XW = Feeds::feed_text(template_line_buffer);
			if (terminator != 0) Sentences::make_node(T, XW, terminator);
		}
		DISCARD_TEXT(template_line_buffer)
	}
}

@ Inside template text, anything in angle brackets <...> is a wildcard.
These cannot be nested and cannot include newlines. All other material is
copied verbatim into the line buffer.

The only sentence terminators we recognise are full stop and colon; in
particular we wouldn't recognise a stop inside quoted matter. This does
not matter, since such things never come into kind definitions.

@<Transcribe one line of the template into the line buffer@> =
	while ((Str::get_at(p, i) != 0) && (Str::get_at(p, i) != '\n')) {
		if (Str::get_at(p, i) == '<') {
			TEMPORARY_TEXT(template_wildcard_buffer)
			i++;
			while ((Str::get_at(p, i) != 0) && (Str::get_at(p, i) != '\n') &&
				(Str::get_at(p, i) != '>'))
				PUT_TO(template_wildcard_buffer, Str::get_at(p, i++));
			i++;
			@<Transcribe the template wildcard@>;
			DISCARD_TEXT(template_wildcard_buffer)
		} else PUT_TO(template_line_buffer, Str::get_at(p, i++));
	}
	if (Str::get_last_char(template_line_buffer) == '.') {
		Str::delete_last_character(template_line_buffer); terminator = '.';
	}
	if (Str::get_last_char(template_line_buffer) == ':') {
		Str::delete_last_character(template_line_buffer); terminator = ':';
	}

@ Only five wildcards are recognised:

@<Transcribe the template wildcard@> =
	if (Str::eq_wide_string(template_wildcard_buffer, U"kind"))
		@<Transcribe the kind's name@>
	else if (Str::eq_wide_string(template_wildcard_buffer, U"lower-case-kind"))
		@<Transcribe the kind's name in lower case@>
	else if (Str::eq_wide_string(template_wildcard_buffer, U"say-function"))
		@<Transcribe the kind's I6 printing routine@>
	else if (Str::eq_wide_string(template_wildcard_buffer, U"compare-function"))
		@<Transcribe the kind's I6 comparison routine@>
	else
		NeptuneFiles::error(template_wildcard_buffer,
			I"no such source text template wildcard", tfp);

@<Transcribe the kind's name@> =
	StarTemplates::transcribe_constructor_name(template_line_buffer, con, FALSE);

@<Transcribe the kind's name in lower case@> =
	StarTemplates::transcribe_constructor_name(template_line_buffer, con, TRUE);

@<Transcribe the kind's I6 printing routine@> =
	WRITE_TO(template_line_buffer, "%S", con->print_identifier);

@<Transcribe the kind's I6 comparison routine@> =
	WRITE_TO(template_line_buffer, "%S", con->comparison_routine);

@ Where:

=
void StarTemplates::transcribe_constructor_name(OUTPUT_STREAM, kind_constructor *con,
	int lower_case) {
	wording W = EMPTY_WORDING;
	if (con->dt_tag) W = KindConstructors::get_name(con, FALSE);
	if (Wordings::nonempty(W)) {
		if (KindConstructors::arity(con) > 0) {
			int full_length = Wordings::length(W);
			int i, w1 = Wordings::first_wn(W);
			for (i=0; i<full_length; i++) {
				if (i > 0) PUT(' ');
				vocabulary_entry *ve = Lexer::word(w1+i);
				if (ve == STROKE_V) break;
				if ((ve == CAPITAL_K_V) || (ve == CAPITAL_L_V)) WRITE("value");
				else WRITE("%V", ve);
			}
		} else {
			if (lower_case) WRITE("%+W", W);
			else WRITE("%W", W);
		}
	}
}

@ Large chunks of the text in the template will need to exist permanently in
memory, and we go into recording mode to accept a series of them,
concatenated with newlines dividing them, in a text stream.

=
text_stream *kind_recording = NULL;

@ And here is recording mode:

=
text_stream *StarTemplates::open_spool(void) {
	kind_recording = Str::new();
	return kind_recording;
}

void StarTemplates::record_to_spool(text_stream *line, text_file_position *tfp) {
	if (kind_recording == NULL)
		NeptuneFiles::error(line, I"can't record outside recording", tfp);
	else
		WRITE_TO(kind_recording, "%S\n", line);
}

void StarTemplates::close_spool(void) {
	kind_recording = NULL;
}
