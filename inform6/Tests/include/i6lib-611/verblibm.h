! ==============================================================================
!   VERBLIBM:  Core of standard verbs library.
!
!   Supplied for use with Inform 6 -- Release 6/11 -- Serial number 040227
!
!   Copyright Graham Nelson 1993-2004 but freely usable (see manuals)
!
!   This file is automatically Included in your game file by "VerbLib".
! ==============================================================================

System_file;

#Ifdef MODULE_MODE;
Constant DEBUG;
Constant Grammar__Version2;
Include "linklpa";
Include "linklv";
#Endif; ! MODULE_MODE

! ------------------------------------------------------------------------------

[ Banner i;
   if (Story ~= 0) {
        #Ifdef TARGET_ZCODE;
        #IfV5; style bold; #Endif;
        print (string) Story;
        #IfV5; style roman; #Endif;
        #Ifnot; ! TARGET_GLULX;
        glk($0086, 3); ! set header style
        print (string) Story;
        glk($0086, 0); ! set normal style
        #Endif; ! TARGET_
    }
    if (Headline ~= 0) print (string) Headline;
    #Ifdef TARGET_ZCODE;
    print "Release ", (HDR_GAMERELEASE-->0) & $03ff, " / Serial number ";
    for (i=0 : i<6 : i++) print (char) HDR_GAMESERIAL->i;
    #Ifnot; ! TARGET_GLULX;
    print "Release ";
    @aloads ROM_GAMERELEASE 0 i;
    print i;
    print " / Serial number ";
    for (i=0 : i<6 : i++) print (char) ROM_GAMESERIAL->i;
    #Endif; ! TARGET_
    print " / Inform v"; inversion;
    print " Library ", (string) LibRelease, " ";
    #Ifdef STRICT_MODE;
    print "S";
    #Endif; ! STRICT_MODE
    #Ifdef INFIX;
    print "X";
    #Ifnot;
    #Ifdef DEBUG;
    print "D";
    #Endif; ! DEBUG
    #Endif; ! INFIX
    new_line;
];

[ VersionSub ix;
    Banner();
    #Ifdef TARGET_ZCODE;
    ix = 0; ! shut up compiler warning
    if (standard_interpreter > 0) {
        print "Standard interpreter ", standard_interpreter/256, ".", standard_interpreter%256,
            " (", HDR_TERPNUMBER->0;
        #Iftrue (#version_number == 6);
        print (char) '.', HDR_TERPVERSION->0;
        #Ifnot;
        print (char) HDR_TERPVERSION->0;
        #Endif;
        print ") / ";
        }
    else {
        print "Interpreter ", HDR_TERPNUMBER->0, " Version ";
        #Iftrue (#version_number == 6);
        print HDR_TERPVERSION->0;
        #Ifnot;
        print (char) HDR_TERPVERSION->0;
        #Endif;
        print " / ";
    }

    #Ifnot; ! TARGET_GLULX;
    @gestalt 1 0 ix;
    print "Interpreter version ", ix / $10000, ".", (ix & $FF00) / $100,
    ".", ix & $FF, " / ";
    @gestalt 0 0 ix;
    print "VM ", ix / $10000, ".", (ix & $FF00) / $100, ".", ix & $FF, " / ";
    #Endif; ! TARGET_;
    print "Library serial number ", (string) LibSerial, "^";
    #Ifdef LanguageVersion;
    print (string) LanguageVersion, "^";
    #Endif; ! LanguageVersion
];

