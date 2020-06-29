[Quantifiers::] Determiners and Quantifiers.

To create the determiners found in standard English which refer
to collections of things, and to create their meanings as logical quantifiers.

@h How these relate.
In logic, a "quantifier" appears at the front of a statement which can
apply to many cases, and describes the quantity of cases for which the
statement is true: all of them, some of them, exactly six, and so on.

When a quantifier is used, it "ranges over a domain". The domain is the
set of cases. For instance, in:

>> if most of the doors are open, ...

the "most of" text is parsed into a quantifier written in the debugging
log as |Proportion>50%|, and the domain is the set of all doors. We then
test the inner condition ("open") for the objects in the domain.

Some quantifiers apply to a proportion of the domain, and the proportion is
measured with a number we will call the $T$-coefficient, which is measured in
tenths. Thus a quantifier talking about the entire domain ("all of the
doors are open") will have $T=10$, while the "most of" example above has
$T=5$. Other quantifiers apply to an exact number, a "cardinality" in
logic jargon, rather than a proportion: for instance, "three doors are
open". These quantifiers have $T=-1$.

Finally, a few quantifiers apply not to the cases in the domain which
passed, but to those which didn't, and those are called "complementary"
(because they describe the complement of the domain set). For instance,
"all but six doors are open", where the "six" describes the number
of closed doors and not the number of open ones.

@ These different ways to describe multiple outcomes are represented in Inform by
//quantifier// structures. One exists for each different meaning supported
by Inform -- |ForAll|, |Exists| and so forth -- except that some quantifiers
take a numerical parameter, and a single //quantifier// structure represents
the meaning for any value of this parameter. For instance, the cardinality
quantifiers |Card=3| and |Card=17| are both represented by the same
quantifier structure, whose pointer is called |exactly_quantifier| below.
This is the result of parsing "exactly three" doors or "exactly 17"
containers, for instance, where the parameter is 3 or 17 respectively.

=
typedef struct quantifier {
	#ifdef CORE_MODULE
	inter_t operator_prim; /* inter opcode to compare successes against the threshold */
	#endif
	int T_coefficient; /* see above */
	int is_complementary; /* tests the complement of the set, not the set of matches */
	int can_be_used_in_now; /* can be asserted true or false using "now" */
	int can_be_used_in_assertions; /* can be used in assertion sentences */
	struct quantifier *negated_quant; /* the logically converse determiner */
	char *log_text; /* to be used in the debugging log when logging propositions */
	CLASS_DEFINITION
} quantifier;

@ The built-in set of 16 quantifiers, arranged in eight pairs, is as follows:

=
quantifier
	*for_all_quantifier = NULL,    *not_for_all_quantifier = NULL,
	*exists_quantifier = NULL,     *not_exists_quantifier = NULL,
	*all_but_quantifier = NULL,    *not_all_but_quantifier = NULL,
	*almost_all_quantifier = NULL, *almost_no_quantifier = NULL,
	*most_quantifier = NULL,       *under_half_quantifier = NULL,
	*at_least_quantifier = NULL,   *more_than_quantifier = NULL,
	*at_most_quantifier = NULL,    *less_than_quantifier = NULL,
	*exactly_quantifier = NULL,    *other_than_quantifier = NULL;

@ Whereas "quantifier" is a term from mathematical logic, "determiner"
is a term from linguistics which approximately -- but only approximately --
means the same thing.

The determiner is the part of a noun phrase, always its head, which gives
counting information to be combined with a common noun. Thus "the" clock,
"seven" seals, "almost all of the" open doors, and so on. When a
determiner appears to refer to a range of objects rather than a single
item, Inform translates it into a quantifier. Thus "the" clock is not parsed
into a quantifier, but "all but three" rooms is.

The same quantifier can have several different verbal forms. For instance,
"each" container and "every" container mean the same thing: both
apply the |ForAll| quantifier to containers. These different verbal forms
are stored in the |determiner| structure, and each one points to the
|quantifier| structure which is its meaning.

=
typedef struct determiner {
	int allows_prefixed_not; /* can the word "not" come before this? */
	struct word_assemblage text_of_det; /* which is allowed to be empty */
	int takes_number; /* does a number follow? (e.g. for "at least N" */
	struct quantifier *quantifier_meant; /* meaning of this quantifier */
	char *index_text; /* used in the Phrasebook index lexicon */
	CLASS_DEFINITION
} determiner;

@h Creating a quantifier.
At present, there's only the built-in set, and no method exists to create
new quantifiers from the source text or the template files, but what follows
is written so that it would be fairly easy to add this ability.

=
quantifier *Quantifiers::quant_new(text_stream *op, int T, int is_comp, char *text) {
	quantifier *quant = CREATE(quantifier);
	#ifdef CORE_MODULE
	if (Str::eq(op, I"=="))      quant->operator_prim = EQ_BIP;
	else if (Str::eq(op, I"~=")) quant->operator_prim = NE_BIP;
	else if (Str::eq(op, I">=")) quant->operator_prim = GE_BIP;
	else if (Str::eq(op, I">"))  quant->operator_prim = GT_BIP;
	else if (Str::eq(op, I"<=")) quant->operator_prim = LE_BIP;
	else if (Str::eq(op, I"<"))  quant->operator_prim = LT_BIP;
	else internal_error("unfamiliar operator");
	#endif

	quant->T_coefficient = T; quant->is_complementary = is_comp;
	quant->can_be_used_in_now = FALSE;
	quant->can_be_used_in_assertions = FALSE;
	quant->negated_quant = NULL;
	quant->log_text = text;
	return quant;
}

@ That fills out the whole structure except for the negation pointers, and
to ensure that these always occur in matched pairs, these are set here.

A little explanation may be useful about what we mean by negation. In
traditional logic, the basic quantifiers "for all" and "there exists"
are dual to each other in that they are related by a sort of negation:
"there does not exist an open door" means the same as "all doors are
closed", and so on. Thus

|Not ( ForAll x: P(x) )| is equivalent to |Exists x: Not(P(x))|

That isn't what we mean here. If $Q$ and $NQ$ are a quantifier and its
negation in our sense, then:

|Not ( Q x: P(x) )| is equivalent to |NQ x: P(x)|

Why do we do this? There are several reasons. First, we are using a richer
set of quantifiers than traditional logic provides, and most of these have
natural negations which we were going to be creating anyway -- so we may
as well exploit that. Second, we are going to try to represent propositions
using as much conjunction ("and") and as little disjunction ("or") as
possible. Consider what effect de Morgan's laws have if we simplify:

|Not ( ForAll x: closed(x) and locked(x) and lockable(x) )|

in the traditional way: we obtain

|Exists x: Not(closed(x)) or Not(locked(x)) or Not(lockable(x))|

which introduces disjunction ("or") in just the way we don't want. By
simply regarding |NotAll| as a quantifier in its own right, we obtain
something much easier to handle:

|NotAll x: closed(x) and locked(x) and lockable(x)|

This is why we will be creating quantifiers |NotAll| and |DoesNotExist| --
the negations of |ForAll| and |ThereExists| -- even though they might seem
puzzlingly redundant from a traditional logic point of view.

=
void Quantifiers::quants_negate_each_other(quantifier *qx, quantifier *qy) {
	qx->negated_quant = qy; qy->negated_quant = qx;
}
quantifier *Quantifiers::get_negation(quantifier *quant) {
	return quant->negated_quant;
}

@ Logging a quantifier:

=
void Quantifiers::log(quantifier *quant, int parameter) {
	if (quant == NULL) { LOG("<NULL-QUANTIFIER>"); return; }
	LOG(quant->log_text, parameter);
}

@h Acting on quantifiers.
When compiling code to test a proposition which includes a quantifier, we
need to test the cases in the domain set to see how many of them qualify
and how many do not. These counts are stored in local variables called
|qcy_0|, |qcn_0| and so on: |qcn| means "quantifier count number" and is
the size of the domain set, while |qcy| is the number of "yes" cases.
Thus if the original source text read:

>> if most of the closed doors are locked, ...

|qcy_0| will be the number of closed doors which turned out to be locked
and |qcn_0| the total number of closed doors. (The indices |_0|, |_1|, ...,
are used because the same routine may have to compile code to test several
quantifiers.)

The following routine compiles an I6 condition to test whether the
tallies are acceptable for the given quantifier. In the example above,
the quantifier is |Proportion>50%|, and compiles to the test:

|qcy_0 > 5*qcn_0/10|

(It looks a little wasteful to multiply by 5 and then divide by 10, but
I6 will fold that out in eventual code generation. When the proportion is
0/10ths or 10/10ths, though, we do generate simpler code, mostly so that
the resulting I6 is more legible.)

=
#ifdef CORE_MODULE
void Quantifiers::emit_test(quantifier *quant,
	int quantification_parameter, inter_symbol *qcy, inter_symbol *qcn) {

	Produce::inv_primitive(Emit::tree(), quant->operator_prim);
	Produce::down(Emit::tree());

	int TC = quant->T_coefficient;
	switch (TC) {
		case -1:
			if (quant->is_complementary) {
				Produce::val_symbol(Emit::tree(), K_value, qcy);
				Produce::inv_primitive(Emit::tree(), MINUS_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, qcn);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
						(inter_t) quantification_parameter);
				Produce::up(Emit::tree());
			} else {
				Produce::val_symbol(Emit::tree(), K_value, qcy);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL,
					(inter_t) quantification_parameter);
			}
			break;
		case 10:
			Produce::val_symbol(Emit::tree(), K_value, qcy);
			Produce::val_symbol(Emit::tree(), K_value, qcn);
			break;
		case 0:
			Produce::val_symbol(Emit::tree(), K_value, qcy);
			Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			break;
		default:
			if (quant->operator_prim != EQ_BIP) {
				Produce::inv_primitive(Emit::tree(), TIMES_BIP);
				Produce::down(Emit::tree());
					Produce::val_symbol(Emit::tree(), K_value, qcy);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
				Produce::up(Emit::tree());
				Produce::inv_primitive(Emit::tree(), TIMES_BIP);
				Produce::down(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) TC);
					Produce::val_symbol(Emit::tree(), K_value, qcn);
				Produce::up(Emit::tree());
			} else {
				Produce::val_symbol(Emit::tree(), K_value, qcy);
				Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
				Produce::down(Emit::tree());
					Produce::inv_primitive(Emit::tree(), TIMES_BIP);
					Produce::down(Emit::tree());
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) TC);
						Produce::val_symbol(Emit::tree(), K_value, qcn);
					Produce::up(Emit::tree());
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
				Produce::up(Emit::tree());
			}
			break;
	}
	Produce::up(Emit::tree());
}
#endif

