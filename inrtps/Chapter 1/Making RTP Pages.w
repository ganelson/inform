[Translator::] Making RTP Pages.

To translate the text in one folder into RTP pages in another.

@h The translator.

=
typedef struct translator_state {
	struct text_stream *current_text;
	struct text_stream *current_code;
	struct text_stream *current_title;
	struct text_stream *current_pcode;
	struct text_stream *font;
	struct filename *model_to_follow;
	struct pathname *destination_folder;
	struct text_stream *write_to;
	int counter;
} translator_state;

void Translator::go(pathname *from_folder, pathname *to_folder, text_stream *font_setting) {
	filename *texts = Filenames::in_folder(from_folder, I"texts.txt");
	translator_state ts;
	ts.current_text = Str::new();
	ts.current_code = Str::new();
	ts.current_title = Str::new();
	ts.current_pcode = Str::new();
	ts.destination_folder = to_folder;
	ts.model_to_follow = NULL;
	ts.font = font_setting;
	ts.counter = 0;
	TextFiles::read(texts, FALSE, "unable to read file of source text", TRUE,
		&Translator::go_helper, NULL, &ts);
	Translator::flush(&ts);
	PRINT("%d problem texts written\n", ts.counter);
}

void Translator::go_helper(text_stream *text, text_file_position *tfp, void *state) {
	translator_state *ts = (translator_state *) state;
	match_results mr = Regexp::create_mr(), mr2 = Regexp::create_mr();

	if (Regexp::match(&mr, text, L"--> *(%C+) *- *(%c*?) *")) {
		Translator::flush(ts);
		Str::clear(ts->current_text);
		Str::copy(ts->current_pcode, mr.exp[0]);
		Str::copy(ts->current_title, mr.exp[1]);
		if (Regexp::match(&mr2, ts->current_pcode, L"P%d+")) {
			Str::clear(ts->current_code);
			WRITE_TO(ts->current_code, "RTP_%S", ts->current_pcode);
		}
		else
			Str::copy(ts->current_code, ts->current_pcode);
	} else if (Regexp::match(&mr, text, L" *")) {
		;
	} else if (Regexp::match(&mr, text, L" *model *= *(%c*?) *")) {
		ts->model_to_follow = Filenames::in_folder(from_folder, mr.exp[0]);
	} else {
		WRITE_TO(ts->current_text, "%S", text);
	}

	Regexp::dispose_of(&mr);
	Regexp::dispose_of(&mr2);
}

@ This is where files are written:

=
void Translator::flush(translator_state *ts) {
	if (Str::len(ts->current_code) > 0) {
		@<Give any material in double-quotes a blue tint@>;
		TEMPORARY_TEXT(leaf);
		WRITE_TO(leaf, "%S.html", ts->current_code);
		filename *F = Filenames::in_folder(ts->destination_folder, leaf);
		DISCARD_TEXT(leaf);
		ts->write_to = CREATE(text_stream);
		if (Streams::open_to_file(ts->write_to, F, UTF8_ENC) == FALSE)
			Errors::fatal_with_file("unable to write RTP page file", F);
		TextFiles::read(ts->model_to_follow, FALSE, "unable to read file of model HTML", TRUE,
			&Translator::flush_helper, NULL, ts);
		Streams::close(ts->write_to);
		ts->counter++;
	}
}

@<Give any material in double-quotes a blue tint@> =
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, ts->current_text, L"(%c*?)\"(%c*?)\"(%c*)")) {
		Str::clear(ts->current_text);
		WRITE_TO(ts->current_text, "%S<font color=_QUOTE_#000080_QUOTE_><b>%S</b></font>%S",
			mr.exp[0], mr.exp[1], mr.exp[2]);
	}
	while (Regexp::match(&mr, ts->current_text, L"(%c*?)_QUOTE_(%c*)")) {
		Str::clear(ts->current_text);
		WRITE_TO(ts->current_text, "%S\"%S",
			mr.exp[0], mr.exp[1]);
	}
	Regexp::dispose_of(&mr);

@ =
void Translator::flush_helper(text_stream *text, text_file_position *tfp, void *state) {
	translator_state *ts = (translator_state *) state;
	@<Expand the asterisked escapes@>;
	WRITE_TO(ts->write_to, "%S\n", text);
}

@<Expand the asterisked escapes@> =
	match_results mr = Regexp::create_mr();

	while (Regexp::match(&mr, text, L"(%c*?)%*1(%c*)")) {
		Str::clear(text);
		WRITE_TO(text, "%S%S%S", mr.exp[0], ts->current_pcode, mr.exp[1]);
	}
	while (Regexp::match(&mr, text, L"(%c*?)%*2(%c*)")) {
		Str::clear(text);
		WRITE_TO(text, "%S%S%S", mr.exp[0], ts->current_text, mr.exp[1]);
	}
	while (Regexp::match(&mr, text, L"(%c*?)%*3(%c*)")) {
		Str::clear(text);
		WRITE_TO(text, "%S%S%S", mr.exp[0], ts->current_title, mr.exp[1]);
	}
	while (Regexp::match(&mr, text, L"(%c*?)%*4(%c*)")) {
		Str::clear(text);
		WRITE_TO(text, "%S%S%S", mr.exp[0], ts->font, mr.exp[1]);
	}
	Regexp::dispose_of(&mr);
