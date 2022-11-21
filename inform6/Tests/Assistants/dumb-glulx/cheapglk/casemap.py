#!/usr/bin/env python

# Moderately dumb script to generate the Glk library tables for Unicode
# case-mapping and normalization.
#
# python casemap.py /path/to/unicode/directory > cgunigen.c
#   or
# python casemap.py --js /path/to/unicode/directory > unicodemap.js
#
# The argument should be a directory which contains UnicodeData.txt
# and SpecialCasing.txt. These files can be found at
# <http://www.unicode.org/Public/4.0-Update1/>, which is version 4.0.1
# of the Unicode spec. This script has only been tested with that version
# (and the included files are from that version). It is not current.

from __future__ import print_function

import os
import re
import sys

output = 'c'
args = sys.argv[ 1 : ]

if ('--js' in args):
    output = 'js'
    args.remove('--js')

if ('--c' in args):
    output = 'c'
    args.remove('--c')

if ('--none' in args):
    output = None
    args.remove('--none')

if (len(args) != 1):
    print('Usage: casemap.py [ --js | --c | --none ] /path/to/unicode/directory')
    sys.exit(1)

unicode_dir = args[0]
unicode_version = '???'

try:
    ucdfl = open(os.path.join(unicode_dir, 'UnicodeData.txt'))
    specfl = open(os.path.join(unicode_dir, 'SpecialCasing.txt'))
except IOError:
    print(unicode_dir, 'must contain the files UnicodeData.txt and SpecialCasing.txt.')
    sys.exit(1)

# parse UnicodeData.txt

combintable = {}
decomptable = {}
recdecomptable = {}
compotable = {}

casetable = {}
upcasetable = {}
downcasetable = {}
titlecasetable = {}
totalchars = 0
titleablechars = 0
totalspecialcases = 0

specialtable = {}

while 1:
    ln = ucdfl.readline()
    if (not ln):
        break
    ln = ln.strip()
    pos = ln.find('#')
    if (pos >= 0):
        ln = ln[ : pos]

    ls = ln.split(';')
    if ((not ls) or (not ls[0])):
        continue

    val = int(ls[0], 16)
    totalchars = totalchars+1

    if (len(ls) > 3 and ls[3]):
        combin = int(ls[3])
        if (combin):
            combintable[val] = combin
        
    if (len(ls) > 5 and ls[5]):
        decomp = ls[5]
        if not decomp.startswith('<'):
            ent = [ int(el, 16) for el in decomp.split(' ') ]
            recdecomptable[val] = ent

    upcase = val
    downcase = val
    titlecase = val

    if (len(ls) > 12 and ls[12]):
        upcase = int(ls[12], 16)
        if (val != upcase):
            upcasetable[val] = [upcase]
    if (len(ls) > 13 and ls[13]):
        downcase = int(ls[13], 16)
        if (val != downcase):
            downcasetable[val] = [downcase]
    if (len(ls) > 14 and ls[14]):
        titlecase = int(ls[14], 16)
        if (val != titlecase):
            titlecasetable[val] = [titlecase]

    if (val == upcase and val == downcase and val == titlecase):
        continue

    if (upcase != titlecase):
        titleablechars = titleablechars+1
        specialtable[val] = ([upcase], [downcase], [titlecase])
        
    casetable[val] = (upcase, downcase, titlecase)

