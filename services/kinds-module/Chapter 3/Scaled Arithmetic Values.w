[Kinds::Scalings::] Scaled Arithmetic Values.

To manage the scalings and offsets used when storing arithmetic
values at run-time, and/or when using scaled units to refer to them.

@h Scaling.
Quasinumerical kinds are sometimes stored using scaled, fixed-point
arithmetic. In general for each named unit $U$ (fundamental or derived) there
is a positive integer $k_U$ such that the true value $v$ is stored at run-time
as the I6 integer $k_U v$. We call this the scaled value.

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

@ Scaled values have no effect on how we add, subtract, approximate (that is,
round off) or take remainder after division. If we have true values $v_1$ and
$v_2$ with scaled values $s_1$ and $s_2$, and $s_o$ is the scaled value for
true value $v_1+v_2$, then

$$ s_1 + s_2 = k_Uv_1 + k_Uv_2 = k_U(v_1+v_2) = s_o. $$

Multiplication is not so easy. This time the values $v_1$ and $v_2$ may have
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
#ifdef CORE_MODULE
void Kinds::Scalings::rescale_multiplication_emit_op(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, TIMES_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_X*k_Y > k_O) {
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP); Emit::down();
	}
	if (k_X*k_Y < k_O) {
		Produce::inv_primitive(Emit::tree(), TIMES_BIP); Emit::down();
	}
}

void Kinds::Scalings::rescale_multiplication_emit_factor(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, TIMES_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_X*k_Y > k_O) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_X*k_Y/k_O));
		Emit::up();
	}
	if (k_X*k_Y < k_O) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_O/k_X/k_Y));
		Emit::up();
	}
}
#endif

@ Second, division, which is similar.
$$ {{s_1}\over{s_2}} = {{k_Xv_1}\over{k_Yv_2}} = k_O{{v_1}\over{v_2}}\cdot\left({{k_X}\over{k_Ok_Y}}\right) = s_o\cdot\left({{k_X}\over{k_Ok_Y}\right) $$
so this time the excess to correct is a factor of $k_X/k_Ok_Y$.

=
#ifdef CORE_MODULE
void Kinds::Scalings::rescale_division_emit_op(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, DIVIDE_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_O*k_Y > k_X) {
		Produce::inv_primitive(Emit::tree(), TIMES_BIP);
		Emit::down();
	}
	if (k_O*k_Y < k_X) {
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
		Emit::down();
	}
}

void Kinds::Scalings::rescale_division_emit_factor(kind *kindx, kind *kindy) {
	if ((kindx == NULL) || (kindy == NULL)) return;
	kind *kindo = Kinds::Dimensions::arithmetic_on_kinds(kindx, kindy, DIVIDE_OPERATION);
	if (kindo == NULL) return;
	int k_X = Kinds::Behaviour::scale_factor(kindx);
	int k_Y = Kinds::Behaviour::scale_factor(kindy);
	int k_O = Kinds::Behaviour::scale_factor(kindo);
	if (k_O*k_Y > k_X) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_O*k_Y/k_X));
		Emit::up();
	}
	if (k_O*k_Y < k_X) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_X/k_O/k_Y));
		Emit::up();
	}
}
#endif

@ Third, the taking of $p$th roots, at any rate for $p=2$ or $p=3$.

=
#ifdef CORE_MODULE
void Kinds::Scalings::rescale_root_emit_op(kind *kindx, int power) {
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
$$ \sqrt{s} = \sqrt{k_Xv} = \sqrt{k_X}\sqrt{v} = k_O\sqrt{v}\cdot\left({{\sqrt{k_X}}\over{k_O}}\right) = s_o \cdot\left({{\sqrt{k_X}}\over{k_O}}\right) $$
and now the overestimate is a factor of $k = \sqrt{k_X}/k_O$. However,
rather than calculating $k\sqrt{x}$ we calculate $\sqrt{k^2 x}$, since
this way accuracy losses in taking the square root are much reduced.
Therefore this scaling operating is to be performed inside the root
function, not outside, and it scales by $k^2$ not $k$:

@<Emit a scaling correction for square roots@> =
	if (k_O*k_O > k_X) {
		Produce::inv_primitive(Emit::tree(), TIMES_BIP); Emit::down();
	}
	if (k_O*k_O < k_X) {
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP); Emit::down();
	}

