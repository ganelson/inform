[Calculus::Terms::] Terms.

Terms are the representations of values in predicate calculus:
variables, constants or functions of other terms.

@ Recall that a "term" can be anything which is a constant, can be a
variable, or can be a function $f_B(t)$ of another term $t$. Our
representation of this as a data structure therefore falls into three
cases. At all times exactly one of the three relevant fields, |variable|,
|constant| and |function| is used.

(a) Variables are represented by the numbers 0 to 25, and |-1| means
"not a variable".

(b) Constants are pointers to |specification| structures of main
type |VALUE|, and |NULL| means "not a constant".

(c) Functions are pointers to |pcalc_func| structures (see below), and
|NULL| means "not a function".

Cinders are discussed in "Cinders and Deferrals", and can be ignored for now.

In order to verify that a proposition makes sense and does not mix up
incompatible kinds of value, we will need to type-check it, and one part
of that involves assigning a kind of value $K$ to every term $t$ occurring
in the proposition. This calculation does involve some work, so we cache
the result in the |term_checked_as_kind| field, in order that we only have
to work it out once.

=
typedef struct pcalc_term {
	int variable; /* 0 to 25, or |-1| for "not a variable" */
	struct parse_node *constant; /* or |NULL| for "not a constant" */
	struct pcalc_func *function; /* or |NULL| for "not a function of another term" */
	int cinder; /* complicated, this: used to worry about scope of I6 local variables */
	struct kind *term_checked_as_kind; /* or |NULL| if unchecked */
} pcalc_term;

@ The |pcalc_func| structure represents a usage of a function inside a term.
Terms such as $f_A(f_B(f_C(x)))$ often occur, so a typical term might be
stored as

(1) A |pcalc_term| structure which has a |function| field pointing to
(2) A |pcalc_func| structure whose |bp| field points to A, and whose |fn_of|
field is
(3) A |pcalc_term| structure which has a |function| field pointing to
(4) A |pcalc_func| structure whose |bp| field points to B, and whose |fn_of|
field is
(5) A |pcalc_term| structure which has a |function| field pointing to
(6) A |pcalc_func| structure whose |bp| field points to C, and whose |fn_of|
field is
(7) A |pcalc_term| structure which has a |variable| field set to 0 (which is $x$).

=
typedef struct pcalc_func {
	struct binary_predicate *bp; /* the predicate $B$ such that this is $f_B(t)$ */
	struct pcalc_term fn_of; /* the term $t$ such that this is $f_B(t)$ */
	int from_term; /* whether $t$ is term 0 or 1 of $B$ */
} pcalc_func;

@h Creating new terms.

=
pcalc_term Calculus::Terms::new_variable(int v) {
	pcalc_term pt; @<Make new blank term structure pt@>;
	if ((v < 0) || (v >= 26)) internal_error("bad variable term created");
	pt.variable = v;
	return pt;
}

pcalc_term Calculus::Terms::new_constant(parse_node *c) {
	pcalc_term pt; @<Make new blank term structure pt@>;
	pt.constant = c;
	return pt;
}

pcalc_term Calculus::Terms::new_function(struct binary_predicate *bp, pcalc_term ptof, int t) {
	pcalc_term pt; @<Make new blank term structure pt@>;
	pcalc_func *pf = CREATE(pcalc_func);
	pf->bp = bp; pf->fn_of = ptof; pf->from_term = t;
	pt.function = pf;
	return pt;
}

@ Where, in all three cases:

@<Make new blank term structure pt@> =
	pt.variable = -1;
	pt.constant = NULL;
	pt.function = NULL;
	pt.cinder = -1; /* that is, no cinder */
	pt.term_checked_as_kind = NULL;

@h Copying.

=
pcalc_term Calculus::Terms::copy(pcalc_term pt) {
	if (pt.constant) pt.constant = Node::duplicate(pt.constant);
	if (pt.function) pt = Calculus::Terms::new_function(pt.function->bp,
		Calculus::Terms::copy(pt.function->fn_of), pt.function->from_term);
	return pt;
}

@h Variable letters.
The variables 0 to 25 are referred to by the letters $x, y, z, a, b,
c, ..., w$: this convention is followed both in the debugging log and
in functions compiled into I6 code.

