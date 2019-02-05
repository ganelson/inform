/*
 * object.c
 *
 * Object manipulation opcodes
 *
 */

#include "frotz.h"

#define MAX_OBJECT 2000

#define O1_PARENT 4
#define O1_SIBLING 5
#define O1_CHILD 6
#define O1_PROPERTY_OFFSET 7
#define O1_SIZE 9

#define O4_PARENT 6
#define O4_SIBLING 8
#define O4_CHILD 10
#define O4_PROPERTY_OFFSET 12
#define O4_SIZE 14

/*
 * object_address
 *
 * Calculate the address of an object.
 *
 */

static zword object_address (zword obj)
{

    /* Check object number */

    if (obj > ((h_version <= V3) ? 255 : MAX_OBJECT))
	runtime_error ("Illegal object");

    /* Return object address */

    if (h_version <= V3)
	return h_objects + ((obj - 1) * O1_SIZE + 62);
    else
	return h_objects + ((obj - 1) * O4_SIZE + 126);

}/* object_address */

/*
 * object_name
 *
 * Return the address of the given object's name.
 *
 */

zword object_name (zword object)
{
    zword obj_addr;
    zword name_addr;

    obj_addr = object_address (object);

    /* The object name address is found at the start of the properties */

    if (h_version <= V3)
	obj_addr += O1_PROPERTY_OFFSET;
    else
	obj_addr += O4_PROPERTY_OFFSET;

    LOW_WORD (obj_addr, name_addr)

    return name_addr;

}/* object_name */

/*
 * first_property
 *
 * Calculate the start address of the property list associated with
 * an object.
 *
 */

static zword first_property (zword obj)
{
    zword prop_addr;
    zbyte size;

    /* Fetch address of object name */

    prop_addr = object_name (obj);

    /* Get length of object name */

    LOW_BYTE (prop_addr, size)

    /* Add name length to pointer */

    return prop_addr + 1 + 2 * size;

}/* first_property */

/*
 * next_property
 *
 * Calculate the address of the next property in a property list.
 *
 */

static zword next_property (zword prop_addr)
{
    zbyte value;

    /* Load the current property id */

    LOW_BYTE (prop_addr, value)
    prop_addr++;

    /* Calculate the length of this property */

    if (h_version <= V3)
	value >>= 5;
    else if (!(value & 0x80))
	value >>= 6;
    else {

	LOW_BYTE (prop_addr, value)
	value &= 0x3f;

	if (value == 0) value = 64;	/* demanded by Spec 1.0 */

    }

    /* Add property length to current property pointer */

    return prop_addr + value + 1;

}/* next_property */

/*
 * unlink_object
 *
 * Unlink an object from its parent and siblings.
 *
 */

static void unlink_object (zword object)
{
    zword obj_addr;
    zword parent_addr;
    zword sibling_addr;

    obj_addr = object_address (object);

    if (h_version <= V3) {

	zbyte parent;
	zbyte younger_sibling;
	zbyte older_sibling;
	zbyte zero = 0;

	/* Get parent of object, and return if no parent */

	obj_addr += O1_PARENT;
	LOW_BYTE (obj_addr, parent)
	if (!parent)
	    return;

	/* Get (older) sibling of object and set both parent and sibling
	   pointers to 0 */

	SET_BYTE (obj_addr, zero)
	obj_addr += O1_SIBLING - O1_PARENT;
	LOW_BYTE (obj_addr, older_sibling)
	SET_BYTE (obj_addr, zero)

	/* Get first child of parent (the youngest sibling of the object) */

	parent_addr = object_address (parent) + O1_CHILD;
	LOW_BYTE (parent_addr, younger_sibling)

	/* Remove object from the list of siblings */

	if (younger_sibling == object)
	    SET_BYTE (parent_addr, older_sibling)
	else {
	    do {
		sibling_addr = object_address (younger_sibling) + O1_SIBLING;
		LOW_BYTE (sibling_addr, younger_sibling)
	    } while (younger_sibling != object);
	    SET_BYTE (sibling_addr, older_sibling)
	}

    } else {

	zword parent;
	zword younger_sibling;
	zword older_sibling;
	zword zero = 0;

	/* Get parent of object, and return if no parent */

	obj_addr += O4_PARENT;
	LOW_WORD (obj_addr, parent)
	if (!parent)
	    return;

	/* Get (older) sibling of object and set both parent and sibling
	   pointers to 0 */

	SET_WORD (obj_addr, zero)
	obj_addr += O4_SIBLING - O4_PARENT;
	LOW_WORD (obj_addr, older_sibling)
	SET_WORD (obj_addr, zero)

	/* Get first child of parent (the youngest sibling of the object) */

	parent_addr = object_address (parent) + O4_CHILD;
	LOW_WORD (parent_addr, younger_sibling)

	/* Remove object from the list of siblings */

	if (younger_sibling == object)
	    SET_WORD (parent_addr, older_sibling)
	else {
	    do {
		sibling_addr = object_address (younger_sibling) + O4_SIBLING;
		LOW_WORD (sibling_addr, younger_sibling)
	    } while (younger_sibling != object);
	    SET_WORD (sibling_addr, older_sibling)
	}

    }

}/* unlink_object */

