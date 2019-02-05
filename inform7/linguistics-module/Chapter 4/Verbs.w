[Verbs::] Verbs.

To record the identity and different structural forms of verbs.

@h Definitions.

@ One verbs above all is special to us, because of the unique role it plays
in natural language. This is the copular verb, so called because it has two
interacting subject phrases rather than a subject and an object: in English,
"to be". We store its identity in a global variable which is set equal
to the first-created verb marked as copular.

=
verb_identity *copular_verb = NULL;

@h Verb Identities.
What is a verb? Are the verbs in "Peter is hungry" and "Jane will be in the
Dining Room" the same? How about in "Donald Trump lies on television" and
"My cat Donald lies on the television"? This isn't so easy to answer.

For our purposes two usages of a verbs are "the same verb" if they ultimately
come from the same instance of the following structure; this essentially
defines a verb as a combination of its inflected forms with its possible
usages in a sentence.

=
typedef struct verb_identity {
	struct verb_conjugation *conjugation;
	struct verb_form *list_of_forms;
	#ifdef CORE_MODULE
	struct package_request *verb_package;
	#endif
	MEMORY_MANAGEMENT
} verb_identity;

@ Note that the first verb submitted with the copular flag set is considered
to be the definitive copular verb.

Note also that every verb always has a bare form, where no prepositions are
combined with it. This is (initially) meaningless, but it always exists.

Finally, note that the conjugation can be null. This is used only for
what we'll call "operator verbs", where a mathematical operator is used
instead of a word: for example, the |<=| sign is such a verb in Inform.

=
verb_identity *Verbs::new_verb(verb_conjugation *vc, int cop) {
	verb_identity *vi = CREATE(verb_identity);
	vi->conjugation = vc;
	vi->list_of_forms = NULL;
	#ifdef CORE_MODULE
	vi->verb_package = NULL;
	#endif
	if ((cop) && (copular_verb == NULL) && (vc) &&
		(WordAssemblages::nonempty(vc->infinitive))) copular_verb = vi;
	LOGIF(VERB_FORMS, "New verb: $w\n", vi);
	Verbs::add_form(vi, NULL, NULL, VerbMeanings::meaninglessness(), SVO_FS_BIT);
	return vi;
}

void Verbs::log_verb(OUTPUT_STREAM, void *vvi) {
	verb_identity *vi = (verb_identity *) vvi;
	if (vi == NULL) { WRITE("<no-vi>"); }
	else {
		WRITE("v=");
		if (vi->conjugation) WRITE("%A", &(vi->conjugation->infinitive));
		else WRITE("<none>");
		WRITE("(%d)", vi->allocation_id);
	}
}

@h Package.

=
#ifdef CORE_MODULE
package_request *Verbs::verb_package(verb_identity *vi, parse_node *where) {
	if (vi == NULL) internal_error("no verb identity");
	if (vi->verb_package == NULL)
		vi->verb_package =
			Packaging::request(
				Packaging::supply_iname(
					Packaging::request_conjugations(Modules::find(where)),
					VERB_PR_COUNTER),
				Packaging::request_conjugations(Modules::find(where)),
				verb_ptype);
	return vi->verb_package;
}
#endif

@h Operator Verbs.
As noted above, these are tenseless verbs with no conjugation, represented
only by symbols such as |<=|. As infix operators, they mimic SVO sentence
structures.

=
verb_identity *Verbs::new_operator_verb(verb_meaning vm) {
	verb_identity *vi = Verbs::new_verb(NULL, FALSE);
	Verbs::add_form(vi, NULL, NULL, vm, SVO_FS_BIT);
	return vi;
}

@h Verb Forms.
A "verb form" is a way to use a given verb in a sentence. This may require
up to two different prepositions to be used. For example, "Peter is hungry"
and "Jane will be in the Dining Room" exhibit two different verb forms:
"to be" with no preposition (meaning that the object phrase, "hungry", is
not introduced by a preposition), and "to be" with the preposition "in".

It's not always the case that the preposition follows the verb, even when
it directly introduces the object, because of a quirk of English called
inversion: for example "In the Dining Room is Jane" locates "in" far from
"is". But the first preposition, if given, always introduces the object
phrase. If it's not given, the object phrase has no introduction, as in
the sentence "Peter is hungry".

