[Extensions::Dictionary::] Extension Dictionary.

To maintain a database of names and constructions in all extensions
so far used by this installation of Inform, and spot potential namespace
clashes.

@h Definitions.

@ Not during the census, but rather when extensions are successfully
used, a dictionary is kept of the terms defined in them: this is used
to generate the dynamic documentation on installed extensions, and
is stored between runs in a cache file inside the I7 application.
This means dictionary entries are first read in from the cache; then
the entries for any extension used by Inform in its current run are
revised, which may mean deleting some entries or adding new ones;
and at last Inform writes the final state of the dictionary back to the
cache. In this way, changes in what an extension defines are reflected
in the dictionary after each successful use of that extension.

=
typedef struct extension_dictionary_entry {
	struct inbuild_work *ede_work; /* author name and title, with hash code */
	struct text_stream *entry_text; /* text of the dictionary entry */
	struct text_stream *sorting; /* text reprocessed for sorting purposes */
	struct text_stream *type; /* grammatical category, such as "kind" */
	int erased; /* marked to be erased */
	struct extension_dictionary_entry *next_in_sorted_dictionary; /* link in linked list */
	MEMORY_MANAGEMENT
} extension_dictionary_entry;

extension_dictionary_entry *first_in_sorted_dictionary = NULL;

@ Clashes occur if, say, two extensions define "chopper" as a kind
of vehicle (for instance, meaning a helicopter in one and a motorcycle
in the other). This results in two dictionary entries under "chopper"
and is recorded as a clash between them. Often, more will turn up:
perhaps "chopper" might elsewhere mean a butchery tool. In the
event of 3 or more clashing entries, $A, B, C, ...$, a linked list of
ordered pairs $(A,B), (A,C), ...$ is maintained where in each pair the
first term (the left one) is from an extension lexicographically earlier
than the second (the right one): see below.

=
typedef struct known_extension_clash {
	int first_known; /* heads a linked list of clashes with a given |ede1| */
	struct known_extension_clash *next; /* next in linked list of clashes */
	struct extension_dictionary_entry *leftx; /* clash is between this entry... */
	struct extension_dictionary_entry *rightx; /* ...and this one */
	int number_clashes; /* number of entries clashing between |ede1| and |ede2| */
	MEMORY_MANAGEMENT
} known_extension_clash;

@ The extension dictionary has no natural order as such. In order to generate
the dictionary page of the documentation, we will sort it alphabetically,
but it is not alphabetically stored either in memory or in its serialised
form on disc. (It might seem advantageous, since we're going to sort it
anyway, to use the sorted ordering when saving it back to disc, as at least
the structure will then be nearly sorted most of the time: but in fact the
reverse is true, because we will sort using the C library's implementation
of quicksort, an algorithm whose worst-case performance is on nearly
sorted lists.)

@ The following sample is an extract of the dictionary in its serialised
form on disc. The four columns are author, title, headword and category.
The special entries with category "indexing" have two roles: they are
markers that the extension in question is indexed in the dictionary, and
they record the last date on which the extension was used.

Note that the stroke character is illegal in unquoted Inform source text,
and therefore also in excerpts with meanings, in extension titles and in
author names. It can therefore safely be used as a record divider.

In December 2007, the dictionary file of a user who had employed 155 different
extensions (by 33 different authors) contained 2223 entries, the longest of
which formed a line 95 characters long: the most prolific extension made 380
definitions. The total file size was about 130K. Some typical entries:

= (not code)
...
|Emily Short|Plurality|20110130181823:Sun 30 January 2011 18:18|indexing|
|Emily Short|Plurality|prior named noun|value|
|Emily Short|Plurality|ambiguously plural|property|
|Emily Short|Plurality|ordinarily enumerated|property|
|Emily Short|Locksmith|20110130181823:Sun 30 January 2011 18:18|indexing|
|Emily Short|Locksmith|passkey|kind|
|Emily Short|Locksmith|keychain|kind|
...

@ The file is encoded as ISO Latin-1 and can in principle have any of |0A|, |0D|,
|0A 0D| or |0D 0A| as line divider. Each line must be no longer than the
following number of characters minus 1:

@d MAX_ED_LINE_LENGTH 512

@ The following logs the dictionary as it stands in memory, in a similar
format but also recorded the erasure flag.

=
void Extensions::Dictionary::log_entry(extension_dictionary_entry *ede) {
	LOG("ede: %4d %d |%S|%S|%S|%S|\n", ede->allocation_id,
		ede->erased, ede->ede_work->author_name, ede->ede_work->title,
		ede->entry_text, ede->type);
}

