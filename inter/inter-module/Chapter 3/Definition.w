[Inter::Defn::] Definition.

Defining the Inter format.

@

@d MAX_INTER_ANNOTATIONS_PER_SYMBOL 8

=
typedef struct inter_annotation_form {
	inter_t annotation_ID;
	int textual_flag;
	struct text_stream *annotation_keyword;
	MEMORY_MANAGEMENT
} inter_annotation_form;

typedef struct inter_annotation {
	struct inter_annotation_form *annot;
	inter_t annot_value;
} inter_annotation;

@

@d MAX_INTER_CONSTRUCTS 100

=
typedef struct inter_line_parse {
	struct text_stream *line;
	struct match_results mr;
	int no_annotations;
	struct inter_annotation *annotations;
	inter_t terminal_comment;
	int indent_level;
} inter_line_parse;

typedef struct inter_construct {
	inter_t construct_ID;
	wchar_t *construct_syntax;
	int min_level;
	int max_level;
	int usage_permissions;
	struct text_stream *singular_name;
	struct text_stream *plural_name;
	METHOD_CALLS
	MEMORY_MANAGEMENT
} inter_construct;

inter_construct *IC_lookup[MAX_INTER_CONSTRUCTS];

inter_construct *Inter::Defn::create_construct(inter_t ID, wchar_t *syntax,
	text_stream *sing,
	text_stream *plur) {
	inter_construct *IC = CREATE(inter_construct);
	ENABLE_METHOD_CALLS(IC);
	IC->construct_ID = ID;
	IC->construct_syntax = syntax;
	if (ID >= MAX_INTER_CONSTRUCTS) internal_error("too many constructs");
	IC->min_level = 0;
	IC->max_level = 0;
	IC_lookup[ID] = IC;
	IC->usage_permissions = INSIDE_PLAIN_PACKAGE;
	IC->singular_name = Str::duplicate(sing);
	IC->plural_name = Str::duplicate(plur);
	return IC;
}

inter_symbol *plain_packagetype = NULL;
inter_symbol *code_packagetype = NULL;

@

@e CONSTRUCT_READ_MTID
@e CONSTRUCT_VERIFY_MTID
@e CONSTRUCT_WRITE_MTID
@e VERIFY_INTER_CHILDREN_MTID

=
VMETHOD_TYPE(CONSTRUCT_READ_MTID, inter_construct *IC, inter_reading_state *, inter_line_parse *, inter_error_location *, inter_error_message **E)
VMETHOD_TYPE(CONSTRUCT_VERIFY_MTID, inter_construct *IC, inter_frame P, inter_error_message **E)
VMETHOD_TYPE(CONSTRUCT_WRITE_MTID, inter_construct *IC, text_stream *OUT, inter_frame P, inter_error_message **E)
VMETHOD_TYPE(VERIFY_INTER_CHILDREN_MTID, inter_construct *IC, inter_frame P, inter_error_message **E)

@

@e INVALID_IST from 0

@d ID_IFLD 0
@d LEVEL_IFLD 1
@d DATA_IFLD 2

=
void Inter::Defn::create_language(void) {
	for (int i=0; i<MAX_INTER_CONSTRUCTS; i++) IC_lookup[i] = NULL;

	Inter::Defn::create_construct(INVALID_IST, NULL, I"nothing", I"nothings");
	Inter::Canon::declare();

	Inter::Nop::define();
	Inter::Comment::define();
	Inter::Marker::define();
	Inter::Symbol::define();
	Inter::Version::define();
	Inter::Pragma::define();
	Inter::Link::define();
	Inter::Append::define();
	Inter::Kind::define();
	Inter::DefaultValue::define();
	Inter::Constant::define();
	Inter::Metadata::define();
	Inter::Response::define();
	Inter::Instance::define();
	Inter::Variable::define();
	Inter::Property::define();
	Inter::Permission::define();
	Inter::PropertyValue::define();
	Inter::Primitive::define();
	Inter::Package::define();
	Inter::PackageType::define();
	Inter::Label::define();
	Inter::Local::define();
	Inter::Inv::define();
	Inter::Ref::define();
	Inter::Val::define();
	Inter::Lab::define();
	Inter::Code::define();
	Inter::Evaluation::define();
	Inter::Reference::define();
	Inter::Cast::define();
	Inter::Splat::define();
}

