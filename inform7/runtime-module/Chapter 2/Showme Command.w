[RTShowmeCommand::] Showme Command.

A feature to provide some support for the SHOWME testing command.

@h Initialising.
This doesn't in fact do anything, except to provide one service when it's
plugged in.

=
int SHOWME_is_active = FALSE;
void RTShowmeCommand::start(void) {
	SHOWME_is_active = TRUE;
}

int RTShowmeCommand::needed_for_kind(kind *K) {
	if (SHOWME_is_active == FALSE) return FALSE;
	inference_subject *subj = KindSubjects::from_kind(K);
	property *prn;
	LOOP_OVER(prn, property)
		if (RTShowmeCommand::is_property_worth_SHOWME(subj, prn, NULL, NULL))
			return TRUE;
	return FALSE;
}

int RTShowmeCommand::needed_for_instance(instance *I) {
	if (SHOWME_is_active == FALSE) return FALSE;
	inference_subject *subj = Instances::as_subject(I);
	property *prn;
	LOOP_OVER(prn, property)
		if (RTShowmeCommand::is_property_worth_SHOWME(subj, prn, NULL, NULL))
			return TRUE;
	return FALSE;
}

@h Support for the SHOWME command.
And here is the one service. We must provide Inter functions, one for a
(property-owning) kind and one for an instance, which print out useful
diagnostic data about the current state of those properties.

object in the local variable |t_0| and prints out useful diagnostic data
about its current state. We get to use a local variable |na|, which stands
for "number of attributes", though that's really I6-speak: what we mean
is "number of either-or properties in the semicolon-separated list we
are currently printing out".

We will show either/or properties first, on their own line, and then value
properties.

=
void RTShowmeCommand::compile_kind_showme_fn(inter_name *iname, kind *K) {
	packaging_state save = Functions::begin(iname);
	inter_symbol *which_s = LocalVariables::new_other_as_symbol(I"which");
	inter_symbol *na_s = LocalVariables::new_other_as_symbol(I"na");
	inter_symbol *t_0_s = LocalVariables::new_other_as_symbol(I"t_0");
	EmitCode::inv(IFDEBUG_BIP);
	EmitCode::down();
		EmitCode::code();
		EmitCode::down();		
			EmitCode::inv(IFELSE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, which_s);
				EmitCode::code();
				EmitCode::down();
					RTShowmeCommand::compile_SHOWME_type_subj(TRUE,
						KindSubjects::from_kind(K), t_0_s, na_s);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					RTShowmeCommand::compile_SHOWME_type_subj(FALSE,
						KindSubjects::from_kind(K), t_0_s, na_s);
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();		
				EmitCode::val_symbol(K_value, na_s);
			EmitCode::up();		
		EmitCode::up();
	EmitCode::up();
	Functions::end(save);
}

@ And almost exactly similarly:

=
void RTShowmeCommand::compile_instance_showme_fn(inter_name *iname, instance *I) {
	inference_subject *subj = Instances::as_subject(I);
	packaging_state save = Functions::begin(iname);
	inter_symbol *which_s = LocalVariables::new_other_as_symbol(I"which");
	inter_symbol *na_s = LocalVariables::new_other_as_symbol(I"na");
	inter_symbol *t_0_s = LocalVariables::new_other_as_symbol(I"t_0");
	EmitCode::inv(IFDEBUG_BIP);
	EmitCode::down();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(IFELSE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, which_s);
				EmitCode::code();
				EmitCode::down();
					RTShowmeCommand::compile_SHOWME_type_subj(TRUE, subj, t_0_s, na_s);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					RTShowmeCommand::compile_SHOWME_type_subj(FALSE, subj, t_0_s, na_s);
				EmitCode::up();
			EmitCode::up();
			EmitCode::inv(RETURN_BIP);
			EmitCode::down();		
				EmitCode::val_symbol(K_value, na_s);
			EmitCode::up();		
		EmitCode::up();
	EmitCode::up();
	Functions::end(save);
}

@ Those call the following once each, with |val| set to |TRUE| to show value
properties, |FALSE| to show either/or.

