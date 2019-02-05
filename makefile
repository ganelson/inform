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

-include ../make-integration-settings.mk

-include ../make-benevolent-overlord.mk

-include build-code.mk

FOUNDATIONWEB = inweb/foundation-module
WORDSWEB = inform7/words-module
INFLECTIONSWEB = inform7/inflections-module
SYNTAXWEB = inform7/syntax-module
LINGUISTICSWEB = inform7/linguistics-module
KINDSWEB = inform7/kinds-module
PROBLEMSWEB = inform7/problems-module
COREWEB = inform7/core-module
IFWEB = inform7/if-module
INDEXWEB = inform7/index-module
MULTIMEDIAWEB = inform7/multimedia-module
INTERWEB = inter/inter-module
CODEGENWEB = inter/codegen-module

INBLORBWEB = inblorb
INBLORBMAKER = $(INBLORBWEB)/inblorb.mk
INBLORBX = $(INBLORBWEB)/Tangled/inblorb

INDOCWEB = indoc
INDOCMAKER = $(INDOCWEB)/indoc.mk
INDOCX = $(INDOCWEB)/Tangled/indoc

INFORM7WEB = inform7
INFORM7MAKER = $(INFORM7WEB)/inform7.mk
INFORM7X = $(INFORM7WEB)/Tangled/inform7

INPOLICYWEB = inpolicy
INPOLICYMAKER = $(INPOLICYWEB)/inpolicy.mk
INPOLICYX = $(INPOLICYWEB)/Tangled/inpolicy

INRTPSWEB = inrtps
INRTPSMAKER = $(INRTPSWEB)/inrtps.mk
INRTPSX = $(INRTPSWEB)/Tangled/inrtps

INTESTWEB = intest
INTESTMAKER = $(INTESTWEB)/intest.mk
INTESTX = $(INTESTWEB)/Tangled/intest

INWEBWEB = inweb
INWEBMAKER = $(INWEBWEB)/inweb.mk
INWEBX = $(INWEBWEB)/Tangled/inweb

INTERTOOLWEB = inter
INTERTOOLMAKER = $(INTERTOOLWEB)/inter.mk
INTERTOOLX = $(INTERTOOLWEB)/Tangled/inter

INFORM6X = inform6/Tangled/inform6

FOUNDATIONTESTWEB = inweb/foundation-test
FOUNDATIONTESTMAKER = $(FOUNDATIONTESTWEB)/foundation-test.mk
FOUNDATIONTESTX = $(FOUNDATIONTESTWEB)/Tangled/foundation-test

INFLECTIONSTESTWEB = inform7/inflections-test
INFLECTIONSTESTMAKER = $(INFLECTIONSTESTWEB)/inflections-test.mk
INFLECTIONSTESTX = $(INFLECTIONSTESTWEB)/Tangled/inflections-test

KINDSTESTWEB = inform7/kinds-test
KINDSTESTMAKER = $(KINDSTESTWEB)/kinds-test.mk
KINDSTESTX = $(KINDSTESTWEB)/Tangled/kinds-test

LINGUISTICSTESTWEB = inform7/linguistics-test
LINGUISTICSTESTMAKER = $(LINGUISTICSTESTWEB)/linguistics-test.mk
LINGUISTICSTESTX = $(LINGUISTICSTESTWEB)/Tangled/linguistics-test

PROBLEMSTESTWEB = inform7/problems-test
PROBLEMSTESTMAKER = $(PROBLEMSTESTWEB)/problems-test.mk
PROBLEMSTESTX = $(PROBLEMSTESTWEB)/Tangled/problems-test

SYNTAXTESTWEB = inform7/syntax-test
SYNTAXTESTMAKER = $(SYNTAXTESTWEB)/syntax-test.mk
SYNTAXTESTX = $(SYNTAXTESTWEB)/Tangled/syntax-test

WORDSTESTWEB = inform7/words-test
WORDSTESTMAKER = $(WORDSTESTWEB)/words-test.mk
WORDSTESTX = $(WORDSTESTWEB)/Tangled/words-test

.PHONY: all

all: tools srules

.PHONY: force

force: forcetools forcesrules

