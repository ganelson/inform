[Extensions::Files::] Extension Files.

To keep details of the extensions currently loaded, their authors,
titles, versions and rubrics, and to index and credit them suitably.

@h Definitions.

@ Extensions are files of source text, normally combined with an appendix
of documentation, provided by third parties for users to include with the
source text of their own projects. Extensions are intended to provide general
solutions to typical needs, and an archive of extensions for download is
provided by the Inform website: those are licenced by their authors with
a Creative Commons Attribution licence, and because of that, Inform behaves
as if all extensions it sees require attribution (unless the author requests
anonymity). A user of Inform 7 will certainly have nine or ten extensions
available to him, because that many are built into the standard distribution:
as of 2007 it is typical for users to have installed 50 to 90 others, and
the total is steadily rising. Our routines here therefore need to be
scalable.

Extensions are stored in two places: a built-in area, inside the Inform 7
application, and an external area. Inform knows the location of the former
because the application passes this as |-rules| on the command line, and it
knows the location of the latter because this is standard and fixed for
each platform: see Platform-Specific Definitions.

@h How the application should install extensions.
When the Inform 7 application looks at a file chosen by the user to
be installed, it should look at the first line. (Note that this might have
any of |0a|, |0d|, |0a0d|, |0d0a|, or Unicode line division as its line
ending: and that the file might, or might not, begin with a Unicode BOM,
"byte order marker", code. Characters within the line will be encoded as
UTF-8, though -- except possibly for some exotic forms of space -- they
will all be found in the ISO Latin-1 set.) The first line is required to
have one of the following forms, possibly with white space before or after,
but definitely without line breaks before:

>> Locksmith Extra by Emily Short begins here.

>> Version 2 of Locksmith Extra by Emily Short begins here.

>> Version 060430 of Locksmith Extra by Emily Short begins here.

>> Version 2/060430 of Locksmith Extra by Emily Short begins here.

If the name of the extension finishes with a bracketed clause, that
should be disregarded. Such clauses are used to specify virtual machine
requirements, at present, and could conceivably be used for other purposes
later, so let's reserve them now.

>> Version 2 of Glulx Text Effects (for Glulx only) by Emily Short begins here.

The application should reject (that is, politely refuse to install) any
purported extension file whose first line does not conform to the above.

Ignoring any version number given, the Inform application should then
store the file in the external extensions area. For instance,

	|~/Library/Inform/Extensions/Emily Short/Glulx Text Effects| (OS X)
	|My Documents\Inform\Extensions\Emily Short\Glulx Text Effects| (Windows)

Note that the file will probably not have the right name initially, and
will need to be renamed as well as moved. (Note the lack of a file
extension.) The subfolders |Inform|, |Extensions| and |Emily Short| must be
created if not already present.

If to install such an extension would result in over-writing an extension
already present at that filename, the user should be given a warning and
asked if he wants to proceed.

However, note that it is not an error to install an extension with
the same name and author as one in the built-in extensions folder. This
does not result in overwriting, since the newly installed version will live
in the external area, not the built-in area.

An extension may be uninstalled simply by deleting the file: but the
application must not allow the user to uninstall any extension from
the built-in area. We must assume that the latter could be on a read-only
disc, or could be part of a cryptographically signed application bundle.

@h The extension census.
The Inform application should run Inform in "census mode" in order to
keep extension documentation up to date. Inform should be run in census mode
on three occasions:

(a) when the Inform application starts up;
(b) when the Inform application installs a new extension;
(c) when the Inform application uninstalls an extension.

When |inform7| is run in "census mode", it should be run with the command |-census|.
All output from Inform should be ignored, including its return code: ideally,
not even a fatal error should provoke a reaction from the application. If the
census doesn't work for some file-system reason, never mind -- it's not
mission-critical.

@h What happens in census mode.
The census has two purposes: first, to create provisional documentation
where needed for new and unused extensions; and second, to create the
following index files in the external documentation area (not in
the external extension area):
= (text)
	.../Extensions.html
	.../ExtIndex.html
=
Documentation for any individual extension is stored at, e.g.,
= (text)
	.../Extensions/Victoria Saxe-Coburg-Gotha/Werewolves.html
=
Inform can generate such a file, for an individual extension, in two ways: (a)
provisionally, with much less detail, and (b) fully. Whenever it
successfully compiles a work using extension X, it rewrites the
documentation for X fully, and updates both the two indexing pages.

