[BuildMethodology::] Build Methodology.

Whether to run tasks internally in some merged tool, or run via the shell, or
simply trace to the standard output what we think ought to be done.

@

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

build_methodology *BuildMethodology::new(pathname *tools_path, int dev) {
	build_methodology *meth = CREATE(build_methodology);
	meth->methodology = DRY_RUN_METHODOLOGY;
	pathname *inter_path = tools_path;
	if (dev) {
		inter_path = Pathnames::subfolder(inter_path, I"inter");
		inter_path = Pathnames::subfolder(inter_path, I"Tangled");
	}
	meth->to_inter = Filenames::in_folder(inter_path, I"inter");
	pathname *inform6_path = tools_path;
	if (dev) {
		inform6_path = Pathnames::subfolder(inform6_path, I"inform6");
		inform6_path = Pathnames::subfolder(inform6_path, I"Tangled");
	}
	meth->to_inform6 = Filenames::in_folder(inform6_path, I"inform6");
	pathname *inform7_path = tools_path;
	if (dev) {
		inform7_path = Pathnames::subfolder(inform7_path, I"inform7");
		inform7_path = Pathnames::subfolder(inform7_path, I"Tangled");
	}
	meth->to_inform7 = Filenames::in_folder(inform7_path, I"inform7");
	pathname *inblorb_path = tools_path;
	if (dev) {
		inblorb_path = Pathnames::subfolder(inblorb_path, I"inblorb");
		inblorb_path = Pathnames::subfolder(inblorb_path, I"Tangled");
	}
	meth->to_inblorb = Filenames::in_folder(inblorb_path, I"inblorb");
	return meth;
}
