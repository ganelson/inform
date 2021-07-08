[PhrasebookElement::] Phrasebook Element.

To write the Phrasebook element (Pb) in the index.

@ =
void PhrasebookElement::render(OUTPUT_STREAM, localisation_dictionary *LD) {
	inter_tree *I = InterpretIndex::get_tree();
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/phrases");
	inter_symbol *wanted = PackageTypes::get(I, I"_phrasebook_super_heading");
	inter_tree_node *D = Inter::Packages::definition(pack);
	for (int pass = 1; pass <= 2; pass++) {
		int grand_c = 0;
		LOOP_THROUGH_INTER_CHILDREN(C, D) {
			if (C->W.data[ID_IFLD] == PACKAGE_IST) {
				inter_package *entry = Inter::Package::defined_by_frame(C);
				if (Inter::Packages::type(entry) == wanted) {	
					if (pass == 2) HTML_TAG("hr");
					HTML_OPEN_WITH("p", "class=\"in1\"");
					WRITE("<b>%S</b>", Metadata::read_textual(entry, I"^text"));
					HTML_CLOSE("p");
					int c = 0;
					inter_symbol *wanted_b = PackageTypes::get(I, I"_phrasebook_heading");
					LOOP_THROUGH_INTER_CHILDREN(B, C) {
						if (C->W.data[ID_IFLD] == PACKAGE_IST) {
							inter_package *entry_b = Inter::Package::defined_by_frame(B);
							if (Inter::Packages::type(entry_b) == wanted_b) {
								c++; grand_c++;
								if ((pass == 1) && (c > 1)) WRITE(", ");
								if (pass == 2) {
									IndexUtilities::anchor_numbered(OUT, grand_c);
									HTML_OPEN_WITH("p", "class=\"in2\"");
									WRITE("<b>");
								}
								WRITE("%S", Metadata::read_textual(entry_b, I"^text"));
								if (pass == 1) IndexUtilities::below_link_numbered(OUT, grand_c);
								if (pass == 2) {
									WRITE("</b>");
									HTML_CLOSE("p");
								}
								if (pass == 2) {
									inter_symbol *wanted_c = PackageTypes::get(I, I"_phrasebook_entry");
									LOOP_THROUGH_INTER_CHILDREN(A, B) {
										if (C->W.data[ID_IFLD] == PACKAGE_IST) {
											inter_package *entry_c = Inter::Package::defined_by_frame(A);
											if (Inter::Packages::type(entry_c) == wanted_c) {
												WRITE("%S", Metadata::read_textual(entry_c, I"^text"));
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