@ For cube roots,
$$ {}^3\sqrt{s} = {}^3\sqrt{k_Xv} = {}^3\sqrt{k_X}{}^3\sqrt{v} = k_O{}^3\sqrt{v}\cdot\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) = s_o\cdot\left({{{}^3\sqrt{k_X}}\over{k_O}}\right) $$
and the overestimate is $k = {}^3\sqrt{k_X}/k_O$. Scaling once again within
the rooting function, we scale by $k^3$:

@<Emit a scaling correction for cube roots@> =
	if (k_O*k_O*k_O > k_X) {
		Produce::inv_primitive(Emit::tree(), TIMES_BIP); Emit::down();
	}
	if (k_O*k_O*k_O < k_X) {
		Produce::inv_primitive(Emit::tree(), DIVIDE_BIP); Emit::down();
	}

@ =
#ifdef CORE_MODULE
void Kinds::Scalings::rescale_root_emit_factor(kind *kindx, int power) {
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
$$ \sqrt{s} = \sqrt{k_Xv} = \sqrt{k_X}\sqrt{v} = k_O\sqrt{v}\cdot \left({{\sqrt{k_X}}\over{k_O}}\right) = s_o \cdot \left({{\sqrt{k_X}}\over{k_O}}\right) $$
and now the overestimate is a factor of $k = \sqrt{k_X}/k_O$. However,
rather than calculating $k\sqrt{x}$ we calculate $\sqrt{k^2 x}$, since
this way accuracy losses in taking the square root are much reduced.
Therefore this scaling operating is to be performed inside the root
function, not outside, and it scales by $k^2$ not $k$:

@<Emit factor for a scaling correction for square roots@> =
	if (k_O*k_O > k_X) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_O*k_O/k_X));
		Emit::up();
	}
	if (k_O*k_O < k_X) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_X/k_O/k_O)); 
		Emit::up();
	}

@ For cube roots,
$$ {}^3\sqrt{s} = {}^3\sqrt{k_Xv} = {}^3\sqrt{k_X}{}^3\sqrt{v} = k_O{}^3\sqrt{v}\cdot \left({{{}^3\sqrt{k_X}}\over{k_O}}\right) = s_o\cdot \left({{{}^3\sqrt{k_X}}\over{k_O}}\right) $$
and the overestimate is $k = {}^3\sqrt{k_X}/k_O$. Scaling once again within
the rooting function, we scale by $k^3$:

@<Emit factor for a scaling correction for cube roots@> =
	if (k_O*k_O*k_O > k_X) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_O*k_O*k_O/k_X));
		Emit::up();
	}
	if (k_O*k_O*k_O < k_X) {
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (k_X/k_O/k_O/k_O));
		Emit::up();
	}

@h Scaling transformations.
A "scaling transformation" defines the relationship between the number
as written and the number stored at runtime. The conversion between the
two is always a linear function: a number written as |x kg| is stored
as |M*x + O| at run-time for constants |M| and |O|, the "multiplier"
and the "offset". |M| must be positive, |O| must be positive or zero.

Units typically have a range of different literal patterns with different
scalings: for example, "1 mm", "1 cm", "1 m", "1 km". One of these patterns
is designated as the "benchmark": in the case of length, probably "1 m".
This is the one we think of abstractly as the natural notation to use
when we don't know that the value is particularly large or small.

@ We have to implement all of this twice, in subtly different ways, to
cope with the fact that some units use integer arithmetic and others
use real.

(a) Real units are easier. A value of |1.0| stored at run-time equals
1 benchmark unit: in our length example, 1 m. Thus the |M| value for the
benchmark scaling is always 1.0.

(b) Integer units are harder. If we stored 1 m as the integer 1, we
would be unable to express any distance smaller than that, and "1 cm"
or "1 mm" would vanish completely. Instead we scale so that the value
1 stored at run-time equals 1 unit of our smallest scale: in the length
example, 1 mm. The |M| value for the benchmark is now usually not 1 --
in this example, it's 1000, because one benchmark unit (1 m) is stored
as the integer 1000.

