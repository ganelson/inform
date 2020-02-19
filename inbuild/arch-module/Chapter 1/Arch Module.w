[ArchModule::] Arch Module.

Setting up the use of this module.

@h Introduction.

@d ARCH_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e inter_architecture_MT
@e target_vm_MT
@e compatibility_specification_MT
@e semantic_version_number_holder_MT

=
ALLOCATE_INDIVIDUALLY(inter_architecture)
ALLOCATE_INDIVIDUALLY(target_vm)
ALLOCATE_INDIVIDUALLY(compatibility_specification)
ALLOCATE_INDIVIDUALLY(semantic_version_number_holder)

@h The beginning.

=
void ArchModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
	Architectures::create();
	TargetVMs::create();
}

@

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	;

@

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;

@<Register this module's command line switches@> =
	;

@h The end.

=
void ArchModule::end(void) {
}
