[MultimediaModule::] Multimedia Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d MULTIMEDIA_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e blorb_figure_CLASS
@e blorb_sound_CLASS
@e external_file_CLASS

=
DECLARE_CLASS(blorb_figure)
DECLARE_CLASS(blorb_sound)
DECLARE_CLASS(external_file)

@ Like all modules, this one must define a |start| and |end| function:

=
void MultimediaModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
}
void MultimediaModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	;

@<Register this module's debugging log aspects@> =
	;

@<Register this module's debugging log writers@> =
	;
