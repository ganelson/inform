[Kinds::Textual::] Describing Kinds.

Translating kinds to and from textual descriptions.

@h The K-grammar.
This is a Preform grammar for textual descriptions of kinds. In effect it's
a mini-language of its own, with a specification closer to traditional
computer-science norms than Inform's free-wheeling approach -- this is not
an accident. It allows for awkward functional-programming needs in a way
which vaguer natural language syntax would not.

All K-grammar nonterminals begin with the "k-" prefix, and their pointer results
are to //kind//| structures.

@ For speed, we parse some kind names as single words, and others as common
nouns, which is slower:

@d KIND_SLOW_MC   0x00000008 /* e.g., |weight| */
@d KIND_FAST_MC   0x01000000 /* number, text, relation, rule, ... */

@ The K-grammar actually has two modes: normal, and phrase-token-mode. Normal
mode is aptly named: it's almost always the one we're using. Phrase token
mode is used only when parsing definitions of phrases, like so:

>> To repeat with (LV - nonexisting K variable) running from (V1 - arithmetic value of kind K) to (V2 - K)

Here the tokens "nonexisting K variable" and so on are parsed as
specifications, but in such a way that any kinds mentioned are parsed in
phrase-token-mode. The difference is that this enables them to refer to kind
variables such as K which are still being defined; in normal mode, that would
only be allowed if K already existed.

@d NORMAL_KIND_PARSING 1
@d PHRASE_TOKEN_KIND_PARSING 2

=
int kind_parsing_mode = NORMAL_KIND_PARSING;

@ This tests which mode we are in, consuming no words:

=
<if-parsing-phrase-tokens> internal 0 {
	if (kind_parsing_mode != NORMAL_KIND_PARSING) return TRUE;
	==> { fail nonterminal };
}

@ And the following internal is in fact only <k-kind> but inside phrase
token parsing mode; it's used when parsing the kind to be decided by a
phrase (which, like phrase tokens, can involve the variables).

=
<k-kind-prototype> internal {
	int s = kind_parsing_mode;
	kind_parsing_mode = PHRASE_TOKEN_KIND_PARSING;
	int t = <k-kind>(W);
	kind_parsing_mode = s;
	if (t) { ==> { -, <<rp>> }; return TRUE; }
	==> { fail nonterminal };
}

@ And here is that "name of kind..." construction, which is valid only in
phrase tokens.

=
<k-kind-as-name-token> ::=
	( <k-kind-as-name-token> ) |             ==> { pass 1 }
	name of kind of <k-kind-abbreviating> |  ==> { pass 1 }
	name of kind <k-kind-abbreviating> |     ==> { pass 1 }
	name of kind of ... |                    ==> { -, NULL }
	name of kind ...                         ==> { -, NULL }

<k-kind-abbreviating> ::=
	( <k-kind-abbreviating> ) |              ==> { pass 1 }
	<k-kind-of-kind> <k-formal-variable> |   ==> { -, Kinds::var_construction(R[2], RP[1]) }
	<k-kind>                                 ==> { pass 1 }

@ So now we can begin properly. Every valid kind matches <k-kind>:

=
<k-kind> ::=
	( <k-kind> ) |                                        ==> { pass 1 }
	^<if-parsing-phrase-tokens> <k-kind-variable> |       ==> { pass 2 }
	<if-parsing-phrase-tokens> <k-variable-definition> |  ==> { pass 2 }
	<k-base-kind> |                                       ==> { pass 1 }
	<k-irregular-kind-construction> |                     ==> { pass 1 }
	<k-kind-construction>                                 ==> { pass 1 }

@ And, as a convenient shorthand:

=
<k-kind-articled> ::=
	<indefinite-article> <k-kind> |  ==> { pass 2 }
	<k-kind>                         ==> { pass 1 }

@ In phrase-token mode, kind variables are treated as formal symbols, not as
the kinds which are their current values:

=
<k-variable-definition> ::=
	<k-formal-variable> |                         ==> { pass 1 }
	<k-kind-of-kind> of kind <k-formal-variable>  ==> { -, Kinds::var_construction(R[2], RP[1]) }

