[Inclusions::] Inclusions.

To fulfill requests to include extensions, adding their material
to the parse tree as needed, and removing INCLUDE nodes.

@ Our main task here is to look through the syntax tree for |INCLUDE_NT|
nodes, which are requests to include an extension, and replace them with
syntax trees for the extensions in question.

This process is repeated until there are no |INCLUDE_NT| nodes left.
In principle this could go on forever if A includes B which includes A, or
some such, but we log each extension read in to ensure that nothing is
read twice.

=
inbuild_copy *inclusions_errors_to = NULL;
inform_project *inclusions_for_project = NULL;

void Inclusions::traverse(inbuild_copy *C, parse_node_tree *T) {
	inclusions_errors_to = C;
	int no_copy_errors = LinkedLists::len(C->errors_reading_source_text);
	inform_project *project = ProjectBundleManager::from_copy(C);
	if (project == NULL) project = ProjectFileManager::from_copy(C);
	inclusions_for_project = project;
	int includes_cleared;
	do {
		includes_cleared = TRUE;
		if (LinkedLists::len(C->errors_reading_source_text) > no_copy_errors) break;
		SyntaxTree::traverse_headingwise(T, Inclusions::visit, &includes_cleared);
	} while (includes_cleared == FALSE);
	inclusions_errors_to = NULL;
}

build_vertex *Inclusions::spawned_from_vertex(parse_node *H0) {
	if (H0) {
		inform_extension *ext = Node::get_inclusion_of_extension(H0);
		if (ext) return ext->as_copy->vertex;
	}
	if (inclusions_errors_to == NULL) internal_error("no H0 ext or inclusion");
	return inclusions_errors_to->vertex;
}

void Inclusions::visit(parse_node_tree *T, parse_node *pn, parse_node *last_H0,
	int *includes_cleared) {
	if (Node::get_type(pn) == INCLUDE_NT) {
		@<Replace INCLUDE node with sentence nodes for any extensions required@>;
		*includes_cleared = FALSE;
	}
}

@ The INCLUDE node becomes an INCLUSION, which in turn contains the extension's code.

@<Replace INCLUDE node with sentence nodes for any extensions required@> =
	if (!(<structural-sentence>(Node::get_text(pn))))
		internal_error("malformed INCLUDE");
	wording title = GET_RW(<structural-sentence>, 1);
	wording author = GET_RW(<structural-sentence>, 2);
	Node::set_type(pn, INCLUSION_NT); pn->down = NULL;
	int l = SyntaxTree::push_bud(T, pn);
	inform_extension *E = Inclusions::fulfill_request_to_include_extension(last_H0,
		title, author, inclusions_for_project);
	SyntaxTree::pop_bud(T, l);
	if (E) {
		for (parse_node *c = pn->down; c; c = c->next)
			if (Node::get_type(c) == HEADING_NT)
				Node::set_inclusion_of_extension(c, E);
		if ((last_H0) &&
			(Annotations::read_int(last_H0, implied_heading_ANNOT) != TRUE)) {
			build_vertex *V = Inclusions::spawned_from_vertex(last_H0);
			build_vertex *EV = E->as_copy->vertex;
			if (V->as_copy->edition->work->genre == extension_genre)
				Graphs::need_this_to_use(V, EV);
			else
				Graphs::need_this_to_build(V, EV);
		}
	}

@ Here we parse the content of an Include sentence: i.e., what comes after the
word "Include", which might e.g. be "Locksmith by Emily Short".

=
<extension-title-and-version> ::=
	version <extension-version> of <definite-article> <extension-unversioned> |  ==> { pass 1 }
	version <extension-version> of <extension-unversioned> |                     ==> { pass 1 }
	<definite-article> <extension-unversioned> |                                 ==> { -1, - }
	<extension-unversioned>                                                      ==> { -1, - }

<extension-unversioned> ::=
	<extension-unversioned-inner> ( ... ) |  ==> { 0, - }
	<extension-unversioned-inner>            ==> { 0, - }

<extension-unversioned-inner> ::=
	<quoted-text> *** |  ==> @<Issue PM_IncludeExtQuoted problem@>
	...                  ==> { 0, -, <<t1>> = Wordings::first_wn(W), <<t2>> = Wordings::last_wn(W) }

@ Quite a popular mistake, this:

@<Issue PM_IncludeExtQuoted problem@> =
	<<t1>> = -1; <<t2>> = -1;
	copy_error *CE = CopyErrors::new(SYNTAX_CE, IncludeExtQuoted_SYNERROR);
	CopyErrors::supply_node(CE, current_sentence);
	Copies::attach_error(inclusions_errors_to, CE);

@ This nonterminal parses text which will probably be something like "3.14" or
"12/110410", but at this stage it accepts anything: actual parsing comes later.

