[VerifyingInter::] Verifying Inter.

Verifying that a new Inter instruction is correct and consistent.

@ Each time a new instruction is created within //inter//, or loaded in
from a binary Inter file, it is "verified". We use a flag in the preframe for
the instruction to ensure that it is verified only once, for the sake both of
speed and to ensure that certain one-time-only operations are indeed done
one time only.

As this implies, "verification" is not quite the passive business which the
name makes it seem. Verification does indeed perform many sanity checks on
an instruction, but it also cross-references the Inter tree to accommodate
the new instruction. (Because of this, unverified instructions may not work,
and this is why the code to create instructions automatically calls us.)

=
inter_error_message *VerifyingInter::instruction(inter_package *owner, inter_tree_node *P) {
	if (Inode::get_vflag(P) == FALSE) {
		Inode::set_vflag(P);
		inter_construct *IC = NULL;
		inter_error_message *E = InterInstruction::get_construct(P, &IC);
		if (E) return E;
		@<Check the extent of the instruction@>;
		if (IC->symbol_defn_field >= 0) @<Set the symbol definition to this instruction@>;
		@<Apply construct-specific checks@>;
		return E;
	}
	return NULL;
}

@<Check the extent of the instruction@> =
	if ((P->W.extent < IC->min_extent) || (P->W.extent > IC->max_extent)) {
		text_stream *msg = Str::new();
		WRITE_TO(msg, "%S instruction has extent %d words, which is not between %d and %d",
			IC->construct_name, P->W.extent, IC->min_extent, IC->max_extent);
		return Inode::error(P, msg, NULL);
	}
	
@ Some instructions create new symbols, giving them definitions: for example,
if |P| is |constant bakers_dozen = 13| then a new |bakers_dozen| symbol must
be created and given the node |P| as its definition.

We create the symbol when we create the instruction. But the assignment of the
instruction as the definition of the symbol happens only during verification.
This is done because binary Inter files do contain the symbols and the instructions,
but not the assignments of which instruction is the definition of which symbol.
Instead, these assignments are deduced as each instruction is verified.

@<Set the symbol definition to this instruction@> =
	if (P->W.extent < IC->symbol_defn_field) return Inode::error(P, I"extent wrong", NULL);
	inter_symbols_table *T = InterPackage::scope(owner);
	inter_ti SID = P->W.instruction[IC->symbol_defn_field];
	inter_symbol *S = InterSymbolsTable::symbol_from_ID_not_following(T, SID);
	if ((IC->construct_ID == LOCAL_IST) || (IC->construct_ID == LABEL_IST)) {
		if (T == NULL) return Inode::error(P, I"no symbols table in function", NULL);
		@<Make a local definition@>;
	} else {
		if (T == NULL) T = Inode::globals(P);
		@<Make a global definition@>;
	}
	if (E) return E;

@<Make a global definition@> =
	if (S == NULL) {
		E = Inode::error(P, I"no symbol for global definition ID", NULL);
	} else if (Wiring::is_wired(S)) {
		inter_symbol *CE = Wiring::cable_end(S);
		LOG("This is $6 but $3 ~~> $3 in $6\n",
			InterPackage::container(P), S, CE, InterPackage::container(CE->definition));
		E = Inode::error(P, I"symbol defined outside its native scope",
			InterSymbol::identifier(S));
	} else if (InterSymbol::misc_but_undefined(S)) {
		InterSymbol::define(S, P);
	} else /* if (P != InterSymbol::definition(S)) */ {
		E = Inode::error(P, I"duplicated symbol", InterSymbol::identifier(S));
	}

@<Make a local definition@> =
	if (S == NULL) {
		E = Inode::error(P, I"no symbol for local variable ID", NULL);
	} else if (InterSymbol::is_defined(S) == FALSE) {
		InterSymbol::define(S, P);
	} else /* if (P != InterSymbol::definition(S)) */ {
		E = Inode::error(P, I"duplicated local symbol", InterSymbol::identifier(S));
	}

@ Finally we will check, where we can do so speedily, that the bytecode for the
instruction passes various sanity checks. This is partly to catch errors in our
own work (i.e. bugs in the code generating instructions), but also because raw
bytecode read in by //Inter in Binary Files// is not trustworthy. There's less
chance of garbage bytecode crashing the compiler if we take precautions.

All that //InterInstruction::verify// does is to call the |CONSTRUCT_VERIFY_MTID|
method for the construct of the instruction. So, for example, for |PROPERTY_IST|
instructions this is done by //PropertyInstruction::verify//, and so on.

@<Apply construct-specific checks@> =
	E = InterInstruction::verify(owner, IC, P);

@ Although that work is delegated to the implementation of each construct, it's
convenient for those implementations to use the functions below for some common
sorts of check.

Firstly, this tests that a field in a bytecode instruction which purportedly
holds a symbol ID, |SID|, actually does so: and that the symbol if defined
is defined by a given |construct|. It can still be undefined (this allows for,
e.g., the symbol to be wired to a plug for definition in some other compilation
block, or for it not to be defined yet because the rest of the bytecode for
the program has not yet been loaded); but it cannot be the wrong sort of thing.

=
inter_error_message *VerifyingInter::SID_field(inter_package *owner, inter_tree_node *P,
	int field, inter_ti construct) {
	return VerifyingInter::SID(owner, P, P->W.instruction[field], construct);
}

