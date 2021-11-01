[VanillaIF::] Vanilla IF.

Constructing the dictionary, command verb and action tables when the target
language is not Inform 6 (where such things are made automatically).

@h Dictionary words.
Compiling the table of dictionary words is not completely simple: they must
be sorted into alphabetical order, but do not present themselves that way.

So we provide the following functions, which a generator is not obliged to
make use of.

For each different dictionary word brought to our attention, we create one
of these:

=
typedef struct vanilla_dword {
	struct text_stream *text;
	struct text_stream *identifier;
	int pluralise;
	int meta;
	int preplike;
	int nounlike;
	int verblike;
	int verb_number;
	int grammar_table_offset;
	CLASS_DEFINITION
} vanilla_dword;

@ The following sorting function places dwords in alphabetical order:

=
int VanillaIF::compare_dwords(const void *ent1, const void *ent2) {
	text_stream *tx1 = (*((const vanilla_dword **) ent1))->text;
	text_stream *tx2 = (*((const vanilla_dword **) ent2))->text;
	return Str::cmp_insensitive(tx1, tx2);
}

@ We use a dictionary to ensure that each dword has exactly one such structure
created:

=
vanilla_dword *VanillaIF::find_dword(code_generation *gen, text_stream *S,
	int pluralise) {
	TEMPORARY_TEXT(K)
	LOOP_THROUGH_TEXT(pos, S)
		PUT_TO(K, Characters::tolower(Str::get(pos)));
	while (Str::get_last_char(K) == '/') Str::delete_last_character(K);
	vanilla_dword *dw;
	if (Dictionaries::find(gen->dword_dictionary, K)) {
		dw = Dictionaries::read_value(gen->dword_dictionary, K);
		if (pluralise) dw->pluralise = TRUE;
	} else {
		dw = CREATE(vanilla_dword);
		dw->text = Str::duplicate(K);
		dw->identifier = Str::new();
		WRITE_TO(dw->identifier, "i7_dword_%d", gen->dword_count++);
		dw->pluralise = pluralise;
		dw->meta = FALSE;
		dw->preplike = FALSE;
		dw->nounlike = FALSE;
		dw->verblike = FALSE;
		dw->verb_number = 0;
		dw->grammar_table_offset = 0;
		ADD_TO_LINKED_LIST(dw, vanilla_dword, gen->words);
		Dictionaries::create(gen->dword_dictionary, K);
		Dictionaries::write_value(gen->dword_dictionary, K, dw);
	}
	DISCARD_TEXT(K)
	return dw;
}

@ These linguistic categories are very crudely applied. The main thing to note
is that the same word can be in any combination of the three, except that it
cannot be in none of them.

If a generator wants to register a dword with us, it must call one of these:

=
vanilla_dword *VanillaIF::text_to_noun_dword(code_generation *gen, text_stream *S,
	int pluralise) {
	vanilla_dword *dw = VanillaIF::find_dword(gen, S, pluralise);
	dw->nounlike = TRUE;
	return dw;
}

vanilla_dword *VanillaIF::text_to_prep_dword(code_generation *gen, text_stream *S,
	int pluralise) {
	vanilla_dword *dw = VanillaIF::find_dword(gen, S, pluralise);
	dw->preplike = TRUE;
	return dw;
}

vanilla_dword *VanillaIF::text_to_verb_dword(code_generation *gen, text_stream *S,
	int verbnum) {
	vanilla_dword *dw = VanillaIF::find_dword(gen, S, FALSE);
	dw->verblike = TRUE;
	dw->verb_number = verbnum;
	return dw;
}

@ And this function then compiles the |#dictionary_table| array, which is
really a concatenation of many arrays: a single word holding the length
and then one mini-array for each dword, presented in alphabetical order.

For the format of dictionary word arrays, see the Inform 6 Technical Manual.
(This is the later Glulx format, not the earlier Z-machine format.)

