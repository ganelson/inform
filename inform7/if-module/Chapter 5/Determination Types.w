[DeterminationTypes::] Determination Types.

Command grammars, their lines and their tokens may each "determine" up to
two values, and here we provide a way to describe the range of those.

@ Determination is the process by which Inform looks at a command grammar,
or a line in one, or a token in one of those lines, and works out what value
or values this grammar is talking about. Those could be specific values or
whole kinds, and so we use a specification -- which will always be an rvalue
or a description -- for each value.

For example, the grammar line created in:
>> Understand "put [other things] on/onto [something]" as putting it on.
has a determination type with two terms, one a description of |K_thing| with
multiplicity |TRUE|, and the other a description of |K_thing| without.

@d MAX_DETERMINATION_TYPE_TERMS 2

=
typedef struct determination_type {
	int no_values_described;
	struct determination_type_term term[MAX_DETERMINATION_TYPE_TERMS];
} determination_type;

typedef struct determination_type_term {
	struct parse_node *what; /* always an rvalue or a description */
	int multiplicity; /* relevant for lines only: allow a multiple object here? */
} determination_type_term;

int DeterminationTypes::get_no_values_described(determination_type *gty) {
	return gty->no_values_described;
}

@ This function returns the equivalent of the |void| type in C: something
which describes no values at all.

=
determination_type DeterminationTypes::new(void) {
	determination_type gty;
	for (int t=0; t<MAX_DETERMINATION_TYPE_TERMS; t++) {
		gty.term[t].what = NULL;
		gty.term[t].multiplicity = FALSE;
	}
	gty.no_values_described = 0;
	return gty;
}

@ And then call this to make more interesting DTs:

=
void DeterminationTypes::add_term(determination_type *gty, parse_node *spec,
	int multiple_flag) {
	if (gty->no_values_described >= MAX_DETERMINATION_TYPE_TERMS) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_ThreeValuedLine),
			"there can be at most two varying parts to a line of grammar",
			"so 'put [something] in [a container]' is allowed but 'put "
			"[something] in [something] beside [a door]' is not.");
	} else {
		gty->term[gty->no_values_described].what = spec;
		gty->term[gty->no_values_described].multiplicity = multiple_flag;
		gty->no_values_described++;
	}
}

@ When dealing with grammar describing just a single value, these functions
are convenient:

=
parse_node *DeterminationTypes::get_single_term(determination_type *gty) {
	if (gty->no_values_described == 1) return gty->term[0].what;
	return NULL;
}

kind *DeterminationTypes::get_single_kind(determination_type *gty) {
	if ((gty->no_values_described == 1) && (gty->term[0].what))
		return Specifications::to_kind(gty->term[0].what);
	return NULL;
}

void DeterminationTypes::set_single_term(determination_type *gty, parse_node *spec) {
	if (spec == NULL) {
		gty->no_values_described = 0;
	} else {
		gty->no_values_described = 1;
		gty->term[0].what = spec;
		gty->term[0].multiplicity = FALSE;
	}
}

@ The behaviour of this sorting function is documented in the discussion
of CGL sorting in //Command Grammar Lines//.

=
int DeterminationTypes::must_precede(determination_type *gty1, determination_type *gty2) {
	if ((gty1->no_values_described) < (gty2->no_values_described)) return TRUE;
	if ((gty1->no_values_described) > (gty2->no_values_described)) return FALSE;
	
	for (int t=0; t<MAX_DETERMINATION_TYPE_TERMS; t++) {
		if (gty1->no_values_described == t) return NOT_APPLICABLE;
		int cs = Specifications::compare_specificity(gty1->term[t].what, gty2->term[t].what, NULL);
		if (cs == 1) return TRUE;
		if (cs == -1) return FALSE;
		if ((gty1->term[t].multiplicity) && (gty2->term[t].multiplicity == FALSE))
			return FALSE;
		if ((gty1->term[t].multiplicity == FALSE) && (gty2->term[t].multiplicity))
			return TRUE;
	}

	return NOT_APPLICABLE;
}
