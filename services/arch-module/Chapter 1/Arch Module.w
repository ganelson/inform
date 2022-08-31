[ArchModule::] Arch Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d ARCH_MODULE TRUE

@ This module defines the following classes:

@e inter_architecture_CLASS
@e target_vm_CLASS
@e compatibility_specification_CLASS
@e compiler_feature_CLASS

=
DECLARE_CLASS(inter_architecture)
DECLARE_CLASS(target_vm)
DECLARE_CLASS(compatibility_specification)
DECLARE_CLASS(compiler_feature)

@ Like all modules, this one must define a |start| and |end| function:

=
void ArchModule::start(void) {
	Architectures::create();
	TargetVMs::create();
}

void ArchModule::end(void) {
}
