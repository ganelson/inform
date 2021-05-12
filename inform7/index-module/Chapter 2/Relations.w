[IXRelations::] Relations.

To index relations.

@ A brief table of relations appears on the Phrasebook Index page.

=
void IXRelations::index_table(OUTPUT_STREAM) {
	binary_predicate *bp;
	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0); WRITE("<i>name</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>category</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>relates this...</i>");
	HTML::next_html_column(OUT, 0); WRITE("<i>...to this</i>");
	HTML::end_html_row(OUT);
	LOOP_OVER(bp, binary_predicate)
		if (bp->right_way_round) {
			TEMPORARY_TEXT(type)
			BinaryPredicateFamilies::describe_for_index(type, bp);
			if ((Str::len(type) == 0) || (WordAssemblages::nonempty(bp->relation_name) == FALSE)) continue;
			HTML::first_html_column(OUT, 0);
			WordAssemblages::index(OUT, &(bp->relation_name));
			if (bp->bp_created_at) Index::link(OUT, Wordings::first_wn(Node::get_text(bp->bp_created_at)));
			HTML::next_html_column(OUT, 0);
			if (Str::len(type) > 0) WRITE("%S", type); else WRITE("--");
			HTML::next_html_column(OUT, 0);
			BPTerms::index(OUT, &(bp->term_details[0]));
			HTML::next_html_column(OUT, 0);
			BPTerms::index(OUT, &(bp->term_details[1]));
			HTML::end_html_row(OUT);
		}
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");
}

@ And a briefer note still for the table of verbs.

=
void IXRelations::index_for_verbs(OUTPUT_STREAM, binary_predicate *bp) {
	WRITE(" ... <i>");
	if (bp == NULL) WRITE("(a meaning internal to Inform)");
	else {
		if (bp->right_way_round == FALSE) {
			bp = bp->reversal;
			WRITE("reversed ");
		}
		WordAssemblages::index(OUT, &(bp->relation_name));
	}
	WRITE("</i>");
}
