[NaturalLanguages::] Natural Languages.

To manage definitions of natural languages, such as English or
French, which may be used either to write Inform or to read the works it
compiles.

@h Definitions.

@ Inform can read and write text in multiple natural languages, though it
needs help to do so. Each natural language known to Inform comes from a
small resource folder called its "bundle", and also has an extension
associated with it: this includes English. Bundles for common languages
are included as part of the default distribution for Inform, but the
extension is only included for English.

@ Within the bundle folder is a file called |about.txt|, which sets numbered
fields to excerpts of text. The following are the field numbers:

@d NAME_IN_ENGLISH_LFIELD 1		/* e.g. "German" */
@d NAME_NATIVE_LFIELD 2			/* e.g. "Deutsch" */
@d CUE_NATIVE_LFIELD 3			/* e.g. "in deutscher Sprache" */
@d ISO_639_CODE_LFIELD 4		/* e.g. "de": an ISO 639-1 code */
@d TRANSLATOR_LFIELD 5			/* e.g. "Team GerX" */
@d MAX_LANGUAGE_FIELDS 6		/* one more than the highest number above */

@ Each natural language whose bundle can be located generates an instance
of the following structure.

Note that each NL automatically defines an instance of the kind "natural
language". For timing reasons, we first store the name of this instance --
say, "German language" -- and only later create the instance.

=
typedef struct natural_language {
	struct pathname *nl_bundle_path; /* pathname of the bundle folder */
	struct wording instance_name; /* instance name, e.g., "German language" */
	struct instance *nl_instance; /* instance, e.g., "German language" */
	struct wording language_field[MAX_LANGUAGE_FIELDS]; /* contents of the |about.txt| fields */
	int extension_required; /* do we need to Include the extension for this language? */
	int adaptive_person; /* which person (one of constants below) text subs are written from */
	MEMORY_MANAGEMENT
} natural_language;

@ The following defaults to English in practice:

=
natural_language *language_of_play = NULL; /* the language read and typed by the player */

@

@d NATURAL_LANGUAGES_PRESENT

@h The bundle scan.
Early in Inform's run we scan for installed language bundle folders. This is
done on demand (i.e., when we need to know something about languages). We
only want to do it once, and we must prevent it recursing:

=
int bundle_scan_made = FALSE;

void NaturalLanguages::scan(void) {
	if (bundle_scan_made == FALSE) {
		bundle_scan_made = TRUE;
		@<Perform the bundle scan@>;
		@<Process the bundles scanned in@>;
	}
}

@ The rules for these are exactly the same as for extensions, or website
templates, so for example the materials folder takes priority. If we find
a bundle with the same name twice (e.g., if we find "German" in two
different locations), the first to be found wins out.

@<Perform the bundle scan@> =
	for (int area=0; area<NO_FS_AREAS; area++)
		NaturalLanguages::scan_bundles_from(pathname_of_languages[area], AREA_NAME[area]);

@ The following rather crudely loads a directory listing for the pathname
into a scratch string, then cuts it up into individual names.

=
void NaturalLanguages::scan_bundles_from(pathname *P, char *origin) {
	scan_directory *sd = Directories::open(P);
	if (sd == NULL) return;

	TEMPORARY_TEXT(item);
	while (Directories::next(sd, item))
		@<Act on an item in the bundle listing@>;
	DISCARD_TEXT(item);

	Directories::close(sd);
}

@ We expect each such folder to contain only names of bundles, each of which
should be a single English word, without accents.

@<Act on an item in the bundle listing@> =
	int acceptable = TRUE;
	LOOP_THROUGH_TEXT(pos, item) {
		int c = Str::get(pos);
		if ((c < 32) || (c > 126)) acceptable = FALSE; /* contains non-ASCII */
		if (c == FOLDER_SEPARATOR) { Str::put(pos, 0); break; }
	}
	if (Str::len(item) == 0) acceptable = FALSE; /* i.e., an empty text */
	if (acceptable) {
		natural_language *nl = NaturalLanguages::get_nl(item);
		if (nl == NULL) @<Create a new natural language structure@>;
		nl->nl_bundle_path = Pathnames::subfolder(P, item);
		LOG("Found language bundle '%S' (%s)\n", item, origin);
	}

@<Create a new natural language structure@> =
	nl = CREATE(natural_language);

	TEMPORARY_TEXT(sentence_format);
	WRITE_TO(sentence_format, "%S language", item);
	nl->instance_name = Feeds::feed_stream(sentence_format);
	DISCARD_TEXT(sentence_format);
	nl->nl_instance = NULL;
	nl->extension_required = FALSE;
	nl->adaptive_person = -1; /* i.e., none yet specified */

	for (int n=0; n<MAX_LANGUAGE_FIELDS; n++) nl->language_field[n] = EMPTY_WORDING;

