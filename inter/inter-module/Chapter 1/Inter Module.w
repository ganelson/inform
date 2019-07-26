[InterModule::] Inter Module.

Setting up the use of this module.

@h Introduction.

@d INTER_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e inter_tree_MT
@e inter_tree_node_array_MT
@e inter_warehouse_MT
@e inter_warehouse_room_MT
@e inter_symbols_table_MT
@e inter_symbol_array_MT
@e inter_annotation_array_MT
@e inter_data_type_MT
@e inter_construct_MT
@e inter_annotation_form_MT
@e inter_error_location_MT
@e inter_error_message_MT
@e inter_error_stash_MT
@e inter_package_MT
@e inter_node_list_MT
@e inter_node_list_entry_MT

=
ALLOCATE_INDIVIDUALLY(inter_tree)
ALLOCATE_INDIVIDUALLY(inter_warehouse)
ALLOCATE_INDIVIDUALLY(inter_warehouse_room)
ALLOCATE_INDIVIDUALLY(inter_symbols_table)
ALLOCATE_INDIVIDUALLY(inter_data_type)
ALLOCATE_INDIVIDUALLY(inter_construct)
ALLOCATE_INDIVIDUALLY(inter_annotation_form)
ALLOCATE_INDIVIDUALLY(inter_error_location)
ALLOCATE_INDIVIDUALLY(inter_error_message)
ALLOCATE_INDIVIDUALLY(inter_error_stash)
ALLOCATE_INDIVIDUALLY(inter_package)
ALLOCATE_INDIVIDUALLY(inter_node_list)
ALLOCATE_INDIVIDUALLY(inter_node_list_entry)
ALLOCATE_IN_ARRAYS(inter_symbol, 1024)
ALLOCATE_IN_ARRAYS(inter_tree_node, 8192)
ALLOCATE_IN_ARRAYS(inter_annotation, 8192)

@h The beginning.
(The client doesn't need to call the start and end routines, because the
foundation module does that automatically.)

=
void InterModule::start(void) {
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	@<Register this module's command line switches@>;

	Inter::Defn::create_language();
	Inter::Types::create_all();
}

@

@e INTER_SYMBOLS_MREASON
@e INTER_BYTECODE_MREASON
@e INTER_LINKS_MREASON

@<Register this module's memory allocation reasons@> =
	Memory::reason_name(INTER_SYMBOLS_MREASON, "inter symbols storage");
	Memory::reason_name(INTER_BYTECODE_MREASON, "inter bytecode storage");
	Memory::reason_name(INTER_LINKS_MREASON, "inter links storage");

@<Register this module's stream writers@> =
	Writers::register_writer('t', &Inter::Textual::writer);
	Writers::register_writer('F', &Inter::Verify::writer);

@

@e INTER_FILE_READ_DA
@e INTER_MEMORY_DA
@e INTER_BINARY_DA
@e INTER_SYMBOLS_DA
@e INTER_FRAMES_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(INTER_MEMORY_DA, L"inter memory usage", FALSE, FALSE);
	Log::declare_aspect(INTER_FILE_READ_DA, L"intermediate file reading", FALSE, FALSE);
	Log::declare_aspect(INTER_BINARY_DA, L"inter binary", FALSE, FALSE);
	Log::declare_aspect(INTER_SYMBOLS_DA, L"inter symbols", FALSE, FALSE);
	Log::declare_aspect(INTER_FRAMES_DA, L"inter frames", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('3', Inter::Symbols::log);
	Writers::register_logger('4', Inter::SymbolsTables::log);
	Writers::register_logger('5', Inter::Bookmarks::log);
	Writers::register_logger('6', Inter::Packages::log);

@<Register this module's command line switches@> =
	;

@h The end.

=
void InterModule::end(void) {
}
