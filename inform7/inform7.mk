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

MYNAME = inform7
ME = inform7
# which depends on:
MODULE1 = inweb/foundation-module
MODULE2 = inform7/words-module
MODULE3 = inform7/inflections-module
MODULE4 = inform7/syntax-module
MODULE5 = inform7/problems-module
MODULE6 = inform7/linguistics-module
MODULE7 = inform7/kinds-module
MODULE8 = inter/inter-module
MODULE9 = inform7/core-module
MODULE10 = inter/codegen-module
MODULE11 = inform7/if-module
MODULE12 = inform7/multimedia-module
MODULE13 = inform7/index-module

BLORBLIB = $(ME)/Tests/Assistants/blorblib

$(ME)/Tangled/$(MYNAME): $(ME)/Contents.w $(ME)/Chapter*/*.w $(MODULE1)/Contents.w $(MODULE1)/Chapter*/*.w $(MODULE2)/Contents.w $(MODULE2)/Chapter*/*.w $(MODULE3)/Contents.w $(MODULE3)/Chapter*/*.w $(MODULE4)/Contents.w $(MODULE4)/Chapter*/*.w $(MODULE5)/Contents.w $(MODULE5)/Chapter*/*.w $(MODULE6)/Contents.w $(MODULE6)/Chapter*/*.w $(MODULE7)/Contents.w $(MODULE7)/Chapter*/*.w $(MODULE8)/Contents.w $(MODULE8)/Chapter*/*.w $(MODULE9)/Contents.w $(MODULE9)/Chapter*/*.w $(MODULE10)/Contents.w $(MODULE10)/Chapter*/*.w $(MODULE11)/Contents.w $(MODULE11)/Chapter*/*.w $(MODULE12)/Contents.w $(MODULE12)/Chapter*/*.w $(MODULE13)/Contents.w $(MODULE13)/Chapter*/*.w
	$(call make-me)

.PHONY: force
force:
	$(call make-me)

define make-me
	$(INWEB) $(ME) -import-from modules -tangle
	$(CC) -o $(ME)/Tangled/$(ME).o $(ME)/Tangled/$(ME).c
	$(LINK) -o $(ME)/Tangled/$(ME) $(ME)/Tangled/$(ME).o $(LINKEROPTS)
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
	rm -f $(ME)/Tangled/$(ME)

define clean-up
	rm -f $(ME)/Tangled/*.o
	rm -f $(ME)/Tangled/*.c
	rm -f $(ME)/Tangled/*.h
	rm -f $(ME)/Tests/Test\ Cases/_Results_Actual/*.txt
	rm -f $(ME)/Tests/Test\ Extensions/_Results_Actual/*.txt
	rm -f $(ME)/Tests/Test\ Index/_Results_Actual/*.txt
	rm -f $(ME)/Tests/Test\ Maps/_Results_Actual/*.txt
	rm -f $(ME)/Tests/Test\ Problems/_Results_Actual/*.txt
	rm -f Documentation/Examples/_Results_Actual/*.txt
endef

