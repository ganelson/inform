[DetectIndirectCalls::] Detect Indirect Calls.

To make sure certain symbol names translate into globally unique target symbols.

@h Pipeline stage.

=
void DetectIndirectCalls::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"detect-indirect-calls", DetectIndirectCalls::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int DetectIndirectCalls::run_pipeline_stage(pipeline_step *step) {
	InterTree::traverse(step->repository, DetectIndirectCalls::visitor, NULL, NULL, PACKAGE_IST);
	return TRUE;
}

void DetectIndirectCalls::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_package *pack = Inter::Package::defined_by_frame(P);
	if (Inter::Packages::is_codelike(pack)) {
		inter_tree_node *D = Inter::Packages::definition(pack);
		DetectIndirectCalls::traverse_code_tree(D);
	}
}

@ |iden[0]| and |iden[1]| hold left and right identity elements for these binary
operations:

=
void DetectIndirectCalls::traverse_code_tree(inter_tree_node *P) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P) {
		DetectIndirectCalls::traverse_code_tree(F);
	}
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P) {
		if ((F->W.data[ID_IFLD] == INV_IST) &&
			(F->W.data[METHOD_INV_IFLD] == INVOKED_ROUTINE)) {
			inter_symbol *routine = InterSymbolsTables::symbol_from_frame_data(F, INVOKEE_INV_IFLD);
			if (routine == NULL) internal_error("bad routine");
			inter_tree_node *D = routine->definition;
			if ((D) && (D->W.data[ID_IFLD] == VARIABLE_IST)) {
				inter_tree *I = F->tree;
				F->W.data[METHOD_INV_IFLD] = INVOKED_PRIMITIVE;
				int arity = 0;
				PROTECTED_LOOP_THROUGH_INTER_CHILDREN(X, F) arity++;
				inter_ti bip = Primitives::indirect_interp(arity);
				inter_symbol *prim_symb = Primitives::get(I, bip);
				F->W.data[INVOKEE_INV_IFLD] = InterSymbolsTables::id_from_symbol_F(F, NULL, prim_symb);
				WRITE_TO(STDERR, "Yes %S arity %d\n", CodeGen::CL::name(routine), arity);
				inter_bookmark IBM = Inter::Bookmarks::first_child_of_this_node(I, F);
				inter_ti val1 = 0, val2 = 0;
				Inter::Symbols::to_data(Inter::Bookmarks::tree(&IBM), Inter::Bookmarks::package(&IBM), routine, &val1, &val2);
				Inter::Val::new(&IBM, unchecked_kind_symbol, (int) F->W.data[LEVEL_IFLD] + 1, val1, val2, NULL); 
			}
		}
	}
}
