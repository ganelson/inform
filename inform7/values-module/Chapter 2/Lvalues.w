[Lvalues::] Lvalues.

Storage locations into which rvalues can be put at run-time.

@h Creation.
"Lvalues" can occur on the left of an assignment sign: they are values
which can be written to.

|LOCAL_VARIABLE_NT| refers to a specific local variable, so it has meaning
only within the routine currently being compiled. A |local_variable| pointer
is attached. There are no references or arguments.

|NONLOCAL_VARIABLE_NT| refers to a variable of any other scope: that is, a
global variable, or perhaps a rulebook, action or activity variable. The
important distinction between these other scopes and local scope is
essentially that local variables live on the I6 call-stack and have only a
local namespace, whereas others correspond to array entries or global I6
variables and share a global namespace. (It is basically a matter of
implementation convenience which makes us divide the stock of variables
into two different species this way.) A |instance *| pointer is attached,
identifying the name of the variable in question. There are no
arguments.

|PROPERTY_VALUE_NT| represents a given (value-)property of a given object,
not the name of a property in abstract. Thus "description of the Police
Commissioner" qualifies, but "description" does not. There are two arguments:
the property and the object which possesses it, respectively.

|TABLE_ENTRY_NT| represents a given entry to a table, which can be referred
to in several different ways. There are four different kinds of table reference,
distinguished by the number of arguments found:

(1) 1 argument. By column name only, the table and row to be understood from
context because we have selected a row in the surrounding source text.
(2) 2 arguments. Used as a condition to see if a value is listed in a
given column of a given table. Argument 0 must be a constant of kind
"table column", argument 1 any value of kind "table". (Argument 0
has to be a constant because it is not type-safe to allow looping through
columns, say: different columns have different kinds, and the compiler
would be unable to tell the kind of the result of such a lookup. The
same doesn't apply to argument 1, perhaps oddly, because Inform requires
that every column name have the same kind in every table using it. So
the choice of table does not have to be a constant, and this allows
for some interesting data structures to be built.)
(3) 3 arguments. An explicitly specified entry. The arguments are the
table column, row number, and table respectively.
(4) 4 arguments. A reference to the X corresponding to a Y value of Z in table T.
The arguments are X, Y, Z, T respectively.

|LIST_ENTRY_NT| represents a given entry in a list, which is much simpler:
there are two arguments, the list and the numerical index, which counts from 1.

Note that property names, table names, and lists themselves are not storage
items as such -- they are places where storage items are found. They are
all in the |VALUE| family.

@ And here are some convenient creators. Variables:

=
parse_node *Lvalues::new_LOCAL_VARIABLE(wording W, local_variable *lvar) {
	parse_node *spec = Node::new(LOCAL_VARIABLE_NT);
	Node::set_text(spec, W);
	Node::set_constant_local_variable(spec, lvar);
	if (lvar == NULL) internal_error("bad local variable");
	return spec;
}

parse_node *Lvalues::new_actual_NONLOCAL_VARIABLE(nonlocal_variable *nlv) {
	parse_node *spec = Node::new(NONLOCAL_VARIABLE_NT);
	Node::set_constant_nonlocal_variable(spec, nlv);
	Node::set_text(spec, nlv->name);
	return spec;
}

@ Table entries have their arguments filled in by the relevant routines in
"Meaning List Conversion":

=
parse_node *Lvalues::new_TABLE_ENTRY(wording W) {
	parse_node *spec = Node::new_with_words(TABLE_ENTRY_NT, W);
	return spec;
}

@ List entries:

=
parse_node *Lvalues::new_LIST_ENTRY(parse_node *owner, parse_node *index) {
	parse_node *spec = Node::new(LIST_ENTRY_NT);
	spec->down = owner;
	spec->down->next = index;
	return spec;
}

@ Property values are constructed out of what's often only implied text:
for instance, "description" sometimes means "the description [of the
|self| object]". We give them a word range which is minimal such that it
must contain word ranges of both property and owner, if given. Thus
"carrying capacity of the trunk" will result from "carrying capacity"
and "trunk". This is not very scientific, perhaps, but it's done only to
make problem messages more readable.

=
parse_node *Lvalues::new_PROPERTY_VALUE(parse_node *prop, parse_node *owner) {
	parse_node *spec = Node::new(PROPERTY_VALUE_NT);
	spec->down = prop;
	spec->down->next = owner;
	Node::set_text(spec,
		Wordings::union(Node::get_text(prop), Node::get_text(owner)));
	return spec;
}

@ On the other hand we sometimes want to refer to the property in abstract.

