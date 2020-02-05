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

When Inform is run in "census mode", it should be run with the command

	|ni -rules (...) -census|

where the argument for |-rules| is the same as for any other run. All
output from Inform should be ignored, including its return code: ideally,
not even a fatal error should provoke a reaction from the application.
If the census doesn't work for some file-system reason, never mind --
it's not mission-critical.

@h What happens in census mode.
The census has two purposes: first, to create provisional documentation
where needed for new and unused extensions; and second, to create the
following index files in the external documentation area (not in
the external extension area):

	|.../Extensions.html| (basically a contents page)
	|.../ExtIndex.html| (basically an index)

Documentation for any individual extension is stored at, e.g.,

	|.../Extensions/Victoria Saxe-Coburg-Gotha/Werewolves.html|

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
typedef struct extension_file {
	struct inbuild_requirement *ef_req; /* Work and version needed */
	struct wording author_text; /* Author's name */
	struct wording title_text; /* Extension name */
	struct wording VM_restriction_text; /* Restricting use to certain VMs */
	struct parse_node *inclusion_sentence; /* Where the source called for this */
	struct inbuild_copy *found;
	MEMORY_MANAGEMENT
} extension_file;

extension_file *standard_rules_extension; /* the Standard Rules by Graham Nelson */

@ We begin with some housekeeping, really: the code required to create new
extension file structures, and to manage existing ones.

=
extension_file *Extensions::Files::new(wording AW, wording NW, wording VMW, int version_word) {
	TEMPORARY_TEXT(violation);
	extension_file *ef = CREATE(extension_file);
	ef->author_text = AW;
	ef->title_text = NW;
	@<Create work for new extension file@>;
	ef->inclusion_sentence = current_sentence;
	ef->VM_restriction_text = VMW;
	ef->found = NULL;
	if (Str::len(violation) > 0) {
		LOG("So %S\n", violation);
		Problems::Issue::extension_problem_S(_p_(PM_IncludesTooLong), ef, violation); /* see below */
	}
	DISCARD_TEXT(violation);
	return ef;
}

inform_extension *Extensions::Files::find(extension_file *ef) {
	if (ef == NULL) return NULL;
	if (ef->found == NULL) return NULL;
	return Extensions::from_copy(ef->found);
}

@ We protect ourselves a little against absurdly long requested author or
title names, and then produce problem messages in the event of only longish
ones, unless the census is going on: in which case it's better to leave the
matter to the census errors system elsewhere.

@<Create work for new extension file@> =
	TEMPORARY_TEXT(exft);
	TEMPORARY_TEXT(exfa);
	WRITE_TO(exft, "%+W", ef->title_text);
	WRITE_TO(exfa, "%+W", ef->author_text);
	if (Extensions::Census::currently_recording_errors() == FALSE) {
		if (Str::len(exfa) >= MAX_EXTENSION_AUTHOR_LENGTH) {
			WRITE_TO(violation,
				"has an author's name which is too long, exceeding the maximum "
				"allowed (%d characters) by %d",
				MAX_EXTENSION_AUTHOR_LENGTH-1,
				(int) (1+Str::len(exfa)-MAX_EXTENSION_AUTHOR_LENGTH));
			Str::truncate(exfa, MAX_EXTENSION_AUTHOR_LENGTH-1);
		}
		if (Str::len(exft) >= MAX_EXTENSION_AUTHOR_LENGTH) {
			WRITE_TO(violation,
				"has a title which is too long, exceeding the maximum allowed "
				"(%d characters) by %d",
				MAX_EXTENSION_TITLE_LENGTH-1,
				(int) (1+Str::len(exft)-MAX_EXTENSION_TITLE_LENGTH));
			Str::truncate(exft, MAX_EXTENSION_AUTHOR_LENGTH-1);
		}
	}
	inbuild_work *work = Works::new(extension_genre, exft, exfa);
	Works::add_to_database(work, LOADED_WDBC);
	inbuild_version_number min = VersionNumbers::null();
	if (version_word >= 0) min = Extensions::Inclusion::parse_version(version_word);
	ef->ef_req = Requirements::new(work, min, VersionNumbers::null());
	if (Works::is_standard_rules(work)) standard_rules_extension = ef;
	DISCARD_TEXT(exft);
	DISCARD_TEXT(exfa);

