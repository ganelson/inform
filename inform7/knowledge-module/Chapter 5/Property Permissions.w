[World::Permissions::] Property Permissions.

To enforce the domain of properties: for instance, that a door can
be open or closed but that an animal cannot, or that a person can have a
carrying capacity but that a door cannot.

@ Properties are pieces of data attached to their "owners", but they also
have a common identity wherever they turn up. For example, the property
"carrying capacity" is owned by any person and also by any container, but
it has a common meaning in each case, and in each case it's a number.

Only values can own properties at run-time, but kinds can own properties
during compilation. Thus the Standard Rules declare that the kinds "person"
and "container" have a number called "carrying capacity", and we record
that as a single property which has two owners, both kinds. In the final
story file as compiled, each individual person and container then inherits
the property.

And so each inference subject has a list of properties it can provide,
and each property a list of subjects it can be provided by. These are each
lists of //property_permission// objects.

=
typedef struct property_permission {
	struct inference_subject *property_owner; /* to whom permission is granted */
	struct property *property_granted; /* which property is permitted */

	struct parse_node *where_granted; /* sentence granting the permission */

	struct general_pointer pp_storage_data; /* how we'll compile this at run-time */
	void *plugin_pp[MAX_PLUGINS]; /* storage for plugins to attach, if they want to */

	CLASS_DEFINITION
} property_permission;

@h Seeking permission.
Note that an either/or property and its antonym (say, "open" and "closed")
are equivalent here: permission for one is always permission for the other.

If these were long lists, or searched often, it would be faster to move each
found permission to the front, thus tending to move frequently-sought properties
to the start. Pofiling shows that this would save no significant time,
whereas the unpredictable order might make testing Inform more annoying.

@d LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn)
	LOOP_OVER_LINKED_LIST(pp, property_permission, Properties::get_permissions(prn))
@d LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs)
	LOOP_OVER_LINKED_LIST(pp, property_permission, InferenceSubjects::get_permissions(infs))

=
property_permission *World::Permissions::find(inference_subject *infs,
	property *prn, int allow_inheritance) {
	property *prnbar = NULL;
	if (Properties::is_either_or(prn)) prnbar = Properties::EitherOr::get_negation(prn);

	if (prn)
		while (infs) {
			property_permission *pp;
			LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs)
				if ((pp->property_granted == prn) || (pp->property_granted == prnbar))
					return pp;
			infs = (allow_inheritance)?
					(InferenceSubjects::narrowest_broader_subject(infs)):NULL;
		}

	return NULL;
}

@h Granting permission.
This does nothing if permission already exists, simply returning the existing
permission structure; but note the use of |allow_inheritance|. If this is
set to |FALSE|, and we call for the "carrying capacity" property of the
player (say), then we may create a new permission even though the player's
kind ("person") already has one. This is intentional.[1]

[1] It means that plugins can specify different data about permissions when
applied to specific instances -- see the example of the jar below.

=
property_permission *World::Permissions::grant(inference_subject *infs, property *prn,
	int allow_inheritance) {
	property_permission *new_pp = World::Permissions::find(infs, prn, allow_inheritance);
	if (new_pp == NULL) {
		LOGIF(PROPERTY_PROVISION, "Allowing $j to provide $Y\n", infs, prn);
		@<Create the new permission structure@>;
		@<Add the new permission to the owner's list@>;
		@<Add the new permission to the property's list@>;
		@<Notify plugins that a new permission has been issued@>;
	}
	return new_pp;
}

@<Create the new permission structure@> =
	new_pp = CREATE(property_permission);
	new_pp->property_owner = infs;
	new_pp->property_granted = prn;
	new_pp->where_granted = current_sentence;
	new_pp->pp_storage_data = InferenceSubjects::new_permission_granted(infs);

@<Add the new permission to the owner's list@> =
	linked_list *L = InferenceSubjects::get_permissions(infs);
	ADD_TO_LINKED_LIST(new_pp, property_permission, L);

@<Add the new permission to the property's list@> =
	linked_list *L = Properties::get_permissions(prn);
	ADD_TO_LINKED_LIST(new_pp, property_permission, L);

@ Complicating matters, plugins have the ability to attach data of their
own to a permission. For instance, the "parsing" plugin attaches the idea
of a property being visible -- we might say that every thing has an
interior colour, but that it is invisible in the case of a dog and visible
in the case of a broken jar.

@<Notify plugins that a new permission has been issued@> =
	for (int i=0; i<MAX_PLUGINS; i++) new_pp->plugin_pp[i] = NULL;
	Plugins::Call::new_permission_notify(new_pp);

@ These two macros provide access to plugin-specific permission data:

@d PLUGIN_PP(id, pp)
	((id##_pp_data *) pp->plugin_pp[id##_plugin->allocation_id])

@d CREATE_PLUGIN_PP_DATA(id, pp, creator)
	(pp)->plugin_pp[id##_plugin->allocation_id] = (void *) (creator(pp));

@h Boring access functions.

=
property *World::Permissions::get_property(property_permission *pp) {
	return pp->property_granted;
}

inference_subject *World::Permissions::get_subject(property_permission *pp) {
	return pp->property_owner;
}

general_pointer World::Permissions::get_storage_data(property_permission *pp) {
	return pp->pp_storage_data;
}

parse_node *World::Permissions::where_granted(property_permission *pp) {
	return pp->where_granted;
}
