[RTPlayer::] The Player.

@ A special Inter array holds enough details about the initial situation of
the player for |WorldModelKit| to get things started.

=
void RTPlayer::InitialSituation(void) {
	RTPlayer::InitialSituation_define(PLAYER_OBJECT_INIS_HL, 0);
	RTPlayer::InitialSituation_define(START_OBJECT_INIS_HL, 1);
	RTPlayer::InitialSituation_define(START_ROOM_INIS_HL, 2);
	RTPlayer::InitialSituation_define(START_TIME_INIS_HL, 3);
	RTPlayer::InitialSituation_define(DONE_INIS_HL, 4);

	inter_name *iname = Hierarchy::find(INITIALSITUATION_HL);
	packaging_state save = Emit::named_array_begin(iname, K_value);
	RTVariables::emit_initial_value(player_VAR);
	if (start_object == NULL) Emit::array_numeric_entry(0);
	else Emit::array_iname_entry(RTInstances::iname(start_object));
	if (start_room == NULL) Emit::array_numeric_entry(0);
	else Emit::array_iname_entry(RTInstances::iname(start_room));
	RTVariables::emit_initial_value(time_of_day_VAR);
	Emit::array_numeric_entry(0);
	Emit::array_end(save);
	Hierarchy::make_available(Emit::tree(), iname);
}

void RTPlayer::InitialSituation_define(int id, int val) {
	inter_name *iname = Hierarchy::find(id);
	Emit::named_array_begin(iname, K_value);
	Emit::named_numeric_constant(iname, (inter_ti) val);
	Hierarchy::make_available(Emit::tree(), iname);
}

@ "Player" is set in an unusual way. That is, Inform does not compile

>> now the player is Mr Chasuble;

to something like |player = O31_mr_chasuble|, as it would do for a typical
variable. It's very important that code compiled by Inform 7 doesn't do
this, because if executed it would break the invariants for |WorldModelKit|
variables about the current situation. The correct thing is always to call
the function |ChangePlayer| instead:

=
void RTPlayer::player_schema(nonlocal_variable *nlv) {
	RTVariables::set_write_schema(nlv, I"ChangePlayer(*2)");
}
