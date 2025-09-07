[ControlStructures::] Control Structures.

To specify the syntax of control structures such as repeat, if and otherwise.

@ Certain phrases are "control structures": otherwise, if, repeat, while and
so on. These have different expectations in terms of the layout of surrounding
phrases in rule or phrase definitions, and the following structure defines
the relevant behaviour. (The contents are static.)

=
typedef struct control_structure_phrase {
	struct control_structure_phrase *subordinate_to;
	struct text_stream *mnemonic;
	int indent_subblocks;
	int body_empty_except_for_subordinates;
	int used_at_stage;
	int is_a_loop;
	int requires_new_syntax;
	int allow_run_on;
	inchar32_t *keyword;
	CLASS_DEFINITION
} control_structure_phrase;

@ =
control_structure_phrase *ControlStructures::new(text_stream *mnemonic) {
	control_structure_phrase *csp = CREATE(control_structure_phrase);
	csp->mnemonic = Str::duplicate(mnemonic);
	csp->subordinate_to = NULL;
	csp->indent_subblocks = FALSE;
	csp->body_empty_except_for_subordinates = FALSE;
	csp->used_at_stage = -1;
	csp->requires_new_syntax = FALSE;
	csp->allow_run_on = FALSE;
	csp->keyword = U"<none>";
	csp->is_a_loop = FALSE;
	return csp;
}

@ Some cryptic mnemonics for logging the invocation tree:

=
void ControlStructures::log(text_stream *OUT, control_structure_phrase *csp) {
	if (csp == NULL) WRITE("---");
	else WRITE("%S", csp->mnemonic);
}

@ The following set is built in to the Inform language; Basic Inform and such
extensions cannot extend it.

=
control_structure_phrase *switch_CSP = NULL, *if_CSP = NULL, *repeat_CSP = NULL,
	*while_CSP = NULL, *otherwise_CSP = NULL, *abbreviated_otherwise_CSP = NULL,
	*otherwise_if_CSP = NULL, *default_case_CSP = NULL, *case_CSP = NULL,
	*say_CSP = NULL, *instead_CSP = NULL;

@ And this is where they are all created:

=
void ControlStructures::create_standard(void) {
	switch_CSP = ControlStructures::new(I"SWI");
	switch_CSP->body_empty_except_for_subordinates = TRUE;
	switch_CSP->indent_subblocks = TRUE;
	switch_CSP->requires_new_syntax = TRUE;
	switch_CSP->keyword = U"if";

	if_CSP = ControlStructures::new(I"IF");
	if_CSP->keyword = U"if";

	repeat_CSP = ControlStructures::new(I"RPT");
	repeat_CSP->keyword = U"repeat";
	repeat_CSP->is_a_loop = TRUE;

	while_CSP = ControlStructures::new(I"WHI");
	while_CSP->keyword = U"while";
	while_CSP->is_a_loop = TRUE;

	otherwise_CSP = ControlStructures::new(I"O");
	otherwise_CSP->subordinate_to =	if_CSP;
	otherwise_CSP->used_at_stage = 1;

	abbreviated_otherwise_CSP = ControlStructures::new(I"AO");
	abbreviated_otherwise_CSP->subordinate_to =	if_CSP;
	abbreviated_otherwise_CSP->used_at_stage = 1;

	otherwise_if_CSP = ControlStructures::new(I"OIF");
	otherwise_if_CSP->subordinate_to = if_CSP;
	otherwise_if_CSP->used_at_stage = 0;

	case_CSP = ControlStructures::new(I"CAS");
	case_CSP->subordinate_to = switch_CSP;
	case_CSP->used_at_stage = 1;
	case_CSP->requires_new_syntax = TRUE;
	case_CSP->allow_run_on = TRUE;

	default_case_CSP = ControlStructures::new(I"DEF");
	default_case_CSP->subordinate_to = switch_CSP;
	default_case_CSP->used_at_stage = 2;
	default_case_CSP->requires_new_syntax = TRUE;
	default_case_CSP->allow_run_on = TRUE;

	say_CSP = ControlStructures::new(I"SAY");

	instead_CSP = ControlStructures::new(I"INS");
}

@ Control structures such as "if" act as a sort of super-punctuation inside
rule and phrase definitions, and in particular they affect the actual
punctuation of the sentences there (consider the rules about colons versus
semicolons). So, though it's still early in Inform's run, we need to seek
them out.

Here we parse the text of a command phrase which, if any, of the control
structures it might be. Note that <s-command> has a grammar partially
overlapping with this, and they need to match.

At one time we handled "now" as a control structure, but have rowed back
on that: it's possible to implement it as a regular phrase (at the cost of
introducing a complication to how its one token is invoked), and that seems
better. See Jira bug report I7-2317.

@d NO_SIGF 0
@d SAY_SIGF 1

=
<control-structure-phrase> ::=
	if ... is begin |               ==> { -, switch_CSP }
	if ... is |                     ==> { -, switch_CSP }
	if/unless ... |                 ==> { -, if_CSP }
	repeat ... |                    ==> { -, repeat_CSP }
	while ... |                     ==> { -, while_CSP }
	else/otherwise |                ==> { -, otherwise_CSP }
	else/otherwise if/unless ... |  ==> { -, otherwise_if_CSP }
	else/otherwise ... |            ==> { -, abbreviated_otherwise_CSP }
	-- otherwise |                  ==> { -, default_case_CSP }
	-- ...                          ==> { -, case_CSP }

<end-control-structure-phrase> ::=
	end if/unless |                 ==> { -, if_CSP }
	end while |                     ==> { -, while_CSP }
	end repeat                      ==> { -, repeat_CSP }

<other-significant-phrase> ::=
	say ...                         ==> { SAY_SIGF, - }

@ This is used to see if an "if" is being used with the comma notation:

=
<phrase-with-comma-notation> ::=
	...... , ......

@ This is used to see if an "if" is being used with the comma notation:

=
<instead-keyword> ::=
	instead ... |
	... instead

@ Finally, this is used to see if a control structure opens a block:

=
<phrase-beginning-block> ::=
	... begin

@ And some miscellaneous provisions:

=
int ControlStructures::comma_possible(control_structure_phrase *csp) {
	if ((csp == if_CSP) || (csp == switch_CSP) || (csp == otherwise_if_CSP))
		return TRUE;
	return FALSE;
}

int ControlStructures::is_a_loop(control_structure_phrase *csp) {
	if (csp) return csp->is_a_loop;
	return FALSE;
}

int ControlStructures::opens_block(control_structure_phrase *csp) {
	if ((csp) && (csp->subordinate_to == NULL) &&
		(csp != say_CSP) && (csp != instead_CSP)) return TRUE;
	return FALSE;
}

int ControlStructures::permits_break(control_structure_phrase *csp) {
	if ((csp == repeat_CSP) || (csp == while_CSP)) return TRUE;
	return FALSE;
}

inchar32_t *ControlStructures::incipit(control_structure_phrase *csp) {
	if (csp) return csp->keyword;
	return U"<none>";
}

control_structure_phrase *ControlStructures::detect(wording W) {
	if (<control-structure-phrase>(W)) {
		if (<<rp>> == abbreviated_otherwise_CSP) return NULL;
		return <<rp>>;
	}
	return NULL;
}

int ControlStructures::abbreviated_otherwise(wording W) {
	if (<control-structure-phrase>(W)) {
		if (<<rp>> == abbreviated_otherwise_CSP) return TRUE;
	}
	return FALSE;
}

control_structure_phrase *ControlStructures::detect_end(wording W) {
	if (<end-control-structure-phrase>(W)) return <<rp>>;
	return NULL;
}
