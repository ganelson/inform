[CNamespace::] C Namespace.

How identifiers are used in the C code we generate.

@ =
void CNamespace::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, MANGLE_IDENTIFIER_MTID, CNamespace::mangle);
	METHOD_ADD(gtr, DECLARE_CONSTANT_MTID, CNamespace::declare_constant);
}

@ A fundamental decision we have to make here is what namespace of identifiers
we will use in the code we generate. If an Inter function is called |example|,
we are going to need to compile that to some C function: what should this be
called?

It seems unwise to call it just |example|, that is, to compile Inter identifiers
directly into C ones. What if the Inter code used the identifier |printf| for
something, for example, or indeed the identifiers |struct| or |unsigned|? Moreover,
unlike the Inform 6 generator, this one is expecting the compile code which will
only be part of a larger program. We want to avoid hogging the entire namespace;
in fact, we want our code to use only names beginning |i7_| or |glulx_|, with
the single exception of |main|, and even that only when |main| is compiled.

@ To that end, we "mangle" identifier names, and this is how. Examples:
= (text)
	example         i7_mgl_example
	##Attack        i7_ss_Attack
	#g$self         i7_ss_gself
=
This is not quite a faithful scheme because, say, |#a#a| and |#aa| both mangle
to the same result, |i7_ss_aa|. But |#| and |$| characters are used extremely
sparingly in Inter, and these can never arise.

=
void CNamespace::mangle(code_generator *gtr, OUTPUT_STREAM, text_stream *identifier) {
	if (Str::get_first_char(identifier) == '#') {
		WRITE("i7_ss_");
		LOOP_THROUGH_TEXT(pos, identifier)
			if ((Str::get(pos) != '#') && (Str::get(pos) != '$'))
				PUT(Str::get(pos));
	} else WRITE("i7_mgl_%S", identifier);
}

void CNamespace::mangle_with(code_generator *gtr, OUTPUT_STREAM, text_stream *identifier,
	text_stream *modifier) {
	WRITE("i7_%S_%S", modifier, identifier);
}

@ Opcode names are also mangled. Each assembly language opcode will use a
corresponding C function, whose name is mangled from that of the opcode. For
example:
= (text)
    @jz             i7_opcode_jz
    @streamnum		i7_opcode_streamnum
=

=
void CNamespace::mangle_opcode(OUTPUT_STREAM, text_stream *opcode) {
	WRITE("i7_opcode_");
	LOOP_THROUGH_TEXT(pos, opcode)
		if (Str::get(pos) != '@')
			PUT(Str::get(pos));
}

@ Global variable names are similarly mangled:
= (text)
    howmayyou       i7_var_howmayyou
=

=
void CNamespace::mangle_variable(OUTPUT_STREAM, text_stream *var) {
	WRITE("i7_var_%S", var);
}

@ Local variable names have to be handled slightly differently. This is because
Inter frequently makes use of local variables whose identifiers are also used
for some global construct. Of course, C also allows for this: for example --
= (text as C)
	int xerxes = 1;
	void govern_Sophene(void) {
		int xerxes = 2;
		printf("%d\n", xerxes);
	}
=
...is legal, and prints 2 when the function is called. So at first sight, there's
no problem giving a local variable the same name as some global construct.

But that does not work if the global definition is made by the C preprocessor
rather than its syntax analyser. Consider:
= (text as C)
	#define xerxes 1
	void govern_Sophene(void) {
		int xerxes = 2;
		printf("%d\n", xerxes);
	}
=
This throws an error message: |int xerxes = 2;| then reads as |int 1 = 2;|. And
since some of our Inter constructs will indeed result in |#define|d values
rather than named C variables, we cannot allow a local variable name to coincide
with the name of anything else (after mangling).

We avoid this by changing the pre-mangled identifiers for all local variables
to begin with |local_|:
= (text)
	original	    translation			mangled translation
    "xerxes"		"local_xerxes"      "i7_mgl_local_xerxes"
=
This is not an elegant trick, but it works nicely enough.

=
void CNamespace::fix_locals(code_generation *gen) {
	InterTree::traverse(gen->from, CNamespace::sweep_for_locals, gen, NULL, LOCAL_IST);
}

void CNamespace::sweep_for_locals(inter_tree *I, inter_tree_node *P, void *state) {
	inter_symbol *var_name = LocalInstruction::variable(P);
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "local_%S", InterSymbol::identifier(var_name));
	InterSymbol::set_translate(var_name, T);
	DISCARD_TEXT(T)
}

@ Constants in Inter are indeed directly converted to |#define|d constants in C,
but with their names of course mangled.

For the reason why |Serial| and |Release| are placed higher-up in the file, see
//C Memory Model//.

=
void CNamespace::declare_constant(code_generator *gtr, code_generation *gen,
	inter_symbol *const_s, int form, text_stream *val) {
	text_stream *name = InterSymbol::trans(const_s);
	int seg = c_constants_I7CGS;
	if (Str::eq(name, I"Serial")) seg = c_ids_and_maxima_I7CGS;
	if (Str::eq(name, I"Release")) seg = c_ids_and_maxima_I7CGS;
	if (Str::eq(name, I"BASICINFORMKIT")) seg = c_ids_and_maxima_I7CGS;
	if (Str::eq(name, I"DICT_WORD_SIZE")) seg = c_ids_and_maxima_I7CGS;
	segmentation_pos saved = CodeGen::select_layered(gen, seg,
		ConstantInstruction::constant_depth(const_s));
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(gtr, OUT, name);
	WRITE(" ");
	VanillaConstants::definition_value(gen, form, const_s, val);
	WRITE("\n");
	CodeGen::deselect(gen, saved);
}
