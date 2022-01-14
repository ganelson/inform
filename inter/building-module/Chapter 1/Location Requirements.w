[LocationRequirements::] Location Requirements.

@ Each //hierarchy_location// comes with a //location_requirement//. This might,
for example, express the idea "locate this resource inside the properties
submodule for the current compilation unit".

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
	int must_be_main_source_text;
} location_requirement;

location_requirement LocationRequirements::blank(void) {
	location_requirement req;
	req.any_submodule_package_of_this_identity = NULL;
	req.this_exact_package = NULL;
	req.this_exact_package_not_yet_created = -1;
	req.any_package_of_this_type = NULL;
	req.any_enclosure = FALSE;
	req.must_be_plug = FALSE;
	req.must_be_main_source_text = FALSE;
	return req;
}

@ Here are creator functions, then:

=
location_requirement LocationRequirements::local_submodule(submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.any_submodule_package_of_this_identity = sid;
	return req;
}

location_requirement LocationRequirements::completion_submodule(inter_tree *I,
	submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = LargeScale::completion_submodule(I, sid);
	req.must_be_main_source_text = TRUE;
	return req;
}

location_requirement LocationRequirements::generic_submodule(inter_tree *I,
	submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = LargeScale::generic_submodule(I, sid);
	return req;
}

location_requirement LocationRequirements::synoptic_submodule(inter_tree *I,
	submodule_identity *sid) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = LargeScale::synoptic_submodule(I, sid);
	return req;
}

location_requirement LocationRequirements::any_package_of_type(text_stream *ptype_name) {
	location_requirement req = LocationRequirements::blank();
	req.any_package_of_this_type = Str::duplicate(ptype_name);
	return req;
}

location_requirement LocationRequirements::any_enclosure(void) {
	location_requirement req = LocationRequirements::blank();
	req.any_enclosure = TRUE;
	return req;
}

location_requirement LocationRequirements::architectural_package(inter_tree *I) {
	return LocationRequirements::this_package(LargeScale::architecture_request(I));
}

location_requirement LocationRequirements::this_package(package_request *P) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package = P;
	return req;
}

location_requirement LocationRequirements::this_exotic_package(int N) {
	location_requirement req = LocationRequirements::blank();
	req.this_exact_package_not_yet_created = N;
	return req;
}

location_requirement LocationRequirements::plug(void) {
	location_requirement req = LocationRequirements::blank();
	req.must_be_plug = TRUE;
	return req;
}
