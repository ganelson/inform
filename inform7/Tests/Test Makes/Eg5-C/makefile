# Where inform7 is installed, relative to this directory

INST = ../../..

# Abbreviations for running C compiler, linker, and inform7 tools

CC = clang -g -std=c99 -c -I $(INST)/Internal/Miscellany
LINK = clang -g
INFORM = $(INST)/Tangled/inform7 -silence

# There is one build target: an executable.

.PHONY: all
all: Eg5

Eg5: Eg5-C.o Eg5-I.o
	$(LINK) -o Eg5 Eg5-C.o Eg5-I.o

Eg5-C.o: Eg5.c
	$(CC) -o Eg5-C.o Eg5.c

Eg5-I.o: Eg5-I.c
	$(CC) -o Eg5-I.o Eg5-I.c

Eg5-I.c: Eg5.i7
	$(INFORM) -format=C/no-main -o Eg5-I.c Eg5.i7

.PHONY: run
run: Eg5
	./Eg5

.PHONY: clean
clean:
	rm -f Eg5-I.c
	rm -f *.o
	rm -f Eg5
	rm -f actual_output.txt
	rm -f build_log.txt
