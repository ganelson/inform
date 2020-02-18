[VirtualMachines::] Virtual Machines.

I7 supports a variety of virtual machines as targets. Most source
text should be independent of the target VM, but sometimes numbering is
needed, and this is where any VM dependencies are decided.

@h Definitions.

@ We use the term "major VM" to mean one of the families we deal with:
the Z-machine, for instance, is a major VM. A "minor VM" is a specific
revision of this, such as version 5 of the Z-machine. The following table
describes both major and minor VMs: records with version set to $-1$ are
major, and the rest minor.

It is assumed that major VM names are single words: happily Z-machine has
always traditionally been hyphenated. We also assume their names use only
the plainest ASCII characters.

@ We store data on both major and minor VMs in the following simple structure.

The point of multiplying version numbers by 10,000 is to allow room for
sub-versions in future: Glulx in particular has version numbers like 3.4.2,
which we might want to represent as 30402. (At present we don't distinguish
versions of Glulx because Glulx's gestalt mechanism means that it's much
easier to construct story files which can cope nicely on different Glulx
interpreter versions than would be the case for the Z-machine.) Given that
the multiplier is larger than 1, it is impossible for $-1$ to be a valid
version number of any VM, so this is used as a "not a version number" value.

@d VMULT 10000

=
typedef struct VM_identifier {
	int VM_code; /* one of the values above */
	int VM_version; /* times the |VMULT|, or -1 to mean generic versionless VM */
	wchar_t *VM_major_name; /* or NULL if not a major VM name */
	char *VM_extension; /* canonical filename extension */
	char *VM_blorbed_extension; /* when blorbed up */
	char *VM_name; /* text to use with author */
	char *VM_image; /* filename of image for icon denoting VM */
	int VM_is_32_bit; /* true or false: false means 16-bit */
	int max_locals; /* upper limit on local variables per stack frame */
	int VM_matches; /* true or false: computed */
	wchar_t *default_browser_interpreter; /* e.g., "Parchment" */
} VM_identifier;

@ We keep track of how array space is used in the VM, since this is in very
short supply in the Z-machine. This is done purely so that we can index
helpfully on the Contents index page.

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

@h Table of supported VMs.
The following data determines what VMs we know about, and how they can
be inferred from the present information passed by the GUI to us at the
command line - viz., the eventual file extension. The application passes
this by including among the command-line switches a pair like so:

	|-extension ulx|

The second word must be one of the file extensions listed in the fourth
column of the table of VM data below: the comparison is made case
insensitively, and any initial full stop is skipped, so ".Z6" is
equivalent to "z6".

@d Z_VM 1 /* Joel Berez and Marc Blank, 1979, and later hands */
@d GLULX_VM 2 /* Andrew Plotkin, 2000 */

@d DEFAULT_TARGET_VM 3 /* if no -extension is supplied, target row 3: Z-machine v8 */

=
VM_identifier table_of_VM_data[] = {
	{ Z_VM,      -1, L"z-machine",  NULL, "zblorb", "Z-Machine", "vm_z.png", FALSE, 15, FALSE, L"Parchment" },
	{ Z_VM, 5*VMULT, NULL,  "z5", "zblorb", "Z-Machine version 5", "vm_z5.png", FALSE, 15, FALSE, L"Parchment" },
	{ Z_VM, 6*VMULT, NULL,  "z6", "zblorb", "Z-Machine version 6", "vm_z6.png", FALSE, 15, FALSE, L"Parchment" },
	{ Z_VM, 8*VMULT, NULL,  "z8", "zblorb", "Z-Machine version 8", "vm_z8.png", FALSE, 15, FALSE, L"Parchment" },
	{ GLULX_VM,  -1, L"glulx", "ulx", "gblorb", "Glulx", "vm_glulx.png", TRUE, 256, FALSE, L"Quixe" },
	{ -1,         0, NULL, NULL, NULL, NULL, NULL, FALSE, 15, FALSE, L"Parchment" }
};