inter_error_message *VerifyingInter::SID(inter_package *owner, inter_tree_node *P,
	inter_ti SID, inter_ti construct) {
	inter_symbols_table *T = InterPackage::scope(owner);
	if (T == NULL) T = Inode::globals(P);
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(T, SID);
	if (S == NULL) return Inode::error(P, I"no symbol for SID (case 3)", NULL);
	inter_tree_node *D = InterSymbol::definition(S);
	if (InterSymbol::defined_elsewhere(S)) return NULL;
	if (InterSymbol::misc_but_undefined(S)) return NULL;
	if (D == NULL) return Inode::error(P, I"undefined symbol", InterSymbol::identifier(S));
	if ((construct != INVALID_IST) &&
		(D->W.instruction[ID_IFLD] != construct) &&
		(InterSymbol::defined_elsewhere(S) == FALSE) &&
		(InterSymbol::misc_but_undefined(S) == FALSE))
		return Inode::error(P, I"symbol of wrong type", InterSymbol::identifier(S));
	return NULL;
}

@ The same, but where the ID refers to a symbol in the tree's global symbols
table (such as a primitive invocation):

=
inter_error_message *VerifyingInter::GSID_field(inter_tree_node *P, int field,
	inter_ti construct) {
	inter_ti GSID = P->W.instruction[field];
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(Inode::globals(P), GSID);
	if (S == NULL) return Inode::error(P, I"no global symbol for GSID", NULL);
	inter_tree_node *D = InterSymbol::definition(S);
	if (InterSymbol::defined_elsewhere(S)) return NULL;
	if (InterSymbol::misc_but_undefined(S)) return NULL;
	if (D == NULL) return Inode::error(P, I"undefined global symbol", InterSymbol::identifier(S));
	if ((D->W.instruction[ID_IFLD] != construct) &&
		(InterSymbol::defined_elsewhere(S) == FALSE) &&
		(InterSymbol::misc_but_undefined(S) == FALSE))
		return Inode::error(P, I"global symbol of wrong type", InterSymbol::identifier(S));
	return NULL;
}

@ This checks an ID for a symbol which has to represent a property owner -- so,
either the typename for an enumerated type, or an instance.

=
inter_error_message *VerifyingInter::POID_field(inter_package *owner, inter_tree_node *P,
	int field) {
	inter_ti POID = P->W.instruction[field];
	inter_symbols_table *T = InterPackage::scope(owner);
	if (T == NULL) T = Inode::globals(P);
	inter_symbol *S = InterSymbolsTable::symbol_from_ID(T, POID);
	if (S == NULL) return Inode::error(P, I"no symbol for property-owner ID", NULL);
	inter_tree_node *D = InterSymbol::definition(S);
	if (InterSymbol::defined_elsewhere(S)) return NULL;
	if (InterSymbol::misc_but_undefined(S)) return NULL;
	if (D == NULL)
		return Inode::error(P, I"undefined property-owner symbol", InterSymbol::identifier(S));
	if ((D->W.instruction[ID_IFLD] != TYPENAME_IST) &&
		(InterSymbol::defined_elsewhere(S) == FALSE) &&
		(D->W.instruction[ID_IFLD] != INSTANCE_IST) &&
		(InterSymbol::misc_but_undefined(S) == FALSE))
			return Inode::error(P, I"property-owner symbol of wrong type",
				InterSymbol::identifier(S));
	return NULL;
}

@ Next, a field which purportedly holds a type constructor such as |INT32_ITCONC|
or |FUNCTION_ITCONC|: see //Inter Data Types//.

=
inter_error_message *VerifyingInter::constructor_field(inter_tree_node *P, int field) {
	inter_ti ID = P->W.instruction[field];
	if (InterTypes::is_valid_constructor_code(ID) == FALSE)
		return Inode::error(P, I"unknown type constructor", NULL);
	return NULL;
}

@ Next, a field which purportedly holds a valid type ID (TID): again, see
//Inter Data Types//.

=
inter_error_message *VerifyingInter::TID_field(inter_package *owner, inter_tree_node *P,
	int field) {
	inter_ti TID = P->W.instruction[field];
	if (TID == 0) return NULL;
	if (InterTypes::is_valid_constructor_code(TID)) return NULL;
	return VerifyingInter::SID(owner, P, TID, TYPENAME_IST);
}

@ Next, a field which purportedly holds a valid text ID:

=
inter_error_message *VerifyingInter::text_field(inter_package *owner, inter_tree_node *P,
	int field) {
	inter_ti text_ID = P->W.instruction[field];
	inter_warehouse *W = InterTree::warehouse(InterPackage::tree(owner));
	if (InterWarehouse::known_type_code(W, text_ID) == TEXT_IRSRC) return NULL;
	return Inode::error(P, I"not a valid text ID", NULL);
}

@ And a node list ID:

=
inter_error_message *VerifyingInter::node_list_field(inter_package *owner, inter_tree_node *P,
	int field) {
	inter_ti text_ID = P->W.instruction[field];
	inter_warehouse *W = InterTree::warehouse(InterPackage::tree(owner));
	if (InterWarehouse::known_type_code(W, text_ID) == NODE_LIST_IRSRC) return NULL;
	return Inode::error(P, I"not a valid node list ID", NULL);
}

@ Finally, two consecutive fields which purportedly hold a valid data pair in
the context of the current package:

=
inter_error_message *VerifyingInter::data_pair_fields(inter_package *owner,
	inter_tree_node *P, int first_field, inter_type type) {
	return InterValuePairs::verify(owner, P, InterValuePairs::get(P, first_field), type);
}
