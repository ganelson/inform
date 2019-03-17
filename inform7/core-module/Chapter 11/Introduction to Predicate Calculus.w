[Calculus::] Introduction to Predicate Calculus.

An exposition of the form of predicate calculus used by Inform.

@ "Again and again Haddon thought he had found the key to the strange writings,
but always he was disappointed. And then one day -- he was an old man of seventy
now -- he fed a trial programme into his computer, and for the first time a
translated sentence was delivered -- his life-long task was rewarded. Yes,
but for the fact that one man had been prepared to devote every spare hour of
his life to solving the riddle, the amazing story of the Trigan Empire would
never have been given to the world. WHAT FOLLOWS IS THAT STORY."
("The Rise and Fall of the Trigan Empire", 1965)

@h Why predicate calculus.
Most attempts to codify the meaning of sentences in any systematic way
involve predicate calculus, and most people generally seem to agree
that linguistic concepts (like verbs, adjectives, and determiners)
correspond uncannily well with logical ones (like binary predicates,
unary predicates, and quantifiers). Since today's mathematical logic
has its roots in work on the philosophy of language (chiefly by Frege and
Wittgenstein), this is not altogether a coincidence. All the same, it is
striking how good the fit is, considering that human language is so
haphazard and logic so regular.

At any rate Inform goes along with this consensus, and converts the
difficult passages in its source text into mathematical propositions
-- lines written in logical notation. This is useful partly as a
well-defined way to store complicated meanings inside the program, but
also because these propositions can then be simplified by logical
rules. We can change their form so long as we do not change their
meaning, in the hope of finding ways to carry out the same tasks but
more efficiently than a simple-minded reading of the text would
suggest.

There are four main tasks to perform:

(a) Building propositions from the other Inform data structures;

(b) Simplifying, rearranging and type-checking propositions;

(c) Asserting that certain propositions are true at the start of play;

(d) Compiling certain propositions to I6 code which can test them, make them
true, or make them false.

In this chapter, we take these tasks in order. Because it contains all
of Inform's predicate calculus lore in one place, it necessarily contains
little pieces of algorithms from other chapters: a piece of the
type-checker, a piece of the code for asserting the initial state of
play, and so on. Well: but the overlap had to go somewhere.

@ A glimpse of Inform's inner workings can be made by writing a test
instruction like so:

>> Laboratory is a room. The box is a container.

>> Test sentence (internal) with a man can see the box in the Laboratory.

At the start of play, the compiled story file will print a textual form of
the proposition in predicate calculus which that became:

	|1. a man can see the box in the Laboratory|
	|[ Exists x : man(x) & thing('box') & is('laboratory', ContainerOf('box')) & can-see(x, 'box') ]|
	|x - object.|

(The |intest| test case |Calculus| runs about 200 sentences like this.)
One can similarly "Test description (internal) with..." for any description,
such as "animals which are in lighted rooms".

@h Formal description.
There are many flavours of predicate calculus, and though they behave in
broadly similar ways, the details vary in practice. Inform's calculus
is unusual in several respects, so here is its definition.

The terms "constant", "variable" and "function" below are used in
their predicate-calculus senses, not their Inform ones. In the excerpt

>> a container in the location of Nicole contains the second noun

the text "location of Nicole" is a phrase deciding an object -- a function --
and "the second noun" is an object that varies -- a variable. But if we are
looking at the sentence only for its logical meaning, we have to forget about
the passage of time and think about what the sentence means at any single
moment. "Location of Nicole" and "the second noun" are both fixed, in
this instant; the only thing which varies is the identity of the possible
container, because we might have to look at hundreds of different containers
to see if the sentence is true. One logical translation might be
$$ \exists x: {\it container}(x)\land {\it in}(x, C_1) \land {\it in}(C_2, x) $$
where $C_1$ and $C_2$ are constants ("location of Nicole" and "second noun"
respectively), while the only variable is $x$, the mysterious container.
(The symbol $\exists$ means "there exists".) Because objects move
around in play, and $C_1$ and $C_2$ have different values at different
moments, this sentence is sometimes true and sometimes false. But its
meaning does not change.

