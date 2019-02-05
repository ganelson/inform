[Locations::] Where Everything Lives.

To configure the many locations used in the host filing system.

@h Definitions.

@ This section of the Inform source is intended to give a single description
of where everything lives in the filing system. Very early in Inform's run,
it works out the filenames of everything it will ever need to refer to, and
these are stored in the following globals. Explanations are given below,
not here. First, some "areas":

@d NO_FS_AREAS 3
@d MATERIALS_FS_AREA 0 /* must match |ORIGIN_WAS_*| constants minus 1 */
@d EXTERNAL_FS_AREA 1
@d INTERNAL_FS_AREA 2

=
char *AREA_NAME[3] = { "from .materials", "installed", "built in" };

@ Now for the folders:

= (early code)
pathname *pathname_of_area[NO_FS_AREAS]              = { NULL, NULL, NULL };
pathname *pathname_of_extensions[NO_FS_AREAS]        = { NULL, NULL, NULL };
pathname *pathname_of_i6t_files[NO_FS_AREAS]         = { NULL, NULL, NULL };
pathname *pathname_of_languages[NO_FS_AREAS]         = { NULL, NULL, NULL };
pathname *pathname_of_website_templates[NO_FS_AREAS] = { NULL, NULL, NULL };

pathname *pathname_of_extension_docs = NULL;
pathname *pathname_of_extension_docs_inner = NULL;
pathname *pathname_of_HTML_models = NULL;
pathname *pathname_of_materials_figures = NULL;
pathname *pathname_of_materials_release = NULL;
pathname *pathname_of_materials_sounds = NULL;
pathname *pathname_of_project = NULL;
pathname *pathname_of_project_index_details_folder = NULL;
pathname *pathname_of_project_index_folder = NULL;
pathname *pathname_of_released_figures = NULL;
pathname *pathname_of_released_interpreter = NULL;
pathname *pathname_of_released_sounds = NULL;
pathname *pathname_of_transient_census_data = NULL;
pathname *pathname_of_transient_external_resources = NULL;

@ And secondly, the files:

= (early code)
filename *filename_of_blurb = NULL;
filename *filename_of_cblorb_report = NULL;
filename *filename_of_cblorb_report_model = NULL;
filename *filename_of_compiled_i6_code = NULL;
filename *filename_of_debugging_log = NULL;
filename *filename_of_documentation_snippets = NULL;
filename *filename_of_epsfile = NULL;
filename *filename_of_existing_story_file = NULL;
filename *filename_of_extensions_dictionary = NULL;
filename *filename_of_headings = NULL;
filename *filename_of_i7_source = NULL;
filename *filename_of_ifiction_record = NULL;
filename *filename_of_intro_booklet = NULL;
filename *filename_of_intro_postcard = NULL;
filename *filename_of_large_cover_art_jpeg = NULL;
filename *filename_of_large_cover_art_png = NULL;
filename *filename_of_large_default_cover_art = NULL;
filename *filename_of_manifest = NULL;
filename *filename_of_options = NULL;
filename *filename_of_parse_tree = NULL;
filename *filename_of_report = NULL;
filename *filename_of_small_cover_art_jpeg = NULL;
filename *filename_of_small_cover_art_png = NULL;
filename *filename_of_small_default_cover_art = NULL;
filename *filename_of_SR_module = NULL;
filename *filename_of_story_file = NULL;
filename *filename_of_telemetry = NULL;
filename *filename_of_uuid = NULL;

@h Command line settings.
The following are called when the command line is parsed.

=
void Locations::set_project(text_stream *loc) {
	pathname_of_project = Pathnames::from_text(loc);
}

void Locations::set_internal(text_stream *loc) {
	pathname_of_area[INTERNAL_FS_AREA] = Pathnames::from_text(loc);
}

void Locations::set_external(text_stream *loc) {
	pathname_of_area[EXTERNAL_FS_AREA] = Pathnames::from_text(loc);
}

void Locations::set_transient(text_stream *loc) {
	pathname_of_transient_external_resources = Pathnames::from_text(loc);
}

int Locations::set_I7_source(text_stream *loc) {
	if (filename_of_i7_source) return FALSE;
	filename_of_i7_source = Filenames::from_text(loc);
	return TRUE;
}

int Locations::set_SR_module(text_stream *loc) {
	if (filename_of_SR_module) return FALSE;
	filename_of_SR_module = Filenames::from_text(loc);
	return TRUE;
}

