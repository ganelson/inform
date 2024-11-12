[CFunctionModel::] C Function Model.

Translating functions into C, and the calling conventions needed for them.

@h Introduction.

=
void CFunctionModel::initialise(code_generator *gtr) {
	METHOD_ADD(gtr, PREDECLARE_FUNCTION_MTID, CFunctionModel::predeclare_function);
	METHOD_ADD(gtr, DECLARE_FUNCTION_MTID, CFunctionModel::declare_function);
	METHOD_ADD(gtr, PLACE_LABEL_MTID, CFunctionModel::place_label);
	METHOD_ADD(gtr, EVALUATE_LABEL_MTID, CFunctionModel::evaluate_label);
	METHOD_ADD(gtr, INVOKE_FUNCTION_MTID, CFunctionModel::invoke_function);
}

typedef struct C_generation_function_model_data {
	int compiling_function;
	struct dictionary *predeclared_external_functions;
} C_generation_function_model_data;

void CFunctionModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(fndata.compiling_function) = FALSE;
	C_GEN_DATA(fndata.predeclared_external_functions) = Dictionaries::new(1024, TRUE);
}

void CFunctionModel::begin(code_generation *gen) {
	CFunctionModel::initialise_data(gen);
}

void CFunctionModel::end(code_generation *gen) {
	CFunctionModel::write_gen_call(gen);
	CFunctionModel::write_inward_calling_wrappers(gen);
}

@h Predeclaration.
So, then: each Inter function will lead to a corresponding C function. The
following places a predeclaration of that function high up in our C code, so
that we then don't need to worry about code-ordering when compiling calls to it:

=
void CFunctionModel::predeclare_function(code_generator *gtr, code_generation *gen,
	vanilla_function *vf) {
	segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	CFunctionModel::C_function_prototype(gen, OUT, vf);
	WRITE(";\n");
	CodeGen::deselect(gen, saved);
	CFunctionModel::declare_function_constant(gen, vf);
}

@ And this expresses what the C prototype for that function will be. For example,
suppose we have an Inter function which arises from a kit function reading like so:
= (text as Inform 6)
	[ HelloThere greeting x y;
		...
	];
=
Now in practice this function may always be called as |HelloThere("Aloha!")| or
similar, with the local variable |greeting| being an argument, and the other two
locals |x| and |y| being used only internally. But Inter does not distinguish between
arguments and private locals; and indeed it permits the same function to be called
with differing numbers of arguments. |HelloThere("Bonjour!", 31)| is a legal call,
and results in |x| initially being 31 rather than 0.

Because of this, our C analogue must also be callable with a variable number of
arguments. Now, of course, C does have a crude mechanism for this (used for |printf|
and similar), but it's nowhere near flexible enough to handle what we need.
Instead we declare our C function like so:
= (text as Inform 6)
	i7word_t i7_fn_HelloThere(i7process_t *proc, i7word_t i7_mgl_local_greeting,
		i7word_t i7_mgl_local_x, 7word_t i7_mgl_local_y) {
		...
	}
=
And we then make calls like |i7_fn_HelloThere(proc, X, 0, 0)| or
|i7_fn_HelloThere(proc, X, Y, 0)| to simulate calling this with one or two
arguments respectively. Because unsupplied arguments are filled in as 0, we achieve
the Inter convention that any local variables not used as call arguments are set
to 0 at the start of a function. While this generates C code which does not look
especially pretty, it works efficiently in practice.

We give the return type as |i7word_t|. In Inter, there is no such thing as a void
function: all functions return something, even if that something is meaningless
and is then thrown away.

=
void CFunctionModel::C_function_identifier(code_generation *gen, OUTPUT_STREAM,
	vanilla_function *vf) {
	CNamespace::mangle_with(NULL, OUT, vf->identifier, I"fn");
}

void CFunctionModel::C_function_prototype(code_generation *gen, OUTPUT_STREAM,
	vanilla_function *vf) {
	WRITE("i7word_t ");
	CFunctionModel::C_function_identifier(gen, OUT, vf);
	WRITE("(i7process_t *proc");

	text_stream *local_name; int c = 0;
	LOOP_OVER_LINKED_LIST(local_name, text_stream, vf->locals) {
		WRITE(", i7word_t ");
		Generators::mangle(gen, OUT, local_name);
		if (++c == vf->max_arity) break;
	}
	WRITE(")");
}

