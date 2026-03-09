[SupervisorModule::] Supervisor Module.

Setting up the use of this module.

@ This section simply sets up the module in ways expected by //foundation//, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d SUPERVISOR_MODULE TRUE

@ Like all modules, this one must define a `start` and `end` function:

@e RESULTS_SORTING_MREASON
@e EXTENSIONS_CENSUS_DA
@e HEADINGS_DA

=
void SupervisorModule::start(void) {
	Memory::reason_name(RESULTS_SORTING_MREASON, "results sorting");
	Writers::register_writer('X', &Works::writer);
	Writers::register_writer('J', &Languages::log);
	Log::declare_aspect(EXTENSIONS_CENSUS_DA, U"extensions census", FALSE, FALSE);
	Log::declare_aspect(HEADINGS_DA, U"headings", FALSE, FALSE);
	Supervisor::start();
	@<Declare the tree annotations@>;
}
void SupervisorModule::end(void) {
}

@ This module uses `syntax`, and adds the following annotations to the
syntax tree.

@e embodying_heading_ANNOT /* `heading`: for parse nodes of headings */
@e inclusion_of_extension_ANNOT /* `inform_extension`: for parse nodes of headings */

=
DECLARE_ANNOTATION_FUNCTIONS(embodying_heading, heading)
MAKE_ANNOTATION_FUNCTIONS(embodying_heading, heading)
DECLARE_ANNOTATION_FUNCTIONS(inclusion_of_extension, inform_extension)
MAKE_ANNOTATION_FUNCTIONS(inclusion_of_extension, inform_extension)

@<Declare the tree annotations@> =
	Annotations::declare_type(embodying_heading_ANNOT,
		SupervisorModule::write_embodying_heading_ANNOT);
	Annotations::declare_type(inclusion_of_extension_ANNOT,
		SupervisorModule::write_inclusion_of_extension_ANNOT);

@ =
void SupervisorModule::write_embodying_heading_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_embodying_heading(p)) {
		heading *H = Node::get_embodying_heading(p);
		WRITE(" {under: H%d'%W'}", H->level, Node::get_text(H->sentence_declaring));
	}
}
void SupervisorModule::write_inclusion_of_extension_ANNOT(text_stream *OUT, parse_node *p) {
	if (Node::get_inclusion_of_extension(p)) {
		inform_extension *E = Node::get_inclusion_of_extension(p);
		WRITE(" {includes: ");
		Copies::write_copy(OUT, E->as_copy);
		WRITE(" }");
	}
}

@

@d STILL_MORE_ANNOTATION_PERMISSIONS_SYNTAX_CALLBACK SupervisorModule::grant_annotation_permissions

=
void SupervisorModule::grant_annotation_permissions(void) {
	Annotations::allow(HEADING_NT, embodying_heading_ANNOT);
	Annotations::allow(HEADING_NT, inclusion_of_extension_ANNOT);
}
