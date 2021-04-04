[Invocations::] Invocations.

Invocations are to phrases what function calls are to functions, though they
do not always compile that way.

@h The node itself.
See //Invocation Lists// for some context for the following.

Every invocation node is produced by the following function: it looks simple
enough now but will go on to be heavily annotated, and also to have child
nodes for its tokens.

=
parse_node *Invocations::new(wording W) {
	parse_node *inv = Node::new(INVOCATION_NT);
	Node::set_text(inv, W);
	return inv;
}

@h What is invoked.
We can invoke either a "To..." phrase (by far the majority case), or a verb
or adjective to be printed using adaptive text. After an invocation node is
created, exactly one of these functions should be called on it:

=
void Invocations::invoke_To_phrase(parse_node *inv, id_body *idb) {
	if (inv == NULL) internal_error("tried to set phrase of null inv");
	Node::set_phrase_invoked(inv, idb);
}

void Invocations::invoke_adaptive_verb(parse_node *inv,
	verb_conjugation *vc, verb_conjugation *modal, int neg) {
	if (inv == NULL) internal_error("tried to set VC of null inv");
	Node::set_say_verb(inv, vc);
	Node::set_modal_verb(inv, modal);
	Annotations::write_int(inv, say_verb_negated_ANNOT, neg);
}

void Invocations::invoke_adaptive_adjective(parse_node *inv, adjective *aph) {
	if (inv == NULL) internal_error("tried to set ADJ of null inv");
	Node::set_say_adjective(inv, aph);
}

@h Unproven annotation.
When the //Dash// typechecker has to decide which invocation in a list is
the right one, it judges each one in turn. But there are three possible outcomes,
not two: as in Scottish law, the verdict can be guilty, not guilty, or "not
proven". An invocation which can be disproved is thrown out of the list; but of
the remainder, some are marked as proven to be correct, some as unproven.

Unproven means is that we cannot tell at compile-time whether the usage
is valid, but that we will be able to tell at run-time. Consider this
//notorious iteration -> https://en.wikipedia.org/wiki/Collatz_conjecture//:
= (text as Inform 7)
To decide which number is next after (N - an even number):
	let T be given by T = N/2 where T is a number;
	decide on T.
To decide which number is next after (N - an odd number):
	let T be given by T = 3N + 1 where T is a number;
	decide on T.
To begin:
	let N be a random number from 1 to 100;
	let M be 0;
	while M is not 1:
		now M is next after N;
		say "[N] goes to [M].";
		now N is M.
=
The difficulty here is the invocation "next after N". The compiler can prove
that N is of kind "number", but there is no way to know at compile-time whether
it will be even or odd: probably it will be sometimes even and sometimes odd.
In such cases, an invocation is marked "unproven". Unproven invocations are
allowed to compile, but require runtime checking code to be compiled.

=
void Invocations::mark_unproven(parse_node *inv) {
	Annotations::write_int(inv, unproven_ANNOT, TRUE);
}

int Invocations::is_marked_unproven(parse_node *inv) {
	return Annotations::read_int(inv, unproven_ANNOT);
}

@h Save self annotation.
This is less often used, and marks an invocation as needing its own implicit
understanding of what "self" -- i.e., the implied owner of a property -- is.
It's used for an invocation of a phrase to say a property value: see //Dash//.

=
void Invocations::mark_to_save_self(parse_node *inv) {
	Annotations::write_int(inv, save_self_ANNOT, TRUE);
}

int Invocations::is_marked_to_save_self(parse_node *inv) {
	return Annotations::read_int(inv, save_self_ANNOT);
}

@h Attaching tokens.
The "tokens" of a phrase are the flexibly-worded parts corresponding to the
bracketed clauses in its prototype. In:
= (text as Inform 7)
To advance (the piece - a chess piece) by (N - a number):
	...
=
the prototype is |advance (the piece - a chess piece) by (N - a number)|, and
an invocation of this should therefore have two tokens. For the invocation
|advance the pawn by 2|, those tokens will be |the pawn| and |2|.

Tokens are represented in the parse tree as children of the |INVOCATION_NT|
node:
= (text)
	INVOCATION_NT "advance the pawn by 2"
		RVALUE_CONTEXT_NT "the pawn"          <--- Node for token 0
			CONSTANT_NT "the pawn"            <--- Token as parsed
		RVALUE_CONTEXT_NT "2"                 <--- Node for token 1
			CONSTANT_NT "2"                   <--- Token as parsed
=
Each token node represents what we expect to find at that position, while its
child node represents what we actually found. Token nodes can have a variety
of types -- any of the |*_CONTEXT_NT| types -- reflecting the surprising range
of possibilities in phrase prototypes, but |RVALUE_CONTEXT_NT| is the commonest.

