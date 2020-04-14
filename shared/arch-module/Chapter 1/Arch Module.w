[ArchModule::] Arch Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d ARCH_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e inter_architecture_MT
@e target_vm_MT
@e compatibility_specification_MT

=
ALLOCATE_INDIVIDUALLY(inter_architecture)
ALLOCATE_INDIVIDUALLY(target_vm)
ALLOCATE_INDIVIDUALLY(compatibility_specification)

@ Like all modules, this one must define a |start| and |end| function:

=
void ArchModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	Architectures::create();
	TargetVMs::create();
}
void ArchModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;
