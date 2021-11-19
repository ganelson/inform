[NewStage::] New Stage.

This stage takes an empty (or wiped) repository and equips it with just the
absolute basics, so that it is ready to have substantive material added
at a later stage.

@ =
void NewStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"new", NewStage::run, NO_STAGE_ARG, FALSE);
}

int NewStage::run(pipeline_step *step) {
	inter_architecture *current_architecture = PipelineModule::get_architecture();
	if (current_architecture == NULL) internal_error("no architecture set");
	int Z = Architectures::is_16_bit(current_architecture);
	int D = Architectures::debug_enabled(current_architecture);

	inter_tree *I = step->ephemera.repository;
	@<Make the main package@>;
	@<Add another few package types which we will need when linking@>;

	inter_package *main_p = Site::main_package(I);
	inter_bookmark in_main = Inter::Bookmarks::at_end_of_this_package(main_p);
	inter_package *generic_p = NULL, *generic_kinds_p = NULL;
	Inter::Package::new_package_named(&in_main, I"generic", FALSE,
		PackageTypes::get(I, I"_module"), 1, NULL, &generic_p);
	inter_bookmark in_generic = Inter::Bookmarks::at_end_of_this_package(generic_p);
	Inter::Package::new_package_named(&in_generic, I"kinds", FALSE,
		PackageTypes::get(I, I"_submodule"), 1, NULL, &generic_kinds_p);
	inter_bookmark in_generic_kinds = Inter::Bookmarks::at_end_of_this_package(generic_kinds_p);

	inter_symbol *unchecked_kind_symbol = NULL;
	@<Create the unchecked kind@>;
	@<Create the unchecked function kind@>;
	@<Create the unchecked list kind@>;
	@<Create the integer kind@>;
	@<Create the boolean kind@>;
	@<Create the string kind@>;

	@<Define some architecture constants@>;
	return TRUE;
}

@ The following creates the |main| package and the package types |_plain|,
|_code| and |_linkage| -- which are needed for the //building// module to
function.

@<Make the main package@> =
	Packaging::outside_all_packages(I);

@ There are then further package types whose use is a matter of convention,
as far as //building// is concerned, but which this //pipeline// module relies on.

@<Add another few package types which we will need when linking@> =
	PackageTypes::get(I, I"_module");
	PackageTypes::get(I, I"_submodule");
	PackageTypes::get(I, I"_function");
	PackageTypes::get(I, I"_action");
	PackageTypes::get(I, I"_command");
	PackageTypes::get(I, I"_property");
	PackageTypes::get(I, I"_to_phrase");
	PackageTypes::get(I, I"_response");

@ The package |main/generic/kinds| contains some rudimentary Inter kinds of data.
(See also //runtime: Emit//, where a matching set is made by the Inform 7 compiler
when it builds an Inter tree: we want to keep this minimum set matching.)

To begin with, the definition of |K_unchecked|, the Inter kind which means "any
base data type matches this".

@<Create the unchecked kind@> =
	unchecked_kind_symbol =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(&in_generic_kinds), I"K_unchecked");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTables::id_from_symbol(I, generic_kinds_p, unchecked_kind_symbol),
		UNCHECKED_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) Inter::Bookmarks::baseline(&in_generic_kinds) + 1, NULL);

@ And this expresses the idea of "any sort of function":

@<Create the unchecked function kind@> =
	inter_ti operands[2];
	operands[0] = InterSymbolsTables::id_from_IRS_and_symbol(
		&in_generic_kinds, unchecked_kind_symbol);
	operands[1] = InterSymbolsTables::id_from_IRS_and_symbol(
		&in_generic_kinds, unchecked_kind_symbol);
	inter_symbol *unchecked_function_symbol =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(&in_generic_kinds), I"K_unchecked_function");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTables::id_from_symbol(I, generic_kinds_p, unchecked_function_symbol),
		ROUTINE_IDT, 0, FUNCTION_ICON, 2, operands,
		(inter_ti) Inter::Bookmarks::baseline(&in_generic_kinds) + 1, NULL);

@ And "any sort of list":

