[RTActions::] Actions.

To compile the actions submodule for a compilation unit, which contains
_action packages.

@h Compilation data.
Each |action_name| object contains this data:

=
typedef struct action_compilation_data {
	struct wording metadata_name;
	int translated;
	struct text_stream *translated_name;
	struct package_request *an_package;
	struct inter_name *an_base_iname; /* e.g., |Take| */
	struct inter_name *an_double_sharp_iname; /* e.g., |##Take| */
	struct inter_name *an_processing_fn_iname; /* e.g., |TakeSub| */
	struct inter_name *variables_id; /* for the shared variables set */
	struct parse_node *where_created;
	int an_specification_text_word; /* description used in index */
	struct parse_node *designers_specification; /* where created */
} action_compilation_data;

action_compilation_data RTActions::new_data(wording W) {
	action_compilation_data acd;
	acd.metadata_name = W;
	acd.translated = FALSE;
	acd.translated_name = NULL;
	acd.an_double_sharp_iname = NULL;
	acd.an_base_iname = NULL;
	acd.an_processing_fn_iname = NULL;
	acd.an_package = NULL;
	acd.variables_id = NULL;
	acd.where_created = current_sentence;
	acd.designers_specification = NULL;
	acd.an_specification_text_word = -1;
	return acd;
}

@ As usual, package requests and inter names are generated on demand.

=
package_request *RTActions::package(action_name *an) {
	if (an->compilation_data.an_package == NULL)
		an->compilation_data.an_package =
			Hierarchy::local_package_to(ACTIONS_HAP, an->compilation_data.where_created);
	return an->compilation_data.an_package;
}

@ This is the ID for the set of variables used by this action.

=
inter_name *RTActions::variables_id(action_name *an) {
	if (an->compilation_data.variables_id == NULL)
		an->compilation_data.variables_id =
			Hierarchy::make_iname_in(ACTION_SHV_ID_HL, RTActions::package(an));
	return an->compilation_data.variables_id;
}

@ Base name, from which the other names are derived:

=
inter_name *RTActions::base_iname(action_name *an) {
	if (an->compilation_data.an_base_iname == NULL) {
		if (waiting_action == an)
			an->compilation_data.an_base_iname =
				Hierarchy::make_iname_in(WAIT_HL, RTActions::package(an));
		else if (Str::len(an->compilation_data.translated_name) > 0)
			an->compilation_data.an_base_iname =
				Hierarchy::make_iname_with_specific_translation(TRANSLATED_BASE_NAME_HL,
					an->compilation_data.translated_name, RTActions::package(an));
		else
			an->compilation_data.an_base_iname =
				Hierarchy::make_iname_with_shorter_memo(ACTION_BASE_NAME_HL,
					RTActions::package(an), ActionNameNames::tensed(an, IS_TENSE));
	}
	return an->compilation_data.an_base_iname;
}

@ We actually want the other names to still be related to the base name even
after a translation; i.e., if an action is translated to |Grab|, then we want
to have the related names be |##Grab| and |GrabSub|. So translation needs to
happen early-ish in the run, before the base iname is generated.

=
void RTActions::translate(action_name *an, wording W) {
	if (an->compilation_data.translated) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_TranslatesActionAlready),
			"this action has already been translated",
			"so there must be some duplication somewhere.");
		return;
	}
	if (an->compilation_data.an_base_iname)
		internal_error("too late for action base name translation");
	an->compilation_data.translated = TRUE;
	an->compilation_data.translated_name = Str::new();
	WRITE_TO(an->compilation_data.translated_name, "%N", Wordings::first_wn(W));
	LOGIF(ACTION_CREATIONS, "Translated action: $l as %W\n", an, W);
}

text_stream *RTActions::identifier(action_name *an) {
	return InterNames::to_text(RTActions::base_iname(an));
}

@ The convention of writing actions with a |##| prefix is lost in the mists of
early Inform history. It's harmless enough, though.

=
inter_name *RTActions::double_sharp(action_name *an) {
	if (an->compilation_data.an_double_sharp_iname == NULL)
		an->compilation_data.an_double_sharp_iname =
			Hierarchy::derive_iname_in(DOUBLE_SHARP_NAME_HL,
				RTActions::base_iname(an), RTActions::package(an));
	return an->compilation_data.an_double_sharp_iname;
}

