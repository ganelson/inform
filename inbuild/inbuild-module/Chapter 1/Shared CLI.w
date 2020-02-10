[SharedCLI::] Shared CLI.

A subset of command-line options shared by the tools which incorporate this
module.

@ We add the following switches:

@e NEST_CLSW
@e INTERNAL_CLSW
@e EXTERNAL_CLSW
@e TRANSIENT_CLSW

=
void SharedCLI::declare_options(void) {
	CommandLine::declare_switch(NEST_CLSW, L"nest", 2,
		L"add the nest at pathname X to the search list");
}

pathname *shared_transient_resources = NULL;

void SharedCLI::option(int id, int val, text_stream *arg, void *state) {
	switch (id) {
		case NEST_CLSW: SharedCLI::add_nest(Pathnames::from_text(arg), GENERIC_NEST_TAG); break;
		case INTERNAL_CLSW: SharedCLI::add_nest(Pathnames::from_text(arg), INTERNAL_NEST_TAG); break;
		case EXTERNAL_CLSW: SharedCLI::add_nest(Pathnames::from_text(arg), EXTERNAL_NEST_TAG); break;
		case TRANSIENT_CLSW: shared_transient_resources = Pathnames::from_text(arg); break;
	}
}

linked_list *unsorted_nest_list = NULL;
linked_list *shared_nest_list = NULL;
inbuild_nest *shared_internal_nest = NULL;
inbuild_nest *shared_external_nest = NULL;

inbuild_nest *SharedCLI::add_nest(pathname *P, int tag) {
	if (unsorted_nest_list == NULL)
		unsorted_nest_list = NEW_LINKED_LIST(inbuild_nest);
	inbuild_nest *N = Nests::new(P);
	Nests::set_tag(N, tag);
	ADD_TO_LINKED_LIST(N, inbuild_nest, unsorted_nest_list);
	if ((tag == EXTERNAL_NEST_TAG) && (shared_external_nest == NULL))
		shared_external_nest = N;
	if ((tag == INTERNAL_NEST_TAG) && (shared_internal_nest == NULL))
		shared_internal_nest = N;
	if (tag == INTERNAL_NEST_TAG) Nests::protect(N);
	return N;
}

inbuild_nest *SharedCLI::internal(void) {
	return shared_internal_nest;
}

inbuild_nest *SharedCLI::external(void) {
	return shared_external_nest;
}

pathname *SharedCLI::transient(void) {
	if (shared_transient_resources == NULL)
		if (shared_external_nest)
			return shared_external_nest->location;
	return shared_transient_resources;
}

@ 

@e NOT_A_NEST_TAG from 0
@e MATERIALS_NEST_TAG
@e EXTERNAL_NEST_TAG
@e GENERIC_NEST_TAG
@e INTERNAL_NEST_TAG

=
linked_list *SharedCLI::nest_list(void) {
	if (shared_nest_list == NULL) {
		shared_nest_list = NEW_LINKED_LIST(inbuild_nest);
		inbuild_nest *N;
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
			if (Nests::get_tag(N) == MATERIALS_NEST_TAG)
				ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
			if (Nests::get_tag(N) == EXTERNAL_NEST_TAG)
				ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
			if (Nests::get_tag(N) == GENERIC_NEST_TAG)
				ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
		LOOP_OVER_LINKED_LIST(N, inbuild_nest, unsorted_nest_list)
			if (Nests::get_tag(N) == INTERNAL_NEST_TAG)
				ADD_TO_LINKED_LIST(N, inbuild_nest, shared_nest_list);
	}
	return shared_nest_list;
}
