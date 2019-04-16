[InterNames::] Inter Namespace.

@

=
typedef struct name_iterator {
	struct text_stream *prototype;
	int counter;
} name_iterator;

@

@e UNIQUE_FUSAGE from 1
@e UNIQUE_PER_NAMESPACE_FUSAGE
@e MANY_PER_NAMESPACE_FUSAGE
@e DERIVED_FUSAGE

=
typedef struct inter_namespace {
	struct text_stream *namespace_prefix;
	struct text_stream *unmarked_prefix;
	int exporting;
	MEMORY_MANAGEMENT
} inter_namespace;

inter_namespace *root_namespace = NULL;

typedef struct inter_name_family {
	int fusage;
	struct text_stream *family_name;
	struct inter_name_consumption_token *first_ict;
	struct inter_name_family *derivative_of;
	struct text_stream *derived_prefix;
	struct text_stream *derived_suffix;
	int mark_exports;
	MEMORY_MANAGEMENT
} inter_name_family;

typedef struct inter_name_consumption_token {
	struct inter_namespace *for_namespace;
	int no_consumed;
	struct inter_name_consumption_token *next_ict;
	MEMORY_MANAGEMENT
} inter_name_consumption_token;

typedef struct inter_name {
	struct inter_namespace *namespace;
	struct inter_name_family *family;
	int unique_number;
	struct inter_symbol *symbol;
	struct package_request *eventual_owner;
	struct text_stream *memo;
	struct text_stream *override;
	struct inter_name *derived_from;
	struct inter_name **parametrised_derivatives;
	struct compilation_module *declared_in;
	int to_mark;
	MEMORY_MANAGEMENT
} inter_name;

@ =
inter_namespace *InterNames::new_namespace(text_stream *prefix) {
	inter_namespace *S = CREATE(inter_namespace);
	S->namespace_prefix = Str::duplicate(prefix);
	S->unmarked_prefix = Str::duplicate(prefix);
	S->exporting = FALSE;
	return S;
}

inter_namespace *InterNames::root(void) {
	if (root_namespace == NULL) root_namespace = InterNames::new_namespace(NULL);
	return root_namespace;
}

inter_name_family *InterNames::new_family(int fu, text_stream *name) {
	inter_name_family *F = CREATE(inter_name_family);
	F->fusage = fu;
	F->family_name = Str::duplicate(name);
	F->first_ict = NULL;
	F->derivative_of = NULL;
	F->derived_prefix = NULL;
	F->derived_suffix = NULL;
	F->mark_exports = TRUE;
	return F;
}

inter_name_consumption_token *InterNames::new_ict(inter_namespace *S) {
	if (S == NULL) internal_error("no namespace");
	inter_name_consumption_token *T = CREATE(inter_name_consumption_token);
	T->for_namespace = S;
	T->no_consumed = 1;
	T->next_ict = NULL;
	return T;
}

inter_name *InterNames::new_in_space(inter_namespace *S, inter_name_family *F, int suppress_count) {
	if (S == NULL) internal_error("no namespace");
	if (F == NULL) internal_error("no family");
	inter_name *N = CREATE(inter_name);
	N->namespace = S;
	N->family = F;
	N->unique_number = 0;
	if (F->fusage == UNIQUE_FUSAGE) internal_error("not a family name");
	if ((F->fusage != DERIVED_FUSAGE) && (suppress_count == FALSE)) {
		inter_name_consumption_token *ict = F->first_ict;
		if (ict == NULL) {
			F->first_ict = InterNames::new_ict(S);
			N->unique_number = 1;
		} else {
			while (ict) {
				if (ict->for_namespace == S) {
					if (F->fusage == UNIQUE_PER_NAMESPACE_FUSAGE) internal_error("one per namespace, please");
					N->unique_number = ++ict->no_consumed;
					break;
				}
				if (ict->next_ict == NULL) {
					ict->next_ict = InterNames::new_ict(S);
					N->unique_number = 1;
					break;
				}
				ict = ict->next_ict;
			}
		}
	}
	N->symbol = NULL;
	N->memo = NULL;
	N->override = NULL;
	N->derived_from = NULL;
	N->parametrised_derivatives = NULL;
	N->declared_in = NULL;
	N->to_mark = 0;
	N->eventual_owner = Hierarchy::main();
	return N;
}

