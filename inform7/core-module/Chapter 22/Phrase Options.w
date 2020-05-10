[Phrases::Options::] Phrase Options.

To create and subsequently parse against the list of phrase options
with which the user can choose to invoke a To phrase.

@h Definitions.

@ A "phrase option" is a sort of modifier tacked on to the instruction to
do something, changing how it works but not enough to merit an entirely new
phrase. It's like an argument passed to a routine which specifies optional
behaviour, and indeed that will be how it is compiled.

Like the token names, phrase option names have local scope (which is why
they are here and not in the excerpts database). Unlike them, they are not
valid as values, since a condition is not also a value in Inform 7.

The packet of these associated with a phrase is stored in the PHOD structure.

@d MAX_OPTIONS_PER_PHRASE 16 /* because held in a 16-bit Z-machine bitmap */

=
typedef struct ph_options_data {
	struct phrase_option *options_permitted[MAX_OPTIONS_PER_PHRASE]; /* see below */
	int no_options_permitted;
	struct wording options_declaration; /* the text declaring the whole set of options */
	int multiple_options_permitted; /* can be combined, or mutually exclusive? */
} ph_options_data;

@ There's nothing to a phrase option, really:

=
typedef struct phrase_option {
	struct wording name; /* text of name */
} phrase_option;

@h Creation.
By default, a phrase has no options.

=
ph_options_data Phrases::Options::new(wording W) {
	ph_options_data phod;
	phod.no_options_permitted = 0;
	phod.multiple_options_permitted = FALSE;
	phod.options_declaration = W;
	return phod;
}

int Phrases::Options::allows_options(ph_options_data *phod) {
	if (phod->no_options_permitted > 0) return TRUE;
	return FALSE;
}

@h Parsing.
This isn't very efficient, but doesn't need to be, since phrase options
are parsed only in a condition context, not in a value context, and
these are relatively rare in Inform source text.

=
int Phrases::Options::parse(ph_options_data *phod, wording W) {
	for (int i = 0; i < phod->no_options_permitted; i++)
		if (Wordings::match(W, phod->options_permitted[i]->name))
			return (1 << i);
	return -1;
}

@h Indexing.

=
void Phrases::Options::index(OUTPUT_STREAM, ph_options_data *phod) {
	for (int i=0; i<phod->no_options_permitted; i++) {
		phrase_option *po = phod->options_permitted[i];
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
		if (i==0) {
			HTML_TAG("br");
			WRITE("<i>optionally</i> ");
		} else if (i == phod->no_options_permitted-1) {
			if (phod->multiple_options_permitted) WRITE("<i>and/or</i> ");
			else WRITE("<i>or</i> ");
		}
		PasteButtons::paste_W(OUT, po->name);
		WRITE("&nbsp;%+W", po->name);
		if (i < phod->no_options_permitted-1) {
			WRITE(",");
			HTML_TAG("br");
		}
		WRITE("\n");
	}
}

@h Parsing phrase options in a declaration.

=
ph_options_data *phod_being_parsed = NULL;
phrase *ph_being_parsed = NULL;

ph_options_data Phrases::Options::parse_declared_options(wording W) {
	ph_options_data phod = Phrases::Options::new(W);
	if (Wordings::nonempty(W)) {
		phod_being_parsed = &phod;
		<phrase-option-declaration-list>(W);
		if (<<r>>) phod.multiple_options_permitted = TRUE;
	}
	return phod;
}

@ I have to say that I regret the syntax for phrase options, which makes
us write commas like the one here:

>> let R be the best route from X to Y, using doors;

I sometimes even regret the existence of phrase options, but it must be
admitted that they are a clean way to interface to low-level Inform 6 code.
But it's mostly the comma which annoys me (making text substitutions unable
to support phrase options); I should have gone for brackets.

The syntax for declaring phrase options is uncontroversial -- it's just
a list of names -- but there are wrinkles: if the list is divided with "or"
then the options are mutually exclusive, but with "and/or" they're not.
For example, in:

>> To decide which object is best route from (R1 - object) to (R2 - object), using doors or using even locked doors: ...

the following parses this list:

>> using doors or using even locked doors

and creates two options with <phrase-option-declaration-setting-entry>.

=
<phrase-option-declaration-list> ::=
	... |    ==> FALSE; return preform_lookahead_mode; /* match only when looking ahead */
	<phrase-option-declaration-setting-entry> <phrase-option-declaration-tail> |    ==> R[2]
	<phrase-option-declaration-setting-entry>		==> FALSE

<phrase-option-declaration-tail> ::=
	, _or <phrase-option-declaration-list> |    ==> R[1]
	, \and/or <phrase-option-declaration-list> |    ==> TRUE
	_,/or <phrase-option-declaration-list> |    ==> R[1]
	\and/or <phrase-option-declaration-list>		==> TRUE

<phrase-option-declaration-setting-entry> ::=
	...		==> FALSE; if (!preform_lookahead_mode) Phrases::Options::phod_add_phrase_option(phod_being_parsed, W);