=
<extension-version> internal 1 {
	==> { Wordings::first_wn(W), - };
	return TRUE;
}

@ =
inform_extension *Inclusions::fulfill_request_to_include_extension(parse_node *last_H0,
	wording TW, wording AW, inform_project *for_project) {
	inform_extension *E = NULL;
	<<t1>> = -1; <<t2>> = -1;
	<extension-title-and-version>(TW);
	wording W = Wordings::new(<<t1>>, <<t2>>);
	int version_word = <<r>>;

	if (Wordings::nonempty(W)) @<Fulfill request to include a single extension@>;
	return E;
}

@ A request consists of author, name and version, the latter being optional.
We obtain the extension file structure corresponding to this: it may have
no text at all (for instance if Inform could not open the file), or it may be
one we have seen before, thanks to an earlier inclusion. Only when it
provided genuinely new text will its |body_text_unbroken| flag be set,
and then we call the sentence-breaker to graft the new material on to the
parse tree.

@<Fulfill request to include a single extension@> =
	TEMPORARY_TEXT(exft)
	TEMPORARY_TEXT(exfa)
	WRITE_TO(exft, "%+W", W);
	WRITE_TO(exfa, "%+W", AW);
	inbuild_work *work = Works::new(extension_genre, exft, exfa);
	semantic_version_number V = VersionNumbers::null();
	if (version_word >= 0) V = Inclusions::parse_version(version_word);
	semver_range *R = VersionNumberRanges::compatibility_range(V);
	inbuild_requirement *req = Requirements::new(work, R);
	DISCARD_TEXT(exft)
	DISCARD_TEXT(exfa)

	E = Inclusions::load(last_H0, current_sentence, req, for_project);

@h Extension loading.
Note that we ignore a request for an extension which has already been
loaded, except if the new request ups the ante in terms of the minimum
version permitted: in which case we need to record that the requirement has
been tightened. That is, if we previously wanted version 2 of Pantomime
Sausages by Mr Punch, and loaded it, but then read the sentence

>> Include version 3 of Pantomime Sausages by Mr Punch.

then we need to note that the version requirement on PS has been raised to 3.

=
inform_extension *Inclusions::load(parse_node *last_H0, parse_node *at,
	inbuild_requirement *req, inform_project *for_project) {
	inform_extension *E = NULL;
	LOOP_OVER(E, inform_extension)
		if ((Requirements::meets(E->as_copy->edition, req)) &&
			(Copies::source_text_has_been_read(E->as_copy))) {
			Extensions::must_satisfy(E, req);
			return E;
		}
	@<Read the extension file into the lexer, and break it into body and documentation@>;
	if (for_project)
		ADD_TO_LINKED_LIST(E, inform_extension, for_project->extensions_included);
	return E;
}

@<Read the extension file into the lexer, and break it into body and documentation@> =
	inbuild_search_result *search_result =
		Nests::search_for_best(req, Projects::nest_list(for_project));
	if (search_result) {
		E = ExtensionManager::from_copy(search_result->copy);
		Extensions::set_inclusion_sentence(E, at);
		Extensions::set_associated_project(E, for_project);
		if (Nests::get_tag(search_result->nest) == INTERNAL_NEST_TAG)
			E->loaded_from_built_in_area = TRUE;
		compatibility_specification *C = E->as_copy->edition->compatibility;
		if (Compatibility::test(C, Supervisor::current_vm()) == FALSE)
			@<Issue a problem message saying that the VM does not meet requirements@>;

		if (LinkedLists::len(search_result->copy->errors_reading_source_text) == 0) {
			Copies::get_source_text(search_result->copy);
		}
		#ifndef CORE_MODULE
		Copies::list_attached_errors(STDERR, search_result->copy);
		#endif
	} else {
		#ifdef CORE_MODULE
		@<Issue a cannot-find problem@>;
		#endif
		build_vertex *RV = Graphs::req_vertex(req);
		build_vertex *V = Inclusions::spawned_from_vertex(last_H0);
		Graphs::need_this_to_build(V, RV);
	}

@ Here the problem is not that the extension is broken in some way: it's
just not what we can currently use. Therefore the correction should be a
matter of removing the inclusion, not of altering the extension, so we
report this problem at the inclusion line.

@<Issue a problem message saying that the VM does not meet requirements@> =
	copy_error *CE = CopyErrors::new_T(SYNTAX_CE, ExtInadequateVM_SYNERROR, C->parsed_from);
	CopyErrors::supply_node(CE, Extensions::get_inclusion_sentence(E));
	Copies::attach_error(inclusions_errors_to, CE);

