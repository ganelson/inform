[Anaphora::] Anaphoric References.

To keep track of the current object and subject of discussion.

@ Inform is deliberately minimal when allowing the use of pronouns which carry
meanings from one sentence to another. It is unclear exactly how natural
language does this, and while some theories are more persuasive than others,
all seem vulnerable to odd cases that they get "wrong". It's therefore
hard to program a computer to understand "it" so that human users are
happy with the result.

But we try, just a little, by keeping track of the subject and object
under discussion. Even this is tricky. Consider:

>> The Pavilion is a room. East is the Cricket Square.

East of where? Clearly of the current subject, the Pavilion (not
the room kind). On the other hand,

>> On the desk is a pencil. It has description "2B."

"It" here is the pencil, not the desk. To disentangle such things,
we keep track of two different running references: the current subject and
the current object. English is an SVO language, so that in assertions of the
form "X is Y", X is the subject and Y the object. But it will turn out to
be more complicated than that, because we disregard all references which are
not to tangible things and kinds.

=
inference_subject *Anaphora::get_current_subject(void) {
	return global_pass_state.subject_of_sentences;
}

inference_subject *Anaphora::get_current_object(void) {
	return global_pass_state.object_of_sentences;
}

int Anaphora::get_current_subject_plurality(void) {
	return global_pass_state.subject_seems_to_be_plural;
}

@ The routine |Anaphora::new_discussion| is called when we reach a
heading or other barrier in the source text, to make clear that there has
been a change of the topic discussed.

|Anaphora::change_discussion_topic| is called once at the end of
processing each assertion during each pass.

Note that we are careful to avoid changing the subject with sentences like:

>> East is the Central Plaza.

where this does not have the subject "east", but has instead an implicit
subject carried over from previous sentences.

=
void Anaphora::new_discussion(void) {
	if (global_pass_state.subject_of_sentences)
		LOGIF(PRONOUNS, "[Forgotten subject of sentences: $j]\n",
			global_pass_state.subject_of_sentences);
	if (global_pass_state.subject_of_sentences)
		LOGIF(PRONOUNS, "[Forgotten object of sentences: $j]\n",
			global_pass_state.object_of_sentences);
	global_pass_state.subject_of_sentences = NULL;
	global_pass_state.object_of_sentences = NULL;
	global_pass_state.subject_seems_to_be_plural = FALSE;
}

@ The slight asymmetry in what follows is partly pragmatic, partly the result
of subject-verb inversion ("in the bag is the ball" not "the ball is in the
bag"). We extract a subject from a relationship node on the left, but not on
the right, and we don't extract an object from one. Consider:

>> A billiards table is in the Gazebo. On it is a trophy cup.

What does "it" mean, and why? A human reader goes for the billiards table at
once, because it seems more likely as a supporter than the Gazebo, but that's
not how Inform gets the same answer. It all hangs on "billiards table" being
the object of the first sentence, not the Gazebo; if we descended the RHS,
which is |RELATIONSHIP_NT -> PROPER_NOUN_NT| pointing to the Gazebo, that's the
conclusion we would have reached.

=
void Anaphora::change_discussion_from_coupling(parse_node *px, parse_node *py) {
	inference_subject *infsx = NULL, *infsy = NULL, *infsy_full = NULL;
	infsx = Anaphora::discussed_at_node(px);
	infsy_full = Anaphora::discussed_at_node(py);
	if (Node::get_type(py) != KIND_NT) infsy = Node::get_subject(py);
	Anaphora::change_discussion_topic(infsx, infsy, infsy_full);
	if (Node::get_type(px) == AND_NT) Anaphora::subject_of_discussion_a_list();
	if (Annotations::read_int(current_sentence, clears_pronouns_ANNOT))
		Anaphora::new_discussion();
}

void Anaphora::change_discussion_topic(inference_subject *infsx,
	inference_subject *infsy, inference_subject *infsy_full) {
	inference_subject *old_sub = global_pass_state.subject_of_sentences,
		*old_obj = global_pass_state.object_of_sentences;
	global_pass_state.subject_seems_to_be_plural = FALSE;
	if (Wordings::length(Node::get_text(current_sentence)) > 1)
		global_pass_state.near_start_of_extension = 0;
	Node::set_interpretation_of_subject(current_sentence,
		global_pass_state.subject_of_sentences);

	if (Annotations::node_has(current_sentence, implicit_in_creation_of_ANNOT))
		return;
	#ifdef IF_MODULE
	if ((PL::Map::is_a_direction(infsx)) &&
			((InstanceSubjects::to_object_instance(infsx) == NULL) ||
				(InstanceSubjects::to_object_instance(infsy_full)))) infsx = NULL;
	#endif
	if (infsx) global_pass_state.subject_of_sentences = infsx;
	if ((infsy) && (KindSubjects::to_kind(infsy) == NULL))
		global_pass_state.object_of_sentences = infsy;
	else if (infsx) global_pass_state.object_of_sentences = infsx;

	if (global_pass_state.subject_of_sentences != old_sub)
		LOGIF(PRONOUNS, "[Changed subject of sentences to $j]\n",
			global_pass_state.subject_of_sentences);
	if (global_pass_state.object_of_sentences != old_obj)
		LOGIF(PRONOUNS, "[Changed object of sentences to $j]\n",
			global_pass_state.object_of_sentences);
}

@ =
inference_subject *Anaphora::discussed_at_node(parse_node *pn) {
	inference_subject *infs = NULL;
	if (Node::get_type(pn) != KIND_NT) infs = Node::get_subject(pn);
	if ((Node::get_type(pn) == RELATIONSHIP_NT) && (pn->down) &&
		(Node::get_type(pn->down) == PROPER_NOUN_NT))
		infs = Node::get_subject(pn->down);
	if ((Node::get_type(pn) == WITH_NT) && (pn->down) &&
		(Node::get_type(pn->down) == PROPER_NOUN_NT))
		infs = Node::get_subject(pn->down);
	return infs;
}

@ Occasionally we need to force the issue, though:

=
void Anaphora::subject_of_discussion_a_list(void) {
	global_pass_state.subject_seems_to_be_plural = TRUE;
}
