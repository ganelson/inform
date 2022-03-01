[EliminateRedundantLabelsStage::] Eliminate Redundant Labels Stage.

To remove labels which are defined but never jumped to.

@ //inform7// tends to produce a lot of labels when compiling complicated text
substitutions, but many -- around 2000 in a typical run -- are never branched to,
either by a jump invocation or by assembly language.

These spurious labels cause no real problem except untidiness, but removing
them provides a simple example of how peephole optimisation can be performed
on an Inter tree.

=
void EliminateRedundantLabelsStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"eliminate-redundant-labels",
		EliminateRedundantLabelsStage::run, NO_STAGE_ARG, FALSE);
}

int redundant_labels_removed = 0;
int EliminateRedundantLabelsStage::run(pipeline_step *step) {
	redundant_labels_removed = 0;
	InterTree::traverse(step->ephemera.tree,
		EliminateRedundantLabelsStage::visitor, NULL, NULL, PACKAGE_IST);
	if (redundant_labels_removed > 0)
		LOG("%d redundant label(s) removed\n", redundant_labels_removed);
	return TRUE;
}

void EliminateRedundantLabelsStage::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_package *pack = PackageInstruction::at_this_head(P);
	if (InterPackage::is_a_function_body(pack))
		@<Perform peephole optimisation on this function body@>;
}

@<Perform peephole optimisation on this function body@> =
	inter_symbols_table *local_symbols = InterPackage::scope(pack);
	@<Mark all the labels for this function as being unused@>;
	@<Look through the function for mentions of labels, marking those as used@>;
	@<Remove the label declarations for any that are still marked unused@>;

@ The symbol flag |USED_MARK_ISYMF| is free for us to use, but its value for
any given symbol is undefined when we begin. We'll clear it for all labels.

@<Mark all the labels for this function as being unused@> =
	LOOP_OVER_SYMBOLS_TABLE(S, local_symbols)
		if (InterSymbol::is_label(S))
			InterSymbol::clear_flag(S, USED_MARK_ISYMF);

@<Look through the function for mentions of labels, marking those as used@> =
	inter_tree_node *D = InterPackage::head(pack);
	EliminateRedundantLabelsStage::traverse_code_tree(D);

@ Anything not marked used must be unused, so we can get rid of it. We do this
by striking its definition; the definition of a label symbol is the line
which shows where it belongs in the function (written |.Example| in Inter
syntax). Striking this does two things: it removes the definition line; and
it renders the symbol undefined. It still lives on in the function's symbols
table, though, and (since we have made sure there are no references to it from
anywhere) we may as well remove it.

@<Remove the label declarations for any that are still marked unused@> =
	LOOP_OVER_SYMBOLS_TABLE(S, local_symbols)
		if (InterSymbol::is_label(S))
			if (InterSymbol::get_flag(S, USED_MARK_ISYMF) == FALSE) {
				InterSymbol::strike_definition(S);
				InterSymbolsTable::remove_symbol(S);
				redundant_labels_removed++;
			}

@ The following visits every line of code in the function, in the same order
it would be written out in a listing.

=
void EliminateRedundantLabelsStage::traverse_code_tree(inter_tree_node *P) {
	LOOP_THROUGH_INTER_CHILDREN(F, P) {
		@<Examine a line of code in the function@>;
		EliminateRedundantLabelsStage::traverse_code_tree(F);
	}
}

@ If a label is used, there will be a line reading |lab Example| or similar.
We look for such lines.

@<Examine a line of code in the function@> =
	if (F->W.instruction[ID_IFLD] == LAB_IST) {
		inter_symbol *lab = LabInstruction::label_symbol(F);
		InterSymbol::set_flag(lab, USED_MARK_ISYMF);
	}
