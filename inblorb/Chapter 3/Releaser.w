[Requests::] Releaser.

To manage requests to release material other than a Blorb file.

@h Requests.
If the previous chapter, which wrote blorb files, was the Lord High Executioner,
then this one is the Lord High Everything Else: it keeps track of requests
to write all kinds of interesting things which are not blorb files,
and then sees that they are carried out. The requests divide as follows:

@e COPY_REQ from 0 /* a miscellaneous file */
@e IFICTION_REQ /* the iFiction record of a project */
@e RELEASE_FILE_REQ /* a template file */
@e RELEASE_SOURCE_REQ /* the source text in HTML form */
@e SOLUTION_REQ /* a solution file generated from the skein */
@e SOURCE_REQ /* the source text of a project */
@e WEBSITE_REQ /* a whole website */
@e INTERPRETER_REQ /* an in-browser interpreter */
@e BASE64_REQ /* a base64-encoded copy of a binary file */
@e INSTRUCTION_REQ /* a release instruction copied to inblorb for reporting only */
@e ALTERNATIVE_REQ /* an unused release instruction copied to inblorb for reporting only */

=
int website_requested = FALSE; /* has a |WEBSITE_REQ| been made? */

@ Each request produces an instance of:

=
typedef struct request {
	int what_is_requested; /* one of the |*_REQ| values above */
	struct text_stream *details1;
	struct text_stream *details2;
	struct text_stream *details3;
	int private; /* is this request private, i.e., not to contribute to a website? */
	int outcome_data; /* e.g. number of bytes copied */
	MEMORY_MANAGEMENT
} request;

@h Receiving requests.
These can have from 0 to 3 textual details attached:

=
request *Requests::request_0(int kind, int privacy) {
	request *req = CREATE(request);
	req->what_is_requested = kind;
	req->details1 = Str::new();
	req->details2 = Str::new();
	req->details3 = Str::new();
	req->private = privacy;
	req->outcome_data = 0;
	if (kind == WEBSITE_REQ) website_requested = TRUE;
	return req;
}

request *Requests::request_1(int kind, text_stream *text1, int privacy) {
	request *req = Requests::request_0(kind, privacy);
	Str::copy(req->details1, text1);
	return req;
}

request *Requests::request_2(int kind, text_stream *text1, text_stream *text2, int privacy) {
	request *req = Requests::request_0(kind, privacy);
	Str::copy(req->details1, text1);
	Str::copy(req->details2, text2);
	return req;
}

request *Requests::request_3(int kind, text_stream *text1, text_stream *text2, text_stream *text3, int privacy) {
	request *req = Requests::request_0(kind, privacy);
	Str::copy(req->details1, text1);
	Str::copy(req->details2, text2);
	Str::copy(req->details3, text3);
	return req;
}

@ A convenient abbreviation:

=
void Requests::request_copy(text_stream *from, text_stream *to, text_stream *subfolder) {
	Requests::request_3(COPY_REQ, from, to, subfolder, FALSE);
}

@h Any Last Requests.
Most of the requests are made as the parser reads commands from the blurb
script. At the end of that process, though, the following routine may add
further requests as consequences:

=
void Requests::any_last_requests(void) {
	Links::request_copy_of_auxiliaries();
	if (default_cover_used == FALSE) {
		text_stream *BIGCOVER = Placeholders::read(I"BIGCOVER");
		if (Str::len(BIGCOVER) > 0) {
			if (cover_is_in_JPEG_format)
				Requests::request_copy(BIGCOVER, I"Cover.jpg", I"--");
			else
				Requests::request_copy(BIGCOVER, I"Cover.png", I"--");
		}
		if (website_requested) {
			text_stream *SMALLCOVER = Placeholders::read(I"SMALLCOVER");
			if (Str::len(SMALLCOVER) > 0) {
				if (cover_is_in_JPEG_format)
					Requests::request_copy(SMALLCOVER, I"Small Cover.jpg", I"--");
				else
					Requests::request_copy(SMALLCOVER, I"Small Cover.png", I"--");
			}
		}
	}
}

@h Carrying out requests.

