/* heap.c: Glulxe code related to the dynamic allocation heap.
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "glulxe.h"

typedef struct heapblock_struct {
  glui32 addr;
  glui32 len;
  int isfree;
  struct heapblock_struct *next;
  struct heapblock_struct *prev;
} heapblock_t;

static glui32 heap_start = 0; /* zero for inactive heap */
static int alloc_count = 0;

/* The heap_head/heap_tail is a doubly-linked list of blocks, both
   free and allocated. It is kept in address order. It should be
   complete -- that is, the first block starts at heap_start, and each
   block ends at the beginning of the next block, until the last one,
   which ends at endmem.

   (Heap_start is never the same as end_mem; if there is no heap space,
   then the heap is inactive and heap_start is zero.)

   Adjacent free blocks may be merged at heap_alloc() time.

   ### To make alloc more efficient, we could keep a separate
   free-list. To make free more efficient, we could keep a hash
   table of allocations.
 */
static heapblock_t *heap_head = NULL;
static heapblock_t *heap_tail = NULL;

/* heap_clear():
   Set the heap state to inactive, and free the block lists. This is
   called when the game starts or restarts.
*/
void heap_clear()
{
  while (heap_head) {
    heapblock_t *blo = heap_head;
    heap_head = blo->next;
    blo->next = NULL;
    blo->prev = NULL;
    glulx_free(blo);
  }
  heap_tail = NULL;

  if (heap_start) {
    glui32 res = change_memsize(heap_start, TRUE);
    if (res)
      fatal_error_i("Unable to revert memory size when deactivating heap.",
        heap_start);
  }

  heap_start = 0;
  alloc_count = 0;
  /* heap_sanity_check(); */
}

/* heap_is_active():
   Returns whether the heap is active.
*/
int heap_is_active() {
  return (heap_start != 0);
}

/* heap_get_start():
   Returns the start address of the heap, or 0 if the heap is not active.
 */
glui32 heap_get_start() {
  return heap_start;
}

/* heap_alloc(): 
   Allocate a block. If necessary, activate the heap and/or extend memory.
   This may not be available at all; #define FIXED_MEMSIZE if you want
   the interpreter to unconditionally refuse.
   Returns the memory address of the block, or 0 if the operation failed.
*/
glui32 heap_alloc(glui32 len)
{
  heapblock_t *blo, *newblo;

#ifdef FIXED_MEMSIZE
  return 0;
#else /* FIXED_MEMSIZE */

  if (len <= 0)
    fatal_error("Heap allocation length must be positive.");

  blo = heap_head;
  while (blo) {
    if (blo->isfree && blo->len >= len)
      break;

    if (!blo->isfree) {
      blo = blo->next;
      continue;
    }

    if (!blo->next || !blo->next->isfree) {
      blo = blo->next;
      continue;
    }

    /* This is a free block, but the next block in the list is also
       free, so we "advance" by merging rather than by going to
       blo->next. */
    newblo = blo->next;
    blo->len += newblo->len;
    if (newblo->next) {
      blo->next = newblo->next;
      newblo->next->prev = blo;
    }
    else {
      blo->next = NULL;
      heap_tail = blo;
    }
    newblo->next = NULL;
    newblo->prev = NULL;
    glulx_free(newblo);
    newblo = NULL;
    continue;
  }

  if (!blo) {
    /* No free area is visible on the list. Try extending memory. How
       much? Double the heap size, or by 256 bytes, or by the memory
       length requested -- whichever is greatest. */
    glui32 res;
    glui32 extension;
    glui32 oldendmem = endmem;

    extension = 0;
    if (heap_start)
      extension = endmem - heap_start;
    if (extension < len)
      extension = len;
    if (extension < 256)
      extension = 256;
    /* And it must be rounded up to a multiple of 256. */
    extension = (extension + 0xFF) & (~(glui32)0xFF);

    res = change_memsize(endmem+extension, TRUE);
    if (res)
      return 0;

    /* If we just started the heap, note that. */
    if (heap_start == 0)
      heap_start = oldendmem;

    if (heap_tail && heap_tail->isfree) {
      /* Append the new space to the last block. */
      blo = heap_tail;
      blo->len += extension;
    }
    else {
      /* Append the new space to the block list, as a new block. */
      newblo = glulx_malloc(sizeof(heapblock_t));
      if (!newblo)
        fatal_error("Unable to allocate record for heap block.");
      newblo->addr = oldendmem;
      newblo->len = extension;
      newblo->isfree = TRUE;
      newblo->next = NULL;
      newblo->prev = NULL;

      if (!heap_tail) {
        heap_head = newblo;
        heap_tail = newblo;
      }
      else {
        blo = heap_tail;
        heap_tail = newblo;
        blo->next = newblo;
        newblo->prev = blo;
      }

      blo = newblo;
      newblo = NULL;
    }

    /* and continue forwards, using this new block (blo). */
  }

  /* Something strange happened. */
  if (!blo || !blo->isfree || blo->len < len)
    return 0;

  /* We now have a free block of size len or longer. */

  if (blo->len == len) {
    blo->isfree = FALSE;
  }
  else {
    newblo = glulx_malloc(sizeof(heapblock_t));
    if (!newblo)
      fatal_error("Unable to allocate record for heap block.");
    newblo->isfree = TRUE;
    newblo->addr = blo->addr + len;
    newblo->len = blo->len - len;
    blo->len = len;
    blo->isfree = FALSE;
    newblo->next = blo->next;
    if (newblo->next)
      newblo->next->prev = newblo;
    newblo->prev = blo;
    blo->next = newblo;
    if (heap_tail == blo)
      heap_tail = newblo;
  }

  alloc_count++;
  /* heap_sanity_check(); */
  return blo->addr;

#endif /* FIXED_MEMSIZE */
}

