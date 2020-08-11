[PL::Naming::] The Naming Thicket.

Inform has a thicket of properties to do with names: not just the
name itself, but whether it is a plural, a proper name, and so on. Here we
look after these properties, and give them their initial states.

@ A few properties are treated specially by Inform, and need to have their
references stored in global variables. They are set as they are created,
during the parsing of assertions in the Standard Rules.

= (early code)
property *P_proper_named = NULL; /* an either/or property for names */
property *P_plural_named = NULL; /* an either/or property for names */
property *P_neuter = NULL; /* an either/or property for names */
property *P_female = NULL; /* an either/or property for names */
property *P_article = NULL; /* a value property for names */
property *P_privately_named = NULL;
property *P_printed_name = NULL;
property *P_printed_plural_name = NULL;
property *P_cap_short_name = NULL;
property *P_adaptive_text_viewpoint = NULL;

@ We need to accumulate routines used for naming properties in a separate
stream, though there aren't very many of them.

=
typedef struct short_name_notice {
	struct inter_name *routine_iname;
	struct inter_name *snn_iname;
	struct instance *namee;
	struct inference_subject *after_subject;
	int capped;
	CLASS_DEFINITION
} short_name_notice;

@h Plugin startup.

=
void PL::Naming::start(void) {
	PLUGIN_REGISTER(PLUGIN_NEW_PROPERTY_NOTIFY, PL::Naming::naming_new_property_notify);
	PLUGIN_REGISTER(PLUGIN_COMPLETE_MODEL, PL::Naming::naming_complete_model);
}

@h Recognising significant properties.
These are property names to do with naming which Inform provides special
support for; it recognises the English names when they are defined by the
Standard Rules. (So there is no need to translate this to other languages.)

=
<notable-naming-properties> ::=
	indefinite article |
	plural-named |
	proper-named |
	printed name |
	printed plural name |
	publicly-named |
	privately-named |
	adaptive text viewpoint |
	neuter |
	female

@ =
int PL::Naming::naming_new_property_notify(property *prn) {
	if (<notable-naming-properties>(prn->name)) {
		switch (<<r>>) {
			case 0: P_article = prn; break;
			case 1: P_plural_named = prn; break;
			case 2: P_proper_named = prn; break;
			case 3: P_printed_name = prn; break;
			case 4: P_printed_plural_name = prn; break;
			case 5: Properties::exclude_from_index(prn); break;
			case 6: P_privately_named = prn; /* this is the negation of "publicly named" */
				Properties::exclude_from_index(prn); break;
			case 7: P_adaptive_text_viewpoint = prn;
				Properties::exclude_from_index(prn); break;
			case 8: P_neuter = prn; break;
			case 9: P_female = prn; break;
		}
	}
	return FALSE;
}

@h Proper named, plural named, definite article.
Only objects can be proper-named or plural-named, so we do nothing if told by
the Creator to make something else have a proper name.

=
void PL::Naming::now_has_proper_name(inference_subject *infs) {
	instance *wto = InferenceSubjects::as_object_instance(infs);
	if (wto) PL::Naming::object_now_has_proper_name(wto);
}

void PL::Naming::object_now_has_proper_name(instance *I) {
	if (P_proper_named)
		Properties::EitherOr::assert(P_proper_named,
			Instances::as_subject(I), TRUE, LIKELY_CE);
}

void PL::Naming::object_now_has_plural_name(instance *I) {
	if (P_plural_named)
		Properties::EitherOr::assert(P_plural_named,
			Instances::as_subject(I), TRUE, LIKELY_CE);
}

