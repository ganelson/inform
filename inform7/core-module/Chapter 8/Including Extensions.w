[Extensions::Inclusion::] Including Extensions.

To fulfill requests to include extensions, adding their material
to the parse tree as needed, and removing INCLUDE nodes.

@ At this point in the narrative of a typical run of Inform, we have read in the
source text supplied by the user. The lexer automatically prefaced this with
"Include Standard Rules by Graham Nelson", and the sentence-breaker
converted all such sentences to nodes of type |INCLUDE_NT| which are
children of the parse tree root. (The eldest child, therefore, is the
Standard Rules inclusion.)

We now look through the parse tree in sentence order -- something we shall
do many times, and which we call a "traverse" -- and look for INCLUDE
nodes. Each is replaced with a mass of further nodes for the material in
whatever new extensions were required. This process is repeated until there
are no "Include" sentences left. In principle this could go on forever if
A includes B which includes A, or some such, but we log each extension read
in to ensure that nothing is read twice.

At the end of this routine, provided no Problems have been issued, there are
guaranteed to be no INCLUDE nodes remaining in the parse tree.

=
void Extensions::Inclusion::traverse(void) {
	int includes_cleared;
	do {
		includes_cleared = TRUE;
		if (problem_count > 0) return;
		parse_node *elder = NULL;
		ParseTree::traverse_ppni(Extensions::Inclusion::visit, &elder, &includes_cleared);
	} while (includes_cleared == FALSE);
}

void Extensions::Inclusion::visit(parse_node *pn, parse_node **elder, int *includes_cleared) {
	if (ParseTree::get_type(pn) == INCLUDE_NT) {
		@<Replace INCLUDE node with sentence nodes for any extensions required@>;
		*includes_cleared = FALSE;
	} else if (ParseTree::get_type(pn) != ROOT_NT) {
		*elder = pn;
	}
}

@ The INCLUDE node becomes an INCLUSION, which in turn contains the extension's code.

@<Replace INCLUDE node with sentence nodes for any extensions required@> =
	parse_node *title = pn->down, *author = pn->down->next;
	int l = ParseTree::begin_inclusion(pn);
	Extensions::Inclusion::fulfill_request_to_include_extension(title, author);
	ParseTree::end_inclusion(l);

@ Here we parse requests to include one or more extensions. People mostly
don't avail themselves of the opportunity, but it is legal to include
several at once, with a line like:

>> Include Carrots by Peter Rabbit and Green Lettuce by Flopsy Bunny.

A consequence of this convention is that "and" is not permitted in the
name of an extension. We might change this some day.

Here's how an individual title is described. The bracketed text is later
parsed by <platform-qualifier>.

=
<extension-title-and-version> ::=
	version <extension-version> of <definite-article> <extension-unversioned> |	==> R[1]
	version <extension-version> of <extension-unversioned> |					==> R[1]
	<definite-article> <extension-unversioned>	|								==> -1
	<extension-unversioned>														==> -1

<extension-unversioned> ::=
	<extension-unversioned-inner> ( ... )	|	==> 0; <<rest1>> = Wordings::first_wn(WR[1]); <<rest2>> = Wordings::last_wn(WR[1])
	<extension-unversioned-inner> 				==> 0; <<rest1>> = -1; <<rest2>> = -1

<extension-unversioned-inner> ::=
	<quoted-text> *** |							==> @<Issue PM_IncludeExtQuoted problem@>
	...											==> 0; <<t1>> = Wordings::first_wn(W); <<t2>> = Wordings::last_wn(W)

@ Quite a popular mistake, this:

@<Issue PM_IncludeExtQuoted problem@> =
	<<t1>> = -1; <<t2>> = -1;
	Problems::Issue::sentence_problem(_p_(PM_IncludeExtQuoted),
		"the name of an included extension should be given without double "
		"quotes in an Include sentence",
		"so for instance 'Include Oh My God by Janice Bing.' rather than "
		"'Include \"Oh My God\" by Janice Bing.')");

@ This internal parses version text such as "12/110410".

=
<extension-version> internal 1 {
	*X = Wordings::first_wn(W); /* actually, defer parsing by returning a word number here */
	return TRUE;
}

