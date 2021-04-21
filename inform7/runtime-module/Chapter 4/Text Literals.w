[TextLiterals::] Text Literals.

In this section we compile text constants.

@

=
inter_name *TextLiterals::small_block(inter_name *large_block, inter_name *format) {
	inter_name *N = Enclosures::new_small_block_for_constant();
	return TextLiterals::small_block_at(large_block, format, N);
}

inter_name *TextLiterals::small_block_at(inter_name *large_block, inter_name *format,
	inter_name *small_block) {
	packaging_state save = EmitArrays::begin_late(small_block, K_value);
	EmitArrays::iname_entry(large_block);
	EmitArrays::iname_entry(format);
	EmitArrays::end(save);
	return small_block;
}

inter_name *TextLiterals::default_text(void) {
	return TextLiterals::small_block(
			Hierarchy::find(PACKED_TEXT_STORAGE_HL),
			Hierarchy::find(EMPTY_TEXT_PACKED_HL));
}

@ Each literal text needed is stored as a "small block array", or SBA, with
just two words in it. These are then compiled in the Inter hierarchy in
alphabetical sequence, with no repetitions. Because of that, a numerical
comparison of the addresses of these literal texts is equivalent to an
alphabetical comparison of their contents.

But it means we must store up every literal text, and keep them in a sorted
condition. To do so reasonably efficiently, we use a "red-black tree": a form of
balanced binary tree structure such that nodes appear in alphabetical order
from left to right in the tree, but which has a roughly equal depth throughout,
so that the number of string comparisons needed to search it is nearly the
binary logarithm of the number of nodes.

For an account of the theory, see Sedgewick, "Algorithms" (2nd edn, chap. 15),
or //this Wikipedia page -> https://en.wikipedia.org/wiki/Red–black_tree//.

The name is used because each node in the tree is marked either "red" or "black":

@d RED_NODE 1
@d BLACK_NODE 2

@ The nodes in the tree will be instances of the following structure:

=
typedef struct literal_text {
	int lt_position; /* position in the source of quoted text */
	int as_boxed_quotation; /* formatted for the Inform 6 |box| statement */
	int bibliographic_conventions; /* mostly for apostrophes */
	int unescaped; /* completely so */
	int unexpanded; /* don't expand single quotes to double */
	int node_colour; /* red or black: see above */
	struct literal_text *left_node; /* within their red-black tree */
	struct literal_text *right_node;
	int small_block_array_needed;
	struct inter_name *lt_iname;
	struct inter_name *lt_sba_iname;
	CLASS_DEFINITION
} literal_text;

@ The tree is always connected, with a single root node. The so-called Z node
is a special node representing a leaf with no contents, Z presumably standing
for zero.

=
literal_text *root_of_literal_text = NULL;
literal_text *z_node = NULL;

@ When Inform is storing text not for use at run-time but instead for the
bibliographic data in, for example, its XML-format iFiction record, it needs
to read text literals in a special mode bypassing all this red-black business:

=
int encode_constant_text_bibliographically = FALSE; /* Compile literal text semi-literally */

@ We are allowed to flag one text where ordinary apostrophe-to-double-quote
substitution doesn't occur: this is used for the title at the top of the
source text, and nothing else.

=
int wn_quote_suppressed = -1;
void TextLiterals::suppress_quote_expansion(wording W) {
	wn_quote_suppressed = Wordings::first_wn(W);
}

@ The following creates a node in the tree; the word number is the location of
the text in the source -- recall that quoted text, whatever its contents,
always occupies just one word number.

=
literal_text *TextLiterals::lt_new(int w1, int colour) {
	literal_text *x = CREATE(literal_text);
	x->left_node = NULL;
	x->right_node = NULL;
	x->node_colour = colour;
	x->lt_position = w1;
	x->as_boxed_quotation = FALSE;
	x->bibliographic_conventions = FALSE;
	x->unescaped = FALSE;
	x->unexpanded = FALSE;
	x->small_block_array_needed = FALSE;
	x->lt_sba_iname = NULL;
	x->lt_iname = Enclosures::new_iname(LITERALS_HAP, TEXT_LITERAL_HL);
	Produce::annotate_i(x->lt_iname, TEXT_LITERAL_IANN, 1);
	if ((wn_quote_suppressed >= 0) && (w1 == wn_quote_suppressed)) x->unexpanded = TRUE;
	return x;
}

@ And this utility compares the text at a given source position with the
text stored at a node in the tree:

=
int TextLiterals::lt_cmp(int w1, literal_text *lt) {
	if (lt == NULL) return 1;
	if (lt->lt_position < 0) return 1;
	return Wide::cmp(Lexer::word_text(w1), Lexer::word_text(lt->lt_position));
}

