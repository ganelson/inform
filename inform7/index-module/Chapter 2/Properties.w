[IXProperties::] Properties.

To index properties.

@

=
typedef struct property_indexing_data {
	int indexed_already; /* and has it been, thus far in index construction? */
} property_indexing_data;

void IXProperties::initialise_pid(property *prn) {
	prn->indexing_data.indexed_already = FALSE;
}

@ During indexing we try to avoid mentioning properties more than once:

=
void IXProperties::set_indexed_already_flag(property *prn, int state) {
	prn->indexing_data.indexed_already = state;
}
int IXProperties::get_indexed_already_flag(property *prn) {
	return prn->indexing_data.indexed_already;
}

@ Who can own a property?

=
void IXProperties::index_either_or(OUTPUT_STREAM, property *prn) {
	property *neg = EitherOrProperties::get_negation(prn);
	WRITE("either/or property");
	if (Properties::get_permissions(prn)) {
		WRITE(" of "); IXProperties::index_permissions(OUT, prn);
	} else if ((neg) && (Properties::get_permissions(neg))) {
		WRITE(" of "); IXProperties::index_permissions(OUT, neg);
	}
	if (neg) WRITE(", opposite of </i>%+W<i>", neg->name);
}

void IXProperties::index_permissions(OUTPUT_STREAM, property *prn) {
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
