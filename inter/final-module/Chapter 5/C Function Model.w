[CFunctionModel::] C Function Model.

Translating functions into C, and the calling conventions needed for them.

@

=
void CFunctionModel::initialise(code_generation_target *cgt) {
	METHOD_ADD(cgt, BEGIN_FUNCTION_MTID, CFunctionModel::begin_function);
	METHOD_ADD(cgt, DECLARE_LOCAL_VARIABLE_MTID, CFunctionModel::declare_local_variable);
	METHOD_ADD(cgt, BEGIN_FUNCTION_CODE_MTID, CFunctionModel::begin_function_code);
	METHOD_ADD(cgt, PLACE_LABEL_MTID, CFunctionModel::place_label);
	METHOD_ADD(cgt, END_FUNCTION_MTID, CFunctionModel::end_function);
	METHOD_ADD(cgt, FUNCTION_CALL_MTID, CFunctionModel::function_call);
}

typedef struct C_generation_function_model_data {
	struct text_stream *prototype;
	int argument_count;
	struct final_c_function *current_fcf;
	int compiling_function;
} C_generation_function_model_data;

void CFunctionModel::initialise_data(code_generation *gen) {
	C_GEN_DATA(fndata.prototype) = Str::new();
	C_GEN_DATA(fndata.argument_count) = 0;
	C_GEN_DATA(fndata.current_fcf) = NULL;
	C_GEN_DATA(fndata.compiling_function) = FALSE;
}

