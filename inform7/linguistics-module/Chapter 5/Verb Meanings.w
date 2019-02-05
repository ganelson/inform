[VerbMeanings::] Verb Meanings.

To abstract the meaning of a verb.

@h Abstracting meaning.
Recall that each verb can have multiple forms: for example, "to go"
might occur in three forms -- "go" alone, "go to", or "go from", which
are distinguished in English by the use of prepositions such as "to" and
"from". Each of these three verb forms has its own meaning.

However, we can also use indirection to tie one meaning to another. This is
used, for example, to specify the meaning of "A is liking B". We regard
this as "to be" plus copular preposition "liking"; or sometimes the verb
is invisible, as in "someone liking B", which implicitly means "someone
who is liking B". The meaning of "to be" plus "liking" is set by
indirection so that it is always the same as "likes". Similarly, the
meaning of "liked by" is set to be the same as "likes", but reversed
(in that its subject and object must be switched). This ensures that
if the meaning of "likes" changes, its associated usages "is liking"
and "is liked by" automatically change with it.

@ The "meaning" is what state or change a verb describes. In Inform, some
verbs used in assertion sentences have special meanings, instructing the
compiler to do something: for example,

>> To disavow is a verb.

But most sentences set the state of some relation:

>> The bag is on the table.

Our abstraction stays close to that. We're going to assume that most
verbs have a regular meaning which can be represented in a piece of
data (of type |VERB_MEANING_TYPE|, which for Inform 7 means a binary
predicate), while a few have special meanings which can only be handled
ad-hoc by a function. Here's the type for such a function:

=
typedef int (*special_meaning_fn)(int, parse_node *, wording *);

@ The first parameter is the task to be performed on the verb node pointed
to by the second. The task number must belong to the following enumeration,
and the only task used by the Linguistics module is |ACCEPT_SMFT|. This should
look at the array of wordings and either accept this as a valid usage, build
a subtree from the verb node, and return |TRUE|, or else return |FALSE| to
say that the usage is invalid: see Verb Phrases for more.

@e ACCEPT_SMFT from 0

=
typedef struct verb_meaning {
	int reversed;
	VERB_MEANING_TYPE *regular_meaning; /* in I7, this will be a binary predicate */
	int (*special_meaning)(int, parse_node *, wording *); /* (for tangling reasons, can't use typedef here) */
	struct verb_identity *take_meaning_from; /* "to like", in the example above */
	struct parse_node *where_assigned; /* at which sentence this is assigned to a form */
} verb_meaning;

@ Here's how the indirection trick is done: if |vm| takes meaning from,
say, "to like", then we replace it with the meaning of "likes" plus no
preposition

=
verb_meaning *VerbMeanings::indirect_meaning(verb_meaning *vm) {
	if ((vm) && (vm->take_meaning_from)) {
		return Verbs::regular_meaning(vm->take_meaning_from, NULL, NULL);
	}
	return vm;
}

@ All VMs begin as meaningless, which indicates (e.g.) that no meaning
has been specified.

=
verb_meaning VerbMeanings::meaninglessness(void) {
	verb_meaning vm;
	vm.regular_meaning = NULL;
	vm.special_meaning = NULL;
	vm.reversed = FALSE;
	vm.take_meaning_from = NULL;
	vm.where_assigned = current_sentence;
	return vm;
}

int VerbMeanings::is_meaningless(verb_meaning *vm) {
	vm = VerbMeanings::indirect_meaning(vm);
	if (vm == NULL) return TRUE;
	if ((vm->regular_meaning == NULL) && (vm->special_meaning == NULL)) return TRUE;
	return FALSE;
}

verb_meaning VerbMeanings::new(VERB_MEANING_TYPE *rel, special_meaning_fn soa) {
	verb_meaning vm = VerbMeanings::meaninglessness();
	vm.regular_meaning = rel;
	vm.special_meaning = soa;
	return vm;
}

verb_meaning VerbMeanings::special(special_meaning_fn soa) {
	verb_meaning vm = VerbMeanings::meaninglessness();
	vm.special_meaning = soa;
	return vm;
}

verb_meaning VerbMeanings::new_indirection(verb_identity *from, int reversed) {
	verb_meaning vm = VerbMeanings::meaninglessness();
	vm.reversed = reversed;
	vm.take_meaning_from = from;
	return vm;
}

VERB_MEANING_TYPE *VerbMeanings::get_relational_meaning(verb_meaning *vm) {
	if (vm == NULL) return NULL;
	int rev = vm->reversed;
	vm = VerbMeanings::indirect_meaning(vm);
	if (vm == NULL) return NULL;
	if (VerbMeanings::is_meaningless(vm)) return NULL;
	VERB_MEANING_TYPE *rel = vm->regular_meaning;
	if (rel == NULL) return NULL;
	if (vm->reversed) rev = (rev)?FALSE:TRUE;
	if (rev) rel = VERB_MEANING_REVERSAL(rel);
	return rel;
}

special_meaning_fn VerbMeanings::get_special_meaning(verb_meaning *vm, int *rev) {
	if (vm == NULL) return NULL;
	*rev = vm->reversed;
	vm = VerbMeanings::indirect_meaning(vm);
	if (vm == NULL) return NULL;
	if (vm->reversed) *rev = (*rev)?FALSE:TRUE;
	return vm->special_meaning;
}

void VerbMeanings::add_special(verb_meaning *vm, special_meaning_fn spec) {
	if (vm) vm->special_meaning = spec;
	else internal_error("assigned special to null meaning");
}

parse_node *VerbMeanings::get_where_assigned(verb_meaning *vm) {
	if (vm) return vm->where_assigned;
	return NULL;
}

void VerbMeanings::set_where_assigned(verb_meaning *vm, parse_node *pn) {
	if (vm) vm->where_assigned = pn;
	else internal_error("assigned location to null meaning");
}

void VerbMeanings::log(OUTPUT_STREAM, void *vvm) {
	verb_meaning *vm = (verb_meaning *) vvm;
	if (vm == NULL) { WRITE("<none>"); return; }
	if (vm->reversed) WRITE("reversed-");
	if (vm->take_meaning_from) WRITE("<$w>=", vm->take_meaning_from);
	if (VerbMeanings::get_relational_meaning(vm)) {
		#ifdef CORE_MODULE
		WRITE("(%S)", VerbMeanings::get_relational_meaning(vm)->debugging_log_name);
		#else
		WRITE("(relation)");
		#endif
	}
	if (vm->special_meaning) {
		if (VerbMeanings::get_relational_meaning(vm)) WRITE("/");
		WRITE("(special)");
	}
	if ((VerbMeanings::get_relational_meaning(vm) == NULL) && (vm->special_meaning == NULL))
		WRITE("(meaningless)");
}
