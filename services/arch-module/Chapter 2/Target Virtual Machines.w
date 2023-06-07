[TargetVMs::] Target Virtual Machines.

To deal with multiple object code formats.

@h Target VMs.
For a fuller explanation of these, see //What This Module Does//, but briefly:
a //target_vm// object represents a choice of both Inter architecture and
also a format for final code-generation from Inter. For example, it might
represent "16-bit with debugging enabled to be generated to Inform 6 code",
or, say, "32-bit to be generated to ANSI C code".

The basic set of possible target VMs is made when the //arch// module starts up:

=
void TargetVMs::create(void) {
	/* hat tip: Joel Berez and Marc Blank, 1979, and later hands */
	TargetVMs::new(Architectures::from_codename(I"16"), I"Inform6",
		VersionNumbers::from_text(I"5"), I"i6", I"z5", I"zblorb", I"Parchment", NULL);
	TargetVMs::new(Architectures::from_codename(I"16d"), I"Inform6",
		VersionNumbers::from_text(I"5"), I"i6", I"z5", I"zblorb", I"Parchment", NULL);

	TargetVMs::new(Architectures::from_codename(I"16"), I"Inform6",
		VersionNumbers::from_text(I"8"), I"i6", I"z8", I"zblorb", I"Parchment", NULL);
	TargetVMs::new(Architectures::from_codename(I"16d"), I"Inform6",
		VersionNumbers::from_text(I"8"), I"i6", I"z8", I"zblorb", I"Parchment", NULL);

	/* hat tip: Andrew Plotkin, 2000 */
	TargetVMs::new(Architectures::from_codename(I"32"), I"Inform6",
		VersionNumbers::from_text(I"3.1.2"), I"i6", I"ulx", I"gblorb", I"Quixe", NULL);
	TargetVMs::new(Architectures::from_codename(I"32d"), I"Inform6",
		VersionNumbers::from_text(I"3.1.2"), I"i6", I"ulx", I"gblorb", I"Quixe", NULL);

	/* hat tip: modesty forbids */
	TargetVMs::new(Architectures::from_codename(I"16"), I"Binary",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"16d"), I"Binary",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"32"), I"Binary",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"32d"), I"Binary",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);

	TargetVMs::new(Architectures::from_codename(I"16"), I"Text",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"16d"), I"Text",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"32"), I"Text",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"32d"), I"Text",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);

	/* C support added September 2021 */
	TargetVMs::new(Architectures::from_codename(I"32"), I"C",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"32d"), I"C",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);

	/* Inventory support added March 2022 */
	TargetVMs::new(Architectures::from_codename(I"16"), I"Inventory",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"16d"), I"Inventory",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"32"), I"Inventory",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
	TargetVMs::new(Architectures::from_codename(I"32d"), I"Inventory",
		VersionNumbers::from_text(I"1"), I"c", I"", I"", I"", NULL);
}

@ The //target_vm// structure contains two arguably architectural doohickies:
potential limits on the use of floating-point arithmetic or on local variables.
These are indeed currently derived only from the choice of |architecture|, but
we're keeping them here in case there is some day a need for a 32-bit format
with integer-only arithmetic, say.

=
typedef struct target_vm {
	struct inter_architecture *architecture; /* such as 32d */
	struct semantic_version_number version; /* such as 0.8.7 */
	struct text_stream *transpiled_extension; /* such as |i6| */
	struct text_stream *VM_unblorbed_extension; /* such as |z8| */
	struct text_stream *VM_blorbed_extension; /* when blorbed up */
	struct text_stream *VM_image; /* filename of image for icon used in the index */
	struct text_stream *default_browser_interpreter; /* e.g., "Parchment" */
	struct text_stream *iFiction_format_name; /* e.g., "zcode": see the Treaty of Babel */
	struct text_stream *transpiler_family; /* transpiler format, e.g., "Inform6" or "C" */
	struct text_stream *full_format; /* e.g., "Inform6/32d/v3.1.2" */
	int supports_floating_point;
	int max_locals; /* upper limit on local variables per stack frame */
	struct linked_list *format_options; /* of |text_stream| */
	CLASS_DEFINITION
} target_vm;

