[UseOptions::] Use Options.

To control compiler settings, pragma-style.

@h Definitions.

@ The preferred way to pass "do it this way, not that way" instructions to
Inform, in the spirit of natural-language input, is not to use command-line
arguments in the shell but to write suitable sentences in the source text.
For instance:

>> Use American dialect and the serial comma.

Use options like "American dialect" take the place of what would be switches
like |--american-dialect| in a conventional Unix tool. They are themselves
defined by the source text (almost always the Standard Rules). They generally
control run-time behaviour, and as a result Inform deals with them simply by
defining suitable I6 constants in the I6 code being output: conditional
compilation of the I6 template layer then delivers the desired result.

But a few use options are more analogous to compiler pragmas, changing how
Inform treats the rest of the source text. In some cases, they affect only
the source text file they come from -- for example, so that an Extension can
set a use option applying only to itself.

=
typedef struct use_option {
	struct wording name; /* word range where name is stored */
	struct parse_node *option_expansion; /* definition as given in source */
	struct parse_node *where_used; /* where the option is taken in the source */
	int option_used; /* set if this option has been taken */
	int source_file_scoped; /* scope is the current source file only? */
	int minimum_setting_value; /* for those which are numeric */
	MEMORY_MANAGEMENT
} use_option;

@ Five of the pragma-like settings are stored here:

= (early code)
int memory_economy_in_force = FALSE;
int dynamic_memory_allocation = 0;
int allow_engineering_notation = FALSE;
int use_exact_parsing_option = FALSE;
int index_figure_thumbnails = 50;

@ We can also meddle with the I6 memory settings which will be used to finish
compiling the story file. We need this because we have no practical way to
predict when our code will break I6's limits: the only reasonable way it can
work is for the user to hit the limit occasionally, and then raise that limit
by hand with a sentence in the source text.

=
typedef struct i6_memory_setting {
	struct text_stream *ICL_identifier; /* see the DM4 for the I6 memory setting names */
	int number; /* e.g., |50000| means "at least 50,000" */
	MEMORY_MANAGEMENT
} i6_memory_setting;

@ Here first is the sentence handler for "Use ... means ..." sentences.

=
int UseOptions::use_translates_as_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Use American dialect means ..." */
		case ACCEPT_SMFT:
			if (<use-translates-as-sentence-subject>(SW)) {
				ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				V->next = <<rp>>;
				<nounphrase>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
			UseOptions::new_use_option(V);
			break;
	}
	return FALSE;
}


void UseOptions::new_use_option(parse_node *p) {
	if ((<use-translates-as-sentence-object>(ParseTree::get_text(p->next->next))) &&
		(<use-sentence-object>(ParseTree::get_text(p->next)))) {
		wording OW = GET_RW(<use-sentence-object>, 1);
		use_option *uo = CREATE(use_option);
		uo->name = OW;
		uo->option_expansion = p->next->next;
		uo->option_used = FALSE;
		if (<<r>> > 0) uo->minimum_setting_value = <<r>>;
		else uo->minimum_setting_value = -1;
		uo->source_file_scoped = FALSE;
		if ((<notable-use-option-name>(OW)) && (<<r>> == AUTHORIAL_MODESTY_UO))
			uo->source_file_scoped = TRUE;
		Nouns::new_proper_noun(OW, NEUTER_GENDER,
			REGISTER_SINGULAR_NTOPT + PARSE_EXACTLY_NTOPT,
			MISCELLANEOUS_MC, Rvalues::from_use_option(uo));
	}
}

@ The object for such a sentence is just an I6 expansion:

=
<use-translates-as-sentence-subject> ::=
	use <nounphrase>			==> TRUE; *XP = RP[1]

