[InterSymbol::] Symbols.

To manage named symbols in inter code.

@h Creation.
Each symbol belongs to exactly one symbols table, and thus to exactly one
package; its ID is unique within that table, and therefore package.

Given that design, it might seem a cleaner solution simply to make the
|symbol_array| of a symbols table be an array of |inter_symbol| structures,
rather than (as it actually is) an array of |inter_symbol *| pointers which
point to |inter_symbol| structures stored elsewhere. However:

(a) It makes binary loading easier to use this indirection, and
(b) It means that pointers to symbols remain valid when symbols tables expand
and then have to dynamically resize their |symbol_array| arrays, which may
in some cases move them in memory.

This all means we have to be careful. The following statements are true:

(1) Symbols are created only by symbols tables, and only as a response to
the "creating" version of name lookups.
(2) No symbol is ever moved from one table to another.
(3) No symbol ever occurs more than once in any table.
(4) No symbol ever occurs in more than one table.

But this is false:

(5) Every symbol belongs to a table.

Although it is true that every symbol is created in a table, it might later
be struck out with the //InterSymbolsTable::remove_symbol// function. If so,
it cannot be reinserted into that or any other table: it is gone forever.

=
typedef struct inter_symbol {
	struct inter_symbols_table *owning_table;
	inter_ti symbol_ID;
	int symbol_status;
	struct text_stream *symbol_name;
	struct text_stream *translate_text;

	struct inter_tree_node *definition;
	struct inter_annotation_set annotations;
	struct wiring_data wiring;
	struct transmigration_data transmigration;
	struct general_pointer translation_data;
} inter_symbol;

@ For the reasons given above, this function must only be called from
//InterSymbolsTable::search_inner//. If what you want is just to create a
symbol with a particular name, call //InterSymbolsTable::symbol_from_name_creating//,
not this.

Note that any symbol whose name matches //Metadata::valid_key// is made a
metadata symbol: in practice that means if its name begins with |^|.

=
inter_symbol *InterSymbol::new_for_symbols_table(text_stream *name, inter_symbols_table *T,
	inter_ti ID) {
	if (Str::len(name) == 0) internal_error("proposed symbol has empty name");
	if (ID < SYMBOL_BASE_VAL) internal_error("proposed symbol ID invalid");

	inter_symbol *S = CREATE(inter_symbol);
	S->owning_table = T;
	S->symbol_ID = ID;
	S->symbol_status = 0;
	S->symbol_name = Str::duplicate(name);
	S->translate_text = NULL;

	if (Metadata::valid_key(name)) InterSymbol::make_metadata_key(S);
	else InterSymbol::make_miscellaneous(S);

	S->definition = NULL;
	S->annotations = Inter::Annotations::new_set();
	S->wiring = Wiring::new_wiring_data(S);
	S->transmigration = Inter::Transmigration::new_transmigration_data(S);
	S->translation_data = NULL_GENERAL_POINTER;

	LOGIF(INTER_SYMBOLS, "Created symbol $3 in $4\n", S, T);
	return S;
}

@ =
inter_package *InterSymbol::package(inter_symbol *S) {
	if (S == NULL) return NULL;
	return InterSymbolsTable::package(S->owning_table);
}

@ This is used only as a final criterion in sorting algorithms for symbols.
It assumes no table contains more than 100,000 symbols, which I think is a
pretty safe assumption, but in fact a violation of this would make no real
difference.

=
int InterSymbol::sort_number(const inter_symbol *S) {
	if (S == NULL) return 0;
	return 100000 * (S->owning_table->allocation_id) +
		(int) (S->symbol_ID - SYMBOL_BASE_VAL);
}

@h Status.
The //inter_symbol// structure could not really be called concise, but we
do make some effort, by packing various flags into a single |symbol_status| field.

First, the "type" of a symbol is enumerated in these 3 bits:

@d MISC_ISYMT               0x00000000
@d PLUG_ISYMT               0x00000001
@d SOCKET_ISYMT             0x00000002
@d LABEL_ISYMT              0x00000003
@d LOCAL_ISYMT              0x00000004

@d SYMBOL_TYPE_STATUS_MASK  0x00000007

=
int InterSymbol::get_type(inter_symbol *S) {
	return S->symbol_status & SYMBOL_TYPE_STATUS_MASK;
}

void InterSymbol::set_type(inter_symbol *S, int V) {
	S->symbol_status = S->symbol_status - (S->symbol_status & SYMBOL_TYPE_STATUS_MASK) + V;
}

@ Subsequent bits are used for miscellaneous persistent flags, and then after
that for some transient flags:

@d MAKE_NAME_UNIQUE_ISYMF   0x00000008
@d METADATA_KEY_ISYMF 		0x00000010

