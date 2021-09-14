# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg2

Eg2: Eg2-C.o Eg2-I.o
	$(LINK) -o Eg2 Eg2-C.o Eg2-I.o

Eg2-C.o: Eg2.c
	$(CC) -o Eg2-C.o Eg2.c

Eg2-I.o: Eg2-I.c
	$(CC) -o Eg2-I.o Eg2-I.c

Eg2-I.c: Eg2.i7
	$(INFORM) -basic -format=C/no-main -o Eg2-I.c Eg2.i7

.PHONY: run
run: Eg2
	./Eg2

.PHONY: clean
clean:
	rm -f Eg2-I.c
	rm -f *.o
	rm -f Eg2
	rm -f actual_output.txt
	rm -f build_log.txt