void Extensions::Dictionary::log_extension_dictionary(void) {
	extension_dictionary_entry *ede;
	int n=0;
	LOGIF(EXTENSIONS_CENSUS, "Extension dictionary:\n");
	LOOP_OVER(ede, extension_dictionary_entry) {
		n++; LOGIF(EXTENSIONS_CENSUS, "$d", ede);
	}
	if (n==0) LOGIF(EXTENSIONS_CENSUS, "no entries\n");
}

@h Erasing entries.
The erasure flag is used to mark entries in the dictionary which are to
be erased, in that they will not survive when we save it back from memory
to disc. (Entries are never physically deleted from the memory structures.)

There are two reasons to erase entries. First, the following routine sets the
erased flag for dictionary entries corresponding to an extension which,
according to the census returns, is no longer installed. (This can happen
if the user has uninstalled an extension since the last time Inform successfully
ran.)

=
void Extensions::Dictionary::erase_entries_of_uninstalled_extensions(void) {
	extension_dictionary_entry *ede;
	LOGIF(EXTENSIONS_CENSUS, "Erasure of dictionary entries for uninstalled extensions\n");
	LOOP_OVER(ede, extension_dictionary_entry)
		if ((ede->erased == FALSE) &&
			(Works::no_times_used_in_context(ede->ede_work, INSTALLED_WDBC) == 0)) {
			ede->erased = TRUE;
			LOGIF(EXTENSIONS_CENSUS, "Erased $d", ede);
		}
}

@ The second reason arises when we are making the dictionary entries for an
extension which was used on the current run. (For instance, if it created a
kind of vehicle called "dragster", then we will make a dictionary entry
for that.) Before making its dictionary entries, we first erase all entries
for the same extension which are left in the dictionary from some previous
run of Inform, as those are now out of date.

=
void Extensions::Dictionary::erase_entries(extension_file *ef) {
	extension_dictionary_entry *ede;
	LOGIF(EXTENSIONS_CENSUS, "Erasure of dictionary entries for $x\n", ef);
	LOOP_OVER(ede, extension_dictionary_entry)
		if ((ede->erased == FALSE) &&
			(Works::match(ede->ede_work, ef->ef_req->work))) {
			ede->erased = TRUE;
			LOGIF(EXTENSIONS_CENSUS, "Erased $d", ede);
		}
}

@h Making new entries.
We provide two ways to add a new entry: from a C string or from a word range.

=
void Extensions::Dictionary::new_entry(text_stream *category, extension_file *ef, wording W) {
	if (Wordings::nonempty(W)) { /* a safety precaution: never index the empty text */
		TEMPORARY_TEXT(headword);
		WRITE_TO(headword, "%+W", W);
		Extensions::Dictionary::new_dictionary_entry_raw(category, ef->ef_req->work->author_name, ef->ef_req->work->title, headword);
		DISCARD_TEXT(headword);
	}
}

void Extensions::Dictionary::new_entry_from_stream(text_stream *category, inform_extension *E, text_stream *headword) {
	Extensions::Dictionary::new_dictionary_entry_raw(category, E->as_copy->edition->work->author_name, E->as_copy->edition->work->title, headword);
}

void Extensions::Dictionary::new_dictionary_entry_raw(text_stream *category,
	text_stream *author, text_stream *title, text_stream *headword) {
	extension_dictionary_entry *ede = CREATE(extension_dictionary_entry);
	ede->ede_work = Works::new(extension_genre, title, author);
	Works::add_to_database(ede->ede_work, DICTIONARY_REFERRED_WDBC);
	ede->entry_text = Str::duplicate(headword);
	ede->type = Str::duplicate(category);
	ede->sorting = Str::new();
	if (Str::eq_wide_string(category, L"indexing")) {
		TEMPORARY_TEXT(sdate);
		TEMPORARY_TEXT(udate);
		int mode = 0, wc = 0;
		LOOP_THROUGH_TEXT(pos, ede->entry_text) {
			if (Str::get(pos) == '/') { mode = 1; continue; }
			if (Str::get(pos) == ':') { mode = 2; continue; }
			int digital = Characters::isdigit(Str::get(pos));
			switch (mode) {
				case 0:
					if (digital) PUT_TO(sdate, Str::get(pos));
					break;
				case 1:
					if (digital) wc = 10*wc + ((int) Str::get(pos)) - ((int) '0');
					break;
				case 2:
					PUT_TO(udate, Str::get(pos));
					break;
			}
		}
		if (Str::len(sdate) > 0) Works::set_sort_date(ede->ede_work, sdate);
		if (wc > 0) Works::set_word_count(ede->ede_work, wc);
		if (Str::len(udate) > 0) Works::set_usage_date(ede->ede_work, udate);
		DISCARD_TEXT(sdate);
		DISCARD_TEXT(udate);
	}
	ede->erased = FALSE;
	ede->next_in_sorted_dictionary = NULL;
	LOGIF(EXTENSIONS_CENSUS, "Created $d", ede);
}

