[StoredActionLiterals::] Stored Action Literals.

Explicit actions stored in memory as literals.

@h Runtime representation.
Literal stored actions arise from source text such as:
= (text as Inform 7)
	let Q be examining the harmonium;
=
This is called only from the actions plugin; in Basic Inform no stored actions
exist, so if the function is called then an internal error will be thrown.

Stored actions are stored in small blocks, always of size 6. There are no
long blocks.
= (text)
	                    small block:
	Q ----------------> action name
	                    first noun
	                    second noun
	                    actor
	                    request
	                    command text
=
See //WorldModelKit: StoredAction// for more. Note that literals do not arise
from typed commands, so they have no command text, and the final word is
therefore always 0 for literal actions.

The default is "waiting":
=
inter_name *StoredActionLiterals::default(void) {
	inter_name *small_block = Enclosures::new_small_block_for_constant();
	packaging_state save = EmitArrays::begin_late(small_block, K_value);
	RTKinds::emit_block_value_header(K_stored_action, FALSE, 6);
	EmitArrays::iname_entry(RTActions::double_sharp(ActionsPlugin::default_action_name()));
	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	EmitArrays::iname_entry(RTInstances::value_iname(I_yourself));
	EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	return small_block;
}

inter_name *StoredActionLiterals::small_block(explicit_action *ea) {
	if (K_stored_action == NULL) internal_error("no stored action kind exists");
	inter_name *small_block = Enclosures::new_small_block_for_constant();
	packaging_state save = EmitArrays::begin_late(small_block, K_value);

	RTKinds::emit_block_value_header(K_stored_action, FALSE, 6);
	action_name *an = ea->action;
	EmitArrays::iname_entry(RTActions::double_sharp(an));

	int request_bits = (ea->request)?1:0;
	if (ea->first_noun) {
		if ((K_understanding) &&
			(Rvalues::is_CONSTANT_of_kind(ea->first_noun, K_understanding))) {
			request_bits = request_bits | 16;
			TEMPORARY_TEXT(BC)
			inter_name *iname = TextLiterals::to_value(Node::get_text(ea->first_noun));
			EmitArrays::iname_entry(iname);
			DISCARD_TEXT(BC)
		} else CompileValues::to_array_entry(ea->first_noun);
	} else {
		EmitArrays::numeric_entry(0);
	}
	if (ea->second_noun) {
		if ((K_understanding) &&
			(Rvalues::is_CONSTANT_of_kind(ea->second_noun, K_understanding))) {
			request_bits = request_bits | 32;
			inter_name *iname = TextLiterals::to_value(Node::get_text(ea->second_noun));
			EmitArrays::iname_entry(iname);
		} else CompileValues::to_array_entry(ea->second_noun);
	} else {
		EmitArrays::numeric_entry(0);
	}
	if (ea->actor) {
		CompileValues::to_array_entry(ea->actor);
	} else
		EmitArrays::iname_entry(RTInstances::value_iname(I_yourself));
	EmitArrays::numeric_entry((inter_ti) request_bits);
	EmitArrays::numeric_entry(0);
	EmitArrays::end(save);
	return small_block;
}

