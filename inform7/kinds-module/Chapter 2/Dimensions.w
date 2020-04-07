[Kinds::Dimensions::] Dimensions.

To keep a small database indicating the physical dimensions of
numerical values, and how they combine: for instance, allowing us to
specify that a length times a length is an area.

@h Definitions.

@ Dimension in this sense is a term drawn from physics. The idea is that when
quantities are multiplied together, their natures are combined as well as
the actual numbers involved. For instance, in
$$ v = f\lambda $$
if the frequency $f$ of a wave is measured in Hz (counts per second), and
the wavelength $\lambda$ in m, then the velocity $v$ must be measured
in m/s: and that is indeed a measure of velocity, so this looks right.
We can tell that the formula
$$ v = f^2\lambda $$
must be wrong because it would result in an acceleration. Physicists use the
term "dimensions" much as Inform uses the term "kinds of value".

Inform applies dimension-checking to all "quasinumerical" kinds -- those
which can be expressed numerically. The choice of which kinds are quasinumerical
is all done in the I6 template, not built into Inform at the compiler level,
but the standard setup makes number, time, intermediate results of calculations
(see below), and what the Inform documentation calls "units" -- kinds of
value specified by literal patterns.

@ Inform divides quasinumerical kinds into three: fundamental units, derived units
with dimensions, and dimensionless units. In the default setup provided by
the template, a typical run has one fundamental unit ("time"), one
dimensionless unit ("number") and -- unless the source text does
something very strange -- no derived units.

It would no doubt be cool to distinguish these by applying Buckingham's
$\pi$-theorem to all the equations we need to use, but this is a tricky
technique and does not always produce the "natural" results which people
expect. Instead, Inform requires the writer to specify explicitly how units
combine.

Number and time are built-in special cases. Further fundamental units are created
every time source text like this is read:

>> Mass is a kind of value. 1kg specifies a mass.

Derived units only come about when the source text specifies a multiplication
rule. For instance, when Inform reads

>> A mass times an acceleration specifies a force.

it chooses one of the three units -- say, force -- and derives that from the
others.

Multiplication rules are stored in a linked list associated with left operand;
so that the rule $A$ times $B$ specifies $C$ causes $(B, C)$ to be stored
in the list of |multiplications| belonging to $A$.

=
typedef struct dimensional_rules {
	struct dimensional_rule *multiplications;
} dimensional_rules;

typedef struct dimensional_rule {
	struct wording name;
	struct kind *right;
	struct kind *outcome;
	struct dimensional_rule *next;
} dimensional_rule;

@ The derivation process can be seen in action by feeding Inform
definitions of the SI units (see the test case |SIUnits-G|) and looking at
the output of:

>> Test dimensions (internal) with --.

(The dash is meaningless -- this is a test with no input.) In the output, we
see that
= (text)
	Base units: time, length, mass, elapsed time, electric current, temperature, luminosity
	Derived units:
	frequency = (elapsed time)-1
	force = (length).(mass).(elapsed time)-2
	energy = (length)2.(mass).(elapsed time)-2
	pressure = (length)-1.(mass).(elapsed time)-2
	power = (length)2.(mass).(elapsed time)-3
	electric charge = (elapsed time).(electric current)
	voltage = (length)2.(mass).(elapsed time)-3.(electric current)-1
=
...and so on. Those expressions on the right hand sides are "derived units",
where the numbers are powers, so that negative numbers mean division.
It's easy to see why we want to give names and notations for some of
these derived units -- imagine going into a cycle shop and asking for a
$5 {\rm m}^2\cdot{\rm kg}\cdot{\rm s}^{-3}\cdot{\rm A}^{-1}$ battery.

@ A "dimensionless" quantity is one which is just a number, and is not a
physical measurement as such. In an equation like
$$ K = {{mv^2}\over{2}} $$
the 2 is clearly dimensionless, but other possibilities also exist. The
arc length of part of a circle at radius $r$ drawn out to angle $\theta$
(if measured in radians) is given by:
$$ A = \theta r $$
Here $A$ and $r$ are both lengths, so the angle $\theta$ must be dimensionless.
But clearly it's not quite conceptually the same thing as an ordinary number.
Inform creates new dimensionless quantities this way, too:

>> Angle is a kind of value. 1 rad specifies an angle. Length times angle specifies a length.

Inform is not quite so careful about distinguishing dimensionless quantities
as some physicists might be. The official SI units distinguish angle, measured
in radians, and solid angle, in steradians, writing them as having units
${\rm m}\cdot{\rm m}^{-1}$ and ${\rm m}^2\cdot{\rm m}^{-2}$ respectively --
one is a ratio of lengths, the other of areas. Inform cancels the units
and sees them as dimensionally equal. So if we write:

>> Solid angle is a kind of value. 1 srad specifies an solid angle. Area times solid angle specifies an area.

then Inform treats angle and solid angle as having the same multiplicative
properties -- but it still allows variables to have either one as a kind of
value, and prints them differently.

Note that a dimensionless unit (other than number) can only get that way
by derivation, so it is always a derived unit, never a fundamental unit.

@ In the process of calculations, we often need to create other and nameless
units as partial answers of calculations. Consider the kinetic energy equation
$$ K = {{mv^2}\over{2}} $$
being evaluated the way a computer does it, one step at a time. One way takes
the mass, multiplies by the velocity to get a momentum, multiplies by the
velocity again to get energy, then divides by a dimensionless constant. But
another way would be to square the velocity first, then multiply by mass
to get energy, then halve. If we do it that way, what units are the squared
velocity in? The answer has to be
= (text)
	(length)2.(elapsed time)-2
