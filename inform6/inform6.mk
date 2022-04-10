# This makefile was automatically written by inweb -makefile
# and is not intended for human editing

INTEST = intest/Tangled/intest
INWEB = inweb/Tangled/inweb

CC = clang -std=c99 -c $(MANYWARNINGS) $(CCOPTS) -g 
INDULGENTCC = clang -std=c99 -c $(FEWERWARNINGS) $(CCOPTS) -g

CCOPTS = -DPLATFORM_MACOS=1 -mmacosx-version-min=10.6 -arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

MANYWARNINGS = -Weverything -Wno-pointer-arith -Wno-unused-macros -Wno-shadow -Wno-cast-align -Wno-variadic-macros -Wno-missing-noreturn -Wno-missing-prototypes -Wno-unused-parameter -Wno-padded -Wno-missing-variable-declarations -Wno-unreachable-code-break -Wno-class-varargs -Wno-format-nonliteral -Wno-cast-qual -Wno-double-promotion -Wno-comma -Wno-strict-prototypes -Wno-extra-semi-stmt -Wno-c11-extensions -Wno-unreachable-code-return -ferror-limit=1000

FEWERWARNINGS = -Wno-implicit-int -Wno-dangling-else -Wno-pointer-sign -Wno-format-extra-args -Wno-tautological-compare -Wno-deprecated-declarations -Wno-logical-op-parentheses -Wno-format -Wno-extra-semi-stmt -Wno-c11-extensions -Wno-unreachable-code-return

LINK = clang $(CCOPTS) -g
LINKEROPTS = 

EXEEXTENSION = 

ARTOOL = libtool -o

INFORM6OS = MACOS

GLULXEOS = OS_UNIX

ME = inform6
INTEST = ../intest/Tangled/intest
SANDBOX = $(ME)/Inform6
INTERPRETERS = $(ME)/Tests/Assistants

I6SOURCE = \
	$(SANDBOX)/arrays.o $(SANDBOX)/asm.o $(SANDBOX)/bpatch.o $(SANDBOX)/chars.o \
	$(SANDBOX)/directs.o $(SANDBOX)/errors.o $(SANDBOX)/expressc.o $(SANDBOX)/expressp.o \
	$(SANDBOX)/files.o $(SANDBOX)/inform.o $(SANDBOX)/lexer.o $(SANDBOX)/linker.o \
	$(SANDBOX)/memory.o $(SANDBOX)/objects.o $(SANDBOX)/states.o $(SANDBOX)/symbols.o \
	$(SANDBOX)/syntax.o $(SANDBOX)/tables.o $(SANDBOX)/text.o $(SANDBOX)/veneer.o \
	$(SANDBOX)/verbs.o

$(ME)/Tangled/$(ME): $(SANDBOX)/*.c $(SANDBOX)/*.h
	$(call make-me)

.PHONY: force
force:
	$(call make-me)

define make-me
	cd $(SANDBOX); $(INDULGENTCC) -std=c99 *.c -D$(INFORM6OS)
	$(LINK) -o $(ME)/Tangled/$(ME)$(EXEEXTENSION) $(I6SOURCE) $(LINKEROPTS)
endef

.PHONY: test
test: $(INTERPRETERS)/dumb-frotz/dumb-frotz $(INTERPRETERS)/dumb-glulx/glulxe/glulxe 
	$(INTEST) -from $(ME) all

.PHONY: interpreters
interpreters: $(INTERPRETERS)/dumb-frotz/dumb-frotz $(INTERPRETERS)/dumb-glulx/glulxe/glulxe 

GLKLIB = libcheapglk.a
GLKINCLUDEDIR = ../cheapglk
GLKLIBDIR = ../cheapglk
GLKMAKEFILE = Make.cheapglk

CHEAPGLK_OBJS =  \
  cgfref.o cggestal.o cgmisc.o cgstream.o cgstyle.o cgwindow.o cgschan.o \
  cgunicod.o main.o gi_dispa.o gi_blorb.o cgblorb.o

GLULXE_OBJS = main.o files.o vm.o exec.o float.o funcs.o operand.o string.o glkop.o \
	heap.o serial.o search.o gestalt.o osdepend.o unixstrt.o accel.o profile.o

CHEAPGLK_HEADERS = cheapglk.h gi_dispa.h

$(INTERPRETERS)/dumb-frotz/dumb-frotz: \
	$(INTERPRETERS)/dumb-frotz/*.c \
	$(INTERPRETERS)/dumb-frotz/*.h
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) buffer.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) dumb-init.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) dumb-input.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) dumb-output.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) dumb-pic.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) fastmem.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) files.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) hotkey.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) input.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) math.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) object.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) process.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) random.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) redirect.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) screen.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) sound.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) stream.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) table.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) text.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) variable.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) profiling.c
	cd $(INTERPRETERS)/dumb-frotz; $(INDULGENTCC) main.c
	cd $(INTERPRETERS)/dumb-frotz; $(LINK) -o dumb-frotz$(EXEEXTENSION) *.o $(LINKEROPTS)

$(INTERPRETERS)/dumb-glulx/glulxe/glulxe: \
	$(INTERPRETERS)/dumb-glulx/cheapglk/*.c \
	$(INTERPRETERS)/dumb-glulx/cheapglk/*.h \
	$(INTERPRETERS)/dumb-glulx/glulxe/*.c \
	$(INTERPRETERS)/dumb-glulx/glulxe/*.h
	cd $(INTERPRETERS)/dumb-glulx/cheapglk; make
	cd $(INTERPRETERS)/dumb-glulx/glulxe; make

.PHONY: clean
clean:
	$(call clean-up)

.PHONY: purge
purge:
	$(call clean-up)
	rm -f $(ME)/Tangled/$(ME)
	rm -f $(INTERPRETERS)/dumb-frotz/dumb-frotz
	rm -f $(INTERPRETERS)/dumb-glulx/glulxe/glulxe

define clean-up
	rm -f $(SANDBOX)/*.o
	rm -f $(INTERPRETERS)/dumb-frotz/*.o
	rm -f $(INTERPRETERS)/dumb-glulx/glulxe/*.o
	rm -f $(INTERPRETERS)/dumb-glulx/cheapglk/*.o
endef