inter_name *InterNames::one_off(text_stream *name, package_request *R) {
	inter_name_family *F = InterNames::new_family(UNIQUE_FUSAGE, name);
	inter_name *N = CREATE(inter_name);
	N->namespace = InterNames::root();
	N->family = F;
	N->unique_number = 1;
	N->symbol = NULL;
	N->memo = NULL;
	N->override = NULL;
	N->derived_from = NULL;
	N->parametrised_derivatives = NULL;
	N->declared_in = NULL;
	N->to_mark = 0;
	N->eventual_owner = R;
	return N;
}

void InterNames::attach_memo(inter_name *N, wording W) {
	if (N->symbol) internal_error("too late to attach memo");
	N->memo = Str::new();
	int c = 0;
	LOOP_THROUGH_WORDING(j, W) {
		/* identifier is at this point 32 chars or fewer in length: add at most 30 more */
		if (c++ > 0) WRITE_TO(N->memo, " ");
		if (Wide::len(Lexer::word_text(j)) > 30)
			WRITE_TO(N->memo, "etc");
		else WRITE_TO(N->memo, "%N", j);
		if (Str::len(N->memo) > 32) break;
	}
	Str::truncate(N->memo, 28); /* it was at worst 62 chars in size, but is now truncated to 28 */
	Identifiers::purify(N->memo);
	TEMPORARY_TEXT(NBUFF);
	WRITE_TO(NBUFF, "%n", N);
	int L = Str::len(NBUFF);
	DISCARD_TEXT(NBUFF);
	if (L > 28) Str::truncate(N->memo, Str::len(N->memo) - (L - 28));
}

inter_symbol *InterNames::to_symbol(inter_name *N) {
	if (N->symbol) {
		if (N->to_mark) Inter::Symbols::set_flag(N->symbol, N->to_mark);
		return N->symbol;
	}
	TEMPORARY_TEXT(NBUFF);
	WRITE_TO(NBUFF, "%n", N);
	inter_symbols_table *T = Packaging::scope(Emit::repository(), N);
	N->symbol = Emit::new_symbol(T, NBUFF);
	DISCARD_TEXT(NBUFF);
	if (N->to_mark) Inter::Symbols::set_flag(N->symbol, N->to_mark);
	return N->symbol;
}

text_stream *InterNames::to_text(inter_name *N) {
	if (N == NULL) return NULL;
	return InterNames::to_symbol(N)->symbol_name;
}

inter_symbol *InterNames::define_symbol(inter_name *N) {
	InterNames::to_symbol(N);
	if (N->symbol) {
		if (Inter::Symbols::is_predeclared(N->symbol)) {
			Inter::Symbols::undefine(N->symbol);
		}
	}
	if ((N->symbol) && (Inter::Symbols::read_annotation(N->symbol, HOLDING_IANN) == 1)) {
		if (Inter::Symbols::read_annotation(N->symbol, DELENDA_EST_IANN) != 1) {
			Emit::annotate_symbol_i(N->symbol, DELENDA_EST_IANN, 1);
			Inter::Symbols::strike_definition(N->symbol);
		}
		return N->symbol;
	}
	return N->symbol;
}

inter_symbol *InterNames::destroy_symbol(inter_name *N) {
	InterNames::to_symbol(N);
	if (N->symbol) {
		if (Inter::Symbols::is_predeclared(N->symbol)) {
			Inter::Symbols::undefine(N->symbol);
		}
	}
	if ((N->symbol) && (Inter::Symbols::read_annotation(N->symbol, HOLDING_IANN) == 1)) {
		if (Inter::Symbols::read_annotation(N->symbol, DELENDA_EST_IANN) != 1) {
			Emit::annotate_symbol_i(N->symbol, DELENDA_EST_IANN, 1);
			Inter::Symbols::strike_definition(N->symbol);
		}
		return N->symbol;
	} else if (Inter::Symbols::read_annotation(N->symbol, DELENDA_EST_IANN) != 1) internal_error("Bang");
	return N->symbol;
}

