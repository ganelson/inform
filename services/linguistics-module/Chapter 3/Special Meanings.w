[SpecialMeanings::] Special Meanings.

To abstract non-standard, perhaps non-SVO, meanings of a verb.

@h Special meaning functions.
Regular meanings of verbs are represented by |VERB_MEANING_LINGUISTICS_TYPE|
pointers -- see //Verb Meanings//. In Inform, those are binary predicates.
They always take two terms.

However, Inform sometimes wants sentences which are written in non-standard
ways, with anything from one to three terms, and which don't correspond to
any of the relations. (For example, "Include Locksmith by Emily Short".)

These are represented by functions to perform the necessary business; the
type |special_meaning_fn| gives the type of such a function.

=
typedef int (*special_meaning_fn)(int, parse_node *, wording *);

@ This is a convenient generic special-meaning function; it simply accumulates
non-empty SPs and OPs as unparsed noun phrases and accepts them.

The first parameter is the task to be performed on the verb node pointed
to by the second. The task number must belong to the |*_SMFT| enumeration,
and the only task used by the Linguistics module is |ACCEPT_SMFT|. This should
look at the array of wordings and either accept this as a valid usage, build
a subtree from the verb node, and return |TRUE|, or else return |FALSE| to
say that the usage is invalid: see Verb Phrases for more.

The user is then free to define further SMF tasks, and Inform does so.

@e ACCEPT_SMFT from 0

=
int SpecialMeanings::generic_smf(int task, parse_node *V, wording *NPs) {
	switch (task) {
		case ACCEPT_SMFT: {
			parse_node *A = V;
			for (int i=0; i<3; i++) {
				wording W = (NPs)?(NPs[i]):EMPTY_WORDING;
				if (Wordings::nonempty(W)) {
					<np-unparsed>(W);
					parse_node *p = <<rp>>;
					A->next = p; A = p;
				}
			}
			return TRUE;
		}
	}
	return FALSE;
}

@h Special meaning holders.
Although a SM is basically encapsulated by a function, it's convenient to
have some metadata with it too:

@ =
typedef struct special_meaning_holder {
	int (*sm_func)(int, parse_node *, wording *); /* (compiler doesn't like typedef here) */
	struct text_stream *sm_name;
	int metadata_N;
	CLASS_DEFINITION
} special_meaning_holder;

@ =
special_meaning_holder *SpecialMeanings::declare(special_meaning_fn func,
	text_stream *name, int p) {
	special_meaning_holder *smh = CREATE(special_meaning_holder);
	if (func == NULL) func = SpecialMeanings::generic_smf;
	smh->sm_func = func;
	smh->sm_name = Str::duplicate(name);
	smh->metadata_N = p;
	return smh;
}

@ SMHs can be found by name:

=
verb_meaning SpecialMeanings::find(wchar_t *name) {
	special_meaning_holder *smh;
	LOOP_OVER(smh, special_meaning_holder)
		if (Str::eq_wide_string(smh->sm_name, name))
			return VerbMeanings::special(smh);
	return VerbMeanings::meaninglessness();
}
special_meaning_holder *SpecialMeanings::find_from_wording(wording W) {
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%W", W);
	special_meaning_holder *smh;
	LOOP_OVER(smh, special_meaning_holder)
		if (Str::eq_insensitive(smh->sm_name, name))
			break;
	DISCARD_TEXT(name)
	return smh;
}

@ Metadata access:

=
int SpecialMeanings::get_metadata_N(special_meaning_holder *smh) {
	if (smh == NULL) return 0;
	return smh->metadata_N;
}

text_stream *SpecialMeanings::get_name(special_meaning_holder *smh) {
	if (smh == NULL) return NULL;
	return smh->sm_name;
}

int SpecialMeanings::is(special_meaning_holder *smh, special_meaning_fn func) {
	if (smh == NULL) return FALSE;
	if (smh->sm_func == func) return TRUE;
	return FALSE;
}

@ Calling:

=
int SpecialMeanings::call(special_meaning_holder *smh, int task, parse_node *V,
	wording *NPs) {
	return (*(smh->sm_func))(task, V, NPs);
}
