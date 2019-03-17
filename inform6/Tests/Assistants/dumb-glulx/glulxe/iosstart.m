/* iosstart.m: iOS-specific interface code for Glulx. (Objective C)
    Designed by Andrew Plotkin <erkyrath@eblong.com>
    http://eblong.com/zarf/glulx/index.html
*/

#import "TerpGlkViewController.h"
#import "TerpGlkDelegate.h"
#import "GlkLibrary.h"
#import "GlkAppWrapper.h"
#import "GlkWindow.h"
#import "GlkStream.h"
#import "GlkFileRef.h"

#include "glk.h" /* This comes with the IosGlk library. */
#include "glulxe.h"
#include "iosstart.h"
#include "iosglk_startup.h" /* This comes with the IosGlk library. */

static library_state_data library_state; /* used by the archive/unarchive hooks */

static void iosglk_game_start(void);
static void iosglk_game_autorestore(void);
static void iosglk_game_select(glui32 eventaddr);
static void stash_library_state(void);
static void recover_library_state(void);
static void free_library_state(void);
static void iosglk_library_archive(NSCoder *encoder);
static void iosglk_library_unarchive(NSCoder *decoder);

/* This is only needed for autorestore. */
extern gidispatch_rock_t glulxe_classtable_register_existing(void *obj, glui32 objclass, glui32 dispid);

static NSString *documents_dir()
{
	/* We use an old-fashioned way of locating the Documents directory. (The NSManager method for this is iOS 4.0 and later.) */
	
	NSArray *dirlist = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if (!dirlist || [dirlist count] == 0) {
		NSLog(@"unable to locate Documents directory.");
		return nil;
	}
	
	return [dirlist objectAtIndex:0];
}

/* Backtrack through the current opcode (at prevpc), and figure out whether its input arguments are on the stack or not. This will be important when setting up the saved VM state for restarting its opcode.
 
	The opmodes argument must be an array int[3]. Returns YES on success.
 */
static int parse_partial_operand(int *opmodes)
{
	glui32 addr = prevpc;
	
    /* Fetch the opcode number. */
    glui32 opcode = Mem1(addr);
    addr++;
    if (opcode & 0x80) {
		/* More than one-byte opcode. */
		if (opcode & 0x40) {
			/* Four-byte opcode */
			opcode &= 0x3F;
			opcode = (opcode << 8) | Mem1(addr);
			addr++;
			opcode = (opcode << 8) | Mem1(addr);
			addr++;
			opcode = (opcode << 8) | Mem1(addr);
			addr++;
		}
		else {
			/* Two-byte opcode */
			opcode &= 0x7F;
			opcode = (opcode << 8) | Mem1(addr);
			addr++;
		}
    }
	
	if (opcode != 0x130) { /* op_glk */
		NSLog(@"iosglk_startup_code: parsed wrong opcode: %d", opcode);
		return NO;
	}
	
	/* @glk has operands LLS. */
	opmodes[0] = Mem1(addr) & 0x0F;
	opmodes[1] = (Mem1(addr) >> 4) & 0x0F;
	opmodes[2] = Mem1(addr+1) & 0x0F;
	
	return YES;
}

/* We don't load in the game file here. Instead, we set a hook which glk_main() will call back to do that. Why? Because of the annoying restartability of the VM under iosglk; we may finish glk_main() and then have to call it again.
 */
void iosglk_startup_code()
{
	set_library_start_hook(&iosglk_game_start);
	set_library_autorestore_hook(&iosglk_game_autorestore);
	set_library_select_hook(&iosglk_game_select);
	max_undo_level = 32; // allow 32 undo steps
#ifdef IOSGLK_EXTEND_STARTUP_CODE
	IOSGLK_EXTEND_STARTUP_CODE
#endif // IOSGLK_EXTEND_STARTUP_CODE
}

/* This is the library_start_hook, which will be called every time glk_main() begins. (VM thread)
 */
