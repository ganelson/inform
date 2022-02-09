[Inode::] Inter Nodes.

To create nodes of inter code, and manage everything about them except their
tree locations.

@h Nodes.
It's essential to be able to walk an Inter tree quickly, while movements
of nodes within the tree are relatively uncommon. So we provide every
imaginatble link. Suppose the structure is:
= (text)
	A
		B
		C
			D
		E
=
Then the links are:
= (text)
              of |	A		B		C		D		E
	-------------+--------------------------------------
	parent		 |	NULL	A		A		C		A
	first_child	 |	B		NULL	D		NULL	NULL
	last_child   |  E		NULL	D		NULL	NULL
	previous     |  NULL	NULL	B		NULL	C
	next         |  NULL	C		E		NULL	NULL
=
Each node also knows the tree and the package it belongs to. We really aren't
concerned about memory consumption here. The Inter trees we deal with will be
large (typically 400,000 nodes), so on a 64-bit processor we might be looking
at 250 MB of memory here, and that can probably be doubled when the warehouse
memory consumption is also considered. But this is no longer prohibitive: speed
of access matters more.

=
typedef struct inter_tree_node {
	struct inter_tree *tree;
	struct inter_package *package;
	struct inter_tree_node *parent_itn;
	struct inter_tree_node *first_child_itn;
	struct inter_tree_node *last_child_itn;
	struct inter_tree_node *previous_itn;
	struct inter_tree_node *next_itn;
	struct warehouse_floor_space W;
} inter_tree_node;

@ Do not call this directly in order to create a node.

=
inter_tree_node *Inode::new_node(inter_warehouse *warehouse, inter_tree *I,
	int n, inter_error_location *eloc, inter_package *owner) {
	if (warehouse == NULL) internal_error("no warehouse");
	if (I == NULL) internal_error("no tree supplied");
	warehouse_floor_space W = InterWarehouse::make_floor_space(warehouse, n);
	inter_tree_node *itn = CREATE(inter_tree_node);
	itn->tree = I;
	itn->package = owner;
	itn->parent_itn = NULL;
	itn->first_child_itn = NULL;
	itn->last_child_itn = NULL;
	itn->previous_itn = NULL;
	itn->next_itn = NULL;
	itn->W = W;
	if (eloc) Inode::attach_error_location(itn, eloc);
	return itn;
}

@ Instead, call one of the following. This of course should be called once
only per tree, and is called by //InterTree::new// anyway.

The root node is meaningless, but in order that all nodes correspond to
instructions, we make it a |NOP_IST|. This is not really part of the program,
though.

=
inter_tree_node *Inode::new_root_node(inter_warehouse *warehouse, inter_tree *I) {
	inter_tree_node *P = Inode::new_node(warehouse, I, 2, NULL, NULL);
	P->W.instruction[ID_IFLD] = (inter_ti) NOP_IST;
	P->W.instruction[LEVEL_IFLD] = 0;
	return P;
}

@ More generally: the content of a node is an instruction stored as bytecode
in memory. (Perhaps wordcode would be more accurate: it's a series of words.)
Words 0 and 1 have the same meaning for all instructions; everything from 2
onwards is data whose meaning differs between instructions. (Indeed, some
instructions have no data at all, and thus occupy only 2 words.)

The ID is an enumeration of |*_IST|: it marks which instruction this is.

The level is the depth of this node in the tree, where the root node is 0,
its children are level 1, their children level 2, and so on.

@d ID_IFLD 0
@d LEVEL_IFLD 1
@d DATA_IFLD 2

@ These functions should be called only by the creator functions for the
Inter instructions. Code which is generating Inter to do something should not
call those creator functions, not these.

=
inter_tree_node *Inode::new_with_0_data_fields(inter_bookmark *IBM, int S,
	inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 2,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	return P;
}

inter_tree_node *Inode::new_with_1_data_field(inter_bookmark *IBM, int S,
	inter_ti V, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 3,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V;
	return P;
}

inter_tree_node *Inode::new_with_2_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 4,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V1;
	P->W.instruction[DATA_IFLD + 1] = V2;
	return P;
}

inter_tree_node *Inode::new_with_3_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 5,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V1;
	P->W.instruction[DATA_IFLD + 1] = V2;
	P->W.instruction[DATA_IFLD + 2] = V3;
	return P;
}

inter_tree_node *Inode::new_with_4_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_error_location *eloc,
	inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 6,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V1;
	P->W.instruction[DATA_IFLD + 1] = V2;
	P->W.instruction[DATA_IFLD + 2] = V3;
	P->W.instruction[DATA_IFLD + 3] = V4;
	return P;
}

