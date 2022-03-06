! This include appears after the functions are called (so they are forward
! definitions); it is a system file.

System_file;

! Will be replaced (entirely).
[ funczeta;
    print "original funczeta.^";
    failures++;  ! Should not be called.
    return 7;
];

! Will be replaced, but will live on as functhetaorig.
[ functheta;
    print "original functheta.^";
    return 8;
];

