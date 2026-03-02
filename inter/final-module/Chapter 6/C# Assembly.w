[CSAssembly::] C# Assembly.

The problem of assembly language.

@h General implementation.
This section does just one thing: compiles invocations of assembly-language
opcodes.

=
void CSAssembly::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, INVOKE_OPCODE_MTID, CSAssembly::invoke_opcode);
	METHOD_ADD(gtr, ASSEMBLY_MARKER_MTID, CSAssembly::assembly_marker);
}

typedef struct CS_generation_assembly_data {
	struct dictionary *opcodes_used;
} CS_generation_assembly_data;

void CSAssembly::initialise_data(code_generation *gen) {
	CS_GEN_DATA(asmdata.opcodes_used) = NULL;
}

void CSAssembly::begin(code_generation *gen) {
	CSAssembly::initialise_data(gen);
}

void CSAssembly::end(code_generation *gen) {
}

@ Inter is for the most part fully specified and cross-platform, but assembly
language is the big hole in that. It is legal for Inter code to contain almost
anything which purports to be assembly language. For example, the following
code will successfully build as part of an Inter kit:
= (text as Inform 6)
	[ Peculiar x;
	    @bandersnatch x;
	];
=
Kit code, and also material included in |(-| and |-)| brackets in I7 source text,
can claim to use assembly language opcodes with any names it likes. No checking
is done that these are "real" opcodes. (Spoilers: |@bandersnatch| is not.)

The point of this is that different final targets support different sets of
assembly language. This was always true for Inform 6 code (after around 2000,
anyway), because the Z and Glulx virtual machines had different assembly
languages: |@split_window| exists for Z but not Glulx, |@atan| exists for
Glulx but not Z, for example.

So each different final generator needs to make its own decision about what
assembly language opcodes to provide, and what they will do. In theory, we could
make an entirely new assembly language for C. But in practice that would just
make the standard Inform kits, such as BasicInformKit, impossible to support
on C, because those kits make quite heavy use of opcodes from Z/Glulx.

We will instead:

(1) Emulate exactly that subset of the Glulx assembly language which is used
by the standard Inform kits, and
(2) Allow any other opcodes to be externally defined by the user.

In this way, we obtain both compatibility with the Inform kits, enabling us to
compile works of IF to C, and also extensibility.
	
@ Each different opcode we see will be matched up to a //CS_supported_opcode//
giving it some metadata: we will gather these into a dictionary so that names
of opcodes can quickly be resolved to their metadata structures.

That dictionary will begin with (1) about 60 standard supported opcodes, but
then may pick up (2) a few others such as |@bandersnatch|, if kits do something
non-standard.

So now we define some very minimal metadata on our opcodes. Each opcode will,
when used, be followed by a number of operands, which we number from 1:
= (text as Inform 6)
	@fmod a b rem quot;
	!     1 2 3   4
=
This opcode, which performs floating-point division with remainder, reads in
operands 1 and 2, and writes results out to operands 3 and 4. In the following,
|store_this_operand[3]| and |store_this_operand[4]| would be |TRUE|, while
|store_this_operand[1]| and |store_this_operand[2]| would be |FALSE|. (In fact,
this is an outlier, because it is the only opcode we support which has more than
one store operand. But in principle we could have many.)

Glulx assembly language also allows variable numbers of arguments to some opcodes,
or "varargs". For example:
= (text as Inform 6)
	@glk 4 _vararg_count ret;
	!    1 2             3
=
Here operand 3 is a store, and operands 1 and 2 are read in. But operand 2 is
special in that it is a count of additional operands which are found on the
stack rather than in the body of the instruction. For example,
= (text as Inform 6)
	@glk 4 6 ret;
=
would provide |@glk| with seven operands to read in: the one in the instruction
itself, |4|, and then the top 6 items on the stack.

Because of this, an operand holding a variable-argument count is special. There
can be at most one for any opcode; |vararg_operand| is -1 if there isn't one,
but for |@glk|, |vararg_operand| would be 2.

=
typedef struct CS_supported_opcode {
	struct text_stream *name; /* including the opening |@| character */
	int store_this_operand[MAX_OPERANDS_IN_INTER_ASSEMBLY];
	int vararg_operand; /* position of |_vararg_count| operand, or -1 if none */
	int speculative; /* i.e., not part of the standard supported set */
	CLASS_DEFINITION
} CS_supported_opcode;

