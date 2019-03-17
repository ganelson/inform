/* float.c: Glulxe code for floating-point operations
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "glulxe.h"

#ifdef FLOAT_SUPPORT

#include <math.h>

/* This entire file is compiled out if the FLOAT_SUPPORT option is off.
   (Because we probably can't define a gfloat32 in that case.) */

#ifndef FLOAT_NOT_NATIVE

int init_float() 
{
    /* Check and make sure the native float format is really
       IEEE-754 single-precision. */

    if (sizeof(gfloat32) != 4) {
        fatal_error("gfloat32 is not 32 bits.");
        return FALSE;
    }
    if (encode_float((gfloat32)(-1)) != 0xBF800000) {
        fatal_error("The gfloat32 format of -1 did not match.");
        return FALSE;
    }
    return TRUE;
}

/* Encode and decode floats by reinterpret-casting. */

glui32 encode_float(gfloat32 val)
{
    glui32 res;
    *(gfloat32 *)(&res) = val;
    return res;
}

gfloat32 decode_float(glui32 val)
{
    gfloat32 res;
    *(glui32 *)(&res) = val;
    return res;
}

#else /* FLOAT_NOT_NATIVE */

int init_float() 
{
    return TRUE;
}

/* Encode and decode floats by a lot of annoying bit manipulation. 
   The following functions are adapted from code in Python 
   (Objects/floatobject.c). */

glui32 encode_float(gfloat32 val)
{
    gfloat32 absval;
    glui32 sign;
    int expo;
    gfloat32 mant;
    glui32 fbits;
 
    if (signbit(val)) {
        sign = 0x80000000;
        absval = -val;
    }
    else {
        sign = 0x0;
        absval = val;
    }

    if (isinf(val)) {
        return sign | 0x7f800000; /* infinity */
    }

    if (isnan(val)) {
        return sign | 0x7fc00000;
    }

    mant = frexpf(absval, &expo);

    /* Normalize mantissa to be in the range [1.0, 2.0) */
    if (0.5 <= mant && mant < 1.0) {
        mant *= 2.0;
        expo--;
    }
    else if (mant == 0.0) {
        expo = 0;
    }
    else {
        return sign | 0x7f800000; /* infinity */
    }

    if (expo >= 128) {
        return sign | 0x7f800000; /* infinity */
    }
    else if (expo < -126) {
        /* Denormalized (very small) number */
        mant = ldexpf(mant, 126 + expo);
        expo = 0;
    }
    else if (!(expo == 0 && mant == 0.0)) {
        expo += 127;
        mant -= 1.0; /* Get rid of leading 1 */
    }

    mant *= 8388608.0; /* 2^23 */
    fbits = (glui32)(mant + 0.5); /* round mant to nearest int */
    if (fbits >> 23) {
        /* The carry propagated out of a string of 23 1 bits. */
        fbits = 0;
        expo++;
        if (expo >= 255) {
            return sign | 0x7f800000; /* infinity */
        }
    }

    return (sign) | ((glui32)(expo << 23)) | (fbits);
}

gfloat32 decode_float(glui32 val)
{
    int sign;
    int expo;
    glui32 mant;
    gfloat32 res;

    /* First byte */
    sign = ((val & 0x80000000) != 0);
    expo = (val >> 23) & 0xFF;
    mant = val & 0x7FFFFF;

    if (expo == 255) {
        if (mant == 0) {
            /* Infinity */
            return (sign ? (-INFINITY) : (INFINITY));
        }
        else {
            /* Not a number */
            return (sign ? (-NAN) : (NAN));
        }
    }

    res = (gfloat32)mant / 8388608.0;

    if (expo == 0) {
        expo = -126;
    }
    else {
        res += 1.0;
        expo -= 127;
    }
    res = ldexpf(res, expo);

    return (sign ? (-res) : (res));
}

#endif /* FLOAT_NOT_NATIVE */

#endif /* FLOAT_SUPPORT */
