echo "(A script to make a first build of the core Inform tools)"
echo "(Step 1 of 3: making the overall makefile)"
if ! ( ../inweb/Tangled/inweb -prototype scripts/makescript.txt -makefile makefile; ) then
	echo "(Okay, so that failed. Have you installed and built Inweb?)"
	exit 1
fi
echo "(Step 2 of 3: making individual makefiles)"
if ! ( make makers; ) then
	exit 1
fi
echo "(Step 3 of 3: building the tools)"
if ! ( make; ) then
	exit 1
fi
echo "(Done!)"
