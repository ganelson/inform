[TargetVMs::] Target Virtual Machines.

To deal with multiple object code formats.

@h Object code.
The end result of compilation is traditionally called "object code" and
people tend to use words like "binary" or even "machine code" about it,
though in fact the world is more diverse nowadays. Inform 7 has always
generated "object code" which is itself a program for a virtual machine;
for example, it makes Glulx bytecode rather than x86 or ARM instructions.
Because of that, we use the customary term "virtual machine" for the format
of the end product of the Inform build process. But it doesn't have to be
virtual. If Inter-to-x86-via-C is properly implemented, we will probably
want to add a VM to represent something like "32-bit binary via ANSI C".

Each different target VM is represented by one of these objects:

=
typedef struct target_vm {
	struct text_stream *family_name; /* such as |Glulx| */
	int with_debugging_enabled;
	struct inter_architecture *architecture; /* such as 32d */
	struct semantic_version_number version; /* such as 0.8.7 */
	struct text_stream *VM_extension; /* canonical filename extension */
	struct text_stream *VM_unblorbed_extension; /* such as |z8| */
	struct text_stream *VM_blorbed_extension; /* when blorbed up */
	struct text_stream *VM_image; /* filename of image for icon denoting VM */
	int max_locals; /* upper limit on local variables per stack frame */
	struct text_stream *default_browser_interpreter; /* e.g., "Parchment" */
	struct text_stream *iFiction_format_name; /* e.g., "zcode": see the Treaty of Babel */
	struct text_stream *format_name; /* transpiler format, e.g., "Inform6" or "C" */
	struct linked_list *format_options; /* of |text_stream| */
	int supports_floating_point;
	CLASS_DEFINITION
} target_vm;

@ =
target_vm *TargetVMs::new(text_stream *code, text_stream *nick, semantic_version_number V,
	text_stream *image, text_stream *interpreter, text_stream *blorbed, inter_architecture *arch,
	int debug, int max_locals, text_stream *iFiction, text_stream *format) {
	target_vm *VM = CREATE(target_vm);
	VM->family_name = Str::duplicate(code);
	VM->version = V;
	VM->VM_extension = Str::duplicate(nick);
	VM->VM_unblorbed_extension = Str::duplicate(nick);
	VM->VM_blorbed_extension = Str::duplicate(blorbed);
	VM->VM_image = Str::duplicate(image);
	VM->max_locals = max_locals;
	VM->default_browser_interpreter = Str::duplicate(interpreter);
	VM->architecture = arch;
	if (VM->architecture == NULL) internal_error("no such architecture");
	VM->with_debugging_enabled = debug;
	VM->supports_floating_point = TRUE;
	if (Architectures::is_16_bit(VM->architecture)) VM->supports_floating_point = FALSE;
	VM->iFiction_format_name = Str::duplicate(iFiction);
	VM->format_name = Str::duplicate(format);
	VM->format_options = NEW_LINKED_LIST(text_stream);
	return VM;
}

@h Standard set.
This is called when the //arch// module starts up; no other architectures
are ever made.

