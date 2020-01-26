[Kits::] Kits.

A kit is a combination of Inter code with an Inform 7 extension.

@h Kits.

=
typedef struct inform_kit {
	struct text_stream *name;
	struct inter_library *lib;
	struct text_stream *early_source;
	struct linked_list *ittt; /* of |inform_kit_ittt| */
	struct linked_list *kind_definitions; /* of |text_stream| */
	int priority;
	MEMORY_MANAGEMENT
} inform_kit;

typedef struct inform_kit_ittt {
	struct text_stream *if_name;
	int if_included;
	struct text_stream *then_name;
	MEMORY_MANAGEMENT
} inform_kit_ittt;

inform_kit *Kits::load(text_stream *name) {
	inform_kit *K = CREATE(inform_kit);
	K->name = Str::duplicate(name);
	K->lib = CodeGen::Libraries::find(name, NO_FS_AREAS, pathname_of_inter_resources);
	if (K->lib == NULL) {
		WRITE_TO(STDERR, "Cannot find kit '%S'\n", name);
		Problems::Fatal::issue("Unable to find one of the Inform support kits");
	}
	K->early_source = NULL;
	K->priority = 10;
	K->ittt = NEW_LINKED_LIST(inform_kit_ittt);
	K->kind_definitions = NEW_LINKED_LIST(text_stream);
	
	pathname *P = CodeGen::Libraries::location(K->lib);
	filename *F = Filenames::in_folder(P, I"kit_metadata.txt");
	TextFiles::read(F, FALSE,
		NULL, FALSE, Kits::read_metadata, NULL, (void *) K);

	return K;
}

void Kits::dependency(inform_kit *K, text_stream *if_text, int inc, text_stream *then_text) {
	inform_kit_ittt *ITTT = CREATE(inform_kit_ittt);
	ITTT->if_name = Str::duplicate(if_text);
	ITTT->if_included = inc;
	ITTT->then_name = Str::duplicate(then_text);
	ADD_TO_LINKED_LIST(ITTT, inform_kit_ittt, K->ittt);
}

void Kits::read_metadata(text_stream *text, text_file_position *tfp, void *state) {
	inform_kit *K = (inform_kit *) state;
	match_results mr = Regexp::create_mr();
	if ((Str::is_whitespace(text)) || (Regexp::match(&mr, text, L" *#%c*"))) {
		;
	} else if (Regexp::match(&mr, text, L"insert: (%c*)")) {
		K->early_source = Str::duplicate(mr.exp[0]);
		WRITE_TO(K->early_source, "\n\n");
	} else if (Regexp::match(&mr, text, L"priority: (%d*)")) {
		K->priority = Str::atoi(mr.exp[0], 0);
	} else if (Regexp::match(&mr, text, L"kinds: (%C+)")) {
		ADD_TO_LINKED_LIST(Str::duplicate(mr.exp[0]), text_stream, K->kind_definitions);
	} else if (Regexp::match(&mr, text, L"dependency: if (%C+) then (%C+)")) {
		Kits::dependency(K, mr.exp[0], TRUE, mr.exp[1]);
	} else if (Regexp::match(&mr, text, L"dependency: if not (%C+) then (%C+)")) {
		Kits::dependency(K, mr.exp[0], FALSE, mr.exp[1]);
	} else {
		Errors::in_text_file("illegible line in kit metadata file", tfp);
	}
	Regexp::dispose_of(&mr);
}

int Kits::loaded(text_stream *name) {
	inform_kit *K;
	LOOP_OVER(K, inform_kit)
		if (Str::eq(K->name, name))
			return TRUE;
	return FALSE;
}

void Kits::perform_ittt(void) {
	int changes_made = TRUE;
	while (changes_made) {
		changes_made = FALSE;
		inform_kit *K;
		LOOP_OVER(K, inform_kit) {
			inform_kit_ittt *ITTT;
			LOOP_OVER_LINKED_LIST(ITTT, inform_kit_ittt, K->ittt)
				if ((Kits::loaded(ITTT->then_name) == FALSE) &&
					(Kits::loaded(ITTT->if_name) == ITTT->if_included)) {
					Kits::load(ITTT->then_name);
					changes_made = TRUE;
				}
		}
	}
}

linked_list *kits_to_include = NULL;

void Kits::determine(void) {
	Kits::load(I"basic_inform");
	if (CoreMain::basic_mode() == FALSE) Kits::load(I"standard_rules");
	Kits::perform_ittt();

	kits_to_include = NEW_LINKED_LIST(inform_kit);
	for (int p=0; p<100; p++) {
		inform_kit *K;
		LOOP_OVER(K, inform_kit)
			if (K->priority == p)
				ADD_TO_LINKED_LIST(K, inform_kit, kits_to_include);
	}
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, kits_to_include)
		LOG("Using Inform kit '%S' (priority %d).\n", K->name, K->priority);
}

void Kits::load_types(void) {
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, kits_to_include) {
		text_stream *segment;
		LOOP_OVER_LINKED_LIST(segment, text_stream, K->kind_definitions) {
			pathname *P = CodeGen::Libraries::location(K->lib);
			P = Pathnames::subfolder(P, I"kinds");
			filename *F = Filenames::in_folder(P, segment);
			LOG("Loading kinds definitions from %f\n", F);
			I6T::interpret_kindt(F);
		}
	}
}

@ In particular, every source text read into Inform is automatically prefixed by
the following eight words -- if Inform were a computer, this would be the BIOS
which boots up its operating system. (In that the rest of the creation of the
I7 world model is handled by source text in the Standard Rules.)

Because of this mandatory insertion, one extension, the Standard Rules, is
compulsorily included in every run. So there will certainly be at least two
files of source text to be read, and quite possibly more.

@d MANDATORY_INSERTED_TEXT L"Include Basic Inform by Graham Nelson. Include the Standard Rules by Graham Nelson.\n\n"
@d BASIC_MODE_INSERTED_TEXT L"Include Basic Inform by Graham Nelson.\n\n"

=
void Kits::feed_early_source_text(void) {
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, kits_to_include)
		if (K->early_source)
			Feeds::feed_stream(K->early_source);
}

linked_list *requirements_list = NULL;
linked_list *Kits::list_of_inter_libraries(void) {
	requirements_list = NEW_LINKED_LIST(inter_library);
	inform_kit *K;
	LOOP_OVER_LINKED_LIST(K, inform_kit, kits_to_include)
		ADD_TO_LINKED_LIST(K->lib, inter_library, requirements_list);
	return requirements_list;
}
