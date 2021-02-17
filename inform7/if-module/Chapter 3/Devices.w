[PL::Devices::] Devices.

A plugin giving minimal support for switchable devices.

@ The Devices plugin does just one thing: it applies an indicator property
to things of the kind "device". This used to be accomplished by the Standard
Rules in a clumsy sort of way (with a direct I6 code injection), but in the
age of Inter we want to avoid that sort of tomfoolery.

= (early code)
kind *K_device = NULL;
property *P_switchable = NULL;

@ =
void PL::Devices::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_BASE_KIND_NOTIFY, PL::Devices::devices_new_base_kind_notify);
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Devices::IF_complete_model);
}


@ =
<notable-device-kinds> ::=
	device

@ =
int PL::Devices::devices_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (<notable-device-kinds>(W)) { K_device = new_base; return TRUE; }
	return FALSE;
}

@ =
int PL::Devices::IF_complete_model(int stage) {
	if (stage == WORLD_STAGE_III) {
		P_switchable = Properties::EitherOr::new_nameless(L"switchable");
		RTProperties::implement_as_attribute(P_switchable, TRUE);
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object)
			if (Instances::of_kind(I, K_device))
				Properties::EitherOr::assert(
					P_switchable, Instances::as_subject(I), TRUE, CERTAIN_CE);
	}
	return FALSE;
}
