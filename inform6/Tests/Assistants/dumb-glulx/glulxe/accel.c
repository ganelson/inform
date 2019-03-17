/* accel.c: Glulxe code for accelerated functions
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#include "glk.h"
#include "glulxe.h"

/* Git passes along function arguments in reverse order. To make our lives
   more interesting. */
#ifdef ARGS_REVERSED
#define ARG(argv, argc, ix) (argv[(argc-1)-ix])
#else
#define ARG(argv, argc, ix) (argv[ix])
#endif

/* Any function can be called with any number of arguments. This macro
   lets us snarf a given argument, or zero if it wasn't supplied. */
#define ARG_IF_GIVEN(argv, argc, ix)  ((argc > ix) ? (ARG(argv, argc, ix)) : 0)

static void accel_error(char *msg);
static glui32 func_1_z__region(glui32 argc, glui32 *argv);
static glui32 func_2_cp__tab(glui32 argc, glui32 *argv);
static glui32 func_3_ra__pr(glui32 argc, glui32 *argv);
static glui32 func_4_rl__pr(glui32 argc, glui32 *argv);
static glui32 func_5_oc__cl(glui32 argc, glui32 *argv);
static glui32 func_6_rv__pr(glui32 argc, glui32 *argv);
static glui32 func_7_op__pr(glui32 argc, glui32 *argv);
static glui32 func_8_cp__tab(glui32 argc, glui32 *argv);
static glui32 func_9_ra__pr(glui32 argc, glui32 *argv);
static glui32 func_10_rl__pr(glui32 argc, glui32 *argv);
static glui32 func_11_oc__cl(glui32 argc, glui32 *argv);
static glui32 func_12_rv__pr(glui32 argc, glui32 *argv);
static glui32 func_13_op__pr(glui32 argc, glui32 *argv);

static int obj_in_class(glui32 obj);
static glui32 get_prop(glui32 obj, glui32 id);
static glui32 get_prop_new(glui32 obj, glui32 id);

/* Parameters, set by @accelparam. */
static glui32 classes_table = 0;     /* class object array */
static glui32 indiv_prop_start = 0;  /* first individual prop ID */
static glui32 class_metaclass = 0;   /* "Class" class object */
static glui32 object_metaclass = 0;  /* "Object" class object */
static glui32 routine_metaclass = 0; /* "Routine" class object */
static glui32 string_metaclass = 0;  /* "String" class object */
static glui32 self = 0;              /* address of global "self" */
static glui32 num_attr_bytes = 0;    /* number of attributes / 8 */
static glui32 cpv__start = 0;        /* array of common prop defaults */

typedef struct accelentry_struct {
    glui32 addr;
    glui32 index;
    acceleration_func func;
    struct accelentry_struct *next;
} accelentry_t;

#define ACCEL_HASH_SIZE (511)

static accelentry_t **accelentries = NULL;

void init_accel()
{
    accelentries = NULL;
}

acceleration_func accel_find_func(glui32 index)
{
    switch (index) {
        case 0: return NULL; /* 0 always means no acceleration */
        case 1: return func_1_z__region;
        case 2: return func_2_cp__tab;
        case 3: return func_3_ra__pr;
        case 4: return func_4_rl__pr;
        case 5: return func_5_oc__cl;
        case 6: return func_6_rv__pr;
        case 7: return func_7_op__pr;
        case 8: return func_8_cp__tab;
        case 9: return func_9_ra__pr;
        case 10: return func_10_rl__pr;
        case 11: return func_11_oc__cl;
        case 12: return func_12_rv__pr;
        case 13: return func_13_op__pr;
    }
    return NULL;
}

acceleration_func accel_get_func(glui32 addr)
{
    int bucknum;
    accelentry_t *ptr;

    if (!accelentries)
        return NULL;

    bucknum = (addr % ACCEL_HASH_SIZE);
    for (ptr = accelentries[bucknum]; ptr; ptr = ptr->next) {
        if (ptr->addr == addr)
            return ptr->func;
    }
    return NULL;
}

/* Iterate the entire acceleration table, calling the callback for
   each (non-NULL) entry. This is used only for autosave. */
void accel_iterate_funcs(void (*func)(glui32 index, glui32 addr))
{
    int bucknum;
    accelentry_t *ptr;

    if (!accelentries)
        return;

    for (bucknum=0; bucknum<ACCEL_HASH_SIZE; bucknum++) {
        for (ptr = accelentries[bucknum]; ptr; ptr = ptr->next) {
            if (ptr->func) {
                func(ptr->index, ptr->addr);
            }
        }
    }
}

