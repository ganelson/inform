[Inter::Defn::] Definition.

Defining the Inter format.

@

@d MAX_INTER_CONSTRUCTS 100

=
typedef struct inter_line_parse {
	struct text_stream *line;
	struct match_results mr;
	struct inter_annotation_set set;
	inter_ti terminal_comment;
	int indent_level;
} inter_line_parse;

typedef struct inter_construct {
	inter_ti construct_ID;
	wchar_t *construct_syntax;
	int min_level;
	int max_level;
	int usage_permissions;
	struct text_stream *singular_name;
	struct text_stream *plural_name;
	struct method_set *methods;
	CLASS_DEFINITION
} inter_construct;

inter_construct *IC_lookup[MAX_INTER_CONSTRUCTS];

inter_construct *Inter::Defn::create_construct(inter_ti ID, wchar_t *syntax,
	text_stream *sing,
	text_stream *plur) {
	inter_construct *IC = CREATE(inter_construct);
	IC->methods = Methods::new_set();
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

@

@e CONSTRUCT_READ_MTID
@e CONSTRUCT_TRANSPOSE_MTID
@e CONSTRUCT_VERIFY_MTID
@e CONSTRUCT_WRITE_MTID
@e VERIFY_INTER_CHILDREN_MTID

=
VOID_METHOD_TYPE(CONSTRUCT_READ_MTID, inter_construct *IC, inter_bookmark *, inter_line_parse *, inter_error_location *, inter_error_message **E)
VOID_METHOD_TYPE(CONSTRUCT_TRANSPOSE_MTID, inter_construct *IC, inter_tree_node *P, inter_ti *grid, inter_ti max, inter_error_message **E)
VOID_METHOD_TYPE(CONSTRUCT_VERIFY_MTID, inter_construct *IC, inter_tree_node *P, inter_package *owner, inter_error_message **E)
VOID_METHOD_TYPE(CONSTRUCT_WRITE_MTID, inter_construct *IC, text_stream *OUT, inter_tree_node *P, inter_error_message **E)
VOID_METHOD_TYPE(VERIFY_INTER_CHILDREN_MTID, inter_construct *IC, inter_tree_node *P, inter_error_message **E)

@

@e INVALID_IST from 0

=
void Inter::Defn::create_language(void) {
	for (int i=0; i<MAX_INTER_CONSTRUCTS; i++) IC_lookup[i] = NULL;

	Inter::Defn::create_construct(INVALID_IST, NULL, I"nothing", I"nothings");
	SymbolAnnotation::declare_canonical_annotations();

	Inter::Nop::define();
	Inter::Comment::define();
	Inter::Symbol::define();
	Inter::Version::define();
	Inter::Pragma::define();
	Inter::Link::define();
	Inter::Append::define();
	Inter::Kind::define();
	Inter::DefaultValue::define();
	Inter::Constant::define();
	Inter::Instance::define();
	Inter::Variable::define();
	Inter::Property::define();
	Inter::Permission::define();
	Inter::PropertyValue::define();
	Inter::Primitive::define();
	InterPackage::define();
	Inter::PackageType::define();
	Inter::Label::define();
	Inter::Local::define();
	Inter::Inv::define();
	Inter::Ref::define();
	Inter::Val::define();
	Inter::Lab::define();
	Inter::Assembly::define();
	Inter::Code::define();
	Inter::Evaluation::define();
	Inter::Reference::define();
	Inter::Cast::define();
	Inter::Splat::define();
}


@

@d OUTSIDE_OF_PACKAGES 1
@d INSIDE_PLAIN_PACKAGE 2
@d INSIDE_CODE_PACKAGE 4
@d CAN_HAVE_CHILDREN 8

=
inter_error_message *Inter::Defn::verify_construct(inter_package *owner, inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return E;
	VOID_METHOD_CALL(IC, CONSTRUCT_VERIFY_MTID, P, owner, &E);
	return E;
}

inter_error_message *Inter::Defn::transpose_construct(inter_package *owner, inter_tree_node *P, inter_ti *grid, inter_ti max) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return E;
	VOID_METHOD_CALL(IC, CONSTRUCT_TRANSPOSE_MTID, P, grid, max, &E);
	return E;
}

inter_error_message *Inter::Defn::get_construct(inter_tree_node *P, inter_construct **to) {
	if (P == NULL) return Inode::error(P, I"invalid frame", NULL);
	if ((P->W.instruction[ID_IFLD] == INVALID_IST) || (P->W.instruction[ID_IFLD] >= MAX_INTER_CONSTRUCTS))
		return Inode::error(P, I"no such construct", NULL);
	inter_construct *IC = IC_lookup[P->W.instruction[ID_IFLD]];
	if (IC == NULL) return Inode::error(P, I"bad construct", NULL);
	if (to) *to = IC;
	return NULL;
}

inter_error_message *Inter::Defn::write_construct_text(OUTPUT_STREAM, inter_tree_node *P) {
	if (P->W.instruction[ID_IFLD] == NOP_IST) return NULL;
	return Inter::Defn::write_construct_text_allowing_nop(OUT, P);
}

inter_error_message *Inter::Defn::write_construct_text_allowing_nop(OUTPUT_STREAM, inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return E;
	for (inter_ti L=0; L<P->W.instruction[LEVEL_IFLD]; L++) WRITE("\t");
	VOID_METHOD_CALL(IC, CONSTRUCT_WRITE_MTID, OUT, P, &E);
	inter_ti ID = Inode::get_comment(P);
	if (ID != 0) {
		if (P->W.instruction[ID_IFLD] != COMMENT_IST) WRITE(" ");
		WRITE("# %S", Inode::ID_to_text(P, ID));
	}
	WRITE("\n");
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) InterPackage::write_symbols(OUT, P);
	return E;
}

