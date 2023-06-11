[InterValuePairs::] Inter Value Pairs.

Two consecutive bytecode words are used to store a single value in binary Inter.

@ About time to define the types we're using to represent Inter words in C.
It turns out to be more convenient to define these by what amounts to |#define|
than to use |typedef|.

@d inter_ti unsigned int
@d signed_inter_ti int

@h Pairs.
A constant value in Inter code is represented by a pair of |inter_ti| values:
the format and the content.

=
typedef struct inter_pair {
	inter_ti data_format; /* one of the |*_IVAL| values below */
	inter_ti data_content;
} inter_pair;

@ These are the formats. Note that changing any of these values would invalidate
existing Inter binary files, necessitating a bump of //The Inter Version//.

@e DECIMAL_IVAL from 0x10000
@e HEX_IVAL
@e BINARY_IVAL
@e SIGNED_IVAL
@e TEXTUAL_IVAL
@e REAL_IVAL
@e DWORD_IVAL
@e PDWORD_IVAL
@e SYMBOLIC_IVAL
@e GLOB_IVAL
@e UNDEF_IVAL

@h Numeric pairs.
These can represent any |inter_ti| value, and are used when the data is a
literal integer. Note that they express both an integer and also a preferred
way to print it out -- as decimal, hexadecimal, binary, or signed decimal.
But these are all numerically equal. They affect only the way in which the
Inter program is printed to text files, not the meaning of the program.

=
inter_pair InterValuePairs::number(inter_ti N) {
	inter_pair pair;
	pair.data_format = DECIMAL_IVAL;
	pair.data_content = N;
	return pair;
}

inter_pair InterValuePairs::number_in_base(inter_ti N, int b) {
	inter_pair pair;
	switch (b) {
		case 2: pair.data_format = BINARY_IVAL; break;
		case 10: pair.data_format = DECIMAL_IVAL; break;
		case 16: pair.data_format = HEX_IVAL; break;
		default: internal_error("only bases 2, 10, 16 are supported");
	}
	pair.data_content = N;
	return pair;
}

inter_pair InterValuePairs::signed_number(int N) {
	inter_pair pair;
	pair.data_format = SIGNED_IVAL;
	pair.data_content = (inter_ti) N;
	return pair;
}

inter_pair InterValuePairs::number_from_I6_notation(text_stream *S) {
	int sign = 1, base = 10, from = 0;
	if (Str::prefix_eq(S, I"-", 1)) { sign = -1; from = 1; }
	if (Str::prefix_eq(S, I"$", 1)) { base = 16; from = 1; }
	if (Str::prefix_eq(S, I"$$", 2)) { base = 2; from = 2; }
	long long int N = 0;
	LOOP_THROUGH_TEXT(pos, S) {
		if (pos.index < from) continue;
		int c = Str::get(pos), d = 0;
		if ((c >= 'a') && (c <= 'z')) d = c-'a'+10;
		else if ((c >= 'A') && (c <= 'Z')) d = c-'A'+10;
		else if ((c >= '0') && (c <= '9')) d = c-'0';
		else return InterValuePairs::undef();
		if (d >= base) return InterValuePairs::undef();
		N = base*N + (long long int) d;
		if (pos.index > 34) return InterValuePairs::undef();
	}
	return InterValuePairs::number((inter_ti) (sign*N));
}

inter_ti InterValuePairs::to_number(inter_pair pair) {
	if (InterValuePairs::is_number(pair)) return pair.data_content;
	return 0;
}

inter_ti InterValuePairs::to_base(inter_pair pair) {
	switch (pair.data_format) {
		case DECIMAL_IVAL: return 10;
		case SIGNED_IVAL: return 10;
		case HEX_IVAL: return 16;
		case BINARY_IVAL: return 2;
	}
	return 0;
}

@ Testing:

=
int InterValuePairs::is_number(inter_pair pair) {
	if ((pair.data_format == DECIMAL_IVAL) ||
		(pair.data_format == HEX_IVAL) ||
		(pair.data_format == BINARY_IVAL) ||
		(pair.data_format == SIGNED_IVAL))
		return TRUE;
	return FALSE;
}

int InterValuePairs::is_one(inter_pair pair) {
	if ((InterValuePairs::is_number(pair)) &&
		(pair.data_content == 1)) return TRUE;
	return FALSE;
}

int InterValuePairs::is_zero(inter_pair pair) {
	if ((InterValuePairs::is_number(pair)) &&
		(pair.data_content == 0)) return TRUE;
	return FALSE;
}

@h Textual pairs.
These can represent an arbitrarily long literal string of text.

=
inter_pair InterValuePairs::from_text(inter_bookmark *IBM, text_stream *text) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, text);
	inter_pair pair;
	pair.data_format = TEXTUAL_IVAL;
	pair.data_content = ID;
	return pair;
}

text_stream *InterValuePairs::to_text(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_text(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

@ Testing:

=
int InterValuePairs::is_text(inter_pair pair) {
	if (pair.data_format == TEXTUAL_IVAL) return TRUE;
	return FALSE;
}

@h Real pairs.
These represent real numbers, but they do so by storing them as literal strings
prefaced by a sign character, |+| or |-|.

Though the argument here has type |double|, we are not guaranteeing that level
of service, and in fact these are likely to be no better than |float| precision
on some platforms.

=
inter_pair InterValuePairs::real(inter_bookmark *IBM, double g) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	if (g > 0) WRITE_TO(text_storage, "+");
	WRITE_TO(text_storage, "%g", g);
	inter_pair pair;
	pair.data_format = REAL_IVAL;
	pair.data_content = ID;
	return pair;
}

@ Inform 6 notation begins with a dollar |$| -- for example, |$+3.1415| -- but
otherwise is similar.

=
inter_pair InterValuePairs::real_from_I6_notation(inter_bookmark *IBM, text_stream *S) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	LOOP_THROUGH_TEXT(pos, S)
		if (Str::get(pos) != '$')
			PUT_TO(text_storage, Str::get(pos));
	inter_pair pair;
	pair.data_format = REAL_IVAL;
	pair.data_content = ID;
	return pair;
}

text_stream *InterValuePairs::to_textual_real(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_real(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

@ Testing:

=
int InterValuePairs::is_real(inter_pair pair) {
	if (pair.data_format == REAL_IVAL) return TRUE;
	return FALSE;
}

@h Dictionary word pairs.
These are relevant only to command-parser IF projects, and none of these values
otherwise ever exist. They exist in two forms, one marked as possibly plural,
the other not so marked. Just because a word is marked plural, it doesn't follow
that every usage of it will be in a plural noun context: so "singular" here is
best read as "no comment on the number of this if it is used in a noun context".

It would be appealing to remove these from the design of Inter, but that's harder
than it seems. Dictionary words have semantics which are hard to imitate with
other values which would be legal in a constant context.

=
inter_pair InterValuePairs::from_singular_dword(inter_bookmark *IBM, text_stream *word) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, word);
	inter_pair pair;
	pair.data_format = DWORD_IVAL;
	pair.data_content = ID;
	return pair;
}

inter_pair InterValuePairs::from_plural_dword(inter_bookmark *IBM, text_stream *word) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, word);
	inter_pair pair;
	pair.data_format = PDWORD_IVAL;
	pair.data_content = ID;
	return pair;
}

