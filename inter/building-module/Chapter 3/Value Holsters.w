[Holsters::] Value Holsters.

To manage requests for compilation to Inter.

@

@e INTER_DATA_VHMODE from 1
@e INTER_VAL_VHMODE
@e INTER_VOID_VHMODE
@e NO_VHMODE

=
typedef struct value_holster {
	int vhmode_wanted;
	int vhmode_provided;
	inter_ti val1, val2;
} value_holster;

@ =
value_holster Holsters::new(int vhm) {
	value_holster vh;
	vh.val1 = 0; vh.val2 = 0;
	vh.vhmode_wanted = vhm;
	vh.vhmode_provided = NO_VHMODE;
	if (vhm == NO_VHMODE) internal_error("can't want NO_VHMODE");
	return vh;
}

@h Conversions.

=
int Holsters::non_void_context(value_holster *vh) {
	if (vh == NULL) internal_error("no VH");
	if ((vh->vhmode_wanted == INTER_DATA_VHMODE) ||
		(vh->vhmode_wanted == INTER_VAL_VHMODE)) return TRUE;
	return FALSE;
}

void Holsters::unholster_to_code_val(inter_tree *I, value_holster *vh) {
	if (vh == NULL) internal_error("no VH");
	switch (vh->vhmode_provided) {
		case INTER_DATA_VHMODE:
			Produce::val(I, K_value, vh->val1, vh->val2);
			break;
		case INTER_VOID_VHMODE:
			internal_error("impossible conversion");
			break;
		case NO_VHMODE:
			vh->val1 = LITERAL_IVAL; vh->val2 = 0;
			Produce::val(I, K_value, vh->val1, vh->val2);
			break;
	}
	vh->vhmode_provided = INTER_VAL_VHMODE;
}

@h Holstering data.

=
void Holsters::holster_pair(value_holster *vh, inter_ti v1, inter_ti v2) {
	if (vh == NULL) internal_error("no VH");
	vh->val1 = v1; vh->val2 = v2;
	vh->vhmode_provided = INTER_DATA_VHMODE;
}

void Holsters::unholster_pair(value_holster *vh, inter_ti *v1, inter_ti *v2) {
	if (vh == NULL) internal_error("no VH");
	if (vh->vhmode_provided != INTER_DATA_VHMODE) {
		if (vh->vhmode_provided != NO_VHMODE)
			if (problem_count == 0) internal_error("errant DV");
		vh->val1 = LITERAL_IVAL; vh->val2 = 0;
		vh->vhmode_provided = INTER_DATA_VHMODE;
	}
	*v1 = vh->val1; *v2 = vh->val2;
}
