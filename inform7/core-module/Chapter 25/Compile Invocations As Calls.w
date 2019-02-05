[Invocations::AsCalls::] Compile Invocations As Calls.

Here we generate Inform 6 code to execute the phrase(s) called
for by an invocation list.

@ Compiling an invocation by a function call is simple:

=
void Invocations::AsCalls::csi_by_call(value_holster *VH, parse_node *inv,
	source_location *where_from, tokens_packet *tokens) {
	phrase *ph = ParseTree::get_phrase_invoked(inv);

	inter_name *IS = Routines::Compile::iname(ph,
		Routines::ToPhrases::make_request(ph, tokens->as_requested,
			ParseTree::get_kind_variable_declarations(inv), ParseTree::get_text(inv)));
	LOGIF(MATCHING, "Calling routine %n with kind $u from $e\n", IS,
		tokens->as_requested, inv);

	int options_supplied = Invocations::get_phrase_options_bitmap(inv);
	if (ParseTree::get_phrase_options_invoked(inv) == NULL) options_supplied = -1;

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
		Emit::inv_call(InterNames::to_symbol(identifier));
		Emit::down();
	} else if (indirect_spec) {
		int arity = tokens->tokens_count;
		if (Kinds::Behaviour::uses_pointer_values(return_kind)) arity++;
		switch (arity) {
			case 0: Emit::inv_primitive(indirect0_interp); break;
			case 1: Emit::inv_primitive(indirect1_interp); break;
			case 2: Emit::inv_primitive(indirect2_interp); break;
			case 3: Emit::inv_primitive(indirect3_interp); break;
			case 4: Emit::inv_primitive(indirect4_interp); break;
			default: internal_error("indirect function call with too many arguments");
		}
		Emit::down();
		if (lookup_flag) {
			Emit::inv_primitive(lookup_interp);
			Emit::down();
				Specifications::Compiler::emit_as_val(K_value, indirect_spec);
				Emit::val(K_number, LITERAL_IVAL, 1);
			Emit::up();
		} else {
			Specifications::Compiler::emit_as_val(K_value, indirect_spec);
		}
	} else internal_error("emit function call improperly called");
		@<Emit the comma-separated list of arguments@>;
	Emit::up();

	END_COMPILATION_MODE;
}

@ See the corresponding code for defining routines. If the return value of
the phrase is a block value, we must call it with a pointer to a new value
of that kind as the first argument. Arguments corresponding to the tokens
then follow, and finally the optional bitmap of phrase options.

@<Emit the comma-separated list of arguments@> =
	if (Kinds::Behaviour::uses_pointer_values(return_kind))
		Frames::emit_allocation(return_kind);
	for (int k=0; k<tokens->tokens_count; k++)
		Specifications::Compiler::emit_to_kind(tokens->args[k], tokens->kind_required[k]);
	if (phrase_options != -1)
		Emit::val(K_number, LITERAL_IVAL, (inter_t) phrase_options);

@<Compute the return kind of the phrase@> =
	kind *K = tokens->as_requested;
	kind *args = NULL;
	if (Kinds::get_construct(K) != CON_phrase) internal_error("no function kind");
	Kinds::binary_construction_material(K, &args, &return_kind);
