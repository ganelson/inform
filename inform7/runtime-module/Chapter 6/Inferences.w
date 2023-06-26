[RTInferences::] Inferences.

To index inferences.

@h Indexing properties of a subject.
This is where the detailed description of a given kind -- what properties it
has, and so on -- is generated.

=
void RTInferences::index(package_request *pack, int hl, inference_subject *infs, int brief) {
	TEMPORARY_TEXT(OUT)
	property *prn;
	LOOP_OVER(prn, property) RTProperties::set_indexed_already_flag(prn, FALSE);
	for (int c = CERTAIN_CE; c >= IMPOSSIBLE_CE; c--) {
		char *cert = "Text only put here to stop gcc -O2 wrongly reporting an error";
		if (c == UNKNOWN_CE) continue;
		switch(c) {
			case CERTAIN_CE:    cert = "Always"; break;
			case LIKELY_CE:     cert = "Usually"; break;
			case UNLIKELY_CE:   cert = "Usually not"; break;
			case IMPOSSIBLE_CE: cert = "Never"; break;
			case INITIALLY_CE:	cert = "Initially"; break;
		}
		RTInferences::index_provided(OUT, infs, TRUE, c, cert, brief);
	}
	RTInferences::index_provided(OUT, infs, FALSE, LIKELY_CE, "Can have", brief);
	Hierarchy::apply_metadata(pack, hl, OUT);
	DISCARD_TEXT(OUT)
}

@ The following lists off the properties of the kind, with the given
state of being boolean, and the given certainty levels:

=
void RTInferences::index_provided(OUTPUT_STREAM, inference_subject *infs, int boolean, int c, char *cert, int brief) {
	int f = TRUE;
	property *prn;
	LOOP_OVER(prn, property) {
		if (RTProperties::is_shown_in_index(prn) == FALSE) continue;
		if (RTProperties::get_indexed_already_flag(prn)) continue;
		if (Properties::is_either_or(prn) != boolean) continue;

		int state = PropertyInferences::has_or_can_have(infs, prn);
		if (state != c) continue;
		int inherited_state = PropertyInferences::has_or_can_have(
			InferenceSubjects::narrowest_broader_subject(infs), prn);
		if ((state == inherited_state) && (brief)) continue;

		if (f) { WRITE("<i>%s</i> ", cert); f = FALSE; }
		else WRITE(", ");
		WRITE("%+W", prn->name);
		RTProperties::set_indexed_already_flag(prn, TRUE);

		if (Properties::is_either_or(prn)) {
			property *prnbar = EitherOrProperties::get_negation(prn);
			if (prnbar) {
				WRITE(" <i>not</i> %+W", prnbar->name);
				RTProperties::set_indexed_already_flag(prnbar, TRUE);
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
void RTInferences::index_specific(package_request *pack, int hl, inference_subject *infs) {
	TEMPORARY_TEXT(OUT)
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
						if (P) IndexUtilities::link(OUT, Wordings::first_wn(Node::get_text(P)));
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
						HTML::begin_span(OUT, I"indexdullblue");
						WRITE("%+W", Node::get_text(S));
						HTML::end_span(OUT);
						if (P) IndexUtilities::link(OUT, Wordings::first_wn(Node::get_text(P)));
						HTML_CLOSE("p");
					}
				}
	Hierarchy::apply_metadata(pack, hl, OUT);
	DISCARD_TEXT(OUT)
}

void RTInferences::index_either_or(OUTPUT_STREAM, property *prn) {
	property *neg = EitherOrProperties::get_negation(prn);
	WRITE("either/or property");
	if (Properties::get_permissions(prn)) {
		WRITE(" of "); RTInferences::index_permissions(OUT, prn);
	} else if ((neg) && (Properties::get_permissions(neg))) {
		WRITE(" of "); RTInferences::index_permissions(OUT, neg);
	}
	if (neg) WRITE(", opposite of </i>%+W<i>", neg->name);
}

void RTInferences::index_permissions(OUTPUT_STREAM, property *prn) {
	for (int ac = 0, s = 1; s <= 2; s++) {
		property_permission *pp;
		LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn) {
			wording W = InferenceSubjects::get_name_text(
				PropertyPermissions::get_subject(pp));
			if (Wordings::nonempty(W)) {
				if (s == 1) ac++;
				else {
					WRITE("</i>%+W<i>", W);
					ac--;
					if (ac == 1) WRITE(" or ");
					if (ac > 1) WRITE(", ");
				}
			}
		}
	}
}
