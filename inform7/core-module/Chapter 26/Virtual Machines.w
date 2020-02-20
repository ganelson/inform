[VirtualMachines::] Virtual Machines.

I7 supports a variety of virtual machines as targets. Most source
text should be independent of the target VM, but sometimes numbering is
needed, and this is where any VM dependencies are decided.

@h Definitions.

@

@d MAX_USAGE_COLUMN_WIDTH 200

=
typedef struct VM_usage_note {
	struct wording structure_name; /* name of the structure using this array space... */
	struct text_stream *usage_explained; /* ...or an explanation instead */
	char *usage_category; /* e.g., "relation" */
	int bytes_used; /* number of bytes (not words) given over to this */
	int each_flag; /* is this a count of how many bytes per usage of something? */
	MEMORY_MANAGEMENT
} VM_usage_note;

@ At present, we infer the target virtual machine by looking at the file
extension requested at the command line.

=
target_vm *current_target_VM = NULL;

void VirtualMachines::set_identifier(text_stream *text, int debugging) {
	current_target_VM = TargetVMs::find(text, debugging);
}

int VirtualMachines::compatible_with(compatibility_specification *C) {
	return Compatibility::with(C, current_target_VM);
}

<current-virtual-machine> internal {
	if (<virtual-machine>(W)) {
		*X = VirtualMachines::compatible_with((compatibility_specification *) <<rp>>);
		return TRUE;
	} else {
		*X = FALSE;
		return FALSE;
	}
}

@ To help Inform detect overflows, it needs to know whether integers in the
target VM are 16 or 32 bits wide:

=
int VirtualMachines::is_16_bit(void) {
	return TargetVMs::is_16_bit(current_target_VM);
}

@ Using which:

=
int VirtualMachines::veto_number(int X) {
	if (((X > 32767) || (X < -32768)) && (TargetVMs::is_16_bit(current_target_VM))) {
		Problems::Issue::sentence_problem(_p_(PM_LiteralOverflow),
			"you use a number which is too large",
			"at least with the Settings for this project as they currently "
			"are. (Change to Glulx to be allowed to use much larger numbers.)");
		return TRUE;
	}
	return FALSE;
}

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
is a remote prospect for now: even megabyte story files are off the
horizon. Anyway, it's this comparison issue which means we need a different
value for each possible word size.

=
inter_name *VirtualMachines::emit_fundamental_constant(int id, inter_t val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant(iname, val);
	return iname;
}

inter_name *VirtualMachines::emit_signed_fundamental_constant(int id, int val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant_signed(iname, val);
	return iname;
}

inter_name *VirtualMachines::emit_hex_fundamental_constant(int id, inter_t val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_numeric_constant_hex(iname, val);
	return iname;
}

inter_name *VirtualMachines::emit_unchecked_hex_fundamental_constant(int id, inter_t val) {
	inter_name *iname = Hierarchy::find(id);
	Hierarchy::make_available(Emit::tree(), iname);
	Emit::named_unchecked_constant_hex(iname, val);
	return iname;
}