while 1:
    ln = specfl.readline()
    if (not ln):
        break
    if ln.startswith('# SpecialCasing'):
        match = re.search('SpecialCasing-([0-9.]+).txt', ln)
        if (match):
            unicode_version = match.group(1)
        continue
    
    ln = ln.strip()
    pos = ln.find('#')
    if (pos >= 0):
        ln = ln[ : pos]

    ls = ln.split(';')
    ls = [st.strip() for st in ls]
    if ((not ls) or (not ls[0])):
        continue

    val = int(ls[0], 16)

    if (len(ls) > 4 and ls[4]):
        # conditional case, ignore
        continue
        
    totalspecialcases = totalspecialcases+1

    upcase = [ int(st, 16) for st in ls[3].split(' ') ]
    downcase = [ int(st, 16) for st in ls[1].split(' ') ]
    titlecase = [ int(st, 16) for st in ls[2].split(' ') ]

    if (upcase != [val]):
        upcasetable[val] = upcase
    if (downcase != [val]):
        downcasetable[val] = downcase
    if (titlecase != [val]):
        titlecasetable[val] = titlecase
    
    speccase = ( upcase, downcase, titlecase )

    casetable[val] = (val, val, val) # placeholder
    specialtable[val] = speccase

# The decomposition data we have extracted is recursive; a character can
# decompose to more decomposable characters. We now expand that into
# flat lists. (It only takes a little more space, because most characters
# aren't recursive that way.)
    
def try_decompose(val):
    if val in decomptable:
        return decomptable[val]
    res = recdecomptable.get(val)
    if not res:
        ls = [ val ]
        decomptable[val] = ls
        return ls
        
    ls = []
    for subval in res:
        ls.extend(try_decompose(subval))
    decomptable[val] = ls
    return ls

for val in recdecomptable.keys():
    try_decompose(val)
for val in list(decomptable.keys()):
    if decomptable[val] == [ val ]:
        decomptable.pop(val)

if (len(recdecomptable) != len(decomptable)):
    raise Exception('Decomposition table changed length in expansion!')

# Generate the composition mapping, which is roughly the inverse of the
# (recursive) decomposition data. It only includes decompositions into
# *two* characters, though. (Decompositions of one character to one
# character are actually canonicalizations, and we don't want to reverse
# those.)

for (val, ls) in recdecomptable.items():
    if len(ls) not in [1, 2]:
        raise Exception('Character %x has decomposition %s' % (val, ls))
    head = ls[0]
    if len(ls) == 2:
        map = compotable.get(head)
        if (map is None):
            map = {}
            compotable[head] = map
        map[ls[1]] = val

max_decompose_length = max([ len(ls) for ls in decomptable.values() ])

sys.stderr.write(str(totalchars) + ' characters in the Unicode database\n')
sys.stderr.write(str(len(combintable)) + ' characters with combining classes\n')
sys.stderr.write(str(len(decomptable)) + ' characters with decompositions (max length ' + str(max_decompose_length) + ')\n')
sys.stderr.write(str(len(compotable)) + ' character compositions\n')
sys.stderr.write(str(len(casetable)) + ' characters which can change case\n')
sys.stderr.write(str(titleablechars) + ' characters with a distinct title-case\n')
sys.stderr.write(str(totalspecialcases) + ' characters with length changes\n')
sys.stderr.write(str(len(specialtable)) + ' special-case characters\n')

# This semi-clever function takes a (sorted) list of integers, and
# divides it into a list of arithmetic runs, and a list of leftovers:
#
#     ([ (start, end, jump), (start, end, jump), ...], [ ... ])
#
# In the worst case, you get back ([], ls) -- no runs, and the entire
# original list as leftovers. The minlength argument tunes the results;
# you get no runs shorter than minlength.
#
def find_runs(ls, minlength=3, jumpone=False):
    runs = []
    extras = []
    minlength = max(minlength, 2)
    
    lslen = len(ls)
    pos = 0

    while True:
        if (lslen - pos < minlength):
            break
        start = ls[pos]
        jump = ls[pos+1] - start
        if (jump == 0):
            raise Exception("Repeated value")

        newpos = pos
        val = start
        while True:
            if (newpos == lslen or ls[newpos] != val):
                break
            newpos += 1
            val += jump

        if (newpos - pos >= minlength and not (jump != 1 and jumpone)):
            runs.append( (start, val-jump, jump) )
            pos = newpos
            continue
        extras.append(start)
        pos += 1

    extras.extend(ls[pos:])

    return (runs, extras)