The second clause preposition is again optional. This marks that the verb
takes two object phrases, and provides a preposition to introduce the
second of these. For example, in "X translates into Y as Z", the verb
is "translate", the first preposition is "into", and the second is "as".
In "X ends Y when Z", the first preposition is null, and the second is "when".

@ A "form structure" is a possible way in which a verb form can be expressed.
SVO means "subject, verb, object", as in "Peter likes Jane"; VOO means
"verb, object, object", as in "Test me with ...", and so on. Since multiple
form usages can be legal for the same form, this is a bitmap:

@d SVO_FS_BIT 			1
@d VO_FS_BIT			2
@d SVOO_FS_BIT			4
@d VOO_FS_BIT			8

@ So here's the verb form:

=
typedef struct verb_form {
	struct verb_identity *underlying_verb;
	struct preposition_identity *preposition;
	struct preposition_identity *second_clause_preposition;
	int form_structures; /* bitmap of |*_FS_BIT| values */
	#ifdef CORE_MODULE
	struct inter_name *vf_iname; /* routine to conjugate this */
	struct parse_node *where_vf_created;
	#endif
	struct word_assemblage infinitive_reference_text; /* e.g. "translate into" */
	struct word_assemblage pos_reference_text; /* e.g. "translate into" */
	struct word_assemblage neg_reference_text; /* e.g. "do not translate into" */

	struct verb_sense *list_of_senses;

	struct verb_form *next_form; /* within the linked list for the verb */
	MEMORY_MANAGEMENT
} verb_form;

@h Verb senses.
In this model, a verb can have multiple senses. Inform makes little use of
that in verbs created by the user, but for example "X is Y" has more than
a dozen different senses. (Inform distinguishes them on a case by case basis,
by looking at X and Y.)

The following structure is just a holder for a "verb meaning", so that it
can be joined into a linked list. Verb meanings are described elsewhere.

=
typedef struct verb_sense {
	struct verb_meaning vm;
	struct verb_sense *next_sense; /* within the linked list for the verb form */
	MEMORY_MANAGEMENT
} verb_sense;

@h Creating forms and senses.
Forms are stored in a linked list, and are uniquely identified by the triplet
of verb and two prepositions:

=
verb_form *Verbs::find_form(verb_identity *vi, preposition_identity *prep, preposition_identity *second_prep) {
	if (vi)
		for (verb_form *vf = vi->list_of_forms; vf; vf = vf->next_form)
			if ((vf->preposition == prep) && (vf->second_clause_preposition == second_prep))
				return vf;
	return NULL;
}

@ And here's how we add them.

=
void Verbs::add_form(verb_identity *vi, preposition_identity *prep,
	preposition_identity *second_prep, verb_meaning vm, int form_structs) {
	if (VerbMeanings::is_meaningless(&vm) == FALSE)
		LOGIF(VERB_FORMS, "  Adding form: $w + $p + $p = $y\n",
			vi, prep, second_prep, &vm);

	VerbMeanings::set_where_assigned(&vm, current_sentence);

	if (vi == NULL) internal_error("added form to null verb");

	verb_form *vf = NULL;
	@<Find or create the verb form structure for this combination@>;

	vf->form_structures = ((vf->form_structures) | form_structs);

	if ((VerbMeanings::is_meaningless(&vm) == FALSE) || (vf->list_of_senses == NULL))
		@<Add this meaning as a new sense of the verb form@>;
}

@<Find or create the verb form structure for this combination@> =
	vf = Verbs::find_form(vi, prep, second_prep);
	if (vf == NULL) {
		vf = CREATE(verb_form);
		vf->underlying_verb = vi;
		vf->preposition = prep;
		vf->second_clause_preposition = second_prep;
		vf->form_structures = 0;
		vf->list_of_senses = NULL;
		vf->next_form = NULL;
		#ifdef CORE_MODULE
		vf->vf_iname = NULL;
		vf->where_vf_created = current_sentence;
		#endif
		@<Compose the reference texts for the new form@>;
		@<Insert the new form into the list of forms for this verb@>;
	}

@ The reference texts are just for convenience, really: they express the form
in a canonical verbal form. For example, "translate into |+| as".