void VirtualMachines::emit_fundamental_constants(void) {
	if (current_target_VM == NULL) internal_error("target VM not set yet");

	if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile))
		VirtualMachines::emit_fundamental_constant(DEBUG_HL, 1);

	if (Str::eq(current_target_VM->family_name, I"Z-Machine")) {
		VirtualMachines::emit_fundamental_constant(TARGET_ZCODE_HL, 1);
		VirtualMachines::emit_fundamental_constant(DICT_WORD_SIZE_HL, 6);
	} else if (Str::eq(current_target_VM->family_name, I"Glulx")) {
		VirtualMachines::emit_fundamental_constant(TARGET_GLULX_HL, 1);
		VirtualMachines::emit_fundamental_constant(DICT_WORD_SIZE_HL, 9);
		VirtualMachines::emit_fundamental_constant(INDIV_PROP_START_HL, 0);
	}

	if (TargetVMs::is_16_bit(current_target_VM)) {
		VirtualMachines::emit_fundamental_constant(WORDSIZE_HL, 2);
		VirtualMachines::emit_unchecked_hex_fundamental_constant(NULL_HL, 0xffff);
		VirtualMachines::emit_hex_fundamental_constant(WORD_HIGHBIT_HL, 0x8000);
		VirtualMachines::emit_hex_fundamental_constant(WORD_NEXTTOHIGHBIT_HL, 0x4000);
		VirtualMachines::emit_hex_fundamental_constant(IMPROBABLE_VALUE_HL, 0x7fe3);
		VirtualMachines::emit_hex_fundamental_constant(REPARSE_CODE_HL, 10000);
		VirtualMachines::emit_fundamental_constant(MAX_POSITIVE_NUMBER_HL, 32767);
		VirtualMachines::emit_signed_fundamental_constant(MIN_NEGATIVE_NUMBER_HL, -32768);
	} else {
		VirtualMachines::emit_fundamental_constant(WORDSIZE_HL, 4);
		VirtualMachines::emit_unchecked_hex_fundamental_constant(NULL_HL, 0xffffffff);
		VirtualMachines::emit_hex_fundamental_constant(WORD_HIGHBIT_HL, 0x80000000);
		VirtualMachines::emit_hex_fundamental_constant(WORD_NEXTTOHIGHBIT_HL, 0x40000000);
		VirtualMachines::emit_hex_fundamental_constant(IMPROBABLE_VALUE_HL, 0xdeadce11);
		VirtualMachines::emit_hex_fundamental_constant(REPARSE_CODE_HL, 0x40000000);
		VirtualMachines::emit_fundamental_constant(MAX_POSITIVE_NUMBER_HL, 2147483647);
		VirtualMachines::emit_signed_fundamental_constant(MIN_NEGATIVE_NUMBER_HL, -2147483648);
	}
}

