[CompletionModule::] Completion Module.

The completion module contains material turning the collection of resources
into a playable work.

@ =
void CompletionModule::compile(void) {
	@<Version number constant@>;
	@<Semantic version number constant@>;
	@<Virtual machine metadata@>;
	@<Plugin usage@>;
	@<Memory economy metadata@>;
	@<Frame size@>;
	@<RNG seed@>;
	@<Max indexed thumbnails@>;
	@<Headings@>;
	@<Kit relative paths@>;
	@<Debugging log aspects@>;
	@<Copyright licences@>;
}

@ So, for example, these might be |10.1.0| and |10.1.0-alpha.1+6R84| respectively.

@<Version number constant@> =
	TEMPORARY_TEXT(vn)
	WRITE_TO(vn, "[[Version Number]]");
	inter_name *iname = Hierarchy::find(I7_VERSION_NUMBER_HL);
	Emit::text_constant(iname, vn);
	Hierarchy::make_available(iname);
	DISCARD_TEXT(vn)

@<Semantic version number constant@> =
	TEMPORARY_TEXT(svn)
	WRITE_TO(svn, "[[Semantic Version Number]]");
	inter_name *iname = Hierarchy::find(I7_FULL_VERSION_NUMBER_HL);
	Emit::text_constant(iname, svn);
	Hierarchy::make_available(iname);
	DISCARD_TEXT(svn)

@<Virtual machine metadata@> =
	target_vm *VM = Supervisor::current_vm();
	if (VM == NULL) internal_error("target VM not set yet");
	TEMPORARY_TEXT(vm)
	TargetVMs::write(vm, VM);
	inter_name *iname = Hierarchy::find(VM_MD_HL);
	Emit::text_constant(iname, vm);
	if (Str::len(VM->VM_image) > 0) {
		inter_name *iname = Hierarchy::find(VM_ICON_MD_HL);
		Emit::text_constant(iname, VM->VM_image);
	}
	DISCARD_TEXT(vm)

@<Plugin usage@> =
	TEMPORARY_TEXT(inc)
	TEMPORARY_TEXT(exc)
	Features::list(inc, TRUE, experimental_feature);
	Features::list(exc, FALSE, experimental_feature);
	inter_name *iname = Hierarchy::find(LANGUAGE_ELEMENTS_USED_MD_HL);
	Emit::text_constant(iname, inc);
	if (Str::len(exc) > 0) {
		inter_name *iname = Hierarchy::find(LANGUAGE_ELEMENTS_NOT_USED_MD_HL);
		Emit::text_constant(iname, exc);
	}
	DISCARD_TEXT(inc)
	DISCARD_TEXT(exc)

@<Memory economy metadata@> =	
	inter_name *iname = Hierarchy::find(MEMORY_ECONOMY_MD_HL);
	if (global_compilation_settings.memory_economy_in_force)
		Emit::numeric_constant(iname, 1);
	else
		Emit::numeric_constant(iname, 0);

@<Frame size@> =	
	inter_name *iname = Hierarchy::find(MAX_FRAME_SIZE_NEEDED_HL);
	Emit::numeric_constant(iname, (inter_ti) SharedVariables::size_of_largest_set());
	Hierarchy::make_available(iname);

@<RNG seed@> =
	inter_name *iname = Hierarchy::find(RNG_SEED_AT_START_OF_PLAY_HL);
	Emit::numeric_constant(iname, (inter_ti) Task::rng_seed());
	Hierarchy::make_available(iname);

@<Max indexed thumbnails@> =
	inter_name *iname = Hierarchy::find(MAX_INDEXED_FIGURES_HL);
	Emit::numeric_constant(iname,
		(inter_ti) global_compilation_settings.index_figure_thumbnails);

@<Kit relative paths@> =
	inform_project *proj = Task::project();
	kit_dependency *kd;
	LOOP_OVER_LINKED_LIST(kd, kit_dependency, proj->kits_to_include) {
		pathname *P = Pathnames::down(kd->kit->as_copy->location_if_path, I"RTPs");
		text_stream *name = kd->kit->as_copy->edition->work->title;
		TEMPORARY_TEXT(identifier)
		WRITE_TO(identifier, "%SRTPs", name);
		@<Define an RTP location for P with this name@>;
		DISCARD_TEXT(identifier)
	}

@<Define an RTP location for P with this name@> =
	TEMPORARY_TEXT(at)
	CompletionModule::write_RTP_path(at, P);
	package_request *pack = Hierarchy::completion_package(RTPS_HAP);
	inter_name *iname = Hierarchy::make_iname_in(RTP_SOURCE_HL, pack);
	InterNames::set_translation(iname, identifier);
	InterNames::clear_flag(iname, MAKE_NAME_UNIQUE_ISYMF);
	Emit::text_constant(iname, at);
	Hierarchy::make_available(iname);
	DISCARD_TEXT(at)

