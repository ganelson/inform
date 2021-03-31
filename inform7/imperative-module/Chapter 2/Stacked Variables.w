[StackedVariables::] Stacked Variables.

To permit variables to have scopes intermediate between local and
global: for example, to be shared by all rules in a given rulebook.

@h Definitions.

=
typedef struct stacked_variable {
	struct wording name; /* text of the name */
	struct parse_node *assigned_at; /* sentence assigning it */
	struct nonlocal_variable *underlying_var; /* the variable in question */
	int owner_id; /* who owns this */
	int offset_in_owning_frame; /* word offset of storage (counts from 0) */
	struct wording match_wording_text; /* matching text (relevant for action variables only) */
	CLASS_DEFINITION
} stacked_variable;

typedef struct stacked_variable_set {
	int no_stvs;
	int recognition_id;
	struct linked_list *list_of_stvs; /* of |stacked_variable| */
	struct inter_name *creator_fn_iname;
	CLASS_DEFINITION
} stacked_variable_set;

typedef struct stacked_variable_access_list {
	struct linked_list *sets; /* of |stacked_variable_set| */
	CLASS_DEFINITION
} stacked_variable_access_list;

@

= (early code)
int max_frame_size_needed = 0;

@ =
int StackedVariables::get_owner_id(stacked_variable *stv) {
	return stv->owner_id;
}

int StackedVariables::get_offset(stacked_variable *stv) {
	return stv->offset_in_owning_frame;
}

kind *StackedVariables::get_kind(stacked_variable *stv) {
	nonlocal_variable *nlv = StackedVariables::get_variable(stv);
	return NonlocalVariables::kind(nlv);
}

nonlocal_variable *StackedVariables::get_variable(stacked_variable *stv) {
	if (stv == NULL) return NULL;
	return stv->underlying_var;
}

void StackedVariables::set_matching_text(stacked_variable *stv, wording W) {
	stv->match_wording_text = W;
}

wording StackedVariables::get_matching_text(stacked_variable *stv) {
	return stv->match_wording_text;
}

stacked_variable *StackedVariables::parse_match_clause(stacked_variable_set *set,
	wording W) {
	stacked_variable *stv;
	LOOP_OVER_LINKED_LIST(stv, stacked_variable, set->list_of_stvs)
		if (Wordings::starts_with(W, stv->match_wording_text))
			return stv;
	return NULL;
}

stacked_variable_set *StackedVariables::new_set(int id) {
	stacked_variable_set *set = CREATE(stacked_variable_set);
	set->recognition_id = id;
	set->no_stvs = 0;
	set->list_of_stvs = NEW_LINKED_LIST(stacked_variable);
	set->creator_fn_iname = NULL;
	return set;
}

int StackedVariables::set_empty(stacked_variable_set *set) {
	if (set->no_stvs == 0) return TRUE;
	return FALSE;
}

stacked_variable *StackedVariables::add_empty(stacked_variable_set *set,
	wording W, kind *K) {
	stacked_variable *stv = CREATE(stacked_variable);
	nonlocal_variable *q;
	W = Articles::remove_the(W);
	stv->name = W;
	stv->owner_id = set->recognition_id;
	stv->offset_in_owning_frame = set->no_stvs++;
	stv->assigned_at = current_sentence;
	stv->match_wording_text = EMPTY_WORDING;
	ADD_TO_LINKED_LIST(stv, stacked_variable, set->list_of_stvs);
	if (set->no_stvs > max_frame_size_needed)
		max_frame_size_needed = set->no_stvs;
	q = NonlocalVariables::new_with_scope(W, K, stv);
	stv->underlying_var = q;
	RTVariables::set_I6_identifier(q, FALSE, RTVariables::stv_rvalue(stv));
	RTVariables::set_I6_identifier(q, TRUE, RTVariables::stv_lvalue(stv));
	return stv;
}

stacked_variable_access_list *StackedVariables::new_access_list(void) {
	stacked_variable_access_list *nstvol = CREATE(stacked_variable_access_list);
	nstvol->sets = NEW_LINKED_LIST(stacked_variable_set);
	return nstvol;
}

void StackedVariables::add_set_to_access_list(stacked_variable_access_list *access,
	stacked_variable_set *set) {
	if (access) {
		stacked_variable_set *existing;
		LOOP_OVER_LINKED_LIST(existing, stacked_variable_set, access->sets)
			if (existing == set)
				return;
		ADD_TO_LINKED_LIST(set, stacked_variable_set, access->sets);
	}
}

