[IXInferences::] Inferences.

To index inferences.

@h Indexing properties of a subject.
This is where the detailed description of a given kind -- what properties it
has, and so on -- is generated.

=
void IXInferences::index(OUTPUT_STREAM, inference_subject *infs, int brief) {
	inference *inf;
	KNOWLEDGE_LOOP(inf, infs, property_inf)
		if (PropertyInferences::get_property(inf) == P_specification) {
			parse_node *spec = PropertyInferences::get_value(inf);
			Index::dequote(OUT, Lexer::word_raw_text(Wordings::first_wn(Node::get_text(spec))));
			HTML_TAG("br");
		}

	property *prn;
	LOOP_OVER(prn, property) IXProperties::set_indexed_already_flag(prn, FALSE);

	int c;
	for (c = CERTAIN_CE; c >= IMPOSSIBLE_CE; c--) {
		char *cert = "Text only put here to stop gcc -O2 wrongly reporting an error";
		if (c == UNKNOWN_CE) continue;
		switch(c) {
			case CERTAIN_CE:    cert = "Always"; break;
			case LIKELY_CE:     cert = "Usually"; break;
			case UNLIKELY_CE:   cert = "Usually not"; break;
			case IMPOSSIBLE_CE: cert = "Never"; break;
			case INITIALLY_CE:	cert = "Initially"; break;
		}
		IXInferences::index_provided(OUT, infs, TRUE, c, cert, brief);
	}
	IXInferences::index_provided(OUT, infs, FALSE, LIKELY_CE, "Can have", brief);
}

@ The following lists off the properties of the kind, with the given
state of being boolean, and the given certainty levels:

=
void IXInferences::index_provided(OUTPUT_STREAM, inference_subject *infs, int bool, int c, char *cert, int brief) {
	int f = TRUE;
	property *prn;
	LOOP_OVER(prn, property) {
		if (RTProperties::is_shown_in_index(prn) == FALSE) continue;
		if (IXProperties::get_indexed_already_flag(prn)) continue;
		if (Properties::is_either_or(prn) != bool) continue;

		int state = PropertyInferences::has_or_can_have(infs, prn);
		if (state != c) continue;
		int inherited_state = PropertyInferences::has_or_can_have(
			InferenceSubjects::narrowest_broader_subject(infs), prn);
		if ((state == inherited_state) && (brief)) continue;

		if (f) { WRITE("<i>%s</i> ", cert); f = FALSE; }
		else WRITE(", ");
		WRITE("%+W", prn->name);
		IXProperties::set_indexed_already_flag(prn, TRUE);

		if (Properties::is_either_or(prn)) {
			property *prnbar = EitherOrProperties::get_negation(prn);
			if (prnbar) {
				WRITE(" <i>not</i> %+W", prnbar->name);
				IXProperties::set_indexed_already_flag(prnbar, TRUE);
			}
		} else {
			kind *K = ValueProperties::kind(prn);
			if (K) {
				WRITE(" (<i>"); Kinds::Textual::write(OUT, K); WRITE("</i>)");
			}
		}
	}
	if (f == FALSE) {
		WRITE(".");
		HTML_TAG("br");
	}
}

@h Indexing properties of a specific subject.
This only tells about specific property settings for a given faux_instance.

=
void IXInferences::index_specific(OUTPUT_STREAM, inference_subject *infs) {
	property *prn; int k = 0;
	LOOP_OVER(prn, property)
		if (RTProperties::is_shown_in_index(prn))
			if (Properties::is_either_or(prn)) {
				if (PropertyPermissions::find(infs, prn, TRUE)) {
					parse_node *P = NULL;
					int S = PropertyInferences::either_or_state_without_inheritance(infs, prn, &P);
					property *prnbar = EitherOrProperties::get_negation(prn);
					if ((prnbar) && (S < 0)) continue;
					if (S != UNKNOWN_CE) {
						k++;
						if (k == 1) HTML::open_indented_p(OUT, 1, "hanging");
						else WRITE("; ");
						if (S < 0) WRITE("not ");
						WRITE("%+W", prn->name);
						if (P) Index::link(OUT, Wordings::first_wn(Node::get_text(P)));
					}
				}
			}
	if (k > 0) HTML_CLOSE("p");
	LOOP_OVER(prn, property)
		if (RTProperties::is_shown_in_index(prn))
			if (Properties::is_either_or(prn) == FALSE)
				if (PropertyPermissions::find(infs, prn, TRUE)) {
					parse_node *P = NULL;
					parse_node *S = PropertyInferences::value_and_where_without_inheritance(infs, prn, &P);
					if ((S) && (Wordings::nonempty(Node::get_text(S)))) {
						HTML::open_indented_p(OUT, 1, "hanging");
						WRITE("%+W: ", prn->name);
						HTML::begin_colour(OUT, I"000080");
						WRITE("%+W", Node::get_text(S));
						HTML::end_colour(OUT);
						if (P) Index::link(OUT, Wordings::first_wn(Node::get_text(P)));
						HTML_CLOSE("p");
					}
				}
}
