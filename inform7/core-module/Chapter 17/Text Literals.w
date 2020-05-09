[Strings::TextLiterals::] Text Literals.

In this section we compile text constants.

@h Definitions.

@ It might not seem necessary to do much about literal text, since we're
compiling to what is already a high-enough level language to take care
of that for us -- that is, it seems reasonable just to translate

>> say "Hello world."

straight into

|print "Hello world.";|

The reason we don't do this is that we want string constants in the target
virtual machine to have addresses in alphabetical order; then a simple
unsigned comparison of packed addresses at run-time is equivalent to an
alphabetical comparison of the text. (We make great use of this when
sorting tables.) We can also ensure that two literal texts with the
same contents are numerically equal, rather than being compiled twice over
with two different addresses at which is stored duplicate data. So in fact
we compile constants such as:

|Constant TX_L_14 "Hello world.";|

and then refer to them as:

|print TX_L_14;|

To do this we need to store all of the string constants in such a way that
we can efficiently search and keep them in alphabetical order. We do this
with a red-black tree: a form of balanced binary tree structure such that
nodes appear in alphabetical order from left to right in the tree, but
which has a roughly equal depth throughout, so that the number of string
comparisons needed to search it is nearly the binary logarithm of the
number of nodes. For an account of the theory, see Sedgewick, "Algorithms"
(2nd edn, chap. 15). Each node in the tree is marked "red" or "black":

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

@ There are two exceptions. One is that the empty text |""| is compiled to
a special value |EMPTY_TEXT_VALUE|, not to a |TX_L_*| constant, since we need
it always to be present whether or not it occurs in the source text as such.

The other is that Inform is sometimes compiling text not to its output code
but to a metadata file like the XML iFiction record instead, which takes a
more literal approach to literal text. So we can force it into a mode which
short-circuits the above mechanism:

=
int encode_constant_text_bibliographically = FALSE; /* Compile literal text semi-literally */

@ We are allowed to flag one text where ordinary apostrophe-to-double-quote
substitution doesn't occur: this is used for the title at the top of the
source text, and nothing else.

=
int wn_quote_suppressed = -1;
void Strings::TextLiterals::suppress_quote_expansion(wording W) {
	wn_quote_suppressed = Wordings::first_wn(W);
}

@ The following creates a node; the word number is the location of the text
in the source.

=
literal_text *Strings::TextLiterals::lt_new(int w1, int colour) {
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
	package_request *PR = Hierarchy::package_in_enclosure(LITERALS_HAP);
	x->lt_iname = Hierarchy::make_iname_in(TEXT_LITERAL_HL, PR);
	Produce::annotate_i(x->lt_iname, TEXT_LITERAL_IANN, 1);
	if ((wn_quote_suppressed >= 0) && (w1 == wn_quote_suppressed)) x->unexpanded = TRUE;
	return x;
}

@ And this utility compares the text at a given source position with the
contents of a node in the tree:

=
int Strings::TextLiterals::lt_cmp(int w1, literal_text *lt) {
	if (lt == NULL) return 1;
	if (lt->lt_position < 0) return 1;
	return Wide::cmp(Lexer::word_text(w1), Lexer::word_text(lt->lt_position));
}

@ =
void Strings::TextLiterals::mark_as_unescaped(literal_text *lt) {
	if (lt) lt->unescaped = TRUE;
}

@ That's it for the preliminaries.

=
literal_text *Strings::TextLiterals::compile_literal(value_holster *VH, int write, wording W) {
	int w1 = Wordings::first_wn(W);
	if (Wide::cmp(Lexer::word_text(w1), L"\"\"") == 0) {
		if ((write) && (VH)) Emit::holster(VH, Hierarchy::find(EMPTY_TEXT_VALUE_HL));
		return NULL;
	}
	if (z_node == NULL) @<Initialise the red-black tree@>;
	@<Search for the text as a key in the red-black tree@>;
}

@ Note that the tree doesn't begin empty, but with a null node. Moreover,
the tree is always a strict binary tree in which every node always has two
children. One or both may be the Z node, and both children of Z are itself.
This sounds tricky, but minimises the number of comparisons needed to
check that branches are valid, the alternative being to allow some branches
which are null pointers.

