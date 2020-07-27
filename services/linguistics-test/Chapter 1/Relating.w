[Relating::] Relating.

Providing a sense of meaning for relationships.

@ This test tool uses the //linguistics// module, and it needs to have some
concept of what relationships are -- that is, of what might be meant by
"X sees Y" or "X is on top of Y".

Inform uses a class called |binary_predicate| for this, but we will use a
class simply called |rel|.

@e rel_CLASS
@d VERB_MEANING_LINGUISTICS_TYPE struct rel

@ //linguistics// also needs us to make annotation functions for one special
annotation it uses. (It can't do this itself without knowing the type.) But
we don't need to create the annotation or give it permissions.

= (early code)
DECLARE_ANNOTATION_FUNCTIONS(relationship, rel)

@ =
DECLARE_CLASS(rel)
MAKE_ANNOTATION_FUNCTIONS(relationship, rel)

@ There isn't much to this, since all we want to be able to do is to
print out a name.

=
typedef struct rel {
	struct text_stream *debugging_log_name;
	struct rel *reversed;
	CLASS_DEFINITION
} rel;

@ //linguistics// requires that whatever this is, it has to be "reversible".
(This transposes the two terms. The reversal of "X sees Y" is "X is seen by Y".)

=
@d VERB_MEANING_REVERSAL_LINGUISTICS_CALLBACK Relating::reverse_rel

=
rel *Relating::reverse_rel(rel *R) {
	return R->reversed;
}

@ //linguistics// also wants to know the identities of two special meanings,
roughly those of the verbs "to be" and "to have". So it requires us to define
these two macros:

@d VERB_MEANING_EQUALITY R_equality
@d VERB_MEANING_POSSESSION R_possession

= (early code)
rel *R_equality = NULL;
rel *R_possession = NULL;

@ And so we will create rels in pairs, and the first two (pairs) to be created
must be for equality and possession:

=
rel *Relating::new(wording W) {
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%W", W);
	rel *R = CREATE(rel), *RR = CREATE(rel);
	R->debugging_log_name = Str::duplicate(name);
	WRITE_TO(name, "-reversed");
	RR->debugging_log_name = Str::duplicate(name);
	R->reversed = RR; RR->reversed = R;
	if (R_equality == NULL) R_equality = R;
	else if (R_possession == NULL) R_possession = R;
	DISCARD_TEXT(name)
	return R;
}

@ This function finds a rel by name.

=
rel *Relating::find(wording W) {
	TEMPORARY_TEXT(name)
	WRITE_TO(name, "%W", W);
	rel *T;
	LOOP_OVER(T, rel)
		if (Str::eq_insensitive(T->debugging_log_name, name))
			break;
	DISCARD_TEXT(name)
	return T;
}