@<Create the unchecked list kind@> =
	inter_ti operands[2];
	operands[0] = InterSymbolsTables::id_from_IRS_and_symbol(
		&in_generic_kinds, unchecked_kind_symbol);
	operands[1] = InterSymbolsTables::id_from_IRS_and_symbol(
		&in_generic_kinds, unchecked_kind_symbol);
	inter_symbol *unchecked_list_symbol =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(&in_generic_kinds), I"K_unchecked_list");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTables::id_from_symbol(I, generic_kinds_p, unchecked_list_symbol),
		LIST_IDT, 0, LIST_ICON, 1, operands,
		(inter_ti) Inter::Bookmarks::baseline(&in_generic_kinds) + 1, NULL);

@ It's safe to say that we are likely to need these, too. (Note that they do not
correspond to Inform 7 kinds, even though |K_number| and |K_truth_state| will
end up being basically the same thing.)

@<Create the integer kind@> =
	inter_symbol *integer_kind_symbol =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(&in_generic_kinds), I"K_int32");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTables::id_from_symbol(I, generic_kinds_p, integer_kind_symbol),
		INT32_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) Inter::Bookmarks::baseline(&in_generic_kinds) + 1, NULL);

@<Create the boolean kind@> =
	inter_symbol *boolean_kind_symbol =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(&in_generic_kinds), I"K_int2");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTables::id_from_symbol(I, generic_kinds_p, boolean_kind_symbol),
		INT2_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) Inter::Bookmarks::baseline(&in_generic_kinds) + 1, NULL);

@<Create the string kind@> =
	inter_symbol *string_kind_symbol =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(&in_generic_kinds), I"K_string");
	Inter::Kind::new(&in_generic_kinds,
		InterSymbolsTables::id_from_symbol(I, generic_kinds_p, string_kind_symbol),
		TEXT_IDT, 0, BASE_ICON, 0, NULL,
		(inter_ti) Inter::Bookmarks::baseline(&in_generic_kinds) + 1, NULL);

@ Lastly, we define the constants |WORDSIZE|, |DEBUG| (if applicable) and
either |TARGET_ZCODE| or |TARGET_GLULX|, as appropriate. These really now mean
"target 16-bit" or "target 32-bit", and their names are a hangover from when
Inform 7 could only work with Inform 6. The reason we need to define these
is so that if a kit is parsed from source and added to this tree, we will then
be able to resolve conditional compilation matter placed inside, e.g.,
|#ifdef TARGET_ZCODE;| ... |#endif;| directives.

For now, at least, these live in the package |main/veneer|.

@<Define some architecture constants@> =
	inter_bookmark *in_veneer = Site::veneer_bookmark(I);
	inter_package *veneer_p = Inter::Packages::veneer(I);
	inter_symbol *vi_unchecked =
		InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(in_veneer), I"K_unchecked");
	InterSymbolsTables::equate(vi_unchecked, unchecked_kind_symbol);

	inter_symbol *con_name = InterSymbolsTables::create_with_unique_name(
		Inter::Bookmarks::scope(in_veneer), I"WORDSIZE");
	Inter::Constant::new_numerical(in_veneer,
		InterSymbolsTables::id_from_symbol(I, veneer_p, con_name),
		InterSymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
		LITERAL_IVAL, (Z)?2:4,
		(inter_ti) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	inter_symbol *target_name = InterSymbolsTables::create_with_unique_name(
		Inter::Bookmarks::scope(in_veneer), (Z)?I"TARGET_ZCODE":I"TARGET_GLULX");
	Inter::Constant::new_numerical(in_veneer,
		InterSymbolsTables::id_from_symbol(I, veneer_p, target_name),
		InterSymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
		LITERAL_IVAL, 1,
		(inter_ti) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	if (D) {
		inter_symbol *D_name = InterSymbolsTables::create_with_unique_name(
			Inter::Bookmarks::scope(in_veneer), I"DEBUG");
		Inter::Constant::new_numerical(in_veneer,
			InterSymbolsTables::id_from_symbol(I, veneer_p, D_name),
			InterSymbolsTables::id_from_symbol(I, veneer_p, vi_unchecked),
			LITERAL_IVAL, 1,
			(inter_ti) Inter::Bookmarks::baseline(in_veneer) + 1, NULL);
	}