@<Initialise the red-black tree@> =
	z_node = Strings::TextLiterals::lt_new(-1, BLACK_NODE); z_node->left_node = z_node; z_node->right_node = z_node;
	root_of_literal_text = Strings::TextLiterals::lt_new(-1, BLACK_NODE);
	root_of_literal_text->left_node = z_node;
	root_of_literal_text->right_node = z_node;

@<Search for the text as a key in the red-black tree@> =
	literal_text *x = root_of_literal_text, *p = x, *g = p, *gg = g;
	int went_left = FALSE; /* redundant assignment to appease |gcc -O2| */
	do {
		gg = g; g = p; p = x;
		int sgn = Strings::TextLiterals::lt_cmp(w1, x);
		if (sgn == 0) @<Locate this as the new node@>;
		if (sgn < 0) { went_left = TRUE; x = x->left_node; }
		if (sgn > 0) { went_left = FALSE; x = x->right_node; }
		if ((x->left_node->node_colour == RED_NODE) &&
			(x->right_node->node_colour == RED_NODE))
			@<Perform a split@>;
	} while (x != z_node);

	x = Strings::TextLiterals::lt_new(w1, RED_NODE);
	x->left_node = z_node; x->right_node = z_node;
	if (went_left == TRUE) p->left_node = x; else p->right_node = x;
	literal_text *new_x = x;
	@<Perform a split@>;
	x = new_x;
	@<Locate this as the new node@>;

@<Locate this as the new node@> =
	if (encode_constant_text_bibliographically) x->bibliographic_conventions = TRUE;
	if (write) {
		if (x->lt_sba_iname == NULL) {
			package_request *PR = Hierarchy::package_in_enclosure(BLOCK_CONSTANTS_HAP);
			x->lt_sba_iname = Hierarchy::make_iname_in(BLOCK_CONSTANT_HL, PR);
		}
		if (VH) Emit::holster(VH, x->lt_sba_iname);
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
	if (Strings::TextLiterals::lt_cmp(w1, g) < 0) left_of_g = TRUE;
	if (Strings::TextLiterals::lt_cmp(w1, p) < 0) left_of_p = TRUE;
	if (left_of_g != left_of_p) p = Strings::TextLiterals::rotate(w1, g);
	x = Strings::TextLiterals::rotate(w1, gg);
	x->node_colour = BLACK_NODE;

@ Rotation is a local tree rearrangement which tends to move it towards
rather than away from "balance", that is, towards a configuration where
the depth of tree is roughly even.

=
literal_text *Strings::TextLiterals::rotate(int w1, literal_text *y) {
	literal_text *c, *gc;
	if (Strings::TextLiterals::lt_cmp(w1, y) < 0) c = y->left_node; else c = y->right_node;
	if (Strings::TextLiterals::lt_cmp(w1, c) < 0) {
		gc = c->left_node; c->left_node = gc->right_node; gc->right_node = c;
	} else {
		gc = c->right_node; c->right_node = gc->left_node; gc->left_node = c;
	}
	if (Strings::TextLiterals::lt_cmp(w1, y) < 0) y->left_node = gc; else y->right_node = gc;
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

void Strings::TextLiterals::compile_quotation(value_holster *VH, wording W) {
	literal_text *lt = Strings::TextLiterals::compile_literal(VH, TRUE, W);
	if (lt) lt->as_boxed_quotation = TRUE;
	else
		Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_EmptyQuotationBox),
			"a boxed quotation can't be empty",
			"though I suppose you could make it consist of just a few spaces "
			"to get a similar effect if you really needed to.");
	extent_of_runtime_quotations_array++;
}

int Strings::TextLiterals::CCOUNT_QUOTATIONS(void) {
	return extent_of_runtime_quotations_array;
}

@ A version from fixed text:

=
void Strings::TextLiterals::compile_literal_from_text(inter_name *context, inter_t *v1, inter_t *v2, wchar_t *p) {
	literal_text *lt = Strings::TextLiterals::compile_literal(NULL, TRUE, Feeds::feed_text(p));
	Emit::to_ival_in_context(context, v1, v2, lt->lt_sba_iname);
}