=
parse_node *Lvalues::underlying_property(parse_node *spec) {
	if (Node::is(spec, PROPERTY_VALUE_NT)) {
		if (Rvalues::is_self_object_constant(spec->down->next))
			return spec->down;
		return spec;
	}
	internal_error("no underlying property"); return NULL;
}

@h Testing.

=
int Lvalues::is_lvalue(parse_node *spec) {
	node_type_metadata *metadata = NodeType::get_metadata(Node::get_type(spec));
	if ((metadata) && (metadata->category == LVALUE_NCAT)) return TRUE;
	return FALSE;
}

node_type_t Lvalues::get_storage_form(parse_node *spec) {
	if (Lvalues::is_lvalue(spec)) return Node::get_type(spec);
	return UNKNOWN_NT;
}

@ More specifically:

=
int Lvalues::is_actual_NONLOCAL_VARIABLE(parse_node *spec) {
	if (Node::is(spec, NONLOCAL_VARIABLE_NT)) return TRUE;
	return FALSE;
}

nonlocal_variable *Lvalues::get_nonlocal_variable_if_any(parse_node *spec) {
	if (Node::is(spec, NONLOCAL_VARIABLE_NT))
		return Node::get_constant_nonlocal_variable(spec);
	return NULL;
}

int Lvalues::is_constant_NONLOCAL_VARIABLE(parse_node *spec) {
	nonlocal_variable *nlv = Lvalues::get_nonlocal_variable_if_any(spec);
	if (nlv) return NonlocalVariables::is_constant(nlv);
	return FALSE;
}

@ Not all non-local variables are global -- some have scope local to rulebooks,
actions and the like:

=
int Lvalues::is_global_variable(parse_node *spec) {
	if (Lvalues::get_nonlocal_variable_if_any(spec)) return TRUE;
	return FALSE;
}

@h Pretty-printing.

=
void Lvalues::write_out_in_English(OUTPUT_STREAM, parse_node *spec) {
	switch(Node::get_type(spec)) {
		case LOCAL_VARIABLE_NT: WRITE("a temporary named value"); break;
		case NONLOCAL_VARIABLE_NT:
			if (Node::get_kind_of_value(spec)) {
				Kinds::Textual::write_articled(OUT, Node::get_kind_of_value(spec));
				WRITE(" that varies");
			} else WRITE("a non-temporary variable");
			break;
		case TABLE_ENTRY_NT: WRITE("a table entry"); break;
		case LIST_ENTRY_NT: WRITE("a list entry"); break;
		case PROPERTY_VALUE_NT:
			if ((Node::no_children(spec) == 2) &&
				(Rvalues::is_CONSTANT_construction(spec->down, CON_property))) {
				property *prn = Rvalues::to_property(
					spec->down);
				WRITE("a property whose value is ");
				Kinds::Textual::write_articled(OUT, Properties::Valued::kind(prn));
			} else WRITE("a property belonging to something");
			break;
		default: WRITE("a stored value"); break;
	}
}

@h Compilation.

=
kind *Lvalues::to_kind(parse_node *spec) {
	if (spec == NULL) internal_error("Rvalues::to_kind on NULL");
	switch (Node::get_type(spec)) {
		case LOCAL_VARIABLE_NT: @<Return the kind of a local variable@>;
		case NONLOCAL_VARIABLE_NT: @<Return the kind of a non-local variable@>;
		case TABLE_ENTRY_NT: @<Return the kind of a table entry@>;
		case LIST_ENTRY_NT: @<Return the kind of a list entry@>;
		case PROPERTY_VALUE_NT: @<Return the kind of a property value@>;
	}
	return K_value; /* a generic answer for storage of an unknown sort */
}

@<Return the kind of a local variable@> =
	local_variable *lvar = Node::get_constant_local_variable(spec);
	if (lvar == NULL) return K_value; /* for "existing" */
	return LocalVariables::unproblematic_kind(lvar);

@<Return the kind of a non-local variable@> =
	nonlocal_variable *nlv = Node::get_constant_nonlocal_variable(spec);
	return NonlocalVariables::kind(nlv);

@ In every form of table entry, argument 0 is the column, and the column
is enough to determine the kind:

@<Return the kind of a table entry@> =
	if (Node::no_children(spec) > 0) { /* i.e., always, for actual table entry specifications */
		parse_node *fts = spec->down;
		table_column *tc = Rvalues::to_table_column(fts);
		return Tables::Columns::get_kind(tc);
	}
	return NULL; /* can happen when scanning phrase arguments, which are generic */

