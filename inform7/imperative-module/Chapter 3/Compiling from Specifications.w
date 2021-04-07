[CompileSpecifications::] Compiling from Specifications.

To compile specifications into Inter values, conditions or void expressions.

@h Introduction.
Specifications unite values, conditions and descriptions: see //values: Specifications//.
They are stored as |parse_node| pointers. In this chapter we will compile them,
making our best effort to have a single unified process for that even though:
(*) We may need to compile either an array entry or an Inter |val| opcode.
We abstract this using //building: Value Holsters//, holders into which
compiled values are placed.
(*) How we compile sometimes depends on context: for a variable, for example,
it may matter whether we are compiling it as lvalue (to be assigned to) or
rvalue (to be read from). So there are a number of compilation "modes"[1] which,
in combination, express the current context.

[1] At one time there were as many as 12, but there really should be as few
as possible.

@h The modes.
|CONSTANT_CMODE| in on when we are compiling in a constant context: for example,
to compile an array entry, or the initial value of a property or variable. It
affects, for exanple, how text substitutions and action patterns are compiled
into values. The API below automatically manages when we are in |CONSTANT_CMODE|,
so the rest of Inform need not worry about it.

This is recursive so that if, for example, |{ X, Y, Z }| is compiled in constant
mode then so are |X|, |Y| and |Z|.

@ |BY_VALUE_CMODE| is on when we want the value compiled to be a new, independent
copy of the data in question. Consider:
= (text as Inform 7)
	let T be { 2, 3, 5, 7 };
	let U be T;
	add 11 to T;
=
Clearly |U| must be set to a new copy of the data in |T|, not a reference to the
same data. So the |T| in |let U be T| is compiled by value. (This is in fact the
default: the alternative, compilation by reference, is less often used.)

@ |IMPLY_NEWLINES_IN_SAY_CMODE| is on when we understand the final part of a
text literal to be allowed to print an implied newline. For example, here it's on:
= (text as Inform 7)
	say "At [time of day], I like to serve afternoon tea. Indian or Chinese?";
=
Here the question mark has an implied newline after it. But there are other
contexts in which newlines are not implied:
= (text as Inform 7)
	let the warning rubric be "Snakes!";
=
But this mode is on by default.

@ So, then, the current state is a single global variable which is a bitmap of these:

@d CONSTANT_CMODE               0x00000001 /* compiling values in a constant context */
@d BY_VALUE_CMODE               0x00000002 /* rather than by reference */
@d IMPLY_NEWLINES_IN_SAY_CMODE  0x00000004 /* at the end, that is */

= (early code)
int compilation_mode = BY_VALUE_CMODE + IMPLY_NEWLINES_IN_SAY_CMODE; /* default */

@ The model for mode switches is that Inform will temporarily enter, or temporarily
exit, a mode when it has particular compilation needs. It should place such
operations within a pair of |BEGIN_COMPILATION_MODE| and |END_COMPILATION_MODE|
macros, in such a way that execution always passes from one to the other. Within
those bookends, it can use either the enter or exit macros to switch a particular
mode on or off.

@d BEGIN_COMPILATION_MODE
	int status_quo_ante = compilation_mode;

@d COMPILATION_MODE_ENTER(mode)
	compilation_mode |= mode;

@d COMPILATION_MODE_EXIT(mode)
	compilation_mode &= (~mode);

@d END_COMPILATION_MODE
	compilation_mode = status_quo_ante;

@d TEST_COMPILATION_MODE(mode)
	(compilation_mode & mode)

@h An API for compiling specifications.
When the rest of Inform wants to compile a specification, it should call one
of the following functions.

To begin with, compiling to array entries:

=
void CompileSpecifications::to_array_entry_of_kind(parse_node *value, kind *K_wanted) {
	CompileSpecifications::to_array_entry(
		CompileSpecifications::cast_constant(value, K_wanted));
}

void CompileSpecifications::to_array_entry(parse_node *spec) {
	inter_ti v1 = 0, v2 = 0;
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	CompileSpecifications::to_holster(&VH, spec, TRUE, TRUE);
	Holsters::unholster_pair(&VH, &v1, &v2);
	Emit::array_generic_entry(v1, v2);
}

@ Now constants, which can be compiled either to a holster or to a pair of |inter_t|
numbers. Use the latter as little as possible.

=
void CompileSpecifications::constant_to_holster(value_holster *VH, parse_node *value,
	kind *K_wanted) {
	CompileSpecifications::to_holster(VH,
		CompileSpecifications::cast_constant(value, K_wanted), TRUE, TRUE);
}

void CompileSpecifications::constant_to_pair(inter_ti *v1, inter_ti *v2,
	parse_node *value, kind *K_wanted) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	CompileSpecifications::constant_to_holster(&VH, value, K_wanted);
	Holsters::unholster_pair(&VH, v1, v2);
}