@ =
target_vm *TargetVMs::new(inter_architecture *arch, text_stream *format,
	semantic_version_number V, text_stream *trans, text_stream *unblorbed,
	text_stream *blorbed, text_stream *interpreter, linked_list *opts) {
	target_vm *VM = CREATE(target_vm);
	VM->version = V;
	VM->transpiled_extension = Str::duplicate(trans);
	VM->VM_unblorbed_extension = Str::duplicate(unblorbed);
	VM->VM_blorbed_extension = Str::duplicate(blorbed);
	VM->default_browser_interpreter = Str::duplicate(interpreter);
	VM->architecture = arch;
	if (VM->architecture == NULL) internal_error("no such architecture");
	if (Architectures::is_16_bit(VM->architecture)) {
		VM->supports_floating_point = FALSE;
		VM->max_locals = 15;
		VM->VM_image = I"vm_z8.png";
	} else {
		VM->supports_floating_point = TRUE;
		VM->max_locals = 256;
		VM->VM_image = I"vm_glulx.png";
	}
	VM->iFiction_format_name = Str::new();
	if (Str::eq(format, I"Inform6")) {
		if (Architectures::is_16_bit(VM->architecture)) {
			VM->iFiction_format_name = I"zcode";
		} else {
			VM->iFiction_format_name = I"glulx";
		}
	} else {
		WRITE_TO(VM->iFiction_format_name, "Inform+%S", format);
	}
	VM->transpiler_family = Str::duplicate(format);
	VM->format_options = NEW_LINKED_LIST(text_stream);
	VM->full_format = Str::new();
	WRITE_TO(VM->full_format, "%S/%S/v%v",
		VM->transpiler_family, Architectures::to_codename(VM->architecture), &V);
	if (opts) {
		text_stream *opt;
		LOOP_OVER_LINKED_LIST(opt, text_stream, opts) {
			WRITE_TO(VM->full_format, "/%S", opt);
			ADD_TO_LINKED_LIST(opt, text_stream, VM->format_options);
		}
	}
	return VM;
}

@ Plumbing is included here to add "options" to a VM's textual description. The
idea is that these allow for the user to specify additional and VM-specific
command-line options (using |-format|) which are then picked up by //final//.
Thus, a request for |-format=C/32d/no-halt/stack=240| would cause a new variant of
|C/32d| to be created which would have the (purely hypothetical) list of
options |I"no-halt", I"stack=240"|. It is then up to the C final code generator
to understand what these mean, if indeed they mean anything.

=
target_vm *TargetVMs::new_variant(target_vm *existing, linked_list *opts) {
	return TargetVMs::new(existing->architecture, existing->transpiler_family,
		existing->version, existing->transpiled_extension, existing->VM_unblorbed_extension,
		existing->VM_blorbed_extension, existing->default_browser_interpreter, opts);
}

@h To and from text.
First, writing. This is the longhand form of the VM name:

=
void TargetVMs::write(OUTPUT_STREAM, target_vm *VM) {
	if (VM == NULL) WRITE("none");
	else WRITE("%S", VM->full_format);
}

text_stream *TargetVMs::get_full_format_text(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->full_format;
}

@ And now for reading. The following is used by //inbuild// when reading the
command-line option |-format=T|: the text |T| is supplied as a parameter here.

Note however that it actually calls //TargetVMs::find_with_hint//. The |debug|
hint, if set, says to make the architecture have debugging enabled or not according
to this hint: thus |"C"| plus the hint |FALSE| will return the VM |C/32|, while
|"C"| plus the hint |TRUE| will return the VM |C/32d|. The hint |NOT_APPLICABLE|
is ignored; and the hint is also ignored if the supplied text already definitely
specifies debugging. Thus |"C/32d"| plus hint |FALSE| will return |C/32d|.

=
target_vm *TargetVMs::find(text_stream *format) {
	return TargetVMs::find_with_hint(format, NOT_APPLICABLE); /* i.e., no hint */
}

