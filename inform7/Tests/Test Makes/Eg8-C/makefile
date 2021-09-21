# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg8

Eg8: Eg8-C.o Eg8-I.o
	$(LINK) -o Eg8 Eg8-C.o Eg8-I.o

Eg8-C.o: Eg8.c Eg8-I.c
	$(CC) -o Eg8-C.o Eg8.c

Eg8-I.o: Eg8-I.c
	$(CC) -o Eg8-I.o Eg8-I.c

Eg8-I.c: Eg8.i7
	$(INFORM) -basic -format=C/no-main/symbols-header -o Eg8-I.c Eg8.i7

.PHONY: run
run: Eg8
	./Eg8

.PHONY: clean
clean:
	rm -f Eg8-I.c
	rm -f *.o
	rm -f Eg8
	rm -f inform7_symbols.h
	rm -f build_log.txt
	rm -f actual_output.txt