@ At present, we infer the target virtual machine by looking at the file
extension requested at the command line.

=
int target_VM; /* an index in the above table, or -1 if unknown */

void VirtualMachines::set_identifier(text_stream *text) {
	if (text == NULL) { target_VM = DEFAULT_TARGET_VM; return; }
	TEMPORARY_TEXT(file_extension);
	Str::copy(file_extension, text);
	if (Str::get_first_char(file_extension) == '.') Str::delete_first_character(file_extension);
	LOOP_THROUGH_TEXT(pos, file_extension)
		Str::put(pos, Characters::tolower(Str::get(pos)));
	target_VM = -1;
    for (int i=0; table_of_VM_data[i].VM_code >= 0; i++)
    	if ((table_of_VM_data[i].VM_extension) &&
    		(Str::eq_narrow_string(file_extension, table_of_VM_data[i].VM_extension)))
    		target_VM = i;
	DISCARD_TEXT(file_extension);
}

@ To help Inform detect overflows, it needs to know whether integers in the
target VM are 16 or 32 bits wide:

=
int VirtualMachines::is_16_bit(void) {
	if (target_VM == -1) internal_error("target VM not set yet");
	if (table_of_VM_data[target_VM].VM_is_32_bit) return FALSE;
	return TRUE;
}

@ Using which:

=
int VirtualMachines::veto_number(int X) {
	if (((X > 32767) || (X < -32768)) && (VirtualMachines::is_16_bit())) {
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
	if (target_VM == -1) internal_error("target VM not set yet");

	if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile))
		VirtualMachines::emit_fundamental_constant(DEBUG_HL, 1);

	if (table_of_VM_data[target_VM].VM_code == Z_VM) {
		VirtualMachines::emit_fundamental_constant(TARGET_ZCODE_HL, 1);
		VirtualMachines::emit_fundamental_constant(DICT_WORD_SIZE_HL, 6);
	} else if (table_of_VM_data[target_VM].VM_code == GLULX_VM) {
		VirtualMachines::emit_fundamental_constant(TARGET_GLULX_HL, 1);
		VirtualMachines::emit_fundamental_constant(DICT_WORD_SIZE_HL, 9);
		VirtualMachines::emit_fundamental_constant(INDIV_PROP_START_HL, 0);
	}

	if (table_of_VM_data[target_VM].VM_is_32_bit) {
		VirtualMachines::emit_fundamental_constant(WORDSIZE_HL, 4);
		VirtualMachines::emit_unchecked_hex_fundamental_constant(NULL_HL, 0xffffffff);
		VirtualMachines::emit_hex_fundamental_constant(WORD_HIGHBIT_HL, 0x80000000);
		VirtualMachines::emit_hex_fundamental_constant(WORD_NEXTTOHIGHBIT_HL, 0x40000000);
		VirtualMachines::emit_hex_fundamental_constant(IMPROBABLE_VALUE_HL, 0xdeadce11);
		VirtualMachines::emit_hex_fundamental_constant(REPARSE_CODE_HL, 0x40000000);
		VirtualMachines::emit_fundamental_constant(MAX_POSITIVE_NUMBER_HL, 2147483647);
		VirtualMachines::emit_signed_fundamental_constant(MIN_NEGATIVE_NUMBER_HL, -2147483648);
	} else {
		VirtualMachines::emit_fundamental_constant(WORDSIZE_HL, 2);
		VirtualMachines::emit_unchecked_hex_fundamental_constant(NULL_HL, 0xffff);
		VirtualMachines::emit_hex_fundamental_constant(WORD_HIGHBIT_HL, 0x8000);
		VirtualMachines::emit_hex_fundamental_constant(WORD_NEXTTOHIGHBIT_HL, 0x4000);
		VirtualMachines::emit_hex_fundamental_constant(IMPROBABLE_VALUE_HL, 0x7fe3);
		VirtualMachines::emit_hex_fundamental_constant(REPARSE_CODE_HL, 10000);
		VirtualMachines::emit_fundamental_constant(MAX_POSITIVE_NUMBER_HL, 32767);
		VirtualMachines::emit_signed_fundamental_constant(MIN_NEGATIVE_NUMBER_HL, -32768);
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
	if (target_VM == -1) internal_error("target VM not set yet");
	if ((table_of_VM_data[target_VM].max_locals >= 0) &&
		(table_of_VM_data[target_VM].max_locals < N)) return FALSE;
	return TRUE;
}
int VirtualMachines::allow_MAX_LOCAL_VARIABLES(void) {
	if (target_VM == -1) internal_error("target VM not set yet");
	if (table_of_VM_data[target_VM].max_locals > 15) return TRUE;
	return FALSE;
}

