[RuntimeModule::] Runtime Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d RUNTIME_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function:

@e EMIT_ARRAY_MREASON
@e PARTITION_MREASON
@e RELATION_CONSTRUCTION_MREASON

=
void RuntimeModule::start(void) {
	Phrases::Phrasal::start();
	Phrases::Condition::start();
	Phrases::RawPhrasal::start();
	Phrases::RawCondition::start();
	Memory::reason_name(EMIT_ARRAY_MREASON, "emitter array storage");
	Memory::reason_name(PARTITION_MREASON, "initial state for relations in groups");
	Memory::reason_name(RELATION_CONSTRUCTION_MREASON, "relation bitmap storage");
}
void RuntimeModule::end(void) {
}

void RuntimeModule::compile_debugging_runtime_data_1(void) {
	PluginCalls::compile_runtime_data(1, TRUE);
}

void RuntimeModule::compile_runtime_data_1(void) {
	PluginCalls::compile_runtime_data(1, FALSE);
}

void RuntimeModule::compile_debugging_runtime_data_2(void) {
	PluginCalls::compile_runtime_data(2, TRUE);
}

void RuntimeModule::compile_runtime_data_2(void) {
	PluginCalls::compile_runtime_data(2, FALSE);
}

void RuntimeModule::compile_debugging_runtime_data_3(void) {
	PluginCalls::compile_runtime_data(3, TRUE);
}

void RuntimeModule::compile_runtime_data_3(void) {
	PluginCalls::compile_runtime_data(3, FALSE);
}

void RuntimeModule::compile_debugging_runtime_data_4(void) {
	PluginCalls::compile_runtime_data(4, TRUE);
}

void RuntimeModule::compile_runtime_data_4(void) {
	PluginCalls::compile_runtime_data(4, FALSE);
}