@ Some base kinds with one-word names have that word flagged with a direct
pointer to the kind, for speed of parsing. Names of base kinds, such as
|number| or |vehicle|, can be registered in two different ways (according
to whether they come from the source text or from template files), so we then
make two further checks:

=
<k-base-kind> internal {
	kind *K = NULL;
	if (Wordings::empty(W)) { ==> { fail nonterminal }; }
	if (Wordings::length(W) == 1)
		K = Kinds::read_kind_marking_from_vocabulary(Lexer::word(Wordings::first_wn(W)));
	if (K == NULL) {
		if (<definite-article>(Wordings::first_word(W))) { ==> { fail nonterminal }; }
		parse_node *p = Lexicon::retrieve(KIND_SLOW_MC, W);
		if (p) {
			excerpt_meaning *em = Node::get_meaning(p);
			general_pointer m = Lexicon::get_data(em);
			if (m.run_time_type_code == noun_usage_CLASS) {
				noun_usage *nu = RETRIEVE_POINTER_noun_usage(m);
				m = nu->noun_used->meaning;
			}
			K = Kinds::base_construction(RETRIEVE_POINTER_kind_constructor(m));
		} else {
			p = Lexicon::retrieve(NOUN_MC, W);
			if (p) {
				noun_usage *nu = Nouns::disambiguate(p, TRUE);
				noun *nt = (nu)?(nu->noun_used):NULL;
				if (nt) K = Kinds::base_construction(
					RETRIEVE_POINTER_kind_constructor(Nouns::meaning(nt)));
			}
		}
	}
	if (K) { ==> { -, K }; return TRUE; }
	==> { fail nonterminal };
}

@ "Object based rulebook" has been on a voyage of unhyphenation: in the early
public beta of Inform 7, it was "object-based-rulebook" (at that time,
built-in kinds had to have one-word names); then it became "object-based
rulebook", when one-word adjectives were allowed to modify the names of
built-in kinds; and now it is preferably "object based rulebook". But the
previous syntax is permitted as an alias to keep old source text working. And
similarly for the others here, except "either-or property", which is a 2010
addition.

=
<k-irregular-kind-construction> ::=
	indexed text |                                                   ==> { -, K_text }
	indexed texts |                                                  ==> { -, K_text }
	stored action |                                                  ==> @<Stored action@>
	stored actions |                                                 ==> @<Stored action@>
	object-based rulebook producing <indefinite-article> <k-kind> |  ==> @<Rulebook obj on 2@>
	object-based rulebook producing <k-kind> |                       ==> @<Rulebook obj on 1@>
	object-based rulebook |                                          ==> @<Rulebook obj on void@>
	action-based rulebook |                                          ==> @<Action rulebook@>
	object-based rule producing <indefinite-article> <k-kind> |      ==> @<Rule obj on 2@>
	object-based rule producing <k-kind> |                           ==> @<Rule obj on 1@>
	object-based rule |                                              ==> @<Rule obj on void@>
	action-based rule |                                              ==> @<Action rule@>
	either-or property                                               ==> @<Property on truth state@>

@<Stored action@> =
	#ifdef IF_MODULE
	if (K_stored_action == NULL) { ==> { fail production }; }
	==> { -, K_stored_action };
	#endif
	#ifndef IF_MODULE
	==> { fail production };
	#endif

@<Rulebook obj on 2@> =
	==> { -, Kinds::binary_con(CON_rulebook, K_object, RP[2]) }

@<Rulebook obj on 1@> =
	==> { -, Kinds::binary_con(CON_rulebook, K_object, RP[1]) }

@<Rulebook obj on void@> =
	==> { -, Kinds::binary_con(CON_rulebook, K_object, K_void) }

@<Action rulebook@> =
	#ifdef IF_MODULE
	if (K_action_name == NULL) { ==> { fail production }; }
	==> { -, Kinds::binary_con(CON_rulebook, K_action_name, K_void) };
	#endif
	#ifndef IF_MODULE
	==> { fail production };
	#endif

@<Rule obj on 2@> =
	==> { -, Kinds::binary_con(CON_rule, K_object, RP[2]) }

@<Rule obj on 1@> =
	==> { -, Kinds::binary_con(CON_rule, K_object, RP[1]) }

@<Rule obj on void@> =
	==> { -, Kinds::binary_con(CON_rule, K_object, K_void) }