=
void VanillaIF::compile_dictionary_table(code_generation *gen) {
	int dictlen = gen->dword_count;
	@<Compile the dictionary length@>;
	if (dictlen > 0) {
		vanilla_dword **sorted = (vanilla_dword **)
			(Memory::calloc(dictlen, sizeof(vanilla_dword *), CODE_GENERATION_MREASON));
		vanilla_dword *dw; int i=0;
		LOOP_OVER_LINKED_LIST(dw, vanilla_dword, gen->words) sorted[i++] = dw;
		qsort(sorted, (size_t) LinkedLists::len(gen->words), sizeof(vanilla_dword *),
			VanillaIF::compare_dwords);
		for (int i=0; i<dictlen; i++) @<Compile an array for this dword@>;
		Memory::I7_free(sorted, CODE_GENERATION_MREASON, dictlen);
	}
}

@ In effect, this is a 1-word word array, but we make it as a 4-byte byte array
instead so that we are not concatenating arrays with different formats; this is
just in case some generators are opting to align word arrays in memory.

@<Compile the dictionary length@> =
	Generators::begin_array(gen, I"#dictionary_table", NULL, NULL, BYTE_ARRAY_FORMAT, NULL);
	VanillaIF::byte_entry(gen, 0);
	VanillaIF::byte_entry(gen, ((dictlen & 0x00FF0000) >> 16));
	VanillaIF::byte_entry(gen, ((dictlen & 0x0000FF00) >> 8));
	VanillaIF::byte_entry(gen, (dictlen & 0x000000FF));
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, NULL);

@<Compile an array for this dword@> =
	dw = sorted[i];
	Generators::begin_array(gen, sorted[i]->identifier, NULL, NULL, BYTE_ARRAY_FORMAT, NULL);
	VanillaIF::byte_entry(gen, 0x60);
	for (int i=0; i<9; i++) {
		int c = 0;
		if (i < Str::len(dw->text)) c = (int) Str::get_at(dw->text, i);
		VanillaIF::byte_entry(gen, c);
	}
	int f = 0;
	if (dw->verblike) f += 1;
	if (dw->meta) f += 2;
	if (dw->pluralise) f += 4;
	if (dw->preplike) f += 8;
	if (dw->nounlike) f += 128;
	VanillaIF::byte_entry(gen, f/256);
	VanillaIF::byte_entry(gen, f%256);
	VanillaIF::byte_entry(gen, (0xFFFF - dw->verb_number)/256);
	VanillaIF::byte_entry(gen, (0xFFFF - dw->verb_number)%256);
	VanillaIF::byte_entry(gen, 0);
	VanillaIF::byte_entry(gen, 0);
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, NULL);

@ =
void VanillaIF::byte_entry(code_generation *gen, int N) {
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "%d", N);
	Generators::array_entry(gen, T, BYTE_ARRAY_FORMAT);
	DISCARD_TEXT(T);
}

@h Actions table.
We also need to make a metadata table called the |#actions_table| which
gives, for each (true) action, a function to carry it out. The name of this
function is always given with a |Sub| suffix: this once stood for subroutine,
and shows just how far back into the history of Inform 1 this all goes.

(It is the absence of such a function which makes a fake action fake.)

=
void VanillaIF::compile_actions_table(code_generation *gen) {
	Generators::begin_array(gen, I"#actions_table", NULL, NULL,
		TABLE_ARRAY_FORMAT, NULL);
	text_stream *an;
	LOOP_OVER_LINKED_LIST(an, text_stream, gen->actions) {
		TEMPORARY_TEXT(O)
		WRITE_TO(O, "%SSub", an);
		TEMPORARY_TEXT(M)
		Generators::mangle(gen, M, O);
		Generators::array_entry(gen, M, TABLE_ARRAY_FORMAT);
		DISCARD_TEXT(O)
		DISCARD_TEXT(M)
	}
	Generators::end_array(gen, TABLE_ARRAY_FORMAT, NULL);	
}

@h Command grammar.