# Produce the output, in whichever form was requested.

if (output == 'c'):
    # C code output
    
    blocktable = {}

    for val in casetable.keys():
        (upcase, downcase, titlecase) = casetable[val]
    
        blocknum = val >> 8
        if (blocknum not in blocktable):
            block = [ None ] * 256
            blocktable[blocknum] = block
        else:
            block = blocktable[blocknum]
        block[val & 0xFF] = (upcase, downcase)
    
    print('/* This file was generated by casemap.py. */')
    print('/* Derived from Unicode data files, Unicode version %s. */' % (unicode_version,))
    print('/* This does not get compiled into a cgunigen.o file; it\'s')
    print(' * #included in cgunicod.c. */')
    print()

    # The case-folding tables.
    
    blockkeys = list(blocktable.keys())
    blockkeys.sort()

    for blocknum in blockkeys:
        print('static gli_case_block_t unigen_case_block_' + hex(blocknum) + '[256] = {')
        block = blocktable[blocknum]
        for ix in range(256):
            ch = blocknum * 0x100 + ix
            res = block[ix]
            if (res == None):
                upcase = ch
                downcase = ch
            else:
                (upcase, downcase) = res
            if (ch in specialtable):
                print('    { 0xFFFFFFFF, 0xFFFFFFFF },')
            else:
                if (upcase != downcase):
                    if (upcase == ch):
                        comment = '  /* upper */'
                    elif (downcase == ch):
                        comment = '  /* lower */'
                    else:
                        comment = '  /* different */'
                else:
                    comment = ''
                print('    { ' + hex(upcase) + ', ' + hex(downcase) + ' },' + comment)
        print('};')
        print()
    
    print('#define GET_CASE_BLOCK(ch, blockptr)  \\')
    print('switch ((glui32)(ch) >> 8) {  \\')
    for blocknum in blockkeys:
        print('    case ' + hex(blocknum) + ':  \\')
        print('        *blockptr = unigen_case_block_' + hex(blocknum) + ';  \\')
        print('        break;  \\')
    print('    default:  \\')
    print('        *blockptr = NULL;  \\')
    print('}')
    
    specialkeys = list(specialtable.keys())
    specialkeys.sort()
    
    pos = 0
    specialstructs = []
    
    print('static glui32 unigen_special_array[] = {')
    
    for val in specialkeys:
        speccase = specialtable[val]
        (upcasel, downcasel, titlecasel) = speccase
        
        comment = '  /* ' + hex(val) + ' upcase */'
        strarr = ', '.join([hex(st) for st in upcasel])
        print('    ' + str(len(upcasel)) + ', ' + strarr + ',' + comment)
        pos0 = pos
        pos = pos + len(upcasel) + 1
        
        comment = '  /* ' + hex(val) + ' downcase */'
        strarr = ', '.join([hex(st) for st in downcasel])
        print('    ' + str(len(downcasel)) + ', ' + strarr + ',' + comment)
        pos1 = pos
        pos = pos + len(downcasel) + 1
    
        comment = '  /* ' + hex(val) + ' titlecase */'
        strarr = ', '.join([hex(st) for st in titlecasel])
        print('    ' + str(len(titlecasel)) + ', ' + strarr + ',' + comment)
        pos2 = pos
        pos = pos + len(titlecasel) + 1
    
        specialstructs.append( (val, pos0, pos1, pos2) )
    
    print('};')
    print()
    
    for (val, pos0, pos1, pos2) in specialstructs:
        print('static gli_case_special_t unigen_special_' + hex(val) + ' = { ' + str(pos0) + ', ' + str(pos1) + ', ' + str(pos2) + ' };')
    
    print()
    
    print('#define GET_CASE_SPECIAL(ch, specptr)  \\')
    print('switch (ch) {  \\')
    for (val, pos0, pos1, pos2) in specialstructs:
        print('    case ' + hex(val) + ':  \\')
        print('        *specptr = unigen_special_' + hex(val) + ';  \\')
        print('        break;  \\')
    print('    default:  \\')
    print('        *specptr = NULL;  \\')
    print('}')
    
    print()

    # The combining-class table.

    usetable = {}

    for (val, ent) in combintable.items():
        blocknum = val >> 8
        if blocknum not in usetable:
            usetable[blocknum] = {}
        if ent not in usetable[blocknum]:
            usetable[blocknum][ent] = []
        usetable[blocknum][ent].append(val)

    usels = list(usetable.keys())
    usels.sort()
    
    print('#define RETURN_COMBINING_CLASS(ch)  \\')
    print('switch ((glui32)(ch) >> 8) {  \\')
    for blocknum in usels:
        print('  case %d:  \\' % (blocknum,))
        print('    switch (ch) {  \\')
        entls = list(usetable[blocknum].keys())
        entls.sort()
        for ent in entls:
            valls = usetable[blocknum][ent]
            valls.sort()
            for val in valls:
                print('      case %d:  \\' % (val,))
            print('        return %d;  \\' % (ent,))
        print('    }  \\')
        print('    return 0;  \\')
    print('}  \\')
    print('return 0;')
    
    print()

    # The composition tables.

    usetable = {}
    
    for (val, map) in compotable.items():
        blocknum = val >> 8
        if blocknum not in usetable:
            usetable[blocknum] = {}
        usetable[blocknum][val] = map
    
    usels = list(usetable.keys())
    usels.sort()

    print('#define RETURN_COMPOSITION(ch1, ch2)  \\')
    print('switch ((glui32)(ch1) >> 8) {  \\')
    for blocknum in usels:
        print('  case %d:  \\' % (blocknum,))
        print('    switch (ch1) {  \\')
        map = usetable[blocknum]
        ls = list(map.keys())
        ls.sort()
        for val in ls:
            print('      case %d:  \\' % (val,))
            print('        switch (ch2) {  \\')
            subls = list(map[val].items())
            subls.sort()
            for (val2, ent) in subls:
                print('          case %d: return %d;  \\' % (val2, ent))
            print('        }  \\')
            print('        return 0;  \\')
        print('    }  \\')
        print('    return 0;  \\')
    print('}  \\')
    print('return 0;')
    print()

    # The decomposition tables.

    usetable = {}

    for val in decomptable.keys():
        blocknum = val >> 8
        usetable[blocknum] = 1 + usetable.get(blocknum, 0)

    for (blocknum, count) in usetable.items():
        if (count < 30):
            usetable[blocknum] = None

    blocktable = {}
    extratable = {}

    ls = list(decomptable.keys())
    ls.sort()
    offsets = []
    
    for val in ls:
        pos = len(offsets)
        ent = decomptable[val]
        if (type(ent) == list):
            offsets.extend(ent)
            count = len(ent)
        else:
            offsets.append(ent)
            count = 1
        
        blocknum = val >> 8
        if not usetable[blocknum]:
            extratable[val] = (count, pos)
        else:
            if (blocknum not in blocktable):
                block = [ None ] * 256
                blocktable[blocknum] = block
            else:
                block = blocktable[blocknum]
            block[val & 0xFF] = (count, pos)

    print('static glui32 unigen_decomp_data[%d] = {' % (len(offsets),))
    rowcount = 0
    for val in offsets:
        if (rowcount >= 8):
            print()
            rowcount = 0
        print('%s,' % (hex(val)), end=' ')
        rowcount += 1
    print('};')
    print()
            
    blockkeys = list(blocktable.keys())
    blockkeys.sort()

    for blocknum in blockkeys:
        print('static gli_decomp_block_t unigen_decomp_block_%s[256] = {' % (hex(blocknum),))
        block = blocktable[blocknum]
        for ix in range(256):
            ch = blocknum * 0x100 + ix
            res = block[ix]
            if (res == None):
                count = 0
                pos = 0
            else:
                (count, pos) = res
            print('    { %s, %s },' % (str(count), str(pos)))
        print('};')
        print()
        
    print('#define GET_DECOMP_BLOCK(ch, blockptr)  \\')
    print('switch ((glui32)(ch) >> 8) {  \\')
    for blocknum in blockkeys:
        print('    case ' + hex(blocknum) + ':  \\')
        print('        *blockptr = unigen_decomp_block_' + hex(blocknum) + ';  \\')
        print('        break;  \\')
    print('    default:  \\')
    print('        *blockptr = NULL;  \\')
    print('}')

    print()

    extrakeys = list(extratable.keys())
    extrakeys.sort()
    
    print('#define GET_DECOMP_SPECIAL(ch, countptr, posptr)  \\')
    print('switch (ch) {  \\')
    for val in extrakeys:
        (count, pos) = extratable[val]
        print('    case ' + hex(val) + ':  \\')
        print('        *countptr = ' + str(count) + '; *posptr = ' + str(pos) + ';  \\')
        print('        break;  \\')
    print('    default:  \\')
    print('        *countptr = 0;  \\')
    print('}')
    
    print()