@ The benchmark |M| has a special significance because it affects the
result of arithmetic (unless it equals 1). For example, suppose we
multiply 2 m by 3 m to get 6 square meters, and suppose the benchmark
|M| is 1000 for both length and area. Then the 2 m and 3 m are stored
as 2000 and 3000. Simply multiplying those as integers gives 6000000,
but that corresponds to 6000 square meters, not 6. So the result of the
multiplication must be rescaled to give the right answer.

Since, as noted above, benchmark |M| is always 1 for real values, there's
no need for rescaling with real arithmetic.

@ Scalings are defined one at a time, and usually in terms of each other.
We can't know the values of |M| they end up with until all have been
defined.

@d LP_SCALED_UP    1
@d LP_SCALED_DOWN -1
@d LP_SCALED_AT    2

=
typedef struct scaling_transformation {
	int use_integer_scaling; /* or if not, use real */

	int int_O; /* the $O$ value described above, if integers used */
	int int_M; /* the $M$ value described above */

	double real_O; /* the $O$ value described above, if real numbers used */
	double real_M; /* the $M$ value described above */

	/* used only in the definition process */
	int scaling_mode; /* one of the |LP_SCALED_*| constants */
	int int_scalar; /* whichever of these is relevant according to the integer/real mode */
	double real_scalar;
} scaling_transformation;

@h Logging.

=
void Kinds::Scalings::describe(OUTPUT_STREAM, scaling_transformation sc) {
	WRITE("scaling: x units --> ");
	if (sc.use_integer_scaling)
		WRITE("%d x + %x stored at runtime (int)", sc.int_M, sc.int_O);
	else
		WRITE("%g x + %g stored at runtime (real)", sc.real_M, sc.real_O);
	switch (sc.scaling_mode) {
		case LP_SCALED_UP: WRITE(" (defined as benchmark * "); break;
		case LP_SCALED_DOWN: WRITE(" (defined as benchmark / "); break;
		case LP_SCALED_AT: WRITE(" (defined as scaled at "); break;
	}
	if (sc.use_integer_scaling) WRITE("%d)", sc.int_scalar);
	else WRITE("%g)", sc.real_scalar);
}

@h Definition.
A new scaling is given with a scale factor either pegging it absolutely, or
relative to the benchmark. At initial definition time, we don't calculate |M|:
we just take notes for later.

=
scaling_transformation Kinds::Scalings::new(int integer_valued,
	int scaled, int int_s, double real_s, int offset, double real_offset) {
	scaling_transformation sc;
	sc.use_integer_scaling = integer_valued;
	sc.int_O = 0; sc.real_O = 0.0;
	if (integer_valued) sc.int_O = offset; else sc.real_O = (double) real_offset;
	sc.int_M = 1; sc.real_M = 1.0;
	sc.scaling_mode = scaled;
	sc.int_scalar = int_s;
	sc.real_scalar = real_s;
	return sc;
}

@ Soon after definition, we may realise that real arithmetic is needed after
all, even though we previously expected it to use integers. So:

=
void Kinds::Scalings::convert_to_real(scaling_transformation *sc) {
	if (sc->use_integer_scaling) {
		sc->real_O = (double) sc->int_O; sc->int_O = 0;
		sc->real_M = (double) sc->int_M; sc->int_M = 1;
		sc->real_scalar = (double) sc->int_scalar; sc->int_scalar = 1;
		sc->use_integer_scaling = FALSE;
	}
}

@ Each new scaling in turn is added to the list of those in use for a given
kind. For example, when the "1 km" scaling is added to those for lengths,
perhaps "1 cm" and "1 m" (the benchmark) already exist, but "1 mm" doesn't.
We call the following routine to calculate a suitable |M| for the scaling.
It returns a value which is either |-1|, or else a scale factor by which
to increase the |M| values of everything else in the list.

=
int Kinds::Scalings::determine_M(scaling_transformation *sc,
	scaling_transformation *benchmark_sc,
	int first, int equiv, int alt) {
	int rescale_the_others_by_this = 1; /* in effect, don't */
	if (first) @<Determine M for the first scaling of the list@>
	else @<Determine M for a subsequent scaling of the list@>;
	return rescale_the_others_by_this;
}

