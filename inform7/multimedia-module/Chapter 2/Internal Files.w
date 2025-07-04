[InternalFiles::] Internal Files.

To register the names associated with internal files, and build
the small I6 arrays associated with each.

@ The following is called to activate the feature:

=
void InternalFiles::start(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-function-pointer-types-strict"
	PluginCalls::plug(PRODUCTION_LINE_PLUG, InternalFiles::production_line);
	PluginCalls::plug(NEW_BASE_KIND_NOTIFY_PLUG, InternalFiles::files_new_base_kind_notify);
	PluginCalls::plug(NEW_INSTANCE_NOTIFY_PLUG, InternalFiles::files_new_named_instance_notify);
#pragma clang diagnostic pop
}

int InternalFiles::production_line(int stage, int debugging,
	stopwatch_timer *sequence_timer) {
	if (stage == INTER1_CSEQ) {
		BENCH(RTMultimedia::compile_internal_files);
	}
	return FALSE;
}

@h One significant kind.

= (early code)
kind *K_internal_file = NULL;

@ =
int InternalFiles::files_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, U"INTERNAL_FILE_TY")) {
		K_internal_file = new_base; return TRUE;
	}
	return FALSE;
}

@h Significant new instances.
This structure of additional data is attached to each figure instance.

=
typedef struct internal_files_data {
	struct wording name; /* text of name */
	int unextended_filename; /* word number of text like |"ice extents.usgs"| */
	struct filename *local_filename; /* of where this file is, in Materials directory */
	struct text_stream *inf_identifier; /* an Inter identifier */
	int file_format; /* |INTERNAL_TEXT_FILE_NFSMF| or |INTERNAL_BINARY_FILE_NFSMF| */
	struct instance *as_instance;
	struct parse_node *where_created;
	int resource_id;
	CLASS_DEFINITION
} internal_files_data;

@ We allow instances of "internal file" to be created only through the code
from //External Files// calling //InternalFiles::files_create//. If any other
proposition somehow manages to make a file, a problem message is thrown.

=
int allow_inf_creations = FALSE;

instance *InternalFiles::files_create(int format, wording W, wording FN) {
	allow_inf_creations = TRUE;
	Assert::true(Propositions::Abstract::to_create_something(K_internal_file, W), CERTAIN_CE);
	allow_inf_creations = FALSE;
	instance *I = Instances::latest();
	internal_files_data *ifd = FEATURE_DATA_ON_INSTANCE(internal_files, I);
	ifd->name = W;
	ifd->unextended_filename = Wordings::first_wn(FN);
	ifd->file_format = format;
	ifd->where_created = current_sentence;
	ifd->as_instance = I;
	ifd->resource_id = Task::get_next_free_blorb_resource_ID();
	TEMPORARY_TEXT(leaf)
	Word::dequote(Wordings::first_wn(FN));
	WRITE_TO(leaf, "%N", Wordings::first_wn(FN));
	ifd->local_filename = ResourceFinder::find_resource(Task::data_department(), leaf, FN);
	DISCARD_TEXT(leaf)
	return I;
}

int InternalFiles::files_new_named_instance_notify(instance *I) {
	if (K_internal_file == NULL) return FALSE;
	kind *K = Instances::to_kind(I);
	if (Kinds::eq(K, K_internal_file)) {
		if (allow_inf_creations == FALSE)
			StandardProblems::sentence_problem(Task::syntax_tree(),
				_p_(PM_BackdoorInternalFileCreation),
				"this is not the way to create a new internal file",
				"which should be done with a special 'The internal data file "
				"... is called ...' sentence.");
		ATTACH_FEATURE_DATA_TO_SUBJECT(internal_files, I->as_subject, CREATE(internal_files_data));
		return TRUE;
	}
	return FALSE;
}

@h Blurb and manifest.
The i-files manifest is used by the implementation of Glulx within the Inform
application to connect file ID numbers with filenames relative to the
|.materials| folder for its project. (It's part of the XML manifest file
created from |Figures.w|.)

=
void InternalFiles::write_files_manifest(OUTPUT_STREAM) {
	if (K_internal_file == NULL) return;
	internal_files_data *ifd;
	if (NUMBER_CREATED(internal_files_data) == 0) return;
	WRITE("<key>Data</key>\n");
	WRITE("<dict>\n"); INDENT;
	LOOP_OVER(ifd, internal_files_data) {
		WRITE("<key>%d</key>\n", ifd->resource_id);
		TEMPORARY_TEXT(rel)
		Filenames::to_text_relative(rel, ifd->local_filename,
			Projects::materials_path(Task::project()));
		WRITE("<string>%S</string>\n", rel);
		DISCARD_TEXT(rel)
	}
	OUTDENT; WRITE("</dict>\n");
}

@ The following writes Blurb commands for all of the internal files.

=
void InternalFiles::write_blurb_commands(OUTPUT_STREAM) {
	if (K_internal_file == NULL) return;
	internal_files_data *ifd;
	LOOP_OVER(ifd, internal_files_data) {
		WRITE("data %d \"%f\" type ", ifd->resource_id, ifd->local_filename);
		switch (ifd->file_format) {
			case INTERNAL_TEXT_FILE_NFSMF:   WRITE("TEXT"); break;
			case INTERNAL_BINARY_FILE_NFSMF: WRITE("BINA"); break;
		}
		WRITE("\n");
	}
}