void CFunctionModel::begin(code_generation *gen) {
	CFunctionModel::initialise_data(gen);
	generated_segment *saved = CodeGen::select(gen, c_stubs_at_eof_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("void i7_initializer(void);\n");
	WRITE("void i7_initialise_streams(void);\n");
	WRITE("int main(int argc, char **argv) { i7_initializer(); i7_initialise_streams(); ");
	WRITE("fn_"); CNamespace::mangle(NULL, OUT, I"Main");
	WRITE("(0); return 0; }\n");
	CodeGen::deselect(gen, saved);
}

void CFunctionModel::end(code_generation *gen) {
	generated_segment *saved = CodeGen::select(gen, c_globals_array_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#ifdef i7_defined_i7_mgl_I7S_Comp\n");
	WRITE("#ifndef fn_i7_mgl_I7S_Comp\n");
	WRITE("i7val fn_i7_mgl_I7S_Comp(int argc, i7val a1, i7val a2, i7val a3, i7val a4, i7val a5) {\n");
	WRITE("    return i7_call_5(i7_mgl_I7S_Comp, a1, a2, a3, a4, a5);\n");
	WRITE("}\n");
	WRITE("#endif\n");
	WRITE("#endif\n");
	WRITE("#ifdef i7_defined_i7_mgl_I7S_Swap\n");
	WRITE("#ifndef fn_i7_mgl_I7S_Swap\n");
	WRITE("i7val fn_i7_mgl_I7S_Swap(int argc, i7val a1, i7val a2, i7val a3) {\n");
	WRITE("    return i7_call_3(i7_mgl_I7S_Swap, a1, a2, a3);\n");
	WRITE("}\n");
	WRITE("#endif\n");
	WRITE("#endif\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_fundamental_types_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("i7val i7_gen_call(i7val fn_ref, i7val *args, int argc);\n");
	CodeGen::deselect(gen, saved);

	saved = CodeGen::select(gen, c_stubs_at_eof_I7CGS);
	OUT = CodeGen::current(gen);
	WRITE("i7val i7_gen_call(i7val fn_ref, i7val *args, int argc) {\n"); INDENT;
	WRITE("switch (fn_ref) {\n"); INDENT;
	WRITE("case 0: return 0;\n");
	final_c_function *fcf;
	LOOP_OVER(fcf, final_c_function) {
		WRITE("case ");
		CNamespace::mangle(NULL, OUT, fcf->identifier_as_constant);
		WRITE(": ");
		if (fcf->uses_vararg_model) {
			WRITE("for (int i=argc-1; i>=0; i--) i7_push(args[i]); ");
		}		
		WRITE("return fn_");
		CNamespace::mangle(NULL, OUT, fcf->identifier_as_constant);
		WRITE("(");		
		if (fcf->uses_vararg_model) {
			WRITE("2, argc");
			for (int i=0; i<fcf->max_arity - 1; i++)
				WRITE(", 0");
		} else {
			WRITE("argc");
			for (int i=0; i<fcf->max_arity; i++)
				WRITE(", args[%d]", i);
		}
		WRITE(");\n");
	}
	OUTDENT; WRITE("}\n");
	WRITE("printf(\"function not found\\n\");\n");
	OUTDENT; WRITE("}\n");
	CodeGen::deselect(gen, saved);
}

typedef struct final_c_function {
	struct text_stream *identifier_as_constant;
	int uses_vararg_model;
	int max_arity;
	CLASS_DEFINITION
} final_c_function;

final_c_function *CFunctionModel::new_fcf(text_stream *unmangled_name) {
	final_c_function *fcf = CREATE(final_c_function);
	fcf->max_arity = 0;
	fcf->uses_vararg_model = FALSE;
	fcf->identifier_as_constant = Str::duplicate(unmangled_name);
	return fcf;
}

void CFunctionModel::declare_fcf(code_generation *gen, final_c_function *fcf) {
	generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
	text_stream *OUT = CodeGen::current(gen);
	WRITE("#define ");
	CNamespace::mangle(NULL, OUT, fcf->identifier_as_constant);
	WRITE(" (I7VAL_FUNCTIONS_BASE + %d)\n", fcf->allocation_id);
	CodeGen::deselect(gen, saved);
}

void CFunctionModel::make_veneer_fcf(code_generation *gen, text_stream *unmangled_name) {
	final_c_function *fcf = CFunctionModel::new_fcf(unmangled_name);
	fcf->max_arity = 1;
	CFunctionModel::declare_fcf(gen, fcf);
}

void CFunctionModel::begin_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	text_stream *fn_name = CodeGen::CL::name(fn);
	C_GEN_DATA(fndata.argument_count) = 0;
	if (pass == 1) {
		C_GEN_DATA(fndata.current_fcf) = CFunctionModel::new_fcf(fn_name);
		fn->translation_data = STORE_POINTER_final_c_function(C_GEN_DATA(fndata.current_fcf));
		Str::clear(C_GEN_DATA(fndata.prototype));
		WRITE_TO(C_GEN_DATA(fndata.prototype), "i7val fn_");
		CNamespace::mangle(cgt, C_GEN_DATA(fndata.prototype), fn_name);
		WRITE_TO(C_GEN_DATA(fndata.prototype), "(int __argc");
	}
	if (pass == 2) {
		C_GEN_DATA(fndata.current_fcf) = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("i7val fn_");
		CNamespace::mangle(cgt, OUT, fn_name);
		WRITE("(int __argc");
	}
}

void CFunctionModel::begin_function_code(code_generation_target *cgt, code_generation *gen) {
	text_stream *OUT = CodeGen::current(gen);
	WRITE(") {");
	if (C_GEN_DATA(fndata.current_fcf)) {
		if (FALSE) {
			WRITE("printf(\"called %S\\n\");\n", C_GEN_DATA(fndata.current_fcf)->identifier_as_constant);
		}
//		if (C_GEN_DATA(fndata.current_fcf)->uses_vararg_model) {
//			WRITE("for (int i=0; i<i7_mgl_local__vararg_count; i++) i7_push(i7_mgl__varargs.args[i]);\n");
//		}
		WRITE("i7_debug_stack(\"%S\");", C_GEN_DATA(fndata.current_fcf)->identifier_as_constant);
	}
	C_GEN_DATA(fndata.compiling_function) = TRUE;
}

void CFunctionModel::place_label(code_generation_target *cgt, code_generation *gen, text_stream *label_name) {
	text_stream *OUT = CodeGen::current(gen);
	LOOP_THROUGH_TEXT(pos, label_name)
		if (Str::get(pos) != '.')
			PUT(Str::get(pos));
	WRITE(": ;\n", label_name);
}

void CFunctionModel::end_function(code_generation_target *cgt, int pass, code_generation *gen, inter_symbol *fn) {
	if (pass == 1) {
		WRITE_TO(C_GEN_DATA(fndata.prototype), ")");

		generated_segment *saved = CodeGen::select(gen, c_predeclarations_I7CGS);
		text_stream *OUT = CodeGen::current(gen);
		WRITE("%S;\n", C_GEN_DATA(fndata.prototype));
		CodeGen::deselect(gen, saved);

		final_c_function *fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);
		CFunctionModel::declare_fcf(gen, fcf);
	}
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE("return 1;\n");
		WRITE("\n}\n");
		C_GEN_DATA(fndata.compiling_function) = FALSE;
	}
}

int CFunctionModel::inside_function(code_generation *gen) {
	if (C_GEN_DATA(fndata.compiling_function)) return TRUE;
	return FALSE;
}