static void iosglk_game_start()
{
	TerpGlkViewController *glkviewc = [TerpGlkViewController singleton];
	NSString *pathname = glkviewc.terpDelegate.gamePath;
	NSLog(@"iosglk_startup_code: game path is %@", pathname);
	
	/* Retain this, because we're assigning it to a global. (It will look like a leak to XCode's leak-profiler.) */
	gamefile = [[GlkStreamFile alloc] initWithMode:filemode_Read rock:1 unicode:NO textmode:NO dirname:@"." pathname:pathname];
	
	/* Now we have to check to see if it's a Blorb file. */
	int res;
	unsigned char buf[12];
	
	glk_stream_set_position(gamefile, 0, seekmode_Start);
	res = glk_get_buffer_stream(gamefile, (char *)buf, 12);
	if (!res) {
		init_err = "The data in this stand-alone game is too short to read.";
		return;
	}

	if (buf[0] == 'G' && buf[1] == 'l' && buf[2] == 'u' && buf[3] == 'l') {
		locate_gamefile(FALSE);
	}
	else if (buf[0] == 'F' && buf[1] == 'O' && buf[2] == 'R' && buf[3] == 'M'
			 && buf[8] == 'I' && buf[9] == 'F' && buf[10] == 'R' && buf[11] == 'S') {
		locate_gamefile(TRUE);
	}
	else {
		init_err = "This is neither a Glulx game file nor a Blorb file which contains one.";
	}
}

/* This is the library_autorestore_hook, which will be called from glk_main() between VM setup and the beginning of the execution loop. (VM thread)
 */
static void iosglk_game_autorestore()
{
	GlkLibrary *library = [GlkLibrary singleton];
	
	NSString *dirname = documents_dir();
	if (!dirname)
		return;
	NSString *gamepath = [dirname stringByAppendingPathComponent:@"autosave.glksave"];
	NSString *libpath = [dirname stringByAppendingPathComponent:@"autosave.plist"];
	
	if (![library.filemanager fileExistsAtPath:gamepath])
		return;
	if (![library.filemanager fileExistsAtPath:libpath])
		return;

	bzero(&library_state, sizeof(library_state));
	GlkLibrary *newlib = nil;
	
	[GlkLibrary setExtraUnarchiveHook:iosglk_library_unarchive];
	@try {
		newlib = [NSKeyedUnarchiver unarchiveObjectWithFile:libpath];
	}
	@catch (NSException *ex) {
		// leave newlib as nil
		NSLog(@"Unable to restore autosave library: %@", ex);
	}
	[GlkLibrary setExtraUnarchiveHook:nil];
	
	if (!newlib || !library_state.active) {
		/* Without a Glk state, there's no point in even trying the VM state. */
		NSLog(@"library autorestore failed!");
		return;
	}
	
	int res;
	GlkStreamFile *savefile = [[[GlkStreamFile alloc] initWithMode:filemode_Read rock:1 unicode:NO textmode:NO dirname:dirname pathname:gamepath] autorelease];
	res = perform_restore(savefile, TRUE);
	glk_stream_close(savefile, nil);
	savefile = nil;
	
	if (res) {
		NSLog(@"VM autorestore failed!");
		return;
	}
	
	pop_callstub(0);
	
	/* Annoyingly, the updateFromLibrary we're about to do will close the currently-open gamefile. We'll recover it immediately, in recover_library_state(). */
	gamefile = nil;
	
	[library updateFromLibrary:newlib];
	recover_library_state();
	NSLog(@"autorestore succeeded.");
	
	free_library_state();
}

/* This is the library_select_hook, which will be called every time glk_select() is invoked. (VM thread)
 */
static void iosglk_game_select(glui32 eventaddr)
{
	glui32 lasteventtype = [GlkAppWrapper singleton].lasteventtype;
	//NSLog(@"### game called select, last event was %d", lasteventtype);
	
	/* Do not autosave if we've just started up, or if the last event was a rearrange event. (We get rearranges in clusters, and they don't change anything interesting anyhow.) */
	if (lasteventtype == -1 || lasteventtype == evtype_Arrange)
		return;
	
	iosglk_do_autosave(eventaddr);
}

