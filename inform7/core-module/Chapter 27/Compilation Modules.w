[Modules::] Compilation Modules.

@ =
typedef struct compilation_module {
	struct inter_namespace *namespace;
	struct package_request *resources;
	struct subpackage_requests subpackages;
	struct parse_node *hanging_from;
	MEMORY_MANAGEMENT
} compilation_module;

compilation_module *pool_module = NULL;
compilation_module *SR_module = NULL;

@ =
void Modules::traverse_to_define(void) {
	pool_module = Modules::new(NULL);
	ParseTree::traverse(Modules::look_for_cu);
}

void Modules::look_for_cu(parse_node *p) {
	if (ParseTree::get_type(p) == HEADING_NT) {
		heading *h = ParseTree::get_embodying_heading(p);
		if ((h) && (h->level == 0)) {
			compilation_module *cm = Modules::new(p);
			if (SR_module == NULL) SR_module = cm;
		}
	}
}

compilation_module *Modules::new(parse_node *from) {
	extension_file *owner = NULL;
	if ((from) && (Wordings::nonempty(ParseTree::get_text(from)))) {
		source_location sl = Wordings::location(ParseTree::get_text(from));
		if (sl.file_of_origin == NULL) owner = standard_rules_extension;
		else owner = SourceFiles::get_extension_corresponding(
			Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(from))));
	}
	if ((owner == NULL) && (pool_module != NULL)) return pool_module;

	compilation_module *C = CREATE(compilation_module);
	C->hanging_from = from;
	C->resources = NULL;
	if (C->allocation_id == 0) C->namespace = InterNames::root();
	else {
		if (from == NULL) internal_error("unlocated CM");
		if (Modules::markable(from) == FALSE) internal_error("inappropriate CM");
		TEMPORARY_TEXT(pfx);
		char *x = "";
		if ((C->allocation_id == 1) && (export_mode)) x = "x";
		WRITE_TO(pfx, "m%s%d", x, C->allocation_id);
		C->namespace = InterNames::new_namespace(pfx);
		Str::clear(C->namespace->unmarked_prefix);
		WRITE_TO(C->namespace->unmarked_prefix, "m%d", C->allocation_id);
		DISCARD_TEXT(pfx);
		ParseTree::set_module(from, C);
		Modules::propagate_downwards(from->down, C);
	}

	TEMPORARY_TEXT(PN);
	if (owner == standard_rules_extension) WRITE_TO(PN, "standard_rules");
	else if (owner == NULL) WRITE_TO(PN, "source_text");
	else {
		WRITE_TO(PN, "%X", Extensions::Files::get_eid(owner));
		LOOP_THROUGH_TEXT(pos, PN)
			if (Str::get(pos) == ' ')
				Str::put(pos, '_');
			else
				Str::put(pos, Characters::tolower(Str::get(pos)));
	}
	inter_name *package_iname = InterNames::one_off(PN, Packaging::request_resources());
	DISCARD_TEXT(PN);
	C->resources = Packaging::request(package_iname, Packaging::request_resources(), module_ptype);
	Packaging::initialise_subpackages(&(C->subpackages));

	return C;
}

subpackage_requests *Modules::subpackages(compilation_module *C) {
	if (C == NULL) internal_error("no module");
	return &(C->subpackages);
}

void Modules::propagate_downwards(parse_node *P, compilation_module *C) {
	while (P) {
		if (Modules::markable(P)) ParseTree::set_module(P, C);
		Modules::propagate_downwards(P->down, C);
		P = P->next;
	}
}

compilation_module *Modules::find(parse_node *from) {
	if (from == NULL) return NULL;
	if (Modules::markable(from)) return ParseTree::get_module(from);
	return pool_module;
}

int Modules::markable(parse_node *from) {
	if (from == NULL) return FALSE;
	if ((ParseTree::get_type(from) == ROOT_NT) ||
		(ParseTree::get_type(from) == HEADING_NT) ||
		(ParseTree::get_type(from) == SENTENCE_NT) ||
		(ParseTree::get_type(from) == ROUTINE_NT)) return TRUE;
	return FALSE;
}

compilation_module *current_CM = NULL;

compilation_module *Modules::current_or_null(void) {
	if (current_CM) return current_CM;
	return NULL;
}

compilation_module *Modules::current(void) {
	if (current_CM) return current_CM;
	return pool_module;
}

void Modules::set_current_to_SR(void) {
	if (SR_module == NULL) internal_error("too soon");
	current_CM = SR_module;
}

compilation_module *Modules::SR(void) {
	return SR_module;
}

void Modules::set_current_to(compilation_module *CM) {
	current_CM = CM;
}

void Modules::set_current(parse_node *P) {
	if (P) current_CM = Modules::find(P);
	else current_CM = NULL;
}
