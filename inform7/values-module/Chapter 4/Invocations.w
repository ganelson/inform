[Invocations::] Invocations.

Invocations are to phrases what function calls are to functions, though they
do not always compile that way.

@ See //Invocation Lists// for some context for the following.

Every invocation node is produced by the following function. As can be seen,
these nodes are heavily annotated.

=
parse_node *Invocations::new(void) {
	parse_node *inv = Node::new(INVOCATION_NT);
	Node::set_phrase_invoked(inv, NULL);
	Node::set_say_verb(inv, NULL);
	Node::set_modal_verb(inv, NULL);
	Node::set_say_adjective(inv, NULL);
	Node::set_kind_resulting(inv, NULL);
	Node::set_phrase_options_invoked(inv, NULL);
	Node::set_kind_variable_declarations(inv, NULL);
	Annotations::write_int(inv, ssp_closing_segment_wn_ANNOT, -1);
	return inv;
}

@

The process of type-checking then strikes out definitely incorrect
invocations, reducing the size of the list. If it becomes empty, the
type-checker produces a Problem message; and similarly if it is
impossible to remove mutually exclusive possibilities, for that is
an ambiguity which Inform cannot resolve. But a successful type-checking
may still leave more than one invocation in the list. There are two
reasons for this:

(a) The list is bunched up into groups, which are numbered within the
list from 0 upwards. Type-checking proceeds on each group independently.
For most phrases, there is only one group -- group 0 -- and this business
therefore has no effect, but it comes into its own for "say" phrases:

>> say "The time is ", time of day in words, " and you yawn."

Here what looks like a single phrase is in fact a sequence of three
phrases, to say each of the items required, and this gives rise to
groups 0, 1 and 2 in the invocation list: each group is treated as,
in effect, a separate phrase in its own right. (Except that compilation
of the final group has a small difference: that's where Inform appends
a line break to text which, from its punctuation, apparently ends a
sentence.) Groups are not interleaved: the list starts with the
whole of group 0, then the whole of group 1, and so on.

(b) More interestingly, type-checking of any individual invocation has
three possible outcomes, not two: as in Scottish law, the verdict
can be guilty, not guilty, or "not proven". An invocation which
can be disproved is thrown out of the list; but of the remainder,
some are marked as proven to be correct, some as unproven. What
this means is that we cannot tell at compile-time whether the usage
is valid, but that we will be able to tell at run-time: so the
code-generator must compile suitable disambiguation code to perform
this run-time checking automatically.

@ When necessary, and it usually isn't, an invocation has a packet of
details attached about any phrase options used; for instance, in

>> list the contents of the Box, with newlines;

this packet records the text "with newlines" along with its translation
as a run-time bitmap (with just one bit set, since only one option is used).

=
typedef struct invocation_options {
	int options; /* bitmap of any phrase options appended */
	struct wording options_invoked_text; /* text of any phrase options appended */
} invocation_options;

@ An invocation can have an arbitrary number of "tokens". These are the
arguments for the phrase being invoked; so for instance in

>> a random number between 2 and 7;

token 0 is "2" and token 1 is "7". For each token we record both what
we've parsed -- these will each be constant |VALUE_VNT| specifications of kind
"number" -- and also what match the type-checker needs to make for them
to be valid.

@ At first sight, the |invocation| structure appears to contain redundant
information. And two of the fields are, in a way, redundant: the word number
fields holding the text will, of course, be common to every entry in its
group, so it is wasteful to store them so many times. But not very wasteful,
by our standards, and the information is not easily available
elsewhere, and it enables the debugging log to be much more informative
about the working of our most complicated algorithms.

Similarly, |token_as_parsed| values look as if they too must be the same
for everything in the group. But this is not always true. If we are
interpreting the text "award 11 points" against possible phrases
"award (O - an object)" and "award (N - a number) points", then
the 0th token will be "11 points" (probably parsing to |UNKNOWN_NT|)
for the first invocation, and "11" (|NUMBER|) for the second. We
shall of course accept the second. But the word positions for the 0th
token, and its parsing values, are different. So each invocation in
the list records its own |token_as_parsed| values.

@ On the other hand, |token_check_to_do| and |kind_resulting|
look as if they are purely a function of the |phrase_invoked|, and
therefore need not be in this structure at all. This is not true:

(i) A SP in |token_check_to_do| means that Inform has not yet satisfied
itself that the |token_as_parsed| value matches properly. Once the
type-checker does convince itself, the relevant entry in
|token_check_to_do| is cleared to |NULL|. If every token can be cleared,
the invocation is declared proven. But if the type-checker accepts the
invocation but marks it as "not proven", one or more values remain as a
sort of to-do list, telling the code generator what remains to be checked
at run-time. So |token_check_to_do| really is associated with a specific
invocation, and is not redundant.

(ii) Because arithmetic phrases return different data depending
on the kinds fed in, |kind_resulting| will be different
for different invocations of, say, "+".

@d LOOP_THROUGH_TOKENS_PARSED_IN_INV(inv, spec)
	int lttpii_counter, lttpii_upto = Invocations::get_no_tokens(inv);
	for (lttpii_counter=0,
		spec = (lttpii_counter < lttpii_upto)?
			Invocations::get_token_as_parsed(inv, lttpii_counter):NULL;
		lttpii_counter < lttpii_upto;
		lttpii_counter++,
		spec = (lttpii_counter < lttpii_upto)?
			Invocations::get_token_as_parsed(inv, lttpii_counter):NULL)

@

@d MAX_INVOCATIONS_PER_PHRASE 4096

@h Invocations themselves.
Are created thus:

=

@ And logging thus:

=
void Invocations::log(parse_node *inv) {
	int i;
	if (inv == NULL) { LOG("<null invocation>"); return; }
	if (inv->node_type != INVOCATION_NT) { LOG("$P", inv); return; }
	char *verdict = Dash::verdict_to_text(inv);

	LOG("[%04d%s] %8s ",
		ToPhraseFamily::sequence_count(Node::get_phrase_invoked(inv)),
		(Invocations::is_marked_to_save_self(inv))?"-save-self":"",
		verdict);
	if (Node::get_say_verb(inv)) {
		LOG("verb:%d", Node::get_say_verb(inv)->allocation_id);
		if (Node::get_modal_verb(inv)) LOG("modal:%d", Node::get_modal_verb(inv)->allocation_id);
	} else if (Node::get_say_adjective(inv)) {
		LOG("adj:%d", Node::get_say_adjective(inv)->allocation_id);
	} else {
		ImperativeDefinitions::log_body_fuller(Node::get_phrase_invoked(inv));
		for (i=0; i<Invocations::get_no_tokens(inv); i++) {
			LOG(" ($P", Invocations::get_token_as_parsed(inv, i));
			if (Invocations::get_token_check_to_do(inv, i))
				LOG(" =? $P", Invocations::get_token_check_to_do(inv, i));
			LOG(")");
		}
		wording OW = Invocations::get_phrase_options(inv);
		if (Wordings::nonempty(OW))
			LOG(" [0x%x %W]", Invocations::get_phrase_options_bitmap(inv), OW);
		kind_variable_declaration *kvd = Node::get_kind_variable_declarations(inv);
		for (; kvd; kvd=kvd->next) LOG(" %c=%u", 'A'+kvd->kv_number-1, kvd->kv_value);
	}
}

@ Two important flags:

=
void Invocations::mark_to_save_self(parse_node *inv) {
	Annotations::write_int(inv, save_self_ANNOT, TRUE);
}

int Invocations::is_marked_to_save_self(parse_node *inv) {
	return Annotations::read_int(inv, save_self_ANNOT);
}

void Invocations::mark_unproven(parse_node *inv) {
	Annotations::write_int(inv, unproven_ANNOT, TRUE);
}

int Invocations::is_marked_unproven(parse_node *inv) {
	return Annotations::read_int(inv, unproven_ANNOT);
}

@ The word range:

=
void Invocations::set_word_range(parse_node *inv, wording W) {
	if (inv == NULL) internal_error("tried to set word range of null inv");
	Node::set_text(inv, W);
}

@ The say verb:

=
void Invocations::set_verb_conjugation(parse_node *inv,
	verb_conjugation *vc, verb_conjugation *modal, int neg) {
	if (inv == NULL) internal_error("tried to set VC of null inv");
	Node::set_say_verb(inv, vc);
	Node::set_modal_verb(inv, modal);
	Annotations::write_int(inv, say_verb_negated_ANNOT, neg);
}