void InterNames::writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_name *N = (inter_name *) vI;
	if (N == NULL) WRITE("<no-inter-name>");
	else {
		if ((N->family == NULL) || (N->namespace == NULL)) internal_error("bad inter_name");
		if (Str::len(N->override) > 0) { WRITE("%S", N->override); return; }
		text_stream *NP = N->namespace->namespace_prefix;
		if (N->family->mark_exports == FALSE) NP = N->namespace->unmarked_prefix;
		switch (N->family->fusage) {
			case DERIVED_FUSAGE:
				WRITE("%S", N->family->derived_prefix);
				InterNames::writer(OUT, format_string, N->derived_from);
				WRITE("%S", N->family->derived_suffix);
				break;
			case UNIQUE_FUSAGE:
				WRITE("%S", N->family->family_name);
				break;
			case UNIQUE_PER_NAMESPACE_FUSAGE:
				if (Str::len(NP) > 0) WRITE("%S_", NP);
				WRITE("%S", N->family->family_name);
				break;
			case MANY_PER_NAMESPACE_FUSAGE:
				if (Str::len(NP) > 0) WRITE("%S_", NP);
				WRITE("%S%d", N->family->family_name, N->unique_number);
				break;
			default: internal_error("unknown fusage");
		}
		if (N->memo) WRITE("_%S", N->memo);
	}
}

void InterNames::annotate_i(inter_name *iname, inter_t annot_ID, inter_t V) {
	if (iname) Emit::annotate_symbol_i(InterNames::to_symbol(iname), annot_ID, V);
}

void InterNames::annotate_t(inter_name *iname, inter_t annot_ID, text_stream *text) {
	if (iname) Emit::annotate_symbol_t(InterNames::to_symbol(iname), annot_ID, text);
}

void InterNames::annotate_w(inter_name *iname, inter_t annot_ID, wording W) {
	if (iname) Emit::annotate_symbol_w(InterNames::to_symbol(iname), annot_ID, W);
}

int InterNames::read_annotation(inter_name *iname, inter_t annot) {
	return Inter::Symbols::read_annotation(InterNames::to_symbol(iname), annot);
}

void InterNames::holster(value_holster *VH, inter_name *iname) {
	if (Holsters::data_acceptable(VH)) {
		inter_t v1 = 0, v2 = 0;
		inter_reading_state *IRS = Emit::IRS();
		InterNames::to_ival(IRS->read_into, IRS->current_package, &v1, &v2, iname);
		Holsters::holster_pair(VH, v1, v2);
	}
}

void InterNames::to_ival(inter_repository *I, inter_package *pack, inter_t *val1, inter_t *val2, inter_name *iname) {
	inter_symbol *S = InterNames::to_symbol(iname);
	if (S) { Inter::Symbols::to_data(I, pack, S, val1, val2); return; }
	*val1 = LITERAL_IVAL; *val2 = 0;
}

int InterNames::defined(inter_name *iname) {
	if (iname == NULL) return FALSE;
	inter_symbol *S = InterNames::to_symbol(iname);
	if (Inter::Symbols::is_defined(S)) return TRUE;
	return FALSE;
}

@

@e INVALID_INAMEF from 0