@ Three pieces of information (not available when the EF is created) will
be set later on, by other parts of Inform calling the routines below.

The rubric text for an extension, which is double-quoted matter just below
its "begins here" line, is parsed as a sentence and will be read as an
assertion in the usual way when the material from this extension is being
worked through (quite a long time after the EF structure was created). When
that happens, the following routine will be called to set the rubric; and
the one after for the optional extra credit line, used to acknowledge I6
sources, collaborators, translators and so on.

=
void Extensions::Files::set_rubric(extension_file *ef, text_stream *text) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E == NULL) internal_error("unfound ef");
	E->rubric_as_lexed = Str::duplicate(text);
	LOGIF(EXTENSIONS_CENSUS, "Extension rubric: %S\n", E->rubric_as_lexed);
}

void Extensions::Files::set_extra_credit(extension_file *ef, text_stream *text) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E == NULL) internal_error("unfound ef");
	E->extra_credit_as_lexed = Str::duplicate(text);
	LOGIF(EXTENSIONS_CENSUS, "Extension extra credit: %S\n", E->extra_credit_as_lexed);
}

@ Once we start reading text from the file (if it can successfully be found:
when the EF structure is created, we don't know that yet), we need to tally
it up with the corresponding source file structure.

=
void Extensions::Files::set_corresponding_source_file(extension_file *ef, source_file *sf) {
	inform_extension *E = Extensions::load_at(
		ef->ef_req->work->title, ef->ef_req->work->author_name, sf->name);
	ef->found = E->as_copy;
	E->read_into_file = sf;
}

source_file *Extensions::Files::source(extension_file *ef) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E) return E->read_into_file;
	return NULL;
}

@ When headings cross-refer to extensions, they need to read extension IDs, so:

=
inbuild_work *Extensions::Files::get_work(extension_file *ef) {
	return (ef)?(ef->ef_req->work):NULL;
}

@ A few problem messages need the version number loaded, so:

=
inbuild_version_number Extensions::Files::get_version(extension_file *ef) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E == NULL) return VersionNumbers::null();
	return E->version_loaded;
}

inbuild_edition *Extensions::Files::get_edition(extension_file *ef) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E == NULL) return NULL;
	return E->as_copy->edition;
}

void Extensions::Files::set_version(extension_file *ef, inbuild_version_number V) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E == NULL) internal_error("no E found");
	E->version_loaded = V;
}

@ The use option "authorial modesty" is unusual in applying to the extension
it is found in, not the whole source text. When we read it, we call one of
the following routines, depending on whether it was in an extension or in
the main source text:

=
int general_authorial_modesty = FALSE;
void Extensions::Files::set_authorial_modesty(extension_file *ef) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E == NULL) internal_error("unfound ef");
	E->authorial_modesty = TRUE;
}
void Extensions::Files::set_general_authorial_modesty(void) { general_authorial_modesty = TRUE; }

@h Printing names of extensions.
We can print the name of the extension in a variety of ways and to a
variety of destinations, but it all comes down to the same thing in the end.
First, printing the name to an arbitrary UTF-8 file:

=
void Extensions::Files::write_name_to_file(extension_file *ef, OUTPUT_STREAM) {
	WRITE("%+W", ef->title_text);
}

void Extensions::Files::write_author_to_file(extension_file *ef, OUTPUT_STREAM) {
	WRITE("%+W", ef->author_text);
}

@ Next, the debugging log:

=
void Extensions::Files::log(extension_file *ef) {
	if (ef == NULL) { LOG("<null-extension-file>"); return; }
	LOG("%W by %W", ef->title_text, ef->author_text);
}

@ Next, printing the name in the form of a comment in an (ISO Latin-1)
Inform 6 source file:

=
void Extensions::Files::write_I6_comment_describing(extension_file *ef) {
	if (ef == standard_rules_extension) {
		Produce::comment(Emit::tree(), I"From the Standard Rules");
	} else {
		TEMPORARY_TEXT(C);
		WRITE_TO(C, "From \"%~W\" by %~W", ef->title_text, ef->author_text);
		Produce::comment(Emit::tree(), C);
		DISCARD_TEXT(C);
	}
}

@ And finally printing the name to a C string:

=
void Extensions::Files::write_full_title_to_stream(OUTPUT_STREAM, extension_file *ef) {
	WRITE("%+W by %+W", ef->title_text, ef->author_text);
}

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
	extension_file *ef;
	LOOP_OVER(ef, extension_file) {
		if (Requirements::meets(Extensions::Files::get_edition(ef), ef->ef_req) == FALSE) {
			inbuild_version_number have = Extensions::Files::get_version(ef);
			LOG("Need %v, have %v\n", &(ef->ef_req->min_version), &have);
			current_sentence = ef->inclusion_sentence;
			Problems::quote_source(1, current_sentence);
			Problems::quote_extension(2, ef);
			if (VersionNumbers::is_null(have) == FALSE) {
				TEMPORARY_TEXT(vn);
				VersionNumbers::to_text(vn, have);
				Problems::quote_stream(3, vn);
				Problems::Issue::handmade_problem(_p_(PM_ExtVersionTooLow));
				Problems::issue_problem_segment(
					"You wrote %1: but my copy of %2 is only version %3.");
				Problems::issue_problem_end();
				DISCARD_TEXT(vn);
			} else {
				Problems::Issue::handmade_problem(_p_(PM_ExtNoVersion));
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
	extension_file *ef;
	LOOP_OVER(ef, extension_file) {
		TEMPORARY_TEXT(the_author_name);
		WRITE_TO(the_author_name, "%+W", ef->author_text);
		int self_penned = FALSE;
		#ifdef IF_MODULE
		if (PL::Bibliographic::story_author_is(the_author_name)) self_penned = TRUE;
		#endif
		inform_extension *E = Extensions::Files::find(ef);
		if (((E == NULL) || (E->authorial_modesty == FALSE)) && /* if (1) extension doesn't ask to be modest */
			((general_authorial_modesty == FALSE) || /* and (2) author doesn't ask to be modest, or... */
			(self_penned == FALSE))) { /* ...didn't write this extension */
				TEMPORARY_TEXT(C);
				Extensions::Files::credit_ef(C, ef, TRUE); /* then we award a credit */
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
	LOOP_OVER(ef, extension_file) {
		TEMPORARY_TEXT(C);
		Extensions::Files::credit_ef(C, ef, TRUE);
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
	LOOP_OVER(ef, extension_file) {
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Produce::down(Emit::tree());
				Produce::val_symbol(Emit::tree(), K_value, id_s);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (ef->allocation_id + 1));
			Produce::up(Emit::tree());
			Produce::code(Emit::tree());
			Produce::down(Emit::tree());
				TEMPORARY_TEXT(C);
				Extensions::Files::credit_ef(C, ef, FALSE);
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
void Extensions::Files::credit_ef(OUTPUT_STREAM, extension_file *ef, int with_newline) {
	inform_extension *E = Extensions::Files::find(ef);
	if (E == NULL) internal_error("unfound ef");
	WRITE("%S", ef->ef_req->work->raw_title);
	inbuild_version_number V = Extensions::Files::get_version(ef);
	if (VersionNumbers::is_null(V) == FALSE) WRITE(" version %v", &V);
	WRITE(" by %S", ef->ef_req->work->raw_author_name);
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
	extension_file *from;
	LOOP_OVER(from, extension_file)
		if (from != standard_rules_extension)
			Extensions::Files::index_extensions_from(OUT, from);
	Extensions::Files::index_extensions_from(OUT, standard_rules_extension);
	HTML_OPEN("p"); HTML_CLOSE("p");
}

void Extensions::Files::index_extensions_from(OUTPUT_STREAM, extension_file *from) {
	int show_head = TRUE;
	extension_file *ef;
	LOOP_OVER(ef, extension_file) {
		extension_file *owner = NULL;
		if (ef == standard_rules_extension) owner = standard_rules_extension;
		else if (Wordings::nonempty(ParseTree::get_text(ef->inclusion_sentence))) {
			source_location sl = Wordings::location(ParseTree::get_text(ef->inclusion_sentence));
			if (sl.file_of_origin == NULL) owner = standard_rules_extension;
			else owner = SourceFiles::get_extension_corresponding(
				Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(ef->inclusion_sentence))));
		}
		if (owner != from) continue;
		if (show_head) {
			HTMLFiles::open_para(OUT, 2, "hanging");
			HTML::begin_colour(OUT, I"808080");
			WRITE("Included ");
			if (from == standard_rules_extension) WRITE("automatically by Inform");
			else if (from == NULL) WRITE("from the source text");
			else {
				WRITE("by the extension %+W", from->title_text);
			}
			show_head = FALSE;
			HTML::end_colour(OUT);
			HTML_CLOSE("p");
		}
		HTML_OPEN_WITH("ul", "class=\"leaders\"");
		HTML_OPEN_WITH("li", "class=\"leaded indent2\"");
		HTML_OPEN("span");
		WRITE("%+W ", ef->title_text);
		Works::begin_extension_link(OUT, ef->ef_req->work, NULL);
		HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/help.png");
		Works::end_extension_link(OUT, ef->ef_req->work);
		if (ef != standard_rules_extension) { /* give author and inclusion links, but not for SR */
			WRITE(" by %+W", ef->author_text);
		}
		if (VersionNumbers::is_null(Extensions::Files::get_version(ef)) == FALSE) {
			WRITE(" ");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			inbuild_version_number V = Extensions::Files::get_version(ef);
			WRITE("version %v", &V);
			HTML_CLOSE("span");
		}
		inform_extension *E = Extensions::Files::find(ef);
		if ((E) && (Str::len(E->extra_credit_as_lexed) > 0)) {
			WRITE(" ");
			HTML_OPEN_WITH("span", "class=\"smaller\"");
			WRITE("(%S)", E->extra_credit_as_lexed);
			HTML_CLOSE("span");
		}
		HTML_CLOSE("span");
		HTML_OPEN("span");
		WRITE("%d words", TextFromFiles::total_word_count(Extensions::Files::source(ef)));
		if (from == NULL) Index::link(OUT, Wordings::first_wn(ParseTree::get_text(ef->inclusion_sentence)));
		HTML_CLOSE("span");
		HTML_CLOSE("li");
		HTML_CLOSE("ul");
		WRITE("\n");
	}
}

@h Updating the documentation.
This is done in the course of taking an extension census, which is called
for in one of two circumstances: when Inform is being run in "census mode" to
notify it that extensions have been installed or uninstalled; or when Inform
has completed the successful compilation of a source text. In the latter
case, it knows quite a lot about the extensions actually used in that
compilation, and so can write detailed versions of their documentation:
since it is updating extension documentation anyway, it conducts a census
as well. (In both cases the extension dictionary is also worked upon.) The
two alternatives are expressed here:

=
void Extensions::Files::handle_census_mode(void) {
	if (census_mode) {
		extension_census *C = Extensions::Census::new(I7_nest_list);
		C->built_in_tag = ORIGIN_WAS_BUILT_IN_EXTENSIONS_AREA;
		C->materials_tag = ORIGIN_WAS_MATERIALS_EXTENSIONS_AREA;
		C->external_tag = ORIGIN_WAS_USER_EXTENSIONS_AREA;
		Extensions::Dictionary::load();
		Extensions::Census::perform(C);
		Extensions::Files::write_top_level_of_extensions_documentation(C);
		Extensions::Files::write_sketchy_documentation_for_extensions_found();
	}
}

void Extensions::Files::update_census(void) {
	extension_file *ef;
	Extensions::Dictionary::load();
	extension_census *C = Extensions::Census::new(I7_nest_list);
	C->built_in_tag = ORIGIN_WAS_BUILT_IN_EXTENSIONS_AREA;
	C->materials_tag = ORIGIN_WAS_MATERIALS_EXTENSIONS_AREA;
	C->external_tag = ORIGIN_WAS_USER_EXTENSIONS_AREA;
	Extensions::Census::perform(C);
	Extensions::Files::write_top_level_of_extensions_documentation(C);
	LOOP_OVER(ef, extension_file) Extensions::Documentation::write_detailed(ef);
	Extensions::Files::write_sketchy_documentation_for_extensions_found();
	Extensions::Dictionary::write_back();
	if (Log::aspect_switched_on(EXTENSIONS_CENSUS_DA)) Works::log_work_hash_table();
}

@ Documenting extensions seen but not used: we run through the census
results in no particular order and create a sketchy page of documentation,
if there's no better one already.

=
void Extensions::Files::write_sketchy_documentation_for_extensions_found(void) {
	extension_census_datum *ecd;
	LOOP_OVER(ecd, extension_census_datum)
		Extensions::Documentation::write_sketchy(ecd);
}

@h Writing the extensions home pages.
Extensions documentation forms a mini-website within the Inform
documentation. There is a top level consisting of two home pages: a
directory of all installed extensions, and an index to the terms defined in
those extensions. A cross-link switches between them. Each of these links
down to the bottom level, where there is a page for every installed
extension (wherever it is installed). The picture is therefore something
like this:

= (not code)
    (Main documentation contents page)
            |
    Extensions.html--ExtIndex.html
            |      \/      |
            |      /\      |
    Nigel Toad/Eggs  Barnabas Dundritch/Neopolitan Iced Cream   ...

@ These pages are stored at the relative pathnames

	|Extensions/Documentation/Extensions.html|
	|Extensions/Documentation/ExtIndex.html|

They are made by inserting content in place of the material between the
HTML anchors |on| and |off| in a template version of the page built in
to the application, with a leafname which varies from platform to
platform, for reasons as always to do with the vagaries of Internet
Explorer 7 for Windows.

=
void Extensions::Files::write_top_level_of_extensions_documentation(extension_census *C) {
	Extensions::Files::write_top_level_extensions_page(I"Extensions.html", 1, C);
	Extensions::Files::write_top_level_extensions_page(I"ExtIndex.html", 2, NULL);
}

@ =
void Extensions::Files::write_top_level_extensions_page(text_stream *leaf, int content, extension_census *C) {
	text_stream HOMEPAGE_struct;
	text_stream *OUT = &HOMEPAGE_struct;
	filename *F = Filenames::in_folder(pathname_of_extension_docs, leaf);
	if (STREAM_OPEN_TO_FILE(OUT, F, UTF8_ENC) == FALSE)
		Problems::Fatal::filename_related(
			"Unable to open extensions documentation index for writing", F);
	HTML::declare_as_HTML(OUT, FALSE);

	HTML::begin_head(OUT, NULL);
	HTML::title(OUT, I"Extensions");
	HTML::incorporate_javascript(OUT, TRUE,
		Filenames::in_folder(pathname_of_HTML_models, I"extensions.js"));
	HTML::incorporate_CSS(OUT,
		Filenames::in_folder(pathname_of_HTML_models, I"main.css"));
	HTML::end_head(OUT);

	HTML::begin_body(OUT, NULL);
	HTML::begin_html_table(OUT, NULL, TRUE, 0, 4, 0, 0, 0);
	HTML::first_html_column(OUT, 0);
	HTML_TAG_WITH("img", "src='inform:/doc_images/extensions@2x.png' border=0 width=150 height=150");
	HTML::next_html_column(OUT, 0);

	HTML_OPEN_WITH("div", "class=\"headingboxDark\"");
	HTML_OPEN_WITH("div", "class=\"headingtextWhite\"");
	WRITE("Installed Extensions");
	HTML_CLOSE("div");
	HTML_OPEN_WITH("div", "class=\"headingrubricWhite\"");
	WRITE("Bundles of extra rules or phrases to extend what Inform can do");
	HTML_CLOSE("div");
	HTML_CLOSE("div");

	switch (content) {
		case 1: Extensions::Census::write_results(OUT, C); break;
		case 2: Extensions::Dictionary::write_to_HTML(OUT); break;
	}

	HTML::end_body(OUT);
}
