[CompilationUnits::] Compilation Units.

The source text is divided into compilation units, and the material they lead
to is similarly divided up.

@h Units.
The source text is divided up into "compilation units". Each extension is its
own compilation unit, and so is the main source text. This demarcation is also
reflected in the Inter hierarchy, where each different compilation unit has its
own sub-hierarchy, a |module_request|.

=
typedef struct compilation_unit {
	struct module_request *to_module;
	struct parse_node *head_node;
	struct inter_name *extension_id;
	struct inform_extension *extension;
	CLASS_DEFINITION
} compilation_unit;

void CompilationUnits::log(compilation_unit *cu) {
	if (cu == NULL) LOG("<null>");
	else LOG("unit'%W'", Node::get_text(cu->head_node));
}

module_request *CompilationUnits::to_module_package(compilation_unit *C) {
	if (C == NULL) internal_error("no unit");
	return C->to_module;
}

@ The main source text, and the extensions included, are exactly the level-0
|HEADING_NT| nodes in the parse tree which correspond to files read in, so we
can find them easily enough. This is done very early in compilation: see
//core: How To Compile//.

=
void CompilationUnits::determine(void) {
	SyntaxTree::traverse(Task::syntax_tree(), CompilationUnits::look_for_cu);
}

void CompilationUnits::look_for_cu(parse_node *p) {
	if (Node::get_type(p) == HEADING_NT) {
		heading *h = Headings::from_node(p);
		if ((h) && (h->level == 0)) {
			source_location sl = Wordings::location(Node::get_text(p));
			if (sl.file_of_origin) @<Create a new compilation unit for this heading@>;
		}
	}
}

@<Create a new compilation unit for this heading@> =
	inform_extension *ext = Extensions::corresponding_to(
		Lexer::file_of_origin(Wordings::first_wn(Node::get_text(p))));

	TEMPORARY_TEXT(pname)
	@<Compose a name for the unit package this will lead to@>;
	module_request *M = LargeScale::module_request(Emit::tree(), pname);
	inter_name *id_iname = NULL;
	if (ext) id_iname = Hierarchy::make_iname_in(EXTENSION_ID_HL, M->where_found);
	@<Give M a category@>;
	DISCARD_TEXT(pname)

	compilation_unit *C = CREATE(compilation_unit);
	C->head_node = p;
	C->to_module = M;
	C->extension = ext;
	C->extension_id = id_iname;
	CompilationUnits::join(p, C);

	if (ext) @<Give M metadata indicating the source extension@>;

@<Give M a category@> =
	inter_ti cat = 1;
	if (ext) cat = 2;
	if (Extensions::is_standard(ext)) cat = 3;
	Hierarchy::apply_metadata_from_number(M->where_found, EXT_CATEGORY_MD_HL, cat);

@ The extension credit consists of a single line, with name, version number
and author; together with any "extra credit" asked for by the extension.

For timing reasons, we need to schedule an agent to make this later: that
allows us to read sentences like "Use authorial modesty" between now and then.

@<Give M metadata indicating the source extension@> =
	text_stream *desc = Str::new();
	WRITE_TO(desc, "extension metadata for %S", ext->as_copy->edition->work->raw_title);
	Sequence::queue(&CompilationUnits::compilation_agent,
		STORE_POINTER_compilation_unit(C), desc);

@ =
void CompilationUnits::compilation_agent(compilation_subtask *t) {
	compilation_unit *CU = RETRIEVE_POINTER_compilation_unit(t->data);
	inform_extension *ext = CU->extension;
	module_request *M = CU->to_module;
	Hierarchy::apply_metadata(M->where_found, EXT_AUTHOR_MD_HL,
		ext->as_copy->edition->work->raw_author_name);
	Hierarchy::apply_metadata(M->where_found, EXT_TITLE_MD_HL,
		ext->as_copy->edition->work->raw_title);
	TEMPORARY_TEXT(V)
	semantic_version_number N = ext->as_copy->edition->version;
	WRITE_TO(V, "%v", &N);
	Hierarchy::apply_metadata(M->where_found, EXT_VERSION_MD_HL, V);
	DISCARD_TEXT(V)
	Emit::numeric_constant(CU->extension_id, 0);
	TEMPORARY_TEXT(C)
	WRITE_TO(C, "%S", ext->as_copy->edition->work->raw_title);
	if (VersionNumbers::is_null(N) == FALSE) WRITE_TO(C, " version %v", &N);
	WRITE_TO(C, " by %S", ext->as_copy->edition->work->raw_author_name);
	if (Str::len(ext->extra_credit_as_lexed) > 0)
		WRITE_TO(C, " (%S)", ext->extra_credit_as_lexed);
	Hierarchy::apply_metadata(M->where_found, EXT_CREDIT_MD_HL, C);
	DISCARD_TEXT(C)
	if (Str::len(ext->extra_credit_as_lexed) > 0)
		Hierarchy::apply_metadata(M->where_found, EXT_EXTRA_CREDIT_MD_HL,
			ext->extra_credit_as_lexed);
	TEMPORARY_TEXT(the_author_name)
	WRITE_TO(the_author_name, "%S", ext->as_copy->edition->work->author_name);
	int self_penned = FALSE;
	if (BibliographicData::story_author_is(the_author_name)) self_penned = TRUE;
	inter_ti modesty = 1;
	if ((ext->authorial_modesty == FALSE) &&       /* if (1) extension doesn't ask to be modest */
		(Extensions::is_standard(ext) == FALSE) && /* and (2) it's not e.g. the Standard Rules */
		((general_authorial_modesty == FALSE) ||   /* and (3a) author doesn't ask to be modest, or */
			(self_penned == FALSE)))               /*     (3b) didn't write this extension */
		modesty = 0;
	Hierarchy::apply_metadata_from_number(M->where_found, EXT_MODESTY_MD_HL, modesty);
	Hierarchy::apply_metadata_from_number(M->where_found, EXT_WORD_COUNT_MD_HL,
		(inter_ti) TextFromFiles::total_word_count(ext->read_into_file));
	DISCARD_TEXT(the_author_name)
}