@e ACTION_BASE_INAMEF
@e ACTION_BITMAP_PROPERTY_VALUE_INAMEF
@e ACTION_INAMEF
@e ACTION_ROUTINE_INAMEF
@e ACTION_STV_FRAME_CREATOR_INAMEF
@e ACTIVITY_INAMEF
@e ACTIVITY_STV_FRAME_CREATOR_INAMEF
@e ADJECTIVAL_TASK_ROUTINE_INAMEF
@e ADJECTIVE_DEFINED_INAMEF
@e AGREE_ADJECTIVE_INAMEF
@e BACKDROP_FOUND_IN_INAMEF
@e BACKDROP_FOUND_IN_ROUTINE_INAMEF
@e CLOSURE_INAMEF
@e CONJUGATE_VERB_FORM_INAMEF
@e CONJUGATE_VERB_ROUTINE_INAMEF
@e CONJUGATIONS_INAMEF
@e CONSULT_GRAMMAR_INAMEF
@e DEFAULT_VALUE_INAMEF
@e DEFERRED_PROPOSITION_ROUTINE_INAMEF
@e DEFERRED_PROPOSITION_RTP_INAMEF
@e DIRECTION_OBJECT_INAMEF
@e EQUATION_ROUTINE_INAMEF
@e EXTERNAL_FILE_INAMEF
@e FORMAL_PAR_INAMEF
@e GPR_FOR_EITHER_OR_PROPERTY_INAMEF
@e GPR_FOR_INSTANCE_INAMEF
@e GPR_FOR_KIND_INAMEF
@e GPR_FOR_TOKEN_INAMEF
@e GRAMMAR_LINE_COND_TOKEN_INAMEF
@e GRAMMAR_LINE_MISTAKE_TOKEN_INAMEF
@e GRAMMAR_PARSE_NAME_ROUTINE_INAMEF
@e GRAMMAR_SLASH_GPR_INAMEF
@e IFID_ARRAY_INAMEF
@e INSTANCE_INAMEF
@e KERNEL_ROUTINE_INAMEF
@e KIND_DECREMENT_ROUTINE_INAMEF
@e KIND_ID_INAMEF
@e KIND_INAMEF
@e KIND_INCREMENT_ROUTINE_INAMEF
@e KIND_RANDOM_ROUTINE_INAMEF
@e LIST_TOGETHER_ARRAY_INAMEF
@e LIST_TOGETHER_ROUTINE_INAMEF
@e LITERAL_LIST_INAMEF
@e LITERAL_TEXT_INAMEF
@e LITERAL_TEXT_SBA_INAMEF
@e LOOP_OVER_SCOPE_ROUTINE_INAMEF
@e MEASUREMENT_ADJECTIVE_INAMEF
@e NAME_PROPERTY_STORAGE_INAMEF
@e NAMED_ACTION_PATTERN_INAMEF
@e NOUN_FILTER_INAMEF
@e PACKAGE_INAMEF
@e PARSE_NAME_ROUTINE_INAMEF
@e PAST_ACTION_ROUTINE_INAMEF
@e PHRASE_INAMEF
@e PHRASE_REQUEST_INAMEF
@e PRINTING_ROUTINE_INAMEF
@e PROPERTY_INAMEF
@e REGION_FOUND_IN_ROUTINE_INAMEF
@e RELATION_BY_ROUTINE_INAMEF
@e RELATION_GUARD_F0_INAMEF
@e RELATION_GUARD_F1_INAMEF
@e RELATION_GUARD_MAKE_FALSE_INAMEF
@e RELATION_GUARD_MAKE_TRUE_INAMEF
@e RELATION_GUARD_TEST_INAMEF
@e RELATION_HANDLER_INAMEF
@e RELATION_INITIALISER_ROUTINE_INAMEF
@e RELATION_RECORD_INAMEF
@e RELATION_RELS_BM_INAMEF
@e RESPONSE_ROUTINE_INAMEF
@e RESPONSE_VALUE_INAMEF
@e RESPONSE_CONSTANT_INAMEF
@e ROUTINE_BLOCK_INAMEF
@e RULE_SHELL_ROUTINE_INAMEF
@e RULEBOOK_INAMEF
@e RULEBOOK_NAMED_OPTION_INAMEF
@e RULEBOOK_STV_FRAME_CREATOR_INAMEF
@e SCOPE_FILTER_INAMEF
@e SHORT_NAME_PROPERTY_ROUTINE_INAMEF
@e SHORT_NAME_ROUTINE_INAMEF
@e TABLE_COLUMN_INAMEF
@e TABLE_INAMEF
@e TEST_REQS_INAMEF
@e TEST_TEXTS_INAMEF
@e TEXT_ROUTINE_INAMEF
@e TEXT_SUBSTITUTION_INAMEF
@e TO_PHRASE_INAMEF
@e TWO_SIDED_DOOR_DOOR_DIR_INAMEF
@e TWO_SIDED_DOOR_DOOR_TO_INAMEF
@e TWO_SIDED_DOOR_FOUND_IN_INAMEF
@e V2V_BITMAP_INAMEF
@e V2V_ROUTE_CACHE_INAMEF
@e VARIABLE_INAMEF
@e VERB_DECLARATION_ARRAY_INAMEF
@e FIRST_INSTANCE_INAMEF
@e COUNT_INSTANCE_INAMEF
@e NEXT_INSTANCE_INAMEF
@e LABEL_BASE_INAMEF
@e LABEL_STORAGE_INAMEF
@e ICOUNT_CONSTANT_INAMEF
@e WEAK_ID_CONSTANT_INAMEF

