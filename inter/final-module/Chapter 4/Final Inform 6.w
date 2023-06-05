[I6Target::] Generating Inform 6.

To generate I6 code from intermediate code.

@h Target.
This generator produces Inform 6 source code, using the Vanilla algorithm.

=
void I6Target::create_generator(void) {
	code_generator *inform6_generator = Generators::new(I"inform6");

	METHOD_ADD(inform6_generator, BEGIN_GENERATION_MTID, I6Target::begin_generation);
	METHOD_ADD(inform6_generator, MANGLE_IDENTIFIER_MTID, I6Target::mangle);
	METHOD_ADD(inform6_generator, OFFER_PRAGMA_MTID, I6Target::offer_pragma)
	METHOD_ADD(inform6_generator, END_GENERATION_MTID, I6Target::end_generation);

	I6TargetCode::create_generator(inform6_generator);
	I6TargetObjects::create_generator(inform6_generator);
	I6TargetConstants::create_generator(inform6_generator);
	I6TargetVariables::create_generator(inform6_generator);
}

@ We will write a single output file of I6 source code, but segmented as follows:

@e ICL_directives_I7CGS
@e compiler_versioning_matter_I7CGS
@e attributes_I7CGS
@e properties_I7CGS
@e global_variables_I7CGS
@e global_variables_array_I7CGS
@e constants_I7CGS
@e fake_actions_I7CGS
@e arrays_I7CGS
@e classes_I7CGS
@e objects_I7CGS
@e property_stubs_I7CGS
@e functions_I7CGS
@e command_grammar_I7CGS

=
int I6_target_segments[] = {
	ICL_directives_I7CGS,
	compiler_versioning_matter_I7CGS,
	attributes_I7CGS,
	properties_I7CGS,
	global_variables_I7CGS,
	global_variables_array_I7CGS,
	constants_I7CGS,
	fake_actions_I7CGS,
	arrays_I7CGS,
	classes_I7CGS,
	objects_I7CGS,
	property_stubs_I7CGS,
	functions_I7CGS,
	command_grammar_I7CGS,
	-1
};

@ This generator uses the following state data while it works:

@d I6_GEN_DATA(x) ((I6_generation_data *) (gen->generator_private_data))->x

=
typedef struct I6_generation_data {
	int attribute_slots_used;
	int value_ranges_needed;
	int value_property_holders_needed;
	int DebugAttribute_seen;
	int subterfuge_count;
	CLASS_DEFINITION
} I6_generation_data;

I6_generation_data *I6Target::new_data(void) {
	I6_generation_data *data = CREATE(I6_generation_data);
	data->attribute_slots_used = 0;
	data->value_ranges_needed = FALSE;
	data->value_property_holders_needed = FALSE;
	data->DebugAttribute_seen = FALSE;
	data->subterfuge_count = 0;
	return data;
}

@ We return |FALSE| here to signal that we want the Vanilla algorithm to
manage the process.

=
int I6Target::begin_generation(code_generator *gtr, code_generation *gen) {
	int omit_ur = TRUE;
	CodeGen::create_segments(gen, I6Target::new_data(), I6_target_segments);
	@<Parse the Inform compilation options@>;
	@<Compile some I6 oddities@>;
	@<Compile some veneer replacement code@>;
	return FALSE;
}

@<Parse the Inform compilation options@> =
	linked_list *opts = TargetVMs::option_list(gen->for_VM);
	text_stream *opt;
	LOOP_OVER_LINKED_LIST(opt, text_stream, opts) {
		if (Str::eq_insensitive(opt, I"omit-unused-routines")) omit_ur = TRUE;
		else if (Str::eq_insensitive(opt, I"no-omit-unused-routines")) omit_ur = FALSE;
		else {
			#ifdef PROBLEMS_MODULE
			Problems::fatal("Unknown compilation format option");
			#endif
			#ifndef PROBLEMS_MODULE
			Errors::fatal("Unknown compilation format option");
			exit(1);
			#endif
		}
	}

@ Defining a constant called |Grammar__Version| tells Inform 6 which storage
layout to use for command parser grammar. 2 is the shiny, modern one -- 1995
not 1993.

The I6 compiler adds a thin layer of hidden code to every program it compiles,
called the "veneer". This layer of code requires a global variable called |debug_flag|
to exist, and since that doesn't exist in the Inter tree, we must make it by hand.

The |or_tmp_var| variable is not significant to I6, and is just a temporary location
we will need for the code we are compiling. But this seems a good time to make it.

See the Inform 6 Technical Manual for more on these oddities.