@ "Now" is the Inform way to assert that a proposition should now be made
true. Many quantifiers obstruct this, by introducing too much vagueness.
For instance, "now three doors are open" is dangerously vague because it
doesn't say which doors are to be made open; similarly "now most of the
coins are in the box". On the other hand, "now all the coins are in the
box" is fine, because there's no ambiguity. The |can_be_used_in_now| flag for
a quantifier shows whether it can be asserted in "now" like this.

=
int Quantifiers::is_now_assertable(quantifier *quant) {
	return quant->can_be_used_in_now;
}

@ Not every proposition can be used in assertion sentences, either, and
again it's the quantifiers which cause the trouble. For instance, "Not
every room is dark." gives Inform too little to act on. Which room(s)
should it make lighted?

=
int Quantifiers::can_be_used_in_assertions(quantifier *quant) {
	return quant->can_be_used_in_assertions;
}

@h Creating a determiner.
Again, at present there's only the built-in set, but we want to keep our
options open.

@d ALL_DET_NAME 0
@d EACH_DET_NAME 1
@d EVERY_DET_NAME 2
@d NO_DET_NAME 3
@d NONE_DET_NAME 4
@d SOME_DET_NAME 5
@d ANY_DET_NAME 6
@d ALL_BUT_DET_NAME 7
@d ALL_EXCEPT_DET_NAME 8
@d ALMOST_ALL_DET_NAME 9
@d ALMOST_NO_DET_NAME 10
@d MOST_DET_NAME 11
@d UNDER_HALF_DET_NAME 12
@d AT_LEAST_DET_NAME 13
@d AT_MOST_DET_NAME 14
@d EXACTLY_DET_NAME 15
@d FEWER_THAN_DET_NAME 16
@d LESS_THAN_DET_NAME 17
@d MORE_THAN_DET_NAME 18
@d GREATER_THAN_DET_NAME 19
@d OTHER_THAN_DET_NAME 20

