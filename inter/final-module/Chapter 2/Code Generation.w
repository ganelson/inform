[CodeGen::] Code Generation.

To generate final code from intermediate code.

@h Pipeline stage.
This whole module exists to provide a single pipeline stage, making the final
generation of code from a tree of fully-linked and generally complete Inter.

It comes in two forms (the optional one writes nothing if no filename is supplied
to it; the compulsory one throws an error in that case), but note that both call
the same function.

=
void CodeGen::create_pipeline_stage(void) {
	CodeGen::Stage::new(I"generate", CodeGen::run_pipeline_stage,
		TEXT_OUT_STAGE_ARG, FALSE);
	CodeGen::Stage::new(I"optionally-generate", CodeGen::run_pipeline_stage, 
		OPTIONAL_TEXT_OUT_STAGE_ARG, FALSE);
}

@ Which is here. Three arguments can be supplied:
(a) The |target_argument|, which is something like |Inform6| or |C/no-main|.
Note that this must have validly parsed as a recognisable target already:
see //CodeGen::Targets::make_targets// for where the possibilities are set up.
(b) The |package_argument|, which can tell us to generate code from just a
single package of the Inter tree, rather than the whole thing. Some targets
recognise this, but most do not, and generate from the whole tree regardless.
(c) The |text_out_file| to write to.

=
int CodeGen::run_pipeline_stage(pipeline_step *step) {
	if (step->target_argument) {
		inter_package *this_package_only = NULL;
		@<Parse package from its argument@>;

		code_generation *gen = CodeGen::new_generation(step->parsed_filename, step->text_out_file,
			step->repository, this_package_only, step->target_argument, step->for_VM);
		if (CodeGen::Targets::begin_generation(gen) == FALSE) {
			CodeGen::generate(gen);
			CodeGen::Targets::end_generation(gen);
			CodeGen::write(step->text_out_file, gen);
		}
	}
	return TRUE;
}

@<Parse package from its argument@> =
	if (Str::len(step->package_argument) > 0) {
		this_package_only =
			Inter::Packages::by_url(step->repository, step->package_argument);
		if (this_package_only == NULL)
			CodeGen::Pipeline::error_with(
				"no such package name as '%S'", step->package_argument);
			return FALSE;
	}

@h Generations.
A "generation" is a single act of translating inter code into final code.

During a generation, textual output is assembled as a set of "segments".
(Different targets need different sets of segments.) This is all to facilitate
rearranging content as necessary to get it to compile in the target language:
for example, one might need to have all constants defined first, then all
arrays, and one could do this by creating two segments, one to accumulate
the constants in, one to accumulate the arrays.

At any given time, a generation has a "current" segment, to which output
is being written. Ome segment is special: the temporary one, which is used
only when assembling other material, and not for the final output.

@e temporary_I7CGS from 0

=
typedef struct code_generation {
	struct filename *to_file;          /* for binary output, or... */
	struct text_stream *text_out_file; /* for textual output */

	struct inter_tree *from;
	struct inter_package *just_this_package;
	struct target_vm *for_VM;

	struct code_generation_target *target;
	struct generated_segment *segments[NO_DEFINED_I7CGS_VALUES];
	struct linked_list *segment_sequence; /* of |generated_segment| */
	struct linked_list *additional_segment_sequence; /* of |generated_segment| */
	struct generated_segment *current_segment; /* an entry in that array, or null */
	int temporarily_diverted; /* to the temporary segment */
	void *target_specific_data; /* depending on the target generated to */
	CLASS_DEFINITION
} code_generation;

code_generation *CodeGen::new_generation(filename *F, text_stream *T, inter_tree *I,
	inter_package *just, code_generation_target *target, target_vm *VM) {
	code_generation *gen = CREATE(code_generation);
	gen->to_file = F;
	gen->text_out_file = T;
	if ((VM == NULL) && (target == NULL)) internal_error("no way to determine format");
	if (VM == NULL) VM = TargetVMs::find(target->target_name);
	gen->for_VM = VM;
	gen->from = I;
	gen->target = target;
	if (just) gen->just_this_package = just;
	else gen->just_this_package = Site::main_package(I);
	gen->current_segment = NULL;
	gen->segment_sequence = NEW_LINKED_LIST(generated_segment);
	gen->additional_segment_sequence = NEW_LINKED_LIST(generated_segment);
	gen->temporarily_diverted = FALSE;
	for (int i=0; i<NO_DEFINED_I7CGS_VALUES; i++) gen->segments[i] = NULL;
	return gen;
}

@ At present, at least, a "segment" is nothing more than a wrapper for a text.
But we abstract it in case it's ever useful for it to be more.

=
typedef struct generated_segment {
	struct text_stream *generated_code;
	CLASS_DEFINITION
} generated_segment;