@<Issue a cannot-find problem@> =
	inbuild_requirement *req2 = Requirements::any_version_of(req->work);
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req2, Projects::nest_list(for_project), L);
	if (LinkedLists::len(L) == 0) {
		copy_error *CE = CopyErrors::new(SYNTAX_CE, BogusExtension_SYNERROR);
		CopyErrors::supply_node(CE, current_sentence);
		Copies::attach_error(inclusions_errors_to, CE);
	} else {
		TEMPORARY_TEXT(versions)
		inbuild_search_result *search_result;
		LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
			if (Str::len(versions) > 0) WRITE_TO(versions, " or ");
			semantic_version_number V = search_result->copy->edition->version;
			if (VersionNumbers::is_null(V)) WRITE_TO(versions, "an unnumbered version");
			else WRITE_TO(versions, "version %v", &V);
		}
		copy_error *CE = CopyErrors::new_T(SYNTAX_CE, ExtVersionTooLow_SYNERROR, versions);
		CopyErrors::supply_node(CE, at);
		Copies::attach_error(inclusions_errors_to, CE);
		DISCARD_TEXT(versions)
	}

@ =
int last_PM_ExtVersionMalformed_at = -1;
semantic_version_number Inclusions::parse_version(int vwn) {
	semantic_version_number V = VersionNumbers::null();
	wording W = Wordings::one_word(vwn);
	if (<version-number>(W)) {
		semantic_version_number_holder *H = (semantic_version_number_holder *) <<rp>>;
		V = H->version;
	} else {
		@<Issue a problem message for a malformed version number@>;
	}
	return V;
}

@ Because we tend to call |Inclusions::parse_version| repeatedly on
the same word, we want to recover tidily from this problem, and not report it
over and over. We do this by altering the text to |1|, the lowest well-formed
version number text.

@<Issue a problem message for a malformed version number@> =
	if (last_PM_ExtVersionMalformed_at != vwn) {
		last_PM_ExtVersionMalformed_at = vwn;
		LOG("Offending word number %d <%N>\n", vwn, vwn);
		copy_error *CE = CopyErrors::new(SYNTAX_CE, ExtVersionMalformed_SYNERROR);
		CopyErrors::supply_node(CE, current_sentence);
		Copies::attach_error(inclusions_errors_to, CE);
	}

@h Checking the begins here and ends here sentences.
When a newly loaded extension is being sentence-broken, problem messages
will be turned up unless it contains the matching pair of "begins here"
and "ends here" sentences. Assuming it does, the sentence breaker has no
objection, but it also calls the two routines below to verify that these
sentences have the correct format. (The point of this is to catch a malformed
extension at the earliest possible moment after loading it: it's easy to
mis-install extensions, especially if doing so by hand, and the resulting
problem messages could be quite inscrutable if one extension was wrongly
identified as another.)

First, we check the "begins here" sentence. We also identify where the
version number is given (if it is), and check that we are not trying to
use an extension which is marked as not working on the current VM.

@ This parses the subject noun-phrase in the sentence

>> Version 3 of Pantomime Sausages by Mr Punch begins here.

=
<begins-here-sentence-subject> ::=
	<extension-title-and-version> by ... |
	...										==> @<Issue problem@>

@<Issue problem@> =
	copy_error *CE = CopyErrors::new(SYNTAX_CE, ExtNoBeginsHere_SYNERROR);
	CopyErrors::supply_node(CE, current_sentence);
	Copies::attach_error(inclusions_errors_to, CE);

@ =
void Inclusions::check_begins_here(parse_node *PN, inform_extension *E) {
	inbuild_copy *S = inclusions_errors_to;
	inclusions_errors_to = E->as_copy;
	<begins-here-sentence-subject>(Node::get_text(PN));
	inclusions_errors_to = S;
}

@ Similarly, we check the "ends here" sentence. Here there are no
side-effects: we merely verify that the name matches the one quoted in
the "begins here".

=
<the-prefix-for-extensions> ::=
	the ...

void Inclusions::check_ends_here(parse_node *PN, inform_extension *E) {
	inbuild_copy *S = inclusions_errors_to;
	inclusions_errors_to = E->as_copy;
	wording W = Node::get_text(PN);
	if (<the-prefix-for-extensions>(W)) W = GET_RW(<the-prefix-for-extensions>, 1);
	wording T = Feeds::feed_text(E->as_copy->edition->work->title);
	if (Wordings::match(T, W) == FALSE) {
		copy_error *CE = CopyErrors::new(SYNTAX_CE, ExtMisidentifiedEnds_SYNERROR);
		CopyErrors::supply_node(CE, PN);
		CopyErrors::supply_wording(CE, Node::get_text(PN));
		Copies::attach_error(inclusions_errors_to, CE);
	}
	inclusions_errors_to = S;
}
