[InterConstruct::] Definition.

Defining the Inter format.

@ Every Inter instruction is a use of a "comstruct". There are only about two
dozen, and inevitably some are used far more often than others.

Each different construct is represented by an instance of the following:

=
typedef struct inter_construct {
	inter_ti construct_ID; /* used to identify this in bytecode */
	struct text_stream *construct_name;

	wchar_t recognition_regexp[MAX_RECOGNITION_REGEXP_LENGTH];
	struct text_stream *syntax;

	int min_level; /* min node tree depth within its package */
	int max_level; /* max node tree depth within its package */
	int usage_permissions; /* a bitmap of the |*_ICUP| values */

	struct method_set *methods; /* what it does is entirely specified by these */

	CLASS_DEFINITION
} inter_construct;

inter_construct *InterConstruct::create_construct(inter_ti ID, text_stream *name) {
	inter_construct *IC = CREATE(inter_construct);
	IC->construct_ID = ID;
	IC->construct_name = Str::duplicate(name);

	IC->recognition_regexp[0] = 0;

	IC->min_level = 0;
	IC->max_level = 0;
	IC->usage_permissions = INSIDE_PLAIN_PACKAGE_ICUP;

	IC->methods = Methods::new_set();

	InterConstruct::set_construct_for_ID(ID, IC);
	return IC;
}

@ Several fields specify restrictions on where, in an Inter tree, instructions
using this construct can appear. |min_level| to |max_level|, inclusive, give
the range of hierarchical levels within their packages which such instructions
can occur at.

By default, note that a construct can only be used at the top level of a package --
min and max both equal 0; and by default, it has no usage permissions at all.
Those must be explicitly granted when a new construct is created.

@d INFINITELY_DEEP 100000000

@d OUTSIDE_OF_PACKAGES_ICUP  1
@d INSIDE_PLAIN_PACKAGE_ICUP 2
@d INSIDE_CODE_PACKAGE_ICUP  4
@d CAN_HAVE_CHILDREN_ICUP    8

=
void InterConstruct::permit(inter_construct *IC, int usage) {
	IC->usage_permissions |= usage;
}

void InterConstruct::allow_in_depth_range(inter_construct *IC, int l1, int l2) {
	IC->min_level = l1;
	IC->max_level = l2;
}

@ This specifies the textual format of the construct for parsing purposes, and
it needs to be set up so that no two different constructs can match the same
line of text.

Note that if no syntax is specified for a construct, then it will be inexpressible
in textual Inter code.

@d MAX_RECOGNITION_REGEXP_LENGTH 64

=
void InterConstruct::specify_syntax(inter_construct *IC, text_stream *syntax) {
	IC->syntax = syntax;
	TEMPORARY_TEXT(regexp)
	for (int i = 0; i < Str::len(syntax); i++) {
		if (Str::includes_wide_string_at(syntax, L"OPTIONALIDENTIFIER", i)) {
			i += 17; WRITE_TO(regexp, "*(%%i*)");
		} else if (Str::includes_wide_string_at(syntax, L"WHITESPACE", i)) {
			i += 9;  WRITE_TO(regexp, " *");
		} else if (Str::includes_wide_string_at(syntax, L"IDENTIFIER", i)) {
			i += 9;  WRITE_TO(regexp, "(%%i+)");
		} else if (Str::includes_wide_string_at(syntax, L"_IDENTIFIER", i)) {
			i += 10; WRITE_TO(regexp, "(_%%i+)");
		} else if (Str::includes_wide_string_at(syntax, L".IDENTIFIER", i)) {
			i += 10; WRITE_TO(regexp, "(.%%i+)");
		} else if (Str::includes_wide_string_at(syntax, L"!IDENTIFIER", i)) {
			i += 10; WRITE_TO(regexp, "(!%%i+)");
		} else if (Str::includes_wide_string_at(syntax, L"IDENTIFIER", i)) {
			i += 9; WRITE_TO(regexp, "(%%i+)");
		} else if (Str::includes_wide_string_at(syntax, L"NUMBER", i)) {
			i += 5; WRITE_TO(regexp, "(%%d+)");
		} else if (Str::includes_wide_string_at(syntax, L"TOKENS", i)) {
			i += 5; WRITE_TO(regexp, "(%%c+)");
		} else if (Str::includes_wide_string_at(syntax, L"TOKEN", i)) {
			i += 4; WRITE_TO(regexp, "(%%C+)");
		} else if (Str::includes_wide_string_at(syntax, L"TEXT", i)) {
			i += 3; WRITE_TO(regexp, "\"(%%c*)\"");
		} else {
			wchar_t c = Str::get_at(syntax, i);
			if (c == '\'') c = '"';
			PUT_TO(regexp, c);
		}
	}
	if (Str::len(regexp) >= MAX_RECOGNITION_REGEXP_LENGTH - 1)
		internal_error("too much syntax");
	int j = 0;
	LOOP_THROUGH_TEXT(pos, regexp) IC->recognition_regexp[j++] = Str::get(pos);
	IC->recognition_regexp[j++] = 0;
	DISCARD_TEXT(regexp)
}