@ The following function might become more interesting if we ever allowed
variable-argument phrases like C's |printf|. Note that if an adaptive verb
or adjective is invoked, rather than a phrase, then this returns 0: there
are never any tokens in such cases.

=
int Invocations::get_no_tokens_needed(parse_node *inv) {
	if (inv == NULL) internal_error("tried to read NTI of null inv");
	if (Node::get_phrase_invoked(inv))
		return IDTypeData::get_no_tokens(
			&(Node::get_phrase_invoked(inv)->type_data));
	return 0;
}

int Invocations::get_no_tokens(parse_node *inv) {
	int C = 0;
	for (parse_node *tok = inv->down; tok; tok = tok->next) C++;
	return C;
}

@ Because the tokens are stored in this tree formation, access to them is slower
than it would be for an array lookup, but since phrases almost never have more
than 4 tokens this is irrelevant: clarity of the tree structure is more important.

=
parse_node *Invocations::get_token(parse_node *inv, int i) {
	int k = 0;
	for (parse_node *tok = inv->down; tok; tok = tok->next)
		if (k++ == i) return tok;
	return NULL;
}

@ Note that the following always returns a non-|NULL| pointer, or else throws
an internal error. If |inv| currently has 2 tokens and //Invocations::get_token_creating//
is asked for the 1000th, it will cheerfully add 999 |INVALID_NT| tokens to the
list, returning the last one.

=
parse_node *Invocations::get_token_creating(parse_node *inv, int i) {
	if (i<0) internal_error("tried to set token out of range");
	if (inv == NULL) internal_error("no invocation");
	if (inv->down == NULL) inv->down = Node::new(INVALID_NT);
	int k = 0;
	for (parse_node *tok = inv->down; tok; tok = tok->next) {
		if (k++ == i) return tok;
		if (tok->next == NULL) tok->next = Node::new(INVALID_NT);
	}
	return NULL; /* can never be reached, but needed because the compiler cannot prove this */
}

@ All tokens thus originate as |INVALID_NT|, but since the following function is
always used to create new tokens, they are immediately given a better type |t|:

=
void Invocations::attach_token(parse_node *inv, int i, node_type_t t, wording W) {
	parse_node *tok = Invocations::get_token_creating(inv, i);
	Node::set_type(tok, t);
	Node::set_text(tok, W);
}

@h Properties of tokens.
As noted above, each token has a child node representing what was actually found
in this position, called the "token as parsed":
=
void Invocations::set_token_as_parsed(parse_node *inv, int i, parse_node *val) {
	parse_node *tok = Invocations::get_token_creating(inv, i);
	tok->down = val;
}
parse_node *Invocations::get_token_as_parsed(parse_node *inv, int i) {
	parse_node *tok = Invocations::get_token(inv, i);
	if (tok) return tok->down;
	return NULL;
}

@ Other properties are stored as annotations of the token node. First, the
"kind required by context": for example, for a token going into the place of
|(X - an even number)| this kind will be "number".

=
void Invocations::set_kind_required_by_context(parse_node *inv, int i, kind *K) {
	parse_node *tok = Invocations::get_token_creating(inv, i);
	Node::set_kind_required_by_context(tok, K);
}
kind *Invocations::get_kind_required_by_context(parse_node *inv, int i) {
	parse_node *tok = Invocations::get_token(inv, i);
	if (tok) return Node::get_kind_required_by_context(tok);
	return NULL;
}

@ The "token to be parsed against" is the full description which must be matched;
for |(X - an even number)| this will be the specification "even number".

=
void Invocations::set_token_to_be_parsed_against(parse_node *inv, int i, parse_node *spec) {
	parse_node *tok = Invocations::get_token_creating(inv, i);
	Node::set_token_to_be_parsed_against(tok, spec);
}
parse_node *Invocations::get_token_to_be_parsed_against(parse_node *inv, int i) {
	parse_node *tok = Invocations::get_token(inv, i);
	if (tok) return Node::get_token_to_be_parsed_against(tok);
	return NULL;
}

@ The "token check to do" is a temporary calculational aid for the //Dash//
typechecker, when it's keeping track of what still has to be checked. If
//Dash// succeeds in proving that the token as parsed meets the test, then
the token check is cleared to |NULL|; but in the case of a "not proven"
verdict, the "token check to do" remains, and code must be generated to
perform this checking at runtime instead.

