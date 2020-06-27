[ExtensionDictionary::] Dictionary.

To maintain a database of names and constructions in all extensions
so far used by this installation of Inform, and spot potential namespace
clashes.

@h The dictionary file.
Each time an extension is successfully used, a dictionary of items defined in
the user's extensions is updated: this is used to generate the dynamic
documentation on installed extensions, and is stored between runs in a cache
file inside the Inform GUI applications. The dictionary is a UTF-8 encoded
text file, kept in the user's transient storage area. (It's no enormous
loss if this should be mislaid.)

=
filename *ExtensionDictionary::filename(void) {
	pathname *P = Supervisor::transient();
	if (P == NULL) return NULL;
	P = Pathnames::down(P, I"Documentation");
	P = Pathnames::down(P, I"Census");
	return Filenames::in(P, I"Dictionary.txt");
}

@ In December 2007, the dictionary file of a user who had employed 155 different
extensions (by 33 different authors) contained 2223 entries, the longest of
which formed a line 95 characters long: the most prolific extension made 380
definitions. The total file size was about 130K.

Typical dictionary file contents look like this. The four columns are author,
title, headword and category.
= (text)
...
|Emily Short|Plurality|20110130181823:Sun 30 January 2011 18:18|indexing|
|Emily Short|Plurality|prior named noun|value|
|Emily Short|Plurality|ambiguously plural|property|
|Emily Short|Plurality|ordinarily enumerated|property|
|Emily Short|Locksmith|20110130181823:Sun 30 January 2011 18:18|indexing|
|Emily Short|Locksmith|passkey|kind|
|Emily Short|Locksmith|keychain|kind|
...
=
It is not necessarily stored in a sorted form, and no ordering of lines is
guaranteed.

The special entries with category "indexing" have two roles: they are
markers that the extension in question is indexed in the dictionary, and
they record the last date on which the extension was used.

Note that the stroke character is illegal in unquoted Inform source text,
and therefore also in excerpts with meanings, in extension titles and in
author names. It can therefore safely be used as a field divider.

@h Storage in memory.
Each record (i.e., line in the above file) is stored in memory thus. A
record marked "to be erased" will not be saved back to the file in due course.

=
typedef struct extension_dictionary_entry {
	struct inform_extension *ede_extension;
	struct inbuild_work *ede_work; /* author name and title, with hash code */
	struct text_stream *entry_text; /* text of the dictionary entry */
	struct text_stream *type; /* grammatical category, such as "kind" */
	int erased; /* marked to be erased */
	struct extension_dictionary_entry *next_in_sorted_dictionary; /* temporary use only */
	struct text_stream *sorting; /* temporary use only */
	CLASS_DEFINITION
} extension_dictionary_entry;

@ =
void ExtensionDictionary::new_ede(inform_extension *E, text_stream *category,
	text_stream *author, text_stream *title, text_stream *headword) {
	if (E == NULL) internal_error("no E for EDE");
	extension_dictionary_entry *ede = CREATE(extension_dictionary_entry);
	ede->ede_extension = E;
	ede->ede_work = E->as_copy->edition->work;
	ede->entry_text = Str::duplicate(headword);
	ede->type = Str::duplicate(category);
	ede->sorting = Str::new();
	if (Str::eq_wide_string(category, L"indexing"))
		@<Change the sort and usage dates, and word count, for the extension work@>
	else E->has_historically_been_used = TRUE;
	ede->erased = FALSE;
	ede->next_in_sorted_dictionary = NULL;
	LOGIF(EXTENSIONS_CENSUS, "Created $d", ede);
}

@ Data on, for example, when an extension was last used is cached in |indexing|
records in the dictionary file. When we generate such an EDE, we must have
new information on those, so we update the //inbuild_work// object representing
the extension:

@<Change the sort and usage dates, and word count, for the extension work@> =
	TEMPORARY_TEXT(sdate)
	TEMPORARY_TEXT(udate)
	int mode = 0, wc = 0;
	LOOP_THROUGH_TEXT(pos, ede->entry_text) {
		if (Str::get(pos) == '/') { mode = 1; continue; }
		if (Str::get(pos) == ':') { mode = 2; continue; }
		int digital = Characters::isdigit(Str::get(pos));
		switch (mode) {
			case 0: if (digital) PUT_TO(sdate, Str::get(pos));
				break;
			case 1: if (digital) wc = 10*wc + ((int) Str::get(pos)) - ((int) '0');
				break;
			case 2: PUT_TO(udate, Str::get(pos));
				break;
		}
	}
	if (Str::len(sdate) > 0) Extensions::set_sort_date(ede->ede_extension, sdate);
	if (wc > 0) Extensions::set_word_count(ede->ede_extension, wc);
	if (Str::len(udate) > 0) Extensions::set_usage_date(ede->ede_extension, udate);
	DISCARD_TEXT(sdate)
	DISCARD_TEXT(udate)

@ This is where the |indexing| records are made; they time-stamp the extension
with its time of last usage, and the word count. (|the_present| is a global
variable created by //foundation//.)

=
void ExtensionDictionary::time_stamp(inform_extension *E) {
	TEMPORARY_TEXT(dbuff)
	char *ascday[] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" };
	char *ascmon[] = { "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December" };
	WRITE_TO(dbuff, "%04d%02d%02d%02d%02d%02d/%d:%s %d %s %d %02d:%02d",
		the_present->tm_year+1900, the_present->tm_mon + 1, the_present->tm_mday,
		the_present->tm_hour, the_present->tm_min, the_present->tm_sec,
		(E->read_into_file)?(TextFromFiles::total_word_count(E->read_into_file)):0,
		ascday[the_present->tm_wday], the_present->tm_mday,
		ascmon[the_present->tm_mon], the_present->tm_year+1900,
		the_present->tm_hour, the_present->tm_min);
	ExtensionDictionary::new_ede(E, I"indexing",
		E->as_copy->edition->work->author_name, E->as_copy->edition->work->title, dbuff);
	DISCARD_TEXT(dbuff)
}

@ We provide two more convenient creator functions: from a wording or from text.

=
void ExtensionDictionary::new_entry_from_wording(text_stream *category,
	inform_extension *E, wording W) {
	if (Wordings::nonempty(W)) { /* a safety precaution: never index the empty text */
		TEMPORARY_TEXT(headword)
		WRITE_TO(headword, "%+W", W);
		ExtensionDictionary::new_entry(category, E, headword);
		DISCARD_TEXT(headword)
	}
}

void ExtensionDictionary::new_entry(text_stream *category,
	inform_extension *E, text_stream *headword) {
	ExtensionDictionary::new_ede(E, category,
		E->as_copy->edition->work->author_name,
		E->as_copy->edition->work->title, headword);
}

@ The following logs the dictionary, and looks roughly like the file records,
but note that it lists the erasure flag too:

=
void ExtensionDictionary::log_entry(extension_dictionary_entry *ede) {
	LOG("ede: %05d %d |%S|%S|%S|%S|\n", ede->allocation_id,
		ede->erased, ede->ede_work->author_name, ede->ede_work->title,
		ede->entry_text, ede->type);
}

@h Reading in.
Not a surprising function: open, convert one line at a time to an
//extension_dictionary_entry// object, close.

=
void ExtensionDictionary::read_from_file(void) {
	filename *F = ExtensionDictionary::filename();
	if (F == NULL) return;
	
	@<Ensure the serialised extensions dictionary file exists@>;

	LOGIF(EXTENSIONS_CENSUS, "Reading dictionary file %f\n", F);
	TextFiles::read(F, FALSE,
		NULL, FALSE, ExtensionDictionary::load_helper, NULL, NULL);
	LOGIF(EXTENSIONS_CENSUS, "Finished reading dictionary file\n");
}

@ The extension dictionary file is stored only transiently and may never have
been made, or may have been wiped by a zealous mobile OS. If it doesn't exist,
we try to make an empty one. Should these attempts fail, we simply return:
there might be permissions reasons, and it doesn't matter too much.

@<Ensure the serialised extensions dictionary file exists@> =
	FILE *DICTF = Filenames::fopen(F, "r");
	if (DICTF == NULL) {
		LOGIF(EXTENSIONS_CENSUS, "Creating new empty dictionary file\n");
		FILE *EMPTY_DICTF = Filenames::fopen(F, "w");
		if (EMPTY_DICTF == NULL) return;
		fclose(EMPTY_DICTF);
	}

@ We parse lines in a fairly forgiving way. Material before the initial stroke
is ignored; material after the final stroke is also ignored, and any line not
containing five vertical strokes (i.e., four stroke-divided fields) is ignored
altogether. We're being forgiving in case the user has picked up Inform again
after ten years away, and still has an old dictionary file from the bad old
days when overlong records were truncated.

=
void ExtensionDictionary::load_helper(text_stream *line_entry,
	text_file_position *tfp, void *state) {
	TEMPORARY_TEXT(author)
	TEMPORARY_TEXT(title)
	TEMPORARY_TEXT(headword)
	TEMPORARY_TEXT(category)
	TEMPORARY_TEXT(at)
	int strokes, pos;
	for (strokes = 0, pos = 0; strokes <= 5; pos++) {
		wchar_t c = Str::get_at(line_entry, pos);
		if (c == 0) break;
		if (c == '|') {
			if (strokes < 5) strokes++;
		} else {
			switch(strokes) {
				case 1: PUT_TO(author, c); break;
				case 2: PUT_TO(title, c); break;
				case 3: PUT_TO(headword, c); break;
				case 4: PUT_TO(category, c); break;
				case 5: PUT_TO(at, c); break;
			}
		}
	}
	DISCARD_TEXT(author)
	DISCARD_TEXT(title)
	DISCARD_TEXT(headword)
	DISCARD_TEXT(category)
	DISCARD_TEXT(at)
	if (Str::len(at) == 0) {
		inbuild_requirement *req =
			Requirements::any_version_of(Works::new(extension_genre, title, author));
		inbuild_search_result *R =
			Nests::search_for_best(req, Supervisor::shared_nest_list());
		if (R) ExtensionDictionary::new_ede(ExtensionManager::from_copy(R->copy),
			category, author, title, headword);
	} else {
		filename *F = Filenames::from_text(at);
		inbuild_copy *C = ExtensionManager::claim_file_as_copy(F);
		if (C) ExtensionDictionary::new_ede(ExtensionManager::from_copy(C),
			category, author, title, headword);
		else PRINT("Hapless! on %S\n", line_entry);
	}
}

@h Writing out.
And inversely... Note that erased records are not written.

=
void ExtensionDictionary::write_back(void) {
	text_stream DICTF_struct;
	text_stream *DICTF = &DICTF_struct;
	filename *F = ExtensionDictionary::filename();
	if (F == NULL) return;
	if (STREAM_OPEN_TO_FILE(DICTF, F, UTF8_ENC) == FALSE) return;
	@<Write into DICTF@>;
	STREAM_CLOSE(DICTF);
}

@<Write into DICTF@> =
	LOGIF(EXTENSIONS_CENSUS, "Writing dictionary file\n");
	extension_dictionary_entry *ede;
	LOOP_OVER(ede, extension_dictionary_entry)
		if (ede->erased == FALSE) {
			LOGIF(EXTENSIONS_CENSUS, "Writing $d", ede);
			WRITE_TO(DICTF, "|%S|%S|%S|%S|%f\n",
				ede->ede_work->author_name, ede->ede_work->title,
				ede->entry_text, ede->type, ede->ede_extension->as_copy->location_if_file);
		} else LOGIF(EXTENSIONS_CENSUS, "Suppressing $d\n", ede);
	LOGIF(EXTENSIONS_CENSUS, "Finished writing dictionary file\n");

@h Erasing entries.
As noted above, any entry marked |erased| is not written back to the
dictionary file, and effectively that takes it out of the dictionary for
subsequent runs of Inform.

This arises when we are making the dictionary entries for an extension which
was used on the current run. Before making new entries, we erase all entries
left over from some previous usage of it: it may, after all, have changed.

=
void ExtensionDictionary::erase_entries_concerning(inform_extension *E) {
	extension_dictionary_entry *ede;
	LOGIF(EXTENSIONS_CENSUS, "Erasure of dictionary entries for %X\n",
		E->as_copy->edition->work);
	LOOP_OVER(ede, extension_dictionary_entry)
		if ((ede->erased == FALSE) &&
			(Works::match(ede->ede_work, E->as_copy->edition->work))) {
			ede->erased = TRUE;
			LOGIF(EXTENSIONS_CENSUS, "Erased $d", ede);
		}
	LOGIF(EXTENSIONS_CENSUS, "Done\n");
}

@h Sorting the extension dictionary.
This function returns the number of (unerased) entries in the dictionary,
and on its exit the (unerased) entries each occur once in alphabetical
order in the linked list beginning at |first_in_sorted_dictionary|.
If two entries have identical headwords, the earliest created is the
one which appears earlier in the sorted dictionary.

We pass this job on to the standard C library |qsort|, in hopes that it is
reasonably efficiently implemented: we certainly don't want to use an
algorithm likely to have $O(n^2)$ running time, given that $n$ is plausibly
as high as 10,000.

=
extension_dictionary_entry *first_in_sorted_dictionary = NULL;

int ExtensionDictionary::sort_extension_dictionary(void) {
	LOGIF(EXTENSIONS_CENSUS, "Beginning dictionary sort\n");
	int no_entries = 0;
	first_in_sorted_dictionary = NULL;
	@<Count headwords and reprocess their texts for dictionary sorting@>;
	if (no_entries == 0) return 0;

	extension_dictionary_entry **sorted_extension_dictionary =
		Memory::calloc(no_entries,
			sizeof(extension_dictionary_entry *), EXTENSION_DICTIONARY_MREASON);
	@<Fill the array with pointers to the EDEs@>;
	qsort(sorted_extension_dictionary, (size_t) no_entries,
		sizeof(extension_dictionary_entry *),
		ExtensionDictionary::compare_ed_entries);
	@<String the sorted array together into a sorted linked list of EDEs@>;
	Memory::I7_array_free(sorted_extension_dictionary, EXTENSION_DICTIONARY_MREASON,
		no_entries, sizeof(extension_dictionary_entry *));

	LOGIF(EXTENSIONS_CENSUS, "Sorted dictionary: %d entries\n", no_entries);
	return no_entries;
}

@ Dictionary entries must be in mixed case: we might have both "green" the
colour and "Green" the kind of person (an environmental activist), say.
But we want to compare them with |strcmp|, which is much faster than its
case-insensitive analogue. So we trade memory for speed and store a modified
form of the headword in which spaces are removed and letters are reduced
to lower case; note that this is no larger than the original, so there is
no risk of the |sorting| string (which is 10 characters longer than the
unprocessed version) overflowing. Note: later we shall rely on the first
character of the sorting text being the lower-case form of the first
character of the original word.

We then append the allocation ID number, padded with initial zeros. We do
this so that (i) all sorting texts will be distinct, and (ii) alphabetical
order for sorting texts derived from two identical headword texts will
correspond to creation order. This ensures that |qsort|'s output will be
predictable -- implementations of Quicksort do not otherwise guarantee this,
since implementations have the freedom to sort unstably in different ways.

@<Count headwords and reprocess their texts for dictionary sorting@> =
	extension_dictionary_entry *ede;
	LOOP_OVER(ede, extension_dictionary_entry)
		if (ede->erased == FALSE) {
			no_entries++;
			Str::clear(ede->sorting);
			LOOP_THROUGH_TEXT(pos, ede->entry_text)
				if (Str::get(pos) != ' ')
					PUT_TO(ede->sorting,
						Characters::tolower(Str::get(pos)));
			WRITE_TO(ede->sorting, "-%09d", ede->allocation_id);
			LOGIF(EXTENSIONS_CENSUS, "Sorted under '%S': $d", ede->sorting, ede);
		}

@ We unbundle the linked list of EDEs in creation order:

@<Fill the array with pointers to the EDEs@> =
	int i = 0;
	extension_dictionary_entry *ede;
	LOOP_OVER(ede, extension_dictionary_entry)
		if (ede->erased == FALSE)
			sorted_extension_dictionary[i++] = ede;

@ We then use the sorted version of the same array to reorder the EDEs:

@<String the sorted array together into a sorted linked list of EDEs@> =
	first_in_sorted_dictionary = sorted_extension_dictionary[0];
	for (int i=0; i<no_entries-1; i++)
		sorted_extension_dictionary[i]->next_in_sorted_dictionary =
			sorted_extension_dictionary[i+1];
	if (no_entries > 0)
		sorted_extension_dictionary[no_entries-1]->next_in_sorted_dictionary = NULL;

@ As always with |qsort|, there's a palaver about the types used for the
comparison function so that the result will compile without errors:

=
int ExtensionDictionary::compare_ed_entries(const void *elem1, const void *elem2) {
	const extension_dictionary_entry **e1 = (const extension_dictionary_entry **) elem1;
	const extension_dictionary_entry **e2 = (const extension_dictionary_entry **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting extension dictionary");
	return Str::cmp((*e1)->sorting, (*e2)->sorting);
}

@h Writing the HTML extension index.
This is the index of terms, not the directory of extensions: it is, in
fact, the HTML rendering of the dictionary constructed above.

=
void ExtensionDictionary::write_to_HTML(OUTPUT_STREAM) {
	int n = ExtensionDictionary::sort_extension_dictionary();
	if (n > 0) {
		int first_letter = 'a';
		for (extension_dictionary_entry *previous_ede = NULL,
			*ede = first_in_sorted_dictionary; ede;
			previous_ede = ede, ede = ede->next_in_sorted_dictionary) {
			if (Str::eq_wide_string(ede->type, L"indexing")) continue;
			extension_dictionary_entry *next_ede = ede->next_in_sorted_dictionary;
			int this_first = Characters::tolower(Str::get_first_char(ede->entry_text));
			if (first_letter != this_first) {
				HTML_TAG("br"); first_letter = this_first;
			}
			@<Write extension dictionary entry for this headword@>;
		}
		ExtensionDictionary::list_known_extension_clashes(OUT);
	}
}

@ A run of $N$ words which are all the same should appear in tinted type
throughout, while $N(N-1)/2$ clashes should be reported to the machinery for
clashes given above: if we find definitions A, B, C, for instance, the clashes
are reported as A vs B, A vs C, then B vs C. This has $O(N^2)$ running time,
so if there are 1000 extensions, each of which gives 1000 different meanings
to the word "frog", we would be in some trouble here. Let's take the risk.

@d EDES_DEFINE_SAME_WORD(X, Y) ((X) && (Y) && (Str::eq(X->sorting, Y->sorting)))

@<Write extension dictionary entry for this headword@> =
	int tint = FALSE;
	if (EDES_DEFINE_SAME_WORD(ede, previous_ede)) tint = TRUE;
	while (EDES_DEFINE_SAME_WORD(ede, next_ede)) {
		tint = TRUE;
		ExtensionDictionary::extension_clash(ede, next_ede);
		next_ede = next_ede->next_in_sorted_dictionary;
	}
	HTML_OPEN_WITH("p", "style='margin:0px; padding:0px;'");
	if (tint) HTML::begin_colour(OUT, I"FF8080");
	WRITE("%S", ede->entry_text);
	if (tint) HTML::end_colour(OUT);
	WRITE(" - <i>%S</i>&nbsp;&nbsp;&nbsp;", ede->type);
	HTML_OPEN_WITH("span", "class=\"smaller\"");
	Works::write_link_to_HTML_file(OUT, ede->ede_work);
	HTML_CLOSE("span");
	HTML_CLOSE("p");

@ So, then, "clashes". These occur if, say, two extensions define "chopper" as
a kind of vehicle (for instance, meaning a helicopter in one and a motorcycle
in the other). This results in two dictionary entries under "chopper" and is
recorded as a clash between them. Often, more will turn up: perhaps "chopper"
might elsewhere mean a butchery tool. In the event of 3 or more clashing
entries, $A, B, C, ...$, a linked list of ordered pairs $(A,B), (A,C), ...$ is
maintained where in each pair the first term (the left one) is from an
extension lexicographically earlier than the second (the right one).

=
typedef struct known_extension_clash {
	int first_known; /* heads a linked list of clashes with a given |ede1| */
	struct known_extension_clash *next; /* next in linked list of clashes */
	struct extension_dictionary_entry *leftx; /* clash is between this entry... */
	struct extension_dictionary_entry *rightx; /* ...and this one */
	int number_clashes; /* number of entries clashing between |ede1| and |ede2| */
	CLASS_DEFINITION
} known_extension_clash;

@ =
known_extension_clash *ExtensionDictionary::new_clash(extension_dictionary_entry *L,
	extension_dictionary_entry *R, int first_known_flag) {
	known_extension_clash *kec = CREATE(known_extension_clash);
	kec->leftx = L;
	kec->rightx = R;
	kec->number_clashes = 1;
	kec->first_known = first_known_flag;
	kec->next = NULL;
	return kec;
}

@ Every clash of names arises from definitions made in a pair of EDEs,
which we shall call left and right. Each distinct KEC ("known extension
clash") represents a different pair of extensions which clash, one
example of a name clashing between them, and a count of the number of
such names.

(a) Given a pair of extensions, the left one is the one whose author name
followed by title is lexicographically earlier. Since we are only concerned
with clashes between different extensions, this unambiguously decides which
is leftmost, as title and author suffice to identify extensions.

(b) Similarly, given a pair of EDEs, the left one is the one whose definition
arises from the lefthand extension. (So, for instance, any definition made
in one of Eric Eve's extensions is always to the left of any definition in
one of John Clemens's.) Different EDEs deriving from the same extension do
not exemplify a clash.

(c) For each extension L, there is at most one KEC whose left EDE derives
from L and which has the "first known" flag set.
If such a KEC does not exist, then L does not clash with any other
extension.
If such a KEC does exist, then it is the head of a linked list of
KECs all of which have lefthand EDE deriving from L, and in which no two
entries have righthand EDEs deriving from the same extension as each other.

It follows that we can determine if extensions X and Y clash by arranging
them as L and R (rule (a)), looking for L among the left EDEs of all KECs
with the "first known" flag set (rule (c)), and then looking for Y among
the right EDEs of all KECs in the list which hangs from that (rule (c.2)).
Should either of these searches fail, there is no clash between X and Y.
Should both succeed, then the KEC found provides a single example of the
clash (in its left and right EDEs), together with the number of clashes.

If there are $n$ extensions then there could in theory be $n(n-1)/2$ KECs,
which might amount to a lot of storage. In practice, though, Inform source
text tends to be dispersed around the cloud of English nouns and adjectives
fairly well, and since extension authors use each other's extensions, there
is also some social pressure to reduce the number of clashes. The user
mentioned above who had installed 155 different extensions -- for a possible
11,935 distinct clashing pairs -- in fact observed 15 such pairs, mostly arising
from part-finished drafts which had borrowed source text from pieces of other
extensions. Of the few remaining, several were cases where the same name
occurred in rival extensions aspiring to do much the same thing as each
other: for instance, "current quip" was defined by two different conversation
extensions. The only clashes of different meanings which might both be needed,
and which seem to have arisen spontaneously, were from definitions of the
words "seen" and "implicit", both treacherously ambiguous. Clashes did
not seem to have arisen from homonyms like "lead" (the substance) versus
"lead" (the cable to a pair of headphones).

=
void ExtensionDictionary::extension_clash(extension_dictionary_entry *ede1,
	extension_dictionary_entry *ede2) {
	extension_dictionary_entry *left = NULL, *right = NULL;
	inbuild_work *leftx, *rightx;
	known_extension_clash *kec;
	if ((ede1 == NULL) || (ede2 == NULL)) internal_error("bad extension clash");

	int d = Works::compare(ede1->ede_work, ede2->ede_work); /* compare source extensions */

	@<Ignore apparent clashes which are in fact not troublesome@>;

	if (d < 0) { left = ede1; right = ede2; }
	if (d > 0) { left = ede2; right = ede1; }
	leftx = left->ede_work; rightx = right->ede_work;

	LOOP_OVER(kec, known_extension_clash)
		if ((kec->first_known) && (Works::match(leftx, kec->leftx->ede_work))) {
			@<Search list of KECs deriving from the same left extension as this clash@>;
			return;
		}

	kec = ExtensionDictionary::new_clash(left, right, TRUE);
}

@ If two name clashes occur in the same extension then, since we can presume
that this extension does actually work, the clash cannot cause problems.
We also ignore a clash of a property name against some other form of name,
because these occur quite often and cause little difficulty in practice: so
they would only clutter up the dictionary with spurious warnings.

@<Ignore apparent clashes which are in fact not troublesome@> =
	if (d == 0) return; /* both definitions come from the same extension */
	if ((Str::eq_wide_string(ede1->type, L"property")) &&
		(Str::eq_wide_string(ede2->type, L"property") == FALSE)) return;
	if ((Str::eq_wide_string(ede1->type, L"property") == FALSE) &&
		(Str::eq_wide_string(ede2->type, L"property"))) return;

@ If we can find the righthand extension on the righthand side of any KEC
in the list, then the clash is not a new one: we simply increment the number
of definition pairs clashing between the left and right extensions, and
return. (Thus forgetting what the actual definitions causing the present
clash were: we don't need them, as we already have an example of the
definitions clashing between the two.) But if we can't find righthand
extension anywhere in the list, we must add the new pair of definitions:

@<Search list of KECs deriving from the same left extension as this clash@> =
	while (kec) {
		if (Works::match(rightx, kec->rightx->ede_work)) {
			kec->number_clashes++; return;
		}
		if (kec->next == NULL) {
			kec->next = ExtensionDictionary::new_clash(left, right, FALSE);
			return;
		}
		kec = kec->next;
	}

@ The above arrangement was designed to make it easy to print out the
clashes in a concise, human-readable way, which is what we now do.

=
void ExtensionDictionary::list_known_extension_clashes(OUTPUT_STREAM) {
	known_extension_clash *kec;
	if (NUMBER_CREATED(known_extension_clash) == 0) return;
	@<Write the headnote about what extension clashes mean@>;
	LOOP_OVER(kec, known_extension_clash)
		if (kec->first_known)
			@<Write a paragraph about extensions clashing with the lefthand one here@>;
}

@ Not the end of the world! Extension clashes are not an error condition: they
are, if anything, a sign of life and activity.

@<Write the headnote about what extension clashes mean@> =
	HTML_OPEN("p");
	WRITE("<b>Clashes found.</b> The dictionary above shows that some "
		"extensions make incompatible definitions of the same words or phrases. "
		"When two extensions disagree like this, it is not necessarily a bad "
		"sign (they might simply be two ways to approach the same problem), "
		"but in general it means that it may not be safe to use both "
		"extensions at the same time. The following list shows some potential "
		"clashes.");
	HTML_CLOSE("p");

@<Write a paragraph about extensions clashing with the lefthand one here@> =
	known_extension_clash *example;
	HTML_OPEN("b");
	Works::write_to_HTML_file(OUT, kec->leftx->ede_work, FALSE);
	HTML_CLOSE("b");
	WRITE(": ");
	for (example = kec; example; example = example->next) {
		WRITE("clash with ");
		HTML_OPEN("b");
		Works::write_to_HTML_file(OUT, example->rightx->ede_work, FALSE);
		HTML_CLOSE("b");
		WRITE(" (on ");
		if (example->number_clashes > 1)
			WRITE("%d names, for instance ", example->number_clashes);
		WRITE("%S)", example->leftx->entry_text);
		if (example->next) WRITE("; ");
	}
	HTML_OPEN("p");
	WRITE("\n");