@ This is the easy case -- there's no list yet, and no benchmark yet. The |M|
value will usually therefore be 1, unless the source text explicitly asked
for it to be something else:

>> 1m specifies a length scaled at 10000.

in which case, of course, |M| is 10000. Since there's no benchmark yet, it
must be a problem message if the unit is defined scaled up or down from the
benchmark; and similarly if the new notation is claimed to be equivalent to
some existing notation, in which case the |equiv| flag is set.

@<Determine M for the first scaling of the list@> =
	if (((sc->int_scalar != 1) || (sc->real_scalar != 1.0)) &&
		((sc->scaling_mode == LP_SCALED_UP) ||
		(sc->scaling_mode == LP_SCALED_DOWN) ||
		(equiv) ||
		((sc->scaling_mode == LP_SCALED_AT) && (sc->use_integer_scaling == FALSE))))
		KindsModule::problem_handler(LPCantScaleYet_KINDERROR, NULL, NULL, NULL, NULL);
	sc->int_M = sc->int_scalar;

@ The harder case, when some scalings already exist for this kind. Firstly,
you can't create an alternative set of scalings (e.g. Imperial units such
as feet and inches) with its own absolute scale factor, because the existing
scalings (metric units such as mm, km, etc.) already have their |M| value.

@<Determine M for a subsequent scaling of the list@> =
	if (((sc->int_scalar != 1) || (sc->real_scalar != 1.0)) &&
		((alt) && (sc->scaling_mode == LP_SCALED_AT)))
		KindsModule::problem_handler(LPCantScaleTwice_KINDERROR, NULL, NULL, NULL, NULL);

	if (equiv)
		@<Calculate the multiplier for this equivalent scaling@>
	else
		@<Calculate the multiplier for the LP relative to the benchmark@>;

@ An equivalent unit exactly specifies its |M|-value. For example:

>> 1 pencil specifies a length equivalent to 18cm.

What happens here is that "18cm" is parsed and turned not into 18, but into
the "1 cm" scaling applied to 18, and that's the value in our scalar,
which then becomes |M|.

@<Calculate the multiplier for this equivalent scaling@> =
	if (sc->use_integer_scaling)
		sc->int_M = sc->int_scalar;
	else
		sc->real_M = sc->real_scalar;

@ Finally the trickiest case. We calculate |M| based on scaling the benchmark
either up or down.

Scaling up by |k| is no problem: the |M| value is just |k| times the benchmark
|M|, which we call |B|.

Scaling down might look similar: we want |M = B/k|. But in integer arithmetic
|k| probably doesn't divide |B|, and extreme cases frequently occur: for
example, where |k| is 1000 and |B| is 1.

We get around this by increasing every |M|-value in the list by a factor of:
= (text)
	k / gcd(B, k)
=
Note that |B| also increases in this process, and in fact becomes
= (text)
	Bk / gcd(B, k)
=
which is the smallest multiple of |B| which has |k| as a factor. (If in fact
|k| always divided |B|, then the scale multiple is 1 and no change is made.)
That means that the new value of |B| divided by |k| will be
= (text)
	B / gcd(B, k)
=
so this is what we set |M| to.

@<Calculate the multiplier for the LP relative to the benchmark@> =
	if (benchmark_sc == NULL) internal_error("no benchmark for comparison");
	if (sc->scaling_mode == LP_SCALED_DOWN) {
		if (sc->use_integer_scaling) {
			int B = benchmark_sc->int_M;
			int k = sc->int_scalar;
			int g = Kinds::Dimensions::gcd(B, k);
			sc->int_M = B/g;
			rescale_the_others_by_this = k/g;
		} else {
			double B = benchmark_sc->real_M;
			double k = sc->real_scalar;
			sc->real_M = B/k;
		}
	} else if (sc->scaling_mode == LP_SCALED_UP) {
		if (sc->use_integer_scaling) {
			int B = benchmark_sc->int_M;
			int k = sc->int_scalar;
			sc->int_M = B*k;
		} else {
			double B = benchmark_sc->real_M;
			double k = sc->real_scalar;
			sc->real_M = B*k;
		}
	}