@ Real numbers are also a concern:

=
int VirtualMachines::supports(kind *K) {
	if (target_VM == -1) internal_error("target VM not set yet");
	if ((Kinds::FloatingPoint::uses_floating_point(K)) &&
		(table_of_VM_data[target_VM].VM_is_32_bit == FALSE)) return FALSE;
	return TRUE;
}

@ When releasing a blorbed story file, the file extension depends on the
story file wrapped inside. (This is a dubious idea, in the opinion of
the author of Inform -- should not blorb be one unified wrapper? -- but
interpreter writers disagree.)

=
char *VirtualMachines::get_blorbed_extension(void) {
	if (target_VM == -1) internal_error("target VM not set yet");
	return table_of_VM_data[target_VM].VM_blorbed_extension;
}

@ Different VMs have different in-browser interpreters, which means that
Inblorb needs to be given different release instructions for them. If the
user doesn't specify any particular interpreter, he gets:

=
wchar_t *VirtualMachines::get_default_interpreter(void) {
	if (target_VM == -1) internal_error("target VM not set yet");
	return table_of_VM_data[target_VM].default_browser_interpreter;
}

@h Parsing VM restrictions.
Given a word range, we see what set of virtual machines it specifies. For example,
the result of calling

>> for Z-machine version 5 or 8 only

is that the |VM_matches| field in the table above is set for the two minor VMs
cited, and cleared for all of the others, while the |VM_matching_error_thrown|
is false (since the text was valid). The same result is produced by

>> for Z-machine versions 5 and 8 only

English being quirky that way.

@d THROW_VM_MATCHING_ERROR_AND_RETURN { VM_matching_error_thrown = TRUE; return TRUE; }

=
int VM_matching_error_thrown = FALSE; /* an error occurred during parsing */
int most_recent_major_VM; /* most recent major VM which matched, or $-1$ */
int version_can_be_inferred; /* from earlier in the word range parsed */

void VirtualMachines::match_against(wording W) {
	@<Clean the slate ready for a fresh VM parse@>;
	<vm-description-list>(W);
}

@ It is slightly lazy of this code to use global variables to preserve state
through a sequence of function calls to |match_VM_from|, but sometimes a
little laziness is what we deserve.

@<Clean the slate ready for a fresh VM parse@> =
	int i;
	VM_matching_error_thrown = FALSE;
	most_recent_major_VM = -1;
	version_can_be_inferred = FALSE;
    for (i=0; table_of_VM_data[i].VM_code >= 0; i++) table_of_VM_data[i].VM_matches = FALSE;

@ Not much grammar is used to parse virtual machine identifications like:

>> Z-machine versions 5 and 8

The words "Z-machine" and "Glulx" are hard-wired so that they can't be
altered using Preform. (The Spanish for "Glulx", say, is "Glulx".) Preform
grammar is used first to split the list:

=
<vm-description-list> ::=
	... |												==> 0; return preform_lookahead_mode; /* match only when looking ahead */
	<vm-description-entry> <vm-description-tail> |	==> 0
	<vm-description-entry>								==> 0

