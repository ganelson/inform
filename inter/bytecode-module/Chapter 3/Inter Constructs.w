[InterConstruct::] Inter Constructs.

There are around two dozen constructs in textual Inter source code, with each
instruction in bytecode being a usage of one of them.

@ Each different construct is represented by an instance of the following:

=
typedef struct inter_construct {
	inter_ti construct_ID; /* used to identify this in bytecode */
	struct text_stream *construct_name;

	wchar_t recognition_regexp[MAX_RECOGNITION_REGEXP_LENGTH];
	struct text_stream *syntax;

	int min_level; /* min node tree depth within its package */
	int max_level; /* max node tree depth within its package */
	int usage_permissions; /* a bitmap of the |*_ICUP| values */

	int min_extent; /* min number of words in the frame for this instruction */
	int max_extent; /* max number of words in the frame for this instruction */
	int symbol_defn_field; /* if this instruction declares a symbol, -1 otherwise */
	int TID_field; /* if this instruction declares a symbol with a type, -1 otherwise */

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
	IC->min_extent = 1; IC->max_extent = UNLIMITED_INSTRUCTION_FRAME_LENGTH;

	IC->symbol_defn_field = -1;
	IC->TID_field = -1;

	IC->methods = Methods::new_set();

	InterConstruct::set_construct_for_ID(ID, IC);
	return IC;
}