/*
 * z_clear_attr, clear an object attribute.
 *
 *	zargs[0] = object
 *	zargs[1] = number of attribute to be cleared
 *
 */

void z_clear_attr (void)
{
    zword obj_addr;
    zbyte value;

    if (story_id == SHERLOCK)
	if (zargs[1] == 48)
	    return;

    if (zargs[1] > ((h_version <= V3) ? 31 : 47))
	runtime_error ("Illegal attribute");

    /* If we are monitoring attribute assignment display a short note */

    if (option_attribute_assignment) {
	stream_mssg_on ();
	print_string ("@clear_attr ");
	print_object (zargs[0]);
	print_string (" ");
	print_num (zargs[1]);
	stream_mssg_off ();
    }

    /* Get attribute address */

    obj_addr = object_address (zargs[0]) + zargs[1] / 8;

    /* Clear attribute bit */

    LOW_BYTE (obj_addr, value)
    value &= ~(0x80 >> (zargs[1] & 7));
    SET_BYTE (obj_addr, value)

}/* z_clear_attr */

/*
 * z_jin, branch if the first object is inside the second.
 *
 *	zargs[0] = first object
 *	zargs[1] = second object
 *
 */

void z_jin (void)
{
    zword obj_addr;

    /* If we are monitoring object locating display a short note */

    if (option_object_locating) {
	stream_mssg_on ();
	print_string ("@jin ");
	print_object (zargs[0]);
	print_string (" ");
	print_object (zargs[1]);
	stream_mssg_off ();
    }

    obj_addr = object_address (zargs[0]);

    if (h_version <= V3) {

	zbyte parent;

	/* Get parent id from object */

	obj_addr += O1_PARENT;
	LOW_BYTE (obj_addr, parent)

	/* Branch if the parent is obj2 */

	branch (parent == zargs[1]);

    } else {

	zword parent;

	/* Get parent id from object */

	obj_addr += O4_PARENT;
	LOW_WORD (obj_addr, parent)

	/* Branch if the parent is obj2 */

	branch (parent == zargs[1]);

    }

}/* z_jin */

/*
 * z_get_child, store the child of an object.
 *
 *	zargs[0] = object
 *
 */

void z_get_child (void)
{
    zword obj_addr;

    /* If we are monitoring object locating display a short note */

    if (option_object_locating) {
	stream_mssg_on ();
	print_string ("@get_child ");
	print_object (zargs[0]);
	stream_mssg_off ();
    }

    obj_addr = object_address (zargs[0]);

    if (h_version <= V3) {

	zbyte child;

	/* Get child id from object */

	obj_addr += O1_CHILD;
	LOW_BYTE (obj_addr, child)

	/* Store child id and branch */

	store (child);
	branch (child);

    } else {

	zword child;

	/* Get child id from object */

	obj_addr += O4_CHILD;
	LOW_WORD (obj_addr, child)

	/* Store child id and branch */

	store (child);
	branch (child);

    }

}/* z_get_child */

/*
 * z_get_next_prop, store the number of the first or next property.
 *
 *	zargs[0] = object
 *	zargs[1] = address of current property (0 gets the first property)
 *
 */

void z_get_next_prop (void)
{
    zword prop_addr;
    zbyte value;
    zbyte mask;

    /* Property id is in bottom five (six) bits */

    mask = (h_version <= V3) ? 0x1f : 0x3f;

    /* Load address of first property */

    prop_addr = first_property (zargs[0]);

    if (zargs[1] != 0) {

	/* Scan down the property list */

	do {
	    LOW_BYTE (prop_addr, value)
	    prop_addr = next_property (prop_addr);
	} while ((value & mask) > zargs[1]);

	/* Exit if the property does not exist */

	if ((value & mask) != zargs[1])
	    runtime_error ("No such property");

    }

    /* Return the property id */

    LOW_BYTE (prop_addr, value)
    store ((zword) (value & mask));

}/* z_get_next_prop */

/*
 * z_get_parent, store the parent of an object.
 *
 *	zargs[0] = object
 *
 */