/* heap_free():
   Free a heap block. If necessary, deactivate the heap.
*/
void heap_free(glui32 addr)
{
  heapblock_t *blo;

  for (blo = heap_head; blo; blo = blo->next) { 
    if (blo->addr == addr)
      break;
  };
  if (!blo || blo->isfree)
    fatal_error_i("Attempt to free unallocated address from heap.", addr);

  blo->isfree = TRUE;
  alloc_count--;
  if (alloc_count <= 0) {
    heap_clear();
  }

  /* heap_sanity_check(); */
}

/* heap_get_summary():
   Create an array of words, in the VM serialization format:

     heap_start
     alloc_count
     addr of first block
     len of first block
     ...

   (Note that these are glui32 values -- native byte ordering. Also,
   the blocks will be in address order, which is a stricter guarantee
   than the VM specifies; that'll help in heap_apply_summary().)

   If the heap is inactive, store NULL. Return 0 for success;
   otherwise, the operation failed.

   The array returned in summary must be freed with glulx_free() after
   the caller uses it.
*/
int heap_get_summary(glui32 *valcount, glui32 **summary)
{
  glui32 *arr, len, pos;
  heapblock_t *blo;

  *valcount = 0;
  *summary = NULL;

  if (heap_start == 0)
    return 0;

  len = 2 + 2*alloc_count;
  arr = glulx_malloc(len * sizeof(glui32));
  if (!arr)
    return 1;

  pos = 0;
  arr[pos++] = heap_start;
  arr[pos++] = alloc_count;

  for (blo = heap_head; blo; blo = blo->next) {
    if (blo->isfree)
      continue;
    arr[pos++] = blo->addr;
    arr[pos++] = blo->len;
  }

  if (pos != len)
    fatal_error("Wrong number of active blocks in heap");

  *valcount = len;
  *summary = arr;
  return 0;
}