.PHONY: makers
makers:
	$(INWEBX) $(INBLORBWEB) -makefile $(INBLORBMAKER)
	$(INWEBX) $(INDOCWEB) -makefile $(INDOCMAKER)
	$(INWEBX) $(INFORM7WEB) -makefile $(INFORM7MAKER)
	$(INWEBX) $(INPOLICYWEB) -makefile $(INPOLICYMAKER)
	$(INWEBX) $(INRTPSWEB) -makefile $(INRTPSMAKER)
	$(INWEBX) $(INTESTWEB) -makefile $(INTESTMAKER)
	$(INWEBX) $(INWEBWEB) -makefile $(INWEBMAKER)
	$(INWEBX) $(INTERTOOLWEB) -makefile $(INTERTOOLMAKER)
	$(INWEBX) $(FOUNDATIONTESTWEB) -makefile $(FOUNDATIONTESTMAKER)
	$(INWEBX) $(INFLECTIONSTESTWEB) -makefile $(INFLECTIONSTESTMAKER)
	$(INWEBX) $(KINDSTESTWEB) -makefile $(KINDSTESTMAKER)
	$(INWEBX) $(LINGUISTICSTESTWEB) -makefile $(LINGUISTICSTESTMAKER)
	$(INWEBX) $(PROBLEMSTESTWEB) -makefile $(PROBLEMSTESTMAKER)
	$(INWEBX) $(SYNTAXTESTWEB) -makefile $(SYNTAXTESTMAKER)
	$(INWEBX) $(WORDSTESTWEB) -makefile $(WORDSTESTMAKER)
	inweb/Tangled/inweb -prototype inform6/makescript.txt -makefile inform6/inform6.mk

.PHONY: gitignores
gitignores:
	$(INWEBX) $(INBLORBWEB) -gitignore $(INBLORBWEB)/.gitignore
	$(INWEBX) $(INDOCWEB) -gitignore $(INDOCWEB)/.gitignore
	$(INWEBX) $(INFORM7WEB) -gitignore $(INFORM7WEB)/.gitignore
	$(INWEBX) $(INPOLICYWEB) -gitignore $(INPOLICYWEB)/.gitignore
	$(INWEBX) $(INRTPSWEB) -gitignore $(INRTPSWEB)/.gitignore
	$(INWEBX) $(INTESTWEB) -gitignore $(INTESTWEB)/.gitignore
	$(INWEBX) $(INWEBWEB) -gitignore $(INWEBWEB)/.gitignore
	$(INWEBX) $(INTERTOOLWEB) -gitignore $(INTERTOOLWEB)/.gitignore
	$(INWEBX) $(FOUNDATIONTESTWEB) -gitignore $(FOUNDATIONTESTWEB)/.gitignore
	$(INWEBX) $(INFLECTIONSTESTWEB) -gitignore $(INFLECTIONSTESTWEB)/.gitignore
	$(INWEBX) $(KINDSTESTWEB) -gitignore $(KINDSTESTWEB)/.gitignore
	$(INWEBX) $(LINGUISTICSTESTWEB) -gitignore $(LINGUISTICSTESTWEB)/.gitignore
	$(INWEBX) $(PROBLEMSTESTWEB) -gitignore $(PROBLEMSTESTWEB)/.gitignore
	$(INWEBX) $(SYNTAXTESTWEB) -gitignore $(SYNTAXTESTWEB)/.gitignore
	$(INWEBX) $(WORDSTESTWEB) -gitignore $(WORDSTESTWEB)/.gitignore
	inweb/Tangled/inweb -prototype inform6/gitignorescript.txt -gitignore inform6/.gitignore

.PHONY: versions
versions:
	$(INBLORBX) -version
	$(INDOCX) -version
	$(INFORM7X) -version
	$(INPOLICYX) -version
	$(INRTPSX) -version
	$(INTESTX) -version
	$(INWEBX) -version
	$(INTERTOOLX) -version
	$(FOUNDATIONTESTX) -version
	$(INFLECTIONSTESTX) -version
	$(KINDSTESTX) -version
	$(LINGUISTICSTESTX) -version
	$(PROBLEMSTESTX) -version
	$(SYNTAXTESTX) -version
	$(WORDSTESTX) -version
	$(INFORM6X) -V

SRULES = Internal/Extensions/Graham\ Nelson/Standard\ Rules.i7x

.PHONY: srules
srules: $(SRULES)