=
determiner *Quantifiers::det_new(int not, int pr, int num, quantifier *quant, char *text) {
	word_assemblage wa;
	if (pr < 0) wa = WordAssemblages::lit_0();
	else wa = PreformUtilities::wording(<determiner-names>, pr);
	determiner *det = CREATE(determiner);
	det->text_of_det = wa;
	det->takes_number = num;
	det->allows_prefixed_not = not;
	det->quantifier_meant = quant;
	if (quant == NULL) internal_error("created meaningless quantifier");
	det->index_text = text;
	#ifdef CORE_MODULE
	if (text)
		IndexLexicon::new_entry_with_details(
			EMPTY_WORDING, MISCELLANEOUS_LEXE, wa, "determiner", text);
	#endif
	return det;
}

@ Inform supports a built-in set of sixteen generalised quantifiers, in
logical terms, and English maps onto these with a rather less elegantly
structured set of twenty wordings. One of these doesn't appear below because
it's empty of text: this is the determiner in "three blind mice", where
no text appears in front of the number "three".

=
<determiner-names> ::=
	all |
	each |
	every |
	no |
	none |
	some |
	any |
	all but |
	all except |
	almost all |
	almost no |
	most |
	under half |
	at least |
	at most |
	exactly |
	fewer than |
	less than |
	more than |
	greater than |
	other than