target_vm *TargetVMs::find_with_hint(text_stream *format, int debug) {
	if (Str::len(format) == 0) format = I"Inform6";
	text_stream *wanted_language = NULL;
	inter_architecture *wanted_arch = NULL;
	semantic_version_number wanted_version = VersionNumbers::null();
	linked_list *wanted_opts = NEW_LINKED_LIST(text_stream);
	@<Parse the text supplied into these variables@>;
	if ((wanted_arch) && (Architectures::debug_enabled(wanted_arch))) debug = TRUE;
	@<Try to find a VM which is a perfect match@>;
	@<Try to find a VM which would be a match except for the options@>;
	@<Try to find a VM in the now-deprecated old notation@>;
	return NULL;
}

@ Format text is a list of criteria divided by slashes:

@<Parse the text supplied into these variables@> =
	TEMPORARY_TEXT(criterion)
	LOOP_THROUGH_TEXT(pos, format) {
		if (Str::get(pos) == '/') {
			if (Str::len(criterion) > 0) @<Accept criterion@>;
			Str::clear(criterion);
		} else {
			PUT_TO(criterion, Str::get(pos));
		}
	}
	if (Str::len(criterion) > 0) @<Accept criterion@>;
	DISCARD_TEXT(criterion)

@ The first criterion is the only compulsory one, and must be something like
|Inform6| or |C|. After that, any criterion in the form of an architecture code,
like |32d|, is interpreted as such; and any criterion opening with |v| plus a
digit is read as a semantic version number. If any criteria are left after all
that, they are considered options (see above).

@<Accept criterion@> =
	if (wanted_language == NULL) wanted_language = Str::duplicate(criterion);
	else {
		inter_architecture *arch = Architectures::from_codename_with_hint(criterion, debug);
		if (arch) wanted_arch = arch;
		else {
			if (((Str::get_at(criterion, 0) == 'v') || (Str::get_at(criterion, 0) == 'V')) &&
				(Characters::isdigit(Str::get_at(criterion, 1)))) {
				Str::delete_first_character(criterion);
				wanted_version = VersionNumbers::from_text(criterion);
			} else {
				ADD_TO_LINKED_LIST(Str::duplicate(criterion), text_stream, wanted_opts);
			}
		}
	}

@<Try to find a VM which is a perfect match@> =
	target_vm *result = NULL;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->transpiler_family, wanted_language)) &&
			((wanted_arch == NULL) || (VM->architecture == wanted_arch)) &&
			((debug == NOT_APPLICABLE) || (TargetVMs::debug_enabled(VM) == debug)) &&
			(TargetVMs::versions_match(VM, wanted_version)) &&
			(TargetVMs::options_match(VM, wanted_opts)))
			result = VM;
	if (result) return result;

@ If we're given, say, |C/32d/no-pointer-nonsense| and we can't find that exact
thing, but can find |C/32d|, then we construct a variant of it which does have
the option |no-pointer-nonsense| and return that.

@<Try to find a VM which would be a match except for the options@> =
	target_vm *result = NULL;
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->transpiler_family, wanted_language)) &&
			((wanted_arch == NULL) || (VM->architecture == wanted_arch)) &&
			((debug == NOT_APPLICABLE) || (TargetVMs::debug_enabled(VM) == debug)) &&
			(TargetVMs::versions_match(VM, wanted_version)))
			result = VM;
	if (result) return TargetVMs::new_variant(result, wanted_opts);

@ If we get here, we've failed to make any match using the modern notation.

So next we try to deduce a VM from the given filename extension, which is the
clumsy way that VMs used to be referred to on the //inform7// command line. For
example, |-format=ulx| produces |Inform6/32| or |Inform6/32d| (depending on
the |debug| hint).

=
@<Try to find a VM in the now-deprecated old notation@> =
	target_vm *result = NULL;
	TEMPORARY_TEXT(file_extension)
	Str::copy(file_extension, format);
	if (Str::get_first_char(file_extension) == '.')
		Str::delete_first_character(file_extension);
	LOOP_THROUGH_TEXT(pos, file_extension)
		Str::put(pos, Characters::tolower(Str::get(pos)));
	target_vm *VM;
	LOOP_OVER(VM, target_vm)
		if ((Str::eq_insensitive(VM->VM_unblorbed_extension, file_extension)) &&
			(TargetVMs::debug_enabled(VM) == debug))
			result = VM;
	DISCARD_TEXT(file_extension)
	if (result) {
		WRITE_TO(STDOUT, "(-format=%S is deprecated: try -format=%S/%S instead)\n",
			format, result->transpiler_family,
			Architectures::to_codename(result->architecture));
		return result;
	}