/* heap_apply_summary():
   Given an array of words in the above format, set up the heap to
   contain it. As noted above, the caller must ensure that the blocks
   are in address order. When this is called, the heap must be
   inactive.

   Return 0 for success. Otherwise the operation failed (and, most
   likely, caused a fatal error).
*/
int heap_apply_summary(glui32 valcount, glui32 *summary)
{
  glui32 lx, jx, lastend;

  if (heap_start)
    fatal_error("Heap active when heap_apply_summary called");

  if (valcount == 0 || summary == NULL)
    return 0;
  if (valcount == 2 && summary[0] == 0 && summary[1] == 0)
    return 0;

#ifdef FIXED_MEMSIZE
  return 1;
#else /* FIXED_MEMSIZE */

  lx = 0;
  heap_start = summary[lx++];
  alloc_count = summary[lx++];

  for (jx=lx; jx+2<valcount; jx+=2) {
    if (summary[jx] >= summary[jx+2])
      fatal_error("Heap block summary is out of order.");
  }

  lastend = heap_start;

  while (lx < valcount || lastend < endmem) {
    heapblock_t *blo;

    blo = glulx_malloc(sizeof(heapblock_t));
    if (!blo)
      fatal_error("Unable to allocate record for heap block.");

    if (lx >= valcount) {
      blo->addr = lastend;
      blo->len = endmem - lastend;
      blo->isfree = TRUE;
    }
    else {
      if (lastend < summary[lx]) {
        blo->addr = lastend;
        blo->len = summary[lx] - lastend;
        blo->isfree = TRUE;
      }
      else {
        blo->addr = summary[lx++];
        blo->len = summary[lx++];
        blo->isfree = FALSE;
      }
    }

    blo->prev = NULL;
    blo->next = NULL;

    if (!heap_head) {
      heap_head = blo;
      heap_tail = blo;
    }
    else {
      heap_tail->next = blo;
      blo->prev = heap_tail;
      heap_tail = blo;
    }

    lastend = blo->addr + blo->len;
  }

  /* heap_sanity_check(); */

  return 0;
#endif /* FIXED_MEMSIZE */
}

#if 0
#include <stdio.h>

static void heap_dump(void);

/* heap_dump():
   Print out the heap list (using printf). This exists for debugging,
   which is why it's ifdeffed out.
*/
static void heap_dump()
{
  heapblock_t *blo;

  if (heap_start == 0) {
    printf("# Heap is inactive.\n");
    return;    
  }

  printf("# Heap active: %d outstanding blocks\n", alloc_count);
  printf("# Heap start: %ld\n", heap_start);

  for (blo = heap_head; blo; blo = blo->next) {
    printf("#  %s at %ld..%ld, len %ld\n", 
      (blo->isfree ? " free" : "*used"),
      blo->addr, blo->addr+blo->len, blo->len);
  }

  printf("# Heap end: %ld\n", endmem);
}

/* heap_sanity_check():
   Check the validity of the heap. Throw a fatal error if anything is
   wrong.
*/
void heap_sanity_check()
{
  heapblock_t *blo, *last;
  int livecount;

  heap_dump();

  if (heap_start == 0) {
    if (heap_head || heap_tail)
      fatal_error("Heap sanity: nonempty list when heap is inactive.");
    if (alloc_count)
      fatal_error_i("Heap sanity: outstanding blocks when heap is inactive.",
        alloc_count);
    return;
  }

#ifdef FIXED_MEMSIZE
  fatal_error("Heap sanity: heap is active, but interpreter is compiled with no allocation.");
#endif /* FIXED_MEMSIZE */

  /* When the heap is active there may, briefly, be no heapblocks on the
     list. */

  last = NULL;
  livecount = 0;

  for (blo = heap_head; blo; last = blo, blo = blo->next) {
    glui32 lastend;

    if (blo->prev != last)
      fatal_error("Heap sanity: prev pointer mismatch.");
    if (!last) 
      lastend = heap_start;
    else
      lastend = last->addr + last->len;
    if (lastend != blo->addr)
      fatal_error("Heap sanity: addr+len mismatch.");

    if (!blo->isfree)
      livecount++;
  }

  if (!last) {
    if (heap_start != endmem)
      fatal_error_i("Heap sanity: empty list, but endmem is not heap start.",
        heap_start);
    if (heap_tail)
      fatal_error("Heap sanity: empty list, but heap tail exists.");
  }
  else {
    if (last->addr + last->len != endmem)
      fatal_error_i("Heap sanity: last block does not end at endmem.",
        last->addr + last->len);
    if (last != heap_tail)
      fatal_error("Heap sanity: heap tail points wrong.");
  }

  if (livecount != alloc_count)
    fatal_error_i("Heap sanity: wrong number of live blocks.", livecount);
}

#endif /* 0 */