@ The propositions in our predicate calculus are those which can be made
using the following ingredients and recipes.

1. There are 26 variables, which we print to the debugging log as |x|, |y|,
|z|, |a|, |b|, |c|, ..., |w|.

2. The constants are specifications with family |VALUE| -- that
is, all literal constants, variables, list and table entries, or phrases
which decide values.

3. A "predicate" $P$ is a statement $P(a, b, c, ...)$ which is
either true or false for any given combination $a, b, c, ...$. The
"arity" of a predicate is the number of terms it looks at. There is
speculative talk of allowing higher-order predicates in future (and Inform's
data structures have been built with one eye on this), but for now
we use only unary predicates $U(x)$ or binary predicates $B(x, y)$, of
arity 1 and 2 respectively. The predicates in our calculus are as follows:

(a) The special binary predicate ${\it is}(x, y)$, true if and only if $x=y$.
(b) Every kind K (of value or of object) corresponds to a unary
predicate $K(x)$.
(c) Every state of an either/or property corresponds to a unary
predicate, e.g., ${\it open}(x)$.
(d) Every possible value of an enumerated kind of value which
corresponds to a property similarly corresponds to a unary predicate:
e.g., if we have defined "colour" as a kind of value and made it a
property of things, then ${\it green}(x)$, ${\it red}(x)$, and
${\it blue}(x)$ might all be unary predicates.
(e) Every adjectival phrase, to which a definition has been
supplied in the source, likewise produces a unary predicate: for
example, ${\it visible}(x)$.
(f) An adjective given a definition which involves a threshold for
a numeric property also produces a binary predicate for its comparative
form: for instance, a definition for "tall" gives not only a unary
predicate ${\it tall}(x)$ (as in (e) above) but also a binary predicate
${\it taller}(x, y)$.
(g) A special unary predicate ${\it everywhere}(x)$ which asserts that
the backdrop $x$ can be found in every room.
(h) Each table column name C gives rise to a binary predicate
{\it listed-in-C}$(x, y)$, which tests whether value $x$ is listed in
the C column of table $y$. (This looks as if it should really be a
single ternary predicate, but since we never need to quantify over
choice of column, nothing would be gained by that.)
(i) Every value property P gives rise to a binary predicate
{\it same-P-value}$(x, y)$, testing whether objects $x$ and $y$
have the same value of P. (Again, it would not be useful to quantify
over P.)
(j) Every direction D gives rise to a binary predicated
{\it mapped-D}$(x, y)$, testing whether there is a map connection
from $x$ to $y$ in direction D.
(k) Each new relation defined in the source text is a binary
predicate.
(l) The basic stock of spatial containment relations built into
Inform -- ${\it in}(x, y)$, ${\it on}(x, y)$, etc. -- are similarly
binary predicates.
(m) If $P$ is a binary predicate present in Inform then so automatically
is its "reversal" $R$, defined by $R(x, y)$ if and only if $P(y, x)$.
For instance, the existence of ${\it carries}(x, y)$ ensures that we
also have {\it carried-by}$(x, y)$, its reversal. The equality predicate
$x=y$ is its own reversal, but all other binary predicates are formally
different from their reversals, even if they always mean the same in
practice. (The reversal of {\it same-carrying-capacity-as}$(x, y)$ is
true if and only if the original is true, but we regard them as different
predicates just the same.)

4. If a binary predicate $B$ has the property that for any $x$ there
is at most one $y$ such that $B(x, y)$ (for instance, {\it carried-by}
has this property) then we write $f_B$ for the function which maps $x$
to either the unique value $y$ such that $B(x, y)$, or else to a zero
value. (In the case where $y$ is an object, we interpret this as "nothing",
which for logical purposes is treated as if it were a valid object, so
that $f_B$ maps the set of objects to itself.) Another way of saying
this is that $f_B$, if it exists, is defined by:
$$ B(x, y) \Leftrightarrow y = f_B(x). $$

These are the only functions allowed in our predicate calculus, and they
are always functions of just one variable.

