[CConditions::] C Conditions.

Evaluating conditions.

@ This section implements the primitives which evaluate conditions. |!propertyvalue|
might seem a surprising inclusion in the list: as the name suggests, this finds
a property value. But although it is often used in a value context, it's also used
as a condition. For example, if kit code (written in Inform 6 notation) does this:
= (text as Inform 6)
	if (obj has concealed) ...
=
then the condition amounts to an |inv !propertyvalue|. Now, since any value can
be used as a condition, this may still not seem to mean that |!propertyvalue|
belongs here; but consider that it is also legal to write --
= (text as Inform 6)
	if (obj has concealed or scenery) ...
=
Here the |inv !propertyvalue| involves an |inv !alternative| in its children,
and handling that requires the mechanism below.

=
int CConditions::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case NOT_BIP:
			WRITE("(!("); VNODE_1C; WRITE("))"); break;
		case AND_BIP:
			WRITE("(("); VNODE_1C; WRITE(") && ("); VNODE_2C; WRITE("))"); break;
		case OR_BIP:
			WRITE("(("); VNODE_1C; WRITE(") || ("); VNODE_2C; WRITE("))"); break;
		case PROPERTYEXISTS_BIP:
			C_GEN_DATA(objdata.value_ranges_needed) = TRUE;
			C_GEN_DATA(objdata.value_property_holders_needed) = TRUE;
			WRITE("(i7_provides_gprop(proc, "); VNODE_1C; WRITE(", ");
			VNODE_2C; WRITE(", "); VNODE_3C; WRITE("))");
			break;
		case EQ_BIP: case NE_BIP: case GT_BIP: case GE_BIP: case LT_BIP: case LE_BIP:
		case OFCLASS_BIP: case IN_BIP: case NOTIN_BIP:
			CConditions::comparison_r(gen, bip, NULL,
				InterTree::first_child(P), InterTree::second_child(P), 0);
			break;
		case PROPERTYVALUE_BIP:
			CConditions::comparison_r(gen, bip, InterTree::first_child(P),
				InterTree::second_child(P), InterTree::third_child(P), 0);
			break;
		case ALTERNATIVE_BIP:
			internal_error("misplaced !alternative in Inter tree"); break;
		default: return NOT_APPLICABLE;
	}
	return FALSE;
}

@ The following recursive mechanism exists because of the need to support
alternative choices in Inter conditions, as here:
= (text as Inter)
	inv !if
	    inv !eq
	    	val K_number x
	    	inv !alternative
	    	    val K_number 4
	    	    val K_number 8
        ...
=
This is the equivalent of writing |if (x == 4 or 8) ...| in Inform 6, but C does
not have an |or| operator like that. We could with care sometimes compile this
as |if ((x == 4) || (x == 8))|, but if evaluating |x| has side-effects, or is
slow, this will cause problems. Instead we compile |if (t = x, ((t == 4) || (t == 8)))|
where |t| is temporary storage.

Note that |!ne| and |!notin| interpret |!alternative| in a de Morgan-like way,
so that we compile |if ((x != 4) && (x != 8))| rather than |if ((x != 4) || (x != 8))|.
The former is equivalent to negating |!eq| on the same choices, which is what we want; 
the latter would be universally true, which is useless.

=
void CConditions::comparison_r(code_generation *gen,
	inter_ti bip, inter_tree_node *K, inter_tree_node *X, inter_tree_node *Y, int depth) {
	if (Y->W.instruction[ID_IFLD] == INV_IST) {
		if (InvInstruction::method(Y) == PRIMITIVE_INVMETH) {
			inter_symbol *prim = InvInstruction::primitive(Y);
			inter_ti ybip = Primitives::to_BIP(gen->from, prim);
			if (ybip == ALTERNATIVE_BIP) {
				text_stream *OUT = CodeGen::current(gen);
				if (depth == 0) {
					WRITE("(proc->state.tmp[0] = "); Vanilla::node(gen, X); WRITE(", (");
				}
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
	text_stream *test_fn = NULL, *test_operator = NULL;
	switch (bip) {
		case OFCLASS_BIP:	     positive = TRUE;  test_fn = I"i7_ofclass"; break;
		case IN_BIP:		     positive = TRUE;  test_fn = I"i7_in"; break;
		case NOTIN_BIP:		     positive = FALSE; test_fn = I"i7_in"; break;
		case EQ_BIP:             test_operator = I"=="; break;
		case NE_BIP:             test_operator = I"!="; break;
		case GT_BIP:             test_operator = I">";  break;
		case GE_BIP:             test_operator = I">="; break;
		case LT_BIP:             test_operator = I"<";  break;
		case LE_BIP:             test_operator = I"<="; break;
		case PROPERTYVALUE_BIP:  break;
		default:                 internal_error("unsupported condition"); break;
	}

	if (bip == PROPERTYVALUE_BIP) {
		WRITE("(i7_read_gprop_value(proc, ", test_fn);
		Vanilla::node(gen, K); WRITE(", ");
		@<Compile first comparand@>;
		WRITE(", ");
		@<Compile second comparand@>;
		WRITE("))");
	} else if (Str::len(test_fn) > 0) {
		WRITE("(%S(proc, ", test_fn);
		@<Compile first comparand@>;
		WRITE(", ");
		@<Compile second comparand@>;
		WRITE(")");
		if (positive == FALSE) WRITE(" == 0");
		WRITE(")");
	} else {
		WRITE("("); @<Compile first comparand@>;
		WRITE(" %S ", test_operator);
		@<Compile second comparand@>; WRITE(")");
	}
}

@<Compile first comparand@> =
	if (X) Vanilla::node(gen, X); else WRITE("proc->state.tmp[0]");

@<Compile second comparand@> =
	Vanilla::node(gen, Y);
