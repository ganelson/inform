[Holsters::] Value Holsters.

Representing compilation contexts, and holding compiled values.

@ Value holsters were created as a shim at a time when almost the entire Inform
code-base had to be turned around. Pre-2017, Inform generated code by writing
Inform 6 syntax out by hand: but post-2019, Inter bytecode was generated instead.
Hundreds of subsystems had to be rewritten, a process taking over a year, and
during this time the compiler had to work in a piebald sort of way -- some
systems generating bytecode, others still pouring our raw I6 as text.

The //value_holster// was invented as a way to manage this. It allows the caller
of a compilation function to ask for code to be made in a particular way: this
is the |vhmode_wanted| field. These ways are:

(*) |INTER_VAL_VHMODE| -- generate Inter bytecode inside a function, producing a value

(*) |INTER_VOID_VHMODE| -- generate Inter bytecode inside a function but in
void context, i.e., not producing a value

(*) |INTER_DATA_VHMODE| -- encode a constant value as a pair of Inter values,
for use in, say, an array entry.

So much for what the caller wants. The compilation function, or subsystem, then
does whatever it does, and sets |vhmode_provided| to the mode it actually compiled
in; the caller can then deal with the situation arising if it wasn't what was
wanted. During 2017 this often meant that the function would write out some
raw I6 syntax, and reply |INTER_TEXT_VHMODE| to signal this; the caller would
then turn this into Inter by wrapping it up as either a "splat" or a "glob".

With the transition now complete, |INTER_TEXT_VHMODE| no longer exists. But
value holsters continue to be a useful device.

@e INTER_DATA_VHMODE from 1
@e INTER_VAL_VHMODE
@e INTER_VOID_VHMODE
@e NO_VHMODE

=
typedef struct value_holster {
	int vhmode_wanted;
	int vhmode_provided;
	inter_ti val1, val2;
} value_holster;

@ =
value_holster Holsters::new(int vhm) {
	value_holster vh;
	vh.val1 = 0; vh.val2 = 0;
	vh.vhmode_wanted = vhm;
	vh.vhmode_provided = NO_VHMODE; /* the compilation function has not yet set this */
	if (vhm == NO_VHMODE) internal_error("can't want NO_VHMODE");
	return vh;
}

@ A compilation function can produce, as its output, a value pair |val1|, |val2|
in either |INTER_DATA_VHMODE| (where this is exactly what is wanted) or in
|INTER_VAL_VHMODE| (where it can easily be adapted).

=
int Holsters::value_pair_allowed(value_holster *vh) {
	if (vh == NULL) internal_error("no VH");
	if ((vh->vhmode_wanted == INTER_DATA_VHMODE) ||
		(vh->vhmode_wanted == INTER_VAL_VHMODE)) return TRUE;
	return FALSE;
}

@ This is how a compilation function "holsters" a value pair:

=
void Holsters::holster_pair(value_holster *vh, inter_ti v1, inter_ti v2) {
	if (vh == NULL) internal_error("no VH");
	vh->val1 = v1; vh->val2 = v2;
	vh->vhmode_provided = INTER_DATA_VHMODE;
}

@ And this is how the caller "unholsters" that pair, after the function has
returned. If we find |NO_VHMODE|, we convert that to |INTER_DATA_VHMODE| with
the literal number value 0 as the pair.

On exit, the provided mode is always |INTER_DATA_VHMODE|.

A second or subsequent call on the same holster does nothing, except to return
the same value pair, which is still stored in it. (In that sense, these aren't
really like a gunslinger's holster, where a revolver once drawn is no longer
in the holster.)

=
void Holsters::unholster_to_pair(value_holster *vh, inter_ti *v1, inter_ti *v2) {
	if (vh == NULL) internal_error("no VH");
	switch (vh->vhmode_provided) {
		case INTER_DATA_VHMODE:
			*v1 = vh->val1; *v2 = vh->val2;
			break;
		case INTER_VAL_VHMODE:
			internal_error("impossible to unholster pair for compiled val code");
			break;
		case INTER_VOID_VHMODE:
			internal_error("impossible to unholster pair for compiled void code");
			break;
		case NO_VHMODE:
			vh->vhmode_provided = INTER_DATA_VHMODE;
			vh->val1 = LITERAL_IVAL; vh->val2 = 0;
			*v1 = vh->val1; *v2 = vh->val2;
			break;
	}
}

@ If, on the other hand, the caller was asking for |INTER_VAL_VHMODE|, it
should make use of the following. If we find |NO_VHMODE|, we compile a |val|
producing the literal value 0; if we find |INTER_DATA_VHMODE|, we compile a
|val| producing whatever value was holstered.

On exit, the provided mode is always |INTER_VAL_VHMODE|.

A second or subsequent call on the same holster does nothing.

=
void Holsters::unholster_to_code_val(inter_tree *I, value_holster *vh) {
	if (vh == NULL) internal_error("no VH");
	switch (vh->vhmode_provided) {
		case INTER_DATA_VHMODE:
		case NO_VHMODE: {
			inter_ti v1 = LITERAL_IVAL, v2 = 0;
			Holsters::unholster_to_pair(vh, &v1, &v2);
			Produce::val(I, K_value, v1, v2);
			vh->vhmode_provided = INTER_VAL_VHMODE;
			break;
		}
		case INTER_VAL_VHMODE:
			break;
		case INTER_VOID_VHMODE:
			internal_error("impossible to use void Inter code in val context");
			break;
	}
}