@ The above gradually piled up the need for |TX_L_*| constants/routines,
as compilation went on: now comes the reckoning, when we have to declare
all of these. We traverse the tree from left to right, because that produces
the texts in alphabetical order; the Z-node, of course, is a terminal and
shouldn't be visited, and the root node has no text (and so has word
number |-1|).

=
void Strings::TextLiterals::compile(void) {
	if (root_of_literal_text)
		Strings::TextLiterals::traverse_lts(root_of_literal_text);
}

void Strings::TextLiterals::traverse_lts(literal_text *lt) {
	if (lt->left_node != z_node) Strings::TextLiterals::traverse_lts(lt->left_node);
	if (lt->lt_position >= 0) {
		if (lt->as_boxed_quotation == FALSE)
			@<Compile a standard literal text@>
		else
			@<Compile a boxed-quotation literal text@>;
	}
	if (lt->right_node != z_node) Strings::TextLiterals::traverse_lts(lt->right_node);
}

@<Compile a standard literal text@> =
	if (Task::wraps_existing_storyfile()) { /* to prevent trouble when no story file is really being made */
		Emit::named_string_constant(lt->lt_iname, I"--");
	} else {
		TEMPORARY_TEXT(TLT);
		int options = CT_DEQUOTE + CT_EXPAND_APOSTROPHES;
		if (lt->unescaped) options = CT_DEQUOTE;
		if (lt->bibliographic_conventions)
			options += CT_RECOGNISE_APOSTROPHE_SUBSTITUTION + CT_RECOGNISE_UNICODE_SUBSTITUTION;
		if (lt->unexpanded) options = CT_DEQUOTE;
		CompiledText::from_wide_string(TLT, Lexer::word_text(lt->lt_position), options);
		Emit::named_string_constant(lt->lt_iname, TLT);
		DISCARD_TEXT(TLT);
	}
	if (lt->small_block_array_needed) {
		packaging_state save = Emit::named_array_begin(lt->lt_sba_iname, K_value);
		Emit::array_iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
		Emit::array_iname_entry(lt->lt_iname);
		Emit::array_end(save);
	}

@<Compile a boxed-quotation literal text@> =
	package_request *PR = Hierarchy::package_in_enclosure(BOX_QUOTATIONS_HAP);
	inter_name *iname = Hierarchy::make_iname_in(BOX_QUOTATION_FN_HL, PR);

	if (lt->lt_sba_iname == NULL) {
		package_request *PR = Hierarchy::package_in_enclosure(BLOCK_CONSTANTS_HAP);
		lt->lt_sba_iname = Hierarchy::make_iname_in(BLOCK_CONSTANT_HL, PR);
	}

	Emit::named_iname_constant(lt->lt_sba_iname, K_value, iname);

	packaging_state save = Routines::begin(iname);
	Produce::inv_primitive(Emit::tree(), BOX_BIP);
	Produce::down(Emit::tree());
		TEMPORARY_TEXT(T);
		CompiledText::bq_from_wide_string(T, Lexer::word_text(lt->lt_position));
		Produce::val_text(Emit::tree(), T);
		DISCARD_TEXT(T);
	Produce::up(Emit::tree());
	Routines::end(save);

@ =
void Strings::TextLiterals::compile_small_block(OUTPUT_STREAM, literal_text *lt) {
}

@ =
literal_text *Strings::TextLiterals::compile_literal_sb(value_holster *VH, wording W) {
	literal_text *lt = NULL;
	if (TEST_COMPILATION_MODE(CONSTANT_CMODE)) {
		package_request *PR = Hierarchy::package_in_enclosure(BLOCK_CONSTANTS_HAP);
		inter_name *N = Hierarchy::make_iname_in(BLOCK_CONSTANT_HL, PR);
		packaging_state save = Emit::named_late_array_begin(N, K_value);
		lt = Strings::TextLiterals::compile_literal(NULL, FALSE, W);
		Emit::array_iname_entry(Hierarchy::find(PACKED_TEXT_STORAGE_HL));
		if (lt == NULL) Emit::array_iname_entry(Hierarchy::find(EMPTY_TEXT_PACKED_HL));
		else Emit::array_iname_entry(lt->lt_iname);
		Emit::array_end(save);
		if (N) Emit::holster(VH, N);
	} else {
		lt = Strings::TextLiterals::compile_literal(VH, TRUE, W);
	}
	return lt;
}
