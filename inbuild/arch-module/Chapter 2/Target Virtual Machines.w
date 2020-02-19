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
	int supports_floating_point;
	MEMORY_MANAGEMENT
} target_vm;

target_vm *TargetVMs::new(text_stream *code, text_stream *nick, semantic_version_number V,
	text_stream *image, text_stream *interpreter, text_stream *blorbed, text_stream *arch, int debug) {
	target_vm *VM = CREATE(target_vm);
	VM->family_name = Str::duplicate(code);
	VM->version = V;
	VM->VM_extension = Str::duplicate(nick);
	VM->VM_unblorbed_extension = Str::duplicate(nick);
	VM->VM_blorbed_extension = Str::duplicate(blorbed);
	VM->VM_image = Str::duplicate(image);
	VM->max_locals = 15;
	VM->default_browser_interpreter = Str::duplicate(interpreter);
	VM->architecture = Architectures::from_codename(arch);
	if (VM->architecture == NULL) internal_error("no such architecture");
	VM->with_debugging_enabled = debug;
	VM->supports_floating_point = TRUE;
	if (Architectures::is_16_bit(VM->architecture)) VM->supports_floating_point = FALSE;
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
		I"vm_z5.png", I"Parchment", I"zblorb", I"16", FALSE);
	TargetVMs::new(I"Z-Machine", I"z5", VersionNumbers::from_text(I"5"),
		I"vm_z5.png", I"Parchment", I"zblorb", I"16d", TRUE);

	TargetVMs::new(I"Z-Machine", I"z8", VersionNumbers::from_text(I"8"),
		I"vm_z8.png", I"Parchment", I"zblorb", I"16", FALSE);
	TargetVMs::new(I"Z-Machine", I"z8", VersionNumbers::from_text(I"8"),
		I"vm_z8.png", I"Parchment", I"zblorb", I"16d", TRUE);

	/* hat tip: Andrew Plotkin, 2000 */
	TargetVMs::new(I"Glulx", I"ulx", VersionNumbers::from_text(I"3.1.2"),
		I"vm_glulx.png", I"Quixe", I"gblorb", I"32", FALSE);
	TargetVMs::new(I"Glulx", I"ulx", VersionNumbers::from_text(I"3.1.2"),
		I"vm_glulx.png", I"Quixe", I"gblorb", I"32d", TRUE);
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
