[CompileLvalues::] Compile Lvalues.

To compile storage references into Inter value opcodes.

@ The following compiles an lvalue -- a piece of stored data: see //values: Lvalues// --
but in one of three different ways:

|COMPILE_LVALUE_AS_RVALUE| is a mode used when the storage is being compiled in
an rvalue context, i.e., having its value read but not being altered.

|COMPILE_LVALUE_AS_LVALUE| is a mode used only when the lvalue really is being
compiled as the recipient of an assignment, rather than being read. Thus:
= (text as Inform 7)
	let R be a number;
	now R is 76;
	showme R plus 1;
=
In line 2 here, |R| must be compiled in |COMPILE_LVALUE_AS_LVALUE| mode; in line 3,
it must not be.

|COMPILE_LVALUE_AS_FUNCTION| is a way to access the Inter function managing the
storage at runtime. (This can be accessed from a schema.)

@d COMPILE_LVALUE_AS_RVALUE   0
@d COMPILE_LVALUE_AS_LVALUE   1
@d COMPILE_LVALUE_AS_FUNCTION 2

=
void CompileLvalues::in_rvalue_context(value_holster *VH, parse_node *spec_found) {
	CompileLvalues::compile_in_mode(VH, spec_found, COMPILE_LVALUE_AS_RVALUE);
}

void CompileLvalues::compile_in_mode(value_holster *VH, parse_node *spec_found, int storage_mode) {
	switch (Node::get_type(spec_found)) {
		case LOCAL_VARIABLE_NT: @<Compile a local variable specification@>;
		case NONLOCAL_VARIABLE_NT: @<Compile a non-local variable specification@>;
		case PROPERTY_VALUE_NT: @<Compile a property value specification@>;
		case LIST_ENTRY_NT: @<Compile a list entry specification@>;
		case TABLE_ENTRY_NT: @<Compile a table entry specification@>;
		default: LOG("Offender: $P\n", spec_found);
			internal_error("unable to compile this lvalue");
	}
}

@<Compile a local variable specification@> =
	local_variable *lvar = Node::get_constant_local_variable(spec_found);
	inter_symbol *lvar_s = LocalVariables::declare(lvar);
	if (lvar == NULL) {
		internal_error("Compiled never-specified LOCAL VARIABLE SP");
	}
	EmitCode::val_symbol(K_value, lvar_s);
	return;

@<Compile a non-local variable specification@> =
	nonlocal_variable *nlv = Node::get_constant_nonlocal_variable(spec_found);
	RTVariables::compile_NVE_as_val(nlv, &(nlv->compilation_data.lvalue_nve));
	return;

@<Compile a property value specification@> =
	if (Node::no_children(spec_found) != 2) internal_error("malformed PROPERTY_OF SP");
	if (spec_found->down == NULL) internal_error("PROPERTY_OF with null arg 0");
	if (spec_found->down->next == NULL) internal_error("PROPERTY_OF with null arg 1");
	property *prn = Rvalues::to_property(spec_found->down);
	if (prn == NULL) internal_error("PROPERTY_OF with null property");
	parse_node *prop_spec = spec_found->down;
	parse_node *owner = spec_found->down->next;
	kind *owner_kind = Specifications::to_kind(owner);

	@<Reinterpret the "self" for what are unambiguously conditions of single things@>;

	if (storage_mode == 2) {
		EmitCode::val_iname(K_value, Hierarchy::find(GPROPERTY_HL));
	} else {
		if (storage_mode != 1) {
			EmitCode::call(Hierarchy::find(GPROPERTY_HL));
			EmitCode::down();
		}
		RTKindIDs::emit_weak_ID_as_val(owner_kind);
		@<Emit the property's owner@>;
		CompileValues::to_code_val(prop_spec);
		if (storage_mode != 1) {
			EmitCode::up();
		}
	}
	return;

@ When Inform reads a text with a substitution like so:

>> if the signpost is visible, say "The signpost is still [signpost condition]."

...it has to decide which object is meant as the owner of the property
"signpost condition". Ordinarily, missing property owners are the self object,
which works nicely because |self| always has the right value at run-time when
we're, e.g., printing names of things. But what if, as here, there is no
formal indication of the owner? If we compile with the self object as owner,
the code may fail at run-time, complaining about using a property of nothing.

The author who wrote the source text above, though, felt able to write
"[signpost condition]" without any indication of its owner because there
could only be one possible owner: the signpost. And so that's the convention
we use here. We replace "self" as a default owner by the only possible owner.

@<Reinterpret the "self" for what are unambiguously conditions of single things@> =
	if (Rvalues::is_self_object_constant(owner)) {
		inference_subject *infs = ConditionsOfSubjects::of_what(prn);
		instance *I = InstanceSubjects::to_object_instance(infs);
		if (I) owner = Rvalues::from_instance(I);
	}

