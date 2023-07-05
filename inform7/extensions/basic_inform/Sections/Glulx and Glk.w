Glulx and Glk.

Support for Glulx and Glk interpreter systems.

@ =
Part Four - Glulx and Glk (for Glulx only)

@h Feature testing.
These phrases let us test for various interpreter features.
While most features can use the generic functions, a few need special handling,
and so individual phrases are defined for them.

=
Chapter - Feature testing

To decide whether (F - glk feature) is/are supported:
	(- glk_gestalt({F}) -).

To decide what number is the glk version number/--:
	(- glk_gestalt(gestalt_Version) -).

To decide whether buffer window graphics are/is supported:
	(- glk_gestalt(gestalt_DrawImage, winType_TextBuffer) -).

To decide whether graphics window graphics are/is supported:
	(- glk_gestalt(gestalt_DrawImage, winType_Graphics) -).

To decide whether graphics window mouse input is supported:
	(- glk_gestalt(gestalt_MouseInput, winType_Graphics) -).

To decide whether grid window mouse input is supported:
	(- glk_gestalt(gestalt_MouseInput, winType_TextGrid) -).

To decide whether (F - glulx feature) is/are supported:
	(- Glulx_Gestalt({F}) -).

To decide what number is the glulx version number/--:
	(- Glulx_Gestalt(GLULX_GESTALT_GlulxVersion) -).

To decide what number is the interpreter version number/--:
	(- Glulx_Gestalt(GLULX_GESTALT_TerpVersion) -).
