[CompileSpecifications::] Compiling from Specifications.

To compile specifications into Inter values, conditions or void expressions.

@ Specifications unite values, conditions and descriptions: see //values: Specifications//.
They are stored as |parse_node| pointers. Here, we compile them to a 

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
@d CONSTANT_CMODE 			      0x00002000 /* compiling values in a constant context */

@d TREAT_AS_LVALUE_CMODE		  0x00010000 /* compile storage as lvalue not rvalue */
@d JUST_ROUTINE_CMODE			  0x00020000 /* compile storage to Inter function handling it */

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

@ And the same in a constant context:

=
void CompileSpecifications::to_array_entry(parse_node *spec) {
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	CompileSpecifications::to_holster(&VH, spec, TRUE);
	inter_ti v1 = 0, v2 = 0;
	Holsters::unholster_pair(&VH, &v1, &v2);
	Emit::array_generic_entry(v1, v2);
}

void CompileSpecifications::to_array_entry_promoting(parse_node *value, kind *K_wanted) {
	CompileSpecifications::to_array_entry(
		CompileSpecifications::cast(value, K_wanted));
}

void CompileSpecifications::to_code_val(kind *K, parse_node *spec) {
	value_holster VH = Holsters::new(INTER_VAL_VHMODE);
	CompileSpecifications::to_holster(&VH, spec, FALSE);
}

@ A variation on this is to compile a specification which represents
a value in a context where a particular kind of value is expected:

=
void CompileSpecifications::to_code_val_promoting(parse_node *value, kind *K_wanted) {
	RTKinds::notify_of_use(K_wanted);
	kind *K_found = Specifications::to_kind(value);
	RTKinds::notify_of_use(K_found);

	if ((K_understanding) && (Kinds::eq(K_wanted, K_understanding)) && (Kinds::eq(K_found, K_text))) {
		Node::set_kind_of_value(value, K_understanding);
		K_found = K_understanding;
	}

	int down = FALSE;
	RTKinds::emit_cast_call(K_found, K_wanted, &down);
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_ENTER(PERMIT_LOCALS_IN_TEXT_CMODE);
	CompileSpecifications::to_code_val(K_value, value);
	END_COMPILATION_MODE;
	if (down) Produce::up(Emit::tree());
}




void CompileSpecifications::holster_constant(value_holster *VH, parse_node *value, kind *K_wanted) {
	CompileSpecifications::to_holster(VH,
		CompileSpecifications::cast(value, K_wanted), TRUE);
}

parse_node *CompileSpecifications::cast(parse_node *value, kind *K_wanted) {
	RTKinds::notify_of_use(K_wanted);
	value = LiteralReals::promote_number_if_necessary(value, K_wanted);
	return value;
}

void CompileSpecifications::to_pair(inter_ti *v1, inter_ti *v2, parse_node *spec) {
	BEGIN_COMPILATION_MODE;
	COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
	value_holster VH = Holsters::new(INTER_DATA_VHMODE);
	CompileSpecifications::to_holster(&VH, spec, FALSE);
	Holsters::unholster_pair(&VH, v1, v2);
	END_COMPILATION_MODE;
}

void CompileSpecifications::to_holster(value_holster *VH, parse_node *spec, int c) {
	LOGIF(EXPRESSIONS, "Compiling: $P\n", spec);
	BEGIN_COMPILATION_MODE;
	if (c) {
		COMPILATION_MODE_EXIT(DEREFERENCE_POINTERS_CMODE);
		COMPILATION_MODE_ENTER(CONSTANT_CMODE);
	}	
	spec = NonlocalVariables::substitute_constants(spec);

	LOG_INDENT;
	kind *K_found = Specifications::to_kind(spec);
	RTKinds::notify_of_use(K_found);

	int dereffed = FALSE;
	if (TEST_COMPILATION_MODE(DEREFERENCE_POINTERS_CMODE)) {
		kind *K = Specifications::to_kind(spec);
		if ((K) && (Kinds::Behaviour::uses_pointer_values(K))) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUECOPY_HL));
			Produce::down(Emit::tree());
				Frames::emit_new_local_value(K);
			dereffed = TRUE;
		}
	}
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
	if (dereffed) {
		Produce::up(Emit::tree());
	}
	LOG_OUTDENT;
	END_COMPILATION_MODE;
}
