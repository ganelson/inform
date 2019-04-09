[InterNames::] Inter Namespace.

@

@e UNIQUE_FUSAGE from 1
@e UNIQUE_PER_NAMESPACE_FUSAGE
@e MANY_PER_NAMESPACE_FUSAGE
@e DERIVED_FUSAGE
@e EXTERN_FUSAGE

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
	int cache_me;
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
	F->cache_me = FALSE;
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
	N->eventual_owner = Packaging::request_main();
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
			case EXTERN_FUSAGE:
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
@e CASTER_ROUTINE_INAMEF
@e CLOSURE_INAMEF
@e COMPARISON_ROUTINE_INAMEF
@e CONJUGATE_VERB_FORM_INAMEF
@e CONJUGATE_VERB_ROUTINE_INAMEF
@e CONJUGATIONS_INAMEF
@e CONSULT_GRAMMAR_INAMEF
@e DEFAULT_VALUE_INAMEF
@e DEFERRED_PROPOSITION_ROUTINE_INAMEF
@e DEFERRED_PROPOSITION_RTP_INAMEF
@e DIRECTION_OBJECT_INAMEF
@e DISTINGUISHER_ROUTINE_INAMEF
@e EQUATION_ROUTINE_INAMEF
@e EXTERN_FORMAL_PAR_INAMEF
@e EXTERN_GPR_ROUTINE_INAMEF
@e EXTERN_INSTANCE_OR_KIND_INAMEF
@e EXTERN_MISCELLANEOUS_INAMEF
@e EXTERN_RESPONSE_ROUTINE_INAMEF
@e EXTERN_TOKEN_ROUTINE_INAMEF
@e EXTERNAL_FILE_INAMEF
@e EXTERNALLY_DEFINED_PHRASE_INAMEF
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
@e RECOGNISER_ROUTINE_INAMEF
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
@e SCHEMA_NAMED_ROUTINE_INAMEF
@e SCOPE_FILTER_INAMEF
@e SHORT_NAME_PROPERTY_ROUTINE_INAMEF
@e SHORT_NAME_ROUTINE_INAMEF
@e SUPPORT_ROUTINE_INAMEF
@e TABLE_COLUMN_INAMEF
@e TABLE_INAMEF
@e TEMPLATE_RESPONSE_INAMEF
@e TEST_REQS_INAMEF
@e TEST_TEXTS_INAMEF
@e TEXT_ROUTINE_INAMEF
@e TEXT_SUBSTITUTION_INAMEF
@e TO_PHRASE_INAMEF
@e TRACE_PRINTING_ROUTINE_INAMEF
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
	if ((C) && (C->allocation_id == 1) && (F->cache_me)) InterNames::cache(iname);
}