=
void Requests::create_requested_material(void) {
	if (release_folder == NULL) return;
	PRINT("! Release folder: <%p>\n", release_folder);
	if (blorb_file_size > 0) Requests::declare_where_blorb_should_be_copied(release_folder);
	Requests::any_last_requests();
	request *req;
	LOOP_OVER(req, request) {
		switch (req->what_is_requested) {
			case ALTERNATIVE_REQ: break;
			case BASE64_REQ: @<Copy a base64-encoded file across@>; break;
			case COPY_REQ: @<Copy a file into the release folder@>; break;
			case IFICTION_REQ: @<Create an iFiction file@>; break;
			case INSTRUCTION_REQ: break;
			case INTERPRETER_REQ: @<Create an in-browser interpreter@>; break;
			case RELEASE_FILE_REQ: @<Release a file into the release folder@>; break;
			case RELEASE_SOURCE_REQ: @<Release source text as HTML into the release folder@>; break;
			case SOLUTION_REQ: @<Create a Solution::walkthrough file@>; break;
			case SOURCE_REQ: @<Create a plain text source file@>; break;
			case WEBSITE_REQ: @<Create a website@>; break;
		}
	}
}

@<Create a Solution::walkthrough file@> =
	filename *Skein_filename = Filenames::in_folder(project_folder, I"Skein.skein");
	filename *solution_filename = Filenames::in_folder(release_folder, I"solution.txt");
	Solution::walkthrough(Skein_filename, solution_filename);

@<Create a plain text source file@> =
	pathname *Source = Pathnames::subfolder(project_folder, I"Source");
	filename *source_text_filename = Filenames::in_folder(Source, I"story.ni");
	filename *write_to = Filenames::in_folder(release_folder, I"source.txt");
	BinaryFiles::copy(source_text_filename, write_to, FALSE);

@<Create an iFiction file@> =
	filename *iFiction_filename = Filenames::in_folder(project_folder, I"Metadata.iFiction");
	filename *write_to = Filenames::in_folder(release_folder, I"iFiction.xml");
	BinaryFiles::copy(iFiction_filename, write_to, FALSE);

@<Copy a file into the release folder@> =
	pathname *P = release_folder;
	if (Str::eq_wide_string(req->details3, L"--") == FALSE)
		P = Pathnames::subfolder(P, req->details3);
	filename *write_to = Filenames::in_folder(P, req->details2);
	filename *from = Filenames::from_text(req->details1);
	int size = BinaryFiles::copy(from, write_to, TRUE);
	req->outcome_data = size;
	if (size == -1)
		BlorbErrors::errorf_1S(
			"You asked to release along with a file called '%S', which ought "
			"to be in the Materials folder for the project. But I can't find "
			"it there.", Filenames::get_leafname(from));

@<Copy a base64-encoded file across@> =
	Base64::encode(Filenames::from_text(req->details1), Filenames::from_text(req->details2),
		Placeholders::read(I"BASESIXTYFOURTOP"), Placeholders::read(I"BASESIXTYFOURTAIL"));

@<Release a file into the release folder@> =
	Requests::release_file_into_website(req->details1, req->details2, NULL);

@<Release source text as HTML into the release folder@> =
	Placeholders::set_to(I"SOURCEPREFIX", I"source", 0);
	Placeholders::set_to(I"SOURCELOCATION", req->details1, 0);
	Placeholders::set_to(I"TEMPLATE", req->details3, 0);
	filename *HTML_template = Templates::find_file_in_specific_template(req->details3, req->details2);
	if (HTML_template == NULL) BlorbErrors::error_1S("can't find HTML template file", req->details2);
	if (verbose_mode) PRINT("! Web page %f from template %s\n", HTML_template, req->details3);
	Websites::web_copy_source(HTML_template, release_folder);