@ Similarly, the function to carry out an action has been named with a |Sub|
suffix for as long as anyone can remember. "Sub" simply meant "subroutine",
and has its roots in Inform 1's predecessor, a Z-machine assembler called "zass".
Again, we keep these conventions because why not. They are at least familiar
to anyone reading the Inform 6 code we generate.

=
inter_name *RTActions::Sub(action_name *an) {
	if (an->compilation_data.an_processing_fn_iname == NULL) {
		an->compilation_data.an_processing_fn_iname =
			Hierarchy::derive_iname_in(PERFORM_FN_HL,
				RTActions::base_iname(an), RTActions::package(an));
		Hierarchy::make_available(an->compilation_data.an_processing_fn_iname);
	}
	return an->compilation_data.an_processing_fn_iname;
}

void RTActions::actions_set_specification_text(action_name *an, int wn) {
	an->compilation_data.an_specification_text_word = wn;
}

@h Compilation.

=
void RTActions::compile(void) {
	action_name *an;
	LOOP_OVER(an, action_name) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "action %W", an->compilation_data.metadata_name);
		Sequence::queue(&RTActions::compilation_agent, STORE_POINTER_action_name(an), desc);
	}
}

void RTActions::compilation_agent(compilation_subtask *t) {
	action_name *an = RETRIEVE_POINTER_action_name(t->data);
	package_request *pack = RTActions::package(an);
	@<Compile action ID@>;
	@<Compile double-sharp constant@>;
	@<Compile miscellaneous metadata@>;
	if (SharedVariables::set_empty(an->action_variables) == FALSE)
		@<Compile creator function for shared variables@>;
	@<Compile the performance function@>;
	@<Compile the debugging function@>;
}

@<Compile action ID@> =
	inter_name *iname = Hierarchy::make_iname_in(ACTION_ID_HL, pack);
	Emit::numeric_constant(iname, 0); /* placeholder, corrected in linking */

@<Compile double-sharp constant@> =
	inter_name *ds_iname = RTActions::double_sharp(an);
	Emit::unchecked_numeric_constant(ds_iname, (inter_ti) an->allocation_id);
	Hierarchy::make_available(ds_iname);

