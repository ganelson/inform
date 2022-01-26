[EliminateRedundantOperationsStage::] Eliminate Redundant Operations Stage.

To remove logical or arithmetic operations which neither do anything, nor
have side-effects.

@ This stage removes redundant operations, replacing each of the following
with just |x|. This is useful mainly for the first of these cases, because
//imperative: Compile Conditions// has a tendency to make redundant |OR_BIP|
operations. The other cases occur much more rarely, but we might as well
handle them too.
= (text)
	x || false
	x && true
	x + 0
	0 + x
	x - 0
	x * 1
	1 * x
	x / 1
=
We could also perform constant-folding here (e.g., replacing |2+3| with |5|),
but we would need to be careful about word size on the VM, and there's not much
gain because the next compiler after us (e.g. Inform 6) will perform its own
constant-folding anyway.

We do not replace |x * 0| with |0|, nor |x && false| with |false|, because then
any intended side-effects of evaluating |x| would be lost.

=
void EliminateRedundantOperationsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"eliminate-redundant-operations",
		EliminateRedundantOperationsStage::run, NO_STAGE_ARG, FALSE);
}

int redundant_operations_removed = 0;
int EliminateRedundantOperationsStage::run(pipeline_step *step) {
	redundant_operations_removed = 0;
	InterTree::traverse(step->ephemera.tree,
		EliminateRedundantOperationsStage::visitor, NULL, NULL, 0);
	if (redundant_operations_removed > 0)
		LOG("%d redundant operation(s) removed\n", redundant_operations_removed);
	return TRUE;
}

void EliminateRedundantOperationsStage::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	if (P->W.data[ID_IFLD] == PACKAGE_IST) {
		inter_package *pack = Inter::Package::defined_by_frame(P);
		if (Inter::Packages::is_codelike(pack)) {
			inter_tree_node *D = Inter::Packages::definition(pack);
			EliminateRedundantOperationsStage::traverse_code_tree(D);
		}
	}
}

@ |iden[0]| and |iden[1]| hold left and right identity elements for these binary
operations:

=
void EliminateRedundantOperationsStage::traverse_code_tree(inter_tree_node *P) {
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P) {
		EliminateRedundantOperationsStage::traverse_code_tree(F);
	}
	PROTECTED_LOOP_THROUGH_INTER_CHILDREN(F, P) {
		int iden[2] = { -1, -1 };
		if ((F->W.data[ID_IFLD] == INV_IST) &&
			(F->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE)) {
			inter_symbol *prim = Inter::Inv::invokee(F);
			if (Primitives::to_BIP(P->tree, prim) == OR_BIP)     { iden[1] = 0; }
			if (Primitives::to_BIP(P->tree, prim) == AND_BIP)    { iden[1] = 1; }
			if (Primitives::to_BIP(P->tree, prim) == PLUS_BIP)   { iden[0] = 0; iden[1] = 0; }
			if (Primitives::to_BIP(P->tree, prim) == MINUS_BIP)  { iden[1] = 0; }
			if (Primitives::to_BIP(P->tree, prim) == TIMES_BIP)  { iden[0] = 1; iden[1] = 1; }
			if (Primitives::to_BIP(P->tree, prim) == DIVIDE_BIP) { iden[1] = 1; }
		}
		if ((iden[0] >= 0) || (iden[1] >= 0)) @<An elimination candidate@>;
	}
}

@<An elimination candidate@> =
	inter_tree_node *operands[2];
	operands[0] = InterTree::first_child(F);
	operands[1] = InterTree::second_child(F);
	if ((operands[0]) && (operands[1])) {
		for (int i = 0; i < 2; i++) {
			if ((iden[i] >= 0) && (operands[i]->W.data[ID_IFLD] == VAL_IST)) {
				inter_ti val1 = operands[i]->W.data[VAL1_VAL_IFLD];
				inter_ti val2 = operands[i]->W.data[VAL2_VAL_IFLD];
				if ((val1 == LITERAL_IVAL) && (val2 == (inter_ti) iden[i])) {
					redundant_operations_removed++;
					NodePlacement::remove(operands[i]);
					NodePlacement::move_to(operands[1-i], InterBookmark::immediately_after(F));
					NodePlacement::remove(F);
					break;
				}
			}
		}
	}