@ =
void TextLiterals::mark_as_unescaped(literal_text *lt) {
	if (lt) lt->unescaped = TRUE;
}

@ That's it for the preliminaries.

=
literal_text *TextLiterals::compile_literal(value_holster *VH, int write, wording W) {
	int w1 = Wordings::first_wn(W);
	if (Wide::cmp(Lexer::word_text(w1), L"\"\"") == 0) @<Handle the empty text outside the tree@>;
	if (z_node == NULL) @<Initialise the red-black tree@>;
	@<Search for the text as a key in the red-black tree@>;
}

@ The empty text |""| compiles to a special value |EMPTY_TEXT_VALUE|, and is
not stored in the tree.

@<Handle the empty text outside the tree@> =
	if ((write) && (VH)) Emit::holster_iname(VH, Hierarchy::find(EMPTY_TEXT_VALUE_HL));
	return NULL;

@ Note that the tree doesn't begin empty, but with a null node. Moreover,
the tree is always a strict binary tree in which every node always has two
children. One or both may be the Z node, and both children of Z are itself.
This sounds tricky, but minimises the number of comparisons needed to
check that branches are valid, the alternative being to allow some branches
which are null pointers.

@<Initialise the red-black tree@> =
	z_node = TextLiterals::lt_new(-1, BLACK_NODE);
	z_node->left_node = z_node; z_node->right_node = z_node;
	root_of_literal_text = TextLiterals::lt_new(-1, BLACK_NODE);
	root_of_literal_text->left_node = z_node;
	root_of_literal_text->right_node = z_node;

@<Search for the text as a key in the red-black tree@> =
	literal_text *x = root_of_literal_text, *p = x, *g = p, *gg = g;
	int went_left = FALSE; /* redundant assignment to appease |gcc -O2| */
	do {
		gg = g; g = p; p = x;
		int sgn = TextLiterals::lt_cmp(w1, x);
		if (sgn == 0) @<Locate this as the new node@>;
		if (sgn < 0) { went_left = TRUE; x = x->left_node; }
		if (sgn > 0) { went_left = FALSE; x = x->right_node; }
		if ((x->left_node->node_colour == RED_NODE) &&
			(x->right_node->node_colour == RED_NODE))
			@<Perform a split@>;
	} while (x != z_node);

	x = TextLiterals::lt_new(w1, RED_NODE);
	x->left_node = z_node; x->right_node = z_node;
	if (went_left == TRUE) p->left_node = x; else p->right_node = x;
	literal_text *new_x = x;
	@<Perform a split@>;
	x = new_x;
	@<Locate this as the new node@>;

@<Locate this as the new node@> =
	if (encode_constant_text_bibliographically) x->bibliographic_conventions = TRUE;
	if (write) {
		if (x->lt_sba_iname == NULL)
			x->lt_sba_iname = Enclosures::new_small_block_for_constant();
		if (VH) Emit::holster_iname(VH, x->lt_sba_iname);
		x->small_block_array_needed = TRUE;
	}
	return x;

@<Perform a split@> =
	x->node_colour = RED_NODE;
	x->left_node->node_colour = BLACK_NODE;
	x->right_node->node_colour = BLACK_NODE;
	if (p->node_colour == RED_NODE) @<Rotations will be needed@>;
	root_of_literal_text->right_node->node_colour = BLACK_NODE;

@<Rotations will be needed@> =
	g->node_colour = RED_NODE;
	int left_of_g = FALSE, left_of_p = FALSE;
	if (TextLiterals::lt_cmp(w1, g) < 0) left_of_g = TRUE;
	if (TextLiterals::lt_cmp(w1, p) < 0) left_of_p = TRUE;
	if (left_of_g != left_of_p) p = TextLiterals::rotate(w1, g);
	x = TextLiterals::rotate(w1, gg);
	x->node_colour = BLACK_NODE;

@ Rotation is a local tree rearrangement which tends to move it towards
rather than away from "balance", that is, towards a configuration where
the depth of tree is roughly even.

=
literal_text *TextLiterals::rotate(int w1, literal_text *y) {
	literal_text *c, *gc;
	if (TextLiterals::lt_cmp(w1, y) < 0) c = y->left_node; else c = y->right_node;
	if (TextLiterals::lt_cmp(w1, c) < 0) {
		gc = c->left_node; c->left_node = gc->right_node; gc->right_node = c;
	} else {
		gc = c->right_node; c->right_node = gc->left_node; gc->left_node = c;
	}
	if (TextLiterals::lt_cmp(w1, y) < 0) y->left_node = gc; else y->right_node = gc;
	return gc;
}

