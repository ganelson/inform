[CGlobals::] C Global Variables.

Global variables translated to C.

@ =
void CGlobals::initialise(code_generator *cgt) {
	METHOD_ADD(cgt, DECLARE_VARIABLES_MTID, CGlobals::declare_variables);
	METHOD_ADD(cgt, EVALUATE_VARIABLE_MTID, CGlobals::evaluate_variable);
}

typedef struct C_generation_variables_data {
	int no_variables;
} C_generation_variables_data;

void CGlobals::initialise_data(code_generation *gen) {
	C_GEN_DATA(vardata.no_variables) = 1;
}

@ The basic scheme is this: the global Inter variables are going to have
their values stored in an array, so to identify which variable you are reading
or writing, you need an index (i.e., position) in that array.

The main thing we need to compile is a (static) array of initial values for
these variables, so that a new process can be initialised. But we must also
define constants to refer to their positions in the array.

=
void CGlobals::begin(code_generation *gen) {
}

void CGlobals::end(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define i7_no_variables %d\n", C_GEN_DATA(vardata.no_variables));
	WRITE("i7word_t i7_initial_variable_values[i7_no_variables];\n");
	CodeGen::deselect(gen, saved);
}

@ We will assign the global variables unique index numbers 0, 1, 2, ..., with
the special variable |self| given index 0. Note that |self| always exists,
but has no Inter declaration node.

=
void CGlobals::declare_variables(code_generator *cgt, code_generation *gen, linked_list *L) {
	segmentation_pos saved = CodeGen::select(gen, c_globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7word_t i7_initial_variable_values[i7_no_variables] = {\n");

	@<Define a constant for the self position in the globals array@>;
	@<Add the initial value for self to the globals array@>;
	@<Define a more legible constant for self to the header target@>;

	int N = 1;
	inter_symbol *var_name;
	LOOP_OVER_LINKED_LIST(var_name, inter_symbol, L) {
		text_stream *identifier = Inter::Symbols::name(var_name);
		@<Define a constant for this position in the globals array@>;
		@<Add the initial value to the globals array@>;
		@<Define a more legible constant for the header target@>;
		N++;
	}
	C_GEN_DATA(vardata.no_variables) = N;

	WRITE("};\n");
	CodeGen::deselect(gen, saved);
}

@<Define a constant for the self position in the globals array@> =
	segmentation_pos saved = CodeGen::select(gen, c_ids_and_maxima_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle_variable(OUT, I"self");
	WRITE(" 0\n");
	CodeGen::deselect(gen, saved);

@<Define a constant for this position in the globals array@> =
	segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle_variable(OUT, identifier);
	WRITE(" %d\n", N);
	CodeGen::deselect(gen, saved);

@<Add the initial value for self to the globals array@> =
	segmentation_pos saved = CodeGen::select(gen, c_globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("  0 /* self */\n");
	CodeGen::deselect(gen, saved);

@<Add the initial value to the globals array@> =
	segmentation_pos saved = CodeGen::select(gen, c_globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE(", ");
	if (var_name->definition) {
		inter_tree_node *P = var_name->definition;
		CodeGen::pair(gen, P, P->W.data[VAL1_VAR_IFLD], P->W.data[VAL2_VAR_IFLD]);
	} else {
		WRITE("0");
	}
	WRITE(" /* %S */\n", identifier);
	CodeGen::deselect(gen, saved);

@<Define a more legible constant for self to the header target@> =
	CGlobals::define_header_constant_for_variable(gen, I"self", 0);

@<Define a more legible constant for the header target@> =
	text_stream *name = Metadata::read_optional_textual(
		Inter::Packages::container(var_name->definition), I"^name");
	if (name)
		CGlobals::define_header_constant_for_variable(gen, name, N);
	else 
		CGlobals::define_header_constant_for_variable(gen, identifier, N);

@ =
void CGlobals::define_header_constant_for_variable(code_generation *gen, text_stream *var_name,
	int id) {
	segmentation_pos saved = CodeGen::select(gen, c_variable_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %d\n", CTarget::symbols_header_identifier(gen, I"V", var_name), id);
	CodeGen::deselect(gen, saved);
}

@ Within a process |proc|, the current value of variable |i| is |proc->state.variables[i]|.

=
void CGlobals::evaluate_variable(code_generator *cgt, code_generation *gen,
	inter_symbol *var_name, int as_reference) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("proc->state.variables[");
	CNamespace::mangle_variable(OUT, Inter::Symbols::name(var_name));
	WRITE("]");
}

@ Finally, this function, part of the C library, initialises the variables for a
newly-starting process.

= (text to inform7_clib.h)
void i7_initialise_variables(i7process_t *proc);
=

= (text to inform7_clib.c)
void i7_initialise_variables(i7process_t *proc) {
	proc->state.variables = i7_calloc(proc, i7_no_variables, sizeof(i7word_t));
	for (int i=0; i<i7_no_variables; i++)
		proc->state.variables[i] = i7_initial_variable_values[i];
}
=
