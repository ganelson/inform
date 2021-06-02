[IXArithmetic::] Arithmetic Element.

To index dimensional rules.

@

=
void IXArithmetic::render(OUTPUT_STREAM) {
	HTML_TAG("hr");
	@<Index the rubric about quasinumerical kinds@>;
	@<Index the table of quasinumerical kinds@>;
	@<Index the table of multiplication rules@>;
}

@<Index the rubric about quasinumerical kinds@> =
	HTML_OPEN("p");
	HTML_TAG_WITH("a", "calculator");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/calc2.png");
	WRITE("&nbsp;");
	WRITE("Kinds of value marked with the <b>calculator symbol</b> are numerical - "
		"these are values we can add, multiply and so on. The range of these "
		"numbers depends on the Format setting for the project (Glulx format "
		"supports much higher numbers than Z-code).");
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");

@<Index the table of quasinumerical kinds@> =
	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);

	HTML::first_html_column(OUT, 0);
	WRITE("<b>kind of value</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>minimum</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>maximum</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>dimensions</b>");
	HTML::end_html_row(OUT);

	kind *R;
	LOOP_OVER_BASE_KINDS(R)
		if (Kinds::Behaviour::is_quasinumerical(R)) {
			if (Kinds::is_intermediate(R)) continue;
			HTML::first_html_column(OUT, 0);
			Kinds::Index::index_kind(OUT, R, FALSE, FALSE);
			HTML::next_html_column(OUT, 0);
			@<Index the minimum positive value for a quasinumerical kind@>;
			HTML::next_html_column(OUT, 0);
			@<Index the maximum positive value for a quasinumerical kind@>;
			HTML::next_html_column(OUT, 0);
			if (Kinds::Dimensions::dimensionless(R)) WRITE("<i>dimensionless</i>");
			else {
				unit_sequence *deriv = Kinds::Behaviour::get_dimensional_form(R);
				Kinds::Dimensions::index_unit_sequence(OUT, deriv, TRUE);
			}
			HTML::end_html_row(OUT);
		}
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");

@ At run-time, the minimum positive value is of course |1|, but because of
scaling this can appear to be much lower.

@<Index the minimum positive value for a quasinumerical kind@> =
	if (Kinds::eq(R, K_number)) WRITE("1");
	else {
		text_stream *p = Kinds::Behaviour::get_index_minimum_value(R);
		if (Str::len(p) > 0) WRITE("%S", p);
		else LiteralPatterns::index_value(OUT,
			LiteralPatterns::list_of_literal_forms(R), 1);
	}

@<Index the maximum positive value for a quasinumerical kind@> =
	if (Kinds::eq(R, K_number)) {
		if (TargetVMs::is_16_bit(Task::vm())) WRITE("32767");
		else WRITE("2147483647");
	} else {
		text_stream *p = Kinds::Behaviour::get_index_maximum_value(R);
		if (Str::len(p) > 0) WRITE("%S", p);
		else {
			if (TargetVMs::is_16_bit(Task::vm()))
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(R), 32767);
			else
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(R), 2147483647);
		}
	}

@ This is simply a table of all the multiplications declared in the source
text, sorted into kind order of left and then right operand.

@<Index the table of multiplication rules@> =
	kind *L, *R, *O;
	int NP = 0, wn;
	LOOP_OVER_MULTIPLICATIONS(L, R, O, wn) {
		if (NP++ == 0) {
			HTML_OPEN("p");
			WRITE("This is how multiplication changes kinds:");
			HTML_CLOSE("p");
			HTML_OPEN("p");
			HTML::begin_plain_html_table(OUT);
		}
		HTML::first_html_column(OUT, 0);
		if (wn >= 0) Index::link(OUT, wn);
		HTML::next_html_column(OUT, 0);
		Kinds::Index::index_kind(OUT, L, FALSE, FALSE);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" x ");
		HTML::end_colour(OUT);
		Kinds::Index::index_kind(OUT, R, FALSE, FALSE);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" = ");
		HTML::end_colour(OUT);
		Kinds::Index::index_kind(OUT, O, FALSE, FALSE);
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
		HTML::next_html_column(OUT, 0);
		LiteralPatterns::index_benchmark_value(OUT, L);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" x ");
		HTML::end_colour(OUT);
		LiteralPatterns::index_benchmark_value(OUT, R);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" = ");
		HTML::end_colour(OUT);
		LiteralPatterns::index_benchmark_value(OUT, O);
		HTML::end_html_row(OUT);
	}
	if (NP > 0) { HTML::end_html_table(OUT); HTML_CLOSE("p"); }