When Inform runs in |-census| mode, what it does is to scan for all extensions.
If Inform finds a valid extension with no documentation page, it writes a
provisional one; and again, it updates both the two indexing pages.

(Inform in fact runs a census on every compilation, as well, so |-census| runs
do nothing "extra" that a normal run of Inform does not also do. On every
census, Inform automatically checks for misfiled or broken extensions, and
places a descriptive report of what's wrong on the |Extensions.html| index
page -- if people move around or edit extensions by hand, they may run into
these errors.)

@ With that general discussion out of the way, we can get on with
implementation. A modest structure is used to store details of extension
files loaded into Inform: or rather, to store requests to include them, and then
to keep track of the results.

The rubric of an extension is text found near its opening, describing
its purpose.

=

@ We begin with some housekeeping, really: the code required to create new
extension file structures, and to manage existing ones.

=

@h Checking version numbers.
It's only at the end of semantic analysis, when all extensions have been
loaded, that we check that all the version numbers are sufficient to meet
the requests made. The reason we don't do this one at a time, as we load
them in, is that we might load E at a time when version $V$ is required,
and find that it matches; but then an extension loaded later might turn out
to require E version $V+1$. So it is only when all extensions have been
loaded that we know the full set of requirements, and only then do we
check that they have been met.

=
void Extensions::Files::check_versions(void) {
	inform_extension *E;
	LOOP_OVER(E, inform_extension) {
		if (Extensions::satisfies(E) == FALSE) {
			semantic_version_number have = E->as_copy->edition->version;
			current_sentence = Extensions::get_inclusion_sentence(E);
			Problems::quote_source(1, current_sentence);
			Problems::quote_extension(2, E);
			if (VersionNumbers::is_null(have) == FALSE) {
				TEMPORARY_TEXT(vn);
				VersionNumbers::to_text(vn, have);
				Problems::quote_stream(3, vn);
				Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
				Problems::issue_problem_segment(
					"You wrote %1: but my copy of %2 is only version %3.");
				Problems::issue_problem_end();
				DISCARD_TEXT(vn);
			} else {
				Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(BelievedImpossible));
				Problems::issue_problem_segment(
					"You wrote %1: but my copy of %2 contains no version "
					"number, and is therefore considered to be earlier than "
					"all numbered versions.");
				Problems::issue_problem_end();
			}
		}
	}
}

@h Credit for extensions.
Here we compile an I6 routine to print out credits for all the extensions
present in the compiled work. This is important because the extensions
published at the Inform website are available under a Creative Commons
license which requires users to give credit to the authors: Inform
ensures that this happens automatically.

Use of authorial modesty (see above) will suppress a credit in the
|ShowExtensionVersions| routine, but the system is set up so that one can
only be modest about one's own extensions: this would otherwise violate a
CC license of somebody else. General authorial modesty thus suppresses
credits for all extensions used which are by the user himself. On the
other hand, if an extension contains an authorial modesty disclaimer
in its own text, then that must have been the wish of its author, so
we can suppress the credit whoever that author was.

In |I7FullExtensionVersions| all extensions are credited whatever anyone's
feelings of modesty.

=
void Extensions::Files::ShowExtensionVersions_routine(void) {
	inter_name *iname = Hierarchy::find(SHOWEXTENSIONVERSIONS_HL);
	packaging_state save = Routines::begin(iname);
	inform_extension *E;
	LOOP_OVER(E, inform_extension) {
		TEMPORARY_TEXT(the_author_name);
		WRITE_TO(the_author_name, "%S", E->as_copy->edition->work->author_name);
		int self_penned = FALSE;
		#ifdef IF_MODULE
		if (PL::Bibliographic::story_author_is(the_author_name)) self_penned = TRUE;
		#endif
		if (((E == NULL) || (E->authorial_modesty == FALSE)) && /* if (1) extension doesn't ask to be modest */
			((general_authorial_modesty == FALSE) || /* and (2) author doesn't ask to be modest, or... */
			(self_penned == FALSE))) { /* ...didn't write this extension */
				TEMPORARY_TEXT(C);
				Extensions::Files::credit_ef(C, E, TRUE); /* then we award a credit */
				Produce::inv_primitive(Emit::tree(), PRINT_BIP);
				Produce::down(Emit::tree());
					Produce::val_text(Emit::tree(), C);
				Produce::up(Emit::tree());
				DISCARD_TEXT(C);
			}
		DISCARD_TEXT(the_author_name);
	}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);

	iname = Hierarchy::find(SHOWFULLEXTENSIONVERSIONS_HL);
	save = Routines::begin(iname);
	LOOP_OVER(E, inform_extension) {
		TEMPORARY_TEXT(C);
		Extensions::Files::credit_ef(C, E, TRUE);
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), C);
		Produce::up(Emit::tree());
		DISCARD_TEXT(C);
	}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
	
	iname = Hierarchy::find(SHOWONEEXTENSION_HL);
	save = Routines::begin(iname);
	inter_symbol *id_s = LocalVariables::add_named_call_as_symbol(I"id");
	LOOP_OVER(E, inform_extension) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, id_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (E->allocation_id + 1));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				TEMPORARY_TEXT(C);
				Extensions::Files::credit_ef(C, E, FALSE);
				Produce::inv_primitive(Emit::tree(), PRINT_BIP);
				Produce::down(Emit::tree());
					Produce::val_text(Emit::tree(), C);
				Produce::up(Emit::tree());
				DISCARD_TEXT(C);
			Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}
	Routines::end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

