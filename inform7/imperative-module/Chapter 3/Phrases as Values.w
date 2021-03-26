[Phrases::Constants::] Phrases as Values.

To provide the names of phrases as first-class values.

@ A few "To..." phrases have names, and can therefore be used as values in their
own right, a functional-programming sort of device. For example:

>> To decide what number is double (N - a number) (this is doubling):

has the name "doubling". Such a name is recorded here:

=
typedef struct constant_phrase {
	struct noun *name;
	struct phrase *phrase_meant; /* if known at this point */
	struct kind *cphr_kind; /* ditto */
	struct inter_name *cphr_iname;
	struct wording associated_preamble_text;
	CLASS_DEFINITION
} constant_phrase;

@ Here we create a new named phrase ("doubling", say):

=
constant_phrase *Phrases::Constants::create(wording NW, wording RW) {
	constant_phrase *cphr = CREATE(constant_phrase);
	cphr->phrase_meant = NULL; /* we won't know until later */
	cphr->cphr_kind = NULL; /* nor this */
	cphr->associated_preamble_text = RW;
	cphr->name = Nouns::new_proper_noun(NW, NEUTER_GENDER, ADD_TO_LEXICON_NTOPT,
		PHRASE_CONSTANT_MC, Rvalues::from_constant_phrase(cphr), Task::language_of_syntax());
	cphr->cphr_iname = NULL;
	return cphr;
}

@ ...and parse for an existing one:

=
constant_phrase *Phrases::Constants::parse(wording NW) {
	if (<s-value>(NW)) {
		parse_node *spec = <<rp>>;
		if (Rvalues::is_CONSTANT_construction(spec, CON_phrase)) {
			constant_phrase *cphr = Rvalues::to_constant_phrase(spec);
			Phrases::Constants::kind(cphr);
			return cphr;
		}
	}
	return NULL;
}

@ As often happens with Inform constants, the kind of a constant phrase can't
be known when its name first comes up, and must be filled in later. (In
particular, before the second traverse many kinds do not yet exist.) So
the following takes a patch-it-later approach.

=
kind *Phrases::Constants::kind(constant_phrase *cphr) {
	if (cphr == NULL) return NULL;
	if (global_pass_state.pass < 2) return Kinds::binary_con(CON_phrase, K_value, K_value);
	if (cphr->cphr_kind == NULL) {
		wording OW = EMPTY_WORDING;
		ph_type_data phtd = Phrases::TypeData::new();
		Phrases::TypeData::Textual::parse(&phtd,
			cphr->associated_preamble_text, &OW);
		cphr->cphr_kind = Phrases::TypeData::kind(&phtd);
	}
	return cphr->cphr_kind;
}

@ And similarly for the |phrase| structure this name corresponds to.

=
phrase *Phrases::Constants::as_phrase(constant_phrase *cphr) {
	if (cphr == NULL) internal_error("null cphr");
	if (cphr->phrase_meant == NULL) {
		imperative_defn *id;
		LOOP_OVER(id, imperative_defn) {
			if (ToPhraseFamily::constant_phrase(id) == cphr) {
				cphr->phrase_meant = id->defines;
				break;
			}
		}
	}
	return cphr->phrase_meant;
}

@ So much for setting up constant phrases. Now we come to compilation, and
a surprise. It might be expected that a constant phrase compiles simply to
an I6 routine name, but no: it compiles to a small array called a "closure".

=
inter_name *Phrases::Constants::compile(constant_phrase *cphr) {
	phrase *ph = Phrases::Constants::as_phrase(cphr);
	if (ph == NULL) internal_error("cannot reconstruct phrase from cphr");
	if (Phrases::compiled_inline(ph) == FALSE)
		Routines::ToPhrases::make_request(ph,
			Phrases::Constants::kind(cphr), NULL, EMPTY_WORDING);
	return Phrases::Constants::iname(cphr);
}