void InterNames::cache(inter_name *iname) {
	iname->to_mark = SR_CACHE_MARK_BIT;
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

inter_name *InterNames::extern_name(int fnum, text_stream *name, kind *K) {
	if (Str::len(name) == 0) internal_error("null extern");

	inter_name *try = InterNames::find_by_name(name);
	if (try) return try;

	inter_name_family *F = InterNames::get_family(fnum);
	if (F->fusage != EXTERN_FUSAGE) internal_error("not an extern family");
	inter_name *N = InterNames::new_in_space(InterNames::root(), F, TRUE);
	N->override = Str::duplicate(name);
	if (K == NULL) K = K_value;
	N->symbol = Emit::extern(N->override, K);
	N->eventual_owner = Packaging::request_template();
	return N;
}

inter_name *InterNames::intern(int fnum, text_stream *name) {
	if (Str::len(name) == 0) internal_error("null intern");
LOG("INTERN: %S\n", name);
	inter_name_family *F = InterNames::get_family(fnum);
	if (F->fusage != EXTERN_FUSAGE) internal_error("not an extern family");
	inter_name *N = InterNames::new_in_space(InterNames::root(), F, TRUE);
	N->override = Str::duplicate(name);
	N->symbol = Emit::holding_symbol(Emit::main_scope(), N->override);
	return N;
}

inter_name *InterNames::new_derived(int fnum, inter_name *from) {
	inter_name_family *F = InterNames::get_family(fnum);
	if (F->fusage != DERIVED_FUSAGE) internal_error("not a derived family");
	if (from->family != F->derivative_of) internal_error("derived from name of wrong family");
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

inter_name *InterNames::letter_parametrised_name(int family, inter_name *rname, int marker) {
	if (rname == NULL) internal_error("can't parametrise null name");
	if (rname->parametrised_derivatives == NULL) {
		rname->parametrised_derivatives =
			Memory::I7_calloc(FINAL_INDERIV, sizeof(inter_name *), INTER_SYMBOLS_MREASON);
		for (int i=0; i<FINAL_INDERIV; i++) rname->parametrised_derivatives[i] = NULL;
	}
	if ((marker < 0) || (marker >= FINAL_INDERIV)) internal_error("respomse parameter out of range");
	if (rname->parametrised_derivatives[marker] == NULL) {
		compilation_module *C = InterNames::to_module(rname);
		rname->parametrised_derivatives[marker] = InterNames::new_in(family, C);
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
	int D = -1, XT = FALSE, cache = FALSE, mark_exports = TRUE;
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
		case ADJECTIVAL_TASK_ROUTINE_INAMEF:		D = AGREE_ADJECTIVE_INAMEF; Suf = I"Task"; cache = TRUE; break;
		case AGREE_ADJECTIVE_INAMEF:				S = I"Adj"; cache = TRUE;	break;
		case BACKDROP_FOUND_IN_INAMEF:				S = I"BD_found_in_storage";	break;
		case BACKDROP_FOUND_IN_ROUTINE_INAMEF:		S = I"FI_for_I";			break;
		case CASTER_ROUTINE_INAMEF:					XT = TRUE;					break;
		case CLOSURE_INAMEF:						S = I"Closure";				break;
		case COMPARISON_ROUTINE_INAMEF:				XT = TRUE;					break;
		case CONJUGATE_VERB_FORM_INAMEF:			S = I"ConjugateVerbForm";	break;
		case CONJUGATE_VERB_ROUTINE_INAMEF:			S = I"ConjugateVerb";		break;
		case CONJUGATIONS_INAMEF:					S = I"conjugations";		break;
		case CONSULT_GRAMMAR_INAMEF:				S = I"Consult_Grammar"; cache = TRUE;	break;
		case COUNT_INSTANCE_INAMEF:					D = KIND_INAMEF; Suf = I"_Count"; break;
		case DEFAULT_VALUE_INAMEF:					S = I"DV";					break;
		case DEFERRED_PROPOSITION_ROUTINE_INAMEF:	S = I"Prop"; cache = TRUE;	break;
		case DEFERRED_PROPOSITION_RTP_INAMEF:		S = I"PROP_SRC";			break;
		case DIRECTION_OBJECT_INAMEF:				S = I"DirectionObject";		break;
		case DISTINGUISHER_ROUTINE_INAMEF:			XT = TRUE;					break;
		case EQUATION_ROUTINE_INAMEF:				S = I"Q";					break;
		case EXTERN_FORMAL_PAR_INAMEF:				XT = TRUE;					break;
		case EXTERN_GPR_ROUTINE_INAMEF:				XT = TRUE;					break;
		case EXTERN_INSTANCE_OR_KIND_INAMEF:		XT = TRUE;					break;
		case EXTERN_MISCELLANEOUS_INAMEF:			XT = TRUE;					break;
		case EXTERN_RESPONSE_ROUTINE_INAMEF:		D = TEMPLATE_RESPONSE_INAMEF; Suf = I"M"; break;
		case EXTERN_TOKEN_ROUTINE_INAMEF:			XT = TRUE;					break;
		case EXTERNAL_FILE_INAMEF:					S = I"X";					break;
		case EXTERNALLY_DEFINED_PHRASE_INAMEF:		XT = TRUE;					break;
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
		case KERNEL_ROUTINE_INAMEF:					S = I"KERNEL"; cache = TRUE; break;
		case KIND_DECREMENT_ROUTINE_INAMEF:			D = PRINTING_ROUTINE_INAMEF; Pre = I"B_"; break;
		case KIND_ID_INAMEF:						S = I"KD";					break;
		case KIND_INAMEF:							S = I"K";					break;
		case KIND_INCREMENT_ROUTINE_INAMEF:			D = PRINTING_ROUTINE_INAMEF; Pre = I"A_"; break;
		case KIND_RANDOM_ROUTINE_INAMEF:			D = PRINTING_ROUTINE_INAMEF; Pre = I"R_"; break;
		case LABEL_BASE_INAMEF:						S = I"always_overridden";	break;
		case LABEL_STORAGE_INAMEF:					D = LABEL_BASE_INAMEF; Pre = I"I7_ST_"; break;
		case LIST_TOGETHER_ARRAY_INAMEF:			S = I"LTR";					break;
		case LIST_TOGETHER_ROUTINE_INAMEF:			S = I"LTR_R";				break;
		case LITERAL_LIST_INAMEF:					S = I"LIST_CONST"; cache = TRUE; break;
		case LITERAL_TEXT_INAMEF:					S = I"TX_PS"; cache = TRUE;	break;
		case LITERAL_TEXT_SBA_INAMEF:				S = I"TX_L"; cache = TRUE;	break;
		case LOOP_OVER_SCOPE_ROUTINE_INAMEF:		S = I"LOS";					break;
		case MEASUREMENT_ADJECTIVE_INAMEF:			S = I"MADJ_Test";			break;
		case NAME_PROPERTY_STORAGE_INAMEF:			S = I"name_storage";		break;
		case NAMED_ACTION_PATTERN_INAMEF:			S = I"NAP";					break;
		case NEXT_INSTANCE_INAMEF:					D = KIND_INAMEF; Suf = I"_Next"; break;
		case NOUN_FILTER_INAMEF:					S = I"Noun_Filter";			break;
		case PACKAGE_INAMEF:						S = I"package";				break;
		case PARSE_NAME_ROUTINE_INAMEF:				S = I"PN_for_S";			break;
		case PAST_ACTION_ROUTINE_INAMEF:			S = I"PAPR";				break;
		case PHRASE_INAMEF:							S = I"R"; cache = TRUE;		break;
		case PHRASE_REQUEST_INAMEF:					S = I"REQ"; cache = TRUE;	break;
		case PRINTING_ROUTINE_INAMEF:				S = I"E"; XT = TRUE;		break;
		case PROPERTY_INAMEF:						S = I"P"; mark_exports = FALSE; break;
		case RECOGNISER_ROUTINE_INAMEF:				XT = TRUE;					break;
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
		case RESPONSE_CONSTANT_INAMEF:				S = I"RESP"; cache = TRUE;	break;
		case RESPONSE_ROUTINE_INAMEF:				D = RESPONSE_VALUE_INAMEF; Suf = I"_R"; cache = TRUE;	break;
		case RESPONSE_VALUE_INAMEF:					S = I"TX_R"; cache = TRUE;	break;
		case ROUTINE_BLOCK_INAMEF:					S = I"RBLK"; cache = TRUE;	break;
		case RULE_SHELL_ROUTINE_INAMEF:				S = I"I6_Rule_Shell";		break;
		case RULEBOOK_INAMEF:						S = I"B";					break;
		case RULEBOOK_NAMED_OPTION_INAMEF:			S = I"RBNO";				break;
		case RULEBOOK_STV_FRAME_CREATOR_INAMEF:		S = I"RBSTVC";				break;
		case SCHEMA_NAMED_ROUTINE_INAMEF:			XT = TRUE;					break;
		case SCOPE_FILTER_INAMEF:					S = I"Scope_Filter";		break;
		case SHORT_NAME_PROPERTY_ROUTINE_INAMEF:	S = I"SN_R_A";				break;
		case SHORT_NAME_ROUTINE_INAMEF:				S = I"SN_R";				break;
		case SUPPORT_ROUTINE_INAMEF:				XT = TRUE;					break;
		case TABLE_COLUMN_INAMEF:					S = I"TC";					break;
		case TABLE_INAMEF:							S = I"T";					break;
		case TEMPLATE_RESPONSE_INAMEF:				XT = TRUE;					break;
		case TEST_REQS_INAMEF:						S = I"TestReq";				break;
		case TEST_TEXTS_INAMEF:						S = I"TestText";			break;
		case TEXT_ROUTINE_INAMEF:					D = TEXT_SUBSTITUTION_INAMEF; Pre = I"R_"; cache = TRUE; break;
		case TEXT_SUBSTITUTION_INAMEF:				S = I"TX_S"; cache = TRUE;	break;
		case TO_PHRASE_INAMEF:						S = I"PHR";					break;
		case TRACE_PRINTING_ROUTINE_INAMEF:			XT = TRUE;					break;
		case TWO_SIDED_DOOR_DOOR_DIR_INAMEF:		S = I"TSD_door_dir_value";	break;
		case TWO_SIDED_DOOR_DOOR_TO_INAMEF:			S = I"TSD_door_to_value";	break;
		case TWO_SIDED_DOOR_FOUND_IN_INAMEF:		S = I"TSD_found_in_value";	break;
		case V2V_BITMAP_INAMEF:						S = I"V2V_Bitmap";			break;
		case V2V_ROUTE_CACHE_INAMEF:				S = I"V2V_Route_Cache";		break;
		case VARIABLE_INAMEF:						S = I"V";					break;
		case VERB_DECLARATION_ARRAY_INAMEF:			S = I"GV_Grammar";			break;
		case WEAK_ID_CONSTANT_INAMEF:				S = I"always_overridden";	break;
	}

	if ((S) || (D >= 0) || (XT)) {
		int fusage = MANY_PER_NAMESPACE_FUSAGE;
		if (D >= 0) fusage = DERIVED_FUSAGE;
		if (XT) fusage = EXTERN_FUSAGE;
		inter_name_families[fnum] = InterNames::new_family(fusage, S);
		if (D >= 0) {
			inter_name_families[fnum]->derivative_of = inter_name_families[D];
			inter_name_families[fnum]->derived_prefix = Str::duplicate(Pre);
			inter_name_families[fnum]->derived_suffix = Str::duplicate(Suf);
		}
		if (cache) inter_name_families[fnum]->cache_me = TRUE;
		inter_name_families[fnum]->mark_exports = mark_exports;
	} else internal_error("nameless namespace family");
	return inter_name_families[fnum];
}

@

@e INVALID_EXNAMEF from 0

@e EMPTY_TEXT_PACKED_EXNAMEF
@e PACKED_TEXT_STORAGE_EXNAMEF
@e CONSTANT_PACKED_TEXT_STORAGE_EXNAMEF
@e CONSTANT_PERISHABLE_TEXT_STORAGE_EXNAMEF
@e EMPTYRELATIONHANDLER_EXNAMEF
@e HASHLISTRELATIONHANDLER_EXNAMEF
@e DOUBLEHASHSETRELATIONHANDLER_EXNAMEF
@e EMPTY_TABLE_EXNAMEF
@e TABLE_NOVALUE_EXNAMEF
@e AUXF_MAGIC_VALUE_EXNAMEF
@e AUXF_STATUS_IS_CLOSED_EXNAMEF
@e FOUND_EVERYWHERE_EXNAMEF
@e DECIMAL_NUMBER_EXNAMEF
@e DA_NAME_EXNAMEF
@e I7SFRAME_EXNAMEF
@e ALLOWINSHOWME_EXNAMEF
@e LISTOFTYSAY_EXNAMEF
@e LISTOFTYSETLENGTH_EXNAMEF
@e LISTOFTYINSERTITEM_EXNAMEF
@e TEXTTYSAY_EXNAMEF
@e TEXTTYCOMPARE_EXNAMEF
@e RELATIONTYNAME_EXNAMEF
@e RELATIONTYOTOOADJECTIVE_EXNAMEF
@e RELATIONTYOTOVADJECTIVE_EXNAMEF
@e RELATIONTYVTOOADJECTIVE_EXNAMEF
@e RELATIONTYSYMMETRICADJECTIVE_EXNAMEF
@e RELATIONTYEQUIVALENCEADJECTIVE_EXNAMEF
@e ROUNDOFFTIME_EXNAMEF
@e BLKVALUEFREEONSTACK_EXNAMEF
@e RESPONSEVIAACTIVITY_EXNAMEF
@e STACKFRAMECREATE_EXNAMEF
@e BLKVALUECOPY_EXNAMEF
@e BLKVALUECOPYAZ_EXNAMEF
@e BLKVALUECREATE_EXNAMEF
@e BLKVALUEERROR_EXNAMEF
@e BLKVALUEFREE_EXNAMEF
@e BLKVALUEWRITE_EXNAMEF
@e BLKVALUECREATEONSTACK_EXNAMEF
@e RULEBOOKFAILS_EXNAMEF
@e RULEBOOKSUCCEEDS_EXNAMEF
@e PRINTORRUN_EXNAMEF
@e DEBUGRULES_EXNAMEF
@e DBRULE_EXNAMEF
@e DEADFLAG_EXNAMEF
@e ACTION_EXNAMEF
@e ACTREQUESTER_EXNAMEF
@e NOUN_EXNAMEF
@e SECOND_EXNAMEF
@e INP1_EXNAMEF
@e INP2_EXNAMEF
@e ACTOR_EXNAMEF
@e PLAYER_EXNAMEF
@e LOCATION_EXNAMEF
@e SCENESTARTED_EXNAMEF
@e SCENEENDED_EXNAMEF
@e SCENESTATUS_EXNAMEF
@e SCENEENDINGS_EXNAMEF
@e SCENELATESTENDING_EXNAMEF
@e PARSEDNUMBER_EXNAMEF
@e SPECIALWORD_EXNAMEF
@e CONSULTFROM_EXNAMEF
@e CONSULTWORDS_EXNAMEF
@e THEDARK_EXNAMEF
@e GPRFAIL_EXNAMEF
@e GPRPREPOSITION_EXNAMEF
@e THETIME_EXNAMEF
@e UNDERSTANDASMISTAKENUMBER_EXNAMEF
@e REALLOCATION_EXNAMEF
@e ACTORLOCATION_EXNAMEF
@e INVENTORYSTAGE_EXNAMEF
@e CSTYLE_EXNAMEF
@e ENGLISHBIT_EXNAMEF
@e NOARTICLEBIT_EXNAMEF
@e NEWLINEBIT_EXNAMEF
@e INDENTBIT_EXNAMEF
@e SAYN_EXNAMEF
@e SAYP_EXNAMEF
@e SAYPC_EXNAMEF
@e UNICODETEMP_EXNAMEF
@e SUPPRESSTEXTSUBSTITUTION_EXNAMEF
@e LOCALPARKING_EXNAMEF
@e PARACONTENT_EXNAMEF
@e TESTREGIONALCONTAINMENT_EXNAMEF
@e THEEMPTYTABLE_EXNAMEF
@e KINDATOMIC_EXNAMEF
@e GETGNAOFOBJECT_EXNAMEF
@e GPROPERTY_EXNAMEF
@e FOLLOWRULEBOOK_EXNAMEF
@e WHENSCENEBEGINS_EXNAMEF
@e WHENSCENEENDS_EXNAMEF
@e GENERICVERBSUB_EXNAMEF
@e SHORTNAME_EXNAMEF
@e CAPSHORTNAME_EXNAMEF
@e RELATIONTEST_EXNAMEF
@e DEBUGSCENES_EXNAMEF
@e PRIORNAMEDLISTGENDER_EXNAMEF
@e LOSRV_EXNAMEF
@e EMPTYTEXTVALUE_EXNAMEF
@e MSTACK_EXNAMEF
@e MSTVO_EXNAMEF
@e MSTVON_EXNAMEF
@e RUNTIMEPROBLEM_EXNAMEF
@e RTPRELKINDVIOLATION_EXNAMEF
@e RTPRELMINIMAL_EXNAMEF
@e TESTSTART_EXNAMEF
@e PARSERERROR_EXNAMEF
@e PASTCHRONOLOGICALRECORD_EXNAMEF
@e PRESENTCHRONOLOGICALRECORD_EXNAMEF
@e RELFOLLOWVECTOR_EXNAMEF
@e RLANYGETX_EXNAMEF
@e RLANYCANGETX_EXNAMEF
@e RLANYCANGETY_EXNAMEF
@e RLISTALLX_EXNAMEF
@e RLISTALLY_EXNAMEF
@e RELSEMPTY_EXNAMEF
@e RRSTORAGE_EXNAMEF
@e RLNGETF_EXNAMEF
@e RELATIONEMPTYOTOO_EXNAMEF
@e RELATIONEMPTYEQUIV_EXNAMEF
@e RELATIONEMPTYVTOV_EXNAMEF
@e OTOVRELROUTETO_EXNAMEF
@e RELATIONRSHOWOTOO_EXNAMEF
@e RELATIONSHOWEQUIV_EXNAMEF
@e RELATIONSHOWOTOO_EXNAMEF
@e RELATIONSHOWVTOV_EXNAMEF
@e VTOORELROUTETO_EXNAMEF
@e VTOVRELROUTETO_EXNAMEF
@e PARAMETERVALUE_EXNAMEF
@e RULEBOOKPARBREAK_EXNAMEF
@e REASONTHEACTIONFAILED_EXNAMEF
@e LATESTRULERESULT_EXNAMEF
@e NUMBERTYABS_EXNAMEF
@e REALNUMBERTYABS_EXNAMEF
@e REALNUMBERTYCOMPARE_EXNAMEF
@e REALNUMBERTYSAY_EXNAMEF
@e REALNUMBERTYMINUS_EXNAMEF
@e REALNUMBERTYDIVIDE_EXNAMEF
@e REALNUMBERTYROOT_EXNAMEF
@e REALNUMBERTYCUBEROOT_EXNAMEF
@e GPRNUMBER_EXNAMEF
@e SCOPESTAGE_EXNAMEF
@e OBJECT_EXNAMEF
@e PLACEINSCOPE_EXNAMEF
@e SUPPRESSSCOPELOOPS_EXNAMEF
@e NEXTBESTETYPE_EXNAMEF
@e NOTINCONTEXTPE_EXNAMEF
@e DEFERREDCALLINGLIST_EXNAMEF
@e LISTITEMKOVF_EXNAMEF
@e LISTOFTYGETLENGTH_EXNAMEF
@e LISTOFTYGETITEM_EXNAMEF
@e LISTITEMBASE_EXNAMEF
@e PROPERTYTOBETOTALLED_EXNAMEF
@e PROPERTYLOOPSIGN_EXNAMEF
@e WN_EXNAMEF
@e NEXTWORDSTOPPED_EXNAMEF
@e PARSERACTION_EXNAMEF
@e PARSERTRACE_EXNAMEF
@e PARSERONE_EXNAMEF
@e PARSERTWO_EXNAMEF
@e DETECTPLURALWORD_EXNAMEF
@e PLURALFOUND_EXNAMEF
@e WORDINPROPERTY_EXNAMEF
@e NAME_EXNAMEF
@e ETYPE_EXNAMEF
@e REALNUMBERTYTIMES_EXNAMEF
@e REALNUMBERTYPLUS_EXNAMEF
@e REALNUMBERTYREMAINDER_EXNAMEF
@e REALNUMBERTYAPPROXIMATE_EXNAMEF
@e INTEGERDIVIDE_EXNAMEF
@e INTEGERREMAINDER_EXNAMEF
@e SQUAREROOT_EXNAMEF
@e CUBEROOT_EXNAMEF
@e REALNUMBERTYNAN_EXNAMEF
@e REALNUMBERTYNEGATE_EXNAMEF
@e REALNUMBERTYPOW_EXNAMEF
@e WORDADDRESS_EXNAMEF
@e WORDLENGTH_EXNAMEF
@e DIGITTOVALUE_EXNAMEF
@e THEN1WD_EXNAMEF
@e FLOATPARSE_EXNAMEF
@e FLOATNAN_EXNAMEF
@e ARTICLEDESCRIPTORS_EXNAMEF
@e CONTAINER_EXNAMEF
@e SUPPORTER_EXNAMEF
@e ANIMATE_EXNAMEF
@e COMPONENTPARENT_EXNAMEF
@e COMPONENTCHILD_EXNAMEF
@e COMPONENTSIBLING_EXNAMEF
@e PARSETOKENSTOPPED_EXNAMEF
@e GPRTT_EXNAMEF
@e ELEMENTARYTT_EXNAMEF
@e SCOPETT_EXNAMEF
@e ROUTINEFILTERTT_EXNAMEF
@e WORN_EXNAMEF
@e TRYGIVENOBJECT_EXNAMEF
@e PNTOVP_EXNAMEF
@e STORYTENSE_EXNAMEF
@e PRIORNAMEDNOUN_EXNAMEF
@e PRIORNAMEDLIST_EXNAMEF
@e ARGUMENTTYPEFAILED_EXNAMEF
@e FORMALRV_EXNAMEF
@e CHECKKINDRETURNED_EXNAMEF
@e STOREDACTIONTYTRY_EXNAMEF
@e KEEPSILENT_EXNAMEF
@e CLEARPARAGRAPHING_EXNAMEF
@e DIVIDEPARAGRAPHPOINT_EXNAMEF
@e ADJUSTPARAGRAPHPOINT_EXNAMEF
@e TRYACTION_EXNAMEF
@e STOREDACTIONTYCURRENT_EXNAMEF
@e NUMBERTYTOREALNUMBERTY_EXNAMEF
@e REALNUMBERTYTONUMBERTY_EXNAMEF
@e NUMBERTYTOTIMETY_EXNAMEF
@e LISTOFTYDESC_EXNAMEF
@e SIGNEDCOMPARE_EXNAMEF
@e DURINGSCENEMATCHING_EXNAMEF
@e TESTACTIONBITMAP_EXNAMEF
@e TESTACTIVITY_EXNAMEF
@e EXISTSTABLEROWCORR_EXNAMEF
@e LOCATIONOF_EXNAMEF
@e TESTSCOPE_EXNAMEF
@e LOOPOVERSCOPE_EXNAMEF
@e TURNSACTIONHASBEENHAPPENING_EXNAMEF
@e TIMESACTIONHASBEENHAPPENING_EXNAMEF
@e TIMESACTIONHASHAPPENED_EXNAMEF
@e ACTIONCURRENTLYHAPPENINGFLAG_EXNAMEF
@e TABLELOOKUPENTRY_EXNAMEF
@e TABLELOOKUPCORR_EXNAMEF
@e TEXTTYEXPANDIFPERISHABLE_EXNAMEF
@e GENERATERANDOMNUMBER_EXNAMEF

@e FINAL_EXNAMEF

inter_name *InterNames::extern(int exnum) {
	return InterNames::extern_in(EXTERN_MISCELLANEOUS_INAMEF, exnum);
}

inter_name *extern_inter_names[FINAL_EXNAMEF+1];
inter_name *InterNames::extern_in(int family, int exnum) {
	if ((exnum < 1) || (exnum >= FINAL_EXNAMEF)) internal_error("exnum out of range");
	if (extern_inter_names[exnum]) return extern_inter_names[exnum];
	text_stream *S = NULL;
	kind *K = K_value;
	switch (exnum) {
		case EMPTY_TEXT_PACKED_EXNAMEF: 				S = I"EMPTY_TEXT_PACKED"; break;
		case PACKED_TEXT_STORAGE_EXNAMEF: 				S = I"PACKED_TEXT_STORAGE"; break;
		case CONSTANT_PACKED_TEXT_STORAGE_EXNAMEF: 		S = I"CONSTANT_PACKED_TEXT_STORAGE"; break;
		case CONSTANT_PERISHABLE_TEXT_STORAGE_EXNAMEF: 	S = I"CONSTANT_PERISHABLE_TEXT_STORAGE"; break;
		case EMPTYRELATIONHANDLER_EXNAMEF: 				S = I"EmptyRelationHandler"; break;
		case HASHLISTRELATIONHANDLER_EXNAMEF: 			S = I"HashListRelationHandler"; break;
		case DOUBLEHASHSETRELATIONHANDLER_EXNAMEF: 		S = I"DoubleHashSetRelationHandler"; break;
		case EMPTY_TABLE_EXNAMEF: 						S = I"TheEmptyTable"; break;
		case TABLE_NOVALUE_EXNAMEF: 					S = I"TABLE_NOVALUE"; break;
		case AUXF_MAGIC_VALUE_EXNAMEF: 					S = I"AUXF_MAGIC_VALUE"; break;
		case AUXF_STATUS_IS_CLOSED_EXNAMEF: 			S = I"AUXF_STATUS_IS_CLOSED"; break;
		case FOUND_EVERYWHERE_EXNAMEF: 					S = I"FoundEverywhere"; break;
		case DA_NAME_EXNAMEF: 							S = I"DA_Name"; break;
		case DECIMAL_NUMBER_EXNAMEF: 					S = I"DecimalNumber"; break;
		case I7SFRAME_EXNAMEF: 							S = I"I7SFRAME"; break;
		case ALLOWINSHOWME_EXNAMEF: 					S = I"AllowInShowme";
			K = Kinds::binary_construction(CON_phrase, K_value, K_value); break;
		case BLKVALUEFREEONSTACK_EXNAMEF: 				S = I"BlkValueFreeOnStack";
			K = Kinds::binary_construction(CON_phrase, K_number, K_nil); break;
		case RESPONSEVIAACTIVITY_EXNAMEF: 				S = I"ResponseViaActivity";
			K = Kinds::binary_construction(CON_phrase, K_number, K_nil); break;
		case STACKFRAMECREATE_EXNAMEF: 					S = I"StackFrameCreate";
			K = Kinds::binary_construction(CON_phrase, K_number, K_nil); break;
		case BLKVALUECOPY_EXNAMEF: 						S = I"BlkValueCopy";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_value); break;
		case BLKVALUECOPYAZ_EXNAMEF: 					S = I"BlkValueCopyAZ";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_value); break;
		case BLKVALUECREATE_EXNAMEF: 					S = I"BlkValueCreate";
			K = Kinds::binary_construction(CON_phrase, K_value, K_nil); break;
		case BLKVALUEERROR_EXNAMEF: 					S = I"BlkValueError";
			K = Kinds::binary_construction(CON_phrase, K_value, K_nil); break;
		case LISTOFTYSAY_EXNAMEF:						S = I"LIST_OF_TY_Say"; break;
		case LISTOFTYSETLENGTH_EXNAMEF:					S = I"LIST_OF_TY_SetLength"; break;
		case LISTOFTYINSERTITEM_EXNAMEF:				S = I"LIST_OF_TY_InsertItem"; break;
		case TEXTTYSAY_EXNAMEF: 						S = I"TEXT_TY_Say";
			K = Kinds::binary_construction(CON_phrase, K_value, K_nil); break;
		case TEXTTYCOMPARE_EXNAMEF: 					S = I"TEXT_TY_Compare";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_number, K_value), K_truth_state); break;
		case RELATIONTYNAME_EXNAMEF: 					S = I"RELATION_TY_Name";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_nil); break;
		case RELATIONTYOTOOADJECTIVE_EXNAMEF: 			S = I"RELATION_TY_OToOAdjective";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_nil); break;
		case RELATIONTYOTOVADJECTIVE_EXNAMEF: 			S = I"RELATION_TY_OToVAdjective";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_nil); break;
		case RELATIONTYVTOOADJECTIVE_EXNAMEF: 			S = I"RELATION_TY_VToOAdjective";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_nil); break;
		case RELATIONTYSYMMETRICADJECTIVE_EXNAMEF: 		S = I"RELATION_TY_SymmetricAdjective";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_nil); break;
		case RELATIONTYEQUIVALENCEADJECTIVE_EXNAMEF: 	S = I"RELATION_TY_EquivalenceAdjective";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value), K_nil); break;
		case BLKVALUEFREE_EXNAMEF: 						S = I"BlkValueFree";
			K = Kinds::binary_construction(CON_phrase, K_value, K_nil); break;
		case BLKVALUEWRITE_EXNAMEF: 					S = I"BlkValueWrite"; break;
		case BLKVALUECREATEONSTACK_EXNAMEF: 			S = I"BlkValueCreateOnStack";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_number, K_value), K_nil); break;
		case RULEBOOKFAILS_EXNAMEF: 					S = I"RulebookFails";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_number, K_value), K_nil); break;
		case RULEBOOKSUCCEEDS_EXNAMEF: 					S = I"RulebookSucceeds";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_number, K_value), K_nil); break;
		case PRINTORRUN_EXNAMEF: 						S = I"PrintOrRun";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value)), K_nil); break;
		case DEBUGRULES_EXNAMEF: 						S = I"debug_rules"; break;
		case DBRULE_EXNAMEF:							S = I"DB_Rule";
			K = Kinds::binary_construction(CON_phrase, Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, Kinds::binary_construction(CON_TUPLE_ENTRY, K_number, K_number)), K_nil); break;
		case DEADFLAG_EXNAMEF: 							S = I"deadflag"; break;
		case ACTION_EXNAMEF: 							S = I"action"; break;
		case NOUN_EXNAMEF: 								S = I"noun"; break;
		case SECOND_EXNAMEF: 							S = I"second"; break;
		case INP1_EXNAMEF: 								S = I"inp1"; break;
		case INP2_EXNAMEF: 								S = I"inp2"; break;
		case ACTOR_EXNAMEF: 							S = I"actor"; break;
		case ACTREQUESTER_EXNAMEF:						S = I"act_requester"; break;
		case PLAYER_EXNAMEF: 							S = I"player"; break;
		case LOCATION_EXNAMEF: 							S = I"location"; break;
		case SCENESTARTED_EXNAMEF: 						S = I"scene_started"; break;
		case SCENEENDED_EXNAMEF: 						S = I"scene_ended"; break;
		case SCENESTATUS_EXNAMEF: 						S = I"scene_status"; break;
		case SCENEENDINGS_EXNAMEF: 						S = I"scene_endings"; break;
		case SCENELATESTENDING_EXNAMEF: 				S = I"scene_latest_ending"; break;
		case PARSEDNUMBER_EXNAMEF: 						S = I"parsed_number"; break;
		case SPECIALWORD_EXNAMEF: 						S = I"special_word"; break;
		case CONSULTFROM_EXNAMEF: 						S = I"consult_from"; break;
		case CONSULTWORDS_EXNAMEF: 						S = I"consult_words"; break;
		case REALLOCATION_EXNAMEF: 						S = I"real_location"; break;
		case ACTORLOCATION_EXNAMEF: 					S = I"actor_location"; break;
		case INVENTORYSTAGE_EXNAMEF:					S = I"inventory_stage"; break;
		case CSTYLE_EXNAMEF:							S = I"c_style"; break;
		case ENGLISHBIT_EXNAMEF:						S = I"ENGLISH_BIT"; break;
		case NOARTICLEBIT_EXNAMEF:						S = I"NOARTICLE_BIT"; break;
		case NEWLINEBIT_EXNAMEF:						S = I"NEWLINE_BIT"; break;
		case INDENTBIT_EXNAMEF:							S = I"INDENT_BIT"; break;
		case THEDARK_EXNAMEF:							S = I"thedark"; break;
		case GPRFAIL_EXNAMEF:							S = I"GPR_FAIL"; break;
		case GPRPREPOSITION_EXNAMEF:					S = I"GPR_PREPOSITION"; break;
		case THETIME_EXNAMEF:							S = I"the_time"; break;
		case UNDERSTANDASMISTAKENUMBER_EXNAMEF:			S = I"understand_as_mistake_number"; break;
		case SAYN_EXNAMEF: 								S = I"say__n"; break;
		case SAYP_EXNAMEF: 								S = I"say__p"; break;
		case SAYPC_EXNAMEF: 							S = I"say__pc"; break;
		case UNICODETEMP_EXNAMEF:						S = I"unicode_temp"; break;
		case SUPPRESSTEXTSUBSTITUTION_EXNAMEF:			S = I"suppress_text_substitution"; break;
		case LOCALPARKING_EXNAMEF: 						S = I"LocalParking"; break;
		case PARACONTENT_EXNAMEF:						S = I"ParaContent"; break;
		case TESTREGIONALCONTAINMENT_EXNAMEF:			S = I"TestRegionalContainment"; break;
		case THEEMPTYTABLE_EXNAMEF:						S = I"TheEmptyTable"; break;
		case KINDATOMIC_EXNAMEF:						S = I"KindAtomic"; break;
		case GETGNAOFOBJECT_EXNAMEF:					S = I"GetGNAOfObject"; break;
		case GPROPERTY_EXNAMEF:							S = I"GProperty"; break;
		case FOLLOWRULEBOOK_EXNAMEF:					S = I"FollowRulebook"; break;
		case WHENSCENEBEGINS_EXNAMEF:					S = I"WHEN_SCENE_BEGINS_RB"; break;
		case WHENSCENEENDS_EXNAMEF:						S = I"WHEN_SCENE_ENDS_RB"; break;
		case GENERICVERBSUB_EXNAMEF:					S = I"GenericVerbSub"; break;
		case SHORTNAME_EXNAMEF:							S = I"short_name"; break;
		case CAPSHORTNAME_EXNAMEF:						S = I"cap_short_name"; break;
		case RELATIONTEST_EXNAMEF: 						S = I"RelationTest";
			K = Kinds::binary_construction(CON_phrase,
				Kinds::binary_construction(CON_TUPLE_ENTRY, K_value,
					Kinds::binary_construction(CON_TUPLE_ENTRY, K_value,
						Kinds::binary_construction(CON_TUPLE_ENTRY, K_value, K_value))), K_nil); break;
		case DEBUGSCENES_EXNAMEF:						S = I"debug_scenes"; break;
		case PRIORNAMEDLISTGENDER_EXNAMEF:				S = I"prior_named_list_gender"; break;
		case LOSRV_EXNAMEF:								S = I"los_rv"; break;
		case EMPTYTEXTVALUE_EXNAMEF:					S = I"EMPTY_TEXT_VALUE"; break;
		case MSTACK_EXNAMEF:							S = I"MStack"; break;
		case MSTVO_EXNAMEF:								S = I"MstVO"; break;
		case MSTVON_EXNAMEF:							S = I"MstVON"; break;
		case RUNTIMEPROBLEM_EXNAMEF:					S = I"RunTimeProblem"; break;
		case RTPRELKINDVIOLATION_EXNAMEF:				S = I"RTP_RELKINDVIOLATION"; break;
		case RTPRELMINIMAL_EXNAMEF:						S = I"RTP_RELMINIMAL"; break;
		case TESTSTART_EXNAMEF:							S = I"TestStart"; break;
		case PARSERERROR_EXNAMEF:						S = I"ParserError"; break;
		case PASTCHRONOLOGICALRECORD_EXNAMEF:			S = I"past_chronological_record"; break;
		case PRESENTCHRONOLOGICALRECORD_EXNAMEF:		S = I"present_chronological_record"; break;
		case RELFOLLOWVECTOR_EXNAMEF:					S = I"RelFollowVector"; break;
		case RLANYGETX_EXNAMEF:							S = I"RLANY_GET_X"; break;
		case RLANYCANGETX_EXNAMEF:						S = I"RLANY_CAN_GET_X"; break;
		case RLANYCANGETY_EXNAMEF:						S = I"RLANY_CAN_GET_Y"; break;
		case RLISTALLX_EXNAMEF:							S = I"RLIST_ALL_X"; break;
		case RLISTALLY_EXNAMEF:							S = I"RLIST_ALL_Y"; break;
		case RELSEMPTY_EXNAMEF:							S = I"RELS_EMPTY"; break;
		case RRSTORAGE_EXNAMEF:							S = I"RR_STORAGE"; break;
		case RLNGETF_EXNAMEF:							S = I"RlnGetF"; break;
		case RELATIONEMPTYOTOO_EXNAMEF:					S = I"Relation_EmptyOtoO"; break;
		case RELATIONEMPTYEQUIV_EXNAMEF:				S = I"Relation_EmptyEquiv"; break;
		case RELATIONEMPTYVTOV_EXNAMEF:					S = I"Relation_EmptyVtoV"; break;
		case OTOVRELROUTETO_EXNAMEF:					S = I"OtoVRelRouteTo"; break;
		case RELATIONRSHOWOTOO_EXNAMEF:					S = I"Relation_RShowOtoO"; break;
		case RELATIONSHOWEQUIV_EXNAMEF:					S = I"Relation_ShowEquiv"; break;
		case RELATIONSHOWOTOO_EXNAMEF:					S = I"Relation_ShowOtoO"; break;
		case RELATIONSHOWVTOV_EXNAMEF:					S = I"Relation_ShowVtoV"; break;
		case VTOORELROUTETO_EXNAMEF:					S = I"VtoORelRouteTo"; break;
		case VTOVRELROUTETO_EXNAMEF:					S = I"VtoVRelRouteTo"; break;
		case PARAMETERVALUE_EXNAMEF:					S = I"parameter_value"; break;
		case RULEBOOKPARBREAK_EXNAMEF:					S = I"RulebookParBreak"; break;
		case REASONTHEACTIONFAILED_EXNAMEF:				S = I"reason_the_action_failed"; break;
		case LATESTRULERESULT_EXNAMEF:					S = I"latest_rule_result"; break;
		case NUMBERTYABS_EXNAMEF:						S = I"NUMBER_TY_Abs"; break;
		case REALNUMBERTYABS_EXNAMEF:					S = I"REAL_NUMBER_TY_Abs"; break;
		case REALNUMBERTYCOMPARE_EXNAMEF:				S = I"REAL_NUMBER_TY_Compare"; break;
		case REALNUMBERTYSAY_EXNAMEF:					S = I"REAL_NUMBER_TY_Say"; break;
		case REALNUMBERTYMINUS_EXNAMEF:					S = I"REAL_NUMBER_TY_Minus"; break;
		case REALNUMBERTYDIVIDE_EXNAMEF:				S = I"REAL_NUMBER_TY_Divide"; break;
		case REALNUMBERTYREMAINDER_EXNAMEF:				S = I"REAL_NUMBER_TY_Remainder"; break;
		case REALNUMBERTYAPPROXIMATE_EXNAMEF:			S = I"REAL_NUMBER_TY_Approximate"; break;
		case REALNUMBERTYROOT_EXNAMEF:					S = I"REAL_NUMBER_TY_Root"; break;
		case REALNUMBERTYCUBEROOT_EXNAMEF:				S = I"REAL_NUMBER_TY_Cube_Root"; break;
		case INTEGERDIVIDE_EXNAMEF:						S = I"IntegerDivide"; break;
		case INTEGERREMAINDER_EXNAMEF:					S = I"IntegerRemainder"; break;
		case ROUNDOFFTIME_EXNAMEF:						S = I"RoundOffTime"; break;
		case SQUAREROOT_EXNAMEF:						S = I"SquareRoot"; break;
		case CUBEROOT_EXNAMEF:							S = I"CubeRoot"; break;
		case GPRNUMBER_EXNAMEF:							S = I"GPR_NUMBER"; break;
		case SCOPESTAGE_EXNAMEF:						S = I"scope_stage"; break;
		case OBJECT_EXNAMEF:							S = I"Object"; break;
		case PLACEINSCOPE_EXNAMEF:						S = I"PlaceInScope"; break;
		case SUPPRESSSCOPELOOPS_EXNAMEF:				S = I"suppress_scope_loops"; break;
		case NEXTBESTETYPE_EXNAMEF:						S = I"nextbest_etype"; break;
		case NOTINCONTEXTPE_EXNAMEF:					S = I"NOTINCONTEXT_PE"; break;
		case DEFERREDCALLINGLIST_EXNAMEF:				S = I"deferred_calling_list"; break;
		case LISTITEMKOVF_EXNAMEF:						S = I"LIST_ITEM_KOV_F"; break;
		case LISTOFTYGETLENGTH_EXNAMEF:					S = I"LIST_OF_TY_GetLength"; break;
		case LISTOFTYGETITEM_EXNAMEF:					S = I"LIST_OF_TY_GetItem"; break;
		case LISTITEMBASE_EXNAMEF:						S = I"LIST_ITEM_BASE"; break;
		case PROPERTYTOBETOTALLED_EXNAMEF:				S = I"property_to_be_totalled"; break;
		case PROPERTYLOOPSIGN_EXNAMEF:					S = I"property_loop_sign"; break;
		case WN_EXNAMEF:								S = I"wn"; break;
		case NEXTWORDSTOPPED_EXNAMEF:					S = I"NextWordStopped"; break;
		case PARSERACTION_EXNAMEF:						S = I"parser_action"; break;
		case PARSERTRACE_EXNAMEF:						S = I"parser_trace"; break;
		case PARSERONE_EXNAMEF:							S = I"parser_one"; break;
		case PARSERTWO_EXNAMEF:							S = I"parser_two"; break;
		case DETECTPLURALWORD_EXNAMEF:					S = I"DetectPluralWord"; break;
		case PLURALFOUND_EXNAMEF:						S = I"##PluralFound"; break;
		case WORDINPROPERTY_EXNAMEF:					S = I"WordInProperty"; break;
		case NAME_EXNAMEF:								S = I"name"; break;
		case ETYPE_EXNAMEF:								S = I"etype"; break;
		case REALNUMBERTYTIMES_EXNAMEF:					S = I"REAL_NUMBER_TY_Times"; break;
		case REALNUMBERTYPLUS_EXNAMEF:					S = I"REAL_NUMBER_TY_Plus"; break;
		case REALNUMBERTYNAN_EXNAMEF:					S = I"REAL_NUMBER_TY_Nan"; break;
		case REALNUMBERTYNEGATE_EXNAMEF:				S = I"REAL_NUMBER_TY_Negate"; break;
		case REALNUMBERTYPOW_EXNAMEF:					S = I"REAL_NUMBER_TY_Pow"; break;
		case WORDADDRESS_EXNAMEF:						S = I"WordAddress"; break;
		case WORDLENGTH_EXNAMEF:						S = I"WordLength"; break;
		case DIGITTOVALUE_EXNAMEF:						S = I"DigitToValue"; break;
		case THEN1WD_EXNAMEF:							S = I"THEN1__WD"; break;
		case FLOATPARSE_EXNAMEF:						S = I"FloatParse"; break;
		case FLOATNAN_EXNAMEF:							S = I"FLOAT_NAN"; break;
		case ARTICLEDESCRIPTORS_EXNAMEF:				S = I"ArticleDescriptors"; break;
		case CONTAINER_EXNAMEF:							S = I"container"; break;
		case SUPPORTER_EXNAMEF:							S = I"supporter"; break;
		case ANIMATE_EXNAMEF:							S = I"animate"; break;
		case COMPONENTPARENT_EXNAMEF:					S = I"component_parent"; break;
		case COMPONENTCHILD_EXNAMEF:					S = I"component_child"; break;
		case COMPONENTSIBLING_EXNAMEF:					S = I"component_sibling"; break;
		case PARSETOKENSTOPPED_EXNAMEF:					S = I"ParseTokenStopped"; break;
		case GPRTT_EXNAMEF:								S = I"GPR_TT"; break;
		case ELEMENTARYTT_EXNAMEF:						S = I"ELEMENTARY_TT"; break;
		case SCOPETT_EXNAMEF:							S = I"SCOPE_TT"; break;
		case ROUTINEFILTERTT_EXNAMEF:					S = I"ROUTINE_FILTER_TT"; break;
		case WORN_EXNAMEF:								S = I"worn"; break;
		case TRYGIVENOBJECT_EXNAMEF:					S = I"TryGivenObject"; break;
		case PNTOVP_EXNAMEF:							S = I"PNToVP"; break;
		case STORYTENSE_EXNAMEF:						S = I"story_tense"; break;
		case PRIORNAMEDNOUN_EXNAMEF:					S = I"prior_named_noun"; break;
		case PRIORNAMEDLIST_EXNAMEF:					S = I"prior_named_list"; break;
		case ARGUMENTTYPEFAILED_EXNAMEF:				S = I"ArgumentTypeFailed"; break;
		case FORMALRV_EXNAMEF:							S = I"formal_rv"; break;
		case CHECKKINDRETURNED_EXNAMEF:					S = I"CheckKindReturned"; break;
		case STOREDACTIONTYTRY_EXNAMEF:					S = I"STORED_ACTION_TY_Try"; break;
		case KEEPSILENT_EXNAMEF:						S = I"keep_silent"; break;
		case CLEARPARAGRAPHING_EXNAMEF:					S = I"ClearParagraphing"; break;
		case DIVIDEPARAGRAPHPOINT_EXNAMEF:				S = I"DivideParagraphPoint"; break;
		case ADJUSTPARAGRAPHPOINT_EXNAMEF:				S = I"AdjustParagraphPoint"; break;
		case TRYACTION_EXNAMEF:							S = I"TryAction"; break;
		case STOREDACTIONTYCURRENT_EXNAMEF:				S = I"STORED_ACTION_TY_Current"; break;
		case NUMBERTYTOREALNUMBERTY_EXNAMEF:			S = I"NUMBER_TY_to_REAL_NUMBER_TY"; break;
		case REALNUMBERTYTONUMBERTY_EXNAMEF:			S = I"REAL_NUMBER_TY_to_NUMBER_TY"; break;
		case NUMBERTYTOTIMETY_EXNAMEF:					S = I"NUMBER_TY_to_TIME_TY"; break;
		case LISTOFTYDESC_EXNAMEF:						S = I"LIST_OF_TY_Desc"; break;
		case SIGNEDCOMPARE_EXNAMEF:						S = I"SignedCompare"; break;
		case DURINGSCENEMATCHING_EXNAMEF:				S = I"DuringSceneMatching"; break;
		case TESTACTIONBITMAP_EXNAMEF:					S = I"TestActionBitmap"; break;
		case TESTACTIVITY_EXNAMEF:						S = I"TestActivity"; break;
		case EXISTSTABLEROWCORR_EXNAMEF:				S = I"ExistsTableRowCorr"; break;
		case LOCATIONOF_EXNAMEF:						S = I"LocationOf"; break;
		case TESTSCOPE_EXNAMEF:							S = I"TestScope"; break;
		case LOOPOVERSCOPE_EXNAMEF:						S = I"LoopOverScope"; break;
		case TURNSACTIONHASBEENHAPPENING_EXNAMEF:		S = I"TurnsActionHasBeenHappening"; break;
		case TIMESACTIONHASBEENHAPPENING_EXNAMEF:		S = I"TimesActionHasBeenHappening"; break;
		case TIMESACTIONHASHAPPENED_EXNAMEF:			S = I"TimesActionHasHappened"; break;
		case ACTIONCURRENTLYHAPPENINGFLAG_EXNAMEF:		S = I"ActionCurrentlyHappeningFlag"; break;
		case TABLELOOKUPENTRY_EXNAMEF:					S = I"TableLookUpEntry"; break;
		case TABLELOOKUPCORR_EXNAMEF:					S = I"TableLookUpCorr"; break;
		case TEXTTYEXPANDIFPERISHABLE_EXNAMEF:			S = I"TEXT_TY_ExpandIfPerishable"; break;
		case GENERATERANDOMNUMBER_EXNAMEF:				S = I"GenerateRandomNumber"; break;
	}
	if (S == NULL) internal_error("no wording for external name");
	extern_inter_names[exnum] = InterNames::extern_name(family, S, K);
	return extern_inter_names[exnum];
}

