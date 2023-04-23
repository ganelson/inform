[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@d PROGRAM_NAME "inrtps"
@d DEFAULT_FONT_TEXT 

=
pathname *from_folder = NULL;
pathname *to_folder = NULL;
int font_setting = TRUE;

int main(int argc, char **argv) {
	Foundation::start(argc, argv);
	@<Read the command line@>;
	if (from_folder) {
		if (to_folder == NULL)
			Errors::fatal("usage: inrtps from-folder to-folder [options]");
		text_stream *f = NULL;
		if (font_setting)
			f = I"face='lucida grande,geneva,arial,tahoma,verdana,helvetica,helv'";
		TEMPORARY_TEXT(css)
		@<Read the platform CSS file@>;
		Translator::go(from_folder, to_folder, f, css);
	}
	Foundation::end();
	return 0;
}

@ We use Foundation to read the command line:

@e FONT_CLSW

@<Read the command line@> =	
	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inrtps from-folder to-folder [options]\n");

	CommandLine::declare_boolean_switch(FONT_CLSW, L"font", 1,
		L"explicitly set sans-serif fonts by name", TRUE);

	CommandLine::read(argc, argv, NULL, &Main::option, &Main::bareword);

@ =
void Main::option(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case FONT_CLSW: font_setting = val; break;
	}
}

void Main::bareword(int id, text_stream *arg, void *state) {
	if (from_folder == NULL) from_folder = Pathnames::from_text(arg);
	else if (to_folder == NULL) to_folder = Pathnames::from_text(arg);
	else Errors::fatal("too many arguments given at command line");
}

@ We also read the per-platform CSS file, if present:

@<Read the platform CSS file@> =
	filename *css_filename = NULL;
	pathname *css_path = Pathnames::from_text(I"inform7/Internal/HTML");
	TEMPORARY_TEXT(platform_variation)
	WRITE_TO(platform_variation, "%s-platform.css", PLATFORM_STRING);
	css_filename = Filenames::in(css_path, platform_variation);
	if (TextFiles::exists(css_filename) == FALSE) {
		css_filename = Filenames::in(css_path, I"platform.css");
	}
	if (TextFiles::exists(css_filename)) {
		TextFiles::read(css_filename, FALSE, "can't open css file",
			TRUE, Main::read_css_line, NULL, css);
	}

@ =
void Main::read_css_line(text_stream *line, text_file_position *tfp, void *X) {
	text_stream *str = (text_stream *) X;
	WRITE_TO(str, "%S\n", line);
}
