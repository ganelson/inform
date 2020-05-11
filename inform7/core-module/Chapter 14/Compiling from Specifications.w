[Specifications::Compiler::] Compiling from Specifications.

To compile specifications into Inform 6 values, conditions or void
expressions.

@h Definitions.

@ In a more traditional compiler, the code-generator would be something of a
landmark -- one of the three or four most important stations. Here it's
something of an anticlimax, partly because traditional "code" -- values
and statements -- are only a small part of the I6 we have to generate,
which also includes object and class definitions, grammar, and so on.

Still, this is the key point where the actual rather than generic
specifications -- phrases to do something, or to decide things; constants;
variables; conditions -- finally convert into I6 code.

@ For the most part this is "modeless" -- that is, the I6 code generated
by a specification does not depend on any context. But not entirely so, and
we have a small set of "C-modes", each of which slightly alters the result
to fit some particular need.

The rule is that any part of Inform needing to do something in a specific
mode should place that operation within a pair of |BEGIN_COMPILATION_MODE|
and |END_COMPILATION_MODE| macros, in such a way that execution always
passes from one to the other. Within those bookends, it can use either the
enter or exit macros to switch a particular mode on or off.

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

@d DEREFERENCE_POINTERS_CMODE     0x00000001 /* make an independent copy of the result if on the heap */
@d IMPLY_NEWLINES_IN_SAY_CMODE    0x00000010 /* at the end, that is */
@d PERMIT_LOCALS_IN_TEXT_CMODE    0x00000020 /* unless casting to text */
@d COMPILE_TEXT_TO_QUOT_CMODE     0x00000080 /* for the idiosyncratic I6 |box| statement */
@d COMPILE_TEXT_TO_XML_CMODE      0x00000100 /* use XML escapes and UTF-8 encoding */
@d TRUNCATE_TEXT_CMODE            0x00000200 /* into a plausible filename length */
@d COMPILE_TEXT_TO_I6_CMODE       0x00001000 /* for bibliographic text to I6 constants */
@d CONSTANT_CMODE 			      0x00002000 /* compiling values in a constant context */
@d SPECIFICATIONS_CMODE 		  0x00004000 /* compiling specifications at all */
@d BLANK_OUT_CMODE		 		  0x00008000 /* blank out table references */
@d TREAT_AS_LVALUE_CMODE		  0x00010000 /* similarly affects table references */
@d JUST_ROUTINE_CMODE			  0x00020000 /* similarly affects table references */

= (early code)
int compilation_mode = DEREFERENCE_POINTERS_CMODE + IMPLY_NEWLINES_IN_SAY_CMODE; /* default */

@ These modes are all explained where they are used. The one used right here
is |DEREFERENCE_POINTERS_CMODE|. This applies only when compiling a specification
which generates a pointer value -- an I6 value which is a pointer to a larger
block of data on the heap, such as a list or text.

Inform presents such values to the end user exactly as if they are non-pointer
values. It must always be careful to ensure that there are never two different
I7 values each holding pointers to the same block of data, because then
changing one would also change the other. So we ordinarily need
to make a copy of any block of data produced as a value; this is called
"dereferencing".

But there are some circumstances -- initialising entries in an Inform 6 array,
for instance -- where we don't want to do this, and indeed can't, because the
code to handle dereferencing is invalid as an Inform 6 constant. The mode
therefore exists as a way of temporarily turning off dereferencing -- by
default, it is always on.

@ The outer shell here has two purposes. One is to copy the specification
onto the local stack frame and then compile that copy -- useful since
compilation may alter its contents. The other purpose, and this is not to
be dismissed lightly, is to ensure correct indentation in the log when
we exit unexpectedly, for instance due to a problem.

@ =
void Specifications::Compiler::compile_inner(value_holster *VH, parse_node *spec) {
	LOGIF(EXPRESSIONS, "Compiling: $P\n", spec);
	spec = NonlocalVariables::substitute_constants(spec);

	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(SPECIFICATIONS_CMODE);
	LOG_INDENT;
	parse_node breakable_copy = *spec;
	Specifications::Compiler::spec_compile_primitive(VH, &breakable_copy);
	LOG_OUTDENT;
	END_COMPILATION_MODE;
}

