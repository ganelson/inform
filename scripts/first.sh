echo "(A script to make a first build of the core Inform tools)"
echo "(Step 1 of 4: making the overall makefile)"
if ! ( ../inweb/Tangled/inweb make-makefile -script scripts/inform.mkscript -to makefile; ) then
	echo "(Okay, so that failed. Have you installed and built Inweb?)"
	exit 1
fi
echo "(Step 2 of 4: making individual makefiles)"
if ! ( make makers; ) then
	exit 1
fi
echo "(Step 3 of 4: building the tools)"
if ! ( make force; ) then
	exit 1
fi
echo "(Step 4 of 4: building the virtual machine interpreters)"
if ! ( make -f inform6/inform6.mk interpreters; ) then
	exit 1
fi
echo "(Done!)"