@ =
void Extensions::Inclusion::fulfill_request_to_include_extension(parse_node *p, parse_node *auth_p) {
	if (ParseTree::get_type(p) == AND_NT) {
		Extensions::Inclusion::fulfill_request_to_include_extension(p->down, auth_p);
		Extensions::Inclusion::fulfill_request_to_include_extension(p->down->next, auth_p);
		return;
	}

	<<rest1>> = -1; <<rest2>> = -1;
	<<t1>> = -1; <<t2>> = -1;
	<extension-title-and-version>(ParseTree::get_text(p));
	wording W = Wordings::new(<<t1>>, <<t2>>);
	wording AW = ParseTree::get_text(auth_p);
	wording RW = Wordings::new(<<rest1>>, <<rest2>>);
	int version_word = <<r>>;

	if (Wordings::nonempty(W)) @<Fulfill request to include a single extension@>;
}

@ A request consists of author, name and version, the latter being optional.
We obtain the extension file structure corresponding to this: it may have
no text at all (for instance if Inform could not open the file), or it may be
one we have seen before, thanks to an earlier inclusion. Only when it
provided genuinely new text will its |body_text_unbroken| flag be set,
and then we call the sentence-breaker to ParseTree::graft the new material on to the
parse tree.

@<Fulfill request to include a single extension@> =
	if (version_word >= 0)
		Extensions::Inclusion::parse_version(version_word); /* this checks the formatting of the version number */

	TEMPORARY_TEXT(exft);
	TEMPORARY_TEXT(exfa);
	WRITE_TO(exft, "%+W", W);
	WRITE_TO(exfa, "%+W", AW);
	inbuild_work *work = Works::new(extension_genre, exft, exfa);
	Works::add_to_database(work, LOADED_WDBC);
	semantic_version_number V = VersionNumbers::null();
	if (version_word >= 0) V = Extensions::Inclusion::parse_version(version_word);
	semver_range *R = NULL;
	if (VersionNumbers::is_null(V)) R = VersionNumbers::any_range();
	else R = VersionNumbers::compatibility_range(V);
	inbuild_requirement *req = Requirements::new(work, R);
	DISCARD_TEXT(exft);
	DISCARD_TEXT(exfa);

	parse_node *at = current_sentence;
	inform_extension *E = Extensions::Inclusion::load(req);
	if (E) {
		Extensions::set_inclusion_sentence(E, at);
		Extensions::set_VM_text(E, RW);
	}
//	if ((E) && (E->body_text_unbroken)) {
//		Sentences::break(E->body_text, E);
//		E->body_text_unbroken = FALSE;
//	}

@h Extension loading.
Extensions are loaded here.

=
inform_extension *Extensions::Inclusion::load(inbuild_requirement *req) {
	NaturalLanguages::scan(); /* to avoid wording from those interleaving with extension wording */
	@<Do not load the same extension work twice@>;

	inform_extension *E = NULL;
	@<Read the extension file into the lexer, and break it into body and documentation@>;
	return E;
}

@ Note that we ignore a request for an extension which has already been
loaded, except if the new request ups the ante in terms of the minimum
version permitted: in which case we need to record that the requirement has
been tightened. That is, if we previously wanted version 2 of Pantomime
Sausages by Mr Punch, and loaded it, but then read the sentence

>> Include version 3 of Pantomime Sausages by Mr Punch.

then we need to note that the version requirement on PS has been raised to 3.
(This is why version numbers are not checked at load time: in general, we
can't know at load time what we will ultimately require.)

@<Do not load the same extension work twice@> =
	inform_extension *E;
	LOOP_OVER(E, inform_extension)
		if (Requirements::meets(E->as_copy->edition, req)) {
			Extensions::must_satisfy(E, req);
			return E;
		}

@ We finally make our call out of the Extensions section, down through the
trap-door into Read Source Text, to seek and open the file.

@<Read the extension file into the lexer, and break it into body and documentation@> =
	int found_to_be_malformed = FALSE;
	req->allow_malformed = TRUE;
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req, Inbuild::nest_list(), L);
	inbuild_search_result *search_result;
	LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
		E = ExtensionManager::from_copy(search_result->copy);
		int origin = Nests::get_tag(search_result->nest);
		switch (origin) {
			case MATERIALS_NEST_TAG:
			case EXTERNAL_NEST_TAG:
				E->loaded_from_built_in_area = FALSE; break;
			case INTERNAL_NEST_TAG:
				E->loaded_from_built_in_area = TRUE; break;
		}
		if (LinkedLists::len(search_result->copy->errors_reading_source_text) > 0) {
			SourceFiles::issue_problems_arising(search_result->copy);
			E = NULL;
			found_to_be_malformed = TRUE;
		}
		break;
	}
	if (found_to_be_malformed == FALSE) {
		if (E == NULL) @<Issue a cannot-find problem@>
		else {
			SourceFiles::read(E->as_copy);
		}
	}