# Some helper functions for generating the Javascript data tables. We
# have separate functions for the case tables and the decomp tables,
# because their particular structures are amenable to different
# optimizations. (The case tables have long runs of "N => N+K",
# whereas the decomp tables have long runs of arbitrary values.)
    
def generate_js_table_case(label, pairs, offsets):
    special_offsets = dict([ (key, offsets[key]) for key in offsets.keys()
                             if offsets[key] >= 16 ])
    offmaps = {}
    for offset in special_offsets.keys():
        offmaps[offset] = []
        
    print('/* list all the special cases in unicode_%s_table */' % (label,))
    print('var unicode_%s_table = {' % (label,))
    outls = []
    for (key, val) in pairs:
        if (type(val) == list):
            ls = val
            ls = [ str(val) for val in ls ]
            outls.append('%s: [ %s ]' % (str(key), ','.join(ls)))
            continue
        offset = key-val
        if (offset in offmaps):
            offmaps[offset].append(key)
            continue
        outls.append('%s: %s' % (str(key), str(val)))
    rowcount = 0
    for ix in range(len(outls)):
        val = outls[ix]
        islast = (ix == len(outls)-1)
        if (rowcount >= 5):
            print()
            rowcount = 0
        print(val+('' if islast else ','), end=' ')
        rowcount += 1
    print()
    print('};')

    if (not offmaps):
        print()
        return

    print('/* add all the regular cases to unicode_%s_table */' % (label,))
    print('(function() {')
    print('  var ls, ix, val;')
    print('  var map = unicode_%s_table;' % (label,))
    ls = list(offmaps.keys())
    ls.sort()
    for offset in ls:
        if (offset < 0):
            op = '+' + str(-offset)
        else:
            op = '-' + str(offset)
        # Divide the list of values into a list of runs (which we can
        # do with a simple for loop) and a list of leftovers (which
        # we have to do one by one).
        # The minlength value of 16 is about optimal (by experiment)
        (runs, extras) = find_runs(offmaps[offset], 16)
        for (start, end, jump) in runs:
            print('  for (val=%s; val<=%s; val+=%s) {' % (str(start), str(end), str(jump)))
            print('    map[val] = val%s;' % (op,))
            print('  }')
        if (extras and len(extras) < 3):
            # It's more efficient to dump a few extras as single lines.
            for val in extras:
                print('  map[%d] = %d;' % (val, val-offset))
        elif (extras):
            # But if we have a lot of extras, we should loop over an array.
            print('  ls = [')
            rowcount = 0
            for val in extras:
                if (rowcount >= 8):
                    print()
                    rowcount = 0
                print('%s,' % (str(val)), end=' ')
                rowcount += 1
            print()
            print('  ];')
            print('  for (ix=0; ix<%d; ix++) {' % (len(extras),))
            print('    val = ls[ix];')
            print('    map[val] = val%s;' % (op,))
            print('  }')
    print('})();')

    print()

