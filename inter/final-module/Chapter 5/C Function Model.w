[CFunctionModel::] C Function Model.

Translating functions into C, and the calling conventions needed for them.

@h Introduction.

=
void CFunctionModel::initialise(code_generator *cgt) {
	METHOD_ADD(cgt, PREDECLARE_FUNCTION_MTID, CFunctionModel::predeclare_function);
	METHOD_ADD(cgt, DECLARE_FUNCTION_MTID, CFunctionModel::declare_function);
	METHOD_ADD(cgt, PLACE_LABEL_MTID, CFunctionModel::place_label);
	METHOD_ADD(cgt, EVALUATE_LABEL_MTID, CFunctionModel::evaluate_label);
	METHOD_ADD(cgt, INVOKE_FUNCTION_MTID, CFunctionModel::invoke_function);
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
	CFunctionModel::write_hooks(gen);
}

@h Predeclaration.
So, then: each Inter function will lead to a corresponding C function. The
following places a predeclaration of that function high up in our C code, so
that we then don't need to worry about code-ordering when compiling calls to it:

=
void CFunctionModel::predeclare_function(code_generator *cgt, code_generation *gen,
	vanilla_function *vf) {
	segmentation_pos saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	CFunctionModel::prototype(gen, OUT, vf);
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
	i7word_t fn_i7_mgl_HelloThere(i7process_t *proc, i7word_t i7_mgl_local_greeting,
		i7word_t i7_mgl_local_x, 7word_t i7_mgl_local_y) {
		...
	}
=
And we then make calls like |fn_i7_mgl_HelloThere(proc, X, 0, 0)| or
|fn_i7_mgl_HelloThere(proc, X, Y, 0)| to simulate calling this with one or two
arguments respectively. Because unsupplied arguments are filled in as 0, we achieve
the Inter convention that any local variables not used as call arguments are set
to 0 at the start of a function. While this generates C code which does not look
especially pretty, it works efficiently in practice.

We give the return type as |i7word_t|. In Inter, there is no such thing as a void
function: all functions return something, even if that something is meaningless
and is then thrown away.

=
void CFunctionModel::C_function_identifier(code_generation *gen, OUTPUT_STREAM, vanilla_function *vf) {
	WRITE("fn_");
	Generators::mangle(gen, OUT, vf->identifier_as_constant);
}

void CFunctionModel::prototype(code_generation *gen, OUTPUT_STREAM, vanilla_function *vf) {
	WRITE("i7word_t ");
	CFunctionModel::C_function_identifier(gen, OUT, vf);
	WRITE("(i7process_t *proc");
	text_stream *local_name;
	LOOP_OVER_LINKED_LIST(local_name, text_stream, vf->locals) {
		WRITE(", i7word_t ");
		Generators::mangle(gen, OUT, local_name);
	}
	WRITE(")");
}

@h Function calls.

=
void CFunctionModel::invoke_function(code_generator *cgt, code_generation *gen,
	inter_symbol *fn, inter_tree_node *P, vanilla_function *vf, int void_context) {
	text_stream *OUT = CodeGen::current(gen);
	
	CFunctionModel::C_function_identifier(gen, OUT, vf);
	WRITE("(proc");
	if (vf->uses_vararg_model) {
		inter_tree_node *fargstuff[128];
		int c = 0;
		LOOP_THROUGH_INTER_CHILDREN(F, P) fargstuff[c++] = F;
		WRITE(", (");
		for (int i=c-1; i >= 0; i--) {
			WRITE("i7_push(proc, ");
			Vanilla::node(gen, fargstuff[i]);
			WRITE("), ");
		}
		WRITE("%d)", c);
		for (int i=1; i < vf->max_arity; i++) WRITE(", 0");
	} else {
		int c = 0;
		LOOP_THROUGH_INTER_CHILDREN(F, P) {
			WRITE(", "); Vanilla::node(gen, F);
			c++;
		}
		for (; c < vf->max_arity; c++) WRITE(", 0");
	}
	WRITE(")");
	if (void_context) WRITE(";\n");
}

@

=
text_stream *CFunctionModel::external_function(code_generation *gen, text_stream *fn) {
	dictionary *D = C_GEN_DATA(fndata.predeclared_external_functions);
	text_stream *key = Str::new();
	for (int i=10; i<Str::len(fn); i++)
		PUT_TO(key, Str::get_at(fn, i));
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

void CFunctionModel::declare_function_constant(code_generation *gen, vanilla_function *vf) {
	int seg = c_predeclarations_I7CGS;
	if (Str::eq(vf->identifier_as_constant, I"DealWithUndo")) seg = c_ids_and_maxima_I7CGS;
	if (Str::eq(vf->identifier_as_constant, I"TryAction")) seg = c_ids_and_maxima_I7CGS;
	segmentation_pos saved = CodeGen::select(gen, seg);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(NULL, OUT, vf->identifier_as_constant);
	WRITE(" (I7VAL_FUNCTIONS_BASE + %d)\n", vf->allocation_id);
	CodeGen::deselect(gen, saved);
}

void CFunctionModel::make_veneer_vf(code_generation *gen, text_stream *unmangled_name) {
	vanilla_function *vf = VanillaFunctions::new_vf(unmangled_name);
	vf->max_arity = 1;
	CFunctionModel::declare_function_constant(gen, vf);
}

void CFunctionModel::declare_function(code_generator *cgt, code_generation *gen, inter_symbol *fn, inter_tree_node *D, vanilla_function *vf) {
	text_stream *fn_name = Inter::Symbols::name(fn);
	segmentation_pos saved = CodeGen::select(gen, c_functions_at_eof_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	CFunctionModel::prototype(gen, OUT, vf);
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
	Vanilla::node(gen, D);
	C_GEN_DATA(fndata.compiling_function) = FALSE;
	WRITE("return 1;\n");
	WRITE("\n}\n\n");
	CodeGen::deselect(gen, saved);
}

void CFunctionModel::place_label(code_generator *cgt, code_generation *gen, text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
	WRITE(": ;\n", label_name);
}
void CFunctionModel::evaluate_label(code_generator *cgt, code_generation *gen, text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
}

int CFunctionModel::inside_function(code_generation *gen) {
	if (C_GEN_DATA(fndata.compiling_function)) return TRUE;
	return FALSE;
}

void CFunctionModel::write_gen_call(code_generation *gen) {
	segmentation_pos saved = CodeGen::select(gen, c_stubs_at_eof_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("i7word_t i7_gen_call(i7process_t *proc, i7word_t fn_ref, i7word_t *args, int argc) {\n"); INDENT;
	WRITE("int ssp = proc->state.stack_pointer;\n");
	WRITE("i7word_t rv = 0;\n");
	WRITE("switch (fn_ref) {\n"); INDENT;
	WRITE("case 0: rv = 0; break;\n");
	vanilla_function *vf;
	LOOP_OVER(vf, vanilla_function) {
		WRITE("case ");
		CNamespace::mangle(NULL, OUT, vf->identifier_as_constant);
		WRITE(": ");
		if (vf->uses_vararg_model) {
			WRITE("for (int i=argc-1; i>=0; i--) i7_push(proc, args[i]); ");
		}		
		WRITE("rv = ");
		CFunctionModel::C_function_identifier(gen, OUT, vf);
		WRITE("(");
		if (vf->uses_vararg_model) {
			WRITE("proc, argc");
			for (int i=0; i<vf->max_arity - 1; i++)
				WRITE(", 0");
		} else {
			WRITE("proc");
			for (int i=0; i<vf->max_arity; i++)
				WRITE(", args[%d]", i);
		}
		WRITE("); break;\n");
	}
	WRITE("default: printf(\"function %%d not found\\n\", fn_ref); break;\n");
	OUTDENT; WRITE("}\n");
	WRITE("proc->state.stack_pointer = ssp;\n");
	WRITE("return rv;\n");
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);
}

void CFunctionModel::write_hooks(code_generation *gen) {
	vanilla_function *vf;
	segmentation_pos saved = CodeGen::select(gen, c_stubs_at_eof_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	LOOP_OVER(vf, vanilla_function) {
		if (vf->formal_arity >= 0) {
			WRITE("i7word_t xfn_");
			CNamespace::mangle(NULL, OUT, vf->identifier_as_constant);
			WRITE("(i7process_t *proc");
			if (vf->formal_arity > 0) {
				for (int i=0; i<vf->formal_arity; i++) {
					WRITE(", ");
					WRITE("i7word_t p%d", i);
				}
			}
			WRITE(") {\n"); INDENT;
			WRITE("return ");
			CFunctionModel::C_function_identifier(gen, OUT, vf);
			WRITE("(proc");
			for (int i=0; i<vf->max_arity; i++) {
				WRITE(", ");
				if (i < vf->formal_arity) WRITE("p%d", i);
				else WRITE("0");
			}
			WRITE(");\n");			
			OUTDENT; WRITE("}\n");
		}
	}

	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_function_symbols_I7CGS);
	OUT = CodeGen::current(gen);
	LOOP_OVER(vf, vanilla_function) {
		if (vf->formal_arity >= 0) {
			TEMPORARY_TEXT(synopsis)
			VanillaFunctions::syntax_synopsis(synopsis, vf);
			TEMPORARY_TEXT(val)
			WRITE_TO(val, "xfn_");
			CNamespace::mangle(NULL, val, vf->identifier_as_constant);
			CObjectModel::define_header_constant_for_function(gen, synopsis, val);
			DISCARD_TEXT(val)
			DISCARD_TEXT(synopsis)
			WRITE("i7word_t xfn_");
			CNamespace::mangle(NULL, OUT, vf->identifier_as_constant);
			WRITE("(i7process_t *proc");
			if (vf->formal_arity > 0) {
				for (int i=0; i<vf->formal_arity; i++) {
					WRITE(", ");
					WRITE("i7word_t p%d", i);
				}
			}
			WRITE(");\n");
		}
	}	
	CodeGen::deselect(gen, saved);
}

@

= (text to inform7_clib.h)
i7word_t i7_call_0(i7process_t *proc, i7word_t fn_ref);
i7word_t i7_call_1(i7process_t *proc, i7word_t fn_ref, i7word_t v);
i7word_t i7_call_2(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2);
i7word_t i7_call_3(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3);
i7word_t i7_call_4(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3, i7word_t v4);
i7word_t i7_call_5(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3, i7word_t v4, i7word_t v5);
i7word_t i7_mcall_0(i7process_t *proc, i7word_t to, i7word_t prop);
i7word_t i7_mcall_1(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v);
i7word_t i7_mcall_2(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v, i7word_t v2);
i7word_t i7_mcall_3(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v, i7word_t v2, i7word_t v3);
i7word_t i7_gen_call(i7process_t *proc, i7word_t fn_ref, i7word_t *args, int argc);
=

= (text to inform7_clib.c)
i7word_t i7_call_0(i7process_t *proc, i7word_t fn_ref) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	return i7_gen_call(proc, fn_ref, args, 0);
}

i7word_t i7_mcall_0(i7process_t *proc, i7word_t to, i7word_t prop) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 0);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_1(i7process_t *proc, i7word_t fn_ref, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	return i7_gen_call(proc, fn_ref, args, 1);
}

i7word_t i7_mcall_1(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 1);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_2(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	return i7_gen_call(proc, fn_ref, args, 2);
}

i7word_t i7_mcall_2(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v, i7word_t v2) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 2);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_3(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	return i7_gen_call(proc, fn_ref, args, 3);
}

i7word_t i7_mcall_3(i7process_t *proc, i7word_t to, i7word_t prop, i7word_t v, i7word_t v2, i7word_t v3) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	i7word_t saved = proc->state.variables[i7_var_self];
	proc->state.variables[i7_var_self] = to;
	i7word_t fn_ref = i7_read_prop_value(proc, to, prop);
	i7word_t rv = i7_gen_call(proc, fn_ref, args, 3);
	proc->state.variables[i7_var_self] = saved;
	return rv;
}

i7word_t i7_call_4(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3, i7word_t v4) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4;
	return i7_gen_call(proc, fn_ref, args, 4);
}

i7word_t i7_call_5(i7process_t *proc, i7word_t fn_ref, i7word_t v, i7word_t v2, i7word_t v3, i7word_t v4, i7word_t v5) {
	i7word_t args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4; args[4] = v5;
	return i7_gen_call(proc, fn_ref, args, 5);
}

=
