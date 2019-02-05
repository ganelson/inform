[Diagrams::] Diagrams.

To construct standard verb-phrase nodes in the parse tree.

@h Node types.

@e L3_NCAT

@e AVERB_NT             			/* "is" */
@e PROPER_NOUN_NT       			/* "the red handkerchief" */

@e RELATIONSHIP_NT      			/* "on" */
@e CALLED_NT            			/* "On the table is a container called the box" */
@e WITH_NT              			/* "The footstool is a supporter with capacity 2" */
@e AND_NT               			/* "whisky and soda" */
@e KIND_NT              			/* "A woman is a kind of person" */
@e PROPERTY_LIST_NT     			/* "capacity 2" */

@e verbal_certainty_ANNOT		/* |int|: certainty level if known */
@e sentence_is_existential_ANNOT /* |int|: such as "there is a man" */
@e linguistic_error_here_ANNOT   /* |int|: one of the errors occurred here */
@e inverted_verb_ANNOT   		/* |int|: an inversion of subject and object has occurred */
@e possessive_verb_ANNOT   		/* |int|: this is a non-relative use of "to have" */
@e verb_ANNOT   					/* |verb_usage|: what's being done here */
@e preposition_ANNOT   			/* |preposition_identity|: which preposition, if any, qualifies it */
@e second_preposition_ANNOT   	/* |preposition_identity|: which further preposition, if any, qualifies it */
@e verb_meaning_ANNOT   			/* |verb_meaning|: what it means */

@e nounphrase_article_ANNOT 		/* |int|: definite or indefinite article: see below */
@e plural_reference_ANNOT 		/* |int|: used by PROPER NOUN nodes for evident plurals */
@e gender_reference_ANNOT 		/* |int|: used by PROPER NOUN nodes for evident genders */
@e relationship_node_type_ANNOT 	/* |int|: what kind of inference this assertion makes */
@e implicitly_refers_to_ANNOT 	/* |int|: this will implicitly refer to something */

@d ASSERT_NFLAG		0x00000008 /* allow this on either side of an assertion? */

@e TwoLikelihoods_LINERROR

=
DECLARE_ANNOTATION_FUNCTIONS(verb, verb_usage)
DECLARE_ANNOTATION_FUNCTIONS(preposition, preposition_identity)
DECLARE_ANNOTATION_FUNCTIONS(second_preposition, preposition_identity)
DECLARE_ANNOTATION_FUNCTIONS(verb_meaning, verb_meaning)

@ =
MAKE_ANNOTATION_FUNCTIONS(verb, verb_usage)
MAKE_ANNOTATION_FUNCTIONS(preposition, preposition_identity)
MAKE_ANNOTATION_FUNCTIONS(second_preposition, preposition_identity)
MAKE_ANNOTATION_FUNCTIONS(verb_meaning, verb_meaning)

void Diagrams::setup(void) {
	ParseTree::md((parse_tree_node_type) { AVERB_NT, "AVERB_NT", 0, 0, L3_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { RELATIONSHIP_NT, "RELATIONSHIP_NT",	   					0, 2,		L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { CALLED_NT, "CALLED_NT",				   					2, 2,		L3_NCAT, 0 });
	ParseTree::md((parse_tree_node_type) { WITH_NT, "WITH_NT",					   					2, 2,		L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { AND_NT, "AND_NT",						   					2, 2,		L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { KIND_NT, "KIND_NT",				       					0, 1,		L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { PROPER_NOUN_NT, "PROPER_NOUN_NT",		   					0, 0,		L3_NCAT, ASSERT_NFLAG });
	ParseTree::md((parse_tree_node_type) { PROPERTY_LIST_NT, "PROPERTY_LIST_NT",	   					0, INFTY,	L3_NCAT, ASSERT_NFLAG });
	ParseTree::allow_annotation(AVERB_NT, verbal_certainty_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, sentence_is_existential_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, possessive_verb_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, inverted_verb_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, verb_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, preposition_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, second_preposition_ANNOT);
	ParseTree::allow_annotation(AVERB_NT, verb_meaning_ANNOT);
	ParseTree::allow_annotation(RELATIONSHIP_NT, preposition_ANNOT);
	ParseTree::allow_annotation(RELATIONSHIP_NT, relationship_node_type_ANNOT);
	ParseTree::allow_annotation_to_category(L3_NCAT, linguistic_error_here_ANNOT);
	ParseTree::allow_annotation_to_category(L3_NCAT, gender_reference_ANNOT);
	ParseTree::allow_annotation_to_category(L3_NCAT, nounphrase_article_ANNOT);
	ParseTree::allow_annotation_to_category(L3_NCAT, plural_reference_ANNOT);
	ParseTree::allow_annotation(PROPER_NOUN_NT, implicitly_refers_to_ANNOT);
}

@ =
void Diagrams::log_node(OUTPUT_STREAM, parse_node *pn) {
	switch (ParseTree::int_annotation(pn, linguistic_error_here_ANNOT)) {
		case TwoLikelihoods_LINERROR: WRITE(" (*** TwoLikelihoods_LINERROR ***)"); break;
	}
	switch(pn->node_type) {
		case AVERB_NT:
			if (ParseTree::int_annotation(pn, sentence_is_existential_ANNOT))
				WRITE(" (existential)");
			if (ParseTree::int_annotation(pn, possessive_verb_ANNOT))
				WRITE(" (possessive)");
			if (ParseTree::int_annotation(pn, inverted_verb_ANNOT))
				WRITE(" (inverted)");
			if (ParseTree::get_verb_meaning(pn)) {
				WRITE(" $y", ParseTree::get_verb_meaning(pn));
			}
			break;
		case PROPER_NOUN_NT:
			switch (ParseTree::int_annotation(pn, nounphrase_article_ANNOT)) {
				case IT_ART: WRITE(" (pronoun)"); break;
				case DEF_ART: WRITE(" (definite)"); break;
				case INDEF_ART: WRITE(" (indefinite)"); break;
			}
			if (ParseTree::int_annotation(pn, plural_reference_ANNOT)) WRITE(" (plural)");
			break;
		case RELATIONSHIP_NT:
			switch (ParseTree::int_annotation(pn, relationship_node_type_ANNOT)) {
				case STANDARD_RELN:
					#ifdef CORE_MODULE
					if (ParseTree::get_relationship(pn))
						LOG(" (%S)", ParseTree::get_relationship(pn)->debugging_log_name);
					#endif
					break;
				case PARENTAGE_HERE_RELN: WRITE(" (here)"); break;
				case DIRECTION_RELN: WRITE(" (direction)"); break;
			}
			break;
	}
}
