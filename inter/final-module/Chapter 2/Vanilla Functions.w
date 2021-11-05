[VanillaFunctions::] Vanilla Functions.

How the vanilla code generation strategy declares functions.

@

=
typedef struct vanilla_function {
	struct text_stream *identifier_as_constant;
	struct text_stream *syntax_md;
	struct linked_list *locals; /* of |text_stream| */
	int uses_vararg_model;
	int max_arity;
	int formal_arity;
	CLASS_DEFINITION
} vanilla_function;

vanilla_function *VanillaFunctions::new_vf(text_stream *unmangled_name) {
	vanilla_function *fcf = CREATE(vanilla_function);
	fcf->max_arity = 0;
	fcf->formal_arity = -1;
	fcf->uses_vararg_model = FALSE;
	fcf->identifier_as_constant = Str::duplicate(unmangled_name);
	fcf->syntax_md = NULL;
	fcf->locals = NEW_LINKED_LIST(text_stream);
	return fcf;
}

vanilla_function *VanillaFunctions::new_from_definition(code_generation *gen,
	inter_symbol *fn) {
	inter_package *P = Inter::Packages::container(fn->definition);
	inter_package *PP = Inter::Packages::parent(P);
	text_stream *fn_name = Inter::Symbols::name(fn);
	text_stream *md = Metadata::read_optional_textual(PP, I"^phrase_syntax");
	vanilla_function *fcf = VanillaFunctions::new_vf(fn_name);
	fcf->syntax_md = Str::duplicate(md);
	fn->translation_data = STORE_POINTER_vanilla_function(fcf);
	inter_package *code_block = Inter::Constant::code_block(fn);
	inter_tree_node *D = Inter::Packages::definition(code_block);
	VanillaFunctions::seek_locals(gen, D, fcf->locals);
	text_stream *local_name;
	LOOP_OVER_LINKED_LIST(local_name, text_stream, fcf->locals) {
		if (Str::eq(local_name, I"local__vararg_count"))
			fcf->uses_vararg_model = TRUE;
		fcf->max_arity++;
	}
	fcf->formal_arity = 0;
	LOOP_THROUGH_TEXT(pos, fcf->syntax_md)
		if (Str::get(pos) == '(')
			fcf->formal_arity++;			
	return fcf;
}

void VanillaFunctions::seek_locals(code_generation *gen, inter_tree_node *P, linked_list *L) {
	if (P->W.data[ID_IFLD] == LOCAL_IST) {
		inter_package *pack = Inter::Packages::container(P);
		inter_symbol *var_name =
			InterSymbolsTables::local_symbol_from_id(pack, P->W.data[DEFN_LOCAL_IFLD]);
		ADD_TO_LINKED_LIST(Inter::Symbols::name(var_name), text_stream, L);
	}
	LOOP_THROUGH_INTER_CHILDREN(F, P) VanillaFunctions::seek_locals(gen, F, L);
}

void VanillaFunctions::syntax_synopsis(OUTPUT_STREAM, vanilla_function *fcf) {
	text_stream *md = fcf->syntax_md;
	for (int i=3, bracketed = FALSE; i<Str::len(md); i++) {
		wchar_t c = Str::get_at(md, i);
		if (bracketed) {
			if (c == ')') bracketed = FALSE;
		} else if (c == '(') {
			PUT('X');
			bracketed = TRUE;
		} else if (Characters::isalpha(c)) {
			PUT(c);
		} else {
			PUT('_');
		}
	}
}

@ The following calls //Generators::predeclare_function// on every function in
the tree. Not all target languages require functions to be predeclared (Inform 6
does not, for example), so generators can choose simply to ignore this.

=
void VanillaFunctions::predeclare_functions(code_generation *gen) {
	InterTree::traverse(gen->from, VanillaFunctions::predeclare_this, gen, NULL, CONSTANT_IST);
}

@ =
void VanillaFunctions::predeclare_this(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *constant_s =
		InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
	if (Inter::Constant::is_routine(constant_s)) {
		vanilla_function *fcf = VanillaFunctions::new_from_definition(gen, constant_s);
		Generators::predeclare_function(gen, fcf);
	}
}

@ =
void VanillaFunctions::declare_function(code_generation *gen, inter_symbol *con_name) {
	inter_package *code_block = Inter::Constant::code_block(con_name);
	inter_tree_node *D = Inter::Packages::definition(code_block);
	vanilla_function *fcf = RETRIEVE_POINTER_vanilla_function(con_name->translation_data);
	Generators::declare_function(gen, con_name, D, fcf);
}

@ =
void VanillaFunctions::invoke_function(code_generation *gen, inter_symbol *function_s, inter_tree_node *P, int void_context) {
	inter_tree_node *D = function_s->definition;
	if ((D) && (D->W.data[ID_IFLD] == CONSTANT_IST) &&
		(D->W.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT)) {
		inter_ti val1 = D->W.data[DATA_CONST_IFLD];
		inter_ti val2 = D->W.data[DATA_CONST_IFLD + 1];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_symbol *aliased =
				InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(D));
			if (aliased) function_s = aliased;
		}
	}

	vanilla_function *vf = NULL;
	if (GENERAL_POINTER_IS_NULL(function_s->translation_data))
		internal_error("no translation data");
	vf = RETRIEVE_POINTER_vanilla_function(function_s->translation_data);
	if (vf == NULL) internal_error("no translation data");
	Generators::invoke_function(gen, function_s, P, vf, void_context);
}
