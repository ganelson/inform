# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg4

Eg4: Eg4-C.o Eg4-I.o
	$(LINK) -o Eg4 Eg4-C.o Eg4-I.o

Eg4-C.o: Eg4.c
	$(CC) -o Eg4-C.o Eg4.c

Eg4-I.o: Eg4-I.c
	$(CC) -o Eg4-I.o Eg4-I.c

Eg4-I.c: Eg4.i7
	$(INFORM) -basic -format=C/no-main -o Eg4-I.c Eg4.i7 -variable *tout=textual.txt

.PHONY: run
run: Eg4
	./Eg4

.PHONY: clean
clean:
	rm -f Eg4-I.c
	rm -f *.o
	rm -f Eg4
	rm -f actual_output.txt
	rm -f build_log.txt