=
void Invocations::set_token_check_to_do(parse_node *inv, int i, parse_node *spec) {
	parse_node *tok = Invocations::get_token_creating(inv, i);
	Node::set_token_check_to_do(tok, spec);
}
parse_node *Invocations::get_token_check_to_do(parse_node *inv, int i) {
	parse_node *tok = Invocations::get_token(inv, i);
	if (tok) return Node::get_token_check_to_do(tok);
	return NULL;
}

@ Similarly, the "token variable kind" is a way for //Dash// to keep track of
the kind of any variable created by a token such as |(V - nonexisting variable)|.

=
void Invocations::set_token_variable_kind(parse_node *inv, int i, kind *K) {
	parse_node *tok = Invocations::get_token_creating(inv, i);
	Node::set_kind_of_new_variable(tok, K);
}
kind *Invocations::get_token_variable_kind(parse_node *inv, int i) {
	parse_node *tok = Invocations::get_token(inv, i);
	if (tok) return Node::get_kind_of_new_variable(tok);
	return NULL;
}

@h Attaching phrase options.
When necessary, and it usually isn't, an invocation has a packet of
details attached about any phrase options used; for instance, in

>> list the contents of the Box, with newlines;

this packet records the text "with newlines" along with its translation
as a run-time bitmap (with just one bit set, since only one option is used).

=
typedef struct invocation_options {
	int options; /* bitmap of any phrase options appended */
	struct wording options_invoked_text; /* text of any phrase options appended */
} invocation_options;

invocation_options *Invocations::create_invo(parse_node *inv) {
	invocation_options *invo = CREATE(invocation_options);
	invo->options_invoked_text = EMPTY_WORDING;
	invo->options = 0;
	Node::set_phrase_options_invoked(inv, invo);
	return invo;
}

void Invocations::set_phrase_options(parse_node *inv, wording W) {
	invocation_options *invo = Node::get_phrase_options_invoked(inv);
	if (invo == NULL) invo = Invocations::create_invo(inv);
	invo->options_invoked_text = W;
}

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
	if (further_bits != 0) {
		invocation_options *invo = Node::get_phrase_options_invoked(inv);
		if (invo == NULL) invo = Invocations::create_invo(inv);
		invo->options |= further_bits;
	}
}

@h Sort-of-equality.
The //Dash// typechecker occasionally needs to test whether two invocations
of phrases (never of adaptive text) are "equal" in the sense that they invoke
the same phrase, with tokens giving roughly the same interpretations of the
same source text.

=
int Invocations::same_phrase_and_tokens(parse_node *inv1, parse_node *inv2) {
	if (inv1 == inv2) return TRUE;
	if ((inv1) && (inv2 == NULL)) return FALSE;
	if ((inv1 == NULL) && (inv2)) return FALSE;

	if (Node::get_phrase_invoked(inv1) != Node::get_phrase_invoked(inv2)) return FALSE;
	if (Invocations::get_no_tokens(inv1) != Invocations::get_no_tokens(inv2)) return FALSE;

	for (int i=0; i<Invocations::get_no_tokens(inv1); i++) {
		parse_node *m1 = Invocations::get_token_to_be_parsed_against(inv1, i);
		parse_node *m2 = Invocations::get_token_to_be_parsed_against(inv2, i);
		if (Node::get_type(m1) != Node::get_type(m2)) return FALSE;
		parse_node *v1 = Invocations::get_token_as_parsed(inv1, i);
		parse_node *v2 = Invocations::get_token_as_parsed(inv2, i);
		if (Node::get_type(v1) != Node::get_type(v2)) return FALSE;
		if (Wordings::eq(Node::get_text(v1), Node::get_text(v2)) == FALSE) return FALSE;
	}
	return TRUE;
}

@h Logging.

=
void Invocations::log(parse_node *inv) {
	if (inv == NULL) { LOG("<null invocation>"); return; }
	if (inv->node_type != INVOCATION_NT) { LOG("<not an invocation>"); return; }
	char *verdict = Dash::verdict_to_text(inv);
	LOG("[%04d%s] %8s ",
		ToPhraseFamily::sequence_count(Node::get_phrase_invoked(inv)),
		(Invocations::is_marked_to_save_self(inv))?"-save-self":"", verdict);
	if (Node::get_say_verb(inv)) {
		LOG("verb:%d", Node::get_say_verb(inv)->allocation_id);
		if (Node::get_modal_verb(inv))
			LOG("modal:%d", Node::get_modal_verb(inv)->allocation_id);
	} else if (Node::get_say_adjective(inv)) {
		LOG("adj:%d", Node::get_say_adjective(inv)->allocation_id);
	} else {
		ImperativeDefinitions::log_body_fuller(Node::get_phrase_invoked(inv));
		for (int i=0; i<Invocations::get_no_tokens(inv); i++) {
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