@

@e THESAME_NRL from 0
@e PARENT_NRL
@e CHILD_NRL
@e SIBLING_NRL
@e SELF_NRL

@e DEBUG_NRL
@e TARGET_ZCODE_NRL
@e TARGET_GLULX_NRL
@e DICT_WORD_SIZE_NRL
@e WORDSIZE_NRL
@e NULL_NRL
@e WORD_HIGHBIT_NRL
@e WORD_NEXTTOHIGHBIT_NRL
@e IMPROBABLE_VALUE_NRL
@e REPARSE_CODE_NRL
@e MAX_POSITIVE_NUMBER_NRL
@e MIN_NEGATIVE_NUMBER_NRL

@e CV_MEANING_NRL
@e CV_MODAL_NRL
@e CV_NEG_NRL
@e CV_POS_NRL

@e RELS_ASSERT_FALSE_NRL
@e RELS_ASSERT_TRUE_NRL
@e RELS_EQUIVALENCE_NRL
@e RELS_LIST_NRL
@e RELS_LOOKUP_ALL_X_NRL
@e RELS_LOOKUP_ALL_Y_NRL
@e RELS_LOOKUP_ANY_NRL
@e RELS_ROUTE_FIND_COUNT_NRL
@e RELS_ROUTE_FIND_NRL
@e RELS_SHOW_NRL
@e RELS_SYMMETRIC_NRL
@e RELS_TEST_NRL
@e RELS_X_UNIQUE_NRL
@e RELS_Y_UNIQUE_NRL
@e REL_BLOCK_HEADER_NRL
@e TTF_SUM_NRL