@e FINAL_INAMEF

=
inter_name *InterNames::new(int fnum) {
	inter_name_family *F = InterNames::get_family(fnum);
	return InterNames::new_in_space(InterNames::root(), F, FALSE);
}

inter_name *InterNames::new_in(int fnum, compilation_module *C) {
	if (C == NULL) return InterNames::new(fnum);
	inter_name_family *F = InterNames::get_family(fnum);
	inter_name *iname = InterNames::new_in_space(C->namespace, F, FALSE);
	InterNames::mark(F, iname, C);
	return iname;
}

void InterNames::mark(inter_name_family *F, inter_name *iname, compilation_module *C) {
	iname->declared_in = C;
}

compilation_module *InterNames::to_module(inter_name *iname) {
	if (iname == NULL) return NULL;
	return iname->declared_in;
}

inter_name *InterNames::new_fixed(int fnum, int no) {
	inter_name_family *F = InterNames::get_family(fnum);
	inter_name *N = InterNames::new_in_space(InterNames::root(), F, FALSE);
	N->unique_number = no;
	return N;
}

inter_name *InterNames::new_overridden(int fnum, text_stream *identifier) {
	inter_name_family *F = InterNames::get_family(fnum);
	inter_name *N = InterNames::new_in_space(InterNames::root(), F, FALSE);
	N->override = Str::duplicate(identifier);
	return N;
}

inter_name *InterNames::new_derived(int fnum, inter_name *from) {
	inter_name_family *F = InterNames::get_family(fnum);
	if (F->fusage != DERIVED_FUSAGE) internal_error("not a derived family");
//	if (from->family != F->derivative_of) {
//		LOG("From = %n in $X\n", from, Packaging::home_of(from));
//		LOG("From family %S but derivative should be of %S\n", from->family->family_name, F->derivative_of->family_name);
//		internal_error("derived from name of wrong family");
//	}
	inter_name *N = InterNames::new_in_space(InterNames::root(), F, TRUE);
	Packaging::house_with(N, from);
	N->derived_from = from;
	compilation_module *C = InterNames::to_module(from);
	InterNames::mark(F, N, C);
	return N;
}

inter_name *InterNames::icount_name(kind *K) {
	TEMPORARY_TEXT(ICN);
	WRITE_TO(ICN, "ICOUNT_");
	Kinds::Textual::write(ICN, K);
	Str::truncate(ICN, 31);
	LOOP_THROUGH_TEXT(pos, ICN) {
		Str::put(pos, Characters::toupper(Str::get(pos)));
		if (Characters::isalnum(Str::get(pos)) == FALSE) Str::put(pos, '_');
	}
	Emit::main_render_unique(Emit::main_scope(), ICN);
	inter_name *iname = InterNames::new_overridden(ICOUNT_CONSTANT_INAMEF, ICN);
	DISCARD_TEXT(ICN);
	return iname;
}

inter_name *InterNames::constructed_kind_name(kind *K) {
	package_request *R2 = Kinds::Behaviour::package(K);
	wording W;
	TEMPORARY_TEXT(KT);
	Kinds::Textual::write(KT, K);
	W = Feeds::feed_stream(KT);
	DISCARD_TEXT(KT);
	inter_name *iname = NULL;
	if (Kinds::Compare::lt(K, K_object)) {
		iname = InterNames::new_fixed(KIND_INAMEF, Kinds::RunTime::I6_classnumber(K));
		if (Wordings::nonempty(W)) InterNames::attach_memo(iname, W);
	} else {
		TEMPORARY_TEXT(TO);
		Identifiers::compose_numberless(TO, I"K", W);
		iname = InterNames::new_overridden(KIND_INAMEF, TO);
		DISCARD_TEXT(TO);
	}
	iname->eventual_owner = R2;
	Hierarchy::make_available(iname);
	return iname;
}

inter_name *InterNames::label_base_name(text_stream *name) {
	inter_name *iname = InterNames::new_overridden(LABEL_BASE_INAMEF, name);
	return iname;
}

inter_name *InterNames::template_weak_ID_name(text_stream *name) {
	inter_name *iname = InterNames::new_overridden(WEAK_ID_CONSTANT_INAMEF, name);
	return iname;
}

void InterNames::translate(inter_name *iname, text_stream *text) {
	Emit::translate(iname, text);
}