@ =
int too_many_POs_error = FALSE;
void Phrases::Options::phod_add_phrase_option(ph_options_data *phod, wording W) {
	LOGIF(PHRASE_CREATIONS, "Adding phrase option <%W>\n", W);
	if (phod->no_options_permitted >= MAX_OPTIONS_PER_PHRASE) {
		if (too_many_POs_error == FALSE)
			Problems::Issue::sentence_problem(Task::syntax_tree(), _p_(PM_TooManyPhraseOptions),
				"a phrase is only allowed to have 16 different options",
				"so either some of these will need to go, or you may want to "
				"consider breaking up the phrase into simpler ones whose usage "
				"is easier to describe.");
		too_many_POs_error = TRUE;
		return;
	}
	too_many_POs_error = FALSE; /* so that the problem can recur on later phrases */

	phrase_option *po = CREATE(phrase_option);
	po->name = W;
	phod->options_permitted[phod->no_options_permitted++] = po;
}

@h Parsing phrase options in an invocation.
At this point, we're looking at the text after the first comma in something
like:

>> list the contents of the box, as a sentence, with newlines;

The invocation has already been parsed enough that we know the options
chosen are:

>> as a sentence, with newlines

and the following routine turns that into a bitmap with two bits set, one
corresponding to each choice.

We return |TRUE| or |FALSE| according to whether the options were valid or
not, and the |silently| flag suppresses problem messages we would otherwise
produce.

=
int phod_being_parsed_silently = FALSE; /* context for the grammar below */

int Phrases::Options::parse_invoked_options(parse_node *inv, int silently) {
	phrase *ph = ParseTree::get_phrase_invoked(inv);
	wording W = Invocations::get_phrase_options(inv);

	ph_being_parsed = ph;
	phod_being_parsed = &(ph_being_parsed->options_data);

	int bitmap = 0;
	int pc = problem_count;
	@<Parse the supplied list of options into a bitmap@>;

	Invocations::set_phrase_options_bitmap(inv, bitmap);
	if (problem_count > pc) return FALSE;
	return TRUE;
}

@<Parse the supplied list of options into a bitmap@> =
	int s = phod_being_parsed_silently;
	phod_being_parsed_silently = silently;
	if (<phrase-option-list>(W)) bitmap = <<r>>;
	phod_being_parsed_silently = s;

	if ((problem_count == pc) &&
		(phod_being_parsed->multiple_options_permitted == FALSE))
		@<Reject this if multiple options are set@>;

@ Ah, bit-twiddling: fun for all the family. There's no point computing the
Hamming distance of the bitmap, that is, the number of bits set: we only need
to know if it's a power of 2 or not. Note that subtracting 1, in binary,
clears the least significant set bit, leaves the higher bits as they are,
and changes the lower bits (which were previously all 0s) to 1s. So taking
a bitwise-and of a number and itself minus one leaves just the higher bits
alone. The original number therefore had a single set bit if and only if
this residue is zero.

@<Reject this if multiple options are set@> =
	if ((bitmap & (bitmap - 1)) != 0) {
		if (silently == FALSE) {
			Problems::quote_source(1, current_sentence);
			Problems::quote_wording(2, W);
			Problems::quote_phrase(3, ph);
			Problems::quote_wording(4, phod_being_parsed->options_declaration);
			Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_PhraseOptionsExclusive));
			Problems::issue_problem_segment(
				"You wrote %1, supplying the options '%2' to the phrase '%3', but "
				"the options listed for this phrase ('%4') are mutually exclusive.");
			Problems::issue_problem_end();
		}
		return FALSE;
	}

@ When setting options, in an actual use of a phrase, the list is divided
by "and":

=
<phrase-option-list> ::=
	... |    ==> FALSE; return preform_lookahead_mode; /* match only when looking ahead */
	<phrase-option-setting-entry> <phrase-option-tail> | ==> R[1] | R[2]
	<phrase-option-setting-entry>						==> R[1]

<phrase-option-tail> ::=
	, _and <phrase-option-list> |    ==> R[1]
	_,/and <phrase-option-list>							==> R[1]

<phrase-option-setting-entry> ::=
	<phrase-option> |    ==> R[1]
	...					==> @<Issue PM_NotAPhraseOption or C22NotTheOnlyPhraseOption problem@>

@<Issue PM_NotAPhraseOption or C22NotTheOnlyPhraseOption problem@> =
	if ((!preform_lookahead_mode) && (!phod_being_parsed_silently)) {
		Problems::quote_source(1, current_sentence);
		Problems::quote_wording(2, W);
		Problems::quote_phrase(3, ph_being_parsed);
		Problems::quote_wording(4, phod_being_parsed->options_declaration);
		if (phod_being_parsed->no_options_permitted > 1) {
			Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_NotAPhraseOption));
			Problems::issue_problem_segment(
				"You wrote %1, but '%2' is not one of the options allowed on "
				"the end of the phrase '%3'. (The options allowed are: '%4'.)");
			Problems::issue_problem_end();
		} else {
			Problems::Issue::handmade_problem(Task::syntax_tree(), _p_(PM_NotTheOnlyPhraseOption));
			Problems::issue_problem_segment(
				"You wrote %1, but the only option allowed on the end of the "
				"phrase '%3' is '%4', so '%2' is not something I know how to "
				"deal with.");
			Problems::issue_problem_end();
		}
	}

@ The following matches any single phrase option for the phrase being used.

=
<phrase-option> internal {
	int bitmap = Phrases::Options::parse(phod_being_parsed, W);
	if (bitmap == -1) return FALSE;
	*X = bitmap; return TRUE;
}