inter_annotation_form *Inter::Defn::create_annotation(inter_t ID, text_stream *keyword, int textual) {
	inter_annotation_form *IAF;
	LOOP_OVER(IAF, inter_annotation_form)
		if (Str::eq(keyword, IAF->annotation_keyword)) {
			if (IAF->annotation_ID == ID)
				return IAF;
			else
				return NULL;
		}

	IAF = CREATE(inter_annotation_form);
	IAF->annotation_ID = ID;
	IAF->annotation_keyword = Str::duplicate(keyword);
	IAF->textual_flag = textual;
	return IAF;
}

inter_annotation Inter::Defn::invalid_annotation(void) {
	inter_annotation IA;
	IA.annot = invalid_IAF;
	IA.annot_value = 0;
	return IA;
}

inter_annotation Inter::Defn::read_annotation(inter_repository *I, text_stream *keyword, inter_error_location *eloc, inter_error_message **E) {
	inter_t val = 0;
	int textual = FALSE;
	*E = NULL;
	LOOP_THROUGH_TEXT(P, keyword)
		if (Str::get(P) == '=') {
			if (Str::get(Str::forward(P)) == '"') {
				TEMPORARY_TEXT(parsed_text);
				inter_error_message *EP =
					Inter::Constant::parse_text(parsed_text, keyword, P.index+2, Str::len(keyword)-2, NULL);
				val = Inter::create_text(I);
				Str::copy(Inter::get_text(I, val), parsed_text);
				DISCARD_TEXT(parsed_text);
				if (EP) *E = EP;
				textual = TRUE;
			} else {
				val = (inter_t) Str::atoi(keyword, P.index + 1);
				textual = FALSE;
			}
			Str::truncate(keyword, P.index);
		}

	inter_annotation_form *IAF;
	LOOP_OVER(IAF, inter_annotation_form)
		if (Str::eq(keyword, IAF->annotation_keyword)) {
			if (IAF->textual_flag != textual) *E = Inter::Errors::plain(I"bad type for =value", eloc);
			inter_annotation IA;
			IA.annot = IAF;
			IA.annot_value = val;
			return IA;
		}
	*E = Inter::Errors::plain(I"unrecognised annotation", eloc);
	return Inter::Defn::invalid_annotation();
}

inter_annotation Inter::Defn::annotation_from_bytecode(inter_t c1, inter_t c2) {
	inter_annotation_form *IAF;
	LOOP_OVER(IAF, inter_annotation_form)
		if (c1 == IAF->annotation_ID) {
			inter_annotation IA;
			IA.annot = IAF;
			IA.annot_value = c2;
			return IA;
		}
	return Inter::Defn::invalid_annotation();
}

int Inter::Defn::is_invalid(inter_annotation IA) {
	if ((IA.annot == NULL) || (IA.annot->annotation_ID == INVALID_IANN)) return TRUE;
	return FALSE;
}

void Inter::Defn::annotation_to_bytecode(inter_annotation IA, inter_t *c1, inter_t *c2) {
	*c1 = IA.annot->annotation_ID;
	*c2 = IA.annot_value;
}

void Inter::Defn::write_annotation(OUTPUT_STREAM, inter_repository *I, inter_annotation IA) {
	WRITE(" %S", IA.annot->annotation_keyword);
	if (IA.annot_value != 0) {
		if (IA.annot->textual_flag) {
			WRITE("=\"");
			Inter::Constant::write_text(OUT, Inter::get_text(I, IA.annot_value));
			WRITE("\"");
		} else {
			WRITE("=%d", IA.annot_value);
		}
	}
}

@

@d OUTSIDE_OF_PACKAGES 1
@d INSIDE_PLAIN_PACKAGE 2
@d INSIDE_CODE_PACKAGE 4
@d CAN_HAVE_CHILDREN 8

