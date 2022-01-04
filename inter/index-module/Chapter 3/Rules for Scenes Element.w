[RulesForScenesElement::] Rules for Scenes Element.

To write the Rules for Scenes element (RS) in the index.

@

=
void RulesForScenesElement::render(OUTPUT_STREAM, index_session *session) {
	localisation_dictionary *LD = Indexing::get_localisation(session);
	tree_inventory *inv = Indexing::get_inventory(session);
	TreeLists::sort(inv->rulebook_nodes, MakeSynopticModuleStage::module_order);

	HTML_OPEN("p");
	Localisation::bold(OUT, LD, I"Index.Elements.RS.Machinery");
	HTML_CLOSE("p");

	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.RS.SceneChanging", NULL,
		IndexRules::find_rulebook(inv, I"scene_changing"), NULL, 1, FALSE, session);

	HTML_OPEN("p");
	IndexUtilities::anchor(OUT, I"SRULES");
	Localisation::bold(OUT, LD, I"Index.Elements.RS.General");
	HTML_CLOSE("p");

	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.RS.SceneBegins", NULL,
		IndexRules::find_rulebook(inv, I"when_scene_begins"), NULL, 1, FALSE, session);
	IndexRules::rulebook_box(OUT, inv, I"Index.Elements.RS.SceneEnds", NULL,
		IndexRules::find_rulebook(inv, I"when_scene_ends"), NULL, 1, FALSE, session);
}
