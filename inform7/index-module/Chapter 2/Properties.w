[IXProperties::] Properties.

To index properties.

@ Who can own a property?

=
void IXProperties::index_permissions(OUTPUT_STREAM, property *prn) {
	for (int ac = 0, s = 1; s <= 2; s++) {
		property_permission *pp;
		LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn) {
			wording W = InferenceSubjects::get_name_text(
				World::Permissions::get_subject(pp));
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