@ At this point, the bundle scan is over. For each bundle we've found, we
read in the |about.txt| file and extract the excerpts.

@<Process the bundles scanned in@> =
	natural_language *nl;
	LOOP_OVER(nl, natural_language)
		@<Read the about.txt file for the bundle@>;

@ If we can't find the file, it doesn't matter except that all of the excerpts
remain empty. But we may as well tell the debugging log.

@d MAX_BUNDLE_ABOUT_LINE_LENGTH 256  /* which is far more than necessary, really */

@<Read the about.txt file for the bundle@> =
	filename *about_file = Filenames::in_folder(nl->nl_bundle_path, I"about.txt");

	if (TextFiles::read(about_file, FALSE,
		NULL, FALSE, NaturalLanguages::about_helper, NULL, nl) == FALSE)
		LOG("Can't find about file: %f\n", about_file);

@ The format of the file is very simple. Each line is introduced by a number
from 1 to |MAX_LANGUAGE_FIELDS| minus one, and then contains text which
extends for the rest of the line.

=
void NaturalLanguages::about_helper(text_stream *item_name,
	text_file_position *tfp, void *vnl) {
	natural_language *nl = (natural_language *) vnl;
	wording W = Feeds::feed_stream(item_name);
	if (Wordings::nonempty(W)) {
		vocabulary_entry *ve = Lexer::word(Wordings::first_wn(W));
		int field = -1;
		if ((ve) && (Vocabulary::test_vflags(ve, NUMBER_MC)))
			field = Vocabulary::get_literal_number_value(ve);
		if ((field >= 1) && (field < MAX_LANGUAGE_FIELDS)) {
			nl->language_field[field] =
				Wordings::new(Wordings::first_wn(W)+1, Wordings::last_wn(W));
		} else LOG("Warning: couldn't read about.txt line: %S\n", item_name);
	}
}

@h Finding by name.
Given the name of a natural language (e.g., "German") we find the
corresponding structure, if it exists. We perform this check case
insensitively.

=
natural_language *NaturalLanguages::get_nl(text_stream *name) {
	NaturalLanguages::scan();
	natural_language *nl;
	LOOP_OVER(nl, natural_language) {
		TEMPORARY_TEXT(lname);
		WRITE_TO(lname, "%W", Wordings::one_word(Wordings::first_wn(nl->instance_name)));
		if (Str::eq_insensitive(name, lname)) return nl;
		DISCARD_TEXT(lname);
	}
	return NULL;
}

@h Logging.

=
void NaturalLanguages::log(natural_language *nl) {
	if (nl == NULL) { LOG("<null-language>"); }
	else { LOG("%+W", NaturalLanguages::get_name(nl)); }
}

@h Naming.

=
wording NaturalLanguages::get_name(natural_language *nl) {
	if (nl == NULL) nl = English_language;
	return Wordings::one_word(Wordings::first_wn(nl->instance_name));
}

@h Parsing.
The following matches the English-language name of a language: for example,
"French". It will only make a match if Inform has successfully found a
bundle for that language during its initial scan.

=
<natural-language> internal {
	natural_language *nl;
	LOOP_OVER(nl, natural_language)
		if (Wordings::match(W, Wordings::first_word(nl->instance_name))) {
			*XP = nl; return TRUE;
		}
	return FALSE;
}

@h The natural language kind.
Inform has a kind built in called "natural language", whose values are
enumerated names: English language, French language, German language and so on.
When the kind is created, the following routine makes these instances. We do
this exactly as we would to create any other instance -- we write a logical
proposition claiming its existence, then assert this to be true. It's an
interesting question whether the possibility of the game having been written
in German "belongs" in the model world, if in fact the game wasn't written
in German; but this is how we'll do it, anyway.

=
void NaturalLanguages::stock_nl_kind(kind *K) {
	natural_language *nl;
	LOOP_OVER(nl, natural_language) {
		pcalc_prop *prop =
			Calculus::Propositions::Abstract::to_create_something(K, nl->instance_name);
		Calculus::Propositions::Assert::assert_true(prop, CERTAIN_CE);
		nl->nl_instance = latest_instance;
	}
}

@h The adaptive person.
The following is only relevant for the language of play, whose extension will
always be read in. That in turn is expected to contain a declaration like
this one:

>> The adaptive text viewpoint of the French language is second person singular.

The following routine picks up on the result of this declaration. (We cache
this because we need access to it very quickly when parsing text substitutions.)

=
int NaturalLanguages::adaptive_person(natural_language *nl) {
	#ifdef IF_MODULE
	if ((nl->adaptive_person == -1) && (P_adaptive_text_viewpoint)) {
		instance *I = nl->nl_instance;
		parse_node *spec = World::Inferences::get_prop_state(
			Instances::as_subject(I), P_adaptive_text_viewpoint);
		if (ParseTree::is(spec, CONSTANT_NT)) {
			instance *V = ParseTree::get_constant_instance(spec);
			nl->adaptive_person = Instances::get_numerical_value(V)-1;
		}
	}
	#endif

	if (nl->adaptive_person == -1) return FIRST_PERSON_PLURAL;
	return nl->adaptive_person;
}

