[IXInstances::] Instances.

To index instances.

@ Each instance includes the following additional data:

=
typedef struct instance_index_data {
	int index_appearances; /* how many times have I appeared thus far in the World index? */
	struct instance_usage *first_noted_usage;
	struct instance_usage *last_noted_usage;
} instance_index_data;

typedef struct instance_usage {
	struct parse_node *where_instance_used;
	struct instance_usage *next;
} instance_usage;

@ =
void IXInstances::initialise_iid(instance *I) {
	I->iid.index_appearances = 0;
	I->iid.first_noted_usage = NULL;
	I->iid.last_noted_usage = NULL;
}

@h Noun usage.
This simply avoids repetitions in the World index:

=
void IXInstances::increment_indexing_count(instance *I) {
	I->iid.index_appearances++;
}

int IXInstances::indexed_yet(instance *I) {
	if (I->iid.index_appearances > 0) return TRUE;
	return FALSE;
}

@ Not every instance has a name, which is a nuisance for the index:

=
void IXInstances::index_name(OUTPUT_STREAM, instance *I) {
	wording W = Instances::get_name_in_play(I, FALSE);
	if (Wordings::nonempty(W)) {
		WRITE("%+W", W);
		return;
	}
	kind *K = Instances::to_kind(I);
	W = Kinds::Behaviour::get_name_in_play(K, FALSE,
		Projects::get_language_of_play(Task::project()));
	if (Wordings::nonempty(W)) {
		WRITE("%+W", W);
		return;
	}
	WRITE("nameless");
}

@ It's perhaps ambiguous what a usage of an instance is, or where it occurs,
but this function is called each time the instance |I| is compiled as a
constant value.

=
void IXInstances::note_usage(instance *I, parse_node *NB) {
	if (I->iid.last_noted_usage) {
		if (NB == I->iid.last_noted_usage->where_instance_used) return;
	}
	instance_usage *IU = CREATE(instance_usage);
	IU->where_instance_used = NB;
	IU->next = NULL;
	if (I->iid.last_noted_usage == NULL) {
		I->iid.first_noted_usage = IU;
		I->iid.last_noted_usage = IU;
	} else {
		I->iid.last_noted_usage->next = IU;
		I->iid.last_noted_usage = IU;
	}
}

void IXInstances::index_usages(OUTPUT_STREAM, instance *I) {
	int k = 0;
	instance_usage *IU = I->iid.first_noted_usage;
	for (; IU; IU = IU->next) {
		parse_node *at = IU->where_instance_used;
		if (at) {
			source_file *sf = Lexer::file_of_origin(Wordings::first_wn(Node::get_text(at)));
			if (Projects::draws_from_source_file(Task::project(), sf)) {
				k++;
				if (k == 1) {
					HTML::open_indented_p(OUT, 1, "tight");
					WRITE("<i>mentioned in rules:</i> ");
				} else WRITE("; ");
				Index::link(OUT, Wordings::first_wn(Node::get_text(at)));
			}
		}
	}
	if (k > 0) HTML_CLOSE("p");
}

@h Adjectival usage.

=
int IXInstances::as_adjective(OUTPUT_STREAM, instance *I) {
	property *P = Properties::Conditions::get_coinciding_property(Instances::to_kind(I));
	if (Properties::Conditions::of_what(P) == NULL) {
		if (Properties::get_permissions(P)) {
			WRITE("(of "); IXProperties::index_permissions(OUT, P); WRITE(") ");
		}
		WRITE("having this %+W", P->name);
	} else {
		WRITE("a condition which is otherwise ");
		kind *K = Instances::to_kind(I);
		int no_alts = Instances::count(K) - 1, i = 0;
		instance *alt;
		LOOP_OVER_INSTANCES(alt, K)
			if (alt != I) {
				WRITE("</i>");
				WRITE("%+W", Instances::get_name(alt, FALSE));
				WRITE("<i>");
				i++;
				if (i == no_alts-1) WRITE(" or ");
				else if (i < no_alts) WRITE(", ");
			}
	}
	return TRUE;
}
