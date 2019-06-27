[CodeGen::Targets::] Targets.

To create the range of possible targets into which Inter can be converted.

@h Targets.
Single, steel-cut artisanal targets are made here:

=
typedef struct code_generation_target {
	struct text_stream *target_name;
	METHOD_CALLS
	MEMORY_MANAGEMENT
} code_generation_target;

code_generation_target *CodeGen::Targets::new(text_stream *name) {
	code_generation_target *cgt = CREATE(code_generation_target);
	cgt->target_name = Str::duplicate(name);
	ENABLE_METHOD_CALLS(cgt);
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
		CodeGen::I6::create_target();
	}
}

@

@e BEGIN_GENERATION_MTID

=
VMETHOD_TYPE(BEGIN_GENERATION_MTID, code_generation_target *cgt, code_generation *gen)
void CodeGen::Targets::begin_generation(code_generation *gen) {
	VMETHOD_CALL(gen->target, BEGIN_GENERATION_MTID, gen);
}

@

@e GENERAL_SEGMENT_MTID
@e DEFAULT_SEGMENT_MTID
@e CONSTANT_SEGMENT_MTID
@e PROPERTY_SEGMENT_MTID
@e TL_SEGMENT_MTID

=
IMETHOD_TYPE(GENERAL_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen, inter_frame P)
IMETHOD_TYPE(DEFAULT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
IMETHOD_TYPE(CONSTANT_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
IMETHOD_TYPE(PROPERTY_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)
IMETHOD_TYPE(TL_SEGMENT_MTID, code_generation_target *cgt, code_generation *gen)

int CodeGen::Targets::general_segment(code_generation *gen, inter_frame P) {
	int rv = 0;
	IMETHOD_CALL(rv, gen->target, GENERAL_SEGMENT_MTID, gen, P);
	return rv;
}

int CodeGen::Targets::default_segment(code_generation *gen) {
	int rv = 0;
	IMETHOD_CALL(rv, gen->target, DEFAULT_SEGMENT_MTID, gen);
	return rv;
}

int CodeGen::Targets::constant_segment(code_generation *gen) {
	int rv = 0;
	IMETHOD_CALL(rv, gen->target, CONSTANT_SEGMENT_MTID, gen);
	return rv;
}

int CodeGen::Targets::property_segment(code_generation *gen) {
	int rv = 0;
	IMETHOD_CALL(rv, gen->target, PROPERTY_SEGMENT_MTID, gen);
	return rv;
}

int CodeGen::Targets::tl_segment(code_generation *gen) {
	int rv = 0;
	IMETHOD_CALL(rv, gen->target, TL_SEGMENT_MTID, gen);
	return rv;
}

@

@e COMPILE_PRIMITIVE_MTID

=
IMETHOD_TYPE(COMPILE_PRIMITIVE_MTID, code_generation_target *cgt, code_generation *gen, inter_symbol *prim_name, inter_frame_list *ifl)
int CodeGen::Targets::compile_primitive(code_generation *gen, inter_symbol *prim_name, inter_frame_list *ifl) {
	int rv = FALSE;
	IMETHOD_CALL(rv, gen->target, COMPILE_PRIMITIVE_MTID, gen, prim_name, ifl);
	return rv;
}

@

@e COMPILE_LITERAL_TEXT_MTID

=
VMETHOD_TYPE(COMPILE_LITERAL_TEXT_MTID, code_generation_target *cgt, code_generation *gen, text_stream *S, int print_mode, int box_mode)
void CodeGen::Targets::compile_literal_text(code_generation *gen, text_stream *S, int print_mode, int box_mode) {
	VMETHOD_CALL(gen->target, COMPILE_LITERAL_TEXT_MTID, gen, S, print_mode, box_mode);
}

@

@e DECLARE_PROPERTY_MTID

=
VMETHOD_TYPE(DECLARE_PROPERTY_MTID, code_generation_target *cgt, code_generation *gen, inter_symbol *prop_name, int used)
void CodeGen::Targets::declare_property(code_generation *gen, inter_symbol *prop_name, int used) {
	VMETHOD_CALL(gen->target, DECLARE_PROPERTY_MTID, gen, prop_name, used);
}
