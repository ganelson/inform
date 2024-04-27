Version 1 of Memory Addresses by Graham Nelson begins here.

Section 1 - General Support

To decide which memory address is (N - number) byte/bytes:
	(- {N} -).

To decide which memory address is (N - number) in memory:
	(- {N} -).

To decide which memory address is the address of the serial code:
	(- (VM_SerialNumber()) -).

To say dump of (N - number) bytes at (address - memory address):
	(-	MEMORY_ADDRESS_TY_SAY({address});
		print ": ";
		MEMORY_ADDRESS_TY_ShowBytes({address}, {N});
	-);

Section 2 - Dump Command (not for release)

Dumping memory at is an action out of world applying to one memory address.

Carry out dumping memory at:
	say dump of 32 bytes at the memory address understood;
	say line break.

Understand "dump [memory address]" as dumping memory at.

Memory Addresses ends here.
