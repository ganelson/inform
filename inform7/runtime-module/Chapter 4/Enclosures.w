[Enclosures::] Enclosures.

Packages which contain all the resources any of their subpackages will need are
called "enclosures".

@ The idea of "enclosure" lets us create something "nearby". We are generally
creating bytecode at a particular position in the hierarchy -- say, in the
current function being compiled. We then want to create some associated local
resource, which can't be at that exact position, but which we want to keep
nearby. (For example, a constant list mentioned in the function will need an
associated array.)

The following creates a package in the enclosure surrounding the current
emission position:

=
inter_name *Enclosures::new_iname(int hap, int hl) {
	package_request *PR = HierarchyLocations::attach_new_package(
		Emit::tree(), NULL, Emit::current_enclosure(), hap);
	return Hierarchy::make_iname_in(hl, PR);
}

@ As noted above, literal values for constants which cannot be stored in a
single word are a case in point. In general, these are represented in memory
like so:
= (text)
	                    small block:
	  ----------------> data
	                    data
	                    ...
=
The size of the small block varies from kind to kind,[1] but for any given
kind this size is fixed. For example, a text has a small block of 2 words.

Often, but not always, the small block points to a larger and flexibly-sized
block of data elsewhere:
= (text)
	                    small block:              large block:
	  ----------------> metadata
	  					...
	  					pointer ----------------> block value header
	                    ...                       data
	                                              ...
=
The size of the large block, and the format of the small block and the "actual
data", vary from kind to kind.

[1] Properly speaking, from constructor to constructor. All lists have the
same size of small block.

=
inter_name *Enclosures::new_small_block_for_constant(void) {
	return Enclosures::new_iname(BLOCK_CONSTANTS_HAP, BLOCK_CONSTANT_HL);
}
