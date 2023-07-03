[ActivityRequests::] New Activity Requests.

Special sentences creating new activities.

@ This special meaning is only needed for one case. If activities are created
by the sentence

>> Counting is an activity on numbers.

then this happens via the regular meaning of "to be", because "activity on
numbers" is a valid kind of value. But this:

>> Describing is an activity.

can't be handled that way because "activity" is not a valid kind. And so we
handle this case through a special case of "X is Y" which applies only if Y
matches:

=
<bare-activity-sentence-object> ::=
	<article> activity |
	activity

@ =
int ActivityRequests::new_activity_SMF(int task, parse_node *V, wording *NPs) {
	wording SW = (NPs)?(NPs[0]):EMPTY_WORDING;
	wording OW = (NPs)?(NPs[1]):EMPTY_WORDING;
	switch (task) {
		case ACCEPT_SMFT:
			if (<bare-activity-sentence-object>(OW)) {
				<np-unparsed>(SW);
				V->next = <<rp>>;
				<np-unparsed>(OW);
				V->next->next = <<rp>>;
				return TRUE;
			}
			break;
		case PASS_1_SMFT:
			Activities::new(Kinds::unary_con(CON_activity, K_object),
				Node::get_text(V->next), TRUE);
			break;
	}
	return FALSE;
}