@ It's a little strange to be writing, in 2012, code to handle an idiosyncratic
one-off form of text called a "quotation", just to match an idiosyncratic
feature of Inform 1 from 1993 which was in turn matching an idiosyncratic
feature of version 4 of the Z-machine from 1985 which, in turn, existed only
to serve the needs of an unusual single work of IF called "Trinity".
But here we are. Boxed quotations are handled much like other literal
texts in that they enter the red-black tree, but they are marked out as
different for compilation purposes.

=
int extent_of_runtime_quotations_array = 1; /* start at 1 to avoid 0 length */

void TextLiterals::compile_quotation(value_holster *VH, wording W) {
	literal_text *lt = TextLiterals::compile_literal(VH, TRUE, W);
	if (lt) lt->as_boxed_quotation = TRUE;
	else
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_EmptyQuotationBox),
			"a boxed quotation can't be empty",
			"though I suppose you could make it consist of just a few spaces "
			"to get a similar effect if you really needed to.");
	extent_of_runtime_quotations_array++;
}

int TextLiterals::CCOUNT_QUOTATIONS(void) {
	return extent_of_runtime_quotations_array;
}

@ A version from fixed text:

=
void TextLiterals::compile_literal_from_text(inter_name *context,
	inter_ti *v1, inter_ti *v2, wchar_t *p) {
	literal_text *lt =
		TextLiterals::compile_literal(NULL, TRUE, Feeds::feed_C_string(p));
	Emit::to_value_pair_in_context(context, v1, v2, lt->lt_sba_iname);
}

@ The above gradually piled up the need for |TX_L_*| constants/routines,
as compilation went on: now comes the reckoning, when we have to declare
all of these. We traverse the tree from left to right, because that produces
the texts in alphabetical order; the Z-node, of course, is a terminal and
shouldn't be visited, and the root node has no text (and so has word
number |-1|).

=
void TextLiterals::compile(void) {
	if (root_of_literal_text)
		TextLiterals::traverse_lts(root_of_literal_text);
}

void TextLiterals::traverse_lts(literal_text *lt) {
	if (lt->left_node != z_node) TextLiterals::traverse_lts(lt->left_node);
	if (lt->lt_position >= 0) {
		if (lt->as_boxed_quotation == FALSE)
			@<Compile a standard literal text@>
		else
			@<Compile a boxed-quotation literal text@>;
	}
	if (lt->right_node != z_node) TextLiterals::traverse_lts(lt->right_node);
}

@<Compile a standard literal text@> =
	if (Task::wraps_existing_storyfile()) { /* to prevent trouble when no story file is really being made */
		Emit::text_constant(lt->lt_iname, I"--");
	} else {
		TEMPORARY_TEXT(TLT)
		int options = CT_DEQUOTE + CT_EXPAND_APOSTROPHES;
		if (lt->unescaped) options = CT_DEQUOTE;
		if (lt->bibliographic_conventions)
			options += CT_RECOGNISE_APOSTROPHE_SUBSTITUTION + CT_RECOGNISE_UNICODE_SUBSTITUTION;
		if (lt->unexpanded) options = CT_DEQUOTE;
		CompiledText::from_wide_string(TLT, Lexer::word_text(lt->lt_position), options);
		Emit::text_constant(lt->lt_iname, TLT);
		DISCARD_TEXT(TLT)
	}
	if (lt->small_block_array_needed) {
		TextLiterals::small_block_at(
			Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL),
			lt->lt_iname,
			lt->lt_sba_iname);
	}

@<Compile a boxed-quotation literal text@> =
	inter_name *iname = Enclosures::new_iname(BOX_QUOTATIONS_HAP, BOX_QUOTATION_FN_HL);

	if (lt->lt_sba_iname == NULL)
		lt->lt_sba_iname = Enclosures::new_small_block_for_constant();

	Emit::iname_constant(lt->lt_sba_iname, K_value, iname);

	packaging_state save = Functions::begin(iname);
	EmitCode::inv(BOX_BIP);
	EmitCode::down();
		TEMPORARY_TEXT(T)
		CompiledText::bq_from_wide_string(T, Lexer::word_text(lt->lt_position));
		EmitCode::val_text(T);
		DISCARD_TEXT(T)
	EmitCode::up();
	Functions::end(save);

@ =
literal_text *TextLiterals::compile_literal_sb(value_holster *VH, wording W) {
	literal_text *lt = NULL;
	if (CompileValues::compiling_in_constant_mode()) {
		lt = TextLiterals::compile_literal(NULL, FALSE, W);
		inter_name *N = NULL;
		if (lt == NULL) N = TextLiterals::default_text();
		else N = TextLiterals::small_block(Hierarchy::find(PACKED_TEXT_STORAGE_HL), lt->lt_iname);
		Emit::holster_iname(VH, N);
	} else {
		lt = TextLiterals::compile_literal(VH, TRUE, W);
	}
	return lt;
}