@ The actual credit consists of a single line, with name, version number
and author. These are printed as I6 strings, hence the ISO encoding.

=
void Extensions::Files::credit_ef(OUTPUT_STREAM, inform_extension *E, int with_newline) {
	if (E == NULL) internal_error("unfound ef");
	WRITE("%S", E->as_copy->edition->work->raw_title);
	semantic_version_number V = E->as_copy->edition->version;
	if (VersionNumbers::is_null(V) == FALSE) WRITE(" version %v", &V);
	WRITE(" by %S", E->as_copy->edition->work->raw_author_name);
	if (Str::len(E->extra_credit_as_lexed) > 0) WRITE(" (%S)", E->extra_credit_as_lexed);
	if (with_newline) WRITE("\n");
}

@h Indexing extensions in the Contents index.
The routine below places a list of extensions used in the Contents index,
giving only minimal entries about them.

=
void Extensions::Files::index(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("EXTENSIONS"); HTML_CLOSE("p");
	Extensions::Files::index_extensions_from(OUT, NULL);
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Extensions::is_standard(E) == FALSE)
			Extensions::Files::index_extensions_from(OUT, E);
	LOOP_OVER(E, inform_extension)
		if (Extensions::is_standard(E))
			Extensions::Files::index_extensions_from(OUT, E);
	HTML_OPEN("p"); HTML_CLOSE("p");
}

void Extensions::Files::index_extensions_from(OUTPUT_STREAM, inform_extension *from) {
	int show_head = TRUE;
	inform_extension *E;
	LOOP_OVER(E, inform_extension) {
		inform_extension *owner = NULL;
		parse_node *N = Extensions::get_inclusion_sentence(from);
		if (Wordings::nonempty(ParseTree::get_text(N))) {
			source_location sl = Wordings::location(ParseTree::get_text(N));
			if (sl.file_of_origin == NULL) owner = NULL;
			else owner = Extensions::corresponding_to(
				Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(N))));
		}
		if (owner != from) continue;
		if (show_head) {
			HTMLFiles::open_para(OUT, 2, "hanging");
			HTML::begin_colour(OUT, I"808080");
			WRITE("Included ");
			if (Extensions::is_standard(from)) WRITE("automatically by Inform");
			else if (from == NULL) WRITE("from the source text");
			else {
				WRITE("by the extension %S", from->as_copy->edition->work->title);
			}
			show_head = FALSE;
			HTML::end_colour(OUT);
			HTML_CLOSE("p");
		}
		HTML_OPEN_WITH("ul", "class=\"leaders\"");
		HTML_OPEN_WITH("li", "class=\"leaded indent2\"");
		HTML_OPEN("span");
		WRITE("%S ", E->as_copy->edition->work->title);
		Works::begin_extension_link(OUT, E->as_copy->edition->work, NULL);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/help.png");
		Works::end_extension_link(OUT, E->as_copy->edition->work);
		if (Extensions::is_standard(E) == FALSE) { /* give author and inclusion links, but not for SR */
			WRITE(" by %X", E->as_copy->edition->work->author_name);
		}
		if (VersionNumbers::is_null(E->as_copy->edition->version) == FALSE) {
			WRITE(" ");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			semantic_version_number V = E->as_copy->edition->version;
			WRITE("version %v", &V);
			HTML_CLOSE("span");
		}
		if (Str::len(E->extra_credit_as_lexed) > 0) {
			WRITE(" ");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			WRITE("(%S)", E->extra_credit_as_lexed);
			HTML_CLOSE("span");
		}
		HTML_CLOSE("span");
		HTML_OPEN("span");
		WRITE("%d words", TextFromFiles::total_word_count(E->read_into_file));
		if (from == NULL) Index::link(OUT, Wordings::first_wn(ParseTree::get_text(Extensions::get_inclusion_sentence(E))));
		HTML_CLOSE("span");
		HTML_CLOSE("li");
		HTML_CLOSE("ul");
		WRITE("\n");
	}
}