@d SYMBOL_FLAGS_STATUS_MASK 0x00000018

@d TRAVERSE_MARK_ISYMF  	0x00000020
@d ATTRIBUTE_MARK_ISYMF 	0x00000040
@d USED_MARK_ISYMF          0x00000080

=
int InterSymbol::get_flag(inter_symbol *S, int f) {
	if (S == NULL) internal_error("no symbol");
	return (S->symbol_status & f)?TRUE:FALSE;
}

void InterSymbol::set_flag(inter_symbol *S, int f) {
	if (S == NULL) internal_error("no symbol");
	S->symbol_status = S->symbol_status | f;
}

void InterSymbol::clear_flag(inter_symbol *S, int f) {
	if (S == NULL) internal_error("no symbol");
	if (S->symbol_status & f) S->symbol_status = S->symbol_status - f;
}

@ Transient flags convey no lasting meaning: they're used as workspace during
optimisations. The part of the word which must be preserved is:

@d NONTRANSIENT_SYMBOL_BITS (SYMBOL_FLAGS_STATUS_MASK + SYMBOL_TYPE_STATUS_MASK)

=
void InterSymbol::clear_transient_flags(inter_symbol *S) {
	S->symbol_status = (S->symbol_status) & NONTRANSIENT_SYMBOL_BITS;
}

@h Various sorts of symbol.
By far the most common symbols are the miscellaneous ones, which are destined
to be defined as constants, variables and the like.

=
void InterSymbol::make_miscellaneous(inter_symbol *S) {
	InterSymbol::set_type(S, MISC_ISYMT);
}

int InterSymbol::misc_but_undefined(inter_symbol *S) {
	if ((S) &&
		(InterSymbol::get_type(S) == MISC_ISYMT) &&
		(InterSymbol::is_defined(S) == FALSE))
		return TRUE; 
	return FALSE;
}

@ Symbols whose names begin |^| are metadata keys. Those should always be defined
as constants, cannot be wired, and are never compiled. See //Metadata// for more.

=
int InterSymbol::is_metadata_key(inter_symbol *S) {
	return InterSymbol::get_flag(S, METADATA_KEY_ISYMF);
}

void InterSymbol::make_metadata_key(inter_symbol *S) {
	InterSymbol::set_type(S, MISC_ISYMT);
	InterSymbol::set_flag(S, METADATA_KEY_ISYMF);
}

@ Labels are special symbols used to mark positions in function bodies to which
execution of code can jump. Their names must begin with a |.|.

=
int InterSymbol::is_label(inter_symbol *S) {
	if ((S) && (InterSymbol::get_type(S) == LABEL_ISYMT)) return TRUE;
	return FALSE;
}

void InterSymbol::make_label(inter_symbol *S) {
	if (Str::get_first_char(S->symbol_name) != '.') {
		LOG("Name is %S\n", S->symbol_name);
		internal_error("not a label name");
	}
	InterSymbol::set_type(S, LABEL_ISYMT);
	S->definition = NULL;
}

@ Local variable names behave very similarly, but have no naming convention.

=
int InterSymbol::is_local(inter_symbol *S) {
	if ((S) && (InterSymbol::get_type(S) == LOCAL_ISYMT)) return TRUE;
	return FALSE;
}

void InterSymbol::make_local(inter_symbol *S) {
	InterSymbol::set_type(S, LOCAL_ISYMT);
	S->definition = NULL;
}

@ Connectors are symbols used either as plugs or sockets. These only appear
in one special package, and are used to link different trees together.
See //Connectors//.

=
int InterSymbol::is_plug(inter_symbol *S) {
	if ((S) && (InterSymbol::get_type(S) == PLUG_ISYMT)) return TRUE;
	return FALSE;
}

void InterSymbol::make_plug(inter_symbol *S) {
	InterSymbol::set_type(S, PLUG_ISYMT);
	S->definition = NULL;
}

int InterSymbol::is_socket(inter_symbol *S) {
	if ((S) && (InterSymbol::get_type(S) == SOCKET_ISYMT)) return TRUE;
	return FALSE;
}

void InterSymbol::make_socket(inter_symbol *S) {
	InterSymbol::set_type(S, SOCKET_ISYMT);
	S->definition = NULL;
}

int InterSymbol::is_connector(inter_symbol *S) {
	if ((InterSymbol::is_plug(S)) || (InterSymbol::is_socket(S))) return TRUE;
	return FALSE;
}

@ A symbol is "private" if it cannot be seen from outside the package, that is,
if no external symbol is allowed to be wired to it. For example, local variables
in a function body have this property.