<vm-description-tail> ::=
	, _and/or <vm-description-list> |
	_,/and/or <vm-description-list>

<vm-description-entry> ::=
	...													==> @<Parse latest term in word range list@>

@ Preform doesn't parse the VM names themselves, but it does pick up the
optional part about version numbering:

=
<version-identification> ::=
	version/versions <cardinal-number>		==> R[1]

@<Parse latest term in word range list@> =
	@<Detect major VM name, if given, and advance one word@>;
	@<Give up if no major VM name found in any term of the list so far@>;
	if (Wordings::nonempty(W)) {
		int version_specified = -1;
		if (<version-identification>(W)) {
			version_specified = VMULT * <<r>>;
			version_can_be_inferred = TRUE;
		} else if ((version_can_be_inferred) && (<cardinal-number>(W))) {
			version_specified = VMULT * <<r>>;
		} else THROW_VM_MATCHING_ERROR_AND_RETURN;
		@<Score a match for this specific version of the major VM, if we know about it@>;
	} else {
		@<Score a match for every known version of the major VM@>;
	}

@ The word "version" is sometimes implicit, but not after a major VM name.
Thus "Glulx 3" is not allowed: it has to be "Glulx version 3".

@<Detect major VM name, if given, and advance one word@> =
	int i;
	for (i=0; table_of_VM_data[i].VM_code >= 0; i++)
    	if ((table_of_VM_data[i].VM_major_name) &&
    		(Word::compare_by_strcmp(Wordings::first_wn(W), table_of_VM_data[i].VM_major_name))) {
			most_recent_major_VM = table_of_VM_data[i].VM_code;
			version_can_be_inferred = FALSE;
			W = Wordings::trim_first_word(W);
			break;
		}

@ The variable |VM_matching_error_thrown| may have been set either on
this term or a previous one: for instance, if we are reading "Squirrel
versions 4 and 7" then at the second term, "7", no major VM is named
but the variable remains set from "Squirrel" having been parsed at the
first term.

@<Give up if no major VM name found in any term of the list so far@> =
    if (most_recent_major_VM == -1) THROW_VM_MATCHING_ERROR_AND_RETURN;

@ We either make a run of matches:

@<Score a match for every known version of the major VM@> =
	for (int i=0; table_of_VM_data[i].VM_code >= 0; i++)
    	if (table_of_VM_data[i].VM_code == most_recent_major_VM)
    		table_of_VM_data[i].VM_matches = TRUE;

@ ...or else we make a single match, or even none at all. This would not be
an error: if the request was for "version 71 of Chipmunk", and we were
unable to compile to this VM (so that no such minor VM record appeared in
the table) then the situation might be that we are reading the requirements
of some extension used by other people, who have a later version of Inform
than us, and which does compile to that VM.

@<Score a match for this specific version of the major VM, if we know about it@> =
	for (int i=0; table_of_VM_data[i].VM_code >= 0; i++)
		if ((table_of_VM_data[i].VM_code == most_recent_major_VM) &&
			(version_specified == table_of_VM_data[i].VM_version))
			table_of_VM_data[i].VM_matches = TRUE;

@ The following nonterminal matches any valid description of a virtual machine,
with result |TRUE| if the current target VM matches that description and
|FALSE| if not.

=
<virtual-machine> internal {
	if (target_VM == -1) internal_error("target VM not set yet");
	VirtualMachines::match_against(W);
	if (VM_matching_error_thrown) return FALSE;
    if (table_of_VM_data[target_VM].VM_matches) *X = TRUE;
    else *X = FALSE;
    return TRUE;
}

@h Icons for virtual machines.
And everything else is cosmetic: printing, or showing icons to signify,
the current VM or some set of permitted VMs. The following plots the
icon associated with a given minor VM, and explicates what the icons mean:

=
void VirtualMachines::plot_icon(OUTPUT_STREAM, int minor) {
	if (table_of_VM_data[minor].VM_image) {
		HTML_TAG_WITH("img",
			"border=0 src=inform:/doc_images/%s",
			table_of_VM_data[minor].VM_image);
		WRITE("&nbsp;");
	}
}

void VirtualMachines::write_key(OUTPUT_STREAM) {
	WRITE("Extensions compatible with specific story file formats only: ");
    for (int i=0; table_of_VM_data[i].VM_code >= 0; i++) {
    	if (i>0) WRITE(", ");
    	VirtualMachines::plot_icon(OUT, i);
		WRITE("%s", table_of_VM_data[i].VM_name);
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
	if (target_VM == -1) internal_error("target VM not set yet");
	Index::anchor(OUT, I"STORYFILE");
	HTML_OPEN("p"); WRITE("Story file format: ");
	VirtualMachines::plot_icon(OUT, target_VM);
	if (table_of_VM_data[target_VM].VM_name) WRITE(table_of_VM_data[target_VM].VM_name);
	else WRITE("No name available\n");
	HTML_CLOSE("p");
	if (VirtualMachines::is_16_bit()) {
		HTML_OPEN("p"); Index::extra_link(OUT, 1);
		WRITE("See estimates of memory usage");
		HTML_CLOSE("p");
		Index::extra_div_open(OUT, 1, 1, "e0e0e0");
		VirtualMachines::index_memory_usage(OUT);
		Index::extra_div_close(OUT, "e0e0e0");
	}
}

@h Displaying VM restrictions.
Given a word range, we parse it to set the match flags, then describe the
result as concisely as we can with a row of icons.

=
void VirtualMachines::write_icons(OUTPUT_STREAM, wording W) {
	VirtualMachines::match_against(W);
	@<Display nothing if every VM matches@>;
	@<Display only the generic Z icon if every Z-machine VM version matches@>;
    for (int i=0; table_of_VM_data[i].VM_code >= 0; i++)
    	if (table_of_VM_data[i].VM_matches)
    		VirtualMachines::plot_icon(OUT, i);
}

@ To avoid the extensions directory page being plastered with gaudy but
uncommunicative icons, we leave blank space if the requirements are always
met. The icons are to signal exceptions.

@<Display nothing if every VM matches@> =
	int everything_matches = TRUE;
    for (int i=0; table_of_VM_data[i].VM_code >= 0; i++)
    	if (table_of_VM_data[i].VM_matches == FALSE)
    		everything_matches = FALSE;
	if (everything_matches) return;

@ This might happen if the user typed "for Z-machine only", but could also
come about if he typed a specification naming in turn each minor version we
know about, so the only way to check is to look at the match flag for each
one.

@<Display only the generic Z icon if every Z-machine VM version matches@> =
	int every_Z_matches = TRUE;
    for (int i=0; table_of_VM_data[i].VM_code >= 0; i++)
    	if ((table_of_VM_data[i].VM_code == Z_VM) &&
    		(table_of_VM_data[i].VM_matches == FALSE))
    		every_Z_matches = FALSE;
	if (every_Z_matches)
		@<Replace minor Z VMs in the match set with the single major one@>;

@ The following operation leaves the match set in a state which does not
correspond to what parsing would tell us (indeed, that's the point): so
we must not use the match set again without reparsing it. But in fact,
the match set is always recalculated before being used, so this is fine.

@<Replace minor Z VMs in the match set with the single major one@> =
	for (int i=0; table_of_VM_data[i].VM_code >= 0; i++)
		if (table_of_VM_data[i].VM_code == Z_VM) {
			if (table_of_VM_data[i].VM_major_name) /* the major VM line for Z */
				table_of_VM_data[i].VM_matches = TRUE;
			else
				table_of_VM_data[i].VM_matches = FALSE; /* one of the minor ones */
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