@ Nothing can prevent a certain repetitiousness intruding here, but there is
just enough local knowledge required to make it foolhardy to try to automate
this from a dump of the excerpt meanings table (say). The ordering of
paragraphs, as in Roget's Thesaurus, tries to proceed from solid things
through to diffuse linguistic ones. But the reader of the resulting
documentation page could be forgiven for thinking it a miscellany.

=
void Extensions::Files::document_in_detail(OUTPUT_STREAM, inform_extension *E) {
	Extensions::Dictionary::erase_entries(E);
	if (E) Extensions::Dictionary::time_stamp(E);

	@<Document and dictionary the kinds made in extension@>;
	@<Document and dictionary the objects made in extension@>;

	@<Document and dictionary the global variables made in extension@>;
	@<Document and dictionary the enumerated constant values made in extension@>;

	@<Document and dictionary the kinds of action made in extension@>;
	@<Document and dictionary the actions made in extension@>;

	@<Document and dictionary the verbs made in extension@>;
	@<Document and dictionary the adjectival phrases made in extension@>;
	@<Document and dictionary the property names made in extension@>;

	@<Document and dictionary the use options made in extension@>;
}

@ Off we go, then. Kinds of object:

@<Document and dictionary the kinds made in extension@> =
	kind *K;
	int kc = 0;
	LOOP_OVER_BASE_KINDS(K) {
		parse_node *S = Kinds::Behaviour::get_creating_sentence(K);
		if (S) {
			if (Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(S))) == E->read_into_file) {
				wording W = Kinds::Behaviour::get_name(K, FALSE);
				kc = Extensions::Files::document_headword(OUT, kc, E, "Kinds", I"kind", W);
				kind *S = Kinds::Compare::super(K);
				if (S) {
					W = Kinds::Behaviour::get_name(S, FALSE);
					if (Wordings::nonempty(W)) WRITE(" (a kind of %+W)", W);
				}
			}
		}
	}
	if (kc != 0) HTML_CLOSE("p");

@ Actual objects:

@<Document and dictionary the objects made in extension@> =
	instance *I;
	int kc = 0;
	LOOP_OVER_OBJECT_INSTANCES(I) {
		wording OW = Instances::get_name(I, FALSE);
		if ((Instances::get_creating_sentence(I)) && (Wordings::nonempty(OW))) {
			if (Lexer::file_of_origin(
				Wordings::first_wn(ParseTree::get_text(Instances::get_creating_sentence(I))))
					== E->read_into_file) {
				TEMPORARY_TEXT(name_of_its_kind);
				kind *k = Instances::to_kind(I);
				wording W = Kinds::Behaviour::get_name(k, FALSE);
				WRITE_TO(name_of_its_kind, "%+W", W);
				kc = Extensions::Files::document_headword(OUT, kc, E,
					"Physical creations", name_of_its_kind, OW);
				WRITE(" (a %S)", name_of_its_kind);
				DISCARD_TEXT(name_of_its_kind);
			}
		}
	}
	if (kc != 0) HTML_CLOSE("p");

@ Global variables:

@<Document and dictionary the global variables made in extension@> =
	nonlocal_variable *q;
	int kc = 0;
	LOOP_OVER(q, nonlocal_variable)
		if ((Wordings::first_wn(q->name) >= 0) &&
			(NonlocalVariables::is_global(q)) &&
			(Lexer::file_of_origin(Wordings::first_wn(q->name)) == E->read_into_file) &&
			(Headings::indexed(Headings::of_wording(q->name)))) {
			if (<value-understood-variable-name>(q->name) == FALSE)
				kc = Extensions::Files::document_headword(OUT,
					kc, E, "Values that vary", I"value", q->name);
		}
	if (kc != 0) HTML_CLOSE("p");

