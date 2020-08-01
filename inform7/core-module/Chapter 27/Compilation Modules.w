[CompilationUnits::] Compilation Units.

To identify which parts of the source text come from which source (the main source
text, the Standard Rules, or another extension).

@ Inform is a language in which it is semantically relevant which source file the
source text is coming from: unlike, say, C, where |#include| allows files to include
each other in arbitrary ways. In Inform, all source text comes from one of the
following places:

(a) The main source text, as shown in the Source panel of the UI app;
(b) An extension file, including the Standard Rules extension;
(c) Invented text created by the compiler itself.

The Inter hierarchy also splits, with named units representing each possibility
in (a) or (b) above. This section of code determines to which unit any new
definition (of, say, a property or kind) belongs.

=
compilation_unit *source_text_unit = NULL; /* the one for the main text */

@ We find these by performing a traverse of the parse tree, and looking for
level-0 headings, which are the nodes from which these blocks of source text hang:

=
void CompilationUnits::determine(void) {
	SyntaxTree::traverse(Task::syntax_tree(), CompilationUnits::look_for_cu);
}

void CompilationUnits::look_for_cu(parse_node *p) {
	if (Node::get_type(p) == HEADING_NT) {
		heading *h = Headings::from_node(p);
		if ((h) && (h->level == 0)) CompilationUnits::new(p);
	}
}

compilation_unit *CompilationUnits::new(parse_node *from) {
	source_location sl = Wordings::location(Node::get_text(from));
	if (sl.file_of_origin == NULL) return NULL;
	inform_extension *owner = Extensions::corresponding_to(
		Lexer::file_of_origin(Wordings::first_wn(Node::get_text(from))));

	compilation_unit *C = Packaging::new_cu();
	C->hanging_from = from;
	Node::set_unit(from, C);
	CompilationUnits::propagate_downwards(from->down, C);

	TEMPORARY_TEXT(pname)
	@<Compose a name for the unit package this will lead to@>;
	C->inter_presence = Packaging::get_unit(Emit::tree(), pname);
	DISCARD_TEXT(pname)

	if (owner) {
		Hierarchy::markup(C->inter_presence->the_package, EXT_AUTHOR_HMD, owner->as_copy->edition->work->raw_author_name);
		Hierarchy::markup(C->inter_presence->the_package, EXT_TITLE_HMD, owner->as_copy->edition->work->raw_title);
		TEMPORARY_TEXT(V)
		semantic_version_number N = owner->as_copy->edition->version;
		WRITE_TO(V, "%v", &N);
		Hierarchy::markup(C->inter_presence->the_package, EXT_VERSION_HMD, V);
		DISCARD_TEXT(V)
	}

	if (owner == NULL) source_text_unit = C;
	return C;
}

@ Here we must find a unique name, valid as an Inter identifier: the code
compiled from the compilation unit will go into a package of that name.

@<Compose a name for the unit package this will lead to@> =
	if (Extensions::is_standard(owner)) WRITE_TO(pname, "standard_rules");
	else if (owner == NULL) WRITE_TO(pname, "source_text");
	else {
		WRITE_TO(pname, "%X", owner->as_copy->edition->work);
		LOOP_THROUGH_TEXT(pos, pname)
			if (Str::get(pos) == ' ')
				Str::put(pos, '_');
			else
				Str::put(pos, Characters::tolower(Str::get(pos)));
	}

@ We are eventually going to need to be able to look at a given node in the parse
tree and say which compilation unit it belongs to. If there were a fast way
to go up in the tree, that would be easy -- we could simply run upward until we
reach a level-0 heading. But the node links all run downwards. Instead, we'll
"mark" nodes in the tree, annotating them with the compilation unit which owns
them. This is done by "propagating downwards", as follows.

@ =
void CompilationUnits::propagate_downwards(parse_node *P, compilation_unit *C) {
	while (P) {
		Node::set_unit(P, C);
		CompilationUnits::propagate_downwards(P->down, C);
		P = P->next;
	}
}

@ As promised, then, given a parse node, we have to return its compilation unit:
but that's now easy, as we just have to read off the annotation made above --

=
compilation_unit *CompilationUnits::find(parse_node *from) {
	if (from == NULL) return NULL;
	return Node::get_unit(from);
}

@h Current unit.
Inform has a concept of the "current unit" it's working on, much as it has
a concept of "current sentence".

=
compilation_unit *current_CM = NULL;

compilation_unit *CompilationUnits::current(void) {
	return current_CM;
}

void CompilationUnits::set_current_to(compilation_unit *CM) {
	current_CM = CM;
}

void CompilationUnits::set_current(parse_node *P) {
	if (P) current_CM = CompilationUnits::find(P);
	else current_CM = NULL;
}

@h Relating to Inter.
Creating the necessary package, of type |_module|, is the work of the
Packaging code.

=
module_package *CompilationUnits::inter_presence(compilation_unit *C) {
	if (C == NULL) internal_error("no unit");
	return C->inter_presence;
}