@ It's a rather ugly fact of Inform 6 life that we indicate something is
unique, yet not proper-named, by giving it the indefinite article "the";
thus the following routine is called for creations of directions ("the north")
and where "called..." absolutely requires the definite article ("There is
a room called the Counting House").

We cache the text literal "the" rather than create it over and over.

=
parse_node *text_of_word_the = NULL;
void PL::Naming::object_takes_definite_article(inference_subject *subj) {
	if (text_of_word_the == NULL)
		text_of_word_the = Rvalues::from_wording(Feeds::feed_C_string(L"\"the\""));
	Properties::Valued::assert(P_article, subj, text_of_word_the, LIKELY_CE);
}

@h Transferring name details.
This is needed when assemblies name one new creation after another; for instance,
"Cleopatra's nose" must be proper-named because "Cleopatra" is.

=
void PL::Naming::transfer_details(inference_subject *from, inference_subject *to) {
	instance *wto = InferenceSubjects::as_object_instance(to);
	if (wto) {
		if (World::Inferences::get_EO_state(from, P_proper_named) > 0)
			PL::Naming::now_has_proper_name(to);
		parse_node *art = World::Inferences::get_prop_state(from, P_article);
		if (art) Properties::Valued::assert(P_article, to, art, LIKELY_CE);
	}
}

instance *PL::Naming::object_this_is_named_after(instance *I) {
	return InferenceSubjects::as_object_instance(
		Assertions::Assemblies::what_this_is_named_after(
			Instances::as_subject(I)));
}

@h Private naming.
"Privately named" is a property which affects the parsing of commands; all
we do here is provide its state on request.

=
int PL::Naming::object_is_privately_named(instance *I) {
	int certainty = World::Inferences::get_EO_state(Instances::as_subject(I), P_privately_named);
	if (certainty > 0) return TRUE;
	if (certainty < 0) return FALSE;
	return NOT_APPLICABLE;
}

@h Model completion.
Quite a lot of work is entailed in producing all of the necessary I6 properties
to fill in the naming details for objects, so here goes.

=
int PL::Naming::naming_complete_model(int stage) {
	if (stage == 3) @<Add naming properties implicit from context@>;
	return FALSE;
}

@ Stage 3 of world model completion is adding properties not inferred directly
from sentences, and this can include I6 properties with no I7 analogue.

@<Add naming properties implicit from context@> =
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		if (Kinds::Compare::lt(K, K_object)) {
			wording W = Kinds::Behaviour::get_name_in_play(K, FALSE, Projects::get_language_of_play(Task::project()));
			wording PW = Kinds::Behaviour::get_name_in_play(K, TRUE, Projects::get_language_of_play(Task::project()));
			inference_subject *subj = Kinds::Knowledge::as_subject(K);
			@<Issue problem message if the name contains a comma@>;
			@<Assert the printed plural name property for kinds other than thing or kinds of room@>;
		}
	instance *I;
	LOOP_OVER_OBJECT_INSTANCES(I) {
		wording W = Instances::get_name_in_play(I, FALSE);
		inference_subject *subj = Instances::as_subject(I);
		int this_is_a_room = PL::Spatial::object_is_a_room(I);
		int this_has_a_printed_name = PL::Naming::look_for_printed_name(subj);
		int this_is_named_for_something_with_a_printed_name = FALSE;
		if (PL::Naming::object_this_is_named_after(I))
			if (PL::Naming::look_for_printed_name(
				Instances::as_subject(PL::Naming::object_this_is_named_after(I))))
				this_is_named_for_something_with_a_printed_name = TRUE;
		@<Issue problem message if the name contains a comma@>;
		if (this_has_a_printed_name == FALSE) @<Assert the printed name property@>;
		if (Projects::get_language_of_play(Task::project()) != DefaultLanguage::get(NULL))
			@<Assert male, female, neuter adjectives from grammatical gender@>;
	}

@ This was added in beta-testing when it turned out that mistakes in coding
sometimes created unlikely objects: for example, "In the Building is a
person called Wallace, Gromit Too." creates a single object. Its name contains
a comma, and that's caught here:

@<Issue problem message if the name contains a comma@> =
	LOOP_THROUGH_WORDING(j, W) {
		if (Lexer::word(j) == COMMA_V) {
			StandardProblems::subject_creation_problem(_p_(PM_CommaInName),
				subj,
				"has a comma in its name",
				"which is forbidden. Perhaps you used a comma in "
				"punctuating a sentence? Inform generally doesn't "
				"like this because it reserves commas for specific "
				"purposes such as dividing rules or 'if' phrases.");
			break;
		}
		if (Vocabulary::test_flags(j, TEXT_MC+TEXTWITHSUBS_MC)) {
			StandardProblems::subject_creation_problem(_p_(BelievedImpossible),
				subj,
				"has some double-quoted text in its name",
				"which is forbidden. Perhaps something odd happened "
				"to do with punctuation between sentences? Or perhaps "
				"you really do need the item to be described with "
				"literal quotation marks on screen when the player "
				"sees it. If so, try giving it a printed name: perhaps "
				"'The printed name of Moby Dick is \"'Moby Dick'\".'");
			break;
		}
	}

@<Assert the printed name property@> =
	if (this_has_a_printed_name == FALSE) {
		wording W = Instances::get_name_in_play(I, FALSE);
		if (Wordings::empty(W)) {
			kind *k = Instances::to_kind(I);
			W = Kinds::Behaviour::get_name_in_play(k, FALSE, Projects::get_language_of_play(Task::project()));
		}
		int begins_with_lower_case = FALSE;
		if (Wordings::nonempty(W)) {
			wchar_t *p = Lexer::word_raw_text(Wordings::first_wn(W));
			if (Characters::islower(p[0])) begins_with_lower_case = TRUE;
		}
		@<Assert the I6 short-name property@>;
		@<Assert the I6 cap-short-name property@>;
	}

@ The I7 property "printed name" translates to I6 |short_name|.

@<Assert the I6 short-name property@> =
	inter_name *faux = NULL;
	text_stream *PROP = Str::new();

	if (this_is_named_for_something_with_a_printed_name)
		@<Compose the I6 short-name as a routine dynamically using its owner's short-name@>
	else @<Compose the I6 short-name as a piece of text@>;

	if (faux)
		Properties::Valued::assert(P_printed_name, subj,
			Rvalues::from_iname(faux), CERTAIN_CE);
	else
		Properties::Valued::assert(P_printed_name, subj,
			Rvalues::from_unescaped_wording(Feeds::feed_text(PROP)), CERTAIN_CE);

@ The I6 |cap_short_name| has no corresponding property in I7. Note that it's
only needed if the object is named after something else which might need it,
or if it's a proper-named object which begins with a lower-case letter. (This
actually means it's rarely needed.)

@<Assert the I6 cap-short-name property@> =
	inter_name *faux = NULL;
	int set_csn = TRUE;
	text_stream *PROP = Str::new();
	if (this_is_named_for_something_with_a_printed_name) {
		@<Compose the I6 cap-short-name as a routine dynamically using its owner's cap-short-name@>
	} else {
		if ((World::Inferences::get_EO_state(subj, P_proper_named) > 0)
			&& (begins_with_lower_case))
			@<Compose the I6 cap-short-name as a piece of text@>
		else set_csn = FALSE;
	}
	if (set_csn) {
		if (P_cap_short_name == NULL) {
			inter_name *property_iname = Hierarchy::find(CAPSHORTNAME_HL);
			P_cap_short_name = Properties::Valued::new_nameless_using(
				K_text, Kinds::Behaviour::package(K_object), property_iname);
			Hierarchy::make_available(Emit::tree(), property_iname);
		}
		if (faux)
			Properties::Valued::assert(P_cap_short_name, subj,
				Rvalues::from_iname(faux), CERTAIN_CE);
		else
			Properties::Valued::assert(P_cap_short_name, subj,
				Rvalues::from_unescaped_wording(Feeds::feed_text(PROP)), CERTAIN_CE);
	}

@ Note that it is important here to preserve the cases of the original
source text description, so that "Mr Beebe" will not be flattened to "mr
beebe"; but that we take care to reduce the case of "Your nose" (etc.)
to "your nose", unless it occurs in the name of a room, like "Your Bedroom".

@<Compose the I6 short-name as a piece of text@> =
	PL::Naming::compose_words_to_I6_naming_text(PROP, W, FALSE, (this_is_a_room)?FALSE:TRUE);

@<Compose the I6 cap-short-name as a piece of text@> =
	PL::Naming::compose_words_to_I6_naming_text(PROP, W, TRUE, (this_is_a_room)?FALSE:TRUE);

@ The following need to be routines so that the printed name will dynamically
change if the owner changes its own printed name during play: e.g. if the
"masked maiden" changes to "Cleopatra", then "masked maiden's nose"
must become "Cleopatra's nose", or at least several bug-reporters thought
so. These routines allow that to happen.

@<Compose the I6 short-name as a routine dynamically using its owner's short-name@> =
	short_name_notice *notice = CREATE(short_name_notice);
	notice->routine_iname = Hierarchy::make_iname_in(SHORT_NAME_FN_HL, Instances::package(I));
	notice->namee = I;
	notice->after_subject = subj;
	notice->capped = FALSE;
	notice->snn_iname = Hierarchy::make_iname_in(SHORT_NAME_PROPERTY_FN_HL, Instances::package(I));
	faux = notice->snn_iname;

@<Compose the I6 cap-short-name as a routine dynamically using its owner's cap-short-name@> =
	short_name_notice *notice = CREATE(short_name_notice);
	notice->routine_iname = Hierarchy::make_iname_in(SHORT_NAME_FN_HL, Instances::package(I));
	notice->namee = I;
	notice->after_subject = subj;
	notice->capped = TRUE;
	notice->snn_iname = Hierarchy::make_iname_in(SHORT_NAME_PROPERTY_FN_HL, Instances::package(I));
	faux = notice->snn_iname;

@ Lastly, then. We don't give this to kinds of room, because it's never necessary
to pluralise them at run-time in practice, so it would carry an unnecessary cost
in Z-machine memory. We don't give it to "thing" because this would be too
vague, and might cause Inform at run-time to spuriously group unrelated things
together in lists.

@<Assert the printed plural name property for kinds other than thing or kinds of room@> =
	if ((Kinds::Behaviour::is_object_of_kind(K, K_room) == FALSE) &&
		(Kinds::Compare::eq(K, K_thing) == FALSE) &&
		(World::Inferences::get_prop_state_without_inheritance(
			subj, P_printed_plural_name, NULL) == NULL)) {
		if (Wordings::nonempty(PW)) {
			text_stream *PROP = Str::new();
			PL::Naming::compose_words_to_I6_naming_text(PROP, PW, FALSE, TRUE);
			Properties::Valued::assert(P_printed_plural_name, subj,
				Rvalues::from_unescaped_wording(Feeds::feed_text(PROP)), CERTAIN_CE);
		}
	}

@ The following isn't done in English.

@<Assert male, female, neuter adjectives from grammatical gender@> =
	parse_node *spec = World::Inferences::get_prop_state(subj, P_grammatical_gender);
	if (spec) {
		int g = Annotations::read_int(spec, constant_enumeration_ANNOT);
		switch (g) {
			case NEUTER_GENDER:
				if (World::Permissions::grant(subj, P_neuter, TRUE))
					Properties::EitherOr::assert(P_neuter, subj, TRUE, LIKELY_CE);
				break;
			case MASCULINE_GENDER:
				if (World::Permissions::grant(subj, P_female, TRUE))
					Properties::EitherOr::assert(P_female, subj, FALSE, LIKELY_CE);
				break;
			case FEMININE_GENDER:
				if (World::Permissions::grant(subj, P_female, TRUE))
					Properties::EitherOr::assert(P_female, subj, TRUE, LIKELY_CE);
				break;
		}
	}

@ We needed the following utility above. Note that only printed names
inferred from sentences count here -- not printed names added in model
completion. (This is important because we might be working on these objects
in any order, and might have completed X but not Y where either X is named
after Y or vice versa.)

=
int PL::Naming::look_for_printed_name(inference_subject *subj) {
	inference_subject *check;
	for (check = subj; check; check = InferenceSubjects::narrowest_broader_subject(check)) {
		inference *inf;
		POSITIVE_KNOWLEDGE_LOOP(inf, check, PROPERTY_INF)
			if (World::Inferences::added_in_construction(inf) == FALSE)
				if (World::Inferences::get_property(inf) == P_printed_name)
					return TRUE;
	}
	return FALSE;
}

@ And here we transcribe a word range to text suitable for an I6 property,
capitalising and fixing "your" as needed.

=
void PL::Naming::compose_words_to_I6_naming_text(OUTPUT_STREAM, wording W, int cap, int your_flag) {
	WRITE("\"");
	if (Wordings::nonempty(W)) {
		LOOP_THROUGH_WORDING(j, W) {
			int your_here = <possessive-second-person>(Wordings::one_word(j));
			wchar_t *p = Lexer::word_raw_text(j);
			if (cap) {
				if ((j==Wordings::first_wn(W)) && (your_here) && (your_flag)) {
					PUT(Characters::toupper(p[0]));
					CompiledText::from_wide_string(OUT, p+1, CT_RAW);
				} else if (j==Wordings::first_wn(W)) {
					CompiledText::from_wide_string(OUT, p, CT_RAW + CT_CAPITALISE);
				} else {
					CompiledText::from_wide_string(OUT, p, CT_RAW);
				}
			} else {
				if ((j==Wordings::first_wn(W)) && (your_here) && (your_flag)) {
					PUT(Characters::tolower(p[0]));
					CompiledText::from_wide_string(OUT, p+1, CT_RAW);
				} else CompiledText::from_wide_string(OUT, p, CT_RAW);
			}
			if (j<Wordings::last_wn(W)) WRITE(" ");
		}
	} else {
		if (cap) WRITE("Object"); else WRITE("object");
	}
	WRITE("\"");
}

@ Finally:

=
void PL::Naming::compile_small_names(void) {
	short_name_notice *notice;
	LOOP_OVER(notice, short_name_notice) {
		instance *owner = PL::Naming::object_this_is_named_after(notice->namee);
		packaging_state save = Routines::begin(notice->routine_iname);
		wording NA = Assertions::Assemblies::get_named_after_text(notice->after_subject);
		if (notice->capped) {
			inter_name *porname = Hierarchy::find(PRINTORRUN_HL);

			Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
			Produce::down(Emit::tree());
				Produce::inv_primitive(Emit::tree(), PROPERTYADDRESS_BIP);
				Produce::down(Emit::tree());
					Produce::val_iname(Emit::tree(), K_value, Instances::iname(owner));
					Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CAPSHORTNAME_HL));
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), porname);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Instances::iname(owner));
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(CAPSHORTNAME_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
				Produce::code(Emit::tree());
				Produce::down(Emit::tree());
					Produce::inv_call_iname(Emit::tree(), porname);
					Produce::down(Emit::tree());
						Produce::val_iname(Emit::tree(), K_value, Instances::iname(owner));
						Produce::val_iname(Emit::tree(), K_value, Hierarchy::find(SHORT_NAME_HL));
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
					Produce::up(Emit::tree());
				Produce::up(Emit::tree());
			Produce::up(Emit::tree());
		} else {
			Produce::inv_primitive(Emit::tree(), PRINTNAME_BIP);
			Produce::down(Emit::tree());
				Produce::val_iname(Emit::tree(), K_value, Instances::iname(owner));
			Produce::up(Emit::tree());
		}
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), I"'s ");
		Produce::up(Emit::tree());
		TEMPORARY_TEXT(SNAMES)
		LOOP_THROUGH_WORDING(j, NA) {
			CompiledText::from_wide_string(SNAMES, Lexer::word_raw_text(j), 0);
			if (j<Wordings::last_wn(NA)) WRITE_TO(SNAMES, " ");
		}
		Produce::inv_primitive(Emit::tree(), PRINT_BIP);
		Produce::down(Emit::tree());
			Produce::val_text(Emit::tree(), SNAMES);
		Produce::up(Emit::tree());
		DISCARD_TEXT(SNAMES)

		Produce::rtrue(Emit::tree());
		Routines::end(save);

		save = Emit::named_array_begin(notice->snn_iname, NULL);
		Emit::array_iname_entry(Hierarchy::find(CONSTANT_PACKED_TEXT_STORAGE_HL));
		Emit::array_iname_entry(notice->routine_iname);
		Emit::array_end(save);
	}
}
void PL::Naming::compile_cap_short_name(void) {
	if (P_cap_short_name == NULL) {
		inter_name *iname = Hierarchy::find(CAPSHORTNAME_HL);
		Emit::named_iname_constant(iname, K_value, Hierarchy::find(SHORT_NAME_HL));
		Hierarchy::make_available(Emit::tree(), iname);
	}
}

