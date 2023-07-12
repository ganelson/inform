[IndexStage::] Index Stage.

A pipeline stage for generating the index of an Inform project.

@ This is not really a general-purpose pipeline stage: it makes sense only in
the context of an Inform compilation run, and will (silently) do nothing if
run in any other pipeline.

=
void IndexStage::create_pipeline_stage(void) {
	ParsingPipelines::new_stage(I"index", IndexStage::run,
		NO_STAGE_ARG, FALSE);
}

@ The implementation here needs an |inform_project| structure to work from,
and that exists only in the //supervisor// module -- which is not a part of
the Inter stand-alone tool. So running |inter| at the command line does not
allow the indexer to do anything.

Moreover, and in a sneaky fashion, updating the extensions documentation and
generating an EPS map are also sometimes part of the indexing process, depending
on the command-line settings used when invoking |inform7|.

@d INDEX_REQUIRED_BIT 1
@d EXTENSIONS_INDEX_REQUIRED_BIT 2
@d EPS_MAP_REQUIRED_BIT 4

=
int IndexStage::run(pipeline_step *step) {
	#ifdef SUPERVISOR_MODULE
	inter_tree *I = step->ephemera.tree;
	int req = INDEX_REQUIRED_BIT;
	#ifdef CORE_MODULE
	req = Task::get_index_requirements();
	#endif
	inform_project *project = InterSkill::get_associated_project();
	if (project) {
		if ((req & INDEX_REQUIRED_BIT) ||
			(req & EPS_MAP_REQUIRED_BIT) ||
			(req & EXTENSIONS_INDEX_REQUIRED_BIT)) {
			index_session *session = IndexStage::index_session_for(I, project);
			if (req & INDEX_REQUIRED_BIT)
				Indexing::generate_index_website(session, Projects::index_structure(project));
			if (req & EXTENSIONS_INDEX_REQUIRED_BIT)
				ExtensionWebsite::update(project);
			#ifdef CORE_MODULE
			if (req & EPS_MAP_REQUIRED_BIT)
				Indexing::generate_EPS_map(session, Task::epsmap_file(), NULL);
			#endif
			Indexing::close_session(session);
		}
	}
	#endif
	return TRUE;
}

@ The actual indexing work is all done using the //Indexing API//.

=
#ifdef SUPERVISOR_MODULE
index_session *IndexStage::index_session_for(inter_tree *I, inform_project *project) {
	index_session *session = Indexing::open_session(I);
	inform_language *E = Languages::find_for(I"English", Projects::nest_list(project));
	inform_language *L = Projects::get_language_of_index(project);
	if (E != L)
		Indexing::localise(session,
			Filenames::in(Languages::path_to_bundle(E), I"Index.txt"));
	Indexing::localise(session,
		Filenames::in(Languages::path_to_bundle(L), I"Index.txt"));
	return session;
}
#endif
