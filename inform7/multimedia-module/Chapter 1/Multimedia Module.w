[MultimediaModule::] Multimedia Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d MULTIMEDIA_MODULE TRUE

@ This module defines the following classes:

@e blorb_figure_CLASS
@e blorb_sound_CLASS
@e external_file_CLASS

=
DECLARE_CLASS(blorb_figure)
DECLARE_CLASS(blorb_sound)
DECLARE_CLASS(external_file)

@ Like all modules, this one must define a |start| and |end| function:

@e FIGURE_CREATIONS_DA

=
void MultimediaModule::start(void) {
	Log::declare_aspect(FIGURE_CREATIONS_DA, L"figure creations", FALSE, FALSE);
}
void MultimediaModule::end(void) {
}
