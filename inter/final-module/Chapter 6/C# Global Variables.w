[CSGlobals::] C# Global Variables.

Global variables translated to C#.

@ =
void CSGlobals::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, DECLARE_VARIABLES_MTID, CSGlobals::declare_variables);
	METHOD_ADD(gtr, EVALUATE_VARIABLE_MTID, CSGlobals::evaluate_variable);
}

typedef struct CS_generation_variables_data {
	int no_variables;
} CS_generation_variables_data;

void CSGlobals::initialise_data(code_generation *gen) {
	CS_GEN_DATA(vardata.no_variables) = 1;
}

@ The basic scheme is this: the global Inter variables are going to have
their values stored in an array, so to identify which variable you are reading
or writing, you need an index (i.e., position) in that array.

The main thing we need to compile is a (static) array of initial values for
these variables, so that a new process can be initialised. But we must also
define constants to refer to their positions in the array.

= (text to inform7_cslib.cs)
partial class Story {
	protected internal int i7_no_variables;
	protected internal int[] i7_initial_variable_values;
}
=

=
void CSGlobals::begin(code_generation *gen) {
}

void CSGlobals::end(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7_no_variables = %d;\n", CS_GEN_DATA(vardata.no_variables));
	CodeGen::deselect(gen, saved);
}

@ We will assign the global variables unique index numbers 0, 1, 2, ..., with
the special variable |self| given index 0. Note that |self| always exists,
but has no Inter declaration node.

=
void CSGlobals::declare_variables(code_generator *gtr, code_generation *gen, linked_list *L) {
	segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7_initial_variable_values = new[] {\n");

	@<Define a constant for the self position in the globals array@>;
	@<Add the initial value for self to the globals array@>;
	@<Define a more legible constant for self to the header target@>;

	int N = 1;
	inter_symbol *var_name;
	LOOP_OVER_LINKED_LIST(var_name, inter_symbol, L) {
		text_stream *identifier = InterSymbol::trans(var_name);
		@<Define a constant for this position in the globals array@>;
		@<Add the initial value to the globals array@>;
		@<Define a more legible constant for the header target@>;
		N++;
	}
	CS_GEN_DATA(vardata.no_variables) = N;

	WRITE("};\n");
	CodeGen::deselect(gen, saved);
}

@<Define a constant for the self position in the globals array@> =
	/* segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	CSNamespace::mangle_variable(OUT, I"self");
	WRITE("= 0;\n");
	CodeGen::deselect(gen, saved); */

@<Define a constant for this position in the globals array@> =
	segmentation_pos saved = CodeGen::select(gen, cs_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("/*dcpga*/const int ");
	CSNamespace::mangle_variable(OUT, identifier);
	WRITE(" = %d;\n", N);
	CodeGen::deselect(gen, saved);

@<Add the initial value for self to the globals array@> =
	segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("  0 /* self */\n");
	CodeGen::deselect(gen, saved);

@<Add the initial value to the globals array@> =
	segmentation_pos saved = CodeGen::select(gen, cs_constructor_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE(", ");
	if (var_name->definition) {
		inter_tree_node *P = var_name->definition;
		CodeGen::pair(gen, P, VariableInstruction::value(P));
	} else {
		WRITE("0");
	}
	WRITE(" /* %S */\n", identifier);
	CodeGen::deselect(gen, saved);

@<Define a more legible constant for self to the header target@> =
	CSGlobals::define_header_constant_for_variable(gen, I"self", 0);

@<Define a more legible constant for the header target@> =
	text_stream *name = Metadata::optional_textual(
		InterPackage::container(var_name->definition), I"^name");
	if (name)
		CSGlobals::define_header_constant_for_variable(gen, name, N);
	else 
		CSGlobals::define_header_constant_for_variable(gen, identifier, N);

@ =
void CSGlobals::define_header_constant_for_variable(code_generation *gen, text_stream *var_name,
	int id) {
	segmentation_pos saved = CodeGen::select(gen, cs_variable_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("/*dhcv*/const int %S = %d;\n", CSTarget::symbols_header_identifier(gen, I"V", var_name), id);
	CodeGen::deselect(gen, saved);
}

@ Within a process |proc|, the current value of variable |i| is |proc.state.variables[i]|.

=
void CSGlobals::evaluate_variable(code_generator *gtr, code_generation *gen,
	inter_symbol *var_name, int as_reference) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE("proc.state.variables[");
	CSNamespace::mangle_variable(OUT, InterSymbol::trans(var_name));
	WRITE("]");
}

@ Finally, this function, part of the C# library, initialises the variables for a
newly-starting process.

= (text to inform7_cslib.cs)
partial class Process {
	void i7_initialise_variables() {
		// TODO: use array copy method instead
		state.variables = new int[story.i7_no_variables];
		for (int i=0; i<story.i7_no_variables; i++)
			state.variables[i] = story.i7_initial_variable_values[i];
	}
}
=
