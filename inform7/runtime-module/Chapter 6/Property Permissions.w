[RTPropertyPermissions::] Property Permissions.

Each property needs permission to be used, and here we emit the Inter statements
necessary.

@ Property details for kinds and instances are stored here:

=
package_request *RTPropertyPermissions::home(inference_subject *subj) {
	package_request *pack = NULL;
	instance *I = InstanceSubjects::to_instance(subj);
	if (I) pack = RTInstances::package(I);
	kind *K = KindSubjects::to_kind(subj);
	if (K) pack = RTKindConstructors::kind_package(K);
	return pack;
}

inter_name *RTPropertyPermissions::owner(inference_subject *subj) {
	inter_name *iname = NULL;
	instance *I = InstanceSubjects::to_instance(subj);
	if (I) iname = RTInstances::value_iname(I);
	kind *K = KindSubjects::to_kind(subj);
	if (K) iname = RTKindDeclarations::iname(K);
	return iname;
}

@ Properties of kinds are given permission inside the relevant kind's package:

=
void RTPropertyPermissions::emit_kind_permissions(kind *K) {
	inference_subject *subj = KindSubjects::from_kind(K);
	int c = 0;
	property_permission *pp;
	LOOP_OVER_PERMISSIONS_FOR_INFS(pp, subj) c++;
	if (c == 0) return;
	if (RTKindConstructors::is_nonstandard_enumeration(K))
		internal_error("nonstandard enumeration with properties");
	packaging_state save = Packaging::enter(RTPropertyPermissions::home(subj));
	inter_symbol *owner_s = Produce::kind_to_symbol(K);
	LOOP_OVER_PERMISSIONS_FOR_INFS(pp, subj)
		RTPropertyPermissions::emit_permission(pp->property_granted, owner_s, pp);
	if (Kinds::eq(K, K_object)) {
		property *prn;
		LOOP_OVER(prn, property)
			if (prn->Inter_level_only)
				RTPropertyPermissions::emit_permission(prn, owner_s, NULL);
	}
	Packaging::exit(Emit::tree(), save);
}

@ And properties of instances inside the relevant instance's package:

=
void RTPropertyPermissions::compile_permissions_for_instance(instance *I) {
	inference_subject *subj = Instances::as_subject(I);
	int c = 0;
	property_permission *pp;
	LOOP_OVER_PERMISSIONS_FOR_INFS(pp, subj) c++;
	if (c == 0) return;
	inter_name *inst_iname = RTInstances::value_iname(I);
	inter_symbol *inst_s = InterNames::to_symbol(inst_iname);
	packaging_state save = Packaging::enter(RTPropertyPermissions::home(subj));
	LOOP_OVER_PERMISSIONS_FOR_INFS(pp, subj)
		RTPropertyPermissions::emit_permission(pp->property_granted, inst_s, NULL);
	Packaging::exit(Emit::tree(), save);
}

@ And these both use:

=
void RTPropertyPermissions::emit_permission(property *prn, inter_symbol *owner_s,
	property_permission *pp) {
	if ((Properties::is_either_or(prn)) &&
		(prn->compilation_data.store_in_negation)) return;
	inter_name *storage_iname = NULL;
	if (pp) storage_iname = RTPropertyPermissions::get_table_storage_iname(pp);
	Emit::permission(prn, owner_s, storage_iname);
}

@h In-table storage.
Some kinds of non-object are created by table, with the table columns holding the
relevant property values. The following structure indicates which column of
which table will store the property values at run-time, or else is left as
|-1, 0| if the property values aren't living inside a table structure.

=
typedef struct property_permission_compilation_data {
	struct inter_name *storage_table_iname; /* for the relevant column array */
} property_permission_compilation_data;

property_permission_compilation_data RTPropertyPermissions::new_compilation_data(
	property_permission *pp) {
	property_permission_compilation_data ppcd;
	ppcd.storage_table_iname = NULL;
	return ppcd;
}

@ It's a little inconvenient to work out some elegant mechanism for the table
compilation code to tell each kind where it will be living, so instead we
rely on the fact that we're doing one at a time.

=
property_permission *latest_storage_worthy_pp_created = NULL; /* see below */

void RTPropertyPermissions::new_storage(property_permission *pp) {
	latest_storage_worthy_pp_created = pp;
}

void RTPropertyPermissions::set_table_storage_iname(inter_name *store) {
	if (latest_storage_worthy_pp_created)
		latest_storage_worthy_pp_created->compilation_data.storage_table_iname = store;
}

@ The code generator will need to know these numbers, so we will annotate
the property-permission symbol accordingly:

=
inter_name *RTPropertyPermissions::get_table_storage_iname(property_permission *pp) {
	if (pp == NULL) return NULL;
	return pp->compilation_data.storage_table_iname;
}
