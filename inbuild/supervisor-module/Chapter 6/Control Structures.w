[ControlStructures::] Control Structures.

To specify the syntax of control structures such as repeat, if and otherwise.

@ Certain phrases are "structural": otherwise, if, repeat, while and so
on. These have different expectations in terms of the layout of surrounding
phrases in rule or phrase definitions, and the following structure defines
the relevant behaviour. (The contents are static.)

=
typedef struct control_structure_phrase {
	struct control_structure_phrase *subordinate_to;
	int indent_subblocks;
	int body_empty_except_for_subordinates;
	int used_at_stage;
	int is_a_loop;
	int requires_new_syntax;
	int allow_run_on;
	wchar_t *keyword;
	MEMORY_MANAGEMENT
} control_structure_phrase;

@ The following set is built in to the Inform language; Basic Inform and such
extensions cannot extend it.

=
control_structure_phrase
	*switch_CSP = NULL,
	*if_CSP = NULL,
	*repeat_CSP = NULL,
	*while_CSP = NULL,
	*otherwise_CSP = NULL,
	*abbreviated_otherwise_CSP = NULL,
	*otherwise_if_CSP = NULL,
	*default_case_CSP = NULL,
	*case_CSP = NULL,
	*say_CSP = NULL,
	*now_CSP = NULL,
	*instead_CSP = NULL;

@ The following functions attempt to contain information about the
basic structural phrases in one place, so that if future loop constructs
are added, they can fairly simply be put here.

=
control_structure_phrase *ControlStructures::new(void) {
	control_structure_phrase *csp = CREATE(control_structure_phrase);
	csp->subordinate_to = NULL;
	csp->indent_subblocks = FALSE;
	csp->body_empty_except_for_subordinates = FALSE;
	csp->used_at_stage = -1;
	csp->requires_new_syntax = FALSE;
	csp->allow_run_on = FALSE;
	csp->keyword = L"<none>";
	csp->is_a_loop = FALSE;
	return csp;
}

void ControlStructures::create_standard(void) {
	switch_CSP = ControlStructures::new();
	switch_CSP->body_empty_except_for_subordinates = TRUE;
	switch_CSP->indent_subblocks = TRUE;
	switch_CSP->requires_new_syntax = TRUE;
	switch_CSP->keyword = L"if";

	if_CSP = ControlStructures::new();
	if_CSP->keyword = L"if";

	repeat_CSP = ControlStructures::new();
	repeat_CSP->keyword = L"repeat";
	repeat_CSP->is_a_loop = TRUE;

	while_CSP = ControlStructures::new();
	while_CSP->keyword = L"while";
	while_CSP->is_a_loop = TRUE;

	otherwise_CSP = ControlStructures::new();
	otherwise_CSP->subordinate_to =	if_CSP;
	otherwise_CSP->used_at_stage = 1;

	abbreviated_otherwise_CSP = ControlStructures::new();
	abbreviated_otherwise_CSP->subordinate_to =	if_CSP;
	abbreviated_otherwise_CSP->used_at_stage = 1;

	otherwise_if_CSP = ControlStructures::new();
	otherwise_if_CSP->subordinate_to = if_CSP;
	otherwise_if_CSP->used_at_stage = 0;

	case_CSP = ControlStructures::new();
	case_CSP->subordinate_to = switch_CSP;
	case_CSP->used_at_stage = 1;
	case_CSP->requires_new_syntax = TRUE;
	case_CSP->allow_run_on = TRUE;

	default_case_CSP = ControlStructures::new();
	default_case_CSP->subordinate_to = switch_CSP;
	default_case_CSP->used_at_stage = 2;
	default_case_CSP->requires_new_syntax = TRUE;
	default_case_CSP->allow_run_on = TRUE;

	say_CSP = ControlStructures::new();

	now_CSP = ControlStructures::new();

	instead_CSP = ControlStructures::new();
}

void ControlStructures::log(control_structure_phrase *csp) {
	if (csp == if_CSP) LOG("IF");
	if (csp == repeat_CSP) LOG("RPT");
	if (csp == while_CSP) LOG("WHI");
	if (csp == switch_CSP) LOG("SWI");
	if (csp == otherwise_CSP) LOG("O");
	if (csp == abbreviated_otherwise_CSP) LOG("AO");
	if (csp == otherwise_if_CSP) LOG("OIF");
	if (csp == case_CSP) LOG("CAS");
	if (csp == default_case_CSP) LOG("DEF");
	if (csp == say_CSP) LOG("SAY");
	if (csp == now_CSP) LOG("NOW");
	if (csp == instead_CSP) LOG("INS");
	if (csp == NULL) LOG("---");
}

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
		(csp != say_CSP) && (csp != now_CSP) && (csp != instead_CSP)) return TRUE;
	return FALSE;
}

int ControlStructures::permits_break(control_structure_phrase *csp) {
	if ((csp == repeat_CSP) || (csp == while_CSP)) return TRUE;
	return FALSE;
}

wchar_t *ControlStructures::incipit(control_structure_phrase *csp) {
	if (csp) return csp->keyword;
	return L"<none>";
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

@ Control structures such as "if" act as a sort of super-punctuation inside
rule and phrase definitions, and in particular they affect the actual
punctuation of the sentences there (consider the rules about colons versus
semicolons). So, though it's still early in Inform's run, we need to seek
them out.

Here we parse the text of a command phrase which, if any, of the control
structures it might be. Note that <s-command> has a grammar partially
overlapping with this, and they need to match.

@d NO_SIGF 0
@d SAY_SIGF 1
@d NOW_SIGF 2

=
<control-structure-phrase> ::=
	if ... is begin |    ==> 0; *XP = switch_CSP
	if ... is |    ==> 0; *XP = switch_CSP
	if/unless ... |    ==> 0; *XP = if_CSP
	repeat ... |    ==> 0; *XP = repeat_CSP
	while ... |    ==> 0; *XP = while_CSP
	else/otherwise |    ==> 0; *XP = otherwise_CSP
	else/otherwise if/unless ... |    ==> 0; *XP = otherwise_if_CSP
	else/otherwise ... |    ==> 0; *XP = abbreviated_otherwise_CSP
	-- otherwise |    ==> 0; *XP = default_case_CSP
	-- ...							==> 0; *XP = case_CSP

<end-control-structure-phrase> ::=
	end if/unless |    ==> 0; *XP = if_CSP
	end while |    ==> 0; *XP = while_CSP
	end repeat						==> 0; *XP = repeat_CSP

<other-significant-phrase> ::=
	say ... |    ==> SAY_SIGF
	now ...							==> NOW_SIGF

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
