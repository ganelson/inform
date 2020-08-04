[BootVerbs::] Booting Verbs.

In Inform even verbs are created with natural language sentences, but this
process has to start somewhere.

@ "Booting" is the traditional computing term for "pulling yourself up by
your own bootstraps": when a computer switches on it has no program to run,
but to load in a program would require a program. The circularity is broken
by having a minimal "boot" program wired into the hardware.

So too with Inform. The opening sentence of the Basic Inform extension, always
the first sentence read in, is:

>> The verb to mean means the meaning relation.

(See //basic_inform: Preamble//.) But this is circular: if we have not yet
defined "to mean", how can we recognise "means" as the verb, or know what it
means? We break this circularity by hard-wiring it, as follows.

=
void BootVerbs::make_built_in(void) {
	verb *to_mean;
	special_meaning_holder *meaning_of_mean;
	@<Create the special meanings@>;
	@<Create the verbs to be and to mean@>;
	@<Give meaning to mean@>;
}

@ "Regular" meanings involve relations between two values: for example, carrying
and numerical greater-than are both regular meanings, of the verbs "to carry"
and |>| respectively.

"Special" meanings are different. The noun phrases need not represent values,
there need not be two of them, and the meaning can have internal significance
to the Inform compiler. For example,

>> Black king chess piece translates into Unicode as 9818.

is one of three special meanings of "to translate into". The //linguistics//
module decides which if any is meant in a given case by calling the "special
meaning functions" to see if wants to accept the sentence in question.

@ When the //linguistics// module looks for a primary verb, it may find
multiple candidates: consider "fruit flies like a banana", where "flies" and
"like" are both candidate verbs. We decide by (a) ranking verbs in tiers by
"priority number", and failing that (b) choosing the leftmost. Priority 0
verbs are never considered, but otherwise low priority numbers beat higher.
(See //linguistics: Verb Usages//.)

Inform adopts the following convention for the priority of regular meanings:

(a) Regular "to have" has priority 1.
(b) Regular "to be" has priority 2.
(c) Otherwise, regular verbs in the language of the source text have priority 4.
(d) And regular verbs in some other language have priority 5.

As can be seen below, special meanings have priorities between 1 and 4. Note
that "to mean" itself has both a special meaning (priority 3) and a regular
meaning (priority 4). This is why the sentence:

>> The verb to mean means the meaning relation.

is not circular. It uses the special meaning of "mean" (priority 3) to create
the regular one (4).

@ So, then, here are the core module's special meanings. Just like regular
meanings, which have names like "containment relation", special meanings have
names. But as these names are only used in early boot sentences in the
//basic_inform// extension, the user never sees them. They are required to
be a single word, and are hyphenated.

@<Create the special meanings@> =
	SpecialMeanings::declare(RelationRequests::new_relation_SMF,					I"new-relation", 1);
	SpecialMeanings::declare(Rules::Placement::substitutes_for_SMF,			I"rule-substitutes-for", 1);
	SpecialMeanings::declare(Rules::Placement::does_nothing_SMF,			I"rule-does-nothing", 1);
	SpecialMeanings::declare(Rules::Placement::does_nothing_if_SMF,			I"rule-does-nothing-if", 1);
	SpecialMeanings::declare(Rules::Placement::does_nothing_unless_SMF,		I"rule-does-nothing-unless", 1);
	SpecialMeanings::declare(Translations::translates_into_unicode_as_SMF,	I"translates-into-unicode", 1);
	SpecialMeanings::declare(Translations::translates_into_Inter_as_SMF,	I"translates-into-i6", 1);
	SpecialMeanings::declare(Translations::translates_into_language_as_SMF,	I"translates-into-language", 1);

	SpecialMeanings::declare(NewVerbs::new_verb_SMF, 						I"new-verb", 2);
	SpecialMeanings::declare(Plurals::plural_SMF, 							I"new-plural", 2);
	SpecialMeanings::declare(ActivityRequests::new_activity_SMF, 					I"new-activity", 2);
	SpecialMeanings::declare(NewVerbs::new_adjective_SMF,					I"new-adjective", 2);
	SpecialMeanings::declare(Assertions::Property::either_SMF,				I"new-either-or", 2);
	SpecialMeanings::declare(DefineByTable::defined_by_SMF,				I"defined-by-table", 2);
	SpecialMeanings::declare(Rules::Placement::listed_in_SMF,				I"rule-listed-in", 2);
	SpecialMeanings::declare(Assertions::Property::optional_either_SMF,		I"can-be", 2);

	meaning_of_mean = SpecialMeanings::declare(NewVerbs::verb_means_SMF, 	I"verb-means", 3);

	SpecialMeanings::declare(LPRequests::specifies_SMF, 				I"specifies-notation", 4);
	SpecialMeanings::declare(NewUseOptions::use_translates_as_SMF,				I"use-translates", 4);
	SpecialMeanings::declare(UseOptions::use_SMF,							I"use", 4);
	SpecialMeanings::declare(Sentences::DLRs::include_in_SMF,				I"include-in", 4);
	SpecialMeanings::declare(Sentences::DLRs::omit_from_SMF,				I"omit-from", 4);

	#ifdef MULTIMEDIA_MODULE
	MultimediaMeanings::bootstrap();
	#endif
	#ifdef IF_MODULE
	IFModuleMeanings::bootstrap();
	#endif

@ We need the English infinitive forms of two verbs to get started. In each
case we use the //inflections// module to conjugate them -- i.e., to generate
all the other forms, "is", "did not mean" and so on -- and then hand them to
the //linguistics// module to add to its stock of known verbs. (It starts out
with none, so these are initially the only two.)

We need to create "to be" first because (a) it is the only copular verb in
Inform, and there is no way to create a copular verb using Inform source text;
and (b) because this enables us to conjugate forms of "mean" such as "X is
meant by" -- note the use of "is".

=
<bootstrap-verb> ::=
	be |
	mean

@<Create the verbs to be and to mean@> =
	word_assemblage infinitive = PreformUtilities::wording(<bootstrap-verb>, 0);
	verb_conjugation *vc = Conjugation::conjugate(infinitive, DefaultLanguage::get(NULL));
	verb *to_be = Verbs::new_verb(vc, TRUE); /* note that "to be" is created as copular */
	vc->vc_conjugates = to_be;
	VerbUsages::register_all_usages_of_verb(to_be, FALSE, 2, NULL);

	infinitive = PreformUtilities::wording(<bootstrap-verb>, 1);
	vc = Conjugation::conjugate(infinitive, DefaultLanguage::get(NULL));
	to_mean = Verbs::new_verb(vc, FALSE); /* but "to mean" is not */
	vc->vc_conjugates = to_mean;
	VerbUsages::register_all_usages_of_verb(to_mean, FALSE, 3, NULL);

@ Those two verbs are now part of our linguistic stock, but do not yet mean
anything. We need to give the build-in "verb-means" meaning to "to mean":

@<Give meaning to mean@> =
	if ((to_mean == NULL) || (meaning_of_mean == NULL)) internal_error("could not make to mean");
	Verbs::add_form(to_mean, NULL, NULL, VerbMeanings::special(meaning_of_mean), SVO_FS_BIT);
