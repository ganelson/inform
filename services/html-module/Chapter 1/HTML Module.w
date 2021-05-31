[HTMLModule::] HTML Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//,
and contains no code of interest. The following constant exists only in tools
which use this module:

@d HTML_MODULE TRUE

@ Like all modules, this one must define a |start| and |end| function; the
following have been thoroughly debugged and only rarely give trouble --

@e DOC_FRAGMENT_MREASON

=
void HTMLModule::start(void) {
	Memory::reason_name(DOC_FRAGMENT_MREASON, "documentation fragments");
}

void HTMLModule::end(void) {
}

@

@e documentation_ref_CLASS

=
DECLARE_CLASS(documentation_ref)
