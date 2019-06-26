[CodeGen::I6::] Generating Inform 6.

To generate I6 code from intermediate code.

@h Pipeline stage.

=
void CodeGen::I6::create_target(void) {
	code_generation_target *cgt = CodeGen::Targets::new(I"inform6");
	METHOD_ADD(cgt, BEGIN_GENERATION_MTID, CodeGen::I6::begin_generation);
	METHOD_ADD(cgt, GENERAL_SEGMENT_MTID, CodeGen::I6::general_segment);
	METHOD_ADD(cgt, TL_SEGMENT_MTID, CodeGen::I6::tl_segment);
	METHOD_ADD(cgt, DEFAULT_SEGMENT_MTID, CodeGen::I6::default_segment);
	METHOD_ADD(cgt, CONSTANT_SEGMENT_MTID, CodeGen::I6::constant_segment);
	METHOD_ADD(cgt, PROPERTY_SEGMENT_MTID, CodeGen::I6::property_segment);
	METHOD_ADD(cgt, DECLARE_PROPERTY_MTID, CodeGen::I6::declare_property);
}

@

@e pragmatic_matter_I7CGS from 0
@e attributes_at_eof_I7CGS
@e early_matter_I7CGS
@e text_literals_code_I7CGS
@e summations_at_eof_I7CGS
@e arrays_at_eof_I7CGS
@e main_matter_I7CGS
@e routines_at_eof_I7CGS
@e code_at_eof_I7CGS
@e verbs_at_eof_I7CGS

=
void CodeGen::I6::begin_generation(code_generation_target *cgt, code_generation *cg) {
	cg->segments[pragmatic_matter_I7CGS] = CodeGen::new_segment();
	cg->segments[attributes_at_eof_I7CGS] = CodeGen::new_segment();
	cg->segments[early_matter_I7CGS] = CodeGen::new_segment();
	cg->segments[text_literals_code_I7CGS] = CodeGen::new_segment();
	cg->segments[summations_at_eof_I7CGS] = CodeGen::new_segment();
	cg->segments[arrays_at_eof_I7CGS] = CodeGen::new_segment();
	cg->segments[main_matter_I7CGS] = CodeGen::new_segment();
	cg->segments[routines_at_eof_I7CGS] = CodeGen::new_segment();
	cg->segments[code_at_eof_I7CGS] = CodeGen::new_segment();
	cg->segments[verbs_at_eof_I7CGS] = CodeGen::new_segment();
}

int CodeGen::I6::general_segment(code_generation_target *cgt, inter_frame P) {
	switch (P.data[ID_IFLD]) {
		case CONSTANT_IST: {
			inter_symbol *con_name =
				Inter::SymbolsTables::symbol_from_frame_data(P, DEFN_CONST_IFLD);
			int choice = early_matter_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, LATE_IANN) == 1) choice = code_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BUFFERARRAY_IANN) == 1) choice = arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, BYTEARRAY_IANN) == 1) choice = arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, STRINGARRAY_IANN) == 1) choice = arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, TABLEARRAY_IANN) == 1) choice = arrays_at_eof_I7CGS;
			if (P.data[FORMAT_CONST_IFLD] == CONSTANT_INDIRECT_LIST) choice = arrays_at_eof_I7CGS;
			if (Inter::Symbols::read_annotation(con_name, VERBARRAY_IANN) == 1) choice = verbs_at_eof_I7CGS;
			if (Inter::Constant::is_routine(con_name)) choice = routines_at_eof_I7CGS;
			return choice;
		}
		case RESPONSE_IST:
			return early_matter_I7CGS;
		case PRAGMA_IST:
			return pragmatic_matter_I7CGS;
	}
	return CodeGen::I6::default_segment(cgt);
}

int CodeGen::I6::default_segment(code_generation_target *cgt) {
	return main_matter_I7CGS;
}
int CodeGen::I6::constant_segment(code_generation_target *cgt) {
	return early_matter_I7CGS;
}
int CodeGen::I6::property_segment(code_generation_target *cgt) {
	return attributes_at_eof_I7CGS;
}
int CodeGen::I6::tl_segment(code_generation_target *cgt) {
	return text_literals_code_I7CGS;
}

@ Because in I6 source code some properties aren't declared before use, it follows
that if not used by any object then they won't ever be created. This is a
problem since it means that I6 code can't refer to them, because it would need
to mention an I6 symbol which doesn't exist. To get around this, we create the
property names which don't exist as constant symbols with the harmless value
0; we do this right at the end of the compiled I6 code. (This is a standard I6
trick called "stubbing", these being "stub definitions".)

=
void CodeGen::I6::declare_property(code_generation_target *cgt, code_generation *gen, inter_symbol *prop_name, int used) {
	text_stream *name = CodeGen::name(prop_name);
	if (used) {
		WRITE_TO(CodeGen::seg(gen, attributes_at_eof_I7CGS), "Property %S;\n", prop_name->symbol_name);
	} else {
		WRITE_TO(CodeGen::seg(gen, code_at_eof_I7CGS), "#ifndef %S; Constant %S = 0; #endif;\n", name, name);
	}
}