The local variable |t_0| is the property owner, and |na_s| is a count of the
number of annotations made, which is used to keep the punctuation straight.

=
void RTShowmeCommand::compile_SHOWME_type_subj(int val, inference_subject *subj,
	inter_symbol *t_0_s, inter_symbol *na_s) {
	@<Skip if this object's definition has nothing to offer SHOWME@>;

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		InferenceSubjects::emit_element_of_condition(subj, t_0_s);
		EmitCode::code();
		EmitCode::down();
			@<Divide up the sublists of either/or properties in a SHOWME@>;
			@<Compile code which shows properties inherited from this object's definition@>;
		EmitCode::up();
	EmitCode::up();
}

@ This simply avoids compiling redundant empty |if| statements.

@<Skip if this object's definition has nothing to offer SHOWME@> =
	int todo = FALSE;
	property *prn;
	LOOP_OVER(prn, property)
		if (Properties::is_value_property(prn) == val)
			if (RTShowmeCommand::is_property_worth_SHOWME(subj, prn, t_0_s, na_s))
				todo = TRUE;
	if (todo == FALSE) return;

@ In the code running at this point, |na_s| holds the number of either/or
properties listed since the last time it was zeroed. If it's positive, we
need either a semicolon or a line break. If we're about to work on another
definition contributing either/or properties, the former; otherwise the
latter. Thus we end up with printed output such as
= (text)
	unlit, inedible, portable; male
=
where the first sublist of three either/ors comes from "thing", and the
second of just one from "person".

@<Divide up the sublists of either/or properties in a SHOWME@> =
	text_stream *divider = I"; ";
	if (val) divider = I"\n";
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::val_symbol(K_value, na_s);
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(STORE_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, na_s);
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::inv(PRINT_BIP);
			EmitCode::down();
				EmitCode::val_text(divider);
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();

@<Compile code which shows properties inherited from this object's definition@> =
	property *prn;
	LOOP_OVER(prn, property)
		if (Properties::is_value_property(prn) == val)
			RTShowmeCommand::compile_property_SHOWME(subj, prn, t_0_s, na_s);

@ We actually use the same function for both testing and compiling:

=
int RTShowmeCommand::is_property_worth_SHOWME(inference_subject *subj, property *prn,
	inter_symbol *t_0_s, inter_symbol *na_s) {
	return RTShowmeCommand::SHOWME_primitive(subj, prn, FALSE, t_0_s, na_s);
}

void RTShowmeCommand::compile_property_SHOWME(inference_subject *subj, property *prn,
	inter_symbol *t_0_s, inter_symbol *na_s) {
	RTShowmeCommand::SHOWME_primitive(subj, prn, TRUE, t_0_s, na_s);
}

@ So here goes.

