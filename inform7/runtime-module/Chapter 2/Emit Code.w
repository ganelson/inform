[EmitCode::] Emit Code.

Here is how bytecode for instructions inside functions is emitted.

@h Introduction.
Many sections of //runtime// need to create functions by explicitly giving
their bytecode. This is quite verbose, but with practice easy enough to read.
For example, here's bytecode equivalent to |return 13|:
= (text as InC)
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		EmitCode::val_number(13);
	EmitCode::up();
=
We conventionally indent this code to reflect the structure of what is being
generated, so that the source code in this module looks like the Inter tree
structure which emerges.

@h Where bytecode comes out.
We are generating a hierarchical structure and not a stream, so we need the
ability to move the point at which new opcodes are being spawned. This is
that point

=
inter_bookmark *EmitCode::at(void) {
	return Produce::at(Emit::tree());
}

@ These should always be used in ways guaranteed to match:
(*) //EmitCode::down// shifts us so that we are now creating bytecode below the
instruction last emitted, not after it.
(*) //EmitCode::up// then returns us back to where we were.

=
void EmitCode::up(void) {
	Produce::up(Emit::tree());
}
void EmitCode::down(void) {
	Produce::down(Emit::tree());
}

@ And this returns the current depth of nesting, that is, how many downs we
have made, net:

=
int EmitCode::level(void) {
	return Produce::level(Emit::tree());
}

@h Structural.

=
void EmitCode::code(void) {
	Produce::code(Emit::tree());
}

void EmitCode::reference(void) {
	Produce::reference(Emit::tree());
}

@h Comments.
Note that these can only safely be made in void context: for example, at the
start of a function.

=
void EmitCode::comment(text_stream *text) {
	if (Functions::a_function_is_being_compiled() == FALSE)
		internal_error("code comment emitted outside function");
	inter_ti ID = Inter::Warehouse::create_text(Emit::warehouse(), Emit::package());
	Str::copy(Inter::Warehouse::get_text(Emit::warehouse(), ID), text);
	Produce::guard(Inter::Comment::new(EmitCode::at(),
		(inter_ti) EmitCode::level(), NULL, ID));
}

@h In value context.
These functions all generate a |val| opcode:

=
void EmitCode::val_number(inter_ti N) {
	Produce::val(Emit::tree(), K_number, LITERAL_IVAL, N);
}

void EmitCode::val_true(void) {
	Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 1);
}

void EmitCode::val_false(void) {
	Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
}

void EmitCode::val_iname(kind *K, inter_name *iname) {
	Produce::val_iname(Emit::tree(), K, iname);
}

void EmitCode::val_text(text_stream *text) {
	Produce::val_text(Emit::tree(), text);
}

void EmitCode::val_dword(text_stream *text) {
	Produce::val_dword(Emit::tree(), text);
}

void EmitCode::val_real(double g) {
	Produce::val_real(Emit::tree(), g);
}

void EmitCode::val_nothing(void) {
	Produce::val_nothing(Emit::tree());
}

void EmitCode::val_symbol(kind *K, inter_symbol *S) {
	Produce::val_symbol(Emit::tree(), K, S);
}

@ Whereas this produces a |cast|:

=
void EmitCode::cast(kind *F, kind *T) {
	Produce::cast(Emit::tree(), F, T);
}

@h In reference context.
And these produce a |ref|:

=
void EmitCode::ref_iname(kind *K, inter_name *iname) {
	Produce::ref_iname(Emit::tree(), K, iname);
}

void EmitCode::ref_symbol(kind *K, inter_symbol *S) {
	Produce::ref_symbol(Emit::tree(), K, S);
}

@h Invocations.
These three produce |inv| opcodes:

=
void EmitCode::inv(inter_ti bip) {
	Produce::inv_primitive(Emit::tree(), bip);
}

void EmitCode::call(inter_name *fn_iname) {
	Produce::inv_call_iname(Emit::tree(), fn_iname);
}

void EmitCode::call_symbol(inter_symbol *S) {
	Produce::inv_call(Emit::tree(), S);
}

@ These conveniences functions produce an invocation and argument all in one,
so they generate several opcodes. Here we return |true| or |false| from the
current function:

=
void EmitCode::rtrue(void) {
	Produce::rtrue(Emit::tree());
}

void EmitCode::rfalse(void) {
	Produce::rfalse(Emit::tree());
}

@ And here we pull or pull a global variable to or from the Inter call stack:

=
void EmitCode::push(inter_name *iname) {
	Produce::push(Emit::tree(), iname);
}

void EmitCode::pull(inter_name *iname) {
	Produce::pull(Emit::tree(), iname);
}

@h Labels.
Labels can be referred to before they are defined, but must be reserved in
advance:

=
inter_symbol *EmitCode::reserve_label(text_stream *identifier) {
	return Produce::reserve_label(Emit::tree(), identifier);
}

void EmitCode::place_label(inter_symbol *lab_s) {
	Produce::place_label(Emit::tree(), lab_s);
}

void EmitCode::lab(inter_symbol *L) {
	Produce::lab(Emit::tree(), L);
}