@h Enlarging and contracting.
Note that the offset values |O| are not affected here. The idea is this:
suppose we have a unit such as temperature, and have defined centigrade as
a scaling with offset 273. Then suppose we want a unit equal to 0.1 of a
degree centigrade: we want to scale down C by 10, but preserve offset 273,
so that the value "1 deciC" (or whatever) is 273.1 degrees, not 27.4.
(In practice, and wisely, scientists never scale units with offsets, so
this seldom arises.)

=
scaling_transformation Kinds::Scalings::enlarge(scaling_transformation sc, int F) {
	if (sc.use_integer_scaling) {
		sc.int_M *= F;
	} else {
		sc.real_M *= F;
	}
	return sc;
}

scaling_transformation Kinds::Scalings::contract(scaling_transformation sc, int F,
	int *loses_accuracy) {
	*loses_accuracy = FALSE;
	if (sc.use_integer_scaling) {
		if (sc.int_M % F != 0) *loses_accuracy = TRUE;
		sc.int_M /= F;
	} else {
		sc.real_M /= F;
	}
	return sc;
}

@h Using scalings.
First, here's a |strcmp|-like routine to report which scaling is smaller
out of two; it's used for sorting scalings into ascending order of magnitude.

=
int Kinds::Scalings::compare(scaling_transformation A, scaling_transformation B) {
	if (A.use_integer_scaling != B.use_integer_scaling)
		internal_error("scalings incomparable");
	if (A.use_integer_scaling) {
		if (A.int_M > B.int_M) return 1;
		if (A.int_M < B.int_M) return -1;
		if (A.int_O > B.int_O) return 1;
		if (A.int_O < B.int_O) return -1;
	} else {
		if (A.real_M > B.real_M) return 1;
		if (A.real_M < B.real_M) return -1;
		if (A.real_O > B.real_O) return 1;
		if (A.real_O < B.real_O) return -1;
	}
	return 0;
}

@ Second, the following returns |M| unless we're in real mode, in which case it
returns 1.

=
int Kinds::Scalings::get_integer_multiplier(scaling_transformation sc) {
	return sc.int_M;
}

@ Finally, this simply detects the presence of a scale factor, real or integer:

=
int Kinds::Scalings::involves_scale_change(scaling_transformation sc) {
	if (sc.int_M != 1) return TRUE;
	if (sc.real_M != 1.0) return TRUE;
	return FALSE;
}

@h Scaled arithmetic at compile-time.
The "quantum" of a scaling is the run-time value corresponding to 1 unit:
for example, for kilometers, it's the run-time value which "1 km" translates
into.

=
int Kinds::Scalings::quantum(scaling_transformation sc) {
	return (int) Kinds::Scalings::quanta_to_value(sc, 1);
}

double Kinds::Scalings::real_quantum(scaling_transformation sc) {
	return Kinds::Scalings::real_quanta_to_value(sc, 1.0);
}

@ More generally, the following takes a number of quanta and turns it into
the run-time value that stores as:

=
int Kinds::Scalings::quanta_to_value(scaling_transformation sc, int q) {
	return q*sc.int_M + sc.int_O;
}

double Kinds::Scalings::real_quanta_to_value(scaling_transformation sc, double q) {
	return q*sc.real_M + sc.real_O;
}

@ In integer arithmetic, the inverse of this function won't generally
exist, since division can't be performed exactly. The following is the
best we can do.

So consider the run-time value |v|, and let's try to express it as a
whole number of quanta plus a fractional remainder. For example, if the
scaling is for "1 m", with offset 0 and multiplier 1000, then the value
|v = 2643| produces 2 quanta and remainder 643/1000ths.

In real arithmetic, on the other hand, the inverse straightforwardly exists.

=
void Kinds::Scalings::value_to_quanta(int v, scaling_transformation sc, int *q, int *r) {
	if (sc.use_integer_scaling == FALSE) internal_error("inversion unimplemented");
	if (r) *r = (v - sc.int_O) % (sc.int_M);
	if (q) *q = (v - sc.int_O) / (sc.int_M);
}

