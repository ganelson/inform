! This include appears before the functions are called; it is not a system
! file.

! Will be replaced (entirely).
[ funcalpha;
    print "original funcalpha.^";
    failures++;  ! Should not be called.
    return 1;
];

! Will be replaced, but will live on as funcgammaorig.
[ funcgamma;
    print "original funcgamma.^";
    return 2;
];

