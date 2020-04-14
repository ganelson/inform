[BuildMethodology::] Build Methodology.

Whether to run tasks internally in some merged tool, or run via the shell, or
simply trace to the standard output what we think ought to be done.

@ This is rather grandly named for what it is: it's just a bundle of settings
about how to carry out build steps. Should we (a) make a dry run, just printing
hypothetical shell commands, or (b) issue those shell commands via |system|,
or (c) take direct action by calling functions within the current executable?
If (a) or (b) then we will need to know the locations of the executable files
for the tools |inter|, |inform6|, |inform7| and |inblorb|.

@e DRY_RUN_METHODOLOGY from 1
@e SHELL_METHODOLOGY
@e INTERNAL_METHODOLOGY

=
typedef struct build_methodology {
	filename *to_inter;
	filename *to_inform6;
	filename *to_inform7;
	filename *to_inblorb;
	int methodology;
	MEMORY_MANAGEMENT
} build_methodology;

@ If the |tangled| flag is set, we expect |inform7|, for example, to be at
|tools_path/inform7/Tangled/inform7|; if it is clear, we expect it only to
be |tools_path/inform7|. This is relevant only for the command-line Inbuild,
which used tangled mode by default, but untangled mode if the user has
specified an explicit path at the command line.

=
build_methodology *BuildMethodology::new(pathname *tools_path, int tangled, int meth) {
	build_methodology *BM = CREATE(build_methodology);
	BM->methodology = meth;
	pathname *inter_path = tools_path;
	if (tangled) {
		inter_path = Pathnames::subfolder(inter_path, I"inter");
		inter_path = Pathnames::subfolder(inter_path, I"Tangled");
	}
	BM->to_inter = Filenames::in_folder(inter_path, I"inter");
	pathname *inform6_path = tools_path;
	if (tangled) {
		inform6_path = Pathnames::subfolder(inform6_path, I"inform6");
		inform6_path = Pathnames::subfolder(inform6_path, I"Tangled");
	}
	BM->to_inform6 = Filenames::in_folder(inform6_path, I"inform6");
	pathname *inform7_path = tools_path;
	if (tangled) {
		inform7_path = Pathnames::subfolder(inform7_path, I"inform7");
		inform7_path = Pathnames::subfolder(inform7_path, I"Tangled");
	}
	BM->to_inform7 = Filenames::in_folder(inform7_path, I"inform7");
	pathname *inblorb_path = tools_path;
	if (tangled) {
		inblorb_path = Pathnames::subfolder(inblorb_path, I"inblorb");
		inblorb_path = Pathnames::subfolder(inblorb_path, I"Tangled");
	}
	BM->to_inblorb = Filenames::in_folder(inblorb_path, I"inblorb");
	return BM;
}

@ The |inform7| tool only ever uses the internal methodology, for which
these filenames are irrelevant, since no shell commands are ever issued.
It gets its BM by calling the following:

=
build_methodology *BuildMethodology::stay_in_current_process(void) {
	return BuildMethodology::new(NULL, FALSE, INTERNAL_METHODOLOGY);
}