@ During type-checking, a small number of |PROPERTY_VALUE_NT| SPs are marked
with the |record_as_self_ANNOT| flag. Such a SP compiles not only to code
performing the property lookup, but also setting the |self| I6 variable at
run-time to the object whose property is being looked up. The point of this
is to change the context used for implicit property lookups involved in the
actual property: e.g., if the value of this property turns out to be text
which contains a substitution referring vaguely to another property, then
we need to make sure that this other property is looked up from the same
object as produced the original text containing the substitution.

@<Emit the property's owner@> =
	if (Annotations::read_int(spec_found, record_as_self_ANNOT)) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_iname(K_value, Hierarchy::find(SELF_HL));
			CompileValues::to_code_val(owner);
		EmitCode::up();
	} else {
		CompileValues::to_code_val(owner);
	}

@ List entries are blessedly simpler.

@<Compile a list entry specification@> =
	if (Node::no_children(spec_found) != 2) internal_error("malformed LIST_OF SP");
	if (spec_found->down == NULL) internal_error("LIST_OF with null arg 0");
	if (spec_found->down->next == NULL) internal_error("LIST_OF with null arg 1");

	if (storage_mode == 2) {
		EmitCode::val_iname(K_value, Hierarchy::find(LIST_OF_TY_GETITEM_HL));
	} else {
		if (storage_mode != 1) {
			EmitCode::call(Hierarchy::find(LIST_OF_TY_GETITEM_HL));
			EmitCode::down();
		}
		CompileValues::to_code_val(spec_found->down);
		CompileValues::to_code_val(spec_found->down->next);
		if (storage_mode != 1) {
			EmitCode::up();
		}
	}
	return;

@<Compile a table entry specification@> =
	CompileLvalues::compile_table_reference(VH, spec_found, FALSE, FALSE, storage_mode);
	return;

@ Table entries are simple too, but come in four variant forms:

=
void CompileLvalues::compile_table_reference(value_holster *VH, parse_node *spec_found,
	int exists, int blank_out, int storage_mode) {
	inter_name *lookup = Hierarchy::find(TABLELOOKUPENTRY_HL);
	inter_name *lookup_corr = Hierarchy::find(TABLELOOKUPCORR_HL);
	if (exists) {
		lookup = Hierarchy::find(EXISTSTABLELOOKUPENTRY_HL);
		lookup_corr = Hierarchy::find(EXISTSTABLELOOKUPCORR_HL);
	}

	switch(Node::no_children(spec_found)) {
		case 1:
			if (storage_mode == 2) {
				EmitCode::val_iname(K_value, lookup);
			} else {
				LocalVariables::used_ct_locals();
				LocalVariables::add_table_lookup();
				if (storage_mode != 1) {
					EmitCode::call(lookup);
					EmitCode::down();
				}
				local_variable *ct_0_lv = LocalVariables::find_internal(I"ct_0");
				inter_symbol *ct_0_s = LocalVariables::declare(ct_0_lv);
				local_variable *ct_1_lv = LocalVariables::find_internal(I"ct_1");
				inter_symbol *ct_1_s = LocalVariables::declare(ct_1_lv);
				EmitCode::val_symbol(K_value, ct_0_s);
				CompileValues::to_code_val(spec_found->down);
				EmitCode::val_symbol(K_value, ct_1_s);
				if (blank_out) {
					EmitCode::val_number(4);
				}
				if (storage_mode != 1) {
					EmitCode::up();
				}
			}
			break;
		case 2: /* never here except when printing debugging code */
			EmitCode::val_false();
			break;
		case 3:
			if (storage_mode == 2) {
				EmitCode::val_iname(K_value, lookup);
			} else {
				if (storage_mode != 1) {
					EmitCode::call(lookup);
					EmitCode::down();
				}
				CompileValues::to_code_val(spec_found->down->next->next);
				CompileValues::to_code_val(spec_found->down);
				CompileValues::to_code_val(spec_found->down->next);
				if (blank_out) {
					EmitCode::val_number(4);
				}
				if (storage_mode != 1) {
					EmitCode::up();
				}
			}
			break;
		case 4:	
			if (storage_mode == 2) {
				EmitCode::val_iname(K_value, lookup_corr);
			} else {
				if (storage_mode != 1) {
					EmitCode::call(lookup_corr);
					EmitCode::down();
				}
				CompileValues::to_code_val(spec_found->down->next->next->next);
				CompileValues::to_code_val(spec_found->down);
				CompileValues::to_code_val(spec_found->down->next);
				CompileValues::to_code_val(spec_found->down->next->next);
				if (blank_out) {
					EmitCode::val_number(4);
				}
				if (storage_mode != 1) {
					EmitCode::up();
				}
			}
			break;
		default: internal_error("TABLE REFERENCE with bad number of args");
	}
}