@ The say adjective:

=
void Invocations::set_adjective(parse_node *inv, adjective *aph) {
	if (inv == NULL) internal_error("tried to set ADJ of null inv");
	Node::set_say_adjective(inv, aph);
}

@ The tokens. Recall that these are stored as a linked list; the following
creates a new entry structure.

=
parse_node *Invocations::new_token(node_type_t t) {
	parse_node *it = Node::new(t);
	Node::set_token_check_to_do(it, NULL);
	Node::set_token_to_be_parsed_against(it, NULL);
	Node::set_kind_of_new_variable(it, NULL);
	return it;
}

@ However, we want to access it as if it were an array. (Speed is not too
vital here, and the list sizes are almost always lower than 3.) So:

=
void Invocations::make_token(parse_node *inv, int i, node_type_t t, wording W, kind *K) {
	int k;
	parse_node *itl;
	if (i<0) internal_error("tried to set token out of range");
	if (inv->down == NULL) inv->down = Invocations::new_token(t);
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++) {
		if (k == i) {
			Node::set_text(itl, W);
			Node::set_type(itl, t);
			Node::set_kind_required_by_context(itl, K);
			return;
		}
		if (itl->next == NULL) itl->next = Invocations::new_token(t);
	}
}

void Invocations::set_token_check_to_do(parse_node *inv, int i, parse_node *spec) {
	int k;
	parse_node *itl;
	if (i<0) internal_error("tried to set token out of range");
	if (inv->down == NULL) inv->down = Invocations::new_token(INVALID_NT);
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++) {
		if (k == i) { Node::set_token_check_to_do(itl, spec); return; }
		if (itl->next == NULL) itl->next = Invocations::new_token(INVALID_NT);
	}
}

void Invocations::set_token_as_parsed(parse_node *inv, int i, parse_node *spec) {
	int k;
	parse_node *itl;
	if (i<0) internal_error("tried to set token out of range");
	if (inv->down == NULL) inv->down = Invocations::new_token(INVALID_NT);
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++) {
		if (k == i) { itl->down = spec; return; }
		if (itl->next == NULL) itl->next = Invocations::new_token(INVALID_NT);
	}
}

void Invocations::set_token_to_be_parsed_against(parse_node *inv, int i, parse_node *spec) {
	int k;
	parse_node *itl;
	if (i<0) internal_error("tried to set token out of range");
	if (inv->down == NULL) inv->down = Invocations::new_token(INVALID_NT);
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++) {
		if (k == i) { Node::set_token_to_be_parsed_against(itl, spec); return; }
		if (itl->next == NULL) itl->next = Invocations::new_token(INVALID_NT);
	}
}

void Invocations::set_token_variable_kind(parse_node *inv, int i, kind *K) {
	int k;
	parse_node *itl;
	if (i<0) internal_error("tried to set token out of range");
	if (inv->down == NULL) inv->down = Invocations::new_token(INVALID_NT);
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++) {
		if (k == i) { Node::set_kind_of_new_variable(itl, K); return; }
		if (itl->next == NULL) itl->next = Invocations::new_token(INVALID_NT);
	}
}

@ And similarly for reading them:

=
parse_node *Invocations::get_token(parse_node *inv, int i) {
	int k;
	parse_node *itl;
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++)
		if (k == i) return itl;
	return NULL;
}

parse_node *Invocations::get_token_check_to_do(parse_node *inv, int i) {
	int k;
	parse_node *itl;
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++)
		if (k == i) return Node::get_token_check_to_do(itl);
	return NULL;
}

parse_node *Invocations::get_token_as_parsed(parse_node *inv, int i) {
	int k;
	parse_node *itl;
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++)
		if (k == i) return itl->down;
	return NULL;
}

parse_node *Invocations::get_token_to_be_parsed_against(parse_node *inv, int i) {
	int k;
	parse_node *itl;
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++)
		if (k == i) return Node::get_token_to_be_parsed_against(itl);
	return NULL;
}

kind *Invocations::get_token_variable_kind(parse_node *inv, int i) {
	int k;
	parse_node *itl;
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++)
		if (k == i) return Node::get_kind_of_new_variable(itl);
	return NULL;
}

