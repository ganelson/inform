[ShortNames::] Short Names.

To compile the "short name" and "capitalised short name" properties.

@ All versions of Inform, even Basic Inform, support the "short name" property.
The "capitalised short name" variant property, though, may not always exist.
It can be conjured into being by calling this function:

=
property *P_cap_short_name = NULL;
property *ShortNames::cap_short_name_property(void) {
	if (P_cap_short_name == NULL) {
		inter_name *property_iname = Hierarchy::find(CAPSHORTNAME_HL);
		P_cap_short_name = ValueProperties::new_nameless_using(
			K_text, RTKindConstructors::kind_package(K_object), property_iname);
		Hierarchy::make_available(property_iname);
	}
	return P_cap_short_name;
}

@ But in Basic Inform projects, that function may never be called, leaving
|P_cap_short_name| null. This is a problem for code in //BasicInformKit//,
which assumes that this name means something. So in that contingency we
define it to be equivalent to regular short name, thus:

=
void ShortNames::compile_cap_short_name(void) {
	if (P_cap_short_name == NULL) {
		inter_name *iname = Hierarchy::find(CAPSHORTNAME_HL);
		Emit::iname_constant(iname, K_value, Hierarchy::find(SHORT_NAME_HL));
		Hierarchy::make_available(iname);
	}
}

@ Most of the time the short name property holds text, in a straightforward
way: |"blue hat"|, say. But if the property belongs to an object created as
part of an assembly, then its name needs to contain that of the object it
was assembled from: say |"Marianne's blue hat"|, where |"Marianne"| is the
name of the owner.

If, however, the short name for |"Marianne"| varies -- through the use of
an activity -- then we want to respect that. So we don't give the name using
static text, but as a dynamic function, which first prints Marianne's name
through the usual apparatus, and then adds |"'s blue hat"| afterwards. That
way, if Marianne changes her name to Emilia, the result will be
|"Emilia's blue hat"|.

This function returns the name of the function to do this, and queues a compilation
request for it. |capped| is |TRUE| if the function is to be used in a capitalised
short name, and |FALSE| for regular.

=
typedef struct short_name_notice {
	struct inter_name *routine_iname;
	struct inter_name *snn_iname;
	struct instance *namee;
	struct inference_subject *after_subject;
	int capped;
	CLASS_DEFINITION
} short_name_notice;

inter_name *ShortNames::iname_for_short_name_fn(instance *I, inference_subject *subj,
	int capped) {
	short_name_notice *notice = CREATE(short_name_notice);
	notice->routine_iname = Hierarchy::make_iname_in(SHORT_NAME_FN_HL, RTInstances::package(I));
	notice->namee = I;
	notice->after_subject = subj;
	notice->capped = capped;
	notice->snn_iname = Hierarchy::make_iname_in(SHORT_NAME_PROPERTY_FN_HL, RTInstances::package(I));
	text_stream *desc = Str::new();
	WRITE_TO(desc, "short name for "); Instances::write(desc, I);
	Sequence::queue(&ShortNames::compilation_agent, STORE_POINTER_short_name_notice(notice), desc);
	return notice->snn_iname;
}

@ And here the function in question is compiled:

=
void ShortNames::compilation_agent(compilation_subtask *t) {
	short_name_notice *notice = RETRIEVE_POINTER_short_name_notice(t->data);
	instance *owner = Naming::object_this_is_named_after(notice->namee);
	packaging_state save = Functions::begin(notice->routine_iname);
	wording NA = Assertions::Assemblies::get_named_after_text(notice->after_subject);
	@<Print the owner's short name@>;
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(I"'s ");
	EmitCode::up();
	@<Print the assembled object's name@>;

	EmitCode::rtrue();
	Functions::end(save);

	save = EmitArrays::begin(notice->snn_iname, NULL);
	EmitArrays::iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
	EmitArrays::iname_entry(notice->routine_iname);
	EmitArrays::end(save);
}

@<Print the owner's short name@> =
	if (notice->capped) {
		inter_name *porname = Hierarchy::find(PRINTORRUN_HL);

		EmitCode::inv(IFELSE_BIP);
		EmitCode::down();
			EmitCode::inv(PROPERTYADDRESS_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, RTInstances::value_iname(owner));
				EmitCode::val_iname(K_value, Hierarchy::find(CAPSHORTNAME_HL));
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::call(porname);
				EmitCode::down();
					EmitCode::val_iname(K_value, RTInstances::value_iname(owner));
					EmitCode::val_iname(K_value, Hierarchy::find(CAPSHORTNAME_HL));
					EmitCode::val_number(1);
				EmitCode::up();
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				EmitCode::call(porname);
				EmitCode::down();
					EmitCode::val_iname(K_value, RTInstances::value_iname(owner));
					EmitCode::val_iname(K_value, Hierarchy::find(SHORT_NAME_HL));
					EmitCode::val_number(1);
				EmitCode::up();
			EmitCode::up();
		EmitCode::up();
	} else {
		inter_name *psnname = Hierarchy::find(PRINTSHORTNAME_HL);
		EmitCode::call(psnname);
		EmitCode::down();
			EmitCode::val_iname(K_value, RTInstances::value_iname(owner));
		EmitCode::up();
	}

@<Print the assembled object's name@> =
	TEMPORARY_TEXT(SNAMES)
	LOOP_THROUGH_WORDING(j, NA) {
		TranscodeText::from_wide_string(SNAMES, Lexer::word_raw_text(j), 0);
		if (j<Wordings::last_wn(NA)) WRITE_TO(SNAMES, " ");
	}
	EmitCode::inv(PRINT_BIP);
	EmitCode::down();
		EmitCode::val_text(SNAMES);
	EmitCode::up();
	DISCARD_TEXT(SNAMES)
