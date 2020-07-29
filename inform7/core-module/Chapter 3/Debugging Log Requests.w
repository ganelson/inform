[Sentences::DLRs::] Debugging Log Requests.

Special sentences for changing what goes into the debugging log.

@ These are the special meaning functions for the sentences:

>> Include ... in the debugging log. Omit ... from the debugging log.

Which have identical semantics except for the positive or negative sense.
The object phrase has to be exactly "the debugging log", so:

=
<debugging-log-sentence-object> ::=
	the debugging log

@ =
int Sentences::DLRs::include_in_SMF(int task, parse_node *V, wording *NPs) {
	return Sentences::DLRs::dl_SMF(task, V, NPs, TRUE);
}

int Sentences::DLRs::omit_from_SMF(int task, parse_node *V, wording *NPs) {
	return Sentences::DLRs::dl_SMF(task, V, NPs, FALSE);
}

@ The subject phrase, however, can be a list...

=
int Sentences::DLRs::dl_SMF(int task, parse_node *V, wording *NPs, int sense) {
	wording SW = (NPs)?(NPs[2]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) {
		case ACCEPT_SMFT:
			if (<debugging-log-sentence-object>(OW)) {
				<np-articled-list>(SW);
				V->next = <<rp>>;
				Sentences::DLRs::switch_dl_mode(V->next, sense);
				return TRUE;
			}
			return FALSE;
		case ALLOW_IN_OPTIONS_FILE_SMFT:
			return TRUE;
	}
	return FALSE;
}

void Sentences::DLRs::switch_dl_mode(parse_node *PN, int sense) {
	if (Node::get_type(PN) == AND_NT) {
		Sentences::DLRs::switch_dl_mode(PN->down, sense);
		Sentences::DLRs::switch_dl_mode(PN->down->next, sense);
		return;
	}
	Sentences::DLRs::set_aspect_from_text(Node::get_text(PN), sense);
}

@ Each list entry must match the following, which returns a bitmap of
modifiers and a pointer to a Preform nonterminal if one has been named.

@d ONLY_DLR 1
@d EVERYTHING_DLR 2
@d NOTHING_DLR 4
@d SOMETHING_DLR 8
@d PREFORM_DLR 16

=
<debugging-log-sentence-subject> ::=
	only <debugging-log-request> |  ==> { R[1] | ONLY_DLR, RP[1] }
	<debugging-log-request>         ==> { pass 1 }

<debugging-log-request> ::=
	everything |                    ==> { EVERYTHING_DLR, NULL }
	nothing |                       ==> { NOTHING_DLR, NULL }
	<preform-nonterminal> |         ==> { PREFORM_DLR, RP[1] }
	...                             ==> { SOMETHING_DLR, NULL }

@ =
void Sentences::DLRs::set_aspect_from_text(wording W, int new_state) {
	LOGIF(DEBUGGING_LOG_INCLUSIONS,
		"Set contents of debugging log: %W -> %s\n",
		W, new_state?"TRUE":"FALSE");

	<debugging-log-sentence-subject>(W);
	if (<<r>> & ONLY_DLR) Log::set_all_aspects(new_state?FALSE:TRUE);
	if (<<r>> & EVERYTHING_DLR) { Log::set_all_aspects(new_state); return; }
	if (<<r>> & NOTHING_DLR) { Log::set_all_aspects(1-new_state); return; }
	if (<<r>> & SOMETHING_DLR) {
		TEMPORARY_TEXT(req)
		WRITE_TO(req, "%W", GET_RW(<debugging-log-request>, 1));
		int rv = Log::set_aspect_from_command_line(req, FALSE);
		DISCARD_TEXT(req)
		if (rv) return;
	}
	if (<<r>> & PREFORM_DLR) { Instrumentation::watch(<<rp>>, new_state); return; }

	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, W);
	StandardProblems::handmade_problem(Task::syntax_tree(), _p_(PM_UnknownDA));
	Problems::issue_problem_segment(
		"In the sentence %1, you asked to include '%2' in the "
		"debugging log, but there is no such debugging log topic.");
	Problems::issue_problem_end();
}
