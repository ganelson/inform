[PL::Showme::] Showme Command.

A plugin to provide some support for the SHOWME testing command.

@h Initialising.
This doesn't in fact do anything, except to provide one service when it's
plugged in.

=
void PL::Showme::start(void) {
}

@h Support for the SHOWME command.
And here is the one service. We must compile I6 code which looks at the
object in the local variable |t_0| and prints out useful diagnostic data
about its current state. We get to use a local variable |na|, which stands
for "number of attributes", though that's really I6-speak: what we mean
is "number of either-or properties in the semicolon-separated list we
are currently printing out".

We will show either/or properties first, on their own line, and then value
properties.

=
void PL::Showme::compile_SHOWME_details(void) {
	if (Plugins::Manage::plugged_in(showme_plugin) == FALSE) return;
	packaging_state save = Routines::begin(Hierarchy::find(SHOWMEDETAILS_HL));
	inter_symbol *t_0_s = LocalVariables::add_named_call_as_symbol(I"t_0");
	inter_symbol *na_s = LocalVariables::add_named_call_as_symbol(I"na");
	Produce::inv_primitive(Produce::opcode(IFDEBUG_BIP));
	Produce::down();
		Produce::code();
		Produce::down();
			PL::Showme::compile_SHOWME_type(FALSE, t_0_s, na_s);
			PL::Showme::compile_SHOWME_type(TRUE, t_0_s, na_s);
		Produce::up();
	Produce::up();
	Routines::end(save);
}

void PL::Showme::compile_SHOWME_type(int val, inter_symbol *t_0_s, inter_symbol *na_s) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Compare::le(K, K_object))
			PL::Showme::compile_SHOWME_type_subj(val, Kinds::Knowledge::as_subject(K), t_0_s, na_s);
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I)
		PL::Showme::compile_SHOWME_type_subj(val, Instances::as_subject(I), t_0_s, na_s);
}

void PL::Showme::compile_SHOWME_type_subj(int val, inference_subject *subj, inter_symbol *t_0_s, inter_symbol *na_s) {
	@<Skip if this object's definition has nothing to offer SHOWME@>;

	Produce::inv_primitive(Produce::opcode(IF_BIP));
	Produce::down();
		InferenceSubjects::emit_element_of_condition(subj, t_0_s);
		Produce::code();
		Produce::down();
			@<Divide up the sublists of either/or properties in a SHOWME@>;
			@<Compile code which shows properties inherited from this object's definition@>;
		Produce::up();
	Produce::up();
}

@ This simply avoids compiling redundant empty |if| statements.

@<Skip if this object's definition has nothing to offer SHOWME@> =
	int todo = FALSE;
	property *prn;
	LOOP_OVER(prn, property)
		if (Properties::is_value_property(prn) == val)
			if (PL::Showme::is_property_worth_SHOWME(subj, prn, t_0_s, na_s))
				todo = TRUE;
	if (todo == FALSE) return;

@ In the code running at this point, |na| holds the number of either/or
properties listed since the last time it was zeroed. If it's positive, we
need either a semicolon or a line break. If we're about to work on another
definition contributing either/or properties, the former; otherwise the
latter. Thus we end up with printed output such as

	|unlit, inedible, portable; male|

where the first sublist of three either/ors comes from "thing", and the
second of just one from "person".

