[BytecodeModule::] Bytecode Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d BYTECODE_MODULE TRUE

@ This module defines the following classes:

@e inter_tree_CLASS
@e inter_tree_node_CLASS
@e inter_warehouse_CLASS
@e inter_warehouse_room_CLASS
@e inter_symbols_table_CLASS
@e inter_symbol_CLASS
@e inter_annotation_CLASS
@e inter_construct_CLASS
@e inter_annotation_form_CLASS
@e inter_error_location_CLASS
@e inter_error_message_CLASS
@e inter_error_stash_CLASS
@e inter_package_CLASS
@e inter_node_list_CLASS
@e inter_node_array_CLASS

=
DECLARE_CLASS(inter_tree)
DECLARE_CLASS(inter_warehouse)
DECLARE_CLASS(inter_warehouse_room)
DECLARE_CLASS(inter_symbols_table)
DECLARE_CLASS(inter_construct)
DECLARE_CLASS(inter_annotation_form)
DECLARE_CLASS(inter_error_location)
DECLARE_CLASS(inter_error_message)
DECLARE_CLASS(inter_error_stash)
DECLARE_CLASS(inter_package)
DECLARE_CLASS(inter_node_list)
DECLARE_CLASS(inter_node_array)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(inter_symbol, 1024)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(inter_tree_node, 8192)
DECLARE_CLASS_ALLOCATED_IN_ARRAYS(inter_annotation, 8192)

@ Like all modules, this one must define a |start| and |end| function:

=
void BytecodeModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;

	InterConstruct::create_language();
	InterTypes::initialise_constructors();
}
void BytecodeModule::end(void) {
}

@

@e INTER_SYMBOLS_MREASON
@e INTER_BYTECODE_MREASON
@e INTER_LINKS_MREASON
@e TREE_LIST_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(INTER_SYMBOLS_MREASON, "inter symbols storage");
	Memory::reason_name(INTER_BYTECODE_MREASON, "inter bytecode storage");
	Memory::reason_name(INTER_LINKS_MREASON, "inter links storage");
	Memory::reason_name(TREE_LIST_MREASON, "inter tree location list storage");

@<Register this module's stream writers@> =
	Writers::register_writer('t', &TextualInter::writer);
	Writers::register_writer('F', &Inter::Verify::writer);

@

@e INTER_FILE_READ_DA
@e INTER_MEMORY_DA
@e INTER_BINARY_DA
@e INTER_SYMBOLS_DA
@e INTER_CONNECTORS_DA
@e CONSTANT_DEPTH_CALCULATION_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(INTER_MEMORY_DA, L"inter memory usage", FALSE, FALSE);
	Log::declare_aspect(INTER_FILE_READ_DA, L"intermediate file reading", FALSE, FALSE);
	Log::declare_aspect(INTER_BINARY_DA, L"inter binary", FALSE, FALSE);
	Log::declare_aspect(INTER_SYMBOLS_DA, L"inter symbols", FALSE, FALSE);
	Log::declare_aspect(INTER_CONNECTORS_DA, L"inter connectors", FALSE, FALSE);
	Log::declare_aspect(CONSTANT_DEPTH_CALCULATION_DA, L"constant depth calculation", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('3', InterSymbol::log);
	Writers::register_logger('4', InterSymbolsTable::log);
	Writers::register_logger('5', InterBookmark::log);
	Writers::register_logger('6', InterPackage::log);
