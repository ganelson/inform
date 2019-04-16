[UseNouns::] Using Nametags.

Nametags provide for a more contextual parsing of nouns, allowing
them to be given in an inexact verbal form.

@h Identifiers.
Since I6 identifiers compiled by Inform are usually based on the names of
the things they represent -- a typical example would be |I45_silver_bars| --
it's convenient to associate them with nametags.

=
text_stream *UseNouns::identifier(noun *t) {
	if (t == NULL) return I"nothing";
	return t->nt_I6_identifier;
}

inter_name *UseNouns::iname(noun *t) {
	if (t == NULL) return NULL;
	if (t->nt_iname == NULL) { LOG("So %W / %S is stuck\n", Nouns::get_name(t, FALSE), t->nt_I6_identifier); internal_error("stuck"); }
	return t->nt_iname;
}

int UseNouns::iname_set(noun *t) {
	if (t == NULL) return FALSE;
	if (t->nt_iname == NULL) return FALSE;
	return TRUE;
}

void UseNouns::noun_compose_identifier(package_request *R, noun *t, int N) {
	if (t->nt_iname == NULL) {
		wording W = Nouns::get_name(t, FALSE);
		t->nt_iname = Hierarchy::make_iname_with_memo(INSTANCE_HL, R, W);
	}
}

void UseNouns::noun_impose_identifier(noun *t, inter_name *iname) {
	if (t->nt_iname == NULL) t->nt_iname = iname;
}

void UseNouns::noun_set_I6_representation(noun *t, text_stream *new) {
	if (t->nt_iname == NULL) internal_error("no instance iname yet");
	Str::clear(t->nt_I6_identifier);
	Str::copy(t->nt_I6_identifier, new);
	if (Str::get_first_char(t->nt_I6_identifier) == '"')
		Str::delete_first_character(t->nt_I6_identifier);
	if (Str::get_last_char(t->nt_I6_identifier) == '"')
		Str::delete_last_character(t->nt_I6_identifier);
	InterNames::translate(t->nt_iname, t->nt_I6_identifier);
	Inter::Symbols::clear_flag(InterNames::to_symbol(t->nt_iname), MAKE_NAME_UNIQUE);
}

@ The identifiers are created all at once, but the process is complicated by
the fact that the source text is allowed to override our choices. For
instance, the Standard Rules want the player-character object to be called
|selfobj| in I6 source text, not something like |I32_yourself|.

=
void UseNouns::name_all(void) {
	kind *K;
	LOOP_OVER_BASE_KINDS(K)
		Kinds::RunTime::assure_iname_exists(K);
	ParseTree::traverse(UseNouns::visit_to_name);
}

void UseNouns::visit_to_name(parse_node *p) {
	if ((ParseTree::get_type(p) == SENTENCE_NT) && (p->down) &&
		(ParseTree::int_annotation(p->down, category_of_I6_translation_ANNOT) == NOUN_I6TR))
		@<Act on a request to translate a noun in a specific way@>;
}

@<Act on a request to translate a noun in a specific way@> =
	wording W = Wordings::trim_last_word(ParseTree::get_text(p->down->next));
	parse_node *res = ExParser::parse_excerpt(NOUN_MC, W);
	if (res) {
		noun *nt = Nouns::disambiguate(res, MAX_NOUN_PRIORITY);
		if (nt) {
			TEMPORARY_TEXT(i6r);
			WRITE_TO(i6r, "%N", Wordings::first_wn(ParseTree::get_text(p->down->next->next)));
			UseNouns::noun_set_I6_representation(nt, i6r);
			DISCARD_TEXT(i6r);
		}
	} else {
		Problems::Issue::sentence_problem(_p_(PM_BadObjectTranslation),
			"there is no such object or kind of object",
			"so its name will never be translated into an I6 Object or Class identifier "
			"in any event.");
	}

@h Translation.

@d TRANS_KIND 1
@d TRANS_INSTANCE 2

@ This is for translation of nouns into different natural languages,
and is a somewhat provisional feature for now.

>> Thing translates into French as chose (f).

=
<translates-into-nl-sentence-subject> ::=
	<k-kind> |						==> TRANS_KIND; *XP = RP[1]
	<instance>						==> TRANS_INSTANCE; *XP = RP[1]

@ =
void UseNouns::nl_translates(parse_node *pn) {
	/* the object */
	natural_language *nl = ParseTree::get_defn_language(pn->next->next);
	int g = ParseTree::int_annotation(pn->next->next, gender_reference_ANNOT);
	if (nl == NULL) internal_error("No such NL");
	if (nl == English_language) {
		Problems::Issue::sentence_problem(_p_(PM_CantTranslateIntoEnglish),
			"you can't translate into English",
			"only out of it.");
		return;
	}

	if ((<translates-into-nl-sentence-subject>(ParseTree::get_text(pn->next))) == FALSE) {
		Problems::Issue::sentence_problem(_p_(PM_CantTranslateValue),
			"this isn't something which can be translated",
			"that is, it isn't a kind.");
		return;
	}

	switch (<<r>>) {
		case TRANS_INSTANCE: {
			instance *I = <<rp>>;
			noun *t = Instances::get_noun(I);
			if (t == NULL) internal_error("stuck on instance name");
			Nouns::add_to_noun_and_reg(t, ParseTree::get_text(pn->next->next), nl, g,
				1, REGISTER_SINGULAR_NTOPT);
			break;
		}
		case TRANS_KIND: {
			kind *K = <<rp>>;
			kind_constructor *KC = Kinds::get_construct(K);
			if (KC == NULL) internal_error("stuck on kind name");
			noun *t = Kinds::Constructors::get_noun(KC);
			if (t == NULL) internal_error("further stuck on kind name");
			Nouns::add_to_noun_and_reg(t, ParseTree::get_text(pn->next->next), nl, g,
				1, REGISTER_SINGULAR_NTOPT + REGISTER_PLURAL_NTOPT);
			break;
		}
		default:
			internal_error("bad translation category");
	}
}