@ There isn't really a construct with ID 0: this is used only as a sort of "not
a legal construct" value. Notice the way we give it no syntax, grant it no
permissions, and allow it only in an impossible range. So this cannot be expressed
in textual Inter, and cannot be stored in bytecode binary Inter either.

@e INVALID_IST from 0

=
void InterConstruct::define_invalid_construct(void) {
	inter_construct *IC = InterConstruct::create_construct(INVALID_IST, I"invalid");
	InterConstruct::allow_in_depth_range(IC, 0, -1);
}

@ The valid construct IDs then count upwards from there. Since these IDs are
stored in the bytecode for an instruction, in fact in the 0th word of the frame,
we will need to convert them to their //inter_construct// equivalents quickly.
So we store a lookup table:

@d MAX_INTER_CONSTRUCTS 100

=
int inter_construct_by_ID_ready = FALSE;
inter_construct *inter_construct_by_ID[MAX_INTER_CONSTRUCTS];

void InterConstruct::set_construct_for_ID(inter_ti ID, inter_construct *IC) {
	if (inter_construct_by_ID_ready == FALSE) {
		inter_construct_by_ID_ready = TRUE;
		for (int i=0; i<MAX_INTER_CONSTRUCTS; i++) inter_construct_by_ID[i] = NULL;
	}
	if (ID >= MAX_INTER_CONSTRUCTS) internal_error("too many constructs");
	inter_construct_by_ID[ID] = IC;
}

inter_construct *InterConstruct::get_construct_for_ID(inter_ti ID) {
	if ((ID == INVALID_IST) || (ID >= MAX_INTER_CONSTRUCTS) ||
		(inter_construct_by_ID_ready == FALSE))
		return NULL;
	return inter_construct_by_ID[ID];
}

@ Each construct is managed by its own section of code, and that includes
the creation of the constructs: so we poll those sections in turn.

