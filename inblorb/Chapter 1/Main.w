[Main::] Main.

To parse command-line arguments, then start the Blurb interpreter, then
report back to the user.

@h Some globals.
The following variables record HTML and Javascript-related points where
Inblorb needs to behave differently on the different platforms. The default
values here aren't actually correct for any platform as they stand: in the
|main| routine below, we set them as needed.

=
wchar_t *FONT_TAG = L"size=2"; /* contents of a |<font>| tag */
wchar_t *JAVASCRIPT_PRELUDE = L"javascript:window.Project."; /* calling prefix */
int escape_openUrl = FALSE, escape_fileUrl = FALSE;
int reverse_slash_openUrl = FALSE, reverse_slash_fileUrl = FALSE;

@ Some global variables:

=
int error_count = 0; /* number of error messages produced so far */

int verbose_mode = FALSE; /* print diagnostics to |stdout| while running? */
int current_year_AD = 0; /* e.g., 2008 */

int blorb_file_size = 0; /* size in bytes of the blorb file written */
int no_pictures_included = 0; /* number of picture resources included in the blorb */
int no_sounds_included = 0; /* number of sound resources included in the blorb */
int HTML_pages_created = 0; /* number of pages created in the website, if any */
int source_HTML_pages_created = 0; /* number of those holding source */
int sound_resource_num = 3; /* current sound resource number we're working on */
int picture_resource_num = 1; /* current picture resource number we're working on */

int use_css_code_styles = FALSE; /* use |<span class="X">| markings when setting code */
pathname *project_folder = NULL; /* pathname of I7 project folder, if any */
pathname *release_folder = NULL; /* pathname of folder for website to write, if any */
filename *status_template = NULL; /* filename of report HTML page template, if any */
filename *status_file = NULL; /* filename of report HTML page to write, if any */
int cover_exists = FALSE; /* an image is specified as cover art */
int default_cover_used = FALSE; /* but it's only the default supplied by Inform */
int cover_is_in_JPEG_format = TRUE; /* as opposed to |PNG| format */

@h Main.
Like most programs, this one parses command-line arguments, sets things up,
reads the input and then writes the output.

That's a little over-simplified, though, because it also produces auxiliary
outputs along the way, in the course of parsing the blurb file. The blorb
file is only the main output -- there might also be a web page and a solution
file, for instance.

=
filename *blurb_filename = NULL;
filename *blorb_filename = NULL;

int main(int argc, char *argv[]) {
	Foundation::start();
	Basics::register_mreasons();
	blurb_filename = Filenames::in(NULL, I"Release.blurb");
	blorb_filename = Filenames::in(NULL, I"story.zblorb");

	@<Make the default settings@>;
	@<Parse command-line arguments@>;

	Placeholders::initialise();
	if (blurb_filename) {
		Main::print_banner();
		Parser::parse_blurb_file(blurb_filename);
		Writer::write_blorb_file(blorb_filename);
		Requests::create_requested_material();
		Main::print_report();
	}

	Foundation::end();
	if (error_count > 0) return 1;
	return 0;
}

@<Make the default settings@> =
	release_folder = NULL;
	project_folder = NULL;
	status_file = NULL;
	status_template = NULL;

@ We use Foundation's standard command-line routines.

@e VERBOSE_CLSW
@e PROJECT_CLSW

@<Parse command-line arguments@> =
	@<Read the command-line switches@>;
	@<Set platform-dependent HTML and Javascript variables@>;

	if (verbose_mode)
		PRINT("! Blurb in: <%f>\n! Blorb out: <%f>\n",
			blurb_filename, blorb_filename);

@<Read the command-line switches@> =
	CommandLine::declare_heading(L"inblorb: a releaser and packager for IF story files\n\n"
		L"usage: inblorb [-options] [blurbfile [blorbfile]]\n");

	CommandLine::declare_boolean_switch(VERBOSE_CLSW, L"verbose", 1,
		L"print running notes on what's happening", FALSE);
	CommandLine::declare_switch(PROJECT_CLSW, L"project", 2,
		L"work within Inform project X");

	int bare_words = 0;
	CommandLine::read(argc, argv, &bare_words, &Main::switch, &Main::bareword);

	if (project_folder) {
		if (bare_words > 0) Errors::fatal("if -project is used, no other filenames should be given");
		blurb_filename = Filenames::in(project_folder, I"Release.blurb");
		pathname *Build = Pathnames::down(project_folder, I"Build");
		blorb_filename = Filenames::in(Build, I"output.zblorb");
	} else {
		if (bare_words == 0) blurb_filename = NULL;
	}