void accel_set_func(glui32 index, glui32 addr)
{
    int bucknum;
    accelentry_t *ptr;
    int functype;
    acceleration_func new_func = NULL;

    /* Check the Glulx type identifier byte. */
    functype = Mem1(addr);
    if (functype != 0xC0 && functype != 0xC1) {
        fatal_error_i("Attempt to accelerate non-function.", addr);
    }

    if (!accelentries) {
        accelentries = (accelentry_t **)glulx_malloc(ACCEL_HASH_SIZE 
            * sizeof(accelentry_t *));
        if (!accelentries) 
            fatal_error("Cannot malloc acceleration table.");
        for (bucknum=0; bucknum<ACCEL_HASH_SIZE; bucknum++)
            accelentries[bucknum] = NULL;
    }

    new_func = accel_find_func(index);
    /* Might be NULL, if the index is zero or not recognized. */

    bucknum = (addr % ACCEL_HASH_SIZE);
    for (ptr = accelentries[bucknum]; ptr; ptr = ptr->next) {
        if (ptr->addr == addr)
            break;
    }
    if (!ptr) {
        if (!new_func) {
            return; /* no need for a new entry */
        }
        ptr = (accelentry_t *)glulx_malloc(sizeof(accelentry_t));
        if (!ptr)
            fatal_error("Cannot malloc acceleration entry.");
        ptr->addr = addr;
        ptr->index = 0;
        ptr->func = NULL;
        ptr->next = accelentries[bucknum];
        accelentries[bucknum] = ptr;
    }

    ptr->index = index;
    ptr->func = new_func;
}

void accel_set_param(glui32 index, glui32 val)
{
    switch (index) {
        case 0: classes_table = val; break;
        case 1: indiv_prop_start = val; break;
        case 2: class_metaclass = val; break;
        case 3: object_metaclass = val; break;
        case 4: routine_metaclass = val; break;
        case 5: string_metaclass = val; break;
        case 6: self = val; break;
        case 7: num_attr_bytes = val; break;
        case 8: cpv__start = val; break;
    }
}

/* This is used only for autosave. */
glui32 accel_get_param_count()
{
    return 9;
}

/* This is used only for autosave. */
glui32 accel_get_param(glui32 index)
{
    switch (index) {
        case 0: return classes_table;
        case 1: return indiv_prop_start;
        case 2: return class_metaclass;
        case 3: return object_metaclass;
        case 4: return routine_metaclass;
        case 5: return string_metaclass;
        case 6: return self;
        case 7: return num_attr_bytes;
        case 8: return cpv__start;
        default: return 0;
    }
}

static void accel_error(char *msg)
{
    glk_put_char('\n');
    glk_put_string(msg);
    glk_put_char('\n');
}

static int obj_in_class(glui32 obj)
{
    /* This checks whether obj is contained in Class, not whether
       it is a member of Class. */
    return (Mem4(obj + 13 + num_attr_bytes) == class_metaclass);
}

/* Look up a property entry. */
static glui32 get_prop(glui32 obj, glui32 id)
{
    glui32 cla = 0;
    glui32 prop;
    glui32 call_argv[2];

    if (id & 0xFFFF0000) {
        cla = Mem4(classes_table+((id & 0xFFFF) * 4));
        ARG(call_argv, 2, 0) = obj;
        ARG(call_argv, 2, 1) = cla;
        if (func_5_oc__cl(2, call_argv) == 0)
            return 0;

        id >>= 16;
        obj = cla;
    }

    ARG(call_argv, 2, 0) = obj;
    ARG(call_argv, 2, 1) = id;
    prop = func_2_cp__tab(2, call_argv);
    if (prop == 0)
        return 0;

    if (obj_in_class(obj) && (cla == 0)) {
        if ((id < indiv_prop_start) || (id >= indiv_prop_start+8))
            return 0;
    }

    if (Mem4(self) != obj) {
        if (Mem1(prop + 9) & 1)
            return 0;
    }
    return prop;
}

/* Look up a property entry. This is part of the newer set of accel
   functions (8 through 13), which support increasing NUM_ATTR_BYTES.
   It is identical to get_prop() except that it calls the new versions
   of func_5 and func_2. */
static glui32 get_prop_new(glui32 obj, glui32 id)
{
    glui32 cla = 0;
    glui32 prop;
    glui32 call_argv[2];

    if (id & 0xFFFF0000) {
        cla = Mem4(classes_table+((id & 0xFFFF) * 4));
        ARG(call_argv, 2, 0) = obj;
        ARG(call_argv, 2, 1) = cla;
        if (func_11_oc__cl(2, call_argv) == 0)
            return 0;

        id >>= 16;
        obj = cla;
    }

    ARG(call_argv, 2, 0) = obj;
    ARG(call_argv, 2, 1) = id;
    prop = func_8_cp__tab(2, call_argv);
    if (prop == 0)
        return 0;

    if (obj_in_class(obj) && (cla == 0)) {
        if ((id < indiv_prop_start) || (id >= indiv_prop_start+8))
            return 0;
    }

    if (Mem4(self) != obj) {
        if (Mem1(prop + 9) & 1)
            return 0;
    }
    return prop;
}

