/* gestalt.c: Glulxe code for gestalt selectors
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "glulxe.h"
#include "gestalt.h"

glui32 do_gestalt(glui32 val, glui32 val2)
{
  switch (val) {

  case gestulx_GlulxVersion:
    return 0x00030103; /* Glulx spec version 3.1.3 */

  case gestulx_TerpVersion:
    return 0x00000601; /* Glulxe version 0.6.1 */

  case gestulx_ResizeMem:
#ifdef FIXED_MEMSIZE
    return 0; /* The setmemsize opcodes are compiled out. */
#else /* FIXED_MEMSIZE */
    return 1; /* We can handle setmemsize. */
#endif /* FIXED_MEMSIZE */

  case gestulx_Undo:
    if (max_undo_level > 0)
      return 1; /* We can handle saveundo and restoreundo. */
    return 0; /* Got "--undo 0", so nope. */

  case gestulx_IOSystem:
    switch (val2) {
    case 0:
      return 1; /* The "null" system always works. */
    case 1:
      return 1; /* The "filter" system always works. */
    case 2:
      return 1; /* A Glk library is hooked up. */
    default:
      return 0;
    }

  case gestulx_Unicode:
    return 1; /* We can handle Unicode. */

  case gestulx_MemCopy:
    return 1; /* We can do mcopy/mzero. */

  case gestulx_MAlloc:
#ifdef FIXED_MEMSIZE
    return 0; /* The malloc opcodes are compiled out. */
#else /* FIXED_MEMSIZE */
    return 1; /* We can handle malloc/mfree. */
#endif /* FIXED_MEMSIZE */

  case gestulx_MAllocHeap:
    return heap_get_start();

  case gestulx_Acceleration:
    return 1; /* We can do accelfunc/accelparam. */

  case gestulx_AccelFunc:
    if (accel_find_func(val2))
      return 1; /* We know this accelerated function. */
    return 0;

  case gestulx_Float:
#ifdef FLOAT_SUPPORT
    return 1; /* We can do floating-point operations. */
#else /* FLOAT_SUPPORT */
    return 0; /* The floating-point opcodes are not compiled in. */
#endif /* FLOAT_SUPPORT */

  case gestulx_ExtUndo:
    return 1; /* We can handle hasundo and discardundo. */

  case gestulx_Double:
#ifdef FLOAT_SUPPORT
#ifdef DOUBLE_SUPPORT   /* Inside FLOAT_SUPPORT! */
    return 1; /* We can do double-precision operations. */
#else /* DOUBLE_SUPPORT */
    return 0; /* The double-precision opcodes are not compiled in. */
#endif /* DOUBLE_SUPPORT */
#else /* FLOAT_SUPPORT */
    return 0; /* Neither float nor double opcodes are compiled in. */
#endif /* FLOAT_SUPPORT */

#ifdef GLULX_EXTEND_GESTALT
  GLULX_EXTEND_GESTALT
#endif /* GLULX_EXTEND_GESTALT */

  default:
    return 0;

  }
}
