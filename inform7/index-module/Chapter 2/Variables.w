[IXVariables::] Variables.

To index variables.

@ The index of all the global variables doesn't actually include all of them,
because there are "K understood" variables for every kind which can be
understood, and a list of those would be tediously repetitive -- it would
duplicate most of the list of base kinds. So the index shows just one such
variable. Inform recognises these variables by parsing their names against
the following:

=
<value-understood-variable-name> ::=
	<k-kind> understood

@ And here is the indexing code:

=
void IXVariables::index_all(OUTPUT_STREAM) {
	nonlocal_variable *nlv;
	heading *definition_area, *current_area = NULL;
	HTML_OPEN("p");
	Index::anchor(OUT, I"NAMES");
	int understood_note_given = FALSE;
	LOOP_OVER(nlv, nonlocal_variable)
		if ((Wordings::first_wn(nlv->name) >= 0) && (NonlocalVariables::is_global(nlv))) {
			if (<value-understood-variable-name>(nlv->name))
				@<Index a K understood variable@>
			else
				@<Index a regular variable@>;
		}
	HTML_CLOSE("p");
}

@<Index a K understood variable@> =
	if (understood_note_given == FALSE) {
		understood_note_given = TRUE;
		WRITE("<i>kind</i> understood - <i>value</i>");
		HTML_TAG("br");
	}

@<Index a regular variable@> =
	definition_area = Headings::of_wording(nlv->name);
	if (Headings::indexed(definition_area) == FALSE) continue;
	if (definition_area != current_area) {
		wording W = Headings::get_text(definition_area);
		HTML_CLOSE("p");
		HTML_OPEN("p");
		if (Wordings::nonempty(W)) Phrases::Index::index_definition_area(OUT, W, FALSE);
	}
	current_area = definition_area;
	IXVariables::index_one(OUT, nlv);
	HTML_TAG("br");

@ =
void IXVariables::index_one(OUTPUT_STREAM, nonlocal_variable *nlv) {
	WRITE("%+W", nlv->name);
	Index::link(OUT, Wordings::first_wn(nlv->name));
	if (Wordings::nonempty(nlv->var_documentation_symbol)) {
		TEMPORARY_TEXT(ixt)
		WRITE_TO(ixt, "%+W", Wordings::one_word(Wordings::first_wn(nlv->var_documentation_symbol)));
		Index::DocReferences::link(OUT, ixt);
		DISCARD_TEXT(ixt)
	}
	WRITE(" - <i>");
	Kinds::Textual::write(OUT, nlv->nlv_kind);
	WRITE("</i>");
}

void IXVariables::index_stv_set(OUTPUT_STREAM, shared_variable_set *set) {
	shared_variable *stv;
	LOOP_OVER_LINKED_LIST(stv, shared_variable, set->variables)
		if (stv->underlying_var) {
			HTML::open_indented_p(OUT, 2, "tight");
			IXVariables::index_one(OUT, stv->underlying_var);
			HTML_CLOSE("p");
		}
}
