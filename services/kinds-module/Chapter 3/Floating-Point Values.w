[Kinds::FloatingPoint::] Floating-Point Values.

To cope with promotions from integer to floating-point arithmetic.

@ In principle, we could recognise integer and real versions of any
dimensionless kind (if we really wanted, say, to distinguish "integer weight"
from "real weight"), but at present we allow only one such pair: |number|
and |real number|.

=
kind *Kinds::FloatingPoint::real_equivalent(kind *K) {
	if (Kinds::eq(K, K_number)) return K_real_number;
	return K;
}

kind *Kinds::FloatingPoint::integer_equivalent(kind *K) {
	if (Kinds::eq(K, K_real_number)) return K_number;
	return K;
}

@ There can be numerous other real-valued kinds; it's just that those don't
have integer equivalents.

=
int Kinds::FloatingPoint::uses_floating_point(kind *K) {
	if (K == NULL) return FALSE;
	return Kinds::Constructors::is_arithmetic_and_real(K->construct);
}

@ Inform's equations system has to handle promotion (from int to real) or
demotion (from real to int) quite carefully, and needs the following concept:

=
typedef struct generalised_kind {
	struct kind *valid_kind; /* must be non-null */
	int promotion; /* |0| for no change, |1| for "a real version", |-1| for "an int version" */
} generalised_kind;

@ =
generalised_kind Kinds::FloatingPoint::new_gk(kind *K) {
	if (K == NULL) internal_error("can't generalise the null kind");
	generalised_kind gK;
	gK.valid_kind = K;
	gK.promotion = 0;
	return gK;
}

void Kinds::FloatingPoint::log_gk(generalised_kind gK) {
	LOG("%u", gK.valid_kind);
	if (gK.promotion == 1) { LOG("=>real"); }
	if (gK.promotion == -1) { LOG("=>int"); }
}

@ Access to which:

=
kind *Kinds::FloatingPoint::underlying(generalised_kind gK) {
	return gK.valid_kind;
}

int Kinds::FloatingPoint::is_real(generalised_kind gK) {
	if (gK.promotion == 1) return TRUE;
	if (Kinds::FloatingPoint::uses_floating_point(gK.valid_kind)) return TRUE;
	return FALSE;
}

@ The following performs the operations "change to real" and "change to int":

=
generalised_kind Kinds::FloatingPoint::to_integer(generalised_kind gK) {
	if (Kinds::FloatingPoint::is_real(gK)) {
		if (gK.promotion == 1) gK.promotion = 0;
		else {
			kind *K = Kinds::FloatingPoint::integer_equivalent(gK.valid_kind);
			if (Kinds::FloatingPoint::uses_floating_point(K) == FALSE) gK.valid_kind = K;
			else gK.promotion = -1;
		}
	}
	if (Kinds::FloatingPoint::is_real(gK))
		internal_error("gK inconsistent");
	return gK;
}

generalised_kind Kinds::FloatingPoint::to_real(generalised_kind gK) {
	if (Kinds::FloatingPoint::is_real(gK) == FALSE) {
		if (gK.promotion == -1) gK.promotion = 0;
		else {
			kind *K = Kinds::FloatingPoint::real_equivalent(gK.valid_kind);
			if (Kinds::FloatingPoint::uses_floating_point(K)) gK.valid_kind = K;
			else gK.promotion = 1;
		}
	}
	if (Kinds::FloatingPoint::is_real(gK) == FALSE)
		internal_error("gK inconsistent");
	return gK;
}

@h Flotations.
This is where we compile Inter code to perform "flotation" -- promotion to real --
or "deflotation" -- demotion, but taking into account scale factors since the
integer versions may have been scaled.

=
#ifdef CORE_MODULE
void Kinds::FloatingPoint::begin_flotation_emit(kind *K) {
	if (Kinds::Behaviour::scale_factor(K) != 1) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_DIVIDE_HL));
		Produce::down(Emit::tree());
	}
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NUMBER_TY_TO_REAL_NUMBER_TY_HL));
	Produce::down(Emit::tree());
}

void Kinds::FloatingPoint::end_flotation_emit(kind *K) {
	Produce::up(Emit::tree());
	if (Kinds::Behaviour::scale_factor(K) != 1) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NUMBER_TY_TO_REAL_NUMBER_TY_HL));
		Produce::down(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
				(inter_ti) Kinds::Behaviour::scale_factor(K));
		Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}
}

void Kinds::FloatingPoint::begin_deflotation_emit(kind *K) {
	Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_TO_NUMBER_TY_HL));
	Produce::down(Emit::tree());
	if (Kinds::Behaviour::scale_factor(K) != 1) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_TIMES_HL));
		Produce::down(Emit::tree());
	}
}

void Kinds::FloatingPoint::end_deflotation_emit(kind *K) {
	if (Kinds::Behaviour::scale_factor(K) != 1) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_TO_NUMBER_TY_HL));
		Produce::down(Emit::tree());
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
				(inter_ti) Kinds::Behaviour::scale_factor(K));
		Produce::up(Emit::tree());
		Produce::up(Emit::tree());
	}
	Produce::up(Emit::tree());
}
#endif
