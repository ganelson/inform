[CNamespace::] C Namespace.

How identifiers are used in the C code we generate.

@

=
void CNamespace::initialise(code_generator *cgt) {
	METHOD_ADD(cgt, MANGLE_IDENTIFIER_MTID, CNamespace::mangle);
	METHOD_ADD(cgt, DECLARE_CONSTANT_MTID, CNamespace::declare_constant);
}

void CNamespace::mangle(code_generator *cgt, OUTPUT_STREAM, text_stream *identifier) {
	if (Str::get_first_char(identifier) == '(') WRITE("%S", identifier);
	else if (Str::get_first_char(identifier) == '#') {
		WRITE("i7_ss_");
		LOOP_THROUGH_TEXT(pos, identifier)
			if ((Str::get(pos) != '#') && (Str::get(pos) != '$'))
				PUT(Str::get(pos));
	} else WRITE("i7_mgl_%S", identifier);
}

void CNamespace::mangle_opcode(code_generator *cgt, OUTPUT_STREAM, text_stream *opcode) {
	WRITE("glulx_");
	LOOP_THROUGH_TEXT(pos, opcode)
		if (Str::get(pos) != '@')
			PUT(Str::get(pos));
}

@

=
void CNamespace::fix_locals(code_generation *gen) {
	InterTree::traverse(gen->from, CNamespace::sweep_for_locals, gen, NULL, LOCAL_IST);
}

void CNamespace::sweep_for_locals(inter_tree *I, inter_tree_node *P, void *state) {
	inter_package *pack = Inter::Packages::container(P);
	inter_symbol *var_name =
		InterSymbolsTables::local_symbol_from_id(pack, P->W.data[DEFN_LOCAL_IFLD]);
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "local_%S", var_name->symbol_name);
	Inter::Symbols::set_translate(var_name, T);
	DISCARD_TEXT(T)
}

@

=
void CNamespace::declare_constant(code_generator *cgt, code_generation *gen, text_stream *const_name, inter_symbol *const_s, int form, inter_tree_node *P, text_stream *val, int ifndef_me) {
	int depth = 1, id = c_constants_1_I7CGS;
	if (const_s) {
		depth = Inter::Constant::constant_depth(const_s);
		if (Str::eq(Inter::Symbols::name(const_s), I"Release")) { id = c_ids_and_maxima_I7CGS; depth = 1; }
		if (Str::eq(Inter::Symbols::name(const_s), I"Serial")) { id = c_ids_and_maxima_I7CGS; depth = 1; }
	}
	segmentation_pos saved = CodeGen::select_layered(gen, id, depth);
	text_stream *OUT = CodeGen::current(gen);
	if (ifndef_me) {
		WRITE("#ifndef ");
		CNamespace::mangle(cgt, OUT, const_name);
		WRITE("\n");
	}
	WRITE("#define ");
	CNamespace::mangle(cgt, OUT, const_name);
	WRITE(" ");
	VanillaConstants::definition_value(gen, form, P, const_s, val);
	WRITE("\n");
	if (ifndef_me) WRITE("#endif\n");
	CodeGen::deselect(gen, saved);
}
