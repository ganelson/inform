[Kinds::Knowledge::] Knowledge about Kinds.

How kinds can be inference subjects.

@h In principle every base kind gets its own inference subject, making it possible
to draw inferences from sentences such as:

>> A scene has a number called the witness count. The witness count of a scene is usually 4.

In practice we never need inferences for intermediate kinds, since they
don't last enough and aren't visible enough to have properties. We do need
exactly one inference subject per base kind: one for "scene" (as in the
above example), one for "text" and so on.

Constructed kinds like "list of scenes" have no properties, and no inferences
are drawn about them.

=
inference_subject_family *kinds_family = NULL;

inference_subject_family *Kinds::Knowledge::family(void) {
	if (kinds_family == NULL) {
		kinds_family = InferenceSubjects::new_family();
		METHOD_ADD(kinds_family, GET_DEFAULT_CERTAINTY_INFS_MTID,
			Kinds::Knowledge::certainty);
		METHOD_ADD(kinds_family, EMIT_ALL_INFS_MTID, Kinds::Knowledge::emit_all);
		METHOD_ADD(kinds_family, EMIT_ONE_INFS_MTID, Kinds::Knowledge::emit);
		METHOD_ADD(kinds_family, CHECK_MODEL_INFS_MTID, Kinds::Knowledge::check_model);
		METHOD_ADD(kinds_family, COMPLETE_MODEL_INFS_MTID, Kinds::Knowledge::complete_model);
		METHOD_ADD(kinds_family, EMIT_ELEMENT_INFS_MTID, Kinds::Knowledge::emit_element_of_condition);
		METHOD_ADD(kinds_family, GET_NAME_TEXT_INFS_MTID, Kinds::Knowledge::get_name_text);
		METHOD_ADD(kinds_family, MAKE_ADJ_CONST_DOMAIN_INFS_MTID, Kinds::Knowledge::make_adj_const_domain);
		METHOD_ADD(kinds_family, NEW_PERMISSION_GRANTED_INFS_MTID, Kinds::Knowledge::new_permission_granted);
	}
	return kinds_family;
}

int Kinds::Knowledge::certainty(inference_subject_family *f, inference_subject *infs) {
	return LIKELY_CE;	
}

kind *Kinds::Knowledge::nonobject_from_infs(inference_subject *infs) {
	kind *K = Kinds::Knowledge::from_infs(infs);
	if ((K) && (Kinds::Behaviour::is_subkind_of_object(K))) return NULL;
	return K;
}

kind *Kinds::Knowledge::from_infs(inference_subject *infs) {
	if ((infs) && (infs->infs_family == kinds_family)) {
		kind *K = Kinds::base_construction(
				RETRIEVE_POINTER_kind_constructor(infs->represents));
		return K;
	}
	return NULL;
}

inference_subject *Kinds::Knowledge::as_subject(kind *K) {
	if (K == NULL) return NULL;
	return K->construct->dt_knowledge;
}

void Kinds::Knowledge::set_subject(kind *K, inference_subject *infs) {
	if (K == NULL) return;
	K->construct->dt_knowledge = infs;
}

inference_subject *Kinds::Knowledge::create_for_constructor(kind_constructor *con) {
	return InferenceSubjects::new(global_constants,
		Kinds::Knowledge::family(), STORE_POINTER_kind_constructor(con), NULL);
}

@ This is used to overcome a timing problem. A few inference subjects need to
be defined early in Inform's run to set up relations -- "thing", for example.
So when we do finally create "thing" as a kind of object, it needs to be
matched up with the inference subject already existing.

=
void Kinds::Knowledge::renew(kind *K, kind *super, wording W) {
	inference_subject *revised = NULL;
	if (Wordings::nonempty(W)) Plugins::Call::name_to_early_infs(W, &revised);
	if (revised) {
		InferenceSubjects::infs_initialise(revised,
			STORE_POINTER_kind_constructor(K->construct), Kinds::Knowledge::family(),
			Kinds::Knowledge::as_subject(super), NULL);
		Kinds::Knowledge::set_subject(K, revised);
	}
}

@ Some values can have properties attached -- scenes, for instance -- while
others can't -- numbers or times, for instance. In general a value can have
properties only if its kind passes this test:

=
int Kinds::Knowledge::has_properties(kind *K) {
	if (K == NULL) return FALSE;
	if (Kinds::Behaviour::is_an_enumeration(K)) return TRUE;
	if (Kinds::Behaviour::is_object(K)) return TRUE;
	return FALSE;
}

@ This is one of Inform's sets of inference subjects, and here are the
routines to support them:

=
void Kinds::Knowledge::get_name_text(inference_subject_family *family,
	inference_subject *from, wording *W) {
	kind *K = Kinds::Knowledge::from_infs(from);
	*W = Kinds::Behaviour::get_name(K, FALSE);
}
void Kinds::Knowledge::complete_model(inference_subject_family *family, inference_subject *infs) { }
void Kinds::Knowledge::check_model(inference_subject_family *family, inference_subject *infs) { }

int Kinds::Knowledge::emit_element_of_condition(inference_subject_family *family, inference_subject *infs, inter_symbol *t0_s) {
	kind *K = Kinds::Knowledge::from_infs(infs);
	if (Kinds::Behaviour::is_subkind_of_object(K)) {
		Produce::inv_primitive(Emit::tree(), OFCLASS_BIP);
		Produce::down(Emit::tree());
			Produce::val_symbol(Emit::tree(), K_value, t0_s);
			Produce::val_iname(Emit::tree(), K_value, Kinds::RunTime::I6_classname(K));
		Produce::up(Emit::tree());
		return TRUE;
	}
	if (Kinds::eq(K, K_object)) {
		Produce::val_symbol(Emit::tree(), K_value, t0_s);
		return TRUE;
	}
	return FALSE;
}

@ As noted above, a POVS structure is attached to every property permission
concerning our kind.

=
void Kinds::Knowledge::new_permission_granted(inference_subject_family *f,
	inference_subject *from, general_pointer *G) {
	*G = STORE_POINTER_property_of_value_storage(
		Properties::OfValues::get_storage());
}

@ When a property value comes along which might have an adjectival use -- say,
"green" out of a range of possible colour nouns -- the following is called.
We simply pass the request along to the appropriate code.

=
void Kinds::Knowledge::make_adj_const_domain(inference_subject_family *family, inference_subject *infs,
	instance *nc, property *prn) {
	kind *K = Kinds::Knowledge::from_infs(infs);
	Instances::make_adj_const_domain(nc, prn, K, NULL);
}

@ These routines do actually do something big -- they emit the great stream
of Inter commands needed to define the kinds and their properties.

First, we will call |Properties::Emit::emit_subject| for all kinds of object,
beginning with object and working downwards through the tree of its subkinds.
After that, we call it for all other kinds able to have properties, in no
particular order.

=
int Kinds::Knowledge::emit_all(inference_subject_family *f, int ignored) {
	inter_name *iname = Hierarchy::find(MAX_WEAK_ID_HL);
	Emit::named_numeric_constant(iname, (inter_ti) next_free_data_type_ID);
	Kinds::Knowledge::emit_recursive(Kinds::Knowledge::as_subject(K_object));
	return FALSE;
}

void Kinds::Knowledge::emit_recursive(inference_subject *within) {
	Properties::Emit::emit_subject(within);
	inference_subject *subj;
	LOOP_OVER(subj, inference_subject)
		if ((InferenceSubjects::narrowest_broader_subject(subj) == within) &&
			(InferenceSubjects::is_a_kind_of_object(subj))) {
			Kinds::Knowledge::emit_recursive(subj);
		}
}

void Kinds::Knowledge::emit(inference_subject_family *f, inference_subject *infs) {
	kind *K = Kinds::Knowledge::from_infs(infs);
	if ((Kinds::Knowledge::has_properties(K)) &&
		(Kinds::Behaviour::is_object(K) == FALSE))
		Properties::Emit::emit_subject(infs);
	Properties::OfValues::check_allowable(K);
}

@ We use the hierarchy of inference subjects to represent the hierarchy of
kinds:

@d HIERARCHY_GET_SUPER_KINDS_CALLBACK Kinds::Knowledge::super
@d HIERARCHY_ALLOWS_SOMETIMES_MATCH_KINDS_CALLBACK Kinds::Knowledge::allow_sometimes
@d HIERARCHY_MOVE_KINDS_CALLBACK Kinds::Knowledge::move_within

=
kind *Kinds::Knowledge::super(kind *K) {
	inference_subject *infs = Kinds::Knowledge::as_subject(K);
	return Kinds::Knowledge::from_infs(InferenceSubjects::narrowest_broader_subject(infs));
}

void Kinds::Knowledge::move_within(kind *sub, kind *super) {
	if (Kinds::Behaviour::is_object(super))
		InferenceSubjects::falls_within(
			Kinds::Knowledge::as_subject(sub), Kinds::Knowledge::as_subject(super));
}

int Kinds::Knowledge::allow_sometimes(kind *from) {
	while (from) {
		if (Kinds::eq(from, K_object)) return TRUE;
		from = Latticework::super(from);
	}
	return FALSE;
}
