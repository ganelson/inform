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

(2) The //index// module probably works fine if multiple sessions are open at
once (and indeed is probably threadsafe), but it hasn't been tested for that
or written with that in mind: a safer way to make multiple indexes simultaneously
is probably to run multiple independent |inter| processes, each making one index.

@ So, then, opening:

=
index_session *Indexing::open_session(inter_tree *I) {
	return Indexing::new_session(I);
}

@ Now localising. You can either set an existing dictionary which you happen
to have to hand, or else ask to read definitions from a file. See //html: Localisation//
for how all of this works.

=
void Indexing::set_localisation_dictionary(index_session *session, localisation_dictionary *LD) {
	@<Check this is an open session@>;
	session->localisation = LD;
}

void Indexing::localise(index_session *session, filename *F) {
	@<Check this is an open session@>;
	Localisation::stock_from_file(F, session->localisation);
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
of this. This is written to the stream |F_alt| if that is non-null, and otherwise
into a text file at |F| (which is created in the process).

=
void Indexing::generate_EPS_map(index_session *session, filename *F, text_stream *F_alt) {
	@<Check this is an open session@>;
	RenderEPSMap::render_map_as_EPS(F, F_alt, session);
}

@ And lastly closing. The only thing this now does is to enable a new session
to be opened afterwards, in fact, but that might change in future.

=
void Indexing::close_session(index_session *session) {
	@<Check this is an open session@>;
	session->session_closed = TRUE;
}

@<Check this is an open session@> =
	if (session == NULL) internal_error("no indexing session");
	if (session->session_closed) internal_error("closed indexing session");

@h Sessions.
This is a miscellany, plain and simple, but it contains all of the workspace
and caches needed to index an Inter tree.

=
typedef struct index_session {
	struct inter_tree *tree;
	struct tree_inventory *inv;
	struct inter_lexicon *lexicon;
	struct faux_instance_set *set_of_instances;
	struct linked_list *list_of_scenes; /* of |simplified_scene| */
	struct localisation_dictionary *localisation;
	struct linked_list *list_of_EPS_map_levels; /* of |EPS_map_level| */
	struct linked_list *list_of_submaps; /* of |connected_submap| */
	struct linked_list *list_of_pages; /* of |index_page| */
	struct map_parameter_scope global_map_scope;
	int changed_global_room_colour;
	struct index_page_data page;
	struct map_calculation_data calc;
	int story_dir_to_page_dir[MAX_DIRECTIONS];
	int session_closed;
	CLASS_DEFINITION
} index_session;

@ =
index_session *Indexing::new_session(inter_tree *I) {
	if (I == NULL) internal_error("no tree to index");
	index_session *session = CREATE(index_session);
	session->tree = I;
	session->inv = MakeSynopticModuleStage::take_inventory(I);
	session->lexicon = NULL;
	session->set_of_instances = NULL;
	session->list_of_scenes = NULL;
	session->list_of_EPS_map_levels = NEW_LINKED_LIST(EPS_map_level);
	session->list_of_submaps = NEW_LINKED_LIST(connected_submap);
	session->list_of_pages = NEW_LINKED_LIST(index_page);
	session->localisation = Localisation::new();
	session->global_map_scope = ConfigureIndexMap::global_settings();
	session->changed_global_room_colour = FALSE;
	session->calc = SpatialMap::fresh_data();
	session->session_closed = FALSE;
	for (int i=0; i<MAX_DIRECTIONS; i++)
		session->story_dir_to_page_dir[i] = i;
	return session;
}

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
	return session->localisation;
}

tree_inventory *Indexing::get_inventory(index_session *session) {
	@<Check this is an open session@>;
	return session->inv;
}

map_parameter_scope *Indexing::get_global_map_scope(index_session *session) {
	return &(session->global_map_scope);
}

@ These build up gradually:

=
linked_list *Indexing::get_list_of_EPS_map_levels(index_session *session) {
	@<Check this is an open session@>;
	return session->list_of_EPS_map_levels;
}

void Indexing::add_EPS_map_levels(index_session *session, EPS_map_level *eml) {
	@<Check this is an open session@>;
	ADD_TO_LINKED_LIST(eml, EPS_map_level, session->list_of_EPS_map_levels);
}

linked_list *Indexing::get_list_of_submaps(index_session *session) {
	@<Check this is an open session@>;
	return session->list_of_submaps;
}

void Indexing::add_submap(index_session *session, connected_submap *sub) {
	@<Check this is an open session@>;
	ADD_TO_LINKED_LIST(sub, connected_submap, session->list_of_submaps);
}

void Indexing::empty_list_of_pages(index_session *session) {
	@<Check this is an open session@>;
	LinkedLists::empty(session->list_of_pages);
}

linked_list *Indexing::get_list_of_pages(index_session *session) {
	@<Check this is an open session@>;
	return session->list_of_pages;
}

void Indexing::add_page(index_session *session, index_page *page) {
	@<Check this is an open session@>;
	ADD_TO_LINKED_LIST(page, index_page, session->list_of_pages);
}

index_page *Indexing::latest_page(index_session *session) {
	@<Check this is an open session@>;
	if (LinkedLists::len(session->list_of_pages) == 0) return NULL;
	return LAST_IN_LINKED_LIST(index_page, session->list_of_pages);
}

@ These more substantial resources are calculated all in one go, but only on demand:

=
inter_lexicon *Indexing::get_lexicon(index_session *session) {
	@<Check this is an open session@>;
	if (session->lexicon == NULL)
		session->lexicon = IndexLexicon::stock(session->tree, session->inv);
	return session->lexicon;
}

faux_instance_set *Indexing::get_set_of_instances(index_session *session) {
	@<Check this is an open session@>;
	if (session->set_of_instances == NULL) FauxInstances::make_faux(session);
	return session->set_of_instances;
}

linked_list *Indexing::get_list_of_scenes(index_session *session) {
	@<Check this is an open session@>;
	if (session->list_of_scenes == NULL) FauxScenes::list_of_faux_scenes(session);
	return session->list_of_scenes;
}