@<Debugging log aspects@> =
	for (int i=0; i<NO_DEFINED_DA_VALUES; i++) {
		debugging_aspect *da = &(the_debugging_aspects[i]);
		if (Str::len(da->unhyphenated_name) > 0) {
			package_request *pack = Hierarchy::completion_package(DEBUGGING_ASPECTS_HAP);
			Hierarchy::apply_metadata(pack, DEBUGGING_ASPECT_NAME_MD_HL,
				da->unhyphenated_name);
			Hierarchy::apply_metadata_from_number(pack, DEBUGGING_ASPECT_USED_MD_HL,
				(inter_ti) Log::aspect_switched_on(i));
		}
	}

@<Copyright licences@> =
	inter_name *iname = Hierarchy::find(COPYRIGHT_LICENCES_HL);
	TEMPORARY_TEXT(licences)
	LicenceDeclaration::describe(licences, I6_TEXT_LICENSESFORMAT);
	if (Str::len(licences) > 0) Emit::text_constant(iname, licences);
	else Emit::numeric_constant(iname, 0);
	Hierarchy::make_available(iname);
	
@ =
void CompletionModule::write_RTP_path(OUTPUT_STREAM, pathname *P) {
	inform_project *proj = Task::project();
	TEMPORARY_TEXT(P_text)
	WRITE_TO(P_text, "%/p", P);
	TEMPORARY_TEXT(M_text)
	WRITE_TO(M_text, "%/p", Projects::materials_path(proj));
	TEMPORARY_TEXT(I_text)
	if (Supervisor::installed_files())
		WRITE_TO(I_text, "%/p", Supervisor::installed_files());

	if (Str::begins_with(P_text, M_text)) {
		WRITE("MATERIALS/");
		Pathnames::to_text_relative_forward_slashed(OUT, Projects::materials_path(proj), P);
	} else if ((Str::len(I_text) > 0) && (Str::begins_with(P_text, I_text))) {
		WRITE("INTERNAL/");
		Pathnames::to_text_relative_forward_slashed(OUT, Supervisor::installed_files(), P);
	} else {
		WRITE("%S", P_text);
	}
	DISCARD_TEXT(P_text)
	DISCARD_TEXT(M_text)
	DISCARD_TEXT(I_text)
}

@ =
typedef struct heading_compilation_data {
	struct package_request *heading_package;
	struct inter_name *heading_ID;
	CLASS_DEFINITION
} heading_compilation_data;

heading_compilation_data CompletionModule::new_compilation_data(heading *h) {
	heading_compilation_data hcd;
	hcd.heading_package = NULL;
	hcd.heading_ID = NULL;
	return hcd;
}

int CompletionModule::has_heading_id(heading *h) {
	if (h == NULL) return FALSE;
	if (h->compilation_data.heading_ID == NULL) return FALSE;
	return TRUE;
}

inter_name *CompletionModule::heading_id(heading *h) {
	if (h->compilation_data.heading_ID == NULL) internal_error("heading ID not ready");
	return h->compilation_data.heading_ID;
}

typedef struct contents_entry {
	struct heading *heading_entered;
	struct contents_entry *next;
	CLASS_DEFINITION
} contents_entry;

@<Headings@> =
	CompletionModule::index_heading_recursively(
		NameResolution::pseudo_heading()->child_heading);
	contents_entry *ce;
	int min_positive_level = 10;
	LOOP_OVER(ce, contents_entry)
		if ((ce->heading_entered->level > 0) &&
			(ce->heading_entered->level < min_positive_level))
			min_positive_level = ce->heading_entered->level;
	
	LOOP_OVER(ce, contents_entry) {
		heading *h = ce->heading_entered;
		package_request *pack = Hierarchy::completion_package(HEADINGS_HAP);
		@<Write the details@>;
		Hierarchy::apply_metadata_from_number(pack, HEADING_INDEXABLE_MD_HL, 1);
		contents_entry *next_ce = NEXT_OBJECT(ce, contents_entry);
		if (h->level != 0)
			while ((next_ce) && (next_ce->heading_entered->level > ce->heading_entered->level))
				next_ce = NEXT_OBJECT(next_ce, contents_entry);
		int start_word = Wordings::first_wn(Node::get_text(ce->heading_entered->sentence_declaring));
		int end_word = (next_ce)?(Wordings::first_wn(Node::get_text(next_ce->heading_entered->sentence_declaring)))
			: (TextFromFiles::last_lexed_word(FIRST_OBJECT(source_file)));

		int N = 0;
		for (int i = start_word; i < end_word; i++)
			N += TextFromFiles::word_count(i);
		Hierarchy::apply_metadata_from_number(pack, HEADING_WORD_COUNT_MD_HL,
			(inter_ti) N);
		TEMPORARY_TEXT(OUT)
		@<Summarise all the objects and kinds created under the given heading@>;
		if (Str::len(OUT) > 0)
			Hierarchy::apply_metadata(pack, HEADING_SUMMARY_MD_HL, OUT);
		DISCARD_TEXT(OUT)
	}
	heading *h;
	LOOP_OVER(h, heading) {
		if (h->compilation_data.heading_package == NULL) {
			package_request *pack = Hierarchy::completion_package(HEADINGS_HAP);
			@<Write the details@>;
			Hierarchy::apply_metadata_from_number(pack, HEADING_INDEXABLE_MD_HL, 0);
		}
	}

