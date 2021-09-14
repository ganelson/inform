# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg1

Eg1: Eg1-I.o
	$(LINK) -o Eg1 Eg1-I.o

Eg1-I.o: Eg1-I.c
	$(CC) -o Eg1-I.o Eg1-I.c

Eg1-I.c: Eg1.i7
	$(INFORM) -basic -format=C -o Eg1-I.c Eg1.i7

.PHONY: run
run: Eg1
	./Eg1

.PHONY: clean
clean:
	rm -f Eg1-I.c
	rm -f *.o
	rm -f Eg1
	rm -f actual_output.txt
	rm -f build_log.txt
	