=
void InterConstruct::create_language(void) {
	SymbolAnnotation::declare_canonical_annotations();
	InterConstruct::define_invalid_construct();
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

@ The result is printed when //inter// is run with the |-constructs| switch.

=
void InterConstruct::show_constructs(OUTPUT_STREAM) {
	WRITE("  Code     Construct           Syntax\n");
	for (int ID=0; ID<MAX_INTER_CONSTRUCTS; ID++) {
		inter_construct *IC = inter_construct_by_ID[ID];
		if ((IC) && (ID != INVALID_IST)) {
			WRITE("  %4x     %S", ID, IC->construct_name);
			for (int j = Str::len(IC->construct_name); j<20; j++) PUT(' ');
			WRITE("%S\n", IC->syntax);
		}
	}	
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

=
inter_error_message *InterConstruct::verify_construct(inter_package *owner, inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
	if (E) return E;
	VOID_METHOD_CALL(IC, CONSTRUCT_VERIFY_MTID, P, owner, &E);
	return E;
}

inter_error_message *InterConstruct::transpose_construct(inter_package *owner, inter_tree_node *P, inter_ti *grid, inter_ti max) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
	if (E) return E;
	VOID_METHOD_CALL(IC, CONSTRUCT_TRANSPOSE_MTID, P, grid, max, &E);
	return E;
}

inter_error_message *InterConstruct::get_construct(inter_tree_node *P, inter_construct **to) {
	if (P == NULL) return Inode::error(P, I"invalid frame", NULL);
	inter_construct *IC = InterConstruct::get_construct_for_ID(P->W.instruction[ID_IFLD]);
	if (IC == NULL) return Inode::error(P, I"no such construct", NULL);
	if (to) *to = IC;
	return NULL;
}

inter_error_message *InterConstruct::write_construct_text(OUTPUT_STREAM, inter_tree_node *P) {
	if (P->W.instruction[ID_IFLD] == NOP_IST) return NULL;
	return InterConstruct::write_construct_text_allowing_nop(OUT, P);
}

inter_error_message *InterConstruct::write_construct_text_allowing_nop(OUTPUT_STREAM, inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
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

inter_error_message *InterConstruct::read_construct_text(text_stream *line, inter_error_location *eloc, inter_bookmark *IBM) {
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
		if (IC->recognition_regexp[0])
			if (Regexp::match(&ilp.mr, ilp.line, IC->recognition_regexp)) {
				inter_error_message *E = NULL;
				VOID_METHOD_CALL(IC, CONSTRUCT_READ_MTID, IBM, &ilp, eloc, &E);
				return E;
			}
	return Inter::Errors::plain(I"bad inter line", eloc);
}

void InterConstruct::set_latest_block_package(inter_package *F) {
	latest_block_package = F;
}

inter_package *InterConstruct::get_latest_block_package(void) {
	return latest_block_package;
}

inter_error_message *InterConstruct::vet_level(inter_bookmark *IBM, inter_ti cons, int level, inter_error_location *eloc) {
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

int InterConstruct::get_level(inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
	if (E) return 0;
	return (int) P->W.instruction[LEVEL_IFLD];
}

inter_error_message *InterConstruct::verify_children_inner(inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
	if (E) return E;
	inter_package *pack = InterPackage::container(P);
	int need = INSIDE_PLAIN_PACKAGE_ICUP;
	if (pack == NULL) need = OUTSIDE_OF_PACKAGES_ICUP;
	else if (InterPackage::is_a_function_body(pack)) need = INSIDE_CODE_PACKAGE_ICUP;
	if ((IC->usage_permissions & need) != need) {
		text_stream *M = Str::new();
		WRITE_TO(M, "construct (%d) '", P->W.instruction[LEVEL_IFLD]);
		InterConstruct::write_construct_text(M, P);
		WRITE_TO(M, "' (%d) cannot be used ", IC->construct_ID);
		switch (need) {
			case OUTSIDE_OF_PACKAGES_ICUP: WRITE_TO(M, "outside packages"); break;
			case INSIDE_PLAIN_PACKAGE_ICUP: WRITE_TO(M, "inside non-code packages such as %S", InterPackage::name(pack)); break;
			case INSIDE_CODE_PACKAGE_ICUP: WRITE_TO(M, "inside code packages such as %S", InterPackage::name(pack)); break;
		}
		return Inode::error(P, M, NULL);
	}
	E = NULL;
	VOID_METHOD_CALL(IC, VERIFY_INTER_CHILDREN_MTID, P, &E);
	if (E) Inter::Errors::backtrace(STDERR, P);
	return E;
}

void InterConstruct::lint(inter_tree *I) {
	InterTree::traverse(I, InterConstruct::lint_visitor, NULL, NULL, -PACKAGE_IST);
}

void InterConstruct::lint_visitor(inter_tree *I, inter_tree_node *P, void *state) {
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

	Produce::guard(InterConstruct::verify_children_inner(P));
}

typedef struct inter_line_parse {
	struct text_stream *line;
	struct match_results mr;
	struct inter_annotation_set set;
	inter_ti terminal_comment;
	int indent_level;
} inter_line_parse;
