[KindsProblems::] Kinds Problems.

Errors in setting up kinds and how they multiply are sometimes caught by the kinds
module: this section collects and issues such errors as tidy Inform problems.

@ The |:kinds| group of tests for //inform7// generates all of the problems
below.

@d PROBLEM_KINDS_CALLBACK KindsProblems::kinds_problem_handler

=
void KindsProblems::kinds_problem_handler(int err_no, parse_node *pn, text_stream *E,
	kind *K1, kind *K2) {
	switch (err_no) {
		case DimensionRedundant_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DimensionRedundant),
				"multiplication rules can only be given once",
				"and this combination is already established.");
			break;
		case DimensionNotBaseKOV_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DimensionNotBaseKOV),
				"multiplication rules can only involve simple kinds of value",
				"rather than complicated ones such as lists of other values.");
			break;
		case ImproperSubtraction_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_ImproperSubtractionKOV),
				"we can only specify the result of one kind minus itself",
				"and moreover it has to be a dimensionless kind.");
			break;
		case NonDimensional_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_NonDimensional),
				"multiplication rules can only be given between kinds of "
				"value which are known to be numerical",
				"and not all of these are. Saying something like 'Pressure is a "
				"kind of value.' is not enough - you may think 'pressure' ought "
				"to be numerical, but Inform doesn't know that yet. You need "
				"to add something like '100 Pa specifies a pressure.' before "
				"Inform will realise.");
			break;
		case UnitSequenceOverflow_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_UnitSequenceOverflow),
				"reading that sentence led me into calculating such a complicated "
				"kind of value that I ran out of memory",
				"which my programmer really didn't expect to happen. I think you "
				"must have made an awful lot of numerical kinds of value, and "
				"then specified how they multiply so that one of them became "
				"weirdly tricky. Can you simplify?");
			break;
		case DimensionsInconsistent_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_DimensionsInconsistent),
				"this is inconsistent with what is already known about those kinds of value",
				"all three of which already have well-established relationships - see the "
				"Kinds index for more.");
			break;
		case KindUnalterable_KINDERROR:
			Problems::quote_source(1, current_sentence);
			Problems::quote_source(2, pn);
			Problems::quote_kind(3, K1);
			Problems::quote_kind(4, K2);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindUnalterable));
			Problems::issue_problem_segment(
				"You wrote %1, but that seems to contradict %2, as %3 and %4 "
				"are incompatible. (If %3 were a kind of %4 or vice versa "
				"there'd be no problem, but they aren't.)");
			Problems::issue_problem_end();
			break;
		case KindsCircular_KINDERROR:
			Problems::quote_source(1, current_sentence);
			Problems::quote_source(2, pn);
			Problems::quote_kind(3, K1);
			Problems::quote_kind(4, K2);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindsCircular));
			Problems::issue_problem_segment(
				"You wrote %1, but that seems to contradict %2, as it would "
				"make a circularity with %3 and %4 each being kinds of the "
				"other.");
			Problems::issue_problem_end();
			break;
		case KindsCircular2_KINDERROR:
			Problems::quote_source(1, current_sentence);
			Problems::quote_source(2, pn);
			Problems::quote_kind(3, K1);
			Problems::quote_kind(4, K2);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_KindsCircular2));
			Problems::issue_problem_segment(
				"You wrote %1, but that seems to make %3 a kind of itself, which "
				"cannot make sense.");
			Problems::issue_problem_end();
			break;
		case LPCantScaleYet_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPCantScaleYet),
				"this tries to scale up or down a value which so far has no point of "
				"reference to scale from",
				"which is impossible.");
			break;
		case LPCantScaleTwice_KINDERROR:
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_LPCantScaleTwice),
				"this tries to specify the scaling for a kind of value whose "
				"scaling is already established",
				"which is impossible.");
			break;
		case NeptuneError_KINDERROR:
			Problems::quote_stream(1, E);
			StandardProblems::handmade_problem(Task::syntax_tree(), _p_(Untestable));
			Problems::issue_problem_segment(
				"One of the so-called Neptune files used to configure the kinds of value "
				"built into Inform contained an error. Either there is something wrong with "
				"this installation of Inform, or new Neptune files are being tried out but "
				"do not yet work. Specifically: '%1'.");
			Problems::issue_problem_end();
			break;
		default: internal_error("unimplemented problem message");
	}
}