@<Compile miscellaneous metadata@> =
	Hierarchy::apply_metadata_from_wording(pack, ACTION_NAME_MD_HL,
		an->compilation_data.metadata_name);
	Hierarchy::apply_metadata_from_raw_wording(pack, ACTION_PAST_NAME_MD_HL,
		an->naming_data.past_name);
	Hierarchy::apply_metadata_from_number(pack, ACTION_AT_MD_HL,
		(inter_ti) Wordings::first_wn(an->compilation_data.metadata_name));
	Emit::numeric_constant(RTActions::variables_id(an), 0);
	if (Str::get_first_char(RTActions::identifier(an)) == '_')
		Hierarchy::apply_metadata_from_number(pack, NO_CODING_MD_HL, 1);
	inter_name *dsc = Hierarchy::make_iname_in(ACTION_DSHARP_MD_HL, pack);
	Emit::iname_constant(dsc, K_value, RTActions::double_sharp(an));
	Hierarchy::apply_metadata_from_number(pack,
		OUT_OF_WORLD_MD_HL, (inter_ti) ActionSemantics::is_out_of_world(an));
	Hierarchy::apply_metadata_from_number(pack,
		REQUIRES_LIGHT_MD_HL, (inter_ti) ActionSemantics::requires_light(an));
	Hierarchy::apply_metadata_from_number(pack,
		CAN_HAVE_NOUN_MD_HL, (inter_ti) ActionSemantics::can_have_noun(an));
	Hierarchy::apply_metadata_from_number(pack,
		CAN_HAVE_SECOND_MD_HL, (inter_ti) ActionSemantics::can_have_second(an));
	Hierarchy::apply_metadata_from_number(pack,
		NOUN_ACCESS_MD_HL, (inter_ti) ActionSemantics::noun_access(an));
	Hierarchy::apply_metadata_from_number(pack,
		SECOND_ACCESS_MD_HL, (inter_ti) ActionSemantics::second_access(an));
	inter_name *kn_iname = Hierarchy::make_iname_in(NOUN_KIND_MD_HL, pack);
	RTKindIDs::define_constant_as_strong_id(kn_iname, ActionSemantics::kind_of_noun(an));
	inter_name *ks_iname = Hierarchy::make_iname_in(SECOND_KIND_MD_HL, pack);
	RTKindIDs::define_constant_as_strong_id(ks_iname, ActionSemantics::kind_of_second(an));
	wording SW = Node::get_text(an->compilation_data.designers_specification);
	if (Wordings::nonempty(SW))
		Hierarchy::apply_metadata_from_wording(pack, ACTION_SPECIFICATION_MD_HL, SW);
	if (an->compilation_data.an_specification_text_word >= 0)
		Hierarchy::apply_metadata_from_wording(pack, ACTION_DESCRIPTION_MD_HL,
			Wordings::one_word(an->compilation_data.an_specification_text_word));

	heading *definition_area = Headings::of_wording(ActionNameNames::tensed(an, IS_TENSE));
	inform_extension *this_extension =
		Headings::get_extension_containing(definition_area);
	if (this_extension == NULL) {
		Hierarchy::apply_metadata(pack,
			ACTION_INDEX_HEADING_MD_HL, I"Defined in the source");
	} else if (Extensions::is_standard(this_extension)) {
		TEMPORARY_TEXT(credit)
		WRITE_TO(credit, "From the extension ");
		Extensions::write_name_to_file(this_extension, credit);
		Hierarchy::apply_metadata(pack, ACTION_INDEX_HEADING_MD_HL, credit);
		DISCARD_TEXT(credit)
	} else {
		TEMPORARY_TEXT(credit)
		WRITE_TO(credit, "From the extension ");
		Extensions::write_name_to_file(this_extension, credit);
		WRITE_TO(credit, " by ");
		Extensions::write_author_to_file(this_extension, credit);
		Hierarchy::apply_metadata(pack, ACTION_INDEX_HEADING_MD_HL, credit);
		DISCARD_TEXT(credit)
	}
	TEMPORARY_TEXT(subh)
	wording W = Headings::get_text(definition_area);
	if ((this_extension) && (Extensions::is_standard(this_extension) == FALSE)) {
		WRITE_TO(subh, "Miscellaneous");
	} else if (Wordings::nonempty(W)) {
		RTPhrasebook::index_definition_area(subh, W, TRUE);
	} else {
		WRITE_TO(subh, "New actions");
	}
	Hierarchy::apply_metadata(pack, ACTION_INDEX_SUBHEADING_MD_HL, subh);
	DISCARD_TEXT(subh)

	TEMPORARY_TEXT(disp)
	int j = Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE));
	int somethings = 0;
	while (j <= Wordings::last_wn(ActionNameNames::tensed(an, IS_TENSE))) {
		if (<object-pronoun>(Wordings::one_word(j))) {
			RTActions::print_something(disp, an, somethings++);
		} else {
			WRITE_TO(disp, "%+W ", Wordings::one_word(j));
		}
		j++;
	}
	if (somethings < ActionSemantics::max_parameters(an))
		RTActions::print_something(disp, an, somethings++);
	Hierarchy::apply_metadata(pack, ACTION_DISPLAY_NAME_MD_HL, disp);
	DISCARD_TEXT(disp)
	
	RTActions::write_shared_variable_metadata(pack, an->action_variables);

	Hierarchy::apply_metadata_from_iname(pack, ACTION_CHECK_MD_HL,
		RTRulebooks::id_iname(an->check_rules));
	Hierarchy::apply_metadata_from_iname(pack, ACTION_CARRY_OUT_MD_HL,
		RTRulebooks::id_iname(an->carry_out_rules));
	Hierarchy::apply_metadata_from_iname(pack, ACTION_REPORT_MD_HL,
		RTRulebooks::id_iname(an->report_rules));

