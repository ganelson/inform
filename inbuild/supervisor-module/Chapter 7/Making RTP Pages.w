[RTPPages::] Making RTP Pages.

To turn Markdown source into outcome or run-time-problem pages.

@h Introduction.
This section is descended from an earlier command-line tool, |inrtps|, which
was removed in August 2023. Its purpose was to generate simple HTML pages
which could be displayed inside the Inform GUI apps to explain run-time problems
or other issues to the user. But it was very inflexible, making it difficult to
provide RTPs from kits other than the built-in ones, and it used a notation of
its own. The code below, which is activated from |inbuild| using the |-markdown-*|
command-line switches, uses Markdown instead and is quite flexible in the
services it provides.

@h RTP-flavoured Markdown.
We do not want examples embedded in RTPs, and we do not want level-1 headings
to be interpreted as chapter headings, since we need those for problem titles.

=
markdown_variation *RTP_flavoured_Markdown = NULL;
markdown_variation *RTPPages::RTP_flavoured_Markdown(void) {
	if (RTP_flavoured_Markdown == NULL) {
		RTP_flavoured_Markdown = MarkdownVariations::new(I"RTP-flavoured Markdown");
		MarkdownVariations::copy_features_of(RTP_flavoured_Markdown,
			InformFlavouredMarkdown::variation());
		MarkdownVariations::remove_feature(RTP_flavoured_Markdown,
			DESCRIPTIVE_INFORM_HEADINGS_MARKDOWNFEATURE);	
		MarkdownVariations::remove_feature(RTP_flavoured_Markdown,
			EMBEDDED_EXAMPLES_MARKDOWNFEATURE);	
	}
	return RTP_flavoured_Markdown;
}

@h Models.
Markdown is in practice not enough to make a stand-alone HTML file, since it
renders only to content suitable for the body, and cannot render the head,
any CSS needed, and so on. We therefore generate pages from "models", which
are HTML pages where the place where the content should go is marked as a
placeholder |[CONTENT]|, and so on.

In the standard Inform distribution, the internal resources nest contains a
subdirectory called |HTML|, and that's where we look for models by default.

=
pathname *RTPPages::internal_HTML_path(void) {
	pathname *M = Supervisor::internal()->location;
	return Pathnames::down(M, I"HTML");
}

filename *RTPPages::default_model(void) {
	return Filenames::in(RTPPages::internal_HTML_path(), I"rtp-model.html");
}

@h Making one page.
So, then, |RTPPages::make_one(M, F, T, V)| generates an HTML page from model
|M| using Markdown source in |F|, writing to file |T| and using the dialect
of Markdown indicated by |V|.

Only |F| is mandatory. |M| defaults to the RTP template; |T| defaults to writing
the HTML to the same directory as the source, but with |.html| not |.md| as
the file extension; |V| defaults to RTP-flavoured Markdown.

=
typedef struct RTP_maker_state {
	struct markdown_item *content;
	struct markdown_variation *variation;
	struct text_stream *title;
	struct text_stream *pcode;
	struct text_stream *output_stream;
} RTP_maker_state;

