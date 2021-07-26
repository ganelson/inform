[FauxScenes::] Faux Scenes.

Creating a simple graph of scenes, ends and connectors.

@ As with //Faux Instances//, we need to make faux scenes: these more or less
reconstruct the original data structures in Inform, though they are much less
annotated.

@d MAX_SCENE_ENDS 32 /* this must exceed 31 */

=
typedef struct simplified_scene {
	struct inter_package *pack;
	int no_ends;
	struct simplified_end *ends[MAX_SCENE_ENDS];
	int indexed_already;
	CLASS_DEFINITION
} simplified_scene;

typedef struct simplified_end {
	struct inter_package *end_pack;
	struct simplified_connector *anchor_connectors; /* linked list */
	CLASS_DEFINITION
} simplified_end;

typedef struct simplified_connector {
	struct inter_package *con_pack;
	struct simplified_scene *connect_to;
	struct simplified_connector *next; /* next in list of connectors for a scene end */
	CLASS_DEFINITION
} simplified_connector;

linked_list *FauxScenes::list_of_faux_scenes(index_session *session) {
	linked_list *L = NEW_LINKED_LIST(simplified_scene);
	inter_tree *I = Indexing::get_tree(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	TreeLists::sort(inv->scene_nodes, PlotElement::scene_order);
	TreeLists::sort(inv->rulebook_nodes, Synoptic::module_order);

	inter_package *scene_pack;
	LOOP_OVER_INVENTORY_PACKAGES(scene_pack, i, inv->scene_nodes)
		ADD_TO_LINKED_LIST(FauxScenes::simplified(I, scene_pack), simplified_scene, L);
	return L;
}	

simplified_scene *FauxScenes::simplified(inter_tree *I, inter_package *sc_pack) {
	simplified_scene *ssc = CREATE(simplified_scene);
	ssc->pack = sc_pack;
	ssc->no_ends = 0;
	ssc->indexed_already = FALSE;
	inter_package *end_pack;
	LOOP_THROUGH_SUBPACKAGES(end_pack, sc_pack, I"_scene_end") {
		simplified_end *se = CREATE(simplified_end);
		se->end_pack = end_pack;
		se->anchor_connectors = NULL;
		inter_package *con_pack;
		LOOP_THROUGH_SUBPACKAGES(con_pack, end_pack, I"_scene_connector") {
			simplified_connector *scon = CREATE(simplified_connector);
			scon->con_pack = con_pack;
			scon->next = NULL;
			if (se->anchor_connectors == NULL) {
				se->anchor_connectors = scon;
			} else {
				simplified_connector *last = se->anchor_connectors;
				while ((last) && (last->next)) last = last->next;
				last->next = scon;
			}
			scon->connect_to = NULL;
		}
		if (ssc->no_ends >= MAX_SCENE_ENDS) internal_error("too many scene ends");
		ssc->ends[ssc->no_ends++] = se;
	}
	return ssc;
}

int FauxScenes::is_entire_game(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^is_entire_game")) return TRUE;
	return FALSE;
}

int FauxScenes::recurs(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^recurs")) return TRUE;
	return FALSE;
}

int FauxScenes::never_ends(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^never_ends")) return TRUE;
	return FALSE;
}

int FauxScenes::starts_at_start_of_play(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^starts")) return TRUE;
	return FALSE;
}

int FauxScenes::starts_on_condition(simplified_scene *ssc) {
	if (Metadata::read_optional_numeric(ssc->pack, I"^starts_on_condition")) return TRUE;
	return FALSE;
}

int FauxScenes::no_ends(simplified_scene *ssc) {
	return ssc->no_ends;
}

text_stream *FauxScenes::scene_name(simplified_scene *ssc) {
	return Metadata::read_textual(ssc->pack, I"^name");
}

text_stream *FauxScenes::end_name(simplified_end *se) {
	return Metadata::read_textual(se->end_pack, I"^name");
}

text_stream *FauxScenes::anchor_condition(simplified_end *se) {
	return Metadata::read_textual(se->end_pack, I"^condition");
}

int FauxScenes::has_anchor_condition(simplified_end *se) {
	if (Str::len(FauxScenes::anchor_condition(se)) > 0) return TRUE;
	return FALSE;
}

int FauxScenes::anchor_condition_set_at(simplified_end *se) {
	return (int) Metadata::read_optional_numeric(se->end_pack, I"^at");
}

inter_symbol *FauxScenes::end_rulebook(simplified_end *se) {
	return Metadata::read_optional_symbol(se->end_pack, I"^rulebook");
}

simplified_scene *FauxScenes::connects_to(simplified_connector *scon) {
	if (scon->connect_to) return scon->connect_to;
	inter_symbol *sc_symbol = Metadata::read_optional_symbol(scon->con_pack, I"^to");
	if (sc_symbol) {
		inter_package *to_pack = Inter::Packages::container(sc_symbol->definition);
		simplified_scene *ssc;
		LOOP_OVER(ssc, simplified_scene)
			if (ssc->pack == to_pack) {
				scon->connect_to = ssc;
				return ssc;
			}
	}
	internal_error("scene metadata broken: bad connector");
	return NULL;
}

int FauxScenes::scon_end(simplified_connector *scon) {
	return (int) Metadata::read_numeric(scon->con_pack, I"^end");
}

int FauxScenes::scon_at(simplified_connector *scon) {
	return (int) Metadata::read_numeric(scon->con_pack, I"^at");
}