void z_get_parent (void)
{
    zword obj_addr;

    /* If we are monitoring object locating display a short note */

    if (option_object_locating) {
	stream_mssg_on ();
	print_string ("@get_parent ");
	print_object (zargs[0]);
	stream_mssg_off ();
    }

    obj_addr = object_address (zargs[0]);

    if (h_version <= V3) {

	zbyte parent;

	/* Get parent id from object */

	obj_addr += O1_PARENT;
	LOW_BYTE (obj_addr, parent)

	/* Store parent */

	store (parent);

    } else {

	zword parent;

	/* Get parent id from object */

	obj_addr += O4_PARENT;
	LOW_WORD (obj_addr, parent)

	/* Store parent */

	store (parent);

    }

}/* z_get_parent */

/*
 * z_get_prop, store the value of an object property.
 *
 *	zargs[0] = object
 *	zargs[1] = number of property to be examined
 *
 */

void z_get_prop (void)
{
    zword prop_addr;
    zword wprop_val;
    zbyte bprop_val;
    zbyte value;
    zbyte mask;

    /* Property id is in bottom five (six) bits */

    mask = (h_version <= V3) ? 0x1f : 0x3f;

    /* Load address of first property */

    prop_addr = first_property (zargs[0]);

    /* Scan down the property list */

    for (;;) {
	LOW_BYTE (prop_addr, value)
	if ((value & mask) <= zargs[1])
	    break;
	prop_addr = next_property (prop_addr);
    }

    if ((value & mask) == zargs[1]) {	/* property found */

	/* Load property (byte or word sized) */

	prop_addr++;

	if (h_version <= V3 && !(value & 0xe0) || h_version >= V4 && !(value & 0xc0)) {

	    LOW_BYTE (prop_addr, bprop_val)
	    wprop_val = bprop_val;

	} else LOW_WORD (prop_addr, wprop_val)

    } else {	/* property not found */

	/* Load default value */

	prop_addr = h_objects + 2 * (zargs[1] - 1);
	LOW_WORD (prop_addr, wprop_val)

    }

    /* Store the property value */

    store (wprop_val);

}/* z_get_prop */

/*
 * z_get_prop_addr, store the address of an object property.
 *
 *	zargs[0] = object
 *	zargs[1] = number of property to be examined
 *
 */

void z_get_prop_addr (void)
{
    zword prop_addr;
    zbyte value;
    zbyte mask;

    if (story_id == BEYOND_ZORK)
	if (zargs[0] > MAX_OBJECT)
	    { store (0); return; }

    /* Property id is in bottom five (six) bits */

    mask = (h_version <= V3) ? 0x1f : 0x3f;

    /* Load address of first property */

    prop_addr = first_property (zargs[0]);

    /* Scan down the property list */

    for (;;) {
	LOW_BYTE (prop_addr, value)
	if ((value & mask) <= zargs[1])
	    break;
	prop_addr = next_property (prop_addr);
    }

    /* Calculate the property address or return zero */

    if ((value & mask) == zargs[1]) {

	if (h_version >= V4 && (value & 0x80))
	    prop_addr++;
	store ((zword) (prop_addr + 1));

    } else store (0);

}/* z_get_prop_addr */

/*
 * z_get_prop_len, store the length of an object property.
 *
 * 	zargs[0] = address of property to be examined
 *
 */

void z_get_prop_len (void)
{
    zword addr;
    zbyte value;

    /* Back up the property pointer to the property id */

    addr = zargs[0] - 1;
    LOW_BYTE (addr, value)

    /* Calculate length of property */

    if (h_version <= V3)
	value = (value >> 5) + 1;
    else if (!(value & 0x80))
	value = (value >> 6) + 1;
    else {

	value &= 0x3f;

	if (value == 0) value = 64;	/* demanded by Spec 1.0 */

    }

    /* Store length of property */

    store (value);

}/* z_get_prop_len */

/*
 * z_get_sibling, store the sibling of an object.
 *
 *	zargs[0] = object
 *
 */

void z_get_sibling (void)
{
    zword obj_addr;

    obj_addr = object_address (zargs[0]);

    if (h_version <= V3) {

	zbyte sibling;

	/* Get sibling id from object */

	obj_addr += O1_SIBLING;
	LOW_BYTE (obj_addr, sibling)

	/* Store sibling and branch */

	store (sibling);
	branch (sibling);

    } else {

	zword sibling;

	/* Get sibling id from object */

	obj_addr += O4_SIBLING;
	LOW_WORD (obj_addr, sibling)

	/* Store sibling and branch */

	store (sibling);
	branch (sibling);

    }

}/* z_get_sibling */

/*
 * z_insert_obj, make an object the first child of another object.
 *
 *	zargs[0] = object to be moved
 *	zargs[1] = destination object
 *
 */