=
inter_error_message *Inter::Defn::verify_construct(inter_frame P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return E;
	inter_package *pack = Inter::Packages::container(P);
	int need = INSIDE_PLAIN_PACKAGE;
	if (pack == NULL) need = OUTSIDE_OF_PACKAGES;
	else if (pack->codelike_package) need = INSIDE_CODE_PACKAGE;
	if ((IC->usage_permissions & need) != need) {
		text_stream *M = Str::new();
		WRITE_TO(M, "construct (%d, %08x) '", P.data[LEVEL_IFLD], Inter::Frame::get_package(P));
		Inter::Defn::write_construct_text(M, P);
		WRITE_TO(M, "' (%d) cannot be used ", IC->construct_ID);
		switch (need) {
			case OUTSIDE_OF_PACKAGES: WRITE_TO(M, "outside packages"); break;
			case INSIDE_PLAIN_PACKAGE: WRITE_TO(M, "inside non-code packages such as %S", (pack->package_name)?(pack->package_name->symbol_name):I"<nameless>"); break;
			case INSIDE_CODE_PACKAGE: WRITE_TO(M, "inside code packages such as %S", (pack->package_name)?(pack->package_name->symbol_name):I"<nameless>"); break;
		}
		return Inter::Frame::error(&P, M, NULL);
	}
	E = NULL;
	VMETHOD_CALL(IC, CONSTRUCT_VERIFY_MTID, P, &E);
	return E;
}

inter_error_message *Inter::Defn::get_construct(inter_frame P, inter_construct **to) {
	if (Inter::Frame::valid(&P) == FALSE) {
internal_error("zob");
		return Inter::Frame::error(&P, I"invalid frame", NULL);
	}
	if ((P.data[ID_IFLD] == INVALID_IST) || (P.data[ID_IFLD] >= MAX_INTER_CONSTRUCTS))
		return Inter::Frame::error(&P, I"no such construct", NULL);
	inter_construct *IC = IC_lookup[P.data[ID_IFLD]];
	if (IC == NULL) return Inter::Frame::error(&P, I"bad construct", NULL);
	if (to) *to = IC;
	return NULL;
}

inter_error_message *Inter::Defn::write_construct_text(OUTPUT_STREAM, inter_frame P) {
	if (P.data[ID_IFLD] == NOP_IST) return NULL;
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return E;
	for (inter_t L=0; L<P.data[LEVEL_IFLD]; L++) WRITE("\t");
	VMETHOD_CALL(IC, CONSTRUCT_WRITE_MTID, OUT, P, &E);
	inter_t ID = Inter::Frame::get_comment(P);
	if (ID != 0) {
		if (P.data[ID_IFLD] != COMMENT_IST) WRITE(" ");
		WRITE("# %S", Inter::get_text(P.repo_segment->owning_repo, ID));
	}
	WRITE("\n");
	if (P.data[ID_IFLD] == PACKAGE_IST) Inter::Package::write_symbols(OUT, P);
	return E;
}

inter_symbol *latest_block_symbol = NULL;