5. A "quantifier" $Qx$ is a logical expression for the range of values
of a given variable $x$: for instance, $\forall x$ (read "for all $x$")
implies that $x$ can have any value, whereas $\exists x$ (read "there
exists an $x$") means only that at least one value works for $x$. In
our calculus, we allow not only these quantifiers but also the following
generalised quantifiers, where $n$ is a non-negative integer:

(a) The quantifier $V_{=n} x$ --
meaning "for exactly $n$ values of $x$".
(b) The quantifier $V_{\geq n} x$ --
meaning "for at least $n$ values of $x$".
(c) The quantifier $V_{\leq n} x$ --
meaning "for at most $n$ values of $x$".
(d) The quantifier $P_{\geq n} x$ --
meaning "for at least a percentage of $n$ values of $x$".
(e) The quantifier $P_{\leq n} x$ --
meaning "for at most a percentage of $n$ values of $x$".

Note that "for all x" corresponds to $P_{\geq 100} x$, and "there exists
x" to $V_{\geq 1} x$, so the above scheme does indeed generalise the
standard pair of quantifiers $\forall$ and $\exists$.

6. A "term" must be a constant, a variable or a function $f_B(t)$ of
another term $t$. So $x$, "Miss Marple", $f_B(x)$ and $f_A(f_B(f_C(6)))$
are all examples of terms. We are only allowed to apply functions a finite
number of times, so any term has the form:
$$ f_{B_1}(f_{B_2}(... f_{B_n}(s)...)) $$
for at most a finite number $n$ of function usages (possibly $n=0$), where
at bottom $s$ must be either a constant or a variable.

7. A proposition is defined by the following rules:

(a) The empty expression is a proposition. This is always true, so in these
notes it will be written $\top$.
(b) For any unary predicate $U$ and any term $t$, $U(t)$ is a proposition.
(c) For any binary predicate $B$ and any terms $s$, $t$, $B(s, t)$
is a proposition.
(d) For any proposition $\phi$, the negation $\lnot(\phi)$ is a
proposition. This is by definition true if and only if $\phi$ is false.
(e) For any propositions $\phi$ and $\psi$, the conjunction
$\phi\land\psi$ -- true if and only if both are true -- is a proposition
so long as it is well-formed (see below).
(f) For any variable $v$, the quantifier $\exists v$ is a proposition.
(g) For any variable $v$, any quantifier $Q$ other than $\exists$, and any
proposition $\phi$ in which $v$ is a "free" variable (see below),
$Qv\in\lbrace v\mid \phi(v)\rbrace$ is a proposition. The set denotes all
possible values of $v$ matching the condition $\phi(v)$, and this specifies
the range of the quantifier.

@ Note that there are two ways in which propositions can appear in brackets
in a bigger proposition: negation (d), and specifying a quantification
domain (g). We sometimes call the bracketed part a "subexpression" of the
whole.

In particular, note that -- unusually -- we do not bracket quantification
itself. Most definitions would say that given $v$ and a proposition
$\phi(v)$, we can form $\exists v: (\phi(v))$ -- in other words that
quantification is a way to modify an already created proposition, but that
$\exists v$ is not a proposition in its own right, just as $\lnot$ is not a
proposition. Inform disagrees. Here $\exists v$ is a meaningful sentence:
it means "an object exists". We can form "there is a door" by rule (e),
conjoining $\exists x$ and ${\it door}(x)$ to form $\exists x: {\it door}(x)$.
(As a nod to conventional mathematical notation, we write a colon after
a quantifier instead of a conjunction sign $\land$. But Inform stores it
as just another conjunction.)

We do bracket the domain of quantification. Most simple predicate
calculuses (predicates calculus?) have no need, since their only quantifiers
are $\forall$ and $\exists$, and there is a single universe set from which
all values are drawn. But in Inform, some quantifiers range over doors,
some over numbers, and so on. In most cases, a quantifier must specify its
domain. For example,
$$ \forall x\in \lbrace x\mid {\it number}(x)\rbrace : {\it even}(x) $$
("all numbers are even" -- false, of course) specifies the domain of
$\forall$ as the set of all $x$ such that ${\it number}(x)$.

$\exists$ is the one exception to this. The statement
$$ \exists x\in \lbrace x\mid {\it number}(x)\rbrace : {\it even}(x) $$
("a number is even" -- true this time) could equally be written
$$ \exists x: {\it number}(x)\land {\it even}(x) $$
("there is an even number"). We take advantage of this, and Inform never
specifies a domain for a $\exists$ quantifier.

@h Free and bound variables, well-formedness.
In any proposition $\phi$, we say that a variable $v$ is "bound" if it
appears as the variable governed by a quantifier: it is "free" if it
does appear somewhere in $\phi$ -- either directly as a term or indirectly
through a function application -- and is not bound. For instance, in
$$ \forall x : K(x) \land B(x, f_C(y)) $$
the variable $x$ is bound and the variable $y$ is free. In most accounts
of predicate calculus we say that a proposition is a "sentence" if all
of its variables are bound, but Inform often needs to parse English text to
a proposition with one free variable remaining in it, so we are not too
picky about this.

A well-formed proposition is one in which a variable $v$ is quantified
at most once: and in which, if it is quantified, then it occurs only
after (to the right of) its quantifier, and only within the subexpression
containing its quantifier. Thus the following are not well-formed:
$$ \exists v: {\it open}(v)\land \exists v : {\it closed}(v) $$
($v$ is quantified twice),
$$ {\it open}(v)\land \exists v : {\it closed}(v) $$
($v$ occurs before its quantifier),
$$ \lnot ( \exists v : {\it closed}(v) ) \land {\it openable}(v) $$
($v$ occurs outside the subexpression containing the quantifier -- in this
case, outside the negation brackets).

@h The scope of quantifiers.
A quantifier introduces a variable into a proposition which would not
otherwise be there, and it exists only for a limited range. For instance, in
the proposition
$$ {\it open}(x)\land\lnot(\exists y: {\it in}(x, y))\land {\it container}(x) $$
the variable $y$ exists only within the negation brackets; it ceases to exist
as soon as we move back out to the container atom. This range is called
the "scope" of the quantifier. In general, scopes are always as large as
possible in Inform: a variable lasts until the end of the subexpression in
which it is created. If the quantifier is outside of any brackets, then the
variable lasts until the end of the proposition.

@ Earlier drafts of Inform played games with moving quantifiers around, in
order to try to achieve more efficiently compiled propositions. The same
thing is now done by building propositions in a way which places quantifiers
as far forwards as possible, so we no longer actively move them once they
are in place. But it seems still worth preserving the rule which says when
this can be done:

Lemma. Suppose that $x$ is a variable; $\phi$ is a proposition in
which $x$ is unused; $\psi(x)$ is a proposition in which $x$ is free; and that
$Q$ is a generalised quantifier. Then
$$ \phi\land Qx : \psi(x) \quad\Leftrightarrow\quad Qx : \phi\land\psi(x) $$
provided that $Q$ requires at least one case in its range to be satisfied.

Proof. In any given evaluation, either $\phi$ is true, or it is false.
Suppose it is true. Since $T\land \theta \Leftrightarrow \theta$, both sides
reduce to the same expression, $Qx : \psi(x)$. On the other hand, suppose $\phi$
is false. Then $\phi\land Qx : \psi(x)$ is false, since $F\land\theta = F$
for any $\theta$. But the other side is $Qx : F$. Since we know that $Q$ can
only be satisfied if at least one case of $x$ works, and here every case of
$x$ results in falsity, $Qx : F$ is also false. So the two expressions have
the same evaluation in this case, too.

@h What is not in our calculus.
The significant thing missing is disjunction. In general, the
disjunction $\phi\lor\psi$ -- "at least one of $\phi$ and $\psi$
holds" -- is not a proposition.

Natural language does not seem to share the general even-handedness of
Boolean logic as between "and" and "or", perhaps because of the
way that speech is essentially a one-dimensional stream of discourse.
Talking makes it easier to reel off a linear list of requirements than
to describe a deep tree structure.

Of course, the operations "not" and "and" are between them sufficient
to express all other operations, and in particular we could imitate
disjunction like so:
$$ \lnot (\lnot(\phi)\land\lnot(\psi)) $$
("they are not both false" being equivalent to "at least one is true"),
but Inform does not at present make use of this.