inter_name *Phrases::Constants::iname(constant_phrase *cphr) {
	if (cphr->cphr_iname == NULL) {
		phrase *ph = Phrases::Constants::as_phrase(cphr);
		if (ph == NULL) internal_error("cannot reconstruct phrase from cphr");
		package_request *P = Hierarchy::package_within(CLOSURES_HAP, ph->requests_package);
		cphr->cphr_iname = Hierarchy::make_iname_in(CLOSURE_DATA_HL, P);
	}
	return cphr->cphr_iname;
}

@ And this is where those arrays are made:

=
void Phrases::Constants::compile_closures(void) {
	constant_phrase *cphr;
	LOOP_OVER(cphr, constant_phrase) {
		phrase *ph = Phrases::Constants::as_phrase(cphr);
		if (ph == NULL) internal_error("cannot reconstruct phrase from cphr");
		Phrases::Constants::kind(cphr);
		@<Compile the closure array for this constant phrase@>;
	}
}

@ The closure array consists of three words: the strong kind ID, the address
of the routine, and the text of the name. (The latter enables us to print
phrase values efficiently.) Note that we make a compilation request for the
phrase in order to make sure somebody has actually compiled it: this is in
case the phrase occurs as a constant but is never explicitly invoked.

@<Compile the closure array for this constant phrase@> =
	inter_name *iname = Phrases::Constants::iname(cphr);
	packaging_state save = Emit::named_array_begin(iname, K_value);

	RTKinds::emit_strong_id(cphr->cphr_kind);

	inter_name *RS = Routines::ToPhrases::make_iname(ph,
		Phrases::Constants::kind(cphr));
	Emit::array_iname_entry(RS);

	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%W", Nouns::nominative_singular(cphr->name));
	Emit::array_text_entry(name);
	DISCARD_TEXT(name)

	Emit::array_end(save);

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
them, and always returns 0. But this means we need to actually compile such
routines. Since there are in principle an infinite number of distinct phrase
kinds, we will only compile them for the phrase kinds which arise during
compilation.

=
void Phrases::Constants::compile_default_closure(inter_name *closure_identifier, kind *K) {
	package_request *P = Kinds::Behaviour::package(K);
	inter_name *rname = Hierarchy::make_iname_in(DEFAULT_CLOSURE_FN_HL, P);

	@<Compile the default routine@>;
	@<Compile the default closure@>;
}

@ This must have exactly the same three-word form as the closure arrays
made above.

@<Compile the default closure@> =
	packaging_state save = Emit::named_array_begin(closure_identifier, K_value);
	RTKinds::emit_strong_id(K);
	Emit::array_iname_entry(rname);
	TEMPORARY_TEXT(DVT)
	WRITE_TO(DVT, "default value of "); Kinds::Textual::write(DVT, K);
	Emit::array_text_entry(DVT);
	DISCARD_TEXT(DVT)
	Emit::array_end(save);

@ And here is the function that refers to:

@<Compile the default routine@> =
	packaging_state save = Routines::begin(rname);
	LocalVariables::add_named_call(I"a");
	LocalVariables::add_named_call(I"b");
	LocalVariables::add_named_call(I"c");
	LocalVariables::add_named_call(I"d");
	LocalVariables::add_named_call(I"e");
	LocalVariables::add_named_call(I"f");
	LocalVariables::add_named_call(I"g");
	LocalVariables::add_named_call(I"h");
	kind *result = NULL;
	Kinds::binary_construction_material(K, NULL, &result);
	if (Kinds::get_construct(result) != CON_NIL) {
		Produce::inv_primitive(Emit::tree(), RETURN_BIP);
		Produce::down(Emit::tree());

		if (Kinds::Behaviour::uses_pointer_values(result)) {
			inter_name *iname = Hierarchy::find(BLKVALUECREATE_HL);
			Produce::inv_call_iname(Emit::tree(), iname);
			Produce::down(Emit::tree());
			RTKinds::emit_strong_id_as_val(result);
			Produce::up(Emit::tree());
		} else {
			if (RTKinds::emit_default_value_as_val(result, EMPTY_WORDING, NULL) != TRUE)
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
		}

		Produce::up(Emit::tree());
	}
	Routines::end(save);
