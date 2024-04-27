[Closures::] Closures.

To provide the names of phrases as first-class values.

@ Phrases which have been given names can be used as first-class values in
Inform, meaning that they can be stored in variables, have a kind which can
be expressed in Inform source text, and so on.

At runtime, it might be expected that such a constant would be stored just as
the address of the function. In fact it is stored as (the address of) a small
fixed-size array called a "closure", which does include the function address,
but also some metadata about it.

In the theory of compilers, the term "closure" is usually used more ambitiously
than this, in that closures "capture" references to local variables, thus enabling
"closed" functions to be made out of fragments occurring inside code. For example,
in the Swift programming language:
= (text)
	var threshold = 10
	let fn = { x in return x > threshold }
	return fn
=
a nameless function has been made with |{ x in return x > threshold }| which
includes a reference to a local variable not part of its own definition, i.e.,
|threshold|. A reference to this must be "captured" and salted away in the
closure data, since otherwise by the time the |fn| value is used, |threshold|
will not exist.

This issue does not arise for Inform because, at present, there is no lambda
operator, or syntax like Swift's |{ x in ... }|, for making one phrase inside
the body of another one.[1] So we never need capture anything, and phrases are
never half-open and so in that sense do not need closing, but we will continue
to use the flattering term "closure" anyway.

[1] Unless you count text substitutions, where exactly this issue of capturing
values does arise.

@ This returns the iname for a closure array for |cphr|. Since each phrase can
have at most one closure, and they occupy little memory, we do not need to
create or destroy them dynamically as small blocks: we can simply store them
in memory at known locations, and the iname here refers to that location.

=
inter_name *Closures::iname(constant_phrase *cphr) {
	if (cphr->cphr_iname == NULL) {
		id_body *idb = ToPhraseFamily::body_of_constant(cphr);
		if (idb == NULL) internal_error("cannot reconstruct phrase from cphr");
		package_request *P = Hierarchy::package_within(CLOSURES_HAP,
			CompileImperativeDefn::requests_package(idb));
		cphr->cphr_iname = Hierarchy::make_iname_in(CLOSURE_DATA_HL, P);
	}
	return cphr->cphr_iname;
}

@ And this is where those arrays are made:

=
void Closures::compile_closures(void) {
	constant_phrase *cphr;
	LOOP_OVER(cphr, constant_phrase) {
		id_body *idb = ToPhraseFamily::body_of_constant(cphr);
		if (idb == NULL) internal_error("cannot reconstruct phrase from cphr");
		ToPhraseFamily::kind(cphr);
		@<Compile the closure array for this constant phrase@>;
	}
}

@ The closure array consists of three words: the strong kind ID, the address
of the function, and the text of the name. (The latter enables us to print
phrase values efficiently.) Note that we make a compilation request for the
phrase in order to make sure somebody has actually compiled it: this is in
case the phrase occurs as a constant but is never explicitly invoked, as here --
= (text as Inform 7)
To decide which number is (N - a number) doubled (this is doubling):
	decide on N + N.
To begin:
	let L be { 2, 3, 5, 7, 11 };
	say "Doubling produces [doubling applied to L]."
=
In this source text, there is never an explicit invocation such as "4 doubled",
but the fact that the phrase has been given the name "doubling" is enough to
ensure that the closure array for it is compiled, and that forces a request
for the underlying function's compilation.

@<Compile the closure array for this constant phrase@> =
	inter_name *iname = Closures::iname(cphr);
	packaging_state save = EmitArrays::begin_word(iname, K_value);

	RTKindIDs::strong_ID_array_entry(cphr->cphr_kind);

	inter_name *RS = PhraseRequests::simple_request(idb, ToPhraseFamily::kind(cphr));
	EmitArrays::iname_entry(RS);

	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%W", Nouns::nominative_singular(cphr->name));
	EmitArrays::text_entry(name);
	DISCARD_TEXT(name)

	EmitArrays::end(save);

@ Now we come to something trickier. We want default values for kinds of phrases,
because otherwise we can't have variables holding phrases unless they are
always initialised explicitly, and so on. Clearly the default value for a
phrase to nothing is one that does nothing, and for a phrase to some kind K
is one that returns the default value of kind K. For example, the default
value of
= (text)
	phrase (text, time) -> number
=
is the function which takes any pair of a text and a time, does nothing with
them, and always returns the default number, i.e., 0. But this means we need
to actually compile such functions. Since there are in principle an infinite
number of distinct phrase kinds, we will only compile them for the phrase kinds
which actually arise during compilation.

The following function is called exactly once for each such kind |K|.

=
typedef struct default_closure_request {
	struct inter_name *closure_identifier;
	struct kind *K;
	CLASS_DEFINITION
} default_closure_request;

void Closures::compile_default_closure(inter_name *closure_identifier, kind *K) {
	text_stream *desc = Str::new();
	WRITE_TO(desc, "default closure for %u", K);
	default_closure_request	*dcr = CREATE(default_closure_request);
	dcr->closure_identifier = closure_identifier;
	dcr->K = K;
	Sequence::queue(&Closures::compilation_agent, STORE_POINTER_default_closure_request(dcr), desc);
}

@ And the actual compilation is done here, when we can be certain that no other
function is being compiled at the same time.

=
void Closures::compilation_agent(compilation_subtask *t) {
	default_closure_request	*dcr = RETRIEVE_POINTER_default_closure_request(t->data);
	package_request *P = RTKindConstructors::kind_package(dcr->K);
	inter_name *rname = Hierarchy::make_iname_in(DEFAULT_CLOSURE_FN_HL, P);
	@<Compile the default function@>;
	@<Compile its closure@>;
}

@<Compile the default function@> =
	packaging_state save = Functions::begin(rname);
	LocalVariables::new_other_parameter(I"a");
	LocalVariables::new_other_parameter(I"b");
	LocalVariables::new_other_parameter(I"c");
	LocalVariables::new_other_parameter(I"d");
	LocalVariables::new_other_parameter(I"e");
	LocalVariables::new_other_parameter(I"f");
	LocalVariables::new_other_parameter(I"g");
	LocalVariables::new_other_parameter(I"h");
	kind *result = NULL;
	Kinds::binary_construction_material(dcr->K, NULL, &result);
	if (Kinds::get_construct(result) != CON_NIL) {
		EmitCode::inv(RETURN_BIP);
		EmitCode::down();

		if (Kinds::Behaviour::uses_block_values(result)) {
			inter_name *iname = Hierarchy::find(CREATEPV_HL);
			EmitCode::call(iname);
			EmitCode::down();
			RTKindIDs::emit_strong_ID_as_val(result);
			EmitCode::up();
		} else {
			if (DefaultValues::val(result, EMPTY_WORDING, NULL) != TRUE)
				EmitCode::val_number(0);
		}

		EmitCode::up();
	}
	Functions::end(save);

@<Compile its closure@> =
	packaging_state save = EmitArrays::begin_word(dcr->closure_identifier, K_value);
	RTKindIDs::strong_ID_array_entry(dcr->K);
	EmitArrays::iname_entry(rname);
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "default value of "); Kinds::Textual::write(DVT, dcr->K);
	EmitArrays::text_entry(DVT);
	DISCARD_TEXT(DVT)
	EmitArrays::end(save);