@<Compose the reference texts for the new form@> =
	verb_conjugation *vc = vi->conjugation;
	if (vc) {
		int p = PREFORM_ADAPTIVE_PERSON(vc->defined_in);
		word_assemblage we_form = (vc->tabulations[ACTIVE_MOOD].vc_text[IS_TENSE][0][p]);
		word_assemblage we_dont_form = (vc->tabulations[ACTIVE_MOOD].vc_text[IS_TENSE][1][p]);
		vf->infinitive_reference_text = vc->infinitive;
		vf->pos_reference_text = we_form;
		vf->neg_reference_text = we_dont_form;
		if (prep) {
			vf->infinitive_reference_text = WordAssemblages::join(vf->infinitive_reference_text, prep->prep_text);
			vf->pos_reference_text = WordAssemblages::join(vf->pos_reference_text, prep->prep_text);
			vf->neg_reference_text = WordAssemblages::join(vf->neg_reference_text, prep->prep_text);
		}
		if (second_prep) {
			word_assemblage plus = WordAssemblages::lit_1(PLUS_V);
			vf->infinitive_reference_text = WordAssemblages::join(vf->infinitive_reference_text, plus);
			vf->pos_reference_text = WordAssemblages::join(vf->pos_reference_text, plus);
			vf->neg_reference_text = WordAssemblages::join(vf->neg_reference_text, plus);
			vf->infinitive_reference_text = WordAssemblages::join(vf->infinitive_reference_text, second_prep->prep_text);
			vf->pos_reference_text = WordAssemblages::join(vf->pos_reference_text, second_prep->prep_text);
			vf->neg_reference_text = WordAssemblages::join(vf->neg_reference_text, second_prep->prep_text);
		}
	} else {
		vf->infinitive_reference_text = WordAssemblages::new_assemblage();
		vf->pos_reference_text = WordAssemblages::new_assemblage();
		vf->neg_reference_text = WordAssemblages::new_assemblage();
	}

@ The list of forms for a verb is in order of preposition length.

@<Insert the new form into the list of forms for this verb@> =
	verb_form *prev = NULL, *evf = vi->list_of_forms;
	for (; evf; prev = evf, evf = evf->next_form) {
		if (Prepositions::length(prep) > Prepositions::length(evf->preposition)) break;
	}
	if (prev == NULL) {
		vf->next_form = vi->list_of_forms;
		vi->list_of_forms = vf;
	} else {
		vf->next_form = prev->next_form;
		prev->next_form = vf;
	}

@ A new sense is normally just added to the end of the list of senses for
the given form, except that if there's a meaningless sense present already,
we overwrite that with the new (presumably meaningful) one.

@<Add this meaning as a new sense of the verb form@> =
	verb_sense *vs = vf->list_of_senses, *prev = NULL;
	while (vs) {
		if (VerbMeanings::is_meaningless(&(vs->vm))) { vs->vm = vm; break; }
		prev = vs; vs = vs->next_sense;
	}
	if (vs == NULL) {
		vs = Verbs::new_sense(vm);
		if (prev == NULL) vf->list_of_senses = vs;
		else prev->next_sense = vs;
	}

@ =
#ifdef CORE_MODULE
inter_name *Verbs::form_iname(verb_form *vf) {
	if (vf->vf_iname == NULL) {
		package_request *R = Verbs::verb_package(vf->underlying_verb, vf->where_vf_created);
		vf->vf_iname =
			Packaging::function(
				Packaging::supply_iname(R, FORM_PR_COUNTER),
				R,
				InterNames::new(CONJUGATE_VERB_FORM_INAMEF));
	}
	return vf->vf_iname;
}
#endif

@ Where:

=
verb_sense *Verbs::new_sense(verb_meaning vm) {
	verb_sense *vs = CREATE(verb_sense);
	vs->vm = vm;
	vs->next_sense = NULL;
	return vs;
}

verb_meaning *Verbs::regular_meaning(verb_identity *vi,
	preposition_identity *prep, preposition_identity *second_prep) {
	verb_form *vf = Verbs::find_form(vi, prep, second_prep);
	return Verbs::regular_meaning_from_form(vf);
}

verb_meaning *Verbs::regular_meaning_from_form(verb_form *vf) {
	if (vf)
		for (verb_sense *vs = vf->list_of_senses; vs; vs = vs->next_sense) {
			int rev = 0;
			if (VerbMeanings::get_special_meaning(&(vs->vm), &rev) == NULL)
				return &(vs->vm);
		}
	return NULL;
}
