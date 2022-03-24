[MakeIdentifiersUniqueStage::] Make Identifiers Unique Stage.

To make sure certain symbol names translate into globally unique target symbols.

@ Inter frequently contains multiple symbols with different meanings but the
same name: for example, the active part of a function package is referred to
with the symbol |call|, so Inter trees tend to be full of symbols called that.

This overlap of names is not convenient when we eventually generate code from
the Inter tree: we want different meanings to produce different "translated"
names. (Recall that a symbol has a "translated" name as well as its real name;
the "translated" name is the identifier used for it in the code we generated.)

So the following gives unique translated names to symbols marked with the
|MAKE_NAME_UNIQUE_ISYMF| bit. So for example
= (text)
	NAME		MAKE_NAME_UNIQUE_ISYMF	TRANSLATION
	call		TRUE				--
	call		TRUE				--
	example		FALSE				--
	call		TRUE				--
=
will become
= (text)
	NAME		MAKE_NAME_UNIQUE_ISYMF	TRANSLATION
	call		FALSE				call_U1
	call		FALSE				call_U2
	example		FALSE				--
	call		FALSE				call_U3
=
Only the translation changes, not the name itself, which remains |call|.

Note that this operation is done at the end of linking because these |call|
symbols (or whatever) may occur in multiple compilation units; it would be no
good to uniquely number them within each kit, for example, because then each
kit would have its own |call_U1|, causing a collision.

=
void MakeIdentifiersUniqueStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"make-identifiers-unique",
		MakeIdentifiersUniqueStage::run_pipeline_stage, NO_STAGE_ARG, FALSE);
}

int MakeIdentifiersUniqueStage::run_pipeline_stage(pipeline_step *step) {
	inter_tree *I = step->ephemera.tree;
	dictionary *D = Dictionaries::new(16, FALSE);
	InterTree::traverse(I, MakeIdentifiersUniqueStage::visitor, D, NULL, 0);
	return TRUE;
}

@ The dictionary efficiently connects names such as |call| to an integer count
for each one, but //foundation// does not provide dictionaries from texts to
integers, only to structures allocated by the memory manager: so we must use
the following.

=
typedef struct uniqueness_count {
	int count;
	CLASS_DEFINITION
} uniqueness_count;

@ Note that if |S| is equated to some other symbol, then its translated
name will never matter, because identifiers in the eventual code will come
from the symbol |S| is equated to. So we needn't bother to have a unique
translation in that case.

=
void MakeIdentifiersUniqueStage::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	dictionary *D = (dictionary *) state;
	if (Inode::is(P, PACKAGE_IST)) {
		inter_package *Q = PackageInstruction::at_this_head(P);
		inter_symbols_table *ST = InterPackage::scope(Q);
		LOOP_OVER_SYMBOLS_TABLE(S, ST) {
			if ((Wiring::is_wired(S) == FALSE) &&
				(InterSymbol::get_flag(S, MAKE_NAME_UNIQUE_ISYMF))) {
				@<Give this symbol a unique translation@>;
				InterSymbol::clear_flag(S, MAKE_NAME_UNIQUE_ISYMF);
			}
		}
	}
}

@<Give this symbol a unique translation@> =
	text_stream *N = InterSymbol::identifier(S);
	uniqueness_count *U = NULL;
	dict_entry *de = Dictionaries::find(D, N);
	if (de) {
		U = (uniqueness_count *) Dictionaries::value_for_entry(de);
	} else {
		U = CREATE(uniqueness_count);
		U->count = 0;
		Dictionaries::create(D, N);
		Dictionaries::write_value(D, N, (void *) U);
	}
	U->count++;
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "%S_U%d", N, U->count);
	InterSymbol::set_translate(S, T);
	DISCARD_TEXT(T)
