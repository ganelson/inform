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
	Generators::begin_array(gen, I"#dictionary_table", NULL, NULL, BYTE_ARRAY_FORMAT, -1, NULL);
	VanillaIF::byte_entry(gen, 0);
	VanillaIF::byte_entry(gen, ((dictlen & 0x00FF0000) >> 16));
	VanillaIF::byte_entry(gen, ((dictlen & 0x0000FF00) >> 8));
	VanillaIF::byte_entry(gen, (dictlen & 0x000000FF));
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, -1, NULL);

@<Compile an array for this dword@> =
	dw = sorted[i];
	Generators::begin_array(gen, sorted[i]->identifier, NULL, NULL, BYTE_ARRAY_FORMAT, -1, NULL);
	VanillaIF::byte_entry(gen, 0x60);
	VanillaIF::byte_entry(gen, 0);
	VanillaIF::byte_entry(gen, 0);
	VanillaIF::byte_entry(gen, 0);
	for (int i=0; i<gen->dictionary_resolution; i++) {
		int c = 0;
		if (i < Str::len(dw->text)) c = (int) Str::get_at(dw->text, i);
		VanillaIF::byte_entry(gen, (((unsigned int)c & 0xFF000000) >> 24));
		VanillaIF::byte_entry(gen, ((c & 0x00FF0000) >> 16));
		VanillaIF::byte_entry(gen, ((c & 0x0000FF00) >> 8));
		VanillaIF::byte_entry(gen, (c & 0x000000FF));
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
	VanillaIF::byte_entry(gen, 0);
	VanillaIF::byte_entry(gen, 0);
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, -1, NULL);

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
		TABLE_ARRAY_FORMAT, -1, NULL);
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
	Generators::end_array(gen, TABLE_ARRAY_FORMAT, -1, NULL);	
}

@h Command grammar.
This is not the place to specify what an Inform 6 grammar table looks like:
again, see the I6 Technical Manual.

This limit is much, much larger than we need:

@d MAX_LINES_IN_VANILLA_GRAMMAR 256

=
void VanillaIF::verb_grammar(code_generator *gtr, code_generation *gen,
	inter_symbol *array_s, inter_tree_node *P) {
	inter_tree *I = gen->from;
	
	int line_count = 0;
	inter_symbol *line_actions[MAX_LINES_IN_VANILLA_GRAMMAR];
	int line_reverse[MAX_LINES_IN_VANILLA_GRAMMAR];
	@<Find the resulting actions and reversal states for each grammar line@>;
	
	@<Add a record for this grammar to the table@>;
}

@ So the grammar is currently a list of values at the Inter node |P|. The
first few terms in the list give the verb command words (TAKE, GET, say);
then come a series of 1 or more "grammar lines", each of which begins with
a |VERB_DIRECTIVE_DIVIDER| symbol. A line ends with |VERB_DIRECTIVE_RESULT|
followed by a token indicating the action resulting from the line; the
|VERB_DIRECTIVE_REVERSE| token means that the action should be taken with
its nouns exchanged.

@<Find the resulting actions and reversal states for each grammar line@> =
	int lines = 0, extent = ConstantInstruction::list_len(P);
	for (int i=0; i<extent; i++) {
		inter_symbol *S = VanillaIF::get_symbol(gen, P, ConstantInstruction::list_entry(P, i));
		if (S) {
			if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_DIVIDER")) {
				if (lines >= MAX_LINES_IN_VANILLA_GRAMMAR)
					internal_error("too many lines in grammar");
				line_reverse[lines] = FALSE;
				line_actions[lines] = NULL;
				lines++;
			}
			if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_RESULT")) {
				line_actions[lines-1] =
					VanillaIF::get_symbol(gen, P, ConstantInstruction::list_entry(P, i+1));
			}
			if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_REVERSE"))
				line_reverse[lines-1] = TRUE;
		}
	}
	line_count = lines;

@<Add a record for this grammar to the table@> =
	int verbnum = gen->verb_count++;
	int address = LinkedLists::len(gen->verb_grammar);
	VanillaIF::grammar_byte(gen, line_count); /* no grammar lines */

	int reading_command_verbs = TRUE, synonyms = 0, line_started = FALSE,
		filter = NOT_APPLICABLE;
	int lines = 0, extent = ConstantInstruction::list_len(P);
	for (int i=0; i<extent; i++) {
		inter_pair val = ConstantInstruction::list_entry(P, i);
		if (reading_command_verbs) @<Read this as a command verb@>
		else @<Read this as part of a grammar line@>;
	}
	@<Close any grammar line record we have already started writing@>;