@<Action rule@> =
	#ifdef IF_MODULE
	if (K_action_name == NULL) { ==> { fail production }; }
	==> { -, Kinds::binary_con(CON_rule, K_action_name, K_void) };
	#endif
	#ifndef IF_MODULE
	==> { fail production };
	#endif

@<Property on truth state@> =
	==> { -, Kinds::unary_con(CON_property, K_truth_state) }

@ This loop looks a little slow, but there are only about 10 proper constructors.

=
<k-kind-construction> internal {
	kind_constructor *con;
	LOOP_OVER(con, kind_constructor)
		if (KindConstructors::arity(con) > 0) {
			wording X = W;
			wording Y = EMPTY_WORDING;
			if (Kinds::Textual::parse_constructor_name(con, &X, &Y))
				@<See if this partial kind-constructor match works out@>;
		}
	==> { fail nonterminal };
}

@ So at this point we have a match of the fixed words in the constructor.
For example, we might have "list of ...", where the X excerpt represents
the "..." and the Y excerpt is empty; or "... based rule producing ...",
where both X and Y are non-empty; or even something like "relation",
where both X and Y are empty.

We try to match X and Y against kinds, filling in defaults if either is
unspecified because a short form of the constructor is used (e.g.,
"relation" instead of "relation of ..." or "relation of ... to ...").

@<See if this partial kind-constructor match works out@> =
	kind *KX = K_value, *KY = K_value;
	if (con->variance[0] == CONTRAVARIANT)
		KX = K_nil;
	if ((KindConstructors::arity(con) == 2) && (con->variance[1] == CONTRAVARIANT))
		KY = K_nil;

	@<The rule and rulebook constructors default to actions for X@>;
	if (Wordings::nonempty(X)) {
		int tupling = KindConstructors::tupling(con, 0);
		if ((tupling == 0) && (<k-single-term>(X))) KX = <<rp>>;
		else if ((tupling == 1) && (<k-optional-term>(X))) KX = <<rp>>;
		else if ((tupling >= 2) && (<k-tupled-term>(X))) KX = <<rp>>;
		else KX = NULL;
	}
	if (Wordings::nonempty(Y)) {
		int tupling = KindConstructors::tupling(con, 1);
		if ((tupling == 0) && (<k-single-term>(Y))) KY = <<rp>>;
		else if ((tupling == 1) && (<k-optional-term>(Y))) KY = <<rp>>;
		else if ((tupling >= 2) && (<k-tupled-term>(Y))) KY = <<rp>>;
		else KY = NULL;
	}
	@<The relation constructor defaults to Y matching X, if X is specified@>;

	if ((KindConstructors::arity(con) == 1) && (KX)) {
		==> { -, Kinds::unary_con(con, KX) }; return TRUE;
	}
	if ((KindConstructors::arity(con) == 2) && (KX) && (KY)) {
		==> { -, Kinds::binary_con(con, KX, KY) }; return TRUE;
	}

@ Ordinarily missing X or Y are filled in as "value", but...

@<The rule and rulebook constructors default to actions for X@> =
	if ((con == CON_rule) || (con == CON_rulebook)) {
		#ifdef IF_MODULE
		if (K_action_name) KX = K_action_name; else KX = K_void;
		#endif
		#ifndef IF_MODULE
		KX = K_void;
		#endif
		KY = K_void;
	}

@ And...

@<The relation constructor defaults to Y matching X, if X is specified@> =
	if ((con == CON_relation) && (Wordings::empty(Y))) KY = KX;

@ Where the materials used in construction are not quite kinds, but can
be more varied.

=
<k-single-term> ::=
	( <k-single-term> ) |              ==> { pass 1 }
	<article> <k-single-term> |        ==> { pass 2 }
	<k-kind>                           ==> { pass 1 }

<k-optional-term> ::=
	( <k-optional-term> ) |            ==> { pass 1 }
	<article> <k-optional-term> |      ==> { pass 2 }
	nothing |                          ==> { -, K_nil }
	action |                           ==> @<The action term@>
	<k-kind>                           ==> { pass 1 }

<k-tupled-term> ::=
	( <k-tuple-list> ) |               ==> { pass 1 }
	nothing |                          ==> { -, K_void }
	<k-single-term>                    ==> { -, Kinds::binary_con(CON_TUPLE_ENTRY, RP[1], K_void) }