@h Parsing the determiner at the head of a noun phrase.
We run through the possible determiners in reverse creation order, choosing the
first which matches. The following returns $-1$ if nothing was found, or
else the first word number after the determiner words, and in that case
it also writes a pointer to the quantifier meant to |*which_quant| and the
parameter value to |*which_P|.

(Reverse order is used really only to make sure "all but" and "all except"
are tried before "all".)

=
int Quantifiers::parse_against_text(wording W, int *which_P, quantifier **which_quant) {
	if (<excluded-from-determiners>(W)) return -1;
	int not_flag = <negated-clause>(W);
	if (not_flag) W = GET_RW(<negated-clause>, 1);

	*which_P = -1; *which_quant = NULL;

	determiner *det;
	LOOP_BACKWARDS_OVER(det, determiner) {
		if ((not_flag) && (det->allows_prefixed_not == FALSE)) continue;
		wording XW = Quantifiers::det_parse_against_text(W, det, which_P);
		if (Wordings::nonempty(XW)) {
			if (not_flag) *which_quant = det->quantifier_meant->negated_quant;
			else *which_quant = det->quantifier_meant;
			return Wordings::first_wn(XW);
		}
	}
	return -1;
}

@ We look for a determiner at the start of a noun phrase; this can sometimes
be followed by a number. For example,

>> More than three doors

matches "more than" from the selection above, then the number "three".
It's legal to include "of the":

>> three of the doors are open

but not "of" on its own: this reduces misunderstandings when objects have
names like "three of clubs", meaning a single playing card.

=
<determination-of> ::=
	of the ... |    ==> TRUE
	of ... |    ==> TRUE; return FAIL_NONTERMINAL
	...					==> TRUE

@ English has an awkward ambiguity here: what does this mean?

>> no one

