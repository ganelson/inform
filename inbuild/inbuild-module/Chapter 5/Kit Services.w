[Kits::] Kits.

A kit is a combination of Inter code with an Inform 7 extension.

@h Genre definition.

=
typedef struct inform_kit {
	struct inbuild_copy *as_copy;
	struct text_stream *attachment_point;
	struct text_stream *early_source;
	struct linked_list *ittt; /* of |inform_kit_ittt| */
	struct linked_list *kind_definitions; /* of |text_stream| */
	struct linked_list *extensions; /* of |inbuild_requirement| */
	struct linked_list *activations; /* of |element_activation| */
	struct text_stream *index_template;
	int defines_Main;
	int supports_inform_language;
	int priority;
	MEMORY_MANAGEMENT
} inform_kit;

typedef struct inform_kit_ittt {
	struct text_stream *if_name;
	int if_included;
	struct text_stream *then_name;
	MEMORY_MANAGEMENT
} inform_kit_ittt;

typedef struct element_activation {
	struct text_stream *element_name;
	int activate;
	MEMORY_MANAGEMENT
} element_activation;

pathname *Kits::find(text_stream *name, linked_list *nest_list) {
	inbuild_nest *N;
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, nest_list) {
		pathname *P = KitManager::path_within_nest(N);
		P = Pathnames::subfolder(P, name);
		filename *F = Filenames::in_folder(P, I"kit_metadata.txt");
		if (TextFiles::exists(F)) return P;
	}
	return NULL;
}

void Kits::scan(inbuild_genre *G, inbuild_copy *C) {
	if (C == NULL) internal_error("no copy to scan");

	inform_kit *K = CREATE(inform_kit);
	K->as_copy = C;
	Copies::set_content(C, STORE_POINTER_inform_kit(K));
	K->attachment_point = Str::new();
	K->early_source = NULL;
	K->priority = 10;
	K->ittt = NEW_LINKED_LIST(inform_kit_ittt);
	K->kind_definitions = NEW_LINKED_LIST(text_stream);
	K->extensions = NEW_LINKED_LIST(inbuild_requirement);
	K->activations = NEW_LINKED_LIST(element_activation);
	K->defines_Main = FALSE;
	K->supports_inform_language = FALSE;
	K->index_template = NULL;

	filename *F = Filenames::in_folder(C->location_if_path, I"kit_metadata.txt");
	TextFiles::read(F, FALSE,
		NULL, FALSE, Kits::read_metadata, NULL, (void *) C);

	WRITE_TO(K->attachment_point, "/main/%S", C->edition->work->title);
}

