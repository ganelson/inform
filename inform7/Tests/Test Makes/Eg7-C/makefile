# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg7

Eg7: Eg7-C.o Eg7-I.o
	$(LINK) -o Eg7 Eg7-C.o Eg7-I.o

Eg7-C.o: Eg7.c Eg7-I.c
	$(CC) -o Eg7-C.o Eg7.c

Eg7-I.o: Eg7-I.c
	$(CC) -o Eg7-I.o Eg7-I.c

Eg7-I.c: Eg7.i7
	$(INFORM) -format=C/no-main/symbols-header -o Eg7-I.c Eg7.i7

.PHONY: run
run: Eg7
	./Eg7

.PHONY: clean
clean:
	rm -f Eg7-I.c
	rm -f *.o
	rm -f Eg7
	rm -f inform7_symbols.h
	rm -f actual_output.txt
	rm -f build_log.txt
