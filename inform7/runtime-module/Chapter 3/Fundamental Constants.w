[FundamentalConstants::] Fundamental Constants.

Inter constants for, say, extremal number values, which depend on the
target we are compiling to, and are generally low-level in nature.

@ =
void FundamentalConstants::emit(void) {
	@<Version number constant@>;
	@<Semantic version number constant@>;

	target_vm *VM = Task::vm();
	if (VM == NULL) internal_error("target VM not set yet");

	if (TargetVMs::debug_enabled(VM)) FundamentalConstants::emit_one(DEBUG_HL, 1);

	@<Special constants for Z-machine and Glulx VMs@>;
	if (TargetVMs::is_16_bit(VM)) @<16-bit constants@>
	else @<32-bit constants@>;
}

@ So, for example, these might be |10.1.0| and |10.1.0-alpha.1+6R84| respectively.

@<Version number constant@> =
	TEMPORARY_TEXT(vn)
	WRITE_TO(vn, "[[Version Number]]");
	inter_name *iname = Hierarchy::find(I7_VERSION_NUMBER_HL);
	Emit::text_constant(iname, vn);
	Hierarchy::make_available(iname);
	DISCARD_TEXT(vn)

@<Semantic version number constant@> =
	TEMPORARY_TEXT(svn)
	WRITE_TO(svn, "[[Semantic Version Number]]");
	inter_name *iname = Hierarchy::find(I7_FULL_VERSION_NUMBER_HL);
	Emit::text_constant(iname, svn);
	Hierarchy::make_available(iname);
	DISCARD_TEXT(svn)

@ These constants may be predefined in the veneer of the Inform 6 compiler,
if that is being used further down the compilation chain, but we want to define
them here regardless of that: and then linking can work properly, and the code
will make sense even if I6 is not the final code-generator.

@<Special constants for Z-machine and Glulx VMs@> =
	if (Str::eq(VM->family_name, I"Z-Machine")) {
		FundamentalConstants::emit_one(TARGET_ZCODE_HL,     1);
		FundamentalConstants::emit_one(DICT_WORD_SIZE_HL,   6);
	}
	if (Str::eq(VM->family_name, I"Glulx")) {
		FundamentalConstants::emit_one(TARGET_GLULX_HL,     1);
		FundamentalConstants::emit_one(DICT_WORD_SIZE_HL,   9);
		FundamentalConstants::emit_one(INDIV_PROP_START_HL, 0);
	}

@ These constants mostly have obvious meanings, but a few notes:

(1) |NULL|, in our runtime, is -1, and not 0 as it would be in C. This is
emitted as "unchecked" to avoid the value being rejected as being too large,
as it would be if it were viewed as a signed rather than unsigned integer.

(2) |IMPROBABLE_VALUE| is one which is unlikely even if possible to be a
genuine I7 value. The efficiency of runtime code handling tables depends on
how well chosen this is: it would ran badly if we chose 1, for instance.

(3) |REPARSE_CODE| is a magic value used in //CommandParserKit// to
signal that some code which ought to have been parsing a command has in
fact rewritten it, so that the whole command must be re-parsed afresh.
That doesn't sound very "fundamental", but in fact it depends on the word
size, because it needs to be a large number but also such that an address
in the VM can be added to it without it becoming negative.

@<16-bit constants@> =
	FundamentalConstants::emit_one(WORDSIZE_HL,                         2);
	FundamentalConstants::emit_unchecked_hex(NULL_HL,              0xffff);
	FundamentalConstants::emit_hex(WORD_HIGHBIT_HL,                0x8000);
	FundamentalConstants::emit_hex(WORD_NEXTTOHIGHBIT_HL,          0x4000);
	FundamentalConstants::emit_hex(IMPROBABLE_VALUE_HL,            0x7fe3);
	FundamentalConstants::emit_hex(REPARSE_CODE_HL,                 10000);
	FundamentalConstants::emit_one(MAX_POSITIVE_NUMBER_HL,          32767);
	FundamentalConstants::emit_signed(MIN_NEGATIVE_NUMBER_HL,      -32768);

@<32-bit constants@> =
	FundamentalConstants::emit_one(WORDSIZE_HL,                         4);
	FundamentalConstants::emit_unchecked_hex(NULL_HL,          0xffffffff);
	FundamentalConstants::emit_hex(WORD_HIGHBIT_HL,            0x80000000);
	FundamentalConstants::emit_hex(WORD_NEXTTOHIGHBIT_HL,      0x40000000);
	FundamentalConstants::emit_hex(IMPROBABLE_VALUE_HL,        0xdeadce11);
	FundamentalConstants::emit_hex(REPARSE_CODE_HL,            0x40000000);
	FundamentalConstants::emit_one(MAX_POSITIVE_NUMBER_HL,     2147483647);
	FundamentalConstants::emit_signed(MIN_NEGATIVE_NUMBER_HL, -2147483648);

@ Note that all of these constants are made available for linking:

=
void FundamentalConstants::emit_one(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(iname);
	Emit::numeric_constant(iname, val);
}
void FundamentalConstants::emit_signed(int id, int val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(iname);
	Emit::named_numeric_constant_signed(iname, val);
}
void FundamentalConstants::emit_hex(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(iname);
	Emit::named_numeric_constant_hex(iname, val);
}
void FundamentalConstants::emit_unchecked_hex(int id, inter_ti val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(iname);
	Emit::named_unchecked_constant_hex(iname, val);
}