=
void TargetVMs::create(void) {
	/* hat tip: Joel Berez and Marc Blank, 1979, and later hands */
	TargetVMs::new(I"Z-Machine", I"z5", VersionNumbers::from_text(I"5"),
		I"vm_z5.png", I"Parchment", I"zblorb", Architectures::from_codename(I"16"), FALSE, 15, I"zcode", I"Inform6");
	TargetVMs::new(I"Z-Machine", I"z5", VersionNumbers::from_text(I"5"),
		I"vm_z5.png", I"Parchment", I"zblorb", Architectures::from_codename(I"16d"), TRUE, 15, I"zcode", I"Inform6");

	TargetVMs::new(I"Z-Machine", I"z8", VersionNumbers::from_text(I"8"),
		I"vm_z8.png", I"Parchment", I"zblorb", Architectures::from_codename(I"16"), FALSE, 15, I"zcode", I"Inform6");
	TargetVMs::new(I"Z-Machine", I"z8", VersionNumbers::from_text(I"8"),
		I"vm_z8.png", I"Parchment", I"zblorb", Architectures::from_codename(I"16d"), TRUE, 15, I"zcode", I"Inform6");

	/* hat tip: Andrew Plotkin, 2000 */
	TargetVMs::new(I"Glulx", I"ulx", VersionNumbers::from_text(I"3.1.2"),
		I"vm_glulx.png", I"Quixe", I"gblorb", Architectures::from_codename(I"32"), FALSE, 256, I"glulx", I"Inform6");
	TargetVMs::new(I"Glulx", I"ulx", VersionNumbers::from_text(I"3.1.2"),
		I"vm_glulx.png", I"Quixe", I"gblorb", Architectures::from_codename(I"32d"), TRUE, 256, I"glulx", I"Inform6");

	TargetVMs::new(I"C", I"c", VersionNumbers::from_text(I"1"),
		I"vm_glulx.png", I"", I"", Architectures::from_codename(I"32"), FALSE, 256, I"inform7-c", I"C");
	TargetVMs::new(I"C", I"c", VersionNumbers::from_text(I"1"),
		I"vm_glulx.png", I"", I"", Architectures::from_codename(I"32d"), TRUE, 256, I"inform7-c", I"C");
}

@h Describing and finding.
This is the longhand form of the VM name:

=
void TargetVMs::write(OUTPUT_STREAM, target_vm *VM) {
	if (VM == NULL) WRITE("none");
	else {
		WRITE("%S", VM->family_name);
		semantic_version_number V = VM->version;
		if (VersionNumbers::is_null(V) == FALSE) WRITE(" version %v", &V);	
		if (VM->with_debugging_enabled) WRITE(" with debugging");
	}
}

@ Here we deduce a VM from the given filename extension, which is the rather
clumsy way that VMs are referred to on the //inform7// command line. For
example, |ulx| produces one of the Glulx VMs.

=
target_vm *TargetVMs::find_by_extension(text_stream *ext, int debug) {
	target_vm *result = NULL;
	if (Str::len(ext) == 0) ext = I"ulx";
	TEMPORARY_TEXT(file_extension)
	Str::copy(file_extension, ext);
	if (Str::get_first_char(file_extension) == '.')
		Str::delete_first_character(file_extension);
	LOOP_THROUGH_TEXT(pos, file_extension)
		Str::put(pos, Characters::tolower(Str::get(pos)));
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->VM_unblorbed_extension, ext)) &&
			(VM->with_debugging_enabled == debug))
			result = VM;
	DISCARD_TEXT(file_extension)
	return result;
}

@ A somewhat sharper method finds specific versions: for example, it can pick
out version 5 rather than version 8 of the Z-machine. Note that the version
numbers must match exactly, and not simply be compatible according to semver
rules.

=
target_vm *TargetVMs::find_in_family(text_stream *family, semantic_version_number V,
	int debug) {
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->family_name, family)) &&
			(VersionNumbers::eq(VM->version, V)) &&
			((debug == NOT_APPLICABLE) || (debug == VM->with_debugging_enabled)))
			return VM;
	return NULL;
}

@ And a device for discovering (or making) a target VM given a more general
format,