def generate_js_table_decomp(label, table, runmin=16):
    keys = list(table.keys())
    keys.sort()
    (runs, extras) = find_runs(keys, runmin, True)
    
    print('/* list all the special cases in unicode_%s_table */' % (label,))
    print('var unicode_%s_table = {' % (label,))
    outls = []
    for key in extras:
        val = table[key]
        if (type(val) == list):
            ls = val
            ls = [ str(val) for val in ls ]
            outls.append('%s: [ %s ]' % (str(key), ','.join(ls)))
            continue
        outls.append('%s: %s' % (str(key), str(val)))
    rowcount = 0
    for ix in range(len(outls)):
        val = outls[ix]
        islast = (ix == len(outls)-1)
        if (rowcount >= 5):
            print()
            rowcount = 0
        print(val+('' if islast else ','), end=' ')
        rowcount += 1
    print()
    print('};')

    if (not runs):
        print()
        return

    print('/* add all the regular cases to unicode_%s_table */' % (label,))
    print('(function() {')
    print('  var ls, ix, val;')
    print('  var map = unicode_%s_table;' % (label,))
    for (start, end, jump) in runs:
        print('  ls = [')
        rowcount = 0
        for ix in range(start, end+1):
            val = table[ix]
            if (rowcount >= 8):
                print()
                rowcount = 0
            if (type(val) == list):
                val = [ str(ent) for ent in val ]
                ent = '[' + ','.join(val) + ']'
            else:
                ent = str(val)
            print('%s,' % (ent), end=' ')
            rowcount += 1
        print()
        print('  ];')
        print('  for (ix=0; ix<%d; ix++) {' % (end-start+1,))
        print('    val = ls[ix];')
        print('    map[ix+%d] = val;' % (start,))
        print('  }')
        
    print('})();')

    print()
    
