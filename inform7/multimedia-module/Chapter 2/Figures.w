[PL::Figures::] Figures.

To register the names associated with picture resource numbers, which
are defined to allow the final story file to display pictures, and to produce
the thumbnail index of figures.

@h Definitions.

@ To be viable, figures have to be of an image format which Blorb recognises,
and in any case we only allow two formats: JPEG and PNG.

=
typedef struct blorb_figure {
	struct wording name; /* text of name */
	struct filename *filename_of_image_file;
	int figure_number; /* resource number of this picture inside Blorb */
	int alt_description; /* word number of double-quoted description */
	CLASS_DEFINITION
} blorb_figure;

@ One is special:

=
blorb_figure *F_cover_art = NULL;

@ And we define one type ID.
A resource ID number for a figure (i.e.,
a picture) or a sound effect in the eventual blorb, or for use in Glulx
within the application.

= (early code)
kind *K_figure_name = NULL;

@ =
void PL::Figures::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_INSTANCE_NOTIFY, PL::Figures::figures_new_named_instance_notify);
	PLUGIN_REGISTER(PLUGIN_NEW_BASE_KIND_NOTIFY, PL::Figures::figures_new_base_kind_notify);
}

@ =
int PL::Figures::figures_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, L"FIGURE_NAME_TY")) {
		K_figure_name = new_base; return TRUE;
	}
	return FALSE;
}

int allow_figure_creations = FALSE;

int PL::Figures::figures_new_named_instance_notify(instance *nc) {
	if (K_figure_name == NULL) return FALSE;
	kind *K = Instances::to_kind(nc);
	if (Kinds::Compare::eq(K, K_figure_name)) {
		if (allow_figure_creations == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_BackdoorFigureCreation),
				"this is not the way to create a new figure name",
				"which should be done with a special 'Figure ... is the file ...' "
				"sentence.");
		Instances::set_connection(nc,
			STORE_POINTER_blorb_figure(PL::Figures::new_blorb_figure(nc)));
		return TRUE;
	}
	return FALSE;
}

blorb_figure *PL::Figures::new_blorb_figure(instance *nc) {
	blorb_figure *bf = CREATE(blorb_figure);
	bf->name = EMPTY_WORDING;
	bf->filename_of_image_file = NULL;
	bf->figure_number = 0;
	bf->alt_description = -1;
	return bf;
}

@ Figure allocation now follows. This handles the special meaning "X is an figure...".

=
<new-figure-sentence-object> ::=
	<definite-article> <new-figure-sentence-object-unarticled> |    ==> R[2]; *XP = RP[2]
	<new-figure-sentence-object-unarticled>							==> R[1]; *XP = RP[1]

<new-figure-sentence-object-unarticled> ::=
	file <nounphrase>												==> TRUE; *XP = RP[1]

@ =
int PL::Figures::new_figure_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) { /* "Figure... is the file..." */
		case ACCEPT_SMFT:
			if ((<nounphrase-figure>(SW)) && (<new-figure-sentence-object>(OW))) {
				Annotations::write_int(V, verb_id_ANNOT, SPECIAL_MEANING_VB);
				parse_node *O = <<rp>>;
				<nounphrase>(SW);
				V->next = <<rp>>;
				V->next->next = O;
				return TRUE;
			}
			break;
		case TRAVERSE1_SMFT:
			if (Plugins::Manage::plugged_in(figures_plugin) == FALSE)
				internal_error("Figures plugin inactive");
			PL::Figures::register_figure(Node::get_text(V->next),
				Node::get_text(V->next->next));
			break;
	}
	return FALSE;
}

@ =
<figure-sentence-object> ::=
	<figure-source> ( <quoted-text> ) |    ==> R[1]; <<alttext>> = R[2];
	<figure-source>							==> R[1]

<figure-source> ::=
	of cover art |    ==> -1
	<quoted-text> |    ==> R[1]
	...						==> @<Issue PM_PictureNotTextual problem@>;

@<Issue PM_PictureNotTextual problem@> =
	StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PictureNotTextual),
		"a figure can only be declared as a quoted file name",
		"which should be the name of a JPEG or PNG image inside the "
		"project's .materials folder. For instance, 'Figure 2 is the "
		"file \"Crossed Swords.png\".'");
	*X = 0;

@ This is a figure name which Inform provides special support for; it
recognises the English name when it is defined by the Standard Rules. (So there
is no need to translate this to other languages.)

=
<notable-figures> ::=
	of cover art

