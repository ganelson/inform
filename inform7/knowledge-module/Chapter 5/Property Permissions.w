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

So "value" is not quite the correct concept for "something which owns a
property" -- not only does that fail to allow for kinds, it also puts in
too much; the number 176 is a value, but cannot own properties. Similarly,
"specification" is far too broad a category. But "inference-subject" is
a natural choice, because actual and potential property ownership are
so closely tied together.

@ Each inference-subject (or INFS) has a list of "property permissions",
each of which gives it permission to own a given property. Each INFS can
also inherit from a more general INFS, and it gets those permissions
automatically. So every individual door has permission to have the "open"
property automatically provided that the "door" kind's INFS has such a
permission. (This prevents our memory from filling up with unnecessary
permissions.)

In addition, it's efficient for each property also to have a list of the
permissions granted for it -- in effect, a "who owns me" list.

That means that whenever a new property permission is created, it must be
entered into two lists -- one for the property, one for the owner.
Fortunately, permissions are never revoked.

To return to the previous example, the "carrying capacity" property would
have a list of two permissions, $P_1$ and $P_2$. $P_1$ would also be found
in the list of permission for the INFS representing the kind "person",
and $P_2$ in the corresponding list for "container".

This doubled indexing is a tacit form of multiple-inheritance, even though
Inform 7 is officially a single-inheritance language from an objects-and-classes
point of view: "person" is not a kind of "container", nor vice versa,
but both effectively inherit the same behaviour to do with carrying capacity.

@ Complicating matters, plugins have the ability to attach data of their
own to a permission. For instance, the "parsing" plugin attaches the idea
of a property being visible -- we might say that every thing has an
interior colour, but that it is invisible in the case of a dog and visible
in the case of a broken jar. Because of this, we need to make it possible
for the same property to have multiple permissions in the inheritance
hierarchy above a single point: the jar has a permission for "interior
colour" of its own, even though it inherits this permission from "thing"
in any case.

@ Anyway, here is a property permission:

=
typedef struct property_permission {
	struct inference_subject *property_owner; /* to whom permission is granted */
	struct property_permission *next_for_this_owner; /* in list of permissions */

	struct property *property_granted; /* which property is permitted */
	struct property_permission *next_for_this_property; /* in list of permissions */

	struct parse_node *where_granted; /* sentence granting the permission */

	struct general_pointer pp_storage_data; /* how we'll compile this at run-time */
	void *plugin_pp[MAX_PLUGINS]; /* storage for plugins to attach, if they want to */

	CLASS_DEFINITION
} property_permission;

@ These macros simply provide access to plugin data, exactly as for world
objects.

@d PLUGIN_PP(id, pp)
	((id##_pp_data *) pp->plugin_pp[id##_plugin->allocation_id])

@d CREATE_PLUGIN_PP_DATA(id, pp, creator)
	(pp)->plugin_pp[id##_plugin->allocation_id] = (void *) (creator(pp));

@ This loop trawls through the two cross-lists:

@d LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn)
	for (pp = Properties::permission_list(prn); pp; pp = pp->next_for_this_property)
@d LOOP_OVER_PERMISSIONS_FOR_INFS(pp, infs)
	for (pp = *(InferenceSubjects::get_permissions(infs)); pp; pp = pp->next_for_this_owner)

@h Searching for permission.
Note that an either/or property and its antonym (say, "open" and "closed")
are equivalent here: to find one is to find the other.

If these were long lists, or searched often, it would be faster to move each
found permission to the front, thus tending to move frequently-sought properties
to the start. But profiling shows that this would save no significant time,
whereas the unpredictable order might make the Index or SHOWME output harder
to verify with |intest|.

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
			infs = (allow_inheritance)?(InferenceSubjects::narrowest_broader_subject(infs)):NULL;
		}

	return NULL;
}

@h Granting permission.
This does nothing if permission already exists, simply returning the existing
permission structure; but note the use of |allow_inheritance|. If this is
set to |FALSE|, and we call for the "carrying capacity" property of the
player (say), then we may create a new permission even though the player's
kind ("person") already has one. This is intentional -- it makes it possible
for a property to have different characteristics (say, visibility in the
parser) for some of its owners as compared with others.

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
	new_pp->where_granted = current_sentence;
	new_pp->pp_storage_data = InferenceSubjects::new_permission_granted(infs);

@<Add the new permission to the owner's list@> =
	new_pp->property_owner = infs;
	property_permission **ppl = InferenceSubjects::get_permissions(infs);
	if (*ppl == NULL) *ppl = new_pp;
	else {
		property_permission *pp = *ppl;
		while (pp->next_for_this_owner) pp = pp->next_for_this_owner;
		pp->next_for_this_owner = new_pp;
	}
	new_pp->next_for_this_owner = NULL;

@<Add the new permission to the property's list@> =
	new_pp->property_granted = prn;
	property_permission *pp = Properties::permission_list(prn);
	if (pp == NULL) {
		Properties::set_permission_list(prn, new_pp);
	} else {
		while (pp->next_for_this_property != NULL) pp = pp->next_for_this_property;
		pp->next_for_this_property = new_pp;
	}
	new_pp->next_for_this_property = NULL;

@<Notify plugins that a new permission has been issued@> =
	int i;
	for (i=0; i<MAX_PLUGINS; i++) new_pp->plugin_pp[i] = NULL;
	Plugins::Call::new_permission_notify(new_pp);

@h Miscellaneous.
With the two fundamental operations out of the way, there's not much left
to do except provide access to the details of the permission.

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

@ A case where it's convenient to run through permissions for a given
property -- when indexing who can own it.

=
void World::Permissions::index(OUTPUT_STREAM, property *prn) {
	int ac = 0, s;
	for (s = 1; s <= 2; s++) {
		property_permission *pp;
		LOOP_OVER_PERMISSIONS_FOR_PROPERTY(pp, prn) {
			wording W = InferenceSubjects::get_name_text(World::Permissions::get_subject(pp));
			if (Wordings::nonempty(W)) {
				if (s == 1) ac++;
				else {
					WRITE("</i>%+W<i>", W);
					ac--;
					if (ac == 1) WRITE(" or ");
					if (ac > 1) WRITE(", ");
				}
			}
		}
	}
}
