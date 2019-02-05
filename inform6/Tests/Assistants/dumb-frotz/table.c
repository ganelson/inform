/*
 * table.c
 *
 * Table handling opcodes
 *
 */

#include "frotz.h"

/*
 * z_copy_table, copy a table or fill it with zeroes.
 *
 *	zargs[0] = address of table
 * 	zargs[1] = destination address or 0 for fill
 *	zargs[2] = size of table
 *
 * Note: Copying is safe even when source and destination overlap; but
 *       if zargs[1] is negative the table _must_ be copied forwards.
 *
 */

void z_copy_table (void)
{
    zword addr;
    zword size = zargs[2];
    zbyte value;
    int i;

    if (zargs[1] == 0)      				/* zero table */

	for (i = 0; i < size; i++)
	    storeb ((zword) (zargs[0] + i), 0);

    else if ((short) size < 0 || zargs[0] > zargs[1])	/* copy forwards */

	for (i = 0; i < (((short) size < 0) ? - (short) size : size); i++) {
	    addr = zargs[0] + i;
	    LOW_BYTE (addr, value)
	    storeb ((zword) (zargs[1] + i), value);
	}

    else						/* copy backwards */

	for (i = size - 1; i >= 0; i--) {
	    addr = zargs[0] + i;
	    LOW_BYTE (addr, value)
	    storeb ((zword) (zargs[1] + i), value);
	}

}/* z_copy_table */

/*
 * z_loadb, store a value from a table of bytes.
 *
 *	zargs[0] = address of table
 *	zargs[1] = index of table entry to store
 *
 */

void z_loadb (void)
{
    zword addr = zargs[0] + zargs[1];
    zbyte value;

    LOW_BYTE (addr, value)

    store (value);

}/* z_loadb */

/*
 * z_loadw, store a value from a table of words.
 *
 *	zargs[0] = address of table
 *	zargs[1] = index of table entry to store
 *
 */

void z_loadw (void)
{
    zword addr = zargs[0] + 2 * zargs[1];
    zword value;

    LOW_WORD (addr, value)

    store (value);

}/* z_loadw */

/*
 * z_scan_table, find and store the address of a target within a table.
 *
 *	zargs[0] = target value to be searched for
 *	zargs[1] = address of table
 *	zargs[2] = number of table entries to check value against
 *	zargs[3] = type of table (optional, defaults to 0x82)
 *
 * Note: The table is a word array if bit 7 of zargs[3] is set; otherwise
 *       it's a byte array. The lower bits hold the address step.
 *
 */

void z_scan_table (void)
{
    zword addr = zargs[1];
    int i;

    /* Supply default arguments */

    if (zargc < 4)
	zargs[3] = 0x82;

    /* Scan byte or word array */

    for (i = 0; i < zargs[2]; i++) {

	if (zargs[3] & 0x80) {	/* scan word array */

	    zword wvalue;

	    LOW_WORD (addr, wvalue)

	    if (wvalue == zargs[0])
		goto finished;

	} else {		/* scan byte array */

	    zbyte bvalue;

	    LOW_BYTE (addr, bvalue)

	    if (bvalue == zargs[0])
		goto finished;

	}

	addr += zargs[3] & 0x7f;

    }

    addr = 0;

finished:

    store (addr);
    branch (addr);

}/* z_scan_table */

/*
 * z_storeb, write a byte into a table of bytes.
 *
 *	zargs[0] = address of table
 *	zargs[1] = index of table entry
 *	zargs[2] = value to be written
 *
 */

void z_storeb (void)
{

    storeb ((zword) (zargs[0] + zargs[1]), zargs[2]);

}/* z_storeb */

/*
 * z_storew, write a word into a table of words.
 *
 *	zargs[0] = address of table
 *	zargs[1] = index of table entry
 *	zargs[2] = value to be written
 *
 */

void z_storew (void)
{

    storew ((zword) (zargs[0] + 2 * zargs[1]), zargs[2]);

}/* z_storew */