Inform would normally read this as the determiner "no" followed by the
number "one", not realising that "one" is more likely to refer to a
kind (i.e., people and not things) rather than counting something. We want
to stop this reading, so that we can read "no one" as if it were "nobody".

The following grammar is provided to list noun phrases which will be immune
from determiner parsing:

=
<excluded-from-determiners> ::=
	no one ***

@ We attempt to see if the word range begins with (or consists of) text which
refers to the given determiner, returning the first word past this text and
also (where appropriate) setting the number specified. For instance, for
"at least three doors are open" and the |at_least_determiner| we would
return the word "doors" and set |which_P| to 3.

=
wording Quantifiers::det_parse_against_text(wording W, determiner *det, int *which_P) {
	int parameter = -1;
	if (Wordings::empty(W)) return W;
	int x = WordAssemblages::parse_as_weakly_initial_text(W, &(det->text_of_det),
		EMPTY_WORDING, TRUE, FALSE);
	W = Wordings::from(W, x);
	if (Wordings::empty(W)) return W;
	if (det->takes_number) {
		if ((<cardinal-number>(Wordings::one_word(x)) == FALSE) ||
			(Word::unexpectedly_upper_case(x))) return EMPTY_WORDING;
		W = Wordings::trim_first_word(W);
		if (Wordings::empty(W)) return W;
		parameter = <<r>>;
	}
	if (<determination-of>(W)) {
		W = GET_RW(<determination-of>, 1);
		*which_P = parameter;
		W = Articles::remove_the(W);
	} else W = EMPTY_WORDING;
	return W;
}

@h The built-in set.
We now construct both the tidy logical world of 16 quantifiers in matched
pairs, and also a higgledy-piggledy world of 20 English-language determiners
referring to them. There are four broad families which we take in turn.

=
void Quantifiers::make_built_in(void) {
	@<Make traditional quantification determiners@>;
	@<Make complement comparison determiners@>;
	@<Make proportion determiners@>;
	@<Make cardinality quantification determiners@>;
}

@ As discussed above, the two traditional quantifiers in logic are "for
all" and "there exists", usually written in mathematical notation as
$\forall$ and $\exists$, but we also need to create their negation
quantifiers. So we end up with four: |ForAll|, |NotAll|, |Exists| and
|DoesNotExist|.

The for-all quantifier can be used in assertions for a slightly oddball
reason: it's how the source text makes assemblies. For instance,

>> A nose is part of every person.

The "every" is parsed as a use of |ForAll|. Strictly speaking this
sentence should be read as creating a single nose which would be shared
by all of the people. But the presence of a |ForAll| quantifier in an
assertion causes the A-parser to interpret the sentence differently, and to
create a fresh nose for each person. (There are some restrictions on the
use of |ForAll| in this way, but they are enforced in the A-parser: our
part here is simply to authorise |ForAll| in assertions.)

Something which English allows, but Inform does not, is the use of "all"
in a way which also specifies a cardinality. For instance, the following
condition:

>> if all six doors are open, ...

is an attempt to use a determiner which Inform does not possess -- "all"
plus number. We don't allow this because if there happen to be eight doors,
say, the condition would be meaningless.

It's an example of the irregularity of English that you can say "not every
door is open" but would never say "not each door is open". In all other
respects "each" and "every" are synonymous in the S-parser.