@e NOTHING_NRL
@e OBJECT_NRL
@e TESTUSEOPTION_NRL

@e MAX_NRL

=
typedef struct named_resource_location {
	int access_number;
	struct text_stream *access_name;
	struct package_request *package;
	struct inter_name *equates_to_iname;
	MEMORY_MANAGEMENT
} named_resource_location;

named_resource_location *nrls_indexed_by_id[MAX_NRL];
dictionary *nrls_indexed_by_name = NULL;

named_resource_location *InterNames::make_in(int id, text_stream *name, package_request *P) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->package = P;
	nrl->equates_to_iname = NULL;
	nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, name);
	Dictionaries::write_value(nrls_indexed_by_name, name, (void *) nrl);
	return nrl;
}

named_resource_location *InterNames::make_as(int id, text_stream *name, inter_name *iname) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->package = iname->eventual_owner;
	nrl->equates_to_iname = iname;
	nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, name);
	Dictionaries::write_value(nrls_indexed_by_name, name, (void *) nrl);
	return nrl;
}

named_resource_location *InterNames::make_on_demand(int id, text_stream *name) {
	named_resource_location *nrl = CREATE(named_resource_location);
	nrl->access_number = id;
	nrl->access_name = Str::duplicate(name);
	nrl->package = NULL;
	nrl->equates_to_iname = NULL;
	nrls_indexed_by_id[id] = nrl;
	Dictionaries::create(nrls_indexed_by_name, name);
	Dictionaries::write_value(nrls_indexed_by_name, name, (void *) nrl);
	return nrl;
}