void Kits::read_metadata(text_stream *text, text_file_position *tfp, void *state) {
	inbuild_copy *C = (inbuild_copy *) state;
	inform_kit *K = KitManager::from_copy(C);
	match_results mr = Regexp::create_mr();
	if ((Str::is_whitespace(text)) || (Regexp::match(&mr, text, L" *#%c*"))) {
		;
	} else if (Regexp::match(&mr, text, L"version: (%C+)")) {
		C->edition->version = VersionNumbers::from_text(mr.exp[0]);
	} else if (Regexp::match(&mr, text, L"compatibility: (%c+)")) {
		compatibility_specification *CS = Compatibility::from_text(mr.exp[0]);
		if (CS) C->edition->compatibility = CS;
		else {
			TEMPORARY_TEXT(err);
			WRITE_TO(err, "cannot read compatibility '%S'", mr.exp[0]);
			Copies::attach(C, Copies::new_error(KIT_MISWORDED_CE, err));
			DISCARD_TEXT(err);
		}
	} else if (Regexp::match(&mr, text, L"defines Main: yes")) {
		K->defines_Main = TRUE;
	} else if (Regexp::match(&mr, text, L"defines Main: no")) {
		K->defines_Main = FALSE;
	} else if (Regexp::match(&mr, text, L"natural language: yes")) {
		K->supports_inform_language = TRUE;
	} else if (Regexp::match(&mr, text, L"natural language: no")) {
		K->supports_inform_language = FALSE;
	} else if (Regexp::match(&mr, text, L"insert: (%c*)")) {
		K->early_source = Str::duplicate(mr.exp[0]);
		WRITE_TO(K->early_source, "\n\n");
	} else if (Regexp::match(&mr, text, L"priority: (%d*)")) {
		K->priority = Str::atoi(mr.exp[0], 0);
	} else if (Regexp::match(&mr, text, L"kinds: (%C+)")) {
		ADD_TO_LINKED_LIST(Str::duplicate(mr.exp[0]), text_stream, K->kind_definitions);
	} else if (Regexp::match(&mr, text, L"extension: (%c+) by (%c+)")) {
		inbuild_work *work = Works::new(extension_genre, mr.exp[0], mr.exp[1]);
		inbuild_requirement *req = Requirements::any_version_of(work);
		ADD_TO_LINKED_LIST(req, inbuild_requirement, K->extensions);
	} else if (Regexp::match(&mr, text, L"activate: (%c+)")) {
		Kits::activation(K, mr.exp[0], TRUE);
	} else if (Regexp::match(&mr, text, L"deactivate: (%c+)")) {
		Kits::activation(K, mr.exp[0], FALSE);
	} else if (Regexp::match(&mr, text, L"dependency: if (%C+) then (%C+)")) {
		Kits::dependency(K, mr.exp[0], TRUE, mr.exp[1]);
	} else if (Regexp::match(&mr, text, L"dependency: if not (%C+) then (%C+)")) {
		Kits::dependency(K, mr.exp[0], FALSE, mr.exp[1]);
	} else if (Regexp::match(&mr, text, L"index from: (%c*)")) {
		K->index_template = Str::duplicate(mr.exp[0]);
	} else {
		TEMPORARY_TEXT(err);
		WRITE_TO(err, "unreadable instruction '%S'", text);
		Copies::attach(C, Copies::new_error(KIT_MISWORDED_CE, err));
		DISCARD_TEXT(err);	
	}
	Regexp::dispose_of(&mr);
}

inform_kit *Kits::load(text_stream *name, linked_list *nest_list) {
	pathname *P = Kits::find(name, nest_list);
	if (P == NULL) Errors::fatal_with_text("cannot find kit", name);
	inbuild_copy *C = KitManager::new_copy(name, P);
	if (C->vertex == NULL) KitManager::build_vertex(C);
	return KitManager::from_copy(C);
}

void Kits::dependency(inform_kit *K, text_stream *if_text, int inc, text_stream *then_text) {
	inform_kit_ittt *ITTT = CREATE(inform_kit_ittt);
	ITTT->if_name = Str::duplicate(if_text);
	ITTT->if_included = inc;
	ITTT->then_name = Str::duplicate(then_text);
	ADD_TO_LINKED_LIST(ITTT, inform_kit_ittt, K->ittt);
}

void Kits::activation(inform_kit *K, text_stream *name, int act) {
	element_activation *EA = CREATE(element_activation);
	EA->element_name = Str::duplicate(name);
	EA->activate = act;
	ADD_TO_LINKED_LIST(EA, element_activation, K->activations);
}

int Kits::perform_ittt(inform_kit *K, inform_project *project, int parity) {
	int changes_made = FALSE;
	inform_kit_ittt *ITTT;
	LOOP_OVER_LINKED_LIST(ITTT, inform_kit_ittt, K->ittt)
		if ((ITTT->if_included == parity) &&
			(Projects::uses_kit(project, ITTT->then_name) == FALSE) &&
			(Projects::uses_kit(project, ITTT->if_name) == ITTT->if_included)) {
			Projects::add_kit_dependency(project, ITTT->then_name);
			changes_made = TRUE;
		}
	return changes_made;
}

#ifdef CORE_MODULE
void Kits::load_types(inform_kit *K) {
	text_stream *segment;
	LOOP_OVER_LINKED_LIST(segment, text_stream, K->kind_definitions) {
		pathname *P = Pathnames::subfolder(K->as_copy->location_if_path, I"kinds");
		filename *F = Filenames::in_folder(P, segment);
		LOG("Loading kinds definitions from %f\n", F);
		I6T::interpret_kindt(F);
	}
}
#endif

