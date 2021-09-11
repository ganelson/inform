.PHONY: all
all: inform7/Tests/Test\ Externals/_Executables/XText

inform7/Tests/Test\ Externals/_Executables/XText: \
		inform7/Tests/Test\ Externals/_Build/XText.o \
		inform7/Tests/Test\ Externals/_Build/XText-I.o
	clang -g -o inform7/Tests/Test\ Externals/_Executables/XText \
		inform7/Tests/Test\ Externals/_Build/XText.o \
		inform7/Tests/Test\ Externals/_Build/XText-I.o

inform7/Tests/Test\ Externals/_Build/XText.o: inform7/Tests/Test\ Externals/_Source/XText.c
	clang -g -std=c99 -c -o inform7/Tests/Test\ Externals/_Build/XText.o  inform7/Tests/Test\ Externals/_Source/XText.c  -Wno-parentheses-equality -D DEBUG -I inform7/Internal/Miscellany

inform7/Tests/Test\ Externals/_Build/XText-I.o: inform7/Tests/Test\ Externals/_Build/XText-I.c
	clang -g -std=c99 -c -o inform7/Tests/Test\ Externals/_Build/XText-I.o  inform7/Tests/Test\ Externals/_Build/XText-I.c  -Wno-parentheses-equality -D DEBUG -D I7_NO_MAIN -I inform7/Internal/Miscellany

inform7/Tests/Test\ Externals/_Build/XText-I.c: inform7/Tests/Test\ Externals/_Source/XText.i7
	'inform7/Tangled/inform7'  '-kit' 'BasicInformKit' '-format=C/32d' '-no-progress' '-fixtime' '-rng' '-sigils' '-log' 'nothing' '-external' 'inform7/Tests' '-transient' '/Users/gnelson/Natural Inform/intest/Workspace/T0/Transient' '-no-index' '-internal' 'inform7/Internal' '-project'  '/Users/gnelson/Natural Inform/intest/Workspace/T0/Example.inform'  '-variable'  '*tout=inform7/Tests/Test Externals/_Textual/XText.intert'  '-variable'  '*out=inform7/Tests/Test Externals/_Build/XText-I.c'  '-pipeline'  'test_any'