if (output == 'js'):
    # javascript code output
    print('/* These tables were generated by casemap.py. */')
    print('/* Derived from Unicode data files, Unicode version %s. */' % (unicode_version,))
    print()
    
    tablelist = [ (upcasetable, 'upper'),
                  (downcasetable, 'lower') ]
    for (map, label) in tablelist:
        keys = list(map.keys())
        keys.sort()

        pairs = []
        offsets = {}
        for key in keys:
            if (key not in map):
                continue
            ls = map[key]
            if (len(ls) != 1):
                pairs.append( (key, ls) )
                continue
            val = ls[0]
            offset = key-val
            offsets[offset] = offsets.get(offset, 0) + 1
            pairs.append( (key, val) )

        generate_js_table_case(label, pairs, offsets)

    map = {}
    for key in upcasetable.keys():
        if (key not in titlecasetable):
            map[key] = key
    for key in titlecasetable.keys():
        if (titlecasetable[key] != upcasetable.get(key)):
            val = titlecasetable[key]
            if (len(val) == 1):
                val = val[0]
            map[key] = val
    generate_js_table_decomp('title', map)

    map = {}
    for (key, val) in decomptable.items():
        if (len(val) == 1):
            val = val[0]
        map[key] = val
    generate_js_table_decomp('decomp', map, 16)
    generate_js_table_decomp('combin', combintable, 100)

    print('/* list all of unicode_compo_table */')
    print('var unicode_compo_table = {')
    ls = list(compotable.keys())
    ls.sort()
    for key in ls:
        islast = (key == ls[-1])
        subls = list(compotable[key].items())
        subls.sort()
        val = ', '.join([ '%d:%d' % (subkey, subval) for (subkey, subval) in subls ])
        print(' %d: { %s }%s' % (key, val, ('' if islast else ',')))
    print('};')
    
    print('/* End of tables generated by casemap.py. */')
