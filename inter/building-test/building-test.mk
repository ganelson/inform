# This makefile was automatically written by inweb -makefile
# and is not intended for human editing

INTEST = intest/Tangled/intest
INWEB = inweb/Tangled/inweb

CC = clang -std=c99 -c $(MANYWARNINGS) $(CCOPTS) -g 
INDULGENTCC = clang -std=c99 -c $(FEWERWARNINGS) $(CCOPTS) -g

CCOPTS = -DPLATFORM_MACOS=1 -mmacosx-version-min=10.6 -arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

MANYWARNINGS = -Weverything -Wno-pointer-arith -Wno-unused-macros -Wno-shadow -Wno-cast-align -Wno-variadic-macros -Wno-missing-noreturn -Wno-missing-prototypes -Wno-unused-parameter -Wno-padded -Wno-missing-variable-declarations -Wno-unreachable-code-break -Wno-class-varargs -Wno-format-nonliteral -Wno-cast-qual -Wno-double-promotion -Wno-comma -Wno-strict-prototypes -Wno-extra-semi-stmt -ferror-limit=1000

FEWERWARNINGS = -Wno-implicit-int -Wno-dangling-else -Wno-pointer-sign -Wno-format-extra-args -Wno-tautological-compare -Wno-deprecated-declarations -Wno-logical-op-parentheses -Wno-format -Wno-extra-semi-stmt

LINK = clang $(CCOPTS) -g
LINKEROPTS = 

ARTOOL = libtool -o

INFORM6OS = OSX

GLULXEOS = OS_UNIX

INWEB = /Users/gnelson/Natural\ Inform/inweb/Tangled/inweb
INTEST = /Users/gnelson/Natural\ Inform/intest/Tangled/intest
MYNAME = building-test
ME = inter/building-test

$(ME)/Tangled/$(MYNAME): inter/building-test/*.w /Users/gnelson/Natural\ Inform/inweb/foundation-module/Preliminaries/*.w /Users/gnelson/Natural\ Inform/inweb/foundation-module/Chapter*/*.w inter/building-test/../building-module/Chapter*/*.w inter/building-test/../bytecode-module/Preliminaries/*.w inter/building-test/../bytecode-module/Chapter*/*.w inter/building-test/../../services/words-module/Preliminaries/*.w inter/building-test/../../services/words-module/Chapter*/*.w inter/building-test/Chapter*/*.w
	$(call make-me)

.PHONY: force
force:
	$(call make-me)

define make-me
	$(INWEB) $(ME) -import-from modules -tangle
	$(CC) -o $(ME)/Tangled/$(MYNAME).o $(ME)/Tangled/$(MYNAME).c
	$(LINK) -o $(ME)/Tangled/$(MYNAME)$(EXEEXTENSION) $(ME)/Tangled/$(MYNAME).o $(LINKEROPTS)
endef

.PHONY: test
test:
	$(INTEST) -from $(ME) all

.PHONY: pages
pages:
	mkdir -p $(ME)/docs/$(MYNAME)
	$(INWEB) $(ME) -weave-docs -weave-into $(ME)/docs/$(MYNAME)

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