void RTPPages::make_one(filename *model, filename *from, filename *to,
	markdown_variation *variation) {
	if (model == NULL) model = RTPPages::default_model();
	if (variation == NULL) variation = RTPPages::RTP_flavoured_Markdown();
	if (to == NULL) to = Filenames::set_extension(from, I"html");
	if (from == NULL) internal_error("required to have a source filename");
	
	TEMPORARY_TEXT(content)
	if (TextFiles::write_file_contents(content, from) == 0)
		Errors::fatal_with_file("no Markdown source", from);
	Str::trim_white_space(content);

	text_stream *OUT = CREATE(text_stream);
	if (Streams::open_to_file(OUT, to, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("unable to write RTP page file", to);

	RTP_maker_state state;
	state.content = Markdown::parse_extended(content, variation);
	state.variation = variation;
	state.title = Str::new();
	state.pcode = Str::new(); Filenames::write_unextended_leafname(state.pcode, from);
	state.output_stream = OUT;
	if ((state.content->down) && (state.content->down->type == HEADING_MIT) &&
		(Markdown::get_heading_level(state.content->down) == 1)) {
		WRITE_TO(state.title, "%S", state.content->down->stashed);
		state.content->down = state.content->down->next;
	}
	if (Str::eq_insensitive(Filenames::get_leafname(model), I"none")) {
		Markdown::render_extended(OUT, state.content, state.variation);
	} else {
		TextFiles::read(model, FALSE, "unable to read file of model HTML", TRUE,
			&RTPPages::make_helper, NULL, &state);
	}
	
	Streams::close(OUT);
	DISCARD_TEXT(content)
}

void RTPPages::make_helper(text_stream *text, text_file_position *tfp, void *state) {
	RTP_maker_state *ts = (RTP_maker_state *) state;
	text_stream *OUT = ts->output_stream;
	@<Expand the escapes@>;
	WRITE("%S\n", text);
}

@ Inside the model, we recognise certain square-bracketed words as placeholders
which we expand into appropriate material:

@<Expand the escapes@> =
	match_results mr = Regexp::create_mr();
	TEMPORARY_TEXT(source)
	WRITE_TO(source, "%S", text);
	Str::clear(text);

	while (Regexp::match(&mr, source, L"(%c*?)%[(%C+)%](%c*)")) {
		WRITE_TO(text, "%S", mr.exp[0]);
		text_stream *insertion = mr.exp[1];
		@<Insert the insertion@>;
		Str::clear(source);
		WRITE_TO(source, "%S", mr.exp[2]);
	}
	WRITE_TO(text, "%S", source);
	DISCARD_TEXT(source)
	Regexp::dispose_of(&mr);

@ The precursor tool |inrtps| used the awkward notations |*1| to |*5| for
placeholders. |[RTPCODE]| is the new |*1|; |[CONTENT]| is the new |*2|;
|[TITLE]| is the new |*3|; |INFORMCSS| is the new |*5|, and |*4| has been
abolished.

@<Insert the insertion@> =
	if (Str::eq_insensitive(insertion, I"INFORMCSS")) {
		TextFiles::write_file_contents(text, InstalledFiles::filename(CSS_SET_BY_PLATFORM_IRES));
		TextFiles::write_file_contents(text, InstalledFiles::filename(CSS_FOR_STANDARD_PAGES_IRES));
	} else if (Str::eq_insensitive(insertion, I"RTPCODE")) {
		WRITE_TO(text, "%S", ts->pcode);
	} else if (Str::eq_insensitive(insertion, I"CONTENT")) {
		Markdown::render_extended(text, ts->content, ts->variation);
	} else if (Str::eq_insensitive(insertion, I"TITLE")) {
		WRITE_TO(text, "%S", ts->title);
	} else {
		WRITE_TO(text, "[%S]", insertion);
	} 

@h Making a batch of pages.
This works through all Markdown files in a source folder and converts them
into the destination, using a common model. Again, only |from_folder| is
mandatory.

If a file |roster.txt| exists in the source folder, we follow that: see below.
If not, we convert every file whose leafname has the extension |.md| or |.MD|.

=
void RTPPages::work_through_directory(filename *model, pathname *from_folder,
	pathname *to_folder, markdown_variation *variation) {
	if (from_folder == NULL) internal_error("no directory given to read from");
	if (to_folder == NULL) to_folder = from_folder;
	filename *roster = Filenames::in(from_folder, I"roster.txt");
	if (TextFiles::exists(roster)) {
		RTPPages::work_through_roster(roster, NULL, from_folder, to_folder, variation);
	} else {
		int counter = 0;
		if (to_folder == NULL) to_folder = from_folder;
		linked_list *L = Directories::listing(from_folder);
		text_stream *entry;
		LOOP_OVER_LINKED_LIST(entry, text_stream, L) {
			if (Platform::is_folder_separator(Str::get_last_char(entry)) == FALSE) {
				if ((Str::ends_with(entry, I".md")) || (Str::ends_with(entry, I".MD"))) {
					filename *from = Filenames::in(from_folder, entry);
					filename *to = Filenames::in(to_folder, entry);
					to = Filenames::set_extension(to, I"html");
					RTPPages::make_one(model, from, to, variation);
					counter++;
				}
			}
		}
		PRINT("%d stand-alone page(s) written (%p -> %p)\n", counter, from_folder, to_folder);
	}
}

@h Making a batch from a roster.
This is called by the above, but can also be called directly. Once again,
only |from_folder| is mandatory.

=
typedef struct RTP_roster_state {
	struct pathname *source_folder;
	struct pathname *destination_folder;
	struct pathname *models_folder;
	struct markdown_variation *variation;
	int counter;
} RTP_roster_state;

void RTPPages::work_through_roster(filename *roster, pathname *models_folder,
	pathname *from_folder, pathname *to_folder, markdown_variation *variation) {
	if (from_folder == NULL) internal_error("no directory given to read from");
	if (models_folder == NULL) models_folder = RTPPages::internal_HTML_path();
	if (to_folder == NULL) to_folder = from_folder;
	if (roster == NULL) roster = Filenames::in(from_folder, I"roster.txt");
	RTP_roster_state state;
	state.source_folder = from_folder;
	state.destination_folder = to_folder;
	state.models_folder = models_folder;
	state.variation = variation;
	state.counter = 0;
	TextFiles::read(roster, FALSE, "unable to read roster file", TRUE,
		&RTPPages::roster_helper, NULL, &state);
	PRINT("%d stand-alone page(s) written (following %f)\n", state.counter, roster);
}

@ Thus, the following is called on each line in turn of the roster file. In
a roster file, leading and trailing white space is removed. Blank lines are
ignored, and lines beginning with |!| are ignored as comments. All other
lines are commands to make one HTML page.

The line |> TOKEN| means "convert |TOKEN.md| in the source folder into
|TOKEN.html| in the destination folder, using the default model". |TOKEN|
must not contain spaces.

The line |> MODEL: TOKEN| means "convert |TOKEN.md| in the source folder into
|TOKEN.html| in the destination folder, using |MODEL| as model". |MODEL|
should be a leafname in the models directory.

Finally, |> MODEL: FROM --> TO| means the same, except that the Markdown
is read from |FROM.md| and written to |TO.html|. |FROM| and |TO| must not
contain spaces.

=
void RTPPages::roster_helper(text_stream *text, text_file_position *tfp, void *state) {
	RTP_roster_state *roster_state = (RTP_roster_state *) state;
	
	if (Str::is_whitespace(text)) return;
	Str::trim_white_space(text);
	if (Str::get_first_char(text) == '!') return;

	match_results mr = Regexp::create_mr();
	text_stream *token = NULL, *equivalent = NULL, *model = NULL;
	if (Regexp::match(&mr, text, L"> *(%c*?) *: *(%C+) *--> *(%C+)")) {
		model = mr.exp[0]; token = mr.exp[2]; equivalent = mr.exp[1];
		@<Act on roster item@>;
	} else if (Regexp::match(&mr, text, L"> *(%c+?) *: *(%C+)")) {
		model = mr.exp[0]; token = mr.exp[1]; equivalent = token;
		@<Act on roster item@>;
	} else if (Regexp::match(&mr, text, L"> *(%C+)")) {
		model = NULL; token = mr.exp[0]; equivalent = token;
		@<Act on roster item@>;
	} else {
		TEMPORARY_TEXT(err)
		WRITE_TO(err, "Line not recognised in page roster file: '%S'", text);
		Errors::in_text_file_S(err, tfp);
	}
	Regexp::dispose_of(&mr);
}

@<Act on roster item@> =
	TEMPORARY_TEXT(leaf)
	WRITE_TO(leaf, "%S.html", token);
	filename *to = Filenames::in(roster_state->destination_folder, leaf);
	DISCARD_TEXT(leaf)

	TEMPORARY_TEXT(md_leaf)
	WRITE_TO(md_leaf, "%S.md", equivalent);
	filename *MD = Filenames::in(roster_state->source_folder, md_leaf);
	DISCARD_TEXT(md_leaf)
	
	filename *model_to_follow = Filenames::in(roster_state->models_folder, model);
	
	RTPPages::make_one(model_to_follow, MD, to, roster_state->variation);
	roster_state->counter++;
