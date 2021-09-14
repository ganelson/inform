# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg3

Eg3: Eg3-C.o Eg3-I.o
	$(LINK) -o Eg3 Eg3-C.o Eg3-I.o

Eg3-C.o: Eg3.c
	$(CC) -o Eg3-C.o Eg3.c

Eg3-I.o: Eg3-I.c
	$(CC) -o Eg3-I.o Eg3-I.c

Eg3-I.c: Eg3.i7
	$(INFORM) -basic -format=C/no-main -o Eg3-I.c Eg3.i7

.PHONY: run
run: Eg3
	./Eg3

.PHONY: clean
clean:
	rm -f Eg3-I.c
	rm -f *.o
	rm -f Eg3
	rm -f actual_output.txt
	rm -f build_log.txt