=
int RTShowmeCommand::SHOWME_primitive(inference_subject *subj, property *prn, int comp,
	inter_symbol *t_0_s, inter_symbol *na_s) {
	if (RTProperties::is_shown_in_index(prn) == FALSE) return FALSE;
	if (RTProperties::can_be_compiled(prn) == FALSE) return FALSE;

	inference_subject *parent = InferenceSubjects::narrowest_broader_subject(subj);

	if ((PropertyPermissions::find(subj, prn, FALSE)) &&
		(PropertyPermissions::find(parent, prn, TRUE) == FALSE)) {
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
	kind *K = ValueProperties::kind(prn);
	if (K) {
		int require_nonzero = FALSE;
		if ((RTProperties::uses_non_typesafe_0(prn)) ||
			(Kinds::Behaviour::is_object(K)))
			require_nonzero = TRUE;
		if (require_nonzero) {
			EmitCode::inv(IF_BIP);
			EmitCode::down();
				inter_name *iname = Hierarchy::find(GPROPERTY_HL);
				EmitCode::call(iname);
				EmitCode::down();
					RTKindIDs::emit_weak_ID_as_val(K_object);
					EmitCode::val_symbol(K_value, t_0_s);
					EmitCode::val_iname(K_value, RTProperties::iname(prn));
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
		}
		@<Compile the SHOWME printing of the value of a value property@>;
		if (require_nonzero) {
				EmitCode::up();
			EmitCode::up();
		}
	}

@<Compile the SHOWME printing of the value of a value property@> =
	TEMPORARY_TEXT(T)
	WRITE_TO(T, "%+W: ", prn->name);
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(T);
	EmitCode::up();
	DISCARD_TEXT(T)

	if (Kinds::eq(K, K_text)) {
		EmitCode::inv(IFELSE_BIP);
		EmitCode::down();
			EmitCode::inv(EQ_BIP);
			EmitCode::down();
				EmitCode::call(Hierarchy::find(TEXT_TY_COMPARE_HL));
				EmitCode::down();
					EmitCode::call(Hierarchy::find(GPROPERTY_HL));
					EmitCode::down();
						RTKindIDs::emit_weak_ID_as_val(K_object);
						EmitCode::val_symbol(K_value, t_0_s);
						EmitCode::val_iname(K_value, RTProperties::iname(prn));
					EmitCode::up();
					EmitCode::val_iname(K_value, Hierarchy::find(EMPTY_TEXT_VALUE_HL));
				EmitCode::up();
				EmitCode::val_number(0);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(I"none");
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::inv(PRINTCHAR_BIP);
				EmitCode::down();
					EmitCode::val_number('\"');
				EmitCode::up();
				@<Compile the SHOWME of the actual value@>;
				EmitCode::inv(PRINTCHAR_BIP);
				EmitCode::down();
					EmitCode::val_number('\"');
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		@<Compile the SHOWME of the actual value@>;
	}

	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(I"\n");
	EmitCode::up();

@<Compile the SHOWME of the actual value@> =
	EmitCode::inv(INDIRECT1V_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, RTKindConstructors::printing_fn_iname(K));
		EmitCode::call(Hierarchy::find(GPROPERTY_HL));
		EmitCode::down();
			RTKindIDs::emit_weak_ID_as_val(K_object);
			EmitCode::val_symbol(K_value, t_0_s);
			EmitCode::val_iname(K_value, RTProperties::iname(prn));
		EmitCode::up();
	EmitCode::up();

@ Code in the kits is allowed to bar certain either/or properties using
|AllowInShowme|; it typically uses this to block distracting temporary-workspace
properties like "marked for listing" whose values have no significance
turn by turn.

@<Compile the SHOWME printing code for an either/or property@> =
	property *allow = prn;
	if (RTProperties::stored_in_negation(prn))
		allow = EitherOrProperties::get_negation(prn);

	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(AND_BIP);
		EmitCode::down();
			if (TargetVMs::debug_enabled(Task::vm())) {
				EmitCode::call(Hierarchy::find(ALLOWINSHOWME_HL));
				EmitCode::down();
					EmitCode::val_iname(K_value, RTProperties::iname(prn));
				EmitCode::up();
			} else {
				EmitCode::val_number(0);
			}
			EmitCode::test_if_symbol_has_property(K_value, t_0_s, prn);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			@<Compile the comma as needed@>;
			TEMPORARY_TEXT(T)
			WRITE_TO(T, "%+W", prn->name);
			EmitCode::inv(PRINT_BIP);
			EmitCode::down();
				EmitCode::val_text(T);
			EmitCode::up();
			DISCARD_TEXT(T)
		EmitCode::up();
	EmitCode::up();

@<Compile the comma as needed@> =
	EmitCode::inv(IF_BIP);
	EmitCode::down();
		EmitCode::inv(GT_BIP);
		EmitCode::down();
			EmitCode::inv(POSTINCREMENT_BIP);
			EmitCode::down();
				EmitCode::ref_symbol(K_value, na_s);
			EmitCode::up();
			EmitCode::val_number(0);
		EmitCode::up();
		EmitCode::code();
		EmitCode::down();
			EmitCode::inv(PRINT_BIP);
			EmitCode::down();
				EmitCode::val_text(I", ");
			EmitCode::up();
		EmitCode::up();
	EmitCode::up();