@<Compile creator function for shared variables@> =
	inter_name *iname = Hierarchy::make_iname_in(ACTION_STV_CREATOR_FN_HL, pack);
	RTSharedVariables::compile_creator_fn(an->action_variables, iname);
	inter_name *vc = Hierarchy::make_iname_in(ACTION_VARC_MD_HL, pack);
	Emit::iname_constant(vc, K_value, iname);

@ The "perform" function for an action, typically called something like |TakeSub|,
consists only of a call to a generic action-performing function; that function
takes our three rulebooks as arguments.

@<Compile the performance function@> =
	packaging_state save = Functions::begin(RTActions::Sub(an));
	EmitCode::inv(RETURN_BIP);
	EmitCode::down();
		inter_name *generic_iname = Hierarchy::find(GENERICVERBSUB_HL);
		EmitCode::call(generic_iname);
		EmitCode::down();
			EmitCode::val_iname(K_value, RTRulebooks::id_iname(an->check_rules));
			EmitCode::val_iname(K_value, RTRulebooks::id_iname(an->carry_out_rules));
			EmitCode::val_iname(K_value, RTRulebooks::id_iname(an->report_rules));
		EmitCode::up();
	EmitCode::up();
	Functions::end(save);

@ The "debugging" function is used by the ACTIONS debugging command, and prints
a description of the current action, on the assumption that the action name is
the function is attached to.

@<Compile the debugging function@> = 
	inter_name *iname = Hierarchy::derive_iname_in(DEBUG_ACTION_FN_HL,
		RTActions::base_iname(an), pack);
	Hierarchy::apply_metadata_from_iname(pack, DEBUG_ACTION_MD_HL, iname);
	packaging_state save = Functions::begin(iname);
	inter_symbol *n_s = LocalVariables::new_other_as_symbol(I"n");
	inter_symbol *s_s = LocalVariables::new_other_as_symbol(I"s");
	inter_symbol *for_say_s = LocalVariables::new_other_as_symbol(I"for_say");

	int j = Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE)),
		j0 = -1, somethings = 0, clc = 0;
	while (j <= Wordings::last_wn(ActionNameNames::tensed(an, IS_TENSE))) {
		if (<object-pronoun>(Wordings::one_word(j))) {
			if (j0 >= 0) {
				@<Insert a space here if needed to break up the action name@>;

				TEMPORARY_TEXT(AT)
				RTActions::print_action_text_to(Wordings::new(j0, j-1),
					Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE)), AT);
				EmitCode::inv(PRINT_BIP);
				EmitCode::down();
					EmitCode::val_text(AT);
				EmitCode::up();
				DISCARD_TEXT(AT)

				j0 = -1;
			}
			@<Insert a space here if needed to break up the action name@>;
			EmitCode::inv(IFELSE_BIP);
			EmitCode::down();
				EmitCode::inv(EQ_BIP);
				EmitCode::down();
					EmitCode::val_symbol(K_value, for_say_s);
					EmitCode::val_number(2);
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					EmitCode::inv(PRINT_BIP);
					EmitCode::down();
						EmitCode::val_text(I"it");
					EmitCode::up();
				EmitCode::up();
				EmitCode::code();
				EmitCode::down();
					RTActions::print_noun_or_second(an, somethings++, n_s, s_s);
				EmitCode::up();
			EmitCode::up();
		} else {
			if (j0<0) j0 = j;
		}
		j++;
	}
	if (j0 >= 0) {
		@<Insert a space here if needed to break up the action name@>;
		TEMPORARY_TEXT(AT)
		RTActions::print_action_text_to(Wordings::new(j0, j-1),
			Wordings::first_wn(ActionNameNames::tensed(an, IS_TENSE)), AT);
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(AT);
		EmitCode::up();
		DISCARD_TEXT(AT)
	}
	if (somethings < ActionSemantics::max_parameters(an)) {
		EmitCode::inv(IF_BIP);
		EmitCode::down();
			EmitCode::inv(NE_BIP);
			EmitCode::down();
				EmitCode::val_symbol(K_value, for_say_s);
				EmitCode::val_number(2);
			EmitCode::up();
			EmitCode::code();
			EmitCode::down();
				@<Insert a space here if needed to break up the action name@>;
				RTActions::print_noun_or_second(an, somethings++, n_s, s_s);
			EmitCode::up();
		EmitCode::up();
	}
	Functions::end(save);

