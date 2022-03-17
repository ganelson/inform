[Metadata::] Metadata.

Looking up metadata in special constants.

@ This section is in some ways a postscript to //The Constant Construct//. If
constants are created which have names matching...

=
int Metadata::valid_key(text_stream *key) {
	if (Str::get_at(key, 0) == '^') return TRUE;
	return FALSE;
}

@ ...then their symbols are given the |METADATA_KEY_ISYMF| flag: see
//InterSymbol::new_for_symbols_table//. These symbols never code-generate: see
//final: Vanilla Constants//. It follows that metadata cannot be part of the
program at runtime. Nor can metadata be wired to anything else, either way
round -- see //Wiring::wire_to//.

So the only purpose metadata can serve is to annotate the program, to assist
tools such as the //pipeline// module. Metadata helps with linking, optimisation,
and similar tasks.

Since metadata exists solely so that other parts of the Inform tool chain can
read its values, we clearly need an API for doing that, and this is the point
of the present section.

@ Some metadata keys are expected, and others are optional. The following
determines whether a given package |pack| contains a value for metadata |key|: 

=
inter_tree_node *Metadata::value_node(inter_package *pack, text_stream *key) {
	inter_symbol *md = InterSymbolsTable::symbol_from_name(InterPackage::scope(pack), key);
	if (md) return md->definition;
	return NULL;
}

int Metadata::exists(inter_package *pack, text_stream *key) {
	if (Metadata::value_node(pack, key)) return TRUE;
	return FALSE;
}

@ So for each kind of data we allow, we provide a required and an optional
version, which differ only in that the required version halts with an error
if the key is missing.

=
inter_ti Metadata::read_numeric(inter_package *pack, text_stream *key) {
	inter_tree_node *D = Metadata::value_node(pack, key);
	if (D) @<Extract the numeric value@>;
	Metadata::err("not defined", pack, key); return 0;
}

inter_ti Metadata::read_optional_numeric(inter_package *pack, text_stream *key) {
	inter_tree_node *D = Metadata::value_node(pack, key);
	if (D) @<Extract the numeric value@>;
	return 0;
}

@<Extract the numeric value@> =
	if (ConstantInstruction::list_format(D) == CONST_LIST_FORMAT_NONE) {
		inter_pair val = ConstantInstruction::constant(D);
		if (InterValuePairs::is_number(val) == FALSE)
			Metadata::err("not numeric", pack, key);
		return InterValuePairs::to_number(val);
	}
	
@ A metadata key cannot be wired to a symbol; but it can have its value set
to a symbol, so:

=
inter_symbol *Metadata::required_symbol(inter_package *pack, text_stream *key) {
	inter_tree_node *D = Metadata::value_node(pack, key);
	if (D) @<Extract the symbolic value@>;
	Metadata::err("required symbolic metadata not supplied", pack, key);
	return NULL;
}

inter_symbol *Metadata::optional_symbol(inter_package *pack, text_stream *key) {
	inter_tree_node *D = Metadata::value_node(pack, key);
	if (D) @<Extract the symbolic value@>;
	return NULL;
}

@<Extract the symbolic value@> =
	if ((D) && (ConstantInstruction::list_format(D) == CONST_LIST_FORMAT_NONE)) {
		inter_pair val = ConstantInstruction::constant(D);
		if (InterValuePairs::is_symbolic(val) == FALSE)
			Metadata::err("not symbolic", pack, key);
		return InterValuePairs::to_symbol_in(val, pack);
	}

@ Text:

=
text_stream *Metadata::required_textual(inter_package *pack, text_stream *key) {
	inter_tree_node *D = Metadata::value_node(pack, key);
	if (D) @<Extract the textual value@>;
	Metadata::err("required textual metadata not supplied", pack, key);
	return NULL;
}

text_stream *Metadata::optional_textual(inter_package *pack, text_stream *key) {
	inter_tree_node *D = Metadata::value_node(pack, key);
	if (D) @<Extract the textual value@>;
	return NULL;
}

@<Extract the textual value@> =
	if (ConstantInstruction::list_format(D) == CONST_LIST_FORMAT_NONE) {
		inter_pair val = ConstantInstruction::constant(D);
		if (InterValuePairs::is_text(val) == FALSE)
			Metadata::err("not textual", pack, key);
		return InterValuePairs::to_text(InterPackage::tree(pack), val);
	}
	
@ Lists (which are optional only, and return only as the node from which values
must then be extracted):

=
inter_tree_node *Metadata::optional_list(inter_package *pack, text_stream *key) {
	inter_tree_node *D = Metadata::value_node(pack, key);
	if ((D) && (ConstantInstruction::list_format(D) == CONST_LIST_FORMAT_WORDS))
		return D;
	return NULL;
}

@ Metadata errors are fatal:

=
void Metadata::err(char *err, inter_package *pack, text_stream *key) {
	WRITE_TO(STDERR, "Error on metadata '%S' in package '", key);
	InterPackage::write_URL(STDERR, pack);
	WRITE_TO(STDERR, "': %s\n", err);
	internal_error(err);
}