void CFunctionModel::function_call(code_generation_target *cgt, code_generation *gen, inter_symbol *fn, inter_tree_node *P, int argc) {
	inter_tree_node *D = fn->definition;
	if ((D) && (D->W.data[ID_IFLD] == CONSTANT_IST) && (D->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT)) {
		inter_ti val1 = D->W.data[DATA_CONST_IFLD];
		inter_ti val2 = D->W.data[DATA_CONST_IFLD + 1];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(D));
			if (aliased) fn = aliased;
		}
	}
	final_c_function *fcf = NULL;
	if (GENERAL_POINTER_IS_NULL(fn->translation_data) == FALSE)
		fcf = RETRIEVE_POINTER_final_c_function(fn->translation_data);

	text_stream *fn_name = CodeGen::CL::name(fn);
	text_stream *OUT = CodeGen::current(gen);
	
	inter_tree_node *fargstuff[128];
	
	WRITE("fn_");
	CNamespace::mangle(cgt, OUT, fn_name);
	WRITE("(%d", argc);

	int c = 0;
	LOOP_THROUGH_INTER_CHILDREN(F, P) {
		if (fcf) {
			if (fcf->uses_vararg_model) fargstuff[c] = F;
			else { WRITE(", "); CodeGen::FC::frame(gen, F); }
		} else {
			WRITE(", ");
			CodeGen::FC::frame(gen, F);
		}
		c++;
	}

	if (fcf) {
		if (fcf->uses_vararg_model) {
			WRITE(", (");
			for (int i=argc-1; i >= 0; i--) {
				WRITE("i7_push(");
				CodeGen::FC::frame(gen, fargstuff[i]);
				WRITE("), ");
			}
			WRITE("%d)", argc);
			argc = 1;
		}
		while (argc < fcf->max_arity) {
			WRITE(", 0");
			argc++;
		}
	}
	WRITE(")");
}

void CFunctionModel::declare_local_variable(code_generation_target *cgt, int pass,
	code_generation *gen, inter_tree_node *P, inter_symbol *var_name) {
	TEMPORARY_TEXT(name)
	CNamespace::mangle(cgt, name, CodeGen::CL::name(var_name));
	C_GEN_DATA(fndata.argument_count)++;
	if (pass == 1) {
		if (Str::eq(var_name->symbol_name, I"_vararg_count")) {
			C_GEN_DATA(fndata.current_fcf)->uses_vararg_model = TRUE;
			WRITE_TO(C_GEN_DATA(fndata.prototype), ", i7val %S", name);
		} else {
			WRITE_TO(C_GEN_DATA(fndata.prototype), ", i7val %S", name);
		}
		C_GEN_DATA(fndata.current_fcf)->max_arity++;
	}
	if (pass == 2) {
		text_stream *OUT = CodeGen::current(gen);
		WRITE(", i7val %S", name);
	}
	DISCARD_TEXT(name)
}

@

= (text to inform7_clib.h)
i7val i7_mgl_self = 0;

i7val i7_call_0(i7val fn_ref) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	return i7_gen_call(fn_ref, args, 0);
}

i7val i7_mcall_0(i7val fn_ref) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	i7val saved = i7_mgl_self;
	i7val rv = i7_gen_call(fn_ref, args, 0);
	i7_mgl_self = saved;
	return rv;
}

i7val i7_call_1(i7val fn_ref, i7val v) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	return i7_gen_call(fn_ref, args, 1);
}

i7val i7_mcall_1(i7val fn_ref, i7val v) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v;
	i7val saved = i7_mgl_self;
	i7val rv = i7_gen_call(fn_ref, args, 1);
	i7_mgl_self = saved;
	return rv;
}

i7val i7_call_2(i7val fn_ref, i7val v, i7val v2) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	return i7_gen_call(fn_ref, args, 2);
}

i7val i7_mcall_2(i7val fn_ref, i7val v, i7val v2) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2;
	i7val saved = i7_mgl_self;
	i7val rv = i7_gen_call(fn_ref, args, 2);
	i7_mgl_self = saved;
	return rv;
}

i7val i7_call_3(i7val fn_ref, i7val v, i7val v2, i7val v3) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	return i7_gen_call(fn_ref, args, 3);
}

i7val i7_mcall_3(i7val fn_ref, i7val v, i7val v2, i7val v3) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3;
	i7val saved = i7_mgl_self;
	i7val rv = i7_gen_call(fn_ref, args, 3);
	i7_mgl_self = saved;
	return rv;
}

i7val i7_call_4(i7val fn_ref, i7val v, i7val v2, i7val v3, i7val v4) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4;
	return i7_gen_call(fn_ref, args, 4);
}

i7val i7_call_5(i7val fn_ref, i7val v, i7val v2, i7val v3, i7val v4, i7val v5) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	args[0] = v; args[1] = v2; args[2] = v3; args[3] = v4; args[4] = v5;
	return i7_gen_call(fn_ref, args, 5);
}

void glulx_call(i7val fn_ref, i7val varargc, i7val *z) {
	i7val args[10]; for (int i=0; i<10; i++) args[i] = 0;
	for (int i=0; i<varargc; i++) args[i] = i7_pull();
	i7val rv = i7_gen_call(fn_ref, args, varargc);
	if (z) *z = rv;
}
=
