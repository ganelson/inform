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

	extension_file *requested_extension =
		Extensions::Inclusion::load(AW, W, version_word, RW);

	if (requested_extension->body_text_unbroken) {
		Sentences::break(requested_extension->body_text, requested_extension);
		requested_extension->body_text_unbroken = FALSE;
	}

@h Extension loading.
Extensions are loaded here.

=
extension_file *Extensions::Inclusion::load(wording A, wording T,
	int version_word, wording VMW) {
	extension_file *ef;
	LOOP_OVER(ef, extension_file)
		if ((Wordings::match(ef->author_text, A)) && (Wordings::match(ef->title_text, T)))
			@<This is an extension already loaded, so note any version number hike and return@>;

	ef = Extensions::Files::new(A, T, VMW, version_word);
	if (problem_count == 0)
		@<Read the extension file into the lexer, and break it into body and documentation@>;
	return ef;
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

@<This is an extension already loaded, so note any version number hike and return@> =
	if (Extensions::Inclusion::parse_version(ef->min_version_needed) <
		Extensions::Inclusion::parse_version(version_word)) {
		ef->min_version_needed = version_word;
		ef->inclusion_sentence = current_sentence;
	}
	return ef;

@ We finally make our call out of the Extensions section, down through the
trap-door into Read Source Text, to seek and open the file.

@<Read the extension file into the lexer, and break it into body and documentation@> =
	TEMPORARY_TEXT(synopsis);
	@<Concoct a synopsis for the extension to be read@>;
	feed_t id = Feeds::begin();
	switch (SourceFiles::read_extension_source_text(ef, synopsis, census_mode)) {
		case ORIGIN_WAS_MATERIALS_EXTENSIONS_AREA:
		case ORIGIN_WAS_USER_EXTENSIONS_AREA:
			ef->loaded_from_built_in_area = FALSE; break;
		case ORIGIN_WAS_BUILT_IN_EXTENSIONS_AREA:
			ef->loaded_from_built_in_area = TRUE; break;
		default: /* which can happen if the extension file cannot be found */
			ef->loaded_from_built_in_area = FALSE; break;
	}
	wording EXW = Feeds::end(id);
	if (Wordings::nonempty(EXW)) @<Break the extension's text into body and documentation@>;
	DISCARD_TEXT(synopsis);

@ We concoct a textual synopsis in the form

	|"Pantomime Sausages by Mr Punch"|

to be used by |SourceFiles::read_extension_source_text| for printing to |stdout|. Since
we dare not assume |stdout| can manage characters outside the basic ASCII
range, we flatten them from general ISO to plain ASCII.

@<Concoct a synopsis for the extension to be read@> =
	WRITE_TO(synopsis, "%+W by %+W", T, A);
	LOOP_THROUGH_TEXT(pos, synopsis)
		Str::put(pos,
			Characters::make_filename_safe(Str::get(pos)));

@  If an extension file contains the special text (outside literal mode) of

	|---- Documentation ----|

then this is taken as the end of the Inform source, and the beginning of a
snippet of documentation about the extension; text from that point on is
saved until later, but not broken into sentences for the parse tree, and it
is therefore invisible to the rest of Inform. If this division line is not
present then the extension contains only body source and no documentation.

=
<extension-body> ::=
	*** ---- documentation ---- ... |	==> TRUE
	...									==> FALSE

@<Break the extension's text into body and documentation@> =
	<extension-body>(EXW);
	ef->body_text = GET_RW(<extension-body>, 1);
	if (<<r>>) ef->documentation_text = GET_RW(<extension-body>, 2);
	ef->body_text_unbroken = TRUE; /* mark this to be sentence-broken */

@h Parsing extension version numbers.
Extensions can have versions in the form N/DDDDDD, a format which was chosen
for sentimental reasons: IF enthusiasts know it well from the banner text of
the Infocom titles of the 1980s. This story file, for instance, was compiled
at the time of the Reykjavik summit between Presidents Gorbachev and Reagan:

	|Moonmist|
	|Infocom interactive fiction - a mystery story|
	|Copyright (c) 1986 by Infocom, Inc. All rights reserved.|
	|Moonmist is a trademark of Infocom, Inc.|
	|Release number 9 / Serial number 861022|

Story file collectors customarily abbreviate this in catalogues to |9/861022|.

In our scheme, DDDDDD can be omitted (in which case so must the slash be).
Spacing is not allowed around the slash (if present), so the version number
always occupies a single lexical word.

The following routine parses the version number at word |vwn| to give an
non-negative integer -- in fact it really just construes the whole thing,
with the slash removed, as a 7-digit number -- in such a way that an earlier
version always has a lower integer than a later one. It is legal for |vwn|
to be $-1$, which means "no version number quoted", and evaluates as
0 -- corresponding to |0/000000|, lower than the lowest version number it is
legal to quote explicitly, which is |1|. (It follows that requiring no
version in particular is equivalent to requiring |0/000000| or better, since
every extension passes that test.)

In order that the numerical form of a version number should be a signed
32-bit integer which does not overflow, we require that the release number
|N| be at most 999. It could in fact rise to 2146 without incident, but
it seems cleaner to constrain the number of digits than the value.

@d MAX_VERSION_NUMBER_LENGTH 10 /* for |999/991231| */

=
int Extensions::Inclusion::parse_version(int vwn) {
	int i, rv, slashes = 0, digits = 0, slash_at = 0;
	wchar_t *p, *q;
	if (vwn == -1) return 0; /* an unspecified version equates to |0/000000| */
	p = Lexer::word_text(vwn); q = p;
	for (i=0; p[i] != 0; i++)
		if (p[i] == '/') {
			slashes++; if ((i == 0) || (slashes > 1)) goto Malformed;
			slash_at = i; q = p+i+1;
		} else {
			if (!(Characters::isdigit(p[i]))) goto Malformed;
			digits++;
		}
	if ((p[0] == '0') || (digits == 0)) goto Malformed;

	if ((slashes == 0) && (digits <= 3)) /* so that |p| points to 1 to 3 digits, not starting with |0| */
		return Wide::atoi(p)*1000000;
	p[slash_at] = 0; /* temporarily replace the slash with a null, making |p| and |q| distinct C strings */
	if (Wide::len(p) > 3) goto Malformed; /* now |p| points to 1 to 3 digits, not starting with |0| */
	if (Wide::len(q) != 6) goto Malformed;
	while (*q == '0') q++; /* now |q| points to 0 to 6 digits, not starting with |0| */
	if (q[0] == 0) q--; /* if it was 0 digits, backspace to make it a single digit |0| */
	rv = (Wide::atoi(p)*1000000) + Wide::atoi(q);
	p[slash_at] = '/'; /* put the slash back over the null byte temporarily dividing the string */
	return rv;

	Malformed: @<Issue a problem message for a malformed version number@>;
}

@ Because we tend to call |Extensions::Inclusion::parse_version| repeatedly on the same word, we
want to recover tidily from this problem, and not report it over and over.
We do this by altering the text to |1|, the lowest well-formed version
number text.

@<Issue a problem message for a malformed version number@> =
	LOG("Offending word number %d <%N>\n", vwn, vwn);
	Problems::Issue::sentence_problem(_p_(PM_ExtVersionMalformed),
		"a version number must have the form N/DDDDDD",
		"as in the example '2/040426' for release 2 made on 26 April 2004. "
		"(The DDDDDD part is optional, so '3' is a legal version number too. "
		"N must be between 1 and 999: in particular, there is no version 0.)");
	Vocabulary::change_text_of_word(vwn, L"1");
	return 1000000; /* which equates to |1/000000| */

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
	...										==> @<Issue PM_ExtMiswordedBeginsHere problem@>

@<Issue PM_ExtMiswordedBeginsHere problem@> =
	<<auth1>> = -1; <<auth2>> = -1;
	Problems::Issue::handmade_problem(_p_(PM_ExtMiswordedBeginsHere));
	Problems::issue_problem_segment(
		"has a misworded 'begins here' sentence ('%2'), which contains "
		"no 'by'. Recall that every extension should begin with a "
		"sentence such as 'Quantum Mechanics by Max Planck begins "
		"here.', and end with a matching 'Quantum Mechanics ends "
		"here.', perhaps with documentation to follow.");
	Problems::issue_problem_end();

@ =
void Extensions::Inclusion::check_begins_here(parse_node *PN, extension_file *ef) {
	current_sentence = PN; /* in case problem messages need to be issued */
	Problems::quote_extension(1, ef);
	Problems::quote_wording(2, ParseTree::get_text(PN));

	<begins-here-sentence-subject>(ParseTree::get_text(PN));
	wording W = Wordings::new(<<t1>>, <<t2>>);
	wording AW = Wordings::new(<<auth1>>, <<auth2>>);
	if (Wordings::empty(AW)) return;
	ef->version_loaded = <<r>>;
	ef->VM_restriction_text = Wordings::new(<<rest1>>, <<rest2>>);

	if (ef->version_loaded >= 0) Extensions::Inclusion::parse_version(ef->version_loaded);

	if (Wordings::nonempty(ef->VM_restriction_text))
		@<Check that the extension's stipulation about the virtual machine can be met@>;

	if ((Wordings::match(ef->title_text, W) == FALSE) ||
		(Wordings::match(ef->author_text, AW) == FALSE))
		@<Issue a problem message pointing out that name and author do not agree with filename@>;
}

@ On the other hand, we do already know what virtual machine we are compiling
for, so we can immediately object if the loaded extension cannot be used
with our VM de jour.

@<Check that the extension's stipulation about the virtual machine can be met@> =
	if (<platform-qualifier>(ef->VM_restriction_text)) {
		if (<<r>> == PLATFORM_UNMET_HQ)
			@<Issue a problem message saying that the VM does not meet requirements@>;
	} else {
		@<Issue a problem message saying that the VM requirements are malformed@>;
	}

@ Suppose we wanted Onion Cookery by Delia Smith. We loaded the extension
file called Onion Cookery in the Delia Smith folder of the (probably external)
extensions area: but suppose that file turns out instead to be French Cuisine
by Elizabeth David, according to its "begins here" sentence? Then the
following problem message is produced:

@<Issue a problem message pointing out that name and author do not agree with filename@> =
	Problems::quote_extension(1, ef);
	Problems::quote_wording(2, ParseTree::get_text(PN));
	Problems::Issue::handmade_problem(_p_(PM_ExtMisidentified));
	Problems::issue_problem_segment(
		"The extension %1, which your source text makes use of, seems to be "
		"misidentified: its 'begins here' sentence declares it as '%2'. "
		"(Perhaps it was wrongly installed?)");
	Problems::issue_problem_end();
	return;

@ See Virtual Machines for the grammar of what can be given as a VM
requirement.

@<Issue a problem message saying that the VM requirements are malformed@> =
	Problems::quote_extension(1, ef);
	Problems::quote_wording(2, ef->VM_restriction_text);
	Problems::Issue::handmade_problem(_p_(PM_ExtMalformedVM));
	Problems::issue_problem_segment(
		"Your source text makes use of the extension %1: but my copy "
		"stipulates that it is '%2', which is a description of the required "
		"story file format which I can't understand, and should be "
		"something like '(for Z-machine version 5 or 8 only)'.");
	Problems::issue_problem_end();

@ Here the problem is not that the extension is broken in some way: it's
just not what we can currently use. Therefore the correction should be a
matter of removing the inclusion, not of altering the extension, so we
report this problem at the inclusion line.

@<Issue a problem message saying that the VM does not meet requirements@> =
	current_sentence = ef->inclusion_sentence;
	Problems::quote_source(1, current_sentence);
	Problems::quote_wording(2, ef->title_text);
	Problems::quote_wording(3, ef->author_text);
	Problems::quote_wording(4, ef->VM_restriction_text);
	Problems::Issue::handmade_problem(_p_(PM_ExtInadequateVM));
	Problems::issue_problem_segment(
		"You wrote %1: but my copy of %2 by %3 stipulates that it "
		"is '%4'. That means it can only be used with certain of "
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
void Extensions::Inclusion::check_ends_here(parse_node *PN, extension_file *ef) {
	wording W = Articles::remove_the(ParseTree::get_text(PN));
	if ((problem_count == 0) && (Wordings::match(ef->title_text, W) == FALSE)) {
		current_sentence = PN;
		Problems::quote_extension(1, ef);
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