@<Issue a cannot-find problem@> =
	inbuild_requirement *req2 = Requirements::any_version_of(req->work);
	linked_list *L = NEW_LINKED_LIST(inbuild_search_result);
	Nests::search_for(req2, Inbuild::nest_list(), L);
	if (LinkedLists::len(L) == 0) {
		LOG("Author: %W\n", req->work->author_name);
		LOG("Title: %W\n", req->work->title);
		Problems::quote_source(1, current_sentence);
		Problems::Issue::handmade_problem(_p_(PM_BogusExtension));
		Problems::issue_problem_segment(
			"I can't find the extension requested by: %1. %P"
			"You can get hold of extensions which people have made public at "
			"the Inform website, www.inform7.com, or by using the Public "
			"Library in the Extensions panel.");
		Problems::issue_problem_end();
	} else {
		TEMPORARY_TEXT(versions);
		inbuild_search_result *search_result;
		LOOP_OVER_LINKED_LIST(search_result, inbuild_search_result, L) {
			if (Str::len(versions) > 0) WRITE_TO(versions, " or ");
			semantic_version_number V = search_result->copy->edition->version;
			if (VersionNumbers::is_null(V)) WRITE_TO(versions, "an unnumbered version");
			else WRITE_TO(versions, "version %v", &V);
		}
		Problems::quote_source(1, current_sentence);
		Problems::quote_stream(2, versions);
		Problems::Issue::handmade_problem(_p_(PM_ExtVersionTooLow));
		Problems::issue_problem_segment(
			"I can't find the right version of the extension requested by %1 - "
			"I can only find %2. %P"
			"You can get hold of extensions which people have made public at "
			"the Inform website, www.inform7.com, or by using the Public "
			"Library in the Extensions panel.");
		Problems::issue_problem_end();
		DISCARD_TEXT(versions);
	}

