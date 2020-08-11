[Problems::] Supplementary Quotes.

More things to quote in problem messages.

@ We provide some simple extensions to the Problems module's stock of data
structures which can be quoted. (These routines look as if they ought to be
automated with macros, but that would be a nuisance because the tangler then
wouldn't auto-predeclare them; and there aren't so very many of them.)

=
void Problems::quote_spec(int t, parse_node *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_spec);
}
void Problems::expand_spec(OUTPUT_STREAM, void *p) {
	Specifications::write_out_in_English(OUT, (parse_node *) p);
}
void Problems::quote_relation(int t, binary_predicate *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_relation);
}
void Problems::expand_relation(OUTPUT_STREAM, void *p) {
	BinaryPredicates::describe_for_problems(OUT, (binary_predicate *) p);
}
void Problems::quote_phrase(int t, phrase *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_phrase);
}
void Problems::expand_phrase(OUTPUT_STREAM, void *p) {
	Phrases::write_HTML_representation(OUT, (phrase *) p, INDEX_PHRASE_FORMAT);
}
void Problems::quote_extension(int t, inform_extension *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_extension);
}
void Problems::expand_extension(OUTPUT_STREAM, void *p) {
	Extensions::write(OUT, (inform_extension *) p);
}
void Problems::quote_copy(int t, inbuild_copy *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_copy);
}
void Problems::expand_copy(OUTPUT_STREAM, void *p) {
	Copies::write_copy(OUT, (inbuild_copy *) p);
}
void Problems::quote_work(int t, inbuild_work *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_work);
}
void Problems::expand_work(OUTPUT_STREAM, void *p) {
	Works::write(OUT, (inbuild_work *) p);
}
void Problems::quote_object(int t, instance *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_object);
}

@ Since numerous instances are created without explicit and distinct
names, for instance by sentences like

>> Four coins are in the box.

...it's prudent to quote instances without names carefully, and not to ignore
this as some kind of marginal will-never-happen case.

=
void Problems::expand_object(OUTPUT_STREAM, void *p) {
	instance *I = (instance *) p;
	if (I) {
		wording W = Instances::get_name(I, FALSE);
		if (Wordings::nonempty(W))
			Problems::expand_text_within_reason(OUT, W);
		else {
			WRITE("nameless ");
			kind *k = Instances::to_kind(I);
			wording KW = Kinds::Behaviour::get_name(k, FALSE);
			if (Wordings::nonempty(KW)) Problems::expand_text_within_reason(OUT, KW);
			else WRITE("thing");
			parse_node *from = Instances::get_creating_sentence(I);
			if (from) {
				WRITE(" created in the sentence ");
				Problems::append_source(Node::get_text(from));
			}
		}
	}
}
void Problems::quote_subject(int t, inference_subject *infs) {
	if (infs == NULL) { Problems::quote_text(t, "something"); return; }
	wording W = InferenceSubjects::get_name_text(infs);
	if (Wordings::nonempty(W)) { Problems::quote_wording(t, W); return; }
	instance *I = InferenceSubjects::as_object_instance(infs);
	if (I) { Problems::quote_object(t, I); return; }
	Problems::quote_text(t, "something nameless"); /* this never actually happens */
}
void Problems::quote_invocation(int t, parse_node *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_invocation);
}
void Problems::expand_invocation(OUTPUT_STREAM, void *p) {
	Phrases::TypeData::Textual::inv_write_HTML_representation(OUT, (parse_node *) p);
}
void Problems::quote_extension_id(int t, inbuild_work *p) {
	Problems::problem_quote(t, (void *) p, Problems::expand_extension_id);
}
void Problems::expand_extension_id(OUTPUT_STREAM, void *p) {
	Works::write_to_HTML_file(OUT, (inbuild_work *) p, FALSE);
}
void Problems::quote_property(int t, property *p) { Problems::quote_wording(t, p->name); }
void Problems::quote_table(int t, table *tab) {
	Problems::quote_source(t, Tables::get_headline(tab));
}

@ To quote a kind is straightforward enough:

=
void Problems::quote_kind(int t, kind *K) {
	if ((K == NULL) || (Kinds::Compare::eq(K, K_nil))) Problems::quote_text(t, "nothing");
	else if ((K == NULL) || (Kinds::Compare::eq(K, K_void))) Problems::quote_text(t, "nothing");
	else Problems::problem_quote(t, (void *) K, Problems::expand_kind);
}

void Problems::expand_kind(OUTPUT_STREAM, void *p) {
	Kinds::Textual::write_articled(OUT, (kind *) p);
}

@ But we also provide another way to mention kinds within problem messages;
we quote not a literal constant but its kind of value, changing (say) the
actual constant 15 to the generic constant "number":

=
void Problems::quote_kind_of(int t, parse_node *spec) {
	if (Rvalues::is_object(spec)) {
		if (Annotations::read_int(spec, self_object_ANNOT)) {
			Problems::quote_text(t, "implicit object"); /* this is probably never seen, but just in case */
			return;
		} else if (Annotations::read_int(spec, nothing_object_ANNOT)) {
			Problems::quote_text(t, "the 'nothing' non-object"); /* whereas this can certainly happen */
			return;
		} else {
			instance *I = Rvalues::to_instance(spec);
			Problems::quote_kind(t, Instances::to_kind(I));
			return;
		}
	}
	kind *K = Specifications::to_kind(spec);
	if (K) Problems::quote_kind(t, K);
	else Problems::quote_spec(t, spec);
}
