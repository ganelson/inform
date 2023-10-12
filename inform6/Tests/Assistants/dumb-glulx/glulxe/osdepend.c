/* osdepend.c: Glulxe platform-dependent code.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "glulxe.h"

/* This file contains definitions for platform-dependent code. Since
   Glk takes care of I/O, this is a short list -- memory allocation
   and random numbers.

   The Makefile (or whatever) should define OS_UNIX, or some other
   symbol. Code contributions welcome. 
*/


/* We have a slightly baroque random-number scheme. If the Glulx
   @setrandom opcode is given seed 0, we use "true" randomness, from a
   platform native RNG if possible. If @setrandom is given a nonzero
   seed, we use a simple xoshiro128** RNG (provided below). The
   use of a known algorithm aids cross-platform testing and debugging.
   (Those being the cases where you'd set a nonzero seed.)

   To define a native RNG, define the macros RAND_SET_SEED() (seed the
   RNG with the clock or some other truly random source) and RAND_GET()
   (grab a number). Note that RAND_SET_SEED() does not take an argument;
   it is only called when seed=0. If RAND_GET() calls a non-seeded RNG
   API (such as arc4random()), then RAND_SET_SEED() should be a no-op.

   If RAND_SET_SEED/RAND_GET are not provided, we call back to the same
   xoshiro128** RNG as before, but seeded from the system clock.
*/

static glui32 xo_random(void);
static void xo_seed_random(glui32 seed);
static void xo_seed_random_4(glui32 seed0, glui32 seed1, glui32 seed2, glui32 seed3);

#ifdef OS_STDC

#include <time.h>
#include <stdlib.h>

/* Allocate a chunk of memory. */
void *glulx_malloc(glui32 len)
{
  return malloc(len);
}

/* Resize a chunk of memory. This must follow ANSI rules: if the
   size-change fails, this must return NULL, but the original chunk
   must remain unchanged. */
void *glulx_realloc(void *ptr, glui32 len)
{
  return realloc(ptr, len);
}

/* Deallocate a chunk of memory. */
void glulx_free(void *ptr)
{
  free(ptr);
}

/* Use our xoshiro128** as the native RNG, seeded from the clock. */
#define RAND_SET_SEED() (xo_seed_random(time(NULL)))
#define RAND_GET() (xo_random())

#endif /* OS_STDC */

#ifdef OS_UNIX

#include <time.h>
#include <stdlib.h>

/* Allocate a chunk of memory. */
void *glulx_malloc(glui32 len)
{
  return malloc(len);
}

/* Resize a chunk of memory. This must follow ANSI rules: if the
   size-change fails, this must return NULL, but the original chunk
   must remain unchanged. */
void *glulx_realloc(void *ptr, glui32 len)
{
  return realloc(ptr, len);
}

/* Deallocate a chunk of memory. */
void glulx_free(void *ptr)
{
  free(ptr);
}

#ifdef UNIX_RAND_ARC4

/* Use arc4random() as the native RNG. It doesn't need to be seeded. */
#define RAND_SET_SEED() (0)
#define RAND_GET() (arc4random())

#elif UNIX_RAND_GETRANDOM

/* Use xoshiro128** as the native RNG, seeded from getrandom(). */
#include <sys/random.h>

static void rand_set_seed(void)
{
    glui32 seeds[4];
    int res = getrandom(seeds, 4*sizeof(glui32), 0);
    if (res < 0) {
        /* Error; fall back to the clock. */
        xo_seed_random(time(NULL));
    }
    else {
        xo_seed_random_4(seeds[0], seeds[1], seeds[2], seeds[3]);
    }
}

#define RAND_SET_SEED() (rand_set_seed())
#define RAND_GET() (xo_random())

#else /* UNIX_RAND_... */

/* Use our xoshiro128** as the native RNG, seeded from the clock. */
#define RAND_SET_SEED() (xo_seed_random(time(NULL)))
#define RAND_GET() (xo_random())

#endif /* UNIX_RAND_... */

#endif /* OS_UNIX */

#ifdef OS_MAC

#include <stdlib.h>

/* Allocate a chunk of memory. */
void *glulx_malloc(glui32 len)
{
  return malloc(len);
}

/* Resize a chunk of memory. This must follow ANSI rules: if the
   size-change fails, this must return NULL, but the original chunk
   must remain unchanged. */
void *glulx_realloc(void *ptr, glui32 len)
{
  return realloc(ptr, len);
}

/* Deallocate a chunk of memory. */
void glulx_free(void *ptr)
{
  free(ptr);
}

/* Use arc4random() as the native RNG. It doesn't need to be seeded. */
#define RAND_SET_SEED() (0)
#define RAND_GET() (arc4random())

#endif /* OS_MAC */

#ifdef OS_WINDOWS

#ifdef _MSC_VER /* For Visual C++, get rand_s() */
#define _CRT_RAND_S
#endif

#include <time.h>
#include <stdlib.h>

/* Allocate a chunk of memory. */
void *glulx_malloc(glui32 len)
{
  return malloc(len);
}

/* Resize a chunk of memory. This must follow ANSI rules: if the
   size-change fails, this must return NULL, but the original chunk
   must remain unchanged. */