The number 26 turns up quite often in this chapter, and while it's
normally good style to define named constants, here we're not going
to. 26 is a number which anyone other than a string theorist will
immediately associate with the size of the alphabet. Moreover, we
can't really raise the total, because there are only 26
single-character local variable names in I6, |a| to |z|. (Well,
strictly speaking there is also |_|, but we won't go there.) To have a
variable limit lower than 26 would be artificial, since there are no
memory constraints arguing for it; and in any case a proposition with
27 or more variables would be so huge that it could not be evaluated
at run-time in any remotely plausible length of time. So although the
26-variables-only limit is embedded in Inform, it really is not any
restriction, and it greatly simplifies the code.

=
char *pcalc_vars = "xyzabcdefghijklmnopqrstuvw";

@h Underlying terms.
Routines to see if a term is a constant $C$, or if it is a chain of functions
at the bottom of which is a constant $C$; and similarly for variables.

=
parse_node *Calculus::Terms::constant_underlying(pcalc_term *t) {
	if (t == NULL) internal_error("null term");
	if (t->constant) return t->constant;
	if (t->function) return Calculus::Terms::constant_underlying(&(t->function->fn_of));
	return NULL;
}

int Calculus::Terms::variable_underlying(pcalc_term *t) {
	if (t == NULL) internal_error("null term");
	if (t->variable >= 0) return t->variable;
	if (t->function) return Calculus::Terms::variable_underlying(&(t->function->fn_of));
	return -1;
}

@h Adjective-noun conversions.
As we shall see, a general unary predicate stores a type-reference
pointer to an adjectival phrase -- the adjective it tests. But
sometimes the same word acts both as adjective and noun in English. In
"the green door", clearly "green" is an adjective; in "the door
is green", it is possibly a noun; in "the colour of the door is
green", it must surely be a noun. Yet these are all really the same
meaning. To cope with this ambiguity, we need a way to convert the
adjectival form of such an adjective into its noun form, and back
again.

=
#ifdef CORE_MODULE
pcalc_term Calculus::Terms::adj_to_noun_conversion(unary_predicate *tr) {
	adjective *aph = UnaryPredicates::get_adj(tr);
	instance *I = Adjectives::Meanings::has_ENUMERATIVE_meaning(aph);
	if (I) return Calculus::Terms::new_constant(Rvalues::from_instance(I));
	property *prn = Adjectives::Meanings::has_EORP_meaning(aph, NULL);
	if (prn) return Calculus::Terms::new_constant(Rvalues::from_property(prn));
	return Calculus::Terms::new_variable(0);
}
#endif

@ And conversely:

=
#ifdef CORE_MODULE
unary_predicate *Calculus::Terms::noun_to_adj_conversion(pcalc_term pt) {
	kind *K;
	adjective *aph;
	parse_node *spec = pt.constant;
	if (Node::is(spec, CONSTANT_NT) == FALSE) return NULL;
	K = Node::get_kind_of_value(spec);
	if (Properties::Conditions::get_coinciding_property(K) == NULL) return NULL;
	if (Kinds::Behaviour::is_an_enumeration(K)) {
		instance *I = Node::get_constant_instance(spec);
		aph = Instances::get_adjective(I);
		return UnaryPredicates::new(aph, TRUE);
	}
	return NULL;
}
#endif

@h Compiling terms.
We are now ready to compile a general predicate-calculus term, which
may be a constant (perhaps with a cinder marking), a variable or a function
of another term.

Variables are compiled to I6 locals |x|, |y|, |z|, ...; cindered constants to
|const_0|, |const_1|, ... These will only be valid inside a deferred routine
like |Prop_19|, but that is fine because they cannot arise anywhere else.
If we are compiling an undeferred proposition then all constants are uncindered
and there are no variables (if there were, it would have been deferred).

Functions $f_R(t)$ are compiled by expanding an I6 schema for $f_R$ with $t$
as parameter.

One small wrinkle is that we type-check any use of a phrase to decide a
value, because this might not yet have been checked otherwise.

=
#ifdef CORE_MODULE
void Calculus::Terms::emit(pcalc_term pt) {
	if (pt.variable >= 0) {
		local_variable *lvar = LocalVariables::find_pcalc_var(pt.variable);
		if (lvar == NULL) {
			LOG("var is %d\n", pt.variable);
			internal_error("absent calculus variable");
		}
		inter_symbol *lvar_s = LocalVariables::declare_this(lvar, FALSE, 8);
		Produce::val_symbol(Emit::tree(), K_value, lvar_s);
		return;
	}
	if (pt.constant) {
		if (pt.cinder >= 0) {
			Calculus::Deferrals::Cinders::emit(pt.cinder);
		} else {
			if (ParseTreeUsage::is_phrasal(pt.constant))
				Dash::check_value(pt.constant, NULL);
			Specifications::Compiler::emit_as_val(K_value, pt.constant);
		}
		return;
	}
	if (pt.function) {
		i6_schema *fn;
		binary_predicate *bp = (pt.function)->bp;
		fn = BinaryPredicates::get_term_as_function_of_other(bp, 0);
		if (fn == NULL) fn = BinaryPredicates::get_term_as_function_of_other(bp, 1);
		if (fn == NULL) internal_error("Function of non-functional predicate");
		Calculus::Schemas::emit_expand_from_terms(fn, &(pt.function->fn_of), NULL, FALSE);
		return;
	}
	internal_error("Broken pcalc term");
}
#endif

@h Debugging terms.
The art of this is to be unobtrusive; when a proposition is being logged,
we don't much care about the constant terms, and want to display them
concisely and without fuss.

=
void Calculus::Terms::log(pcalc_term *pt) {
	Calculus::Terms::write(DL, pt);
}
void Calculus::Terms::write(text_stream *OUT, pcalc_term *pt) {
	if (pt == NULL) {
		WRITE("<null-term>");
	} else if (pt->constant) {
		parse_node *spec = pt->constant;
		if (pt->cinder >= 0) { WRITE("const_%d", pt->cinder); return; }
		if (Wordings::nonempty(Node::get_text(spec))) { WRITE("'%W'", Node::get_text(spec)); return; }
		#ifdef CORE_MODULE
		if (Node::is(spec, CONSTANT_NT)) {
			instance *I = Rvalues::to_object_instance(spec);
			if (I) { Instances::write(OUT, I); return; }
		}
		#endif
		Node::log_node(OUT, spec);
	} else if (pt->function) {
		#ifdef CORE_MODULE
		binary_predicate *bp = pt->function->bp;
		i6_schema *fn = BinaryPredicates::get_term_as_function_of_other(bp, 0);
		if (fn == NULL) fn = BinaryPredicates::get_term_as_function_of_other(bp, 1);
		if (fn == NULL) internal_error("Function of non-functional predicate");
		Calculus::Schemas::write_applied(OUT, fn, &(pt->function->fn_of));
		#endif
		#ifndef CORE_MODULE
		WRITE("function");
		#endif
	} else if (pt->variable >= 0) {
		int j = pt->variable;
		if (j<26) WRITE("%c", pcalc_vars[j]); else WRITE("<bad-var=%d>", j);
	} else {
		WRITE("<bad-term>");
	}
}