@ On creation, a //CS_supported_opcode// is automatically added to the dictionary:

=
CS_supported_opcode *CSAssembly::new_opcode(code_generation *gen, text_stream *name,
	int s1, int s2, int va) {
	CS_supported_opcode *opc = CREATE(CS_supported_opcode);
	opc->speculative = FALSE;
	opc->name = Str::duplicate(name);
	for (int i=0; i<MAX_OPERANDS_IN_INTER_ASSEMBLY; i++) opc->store_this_operand[i] = FALSE;
	if (s1 >= 1) opc->store_this_operand[s1] = TRUE;
	if (s2 >= 1) opc->store_this_operand[s2] = TRUE;
	opc->vararg_operand = va;
	Dictionaries::create(CS_GEN_DATA(asmdata.opcodes_used), name);
	Dictionaries::write_value(CS_GEN_DATA(asmdata.opcodes_used), name, opc);
	return opc;
}

@ When the generator encounters an opcode called |name| which seems to be used
with |operand_count| operands, it calls the following function to find the
corresponding metadata. Note that this always returns a valid //CS_supported_opcode//,
because even if a completely unexpected name is encountered, the above
mechanism will just create a meaning for it.

=
CS_supported_opcode *CSAssembly::find_opcode(code_generation *gen, text_stream *name,
	int operand_count) {
	if (CS_GEN_DATA(asmdata.opcodes_used) == NULL) {
		CS_GEN_DATA(asmdata.opcodes_used) = Dictionaries::new(256, FALSE);
		@<Stock with the basics@>;
	}
	CS_supported_opcode *opc;
	if (Dictionaries::find(CS_GEN_DATA(asmdata.opcodes_used), name)) {
		opc = Dictionaries::read_value(CS_GEN_DATA(asmdata.opcodes_used), name);
	} else {
		@<Add a speculative new opcode to the dictionary@>;
	}
	return opc;
}