=
target_vm *TargetVMs::find(text_stream *format, int debug) {
	text_stream *wanted = NULL;
	inter_architecture *wanted_arch = NULL;
	linked_list *segs = NEW_LINKED_LIST(text_stream);
	TEMPORARY_TEXT(segment)
	LOOP_THROUGH_TEXT(pos, format) {
		if (Str::get(pos) == '/') {
			if (Str::len(segment) > 0) @<Accept segment@>;
			Str::clear(segment);
		}
	}
	if (Str::len(segment) > 0) @<Accept segment@>
	DISCARD_TEXT(segment)
	target_vm *result = NULL;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->format_name, wanted)) &&
			((wanted_arch == NULL) || (VM->architecture == wanted_arch)) &&
			(VM->with_debugging_enabled == debug) &&
			(TargetVMs::options_match(VM, segs)))
			result = VM;
	if (result) return result;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->format_name, wanted)) &&
			((wanted_arch == NULL) || (VM->architecture == wanted_arch)) &&
			(VM->with_debugging_enabled == debug))
			result = VM;
	if (result) {
		target_vm *new_VM = TargetVMs::new(result->family_name, result->VM_extension, result->version,
			result->VM_image, result->default_browser_interpreter, result->VM_blorbed_extension, result->architecture,
			result->with_debugging_enabled, result->max_locals, result->iFiction_format_name, result->format_name);
		new_VM->format_options = segs;
		return new_VM;
	}
	result = TargetVMs::find_by_extension(format, debug);
	if (result) {
		WRITE_TO(STDOUT, "(warning: that use of -format is deprecated: try -format=%S/%S instead)\n",
			result->format_name, Architectures::to_codename(result->architecture));
	}
	return result;
}

@<Accept segment@> =
	if (wanted == NULL) wanted = Str::duplicate(segment);
	else {
		inter_architecture *arch = Architectures::from_codename(segment);
		if (arch) wanted_arch = arch;
		else {
			ADD_TO_LINKED_LIST(Str::duplicate(segment), text_stream, segs);
		}
	}

@

=
int TargetVMs::options_match(target_vm *VM, linked_list *supplied) {
	if ((TargetVMs::ll_of_text_is_subset(supplied, VM->format_options)) &&
		(TargetVMs::ll_of_text_is_subset(VM->format_options, supplied)))
		return TRUE;
	return FALSE;
}

int TargetVMs::ll_of_text_is_subset(linked_list *A, linked_list *B) {
	text_stream *opt;
	LOOP_OVER_LINKED_LIST(opt, text_stream, A) {
		int found = FALSE;
		text_stream *opt2;
		LOOP_OVER_LINKED_LIST(opt2, text_stream, B) {
			if (Str::eq(opt, opt2)) found = TRUE;
		}
		if (found == FALSE) return FALSE;
	}
	return TRUE;
}

@h Miscellaneous provisions.

=
int TargetVMs::is_16_bit(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return Architectures::is_16_bit(VM->architecture);
}
int TargetVMs::debug_enabled(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return Architectures::debug_enabled(VM->architecture);
}
int TargetVMs::supports_floating_point(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->supports_floating_point;
}

@ The limits on local variables per routine are different on each platform.
On Z, the maximum is fixed at 15, but Glulx allows it to be set with an I6
memory setting.

=
int TargetVMs::allow_this_many_locals(target_vm *VM, int N) {
	if (VM == NULL) internal_error("no VM");
	if ((VM->max_locals >= 0) && (VM->max_locals < N)) return FALSE;
	return TRUE;
}
int TargetVMs::allow_MAX_LOCAL_VARIABLES(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	if (VM->max_locals > 15) return TRUE;
	return FALSE;
}

@ When releasing a blorbed story file, the file extension depends on the
story file wrapped inside. (This is a dubious idea, in the opinion of
the author of Inform -- should not "blorb" be one unified wrapper? -- but
that ship seems to have sailed.)

=
text_stream *TargetVMs::get_unblorbed_extension(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->VM_unblorbed_extension;
}

text_stream *TargetVMs::get_blorbed_extension(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->VM_blorbed_extension;
}

@ This is the format name as expressed in an iFiction bibliographic record,
where it's not meaningful to talk about debugging features or the number
of bits, and where it's currently not possible to express a VM version number.

=
text_stream *TargetVMs::get_iFiction_format(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->iFiction_format_name;
}

inter_architecture *TargetVMs::get_architecture(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->architecture;
}

@ Different VMs have different in-browser interpreters, which means that
Inblorb needs to be given different release instructions for them. If the
user doesn't specify any particular interpreter, she gets:

=
text_stream *TargetVMs::get_default_interpreter(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->default_browser_interpreter;
}