@ So this is where the compilation is done, or rather, delegated:

=
void Specifications::Compiler::spec_compile_primitive(value_holster *VH, parse_node *spec) {
	kind *K_found = Specifications::to_kind(spec);
	Kinds::RunTime::notify_of_use(K_found);

	int dereffed = FALSE;
	if (TEST_COMPILATION_MODE(DEREFERENCE_POINTERS_CMODE)) {
		kind *K = Specifications::to_kind(spec);
		if ((K) && (Kinds::Behaviour::uses_pointer_values(K))) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUECOPY_HL));
			Produce::down(Emit::tree());
				Frames::emit_allocation(K);
			dereffed = TRUE;
		}
	}
	if (ParseTreeUsage::is_lvalue(spec)) {
		Lvalues::compile(VH, spec);
	} else if (ParseTreeUsage::is_rvalue(spec)) {
		Rvalues::compile(VH, spec);
		if ((VH->vhmode_provided == INTER_DATA_VHMODE) && (VH->vhmode_wanted == INTER_VAL_VHMODE)) {
			Holsters::to_val_mode(Emit::tree(), VH);
		}
	} else if (ParseTreeUsage::is_condition(spec)) {
		Conditions::compile(VH, spec);
	}
	if (dereffed) {
		Produce::up(Emit::tree());
	}
}

@ A variation on this is to compile a specification which represents
a value in a context where a particular kind of value is expected:

=
void Specifications::Compiler::emit_to_kind(parse_node *value, kind *K_wanted) {
	Kinds::RunTime::notify_of_use(K_wanted);
	kind *K_found = Specifications::to_kind(value);
	Kinds::RunTime::notify_of_use(K_found);

	if ((K_understanding) && (Kinds::Compare::eq(K_wanted, K_understanding)) && (Kinds::Compare::eq(K_found, K_text))) {
		Node::set_kind_of_value(value, K_understanding);
		K_found = K_understanding;
	}

	int down = FALSE;
	Kinds::RunTime::emit_cast_call(K_found, K_wanted, &down);
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(PERMIT_LOCALS_IN_TEXT_CMODE);
	Specifications::Compiler::emit_as_val(K_value, value);
	END_COMPILATION_MODE;
	if (down) Produce::up(Emit::tree());
}

@ And the same in a constant context:

=
void Specifications::Compiler::compile_constant_to_kind_vh(value_holster *VH, parse_node *value, kind *K_wanted) {
	Kinds::RunTime::notify_of_use(K_wanted);
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	COMPILATION_MODE_ENTER(CONSTANT_CMODE);
	Specifications::Compiler::compile_inner(VH, Kinds::Behaviour::cast_constant(value, K_wanted));
	END_COMPILATION_MODE;
}

void Specifications::Compiler::emit_constant_to_kind(parse_node *value, kind *K_wanted) {
	Kinds::RunTime::notify_of_use(K_wanted);
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	COMPILATION_MODE_ENTER(CONSTANT_CMODE);
	parse_node *casted = Kinds::Behaviour::cast_constant(value, K_wanted);
	END_COMPILATION_MODE;
	Specifications::Compiler::emit(casted);
}

void Specifications::Compiler::emit_constant_to_kind_as_val(parse_node *value, kind *K_wanted) {
	Kinds::RunTime::notify_of_use(K_wanted);
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	COMPILATION_MODE_ENTER(CONSTANT_CMODE);
	parse_node *casted = Kinds::Behaviour::cast_constant(value, K_wanted);
	END_COMPILATION_MODE;
	Specifications::Compiler::emit_as_val(K_value, casted);
}

void Specifications::Compiler::emit(parse_node *spec) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);

	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	COMPILATION_MODE_ENTER(CONSTANT_CMODE);
	Specifications::Compiler::compile_inner(&VH, spec);
	END_COMPILATION_MODE;

	inter_t v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	Emit::array_generic_entry(v1, v2);
}

void Specifications::Compiler::emit_as_val(kind *K, parse_node *spec) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	Specifications::Compiler::compile_inner(&VH, spec);
}