void z_insert_obj (void)
{
    zword obj1 = zargs[0];
    zword obj2 = zargs[1];
    zword obj1_addr;
    zword obj2_addr;

    /* If we are monitoring object movements display a short note */

    if (option_object_movement) {
	stream_mssg_on ();
	print_string ("@move_obj ");
	print_object (obj1);
	print_string (" ");
	print_object (obj2);
	stream_mssg_off ();
    }

    /* Get addresses of both objects */

    obj1_addr = object_address (obj1);
    obj2_addr = object_address (obj2);

    /* Remove object 1 from current parent */

    unlink_object (obj1);

    /* Make object 1 first child of object 2 */

    if (h_version <= V3) {

	zbyte child;

	obj1_addr += O1_PARENT;
	SET_BYTE (obj1_addr, obj2)
	obj2_addr += O1_CHILD;
	LOW_BYTE (obj2_addr, child)
	SET_BYTE (obj2_addr, obj1)
	obj1_addr += O1_SIBLING - O1_PARENT;
	SET_BYTE (obj1_addr, child)

    } else {

	zword child;

	obj1_addr += O4_PARENT;
	SET_WORD (obj1_addr, obj2)
	obj2_addr += O4_CHILD;
	LOW_WORD (obj2_addr, child)
	SET_WORD (obj2_addr, obj1)
	obj1_addr += O4_SIBLING - O4_PARENT;
	SET_WORD (obj1_addr, child)

    }

}/* z_insert_obj */

/*
 * z_put_prop, set the value of an object property.
 *
 *	zargs[0] = object
 *	zargs[1] = number of property to set
 *	zargs[2] = value to set property to
 *
 */

void z_put_prop (void)
{
    zword prop_addr;
    zword value;
    zbyte mask;

    /* Property id is in bottom five or six bits */

    mask = (h_version <= V3) ? 0x1f : 0x3f;

    /* Load address of first property */

    prop_addr = first_property (zargs[0]);

    /* Scan down the property list */

    for (;;) {
	LOW_BYTE (prop_addr, value)
	if ((value & mask) <= zargs[1])
	    break;
	prop_addr = next_property (prop_addr);
    }

    /* Exit if the property does not exist */

    if ((value & mask) != zargs[1])
	runtime_error ("No such property");

    /* Store the new property value (byte or word sized) */

    prop_addr++;

    if (h_version <= V3 && !(value & 0xe0) || h_version >= V4 && !(value & 0xc0)) {
	zbyte v = zargs[2];
	SET_BYTE (prop_addr, v)
    } else {
	zword v = zargs[2];
	SET_WORD (prop_addr, v)
    }

}/* z_put_prop */

/*
 * z_remove_obj, unlink an object from its parent and siblings.
 *
 *	zargs[0] = object
 *
 */

void z_remove_obj (void)
{

    /* If we are monitoring object movements display a short note */

    if (option_object_movement) {
	stream_mssg_on ();
	print_string ("@remove_obj ");
	print_object (zargs[0]);
	stream_mssg_off ();
    }

    /* Call unlink_object to do the job */

    unlink_object (zargs[0]);

}/* z_remove_obj */

/*
 * z_set_attr, set an object attribute.
 *
 *	zargs[0] = object
 *	zargs[1] = number of attribute to set
 *
 */

void z_set_attr (void)
{
    zword obj_addr;
    zbyte value;

    if (story_id == SHERLOCK)
	if (zargs[1] == 48)
	    return;

    if (zargs[1] > ((h_version <= V3) ? 31 : 47))
	runtime_error ("Illegal attribute");

    /* If we are monitoring attribute assignment display a short note */

    if (option_attribute_assignment) {
	stream_mssg_on ();
	print_string ("@set_attr ");
	print_object (zargs[0]);
	print_string (" ");
	print_num (zargs[1]);
	stream_mssg_off ();
    }

    /* Get attribute address */

    obj_addr = object_address (zargs[0]) + zargs[1] / 8;

    /* Load attribute byte */

    LOW_BYTE (obj_addr, value)

    /* Set attribute bit */

    value |= 0x80 >> (zargs[1] & 7);

    /* Store attribute byte */

    SET_BYTE (obj_addr, value)

}/* z_set_attr */

/*
 * z_test_attr, branch if an object attribute is set.
 *
 *	zargs[0] = object
 *	zargs[1] = number of attribute to test
 *
 */

void z_test_attr (void)
{
    zword obj_addr;
    zbyte value;

    if (zargs[1] > ((h_version <= V3) ? 31 : 47))
	runtime_error ("Illegal attribute");

    /* If we are monitoring attribute testing display a short note */

    if (option_attribute_testing) {
	stream_mssg_on ();
	print_string ("@test_attr ");
	print_object (zargs[0]);
	print_string (" ");
	print_num (zargs[1]);
	stream_mssg_off ();
    }

    /* Get attribute address */

    obj_addr = object_address (zargs[0]) + zargs[1] / 8;

    /* Load attribute byte */

    LOW_BYTE (obj_addr, value)

    /* Test attribute */

    branch (value & (0x80 >> (zargs[1] & 7)));

}/* z_test_attr */