@h Establishing the defaults.
Inform's file access happens inside four different areas: the internal
resources area, usually inside the Inform application; the external resources
area, which is where the user (or the application acting on the user's behalf)
installs extensions; the project bundle, say |Example.inform|; and, alongside
that, the materials folder, |Example.materials|.

Inform can run in two modes: regular mode, when it's compiling source text,
and census mode, when it's scanning the file system for extensions.

=
int Locations::set_defaults(int census_mode) {
	@<Internal resources@>;
	@<External resources@>;
	@<Project resources@>;
	@<Materials resources@>;
	if ((census_mode == FALSE) && (filename_of_i7_source == NULL))
		Problems::Fatal::issue("Except in census mode, source text must be supplied");
	if ((census_mode) && (filename_of_i7_source))
		Problems::Fatal::issue("In census mode, no source text may be supplied");
	return TRUE;
}

@h Internal resources.
Inform needs a whole pile of files to have been installed on the host computer
before it can run: everything from the Standard Rules to a PDF file explaining
what interactive fiction is. They're never written to, only read. They are
referred to as "internal" or "built-in", and they occupy a folder called the
"internal resources" folder.

Unfortunately we don't know where it is. Typically this compiler will be an
executable sitting somewhere inside a user interface application, and the
internal resources folder will be somewhere else inside it. But we don't
know how to find that folder, and we don't want to make any assumptions.
Inform therefore requires on every run that it be told via the |-internal|
switch where the internal resources folder is.

The main ingredients here are the "EILT" resources: extensions, I6T files,
language definitions, and website templates. The Standard Rules, for
example, live inside the Extensions part of this.

@<Internal resources@> =
	if (pathname_of_area[INTERNAL_FS_AREA] == NULL)
		Problems::Fatal::issue("Did not set -internal when calling");

	Locations::EILT_at(INTERNAL_FS_AREA, pathname_of_area[INTERNAL_FS_AREA]);

	@<Miscellaneous other stuff@>;

@ Most of these files are to help |cblorb| to perform a release. The
documentation models are used when making extension documentation; the
leafname is platform-dependent so that Windows can use different models
from everybody else.

The documentation snippets file is generated by |indoc| and contains
brief specifications of phrases, extracted from the manual "Writing with
Inform". This is used to generate the Phrasebook index.

@<Miscellaneous other stuff@> =
	pathname *misc = Pathnames::subfolder(pathname_of_area[INTERNAL_FS_AREA], I"Miscellany");

	filename_of_large_default_cover_art = Filenames::in_folder(misc, I"Cover.jpg");
	filename_of_small_default_cover_art = Filenames::in_folder(misc, I"Small Cover.jpg");
	filename_of_intro_postcard = Filenames::in_folder(misc, I"Postcard.pdf");
	filename_of_intro_booklet = Filenames::in_folder(misc, I"IntroductionToIF.pdf");

	pathname_of_HTML_models = Pathnames::subfolder(pathname_of_area[INTERNAL_FS_AREA], I"HTML");
	filename_of_cblorb_report_model = Filenames::in_folder(pathname_of_HTML_models, I"CblorbModel.html");

	filename_of_documentation_snippets = Filenames::in_folder(misc, I"definitions.html");

@h External resources.
This is where the user can install downloaded extensions, new interpreters,
website templates and so on; so-called "permanent" external resources, since
the user expects them to stay put once installed. But there is also a
"transient" external resources area, for more ephemeral content, such as
the mechanically generated extension documentation. On most platforms the
permanent and transient external areas will be the same, but some mobile
operating systems are aggressive about wanting to delete ephemeral files
used by applications.

The locations of the permanent and transient external folders can be set
using |-external| and |-transient| respectively. If no |-external| is
specified, the location depends on the platform settings: for example on
Mac OS X it will typically be

	|/Library/Users/hclinton/Library/Inform|

If |-transient| is not specified, it's the same folder, i.e., Inform does
not distinguish between permanent and transient external resources.

@<External resources@> =
	if (pathname_of_area[EXTERNAL_FS_AREA] == NULL) {
		pathname_of_area[EXTERNAL_FS_AREA] = home_path;
		char *subfolder_within = INFORM_FOLDER_RELATIVE_TO_HOME;
		if (subfolder_within[0]) {
			TEMPORARY_TEXT(SF);
			WRITE_TO(SF, "%s", subfolder_within);
			pathname_of_area[EXTERNAL_FS_AREA] = Pathnames::subfolder(home_path, SF);
			DISCARD_TEXT(SF);
		}
		pathname_of_area[EXTERNAL_FS_AREA] =
			Pathnames::subfolder(pathname_of_area[EXTERNAL_FS_AREA], I"Inform");
	}
	if (Pathnames::create_in_file_system(pathname_of_area[EXTERNAL_FS_AREA]) == 0) return FALSE;
	@<Permanent external resources@>;

	if (pathname_of_transient_external_resources == NULL)
		pathname_of_transient_external_resources =
			pathname_of_area[EXTERNAL_FS_AREA];
	if (Pathnames::create_in_file_system(pathname_of_transient_external_resources) == 0) return FALSE;
	@<Transient external resources@>;

@ The permanent resources are read-only as far as we are concerned. (The
user interface application, and the user directly, write to this area when
they (say) install new extensions. But the compiler only reads.)

Once again we have a set of EILT resources, but we also have a curiosity:
a useful little file to add source text to everything Inform compiles,
generally to set use options.

@<Permanent external resources@> =
	Locations::EILT_at(EXTERNAL_FS_AREA, pathname_of_area[EXTERNAL_FS_AREA]);
	filename_of_options =
		Filenames::in_folder(pathname_of_area[EXTERNAL_FS_AREA], I"Options.txt");

@ The transient resources are all written by us.

@<Transient external resources@> =
	@<Transient documentation@>;
	@<Transient telemetry@>;

@ The documentation folder is in effect a little website of its own, generated
automatically by Inform. There'll be some files at the top level, and then
there are files on each extension, in suitable subfolders. The census data
subfolder is not browsable or linked to, but holds working files needed when
assembling all this.

@<Transient documentation@> =
	pathname_of_extension_docs =
		Pathnames::subfolder(pathname_of_transient_external_resources, I"Documentation");
	if (Pathnames::create_in_file_system(pathname_of_extension_docs) == 0) return FALSE;

	pathname_of_transient_census_data =
		Pathnames::subfolder(pathname_of_extension_docs, I"Census");
	if (Pathnames::create_in_file_system(pathname_of_transient_census_data) == 0) return FALSE;
	filename_of_extensions_dictionary =
		Filenames::in_folder(pathname_of_transient_census_data, I"Dictionary.txt");

	pathname_of_extension_docs_inner =
		Pathnames::subfolder(pathname_of_extension_docs, I"Extensions");
	if (Pathnames::create_in_file_system(pathname_of_extension_docs_inner) == 0) return FALSE;

@ Telemetry is not as sinister as it sounds: the app isn't sending data out
on the Internet, only (if requested) logging what it's doing to a local file.
This was provided for classroom use, so that teachers can see what their
students have been getting stuck on.

@<Transient telemetry@> =
	pathname *pathname_of_telemetry_data =
		Pathnames::subfolder(pathname_of_transient_external_resources, I"Telemetry");
	if (Pathnames::create_in_file_system(pathname_of_telemetry_data) == 0) return FALSE;
	TEMPORARY_TEXT(leafname_of_telemetry);
	int this_month = the_present->tm_mon + 1;
	int this_day = the_present->tm_mday;
	int this_year = the_present->tm_year + 1900;
	WRITE_TO(leafname_of_telemetry,
		"Telemetry %04d-%02d-%02d.txt", this_year, this_month, this_day);
	filename_of_telemetry =
		Filenames::in_folder(pathname_of_telemetry_data, leafname_of_telemetry);
	Telemetry::locate_telemetry_file(filename_of_telemetry);
	DISCARD_TEXT(leafname_of_telemetry);

@h Project resources.
Although on some platforms it may look like a single file, an Inform project
is a folder whose name has the dot-extension |.inform|. We'll call this the
"project folder", and it contains a whole bundle of useful files.

The UUID file records an ISBN-like identifying number for the project. This
is read-only for us.

The iFiction record, manifest and blurb file are all files that we generate
to give instructions to the releasing agent |cblorb|. This means that they
have no purpose unless Inform is in a release run (with |-release| set on
the command line), but they take no time to generate so we make them anyway.

@<Project resources@> =
	@<The Source folder within the project@>;
	@<The Build folder within the project@>;
	@<The Index folder within the project@>;

	filename_of_uuid = Filenames::in_folder(pathname_of_project, I"uuid.txt");

	filename_of_ifiction_record = Filenames::in_folder(pathname_of_project, I"Metadata.iFiction");
	filename_of_manifest = Filenames::in_folder(pathname_of_project, I"manifest.plist");
	filename_of_blurb = Filenames::in_folder(pathname_of_project, I"Release.blurb");

@ This contains just the main source text for the project. Anachronistically,
this has the filename extension |.ni| for "natural Inform", which was the
working title for Inform 7 back in the early 2000s.

@<The Source folder within the project@> =
	if (filename_of_i7_source == NULL)
		if (pathname_of_project)
			filename_of_i7_source =
				Filenames::in_folder(
					Pathnames::subfolder(pathname_of_project, I"Source"),
					I"story.ni");

@ The build folder for a project contains all of the working files created
during the compilation process. The opening part here may be a surprise:
In extension census mode, Inform is running not to compile something but to
extract details of all the extensions installed. But it still needs somewhere
to write its temporary and debugging files, and there is no project bundle
to write into. To get round this, we use the census data area as if it
were indeed a project bundle.

Briefly: we aim to compile the source text to an Inform 6 program; we issue
an HTML report on our success or failure, listing problem messages if they
occurred; we track our progress in the debugging log. We don't produce the
story file ourselves, I6 will do that, but we do need to know what it's
called; and similarly for the report which the releasing tool |cblorb|
will produce if this is a Release run.

@<The Build folder within the project@> =
	pathname *build_folder = pathname_of_transient_census_data;

	if (census_mode == FALSE) {
		build_folder = Pathnames::subfolder(pathname_of_project, I"Build");
		if (Pathnames::create_in_file_system(build_folder) == 0) return FALSE;
	}

	filename_of_report = Filenames::in_folder(build_folder, I"Problems.html");
	filename_of_debugging_log = Filenames::in_folder(build_folder, I"Debug log.txt");
	filename_of_parse_tree = Filenames::in_folder(build_folder, I"Parse tree.txt");

	filename_of_compiled_i6_code = Filenames::in_folder(build_folder, I"auto.inf");

	TEMPORARY_TEXT(story_file_leafname);
	WRITE_TO(story_file_leafname, "output.%S", story_filename_extension);
	filename_of_story_file = Filenames::in_folder(build_folder, story_file_leafname);
	DISCARD_TEXT(story_file_leafname);

	filename_of_cblorb_report = Filenames::in_folder(build_folder, I"StatusCblorb.html");

@ We're going to write into the Index folder, so we must ensure it exists.
The main index files (|Phrasebook.html| and so on) live at the top level,
details on actions live in the subfolder |Details|: see below.

An oddity in the Index folder is an XML file recording where the headings
are in the source text: this is for the benefit of the user interface
application, if it wants it, but is not linked to or used by the HTML of
the index as seen by the user.

@<The Index folder within the project@> =
	pathname_of_project_index_folder =
		Pathnames::subfolder(pathname_of_project, I"Index");
	pathname_of_project_index_details_folder =
		Pathnames::subfolder(pathname_of_project_index_folder, I"Details");

	if (census_mode == FALSE)
		if ((Pathnames::create_in_file_system(pathname_of_project_index_folder) == 0) ||
			(Pathnames::create_in_file_system(pathname_of_project_index_details_folder) == 0))
			return FALSE;

	filename_of_headings =
		Filenames::in_folder(pathname_of_project_index_folder, I"Headings.xml");

@h Materials resources.
The materials folder sits alongside the project folder and has the same name,
but ending |.materials| instead of |.inform|.

For the third and final time, there are EILT resources.

@<Materials resources@> =
	if (pathname_of_project) {
		TEMPORARY_TEXT(mf);
		WRITE_TO(mf, "%S", Pathnames::directory_name(pathname_of_project));
		int i = Str::len(mf)-1;
		while ((i>0) && (Str::get_at(mf, i) != '.')) i--;
		if (i>0) {
			Str::truncate(mf, i);
			WRITE_TO(mf, ".materials");
		}
		pathname_of_area[MATERIALS_FS_AREA] =
			Pathnames::subfolder(pathname_of_project->pathname_of_parent, mf);
		DISCARD_TEXT(mf);
		if (Pathnames::create_in_file_system(pathname_of_area[MATERIALS_FS_AREA]) == 0) return FALSE;
	} else {
		pathname_of_area[MATERIALS_FS_AREA] = Pathnames::from_text(I"inform.materials");
	}

	Locations::EILT_at(MATERIALS_FS_AREA, pathname_of_area[MATERIALS_FS_AREA]);

	@<Figures and sounds@>;
	@<The Release folder@>;
	@<Existing story file@>;

@ This is where cover art lives: it could have either the file extension |.jpg|
or |.png|, and we generate both sets of filenames, even though at most one will
actually work. This is also where we generate the EPS file of the map, if
so requested; a bit anomalously, it's the only file in Materials but outside
Release which we write to.

This is also where the originals (not the released copies) of the Figures
and Sounds, if any, live: in their own subfolders.

@<Figures and sounds@> =
	pathname_of_materials_figures =    Pathnames::subfolder(pathname_of_area[MATERIALS_FS_AREA], I"Figures");
	pathname_of_materials_sounds =     Pathnames::subfolder(pathname_of_area[MATERIALS_FS_AREA], I"Sounds");

	filename_of_large_cover_art_jpeg = Filenames::in_folder(pathname_of_area[MATERIALS_FS_AREA], I"Cover.jpg");
	filename_of_large_cover_art_png =  Filenames::in_folder(pathname_of_area[MATERIALS_FS_AREA], I"Cover.png");
	filename_of_small_cover_art_jpeg = Filenames::in_folder(pathname_of_area[MATERIALS_FS_AREA], I"Small Cover.jpg");
	filename_of_small_cover_art_png =  Filenames::in_folder(pathname_of_area[MATERIALS_FS_AREA], I"Small Cover.png");

	filename_of_epsfile =              Filenames::in_folder(pathname_of_area[MATERIALS_FS_AREA], I"Inform Map.eps");

@ On a release run, |cblorb| will populate the Release subfolder of Materials;
figures and sounds will be copied into the relevant subfolders. The principle
is that everything in Release can always be thrown away without loss, because
it can all be generated again.

@<The Release folder@> =
	pathname_of_materials_release =    Pathnames::subfolder(pathname_of_area[MATERIALS_FS_AREA], I"Release");
	pathname_of_released_interpreter = Pathnames::subfolder(pathname_of_materials_release, I"interpreter");
	pathname_of_released_figures =     Pathnames::subfolder(pathname_of_materials_release, I"Figures");
	pathname_of_released_sounds =      Pathnames::subfolder(pathname_of_materials_release, I"Sounds");

@ Inform is occasionally run in a mode where it performs a release on an
existing story file (for example a 1980s Infocom one) rather than on one
that it has newly generated. This is the filename such a story file would
have by default, if so.

@<Existing story file@> =
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "story.%S", story_filename_extension);
	filename_of_existing_story_file =
		Filenames::in_folder(pathname_of_area[MATERIALS_FS_AREA], leaf);
	DISCARD_TEXT(leaf);