@

@e FIRST_INSTANCE_INDERIV from 26
@e COUNT_INSTANCE_INDERIV
@e NEXT_INSTANCE_INDERIV

@e FINAL_INDERIV

inter_name *InterNames::letter_parametrised_name(int family, inter_name *rname, int marker, package_request *R) {
	if (rname == NULL) internal_error("can't parametrise null name");
	if (rname->parametrised_derivatives == NULL) {
		rname->parametrised_derivatives =
			Memory::I7_calloc(FINAL_INDERIV, sizeof(inter_name *), INTER_SYMBOLS_MREASON);
		for (int i=0; i<FINAL_INDERIV; i++) rname->parametrised_derivatives[i] = NULL;
	}
	if ((marker < 0) || (marker >= FINAL_INDERIV)) internal_error("respomse parameter out of range");
	if (rname->parametrised_derivatives[marker] == NULL) {
		rname->parametrised_derivatives[marker] = InterNames::new(family);
		Packaging::house(rname->parametrised_derivatives[marker], R);
		rname->parametrised_derivatives[marker]->derived_from = rname;
	}

	if (family == NEXT_INSTANCE_INAMEF) {
		InterNames::to_symbol(rname->parametrised_derivatives[marker]);
	}

	return rname->parametrised_derivatives[marker];
}

void InterNames::override_action_base_iname(inter_name *ab_iname, text_stream *to) {
	ab_iname->override = Str::duplicate(to);
}

void InterNames::override_count_iname(inter_name *count_iname, int N) {
	if (N <= 10) {
		count_iname->override = Str::new();
		WRITE_TO(count_iname->override, "IK%d_Count", N);
	}
}

@ =
inter_name_family *inter_name_families[FINAL_INAMEF+1];