<k-tuple-list> ::=
	<k-single-term> , <k-tuple-list> | ==> { -, Kinds::binary_con(CON_TUPLE_ENTRY, RP[1], RP[2]) }
	<k-single-term>                    ==> { -, Kinds::binary_con(CON_TUPLE_ENTRY, RP[1], K_void) }

@<The action term@> =
	#ifdef IF_MODULE
	==> { -, K_action_name };
	#endif
	#ifndef IF_MODULE
	==> { fail production };
	#endif
	
@ The following looks at a word range and tries to find text making a kind
construction: if it does, it adjusts the word ranges to the kind(s) being
constructed on, and returns |TRUE|; if it fails, it returns |FALSE|. For
instance, given "list of marbles", it adjusts the word range to "marbles"
and returns |TRUE|.

=
int Kinds::Textual::parse_constructor_name(kind_constructor *con, wording *KW, wording *LW) {
	wording W = *KW;
	for (int p=1; p<=2; p++) {
		wording NW = KindConstructors::get_name(con, (p==1)?FALSE:TRUE);
		if (Wordings::nonempty(NW)) {
			int full_length = Wordings::length(NW);
			int k1 = Wordings::first_wn(NW);
			*KW = EMPTY_WORDING; *LW = EMPTY_WORDING;
			@<Try this as a constructor name@>;
		}
	}
	*KW = EMPTY_WORDING; *LW = EMPTY_WORDING;
	return FALSE;
}

@ Note that the name text for a constructor is likely to have a form like so:
= (text)
	relation STROKE relation of k to l STROKE relation of k
=
with multiple possibilities divided by strokes; each possibility must be
checked for.

@<Try this as a constructor name@> =
	int base = 0, length = full_length;
	int k;
	for (k=0; k<full_length; k++)
		if (Lexer::word(k1+k) == STROKE_V) {
			length = k - base;
			if (length > 0) @<Try one option among the constructor's names@>;
			base = k+1;
		}
	length = full_length - base;
	if (length > 0) @<Try one option among the constructor's names@>;

@<Try one option among the constructor's names@> =
	if (Wordings::length(W) >= length) {
		int i, p, failed = FALSE;
		for (i=0, p=Wordings::first_wn(W); i<length; i++) {
			vocabulary_entry *ve = Lexer::word(k1+base+i);
			if ((ve == CAPITAL_K_V) || (ve == CAPITAL_L_V)) {
				int from = p;
				if (i == length-1) { p = Wordings::last_wn(W)+1; }
				else {
					int bl = 0;
					while (p <= Wordings::last_wn(W)) {
						vocabulary_entry *nw = Lexer::word(p);
						if (nw == OPENBRACKET_V) bl++;
						else if (nw == CLOSEBRACKET_V) bl--;
						else if (bl == 0) {
							if (nw == Lexer::word(k1+base+i+1)) break;
						}
						p++;
					}
					if (p > Wordings::last_wn(W)) { failed = TRUE; break; }
				}
				if (ve == CAPITAL_K_V) { *KW = Wordings::new(from, p-1); }
				else { *LW = Wordings::new(from, p-1); }
			} else {
				if (ve != Lexer::word(p++)) { failed = TRUE; break; }
			}
		}
		if (p != Wordings::last_wn(W)+1) failed = TRUE;
		if (failed == FALSE) return TRUE;
	}

@h Kinds of kind.
This is actually just <k-kind> in disguise, but only lets the result through
if it's a kind of kind, like "arithmetic value"; something like "number"
or "list of texts" will fail.

=
<k-kind-of-kind> ::=
	<k-kind>		==> { pass 1 }; if (Kinds::Behaviour::is_kind_of_kind(RP[1]) == FALSE) return FALSE;

@h Parsing kind variables.
As a small detour, here's how we deal with the pleasingly simple names A to Z
for kind variables, converting them to and from the numbers 1 to 26:

=
int Kinds::Textual::parse_variable(vocabulary_entry *ve) {
	if (ve == NULL) return 0;
	return Kinds::Textual::parse_kind_variable_name(
		Vocabulary::get_exemplar(ve, TRUE), TRUE);
}

