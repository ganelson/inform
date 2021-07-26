[PhrasebookElement::] Phrasebook Element.

To write the Phrasebook element (Pb) in the index.

@ =
void PhrasebookElement::render(OUTPUT_STREAM, index_session *session) {
	inter_tree *I = Indexing::get_tree(session);
	inter_package *pack = Inter::Packages::by_url(I, I"/main/completion/phrases");
	for (int pass = 1; pass <= 2; pass++) {
		int grand_c = 0;
		inter_package *sh_pack;
		LOOP_THROUGH_SUBPACKAGES(sh_pack, pack, I"_phrasebook_super_heading") {	
			if (pass == 2) HTML_TAG("hr");
			HTML_OPEN_WITH("p", "class=\"in1\"");
			WRITE("<b>%S</b>", Metadata::read_textual(sh_pack, I"^text"));
			HTML_CLOSE("p");
			int c = 0;
			inter_package *h_pack;
			LOOP_THROUGH_SUBPACKAGES(h_pack, sh_pack, I"_phrasebook_heading") {
				c++; grand_c++;
				if ((pass == 1) && (c > 1)) WRITE(", ");
				if (pass == 2) {
					IndexUtilities::anchor_numbered(OUT, grand_c);
					HTML_OPEN_WITH("p", "class=\"in2\"");
					WRITE("<b>");
				}
				WRITE("%S", Metadata::read_textual(h_pack, I"^text"));
				if (pass == 1) IndexUtilities::below_link_numbered(OUT, grand_c);
				if (pass == 2) {
					WRITE("</b>");
					HTML_CLOSE("p");
				}
				if (pass == 2) {
					inter_package *entry_pack;
					LOOP_THROUGH_SUBPACKAGES(entry_pack, h_pack, I"_phrasebook_entry")
						WRITE("%S", Metadata::read_textual(entry_pack, I"^text"));
				}
			}
		}
	}
}