@<Make traditional quantification determiners@> =
	for_all_quantifier     = Quantifiers::quant_new(I"==", 10, FALSE, "ForAll");
	not_for_all_quantifier = Quantifiers::quant_new(I"<", 10, FALSE, "NotAll");
	exists_quantifier      = Quantifiers::quant_new(I">", 0, FALSE, "Exists");
	not_exists_quantifier  = Quantifiers::quant_new(I"==", 0, FALSE, "DoesNotExist");

	for_all_quantifier->can_be_used_in_now = TRUE;
	for_all_quantifier->can_be_used_in_assertions = TRUE;
	not_exists_quantifier->can_be_used_in_now = TRUE;

	Quantifiers::quants_negate_each_other(for_all_quantifier, not_for_all_quantifier);
	Quantifiers::quants_negate_each_other(exists_quantifier, not_exists_quantifier);

	Quantifiers::det_new(TRUE, ALL_DET_NAME, FALSE, for_all_quantifier,
		"used in conditions: 'if all of the doors are open'");
	Quantifiers::det_new(FALSE, EACH_DET_NAME, FALSE, for_all_quantifier,
		"- see </i>all<i>");
	Quantifiers::det_new(TRUE, EVERY_DET_NAME, FALSE, for_all_quantifier,
		"- see </i>all<i>, and can also be used in generalisations such as "
		"'A nose is part of every person.'");
	Quantifiers::det_new(FALSE, NO_DET_NAME, FALSE, not_exists_quantifier,
		"opposite of 'all': 'if no door is open...'");
	Quantifiers::det_new(FALSE, NONE_DET_NAME, FALSE, not_exists_quantifier,
		"opposite of 'all of': 'if none of the doors is open...'");
	Quantifiers::det_new(FALSE, SOME_DET_NAME, FALSE, exists_quantifier, NULL);
	Quantifiers::det_new(FALSE, ANY_DET_NAME, FALSE, exists_quantifier, NULL);

@ Here $T=-1$, because we are counting actual numbers of matches rather than
a proportion of matches. But these quantifiers count downwards from the total:
thus "all but six" means there have to be exactly $S-6$ matching items,
where $S$ is the total available. The only logical negation for this
quantifier would be "other than $S-6$", which is too unnatural a
construction to have any natural English paraphrase, so we do not make a
|determiner *| structure pointing to it. But we create it in order that the
built-in quantifiers all occur in negation pairs.

@<Make complement comparison determiners@> =
	all_but_quantifier     = Quantifiers::quant_new(I"==", -1, TRUE, "AllBut%d");
	not_all_but_quantifier = Quantifiers::quant_new(I"~=", -1, TRUE, "NotAllBut%d");

	Quantifiers::quants_negate_each_other(all_but_quantifier, not_all_but_quantifier);

	Quantifiers::det_new(FALSE, ALL_BUT_DET_NAME, TRUE, all_but_quantifier,
		"used to count things: 'all but three containers'");
	Quantifiers::det_new(FALSE, ALL_EXCEPT_DET_NAME, TRUE, all_but_quantifier,
		"- see </i>all but<i>");

@ Here the $T$-coefficient, measuring the proportion needed, has $0 < T < 10$.

We don't support the determiner "half", as in, "if half the doors are open",
because it's ambiguous as to whether it means exactly half or half-or-more.

@<Make proportion determiners@> =
	almost_all_quantifier  = Quantifiers::quant_new(I">=", 8, FALSE, "Proportion>=80%%");
	almost_no_quantifier   = Quantifiers::quant_new(I"<",  2, FALSE, "Proportion<20%%");
	most_quantifier        = Quantifiers::quant_new(I">",  5, FALSE, "Proportion>50%%");
	under_half_quantifier  = Quantifiers::quant_new(I"<=", 5, FALSE, "Proportion<=50%%");

	Quantifiers::quants_negate_each_other(almost_all_quantifier, almost_no_quantifier);
	Quantifiers::quants_negate_each_other(most_quantifier, under_half_quantifier);

	Quantifiers::det_new(FALSE, ALMOST_ALL_DET_NAME, FALSE, almost_all_quantifier,
		"used in conditions: true if 80 percent or more possibilities work");
	Quantifiers::det_new(FALSE, ALMOST_NO_DET_NAME, FALSE, almost_no_quantifier,
		"used in conditions: true if fewer than 20 percent of possibilities work");
	Quantifiers::det_new(FALSE, MOST_DET_NAME, FALSE, most_quantifier,
		"used in conditions: true if a simple majority of possibilities work");
	Quantifiers::det_new(FALSE, UNDER_HALF_DET_NAME, FALSE, under_half_quantifier,
		"used in conditions: true if fewer than half of possibilities work");

