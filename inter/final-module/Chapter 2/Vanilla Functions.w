[VanillaFunctions::] Vanilla Functions.

How the vanilla code generation strategy declares functions.

@ The following traverses the Inter tree to discover all of the functions
defined within it, and does two important things for each:

(a) Assigns it a //vanilla_function// of metadata, and then
(b) Calls //Generators::predeclare_function// to let the generator know that
the function exists. Not all target languages require functions to be predeclared,
so generators can if they choose ignore this.

=
void VanillaFunctions::predeclare_functions(code_generation *gen) {
	InterTree::traverse(gen->from, VanillaFunctions::predeclare_this, gen, NULL, PACKAGE_IST);
}

@ =
void VanillaFunctions::predeclare_this(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *fn_s = PackageInstruction::name_symbol(PackageInstruction::at_this_head(P));
	if (PackageInstruction::is_function(fn_s)) {
		vanilla_function *vf = VanillaFunctions::new(gen, fn_s);
		Generators::predeclare_function(gen, vf);
	}
}

@ Each function has metadata as follows. Note that:

(a) Phrase syntax will only exist for functions which originated in Inform 7
source text; so for functions coming from kits, |phrase_syntax| will be empty
and |formal_arity| will be 0.
(b) For I7 functions, |formal_arity| will be the number of arguments in the
phrase preamble.
(c) For all functions, |max_arity| is the total number of local variables in
the function, and that is by definition the largest number of arguments which
could possibly be passed to this function by a call. Note that it will always
be true that |max_arity >= formal_arity|.
(d) Calling conventions for Inter functions are not entirely simple: see
//C Function Model// for discussion of how they differ from regular C functions.
In particular, any function with a local variable called |_vararg_count| is
called with a variable number of arguments, placed on the stack before the call,
rather than with arguments placed into local variables in the usual way.

=
typedef struct vanilla_function {
	struct text_stream *identifier;
	struct text_stream *phrase_syntax;
	struct linked_list *locals; /* of |text_stream|, the names only */
	struct inter_tree_node *function_body;
	int takes_variable_arguments;
	int max_arity;
	int formal_arity;
	CLASS_DEFINITION
} vanilla_function;

@ This produces a synopsis of the phrase syntax which can be used in an identifier.
For example, for "To award (N - number) points to (P - person)", the following
writes |award_X_points_to_X|:

=
void VanillaFunctions::syntax_synopsis(OUTPUT_STREAM, vanilla_function *vf) {
	text_stream *md = vf->phrase_syntax;
	for (int i=3, bracketed = FALSE; i<Str::len(md); i++) {
		inchar32_t c = Str::get_at(md, i);
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

@ And on the same example, this would return 2:

=
int VanillaFunctions::formal_arity(vanilla_function *vf) {
	int A = 0;
	LOOP_THROUGH_TEXT(pos, vf->phrase_syntax)
		if (Str::get(pos) == '(')
			A++;			
	return A;
}

@ So, then:

=
vanilla_function *VanillaFunctions::new(code_generation *gen, inter_symbol *fn_s) {
	inter_package *P = InterPackage::container(fn_s->definition);
	inter_package *PP = InterPackage::parent(P);
	text_stream *i7_syntax = PP?(Metadata::optional_textual(PP, I"^phrase_syntax")):NULL;
	vanilla_function *vf = CREATE(vanilla_function);
	vf->takes_variable_arguments = FALSE;
	vf->identifier = Str::duplicate(InterSymbol::trans(fn_s));
	vf->locals = NEW_LINKED_LIST(text_stream);
	vf->phrase_syntax = Str::duplicate(i7_syntax);
	inter_package *code_block = PackageInstruction::which(fn_s);
	vf->function_body = InterPackage::head(code_block);
	fn_s->translation_data = STORE_POINTER_vanilla_function(vf);
	VanillaFunctions::seek_locals(gen, vf->function_body, vf);
	vf->max_arity = LinkedLists::len(vf->locals);
	vf->formal_arity = VanillaFunctions::formal_arity(vf);
	if (Str::eq_insensitive(vf->identifier, I"random")) {
		gen->defines_random = TRUE;
		vf->max_arity = 1;
	}
	return vf;
}

@ This performs a local traverse of the body of the function to look for local
variable declarations.

Note that we look at |InterSymbol::identifier(local_s)| not |InterSymbol::trans(local_s)|
when checking for |_vararg_count| because the translated name may have been mangled
in some way by the generator. (As indeed the C generator does, mangling this to
|local__vararg_count|.)

=
void VanillaFunctions::seek_locals(code_generation *gen, inter_tree_node *P,
	vanilla_function *vf) {
	if (Inode::is(P, LOCAL_IST)) {
		inter_symbol *local_s = LocalInstruction::variable(P);
		ADD_TO_LINKED_LIST(InterSymbol::trans(local_s), text_stream, vf->locals);
		if (Str::eq(InterSymbol::identifier(local_s), I"_vararg_count"))
			vf->takes_variable_arguments = TRUE;
	}
	LOOP_THROUGH_INTER_CHILDREN(F, P) VanillaFunctions::seek_locals(gen, F, vf);
}

@ Note that a pointer to |vf| is cached with each function name symbol for speed:

=
void VanillaFunctions::declare_function(code_generation *gen, inter_symbol *fn_s) {
	vanilla_function *vf = RETRIEVE_POINTER_vanilla_function(fn_s->translation_data);
	Generators::declare_function(gen, vf);
}

@ =
void VanillaFunctions::invoke_function(code_generation *gen, inter_symbol *fn_s,
	inter_tree_node *P, int void_context) {
	inter_tree_node *D = fn_s->definition;
	if ((Inode::is(D, CONSTANT_IST)) &&
		(ConstantInstruction::list_format(D) == CONST_LIST_FORMAT_NONE)) {
		inter_pair val = ConstantInstruction::constant(D);
		if (InterValuePairs::is_symbolic(val)) {
			inter_symbol *S = InterValuePairs::to_symbol_at(val, D);
			if (S) fn_s = S;
		}
	}
	vanilla_function *vf = RETRIEVE_POINTER_vanilla_function(fn_s->translation_data);
	if (vf == NULL) internal_error("no translation data");
	Generators::invoke_function(gen, P, vf, void_context);
}
