[NewAdjectiveRequests::] New Adjective Requests.

Special sentences for creating new adjectives.

@ This handles the special meaning "X is an adjective...".

=
<new-adjective-sentence-object> ::=
	<indefinite-article> <new-adjective-sentence-object-unarticled> |  ==> { pass 2 }
	<new-adjective-sentence-object-unarticled>                         ==> { pass 1 }

<new-adjective-sentence-object-unarticled> ::=
	adjective |                                                        ==> { TRUE, NULL }
	adjective implying/meaning <definite-article> <np-unparsed>	|      ==> { TRUE, RP[2] }
	adjective implying/meaning <np-unparsed>					       ==> { TRUE, RP[1] }

<adjective-definition-subject> ::=
	in <natural-language> ... |  ==> { TRUE, RP[1] }
	...                          ==> { TRUE, Projects::get_language_of_play(Task::project()) }

@ =
int NewAdjectiveRequests::new_adjective_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "In French petit is an adjective meaning..." */
		case ACCEPT_SMFT:
			if (<new-adjective-sentence-object>(OW)) {
				parse_node *O = <<rp>>;
				if (O == NULL) { <np-unparsed>(OW); O = <<rp>>; }
				<np-unparsed>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case PASS_1_SMFT: {
			wording W = Node::get_text(V->next);
			<adjective-definition-subject>(W);
			NATURAL_LANGUAGE_WORDS_TYPE *nl = <<rp>>;
			W = GET_RW(<adjective-definition-subject>, 1);
			if (!(<adaptive-adjective>(W))) Adjectives::declare(W, nl);
			break;
		}
	}
	return FALSE;
}
