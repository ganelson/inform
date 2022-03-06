! This include appears before the functions are called; it is a system file.

System_file;

! Will be replaced (entirely).
[ funcepsilon;
    print "original funcepsilon.^";
    failures++;  ! Should not be called.
    return 5;
];

! Will be replaced, but will live on as funcetaorig.
[ funceta;
    print "original funceta.^";
    return 6;
];

