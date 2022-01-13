[GenericModule::] Generic Module.

A variety of Inter constants which do not depend on the content of the program.

@ =
void GenericModule::compile(void) {
	Emit::rudimentary_kinds();
	target_vm *VM = Task::vm();
	if (VM == NULL) internal_error("target VM not set yet");
	LargeScale::make_architectural_definitions(Emit::tree(),
		TargetVMs::get_architecture(VM), unchecked_interk);
	RTVerbs::compile_generic_constants();
	RTCommandGrammars::compile_generic_constants();
	RTPlayer::compile_generic_constants();
	RTRelations::compile_generic_constants();
}
