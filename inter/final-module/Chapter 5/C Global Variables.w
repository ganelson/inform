[CGlobals::] C Global Variables.

Global variables translated to C.

@h Setting up the model.

=
void CGlobals::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, PREPARE_VARIABLE_MTID, CGlobals::prepare_variable);
	METHOD_ADD(cgt, DECLARE_VARIABLE_MTID, CGlobals::declare_variable);
}

void CGlobals::initialise_data(code_generation *gen) {
}

void CGlobals::begin(code_generation *gen) {
}

void CGlobals::end(code_generation *gen) {
}

@

=
int CGlobals::prepare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k) {
/*	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) != 1) {
			text_stream *S = Str::new();
			WRITE_TO(S, "(");
			CNamespace::mangle(cgt, S, I"Global_Vars");
			WRITE_TO(S, "[%d])", k);
			Inter::Symbols::set_translate(var_name, S);
		}
		k++;
	}
*/
	return k;
}

int CGlobals::declare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k, int of) {
//	if (Inter::Symbols::read_annotation(var_name, ASSIMILATED_IANN) == 1) {
		generated_segment *saved = CodeGen::select(gen, c_globals_array_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("i7val ");
		CNamespace::mangle(cgt, OUT, CodeGen::CL::name(var_name));
		WRITE(" = "); 
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		WRITE(";\n");
		WRITE("#define i7_defined_");
		CNamespace::mangle(cgt, OUT, CodeGen::CL::name(var_name));
		WRITE(" 1;\n");
		CodeGen::deselect(gen, saved);
/*	}
	if (Inter::Symbols::read_annotation(var_name, EXPLICIT_VARIABLE_IANN) != 1) {
		if (k == 0) CMemoryModel::begin_array(cgt, gen, I"Global_Vars", WORD_ARRAY_FORMAT);
		TEMPORARY_TEXT(val)
		CodeGen::select_temporary(gen, val);
		CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
		CodeGen::deselect_temporary(gen);
		CMemoryModel::array_entry(cgt, gen, val, WORD_ARRAY_FORMAT);
		DISCARD_TEXT(val)
		k++;
		if (k == of) {
			if (k < 2) {
				CMemoryModel::array_entry(cgt, gen, I"0", WORD_ARRAY_FORMAT);
				CMemoryModel::array_entry(cgt, gen, I"0", WORD_ARRAY_FORMAT);
			}
			CMemoryModel::end_array(cgt, gen, WORD_ARRAY_FORMAT);
		}
	}
*/
	return k;
}