@h Schemas.
The following function returns the text of an I6 schema for the code to set
an lvalue with node type |storage_class|, and kind |left|, to a value of
kind |right|. |inc| is positive if we're incrementing what's there, negative
if decrementing, zero if simply setting.

At present no arithmetic values are stored in pointer values, but that might
change if arbitrary-precision integers are ever added to Inform, for instance.

=
@ Here we supply advice on whether shallow or deep copies are needed.

=
char *CompileLvalues::interpret_store(node_type_t storage_class, kind *left, kind *right, int inc) {
	LOGIF(KIND_CHECKING, "Interpreting assignment of kinds %u, %u\n", left, right);
	kind_constructor *L = NULL, *R = NULL;
	if ((left) && (right)) { L = left->construct; R = right->construct; }
	int form = STORE_WORD_TO_WORD;
	if (inc > 0) {
		form = INCREASE_BY_WORD;
		if (Kinds::FloatingPoint::uses_floating_point(left)) form = INCREASE_BY_REAL;
	}
	if (inc < 0) {
		form = DECREASE_BY_WORD;
		if (Kinds::FloatingPoint::uses_floating_point(left)) form = DECREASE_BY_REAL;
	}
	if (KindConstructors::uses_block_values(L)) {
		if (KindConstructors::allow_word_as_pointer(L, R)) {
			form = STORE_WORD_TO_POINTER;
			if (inc > 0) form = INCREASE_BY_POINTER;
			if (inc < 0) form = DECREASE_BY_POINTER;
		} else {
			form = STORE_POINTER_TO_POINTER;
			if (inc > 0) form = INCREASE_BY_POINTER;
			if (inc < 0) form = DECREASE_BY_POINTER;
		}
	}
	int reduce = FALSE;
	#ifdef IF_MODULE
	kind *KT = TimesOfDay::kind();
	if ((KT) && (Kinds::eq(left, KT))) reduce = TRUE;
	#endif
	return CompileLvalues::storage_schema(storage_class, form, reduce);
}

@ Which uses:

@d STORE_WORD_TO_WORD 1
@d STORE_WORD_TO_POINTER 2
@d STORE_POINTER_TO_POINTER 3
@d INCREASE_BY_WORD 4
@d INCREASE_BY_REAL 5
@d INCREASE_BY_POINTER 6
@d DECREASE_BY_WORD 7
@d DECREASE_BY_REAL 8
@d DECREASE_BY_POINTER 9

