[IndexModule::] Index Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d INDEX_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e documentation_ref_MT
@e index_page_MT
@e index_element_MT
@e lexicon_entry_MT

=
ALLOCATE_INDIVIDUALLY(documentation_ref)
ALLOCATE_INDIVIDUALLY(index_element)
ALLOCATE_INDIVIDUALLY(index_page)
ALLOCATE_INDIVIDUALLY(lexicon_entry)

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