int nrls_created = FALSE;
void InterNames::create_nrls(void) {
	nrls_created = TRUE;
	for (int i=0; i<MAX_NRL; i++) nrls_indexed_by_id[i] = NULL;
	nrls_indexed_by_name = Dictionaries::new(512, FALSE);

	package_request *basics = Packaging::request_resource(NULL, BASICS_SUBPACKAGE);
	InterNames::make_in(THESAME_NRL, I"##TheSame", basics);
	InterNames::make_in(PARENT_NRL, I"parent", basics);
	InterNames::make_in(CHILD_NRL, I"child", basics);
	InterNames::make_in(SIBLING_NRL, I"sibling", basics);
	InterNames::make_in(SELF_NRL, I"self", basics);

	InterNames::make_in(DEBUG_NRL, I"DEBUG", basics);
	InterNames::make_in(TARGET_ZCODE_NRL, I"TARGET_ZCODE", basics);
	InterNames::make_in(TARGET_GLULX_NRL, I"TARGET_GLULX", basics);
	InterNames::make_in(DICT_WORD_SIZE_NRL, I"DICT_WORD_SIZE", basics);
	InterNames::make_in(WORDSIZE_NRL, I"WORDSIZE", basics);
	InterNames::make_in(NULL_NRL, I"NULL", basics);
	InterNames::make_in(WORD_HIGHBIT_NRL, I"WORD_HIGHBIT", basics);
	InterNames::make_in(WORD_NEXTTOHIGHBIT_NRL, I"WORD_NEXTTOHIGHBIT", basics);
	InterNames::make_in(IMPROBABLE_VALUE_NRL, I"IMPROBABLE_VALUE", basics);
	InterNames::make_in(REPARSE_CODE_NRL, I"REPARSE_CODE", basics);
	InterNames::make_in(MAX_POSITIVE_NUMBER_NRL, I"MAX_POSITIVE_NUMBER", basics);
	InterNames::make_in(MIN_NEGATIVE_NUMBER_NRL, I"MIN_NEGATIVE_NUMBER", basics);

	package_request *conj = Packaging::request_resource(NULL, CONJUGATIONS_SUBPACKAGE);
	InterNames::make_in(CV_MEANING_NRL, I"CV_MEANING", conj);
	InterNames::make_in(CV_MODAL_NRL, I"CV_MODAL", conj);
	InterNames::make_in(CV_NEG_NRL, I"CV_NEG", conj);
	InterNames::make_in(CV_POS_NRL, I"CV_POS", conj);

	package_request *rels = Packaging::request_resource(NULL, RELATIONS_SUBPACKAGE);
	InterNames::make_in(RELS_ASSERT_FALSE_NRL, I"RELS_ASSERT_FALSE", rels);
	InterNames::make_in(RELS_ASSERT_TRUE_NRL, I"RELS_ASSERT_TRUE", rels);
	InterNames::make_in(RELS_EQUIVALENCE_NRL, I"RELS_EQUIVALENCE", rels);
	InterNames::make_in(RELS_LIST_NRL, I"RELS_LIST", rels);
	InterNames::make_in(RELS_LOOKUP_ALL_X_NRL, I"RELS_LOOKUP_ALL_X", rels);
	InterNames::make_in(RELS_LOOKUP_ALL_Y_NRL, I"RELS_LOOKUP_ALL_Y", rels);
	InterNames::make_in(RELS_LOOKUP_ANY_NRL, I"RELS_LOOKUP_ANY", rels);
	InterNames::make_in(RELS_ROUTE_FIND_COUNT_NRL, I"RELS_ROUTE_FIND_COUNT", rels);
	InterNames::make_in(RELS_ROUTE_FIND_NRL, I"RELS_ROUTE_FIND", rels);
	InterNames::make_in(RELS_SHOW_NRL, I"RELS_SHOW", rels);
	InterNames::make_in(RELS_SYMMETRIC_NRL, I"RELS_SYMMETRIC", rels);
	InterNames::make_in(RELS_TEST_NRL, I"RELS_TEST", rels);
	InterNames::make_in(RELS_X_UNIQUE_NRL, I"RELS_X_UNIQUE", rels);
	InterNames::make_in(RELS_Y_UNIQUE_NRL, I"RELS_Y_UNIQUE", rels);
	InterNames::make_in(REL_BLOCK_HEADER_NRL, I"REL_BLOCK_HEADER", rels);
	InterNames::make_in(TTF_SUM_NRL, I"TTF_sum", rels);

	InterNames::make_on_demand(OBJECT_NRL, I"Object");
	InterNames::make_on_demand(NOTHING_NRL, I"nothing");
	InterNames::make_on_demand(TESTUSEOPTION_NRL, I"TestUseOption");
}