static glui32 func_1_z__region(glui32 argc, glui32 *argv)
{
    glui32 addr;
    glui32 tb;

    if (argc < 1)
        return 0;

    addr = ARG(argv, argc, 0);
    if (addr < 36)
        return 0;
    if (addr >= endmem)
        return 0;

    tb = Mem1(addr);
    if (tb >= 0xE0) {
        return 3;
    }
    if (tb >= 0xC0) {
        return 2;
    }
    if (tb >= 0x70 && tb <= 0x7F && addr >= ramstart) {
        return 1;
    }
    return 0;
}

/* The old set of accel functions (2 through 7) are deprecated; they
   behave badly if the Inform 6 NUM_ATTR_BYTES option (parameter 7) is
   changed from its default value (7). They will not be removed, but
   new games should use functions 8 through 13 instead. */

static glui32 func_2_cp__tab(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 otab, max;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    if (func_1_z__region(1, &obj) != 1) {
        accel_error("[** Programming error: tried to find the \".\" of (something) **]");
        return 0;
    }

    otab = Mem4(obj + 16);
    if (!otab)
        return 0;

    max = Mem4(otab);
    otab += 4;
    /* @binarysearch id 2 otab 10 max 0 0 res; */
    return binary_search(id, 2, otab, 10, max, 0, 0);
}

static glui32 func_3_ra__pr(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 prop;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    prop = get_prop(obj, id);
    if (prop == 0)
        return 0;

    return Mem4(prop + 4);
}

static glui32 func_4_rl__pr(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 prop;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    prop = get_prop(obj, id);
    if (prop == 0)
        return 0;

    return 4 * Mem2(prop + 2);
}

static glui32 func_5_oc__cl(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 cla;
    glui32 zr, prop, inlist, inlistlen, jx;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    cla = ARG_IF_GIVEN(argv, argc, 1);

    zr = func_1_z__region(1, &obj);
    if (zr == 3)
        return (cla == string_metaclass) ? 1 : 0;
    if (zr == 2)
        return (cla == routine_metaclass) ? 1 : 0;
    if (zr != 1)
        return 0;

    if (cla == class_metaclass) {
        if (obj_in_class(obj))
            return 1;
        if (obj == class_metaclass)
            return 1;
        if (obj == string_metaclass)
            return 1;
        if (obj == routine_metaclass)
            return 1;
        if (obj == object_metaclass)
            return 1;
        return 0;
    }
    if (cla == object_metaclass) {
        if (obj_in_class(obj))
            return 0;
        if (obj == class_metaclass)
            return 0;
        if (obj == string_metaclass)
            return 0;
        if (obj == routine_metaclass)
            return 0;
        if (obj == object_metaclass)
            return 0;
        return 1;
    }
    if ((cla == string_metaclass) || (cla == routine_metaclass))
        return 0;

    if (!obj_in_class(cla)) {
        accel_error("[** Programming error: tried to apply 'ofclass' with non-class **]");
        return 0;
    }

    prop = get_prop(obj, 2);
    if (prop == 0)
       return 0;

    inlist = Mem4(prop + 4);
    if (inlist == 0)
       return 0;

    inlistlen = Mem2(prop + 2);
    for (jx = 0; jx < inlistlen; jx++) {
        if (Mem4(inlist + (4 * jx)) == cla)
            return 1;
    }
    return 0;
}

static glui32 func_6_rv__pr(glui32 argc, glui32 *argv)
{
    glui32 id;
    glui32 addr;

    id = ARG_IF_GIVEN(argv, argc, 1);

    addr = func_3_ra__pr(argc, argv);

    if (addr == 0) {
        if ((id > 0) && (id < indiv_prop_start))
            return Mem4(cpv__start + (4 * id));

        accel_error("[** Programming error: tried to read (something) **]");
        return 0;
    }

    return Mem4(addr);
}