=
void VanillaIF::verb_grammar(code_generator *cgt, code_generation *gen,
	inter_symbol *array_s, inter_tree_node *P) {
	inter_tree *I = gen->from;
	int verbnum = gen->verb_count++;
	
	inter_symbol *line_actions[128];
	int line_reverse[128];
	
	int lines = 0;
	for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
		inter_ti val1 = P->W.data[i], val2 = P->W.data[i+1];
		if (Inter::Symbols::is_stored_in_data(val1, val2)) {
			inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
			if (aliased == NULL) internal_error("bad aliased symbol");
			if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_DIVIDER")) {
				line_reverse[lines] = FALSE;
				line_actions[lines++] = NULL;
			}
			if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_RESULT")) {
				inter_ti val1 = P->W.data[i+2], val2 = P->W.data[i+3];
				inter_symbol *res = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (res == NULL) internal_error("bad aliased symbol");
				line_actions[lines-1] = res;
			}
			if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_REVERSE")) {
				inter_ti val1 = P->W.data[i], val2 = P->W.data[i+1];
				inter_symbol *res = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (res == NULL) internal_error("bad aliased symbol");
				line_reverse[lines-1] = TRUE;
			}
		}
	}
	
	int address = LinkedLists::len(gen->verb_grammar);
	VanillaIF::grammar_byte(gen, lines); /* no grammar lines */

	int stage = 1, synonyms = 0, started = FALSE;
	lines = 0;
	for (int i=DATA_CONST_IFLD; i<P->W.extent; i=i+2) {
		inter_ti val1 = P->W.data[i], val2 = P->W.data[i+1];
		if (stage == 1) {
			if (val1 == DWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				vanilla_dword *dw = VanillaIF::text_to_verb_dword(gen, glob_text, verbnum);
				if (Inter::Symbols::read_annotation(array_s, METAVERB_IANN) == 1) dw->meta = TRUE;
				synonyms++;
				if (synonyms == 1) {
					ADD_TO_LINKED_LIST(dw, vanilla_dword, gen->verbs);
				}
				dw->grammar_table_offset = address;
			} else if (Inter::Symbols::is_stored_in_data(val1, val2)) {
				inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (aliased == NULL) internal_error("bad aliased symbol");
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_DIVIDER")) { stage = 2; i -= 2; continue; }
				else internal_error("not a divider");
			} else {
				internal_error("not a dword");
			}
		}
		if (stage == 2) {
			int lookahead = 0, slash_before = FALSE, slash_after = FALSE;
			if (i > DATA_CONST_IFLD) {
				inter_ti val1 = P->W.data[i-2], val2 = P->W.data[i-1];
				if (Inter::Symbols::is_stored_in_data(val1, val2)) {
					inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
					if (aliased == NULL) internal_error("bad aliased symbol");
					if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SLASH")) {
						slash_before = TRUE;
					}
				}
			}
			if (i+2 < P->W.extent) {
				inter_ti val1 = P->W.data[i+2], val2 = P->W.data[i+3];
				if (Inter::Symbols::is_stored_in_data(val1, val2)) {
					inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
					if (aliased == NULL) internal_error("bad aliased symbol");
					if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SLASH")) {
						slash_after = TRUE;
					}
				}
			}
			if (slash_before) lookahead += 0x10;
			if (slash_after) lookahead += 0x20;
				
			if (Inter::Symbols::is_stored_in_data(val1, val2)) {
				inter_symbol *aliased = InterSymbolsTables::symbol_from_data_pair_and_table(val1, val2, Inter::Packages::scope_of(P));
				if (aliased == NULL) internal_error("bad aliased symbol");
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SLASH")) continue;
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_DIVIDER")) {
					if (started) {
						TEMPORARY_TEXT(T)
						Generators::mangle(gen, T, I"ENDIT_TOKEN");
						VanillaIF::grammar_byte_textual(gen, T);
						DISCARD_TEXT(T)
					}
					TEMPORARY_TEXT(NT)
					Generators::mangle(gen, NT, line_actions[lines]->symbol_name);
					TEMPORARY_TEXT(A)
					TEMPORARY_TEXT(B)
					Generators::word_to_byte(gen, A, NT, 2);
					Generators::word_to_byte(gen, B, NT, 3);
					VanillaIF::grammar_byte_textual(gen, A); /* action (big end) */
					VanillaIF::grammar_byte_textual(gen, B); /* action (lil end) */
					DISCARD_TEXT(A)
					DISCARD_TEXT(B)
					DISCARD_TEXT(NT)
					if (line_reverse[lines])
						VanillaIF::grammar_byte(gen, 1);
					else
						VanillaIF::grammar_byte(gen, 0);
					lines++;
					started = TRUE;
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_RESULT")) {
					i += 2;
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_REVERSE")) continue;

				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_NOUN")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 0);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_HELD")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 1);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTI")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 2);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTIHELD")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 3);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTIEXCEPT")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 4);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_MULTIINSIDE")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 5);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_CREATURE")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 6);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_SPECIAL")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 7);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_NUMBER")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 8);
					continue;
				}
				if (Str::eq(aliased->symbol_name, I"VERB_DIRECTIVE_TOPIC")) {
					VanillaIF::grammar_byte(gen, 1 + lookahead);
					VanillaIF::grammar_word(gen, 9);
					continue;
				}
				int bc = 0x86;				
				if (Inter::Symbols::read_annotation(aliased, SCOPE_FILTER_IANN) == 1)
					bc = 0x85;
				if (Inter::Symbols::read_annotation(aliased, NOUN_FILTER_IANN) == 1)
					bc = 0x83;
				VanillaIF::grammar_byte(gen, bc + lookahead);
				TEMPORARY_TEXT(MG)
				Generators::mangle(gen, MG, Inter::Symbols::name(aliased));
				VanillaIF::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
			if (val1 == DWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				vanilla_dword *dw = VanillaIF::text_to_prep_dword(gen, glob_text, FALSE);
				VanillaIF::grammar_byte(gen, 0x42 + lookahead);
				TEMPORARY_TEXT(MG)
				Generators::mangle(gen, MG, dw->identifier);
				VanillaIF::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
			if (val1 == PDWORD_IVAL) {
				text_stream *glob_text = Inter::Warehouse::get_text(InterTree::warehouse(I), val2);
				vanilla_dword *dw = VanillaIF::text_to_prep_dword(gen, glob_text, TRUE);
				VanillaIF::grammar_byte(gen, 0x42 + lookahead);
				TEMPORARY_TEXT(MG)
				Generators::mangle(gen, MG, dw->identifier);
				VanillaIF::grammar_word_textual(gen, MG);
				DISCARD_TEXT(MG)
				continue;
			}
		}
	}
	if (started) {
		TEMPORARY_TEXT(T)
		Generators::mangle(gen, T, I"ENDIT_TOKEN");
		VanillaIF::grammar_byte_textual(gen, T);
		DISCARD_TEXT(T)
	}
}

