[CConditions::] C Conditions.

Evaluating conditions.

@

=
int CConditions::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case NOT_BIP:			WRITE("(!("); VNODE_1C; WRITE("))"); break;
		case AND_BIP:			WRITE("(("); VNODE_1C; WRITE(") && ("); VNODE_2C; WRITE("))"); break;
		case OR_BIP: 			WRITE("(("); VNODE_1C; WRITE(") || ("); VNODE_2C; WRITE("))"); break;
		case PROPERTYEXISTS_BIP:
			C_GEN_DATA(objdata.value_ranges_needed) = TRUE;
			C_GEN_DATA(objdata.value_property_holders_needed) = TRUE;
			WRITE("(i7_provides_gprop(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(", "); VNODE_3C; WRITE(", i7_mgl_OBJECT_TY, i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_A_door_to, i7_mgl_COL_HSIZE))"); break;
		case EQ_BIP: 			@<Generate comparison@>; break;
		case NE_BIP: 			@<Generate comparison@>; break;
		case GT_BIP: 			@<Generate comparison@>; break;
		case GE_BIP: 			@<Generate comparison@>; break;
		case LT_BIP: 			@<Generate comparison@>; break;
		case LE_BIP: 			@<Generate comparison@>; break;
		case OFCLASS_BIP:		@<Generate comparison@>; break;
		case IN_BIP:			@<Generate comparison@>; break;
		case NOTIN_BIP:			@<Generate comparison@>; break;
		case ALTERNATIVE_BIP:	internal_error("loose ALTERNATIVE_BIP primitive node"); break;
		default: 				return NOT_APPLICABLE;
	}
	return FALSE;
}

@<Generate comparison@> =
	CConditions::comparison_r(gen, bip, NULL, InterTree::first_child(P), InterTree::second_child(P), 0);

@ =
void CConditions::comparison_r(code_generation *gen,
	inter_ti bip, inter_tree_node *K, inter_tree_node *X, inter_tree_node *Y, int depth) {
	if (Y->W.data[ID_IFLD] == INV_IST) {
		if (Y->W.data[METHOD_INV_IFLD] == INVOKED_PRIMITIVE) {
			inter_symbol *prim = Inter::Inv::invokee(Y);
			inter_ti ybip = Primitives::to_bip(gen->from, prim);
			if (ybip == ALTERNATIVE_BIP) {
				text_stream *OUT = CodeGen::current(gen);
				if (depth == 0) { WRITE("(proc->state.tmp[0] = "); Vanilla::node(gen, X); WRITE(", ("); }
				CConditions::comparison_r(gen, bip, K, NULL, InterTree::first_child(Y), depth+1);
				if ((bip == NE_BIP) || (bip == NOTIN_BIP)) WRITE(" && ");
				else WRITE(" || ");
				CConditions::comparison_r(gen, bip, K, NULL, InterTree::second_child(Y), depth+1);
				if (depth == 0) { WRITE("))"); }
				return;
			}
		}
	}
	text_stream *OUT = CodeGen::current(gen);
	int positive = TRUE;
	text_stream *test_fn = CObjectModel::test_with_function(bip, &positive);
	if (Str::len(test_fn) > 0) {
		WRITE("(%S(proc, ", test_fn);
		if (bip == PROPERTYVALUE_BIP) {
			Vanilla::node(gen, K);
			WRITE(", ");
		}
		@<Compile first compared@>;
		WRITE(", ");
		@<Compile second compared@>;
		if (bip == PROPERTYVALUE_BIP) {
			WRITE(", i7_mgl_OBJECT_TY, i7_mgl_value_ranges, i7_mgl_value_property_holders, i7_mgl_A_door_to, i7_mgl_COL_HSIZE");
		}
		WRITE(")");
		if (positive == FALSE) WRITE(" == 0");
		WRITE(")");
	} else {
		WRITE("("); @<Compile first compared@>;
		switch (bip) {
			case EQ_BIP: WRITE(" == "); break;
			case NE_BIP: WRITE(" != "); break;
			case GT_BIP: WRITE(" > ");  break;
			case GE_BIP: WRITE(" >= "); break;
			case LT_BIP: WRITE(" < ");  break;
			case LE_BIP: WRITE(" <= "); break;
		}
		@<Compile second compared@>; WRITE(")");
	}
}

@<Compile first compared@> =
	if (X) Vanilla::node(gen, X); else WRITE("proc->state.tmp[0]");

@<Compile second compared@> =
	Vanilla::node(gen, Y);