@<Return the kind of a list entry@> =
	if (Node::no_children(spec) == 2) { /* i.e., always, for actual list entry specifications */
		kind *K1 = Specifications::to_kind(spec->down);
		if (Kinds::unary_construction_material(K1)) return Kinds::unary_construction_material(K1);
		return K_value; /* to help the type-checker produce better problem messages */
	}
	return NULL; /* can happen when scanning phrase arguments, which are generic */

@<Return the kind of a property value@> =
	if (Node::no_children(spec) == 2) {
		property *prn = Rvalues::to_property(spec->down);
		if ((prn) && (Properties::is_either_or(prn) == FALSE)) return Properties::Valued::kind(prn);
		return K_value; /* to help the type-checker produce better problem messages */
	}
	return NULL; /* can happen when scanning phrase arguments, which are generic */

@ =
local_variable *Lvalues::get_local_variable_if_any(parse_node *spec) {
	if (Node::is(spec, LOCAL_VARIABLE_NT))
		return Node::get_constant_local_variable(spec);
	return NULL;
}

@h Rvalue compilation.
We finally reach the compilation routine which produces an I6 expression
evaluating to the contents of the storage item specified.

=
void Lvalues::compile(value_holster *VH, parse_node *spec_found) {
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
	inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
	if (lvar == NULL) {
		LOG("Bad: %08x\n", spec_found);
		internal_error("Compiled never-specified LOCAL VARIABLE SP");
	}
	Produce::val_symbol(Emit::tree(), K_value, lvar_s);
	return;

@<Compile a non-local variable specification@> =
	nonlocal_variable *nlv = Node::get_constant_nonlocal_variable(spec_found);
	NonlocalVariables::emit_lvalue(nlv);
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

	if (TEST_COMPILATION_MODE(JUST_ROUTINE_CMODE)) {
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(GPROPERTY_HL));
	} else {
		if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(GPROPERTY_HL));
			Produce::down(Emit::tree());
		}
		Kinds::RunTime::emit_weak_id_as_val(owner_kind);
		@<Emit the property's owner@>;
		Specifications::Compiler::emit_as_val(K_value, prop_spec);
		if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
			Produce::up(Emit::tree());
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
		inference_subject *infs = Properties::Conditions::of_what(prn);
		instance *I = InferenceSubjects::as_object_instance(infs);
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
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::ref_iname(Emit::tree(), K_value, Hierarchy::find(SELF_HL));
			Specifications::Compiler::emit_as_val(K_value, owner);
		Produce::up(Emit::tree());
	} else {
		Specifications::Compiler::emit_as_val(K_value, owner);
	}

@ List entries are blessedly simpler.

@<Compile a list entry specification@> =
	if (Node::no_children(spec_found) != 2) internal_error("malformed LIST_OF SP");
	if (spec_found->down == NULL) internal_error("LIST_OF with null arg 0");
	if (spec_found->down->next == NULL) internal_error("LIST_OF with null arg 1");

	if (TEST_COMPILATION_MODE(JUST_ROUTINE_CMODE)) {
		Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(LIST_OF_TY_GETITEM_HL));
	} else {
		if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(LIST_OF_TY_GETITEM_HL));
			Produce::down(Emit::tree());
		}
		BEGIN_COMPILATION_MODE;
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
		Specifications::Compiler::emit_as_val(K_value, spec_found->down);
		END_COMPILATION_MODE;
		Specifications::Compiler::emit_as_val(K_value, spec_found->down->next);
		if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
			Produce::up(Emit::tree());
		}
	}
	return;

@ Table entries are simple too, but come in four variant forms:

@<Compile a table entry specification@> =
	inter_name *lookup = Hierarchy::find(TABLELOOKUPENTRY_HL);
	inter_name *lookup_corr = Hierarchy::find(TABLELOOKUPCORR_HL);
	if (TEST_COMPILATION_MODE(TABLE_EXISTENCE_CMODE_ISSBM)) {
		lookup = Hierarchy::find(EXISTSTABLELOOKUPENTRY_HL);
		lookup_corr = Hierarchy::find(EXISTSTABLELOOKUPCORR_HL);
	}

	switch(Node::no_children(spec_found)) {
		case 1:
			if (TEST_COMPILATION_MODE(JUST_ROUTINE_CMODE)) {
				Produce::val_iname(Emit::tree(), K_value, lookup);
			} else {
				LocalVariables::used_stack_selection();
				LocalVariables::add_table_lookup();
				if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
					Produce::inv_call_iname(Emit::tree(), lookup);
					Produce::down(Emit::tree());
				}
				local_variable *ct_0_lv = LocalVariables::by_name(I"ct_0");
				inter_symbol *ct_0_s = LocalVariables::declare_this(ct_0_lv, FALSE, 8);
				local_variable *ct_1_lv = LocalVariables::by_name(I"ct_1");
				inter_symbol *ct_1_s = LocalVariables::declare_this(ct_1_lv, FALSE, 8);
				Produce::val_symbol(Emit::tree(), K_value, ct_0_s);
				Specifications::Compiler::emit_as_val(K_value, spec_found->down);
				Produce::val_symbol(Emit::tree(), K_value, ct_1_s);
				if (TEST_COMPILATION_MODE(BLANK_OUT_CMODE)) {
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 4);
				}
				if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
					Produce::up(Emit::tree());
				}
			}
			break;
		case 2: /* never here except when printing debugging code */
			Produce::val(Emit::tree(), K_truth_state, LITERAL_IVAL, 0);
			break;
		case 3:
			if (TEST_COMPILATION_MODE(JUST_ROUTINE_CMODE)) {
				Produce::val_iname(Emit::tree(), K_value, lookup);
			} else {
				if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
					Produce::inv_call_iname(Emit::tree(), lookup);
					Produce::down(Emit::tree());
				}
				Specifications::Compiler::emit_as_val(K_value, spec_found->down->next->next);
				Specifications::Compiler::emit_as_val(K_value, spec_found->down);
				Specifications::Compiler::emit_as_val(K_value, spec_found->down->next);
				if (TEST_COMPILATION_MODE(BLANK_OUT_CMODE)) {
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 4);
				}
				if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
					Produce::up(Emit::tree());
				}
			}
			break;
		case 4:
			if (TEST_COMPILATION_MODE(JUST_ROUTINE_CMODE)) {
				Produce::val_iname(Emit::tree(), K_value, lookup_corr);
			} else {
				if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
					Produce::inv_call_iname(Emit::tree(), lookup_corr);
					Produce::down(Emit::tree());
				}
				Specifications::Compiler::emit_as_val(K_value, spec_found->down->next->next->next);
				Specifications::Compiler::emit_as_val(K_value, spec_found->down);
				Specifications::Compiler::emit_as_val(K_value, spec_found->down->next);
				Specifications::Compiler::emit_as_val(K_value, spec_found->down->next->next);
				if (TEST_COMPILATION_MODE(BLANK_OUT_CMODE)) {
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 4);
				}
				if (!(TEST_COMPILATION_MODE(TREAT_AS_LVALUE_CMODE))) {
					Produce::up(Emit::tree());
				}
			}
			break;
		default: internal_error("TABLE REFERENCE with bad number of args");
	}
	return;

@h Lvalue compilation.
To recap, if an assignment takes the form "now X is Y" then X is the lvalue,
Y is the rvalue. We only need to read Y, but we need to write X. Compilation
applied to an lvalue specification produces code suitable for reading it, i.e.,
suitable for use in position Y -- but not in general suitable for X.

To compile the lvalue form of a storage item, we use the following schemas.
These in effect take the rvalue form and modify it. There are three
versions, according to the nature of the data being moved; then two
variations for incrementing, and two for decrementing, where Y's value is
added to X's rather than replacing it. In these schemas, |*1| expands to
the storage item's rvalue form, and |*2| to the value being assigned to it.

At present no arithmetic values are stored in pointer values, but that might
change if arbitrary-precision integers are ever added to Inform, for instance.

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
char *Lvalues::storage_class_schema(node_type_t storage_class, int kind_of_store,
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
				case LOCAL_VARIABLE_NT: return "*=-BlkValueCast(*1, *#2, *!2)";
				case NONLOCAL_VARIABLE_NT: return "*=-BlkValueCast(*1, *#2, *!2)";
				case TABLE_ENTRY_NT: return "*=-BlkValueCast(*$1(*%1, 5), *#2, *!2)";
				case PROPERTY_VALUE_NT: return "*=-BlkValueCast(*+1, *#2, *!2)";
				case LIST_ENTRY_NT: return "*=-BlkValueCast(*1, *#2, *!2)";
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

@ Here we supply advice on whether shallow or deep copies are needed. |inc| is
positive if we're incrementing what's there, negative if decrementing, zero
if simply setting.

=
char *Lvalues::interpret_store(node_type_t storage_class, kind *left, kind *right, int inc) {
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
	if (Kinds::Constructors::uses_pointer_values(L)) {
		if (Kinds::Constructors::allow_word_as_pointer(L, R)) {
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
	return Lvalues::storage_class_schema(storage_class, form, reduce);
}