double Kinds::Scalings::real_value_to_quanta(double v, scaling_transformation sc) {
	return (v - sc.real_O) / (sc.real_M);
}

@h Scaled arithmetic at run-time.
We begin with routines to compile code which, at run-time, performs these
same operations: quanta to value, value to quanta and remainder. The
value is held in the I6 variable named |V_var|.

=
#ifdef CORE_MODULE
void Kinds::Scalings::compile_quanta_to_value(scaling_transformation sc,
	inter_name *V_var, inter_symbol *sgn_var, inter_symbol *x_var, inter_symbol *label) {
	if (sc.use_integer_scaling) {
		Kinds::Scalings::compile_scale_and_add(
			InterNames::to_symbol(V_var), sgn_var, sc.int_M, sc.int_O, x_var, label);
	} else {
		if (sc.real_M != 1.0) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_iname(Emit::tree(), K_value, V_var);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_TIMES_HL));
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, V_var);
					Produce::val_real(Emit::tree(), sc.real_M);
				Emit::up();
			Emit::up();
		}
		if (sc.real_O != 0.0) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_iname(Emit::tree(), K_value, V_var);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_PLUS_HL));
				Emit::down();
					Produce::val_iname(Emit::tree(), K_value, V_var);
					Produce::val_real(Emit::tree(), sc.real_O);
				Emit::up();
			Emit::up();
		}
		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_NAN_HL));
			Emit::down();
				Produce::val_iname(Emit::tree(), K_value, V_var);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				Produce::inv_primitive(Emit::tree(), JUMP_BIP);
				Emit::down();
					Produce::lab(Emit::tree(), label);
				Emit::up();
			Emit::up();
		Emit::up();
	}
}
#endif

@ The integer case of this is extracted as a utility routine because it's useful
for other calculations too. This performs the operation
= (text)
	v --> kv + l
=
carefully checking that the result does not overflow the virtual machine's
signed integer size limit in the process. |k| is a constant known at compile
time, but |l| is an arbitrary I6 expression whose value can't be known until
run-time. If an overflow occurs, we jump to the given label.

If, at run-time, the variable |sgn| is negative, then we are performing this
on the absolute value of what will be a negative number; since we're using
twos-complement arithmetic, this increases the maxima by 1. Thus 32768 or
2147483648 will overflow in the positive domain, but not the negative.

=
#ifdef CORE_MODULE
void Kinds::Scalings::compile_scale_and_add(inter_symbol *var, inter_symbol *sgn_var,
	int scale_factor, int to_add, inter_symbol *var_to_add, inter_symbol *label) {
	if (scale_factor > 1) {
		long long int max = 2147483647LL;
		if (TargetVMs::is_16_bit(Task::vm())) max = 32767LL;
		Produce::inv_primitive(Emit::tree(), IFELSE_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, sgn_var);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 1);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				@<Compile the overflow check@>;
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				max++;
				@<Compile the overflow check@>;
			Emit::up();
		Emit::up();
	}
	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, var);
		Produce::inv_primitive(Emit::tree(), PLUS_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), TIMES_BIP);
			Emit::down();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) scale_factor);
				Produce::val_symbol(Emit::tree(), K_value, var);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), PLUS_BIP);
			Emit::down();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) to_add);
				Produce::val_symbol(Emit::tree(), K_value, var_to_add);
			Emit::up();
		Emit::up();
	Emit::up();
}
#endif

@<Compile the overflow check@> =
	Produce::inv_primitive(Emit::tree(), IF_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), OR_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), GT_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, var);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (max/scale_factor));
			Emit::up();
			Produce::inv_primitive(Emit::tree(), AND_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), EQ_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, var);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (max/scale_factor));
				Emit::up();
				Produce::inv_primitive(Emit::tree(), GT_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), PLUS_BIP);
					Emit::down();
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) to_add);
						Produce::val_symbol(Emit::tree(), K_value, var_to_add);
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (max/scale_factor));
				Emit::up();
			Emit::up();
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), JUMP_BIP);
			Emit::down();
				Produce::lab(Emit::tree(), label);
			Emit::up();
		Emit::up();
	Emit::up();

@ And conversely... Note that in the real case, the remainder variable |R_var|
is ignored, since the division can be performed "exactly".