@ The usefulness of cardinality quantifiers in logic as applied to
linguistics seems to be an observation due to Barwise and Cooper. They are
a natural generalisation of the for-all and there-exists quantifiers, and
again come in matched pairs.

The bare number determiner, as in "six doors are open", is perhaps a little
ambiguous in English. We read it as "at least six doors are open", in
distinction to "exactly six doors are open". This is why the at-least
quantifier is allowed in assertions: the assertion sentence "Four coins are
in the strongbox." is read as containing the |Card>=4| quantifier, not
|Card=4| one. The advantage of this is that two assertions in a row, such
as

>> Four coins are in the strongbox. Two coins are in the strongbox.

can combine to put six coins in the strongbox, rather than having to be
read as contradictory. (It may look improbable that anyone would ever
write that, but of course the two assertions need not be adjacent in
the source text. One might be in an extension, for instance.)

@<Make cardinality quantification determiners@> =
	at_least_quantifier    = Quantifiers::quant_new(I">=", -1, FALSE, "Card>=%d");
	at_most_quantifier     = Quantifiers::quant_new(I"<=", -1, FALSE, "Card<=%d");
	exactly_quantifier     = Quantifiers::quant_new(I"==", -1, FALSE, "Card=%d");
	less_than_quantifier   = Quantifiers::quant_new(I"<",  -1, FALSE, "Card<%d");
	more_than_quantifier   = Quantifiers::quant_new(I">",  -1, FALSE, "Card>%d");
	other_than_quantifier  = Quantifiers::quant_new(I"~=", -1, FALSE, "Card~=%d");

	at_least_quantifier->can_be_used_in_assertions = TRUE;

	Quantifiers::quants_negate_each_other(at_least_quantifier, less_than_quantifier);
	Quantifiers::quants_negate_each_other(at_most_quantifier, more_than_quantifier);
	Quantifiers::quants_negate_each_other(exactly_quantifier, other_than_quantifier);

	Quantifiers::det_new(FALSE, AT_LEAST_DET_NAME, TRUE, at_least_quantifier,
		"used to count things: 'at least five doors'");
	Quantifiers::det_new(FALSE, AT_MOST_DET_NAME, TRUE, at_most_quantifier,
		"- see </i>at least<i>");
	Quantifiers::det_new(FALSE, EXACTLY_DET_NAME, TRUE, exactly_quantifier,
		"whereas 'if two doors are open' implicitly means 'if at least two "
		"doors are open', 'if exactly two...' makes the count precise");
	Quantifiers::det_new(TRUE, FEWER_THAN_DET_NAME, TRUE, less_than_quantifier,
		"pedantic way to say </i>less than<i> when counting");
	Quantifiers::det_new(TRUE, LESS_THAN_DET_NAME, TRUE, less_than_quantifier,
		"- see </i>more than<i>");
	Quantifiers::det_new(TRUE, MORE_THAN_DET_NAME, TRUE, more_than_quantifier,
		"used to count things: 'more than three rooms'");
	Quantifiers::det_new(TRUE, GREATER_THAN_DET_NAME, TRUE, more_than_quantifier,
		"used to count things: 'greater than three rooms'");
	Quantifiers::det_new(FALSE, OTHER_THAN_DET_NAME, TRUE, other_than_quantifier, NULL);

	Quantifiers::det_new(FALSE, -1, TRUE, at_least_quantifier, NULL);

@ The following question is relevant when simplifying propositions:

=
int Quantifiers::quant_requires_at_least_one_true_case(quantifier *quant, int parameter) {
	if (quant == exists_quantifier) return TRUE;
	if (((quant == exactly_quantifier) || (quant == at_least_quantifier)) &&
		(parameter > 0)) return TRUE;
	if ((quant == more_than_quantifier) && (parameter >= 0)) return TRUE;
	if ((quant == other_than_quantifier) && (parameter == 0)) return TRUE;
	return FALSE;
}
