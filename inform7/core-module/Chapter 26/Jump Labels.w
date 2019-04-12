[JumpLabels::] Jump Labels.

I7 is has no Dijkstra-like conscience about compiling code which
is full of |jump| statements, and these require labels to jump to. This
section provides those labels, and other related unique-ID-number counters.

@h Definitions.

@ For clarity we give each label in the compiled code its own unique name
(even though this is not strictly necessary since I6 labels have only local
scope to their routines), and this means allowing for sets of labels with
a unique ID number providing guaranteed-previously-unused new labels in
every set.

So: each set of labels is identified with a name, and the labels written take
the form |L_NameNumber|. For instance, |L_Marble17| is the 18th label in
namespace |Marble|. Every label namespace's name must differ from every
other. It is legal for a namespace's name to be the empty string, which
generates labels |L_0|, |L_1|, ...

@d MAX_NAMESPACE_PREFIX_LENGTH 20 /* when |L_| and a number are added, we are within 31 chars */

=
typedef struct label_namespace {
	struct text_stream *base_prefix;
	struct text_stream *label_prefix;
	int label_counter; /* next free ID number for this label namespace */
	int allocate_storage; /* number of words of memory to reserve for each label */
	struct inter_name *label_base_iname;
	struct inter_name *label_storage_iname;
	struct compilation_module *module;
	MEMORY_MANAGEMENT
} label_namespace;

@ The creator for new label namespaces. Note that, by default, a label namespace
reserves no memory.

=
label_namespace *JumpLabels::new_namespace(text_stream *name, compilation_module *cm) {
	if (cm == NULL) internal_error("jump label outside of module");
	if (Str::len(name) > MAX_NAMESPACE_PREFIX_LENGTH)
		Problems::Issue::sentence_problem(_p_(PM_LabelNamespaceTooLong),
			"a label namespace prefix is too long",
			"and should be shortened to a few alphabetic characters.");
	label_namespace *lns = CREATE(label_namespace);
	lns->base_prefix = Str::duplicate(name);
	lns->label_prefix = Str::new();
	WRITE_TO(lns->label_prefix, "%S%S", cm->namespace->namespace_prefix, name);
	lns->label_base_iname = InterNames::label_base_name(lns->label_prefix);
	
	package_request *PR = Packaging::synoptic_resource(PHRASES_SUBMODULE);
	package_request *PR2 = Packaging::request(
		Packaging::supply_iname(PR, LABEL_STORAGE_PR_COUNTER), PR, label_storage_ptype);
	lns->label_storage_iname = InterNames::one_off(I"label_associated_storage", PR2);
	Inter::Symbols::set_flag(InterNames::to_symbol(lns->label_storage_iname), MAKE_NAME_UNIQUE);
	
	lns->label_counter = 0;
	lns->allocate_storage = 0;
	lns->module = cm;
	return lns;
}

@ The rest of Inform tends not to store pointers to namespaces: instead it
must access them by searching on the name. This is inefficient, but there are
few namespaces and it happens fairly seldom, so there is no point in
optimising.

=
label_namespace *JumpLabels::namespace_by_prefix(text_stream *name, compilation_module *cm) {
	label_namespace *lns;
	LOOP_OVER(lns, label_namespace)
		if ((lns->module == cm) && (Str::eq(name, lns->base_prefix)))
			return lns;
	return NULL;
}

label_namespace *JumpLabels::read_or_create_namespace(text_stream *name) {
	compilation_module *cm = Modules::current();
	label_namespace *lns = JumpLabels::namespace_by_prefix(name, cm);
	if (lns == NULL) lns = JumpLabels::new_namespace(name, cm);
	return lns;
}

@ The rest of Inform is allowed only to call for a label in a given namespace,
advancing the counter or not as it pleases; or to call for the current
counter value.

=
int JumpLabels::read_counter(text_stream *namespace, int advance_flag) {
	label_namespace *lns = JumpLabels::read_or_create_namespace(namespace);
	int c = lns->label_counter;
	if (advance_flag == TRUE) lns->label_counter++;
	if (advance_flag == FALSE) {
		lns->label_counter--;
		if (lns->label_counter < 0) internal_error("label counter negative");
	}
	return c;
}

void JumpLabels::write(OUTPUT_STREAM, text_stream *namespace) {
	label_namespace *lns = JumpLabels::read_or_create_namespace(namespace);
	WRITE("L_%S%d", lns->label_prefix, lns->label_counter);
}

inter_name *JumpLabels::storage(text_stream *namespace) {
	label_namespace *lns = JumpLabels::read_or_create_namespace(namespace);
	return lns->label_storage_iname;
}

@ It is possible to mark a namespace as requiring 1 or more words of storage.
If so, the namespace |Whatsit| makes a word array called |I7_ST_Whatsit|
which contains enough words for each label actually allocated to have that
many words of storage. (And we add 2 words, to provide a safety margin, and
because in the event of a namespace for which no labels are created, I6
would otherwise throw an error at being asked to make an array with the
specification |--> 0|.)

=
void JumpLabels::allocate_counter(text_stream *namespace, int multiplier) {
	label_namespace *lns = JumpLabels::read_or_create_namespace(namespace);
	if (multiplier > lns->allocate_storage) lns->allocate_storage = multiplier;
}

void JumpLabels::compile_necessary_storage(void) {
	label_namespace *lns;
	LOOP_OVER(lns, label_namespace)
		if (lns->allocate_storage > 0) {
			packaging_state save = Packaging::enter_home_of(lns->label_storage_iname);
			Emit::named_array_begin(lns->label_storage_iname, K_number);
			int N = (lns->allocate_storage)*(lns->label_counter) + 2;
			for (int i=0; i<N; i++) Emit::array_numeric_entry(0);
			Emit::array_end();
			Packaging::exit(save);
		}
}

void JumpLabels::reset(void) {
}
