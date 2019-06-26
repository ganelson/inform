[CodeGen::Targets::] Targets.

To create the range of possible targets into which Inter can be converted.

@h Targets.
Single, steel-cut artisanal targets are made here:

=
typedef struct code_generation_target {
	struct text_stream *target_name;
	MEMORY_MANAGEMENT
} code_generation_target;

code_generation_target *CodeGen::Targets::new(text_stream *name) {
	code_generation_target *cgt = CREATE(code_generation_target);
	cgt->target_name = Str::duplicate(name);
	return cgt;
}

@ And they are mass-produced here:

=
int cgts_made = FALSE;

code_generation_target *binary_inter_cgt = NULL;
code_generation_target *textual_inter_cgt = NULL;
code_generation_target *summary_cgt = NULL;

void CodeGen::Targets::make_targets(void) {
	if (cgts_made == FALSE) {
		cgts_made = TRUE;
		binary_inter_cgt = CodeGen::Targets::new(I"binary");
		textual_inter_cgt = CodeGen::Targets::new(I"text");
		summary_cgt = CodeGen::Targets::new(I"summary");
		CodeGen::create_code_targets();
	}
}
