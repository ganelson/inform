[MultimediaModule::] Multimedia Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d MULTIMEDIA_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function.

Note that the "multimedia" feature itself does nothing except to be a parent
to the other three; it doesn't even have an activation function.

@e MULTIMEDIA_CREATIONS_DA

=
compiler_feature *multimedia_feature, *figures_feature, *sounds_feature,
	*files_feature, *internal_files_feature;

void MultimediaModule::start(void) {
	multimedia_feature = Features::new(NULL, I"multimedia", NULL);
	figures_feature = Features::new(&Figures::start, I"figures",
		multimedia_feature);
	sounds_feature = Features::new(&Sounds::start, I"sounds",
		multimedia_feature);
	files_feature = Features::new(&ExternalFiles::start, I"glulx external files",
		multimedia_feature);
	internal_files_feature = Features::new(&InternalFiles::start, I"glulx internal files",
		multimedia_feature);

	Log::declare_aspect(MULTIMEDIA_CREATIONS_DA, L"figure creations", FALSE, FALSE);
}
void MultimediaModule::end(void) {
}
