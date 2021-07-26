[Indexing::] Indexing API.

How the parent tool can ask for an Inter tree to be indexed.

@h Public API.
This is a large and complex module of code, but it really only does one thing,
and so it is simple to control. Other modules or tools should do this only by
calling the functions below.

To produce one or more index products (see below), first open a session; then
set its localisation -- essentially, choose what language it should be written
in; then call functions to make the actual products; and finally close the session.
Note that:

(1) If you want to index the same tree of code to two different languages, you
will need to do this as two sessions. However, an Index website and an EPS map
which are in the same language can both be made in the same session, and this
is more efficient than using two.

(2) Only one session can be open at a time. In some abstract sense it would be tidy
to make this whole module threadsafe, but in concrete terms, it's hard to see
what problem that would solve for anyone. If a user needs to make multiple
indexes simultaneously, the simplest way would be to start multiple |inter|
processes, each working on one project at a time. However, the API is designed
so that this decision could be reversed if we wanted to.

@ So, then, opening:

=
typedef struct index_session {
	struct inter_tree *tree;
	struct tree_inventory *inv;
	struct inter_lexicon *indexing_lexicon;
	struct faux_instance_set *indexing_fis;
	struct linked_list *indexing_fs;
	struct localisation_dictionary *dict;
	int session_closed;
	CLASS_DEFINITION
} index_session;

int index_sessions_open = 0;

index_session *Indexing::open_session(inter_tree *I) {
	if (I == NULL) internal_error("no tree to index");
	if (index_sessions_open++ > 0) internal_error("one indexing session at a time");
	index_session *session = CREATE(index_session);
	session->tree = I;
	session->inv = Synoptic::inv(I);
	session->indexing_lexicon = NULL;
	session->indexing_fis = NULL;
	session->indexing_fs = NULL;
	session->dict = Localisation::new();
	session->session_closed = FALSE;
	return session;
}

@ Now localising. You can either set an existing dictionary which you happen
to have to hand, or else ask to read definitions from a file. See //html: Localisation//
for how all of this works.

=
void Indexing::set_localisation_dictionary(index_session *session, localisation_dictionary *LD) {
	@<Check this is an open session@>;
	session->dict = LD;
}

void Indexing::localise(index_session *session, filename *F) {
	@<Check this is an open session@>;
	Localisation::stock_from_file(F, session->dict);
}

@ Now for the productive part. You can make an entire index mini-website with
the following function, which may generate several hundred HTML files. This is
what is used in the Inform GUI apps on every compilation.

=
void Indexing::generate_index_website(index_session *session, text_stream *structure) {
	@<Check this is an open session@>;
	InterpretIndex::generate(structure, session);
}

@ This is a one-off function for generating the content of an index element
(without its heading, or any HTML surround): it's used for unit-testing those
elements, but is never used by the Inform GUI app.

=
void Indexing::generate_one_element(index_session *session, text_stream *OUT, wording elt) {
	@<Check this is an open session@>;
	Elements::test_card(OUT, elt, session);
}

@ This is used by the Inform GUI apps to "release along with an EPS file".
Essentially it makes a print-suitable version of the Map element of the index,
though there are also many bells and whistles for customising the appearance
of this.

=
void Indexing::generate_EPS_map(index_session *session, filename *F) {
	@<Check this is an open session@>;
	RenderEPSMap::render_map_as_EPS(F, session);
}

@ And lastly closing. The only thing this now does is to enable a new session
to be opened afterwards, in fact, but that might change in future.

=
void Indexing::close_session(index_session *session) {
	@<Check this is an open session@>;
	session->session_closed = TRUE;
	index_sessions_open--;
}

@<Check this is an open session@> =
	if (session == NULL) internal_error("no indexing session");
	if (session->session_closed) internal_error("closed indexing session");

@h Private API.
The remaining functions in this section are for use only within the //index//
module.

=
inter_tree *Indexing::get_tree(index_session *session) {
	@<Check this is an open session@>;
	return session->tree;
}

localisation_dictionary *Indexing::get_localisation(index_session *session) {
	@<Check this is an open session@>;
	return session->dict;
}

tree_inventory *Indexing::get_inventory(index_session *session) {
	@<Check this is an open session@>;
	return session->inv;
}

@ These more substantial resources are calculated only on demand:

=
inter_lexicon *Indexing::get_lexicon(index_session *session) {
	@<Check this is an open session@>;
	if (session->indexing_lexicon == NULL)
		session->indexing_lexicon = IndexLexicon::stock(session->tree, session->inv);
	return session->indexing_lexicon;
}

faux_instance_set *Indexing::get_set_of_instances(index_session *session) {
	@<Check this is an open session@>;
	if (session->indexing_fis == NULL) FauxInstances::make_faux(session);
	return session->indexing_fis;
}

linked_list *Indexing::get_list_of_scenes(index_session *session) {
	@<Check this is an open session@>;
	if (session->indexing_fs == NULL)
		session->indexing_fs = FauxScenes::list_of_faux_scenes(session);
	return session->indexing_fs;
}