@h The adaptive person.
The following is only relevant for the language of play, whose extension will
always be read in. That in turn is expected to contain a declaration like
this one:

>> The adaptive text viewpoint of the French language is second person singular.

The following routine picks up on the result of this declaration. (We cache
this because we need access to it very quickly when parsing text substitutions.)

@d ADAPTIVE_PERSON_LINGUISTICS_CALLBACK PL::Naming::adaptive_person
@d ADAPTIVE_NUMBER_LINGUISTICS_CALLBACK PL::Naming::adaptive_number

=
int PL::Naming::adaptive_person(inform_language *L) {
	int C = PL::Naming::adaptive_combination(L);
	if (C < 0) return -1;
	return C % NO_KNOWN_PERSONS;
}

int PL::Naming::adaptive_number(inform_language *L) {
	int C = PL::Naming::adaptive_combination(L);
	if (C < 0) return -1;
	return C / NO_KNOWN_PERSONS;
}

int PL::Naming::adaptive_combination(inform_language *L) {
	if (L->adaptive_person >= 0) return L->adaptive_person;
	if ((L->adaptive_person == -1) && (P_adaptive_text_viewpoint)) {
		instance *I = L->nl_instance;
		parse_node *val = World::Inferences::get_prop_state(
			Instances::as_subject(I), P_adaptive_text_viewpoint);
		if (Node::is(val, CONSTANT_NT)) {
			instance *V = Node::get_constant_instance(val);
			L->adaptive_person = Instances::get_numerical_value(V)-1;
		}
	}
	return L->adaptive_person;
}