@h Functions as values.
A function is a value in Inter, and can be stored in variables, or arrays, or
properties, and so on. The Vanilla algorithm expects that the mangled name of
the function identifier will evaluate to this value.

But what is this value to be? The obvious thing would be to represent the Inter
function at runtime by a pointer to the C function it has become. We could then
dereference that pointer to perform a function call, and so on. But this doesn't
work, because C does not allow function pointers to be used in a constant context.

This is why the function //CFunctionModel::C_function_identifier// writes an
identifier which is _not_ the same as the mangled function name. Instead, the
mangled function name is defined as a constant, as follows.

=
void CFunctionModel::declare_function_constant(code_generation *gen, vanilla_function *vf) {
	segmentation_pos saved = CodeGen::select(gen, c_function_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(NULL, OUT, vf->identifier);
	WRITE(" (I7VAL_FUNCTIONS_BASE + %d)\n", vf->allocation_id);
	CodeGen::deselect(gen, saved);
}

@h Function calls.
First, the straightforward and most common case: calling a function whose identity
is known at run-time, and is passed to us as |vf|.

=
void CFunctionModel::invoke_function(code_generator *gtr, code_generation *gen,
	inter_tree_node *P, vanilla_function *vf, int void_context) {
	text_stream *OUT = CodeGen::current(gen);
	CFunctionModel::C_function_identifier(gen, OUT, vf);
	WRITE("(proc");
	if (vf->takes_variable_arguments) @<Supply arguments on the stack@>
	else @<Supply arguments as call parameters@>;
	WRITE(")");
	if (void_context) WRITE(";\n");
}

@ As noted above, all unsupplied call parameters are filled in with zeroes:

@<Supply arguments as call parameters@> =
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P) {
		WRITE(", "); Vanilla::node(gen, F);
		c++;
	}
	for (; c < vf->max_arity; c++) WRITE(", 0");

@ A handful of functions, always supplied by kits (i.e., never compiled directly
by Inform 7), use a stack-based calling mechanism instead. For example:
= (text as Inform 6)
[ whatever _vararg_count ret;
    ...
];
=
The significant thing here is that the first local variable is called |_vararg_count|.
The Inform 6 compiler reacts to that by using a different function call mechanism;
the function call |whatever(x, y, z)| will then result in |x|, |y|, |z| being pushed
onto the stack, while execution in the function begins with |_vararg_count| equal
to 3 (the number of things pushed), and |ret| equal to 0.

Note that the arguments must be pushed in reverse order -- |z|, |y|, |x| -- in
order to ensure that the first one, |x|, is at the top of the stack when execution
of the function begins.

But of course a C compiler will not automatically do that just because the first
local happens to be called |_vararg_count|, so we must simulate the effect here.

In practice, the maximum number of variable arguments needed is seldom more than
about 3 and never more than 10 in I7 usage, so the maximum here is not at all
restrictive.

@d MAX_VARARG_COUNT 128

@<Supply arguments on the stack@> =
	inter_tree_node *args[MAX_VARARG_COUNT];
	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P) if (c < MAX_VARARG_COUNT) args[c++] = F;
	WRITE(", (");
	for (int i=c-1; i >= 0; i--) {
		WRITE("i7_push(proc, ");
		Vanilla::node(gen, args[i]);
		WRITE("), ");
	}
	WRITE("%d)", c);
	for (int i=1; i < vf->max_arity; i++) WRITE(", 0");

@ Now the harder case: calling a function whose identity is not known at compile
time, but which is identified only as a runtime value which will be one of the
numbers defined above. This is done with a function called |i7_gen_call|, and
that is what we must now compile:

= (text to inform7_clib.h)
i7word_t i7_gen_call(i7process_t *proc, i7word_t id, i7word_t *args, int argc);
=

The structure is basically one big switch. In simplified pseudocode it looks like so:
= (text as C)
	switch (function_id_number) {
		case id1: rv = fn1(proc, arg1); break;
		case id2: rv = fn2(proc, arg1, arg2, arg3); break;
		...
	}
=
That seems inefficient: instead, why not store the addresses of the relevant
functions in a lookup table? After all, the case ID numbers are just a consecutive
run of integers.

