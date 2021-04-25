[CoreModule::] Core Module.

Setting up the use of this module.

@ The following constant exists only in tools which use this module:

@d CORE_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function.

Note that the "core" plugin itself does nothihg except to be a parent to the
other two; it doesn't even have an activation function.

@e TASK_QUEUE_DA

=
plugin *core_plugin, *naming_plugin, *counting_plugin;

void CoreModule::start(void) {
	core_plugin = PluginManager::new(NULL, I"core", NULL);
	PluginManager::make_permanently_active(core_plugin);
	naming_plugin = PluginManager::new(&Naming::start, I"naming", core_plugin);
	counting_plugin = PluginManager::new(&PL::Counting::start, I"instance counting", core_plugin);

	Log::declare_aspect(TASK_QUEUE_DA, L"task queue", FALSE, FALSE);

	Writers::register_writer_I('B', &CoreModule::writer);
	CorePreform::set_core_internal_NTIs();
	CoreSyntax::declare_annotations();
}
void CoreModule::end(void) {
}

@ The |%B| string escape prints the build number, lying about it when we
want to produce predictable output for easier testing.

=
void CoreModule::writer(OUTPUT_STREAM, char *format_string, int wn) {
	if (Time::fixed()) {
		if (wn) WRITE("9Z99");
		else WRITE("Inform 7.99.99");
	} else {
		if (wn) WRITE("[[Build Number]]");
		else WRITE("Inform [[Version Number]]");
	}
}
