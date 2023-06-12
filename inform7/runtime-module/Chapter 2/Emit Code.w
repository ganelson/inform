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
	Produce::guard(CommentInstruction::new(EmitCode::at(), text, NULL,
		(inter_ti) EmitCode::level()));
}

@h Provenance markers.

=
void EmitCode::provenance(text_provenance from) {
	Produce::provenance(Emit::tree(), from);
}

@h In value context.
These functions all generate a |val| opcode:

=
void EmitCode::val_number(inter_ti N) {
	Produce::val(Emit::tree(), K_number, InterValuePairs::number(N));
}

void EmitCode::val_true(void) {
	Produce::val(Emit::tree(), K_truth_state, InterValuePairs::number(1));
}

void EmitCode::val_false(void) {
	Produce::val(Emit::tree(), K_truth_state, InterValuePairs::number(0));
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

@h Either/or property testing.
This compiles code for the test |N has prn|, that is, compiles a condition
which is true if the value of |prn| for |N| is |true|, and correspondingly
false for |false|.

=
void EmitCode::test_if_iname_has_property(kind *K, inter_name *N, property *prn) {
	EmitCode::test_if_symbol_has_property(K, InterNames::to_symbol(N), prn);
}
void EmitCode::test_if_symbol_has_property(kind *K, inter_symbol *S, property *prn) {
	if (RTProperties::stored_in_negation(prn)) {
		EmitCode::inv(NOT_BIP);
		EmitCode::down();
			EmitCode::inv(PROPERTYVALUE_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
				EmitCode::val_symbol(K, S);
				EmitCode::val_iname(K_value,
					RTProperties::iname(EitherOrProperties::get_negation(prn)));
			EmitCode::up();
		EmitCode::up();
	} else {
		EmitCode::inv(PROPERTYVALUE_BIP);
		EmitCode::down();
			EmitCode::val_iname(K_value, RTKindIDs::weak_iname(K_object));
			EmitCode::val_symbol(K, S);
			EmitCode::val_iname(K_value, RTProperties::iname(prn));
		EmitCode::up();
	}
}

@h Casts.
These are value conversions from one kind to another. In some simple cases,
this can be achieved with an Inter |cast|:

=
void EmitCode::cast(kind *F, kind *T) {
	Produce::cast(Emit::tree(), F, T);
}

@ This allows more complex cases, though:

=
int EmitCode::cast_possible(kind *F, kind *T) {
	F = Kinds::weaken(F, K_object);
	T = Kinds::weaken(T, K_object);
	if ((T) && (F) && (T->construct != F->construct) &&
		(Kinds::Behaviour::definite(T)) && (Kinds::Behaviour::definite(F)) &&
		(Kinds::eq(F, K_object) == FALSE) &&
		(Kinds::eq(T, K_object) == FALSE) &&
		(T->construct != CON_property))
		return TRUE;
	return FALSE;
}

@ Casts are in many cases implicit, so that nothing need be done, and the
following simply returns |TRUE| to indicate success. But in a few cases, a
function call must be inserted, with a name like |SNIPPET_TY_to_TEXT_TY|;
in such cases, this function must exist in the kits somewhere.

=
int EmitCode::casting_call(kind *F, kind *T, int *down) {
	if (EmitCode::cast_possible(F, T)) {
		if (Str::len(Kinds::Behaviour::get_identifier(T)) == 0) {
			return TRUE;
		}
		if ((Kinds::FloatingPoint::uses_floating_point(F)) &&
			(Kinds::FloatingPoint::uses_floating_point(T))) {
			return TRUE;
		}
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "%S_to_%S",
			Kinds::Behaviour::get_identifier(F),
			Kinds::Behaviour::get_identifier(T));
		inter_name *iname = HierarchyLocations::find_by_name(Emit::tree(), N);
		DISCARD_TEXT(N)
		EmitCode::call(iname);
		*down = TRUE;
		EmitCode::down();
		if (Kinds::Behaviour::uses_block_values(T)) Frames::emit_new_local_value(T);
		return TRUE;
	}
	return FALSE;
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
	Produce::inv_call_symbol(Emit::tree(), S);
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