void iosglk_do_autosave(glui32 eventaddr)
{
	GlkLibrary *library = [GlkLibrary singleton];
	//NSLog(@"### attempting autosave (pc = %x, eventaddr = %x, stack = %d before stub)", prevpc, eventaddr, stackptr);
	
	/* When the save file is autorestored, the VM will restart the @glk opcode. That means that the Glk argument (the event structure address) must be waiting on the stack. Possibly also the @glk opcode's operands -- these might or might not have come off the stack. */
	int res;
	int opmodes[3];
	res = parse_partial_operand(opmodes);
	if (!res)
		return;

	NSString *dirname = documents_dir();
	if (!dirname)
		return;
	NSString *tmpgamepath = [dirname stringByAppendingPathComponent:@"autosave-tmp.glksave"];
	
	GlkStreamFile *savefile = [[[GlkStreamFile alloc] initWithMode:filemode_Write rock:1 unicode:NO textmode:NO dirname:dirname pathname:tmpgamepath] autorelease];
	
	/* Push all the necessary arguments for the @glk opcode. */
	glui32 origstackptr = stackptr;
	int stackvals = 0;
	/* The event structure address: */
	stackvals++;
	if (stackptr+4 > stacksize)
		fatal_error("Stack overflow in autosave callstub.");
	StkW4(stackptr, eventaddr);
	stackptr += 4;
	if (opmodes[1] == 8) {
		/* The number of Glk arguments (1): */
		stackvals++;
		if (stackptr+4 > stacksize)
			fatal_error("Stack overflow in autosave callstub.");
		StkW4(stackptr, 1);
		stackptr += 4;
	}
	if (opmodes[0] == 8) {
		/* The Glk call selector (0x00C0): */
		stackvals++;
		if (stackptr+4 > stacksize)
			fatal_error("Stack overflow in autosave callstub.");
		StkW4(stackptr, 0x00C0); /* glk_select */
		stackptr += 4;
	}
	
	/* Push a temporary callstub which contains the *last* PC -- the address of the @glk(select) invocation. */
	if (stackptr+16 > stacksize)
		fatal_error("Stack overflow in autosave callstub.");
	StkW4(stackptr+0, 0);
	StkW4(stackptr+4, 0);
	StkW4(stackptr+8, prevpc);
	StkW4(stackptr+12, frameptr);
	stackptr += 16;
	
	res = perform_save(savefile);
	
	stackptr -= 16; // discard the temporary callstub
	stackptr -= 4 * stackvals; // discard the temporary arguments
	if (origstackptr != stackptr)
		fatal_error("Stack pointer mismatch in autosave");
	
	glk_stream_close(savefile, nil);
	savefile = nil;
	
	if (res) {
		NSLog(@"VM autosave failed!");
		return;
	}
	
	bzero(&library_state, sizeof(library_state));
	stash_library_state();
	/* The iosglk_library_archive hook will write out the contents of library_state. */
	
	NSString *tmplibpath = [dirname stringByAppendingPathComponent:@"autosave-tmp.plist"];
	[GlkLibrary setExtraArchiveHook:iosglk_library_archive];
	res = [NSKeyedArchiver archiveRootObject:library toFile:tmplibpath];
	[GlkLibrary setExtraArchiveHook:nil];
	free_library_state();

	if (!res) {
		NSLog(@"library serialize failed!");
		return;
	}

	NSString *finalgamepath = [dirname stringByAppendingPathComponent:@"autosave.glksave"];
	NSString *finallibpath = [dirname stringByAppendingPathComponent:@"autosave.plist"];
	
	/* This is not really atomic, but we're already past the serious failure modes. */
	[library.filemanager removeItemAtPath:finallibpath error:nil];
	[library.filemanager removeItemAtPath:finalgamepath error:nil];
	
	res = [library.filemanager moveItemAtPath:tmpgamepath toPath:finalgamepath error:nil];
	if (!res) {
		NSLog(@"could not move game autosave to final position!");
		return;
	}
	res = [library.filemanager moveItemAtPath:tmplibpath toPath:finallibpath error:nil];
	if (!res) {
		NSLog(@"could not move library autosave to final position");
		return;
	}
}

/* Delete an autosaved game, if one exists.
 */
void iosglk_clear_autosave()
{
	GlkLibrary *library = [GlkLibrary singleton];
	
	NSString *dirname = documents_dir();
	if (!dirname)
		return;
	
	NSString *finalgamepath = [dirname stringByAppendingPathComponent:@"autosave.glksave"];
	NSString *finallibpath = [dirname stringByAppendingPathComponent:@"autosave.plist"];
	
	[library.filemanager removeItemAtPath:finallibpath error:nil];
	[library.filemanager removeItemAtPath:finalgamepath error:nil];
}

/* Utility function used by stash_library_state. Assumes that library_state.accel_funcs is a valid NSMutableArray. */
static void stash_one_accel_func(glui32 index, glui32 addr)
{
	NSMutableArray *arr = (NSMutableArray *)library_state.accel_funcs;
	
	GlulxAccelEntry *ent = [[[GlulxAccelEntry alloc] initWithIndex:index addr:addr] autorelease];
	[arr addObject:ent];
}

/* Copy extra chunks of the VM state into the (static) library_state object. This is information needed by autosave, but not included in the regular save process.
 */