<use-translates-as-sentence-object> ::=
	(- ### |					==> TRUE
	...							==> @<Issue PM_UseTranslatesNotI6 problem@>

@<Issue PM_UseTranslatesNotI6 problem@> =
	*X = FALSE;
	Problems::Issue::sentence_problem(_p_(PM_UseTranslatesNotI6),
		"that translates into something which isn't a simple I6 inclusion",
		"placed in '(-' and '-)' markers.");

@ Having registered the use option names as miscellaneous, we need to parse
them back that way too:

=
use_option *UseOptions::parse_uo(wording OW) {
	parse_node *p = ExParser::parse_excerpt(MISCELLANEOUS_MC, OW);
	if (Rvalues::is_CONSTANT_of_kind(p, K_use_option)) {
		return Rvalues::to_use_option(p);
	}
	return NULL;
}

@ "Use" sentences are simple in structure. Their object noun phrases are
articled lists:

>> Use American dialect and the serial comma.

Each of the entries in this list must match the following; the text of the
option name is taken from the |...| or |###| as appropriate:

=
<use-sentence-object> ::=
	... of at least <cardinal-number-unlimited> |	==> R[1]
	### of <cardinal-number-unlimited> |			==> -R[1]
	<definite-article> ...	|						==> 0
	...												==> 0

<use-inter-chain> ::=
	inter chain {<quoted-text>} 					==> TRUE

@ These are use option names which Inform provides special support for; it
recognises the English names when they are defined by the Standard Rules. (So
there is no need to translate this to other languages.)

=
<notable-use-option-name> ::=
	authorial modesty |
	dynamic memory allocation |
	memory economy |
	no deprecated features |
	numbered rules |
	telemetry recordings |
	scoring |
	no scoring |
	engineering notation |
	unabbreviated object names |
	index figure thumbnails |
	gn testing version

@ And these correspond to:

@d AUTHORIAL_MODESTY_UO 0
@d DYNAMIC_MEMORY_ALLOCATION_UO 1
@d MEMORY_ECONOMY_UO 2
@d NO_DEPRECATED_FEATURES_UO 3
@d NUMBERED_RULES_UO 4
@d TELEMETRY_RECORDING_UO 5
@d SCORING_UO 6
@d NO_SCORING_UO 7
@d ENGINEERING_NOTATION_UO 8
@d UNABBREVIATED_OBJECT_NAMES_UO 9
@d INDEX_FIGURE_THUMBNAILS_UO 10
@d GN_TESTING_VERSION_UO 11

@ =
int UseOptions::use_SMF(int task, parse_node *V, wording *NPs) {
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Use American dialect." */
		case ACCEPT_SMFT:
			ParseTree::annotate_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
			<nounphrase-articled-list>(OW);
			V->next = <<rp>>;
			return TRUE;
		case TRAVERSE1_SMFT:
		case TRAVERSE2_SMFT:
			UseOptions::set_use_options(V->next);
			break;
	}
	return FALSE;
}

void UseOptions::handle_set_use_option(parse_node *p) {
	UseOptions::set_use_options(p->down->next);
}

void UseOptions::set_use_options(parse_node *p) {
	if (ParseTree::get_type(p) == AND_NT) {
		UseOptions::set_use_options(p->down);
		UseOptions::set_use_options(p->down->next);
		return;
	}
	if (<use-inter-chain>(ParseTree::get_text(p))) @<Set the chain given in this word range@>
	else if (<use-sentence-object>(ParseTree::get_text(p))) @<Set the option given in this word range@>;
	if (traverse == 1) return;
	LOG("Used: %W\n", ParseTree::get_text(p));
	Problems::Issue::sentence_problem(_p_(PM_UnknownUseOption),
		"that isn't a 'Use' option known to me",
		"and needs to be one of the ones listed in the documentation.");
}

@<Set the option given in this word range@> =
	int min_setting = -1;
	if (<<r>> < 0) @<Deal with the case of an I6 memory setting@>;
	if (<<r>> > 0) min_setting = <<r>>;
	wording OW = GET_RW(<use-sentence-object>, 1);
	use_option *uo = UseOptions::parse_uo(OW);
	if (uo) {
		extension_file *ef = NULL;
		@<Adjust the minimum setting@>;
		if (uo->source_file_scoped) {
			ef = SourceFiles::get_extension_corresponding(Lexer::file_of_origin(Wordings::first_wn(OW)));
			if (ef == NULL) { /* that is, if used in the main source text */
				uo->option_used = TRUE;
				uo->where_used = current_sentence;
			}
		} else {
			uo->option_used = TRUE;
			uo->where_used = current_sentence;
		}
		UseOptions::set_immediate_option_flags(OW, uo);
		return;
	}

@<Set the chain given in this word range@> =
	wording CW = GET_RW(<use-inter-chain>, 1);
	CoreMain::set_inter_chain(CW);
	return;

