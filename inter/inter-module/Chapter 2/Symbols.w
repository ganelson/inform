[Inter::Symbols::] Symbols.

To manage named symbols in inter code.

@h Symbols themselves.

@e LABEL_ISYMT from 1
@e MISC_ISYMT
@e PACKAGE_ISYMT
@e PTYPE_ISYMT

@e DEFINED_ISYMD from 1
@e UNDEFINED_ISYMD
@e LINKED_ISYMD

@e PRIVATE_ISYMS from 1
@e PUBLIC_ISYMS
@e EXTERNAL_ISYMS

=
typedef struct inter_symbol {
	inter_t symbol_ID;
	struct inter_symbols_table *owning_table;
	struct text_stream *symbol_name;
	int symbol_type;
	int symbol_scope;
	int definition_status;
	struct inter_frame definition;
	struct inter_frame importation_frame;
	struct inter_reading_state following_symbol;
	struct inter_symbol *equated_to;
	struct text_stream *equated_name;
	int transient_flags;
	int no_symbol_annotations;
	struct inter_annotation symbol_annotations[MAX_INTER_ANNOTATIONS_PER_SYMBOL];
	struct text_stream *splat_text;
	struct text_stream *translate_text;
	struct text_stream *export_name;
	struct text_stream *append_text;
	struct inter_symbol *bridge_symbol;
	MEMORY_MANAGEMENT
} inter_symbol;

@ =
inter_symbol *Inter::Symbols::new(text_stream *name, inter_symbols_table *T, inter_t ID) {
	if (Str::len(name) == 0) internal_error("symbol cannot have empty text as identifier");

	inter_symbol *symb = CREATE(inter_symbol);

	symb->owning_table = T;
	symb->symbol_ID = ID;
	symb->symbol_type = MISC_ISYMT;
	symb->symbol_scope = PUBLIC_ISYMS;
	symb->symbol_name = Str::duplicate(name);
	Inter::Symbols::undefine(symb);
	symb->importation_frame = Inter::Frame::around(NULL, -1);
	symb->no_symbol_annotations = 0;
	for (int i=0; i<MAX_INTER_ANNOTATIONS_PER_SYMBOL; i++)
		symb->symbol_annotations[i] = Inter::Defn::invalid_annotation();
	symb->equated_to = NULL;
	symb->equated_name = NULL;
	symb->transient_flags = 0;
	symb->splat_text = NULL;
	symb->translate_text = NULL;
	symb->export_name = NULL;
	symb->append_text = NULL;
	symb->bridge_symbol = NULL;
	LOGIF(INTER_SYMBOLS, "Created symbol $3 in $4\n", symb, T);

	return symb;
}

void Inter::Symbols::log(OUTPUT_STREAM, void *vs) {
	inter_symbol *S = (inter_symbol *) vs;
	if (S == NULL) WRITE("<no-symbol>");
	else {
		Inter::SymbolsTables::symbol_to_url_name(DL, S);
		WRITE("{%d}", S->symbol_ID - SYMBOL_BASE_VAL);
		if (Str::len(S->translate_text) > 0) WRITE("'%S'", S->translate_text);
	}
}

@ =
int Inter::Symbols::is_stored_in_data(inter_t val1, inter_t val2) {
	if (val1 == ALIAS_IVAL) return TRUE;
	return FALSE;
}

void Inter::Symbols::to_data(inter_repository *I, inter_package *pack, inter_symbol *S, inter_t *val1, inter_t *val2) {
	if (S == NULL) internal_error("no symbol");
	*val1 = ALIAS_IVAL; *val2 = Inter::SymbolsTables::id_from_symbol(I, pack, S);
}

@ =
void Inter::Symbols::write_declaration(OUTPUT_STREAM, inter_symbol *mark, int N) {
	for (int L=0; L<N; L++) WRITE("\t");
	WRITE("symbol ");
	switch (mark->symbol_scope) {
		case PRIVATE_ISYMS: WRITE("private"); break;
		case PUBLIC_ISYMS: WRITE("public"); break;
		case EXTERNAL_ISYMS: WRITE("external"); break;
		default: internal_error("unknown symbol type"); break;
	}
	WRITE(" ");
	switch (mark->symbol_type) {
		case LABEL_ISYMT: WRITE("label"); break;
		case MISC_ISYMT: WRITE("misc"); break;
		case PACKAGE_ISYMT: WRITE("package"); break;
		case PTYPE_ISYMT: WRITE("packagetype"); break;
		default: internal_error("unknown symbol type"); break;
	}
	WRITE(" %S", mark->symbol_name);
	if (Inter::Symbols::get_flag(mark, MAKE_NAME_UNIQUE)) WRITE("*");
	text_stream *trans_name = Inter::Symbols::get_translate(mark);
	if (Str::len(trans_name) > 0)
		WRITE(" -> %S", trans_name);
	inter_symbol *eq = mark->equated_to;
	if (eq) {
		WRITE(" == ");
		Inter::SymbolsTables::symbol_to_url_name(OUT, eq);
	}
}