void StackedVariables::append_access_list(stacked_variable_access_list *access,
	stacked_variable_access_list *extras) {
	stacked_variable_set *set;
	if ((extras) && (access))
		LOOP_OVER_LINKED_LIST(set, stacked_variable_set, extras->sets)
			StackedVariables::add_set_to_access_list(access, set);
}

void StackedVariables::index_owner(OUTPUT_STREAM, stacked_variable_set *set) {
	stacked_variable *stv;
	LOOP_OVER_LINKED_LIST(stv, stacked_variable, set->list_of_stvs)
		if (stv->underlying_var) {
			HTML::open_indented_p(OUT, 2, "tight");
			IXVariables::index_one(OUT, stv->underlying_var);
			HTML_CLOSE("p");
		}
}

stacked_variable *StackedVariables::parse_from_access_list(stacked_variable_access_list *access,
	wording W) {
	if (Wordings::empty(W)) return NULL;
	W = Articles::remove_the(W);
	stacked_variable_set *set;
	if (access)
		LOOP_OVER_LINKED_LIST(set, stacked_variable_set, access->sets) {
			stacked_variable *stv = StackedVariables::parse_from_list(set->list_of_stvs, W);
			if (stv) return stv;
		}
	return NULL;
}

stacked_variable *StackedVariables::parse_from_list(linked_list *stvl, wording W) {
	stacked_variable *stv;
	LOOP_OVER_LINKED_LIST(stv, stacked_variable, stvl)
		if (Wordings::match(stv->name, W))
			return stv;
	return NULL;
}

int StackedVariables::compile_frame_creator(stacked_variable_set *set, inter_name *iname) {
	if (set == NULL) return 0;

	packaging_state save = Routines::begin(iname);
	inter_symbol *pos_s = LocalVariables::add_named_call_as_symbol(I"pos");
	inter_symbol *state_s = LocalVariables::add_named_call_as_symbol(I"state");

	Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
	Produce::down(Emit::tree());
		Produce::inv_primitive(Emit::tree(), EQ_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, state_s);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			@<Compile frame creator if state is set@>;
		Produce::up(Emit::tree());
		Produce::code(Emit::tree());
		Produce::down(Emit::tree());
			@<Compile frame creator if state is clear@>;
		Produce::up(Emit::tree());
	Produce::up(Emit::tree());

	int count = LinkedLists::len(set->list_of_stvs);

	Produce::inv_primitive(Emit::tree(), RETURN_BIP);
	Produce::down(Emit::tree());
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) count);
	Produce::up(Emit::tree());

	Routines::end(save);
	set->creator_fn_iname = iname;
	return count;
}

@<Compile frame creator if state is set@> =
	stacked_variable *stv;
	LOOP_OVER_LINKED_LIST(stv, stacked_variable, set->list_of_stvs) {
		nonlocal_variable *q = StackedVariables::get_variable(stv);
		kind *K = NonlocalVariables::kind(q);
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Produce::down(Emit::tree());
			Produce::inv_primitive(Emit::tree(), LOOKUPREF_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MSTACK_HL));
				Produce::val_symbol(Emit::tree(), K_value, pos_s);
			Produce::up(Emit::tree());
			if (Kinds::Behaviour::uses_pointer_values(K))
				RTKinds::emit_heap_allocation(RTKinds::make_heap_allocation(K, 1, -1));
			else
				RTVariables::emit_initial_value_as_val(q);
		Produce::up(Emit::tree());

		Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, pos_s);
		Produce::up(Emit::tree());
	}

@<Compile frame creator if state is clear@> =
	stacked_variable *stv;
	LOOP_OVER_LINKED_LIST(stv, stacked_variable, set->list_of_stvs) {
		nonlocal_variable *q = StackedVariables::get_variable(stv);
		kind *K = NonlocalVariables::kind(q);
		if (Kinds::Behaviour::uses_pointer_values(K)) {
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(BLKVALUEFREE_HL));
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), LOOKUP_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(MSTACK_HL));
					Produce::val_symbol(Emit::tree(), K_value, pos_s);
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		}
		Produce::inv_primitive(Emit::tree(), POSTINCREMENT_BIP);
		Produce::down(Emit::tree());
			Produce::ref_symbol(Emit::tree(), K_value, pos_s);
		Produce::up(Emit::tree());
	}

@ =
inter_name *StackedVariables::frame_creator(stacked_variable_set *set) {
	return set->creator_fn_iname;
}