@<Insert a space here if needed to break up the action name@> =
	if (clc++ > 0) {
		EmitCode::inv(PRINT_BIP);
		EmitCode::down();
			EmitCode::val_text(I" ");
		EmitCode::up();
	}

@ And that uses these little utilities:

=
void RTActions::print_action_text_to(wording W, int start, OUTPUT_STREAM) {
	if (Wordings::first_wn(W) == start) {
		WRITE("%W", Wordings::first_word(W));
		W = Wordings::trim_first_word(W);
		if (Wordings::empty(W)) return;
		WRITE(" ");
	}
	WRITE("%+W", W);
}

void RTActions::print_noun_or_second(action_name *an, int n, inter_symbol *n_s, inter_symbol *s_s) {
	kind *K = (n == 0)?ActionSemantics::kind_of_noun(an):ActionSemantics::kind_of_second(an);
	inter_symbol *var = (n == 0)?n_s:s_s;

	if (Kinds::Behaviour::is_object(K) == FALSE)
		var = InterNames::to_symbol(Hierarchy::find(PARSED_NUMBER_HL));
	EmitCode::inv(INDIRECT1V_BIP);
	EmitCode::down();
		EmitCode::val_iname(K_value, RTKindConstructors::debug_print_fn_iname(K));
		if ((K_understanding) && (Kinds::eq(K, K_understanding))) {
			EmitCode::inv(PLUS_BIP);
			EmitCode::down();
				EmitCode::inv(TIMES_BIP);
				EmitCode::down();
					EmitCode::val_number(100);
					EmitCode::val_iname(K_number, Hierarchy::find(CONSULT_FROM_HL));
				EmitCode::up();
				EmitCode::val_iname(K_number, Hierarchy::find(CONSULT_WORDS_HL));
			EmitCode::up();
		} else {
			EmitCode::val_symbol(K_value, var);
		}
	EmitCode::up();
}

void RTActions::print_something(OUTPUT_STREAM, action_name *an, int argc) {
	kind *K = NULL; /* redundant assignment to appease |gcc -O2| */
	HTML::begin_span(OUT, I"indexdullblue");
	if (argc == 0) K = ActionSemantics::kind_of_noun(an);
	if (argc == 1) K = ActionSemantics::kind_of_second(an);
	if (Kinds::Behaviour::is_object(K)) WRITE("something");
	else if ((K_understanding) && (Kinds::eq(K, K_understanding))) WRITE("some text");
	else Kinds::Textual::write(OUT, K);
	HTML::end_span(OUT);
	WRITE(" ");
}

void RTActions::write_shared_variable_metadata(package_request *R, shared_variable_set *set) {
	shared_variable *shv;
	LOOP_OVER_LINKED_LIST(shv, shared_variable, set->variables) {
		nonlocal_variable *nlv = SharedVariables::get_variable(shv);
		package_request *sv = Hierarchy::package_within(ACTION_VARIABLES_HAP, R);

		Hierarchy::apply_metadata_from_raw_wording(sv, ACTION_VAR_NAME_MD_HL, nlv->name);
		Hierarchy::apply_metadata_from_number(sv, ACTION_VAR_AT_MD_HL,
			(inter_ti) Wordings::first_wn(nlv->name));
		if (Wordings::nonempty(nlv->var_documentation_symbol)) {
			TEMPORARY_TEXT(ixt)
			WRITE_TO(ixt, "%+W", Wordings::one_word(Wordings::first_wn(nlv->var_documentation_symbol)));
			Hierarchy::apply_metadata(sv, ACTION_VAR_DOCUMENTATION_MD_HL, ixt);
			DISCARD_TEXT(ixt)
		}
		TEMPORARY_TEXT(vk)
		Kinds::Textual::write(vk, nlv->nlv_kind);
		Hierarchy::apply_metadata(sv, ACTION_VAR_KIND_MD_HL, vk);
		DISCARD_TEXT(vk)
	}
}
