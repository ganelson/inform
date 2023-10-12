# Unix Makefile for Glulxe.

# To use this, you must set three variables. GLKINCLUDEDIR must be the 
# directory containing glk.h, glkstart.h, and the Make.library file.
# GLKLIBDIR must be the directory containing the library.a file.
# And GLKMAKEFILE must be the name of the Make.library file. Two
# sets of values appear below; uncomment one of them and change the
# directories appropriately.

GLKINCLUDEDIR = ../cheapglk
GLKLIBDIR = ../cheapglk
GLKMAKEFILE = Make.cheapglk

#GLKINCLUDEDIR = ../glkterm
#GLKLIBDIR = ../glkterm
#GLKMAKEFILE = Make.glkterm

#GLKINCLUDEDIR = ../xglk
#GLKLIBDIR = ../xglk
#GLKMAKEFILE = Make.xglk

#GLKINCLUDEDIR = ../remglk
#GLKLIBDIR = ../remglk
#GLKMAKEFILE = Make.remglk

#GLKINCLUDEDIR = ../gtkglk/src
#GLKLIBDIR = ../gtkglk
#GLKMAKEFILE = ../Make.gtkglk

# Also set an appropriate OS config in OPTIONS, below.
#   -DOS_MAC for MacOS
#   -DOS_WINDOWS for Windows
#   -DOS_UNIX for Unix/Linux
# For OS_UNIX, you probably also want to set a random number generator
# option. These are unfortunately not very standardized across Unixes.
# We recommend -DUNIX_RAND_GETRANDOM on Linux and -DUNIX_RAND_ARC4
# on NetBSD.
# (MacOS always uses ARC4, in case you were wondering.)

# Pick a C compiler.
CC = cc
#CC = gcc

OPTIONS = -g -Wall -Wmissing-prototypes -Wno-unused -DOS_MAC

# Locate the libxml2 library. You only need these lines if you are using
# the VM_DEBUGGER option. If so, uncomment these and set appropriately.
#XMLLIB = -L/usr/local/lib -lxml2
#XMLLIBINCLUDEDIR = -I/usr/local/include/libxml2

include $(GLKINCLUDEDIR)/$(GLKMAKEFILE)

CFLAGS = $(OPTIONS) -I$(GLKINCLUDEDIR) $(XMLLIBINCLUDEDIR)
LIBS = -L$(GLKLIBDIR) $(GLKLIB) $(LINKLIBS) -lm $(XMLLIB)

OBJS = main.o files.o vm.o exec.o funcs.o operand.o string.o glkop.o \
  heap.o serial.o search.o accel.o float.o gestalt.o osdepend.o \
  profile.o debugger.o

all: glulxe

glulxe: $(OBJS) unixstrt.o unixautosave.o
	$(CC) $(OPTIONS) -o glulxe $(OBJS) unixstrt.o unixautosave.o $(LIBS)

glulxdump: glulxdump.o
	$(CC) -o glulxdump glulxdump.o

$(OBJS) unixstrt.o unixautosave.o: glulxe.h unixstrt.h

exec.o operand.o: opcodes.h
gestalt.o: gestalt.h

clean:
	rm -f *~ *.o glulxe glulxdump profile-raw