But we can't do that because in the C standard there is no safe way to cast or
store those pointer types in a way which would safely be a union of the possible
function types. All of the things which probably work on most architectures are
formally "undefined behavior" in C99; we cannot, for example, assume that function
pointers have the same size (in the |sizeof| sense) as other pointers, or even that
a pointer to a function of three arguments has the same size as a pointer to a
function of two. (Almost certainly it does: but the C99 standard is pretty clear
that you take your life into your own hands making these casual assumptions.)

On the brighter side, though, modern C compilers are good at compiling switch
statements with easy-to-index case numbers in an efficient way: so what we cannot
legally express in source code will quite likely be what it compiles anyway,
and it is unlikely that |i7_gen_call| will be slow.

=
void CFunctionModel::write_gen_call(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_function_callers_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7word_t i7_gen_call(\n");
	WRITE("i7process_t *proc, i7word_t id, i7word_t *args, int argc) {\n"); INDENT;
	WRITE("i7word_t rv = 0;\n");
	WRITE("switch (id) {\n"); INDENT;
	WRITE("case 0: rv = 0; break;\n");
	vanilla_function *vf;
	LOOP_OVER(vf, vanilla_function) {
		WRITE("case ");
		CNamespace::mangle(NULL, OUT, vf->identifier);
		WRITE(": ");
		if (vf->takes_variable_arguments) @<Supply general arguments on the stack@>
		else @<Supply general arguments as call parameters@>;
		WRITE(" break;\n");
	}
	WRITE("default: printf(\"function %%d not found\\n\", id); i7_fatal_exit(proc); break;\n");
	OUTDENT; WRITE("}\n");
	WRITE("return rv;\n");
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);
}

@<Supply general arguments as call parameters@> =
	WRITE("rv = ");
	CFunctionModel::C_function_identifier(gen, OUT, vf);
	WRITE("(proc");
	for (int i=0; i<vf->max_arity; i++) WRITE(", args[%d]", i);
	WRITE(");");

@<Supply general arguments on the stack@> =
	WRITE("for (int i=argc-1; i>=0; i--) i7_push(proc, args[i]); ");
	WRITE("rv = ");
	CFunctionModel::C_function_identifier(gen, OUT, vf);
	WRITE("(proc, argc");
	for (int i=1; i<vf->max_arity; i++) WRITE(", 0");
	WRITE(");\n");

@h Declaring functions.
This is now straightforward except for one last annoying part of the Inter calling
convention.

It is legal for an Inter function to leave pushed values still on the stack when
it exits. If the function takes varargs, those values allow for exotic forms of
return value, and are left there for the caller to deal with (or not). But if
it's a regular, non-varargs sort of function, then the stack must be restored
to the status quo ante when the function returns, just as if it had properly
pulled all the values it had pushed.

We deal with this by having a "stack-safe" version of the function whose only
job is to save the stack pointer, call the "unsafe" (i.e. real) version of the
function, then restore the stack pointer again.

The C types of the safe and unsafe functions are identical, so the following
look much like //CFunctionModel::C_function_identifier// and
//CFunctionModel::C_function_prototype//.

=
void CFunctionModel::unsafe_C_function_identifier(code_generation *gen, OUTPUT_STREAM,
	vanilla_function *vf) {
	CNamespace::mangle_with(NULL, OUT, vf->identifier, I"ifn");
}

void CFunctionModel::unsafe_C_function_prototype(code_generation *gen, OUTPUT_STREAM,
	vanilla_function *vf) {
	WRITE("i7word_t ");
	CFunctionModel::unsafe_C_function_identifier(gen, OUT, vf);
	WRITE("(i7process_t *proc");
	text_stream *local_name;
	LOOP_OVER_LINKED_LIST(local_name, text_stream, vf->locals) {
		WRITE(", i7word_t ");
		Generators::mangle(gen, OUT, local_name);
	}
	WRITE(")");
}