void Inter::Symbols::define(inter_symbol *S, inter_frame P) {
	if (S == NULL) internal_error("tried to define null symbol");
	S->definition = P;
	S->definition_status = DEFINED_ISYMD;
}

inter_frame Inter::Symbols::defining_frame(inter_symbol *S) {
	if (S == NULL) internal_error("tried to find definition of null symbol");
	return S->definition;
}

int Inter::Symbols::is_defined(inter_symbol *S) {
	if (S == NULL) return FALSE;
	inter_frame D = Inter::Symbols::defining_frame(S);
	if (Inter::Frame::valid(&D)) return TRUE;
	return FALSE;
}

int Inter::Symbols::evaluate_to_int(inter_symbol *S) {
	inter_frame P = Inter::Symbols::defining_frame(S);
	if ((Inter::Frame::valid(&P)) &&
		(P.data[ID_IFLD] == CONSTANT_IST) &&
		(P.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
		(P.data[DATA_CONST_IFLD] == LITERAL_IVAL)) {
		return (int) P.data[DATA_CONST_IFLD + 1];
	}
	if ((Inter::Frame::valid(&P)) &&
		(P.data[ID_IFLD] == CONSTANT_IST) &&
		(P.data[FORMAT_CONST_IFLD] == CONSTANT_DIRECT) &&
		(P.data[DATA_CONST_IFLD] == ALIAS_IVAL)) {
		inter_symbols_table *scope = S->owning_table;
		inter_symbol *alias_to = Inter::SymbolsTables::symbol_from_id(scope, P.data[DATA_CONST_IFLD + 1]);
		return Inter::Symbols::evaluate_to_int(alias_to);
	}
	return -1;
}

void Inter::Symbols::strike_definition(inter_symbol *S) {
	if (S) {
		inter_frame D = Inter::Symbols::defining_frame(S);
		if (Inter::Frame::valid(&D)) {
			inter_repository *I = D.repo_segment->owning_repo;
			Inter::Frame::remove_from_tree(I, D);
		}
		Inter::Symbols::undefine(S);
	}
}

void Inter::Symbols::remove_from_table(inter_symbol *S) {
	int index = (int) S->symbol_ID - (int) SYMBOL_BASE_VAL;
	S->owning_table->symbol_array[index] = NULL;
}

void Inter::Symbols::undefine(inter_symbol *S) {
	if (S == NULL) internal_error("tried to undefine null symbol");
	S->definition = Inter::Frame::around(NULL, -1);
	S->definition_status = UNDEFINED_ISYMD;
}

void Inter::Symbols::clear_transient_flags(void) {
	inter_symbol *symb;
	LOOP_OVER(symb, inter_symbol) symb->transient_flags = 0;
}

int Inter::Symbols::get_flag(inter_symbol *symb, int f) {
	if (symb == NULL) internal_error("no symbol");
	return (symb->transient_flags & f)?TRUE:FALSE;
}

void Inter::Symbols::set_flag(inter_symbol *symb, int f) {
	if (symb == NULL) internal_error("no symbol");
	symb->transient_flags = symb->transient_flags | f;
}

void Inter::Symbols::clear_flag(inter_symbol *symb, int f) {
	if (symb == NULL) internal_error("no symbol");
	if (symb->transient_flags & f) symb->transient_flags = symb->transient_flags - f;
}

void Inter::Symbols::set_splat(inter_symbol *symb, text_stream *S) {
	if (symb == NULL) internal_error("no symbol");
	symb->splat_text = S;
}

text_stream *Inter::Symbols::get_splat(inter_symbol *symb) {
	if (symb == NULL) internal_error("no symbol");
	return symb->splat_text;
}

void Inter::Symbols::set_bridge(inter_symbol *symb, inter_symbol *B) {
	if (symb == NULL) internal_error("no symbol");
	symb->bridge_symbol = B;
}

inter_symbol *Inter::Symbols::get_bridge(inter_symbol *symb) {
	if (symb == NULL) internal_error("no symbol");
	return symb->bridge_symbol;
}

void Inter::Symbols::set_translate(inter_symbol *symb, text_stream *S) {
	if (symb == NULL) internal_error("no symbol");
	symb->translate_text = Str::duplicate(S);
}

text_stream *Inter::Symbols::get_translate(inter_symbol *symb) {
	if (symb == NULL) internal_error("no symbol");
	return symb->translate_text;
}

void Inter::Symbols::set_export_name(inter_symbol *symb, text_stream *S) {
	if (symb == NULL) internal_error("no symbol");
	symb->export_name = S;
}

text_stream *Inter::Symbols::get_export_name(inter_symbol *symb) {
	if (symb == NULL) internal_error("no symbol");
	return symb->export_name;
}

void Inter::Symbols::set_append(inter_symbol *symb, text_stream *S) {
	if (symb == NULL) internal_error("no symbol");
	symb->append_text = S;
}

text_stream *Inter::Symbols::get_append(inter_symbol *symb) {
	if (symb == NULL) internal_error("no symbol");
	return symb->append_text;
}

void Inter::Symbols::annotate(inter_repository *I, inter_symbol *symb, inter_annotation IA) {
	if (symb == NULL) internal_error("annotated null symbol");
	if (symb->no_symbol_annotations >= MAX_INTER_ANNOTATIONS_PER_SYMBOL)
		internal_error("too many annotations");
	LOGIF(INTER_SYMBOLS, "Annot %d of %S is ", symb->no_symbol_annotations, symb->symbol_name);
	if (Log::aspect_switched_on(INTER_SYMBOLS_DA)) Inter::Defn::write_annotation(DL, I, IA);
	LOGIF(INTER_SYMBOLS, "\n");
	symb->symbol_annotations[symb->no_symbol_annotations++] = IA;
}

void Inter::Symbols::annotate_i(inter_repository *I, inter_symbol *symb, inter_t annot_ID, inter_t n) {
	inter_annotation IA = Inter::Defn::annotation_from_bytecode(annot_ID, n);
	Inter::Symbols::annotate(I, symb, IA);
}

int Inter::Symbols::read_annotation(inter_symbol *symb, inter_t ID) {
	for (int i=0; i<symb->no_symbol_annotations; i++)
		if (symb->symbol_annotations[i].annot->annotation_ID == ID)
			return (int) symb->symbol_annotations[i].annot_value;
	return -1;
}

text_stream *Inter::Symbols::read_annotation_t(inter_symbol *symb, inter_repository *I, inter_t ID) {
	for (int i=0; i<symb->no_symbol_annotations; i++)
		if (symb->symbol_annotations[i].annot->annotation_ID == ID) {
			inter_t N = symb->symbol_annotations[i].annot_value;
			return Inter::get_text(I, N);
		}
	return NULL;
}

void Inter::Symbols::annotate_t(inter_repository *I, inter_symbol *symb, inter_t annot_ID, text_stream *S) {
	inter_t n = Inter::create_text(I);
	Str::copy(Inter::get_text(I, n), S);
	inter_annotation IA = Inter::Defn::annotation_from_bytecode(annot_ID, n);
	Inter::Symbols::annotate(I, symb, IA);
}

void Inter::Symbols::write_annotations(OUTPUT_STREAM, inter_repository *I, inter_symbol *symb) {
	if (symb)
		for (int i=0; i<symb->no_symbol_annotations; i++)
			Inter::Defn::write_annotation(OUT, I, symb->symbol_annotations[i]);
}

@ =
int Inter::Symbols::is_predeclared(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (S->symbol_scope != PUBLIC_ISYMS) return FALSE;
	if (S->symbol_type != MISC_ISYMT) return FALSE;
	if (S->definition_status != UNDEFINED_ISYMD) return FALSE;
	return TRUE;
}

int Inter::Symbols::is_predeclared_local(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (S->symbol_scope != PRIVATE_ISYMS) return FALSE;
	if (S->symbol_type != MISC_ISYMT) return FALSE;
	if (S->definition_status != UNDEFINED_ISYMD) return FALSE;
	return TRUE;
}

int Inter::Symbols::is_undefined_private(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (S->symbol_scope != PRIVATE_ISYMS) return FALSE;
	if (S->definition_status != UNDEFINED_ISYMD) return FALSE;
	return TRUE;
}

int Inter::Symbols::is_extern(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (S->symbol_scope == EXTERNAL_ISYMS) return TRUE;
	return FALSE;
}

void Inter::Symbols::extern(inter_symbol *S) {
	S->symbol_scope = EXTERNAL_ISYMS;
	S->symbol_type = MISC_ISYMT;
	S->definition_status = UNDEFINED_ISYMD;
}

int Inter::Symbols::is_label(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (S->symbol_scope != PRIVATE_ISYMS) return FALSE;
	if (S->symbol_type != LABEL_ISYMT) return FALSE;
	return TRUE;
}

void Inter::Symbols::label(inter_symbol *S) {
	if (Str::get_first_char(S->symbol_name) != '.') {
		LOG("Name is %S\n", S->symbol_name);
		internal_error("not a label name");
	}
	S->symbol_scope = PRIVATE_ISYMS;
	S->symbol_type = LABEL_ISYMT;
	S->definition_status = UNDEFINED_ISYMD;
}

void Inter::Symbols::local(inter_symbol *S) {
	S->symbol_scope = PRIVATE_ISYMS;
	S->symbol_type = MISC_ISYMT;
	S->definition_status = UNDEFINED_ISYMD;
}

int Inter::Symbols::is_local(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (S->symbol_scope != PRIVATE_ISYMS) return FALSE;
	if (S->symbol_type != MISC_ISYMT) return FALSE;
	return TRUE;
}