void VanillaIF::grammar_byte(code_generation *gen, int N) {
	TEMPORARY_TEXT(NT)
	WRITE_TO(NT, "%d", N);
	VanillaIF::grammar_byte_textual(gen, NT);
	DISCARD_TEXT(NT)
}

void VanillaIF::grammar_word(code_generation *gen, int N) {
	TEMPORARY_TEXT(NT)
	WRITE_TO(NT, "%d", N);
	VanillaIF::grammar_word_textual(gen, NT);
	DISCARD_TEXT(NT)
}

void VanillaIF::grammar_word_textual(code_generation *gen, text_stream *NT) {
	for (int b=0; b<4; b++) {
		TEMPORARY_TEXT(BT)
		Generators::word_to_byte(gen, BT, NT, b);
		VanillaIF::grammar_byte_textual(gen, BT);
		DISCARD_TEXT(BT)
	}
}

void VanillaIF::grammar_byte_textual(code_generation *gen, text_stream *NT) {
	NT = Str::duplicate(NT);
	ADD_TO_LINKED_LIST(NT, text_stream, gen->verb_grammar);
}

void VanillaIF::compile_verb_table(code_generation *gen) {
	Generators::begin_array(gen, I"#grammar_table", NULL, NULL, WORD_ARRAY_FORMAT, NULL);
	TEMPORARY_TEXT(N)
	WRITE_TO(N, "%d", gen->verb_count - 1);
	Generators::array_entry(gen, N, WORD_ARRAY_FORMAT);
	DISCARD_TEXT(N)
	vanilla_dword *dw;
	LOOP_OVER_LINKED_LIST(dw, vanilla_dword, gen->verbs) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "(");
		Generators::mangle(gen, N, I"#grammar_table_cont");
		WRITE_TO(N, "+%d)", dw->grammar_table_offset);
		Generators::array_entry(gen, N, WORD_ARRAY_FORMAT);
		DISCARD_TEXT(N)
	}
	Generators::end_array(gen, WORD_ARRAY_FORMAT, NULL);
	Generators::begin_array(gen, I"#grammar_table_cont", NULL, NULL, BYTE_ARRAY_FORMAT, NULL);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, gen->verb_grammar) {
		Generators::array_entry(gen, entry, BYTE_ARRAY_FORMAT);
	}
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, NULL);
}