@<Stock with the basics@> =
	CSAssembly::new_opcode(gen, I"@acos",             2, -1, -1);
	CSAssembly::new_opcode(gen, I"@add",              3, -1, -1);
	CSAssembly::new_opcode(gen, I"@aload",            3, -1, -1);
	CSAssembly::new_opcode(gen, I"@aloadb",           3, -1, -1);
	CSAssembly::new_opcode(gen, I"@aloads",           3, -1, -1);
	CSAssembly::new_opcode(gen, I"@asin",             2, -1, -1);
	CSAssembly::new_opcode(gen, I"@atan",             2, -1, -1);
	CSAssembly::new_opcode(gen, I"@binarysearch",     8, -1, -1);
	CSAssembly::new_opcode(gen, I"@call",             3, -1,  2);
	CSAssembly::new_opcode(gen, I"@ceil",             2, -1, -1);
	CSAssembly::new_opcode(gen, I"@copy",             2, -1, -1);
	CSAssembly::new_opcode(gen, I"@cos",              2, -1, -1);
	CSAssembly::new_opcode(gen, I"@div",              3, -1, -1);
	CSAssembly::new_opcode(gen, I"@exp",              2, -1, -1);
	CSAssembly::new_opcode(gen, I"@fadd",             3, -1, -1);
	CSAssembly::new_opcode(gen, I"@fdiv",             3, -1, -1);
	CSAssembly::new_opcode(gen, I"@floor",            2, -1, -1);
	CSAssembly::new_opcode(gen, I"@fmod",             3,  4, -1);
	CSAssembly::new_opcode(gen, I"@fmul",             3, -1, -1);
	CSAssembly::new_opcode(gen, I"@fsub",             3, -1, -1);
	CSAssembly::new_opcode(gen, I"@ftonumn",          2, -1, -1);
	CSAssembly::new_opcode(gen, I"@ftonumz",          2, -1, -1);
	CSAssembly::new_opcode(gen, I"@gestalt",          3, -1, -1);
	CSAssembly::new_opcode(gen, I"@glk",              3, -1,  2);
	CSAssembly::new_opcode(gen, I"@hasundo",          1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jeq",             -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jfeq",            -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jfge",            -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jflt",            -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jisinf",          -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jisnan",          -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jleu",            -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jnz",             -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@jz",              -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@log",              2, -1, -1);
	CSAssembly::new_opcode(gen, I"@malloc",          -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@mcopy",           -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@mzero",           -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@mfree",           -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@mod",              3, -1, -1);
	CSAssembly::new_opcode(gen, I"@mul",              3, -1, -1);
	CSAssembly::new_opcode(gen, I"@neg",              2, -1, -1);
	CSAssembly::new_opcode(gen, I"@nop",             -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@numtof",           2, -1, -1);
	CSAssembly::new_opcode(gen, I"@pow",              3, -1, -1);
	CSAssembly::new_opcode(gen, I"@quit",            -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@random",           2, -1, -1);
	CSAssembly::new_opcode(gen, I"@restart",         -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@restore",          2, -1, -1);
	CSAssembly::new_opcode(gen, I"@restoreundo",      1, -1, -1);
	CSAssembly::new_opcode(gen, I"@return",          -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@save",             2, -1, -1);
	CSAssembly::new_opcode(gen, I"@saveundo",         1, -1, -1);
	CSAssembly::new_opcode(gen, I"@setiosys",        -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@setrandom",       -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@shiftl",           3, -1, -1);
	CSAssembly::new_opcode(gen, I"@sin",              2, -1, -1);
	CSAssembly::new_opcode(gen, I"@sqrt",             2, -1, -1);
	CSAssembly::new_opcode(gen, I"@streamchar",      -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@streamnum",       -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@streamunichar",   -1, -1, -1);
	CSAssembly::new_opcode(gen, I"@sub",              3, -1, -1);
	CSAssembly::new_opcode(gen, I"@tan",              2, -1, -1);
	CSAssembly::new_opcode(gen, I"@ushiftr",          3, -1, -1);
	CSAssembly::new_opcode(gen, I"@verify",           1, -1, -1);

@ Speculative opcodes cannot store and cannot have varargs. Also, since they
are not part of our supported set, there's no code here to implement them.
Instead we predeclare a function and simply assume that the user will have
written this function somewhere and linked it to us. For example, we might
predeclare this:
= (text as C)
	void i7_opcode_bandersnatch(int v1);
=

@<Add a speculative new opcode to the dictionary@> =
	opc = CSAssembly::new_opcode(gen, name, -1, -1, -1);
	opc->speculative = TRUE;
	segmentation_pos saved = CodeGen::select(gen, cs_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("void ");
	CSNamespace::mangle_opcode(OUT, name);
	WRITE("(Inform.Process proc");
	for (int i=1; i<=operand_count; i++) WRITE(", int v%d", i);
	WRITE(");\n");
	CodeGen::deselect(gen, saved);

@ We finally have enough infrastructure to invoke a general assembly-language
instruction found in our Inter.

=
void CSAssembly::invoke_opcode(code_generator *gtr, code_generation *gen,
	text_stream *opcode, int operand_count, inter_tree_node **operands,
	inter_tree_node *label, int label_sense) {
	CS_supported_opcode *opc = CSAssembly::find_opcode(gen, opcode, operand_count);
	text_stream *OUT = CodeGen::current(gen);
	if (label_sense != NOT_APPLICABLE) @<Begin a branch instruction@>;
	int push_store[MAX_OPERANDS_IN_INTER_ASSEMBLY];
	for (int i=0; i<MAX_OPERANDS_IN_INTER_ASSEMBLY; i++) push_store[i] = FALSE;
	@<Generate a function call@>;
	if (label_sense != NOT_APPLICABLE) @<End a branch instruction@>;
	@<Push any stored results which need to end up on the stack@>;
	WRITE(";\n");
}

@<Begin a branch instruction@> =
	WRITE("if /*as*/(System.Convert.ToBoolean(");

@<End a branch instruction@> =
	WRITE(")");
	if (label_sense == FALSE) WRITE(" == false");
	WRITE(") goto ");
	if (label == NULL) internal_error("no branch label");
	Vanilla::node(gen, label);

@ Each instruction becomes a function call to the function implementing the
opcode in question, except that |@return| becomes the C statement |return|.
If the opcode has N operands then the function has N+1 arguments, since the
first is always the process pointer. 

It may seem to compile slow code if we turn instructions into function calls, but
(a) assembly is not used very much in Inter code, and then not for time-sensitive
operations, and
(b) the C compiler receiving the code we generate will almost certainly perform
inline optimisation to remove most of these calls anyway.

@<Generate a function call@> =
	if (Str::eq(opcode, I"@return")) {
		WRITE("return (");
	} else {
		WRITE("proc."); CSNamespace::mangle_opcode(OUT, opcode); WRITE("(");
	}
	for (int operand = 1; operand <= operand_count; operand++) {
		if (operand > 1) WRITE(", ");
		TEMPORARY_TEXT(O)
		CodeGen::select_temporary(gen, O);
		Vanilla::node(gen, operands[operand-1]);
		CodeGen::deselect_temporary(gen);
		if (opc->store_this_operand[operand]) @<Generate a store operand@>
		else @<Generate a regular operand@>;
		DISCARD_TEXT(O)
	}
	WRITE(")");

@ The argument for a regular operand will have type |int|, so we have to
compile something of that type here.

The special operand notation |sp| is a pseudo-variable meaning "the top of the
stack", so if we see that then we compile that to a pull: note that |i7_pull|
returns an |int|.

@<Generate a regular operand@> =
	if (Str::eq(O, I"sp")) {
		WRITE("proc.i7_pull()");
	} else {
		WRITE("%S", O);
	}

@ The argument for a store operand will have type |out int|, so now we have
to make a pointer.

Again, |sp| is a pseudo-variable meaning "the top of the stack", but this time
we have to push, not pull, and that's something we can't do until the function
has returned -- the function will create the value we need to push. We get
around this by compiling a pointer to some temporary memory.

Finally, assembly also allows |0| as a special value for a store operand, and
this means "throw the value away". We don't want to incur a C compiler warning
by attempting to write |0| in a pointer context, so we pass it as |NULL| instead.

@<Generate a store operand@> =
	if (Str::eq(O, I"sp")) { 
		WRITE("out (proc.state.tmp[%d])", operand);
		push_store[operand] = TRUE;
	} else if (Str::eq(O, I"0")) {
		WRITE("out int _");
	} else {
		WRITE("out %S", O);
	}

@ That may leave a few stored results stranded in temporary workspace, so:

@<Push any stored results which need to end up on the stack@> =
	for (int operand = 1; operand <= operand_count; operand++)
		if (push_store[operand])
			WRITE("; proc.i7_push(proc.state.tmp[%d])", operand);

@ And where does the special operand |sp| come from? From here:

=
void CSAssembly::assembly_marker(code_generator *gtr, code_generation *gen, inter_ti marker) {
	text_stream *OUT = CodeGen::current(gen);
	switch (marker) {
		case ASM_SP_ASMMARKER: WRITE("sp"); break;
		default:
			WRITE_TO(STDERR, "Unsupported assembly marker is '%d'\n", marker);
			internal_error("unsupported assembly marker in C");
	}
}

@h call.
That does everything except to implement the standard set of opcodes, which
must be done with about 60 functions in the C library.

This is not the place to specify what Glulx opcodes do. See Andrew Plotkin's
//documentation on the Glulx virtual machine -> https://www.eblong.com/zarf/glulx//.

Most of the opcodes we support are defined below, but see also //C Input-Output Model//
for |@glk|, and see //C Arithmetic// for the plethora of mathematical operations
such as |@fmul|.

To begin, here is a |@call|, which performs a function call to a perhaps computed
address:

= (text to inform7_cslib.cs)
partial class Process {
	internal void i7_opcode_call(int fn_ref, int varargc, out int z) {
		int[] args = new int[varargc];
		for (int i=0; i<varargc; i++) args[i] = i7_pull();
		z = i7_gen_call(fn_ref, args);
	}
=

@h copy.
Though it doesn't look it, this is one of the main ways Glulx assembly language
programs push or pull to the stack -- |@copy sp x| pulls the stack to |x|;
|@copy sp 0| pops the stack; |@copy x sp| pushes |x| to the stack. But all of
that is handled by the general mechanism above.

= (text to inform7_cslib.cs)
	internal void i7_opcode_copy(int x, out int y) {
		y = x;
	}
=

@h aload, aloads, aloadb.

= (text to inform7_cslib.cs)
	internal void i7_opcode_aload(int x, int y, out int z) {
		z = i7_read_word(x, y);
	}

	internal void i7_opcode_aloads(int x, int y, out int z) {
		z = i7_read_sword(x, y);
	}

	internal void i7_opcode_aloadb(int x, int y, out int z) {
		z = i7_read_byte(x+y);
	}
=

@h ushiftr, shiftl.

= (text to inform7_cslib.cs)
	internal void i7_opcode_shiftl(int x, int y, out int z) {
		int value = 0;
		if ((y >= 0) && (y < 32)) value = (x << y);
		z = value;
	}

	internal void i7_opcode_ushiftr(int x, int y, out int z) {
		int value = 0;
		if ((y >= 0) && (y < 32)) value = (x >> y);
		z = value;
	}
=

@h jeq, jleu, jnz, jz.
These are branch opcodes and return an |int|.

The implementation of |@jleu| uses an explicitly unchecked cast. This code is
unlikely to ever be compiled with checks on by default, but it doesn't hurt to
use |unchecked| just in case.

= (text to inform7_cslib.cs)
	internal int i7_opcode_jeq(int x, int y) {
		if (x == y) return 1;
		return 0;
	}

	internal int i7_opcode_jleu(int x, int y) {
		uint ux, uy;
		ux = unchecked((uint) x); uy = unchecked((uint) y);
		if (ux <= uy) return 1;
		return 0;
	}

	internal int i7_opcode_jnz(int x) {
		if (x != 0) return 1;
		return 0;
	}

	internal int i7_opcode_jz(int x) {
		if (x == 0) return 1;
		return 0;
	}
=

@h nop, quit, verify.
There is no real meaning for |@verify| in this situation: it's supposed to
check the checksum for the contents of a virtual machine, to protect against
the (entirely likely) scenario of a floppy disk sector going bad in 1983.
So we unconditionally store the "okay" result.

= (text to inform7_cslib.cs)
	internal void i7_opcode_nop() {
	}

	internal void i7_opcode_quit() {
		i7_fatal_exit();
	}

	internal void i7_opcode_verify(out int z) {
		z = 0;
	}
=

@h restoreundo, saveundo, hasundo, discardundo.
This all works, but we do something pretty inelegant to support |@restoreundo|:
we insert a call to a (presumably kit-based) function called |DealWithUndo|,
provided this exists. This is done because we are unable safely to follow the
proper Glulx specification. In principle, after a |@restoreundo| succeeds,
execution immediately continues from the position in the program where the
|@saveundo| occurred. For a while the implementation here imitated this by
using |longjmp| and |setjmp|, but it all proved very fragile because of the
difficulty of storing |setjmp| positions safely in memory.

Correspondingly, our implementation of |@saveundo| always stores the result
value 0. The result value 1 would indicate that execution had switched there
from a successful |@restoreundo|: but, as noted, that never happens.

= (text to inform7_cslib.cs)
	internal void i7_opcode_restoreundo(out int x) {
		if (i7_has_snapshot()) {
			i7_restore_snapshot();
			x = 0;
			#if i7_mgl_DealWithUndo
			i7_fn_DealWithUndo(this);
			#endif
		} else {
			x = 1;
		}
	}

	internal void i7_opcode_saveundo(out int x) {
		i7_save_snapshot();
		x = 0;
	}

	internal void i7_opcode_hasundo(out int x) {
		int rv = 0; if (i7_has_snapshot()) rv = 1;
		x = rv;
	}

	internal void i7_opcode_discardundo() {
		i7_destroy_latest_snapshot();
	}
=

@h restart, restore, save.
For the moment, at least, we intentionally do not implement these. It seems
likely that anyone using C# to run interactive fiction is doing so in a wider
framework where saved states will work differently from the traditional model
of asking the user for a filename and then saving data out to a binary file
of that name in the current working directory. Better to do nothing here, and
let users handle this themselves.

Similar considerations apply to |@restart|. The intention of this opcode is
essentially to reboot the virtual machine and start over: here, though, we
have a real machine. It's easy enough to reinitialise the process state,
but not so simple to restart execution as if from a clean process start.


= (text to inform7_cslib.cs)
	internal void i7_opcode_restart() {
		Console.WriteLine("(RESTART is not implemented on this C# program.)");
	}

	internal void i7_opcode_restore(int x, out int y) {
		Console.WriteLine("(RESTORE is not implemented on this C# program.)");
		y = 1;
	}

	internal void i7_opcode_save(int x, out int y) {
		Console.WriteLine("(SAVE is not implemented on this C# program.)");
		y = 1;
	}
=

@h streamchar, streamnum, streamunichar.


= (text to inform7_cslib.cs)
	internal void i7_opcode_streamnum(int x) {
		i7_print_decimal(x);
	}

	internal void i7_opcode_streamchar(int x) {
		i7_print_char(x);
	}

	internal void i7_opcode_streamunichar(int x) {
		i7_print_char(x);
	}
=

@h binarysearch.
This is a Grand Imperial Hotel among Glulx opcodes, with 8 operands, only the
last of which is a store. It performs a binary search on a block of structures
known to be sorted already. It has a nice general-purpose look but was devised so
that command verbs could be looked up quickly in dictionary tables when interactive
fiction is being played: that's the only use which the standard Inform kits make
of it.

The elegant implementation here comes from Andrew Plotkin's reference code for
|glulxe|, a Glulx interpreter. |options| is a bitmap of the bits defined below.
In the only use the standard Inform kits make of this opcode, |options| will be
just |serop_KeyIndirect|, but |keysize| will be more than 4, so that the elaborate
speed optimisation for keys of size 1, 2 and 4, and thus |keybuf|, are never used.
But we may as well have the full functionality here.


= (text to inform7_cslib.cs)
	const int serop_KeyIndirect       = 1;
	const int serop_ZeroKeyTerminates = 2;
	const int serop_ReturnIndex       = 4;

	internal void i7_opcode_binarysearch(int key, int keysize,
		int start, int structsize, int numstructs, int keyoffset,
		int options, out int s1) {

		/* If the key size is 4 or fewer, copy it directly into the keybuf array */
		byte[] keybuf = new byte[4];
		if ((options & serop_KeyIndirect) != 0) {
			if (keysize <= 4)
				for (int ix=0; ix<keysize; ix++)
					keybuf[ix] = i7_read_byte(key + ix);
		} else {
			switch (keysize) {
				case 4:
					keybuf[0] = I7BYTE_0(key); keybuf[1] = I7BYTE_1(key);
					keybuf[2] = I7BYTE_2(key); keybuf[3] = I7BYTE_3(key); break;
				case 2:
					keybuf[0] = I7BYTE_0(key); keybuf[1] = I7BYTE_1(key); break;
				case 1:
					keybuf[0] = (byte) key; break;
			}
		}

		int bot = 0, top = numstructs; /* Initial search range, including bot but not top */
		while (bot < top) { /* I.e., while the search range is not empty */
			/* Find the structure at the midpoint of the search range */
			int val = (top+bot) / 2;
			int addr = start + val * structsize;

			/* Compute cmp = 0 if the key matches this, -1 if it precedes, 1 if it follows */
			int cmp = 0;
			if (keysize <= 4) {
				for (int ix=0; (cmp == 0) && ix<keysize; ix++) {
					byte byte_ = i7_read_byte(addr + keyoffset + ix);
					byte byte2 = keybuf[ix];
					if (byte_ < byte2) cmp = -1;
					else if (byte_ > byte2) cmp = 1;
				}
			} else {
				for (int ix=0; (cmp == 0) && ix<keysize; ix++) {
					byte byte_  = i7_read_byte(addr + keyoffset + ix);
					byte byte2 = i7_read_byte(key + ix);
					if (byte_ < byte2) cmp = -1;
					else if (byte_ > byte2) cmp = 1;
				}
			}

			if (cmp == 0) {
				/* Success! */
				if ((options & serop_ReturnIndex) != 0) s1 = val; else s1 = addr;
				return;
			}

			if (cmp < 0) bot = val+1; /* Chop search range to the second half */
			else top = val; /* Chop search range to the first half */
		}

		/* Failure! */
		if ((options & serop_ReturnIndex) != 0) s1 = -1; else s1 = 0;
	}
=

@h mcopy, mzero, malloc, mfree.
A Glulx assembly opcode is provided for fast memory copies, which we must
implement. We're choosing not to implement the Glulx |@malloc| or |@mfree|
opcodes for now, but that will surely need to change in due course. (When that
does change, we will need also to change |@gestalt|.)

= (text to inform7_cslib.cs)
	internal void i7_opcode_mcopy(int x, int y, int z) {
		if (z < y)
			for (int i=0; i<x; i++)
				i7_write_byte(z+i, i7_read_byte(y+i));
		else
			for (int i=x-1; i>=0; i--)
				i7_write_byte(z+i, i7_read_byte(y+i));
	}

	internal void i7_opcode_mzero(int x, int y) {
		for (int i=0; i<x; i++) i7_write_byte(y+i, 0);
	}

	internal void i7_opcode_malloc(int x, int y) {
		Console.WriteLine("Unimplemented: i7_opcode_malloc.");
		i7_fatal_exit();
	}

	internal void i7_opcode_mfree(int x) {
		Console.WriteLine("Unimplemented: i7_opcode_mfree.");
		i7_fatal_exit();
	}
=

@h random, setrandom.
Note that the |random(...)| function built in to Inform is just a name for the
|@random| opcode, so we define that here too.

We have no convincing need for a statistically good random number algorithm,
but we do want cross-platform consistency in order that the test suite for Inform
should behave equivalently on MacOS, Linux and Windows -- at least when the
generator is seeded with the same value. To that end, we borrow the algorithm
used by the |frotz| Z-machine interpreter, which in turn is based on suggestions
in the Z-machine standards document.

= (text to inform7_cslib.cs)
	internal void i7_opcode_random(int x, out int y) {
		uint rawvalue = 0;
		if (state.seed.interval != 0) {
			rawvalue = state.seed.counter++;
			if (state.seed.counter == state.seed.interval) state.seed.counter = 0;
		} else {
			state.seed.A = (uint)(0x015a4e35L * state.seed.A + 1);;
			rawvalue = (state.seed.A >> 16) & 0x7fff;
		}
		uint value;
		if (x == 0) value = rawvalue;
		else if (x >= 1) value = rawvalue % (uint) (x);
		else value = (uint) -(rawvalue % (uint) (-x));
		y = (int) value;
	}

	internal void i7_opcode_setrandom(int s) {
		if (s == 0) {
			state.seed.A = (uint) DateTime.Now.Ticks;
			state.seed.interval = 0;
		} else if (s < 1000) {
			state.seed.interval = (uint) s;
			state.seed.counter = 0;
		} else {
			state.seed.A = (uint) s;
			state.seed.interval = 0;
		}
	}

	internal int i7_random(int x) {
		int r;
		i7_opcode_random(x, out r);
		return r+1;
	}
=

@h setiosys.
This opcode in principle allows a story file to select the input-output system
it will use. But the Inform kits only use system 2, called Glk, and this is the
only system we support, so we will simply ignore this.

= (text to inform7_cslib.cs)
	internal void i7_opcode_setiosys(int x, int y) {
	}
=

@h gestalt.
This opcode allows a story file to ask the Glulx interpreter running it whether
or not the interpreter can perform certain tasks.

= (text to inform7_cslib.cs)
	internal void i7_opcode_gestalt(int x, int y, out int z) {
		int r = 0;
		switch (x) {
			case 0: r = 0x00030103; break; /* Say that the Glulx version is v3.1.3 */
			case 1: r = 1;          break; /* Say that the interpreter version is 1 */
			case 2: r = 0;          break; /* We do not (yet) support @setmemsize */
			case 3: r = 1;          break; /* We do support UNDO */
			case 4: if (y == 2) r = 1;     /* We do support Glk */
						else r = 0;     /* But not any other I/O system */
					break;
			case 5: r = 1;          break; /* We do support Unicode operations */
			case 6: r = 1;          break; /* We do support @mzero and @mcopy */
			case 7: r = 0;          break; /* We do not (yet) support @malloc or @mfree */
			case 8: r = 0;          break; /* Since we do not support @malloc */
			case 9: r = 0;          break; /* We do not support @accelfunc pr @accelparam */
			case 10: r = 0;         break; /* And therefore provide none of their accelerants */
			case 11: r = 1;         break; /* We do support floating-point maths operations */
			case 12: r = 1;         break; /* We do support @hasundo and @discardundo */
		}
		z = r;
	}
}
=