text_stream *InterValuePairs::to_dictionary_word(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_dword(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

@ Testing:

=
int InterValuePairs::is_dword(inter_pair pair) {
	if ((pair.data_format == DWORD_IVAL) || (pair.data_format == PDWORD_IVAL)) return TRUE;
	return FALSE;
}

int InterValuePairs::is_singular_dword(inter_pair pair) {
	if (pair.data_format == DWORD_IVAL) return TRUE;
	return FALSE;
}

int InterValuePairs::is_plural_dword(inter_pair pair) {
	if (pair.data_format == PDWORD_IVAL) return TRUE;
	return FALSE;
}

@h Symbolic pairs.
All other pairs represent known literal values, but a symbolic pair delegates
that by saying "it's the value of this symbol". For example, a symbolic pair
could mean "whatever the value of |WORDSIZE| is". Note that this symbol might
not even be defined in the current Inter tree: it could be wired to a plug, which
expects to find a definition in some other tree when linking takes place.

=
inter_pair InterValuePairs::symbolic(inter_bookmark *IBM, inter_symbol *S) {
	return InterValuePairs::symbolic_in(InterBookmark::package(IBM), S);
}

inter_pair InterValuePairs::symbolic_in(inter_package *pack, inter_symbol *S) {
	inter_tree *I = InterPackage::tree(pack);
	if (S == NULL) internal_error("no symbol");
	inter_pair pair;
	pair.data_format = SYMBOLIC_IVAL;
	pair.data_content = InterSymbolsTable::id_from_symbol(I, pack, S);
	return pair;
}

inter_symbol *InterValuePairs::to_symbol(inter_pair pair, inter_symbols_table *T) {
	if (InterValuePairs::is_symbolic(pair))
		return InterSymbolsTable::symbol_from_ID(T, pair.data_content);
	return NULL;
}

inter_symbol *InterValuePairs::to_symbol_not_following(inter_pair pair, inter_symbols_table *T) {
	if (InterValuePairs::is_symbolic(pair))
		return InterSymbolsTable::symbol_from_ID_not_following(T, pair.data_content);
	return NULL;
}

inter_symbol *InterValuePairs::to_symbol_in(inter_pair pair, inter_package *pack) {
	return InterValuePairs::to_symbol(pair, InterPackage::scope(pack));
}

inter_symbol *InterValuePairs::to_symbol_at(inter_pair pair, inter_tree_node *P) {
	return InterValuePairs::to_symbol(pair, InterPackage::scope_of(P));
}

@ Testing:

=
int InterValuePairs::is_symbolic(inter_pair pair) {
	if (pair.data_format == SYMBOLIC_IVAL) return TRUE;
	return FALSE;
}

@h Glob pairs.
Globs are a desperation measure. They represent a value, but which is expressed
in terms of raw source code which will produce that value. For instance, if you
knew your Inter code would be compiled to C, you could have a glob of |"time(0)"|,
but of course this wouldn't work in compiled in a constant context, and wouldn't
work if the Inter were aimed at any other final code-generator than C.

Globs were needed in the development stages of Inter but are now never produced
anywhere in the Inter tool chain except in response to the textual Inter notation
below. They cling on here just in case they are needed again.

=
inter_pair InterValuePairs::glob(inter_bookmark *IBM, text_stream *text) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_package *pack = InterBookmark::package(IBM);
	inter_ti ID = InterWarehouse::create_text(InterTree::warehouse(I), pack);
	text_stream *text_storage = InterWarehouse::get_text(InterTree::warehouse(I), ID);
	Str::copy(text_storage, text);
	inter_pair pair;
	pair.data_format = GLOB_IVAL;
	pair.data_content = ID;
	return pair;
}

text_stream *InterValuePairs::to_glob_text(inter_tree *I, inter_pair pair) {
	if (InterValuePairs::is_glob(pair))
		return InterWarehouse::get_text(InterTree::warehouse(I), pair.data_content);
	return NULL;
}

@ Testing:

=
int InterValuePairs::is_glob(inter_pair pair) {
	if (pair.data_format == GLOB_IVAL) return TRUE;
	return FALSE;
}

@h The undef pair.
There is just one |undef| pair. It means "undefined value", and allows functions
which return //inter_pair// to signal that they couldn't work anything useful out.
(See for example //InterValuePairs::number_from_I6_notation// above.)

=
inter_pair InterValuePairs::undef(void) {
	inter_pair pair; 
	pair.data_format = UNDEF_IVAL;
	pair.data_content = 0;
	return pair;
}

@ Testing:

=
int InterValuePairs::is_undef(inter_pair pair) {
	if (pair.data_format == UNDEF_IVAL) return TRUE;
	return FALSE;
}

@h Pairs in bytecode.
In binary Inter, value pairs are always stored as consecutive fields in the
bytecode of instructions. These fields should be read or written only with the
following functions:

=
inter_pair InterValuePairs::get(inter_tree_node *P, int field) {
	inter_pair pair;
	pair.data_format = P->W.instruction[field];
	pair.data_content = P->W.instruction[field+1];
	return pair;
}

void InterValuePairs::set(inter_tree_node *P, int field, inter_pair pair) {
	P->W.instruction[field] = pair.data_format;
	P->W.instruction[field+1] = pair.data_content;
}

@ When creating new instructions, //InterValuePairs::set// cannot be used
because the two words of a pair need to be supplied as two |inter_ti| values.
For that purpose only, the following functions may be used:

=
inter_ti InterValuePairs::to_word1(inter_pair pair) {
	return pair.data_format;
}
inter_ti InterValuePairs::to_word2(inter_pair pair) {
	return pair.data_content;
}

@h Transposition.
See //Inter in Binary Files// for more on this. Basically the idea is that those
pairs holding text or package resource ID numbers will need correction when read
in from a binary Inter file (because in that process, resource ID numbers change).

=
inter_pair InterValuePairs::transpose(inter_pair pair, inter_ti *grid, inter_ti grid_extent,
	inter_error_message **E) {
	switch (pair.data_format) {
		case DWORD_IVAL:
		case PDWORD_IVAL:
		case TEXTUAL_IVAL:
		case REAL_IVAL:
		case GLOB_IVAL:
			pair.data_content = grid[pair.data_content];
			break;
	}
	return pair;
}

@h Verification.
Some minimal sanity checks on a pair, which can be performed quickly. There are
numerous ways bad data could still pass this, but it will certainly catch random
garbage, and doesn't take much time.

=
inter_error_message *InterValuePairs::verify(inter_package *owner, inter_tree_node *P,
	inter_pair pair, inter_type type) {
	inter_symbols_table *scope = InterPackage::scope(owner);
	if (scope == NULL) scope = Inode::globals(P);
	if (InterValuePairs::is_number(pair)) @<Check this is in range for the type@>
	switch (pair.data_format) {
		case SYMBOLIC_IVAL: @<Check this is reasonable, if we know what it is yet@>;
		case DWORD_IVAL:
		case PDWORD_IVAL:
		case TEXTUAL_IVAL:
		case REAL_IVAL:
		case GLOB_IVAL:
		case UNDEF_IVAL:
			return NULL;
	}
	return Inode::error(P, I"value of unknown category", NULL);
}

@<Check this is in range for the type@> =
	long long int I = (signed_inter_ti) pair.data_content;
	if (InterTypes::literal_is_in_range(I, type) == FALSE)
		return Inode::error(P, I"value out of range", NULL);
	return NULL;

@<Check this is reasonable, if we know what it is yet@> =
	inter_symbol *symb = InterSymbolsTable::symbol_from_ID(scope, pair.data_content);
	if (symb == NULL) return Inode::error(P, I"no such symbol", NULL);
	if (InterSymbol::misc_but_undefined(symb)) return NULL;
	if (InterSymbol::defined_elsewhere(symb)) return NULL;
	if (InterTypes::expresses_value(symb) == FALSE)
		return Inode::error(P, I"nonconstant symbol", InterSymbol::identifier(symb));
	inter_type symbol_type = InterTypes::of_symbol(symb);
	return InterTypes::can_be_used_as(symbol_type, type,
		InterSymbol::identifier(symb), Inode::get_error_location(P));