@<Compile some I6 oddities@> =
	segmentation_pos saved = CodeGen::select(gen, compiler_versioning_matter_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("Constant Grammar__Version 2;\n");
	WRITE("Global debug_flag;\n");
	WRITE("Global or_tmp_var;\n");
	CodeGen::deselect(gen, saved);
	saved = CodeGen::select(gen, ICL_directives_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("!%% -Cu\n");
	WRITE("!%% $ZCODE_LESS_DICT_DATA=1;\n");
	if (omit_ur) WRITE("!%% $OMIT_UNUSED_ROUTINES=1;\n");
	CodeGen::deselect(gen, saved);

@ As noted above, I6 will add a veneer of code to what we compile. That veneer
will contain a function called |OC__Cl| which implements "ofclass", the I6
condition determining whether an object belongs to a given class. The I6
compiler's stock copy of |OC__Cl| doesn't work right with I7 code, though,
so we replace it here with a better one. (The I6 compiler uses our definition
in preference to its own.)

We need do this only when compiling to the Z-machine; our replacement function
is implemented in pure Z-machine assembly language. See the Z-Machine Standards
Document for a specification.

@<Compile some veneer replacement code@> =
	segmentation_pos saved = CodeGen::select(gen, functions_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#Ifdef TARGET_ZCODE;\n");
	WRITE("#OrigSource \"%s\" %d;\n", __FILE__, __LINE__);
	WRITE("Global max_z_object;\n");
	WRITE("#Ifdef Z__Region;\n");
	WRITE("[ OC__Cl obj cla j a n objflag;\n"); INDENT;
	WRITE("@jl obj 1 ?NotObj;\n");
	WRITE("@jg obj max_z_object ?NotObj;\n");
	WRITE("@inc objflag;\n");
	WRITE("#Ifdef K1_room;\n");
	WRITE("@je cla K1_room ?~NotRoom;\n");
	WRITE("@test_attr obj mark_as_room ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE(".NotRoom;\n");
	WRITE("#Endif;\n");
	WRITE("#Ifdef K2_thing;\n");
	WRITE("@je cla K2_thing ?~NotObj;\n");
	WRITE("@test_attr obj mark_as_thing ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE("#Endif;\n");
	WRITE(".NotObj;\n");
	WRITE("\n");
	WRITE("@je cla Object Class ?ObjOrClass;\n");
	WRITE("@je cla Routine String ?RoutOrStr;\n");
	WRITE("\n");
	WRITE("@jin cla 1 ?~Mistake;\n");
	WRITE("\n");
	WRITE("@jz objflag ?rfalse;\n");
	WRITE("@get_prop_addr obj 2 -> a;\n");
	WRITE("@jz a ?rfalse;\n");
	WRITE("@get_prop_len a -> n;\n");
	WRITE("\n");
	WRITE("@div n 2 -> n;\n");
	WRITE(".Loop;\n");
	WRITE("@loadw a j -> sp;\n");
	WRITE("@je sp cla ?rtrue;\n");
	WRITE("@inc j;\n");
	WRITE("@jl j n ?Loop;\n");
	WRITE("@rfalse;\n");
	WRITE("\n");
	WRITE(".ObjOrClass;\n");
	WRITE("@jz objflag ?rfalse;\n");
	WRITE("@je cla Object ?JustObj;\n");
	WRITE("\n");
	WRITE("! So now cla is Class\n");
	WRITE("@jg obj String ?~rtrue;\n");
	WRITE("@jin obj Class ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE("\n");
	WRITE(".JustObj;\n");
	WRITE("! So now cla is Object\n");
	WRITE("@jg obj String ?~rfalse;\n");
	WRITE("@jin obj Class ?rfalse;\n");
	WRITE("@rtrue;\n");
	WRITE("\n");
	WRITE(".RoutOrStr;\n");
	WRITE("@jz objflag ?~rfalse;\n");
	WRITE("@call_2s Z__Region obj -> sp;\n");
	WRITE("@inc sp;\n");
	WRITE("@je sp cla ?rtrue;\n");
	WRITE("@rfalse;\n");
	WRITE("\n");
	WRITE(".Mistake;\n");
	WRITE("RT__Err(\"apply 'ofclass' for\", cla, -1);\n");
	WRITE("rfalse;\n");
	OUTDENT; WRITE("];\n");
	WRITE("#Endif;\n");
	WRITE("#OrigSource;\n");
	WRITE("#Endif;\n");
	CodeGen::deselect(gen, saved);

@ Pragmas are interpreted as ICL directives -- ICL being the Inform
Configuration Language part of Inform 6, a mini-language for controlling the I6
compiler, able to set command-line switches, memory settings and so on. I6
ordinarily discards lines beginning with exclamation marks as comments, but at
the very top of the file, lines beginning |!%| are read as ICL commands: as soon
as any line (including a blank line) doesn't have this signature, I6 exits ICL
mode.

=
void I6Target::offer_pragma(code_generator *gtr, code_generation *gen,
	inter_tree_node *P, text_stream *tag, text_stream *content) {
	if (Str::eq(tag, I"Inform6")) {
		segmentation_pos saved = CodeGen::select(gen, ICL_directives_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("!%% %S\n", content);
		CodeGen::deselect(gen, saved);
	}
}

@ Names are not mangled: all Inter identifiers are used as-is.

=
void I6Target::mangle(code_generator *gtr, OUTPUT_STREAM, text_stream *identifier) {
	WRITE("%S", identifier);
}

@ The end:

=
int I6Target::end_generation(code_generator *gtr, code_generation *gen) {
	I6TargetObjects::end_generation(gtr, gen);
	I6TargetCode::end_generation(gtr, gen);
	return FALSE;
}
