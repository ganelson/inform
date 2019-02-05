[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@e FONT_CLSW

=
text_stream *font_setting = NULL;
int folder_count = 0;
pathname *from_folder = NULL;
pathname *to_folder = NULL;

int main(int argc, char **argv) {
	Foundation::start();
	font_setting = Str::new();

	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inrtps from-folder to-folder [options]\n");

	CommandLine::declare_boolean_switch(FONT_CLSW, L"font", 1,
		L"include non-CSS font settings");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::pname);

	if ((folder_count != 0) && (folder_count != 2))
		Errors::fatal("usage: inrtps from-folder to-folder [options]");

	if (folder_count == 2)
		Translator::go(from_folder, to_folder, font_setting);

	Foundation::end();
	return 0;
}

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case FONT_CLSW:
			if (val) WRITE_TO(font_setting,
				"face=\"lucida grande,geneva,arial,tahoma,verdana,helvetica,helv\"");
			else Str::clear(font_setting);
			break;
	}
}

void Main::pname(int id, text_stream *arg, void *state) {
	switch (folder_count++) {
		case 0: from_folder = Pathnames::from_text(arg); break;
		case 1: to_folder = Pathnames::from_text(arg); break;
		default: Errors::fatal("too many arguments given at command line");
	}
}