inter_tree_node *Inode::new_with_5_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5,
	inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 7,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V1;
	P->W.instruction[DATA_IFLD + 1] = V2;
	P->W.instruction[DATA_IFLD + 2] = V3;
	P->W.instruction[DATA_IFLD + 3] = V4;
	P->W.instruction[DATA_IFLD + 4] = V5;
	return P;
}

inter_tree_node *Inode::new_with_6_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6,
	inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 8,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V1;
	P->W.instruction[DATA_IFLD + 1] = V2;
	P->W.instruction[DATA_IFLD + 2] = V3;
	P->W.instruction[DATA_IFLD + 3] = V4;
	P->W.instruction[DATA_IFLD + 4] = V5;
	P->W.instruction[DATA_IFLD + 5] = V6;
	return P;
}

inter_tree_node *Inode::new_with_7_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6,
	inter_ti V7, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 9,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V1;
	P->W.instruction[DATA_IFLD + 1] = V2;
	P->W.instruction[DATA_IFLD + 2] = V3;
	P->W.instruction[DATA_IFLD + 3] = V4;
	P->W.instruction[DATA_IFLD + 4] = V5;
	P->W.instruction[DATA_IFLD + 5] = V6;
	P->W.instruction[DATA_IFLD + 6] = V7;
	return P;
}

inter_tree_node *Inode::new_with_8_data_fields(inter_bookmark *IBM, int S,
	inter_ti V1, inter_ti V2, inter_ti V3, inter_ti V4, inter_ti V5, inter_ti V6,
		inter_ti V7, inter_ti V8, inter_error_location *eloc, inter_ti level) {
	inter_tree *I = InterBookmark::tree(IBM);
	inter_tree_node *P = Inode::new_node(InterTree::warehouse(I), I, 10,
		eloc, InterBookmark::package(IBM));
	P->W.instruction[ID_IFLD] = (inter_ti) S;
	P->W.instruction[LEVEL_IFLD] = level;
	P->W.instruction[DATA_IFLD] = V1;
	P->W.instruction[DATA_IFLD + 1] = V2;
	P->W.instruction[DATA_IFLD + 2] = V3;
	P->W.instruction[DATA_IFLD + 3] = V4;
	P->W.instruction[DATA_IFLD + 4] = V5;
	P->W.instruction[DATA_IFLD + 5] = V6;
	P->W.instruction[DATA_IFLD + 6] = V7;
	P->W.instruction[DATA_IFLD + 7] = V8;
	return P;
}

@h The package and tree of a node.

=
inter_package *Inode::get_package(inter_tree_node *F) {
	if (F) return F->package;
	return NULL;
}

inter_tree *Inode::tree(inter_tree_node *F) {
	if (F) return F->tree;
	return NULL;
}

inter_symbols_table *Inode::globals(inter_tree_node *F) {
	if (F) return InterTree::global_scope(Inode::tree(F));
	return NULL;
}

inter_warehouse *Inode::warehouse(inter_tree_node *F) {
	if (F == NULL) return NULL;
	return F->W.in_room->owning_warehouse;
}

@h Bytecode storage.
Each node represents one instruction, which is encoded with a contiguous
block of bytecode. That bytecode is not stored in the //inter_tree_node//
structure, but in warehouse memory. 
= (text)
......+------+----------+--------+----+-------+-------------+........
      | Skip | Verified | Origin | ID | Level | Data        |
......+------+----------+--------+----+-------+-------------+........
       <------------------------> <------------------------>
        Preframe                             Frame
=
This stretch of memory is divided into a "preframe" and a "frame": the frame
holds the words of data described above, with position 0 being the ID, and
so on. The frame is of variable size, depending on the instruction (and in
some cases its particular content: a constant definition for a list can be
almost any length). But the preframe is of fixed size:

@d PREFRAME_SIZE 3

@d PREFRAME_SKIP_AMOUNT 0
@d PREFRAME_VERIFICATION_COUNT 1
@d PREFRAME_ORIGIN 2

@ |PREFRAME_SKIP_AMOUNT| is the offset (in words) to the next instruction.
Since the preframe has fixed length, this is both the offset from one preframe
to the next and also from one frame to the next.

@ |PREFRAME_VERIFICATION_COUNT| is the number of times the instruction has
been "verified". This is not always a passive process of checking, which is why
we need to track whether it has happened. See //Inter Constructs//.

This function effectively performs |v++|, where |v| is the count.

