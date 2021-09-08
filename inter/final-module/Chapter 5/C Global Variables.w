[CGlobals::] C Global Variables.

Global variables translated to C.

@h Setting up the model.

=
void CGlobals::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, PREPARE_VARIABLE_MTID, CGlobals::prepare_variable);
	METHOD_ADD(cgt, DECLARE_VARIABLE_MTID, CGlobals::declare_variable);
	METHOD_ADD(cgt, EVALUATE_VARIABLE_MTID, CGlobals::evaluate_variable);
}

int C_var_count = 1;
text_stream *C_var_vals = NULL;

void CGlobals::initialise_data(code_generation *gen) {
	C_var_count = 1;
	C_var_vals = Str::new();
}

void CGlobals::begin(code_generation *gen) {
}

void CGlobals::end(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);

	WRITE("#define i7_no_variables %d\n", C_var_count);
	WRITE("#define i7_var_self 0\n");
	WRITE("i7val i7_initial_variable_values[];\n");
	CodeGen::deselect(gen, saved);
	
	saved = CodeGen::select(gen, c_globals_array_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("i7val i7_initial_variable_values[] = { 0 %S };\n", C_var_vals);
	CodeGen::deselect(gen, saved);
}

@

=
int CGlobals::prepare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k) {
	return k;
}

int CGlobals::declare_variable(code_generation_target *cgt, code_generation *gen,
	inter_tree_node *P, inter_symbol *var_name, int k, int of) {
	CGlobals::declare_variable_by_name(gen, CodeGen::CL::name(var_name), P);
	return k;
}

void CGlobals::declare_variable_by_name(code_generation *gen, text_stream *name, 
	inter_tree_node *P) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define i7_var_%S %d\n", name, C_var_count);
	CodeGen::deselect(gen, saved);

	C_var_count++;
	CodeGen::select_temporary(gen, C_var_vals);
	WRITE_TO(C_var_vals, ", ");
	if (P) CodeGen::CL::literal(gen, NULL, Inter::Packages::scope_of(P), P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD], FALSE);
	else WRITE_TO(C_var_vals, "0");
	CodeGen::deselect_temporary(gen);
	WRITE_TO(C_var_vals, " /* %S */\n", name);
}

void CGlobals::evaluate_variable(code_generation_target *cgt, code_generation *gen, inter_symbol *var_name, int as_reference) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("proc->state.variables[i7_var_%S]", CodeGen::CL::name(var_name));
}
