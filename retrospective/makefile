# This makefile was automatically written by inweb -makefile
# and is not intended for human editing

INTEST = intest/Tangled/intest
INWEB = inweb/Tangled/inweb

CC = clang -std=c99 -c $(MANYWARNINGS) $(CCOPTS) -g
INDULGENTCC = clang -std=c99 -c $(FEWERWARNINGS) $(CCOPTS) -g

CCOPTS = -mmacosx-version-min=10.4 -arch i386 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk

MANYWARNINGS = -Weverything -Wno-pointer-arith -Wno-unused-macros -Wno-shadow -Wno-cast-align -Wno-variadic-macros -Wno-missing-noreturn -Wno-missing-prototypes -Wno-unused-parameter -Wno-padded -Wno-missing-variable-declarations -Wno-unreachable-code-break -Wno-class-varargs -Wno-format-nonliteral -Wno-cast-qual -Wno-double-promotion -Wno-comma -Wno-strict-prototypes -ferror-limit=1000

FEWERWARNINGS = -Wno-implicit-int -Wno-dangling-else -Wno-pointer-sign -Wno-format-extra-args -Wno-tautological-compare -Wno-deprecated-declarations -Wno-logical-op-parentheses -Wno-format

LINK = clang $(CCOPTS) -g
LINKEROPTS = 

ARTOOL = libtool -o

INFORM6OS = OSX

GLULXEOS = OS_UNIX

.PHONY: all

all: 6L02/cBlorb 6L02/ni 6L30/cBlorb 6L30/ni 6M62/cBlorb 6M62/ni

6L02/cBlorb:
	$(INDULGENTCC) -o 6L02/cBlorb.o 6L02/cBlorb.c
	$(LINK) -o 6L02/cBlorb 6L02/cBlorb.o $(LINKEROPTS)

6L30/cBlorb:
	$(INDULGENTCC) -o 6L30/cBlorb.o 6L30/cBlorb.c
	$(LINK) -o 6L30/cBlorb 6L30/cBlorb.o $(LINKEROPTS)

6M62/cBlorb:
	$(INDULGENTCC) -o 6M62/cBlorb.o 6M62/cBlorb.c
	$(LINK) -o 6M62/cBlorb 6M62/cBlorb.o $(LINKEROPTS)

6L02/ni:
	$(INDULGENTCC) -o 6L02/ni.o 6L02/ni.c
	$(LINK) -o 6L02/ni 6L02/ni.o $(LINKEROPTS)

6L30/ni:
	$(INDULGENTCC) -o 6L30/ni.o 6L30/ni.c
	$(LINK) -o 6L30/ni 6L30/ni.o $(LINKEROPTS)

6M62/ni:
	$(INDULGENTCC) -o 6M62/ni.o 6M62/ni.c
	$(LINK) -o 6M62/ni 6M62/ni.o $(LINKEROPTS)