static glui32 func_7_op__pr(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 zr;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    zr = func_1_z__region(1, &obj);
    if (zr == 3) {
        /* print is INDIV_PROP_START+6 */
        if (id == indiv_prop_start+6)
            return 1;
        /* print_to_array is INDIV_PROP_START+7 */
        if (id == indiv_prop_start+7)
            return 1;
        return 0;
    }
    if (zr == 2) {
        /* call is INDIV_PROP_START+5 */
        return ((id == indiv_prop_start+5) ? 1 : 0);
    }
    if (zr != 1)
        return 0;

    if ((id >= indiv_prop_start) && (id < indiv_prop_start+8)) {
        if (obj_in_class(obj))
            return 1;
    }

    return ((func_3_ra__pr(argc, argv)) ? 1 : 0);
}

/* Here are the newer functions, which support changing NUM_ATTR_BYTES.
   These call get_prop_new() instead of get_prop(). */

static glui32 func_8_cp__tab(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 otab, max;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    if (func_1_z__region(1, &obj) != 1) {
        accel_error("[** Programming error: tried to find the \".\" of (something) **]");
        return 0;
    }

    otab = Mem4(obj + 4*(3+(int)(num_attr_bytes/4)));
    if (!otab)
        return 0;

    max = Mem4(otab);
    otab += 4;
    /* @binarysearch id 2 otab 10 max 0 0 res; */
    return binary_search(id, 2, otab, 10, max, 0, 0);
}

static glui32 func_9_ra__pr(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 prop;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    prop = get_prop_new(obj, id);
    if (prop == 0)
        return 0;

    return Mem4(prop + 4);
}

static glui32 func_10_rl__pr(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 prop;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    prop = get_prop_new(obj, id);
    if (prop == 0)
        return 0;

    return 4 * Mem2(prop + 2);
}

static glui32 func_11_oc__cl(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 cla;
    glui32 zr, prop, inlist, inlistlen, jx;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    cla = ARG_IF_GIVEN(argv, argc, 1);

    zr = func_1_z__region(1, &obj);
    if (zr == 3)
        return (cla == string_metaclass) ? 1 : 0;
    if (zr == 2)
        return (cla == routine_metaclass) ? 1 : 0;
    if (zr != 1)
        return 0;

    if (cla == class_metaclass) {
        if (obj_in_class(obj))
            return 1;
        if (obj == class_metaclass)
            return 1;
        if (obj == string_metaclass)
            return 1;
        if (obj == routine_metaclass)
            return 1;
        if (obj == object_metaclass)
            return 1;
        return 0;
    }
    if (cla == object_metaclass) {
        if (obj_in_class(obj))
            return 0;
        if (obj == class_metaclass)
            return 0;
        if (obj == string_metaclass)
            return 0;
        if (obj == routine_metaclass)
            return 0;
        if (obj == object_metaclass)
            return 0;
        return 1;
    }
    if ((cla == string_metaclass) || (cla == routine_metaclass))
        return 0;

    if (!obj_in_class(cla)) {
        accel_error("[** Programming error: tried to apply 'ofclass' with non-class **]");
        return 0;
    }

    prop = get_prop_new(obj, 2);
    if (prop == 0)
       return 0;

    inlist = Mem4(prop + 4);
    if (inlist == 0)
       return 0;

    inlistlen = Mem2(prop + 2);
    for (jx = 0; jx < inlistlen; jx++) {
        if (Mem4(inlist + (4 * jx)) == cla)
            return 1;
    }
    return 0;
}

static glui32 func_12_rv__pr(glui32 argc, glui32 *argv)
{
    glui32 id;
    glui32 addr;

    id = ARG_IF_GIVEN(argv, argc, 1);

    addr = func_9_ra__pr(argc, argv);

    if (addr == 0) {
        if ((id > 0) && (id < indiv_prop_start))
            return Mem4(cpv__start + (4 * id));

        accel_error("[** Programming error: tried to read (something) **]");
        return 0;
    }

    return Mem4(addr);
}

static glui32 func_13_op__pr(glui32 argc, glui32 *argv)
{
    glui32 obj;
    glui32 id;
    glui32 zr;

    obj = ARG_IF_GIVEN(argv, argc, 0);
    id = ARG_IF_GIVEN(argv, argc, 1);

    zr = func_1_z__region(1, &obj);
    if (zr == 3) {
        /* print is INDIV_PROP_START+6 */
        if (id == indiv_prop_start+6)
            return 1;
        /* print_to_array is INDIV_PROP_START+7 */
        if (id == indiv_prop_start+7)
            return 1;
        return 0;
    }
    if (zr == 2) {
        /* call is INDIV_PROP_START+5 */
        return ((id == indiv_prop_start+5) ? 1 : 0);
    }
    if (zr != 1)
        return 0;

    if ((id >= indiv_prop_start) && (id < indiv_prop_start+8)) {
        if (obj_in_class(obj))
            return 1;
    }

    return ((func_9_ra__pr(argc, argv)) ? 1 : 0);
}