generated_segment *CodeGen::new_segment(void) {
	generated_segment *seg = CREATE(generated_segment);
	seg->generated_code = Str::new();
	return seg;
}

void CodeGen::create_segments(code_generation *gen, void *data, int codes[]) {
	gen->segment_sequence = NEW_LINKED_LIST(generated_segment);
	for (int i=0; codes[i] >= 0; i++) {
		if ((codes[i] >= NO_DEFINED_I7CGS_VALUES) ||
			(codes[i] == temporary_I7CGS)) internal_error("bad segment sequence");
		gen->segments[codes[i]] = CodeGen::new_segment();
		ADD_TO_LINKED_LIST(gen->segments[codes[i]], generated_segment, gen->segment_sequence);
	}
	gen->target_specific_data = data;
}

void CodeGen::additional_segments(code_generation *gen, int codes[]) {
	gen->additional_segment_sequence = NEW_LINKED_LIST(generated_segment);
	for (int i=0; codes[i] >= 0; i++) {
		if ((codes[i] >= NO_DEFINED_I7CGS_VALUES) ||
			(codes[i] == temporary_I7CGS)) internal_error("bad segment sequence");
		gen->segments[codes[i]] = CodeGen::new_segment();
		ADD_TO_LINKED_LIST(gen->segments[codes[i]], generated_segment, gen->additional_segment_sequence);
	}
}

@ And then all we do is concatenate them in order:

=
void CodeGen::write(OUTPUT_STREAM, code_generation *gen) {
	generated_segment *seg;
	LOOP_OVER_LINKED_LIST(seg, generated_segment, gen->segment_sequence)
		WRITE("%S", seg->generated_code);
}

@ Here we switch the output, by changing the segment selection. This must
always be done in a way which is then undone, restoring the previous state:

=
generated_segment *CodeGen::select(code_generation *gen, int i) {
	generated_segment *saved = gen->current_segment;
	if ((i < 0) || (i >= NO_DEFINED_I7CGS_VALUES)) internal_error("out of range");
	if (gen->temporarily_diverted) internal_error("poorly timed selection");
	gen->current_segment = gen->segments[i];
	return saved;
}

void CodeGen::deselect(code_generation *gen, generated_segment *saved) {
	if (gen->temporarily_diverted) internal_error("poorly timed deselection");
	gen->current_segment = saved;
}

text_stream *CodeGen::content(code_generation *gen, int i) {
	if ((i < 0) || (i >= NO_DEFINED_I7CGS_VALUES)) internal_error("out of range");
	return gen->segments[i]->generated_code;
}

@ The procedure for selecting the temporary segment is different, because
we also have to direct it to a given text.

=
void CodeGen::select_temporary(code_generation *gen, text_stream *T) {
	if (gen->segments[temporary_I7CGS] == NULL) {
		gen->segments[temporary_I7CGS] = CodeGen::new_segment();
		gen->segments[temporary_I7CGS]->generated_code = NULL;
	}
	if (gen->temporarily_diverted)
		internal_error("nested temporary cgs");
	gen->temporarily_diverted = TRUE;
	gen->segments[temporary_I7CGS]->generated_code = T;
}

void CodeGen::deselect_temporary(code_generation *gen) {
	gen->temporarily_diverted = FALSE;
}

@  Note that temporary selections take precedence over the regular selection.

=
text_stream *CodeGen::current(code_generation *gen) {
	if (gen->temporarily_diverted)
		return gen->segments[temporary_I7CGS]->generated_code;
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
	InterTree::traverse(gen->from, CodeGen::clear_transients, NULL, NULL, PACKAGE_IST);
	CodeGen::FC::prepare(gen);
	CodeGen::CL::prepare(gen);
	CodeGen::Var::prepare(gen);
	CodeGen::IP::prepare(gen);

@<Phase two - traverse@> =
	InterTree::traverse_root_only(gen->from, CodeGen::pragma, gen, PRAGMA_IST);
	InterTree::traverse(gen->from, CodeGen::FC::pre_iterate, gen, NULL, -PACKAGE_IST);
	InterTree::traverse(gen->from, CodeGen::FC::iterate, gen, NULL, -PACKAGE_IST);

@<Phase three - consolidation@> =
	CodeGen::IP::write_properties(gen);
	CodeGen::CL::sort_literals(gen);

@

=
void CodeGen::pragma(inter_tree *I, inter_tree_node *P, void *state) {
	code_generation *gen = (code_generation *) state;
	inter_symbol *target_symbol = InterSymbolsTables::symbol_from_frame_data(P, TARGET_PRAGMA_IFLD);
	if (target_symbol == NULL) internal_error("bad pragma");
	inter_ti ID = P->W.data[TEXT_PRAGMA_IFLD];
	text_stream *S = Inode::ID_to_text(P, ID);
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