=
int InterSymbol::private(inter_symbol *S) {
	if (InterSymbol::get_type(S) == LABEL_ISYMT) return TRUE;
	if (InterSymbol::get_type(S) == LOCAL_ISYMT) return TRUE;
	if (InterSymbol::is_metadata_key(S)) return TRUE;
	return FALSE;
} 

@h Definition of a symbol.
When created, a symbol is "undefined": it has no meaning as yet, though it is
usually given one very soon after creation. Even then, though, definitions are
sometimes changed later on.

Giving a symbol a definition says that it means something right here, in the
package to which it belongs. The alternative is to wire it, which says that the
meaning is far away, in another package: see //Connectors//.

A definition in this sense is a pointer to an //inter_tree_node// holding an
instruction which creates the symbol. For example, the definition of |magic_number|
might be the node holding the instruction:
= (text as Inter)
	constant magic_number K_int32 = 27
=

=
void InterSymbol::define(inter_symbol *S, inter_tree_node *P) {
	if (S == NULL) internal_error("tried to define null symbol");
	S->definition = P;
}

void InterSymbol::undefine(inter_symbol *S) {
	if (S) InterSymbol::define(S, NULL);
}

inter_tree_node *InterSymbol::definition(inter_symbol *S) {
	if (S == NULL) internal_error("tried to find definition of null symbol");
	return S->definition;
}

int InterSymbol::is_defined(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (InterSymbol::definition(S)) return TRUE;
	return FALSE;
}

@ This is rather more violent than simply undefining |S|. It does do that,
but also deletes the instruction which had defined |S| from the tree entirely.

Note that it does not go to the even more extreme lengths of removing the
symbol from the symbols table. For that, see //InterSymbolsTable::remove_symbol//,
but see also the warnings attached to it.

=
void InterSymbol::strike_definition(inter_symbol *S) {
	if (S) {
		inter_tree_node *D = InterSymbol::definition(S);
		if (D) NodePlacement::remove(D);
		InterSymbol::undefine(S);
	}
}

@ Symbols which define integer constants occasionally need to be evaluated or
modified, which of course means looking into their defining instructions.

=
int InterSymbol::evaluate_to_int(inter_symbol *S) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((P) && (P->W.instruction[ID_IFLD] == CONSTANT_IST))
		return Inter::Constant::evaluate_to_int(S);
	return -1;
}

void InterSymbol::set_int(inter_symbol *S, int N) {
	inter_tree_node *P = InterSymbol::definition(S);
	if ((P) && (P->W.instruction[ID_IFLD] == CONSTANT_IST) &&
		(Inter::Constant::set_int(S, N))) return;
	if (P == NULL) LOG("Synbol $3 is undefined\n", S);
	LOG("Synbol $3 cannot be set to %d\n", S, N);
	internal_error("unable to set symbol");
}

@ A symbol wired to something in another package, or a plug -- which is not
yet wired, but will be later on, when linking takes place -- has no definition
in the current package. So:

=
int InterSymbol::defined_elsewhere(inter_symbol *S) {
	if (S == NULL) return FALSE;
	if (Wiring::is_wired(S)) return TRUE;
	if (InterSymbol::get_type(S) == PLUG_ISYMT) return TRUE;
	return FALSE;
}

@h Annotation.
Any symbol can be annotated with one or more flags or values: but see //Annotations//
for how this is implemented. Here we only play pass the parcel.

=
void InterSymbol::annotate(inter_symbol *S, inter_annotation IA) {
	if (S == NULL) internal_error("annotated null symbol");
	Inter::Annotations::add_to_set(&(S->annotations), IA);
}

void InterSymbol::unannotate(inter_symbol *S, inter_ti annot_ID) {
	if (S == NULL) internal_error("annotated null symbol");
	Inter::Annotations::remove_from_set(&(S->annotations), annot_ID);
}

void InterSymbol::annotate_i(inter_symbol *S, inter_ti annot_ID, inter_ti n) {
	inter_annotation IA = Inter::Annotations::from_bytecode(annot_ID, n);
	InterSymbol::annotate(S, IA);
}

int InterSymbol::read_annotation(const inter_symbol *S, inter_ti ID) {
	inter_annotation *IA = Inter::Annotations::find(&(S->annotations), ID);
	if (IA) return (int) IA->annot_value;
	return -1;
}

text_stream *InterSymbol::read_annotation_t(inter_symbol *S, inter_tree *I, inter_ti ID) {
	inter_annotation *IA = Inter::Annotations::find(&(S->annotations), ID);
	if (IA) return InterWarehouse::get_text(InterTree::warehouse(I), IA->annot_value);
	return NULL;
}