@ =
void PL::Figures::register_figure(wording F, wording FN) {
	<<alttext>> = -1;
	<figure-sentence-object>(FN);
	int wn = <<r>>;
	if (wn == 0) return;
	if (wn > 0) Word::dequote(wn);
	if (<<alttext>> > 0) Word::dequote(<<alttext>>);

	Assertions::Creator::vet_name_for_noun(F);
	if ((<s-value>(F)) &&
		(Rvalues::is_CONSTANT_of_kind(<<rp>>, K_figure_name))) {
		StandardProblems::sentence_problem(Task::syntax_tree(), _p_(PM_PictureDuplicate),
			"this is already the name of a Figure",
			"so there must be some duplication somewhere.");
		return;
	}

	allow_figure_creations = TRUE;
	pcalc_prop *prop = Calculus::Propositions::Abstract::to_create_something(K_figure_name, F);
	Calculus::Propositions::Assert::assert_true(prop, CERTAIN_CE);
	allow_figure_creations = FALSE;
	blorb_figure *bf = RETRIEVE_POINTER_blorb_figure(
		Instances::get_connection(latest_instance));

	bf->name = F;
	if (wn >= 0) {
		bf->figure_number = Task::get_next_free_blorb_resource_ID();
		TEMPORARY_TEXT(leaf)
		WRITE_TO(leaf, "%N", wn);
		bf->filename_of_image_file = Filenames::in(Task::figures_path(), leaf);
		DISCARD_TEXT(leaf)
		bf->alt_description = <<alttext>>;
	} else {
		bf->figure_number = 1;
		bf->filename_of_image_file = NULL;
		bf->alt_description = <<alttext>>;
		F_cover_art = bf;
	}
	LOGIF(FIGURE_CREATIONS, "Created figure <%W> = filename '%N' = resource ID %d\n",
		F, wn, bf->figure_number);
}

wchar_t *PL::Figures::description_of_cover_art(void) {
	if ((F_cover_art == NULL) || (F_cover_art->alt_description == -1)) return L"";
	return Lexer::word_text(F_cover_art->alt_description);
}

@h Blurb and manifest.
The picture manifest is used by the implementation of Glulx within the
Inform application to connect picture ID numbers with filenames relative
to the Materials folder for its project.