$(SRULES): $(INFORM7WEB)/Appendix*A/*.w
	$(INWEBX) $(INFORM7WEB) -tangle A
	cp 'inform7/Tangled/The Standard Rules' $(SRULES)

.PHONY: forcesrules
forcesrules:
	$(INWEBX) $(INFORM7WEB) -tangle A
	cp 'inform7/Tangled/The Standard Rules' $(SRULES)

.PHONY: tools
tools: $(INBLORBX) $(INDOCX) $(INFORM7X) $(INPOLICYX) $(INRTPSX) $(INTESTX) $(INWEBX) $(INTERTOOLX) $(FOUNDATIONTESTX) $(INFLECTIONSTESTX) $(KINDSTESTX) $(LINGUISTICSTESTX) $(PROBLEMSTESTX) $(SYNTAXTESTX) $(WORDSTESTX) $(INFORM6X)

$(INBLORBX): $(INBLORBWEB)/Contents.w $(INBLORBWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INBLORBWEB)
endif
	$(MAKE) -f $(INBLORBMAKER)

$(INDOCX): $(INDOCWEB)/Contents.w $(INDOCWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INDOCWEB)
endif
	$(MAKE) -f $(INDOCMAKER)

$(INFORM7X): $(INFORM7WEB)/Contents.w $(INFORM7WEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(WORDSWEB)/Contents.w $(WORDSWEB)/Chapter*/*.w $(INFLECTIONSWEB)/Contents.w $(INFLECTIONSWEB)/Chapter*/*.w $(SYNTAXWEB)/Contents.w $(SYNTAXWEB)/Chapter*/*.w $(LINGUISTICSWEB)/Contents.w $(LINGUISTICSWEB)/Chapter*/*.w $(KINDSWEB)/Contents.w $(KINDSWEB)/Chapter*/*.w $(PROBLEMSWEB)/Contents.w $(PROBLEMSWEB)/Chapter*/*.w $(COREWEB)/Contents.w $(COREWEB)/Chapter*/*.w $(IFWEB)/Contents.w $(IFWEB)/Chapter*/*.w $(MULTIMEDIAWEB)/Contents.w $(MULTIMEDIAWEB)/Chapter*/*.w $(INDEXWEB)/Contents.w $(INDEXWEB)/Chapter*/*.w $(INTERWEB)/Contents.w $(INTERWEB)/Chapter*/*.w $(CODEGENWEB)/Contents.w $(CODEGENWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INFORM7WEB)
endif
	$(MAKE) -f $(INFORM7MAKER)

$(INPOLICYX): $(INPOLICYWEB)/Contents.w $(INPOLICYWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INPOLICYWEB)
endif
	$(MAKE) -f $(INPOLICYMAKER)

$(INRTPSX): $(INRTPSWEB)/Contents.w $(INRTPSWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INRTPSWEB)
endif
	$(MAKE) -f $(INRTPSMAKER)

$(INTESTX): $(INTESTWEB)/Contents.w $(INTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INTESTWEB)
endif
	$(MAKE) -f $(INTESTMAKER)

$(INWEBX): $(INWEBWEB)/Contents.w $(INWEBWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INWEBWEB)
endif
	$(MAKE) -f $(INWEBMAKER)

