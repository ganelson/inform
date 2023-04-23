[PL::Devices::] Devices.

A feature giving minimal support for switchable devices.

@ The Devices feature does just one thing: it applies an indicator property
to things of the kind "device". This used to be accomplished by the Standard
Rules in a clumsy sort of way (with a direct I6 code injection), but in the
age of Inter we want to avoid that sort of tomfoolery.

=
void PL::Devices::start(void) {
	PluginCalls::plug(NEW_BASE_KIND_NOTIFY_PLUG, PL::Devices::new_base_kind_notify);
	PluginCalls::plug(COMPLETE_MODEL_PLUG, PL::Devices::IF_complete_model);
}

@ As usual with notable kinds, this is recognised by its English name, so there
is no need to translate this.

=
<notable-device-kinds> ::=
	device

@ =
kind *K_device = NULL;
int PL::Devices::new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (<notable-device-kinds>(W)) { K_device = new_base; return TRUE; }
	return FALSE;
}

int PL::Devices::IF_complete_model(int stage) {
	if (stage == WORLD_STAGE_III) {
		property *P_switchable = EitherOrProperties::new_nameless(I"switchable");
//		RTProperties::recommend_storing_as_attribute(P_switchable, TRUE);
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object)
			if (Instances::of_kind(I, K_device))
				EitherOrProperties::assert(
					P_switchable, Instances::as_subject(I), TRUE, CERTAIN_CE);
	}
	return FALSE;
}