@<Divide up the sublists of either/or properties in a SHOWME@> =
	text_stream *divider = I"; ";
	if (val) divider = I"\n";
	Produce::inv_primitive(Produce::opcode(IF_BIP));
	Produce::down();
		Produce::inv_primitive(Produce::opcode(GT_BIP));
		Produce::down();
			Produce::val_symbol(K_value, na_s);
			Produce::val(K_number, LITERAL_IVAL, 0);
		Produce::up();
		Produce::code();
		Produce::down();
			Produce::inv_primitive(Produce::opcode(STORE_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, na_s);
				Produce::val(K_number, LITERAL_IVAL, 0);
			Produce::up();
			Produce::inv_primitive(Produce::opcode(PRINT_BIP));
			Produce::down();
				Produce::val_text(divider);
			Produce::up();
		Produce::up();
	Produce::up();

@<Compile code which shows properties inherited from this object's definition@> =
	property *prn;
	LOOP_OVER(prn, property)
		if (Properties::is_value_property(prn) == val)
			PL::Showme::compile_property_SHOWME(subj, prn, t_0_s, na_s);

@ We actually use the same routine for both testing and compiling:

=
int PL::Showme::is_property_worth_SHOWME(inference_subject *subj, property *prn, inter_symbol *t_0_s, inter_symbol *na_s) {
	return PL::Showme::SHOWME_primitive(subj, prn, FALSE, t_0_s, na_s);
}

void PL::Showme::compile_property_SHOWME(inference_subject *subj, property *prn, inter_symbol *t_0_s, inter_symbol *na_s) {
	PL::Showme::SHOWME_primitive(subj, prn, TRUE, t_0_s, na_s);
}

@ So here goes.

=
int PL::Showme::SHOWME_primitive(inference_subject *subj, property *prn, int comp, inter_symbol *t_0_s, inter_symbol *na_s) {
	if (Properties::is_shown_in_index(prn) == FALSE) return FALSE;
	if (Properties::can_be_compiled(prn) == FALSE) return FALSE;

	inference_subject *parent = InferenceSubjects::narrowest_broader_subject(subj);

	if ((World::Permissions::find(subj, prn, FALSE)) &&
		(World::Permissions::find(parent, prn, TRUE) == FALSE)) {
		if (comp) {
			if (Properties::is_value_property(prn))
				@<Compile the SHOWME printing code for a value property@>
			else
				@<Compile the SHOWME printing code for an either/or property@>;
		}
		return TRUE;
	}
	return FALSE;
}

@ In general we print the property value even if it's boringly equal to the
default value for the property's kind. For instance, we would print a "number"
property even if its value is 0. But we make two exceptions:

(a) We don't print "nothing" for an object property. The reason for this is
pragmatic: the "matching key" property in the Standard Rules rather
awkwardly has "thing" as its domain, even though it's only meaningful for
lockable things. This has to be true because it's used as the left domain of
a relation, and relation domains have to be kinds, not unions of kinds. But
that means that, for example, the player has a "matching key" property,
which is never likely to be used. We don't want to print this.

(b) We don't print a 0 value for a property used to store a relation whose
relevant domain is enumerative. For instance, if P holds a colour to which
an object is related, then P can validly be 0 at run-time (meaning: there's
no relation to any colour) even though this is not typesafe because 0 is
not a valid colour. Because of this, we can't print 0 using the printing
routine for colours; and the best thing is to print nothing at all.

@<Compile the SHOWME printing code for a value property@> =
	kind *K = Properties::Valued::kind(prn);
	if (K) {
		int require_nonzero = FALSE;
		if ((Properties::Valued::is_used_for_non_typesafe_relation(prn)) ||
			(Kinds::Compare::le(K, K_object)))
			require_nonzero = TRUE;
		if (require_nonzero) {
			Produce::inv_primitive(Produce::opcode(IF_BIP));
			Produce::down();
				inter_name *iname = Hierarchy::find(GPROPERTY_HL);
				Produce::inv_call_iname(iname);
				Produce::down();
					Kinds::RunTime::emit_weak_id_as_val(K_object);
					Produce::val_symbol(K_value, t_0_s);
					Produce::val_iname(K_value, Properties::iname(prn));
				Produce::up();
				Produce::code();
				Produce::down();
		}
		@<Compile the SHOWME printing of the value of a value property@>;
		if (require_nonzero) {
				Produce::up();
			Produce::up();
		}
	}

@<Compile the SHOWME printing of the value of a value property@> =
	TEMPORARY_TEXT(T);
	WRITE_TO(T, "%+W: ", prn->name);
	Produce::inv_primitive(Produce::opcode(PRINT_BIP));
	Produce::down();
		Produce::val_text(T);
	Produce::up();
	DISCARD_TEXT(T);

	if (Kinds::Compare::eq(K, K_text)) {
		Produce::inv_primitive(Produce::opcode(IFELSE_BIP));
		Produce::down();
			Produce::inv_primitive(Produce::opcode(EQ_BIP));
			Produce::down();
				Produce::inv_call_iname(Hierarchy::find(TEXT_TY_COMPARE_HL));
				Produce::down();
					Produce::inv_call_iname(Hierarchy::find(GPROPERTY_HL));
					Produce::down();
						Kinds::RunTime::emit_weak_id_as_val(K_object);
						Produce::val_symbol(K_value, t_0_s);
						Produce::val_iname(K_value, Properties::iname(prn));
					Produce::up();
					Produce::val_iname(K_value, Hierarchy::find(EMPTY_TEXT_VALUE_HL));
				Produce::up();
				Produce::val(K_number, LITERAL_IVAL, 0);
			Produce::up();
			Produce::code();
			Produce::down();
				Produce::inv_primitive(Produce::opcode(PRINT_BIP));
				Produce::down();
					Produce::val_text(I"none");
				Produce::up();
			Produce::up();
			Produce::code();
			Produce::down();
				Produce::inv_primitive(Produce::opcode(PRINTCHAR_BIP));
				Produce::down();
					Produce::val(K_number, LITERAL_IVAL, '\"');
				Produce::up();
				@<Compile the SHOWME of the actual value@>;
				Produce::inv_primitive(Produce::opcode(PRINTCHAR_BIP));
				Produce::down();
					Produce::val(K_number, LITERAL_IVAL, '\"');
				Produce::up();
			Produce::up();
		Produce::up();
	} else {
		@<Compile the SHOWME of the actual value@>;
	}

	Produce::inv_primitive(Produce::opcode(PRINT_BIP));
	Produce::down();
		Produce::val_text(I"\n");
	Produce::up();

@<Compile the SHOWME of the actual value@> =
	Produce::inv_primitive(Produce::opcode(INDIRECT1V_BIP));
	Produce::down();
		Produce::val_iname(K_value, Kinds::Behaviour::get_iname(K));
		Produce::inv_call_iname(Hierarchy::find(GPROPERTY_HL));
		Produce::down();
			Kinds::RunTime::emit_weak_id_as_val(K_object);
			Produce::val_symbol(K_value, t_0_s);
			Produce::val_iname(K_value, Properties::iname(prn));
		Produce::up();
	Produce::up();

@ The I6 template code is allowed to bar certain either/or properties using
|AllowInShowme|; it typically uses this to block distracting temporary-workspace
properties like "marked for listing" whose values have no significance
turn by turn.

@<Compile the SHOWME printing code for an either/or property@> =
	property *allow = prn;
	if (Properties::EitherOr::stored_in_negation(prn))
		allow = Properties::EitherOr::get_negation(prn);

	Produce::inv_primitive(Produce::opcode(IF_BIP));
	Produce::down();
		Produce::inv_primitive(Produce::opcode(AND_BIP));
		Produce::down();
			if ((this_is_a_release_compile == FALSE) || (this_is_a_debug_compile)) {
				Produce::inv_call_iname(Hierarchy::find(ALLOWINSHOWME_HL));
				Produce::down();
					Produce::val_iname(K_value, Properties::iname(prn));
				Produce::up();
			} else {
				Produce::val(K_number, LITERAL_IVAL, 0);
			}
			Properties::Emit::emit_has_property(K_value, t_0_s, prn);
		Produce::up();
		Produce::code();
		Produce::down();
			@<Compile the comma as needed@>;
			TEMPORARY_TEXT(T);
			WRITE_TO(T, "%+W", prn->name);
			Produce::inv_primitive(Produce::opcode(PRINT_BIP));
			Produce::down();
				Produce::val_text(T);
			Produce::up();
			DISCARD_TEXT(T);
		Produce::up();
	Produce::up();

@<Compile the comma as needed@> =
	Produce::inv_primitive(Produce::opcode(IF_BIP));
	Produce::down();
		Produce::inv_primitive(Produce::opcode(GT_BIP));
		Produce::down();
			Produce::inv_primitive(Produce::opcode(POSTINCREMENT_BIP));
			Produce::down();
				Produce::ref_symbol(K_value, na_s);
			Produce::up();
			Produce::val(K_number, LITERAL_IVAL, 0);
		Produce::up();
		Produce::code();
		Produce::down();
			Produce::inv_primitive(Produce::opcode(PRINT_BIP));
			Produce::down();
				Produce::val_text(I", ");
			Produce::up();
		Produce::up();
	Produce::up();
