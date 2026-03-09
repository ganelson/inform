[ArchModule::] Arch Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d ARCH_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

=
void ArchModule::start(void) {
	Architectures::create();
	TargetVMs::create();
}

void ArchModule::end(void) {
}
