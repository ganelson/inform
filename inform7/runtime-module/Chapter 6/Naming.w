[RTNaming::] Naming.

@ 

=
property *P_cap_short_name = NULL;
property *RTNaming::cap_short_name_property(void) {
	if (P_cap_short_name == NULL) {
		inter_name *property_iname = Hierarchy::find(CAPSHORTNAME_HL);
		P_cap_short_name = ValueProperties::new_nameless_using(
			K_text, Kinds::Behaviour::package(K_object), property_iname);
		Hierarchy::make_available(Emit::tree(), property_iname);
	}
	return P_cap_short_name;
}

@h Short-name functions.
We accumulate requests for functions used for naming properties by keeping
"notices" of what needs to be made:

=
typedef struct short_name_notice {
	struct inter_name *routine_iname;
	struct inter_name *snn_iname;
	struct instance *namee;
	struct inference_subject *after_subject;
	int capped;
	CLASS_DEFINITION
} short_name_notice;

inter_name *RTNaming::iname_for_short_name_fn(instance *I, inference_subject *subj,
	int capped) {
	short_name_notice *notice = CREATE(short_name_notice);
	notice->routine_iname = Hierarchy::make_iname_in(SHORT_NAME_FN_HL, RTInstances::package(I));
	notice->namee = I;
	notice->after_subject = subj;
	notice->capped = capped;
	notice->snn_iname = Hierarchy::make_iname_in(SHORT_NAME_PROPERTY_FN_HL, RTInstances::package(I));
	return notice->snn_iname;
}

void RTNaming::compile_small_names(void) {
	short_name_notice *notice;
	LOOP_OVER(notice, short_name_notice) {
		instance *owner = Naming::object_this_is_named_after(notice->namee);
		packaging_state save = Functions::begin(notice->routine_iname);
		wording NA = Assertions::Assemblies::get_named_after_text(notice->after_subject);
		if (notice->capped) {
			inter_name *porname = Hierarchy::find(PRINTORRUN_HL);

			Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PROPERTYADDRESS_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(owner));
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CAPSHORTNAME_HL));
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), porname);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(owner));
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CAPSHORTNAME_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), porname);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(owner));
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SHORT_NAME_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), PRINTNAME_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, RTInstances::iname(owner));
			Produce::up(Emit::tree());
		}
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), I"'s ");
		Produce::up(Emit::tree());
		TEMPORARY_TEXT(SNAMES)
		LOOP_THROUGH_WORDING(j, NA) {
			CompiledText::from_wide_string(SNAMES, Lexer::word_raw_text(j), 0);
			if (j<Wordings::last_wn(NA)) WRITE_TO(SNAMES, " ");
		}
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), SNAMES);
		Produce::up(Emit::tree());
		DISCARD_TEXT(SNAMES)

		Produce::rtrue(Emit::tree());
		Functions::end(save);

		save = Emit::named_array_begin(notice->snn_iname, NULL);
		Emit::array_iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
		Emit::array_iname_entry(notice->routine_iname);
		Emit::array_end(save);
	}
}
void RTNaming::compile_cap_short_name(void) {
	if (P_cap_short_name == NULL) {
		inter_name *iname = Hierarchy::find(CAPSHORTNAME_HL);
		Emit::named_iname_constant(iname, K_value, Hierarchy::find(SHORT_NAME_HL));
		Hierarchy::make_available(Emit::tree(), iname);
	}
}