[ RunTimeError n p1 p2;
    #Ifdef DEBUG;
    print "** Library error ", n, " (", p1, ",", p2, ") **^** ";
    switch (n) {
      1:    print "preposition not found (this should not occur)";
      2:    print "Property value not routine or string: ~", (property) p2, "~ of ~", (name) p1,
                  "~ (", p1, ")";
      3:    print "Entry in property list not routine or string: ~", (property) p2, "~ list of ~",
                  (name) p1, "~ (", p1, ")";
      4:    print "Too many timers/daemons are active simultaneously.
                  The limit is the library constant MAX_TIMERS (currently ",
                  MAX_TIMERS, ") and should be increased";
      5:    print "Object ~", (name) p1, "~ has no ~time_left~ property";
      7:    print "The object ~", (name) p1, "~ can only be used as a player object if it has
                  the ~number~ property";
      8:    print "Attempt to take random entry from an empty table array";
      9:    print p1, " is not a valid direction property number";
      10:   print "The player-object is outside the object tree";
      11:   print "The room ~", (name) p1, "~ has no ~description~ property";
      12:   print "Tried to set a non-existent pronoun using SetPronoun";
      13:   print "A 'topic' token can only be followed by a preposition";
      default:
            print "(unexplained)";
    }
    " **";
    #Ifnot;
    "** Library error ", n, " (", p1, ",", p2, ") **";
    #Endif; ! DEBUG
];

! ----------------------------------------------------------------------------
!  The WriteListFrom routine, a flexible object-lister taking care of
!  plurals, inventory information, various formats and so on.  This is used
!  by everything in the library which ever wants to list anything.
!
!  If there were no objects to list, it prints nothing and returns false;
!  otherwise it returns true.
!
!  o is the object, and style is a bitmap, whose bits are given by:
! ----------------------------------------------------------------------------

Constant NEWLINE_BIT       1;       ! New-line after each entry
Constant INDENT_BIT        2;       ! Indent each entry by depth
Constant FULLINV_BIT       4;       ! Full inventory information after entry
Constant ENGLISH_BIT       8;       ! English sentence style, with commas and and
Constant RECURSE_BIT      16;       ! Recurse downwards with usual rules
Constant ALWAYS_BIT       32;       ! Always recurse downwards
Constant TERSE_BIT        64;       ! More terse English style
Constant PARTINV_BIT     128;       ! Only brief inventory information after entry
Constant DEFART_BIT      256;       ! Use the definite article in list
Constant WORKFLAG_BIT    512;       ! At top level (only), only list objects
                                    ! which have the "workflag" attribute
Constant ISARE_BIT      1024;       ! Print " is" or " are" before list
Constant CONCEAL_BIT    2048;       ! Omit objects with "concealed" or "scenery":
                                    ! if WORKFLAG_BIT also set, then does _not_
                                    ! apply at top level, but does lower down
Constant NOARTICLE_BIT  4096;       ! Print no articles, definite or not

[ NextEntry o odepth;
    for (::) {
        o = sibling(o);
        if (o == 0) return 0;
        if (lt_value ~= 0 && o.list_together ~= lt_value) continue;
        if (c_style & WORKFLAG_BIT ~= 0 && odepth==0 && o hasnt workflag) continue;
        if (c_style & CONCEAL_BIT ~= 0 && (o has concealed || o has scenery)) continue;
        return o;
    }
];

[ WillRecurs o;
    if (c_style & ALWAYS_BIT ~= 0) rtrue;
    if (c_style & RECURSE_BIT == 0) rfalse;
    if (o has transparent || o has supporter || (o has container && o has open)) rtrue;
    rfalse;
];

[ ListEqual o1 o2;
    if (child(o1) ~= 0 && WillRecurs(o1) ~= 0) rfalse;
    if (child(o2) ~= 0 && WillRecurs(o2) ~= 0) rfalse;
    if (c_style & (FULLINV_BIT + PARTINV_BIT) ~= 0) {
        if ((o1 hasnt worn && o2 has worn) || (o2 hasnt worn && o1 has worn)) rfalse;
        if ((o1 hasnt light && o2 has light) || (o2 hasnt light && o1 has light)) rfalse;
        if (o1 has container) {
            if (o2 hasnt container) rfalse;
            if ((o1 has open && o2 hasnt open) || (o2 has open && o1 hasnt open))
                rfalse;
        }
        else if (o2 has container)
            rfalse;
    }
    return Identical(o1, o2);
];

[ SortTogether obj value;
    ! print "Sorting together possessions of ", (object) obj, " by value ", value, "^";
    ! for (x=child(obj) : x~=0 : x=sibling(x))
    !     print (the) x, " no: ", x, " lt: ", x.list_together, "^";
    while (child(obj) ~= 0) {
        if (child(obj).list_together ~= value) move child(obj) to out_obj;
        else                                   move child(obj) to in_obj;
    }
    while (child(in_obj) ~= 0)  move child(in_obj) to obj;
    while (child(out_obj) ~= 0) move child(out_obj) to obj;
];

[ SortOutList obj i k l;
    !  print "^^Sorting out list from ", (name) obj, "^  ";
    !  for (i=child(location) : i~=0 : i=sibling(i))
    !      print (name) i, " --> ";
    !  new_line;

  .AP_SOL;

    for (i=obj : i~=0 : i=sibling(i)) {
        k = i.list_together;
        if (k ~= 0) {
            ! print "Scanning ", (name) i, " with lt=", k, "^";
            for (i=sibling(i) : i~=0 && i.list_together == k :) i = sibling(i);
            if (i == 0) rfalse;
            ! print "First not in block is ", (name) i, " with lt=", i.list_together, "^";
            for (l=sibling(i) : l~=0 : l=sibling(l))
                if (l.list_together == k) {
                    SortTogether(parent(obj), k);
                    ! print "^^After ST:^  ";
                    ! for (i=child(location) : i~=0 : i=sibling(i))
                    !     print (name) i, " --> ";
                    ! new_line;
                    obj = child(parent(obj));
                    jump AP_SOL;
                }
        }
    }
];

#Ifdef TARGET_ZCODE;

[ Print__Spaces n;         ! To avoid a bug occurring in Inform 6.01 to 6.10
    if (n == 0) return;
    spaces n;
];

#Ifnot; ! TARGET_GLULX;

[ Print__Spaces n;
    while (n > 0) {
        @streamchar ' ';
        n = n - 1;
    }
];

#Endif; ! TARGET_

[ WriteListFrom o style depth;

    #Ifdef TARGET_ZCODE;
    @push c_style;      @push lt_value;   @push listing_together;
    @push listing_size; @push wlf_indent; @push inventory_stage;
    #Ifnot; ! TARGET_GLULX
    @copy c_style sp;      @copy lt_value sp;   @copy listing_together sp;
    @copy listing_size sp; @copy wlf_indent sp; @copy inventory_stage sp;
    #Endif;

    if (o == child(parent(o))) {
        SortOutList(o);
        o = child(parent(o));
    }
    c_style = style;
    wlf_indent = 0;
    WriteListR(o, depth);

    #Ifdef TARGET_ZCODE;
    @pull inventory_stage;  @pull wlf_indent; @pull listing_size;
    @pull listing_together; @pull lt_value;   @pull c_style;
    #Ifnot; ! TARGET_GLULX
    @copy sp inventory_stage;  @copy sp wlf_indent; @copy sp listing_size;
    @copy sp listing_together; @copy sp lt_value;   @copy sp c_style;
    #Endif;
    rtrue;
];

[ WriteListR o depth stack_pointer  classes_p sizes_p i j k k2 l m n q senc mr;
    if (depth > 0 && o == child(parent(o))) {
        SortOutList(o);
        o = child(parent(o));
    }
    for (::) {
        if (o == 0) rfalse;
        if (c_style & WORKFLAG_BIT ~= 0 && depth==0 && o hasnt workflag) {
            o = sibling(o);
            continue;
        }
        if (c_style & CONCEAL_BIT ~= 0 && (o has concealed || o has scenery)) {
            o = sibling(o);
            continue;
        }
        break;
    }
    classes_p = match_classes + stack_pointer;
    sizes_p   = match_list + stack_pointer;

    for (i=o,j=0 : i~=0 && (j+stack_pointer)<128 : i=NextEntry(i,depth),j++) {
        classes_p->j = 0;
        if (i.plural ~= 0) k++;
    }

    if (c_style & ISARE_BIT ~= 0) {
        if (j == 1 && o hasnt pluralname) print (string) IS__TX;
        else                              print (string) ARE__TX;
        if (c_style & NEWLINE_BIT ~= 0)   print ":^";
        else                              print (char) ' ';
        c_style = c_style - ISARE_BIT;
    }

    stack_pointer = stack_pointer+j+1;

    if (k < 2) jump EconomyVersion;   ! It takes two to plural
    n = 1;
    for (i=o,k=0 : k<j : i=NextEntry(i,depth),k++)
        if (classes_p->k == 0) {
            classes_p->k = n; sizes_p->n = 1;
            for (l=NextEntry(i,depth),m=k+1 : l~=0 && m<j : l=NextEntry(l,depth),m++)
                if (classes_p->m == 0 && i.plural ~= 0 && l.plural ~= 0) {
                    if (ListEqual(i, l) == 1) {
                        sizes_p->n = sizes_p->n + 1;
                        classes_p->m = n;
                    }
                }
            n++;
        }
    n--;

    for (i=1,j=o,k=0 : i<=n : i++,senc++) {
        while (((classes_p->k) ~= i) && ((classes_p->k) ~= -i)) {
            k++; j=NextEntry(j, depth);
        }
        m = sizes_p->i;
        if (j == 0) mr = 0;
        else {
            if (j.list_together ~= 0 or lt_value && ZRegion(j.list_together) == 2 or 3 &&
                j.list_together == mr) senc--;
            mr = j.list_together;
        }
    }
    senc--;

    for (i=1,j=o,k=0,mr=0 : senc>=0 : i++,senc--) {
        while (((classes_p->k) ~= i) && ((classes_p->k) ~= -i)) {
            k++; j=NextEntry(j, depth);
        }
        if (j.list_together ~= 0 or lt_value) {
            if (j.list_together == mr) {
                senc++;
                jump Omit_FL2;
            }
            k2 = NextEntry(j, depth);
            if (k2 == 0 || k2.list_together ~= j.list_together) jump Omit_WL2;
            k2 = ZRegion(j.list_together);
            if (k2 == 2 or 3) {
                q = j; listing_size = 1; l = k; m = i;
                while (m < n && q.list_together == j.list_together) {
                    m++;
                    while (((classes_p->l) ~= m) && ((classes_p->l) ~= -m)) {
                        l++; q = NextEntry(q, depth);
                     }
                    if (q.list_together == j.list_together) listing_size++;
                }
                ! print " [", listing_size, "] ";
                if (listing_size == 1) jump Omit_WL2;
                if (c_style & INDENT_BIT ~= 0) Print__Spaces(2*(depth+wlf_indent));
                if (k2 == 3) {
                    q = 0;
                    for (l=0 : l<listing_size : l++) q = q+sizes_p->(l+i);
                    EnglishNumber(q); print " ";
                    print (string) j.list_together;
                    if (c_style & ENGLISH_BIT ~= 0) print " (";
                    if (c_style & INDENT_BIT ~= 0)  print ":^";
                }
                q = c_style;
                if (k2 ~= 3) {
                    inventory_stage = 1;
                    parser_one = j; parser_two = depth+wlf_indent;
                    if (RunRoutines(j, list_together) == 1) jump Omit__Sublist2;
                }

                #Ifdef TARGET_ZCODE;
                @push lt_value; @push listing_together; @push listing_size;
                #Ifnot; ! TARGET_GLULX;
                @copy lt_value sp; @copy listing_together sp; @copy listing_size sp;
                #Endif; ! TARGET_;

                lt_value = j.list_together; listing_together = j; wlf_indent++;
                WriteListR(j, depth, stack_pointer); wlf_indent--;

                #Ifdef TARGET_ZCODE;
                @pull listing_size; @pull listing_together; @pull lt_value;
                #Ifnot; ! TARGET_GLULX;
                @copy sp listing_size;
                @copy sp listing_together;
                @copy sp lt_value;
                #Endif; ! TARGET_;

                if (k2 == 3) {
                    if (q & ENGLISH_BIT ~= 0) print ")";
                }
                else {
                    inventory_stage = 2;
                    parser_one = j; parser_two = depth+wlf_indent;
                    RunRoutines(j, list_together);
                }

              .Omit__Sublist2;

                if (q & NEWLINE_BIT ~= 0 && c_style & NEWLINE_BIT == 0) new_line;
                c_style = q;
                mr = j.list_together;
                jump Omit_EL2;
            }
        }

      .Omit_WL2;

        if (WriteBeforeEntry(j, depth, -senc) == 1) jump Omit_FL2;
        if (sizes_p->i == 1) {
            if (c_style & NOARTICLE_BIT ~= 0) print (name) j;
            else {
                if (c_style & DEFART_BIT ~= 0) print (the) j; else print (a) j;
            }
        }
        else {
            if (c_style & DEFART_BIT ~= 0) PrefaceByArticle(j, 1, sizes_p->i);
            print (number) sizes_p->i, " ";
            PrintOrRun(j, plural, 1);
        }
        if (sizes_p->i > 1 && j hasnt pluralname) {
            give j pluralname;
            WriteAfterEntry(j, depth, stack_pointer);
            give j ~pluralname;
        }
        else WriteAfterEntry(j,depth,stack_pointer);
      .Omit_EL2;

        if (c_style & ENGLISH_BIT ~= 0) {
            if (senc == 1) print (string) AND__TX;
            if (senc > 1) print (string) COMMA__TX;
        }
     .Omit_FL2;
    }
    rtrue;

  .EconomyVersion;

    n = j;
    for (i=1,j=o : i<=n : j=NextEntry(j,depth),i++,senc++) {
        if (j.list_together ~= 0 or lt_value && ZRegion(j.list_together) == 2 or 3 &&
            j.list_together==mr) senc--;
        mr = j.list_together;
    }

    for (i=1,j=o,mr=0 : i<=senc : j=NextEntry(j,depth),i++) {
        if (j.list_together ~= 0 or lt_value) {
            if (j.list_together == mr) {
                i--;
                jump Omit_FL;
            }
            k = NextEntry(j, depth);
            if (k == 0 || k.list_together ~= j.list_together) jump Omit_WL;
            k = ZRegion(j.list_together);
            if (k == 2 or 3) {
                if (c_style & INDENT_BIT ~= 0) Print__Spaces(2*(depth+wlf_indent));
                if (k == 3) {
                    q = j; l = 0;
                    do {
                        q = NextEntry(q, depth); l++;
                    } until (q == 0 || q.list_together ~= j.list_together);
                    EnglishNumber(l); print " ";
                    print (string) j.list_together;
                    if (c_style & ENGLISH_BIT ~= 0) print " (";
                    if (c_style & INDENT_BIT ~= 0) print ":^";
                }
                q = c_style;
                if (k ~= 3) {
                    inventory_stage = 1;
                    parser_one = j; parser_two = depth+wlf_indent;
                    if (RunRoutines(j, list_together) == 1) jump Omit__Sublist;
                }

                #Ifdef TARGET_ZCODE;
                @push lt_value; @push listing_together; @push listing_size;
                #Ifnot; ! TARGET_GLULX;
                @copy lt_value sp; @copy listing_together sp; @copy listing_size sp;
                #Endif; ! TARGET_;

                lt_value = j.list_together; listing_together = j; wlf_indent++;
                WriteListR(j, depth, stack_pointer); wlf_indent--;

                #Ifdef TARGET_ZCODE;
                @pull listing_size; @pull listing_together; @pull lt_value;
                #Ifnot; ! TARGET_GLULX;
                @copy sp listing_size; @copy sp listing_together; @copy sp lt_value;
                #Endif; ! TARGET_;

                if (k == 3) {
                    if (q & ENGLISH_BIT ~= 0) print ")";
                }
                else {
                    inventory_stage = 2;
                    parser_one = j; parser_two = depth+wlf_indent;
                    RunRoutines(j, list_together);
                }

              .Omit__Sublist;

                if (q & NEWLINE_BIT ~= 0 && c_style & NEWLINE_BIT == 0) new_line;
                c_style = q;
                mr = j.list_together;
                jump Omit_EL;
            }
        }

      .Omit_WL;

        if (WriteBeforeEntry(j, depth, i-senc) == 1) jump Omit_FL;
        if (c_style & NOARTICLE_BIT ~= 0) print (name) j;
        else {
            if (c_style & DEFART_BIT ~= 0) print (the) j; else print (a) j;
        }
        WriteAfterEntry(j, depth, stack_pointer);

      .Omit_EL;

        if (c_style & ENGLISH_BIT ~= 0) {
            if (i == senc-1) print (string) AND__TX;
            if (i < senc-1) print (string) COMMA__TX;
        }

  .Omit_FL;

    }
]; ! end of WriteListR

[ WriteBeforeEntry o depth sentencepos
    flag;

    inventory_stage = 1;
    if (c_style & INDENT_BIT) Print__Spaces(2*(depth+wlf_indent));
    if (o.invent && (c_style & (PARTINV_BIT|FULLINV_BIT))) {    ! This line changed
        flag = PrintOrRun(o, invent, 1);
        if (flag) {
            if (c_style & ENGLISH_BIT) {
                if (sentencepos == -1) print (string) AND__TX;
                if (sentencepos <  -1) print (string) COMMA__TX;
            }
            if (c_style & NEWLINE_BIT) new_line;
        }
    }
    return flag;
];

[ WriteAfterEntry o depth stack_p
    p recurse_flag parenth_flag eldest_child child_count combo;

    inventory_stage = 2;
    if (c_style & PARTINV_BIT) {
        if (o.invent && RunRoutines(o, invent))                 ! These lines
            if (c_style & NEWLINE_BIT) ""; else rtrue;          ! added

        combo = 0;
        if (o has light && location hasnt light) combo=combo+1;
        if (o has container && o hasnt open)     combo=combo+2;
        if ((o has container && (o has open || o has transparent))
            && (child(o)==0))                    combo=combo+4;
        if (combo) L__M(##ListMiscellany, combo, o);
    }   ! end of PARTINV_BIT processing

    if (c_style & FULLINV_BIT) {
        if (o.invent && RunRoutines(o, invent))
            if (c_style & NEWLINE_BIT) ""; else rtrue;

        if (o has light && o has worn) { L__M(##ListMiscellany, 8);     parenth_flag = true; }
        else {
            if (o has light)           { L__M(##ListMiscellany, 9, o);  parenth_flag = true; }
            if (o has worn)            { L__M(##ListMiscellany, 10, o); parenth_flag = true; }
        }

        if (o has container)
            if (o has openable) {
                if (parenth_flag) print (string) AND__TX;
                else              L__M(##ListMiscellany, 11, o);
                if (o has open)
                    if (child(o)) L__M(##ListMiscellany, 12, o);
                    else          L__M(##ListMiscellany, 13, o);
                else
                    if (o has lockable && o has locked) L__M(##ListMiscellany, 15, o);
                    else                                L__M(##ListMiscellany, 14, o);
                parenth_flag = true;
            }
            else
                if (child(o)==0 && o has transparent)
                    if (parenth_flag) L__M(##ListMiscellany, 16, o);
                    else              L__M(##ListMiscellany, 17, o);

        if (parenth_flag) print ")";
    }   ! end of FULLINV_BIT processing

    if (c_style & CONCEAL_BIT) {
        child_count = 0;
        objectloop (p in o)
            if (p hasnt concealed && p hasnt scenery) { child_count++; eldest_child = p; }
    }
    else { child_count = children(o); eldest_child = child(o); }

    if (child_count && (c_style & ALWAYS_BIT)) {
        if (c_style & ENGLISH_BIT) L__M(##ListMiscellany, 18, o);
        recurse_flag = true;
    }

    if (child_count && (c_style & RECURSE_BIT)) {
        if (o has supporter) {
            if (c_style & ENGLISH_BIT) {
                if (c_style & TERSE_BIT) L__M(##ListMiscellany, 19, o);
                else                     L__M(##ListMiscellany, 20, o);
                if (o has animate)       print (string) WHOM__TX;
                else                     print (string) WHICH__TX;
            }
            recurse_flag = true;
        }
        if (o has container && (o has open || o has transparent)) {
            if (c_style & ENGLISH_BIT) {
                if (c_style & TERSE_BIT) L__M(##ListMiscellany, 21, o);
                else                     L__M(##ListMiscellany, 22, o);
                if (o has animate)       print (string) WHOM__TX;
                else                     print (string) WHICH__TX;
                }
            recurse_flag = true;
        }
    }

    if (recurse_flag && (c_style & ENGLISH_BIT))
        if (child_count > 1 || eldest_child has pluralname) print (string) ARE2__TX;
        else                                                print (string) IS2__TX;

    if (c_style & NEWLINE_BIT) new_line;

    if (recurse_flag) {
        o = child(o);
        #Ifdef TARGET_ZCODE;
        @push lt_value; @push listing_together; @push listing_size;
        #Ifnot; ! TARGET_GLULX;
        @copy lt_value sp; @copy listing_together sp; @copy listing_size sp;
        #Endif;
        lt_value = 0;   listing_together = 0;   listing_size = 0;
        WriteListR(o, depth+1, stack_p);
        #Ifdef TARGET_ZCODE;
        @pull listing_size; @pull listing_together; @pull lt_value;
        #Ifnot; ! TARGET_GLULX;
        @copy sp listing_size; @copy sp listing_together; @copy sp lt_value;
        #Endif;
        if (c_style & TERSE_BIT) print ")";
    }
];

! ----------------------------------------------------------------------------
!  Much better menus can be created using one of the optional library
!  extensions.  These are provided for compatibility with previous practice:
! ----------------------------------------------------------------------------

[ LowKey_Menu menu_choices EntryR ChoiceR lines main_title i j;
    menu_nesting++;

  .LKRD;

    menu_item = 0;
    lines = indirect(EntryR);
    main_title = item_name;

    print "--- "; print (string) main_title; print " ---^^";

    if (menu_choices ofclass Routine) menu_choices.call();
    else                              print (string) menu_choices;

    for (::) {
        L__M(##Miscellany, 52, lines);
        print "> ";

        #Ifdef TARGET_ZCODE;
        #IfV3;
        read buffer parse;
        #Ifnot;
        read buffer parse DrawStatusLine;
        #Endif; ! V3
        j = parse->1; ! number of words
        #Ifnot; ! TARGET_GLULX;
        KeyboardPrimitive(buffer, parse);
        j = parse-->0; ! number of words
        #Endif; ! TARGET_

        i = parse-->1;
        if (j == 0 || (i == QUIT1__WD or QUIT2__WD)) {
            menu_nesting--; if (menu_nesting > 0) rfalse;
            if (deadflag == 0) <<Look>>;
            rfalse;
        }
        i = TryNumber(1);
        if (i == 0) jump LKRD;
        if (i < 1 || i > lines) continue;
        menu_item = i;
        j = indirect(ChoiceR);
        if (j == 2) jump LKRD;
        if (j == 3) rfalse;
    }
];

#Ifdef TARGET_ZCODE;

#IfV3;

[ DoMenu menu_choices EntryR ChoiceR; LowKey_Menu(menu_choices, EntryR, ChoiceR); ];

#Endif; ! V3

#IfV5;

[ DoMenu menu_choices EntryR ChoiceR
         lines main_title main_wid cl i j oldcl pkey ch cw y x;
    if (pretty_flag == 0) return LowKey_Menu(menu_choices, EntryR, ChoiceR);
    menu_nesting++;
    menu_item = 0;
    lines = indirect(EntryR);
    main_title = item_name; main_wid = item_width;
    cl = 7;

  .ReDisplay;

    oldcl = 0;
    @erase_window $ffff;
    #Iftrue (#version_number == 6);
    @set_cursor -1;
    ch = HDR_FONTWUNITS->0;
    #Ifnot;
    ch = 1;
    #Endif;
    i = ch * (lines+7);
    @split_window i;
    i = HDR_SCREENWCHARS->0;
    if (i == 0) i = 80;
    @set_window 1;
    @set_cursor 1 1;

    #Iftrue (#version_number == 6);
    @set_font 4 -> cw;
    cw = HDR_FONTHUNITS->0;
    #Ifnot;
    cw = 1;
    #Endif;

    style reverse;
    spaces(i); j=1+(i/2-main_wid)*cw;
    @set_cursor 1 j;
    print (string) main_title;
    y=1+ch; @set_cursor y 1; spaces(i);
    x=1+cw; @set_cursor y x; print (string) NKEY__TX;
    j=1+(i-13)*cw; @set_cursor y j; print (string) PKEY__TX;
    y=y+ch; @set_cursor y 1; spaces(i);
    @set_cursor y x; print (string) RKEY__TX;
    j=1+(i-18)*cw; @set_cursor y j;

    if (menu_nesting == 1) print (string) QKEY1__TX;
    else                   print (string) QKEY2__TX;
    style roman;
    y = y+2*ch;
    @set_cursor y x; font off;

    if (menu_choices ofclass String) print (string) menu_choices;
    else                             menu_choices.call();

    x = 1+3*cw;
    for (::) {
        if (cl ~= oldcl) {
            if (oldcl>0) {
                y=1+(oldcl-1)*ch; @set_cursor y x; print " ";
            }
            y=1+(cl-1)*ch; @set_cursor y x; print ">";
        }

        oldcl = cl;
        @read_char 1 -> pkey;
        if (pkey == NKEY1__KY or NKEY2__KY or 130) {
            cl++; if (cl == 7+lines) cl = 7; continue;
        }
        if (pkey == PKEY1__KY or PKEY2__KY or 129) {
            cl--; if (cl == 6) cl = 6+lines; continue;
        }
        if (pkey == QKEY1__KY or QKEY2__KY or 27 or 131) break;
        if (pkey == 10 or 13 or 132) {
            @set_window 0; font on;
            new_line; new_line; new_line;

            menu_item = cl-6;
            EntryR.call();

            @erase_window $ffff;
            @split_window ch;
            i = HDR_SCREENWCHARS->0; if ( i== 0) i = 80;
            @set_window 1; @set_cursor 1 1; style reverse; spaces(i);
            j=1+(i/2-item_width)*cw;
            @set_cursor 1 j;
            print (string) item_name;
            style roman; @set_window 0; new_line;

            i = ChoiceR.call();
            if (i == 2) jump ReDisplay;
            if (i == 3) break;

            L__M(##Miscellany, 53);
            @read_char 1 -> pkey; jump ReDisplay;
        }
    }

    menu_nesting--; if (menu_nesting > 0) rfalse;
    font on; @set_cursor 1 1;
    @erase_window $ffff; @set_window 0;
    #Iftrue (#version_number == 6);
    @set_cursor -2;
    #Endif;
    new_line; new_line; new_line;
    if (deadflag == 0) <<Look>>;
];

#Endif; ! V5

#Ifnot; ! TARGET_GLULX

[ DoMenu menu_choices EntryR ChoiceR
    winwid winhgt lines main_title main_wid cl i oldcl pkey;

    if (pretty_flag == 0 || gg_statuswin == 0) return LowKey_Menu(menu_choices, EntryR, ChoiceR);

    menu_nesting++;
    menu_item = 0;
    lines = indirect(EntryR);
    main_title = item_name;
    main_wid = item_width;

    cl = 0;

    ! If we printed "hit arrow keys" here, it would be appropriate to
    ! check for the availability of Glk input keys. But we actually
    ! print "hit N/P/Q". So it's reasonable to silently accept Glk
    ! arrow key codes as secondary options.

  .ReDisplay;

    glk($002A, gg_statuswin); ! window_clear
    glk($002A, gg_mainwin); ! window_clear
    glk($002F, gg_statuswin); ! set_window
    StatusLineHeight(lines+7);
    glk($0025, gg_statuswin, gg_arguments, gg_arguments+4); ! window_get_size
    winwid = gg_arguments-->0;
    winhgt = gg_arguments-->1;
    glk($0086, 4); ! set subheader style
    glk($002B, gg_statuswin, winwid/2-main_wid, 0); ! window_move_cursor
    print (string) main_title;
    glk($002B, gg_statuswin, 1, 1); ! window_move_cursor
    print (string) NKEY__TX;
    glk($002B, gg_statuswin, winwid-13, 1); ! window_move_cursor
    print (string) PKEY__TX;
    glk($002B, gg_statuswin, 1, 2); ! window_move_cursor
    print (string) RKEY__TX;
    glk($002B, gg_statuswin, winwid-18, 2); ! window_move_cursor
    if (menu_nesting == 1) print (string) QKEY1__TX;
    else                   print (string) QKEY2__TX;
    glk($0086, 0); ! set normal style

    glk($002B, gg_statuswin, 1, 4); ! window_move_cursor
    if (menu_choices ofclass String) print (string) menu_choices;
    else                             menu_choices.call();

    oldcl = -1;

    for (::) {
        if (cl ~= oldcl) {
            if (cl < 0 || cl >= lines) cl = 0;
            if (oldcl >= 0) {
                glk($002B, gg_statuswin, 3, oldcl+6);
                print (char) ' ';
            }
            oldcl = cl;
            glk($002B, gg_statuswin, 3, oldcl+6);
            print (char) '>';
        }
        pkey = KeyCharPrimitive(gg_statuswin, true);
        if (pkey == $80000000) jump ReDisplay;
        if (pkey == NKEY1__KY or NKEY2__KY or $fffffffb) {
            cl++;
            if (cl >= lines) cl = 0;
            continue;
        }
        if (pkey == PKEY1__KY or PKEY2__KY or $fffffffc) {
            cl--;
            if (cl < 0) cl = lines-1;
            continue;
        }
        if (pkey == QKEY1__KY or QKEY2__KY or $fffffff8 or $fffffffe) break;
        if (pkey == $fffffffa or $fffffffd) {
            glk($002F, gg_mainwin); ! set_window
            new_line; new_line; new_line;
            menu_item = cl+1;
            EntryR.call();

            glk($002A, gg_statuswin); ! window_clear
            glk($002A, gg_mainwin); ! window_clear
            glk($002F, gg_statuswin); ! set_window
            StatusLineHeight(1);
            glk($0025, gg_statuswin, gg_arguments, gg_arguments+4); ! window_get_size
            winwid = gg_arguments-->0;
            winhgt = gg_arguments-->1;
            glk($0086, 4); ! set subheader style
            glk($002B, gg_statuswin, winwid/2-item_width, 0); ! window_move_cursor
            print (string) item_name;
            glk($0086, 0); ! set normal style

            glk($002F, gg_mainwin); ! set_window
            new_line;
            i = ChoiceR.call();
            if (i == 2) jump ReDisplay;
            if (i == 3) break;
            L__M(##Miscellany, 53);
            pkey = KeyCharPrimitive(gg_mainwin, 1);
            jump ReDisplay;
        }
    }

    ! done with this menu...
    menu_nesting--;
    if (menu_nesting > 0) rfalse;
    glk($002F, gg_mainwin); ! set_window
    glk($002A, gg_mainwin); ! window_clear
    new_line; new_line; new_line;
    if (deadflag == 0) <<Look>>;
];

#Endif; ! TARGET_

! ----------------------------------------------------------------------------
!   A cunning routine (which could have been a daemon, but isn't, for the
!   sake of efficiency) to move objects which could be in many rooms about
!   so that the player never catches one not in place
! ----------------------------------------------------------------------------

[ MoveFloatingObjects i k l m address flag;
    if (location == player or nothing) return;
    objectloop (i) {
        address = i.&found_in;
        if (address ~= 0 && i hasnt absent && ~~IndirectlyContains(player, i)) {
            if (ZRegion(address-->0) == 2) {
                if (i.found_in() ~= 0) move i to location;
                else                   remove i;
            }
            else {
                k = i.#found_in;
                for (l=0 : l<k/WORDSIZE : l++) {
                    m = address-->l;
                    if (m == location || m in location) {
                        if (i notin location) move i to location;
                        flag = true;
                    }
                }
                if (flag == false) { if (parent(i)) remove i; }
            }
        }
    }
];

! ----------------------------------------------------------------------------
!   Two little routines for moving the player safely.
! ----------------------------------------------------------------------------

[ PlayerTo newplace flag;
    move player to newplace;
    while (parent(newplace) ~= 0) newplace = parent(newplace);
    location = newplace;
    real_location = location; MoveFloatingObjects();
    AdjustLight(1);
    if (flag == 0) <Look>;
    if (flag == 1) { NoteArrival(); ScoreArrival(); }
    if (flag == 2) LookSub(1);
];

[ MovePlayer direc; <Go direc>; <Look>; ];

! ----------------------------------------------------------------------------
!   The handy YesOrNo routine, and some "meta" verbs
! ----------------------------------------------------------------------------

[ YesOrNo i j;
    for (::) {
        #Ifdef TARGET_ZCODE;
        if (location == nothing || parent(player) == nothing) read buffer parse;
        else read buffer parse DrawStatusLine;
        j = parse->1;
        #Ifnot; ! TARGET_GLULX;
        KeyboardPrimitive(buffer, parse);
        j = parse-->0;
        #Endif; ! TARGET_
        if (j) { ! at least one word entered
            i = parse-->1;
            if (i == YES1__WD or YES2__WD or YES3__WD) rtrue;
            if (i == NO1__WD or NO2__WD or NO3__WD) rfalse;
        }
        L__M(##Quit, 1); print "> ";
    }
];

#Ifdef TARGET_ZCODE;

[ QuitSub; L__M(##Quit, 2); if (YesOrNo() ~= 0) quit; ];

[ RestartSub;
    L__M(##Restart,1);
    if (YesOrNo() ~= 0) { @restart; L__M(##Restart, 2); }
];

[ RestoreSub;
    restore Rmaybe;
    return L__M(##Restore, 1);
  .RMaybe;
    L__M(##Restore, 2);
];

[ SaveSub flag;
    #IfV5;
    @save -> flag;
    switch (flag) {
      0: L__M(##Save, 1);
      1: L__M(##Save, 2);
      2:
        RestoreColours();
        L__M(##Restore, 2);
    }
    #Ifnot;
    save Smaybe;
    return L__M(##Save, 1);
  .SMaybe;
    L__M(##Save, 2);
    #Endif; ! V
];

[ VerifySub;
    @verify ?Vmaybe;
    jump Vwrong;
  .Vmaybe;
    return L__M(##Verify, 1);
  .Vwrong;
    L__M(##Verify, 2);
];

[ ScriptOnSub;
    transcript_mode = ((HDR_GAMEFLAGS-->0) & 1);
    if (transcript_mode) return L__M(##ScriptOn, 1);
    @output_stream 2;
    if (((HDR_GAMEFLAGS-->0) & 1) == 0) return L__M(##ScriptOn, 3);
    L__M(##ScriptOn, 2); VersionSub();
    transcript_mode = true;
];

[ ScriptOffSub;
    transcript_mode = ((HDR_GAMEFLAGS-->0) & 1);
    if (transcript_mode == false) return L__M(##ScriptOff, 1);
    L__M(##ScriptOff, 2);
    @output_stream -2;
    if ((HDR_GAMEFLAGS-->0) & 1) return L__M(##ScriptOff, 3);
    transcript_mode = false;
];

[ CommandsOnSub;
    @output_stream 4;
    xcommsdir = 1;
    L__M(##CommandsOn, 1);
];

[ CommandsOffSub;
    if (xcommsdir == 1) @output_stream -4;
    xcommsdir = 0;
    L__M(##CommandsOff, 1);
];

[ CommandsReadSub;
    @input_stream 1;
    xcommsdir = 2;
    L__M(##CommandsRead, 1);
];

#Ifnot; ! TARGET_GLULX;

[ QuitSub;
    L__M(##Quit, 2);
    if (YesOrNo() ~= 0) quit;
];

[ RestartSub;
    L__M(##Restart,1);
    if (YesOrNo() ~= 0) {
        @restart;
        L__M(##Restart, 2);
    }
];

[ RestoreSub res fref;
    fref = glk($0062, $01, $02, 0); ! fileref_create_by_prompt
    if (fref == 0) jump RFailed;
    gg_savestr = glk($0042, fref, $02, GG_SAVESTR_ROCK); ! stream_open_file
    glk($0063, fref); ! fileref_destroy
    if (gg_savestr == 0) jump RFailed;
    @restore gg_savestr res;
    glk($0044, gg_savestr, 0); ! stream_close
    gg_savestr = 0;
  .RFailed;
    L__M(##Restore, 1);
];

[ SaveSub res fref;
    fref = glk($0062, $01, $01, 0); ! fileref_create_by_prompt
    if (fref == 0) jump SFailed;
    gg_savestr = glk($0042, fref, $01, GG_SAVESTR_ROCK); ! stream_open_file
    glk($0063, fref); ! fileref_destroy
    if (gg_savestr == 0) jump SFailed;
    @save gg_savestr res;
    if (res == -1) {
        ! The player actually just typed "restore". We're going to print
        !  L__M(##Restore,2); the Z-Code Inform library does this correctly
        ! now. But first, we have to recover all the Glk objects; the values
        ! in our global variables are all wrong.
        GGRecoverObjects();
        glk($0044, gg_savestr, 0); ! stream_close
        gg_savestr = 0;
        return L__M(##Restore, 2);
    }
    glk($0044, gg_savestr, 0); ! stream_close
    gg_savestr = 0;
    if (res == 0) return L__M(##Save, 2);
  .SFailed;
    L__M(##Save, 1);
];

[ VerifySub res;
    @verify res;
    if (res == 0) return L__M(##Verify, 1);
    L__M(##Verify, 2);
];

[ ScriptOnSub;
    if (gg_scriptstr ~= 0) return L__M(##ScriptOn, 1);
    if (gg_scriptfref == 0) {
        ! fileref_create_by_prompt
        gg_scriptfref = glk($0062, $102, $05, GG_SCRIPTFREF_ROCK);
        if (gg_scriptfref == 0) jump S1Failed;
    }
    ! stream_open_file
    gg_scriptstr = glk($0042, gg_scriptfref, $05, GG_SCRIPTSTR_ROCK);
    if (gg_scriptstr == 0) jump S1Failed;
    glk($002D, gg_mainwin, gg_scriptstr); ! window_set_echo_stream
    L__M(##ScriptOn, 2);
    VersionSub();
    return;
  .S1Failed;
    L__M(##ScriptOn, 3);
];

[ ScriptOffSub;
    if (gg_scriptstr == 0) return L__M(##ScriptOff,1);
    L__M(##ScriptOff, 2);
    glk($0044, gg_scriptstr, 0); ! stream_close
    gg_scriptstr = 0;
];

[ CommandsOnSub fref;
    if (gg_commandstr ~= 0) {
        if (gg_command_reading)
            L__M(##CommandsOn, 2);
        else
            L__M(##CommandsOn, 3);
        return;
    }
    ! fileref_create_by_prompt
    fref = glk($0062, $103, $01, 0);
    if (fref == 0) return L__M(##CommandsOn, 4);
    gg_command_reading = false;
    ! stream_open_file
    gg_commandstr = glk($0042, fref, $01, GG_COMMANDWSTR_ROCK);
    glk($0063, fref); ! fileref_destroy
    if (gg_commandstr == 0) return L__M(##CommandsOn, 4);
    L__M(##CommandsOn, 1);
];

[ CommandsOffSub;
    if (gg_commandstr == 0) return L__M(##CommandsOff, 2);
    if (gg_command_reading) return L__M(##CommandsRead, 5); ! was L__M(##CommandsOn, 2);
    glk($0044, gg_commandstr, 0); ! stream_close
    gg_commandstr = 0;
    gg_command_reading = false;
    L__M(##CommandsOff, 1);
];

[ CommandsReadSub fref;
    if (gg_commandstr ~= 0) {
        if (gg_command_reading)
            L__M(##CommandsRead, 2);
        else
            L__M(##CommandsRead, 3);
        return;
    }
    ! fileref_create_by_prompt
    fref = glk($0062, $103, $02, 0);
    if (fref == 0) return L__M(##CommandsRead, 4);
    gg_command_reading = true;
    ! stream_open_file
    gg_commandstr = glk($0042, fref, $02, GG_COMMANDRSTR_ROCK);
    glk($0063, fref); ! fileref_destroy
    if (gg_commandstr == 0) return L__M(##CommandsRead, 4);
    return L__M(##CommandsRead, 1);
];

#Endif; ! TARGET_;

[ NotifyOnSub;  notify_mode = 1; L__M(##NotifyOn);  ];
[ NotifyOffSub; notify_mode = 0; L__M(##NotifyOff); ];

[ Places1Sub i j k;
    L__M(##Places, 1);
    objectloop (i has visited) j++;
    objectloop (i has visited) {
        print (name) i; k++;
        if (k == j) { L__M(##Places, 2); return; }
        if (k == j-1) print (string) AND__TX;
        else          print (string) COMMA__TX;
    }
];

[ Objects1Sub i j f;
    L__M(##Objects, 1);
    objectloop (i has moved) {
       f = 1; print (the) i; j = parent(i);
        if (j) {
           if (j == player) {
               if (i has worn) L__M(##Objects, 3);
               else            L__M(##Objects, 4);
                jump Obj__Ptd;
            }
            if (j has animate)   { L__M(##Objects, 5);    jump Obj__Ptd; }
            if (j has visited)   { L__M(##Objects, 6, j); jump Obj__Ptd; }
            if (j has container) { L__M(##Objects, 8, j); jump Obj__Ptd; }
            if (j has supporter) { L__M(##Objects, 9, j); jump Obj__Ptd; }
            if (j has enterable) { L__M(##Objects, 7, j); jump Obj__Ptd; }
        }
        L__M(##Objects, 10);

      .Obj__Ptd;

        new_line;
    }
    if (f == 0) L__M(##Objects, 2);
];

! ----------------------------------------------------------------------------
!   The scoring system
! ----------------------------------------------------------------------------

[ ScoreSub;
    #Ifdef NO_SCORE;
    if (deadflag == 0) L__M(##Score, 2);
    #Ifnot;
    L__M(##Score, 1);
    PrintRank();
    #Endif; ! NO_SCORE
];

#Ifndef TaskScore;
[ TaskScore i;
    return task_scores->i;
];
#Endif;

[ Achieved num;
    if (task_done->num == 0) {
        task_done->num = 1;
        score = score + TaskScore(num);
    }
];

[ PANum m n;
    print "  ";
    n = m;
    if (n < 0)    { n = -m; n = n*10; }
    if (n < 10)   { print "   "; jump Panuml; }
    if (n < 100)  { print "  "; jump Panuml; }
    if (n < 1000) { print " "; }

  .Panuml;

    print m, " ";
];

[ FullScoreSub i;
    ScoreSub();
    if (score == 0 || TASKS_PROVIDED == 1) rfalse;
    new_line;
    L__M(##FullScore, 1);
    for (i=0 : i<NUMBER_TASKS : i++)
        if (task_done->i == 1) {
            PANum(TaskScore(i));
            PrintTaskName(i);
        }
    if (things_score ~= 0) {
        PANum(things_score);
        L__M(##FullScore, 2);
    }
    if (places_score ~= 0) {
        PANum(places_score);
        L__M(##FullScore, 3);
    }
    new_line; PANum(score); L__M(##FullScore, 4);
];

! ----------------------------------------------------------------------------
!   Real verbs start here: Inventory
! ----------------------------------------------------------------------------

[ InvWideSub;
    inventory_style = ENGLISH_BIT+RECURSE_BIT+FULLINV_BIT;
    <Inv>;
];

[ InvTallSub;
    inventory_style = NEWLINE_BIT+RECURSE_BIT+INDENT_BIT+FULLINV_BIT;
    <Inv>;
];

[ InvSub x;
    if (child(player) == 0) return L__M(##Inv, 1);
    if (inventory_style == 0) return InvTallSub();

    L__M(##Inv, 2);
    if (inventory_style & NEWLINE_BIT ~= 0) L__M(##Inv, 3); else print " ";

    WriteListFrom(child(player), inventory_style, 1);
    if (inventory_style & ENGLISH_BIT ~= 0) L__M(##Inv, 4);

    #Ifndef MANUAL_PRONOUNS;
    objectloop (x in player) PronounNotice(x);
    #Endif;
    x = 0; ! To prevent a "not used" error
    AfterRoutines();
];

! ----------------------------------------------------------------------------
!   The object tree and determining the possibility of moves
! ----------------------------------------------------------------------------

[ CommonAncestor o1 o2 i j;
    ! Find the nearest object indirectly containing o1 and o2,
    ! or return 0 if there is no common ancestor.
    i = o1;
    while (i ~= 0) {
        j = o2;
        while (j ~= 0) {
            if (j == i) return i;
            j = parent(j);
        }
        i = parent(i);
    }
    return 0;
];

[ IndirectlyContains o1 o2;
    ! Does o1 indirectly contain o2?  (Same as testing if their common ancestor is o1.)
    while (o2 ~= 0) {
        if (o1 == o2) rtrue;
        if (o2 ofclass Class) rfalse;
        o2 = parent(o2);
    }
    rfalse;
];

[ ObjectScopedBySomething item i j k l m;
    i = item;
    objectloop (j .& add_to_scope) {
        l = j.&add_to_scope;
        k = (j.#add_to_scope)/WORDSIZE;
        if (l-->0 ofclass Routine) continue;
        for (m=0 : m<k : m++)
            if (l-->m == i) return j;
    }
    rfalse;
];

[ ObjectIsUntouchable item flag1 flag2 ancestor i;
    ! Determine if there's any barrier preventing the player from moving
    ! things to "item".  Return false if no barrier; otherwise print a
    ! suitable message and return true.
    ! If flag1 is set, do not print any message.
    ! If flag2 is set, also apply Take/Remove restrictions.

    ! If the item has been added to scope by something, it's first necessary
    ! for that something to be touchable.

    ancestor = CommonAncestor(player, item);
    if (ancestor == 0) {
        ancestor = item;
        while (ancestor && (i = ObjectScopedBySomething(ancestor)) == 0)
            ancestor = parent(ancestor);
        if (i ~= 0) {
            if (ObjectIsUntouchable(i, flag1, flag2)) return;
            ! An item immediately added to scope
        }
    }
    else

    ! First, a barrier between the player and the ancestor.  The player
    ! can only be in a sequence of enterable objects, and only closed
    ! containers form a barrier.

    if (player ~= ancestor) {
        i = parent(player);
        while (i ~= ancestor) {
            if (i has container && i hasnt open) {
                if (flag1) rtrue;
                return L__M(##Take, 9, i);
            }
            i = parent(i);
        }
    }

    ! Second, a barrier between the item and the ancestor.  The item can
    ! be carried by someone, part of a piece of machinery, in or on top
    ! of something and so on.

    if (item ~= ancestor) {
        i = parent(item);
        while (i ~= ancestor) {
            if (flag2 && i hasnt container && i hasnt supporter) {
                if (i has animate) {
                    if (flag1) rtrue;
                    return L__M(##Take, 6, i);
                }
                if (i has transparent) {
                    if (flag1) rtrue;
                    return L__M(##Take, 7, i);
                }
                if (flag1) rtrue;
                return L__M(##Take, 8, item);
            }
            if (i has container && i hasnt open) {
                if (flag1) rtrue;
                return L__M(##Take, 9, i);
            }
            i = parent(i);
        }
    }
    rfalse;
];

[ AttemptToTakeObject item     ancestor after_recipient i j k;
    ! Try to transfer the given item to the player: return false
    ! if successful, true if unsuccessful, printing a suitable message
    ! in the latter case.
    ! People cannot ordinarily be taken.
    if (item == player) return L__M(##Take, 2);
    if (item has animate) return L__M(##Take, 3, item);

    ancestor = CommonAncestor(player, item);

    if (ancestor == 0) {
        i = ObjectScopedBySomething(item);
        if (i ~= 0) ancestor = CommonAncestor(player, i);
    }

    ! Is the player indirectly inside the item?
    if (ancestor == item) return L__M(##Take, 4, item);

    ! Does the player already directly contain the item?
    if (item in player) return L__M(##Take, 5, item);

    ! Can the player touch the item, or is there (e.g.) a closed container
    ! in the way?
    if (ObjectIsUntouchable(item, false, true)) return;

    ! The item is now known to be accessible.

    ! Consult the immediate possessor of the item, if it's in a container
    ! which the player is not in.

    i = parent(item);
    if (i ~= ancestor && (i has container || i has supporter)) {
        after_recipient = i;
        k = action; action = ##LetGo;
        if (RunRoutines(i, before) ~= 0) { action = k; rtrue; }
        action=k;
    }

    if (item has scenery) return L__M(##Take, 10, item);
    if (item has static)  return L__M(##Take, 11, item);

    ! The item is now known to be available for taking.  Is the player
    ! carrying too much?  If so, possibly juggle items into the rucksack
    ! to make room.

    k = 0; objectloop (j in player) if (j hasnt worn) k++;

    if (k >= ValueOrRun(player, capacity)) {
        if (SACK_OBJECT ~= 0) {
            if (parent(SACK_OBJECT) ~= player)
                return L__M(##Take, 12);
            j = 0;
            objectloop (k in player)
                if (k ~= SACK_OBJECT && k hasnt worn && k hasnt light) j = k;

            if (j ~= 0) {
                L__M(##Take, 13, j);
                keep_silent = 1; <Insert j SACK_OBJECT>; keep_silent = 0;
                if (j notin SACK_OBJECT) rtrue;
            }
            else return L__M(##Take, 12);
        }
        else return L__M(##Take, 12);
    }

    ! Transfer the item.

    move item to player;

    ! Send "after" message to the object letting go of the item, if any.

    if (after_recipient ~= 0) {
        k = action; action = ##LetGo;
        if (RunRoutines(after_recipient, after) ~= 0) { action = k; rtrue; }
        action=k;
    }
    rfalse;
];

! ----------------------------------------------------------------------------
!   Object movement verbs
! ----------------------------------------------------------------------------

[ TakeSub;
    if (onotheld_mode == 0 || noun notin player)
        if (AttemptToTakeObject(noun)) rtrue;
    if (AfterRoutines() == 1) rtrue;
    notheld_mode = onotheld_mode;
    if (notheld_mode == 1 || keep_silent == 1) rtrue;
    L__M(##Take, 1);
];

[ RemoveSub i;
    i = parent(noun);
    if (i has container && i hasnt open) return L__M(##Remove, 1, noun);
    if (i ~= second) return L__M(##Remove, 2, noun);
    if (i has animate) return L__M(##Take, 6, i);
    if (AttemptToTakeObject(noun)) rtrue;
    action = ##Remove; if (AfterRoutines() == 1) rtrue;
    action = ##Take;   if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    return L__M(##Remove, 3, noun);
];

[ DropSub;
    if (noun == player) return L__M(##PutOn, 4);
    if (noun in parent(player)) return L__M(##Drop, 1, noun);
    if (noun notin player) return L__M(##Drop, 2, noun);
    if (noun has worn) {
        L__M(##Drop, 3, noun);
        <Disrobe noun>;
        if (noun has worn && noun in player) rtrue;
    }
    move noun to parent(player);
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    return L__M(##Drop, 4, noun);
];

[ PutOnSub ancestor;
    receive_action = ##PutOn;
    if (second == d_obj || player in second) <<Drop noun>>;
    if (parent(noun) == second) return L__M(##Drop,1,noun);
    if (parent(noun) ~= player) return L__M(##PutOn, 1, noun);

    ancestor = CommonAncestor(noun, second);
    if (ancestor == noun) return L__M(##PutOn, 2, noun);
    if (ObjectIsUntouchable(second)) return;

    if (second ~= ancestor) {
        action = ##Receive;
        if (RunRoutines(second, before) ~= 0) { action = ##PutOn; return; }
        action = ##PutOn;
    }
    if (second hasnt supporter) return L__M(##PutOn, 3, second);
    if (ancestor == player) return L__M(##PutOn, 4);
    if (noun has worn) {
        L__M(##PutOn, 5, noun); <Disrobe noun>; if (noun has worn) return;
    }

    if (children(second) >= ValueOrRun(second, capacity))
        return L__M(##PutOn, 6, second);

    move noun to second;

    if (AfterRoutines() == 1) return;

    if (second ~= ancestor) {
        action = ##Receive;
        if (RunRoutines(second, after) ~= 0) { action = ##PutOn; return; }
        action = ##PutOn;
    }
    if (keep_silent == 1) return;
    if (multiflag == 1) return L__M(##PutOn, 7);
    L__M(##PutOn, 8, noun);
];

[ InsertSub ancestor;
    receive_action = ##Insert;
    if (second == d_obj || player in second) <<Drop noun>>;
    if (parent(noun) == second) return L__M(##Drop,1,noun);
    if (parent(noun) ~= player) return L__M(##Insert, 1, noun);

    ancestor = CommonAncestor(noun, second);
    if (ancestor == noun) return L__M(##Insert, 5, noun);
    if (ObjectIsUntouchable(second)) return;

    if (second ~= ancestor) {
        action = ##Receive;
        if (RunRoutines(second,before) ~= 0) { action = ##Insert; rtrue; }
        action = ##Insert;
        if (second has container && second hasnt open)
            return L__M(##Insert, 3, second);
    }
    if (second hasnt container) return L__M(##Insert, 2, second);

    if (noun has worn) {
        L__M(##Insert, 6, noun); <Disrobe noun>; if (noun has worn) return;
    }

    if (children(second) >= ValueOrRun(second, capacity))
        return L__M(##Insert, 7, second);

    move noun to second;

    if (AfterRoutines() == 1) rtrue;

    if (second ~= ancestor) {
        action = ##Receive;
        if (RunRoutines(second, after) ~= 0) { action = ##Insert; rtrue; }
        action = ##Insert;
    }
    if (keep_silent == 1) rtrue;
    if (multiflag == 1) return L__M(##Insert, 8, noun);
    L__M(##Insert, 9, noun);
];

! ----------------------------------------------------------------------------
!   Empties and transfers are routed through the actions above
! ----------------------------------------------------------------------------

[ TransferSub;
    if (noun notin player && AttemptToTakeObject(noun)) return;
    if (second has supporter) <<PutOn noun second>>;
    if (second == d_obj) <<Drop noun>>;
    <<Insert noun second>>;
];

[ EmptySub; second = d_obj; EmptyTSub(); ];

[ EmptyTSub i j k flag;
    if (noun == second) return L__M(##EmptyT, 4);
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt container) return L__M(##EmptyT, 1, noun);
    if (noun hasnt open) return L__M(##EmptyT, 2, noun);
    if (second ~= d_obj) {
        if (second hasnt supporter) {
            if (second hasnt container) return L__M(##EmptyT, 1, second);
            if (second hasnt open) return L__M(##EmptyT, 2, second);
        }
    }
    i = child(noun); k = children(noun);
    if (i == 0) return L__M(##EmptyT, 3, noun);
    while (i ~= 0) {
        j = sibling(i);
        flag = 0;
        if (ObjectIsUntouchable(noun)) flag = 1;
        if (noun hasnt container) flag = 1;
        if (noun hasnt open) flag = 1;
        if (second ~= d_obj) {
            if (second hasnt supporter) {
                if (second hasnt container) flag = 1;
                if (second hasnt open) flag = 1;
            }
        }
        if (k-- == 0) flag = 1;
        if (flag) break;
        if (keep_silent == 0) print (name) i, ": ";
        <Transfer i second>;
        i = j;
    }
];

! ----------------------------------------------------------------------------
!   Gifts
! ----------------------------------------------------------------------------

[ GiveSub;
    if (parent(noun) ~= player) return L__M(##Give, 1, noun);
    if (second == player)  return L__M(##Give, 2, noun);
    if (RunLife(second, ##Give) ~= 0) rfalse;
    L__M(##Give, 3, second);
];

[ GiveRSub; <Give second noun>; ];

[ ShowSub;
    if (parent(noun) ~= player) return L__M(##Show, 1, noun);
    if (second == player) <<Examine noun>>;
    if (RunLife(second, ##Show) ~= 0) rfalse;
    L__M(##Show, 2, second);
];

[ ShowRSub; <Show second noun>; ];

! ----------------------------------------------------------------------------
!   Travelling around verbs
! ----------------------------------------------------------------------------

[ EnterSub ancestor j k;
    if (noun has door || noun in compass) <<Go noun>>;

    if (player in noun) return L__M(##Enter, 1, noun);
    if (noun hasnt enterable) return L__M(##Enter, 2, noun);
    if (noun has container && noun hasnt open) return L__M(##Enter, 3, noun);

    if (parent(player) ~= parent(noun)) {
        ancestor = CommonAncestor(player, noun);
        if (ancestor == player or 0) return L__M(##Enter, 4, noun);
        while (player notin ancestor) {
            j = parent(player);
            k = keep_silent;
            if (parent(j) ~= ancestor || noun ~= ancestor) {
                L__M(##Enter, 6, j);
                keep_silent = 1;
            }
            <Exit>;
            keep_silent = k;
            if (player in j) return;
        }
        if (player in noun) return;
        if (noun notin ancestor) {
            j = parent(noun);
            while (parent(j) ~= ancestor) j = parent(j);
            L__M(##Enter, 7, j);
            k = keep_silent; keep_silent = 1;
            <Enter j>;
            keep_silent = k;
            if (player notin j) return;
            <<Enter noun>>;
        }
    }

    move player to noun;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Enter, 5, noun);
    Locale(noun);
];

[ GetOffSub;
    if (parent(player) == noun) <<Exit>>;
    L__M(##GetOff, 1, noun);
];

[ ExitSub p;
    p = parent(player);
    if (noun ~= nothing && noun ~= p) return L__M(##Exit,4,noun);
    if (p == location || (location == thedark && p == real_location)) {
        if ((location.out_to ~= 0) || (location == thedark && real_location.out_to ~= 0))
            <<Go out_obj>>;
        return L__M(##Exit, 1);
    }
    if (p has container && p hasnt open) return L__M(##Exit, 2, p);

    move player to parent(p);

    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Exit, 3, p); LookSub(1);
];

[ VagueGoSub; L__M(##VagueGo); ];

[ GoInSub; <<Go in_obj>>; ];

[ GoSub i j k df movewith thedir old_loc;

    ! first, check if any PushDir object is touchable
    if (second ~= 0 && second notin Compass && ObjectIsUntouchable(second)) return;

    old_loc = location;
    movewith = 0;
    i = parent(player);
    if ((location ~= thedark && i ~= location) || (location == thedark && i ~= real_location)) {
        j = location;
        if (location == thedark) location = real_location;
        k = RunRoutines(i, before); if (k ~= 3) location = j;
        if (k == 1) {
           movewith = i; i = parent(i);
        }
        else {
            if (k == 0) L__M(##Go,1,i);
            rtrue;
        }
    }

    thedir = noun.door_dir;
    if (ZRegion(thedir) == 2) thedir = RunRoutines(noun, door_dir);

    j = i.thedir; k = ZRegion(j);
    if (k == 3) { print (string) j; new_line; rfalse; }
    if (k == 2) {
        j = RunRoutines(i,thedir);
        if (j==1) rtrue;
    }

    if (k == 0 || j == 0) {
        if (i.cant_go ~= 0 or CANTGO__TX) PrintOrRun(i, cant_go);
        else L__M(##Go,2);
        rfalse;
    }

    if (j has door) {
        if (j has concealed) return L__M(##Go, 2);
        if (j hasnt open) {
            if (noun == u_obj) return L__M(##Go, 3, j);
            if (noun == d_obj) return L__M(##Go, 4, j);
            return L__M(##Go, 5, j);
        }
        k = RunRoutines(j,door_to);
        if (k == 0) return L__M(##Go, 6, j);
        if (k == 1) rtrue;
        j = k;
    }
    if (movewith == 0) move player to j; else move movewith to j;

    location = j; MoveFloatingObjects();
    df = OffersLight(j);
    if (df ~= 0) { location = j; real_location = j; lightflag = 1; }
    else {
        if (old_loc == thedark) {
            DarkToDark();
            if (deadflag ~= 0) rtrue;
        }
        real_location = j;
        location = thedark; lightflag = 0;
    }
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    LookSub(1);
];

! ----------------------------------------------------------------------------
!   Describing the world.  SayWhatsOn(object) does just that (producing
!   no text if nothing except possibly "scenery" and "concealed" items are).
!   Locale(object) runs through the "tail end" of a Look-style room
!   description for the contents of the object, printing up suitable
!   descriptions as it goes.
! ----------------------------------------------------------------------------

[ SayWhatsOn descon j f;
    if (descon == parent(player)) rfalse;
    objectloop (j in descon)
        if (j hasnt concealed && j hasnt scenery) f = 1;
    if (f == 0) rfalse;
    L__M(##Look, 4, descon); rtrue;
];

[ NotSupportingThePlayer o i;
    i = parent(player);
    while (i ~= 0 && i ~= visibility_ceiling) {
        if (i == o) rfalse;
        i = parent(i);
        if (i ~= 0 && i hasnt supporter) rtrue;
    }
    rtrue;
];

[ Locale descin text1 text2 o k p j f2 flag;
    objectloop (o in descin) give o ~workflag;
    k=0;
    objectloop (o in descin)
        if (o hasnt concealed && NotSupportingThePlayer(o)) {
            #Ifndef MANUAL_PRONOUNS;
            PronounNotice(o);
            #Endif;
            if (o hasnt scenery) {
                give o workflag; k++;
                p = initial; f2 = 0;
                if ((o has door || o has container) && o has open && o provides when_open) {
                    p = when_open; f2 = 1; jump Prop_Chosen;
                }
                if ((o has door || o has container) && o hasnt open && o provides when_closed) {
                    p = when_closed; f2 = 1; jump Prop_Chosen;
                }
                if (o has switchable && o has on && o provides when_on) {
                    p = when_on; f2 = 1; jump Prop_Chosen;
                }
                if (o has switchable && o hasnt on && o provides when_off) {
                    p = when_off; f2 = 1;
                }

              .Prop_Chosen;

                if (o hasnt moved || o.&describe ~= 0 || f2 == 1) {
                    if (o.&describe ~= 0 && RunRoutines(o, describe) ~= 0) {
                        flag = 1;
                        give o ~workflag; k--;
                    }
                    else {
                      j = o.p;
                        if (j ~= 0) {
                            new_line;
                            PrintOrRun(o, p);
                            flag = 1;
                            give o ~workflag; k--;
                            if (o has supporter && child(o) ~= 0) SayWhatsOn(o);
                        }
                    }
                }
            }
            else
                if (o has supporter && child(o) ~= 0) SayWhatsOn(o);
        }

    if (k == 0) return 0;

    if (text1 ~= 0) {
        new_line;
        if (flag == 1) text1 = text2;
        print (string) text1, " ";
        WriteListFrom(child(descin),
          ENGLISH_BIT+RECURSE_BIT+PARTINV_BIT+TERSE_BIT+CONCEAL_BIT+WORKFLAG_BIT);
        return k;
    }

    if (flag == 1) L__M(##Look, 5, descin);
    else           L__M(##Look, 6, descin);
];

! ----------------------------------------------------------------------------
!   Looking.  LookSub(1) is allowed to abbreviate long descriptions, but
!     LookSub(0) (which is what happens when the Look action is generated)
!     isn't.  (Except that these are over-ridden by the player-set lookmode.)
! ----------------------------------------------------------------------------

[ LMode1Sub; lookmode=1; print (string) Story; L__M(##LMode1); ];  ! Brief

[ LMode2Sub; lookmode=2; print (string) Story; L__M(##LMode2); ];  ! Verbose

[ LMode3Sub; lookmode=3; print (string) Story; L__M(##LMode3); ];  ! Superbrief

[ NoteArrival descin;
    if (location == thedark) { lastdesc = thedark; return; }
    if (location ~= lastdesc) {
        if (location.initial ~= 0) PrintOrRun(location, initial);
        descin = location;
        NewRoom();
        lastdesc = descin;
    }
];

[ ScoreArrival;
    if (location hasnt visited) {
        give location visited;
        if (location has scored) {
            score = score + ROOM_SCORE;
            places_score = places_score + ROOM_SCORE;
        }
    }
];

[ FindVisibilityLevels visibility_levels;
    visibility_levels = 1;
    visibility_ceiling = parent(player);
    while ((parent(visibility_ceiling) ~= 0)
      && (visibility_ceiling hasnt container || visibility_ceiling has open ||
          visibility_ceiling has transparent)) {
        visibility_ceiling = parent(visibility_ceiling);
        visibility_levels++;
    }
    return visibility_levels;
];

[ LookSub allow_abbrev  visibility_levels i j k nl_flag;
    if (parent(player) == 0) return RunTimeError(10);

  .MovedByInitial;

    if (location == thedark) { visibility_ceiling = thedark; NoteArrival(); }
    else {
        visibility_levels = FindVisibilityLevels();
        if (visibility_ceiling == location) {
            NoteArrival();
            if (visibility_ceiling ~= location) jump MovedByInitial;
        }
    }
    ! Printing the top line: e.g.
    ! Octagonal Room (on the table) (as Frodo)
    new_line;
    #Ifdef TARGET_ZCODE;
    style bold;
    #Ifnot; ! TARGET_GLULX;
    glk($0086, 4); ! set subheader style
    #Endif; ! TARGET_
    if (visibility_levels == 0) print (name) thedark;
    else {
        if (visibility_ceiling ~= location) print (The) visibility_ceiling;
        else print (name) visibility_ceiling;
    }
    #Ifdef TARGET_ZCODE;
    style roman;
    #Ifnot; ! TARGET_GLULX;
    glk($0086, 0); ! set normal style
    #Endif; ! TARGET_

    for (j=1,i=parent(player) : j<visibility_levels : j++,i=parent(i))
        if (i has supporter) L__M(##Look, 1, i);
        else                 L__M(##Look, 2, i);

    if (print_player_flag == 1) L__M(##Look, 3, player);
    new_line;

    ! The room description (if visible)

    if (lookmode < 3 && visibility_ceiling == location) {
        if ((allow_abbrev ~= 1) || (lookmode == 2) || (location hasnt visited)) {
            if (location.&describe ~= 0) RunRoutines(location, describe);
            else {
                if (location.description == 0) RunTimeError(11, location);
                else PrintOrRun(location, description);
            }
        }
    }

    if (visibility_ceiling == location) nl_flag = 1;

    if (visibility_levels == 0) Locale(thedark);
    else {
        for (i=player,j=visibility_levels : j>0: j--,i=parent(i)) give i workflag;

        for (j=visibility_levels : j>0 : j--) {
            for (i=player,k=0 : k<j : k++) i=parent(i);
            if (i.inside_description ~= 0) {
                if (nl_flag) new_line; else nl_flag = 1;
                PrintOrRun(i,inside_description); }
            if (Locale(i)~=0) nl_flag=1;
        }
    }

    LookRoutine();
    ScoreArrival();

    action = ##Look;
    if (AfterRoutines() == 1) rtrue;
];

[ ExamineSub i;
    if (location == thedark) return L__M(##Examine, 1);
    i = noun.description;
    if (i == 0) {
        if (noun has container) <<Search noun>>;
        if (noun has switchable) { L__M(##Examine, 3, noun); rfalse; }
        return L__M(##Examine, 2, noun);
    }
    PrintOrRun(noun, description);
    if (noun has switchable) L__M(##Examine, 3, noun);
    if (AfterRoutines() == 1) rtrue;
];

[ LookUnderSub;
    if (location == thedark) return L__M(##LookUnder, 1);
    L__M(##LookUnder, 2);
];

[ VisibleContents o  i f;
    objectloop (i in o) if (i hasnt concealed && i hasnt scenery) f++;
    return f;
];

[ SearchSub f;
    if (location == thedark) return L__M(##Search, 1, noun);
    if (ObjectIsUntouchable(noun)) return;
    f = VisibleContents(noun);
    if (noun has supporter) {
        if (f == 0) return L__M(##Search, 2, noun);
        return L__M(##Search, 3, noun);
    }
    if (noun hasnt container) return L__M(##Search, 4, noun);
    if (noun hasnt transparent && noun hasnt open) return L__M(##Search, 5, noun);
    if (AfterRoutines() == 1) rtrue;

    if (f == 0) return L__M(##Search, 6, noun);
    L__M(##Search, 7, noun);
];

! ----------------------------------------------------------------------------
!   Verbs which change the state of objects without moving them
! ----------------------------------------------------------------------------

[ UnlockSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt lockable)     return L__M(##Unlock, 1, noun);
    if (noun hasnt locked)       return L__M(##Unlock, 2, noun);
    if (noun.with_key ~= second) return L__M(##Unlock, 3, second);
    give noun ~locked;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Unlock, 4, noun);
];

[ LockSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt lockable) return L__M(##Lock, 1, noun);
    if (noun has locked)     return L__M(##Lock, 2 ,noun);
    if (noun has open)       return L__M(##Lock, 3 ,noun);
    if (noun.with_key ~= second) return L__M(##Lock, 4, second);
    give noun locked;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Lock, 5, noun);
];

[ SwitchonSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt switchable) return L__M(##SwitchOn, 1, noun);
    if (noun has on)           return L__M(##SwitchOn, 2, noun);
    give noun on;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##SwitchOn, 3, noun);
];

[ SwitchoffSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt switchable) return L__M(##SwitchOff, 1, noun);
    if (noun hasnt on)         return L__M(##SwitchOff, 2, noun);
    give noun ~on;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##SwitchOff, 3, noun);
];

[ OpenSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt openable) return L__M(##Open, 1, noun);
    if (noun has locked)     return L__M(##Open, 2, noun);
    if (noun has open)       return L__M(##Open, 3, noun);
    give noun open;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    if (noun has container && noun hasnt transparent && location ~= thedark
        && VisibleContents(noun) ~= 0 && IndirectlyContains(noun, player) == 0)
        return L__M(##Open, 4, noun);
    L__M(##Open,5,noun);
];

[ CloseSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt openable) return L__M(##Close, 1, noun);
    if (noun hasnt open)     return L__M(##Close, 2, noun);
    give noun ~open;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Close, 3, noun);
];

[ DisrobeSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt worn) return L__M(##Disrobe, 1, noun);
    give noun ~worn;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Disrobe,2,noun);
];

[ WearSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt clothing)    return L__M(##Wear, 1, noun);
    if (parent(noun) ~= player) return L__M(##Wear, 2, noun);
    if (noun has worn)          return L__M(##Wear, 3, noun);
    give noun worn;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Wear, 4, noun);
];

[ EatSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun hasnt edible) return L__M(##Eat, 1, noun);
    if (noun has worn) {
        L__M(##Drop, 3, noun);
        <Disrobe noun>;
        if (noun has worn && noun in player) rtrue;
    }
    remove noun;
    if (AfterRoutines() == 1) rtrue;
    if (keep_silent == 1) rtrue;
    L__M(##Eat, 2, noun);
];

! ----------------------------------------------------------------------------
!   Verbs which are really just stubs (anything which happens for these
!   actions must happen in before rules)
! ----------------------------------------------------------------------------

[ AllowPushDir i;
    if (parent(second) ~= compass) return L__M(##PushDir, 2, noun);
    if (second == u_obj or d_obj)  return L__M(##PushDir, 3, noun);
    AfterRoutines(); i = noun; move i to player;
    <Go second>;
    if (location == thedark) move i to real_location;
    else                     move i to location;
];

[ AnswerSub;
    if (second ~= 0 && RunLife(second,##Answer) ~= 0) rfalse;
    L__M(##Answer, 1, noun);
];

[ AskSub;
    if (RunLife(noun,##Ask) ~= 0) rfalse;
    L__M(##Ask, 1, noun);
];

[ AskForSub;
    if (noun == player) <<Inv>>;
    L__M(##Order, 1, noun);
];

[ AskToSub;
    L__M(##Order, 1, noun);
];

[ AttackSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun has animate && RunLife(noun, ##Attack) ~= 0) rfalse;
    L__M(##Attack, 1, noun);
];

[ BlowSub; L__M(##Blow, 1, noun); ];

[ BurnSub; L__M(##Burn, 1, noun); ];

[ BuySub; L__M(##Buy, 1, noun); ];

[ ClimbSub; L__M(##Climb, 1, noun); ];

[ ConsultSub; L__M(##Consult, 1, noun); ];

[ CutSub; L__M(##Cut, 1, noun); ];

[ DigSub; L__M(##Dig, 1, noun); ];

[ DrinkSub; L__M(##Drink, 1, noun); ];

[ FillSub; L__M(##Fill, 1, noun); ];

[ JumpSub; L__M(##Jump, 1, noun); ];

[ JumpOverSub; L__M(##JumpOver, 1, noun); ];

[ KissSub;
    if (ObjectIsUntouchable(noun)) return;
    if (RunLife(noun, ##Kiss) ~= 0) rfalse;
    if (noun == player) return L__M(##Touch, 3, noun);
    L__M(##Kiss, 1, noun);
];

[ ListenSub; L__M(##Listen, 1, noun); ];

[ MildSub; L__M(##Mild, 1, noun); ];

[ NoSub; L__M(##No); ];

[ PraySub; L__M(##Pray, 1, noun); ];

[ PullSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun has static)  return L__M(##Pull, 1, noun);
    if (noun has scenery) return L__M(##Pull, 2, noun);
    if (noun has animate) return L__M(##Pull, 4, noun);
    L__M(##Pull, 3, noun);
];

[ PushSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun has static)  return L__M(##Push, 1, noun);
    if (noun has scenery) return L__M(##Push, 2, noun);
    if (noun has animate) return L__M(##Push, 4, noun);
    L__M(##Push, 3, noun);
];

[ PushDirSub; L__M(##PushDir, 1, noun); ];

[ RubSub; L__M(##Rub, 1, noun); ];

[ SetSub; L__M(##Set, 1, noun); ];

[ SetToSub; L__M(##SetTo, 1, noun); ];

[ SingSub; L__M(##Sing, 1, noun); ];

[ SleepSub; L__M(##Sleep, 1, noun); ];

[ SmellSub; L__M(##Smell, 1, noun); ];

[ SorrySub; L__M(##Sorry, 1, noun); ];

[ SqueezeSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun has animate) return L__M(##Squeeze, 1, noun);
    L__M(##Squeeze, 2, noun);
];

[ StrongSub; L__M(##Strong, 1, noun); ];

[ SwimSub; L__M(##Swim, 1, noun); ];

[ SwingSub; L__M(##Swing, 1, noun); ];

[ TasteSub; L__M(##Taste, 1, noun); ];

[ TellSub;
    if (noun == player) return L__M(##Tell, 1, noun);
    if (RunLife(noun, ##Tell) ~= 0) rfalse;
    L__M(##Tell, 2, noun);
];

[ ThinkSub; L__M(##Think, 1, noun); ];

[ ThrowAtSub;
    if (ObjectIsUntouchable(noun)) return;
    if (second > 1) {
        action = ##ThrownAt;
        if (RunRoutines(second, before) ~= 0) { action = ##ThrowAt; rtrue; }
        action = ##ThrowAt;
    }
    if (noun has worn) {
        L__M(##Drop, 3, noun);
        <Disrobe noun>;
        if (noun has worn && noun in player) rtrue;
    }
    if (second hasnt animate) return L__M(##ThrowAt, 1);
    if (RunLife(second,##ThrowAt) ~= 0) rfalse;
    L__M(##ThrowAt, 2, noun);
];

[ TieSub; L__M(##Tie,1,noun); ];

[ TouchSub;
    if (noun == player)   return L__M(##Touch, 3, noun);
    if (ObjectIsUntouchable(noun)) return;
    if (noun has animate) return L__M(##Touch, 1, noun);
    L__M(##Touch,2,noun); ];

[ TurnSub;
    if (ObjectIsUntouchable(noun)) return;
    if (noun has static)   return L__M(##Turn, 1, noun);
    if (noun has scenery)  return L__M(##Turn, 2, noun);
    if (noun has animate)  return L__M(##Turn, 4, noun);
    L__M(##Turn, 3, noun);
];

[ WaitSub;
    if (AfterRoutines() == 1) rtrue;
    L__M(##Wait, 1, noun);
];

[ WakeSub; L__M(##Wake, 1, noun); ];

[ WakeOtherSub;
    if (ObjectIsUntouchable(noun)) return;
    if (RunLife(noun, ##WakeOther) ~= 0) rfalse;
    L__M(##WakeOther, 1, noun);
];

[ WaveSub;
    if (parent(noun) ~= player) return L__M(##Wave, 1, noun);
    L__M(##Wave, 2 ,noun); ];

[ WaveHandsSub; L__M(##WaveHands, 1, noun); ];

[ YesSub; L__M(##Yes); ];

! ----------------------------------------------------------------------------
!   Debugging verbs
! ----------------------------------------------------------------------------

#Ifdef DEBUG;

[ TraceOnSub; parser_trace=1; "[Trace on.]"; ];

[ TraceLevelSub;
    parser_trace = noun;
    print "[Parser tracing set to level ", parser_trace, ".]^";
];

[ TraceOffSub; parser_trace=0; "Trace off."; ];

[ RoutinesOnSub;  debug_flag = debug_flag | 1;  "[Message listing on.]"; ];

[ RoutinesOffSub; debug_flag = debug_flag & 14; "[Message listing off.]"; ];

[ ActionsOnSub;   debug_flag = debug_flag | 2;  "[Action listing on.]"; ];

[ ActionsOffSub;  debug_flag = debug_flag & 13; "[Action listing off.]"; ];

[ TimersOnSub;    debug_flag = debug_flag | 4;  "[Timers listing on.]"; ];

[ TimersOffSub;   debug_flag = debug_flag & 11; "[Timers listing off.]"; ];

#Ifdef VN_1610;

[ ChangesOnSub;   debug_flag = debug_flag | 8;  "[Changes listing on.]"; ];

[ ChangesOffSub;  debug_flag = debug_flag & 7;  "[Changes listing off.]"; ];

#Ifnot;

[ ChangesOnSub; "[Changes listing available only from Inform 6.2 onwards.]"; ];

[ ChangesOffSub; "[Changes listing available only from Inform 6.2 onwards.]"; ];

#Endif; ! VN_1610

#Ifdef TARGET_ZCODE;

[ PredictableSub i;
    i = random(-100);
    "[Random number generator now predictable.]";
];

#Ifnot; ! TARGET_GLULX;

[ PredictableSub;
    @setrandom 100;
    "[Random number generator now predictable.]";
];

#Endif; ! TARGET_;

[ XTestMove obj dest;
    if ((obj <= InformLibrary) || (obj == LibraryMessages) || (obj in 1))
        "[Can't move ", (name) obj, ": it's a system object.]";
    while (dest ~= 0) {
        if (dest == obj) "[Can't move ", (name) obj, ": it would contain itself.]";
        dest = parent(dest);
    }
    rfalse;
];

[ XPurloinSub;
    if (XTestMove(noun, player)) return;
    move noun to player; give noun moved ~concealed;
    "[Purloined.]";
];

[ XAbstractSub;
    if (XTestMove(noun, second)) return;
    move noun to second;
    "[Abstracted.]";
];

[ XObj obj f;
    if (parent(obj) == 0) print (name) obj; else print (a) obj;
    print " (", obj, ") ";
    if (f == 1 && parent(obj) ~= 0)
        print "(in ", (name) parent(obj), " ", parent(obj), ")";
    new_line;
    if (child(obj) == 0) rtrue;
    if (obj == Class)
        WriteListFrom(child(obj), NEWLINE_BIT+INDENT_BIT+ALWAYS_BIT+NOARTICLE_BIT, 1);
    else
        WriteListFrom(child(obj), NEWLINE_BIT+INDENT_BIT+ALWAYS_BIT+FULLINV_BIT, 1);
];

[ XTreeSub i;
    if (noun == 0) {
        objectloop (i)
            if (i ofclass Object && parent(i) == 0) XObj(i);
    }
    else XObj(noun,1);
];

[ GotoSub;
    if (~~(noun ofclass Object) || (parent(noun)~=0)) "[Not a safe place.]";
    PlayerTo(noun);
];

[ GonearSub x;
    x = noun;
    while (parent(x) ~= 0) x = parent(x);
    PlayerTo(x);
];

[ Print_ScL obj; print_ret ++x_scope_count, ": ", (a) obj, " (", obj, ")"; ];

[ ScopeSub;
    x_scope_count = 0;
    LoopOverScope(Print_ScL, noun);
    if (x_scope_count == 0) "Nothing is in scope.";
];

#Ifdef TARGET_GLULX;

[ GlkListSub id val;
    id = glk($0020, 0, gg_arguments); ! window_iterate
    while (id) {
        print "Window ", id, " (", gg_arguments-->0, "): ";
        val = glk($0028, id); ! window_get_type
        switch (val) {
          1: print "pair";
          2: print "blank";
          3: print "textbuffer";
          4: print "textgrid";
          5: print "graphics";
          default: print "unknown";
        }
        val = glk($0029, id); ! window_get_parent
        if (val) print ", parent is window ", val;
        else     print ", no parent (root)";
        val = glk($002C, id); ! window_get_stream
        print ", stream ", val;
        val = glk($002E, id); ! window_get_echo_stream
        if (val) print ", echo stream ", val;
        print "^";
        id = glk($0020, id, gg_arguments); ! window_iterate
    }
    id = glk($0040, 0, gg_arguments); ! stream_iterate
    while (id) {
        print "Stream ", id, " (", gg_arguments-->0, ")^";
        id = glk($0040, id, gg_arguments); ! stream_iterate
    }
    id = glk($0064, 0, gg_arguments); ! fileref_iterate
    while (id) {
        print "Fileref ", id, " (", gg_arguments-->0, ")^";
        id = glk($0064, id, gg_arguments); ! fileref_iterate
    }
    val = glk($0004, 8, 0); ! gestalt, Sound
    if (val) {
        id = glk($00F0, 0, gg_arguments); ! schannel_iterate
        while (id) {
            print "Soundchannel ", id, " (", gg_arguments-->0, ")^";
            id = glk($00F0, id, gg_arguments); ! schannel_iterate
        }
    }
];

#Endif; ! TARGET_;

#Endif; ! DEBUG

! ----------------------------------------------------------------------------
!   Finally: the mechanism for library text (the text is in the language defn)
! ----------------------------------------------------------------------------

[ L__M act n x1 s;
    s = sw__var;
    sw__var = act;
    if (n == 0) n = 1;
    L___M(n,x1);
    sw__var = s;
];

[ L___M n x1 s;
    s = action;
    lm_n = n;
    lm_o = x1;
    action = sw__var;
    if (RunRoutines(LibraryMessages, before) ~= 0)        { action = s; rfalse; }
    if (LibraryExtensions.RunWhile(ext_messages, 0) ~= 0) { action = s; rfalse; }
    action = s;
    LanguageLM(n, x1);
];

! ==============================================================================
