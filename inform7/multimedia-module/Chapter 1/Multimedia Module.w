[MultimediaModule::] Multimedia Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d MULTIMEDIA_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function.

Note that the "multimedia" plugin itself does nothing except to be a parent
to the other three; it doesn't even have an activation function.

@e MULTIMEDIA_CREATIONS_DA

=
plugin *multimedia_plugin, *figures_plugin, *sounds_plugin, *files_plugin;

void MultimediaModule::start(void) {
	multimedia_plugin = PluginManager::new(NULL, I"multimedia", NULL);
	figures_plugin = PluginManager::new(&Figures::start, I"figures",
		multimedia_plugin);
	sounds_plugin = PluginManager::new(&Sounds::start, I"sounds",
		multimedia_plugin);
	files_plugin = PluginManager::new(&ExternalFiles::start, I"glulx external files",
		multimedia_plugin);

	Log::declare_aspect(MULTIMEDIA_CREATIONS_DA, L"figure creations", FALSE, FALSE);
}
void MultimediaModule::end(void) {
}