@ Constants:

@<Document and dictionary the enumerated constant values made in extension@> =
	instance *q;
	int kc = 0;
	LOOP_OVER_ENUMERATION_INSTANCES(q) {
		wording NW = Instances::get_name(q, FALSE);
		if ((Wordings::nonempty(NW)) && (Lexer::file_of_origin(Wordings::first_wn(NW)) == E->read_into_file))
			kc = Extensions::Files::document_headword(OUT, kc, E, "Values", I"value", NW);
	}
	if (kc != 0) HTML_CLOSE("p");

@ Kinds of action:

@<Document and dictionary the kinds of action made in extension@> =
	#ifdef IF_MODULE
	PL::Actions::Patterns::Named::index_for_extension(OUT, E->read_into_file, E);
	#endif

@ Actions:

@<Document and dictionary the actions made in extension@> =
	#ifdef IF_MODULE
	PL::Actions::Index::index_for_extension(OUT, E->read_into_file, E);
	#endif

@ Verbs (this one we delegate):

@<Document and dictionary the verbs made in extension@> =
	Index::Lexicon::list_verbs_in_file(OUT, E->read_into_file, E);

@ Adjectival phrases:

@<Document and dictionary the adjectival phrases made in extension@> =
	adjectival_phrase *adj;
	int kc = 0;
	LOOP_OVER(adj, adjectival_phrase) {
		wording W = Adjectives::get_text(adj, FALSE);
		if ((Wordings::nonempty(W)) &&
			(Lexer::file_of_origin(Wordings::first_wn(W)) == E->read_into_file))
			kc = Extensions::Files::document_headword(OUT, kc, E, "Adjectives", I"adjective", W);
	}
	if (kc != 0) HTML_CLOSE("p");

@ Other adjectives:

@<Document and dictionary the property names made in extension@> =
	property *prn;
	int kc = 0;
	LOOP_OVER(prn, property)
		if ((Wordings::nonempty(prn->name)) &&
			(Properties::is_shown_in_index(prn)) &&
			(Lexer::file_of_origin(Wordings::first_wn(prn->name)) == E->read_into_file))
			kc = Extensions::Files::document_headword(OUT, kc, E, "Properties", I"property",
				prn->name);
	if (kc != 0) HTML_CLOSE("p");

@ Use options:

@<Document and dictionary the use options made in extension@> =
	use_option *uo;
	int kc = 0;
	LOOP_OVER(uo, use_option)
		if ((Wordings::first_wn(uo->name) >= 0) &&
			(Lexer::file_of_origin(Wordings::first_wn(uo->name)) == E->read_into_file))
			kc = Extensions::Files::document_headword(OUT, kc, E, "Use options", I"use option",
				uo->name);
	if (kc != 0) HTML_CLOSE("p");

@ Finally, the utility routine which keeps count (hence |kc|) and displays
suitable lists, while entering each entry in turn into the extension
dictionary.

=
int Extensions::Files::document_headword(OUTPUT_STREAM, int kc, inform_extension *E, char *par_heading,
	text_stream *category, wording W) {
	if (kc++ == 0) { HTML_OPEN("p"); WRITE("%s: ", par_heading); }
	else WRITE(", ");
	WRITE("<b>%+W</b>", W);
	Extensions::Dictionary::new_entry(category, E, W);
	return kc;
}

@h Sentence handlers for begins here and ends here.
The main traverses of the assertions are handled by code which calls
"sentence handler" routines on each node in turn, depending on type.
Here are the handlers for BEGINHERE and ENDHERE. As can be seen, all
we really do is start again from a clean piece of paper.

Note that, because one extension can include another, these nodes may
well be interleaved: we might find the sequence A begins, B begins,
B ends, A ends. The careful checking done so far ensures that these
will always properly nest. We don't at present make use of this, but
we might in future.

=
sentence_handler BEGINHERE_SH_handler =
	{ BEGINHERE_NT, -1, 0, Extensions::Files::handle_extension_begins };
sentence_handler ENDHERE_SH_handler =
	{ ENDHERE_NT, -1, 0, Extensions::Files::handle_extension_ends };

void Extensions::Files::handle_extension_begins(parse_node *PN) {
	Assertions::Traverse::new_discussion(); near_start_of_extension = 1;
}

void Extensions::Files::handle_extension_ends(parse_node *PN) {
	near_start_of_extension = 0;
}