int Invocations::get_no_tokens(parse_node *inv) {
	int k;
	parse_node *itl;
	for (itl = inv->down, k = 0; itl; itl = itl->next, k++) ;
	return k;
}

@ The following routine might become more interesting if we ever allowed
variable-argument phrases like C's |printf|.

=
int Invocations::get_no_tokens_needed(parse_node *inv) {
	if (inv == NULL) internal_error("tried to read NTI of null inv");
	if (Node::get_phrase_invoked(inv))
		return IDTypeData::get_no_tokens(
			&(Node::get_phrase_invoked(inv)->type_data));
	return 0;
}

@ The phrase options invoked:

=
void Invocations::set_phrase_options(parse_node *inv, wording W) {
	invocation_options *invo = Node::get_phrase_options_invoked(inv);
	if (invo == NULL) {
		invo = CREATE(invocation_options);
		invo->options = 0;
		Node::set_phrase_options_invoked(inv, invo);
	}
	invo->options_invoked_text = W;
}

@ Reading the word range:

=
wording Invocations::get_phrase_options(parse_node *inv) {
	invocation_options *invo = Node::get_phrase_options_invoked(inv);
	if (invo == NULL) return EMPTY_WORDING;
	return invo->options_invoked_text;
}

@ The functional part is of course the bitmap, which we read and write thus.
When no options are set, the bitmap is always 0.

=
int Invocations::get_phrase_options_bitmap(parse_node *inv) {
	invocation_options *invo = Node::get_phrase_options_invoked(inv);
	if (invo == NULL) return 0;
	return invo->options;
}

void Invocations::set_phrase_options_bitmap(parse_node *inv, int further_bits) {
	if (further_bits == 0) return;
	invocation_options *invo = Node::get_phrase_options_invoked(inv);
	if (invo == NULL) {
		invo = CREATE(invocation_options);
		invo->options_invoked_text = EMPTY_WORDING;
		invo->options = 0;
		Node::set_phrase_options_invoked(inv, invo);
	}
	invo->options |= further_bits;
}

@h The implied newlines rule.
This is applied only when the invocation passes the following stringent test:

=
int Invocations::implies_newline(parse_node *inv) {
	if (!(IDTypeData::is_a_say_phrase(Node::get_phrase_invoked(inv)))) return FALSE;
	if (!(TEST_COMPILATION_MODE(IMPLY_NEWLINES_IN_SAY_CMODE))) return FALSE;
	return TRUE;
}

@ By contrast, this compares two invocations by their contents:

=
int Invocations::eq(parse_node *inv1, parse_node *inv2) {
	if ((inv1) && (inv2 == NULL)) return FALSE;
	if ((inv1 == NULL) && (inv2)) return FALSE;
	if (inv1 == NULL) return TRUE;

	if (Node::get_phrase_invoked(inv1) != Node::get_phrase_invoked(inv2))
		return FALSE;
	if (Invocations::get_no_tokens(inv1) != Invocations::get_no_tokens(inv2))
		return FALSE;

	for (int i=0; i<Invocations::get_no_tokens(inv1); i++) {
		parse_node *m1 = Invocations::get_token_to_be_parsed_against(inv1, i);
		parse_node *m2 = Invocations::get_token_to_be_parsed_against(inv2, i);
		if (Node::get_type(m1) != Node::get_type(m2)) return FALSE;
		parse_node *v1 = Invocations::get_token_as_parsed(inv1, i);
		parse_node *v2 = Invocations::get_token_as_parsed(inv2, i);
		if (Node::get_type(v1) != Node::get_type(v2)) return FALSE;
		if (!Wordings::eq(Node::get_text(v1), Node::get_text(v2))) return FALSE;
	}
	return TRUE;
}

@

=
void Invocations::log_tokens(parse_node *inv) {
	for (int j=0; j<Invocations::get_no_tokens(inv); j++) {
		parse_node *tok = Invocations::get_token_as_parsed(inv, j);
		LOG("  %d: $P\n", j, tok);
		if (Node::is(tok->down, INVOCATION_LIST_NT)) {
			LOG_INDENT;
			InvocationLists::log_in_detail(tok->down->down);
			LOG_OUTDENT;
		}
	}
}