inter_name *InterNames::find(int id) {
	if (nrls_created == FALSE) InterNames::create_nrls();
	if ((id < 0) || (id >= MAX_NRL) || (nrls_indexed_by_id[id] == NULL))
		internal_error("bad nrl ID");
	return InterNames::nrl_to_iname(nrls_indexed_by_id[id]);
}

inter_name *InterNames::find_by_name(text_stream *name) {
	if (Str::len(name) == 0) internal_error("bad nrl name");
	if (nrls_created == FALSE) InterNames::create_nrls();
	if (Dictionaries::find(nrls_indexed_by_name, name))
		return InterNames::nrl_to_iname(
			(named_resource_location *)
				Dictionaries::read_value(nrls_indexed_by_name, name));
	return NULL;
}

inter_name *InterNames::nrl_to_iname(named_resource_location *nrl) {
	if (nrl->equates_to_iname == NULL) {
		if (nrl->package)
			nrl->equates_to_iname = InterNames::one_off(nrl->access_name, nrl->package);
		switch (nrl->access_number) {
			case THESAME_NRL:
			case PARENT_NRL:
			case CHILD_NRL:
			case SIBLING_NRL: {
				packaging_state save = Packaging::enter_home_of(nrl->equates_to_iname);
				Emit::named_numeric_constant(nrl->equates_to_iname, 0);
				Packaging::exit(save);
				break;
			}
			case SELF_NRL: {
				packaging_state save = Packaging::enter_home_of(nrl->equates_to_iname);
				Emit::variable(nrl->equates_to_iname, K_value, UNDEF_IVAL, 0, I"self");
				Packaging::exit(save);
				break;
			}
			
			case NOTHING_NRL:
				nrl->package = Kinds::Behaviour::package(K_object);
				nrl->equates_to_iname = InterNames::one_off(nrl->access_name, nrl->package);
				break;
			case OBJECT_NRL:
				nrl->equates_to_iname = Kinds::RunTime::I6_classname(K_object);
				break;
			case TESTUSEOPTION_NRL: {
				package_request *R = Kinds::RunTime::package(K_use_option);
				nrl->equates_to_iname =
					Packaging::function(
						InterNames::one_off(I"test_fn", R),
						R,
						NULL);
				Inter::Symbols::set_translate(InterNames::to_symbol(nrl->equates_to_iname), nrl->access_name);
				break;
			}

		}
		if (nrl->package == NULL)
			nrl->package = Packaging::home_of(nrl->equates_to_iname);
	}
	return nrl->equates_to_iname;
}