=
#ifdef CORE_MODULE
void Kinds::Scalings::compile_value_to_quanta(scaling_transformation sc,
	inter_symbol *V_var, inter_symbol *R_var) {
	if (sc.use_integer_scaling) {
		if (sc.int_O != 0) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, V_var);
				Produce::inv_primitive(Emit::tree(), MINUS_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, V_var);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc.int_O);
				Emit::up();
			Emit::up();
		}
		if (sc.int_M != 1) {
			if (R_var) {
				Produce::inv_primitive(Emit::tree(), STORE_BIP);
				Emit::down();
					Produce::ref_symbol(Emit::tree(), K_value, R_var);
					Produce::inv_primitive(Emit::tree(), MODULO_BIP);
					Emit::down();
						Produce::val_symbol(Emit::tree(), K_value, V_var);
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc.int_M);
					Emit::up();
				Emit::up();
			}
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, V_var);
				Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, V_var);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) sc.int_M);
				Emit::up();
			Emit::up();
		}
	} else {
		if (sc.int_M != 0.0) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, V_var);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_MINUS_HL));
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, V_var);
					Produce::val_real(Emit::tree(), sc.real_O);
				Emit::up();
			Emit::up();
		}
		if (sc.real_M != 1.0) {
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, V_var);
				Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_DIVIDE_HL));
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, V_var);
					Produce::val_real(Emit::tree(), sc.real_M);
				Emit::up();
			Emit::up();
		}
	}
}
#endif

@ The following compiles a valid condition to test whether the value in the
named I6 variable is equal to, greater than, less than or equal to, etc., the
quantum for the scaling. |op| contains the textual form of the comparison
operator to use: say, |">="|.

=
#ifdef CORE_MODULE
void Kinds::Scalings::compile_threshold_test(scaling_transformation sc,
	inter_symbol *V_var, inter_ti op) {
	Produce::inv_primitive(Emit::tree(), op);
	Emit::down();
	if (sc.use_integer_scaling) {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(NUMBER_TY_ABS_HL));
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, V_var);
		Emit::up();
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) Kinds::Scalings::quantum(sc));
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_COMPARE_HL));
		Emit::down();
			Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_ABS_HL));
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, V_var);
			Emit::up();
			Produce::val_real(Emit::tree(), Kinds::Scalings::real_quantum(sc));
		Emit::up();
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
	}
	Emit::up();
}
#endif

@ We now compile code to print the value in the variable |V_var| with
respect to this scaling. We need two other variables at our disposal to
do this: |R_var|, which is temporary storage to hold the remainder part;
and |S_var|, which is a scratch variable used as a form of loop counter.

=
#ifdef CORE_MODULE
void Kinds::Scalings::compile_print_in_quanta(scaling_transformation sc,
	inter_symbol *V_var, inter_symbol *R_var, inter_symbol *S_var) {

	Kinds::Scalings::compile_value_to_quanta(sc, V_var, R_var);

	if (sc.use_integer_scaling) {
		Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, V_var);
		Emit::up();

		Produce::inv_primitive(Emit::tree(), IF_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), GT_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, R_var);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
			Produce::code(Emit::tree());
			Emit::down();
				@<Print a decimal expansion for the remainder@>;
			Emit::up();
		Emit::up();
	} else {
		Produce::inv_call_iname(Emit::tree(), Hierarchy::find(REAL_NUMBER_TY_SAY_HL));
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, V_var);
		Emit::up();
	}
}
#endif

@ In the integer case, then, suppose we have determined that our value is
2 quanta with remainder 26/Mths. We've already printed the 2, and it remains
to print the best decimal expansion we can to represent 26/Mths.

This splits into two cases. If |M| divides some power of 10 then the fraction
|26/M| can be written as a positive integer divided by a power of 10, and
that means the decimal expansion can be printed exactly: there are no
recurring decimals. If it can't, then we must approximate.

