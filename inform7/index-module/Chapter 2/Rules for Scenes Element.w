[IXRulesForScenes::] Rules for Scenes Element.

The RS element.

@

=
void IXRulesForScenes::render(OUTPUT_STREAM) {
	HTML_OPEN("p"); WRITE("<b>The scene-changing machinery</b>"); HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "Scene changing", EMPTY_WORDING, NULL,
		Rulebooks::std(SCENE_CHANGING_RB), NULL, NULL, 1, FALSE);
	HTML_OPEN("p");
	Index::anchor(OUT, I"SRULES");
	WRITE("<b>General rules applying to scene changes</b>");
	HTML_CLOSE("p");
	IXRules::index_rules_box(OUT, "When a scene begins", EMPTY_WORDING, NULL,
		Rulebooks::std(WHEN_SCENE_BEGINS_RB), NULL, NULL, 1, FALSE);
	IXRules::index_rules_box(OUT, "When a scene ends", EMPTY_WORDING, NULL,
		Rulebooks::std(WHEN_SCENE_ENDS_RB), NULL, NULL, 1, FALSE);
}
