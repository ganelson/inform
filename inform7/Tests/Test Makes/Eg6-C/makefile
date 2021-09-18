# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg6

Eg6: Eg6-C.o Eg6-I.o
	$(LINK) -o Eg6 Eg6-C.o Eg6-I.o

Eg6-C.o: Eg6.c Eg6-I.c
	$(CC) -o Eg6-C.o Eg6.c

Eg6-I.o: Eg6-I.c
	$(CC) -o Eg6-I.o Eg6-I.c

Eg6-I.c: Eg6.i7
	$(INFORM) -format=C/no-main/symbols-header -o Eg6-I.c Eg6.i7

.PHONY: run
run: Eg6
	./Eg6

.PHONY: clean
clean:
	rm -f Eg6-I.c
	rm -f *.o
	rm -f Eg6
	rm -f inform7_symbols.h
	rm -f actual_output.txt
	rm -f build_log.txt
