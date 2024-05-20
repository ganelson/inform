[InstalledFiles::] Installed Files.

Filenames for a few unmanaged files included in a standard Inform installation.

@ Inform needs a whole pile of files to have been installed on the host computer
before it can run: everything from the Standard Rules to a PDF file explaining
what interactive fiction is. They're never written to, only read. They are
stored in subdirectories called |Miscellany| or |HTML| of the internal nest;
but they're just plain old files, and are not managed by Inbuild as "copies".

@e CBLORB_REPORT_MODEL_IRES from 1
@e DOCUMENTATION_SNIPPETS_IRES
@e INTRO_BOOKLET_IRES
@e INTRO_POSTCARD_IRES
@e LARGE_DEFAULT_COVER_ART_IRES
@e SMALL_DEFAULT_COVER_ART_IRES
@e DOCUMENTATION_XREFS_IRES
@e JAVASCRIPT_FOR_STANDARD_PAGES_IRES
@e JAVASCRIPT_FOR_EXTENSIONS_IRES
@e JAVASCRIPT_FOR_ONE_EXTENSION_IRES
@e CSS_SET_BY_PLATFORM_IRES
@e CSS_FOR_STANDARD_PAGES_IRES
@e RESOURCE_JSON_REQS_IRES
@e REGISTRY_JSON_REQS_IRES
@e INBUILD_JSON_REQS_IRES
@e UNICODE_DATA_IRES
@e MIT_LICENSE_IRES
@e MIT_0_LICENSE_IRES

=
filename *InstalledFiles::filename(int ires) {
	pathname *internal = INSTALLED_FILES_HTML_CALLBACK();
	pathname *misc = Pathnames::down(internal, I"Miscellany");
	pathname *models = Pathnames::down(internal, I"HTML");
	switch (ires) {
		case DOCUMENTATION_SNIPPETS_IRES: 
				return Filenames::in(misc, I"definitions.html");
		case INTRO_BOOKLET_IRES: 
				return Filenames::in(misc, I"IntroductionToIF.pdf");
		case INTRO_POSTCARD_IRES: 
				return Filenames::in(misc, I"Postcard.pdf");
		case LARGE_DEFAULT_COVER_ART_IRES: 
				return Filenames::in(misc, I"DefaultCover.jpg");
		case SMALL_DEFAULT_COVER_ART_IRES: 
				return Filenames::in(misc, I"Small Cover.jpg");
		case RESOURCE_JSON_REQS_IRES:
				return Filenames::in(misc, I"resource.jsonr");
		case REGISTRY_JSON_REQS_IRES:
				return Filenames::in(misc, I"registry.jsonr");
		case INBUILD_JSON_REQS_IRES:
				return Filenames::in(misc, I"inbuild.jsonr");
		case UNICODE_DATA_IRES:
				return Filenames::in(misc, I"UnicodeData.txt");
		case MIT_LICENSE_IRES:
				return Filenames::in(misc, I"MIT.html");
		case MIT_0_LICENSE_IRES:
				return Filenames::in(misc, I"MIT-0.html");

		case CBLORB_REPORT_MODEL_IRES: 
				return InstalledFiles::varied_by_platform(models, I"CblorbModel.html");
		case DOCUMENTATION_XREFS_IRES: 
				return InstalledFiles::varied_by_platform(models, I"xrefs.txt");
		case JAVASCRIPT_FOR_STANDARD_PAGES_IRES: 
				return InstalledFiles::varied_by_platform(models, I"main.js");
		case JAVASCRIPT_FOR_EXTENSIONS_IRES: 
				return InstalledFiles::varied_by_platform(models, I"extensions.js");
		case JAVASCRIPT_FOR_ONE_EXTENSION_IRES: 
				return InstalledFiles::varied_by_platform(models, I"extensionfile.js");
		case CSS_SET_BY_PLATFORM_IRES: 
				return InstalledFiles::varied_by_platform(models, I"platform.css");
		case CSS_FOR_STANDARD_PAGES_IRES: 
				return InstalledFiles::varied_by_platform(models, I"main.css");
	}
	internal_error("unknown installation resource file");
	return NULL;
}

@ This enables each platform to provide its own CSS and Javascript definitions,
if they would prefer that:

=
filename *InstalledFiles::varied_by_platform(pathname *models, text_stream *leafname) {
	TEMPORARY_TEXT(variation)
	WRITE_TO(variation, "%s-%S", PLATFORM_STRING, leafname);
	/* NB: PLATFORM_STRING is a C string, so that %s is correct */
	filename *F = Filenames::in(models, variation);
	if (TextFiles::exists(F) == FALSE) F = Filenames::in(models, leafname);
	DISCARD_TEXT(variation)
	return F;
}

@ Or even for a different platform than the one we're running on:

=
filename *InstalledFiles::filename_for_platform(int ires, text_stream *platform) {
	if (Str::len(platform) == 0) return InstalledFiles::filename(ires);
	pathname *internal = INSTALLED_FILES_HTML_CALLBACK();
	pathname *models = Pathnames::down(internal, I"HTML");
	switch (ires) {
		case CBLORB_REPORT_MODEL_IRES: 
				return InstalledFiles::varied_by_named_platform(models,
					I"CblorbModel.html", platform);
		case DOCUMENTATION_XREFS_IRES: 
				return InstalledFiles::varied_by_named_platform(models,
					I"xrefs.txt", platform);
		case JAVASCRIPT_FOR_STANDARD_PAGES_IRES: 
				return InstalledFiles::varied_by_named_platform(models,
					I"main.js", platform);
		case JAVASCRIPT_FOR_EXTENSIONS_IRES: 
				return InstalledFiles::varied_by_named_platform(models,
					I"extensions.js", platform);
		case JAVASCRIPT_FOR_ONE_EXTENSION_IRES: 
				return InstalledFiles::varied_by_named_platform(models,
					I"extensionfile.js", platform);
		case CSS_SET_BY_PLATFORM_IRES: 
				return InstalledFiles::varied_by_named_platform(models,
					I"platform.css", platform);
		case CSS_FOR_STANDARD_PAGES_IRES:
				return InstalledFiles::varied_by_named_platform(models,
					I"main.css", platform);
	}
	return InstalledFiles::filename(ires);
}

filename *InstalledFiles::varied_by_named_platform(pathname *models, text_stream *leafname,
	text_stream *platform) {
	TEMPORARY_TEXT(variation)
	WRITE_TO(variation, "%S-%S", platform, leafname);
	filename *F = Filenames::in(models, variation);
	if (TextFiles::exists(F) == FALSE) F = Filenames::in(models, leafname);
	DISCARD_TEXT(variation)
	return F;
}

@ This directory also holds the |Basic.indext| and |Standard.indext| index
structure files, but in principle we allow a wider range of these to exist, so:

=
filename *InstalledFiles::index_structure_file(text_stream *leaf) {
	pathname *internal = INSTALLED_FILES_HTML_CALLBACK();
	pathname *misc = Pathnames::down(internal, I"Miscellany");
	return Filenames::in(misc, leaf);
}