=
inter_ti Inode::bump_verification_count(inter_tree_node *F) {
	inter_ti v = Inode::get_preframe(F, PREFRAME_VERIFICATION_COUNT);
	Inode::set_preframe(F, PREFRAME_VERIFICATION_COUNT, v + 1);
	return v;
}

@ |PREFRAME_ORIGIN| allows the origin of the instruction, in source code,
to be preserved: for example, to show that this came from line 14 of a file
called |whatever.intert|. It is 0 if no origin is recorded; it is used only
for better reporting of any errors which arise. For how the location is
actually encoded in the word, see //The Warehouse//.

=
inter_error_location *Inode::get_error_location(inter_tree_node *F) {
	if (F == NULL) return NULL;
	inter_ti L = Inode::get_preframe(F, PREFRAME_ORIGIN);
	return InterTree::origin_word_to_eloc(Inode::tree(F), L);
}

void Inode::attach_error_location(inter_tree_node *F, inter_error_location *eloc) {
	Inode::set_preframe(F, PREFRAME_ORIGIN,
		InterTree::eloc_to_origin_word(Inode::tree(F), eloc));
}

@ The following gets and sets from the preframe:

=
inter_ti Inode::get_preframe(inter_tree_node *F, int at) {
	if (F == NULL) return 0;
	return F->W.in_room->bytecode[F->W.index + at];
}

void Inode::set_preframe(inter_tree_node *F, int at, inter_ti V) {
	if (F) F->W.in_room->bytecode[F->W.index + at] = V;
}

@ As noted above, the size of the frame varies from instruction to instruction.
For most instructions, it's determined as soon as the inode is created -- for
example, a |PROPERTYVALUE_IST| is always of a fixed length, and it's created
already being that length, so that it doesn't need to be extended.

But just a few instructions are of variable length depending on what they are
doing -- |CONSTANT_IST|, for example. Those are created at their minimum
length and then extended as needed.

Note that |by| is unsigned, so cannot be negative: the bytecode can extend
but not contract.

All of this extension happens only during the process of creating the
instruction: once that's done, it never changes in length again. Because of
this, we can only build one instruction at a time.

Note that this function always succeeds, because an internal error is thrown
if the system is out of memory.

=
void Inode::extend_instruction_by(inter_tree_node *F, inter_ti by) {
	if (by > 0) F->W = InterWarehouse::enlarge_floor_space(F->W, by);
}

@ Every instruction has a level:

=
int Inode::get_level(inter_tree_node *P) {
	if (P == NULL) return 0;
	return (int) P->W.instruction[LEVEL_IFLD];
}

@h Interpreting values stored in bytecode.
The data stored in the fields above may represent strings, symbols and the like,
but it's just stored in what amounts to an array of unsigned integers: what is
stored is just an ID representing one of those things. The conversion from an ID
to the actual resource it represents depends on:

(a) What it is meant to be (symbols table, text, package, ...) -- there is no
indication in the bytecode as to which that is, so we need to know what we're
looking for, e.g. that what is in position 3 is a text;

(b) Which node the value came from -- because these depend on the warehouse
where data is stored (and some nodes are in different warehouses than others),
and sometimes also on the local symbols table (which depends on the package
we are in, which in turn depends on the node).

=
inter_symbols_table *Inode::ID_to_symbols_table(inter_tree_node *F, inter_ti ID) {
	return InterWarehouse::get_symbols_table(Inode::warehouse(F), ID);
}

text_stream *Inode::ID_to_text(inter_tree_node *F, inter_ti ID) {
	return InterWarehouse::get_text(Inode::warehouse(F), ID);
}

inter_package *Inode::ID_to_package(inter_tree_node *F, inter_ti ID) {
	if (ID == 0) return NULL;
	return InterWarehouse::get_package(Inode::warehouse(F), ID);
}

inter_node_list *Inode::ID_to_frame_list(inter_tree_node *F, inter_ti N) {
	return InterWarehouse::get_node_list(Inode::warehouse(F), N);
}

@h Errors.
Suppose we want to generate an error message for malformed Inter code, and
to identify it as occurring at a particular node. We can get one thus:

=
inter_error_message *Inode::error(inter_tree_node *F, text_stream *err, text_stream *quote) {
	inter_error_message *iem = CREATE(inter_error_message);
	inter_error_location *eloc = Inode::get_error_location(F);
	if (eloc)
		iem->error_at = *eloc;
	else
		iem->error_at = Inter::Errors::file_location(NULL, NULL);
	iem->error_body = err;
	iem->error_quote = quote;
	return iem;
}