@ =
void Main::switch(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case VERBOSE_CLSW: verbose_mode = val; break;
		case PROJECT_CLSW: project_folder = Pathnames::from_text(arg); break;
		default: internal_error("unimplemented switch");
	}
}

void Main::bareword(int id, text_stream *opt, void *state) {
	int *bare_words = (int *) state;
	(*bare_words)++;
	switch (*bare_words) {
		case 1: blurb_filename = Filenames::from_text(opt); break;
		case 2: blorb_filename = Filenames::from_text(opt); break;
		default: Errors::fatal("bad command line usage (see -help)");
	}
}

@ Now let's set the platform-dependent variables.

Inblorb generates quite a variety of HTML, for instance to create websites,
but the tricky points below affect only one special page not browsed by
the general public: the results page usually called |StatusCblorb.html|
(though this depends on how the |status| command is used in the blurb).
The results page is intended only for viewing within the Inform user
interface, and it expects to have two Javascript functions available,
|openUrl| and |fileUrl|. Because the object structure has needed to be
different for the Windows and OS X user interface implementations of
Javascript, we abstract the prefix for these function calls into the
|JAVASCRIPT_PRELUDE|. Thus
= (text)
	<a href="***openUrl">...</a>
=
causes a link, when clicked, to call the |openUrl| function, where |***|
is the prelude; similarly for |fileUrl|. The first opens a URL in the local
operating system's default web browser, the second opens a file (identified
by a |file:...| URL) in the local operating system. These two URLs may
need treatment to handle special characters:

(a) "escaping", where spaces in the URL are escaped to |%2520|, which
within a Javascript string literal produces |%20|, the standard way to
represent a space in a web URL;

(b) "reversing slashes", where backslashes are converted to forward
slashes -- useful if the separation character is a backslash, as on Windows,
since backslashes are escape characters in Javascript literals.

@<Set platform-dependent HTML and Javascript variables@> =
	#ifndef WINDOWS_JAVASCRIPT
		FONT_TAG = L"face=\"lucida grande,geneva,arial,tahoma,verdana,helvetica,helv\" size=2";
		escape_openUrl = TRUE; /* we want |openUrl| to escape, and |fileUrl| not to */
	#endif
	#ifdef WINDOWS_JAVASCRIPT
		JAVASCRIPT_PRELUDE = L"javascript:external.Project.";
		reverse_slash_openUrl = TRUE; reverse_slash_fileUrl = TRUE;
	#endif

@ The placeholder variable [YEAR] is initialised to the year in which Inblorb
runs, according to the host operating system, at least. (It can of course then
be overridden by commands in the blurb file, and Inform always does this in
the blurb files it writes. But it leaves [DATESTAMP] and [TIMESTAMP] alone.)

=
void Main::initialise_time_variables(void) {
	TEMPORARY_TEXT(datestamp)
	TEMPORARY_TEXT(infocom)
	TEMPORARY_TEXT(timestamp)
	char *weekdays[] = { "Sunday", "Monday", "Tuesday", "Wednesday",
		"Thursday", "Friday", "Saturday" };
	char *months[] = { "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December" };
	Placeholders::set_to_number(I"YEAR", the_present->tm_year+1900);
	WRITE_TO(datestamp, "%s %d %s %d", weekdays[the_present->tm_wday],
		the_present->tm_mday, months[the_present->tm_mon], the_present->tm_year+1900);
	WRITE_TO(infocom, "%02d%02d%02d",
		the_present->tm_year-100, the_present->tm_mon + 1, the_present->tm_mday);
	WRITE_TO(timestamp, "%02d:%02d.%02d", the_present->tm_hour,
		the_present->tm_min, the_present->tm_sec);
	Placeholders::set_to(I"DATESTAMP", datestamp, 0);
	Placeholders::set_to(I"INFOCOMDATESTAMP", infocom, 0);
	Placeholders::set_to(I"TIMESTAMP", timestamp, 0);
	DISCARD_TEXT(datestamp)
	DISCARD_TEXT(infocom)
	DISCARD_TEXT(timestamp)
}