@ Interpreters are copied, not made. They're really just like website
templates, except that they have a manifest file instead of an extras file,
and that they're copied into an |interpreter| subfolder of the release folder,
which is assumed already to exist. (It isn't copied because folder creation
is tiresome to do in a cross-platform way, since Windows doesn't follow POSIX.
The necessary code exists in Inform already, so we'll do it there.)

@<Create an in-browser interpreter@> =
	Placeholders::set_to(I"INTERPRETER", req->details1, 0);
	text_stream *t = Placeholders::read(I"INTERPRETER");
	filename *from = Templates::find_file_in_specific_template(t, I"(manifest).txt");
	if (from) { /* i.e., if the "(manifest).txt" file exists */
		TextFiles::read(from, FALSE, "can't open (manifest) file", FALSE, Requests::read_requested_ifile, 0, NULL);
	}

@ We copy the CSS file, if we need one; make the home page; and make any
other pages demanded by public released material. After that, it's up to
the template to add more if it wants to.

@<Create a website@> =
	Placeholders::set_to(I"TEMPLATE", req->details1, 0);
	text_stream *t = Placeholders::read(I"TEMPLATE");
	if (use_css_code_styles) {
		filename *from = Templates::find_file_in_specific_template(t, I"style.css");
		if (from) {
			filename *CSS_filename = Filenames::in_folder(release_folder, I"style.css");
			BinaryFiles::copy(from, CSS_filename, FALSE);
		}
	}
	Requests::release_file_into_website(I"index.html", t, NULL);
	request *req;
	LOOP_OVER(req, request)
		if (req->private == FALSE)
			switch (req->what_is_requested) {
				case INTERPRETER_REQ:
					Requests::release_file_into_website(I"play.html", t, NULL); break;
				case SOURCE_REQ:
					Placeholders::set_to(I"SOURCEPREFIX", I"source", 0);
					pathname *Source = Pathnames::subfolder(project_folder, I"Source");
					filename *story = Filenames::in_folder(Source, I"story.ni");
					TEMPORARY_TEXT(source_text);
					WRITE_TO(source_text, "%f", story);
					Placeholders::set_to(I"SOURCELOCATION", source_text, 0);
					DISCARD_TEXT(source_text);
					Requests::release_file_into_website(I"source.html", t, NULL); break;
			}
	@<Add further material as requested by the template@>;

@ Most templates do not request extra files, but they have the option by
including a manifest called "(extras).txt":

@<Add further material as requested by the template@> =
	filename *from = Templates::find_file_in_specific_template(t, I"(extras).txt");
	if (from) { /* i.e., if the "(extras).txt" file exists */
		TextFiles::read(from, FALSE, "can't open (extras) file", FALSE, Requests::read_requested_file, 0, NULL);
	}

@h The Extras file for a website template.
When parsing "(extras).txt", |Requests::read_requested_file| is called for each line.
We trim white space and expect the result to be a filename of something
within the template.

=
void Requests::read_requested_file(text_stream *filename, text_file_position *tfp, void *state) {
	Str::trim_white_space(filename);
	if (Str::len(filename) == 0) return;
	Requests::release_file_into_website(filename,
		Placeholders::read(I"TEMPLATE"), NULL);
}

@h The Manifest file for an interpreter.
When parsing "(manifest).txt", we do almost the same thing. Like a website
template, an interpreter is stored in a single folder, and the manifest can
list files which need to be copied into the Release in order to piece together
a working copy of the interpreter.

However, this is more expressive than the "(extras).txt" file because it
also has the ability to set placeholders in Inblorb. We use this mechanism
because it allows each interpreter to provide some metadata about its own
identity and exactly how it wants to be interfaced with the website which
Inblorb will generate. This isn't the place to document what those metadata
placeholders are and what they mean, since (except for a consistency check
below) Inblorb doesn't know anything about them -- it's the Standard
website template which they need to match up to. Anyway, the best way
to get an idea of this is to read the manifest file for the default,
Parchment, interpreter.

Placeholders are set thus:

	|[INTERPRETERVERSION]|
	|Parchment for Inform 7|
	|[]|

where the opening line names the placeholder, then one or more lines give
the contents, and the box line ends the definition.

We're in the mode if |current_placeholder| is a non-empty text, and
if so, then it's the name of the one being set. Thus the code to handle
the opening and closing lines can be identical.

=
text_stream *current_placeholder = NULL;
int cp_written = FALSE;
void Requests::read_requested_ifile(text_stream *manifestline, text_file_position *tfp, void *state) {
	if (cp_written == FALSE) { cp_written = TRUE; current_placeholder = Str::new(); }
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, manifestline, L" *(%c*?) *")) Str::copy(manifestline, mr.exp[0]);
	if (Regexp::match(&mr, manifestline, L"%[(%c+)%]"))
		Str::copy(current_placeholder, mr.exp[0]);
	else if (Str::len(current_placeholder) == 0)
		@<We're outside placeholder mode, so it's a comment or a manifested filename@>
	else
		@<We're inside placeholder mode, so it's content to be spooled into the named placeholder@>;
	Regexp::dispose_of(&mr);
}

@ Outside of placeholders, blank lines and lines introduced by the comment
character |!| are skipped.

@<We're outside placeholder mode, so it's a comment or a manifested filename@> =
	if ((Str::len(manifestline) == 0) || (Str::get_first_char(manifestline) == '!')) return;
	Requests::release_file_into_website(manifestline, Placeholders::read(I"INTERPRETER"), I"interpreter");