int Kinds::Textual::parse_kind_variable_name(wchar_t *p, int allow_lower) {
	if (p == NULL) return 0;
	if ((p[1] == 0) || ((p[1] == 's') && (p[2] == 0))) {
		if ((p[0] >= 'A') && (p[0] <= 'Z')) return p[0] - 'A' + 1;
		if ((allow_lower) && (p[0] >= 'a') && (p[0] <= 'z')) return p[0] - 'a' + 1;
	}
	return 0;
}

int Kinds::Textual::parse_kind_variable_name_singular(wchar_t *p) {
	if ((p) && (p[1] == 0) && (p[0] >= 'A') && (p[0] <= 'Z'))
		return p[0] - 'A' + 1;
	return 0;
}

@ Kind variables are written with the letters A to Z. That provides for only
26 of them, but it's very, very rare to need more than 2, in practice.

The following nonterminal matches only those kind variables whose values are
actually set, and it returns those values. This is how kind variables are
parsed almost all of the time.

=
<k-kind-variable> internal 1 {
	int k = Kinds::Textual::parse_kind_variable_name(
		Lexer::word_raw_text(Wordings::first_wn(W)), FALSE);
	if (k != 0) {
		kind *K = Kinds::variable_from_context(k);
		if (K) { ==> { k, K }; return TRUE; }
	}
	==> { fail nonterminal };
}

@ But we can also formally parse A to Z as their own abstract identities;
now they always parse, regardless of what might be stored in them, and
they aren't replaced with their values (which they may not even have).