=
void PL::Figures::write_picture_manifest(OUTPUT_STREAM, int include_cover,
	char *cover_art_format) {
	if (Plugins::Manage::plugged_in(figures_plugin) == FALSE) return;
	blorb_figure *bf;
	WRITE("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
	WRITE("<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" "
		"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
	WRITE("<plist version=\"1.0\">\n"); INDENT;
	WRITE("<dict>\n"); INDENT;
	WRITE("<key>Graphics</key>\n");
	WRITE("<dict>\n"); INDENT;
	if (include_cover) {
		WRITE("<key>1</key>\n");
		filename *large = NULL;
		if (strcmp(cover_art_format, "jpg") == 0)
			large = Task::large_cover_art_file(TRUE);
		else
			large = Task::large_cover_art_file(FALSE);
		WRITE("<string>%f</string>\n", large);
	}
	LOOP_OVER(bf, blorb_figure)
		if (bf->figure_number > 1) {
			WRITE("<key>%d</key>\n", bf->figure_number);
			TEMPORARY_TEXT(rel)
			Filenames::to_text_relative(rel, bf->filename_of_image_file,
				Projects::materials_path(Task::project()));
			WRITE("<string>%S</string>\n", rel);
			DISCARD_TEXT(rel)
		}
	OUTDENT; WRITE("</dict>\n");
	PL::Sounds::write_sounds_manifest(OUT);
	OUTDENT; WRITE("</dict>\n");
	OUTDENT; WRITE("</plist>\n");
}

@ The following writes Blurb commands for all of the figures, but not for
the cover art, which is handled by Bibliographic Data.

=
void PL::Figures::write_blurb_commands(OUTPUT_STREAM) {
	if (Plugins::Manage::plugged_in(figures_plugin) == FALSE) return;
	blorb_figure *bf;
	LOOP_OVER(bf, blorb_figure)
		if (bf->figure_number > 1) {
			wchar_t *desc = L"";
			if (bf->alt_description >= 0)
				desc = Lexer::word_text(bf->alt_description);
			if (Wide::len(desc) > 0)
				WRITE("picture %d \"%f\" \"%N\"\n", bf->figure_number, bf->filename_of_image_file, bf->alt_description);
			else
				WRITE("picture %d \"%f\"\n", bf->figure_number, bf->filename_of_image_file);
		}
}

@ The following is used only with the "separate figures" release option.

=
void PL::Figures::write_copy_commands(void) {
	if (Plugins::Manage::plugged_in(figures_plugin) == FALSE) return;
	blorb_figure *bf;
	LOOP_OVER(bf, blorb_figure)
		if (bf->figure_number > 1)
			PL::Bibliographic::Release::create_aux_file(bf->filename_of_image_file,
				Task::released_figures_path(), L"--", SEPARATE_FIGURES_PAYLOAD);
}

@ =
void PL::Figures::compile_ResourceIDsOfFigures_array(void) {
	if (Plugins::Manage::plugged_in(figures_plugin) == FALSE) return;
	inter_name *iname = Hierarchy::find(RESOURCEIDSOFFIGURES_HL);
	packaging_state save = Emit::named_array_begin(iname, K_number);
	Emit::array_numeric_entry(0);
	blorb_figure *bf;
	LOOP_OVER(bf, blorb_figure) Emit::array_numeric_entry((inter_t) bf->figure_number);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
}

@h Thumbnail Index.
The index is presented with thumbnails of a given pixel width, which
the HTML renderer automatically scales to fit. Height is adjusted so as
to match this width, preserving the aspect ratio.

@d THUMBNAIL_WIDTH 80

=
void PL::Figures::index_all(OUTPUT_STREAM) {
	if (Plugins::Manage::plugged_in(figures_plugin) == FALSE) return;
	blorb_figure *bf; FILE *FIGURE_FILE;
	int MAX_INDEXED_FIGURES = UseOptions::get_index_figure_thumbnails();
	int rv;
	if (NUMBER_CREATED(blorb_figure) < 2) { /* cover art always creates 1 */
		HTML_OPEN("p"); WRITE("There are no figures, or illustrations, in this project.");
		HTML_CLOSE("p"); return;
	}
	HTML_OPEN("p"); WRITE("<b>List of Figures</b>"); HTML_CLOSE("p");

	HTML::begin_html_table(OUT, "#ffffff", TRUE, 0, 0, 0, 0, 0);
	int count_of_displayed_figures = 0;
	LOOP_OVER(bf, blorb_figure) {
		if (bf->figure_number > 1) {
			TEMPORARY_TEXT(line2)
			unsigned int width = 0, height = 0;
			rv = 0;
			FIGURE_FILE = Filenames::fopen(bf->filename_of_image_file, "rb");
			if (FIGURE_FILE) {
				char *real_format = "JPEG";
				rv = ImageFiles::get_JPEG_dimensions(FIGURE_FILE, &width, &height);
				fclose(FIGURE_FILE);
				if (rv == 0) {
					FIGURE_FILE = Filenames::fopen(bf->filename_of_image_file, "rb");
					if (FIGURE_FILE) {
						real_format = "PNG";
						rv = ImageFiles::get_PNG_dimensions(FIGURE_FILE, &width, &height);
						fclose(FIGURE_FILE);
					}
				}
				if (rv == 0) {
					WRITE_TO(line2, "<i>Unknown image format</i>");
					HTML_TAG("br");
				} else {
					WRITE_TO(line2, "%s format: %d (width) by %d (height) pixels",
						real_format, width, height);
					HTML_TAG("br");
				}
			} else {
				WRITE_TO(line2, "<i>Missing from the Figures folder</i>");
				HTML_TAG("br");
			}
			HTML::first_html_column(OUT, THUMBNAIL_WIDTH+10);
			if (rv == 0) {
				HTML_TAG_WITH("img", "border=\"0\" src=\"inform:/doc_images/image_problem.png\"");
				WRITE("&nbsp;");
			} else if (count_of_displayed_figures++ < MAX_INDEXED_FIGURES) {
				HTML_TAG_WITH("img", "border=\"1\" src=\"file://%f\" width=\"%d\" height=\"%d\"",
					bf->filename_of_image_file, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
				WRITE("&nbsp;");
			} else {
				HTML_OPEN_WITH("div", "style=\"width:%dpx; height:%dpx; border:1px solid; background-color:#6495ed;\"",
					THUMBNAIL_WIDTH, THUMBNAIL_WIDTH*height/width);
				WRITE("&nbsp;");
				HTML_CLOSE("div");
			}

			HTML::next_html_column(OUT, 0);
			WRITE("%+W", bf->name);
			Index::link(OUT, Wordings::first_wn(bf->name));

			TEMPORARY_TEXT(rel)
			Filenames::to_text_relative(rel, bf->filename_of_image_file,
				Projects::materials_path(Task::project()));
			HTML_TAG("br");
			WRITE("%SFilename: \"%S\" - resource number %d", line2, rel, bf->figure_number);
			DISCARD_TEXT(rel)
			HTML::end_html_row(OUT);
			DISCARD_TEXT(line2)
		}
	}
	HTML::end_html_table(OUT);
	HTML_OPEN("p");
	if (count_of_displayed_figures > MAX_INDEXED_FIGURES) {
		WRITE("(Only the first %d thumbnails have been shown here, "
			"to avoid Inform taking up too much memory. If you'd like to "
			"see more, set 'Use index figure thumbnails of at least %d.', or "
			"whatever number you want to wait for.)",
			MAX_INDEXED_FIGURES, 10*MAX_INDEXED_FIGURES);
		HTML_CLOSE("p");
	}
}
