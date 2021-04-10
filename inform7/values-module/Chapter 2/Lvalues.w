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

@ On which subject:

=
local_variable *Lvalues::get_local_variable_if_any(parse_node *spec) {
	if (Node::is(spec, LOCAL_VARIABLE_NT))
		return Node::get_constant_local_variable(spec);
	return NULL;
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
				Kinds::Textual::write_articled(OUT, ValueProperties::kind(prn));
			} else WRITE("a property belonging to something");
			break;
		default: WRITE("a stored value"); break;
	}
}

@h Kinds.

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
	return LocalVariables::kind(lvar);

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
		if ((prn) && (Properties::is_either_or(prn) == FALSE)) return ValueProperties::kind(prn);
		return K_value; /* to help the type-checker produce better problem messages */
	}
	return NULL; /* can happen when scanning phrase arguments, which are generic */
