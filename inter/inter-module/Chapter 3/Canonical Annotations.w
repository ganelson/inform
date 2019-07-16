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

@d TRAVERSE_MARK_BIT 1
@d ATTRIBUTE_MARK_BIT 2
@d VPH_MARK_BIT 4
@d USED_MARK_BIT 16
@d MAKE_NAME_UNIQUE 32
@d EXTERN_TARGET_BIT 64
@d ALIAS_ONLY_BIT 128

@ =
inter_annotation_form *invalid_IAF = NULL;
inter_annotation_form *name_IAF = NULL;

void Inter::Canon::declare(void) {
	invalid_IAF = Inter::Defn::create_annotation(INVALID_IANN, I"__invalid", FALSE);

	name_IAF = Inter::Defn::create_annotation(PROPERTY_NAME_IANN, I"__property_name", TRUE);
	Inter::Defn::create_annotation(HEX_IANN, I"__hex", FALSE);
	Inter::Defn::create_annotation(SIGNED_IANN, I"__signed", FALSE);
	Inter::Defn::create_annotation(CALL_PARAMETER_IANN, I"__call_parameter", FALSE);
	Inter::Defn::create_annotation(IMPLIED_CALL_PARAMETER_IANN, I"__implied_call_parameter", FALSE);

	Inter::Defn::create_annotation(ACTION_IANN, I"__action", FALSE);
	Inter::Defn::create_annotation(ARROW_COUNT_IANN, I"__arrow_count", FALSE);
	Inter::Defn::create_annotation(ASSIMILATED_IANN, I"__assimilated", FALSE);
	Inter::Defn::create_annotation(ATTRIBUTE_IANN, I"__attribute", FALSE);
	Inter::Defn::create_annotation(BIP_CODE_IANN, I"__bip", FALSE);
	Inter::Defn::create_annotation(BUFFERARRAY_IANN, I"__buffer_array", FALSE);
	Inter::Defn::create_annotation(BYTEARRAY_IANN, I"__byte_array", FALSE);
	Inter::Defn::create_annotation(DECLARATION_ORDER_IANN, I"__declaration_order", FALSE);
	Inter::Defn::create_annotation(DELENDA_EST_IANN, I"__delenda_est", FALSE);
	Inter::Defn::create_annotation(EITHER_OR_IANN, I"__either_or", FALSE);
	Inter::Defn::create_annotation(ENCLOSING_IANN, I"__enclosing", FALSE);
	Inter::Defn::create_annotation(FAKE_ACTION_IANN, I"__fake_action", FALSE);
	Inter::Defn::create_annotation(OBJECT_IANN, I"__object", FALSE);
	Inter::Defn::create_annotation(HOLDING_IANN, I"__holding", FALSE);
	Inter::Defn::create_annotation(INLINE_ARRAY_IANN, I"__inline_array", FALSE);
	Inter::Defn::create_annotation(LATE_IANN, I"__late", FALSE);
	Inter::Defn::create_annotation(METAVERB_IANN, I"__meta_verb", FALSE);
	Inter::Defn::create_annotation(NOUN_FILTER_IANN, I"__noun_filter", FALSE);
	Inter::Defn::create_annotation(OBJECT_KIND_COUNTER_IANN, I"__object_kind_counter", FALSE);
	Inter::Defn::create_annotation(RTO_IANN, I"__rto", FALSE);
	Inter::Defn::create_annotation(SCOPE_FILTER_IANN, I"__scope_filter", FALSE);
	Inter::Defn::create_annotation(SOURCE_ORDER_IANN, I"__source_order", FALSE);
	Inter::Defn::create_annotation(STRINGARRAY_IANN, I"__string_array", FALSE);
	Inter::Defn::create_annotation(TABLEARRAY_IANN, I"__table_array", FALSE);
	Inter::Defn::create_annotation(VERBARRAY_IANN, I"__verb", FALSE);
	Inter::Defn::create_annotation(WEAK_ID_IANN, I"__weak_ID", FALSE);
	Inter::Defn::create_annotation(EXPLICIT_ATTRIBUTE_IANN, I"__explicit_attribute", FALSE);
	Inter::Defn::create_annotation(EXPLICIT_VARIABLE_IANN, I"__explicit_variable", FALSE);
	Inter::Defn::create_annotation(TEXT_LITERAL_IANN, I"__text_literal", FALSE);
	Inter::Defn::create_annotation(VENEER_IANN, I"__veneer", FALSE);
}
