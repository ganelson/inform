[CodeGen::] Code Generation.

To generate final code from intermediate code.

@h Pipeline stage.

=
void CodeGen::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"generate", CodeGen::run_pipeline_stage, TEXT_OUT_STAGE_ARG, FALSE);
}

int CodeGen::run_pipeline_stage(pipeline_step *step) {
	if (step->target_argument == NULL) internal_error("no target specified");
	inter_package *which = NULL;
	if (Str::len(step->package_argument) > 0) {
		which = Inter::Packages::by_url(step->repository,
			step->package_argument);
		if (which == NULL) {
			LOG("Arg %S\n", step->package_argument);
			internal_error("no such package name");
		}
	}

	code_generation *gen =
		CodeGen::new_generation(step, step->repository, which, step->target_argument);
	if (CodeGen::Targets::begin_generation(gen) == FALSE) {
		CodeGen::generate(gen);
		CodeGen::write(step->text_out_file, gen);
	}
	return TRUE;
}

@h Generations.
A "generation" is a single act of translating inter code into final code.
That final code will be a text file written in some other programming
language, though probably a low-level one.

The "target" of a generation is the final language: for example, Inform 6.

During a generation, textual output is assembled as a set of "segments".
Different targets may need different segments. This is all to facilitate
rearranging content as necessary to get it to compile in the target language:
for example, one might need to have all constants defined first, then all
arrays, and one could do this by creating two segments, one to accumulate
the constants in, one to accumulate the arrays.

At any given time, a generation has a "current" segment, to which output
is being written. Ome segment is special: the temporary one, which is used
only when assembling other material, and not for the final output.

@d MAX_CG_SEGMENTS 100
@d TEMP_CG_SEGMENT 99

=
typedef struct code_generation {
	struct pipeline_step *from_step;
	struct inter_tree *from;
	struct code_generation_target *target;
	struct inter_package *just_this_package;
	struct generated_segment *segments[MAX_CG_SEGMENTS];
	struct generated_segment *current_segment; /* an entry in that array, or null */
	int temporarily_diverted; /* to the temporary segment */
	MEMORY_MANAGEMENT
} code_generation;

code_generation *CodeGen::new_generation(pipeline_step *step, inter_tree *I,
	inter_package *just, code_generation_target *target) {
	code_generation *gen = CREATE(code_generation);
	gen->from_step = step;
	gen->from = I;
	gen->target = target;
	if (just) gen->just_this_package = just;
	else gen->just_this_package = Site::main_package(I);
	gen->current_segment = NULL;
	gen->temporarily_diverted = FALSE;
	for (int i=0; i<MAX_CG_SEGMENTS; i++) gen->segments[i] = NULL;
	return gen;
}

@ At present, at least, a "segment" is nothing more than a wrapper for a text.
But we abstract it in case it's ever useful for it to be more.

=
typedef struct generated_segment {
	struct text_stream *generated_code;
	MEMORY_MANAGEMENT
} generated_segment;

generated_segment *CodeGen::new_segment(void) {
	generated_segment *seg = CREATE(generated_segment);
	seg->generated_code = Str::new();
	return seg;
}

@ The segments should be numbered in the order they will appear in the final
output, because:

=
void CodeGen::write(OUTPUT_STREAM, code_generation *gen) {
	for (int i=0; i<MAX_CG_SEGMENTS; i++) {
		if ((gen->segments[i]) && (i != TEMP_CG_SEGMENT))
			WRITE("%S", gen->segments[i]->generated_code);
	}
}

@ Here we switch the output, by changing the segment selection. This must
always be done in a way which is then undone, restoring the previous state:

=
generated_segment *CodeGen::select(code_generation *gen, int i) {
	generated_segment *saved = gen->current_segment;
	if ((i < 0) || (i >= MAX_CG_SEGMENTS)) internal_error("out of range");
	if (gen->temporarily_diverted) internal_error("poorly timed selection");
	gen->current_segment = gen->segments[i];
	return saved;
}

void CodeGen::deselect(code_generation *gen, generated_segment *saved) {
	if (gen->temporarily_diverted) internal_error("poorly timed deselection");
	gen->current_segment = saved;
}

@ The procedure for selecting the temporary segment is different, because
we also have to direct it to a given text.

=
void CodeGen::select_temporary(code_generation *gen, text_stream *T) {
	if (gen->segments[TEMP_CG_SEGMENT] == NULL) {
		gen->segments[TEMP_CG_SEGMENT] = CodeGen::new_segment();
		gen->segments[TEMP_CG_SEGMENT]->generated_code = NULL;
	}
	if (gen->temporarily_diverted)
		internal_error("nested temporary cgs");
	gen->temporarily_diverted = TRUE;
	gen->segments[TEMP_CG_SEGMENT]->generated_code = T;
}

void CodeGen::deselect_temporary(code_generation *gen) {
	gen->temporarily_diverted = FALSE;
}

@  Note that temporary selections take precedence over the regular selection.

=
text_stream *CodeGen::current(code_generation *gen) {
	if (gen->temporarily_diverted)
		return gen->segments[TEMP_CG_SEGMENT]->generated_code;
	if (gen->current_segment == NULL) return NULL;
	return gen->current_segment->generated_code;
}

@h Actual generation happens in three phases:

=
void CodeGen::generate(code_generation *gen) {
	@<Phase one - preparation@>;
	@<Phase two - traverse@>;
	@<Phase three - consolidation@>;
}

@<Phase one - preparation@> =
	Inter::Tree::traverse(gen->from, CodeGen::clear_transients, NULL, NULL, PACKAGE_IST);
	CodeGen::FC::prepare(gen);
	CodeGen::CL::prepare(gen);
	CodeGen::Var::prepare(gen);
	CodeGen::IP::prepare(gen);

@<Phase two - traverse@> =
	Inter::Tree::traverse_root_only(gen->from, CodeGen::pragma, gen, PRAGMA_IST);
	Inter::Tree::traverse(gen->from, CodeGen::FC::iterate, gen, NULL, -PACKAGE_IST);

@<Phase three - consolidation@> =
	CodeGen::CL::responses(gen);
	CodeGen::IP::write_properties(gen);
	CodeGen::CL::sort_literals(gen);

@

=
void CodeGen::pragma(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *target_symbol = Inter::SymbolsTables::symbol_from_frame_data(P, TARGET_PRAGMA_IFLD);
	if (target_symbol == NULL) internal_error("bad pragma");
	inter_t ID = P->W.data[TEXT_PRAGMA_IFLD];
	text_stream *S = Inter::Node::ID_to_text(P, ID);
	CodeGen::Targets::offer_pragma(gen, P, target_symbol->symbol_name, S);
}

@h Marking.
We use a transient flag on symbols, but abstract that here:

=
int CodeGen::marked(inter_symbol *symb_name) {
	return Inter::Symbols::get_flag(symb_name, TRAVERSE_MARK_BIT);
}

void CodeGen::mark(inter_symbol *symb_name) {
	Inter::Symbols::set_flag(symb_name, TRAVERSE_MARK_BIT);
}

void CodeGen::unmark(inter_symbol *symb_name) {
	Inter::Symbols::clear_flag(symb_name, TRAVERSE_MARK_BIT);
}

void CodeGen::clear_transients(inter_tree *I, inter_tree_node *P, void *state) {
	inter_package *pack = Inter::Package::defined_by_frame(P);
	inter_symbols_table *T = Inter::Packages::scope(pack);
	for (int i=0; i<T->size; i++)
		if (T->symbol_array[i])
			Inter::Symbols::clear_transient_flags(T->symbol_array[i]);
}