@h Opening and closing banners.
Note that Inblorb customarily prints informational messages with an initial
|!|, so that the piped output from Inblorb could be used as an |Include|
file in I6 code, where |!| is the comment character; that isn't in fact how
I7 uses Inblorb, but it's traditional for blorbing programs to do this.

=
void Main::print_banner(void) {
	text_stream *ver = I"inblorb [[Build Number]]";
	if (fix_time_mode) ver = I"inblorb 99.99";
	PRINT("! %S [executing on %S at %S]\n",
		ver, Placeholders::read(I"DATESTAMP"), Placeholders::read(I"TIMESTAMP"));
	PRINT("! The blorb spell (safely protect a small object ");
	PRINT("as though in a strong box).\n");
}

@ The concluding banner is much smaller -- empty if all went well, a single
comment line if not. But we also generate the status report page (if that has
been requested) -- a single HTML file generated from a template by expanding
placeholders in the template. All of the meat of the report is in those
placeholders, of course; the template contains only some fancy formatting.

=
void Main::print_report(void) {
	if (error_count > 0) PRINT("! Completed: %d error(s)\n", error_count);
	@<Set a whole pile of placeholders which will be needed to generate the status page@>;
	if (status_template) Websites::web_copy(status_template, status_file);
}

@ If it isn't apparent what these placeholders do, take a look at
the template file called |CblorbModel.html| in the Inform application --
that's where they're used.

@<Set a whole pile of placeholders which will be needed to generate the status page@> =
	if (error_count > 0) {
		Placeholders::set_to(I"CBLORBSTATUS", I"Failed", 0);
		Placeholders::set_to(I"CBLORBSTATUSIMAGE", I"inform:/outcome_images/cblorb_failed.png", 0);
		Placeholders::set_to(I"CBLORBSTATUSTEXT",
			Str::literal(L"Inform translated your source text as usual, to manufacture a 'story "
				L"file': all of that worked fine. But the Release then went wrong, for "
				L"the following reason:<p><ul>[CBLORBERRORS]</ul>"), 0
		);
	} else {
		Placeholders::set_to(I"CBLORBERRORS", I"No problems occurred", 0);
		Placeholders::set_to(I"CBLORBSTATUS", I"Succeeded", 0);
		Placeholders::set_to(I"CBLORBSTATUSIMAGE", I"file://[SMALLCOVER]", 0);
		Placeholders::set_to(I"CBLORBSTATUSTEXT",
			Str::literal(L"All went well. I've put the released material into the 'Release' subfolder "
				L"of the Materials folder for the project: you can take a look with "
				L"the menu option <b>Release &gt; Open Materials Folder</b> or by clicking "
				L"the blue folders above.<p>"
				L"Releases can range in size from a single blorb file to a medium-sized website. "
				L"Here's what we currently have:<p>"), 0
		);
		Requests::report_requested_material(I"CBLORBSTATUSTEXT");
	}
	if (blorb_file_size > 0) {
		Placeholders::set_to_number(I"BLORBFILESIZE", blorb_file_size/1024);
		Placeholders::set_to_number(I"BLORBFILEPICTURES", no_pictures_included);
		Placeholders::set_to_number(I"BLORBFILESOUNDS", no_sounds_included);
		PRINT("! Completed: wrote blorb file with ");
		PRINT("%d picture(s), %d sound(s)\n", no_pictures_included, no_sounds_included);
	} else {
		Placeholders::set_to_number(I"BLORBFILESIZE", 0);
		Placeholders::set_to_number(I"BLORBFILEPICTURES", 0);
		Placeholders::set_to_number(I"BLORBFILESOUNDS", 0);
		PRINT("! Completed: no blorb output requested\n");
	}
