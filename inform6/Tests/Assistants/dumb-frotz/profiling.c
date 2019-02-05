/* profiling.c: the game profiler */

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "frotz.h"

typedef struct profrec {
  long r_start, r_end;
  char *r_name;
  unsigned long hits;		/* opcodes executed in this routine */
  unsigned long allhits;	/* this routine + everything it calls */
  unsigned long calls;
  int nesting, max_nesting;
} profrec_t;

static profrec_t *rec_new(void);
static profrec_t *rec_find(long address);

typedef struct callrec {
  profrec_t *routine;
  struct callrec *prev;
} callrec_t;

#define MAX_STRING	100

static FILE *dbgfile;
static FILE *rsltfile = NULL;
static char dbgstring[MAX_STRING];
static profrec_t *records;
static int recordcount, recordspace;
static callrec_t *callstack;
static unsigned long totalhits, maxstack, totalcalls;

static zbyte dbg_byte()
{
  return (zbyte)fgetc(dbgfile);
}

static zword dbg_word()
{
  zbyte first = dbg_byte();
  zbyte second = dbg_byte();
  return (first << 8) + second;
}

static long dbg_addr()
{
  zbyte top = dbg_byte();
  zword bot = dbg_word();
  return (top << 16) + bot;
}

static unsigned long dbg_line()
{
  zword first = dbg_word();
  zword second = dbg_word();
  return (first << 16) + second;
}

static char *dbg_string()
{
  int i;
  for (i = 0; ; i++) {
    zbyte b = dbg_byte();
    if (i < MAX_STRING)
      dbgstring[i] = b;
    if (!b)
      break;
  }
  dbgstring[MAX_STRING - 1] = '\0';
  return dbgstring;
}

static int compare_recs_addr(const void *p1, const void *p2)
{
  return ((profrec_t *)p1)->r_start - ((profrec_t *)p2)->r_start;
}

static int compare_recs_hits(const void *p1, const void *p2)
{
  return ((profrec_t *)p2)->allhits - ((profrec_t *)p1)->allhits;
}

void prof_dest(const char *filename)
{
  rsltfile = fopen(filename, "w");
  if (!rsltfile)
    return;
}

void prof_init(const char *filename)
{
  profrec_t *rec = NULL;
  long codearea = 0;
  int i;

  if (!rsltfile)
    rsltfile = stderr;

  dbgfile = fopen(filename, "rb");
  if (!dbgfile)
    return;
  
  /* check file header and version */
  if (dbg_word() != 0xDEBF)
    os_fatal("Not an Inform debug file");
  if (dbg_word() != 0)
    os_fatal("Unrecognized debug file version");
  dbg_word(); /* skip Inform version */

  records = NULL;
  recordcount = recordspace = 0;
  callstack = NULL;
  totalhits = 0;
  maxstack = 0;
  
  while (!feof(dbgfile)) {
    zbyte type = dbg_byte();
    zword w;
    long a;
    char *s;

    switch (type) {
      /* a bunch of debug record types we don't care about */
      case 0: fseek(dbgfile, 0L, SEEK_END); break;
      case 1: dbg_byte(); dbg_string(); dbg_string(); break;
      case 2: dbg_string(); dbg_line(); dbg_line(); break;
      case 3: dbg_word(); dbg_string(); dbg_line(); dbg_line(); break;
      case 4: dbg_byte(); dbg_string(); break;
      case 5: case 6: case 7: case 8: case 12:
        dbg_word(); dbg_string(); break;
      case 10:
        dbg_word();
        w = dbg_word();
        while (w--) {
          dbg_line();
          dbg_word();
        }
        break;
      
      case 9:
        /* associated game header (we'll trust the user for now) */
        fseek(dbgfile, 64L, SEEK_CUR);
        break;
      
      case 11:
        /* routine start */
        rec = rec_new();
        dbg_word();
        dbg_line();
        rec->r_start = dbg_addr();
        s = dbg_string();
        rec->r_name = (char *)malloc(strlen(s) + 1);
        strcpy(rec->r_name, s);
        while (strlen(dbg_string()) != 0)
          ;	/* skip local variable names */
        break;
      
      case 14:
        /* routine end */
        if (!rec)
          os_fatal("ROUTINE_END_DBR without matching ROUTINE_DBR");
        dbg_word();
        dbg_line();
        rec->r_end = dbg_addr();
        rec = NULL;
        break;
        
      case 13:
        /* memory map */
        do {
          s = dbg_string();
          if (*s) {
            a = dbg_addr();
            if (!strcmp(s, "code area"))
              codearea = a;
          }
        } while (*s);
        break;
    }
  }
  
  /* patch routine addresses and sort records */
  for (i = 0; i < recordcount; i++) {
    records[i].r_start += codearea;
    records[i].r_end += codearea;
  }
  qsort(records, recordcount, sizeof(profrec_t), compare_recs_addr);
}