$(INTERTOOLX): $(INTERTOOLWEB)/Contents.w $(INTERTOOLWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(INTERWEB)/Contents.w $(INTERWEB)/Chapter*/*.w $(CODEGENWEB)/Contents.w $(CODEGENWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INTERTOOLWEB)
endif
	$(MAKE) -f $(INTERTOOLMAKER)

$(FOUNDATIONTESTX): $(FOUNDATIONTESTWEB)/Contents.w $(FOUNDATIONTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(FOUNDATIONTESTWEB)
endif
	$(MAKE) -f $(FOUNDATIONTESTMAKER)

$(INFLECTIONSTESTX): $(INFLECTIONSTESTWEB)/Contents.w $(INFLECTIONSTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(WORDSWEB)/Contents.w $(WORDSWEB)/Chapter*/*.w $(INFLECTIONSWEB)/Contents.w $(INFLECTIONSWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(INFLECTIONSTESTWEB)
endif
	$(MAKE) -f $(INFLECTIONSTESTMAKER)

$(KINDSTESTX): $(KINDSTESTWEB)/Contents.w $(KINDSTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(WORDSWEB)/Contents.w $(WORDSWEB)/Chapter*/*.w $(INFLECTIONSWEB)/Contents.w $(INFLECTIONSWEB)/Chapter*/*.w $(SYNTAXWEB)/Contents.w $(SYNTAXWEB)/Chapter*/*.w $(LINGUISTICSWEB)/Contents.w $(LINGUISTICSWEB)/Chapter*/*.w $(KINDSWEB)/Contents.w $(KINDSWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(KINDSTESTWEB)
endif
	$(MAKE) -f $(KINDSTESTMAKER)

$(LINGUISTICSTESTX): $(LINGUISTICSTESTWEB)/Contents.w $(LINGUISTICSTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(WORDSWEB)/Contents.w $(WORDSWEB)/Chapter*/*.w $(INFLECTIONSWEB)/Contents.w $(INFLECTIONSWEB)/Chapter*/*.w $(SYNTAXWEB)/Contents.w $(SYNTAXWEB)/Chapter*/*.w $(LINGUISTICSWEB)/Contents.w $(LINGUISTICSWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(LINGUISTICSTESTWEB)
endif
	$(MAKE) -f $(LINGUISTICSTESTMAKER)

$(PROBLEMSTESTX): $(PROBLEMSTESTWEB)/Contents.w $(PROBLEMSTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(WORDSWEB)/Contents.w $(WORDSWEB)/Chapter*/*.w $(SYNTAXWEB)/Contents.w $(SYNTAXWEB)/Chapter*/*.w $(PROBLEMSWEB)/Contents.w $(PROBLEMSWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(PROBLEMSTESTWEB)
endif
	$(MAKE) -f $(PROBLEMSTESTMAKER)

$(SYNTAXTESTX): $(SYNTAXTESTWEB)/Contents.w $(SYNTAXTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(WORDSWEB)/Contents.w $(WORDSWEB)/Chapter*/*.w $(SYNTAXWEB)/Contents.w $(SYNTAXWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(SYNTAXTESTWEB)
endif
	$(MAKE) -f $(SYNTAXTESTMAKER)

$(WORDSTESTX): $(WORDSTESTWEB)/Contents.w $(WORDSTESTWEB)/Chapter*/*.w $(FOUNDATIONWEB)/Contents.w $(FOUNDATIONWEB)/Chapter*/*.w $(WORDSWEB)/Contents.w $(WORDSWEB)/Chapter*/*.w
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
	$(INPOLICYX) -advance-build $(WORDSTESTWEB)
endif
	$(MAKE) -f $(WORDSTESTMAKER)

$(INFORM6X): inform6/Inform6/*.c
	$(MAKE) -f inform6/inform6.mk

.PHONY: forcetools
forcetools:
ifdef BENEVOLENTOVERLORD
	$(MAKE) -f $(INPOLICYMAKER)
endif
	$(MAKE) -f $(INWEBMAKER) initial
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INBLORBWEB)
endif
	$(MAKE) -f $(INBLORBMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INDOCWEB)
endif
	$(MAKE) -f $(INDOCMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INFORM7WEB)
endif
	$(MAKE) -f $(INFORM7MAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INPOLICYWEB)
endif
	$(MAKE) -f $(INPOLICYMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INRTPSWEB)
endif
	$(MAKE) -f $(INRTPSMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INTESTWEB)
endif
	$(MAKE) -f $(INTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INWEBWEB)
endif
	$(MAKE) -f $(INWEBMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INTERTOOLWEB)
endif
	$(MAKE) -f $(INTERTOOLMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(FOUNDATIONTESTWEB)
endif
	$(MAKE) -f $(FOUNDATIONTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(INFLECTIONSTESTWEB)
endif
	$(MAKE) -f $(INFLECTIONSTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(KINDSTESTWEB)
endif
	$(MAKE) -f $(KINDSTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(LINGUISTICSTESTWEB)
endif
	$(MAKE) -f $(LINGUISTICSTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(PROBLEMSTESTWEB)
endif
	$(MAKE) -f $(PROBLEMSTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(SYNTAXTESTWEB)
endif
	$(MAKE) -f $(SYNTAXTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force
ifdef BENEVOLENTOVERLORD
	$(INPOLICYX) -advance-build $(WORDSTESTWEB)
endif
	$(MAKE) -f $(WORDSTESTMAKER) force
	$(MAKE) -f inform6/inform6.mk force

.PHONY: check
check:
	$(MAKE) -f inform6/inform6.mk test
	$(INPOLICYX) -silence -check-problems
	$(MAKE) -f $(INBLORBMAKER) test
	$(MAKE) -f $(INDOCMAKER) test
	$(MAKE) -f $(INFORM7MAKER) test
	$(MAKE) -f $(INPOLICYMAKER) test
	$(MAKE) -f $(INRTPSMAKER) test
	$(MAKE) -f $(INTESTMAKER) test
	$(MAKE) -f $(INWEBMAKER) test
	$(MAKE) -f $(INTERTOOLMAKER) test
	$(MAKE) -f $(FOUNDATIONTESTMAKER) test
	$(MAKE) -f $(INFLECTIONSTESTMAKER) test
	$(MAKE) -f $(KINDSTESTMAKER) test
	$(MAKE) -f $(LINGUISTICSTESTMAKER) test
	$(MAKE) -f $(PROBLEMSTESTMAKER) test
	$(MAKE) -f $(SYNTAXTESTMAKER) test
	$(MAKE) -f $(WORDSTESTMAKER) test

.PHONY: tangle
tangle:
	$(call tangle-webs)

define tangle-webs
	$(INWEBX) $(INBLORBWEB) -tangle
	$(INWEBX) $(INDOCWEB) -tangle
	$(INWEBX) $(INFORM7WEB) -tangle
	$(INWEBX) $(INPOLICYWEB) -tangle
	$(INWEBX) $(INRTPSWEB) -tangle
	$(INWEBX) $(INTESTWEB) -tangle
	$(INWEBX) $(INWEBWEB) -tangle
	$(INWEBX) $(INTERTOOLWEB) -tangle
	$(INWEBX) $(FOUNDATIONTESTWEB) -tangle
	$(INWEBX) $(INFLECTIONSTESTWEB) -tangle
	$(INWEBX) $(KINDSTESTWEB) -tangle
	$(INWEBX) $(LINGUISTICSTESTWEB) -tangle
	$(INWEBX) $(PROBLEMSTESTWEB) -tangle
	$(INWEBX) $(SYNTAXTESTWEB) -tangle
	$(INWEBX) $(WORDSTESTWEB) -tangle
endef

WEAVEOPTS = -weave sections

.PHONY: weave
weave:
	$(call weave-webs)

define weave-webs
	$(INWEBX) $(INBLORBWEB) $(WEAVEOPTS)
	$(INWEBX) $(INDOCWEB) $(WEAVEOPTS)
	$(INWEBX) $(INFORM7WEB) $(WEAVEOPTS)
	$(INWEBX) $(INPOLICYWEB) $(WEAVEOPTS)
	$(INWEBX) $(INRTPSWEB) $(WEAVEOPTS)
	$(INWEBX) $(INTESTWEB) $(WEAVEOPTS)
	$(INWEBX) $(INWEBWEB) $(WEAVEOPTS)
	$(INWEBX) $(INTERTOOLWEB) $(WEAVEOPTS)
	$(INWEBX) $(FOUNDATIONTESTWEB) $(WEAVEOPTS)
	$(INWEBX) $(INFLECTIONSTESTWEB) $(WEAVEOPTS)
	$(INWEBX) $(KINDSTESTWEB) $(WEAVEOPTS)
	$(INWEBX) $(LINGUISTICSTESTWEB) $(WEAVEOPTS)
	$(INWEBX) $(PROBLEMSTESTWEB) $(WEAVEOPTS)
	$(INWEBX) $(SYNTAXTESTWEB) $(WEAVEOPTS)
	$(INWEBX) $(WORDSTESTWEB) $(WEAVEOPTS)
endef

.PHONY: clean
clean:
	$(call clean-up)

define clean-up
	$(MAKE) -f $(INBLORBMAKER) clean
	$(MAKE) -f $(INDOCMAKER) clean
	$(MAKE) -f $(INFORM7MAKER) clean
	$(MAKE) -f $(INPOLICYMAKER) clean
	$(MAKE) -f $(INRTPSMAKER) clean
	$(MAKE) -f $(INTESTMAKER) clean
	$(MAKE) -f $(INWEBMAKER) clean
	$(MAKE) -f $(INTERTOOLMAKER) clean
	$(MAKE) -f $(FOUNDATIONTESTMAKER) clean
	$(MAKE) -f $(INFLECTIONSTESTMAKER) clean
	$(MAKE) -f $(KINDSTESTMAKER) clean
	$(MAKE) -f $(LINGUISTICSTESTMAKER) clean
	$(MAKE) -f $(PROBLEMSTESTMAKER) clean
	$(MAKE) -f $(SYNTAXTESTMAKER) clean
	$(MAKE) -f $(WORDSTESTMAKER) clean
	$(MAKE) -f inform6/inform6.mk clean
endef

.PHONY: purge
purge:
	$(call purge-up)

define purge-up
	$(MAKE) -f $(INBLORBMAKER) purge
	$(MAKE) -f $(INDOCMAKER) purge
	$(MAKE) -f $(INFORM7MAKER) purge
	$(MAKE) -f $(INPOLICYMAKER) purge
	$(MAKE) -f $(INRTPSMAKER) purge
	$(MAKE) -f $(INTESTMAKER) purge
	$(MAKE) -f $(INWEBMAKER) purge
	$(MAKE) -f $(INTERTOOLMAKER) purge
	$(MAKE) -f $(FOUNDATIONTESTMAKER) purge
	$(MAKE) -f $(INFLECTIONSTESTMAKER) purge
	$(MAKE) -f $(KINDSTESTMAKER) purge
	$(MAKE) -f $(LINGUISTICSTESTMAKER) purge
	$(MAKE) -f $(PROBLEMSTESTMAKER) purge
	$(MAKE) -f $(SYNTAXTESTMAKER) purge
	$(MAKE) -f $(WORDSTESTMAKER) purge
	$(MAKE) -f inform6/inform6.mk purge
endef

MANIFEST = \
	About.txt \
	Changes Documentation Imagery Internal "Outcome Pages" "Sample Projects" \
	inblorb indoc inform6 inform7 inpolicy inrtps inter intest inweb \
	makefile makescript.txt gitignorescript.txt .gitignore build-code.mk

.PHONY: archive
archive:
	$(call tangle-webs)
	$(call purge-up)
	export COPYFILE_DISABLE=true
	tar --create --exclude='*/.*' --exclude='inweb/Tangled/inweb' --file Inform-Source-$(BUILDCODE).tar $(MANIFEST)
	gzip -f Inform-Source-$(BUILDCODE).tar
	export COPYFILE_DISABLE=false
 

.PHONY: ebooks
ebooks:
	$(call clean-ebooks)
	$(INDOCX) ebook
	$(call clean-ebooks)
	$(INDOCX) -from Changes ebook
	$(call clean-ebooks)

define clean-ebooks
	rm -f Documentation/Output/OEBPS/images/*
	rm -f Documentation/Output/OEBPS/*.*
	rm -f Documentation/Output/META-INF/container.xml
	rm -f Documentation/Output/mimetype
	rm -f Documentation/Output/*.*
	rm -f Changes/Output/OEBPS/images/*
	rm -f Changes/Output/OEBPS/*.*
	rm -f Changes/Output/META-INF/container.xml
	rm -f Changes/Output/mimetype
	rm -f Changes/Output/*.*
endef

.PHONY: csr
csr:
	cp -f $(INFORM7WEB)/Home.txt $(INTESTWEB)/Workspace/T0/Example.inform/Source/story.ni
	'inform7/Tangled/inform7' '-format=z8' '-noprogress' '-fixtime' '-rng' '-sigils' '-clock' '-log' 'nothing' '-external' 'inform7/Tests' '-transient' 'intest/Workspace/T0/Transient' '-noindex' '-internal' 'Internal' '-project'  'intest/Workspace/T0/Example.inform' '-export' 'Internal/I6T/sr-Z.intert' '-inter'  'stop'
	$(INTERTOOLWEB)/Tangled/inter Internal/I6T/sr-Z.intert -binary Internal/I6T/sr-Z.interb
	cp -f Internal/I6T/sr-Z.intert $(INTERNAL)/I6T/sr-Z.intert 
	cp -f Internal/I6T/sr-Z.interb $(INTERNAL)/I6T/sr-Z.interb 
	'inform7/Tangled/inform7' '-format=ulx' '-noprogress' '-fixtime' '-rng' '-sigils' '-clock' '-log' 'nothing' '-external' 'inform7/Tests' '-transient' 'intest/Workspace/T0/Transient' '-noindex' '-internal' 'Internal' '-project'  'intest/Workspace/T0/Example.inform' '-export' 'Internal/I6T/sr-G.intert' '-inter'  'stop'
	$(INTERTOOLWEB)/Tangled/inter Internal/I6T/sr-G.intert -binary Internal/I6T/sr-G.interb
	cp -f Internal/I6T/sr-G.intert $(INTERNAL)/I6T/sr-G.intert 
	cp -f Internal/I6T/sr-G.interb $(INTERNAL)/I6T/sr-G.interb 

INTOOLSBUILTIN = \
	$(BUILTINCOMPS)/$(INBLORBNAME) \
	$(BUILTINCOMPS)/$(INFORM6NAME) \
	$(BUILTINCOMPS)/$(INFORM7NAME) \
	$(BUILTINCOMPS)/$(INTESTNAME)

SRULESINPLACE = $(INTERNAL)/Extensions/Graham\ Nelson/Standard\ Rules.i7x
INTERNALEXEMPLUM = $(INTERNAL)/Miscellany/Cover.jpg
INTERNALEXEMPLUMFROM = Internal/Miscellany/Cover.jpg
IMAGESEXEMPLUM = $(BUILTINHTML)/doc_images/help.png
IMAGESEXEMPLUMFROM = Imagery/doc_images/help.png
DOCEXEMPLUM = $(BUILTINHTMLINNER)/index.html
RTPEXEMPLUM = $(BUILTINHTMLINNER)/RTP_P1.html

.PHONY: integration
integration: \
		$(INTOOLSBUILTIN) \
		$(INTERNAL)/Languages/English/Syntax.preform \
		$(SRULESINPLACE) \
		$(INTERNAL)/I6T/Main.i6t \
		$(INTERNALEXEMPLUM) \
		$(IMAGESEXEMPLUM) \
		$(DOCEXEMPLUM) \
		$(RTPEXEMPLUM)

.PHONY: forceintegration
forceintegration:
	$(call transfer-intools)
	$(call transfer-preform)
	$(call transfer-standard-rules)
	$(call transfer-i6-template)
	$(call transfer-internal-tree)
	$(call transfer-images)
	$(call make-inapp-documentation)
	$(call make-inapp-outcome-pages)

$(BUILTINCOMPS)/$(INBLORBNAME): $(INBLORBX)
	mkdir -p $(BUILTINCOMPS)
	cp -f $(INBLORBX) $(BUILTINCOMPS)/$(INBLORBNAME)

$(BUILTINCOMPS)/$(INFORM6NAME): inform6/Tangled/inform6
	$(MAKE) -f inform6/inform6.mk
	mkdir -p $(BUILTINCOMPS)
	cp -f $(INFORM6X) $(BUILTINCOMPS)/$(INFORM6NAME)

$(BUILTINCOMPS)/$(INFORM7NAME): $(INFORM7WEB)/Tangled/inform7
	$(MAKE) -f $(INFORM7MAKER)
	mkdir -p $(BUILTINCOMPS)
	cp -f $(INFORM7X) $(BUILTINCOMPS)/$(INFORM7NAME)

$(BUILTINCOMPS)/intest: $(INTESTWEB)/Tangled/intest
	$(MAKE) -f $(INTESTMAKER)
	mkdir -p $(BUILTINCOMPS)
	cp -f $(INTESTX) $(BUILTINCOMPS)/intest

define transfer-intools
	mkdir -p $(BUILTINCOMPS)
	cp -f $(INBLORBX) $(BUILTINCOMPS)/$(INBLORBNAME)
	cp -f $(INFORM6X) $(BUILTINCOMPS)/$(INFORM6NAME)
	cp -f $(INFORM7X) $(BUILTINCOMPS)/$(INFORM7NAME)
	cp -f $(INTESTX) $(BUILTINCOMPS)/intest
endef

$(INTERNAL)/Languages/English/Syntax.preform: $(INFORM7WEB)/Tangled/Syntax.preform
	$(call transfer-preform)
	
$(INFORM7WEB)/Tangled/Syntax.preform:
	$(MAKE) -f $(INFORM7MAKER)

define transfer-preform
	cp -f 'inform7/Tangled/Syntax.preform' "$(INTERNAL)/Languages/English/Syntax.preform"
	cp -f 'inform7/Tangled/Syntax.preform' "Internal/Languages/English/Syntax.preform"
endef

$(SRULESINPLACE): $(SRULES)
	$(call transfer-standard-rules)

define transfer-standard-rules
	mkdir -p "$(INTERNAL)/Extensions/Graham Nelson"
	cp $(SRULES) $(SRULESINPLACE)
endef

$(INTERNAL)/I6T/Main.i6t: $(INFORM7WEB)/Appendix\ B/*.i6t
	$(call transfer-i6-template)

define transfer-i6-template
	mkdir -p "$(INTERNAL)/I6T"
	rm -f $(INTERNAL)/I6T/*.i6t
	touch $(INFORM7WEB)/Appendix\ B/Main.i6t
	cp -R -f $(INFORM7WEB)/Appendix\ B/*.i6t $(INTERNAL)/I6T
	rm -f Internal/I6T/*.i6t
	cp -R -f $(INFORM7WEB)/Appendix\ B/*.i6t Internal/I6T
endef

$(INTERNALEXEMPLUM): \
		Internal/Extensions/Eric\ Eve/[A-Za-z]* \
		Internal/Extensions/Emily\ Short/[A-Za-z]* \
		Internal/Extensions/Graham\ Nelson/[A-Za-z]* \
		Internal/Miscellany/[A-Za-z]*.* \
		Internal/HTML/[A-Za-z]*.* \
		Internal/Templates/Parchment/[A-Za-z]*.* \
		Internal/Templates/Quixe/[A-Za-z]*.* \
		Internal/Templates/Classic/[A-Za-z]*.* \
		Internal/Templates/Vorple/[A-Za-z]*.* \
		Internal/Templates/Standard/[A-Za-z]*.*
	$(call transfer-internal-tree)

define transfer-internal-tree
	touch $(INTERNALEXEMPLUMFROM)
	mkdir -p $(INTERNAL)
	mkdir -p "$(INTERNAL)/Extensions/Eric Eve"
	rm -f $(INTERNAL)/Extensions/Eric\ Eve/*
	mkdir -p "$(INTERNAL)/Extensions/Emily Short"
	rm -f $(INTERNAL)/Extensions/Emily\ Short/*
	mkdir -p "$(INTERNAL)/Extensions/Graham Nelson"
	rm -f $(INTERNAL)/Extensions/Graham\ Nelson/*
	cp -R -f Internal/Extensions $(INTERNAL)/Extensions/..
	mkdir -p "$(INTERNAL)/Languages"
	mkdir -p "$(INTERNAL)/Languages/English"
	mkdir -p "$(INTERNAL)/Languages/French"
	mkdir -p "$(INTERNAL)/Languages/German"
	mkdir -p "$(INTERNAL)/Languages/Italian"
	mkdir -p "$(INTERNAL)/Languages/Spanish"
	cp -R -f Internal/Languages $(INTERNAL)/Languages/..
	mkdir -p "$(INTERNAL)/Templates"
	mkdir -p "$(INTERNAL)/Templates/Standard"
	rm -f $(INTERNAL)/Templates/Standard/*
	mkdir -p "$(INTERNAL)/Templates/Classic"
	rm -f $(INTERNAL)/Templates/Classic/*
	mkdir -p "$(INTERNAL)/Templates/Parchment"
	rm -f $(INTERNAL)/Templates/Parchment/*
	mkdir -p "$(INTERNAL)/Templates/Quixe"
	rm -f $(INTERNAL)/Templates/Quixe/*
	mkdir -p "$(INTERNAL)/Templates/Vorple"
	rm -f $(INTERNAL)/Templates/Vorple/*
	cp -R -f Internal/Templates $(INTERNAL)/Templates/..
	mkdir -p "$(INTERNAL)/Miscellany"
	rm -f $(INTERNAL)/Miscellany/*
	cp -R -f Internal/Miscellany $(INTERNAL)/Miscellany/..
	mkdir -p "$(INTERNAL)/HTML"
	rm -f $(INTERNAL)/HTML/*
	cp -R -f Internal/HTML $(INTERNAL)/HTML/..
endef

$(IMAGESEXEMPLUM): \
	Imagery/app_images/[A-Za-z]*.* \
	Imagery/bg_images/[A-Za-z]*.* \
	Imagery/doc_images/[A-Za-z]*.* \
	Imagery/map_icons/[A-Za-z]*.* \
	Imagery/outcome_images/[A-Za-z]*.* \
	Imagery/scene_icons/[A-Za-z]*.*
	$(call transfer-images)

define transfer-images
	touch $(IMAGESEXEMPLUMFROM)
	cp -f Imagery/app_images/Welcome*Background.png $(BUILTINHTML)
	mkdir -p $(BUILTINHTML)/bg_images
	rm -f $(BUILTINHTML)/bg_images/*
	cp -f Imagery/bg_images/[A-Za-z]*.* $(BUILTINHTML)/bg_images
	mkdir -p $(BUILTINHTML)/doc_images
	rm -f $(BUILTINHTML)/doc_images/*
	cp -f Imagery/doc_images/[A-Za-z]*.* $(BUILTINHTML)/doc_images
	mkdir -p $(BUILTINHTML)/map_icons
	rm -f $(BUILTINHTML)/map_icons/*
	cp -f Imagery/map_icons/[A-Za-z]*.* $(BUILTINHTML)/map_icons
	mkdir -p $(BUILTINHTML)/outcome_images
	rm -f $(BUILTINHTML)/outcome_images/*
	cp -f Imagery/outcome_images/[A-Za-z]*.* $(BUILTINHTML)/outcome_images
	mkdir -p $(BUILTINHTML)/scene_icons
	rm -f $(BUILTINHTML)/scene_icons/*
	cp -f Imagery/scene_icons/[A-Za-z]*.* $(BUILTINHTML)/scene_icons
endef

$(DOCEXEMPLUM): Documentation/*.txt Documentation/Examples/*.txt
	$(call make-inapp-documentation)

ifdef BENEVOLENTOVERLORD
define make-inapp-documentation
	mkdir -p "$(INTERNAL)/Documentation"
	mkdir -p $(BUILTINHTMLINNER)
	$(INDOCX) -rewrite-standard-rules 'inform7/Appendix A/Preamble.w' $(INDOCOPTS)
	$(INWEBX) inform7 -tangle A
	cp 'inform7/Tangled/The Standard Rules' $(SRULES)
	$(call transfer-standard-rules)
	$(INDOCX) $(INDOCOPTS)
endef
else
define make-inapp-documentation
	mkdir -p "$(INTERNAL)/Documentation"
	mkdir -p $(BUILTINHTMLINNER)
	$(INDOCX) $(INDOCOPTS)
endef
endif

$(RTPEXEMPLUM): Outcome*Pages/texts.txt Outcome*Pages/*.html
	$(call make-inapp-outcome-pages)

define make-inapp-outcome-pages
	$(INRTPSX) Outcome\ Pages $(BUILTINHTMLINNER) $(INRTPSOPTS)
	cp -f Outcome\ Pages/pl404.html $(BUILTINHTMLINNER)
endef