inter_name_family *InterNames::get_family(int fnum) {
	if ((fnum < 1) || (fnum >= FINAL_INAMEF)) internal_error("fnum out of range");
	if (inter_name_families[fnum]) return inter_name_families[fnum];
	text_stream *S = NULL;
	int D = -1, mark_exports = TRUE;
	text_stream *Pre = NULL, *Suf = NULL;
	switch (fnum) {
		case ACTION_BASE_INAMEF:					S = I"A";					break;
		case ACTION_BITMAP_PROPERTY_VALUE_INAMEF:	S = I"ActionBitmapPV";		break;
		case ACTION_INAMEF:							D = ACTION_BASE_INAMEF; Pre = I"##"; break;
		case ACTION_ROUTINE_INAMEF:					D = ACTION_BASE_INAMEF; Suf = I"Sub"; break;
		case ACTION_STV_FRAME_CREATOR_INAMEF:		S = I"ANSTVC";				break;
		case ACTIVITY_INAMEF:						S = I"V";					break;
		case ACTIVITY_STV_FRAME_CREATOR_INAMEF:		S = I"AVSTVC";				break;
		case ADJECTIVE_DEFINED_INAMEF:				S = I"ADJDEFN";				break;
		case ADJECTIVAL_TASK_ROUTINE_INAMEF:		D = AGREE_ADJECTIVE_INAMEF; Suf = I"Task"; break;
		case AGREE_ADJECTIVE_INAMEF:				S = I"Adj";	break;
		case BACKDROP_FOUND_IN_INAMEF:				S = I"BD_found_in_storage";	break;
		case BACKDROP_FOUND_IN_ROUTINE_INAMEF:		S = I"FI_for_I";			break;
		case CLOSURE_INAMEF:						S = I"Closure";				break;
		case CONJUGATE_VERB_FORM_INAMEF:			S = I"ConjugateVerbForm";	break;
		case CONJUGATE_VERB_ROUTINE_INAMEF:			S = I"ConjugateVerb";		break;
		case CONJUGATIONS_INAMEF:					S = I"conjugations";		break;
		case CONSULT_GRAMMAR_INAMEF:				S = I"Consult_Grammar";	break;
		case COUNT_INSTANCE_INAMEF:					D = KIND_INAMEF; Suf = I"_Count"; break;
		case DEFAULT_VALUE_INAMEF:					S = I"DV";					break;
		case DEFERRED_PROPOSITION_ROUTINE_INAMEF:	S = I"Prop";	break;
		case DEFERRED_PROPOSITION_RTP_INAMEF:		S = I"PROP_SRC";			break;
		case DIRECTION_OBJECT_INAMEF:				S = I"DirectionObject";		break;
		case EQUATION_ROUTINE_INAMEF:				S = I"Q";					break;
		case EXTERNAL_FILE_INAMEF:					S = I"X";					break;
		case FIRST_INSTANCE_INAMEF:					D = KIND_INAMEF; Suf = I"_First"; break;
		case FORMAL_PAR_INAMEF:						S = I"formal_par";			break;
		case GPR_FOR_EITHER_OR_PROPERTY_INAMEF:		S = I"PRN_PN";				break;
		case GPR_FOR_INSTANCE_INAMEF:				S = I"Instance_GPR";		break;
		case GPR_FOR_KIND_INAMEF:					S = I"Kind_GPR";			break;
		case GPR_FOR_TOKEN_INAMEF:					S = I"GPR_Line";			break;
		case GRAMMAR_LINE_COND_TOKEN_INAMEF:		S = I"Cond_Token";			break;
		case GRAMMAR_LINE_MISTAKE_TOKEN_INAMEF:		S = I"Mistake_Token";		break;
		case GRAMMAR_PARSE_NAME_ROUTINE_INAMEF:		S = I"Parse_Name_GV";		break;
		case GRAMMAR_SLASH_GPR_INAMEF:				S = I"SlashGPR";			break;
		case ICOUNT_CONSTANT_INAMEF:				S = I"always_overridden";	break;
		case IFID_ARRAY_INAMEF:						S = I"IFID_ARRAY";			break;
		case INSTANCE_INAMEF:						S = I"I";					break;
		case KERNEL_ROUTINE_INAMEF:					S = I"KERNEL"; break;
		case KIND_DECREMENT_ROUTINE_INAMEF:			D = PRINTING_ROUTINE_INAMEF; Pre = I"B_"; break;
		case KIND_ID_INAMEF:						S = I"KD";					break;
		case KIND_INAMEF:							S = I"K";					break;
		case KIND_INCREMENT_ROUTINE_INAMEF:			D = PRINTING_ROUTINE_INAMEF; Pre = I"A_"; break;
		case KIND_RANDOM_ROUTINE_INAMEF:			D = PRINTING_ROUTINE_INAMEF; Pre = I"R_"; break;
		case LABEL_BASE_INAMEF:						S = I"always_overridden";	break;
		case LABEL_STORAGE_INAMEF:					D = LABEL_BASE_INAMEF; Pre = I"I7_ST_"; break;
		case LIST_TOGETHER_ARRAY_INAMEF:			S = I"LTR";					break;
		case LIST_TOGETHER_ROUTINE_INAMEF:			S = I"LTR_R";				break;
		case LITERAL_LIST_INAMEF:					S = I"LIST_CONST"; break;
		case LITERAL_TEXT_INAMEF:					S = I"TX_PS";	break;
		case LITERAL_TEXT_SBA_INAMEF:				S = I"TX_L";	break;
		case LOOP_OVER_SCOPE_ROUTINE_INAMEF:		S = I"LOS";					break;
		case MEASUREMENT_ADJECTIVE_INAMEF:			S = I"MADJ_Test";			break;
		case NAME_PROPERTY_STORAGE_INAMEF:			S = I"name_storage";		break;
		case NAMED_ACTION_PATTERN_INAMEF:			S = I"NAP";					break;
		case NEXT_INSTANCE_INAMEF:					D = KIND_INAMEF; Suf = I"_Next"; break;
		case NOUN_FILTER_INAMEF:					S = I"Noun_Filter";			break;
		case PACKAGE_INAMEF:						S = I"package";				break;
		case PARSE_NAME_ROUTINE_INAMEF:				S = I"PN_for_S";			break;
		case PAST_ACTION_ROUTINE_INAMEF:			S = I"PAPR";				break;
		case PHRASE_INAMEF:							S = I"R";		break;
		case PHRASE_REQUEST_INAMEF:					S = I"REQ";	break;
		case PRINTING_ROUTINE_INAMEF:				S = I"E";					break;
		case PROPERTY_INAMEF:						S = I"P"; mark_exports = FALSE; break;
		case REGION_FOUND_IN_ROUTINE_INAMEF:		S = I"RFI_for_I";			break;
		case RELATION_BY_ROUTINE_INAMEF:			S = I"Relation";			break;
		case RELATION_GUARD_F0_INAMEF:				S = I"RGuard_f0";			break;
		case RELATION_GUARD_F1_INAMEF:				S = I"RGuard_f1";			break;
		case RELATION_GUARD_MAKE_FALSE_INAMEF:		S = I"RGuard_MF";			break;
		case RELATION_GUARD_MAKE_TRUE_INAMEF:		S = I"RGuard_MT";			break;
		case RELATION_GUARD_TEST_INAMEF:			S = I"RGuard_T";			break;
		case RELATION_HANDLER_INAMEF:				S = I"Rel_Handler";			break;
		case RELATION_INITIALISER_ROUTINE_INAMEF:	S = I"InitialiseRelation";	break;
		case RELATION_RECORD_INAMEF:				S = I"Rel_Record";			break;
		case RELATION_RELS_BM_INAMEF:				S = I"Relation_RELS_BM";	break;
		case RESPONSE_CONSTANT_INAMEF:				S = I"RESP";	break;
		case RESPONSE_ROUTINE_INAMEF:				D = RESPONSE_VALUE_INAMEF; Suf = I"_R";	break;
		case RESPONSE_VALUE_INAMEF:					S = I"TX_R";	break;
		case ROUTINE_BLOCK_INAMEF:					S = I"RBLK";	break;
		case RULE_SHELL_ROUTINE_INAMEF:				S = I"I6_Rule_Shell";		break;
		case RULEBOOK_INAMEF:						S = I"B";					break;
		case RULEBOOK_NAMED_OPTION_INAMEF:			S = I"RBNO";				break;
		case RULEBOOK_STV_FRAME_CREATOR_INAMEF:		S = I"RBSTVC";				break;
		case SCOPE_FILTER_INAMEF:					S = I"Scope_Filter";		break;
		case SHORT_NAME_PROPERTY_ROUTINE_INAMEF:	S = I"SN_R_A";				break;
		case SHORT_NAME_ROUTINE_INAMEF:				S = I"SN_R";				break;
		case TABLE_COLUMN_INAMEF:					S = I"TC";					break;
		case TABLE_INAMEF:							S = I"T";					break;
		case TEST_REQS_INAMEF:						S = I"TestReq";				break;
		case TEST_TEXTS_INAMEF:						S = I"TestText";			break;
		case TEXT_ROUTINE_INAMEF:					D = TEXT_SUBSTITUTION_INAMEF; Pre = I"R_"; break;
		case TEXT_SUBSTITUTION_INAMEF:				S = I"TX_S";	break;
		case TO_PHRASE_INAMEF:						S = I"PHR";					break;
		case TWO_SIDED_DOOR_DOOR_DIR_INAMEF:		S = I"TSD_door_dir_value";	break;
		case TWO_SIDED_DOOR_DOOR_TO_INAMEF:			S = I"TSD_door_to_value";	break;
		case TWO_SIDED_DOOR_FOUND_IN_INAMEF:		S = I"TSD_found_in_value";	break;
		case V2V_BITMAP_INAMEF:						S = I"V2V_Bitmap";			break;
		case V2V_ROUTE_CACHE_INAMEF:				S = I"V2V_Route_Cache";		break;
		case VARIABLE_INAMEF:						S = I"V";					break;
		case VERB_DECLARATION_ARRAY_INAMEF:			S = I"GV_Grammar";			break;
		case WEAK_ID_CONSTANT_INAMEF:				S = I"always_overridden";	break;
	}

	if ((S) || (D >= 0)) {
		int fusage = MANY_PER_NAMESPACE_FUSAGE;
		if (D >= 0) fusage = DERIVED_FUSAGE;
		inter_name_families[fnum] = InterNames::new_family(fusage, S);
		if (D >= 0) {
			inter_name_families[fnum]->derivative_of = inter_name_families[D];
			inter_name_families[fnum]->derived_prefix = Str::duplicate(Pre);
			inter_name_families[fnum]->derived_suffix = Str::duplicate(Suf);
		}
		inter_name_families[fnum]->mark_exports = mark_exports;
	} else internal_error("nameless namespace family");
	return inter_name_families[fnum];
}


