[BytecodeModule::] Bytecode Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d BYTECODE_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

=
void BytecodeModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;

	InterInstruction::create_language();
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
	Writers::register_writer('F', &InterInstruction::instruction_writer);

@

@e INTER_FILE_READ_DA
@e INTER_MEMORY_DA
@e INTER_BINARY_DA
@e INTER_SYMBOLS_DA
@e INTER_CONNECTORS_DA
@e CONSTANT_DEPTH_CALCULATION_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(INTER_MEMORY_DA, U"inter memory usage", FALSE, FALSE);
	Log::declare_aspect(INTER_FILE_READ_DA, U"intermediate file reading", FALSE, FALSE);
	Log::declare_aspect(INTER_BINARY_DA, U"inter binary", FALSE, FALSE);
	Log::declare_aspect(INTER_SYMBOLS_DA, U"inter symbols", FALSE, FALSE);
	Log::declare_aspect(INTER_CONNECTORS_DA, U"inter connectors", FALSE, FALSE);
	Log::declare_aspect(CONSTANT_DEPTH_CALCULATION_DA, U"constant depth calculation", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('3', InterSymbol::log);
	Writers::register_logger('4', InterSymbolsTable::log);
	Writers::register_logger('5', InterBookmark::log);
	Writers::register_logger('6', InterPackage::log);
