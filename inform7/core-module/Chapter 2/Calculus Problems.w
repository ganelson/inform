[CalculusProblems::] Calculus Problems.

Errors with formulating logical statements are sometimes caught by the calculus
module: this section collects and issues such errors as tidy Inform problems.

@ The |:calculus| group of tests for //inform7// generates all of the problems
below.

@d PROBLEM_CALCULUS_CALLBACK CalculusProblems::issue_problem

=
void CalculusProblems::issue_problem(int err_no, parse_node *spec, wording W,
	kind *K1, kind *K2, binary_predicate *bp, tc_problem_kit *tck) {
	switch(err_no) {
		case BareKindVariable_CALCERROR:
			Problems::quote_source(1, current_sentence);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_BareKindVariable));
			Problems::issue_problem_segment(
				"The sentence %1 seems to use a kind variable by its letter "
				"alone in the context of a noun, which Inform doesn't allow. "
				"It's fine to say 'if the noun is a K', for example, but "
				"not 'if K is number'. By putting 'a' or 'an' in front of the "
				"kind variable, you make clear that I'm supposed to perform "
				"matching against a description.");
			Problems::issue_problem_end();
			break;
		case ConstantFailed_CALCERROR:
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, Node::get_text(spec));
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
			Problems::issue_problem_segment(
				"The sentence %1 seems to contain a value '%2' which I can't make "
				"any sense of.");
			Problems::issue_problem_end();
			break;
		case UnaryMisapplied_CALCERROR:
			Problems::quote_wording(4, W);
			Problems::quote_kind(5, K1);
			StandardProblems::tcp_problem(_p_(PM_AdjectiveMisapplied), tck,
				"that seems to involve applying the adjective '%4' to %5 - and I "
				"have no definition of it which would apply in that situation. "
				"(Try looking it up in the Lexicon part of the Phrasebook index "
				"to see what definition(s) '%4' has.)");
			break;
		case ComparisonFailed_CALCERROR:
			Problems::quote_kind(4, K1);
			Problems::quote_kind(5, K2);
			char *msg;
			if (((Kinds::eq(K1, K_time)) && (Kinds::eq(K2, K_time_period))) ||
				((Kinds::eq(K2, K_time)) && (Kinds::eq(K1, K_time_period))))
				msg = "that would mean comparing two kinds of value which cannot mix - "
					"%4 and %5 - so this must be incorrect. Note that 'time period', "
					"introduced in Inform in 2024, holds values like '10 minutes', "
					"and is not the same kind as 'time', which is for times of day "
					"like '6:12 PM'. (Before 2024, the same kind was used for both.)";
			else
				msg = "that would mean comparing two kinds of value which cannot mix - "
					"%4 and %5 - so this must be incorrect.";
			StandardProblems::tcp_problem(_p_(PM_ComparisonFailed), tck, msg);					
			break;
		case BadUniversal1_CALCERROR:
			Problems::quote_kind(4, K1);
			StandardProblems::tcp_problem(_p_(PM_BadUniversal1), tck,
				"that asks whether something relates something, and in Inform 'to relate' "
				"means that a particular relation applies between two things. Here, though, "
				"we have %4 rather than the name of a relation.");
			break;
		case BadUniversal2_CALCERROR:
			Problems::quote_kind(4, K1);
			StandardProblems::tcp_problem(_p_(BelievedImpossible), tck,
				"that asks whether something relates something, and in Inform 'to relate' "
				"means that a particular relation applies between two things. Here, though, "
				"we have %4 rather than the combination of the two things.");
			break;
		case BinaryMisapplied1_CALCERROR:
			Problems::quote_kind(4, K1);
			Problems::quote_kind(5, K2);
			Problems::quote_relation(6, bp);
			StandardProblems::tcp_problem(_p_(PM_TypeCheckBP2a), tck,
				"that doesn't work because you use %6 with %4 instead of %5.");
			break;
		case BinaryMisapplied2_CALCERROR:
			Problems::quote_kind(4, K1);
			Problems::quote_kind(5, K2);
			Problems::quote_relation(6, bp);
			StandardProblems::tcp_problem(_p_(PM_TypeCheckBP2), tck,
				"that would mean applying %6 to kinds of value which do not "
				"fit - %4 and %5 - so this must be incorrect.");
			break;
		case KindMismatch_CALCERROR:
			Problems::quote_kind(4, K1);
			Problems::quote_kind(5, K2);
			StandardProblems::tcp_problem(_p_(PM_TypeCheckKind), tck,
				"%4 cannot be %5, so this must be incorrect.");
			break;
		default:
			internal_error("unknown calculus error");
	}
}
