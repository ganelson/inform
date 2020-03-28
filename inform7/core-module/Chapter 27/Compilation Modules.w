[Modules::] Compilation Modules.

To identify which parts of the source text come from which source (the main source
text, the Standard Rules, or another extension).

@h Compilation modules.
Inform is a language in which it is semantically relevant which source file the
source text is coming from: unlike, say, C, where |#include| allows files to include
each other in arbitrary ways. In Inform, all source text comes from one of the
following places:

(a) The main source text, as shown in the Source panel of the UI app;
(b) An extension file, including the Standard Rules extension;
(c) Invented text created by the compiler itself.

The Inter hierarchy also splits, with named modules representing each possibility
in (a) or (b) above. This section of code determines to which module any new
definition (of, say, a property or kind) belongs.

=
compilation_module *source_text_module = NULL; /* the one for the main text */
compilation_module *SR_module = NULL; /* the one for the Standard Rules */

compilation_module *Modules::SR(void) {
	return SR_module;
}

@ We find these by performing a traverse of the parse tree, and looking for
level-0 headings, which are the nodes from which these blocks of source text hang:

=
void Modules::traverse_to_define(void) {
	ParseTree::traverse(Task::syntax_tree(), Modules::look_for_cu);
}

void Modules::look_for_cu(parse_node *p) {
	if (ParseTree::get_type(p) == HEADING_NT) {
		heading *h = Headings::from_node(p);
		if ((h) && (h->level == 0)) Modules::new(p);
	}
}

compilation_module *Modules::new(parse_node *from) {
	source_location sl = Wordings::location(ParseTree::get_text(from));
	if (sl.file_of_origin == NULL) internal_error("null foo");
	inform_extension *owner = Extensions::corresponding_to(
		Lexer::file_of_origin(Wordings::first_wn(ParseTree::get_text(from))));

	compilation_module *C = Packaging::new_cm();
	C->hanging_from = from;
	ParseTree::set_module(from, C);
	Modules::propagate_downwards(from->down, C);

	TEMPORARY_TEXT(pname);
	@<Compose a name for the module package this will lead to@>;
	C->inter_presence = Packaging::get_module(Emit::tree(), pname);
	DISCARD_TEXT(pname);

	if (owner) {
		Hierarchy::markup(C->inter_presence->the_package, EXT_AUTHOR_HMD, owner->as_copy->edition->work->raw_author_name);
		Hierarchy::markup(C->inter_presence->the_package, EXT_TITLE_HMD, owner->as_copy->edition->work->raw_title);
		TEMPORARY_TEXT(V);
		semantic_version_number N = owner->as_copy->edition->version;
		WRITE_TO(V, "%v", &N);
		Hierarchy::markup(C->inter_presence->the_package, EXT_VERSION_HMD, V);
		DISCARD_TEXT(V);
	}

	if (Extensions::is_standard(owner)) SR_module = C;
	if (owner == NULL) source_text_module = C;
	return C;
}

@ Here we must find a unique name, valid as an Inter identifier: the code
compiled from the compilation module will go into a package of that name.

@<Compose a name for the module package this will lead to@> =
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
tree and say which compilation module it belongs to. If there were a fast way
to go up in the tree, that would be easy -- we could simply run upward until we
reach a level-0 heading. But the node links all run downwards. Instead, we'll
"mark" nodes in the tree, annotating them with the compilation module which owns
them. This is done by "propagating downwards", as follows.

@ =
void Modules::propagate_downwards(parse_node *P, compilation_module *C) {
	while (P) {
		ParseTree::set_module(P, C);
		Modules::propagate_downwards(P->down, C);
		P = P->next;
	}
}

@ As promised, then, given a parse node, we have to return its compilation module:
but that's now easy, as we just have to read off the annotation made above --

=
compilation_module *Modules::find(parse_node *from) {
	if (from == NULL) return NULL;
	return ParseTree::get_module(from);
}

@h Current module.
Inform has a concept of the "current module" it's working on, much as it has
a concept of "current sentence".

=
compilation_module *current_CM = NULL;

compilation_module *Modules::current(void) {
	return current_CM;
}

void Modules::set_current_to(compilation_module *CM) {
	current_CM = CM;
}

void Modules::set_current(parse_node *P) {
	if (P) current_CM = Modules::find(P);
	else current_CM = NULL;
}

@h Relating to Inter.
Creating the necessary package, of type |_module|, is the work of the
Packaging code.

=
module_package *Modules::inter_presence(compilation_module *C) {
	if (C == NULL) internal_error("no module");
	return C->inter_presence;
}
