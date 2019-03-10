[Configuration::] Configuration.

Instructions of indoc to different output types.

@h Known instruction files.
Most configuration is done not from the command line, but by instructions
files, and we store a list of those here:

=
linked_list *instructions_files = NULL; /* of |filename| */

void Configuration::add_instructions_file(filename *F) {
	if (instructions_files == NULL) instructions_files = NEW_LINKED_LIST(filename);
	ADD_TO_LINKED_LIST(F, filename, instructions_files);
}

void Configuration::read_instructions(text_stream *target, settings_block *settings) {
	Instructions::read_instructions(target, instructions_files, settings);
}

@h Command line switches.

=
typedef struct cl_state {
	struct text_stream *target_chosen;
	struct settings_block *settings;
} cl_state;

void Configuration::read_command_line(int argc, char **argv, settings_block *settings) {
	cl_state state;
	state.target_chosen = Str::new();
	state.settings = settings;
	@<Read the command line@>;
	path_to_indoc = Pathnames::installation_path("INDOC_PATH", I"indoc");
	if (settings->verbose_mode) PRINT("Installation path is %p\n", path_to_indoc);
	path_to_indoc_materials = Pathnames::subfolder(path_to_indoc, I"Materials");
	Configuration::add_instructions_file(
		Filenames::in_folder(path_to_indoc_materials, I"basic-instructions.txt"));
	Configuration::add_instructions_file(
		Filenames::in_folder(settings->book_folder, I"indoc-instructions.txt"));
	Configuration::read_instructions(state.target_chosen, settings);
}

@

@e VERBOSE_CLSW
@e TEST_INDEX_CLSW
@e REWRITE_CLSW
@e FROM_CLSW
@e TO_CLSW
@e INSTRUCTIONS_CLSW

@<Read the command line@> =
	CommandLine::declare_heading(
		L"indoc: a tool for rendering Inform documentation\n\n"
		L"Usage: indoc [OPTIONS] TARGET\n"
		L"where TARGET must be one of those set up in the instructions.\n");

	CommandLine::declare_boolean_switch(VERBOSE_CLSW, L"verbose", 1,
		L"explain what indoc is doing");
	CommandLine::declare_boolean_switch(TEST_INDEX_CLSW, L"test-index", 1,
		L"test indexing");
	CommandLine::declare_switch(REWRITE_CLSW, L"rewrite-standard-rules", 2,
		L"amend source of Standard Rules to include documentation references");
	CommandLine::declare_switch(FROM_CLSW, L"from", 2,
		L"use documentation in directory X (instead of 'Documentation' in cwd)");
	CommandLine::declare_switch(TO_CLSW, L"to", 2,
		L"redirect output to folder X (which must already exist)");
	CommandLine::declare_switch(INSTRUCTIONS_CLSW, L"instructions", 2,
		L"read further instructions from file X");

	if (CommandLine::read(argc, argv, &state, &Configuration::switch, &Configuration::bareword)
		== FALSE) exit(0);

@ =
void Configuration::switch(int id, int val, text_stream *arg, void *v_cl_state) {
	settings_block *settings = ((cl_state *) v_cl_state)->settings;
	switch (id) {
		case VERBOSE_CLSW: settings->verbose_mode = val; break;
		case TEST_INDEX_CLSW: settings->test_index_mode = val; break;
		case REWRITE_CLSW: settings->standard_rules_filename = Filenames::from_text(arg); break;
		case FROM_CLSW: settings->book_folder = Pathnames::from_text(arg); break;
		case TO_CLSW: settings->destination = Pathnames::from_text(arg);
			settings->destination_modifiable = FALSE; break;
		case INSTRUCTIONS_CLSW: Configuration::add_instructions_file(Filenames::from_text(arg)); break;
		default: internal_error("unimplemented switch");
	}
}

void Configuration::bareword(int id, text_stream *opt, void *v_cl_state) {
	cl_state *state = (cl_state *) v_cl_state;
	Str::copy(state->target_chosen, opt);
}
