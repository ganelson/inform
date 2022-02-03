[NewStage::] New Stage.

This stage takes an empty (or wiped) tree and equips it with just the
absolute basics, so that it is ready to have substantive material added
at a later stage.

@ =
void NewStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"new", NewStage::run, NO_STAGE_ARG, FALSE);
}

int NewStage::run(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	@<Make the main package@>;
	@<Add another few package types which we will need when linking@>;

	inter_package *main_p = LargeScale::main_package(I);
	inter_bookmark in_main = InterBookmark::at_end_of_this_package(main_p);
	inter_package *generic_p = NULL, *generic_kinds_p = NULL;
	InterPackage::new_package_named(&in_main, I"generic", FALSE,
		LargeScale::package_type(I, I"_module"), 1, NULL, &generic_p);
	inter_bookmark in_generic = InterBookmark::at_end_of_this_package(generic_p);
	InterPackage::new_package_named(&in_generic, I"kinds", FALSE,
		LargeScale::package_type(I, I"_submodule"), 1, NULL, &generic_kinds_p);
	inter_bookmark in_generic_kinds = InterBookmark::at_end_of_this_package(generic_kinds_p);

	inter_symbol *unchecked_kind_symbol = NULL;
	@<Create the unchecked kind@>;
	@<Create the unchecked function kind@>;
	@<Create the unchecked list kind@>;
	@<Create the integer kind@>;
	@<Create the boolean kind@>;
	@<Create the string kind@>;

	LargeScale::make_architectural_definitions(I, PipelineModule::get_architecture(),
		unchecked_kind_symbol);
	return TRUE;
}

@ The following creates the |main| package and the package types |_plain|,
|_code| and |_linkage| -- which are needed for the //building// module to
function.

@<Make the main package@> =
	LargeScale::begin_new_tree(I);

@ There are then further package types whose use is a matter of convention,
as far as //building// is concerned, but which this //pipeline// module relies on.

@<Add another few package types which we will need when linking@> =
	LargeScale::package_type(I, I"_module");
	LargeScale::package_type(I, I"_submodule");
	LargeScale::package_type(I, I"_function");
	LargeScale::package_type(I, I"_action");
	LargeScale::package_type(I, I"_command");
	LargeScale::package_type(I, I"_property");
	LargeScale::package_type(I, I"_to_phrase");
	LargeScale::package_type(I, I"_response");

@ The package |main/generic/kinds| contains some rudimentary Inter kinds of data.
(See also //runtime: Emit//, where a matching set is made by the Inform 7 compiler
when it builds an Inter tree: we want to keep this minimum set matching.)

To begin with, the definition of |K_unchecked|, the Inter kind which means "any
base data type matches this".

@<Create the unchecked kind@> =
	unchecked_kind_symbol =
		InterSymbolsTable::create_with_unique_name(
			InterBookmark::scope(&in_generic_kinds), I"K_unchecked");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTable::id_from_symbol(I, generic_kinds_p, unchecked_kind_symbol),
		UNCHECKED_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) InterBookmark::baseline(&in_generic_kinds) + 1, NULL);

@ And this expresses the idea of "any sort of function":

@<Create the unchecked function kind@> =
	inter_ti operands[2];
	operands[0] = InterSymbolsTable::id_from_symbol_at_bookmark(
		&in_generic_kinds, unchecked_kind_symbol);
	operands[1] = InterSymbolsTable::id_from_symbol_at_bookmark(
		&in_generic_kinds, unchecked_kind_symbol);
	inter_symbol *unchecked_function_symbol =
		InterSymbolsTable::create_with_unique_name(
			InterBookmark::scope(&in_generic_kinds), I"K_unchecked_function");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTable::id_from_symbol(I, generic_kinds_p, unchecked_function_symbol),
		ROUTINE_IDT, 0, FUNCTION_ICON, 2, operands,
		(inter_ti) InterBookmark::baseline(&in_generic_kinds) + 1, NULL);

@ And "any sort of list":

@<Create the unchecked list kind@> =
	inter_ti operands[2];
	operands[0] = InterSymbolsTable::id_from_symbol_at_bookmark(
		&in_generic_kinds, unchecked_kind_symbol);
	operands[1] = InterSymbolsTable::id_from_symbol_at_bookmark(
		&in_generic_kinds, unchecked_kind_symbol);
	inter_symbol *unchecked_list_symbol =
		InterSymbolsTable::create_with_unique_name(
			InterBookmark::scope(&in_generic_kinds), I"K_unchecked_list");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTable::id_from_symbol(I, generic_kinds_p, unchecked_list_symbol),
		LIST_IDT, 0, LIST_ICON, 1, operands,
		(inter_ti) InterBookmark::baseline(&in_generic_kinds) + 1, NULL);

@ It's safe to say that we are likely to need these, too. (Note that they do not
correspond to Inform 7 kinds, even though |K_number| and |K_truth_state| will
end up being basically the same thing.)

@<Create the integer kind@> =
	inter_symbol *integer_kind_symbol =
		InterSymbolsTable::create_with_unique_name(
			InterBookmark::scope(&in_generic_kinds), I"K_int32");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTable::id_from_symbol(I, generic_kinds_p, integer_kind_symbol),
		INT32_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) InterBookmark::baseline(&in_generic_kinds) + 1, NULL);

@<Create the boolean kind@> =
	inter_symbol *boolean_kind_symbol =
		InterSymbolsTable::create_with_unique_name(
			InterBookmark::scope(&in_generic_kinds), I"K_int2");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTable::id_from_symbol(I, generic_kinds_p, boolean_kind_symbol),
		INT2_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) InterBookmark::baseline(&in_generic_kinds) + 1, NULL);

@<Create the string kind@> =
	inter_symbol *string_kind_symbol =
		InterSymbolsTable::create_with_unique_name(
			InterBookmark::scope(&in_generic_kinds), I"K_string");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTable::id_from_symbol(I, generic_kinds_p, string_kind_symbol),
		TEXT_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) InterBookmark::baseline(&in_generic_kinds) + 1, NULL);
