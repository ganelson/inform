[Diagrams::] Diagrams.

To specify standard verb-phrase nodes in the parse tree.

@ This section lays out a sort of specification for what we ultinately want
to turn sentences into: i.e., little sentence diagrams made up of parse nodes.
We do that with the aid of the //syntax// module. So we must first set up
some new node types:

@e VERB_NT             				/* "is" */
@e UNPARSED_NOUN_NT       			/* "arfle barfle gloop" */
@e PRONOUN_NT       			    /* "them" */
@e DEFECTIVE_NOUN_NT       			/* "there" */
@e COMMON_NOUN_NT       			/* "a container" */
@e PROPER_NOUN_NT       			/* "the red handkerchief" */
@e RELATIONSHIP_NT      			/* "on" */
@e CALLED_NT            			/* "On the table is a container called the box" */
@e WITH_NT              			/* "The footstool is a supporter with capacity 2" */
@e AND_NT               			/* "whisky and soda" */
@e KIND_NT              			/* "A woman is a kind of person" */
@e PROPERTY_LIST_NT     			/* "capacity 2" */

@ These nodes are annotated with the following:

@e verbal_certainty_ANNOT        /* |int|: certainty level if known */
@e sentence_is_existential_ANNOT /* |int|: such as "there is a man" */
@e linguistic_error_here_ANNOT   /* |int|: one of the errors occurred here */
@e possessive_verb_ANNOT         /* |int|: this is a non-relative use of "to have" */
@e verb_ANNOT                    /* |verb_usage|: what's being done here */
@e noun_ANNOT                    /* |noun_usage|: what's being done here */
@e pronoun_ANNOT                 /* |pronoun_usage|: what's being done here */
@e article_ANNOT                 /* |article_usage|: what's being done here */
@e preposition_ANNOT             /* |preposition|: which preposition, if any, qualifies it */
@e second_preposition_ANNOT      /* |preposition|: which further preposition, if any, qualifies it */
@e verb_meaning_ANNOT            /* |verb_meaning|: what it means */
@e occurrence_ANNOT              /* |time_period|: any stipulation on occurrence */
@e explicit_gender_marker_ANNOT  /* |int|: used by PROPER NOUN nodes for evident genders */
@e relationship_ANNOT            /* |binary_predicate|: for RELATIONSHIP nodes */
@e relationship_node_type_ANNOT  /* |int|: what kind of inference this assertion makes */
@e implicitly_refers_to_ANNOT    /* |int|: this will implicitly refer to something */

=
DECLARE_ANNOTATION_FUNCTIONS(verb, verb_usage)
DECLARE_ANNOTATION_FUNCTIONS(noun, noun_usage)
DECLARE_ANNOTATION_FUNCTIONS(pronoun, pronoun_usage)
DECLARE_ANNOTATION_FUNCTIONS(article, article_usage)
DECLARE_ANNOTATION_FUNCTIONS(preposition, preposition)
DECLARE_ANNOTATION_FUNCTIONS(second_preposition, preposition)
DECLARE_ANNOTATION_FUNCTIONS(verb_meaning, verb_meaning)
DECLARE_ANNOTATION_FUNCTIONS(occurrence, time_period)

MAKE_ANNOTATION_FUNCTIONS(verb, verb_usage)
MAKE_ANNOTATION_FUNCTIONS(noun, noun_usage)
MAKE_ANNOTATION_FUNCTIONS(pronoun, pronoun_usage)
MAKE_ANNOTATION_FUNCTIONS(article, article_usage)
MAKE_ANNOTATION_FUNCTIONS(preposition, preposition)
MAKE_ANNOTATION_FUNCTIONS(second_preposition, preposition)
MAKE_ANNOTATION_FUNCTIONS(verb_meaning, verb_meaning)
MAKE_ANNOTATION_FUNCTIONS(occurrence, time_period)

@ The |linguistic_error_here_ANNOT| annotation is for any errors we find,
though at present there is just one:

@e TwoLikelihoods_LINERROR from 1

@ Two callbacks are needed so that the //syntax// module will create the above
nodes and annotations correctly:

@d EVEN_MORE_NODE_METADATA_SETUP_SYNTAX_CALLBACK Diagrams::setup
@d EVEN_MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK Diagrams::permissions