void *glulx_realloc(void *ptr, glui32 len)
{
  return realloc(ptr, len);
}

/* Deallocate a chunk of memory. */
void glulx_free(void *ptr)
{
  free(ptr);
}

#ifdef _MSC_VER /* Visual C++ */

/* Do nothing, as rand_s() has no seed. */
static void msc_srandom()
{
}

/* Use the Visual C++ function rand_s() as the native RNG.
   This calls the OS function RtlGetRandom(). */
static glui32 msc_random()
{
  glui32 value;
  rand_s(&value);
  return value;
}

#define RAND_SET_SEED() (msc_srandom())
#define RAND_GET() (msc_random())

#else /* Other Windows compilers */

/* Use our xoshiro128** as the native RNG, seeded from the clock. */
#define RAND_SET_SEED() (xo_seed_random(time(NULL)))
#define RAND_GET() (xo_random())

#endif

#endif /* OS_WINDOWS */


/* If no native RNG is defined above, use the xoshiro128** implementation. */
#ifndef RAND_SET_SEED
#define RAND_SET_SEED() (xo_seed_random(time(NULL)))
#define RAND_GET() (xo_random())
#endif /* RAND_SET_SEED */

static int rand_use_native = TRUE;

/* Set the random-number seed, and also select which RNG to use.
*/
void glulx_setrandom(glui32 seed)
{
    if (seed == 0) {
        rand_use_native = TRUE;
        RAND_SET_SEED();
    }
    else {
        rand_use_native = FALSE;
        xo_seed_random(seed);
    }
}

/* Return a random number in the range 0 to 2^32-1. */
glui32 glulx_random()
{
    if (rand_use_native) {
        return RAND_GET();
    }
    else {
        return xo_random();
    }
}


/* This is the "xoshiro128**" random-number generator and seed function.
   Adapted from: https://prng.di.unimi.it/xoshiro128starstar.c
   About this algorithm: https://prng.di.unimi.it/
*/
static uint32_t xo_table[4];

static void xo_seed_random_4(glui32 seed0, glui32 seed1, glui32 seed2, glui32 seed3)
{
    /* Set up the 128-bit state from four integers. Use this if you can get
       four high-quality random values. */
    xo_table[0] = seed0;
    xo_table[1] = seed1;
    xo_table[2] = seed2;
    xo_table[3] = seed3;
}

static void xo_seed_random(glui32 seed)
{
    int ix;
    /* Set up the 128-bit state from a single 32-bit integer. We rely
       on a different RNG, SplitMix32. This isn't high-quality, but we
       just need to get a bunch of bits into xo_table. */
    for (ix=0; ix<4; ix++) {
        seed += 0x9E3779B9;
        glui32 s = seed;
        s ^= s >> 15;
        s *= 0x85EBCA6B;
        s ^= s >> 13;
        s *= 0xC2B2AE35;
        s ^= s >> 16;
        xo_table[ix] = s;
    }
}

static glui32 xo_random(void)
{
    /* I've inlined the utility function:
       rotl(x, k) => (x << k) | (x >> (32 - k))
     */
    
    const uint32_t t1x5 = xo_table[1] * 5;
    const uint32_t result = ((t1x5 << 7) | (t1x5 >> (32-7))) * 9;

    const uint32_t t1s9 = xo_table[1] << 9;

    xo_table[2] ^= xo_table[0];
    xo_table[3] ^= xo_table[1];
    xo_table[1] ^= xo_table[2];
    xo_table[0] ^= xo_table[3];

    xo_table[2] ^= t1s9;

    const uint32_t t3 = xo_table[3];
    xo_table[3] =  ((t3 << 11) | (t3 >> (32-11)));

    return result;
}


#include <stdlib.h>

/* I'm putting a wrapper for qsort() here, in case I ever have to
   worry about a platform without it. But I am not worrying at
   present. */
void glulx_sort(void *addr, int count, int size, 
  int (*comparefunc)(void *p1, void *p2))
{
  qsort(addr, count, size, (int (*)(const void *, const void *))comparefunc);
}

#ifdef FLOAT_SUPPORT
#include <math.h>

/* This wrapper handles all special cases, even if the underlying
   powf() function doesn't. */
gfloat32 glulx_powf(gfloat32 val1, gfloat32 val2)
{
  if (val1 == 1.0f)
    return 1.0f;
  else if ((val2 == 0.0f) || (val2 == -0.0f))
    return 1.0f;
  else if ((val1 == -1.0f) && isinf(val2))
    return 1.0f;
  return powf(val1, val2);
}

#endif /* FLOAT_SUPPORT */

#ifdef DOUBLE_SUPPORT

/* Same for pow(). */
extern gfloat64 glulx_pow(gfloat64 val1, gfloat64 val2)
{
  if (val1 == 1.0)
    return 1.0;
  else if ((val2 == 0.0) || (val2 == -0.0))
    return 1.0;
  else if ((val1 == -1.0) && isinf(val2))
    return 1.0;
  return pow(val1, val2);
}

#endif /* DOUBLE_SUPPORT */
