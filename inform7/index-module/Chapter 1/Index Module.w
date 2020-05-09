[IndexModule::] Index Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INDEX_MODULE TRUE

@ This module defines the following classes:

@e documentation_ref_CLASS
@e index_page_CLASS
@e index_element_CLASS
@e lexicon_entry_CLASS

=
DECLARE_CLASS(documentation_ref)
DECLARE_CLASS(index_element)
DECLARE_CLASS(index_page)
DECLARE_CLASS(lexicon_entry)

@ Like all modules, this one must define a |start| and |end| function:

=
void IndexModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}
void IndexModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;