@h Loading from disc.
Not a surprising routine: open, convert one line at a time to dictionary
entries, close.

=
void Extensions::Dictionary::load(void) {
	@<Ensure the serialised extensions dictionary file exists@>;

	LOGIF(EXTENSIONS_CENSUS, "Reading dictionary file\n");
	TextFiles::read(filename_of_extensions_dictionary, FALSE,
		NULL, FALSE, Extensions::Dictionary::load_helper, NULL, NULL);
	LOGIF(EXTENSIONS_CENSUS, "Finished reading dictionary file\n");
}

@ The extension dictionary file is stored only transiently and may never have
been made, or may have been wiped by a zealous mobile OS. If it doesn't exist,
we try to make an empty one. Should these attempts fail, we simply return:
there might be permissions reasons, and it doesn't matter too much if the
dictionary isn't read. A fatal error results only if, having written the empty
file, we are then unable to open it again: that must mean a file I/O error of
some kind, which is bad enough news to bother the user with.

@<Ensure the serialised extensions dictionary file exists@> =
	FILE *DICTF = Filenames::fopen(filename_of_extensions_dictionary, "r");
	if (DICTF == NULL) {
		LOGIF(EXTENSIONS_CENSUS, "Creating new empty dictionary file\n");
		FILE *EMPTY_DICTF = Filenames::fopen(filename_of_extensions_dictionary, "w");
		if (EMPTY_DICTF == NULL) return;
		fclose(EMPTY_DICTF);
	}

@ We parse lines in a fairly forgiving way. Material before the initial stroke
is ignored (this helps us cope with any spare newline characters if there are
blank lines, or if the line division is multi-byte); material after the final
stroke is also ignored, and any line not containing five vertical strokes
(i.e., four stroke-divided columns) is ignored altogether. This means that
any truncated, overlong lines are ineffectual but safe.

=
void Extensions::Dictionary::load_helper(text_stream *line_entry,
	text_file_position *tfp, void *state) {
	TEMPORARY_TEXT(author);
	TEMPORARY_TEXT(title);
	TEMPORARY_TEXT(headword);
	TEMPORARY_TEXT(category);
	for (int strokes = 0, pos = 0; strokes <= 4; pos++) {
		int c = Str::get_at(line_entry, pos);
		if (c == 0) break;
		if (c == '|') {
			if (++strokes == 5)
				Extensions::Dictionary::new_dictionary_entry_raw(
					category, author, title, headword);
		} else {
			switch(strokes) {
				case 1: PUT_TO(author, c); break;
				case 2: PUT_TO(title, c); break;
				case 3: PUT_TO(headword, c); break;
				case 4: PUT_TO(category, c); break;
			}
		}
	}
	DISCARD_TEXT(author);
	DISCARD_TEXT(title);
	DISCARD_TEXT(headword);
	DISCARD_TEXT(category);
}

@h Time stamping.

=
void Extensions::Dictionary::time_stamp(inform_extension *E) {
	TEMPORARY_TEXT(dbuff);
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
	Extensions::Dictionary::new_entry_from_stream(I"indexing", E, dbuff);
	DISCARD_TEXT(dbuff);
}

@h Saving to disc.
And inversely...

=
void Extensions::Dictionary::write_back(void) {
	extension_dictionary_entry *ede;
	text_stream DICTF_struct;
	text_stream *DICTF = &DICTF_struct;

	if (STREAM_OPEN_TO_FILE(DICTF, filename_of_extensions_dictionary, UTF8_ENC) == FALSE) return;

	LOGIF(EXTENSIONS_CENSUS, "Writing dictionary file\n");

	LOOP_OVER(ede, extension_dictionary_entry)
		if (ede->erased == FALSE) {
			LOGIF(EXTENSIONS_CENSUS, "Writing $d", ede);
			@<Write line to the dictionary file from single entry@>;
		} else LOGIF(EXTENSIONS_CENSUS, "Suppressing $d\n", ede);

	LOGIF(EXTENSIONS_CENSUS, "Finished writing dictionary file\n");
	STREAM_CLOSE(DICTF);
}