@ Line breaks are included between lines, though not at the end of the final
line, so that a one-line definition like the example above contains no line
break. White space is stripped out at the left and right hand edges of
each line.

@<We're inside placeholder mode, so it's content to be spooled into the named placeholder@> =
	if (Str::eq_wide_string(current_placeholder, L"INTERPRETERVM") == 0)
		@<Check the value being given against the actual VM we're blorbing up@>;
	if (Placeholders::read(current_placeholder))
		Placeholders::append_to(current_placeholder, I"\n");
	Placeholders::append_to(current_placeholder, manifestline);

@ Perhaps it's clumsy to do it here, but at some point Inblorb needs to
make sure we aren't trying to release a Z-machine game along with a
Glulx interpreter, or vice versa. The manifest file for the interpreter
is required to declare which virtual machines it implements, by giving a
value of the placeholder |INTERPRETERVM|. This declares whether the interpreter
can handle blorbed Z-machine files (|z|), blorbed Glulx files (|g|) or both
(|zg| or |gz|). No other values are legal; note lower case. Inblorb then
checks this against its own placeholder |INTERPRETERVMIS|, which stores
what the actual format of the blorb being released is.

@<Check the value being given against the actual VM we're blorbing up@> =
	text_stream *vm_used = Placeholders::read(I"INTERPRETERVMIS");
	int capable = FALSE;
	LOOP_THROUGH_TEXT(P, manifestline)
		if (Str::get(P) == Str::get_first_char(vm_used))
			capable = TRUE;
	if (capable == FALSE) {
		text_stream *format = I"Z-machine";
		if (Str::get_first_char(vm_used) == 'g') format = I"Glulx";
		BlorbErrors::errorf_2S(
			"You asked to release along with a copy of the '%S' in-browser "
			"interpreter, but this can't handle story files which use the "
			"%S story file format. (The format can be changed on Inform's "
			"Settings panel for a project.)",
			Placeholders::read(I"INTERPRETER"), format);
	}

@ There are really three cases when we release something from a website
template. We can copy it verbatim as a binary file, we can expand placeholders
but otherwise copy as a single item, or we can use it to make a mass
generation of source pages.

=
void Requests::release_file_into_website(text_stream *name, text_stream *t, text_stream *sub) {
	pathname *P = release_folder;
	if (sub) P = Pathnames::subfolder(P, sub);
	filename *write_to = Filenames::in_folder(P, name);

	filename *from = Templates::find_file_in_specific_template(t, name);
	if (from == NULL) {
		BlorbErrors::error_1S("unable to find file in website template", name);
		return;
	}

	if (Filenames::guess_format(write_to) == FORMAT_PERHAPS_HTML)
		@<Release an HTML page from the template into the website@>
	else
		@<Release a binary file from the template into the website@>;
}

@ "Source.html" is a special case, as it expands into a whole suite of
pages automagically. Otherwise we work out the filenames and then hand over
to the experts.

@<Release an HTML page from the template into the website@> =
	Placeholders::set_to(I"TEMPLATE", t, 0);
	if (verbose_mode) PRINT("! Web page %S from template %S\n", name, t);
	if (Str::eq_wide_string(name, L"source.html"))
		Websites::web_copy_source(from, release_folder);
	else
		Websites::web_copy(from, write_to);

@<Release a binary file from the template into the website@> =
	if (verbose_mode) PRINT("! Binary file %S from template %S\n", name, t);
	BinaryFiles::copy(from, write_to, FALSE);

@ The home page will need links to any public released resources, and this
is where those are added (to the other links already present, that is).

=
void Requests::add_links_to_requested_resources(OUTPUT_STREAM) {
	request *req;
	LOOP_OVER(req, request)
		if (req->private == FALSE)
			switch (req->what_is_requested) {
				case WEBSITE_REQ: break;
				case INTERPRETER_REQ:
					WRITE("<li>");
					Links::download_link(OUT, I"Play In-Browser", NULL, I"play.html", I"link");
					WRITE("</li>");
					break;
				case SOURCE_REQ:
					WRITE("<li>");
					Links::download_link(OUT, I"Source Text", NULL, I"source.html", I"link");
					WRITE("</li>");
					break;
				case SOLUTION_REQ:
					WRITE("<li>");
					Links::download_link(OUT, I"Solution", NULL, I"solution.txt", I"link");
					WRITE("</li>");
					break;
				case IFICTION_REQ:
					WRITE("<li>");
					Links::download_link(OUT, I"Library Card", NULL, I"iFiction.xml", I"link");
					WRITE("</li>");
					break;
			}
}