@<Write the details@> =
	h->compilation_data.heading_package = pack;
	h->compilation_data.heading_ID = Hierarchy::make_iname_in(HEADING_ID_HL, pack);
	Emit::numeric_constant(h->compilation_data.heading_ID, 561);
	if (h->level == 0) {
		if (NUMBER_CREATED(contents_entry) == 1)
			Hierarchy::apply_metadata(pack, HEADING_TEXT_MD_HL, I"Source text");
		else
			Hierarchy::apply_metadata(pack, HEADING_TEXT_MD_HL, I"Preamble");
	} else {
		wording NW = Node::get_text(h->sentence_declaring);
		Hierarchy::apply_metadata_from_raw_wording(pack, HEADING_TEXT_MD_HL, NW);
		Hierarchy::apply_metadata_from_number(pack, HEADING_AT_MD_HL,
			(inter_ti) Wordings::first_wn(NW));
		<heading-name-hyphenated>(NW);
		Hierarchy::apply_metadata_from_number(pack, HEADING_PARTS_MD_HL,
			(inter_ti) <<r>>);
		switch (<<r>>) {
			case 1: {
				wording B = GET_RW(<heading-name-hyphenated>, 1);
				Hierarchy::apply_metadata_from_raw_wording(pack, HEADING_PART1_MD_HL, B);
				break;
			}
			case 2: {
				wording B = GET_RW(<heading-name-hyphenated>, 1);
				Hierarchy::apply_metadata_from_raw_wording(pack, HEADING_PART1_MD_HL, B);
				wording C = GET_RW(<heading-name-hyphenated>, 2);
				Hierarchy::apply_metadata_from_raw_wording(pack, HEADING_PART2_MD_HL, C);
				break;
			}
			case 3: {
				wording B = GET_RW(<heading-name-hyphenated>, 1);
				Hierarchy::apply_metadata_from_raw_wording(pack, HEADING_PART1_MD_HL, B);
				wording C = GET_RW(<heading-name-hyphenated>, 2);
				Hierarchy::apply_metadata_from_raw_wording(pack, HEADING_PART2_MD_HL, C);
				wording D = GET_RW(<heading-name-hyphenated>, 3);
				Hierarchy::apply_metadata_from_raw_wording(pack, HEADING_PART3_MD_HL, D);
				break;
			}
		}
	}
	Hierarchy::apply_metadata_from_number(pack, HEADING_LEVEL_MD_HL,
		(inter_ti) h->level);
	Hierarchy::apply_metadata_from_number(pack, HEADING_INDENTATION_MD_HL,
		(inter_ti) h->indentation);

@<Summarise all the objects and kinds created under the given heading@> =
	int c = 0;
	noun *nt;
	LOOP_OVER_NOUNS_UNDER(nt, h) {
		wording W = Nouns::nominative(nt, FALSE);
		if (Wordings::nonempty(W)) {
			if (c++ > 0) WRITE(", ");
			WRITE("%+W", W);
		}
	}

@ We index only headings of level 1 and up -- so, not the pseudo-heading or the
File (0) ones -- and which are not within any extensions -- so, are in the
primary source text written by the user.

=
int headings_indexed = 0;

void CompletionModule::index_heading_recursively(heading *h) {
	if (h == NULL) return;
	int show_heading = TRUE;
	heading *next = h->child_heading;
	if (next == NULL) next = h->next_heading;
	if ((next) &&
		(Extensions::corresponding_to(next->start_location.file_of_origin)))
		next = NULL;
	if (h->level == 0) {
		show_heading = FALSE;
		if ((headings_indexed == 0) &&
			((next == NULL) ||
				(Wordings::first_wn(Node::get_text(next->sentence_declaring)) !=
					Wordings::first_wn(Node::get_text(h->sentence_declaring)))))
			show_heading = TRUE;
	}
	if (Extensions::corresponding_to(h->start_location.file_of_origin))
		show_heading = FALSE;
	if (show_heading) {
		contents_entry *ce = CREATE(contents_entry);
		ce->heading_entered = h;
		headings_indexed++;
	}

	CompletionModule::index_heading_recursively(h->child_heading);
	CompletionModule::index_heading_recursively(h->next_heading);
}