=
but that's a unit which isn't useful for much, and doesn't have any everyday
name. Inform creates what are called "intermediate kinds" like this in
order to be able to represent the kinds of intermediate values which turn
up in calculation. They use the special |CON_INTERMEDIATE| construction, they
are nameless, and the user isn't allowed to store the results permanently.
(They can't be the kind of a global variable, a table column, and so on.)
If the user wants to deal with such values on a long-term basis, he must give
them a name, like this:

>> Funkiness is a kind of value. 1 Claude is a funkiness. A velocity times a velocity specifies a funkiness.

@ Expressions like ${\rm m}^2\cdot{\rm kg}$ are stored inside Inform as
sequences of ordered pairs in the form
$$ ((B_1, p_1), (B_2, p_2), ..., (B_k, p_k)) $$
where each $B_i$ is the type ID of a fundamental unit, each $p_i$ is a non-zero
integer, and $B_1 < B_2 < ... < B_k$. For instance, energy would be
$$ (({\rm length}, 2), ({\rm mass}, 1), ({\rm elapsed~time}, -2)). $$

Every physically different derived unit has a unique and distinct sequence.
This is only true because a unit sequence is forbidden to contain derived
units. For instance, specific heat capacity looks as if it is written with
two different units in physics:
$$ {\rm J}\cdot {\rm K}^{-1}\cdot {\rm kg}^{-1} \quad = \quad
{\rm m}^2\cdot{\rm s}^{-2}\cdot{\rm K}^{-1} $$
But this is because the Joule is a derived unit. Substituting
${\rm J} = {\rm m}^2\cdot{\rm kg}\cdot{\rm s}^{-2}$
to get back to fundamental units shows that both sides would be computed as the
same unit sequence.

The case $k=0$, the empty sequence, is not only legal but important: it is
the derivation for a dimensionless unit. (As discussed above, Inform doesn't
see different dimensionless units as being physically different.)

=
typedef struct unit_pair {
	struct kind *fund_unit; /* and this really must be a fundamental kind */
	int power; /* a non-zero integer */
} unit_pair;

@ The following is a hard limit, but really not a problematic one. The
entire SI system has only 7 fundamental units, and the only named scientific
unit I've seen which has even 5 terms in its derivation is molar entropy, a
less than everyday chemical measure
(${\rm kg}\cdot{\rm m}^2\cdot{\rm s}^{-2}\cdot{\rm K}^{-1}\cdot{\rm mol}^{-1}$,
if you're taking notes).

@d MAX_BASE_UNITS_IN_SEQUENCE 16

=
typedef struct unit_sequence {
	int no_unit_pairs; /* in range 0 to |MAX_BASE_UNITS_IN_SEQUENCE| */
	struct unit_pair unit_pairs[MAX_BASE_UNITS_IN_SEQUENCE];
	int scaling_factor; /* see discussion of scaling below */
} unit_sequence;

@ Manipulating units like ${\rm m}^2\cdot{\rm kg}\cdot{\rm s}^{-2}$ looks
a little like manipulating formal polynomials in several variables, and of
course that isn't an accident. Another way of thinking of the above is that
we have a ring $R$ of underlying numbers but that all arithmetic is done
in a larger ring. For each unit extend by $R$ by a pair of formal
variables $U_i$ and $U_i^{-1}$, and then quotient by the ideal generated
by $U_jU_j^{-1}$ (so that they are indeed reciprocals of each other, as
the notation suggests) and also by all of the derivations we know of. Thus
Inform calculates in the ring:
$$ I = R[U_1, U_2, ..., U_n, U_1^{-1}, ..., U_n^{-1}] /
(U_1U_1^{-1}, U_2U_2^{-1}, ..., U_nU_n^{-1}, D_1, D_2, ..., D_i). $$
It does that in practice by eliminating all of the $U_i$ and $U_i^{-1}$
which are derived, so that it's left with just
$$ I = R[U_1, U_2, ..., U_k, U_1^{-1}, ..., U_k^{-1}] /
(U_1U_1^{-1}, U_2U_2^{-1}, ..., U_kU_k^{-1}). $$

For instance, given seconds, Watts and Joules,
$$ I = R[{\rm s}, {\rm s}^{-1}, {\rm W}, {\rm W}^{-1}, {\rm J}, {\rm J}^{-1}]/
({\rm s}{\rm s}^{-1} = 1, {\rm W}{\rm W}^{-1}=1, {\rm J}{\rm J}^{-1} = 1,
{\rm s}{\rm W} = {\rm J}) $$
which by substituting all occurrences of {\rm J} can be reduced to:
$$ I = R[{\rm s}, {\rm s}^{-1}, {\rm W}, {\rm W}^{-1}]/
({\rm s}{\rm s}^{-1} = 1, {\rm W}{\rm W}^{-1}=1). $$
Of course there are other ways to calculate $I$ -- we could have
eliminated any of the three units and kept the other two.

If the derivations were ever more complex than $AB=C$, we might have to
use some elegant algorithms for calculating Gröbner bases in order to
determine $I$. But Inform's syntax is such that the writer of the source
text gives us the simplest possible description of the ideal, so no such
fun occurs.

What does this ring look like? Because we are not allowed to add terms with
different powers of the variables, we only ever deal with monomials. Thus
we can form $2{\rm W}{\rm s}^{-1} + 7{\rm W}{\rm s}^{-1}$, but Inform forbids
us to form (say) $6{\rm J} + 7{\rm W}$. We can therefore picture the ring $I$
as a great mass of parallel copies of $R$. Dimensionless values all live
in $R$ itself, while energies all live in $R.{\rm s}.{\rm W}$, powers in $R.{\rm W}$
and so on. Addition and subtraction slide values around within their own
parallel copies, but multiplication and division move them from one to
another. The computation $v_1v_2$ is done in general by calculating the
numerical part (in $R$) at run-time, and the units (the choice of which
copy of $R$) at compile-time.

@ But enough abstraction: time for some arithmetic. Inform performs
checking whenever values from two different kinds are combined by any of
eight arithmetic operations, numbered as follows. The numbers must not
be changed without amending the definitions of "plus" and so on
in the Standard Rules.

@d NO_OPERATIONS 9
@d PLUS_OPERATION 0 /* addition */
@d MINUS_OPERATION 1 /* subtraction */
@d TIMES_OPERATION 2 /* multiplication */
@d DIVIDE_OPERATION 3 /* division */
@d REMAINDER_OPERATION 4 /* remainder after division */
@d APPROXIMATION_OPERATION 5 /* "X to the nearest Y" */
@d ROOT_OPERATION 6 /* square root -- a unary operation */
@d REALROOT_OPERATION 7 /* real-valued square root -- a unary operation */
@d CUBEROOT_OPERATION 8 /* cube root -- similarly unary */
@d EQUALS_OPERATION 9 /* set equal -- used only in equations */
@d POWER_OPERATION 10 /* raise to integer power -- used only in equations */
@d UNARY_MINUS_OPERATION 11 /* unary minus -- used only in equations */

@ The following is associated with "total...", as in "the total weight
of things on the table", but that's a dodge used in the Standard Rules,
and for dimensional purposes we ignore it.

@d TOTAL_OPERATION 12 /* not really one of the above */

@ There are two reasons why Inform monitors arithmetic: to keep track of
how it changes kinds, and to preserve scaling factors.

We start from the principle that not every arithmetic operation can be done,
and that even when it can, the result may have a different kind than the
operand(s) had. For one thing, every arithmetic operation requires that its
operands are quasinumerical -- Inform won't allow a text to be multiplied by
a sound effect. (Occasionally we have thought about allowing text to be
duplicated by multiplication -- 2 times "zig" would be "zigzig", and
maybe similarly for lists -- but it always seemed more likely to be used by
mistake than intentionally.)

Other restrictions are also applied. For instance, a time cannot be added
to a number, or vice versa; addition, subtraction and approximation require
both operands to have the same units.

@ Finally, scaling. Number is straightforwardly an integer kind:
it holds whole numbers. But other quasinumerical kinds can be stored
using scaled, fixed-point arithmetic. In general for each named unit
$U$ (fundamental or derived) there is a positive integer $k_U$ such that the
true value $v$ is stored at run-time as the I6 integer $k_U v$. We call
this the scaled value.

For example, if the text reads:

>> Force is a kind of value. 1N specifies a force scaled up by 1000.

then $k = 1000$ and the value 1N will be stored at run-time as |1000|;
forces can thus be calculated to a true value accuracy of at best 0.001N,
stored at run-time as |1|.

It must be emphasised that this is scaled, fixed-point arithmetic: there
are no mantissas or exponents. In such schemes the scale factor is usually
$2^{16}$ or some similar power of 2, but here we want to use exactly the
scale factors laid out by the source text -- partly because the user
knows best, partly so that it is unambiguous how to print values, partly
so that source text like "0.001N" determines an exact value rather than
being approximated by a binary equivalent.

@h Prior kinds.
It turns out to be convenient to have a definition ordering of fundamental kinds,
which is completely unlike the $\leq$ relation; it just places them in
order of creation.

=
int Kinds::Dimensions::kind_prior(kind *A, kind *B) {
	if (A == NULL) {
		if (B == NULL) return FALSE;
		return TRUE;
	}
	if (B == NULL) {
		if (A == NULL) return FALSE;
		return FALSE;
	}
	if (Kinds::get_construct(A)->allocation_id < Kinds::get_construct(B)->allocation_id) return TRUE;
	return FALSE;
}

@h Multiplication lists.
The linked lists of multiplication rules begin empty for every kind:

=
void Kinds::Dimensions::dim_initialise(dimensional_rules *dimrs) {
	dimrs->multiplications = NULL;
}

@ And this adds a new one to the relevant list:

=
void Kinds::Dimensions::record_multiplication_rule(kind *left, kind *right, kind *outcome) {
	dimensional_rules *dimrs = Kinds::Behaviour::get_dim_rules(left);
	dimensional_rule *dimr;

	for (dimr = dimrs->multiplications; dimr; dimr = dimr->next)
		if (dimr->right == right) {
			Kinds::problem_handler(DimensionRedundant_KINDERROR, NULL, NULL, NULL);
			return;
		}

	dimensional_rule *dimr_new = CREATE(dimensional_rule);
	dimr_new->right = right;
	dimr_new->outcome = outcome;
	if (current_sentence)
		dimr_new->name = ParseTree::get_text(current_sentence);
	else
		dimr_new->name = EMPTY_WORDING;
	dimr_new->next = dimrs->multiplications;
	dimrs->multiplications = dimr_new;
}

@ The following loop-header macro iterates through the possible triples
$(L, R, O)$ of multiplication rules $L\times R = O$.

@d LOOP_OVER_MULTIPLICATIONS(left_operand, right_operand, outcome_type, wn)
	dimensional_rules *dimrs;
	dimensional_rule *dimr;
	LOOP_OVER_BASE_KINDS(left_operand)
		for (dimrs = Kinds::Behaviour::get_dim_rules(left_operand),
			dimr = (dimrs)?(dimrs->multiplications):NULL,
			wn = (dimr)?(Wordings::first_wn(dimr->name)):-1,
			right_operand = (dimr)?(dimr->right):0,
			outcome_type = (dimr)?(dimr->outcome):0;
			dimr;
			dimr = dimr->next,
			wn = (dimr)?(Wordings::first_wn(dimr->name)):-1,
			right_operand = (dimr)?(dimr->right):0,
			outcome_type = (dimr)?(dimr->outcome):0)

@ And this is where the user asks for a multiplication to come out in a
particular way:

=
void Kinds::Dimensions::dim_set_multiplication(kind *left, kind *right,
	kind *outcome) {
	if ((Kinds::is_proper_constructor(left)) ||
		(Kinds::is_proper_constructor(right)) ||
		(Kinds::is_proper_constructor(outcome))) {
		Kinds::problem_handler(DimensionNotBaseKOV_KINDERROR, NULL, NULL, NULL);
		return;
	}
	if ((Kinds::Behaviour::is_quasinumerical(left) == FALSE) ||
		(Kinds::Behaviour::is_quasinumerical(right) == FALSE) ||
		(Kinds::Behaviour::is_quasinumerical(outcome) == FALSE)) {
		Kinds::problem_handler(NonDimensional_KINDERROR, NULL, NULL, NULL);
		return;
	}
	Kinds::Dimensions::record_multiplication_rule(left, right, outcome);
	if ((Kinds::Compare::eq(left, outcome)) && (Kinds::Compare::eq(right, K_number))) return;
	if ((Kinds::Compare::eq(right, outcome)) && (Kinds::Compare::eq(left, K_number))) return;
	Kinds::Dimensions::make_unit_derivation(left, right, outcome);
}

@h Unary operations.
All we need to know is which ones are unary, in fact, and:

=
int Kinds::Dimensions::arithmetic_op_is_unary(int op) {
	switch (op) {
		case CUBEROOT_OPERATION:
		case ROOT_OPERATION:
		case REALROOT_OPERATION:
		case UNARY_MINUS_OPERATION:
			return TRUE;
	}
	return FALSE;
}

@h Euclid's algorithm.
In my entire life, I believe this is the only time I have ever actually
used Euclid's algorithm for the GCD of two natural numbers. I've never
quite understood why textbooks take this as somehow the typical algorithm.
My maths students always find it a little oblique, despite the almost
trivial proof that it works. I find it hard to visualise myself, for that
matter. And then, consider that the average number of iterations $\tau_n$,
in effect its running time, is known to be
$$ \tau_n = {{12\log 2}\over{\pi^2}}\log n + (4P + 5/2) + O(n^{-1/6+\epsilon) $$
for any $\epsilon>0$, where $P$ is defined in terms of an integral, Euler's
constant, and an evaluation of the derivative of the Riemann zeta function
-- see D. E. Knuth, `Evaluation of Porter's Constant', reprinted in
"Selected Papers on Analysis of Algorithms" (Stanford: CSLI Lecture Notes
102, 2000). In practice, a shade under $\log n$ steps, then, which is nicely
quick. But I don't look at the code and immediately see this, myself.

=
int Kinds::Dimensions::gcd(int m, int n) {
	if ((m<1) || (n<1)) internal_error("applied Kinds::Dimensions::gcd outside natural numbers");
	while (TRUE) {
		int rem = m%n;
		if (rem == 0) return n;
		m = n; n = rem;
	}
}

@ The sequence of operation here is to reduce the risk of integer overflows
when multiplying |m| by |n|.

=
int Kinds::Dimensions::lcm(int m, int n) {
	return (m/Kinds::Dimensions::gcd(m, n))*n;
}

@h Unit sequences.
Given a fundamental type $B$, convert it to a unit sequence: $B = B^1$, so we
get a sequence with a single pair: $((B, 1))$. Uniquely, "number" is born
derived and dimensionless, though, so that comes out as the empty sequence.

=
unit_sequence Kinds::Dimensions::fundamental_unit_sequence(kind *B) {
	unit_sequence us;
	if (B == NULL) {
		us.no_unit_pairs = 0;
		us.unit_pairs[0].fund_unit = NULL; us.unit_pairs[0].power = 0; /* redundant, but appeases |gcc -O2| */
	} else {
		us.no_unit_pairs = 1;
		us.unit_pairs[0].fund_unit = B; us.unit_pairs[0].power = 1;
	}
	return us;
}

@ As noted above, two units represent dimensionally equivalent physical
quantities if and only if they are identical, which makes comparison easy:

=
int Kinds::Dimensions::compare_unit_sequences(unit_sequence *ik1, unit_sequence *ik2) {
	int i;
	if (ik1 == ik2) return TRUE;
	if ((ik1 == NULL) || (ik2 == NULL)) return FALSE;
	if (ik1->no_unit_pairs != ik2->no_unit_pairs) return FALSE;
	for (i=0; i<ik1->no_unit_pairs; i++)
		if ((Kinds::Compare::eq(ik1->unit_pairs[i].fund_unit, ik2->unit_pairs[i].fund_unit) == FALSE) ||
			(ik1->unit_pairs[i].power != ik2->unit_pairs[i].power))
				return FALSE;
	return TRUE;
}

@ We now have three fundamental operations we can perform on unit sequences.
First, we can multiply them: that is, we store in |result| the unit
sequence representing $X_1^{s_1}X_2^{s_2}$, where $X_1$ and $X_2$ are
represented by unit sequences |us1| and |us2|.

So the case $s_1 = s_2 = 1$ represents multiplying $X_1$ by $X_2$, while
$s_1 = 1, s_2 = -1$ represents dividing $X_1$ by $X_2$. But we can also
raise to higher powers.

Our method relies on noting that
$$ X_1 = T_{11}^{p_{11}}\cdot T_{12}^{p_{12}}\cdots T_{1n}^{p_{1n}},\qquad
X_2 = T_{21}^{p_{21}}\cdot T_{22}^{p_{22}}\cdots T_{2m}^{p_{2m}} $$
where $T_{11} < T_{12} < ... < T_{1n}$ and $T_{21}<T_{22}<...<T_{2m}$. We
can therefore merge the two in a single pass.

On each iteration of the loop the variables |i1| and |i2| are our current
read positions in each sequence, while we are currently looking at the
unit pairs (|t1|, |m1|) and (|t2|, |m2|). The following symmetrical
algorithm holds on to each pair until the one from the other sequence has had
a chance to catch up with it, because we always deal with the pair with the
numerically lower |t| first. This also proves that the |results| sequence comes
out in numerical order.

=
void Kinds::Dimensions::multiply_unit_sequences(unit_sequence *us1, int s1, unit_sequence *us2, int s2,
	unit_sequence *result) {
	if ((result == us1) || (result == us2)) internal_error("result must be different structure");

	result->no_unit_pairs = 0;

	int i1 = 0, i2 = 0; /* read position in sequences 1, 2 */
	kind *t1 = NULL; int p1 = 0; /* start with no current term from sequence 1 */
	kind *t2 = NULL; int p2 = 0; /* start with no current term from sequence 2 */
	while (TRUE) {
		@<If we have no current term from sequence 1, and it hasn't run out, fetch a new one@>;
		@<If we have no current term from sequence 2, and it hasn't run out, fetch a new one@>;
		if (Kinds::Compare::eq(t1, t2)) {
			if (t1 == NULL) break; /* both sequences have now run out */
			@<Both terms refer to the same fundamental unit, so combine these into the result@>;
		} else {
			@<The terms refer to different fundamental units, so copy the numerically lower one into the result@>;
		}
	}
	LOGIF(KIND_CREATIONS, "Multiplication: $Q * $Q = $Q\n", us1, us2, result);
}

@<If we have no current term from sequence 1, and it hasn't run out, fetch a new one@> =
	if ((t1 == NULL) && (us1) && (i1 < us1->no_unit_pairs)) {
		t1 = us1->unit_pairs[i1].fund_unit; p1 = us1->unit_pairs[i1].power; i1++;
	}

@<If we have no current term from sequence 2, and it hasn't run out, fetch a new one@> =
	if ((t2 == NULL) && (us2) && (i2 < us2->no_unit_pairs)) {
		t2 = us2->unit_pairs[i2].fund_unit; p2 = us2->unit_pairs[i2].power; i2++;
	}

@ So here the head of one sequence is $T^{p_1}$ and the head of the other
is $T^{p_2}$, so in the product we ought to see $(T^{p_1})^{s_1}\cdot
(T^{p_2})^{s_2} = T^{p_1s_1+p_2s_2}$. But we don't enter terms that have
cancelled out, that is, where $p_1s_1+p_2s_2$ = 0.

@<Both terms refer to the same fundamental unit, so combine these into the result@> =
	int p = p1*s1 + p2*s2; /* combined power of |t1| $=$ |t2| */
	if (p != 0) {
		if (result->no_unit_pairs == MAX_BASE_UNITS_IN_SEQUENCE)
			@<Trip a unit sequence overflow@>;
		result->unit_pairs[result->no_unit_pairs].fund_unit = t1;
		result->unit_pairs[result->no_unit_pairs++].power = p;
	}
	t1 = NULL; t2 = NULL; /* dispose of both terms as dealt with */

@ Otherwise we copy. By copying the numerically lower term, we can be sure
that it will never occur again in either sequence. So we can copy it straight
into the results.

The code is slightly warped by the fact that |UNKNOWN_NT|, representing the
end of the sequence, happens to be numerically lower than all the valid
kinds. We don't want to make use of facts like that, so we write code
to deal with |UNKNOWN_NT| explicitly.

@<The terms refer to different fundamental units, so copy the numerically lower one into the result@> =
	if ((t2 == NULL) || ((t1 != NULL) && (Kinds::Dimensions::kind_prior(t1, t2)))) {
		if (result->no_unit_pairs == MAX_BASE_UNITS_IN_SEQUENCE)
			@<Trip a unit sequence overflow@>;
		result->unit_pairs[result->no_unit_pairs].fund_unit = t1;
		result->unit_pairs[result->no_unit_pairs++].power = p1*s1;
		t1 = NULL; /* dispose of the head of sequence 1 as dealt with */
	} else if ((t1 == NULL) || ((t2 != NULL) && (Kinds::Dimensions::kind_prior(t2, t1)))) {
		if (result->no_unit_pairs == MAX_BASE_UNITS_IN_SEQUENCE)
			@<Trip a unit sequence overflow@>;
		result->unit_pairs[result->no_unit_pairs].fund_unit = t2;
		result->unit_pairs[result->no_unit_pairs++].power = p2*s2;
		t2 = NULL; /* dispose of the head of sequence 1 as dealt with */
	} else internal_error("unit pairs disarrayed");

@ For reasons explained above, this is really never going to happen by
accident, but we'll be careful:

@<Trip a unit sequence overflow@> =
	Kinds::problem_handler(UnitSequenceOverflow_KINDERROR, NULL, NULL, NULL);
	return;

@ The second operation is taking roots.

Surprisingly, perhaps, it's much easier to compute $\sqrt{X}$ or
$^{3}\sqrt{X}$ for any unit $X$ -- it's just that it can't always be done.
Inform does not permit non-integer powers of units, so for instance
$\sqrt{{\rm time}}$ does not exist, whereas $\sqrt{{\rm length}^2\cdot{\rm mass}^{-2}}$
does. Square roots exist if each power in the sequence is even, cube roots
exist if each is divisible by 3. We return |TRUE| or |FALSE| according to
whether the root could be taken, and if |FALSE| then the contents of
|result| are undefined.

=
int Kinds::Dimensions::root_unit_sequence(unit_sequence *us, int pow, unit_sequence *result) {
	if (us == NULL) return FALSE;
	*result = *us;
	int i;
	for (i=0; i<result->no_unit_pairs; i++) {
		if ((result->unit_pairs[i].power) % pow != 0) return FALSE;
		result->unit_pairs[i].power = (result->unit_pairs[i].power)/pow;
	}
	return TRUE;
}

@ The final operation on unit sequences is substitution. Given a fundamental type
$B$, we substitute $B = K_D$ into an existing unit sequence $K_E$. (This is
used when $B$ is becoming a derived type -- once we discover that $B=K_D$,
we are no longer allowed to keep $B$ in any unit sequence.)

We simply search for $B^p$, and if we find it, we remove it and then
multiply by $K_D^p$.

=
void Kinds::Dimensions::dim_substitute(unit_sequence *existing, kind *fundamental, unit_sequence *derived) {
	int i, j, p = 0, found = FALSE;
	if (existing == NULL) return;
	for (i=0; i<existing->no_unit_pairs; i++)
		if (Kinds::Compare::eq(existing->unit_pairs[i].fund_unit, fundamental)) {
			p = existing->unit_pairs[i].power;
			found = TRUE;
			@<Remove the B term from the existing sequence@>;
		}
	if (found)
		@<Multiply the existing sequence by a suitable power of B's derivation@>;
}

@ We shuffle the remaining terms in the sequence down by one, overwriting B:

@<Remove the B term from the existing sequence@> =
	for (j=i; j<existing->no_unit_pairs-1; j++)
		existing->unit_pairs[j] = existing->unit_pairs[j+1];
	existing->no_unit_pairs--;

@ We now multiply by $K_D^p$.

@<Multiply the existing sequence by a suitable power of B's derivation@> =
	unit_sequence result;
	Kinds::Dimensions::multiply_unit_sequences(existing, 1, derived, p, &result);
	*existing = result;

@ For reasons which will be explained below, a unit sequence also has
a scale factor associated with it:

=
int Kinds::Dimensions::us_get_scaling_factor(unit_sequence *us) {
	if (us == NULL) return 1;
	return us->scaling_factor;
}

@ That just leaves, as usual, indexing...

=
void Kinds::Dimensions::index_unit_sequence(OUTPUT_STREAM, unit_sequence *deriv, int briefly) {
	if (deriv == NULL) return;
	if (deriv->no_unit_pairs == 0) { WRITE("dimensionless"); return; }

	int j;
	for (j=0; j<deriv->no_unit_pairs; j++) {
		kind *fundamental = deriv->unit_pairs[j].fund_unit;
		int power = deriv->unit_pairs[j].power;
		if (briefly) {
			if (j>0) WRITE(".");
			WRITE("(");
			#ifdef CORE_MODULE
			Kinds::Index::index_kind(OUT, fundamental, FALSE, FALSE);
			#else
			Kinds::Textual::write(OUT, fundamental);
			#endif
			WRITE(")");
			if (power != 1) WRITE("<sup>%d</sup>", power);
		} else {
			if (j>0) WRITE(" times ");
			if (power < 0) { power = -power; WRITE("reciprocal of "); }
			wording W = Kinds::Behaviour::get_name(fundamental, FALSE);
			WRITE("%W", W);
			switch (power) {
				case 1: break;
				case 2: WRITE(" squared"); break;
				case 3: WRITE(" cubed"); break;
				default: WRITE(" to the power %d", power); break;
			}
		}
	}
}

@ ...and logging.

=
void Kinds::Dimensions::log_unit_sequence(unit_sequence *deriv) {
	if (deriv == NULL) { LOG("<null-us>"); return; }
	if (deriv->no_unit_pairs == 0) { LOG("dimensionless"); return; }

	int j;
	for (j=0; j<deriv->no_unit_pairs; j++) {
		if (j>0) LOG(".");
		LOG("($u)", deriv->unit_pairs[j].fund_unit);
		if (deriv->unit_pairs[j].power != 1) LOG("%d", deriv->unit_pairs[j].power);
	}
}

@h Performing derivations.
The following is called when the user specifies that $L$ times $R$ specifies
an $O$. These are required all to be quasinumerical: any of the three might
be either a fundamental unit (so far) or a derived unit (already).

If two or more are fundamental units, we have a choice. That is, suppose we have
created three kinds already: mass, acceleration, force. Then we read:

>> Mass times acceleration specifies a force.

We could make this true in any of three ways: keep M and A as fundamental units
and derive F from them, keep A and F as fundamental units and derive M from those,
or keep M and F while deriving A. Inform always chooses the most recently
created unit as the one to derive, on the grounds that the source text has
probably set things out with what the user thinks are the most fundamental
units first.

=
void Kinds::Dimensions::make_unit_derivation(kind *left, kind *right, kind *outcome) {
	kind *terms[3];
	terms[0] = left; terms[1] = right; terms[2] = outcome;
	int newest_term = -1;
	@<Find which (if any) of the three units is the newest-made fundamental unit@>;
	if (newest_term >= 0) {
		unit_sequence *derivation = NULL;
		@<Derive the newest one by rearranging the equation in terms of the other two@>;
		@<Substitute this new derivation to eliminate this fundamental unit from other sequences@>;
	} else
		@<Check this derivation to make sure it is redundant, not contradictory@>;
}

@ Data type IDs are allocated in creation order, so "newest" means largest ID.

@<Find which (if any) of the three units is the newest-made fundamental unit@> =
	int i; kind *max = NULL;
	for (i=0; i<3; i++)
		if ((Kinds::Dimensions::kind_prior(max, terms[i])) && (Kinds::Behaviour::test_if_derived(terms[i]) == FALSE)) {
			newest_term = i; max = terms[i];
		}

@ We need to ensure that the user's multiplication rule is henceforth true,
and we do that by fixing the newest unit to make it so.

@<Derive the newest one by rearranging the equation in terms of the other two@> =
	unit_sequence *kx = NULL, *ky = NULL; int sx = 0, sy = 0;
	switch (newest_term) {
		case 0: /* here $L$ is newest and we derive $L = R^{-1}O$ */
			kx = Kinds::Behaviour::get_dimensional_form(terms[1]); sx = -1;
			ky = Kinds::Behaviour::get_dimensional_form(terms[2]); sy = 1;
			break;
		case 1: /* here $R$ is newest and we derive $R = L^{-1}O$ */
			kx = Kinds::Behaviour::get_dimensional_form(terms[0]); sx = -1;
			ky = Kinds::Behaviour::get_dimensional_form(terms[2]); sy = 1;
			break;
		case 2: /* here $O$ is newest and we derive $O = LR$ */
			kx = Kinds::Behaviour::get_dimensional_form(terms[0]); sx = 1;
			ky = Kinds::Behaviour::get_dimensional_form(terms[1]); sy = 1;
			break;
	}
	derivation = Kinds::Behaviour::get_dimensional_form(terms[newest_term]);
	unit_sequence result;
	Kinds::Dimensions::multiply_unit_sequences(kx, sx, ky, sy, &result);
	*derivation = result;
	Kinds::Behaviour::now_derived(terms[newest_term]);

@ Later in Inform's run, when we start compiling code, many more unit sequences
will exist on a temporary basis -- as part of the kinds for intermediate results
in calculations -- but early on, when we're here, the only unit sequences made
are the derivations of the units. So it is easy to cover all of them.

@<Substitute this new derivation to eliminate this fundamental unit from other sequences@> =
	kind *R;
	LOOP_OVER_BASE_KINDS(R)
		if (Kinds::Behaviour::is_quasinumerical(R)) {
			unit_sequence *existing = Kinds::Behaviour::get_dimensional_form(R);
			Kinds::Dimensions::dim_substitute(existing, terms[newest_term], derivation);
		}

@ If we have $AB = C$ but all three of $A$, $B$, $C$ are already derived,
that puts us in a bind. Their definitions are fixed already, so we can't
simply force the equation to come true by fixing one of them. That means
either the derivation is redundant -- because it's already true that
$AB = C$ -- or contradictory -- because we know $AB\neq C$. We silently
allow a redundancy, as it may have been put in for clarity, or so that
the user can check the consistency of his own definitions, or to make
the Kinds index page more helpful. But we must reject a contradiction.

@<Check this derivation to make sure it is redundant, not contradictory@> =
	unit_sequence product;
	Kinds::Dimensions::multiply_unit_sequences(
		Kinds::Behaviour::get_dimensional_form(terms[0]), 1,
		Kinds::Behaviour::get_dimensional_form(terms[1]), 1, &product);
	if (Kinds::Dimensions::compare_unit_sequences(&product,
		Kinds::Behaviour::get_dimensional_form(terms[2])) == FALSE)
		Kinds::problem_handler(DimensionsInconsistent_KINDERROR, NULL, NULL, NULL);

@h Classifying the units.
Some of the derived units are dimensionless, others not. Number
is always dimensionless; and any unit whose derivation is the empty
unit sequence must be dimensionless.

=
int Kinds::Dimensions::dimensionless(kind *K) {
	if (K == NULL) return FALSE;
	if (Kinds::Compare::eq(K, K_number)) return TRUE;
	if (Kinds::Compare::eq(K, K_real_number)) return TRUE;
	if (Kinds::Behaviour::is_quasinumerical(K) == FALSE) return FALSE;
	return Kinds::Dimensions::us_dimensionless(Kinds::Behaviour::get_dimensional_form(K));
}

int Kinds::Dimensions::us_dimensionless(unit_sequence *us) {
	if ((us) && (us->no_unit_pairs == 0)) return TRUE;
	return FALSE;
}

@ Using these definitions, we can now print analyses of the units into the
index and the debugging log.

=
#ifdef CORE_MODULE
void Kinds::Dimensions::index_dimensional_rules(OUTPUT_STREAM) {
	HTML_TAG("hr");
	@<Index the rubric about quasinumerical kinds@>;
	@<Index the table of quasinumerical kinds@>;
	@<Index the table of multiplication rules@>;
}
#endif

@<Index the rubric about quasinumerical kinds@> =
	HTML_OPEN("p");
	HTML_TAG_WITH("a", "calculator");
	HTML::begin_plain_html_table(OUT);
	HTML::first_html_column(OUT, 0);
	HTML_TAG_WITH("img", "border=0 src=inform:/doc_images/calc2.png");
	WRITE("&nbsp;");
	WRITE("Kinds of value marked with the <b>calculator symbol</b> are numerical - "
		"these are values we can add, multiply and so on. The range of these "
		"numbers depends on the Format setting for the project (Glulx format "
		"supports much higher numbers than Z-code).");
	HTML::end_html_row(OUT);
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");

@<Index the table of quasinumerical kinds@> =
	HTML_OPEN("p");
	HTML::begin_plain_html_table(OUT);

	HTML::first_html_column(OUT, 0);
	WRITE("<b>kind of value</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>minimum</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>maximum</b>");
	HTML::next_html_column(OUT, 0);
	WRITE("<b>dimensions</b>");
	HTML::end_html_row(OUT);

	kind *R;
	LOOP_OVER_BASE_KINDS(R)
		if (Kinds::Behaviour::is_quasinumerical(R)) {
			if (Kinds::is_intermediate(R)) continue;
			HTML::first_html_column(OUT, 0);
			Kinds::Index::index_kind(OUT, R, FALSE, FALSE);
			HTML::next_html_column(OUT, 0);
			@<Index the minimum positive value for a quasinumerical kind@>;
			HTML::next_html_column(OUT, 0);
			@<Index the maximum positive value for a quasinumerical kind@>;
			HTML::next_html_column(OUT, 0);
			if (Kinds::Dimensions::dimensionless(R)) WRITE("<i>dimensionless</i>");
			else {
				unit_sequence *deriv = Kinds::Behaviour::get_dimensional_form(R);
				Kinds::Dimensions::index_unit_sequence(OUT, deriv, TRUE);
			}
			HTML::end_html_row(OUT);
		}
	HTML::end_html_table(OUT);
	HTML_CLOSE("p");

@ At run-time, the minimum positive value is of course |1|, but because of
scaling this can appear to be much lower.

@<Index the minimum positive value for a quasinumerical kind@> =
	if (Kinds::Compare::eq(R, K_number)) WRITE("1");
	else {
		text_stream *p = Kinds::Behaviour::get_index_minimum_value(R);
		if (Str::len(p) > 0) WRITE("%S", p);
		else LiteralPatterns::index_value(OUT,
			LiteralPatterns::list_of_literal_forms(R), 1);
	}

@<Index the maximum positive value for a quasinumerical kind@> =
	if (Kinds::Compare::eq(R, K_number)) {
		if (TargetVMs::is_16_bit(Task::vm())) WRITE("32767");
		else WRITE("2147483647");
	} else {
		text_stream *p = Kinds::Behaviour::get_index_maximum_value(R);
		if (Str::len(p) > 0) WRITE("%S", p);
		else {
			if (TargetVMs::is_16_bit(Task::vm()))
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(R), 32767);
			else
				LiteralPatterns::index_value(OUT,
					LiteralPatterns::list_of_literal_forms(R), 2147483647);
		}
	}


@ This is simply a table of all the multiplications declared in the source
text, sorted into kind order of left and then right operand.

@<Index the table of multiplication rules@> =
	kind *L, *R, *O;
	int NP = 0, wn;
	LOOP_OVER_MULTIPLICATIONS(L, R, O, wn) {
		if (NP++ == 0) {
			HTML_OPEN("p");
			WRITE("This is how multiplication changes kinds:");
			HTML_CLOSE("p");
			HTML_OPEN("p");
			HTML::begin_plain_html_table(OUT);
		}
		HTML::first_html_column(OUT, 0);
		if (wn >= 0) Index::link(OUT, wn);
		HTML::next_html_column(OUT, 0);
		Kinds::Index::index_kind(OUT, L, FALSE, FALSE);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" x ");
		HTML::end_colour(OUT);
		Kinds::Index::index_kind(OUT, R, FALSE, FALSE);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" = ");
		HTML::end_colour(OUT);
		Kinds::Index::index_kind(OUT, O, FALSE, FALSE);
		WRITE("&nbsp;&nbsp;&nbsp;&nbsp;");
		HTML::next_html_column(OUT, 0);
		LiteralPatterns::index_benchmark_value(OUT, L);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" x ");
		HTML::end_colour(OUT);
		LiteralPatterns::index_benchmark_value(OUT, R);
		HTML::begin_colour(OUT, I"808080");
		WRITE(" = ");
		HTML::end_colour(OUT);
		LiteralPatterns::index_benchmark_value(OUT, O);
		HTML::end_html_row(OUT);
	}
	if (NP > 0) { HTML::end_html_table(OUT); HTML_CLOSE("p"); }

@ A simpler format for the debugging log, which is printed when we ask for
the internal "dimensions" test:

=
void Kinds::Dimensions::log_unit_analysis(void) {
	LOG("Dimensionless: ");
	int c = 0; kind *R;
	LOOP_OVER_BASE_KINDS(R)
		if (Kinds::Dimensions::dimensionless(R)) { if (c++ > 0) LOG(", "); LOG("$u", R); }
	LOG("\nBase units: ");
	c = 0;
	LOOP_OVER_BASE_KINDS(R)
		if ((Kinds::Dimensions::dimensionless(R) == FALSE) &&
			(Kinds::Dimensions::kind_is_derived(R) == FALSE) &&
			(Kinds::Behaviour::is_quasinumerical(R)))
		{ if (c++ > 0) LOG(", "); LOG("$u", R); }
	LOG("\nDerived units:\n");
	LOOP_OVER_BASE_KINDS(R)
		if ((Kinds::Dimensions::kind_is_derived(R)) && (Kinds::is_intermediate(R) == FALSE)) {
			unit_sequence *deriv = Kinds::Behaviour::get_dimensional_form(R);
			LOG("$u = $Q\n", R, deriv);
		}
}

int Kinds::Dimensions::kind_is_derived(kind *K) {
	if (Kinds::is_intermediate(K)) return TRUE;
	if ((Kinds::Behaviour::is_quasinumerical(K)) &&
		(Kinds::Behaviour::test_if_derived(K) == TRUE) &&
		(Kinds::Dimensions::dimensionless(K) == FALSE)) return TRUE;
	return FALSE;
}

@h Scaling.
Recall that every quasinumerical kind $U$ has a scale factor $k_U$, by
default 1 and always $\geq 1$, such that the true value $v$ is represented
at runtime as the I6 integer $k_U v$. For instance, if length is measured
in metres but has a scale factor of 1000 then the I6 integer 1 means the
true value 1mm, 10 means 1cm, 1000 means 1m. This I6 integer is called
the scaled value $s$, and to reiterate, $s = k_U v$.

Scaled values are convenient, and they have no effect on how we add, subtract,
approximate (that is, round off) or take remainder after division. If we
have true values $v_1$ and $v_2$ with scaled values $s_1$ and $s_2$,
and $s_o$ is the scaled value for true value $v_1+v_2$, then

$$ s_1 + s_2 = k_Uv_1 + k_Uv_2 = k_U(v_1+v_2) = s_o. $$

So ordinary I6 |+| at run-time correctly adds scaled values. But that's
not true for all operations, and this is where we deal with that.

@ First, multiplication. This time the values $v_1$ and $v_2$ may have
different kinds, which we'll call $X$ and $Y$, and the result in general
will be a third kind, which we'll call $O$ (for outcome). Then:

$$ s_1s_2 = k_Xv_1\cdot k_Yv_2 = k_Ov_1v_2\cdot\left({{k_Xk_Y}\over{k_O}}\right) = s_o\cdot\left({{k_Xk_Y}\over{k_O}}\right) $$

so that simply multiplying the scaled values produces an answer which is
too large by a factor of $k_Xk_Y/k_O$. We need to correct for that, which
we do either by dividing by this factor or multiplying by its reciprocal.

This is all a little delicate since rounding errors may be an issue and
since $k_Xk_Y/k_O$ is itself evaluated in integer arithmetic. In an ideal
world we might use the same $k$ for many units (e.g., $k=1000$ throughout)
and then of course this cancels to just $1000$. But in practice people
won't always do this -- they may use some Babylonian, base 60, units, such
as minutes and degrees, for instance, where $k=3600$ would be more natural.

=
void Kinds::Dimensions::kind_rescale_multiplication(OUTPUT_STREAM, kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, TIMES_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_X*k_Y > k_O) WRITE("/%d", (k_X*k_Y/k_O));
	if (k_X*k_Y < k_O) WRITE("*%d", (k_O/k_X/k_Y));
}

#ifdef CORE_MODULE
void Kinds::Dimensions::kind_rescale_multiplication_emit_op(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, TIMES_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_X*k_Y > k_O) { Produce::inv_primitive(Emit::tree(), DIVIDE_BIP); Produce::down(Emit::tree()); }
	if (k_X*k_Y < k_O) { Produce::inv_primitive(Emit::tree(), TIMES_BIP); Produce::down(Emit::tree()); }
}

void Kinds::Dimensions::kind_rescale_multiplication_emit_factor(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, TIMES_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_X*k_Y > k_O) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_X*k_Y/k_O)); Produce::up(Emit::tree()); }
	if (k_X*k_Y < k_O) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_O/k_X/k_Y)); Produce::up(Emit::tree()); }
}
#endif

@ Second, division, which is similar.
$$ {{s_1}\over{s_2}} = {{k_Xv_1}\over{k_Yv_2}} = k_O{{v_1}\over{v_2}}\cdot\left({{k_X}\over{k_Ok_Y}}\right)
    = s_o\cdot\left({{k_X}\over{k_Ok_Y}\right) $$
so this time the excess to correct is a factor of $k_X/k_Ok_Y$.

=
void Kinds::Dimensions::kind_rescale_division(OUTPUT_STREAM, kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, DIVIDE_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_O*k_Y > k_X) WRITE("*%d", (k_O*k_Y/k_X));
	if (k_O*k_Y < k_X) WRITE("/%d", (k_X/k_O/k_Y));
}

#ifdef CORE_MODULE
void Kinds::Dimensions::kind_rescale_division_emit_op(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, DIVIDE_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_O*k_Y > k_X) { Produce::inv_primitive(Emit::tree(), TIMES_BIP); Produce::down(Emit::tree()); }
	if (k_O*k_Y < k_X) { Produce::inv_primitive(Emit::tree(), DIVIDE_BIP); Produce::down(Emit::tree()); }
}

void Kinds::Dimensions::kind_rescale_division_emit_factor(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, DIVIDE_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_O*k_Y > k_X) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_O*k_Y/k_X)); Produce::up(Emit::tree()); }
	if (k_O*k_Y < k_X) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_X/k_O/k_Y)); Produce::up(Emit::tree()); }
}
#endif

@ Third, the taking of $p$th roots, at any rate for $p=2$ or $p=3$.

=
void Kinds::Dimensions::kind_rescale_root(OUTPUT_STREAM, kind *kindx, int power) {
	if (kindx == NULL) return;
	kind *kindo = NULL;
	if (power == 2) kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, NULL, ROOT_OPERATION);
	if (power == 3) kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, NULL, CUBEROOT_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_O = Kinds::Behaviour::scale_factor(kindo);

	if (power == 2) @<Apply a scaling correction for square roots@>
	else if (power == 3) @<Apply a scaling correction for cube roots@>
	else internal_error("can only scale square and cube roots");
}

@ For square roots,
$$ \sqrt{s} = \sqrt{k_Xv} = \sqrt{k_X}\sqrt{v} = k_O\sqrt{v}\cdot
\left({{\sqrt{k_X}}\over{k_O}}\right) = s_o \cdot
\left({{\sqrt{k_X}}\over{k_O}}\right) $$
and now the overestimate is a factor of $k = \sqrt{k_X}/k_O$. However,
rather than calculating $k\sqrt{x}$ we calculate $\sqrt{k^2 x}$, since
this way accuracy losses in taking the square root are much reduced.
Therefore this scaling operating is to be performed inside the root
function, not outside, and it scales by $k^2$ not $k$:

@<Apply a scaling correction for square roots@> =
	if (k_O*k_O > k_X) WRITE("*%d", (k_O*k_O/k_X));
	if (k_O*k_O < k_X) WRITE("/%d", (k_X/k_O/k_O));

@ For cube roots,
$$ {}^3\sqrt{s} = {}^3\sqrt{k_Xv} = {}^3\sqrt{k_X}{}^3\sqrt{v} = k_O{}^3\sqrt{v}\cdot
\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) = s_o\cdot
\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) $$
and the overestimate is $k = {}^3\sqrt{k_X}/k_O$. Scaling once again within
the rooting function, we scale by $k^3$:

@<Apply a scaling correction for cube roots@> =
	if (k_O*k_O*k_O > k_X) WRITE("*%d", (k_O*k_O*k_O/k_X));
	if (k_O*k_O*k_O < k_X) WRITE("/%d", (k_X/k_O/k_O/k_O));

@ =
#ifdef CORE_MODULE
void Kinds::Dimensions::kind_rescale_root_emit_op(kind *kindx, int power) {
	if (kindx == NULL) return;
	kind *kindo = NULL;
	if (power == 2) kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, NULL, ROOT_OPERATION);
	if (power == 3) kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, NULL, CUBEROOT_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_O = Kinds::Behaviour::scale_factor(kindo);

	if (power == 2) @<Emit a scaling correction for square roots@>
	else if (power == 3) @<Emit a scaling correction for cube roots@>
	else internal_error("can only scale square and cube roots");
}
#endif

@ For square roots,
$$ \sqrt{s} = \sqrt{k_Xv} = \sqrt{k_X}\sqrt{v} = k_O\sqrt{v}\cdot
\left({{\sqrt{k_X}}\over{k_O}}\right) = s_o \cdot
\left({{\sqrt{k_X}}\over{k_O}}\right) $$
and now the overestimate is a factor of $k = \sqrt{k_X}/k_O$. However,
rather than calculating $k\sqrt{x}$ we calculate $\sqrt{k^2 x}$, since
this way accuracy losses in taking the square root are much reduced.
Therefore this scaling operating is to be performed inside the root
function, not outside, and it scales by $k^2$ not $k$:

@<Emit a scaling correction for square roots@> =
	if (k_O*k_O > k_X) { Produce::inv_primitive(Emit::tree(), TIMES_BIP); Produce::down(Emit::tree()); }
	if (k_O*k_O < k_X) { Produce::inv_primitive(Emit::tree(), DIVIDE_BIP); Produce::down(Emit::tree()); }

@ For cube roots,
$$ {}^3\sqrt{s} = {}^3\sqrt{k_Xv} = {}^3\sqrt{k_X}{}^3\sqrt{v} = k_O{}^3\sqrt{v}\cdot
\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) = s_o\cdot
\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) $$
and the overestimate is $k = {}^3\sqrt{k_X}/k_O$. Scaling once again within
the rooting function, we scale by $k^3$:

@<Emit a scaling correction for cube roots@> =
	if (k_O*k_O*k_O > k_X) { Produce::inv_primitive(Emit::tree(), TIMES_BIP); Produce::down(Emit::tree()); }
	if (k_O*k_O*k_O < k_X) { Produce::inv_primitive(Emit::tree(), DIVIDE_BIP); Produce::down(Emit::tree()); }

@ =
#ifdef CORE_MODULE
void Kinds::Dimensions::kind_rescale_root_emit_factor(kind *kindx, int power) {
	if (kindx == NULL) return;
	kind *kindo = NULL;
	if (power == 2) kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, NULL, ROOT_OPERATION);
	if (power == 3) kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, NULL, CUBEROOT_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_O = Kinds::Behaviour::scale_factor(kindo);

	if (power == 2) @<Emit factor for a scaling correction for square roots@>
	else if (power == 3) @<Emit factor for a scaling correction for cube roots@>
	else internal_error("can only scale square and cube roots");
}
#endif

@ For square roots,
$$ \sqrt{s} = \sqrt{k_Xv} = \sqrt{k_X}\sqrt{v} = k_O\sqrt{v}\cdot
\left({{\sqrt{k_X}}\over{k_O}}\right) = s_o \cdot
\left({{\sqrt{k_X}}\over{k_O}}\right) $$
and now the overestimate is a factor of $k = \sqrt{k_X}/k_O$. However,
rather than calculating $k\sqrt{x}$ we calculate $\sqrt{k^2 x}$, since
this way accuracy losses in taking the square root are much reduced.
Therefore this scaling operating is to be performed inside the root
function, not outside, and it scales by $k^2$ not $k$:

@<Emit factor for a scaling correction for square roots@> =
	if (k_O*k_O > k_X) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_O*k_O/k_X)); Produce::up(Emit::tree()); }
	if (k_O*k_O < k_X) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_X/k_O/k_O)); Produce::up(Emit::tree()); }

@ For cube roots,
$$ {}^3\sqrt{s} = {}^3\sqrt{k_Xv} = {}^3\sqrt{k_X}{}^3\sqrt{v} = k_O{}^3\sqrt{v}\cdot
\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) = s_o\cdot
\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) $$
and the overestimate is $k = {}^3\sqrt{k_X}/k_O$. Scaling once again within
the rooting function, we scale by $k^3$:

@<Emit factor for a scaling correction for cube roots@> =
	if (k_O*k_O*k_O > k_X) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_O*k_O*k_O/k_X)); Produce::up(Emit::tree()); }
	if (k_O*k_O*k_O < k_X) { Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_t) (k_X/k_O/k_O/k_O)); Produce::up(Emit::tree()); }

@h Arithmetic on kinds.
We are finally able to provide our central routine, the one providing a service
for the rest of Inform. Given |K1| and |K2|, we return the kind resulting
from applying arithmetic operation |op|, or |NULL| if the operation cannot
meaningfully be applied. In the case where |op| is a unary operation, |K2|
has no significance and should be |NULL|.

The kinds here are called operands, because they are what will be operated on.

=
kind *Kinds::Dimensions::arithmetic_on_kinds(kind *K1, kind *K2, int op) {
	if (K1 == NULL) return NULL;
	if ((Kinds::Dimensions::arithmetic_op_is_unary(op) == FALSE) && (K2 == NULL)) return NULL;

	unit_sequence *operand1 = Kinds::Behaviour::get_dimensional_form(K1);
	if (operand1 == NULL) return NULL;
	unit_sequence *operand2 = Kinds::Behaviour::get_dimensional_form(K2);
	if ((Kinds::Dimensions::arithmetic_op_is_unary(op) == FALSE) && (operand2 == NULL)) return NULL;

	unit_sequence result;

	switch (op) {
		case PLUS_OPERATION:
		case MINUS_OPERATION:
		case EQUALS_OPERATION:
		case APPROXIMATION_OPERATION:
			if (Kinds::Dimensions::compare_unit_sequences(operand1, operand2)) {
				result = *operand1;
				break;
			}
			return NULL;
		case UNARY_MINUS_OPERATION:
		case REMAINDER_OPERATION:
			result = *operand1;
			break;
		case ROOT_OPERATION:
			if (Kinds::Dimensions::root_unit_sequence(operand1, 2, &result) == FALSE)
				return NULL;
			break;
		case REALROOT_OPERATION:
			if (Kinds::Dimensions::root_unit_sequence(operand1, 2, &result) == FALSE)
				return NULL;
			break;
		case CUBEROOT_OPERATION:
			if (Kinds::Dimensions::root_unit_sequence(operand1, 3, &result) == FALSE)
				return NULL;
			break;
		case TIMES_OPERATION:
			Kinds::Dimensions::multiply_unit_sequences(operand1, 1, operand2, 1, &result);
			break;
		case DIVIDE_OPERATION:
			Kinds::Dimensions::multiply_unit_sequences(operand1, 1, operand2, -1, &result);
			break;
		default: return NULL;
	}

	@<Handle calculations entirely between dimensionless units more delicately@>;
	@<Handle the case of a dimensionless result@>;
	@<Identify the result as a known kind, if possible@>;
	@<And otherwise create a kind as the intermediate result of a calculation@>;
}

@ If |result| is the empty unit sequence, we'll identify it as a number,
because number is the lowest type ID representing a dimensionless unit.
Usually that's good: for instance, it says that a frequency times a time
is a number, and not some more exotic dimensionless quantity like an angle.

But it's not so good when the calculation is not really physical at all, but
purely mathematical, and all we are doing is working on dimensionless units.
For instance, if take an angle $\theta$ and double it to $2\theta$, we don't
want Inform to say the result is number -- we want $2\theta$ to be
another angle. So we make an exception.

@<Handle calculations entirely between dimensionless units more delicately@> =
	if (Kinds::Dimensions::arithmetic_op_is_unary(op)) {
		if ((op == REALROOT_OPERATION) && (Kinds::Compare::eq(K1, K_number)))
			return K_real_number;
		if (Kinds::Dimensions::dimensionless(K1)) return K1;
	} else {
		if ((Kinds::Dimensions::dimensionless(K1)) &&
			(Kinds::Dimensions::dimensionless(K2))) {
			if (Kinds::Compare::eq(K2, K_number)) return K1;
			if (Kinds::Compare::eq(K1, K_number)) return K2;
			if (Kinds::Compare::eq(K1, K2)) return K1;
		}
	}

@ It's also possible to get a dimensionless result by, for example, dividing
a mass by another mass, and we need to be careful to keep track of whether
we're using real or integer arithmetic: 1500.0m divided by 10.0m must be
150.0, not 150.

@<Handle the case of a dimensionless result@> =
	if (Kinds::Dimensions::us_dimensionless(&result)) {
		if (Kinds::Dimensions::arithmetic_op_is_unary(op)) {
			if (Kinds::FloatingPoint::uses_floating_point(K1)) return K_real_number;
			return K_number;
		} else {
			if ((Kinds::FloatingPoint::uses_floating_point(K1)) ||
				(Kinds::FloatingPoint::uses_floating_point(K2))) return K_real_number;
			return K_number;
		}
	}

@ If we've produced the right combination of fundamental units to make one of the
named units, then we return that as an atomic kind. For instance, maybe we
divided a velocity by a time, and now we find that we have ${\rm m}\cdot
{\rm s}^{-2}$, which turns out to have a name: acceleration.

@<Identify the result as a known kind, if possible@> =
	kind *R;
	LOOP_OVER_BASE_KINDS(R)
		if (Kinds::Dimensions::compare_unit_sequences(&result,
			Kinds::Behaviour::get_dimensional_form(R)))
			return R;

@ Otherwise the |result| is a unit sequence which doesn't have a name, so
we store it as an intermediate kind, representing a temporary value living
only for the duration of a calculation.

A last little wrinkle is: how we should scale this? For results like an
acceleration, something defined in the source text, we know how accurate the
author wants us to be. But these intermediate kinds are not defined, and we
don't know for sure what the author would want. It seems wise to set
$k \geq k_X$ and $k\geq k_Y$, so that we have at least as much detail as
the calculation would have had within each operand kind. So perhaps we should
put $k = {\rm max}(k_X, k_Y)$. But in fact we will choose $k$ = |Kinds::Dimensions::lcm(k_X, k_Y)|,
the least common multiple, so that any subsequent divisions will cancel
correctly and we won't lose too much information through integer rounding.
(In practice this will probably either be the same as ${\rm max}(k_X, k_Y)$
or will multiply by 6, since |Kinds::Dimensions::lcm(60, 1000) == 6000| and so on.)

The same unit sequence can have different scalings each time it appears as
an intermediate calculation. We could get to ${\rm m}^2\cdot {\rm kg}$
either as ${\rm m}\cdot{\rm kg}$ times ${\rm m}$, or as ${\rm m^2}$ times
${\rm kg}$, or many other ways, and we'll get different scalings depending
on the route. This is why the |unit_sequence| structure has a
|scaling_factor| field; the choice of scale factor does not depend on
the physics but on the arithmetic method being used.

@<And otherwise create a kind as the intermediate result of a calculation@> =
	result.scaling_factor = Kinds::Dimensions::lcm(Kinds::Behaviour::scale_factor(K1), Kinds::Behaviour::scale_factor(K2));
	return Kinds::intermediate_construction(&result);

@ =
kind *Kinds::Dimensions::to_rational_power(kind *F, int n, int m) {
	if ((n < 1) || (m < 1)) internal_error("bad rational power");
	if (Kinds::Dimensions::dimensionless(F)) return F;
	kind *K = K_number;
	int op = TIMES_OPERATION;
	if (n < 0) { n = -n; op = DIVIDE_OPERATION; }
	while (n > 0) {
		K = Kinds::Dimensions::arithmetic_on_kinds(K, F, op);
		n--;
	}
	if (m == 1) return K;

	unit_sequence result;
	unit_sequence *operand = Kinds::Behaviour::get_dimensional_form(K);
	if (Kinds::Dimensions::root_unit_sequence(operand, m, &result) == FALSE) return NULL;
	@<Identify the result as a known kind, if possible@>;
	return NULL;
}
