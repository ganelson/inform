[Links::] Links and Auxiliary Files.

To manage links to auxiliary files, and placeholder variables.

@h Auxiliary files are for items bundled up with the release but which are
deliberately made accessible for the eventual player: things such as maps
or manuals. Inblorb needs to know about these only when releasing a website;
they are also recorded in an iFiction record, but Inblorb doesn't create that,
Inform 7 does.

=
typedef struct auxiliary_file {
	struct filename *full_filename;
	struct text_stream *aux_leafname;
	struct text_stream *aux_subfolder;
	struct text_stream *description;
	struct text_stream *format; /* e.g., "jpg", "pdf" */
	CLASS_DEFINITION
} auxiliary_file;

@h Registration.
The format text is set to a lower-case version of the filename extension,
and the URL to the filename itself; except when there is no extension, so
that the auxiliary resource is a mini-website in a subfolder of the release
website. In that case the format is |link| and the URL is to the index file
in the subfolder.

=
void Links::create_auxiliary_file(text_stream *fn, text_stream *description, text_stream *subfolder) {
	auxiliary_file *aux = CREATE(auxiliary_file);
	aux->description = Str::duplicate(description);
	aux->aux_subfolder = Str::duplicate(subfolder);
	TEMPORARY_TEXT(ext)
	Links::get_extension_from_textual_filename(ext, fn);
	TEMPORARY_TEXT(leaf)
	Links::get_leafname_from_textual_filename(leaf, fn);
	if (Str::get_first_char(ext) == '.') {
		aux->full_filename = Filenames::from_text(fn);
		aux->format = Str::duplicate(ext);
		Str::delete_first_character(aux->format);
		LOOP_THROUGH_TEXT(pos, aux->format)
			Str::put(pos, Characters::tolower(Str::get(pos)));
	} else {
		aux->full_filename = NULL;
		aux->format = I"link";
	}
	aux->aux_leafname = Str::duplicate(leaf);
	DISCARD_TEXT(ext)
	DISCARD_TEXT(leaf)

	PRINT("! Auxiliary file: <%S> = <%S>\n", fn, description);
}

void Links::get_extension_from_textual_filename(OUTPUT_STREAM, text_stream *filename) {
	int i = Str::len(filename) - 1;
	while ((i>=0) && ((Str::get_at(filename, i) == '.') || (Str::get_at(filename, i) == ' '))) i--;
	while ((i>=0) && (Str::get_at(filename, i) != '.') && (Platform::is_folder_separator(Str::get_at(filename, i)) == FALSE)) i--;
	if ((i<0) || (Platform::is_folder_separator(Str::get_at(filename, i)))) return;
	Str::copy_tail(OUT, filename, i);
}

@ =
void Links::get_leafname_from_textual_filename(OUTPUT_STREAM, text_stream *filename) {
	int i = Str::len(filename) - 1;
	while ((i>=0) && (Platform::is_folder_separator(Str::get_at(filename, i)) == FALSE)) i--;
	Str::copy_tail(OUT, filename, i+1);
}

@h Linking.
The list of links to auxiliary resources is written using |<li>...</li>|
list entry tags, for convenience of CSS styling.

=
void Links::expand_AUXILIARY_variable(OUTPUT_STREAM) {
	auxiliary_file *aux;
	LOOP_OVER(aux, auxiliary_file) {
		if (Str::eq_wide_string(aux->description, U"--") == FALSE) {
			WRITE("<li>");
			Links::download_link(OUT,
				aux->description, aux->full_filename, aux->aux_leafname, aux->format);
			WRITE("</li>");
		}
	}
	Requests::add_links_to_requested_resources(OUT);
}

@ On some of the pages produced by Inblorb the story file itself looks like
another auxiliary resource, but it's produced thus:

=
void Links::expand_DOWNLOAD_variable(OUTPUT_STREAM) {
	filename *eventual_Blorb_location =
		Filenames::in(release_folder, Placeholders::read(I"STORYFILE"));
	Links::download_link(OUT, I"Story File", eventual_Blorb_location,
		Placeholders::read(I"STORYFILE"), I"Blorb");
}

@h Links.
This routine, then, handles either kind of link.

=
void Links::download_link(OUTPUT_STREAM, text_stream *desc, filename *F, text_stream *relative_url, text_stream *form) {
	int size_up = TRUE;
	if (Str::eq_wide_string(form, U"link")) size_up = FALSE;
	WRITE("<a href=\"%S\">%S</a> ", relative_url, desc);
	Websites::open_style(OUT, "filetype");
	WRITE("(%S", form);
	if (size_up) {
		long int size = -1L;
		if (Str::eq_wide_string(desc, U"Story File")) size = (long int) blorb_file_size;
		else size = BinaryFiles::size(F);
		if (size != -1L) @<Write a description of the rough file size@>
	}
	WRITE(")");
	Websites::close_style(OUT, "filetype");
}

@ We round down to the nearest KB, MB, GB, TB or byte, as appropriate. Although
this will describe a 1-byte auxiliary file as "1 bytes", the contingency seems
remote.

@<Write a description of the rough file size@> =
	text_stream *units = I"&nbsp;bytes";
	long int remainder = 0;
	if (size > 1024L) { remainder = size % 1024L; size /= 1024L; units = I"KB"; }
	if (size > 1024L) { remainder = size % 1024L; size /= 1024L; units = I"MB"; }
	if (size > 1024L) { remainder = size % 1024L; size /= 1024L; units = I"GB"; }
	if (size > 1024L) { remainder = size % 1024L; size /= 1024L; units = I"TB"; }
	WRITE(",&nbsp;%d", (int) size);
	if ((size < 100L) && (remainder >= 103L)) WRITE(".%d", (int) (remainder/103L));
	WRITE("%S", units);

@h Cover image.
Note that if the large cover image is a PNG, so is the small (thumbnail)
version, and vice versa -- supplying "Cover.jpg" and "Small Cover.png"
will not work.

=
void Links::expand_COVER_variable(OUTPUT_STREAM) {
	if (cover_exists) {
		char *format = "png"; if (cover_is_in_JPEG_format) format = "jpg";
		WRITE("<a href=\"Cover.%s\"><img src=\"Small Cover.%s\" border=\"1\" width=\"120px\"></a>",
			format, format);
	}
}

@h Releasing.
When we generate a website, we need to copy the auxiliary files into it
(though not mini-websites: the user will have to do that).

=
void Links::request_copy_of_auxiliaries(void) {
	auxiliary_file *aux;
	LOOP_OVER(aux, auxiliary_file) {
		if (Str::ne(aux->format, I"link")) {
			if (verbose_mode)
				PRINT("! COPY <%f> as <%S>\n", aux->full_filename, aux->aux_leafname);
			TEMPORARY_TEXT(as_text)
			WRITE_TO(as_text, "%f", aux->full_filename);
			Requests::request_copy(as_text, aux->aux_leafname, aux->aux_subfolder);
			DISCARD_TEXT(as_text)
		}
	}
}
