[CallingFunctions::] Compile Invocations As Calls.

An invocation defined with Inform 7 source text is made with an Inter function call.

@ Compiling an invocation into a call to an Inter function is simple enough:

=
void CallingFunctions::csi_by_call(value_holster *VH, parse_node *inv,
	source_location *where_from, tokens_packet *tokens) {

	id_body *idb = Node::get_phrase_invoked(inv);

	inter_name *IS = PhraseRequests::complex_request(idb, tokens->fn_kind,
		Node::get_kind_variable_declarations(inv), Node::get_text(inv));
	LOGIF(MATCHING, "Calling function %n with kind %u from $e\n", IS,
		tokens->fn_kind, inv);

	int options_supplied = Invocations::get_phrase_options_bitmap(inv);
	if (Node::get_phrase_options_invoked(inv) == NULL) options_supplied = -1;

	if (VH->vhmode_wanted == INTER_VAL_VHMODE) VH->vhmode_provided = INTER_VAL_VHMODE;
	else VH->vhmode_provided = INTER_VOID_VHMODE;
	CallingFunctions::direct_function_call(tokens, IS, options_supplied);
}

@ The following can be used to call any phrase compiled to an I6 routine,
and it's used not only by the code above, but also when calling a
phrase value stored dynamically at run-time.

=
void CallingFunctions::direct_function_call(tokens_packet *tokens, inter_name *identifier,
	int phrase_options) {
	kind *return_kind = NULL;
	@<Compute the return kind of the phrase@>;

	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(DEREFERENCE_POINTERS_CMODE);

	Produce::inv_call_iname(Emit::tree(), identifier);
	Produce::down(Emit::tree());
		@<Emit the comma-separated list of arguments@>;
	Produce::up(Emit::tree());

	END_COMPILATION_MODE;
}

@<Compute the return kind of the phrase@> =
	kind *K = tokens->fn_kind;
	if (Kinds::get_construct(K) != CON_phrase) internal_error("no function kind");
	Kinds::binary_construction_material(K, NULL, &return_kind);

@ If the return kind stores values on the heap, we must call the function with
a pointer to a new value of that kind as the first argument. Arguments corresponding
to the tokens then follow, and finally the optional bitmap of phrase options.

@<Emit the comma-separated list of arguments@> =
	if (Kinds::Behaviour::uses_pointer_values(return_kind))
		Frames::emit_new_local_value(return_kind);
	for (int k=0; k<tokens->tokens_count; k++)
		CompileSpecifications::to_code_val_promoting(tokens->token_vals[k], tokens->token_kinds[k]);
	if (phrase_options != -1)
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) phrase_options);

@ The indirect version of the function is used when a function whose address
is not known at compile time must be called; this is needed in a few inline
invocations.

=
void CallingFunctions::indirect_function_call(tokens_packet *tokens,
	parse_node *indirect_spec, int lookup_flag) {
	kind *return_kind = NULL;
	@<Compute the return kind of the phrase@>;

	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(DEREFERENCE_POINTERS_CMODE);

	int arity = tokens->tokens_count;
	if (Kinds::Behaviour::uses_pointer_values(return_kind)) arity++;
	switch (arity) {
		case 0: Produce::inv_primitive(Emit::tree(), INDIRECT0_BIP); break;
		case 1: Produce::inv_primitive(Emit::tree(), INDIRECT1_BIP); break;
		case 2: Produce::inv_primitive(Emit::tree(), INDIRECT2_BIP); break;
		case 3: Produce::inv_primitive(Emit::tree(), INDIRECT3_BIP); break;
		case 4: Produce::inv_primitive(Emit::tree(), INDIRECT4_BIP); break;
		default: internal_error("indirect function call with too many arguments");
	}
	Produce::down(Emit::tree());
	if (lookup_flag) {
		Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
		Produce::down(Emit::tree());
			CompileSpecifications::to_code_val(K_value, indirect_spec);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
	} else {
		CompileSpecifications::to_code_val(K_value, indirect_spec);
	}
	int phrase_options = -1;
	@<Emit the comma-separated list of arguments@>;
	Produce::up(Emit::tree());

	END_COMPILATION_MODE;
}