@ We needn't worry overmuch about exceeding the maximum length, since any such
lines are handled safely by the loading code above. In any case, they could
only occur if it were true that

	|4 + MAX_ED_CATEGORY_LENGTH + MAX_ED_HEADWORD_LENGTH +|
	|    MAX_EXTENSION_TITLE_LENGTH + MAX_EXTENSION_AUTHOR_LENGTH >= MAX_ED_LINE_LENGTH|

and this is not nearly the case. (|MAX_ED_LINE_LENGTH| is larger than
strictly necessary since it costs us only temporary stack space and allows
for any future increase of the above maxima without fuss.)

@<Write line to the dictionary file from single entry@> =
	WRITE_TO(DICTF, "|%S|%S|%S|%S|\n",
		ede->ede_work->author_name, ede->ede_work->title,
		ede->entry_text, ede->type);

@h Sorting the extension dictionary.
We pass this job on to the standard C library |qsort|, in hopes that it is
reasonably efficiently implemented. We need to bear in mind that the
extensions database can be expected to have some thousands of entries,
and that the $O(n^2)$ insertion sorts used so casually elsewhere in Inform --
where lists are certainly much smaller -- could cause misery here.

This routine returns the number of (unerased) entries in the dictionary,
and on its exit the (unerased) entries each occur once in alphabetical
order in the linked list beginning at |first_in_sorted_dictionary|.
If two entries have identical headwords, the earliest created is the
one which appears earlier in the sorted dictionary.

=
int Extensions::Dictionary::sort_extension_dictionary(void) {
	extension_dictionary_entry **sorted_extension_dictionary = NULL;
	int no_entries = 0;

	LOGIF(EXTENSIONS_CENSUS, "Beginning dictionary sort\n");
	sorted_extension_dictionary = NULL;

	@<Count headwords and reprocess their texts for dictionary sorting@>;

	if (no_entries == 0) {
		first_in_sorted_dictionary = NULL;
		return 0;
	}

	@<Allocate memory for, and fill, an array of pointers to the EDEs@>;

	qsort(sorted_extension_dictionary, (size_t) no_entries, sizeof(extension_dictionary_entry *),
		Extensions::Dictionary::compare_ed_entries);

	@<String the sorted array together into a sorted linked list of EDEs@>;
	@<Deallocate memory for the array again@>;

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
correspond to creation order. This means that |qsort|'s output will be
predictable (whereas different implementations of Quicksort might use the
freedom to sort unstably in different ways), and this seems a good idea
for better testing.

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

@ We unbundle the linked list of EDEs in creation order into an array
temporarily allocated in memory:

@<Allocate memory for, and fill, an array of pointers to the EDEs@> =
	extension_dictionary_entry *ede;
	int i = 0;
	sorted_extension_dictionary = Memory::I7_calloc(no_entries,
		sizeof(extension_dictionary_entry *), EXTENSION_DICTIONARY_MREASON);
	LOOP_OVER(ede, extension_dictionary_entry) {
		if (ede->erased == FALSE)
			sorted_extension_dictionary[i++] = ede;
	}

@ We then use the sorted version of the same array to reorder the EDEs:

@<String the sorted array together into a sorted linked list of EDEs@> =
	int i;
	first_in_sorted_dictionary = sorted_extension_dictionary[0];
	for (i=0; i<no_entries-1; i++)
		sorted_extension_dictionary[i]->next_in_sorted_dictionary =
			sorted_extension_dictionary[i+1];
	if (no_entries > 0)
		sorted_extension_dictionary[no_entries-1]->next_in_sorted_dictionary = NULL;

@ And for the sake of tidiness:

@<Deallocate memory for the array again@> =
	Memory::I7_array_free(sorted_extension_dictionary, EXTENSION_DICTIONARY_MREASON,
		no_entries, sizeof(extension_dictionary_entry *));

@ As always with |qsort|, there's a palaver about the types used for the
comparison function so that the result will compile without errors. The
comparison of two EDEs is in fact delegated to a |strcmp| comparison
of their sorting texts:

=
int Extensions::Dictionary::compare_ed_entries(const void *elem1, const void *elem2) {
	const extension_dictionary_entry **e1 = (const extension_dictionary_entry **) elem1;
	const extension_dictionary_entry **e2 = (const extension_dictionary_entry **) elem2;
	if ((*e1 == NULL) || (*e2 == NULL))
		internal_error("Disaster while sorting extension dictionary");
	return Str::cmp((*e1)->sorting, (*e2)->sorting);
}

@h Extension clashes.
All Inform extensions included share the main name-space of the source
text, and this causes potential problems with name clashes between two
different extensions if ever an author wants to include both at once. To
try to detect these clashes, we automatically scan the dictionary for them,
and provide warnings on the dynamic extension index.

=
known_extension_clash *Extensions::Dictionary::kec_new(extension_dictionary_entry *L, extension_dictionary_entry *R,
	int first_known_flag) {
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

(-c.1) If such a KEC does not exist, then L does not clash with any other
extension.

(-c.2) If such a KEC does exist, then it is the head of a linked list of
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
"lead" (the attachment to a collar).

=
void Extensions::Dictionary::extension_clash(extension_dictionary_entry *ede1, extension_dictionary_entry *ede2) {
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

	kec = Extensions::Dictionary::kec_new(left, right, TRUE);
}

@ If two name clashes occur in the same extension then, since we can presume
that this extension does actually work, the clash cannot cause problems.
We also ignore a clash of a property name against some other form of name,
because these occur quite often and cause little difficulty in practice: so
they would only clutter up the dictionary with spurious warnings.

@<Ignore apparent clashes which are in fact not troublesome@> =
	if (d == 0) return; /* both definitions come from the same extension */
	if ((Str::eq_wide_string(ede1->type, L"property")) && (Str::eq_wide_string(ede2->type, L"property") == FALSE)) return;
	if ((Str::eq_wide_string(ede1->type, L"property") == FALSE) && (Str::eq_wide_string(ede2->type, L"property"))) return;

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
			kec->next = Extensions::Dictionary::kec_new(left, right, FALSE); return;
		}
		kec = kec->next;
	}

