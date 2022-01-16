[LocationRequirements::] Location Requirements.

A way to express rules for the permitted places where inames and packages
are allowed to appear in the Inter hierarchy.

@ As seen in //Hierarchy Locations//, each //hierarchy_location// and
//hierarchy_attachment_point// stipulates something about where its resource
(an iname, a package) can aopear in the hierarchy. For example, that might be
"only in |/main/ingredients|", or "only in a package of type |_recipe|".

A variety of stipulations can be made, and with memory consumption unimportant
here, the following is really a union: almost all the fields will be left blank.

=
typedef struct location_requirement {
	struct submodule_identity *any_submodule_package_of_this_identity;
	struct package_request *this_exact_package;
	int this_exact_package_not_yet_created;
	struct text_stream *any_package_of_this_type;
	int any_enclosure;
	int must_be_plug;
} location_requirement;

location_requirement LocationRequirements::blank(void) {
	location_requirement req;
	req.any_submodule_package_of_this_identity = NULL;
	req.this_exact_package = NULL;
	req.this_exact_package_not_yet_created = -1;
	req.any_package_of_this_type = NULL;
	req.any_enclosure = FALSE;
	req.must_be_plug = FALSE;
	return req;
}

@ "You must put me in package |P|."

=
location_requirement LocationRequirements::this_package(package_request *P) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = P;
	return req;
}

@ "You can put me in any package of this type."

=
location_requirement LocationRequirements::any_package_of_type(text_stream *ptype_name) {
	location_requirement req = LocationRequirements::blank();
	req.any_package_of_this_type = Str::duplicate(ptype_name);
	return req;
}

@ "You can put me in any enclosing package." (See //LargeScale::package_type//
for what this means.)

=
location_requirement LocationRequirements::any_enclosure(void) {
	location_requirement req = LocationRequirements::blank();
	req.any_enclosure = TRUE;
	return req;
}

@ "You must put me in |/main/architectural|."

=
location_requirement LocationRequirements::architectural_package(inter_tree *I) {
	return LocationRequirements::this_package(LargeScale::architecture_request(I));
}

@ "You must put me in |/main/connectors|, as a plug."

=
location_requirement LocationRequirements::plug(void) {
	location_requirement req = LocationRequirements::blank();
	req.must_be_plug = TRUE;
	return req;
}

@ "You must put me in a submodule, identified by |sid|, of some module." In
practice, //inform7// uses this to place material in the module associated with
the compilation unit where the material came from -- the source text, or a
particular extension -- and this is why the term "local" is used.

=
location_requirement LocationRequirements::local_submodule(submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.any_submodule_package_of_this_identity = sid;
	return req;
}

@ "You must put me in a submodule, identified by |sid|, of the generic module."
So, for example, in |/main/generic/properties|, where |properties| is the
submodule.

=
location_requirement LocationRequirements::generic_submodule(inter_tree *I,
	submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = LargeScale::generic_submodule(I, sid);
	return req;
}

@ "You must put me in a submodule, identified by |sid|, of the synoptic module."

=
location_requirement LocationRequirements::synoptic_submodule(inter_tree *I,
	submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = LargeScale::synoptic_submodule(I, sid);
	return req;
}

@ "You must put me in a submodule, identified by |sid|, of the completion module."

=
location_requirement LocationRequirements::completion_submodule(inter_tree *I,
	submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = LargeScale::completion_submodule(I, sid);
	return req;
}

@ "You must put me somewhere exceptional." This is a hook used by //inform7//,
and which doesn't work in //inter// alone, for a handful of oddball cases
where a resource needs to be put somewhere strange. See //runtime: Hierarchy//.

=
location_requirement LocationRequirements::this_exotic_package(int N) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package_not_yet_created = N;
	return req;
}
