[Inter::Canon::] Canonical Annotations.

Defining the one true set of Inter annotation codes.

@

@e INVALID_IANN from 0

@e PROPERTY_NAME_IANN
@e INNER_PROPERTY_NAME_IANN
@e HEX_IANN
@e SIGNED_IANN
@e CALL_PARAMETER_IANN
@e IMPLIED_CALL_PARAMETER_IANN

@e ACTION_IANN
@e APPEND_IANN
@e ARROW_COUNT_IANN
@e ASSIMILATED_IANN
@e BIP_CODE_IANN
@e BUFFERARRAY_IANN
@e BYTEARRAY_IANN
@e DECLARATION_ORDER_IANN
@e EITHER_OR_IANN
@e ENCLOSING_IANN
@e FAKE_ACTION_IANN
@e OBJECT_IANN
@e INLINE_ARRAY_IANN
@e METAVERB_IANN
@e NOUN_FILTER_IANN
@e OBJECT_KIND_COUNTER_IANN
@e SCOPE_FILTER_IANN
@e SOURCE_ORDER_IANN
@e TABLEARRAY_IANN
@e VERBARRAY_IANN
@e EXPLICIT_VARIABLE_IANN
@e TEXT_LITERAL_IANN
@e ARCHITECTURAL_IANN
@e VENEER_IANN
@e SYNOPTIC_IANN
@e I6_GLOBAL_OFFSET_IANN
@e C_ARRAY_ADDRESS_IANN

@ =
void Inter::Canon::declare(void) {
	invalid_IAF = Inter::Annotations::form(INVALID_IANN, I"__invalid", INTEGER_IATYPE);

	name_IAF = Inter::Annotations::form(PROPERTY_NAME_IANN, I"__property_name", TEXTUAL_IATYPE);
	inner_pname_IAF = Inter::Annotations::form(INNER_PROPERTY_NAME_IANN, I"__inner_property_name", TEXTUAL_IATYPE);
	Inter::Annotations::form(HEX_IANN, I"__hex", INTEGER_IATYPE);
	Inter::Annotations::form(SIGNED_IANN, I"__signed", INTEGER_IATYPE);
	Inter::Annotations::form(CALL_PARAMETER_IANN, I"__call_parameter", INTEGER_IATYPE);
	Inter::Annotations::form(IMPLIED_CALL_PARAMETER_IANN, I"__implied_call_parameter", INTEGER_IATYPE);

	Inter::Annotations::form(ACTION_IANN, I"__action", INTEGER_IATYPE);
	Inter::Annotations::form(APPEND_IANN, I"__append", TEXTUAL_IATYPE);
	Inter::Annotations::form(ARROW_COUNT_IANN, I"__arrow_count", INTEGER_IATYPE);
	Inter::Annotations::form(ASSIMILATED_IANN, I"__assimilated", INTEGER_IATYPE);
	Inter::Annotations::form(BIP_CODE_IANN, I"__bip", INTEGER_IATYPE);
	Inter::Annotations::form(BUFFERARRAY_IANN, I"__buffer_array", INTEGER_IATYPE);
	Inter::Annotations::form(BYTEARRAY_IANN, I"__byte_array", INTEGER_IATYPE);
	Inter::Annotations::form(DECLARATION_ORDER_IANN, I"__declaration_order", INTEGER_IATYPE);
	Inter::Annotations::form(EITHER_OR_IANN, I"__either_or", INTEGER_IATYPE);
	Inter::Annotations::form(ENCLOSING_IANN, I"__enclosing", INTEGER_IATYPE);
	Inter::Annotations::form(FAKE_ACTION_IANN, I"__fake_action", INTEGER_IATYPE);
	Inter::Annotations::form(OBJECT_IANN, I"__object", INTEGER_IATYPE);
	Inter::Annotations::form(INLINE_ARRAY_IANN, I"__inline_array", INTEGER_IATYPE);
	Inter::Annotations::form(METAVERB_IANN, I"__meta_verb", INTEGER_IATYPE);
	Inter::Annotations::form(NOUN_FILTER_IANN, I"__noun_filter", INTEGER_IATYPE);
	Inter::Annotations::form(OBJECT_KIND_COUNTER_IANN, I"__object_kind_counter", INTEGER_IATYPE);
	Inter::Annotations::form(SCOPE_FILTER_IANN, I"__scope_filter", INTEGER_IATYPE);
	Inter::Annotations::form(SOURCE_ORDER_IANN, I"__source_order", INTEGER_IATYPE);
	Inter::Annotations::form(TABLEARRAY_IANN, I"__table_array", INTEGER_IATYPE);
	Inter::Annotations::form(VERBARRAY_IANN, I"__verb", INTEGER_IATYPE);
	Inter::Annotations::form(EXPLICIT_VARIABLE_IANN, I"__explicit_variable", INTEGER_IATYPE);
	Inter::Annotations::form(TEXT_LITERAL_IANN, I"__text_literal", INTEGER_IATYPE);
	Inter::Annotations::form(ARCHITECTURAL_IANN, I"__architectural", INTEGER_IATYPE);
	Inter::Annotations::form(VENEER_IANN, I"__veneer", INTEGER_IATYPE);
	Inter::Annotations::form(SYNOPTIC_IANN, I"__synoptic", INTEGER_IATYPE);
	Inter::Annotations::form(I6_GLOBAL_OFFSET_IANN, I"__global_offset", INTEGER_IATYPE);
	Inter::Annotations::form(C_ARRAY_ADDRESS_IANN, I"__array_address", INTEGER_IATYPE);
}
