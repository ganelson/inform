[Inter::Canon::] Canonical Annotations.

Defining the one true set of Inter annotation codes.

@

@e INVALID_IANN from 0

@e PROPERTY_NAME_IANN
@e HEX_IANN
@e SIGNED_IANN
@e CALL_PARAMETER_IANN
@e IMPLIED_CALL_PARAMETER_IANN

@e ACTION_IANN
@e APPEND_IANN
@e ARROW_COUNT_IANN
@e ASSIMILATED_IANN
@e ATTRIBUTE_IANN
@e BIP_CODE_IANN
@e BUFFERARRAY_IANN
@e BYTEARRAY_IANN
@e DECLARATION_ORDER_IANN
@e DELENDA_EST_IANN
@e EITHER_OR_IANN
@e ENCLOSING_IANN
@e FAKE_ACTION_IANN
@e OBJECT_IANN
@e HOLDING_IANN
@e INLINE_ARRAY_IANN
@e LATE_IANN
@e METAVERB_IANN
@e NOUN_FILTER_IANN
@e OBJECT_KIND_COUNTER_IANN
@e RTO_IANN
@e SCOPE_FILTER_IANN
@e SOURCE_ORDER_IANN
@e STRINGARRAY_IANN
@e TABLEARRAY_IANN
@e VERBARRAY_IANN
@e WEAK_ID_IANN
@e EXPLICIT_ATTRIBUTE_IANN
@e EXPLICIT_VARIABLE_IANN
@e TEXT_LITERAL_IANN
@e VENEER_IANN

@ And also the canonical set of bits to use in the flags word for an Inter
symbol.

@d LABEL_ISYMT    0x00000000
@d MISC_ISYMT     0x00000001
@d PACKAGE_ISYMT  0x00000002
@d PTYPE_ISYMT    0x00000003
@d SYMBOL_TYPE_MASK_ISYMT 0x00000003

@d PRIVATE_ISYMS  0x00000000
@d PUBLIC_ISYMS   0x00000004
@d EXTERNAL_ISYMS 0x00000008
@d PLUG_ISYMS     0x0000000C
@d SOCKET_ISYMS   0x00000010
@d SYMBOL_SCOPE_MASK_ISYMT 0x0000001C

@d TRAVERSE_MARK_BIT  		0x00000020
@d ATTRIBUTE_MARK_BIT 		0x00000040
@d VPH_MARK_BIT       		0x00000080
@d USED_MARK_BIT      		0x00000100
@d MAKE_NAME_UNIQUE   		0x00000200
@d ERROR_ISSUED_MARK_BIT	0x00000400

@d NONTRANSIENT_SYMBOL_BITS (MAKE_NAME_UNIQUE + SYMBOL_TYPE_MASK_ISYMT + SYMBOL_SCOPE_MASK_ISYMT)

@ =
void Inter::Canon::declare(void) {
	invalid_IAF = Inter::Annotations::form(INVALID_IANN, I"__invalid", FALSE);

	name_IAF = Inter::Annotations::form(PROPERTY_NAME_IANN, I"__property_name", TRUE);
	Inter::Annotations::form(HEX_IANN, I"__hex", FALSE);
	Inter::Annotations::form(SIGNED_IANN, I"__signed", FALSE);
	Inter::Annotations::form(CALL_PARAMETER_IANN, I"__call_parameter", FALSE);
	Inter::Annotations::form(IMPLIED_CALL_PARAMETER_IANN, I"__implied_call_parameter", FALSE);

	Inter::Annotations::form(ACTION_IANN, I"__action", FALSE);
	Inter::Annotations::form(APPEND_IANN, I"__append", TRUE);
	Inter::Annotations::form(ARROW_COUNT_IANN, I"__arrow_count", FALSE);
	Inter::Annotations::form(ASSIMILATED_IANN, I"__assimilated", FALSE);
	Inter::Annotations::form(ATTRIBUTE_IANN, I"__attribute", FALSE);
	Inter::Annotations::form(BIP_CODE_IANN, I"__bip", FALSE);
	Inter::Annotations::form(BUFFERARRAY_IANN, I"__buffer_array", FALSE);
	Inter::Annotations::form(BYTEARRAY_IANN, I"__byte_array", FALSE);
	Inter::Annotations::form(DECLARATION_ORDER_IANN, I"__declaration_order", FALSE);
	Inter::Annotations::form(DELENDA_EST_IANN, I"__delenda_est", FALSE);
	Inter::Annotations::form(EITHER_OR_IANN, I"__either_or", FALSE);
	Inter::Annotations::form(ENCLOSING_IANN, I"__enclosing", FALSE);
	Inter::Annotations::form(FAKE_ACTION_IANN, I"__fake_action", FALSE);
	Inter::Annotations::form(OBJECT_IANN, I"__object", FALSE);
	Inter::Annotations::form(HOLDING_IANN, I"__holding", FALSE);
	Inter::Annotations::form(INLINE_ARRAY_IANN, I"__inline_array", FALSE);
	Inter::Annotations::form(LATE_IANN, I"__late", FALSE);
	Inter::Annotations::form(METAVERB_IANN, I"__meta_verb", FALSE);
	Inter::Annotations::form(NOUN_FILTER_IANN, I"__noun_filter", FALSE);
	Inter::Annotations::form(OBJECT_KIND_COUNTER_IANN, I"__object_kind_counter", FALSE);
	Inter::Annotations::form(RTO_IANN, I"__rto", FALSE);
	Inter::Annotations::form(SCOPE_FILTER_IANN, I"__scope_filter", FALSE);
	Inter::Annotations::form(SOURCE_ORDER_IANN, I"__source_order", FALSE);
	Inter::Annotations::form(STRINGARRAY_IANN, I"__string_array", FALSE);
	Inter::Annotations::form(TABLEARRAY_IANN, I"__table_array", FALSE);
	Inter::Annotations::form(VERBARRAY_IANN, I"__verb", FALSE);
	Inter::Annotations::form(WEAK_ID_IANN, I"__weak_ID", FALSE);
	Inter::Annotations::form(EXPLICIT_ATTRIBUTE_IANN, I"__explicit_attribute", FALSE);
	Inter::Annotations::form(EXPLICIT_VARIABLE_IANN, I"__explicit_variable", FALSE);
	Inter::Annotations::form(TEXT_LITERAL_IANN, I"__text_literal", FALSE);
	Inter::Annotations::form(VENEER_IANN, I"__veneer", FALSE);
}