@<Print a decimal expansion for the remainder@> =
	Produce::inv_primitive(Emit::tree(), PRINT_BIP);
	Emit::down();
		Produce::val_text(Emit::tree(), I".");
	Emit::up();

	int M = sc.int_M;
	int cl10M = 1; while (M > cl10M) cl10M = cl10M*10;

	TEMPORARY_TEXT(C)
	WRITE_TO(C, "M = %d, ceiling(log_10(M)) = %d", M, cl10M);
	Emit::code_comment(C);
	DISCARD_TEXT(C)

	if (cl10M % M == 0)
		@<Use an exact method, since the multiplier divides a power of 10@>
	else
		@<Use an approximate method, since we can't have an exact one in all cases@>;

@ In this exact case,
= (text)
	M = cl10M / t
=
for some natural number |t|, which means our example |26/M| is equal to
= (text)
	26t/Mt = 26t / cl10M
=
Once we've done that, we simply work out how many initial 0s there should
be; print that many zeroes; and then print |26t| as if it's an integer.

@<Use an exact method, since the multiplier divides a power of 10@> =
	int t = cl10M/M;
	if (t != 1) {
		Produce::inv_primitive(Emit::tree(), STORE_BIP);
		Emit::down();
			Produce::ref_symbol(Emit::tree(), K_value, R_var);
			Produce::inv_primitive(Emit::tree(), TIMES_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, R_var);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) t);
			Emit::up();
		Emit::up();
	}

	Produce::inv_primitive(Emit::tree(), STORE_BIP);
	Emit::down();
		Produce::ref_symbol(Emit::tree(), K_value, S_var);
		Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) cl10M);
	Emit::up();

	Produce::inv_primitive(Emit::tree(), WHILE_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), AND_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), EQ_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), MODULO_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, R_var);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
			Produce::inv_primitive(Emit::tree(), GT_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, R_var);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 0);
			Emit::up();
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, R_var);
				Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, R_var);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
				Emit::up();
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, S_var);
				Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, S_var);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), WHILE_BIP);
	Emit::down();
		Produce::inv_primitive(Emit::tree(), LT_BIP);
		Emit::down();
			Produce::val_symbol(Emit::tree(), K_value, R_var);
			Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
			Emit::down();
				Produce::val_symbol(Emit::tree(), K_value, S_var);
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
			Emit::up();
		Emit::up();
		Produce::code(Emit::tree());
		Emit::down();
			Produce::inv_primitive(Emit::tree(), PRINT_BIP);
			Emit::down();
				Produce::val_text(Emit::tree(), I"0");
			Emit::up();
			Produce::inv_primitive(Emit::tree(), STORE_BIP);
			Emit::down();
				Produce::ref_symbol(Emit::tree(), K_value, S_var);
				Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
				Emit::down();
					Produce::val_symbol(Emit::tree(), K_value, S_var);
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
				Emit::up();
			Emit::up();
		Emit::up();
	Emit::up();

	Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
	Emit::down();
		Produce::val_symbol(Emit::tree(), K_value, R_var);
	Emit::up();

@ In this approximation, |R_var| is measured in units of |1/M|. Thus the first
digit after the decimal point should be |R_var| times |10/M|, the second
|R_var| times |100/M|, and so on.

@<Use an approximate method, since we can't have an exact one in all cases@> =
	int R = 1;
	while (R<=M) {
		R = R*10;
		int g = Kinds::Dimensions::gcd(R, M);
		Produce::inv_primitive(Emit::tree(), PRINTNUMBER_BIP);
		Emit::down();
			Produce::inv_primitive(Emit::tree(), MODULO_BIP);
			Emit::down();
				Produce::inv_primitive(Emit::tree(), PLUS_BIP);
				Emit::down();
					Produce::inv_primitive(Emit::tree(), MODULO_BIP);
					Emit::down();
						Produce::inv_primitive(Emit::tree(), DIVIDE_BIP);
						Emit::down();
							Produce::inv_primitive(Emit::tree(), TIMES_BIP);
							Emit::down();
								Produce::val_symbol(Emit::tree(), K_value, R_var);
								Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (R/g));
							Emit::up();
							Produce::val(Emit::tree(), K_number, LITERAL_IVAL, (inter_ti) (M/g));
						Emit::up();
						Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
					Emit::up();
					Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
				Emit::up();
				Produce::val(Emit::tree(), K_number, LITERAL_IVAL, 10);
			Emit::up();
		Emit::up();
	}
