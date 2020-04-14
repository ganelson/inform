[TargetVMs::] Target Virtual Machines.

To deal with multiple inter architectures.

@h Architectures.

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
	int supports_floating_point;
	MEMORY_MANAGEMENT
} target_vm;

target_vm *TargetVMs::new(text_stream *code, text_stream *nick, semantic_version_number V,
	text_stream *image, text_stream *interpreter, text_stream *blorbed, text_stream *arch,
	int debug, int max_locals, text_stream *iFiction) {
	target_vm *VM = CREATE(target_vm);
	VM->family_name = Str::duplicate(code);
	VM->version = V;
	VM->VM_extension = Str::duplicate(nick);
	VM->VM_unblorbed_extension = Str::duplicate(nick);
	VM->VM_blorbed_extension = Str::duplicate(blorbed);
	VM->VM_image = Str::duplicate(image);
	VM->max_locals = max_locals;
	VM->default_browser_interpreter = Str::duplicate(interpreter);
	VM->architecture = Architectures::from_codename(arch);
	if (VM->architecture == NULL) internal_error("no such architecture");
	VM->with_debugging_enabled = debug;
	VM->supports_floating_point = TRUE;
	if (Architectures::is_16_bit(VM->architecture)) VM->supports_floating_point = FALSE;
	VM->iFiction_format_name = Str::duplicate(iFiction);
	return VM;
}

void TargetVMs::write(OUTPUT_STREAM, target_vm *VM) {
	if (VM == NULL) WRITE("none");
	else {
		WRITE("%S", VM->family_name);
		semantic_version_number V = VM->version;
		if (VersionNumbers::is_null(V) == FALSE) WRITE(" version %v", &V);	
		if (VM->with_debugging_enabled) WRITE(" with debugging");
	}
}

void TargetVMs::create(void) {
	/* hat tip: Joel Berez and Marc Blank, 1979, and later hands */
	TargetVMs::new(I"Z-Machine", I"z5", VersionNumbers::from_text(I"5"),
		I"vm_z5.png", I"Parchment", I"zblorb", I"16", FALSE, 15, I"zcode");
	TargetVMs::new(I"Z-Machine", I"z5", VersionNumbers::from_text(I"5"),
		I"vm_z5.png", I"Parchment", I"zblorb", I"16d", TRUE, 15, I"zcode");

	TargetVMs::new(I"Z-Machine", I"z8", VersionNumbers::from_text(I"8"),
		I"vm_z8.png", I"Parchment", I"zblorb", I"16", FALSE, 15, I"zcode");
	TargetVMs::new(I"Z-Machine", I"z8", VersionNumbers::from_text(I"8"),
		I"vm_z8.png", I"Parchment", I"zblorb", I"16d", TRUE, 15, I"zcode");

	/* hat tip: Andrew Plotkin, 2000 */
	TargetVMs::new(I"Glulx", I"ulx", VersionNumbers::from_text(I"3.1.2"),
		I"vm_glulx.png", I"Quixe", I"gblorb", I"32", FALSE, 256, I"glulx");
	TargetVMs::new(I"Glulx", I"ulx", VersionNumbers::from_text(I"3.1.2"),
		I"vm_glulx.png", I"Quixe", I"gblorb", I"32d", TRUE, 256, I"glulx");
}

target_vm *TargetVMs::find(text_stream *ext, int debug) {
	target_vm *result = NULL;
	if (Str::len(ext) == 0) ext = I"ulx";
	TEMPORARY_TEXT(file_extension);
	Str::copy(file_extension, ext);
	if (Str::get_first_char(file_extension) == '.') Str::delete_first_character(file_extension);
	LOOP_THROUGH_TEXT(pos, file_extension)
		Str::put(pos, Characters::tolower(Str::get(pos)));
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->VM_unblorbed_extension, ext)) &&
			(VM->with_debugging_enabled == debug))
			result = VM;
	DISCARD_TEXT(file_extension);
	return result;
}

target_vm *TargetVMs::find_in_family(text_stream *family, semantic_version_number V, int debug) {
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->family_name, family)) &&
			(VersionNumbers::eq(VM->version, V)) &&
			((debug == NOT_APPLICABLE) || (debug == VM->with_debugging_enabled)))
			return VM;
	return NULL;
}

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

@ The limits are different on each platform. On Z, the maximum is fixed
at 15, but Glulx allows it to be set with an I6 memory setting.

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
the author of Inform -- should not blorb be one unified wrapper? -- but
interpreter writers disagree.)

=
text_stream *TargetVMs::get_unblorbed_extension(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->VM_unblorbed_extension;
}

text_stream *TargetVMs::get_blorbed_extension(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->VM_blorbed_extension;
}

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
user doesn't specify any particular interpreter, he gets:

=
text_stream *TargetVMs::get_default_interpreter(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->default_browser_interpreter;
}
