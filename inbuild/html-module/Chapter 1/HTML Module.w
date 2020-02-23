[HTMLModule::] Index Module.

Setting up the use of this module.

@h Introduction.

@d HTML_MODULE TRUE

@ To begin with, this module needs to allocate memory:

=

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void HTMLModule::start(void) {
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;
}

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;

@<Register this module's command line switches@> =
	;

@h The end.

=
void HTMLModule::end(void) {
}
