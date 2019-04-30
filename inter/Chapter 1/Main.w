[Main::] Main.

The top level, which decides what is to be done and then carries
this plan out.

@h Main routine.

@e TEXTUAL_CLSW
@e BINARY_CLSW
@e INTER_CLSW
@e DOMAIN_CLSW
@e TEMPLATE_CLSW
@e TEST_CLSW

=
int main(int argc, char **argv) {
	Foundation::start();
	InterModule::start();
	CodegenModule::start();

	CommandLine::declare_heading(
		L"[[Purpose]]\n\n"
		L"usage: inter file1 file2 ... [options]\n");

	CommandLine::declare_switch(TEXTUAL_CLSW, L"textual", 2,
		L"write to file X in textual format");
	CommandLine::declare_switch(BINARY_CLSW, L"binary", 2,
		L"write to file X in binary format");
	CommandLine::declare_switch(INTER_CLSW, L"inter", 2,
		L"specify code-generation chain for inter code");
	CommandLine::declare_switch(TEMPLATE_CLSW, L"template", 2,
		L"specify folder holding i6t template files");
	CommandLine::declare_switch(TEST_CLSW, L"test", 2,
		L"perform unit tests from file X");
	CommandLine::declare_switch(DOMAIN_CLSW, L"domain", 2,
		L"specify folder to read/write inter files from/to");

	CommandLine::read(argc, argv, NULL, &Main::respond, &Main::add_file);

	Main::act();

	InterModule::end();
	CodegenModule::end();
	Foundation::end();

	if (Errors::have_occurred()) return 1;
	return 0;
}

@ =
pathname *template_path = NULL;
pathname *domain_path = NULL;
filename *output_textually = NULL;
filename *output_binarily = NULL;
filename *unit_test_file = NULL;
text_stream *inter_processing_chain = NULL;

void Main::respond(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case TEXTUAL_CLSW: output_textually = Filenames::from_text(arg); break;
		case BINARY_CLSW: output_binarily = Filenames::from_text(arg); inter_processing_chain = NULL; break;
		case INTER_CLSW: inter_processing_chain = Str::duplicate(arg); inter_processing_chain = NULL; break;
		case DOMAIN_CLSW: domain_path = Pathnames::from_text(arg); inter_processing_chain = NULL; break;
		case TEMPLATE_CLSW: template_path = Pathnames::from_text(arg); inter_processing_chain = NULL; break;
		case TEST_CLSW: unit_test_file = Filenames::from_text(arg); break;
	}
}

@ =
typedef struct inter_file {
	struct filename *inter_filename;
	MEMORY_MANAGEMENT
} inter_file;

void Main::add_file(int id, text_stream *arg, void *state) {
	inter_file *IF = CREATE(inter_file);
	IF->inter_filename = Filenames::from_text(arg);
}

@ =
void Main::act(void) {
	inter_repository *I = Inter::create(1, 32);
	inter_file *IF;
	LOOP_OVER(IF, inter_file)
		if (Inter::Binary::test_file(IF->inter_filename))
			Inter::Binary::read(I, IF->inter_filename);
		else
			Inter::Textual::read(I, IF->inter_filename);
	if (inter_processing_chain) {
		int NO_FS_AREAS = 0;
		pathname *pathname_of_i6t_files[1];
		if (template_path) { NO_FS_AREAS = 1; pathname_of_i6t_files[0] = template_path; }
		stage_set *SS = CodeGen::Stage::parse(inter_processing_chain, I"output.i6");
		CodeGen::Stage::follow(domain_path, SS, I, NO_FS_AREAS, pathname_of_i6t_files, template_path, NULL);
	} else if (unit_test_file) {
		UnitTests::run(unit_test_file);
	} else {
		if (output_textually) {
			text_stream C_struct; text_stream *OUT = &C_struct;
			if (STREAM_OPEN_TO_FILE(OUT, output_textually, UTF8_ENC) == FALSE)
				Errors::fatal_with_file("unable to open textual inter file for output: %f",
					output_textually);
			Inter::Textual::write(OUT, I, NULL, 1);
			STREAM_CLOSE(OUT);
		}
		if (output_binarily) Inter::Binary::write(output_binarily, I);
	}
}