inter_name *InterNames::formal_par(int n) {
	TEMPORARY_TEXT(lvalue);
	WRITE_TO(lvalue, "formal_par%d", n);
	inter_name *iname = InterNames::extern_name(EXTERN_FORMAL_PAR_INAMEF, lvalue, NULL);
	DISCARD_TEXT(lvalue);
	return iname;
}

@

@e INVALID_INAME from 0

@e ActionCoding_INAME
@e ActionData_INAME
@e ActionHappened_INAME
@e Activity_after_rulebooks_INAME
@e Activity_atb_rulebooks_INAME
@e Activity_before_rulebooks_INAME
@e Activity_for_rulebooks_INAME
@e activity_var_creators_INAME
@e AD_RECORDS_INAME
@e BASE_KIND_HWM_INAME
@e CAP_SHORT_NAME_EXISTS_INAME
@e CCOUNT_ACTION_NAME_INAME
@e CCOUNT_BINARY_PREDICATE_INAME
@e CCOUNT_PROPERTY_INAME
@e CCOUNT_QUOTATIONS_INAME
@e CommandPromptText_INAME
@e CreateDynamicRelations_INAME
@e DB_Action_Details_INAME
@e DEBUG_INAME
@e DECIMAL_TOKEN_INNER_INAME
@e DEFAULT_SCORING_SETTING_INAME
@e DefaultValueFinder_INAME
@e DefaultValueOfKOV_INAME
@e DetectSceneChange_INAME
@e DONE_INIS_INAME
@e EMPTY_RULEBOOK_INAME
@e Headline_INAME
@e I7_Kind_Name_INAME
@e INITIAL_MAX_SCORE_INAME
@e InitialSituation_INAME
@e InternalTestCases_INAME
@e IterateRelations_INAME
@e KOVComparisonFunction_INAME
@e KOVDomainSize_INAME
@e KOVIsBlockValue_INAME
@e KOVSupportFunction_INAME
@e main_INAME
@e generic_INAME
@e template_INAME
@e synoptic_INAME
@e resources_INAME
@e Map_Storage_INAME
@e MAX_FRAME_SIZE_NEEDED_INAME
@e MAX_WEAK_ID_INAME
@e MEANINGLESS_RR_INAME
@e MEMORY_HEAP_SIZE_INAME
@e MistakeAction_INAME
@e MistakeActionSub_INAME
@e MStack_GetRBVarCreator_INAME
@e NI_BUILD_COUNT_INAME
@e No_Directions_INAME
@e NO_EXTERNAL_FILES_INAME
@e NO_PAST_TENSE_ACTIONS_INAME
@e NO_PAST_TENSE_CONDS_INAME
@e NO_RESPONSES_INAME
@e NO_TEST_SCENARIOS_INAME
@e NO_USE_OPTIONS_INAME
@e NO_VERB_VERB_DEFINED_INAME
@e nothing_INAME
@e NUMBER_RULEBOOKS_CREATED_INAME
@e PastActionsI6Routines_INAME
@e PLAYER_OBJECT_INIS_INAME
@e PLUGIN_FILES_INAME
@e PrintKindValuePair_INAME
@e PrintResponse_INAME
@e PrintSceneName_INAME
@e PrintTableName_INAME
@e PrintUseOption_INAME
@e RANKING_TABLE_INAME
@e Release_INAME
@e ResourceIDsOfFigures_INAME
@e ResourceIDsOfSounds_INAME
@e ResponseDivisions_INAME
@e ResponseTexts_INAME
@e RNG_SEED_AT_START_OF_PLAY_INAME
@e RProperty_INAME
@e rulebook_var_creators_INAME
@e RulebookNames_INAME
@e RulebookOutcomePrintingRule_INAME
@e rulebooks_array_INAME
@e RulePrintingRule_INAME
@e Serial_INAME
@e ShowExtensionVersions_INAME
@e ShowFullExtensionVersions_INAME
@e ShowMeDetails_INAME
@e ShowOneExtension_INAME
@e ShowSceneStatus_INAME
@e STANDARD_RESPONSE_ISSUING_R_INAME
@e START_OBJECT_INIS_INAME
@e START_ROOM_INIS_INAME
@e START_TIME_INIS_INAME
@e Story_Author_INAME
@e Story_INAME
@e TableOfExternalFiles_INAME
@e TableOfTables_INAME
@e TableOfVerbs_INAME
@e TB_Blanks_INAME
@e TC_KOV_INAME
@e TestScriptSub_INAME
@e TestSinglePastState_INAME
@e TIME_TOKEN_INNER_INAME
@e TimedEventsTable_INAME
@e TimedEventTimesTable_INAME
@e TRUTH_STATE_TOKEN_INNER_INAME
@e TTF_sum_INAME
@e UNKNOWN_TY_INAME
@e UUID_ARRAY_INAME
@e VERB_DIRECTIVE_CREATURE_INAME
@e VERB_DIRECTIVE_DIVIDER_INAME
@e VERB_DIRECTIVE_HELD_INAME
@e VERB_DIRECTIVE_MULTI_INAME
@e VERB_DIRECTIVE_MULTIEXCEPT_INAME
@e VERB_DIRECTIVE_MULTIHELD_INAME
@e VERB_DIRECTIVE_MULTIINSIDE_INAME
@e VERB_DIRECTIVE_NOUN_INAME
@e VERB_DIRECTIVE_NUMBER_INAME
@e VERB_DIRECTIVE_RESULT_INAME
@e VERB_DIRECTIVE_REVERSE_INAME
@e VERB_DIRECTIVE_SLASH_INAME
@e VERB_DIRECTIVE_SPECIAL_INAME
@e VERB_DIRECTIVE_TOPIC_INAME

@e FINAL_INAME