@h Blorb relocation.
This is a little dodge used to make the process of releasing games in
Inform 7 more seamless: see the manual for an explanation.

=
void Requests::declare_where_blorb_should_be_copied(pathname *path) {
	text_stream *leaf = Placeholders::read(I"STORYFILE");
	if (leaf == NULL) leaf = I"Story";
	filename *to = Filenames::in_folder(path, leaf);
	PRINT("Copy blorb to: [[%f]]\n", to);
}

@h Reporting the release.
Inform normally asks Inblorb to generate an HTML page reporting what it has
done, and if things have gone well then this typically contains a list of
what has been released. (That's easy for us to produce, since we just have to
look through the requests.) Rather than attempt to write to the file here,
we copy the necessary HTML into the placeholder |ph|.

=
void Requests::report_requested_material(text_stream *ph) {
	if (release_folder == NULL) return; /* this should never happen */

	int launch_website = FALSE, launch_play = FALSE;

	Placeholders::append_to(ph, I"<ul>");
	@<Itemise the blorb file, possibly mentioning pictures and sounds@>;
	@<Itemise the website, mentioning how many pages it has@>;
	@<Itemise the interpreter@>;
	@<Itemise the library card@>;
	@<Itemise the solution file@>;
	@<Itemise the source text@>;
	@<Itemise auxiliary files in a sub-list@>;
	Placeholders::append_to(ph, I"</ul>");
	if ((launch_website) || (launch_play))
		@<Give a centred line of links to the main web pages produced@>;

	@<Add in links to release instructions from Inform source text@>;
	@<Add in advertisements for features Inform would like to offer@>;
}

@<Itemise the blorb file, possibly mentioning pictures and sounds@> =
	if ((no_pictures_included > 1) || (no_sounds_included > 0))
		Placeholders::append_to(ph,
			Str::literal(L"<li>The blorb file <b>[STORYFILE]</b> ([BLORBFILESIZE]K in size, "
				L"including [BLORBFILEPICTURES] figures(s) and [BLORBFILESOUNDS] "
				L"sound(s))</li>"));
	else
		Placeholders::append_to(ph, I"<li>The blorb file <b>[STORYFILE]</b> ([BLORBFILESIZE]K in size)</li>");

@<Itemise the website, mentioning how many pages it has@> =
	if (Requests::count_requests_of_type(WEBSITE_REQ) > 0) {
		Placeholders::append_to(ph, I"<li>A website (generated from the [TEMPLATE] template) of ");
		TEMPORARY_TEXT(pcount);
		WRITE_TO(pcount, "%d page%s", HTML_pages_created, (HTML_pages_created!=1)?"s":"");
		Placeholders::append_to(ph, pcount);
		Placeholders::append_to(ph, I"</li>");
		launch_website = TRUE;
		DISCARD_TEXT(pcount);
	}

@<Itemise the interpreter@> =
	if (Requests::count_requests_of_type(INTERPRETER_REQ) > 0) {
		launch_play = TRUE;
		Placeholders::append_to(ph, I"<li>A play-in-browser page (generated from the [INTERPRETER] interpreter)</li>");
	}

@<Itemise the library card@> =
	if (Requests::count_requests_of_type(IFICTION_REQ) > 0)
		Placeholders::append_to(ph, I"<li>The library card (stored as an iFiction record)</li>");

@<Itemise the solution file@> =
	if (Requests::count_requests_of_type(SOLUTION_REQ) > 0)
		Placeholders::append_to(ph, I"<li>A solution file</li>");

@<Itemise the source text@> =
	if (Requests::count_requests_of_type(SOURCE_REQ) > 0) {
		if (source_HTML_pages_created > 0) {
			Placeholders::append_to(ph, I"<li>The source text (as plain text and as ");
			TEMPORARY_TEXT(pcount);
			WRITE_TO(pcount, "%d web page%s",
				source_HTML_pages_created, (source_HTML_pages_created!=1)?"s":"");
			Placeholders::append_to(ph, pcount);
			Placeholders::append_to(ph, I")</li>");
			DISCARD_TEXT(pcount);
		}
	}
	if (Requests::count_requests_of_type(RELEASE_SOURCE_REQ) > 0)
		Placeholders::append_to(ph, I"<li>The source text (as part of the website)</li>");

