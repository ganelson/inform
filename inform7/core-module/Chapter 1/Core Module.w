[CoreModule::] Core Module.

Setting up the use of this module.

@ The following constant exists only in tools which use this module:

@d CORE_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function.

Note that the "core" feature itself does nothing except to be a parent to the
other two; it doesn't even have an activation function.

The "experimental features" feature is similarly an umbrella for any features
being used to test out half-implemented compiler functionality before it's ready
to be part of a released version.

@e TASK_QUEUE_DA
@e INTER_DA
@e INFORM_INTER_DA

=
compiler_feature *core_feature, *naming_feature, *counting_feature, *experimental_feature;

void CoreModule::start(void) {
	core_feature = Features::new(NULL, I"core", NULL);
	Features::make_permanently_active(core_feature);
	naming_feature = Features::new(&Naming::start, I"naming", core_feature);
	counting_feature = Features::new(&InstanceCounting::start, I"instance counting", core_feature);

	experimental_feature = Features::new(NULL, I"experimental features", NULL);

	Log::declare_aspect(TASK_QUEUE_DA, L"task queue", FALSE, FALSE);
	Log::declare_aspect(INTER_DA, L"inter", FALSE, FALSE);
	Log::declare_aspect(INFORM_INTER_DA, L"inform inter", FALSE, FALSE);

	Writers::register_writer_I('B', &CoreModule::writer);
	CorePreform::set_core_internal_NTIs();
	CoreSyntax::declare_annotations();
	InternalTests::begin();
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