@<Adjust the minimum setting@> =
	if (uo->minimum_setting_value == -1) {
		if (min_setting != -1)
			Problems::Issue::sentence_problem(_p_(PM_UONotNumerical),
				"that 'Use' option does not have a numerical setting",
				"but is either used or not used.");
	} else {
		if (min_setting >= uo->minimum_setting_value)
			uo->minimum_setting_value = min_setting;
	}

@<Deal with the case of an I6 memory setting@> =
	int n = -<<r>>, w1 = Wordings::first_wn(ParseTree::get_text(p));
	TEMPORARY_TEXT(new_identifier);
	WRITE_TO(new_identifier, "%+W", Wordings::one_word(w1));
	if (Str::len(new_identifier) > 63) {
		Problems::Issue::sentence_problem(_p_(PM_BadICLIdentifier),
			"that is too long to be an ICL identifier",
			"so can't be the name of any I6 memory setting.");
	}
	i6_memory_setting *ms;
	LOOP_OVER(ms, i6_memory_setting)
		if (Str::eq(new_identifier, ms->ICL_identifier)) {
			if (ms->number < n) ms->number = n;
			return;
		}
	ms = CREATE(i6_memory_setting);
	ms->ICL_identifier = Str::duplicate(new_identifier);
	ms->number = n;
	DISCARD_TEXT(new_identifier);
	return;

@ For the pragma-like UOs:

=
use_option *uo_being_set = NULL;
void UseOptions::set_immediate_option_flags(wording W, use_option *uo) {
	uo_being_set = uo;
	<immediate-use>(W);
}

@ Some use options need to acted on immediately -- for instance, if they're
set in the "Options.txt" file and they affect how Inform parses subsequent
sentences. The following works through a list of use options, acting on
those which need immediate action.

=
<immediate-use> ::=
	... |											==> TRUE; return preform_lookahead_mode; /* match only when looking ahead */
	<immediate-use-entry> <immediate-use-tail> |	==> TRUE
	<immediate-use-entry>							==> TRUE

<immediate-use-tail> ::=
	, _and <immediate-use> |
	_,/and <immediate-use>

<immediate-use-entry> ::=
	<notable-use-option-name> |						==> @<Act on this use option immediately@>
	......

@<Act on this use option immediately@> =
	switch (R[1]) {
		case AUTHORIAL_MODESTY_UO: {
			extension_file *ef =
				SourceFiles::get_extension_corresponding(
					Lexer::file_of_origin(Wordings::first_wn(W)));
			if (ef == NULL) Extensions::Files::set_general_authorial_modesty();
			else Extensions::Files::set_authorial_modesty(ef);
			break;
		}
		case DYNAMIC_MEMORY_ALLOCATION_UO:
			if (uo_being_set) dynamic_memory_allocation = uo_being_set->minimum_setting_value;
			break;
		case MEMORY_ECONOMY_UO: memory_economy_in_force = TRUE; break;
		case NO_DEPRECATED_FEATURES_UO: no_deprecated_features = TRUE; break;
		case NUMBERED_RULES_UO: Rules::set_numbered_rules(); break;
		case TELEMETRY_RECORDING_UO: telemetry_recording = TRUE; break;
		case SCORING_UO: scoring_option_set = TRUE; break;
		case NO_SCORING_UO: scoring_option_set = FALSE; break;
		case ENGINEERING_NOTATION_UO: allow_engineering_notation = TRUE; break;
		case UNABBREVIATED_OBJECT_NAMES_UO: use_exact_parsing_option = TRUE; break;
		case INDEX_FIGURE_THUMBNAILS_UO:
			if (uo_being_set) index_figure_thumbnails = uo_being_set->minimum_setting_value;
			break;
		case GN_TESTING_VERSION_UO:
			break;
	}

@ It's possible to configure the size of the memory allocation for the run-time
heap, on which strings, lists and stored actions sit; here's where the level
is read:

=
int UseOptions::get_dynamic_memory_allocation(void) {
	return dynamic_memory_allocation;
}

@ This keeps the Contents page of the index from exploding:

=
int UseOptions::get_index_figure_thumbnails(void) {
	return index_figure_thumbnails;
}

@ And this is what the rest of Inform calls to find out whether a particular
pragma is set:

=
int UseOptions::uo_set_from(use_option *uo, int category, extension_file *ef) {
	source_file *sf = (uo->where_used)?(Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(uo->where_used)))):NULL;
	extension_file *efo = (sf)?(SourceFiles::get_extension_corresponding(sf)):NULL;
	switch (category) {
		case 1: if ((sf) && (efo == NULL)) return TRUE; break;
		case 2: if (sf == NULL) return TRUE; break;
		case 3: if ((sf) && (efo == ef)) return TRUE; break;
	}
	return FALSE;
}