inter_package *latest_block_package = NULL;

inter_error_message *Inter::Defn::read_construct_text(text_stream *line, inter_error_location *eloc, inter_bookmark *IBM) {
	inter_line_parse ilp;
	ilp.line = line;
	ilp.mr = Regexp::create_mr();
	ilp.terminal_comment = 0;
	ilp.set = SymbolAnnotation::new_annotation_set();
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
			ilp.terminal_comment = InterWarehouse::create_text(InterBookmark::warehouse(IBM), InterBookmark::package(IBM));
			int at = Str::index(P);
			P = Str::forward(P);
			while (Str::get(P) == ' ') P = Str::forward(P);
			Str::substr(InterWarehouse::get_text(InterBookmark::warehouse(IBM), ilp.terminal_comment), P, Str::end(ilp.line));
			Str::truncate(ilp.line, at);
			break;
		}
	}

	Str::trim_white_space(ilp.line);

	if (ilp.indent_level == 0) latest_block_package = NULL;

	while ((InterBookmark::package(IBM)) && (InterPackage::is_a_root_package(InterBookmark::package(IBM)) == FALSE) && (ilp.indent_level <= InterBookmark::baseline(IBM))) {
		InterBookmark::move_into_package(IBM, InterPackage::parent(InterBookmark::package(IBM)));
	}

	while (Regexp::match(&ilp.mr, ilp.line, L"(%c+) (__%c+) *")) {
		Str::copy(ilp.line, ilp.mr.exp[0]);
		inter_error_message *E = NULL;
		inter_annotation IA = SymbolAnnotation::read_annotation(InterBookmark::tree(IBM), ilp.mr.exp[1], eloc, &E);
		if (E) return E;
		SymbolAnnotation::write_to_set(IA.annot->iatype, &(ilp.set), IA);
	}
	inter_construct *IC;
	LOOP_OVER(IC, inter_construct)
		if (IC->construct_syntax)
			if (Regexp::match(&ilp.mr, ilp.line, IC->construct_syntax)) {
				inter_error_message *E = NULL;
				VOID_METHOD_CALL(IC, CONSTRUCT_READ_MTID, IBM, &ilp, eloc, &E);
				return E;
			}
	return Inter::Errors::plain(I"bad inter line", eloc);
}

void Inter::Defn::set_latest_block_package(inter_package *F) {
	latest_block_package = F;
}

inter_package *Inter::Defn::get_latest_block_package(void) {
	return latest_block_package;
}

inter_error_message *Inter::Defn::vet_level(inter_bookmark *IBM, inter_ti cons, int level, inter_error_location *eloc) {
	int actual = level;
	if ((InterBookmark::package(IBM)) &&
		(InterPackage::is_a_root_package(InterBookmark::package(IBM)) == FALSE))	
		actual = level - InterBookmark::baseline(IBM) - 1;
	inter_construct *proposed = NULL;
	LOOP_OVER(proposed, inter_construct)
		if (proposed->construct_ID == cons) {
			if (actual < 0) return Inter::Errors::plain(I"impossible level", eloc);
			if ((actual < proposed->min_level) || (actual > proposed->max_level))
				return Inter::Errors::plain(I"indentation error", eloc);
			return NULL;
		}
	return Inter::Errors::plain(I"no such construct", eloc);
}

int Inter::Defn::get_level(inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return 0;
	return (int) P->W.instruction[LEVEL_IFLD];
}

inter_error_message *Inter::Defn::verify_children_inner(inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = Inter::Defn::get_construct(P, &IC);
	if (E) return E;
	inter_package *pack = InterPackage::container(P);
	int need = INSIDE_PLAIN_PACKAGE;
	if (pack == NULL) need = OUTSIDE_OF_PACKAGES;
	else if (InterPackage::is_a_function_body(pack)) need = INSIDE_CODE_PACKAGE;
	if ((IC->usage_permissions & need) != need) {
		text_stream *M = Str::new();
		WRITE_TO(M, "construct (%d) '", P->W.instruction[LEVEL_IFLD]);
		Inter::Defn::write_construct_text(M, P);
		WRITE_TO(M, "' (%d) cannot be used ", IC->construct_ID);
		switch (need) {
			case OUTSIDE_OF_PACKAGES: WRITE_TO(M, "outside packages"); break;
			case INSIDE_PLAIN_PACKAGE: WRITE_TO(M, "inside non-code packages such as %S", InterPackage::name(pack)); break;
			case INSIDE_CODE_PACKAGE: WRITE_TO(M, "inside code packages such as %S", InterPackage::name(pack)); break;
		}
		return Inode::error(P, M, NULL);
	}
	E = NULL;
	VOID_METHOD_CALL(IC, VERIFY_INTER_CHILDREN_MTID, P, &E);
	if (E) Inter::Errors::backtrace(STDERR, P);
	return E;
}

void Inter::Defn::lint(inter_tree *I) {
	InterTree::traverse(I, Inter::Defn::lint_visitor, NULL, NULL, -PACKAGE_IST);
}

void Inter::Defn::lint_visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_ti c = Inode::get_package(P)->resource_ID;
	inter_ti a = Inode::get_package_slowly_getting_same_answer(P);
	if (c != a) {
		LOG("Frame gives package as $6, but its location is in package $6\n",
			Inode::ID_to_package(P, c),
			Inode::ID_to_package(P, a));
		WRITE_TO(STDERR, "Frame gives package as %d, but its location is in package %d\n",
			Inode::ID_to_package(P, c)->resource_ID,
			Inode::ID_to_package(P, a)->resource_ID);
		internal_error("misplaced package");
	}

	Produce::guard(Inter::Defn::verify_children_inner(P));
}

