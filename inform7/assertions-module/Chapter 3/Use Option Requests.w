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
			UseOptions::set_use_options(V->next, task);
			break;
	}
	return FALSE;
}

@ "Use" sentences are simple in structure. Their object noun phrases are
articled lists:

>> Use American dialect and the serial comma.

=
void UseOptions::set_use_options(parse_node *p, int task) {
	if (Node::get_type(p) == AND_NT) {
		UseOptions::set_use_options(p->down, task);
		UseOptions::set_use_options(p->down->next, task);
		return;
	}
	@<Set a single use option@>;
}

@ Needed to provide a structured response from |<use-setting>|:

=
typedef struct parsed_use_option_setting {
	struct wording textual_option;
	struct use_option *resolved_option;
	struct parse_node *made_at;
	int at_least;
	int value;
	struct text_stream *language_for_pragma;
	struct text_stream *content_of_pragma;
	CLASS_DEFINITION
} parsed_use_option_setting;

parsed_use_option_setting *UseOptions::new_puos(wording W) {
	parsed_use_option_setting *puos = CREATE(parsed_use_option_setting);
	puos->textual_option = W;
	puos->resolved_option = NULL;
	puos->at_least = NOT_APPLICABLE;
	puos->value = -1;
	puos->language_for_pragma = NULL;
	puos->content_of_pragma = NULL;
	return puos;
}

parsed_use_option_setting *UseOptions::parse_setting(wording W) {
	<use-setting>(W);
	parsed_use_option_setting *puos = <<rp>>;
	puos->made_at = current_sentence;
	if (Wordings::empty(W)) internal_error("cannot parse empty setting wording");
	puos->resolved_option = NewUseOptions::parse_uo(puos->textual_option);
	return puos;
}

@ Each of the entries in this list must match the following; the text of the
option name is taken from the |...| or |###| as appropriate:

=
<use-inter-pipeline> ::=
	inter pipeline {<quoted-text>}                 ==> { TRUE, - }

<use-index-language> ::=
	... language index                             ==> { TRUE, - }

<use-memory-setting> ::=
	... compiler option {<quoted-text>} |          ==> @<Make a compiler option@>
	### of <cardinal-number-unlimited>             ==> @<Make an exact setting@>

<use-setting> ::=
	... of at least <cardinal-number-unlimited> |  ==> @<Make an at-least setting@>
	... of <cardinal-number-unlimited> |		   ==> @<Make an exact setting@>
	<definite-article> ...	|                      ==> @<Make a non-setting@>
	...                                            ==> @<Make a non-setting@>

@<Make a non-setting@> =
	parsed_use_option_setting *puos = UseOptions::new_puos(GET_RW(<use-setting>, 1));
	==> { -1, puos }

@<Make an at-least setting@> =
	int val = R[1];
	if (val < 0) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_UseOptionAtLeastNegative),
			"the minimum possible value is not allowed to be negative",
			"since it describes a quantity which must be 0 or more");
		val = 0;
	}
	parsed_use_option_setting *puos = UseOptions::new_puos(GET_RW(<use-setting>, 1));
	puos->at_least = TRUE;
	puos->value = val;
	==> { val, puos }

@<Make a compiler option@> =
	int val = R[1];
	parsed_use_option_setting *puos = UseOptions::new_puos(EMPTY_WORDING);
	puos->at_least = FALSE;
	puos->value = val;
	puos->language_for_pragma = Str::new();
	WRITE_TO(puos->language_for_pragma, "%+W", GET_RW(<use-memory-setting>, 1));
	puos->content_of_pragma = Str::new();
	WRITE_TO(puos->content_of_pragma, "%+W", GET_RW(<use-memory-setting>, 2));
	Str::delete_first_character(puos->content_of_pragma);
	Str::delete_last_character(puos->content_of_pragma);
	==> { -1, puos }

@<Make an exact setting@> =
	int val = R[1];
	parsed_use_option_setting *puos = UseOptions::new_puos(GET_RW(<use-setting>, 1));
	puos->at_least = FALSE;
	puos->value = val;
	==> { val, puos }

@<Set a single use option@> =
	wording S = Node::get_text(p);
	if (<use-inter-pipeline>(S))
		@<Set the pipeline given in this word range@>
	else if (<use-index-language>(S))
		@<Set index language@>
	else if (<use-memory-setting>(S))
		@<Set a memory setting@>
	else
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
	parsed_use_option_setting *puos = (parsed_use_option_setting *) <<rp>>;
	if (Str::len(puos->language_for_pragma) > 0) {
		NewUseOptions::pragma_setting(puos);
	} else {
		int n = <<r>>, w1 = Wordings::first_wn(S);
		TEMPORARY_TEXT(icl_identifier)
		WRITE_TO(icl_identifier, "%+W", Wordings::one_word(w1));
		NewUseOptions::memory_setting(icl_identifier, n);
		DISCARD_TEXT(icl_identifier)
	}

@ Whereas this is the standard use option syntax:

@<Set the option given in this word range@> =
	parsed_use_option_setting *puos = UseOptions::parse_setting(S);
	if (global_pass_state.pass > 1) {
		if (puos->resolved_option) NewUseOptions::set(puos);
		else {
			LOG("Used: %W\n", S);
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_UnknownUseOption),
				"that isn't a 'Use' option known to me",
				"and needs to be one of the ones listed in the documentation.");
		}
	}