@h Choice of languages.

=
natural_language *NaturalLanguages::English(void) {
	natural_language *nl = NaturalLanguages::get_nl(I"english");
	if (nl == NULL) internal_error("unable to find English language bundle");
	nl->extension_required = TRUE;
	English_language = nl;
	return nl;
}

void NaturalLanguages::set_language_of_play(natural_language *nl) {
	language_of_play = nl;
	if (nl) nl->extension_required = TRUE;
}

@h Language code.
This is used when we write the bibliographic data for the work of IF we're
making; this enables online databases like IFDB, and smart interpreters, to
detect the language of play for a story file without actually running it.

=
void NaturalLanguages::write_language_code(OUTPUT_STREAM, natural_language *nl) {
	if (nl == NULL) nl = English_language;
	if (Wordings::nonempty(nl->language_field[ISO_639_CODE_LFIELD]))
		WRITE("%+W", nl->language_field[ISO_639_CODE_LFIELD]);
	else WRITE("en");
}

@h Including language extensions.
Most extensions are included with explicit Inform source text:

>> Include Locksmith by Emily Short.

But the Standard Rules are an exception -- they're always included -- and so
are the languages used in the source text and for play. Note that French
games, say, involve loading two language extensions: English Language, because
that's the language in which the SR are written, and French Language, because
that's the language of play.

=
void NaturalLanguages::include_required(void) {
	natural_language *nl;
	feed_t id = Feeds::begin();
	int icount = 0;
	LOOP_OVER(nl, natural_language)
		if (nl->extension_required) {
			TEMPORARY_TEXT(TEMP);
			if (icount++ > 0) WRITE_TO(TEMP, ". ");
			WRITE_TO(TEMP, "Include %+W Language by ", NaturalLanguages::get_name(nl));
			if (Wordings::nonempty(nl->language_field[TRANSLATOR_LFIELD]))
				WRITE_TO(TEMP, "%+W", nl->language_field[TRANSLATOR_LFIELD]);
			else WRITE_TO(TEMP, "Unknown Translator");
			Feeds::feed_stream(TEMP);
			DISCARD_TEXT(TEMP);
		}
	ParseTree::set_attachment_point_one_off(language_extension_inclusion_point);
	wording W = Feeds::end(id);
	Sentences::break(W, NULL);
	ParseTree::set_attachment_point_one_off(NULL);
}

@h Including Preform syntax.
At present we do this only for English, but some day...

=
wording NaturalLanguages::load_preform(natural_language *nl) {
	if (nl == NULL) internal_error("can't load preform from null language");
	language_being_read_by_Preform = nl;
	filename *preform_file = Filenames::in_folder(nl->nl_bundle_path, I"Syntax.preform");
	LOG("Reading language definition from <%f>\n", preform_file);
	return Preform::load_from_file(preform_file);
}

@h Preform error handling.

=
void NaturalLanguages::preform_error(word_assemblage base_text, nonterminal *nt,
	production *pr, char *message) {
	if (pr) {
		LOG("The production at fault is:\n");
		Preform::log_production(pr, FALSE); LOG("\n");
	}
	if (nt == NULL)
		Problems::quote_text(1, "(no nonterminal)");
	else
		Problems::quote_wide_text(1, Vocabulary::get_exemplar(nt->nonterminal_id, FALSE));
	Problems::quote_text(2, message);
	Problems::Issue::handmade_problem(_p_(Untestable));
	if (WordAssemblages::nonempty(base_text)) {
		Problems::quote_wa(5, &base_text);
		Problems::issue_problem_segment(
			"I'm having difficulties conjugating the verb '%5'. ");
	}

	TEMPORARY_TEXT(TEMP);
	if (pr) {
		Problems::quote_number(3, &(pr->match_number));
		ptoken *pt;
		for (pt = pr->first_ptoken; pt; pt = pt->next_ptoken) {
			Preform::write_ptoken(TEMP, pt);
			if (pt->next_ptoken) WRITE_TO(TEMP, " ");
		}
		Problems::quote_stream(4, TEMP);
		Problems::issue_problem_segment(
			"There's a problem in Inform's linguistic grammar, which is probably "
			"set by a translation extension. The problem occurs in line %3 of "
			"%1 ('%4'): %2.");
	} else {
		Problems::issue_problem_segment(
			"There's a problem in Inform's linguistic grammar, which is probably "
			"set by a translation extension. The problem occurs in the definition of "
			"%1: %2.");
	}
	Problems::issue_problem_end();
	DISCARD_TEXT(TEMP);
}