@ =
int last_PM_ExtVersionMalformed_at = -1;
semantic_version_number Extensions::Inclusion::parse_version(int vwn) {
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

@ Because we tend to call |Extensions::Inclusion::parse_version| repeatedly on
the same word, we want to recover tidily from this problem, and not report it
over and over. We do this by altering the text to |1|, the lowest well-formed
version number text.

@<Issue a problem message for a malformed version number@> =
	if (last_PM_ExtVersionMalformed_at != vwn) {
		last_PM_ExtVersionMalformed_at = vwn;
		LOG("Offending word number %d <%N>\n", vwn, vwn);
		Problems::Issue::sentence_problem(_p_(PM_ExtVersionMalformed),
			"a version number must have the form N/DDDDDD",
			"as in the example '2/040426' for release 2 made on 26 April 2004. "
			"(The DDDDDD part is optional, so '3' is a legal version number too. "
			"N must be between 1 and 999: in particular, there is no version 0.)");
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

It is sufficient to try parsing the version number in order to check it:
we throw away the answer, as we can't use it yet, but this will provoke
problem messages if it is malformed.

@ This parses the subject noun-phrase in the sentence

>> Version 3 of Pantomime Sausages by Mr Punch begins here.

=
<begins-here-sentence-subject> ::=
	<extension-title-and-version> by ... |	==> R[1]; <<auth1>> = Wordings::first_wn(WR[1]); <<auth2>> = Wordings::last_wn(WR[1]);
	...										==> @<Issue problem@>

@<Issue problem@> =
	<<auth1>> = -1; <<auth2>> = -1;
	Problems::Issue::handmade_problem(_p_(BelievedImpossible)); // since inbuild's scan catches this first
	Problems::issue_problem_segment(
		"has a misworded 'begins here' sentence ('%2'), which contains "
		"no 'by'. Recall that every extension should begin with a "
		"sentence such as 'Quantum Mechanics by Max Planck begins "
		"here.', and end with a matching 'Quantum Mechanics ends "
		"here.', perhaps with documentation to follow.");
	Problems::issue_problem_end();

@ =
void Extensions::Inclusion::check_begins_here(parse_node *PN, inform_extension *E) {
	current_sentence = PN; /* in case problem messages need to be issued */
	Problems::quote_extension(1, E);
	Problems::quote_wording(2, ParseTree::get_text(PN));

	<begins-here-sentence-subject>(ParseTree::get_text(PN));
	Extensions::set_VM_text(E, Wordings::new(<<rest1>>, <<rest2>>));

	@<Check that the extension's stipulation about the virtual machine can be met@>;
}

@ On the other hand, we do already know what virtual machine we are compiling
for, so we can immediately object if the loaded extension cannot be used
with our VM de jour.

@<Check that the extension's stipulation about the virtual machine can be met@> =
	compatibility_specification *C = E->as_copy->edition->compatibility;
	if (Compatibility::with(C, Task::vm()) == FALSE)
		@<Issue a problem message saying that the VM does not meet requirements@>;

@ Here the problem is not that the extension is broken in some way: it's
just not what we can currently use. Therefore the correction should be a
matter of removing the inclusion, not of altering the extension, so we
report this problem at the inclusion line.

@<Issue a problem message saying that the VM does not meet requirements@> =
	current_sentence = Extensions::get_inclusion_sentence(E);
	Problems::quote_source(1, current_sentence);
	Problems::quote_copy(2, E->as_copy);
	Problems::quote_stream(3, C->parsed_from);
	Problems::Issue::handmade_problem(_p_(PM_ExtInadequateVM));
	Problems::issue_problem_segment(
		"You wrote %1: but my copy of %2 stipulates that it "
		"is '%3'. That means it can only be used with certain of "
		"the possible compiled story file formats, and at the "
		"moment, we don't fit the requirements. (You can change "
		"the format used for this project on the Settings panel.)");
	Problems::issue_problem_end();

@ Similarly, we check the "ends here" sentence. Here there are no
side-effects: we merely verify that the name matches the one quoted in
the "begins here". We only check this if the problem count is still 0,
since we don't want to keep on nagging somebody who has already been told
that the extension isn't the one he thinks it is.

=
void Extensions::Inclusion::check_ends_here(parse_node *PN, inform_extension *E) {
	wording W = Articles::remove_the(ParseTree::get_text(PN));
	wording T = Feeds::feed_stream(E->as_copy->edition->work->title);
	if ((problem_count == 0) && (Wordings::match(T, W) == FALSE)) {
		current_sentence = PN;
		Problems::quote_extension(1, E);
		Problems::quote_wording(2, ParseTree::get_text(PN));
		Problems::Issue::handmade_problem(_p_(PM_ExtMisidentifiedEnds));
		Problems::issue_problem_segment(
			"The extension %1, which your source text makes use of, seems to be "
			"malformed: its 'begins here' sentence correctly identifies it, but "
			"then the 'ends here' sentence calls it '%2' instead. (They need "
			"to be a matching pair except that the end does not name the "
			"author: for instance, 'Hocus Pocus by Jan Ackerman begins here.' "
			"would match with 'Hocus Pocus ends here.')");
		Problems::issue_problem_end();
		return;
	}
}

@h Sentence handlers for begins here and ends here.
The main traverses of the assertions are handled by code which calls
"sentence handler" routines on each node in turn, depending on type.
Here are the handlers for BEGINHERE and ENDHERE. As can be seen, all
we really do is start again from a clean piece of paper.

Note that, because one extension can include another, these nodes may
well be interleaved: we might find the sequence A begins, B begins,
B ends, A ends. The careful checking done so far ensures that these
will always properly nest. We don't at present make use of this, but
we might in future.

=
sentence_handler BEGINHERE_SH_handler =
	{ BEGINHERE_NT, -1, 0, Extensions::Inclusion::handle_extension_begins };
sentence_handler ENDHERE_SH_handler =
	{ ENDHERE_NT, -1, 0, Extensions::Inclusion::handle_extension_ends };

void Extensions::Inclusion::handle_extension_begins(parse_node *PN) {
	Assertions::Traverse::new_discussion(); near_start_of_extension = 1;
}

void Extensions::Inclusion::handle_extension_ends(parse_node *PN) {
	near_start_of_extension = 0;
}