static void stash_library_state()
{
	library_state.active = YES;
	
	library_state.protectstart = protectstart;
	library_state.protectend = protectend;
	stream_get_iosys(&library_state.iosys_mode, &library_state.iosys_rock);
	library_state.stringtable = stream_get_table();
	
	glui32 count = accel_get_param_count();
	NSMutableArray *accel_params = [NSMutableArray arrayWithCapacity:count];
	library_state.accel_params = [accel_params retain];
	for (int ix=0; ix<count; ix++) {
		glui32 param = accel_get_param(ix);
		[accel_params addObject:[NSNumber numberWithUnsignedInt:param]];
	}

	NSMutableArray *accel_funcs = [NSMutableArray arrayWithCapacity:8];
	library_state.accel_funcs = [accel_funcs retain];
	accel_iterate_funcs(&stash_one_accel_func);

	if (gamefile)
		library_state.gamefiletag = gamefile.tag.intValue;
	
	GlkLibrary *library = [GlkLibrary singleton];
	NSMutableArray *id_map_list = [NSMutableArray arrayWithCapacity:4];
	library_state.id_map_list = [id_map_list retain];
	
	for (GlkWindow *win in library.windows) {
		GlkObjIdEntry *ent = [[[GlkObjIdEntry alloc] initWithClass:gidisp_Class_Window tag:win.tag id:find_id_for_window(win)] autorelease];
		[id_map_list addObject:ent];
	}
	for (GlkStream *str in library.streams) {
		GlkObjIdEntry *ent = [[[GlkObjIdEntry alloc] initWithClass:gidisp_Class_Stream tag:str.tag id:find_id_for_stream(str)] autorelease];
		[id_map_list addObject:ent];
	}
	for (GlkFileRef *fref in library.filerefs) {
		GlkObjIdEntry *ent = [[[GlkObjIdEntry alloc] initWithClass:gidisp_Class_Fileref tag:fref.tag id:find_id_for_fileref(fref)] autorelease];
		[id_map_list addObject:ent];
	}
}

/* Copy chunks of VM state out of the (static) library_state object.
 */
static void recover_library_state()
{
	if (library_state.active) {
		protectstart = library_state.protectstart;
		protectend = library_state.protectend;
		stream_set_iosys(library_state.iosys_mode, library_state.iosys_rock);
		stream_set_table(library_state.stringtable);
		
		if (library_state.accel_params) {
			for (int ix=0; ix<library_state.accel_params.count; ix++) {
				NSNumber *num = [library_state.accel_params objectAtIndex:ix];
				glui32 param = num.unsignedIntValue;
				accel_set_param(ix, param);
			}
		}
		if (library_state.accel_funcs) {
			for (GlulxAccelEntry *entry in library_state.accel_funcs) {
				accel_set_func(entry.index, entry.addr);
			}
		}
	}
	
	GlkLibrary *library = [GlkLibrary singleton];
	if (library_state.id_map_list) {
		for (GlkObjIdEntry *ent in library_state.id_map_list) {
			switch (ent.objclass) {
				case gidisp_Class_Window: {
					GlkWindow *win = [library windowForIntTag:ent.tag];
					if (!win) {
						NSLog(@"### Could not find window for tag %d", ent.tag);
						continue;
					}
					win.disprock = glulxe_classtable_register_existing(win, ent.objclass, ent.dispid);
				}
				break;
				case gidisp_Class_Stream: {
					GlkStream *str = [library streamForIntTag:ent.tag];
					if (!str) {
						NSLog(@"### Could not find stream for tag %d", ent.tag);
						continue;
					}
					str.disprock = glulxe_classtable_register_existing(str, ent.objclass, ent.dispid);
				}
				break;
				case gidisp_Class_Fileref: {
					GlkFileRef *fref = [library filerefForIntTag:ent.tag];
					if (!fref) {
						NSLog(@"### Could not find fileref for tag %d", ent.tag);
						continue;
					}
					fref.disprock = glulxe_classtable_register_existing(fref, ent.objclass, ent.dispid);
				}
				break;
			}
		}
	}
	
	if (library_state.gamefiletag)
		gamefile = [library streamForIntTag:library_state.gamefiletag];
}

static void free_library_state()
{
	library_state.active = false;
	
	if (library_state.accel_params) {
		[library_state.accel_params release]; // was retained in stash_library_state()
		library_state.accel_params = nil;
	}
	if (library_state.accel_funcs) {
		[library_state.accel_funcs release]; // was retained in stash_library_state()
		library_state.accel_funcs = nil;
	}
	if (library_state.id_map_list) {
		[library_state.id_map_list release]; // was retained in stash_library_state()
		library_state.id_map_list = nil;
	}
}