@<Read this as a command verb@> =
	if (InterValuePairs::is_dword(val)) {
		text_stream *glob_text = InterValuePairs::to_dictionary_word(I, val);
		vanilla_dword *dw = VanillaIF::text_to_verb_dword(gen, glob_text, verbnum);
		if (VanillaIF::is_verb_meta(P)) dw->meta = TRUE;
		synonyms++;
		if (synonyms == 1) ADD_TO_LINKED_LIST(dw, vanilla_dword, gen->verbs);
		dw->grammar_table_offset = address;
	} else {
		inter_symbol *S = VanillaIF::get_symbol(gen, P, val);
		if ((S) && (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_DIVIDER"))) {
			reading_command_verbs = FALSE; i--;
		}
	}

@<Read this as part of a grammar line@> =
	int token_metadata = 0;
	@<Add the slash before and slash after bits to token_metadata@>;
		
	inter_symbol *S = VanillaIF::get_symbol(gen, P, val);
	if (S) {
		@<Read this symbol name as part of a grammar line@>;
	} else if (InterValuePairs::is_dword(val)) {
		@<Read this dictionary word as part of a grammar line@>;
	}

@ Was the previous token a slash? How about the next? (This is for command grammar
like |'fish' / 'fowl' / 'chalk'|, where |'fish'| has a slash after but not before,
|'fowl'| has both, and |'chalk'| before but not after.

@<Add the slash before and slash after bits to token_metadata@> =
	if (i > 0) {
		inter_symbol *S_before = VanillaIF::get_symbol(gen, P, ConstantInstruction::list_entry(P, i-1));
		if ((S_before) && (Str::eq(InterSymbol::identifier(S_before), I"VERB_DIRECTIVE_SLASH")))
			token_metadata += 0x10;
	}
	if (i+1 < extent) {
		inter_symbol *S_after = VanillaIF::get_symbol(gen, P, ConstantInstruction::list_entry(P, i+1));
		if ((S_after) && (Str::eq(InterSymbol::identifier(S_after), I"VERB_DIRECTIVE_SLASH")))
			token_metadata += 0x20;
	}

@<Read this symbol name as part of a grammar line@> =
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_SLASH")) continue;
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_REVERSE")) continue;
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_DIVIDER")) {
		@<Close any grammar line record we have already started writing@>;
		@<Start writing a record for a new grammar line@>;
		lines++;
		line_started = TRUE;
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_RESULT")) {
		i++; /* Skip the result action */
		continue;
	}
	@<Handle the 10 built-in tokens@>;
	@<Handle a noun filter, a scope filter or similar@>;

@ This is the header block at the beginning of a new grammar line in the table,
which occupies 3 bytes: a short word giving the resulting action, and a flag
for reversal. (Happily, we worked these out in the first pass through earlier.)

@<Start writing a record for a new grammar line@> =
	TEMPORARY_TEXT(NT)
	Generators::mangle(gen, NT, InterSymbol::identifier(line_actions[lines]));
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

@ That 3-byte header is then followed by a list of 5-byte token blocks.
The opening byte gives some metadata bits, and then there's a word.

@<Handle the 10 built-in tokens@> =
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_NOUN")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 0);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_HELD")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 1);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_MULTI")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 2);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_MULTIHELD")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 3);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_MULTIEXCEPT")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 4);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_MULTIINSIDE")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 5);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_CREATURE")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 6);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_SPECIAL")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 7);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_NUMBER")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 8);
		continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_TOPIC")) {
		VanillaIF::grammar_byte(gen, 1 + token_metadata);
		VanillaIF::grammar_word(gen, 9);
		continue;
	}

@ Again, five bytes: one byte metadata, one word value.