@ =
void CFunctionModel::declare_function(code_generator *gtr, code_generation *gen,
	vanilla_function *vf) {
	text_stream *fn_name = vf->identifier;
	segmentation_pos saved = CodeGen::select(gen, c_function_declarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	@<Compile the functional part@>;
	if (vf->takes_variable_arguments == FALSE) @<Compile the stack-safe outer function@>;
	CodeGen::deselect(gen, saved);
}

@<Compile the functional part@> =
	if (vf->takes_variable_arguments) CFunctionModel::C_function_prototype(gen, OUT, vf);
	else CFunctionModel::unsafe_C_function_prototype(gen, OUT, vf);
	WRITE(" {\n");
	WRITE("i7_debug_stack(\"%S\");\n", fn_name);
	if (Str::eq(fn_name, I"DebugAction")) {
		WRITE("switch (i7_mgl_local_a) {\n");
		text_stream *aname;
		LOOP_OVER_LINKED_LIST(aname, text_stream, gen->actions) {
			WRITE("case i7_ss_%S", aname);
			WRITE(": printf(\"%S\"); return 1;\n", aname);
		}
		WRITE("}\n");
	}
	C_GEN_DATA(fndata.compiling_function) = TRUE;
	Vanilla::node(gen, vf->function_body);
	C_GEN_DATA(fndata.compiling_function) = FALSE;
	WRITE("return 1;\n");
	WRITE("\n}\n\n");

@<Compile the stack-safe outer function@> =
	CFunctionModel::C_function_prototype(gen, OUT, vf);
	WRITE(" {\n");
	WRITE("int ssp = proc->state.stack_pointer;\n");
	WRITE("i7word_t rv = ");
	CFunctionModel::unsafe_C_function_identifier(gen, OUT, vf);
	WRITE("(proc");
	int c = 0;
	text_stream *local_name;
	LOOP_OVER_LINKED_LIST(local_name, text_stream, vf->locals) {
		WRITE(", ");
		if (++c <= vf->max_arity)
			Generators::mangle(gen, OUT, local_name);
		else
			WRITE("0");
	}
	WRITE(");\n");
	WRITE("proc->state.stack_pointer = ssp;\n", vf->identifier);
	WRITE("return rv;\n");
	WRITE("\n}\n\n");

@ =
int CFunctionModel::inside_function(code_generation *gen) {
	if (C_GEN_DATA(fndata.compiling_function)) return TRUE;
	return FALSE;
}

@ Labels can be placed in C code with the notation |LabelName:|, but note that
in C it is a syntax error for a label to occur at the end of a block, e.g.,
|while (1) { ...; EndOfLoop: }| is a syntax error. This can be put right with
an empty statement, i.e., a semicolon: |while (1) { ...; EndOfLoop: ; }|
And in case that is what we need here, we always place an empty statement after
a label.

=
void CFunctionModel::place_label(code_generator *gtr, code_generation *gen,
	text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
	WRITE(": ;\n", label_name);
}

@ Labels are not really "evaluated" in C: |goto| destinations are not values.
Evaluation in this sense just means compiling the name used a sort of argument
to the |goto| statement.

Note that label names, whose scope is confined to the function in which they
occur, are unmangled. This is safe because label names have their own namespace
in C, so they cannot clash with other identifiers.

=
void CFunctionModel::evaluate_label(code_generator *gtr, code_generation *gen,
	text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

@h Outward-bound function calls.
"Outward" here means "when a function compiled from Inter makes a call to a C
function from the world outside, i.e., which wasn't compiled from Inter". This
is done with the |!externalcall| primitive: see below.

In order to make the linking work, we need to ensure that our code declares
the external function's name before use. But we should do this only for those
functions we actually need to call, and only once for each of them. So we keep
a dictionary of those already declared.

Note that all external identifiers begin with |external__|, which is 10 characters
long.

=
text_stream *CFunctionModel::ensure_external_function_predeclared(code_generation *gen,
	text_stream *external_identifier) {
	dictionary *D = C_GEN_DATA(fndata.predeclared_external_functions);
	text_stream *key = Str::new();
	for (int i=10; i<Str::len(external_identifier); i++)
		PUT_TO(key, Str::get_at(external_identifier, i));
	text_stream *dv = Dictionaries::get_text(D, key);
	if (dv == NULL) {
		Dictionaries::create_text(D, key);
		segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE_TO(OUT, "i7word_t %S(i7process_t *proc, i7word_t arg);\n", key);
		CodeGen::deselect(gen, saved);		
	}
	return key;
}

@h Inward-bound function calls.
"Inward" here means "when a C function not compiled from Inter calls one which
is": that is, when the world outside wants to call into some portion of an
Inform program.

In principle, the caller could just imitate our own calling convention, i.e.,
could do something like what //CFunctionModel::invoke_function// does. But in
practice this is a messy business, in that it makes for illegible code, so we
provide something easier on the eyes.

In particular, for each function arising from Inform 7 source text, we deduce
the "formal arity" (the actual number of arguments it takes) and make a wrapper
function which has just those as arguments. The wrapper then calls the real
function, filling in all the bogus arguments as 0.

=
void CFunctionModel::inward_C_function_identifier(code_generation *gen, OUTPUT_STREAM,
	vanilla_function *vf) {
	CNamespace::mangle_with(NULL, OUT, vf->identifier, I"xfn");
}

void CFunctionModel::inward_C_function_prototype(code_generation *gen, OUTPUT_STREAM,
	vanilla_function *vf) {
	WRITE("i7word_t ");
	CFunctionModel::inward_C_function_identifier(gen, OUT, vf);
	WRITE("(i7process_t *proc");
	for (int i=0; i<vf->formal_arity; i++) WRITE(", i7word_t p%d", i);
	WRITE(")");
}

@ =
void CFunctionModel::write_inward_calling_wrappers(code_generation *gen) {
	vanilla_function *vf;
	LOOP_OVER(vf, vanilla_function) {
		@<Compile a wrapper function for inward calling@>;
		@<Define a more friendly alias for the wrapper function name@>;
		@<Compile a predeclaration for the wrapper function for inward calling@>;
	}	
}

@ This goes into the main C file we are compiling.

@<Compile a wrapper function for inward calling@> =
	segmentation_pos saved = CodeGen::select(gen, c_function_callers_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	CFunctionModel::inward_C_function_prototype(gen, OUT, vf); WRITE(" {\n"); INDENT;
	WRITE("return ");
	CFunctionModel::C_function_identifier(gen, OUT, vf);
	WRITE("(proc");
	for (int i=0; i<vf->max_arity; i++) {
		WRITE(", ");
		if (i < vf->formal_arity) WRITE("p%d", i); else WRITE("0");
	}
	WRITE(");\n");			
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);

@ This goes into the secondary header file, and predeclares the wrapper function
for linking purposes.

@<Compile a predeclaration for the wrapper function for inward calling@> =
	segmentation_pos saved = CodeGen::select(gen, c_function_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	CFunctionModel::inward_C_function_prototype(gen, OUT, vf); WRITE(";\n");
	CodeGen::deselect(gen, saved);

@ Similarly, this for the header file produces a nicer name which can be used
for the wrapper.

@<Define a more friendly alias for the wrapper function name@> =
	TEMPORARY_TEXT(synopsis)
	VanillaFunctions::syntax_synopsis(synopsis, vf);
	TEMPORARY_TEXT(val)
	CFunctionModel::inward_C_function_identifier(gen, val, vf);
	segmentation_pos saved = CodeGen::select(gen, c_function_symbols_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define %S %S\n", CTarget::symbols_header_identifier(gen, I"F", synopsis), val);
	CodeGen::deselect(gen, saved);
	DISCARD_TEXT(val)
	DISCARD_TEXT(synopsis)

@h Primitives for indirect or external function calls.
Most function calls are made explicitly: see //CFunctionModel::invoke_function//
above. But the Inter primitives below offer a way to call functions whose identities
are not known at compile time, or which are not even part of the Inter program.

The following primitives all simply call functions |i7_call_0|, and so on -- see
below for their definitions -- except for |!externalcall|.

=
int CFunctionModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case INDIRECT0_BIP: case INDIRECT0V_BIP:
			WRITE("i7_call_0(proc, "); VNODE_1C; WRITE(")"); break;
		case INDIRECT1_BIP: case INDIRECT1V_BIP:
			WRITE("i7_call_1(proc, "); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(")"); break;
		case INDIRECT2_BIP: case INDIRECT2V_BIP:
			WRITE("i7_call_2(proc, "); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE(")"); break;
		case INDIRECT3_BIP: case INDIRECT3V_BIP:
			WRITE("i7_call_3(proc, "); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE(", "); VNODE_4C; WRITE(")"); break;
		case INDIRECT4_BIP: case INDIRECT4V_BIP:
			WRITE("i7_call_4(proc, "); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE(", "); VNODE_4C; WRITE(", ");
			VNODE_5C; WRITE(")"); break;
		case INDIRECT5_BIP: case INDIRECT5V_BIP:
			WRITE("i7_call_5(proc, "); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE(", "); VNODE_4C; WRITE(", ");
			VNODE_5C; WRITE(", "); VNODE_6C; WRITE(")"); break;
		case INDIRECT6_BIP: case INDIRECT6V_BIP:
			WRITE("i7_call_6(proc, "); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE(", "); VNODE_4C; WRITE(", ");
			VNODE_5C; WRITE(", "); VNODE_6C; WRITE(", "); VNODE_7C; WRITE(")"); break;
		case MESSAGE0_BIP:
			WRITE("i7_mcall_0(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		case MESSAGE1_BIP:
			WRITE("i7_mcall_1(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(")"); break;
		case MESSAGE2_BIP:
			WRITE("i7_mcall_2(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(", "); VNODE_4C; WRITE(")"); break;
		case MESSAGE3_BIP:
			WRITE("i7_mcall_3(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", ");
			VNODE_3C; WRITE(", "); VNODE_4C; WRITE(", "); VNODE_5C; WRITE(")"); break;
		case EXTERNALCALL_BIP:
			@<Generate primitive for externalcall@>; break;
		default:
			return NOT_APPLICABLE;
	}
	return FALSE;
}

@<Generate primitive for externalcall@> =
	inter_tree_node *N = InterTree::first_child(P);
	if (Inode::is(N, VAL_IST)) {
		inter_pair val = ValInstruction::value(N);
		if (InterValuePairs::is_text(val)) {
			text_stream *text = InterValuePairs::to_text(gen->from, val);
			WRITE("%S(proc, ",
				CFunctionModel::ensure_external_function_predeclared(gen, text));
			VNODE_2C; WRITE(")");
		} else {
			internal_error("unimplemented form of !externalcall");
		}
	} else {
		internal_error("unimplemented form of !externalcall");
	}

@ The following functions implement the above. |i7_call_N| provides a general
way to call an Inter function with |N| arguments, up to 5.

= (text to inform7_clib.h)
i7word_t i7_call_0(i7process_t *proc, i7word_t id);
i7word_t i7_call_1(i7process_t *proc, i7word_t id, i7word_t v);
i7word_t i7_call_2(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2);
i7word_t i7_call_3(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2, i7word_t v3);
i7word_t i7_call_4(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2, i7word_t v3,
	i7word_t v4);
i7word_t i7_call_5(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2, i7word_t v3,
	i7word_t v4, i7word_t v5);
=

But these are not really different from each other: they all simply call |i7_gen_call|,
the function we compiled laboriously in //CFunctionModel::write_gen_call// above,
to do the actual business.

= (text to inform7_clib.c)
i7word_t i7_call_0(i7process_t *proc, i7word_t id) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	return i7_gen_call(proc, id, args, 0);
}
i7word_t i7_call_1(i7process_t *proc, i7word_t id, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	return i7_gen_call(proc, id, args, 1);
}
i7word_t i7_call_2(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	return i7_gen_call(proc, id, args, 2);
}
i7word_t i7_call_3(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2,
	i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	return i7_gen_call(proc, id, args, 3);
}
i7word_t i7_call_4(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2,
	i7word_t v3, i7word_t v4) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4;
	return i7_gen_call(proc, id, args, 4);
}
i7word_t i7_call_5(i7process_t *proc, i7word_t id, i7word_t v, i7word_t v2,
	i7word_t v3, i7word_t v4, i7word_t v5) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4; args[4] = v5;
	return i7_gen_call(proc, id, args, 5);
}
=

@ The following functions implement the above. |i7_mcall_N| provides a general
way to make a "message call" to an Inter function with |N| arguments, up to 3.
Message calls are really the same as regular function calls, except that the
function ID is read from a property of an object, and except that the |self|
variable has to be set to that object when the function is running (and restored
back to its previous value afterwards). Again, we use |i7_gen_call| to do the
actual work.

= (text to inform7_clib.h)
i7word_t i7_mcall_0(i7process_t *proc, i7word_t to, i7word_t prop);
i7word_t i7_mcall_1(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v);
i7word_t i7_mcall_2(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2);
i7word_t i7_mcall_3(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2, i7word_t v3);
=

= (text to inform7_clib.c)
i7word_t i7_mcall_0(i7process_t *proc, i7word_t to, i7word_t prop) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 0);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_mcall_1(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 1);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_mcall_2(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 2);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_mcall_3(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v,
	i7word_t v2, i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t id = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, id, args, 3);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}
=
