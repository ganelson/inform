[Elements::] Elements.

The index is divided up into 'elements'.

@

=
void Elements::test_card(OUTPUT_STREAM, wording W, localisation_dictionary *LD) {
	TEMPORARY_TEXT(elt)
	WRITE_TO(elt, "%+W", W);
	Elements::render(OUT, elt, LD);
	DISCARD_TEXT(elt)
}

void Elements::render(OUTPUT_STREAM, text_stream *elt, localisation_dictionary *LD) {
	if (Str::eq_wide_string(elt, L"A1")) { GroupedElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"A2")) { AlphabeticElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Ar")) { ArithmeticElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Bh")) { BehaviourElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"C"))  { ContentsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Cd")) { CardElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Ch")) { ChartElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Cm")) { CommandsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Ev")) { EventsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Fi")) { FiguresElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Gz")) { GazetteerElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"In")) { InnardsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Lx")) { LexiconElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Mp")) { MapElement::render(OUT, LD, FALSE); return; }
	if (Str::eq_wide_string(elt, L"MT")) { MapElement::render(OUT, LD, TRUE); return; }
	if (Str::eq_wide_string(elt, L"Ph")) { PhrasebookElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Pl")) { PlotElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Rl")) { RelationsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"RS")) { RulesForScenesElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"St")) { StandardsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Tb")) { TablesElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"To")) { TokensElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Vb")) { VerbsElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Vl")) { ValuesElement::render(OUT, LD); return; }
	if (Str::eq_wide_string(elt, L"Xt")) { ExtrasElement::render(OUT, LD); return; }

	HTML_OPEN("p"); WRITE("NO CONTENT"); HTML_CLOSE("p");
}