@ Most use options, though, take effect by causing a constant to be defined
in the I6 code, or more generally by inserting some I6.

(The flummery about memory economy is to take care of obscure bugs which
can occur if an attempt to release with an existing story file goes wrong
and problem messages must be issued.)

=
void UseOptions::compile(void) {
	use_option *uo;
	LOOP_OVER(uo, use_option)
		if ((uo->option_used) || (uo->minimum_setting_value >= 0)) {
			text_stream *UO = Str::new();
			TemplateFiles::interpret(UO,
				Lexer::word_raw_text(Wordings::first_wn(ParseTree::get_text(uo->option_expansion)) + 1),
				NULL, uo->minimum_setting_value);
			WRITE_TO(UO, "\n");
			Emit::intervention(EARLY_LINK_STAGE, NULL, NULL, UO, NULL);
		}
}

@ I6 memory settings need to be issued as ICL commands at the top of the I6
source code: see the DM4 for details.

=
void UseOptions::compile_icl_commands(void) {
	Emit::pragma(I"-s");
	i6_memory_setting *ms;
	LOOP_OVER(ms, i6_memory_setting) {
		if ((Str::eq_wide_string(ms->ICL_identifier, L"MAX_LOCAL_VARIABLES")) &&
			(VirtualMachines::allow_MAX_LOCAL_VARIABLES() == FALSE))
			continue;
		TEMPORARY_TEXT(prag);
		WRITE_TO(prag, "$%S=%d", ms->ICL_identifier, ms->number);
		Emit::pragma(prag);
		DISCARD_TEXT(prag);
	}
}

@ Now for indexing, where there's nothing much to see.

@d MAIN_TEXT_UO_ORIGIN 1
@d OPTIONS_FILE_UO_ORIGIN 2
@d EXTENSION_UO_ORIGIN 3

=
void UseOptions::index(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("The following use options are in force:"); HTML_CLOSE("p");
	UseOptions::index_options_in_force_from(OUT, MAIN_TEXT_UO_ORIGIN, NULL);
	UseOptions::index_options_in_force_from(OUT, OPTIONS_FILE_UO_ORIGIN, NULL);
	extension_file *ef;
	LOOP_OVER(ef, extension_file) UseOptions::index_options_in_force_from(OUT, EXTENSION_UO_ORIGIN, ef);
	int nt = 0;
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if ((uo->option_used == FALSE) && (uo->minimum_setting_value < 0)) nt++;
	}
	if (nt > 0) {
		HTML_OPEN("p"); WRITE("Whereas these are not in force:"); HTML_CLOSE("p");
		HTMLFiles::open_para(OUT, 2, "tight");
		LOOP_OVER(uo, use_option) {
			if (uo->source_file_scoped) continue;
			if ((uo->option_used == FALSE) && (uo->minimum_setting_value < 0)) {
				@<Write in the index line for a use option not taken@>;
				if (--nt > 0) WRITE(", ");
			}
		}
		HTML_CLOSE("p");
	}
}

@<Write in the index line for a use option not taken@> =
	HTML_OPEN_WITH("span", "style=\"white-space:nowrap\";");
	TEMPORARY_TEXT(TEMP);
	WRITE_TO(TEMP, "Use %+W.", uo->name);
	HTML::Javascript::paste_stream(OUT, TEMP);
	DISCARD_TEXT(TEMP);
	WRITE("&nbsp;%+W", uo->name);
	HTML_CLOSE("span");

@ =
void UseOptions::index_options_in_force_from(OUTPUT_STREAM, int category, extension_file *ef) {
	int N = 0;
	use_option *uo;
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if ((uo->option_used) && (uo->minimum_setting_value < 0) &&
			(UseOptions::uo_set_from(uo, category, ef))) {
			if (N++ == 0) @<Write in the use option subheading@>;
			@<Write in the index line for a use option taken@>;
		}
	}
	LOOP_OVER(uo, use_option) {
		if (uo->source_file_scoped) continue;
		if (((uo->option_used) && (uo->minimum_setting_value >= 0)) &&
			(UseOptions::uo_set_from(uo, category, ef))) {
			if (N++ == 0) @<Write in the use option subheading@>;
			@<Write in the index line for a use option taken@>;
		}
	}
}