@ The above arrangement was designed to make it easy to print out the
clashes in a concise, human-readable way, which is what we now do.

=
void Extensions::Dictionary::list_known_extension_clashes(OUTPUT_STREAM) {
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

@ As always, we need to be careful about writing the ISO text of clashing
matter to the UTF-8 HTML file:

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

@h Writing the HTML extension index.
This is the index of terms, not the directory of extensions: it is, in
fact, the HTML rendering of the dictionary constructed above.

=
void Extensions::Dictionary::write_to_HTML(OUTPUT_STREAM) {
	HTML_OPEN("p");
	WRITE("Whenever an extension is used, its definitions are entered into the "
		"following index. (Thus, a newly installed but never-used extension "
		"is not indexed yet.).");
	HTML_CLOSE("p");
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	int n;
	int first_letter = 'a';
	extension_dictionary_entry *ede, *previous_ede, *next_ede;
	Extensions::Dictionary::erase_entries_of_uninstalled_extensions();
	n = Extensions::Dictionary::sort_extension_dictionary();
	if (n <= 0) return;
	for (previous_ede = NULL, ede = first_in_sorted_dictionary; ede;
		previous_ede = ede, ede = ede->next_in_sorted_dictionary) {
		if (Str::eq_wide_string(ede->type, L"indexing")) continue;
		next_ede = ede->next_in_sorted_dictionary;
		int this_first = Characters::tolower(Str::get_first_char(ede->entry_text));
		if (first_letter != this_first) {
			HTML_TAG("br"); first_letter = this_first;
		}
		@<Write extension dictionary entry for this headword@>;
	}
	Extensions::Dictionary::list_known_extension_clashes(OUT);
}

@ A run of $N$ words which are all the same should appear in tinted type
throughout, while $N(N-1)/2$ clashes should be reported to the machinery above:
if we find definitions A, B, C, for instance, the clashes are reported as
A vs B, A vs C, then B vs C. This has $O(N^2)$ running time, so if there are
1000 extensions, each of which gives 1000 different meanings to the word
"frog", we would be in some trouble here. Let's take the risk.

@d EDES_DEFINE_SAME_WORD(X, Y) ((X) && (Y) && (Str::eq(X->sorting, Y->sorting)))

@<Write extension dictionary entry for this headword@> =
	int tint = FALSE;
	if (EDES_DEFINE_SAME_WORD(ede, previous_ede)) tint = TRUE;
	while (EDES_DEFINE_SAME_WORD(ede, next_ede)) {
		tint = TRUE;
		Extensions::Dictionary::extension_clash(ede, next_ede);
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
