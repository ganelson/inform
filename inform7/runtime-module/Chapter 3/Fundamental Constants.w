[FundamentalConstants::] Fundamental Constants.

Inter constants for, say, extremal number values, which depend on the
target we are compiling to, and are generally low-level in nature.

@ Fundamental constants are emitted about our choice of virtual machine.

The old I6 library used to confuse Z-vs-G with 16-vs-32-bit, but we try
to separate these distinctions here, even though at present the Z-machine
is our only 16-bit target and Glulx our only 32-bit one. The |WORDSIZE|
constant is the word size in bytes, so is the multiplier between |->| and
|-->| offsets in I6 pointer syntax.

(1) |NULL| is used, as in C, to represent a null value or pointer. In C,
this is conventionally 0, but here it is the maximum unsigned value which
can be stored, pointing to the topmost byte in the directly addressable
memory map; this means it is also $-1$ when regarded as a signed
twos-complement integer, but we write it as an unsigned hexadecimal
address for clarity's sake.

(2) |WORD_HIGHBIT| is the most significant bit in the VM's data word.

(3) |IMPROBABLE_VALUE| is one which is unlikely but still possible
to be a genuine I7 value. The efficiency of some algorithms depends on
how well chosen this is: they would ran badly if we chose 1, for instance.

(4) |MAX_POSITIVE_NUMBER| is the largest representable positive (signed)
integer, in twos-complement form.

(5) |REPARSE_CODE| is a magic value used in the I6 library's parser to
signal that some code which ought to have been parsing a command has in
fact rewritten it, so that the whole command must be re-parsed afresh.
(Returning this value is like throwing an exception in a language like
Java, though we don't implement it that way.) A comment in the 6/11 library
reads: "The parser rather gunkily adds addresses to |REPARSE_CODE| for
some purposes. And expects the result to be greater than |REPARSE_CODE|
(signed comparison). So Glulx Inform is limited to a single gigabyte of
storage, for the moment." Guilty as charged, but the gigabyte story file
is a remote prospect for now. Anyway, it's this comparison issue which
means we need a different value for each possible word size.

=
inter_name *FundamentalConstants::emit_one(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant(iname, val);
	return iname;
}

inter_name *FundamentalConstants::emit_signed(int id, int val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant_signed(iname, val);
	return iname;
}

inter_name *FundamentalConstants::emit_hex(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant_hex(iname, val);
	return iname;
}

inter_name *FundamentalConstants::emit_unchecked_hex(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_unchecked_constant_hex(iname, val);
	return iname;
}

void FundamentalConstants::emit(void) {
	target_vm *VM = Task::vm();
	if (VM == NULL) internal_error("target VM not set yet");

	if (TargetVMs::debug_enabled(VM))
		FundamentalConstants::emit_one(DEBUG_HL, 1);

	if (Str::eq(VM->family_name, I"Z-Machine")) {
		FundamentalConstants::emit_one(TARGET_ZCODE_HL, 1);
		FundamentalConstants::emit_one(DICT_WORD_SIZE_HL, 6);
	} else if (Str::eq(VM->family_name, I"Glulx")) {
		FundamentalConstants::emit_one(TARGET_GLULX_HL, 1);
		FundamentalConstants::emit_one(DICT_WORD_SIZE_HL, 9);
		FundamentalConstants::emit_one(INDIV_PROP_START_HL, 0);
	}

	if (TargetVMs::is_16_bit(VM)) {
		FundamentalConstants::emit_one(WORDSIZE_HL, 2);
		FundamentalConstants::emit_unchecked_hex(NULL_HL, 0xffff);
		FundamentalConstants::emit_hex(WORD_HIGHBIT_HL, 0x8000);
		FundamentalConstants::emit_hex(WORD_NEXTTOHIGHBIT_HL, 0x4000);
		FundamentalConstants::emit_hex(IMPROBABLE_VALUE_HL, 0x7fe3);
		FundamentalConstants::emit_hex(REPARSE_CODE_HL, 10000);
		FundamentalConstants::emit_one(MAX_POSITIVE_NUMBER_HL, 32767);
		FundamentalConstants::emit_signed(MIN_NEGATIVE_NUMBER_HL, -32768);
	} else {
		FundamentalConstants::emit_one(WORDSIZE_HL, 4);
		FundamentalConstants::emit_unchecked_hex(NULL_HL, 0xffffffff);
		FundamentalConstants::emit_hex(WORD_HIGHBIT_HL, 0x80000000);
		FundamentalConstants::emit_hex(WORD_NEXTTOHIGHBIT_HL, 0x40000000);
		FundamentalConstants::emit_hex(IMPROBABLE_VALUE_HL, 0xdeadce11);
		FundamentalConstants::emit_hex(REPARSE_CODE_HL, 0x40000000);
		FundamentalConstants::emit_one(MAX_POSITIVE_NUMBER_HL, 2147483647);
		FundamentalConstants::emit_signed(MIN_NEGATIVE_NUMBER_HL, -2147483648);
	}
}

@ This version-numbering constant is not really to do with the VM (it is
Inform's own version number), but it belongs nowhere else either, so:

=
void FundamentalConstants::emit_build_number(void) {
	TEMPORARY_TEXT(build)
	WRITE_TO(build, "%B", TRUE);
	inter_name *iname = Hierarchy::find(NI_BUILD_COUNT_HL);
	Emit::text_constant(iname, build);
	Hierarchy::make_available(Emit::tree(), iname);
	DISCARD_TEXT(build)
}

@ This also doesn't really belong here, but...

=
int FundamentalConstants::veto_number(int X) {
	if (((X > 32767) || (X < -32768)) &&
		(TargetVMs::is_16_bit(Task::vm()))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LiteralOverflow),
			"you use a number which is too large",
			"at least with the Settings for this project as they currently "
			"are. (Change to Glulx to be allowed to use much larger numbers.)");
		return TRUE;
	}
	return FALSE;
}
