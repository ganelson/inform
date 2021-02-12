[PL::Persons::] Persons.

A plugin giving minimal support for switchable devices.

@ The Persons plugin does just one thing: it applies an indicator property
to things of the kind "animate", and a blank "before" property. This used
to be accomplished by the Standard Rules in a clumsy sort of way (with a
direct I6 code injection), but in the age of Inter we want to avoid that
sort of tomfoolery.

= (early code)
property *P_animate = NULL;
property *P_before = NULL;

@ =
void PL::Persons::start(void) {
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Persons::IF_complete_model);
}


@ =
int PL::Persons::IF_complete_model(int stage) {
	if ((stage == 3) && (K_person)) {
		P_animate = Properties::EitherOr::new_nameless(L"animate");
		Properties::EitherOr::implement_as_attribute(P_animate, TRUE);
		P_before = Properties::Valued::new_nameless(I"before", K_value);
		instance *I;
		LOOP_OVER_INSTANCES(I, K_object)
			if (Instances::of_kind(I, K_person)) {
				Properties::EitherOr::assert(
					P_animate, Instances::as_subject(I), TRUE, CERTAIN_CE);
				Properties::Valued::assert(P_before, Instances::as_subject(I),
					Rvalues::from_iname(Hierarchy::find(NULL_HL)), CERTAIN_CE);
			}
	}
	return FALSE;
}
