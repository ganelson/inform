[Invocations::AsCalls::] Compile Invocations As Calls.

Here we generate Inform 6 code to execute the phrase(s) called
for by an invocation list.

@ Compiling an invocation by a function call is simple:

=
void Invocations::AsCalls::csi_by_call(value_holster *VH, parse_node *inv,
	source_location *where_from, tokens_packet *tokens) {
	id_body *idb = Node::get_phrase_invoked(inv);

	inter_name *IS = Routines::Compile::iname(idb,
		PhraseRequests::make_request(idb, tokens->as_requested,
			Node::get_kind_variable_declarations(inv), Node::get_text(inv)));
	LOGIF(MATCHING, "Calling routine %n with kind %u from $e\n", IS,
		tokens->as_requested, inv);

	int options_supplied = Invocations::get_phrase_options_bitmap(inv);
	if (Node::get_phrase_options_invoked(inv) == NULL) options_supplied = -1;

	if (VH->vhmode_wanted == INTER_VAL_VHMODE) VH->vhmode_provided = INTER_VAL_VHMODE;
	else VH->vhmode_provided = INTER_VOID_VHMODE;
	Invocations::AsCalls::emit_function_call(tokens, IS, options_supplied, NULL, FALSE);
}

@ The following can be used to call any phrase compiled to an I6 routine,
and it's used not only by the code above, but also when calling a
phrase value stored dynamically at run-time.

=
void Invocations::AsCalls::emit_function_call(
	tokens_packet *tokens, inter_name *identifier, int phrase_options,
	parse_node *indirect_spec, int lookup_flag) {

	kind *return_kind = NULL;
	@<Compute the return kind of the phrase@>;

	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(DEREFERENCE_POINTERS_CMODE);

	if (identifier) {
		Produce::inv_call_iname(Emit::tree(), identifier);
		Produce::down(Emit::tree());
	} else if (indirect_spec) {
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
				Specifications::Compiler::emit_as_val(K_value, indirect_spec);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
			Produce::up(Emit::tree());
		} else {
			Specifications::Compiler::emit_as_val(K_value, indirect_spec);
		}
	} else internal_error("emit function call improperly called");
		@<Emit the comma-separated list of arguments@>;
	Produce::up(Emit::tree());

	END_COMPILATION_MODE;
}

@ See the corresponding code for defining routines. If the return value of
the phrase is a block value, we must call it with a pointer to a new value
of that kind as the first argument. Arguments corresponding to the tokens
then follow, and finally the optional bitmap of phrase options.

@<Emit the comma-separated list of arguments@> =
	if (Kinds::Behaviour::uses_pointer_values(return_kind))
		Frames::emit_new_local_value(return_kind);
	for (int k=0; k<tokens->tokens_count; k++)
		Specifications::Compiler::emit_to_kind(tokens->args[k], tokens->kind_required[k]);
	if (phrase_options != -1)
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) phrase_options);

@<Compute the return kind of the phrase@> =
	kind *K = tokens->as_requested;
	kind *args = NULL;
	if (Kinds::get_construct(K) != CON_phrase) internal_error("no function kind");
	Kinds::binary_construction_material(K, &args, &return_kind);