@<Handle a noun filter, a scope filter or similar@> =
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_NOUN_FILTER")) {
		filter = TRUE; continue;
	}
	if (Str::eq(InterSymbol::identifier(S), I"VERB_DIRECTIVE_SCOPE_FILTER")) {
		filter = FALSE; continue;
	}
	int bc = 0x86;				
	if (filter == FALSE) bc = 0x85;
	if (filter == TRUE)  bc = 0x83;
	VanillaIF::grammar_byte(gen, bc + token_metadata);
	TEMPORARY_TEXT(MG)
	Generators::mangle(gen, MG, InterSymbol::trans(S));
	VanillaIF::grammar_word_textual(gen, MG);
	DISCARD_TEXT(MG)
	filter = NOT_APPLICABLE;

@<Read this dictionary word as part of a grammar line@> =
	text_stream *glob_text = InterValuePairs::to_dictionary_word(I, val);
	vanilla_dword *dw =
		VanillaIF::text_to_prep_dword(gen, glob_text,
			(InterValuePairs::is_plural_dword(val))?TRUE:FALSE);
	VanillaIF::grammar_byte(gen, 0x42 + token_metadata);
	TEMPORARY_TEXT(MG)
	Generators::mangle(gen, MG, dw->identifier);
	VanillaIF::grammar_word_textual(gen, MG);
	DISCARD_TEXT(MG)

@<Close any grammar line record we have already started writing@> =
	if (line_started) {
		TEMPORARY_TEXT(T)
		Generators::mangle(gen, T, I"ENDIT_TOKEN");
		VanillaIF::grammar_byte_textual(gen, T);
		DISCARD_TEXT(T)
	}

@ =
inter_symbol *VanillaIF::get_symbol(code_generation *gen, inter_tree_node *P,
	inter_pair val) {
	if (InterValuePairs::is_symbolic(val)) {
		inter_symbol *S = InterValuePairs::to_symbol_at(val, P);
		if (S == NULL) internal_error("bad symbol in grammar token data");
		return S;
	}
	return NULL;
}

@ This looks at the opening of the verb grammar to check for the keyword |meta|:

=
int VanillaIF::is_verb_meta(inter_tree_node *P) {
	inter_pair val = ConstantInstruction::list_entry(P, 0);
	if (InterValuePairs::is_symbolic(val)) {
		inter_symbol *A = InterValuePairs::to_symbol_at(val, P);
		if ((A) && (Str::eq(InterSymbol::identifier(A), I"VERB_DIRECTIVE_META")))
			return TRUE;
	}
	return FALSE;
}

@ Okay then. So the above functions called the following to insert either
bytes or words into the growing grammar table. But Vanilla doesn't support
arrays with a mixture of bytes and words -- its entries should all be of
the same format. So we will break the words down into a sequence of 4 bytes,
and have only a |BYTE_ARRAY_FORMAT| array in the end.

The above supplied some entries numerically, and others textually, so we
need four functions in all.

=
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

@ Finally, then, the following outputs the table itself. In fact there need to
be two tables: first a table of addresses of each command verb's grammar table,
called |#grammar_table|, and then each of those grammar tables in turn. I don't
think there is any reason they necessarily have to be contiguous in the way
they are here, but that's what Inform 6 always did, and we're imitating Inform 6.

=
void VanillaIF::compile_verb_table(code_generation *gen) {
	Generators::begin_array(gen, I"#grammar_table", NULL, NULL, TABLE_ARRAY_FORMAT, -1, NULL);
	vanilla_dword *dw;
	LOOP_OVER_LINKED_LIST(dw, vanilla_dword, gen->verbs) {
		TEMPORARY_TEXT(N)
		WRITE_TO(N, "(");
		Generators::mangle(gen, N, I"#grammar_table_cont");
		WRITE_TO(N, "+%d)", dw->grammar_table_offset);
		Generators::array_entry(gen, N, TABLE_ARRAY_FORMAT);
		DISCARD_TEXT(N)
	}
	Generators::end_array(gen, TABLE_ARRAY_FORMAT, -1, NULL);

	Generators::begin_array(gen, I"#grammar_table_cont", NULL, NULL, BYTE_ARRAY_FORMAT, -1, NULL);
	text_stream *entry;
	LOOP_OVER_LINKED_LIST(entry, text_stream, gen->verb_grammar)
		Generators::array_entry(gen, entry, BYTE_ARRAY_FORMAT);
	Generators::end_array(gen, BYTE_ARRAY_FORMAT, -1, NULL);
}