static void iosglk_library_archive(NSCoder *encoder)
{
	if (library_state.active) {
		[encoder encodeBool:YES forKey:@"glulx_library_state"];
		[encoder encodeInt32:library_state.protectstart forKey:@"glulx_protectstart"];
		[encoder encodeInt32:library_state.protectend forKey:@"glulx_protectend"];
		[encoder encodeInt32:library_state.iosys_mode forKey:@"glulx_iosys_mode"];
		[encoder encodeInt32:library_state.iosys_rock forKey:@"glulx_iosys_rock"];
		[encoder encodeInt32:library_state.stringtable forKey:@"glulx_stringtable"];
		if (library_state.accel_params)
			[encoder encodeObject:library_state.accel_params forKey:@"glulx_accel_params"];
		if (library_state.accel_funcs)
			[encoder encodeObject:library_state.accel_funcs forKey:@"glulx_accel_funcs"];
		[encoder encodeInt32:library_state.gamefiletag forKey:@"glulx_gamefiletag"];
		if (library_state.id_map_list)
			[encoder encodeObject:library_state.id_map_list forKey:@"glulx_id_map_list"];
	}
}

static void iosglk_library_unarchive(NSCoder *decoder)
{
	NSArray *arr;
	
	if ([decoder decodeBoolForKey:@"glulx_library_state"]) {
		library_state.active = true;
		library_state.protectstart = [decoder decodeInt32ForKey:@"glulx_protectstart"];
		library_state.protectend = [decoder decodeInt32ForKey:@"glulx_protectend"];
		library_state.iosys_mode = [decoder decodeInt32ForKey:@"glulx_iosys_mode"];
		library_state.iosys_rock = [decoder decodeInt32ForKey:@"glulx_iosys_rock"];
		library_state.stringtable = [decoder decodeInt32ForKey:@"glulx_stringtable"];
		arr = [decoder decodeObjectForKey:@"glulx_accel_params"];
		library_state.accel_params = [arr retain];
		arr = [decoder decodeObjectForKey:@"glulx_accel_funcs"];
		library_state.accel_funcs = [arr retain];
		library_state.gamefiletag = [decoder decodeInt32ForKey:@"glulx_gamefiletag"];
		arr = [decoder decodeObjectForKey:@"glulx_id_map_list"];
		library_state.id_map_list = [arr retain];
	}
}

int iosglk_can_restart_cleanly()
{
 	return vm_exited_cleanly;
}

void iosglk_shut_down_process()
{
	/* Yes, we really do want to exit the app here. A fatal error has occurred at the interpreter level, so we can't restart it cleanly. The user has either hit a "goodbye" dialog button or the Home button; either way, it's time for suicide. */
	NSLog(@"iosglk_shut_down_process: goodbye!");
	exit(1);
}


/* GlkObjIdEntry: A simple data class which stores the mapping of a GlkLibrary object (window, stream, etc) to its Glulx-VM ID number. */

@implementation GlkObjIdEntry

- (id) initWithClass:(int)objclassval tag:(NSNumber *)tagref id:(glui32)dispidval
{
	self = [super init];
	
	if (self) {
		objclass = objclassval;
		tag = tagref.intValue;
		dispid = dispidval;
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder
{
	objclass = [decoder decodeInt32ForKey:@"objclass"];
	tag = [decoder decodeInt32ForKey:@"tag"];
	dispid = [decoder decodeInt32ForKey:@"dispid"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeInt32:objclass forKey:@"objclass"];
	[encoder encodeInt32:tag forKey:@"tag"];
	[encoder encodeInt32:dispid forKey:@"dispid"];
}

- (glui32) objclass { return objclass; }
- (glui32) tag { return tag; }
- (glui32) dispid { return dispid; }

@end


/* GlulxAccelEntry: A simple data class which stores an accelerated-function table entry. */

@implementation GlulxAccelEntry

- (id) initWithIndex:(glui32)indexval addr:(glui32)addrval
{
	self = [super init];
	
	if (self) {
		index = indexval;
		addr = addrval;
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder
{
	index = [decoder decodeInt32ForKey:@"index"];
	addr = [decoder decodeInt32ForKey:@"addr"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeInt32:index forKey:@"index"];
	[encoder encodeInt32:addr forKey:@"addr"];
}

- (glui32) index { return index; }
- (glui32) addr { return addr; }

@end