#ifdef CORE_MODULE
void Kits::activate_plugins(inform_kit *K) {
	element_activation *EA;
	LOOP_OVER_LINKED_LIST(EA, element_activation, K->activations) {
		int S = Plugins::Manage::parse(EA->element_name);
		if (S == -1)
			Problems::Issue::sentence_problem(_p_(Untestable),
				"one of the Inform kits made reference to a language segment which does not exist",
				"which strongly suggests that Inform is not properly installed.");
		if (S >= 0) {
			if (EA->activate) Plugins::Manage::activate(S);
			else Plugins::Manage::deactivate(S);
		}
	}
}
#endif

void Kits::early_source_text(OUTPUT_STREAM, inform_kit *K) {
	inbuild_requirement *req;
	LOOP_OVER_LINKED_LIST(req, inbuild_requirement, K->extensions)
		WRITE("Include %S by %S.\n\n", req->work->title, req->work->author_name);
	if (K->early_source) WRITE("%S\n\n", K->early_source);
}

linked_list *Kits::inter_paths(void) {
	linked_list *inter_paths = NEW_LINKED_LIST(pathname);
	inbuild_nest *N;
	linked_list *L = Inbuild::nest_list();
	LOOP_OVER_LINKED_LIST(N, inbuild_nest, L)
		ADD_TO_LINKED_LIST(KitManager::path_within_nest(N), pathname, inter_paths);
	return inter_paths;
}

@ The build graph for a kit is quite extensive, since a kit contains Inter
binaries for four different architectures; and each of those has a
dependency on every section file of the web of Inform 6 source for the kit.
If there are $S$ sections then the graph has $S+5$ vertices and $4(S+1)$ edges.

=
void Kits::construct_graph(inform_kit *K) {
	RUN_ONLY_IN_PHASE(GOING_OPERATIONAL_INBUILD_PHASE)
	if (K == NULL) return;
	inbuild_copy *C = K->as_copy;
	pathname *P = C->location_if_path;
	build_vertex *KV = C->vertex;
	linked_list *BVL = NEW_LINKED_LIST(build_vertex);	
	inter_architecture *A;
	LOOP_OVER(A, inter_architecture) {
		build_vertex *BV = Graphs::file_vertex(Architectures::canonical_binary(P, A));
		Graphs::need_this_to_build(KV, BV);
		BuildSteps::attach(BV, assimilate_using_inter_skill,
			Inbuild::nest_list(), FALSE, NULL, A, K->as_copy);
		ADD_TO_LINKED_LIST(BV, build_vertex, BVL);
	}

	filename *contents_page = Filenames::in_folder(C->location_if_path, I"Contents.w");
	build_vertex *CV = Graphs::file_vertex(contents_page);
	build_vertex *BV;
	LOOP_OVER_LINKED_LIST(BV, build_vertex, BVL)
		Graphs::need_this_to_build(BV, CV);

	kit_contents_section_state CSS;
	CSS.active = FALSE;
	CSS.sects = NEW_LINKED_LIST(text_stream);
	TextFiles::read(contents_page, FALSE, NULL, FALSE, KitManager::read_contents, NULL, (void *) &CSS);
	text_stream *segment;
	LOOP_OVER_LINKED_LIST(segment, text_stream, CSS.sects) {
		filename *SF = Filenames::in_folder(
			Pathnames::subfolder(C->location_if_path, I"Sections"), segment);
		build_vertex *SV = Graphs::file_vertex(SF);
		build_vertex *BV;
		LOOP_OVER_LINKED_LIST(BV, build_vertex, BVL)
			Graphs::need_this_to_build(BV, SV);
	}

	inbuild_requirement *req;
	LOOP_OVER_LINKED_LIST(req, inbuild_requirement, K->extensions) {
		build_vertex *EV = Graphs::req_vertex(req);
		Graphs::need_this_to_use(KV, EV);
	}
}
