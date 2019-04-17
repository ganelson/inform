[InterNames::] Inter Namespace.

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
	N->derived_from = NULL;
	N->parametrised_derivatives = NULL;
	N->declared_in = NULL;
	N->to_mark = 0;
	N->eventual_owner = Hierarchy::main();
	return N;
}

inter_name_family *InterNames::name_generator(text_stream *prefix, text_stream *stem, text_stream *suffix) {
	int fusage = MANY_PER_NAMESPACE_FUSAGE;
	if ((Str::len(prefix) > 0) || (Str::len(suffix) > 0)) fusage = DERIVED_FUSAGE;
	inter_name_family *family = InterNames::new_family(fusage, stem);
	if (Str::len(prefix) > 0) family->derived_prefix = Str::duplicate(prefix);
	if (Str::len(suffix) > 0) family->derived_suffix = Str::duplicate(suffix);
	return family;
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

void InterNames::change_translation(inter_name *N, text_stream *new_text) {
	Inter::Symbols::set_translate(InterNames::to_symbol(N), new_text);
}

text_stream *InterNames::get_translation(inter_name *N) {
	return Inter::Symbols::get_translate(InterNames::to_symbol(N));
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
				WRITE("%S", N->family->family_name);
				if (N->unique_number >= 0) WRITE("%d", N->unique_number);
				break;
			default: internal_error("unknown fusage");
		}
		if (Str::len(N->memo) > 0) WRITE("_%S", N->memo);
	}
}

void InterNames::set_flag(inter_name *iname, int f) {
	Inter::Symbols::set_flag(InterNames::to_symbol(iname), f);
}

void InterNames::clear_flag(inter_name *iname, int f) {
	Inter::Symbols::clear_flag(InterNames::to_symbol(iname), f);
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

inter_name *InterNames::new_f(inter_name_family *F, int fix) {
	inter_name *iname = InterNames::new_in_space(InterNames::root(), F, FALSE);
	if (fix != -1) iname->unique_number = fix;
	return iname;
}

inter_name *InterNames::new_in_f(inter_name_family *F, compilation_module *C, int fix) {
	if (C == NULL) return InterNames::new_f(F, fix);
	inter_name *iname = InterNames::new_in_space(C->namespace, F, FALSE);
	if (fix != -1) iname->unique_number = fix;
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

inter_name *InterNames::new_derived_f(inter_name_family *F, inter_name *from) {
	if (F->fusage != DERIVED_FUSAGE) internal_error("not a derived family");
	inter_name *N = InterNames::new_in_space(InterNames::root(), F, TRUE);
	Packaging::house_with(N, from);
	N->derived_from = from;
	compilation_module *C = InterNames::to_module(from);
	InterNames::mark(F, N, C);
	return N;
}

@

@e FIRST_INSTANCE_INDERIV from 26
@e COUNT_INSTANCE_INDERIV
@e NEXT_INSTANCE_INDERIV

@e FINAL_INDERIV

inter_name *InterNames::letter_parametrised_name_f(inter_name_family *family, inter_name *rname, int marker, package_request *R) {
	if (rname == NULL) internal_error("can't parametrise null name");
	if (rname->parametrised_derivatives == NULL) {
		rname->parametrised_derivatives =
			Memory::I7_calloc(FINAL_INDERIV, sizeof(inter_name *), INTER_SYMBOLS_MREASON);
		for (int i=0; i<FINAL_INDERIV; i++) rname->parametrised_derivatives[i] = NULL;
	}
	if ((marker < 0) || (marker >= FINAL_INDERIV)) internal_error("respomse parameter out of range");
	if (rname->parametrised_derivatives[marker] == NULL) {
		rname->parametrised_derivatives[marker] = InterNames::new_f(family, -1);
		if (R) Packaging::house(rname->parametrised_derivatives[marker], R);
		rname->parametrised_derivatives[marker]->derived_from = rname;
	}

	return rname->parametrised_derivatives[marker];
}

void InterNames::override_action_base_iname(inter_name *ab_iname, text_stream *to) {
	ab_iname->family->family_name = Str::duplicate(to);
	Str::clear(ab_iname->memo);
}