@ A general method (i.e., not restricted to constant context) for compiling to a
pair of |inter_t| numbers. Use this as little as possible.

=
void CompileSpecifications::to_pair(inter_ti *v1, inter_ti *v2, parse_node *spec) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	CompileSpecifications::to_holster(&VH, spec, FALSE, TRUE);
	Holsters::unholster_pair(&VH, v1, v2);
}

@ Finally, for compiling to Inter opcodes in a |val| context -- in other words,
for values as they appear in imperative code rather than in data structures
such as arrays.

=
void CompileSpecifications::to_code_val(kind *K, parse_node *spec) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	CompileSpecifications::to_holster(&VH, spec, FALSE, FALSE);
}

void CompileSpecifications::to_code_val_by_reference(kind *K, parse_node *spec) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	CompileSpecifications::to_holster(&VH, spec, FALSE, TRUE);
}

void CompileSpecifications::to_code_val_of_kind(parse_node *value, kind *K_wanted) {
	int down = FALSE;
	value = CompileSpecifications::cast_in_val_mode(value, K_wanted, &down);
	CompileSpecifications::to_code_val(K_value, value);
	if (down) Produce::up(Emit::tree());
}

@ All of the functions in the above API make use of this private one:

=
void CompileSpecifications::to_holster(value_holster *VH, parse_node *spec,
	int as_const, int by_ref) {
	LOGIF(EXPRESSIONS, "Compiling: $P\n", spec);
	BEGIN_COMPILATION_MODE;
	if (as_const) COMPILATION_MODE_ENTER(CONSTANT_CMODE);
	if (by_ref) COMPILATION_MODE_EXIT(BY_VALUE_CMODE);
	LOG_INDENT;
	@<Compile this either by value or reference@>;
	LOG_OUTDENT;
	END_COMPILATION_MODE;
}

@ This implements |BY_VALUE_CMODE|. For regular values like numbers there's no
difference, but if our value is a block value such as a list then we evaluate to
a copy of it, not to the original. Making that copy means calling |BlkValueCopy|
at runtime, so it cannot be done in a data holster (i.e., when |VH| is an
|INTER_DATA_VHMODE| holster).

@<Compile this either by value or reference@> =	
	spec = NonlocalVariables::substitute_constants(spec);
	kind *K_found = Specifications::to_kind(spec);
	RTKinds::notify_of_use(K_found);
	int copied_a_block_value = FALSE;
	if (TEST_COMPILATION_MODE(BY_VALUE_CMODE)) {
		if (VH->vhmode_wanted == INTER_DATA_VHMODE)
			internal_error("must compile by reference in INTER_DATA_VHMODE"); 
		kind *K = Specifications::to_kind(spec);
		if ((K) && (Kinds::Behaviour::uses_pointer_values(K))) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUECOPY_HL));
			Produce::down(Emit::tree());
				Frames::emit_new_local_value(K);
			copied_a_block_value = TRUE;
		}
	}
	@<Compile this@>;
	if (copied_a_block_value) {
		Produce::up(Emit::tree());
	}

@<Compile this@> =
	if (Lvalues::is_lvalue(spec)) {
		Lvalues::compile(VH, spec);
	} else if (Rvalues::is_rvalue(spec)) {
		Rvalues::compile(VH, spec);
		if ((VH->vhmode_provided == INTER_DATA_VHMODE) &&
			(VH->vhmode_wanted == INTER_VAL_VHMODE)) {
			Holsters::unholster_to_code_val(Emit::tree(), VH);
		}
	} else if (Specifications::is_condition(spec)) {
		Conditions::compile(VH, spec);
	}

@h Casting.
"Casting" is converting a value of one kind to a value of another but which has
the same meaning, give or take. In a constant context, all we can cast is from
literal |K_number| values like |31| to turn them into literal |K_real_number|
values, a process called "promotion".

=
parse_node *CompileSpecifications::cast_constant(parse_node *value, kind *K_wanted) {
	value = NonlocalVariables::substitute_constants(value);
	RTKinds::notify_of_use(K_wanted);
	value = LiteralReals::promote_number_if_necessary(value, K_wanted);
	kind *K_found = Specifications::to_kind(value);
	if ((K_understanding) &&
		(Kinds::eq(K_wanted, K_understanding)) && (Kinds::eq(K_found, K_text))) {
		Node::set_kind_of_value(value, K_understanding);
		K_found = K_understanding;
	}
	return value;
}

@ In a value context we can additionally compile code to perform the conversion
at runtime, which extends the range of promotions we can make.

=
parse_node *CompileSpecifications::cast_in_val_mode(parse_node *value, kind *K_wanted,
	int *down) {
	value = CompileSpecifications::cast_constant(value, K_wanted);
	kind *K_found = Specifications::to_kind(value);
	RTKinds::notify_of_use(K_found);
	RTKinds::emit_cast_call(K_found, K_wanted, down);
	return value;
}
