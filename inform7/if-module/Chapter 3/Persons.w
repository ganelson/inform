[PL::Persons::] Persons.

A plugin giving minimal support for switchable devices.

@ This plugin does just one thing: it applies an indicator property to things
of the kind "animate", and a blank "before" property. This used to be
accomplished by the Standard Rules in a clumsy sort of way (with a direct I6
code injection), but in the age of Inter we want to avoid that sort of
tomfoolery.

=
void PL::Persons::start(void) {
	PluginManager::plug(COMPLETE_MODEL_PLUG, PL::Persons::IF_complete_model);
}

int PL::Persons::IF_complete_model(int stage) {
	if ((stage == WORLD_STAGE_III) && (K_person)) {
		property *P_animate = EitherOrProperties::new_nameless(I"animate");
//		RTProperties::recommend_storing_as_attribute(P_animate, TRUE);
		property *P_before = ValueProperties::new_nameless(I"before", K_value);
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object)
			if (Instances::of_kind(I, K_person)) {
				EitherOrProperties::assert(
					P_animate, Instances::as_subject(I), TRUE, CERTAIN_CE);
				ValueProperties::assert(P_before, Instances::as_subject(I),
					Rvalues::from_iname(Hierarchy::find(NULL_HL)), CERTAIN_CE);
			}
	}
	return FALSE;
}
