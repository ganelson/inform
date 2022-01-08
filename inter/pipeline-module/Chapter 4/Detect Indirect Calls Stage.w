[DetectIndirectCallsStage::] Detect Indirect Calls Stage.

To handle function calls made to functions identified by symbols which turn
out, during linking, to be variables rather than constants.

@ Suppose kit A makes the function call |Mystery(1, 2, 3)|, where |Mystery| is a
function defined in kit B; and suppose further that |Mystery| is not the name of
a function, but the name of a variable in kit B, whose value at runtime will be
the address of the function which must be called. The original call in Kit A
will be a function invocation like so:
= (text as Inter)
	inv Mystery
		val K_number 1
		val K_number 2
		val K_number 3
=
But this is incorrect, because only explicitly identified functions can be
invoked like this, and |Mystery| turns out to be a variable. (The compiler
of kit A has no way to know this.) We must correct to:
= (text as Inter)
	inv !indirect3v
		val K_unchecked Mystery
		val K_number 1
		val K_number 2
		val K_number 3
=
This looks like an edge case, and it would certainly be possible to rewrite the
kits so that it doesn't arise. But rejecting such usages with an error message
would be as slow as correcting them, so we might as well get them right.

=
void DetectIndirectCallsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"detect-indirect-calls",
		DetectIndirectCallsStage::run, NO_STAGE_ARG, FALSE);
}

int DetectIndirectCallsStage::run(pipeline_step *step) {
	InterTree::traverse(step->ephemera.tree,
		DetectIndirectCallsStage::visitor, step, NULL, PACKAGE_IST);
	return TRUE;
}

void DetectIndirectCallsStage::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	pipeline_step *step = (pipeline_step *) state;
	inter_package *pack = Inter::Package::defined_by_frame(P);
	if (Inter::Packages::is_codelike(pack)) {
		inter_tree_node *D = Inter::Packages::definition(pack);
		DetectIndirectCallsStage::traverse_code_tree(D, step);
	}
}

@ Within each code package (i.e., function body), we make a depth-first traverse,
though as it happens this transformation would work just as well either way:

=
void DetectIndirectCallsStage::traverse_code_tree(inter_tree_node *P, pipeline_step *step) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P)
		DetectIndirectCallsStage::traverse_code_tree(F, step);
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P)
		if ((F->W.data[ID_IFLD] == INV_IST) &&
			(F->W.data[METHOD_INV_IFLD] == INVOKED_ROUTINE)) {
			inter_symbol *var =
				InterSymbolsTables::symbol_from_frame_data(F, INVOKEE_INV_IFLD);
			if (var == NULL) internal_error("bad invocation");
			inter_tree_node *D = var->definition;
			if ((D) && (D->W.data[ID_IFLD] == VARIABLE_IST))
				@<This is an invocation of a variable not a function@>;
		}
}

@<This is an invocation of a variable not a function@> =
	inter_tree *I = F->tree;
	@<Change to be an invocation of a primitive@>;
	@<Insert the variable as the new first argument@>;

@<Change to be an invocation of a primitive@> =
	F->W.data[METHOD_INV_IFLD] = INVOKED_PRIMITIVE;
	int arity = 0;
	LOOP_THROUGH_INTER_CHILDREN(X, F) arity++;
	inter_ti prim = Primitives::indirect_interp(arity);
	inter_symbol *prim_s = Primitives::get(I, prim);
	F->W.data[INVOKEE_INV_IFLD] =
		InterSymbolsTables::id_from_symbol_F(F, NULL, prim_s);

@<Insert the variable as the new first argument@> =
	inter_bookmark IBM = Inter::Bookmarks::first_child_of_this_node(I, F);
	inter_ti val1 = 0, val2 = 0;
	Inter::Symbols::to_data(Inter::Bookmarks::tree(&IBM),
		Inter::Bookmarks::package(&IBM), var, &val1, &val2);
	Inter::Val::new(&IBM,
		RunningPipelines::get_symbol(step, unchecked_kind_RPSYM),
		(int) F->W.data[LEVEL_IFLD] + 1, val1, val2, NULL); 