@<Itemise auxiliary files in a sub-list@> =
	if (Requests::count_requests_of_type(COPY_REQ) > 0) {
		Placeholders::append_to(ph, I"<li>The following additional file(s):<ul>");
		request *req;
		LOOP_OVER(req, request)
			if (req->what_is_requested == COPY_REQ) {
				text_stream *leafname = req->details2;
				Placeholders::append_to(ph, I"<li>");
				Placeholders::append_to(ph, leafname);
				if (req->outcome_data >= 4096) {
					TEMPORARY_TEXT(filesize);
					WRITE_TO(filesize, " (%dK)", req->outcome_data/1024);
					Placeholders::append_to(ph, filesize);
					DISCARD_TEXT(filesize);
				} else if (req->outcome_data >= 0) {
					TEMPORARY_TEXT(filesize);
					WRITE_TO(filesize, " (%d byte%s)",
						req->outcome_data, (req->outcome_data!=1)?"s":"");
					Placeholders::append_to(ph, filesize);
					DISCARD_TEXT(filesize);
				}
				if (Str::eq_wide_string(req->details3, L"--") == FALSE) {
					Placeholders::append_to(ph, I" to subfolder ");
					Placeholders::append_to(ph, req->details3);
				}
				Placeholders::append_to(ph, I"</li>");
			}
		Placeholders::append_to(ph, I"</ul></li>");
	}

@ These two links are handled by means of LAUNCH icons which, if clicked,
open the relevant pages not in the Inform application but using an external
web browser (e.g., Safari on most Mac OS X installations). We can only
achieve this effect using a Javascript function provided by the Inform
application, called |openUrl|.

@<Give a centred line of links to the main web pages produced@> =
	Placeholders::append_to(ph, I"<p><center>");
	if (launch_website) {
		Placeholders::append_to(ph,
			Str::literal(L"<a href=\"[JAVASCRIPTPRELUDE]"
				"openUrl('file://[**MATERIALSFOLDERPATHOPEN]/Release/index.html')\">"
				"<img src='inform:/outcome_images/browse.png' border=0></a> home page"));
	}
	if ((launch_website) && (launch_play))
		Placeholders::append_to(ph, I" : ");
	if (launch_play)
		Placeholders::append_to(ph,
			Str::literal(L"<a href=\"[JAVASCRIPTPRELUDE]"
				L"openUrl('file://[**MATERIALSFOLDERPATHOPEN]/Release/play.html')\">"
				L"<img src='inform:/outcome_images/browse.png' border=0></a> play-in-browser page"));
	Placeholders::append_to(ph, I"</center></p>");

@ Since Inblorb has no knowledge of what the Inform source text producing
this blorb was, it can't finish the status report from its own knowledge --
it must rely on details supplied to it by Inform via blurb commands. First,
Inform gives it source-text links for any "Release along with..." sentences,
which have by now become |INSTRUCTION_REQ| requests:

@<Add in links to release instructions from Inform source text@> =
	request *req;
	int count = 0;
	LOOP_OVER(req, request)
		if (req->what_is_requested == INSTRUCTION_REQ) {
			if (count == 0)
				Placeholders::append_to(ph,
					I"<p>The source text gives release instructions ");
			else
				Placeholders::append_to(ph, I" and ");
			Placeholders::append_to(ph, req->details1);
			Placeholders::append_to(ph, I" here");
			count++;
		}
	if (count > 0)
		Placeholders::append_to(ph, I".</p>");

@ And secondly, Inform gives it adverts for other fancy services on offer,
complete with links to the Inform documentation (which, again, Inblorb
doesn't itself know about); and these have by now become |ALTERNATIVE_REQ|
requests.

@<Add in advertisements for features Inform would like to offer@> =
	request *req;
	int count = 0;
	LOOP_OVER(req, request)
		if (req->what_is_requested == ALTERNATIVE_REQ) {
			if (count == 0)
				Placeholders::append_to(ph,
					I"<p>Here are some other possibilities you might want to consider:<p><ul>");
			Placeholders::append_to(ph, I"<li>");
			Placeholders::append_to(ph, req->details1);
			Placeholders::append_to(ph, I"</li>");
			count++;
		}
	if (count > 0)
		Placeholders::append_to(ph, I"</ul></p>");

@ A convenient way to see if we've received requests of any given type:

=
int Requests::count_requests_of_type(int t) {
	request *req;
	int count = 0;
	LOOP_OVER(req, request)
		if (req->what_is_requested == t)
			count++;
	return count;
}
