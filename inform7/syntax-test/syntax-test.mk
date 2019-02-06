# This makefile was automatically written by inweb -makefile
# and is not intended for human editing

INTEST = intest/Tangled/intest
INWEB = inweb/Tangled/inweb

CC = clang -std=c99 -c $(MANYWARNINGS) $(CCOPTS) -g 
INDULGENTCC = clang -std=c99 -c $(FEWERWARNINGS) $(CCOPTS) -g

CCOPTS = -DPLATFORM_MACOSX=1 -mmacosx-version-min=10.4 -arch i386 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk

MANYWARNINGS = -Weverything -Wno-pointer-arith -Wno-unused-macros -Wno-shadow -Wno-cast-align -Wno-variadic-macros -Wno-missing-noreturn -Wno-missing-prototypes -Wno-unused-parameter -Wno-padded -Wno-missing-variable-declarations -Wno-unreachable-code-break -Wno-class-varargs -Wno-format-nonliteral -Wno-cast-qual -Wno-double-promotion -Wno-comma -Wno-strict-prototypes -ferror-limit=1000

FEWERWARNINGS = -Wno-implicit-int -Wno-dangling-else -Wno-pointer-sign -Wno-format-extra-args -Wno-tautological-compare -Wno-deprecated-declarations -Wno-logical-op-parentheses -Wno-format

LINK = clang $(CCOPTS) -g
LINKEROPTS = 

ARTOOL = libtool -o

INFORM6OS = OSX

GLULXEOS = OS_UNIX

MYNAME = syntax-test
ME = inform7/syntax-test
# which depends on:
MODULE1 = inweb/foundation-module
MODULE2 = inform7/words-module
MODULE3 = inform7/syntax-module

$(ME)/Tangled/$(MYNAME): $(ME)/Contents.w $(ME)/Chapter*/*.w $(MODULE1)/Contents.w $(MODULE1)/Chapter*/*.w $(MODULE2)/Contents.w $(MODULE2)/Chapter*/*.w $(MODULE3)/Contents.w $(MODULE3)/Chapter*/*.w
	$(call make-me)

.PHONY: force
force:
	$(call make-me)

define make-me
	$(INWEB) $(ME) -import-from modules -tangle
	$(CC) -o $(ME)/Tangled/$(MYNAME).o $(ME)/Tangled/$(MYNAME).c
	$(LINK) -o $(ME)/Tangled/$(MYNAME) $(ME)/Tangled/$(MYNAME).o $(LINKEROPTS)
endef

.PHONY: test
test:
	$(INTEST) -from $(ME) all

.PHONY: clean
clean:
	$(call clean-up)

.PHONY: purge
purge:
	$(call clean-up)
	rm -f $(ME)/Tangled/$(MYNAME)

define clean-up
	rm -f $(ME)/Tangled/*.o
	rm -f $(ME)/Tangled/*.c
	rm -f $(ME)/Tangled/*.h
endef