inter_name *intern_inter_names[FINAL_INAME+1];
inter_name *InterNames::iname(int num) {
	if ((num < 1) || (num >= FINAL_INAME)) internal_error("inum out of range");
	if (intern_inter_names[num]) return intern_inter_names[num];
	text_stream *S = NULL; int glob = FALSE;
	switch (num) {
		case ActionCoding_INAME:				S = I"ActionCoding"; break;
		case ActionData_INAME:					S = I"ActionData"; break;
		case ActionHappened_INAME:				S = I"ActionHappened"; break;
		case Activity_after_rulebooks_INAME:	S = I"Activity_after_rulebooks"; break;
		case Activity_atb_rulebooks_INAME:		S = I"Activity_atb_rulebooks"; break;
		case Activity_before_rulebooks_INAME:	S = I"Activity_before_rulebooks"; break;
		case Activity_for_rulebooks_INAME:		S = I"Activity_for_rulebooks"; break;
		case activity_var_creators_INAME:		S = I"activity_var_creators"; break;
		case AD_RECORDS_INAME:					S = I"AD_RECORDS"; break;
		case BASE_KIND_HWM_INAME:				S = I"BASE_KIND_HWM"; break;
		case CAP_SHORT_NAME_EXISTS_INAME:		S = I"CAP_SHORT_NAME_EXISTS"; break;
		case CCOUNT_ACTION_NAME_INAME:			S = I"CCOUNT_ACTION_NAME"; break;
		case CCOUNT_BINARY_PREDICATE_INAME:		S = I"CCOUNT_BINARY_PREDICATE"; break;
		case CCOUNT_PROPERTY_INAME:				S = I"CCOUNT_PROPERTY"; break;
		case CCOUNT_QUOTATIONS_INAME:			S = I"CCOUNT_QUOTATIONS"; break;
		case CommandPromptText_INAME:			S = I"CommandPromptText"; break;
		case CreateDynamicRelations_INAME:		S = I"CreateDynamicRelations"; break;
		case DB_Action_Details_INAME:			S = I"DB_Action_Details"; break;
		case DEBUG_INAME:						S = I"DEBUG"; break;
		case DECIMAL_TOKEN_INNER_INAME:			S = I"DECIMAL_TOKEN_INNER"; break;
		case DEFAULT_SCORING_SETTING_INAME:		S = I"DEFAULT_SCORING_SETTING"; break;
		case DefaultValueFinder_INAME:			S = I"DefaultValueFinder"; break;
		case DefaultValueOfKOV_INAME:			S = I"DefaultValueOfKOV"; break;
		case DetectSceneChange_INAME:			S = I"DetectSceneChange"; break;
		case DONE_INIS_INAME:					S = I"DONE_INIS"; break;
		case EMPTY_RULEBOOK_INAME: 				S = I"EMPTY_RULEBOOK"; break;
		case Headline_INAME:					S = I"Headline"; break;
		case I7_Kind_Name_INAME:				S = I"I7_Kind_Name"; break;
		case INITIAL_MAX_SCORE_INAME:			S = I"INITIAL_MAX_SCORE"; break;
		case InitialSituation_INAME:			S = I"InitialSituation"; break;
		case InternalTestCases_INAME:			S = I"InternalTestCases"; break;
		case IterateRelations_INAME:			S = I"IterateRelations"; break;
		case KOVComparisonFunction_INAME:		S = I"KOVComparisonFunction"; break;
		case KOVDomainSize_INAME:				S = I"KOVDomainSize"; break;
		case KOVIsBlockValue_INAME:				S = I"KOVIsBlockValue"; break;
		case KOVSupportFunction_INAME:			S = I"KOVSupportFunction"; break;
		case main_INAME:						S = I"main"; glob = TRUE; break;
		case generic_INAME:						S = I"generic"; glob = TRUE; break;
		case template_INAME:					S = I"template"; glob = TRUE; break;
		case resources_INAME:					S = I"resources"; glob = TRUE; break;
		case synoptic_INAME:					S = I"synoptic"; glob = TRUE; break;
		case Map_Storage_INAME:					S = I"Map_Storage"; break;
		case MAX_FRAME_SIZE_NEEDED_INAME:		S = I"MAX_FRAME_SIZE_NEEDED"; break;
		case MAX_WEAK_ID_INAME:					S = I"MAX_WEAK_ID"; break;
		case MEANINGLESS_RR_INAME:				S = I"MEANINGLESS_RR"; break;
		case MEMORY_HEAP_SIZE_INAME:			S = I"MEMORY_HEAP_SIZE"; break;
		case MistakeAction_INAME:				S = I"##MistakeAction"; break;
		case MistakeActionSub_INAME:			S = I"MistakeActionSub"; break;
		case MStack_GetRBVarCreator_INAME:		S = I"MStack_GetRBVarCreator"; break;
		case NI_BUILD_COUNT_INAME:				S = I"NI_BUILD_COUNT"; break;
		case No_Directions_INAME:				S = I"No_Directions"; break;
		case NO_EXTERNAL_FILES_INAME:			S = I"NO_EXTERNAL_FILES"; break;
		case NO_PAST_TENSE_ACTIONS_INAME:		S = I"NO_PAST_TENSE_ACTIONS"; break;
		case NO_PAST_TENSE_CONDS_INAME:			S = I"NO_PAST_TENSE_CONDS"; break;
		case NO_RESPONSES_INAME:				S = I"NO_RESPONSES"; break;
		case NO_TEST_SCENARIOS_INAME:			S = I"NO_TEST_SCENARIOS"; break;
		case NO_USE_OPTIONS_INAME:				S = I"NO_USE_OPTIONS"; break;
		case NO_VERB_VERB_DEFINED_INAME:		S = I"NO_VERB_VERB_DEFINED"; break;
		case nothing_INAME:						S = I"nothing"; break;
		case NUMBER_RULEBOOKS_CREATED_INAME:	S = I"NUMBER_RULEBOOKS_CREATED"; break;
		case PastActionsI6Routines_INAME:		S = I"PastActionsI6Routines"; break;
		case PLAYER_OBJECT_INIS_INAME:			S = I"PLAYER_OBJECT_INIS"; break;
		case PLUGIN_FILES_INAME:				S = I"PLUGIN_FILES"; break;
		case PrintKindValuePair_INAME:			S = I"PrintKindValuePair"; break;
		case PrintResponse_INAME:				S = I"PrintResponse"; break;
		case PrintSceneName_INAME:				S = I"PrintSceneName"; break;
		case PrintTableName_INAME:				S = I"PrintTableName"; break;
		case PrintUseOption_INAME:				S = I"PrintUseOption"; break;
		case RANKING_TABLE_INAME:				S = I"RANKING_TABLE"; break;
		case Release_INAME:						S = I"Release"; break;
		case ResourceIDsOfFigures_INAME:		S = I"ResourceIDsOfFigures"; break;
		case ResourceIDsOfSounds_INAME:			S = I"ResourceIDsOfSounds"; break;
		case ResponseDivisions_INAME:			S = I"ResponseDivisions"; break;
		case ResponseTexts_INAME:				S = I"ResponseTexts"; break;
		case RNG_SEED_AT_START_OF_PLAY_INAME:	S = I"RNG_SEED_AT_START_OF_PLAY"; break;
		case RProperty_INAME:					S = I"RProperty"; break;
		case rulebook_var_creators_INAME:		S = I"rulebook_var_creators"; break;
		case RulebookNames_INAME:				S = I"RulebookNames"; break;
		case RulebookOutcomePrintingRule_INAME:	S = I"RulebookOutcomePrintingRule"; break;
		case rulebooks_array_INAME:				S = I"rulebooks_array"; break;
		case RulePrintingRule_INAME:			S = I"RulePrintingRule"; break;
		case Serial_INAME:						S = I"Serial"; break;
		case ShowExtensionVersions_INAME:		S = I"ShowExtensionVersions"; break;
		case ShowFullExtensionVersions_INAME:	S = I"ShowFullExtensionVersions"; break;
		case ShowMeDetails_INAME:				S = I"ShowMeDetails"; break;
		case ShowOneExtension_INAME:			S = I"ShowOneExtension"; break;
		case ShowSceneStatus_INAME:				S = I"ShowSceneStatus"; break;
		case STANDARD_RESPONSE_ISSUING_R_INAME:	S = I"STANDARD_RESPONSE_ISSUING_R"; break;
		case START_OBJECT_INIS_INAME:			S = I"START_OBJECT_INIS"; break;
		case START_ROOM_INIS_INAME:				S = I"START_ROOM_INIS"; break;
		case START_TIME_INIS_INAME:				S = I"START_TIME_INIS"; break;
		case Story_Author_INAME:				S = I"Story_Author"; break;
		case Story_INAME:						S = I"Story"; break;
		case TableOfExternalFiles_INAME:		S = I"TableOfExternalFiles"; break;
		case TableOfTables_INAME:				S = I"TableOfTables"; break;
		case TableOfVerbs_INAME:				S = I"TableOfVerbs"; break;
		case TB_Blanks_INAME:					S = I"TB_Blanks"; break;
		case TC_KOV_INAME:						S = I"TC_KOV"; break;
		case TestScriptSub_INAME:				S = I"TestScriptSub"; break;
		case TestSinglePastState_INAME:			S = I"TestSinglePastState"; break;
		case TIME_TOKEN_INNER_INAME:			S = I"TIME_TOKEN_INNER"; break;
		case TimedEventsTable_INAME:			S = I"TimedEventsTable"; break;
		case TimedEventTimesTable_INAME:		S = I"TimedEventTimesTable"; break;
		case TRUTH_STATE_TOKEN_INNER_INAME:		S = I"TRUTH_STATE_TOKEN_INNER"; break;
		case UNKNOWN_TY_INAME:					S = I"UNKNOWN_TY"; break;
		case UUID_ARRAY_INAME:					S = I"UUID_ARRAY"; break;
		case VERB_DIRECTIVE_CREATURE_INAME:		S = I"VERB_DIRECTIVE_CREATURE"; break;
		case VERB_DIRECTIVE_DIVIDER_INAME:		S = I"VERB_DIRECTIVE_DIVIDER"; break;
		case VERB_DIRECTIVE_HELD_INAME:			S = I"VERB_DIRECTIVE_HELD"; break;
		case VERB_DIRECTIVE_MULTI_INAME:		S = I"VERB_DIRECTIVE_MULTI"; break;
		case VERB_DIRECTIVE_MULTIEXCEPT_INAME:	S = I"VERB_DIRECTIVE_MULTIEXCEPT"; break;
		case VERB_DIRECTIVE_MULTIHELD_INAME:	S = I"VERB_DIRECTIVE_MULTIHELD"; break;
		case VERB_DIRECTIVE_MULTIINSIDE_INAME:	S = I"VERB_DIRECTIVE_MULTIINSIDE"; break;
		case VERB_DIRECTIVE_NOUN_INAME:			S = I"VERB_DIRECTIVE_NOUN"; break;
		case VERB_DIRECTIVE_NUMBER_INAME:		S = I"VERB_DIRECTIVE_NUMBER"; break;
		case VERB_DIRECTIVE_RESULT_INAME:		S = I"VERB_DIRECTIVE_RESULT"; break;
		case VERB_DIRECTIVE_REVERSE_INAME:		S = I"VERB_DIRECTIVE_REVERSE"; break;
		case VERB_DIRECTIVE_SLASH_INAME:		S = I"VERB_DIRECTIVE_SLASH"; break;
		case VERB_DIRECTIVE_SPECIAL_INAME:		S = I"VERB_DIRECTIVE_SPECIAL"; break;
		case VERB_DIRECTIVE_TOPIC_INAME:		S = I"VERB_DIRECTIVE_TOPIC"; break;
	}
	if (S == NULL) internal_error("no wording for external name");
	intern_inter_names[num] = InterNames::one_off(S, glob?NULL:(Packaging::request_main()));
	return intern_inter_names[num];
}