=
char *CompileLvalues::storage_schema(node_type_t storage_class, int kind_of_store,
	int reducing_modulo_1440) {
	switch(kind_of_store) {
		case STORE_WORD_TO_WORD:
			switch(storage_class) {
				case LOCAL_VARIABLE_NT: return "*=-*1 = *<2";
				case NONLOCAL_VARIABLE_NT: return "*=-*1 = *<2";
				case TABLE_ENTRY_NT: return "*=-*$1(*%1,1,*<2)";
				case PROPERTY_VALUE_NT: return "*=-WriteGProperty(*|1,*<2)";
				case LIST_ENTRY_NT: return "*=-WriteLIST_OF_TY_GetItem(*%1,*<2)";
			}
			return "";
		case STORE_WORD_TO_POINTER:
			switch(storage_class) {
				case LOCAL_VARIABLE_NT: return "*=-BlkValueCast(*1, *#2, *2)";
				case NONLOCAL_VARIABLE_NT: return "*=-BlkValueCast(*1, *#2, *2)";
				case TABLE_ENTRY_NT: return "*=-BlkValueCast(*$1(*%1, 5), *#2, *2)";
				case PROPERTY_VALUE_NT: return "*=-BlkValueCast(*+1, *#2, *2)";
				case LIST_ENTRY_NT: return "*=-BlkValueCast(*1, *#2, *2)";
			}
			return "";
		case STORE_POINTER_TO_POINTER:
			switch(storage_class) {
				case LOCAL_VARIABLE_NT: return "*=-BlkValueCopy(*1, *<2)";
				case NONLOCAL_VARIABLE_NT: return "*=-BlkValueCopy(*1, *<2)";
				case TABLE_ENTRY_NT: return "*=-BlkValueCopy(*$1(*%1, 5), *<2)";
				case PROPERTY_VALUE_NT: return "*=-BlkValueCopy(*+1, *<2)";
				case LIST_ENTRY_NT: return "*=-BlkValueCopy(*1, *<2)";
			}
			return "";
		case INCREASE_BY_WORD:
			if (reducing_modulo_1440) {
				switch(storage_class) {
					case LOCAL_VARIABLE_NT: return "*=-*1 = NUMBER_TY_to_TIME_TY(*1 + *<2)";
					case NONLOCAL_VARIABLE_NT: return "*=-*1 = NUMBER_TY_to_TIME_TY(*1 + *<2)";
					case TABLE_ENTRY_NT: return "*=-*$1(*%1,1,NUMBER_TY_to_TIME_TY(*1 + *<2))";
					case PROPERTY_VALUE_NT: return "*=-WriteGProperty(*|1,NUMBER_TY_to_TIME_TY(*+1 + *<2))";
					case LIST_ENTRY_NT: return "*=-WriteLIST_OF_TY_GetItem(*%1,NUMBER_TY_to_TIME_TY(*1 + *<2))";
				}
			} else {
				switch(storage_class) {
					case LOCAL_VARIABLE_NT: return "*=-*1 = *1 + *<2";
					case NONLOCAL_VARIABLE_NT: return "*=-*1 = *1 + *<2";
					case TABLE_ENTRY_NT: return "*=-*$1(*%1, 1, *1 + *<2)";
					case PROPERTY_VALUE_NT: return "*=-WriteGProperty(*|1,*+1 + *<2)";
					case LIST_ENTRY_NT: return "*=-WriteLIST_OF_TY_GetItem(*%1,*1 + *<2)";
				}
			}
			return "";
		case INCREASE_BY_REAL:
			switch(storage_class) {
				case LOCAL_VARIABLE_NT: return "*=-*1 = REAL_NUMBER_TY_Plus(*1, *<2)";
				case NONLOCAL_VARIABLE_NT: return "*=-*1 = REAL_NUMBER_TY_Plus(*1, *<2)";
				case TABLE_ENTRY_NT: return "*=-*$1(*%1,1,REAL_NUMBER_TY_Plus(*1, *<2))";
				case PROPERTY_VALUE_NT: return "*=-WriteGProperty(*|1,REAL_NUMBER_TY_Plus(*+1, *<2))";
				case LIST_ENTRY_NT: return "*=-WriteLIST_OF_TY_GetItem(*%1,REAL_NUMBER_TY_Plus(*1, *<2))";
			}
			return "";
		case INCREASE_BY_POINTER:
			internal_error("pointer value increments not implemented");
			return "";
		case DECREASE_BY_WORD:
			if (reducing_modulo_1440) {
				switch(storage_class) {
					case LOCAL_VARIABLE_NT: return "*=-*1 = NUMBER_TY_to_TIME_TY(*1 - *<2)";
					case NONLOCAL_VARIABLE_NT: return "*=-*1 = NUMBER_TY_to_TIME_TY(*1 - *<2)";
					case TABLE_ENTRY_NT: return "*=-*$1(*%1,1,NUMBER_TY_to_TIME_TY(*1 - *<2))";
					case PROPERTY_VALUE_NT: return "*=-WriteGProperty(*|1,NUMBER_TY_to_TIME_TY(*+1 - *<2))";
					case LIST_ENTRY_NT: return "*=-WriteLIST_OF_TY_GetItem(*%1,NUMBER_TY_to_TIME_TY(*1 - *<2))";
				}
			} else {
				switch(storage_class) {
					case LOCAL_VARIABLE_NT: return "*=-*1 = *1 - *<2";
					case NONLOCAL_VARIABLE_NT: return "*=-*1 = *1 - *<2";
					case TABLE_ENTRY_NT: return "*=-*$1(*%1,1,*1 - *<2)";
					case PROPERTY_VALUE_NT: return "*=-WriteGProperty(*|1,*+1 - *<2)";
					case LIST_ENTRY_NT: return "*=-WriteLIST_OF_TY_GetItem(*%1,*1 - *<2)";
				}
			}
			return "";
		case DECREASE_BY_REAL:
			switch(storage_class) {
				case LOCAL_VARIABLE_NT: return "*=-*1 = REAL_NUMBER_TY_Minus(*1, *<2)";
				case NONLOCAL_VARIABLE_NT: return "*=-*1 = REAL_NUMBER_TY_Minus(*1, *<2)";
				case TABLE_ENTRY_NT: return "*=-*$1(*%1,1,REAL_NUMBER_TY_Minus(*1, *<2))";
				case PROPERTY_VALUE_NT: return "*=-WriteGProperty(*|1,REAL_NUMBER_TY_Minus(*+1, *<2))";
				case LIST_ENTRY_NT: return "*=-WriteLIST_OF_TY_GetItem(*%1,REAL_NUMBER_TY_Minus(*1, *<2))";
			}
			return "";
		case DECREASE_BY_POINTER:
			internal_error("pointer value decrements not implemented");
			return "";
	}
	return "";
}
