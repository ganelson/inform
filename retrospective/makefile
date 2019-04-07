# This makefile was automatically written by inweb -makefile
# and is not intended for human editing

INTEST = intest/Tangled/intest
INWEB = inweb/Tangled/inweb

CC = clang -std=c99 -c $(MANYWARNINGS) $(CCOPTS) -g 
INDULGENTCC = clang -std=c99 -c $(FEWERWARNINGS) $(CCOPTS) -g

CCOPTS = -DPLATFORM_MACOS=1 -mmacosx-version-min=10.6 -arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

MANYWARNINGS = -Weverything -Wno-pointer-arith -Wno-unused-macros -Wno-shadow -Wno-cast-align -Wno-variadic-macros -Wno-missing-noreturn -Wno-missing-prototypes -Wno-unused-parameter -Wno-padded -Wno-missing-variable-declarations -Wno-unreachable-code-break -Wno-class-varargs -Wno-format-nonliteral -Wno-cast-qual -Wno-double-promotion -Wno-comma -Wno-strict-prototypes -ferror-limit=1000

FEWERWARNINGS = -Wno-implicit-int -Wno-dangling-else -Wno-pointer-sign -Wno-format-extra-args -Wno-tautological-compare -Wno-deprecated-declarations -Wno-logical-op-parentheses -Wno-format

LINK = clang $(CCOPTS) -g
LINKEROPTS = 

ARTOOL = libtool -o

INFORM6OS = OSX

GLULXEOS = OS_UNIX

.PHONY: all

all: retrospective/6L02/cBlorb retrospective/6L02/ni retrospective/6L30/cBlorb retrospective/6L30/ni retrospective/6M62/cBlorb retrospective/6M62/ni

retrospective/6L02/cBlorb:
	$(INDULGENTCC) -o retrospective/6L02/cBlorb.o retrospective/6L02/cBlorb.c
	$(LINK) -o retrospective/6L02/cBlorb retrospective/6L02/cBlorb.o $(LINKEROPTS)

retrospective/6L30/cBlorb:
	$(INDULGENTCC) -o retrospective/6L30/cBlorb.o retrospective/6L30/cBlorb.c
	$(LINK) -o retrospective/6L30/cBlorb retrospective/6L30/cBlorb.o $(LINKEROPTS)

retrospective/6M62/cBlorb:
	$(INDULGENTCC) -o retrospective/6M62/cBlorb.o retrospective/6M62/cBlorb.c
	$(LINK) -o retrospective/6M62/cBlorb retrospective/6M62/cBlorb.o $(LINKEROPTS)

retrospective/6L02/ni:
	$(INDULGENTCC) -o retrospective/6L02/ni.o retrospective/6L02/ni.c
	$(LINK) -o retrospective/6L02/ni retrospective/6L02/ni.o $(LINKEROPTS)

retrospective/6L30/ni:
	$(INDULGENTCC) -o retrospective/6L30/ni.o retrospective/6L30/ni.c
	$(LINK) -o retrospective/6L30/ni retrospective/6L30/ni.o $(LINKEROPTS)

retrospective/6M62/ni:
	$(INDULGENTCC) -o retrospective/6M62/ni.o retrospective/6M62/ni.c
	$(LINK) -o retrospective/6M62/ni retrospective/6M62/ni.o $(LINKEROPTS)

