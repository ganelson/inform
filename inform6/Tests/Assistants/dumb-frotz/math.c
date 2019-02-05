/*
 * math.c
 *
 * Arithmetic, compare and logical opcodes
 *
 */

#include "frotz.h"

/*
 * z_add, 16bit addition.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_add (void)
{

    store ((zword) ((short) zargs[0] + (short) zargs[1]));

}/* z_add */

/*
 * z_and, bitwise AND operation.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_and (void)
{

    store ((zword) (zargs[0] & zargs[1]));

}/* z_and */

/*
 * z_art_shift, arithmetic SHIFT operation.
 *
 *	zargs[0] = value
 *	zargs[1] = #positions to shift left (positive) or right
 *
 */

void z_art_shift (void)
{

    if ((short) zargs[1] > 0)
	store ((zword) ((short) zargs[0] << (short) zargs[1]));
    else
	store ((zword) ((short) zargs[0] >> - (short) zargs[1]));

}/* z_art_shift */

/*
 * z_div, signed 16bit division.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_div (void)
{

    if (zargs[1] == 0)
	runtime_error ("Division by zero");

    store ((zword) ((short) zargs[0] / (short) zargs[1]));

}/* z_div */

/*
 * z_je, branch if the first value equals any of the following.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value (optional)
 *	...
 *	zargs[3] = fourth value (optional)
 *
 */

void z_je (void)
{

    branch (
	zargc > 1 && (zargs[0] == zargs[1] || (
	zargc > 2 && (zargs[0] == zargs[2] || (
	zargc > 3 && (zargs[0] == zargs[3]))))));

}/* z_je */

/*
 * z_jg, branch if the first value is greater than the second.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_jg (void)
{

    branch ((short) zargs[0] > (short) zargs[1]);

}/* z_jg */

/*
 * z_jl, branch if the first value is less than the second.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_jl (void)
{

    branch ((short) zargs[0] < (short) zargs[1]);

}/* z_jl */

/*
 * z_jz, branch if value is zero.
 *
 * 	zargs[0] = value
 *
 */

void z_jz (void)
{

    branch ((short) zargs[0] == 0);

}/* z_jz */

/*
 * z_log_shift, logical SHIFT operation.
 *
 * 	zargs[0] = value
 *	zargs[1] = #positions to shift left (positive) or right (negative)
 *
 */

void z_log_shift (void)
{

    if ((short) zargs[1] > 0)
	store ((zword) (zargs[0] << (short) zargs[1]));
    else
	store ((zword) (zargs[0] >> - (short) zargs[1]));

}/* z_log_shift */

/*
 * z_mod, remainder after signed 16bit division.
 *
 * 	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_mod (void)
{

    if (zargs[1] == 0)
	runtime_error ("Division by zero");

    store ((zword) ((short) zargs[0] % (short) zargs[1]));

}/* z_mod */

/*
 * z_mul, 16bit multiplication.
 *
 * 	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_mul (void)
{

    store ((zword) ((short) zargs[0] * (short) zargs[1]));

}/* z_mul */

/*
 * z_not, bitwise NOT operation.
 *
 * 	zargs[0] = value
 *
 */

void z_not (void)
{

    store ((zword) ~zargs[0]);

}/* z_not */

/*
 * z_or, bitwise OR operation.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_or (void)
{

    store ((zword) (zargs[0] | zargs[1]));

}/* z_or */

/*
 * z_sub, 16bit substraction.
 *
 *	zargs[0] = first value
 *	zargs[1] = second value
 *
 */

void z_sub (void)
{

    store ((zword) ((short) zargs[0] - (short) zargs[1]));

}/* z_sub */

/*
 * z_test, branch if all the flags of a bit mask are set in a value.
 *
 *	zargs[0] = value to be examined
 *	zargs[1] = bit mask
 *
 */

void z_test (void)
{

    branch ((zargs[0] & zargs[1]) == zargs[1]);

}/* z_test */
