[JumpLabels::] Jump Labels.

Generating numbered families of identifier names to use as jump labels, and
creating any associated array storage needed.

@ At the risk of angering the ghost of Dijkstra, we compile plenty of |JUMP_BIP|
opcodes in the Inter functions we make, and these require labels to jump to.
Clearly we could just call these |L0|, |L1|, |L2|, ..., |L3475|, ..., but that
would make the Inter code we're generating harder for human eyes to read. So we
will go to a little trouble to give meaningful names.

In particular, labels are generated within "namespaces", which are really just
numbered sets, except that they can also have associated storage,[1] which is
global and persistent:

[1] Labels and storage are not obviously related, but in fact these small pieces
of storage are used in "say" phrases to choose alternative wordings, where the
options correspond to labels to jump to.

=
typedef struct label_namespace {
	struct text_stream *label_prefix;
	int label_counter; /* next free ID number for this label namespace */
	int max_label_counter; /* largest ever value of the label counter */
	int allocate_storage; /* number of words of memory to reserve for each label */
	struct inter_name *label_storage_iname; /* where that storage is */
	int storage_requested;
	int storage_compiled;
	CLASS_DEFINITION
} label_namespace;

@ This function writes the current label identifier within the given namespace.
This takes the form |L_NameNumber|. For instance, |L_Marble17| is the 18th label
in namespace |Marble|.

It is legal for a namespace's name to be the empty text, which generates labels
|L_0|, |L_1|, ...

=
void JumpLabels::write(OUTPUT_STREAM, text_stream *namespace) {
	label_namespace *lns = JumpLabels::obtain_namespace(namespace);
	WRITE("L_%S%d", lns->label_prefix, lns->label_counter);
}

@ The rest of Inform tends not to store pointers to namespaces: instead it
must indicate them by their textual prefixes. This is very slightly inefficient,
but there are very few namespaces in any single function.

However, the namespace |Whatever| is different for different functions -- jump
labels, after all, are private to functions. |JumpLabels::obtain_namespace(I"Whatever")|
will return the namespace for whatever we are currently compiling.

This leads to an interesting nuance, which is that functions which are instantiations
of templates will share a common list. (See //Functions::current_label_namespaces//.)
That means that they share their storage, if they have any. For example, label
storage is used to manage the alternate texts in the following:
= (text as Inform 7)
To judge (V - value):
	say "[V] is [one of]clearly[or]evidently[or]markedly[cycling] just plain [V]."
When play begins:
	judge 21;
	judge "fishslice";
	judge the time of day;
	judge true.
=
Here "to judge" is instantiated four times (for when |V| is a number, when it
is a text, when it is a time of day, and when it is a truth state). The output
here should be:
= (text)
21 is clearly just plain 21.
fishslice is evidently just plain fishslice.
9:00 am is markedly just plain 9:00 am.
true is clearly just plain true.
56 is evidently just plain 56.
=
In other words, the counter used in all four instance functions must be the
same one; if they had all had independent counters, the result would be:
= (text)
21 is clearly just plain 21.
fishslice is clearly just plain fishslice.
9:00 am is clearly just plain 9:00 am.
true is clearly just plain true.
56 is evidently just plain 56.
=
See the test case |InstantiatedLabelStorage|.

@d MAX_NAMESPACE_PREFIX_LENGTH 20 /* when |L_| and a number are added, we are within 31 chars */

=
label_namespace *JumpLabels::obtain_namespace(text_stream *name) {
	linked_list *namespaces = Functions::current_label_namespaces();
	if (namespaces == NULL) internal_error("labels are available only within functions");
	label_namespace *lns;
	LOOP_OVER_LINKED_LIST(lns, label_namespace, namespaces)
		if (Str::eq(name, lns->label_prefix))
			return lns;

	if (Str::len(name) > MAX_NAMESPACE_PREFIX_LENGTH) {
		StandardProblems::sentence_problem(Task::syntax_tree(),
			_p_(PM_LabelNamespaceTooLong),
			"a label namespace prefix is too long",
			"and should be shortened to a few alphabetic characters.");
		Str::truncate(name, MAX_NAMESPACE_PREFIX_LENGTH);
	}
	lns = CREATE(label_namespace);
	lns->label_prefix = Str::duplicate(name);
	lns->label_storage_iname =
		Enclosures::new_iname(LABEL_STORAGES_HAP, LABEL_ASSOCIATED_STORAGE_HL);
	lns->label_counter = 0;
	lns->max_label_counter = 0;
	lns->allocate_storage = 0;
	lns->storage_compiled = FALSE;
	lns->storage_requested = FALSE;
	ADD_TO_LINKED_LIST(lns, label_namespace, namespaces);
	return lns;
}

@ Though multiple instantiations of the same imperative definition may share
a namespace list, we need to reset all the counters each time it is instantiated:

=
void JumpLabels::restart_counters(id_body *idb) {
	label_namespace *lns;
	LOOP_OVER_LINKED_LIST(lns, label_namespace, idb->compilation_data.label_namespaces)
		lns->label_counter = 0;
}

@ An individual counter can be read, advanced or retreated with:

=
int JumpLabels::read_counter(text_stream *namespace, int advance_by) {
	label_namespace *lns = JumpLabels::obtain_namespace(namespace);
	int c = lns->label_counter;
	lns->label_counter += advance_by;
	if (lns->max_label_counter < lns->label_counter)
		lns->max_label_counter = lns->label_counter;
	if (lns->label_counter < 0) internal_error("label counter negative");
	return c;
}

@ So, then, we can mark a namespace as requiring 1 or more words of storage.
This will accumulate into an array, as follows.

=
void JumpLabels::allocate_storage(text_stream *namespace, int multiplier) {
	label_namespace *lns = JumpLabels::obtain_namespace(namespace);
	if (multiplier > lns->allocate_storage) lns->allocate_storage = multiplier;
	lns->storage_requested = TRUE;
}

inter_name *JumpLabels::storage_iname(text_stream *namespace) {
	label_namespace *lns = JumpLabels::obtain_namespace(namespace);
	return lns->label_storage_iname;
}

@ When a function body is completed, this is then called to create the necessary
storage space, if any:

=
void JumpLabels::compile_necessary_storage(void) {
	linked_list *namespaces = Functions::current_label_namespaces();
	label_namespace *lns;
	LOOP_OVER_LINKED_LIST(lns, label_namespace, namespaces)
		if ((lns->storage_compiled == FALSE) && (lns->storage_requested)) {
			int N = (lns->allocate_storage)*(lns->max_label_counter + 1);
			if (N > 0) {
				packaging_state save =
					EmitArrays::begin_word(lns->label_storage_iname, K_value);
				for (int i=0; i<N; i++) EmitArrays::numeric_entry(0);
				if (N == 1) EmitArrays::numeric_entry(0);
				EmitArrays::end(save);
				lns->storage_compiled = TRUE;
			}
		}
}