=
<k-formal-variable> internal 1 {
	int k = Kinds::Textual::parse_kind_variable_name(
		Lexer::word_raw_text(Wordings::first_wn(W)), FALSE);
	if (k != 0) {
		==> { k, Kinds::var_construction(k, NULL) };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ And it's also convenient to have:

=
<k-formal-variable-singular> internal 1 {
	int k = Kinds::Textual::parse_kind_variable_name_singular(
		Lexer::word_raw_text(Wordings::first_wn(W)));
	if (k != 0) {
		==> { k, Kinds::var_construction(k, NULL) };
		return TRUE;
	}
	==> { fail nonterminal };
}

@ For efficiency's sake, we don't actually parse directly using this
nonterminal, but it's needed all the same because of Preform's optimisations.

=
<k-kind-variable-texts> ::=
	a/as |
	b/bs |
	c/cs |
	d/ds |
	e/es |
	f/fs |
	g/gs |
	h/hs |
	i/is |
	j/js |
	k/ks |
	l/ls |
	m/ms |
	n/ns |
	o/os |
	p/ps |
	q/qs |
	r/rs |
	s/ss |
	t/ts |
	u/us |
	v/vs |
	w/ws |
	x/xs |
	y/ys |
	z/zs

@h Textual descriptions.
The following pretty-printer is inverse to the code which parses text and
turns it into a |kind| structure, or very nearly so. We use common
code to handle all of the reasons why we might want to spell out a kind
in words -- the log, the index, problem messages, comments in code, and
so on. For example:

=
void Kinds::Textual::log(kind *K) {
	Kinds::Textual::write(DL, K);
}

void Kinds::Textual::logger(OUTPUT_STREAM, void *vK) {
	kind *K = (kind *) vK;
	Kinds::Textual::write(OUT, K);
}

void Kinds::Textual::writer(OUTPUT_STREAM, char *format_string, void *vK) {
	kind *K = (kind *) vK;
	Kinds::Textual::write(OUT, K);
}

@ Thus we have a basic pretty-printer...

=
void Kinds::Textual::write(OUTPUT_STREAM, kind *K) {
	Kinds::Textual::write_inner(OUT, K, FALSE, FALSE);
}

void Kinds::Textual::write_plural(OUTPUT_STREAM, kind *K) {
	Kinds::Textual::write_inner(OUT, K, TRUE, FALSE);
}

@ ...and also one which prefaces the kind name with an article.

=
void Kinds::Textual::write_articled(OUTPUT_STREAM, kind *K) {
	TEMPORARY_TEXT(TEMP)
	Kinds::Textual::write_inner(TEMP, K, FALSE, TRUE);
	ArticleInflection::preface_by_article(OUT, TEMP, DefaultLanguage::get(NULL));
	DISCARD_TEXT(TEMP)
}

@ In all cases we make use of the following recursive method:

=
void Kinds::Textual::write_inner(OUTPUT_STREAM, kind *K, int plural_form, int substituting) {
	if (K == NULL) { WRITE("nothing"); return; }
	if (K == K_nil) { WRITE("nothing"); return; }
	if (K == K_void) { WRITE("nothing"); return; }
	kind_constructor *con = NULL;
	if (Kinds::is_proper_constructor(K)) con = Kinds::get_construct(K);
	@<Write punctuation kinds out to the stream@>;
	if (con) @<Write constructor kinds out to the stream@>
	else @<Write base kinds out to the stream@>;
}

@ Note that we do cheat in one case, in our resolve to have only a single
written form for kinds in all contexts -- we give a low-level description of
an intermediate value in the debugging log. But such a thing can't be exposed
higher up in Inform, so it's no loss to the index, problem messages, etc.,
to miss out on this detail.

@<Write punctuation kinds out to the stream@> =
	kind_constructor *con = Kinds::get_construct(K);
	if (con == CON_VOID) { WRITE("void"); return; }
	if (con == CON_NIL) { WRITE("nil"); return; }
	if (con == CON_TUPLE_ENTRY) { @<Describe a continuing tuple@>; return; }
	if (con == CON_KIND_VARIABLE) { @<Describe a kind variable, either by name or by value@>; return; }
	if (con == CON_INTERMEDIATE) {
		if (OUT == DL)
			LOG("$Q", Kinds::Behaviour::get_dimensional_form(K));
		else
			Kinds::Dimensions::index_unit_sequence(OUT,
				Kinds::Behaviour::get_dimensional_form(K), FALSE);
		return;
	}

@<Describe a continuing tuple@> =
	kind *head = NULL, *tail = NULL;
	Kinds::binary_construction_material(K, &head, &tail);
	Kinds::Textual::write_inner(OUT, head, FALSE, substituting);
	if (Kinds::get_construct(tail) != CON_VOID) {
		WRITE(", ");
		Kinds::Textual::write_inner(OUT, tail, FALSE, substituting);
	}

@<Describe a kind variable, either by name or by value@> =
	int vn = Kinds::get_variable_number(K);
	if ((substituting) && (vn > 0)) {
		kind *subst = Kinds::variable_from_context(vn);
		if (subst) { Kinds::Textual::write_inner(OUT, subst, plural_form, TRUE); return; }
	}
	WRITE("%c", 'A' + vn - 1);
	if (plural_form) WRITE("s");
	kind *S = Kinds::get_variable_stipulation(K);
	if ((S) && (Kinds::eq(S, K_value) == FALSE)) {
		WRITE(" ["); Kinds::Textual::write(OUT, S); WRITE("]"); }

@<Write base kinds out to the stream@> =
	if (Kinds::eq(K, K_pointer_value)) WRITE("pointer value");
	else if (Kinds::eq(K, K_stored_value)) WRITE("stored value");
	else WRITE("%W", Kinds::Behaviour::get_name(K, plural_form));

@<Write constructor kinds out to the stream@> =
	kind *first_base = NULL, *second_base = NULL;
	if (KindConstructors::arity(con) == 1)
		first_base = Kinds::unary_construction_material(K);
	else
		Kinds::binary_construction_material(K, &first_base, &second_base);
	@<Make a special case for either/or properties@>;
	wording KW = Kinds::Behaviour::get_name(K, plural_form);
	int k1 = Wordings::first_wn(KW);
	int full_length = Wordings::length(KW);
	int from, to;
	@<Choose which form of the constructor to use when writing this out@>;
	@<Actually write out the chosen form of the constructor@>;

@ Since Inform reads "either/or property" as syntactic sugar for "truth
state valued property", we'll also write it: it's a much more familiar
usage.

@<Make a special case for either/or properties@> =
	if ((con == CON_property) && (Kinds::eq(first_base, K_truth_state))) {
		WRITE("either/or property");
		return;
	}

@<Choose which form of the constructor to use when writing this out@> =
	int k_present = 0, l_present = 0; /* these initialisations have no effect but avoid warnings */
	int choice_from[2][2], choice_to[2][2];
	@<Determine the possible forms for writing this constructor@>;
	k_present = 1; l_present = 1;
	if ((con == CON_rule) || (con == CON_rulebook)) {
		#ifdef IF_MODULE
		if (Kinds::eq(first_base, K_action_name)) k_present = 0;
		#endif
	} else {
		if (Kinds::eq(first_base, K_nil)) k_present = 0;
		if (Kinds::eq(first_base, K_void)) k_present = 0;
	}
	if ((con == CON_property) && (Kinds::eq(first_base, K_value))) k_present = 0;
	if ((con == CON_table_column) && (Kinds::eq(first_base, K_value))) k_present = 0;
	if ((con == CON_relation) && (Kinds::eq(first_base, second_base))) l_present = 0;
	if (KindConstructors::arity(con) == 1) l_present = 0;
	else if (Kinds::eq(second_base, K_nil)) l_present = 0;
	else if (Kinds::eq(second_base, K_void)) l_present = 0;
	if (choice_from[k_present][l_present] == -1) {
		if ((k_present == 0) && (choice_from[1][l_present] >= 0)) k_present++;
		else if ((l_present == 0) && (choice_from[k_present][1] >= 0)) l_present++;
		else if ((k_present == 0) && (l_present == 0) && (choice_from[1][1] >= 0)) {
			k_present++; l_present++;
		}
	}
	from = choice_from[k_present][l_present];
	to = choice_to[k_present][l_present];
	if ((from < 0) || (from >= full_length) || (to < 0) || (to >= full_length) || (to<from)) {
		LOG("%W: %d, %d, %d\n", KW, from, to, full_length);
		internal_error("constructor form choice failed");
	}

@<Determine the possible forms for writing this constructor@> =
	int from, i;
	choice_from[0][0] = -1; choice_from[0][1] = -1;
	choice_from[1][0] = -1; choice_from[1][1] = -1;
	for (i=0, from = -1; i<full_length; i++) {
		if (from == -1) { from = i; k_present = 0; l_present = 0; }
		if (Lexer::word(k1+i) == CAPITAL_K_V) k_present = 1;
		if (Lexer::word(k1+i) == CAPITAL_L_V) l_present = 1;
		if (Lexer::word(k1+i) == STROKE_V) @<End this constructor possibility@>;
	}
	@<End this constructor possibility@>;

@<End this constructor possibility@> =
	choice_from[k_present][l_present] = from;
	choice_to[k_present][l_present] = i-1;
	from = -1;

@<Actually write out the chosen form of the constructor@> =
	int i;
	for (i=from; i<=to; i++) {
		if (i > from) WRITE(" ");
		if (Lexer::word(k1+i) == CAPITAL_K_V)
			Kinds::Textual::desc_base(OUT, con, 0, first_base, substituting);
		else if (Lexer::word(k1+i) == CAPITAL_L_V)
			Kinds::Textual::desc_base(OUT, con, 1, second_base, substituting);
		else WRITE("%V", Lexer::word(k1+i));
	}

@ =
void Kinds::Textual::desc_base(OUTPUT_STREAM, kind_constructor *con,
	int b, kind *K, int substituting) {
	if (K == NULL) { WRITE("nothing"); return; }
	if (K == K_nil) { WRITE("nothing"); return; }
	if (K == K_void) { WRITE("nothing"); return; }
	int pluralised = TRUE;
	int tupled = KindConstructors::tupling(con, b);
	int bracketed = FALSE;
	if ((tupled > 1) && (Kinds::get_construct(K) == CON_TUPLE_ENTRY)) {
		kind *first_base = NULL, *second_base = NULL;
		Kinds::binary_construction_material(K, &first_base, &second_base);
		if ((second_base) && (Kinds::get_construct(second_base) == CON_TUPLE_ENTRY)) 
			bracketed = TRUE;
	}
	if ((b == 1) && (con == CON_phrase) && (Kinds::get_construct(K) == CON_phrase))
		bracketed = TRUE;
	if (bracketed) WRITE("(");
	if ((tupled > 1) || (con == CON_phrase)) pluralised = FALSE;
	Kinds::Textual::write_inner(OUT, K, pluralised, substituting);
	if (bracketed) WRITE(")");
}
