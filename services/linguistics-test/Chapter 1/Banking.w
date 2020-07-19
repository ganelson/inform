[Banking::] Banking.

Filling a vocabulary bank with nouns, verbs, prepositions and so on.

@h Keeping the syntax module happy.
We are going to need to use the sentence-breaking apparatus from the //syntax//
module, which means that the following four nonterminals need to exist. But in
fact they are really just placeholders -- they are wired so that they can never
match any text.

=
<dividing-sentence> ::=
	... ==> TRUE; return FAIL_NONTERMINAL;

<structural-sentence> ::=
	... ==> TRUE; return FAIL_NONTERMINAL;

<language-modifying-sentence> ::=
	... ==> TRUE; return FAIL_NONTERMINAL;

<comma-divisible-sentence> ::=
	... ==> TRUE; return FAIL_NONTERMINAL;

@h Loading from a file.
The following function reads a file whose name is in |arg|, feeds it into
the lexer, builds a syntax tree of its sentences, and then walks through
that tree, applying the Preform nonterminal <vocabulary-line> to each
sentence.

=
void Banking::load_from_file(text_stream *arg) {
	filename *F = Filenames::from_text(arg);
	feed_t FD = Feeds::begin();
	source_file *sf = TextFromFiles::feed_into_lexer(F, NULL_GENERAL_POINTER);
	wording W = Feeds::end(FD);
	if (sf == NULL) { PRINT("File has failed to open\n"); return; }
	parse_node_tree *syntax_tree = SyntaxTree::new();
	Sentences::break(syntax_tree, W);
	SyntaxTree::traverse(syntax_tree, Banking::parse);
}

void Banking::parse(parse_node *p) {
	if (Node::get_type(p) == SENTENCE_NT) {
		wording W = Node::get_text(p);
		if (<vocabulary-line>(W) == FALSE)
			Errors::nowhere("vocabulary line not understood");
	}
}

@ The file should contain a series of simple declarations, with the grammar
below. This is not parsed by the //linguistics// module at all: we do it all
with the facilities offered by the //syntax// and //words// modules.

Typical lines in the vocabulary look like this:
= (text)
	CARRIES = relationship.
	be = verb meaning IS with priority 2.
	be + on = preposition meaning CARRIES.
	Beth = feminine proper noun.
	sailor = neuter common noun.
=
And these are parsed by the following simple Preform grammar:

=
<vocabulary-line> ::=
	... = relationship |                                           ==> @<Create relationship@>;
	... = verb meaning <meaning> with priority <cardinal-number> | ==> @<Create verb@>;
	<existing-verb> + ... = preposition meaning <meaning> |        ==> @<Create preposition@>;
	... = <gender> common noun |                                   ==> @<Create common noun@>;
	... = <gender> proper noun                                     ==> @<Create proper noun@>;
	
<gender> ::=
	neuter |    ==> NEUTER_GENDER
	masculine | ==> MASCULINE_GENDER
	feminine    ==> FEMININE_GENDER

<meaning> internal 1 {
	*XP = Relating::find(W);
	if (*XP) return TRUE;
	return FALSE;
}

<existing-verb> internal {
	verb *V;
	LOOP_OVER(V, verb)
		if (WordAssemblages::compare_with_wording(&(V->conjugation->infinitive), W)) {
			*XP = V; return TRUE;
		}
	return FALSE;
}

@<Create relationship@> =
	Relating::new(FW[1]);

@<Create verb@> =
	rel *RN = (rel *) RP[1];
	verb_conjugation *vc =
		Conjugation::conjugate(
			WordAssemblages::from_wording(FW[1]), DefaultLanguage::get(NULL));
	verb *vi = Verbs::new_verb(vc, (RN == R_equality)?TRUE:FALSE);
	vc->vc_conjugates = vi;
	VerbUsages::register_all_usages_of_verb(vi, FALSE, R[2], NULL);
	Verbs::add_form(vi, NULL, NULL, VerbMeanings::regular(RN), SVO_FS_BIT);

@<Create preposition@> =
	word_assemblage wa = WordAssemblages::from_wording(FW[1]);
	preposition *prep = Prepositions::make(wa, FALSE, NULL);
	verb *V = (verb *) RP[1];
	rel *RN = (rel *) RP[2];
	Verbs::add_form(V, prep, NULL, VerbMeanings::regular(RN), SVO_FS_BIT);

@<Create common noun@> =
	Nouns::new_common_noun(FW[1], R[1], ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
		NOUN_MC, NULL_GENERAL_POINTER, DefaultLanguage::get(NULL));

@<Create proper noun@> =
	Nouns::new_proper_noun(FW[1], R[1], ADD_TO_LEXICON_NTOPT + WITH_PLURAL_FORMS_NTOPT,
		NOUN_MC, NULL, DefaultLanguage::get(NULL));