inter_error_message *Inter::Defn::read_construct_text(text_stream *line, inter_error_location *eloc, inter_reading_state *IRS) {
	inter_line_parse ilp;
	ilp.line = line;
	ilp.mr = Regexp::create_mr();
	ilp.terminal_comment = 0;
	ilp.no_annotations = 0;
	inter_annotation annotations[MAX_INTER_ANNOTATIONS_PER_SYMBOL];
	ilp.annotations = annotations;
	ilp.indent_level = 0;

	LOOP_THROUGH_TEXT(P, ilp.line) {
		wchar_t c = Str::get(P);
		if (c == '\t') ilp.indent_level++;
		else if (c == ' ')
			return Inter::Errors::plain(I"spaces (rather than tabs) at the beginning of this line", eloc);
		else break;
	}

	int quoted = FALSE, literal = FALSE;
	LOOP_THROUGH_TEXT(P, ilp.line) {
		wchar_t c = Str::get(P);
		if ((literal == FALSE) && (c == '"')) quoted = (quoted)?FALSE:TRUE;
		literal = FALSE;
		if (c == '\\') literal = TRUE;
		if ((c == '#') && ((P.index == 0) || (Str::get_at(ilp.line, P.index-1) != '#')) && (Str::get_at(ilp.line, P.index+1) != '#') && (quoted == FALSE)) {
			ilp.terminal_comment = Inter::create_text(IRS->read_into);
			int at = Str::index(P);
			P = Str::forward(P);
			while (Str::get(P) == ' ') P = Str::forward(P);
			Str::substr(Inter::get_text(IRS->read_into, ilp.terminal_comment), P, Str::end(ilp.line));
			Str::truncate(ilp.line, at);
			break;
		}
	}

	Str::trim_white_space(ilp.line);

	if (ilp.indent_level == 0) latest_block_symbol = NULL;

	if (ilp.indent_level < IRS->cp_indent) {
		Inter::Defn::unset_current_package(IRS, IRS->current_package, ilp.indent_level);
	}
	IRS->latest_indent = ilp.indent_level;

	while (Regexp::match(&ilp.mr, ilp.line, L"(%c+) (__%c+) *")) {
		Str::copy(ilp.line, ilp.mr.exp[0]);
		inter_error_message *E = NULL;
		inter_annotation IA = Inter::Defn::read_annotation(IRS->read_into, ilp.mr.exp[1], eloc, &E);
		if (E) return E;
		if (ilp.no_annotations >= MAX_INTER_ANNOTATIONS_PER_SYMBOL)
			return Inter::Errors::quoted(I"too many annotations", ilp.mr.exp[1], eloc);
		annotations[ilp.no_annotations++] = IA;
	}
	inter_construct *IC;
	LOOP_OVER(IC, inter_construct)
		if (IC->construct_syntax)
			if (Regexp::match(&ilp.mr, ilp.line, IC->construct_syntax)) {
				inter_error_message *E = NULL;
				VMETHOD_CALL(IC, CONSTRUCT_READ_MTID, IRS, &ilp, eloc, &E);
				return E;
			}
	return Inter::Errors::plain(I"bad inter line", eloc);
}

void Inter::Defn::set_current_package(inter_reading_state *IRS, inter_package *P) {
	IRS->current_package = P;
	IRS->cp_indent = IRS->latest_indent + 1;
}

void Inter::Defn::unset_current_package(inter_reading_state *IRS, inter_package *P, int L) {
	IRS->current_package = P->parent_package;
	IRS->cp_indent = L;
}

void Inter::Defn::set_latest_package_symbol(inter_symbol *F) {
	latest_block_symbol = F;
}

inter_symbol *Inter::Defn::get_latest_block_symbol(void) {
	return latest_block_symbol;
}

inter_error_message *Inter::Defn::vet_level(inter_reading_state *IRS, inter_t cons, int level, inter_error_location *eloc) {
	int actual = level - IRS->cp_indent;
	inter_construct *proposed = NULL;
	LOOP_OVER(proposed, inter_construct)
		if (proposed->construct_ID == cons) {
			if (actual < 0) return Inter::Errors::plain(I"impossible level", eloc);
			if ((actual < proposed->min_level) || (actual > proposed->max_level)) {
				return Inter::Errors::plain(I"indentation error", eloc);
			}
			return NULL;
		}
	return Inter::Errors::plain(I"no such construct", eloc);
}

int Inter::Defn::get_level(inter_frame P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return 0;
	return (int) P.data[LEVEL_IFLD];
}

inter_frame_list *Inter::Defn::list_of_children(inter_frame P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return NULL;
	if ((IC->usage_permissions & CAN_HAVE_CHILDREN) == 0) return NULL;
	if (Inter::Frame::valid(&P) == FALSE) return NULL;
	
	inter_t L = Inter::Frame::get_list(P);
	if (L == 0) {
		L = Inter::create_frame_list(P.repo_segment->owning_repo);
		Inter::Frame::set_list(P, L);
	}
	
	return Inter::find_frame_list(P.repo_segment->owning_repo, L);
}

inter_error_message *Inter::Defn::verify_children_inner(inter_frame P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return E;
	VMETHOD_CALL(IC, VERIFY_INTER_CHILDREN_MTID, P, &E);
	return E;
}