void prof_enter(long pc)
{
  callrec_t *call = malloc(sizeof(callrec_t));
  profrec_t *routine = rec_find(pc);
  if (!call)
    os_fatal("Out of memory for profiling call stack");
  call->routine = routine;
  call->prev = callstack;
  callstack = call;

  totalcalls++;

  if (routine) {
    routine->calls++;
    routine->nesting = 0;
    
    for (call = callstack; call; call = call->prev)
      if (call->routine == routine)
        routine->nesting++;
    
    if (routine->nesting > routine->max_nesting)
      routine->max_nesting = routine->nesting;
  }
}

void prof_leave()
{
  if (callstack) {
    callrec_t *cur = callstack;
    callstack = cur->prev;
    free(cur);
  }
}

void prof_bill_opcode()
{
  totalhits++;
  
  if (callstack) {
    callrec_t *c;
    
    if (callstack->routine && callstack->routine->hits < ULONG_MAX)
      callstack->routine->hits++;
    
    for (c = callstack; c; c = c->prev)
      if (c->routine)
        c->routine->nesting = 0;
    
    for (c = callstack; c; c = c->prev)
      if (c->routine) {
        c->routine->nesting++;
        if (c->routine->nesting == 1 && c->routine->allhits < ULONG_MAX)
          c->routine->allhits++;
      }
  }
}

void prof_note_stack(unsigned long depth)
{
  if (depth > maxstack)
    maxstack = depth;
}

void prof_report()
{
  int i;
  
  fprintf(rsltfile, "Total opcodes: %lu\n", totalhits);
  fprintf(rsltfile, "Total routine calls: %lu\n", totalcalls);
  fprintf(rsltfile, "Max. stack usage: %lu words\n\n", maxstack);
  
  fprintf(rsltfile, "%-35s      %-10s      %-10s %-10s %-4s\n",
    "Routine", "Ops", "Ops(+Subs)", "Calls", "Nest");
  
  qsort(records, recordcount, sizeof(profrec_t), compare_recs_hits);
  
  for (i = 0; i < recordcount; i++) {
  	char percent1[32], percent2[32];
  	int pc1, pc2;
    if (!records[i].allhits)
      continue;
    
    pc1 = ((int) (100*((float) records[i].hits)/((float) totalhits)));
    pc2 = ((int) (100*((float) records[i].allhits)/((float) totalhits)));
    if (pc1 > 0) sprintf(percent1, "%3d%%", pc1); else sprintf(percent1, "    ");
    if (pc2 > 0) sprintf(percent2, "%3d%%", pc2); else sprintf(percent2, "    ");
    
    fprintf(rsltfile, "%-35s %s %-10lu %s %-10lu %-10lu %-4d\n",
      records[i].r_name,
      percent1,
      records[i].hits,
      percent2,
      records[i].allhits,
      records[i].calls,
      records[i].max_nesting);
  }
  
  if (rsltfile != stderr) fclose(rsltfile);
}

static profrec_t *rec_new()
{
  if (recordcount >= recordspace) {
    if (!recordspace)
      recordspace = 10;
    else
      recordspace *= 2;
    profrec_t *newrecs = realloc(records, recordspace * sizeof(profrec_t));
    if (!newrecs)
      os_fatal("Out of memory for profiling records");
    records = newrecs;
  }
  
  int idx = recordcount++;
  memset(&records[idx], 0, sizeof(profrec_t));
  return &records[idx];
}

static profrec_t *rec_find(long address)
{
  int start = 0, end = recordcount;
  while (start < end) {
    int mid = (start + end) / 2;
    profrec_t *rec = &records[mid];
    if (rec->r_start <= address && rec->r_end > address)
      return rec;
    else if (rec->r_start < address)
      start = mid + 1;
    else
      end = mid;
  }
  return NULL;
}
