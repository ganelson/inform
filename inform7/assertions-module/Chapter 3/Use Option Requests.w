[UseOptions::] Use Options.

Special sentences for setting compilation options.

@h The Use sentence.
Note that any sentence beginning with the word "Use" is accepted here, which
is a very wide net: unlike most special meaning sentences, there's no attempt
to cut down the risk of false positives by screening the noun phrase.

=
int UseOptions::use_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Use American dialect." */
		case ACCEPT_SMFT:
			<np-articled-list>(OW);
			V->next = <<rp>>;
			return TRUE;
		case ALLOW_IN_OPTIONS_FILE_SMFT:
			return TRUE;
		case PASS_1_SMFT:
		case PASS_2_SMFT:
			UseOptions::set_use_options(V->next);
			break;
	}
	return FALSE;
}

@ "Use" sentences are simple in structure. Their object noun phrases are
articled lists:

>> Use American dialect and the serial comma.

=
void UseOptions::set_use_options(parse_node *p) {
	if (Node::get_type(p) == AND_NT) {
		UseOptions::set_use_options(p->down);
		UseOptions::set_use_options(p->down->next);
		return;
	}
	@<Set a single use option@>;
}

@ Each of the entries in this list must match the following; the text of the
option name is taken from the |...| or |###| as appropriate:

=
<use-inter-pipeline> ::=
	inter pipeline {<quoted-text>}                 ==> { TRUE, - }

<use-index-language> ::=
	... language index                             ==> { TRUE, - }

<use-memory-setting> ::=
	### of <cardinal-number-unlimited>             ==> @<Validate the at-least setting@>

<use-setting> ::=
	... of at least <cardinal-number-unlimited> |  ==> @<Validate the at-least setting@>
	<definite-article> ...	|                      ==> { -1, - }
	...                                            ==> { -1, - }

@<Validate the at-least setting@> =
	if (R[1] < 0)
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UseOptionAtLeastNegative),
			"the minimum possible value is not allowed to be negative",
			"since it describes a quantity which must be 0 or more");
	==> { R[1], - }

@<Set a single use option@> =
	wording S = Node::get_text(p);
	if (<use-inter-pipeline>(S))
		@<Set the pipeline given in this word range@>
	else if (<use-index-language>(S))
		@<Set index language@>
	else if (<use-memory-setting>(S))
		@<Set a memory setting@>
	else if (<use-setting>(S))
		@<Set the option given in this word range@>

@ This is an undocumented feature used during the transition from I6 to Inter:

@<Set the pipeline given in this word range@> =
	wording CW = GET_RW(<use-inter-pipeline>, 1);
	if (global_pass_state.pass == 1) {
		TEMPORARY_TEXT(p)
		WRITE_TO(p, "%W", CW);
		Str::delete_first_character(p);
		Str::delete_last_character(p);
		Supervisor::set_inter_pipeline(p);
		DISCARD_TEXT(p)
	}

@ This is a somewhat experimental feature, too. For now, it is a deliberate
choice to fail silently if no such language is available.

@<Set index language@> =
	wording CW = GET_RW(<use-index-language>, 1);
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%+W", CW);
	inform_language *L = Languages::find_for(name, Projects::nest_list(Task::project()));
	DISCARD_TEXT(name)
	if (L) Projects::set_language_of_index(Task::project(), L);
	else LOG("Cannot find language %S: ignoring use option\n", name);

@ ICL, the "Inform 6 control language", is a set of a pragma-like settings for
the I6 compiler. Of course, in the age in Inter, those might well be ignored,
since the compiler next down the chain may no longer be I6.

See //runtime: Use Options// for what happens to these.

@<Set a memory setting@> =
	int n = <<r>>, w1 = Wordings::first_wn(S);
	TEMPORARY_TEXT(icl_identifier)
	WRITE_TO(icl_identifier, "%+W", Wordings::one_word(w1));
	if (Str::len(icl_identifier) > 63) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_BadICLIdentifier),
			"that is too long to be an ICL identifier",
			"so can't be the name of any I6 memory setting.");
	}
	NewUseOptions::memory_setting(icl_identifier, n);
	DISCARD_TEXT(icl_identifier)

@ Whereas thus is the standard use option syntax:

@<Set the option given in this word range@> =
	int min_setting = <<r>>;
	wording OW = GET_RW(<use-setting>, 1);
	use_option *uo = NewUseOptions::parse_uo(OW);
	if (uo) NewUseOptions::set(uo, min_setting,
		Lexer::file_of_origin(Wordings::first_wn(OW)));
	else if (global_pass_state.pass > 1) {
		LOG("Used: %W\n", S);
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UnknownUseOption),
			"that isn't a 'Use' option known to me",
			"and needs to be one of the ones listed in the documentation.");
	}