@ Semantic version rules apply if the user supplies a format text with a given
version requirement. If the user asks for |v3.1.0| and we've got |v3.1.2|,
no problem: there's a match. But |v2.9.3| or |3.2.1| would not match.

=
int TargetVMs::versions_match(target_vm *VM, semantic_version_number wanted) {
	if (VersionNumbers::is_null(wanted)) return TRUE;
	if (VersionNumberRanges::in_range(VM->version,
		VersionNumberRanges::compatibility_range(wanted))) return TRUE;
	return FALSE;
}

@ That just leaves how to tell whether or not a VM has exactly the right options,
given that (a) there can be any number of them, including 0, and (b) they can
be specified in any order. Speed is unimportant here: in effect we test whether
two lists of options give rise to sets which are subsets of each other.

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

@h Architectural provisions.

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

int TargetVMs::allow_this_many_locals(target_vm *VM, int N) {
	if (VM == NULL) internal_error("no VM");
	if ((VM->max_locals >= 0) && (VM->max_locals < N)) return FALSE;
	return TRUE;
}

int TargetVMs::has_architecture(target_vm *VM, inter_architecture *A) {
	if (VM == NULL) internal_error("no VM");
	if (A == VM->architecture) return TRUE;
	return FALSE;
}

@ This function is only called to decide whether to issue certain ICL memory
settings to the Inform 6 compiler, and so we can basically assume the VM here
is going to end up as either the Z-machine or Glulx.

=
int TargetVMs::allow_memory_setting(target_vm *VM, text_stream *setting) {
	if (VM == NULL) internal_error("no VM");
	if (Str::eq_insensitive(setting, I"MAX_LOCAL_VARIABLES")) {
		if (VM->max_locals > 15) return TRUE;
		return FALSE;
	}
	if (Str::eq_insensitive(setting, I"DICT_CHAR_SIZE")) {
		if (TargetVMs::is_16_bit(VM) == FALSE) return TRUE;
		return FALSE;
	}
	if (Str::eq_insensitive(setting, I"DICT_WORD_SIZE")) {
		if (TargetVMs::is_16_bit(VM) == FALSE) return TRUE;
		return FALSE;
	}
	return TRUE;
}

@h File extension provisions.
The normal or unblorbed file extension is just a hint for what would make a
natural filename for our output: for example, |py| would be a natural choice
for a Python VN, if there were one.

When releasing a blorbed story file, the file extension used depends on the
story file wrapped inside. (This is a dubious idea, in the opinion of
the author of Inform -- should not "blorb" be one unified wrapper? -- but
that ship seems to have sailed.)

Note that for VMs not using Inform 6, blorbing is essentially meaningless,
and then the blorbed extension may be the empty text.

=
text_stream *TargetVMs::get_transpiled_extension(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->transpiled_extension;
}

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

It's also unclear what to write to this if we're compiling, say, an Inform 7
source text into C: the Treaty of Babel is unclear on that. For now, we write
|Inform7+C|.

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
//inblorb// needs to be given different release instructions for them. If the
user doesn't specify any particular interpreter, she gets the following.

On some platforms this will make no sense, and in those cases the function
will return the empty text.

=
text_stream *TargetVMs::get_default_interpreter(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->default_browser_interpreter;
}

@h Family compatibility.

=
text_stream *TargetVMs::family(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->transpiler_family;
}

int TargetVMs::compatible_with(target_vm *VM, text_stream *token) {	
	if (Str::eq_insensitive(VM->transpiler_family, token)) return TRUE;
	return FALSE;
}

@h Options.
Final code-generators can call this to see what special requests were made.

=
linked_list *TargetVMs::option_list(target_vm *VM) {
	if (VM == NULL) internal_error("no VM");
	return VM->format_options;
}
