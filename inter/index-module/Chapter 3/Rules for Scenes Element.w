[RulesForScenesElement::] Rules for Scenes Element.

To write the Rules for Scenes element (RS) in the index.

@

=
void RulesForScenesElement::render(OUTPUT_STREAM) {
	inter_tree *I = Index::get_tree();
	tree_inventory *inv = Synoptic::inv(I);
	TreeLists::sort(inv->rulebook_nodes, Synoptic::module_order);

	HTML_OPEN("p"); WRITE("<b>The scene-changing machinery</b>"); HTML_CLOSE("p");
	IndexRules::index_rules_box(OUT, inv, I"Scene changing", NULL,
		IndexRules::find_rulebook(inv, I"scene_changing"), NULL, 1, FALSE);
	HTML_OPEN("p");
	Index::anchor(OUT, I"SRULES");
	WRITE("<b>General rules applying to scene changes</b>");
	HTML_CLOSE("p");
	IndexRules::index_rules_box(OUT, inv, I"When a scene begins", NULL,
		IndexRules::find_rulebook(inv, I"when_scene_begins"), NULL, 1, FALSE);
	IndexRules::index_rules_box(OUT, inv, I"When a scene ends", NULL,
		IndexRules::find_rulebook(inv, I"when_scene_ends"), NULL, 1, FALSE);
}