@ Here we must find a unique name, valid as an Inter identifier: the code
compiled from the compilation unit will go into a package of that name.

@<Compose a name for the unit package this will lead to@> =
	if (ext == NULL) {
		WRITE_TO(pname, "source_text");
	} else {
		WRITE_TO(pname, "%X", ext->as_copy->edition->work);
		LOOP_THROUGH_TEXT(pos, pname)
			if (Str::get(pos) == ' ')
				Str::put(pos, '_');
			else
				Str::put(pos, Characters::tolower(Str::get(pos)));
	}

@ For timing reasons, this second round of metadata -- which provides
cross-references between the compilation unit modules, to show which ones
caused which other ones to be included -- can only be written later. (It's
used only for indexing.)

=
void CompilationUnits::complete_metadata(void) {
	compilation_unit *C;
	LOOP_OVER(C, compilation_unit) {
		inform_extension *ext = C->extension;
		if (ext) {
			package_request *pack = C->to_module->where_found;
			Hierarchy::apply_metadata_from_number(pack, EXT_AT_MD_HL,
				(inter_ti) Wordings::first_wn(ext->body_text));
			parse_node *inc = Extensions::get_inclusion_sentence(ext);
			if (Wordings::nonempty(Node::get_text(inc))) {
				Hierarchy::apply_metadata_from_number(pack, EXT_INCLUDED_AT_MD_HL,
					(inter_ti) Wordings::first_wn(Node::get_text(inc)));
				inform_extension *owner = NULL;
				source_location sl = Wordings::location(Node::get_text(inc));
				if (sl.file_of_origin == NULL) owner = NULL;
				else owner = Extensions::corresponding_to(
					Lexer::file_of_origin(Wordings::first_wn(Node::get_text(inc))));
				if (owner) {
					inter_name *owner_id = CompilationUnits::extension_id(owner);
					if (owner_id)
						Hierarchy::apply_metadata_from_iname(pack,
							EXT_INCLUDED_BY_MD_HL, owner_id);
				} else {
					if (Lexer::word_location(Wordings::first_wn(Node::get_text(inc))).file_of_origin == NULL)
						Hierarchy::apply_metadata_from_number(pack, EXT_AUTO_INCLUDED_MD_HL, 1);
				}
			}
			if (Extensions::is_standard(ext))
				Hierarchy::apply_metadata_from_number(pack, EXT_STANDARD_MD_HL, 1);
		}
	}
}

@ This is in principle slow, and in practice fast, and anyway little used.

=
inter_name *CompilationUnits::extension_id(inform_extension *owner) {
	compilation_unit *owner_C;
	LOOP_OVER(owner_C, compilation_unit)
		if (owner_C->extension == owner)
			return owner_C->extension_id;
	return NULL;
}

@h What unit a node belongs to.
We are going to need to determine, for any node |p|, which compilation unit it
belongs to. If there were a fast way to go up in the syntax tree, that would be
easy -- we could simply run upward until we reach a level-0 heading. But the
node links all run downwards. Instead, we'll annotate the nodes in a given unit.
The annotations propagates downwards thus:

=
void CompilationUnits::join(parse_node *p, compilation_unit *C) {
	if (Node::get_unit(p) == NULL) {
		Node::set_unit(p, C);
		for (parse_node *d = p->down; d; d = d->next)
			CompilationUnits::join(d, C);
	}
}

@ Nodes are sometimes added later, so that it may be necessary to mark them
by hand as belonging to the same nodes as their progenitors:

=
void CompilationUnits::assign_to_same_unit(parse_node *to, parse_node *from) {
	CompilationUnits::join(to, Node::get_unit(from));
}

@ As promised, then, given a parse node, we have to return its compilation unit:
but that's now easy.

=
compilation_unit *CompilationUnits::find(parse_node *from) {
	if (from) return Node::get_unit(from);
	return NULL;
}
