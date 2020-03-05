[PL::Parsing::Tokens::Types::] Grammar Types.

Some grammar text specifies one or more values, and we need to
keep track of their kind(s). Here we manage the data structure doing
this.

@h Definitions.

=
typedef struct grammar_type {
	int no_resulting_values; /* number of resulting values: 0, 1 or 2; or |-1| */
	struct parse_node *first_type; /* and their types */
	struct parse_node *second_type;
	int first_multiplicity; /* lines only: allow a multiple object here? */
	int second_multiplicity; /* lines only: allow a multiple object here? */
} grammar_type;

@ =
grammar_type PL::Parsing::Tokens::Types::new(int supports_return_type) {
	grammar_type gty;
	gty.first_type = NULL;
	gty.second_type = NULL;
	gty.first_multiplicity = FALSE;
	gty.second_multiplicity = FALSE;
	if (supports_return_type)
		gty.no_resulting_values = 0;
	else
		gty.no_resulting_values = -1;
	return gty;
}

@ The multiplication by 10 here is explained in the discussion of GSB
tallying during GL sorting in "Grammar Lines". Do not amend it without
changing that discussion.

=
int PL::Parsing::Tokens::Types::add_type(grammar_type *gty, parse_node *spec,
	int multiple_flag, int score) {
	switch((gty->no_resulting_values)++) {
		case 0:
			gty->first_type = spec;
			gty->first_multiplicity = multiple_flag;
			return 10*score;
		case 1:
			gty->second_type = spec;
			gty->second_multiplicity = multiple_flag;
			return score;
		case 2:
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_ThreeValuedLine),
				"there can be at most two varying parts to a line of grammar",
				"so 'put [something] in [a container]' is allowed but 'put "
				"[something] in [something] beside [a door]' is not.");
	}
	return 0;
}

int PL::Parsing::Tokens::Types::has_return_type(grammar_type *gty) {
	if (gty->no_resulting_values == -1) return FALSE;
	return TRUE;
}

int PL::Parsing::Tokens::Types::get_no_resulting_values(grammar_type *gty) {
	return gty->no_resulting_values;
}

parse_node *PL::Parsing::Tokens::Types::get_single_type(grammar_type *gty) {
	switch(gty->no_resulting_values) {
		case 0: return NULL;
		case 1: return gty->first_type;
		default: internal_error("gty improperly typed");
	}
	return NULL;
}

void PL::Parsing::Tokens::Types::set_single_type(grammar_type *gty, parse_node *spec) {
	if (spec == NULL) gty->no_resulting_values = 0;
	else {
		gty->no_resulting_values = 1;
		gty->first_type = spec;
	}
}

void PL::Parsing::Tokens::Types::compile_to_string(grammar_type *gty) {
	Specifications::Compiler::emit_as_val(K_value, gty->first_type);
}

kind *PL::Parsing::Tokens::Types::get_data_type_as_token(grammar_type *gty) {
	if (gty->no_resulting_values > 0) {
		if ((ParseTree::is(gty->first_type, CONSTANT_NT)) ||
			(Specifications::is_description(gty->first_type)))
			return Specifications::to_kind(gty->first_type);
	}
	return NULL;
}

@ The behaviour of this sorting routine is documented in the discussion
of GL sorting in "Grammar Lines". Do not amend it without changing that
discussion.

=
int PL::Parsing::Tokens::Types::must_precede(grammar_type *gty1, grammar_type *gty2) {
	int cs;
	if ((gty1->no_resulting_values) < (gty2->no_resulting_values)) return TRUE;
	if ((gty1->no_resulting_values) > (gty2->no_resulting_values)) return FALSE;
	if (gty1->no_resulting_values == 0) return NOT_APPLICABLE;

	cs = Specifications::compare_specificity(gty1->first_type, gty2->first_type, NULL);
	if (cs == 1) return TRUE;
	if (cs == -1) return FALSE;
	if ((gty1->first_multiplicity) && (gty2->first_multiplicity == FALSE))
		return FALSE;
	if ((gty1->first_multiplicity == FALSE) && (gty2->first_multiplicity))
		return TRUE;
	if (gty1->no_resulting_values == 1) return NOT_APPLICABLE;

	cs = Specifications::compare_specificity(gty1->second_type, gty2->second_type, NULL);
	if (cs == 1) return TRUE;
	if (cs == -1) return FALSE;
	if ((gty1->second_multiplicity) && (gty2->second_multiplicity == FALSE))
		return FALSE;
	if ((gty1->second_multiplicity == FALSE) && (gty2->second_multiplicity))
		return TRUE;
	return NOT_APPLICABLE;
}