void InterSymbol::annotate_t(inter_tree *I, inter_package *owner, inter_symbol *S,
	inter_ti annot_ID, text_stream *text) {
	inter_ti n = InterWarehouse::create_text(InterTree::warehouse(I), owner);
	Str::copy(InterWarehouse::get_text(InterTree::warehouse(I), n), text);
	inter_annotation IA = Inter::Annotations::from_bytecode(annot_ID, n);
	InterSymbol::annotate(S, IA);
}

void InterSymbol::write_annotations(OUTPUT_STREAM, inter_tree_node *F, inter_symbol *S) {
	if (S) Inter::Annotations::write_set(OUT, &(S->annotations), F);
}

void InterSymbol::transpose_annotations(inter_symbol *S, inter_ti *grid,
	inter_ti grid_extent, inter_error_message **E) {
	if (S) Inter::Annotations::transpose_set(&(S->annotations), grid, grid_extent, E);
}

@h Translation.
Any symbol can be marked with a "translation", which is the textual identifier
to use when compiling final code which refers to it. For example, if our
example constant is defined by:
= (text as Inter)
	constant magic_number K_int32 = 27
=
then its translated form would normally just be |"magic_number"| -- the same
as its identifier name in Inter. Any Inform 6 code generated to refer to this
might then read:
= (text as Inform 6)
	print "The magic number is ", magic_number, ".";
=
But if the |magic_number| had been given the translation text |"SHAZAM"|, that
same Inter would compile instead to:
= (text as Inform 6)
	print "The magic number is ", SHAZAM, ".";
=

There is something a little disorienting about storing this data as part of
an //inter_symbol//. One might reasonably say: It's no business of the Inter
tree what the //final// module chooses to call its identifiers, and anyway,
maybe the target language compiled to doesn't even have identifiers in any
recognisable way, or insists that they follow COBOL naming conventions, or
something equally annoying.

However, we have to store translations within the Inter tree because the
Inform 7 language includes low-level features which cannot be expressed any
other way:
= (text as Inform 7)
The tally is a number that varies.
The tally translates into Inter as "SHAZAM".
=
In order for this instruction to reach the //final// code generators, this
data clearly has to be expressed in the Inter tree. Well, this is where.

With that apologia out of the way:

=
void InterSymbol::set_translate(inter_symbol *S, text_stream *identifier) {
	if (S == NULL) internal_error("no symbol");
	S->translate_text = Str::duplicate(identifier);
}

text_stream *InterSymbol::get_translate(inter_symbol *S) {
	if (S == NULL) internal_error("no symbol");
	return S->translate_text;
}

text_stream *InterSymbol::trans(inter_symbol *S) {
	if (S == NULL) return NULL;
	if (InterSymbol::get_translate(S)) return InterSymbol::get_translate(S);
	return S->symbol_name;
}

@h Textual form.
The following writes a valid line of textual Inter to declare the symbol,
appearing at level |N| in the hierarchy.

=
void InterSymbol::write_declaration(OUTPUT_STREAM, inter_symbol *S, int N) {
	for (int L=0; L<N; L++) WRITE("\t");
	WRITE("symbol ");
	if (InterSymbol::private(S)) WRITE("private");
	else WRITE("public");
	WRITE(" ");
	switch (InterSymbol::get_type(S)) {
		case LABEL_ISYMT:    WRITE("label"); break;
		case MISC_ISYMT:     WRITE("misc"); break;
		case PLUG_ISYMT:     WRITE("plug"); break;
		case SOCKET_ISYMT:   WRITE("socket"); break;
		case LOCAL_ISYMT:    WRITE("local"); break;
		default: internal_error("unknown symbol type"); break;
	}
	WRITE(" %S", S->symbol_name);
	if (InterSymbol::get_flag(S, MAKE_NAME_UNIQUE_ISYMF)) WRITE("*");
	if (Wiring::is_wired_to_name(S)) {
		WRITE(" --? %S", Wiring::wired_to_name(S));
	}
	text_stream *trans_name = InterSymbol::get_translate(S);
	if (Str::len(trans_name) > 0) WRITE(" `%S`", trans_name);
	if (Wiring::is_wired(S)) {
		WRITE(" --> ");
		InterSymbolsTable::write_symbol_URL(OUT, Wiring::wired_to(S));
	}
}

@h Logging.

=
void InterSymbol::log(OUTPUT_STREAM, void *vs) {
	inter_symbol *S = (inter_symbol *) vs;
	if (S == NULL) {
		WRITE("<no-symbol>");
	} else {
		InterSymbolsTable::write_symbol_URL(DL, S);
		WRITE("{%d}", S->symbol_ID - SYMBOL_BASE_VAL);
		if (Str::len(S->translate_text) > 0) WRITE("'%S'", S->translate_text);
	}
}
