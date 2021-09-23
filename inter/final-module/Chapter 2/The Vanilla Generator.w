[Vanilla::] The Vanilla Generator.

The plain-vanilla code generation strategy, provided for the use of generators
to imperative languages such as Inform 6 or C.

@ The rest of this chapter is a plain-vanilla algorithm for turning Inter trees
to imperative code, making method calls to the generator to handle each individual
step as needed.

The following function is everything except that the generator has already been
sent the |BEGIN_GENERATION_MTID| method, and that the generator will subsequently
be sent |END_GENERATION_MTID|.

=
void Vanilla::go(code_generation *gen) {
	@<Prepare@>;
	@<Traverse for pragmas@>;
	@<Traverse to make function predeclarations@>;
	@<General traverse@>;
	@<Consolidate@>;
}

@<Prepare@> =
	gen->void_level = -1;
	VanillaConstants::prepare(gen);
	VanillaVariables::prepare(gen);
	VanillaObjects::prepare(gen);

@<Traverse for pragmas@> =
	InterTree::traverse_root_only(gen->from, Vanilla::pragma, gen, PRAGMA_IST);

@ =
void Vanilla::pragma(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *target_symbol = InterSymbolsTables::symbol_from_frame_data(P, TARGET_PRAGMA_IFLD);
	if (target_symbol == NULL) internal_error("bad pragma");
	inter_ti ID = P->W.data[TEXT_PRAGMA_IFLD];
	text_stream *S = Inode::ID_to_text(P, ID);
	Generators::offer_pragma(gen, P, target_symbol->symbol_name, S);
}

@<Traverse to make function predeclarations@> =
	InterTree::traverse(gen->from, Vanilla::predeclare_functions, gen, NULL, -PACKAGE_IST);

@ Of course, not all target languages will need predeclared functions: Inform 6
does not, for example. Such generators can just not provide |PREDECLARE_FUNCTION_MTID|,
and then this will do nothing.

=
void Vanilla::predeclare_functions(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_package *outer = Inter::Packages::container(P);
	if ((outer == NULL) || (Inter::Packages::is_codelike(outer) == FALSE)) {
		generated_segment *saved =
			CodeGen::select(gen, Generators::general_segment(gen, P));
		switch (P->W.data[ID_IFLD]) {
			case CONSTANT_IST: {
				inter_symbol *con_name =
					InterSymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
				if (Inter::Constant::is_routine(con_name)) {
					inter_package *code_block = Inter::Constant::code_block(con_name);
					inter_tree_node *D = Inter::Packages::definition(code_block);
					Generators::predeclare_function(gen, con_name, D);
					return;
				}
				break;
			}
		}
		CodeGen::deselect(gen, saved);
	}
}

@<General traverse@> =
	InterTree::traverse(gen->from, Vanilla::iterate, gen, NULL, -PACKAGE_IST);

@ This looks for the top level of packages which are not the code-body of
functions, and calls //Vanilla::node// to recurse downwards through them.

=
void Vanilla::iterate(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_package *outer = Inter::Packages::container(P);
	if ((outer == NULL) || (Inter::Packages::is_codelike(outer) == FALSE)) {
		generated_segment *saved = CodeGen::select(gen, Generators::general_segment(gen, P));
		switch (P->W.data[ID_IFLD]) {
			case CONSTANT_IST:
			case INSTANCE_IST:
			case PROPERTYVALUE_IST:
			case VARIABLE_IST:
			case SPLAT_IST:
				Vanilla::node(gen, P);
				break;
		}
		CodeGen::deselect(gen, saved);
	}
}

@<Consolidate@> =
	VanillaVariables::consolidate(gen);
	VanillaConstants::consolidate(gen);
	VanillaObjects::consolidate(gen);

@ The function //Vanilla::node// is a sort of handle-any-node function, and is
the main way we iterate through the Inter tree.

Note that the general-traverse iteration above calls into this function, but
that the function then recurses down through nodes. As a result, it sees pretty
well the entire tree by the end.

The current node is always called |P|, for reasons now forgotten.

It is so often used recursively that the following abbreviation macros are helpful:

@d VNODE_1C    Vanilla::node(gen, InterTree::first_child(P))
@d VNODE_2C    Vanilla::node(gen, InterTree::second_child(P))
@d VNODE_3C    Vanilla::node(gen, InterTree::third_child(P))
@d VNODE_4C    Vanilla::node(gen, InterTree::fourth_child(P))
@d VNODE_5C    Vanilla::node(gen, InterTree::fifth_child(P))
@d VNODE_6C    Vanilla::node(gen, InterTree::sixth_child(P))
@d VNODE_ALLC  LOOP_THROUGH_INTER_CHILDREN(C, P) Vanilla::node(gen, C)

=
void Vanilla::node(code_generation *gen, inter_tree_node *P) {
	switch (P->W.data[ID_IFLD]) {
		case CONSTANT_IST:      VanillaConstants::constant(gen, P); break;
		case VARIABLE_IST:      VanillaVariables::variable(gen, P); break;
		case INSTANCE_IST:      VanillaObjects::instance(gen, P); break;
		case SPLAT_IST:         VanillaCode::splat(gen, P); break;
		case LABEL_IST:         VanillaCode::label(gen, P); break;
		case CODE_IST:          VanillaCode::code(gen, P); break;
		case EVALUATION_IST:    VanillaCode::evaluation(gen, P); break;
		case REFERENCE_IST:     VanillaCode::reference(gen, P); break;
		case PACKAGE_IST:       VanillaCode::block(gen, P); break;
		case INV_IST:           VanillaCode::inv(gen, P); break;
		case CAST_IST:          VanillaCode::cast(gen, P); break;
		case VAL_IST:           VanillaCode::val_or_ref(gen, P, FALSE); break;
		case REF_IST:           VanillaCode::val_or_ref(gen, P, TRUE); break;
		case LAB_IST:           VanillaCode::lab(gen, P); break;
		case PROPERTYVALUE_IST: VanillaObjects::propertyvalue(gen, P); break;

		case SYMBOL_IST:        break;
		case LOCAL_IST:         break;
		case NOP_IST:           break;
		case COMMENT_IST:       break;

		default:
			Inter::Defn::write_construct_text(DL, P);
			internal_error("unexpected node type in Inter tree");
	}
}
