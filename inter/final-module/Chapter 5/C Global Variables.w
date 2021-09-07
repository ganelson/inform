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
	return k;
}

int CGlobals::declare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k, int of) {
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
	return k;
}

@

= (text to inform7_clib.c)
i7val i7_mgl_self = 0;
