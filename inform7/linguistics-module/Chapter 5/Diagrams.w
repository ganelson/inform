[Diagrams::] Diagrams.

To construct standard verb-phrase nodes in the parse tree.

@h Node types.

@e AVERB_NT             			/* "is" */
@e PROPER_NOUN_NT       			/* "the red handkerchief" */

@e RELATIONSHIP_NT      			/* "on" */
@e CALLED_NT            			/* "On the table is a container called the box" */
@e WITH_NT              			/* "The footstool is a supporter with capacity 2" */
@e AND_NT               			/* "whisky and soda" */
@e KIND_NT              			/* "A woman is a kind of person" */
@e PROPERTY_LIST_NT     			/* "capacity 2" */

@d ASSERT_NFLAG		0x00000008 /* allow this on either side of an assertion? */

@e TwoLikelihoods_LINERROR

@d EVEN_MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK Diagrams::setup
@d EVEN_MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK Diagrams::permissions

=
void Diagrams::setup(void) {
	NodeType::new(AVERB_NT, I"AVERB_NT",                 0, 0,     L3_NCAT, 0);
	NodeType::new(RELATIONSHIP_NT, I"RELATIONSHIP_NT",   0, 2,	  L3_NCAT, ASSERT_NFLAG);
	NodeType::new(CALLED_NT, I"CALLED_NT",               2, 2,	  L3_NCAT, 0);
	NodeType::new(WITH_NT, I"WITH_NT",                   2, 2,	  L3_NCAT, ASSERT_NFLAG);
	NodeType::new(AND_NT, I"AND_NT",                     2, 2,	  L3_NCAT, ASSERT_NFLAG);
	NodeType::new(KIND_NT, I"KIND_NT",                   0, 1,     L3_NCAT, ASSERT_NFLAG);
	NodeType::new(PROPER_NOUN_NT, I"PROPER_NOUN_NT",     0, 0,	  L3_NCAT, ASSERT_NFLAG);
	NodeType::new(PROPERTY_LIST_NT, I"PROPERTY_LIST_NT", 0, INFTY, L3_NCAT, ASSERT_NFLAG);
}

void Diagrams::permissions(void) {
	Annotations::allow(AVERB_NT, verbal_certainty_ANNOT);
	Annotations::allow(AVERB_NT, sentence_is_existential_ANNOT);
	Annotations::allow(AVERB_NT, possessive_verb_ANNOT);
	Annotations::allow(AVERB_NT, inverted_verb_ANNOT);
	Annotations::allow(AVERB_NT, verb_ANNOT);
	Annotations::allow(AVERB_NT, preposition_ANNOT);
	Annotations::allow(AVERB_NT, second_preposition_ANNOT);
	Annotations::allow(AVERB_NT, verb_meaning_ANNOT);
	Annotations::allow(RELATIONSHIP_NT, preposition_ANNOT);
	Annotations::allow(RELATIONSHIP_NT, relationship_node_type_ANNOT);
	Annotations::allow_for_category(L3_NCAT, linguistic_error_here_ANNOT);
	Annotations::allow_for_category(L3_NCAT, gender_reference_ANNOT);
	Annotations::allow_for_category(L3_NCAT, nounphrase_article_ANNOT);
	Annotations::allow_for_category(L3_NCAT, plural_reference_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, implicitly_refers_to_ANNOT);
}

@ =
void Diagrams::log_node(OUTPUT_STREAM, parse_node *pn) {
	switch (Annotations::read_int(pn, linguistic_error_here_ANNOT)) {
		case TwoLikelihoods_LINERROR: WRITE(" (*** TwoLikelihoods_LINERROR ***)"); break;
	}
	switch(pn->node_type) {
		case AVERB_NT:
			if (Annotations::read_int(pn, sentence_is_existential_ANNOT))
				WRITE(" (existential)");
			if (Annotations::read_int(pn, possessive_verb_ANNOT))
				WRITE(" (possessive)");
			if (Annotations::read_int(pn, inverted_verb_ANNOT))
				WRITE(" (inverted)");
			if (Node::get_verb_meaning(pn)) {
				WRITE(" $y", Node::get_verb_meaning(pn));
			}
			break;
		case PROPER_NOUN_NT:
			switch (Annotations::read_int(pn, nounphrase_article_ANNOT)) {
				case IT_ART: WRITE(" (pronoun)"); break;
				case DEF_ART: WRITE(" (definite)"); break;
				case INDEF_ART: WRITE(" (indefinite)"); break;
			}
			if (Annotations::read_int(pn, plural_reference_ANNOT)) WRITE(" (plural)");
			break;
		case RELATIONSHIP_NT:
			switch (Annotations::read_int(pn, relationship_node_type_ANNOT)) {
				case STANDARD_RELN:
					#ifdef CORE_MODULE
					if (Node::get_relationship(pn))
						LOG(" (%S)", Node::get_relationship(pn)->debugging_log_name);
					#endif
					break;
				case PARENTAGE_HERE_RELN: WRITE(" (here)"); break;
				case DIRECTION_RELN: WRITE(" (direction)"); break;
			}
			break;
	}
}
