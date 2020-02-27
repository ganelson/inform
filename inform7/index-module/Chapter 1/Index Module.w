[IndexModule::] Index Module.

Setting up the use of this module.

@h Introduction.

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

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void IndexModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;

@h The end.

=
void IndexModule::end(void) {
}