@h EILTs.
Each of the materials folder, the internal and external areas has a suite
of subfolders to hold I7 extensions (in an author tree: see below), I6
template files, language definitions and website templates.

=
void Locations::EILT_at(int area, pathname *P) {
	pathname_of_extensions[area] =        Pathnames::subfolder(P, I"Extensions");
	pathname_of_i6t_files[area] =         Pathnames::subfolder(P, I"I6T");
	pathname_of_languages[area] =         Pathnames::subfolder(P, I"Languages");
	pathname_of_website_templates[area] = Pathnames::subfolder(P, I"Templates");
}

@h Location of extensions.
When Inform needs one of the EILT resources, it now has three places to look:
the internal resources folder, the external one, and the materials folder.
In fact, it checks them in reverse order, thus allowing the user to override
default resources.

To take the E part, within an Extensions folder, the extensions are stored
within subfolders named for their authors:

	|Extensions|
	|    Emily Short|
	|        Locksmith.i7x|

This is now very much deprecated, but at one time the filename extension
|.i7x| was optional.

=
filename *Locations::of_extension(pathname *E, text_stream *title, text_stream *author, int i7x_flag) {
	TEMPORARY_TEXT(leaf);
	if (i7x_flag) WRITE_TO(leaf, "%S.i7x", title);
	else WRITE_TO(leaf, "%S", title);
	filename *F = Filenames::in_folder(Pathnames::subfolder(E, author), leaf);
	DISCARD_TEXT(leaf);
	return F;
}

@ Documentation is similarly arranged:

=
filename *Locations::of_extension_documentation(text_stream *title, text_stream *author) {
	TEMPORARY_TEXT(leaf);
	WRITE_TO(leaf, "%S.html", title);
	filename *F = Filenames::in_folder(
		Pathnames::subfolder(pathname_of_extension_docs_inner, author), leaf);
	DISCARD_TEXT(leaf);
	return F;
}

@h Location of index files.
Filenames within the |Index| subfolder. Filenames in |Details| have the form
|N_S| where |N| is the integer supplied and |S| the leafname; for instance,
|21_A.html| provides details page number 21 about actions, derived from the
leafname |A.html|.

=
filename *Locations::in_index(text_stream *leafname, int sub) {
	if (pathname_of_project == NULL) return Filenames::in_folder(NULL, leafname);
	if (sub >= 0) {
		TEMPORARY_TEXT(full_leafname);
		WRITE_TO(full_leafname, "%d_%S", sub, leafname);
		filename *F = Filenames::in_folder(pathname_of_project_index_details_folder, full_leafname);
		DISCARD_TEXT(full_leafname);
		return F;
	} else {
		return Filenames::in_folder(pathname_of_project_index_folder, leafname);
	}
}