=
void Diagrams::setup(void) {
	NodeType::new(VERB_NT, I"VERB_NT",                     0, 0,     L3_NCAT, 0);
	NodeType::new(RELATIONSHIP_NT, I"RELATIONSHIP_NT",     0, 2,	   L3_NCAT, ASSERT_NFLAG);
	NodeType::new(CALLED_NT, I"CALLED_NT",                 2, 2,	   L3_NCAT, 0);
	NodeType::new(WITH_NT, I"WITH_NT",                     2, 2,	   L3_NCAT, ASSERT_NFLAG);
	NodeType::new(AND_NT, I"AND_NT",                       2, 2,	   L3_NCAT, ASSERT_NFLAG);
	NodeType::new(KIND_NT, I"KIND_NT",                     0, 1,     L3_NCAT, ASSERT_NFLAG);
	NodeType::new(UNPARSED_NOUN_NT, I"UNPARSED_NOUN_NT",   0, 0,	   L3_NCAT, ASSERT_NFLAG);
	NodeType::new(PRONOUN_NT, I"PRONOUN_NT",               0, 0,	   L3_NCAT, ASSERT_NFLAG);
	NodeType::new(DEFECTIVE_NOUN_NT, I"DEFECTIVE_NOUN_NT", 0, 0,	   L3_NCAT, ASSERT_NFLAG);
	NodeType::new(PROPER_NOUN_NT, I"PROPER_NOUN_NT",       0, 0,	   L3_NCAT, ASSERT_NFLAG);
	NodeType::new(COMMON_NOUN_NT, I"COMMON_NOUN_NT",	   0, INFTY, L3_NCAT, ASSERT_NFLAG);
	NodeType::new(PROPERTY_LIST_NT, I"PROPERTY_LIST_NT",   0, INFTY, L3_NCAT, ASSERT_NFLAG);
}

void Diagrams::permissions(void) {
	Annotations::allow(VERB_NT, verbal_certainty_ANNOT);
	Annotations::allow(VERB_NT, sentence_is_existential_ANNOT);
	Annotations::allow(VERB_NT, possessive_verb_ANNOT);
	Annotations::allow(VERB_NT, verb_ANNOT);
	Annotations::allow(VERB_NT, preposition_ANNOT);
	Annotations::allow(VERB_NT, second_preposition_ANNOT);
	Annotations::allow(VERB_NT, verb_meaning_ANNOT);
	Annotations::allow(VERB_NT, occurrence_ANNOT);
	Annotations::allow(UNPARSED_NOUN_NT, noun_ANNOT);
	Annotations::allow(PRONOUN_NT, pronoun_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, noun_ANNOT);
	Annotations::allow(COMMON_NOUN_NT, noun_ANNOT);
	Annotations::allow(RELATIONSHIP_NT, preposition_ANNOT);
	Annotations::allow(RELATIONSHIP_NT, relationship_ANNOT);
	Annotations::allow(RELATIONSHIP_NT, relationship_node_type_ANNOT);
	Annotations::allow_for_category(L3_NCAT, linguistic_error_here_ANNOT);
	Annotations::allow_for_category(L3_NCAT, explicit_gender_marker_ANNOT);
	Annotations::allow_for_category(L3_NCAT, article_ANNOT);
	Annotations::allow(UNPARSED_NOUN_NT, implicitly_refers_to_ANNOT);
	Annotations::allow(PROPER_NOUN_NT, implicitly_refers_to_ANNOT);
}

@ And the following conveniently prints out a sentence in diagram form; this
is used by //linguistics-test// to keep us on the straight and narrow.

=
void Diagrams::log_node(OUTPUT_STREAM, parse_node *pn) {
	switch (Annotations::read_int(pn, linguistic_error_here_ANNOT)) {
		case TwoLikelihoods_LINERROR: WRITE(" (*** TwoLikelihoods_LINERROR ***)"); break;
	}
	switch(pn->node_type) {
		case VERB_NT:
			if (Node::get_verb(pn))
				VerbUsages::write_usage(OUT, Node::get_verb(pn));
			if (Annotations::read_int(pn, sentence_is_existential_ANNOT))
				WRITE(" {existential}");
			if (Annotations::read_int(pn, possessive_verb_ANNOT))
				WRITE(" {possessive}");
			if (Node::get_verb_meaning(pn))
				WRITE(" {meaning: %S}",
					VerbMeanings::get_regular_meaning(Node::get_verb_meaning(pn))->debugging_log_name);
			if (Annotations::read_int(pn, verbal_certainty_ANNOT) != UNKNOWN_CE) {
				WRITE(" {certainty:");
				Certainty::write(OUT, Annotations::read_int(pn, verbal_certainty_ANNOT));
				WRITE("}");
			}
			if (Node::get_occurrence(pn)) {
				WRITE(" {occurrence: ");
				Occurrence::log(OUT, Node::get_occurrence(pn));
				WRITE("}");
			}
			break;
		case UNPARSED_NOUN_NT:
		case COMMON_NOUN_NT:
		case PROPER_NOUN_NT:
		case PRONOUN_NT:
		case DEFECTIVE_NOUN_NT:
			if (Node::get_noun(pn))
				Nouns::write_usage(OUT, Node::get_noun(pn));
			if (Node::get_pronoun(pn))
				Pronouns::write_usage(OUT, Node::get_pronoun(pn));
			if (Node::get_article(pn))
				Articles::write_usage(OUT, Node::get_article(pn));
			break;
		case RELATIONSHIP_NT:
			WRITE(" {meaning: ");
			switch (Annotations::read_int(pn, relationship_node_type_ANNOT)) {
				case STANDARD_RELN:
					if (Node::get_relationship(pn))
						WRITE("%S", Node::get_relationship(pn)->debugging_log_name);
					break;
				case PARENTAGE_HERE_RELN: WRITE("(here)"); break;
				case DIRECTION_RELN: WRITE("(direction)"); break;
			}
			WRITE("}");
			break;
	}
}