@ This version-numbering constant is not really to do with the VM (it is
Inform's own version number), but it belongs nowhere else either, so:

=
void VirtualMachines::compile_build_number(void) {
	TEMPORARY_TEXT(build);
	WRITE_TO(build, "%B", TRUE);
	inter_name *iname = Hierarchy::find(NI_BUILD_COUNT_HL);
	Emit::named_string_constant(iname, build);
	Hierarchy::make_available(Emit::tree(), iname);
	DISCARD_TEXT(build);
}

@ The limits are different on each platform. On Z, the maximum is fixed
at 15, but Glulx allows it to be set with an I6 memory setting.

=
int VirtualMachines::allow_this_many_locals(int N) {
	if (current_target_VM == NULL) internal_error("target VM not set yet");
	if ((current_target_VM->max_locals >= 0) &&
		(current_target_VM->max_locals < N)) return FALSE;
	return TRUE;
}
int VirtualMachines::allow_MAX_LOCAL_VARIABLES(void) {
	if (current_target_VM == NULL) internal_error("target VM not set yet");
	if (current_target_VM->max_locals > 15) return TRUE;
	return FALSE;
}

@ Real numbers are also a concern:

=
int VirtualMachines::supports(kind *K) {
	if (current_target_VM == NULL) internal_error("target VM not set yet");
	if ((Kinds::FloatingPoint::uses_floating_point(K)) &&
		(TargetVMs::supports_floating_point(current_target_VM) == FALSE)) return FALSE;
	return TRUE;
}

@ When releasing a blorbed story file, the file extension depends on the
story file wrapped inside. (This is a dubious idea, in the opinion of
the author of Inform -- should not blorb be one unified wrapper? -- but
interpreter writers disagree.)

=
text_stream *VirtualMachines::get_blorbed_extension(void) {
	if (current_target_VM == NULL) internal_error("target VM not set yet");
	return current_target_VM->VM_blorbed_extension;
}

@ Different VMs have different in-browser interpreters, which means that
Inblorb needs to be given different release instructions for them. If the
user doesn't specify any particular interpreter, he gets:

=
text_stream *VirtualMachines::get_default_interpreter(void) {
	if (current_target_VM == NULL) internal_error("target VM not set yet");
	return current_target_VM->default_browser_interpreter;
}

@h Icons for virtual machines.
And everything else is cosmetic: printing, or showing icons to signify,
the current VM or some set of permitted VMs. The following plots the
icon associated with a given minor VM, and explicates what the icons mean:

=
void VirtualMachines::plot_icon(OUTPUT_STREAM, target_vm *VM) {
	if (Str::len(VM->VM_image) > 0) {
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/%S", VM->VM_image);
		WRITE("&nbsp;");
	}
}

void VirtualMachines::write_key(OUTPUT_STREAM) {
	WRITE("Extensions compatible with specific story file formats only: ");
	int i = 0;
	target_vm *VM;
	LOOP_OVER(VM, target_vm) {
		if (VM->with_debugging_enabled) continue; /* avoids listing twice */
    	if (i++ > 0) WRITE(", ");
    	VirtualMachines::plot_icon(OUT, VM);
		TargetVMs::write(OUT, VM);
	}
}

@h Describing the current VM.

=
void VirtualMachines::index_innards(OUTPUT_STREAM) {
	VirtualMachines::write_current(OUT);
	UseOptions::index(OUT);
	HTML_OPEN("p");
	Index::extra_link(OUT, 3);
	WRITE("See some technicalities for Inform maintainers only");
	HTML_CLOSE("p");
	Index::extra_div_open(OUT, 3, 2, "e0e0e0");
	Plugins::Manage::show_configuration(OUT);
	@<Add some paste buttons for the debugging log@>;
	Index::extra_div_close(OUT, "e0e0e0");
}

@ The index provides some hidden paste icons for these:

@<Add some paste buttons for the debugging log@> =
	HTML_OPEN("p");
	WRITE("Debugging log:");
	HTML_CLOSE("p");
	HTML_OPEN("p");
	for (int i=0; i<NO_DEFINED_DA_VALUES; i++) {
		debugging_aspect *da = &(the_debugging_aspects[i]);
		if (Str::len(da->unhyphenated_name) > 0) {
			TEMPORARY_TEXT(is);
			WRITE_TO(is, "Include %S in the debugging log.", da->unhyphenated_name);
			HTML::Javascript::paste_stream(OUT, is);
			WRITE("&nbsp;%S", is);
			DISCARD_TEXT(is);
			HTML_TAG("br");
		}
	}
	HTML_CLOSE("p");

@ =
void VirtualMachines::write_current(OUTPUT_STREAM) {
	if (current_target_VM == NULL) internal_error("target VM not set yet");
	Index::anchor(OUT, I"STORYFILE");
	HTML_OPEN("p"); WRITE("Story file format: ");
	VirtualMachines::plot_icon(OUT, current_target_VM);
	TargetVMs::write(OUT, current_target_VM);
	HTML_CLOSE("p");
	if (TargetVMs::is_16_bit(current_target_VM)) {
		HTML_OPEN("p"); Index::extra_link(OUT, 1);
		WRITE("See estimates of memory usage");
		HTML_CLOSE("p");
		Index::extra_div_open(OUT, 1, 1, "e0e0e0");
		VirtualMachines::index_memory_usage(OUT);
		Index::extra_div_close(OUT, "e0e0e0");
	}
}

@h Displaying VM restrictions.
Given a word range, we describe the result as concisely as we can with a
row of icons (but do not bother for the common case where some extension
has no restriction on its use).

=
void VirtualMachines::write_icons(OUTPUT_STREAM, compatibility_specification *C) {
	int something = FALSE, everything = TRUE;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if (Compatibility::with(C, VM))
			something = TRUE;
		else
			everything = FALSE;
	if (something == FALSE) WRITE("none");
	if (everything == FALSE)
		LOOP_OVER(VM, target_vm)
			if (Compatibility::with(C, VM))
				VirtualMachines::plot_icon(OUT, VM);
}

@ The following table in the index (on the Contents page) may be useful to a
few diehard Z-machine hackers, determined to squeeze the maximum out of the
tiny array space available.

@d NOTEWORTHY_USAGE_THRESHOLD 50 /* don't mention arrays smaller than this, in bytes */

=
void VirtualMachines::note_usage(char *cat, wording W, text_stream *name, int words, int bytes, int each) {
	int b = bytes + words*((VirtualMachines::is_16_bit())?2:4);
	if ((each == FALSE) && (b < NOTEWORTHY_USAGE_THRESHOLD)) return;
	if (b == 0) return;
	VM_usage_note *VMun = CREATE(VM_usage_note);
	VMun->structure_name = W;
	VMun->usage_explained = Str::duplicate(name);
	VMun->usage_category = cat;
	VMun->bytes_used = b;
	VMun->each_flag = each;
}

@ The explanatory note here probably ought to use the words "approximately",
"incomplete" and so forth. It's really no better than a guide.

=
void VirtualMachines::index_memory_usage(OUTPUT_STREAM) {
	int nr = NUMBER_CREATED(VM_usage_note);
	VM_usage_note **sorted = Memory::I7_calloc(nr, sizeof(VM_usage_note *), INDEX_SORTING_MREASON);
	HTML_OPEN("p"); WRITE("In a Z-machine story file, array memory can be very limited. "
		"Switching to the Glulx setting removes all difficulty, but some authors "
		"like to squeeze the very most out of the Z-machine instead. This "
		"list shows about how much array space is used by some larger items "
		"the source text has chosen to create.");
	HTML_CLOSE("p");
	@<Sort the array usages@>;
	@<Tabulate the array usages@>;
	Memory::I7_array_free(sorted, INDEX_SORTING_MREASON, nr, sizeof(VM_usage_note *));
}

@ The rows in the table mention pathetically small numbers of bytes, of course,
by any rational measure.

@<Tabulate the array usages@> =
	HTML::begin_plain_html_table(OUT);
	int i;
	VM_usage_note *VMun;
	for (i=0; i<nr; i++) {
		VMun = sorted[i];
		HTML::first_html_column(OUT, 0);
		WRITE("%s", VMun->usage_category);
		HTML::next_html_column(OUT, 0);
		if (VMun->each_flag) WRITE("each ");
		if (Str::len(VMun->usage_explained) > 0)
			WRITE("%S", VMun->usage_explained);
		else if (Wordings::first_wn(VMun->structure_name) >= 0)
			WRITE("%W", VMun->structure_name);
		if (Wordings::first_wn(VMun->structure_name) >= 0)
			Index::link(OUT, Wordings::first_wn(VMun->structure_name));
		HTML::next_html_column(OUT, 0);
		WRITE("%d bytes", VMun->bytes_used);
		HTML::end_html_row(OUT);
	}
	HTML::end_html_table(OUT);

@ As usual, we sort with the C library's |qsort|.

@<Sort the array usages@> =
	int i = 0;
	VM_usage_note *VMun;
	LOOP_OVER(VMun, VM_usage_note) sorted[i++] = VMun;
	qsort(sorted, (size_t) nr, sizeof(VM_usage_note *), VirtualMachines::compare_usage);

@ The following means the table is sorted in decreasing order of bytes used,
with ties resolved by listing the first-declared item first.

=
int VirtualMachines::compare_usage(const void *ent1, const void *ent2) {
	const VM_usage_note *v1 = *((const VM_usage_note **) ent1);
	const VM_usage_note *v2 = *((const VM_usage_note **) ent2);
	if (v2->bytes_used != v1->bytes_used) return v2->bytes_used - v1->bytes_used;
	return Wordings::first_wn(v1->structure_name) - Wordings::first_wn(v2->structure_name);
}