@ Numerous constructs are for instructions which define symbols, and sometimes
those have a data type attached. If so, the symbol ID will live in one field
of an instruction made with that construct, and the data type (in TID form --
see //Inter Data Types//) will live in another.

=
void InterConstruct::defines_symbol_in_fields(inter_construct *IC, int s, int t) {
	IC->symbol_defn_field = s;
	IC->TID_field = t;
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

@ The instruction can be constrained to have a given length, in terms of the
number of words of bytecode it occupies:

@d UNLIMITED_INSTRUCTION_FRAME_LENGTH 0x7fffffff

=
void InterConstruct::fix_instruction_length_between(inter_construct *IC, int l1, int l2) {
	IC->min_extent = l1;
	IC->max_extent = l2;
}

@ So here is the code to police those restrictions. First, for a node already
in position:

=
inter_error_message *InterConstruct::check_permissions(inter_construct *IC,
	inter_package *pack, inter_error_location *eloc) {
	int need = INSIDE_PLAIN_PACKAGE_ICUP;
	if (pack == NULL) need = OUTSIDE_OF_PACKAGES_ICUP;
	else if (InterPackage::is_a_function_body(pack)) need = INSIDE_CODE_PACKAGE_ICUP;
	if ((IC->usage_permissions & need) != need) {
		text_stream *M = Str::new();
		WRITE_TO(M, "construct '%S' cannot be used ", IC->construct_name);
		switch (need) {
			case OUTSIDE_OF_PACKAGES_ICUP:
				WRITE_TO(M, "outside packages"); break;
			case INSIDE_PLAIN_PACKAGE_ICUP:
				WRITE_TO(M, "inside non-code package '%S'", InterPackage::name(pack)); break;
			case INSIDE_CODE_PACKAGE_ICUP:
				WRITE_TO(M, "inside code package '%S'", InterPackage::name(pack)); break;
		}
		return InterErrors::plain(M, eloc);
	}
	return NULL;
}

@ Second, for a proposed use of node not yet in position -- this is used when
reading textual inter, hence the message about indentation:

=
inter_error_message *InterConstruct::check_level_in_package(inter_bookmark *IBM,
	inter_ti ID, int level, inter_error_location *eloc) {
	inter_construct *proposed = InterConstruct::get_construct_for_ID(ID);
	if (proposed == NULL) return InterErrors::plain(I"no such construct", eloc);
	inter_package *pack = InterBookmark::package(IBM);
	int actual = level;
	if ((pack) && (InterPackage::is_a_root_package(pack) == FALSE))	
		actual = level - InterBookmark::baseline(IBM) - 1;
	if (actual < 0) return InterErrors::plain(I"impossible level", eloc);
	if ((actual < proposed->min_level) || (actual > proposed->max_level))
		return InterErrors::plain(I"indentation error", eloc);
	return InterConstruct::check_permissions(proposed, pack, eloc);
}

@ A much more formidable check. This traverses an entire tree, and verifies
that every construct is legally used:

=
typedef struct tree_lint_state {
	struct inter_package *package;
	inter_ti package_level;
} tree_lint_state;

void InterConstruct::tree_lint(inter_tree *I) {
	tree_lint_state tls;
	tls.package = I->root_package;
	tls.package_level = 0;
	InterConstruct::tree_lint_r(I, I->root_node, &tls);
}

void InterConstruct::tree_lint_r(inter_tree *I, inter_tree_node *P, tree_lint_state *tls) {
	LOOP_THROUGH_INTER_CHILDREN(C, P) {
		if (Inode::get_package(C) != tls->package) {
			WRITE_TO(STDERR, "Node gives package as ");
			InterPackage::write_URL(STDERR, Inode::get_package(C));
			WRITE_TO(STDERR, " but it is actually in ");
			InterPackage::write_URL(STDERR, tls->package);
			WRITE_TO(STDERR, "\n");
			internal_error("node in wrong package");
		}
		inter_construct *IC = NULL;
		inter_error_message *E = InterConstruct::get_construct(C, &IC);
		if (E) InterErrors::issue(E);
		if (IC) {
			inter_error_location *eloc = Inode::get_error_location(C);
			E = InterConstruct::check_permissions(IC, tls->package, eloc);
			if (E) InterErrors::issue(E);
			E = InterConstruct::verify_children(C);
			if (E) {
				InterErrors::issue(E);
				InterErrors::backtrace(STDERR, C);
			}
			inter_ti level = C->W.instruction[LEVEL_IFLD];
			inter_ti level_in_package = level;
			if (tls->package) level_in_package -= tls->package_level;

			if ((IC->construct_ID != PACKAGE_IST) &&
					(((int) level_in_package < IC->min_level) ||
						((int) level_in_package > IC->max_level))) {
				text_stream *M = Str::new();
				WRITE_TO(M, "construct '%S' used at level %d in its package, not %d to %d",
					IC->construct_name, level_in_package, IC->min_level, IC->max_level);
				InterErrors::issue(InterErrors::plain(M, eloc));
			}
			if (C->W.instruction[ID_IFLD] == PACKAGE_IST) {
				tree_lint_state inner_tls;
				inner_tls.package = InterPackage::at_this_head(C);
				inner_tls.package_level = level + 1;
				InterConstruct::tree_lint_r(I, C, &inner_tls);
				LOOP_OVER_SYMBOLS_TABLE(S, InterPackage::scope(inner_tls.package))
					if ((InterSymbol::get_flag(S, SPECULATIVE_ISYMF)) &&
						(InterSymbol::is_defined(S) == FALSE)) {
						InterErrors::issue(InterErrors::quoted(
							I"symbol undefined in package",
							InterSymbol::identifier(S), eloc));
					}
			} else {
				InterConstruct::tree_lint_r(I, C, tls);
			}
		}
	}
}

@ So much for a construct's invariants. Now we turn to the textual syntax for it,
which of course applies only to the textual form of Inter. Moreover, the syntax
fields of an //inter_construct// are used only for parsing, and not for printing
instructions out again; it's just not worth the bother of doing it that way,
elegant as it might be. So note that if a syntax changes, the corresponding
function to write an instruction must change too.

So: |syntax| specifies the textual format of the construct for parsing purposes.
It needs to be set up so that no two different constructs can match the same
line of text. The |syntax| is easier to read than a regular expression, which is
what we turn it into. So for example |deploy !IDENTIFIER| would match the
literal word |deploy|, then any amount of white space, then a literal |!| and
immediately following it an identifier.

Note that it is legal not to call this function, i.e., to create a construct
but give it no syntax. If so, it will be inexpressible in textual Inter code.

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
			i += 9;  WRITE_TO(regexp, "(%%C+)");
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
		} else if (Str::includes_wide_string_at(syntax, L"ANY", i)) {
			i += 2; WRITE_TO(regexp, "(%%c*)");
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

@ Whence, in a faintly paranoid way:

=
inter_error_message *InterConstruct::get_construct(inter_tree_node *P, inter_construct **to) {
	if (P == NULL) return Inode::error(P, I"invalid node", NULL);
	inter_construct *IC = InterConstruct::get_construct_for_ID(P->W.instruction[ID_IFLD]);
	if (IC == NULL) return Inode::error(P, I"no such construct", NULL);
	if (to) *to = IC;
	return NULL;
}

@ Each construct is managed by its own section of code, and that includes
the creation of the constructs: so we poll those sections in turn.

=
void InterConstruct::create_language(void) {
	SymbolAnnotation::declare_canonical_annotations();
	InterConstruct::define_invalid_construct();
	Inter::Nop::define();
	Inter::Comment::define();
	Inter::Plug::define();
	Inter::Socket::define();
	Inter::Version::define();
	Inter::Pragma::define();
	Inter::Link::define();
	Inter::Append::define();
	Inter::Typename::define();
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

@ Okay then! We have our constructs: what shall we do with them?

The answer is that each construct behaves differently, in ways specified by
the following method calls on the relevant //inter_construct//.

Firstly, each construct has a method for verifying (i) that it is being used in
a self-consistent way by the given instruction, and (ii) that it can see child
nodes to that instruction of a kind it expects.

//InterConstruct::verify// should be called only by //Inter::Verify::instruction//,
which ensures that //InterConstruct::verify// is never called twice on the same
instruction. |CONSTRUCT_VERIFY_MTID| methods for the constructs can therefore
safely assume that.

@e CONSTRUCT_VERIFY_MTID
@e CONSTRUCT_VERIFY_CHILDREN_MTID

=
VOID_METHOD_TYPE(CONSTRUCT_VERIFY_MTID, inter_construct *IC, inter_tree_node *P,
	inter_package *owner, inter_error_message **E)
VOID_METHOD_TYPE(CONSTRUCT_VERIFY_CHILDREN_MTID, inter_construct *IC,
	inter_tree_node *P, inter_error_message **E)

inter_error_message *InterConstruct::verify(inter_package *owner,
	inter_construct *IC, inter_tree_node *P) {
	inter_error_message *E = NULL;
	VOID_METHOD_CALL(IC, CONSTRUCT_VERIFY_MTID, P, owner, &E);
	return E;
}

inter_error_message *InterConstruct::verify_children(inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
	if (E) return E;
	VOID_METHOD_CALL(IC, CONSTRUCT_VERIFY_CHILDREN_MTID, P, &E);
	return E;
}

@ This method writes out an instruction in textual Inter format, and this is
handled differently by each construct.

@e CONSTRUCT_WRITE_MTID

=
VOID_METHOD_TYPE(CONSTRUCT_WRITE_MTID, inter_construct *IC, text_stream *OUT,
	inter_tree_node *P, inter_error_message **E)

inter_error_message *InterConstruct::write_construct_text(OUTPUT_STREAM, inter_tree_node *P) {
	if (P->W.instruction[ID_IFLD] == NOP_IST) return NULL;
	return InterConstruct::write_construct_text_allowing_nop(OUT, P);
}

inter_error_message *InterConstruct::write_construct_text_allowing_nop(OUTPUT_STREAM,
	inter_tree_node *P) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
	if (E) return E;
	for (inter_ti L=0; L<P->W.instruction[LEVEL_IFLD]; L++) WRITE("\t");
	VOID_METHOD_CALL(IC, CONSTRUCT_WRITE_MTID, OUT, P, &E);
	WRITE("\n");
	if (P->W.instruction[ID_IFLD] == PACKAGE_IST) InterPackage::write_symbols(OUT, P);
	return E;
}

@ A much less elegant presentation is just to dump the hexadecimal bytecode,
and this is used only for debugging or to show errors in binary Inter files.

=
void InterConstruct::instruction_writer(OUTPUT_STREAM, char *format_string, void *vI) {
	inter_tree_node *F = (inter_tree_node *) vI;
	if (F == NULL) { WRITE("<no frame>"); return; }
	WRITE("%05d -> ", F->W.index);
	WRITE("%d {", F->W.extent);
	for (int i=0; i<F->W.extent; i++) WRITE(" %08x", F->W.instruction[i]);
	WRITE(" }");
}

@ Conversely, the function //InterConstruct::match// takes a line of textual Inter
source code, uses the regular expressions for each construct to find which one
is being used, and then calls its |CONSTRUCT_READ_MTID| method to ask for the
job to be completed.

@e CONSTRUCT_READ_MTID

=
VOID_METHOD_TYPE(CONSTRUCT_READ_MTID, inter_construct *IC, inter_bookmark *,
	inter_line_parse *, inter_error_location *, inter_error_message **E)

inter_error_message *InterConstruct::match(inter_line_parse *ilp, inter_error_location *eloc,
	inter_bookmark *IBM) {
	inter_construct *IC;
	LOOP_OVER(IC, inter_construct)
		if (IC->recognition_regexp[0])
			if (Regexp::match(&ilp->mr, ilp->line, IC->recognition_regexp)) {
				inter_error_message *E = NULL;
				VOID_METHOD_CALL(IC, CONSTRUCT_READ_MTID, IBM, ilp, eloc, &E);
				return E;
			}
	return InterErrors::plain(I"bad inter line", eloc);
}

@ Transposition is an awkward necessity when binary Inter is read in from a file,
and some references in its instruction bytecode need to be modified: this is
not the place to explain it. See //Inter in Binary Files//.

@e CONSTRUCT_TRANSPOSE_MTID

=
VOID_METHOD_TYPE(CONSTRUCT_TRANSPOSE_MTID, inter_construct *IC, inter_tree_node *P,
	inter_ti *grid, inter_ti max, inter_error_message **E)

inter_error_message *InterConstruct::transpose_construct(inter_package *owner,
	inter_tree_node *P, inter_ti *grid, inter_ti max) {
	inter_construct *IC = NULL;
	inter_error_message *E = InterConstruct::get_construct(P, &IC);
	if (E) return E;
	VOID_METHOD_CALL(IC, CONSTRUCT_TRANSPOSE_MTID, P, grid, max, &E);
	return E;
}