@<Write in the use option subheading@> =
	HTMLFiles::open_para(OUT, 2, "tight");
	HTML::begin_colour(OUT, I"808080");
	WRITE("Set from ");
	switch (category) {
		case MAIN_TEXT_UO_ORIGIN:
			WRITE("the source text"); break;
		case OPTIONS_FILE_UO_ORIGIN:
			WRITE("the Options.txt configuration file");
			Index::DocReferences::link(OUT, I"OPTIONSFILE"); break;
		case EXTENSION_UO_ORIGIN:
			if (ef == standard_rules_extension) WRITE("the ");
			else WRITE("the extension ");
			WRITE("%+W", ef->title_text);
			break;
	}
	WRITE(":");
	HTML::end_colour(OUT);
	HTML_CLOSE("p");

@<Write in the index line for a use option taken@> =
	HTMLFiles::open_para(OUT, 3, "tight");
	WRITE("Use %+W", uo->name);
	if (uo->minimum_setting_value >= 0) WRITE(" of at least %d", uo->minimum_setting_value);
	if (uo->where_used) Index::link(OUT, Wordings::first_wn(ParseTree::get_text(uo->where_used)));
	if (uo->minimum_setting_value >= 0) {
		WRITE("&nbsp;");
		TEMPORARY_TEXT(TEMP);
		WRITE_TO(TEMP, "Use %+W of at least %d.", uo->name, 2*(uo->minimum_setting_value));
		HTML::Javascript::paste_stream(OUT, TEMP);
		DISCARD_TEXT(TEMP);
		WRITE("&nbsp;<i>Double this</i>");
	}
	HTML_CLOSE("p");

@ A relatively late addition to the design of use options was to make them
values at run-time, of the kind "use option". We need to provide two routines:
one to test them, one to print them.

=
void UseOptions::TestUseOption_routine(void) {
	Emit::named_numeric_constant(InterNames::iname(NO_USE_OPTIONS_INAME), (inter_t) NUMBER_CREATED(use_option));
	@<Compile the TestUseOption routine@>;
	@<Compile the PrintUseOption routine@>;
}

@<Compile the TestUseOption routine@> =
	package_request *R = Kinds::RunTime::package(K_use_option);
	inter_name *iname =
		Packaging::function(
			InterNames::one_off(I"test_fn", R),
			R,
			InterNames::iname(TestUseOption_INAME));
	packaging_state save = Routines::begin(iname);
	inter_symbol *UO_s = LocalVariables::add_named_call_as_symbol(I"UO");
	use_option *uo;
	LOOP_OVER(uo, use_option)
		if ((uo->option_used) || (uo->minimum_setting_value >= 0)) {
			Emit::inv_primitive(if_interp);
			Emit::down();
				Emit::inv_primitive(eq_interp);
				Emit::down();
					Emit::val_symbol(K_value, UO_s);
					Emit::val(K_number, LITERAL_IVAL, (inter_t) uo->allocation_id);
				Emit::up();
				Emit::code();
				Emit::down();
					Emit::rtrue();
				Emit::up();
			Emit::up();
		}
	Emit::rfalse();
	Routines::end(save);

@<Compile the PrintUseOption routine@> =
	inter_name *iname = Kinds::Behaviour::get_iname(K_use_option);
	packaging_state save = Routines::begin(iname);
	inter_symbol *UO_s = LocalVariables::add_named_call_as_symbol(I"UO");
	Emit::inv_primitive(switch_interp);
	Emit::down();
		Emit::val_symbol(K_value, UO_s);
		Emit::code();
		Emit::down();
			use_option *uo;
			LOOP_OVER(uo, use_option) {
				Emit::inv_primitive(case_interp);
				Emit::down();
					Emit::val(K_number, LITERAL_IVAL, (inter_t) uo->allocation_id);
					Emit::code();
					Emit::down();
						Emit::inv_primitive(print_interp);
						Emit::down();
							TEMPORARY_TEXT(N);
							WRITE_TO(N, "%W option", uo->name);
							if (uo->minimum_setting_value > 0)
								WRITE_TO(N, " [%d]", uo->minimum_setting_value);
							Emit::val_text(N);
							DISCARD_TEXT(N);
						Emit::up();
					Emit::up();
				Emit::up();
			}
		Emit::up();
	Emit::up();
	Routines::end(save);
